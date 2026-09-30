# K1 — O Molde

**Sprint:** K · **Slot:** S03_J11 · **Tamanho:** G · **Estimativa:** US$ 2,0 · **Depende de:** H04, H08, F09, F03, F05, H07, G05

## Por quê

Traçar é levar o dedo de ponto a ponto da letra, um trecho por tempo, e
carimbar com o clique no último; desmoldar é abrir e fechar dois dedos — o
touchpad inteiro (os cantos, os dois dedos, o clique) julgado no tempo, e os
vereditos da bancada de hoje saindo daqui.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [H04 — O kit do minigame](H04-o-kit-do-minigame.md)
- [A linha n.º 11 em 03](../03-os-45-minigames.md#s3--o-molde--touchpad)
- [O índice da seção](K-o-molde.md) (as convenções, o `secao.gd`)
- [As decisões comuns dos minigames — H08](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08) — o fim em tempo de música, a fila de notas do kit, a barra de luz do kit, `Forja.textura`

## O estado de hoje

`godot/scripts/salas/molde.gd` (510 linhas, `class_name SalaMolde`) ainda é
uma sala antiga (`Catalogo.SALAS_ANTIGAS["molde"]`): três passos em
sequência por jogador — traçar uma letra de 3 a 6 pontos, abrir e fechar com
dois dedos, três carimbos quando o metal brilha — por `dt`, sem música, com
`RAIAS` próprias (`±6,3`, `±2,1`). Ela sai: esta ficha cria
`godot/scripts/minigames/s03/o_molde.gd` e
`godot/scripts/minigames/s03/secao.gd`, e apaga `godot/scripts/salas/molde.gd`
e o `.uid` (`git rm`).

| hoje | depois |
| --- | --- |
| uma letra, depois abrir, depois carimbar — uma vez | **a peça**, em dois compassos: três pontos (um por tempo), o carimbo no quarto tempo, abrir no quinto, fechar no sétimo — e a peça seguinte |
| o carimbo quando o metal brilha | o carimbo na batida (o metal brilha nela) |
| pontos por rapidez | peças inteiras (sem erro) na estante |
| `RAIAS` próprias | as do kit (a bancada anda 0,3 m) |
| o ouro metálico (`molde.gd:420`), esferas, toros lisos | ouro fosco (`metallic` 0,15), discos e anéis de 8 lados (11) |
| `_robo` por `rng` | o robô pelo relógio da música |
| `med_tracou`, `med_pedir("dois_dedos")`, `med_pedir("clique")` | os mesmos, na peça |

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S03_J11",
	"titulo": "O Molde",
	"verbo": "Trace!",
	"genero": "tct",
	"icone": "touchpad",
	"entradas": [Forja.TOUCHPAD],
	"camera": "fixa",
	"faixa": "MUS_S03_J11",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "pedra",
	"microjogo": {"verbo": "Trace!", "segundos": 6.0},
	# o que a bancada mede (o veredito é das medidas do núcleo)
	"features": ["touchpad_dois_dedos", "touchpad_clique"],
	"botoes_medidos": [Forja.TOUCHPAD],
	"gesto": "interact-right",
}
```

## Como se joga

- **A faixa:** `MUS_S03_J11` — até a H05, a sintetizada da seção a 100 bpm
  (0,6 s por tempo); com a gerada, 122 bpm ("agudos contra graves, metódico").
- **Os quatro juntos:** aqui não há hoqueto — o molde é um coro: os quatro
  traçam no mesmo tempo, cada um com a sua nota (o kit), e a letra dos quatro
  soa como um acorde. (É a exceção da seção, como a Marcha n'A Centelha.)
- **A peça** (8 tempos, começando no primeiro tempo de um compasso `S`):

  | batida | o que o dedo faz |
  | --- | --- |
  | `S + 0` | **entra** no ponto 1 da letra (encostar nele, ou chegar deslizando) |
  | `S + 1` | chega ao ponto 2, pelo sulco |
  | `S + 2` | chega ao ponto 3 |
  | `S + 3` | **o clique** do touchpad: carimba (o metal brilha nesta batida) |
  | `S + 4` | dois dedos **abrem** (a distância passa de 0,45 da largura) |
  | `S + 6` | os dois **fecham** (a distância cai abaixo de 0,15): a peça sai do molde |

  O ponto conta com qualquer dedo a menos de 0,09 da largura dele. A
  primeira peça começa na batida 4.
- **As letras** (três pontos cada, sorteadas pela semente a cada peça; cada
  uma leva o dedo de um canto a outro do touchpad): Λ `x [0,08; 0,50; 0,92]`,
  `y [0,88; 0,12; 0,88]`; V `x [0,08; 0,50; 0,92]`, `y [0,12; 0,88; 0,12]`;
  Γ `x [0,12; 0,12; 0,88]`, `y [0,88; 0,12; 0,12]`; e o Γ espelhado
  `x [0,88; 0,88; 0,12]`, `y [0,88; 0,12; 0,12]`.
- **O julgamento, no cruzamento** (as convenções da seção). Nada até
  `FOLGA_PERDIDA` (o kit) depois → nota perdida.
- **A peça inteira** é a que teve as seis notas sem erro; com um erro, ela
  sai **torta**.
- **Os pontos por julgamento** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 20, 35, 50]`;
  a peça inteira +100.
