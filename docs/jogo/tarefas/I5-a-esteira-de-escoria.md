# I5 — A Esteira de Escória

**Sprint:** I · **Slot:** S01_J05 · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 1,5 · **Depende de:** H04, H08, F09, F03, H07, I1 (o `secao.gd`)

## Por quê

Prensar é apertar o botão que o lingote pede, na sua vez — e roubar é
apertar o mesmo botão no lingote do outro, antes dele e mais certeiro: os
três botões de face, pedidos e respondidos por todos ao mesmo tempo, com a
esteira dizendo de quem é a vez.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [H04 — O kit do minigame](H04-o-kit-do-minigame.md)
- [A linha n.º 5 em 03](../03-os-45-minigames.md#s1--a-centelha--botões-analógicos-gatilhos-analógicos)
- [O índice da seção](I-a-centelha.md) e a [I1](I1-o-martelo-de-hefesto.md#o-cenário)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S01_J05",
	"titulo": "A Esteira de Escória",
	"verbo": "Prense!",
	"genero": "sabotagem",
	"icone": "cross",
	"entradas": [Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO],
	"camera": "fixa",
	"faixa": "MUS_S01_J05",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "metal",
	"microjogo": {"verbo": "Prense!", "segundos": 6.0},
}
```

## Como se joga

- **A faixa:** `MUS_S01_J05` — até a H05, a sintetizada a 108 bpm; com a
  gerada, 125 bpm ("fábrica, bigorna e ar comprimido").
- **A esteira e a prensa:** uma esteira só, da esquerda para a direita,
  passa por baixo de uma prensa no meio. Os lingotes andam 2 m por tempo e
  ficam debaixo da prensa exatamente na batida deles. Cada lingote tem **a
  cor do dono** e, em cima, **o glifo do botão** do compasso: ✕, ○, □, ✕, ○,
  □… (`[CRUZ, CIRCULO, QUADRADO][c % 3]`, `c = floor(b / 4)`).
- **O hoqueto em colcheias:** o lingote do lugar `l` passa na batida
  `2k + 0,5·l`. Dois por compasso para cada um; um a cada meio tempo na
  esteira. `Ritmo.simples[l]`: um a cada 4 tempos.
- **Prensar o seu:** o botão do lingote, com ele debaixo da prensa →
  `julgar_toque`. Outro botão, na janela do seu → erro. A janela do dono é
  `± (JANELA_BOM + 0,05 s)`; o lingote passou sem prensa → nota perdida, e
  ele cai no fosso.
- **Roubar o do outro:** apertar o botão certo de um lingote que **não é
  seu** a no máximo `JANELA_OTIMO` (90 ms) da batida dele, **antes** do
  dono → o lingote troca de cor e vai para a pilha do ladrão; para o dono,
  é nota perdida (roubado). Um aperto fora de qualquer janela, ou o botão
  errado num roubo, **emperra a sua alavanca** por 2 tempos: o seu lingote
  que passar nesse tempo cai no fosso (sem erro no registro: foi a prensa
  travada).
- **Os pontos por julgamento** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 20, 35, 50]`;
  o roubo +30. Cada lingote prensado ou roubado conta 1 na pilha.
- **A progressão:** `progresso()` do kit (em tempo de música, H08). De 0 a 1/3, as colcheias. **O
  pico (1/3 a 2/3), a esteira dobra:** o lingote de cada um passa em todo
  tempo (`k + 0,25·l`), um a cada quarto de tempo na esteira, e o ar
  comprimido sopra faísca na prensa. De 2/3 em diante, as colcheias.
  Lingotes de cada um em 90 s: ~70 a 108 bpm, ~85 a 125 bpm.

## O cenário

`SECAO.montar(self)` e, no meio da forja, a fábrica:

| o quê | peça | onde (m) |
| --- | --- | --- |
| a esteira | `Kit.caixa(22.0, 0.3, 1.2)`, `#2a2233`; as travessas `Kit.caixa(0.1, 0.05, 1.1)`, `#4a4e5e`, a cada 1 m, que andam pela batida | centro `(0, 0.15, −1.2)` |
| a prensa | dois `column` em `x = ±1.2`; o bloco `Kit.caixa(1.6, 1.0, 1.4)`, `#4a4e5e`, que desce a cada prensa (0,15 s) | `(0, 2.2, −1.2)` |
| o fosso | `Kit.caixa(1.6, 0.1, 1.6)`, `#140f1a`, e uma `OmniLight3D` `#ff6a2a` embaixo | `(10.8, −0.05, −1.2)` |
| o lingote | `Kit.caixa(0.6, 0.2, 0.3)`, a cor do dono `darkened(0.3)` (o do ladrão, quando roubado); o glifo do botão num `Sprite3D` 0,5 m acima | `x = (batida − b) × 2`, `(x, 0.4, −1.2)`; visível de `x = −10` a `x = 10.8` |
| a raia | `raia(l)` | `(RAIAS[l], 0, Z_JOGADOR)` |
| a alavanca | `Kit.caixa(0.1, 0.8, 0.1)`, ferro, inclinada; pisca `Tema.LARANJA` (faíscas) quando emperra | `(RAIAS[l] + 0.6, 0.4, Z_JOGADOR − 0.6)` |
| a pilha | os lingotes do lugar, `Kit.caixa(0.5, 0.18, 0.25)` na cor dele, empilhados de 5 em 5 | `(RAIAS[l], 0.1 + 0.2·(k / 5), −3.2)`, `x` somando `0.55·(k % 5) − 1.1` |
| o prensador | o boneco, de frente para a esteira | `(RAIAS[l], 0.05, Z_JOGADOR)`, olhando `(RAIAS[l], 0, −1.2)` |

Câmera: `camera_pos = Vector3(0, 7.5, 11.0)`, `camera_olhar = Vector3(0, 0.6, -1.4)`.
A cor dos lugares só nos lingotes deles e nas raias. Tudo em caixa.

## O repertório

| recurso | o que acontece, e quando |
| --- | --- |
| **os botões (a feature)** | o botão do lingote, na sua vez; o mesmo botão, antes do dono, para roubar |
| vibração | o kit por nota; o seu roubado: `Forja.sentir(l, "golpe")`; o roubo que deu certo: `Forja.sentir(l, "perfeito")`; a alavanca emperrada: `Forja.sentir(l, "erro")` |
| barra de luz | o kit (`_reagir`, H08): branco no perfeito, a cor do lugar escurecida no erro |
| alto-falante do dono | perfeito: a nota (o kit); ótimo e bom: `Som.no_controle(l, "carimbo", 0.5)`; o roubo: `Forja.som_falante(l, "coleta", 0.8)`; erro: a nota quebrada (o kit) |
| gatilho | livre (o R2 Off) |
| háptica por material | `metal`, pelo kit |
| som na TV | a nota (o kit); `martelo` a cada prensada (na prensa); `golpe` no roubo; `falha` baixo no fosso |

## A falha

O lingote escapa e cai no fosso: ele segue a esteira até a ponta e despenca
(`position.y` até −1,5 em meio tempo, e some) com faíscas `Tema.LARANJA`; o
dono faz `emote-no`. Roubado: o lingote salta da esteira para a pilha do
ladrão, e o dono faz `emote-no`. Emperrado: faíscas na alavanca, e ela fica
de pé por 2 tempos.

## O fim e o vencedor

90 s (a F03). `vencedor()`: mais lingotes na pilha; empate pelos pontos,
depois pelo lugar.

## Com menos de quatro

A esteira fica mais vazia (só os lingotes de quem está); nada mais muda.
Sozinho, não há de quem roubar: o jogo é prensar os seus. **O controle que
cai:** os lingotes dele já na esteira passam e caem no fosso sem erro, e
nenhum novo nasce enquanto ele está sem controle; ao voltar, o próximo nasce
na próxima batida dele pelo menos 1 tempo adiante.

## O robô

Prensa os seus na batida (ou 200 ms atrasado, quando não acerta). Tenta
roubar um lingote a cada seis que passam (os de índice `(i + l) % 6 == 0`):
consulta `Forja.robo_acerta()` e, se acerta, aperta 30 ms antes da batida
do outro.

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var agora := Ritmo.t_musica()
	for ing in lingotes:
		if str(ing.estado) != "vindo" or bool(ing.get("robo_" + str(l), false)):
			continue
		var alvo := Ritmo.t_da_batida(float(ing.b))
		if int(ing.dono) == l:
			if not ing.has("mira"):
				# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado
				ing["mira"] = 0.0 if Forja.robo_acerta() else 0.20
			if agora >= alvo + float(ing.mira):
				Forja.robo_apertar(l, int(ing.botao), 0.05)
				ing["robo_" + str(l)] = true
		elif (int(ing.i) + l) % 6 == 0 and agora >= alvo - 0.03 and agora < alvo:
			if Forja.robo_acerta():
				Forja.robo_apertar(l, int(ing.botao), 0.05)
			ing["robo_" + str(l)] = true
```

## Os ganchos

`godot/scripts/minigames/s01/esteira_de_escoria.gd`:

```gdscript
extends Minigame
## A Esteira de Escória (S01_J05). Uma esteira passa por baixo de uma prensa;
## cada lingote tem a cor do dono e o glifo do botão do compasso, e fica
## debaixo da prensa na batida do dono (o hoqueto em colcheias). O botão
## certo na sua vez prensa o seu; o mesmo botão no lingote do outro, antes
## dele e a menos de 90 ms, rouba. No meio, a esteira dobra.
##
## A falha: o lingote escapa e cai no fosso; roubado, salta para a pilha do
## outro; o aperto à toa emperra a alavanca por 2 tempos.
## O vencedor: mais lingotes; no empate, mais pontos.
## O alto-falante do dono: o carimbo no acerto, a nota no perfeito, a coleta no roubo.
## O registro mede: cada botão pedido e dado (o kit), o botão que chegou no
## lugar do pedido, os roubos e os emperros (a linha `entrada`).
## O robô: prensa os seus na batida; tenta roubar um em seis, 30 ms antes do dono.
## Com menos de quatro: a esteira fica mais vazia.
## A régua: "Prense!" e o glifo no lingote bastam; sem a tela, a nota do lugar
## na TV marca a vez de cada um; nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s01/secao.gd")

# (a FICHA vem aqui)

const BOTOES := [Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO]
const GLIFO := {Forja.CRUZ: "cross", Forja.CIRCULO: "circle", Forja.QUADRADO: "square"}
const VELOCIDADE := 2.0  ## m por tempo
const X_FOSSO := 10.8
const ADIANTE := 6.0  ## tempos: o lingote nasce tantos tempos antes da prensa
const PONTOS := [0, 20, 35, 50]
const ROUBO := 30
const EMPERRA := 2.0  ## tempos
const FOLGA := 0.05
const Z_ESTEIRA := -1.2

var j := {}
var lingotes: Array = []  ## {i, b, dono, botao, n, estado ("vindo", "prensado", "roubado", "caiu"), no, glifo}
var _i := 0  ## o índice do próximo lingote
var _ing: Dictionary = {}  ## o lingote em julgamento (para toque/falha)
var _roubo := false  ## a falha em curso é um roubo
var _bloco: Node3D
var _travessas: Array = []
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]


