# F06 — O registro v2

**Sprint:** F · **Tamanho:** G · **Modelo:** Opus · **Estimativa:** US$ 3,5 · **Depende de:** F00, F01, F03, F04, F05

## Por quê

A noite de seis horas só vira inteligência se cada saída tiver número de
sequência, o lugar e o tempo de verdade: é o que o cruzamento casa, linha a
linha, com o registro da ponte do rádio.

## Ler antes

- [13 — O registro v2](../13-arquitetura.md#o-registro-v2--f06-h01-h02-g02-h07)
- [08 — O registro v2](../08-a-noite-de-6-horas.md#o-registro-v2)
- [ADR 003 — o gauntlet](../../adr/003-o-gauntlet.md) (o `formato` sobe de versão quando muda)

## O estado de hoje

**O formato:** `nativo/nucleo/linha_tempo.h:11`,
`#define LINHA_TEMPO_FORMATO "hefesto-tech-demo/linha-do-tempo/1"`, escrito na
primeira linha da sessão (`nativo/nucleo/forja.c:192-203`, o evento `sessao`
com `formato`, `sessao`, `semente`, `versao`, `sdl`, `plataforma`, `simulado`).

**A cabeça de cada linha:** `linha_tempo.c:20-30`:

```c
void ev_iniciar(Evento *e, const LinhaTempo *lt, const char *tipo, int jogador) {
  tb_iniciar(&e->b);
  (void)lt;
  double t = relogio_agora();
  tb_texto(&e->b, "{\"t\": ");
  tb_json_num(&e->b, t, 3);
  tb_texto(&e->b, ", \"tipo\": ");
  tb_json_str(&e->b, tipo);
  if (jogador > 0)
    tb_printf(&e->b, ", \"jogador\": %d", jogador);
}
```

Não há `lugar` nem `t_musica`. `jogador` 0 (a mesa) não é escrito.

**O relógio:** `forja.c:177-179` chama `relogio_do_jogo(&f->t)` **sempre**, então
o `t` é a soma dos `dt` do jogo — o contrário do que `relogio.h:1-5` diz ("no
jogo normal é o relógio de parede; com `--acelerado`… o tempo do jogo"). Não
existe o argumento `--acelerado`. O mesmo relógio carimba o registro de texto
(`registro.c:31`) e o relatório (`forja_agora`).

**As saídas:** todas passam por `ev_saida()` (`pads.c:137-143`):

```c
static void ev_saida(Forja *a, const Pad *p, const char *o, bool ok, Evento *ev) {
  ev_iniciar(ev, &a->lt, "saida", p && p->slot >= 0 ? p->slot + 1 : 0);
  ev_str(ev, "o", o);
  ev_bool(ev, "ok", ok);
  if (p && p->slot < 0)
    ev_str(ev, "controle", p->nome);
}
```

Chamada por `pad_rumble` (`vibracao`), `pad_luz` (`lightbar`), `pad_gatilho` e
`pad_gatilhos_off` (`gatilho`), `pad_led_mic` (`led_microfone`),
`pad_leds_jogador` (`leds_jogador`), `pad_leds_do_slot` (`player_index`) e
`pad_alto_falante` (`audio_hid`). Nenhuma tem `seq`. Depois da F04, o pad
reservado (sem `slot`) sai com `jogador` 0; `pad_lugar(p)` (F04) dá o lugar
dele.

**A conexão:** o evento de `conectou()` (`pads.c:283-294`) tem `nome`,
`vid_pid`, `origem`, `conexao` (o rótulo da origem) e, depois da F05,
`firmware` e `rumble_escala_cheia`. Não tem `transporte`. O SDL relata o
transporte em `p->conexao_sdl` (`pads.c:177`, `SDL_GetGamepadConnectionState`).

**Os campos vindos do GDScript:** `ForjaControles::evento()`
(`nativo/godot/forja_controles.cpp:481-507`) só conhece `BOOL`, `INT`, `FLOAT`;
qualquer outra coisa vira texto (`default:` → `ev_str(String(v))`), então um
`Array` (`"pontos"` da F03, `"escala_vibracao"` da F05) sai como
`"[10, 40, 30, 20]"`, entre aspas.

**Os leitores:** `tests/prova_da_exportacao.sh:52-59` (Python) lê só
`evento`/`o` das linhas; `experimental/rodar.sh` só aponta a pasta. Ninguém
confere o `formato`.

## O alvo

Do [13](../13-arquitetura.md#o-registro-v2--f06-h01-h02-g02-h07): formato
`hefesto-tech-demo/linha-do-tempo/2`, e toda linha

```json
{"t": 12.345, "t_musica": 8.120, "tipo": "saida", "jogador": 3, "lugar": 2, ...}
```

- `t`: segundos desde o início da sessão pelo **relógio monotônico de parede**
  (`SDL_GetTicksNS`); com `--acelerado` (só com `--simular`), o tempo do jogo.
  A linha `sessao` diz qual: `"relogio": "parede"` ou `"jogo"`.
- `t_musica`: escrito só quando alguém informou a posição da música
  (`Forja.t_musica(s)`, que a H01 vai chamar); ausente quando não há.
- `jogador` 1..4 como hoje (0 = a mesa, não escrito); `lugar` = `jogador - 1`
  em toda linha que tem `jogador`.
- `saida`: `seq` por lugar (1, 2, 3…; os pads sem lugar têm a sua contagem),
  que nunca repete na sessão; `o`, os valores e `ok` como hoje.
- `conexao` (`"evento": "conectou"`): `transporte` = `"usb"` / `"bt"` (o que o
  SDL relata), `"virtual"` no simulado, `"desconhecido"` quando o SDL não sabe;
  `firmware` (F05) e `vid_pid`.
- Os campos `Array` do GDScript viram arrays JSON.
- Ficam para as fichas donas: `som_controle` (H07), `nota` e `toque` (H01, H02),
  `calibracao` (G02), `item` (G03). `minigame` (F03) e `sensacao`/`sessao`
  ampliado (F05) já existem.

A API nova (acrescente ao 13 no mesmo commit, se ainda não estiver lá):

```c
void lt_t_musica(double s);            /* linha_tempo.h: a posição da música; negativo = sem música */
```

```gdscript
# forja.gd
func t_musica(s: float) -> void        # ctl.t_musica: a H01 chama a cada quadro; -1 = sem música
# --acelerado: o t da linha do tempo é o tempo do jogo (só com --simular)
```

## Passos

1. **O formato e a cabeça** (`nativo/nucleo/linha_tempo.h` e `.c`):
   `LINHA_TEMPO_FORMATO` → `"hefesto-tech-demo/linha-do-tempo/2"`; em
   `linha_tempo.c`, `static double g_t_musica = -1.0;` e
   `void lt_t_musica(double s) { g_t_musica = s; }`; em `ev_iniciar`, depois do
   `t`: `if (g_t_musica >= 0) { tb_texto(&e->b, ", \"t_musica\": "); tb_json_num(&e->b, g_t_musica, 3); }`,
   e o `jogador` passa a
   `tb_printf(&e->b, ", \"jogador\": %d, \"lugar\": %d", jogador, jogador - 1);`.
   Novas `void ev_nums(Evento *e, const char *chave, const double *v, int n)` e
   `void ev_strs(Evento *e, const char *chave, const char *const *v, int n)`
   (o molde de `ev_ints`, `:48-53`; a string com `tb_json_str`).
2. **O relógio** (`nativo/nucleo/forja.c:179`): apagar `relogio_do_jogo(&f->t);`.
   No evento `sessao` (`:192-203`): `ev_str(&ev, "relogio", "parede");`.
   Reescrever o comentário de `relogio.h:1-5` para dizer a verdade: parede
   sempre; o tempo do jogo só com `--acelerado`.
3. **O seq** (`nativo/nucleo/forja.h:24-49`, no `struct Forja`):
   `long seq_saida[MAX_JOGADORES + 1]; /* por lugar; o último, dos pads sem lugar */`.
   Em `pads.c` `ev_saida()`:
   ```c
     int l = pad_lugar(p);
     ev_iniciar(ev, &a->lt, "saida", l >= 0 ? l + 1 : 0);
     ev_int(ev, "seq", ++a->seq_saida[l >= 0 ? l : MAX_JOGADORES]);
     ev_str(ev, "o", o);
     ev_bool(ev, "ok", ok);
     if (p && l < 0)
       ev_str(ev, "controle", p->nome);
   ```
   (`p` pode ser `NULL`: `pad_lugar` precisa devolver -1 para `NULL`; se não
   devolver, trate aqui.)
4. **O transporte** (`pads.c`, o evento de `conectou()`):
   ```c
     const char *transporte = p->simulado ? "virtual"
                              : p->conexao_sdl == SDL_JOYSTICK_CONNECTION_WIRED    ? "usb"
                              : p->conexao_sdl == SDL_JOYSTICK_CONNECTION_WIRELESS ? "bt"
                                                                                   : "desconhecido";
     ev_str(&ev, "transporte", transporte);
   ```
   E o mesmo no `reg_linha` de `:295` (`" · transporte %s"`). Se a F05 não pôs
   `firmware` aqui, ponha agora (`"0x%04x"`).
5. **As ligações** (`nativo/godot/forja_controles.cpp` e `.h`):
   - `ForjaControles::evento()` (`:481-507`): `case Variant::ARRAY:` e os
     `PACKED_*_ARRAY` → se todos os itens são `INT`, `ev_ints`; se são números,
     `ev_nums`; se são `String`, `ev_strs` (até 16 itens, num vetor local); o
     resto continua virando texto.
   - `void ForjaControles::t_musica(float s)` → `lt_t_musica(s)`;
     `void ForjaControles::acelerar(bool sim)` → `relogio_do_jogo(sim ? &g_forja.t : NULL)`
     e um evento `sessao` com `"evento": "relogio"` e `"relogio": sim ? "jogo" : "parede"`.
     `METODO(t_musica, "s"); METODO(acelerar, "sim");`.
   - `scripts/compilar.sh linux` e `scripts/compilar.sh testes` (sem o jogo aberto).
6. **`godot/scripts/forja.gd`**: `func t_musica(s: float) -> void` (chama
   `ctl.t_musica(s)` com o módulo); em `_ready()`, depois de
   `semente = ctl.semente()`: `if _args.has("acelerado") and simular > 0: ctl.acelerar(true)`.
   Acrescentar `--acelerado` ao cabeçalho dos argumentos (`:13-25`) e a
   `docs/DESENVOLVER.md`.
7. **Os leitores:** em `tests/prova_da_exportacao.sh` (o Python de `:36-75`),
   depois de ler as linhas: juntar os `formato` das linhas `sessao` e reprovar
   se houver algum fora de `{"hefesto-tech-demo/linha-do-tempo/1", "hefesto-tech-demo/linha-do-tempo/2"}`.
   Os campos lidos (`evento`, `o`) não mudam.
8. **Os documentos:** `docs/adr/003-o-gauntlet.md`, no item 2 do "Decisão",
   uma frase: "Na versão 2, toda linha tem `lugar`, o `t` é o relógio de parede
   (o do jogo só com `--acelerado`), toda `saida` tem `seq` por lugar e a
   `conexao` tem `transporte` e `firmware`."
9. **A prova**: as checagens de "Provas".

## Armadilhas

- **Quem depende do `t` ser o tempo do jogo?** O motor simulado para pelo
  `a->t` (`pads.c:437-443`) e a taxa do giroscópio simulado usa
  `a->relogio_sim_ns` (`pads.c:29-31`): nenhum dos dois usa o `relogio_agora`.
  Mudar o relógio não muda o robô. Confira com `bash tests/prova_do_jogo.sh`.
- **A prova roda com `--fixed-fps 60`**, mais rápido que o tempo real: o `t` de
  parede fica menor que o tempo do jogo. É isso que a checagem usa. Numa
  máquina lenta ela não distingue os dois relógios, mas não falha à toa.
- **`jogador` 0** continua fora da linha (os leitores de hoje contam com isso);
  o `lugar` só aparece junto do `jogador`.
- **O `seq` nunca zera**: ele mora no `struct Forja`, não no `Pad` (o `Pad` é
  zerado a cada reconexão, `pads.c:208` e `:354`).
- **A F04 é pré-requisito** (o `pad_lugar`). Sem ela, use `p->slot` e anote.
- **Nada de endereço de aparelho** na linha nova: o `ev_fim` já passa
  `mascara_mac` (`linha_tempo.c:58`), e a prova do relatório
  (`prova_do_jogo.gd:391-396`) confere os arquivos.
- **CONTRATO:** só registro; nenhuma saída nova ao controle.

## Não fazer

- Não criar os tipos das outras fichas (`som_controle`, `nota`, `toque`,
  `calibracao`, `item`).
- Não escrever o `scripts/cruzar_noite.py` (sprint S).
- Não mudar o registro de texto nem o relatório além do relógio.

## Pronto quando

Uma sessão com `--simular=4 --robo` gera uma linha do tempo v2 em que o `t`
nunca anda para trás e segue o relógio de parede, toda linha com `jogador` tem
`lugar`, toda saída tem `seq` de 1 em 1 por lugar, toda conexão diz
transporte e firmware, e os arrays do GDScript são arrays JSON.

## Provas

Na sessão: `scripts/compilar.sh linux`, `scripts/compilar.sh testes` e
`bash tests/prova_do_jogo.sh`. (O `linha_tempo.c` usa o SDL e fica fora do
`forja-testes`; a prova é a da linha do tempo gravada.)

Em `godot/testes/prova_do_jogo.gd`, uma função chamada no fim de `_ready()`
(usa o `_linha_do_tempo()` da F01):

```gdscript
func _prova_do_registro_v2() -> void:
	var linhas := _linha_do_tempo()
	_esperar(not linhas.is_empty() and linhas[0].get("formato") == "hefesto-tech-demo/linha-do-tempo/2"
		and linhas[0].get("relogio") == "parede", "a linha do tempo é a v2, no relógio de parede")
	var t_antes := -1.0
	var t_ok := true
	var lugar_ok := true
	var seq := {}
	var seq_ok := true
	var saidas := 0
	for e in linhas:
		var t := float(e.get("t", -1.0))
		t_ok = t_ok and t >= t_antes
		t_antes = t
		if int(e.get("jogador", 0)) > 0:
			lugar_ok = lugar_ok and int(e.get("lugar", -1)) == int(e.get("jogador")) - 1
		if e.get("tipo") == "saida":
			saidas += 1
			var chave := int(e.get("lugar", -1))
			var s := int(e.get("seq", 0))
			seq_ok = seq_ok and s == int(seq.get(chave, 0)) + 1
			seq[chave] = s
	var processo := Time.get_ticks_msec() / 1000.0
	_esperar(t_ok, "o t nunca anda para trás")
	_esperar(t_antes <= processo + 0.5, "o t é o relógio de parede (%.1f s na linha, %.1f s de processo)" % [t_antes, processo])
	_esperar(lugar_ok, "toda linha com jogador tem o lugar (jogador - 1)")
	_esperar(saidas > 100 and seq_ok, "toda saída tem seq, de 1 em 1 por lugar (%d saídas)" % saidas)
	var con := linhas.filter(func(e): return e.get("tipo") == "conexao" and e.get("evento") == "conectou")
	_esperar(con.size() >= 4 and con.all(func(e): return e.get("transporte") == "virtual"
		and str(e.get("firmware", "")).begins_with("0x") and e.has("vid_pid")),
		"a conexão diz o transporte (virtual, no simulado), o firmware e o VID:PID")
	var fim := linhas.filter(func(e): return e.get("tipo") == "minigame" and e.get("evento") == "terminou")
	_esperar(not fim.is_empty() and fim.all(func(e): return e.get("pontos") is Array),
		"os pontos do minigame são um array JSON de verdade")
	_esperar(not linhas.any(func(e): return e.has("t_musica")), "sem música informada, nenhuma linha tem t_musica")
```

## Para o André (local)

- `scripts/gauntlet.sh`, `bash tests/prova_de_poucos.sh` e `bash tests/prova_da_bancada.sh`.
- `scripts/exportar.sh tudo && bash tests/prova_da_exportacao.sh` (lê as duas versões).
- Uma partida curta com um DualSense no cabo e um no rádio; abrir a
  `relatorios/linha-do-tempo-*.jsonl` e conferir: `transporte` `"usb"` e
  `"bt"` nas conexões, o `firmware` de cada um, e o `t` da última linha perto
  do tempo que a sessão durou no relógio.

## Ao terminar

- No [quadro](README.md), a linha da F06: estado **feito** (com o commit) e o gasto real.
- Se `lt_t_musica`, `Forja.t_musica`, `--acelerado` e o `transporte` `"virtual"`
  ainda não estiverem no 13 ("O registro v2"), acrescentar no mesmo commit.
- Commit sugerido: `feat: o registro v2 — relógio de parede, lugar em toda linha e seq em toda saída`
