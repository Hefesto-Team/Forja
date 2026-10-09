# J5 — Mira Óptica

**Sprint:** J · **Slot:** S02_J10 · **Tamanho:** M · **Depende de:** H04, H08, F09, F03, F05, H07, G05, G14, G03 (o L2 é do item), J1 (o `secao.gd`)

## Por quê

Mirar é girar o controle como uma luneta: a guinada e a arfagem levam a
mira, e o R2 dispara na batida em que o alvo acende, com a parede e o
clique da arma no dedo e o coice na mão. O giroscópio como ponteiro; o
escudo de ouro do meio é o único alvo que as quatro miras disputam.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [H08 — Os acréscimos do kit](H08-os-acrescimos-do-kit.md) (a fila de notas, `anotar`, `andamento`, `tempo_que_resta`)
- [J1 — O secao.gd](J1-a-viga.md#o-secaogd) (a caverna, `agendar`, `momento`, `gancho`, `levantar`, `pista_s`, `peca_no_tamanho`)

## Arquivos que mudam

| arquivo | o que muda | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s02/mira_optica.gd` | **novo**: o minigame | não |
| `godot/scripts/minigames/catalogo.gd` | o slot `S02_J10` | sim: as cinco |
| `godot/scripts/traducoes.gd` | o título, o verbo e o status | sim: as cinco |
| `godot/testes/prova_do_jogo.gd` | `_prova_da_mira()` e a linha no `_prova_da_ficha` | sim: as cinco |
| `godot/testes/captura_jogo.gd` | os momentos de `"S02_J10"` | sim: as cinco |

O `secao.gd`, `"momento"` em `TIPOS_DO_JOGO`, a linha `momento` no 13 e o
`_linhas_do_minigame()` e o `_notas_por_terco()` da prova são da J1: esta
ficha só os usa.

### O estado de hoje

Não existe `mira_optica.gd`. A ficha anterior trazia a moldura e o disparo
em `Tema.AMARELO`, as faíscas do ricochete em `Tema.LARANJA` (os dois são de
interface), o painel `#3a3346` solto, os painéis nas raias (x ±6, longe
demais para quatro miras disputarem o mesmo alvo), o L1 com ícone, nenhum
coice e nenhum grito. Esta ficha troca tudo pelos tokens do Tema e pelo
`secao.gd`, aproxima os painéis, e acrescenta o escudo de ouro como
momento, o coice, o líder embaçado no ouro e a reta.

### Ao terminar

1. `godot/scripts/minigames/catalogo.gd`: em `MINIGAMES`,
   `"S02_J10": preload("res://scripts/minigames/s02/mira_optica.gd")`; na
   lista `minigames` da S02, `"S02_J10"` logo depois de `"S02_J09"`.
2. `godot/scripts/traducoes.gd`: `"Mira Óptica": "Optical Aim"`,
   `"Mire!": "Aim!"`; em `EN_PADROES`, `["^Alvos: (\\d+)$", "Targets: $1"]`.
3. `godot/testes/prova_do_jogo.gd` e `godot/testes/captura_jogo.gd`: o que
   está em **Provas**.
4. `"$GODOT" --headless --path godot --import --quit`; o
   `mira_optica.gd.uid` entra no commit.
5. O quadro sai do cabeçalho desta ficha: nada a editar nele.
6. Commit (sem trailer): `feat(mira): a Mira Óptica, a luneta no giroscópio, o coice e o escudo de ouro`.

## Como se joga

- **A faixa:** `MUS_S02_J10`. Até a H05, a sintetizada da seção a 96 BPM;
  com a gerada, `mus_s02_j10` a 115 BPM (trap espaçado, foco).
- **Os painéis:** na parede do fundo (`z = −5,75`), um painel por lugar em
  `x = −3,0; −1,0; 1,0; 3,0` (P1 a P4), cada um com seis escudos
  `shield-round` de 0,55 m numa grade de 3 × 2: `x ∈ {−0,6; 0; 0,6}` do
  meio do painel, `y ∈ {1,5; 2,3}`. Acima dos dois do meio, o **painel do
  ouro** em `(0; 3,6)`.
- **A mira:** um retículo na cor do lugar, na parede inteira (`x` de −3,95
  a 3,95, `y` de 1,2 a 4,1); começa no meio do painel do dono. **Girar o
  controle** a leva: `m.x −= giro.y × 3,0 × dt`, `m.y += giro.x × 3,0 × dt`
  (3,0 m por rad). Sem giroscópio, o analógico direito (× 3,5 m/s). **O
  L1** traz a mira ao meio do painel do dono (sem ícone na ficha).
- **O hoqueto em colcheias:** o alvo do lugar `l` acende na batida
  `2k + 0,5·l`: a moldura fraca 1 tempo antes (a prévia, mais o Faro),
  cheia na batida, e some 1 tempo depois. Sorteado pela semente, nunca o
  mesmo escudo duas vezes seguidas. `Ritmo.simples[l]`: um a cada 4 tempos.
- **O tiro:** o R2 cruza 75 % vindo de menos de 50 % (com a arma do
  gatilho, o clique fica ali). Todo tiro dá **o coice**: `sentir golpe_dir`
  40 ms, e a mira ignora o giro abaixo de 0,3 rad/s nos 60 ms seguintes.
  Com a janela da nota aberta (meio tempo antes): a mira a menos de 0,35 m
  do escudo aceso: `julgar_toque`; longe dele: erro (ricochete). Tiro antes
  da janela: ricochete sem nota. A nota passou sem tiro (`FOLGA_PERDIDA`,
  0,140 s): perdida.
- **O ricochete embaça a mira** por 1 tempo × `levantar`: o retículo 1,6
  vez maior e metade da sensibilidade.
