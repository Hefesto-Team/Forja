# F05 — O háptico forte

**Sprint:** F · **Tamanho:** G · **Depende de:** F00, F01

## Por quê

O háptico ficou ultra fraco: o jogo pede 0,2 a 0,35 só no motor fraco, por 40
a 70 ms, e cada sala escolhe os seus números. Toda vibração passa a sair de uma
tabela de sensações com o piso de força, e o que dá para medir das sete
suspeitas fica registrado para o André decidir o resto com o controle na mão.

## Ler antes

- [13 — As sensações](../13-arquitetura.md#as-sensações--f05)
- [05 — Por que o háptico está fraco](../05-haptica-e-controle.md#por-que-o-háptico-está-fraco) e [o piso de força](../05-haptica-e-controle.md#o-piso-de-força)
- [CONTRATO](../../../CONTRATO.md) (o que o jogo pode chamar; "FORJA_FX_RUMBLE nunca é nosso")

## O estado de hoje

**A saída:** `godot/scripts/forja.gd:447-449`:

```gdscript
func vibrar(l: int, forte: float, fraco: float, ms: int) -> bool:
	var k := Opcoes.escala_vibracao(l)
	return ctl.vibrar(l, forte * k, fraco * k, ms) if modulo else false
```

`som_haptica()` (`forja.gd:784-786`) toca nos atuadores sem saber se o motor
do mesmo lugar está vibrando (suspeita **e**).

**As 17 chamadas com números soltos** (fora do `forja.gd`):

| arquivo:linha | hoje (forte, fraco, ms) | o que é | a sensação |
| --- | --- | --- | --- |
| `main.gd:459` | 0,4 · 0,6 · 400 | quem venceu a noite, no pódio | `"perfeito"`, 400 |
| `main.gd:613` | 0 · 0,25 · 40 | trocar o visual no lobby | `"toque"` |
| `main.gd:617` | 0 · 0,5 · 90 | ficar pronto no lobby | `"acerto"` |
| `main.gd:677` | 0,2 · 0 · 60 | ✕ num portão fechado | `"erro"` |
| `ui/tela_opcoes.gd:48` | 0,6 · 0,6 · 160 | provar a escala nova | `"golpe"` |
| `salas/sala_jogo.gd:239` | 0 · 0,3 · 60 | pronto no aviso | `"toque"` |
| `salas/centelha.gd:338` | 0 · 0,2 · 50 | a martelada na runa | `"acerto"` |
| `salas/molde.gd:291` | 0,5 · 0,3 · 90 | o carimbo no ponto | `"perfeito"` |
| `salas/viga.gd:356` | 0,6 · 0,2 · 180 | cair da viga | `"golpe"` |
| `salas/viga.gd:421` | 0 · 0,35 · 70 | o sino acertado | `"acerto"` |
| `salas/viga.gd:458` | 0,8 · 0,4 · 120 | a martelada na pedra | `"perfeito"` |
| `salas/impacto.gd:228` | 1/0 · 0/1 · `GOLPE_MS` | o golpe de um lado (a prova às cegas) | `"golpe_esq"`/`"golpe_dir"`, `GOLPE_MS` |
| `salas/prova.gd:345` | 1/0 · 0/1 · 220 | o tiro recebido, do lado dele | `"golpe_esq"`/`"golpe_dir"` |
| `salas/prova.gd:373` | 0,6 · 0,6 · 150 | soltar a martelada | `"perfeito"` |
| `salas/prova.gd:383` | 1 · 1 · 380 | pego pela martelada | `"explosao"` |
| `salas/prova.gd:445` | 0 · 0,35 · 60 | atirar | `"toque"` |
| `salas/voz.gd:289` | 1 · 1 · 700 | o susto | `"explosao"`, 700 |

Nenhum script chama `Input.start_joy_vibration`. O `ctl.intensidade(v)`
(`forja_controles.cpp:146`, multiplica o motor em `pads.c:625`) existe mas
ninguém chama.

**O firmware** já é lido na conexão (`pads.c:229`, `p->fw = SDL_GetGamepadFirmwareVersion(gp)`)
e decide o corte pela metade da sombra (`pads.c:280`,
`p->rumble_escala_cheia = p->pid == 0x0DF2 || p->fw == 0 || p->fw >= 0x0224;`),
mas não vai para a linha do tempo (o evento `conexao` de `:283-294` não tem
`firmware`) nem para o GDScript (`info_do_pad`, `forja_controles.cpp:57-86`).
O relatório tem (`pads.c:165-166`).

**A escala do lugar** (`opcoes.gd:97-98`, `escala_vibracao`) fica salva em
`user://opcoes.cfg` e não vai para o registro (suspeita **f**).

**A bancada** (`salas/bancada.gd:17-28`, `EXPERIMENTOS`) tem cinco
experimentos; `tests/prova_da_bancada.sh:75-112` roda cada um com
`--simular=4 --robo` e confere as linhas `experimento <chave> · P<n> · <resultado>: <texto>`
do registro (o formato de `forja_bancada.cpp:95-96`).

## O alvo

Do [13](../13-arquitetura.md#as-sensações--f05), com as duas sensações
direcionais que a Prova e o Impacto já precisam hoje:

```gdscript
const SENSACOES := {
	"toque":     [0.0, 0.45,  60],   # navegar na interface
	"acerto":    [0.3, 0.6,   80],
	"perfeito":  [0.5, 0.8,  100],
	"erro":      [0.7, 0.3,  160],
	"golpe":     [1.0, 0.6,  250],   # golpe recebido, queda
	"explosao":  [1.0, 1.0,  400],   # explosão, fim de rodada
	"aviso":     [0.6, 0.0,  200],   # perigo um tempo antes
	"golpe_esq": [1.0, 0.0,  250],   # o golpe que vem da esquerda: só o motor forte
	"golpe_dir": [0.0, 1.0,  250],   # o da direita: só o motor fraco
}
func sentir(l: int, nome: String, ms := -1) -> bool
```

- `Forja.vibrar` continua existindo e **só o `forja.gd` chama**. A prova
  confere lendo os scripts.
- `sentir` grava `{"tipo": "sensacao", "jogador": l + 1, "nome": ..., "escala": ..., "ms": ...}`
  na linha do tempo (13, o registro v2: `sensacao` é da F05).
- **Rumble e háptica por áudio nunca juntos no mesmo lugar** (suspeita **e**):
  enquanto a sensação vibra, `som_haptica` daquele lugar não toca e devolve -1.
  O evento vence; o passo cede.
- **O registro da sessão** ganha as opções de cada lugar (`sessao`,
  `"evento": "opcoes"`, com `escala_vibracao` e `gatilho`), no começo e a cada
  vez que as opções fecham (suspeita **f**).
- **A conexão** grava o firmware e se o SDL manda o rumble inteiro (suspeita
  **b**): `firmware` (`"0x0224"`) e `rumble_escala_cheia` no evento `conexao`
  e no `Forja.pad(i)`.
- **O experimento `haptico`** na bancada toca cada sensação em cada controle.
  No simulado, confere o que chegou ao motor; no aparelho, pergunta
  ✕ senti / ○ não senti (é a bancada: pode perguntar).
- **O modo "seco"** (suspeita **c**) **não se implementa aqui.** Ele pede
  montar o `FORJA_FX_RUMBLE` no nosso bloco de 47 bytes, o que o CONTRATO
  proíbe hoje. A ficha escreve em 05 o protocolo da medição e deixa a decisão
  (e a emenda ao CONTRATO, se vier) para o André.

## Passos

1. **`godot/scripts/forja.gd`**, na seção das saídas (`:443`):
   ```gdscript
   ## As sensações (docs/jogo/05, o piso de força): as salas pedem pelo nome.
   const SENSACOES := { ... }  # a tabela do alvo
   var _agora := 0.0             ## o relógio do jogo (os quadros), para o motor e a háptica
   var _motor_ate := [0.0, 0.0, 0.0, 0.0]

   func sentir(l: int, nome: String, ms := -1) -> bool:
   	if not SENSACOES.has(nome):
   		push_error("sensação que não existe: %s" % nome)
   		return false
   	var s: Array = SENSACOES[nome]
   	var dur := int(s[2]) if ms < 0 else ms
   	_motor_ate[clampi(l, 0, 3)] = _agora + dur / 1000.0
   	evento("sensacao", l + 1, {"nome": nome, "escala": Opcoes.escala_vibracao(l), "ms": dur})
   	return vibrar(l, float(s[0]), float(s[1]), dur)
   ```
   Em `_process(_dt)` (`:201`): `_agora += _dt` (renomeie o parâmetro para `dt`).
   Em `som_haptica()` (`:784`), primeira linha:
   `if _agora < _motor_ate[clampi(l, 0, 3)]: return -1  # o motor vence (05, suspeita e)`.
   Atualizar o comentário de `vibrar` (`:445-446`): "só o forja.gd chama; as salas pedem `sentir`".
2. **As 17 chamadas**: trocar cada uma pela sensação da tabela de "O estado de
   hoje". Onde o retorno é usado, o `sentir` devolve o mesmo `bool`:
   `if Forja.sentir(l, "golpe_esq" if atual.y == 0 else "golpe_dir", GOLPE_MS): j[l].rumble_ok = true`
   (`impacto.gd:228`); `_saida(alvo.lugar, Forja.sentir(alvo.lugar, "golpe_esq" if da_esquerda else "golpe_dir"))`
   (`prova.gd:345`).
3. **As opções no registro**, em `forja.gd`:
   ```gdscript
   func registrar_opcoes() -> void:
   	var escala: Array = []
   	var gat: Array = []
   	for l in 4:
   		escala.append(Opcoes.escala_vibracao(l))
   		gat.append(Opcoes.GATILHO[int(Opcoes.gatilho[l])])
   	evento("sessao", 0, {"evento": "opcoes", "escala_vibracao": escala, "gatilho": gat,
   		"volume_controle": Opcoes.volume_controle, "volume_tv": Opcoes.volume_tv})
   	registrar("opções: vibração %s · gatilho %s" % [escala, gat])
   ```
   Chamar no fim de `_ready()` (depois de `aplicar_opcoes()`, `:121`) e em
   `main.gd` `_fechar_overlay()` logo depois de `Opcoes.gravar(Forja.robo)` (`:791`).
4. **O firmware**, em C:
   - `nativo/nucleo/pads.c`, no evento de `conectou()` (`:283-294`):
     `char fw[8]; snprintf(fw, sizeof(fw), "0x%04x", p->fw); ev_str(&ev, "firmware", fw); ev_bool(&ev, "rumble_escala_cheia", p->rumble_escala_cheia);`
     e, no `reg_linha` de `:295`, `" · firmware 0x%04x · rumble %s"` com
     `p->rumble_escala_cheia ? "inteiro" : "pela metade (firmware abaixo de 2.24)"`.
   - `nativo/godot/forja_controles.cpp` `info_do_pad()`: `d["firmware"]` (o
     mesmo texto) e `d["rumble_escala_cheia"] = p->rumble_escala_cheia;`.
   - `scripts/compilar.sh linux` e `scripts/compilar.sh testes` (sem o jogo aberto).
5. **O experimento `haptico`** em `godot/scripts/salas/bancada.gd`:
   - `EXPERIMENTOS["haptico"] = ["O háptico forte", "Cada sensação da tabela chega inteira ao motor de cada controle? Com o firmware e a escala de cada um."]`.
   - No `match chave` de `_process` (`:160-172`), `"haptico": fim = _haptico(dt)`.
   - `func _haptico(dt: float) -> bool`: um lugar de cada vez (`ordem`, `_vez`),
     as sensações na ordem de `Forja.SENSACOES.keys()` (`_k`), 1,5 s entre uma e
     outra (`_te`). Em `_te == 0`: `Forja.sentir(l, nome)` e
     `agora = "P%d: sensação %d de %d" % [l + 1, _k + 1, n]` (o nome não aparece:
     quem sente não sabe qual é). Dois quadros depois, com
     `var pc := Forja.percepcao(l)`:
     - simulado (`not pc.is_empty()`): `medido` se `absf(pc.forte - s[0] * escala) < 0.03 and absf(pc.fraco - s[1] * escala) < 0.03`,
       senão `falhou`; o texto: `"%s: forte %.2f · fraco %.2f · %d ms (chegou %.2f · %.2f) · firmware %s · escala %.2f"`;
     - aparelho: esperar até 2 s por ✕ (`medido`, "senti") ou ○ (`falhou`,
       "não senti") no controle do lugar; sem resposta, `nao_medido`.
   - Acrescentar `haptico` a `experimental/rodar.sh:28` (a lista padrão) e uma
     seção em `experimental/README.md` ("### `haptico` — o háptico forte").
6. **`tests/prova_da_bancada.sh`**, antes do resumo:
   ```bash
   rodar haptico haptico
   esperar haptico 36 "medido: "
   rodar haptico motores-trocados --defeitos=motores-trocados
   esperar motores-trocados 32 "falhou: "
   ```
   (4 lugares × 9 sensações; com os motores trocados, só a `explosao`, igual
   dos dois lados, passa: 4 × 8 = 32.)
7. **`docs/jogo/05-haptica-e-controle.md`**, depois de "O piso de força": uma
   seção "A medição" com (a) a tabela aplicada e onde ela mora; (b) o firmware
   agora no registro (`conexao`: `firmware`, `rumble_escala_cheia`); (d) o
   Godot não vibra (a prova lê os scripts); (e) a regra do motor que vence; (f)
   as opções no registro; e, para (c) e (g), o **protocolo do André**: rodar
   `--experimento=haptico` com um DualSense no cabo e um no rádio, anotar
   "senti/não senti" de cada sensação em `experimental/RESULTADOS.md`, e só
   então decidir se o modo seco merece emenda ao CONTRATO. A decisão fica
   **em aberto** na página.
8. **A prova**: as checagens de "Provas".

## Armadilhas

- **Não implementar o modo seco**, nem por experimento: montar o
  `FORJA_FX_RUMBLE` no bloco de 47 bytes fere o CONTRATO ("o que a sombra
  NUNCA liga", `include/forja_dualsense.h:124-129`). Sem emenda escrita, não entra.
- **O relógio de `_motor_ate`** é o do jogo (`_agora`, a soma dos quadros), não
  `Time.get_ticks_msec()`: a prova roda com `--fixed-fps 60` mais rápido que o
  tempo real, e o motor simulado para pelo relógio do jogo (`pads.c:437-443`).
- **A Galeria às cegas e o Impacto** dependem de **um motor só** no golpe: o
  `golpe_esq` tem de ser `[1.0, 0.0, …]` exato. A prova do Impacto
  (`prova_do_jogo.gd:148-153`) confere `fraco == 0.0`.
- **O robô do Impacto** (`impacto.gd:567-583`) reage à subida de `forte`/`fraco`
  acima de 0,3: todos os valores da tabela passam disso, exceto o `toque`
  (forte 0). Nenhuma sensação nova deve ter os dois motores entre 0 e 0,3.
- **A Prova** manda passos na háptica o tempo todo (`prova.gd:465`): com a
  regra do motor que vence, alguns passos não tocam durante o golpe. É o
  esperado; o `tudo_junto` não mede passo.
- **Arrays na linha do tempo:** o `Forja.evento` de hoje grava `Array` como
  texto (`forja_controles.cpp:501-503`); a F06 conserta. A checagem lê os
  valores de `saida`, que já são números.
- **Nada de `Forja.robo` novo.** O experimento não tem robô: no simulado, ele
  mede sozinho pelo que chegou ao motor (`Forja.percepcao`), sem perguntar.
- **`.uid`:** nenhum script novo.

## Não fazer

- Não emendar o CONTRATO nem montar bloco de rumble próprio.
- Não mexer na háptica por material (`nativo/som/sintese.c`, H07).
- Não mudar o formato da linha do tempo (F06).

## Pronto quando

Toda vibração do jogo sai de `Forja.sentir` com um nome da tabela; nenhum
script fora do `forja.gd` chama `Forja.vibrar`; toda saída de vibração da
sessão tem os valores de uma sensação; o firmware e as opções de cada lugar
estão na linha do tempo; e o experimento `haptico` passa na prova da bancada.

## Provas

Na sessão: `scripts/compilar.sh linux`, `scripts/compilar.sh testes`,
`bash tests/prova_do_jogo.sh` e `bash tests/prova_da_bancada.sh`.

Em `godot/testes/prova_do_jogo.gd`:

```gdscript
func _scripts(pasta: String) -> Array:
	var lista: Array = []
	for f in DirAccess.get_files_at(pasta):
		if f.ends_with(".gd"):
			lista.append(pasta.path_join(f))
	for d in DirAccess.get_directories_at(pasta):
		lista.append_array(_scripts(pasta.path_join(d)))
	return lista


## Toda vibração passa pela tabela de sensações (13): Forja.vibrar só no forja.gd,
## e nenhum outro dono do motor (o start_joy_vibration do Godot, o ctl.intensidade).
func _prova_das_sensacoes() -> void:
	var achados: Array = []
	for arq in _scripts("res://scripts"):
		var n := 0
		for linha in FileAccess.get_file_as_string(arq).split("\n"):
			n += 1
			var codigo: String = linha.split("#")[0]
			var vibra_fora := codigo.contains("Forja.vibrar(") and not arq.ends_with("/forja.gd")
			if vibra_fora or codigo.contains("start_joy_vibration") or codigo.contains(".intensidade("):
				achados.append("%s:%d" % [arq.get_file(), n])
	_esperar(achados.is_empty(), "nenhuma vibração fora da tabela de sensações (%s)" % [achados])
	var piso := {"toque": [0.0, 0.45, 60], "acerto": [0.3, 0.6, 80], "perfeito": [0.5, 0.8, 100],
		"erro": [0.7, 0.3, 160], "golpe": [1.0, 0.6, 250], "explosao": [1.0, 1.0, 400], "aviso": [0.6, 0.0, 200]}
	for nome in piso:
		_esperar(Forja.SENSACOES.get(nome, []) == piso[nome], "a sensação «%s» é a do piso de 05" % nome)
	# toda vibração que saiu na sessão é uma sensação da tabela (e as opções de fábrica: escala 1)
	var permitidos := {}
	for nome in Forja.SENSACOES:
		var s: Array = Forja.SENSACOES[nome]
		permitidos["%.2f/%.2f" % [s[0], s[1]]] = true
	var fora: Array = []
	var sensacoes := 0
	for e in _linha_do_tempo():
		if e.get("tipo") == "sensacao":
			sensacoes += 1
		if e.get("tipo") == "saida" and e.get("o") == "vibracao" and float(e.get("forte", 0.0)) + float(e.get("fraco", 0.0)) > 0.0:
			var k := "%.2f/%.2f" % [float(e.get("forte", 0.0)), float(e.get("fraco", 0.0))]
			if not permitidos.has(k):
				fora.append(k)
	_esperar(sensacoes > 20 and fora.is_empty(), "toda vibração da sessão veio da tabela (%d sensações; fora: %s)" % [sensacoes, fora.slice(0, 5)])
	var opcoes := _linha_do_tempo().filter(func(e): return e.get("tipo") == "sessao" and e.get("evento") == "opcoes")
	_esperar(not opcoes.is_empty(), "a linha do tempo tem a escala de vibração de cada lugar")
	var conexoes := _linha_do_tempo().filter(func(e): return e.get("tipo") == "conexao" and e.get("evento") == "conectou")
	_esperar(conexoes.size() >= 4 and conexoes.all(func(e): return str(e.get("firmware", "")).begins_with("0x") and e.has("rumble_escala_cheia")),
		"toda conexão registra o firmware e o rumble inteiro ou pela metade")


## O motor vence: com o lugar vibrando, a háptica por áudio dele espera.
func _prova_do_motor_que_vence() -> void:
	jogo._entrar_na_sala("caminhos", false)
	await _quadros(2)
	_esperar(Forja.som_tem(0, Forja.PAPEL_HAPTICA), "Caminhos: o P1 tem a háptica (a placa virtual)")
	Forja.sentir(0, "golpe")
	_esperar(Forja.som_haptica(0, "pulso", "pulso") == -1, "com o motor do P1 vibrando, a háptica dele não toca")
	await _quadros(20)
	_esperar(Forja.som_haptica(0, "pulso", "pulso") != -1, "o motor parou: a háptica volta")
	jogo.sala.terminar()
	var q := 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
```

(`_linha_do_tempo()` é o da F01. Chame `_prova_do_motor_que_vence()` depois
de `_prova_do_percurso()` e `_prova_das_sensacoes()` no fim de `_ready()`.)

## Para o André (local)

- `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh` (o `OPCOES_DE_TESTE`
  confere a vibração do P2 em 0%).
- `./run-local.sh -- --experimento=haptico` com um DualSense no cabo e um no
  rádio: responder ✕ senti / ○ não senti a cada pulso, sem olhar a tela, e
  copiar as linhas `experimento haptico` do registro para
  `experimental/RESULTADOS.md` (com o firmware que aparece em cada uma).
- Jogar três salas e dizer se cada evento se sente (martelada, carimbo, queda,
  golpe, susto).
- A decisão do modo seco (suspeita c): com as anotações na mão, decidir se vale
  a emenda ao CONTRATO. Enquanto não houver emenda, nada muda.

## Ao terminar

- No [quadro](README.md), a linha da F05: estado **feito** (com o commit).
- Se `"golpe_esq"`/`"golpe_dir"` e o registro do firmware ainda não estiverem
  no 13 ("As sensações", "O registro v2"), acrescentar no mesmo commit.
- Commit sugerido: `feat: o háptico forte — a tabela de sensações com o piso, o firmware e as opções no registro`

## O que foi feito (leva 1, o-controle)

- **A tabela e o piso** (`godot/scripts/forja.gd`): `Forja.SENSACOES` com as nove sensações (as sete
  do piso de 05 mais `golpe_esq` e `golpe_dir`, um motor só) e `Forja.sentir(lugar, nome, ms)`. As 17
  chamadas com número solto das salas, do lobby, do pódio e das Opções passaram a pedir o nome; só o
  `forja.gd` chama `Forja.vibrar`. Cada sensação grava `sensacao` na linha do tempo, com a escala do lugar.
- **O motor vence** (suspeita e): enquanto a sensação de um lugar vibra, no relógio do jogo, a
  `som_haptica` do mesmo lugar não toca e devolve -1.
- **O firmware e as opções no registro** (suspeitas b e f): o evento `conexao` ganhou `firmware` e
  `rumble_escala_cheia` (e a linha do registro e o `Forja.pad(i)`); a linha `sessao` com
  `"evento": "opcoes"` grava a escala de vibração e o gatilho de cada lugar, no começo e quando as
  Opções fecham.
- **O experimento `haptico`** na bancada: cada sensação em cada controle; no simulador mede o que
  chegou ao motor, no aparelho pergunta senti ou não senti. `docs/jogo/05-haptica-e-controle.md` ganhou
  «A medição», com o protocolo do André para as suspeitas c e g; o modo seco **não** foi implementado
  (é a F10, e o CONTRATO ainda o proíbe).

**Provas:** `bash tests/prova_do_jogo.sh` verde (as duas rodadas); `bash tests/prova_da_bancada.sh` verde
(`haptico` 36 de 36 medidos; com `motores-trocados`, 32 de 36 falham, só a `explosao` passa).
Mordidas medidas: tirar a regra do motor reprova «com o motor do P1 vibrando, a háptica dele não toca»;
uma `Forja.vibrar` solta na Viga reprova «nenhuma vibração fora da tabela de sensações» (e aponta o
`viga.gd:357`). A prova tinha um erro de tipo (`var vibra_fora :=` sem tipo) que o primeiro rodar pegou.

**Para o André (local):** o que está em «Para o André (local)» acima, em especial o experimento
`haptico` no cabo e no rádio e a decisão do modo seco, que agora tem a [F10](F10-o-rumble-seco.md).
