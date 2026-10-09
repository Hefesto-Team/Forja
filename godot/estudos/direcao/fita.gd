extends RefCounted
## A direção Fita Magnética, num lugar só (o estudo de direção de arte): a
## paleta com o trabalho de cada cor, as quatro fontes, a regra que recolore
## os colormaps da Kenney e os materiais com néon de dono.
##
## A regra que manda em tudo: néon é dos jogadores. O cenário tem um violeta
## próprio, escuro, e nenhuma das quatro cores dos lugares aparece fora do
## jogador dono dela.

# --- a fita: as superfícies (do mais fundo ao mais claro) ---
const FITA := Color("#0d0a16")       ## o fundo de tudo: a fita
const CASCO := Color("#17121f")      ## o casco do cassete: placas do HUD, o plástico
const CASCO_ALTO := Color("#241c30")  ## o casco iluminado, a borda do plástico
const GRAFITE := Color("#3a3346")    ## trilho, segmento apagado do VU, linha estrutural
const JANELA := Color("#07050c")     ## o vidro escuro da janela do cassete, o fundo da célula do leader
const SOMBRA := Color(0, 0, 0, 0.45)  ## a sombra deslocada de placa, etiqueta e adesivo (nunca traço)

# --- a etiqueta: o papel e a tinta ---
const ETIQUETA := Color("#efe4c8")   ## o papel da etiqueta, o texto claro do HUD
const ETIQUETA_SOMBRA := Color("#cfc2a0")  ## a dobra do papel, a linha pautada
const TINTA := Color("#1c1626")      ## a caneta sobre a etiqueta
const TINTA_SUAVE := Color("#5a4f66")  ## o rótulo impresso sobre a etiqueta
const MUDO := Color("#857a95")       ## o texto secundário sobre o casco (o desligado, a dica)

# --- o cenário: o par próprio, escuro, que nunca encosta nos jogadores ---
const VIOLETA := Color("#4a3aa8")    ## o néon da arquitetura (tubo na parede, beira do palco); nunca acima de L 50
const VIOLETA_FUNDO := Color("#1d1638")  ## a luz de preenchimento, a névoa
const TUNGSTENIO := Color("#ffd9a8")  ## a luz quente de lâmpada (pódio, foco da bigorna): luz, nunca traço
const OXIDO := Color("#3b2a22")      ## a fita magnética em si: o rolo, a tira do confete no escuro
const OXIDO_BRILHO := Color("#7a5640")  ## o óxido que pega luz: a face da tira que vira, o cabo do martelo

# --- os jogadores: os únicos néons saturados da tela ---
const JOGADOR := [
	Color("#29e6ff"),  ## P1 ciano
	Color("#ff3ea5"),  ## P2 magenta
	Color("#d4ff4a"),  ## P3 limão (mais amarelo que o de partida: separa do ciano na tritanopia)
	Color("#ee9a1e"),  ## P4 âmbar (mais fundo que o de partida: separa do limão na deuteranopia)
]
const NOME_DA_COR := ["ciano", "magenta", "limão", "âmbar"]
## O padrão do LED de jogador de cada lugar (o LEDS_DO_LUGAR do jogo: as cinco
## lâmpadas do controle, 1 | 2 | 3 | 4 acesas). A cor nunca sozinha.
const LEDS := [0x04, 0x0A, 0x15, 0x1B]

# --- as tintas das seções: impressas, nunca néon (a etiqueta de cada lado) ---
const SECAO := [
	Color("#c8432f"),  ## 1 a forja: vermelhão
	Color("#2f55c4"),  ## 2 cobalto
	Color("#1f8a7e"),  ## 3 verde-petróleo
	Color("#c79a2a"),  ## 4 mostarda
	Color("#86409a"),  ## 5 ameixa
]

# --- o erro ---
const ERRO_R := Color("#ff2a4a")     ## só no deslocamento de cor da Dissonância
const ERRO_B := Color("#2a6bff")

const BUNGEE := "res://assets/fontes/Bungee-Regular.ttf"
const VT323 := "res://assets/fontes/VT323-Regular.ttf"
const ARCHIVO := "res://assets/fontes/ArchivoNarrow-wght.ttf"
const MARCADOR := "res://assets/fontes/PermanentMarker-Regular.ttf"

static var _fontes := {}


static func fonte(caminho: String, peso := 0) -> Font:
	var chave := "%s@%d" % [caminho, peso]
	if _fontes.has(chave):
		return _fontes[chave]
	var base: FontFile = load(caminho)
	var f: Font = base
	if peso > 0:
		var fv := FontVariation.new()
		fv.base_font = base
		fv.variation_opentype = {"wght": peso}
		f = fv
	_fontes[chave] = f
	return f


static func bungee() -> Font:
	return fonte(BUNGEE)


static func vt() -> Font:
	return fonte(VT323)


static func archivo(peso := 500) -> Font:
	return fonte(ARCHIVO, peso)


static func marcador() -> Font:
	return fonte(MARCADOR)