- **A progressão:** `no_pico()` do kit (o terço do meio dos 90 s de música), decidida no começo de
  cada peça. De 0 a 1/3, a peça de 8 tempos. **O pico (1/3 a 2/3), a fornada:**
  a peça de 4 tempos — três pontos e o carimbo; o molde abre sozinho. De 2/3
  em diante, 8 tempos de novo. `Ritmo.simples[l]`: a peça de 12 tempos (uma
  nota a cada 2 tempos).
- **A primeira volta** é a primeira peça inteira (os três pontos, o clique,
  abrir e fechar), e cabe folgada nos 90 s. **O fim é do kit, em tempo de
  música** (H08): os 90 s da FICHA contam em `Ritmo.t_musica()`, não em
  tempo de jogo.

## O cenário

`godot/scripts/minigames/s03/secao.gd` (novo, o arquivo inteiro):

```gdscript
extends RefCounted
## A seção O Molde (S03): o que os cinco minigames têm em comum — a oficina
## (o cenário), a bancada com a placa na proporção do touchpad (o dedo aparece
## onde o jogo o vê), os dedos na placa, as peças facetadas e a textura sob o
## dedo. A barra de luz que pisca no julgamento é do kit (H08). Sem class_name:
## const SECAO := preload("res://scripts/minigames/s03/secao.gd").

const LARGURA := 2.4  ## a placa no mundo, em m (2:1, como o touchpad)
const ALTURA := 1.2
const ASPECTO := 2.0
const INCLINACAO := 32.0  ## graus: a borda de longe sobe, para a câmera ver a placa de frente

static var _textura_b := [-99.0, -99.0, -99.0, -99.0]


## A oficina: o chão e as paredes do kit, a poeira dourada, o neon roxo, as
## tochas, as mesas e as cadeiras do fundo.
static func montar(sala: SalaJogo) -> void:
	Kit.arena(sala, 5, 3)
	sala.atmosfera(Color("#f1c86a"), Tema.ROXO, false, 50)
	sala.luzes([Vector3(-9, 2.5, -4), Vector3(9, 2.5, -4), Vector3(0, 3.0, 4)])
	for x in [-9.0, 9.0]:
		Kit.peca(sala, "table", Vector3(x, 0, -6.0))
		Kit.peca(sala, "chair", Vector3(x + 1.2, 0, -5.2), PI)
	for x in [-5.0, 0.0, 5.0]:
		Kit.peca(sala, "banner", Vector3(x, 0, -7.0))
	Kit.peca(sala, "barrel", Vector3(-10.6, 0, 2.0))
	Kit.peca(sala, "barrel", Vector3(10.6, 0, 2.0), 0.7)


## Um ponto do touchpad (x e y de 0 a 1, y para baixo) na placa, a `altura` da face.
static func no_molde(x: float, y: float, altura := 0.12) -> Vector3:
	return Vector3((x - 0.5) * LARGURA, altura, (y - 0.5) * ALTURA)


## A distância entre dois toques, em larguras do touchpad (como o núcleo mede).
static func distancia(a: Vector2, b: Vector2) -> float:
	return Vector2((b.x - a.x) * ASPECTO, b.y - a.y).length() / ASPECTO


## Um disco de 8 lados (no lugar da esfera e do cilindro lisos).
static func disco8(pai: Node, raio: float, altura: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = raio
	c.bottom_radius = raio
	c.height = altura
	c.radial_segments = 8
	c.rings = 1
	mi.mesh = c
	mi.position = pos
	mi.material_override = mat
	pai.add_child(mi)
	return mi


## Um anel de 8 lados (no lugar do toro liso).
static func anel8(pai: Node, raio: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = raio * 0.84
	t.outer_radius = raio
	t.rings = 8
	t.ring_segments = 4
	mi.mesh = t
	mi.position = pos
	mi.material_override = mat
	pai.add_child(mi)
	return mi


## A bancada do lugar e a placa (o touchpad no mundo). Com o molde, as duas
## metades de pedra e o metal no fundo; sem, só a moldura de pedra.
static func bancada(sala: SalaJogo, l: int, com_molde := true) -> Dictionary:
	var cx: float = Minigame.RAIAS[l] + 0.45
	var cor := Forja.cor_do_lugar(l)
	Kit.caixa(sala, Vector3(2.8, 0.8, 1.7), Vector3(cx, 0.4, 0.3), Kit.material(Color("#4b4558"), 0.0, 0.9))
	Kit.caixa(sala, Vector3(2.9, 0.08, 1.8), Vector3(cx, 0.82, 0.3), Kit.material(Color("#6a6180"), 0.0, 0.8))
	var fogo := OmniLight3D.new()
	fogo.position = Vector3(cx, 2.4, 1.2)
	fogo.light_color = cor.lerp(Color("#ffb070"), 0.55)
	fogo.light_energy = 0.8
	fogo.omni_range = 4.5
	sala.add_child(fogo)
	var placa := Node3D.new()
	placa.position = Vector3(cx, 1.12, 0.3)
	placa.rotation.x = deg_to_rad(INCLINACAO)
	sala.add_child(placa)
	var metades: Array = []
	var metal := Kit.material(Color("#3a1a10"), 0.4, 0.55)
	var pedra := Kit.material(Color("#5d566d"), 0.0, 0.85)
	if com_molde:
		for lado in [-1.0, 1.0]:
			var metade := Node3D.new()
			placa.add_child(metade)
			Kit.caixa(metade, Vector3(LARGURA * 0.5 + 0.12, 0.16, ALTURA + 0.26), Vector3(lado * (LARGURA * 0.25 + 0.06), 0, 0), pedra)
			Kit.caixa(metade, Vector3(LARGURA * 0.5 - 0.02, 0.03, ALTURA), Vector3(lado * LARGURA * 0.25, 0.085, 0), metal)
			metades.append(metade)
	else:
		Kit.caixa(placa, Vector3(LARGURA + 0.24, 0.16, ALTURA + 0.26), Vector3.ZERO, pedra)
	var dedos: Array = []
	for d in 2:
		var cd := cor if d == 0 else cor.lerp(Color.WHITE, 0.45)
		var disco := disco8(placa, 0.08, 0.03, Vector3.ZERO, Kit.material(cd, 2.2))
		disco.visible = false
		dedos.append(disco)
	var ligacao := Kit.caixa(placa, Vector3(0.025, 0.01, 1.0), Vector3.ZERO, Kit.chapado(Color(Tema.FG, 0.6)))
	ligacao.visible = false
	var ouro := Kit.material(Color("#e8b44c"), 1.1, 0.5)
	ouro.metallic = 0.15  # fosco (11): o ouro é cor, não reflexo
	return {"placa": placa, "metades": metades, "metal": metal, "dedos": dedos, "ligacao": ligacao,
		"ouro": ouro, "placa_y": placa.position.y, "cx": cx}


## Os dois dedos do lugar na placa, e a ligação entre eles quando são dois.
static func mostrar_dedos(sala: SalaJogo, l: int, nos: Dictionary) -> void:
	var d := [Forja.dedo(l, 0), Forja.dedo(l, 1)]
	for k in 2:
		var disco: MeshInstance3D = nos.dedos[k]
		disco.visible = sala.fase == "jogo" and d[k].z > 0.5
		if disco.visible:
			disco.position = no_molde(d[k].x, d[k].y, 0.16)
	var lig: MeshInstance3D = nos.ligacao
	lig.visible = sala.fase == "jogo" and d[0].z > 0.5 and d[1].z > 0.5
	if lig.visible:
		var a := no_molde(d[0].x, d[0].y, 0.15)
		var b := no_molde(d[1].x, d[1].y, 0.15)
		lig.position = (a + b) * 0.5
		lig.rotation.y = atan2(b.x - a.x, b.z - a.z)
		lig.scale = Vector3(1, 1, maxf(0.01, a.distance_to(b)))


## A textura do material sob o dedo, só nos atuadores (`Forja.textura`, H08: a
## háptica, sem o alto-falante), no máximo a cada quarto de tempo. No rádio,
## nada: a pista vai pela nota e pela tela.
static func textura(l: int, material: String) -> void:
	var b := Ritmo.batida()
	if b - float(_textura_b[l]) < 0.25 or not Forja.som_tem(l, Forja.PAPEL_HAPTICA):
		return
	_textura_b[l] = b
	Forja.textura(l, material)
```

