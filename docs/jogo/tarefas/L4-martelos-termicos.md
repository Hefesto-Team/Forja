# L4 — Martelos Térmicos

**Sprint:** L · **Slot:** S04_J19 · **Tamanho:** M · **Estimativa:** US$ 1,5 · **Depende de:** H04, F09, L1, G08

## Por quê

O todos contra todos da seção, e o único em que a tela mostra **as duas**
possibilidades. Duas toupeiras de metal sobem juntas, iguais aos olhos; só
uma é quente, e só a mão sabe qual. No pico, às vezes as duas são quentes e
a mão sente os dois lados de uma vez. O verbo da vibração aqui é
**escolher o alvo**: O Cerco defende do lado que vem; aqui se ataca o lado
que queima.

## Ler antes

- [O índice da seção](L-o-impacto.md) e a [L1](L1-o-cerco.md) (o cenário comum, a pista e o fantasma, o `_joga_o_minigame`)
- [O molde de minigame](molde-de-minigame.md) e o [kit](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A G08](G08-a-arte-bonecos-e-coerencia.md) (o `Kit.anel` de 8 lados)

## A ficha de dados

`godot/scripts/minigames/s04/martelos_termicos.gd`:

```gdscript
extends Minigame
## Martelos Térmicos (S04_J19) — duas toupeiras de metal sobem dos dois lados
## de cada raia na batida do dono, iguais aos olhos. Uma é quente: a mão
## sente o lado dela uma batida antes (só o motor daquele lado). Martele o
## lado quente com L1 (esquerda) ou R1 (direita) na batida. No pico, às vezes
## as duas são quentes (os dois motores, forte): L1 e R1 juntos.
##
## A falha: martela a fria (ela afunda oca) e a quente queima a mão — um
## tremor longo, a barra de luz vermelha, o cavaleiro sacode a mão.
## O vencedor: mais toupeiras quentes marteladas; no empate, mais pontos.
## O alto-falante do dono: o martelo no metal ("martelo"); a queimadura ("golpe").
## O registro mede: cada pista (lado, ok) e o lado martelado; o martelo sem
## pista é o fantasma.
## O robô: sente qual motor ligou e martela aquele lado (ou os dois) na batida
## seguinte; quando não acerta, 250 ms tarde.
## Com menos de quatro: as batidas se dividem; sozinho, só as pares.
## A régua: (1) "Acerte o lado!" com as duas toupeiras na tela; (2) sim: os
## olhos não sabem qual é a quente; (3) não pergunta nada.

const FICHA := {
	"slot": "S04_J19",
	"titulo": "Martelos Térmicos",
	"verbo": "Acerte o lado!",
	"genero": "tct",
	"icone": "vibracao",
	"entradas": [Forja.L1, Forja.R1],
	"camera": "fixa",
	"faixa": "MUS_S04_J19",
	"duracao": 75.0,
	"fim": "tempo",
	"sensacoes": ["golpe_esq", "golpe_dir", "explosao", "golpe", "acerto", "perfeito", "erro"],
	"material": "metal",
	"microjogo": {"verbo": "Acerte!", "segundos": 6.0},
}

const PONTOS := [0, 40, 70, 100]  ## ERRO, BOM, OTIMO, PERFEITO
const DUPLA := 150  ## as duas quentes marteladas juntas
const FANTASMA := -20
const JUNTOS_S := 0.12  ## L1 e R1 a até isto um do outro valem "juntos"
const QUEIMA_MS := 300  ## o tremor longo da queimadura
const PISCA_QUEIMA := 0.4
## Por parte (entrada 0-25 s, pico 25-50 s, saída 50-75 s): a chance de
## toupeira na batida do dono e a chance de as duas serem quentes.
const DENSIDADE := [0.6, 1.0, 0.8]
const DUAS_QUENTES := [0.0, 0.3, 0.15]
const X_BURACO := 1.1  ## os buracos em RAIAS[l] ± isto
enum { ESQ, DIR, AMBAS }
```

## Como se joga

**O dono da batida** é o do Cerco (L1): `presentes()` em ordem, `lista[b % k]`;
sozinho, só as batidas pares. O compasso 0 é a contagem; a primeira
toupeira pode ser a batida 4. O compasso é gerado quando
`Ritmo.batida() >= 4c − 4`.

