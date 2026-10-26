extends RefCounted

const FITA := Color("#0d0a16")
const CASCO := Color("#17121f")
const CASCO_ALTO := Color("#241c30")
const GRAFITE := Color("#3a3346")
const JANELA := Color("#07050c")
const SOMBRA := Color(0, 0, 0, 0.45)

const ETIQUETA := Color("#efe4c8")
const ETIQUETA_SOMBRA := Color("#cfc2a0")
const TINTA := Color("#1c1626")
const TINTA_SUAVE := Color("#5a4f66")
const MUDO := Color("#857a95")

const VIOLETA := Color("#4a3aa8")
const VIOLETA_FUNDO := Color("#1d1638")
const TUNGSTENIO := Color("#ffd9a8")
const OXIDO := Color("#3b2a22")
const OXIDO_BRILHO := Color("#7a5640")

const JOGADOR := [
	Color("#29e6ff"),
	Color("#ff3ea5"),
	Color("#d4ff4a"),
	Color("#ee9a1e"),
]
const NOME_DA_COR := ["ciano", "magenta", "limão", "âmbar"]
const LEDS := [0x04, 0x0A, 0x15, 0x1B]

const SECAO := [
	Color("#c8432f"),
	Color("#2f55c4"),
	Color("#1f8a7e"),
	Color("#c79a2a"),
	Color("#86409a"),
]

const ERRO_R := Color("#ff2a4a")
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


const DE_JOGADOR := 0.085
const GRADE := {
	"cenario": {"sat": 0.30, "tinge": 0.024, "l0": 0.16, "l1": 0.28},
	"maquina": {"sat": 0.42, "tinge": 0.024, "l0": 0.18, "l1": 0.42},
	"objeto": {"sat": 0.40, "tinge": 0.0, "l0": 0.22, "l1": 0.56},
	"personagem": {"sat": 0.80, "tinge": 0.006, "l0": 0.06, "l1": 0.86, "teto": 0.098},
	"tecido": {"sat": 0.55, "tinge": 0.0, "l0": 0.46, "l1": 0.12, "teto": 0.098},
	"couro": {"sat": 0.40, "tinge": 0.0, "l0": 0.22, "l1": 0.14, "teto": 0.098},
}

const PELE_UV := Rect2(330.0 / 512.0, 380.0 / 512.0, 182.0 / 512.0, 132.0 / 512.0)

const PELE_ORC := Color("#89aa77")
const PELE_LATAO := Color("#bda978")
const PELE_ESCORIA := Color("#a3958e")
const PELE_RAPOSA := Color("#cd8d6d")
const CERAMICA := Color("#c9b08f")

const PAPEL_DO_PACOTE := {
	"mini-dungeon": "cenario",
	"mini-arena": "cenario",
	"mini-arcade": "maquina",
	"survival-kit": "objeto",
	"mini-characters": "personagem",
	"mini-dungeon-personagens": "personagem",
	"cube-pets": "personagem",
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
	var teto := float(g.get("teto", 1.0))
	if ab.length() > teto:
		ab = ab.normalized() * teto
	var l := float(g.l0) + v.x * float(g.l1)
	if g.has("teto"):
		for passo in 20:
			var perto := false
			for j in JOGADOR:
				if Vector3(l, ab.x, ab.y).distance_to(para_oklab(j)) < DE_JOGADOR:
					perto = true
			if not perto:
				break
			ab *= 0.9
	return de_oklab(Vector3(l, ab.x, ab.y), c.a)


static func recolorir(img: Image, papel: String, papel_pele := "") -> Image:
	var out: Image = img.duplicate()
	out.convert(Image.FORMAT_RGBA8)
	var cache := {}
	var w := float(out.get_width())
	var h := float(out.get_height())
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			var p := papel
			if papel_pele != "" and PELE_UV.has_point(Vector2((x + 0.5) / w, (y + 0.5) / h)):
				p = papel_pele
			var k := "%d@%s" % [c.to_rgba32(), p]
			if not cache.has(k):
				cache[k] = graduar(c, p)
			out.set_pixel(x, y, cache[k])
	return out


static func trocar_matiz(img: Image, pele: Color, limite: float) -> Image:
	var out: Image = img.duplicate()
	var alvo := para_oklab(pele)
	var cache := {}
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			var k := c.to_rgba32()
			if not cache.has(k):
				var v := para_oklab(c)
				cache[k] = de_oklab(Vector3(v.x, alvo.y, alvo.z), c.a) if v.y < limite else c
			out.set_pixel(x, y, cache[k])
	return out


const SH_CONTORNO := preload("res://estudos/direcao/shaders/contorno.gdshader")
const SH_CAVALEIRO := preload("res://estudos/direcao/shaders/cavaleiro.gdshader")
const SH_NEON := preload("res://estudos/direcao/shaders/neon.gdshader")


static func contorno(cor: Color, largura := 0.012, energia := 2.4) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SH_CONTORNO
	m.set_shader_parameter("cor", cor)
	m.set_shader_parameter("largura", largura)
	m.set_shader_parameter("energia", energia)
	return m


static func neon(cor: Color, energia := 2.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SH_NEON
	m.set_shader_parameter("cor", cor)
	m.set_shader_parameter("energia", energia)
	return m


static func fosco(cor: Color, rugoso := 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = rugoso
	m.metallic = 0.0
	return m


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