Por lugar, em `o_molde.gd`: `SECAO.bancada(self, l)`; na placa, os dois
sulcos da letra (`Kit.caixa(0.07, 0.02, comprimento)`, `#1c1622`), os três
pontos (`SECAO.disco8(placa, 0.07, 0.03, ...)`, `#1c1622`, e o ouro fosco
quando o dedo passa) com o número (`Label3D` "1", "2", "3", como hoje) e o
alvo da vez (`SECAO.anel8(placa, 0.17, ...)`, `Kit.chapado(Tema.AMARELO)`);
atrás da bancada, a estante (`wood-structure`, escala 1,2, em
`(cx, 0, −1.6)`) com as peças prontas (`Kit.caixa(0.35, 0.06, 0.18)` de ouro
fosco; as tortas giradas 25° e escurecidas). O ferreiro em
`(RAIAS[l] − 1.45, 0.05, 0.35)`, de perfil (`rotation.y = PI/2`), com o
martelo. Câmera: `camera_pos = Vector3(0, 8.6, 12.7)`,
`camera_olhar = Vector3(0, 0.8, -0.1)` (as de hoje).

## O repertório

| recurso | o que acontece, e quando |
| --- | --- |
| **touchpad (a feature)** | o traço, o clique, os dois dedos |
| vibração | o kit por nota; **o molde fecha**: `Forja.sentir(l, "golpe")` |
| barra de luz | o kit (`_reagir`, H08): branco no perfeito, a cor do lugar escurecida no erro |
| alto-falante do dono | perfeito: a nota (o kit); **o clique carimba**: `Som.no_controle(l, "carimbo", 0.6)` (no ótimo e no bom); os outros acertos: `Forja.som_falante(l, "clique", 0.4)`; erro: a nota quebrada (o kit) |
| háptica por material | a textura `pedra` sob o dedo enquanto ele traça (`SECAO.textura(l, "pedra")`, no cabo) e no acerto (o kit) |
| gatilho | livre (o R2 Off) |
| som na TV | a nota (o kit); `tique` subindo a cada ponto; `carimbo` no clique; `sopro` no abrir; `bigorna` no fechar; `sucesso` baixo na peça inteira |

