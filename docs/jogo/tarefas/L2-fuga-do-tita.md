# L2 — Fuga do Titã

**Sprint:** L · **Slot:** S04_J17 · **Tamanho:** M · **Estimativa:** US$ 1,5 · **Depende de:** H04, H08, F09, L1

## Por quê

O coop da seção. Um vagão desgovernado, um titã atrás, e a caldeira que só
anda se cada um põe carvão na sua vez. A vez de cada um **só a mão sabe**: o
passo do titã chega no controle de quem é o próximo, uma batida antes, e fica
mais forte quanto mais perto ele está. No meio, a ordem se embaralha a cada
compasso e contar não adianta mais: é sentir e pôr carvão. O verbo da
vibração aqui é **revezar** — ela passa de mão em mão como um bastão.

## Ler antes

- [O índice da seção](L-o-impacto.md) e a [L1](L1-o-cerco.md) (o cenário comum, o `_joga_o_minigame` da prova)
- [O molde de minigame](molde-de-minigame.md) e o [kit](../13-arquitetura.md#o-kit-do-minigame--h04)
- [Todo minigame fecha](F03-todo-minigame-fecha.md) (o `coop` e o `coop_venceu`)
- `godot/testes/minigame_de_prova.gd` (o jeito do `_fora` e do robô)

## A ficha de dados

`godot/scripts/minigames/s04/fuga_do_tita.gd`:

```gdscript
extends Minigame
## Fuga do Titã (S04_J17) — os quatro num vagão, o titã atrás. Cada batida
## tem um dono; o passo do titã chega na mão do dono uma batida antes (só o
## motor forte), e ele põe carvão na caldeira apertando R2 na batida. Carvão
## no tempo afasta o titã; o titã chega mais perto a cada compasso. No pico,
## a ordem dos donos se embaralha a cada compasso; na saída, a vez cai nas
## colcheias.
##
## A falha: o titã encosta, sacode o vagão e arranca a grade de quem errou; o
## cavaleiro cai sentado.
## O vencedor: coop — o vagão cruza a ponte (todos vencem) ou o titã alcança;
## quem pôs mais carvão no tempo leva o destaque.
## O alto-falante do dono: a pá que raspa ("clique"); o golpe da grade ("golpe").
## O registro mede: cada passo mandado (lado, ok) e a pá na vez certa; a pá na
## vez de outro é a vibração que vazou.
## O robô: sente o passo (só o motor forte) e aperta R2 na batida seguinte;
## quando não acerta, 250 ms tarde.
## Com menos de quatro: as batidas se dividem; sozinho, só as pares; as
## colcheias da saída só com três ou mais.
## A régua: (1) "Corra!" com a caldeira acesa e o titã atrás; (2) sim: a vez
## é só da mão; (3) não pergunta nada.

const FICHA := {
	"slot": "S04_J17",
	"titulo": "Fuga do Titã",
	"verbo": "Corra!",
	"genero": "coop",
	"icone": "rumble_esquerdo",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S04_J17",
	"duracao": 100.0,
	"fim": "meta_coletiva",
	"sensacoes": ["aviso", "golpe_esq", "golpe", "acerto", "perfeito", "erro", "explosao"],
	"material": "madeira",
	"microjogo": {"verbo": "Corra!", "segundos": 6.0},
}

const PONTOS := [0, 40, 70, 100]  ## ERRO, BOM, OTIMO, PERFEITO
## O quanto a pá afasta o titã, por julgamento (com quatro; com k, vezes 4/k).
const GANHO := [0.0, 0.008, 0.014, 0.02]
## O quanto o titã chega a cada compasso: entrada, pico, saída.
const AVANCO := [0.045, 0.065, 0.055]
const GRADE := 0.02  ## a falha também dá ao titã este tanto
const DISTANCIA_INICIAL := 0.6
const PERTO := 0.35  ## abaixo disto, o passo é o golpe_esq (mais forte) e o gatilho pesa mais
const PERIGO := 0.25  ## abaixo disto, a barra de luz pulsa na batida
const PONTE_S := 90.0  ## a ponte aparece (em segundos de música)
const R2_APERTA := 0.6
const R2_SOLTA := 0.3
const Z_TITA := Vector2(-7.0, -1.2)  ## o z do titã longe (distância 1) e encostado (0)
```

## Como se joga

**O dono da vez.** O compasso `c` tem as batidas `4c` a `4c+3`; o compasso 0
é a contagem de entrada (a primeira vez é a batida 4). `lista` são os
`presentes()` em ordem crescente, `k = lista.size()`.

| parte | música (`progresso()` do kit) | a vez | com poucos |
| --- | --- | --- | --- |
| entrada | 0–33 s | batida `b` → `lista[b % k]`, sempre na mesma ordem | sozinho, só as pares |
| **pico** | 33–66 s | a `ordem` do compasso é `lista` embaralhada pelo `rng` (Fisher-Yates com `rng.randi_range`, nunca `Array.shuffle`); batida `4c + i` → `ordem[i % k]`; se `ordem[0]` for o dono da batida `4c − 1`, gire a `ordem` uma casa | sozinho, só as pares, sem embaralhar |
| saída | 66–100 s | com `k >= 3`: as oito colcheias `4c + i * 0.5` → `ordem[i % k]` (embaralhada, com a mesma regra da virada); com `k <= 2`: como no pico | — |

A regra que vale sempre: **o mesmo lugar nunca tem duas vezes a menos de
uma batida** (na saída, com três ou mais, a menor distância é 1,5 batida). A
pista de uma vez não pode cair na sensação do kit da vez anterior do mesmo
controle. Quem está errando (`Ritmo.simples[l]`) perde as vezes das
colcheias ímpares (`i` ímpar) da saída; elas ficam sem dono.

**A nota:** `{"n": int(round(b * 2)), "b": b, "t": Ritmo.t_da_batida(b), "avisada": false, "peso": 0.5 se o compasso é de colcheias, senão 1.0}`,
com `nova_nota(l, n, t)`. O compasso é gerado quando `Ritmo.batida() >= 4c − 4`.

**A pista** (o passo do titã), em `b − 1`: `Forja.sentir(l, "aviso" if distancia > PERTO else "golpe_esq", _ms_da_pista())`,
com `_ms_da_pista() = int(60000.0 / Ritmo.bpm * 0.4)` (0,4 batida: duas
pistas de colcheia não se emendam). O registro:
`Forja.evento("pista", l + 1, {"slot": id, "n": n, "evento": "mandou", "via": "rumble", "o_que": "esq", "ok": ok})`.
Nenhum sinal na tela diz de quem é a vez.

**A pá:** R2 passando de `R2_APERTA` (0,6) para cima, rearmando abaixo de
`R2_SOLTA` (0,3). Casa com a nota do lugar a até `Ritmo.JANELA_BOM` do tempo
dela → `julgar_toque(l, t, n)` (não é perigo físico: sem folga). Sem nota
perto → **pá fora da vez**: o carvão cai no trilho (`Efeitos.faiscas(self, pos_da_pa, Color("#3a3a44"), 8, 0.4)`), nada de ponto
nem de erro, e `Forja.evento("entrada", l + 1, {"slot": id, "o": "fantasma", "golpe_de": "P%d" % (dono_mais_perto + 1)})`.
A nota que passa de `t + FOLGA_PERDIDA` (o kit) sem pá é `nota_perdida(l, n)`.

**A distância** (0 encostado, 1 longe), começa em 0,6:

- a cada compasso novo (quando `Ritmo.batida()` passa de `4c`, `c >= 1`):
  `distancia -= AVANCO[parte]`;
- a cada pá julgada: `distancia += GANHO[julgamento] * 4.0 / k` (na saída
  com colcheias, `* 0.5` a mais: são o dobro de vezes);
- a cada falha: `distancia -= GRADE`;
- presa entre 0 e 1. **Chegou a 0:** o titã alcança — `coop_venceu = false`,
  todos `acabou`, o titã agarra o vagão (abaixo).

**Os pontos** (o destaque): `marcar(l, PONTOS[julgamento])` (o item, `Itens.pontos_do_acerto`, o kit já aplica no `julgar_toque`: H08).

**O momento:** aos 33 s a ordem se embaralha (o titã ruge: `Som.tocar("golpe", Vector3(0, 3, -6), 0.0)`
e todos sentem `explosao` uma vez); aos `PONTE_S` a ponte sobe na frente.

## O cenário

- `CenarioDoImpacto.montar(self)` (o `coop` vem do gênero da FICHA: H08).
- A câmera: `camera_pos = Vector3(0, 7.2, 11.5)`, `camera_olhar = Vector3(0, 1.2, -1.5)`
  (o titã atrás tem de caber).
- **O vagão:** o estrado `Kit.caixa(self, Vector3(15.0, 0.3, 2.6), Vector3(0, 0.35, Z_JOGADOR), Kit.material(Color("#6b4526"), 0.0, 0.85))`;
  seis rodas `Kit.cilindro(self, 0.4, 0.2, ...)` deitadas (`rotation.x = PI * 0.5`)
  em x = −6, 0, 6 e z = `Z_JOGADOR ± 1.35`, `Color("#3a3a44")`; nos cantos,
  `Kit.peca(self, "wood-support", ...)` na escala 1,0.
- **A raia** de cada lugar em cima do estrado: `raia(l).position.y = 0.5`;
  `posicionar(l)`, depois `jogador(l).position.y = 0.55`, `rotation.y = 0.0`
  (de frente para a caldeira e a câmera) e `preso = true`.
- **A grade** de cada lugar: `Kit.caixa(self, Vector3(1.8, 0.5, 0.08), Vector3(RAIAS[l], 0.95, Z_JOGADOR + 1.25), madeira)`
  com duas estacas `Kit.caixa(Vector3(0.1, 0.6, 0.1))` nas pontas.
- **O carvão:** `Kit.peca(self, "rocks", Vector3(RAIAS[l] + 0.8, 0.5, Z_JOGADOR - 0.6), 0.0, 0.8)` por lugar.
- **A caldeira**, no meio do vagão, na frente: `Kit.peca(self, "barrel", Vector3(0, 0.5, Z_JOGADOR + 0.2), 0.0, 1.6)`,
  a chaminé `Kit.caixa(self, Vector3(0.35, 1.4, 0.35), Vector3(0, 1.9, Z_JOGADOR + 0.2), ferro)`
  e o fogo: uma `OmniLight3D` `#ff7a2a` em `(0, 1.0, Z_JOGADOR + 0.9)`,
  energia `0.6 + 2.0 * distancia`, alcance 5.
- **Os dormentes** (o chão que corre): dez `Kit.caixa(self, Vector3(16.0, 0.06, 0.3), ..., madeira escura #3a2a24)`
  no chão, com `z = -8.0 + fposmod(k * 1.6 + Ritmo.batida() * 0.8, 16.0)` a
  cada quadro — pela batida, nunca somando `dt`.
- **O titã** (peças do kit mais um brilho, na proporção dos bonecos:
  cabeça grande): um `Node3D` `tita` com duas pernas `Kit.peca(tita, "column", (±1.2, 0, 0), 0.0, 2.4)`,
  o tronco `Kit.peca(tita, "wall", (0, 3.0, 0), 0.0, 2.2)`, a cabeça
  `Kit.caixa(tita, Vector3(3.4, 2.6, 2.4), Vector3(0, 6.2, 0), pedra #5e5870)`,
  os dois olhos `Kit.caixa(tita, Vector3(0.5, 0.3, 0.1), Vector3(±0.7, 6.4, 1.22), Kit.material(CenarioDoImpacto.OLHO, 2.0))`
  e um braço `Kit.peca(tita, "column", (2.4, 3.2, 0.6), 0.0, 1.6)` com
  `rotation.x = -0.6` (o que arranca a grade). `tita.position = Vector3(0, 0, lerpf(Z_TITA.y, Z_TITA.x, distancia))`
  a cada quadro, e o passo: `tita.position.y = 0.25 * absf(sin(PI * Ritmo.batida()))`
  (ele pisa em toda batida).
- **A ponte** (aos 90 s): cinco `Kit.peca(self, "wood-structure", Vector3(-8 + 4 * k, -2.0, Z_JOGADOR + 4.0), 0.0, 2.0)`
  que sobem até y = 0 em duas batidas.
- O checklist do 11: tudo caixa e peça do kit, fosco; o emissivo só nos
  olhos do titã e na borda da raia.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **vibração (protagonista)** | `aviso` (longe) ou `golpe_esq` (perto), 0,4 batida | a pista da vez, em `b − 1`, só no dono |
| vibração | `acerto` / `perfeito` / `erro` (o kit) | na pá julgada |
| vibração | `golpe` | a grade arrancada (a falha) |
| vibração | `explosao` | aos 33 s (o rugido) e quando o titã alcança, em todos |
| barra de luz | a cor do lugar, 100% | sempre |
| barra de luz | `CenarioDoImpacto.luz_com_brilho(l, 1.0 if fposmod(Ritmo.batida(), 1.0) < 0.5 else 0.6)` | com `distancia < PERIGO`, em todos (mande só quando o valor muda) |
| barra de luz | o kit (`_reagir`, H08): branco no perfeito, a cor do lugar escurecida no erro | no toque julgado |
| luzinhas de jogador | o número, sempre | — |
| alto-falante do dono | `Forja.som_falante(l, "clique", 0.6)` | na pá BOM ou ÓTIMO (no perfeito, o kit toca a nota) |
| alto-falante do dono | `Som.no_controle(l, "golpe", 0.7)` | na falha |
| gatilho | R2: `Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, 4)` — o peso da pá | ao começar; `(2, 6)` com `distancia < PERTO`; mande só quando muda |
| háptica por material | `"madeira"` (o kit toca na pá) | — |
| som na TV | `"martelo"` na caldeira em cada pá boa; `"golpe"` do titã | — |

## A falha

- O braço do titã desce (tween de `rotation.x` de −0,6 a 0,4 e de volta em
  uma batida), a grade de quem errou voa: tween da grade para `+ Vector3(0, 2.5, -3.0)`
  e escala 0,01 em 0,4 s; ela volta dois compassos depois (tween de 0,3 s).
- O vagão sacode: `tremer(TREMOR_GOLPE)`; o cavaleiro cai sentado:
  `jogador(l).gesto("fall", 0.6)`.
- `Forja.sentir(l, "golpe")`, `Som.no_controle(l, "golpe", 0.7)`,
  `distancia -= GRADE`.
- **O titã alcança** (distância 0): o braço desce no meio, as quatro grades
  voam, `explosao` em todos, todos `gesto("fall", 1.2)`; `coop_venceu = false`
  e `acabou[l] = true` de cada presente — o kit fecha.
- **A recuperação:** a próxima vez do mesmo lugar vem pelo menos uma batida
  depois; a grade volta; a distância perdida se ganha de volta com pá no tempo.

## O fim e o vencedor

`fim` `meta_coletiva`: aos 100 s de música o kit fecha (H08). `coop_venceu` é
posto a cada quadro (`coop_venceu = distancia > 0.0`), e aos 100 s o vagão
atravessa a ponte. O registro grava `vencedor` −1 (coop); o destaque é quem
pôs mais pontos:

```gdscript
## Coop: o kit grava vencedor −1 (H08); o destaque é quem pôs mais carvão no tempo.
func destaque() -> int:
	var lista := presentes()
	lista.sort_custom(func(a, b): return int(pontos[a]) > int(pontos[b]) or (int(pontos[a]) == int(pontos[b]) and a < b))
	return int(lista[0]) if not lista.is_empty() else -1
```

## Com menos de quatro

- **Três:** a roda gira; na saída, as colcheias valem (1,5 batida entre as vezes do mesmo).
- **Dois:** P_a as pares, P_b as ímpares; na saída, sem colcheias. O ganho da pá dobra (`4/k`).
- **Um:** só as batidas pares, sem embaralhar; o ganho é quatro vezes. O
  titã é o mesmo — é um minigame de ritmo sozinho contra ele.
- **O controle que cai:** as vezes dele somem sem erro enquanto está fora
  (e o compasso seguinte já é gerado sem ele: `presentes()` conta quem joga,
  mas o gerador usa só quem tem `conectado(l)`); quando volta, entra na
  roda do compasso seguinte.

## O robô

```gdscript
# O robô sente o passo do titã no controle simulado: só o motor forte ligado.
# A vez é a batida (ou a colcheia) seguinte à pista; ele aperta R2 nela, pelo
# relógio da música.
var _robo_ligado := [false, false, false, false]
var _robo_alvo := [-1.0, -1.0, -1.0, -1.0]
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var pc := Forja.percepcao(l)
	if pc.is_empty():
		return
	var pista := float(pc.get("forte", 0.0)) > 0.3 and float(pc.get("fraco", 0.0)) < 0.05
	if pista and not _robo_ligado[l] and _robo_alvo[l] < 0.0:
		_robo_alvo[l] = snappedf(Ritmo.batida(), 0.5) + 1.0
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 250 ms tarde
		_robo_atraso[l] = 0.0 if Forja.robo_acerta() else 0.25
	_robo_ligado[l] = pista
	if _robo_alvo[l] >= 0.0 and Ritmo.t_musica() >= Ritmo.t_da_batida(_robo_alvo[l]) + float(_robo_atraso[l]):
		Forja.robo_eixo(l, Forja.R2, 1.0, 0.08)
		_robo_alvo[l] = -1.0
```

O `aviso` é só o motor forte (0,6); o `golpe_esq` também (1,0). As sensações
do kit ligam os dois motores e não enganam o robô.

## Os ganchos

```gdscript
var _notas := [[], [], [], []]
var _ultima := [{}, {}, {}, {}]  ## a nota em resolução (toque e falha a leem)
var _gerado := 1
var _fora := [false, false, false, false]
var _armado := [true, true, true, true]  ## o R2 voltou abaixo de R2_SOLTA
var _dono_da_ultima := -1  ## o dono da última vez gerada (a regra da virada)
var _todas: Array = []  ## [lugar, batida] de toda vez gerada (a prova confere as distâncias)
var _compasso_do_tita := 0
var distancia := DISTANCIA_INICIAL
var _gatilho_forte := [false, false, false, false]


func montar() -> void:
	camera_pos = Vector3(0, 7.2, 11.5)
	camera_olhar = Vector3(0, 1.2, -1.5)
	CenarioDoImpacto.montar(self)
	_montar_o_vagao()  # estrado, rodas, caldeira, carvão, grades, dormentes (O cenário)
	_montar_o_tita()
	for p in jogadores:
		var l: int = p.lugar
		raia(l).position.y = 0.5
		posicionar(l)
		p.position.y = 0.55
		p.preso = true
		Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, 4)


func iniciar_jogo() -> void:
	distancia = DISTANCIA_INICIAL
	coop_venceu = true


func jogar(dt: float) -> void:
	while _gerado <= int(floor(Ritmo.batida() / 4.0)) + 1:
		_gerar_compasso(_gerado)
		_gerado += 1
	var c := int(floor(Ritmo.batida() / 4.0))
	if c > _compasso_do_tita and c >= 1:
		_compasso_do_tita = c
		distancia = clampf(distancia - AVANCO[_parte()], 0.0, 1.0)
	var agora := Ritmo.t_musica()
	for l in presentes():
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_notas[l] = _notas[l].filter(func(nt): return float(nt.t) > agora)
		for nt in _notas[l]:
			if not nt.avisada and agora >= Ritmo.t_da_batida(float(nt.b) - 1.0):
				_avisar(l, nt)
		var r2 := Forja.eixo(l, Forja.R2)
		if _armado[l] and r2 >= R2_APERTA:
			_armado[l] = false
			_pa(l)
		elif r2 <= R2_SOLTA:
			_armado[l] = true
		while not _notas[l].is_empty() and agora > float(_notas[l][0].t) + FOLGA_PERDIDA:
			nota_perdida(l, int(_notas[l].pop_front().n))
		_gatilho_do_medo(l)
		_luz_do_perigo(l)
	coop_venceu = distancia > 0.0
	if distancia <= 0.0:
		_o_tita_alcancou()
	_mover_o_mundo()  # dormentes, titã (z e passo), fogo, ponte


func toque(l: int, julgamento: int) -> void:
	var b: float = _ultima[l].b
	marcar(l, PONTOS[julgamento])  # o item, o kit já aplicou (H08)
	var k := float(maxi(presentes().size(), 1))
	distancia = clampf(distancia + GANHO[julgamento] * 4.0 / k * float(_ultima[l].peso), 0.0, 1.0)
	jogador(l).gesto("attack-melee-right", 0.3)
	Som.tocar("martelo", Vector3(0, 1.0, Z_JOGADOR + 0.2), -6.0)
	if julgamento != Ritmo.PERFEITO:
		Forja.som_falante(l, "clique", 0.6)


func falha(l: int) -> void:
	distancia = clampf(distancia - GRADE, 0.0, 1.0)
	Forja.sentir(l, "golpe")
	Som.no_controle(l, "golpe", 0.7)
	tremer(TREMOR_GOLPE)
	jogador(l).gesto("fall", 0.6)
	_arrancar_a_grade(l)
```

`_ultima[l]` é a nota da pá (ponha antes de `julgar_toque`; na
`nota_perdida` do laço, ponha a nota que saiu). `_parte()` devolve 0, 1 ou 2
pelo `progresso()` do kit (um terço e dois terços dos 100 s de música: `no_pico()` é a parte 1). `_gerar_compasso(c)` segue a tabela de "Como se
joga", guarda cada vez em `_todas` e usa só os lugares com `conectado(l)`.
`_gatilho_do_medo(l)` troca o R2 para `(2, 6)` quando `distancia < PERTO` e
volta para `(2, 4)` acima, só quando muda (`_gatilho_forte[l]`).

Catálogo: `Catalogo.MINIGAMES["S04_J17"] = preload("res://scripts/minigames/s04/fuga_do_tita.gd")`
e `"S04_J17"` depois de `"S04_J16"` na lista da seção `S04`. O `.uid`.
Traduções: `"Fuga do Titã": "Escape from the Titan"`, `"Corra!": "Run!"`,
`"Carvão": "Coal"` (a dica: `{"partes": ["@r2", "Carvão"], ...}` quando
`na_raia(l)` e `not aprendeu(l)`).

## O que o registro mede

- `sensacao` `aviso`/`golpe_esq` e a `saida` de vibração (`seq`, `ok`).
- `pista` (`via` `rumble`) na pista; o `toque` do kit na pá; `entrada` `fantasma` na pá
  fora da vez (com o dono da vez mais perto: a vibração foi para o controle
  errado, ou o jogador contou em vez de sentir).
- A `saida` de gatilho (modo 1, 2, 4 ou 6, `seq`, `ok`).

## Armadilhas

- **Nunca `Array.shuffle()`:** usa o gerador global e quebra a semente. O
  embaralhar é Fisher-Yates com `rng.randi_range`.
- **A distância mínima entre as vezes do mesmo lugar** (uma batida; 1,5 na
  saída) é o que deixa a pista inteira. Confira pela `_todas` na prova.
- **O compasso do titã conta uma vez:** o `_compasso_do_tita` guarda o
  último; o treino também avança o titã (o vagão já está correndo), mas não
  soma pontos.
- **O `coop_venceu`** é da `SalaJogo` (F03); o `coop` vem do gênero (H08):
  ninguém liga o `coop` à mão.
- **O R2 é do minigame, o L2 do item** (G03): nunca `gatilhos_off` depois do
  `montar`; o `silencio` do kit solta tudo na saída.
- **Os pontos e o item:** o kit aplica `Itens.pontos_do_acerto` no
  `julgar_toque` (H08); marque `PONTOS[julgamento]` cru.
- **Pela batida:** dormentes, titã e ponte se mexem por `Ritmo.batida()`; o
  tween da grade e do braço é enfeite.

## Pronto quando

A Fuga do Titã joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o
robô nos três temperamentos (o `ruim` perde para o titã, o `bom` cruza a
ponte); aguenta o cabo que cai e volta; fecha com o resultado coop (vitória
ou derrota) e o destaque; a prova do jogo passa; e `bash tests/prova_visual.sh`
passa com a **prancha olhada** com a Fuga do Titã nela
(o `Catalogo.sortear` da H08 põe o `S04_J17` na noite: rode a prova visual com a semente que o sorteia, `--semente=N`).

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, chamada depois de `_prova_do_cerco()`:

```gdscript
## Fuga do Titã (S04_J17): a pista só no motor forte, o peso da pá no R2, a
## vez do mesmo lugar nunca a menos de uma batida, e o fim coop.
func _prova_da_fuga_do_tita() -> void:
	var pesou := {}
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			if int(Forja.percepcao(l).get("gatilho_dir", 0)) == 0x21:
				pesou[l] = true
	var mg = await _joga_o_minigame("S04_J17", 140.0, olhar)
	if mg == null:
		return
	_esperar(mg.coop and mg.destaque() >= 0, "Titã: é coop, com o destaque")
	_esperar(pesou.size() == mg.presentes().size(), "Titã: a pá pesou no R2 de todos (%s)" % [pesou.keys()])
	var perto := 99.0
	for a in mg._todas:
		for b in mg._todas:
			if a != b and int(a[0]) == int(b[0]):
				perto = minf(perto, absf(float(a[1]) - float(b[1])))
	_esperar(perto >= 1.0, "Titã: a vez do mesmo lugar nunca a menos de uma batida (%.2f)" % perto)
	var pistas := _linha_do_tempo().filter(func(e): return e.get("tipo") == "sensacao" and e.get("nome") in ["aviso", "golpe_esq"])
	_esperar(pistas.size() >= 1, "Titã: %d passos do titã mandados" % pistas.size())
```

**O que o André joga e sente** (`./run-local.sh -- --sala=S04_J17`):

- no começo, a vez anda em roda e a mão confirma; no pico, a vez pula e só
  a mão sabe — e dá para jogar olhando para o lado;
- o passo engrossa quando o titã chega perto, e o R2 pesa mais;
- a grade voando é engraçada; a derrota (o titã agarrando) tem cara de fim;
- a barra de luz pulsa junto quando o perigo é grande, e volta à cor.

## Ao terminar

- No [quadro](README.md): a linha **L2** (se não existir, acrescente
  `| [L2](L2-fuga-do-tita.md) | L | S4 — Fuga do Titã | M | — | 1,5 | feito (<commit>) | <gasto> |`
  abaixo da L1), com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: Fuga do Titã — o coop d'O Impacto, a vez que passa de mão em mão`