func montar() -> void:
	camera_pos = Vector3(0, 7.5, 11.0)
	camera_olhar = Vector3(0, 0.6, -1.4)
	SECAO.montar(self)
	var ferro := Kit.material(Color("#4a4e5e"), 0.0, 0.7)
	Kit.caixa(self, Vector3(22.0, 0.3, 1.2), Vector3(0, 0.15, Z_ESTEIRA), Kit.material(Color("#2a2233"), 0.0, 0.9))
	for k in 22:
		_travessas.append(Kit.caixa(self, Vector3(0.1, 0.05, 1.1), Vector3(-11.0 + k, 0.32, Z_ESTEIRA), ferro))
	for x in [-1.2, 1.2]:
		Kit.peca(self, "column", Vector3(x, 0, Z_ESTEIRA))
	_bloco = Kit.caixa(self, Vector3(1.6, 1.0, 1.4), Vector3(0, 2.2, Z_ESTEIRA), ferro)
	Kit.caixa(self, Vector3(1.6, 0.1, 1.6), Vector3(X_FOSSO, -0.05, Z_ESTEIRA), Kit.material(Color("#140f1a"), 0.0, 1.0))
	var brasa := OmniLight3D.new()
	brasa.position = Vector3(X_FOSSO, -0.6, Z_ESTEIRA)
	brasa.light_color = Color("#ff6a2a")
	brasa.light_energy = 1.2
	brasa.omni_range = 3.0
	add_child(brasa)
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		var alavanca := Kit.caixa(self, Vector3(0.1, 0.8, 0.1), Vector3(RAIAS[l] + 0.6, 0.4, Z_JOGADOR - 0.6), ferro)
		maos_livres(p)
		p.position = Vector3(RAIAS[l], 0.05, Z_JOGADOR)
		p.olhar_para(Vector3(RAIAS[l], 0, Z_ESTEIRA))
		j[l] = {"prox_b": -1.0, "n": 0, "pilha": 0, "emperrado_ate": -1.0, "fora": false, "alavanca": alavanca}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