## A falha

O metal escorre e a peça sai torta: faíscas `Tema.LARANJA` caindo da borda
de perto da placa (`Efeitos.faiscas(self, placa.to_global(SECAO.no_molde(0.5, 1.0, 0.1)), Tema.LARANJA, 24, 0.6)`),
o metal esfria (escurece) até o fim da peça, e ela vai para a estante
girada e escura. O ferreiro faz `emote-no`. A peça seguinte começa no tempo
de sempre.

## O fim e o vencedor

O kit fecha aos 90 s de música (`"fim": "tempo"`, H08). `vencedor()`: mais
peças inteiras; empate pelos pontos, depois pelo lugar.

## Com menos de quatro

Nada muda. **O controle que cai:** a peça dele para (sem erro); ao voltar,
uma peça nova começa no próximo compasso inteiro. **Sem touchpad:** o lugar
acaba no `iniciar_jogo()` (as convenções da seção) e o veredito da bancada
diz "não medido", como hoje.

## O robô

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var e: Dictionary = j[l]
	if e.roteiro.is_empty():
		return
	if int(e.robo_n) != int(e.n):
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado
		e.robo_n = int(e.n)
		e.robo_mira = 0.0 if Forja.robo_acerta() else 0.20
		e.robo_feito = false
	var passo: Array = e.roteiro[int(e.passo)]
	var quando := Ritmo.t_da_batida(float(e.s) + float(passo[1])) + float(e.robo_mira)
	var agora := Ritmo.t_musica()
	var letra: Dictionary = LETRAS[int(e.letra)]
	match str(passo[0]):
		"ponto":
			var i := int(e.passo)
			var ate := Vector2(letra.x[i], letra.y[i])
			if i == 0:
				if agora >= quando:  # encosta no primeiro ponto na nota
					Forja.robo_tocar(l, 0, ate.x, ate.y, 0.06)
				return
			# desliza pelo sulco nos 250 ms antes da nota, e chega nela
			var de := Vector2(letra.x[i - 1], letra.y[i - 1])
			var pos := de.lerp(ate, clampf((agora - (quando - 0.25)) / 0.25, 0.0, 1.0))
			Forja.robo_tocar(l, 0, pos.x, pos.y, 0.06)
		"carimbo":
			if not bool(e.robo_feito) and agora >= quando:
				Forja.robo_apertar(l, Forja.TOUCHPAD, 0.05)
				e.robo_feito = true
		"abre":
			if agora >= quando - 0.2:
				var s := lerpf(0.05, 0.30, clampf((agora - (quando - 0.2)) / 0.27, 0.0, 1.0))
				Forja.robo_tocar(l, 0, 0.5 - s, 0.5, 0.06)
				Forja.robo_tocar(l, 1, 0.5 + s, 0.5, 0.06)
		"fecha":
			var s2 := 0.30
			if agora >= quando - 0.2:
				s2 = lerpf(0.30, 0.03, clampf((agora - (quando - 0.2)) / 0.27, 0.0, 1.0))
			Forja.robo_tocar(l, 0, 0.5 - s2, 0.5, 0.06)
			Forja.robo_tocar(l, 1, 0.5 + s2, 0.5, 0.06)
```

(Entre o terceiro ponto e o carimbo, e entre o carimbo e o abrir, o robô não
toca: os dedos sobem sozinhos.)

## Os ganchos

`godot/scripts/minigames/s03/o_molde.gd`:

```gdscript
extends Minigame
## O Molde (S03_J11), o primeiro d'O Molde. O touchpad é a placa do molde na
## bancada. A peça, em dois compassos: o dedo passa pelos três pontos da letra
## (um por tempo), o clique carimba no quarto tempo, dois dedos abrem no quinto
## e fecham no sétimo — a peça sai do molde. Os quatro juntos, como um coro.
## No meio, a fornada: a peça de um compasso, sem abrir.
##
## A falha: o metal escorre e a peça sai torta.
## O vencedor: mais peças inteiras.
## O alto-falante do dono: o carimbo no clique, o clique nos outros acertos, a nota no perfeito.
## O registro mede: quantos dedos chegaram juntos, que pedaço do touchpad os
## toques cobriram, a abertura entre os dedos e se o clique chegou (as medidas
## do núcleo: os vereditos da bancada); a posição e a distância de cada toque
## (a linha `entrada`) e o tempo (o kit).
## O robô: desliza pelo sulco e chega no ponto na nota, clica na nota, abre e
## fecha os dois dedos na nota (ou 200 ms atrasado).
## Com menos de quatro: nada muda.
## A régua: "Trace!" e o touchpad bastam; sem a tela, não (a letra é visual);
## nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s03/secao.gd")

