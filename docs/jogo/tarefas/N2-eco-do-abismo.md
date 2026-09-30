# N2 — Eco do Abismo

**Sprint:** N · **Slot:** S06_J27 · **Tamanho:** M · **Estimativa:** US$ 1,5 · **Depende de:** H04, F09, N1

## Por quê

A corrida no escuro da seção. Quatro escadas que sobem para o breu; em cada
degrau há duas pedras iguais, uma firme e uma oca. O eco no seu controle
diz, uma batida antes, qual lado aguenta: grave é a esquerda, agudo é a
direita. Quem ouve sobe; quem erra o lado despenca um andar. O verbo do
alto-falante aqui é **seguir**: a pista vem já, e a resposta é o próximo
passo — não há compasso de espera como n'O Canto.

## Ler antes

- [O índice da seção](N-o-canto.md) e a [N1](N1-o-canto.md) (o cenário comum, o robô que ouve, o `_joga_o_minigame`)
- [O molde de minigame](molde-de-minigame.md) e o [kit](../13-arquitetura.md#o-kit-do-minigame--h04)

## A ficha de dados

`godot/scripts/minigames/s06/eco_do_abismo.gd`:

```gdscript
extends Minigame
## Eco do Abismo (S06_J27) — cada um numa escada que sobe para o escuro. Na
## batida do dono, ele sobe um degrau; uma batida antes, o eco no alto-falante
## do controle dele diz o lado firme: grave, a esquerda; agudo, a direita.
## Pise com o analógico esquerdo (um toque para o lado) na batida. No pico, o
## eco vem em colcheias: dois degraus por vez.
##
## A falha: o lado errado — a pedra é oca e o cavaleiro despenca um andar
## (quatro degraus); fora do tempo, ou sem pisar — tropeça e fica.
## O vencedor: o primeiro no topo (24 degraus); senão, o mais alto aos 100 s.
## O alto-falante do dono: o eco (a protagonista).
## O registro mede: cada eco (o som, se foi ao controle) e o lado pisado.
## O robô: ouve o ataque do eco no alto-falante simulado e pisa na batida
## seguinte, do lado da partitura; quando não acerta, 250 ms tarde.
## Com menos de quatro: as batidas se dividem; sozinho, só as pares.
## A régua: (1) "Responda o eco!" com as escadas no escuro; (2) sim: as duas
## pedras são iguais, só o eco diz; (3) não pergunta nada.

const FICHA := {
	"slot": "S06_J27",
	"titulo": "Eco do Abismo",
	"verbo": "Responda o eco!",
	"genero": "corrida",
	"icone": "alto_falante",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S06_J27",
	"duracao": 100.0,
	"fim": "primeiro_a_chegar",
	"sensacoes": ["toque", "acerto", "perfeito", "erro", "golpe"],
	"material": "pedra",
	"microjogo": {"verbo": "Responda!", "segundos": 6.0},
	"gesto": "lados",
}

const PONTOS := [0, 40, 70, 100]  ## ERRO, BOM, OTIMO, PERFEITO
const DEGRAUS := 24
const ANDAR := 4  ## quanto despenca no lado errado
const ESQ := 0
const DIR := 1
const ECO := ["nota", "nota_alta"]  ## ESQ grave, DIR agudo
const LX_VAI := 0.6
const LX_VOLTA := 0.3
const ESCURO := 0.4  ## o cenário comum escurecido (o terror)
const BRILHO := 0.5  ## a barra de luz no escuro (F04: nunca abaixo de 0,3)
const PULSO_S := 0.12
## A chance de degrau na batida do dono: entrada, pico, saída (com colcheias no pico).
const DENSIDADE := [0.8, 1.0, 1.0]
const DEGRAU_ALTURA := 0.22
const DEGRAU_FUNDO := 0.3
const PEDRA_X := 0.55  ## as duas pedras em RAIAS[l] ± isto
```

## Como se joga

**O dono da batida** é `presentes()` em ordem, `lista[b % k]`; sozinho, só
as batidas pares. O compasso 0 é a contagem; o compasso é gerado quando
`Ritmo.batida() >= 4c − 4`.

**O passo** do dono na batida `b` (com a chance da parte), e no **pico**
(33–66 s) também em `b + 0,5` (quem está com `Ritmo.simples[l]` fica só com
o de `b`): `{"n": int(round(b * 2)), "b": b, "t": Ritmo.t_da_batida(b), "lado": ESQ | DIR, "ecoado": false}`,
com `nova_nota(l, n, t)`.

**O eco** em `b − 1` (`Ritmo.t_musica() >= Ritmo.t_da_batida(b - 1)`):
`var foi := CenarioDoCanto.falante(self, l, ECO[lado], 0.9)` e
`Forja.evento("jogo", l + 1, {"slot": id, "o": "chamada", "n": n, "som": ECO[lado], "no_controle": foi})`.
Na tela, nada muda: as duas pedras do degrau seguinte são iguais.

**Pisar:** o analógico esquerdo passando de `LX_VAI` para um lado (esquerda
negativa), rearmando abaixo de `LX_VOLTA`, casa com o passo do lugar a até
`Ritmo.JANELA_BOM`:

- o lado do eco → `julgar_toque(l, t, n)`: BOM ou melhor sobe um degrau
  (a pedra firme acende na cor do lugar e fica acesa: o caminho); ERRO
  (fora do tempo) tropeça e fica;
- o lado oposto → `nota_perdida(l, n)` e **despenca** `ANDAR` degraus
  (`degrau[l] = maxi(0, degrau[l] - ANDAR)`);
- nenhum passo perto → nada (o cavaleiro olha para os lados).

O passo que passa de `t + JANELA_BOM` é `nota_perdida(l, n)` (tropeça e fica).
Cada pisada grava `{"o": "resposta", "n": n, "lado_pedido": ..., "lado_feito": ...}`.

**O topo:** o primeiro a chegar a `DEGRAUS` vence: todos `acabou`, e o kit
fecha (`fim` `primeiro_a_chegar`). Senão, os 100 s.

**Os pontos:** `marcar(l, Itens.pontos_do_acerto(l, PONTOS[j], j, fmod(b, 4.0) == 0.0))`.

**Os 100 segundos:** entrada (0–33 s) um passo por vez do dono (chance 0,8);
**pico** (33–66 s) dois passos por vez (em colcheias) — aos 33 s um trovão de
gelo racha no fundo (`Som.tocar("golpe", Vector3(0, 6, -7), -4.0)`, a névoa
clareia por um instante com `pulso_de_luz(Color("#b9b0ff"))`) e todos sentem
`golpe`; saída (66–100 s) um passo, com toda batida do dono.

**O compasso na mão:** no começo de cada compasso, `Forja.sentir(l, "toque")`
em cada presente com controle e `CenarioDoCanto.tempo_forte()`.

## O cenário

- `CenarioDoCanto.montar(self, ESCURO)` (o sino grande fica no fundo, no alto).
- A câmera mais alta e mais longe, para as escadas:
  `camera_pos = Vector3(0, 7.8, 12.2)`, `camera_olhar = Vector3(0, 2.8, -2.2)`.
- Por lugar: `raia(l)` (o chão de partida), `posicionar(l)`, `preso = true`,
  `rotation.y = PI` (de costas: ele sobe para o fundo).
- **A escada de cada raia:** para `k` de 1 a `DEGRAUS`, duas pedras
  `Kit.caixa(self, Vector3(0.9, 0.15, 0.6), Vector3(RAIAS[l] ± PEDRA_X, DEGRAU_ALTURA * k, Z_JOGADOR - DEGRAU_FUNDO * k), mat)`
  com `mat = Kit.material(Color("#2a2233"), 0.0, 0.95)` — iguais; a firme de
  cada degrau é a do `lado` do passo, decidida só quando o passo é gerado
  (antes disso, nenhuma é firme). A pedra firme pisada ganha o emissivo da
  cor do lugar (0,8): o caminho aceso fica atrás dele.
- **O topo:** uma plataforma `Kit.caixa(self, Vector3(2.0, 0.3, 1.2), topo, pedra)`
  com uma tocha `Kit.peca(self, "banner", ...)` e a luz `#ffb070` que acende
  quando alguém chega.
- **A luz do cavaleiro:** uma `OmniLight3D` da cor do lugar, alcance 2,2,
  energia 0,8, presa ao boneco (filha dele): no escuro, cada um vê só onde está.
- O cavaleiro sobe e desce pela escada com tween (0,15 s por degrau; o
  despencar, 0,4 s com `gesto("fall", 0.6)`), a posição final sempre a do
  degrau: `Vector3(RAIAS[l] + (±PEDRA_X do último lado), DEGRAU_ALTURA * d + 0.1, Z_JOGADOR - DEGRAU_FUNDO * d)`.
- O checklist do 11: pedras em caixa, foscas; o terror escurece a luz da
  casa; o emissivo só no caminho aceso e na borda da raia.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **alto-falante (protagonista)** | o eco: `"nota"` (esquerda) / `"nota_alta"` (direita), 0,9 | uma batida antes de cada passo, só no dono |
| vibração | `toque` | no começo de cada compasso (o tempo forte) |
| vibração | `acerto` / `perfeito` / `erro` (o kit) | na pisada julgada |
| vibração | `golpe` | ao despencar; aos 33 s, em todos (o trovão) |
| barra de luz | `CenarioDoCanto.luz_da_nota(l, BRILHO)` (50%: o escuro) | sempre |
| barra de luz | `luz_da_nota(l, 1.0)` por `PULSO_S` | na pisada boa (a própria nota); volta a 50% |
| luzinhas de jogador | o número, sempre | — |
| háptica por material | `"pedra"` (o kit, no acerto, no cabo) | — |
| gatilho | `Forja.gatilho(l, 1, Forja.GATILHO_OFF)` no `montar` | nada a segurar |
| som na TV | `"passo_salao"` baixo (−10 dB) em cada degrau subido; `"pedra"` na pedra oca que cai | — |

## A falha

- **O lado errado:** a pedra oca afunda e cai no escuro (tween de `y` −3 em
  0,5 s, `Som.tocar("pedra", ...)`); o cavaleiro despenca um andar
  (`gesto("fall", 0.6)`, tween de 0,4 s até o degrau de quatro abaixo),
  `Forja.sentir(l, "golpe")`; as pedras acesas acima dele apagam.
- **Tropeçou** (fora do tempo, ou sem pisar): o cavaleiro cambaleia no
  degrau (`gesto("emote-no", 0.3)`) e fica.
- **A recuperação:** o caminho aceso até onde ele está continua; o próximo
  passo é a próxima vez dele.

## O fim e o vencedor

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if int(degrau[a]) != int(degrau[b]):
			return int(degrau[a]) > int(degrau[b])
		return int(pontos[a]) > int(pontos[b]))
	return lista