func _proxima_batida(l: int, b: float) -> float:
	var passo := 2.0
	var desloc := 0.5 * l
	if Ritmo.simples[l]:
		passo = 4.0
	elif no_pico():
		passo = 1.0
		desloc = 0.25 * l
	return proxima_batida(l, b + 0.001, passo, desloc)  # o kit; estritamente depois de b


func iniciar_jogo() -> void:
	for l in presentes():
		j[l].prox_b = _proxima_batida(l, BATIDA_DA_PRIMEIRA_NOTA - 0.01)


## Um lingote novo do lugar na batida b (nasce ADIANTE tempos antes, à esquerda).
func _nascer(l: int, b: float) -> void:
	var e: Dictionary = j[l]
	var botao: int = BOTOES[int(floor(b / 4.0)) % 3]
	var no := Kit.caixa(self, Vector3(0.6, 0.2, 0.3), Vector3(-12.0, 0.4, Z_ESTEIRA),
		Kit.material(Forja.cor_do_lugar(l).darkened(0.3), 0.0, 0.8))
	var glifo := Sprite3D.new()
	glifo.texture = Desenho.glifo(GLIFO[botao])
	glifo.pixel_size = 0.004
	glifo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glifo.shaded = false
	glifo.position = Vector3(0, 0.5, 0)
	no.add_child(glifo)
	lingotes.append({"i": _i, "b": b, "dono": l, "botao": botao, "n": int(e.n), "estado": "vindo", "no": no, "glifo": glifo})
	nova_nota(l, int(e.n), Ritmo.t_da_batida(b))
	e.n = int(e.n) + 1
	_i += 1