# (a FICHA vem aqui)

const LETRAS := [
	{"x": [0.08, 0.50, 0.92], "y": [0.88, 0.12, 0.88]},
	{"x": [0.08, 0.50, 0.92], "y": [0.12, 0.88, 0.12]},
	{"x": [0.12, 0.12, 0.88], "y": [0.88, 0.12, 0.12]},
	{"x": [0.88, 0.88, 0.12], "y": [0.88, 0.12, 0.12]},
]
## A peça: [o que a mão faz, a batida a partir do começo dela], e quantos tempos ela dura.
const PECA := [["ponto", 0.0], ["ponto", 1.0], ["ponto", 2.0], ["carimbo", 3.0], ["abre", 4.0], ["fecha", 6.0]]
const PECA_PICO := [["ponto", 0.0], ["ponto", 1.0], ["ponto", 2.0], ["carimbo", 3.0]]
const PECA_SIMPLES := [["ponto", 0.0], ["ponto", 2.0], ["ponto", 4.0], ["carimbo", 6.0], ["abre", 8.0], ["fecha", 10.0]]
const RAIO_PONTO := 0.09
const ABERTO := 0.45
const FECHADO := 0.15
const PONTOS := [0, 20, 35, 50]
const INTEIRA := 100

var j := {}
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]


func montar() -> void:
	camera_pos = Vector3(0, 8.6, 12.7)
	camera_olhar = Vector3(0, 0.8, -0.1)
	SECAO.montar(self)
	var escuro := Kit.material(Color("#1c1622"), 0.0, 0.9)
	for p in jogadores:
		var l: int = p.lugar
		var nos := SECAO.bancada(self, l)
		var placa: Node3D = nos.placa
		var sulcos: Array = []
		for k in 2:
			sulcos.append(Kit.caixa(placa, Vector3(0.07, 0.02, 1.0), Vector3.ZERO, escuro))
		var pontos_nos: Array = []
		for k in 3:
			var disco := SECAO.disco8(placa, 0.07, 0.03, Vector3.ZERO, escuro)
			var rotulo := Label3D.new()
			rotulo.text = str(k + 1)
			rotulo.font = Tema.fonte(700)
			rotulo.font_size = 56
			rotulo.pixel_size = 0.004
			rotulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			rotulo.outline_size = 12
			rotulo.outline_modulate = Color(Tema.CASA, 0.9)
			rotulo.modulate = Tema.SUAVE
			placa.add_child(rotulo)
			pontos_nos.append({"disco": disco, "rotulo": rotulo})
		nos["sulcos"] = sulcos
		nos["pontos"] = pontos_nos
		nos["alvo"] = SECAO.anel8(placa, 0.17, Vector3.ZERO, Kit.chapado(Tema.AMARELO))
		nos["escuro"] = escuro
		Kit.peca(self, "wood-structure", Vector3(float(nos.cx), 0, -1.6), 0.0, 1.2)
		p.position = Vector3(RAIAS[l] - 1.45, 0.05, 0.35)
		p.rotation.y = PI * 0.5
		martelo_na_mao(p)
		j[l] = {"n": 0, "s": -1.0, "tam": 8.0, "roteiro": [], "passo": 0, "letra": 0, "feitos": 0, "torta": false,
			"aberto": false, "inteiras": 0, "tortas": 0, "volta": 0, "antes": false, "aberta": false,
			"fora": false, "nos": nos, "robo_n": -1, "robo_mira": 0.0, "robo_feito": false}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


func iniciar_jogo() -> void:
	for l in presentes():
		if not Forja.capacidade(l, "toque"):
			anotar("entrada", l, {"o": "sensores", "toque": false})
			acabou[l] = true
			continue
		_nova_peca(l, BATIDA_DA_PRIMEIRA_NOTA)


## Uma peça nova do lugar começando na batida `s` (o primeiro tempo de um compasso).
func _nova_peca(l: int, s: float) -> void:
	var e: Dictionary = j[l]
	e.s = s
	if Ritmo.simples[l]:
		e.roteiro = PECA_SIMPLES
		e.tam = 12.0
	elif no_pico():
		e.roteiro = PECA_PICO
		e.tam = 4.0
	else:
		e.roteiro = PECA
		e.tam = 8.0
	e.passo = 0
	e.letra = rng.randi_range(0, LETRAS.size() - 1)
	e.feitos = 0
	e.torta = false
	e.aberto = false
	_desenhar_a_letra(l)
	_armar(l)


## A nota do passo da vez: no registro, e o pedido às medidas do núcleo.
func _armar(l: int) -> void:
	var e: Dictionary = j[l]
	var passo: Array = e.roteiro[int(e.passo)]
	e.aberta = false
	e.antes = false
	match str(passo[0]):
		"carimbo":
			Forja.med_pedir(l, "clique")
		"abre":
			Forja.med_pedir(l, "dois_dedos")
	nova_nota(l, int(e.n), Ritmo.t_da_batida(float(e.s) + float(passo[1])))