- **Os pontos** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 20, 35, 50]`. Cada
  acerto derruba o escudo (ele gira e volta no próximo acender) e conta 1.
- **O escudo de ouro**, no pico e nas últimas 16 batidas: um disco de 1,2 m
  no painel do ouro, à vista 4 tempos antes (fosco), a prévia 1 tempo
  antes, aceso na batida 1 do compasso. O primeiro tiro a menos de 0,6 m
  dele, de meio tempo antes a `FOLGA_PERDIDA` depois, leva: conta **3** e
  100 pontos. Não é nota de ninguém: não tem erro. Os outros tiros nele
  depois disso ricocheteiam.
- **O líder no ouro:** quem lidera (`vencedor()[0]`, com 1 ou mais escudos)
  quando o ouro aparece tem a mira embaçada de 1 tempo antes da batida do
  ouro até ela. A janela não muda.

### A curva

Os terços de 75 s: 25 s e 50 s (`andamento()` 1/3 e 2/3).

| trecho | os alvos | o mundo |
| --- | --- | --- |
| 0 a 25 s | um a cada 2 tempos (`2k + 0,5·l`) | — |
| 25 a 50 s, o tiroteio | um por tempo (`k + 0,25·l`); os escudos balançam ±0,3 m na batida | o escudo de ouro a cada 2 compassos, na batida 1; a lava sobe a 1,0 e a câmera recua 10 % em 2 batidas |
| 50 s ao fim, a reta | um a cada 2 tempos | — |
| as últimas 16 batidas | um a cada 2 tempos; cada escudo conta 2 e vale o dobro de pontos | o ouro a cada compasso; a linha `momento` `reta` |

### A ficha de dados

```gdscript
const FICHA := {
	"slot": "S02_J10",
	"titulo": "Mira Óptica",
	"verbo": "Mire!",
	"genero": "tct",
	"icone": "giroscopio",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S02_J10",
	"duracao": 75.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "golpe_dir"],
	"material": "metal",
	"microjogo": {"verbo": "Mire!", "segundos": 6.0},
}
```

`"entradas": []`: o L1 continua trazendo a mira ao meio, mas não aparece
no aviso (a diversão: se alguém se perder, aperta; não é parte do jogo).

### O fim e o vencedor

75 s (a F03). `vencedor()`: mais escudos (o ouro conta 3); empate pelos
pontos, depois pelo lugar.

### Com menos de quatro

Os painéis dos ausentes ficam vazios (sem escudos); o ouro é igual. **O
controle que cai:** os alvos dele param (sem erro); ao voltar, a mira volta
ao meio do painel, o R2 recebe a arma de novo e o próximo alvo é a próxima
batida dele pelo menos 1 tempo adiante. **Sem giroscópio:** o analógico
direito; a linha `troca` diz qual.

### Os ganchos

`godot/scripts/minigames/s02/mira_optica.gd`:

```gdscript
extends Minigame
## Mira Óptica (S02_J10). Cada um tem um painel de seis escudos na parede do
## fundo; girar o controle leva a mira (guinada e arfagem), o L1 a traz ao
## meio. O escudo do lugar acende na batida dele (o hoqueto em colcheias): o
## R2 dispara, com a parede e o clique da arma e o coice. No meio, o
## tiroteio: um alvo por tempo, os escudos balançam, e o escudo de ouro do
## painel do meio, que os quatro disputam.
##
## A falha: o disparo fora do alvo ricocheteia e embaça a mira por um tempo.
## O vencedor: mais escudos (o ouro conta 3).
## O alto-falante do dono: o alvo no acerto, o tinido no ouro, a nota no
## perfeito (o kit).
## O registro mede: a distância da mira ao alvo em cada disparo (a linha
## `entrada`), o atraso (o kit), o ouro e a reta (a linha `momento`).
## O robô: gira até o escudo a partir da prévia (até o ouro, quando ele vem
## antes) e dispara na batida (ou 200 ms atrasado).
## Com menos de quatro: os painéis vazios; o ouro igual.
## A régua: "Mire!" e o giroscópio bastam; o alvo é visual (a prévia avisa);
## nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s02/secao.gd")

# (a FICHA vem aqui)

const PAINEL_X := [-3.0, -1.0, 1.0, 3.0]
const POSICOES := [Vector2(-0.6, 1.5), Vector2(0.0, 1.5), Vector2(0.6, 1.5),
	Vector2(-0.6, 2.3), Vector2(0.0, 2.3), Vector2(0.6, 2.3)]
const OURO := Vector2(0.0, 3.6)
const MIRA_X := 3.95
const MIRA_Y0 := 1.2
const MIRA_Y1 := 4.1
const SENSIBILIDADE := 3.0  ## m de mira por rad girado
const ANALOGICO := 3.5  ## m/s com o analógico cheio
const RAIO := 0.35
const RAIO_OURO := 0.6
const Z_PAINEL := -5.6
const DISPARA := 0.75
const SOLTO := 0.5
const COICE_S := 0.06
const COICE_GIRO := 0.3  ## rad/s
const PONTOS := [0, 20, 35, 50]
const VALE_OURO := 3
const PONTOS_OURO := 100
const CAMERA := Vector3(0, 5.0, 13.5)
const OLHAR := Vector3(0, 1.8, -3.0)

var j := {}
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
var _ouro: MeshInstance3D
var _ouro_b := -1.0  ## a batida do ouro à vista (-1: nenhum)
var _ouro_lider := -1
var _ouro_dono := -1  ## quem levou o ouro desta batida (-1: ninguém ainda)
var ouro_t := -1.0  ## o t_musica do último ouro levado
var _reta := false