**A nota:** `{"n": b, "b": b, "t": Ritmo.t_da_batida(b), "quente": ESQ | DIR | AMBAS, "avisada": false, "feito": -1}`
com `nova_nota(l, b, t)`. `quente` é `AMBAS` com a chance da parte
(nunca para quem está com `Ritmo.simples[l]`); senão `ESQ` ou `DIR` pelo `rng`.

**A pista**, em `b − 1`, quando as duas toupeiras começam a subir:

- `ESQ` → `Forja.sentir(l, "golpe_esq", ms)`; `DIR` → `"golpe_dir"`;
  `AMBAS` → `"explosao"` (os dois motores inteiros: é a única pista com o
  fraco acima de 0,9); `ms = int(60000.0 / Ritmo.bpm * 0.4)`;
- `Forja.evento("jogo", l + 1, {"slot": id, "o": "lado", "n": b, "lado": "esq"/"dir"/"ambos", "ok": ok})`.

**As toupeiras sobem** de `b − 1` a `b − 0,25` (`y` de −0,6 a 0, pela
batida) e descem de `b + 0,5` a `b + 1`. As duas têm o mesmo brilho laranja
fosco: a tela não diz qual é a quente.

**O martelo:** L1 martela a esquerda, R1 a direita. Casa com a nota do lugar
a até `Ritmo.JANELA_BOM` do tempo dela:

- nota `ESQ`/`DIR`, lado certo → `julgar_toque(l, t, n)`; lado errado →
  `nota_perdida(l, n)` (a falha); grave
  `{"o": "resposta", "n": b, "lado_pedido": ..., "lado_feito": ...}`;
- nota `AMBAS` → o primeiro martelo chama `julgar_toque(l, t, n)` e guarda
  `nt.feito` (o lado); se o outro lado vier a até `JUNTOS_S`, é a dupla
  (`marcar(l, DUPLA)`, as duas esmagadas); se não vier, a toupeira que
  ficou queima a mão (`_queimar(l)` sem novo erro no registro: o julgamento
  já foi feito);
- sem nota perto → o fantasma (como no Cerco: `marcar(l, FANTASMA)` e o
  `jogo` `fantasma` com o dono da nota mais perto).

A nota que passa de `t + JANELA_BOM` sem martelo é `nota_perdida(l, n)`.

**Os pontos:** `marcar(l, Itens.pontos_do_acerto(l, PONTOS[j], j, b % 4 == 0))`
e `toupeiras[l] += 1` (dupla: `+= 2`).

**Os 75 segundos:** entrada (0–25 s) uma quente por vez, chance 0,6; **pico**
(25–50 s) toda batida do dono tem toupeira e 30% são duas quentes — aos
25 s, a fornalha acende no fundo (`Som.tocar("fogo", Vector3(0, 1, -6), -6.0)`
e o fundo fica laranja: a luz `_fornalha` sobe de 0 a 2,5 em um compasso);
saída (50–75 s) chance 0,8 e 15% duplas.

## O cenário

- `CenarioDoImpacto.montar(self)`; a câmera d'O Impacto.
- Por lugar: `raia(l)`, `posicionar(l)`, `rotation.y = PI` (de frente para
  os buracos), `preso = true`, e o martelo na mão: `martelo_na_mao(jogador(l))`
  (da `SalaJogo`).
- **Os dois buracos** de cada raia, em `Vector3(RAIAS[l] ± X_BURACO, 0.02, Z_JOGADOR - 1.2)`:
  o fundo `Kit.cilindro(self, 0.42, 0.04, pos, Kit.material(Color("#141018"), 0.0, 1.0))`
  e a borda `Kit.anel(self, 0.42, 0.52, pos + Vector3(0, 0.03, 0), Kit.material(Color("#4a4e5e"), 0.0, 0.6))`.
- **A toupeira** (uma por buraco, peças do kit mais um brilho): um `Node3D`
  com `Kit.peca(t, "column", Vector3.ZERO, 0.0, 0.55)` e a cabeça
  `Kit.caixa(t, Vector3(0.5, 0.3, 0.5), Vector3(0, 0.95, 0), mat)` com
  `mat = Kit.material(Color("#b0502a"), 0.6, 0.8)` (o laranja fosco, igual
  nas duas), e dois olhinhos `Kit.caixa(t, Vector3(0.08, 0.06, 0.04), Vector3(±0.1, 1.0, 0.26), Kit.material(Color("#ffd27a"), 1.5))`.