func jogar(_dt: float) -> void:
	var agora := Ritmo.t_musica()
	for l in presentes():
		var e: Dictionary = j[l]
		SECAO.mostrar_dedos(self, l, e.nos)
		_mostrar(l)
		if acabou[l] or e.roteiro.is_empty():
			continue
		if not conectado(l):
			e.fora = true
			continue
		if bool(e.fora):
			e.fora = false
			_nova_peca(l, 4.0 * ceilf(Ritmo.batida() / 4.0 + 0.01))
		_nota(l, e, agora)


func _dedos(l: int) -> Array:
	return [Forja.dedo(l, 0), Forja.dedo(l, 1)]


func _condicao(l: int, e: Dictionary, o: String) -> bool:
	var d := _dedos(l)
	var dois: bool = d[0].z > 0.5 and d[1].z > 0.5
	match o:
		"ponto":
			var letra: Dictionary = LETRAS[int(e.letra)]
			var alvo := Vector2(letra.x[int(e.passo)], letra.y[int(e.passo)])
			for k in 2:
				if d[k].z > 0.5 and SECAO.distancia(Vector2(d[k].x, d[k].y), alvo) < RAIO_PONTO:
					return true
			return false
		"carimbo":
			return Forja.apertou(l, Forja.TOUCHPAD)
		"abre":
			return dois and SECAO.distancia(Vector2(d[0].x, d[0].y), Vector2(d[1].x, d[1].y)) >= ABERTO
		"fecha":
			return dois and SECAO.distancia(Vector2(d[0].x, d[0].y), Vector2(d[1].x, d[1].y)) <= FECHADO
	return false


func _nota(l: int, e: Dictionary, agora: float) -> void:
	var passo: Array = e.roteiro[int(e.passo)]
	var o := str(passo[0])
	var alvo := Ritmo.t_da_batida(float(e.s) + float(passo[1]))
	var d := _dedos(l)
	if o == "ponto" and (d[0].z > 0.5 or d[1].z > 0.5):
		SECAO.textura(l, "pedra")
	var sim := _condicao(l, e, o)
	if agora < alvo - 0.5 * 60.0 / Ritmo.bpm:
		e.antes = sim
		return
	var cruzou := sim and (not bool(e.antes) or not bool(e.aberta))
	e.aberta = true
	e.antes = sim
	if cruzou:
		anotar("entrada", l, {"o": "touchpad", "passo": o, "d0": [snappedf(d[0].x, 0.01), snappedf(d[0].y, 0.01)],
			"d1": [snappedf(d[1].x, 0.01), snappedf(d[1].y, 0.01)], "dedos": int(d[0].z > 0.5) + int(d[1].z > 0.5), "n": int(e.n)})
		julgar_toque(l, alvo, int(e.n))
	elif agora > alvo + FOLGA_PERDIDA:
		nota_perdida(l, int(e.n))


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	var placa: Node3D = nos.placa
	marcar(l, PONTOS[julgamento])
	var o := str(e.roteiro[int(e.passo)][0])
	var p := jogador(l)
	match o:
		"ponto":
			var letra: Dictionary = LETRAS[int(e.letra)]
			var onde := placa.to_global(SECAO.no_molde(letra.x[int(e.passo)], letra.y[int(e.passo)], 0.14))
			Efeitos.faiscas(self, onde, Tema.AMARELO, 14, 0.6)
			Som.tocar("tique", onde, -4.0, 1.0 + 0.08 * int(e.feitos))
			e.feitos = int(e.feitos) + 1
			if int(e.feitos) == 3:
				Forja.med_tracou(l)
			if julgamento != Ritmo.PERFEITO:
				Forja.som_falante(l, "clique", 0.4)
		"carimbo":
			var centro := placa.to_global(SECAO.no_molde(0.5, 0.5, 0.16))
			Efeitos.faiscas(self, centro, Tema.AMARELO, 30, 1.0)
			Efeitos.anel(self, centro, Tema.AMARELO, 0.6)
			Som.tocar("carimbo", centro, 0.0)
			if julgamento != Ritmo.PERFEITO:
				Som.no_controle(l, "carimbo", 0.6)
			if p:
				p.gesto("attack-melee-right", 0.45)
		"abre":
			e.aberto = true
			Som.tocar("sopro", placa.global_position, -2.0)
			if p:
				p.gesto("interact-right", 0.4)
		"fecha":
			e.aberto = false
			Forja.sentir(l, "golpe")  # o molde fecha
			Som.tocar("bigorna", placa.global_position, -8.0)
	_avancar(l)


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	var e: Dictionary = j[l]
	e.torta = true
	var placa: Node3D = e.nos.placa
	Efeitos.faiscas(self, placa.to_global(SECAO.no_molde(0.5, 1.0, 0.1)), Tema.LARANJA, 24, 0.6)
	var p := jogador(l)
	if p:
		p.gesto("emote-no", 0.5)
	_avancar(l)