func montar() -> void:
	SECAO.limpar()
	camera_pos = CAMERA
	camera_olhar = OLHAR
	SECAO.montar(self)
	var grafite := Kit.material(Tema.GRAFITE, 0.0, 0.9)
	Kit.caixa(self, Vector3(1.4, 1.4, 0.1), Vector3(OURO.x, OURO.y, -5.75), grafite)
	_ouro = Kit.cilindro(self, 0.6, 0.08, Vector3(OURO.x, OURO.y, Z_PAINEL), Kit.material(Tema.TUNGSTENIO, 0.3))
	_ouro.rotation.x = PI * 0.5
	_ouro.visible = false
	for p in jogadores:
		var l: int = p.lugar
		var x: float = PAINEL_X[l]
		Kit.caixa(self, Vector3(1.9, 1.8, 0.1), Vector3(x, 1.9, -5.75), grafite)
		var escudos: Array = []
		for pos in POSICOES:
			var suporte := Node3D.new()  # o escudo anda pelo suporte (o balanço do pico)
			suporte.position = Vector3(x + pos.x, pos.y, Z_PAINEL)
			add_child(suporte)
			SECAO.peca_no_tamanho(suporte, "shield-round", Vector3.ZERO, Vector3(0.55, 0.55, 0.1), Kit.material(Tema.OXIDO_BRILHO, 0.0, 0.6))
			escudos.append(suporte)
		var moldura := Kit.caixa(self, Vector3(0.62, 0.62, 0.04), Vector3(x, 1.5, Z_PAINEL - 0.08), Kit.material(Tema.JOGADOR[l], 2.0))
		moldura.visible = false
		var mira := Node3D.new()
		add_child(mira)
		var tinta := Kit.chapado(Tema.JOGADOR[l], true)
		for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			var tam := Vector3(0.2, 0.04, 0.02) if d.y == 0 else Vector3(0.04, 0.2, 0.02)
			Kit.caixa(mira, tam, Vector3(d.x * 0.3, d.y * 0.3, 0), tinta)
		Kit.caixa(mira, Vector3(0.06, 0.06, 0.02), Vector3.ZERO, tinta)
		maos_livres(p)
		p.preso = true
		p.position = Vector3(x, 0.05, 4.2)
		p.rotation.y = PI
		j[l] = {"n": 0, "b": -1.0, "alvo": -1, "mira": _centro(l), "r2_antes": 0.0, "embaca_b": -99.0,
			"embaca_t": 1.0, "coice_t": -1.0, "derrubados": 0, "ouros": 0, "fora": false, "escudos": escudos,
			"moldura": moldura, "no_mira": mira, "robo_mira": 0.0, "robo_ouro": -1.0}


static func _centro(l: int) -> Vector2:
	return Vector2(PAINEL_X[l], 1.9)


func _ultimas_16() -> bool:
	return tempo_que_resta() <= 16.0 * 60.0 / Ritmo.bpm


func _proxima(l: int, desde: float) -> void:
	var e: Dictionary = j[l]
	var passo := 2.0
	var desloc := 0.5 * l
	if no_pico() and not Ritmo.simples[l]:
		passo = 1.0
		desloc = 0.25 * l
	e.n = int(e.n) + (1 if float(e.b) >= 0.0 else 0)
	e.b = proxima_batida(l, desde, passo, desloc)  # o kit dobra o passo na partitura simples
	var novo := rng.randi_range(0, POSICOES.size() - 2)
	if novo >= int(e.alvo) and int(e.alvo) >= 0:
		novo += 1
	e.alvo = novo
	nova_nota(l, int(e.n), Ritmo.t_da_batida(float(e.b)))


func iniciar_jogo() -> void:
	for l in presentes():
		SECAO.anotar_troca(self, l)
		Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, 8)
		_proxima(l, BATIDA_DA_PRIMEIRA_NOTA - 0.01)


## Onde o escudo `i` do lugar está agora, na parede (no pico, balança).
func _pos_do_alvo(l: int, i: int) -> Vector2:
	var pos: Vector2 = POSICOES[i] + Vector2(PAINEL_X[l], 0.0)
	if no_pico():
		pos.x += 0.3 * sin(Ritmo.batida() * PI)
	return pos


func jogar(dt: float) -> void:
	SECAO.pulsos()
	var pico := SECAO.pico_suave(self)
	camera_pos = OLHAR + (CAMERA - OLHAR) * (1.0 + 0.1 * pico)
	SECAO.lava(self, 0.6 + 0.4 * pico)
	if not _reta and _ultimas_16():
		_reta = true
		var ordem := vencedor()
		var onde := Vector3(PAINEL_X[int(ordem[0])], 0.8, Z_PAINEL) if not ordem.is_empty() else Vector3(0, 0.8, Z_PAINEL)
		SECAO.momento(self, "reta", -1, onde, 1.8, {"ordem": ordem, "objeto": "escudos_na_raia"})
	_ouro_vem()
	for l in presentes():
		var e: Dictionary = j[l]
		_mostrar(l)
		if acabou[l]:
			continue
		if not conectado(l):
			e.fora = true
			continue
		if bool(e.fora):
			e.fora = false
			e.mira = _centro(l)
			Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, 8)
			_proxima(l, Ritmo.batida() + 1.0)
		_mirar(l, e, dt)
		_atirar(l, e)
	_mostrar_ouro()


## O ouro: no pico, na batida 1 de cada 2 compassos; nas últimas 16
## batidas, de cada compasso. À vista 4 tempos antes.
func _ouro_vem() -> void:
	var b := Ritmo.batida()
	if _ouro_b >= 0.0 and b > _ouro_b + FOLGA_PERDIDA * Ritmo.bpm / 60.0:
		_ouro_b = -1.0
	if _ouro_b >= 0.0:
		return
	var passo := 8.0 if no_pico() else (4.0 if _ultimas_16() else 0.0)
	if passo == 0.0:
		return
	# a próxima batida 1 de compasso da série (4 + passo·m) depois de agora
	var prox := BATIDA_DA_PRIMEIRA_NOTA + passo * ceilf((b - BATIDA_DA_PRIMEIRA_NOTA) / passo + 0.0001)
	if prox - b <= 4.0:
		_ouro_b = prox
		_ouro_dono = -1
		var ordem := vencedor()
		_ouro_lider = int(ordem[0]) if not ordem.is_empty() and int(j[int(ordem[0])].derrubados) > 0 else -1


func _embacada(l: int) -> bool:
	var e: Dictionary = j[l]
	var b := Ritmo.batida()
	if b - float(e.embaca_b) < float(e.embaca_t):
		return true
	return l == _ouro_lider and _ouro_b >= 0.0 and b >= _ouro_b - 1.0 and b < _ouro_b