func jogar(_dt: float) -> void:
	var agora_b := Ritmo.batida()
	var agora := Ritmo.t_musica()
	# os lingotes nascem ADIANTE tempos antes da batida deles
	for l in presentes():
		var e: Dictionary = j[l]
		if not conectado(l):
			e.fora = true
			continue
		if bool(e.fora):
			e.fora = false
			e.prox_b = _proxima_batida(l, agora_b + 1.0)
		while float(e.prox_b) > 0.0 and float(e.prox_b) <= agora_b + ADIANTE:
			_nascer(l, float(e.prox_b))
			e.prox_b = _proxima_batida(l, float(e.prox_b))
	# os apertos: o seu lingote, um roubo, ou a alavanca emperra
	for l in presentes():
		if not conectado(l):
			continue
		for b in BOTOES:
			if Forja.apertou(l, b):
				_apertou(l, b, agora)
				break
	# os que passaram sem prensa
	for ing in lingotes:
		if str(ing.estado) != "vindo" or agora <= Ritmo.t_da_batida(float(ing.b)) + Ritmo.JANELA_BOM + FOLGA:
			continue
		var dono: int = ing.dono
		ing.estado = "caiu"
		if conectado(dono) and not _emperrou_na_hora(dono, ing):
			_ing = ing
			_roubo = false
			nota_perdida(dono, int(ing.n))
	_mostrar()


## A alavanca estava emperrada quando o lingote passou (então não é erro do registro).
func _emperrou_na_hora(dono: int, ing: Dictionary) -> bool:
	return float(ing.b) < float(j[dono].emperrado_ate)


func _apertou(l: int, botao: int, agora: float) -> void:
	# 1. o seu lingote, na janela do dono
	for ing in lingotes:
		if str(ing.estado) != "vindo" or int(ing.dono) != l:
			continue
		var alvo := Ritmo.t_da_batida(float(ing.b))
		if absf(agora - alvo) <= Ritmo.JANELA_BOM + FOLGA:
			if Ritmo.batida() < float(j[l].emperrado_ate):
				return  # a alavanca está emperrada: o aperto não sai
			_ing = ing
			_roubo = false
			ing.estado = "prensado"
			if botao == int(ing.botao):
				julgar_toque(l, alvo, int(ing.n))
			else:
				Forja.evento("entrada", l + 1, {"o": "botao", "pedido": GLIFO[int(ing.botao)], "chegou": GLIFO[botao], "n": int(ing.n)})
				nota_perdida(l, int(ing.n))
			return
	# 2. o lingote de outro, antes do dono e a menos de JANELA_OTIMO
	for ing in lingotes:
		if str(ing.estado) != "vindo" or int(ing.dono) == l:
			continue
		var alvo2 := Ritmo.t_da_batida(float(ing.b))
		if absf(agora - alvo2) <= Ritmo.JANELA_OTIMO and botao == int(ing.botao):
			_roubar(l, ing)
			return
	# 3. à toa: emperra
	j[l].emperrado_ate = Ritmo.batida() + EMPERRA
	Forja.evento("entrada", l + 1, {"o": "botao", "emperrou": true, "chegou": GLIFO[botao]})
	Forja.sentir(l, "erro")
	Efeitos.faiscas(self, Vector3(RAIAS[l] + 0.6, 0.9, Z_JOGADOR - 0.6), Tema.LARANJA, 14, 0.6)