func _avancar(l: int) -> void:
	var e: Dictionary = j[l]
	e.n = int(e.n) + 1
	e.passo = int(e.passo) + 1
	if int(e.passo) < e.roteiro.size():
		_armar(l)
		return
	_peca_pronta(l)
	_nova_peca(l, float(e.s) + float(e.tam))


func _peca_pronta(l: int) -> void:
	var e: Dictionary = j[l]
	e.volta = int(e.volta) + 1
	e.aberto = false
	if treinando:
		return
	var nos: Dictionary = e.nos
	var k := int(e.inteiras) + int(e.tortas)
	var pos := Vector3(float(nos.cx) - 0.6 + 0.4 * (k % 4), 0.9 + 0.35 * int(k / 4.0), -1.6)
	var peca := Kit.caixa(self, Vector3(0.35, 0.06, 0.18), pos, nos.ouro)
	if bool(e.torta):
		e.tortas = int(e.tortas) + 1
		peca.rotation.z = deg_to_rad(25.0)
		peca.material_override = Kit.material(Color("#7a5a2a"), 0.0, 0.8)
	else:
		e.inteiras = int(e.inteiras) + 1
		marcar(l, INTEIRA)
		Efeitos.faiscas(self, pos, Tema.AMARELO, 20, 0.8)
		Som.tocar("sucesso", pos, -10.0)


## A letra da peça nova na placa: os sulcos entre os pontos e os pontos numerados.
func _desenhar_a_letra(l: int) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	var letra: Dictionary = LETRAS[int(e.letra)]
	for k in 2:
		var a := SECAO.no_molde(letra.x[k], letra.y[k], 0.108)
		var b := SECAO.no_molde(letra.x[k + 1], letra.y[k + 1], 0.108)
		var s: MeshInstance3D = nos.sulcos[k]
		s.position = (a + b) * 0.5
		s.rotation.y = atan2(b.x - a.x, b.z - a.z)
		s.scale = Vector3(1, 1, a.distance_to(b))
		s.material_override = nos.escuro
	for k in 3:
		var c := SECAO.no_molde(letra.x[k], letra.y[k], 0.11)
		var pt: Dictionary = nos.pontos[k]
		(pt.disco as MeshInstance3D).position = c
		(pt.disco as MeshInstance3D).material_override = nos.escuro
		(pt.rotulo as Label3D).position = c + Vector3(0, 0.2, -0.14)


func _mostrar(l: int) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	var em_jogo := fase == "jogo" and not acabou[l] and not e.roteiro.is_empty()
	var passo_i := int(e.passo)
	var tracando := em_jogo and passo_i < 3 and str(e.roteiro[passo_i][0]) == "ponto"
	var letra: Dictionary = LETRAS[int(e.letra)]
	for k in 3:
		var pt: Dictionary = nos.pontos[k]
		var feito := k < int(e.feitos)
		(pt.disco as MeshInstance3D).visible = em_jogo
		if feito:
			(pt.disco as MeshInstance3D).material_override = nos.ouro
		(pt.rotulo as Label3D).visible = tracando
		(pt.rotulo as Label3D).modulate = Tema.AMARELO if feito else Tema.SUAVE
	for k in 2:
		(nos.sulcos[k] as MeshInstance3D).visible = em_jogo
		if k + 1 < int(e.feitos):
			(nos.sulcos[k] as MeshInstance3D).material_override = nos.ouro
	var alvo: MeshInstance3D = nos.alvo
	alvo.visible = tracando
	if tracando:
		alvo.position = SECAO.no_molde(letra.x[passo_i], letra.y[passo_i], 0.13)
		alvo.scale = Vector3.ONE * (0.92 + 0.1 * sin(Ritmo.batida() * TAU))
	# o metal brilha na batida do carimbo e esfria na peça torta
	var quente := 0.25
	if em_jogo:
		# o quarto passo de todo roteiro é o carimbo
		quente = clampf(1.0 - absf(Ritmo.batida() - (float(e.s) + float(e.roteiro[3][1]))), 0.25, 1.0)
		if bool(e.torta):
			quente = 0.1
	var metal: StandardMaterial3D = nos.metal
	var cor_metal := Color("#5a1a08").lerp(Color("#ff9a3a"), quente)
	metal.albedo_color = cor_metal.darkened(0.5)
	metal.emission = cor_metal
	metal.emission_energy_multiplier = 0.3 + 2.2 * quente
	# as metades se afastam enquanto o molde está aberto
	var meio := 0.3 if bool(e.aberto) else 0.0
	for k in nos.metades.size():
		var metade: Node3D = nos.metades[k]
		metade.position.x = lerpf(metade.position.x, meio * (-1.0 if k == 0 else 1.0), 0.2)


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(_antes)
	return lista


func _antes(a: int, b: int) -> bool:
	if int(j[a].inteiras) != int(j[b].inteiras):
		return int(j[a].inteiras) > int(j[b].inteiras)
	if int(pontos[a]) != int(pontos[b]):
		return int(pontos[a]) > int(pontos[b])
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		return "Peças: %d" % int(j[lugar].inteiras)
	return super(lugar)