## A mira anda com o giro do controle (a taxa do próprio controle vezes dt:
## a integração do sensor, não o ritmo). O coice: 60 ms ignorando o giro
## abaixo de 0,3 rad/s.
func _mirar(l: int, e: Dictionary, dt: float) -> void:
	var m: Vector2 = e.mira
	var k := 0.5 if _embacada(l) else 1.0
	if Forja.capacidade(l, "giro"):
		var g := Forja.giro(l)
		if Ritmo.t_musica() - float(e.coice_t) < COICE_S:
			g.x = g.x if absf(g.x) >= COICE_GIRO else 0.0
			g.y = g.y if absf(g.y) >= COICE_GIRO else 0.0
		m.x -= g.y * SENSIBILIDADE * dt * k
		m.y += g.x * SENSIBILIDADE * dt * k
	else:
		m.x += Forja.eixo(l, Forja.RX) * ANALOGICO * dt * k
		m.y -= Forja.eixo(l, Forja.RY) * ANALOGICO * dt * k
	if Forja.apertou(l, Forja.L1):
		m = _centro(l)
	e.mira = Vector2(clampf(m.x, -MIRA_X, MIRA_X), clampf(m.y, MIRA_Y0, MIRA_Y1))


func _atirar(l: int, e: Dictionary) -> void:
	var r2 := Forja.eixo(l, Forja.R2)
	var disparou := float(e.r2_antes) < SOLTO and r2 >= DISPARA
	if r2 < SOLTO or disparou:
		e.r2_antes = r2
	var alvo := Ritmo.t_da_batida(float(e.b))
	var agora := Ritmo.t_musica()
	var aberta := agora >= alvo - 0.5 * 60.0 / Ritmo.bpm
	if not disparou:
		if agora > alvo + FOLGA_PERDIDA:
			nota_perdida(l, int(e.n))
		return
	var m: Vector2 = e.mira
	e.coice_t = agora
	Forja.sentir(l, "golpe_dir", 40)
	_disparo(l, m)
	if _levou_o_ouro(l, m, agora):
		return
	if not aberta:
		_ricochete(l, m)  # cedo demais: embaça, sem nota
		return
	var dist := m.distance_to(_pos_do_alvo(l, int(e.alvo)))
	anotar("entrada", l, {"o": "mira", "erro_m": snappedf(dist, 0.01), "n": int(e.n)})
	if dist <= RAIO:
		julgar_toque(l, alvo, int(e.n))
	else:
		_ricochete(l, m)
		nota_perdida(l, int(e.n))


## O ouro: o primeiro tiro a menos de 0,6 m, na janela, leva. O grito sai na
## colcheia seguinte.
func _levou_o_ouro(l: int, m: Vector2, agora: float) -> bool:
	if _ouro_b < 0.0 or _ouro_dono >= 0 or m.distance_to(OURO) > RAIO_OURO:
		return false
	var t := Ritmo.t_da_batida(_ouro_b)
	if agora < t - 0.5 * 60.0 / Ritmo.bpm or agora > t + FOLGA_PERDIDA:
		return false
	_ouro_dono = l
	anotar("entrada", l, {"o": "ouro", "t": snappedf(agora - t, 0.001)})
	var colcheia := ceilf(Ritmo.batida() * 2.0 + 0.001) / 2.0
	SECAO.agendar(Ritmo.t_da_batida(colcheia), _ouro_derrubado.bind(l))
	return true


## O grito: o golpe na mão de quem levou, o tremor, o tinido, e o escudo
## de ouro voa para o painel dele, onde fica pendurado até o fim.
func _ouro_derrubado(l: int) -> void:
	var e: Dictionary = j[l]
	ouro_t = Ritmo.t_musica()
	if not treinando:
		e.derrubados = int(e.derrubados) + VALE_OURO
		marcar(l, PONTOS_OURO)
	var onde := Vector3(OURO.x, OURO.y, Z_PAINEL)
	SECAO.momento(self, "escudo_de_ouro", l, onde - Vector3(0, 0.6, 0), 1.2, {"ouros": int(e.ouros) + 1})
	Forja.sentir(l, "golpe", 120)
	Forja.som_falante(l, "coleta", 0.7)
	Som.tocar("alvo", onde, 0.0, 0.75)
	tremer(Sala.TREMOR_GOLPE)
	var p := jogador(l)
	if p:
		SECAO.parar([p], 2)
	Efeitos.faiscas(self, onde, Tema.TUNGSTENIO, 30, 1.0)
	var k := int(e.ouros)
	e.ouros = k + 1
	var pendurado := Kit.cilindro(self, 0.15, 0.03, onde, Kit.material(Tema.TUNGSTENIO, 0.6))
	pendurado.rotation.x = PI * 0.5
	var ate := Vector3(PAINEL_X[l] - 0.7 + 0.35 * (k % 5), 0.8 - 0.3 * floorf(k / 5.0), Z_PAINEL - 0.05)
	var tw := pendurado.create_tween()
	tw.tween_property(pendurado, "position", ate, 0.4)
	tw.parallel().tween_property(pendurado, "rotation:z", TAU * 2.0, 0.4)


func _disparo(l: int, m: Vector2) -> void:
	var p := jogador(l)
	var de := p.global_position + Vector3(0.3, 1.3, -0.3) if p else Vector3(PAINEL_X[l], 1.3, 4.0)
	var ate := Vector3(m.x, m.y, Z_PAINEL + 0.1)
	var bala := Kit.caixa(self, Vector3(0.06, 0.06, 0.5), de, Kit.material(Tema.JOGADOR[l], 2.0))
	bala.look_at_from_position(de, ate, Vector3.UP)
	var tw := bala.create_tween()
	tw.tween_property(bala, "global_position", ate, 0.15)
	tw.tween_callback(bala.queue_free)
	Som.tocar("tiro", de, -6.0)
	if p:
		p.gesto("attack-melee-right", 0.3)