- **A fornalha** no fundo: `Kit.peca(self, "wall-opening", Vector3(0, 0, -7.6), 0.0, 2.0)`
  com a `OmniLight3D` `_fornalha` `#ff7a2a` em `(0, 1.5, -6.8)`, energia 0 até
  o pico.
- O checklist do 11: a toupeira é coluna do kit com um brilho; o anel tem 8
  lados (G08); nada metálico acima de 0,2.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **vibração (protagonista)** | `golpe_esq` / `golpe_dir` / `explosao` (0,4 batida) | a pista, em `b − 1`, só no dono |
| vibração | `acerto` / `perfeito` / `erro` (o kit) | no martelo julgado |
| vibração | `golpe` por `QUEIMA_MS` (300 ms) | a queimadura (a falha) |
| barra de luz | a cor do lugar, 100% | sempre |
| barra de luz | branco 0,1 s | no perfeito |
| barra de luz | vermelho por `PISCA_QUEIMA` (0,4 s), depois a cor | na queimadura |
| luzinhas de jogador | o número, sempre | — |
| alto-falante do dono | `Som.no_controle(l, "martelo", 0.7)` | no martelo BOM ou ÓTIMO (no perfeito, o kit toca a nota) |
| alto-falante do dono | `Som.no_controle(l, "golpe", 0.7)` | na queimadura |
| gatilho | `Forja.gatilho(l, 1, Forja.GATILHO_OFF)` no `montar` | o martelo é L1/R1: nada a segurar no R2; o L2 é do item |
| háptica por material | `"metal"` (o kit, no acerto) | — |
| som na TV | `"bigorna_aguda"` na toupeira esmagada; `"sopro"` do vapor na queimadura | — |

## A falha

- **Martelou a fria** (lado errado): a toupeira fria afunda oca
  (`Som.tocar("tique", pos, -6.0)`, escala y 0,3), e a quente, do outro
  lado, cospe vapor (`Efeitos.faiscas(self, pos_da_quente + Vector3(0, 1, 0), Color("#e9e7f2"), 14, 0.6)`)
  e queima a mão.
- **Não martelou:** a quente assobia (`Som.tocar("sopro", pos, -4.0)`) e
  queima a mão do mesmo jeito.
- **A queimadura** (`_queimar(l)`): `Forja.sentir(l, "golpe", QUEIMA_MS)`,
  vermelho na barra de luz por 0,4 s, `Som.no_controle(l, "golpe", 0.7)`,
  o cavaleiro sacode a mão (`gesto("emote-no", 0.5)`).
- **A recuperação:** a próxima toupeira do lugar é pelo menos duas batidas
  depois (o hoqueto); nada se perde além do ponto.

## O fim e o vencedor

75 s de `t_jogo`, pelo kit.

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if int(toupeiras[a]) != int(toupeiras[b]):
			return int(toupeiras[a]) > int(toupeiras[b])
		return int(pontos[a]) > int(pontos[b]))
	return lista
```

## Com menos de quatro

- **Três e dois:** a roda do dono, como no Cerco.
- **Um:** só as batidas pares; o fantasma não se mede (sem vizinho).
- **O controle que cai:** as toupeiras dele não sobem enquanto está fora
  (as notas somem sem erro); quando volta, a próxima é a primeira que ainda
  não chegou.

## O robô

```gdscript
# O robô sente a pista no controle simulado: um motor só é um lado; os dois
# acima de 0,9 são as duas quentes (as sensações do kit nunca passam de 0,8
# no fraco). Martela na batida seguinte, pelo relógio da música.
var _robo_ligado := [false, false, false, false]
var _robo_alvo := [-1.0, -1.0, -1.0, -1.0]
var _robo_quente := [0, 0, 0, 0]
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var pc := Forja.percepcao(l)
	if pc.is_empty():
		return
	var forte := float(pc.get("forte", 0.0))
	var fraco := float(pc.get("fraco", 0.0))
	var qual := -1
	if forte > 0.9 and fraco > 0.9:
		qual = AMBAS
	elif forte > 0.3 and fraco < 0.05:
		qual = ESQ
	elif fraco > 0.3 and forte < 0.05:
		qual = DIR
	var pista := qual >= 0
	if pista and not _robo_ligado[l] and _robo_alvo[l] < 0.0:
		_robo_alvo[l] = roundf(Ritmo.batida()) + 1.0
		_robo_quente[l] = qual
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 250 ms tarde
		_robo_atraso[l] = 0.0 if Forja.robo_acerta() else 0.25
	_robo_ligado[l] = pista
	if _robo_alvo[l] >= 0.0 and Ritmo.t_musica() >= Ritmo.t_da_batida(_robo_alvo[l]) + float(_robo_atraso[l]):
		if _robo_quente[l] != DIR:
			Forja.robo_apertar(l, Forja.L1, 0.06)
		if _robo_quente[l] != ESQ:
			Forja.robo_apertar(l, Forja.R1, 0.06)
		_robo_alvo[l] = -1.0