# ------------------------------------------------------------ o recolorir --
## A regra de recolorir um pacote da Kenney: cada cor do colormap passa pelo
## OKLab (a luz que o olho vê). A luz se comprime na faixa do papel, o croma
## encolhe e um pouco do violeta do cenário entra por cima — em linha reta no
## plano a/b, nunca girando o matiz (girar leva o laranja ao magenta, que é de
## um jogador). O degradê de cada bloco (claro em cima, escuro embaixo) fica:
## é ele que faz o volume.
##
##   sat:  quanto do croma fica
##   tinge: quanto croma de violeta entra (em unidades de OKLab)
##   l0, l1: a luz nova vai de l0 (o preto da Kenney) a l0 + l1 (o branco)
const GRADE := {
	"cenario": {"sat": 0.30, "tinge": 0.024, "l0": 0.16, "l1": 0.28},   ## chão e parede: escuros, frios, foscos
	"maquina": {"sat": 0.42, "tinge": 0.024, "l0": 0.18, "l1": 0.42},   ## fliperamas e móveis do estúdio
	"objeto": {"sat": 0.40, "tinge": 0.0, "l0": 0.22, "l1": 0.56},    ## o que se joga (bigorna, martelo): um degrau acima
	"personagem": {"sat": 0.80, "tinge": 0.006, "l0": 0.06, "l1": 0.86},  ## pele e cabelo quase como vieram
}

## O papel de cada pacote copiado para o estudo.
const PAPEL_DO_PACOTE := {
	"mini-dungeon": "cenario",
	"mini-arena": "cenario",
	"mini-arcade": "maquina",
	"survival-kit": "objeto",
	"mini-characters": "personagem",
}


static func _lin(v: float) -> float:
	return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)


static func _srgb(v: float) -> float:
	v = clampf(v, 0.0, 1.0)
	return v * 12.92 if v <= 0.0031308 else 1.055 * pow(v, 1.0 / 2.4) - 0.055


static func para_oklab(c: Color) -> Vector3:
	var r := _lin(c.r)
	var g := _lin(c.g)
	var b := _lin(c.b)
	var l := pow(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b, 1.0 / 3.0)
	var m := pow(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b, 1.0 / 3.0)
	var s := pow(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b, 1.0 / 3.0)
	return Vector3(0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
		1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
		0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)


static func de_oklab(v: Vector3, a := 1.0) -> Color:
	var l := pow(v.x + 0.3963377774 * v.y + 0.2158037573 * v.z, 3.0)
	var m := pow(v.x - 0.1055613458 * v.y - 0.0638541728 * v.z, 3.0)
	var s := pow(v.x - 0.0894841775 * v.y - 1.2914855480 * v.z, 3.0)
	return Color(_srgb(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
		_srgb(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
		_srgb(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s), a)


static func graduar(c: Color, papel: String) -> Color:
	var g: Dictionary = GRADE[papel]
	var v := para_oklab(c)
	var violeta := para_oklab(VIOLETA)
	var dir := Vector2(violeta.y, violeta.z).normalized()
	var ab := Vector2(v.y, v.z) * float(g.sat) + dir * float(g.tinge)
	return de_oklab(Vector3(float(g.l0) + v.x * float(g.l1), ab.x, ab.y), c.a)


static func recolorir(img: Image, papel: String) -> Image:
	var out: Image = img.duplicate()
	out.convert(Image.FORMAT_RGBA8)
	var cache := {}
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			var k := c.to_rgba32()
			if not cache.has(k):
				cache[k] = graduar(c, papel)
			out.set_pixel(x, y, cache[k])
	return out


# ------------------------------------------------------------ os materiais --
const SH_CONTORNO := preload("res://estudos/direcao/shaders/contorno.gdshader")
const SH_CAVALEIRO := preload("res://estudos/direcao/shaders/cavaleiro.gdshader")
const SH_NEON := preload("res://estudos/direcao/shaders/neon.gdshader")


## O contorno de néon (casco invertido), para o que tem dono.
static func contorno(cor: Color, largura := 0.012, energia := 2.4) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SH_CONTORNO
	m.set_shader_parameter("cor", cor)
	m.set_shader_parameter("largura", largura)
	m.set_shader_parameter("energia", energia)
	return m


## Um néon que trabalha: chapado, com a energia acima de 1 para o glow pegar.
static func neon(cor: Color, energia := 2.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SH_NEON
	m.set_shader_parameter("cor", cor)
	m.set_shader_parameter("energia", energia)
	return m


## Fosco liso (o cenário montado: placas, cones, cabos).
static func fosco(cor: Color, rugoso := 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = rugoso
	m.metallic = 0.0
	return m


## Põe o contorno em todas as malhas de um modelo (o casco invertido vai no
## next_pass do material de cada superfície).
static func contornar(n: Node, cor: Color, largura := 0.012, energia := 2.4) -> void:
	for filho in n.get_children():
		if filho is MeshInstance3D:
			var mi: MeshInstance3D = filho
			for s in mi.mesh.get_surface_count():
				var base: Material = mi.get_surface_override_material(s)
				if base == null:
					base = mi.mesh.surface_get_material(s)
				if base == null:
					continue
				var m: Material = base.duplicate()
				m.next_pass = contorno(cor, largura, energia)
				mi.set_surface_override_material(s, m)
		contornar(filho, cor, largura, energia)