func _ricochete(l: int, m: Vector2) -> void:
	j[l].embaca_b = Ritmo.batida()
	j[l].embaca_t = SECAO.levantar(l, 1.0)
	var onde := Vector3(m.x, m.y, Z_PAINEL + 0.1)
	Efeitos.faiscas(self, onde, Tema.ETIQUETA_SOMBRA, 12, 0.5)
	Som.tocar("tique", onde, -6.0, 0.7)


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	var dobro := 2 if _ultimas_16() else 1
	marcar(l, int(PONTOS[julgamento]) * dobro)
	if not treinando:
		e.derrubados = int(e.derrubados) + dobro
	if julgamento != Ritmo.PERFEITO:
		Som.no_controle(l, "alvo", 0.6)
	var escudo: Node3D = e.escudos[int(e.alvo)]
	Som.tocar("alvo", escudo.global_position, -2.0)
	Efeitos.faiscas(self, escudo.global_position, Tema.JOGADOR[l], 20, 0.8)
	var tw := escudo.create_tween()
	tw.tween_property(escudo, "rotation:x", -PI * 0.5, 0.12)
	tw.tween_property(escudo, "rotation:x", 0.0, 0.3).set_delay(0.3)
	_proxima(l, float(e.b))


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	_proxima(l, float(j[l].b))


func _mostrar(l: int) -> void:
	var e: Dictionary = j[l]
	var m: Vector2 = e.mira
	var no_mira: Node3D = e.no_mira
	no_mira.position = Vector3(m.x, m.y, Z_PAINEL + 0.3)
	no_mira.visible = fase == "jogo" and not acabou[l]
	no_mira.scale = Vector3.ONE * (1.6 if _embacada(l) else 1.0)
	for i in POSICOES.size():
		(e.escudos[i] as Node3D).position.x = _pos_do_alvo(l, i).x
	var moldura: MeshInstance3D = e.moldura
	var falta := float(e.b) - Ritmo.batida()
	var previa := 1.0 + SECAO.pista_s(l) * Ritmo.bpm / 60.0
	moldura.visible = fase == "jogo" and int(e.alvo) >= 0 and falta <= previa and falta > -1.0
	if moldura.visible:
		var pos := _pos_do_alvo(l, int(e.alvo))
		moldura.position = Vector3(pos.x, pos.y, Z_PAINEL - 0.08)
		(moldura.material_override as StandardMaterial3D).emission_energy_multiplier = 0.5 if falta > 0.0 else 2.0


func _mostrar_ouro() -> void:
	_ouro.visible = fase == "jogo" and _ouro_b >= 0.0 and _ouro_dono < 0
	if _ouro.visible:
		var falta := _ouro_b - Ritmo.batida()
		var energia := 0.3 if falta > 1.0 else (0.8 if falta > 0.0 else 1.6)
		(_ouro.material_override as StandardMaterial3D).emission_energy_multiplier = energia


## Quem está embaçado está fora da rodada (arte/09).
func fora_da_rodada(l: int) -> bool:
	return j.has(l) and Ritmo.batida() - float(j[l].embaca_b) < float(j[l].embaca_t)


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(_antes)
	return lista


func _antes(a: int, b: int) -> bool:
	if int(j[a].derrubados) != int(j[b].derrubados):
		return int(j[a].derrubados) > int(j[b].derrubados)
	if int(pontos[a]) != int(pontos[b]):
		return int(pontos[a]) > int(pontos[b])
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		return "Alvos: %d" % int(j[lugar].derrubados)
	return super(lugar)
```

### O robô

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var e: Dictionary = j[l]
	var gx := 0.0
	var gy := 0.0
	var gz := -2.5 * Forja.postura(l).x  # sem rolar
	var alvo_b := -1.0
	var alvo := Vector2.ZERO
	# o ouro, quando a batida dele vem antes da nota própria (de 1,5 tempo antes até ela)
	if _ouro_b >= 0.0 and _ouro_dono < 0 and Ritmo.batida() >= _ouro_b - 1.5 and _ouro_b <= float(e.b):
		alvo_b = _ouro_b
		alvo = OURO
	elif float(e.b) >= 0.0 and Ritmo.batida() >= float(e.b) - 1.0:
		alvo_b = float(e.b)
		alvo = _pos_do_alvo(l, int(e.alvo))
	if alvo_b >= 0.0:
		var chave := alvo_b + 1000.0 * int(alvo == OURO)
		if float(e.robo_ouro) != chave:
			# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado;
			# no ouro, quem acerta atira de 0 a 60 ms depois (sem isso o P1 ganha todo empate)
			e.robo_ouro = chave
			var folga := rng.randf_range(0.0, 0.06) if alvo == OURO else 0.0
			e.robo_mira = folga if Forja.robo_acerta() else 0.20
		var m: Vector2 = e.mira
		gy = clampf(-6.0 * (alvo.x - m.x) / SENSIBILIDADE, -4.5, 4.5)
		gx = clampf(6.0 * (alvo.y - m.y) / SENSIBILIDADE, -4.5, 4.5)
		var quando := Ritmo.t_da_batida(alvo_b) + float(e.robo_mira)
		var agora := Ritmo.t_musica()
		if agora >= quando - 0.01 and agora <= quando + 0.08:
			Forja.robo_eixo(l, Forja.R2, 1.0, 0.06)
	Forja.robo_girar(l, Vector3(gx, gy, gz), 0.06)
```

O robô sai da nota própria pelo ouro quando o ouro vem antes: a nota
própria daquele instante se perde pelo tempo (é a escolha que a sala faz).

### O registro

- O kit: `nota` (o instante em que o alvo acende) e `toque` (o disparo).
- `entrada`: `sensores` no começo; em cada disparo na janela, `o` `mira`,
  `erro_m` (a distância da mira ao escudo, m; pela sensibilidade de 3,0 m
  por rad, o ângulo pedido contra o feito) e `n`; `o` `ouro` (com o `t`, o
  atraso) em quem leva o ouro. Um giroscópio com a taxa errada (a mira que
  passa do alvo) ou com um eixo invertido (a mira que foge) aparece aqui.