```

(Quem chegou ao topo tem `degrau == DEGRAUS`: vem primeiro. Com dois no topo
no mesmo quadro, os pontos desempatam.)

## Com menos de quatro

- **Três e dois:** a roda do dono (mais passos para cada um: a corrida anda
  mais depressa).
- **Um:** só as pares; a corrida é contra os 100 s.
- **O controle que cai:** os ecos dele não tocam e os passos somem sem erro;
  ele fica no degrau em que estava, e volta a subir quando o controle volta.

## O robô

```gdscript
# O robô ouve o ataque do eco no alto-falante simulado (a lógica de ataque da
# N1) e pisa na batida seguinte — do lado da partitura, porque a placa virtual
# dá o nível e não a altura. Se não ouviu, não pisa. Quando não acerta, 250 ms tarde.
var _robo_vale := [1.0, 1.0, 1.0, 1.0]
var _robo_desde := [0.0, 0.0, 0.0, 0.0]
var _robo_ouviu := [{}, {}, {}, {}]  ## meia batida do ataque -> true
var _robo_nota := [-1, -1, -1, -1]
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var nivel := float(Forja.som_virtual(l).get("falante", 0.0))
	var agora := Ritmo.t_musica()
	if nivel > 0.12 and nivel - float(_robo_vale[l]) > 0.10 and agora - float(_robo_desde[l]) > 0.12:
		_robo_vale[l] = nivel
		_robo_desde[l] = agora
		_robo_ouviu[l][int(round(Ritmo.batida() * 2.0))] = true
	else:
		_robo_vale[l] = minf(float(_robo_vale[l]), nivel)
	if _notas[l].is_empty():
		return
	var nt: Dictionary = _notas[l][0]
	if int(nt.n) != _robo_nota[l]:
		_robo_nota[l] = int(nt.n)
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 250 ms tarde
		_robo_atraso[l] = 0.0 if Forja.robo_acerta() else 0.25
	var eco := int(round((float(nt.b) - 1.0) * 2.0))
	var ouviu: bool = _robo_ouviu[l].has(eco) or _robo_ouviu[l].has(eco + 1)
	if ouviu and agora >= float(nt.t) + float(_robo_atraso[l]):
		Forja.robo_eixo(l, Forja.LX, -1.0 if int(nt.lado) == ESQ else 1.0, 0.1)
		_robo_nota[l] = 99999