func _roubar(l: int, ing: Dictionary) -> void:
	var dono: int = ing.dono
	ing.estado = "roubado"
	Forja.evento("entrada", l + 1, {"o": "botao", "roubou_de": dono, "n": int(ing.n)})
	marcar(l, ROUBO)
	if not treinando:
		j[l].pilha = int(j[l].pilha) + 1
	Forja.sentir(l, "perfeito")
	Forja.som_falante(l, "coleta", 0.8)
	Som.tocar("golpe", Vector3(0, 1.0, Z_ESTEIRA), -4.0)
	_prensar_a_vista()
	(ing.no as MeshInstance3D).material_override = Kit.material(Forja.cor_do_lugar(l).darkened(0.3), 0.0, 0.8)
	_para_a_pilha(ing, l)
	if conectado(dono):
		_ing = ing
		_roubo = true
		nota_perdida(dono, int(ing.n))


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	marcar(l, PONTOS[julgamento])
	if not treinando:
		j[l].pilha = int(j[l].pilha) + 1
	if julgamento != Ritmo.PERFEITO:
		Som.no_controle(l, "carimbo", 0.5)
	Som.tocar("martelo", Vector3(0, 1.0, Z_ESTEIRA), -4.0)
	_prensar_a_vista()
	if not _ing.is_empty():
		_para_a_pilha(_ing, l)
	var p := jogador(l)
	if p:
		p.gesto("attack-melee-right", 0.35)


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	var p := jogador(l)
	if p:
		p.gesto("emote-no", 0.5)
	if _roubo:
		Forja.sentir(l, "golpe")
	elif not _ing.is_empty():
		_ing.estado = "caiu"  # segue até o fosso (o _mostrar derruba)


## A prensa desce e sobe (0,15 s).
func _prensar_a_vista() -> void:
	var tw := _bloco.create_tween()
	tw.tween_property(_bloco, "position:y", 1.0, 0.06)
	tw.tween_property(_bloco, "position:y", 2.2, 0.09)
	if no_pico():
		Efeitos.faiscas(self, Vector3(0, 0.6, Z_ESTEIRA), Tema.AMARELO, 10, 0.5)


## O lingote salta da prensa para a pilha do lugar.
func _para_a_pilha(ing: Dictionary, l: int) -> void:
	var no: MeshInstance3D = ing.no
	(ing.glifo as Node3D).visible = false
	var k := int(j[l].pilha)
	var ate := Vector3(RAIAS[l] + 0.55 * (k % 5) - 1.1, 0.1 + 0.2 * int(k / 5.0), -3.2)
	var de := no.position
	var voo := func(q: float) -> void:
		var pos := de.lerp(ate, q)
		pos.y += sin(q * PI) * 1.2
		no.position = pos
	var tw := no.create_tween()
	tw.tween_method(voo, 0.0, 1.0, 0.35)
	no.scale = Vector3(0.85, 0.9, 0.85)


func _mostrar() -> void:
	var agora_b := Ritmo.batida()
	for ing in lingotes.duplicate():
		var no: MeshInstance3D = ing.no
		var x := (agora_b - float(ing.b)) * VELOCIDADE
		match str(ing.estado):
			"vindo":
				no.position = Vector3(x, 0.4, Z_ESTEIRA)
				no.visible = x > -10.0
			"caiu":
				no.position.x = minf(x, X_FOSSO)
				if x >= X_FOSSO:
					no.position.y = 0.4 - clampf((x - X_FOSSO) / VELOCIDADE * 2.0, 0.0, 1.0) * 1.9
				if x >= X_FOSSO + VELOCIDADE:
					no.queue_free()
					lingotes.erase(ing)
			"prensado", "roubado":
				if x > VELOCIDADE * 2.0:
					lingotes.erase(ing)  # o nó fica na pilha
	for k in _travessas.size():
		(_travessas[k] as Node3D).position.x = -11.0 + fposmod(k + agora_b * VELOCIDADE, 22.0)
	for l in presentes():
		var alav: Node3D = j[l].alavanca
		alav.rotation.z = 0.0 if agora_b < float(j[l].emperrado_ate) else 0.5


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(_antes)
	return lista