- `momento`: `escudo_de_ouro` (`lugar` quem levou, `ouros`) e `reta`
  (`ordem`, `objeto` `escudos_na_raia`).

### Armadilhas

- **O `dt` na mira está certo:** é a integração da taxa do próprio controle
  (rad/s). O ritmo (o alvo, a janela, o ouro) é pela batida.
- **O R2 com a arma** manda o Weapon; o L2 é do item (nunca `gatilhos_off`).
  O fim do kit solta os dois.
- **O disparo é o cruzamento** de 75 % vindo de menos de 50 %; segurar o R2
  no fundo não dispara de novo.
- **O coice não anda a mira:** o `sentir golpe_dir` sacode o controle, e o
  giroscópio lê o tremor; os 60 ms ignorando abaixo de 0,3 rad/s seguram o
  retículo.
- **O ouro antes da nota:** o tiro no ouro não julga a nota própria; ela se
  perde pelo tempo, se a janela dela passar.
- **O ouro espera a colcheia:** o dono é marcado no tiro (os outros
  ricocheteiam já), e o grito, a linha `momento` e o `sentir golpe` saem
  juntos na colcheia seguinte (`_ouro_derrubado`, pela fila do `secao.gd`).
- **`look_at_from_position`** com o alvo quase na vertical avisa no console;
  o disparo sai de 1,3 m e vai a 1,2 a 4,1 m, a 10 m de distância: nunca
  vertical.

## A cena

### O secao.gd

O da [J1](J1-a-viga.md#o-secaogd), sem mudança: `SECAO.montar` (a caverna
cobalto), `lava`, `pico_suave`, `agendar`, `pulsos`, `parar`, `momento`,
`gancho`, `levantar`, `pista_s`, `peca_no_tamanho`.

### Por lugar

| o quê | peça | onde (m) | cor |
| --- | --- | --- | --- |
| o painel | `Kit.caixa(1,9; 1,8; 0,1)` | `(PAINEL_X[l]; 1,9; −5,75)` | `GRAFITE` |
| os escudos | `shield-round` em 0,55 × 0,55 × 0,1 (`SECAO.peca_no_tamanho`; sem a peça, a caixa) | `(PAINEL_X[l] + x; y; −5,6)` | o da peça; a caixa de reserva `OXIDO_BRILHO` |
| a moldura acesa | `Kit.caixa(0,62; 0,62; 0,04)` atrás do escudo da vez | `z = −5,68` | `JOGADOR[l]`: 0,5 na prévia, 2,0 na batida |
| a mira | quatro traços `Kit.caixa(0,2; 0,04; 0,02)` / `(0,04; 0,2; 0,02)` e o ponto `(0,06; 0,06; 0,02)`, chapados por cima | `(m.x; m.y; −5,3)`; ×1,6 embaçada | `JOGADOR[l]` |
| o atirador | o boneco, de costas, `preso`, mãos livres | `(PAINEL_X[l]; 0,05; 4,2)` | o da montagem |
| o disparo | `Kit.caixa(0,06; 0,06; 0,5)`, do boneco à mira em 0,15 s | — | `JOGADOR[l]` a 2,0 |
| o painel do ouro | `Kit.caixa(1,4; 1,4; 0,1)` | `(0; 3,6; −5,75)` | `GRAFITE` |
| o escudo de ouro | `Kit.cilindro` r 0,6 × 0,08, de frente | `(0; 3,6; −5,6)` | `TUNGSTENIO`: 0,3 à vista, 0,8 na prévia, 1,6 aceso |
| os ouros pendurados | `Kit.cilindro` r 0,15 × 0,03, voam em 0,4 s girando duas voltas | sob o painel do dono, `(PAINEL_X[l] − 0,7 + 0,35·(k % 5); 0,8 − 0,3·⌊k/5⌋; −5,65)` | `TUNGSTENIO` a 0,6 |

### A câmera

`"camera": "fixa"`, o plano de tiro: 35 mm, 11° de cima, sem corte.
`camera_pos = (0; 5,0; 13,5)`, `camera_olhar = (0; 1,8; −3,0)` (19,2 m até
o painel do ouro: os quatro painéis, o ouro e os quatro atiradores no
quadro; o escudo de ouro de 1,2 m mede 0,086 da altura da tela). O fov é o
global de hoje (40). **No pico**, recua 10 % em 2 batidas e volta em 2
(`SECAO.pico_suave`). O tremor: `tremer(Sala.TREMOR_GOLPE)` no ouro.

### A luz e o brilho

A luz é a da seção (`SECAO.montar`). O que brilha:

| o quê | energia | dono |
| --- | --- | --- |
| a moldura do alvo | 0,5 na prévia, 2,0 na batida | o lugar |
| o disparo | 2,0 | o lugar |
| as faíscas do acerto (20) | as de `Efeitos.faiscas` | o lugar |
| as faíscas do ricochete (12) | as de `Efeitos.faiscas` | o mundo, `ETIQUETA_SOMBRA` |
| o escudo de ouro | 0,3 → 0,8 → 1,6 | ninguém até o tiro, `TUNGSTENIO` |
| as faíscas do ouro (30) e os pendurados (0,6) | as de `Efeitos.faiscas` e 0,6 | quem levou, `TUNGSTENIO` |
| a lava, as brasas, o néon | os da J1 | o mundo |

O ouro é o `TUNGSTENIO` (não há token de ouro).

## O som