```

(Nas duas quentes, o robô aperta L1 e R1 no mesmo quadro: chegam juntos.)

## Os ganchos

```gdscript
var _notas := [[], [], [], []]
var _ultima := [{}, {}, {}, {}]
var _gerado := 1
var _fora := [false, false, false, false]
var toupeiras := [0, 0, 0, 0]
var _pisca := [0.0, 0.0, 0.0, 0.0]
var _buracos := {}  ## lugar -> [toupeira esq, toupeira dir]
var _fornalha: OmniLight3D


func montar() -> void:
	camera_pos = Vector3(0, 6.4, 10.8)
	camera_olhar = Vector3(0, 1.0, -0.4)
	CenarioDoImpacto.montar(self)
	_montar_a_fornalha()
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.rotation.y = PI
		p.preso = true
		martelo_na_mao(p)
		_buracos[l] = [_toupeira(l, ESQ), _toupeira(l, DIR)]
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


func jogar(dt: float) -> void:
	while _gerado <= int(floor(Ritmo.batida() / 4.0)) + 1:
		_gerar_compasso(_gerado)
		_gerado += 1
	var agora := Ritmo.t_musica()
	for l in presentes():
		_piscar(l, dt)
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_notas[l] = _notas[l].filter(func(nt): return float(nt.t) > agora)
		for nt in _notas[l]:
			if not nt.avisada and agora >= Ritmo.t_da_batida(float(nt.b) - 1.0):
				_avisar(l, nt)
		var l1 := Forja.apertou(l, Forja.L1)
		var r1 := Forja.apertou(l, Forja.R1)
		if l1:
			_martelar(l, ESQ)
		if r1:
			_martelar(l, DIR)
		_conferir_a_dupla(l, agora)  # a segunda mão da AMBAS, ou a queimadura quando passou de JUNTOS_S
		while not _notas[l].is_empty() and agora > float(_notas[l][0].t) + Ritmo.JANELA_BOM and int(_notas[l][0].feito) < 0:
			var nt: Dictionary = _notas[l].pop_front()
			_ultima[l] = nt
			nota_perdida(l, int(nt.n))
		_mover_as_toupeiras(l)  # sobe/desce pela batida da nota mais perto
	_fornalha.light_energy = clampf((t_jogo - 25.0) / 2.0, 0.0, 1.0) * 2.5 if t_jogo < 50.0 else maxf(0.0, 2.5 - (t_jogo - 50.0))


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	marcar(l, Itens.pontos_do_acerto(l, PONTOS[julgamento], julgamento, int(nt.b) % 4 == 0))
	toupeiras[l] += 1
	jogador(l).gesto("attack-melee-left" if int(nt.feito) == ESQ else "attack-melee-right", 0.3)
	_esmagar(l, int(nt.feito))
	if julgamento == Ritmo.PERFEITO:
		_piscar_cor(l, Color.WHITE, 0.1)
	else:
		Som.no_controle(l, "martelo", 0.7)


func falha(l: int) -> void:
	var nt: Dictionary = _ultima[l]
	if int(nt.get("feito", -1)) >= 0:
		_afundar_a_fria(l, int(nt.feito))
	_queimar(l)