```

(O robô solta o analógico entre os passos: o `robo_eixo` dura 0,1 s e volta
ao meio, o que rearma a pisada.)

## Os ganchos

```gdscript
var _notas := [[], [], [], []]
var _ultima := [{}, {}, {}, {}]
var _gerado := 1
var _compasso := 0
var _fora := [false, false, false, false]
var _armado := [true, true, true, true]
var degrau := [0, 0, 0, 0]
var _lado_do_boneco := [ESQ, ESQ, ESQ, ESQ]
var _pedras := {}  ## lugar -> [[esq, dir] por degrau]
var _pulso := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	camera_pos = Vector3(0, 7.8, 12.2)
	camera_olhar = Vector3(0, 2.8, -2.2)
	CenarioDoCanto.montar(self, ESCURO)
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.rotation.y = PI
		p.preso = true
		_pedras[l] = _montar_a_escada(l)
		_luz_do_cavaleiro(p)
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)
	_montar_o_topo()


func iniciar_jogo() -> void:
	for l in presentes():
		CenarioDoCanto.luz_da_nota(l, BRILHO)


func jogar(dt: float) -> void:
	var c := int(floor(Ritmo.batida() / 4.0))
	if c > _compasso:
		_compasso = c
		CenarioDoCanto.tempo_forte()
		for l in presentes():
			if conectado(l):
				Forja.sentir(l, "toque")
	while _gerado <= c + 1:
		_gerar_compasso(_gerado)  # os passos, com o lado; marca a pedra firme do degrau
		_gerado += 1
	var agora := Ritmo.t_musica()
	for l in presentes():
		_apagar_o_pulso(l, dt)  # volta a luz_da_nota(l, BRILHO)
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_notas[l] = _notas[l].filter(func(nt): return float(nt.t) > agora)
		for nt in _notas[l]:
			if not nt.ecoado and agora >= Ritmo.t_da_batida(float(nt.b) - 1.0):
				_ecoar(l, nt)
		var lx := Forja.eixo(l, Forja.LX)
		if _armado[l] and absf(lx) >= LX_VAI:
			_armado[l] = false
			_pisar(l, ESQ if lx < 0.0 else DIR)
		elif absf(lx) <= LX_VOLTA:
			_armado[l] = true
		while not _notas[l].is_empty() and agora > float(_notas[l][0].t) + Ritmo.JANELA_BOM:
			var nt: Dictionary = _notas[l].pop_front()
			_ultima[l] = nt
			nota_perdida(l, int(nt.n))
	if presentes().any(func(l): return int(degrau[l]) >= DEGRAUS):
		for l in presentes():
			acabou[l] = true


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	marcar(l, Itens.pontos_do_acerto(l, PONTOS[julgamento], julgamento, fmod(float(nt.b), 4.0) == 0.0))
	degrau[l] = mini(DEGRAUS, int(degrau[l]) + 1)
	_lado_do_boneco[l] = int(nt.lado)
	_subir(l)  # tween, a pedra firme acende, "passo_salao" na TV
	CenarioDoCanto.luz_da_nota(l, 1.0)
	_pulso[l] = PULSO_S