func _antes(a: int, b: int) -> bool:
	if int(j[a].pilha) != int(j[b].pilha):
		return int(j[a].pilha) > int(j[b].pilha)
	if int(pontos[a]) != int(pontos[b]):
		return int(pontos[a]) > int(pontos[b])
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		return "Lingotes: %d" % int(j[lugar].pilha)
	return super(lugar)
```

## O que o registro mede

- O kit: uma `nota` por lingote de cada um (nasce 6 tempos antes: o
  `t_alvo` é a batida da prensa) e um `toque` por prensada (ou `perdida`).
- A linha `entrada`: o botão que chegou no lugar do pedido, os roubos (de
  quem) e os emperros (o botão à toa). Com os três botões de face apertados
  por quatro pessoas ao mesmo tempo, um botão que troca com outro, ou que
  chega no controle vizinho, aparece aqui.

## Armadilhas

- **`_ing` e `_roubo` antes de `julgar_toque`/`nota_perdida`:** o kit chama
  `toque`/`falha` sem dizer qual lingote; eles leem daqui.
- **O lingote que passou com a alavanca emperrada** cai sem `nota_perdida`
  (não é erro de ritmo); o registro fica com a `nota` sem `toque` — o
  cruzamento lê a `entrada` do emperro logo antes.
- **Apagar da lista, não do mundo:** o lingote prensado vira peça da pilha;
  só o que caiu no fosso some (`queue_free`).
- **Iterar numa cópia** (`lingotes.duplicate()`) quando apaga no laço.
- **O dono ainda aperta depois do roubo:** o lingote não está mais `vindo`,
  então o aperto vai para o roubo/emperro — está certo: ele perdeu a vez.
- **Material por lingote:** `Kit.material` cria um material novo a cada
  lingote (uns 300 no minigame). Se a prancha mostrar menos de 55 fps, guarde
  um material por lugar num dicionário.

## Pronto quando

A Esteira joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô
nos três temperamentos (o bom rouba, o ruim emperra); o cabo que cai e volta
não gera erro para quem saiu; o fim tem sempre vencedor;
`bash tests/prova_do_jogo.sh` passa; e `bash tests/prova_visual.sh` passa
com a prancha **olhada** nas partidas em que a Esteira aparece.

## Provas

Em `godot/testes/prova_do_jogo.gd`:

```gdscript
## S01_J05 (I5): a Esteira abre pelo catálogo; cada lugar prensa lingotes
## pelo botão simulado; o fim tem vencedor pela pilha.
func _prova_da_esteira() -> void:
	# a espera é a da H08: o aviso em quadros, o jogo pelo relógio de parede (90 s de música e o treino)
	var mg = await _joga_o_minigame("S01_J05", 130.0)
	if mg == null:
		return
	for l in 4:
		var c: Array = mg.contagem[l]
		_esperar(int(c[1]) + int(c[2]) + int(c[3]) >= 1, "S01_J05 P%d: prensou o seu %s" % [l + 1, c])
	var v: Array = mg.vencedor()
	_esperar(int(mg.j[v[0]].pilha) >= int(mg.j[v[v.size() - 1]].pilha), "S01_J05: o vencedor tem a maior pilha")
	var q := 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "S01_J05: de volta ao salão")
```

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**O André (local):** `./run-local.sh -- --sala=S01_J05` com quatro pessoas:
a esteira na cor de cada um se lê de longe, o roubo dá grito, o emperro
segura quem aperta à toa, e a esteira dobrada do meio é o caos.

## Ao terminar

- Catálogo: `"S01_J05": preload("res://scripts/minigames/s01/esteira_de_escoria.gd")`
  em `MINIGAMES` e na lista da S01.
- `traducoes.gd`: `"A Esteira de Escória": "The Slag Conveyor"`, `"Prense!": "Press!"`;
  em `EN_PADROES`, `["^Lingotes: (\\d+)$", "Ingots: $1"]`.
- Importe e ponha o `.uid` no commit.
- No [quadro](README.md), a I5 **feito**, com o commit e o gasto real.
- Commit (sem trailer): `feat: A Esteira de Escória — prensar na sua vez, roubar antes do dono`
