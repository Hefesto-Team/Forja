class_name Pintura
extends RefCounted
## A cor das peças (arte/02 e 04): cada cor do colormap da Kenney passa pelo
## OKLab, a luz se comprime na faixa do papel da parte, o croma encolhe e a peça
## nunca chega perto do néon de um jogador. O degradê de cada bloco (claro em
## cima, escuro embaixo) fica: é ele que faz o volume. O jogo não puxa a peça
## para o violeta do cenário (o `tinge` do estudo é 0 nos quatro papéis).
##
## Também prepara a malha de um boneco com skin para o shader do cavaleiro:
## o superior e o inferior, a posição de repouso (a faixa do acento) e a normal
## suave do contorno.

## A distância mínima da peça até um néon de jogador: 0,08 mais a folga do sRGB
## de 8 bits.
const DE_JOGADOR := 0.085
## `l = l0 + L × l1`; `sat` é o quanto do croma fica; `teto` é o croma máximo.
const GRADE := {
	"personagem": {"sat": 0.80, "l0": 0.06, "l1": 0.86, "teto": 0.098},  ## pele e cabelo quase como vieram
	"tecido": {"sat": 0.55, "l0": 0.46, "l1": 0.12, "teto": 0.098},      ## o tronco superior
	"couro": {"sat": 0.40, "l0": 0.22, "l1": 0.14, "teto": 0.07},        ## o tronco inferior
	"objeto": {"sat": 0.40, "l0": 0.22, "l1": 0.56, "teto": 0.03},       ## o que se segura: o item
}
## A pele no colormap dos Mini Characters (as três rampas: a mão, a perna de
## fora, o rosto), medida nos 12. No tecido e no couro, esses pixels ficam com a
## graduação da cabeça; numa raça, o shader troca a pele pela dela.
const PELE_UV := Rect2(330.0 / 512.0, 380.0 / 512.0, 182.0 / 512.0, 132.0 / 512.0)
const INFERIOR := ["root", "leg-left", "leg-right"]
## O pescoço: o friso do superior não passa dele.
const PESCOCO := 0.343

static var _texturas := {}   ## "caminho|papel|papel_pele" -> ImageTexture
static var _imagens := {}    ## ImageTexture -> Image (para as medianas)
static var _prontas := {}    ## Mesh de origem -> {"mesh", "medidas"}
static var _medidas_de := {} ## Mesh preparada -> medidas


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


## Distância OKLab entre duas cores.
static func delta_e(a: Color, b: Color) -> float:
	return para_oklab(a).distance_to(para_oklab(b))


## A cor de um colormap no papel: a luz na faixa, o croma no teto e longe dos
## néons (o croma desce 10 % por passo, até 20, enquanto a cor está perto de
## algum Tema.JOGADOR).
static func graduar(c: Color, papel: String) -> Color:
	var g: Dictionary = GRADE[papel]
	var v := para_oklab(c)
	var ab := Vector2(v.y, v.z) * float(g.sat)
	var teto := float(g.teto)
	if ab.length() > teto:
		ab = ab.normalized() * teto
	var l := float(g.l0) + v.x * float(g.l1)
	for passo in 20:
		var perto := false
		for j in Tema.JOGADOR:
			if Vector3(l, ab.x, ab.y).distance_to(para_oklab(j)) < DE_JOGADOR:
				perto = true
		if not perto:
			break
		ab *= 0.9
	return de_oklab(Vector3(l, ab.x, ab.y), c.a)


## `papel_pele`: o papel dos pixels de PELE_UV (o tecido e o couro deixam a pele
## na graduação da cabeça).
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


## Os pixels verdes (o a do OKLab abaixo de `limite`) ganham o a e o b de
## `pele`, cada um com a sua luz.
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


## A textura do colormap `caminho` recolorida pelo papel, uma vez por trio.
## `papel_pele`: o papel dos pixels de PELE_UV ("" fora do Mini Characters).
static func textura(caminho: String, papel: String, papel_pele := "") -> ImageTexture:
	var chave := "%s|%s|%s" % [caminho, papel, papel_pele]
	if _texturas.has(chave):
		return _texturas[chave]
	var origem: Texture2D = load(caminho)
	var img := origem.get_image()
	if img.is_compressed():
		img.decompress()
	var t := ImageTexture.create_from_image(recolorir(img, papel, papel_pele))
	_texturas[chave] = t
	_imagens[t] = t.get_image()
	return t