| evento | id do mapa | onde | volume |
| --- | --- | --- | --- |
| a faixa | `mus_s02_j10` (115 BPM); até a H05, a sintetizada a 96 | TV | o da faixa |
| o disparo | `Som.tocar("tiro")` = `tiro_0..4` | TV, no atirador | −6 dB |
| o escudo derrubado | `Som.tocar("alvo")` = `alvo_0..4` | TV, no escudo | −2 dB |
| o ricochete | `Som.tocar("tique")` = `tique_0..2` (ou `sint_tique`), tom 0,7 | TV, na parede | −6 dB |
| o ouro derrubado | `alvo_0..4`, tom 0,75 | TV, no painel do ouro | 0 dB |
| BOM e ÓTIMO | `alvo_0..4` (`Som.no_controle(l, "alvo", 0.6)`) | alto-falante do dono | 0,6 |
| o tinido do ouro | `mod_coleta` (`som_falante(l, "coleta", 0.7)`) | alto-falante de quem levou | 0,7 |
| PERFEITO e ERRO | o kit | alto-falante do dono | o do kit |
| a textura do acerto | `mod_material_metal` (o kit, `"material": "metal"`) | atuadores do dono | o do kit |

O mapa não tem J5 no `mod_coleta`.

## O controle

| recurso | o evento | para quem | o quê | a prova sem o controle na mão |
| --- | --- | --- | --- | --- |
| giroscópio | sempre | o dono | a guinada e a arfagem levam a mira, 3,0 m por rad | o robô (`robo_girar`) e a linha `entrada` com o `erro_m` |
| gatilho R2 | do começo ao fim | o dono | `GATILHO_ARMA` (2, 6, 8): a parede e o clique | `percepcao(l).gatilho_dir == 0x25` |
| vibração | cada tiro | o dono | o coice: `sentir(l, "golpe_dir", 40)` | `percepcao(l).fraco` ≥ 0,95 de +0 a +0,03 s do `coice_t` |
| vibração | o ouro | quem levou | `sentir(l, "golpe", 120)`: forte 1,0 e fraco 0,6 | `percepcao(l).forte` ≥ 0,95 de +0 a +0,05 s do `ouro_t` |
| vibração | o acerto e o erro | o dono | o kit | o kit (H08) |
| botão L1 | quando aperta | o dono | a mira ao meio do painel | aos 10 s a prova põe a mira do P1 em (3,5; 4,0), `Forja.robo_apertar(0, Forja.L1)`, e a mira está a menos de 0,7 m de (−3,0; 1,9) em até 3 quadros |
| alto-falante | o acerto e o ouro | o dono | `alvo` 0,6; `coleta` 0,7 | `som_virtual(l).falante` |
| barra de luz | o julgamento | o dono | o kit | o kit |
| háptica | o acerto | o dono | `metal` (o kit) | o kit |
| microfone | — | — | Não se aplica: a seção é do corpo | — |

## O cavaleiro

- **A peça aparece inteira e na cor dela.** O minigame não tinge o boneco:
  a cabeça (humana, orc, autômato, golem ou raposa), o superior e o
  inferior vêm da montagem com os tons próprios (G13). A cor do lugar fica
  na mira, na moldura e no disparo. As animações (`idle`,
  `attack-melee-right`) servem às cinco raças.
- **As mãos livres** (`maos_livres(p)`): o L2 é do item (G03).
- **Os stats** (`SECAO.gancho`; sem a classe `Cavaleiro`, o neutro). Nenhum
  mexe na janela, nos pontos, no raio do alvo (0,35 m) nem no do ouro
  (0,6 m).

| gancho | o que muda aqui | stat 1 | stat 5 |
| --- | --- | --- | --- |
| `levantar` | o tempo embaçado do ricochete (1 tempo) | 1,25 tempo | 0,75 tempo |
| `pista` | a prévia da moldura chega antes | −40 ms | +40 ms |

A coluna `queda_tempos` do minigames.csv propõe 2 tempos; esta ficha usa 1
tempo embaçado (no tiroteio o alvo seguinte chega 1 tempo depois: 2 tempos
de mira lenta perderiam dois alvos por ricochete).

## As reações

- **`car_em_chamas`** e **`car_por_um_fio`**: os do kit. O `car_acorde` não
  se aplica.
- **Os adesivos `rea_*`:** quem está embaçado (`fora_da_rodada(l)`).
- Nenhum carimbo próprio deste minigame.

## A diversão

**O grito: o escudo de ouro** (`escudo_de_ouro`), degrau golpe. No pico, o
disco de ouro aparece fosco no painel do meio 4 tempos antes; os quatro
giram a luneta para o mesmo alvo; o primeiro tiro no tempo leva 3: o golpe
na mão, o tremor (`TREMOR_GOLPE`), o tinido no alto-falante, e o escudo voa
girando para o painel do dono. Os outros ricocheteiam e embaçam.

- **O rastro:** o ouro pendurado sob o painel do dono até o fim.
- **Confere pelo robô (o da prova: `--robo`, o `bom` nos quatro, semente
  7):** pelo menos 3 linhas `momento`
  `escudo_de_ouro` entre 25 e 50 s; uma linha `momento` `reta`; nos
  `momento` com `x_tela` ≥ 0, 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,08.
- **Confere pela foto:** `mira_50s` (aos 50 s de jogo) com pelo menos 1
  ouro pendurado sob um painel.

**A curva:** a tabela de **Como se joga**. Pelo robô: as notas por segundo
do 2.º terço ≥ 1,5 × as do 1.º (`_notas_por_terco`).

**Ensina sem falar:** o alvo acende fraco 1 tempo antes e cheio na batida
(a prévia é o aviso); o retículo na cor do dono já se mexe com o controle
nas 4 batidas antes da primeira nota.

**Quem está perdendo:** o ouro vale 3, e o líder tem a mira embaçada no
tempo antes do ouro. Pelo robô: em pelo menos 1 linha `momento`
`escudo_de_ouro`, o `lugar` não é o primeiro da linha `reta`.

**O que se cortou:** o ícone do L1 (o botão fica).

## Pronto quando

A mira joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos
três temperamentos; o cabo que cai e volta recebe a arma de novo; o ouro
sai no tempo e voa para o painel de quem levou; o fim tem sempre vencedor;
`_prova_da_mira()` passa; e a foto `mira_50s` mostra um ouro pendurado.

## Provas