func falha(l: int) -> void:
	var nt: Dictionary = _ultima[l]
	if int(nt.get("feito", -1)) >= 0 and int(nt.feito) != int(nt.lado):
		degrau[l] = maxi(0, int(degrau[l]) - ANDAR)
		Forja.sentir(l, "golpe")
		_despencar(l, int(nt.feito))
	else:
		_tropecar(l)
```

`_pisar(l, lado)` acha o passo a até `JANELA_BOM`, grava `nt.feito = lado`
e a `resposta`, põe em `_ultima[l]`, tira da lista e chama `julgar_toque`
(lado do eco) ou `nota_perdida` (o outro). `_ecoar(l, nt)` toca o eco,
grava a `chamada` e marca `nt.ecoado = true`.

Catálogo: `"S06_J27"` em `MINIGAMES` e na lista da seção `S06`. O `.uid`.
Traduções: `"Eco do Abismo": "Echo of the Abyss"`, `"Responda o eco!": "Answer the echo!"`,
`"Responda!": "Answer!"`; `dica(l)`: `{"partes": ["@stick_l", "Pise do lado do eco"], ...}`
com `na_raia(l)` e `not aprendeu(l)` (`"Pise do lado do eco": "Step to the echo's side"`);
`status(l)`: `"Degrau %d" % degrau[l]` (`"Degrau %d": "Step %d"`).

## O que o registro mede

- `som_controle` (H07) de cada eco; `jogo` `chamada` (n, som, `no_controle`).
- `jogo` `resposta` (lado pedido, lado feito) e o `toque` do kit: o eco com
  `placa` e o lado errado, sempre num controle, é o alto-falante que não
  cantou (o jogador chutou).

## Armadilhas

- **As duas pedras são iguais na tela:** a firme só existe na partitura (e
  acende depois de pisada). Nenhum brilho, cor ou tamanho diferente antes.
- **O eco é mais novo que a nota do kit:** num controle, o eco do próximo
  passo pode cortar o fim da nota do acerto anterior (H07: um som por vez).
  É o certo: o eco é a pista.
- **O despencar não passa de 0** e apaga as pedras acesas acima.
- **`primeiro_a_chegar`:** ao chegar, todos `acabou` no mesmo quadro — o kit
  fecha; não espere os outros.
- **Os pontos e o item:** se o kit já aplica `Itens.pontos_do_acerto`, marque cru.

## Pronto quando

O Eco do Abismo joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o
robô nos três temperamentos; aguenta o cabo que cai e volta; fecha com
vencedor (o primeiro no topo, ou o mais alto); a prova do jogo passa; e
`bash tests/prova_visual.sh` passa com a **prancha olhada** com o Eco nela
(na cópia de trabalho, sem commitar: `"S06_J27"` em primeiro na lista da
seção `S06` e `"canto"` no lugar de `"viga"` em `Partida.NA_ORDEM[5]`; depois
volte os dois arquivos) — no escuro da nuvem, a prancha confere a
disposição; a aparência é o André quem aprova.

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, depois da prova do Canto:

```gdscript
## Eco do Abismo (S06_J27): o eco chega ao alto-falante do dono; o degrau
## nunca passa do topo nem fica negativo; o vencedor é o mais alto.
func _prova_do_eco() -> void:
	var fora := [0]
	var olhar := func(m: Minigame) -> void:
		for l in m.presentes():
			if int(m.degrau[l]) < 0 or int(m.degrau[l]) > m.DEGRAUS:
				fora[0] += 1
	var mg := await _joga_o_minigame("S06_J27", 60.0, olhar)
	if mg == null:
		return
	_esperar(fora[0] == 0, "Eco: o degrau sempre entre 0 e o topo")
	var v := mg.vencedor()
	_esperar(not v.is_empty() and int(mg.degrau[v[0]]) == v.map(func(l): return int(mg.degrau[l])).max(), "Eco: vence o mais alto")
	var ecos := _linha_do_tempo().filter(func(e): return e.get("tipo") == "jogo" and e.get("slot") == "S06_J27" and e.get("o") == "chamada")
	var resp := _linha_do_tempo().filter(func(e): return e.get("tipo") == "jogo" and e.get("slot") == "S06_J27" and e.get("o") == "resposta")
	_esperar(ecos.size() >= 1 and resp.size() >= 1, "Eco: %d ecos e %d pisadas no registro" % [ecos.size(), resp.size()])
```

**O que o André joga e sente** (`./run-local.sh -- --sala=S06_J27`, com a luz da sala apagada):

- o eco grave e o agudo se distinguem na mão, no meio da música;
- dá para subir olhando só para o próprio cavaleiro (a tela não ajuda);
- o despencar é engraçado e dói; o caminho aceso mostra quanto subiu;
- a barra de luz fica meia-luz no escuro e pulsa a cada degrau.

## Ao terminar

- No [quadro](README.md): a linha **N2** (se não existir, acrescente
  `| [N2](N2-eco-do-abismo.md) | N | S6 — Eco do Abismo | M | — | 1,5 | feito (<commit>) | <gasto> |`),
  com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: Eco do Abismo — a escada no escuro que só o alto-falante mostra`