```

`_martelar(l, lado)` acha a nota (`abs(agora − t) <= JANELA_BOM`), põe
`nt.feito = lado`, `_ultima[l] = nt`, e decide pelo "Como se joga" (lado
certo → `julgar_toque`; errado → `nota_perdida`; `AMBAS` → o primeiro julga
e marca `nt.t_primeiro = agora`, o segundo vira a dupla). Tire a nota da
lista depois de resolvida (na `AMBAS`, depois da dupla ou da queimadura).
`_piscar_cor`/`_piscar` como na L1.

Catálogo: `"S04_J19"` em `MINIGAMES` e na lista da seção `S04`. O `.uid`.
Traduções: `"Martelos Térmicos": "Thermal Hammers"`, `"Acerte o lado!": "Hit the side!"`,
`"Acerte!": "Hit!"`. `dica(l)`: `{"partes": ["@l1", "Esquerda", "@r1", "Direita"], ...}`
com `na_raia(l)` e `not aprendeu(l)`.

## O que o registro mede

- `sensacao` `golpe_esq` / `golpe_dir` / `explosao` e a `saida` de vibração.
- `jogo` `lado` na pista e `jogo` `resposta` com o lado martelado; o `toque` do kit.
- O fantasma (o martelo sem pista, com o dono da pista mais perto).
- A dupla: `{"o": "dupla", "n": b, "juntos_ms": <a distância entre os dois martelos>}`.

## Armadilhas

- **A pista das duas é a `explosao`** (os dois motores cheios), não o
  `golpe`: o `golpe` é a queimadura, e o robô (e o jogador) confundiriam.
- **A queimadura dura 300 ms:** a próxima pista do mesmo lugar vem pelo
  menos uma batida depois; o `sentir` novo manda nos motores e corta o
  resto da queimadura (é o mais novo que vale).
- **A dupla:** o julgamento é o do primeiro martelo; o segundo só decide a
  dupla. Não chame `julgar_toque` duas vezes na mesma nota.
- **As toupeiras sobem pela batida**, nunca por `dt`.
- **Os pontos e o item:** se o kit já aplica `Itens.pontos_do_acerto`, marque cru.

## Pronto quando

Os Martelos Térmicos jogam do aviso ao resultado com 4, 3, 2 e 1 jogador e
com o robô nos três temperamentos (o bom faz duplas no pico); aguentam o cabo
que cai e volta; fecham com vencedor; a prova do jogo passa; e
`bash tests/prova_visual.sh` passa com a **prancha olhada** com os Martelos
nela (na cópia de trabalho, sem commitar, `"S04_J19"` em primeiro na lista
da seção `S04`; depois volte a ordem).

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, depois das outras da seção:

```gdscript
## Martelos Térmicos (S04_J19): a pista de um lado só, e a das duas com os
## dois motores cheios; o vencedor por toupeiras.
func _prova_dos_martelos() -> void:
	var viu := {}
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			var pc := Forja.percepcao(l)
			var forte := float(pc.get("forte", 0.0))
			var fraco := float(pc.get("fraco", 0.0))
			if forte > 0.9 and fraco > 0.9:
				viu["ambas"] = true
			elif (forte > 0.3 and fraco < 0.05) or (fraco > 0.3 and forte < 0.05):
				viu["um_lado"] = true
	var mg := await _joga_o_minigame("S04_J19", 60.0, olhar)
	if mg == null:
		return
	_esperar(viu.has("um_lado"), "Martelos: a pista de um lado só chegou (%s)" % [viu.keys()])
	var v := mg.vencedor()
	_esperar(not v.is_empty() and int(mg.toupeiras[v[0]]) == v.map(func(l): return int(mg.toupeiras[l])).max(), "Martelos: vence quem martelou mais")
	var resp := _linha_do_tempo().filter(func(e): return e.get("tipo") == "jogo" and e.get("slot") == "S04_J19" and e.get("o") == "resposta")
	_esperar(resp.size() >= 1, "Martelos: %d respostas com o lado no registro" % resp.size())
```

(As duas quentes só aparecem no pico; com `--fixed-fps 60` a prova pode não
chegar lá — por isso o `"ambas"` não é exigido. A dupla se prova com o André.)

**O que o André joga e sente** (`./run-local.sh -- --sala=S04_J19`):

- de olhos na tela, as duas toupeiras são iguais; a mão sabe a quente;
- as duas quentes (os dois motores cheios) se sentem diferentes de um lado só;
- a queimadura é mais longa e mais áspera que o acerto;
- a fornalha acende no meio e a sala esquenta.

## Ao terminar

- No [quadro](README.md): a linha **L4** (se não existir, acrescente
  `| [L4](L4-martelos-termicos.md) | L | S4 — Martelos Térmicos | M | — | 1,5 | feito (<commit>) | <gasto> |`),
  com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: Martelos Térmicos — a toupeira quente que só a mão distingue`