```

## O que o registro mede

- As medidas do núcleo, como hoje (o módulo amostra os toques a cada
  quadro): quantos dedos chegaram juntos, que pedaço do touchpad os toques
  cobriram, a abertura máxima, abrir e fechar, o clique (`med_tracou` quando
  os três pontos saem, `med_pedir("clique")` e `med_pedir("dois_dedos")` ao
  armar o carimbo e o abrir) — os vereditos `touchpad_dois_dedos` e
  `touchpad_clique` da bancada.
- O kit: `nota` e `toque` (o clique pedido contra o feito, no tempo).
- A linha `entrada` em cada toque julgado: o passo, a posição dos dois
  dedos e quantos estavam encostados.

## Armadilhas

- **O brilho do metal** é na batida do carimbo do roteiro da peça
  (`e.roteiro[3]`: o quarto passo é sempre o carimbo, nos três roteiros).
- **O clique é um evento** (`Forja.apertou`, um quadro): o cruzamento dele é
  o próprio quadro; um clique antes da janela se perde (não é erro).
- **Os pontos contam com qualquer dos dois dedos**; o primeiro ponto pode
  ser encostar ou chegar deslizando.
- **`med_tracou` só com os três pontos acertados** (BOM ou melhor): é o que o
  veredito chama de letra completa.
- **As metades andam em `x` local da placa** (ela é inclinada): nunca
  `global_position`.
- **As fotos:** `godot/testes/captura_jogo.gd` tem os momentos de
  `"molde"` lendo `e.passo == 0/1/2` como os passos antigos; troque (Provas).

## Pronto quando

O Molde joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos
três temperamentos; o cabo que cai e volta começa uma peça nova; a primeira
peça pede os três pontos, o clique e os dois dedos; os vereditos
`touchpad_dois_dedos` e `touchpad_clique` passam na prova limpa, e `um-dedo`
e `sem-clique` continuam pegos no gauntlet; o fim tem sempre vencedor;
`godot/scripts/salas/molde.gd` não existe mais; `bash tests/prova_do_jogo.sh`
passa; e `bash tests/prova_visual.sh` passa com a prancha **olhada**.

## Provas

**`godot/testes/prova_do_jogo.gd`:**

1. O Molde joga pelo `_joga_o_minigame("S03_J11", 140.0, ...)` da H08, que
   espera a fase `fim` pelo relógio de parede (90 s de música, o aviso e o
   fechamento); as esperas de `_termina_a_sala()` e da prova de poucos já
   são as da H08.
2. Em `_prova_do_relatorio()`, no laço da linha do tempo:

   ```gdscript
   	var molde := [0, 0, 0, 0]
   	# (dentro do laço)
   			if ev.get("tipo", "") == "toque" and ev.get("slot", "") == "S03_J11":
   				molde[int(ev.get("lugar", 0))] += 1
   	# (depois do laço)
   	for l in 4:
   		_esperar(molde[l] >= 6, "S03_J11 P%d: a primeira peça julgada (%d notas)" % [l + 1, molde[l]])
   ```

**`godot/testes/captura_jogo.gd`:** os momentos de `"molde"` passam a:

```gdscript
		"molde": [
			["molde_tracar", p1.call(func(_sala, e) -> bool: return int(e.feitos) >= 2 and int(e.passo) <= 2)],
			["molde_abrir", p1.call(func(_sala, e) -> bool: return bool(e.aberto))],
			["molde_carimbar", p1.call(func(_sala, e) -> bool:
				return not e.roteiro.is_empty() and int(e.passo) == 3 and absf(Ritmo.batida() - float(e.s) - 3.0) < 0.2)],
		],
```

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**O André (local):** `scripts/gauntlet.sh` (o `um-dedo` e o `sem-clique` têm
de sair pegos) e `bash tests/prova_de_poucos.sh`; depois
`./run-local.sh -- --sala=molde`: o traço de um ponto por tempo cabe no
dedo, o clique na batida é claro, abrir e fechar dois dedos no tempo se
aprende, a textura de pedra se sente no cabo, e a estante enche.

## Ao terminar

- `godot/scripts/minigames/catalogo.gd`: tire `"molde"` de `SALAS_ANTIGAS`;
  ponha `"S03_J11": preload("res://scripts/minigames/s03/o_molde.gd")` em
  `MINIGAMES` e `"S03_J11"` na lista `minigames` da S03.
- `git rm godot/scripts/salas/molde.gd godot/scripts/salas/molde.gd.uid`.
- `godot/scripts/traducoes.gd`: `"Trace!": "Trace!"` (o título `"O Molde"` já
  existe); em `EN_PADROES`, `["^Peças: (\\d+)$", "Pieces: $1"]`.
- Importe; `o_molde.gd.uid` e `secao.gd.uid` no commit.
- No [quadro](README.md): as linhas K1 a K5 abaixo da linha **K** (se ainda
  não existem), e a K1 **feito**, com o commit e o gasto real.
- Commit (sem trailer): `feat: O Molde no tempo da música — a peça em dois compassos, e a oficina da seção`