static func _nome_do_osso(mi: MeshInstance3D, esq: Skeleton3D, i: int) -> String:
	var sk := mi.skin
	if sk != null and i < sk.get_bind_count():
		var n := String(sk.get_bind_name(i))
		if n != "":
			return n
		var b := sk.get_bind_bone(i)
		if b >= 0:
			return esq.get_bone_name(b)
	return esq.get_bone_name(i) if i < esq.get_bone_count() else ""


## Prepara a malha de um boneco com skin: grava COLOR.r (0 superior, 1
## inferior), UV2 (a posição de repouso x, y; y = -1 nos braços e na cabeça) e a
## normal suave no TANGENT (o casco do contorno), pelo osso de maior peso de cada
## vértice: `leg-left`, `leg-right` e `root` são inferior; os outros, superior.
## Devolve as medidas para o shader: {"friso_y0", "friso_y1", "friso_alto",
## "costura_x", "costura_larg", "frente_cima", "frente_baixo", "largura_torso",
## "altura_perna"}. Guarda a malha pronta num cache por Mesh: os quatro lugares
## dividem a malha e cada um tem o seu material.
static func preparar(mi: MeshInstance3D, esq: Skeleton3D) -> Dictionary:
	var original: Mesh = mi.mesh
	if _medidas_de.has(original):
		return _medidas_de[original]
	if _prontas.has(original):
		mi.mesh = _prontas[original].mesh
		return _prontas[original].medidas
	var nova := ArrayMesh.new()
	var caixas := {}   ## osso -> AABB dos vértices de maior peso nele
	for s in original.get_surface_count():
		var arr: Array = original.surface_get_arrays(s)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var ossos: PackedInt32Array = arr[Mesh.ARRAY_BONES]
		var pesos: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
		var formato: int = original.surface_get_format(s)
		var por_vertice := 8 if (formato & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS) != 0 else 4
		var cores := PackedColorArray()
		var uv2 := PackedVector2Array()
		var soma := {}
		for i in vs.size():
			var k := vs[i].snapped(Vector3.ONE * 0.0005)
			soma[k] = soma.get(k, Vector3.ZERO) + ns[i]
		var tg := PackedFloat32Array()
		tg.resize(vs.size() * 4)
		for i in vs.size():
			var melhor := ""
			var maior := -1.0
			if ossos.size() >= (i + 1) * por_vertice:
				for j in por_vertice:
					if pesos[i * por_vertice + j] > maior:
						maior = pesos[i * por_vertice + j]
						melhor = _nome_do_osso(mi, esq, ossos[i * por_vertice + j])
			var baixo := melhor in INFERIOR
			var marca := 1.0 if baixo else 0.0   # COLOR.r é a marca da parte, não uma cor de tela
			cores.append(Color(marca, 0.0, 0.0, 1.0))
			var braco := melhor == "arm-left" or melhor == "arm-right" or melhor == "head"
			uv2.append(Vector2(vs[i].x, -1.0 if braco else vs[i].y))
			if melhor != "":
				var c: Array = caixas.get(melhor, [vs[i], vs[i]])
				c[0] = Vector3(minf(c[0].x, vs[i].x), minf(c[0].y, vs[i].y), minf(c[0].z, vs[i].z))
				c[1] = Vector3(maxf(c[1].x, vs[i].x), maxf(c[1].y, vs[i].y), maxf(c[1].z, vs[i].z))
				caixas[melhor] = c
			var n: Vector3 = soma[vs[i].snapped(Vector3.ONE * 0.0005)]
			n = n.normalized() if n.length() > 0.0001 else ns[i]
			tg[i * 4] = n.x
			tg[i * 4 + 1] = n.y
			tg[i * 4 + 2] = n.z
			tg[i * 4 + 3] = 1.0
		arr[Mesh.ARRAY_TANGENT] = tg
		arr[Mesh.ARRAY_COLOR] = cores
		arr[Mesh.ARRAY_TEX_UV2] = uv2
		var flags := Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if por_vertice == 8 else 0
		nova.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, flags)
		nova.surface_set_material(s, original.surface_get_material(s))
	var medidas := _medir(caixas)
	_prontas[original] = {"mesh": nova, "medidas": medidas}
	_medidas_de[nova] = medidas
	mi.mesh = nova
	return medidas