**`godot/testes/prova_do_jogo.gd`**, no `match` de `_prova_da_ficha`:
`"S02_J10": await _prova_da_mira()`.

```gdscript
## Mira Óptica (S02_J10): o R2 com a arma, o coice a cada tiro, o golpe do
## ouro no tempo, o L1 e a régua da diversão.
func _prova_da_mira() -> void:
	var visto := {"arma": {}, "coice": {}, "golpe": {}, "l1": 0, "l1_q": 0}
	var olhar := func(mg: Minigame) -> void:
		var agora := Ritmo.t_musica()
		# o L1: aos 10 s, a mira do P1 vai para o canto e o L1 a traz ao meio em até 3 quadros
		if int(visto.l1) == 0 and agora >= 10.0:
			mg.j[0].mira = Vector2(3.5, 4.0)
			Forja.robo_apertar(0, Forja.L1)
			visto.l1 = 1
		elif int(visto.l1) == 1:
			visto.l1_q = int(visto.l1_q) + 1
			if (mg.j[0].mira as Vector2).distance_to(mg._centro(0)) < 0.7:
				visto.l1 = 2 if int(visto.l1_q) <= 3 else 3
		for l in mg.presentes():
			var e: Dictionary = mg.j[l]
			var per := Forja.percepcao(l)
			if int(per.get("gatilho_dir", 0)) == 0x25:
				visto.arma[l] = true
			if float(e.coice_t) >= 0.0 and agora - float(e.coice_t) <= 0.03 and float(per.get("fraco", 0.0)) >= 0.95:
				visto.coice[l] = true
			if mg.ouro_t >= 0.0 and agora - mg.ouro_t <= 0.05 and float(per.get("forte", 0.0)) >= 0.95:
				visto.golpe[l] = true
	var mg := await _joga_o_minigame("S02_J10", 115.0, olhar)
	if mg == null:
		return
	for l in 4:
		_esperar(visto.arma.has(l), "S02_J10 P%d: o R2 com a arma (0x25)" % [l + 1])
		_esperar(visto.coice.has(l), "S02_J10 P%d: o coice na mão" % [l + 1])
		_esperar(int(mg.j[l].derrubados) >= 1, "S02_J10 P%d: derrubou um escudo %s" % [l + 1, mg.contagem[l]])
	_esperar(int(visto.l1) == 2, "S02_J10: o L1 traz a mira ao meio do painel do P1 em até 3 quadros (%d)" % int(visto.l1_q))
	var ouros := []
	var reta := []
	for ev in _linhas_do_minigame("S02_J10"):
		if ev.get("tipo", "") == "momento" and ev.get("nome", "") == "escudo_de_ouro":
			ouros.append(ev)
			_esperar(visto.golpe.has(int(ev.get("lugar", -1))), "S02_J10 P%d: o golpe do ouro na mão" % [int(ev.get("lugar", 0)) + 1])
			if float(ev.get("x_tela", -1.0)) >= 0.0:
				_esperar(float(ev.x_tela) >= 0.2 and float(ev.x_tela) <= 0.8 and float(ev.altura_tela) >= 0.08,
					"S02_J10: o ouro no meio da tela (%s)" % [ev])
		if ev.get("tipo", "") == "momento" and ev.get("nome", "") == "reta":
			reta.append(ev)
	var no_pico := ouros.filter(func(ev): return float(ev.t_musica) >= 25.0 and float(ev.t_musica) <= 50.0)
	_esperar(no_pico.size() >= 3, "S02_J10: 3 ou mais ouros entre 25 e 50 s (%d)" % no_pico.size())
	_esperar(reta.size() == 1, "S02_J10: a linha momento reta (%d)" % reta.size())
	if reta.size() == 1:
		var lider := int(reta[0].ordem[0])
		_esperar(ouros.any(func(ev): return int(ev.lugar) != lider), "S02_J10: o ouro não é só do líder")
	_esperar(mg.vencedor().size() == 4, "S02_J10: a colocação tem os quatro")
	var terco := _notas_por_terco("S02_J10", mg.duracao)
	_esperar(terco[1] >= 1.5 * terco[0], "S02_J10: o tiroteio pede 1,5 × as notas do 1.º terço (%s)" % [terco])
```

**`godot/testes/captura_jogo.gd`**, no dicionário `momentos`:

```gdscript
		"S02_J10": [
			["mira_alvo", fase.call("jogo", 6.0)],
			["mira_ouro", na_sala.call(func(sala) -> bool:
				return sala.ouro_t >= 0.0 and Ritmo.t_musica() - sala.ouro_t <= 0.2)],
			["mira_50s", fase.call("jogo", 50.0)],
		],
```

**Os comandos:** `SALA=S02_J10 bash tests/prova_do_jogo.sh`;
`bash tests/prova_visual.sh`; e as fotos da ficha, o `roteiro` do
`tests/telas.sh` com a sala dela (cada foto num PNG em `SAIDA`:
`S02_J10_aviso`, os momentos acima e `S02_J10_fim`):

```bash
source scripts/engine.sh
SAIDA=/tmp/fotos-S02_J10 ROTEIRO=salas SALAS=S02_J10 RAPIDO=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
  "$FORJA_GODOT" --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --path godot \
  --resolution 1920x1080 res://testes/captura_jogo.tscn -- --simular=4 --semente=7 --robo \
  --relatorios="$(mktemp -d)"
```

**As pranchas que o jogador do time olha:**

- `mira_ouro`: o disco de ouro voando, as quatro miras perto do painel do
  meio;
- `mira_50s`: pelo menos um ouro pendurado sob um painel;
- o boneco de cada lugar, de costas na `mira_alvo`: a cabeça, o superior e o inferior em tons
  diferentes, sem a cor do lugar no corpo.

**O André (local):** `./run-local.sh -- --sala=S02_J10`: girar o controle
leva a mira sem susto, o coice se sente sem tirar a mira, o L1 salva, a
parede e o clique do R2 se sentem, a prévia de um tempo dá para mirar, e o
ouro faz os quatro brigarem pelo meio.
