# F04 — O P1 da tela é o controle P1

**Sprint:** F · **Tamanho:** M · **Depende de:** F00, F01

## Por quê

Na noite de teste o P1 da tela não era o controle com o LED de P1: o lugar só
existe depois do ✕ no lobby, e até lá o SDL acende as luzinhas na ordem dele.
E dentro da Galeria e da Prova as luzinhas viram munição e a barra de luz vira
cor de equipe. O número tem de valer desde a conexão e nunca se apagar.

## Ler antes

- [13 — A identidade](../13-arquitetura.md#a-identidade--f04)
- [05 — A identidade P1..P4](../05-haptica-e-controle.md#a-identidade-p1p4)
- [CONTRATO — Identidade do pad](../../../CONTRATO.md#identidade-do-pad)

## O estado de hoje

**`nativo/nucleo/pads.c`** (a mesa; `pads.h:89-101` tem `Pad.slot` e `Slot`):

- `conectou()` (`:193-328`) abre o gamepad, preenche o `Pad` com `p->slot = -1`
  e só dá lugar a quem **volta** (um slot desconectado com a mesma
  assinatura, `:304-327`). Quem chega pela primeira vez fica sem player index
  do jogo (o SDL põe o dele) e sem a cor do lugar.
- `pads_entrar()` (`:506-575`) escolhe o lugar no ✕ do lobby, nesta ordem:
  ```c
    /* primeiro, um lugar de quem caiu com a mesma assinatura */
    ...
    /* depois, um lugar vazio */
    for (int s = 0; s < MAX_JOGADORES && alvo < 0; s++)
      if (!a->pads.slot[s].ocupado)
        alvo = s;
    /* por fim, qualquer lugar de quem caiu */
    for (int s = 0; s < MAX_JOGADORES && alvo < 0; s++)
      if (a->pads.slot[s].ocupado && a->pads.slot[s].pad < 0)
        alvo = s;
  ```
  A terceira regra (`:540-543`) dá a um controle estranho o lugar de quem caiu.
  O espelho (o mesmo ✕ por dois caminhos, `:515-528`) é detectado aqui.
- `pads_sair()` (`:577-592`) tira o lugar e chama `SDL_SetGamepadPlayerIndex(p->gp, -1)`.
- `pad_luz_do_slot()` (`:671-675`) e `pad_leds_do_slot()` (`:773-786`) usam
  `p->slot` e não fazem nada sem ele.

**`nativo/godot/forja_controles.cpp`**: `info_do_pad()` (`:57-86`) devolve
`d["lugar"] = p->slot`; `ForjaControles::lugar()` (`:176-191`);
`ForjaControles::entrar()` (`:193`); `pad_segura` já existe no C++ (`:206`, ligado em `:618`),
mas o `forja.gd` não o expõe.

**`godot/scripts/main.gd`** `_quadro_lobby()` (`:586-643`): quem não tem lugar
entra com ✕ (`:589-594`, `Forja.entrar(int(p.pad))`). `_todos_entram()`
(`:203-207`) faz o mesmo para os argumentos.

**`godot/scripts/ui/cartao_jogador.gd:33-38`**: o lugar vazio mostra o rótulo em
`Tema.MUDO` e a dica "entrar".

**As salas que apagam a identidade:**
- `salas/galeria.gd:198-202` `_leds(l, quantos)`: a munição nas luzinhas
  (chamado em `:295`, `:316`, `:387-393`, `:463`).
- `salas/prova.gd:225-227` `_mostrar_municao()`: a munição nas luzinhas; e
  `:242-264` `_atualizar_luz()`: `var c: Color = LUZ_EQUIPE[e.equipe]`, com
  `k = 0.04` derrubado e `0.06`/`0.25` por um fio.
- `salas/impacto.gd:184-186` `_cor_da_vida()`: `k := 0.12 + 0.88 * vida` (quase
  apaga).
- `salas/voz.gd:289-290` `_susto()`: a barra vermelha por `SUSTO_S` (1,9 s,
  `:33`), e a cor do lugar só volta em `:445-447`.
- As perguntas de luzinhas e de cor (`galeria.gd:446`, `prova.gd:544-574`,
  `impacto.gd:302`) já só existem no Modo bancada (F01).

**A prova** (`godot/testes/prova_do_jogo.gd:73-88`) aperta ✕ no título e depois
✕ nos simulados 0, 1, 2 e 3, **nessa ordem**, e só então confere player index,
luzinhas e cor. A Prova confere `"a luz é a da %s"` com `SalaProva.LUZ_EQUIPE`
(`:262-266`). O simulador pendura os quatro controles na ordem 0..3, com os
nomes `"DualSense simulado 1".."4"` (`nativo/nucleo/simulador.c:210-211`), e
`simulador_cabo(sim, ligado)` (`:260`) tira e põe o cabo.

## O alvo

Do [13](../13-arquitetura.md#a-identidade--f04) e das regras de
[05](../05-haptica-e-controle.md#a-identidade-p1p4):

- **Na conexão**, o controle recebe o primeiro lugar livre — a **reserva** —,
  com `SDL_SetGamepadPlayerIndex`, as luzinhas e a cor do lugar na hora. Sem
  lugar livre, ele espera com o player index -1 (luzinhas apagadas).
- **O ✕ do lobby confirma** a reserva: o lugar vira ocupado. Não escolhe.
- **Quem caiu reencontra o lugar** pela assinatura (como hoje); um controle
  estranho **não herda** o lugar de ninguém.
- **Trocar de lugar é um gesto:** no lobby (a construção, até a G02), segurar
  Botão ◻ por um segundo, **antes de confirmar**, passa a reserva para o
  próximo lugar livre.
- **Nada apaga a identidade no jogo:** as luzinhas ficam no padrão do lugar; a
  barra de luz fica na cor do lugar (pode escurecer, nunca abaixo de 30% do
  brilho; um piscar de outra cor dura no máximo 0,5 s e volta). A cor de
  equipe vai para o mundo (o disco no chão da Prova, que já existe). **No Modo
  bancada**, as perguntas de luzinhas e de cor continuam: é a ferramenta que
  valida esses recursos.

A API nova (acrescente ao 13 no mesmo commit, se ainda não estiver lá):

```c
/* pads.h */
int reserva;          /* Pad: o lugar dado na conexão, -1 nenhum; o ✕ confirma */
int reservado_por;    /* Slot: o pad que reservou este lugar, -1 nenhum */
int pad_lugar(const Pad *p);                     /* slot, ou a reserva, ou -1 */
int pads_trocar_reserva(struct Forja *a, int pad); /* o próximo lugar livre; devolve a reserva */
```

```gdscript
# forja.gd
func trocar_lugar(indice: int) -> int      # ctl.trocar_lugar: a reserva nova, ou a mesma
func pad_segura(indice: int, botao: int) -> bool
# Forja.pad(i)["reserva"]: int; Forja.lugar(l)["reservado"]: bool
```

## Passos

1. **`nativo/nucleo/pads.h`**: `int reserva;` no `Pad` (depois de `slot`,
   `:89`), `int reservado_por;` no `Slot` (`:94-101`), e as duas funções da API.
2. **`nativo/nucleo/pads.c`**:
   - `pads_iniciar()` (`:52-59`): `a->pads.slot[s].reservado_por = -1`.
   - `int pad_lugar(const Pad *p)`: `p->slot >= 0 ? p->slot : p->reserva`.
   - `static bool reservar(Forja *a, int idx)`: o primeiro `s` com
     `!slot[s].ocupado && slot[s].reservado_por < 0`; sem nenhum,
     `SDL_SetGamepadPlayerIndex(p->gp, -1)` e `return false`. Com um:
     `p->reserva = s; slot[s].reservado_por = idx;`
     `SDL_SetGamepadPlayerIndex(p->gp, s); pad_luz_do_slot(a, p); pad_leds_do_slot(a, p);`,
     e na linha do tempo `ev_iniciar(&ev, &a->lt, "conexao", s + 1)` com
     `ev_str(&ev, "evento", "reservou")`, `ev_int(&ev, "lugar", s)`,
     `ev_str(&ev, "nome", p->nome)`; e no registro `"%s reservou %s"`.
   - `static void soltar_reserva(Forja *a, Pad *p)`: se `p->reserva >= 0`,
     `slot[p->reserva].reservado_por = -1; p->reserva = -1`.
   - `conectou()`: `p->reserva = -1` junto de `p->slot = -1` (`:212`); no fim
     (depois do bloco da volta, `:327`): `if (p->slot < 0) reservar(a, livre);`.
   - `desconectou()` (`:330`): `soltar_reserva(a, p)` antes do `SDL_memset` de `:354`.
   - `pads_entrar()`: no espelho (`:521-527`), antes do `return -1`:
     `soltar_reserva(a, p); SDL_SetGamepadPlayerIndex(p->gp, s); pad_luz(a, p, LUZ_DO_LUGAR[s]);`
     (os dois caminhos do mesmo aparelho dizem o mesmo lugar). Na escolha do
     `alvo`: (1) o lugar de quem caiu com a mesma assinatura (fica); (2) a
     reserva, se `p->reserva >= 0 && !slot[p->reserva].ocupado`; (3) o primeiro
     `!ocupado && reservado_por < 0`. **Apagar** a regra de `:540-543`. Antes
     de ocupar: `soltar_reserva(a, p)`.
   - `pads_sair()` (`:577-592`): no lugar de `SDL_SetGamepadPlayerIndex(p->gp, -1)`,
     o pad volta a reservar o mesmo lugar: depois do `SDL_memset(sl, ...)` e de
     `sl->pad = -1`, `sl->reservado_por = <índice do pad>; p->reserva = slot;`
     (a luz e as luzinhas do lugar já saíram em `pads_silencio`).
   - `pads_atualizar()` (`:426`), no fim: para cada pad `usado` com `slot < 0`,
     `reserva < 0` e `espelho_de < 0`, `reservar(a, i)` (um lugar vagou).
   - `pads_trocar_reserva(a, idx)`: se `p->slot >= 0`, devolve `p->slot` sem
     mexer; senão, procura de `p->reserva + 1` em diante (em volta, os quatro)
     o primeiro livre e não reservado; achando, solta a antiga, reserva a nova
     (mesmos passos de `reservar`, com `"evento": "trocou"`) e devolve o lugar.
   - `pad_luz_do_slot()` (`:671`) e `pad_leds_do_slot()` (`:773`): usar
     `int l = pad_lugar(p); if (l < 0) return false;` no lugar de `p->slot`.
3. **`nativo/godot/forja_controles.cpp` e `.h`**: `d["reserva"] = p->reserva;`
   em `info_do_pad()`; `d["reservado"] = sl->reservado_por >= 0;` em
   `lugar()`; `int ForjaControles::trocar_lugar(int indice)` →
   `pads_trocar_reserva(FORJA, indice)`, com `METODO(trocar_lugar, "indice");`
   perto de `:614-615` (onde estão `entrar` e `sair`). Compilar:
   `scripts/compilar.sh linux` (sem Godot rodando).
4. **`godot/scripts/forja.gd`**, na seção dos lugares (`:287-345`):
   `trocar_lugar(indice)` e `pad_segura(indice, botao)` (o molde de
   `pad_apertou`, `:365-366`).
5. **`godot/scripts/main.gd`** `_quadro_lobby()`: `var _quadrado_t := {}` (pad → s);
   antes do laço de `:589`:
   ```gdscript
   	for p in Forja.pads():
   		var i := int(p.pad)
   		if int(p.lugar) >= 0 or not Forja.pad_segura(i, Forja.QUADRADO):
   			_quadrado_t.erase(i)
   			continue
   		_quadrado_t[i] = float(_quadrado_t.get(i, 0.0)) + dt
   		if float(_quadrado_t[i]) >= 1.0:
   			Forja.trocar_lugar(i)
   			_quadrado_t[i] = -INF  # só de novo depois de soltar
   ```
6. **`godot/scripts/ui/cartao_jogador.gd:33-38`**: com `info.get("reservado")`,
   o rótulo na cor do lugar (`cor_id`) e, além da dica de entrar,
   `Glifo.dica(..., "quadrado", "segure para trocar", ...)`.
7. **As salas** (fora do Modo bancada; com a bancada, como hoje):
   - `galeria.gd:198` `_leds()`: primeira linha `if not Forja.bancada: return`.
     E `status()` (`:598-602`), com `int(e.passo) == ATIRAR`:
     `return "%d balas" % (int(e.balas_mg) if int(e.arma) == METRALHADORA else int(e.balas))`.
     Em `dar_vereditos()` (`:497-505`), fora da bancada, o `"sdl_aceitou"` do
     `leds_jogador` é `true` (a sala não pediu as luzinhas): o relatório diz
     "nenhuma pergunta de munição respondida", e não "o SDL recusou".
   - `prova.gd:225` `_mostrar_municao()`: `if not Forja.bancada: return` (o
     status já mostra as balas, `:743`). `_atualizar_luz()` (`:242-264`):
     `var c: Color = Forja.cor_do_lugar(e.lugar)`, e os brilhos `fora` 0,3,
     por um fio 0,6/0,35, vida 2 0,7, vida 3 1,0. O vermelho do golpe
     (`luz_pisca`, 0,16 s) fica. `LUZ_EQUIPE` continua no disco, nas balas e
     nas faíscas (`:189`, `:322`, `:353`).
   - `impacto.gd:185`: `var k := 0.3 + 0.7 * clampf(float(j[l].vida), 0.0, 1.0)`.
   - `voz.gd`: no estado `SUSTO` (`:443-449`), `if t_estado >= 0.4` e a luz
     ainda vermelha, `Forja.luz_do_lugar(l)` para cada lugar (uma vez).
8. **A prova**: as checagens de "Provas".

## Armadilhas

- **Compilar o módulo com o jogo fechado** (o Godot segura o `.so`). Depois
  de `scripts/compilar.sh linux`, rode também `scripts/compilar.sh testes`.
- **O SDL dá um player index sozinho** na chegada (o comentário de
  `simulador.c:236-237`). Por isso a reserva manda o índice logo em seguida, e
  quem fica sem lugar recebe -1.
- **O 5º controle** fica sem reserva e sem luzinhas; quando um lugar vaga, o
  `pads_atualizar` dá a ele.
- **O espelho** também reserva um lugar na conexão (ainda não se sabe que é
  espelho). Só no ✕ ele é pego; então a reserva dele sai e ele recebe o índice
  e a cor do original. Até o ✕, as luzinhas desse aparelho podem piscar entre
  os dois lugares: registre, não trate.
- **O controle que cai no meio da sala** (`prova_de_poucos`, `CABO=1`) continua
  voltando pelo bloco da volta de `conectou()` — que roda **antes** da reserva.
  Não inverta a ordem.
- **O `jogador` da linha do tempo** das saídas de um pad reservado mas não
  confirmado continua 0 (o `ev_saida` usa `p->slot`, `pads.c:138`). A F06 troca
  por `pad_lugar(p)`; aqui, não.
- **Nada de `Forja.robo` novo** (13, paridade). A prova aperta e segura pelo
  simulador (`Forja.ctl.simulador_botao`, `simulador_cabo`).
- **CONTRATO:** o índice é o player index 0..3, nunca endereço; nenhum
  relatório `0x31`; o `SDL_SetGamepadPlayerIndex` é o caminho oficial.

## Não fazer

- Não criar a tela de construção (G02): o gesto do ◻ vive no lobby de hoje.
- Não refazer a Galeria nem a Prova como jogo (seções M e Q).
- Não mudar o formato da linha do tempo (F06).

## Pronto quando

Ligando quatro controles em qualquer ordem, o número da tela é o das luzinhas
de cada controle antes de qualquer botão; o ✕ só confirma; e, sem
`--bancada`, as luzinhas e a cor do lugar não se perdem dentro de nenhuma sala.

## Provas

Na sessão: `scripts/compilar.sh linux`, `scripts/compilar.sh testes` e
`bash tests/prova_do_jogo.sh`.

Em `godot/testes/prova_do_jogo.gd`:

```gdscript
## O pad (o índice do módulo) do controle simulado `s` (0..3).
func _pad_do_sim(s: int) -> int:
	for p in Forja.pads():
		if str(p.nome) == "DualSense simulado %d" % (s + 1):
			return int(p.pad)
	return -1


func _perc_do_sim(s: int) -> Dictionary:
	return Forja.ctl.percepcao(_pad_do_sim(s))


## Os simulados `sims`, tirados e postos de volta nessa ordem.
func _religar(sims: Array) -> void:
	for s in sims:
		Forja.ctl.simulador_cabo(s, false)
	await _quadros(4)
	for s in sims:
		Forja.ctl.simulador_cabo(s, true)
		await _quadros(4)


## A mesma cor, com outro brilho (a barra de luz escurece com a vida, mas não muda de cor).
func _mesmo_tom(a: Color, b: Color) -> bool:
	var ma := maxf(a.r, maxf(a.g, a.b))
	var mb := maxf(b.r, maxf(b.g, b.b))
	if ma < 0.01 or mb < 0.01:
		return false
	return absf(a.r / ma - b.r / mb) < 0.08 and absf(a.g / ma - b.g / mb) < 0.08 and absf(a.b / ma - b.b / mb) < 0.08
```

Em `_prova_do_percurso()`, logo depois de `"o jogo abre no título"` (`:71`):

```gdscript
	for s in 4:
		var p := _perc_do_sim(s)
		_esperar(int(p.get("player_index", -9)) == s and int(p.get("leds_jogador", 0)) == Forja.LEDS_DO_LUGAR[s]
			and (p.get("luz", Color.BLACK) as Color).is_equal_approx(Forja.cor_do_lugar(s)),
			"conexão: o simulado %d já é P%d, com as luzinhas e a cor, antes de qualquer botão" % [s + 1, s + 1])
	# conectar na ordem 3, 2, 1 (os simulados de índice 2, 1 e 0): P1, P2 e P3
	await _religar([2, 1, 0])
	for par in [[2, 0], [1, 1], [0, 2]]:
		var s: int = par[0]
		var l: int = par[1]
		_esperar(int(Forja.pad(_pad_do_sim(s)).get("reserva", -9)) == l and int(_perc_do_sim(s).get("player_index", -9)) == l
			and int(_perc_do_sim(s).get("leds_jogador", 0)) == Forja.LEDS_DO_LUGAR[l],
			"ordem trocada: o simulado %d, o %dº a chegar, é P%d" % [s + 1, l + 1, l + 1])
	await _religar([0, 1, 2])  # de volta: o simulado N é o PN
```

No lobby (depois de `"✕ no título leva ao lobby"`, `:75`), antes dos ✕:

```gdscript
	# ◻ segurado um segundo, antes de confirmar: a reserva passa ao próximo lugar livre
	Forja.ctl.simulador_cabo(1, false)  # o P2 vaga
	await _quadros(4)
	Forja.ctl.simulador_botao(3, Forja.QUADRADO, true)
	await _quadros(70)
	Forja.ctl.simulador_botao(3, Forja.QUADRADO, false)
	await _quadros(2)
	_esperar(int(Forja.pad(_pad_do_sim(3)).get("reserva", -9)) == 1 and int(_perc_do_sim(3).get("player_index", -9)) == 1,
		"◻ por um segundo: o simulado 4 passa de P4 para P2, o próximo livre")
	Forja.ctl.simulador_cabo(3, false)
	await _quadros(4)
	await _religar([1, 3])  # o simulado 2 volta a P2 e o 4 a P4
```

E os ✕ do lobby (`:76-79`) em ordem **inversa**, conferindo que confirmam:

```gdscript
	for s in [3, 2, 1, 0]:
		await _aperta(s, Forja.CRUZ)
	await _quadros(4)
	for s in 4:
		_esperar(Forja.pad_do_lugar(s) == _pad_do_sim(s), "o ✕ confirma: o simulado %d é P%d, mesmo apertando por último" % [s + 1, s + 1])
```

Na Prova (`:262-266`), trocar a conferência da equipe pela do lugar:
`_esperar(_mesmo_tom(luz, Forja.cor_do_lugar(l)), "Prova P%d: a luz é a do lugar, não a da equipe" % (l + 1))`.

Em `_termina_a_sala(sala, features)`, dentro do laço de espera (a cada 10
quadros), só sem a bancada:

```gdscript
		if not Forja.bancada:
			for l in 4:
				var p := _perc(l)
				amostras += 1
				leds_ok = leds_ok and int(p.get("leds_jogador", 0)) == Forja.LEDS_DO_LUGAR[l] and int(p.get("player_index", -9)) == l
				if not _mesmo_tom(p.get("luz", Color.BLACK), Forja.cor_do_lugar(l)):
					fora_do_tom += 1
	# (depois do laço)
	if not Forja.bancada:
		_esperar(leds_ok, "%s: as luzinhas e o player index de cada um nunca mudaram" % id)
		_esperar(fora_do_tom * 4 <= amostras, "%s: a barra de luz ficou na cor do lugar (%d de %d amostras fora)" % [id, fora_do_tom, amostras])
```

(`var amostras := 0`, `var fora_do_tom := 0`, `var leds_ok := true` no começo
da função. A folga de um quarto cobre os piscares vermelhos de golpe.)

A linha do tempo, no fim (com o `_linha_do_tempo()` da F01):

```gdscript
	var reservas := _linha_do_tempo().filter(func(e): return e.get("tipo") == "conexao" and e.get("evento") == "reservou")
	_esperar(reservas.size() >= 4 and reservas.slice(0, 4).map(func(e): return int(e.get("lugar", -1))) == [0, 1, 2, 3],
		"linha do tempo: os quatro reservaram P1..P4 na conexão, na ordem")
```

## Para o André (local)

- `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh` (em especial o `CABO=1`).
- Com quatro DualSense: ligar na ordem 3, 1, 4, 2 com o jogo aberto no título e
  conferir, **antes de apertar qualquer botão**, que as luzinhas de cada um
  dizem P1, P2, P3, P4 na ordem em que chegaram, e que a barra de luz tem a cor
  do cartão. No lobby, segurar ◻ num controle ainda não confirmado e ver as
  luzinhas mudarem para o próximo lugar livre.
- Jogar a Galeria e A Prova sem `--bancada`: as luzinhas nunca viram munição e
  a barra nunca vira a cor da equipe.

## Ao terminar

- No [quadro](README.md), a linha da F04: estado **feito** (com o commit).
- Se a API da reserva ainda não estiver no 13 ("A identidade — F04"),
  acrescentá-la no mesmo commit (a regra do 13).
- Commit sugerido: `feat: o lugar nasce na conexão — player index, luzinhas e cor antes do primeiro botão`