static func _medir(caixas: Dictionary) -> Dictionary:
	var larg := func(osso: String) -> float:
		return caixas[osso][1].x - caixas[osso][0].x if caixas.has(osso) else 0.0
	var alt := func(osso: String) -> float:
		return caixas[osso][1].y - caixas[osso][0].y if caixas.has(osso) else 0.0
	var largura_torso: float = larg.call("torso")
	var altura_perna: float = maxf(alt.call("leg-left"), alt.call("leg-right"))
	var frente_cima: float = largura_torso * alt.call("torso") \
		+ larg.call("arm-left") * alt.call("arm-left") + larg.call("arm-right") * alt.call("arm-right")
	var frente_baixo: float = larg.call("leg-left") * alt.call("leg-left") + larg.call("leg-right") * alt.call("leg-right")
	var friso_alto := minf(0.010, 0.08 * frente_cima / maxf(2.0 * largura_torso, 0.0001))
	var costura_larg := minf(0.008, 0.05 * frente_baixo / maxf(2.0 * altura_perna, 0.0001))
	var area := 2.0 * friso_alto * largura_torso + 2.0 * costura_larg * altura_perna
	var teto := 0.08 * (frente_cima + frente_baixo)
	if area > teto and area > 0.0:
		friso_alto *= teto / area
		costura_larg *= teto / area
	var x_perna := 0.0
	for osso in ["leg-left", "leg-right"]:
		if caixas.has(osso):
			x_perna = maxf(x_perna, maxf(absf(caixas[osso][0].x), absf(caixas[osso][1].x)))
	var torso_y0: float = caixas["torso"][0].y if caixas.has("torso") else 0.0
	var torso_y1: float = caixas["torso"][1].y if caixas.has("torso") else 0.0
	return {
		"friso_y0": torso_y0, "friso_y1": minf(torso_y1, PESCOCO), "friso_alto": friso_alto,
		"costura_x": x_perna, "costura_larg": costura_larg,
		"frente_cima": frente_cima, "frente_baixo": frente_baixo,
		"largura_torso": largura_torso, "altura_perna": altura_perna,
	}


static func _mediana(v: Array) -> float:
	if v.is_empty():
		return 0.0
	v.sort()
	return float(v[v.size() / 2])


## As medianas de L (OKLab) de cada parte, pela cor da textura recolorida no UV
## de cada vértice: {"cabeca", "superior", "inferior"}, e as cores usadas por
## superior e inferior em "cores". Com `boneco.get_meta("so_pano", false)`, o
## superior e o inferior pulam os vértices com UV em PELE_UV (a pele).
static func medianas(boneco: Node3D) -> Dictionary:
	var so_pano := bool(boneco.get_meta("so_pano", false))
	var luz := {"cabeca": [], "superior": [], "inferior": []}
	var usadas := {}
	for n in boneco.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = n
		var mat := mi.get_surface_override_material(0) as ShaderMaterial
		if mat == null or not (mi.mesh is ArrayMesh):
			continue
		var cabeca := String(mi.name).begins_with("head")
		var cima: Image = _imagens.get(mat.get_shader_parameter("textura_cima"))
		var baixo: Image = _imagens.get(mat.get_shader_parameter("textura_baixo"))
		if cima == null or baixo == null:
			continue
		for s in mi.mesh.get_surface_count():
			var arr: Array = mi.mesh.surface_get_arrays(s)
			var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			var cores: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
			for i in uvs.size():
				var uv := uvs[i]
				var e_baixo := cores.size() > i and cores[i].r > 0.5
				var img := baixo if e_baixo else cima
				var c := img.get_pixelv(Vector2i(clampi(int(uv.x * img.get_width()), 0, img.get_width() - 1),
					clampi(int(uv.y * img.get_height()), 0, img.get_height() - 1)))
				var parte := "cabeca" if cabeca else ("inferior" if e_baixo else "superior")
				if parte != "cabeca" and so_pano and PELE_UV.has_point(uv):
					continue
				luz[parte].append(para_oklab(c).x)
				if parte != "cabeca":
					usadas[c] = true
	return {"cabeca": _mediana(luz.cabeca), "superior": _mediana(luz.superior),
		"inferior": _mediana(luz.inferior), "cores": usadas.keys()}
