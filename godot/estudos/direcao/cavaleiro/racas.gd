extends RefCounted
## As raças do cavaleiro (04, as raças). A raça é aparência: troca a cabeça
## inteira, a pele da mão e da perna de fora, e pode pôr cauda e mudar a
## proporção. O superior e o inferior continuam as peças humanas.
##
##   humana:   a cabeça do perfil (Mini Characters);
##   orc:      a head-mesh do `character-orc` (Kenney Mini Dungeon), no
##             mesmo esqueleto de 7 ossos;
##   automato: por código: a caixa chanfrada com o visor e a antena, as pinças;
##   golem:    por código: o bloco sem pescoço com a rachadura acesa, os
##             punhos de pedra, o torso a 1,15;
##   raposa:   a cabeça por código, a cauda do `animal-fox` (Kenney Cube Pets).
##
## Medidas nas unidades do personagem (o male-a tem 0,67 de altura; a cabeça
## dele vai de y 0,34 a 0,67). A cabeça por código fica presa ao osso `head`.

const Fita := preload("res://estudos/direcao/fita.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")
const Cortar := preload("res://estudos/direcao/cavaleiro/cortar.gd")
const Corpo := preload("res://estudos/direcao/cavaleiro/corpo.gd")

const RACAS := ["humana", "orc", "automato", "golem", "raposa"]
const NOME := {"humana": "Humana", "orc": "Orc", "automato": "Autômato", "golem": "Golem", "raposa": "Raposa"}
const PELE := {"orc": Fita.PELE_ORC, "automato": Fita.PELE_LATAO, "golem": Fita.PELE_ESCORIA, "raposa": Fita.PELE_RAPOSA}
## Onde a cabeça humana começa (o y do osso `head` em descanso).
const PESCOCO := 0.343
## A escala da cabeça por código sobre as medidas da tabela do 04. As medidas
## do 04 (0,28 a 0,34 de largura) ficam 30 % menores que a cabeça humana dos
## Mini Characters (0,45): na tela de montagem, ao lado de um humano, a
## cabeça da raça sumia. A 1,30, o autômato fica com 0,39 de largura.
const ESCALA_CABECA := 1.30
const RAPOSA_CAUDA := "res://estudos/direcao/kenney/cube-pets/animal-fox.glb"
const ENERGIA := 1.6

static var _cabelos := {}


## A raça muda a proporção antes de qualquer coisa ser presa à mão: o golem
## alarga o torso (o ombro e o braço vão junto) e a cabeça compensa.
static func preparar(esq: Skeleton3D, raca: String) -> void:
	if raca != "golem":
		return
	var torso := esq.find_bone("torso")
	esq.set_bone_pose_scale(torso, Vector3(1.15, 1.0, 1.15))
	var cabeca := esq.find_bone("head")
	esq.set_bone_pose_scale(cabeca, Vector3(0.87, 1.0, 0.87))
	esq.force_update_all_bone_transforms()


## Veste a raça. `perfil`: o personagem da cabeça (a marca do perfil sai da
## cor do cabelo dele); `maos`: os dois punhos no espaço do esqueleto,
## [esquerdo, direito].
static func vestir(esq: Skeleton3D, raca: String, perfil: String, cor: Color, maos: Array, contorno := true) -> void:
	if raca == "humana":
		return
	var marca := cabelo(perfil)
	var velha: MeshInstance3D = esq.get_node_or_null("head")
	if raca == "orc":
		var xf := velha.transform
		var vis := velha.visible
		esq.remove_child(velha)
		velha.queue_free()
		var orc := Cortar.partes("orc")
		var mi := Corpo.parte(esq, "head", orc.cabeca, orc.pele_cabeca, xf)
		mi.visible = vis
		return
	var presa := BoneAttachment3D.new()
	presa.name = "raca-cabeca"
	presa.bone_name = "head"
	esq.add_child(presa)
	presa.visible = velha.visible
	velha.visible = false
	var resto := esq.get_bone_global_rest(esq.find_bone("head"))
	var pecas: Dictionary
	match raca:
		"automato":
			pecas = automato(marca)
		"golem":
			pecas = golem(marca)
		"raposa":
			pecas = raposa(marca)
	var e := ESCALA_CABECA
	var xf_cab := resto.affine_inverse() * Transform3D(Basis().scaled(Vector3.ONE * e), Vector3(0, PESCOCO, 0))
	var corpo_ := Node3D.new()
	presa.add_child(corpo_)
	corpo_.transform = xf_cab
	_por(corpo_, "pele", pecas.pele, _liso(PELE[raca], 0.9, 0.2 if raca == "automato" else 0.0, cor))
	if contorno:
		Mundo.contornar(corpo_, cor, 0.012 / e, 1.6)
	if pecas.has("janela"):
		_por(corpo_, "janela", pecas.janela, _liso(Fita.JANELA, 0.6, 0.0, cor, 0.0))
	if pecas.has("clara"):
		_por(corpo_, "clara", pecas.clara, _liso(Fita.ETIQUETA_SOMBRA, 0.9, 0.0, cor))
	if pecas.has("tinta"):
		_por(corpo_, "tinta", pecas.tinta, _liso(Fita.TINTA, 0.6, 0.0, cor, 0.0))
	if pecas.has("marca"):
		_por(corpo_, "marca", pecas.marca, _liso(marca, 0.85, 0.0, cor))
	if pecas.has("acento"):
		var a := _por(corpo_, "acento", pecas.acento, Fita.neon(cor, ENERGIA))
		a.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# as mãos
	if raca in ["automato", "golem"]:
		for lado in 2:
			_mao(esq, ["arm-left", "arm-right"][lado], maos[lado], raca, cor, contorno)
	if raca == "raposa":
		_cauda(esq, cor, contorno)


## A cor do cabelo do perfil: a cor de maior área da cabeça, fora da pele.
static func cabelo(perfil: String) -> Color:
	if _cabelos.has(perfil):
		return _cabelos[perfil]
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://estudos/direcao/kenney/mini-characters/Textures/colormap.png"))
	var malha: Mesh = Cortar.partes(perfil).cabeca
	var arr := malha.surface_get_arrays(0)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var area := {}
	for t in idx.size() / 3:
		var uv := uvs[idx[t * 3]]
		if Fita.PELE_UV.has_point(uv):
			continue
		var a := (vs[idx[t * 3 + 1]] - vs[idx[t * 3]]).cross(vs[idx[t * 3 + 2]] - vs[idx[t * 3]]).length() * 0.5
		var px := Vector2i(clampi(int(uv.x * img.get_width()), 0, img.get_width() - 1), clampi(int(uv.y * img.get_height()), 0, img.get_height() - 1))
		var c := img.get_pixelv(px)
		var k := c.to_html(false)
		area[k] = float(area.get(k, 0.0)) + a
	var melhor := ""
	for k in area:
		if melhor == "" or area[k] > area[melhor] or (area[k] == area[melhor] and k < melhor):
			melhor = k
	var cor := Color(melhor) if melhor != "" else Fita.GRAFITE
	_cabelos[perfil] = cor
	return cor


static func _por(pai: Node3D, nome: String, malha: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.mesh = malha
	for i in malha.get_surface_count():
		mi.set_surface_override_material(i, mat)
	pai.add_child(mi)
	return mi


static var _texturas := {}


## Um material liso no shader do cavaleiro (o aro de luz na cor do dono).
static func _liso(c: Color, rug: float, metal: float, aro_cor: Color, aro := 0.25) -> ShaderMaterial:
	var k := c.to_html()
	if not _texturas.has(k):
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.set_pixel(0, 0, c)
		_texturas[k] = ImageTexture.create_from_image(img)
	var m := ShaderMaterial.new()
	m.shader = Fita.SH_CAVALEIRO
	m.set_shader_parameter("textura", _texturas[k])
	m.set_shader_parameter("rugosidade", rug)
	m.set_shader_parameter("metalico", metal)
	m.set_shader_parameter("aro_cor", aro_cor)
	m.set_shader_parameter("aro", aro)
	return m


# --------------------------------------------------------- a geometria --
static func _caixa(t: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = t
	return b


## A caixa chanfrada em degrau (o chanfro dos Mini Characters): três caixas
## cruzadas, 36 triângulos.
static func _chanfrada(t: Vector3, ch: float, centro: Vector3, lista: Array) -> void:
	lista.append([_caixa(Vector3(t.x, t.y - ch * 2.0, t.z - ch * 2.0)), Transform3D(Basis(), centro)])
	lista.append([_caixa(Vector3(t.x - ch * 2.0, t.y, t.z - ch * 2.0)), Transform3D(Basis(), centro)])
	lista.append([_caixa(Vector3(t.x - ch * 2.0, t.y - ch * 2.0, t.z)), Transform3D(Basis(), centro)])


## O tronco de pirâmide: a base (x, z) em y = 0, o topo (x, z) em y = h,
## faces chapadas.
static func _tronco(base: Vector2, topo: Vector2, h: float) -> ArrayMesh:
	var bx := base.x * 0.5
	var bz := base.y * 0.5
	var tx := topo.x * 0.5
	var tz := topo.y * 0.5
	var b := [Vector3(-bx, 0, -bz), Vector3(bx, 0, -bz), Vector3(bx, 0, bz), Vector3(-bx, 0, bz)]
	var t := [Vector3(-tx, h, -tz), Vector3(tx, h, -tz), Vector3(tx, h, tz), Vector3(-tx, h, tz)]
	var quads := [[t[0], t[1], t[2], t[3]], [b[3], b[2], b[1], b[0]]]
	for i in 4:
		var j := (i + 1) % 4
		quads.append([b[i], b[j], t[j], t[i]])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var meio := Vector3(0, h * 0.5, 0)
	for q in quads:
		var cq: Vector3 = (q[0] + q[1] + q[2] + q[3]) * 0.25
		for tri in [[q[0], q[1], q[2]], [q[0], q[2], q[3]]]:
			var a: Vector3 = tri[0]
			var b2: Vector3 = tri[1]
			var c: Vector3 = tri[2]
			var n := (c - a).cross(b2 - a).normalized()
			if n.dot(cq - meio) < 0.0:
				var tmp := b2
				b2 = c
				c = tmp
				n = -n
			for v in [a, b2, c]:
				st.set_normal(n)
				st.set_uv(Vector2(v.x + v.z, v.y))
				st.add_vertex(v)
	# indexado e com tangentes, como as caixas: o _juntar soma tudo num
	# índice só, e um pedaço sem índice ficaria de fora
	st.index()
	st.generate_tangents()
	return st.commit()


static func _prisma(t: Vector3, xf: Transform3D, lista: Array) -> void:
	var p := PrismMesh.new()
	p.size = t
	lista.append([p, xf])


static func _juntar(lista: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in lista:
		st.append_from(p[0], 0, p[1])
	# as normais de cada caixa ficam as dela (faces chapadas): gerar normais
	# suavizava a quina e borrava o chanfro em faixas
	return st.commit()


static func _montar(partes_: Dictionary) -> Dictionary:
	var out := {}
	for k in partes_:
		if not (partes_[k] as Array).is_empty():
			out[k] = _juntar(partes_[k])
	return out


## O autômato de latão: caixa chanfrada de 0,30 × 0,28 × 0,28; o visor, um
## vão JANELA de 0,24 × 0,06 a 0,10 do topo, com a linha de acento de
## 0,22 × 0,02 dentro; a antena de 0,08 com a bola de 0,025 (a marca).
static func automato(_marca: Color) -> Dictionary:
	var p := {"pele": [], "janela": [], "acento": [], "marca": []}
	var t := Vector3(0.30, 0.28, 0.28)
	var c := Vector3(0, t.y * 0.5, 0)
	_chanfrada(t, 0.025, c, p.pele)
	# as orelhas de parafuso: dois discos nos lados
	for s in [-1.0, 1.0]:
		var d := CylinderMesh.new()
		d.top_radius = 0.035
		d.bottom_radius = 0.035
		d.height = 0.02
		d.radial_segments = 6
		d.rings = 1
		p.pele.append([d, Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(s * (t.x * 0.5 + 0.01), c.y + 0.01, 0))])
	var yv := t.y - 0.10
	var zf := t.z * 0.5
	p.janela.append([_caixa(Vector3(0.24, 0.06, 0.02)), Transform3D(Basis(), Vector3(0, yv, zf - 0.006))])
	p.acento.append([_caixa(Vector3(0.22, 0.02, 0.01)), Transform3D(Basis(), Vector3(0, yv, zf + 0.005))])
	# a boca: a grade de três frestas
	for i in 3:
		p.janela.append([_caixa(Vector3(0.018, 0.04, 0.01)), Transform3D(Basis(), Vector3((i - 1) * 0.04, 0.07, zf + 0.001))])
	p.pele.append([_caixa(Vector3(0.012, 0.08, 0.012)), Transform3D(Basis(), Vector3(0.06, t.y + 0.04, 0))])
	var bola := SphereMesh.new()
	bola.radius = 0.025
	bola.height = 0.05
	bola.radial_segments = 6
	bola.rings = 3
	p.marca.append([bola, Transform3D(Basis(), Vector3(0.06, t.y + 0.08 + 0.02, 0))])
	return _montar(p)


## O golem de escória: um tronco de pirâmide, sem pescoço (desce 0,03): a
## base de 0,36 × 0,30, o topo de 0,26 × 0,24, 0,27 de altura. A silhueta é
## um trapézio, largo embaixo, que a 64 px não se confunde com a cabeça
## humana (larga em cima, pelo cabelo e as orelhas). Na frente: a
## sobrancelha de pedra de 0,30 × 0,045, os olhos e a boca em TINTA; duas
## pedras nas bochechas e uma laje torta no alto; a rachadura são três
## traços de 0,007 em zigue-zague num vão JANELA
## estreito, com o acento dentro; dois tufos de líquen de 0,05 no alto, um
## de cada lado, desencontrados (a marca).
static func golem(_marca: Color) -> Dictionary:
	var p := {"pele": [], "janela": [], "acento": [], "marca": [], "tinta": []}
	var base := -0.03
	var h := 0.27
	var zb := 0.15                      # a frente, embaixo
	var zt := 0.12                      # a frente, no topo
	var frente := func(y: float) -> float: return zb + (zt - zb) * (y - base) / h
	p.pele.append([_tronco(Vector2(0.36, 0.30), Vector2(0.26, 0.24), h), Transform3D(Basis(), Vector3(0, base, 0))])
	# a sobrancelha de pedra, que faz a sombra sobre os olhos
	var yb := base + 0.165
	_chanfrada(Vector3(0.30, 0.045, 0.07), 0.01, Vector3(0, yb, frente.call(yb) + 0.01), p.pele)
	# as pedras soltas: duas bochechas que alargam a base e uma laje torta
	# no alto, fora do eixo (a cabeça não é simétrica)
	for s in [-1.0, 1.0]:
		_chanfrada(Vector3(0.08, 0.075, 0.12), 0.012, Vector3(s * 0.165, base + 0.045, 0.06), p.pele)
	_chanfrada(Vector3(0.15, 0.05, 0.14), 0.012, Vector3(0.035, base + h + 0.015, -0.02), p.pele)
	var yo := base + 0.13
	for s in [-1.0, 1.0]:
		p.tinta.append([_caixa(Vector3(0.06, 0.026, 0.01)), Transform3D(Basis(), Vector3(s * 0.075, yo, frente.call(yo) + 0.001))])
	# a boca: uma fresta reta, larga
	var ym := base + 0.06
	p.tinta.append([_caixa(Vector3(0.14, 0.014, 0.01)), Transform3D(Basis(), Vector3(0, ym, frente.call(ym) + 0.001))])
	# a rachadura: do topo até a sobrancelha, à esquerda do meio
	var x0 := -0.05
	var ys := [base + h - 0.005, base + 0.235, base + 0.212, base + 0.188]
	var xs := [x0 + 0.010, x0 - 0.010, x0 + 0.010, x0 - 0.004]
	for i in 3:
		var de := Vector2(xs[i], ys[i])
		var ate := Vector2(xs[i + 1], ys[i + 1])
		var meio := (de + ate) * 0.5
		var ang := (ate - de).angle()
		var comp := de.distance_to(ate) + 0.004
		var z: float = frente.call(meio.y)
		p.janela.append([_caixa(Vector3(comp, 0.018, 0.01)), Transform3D(Basis(Vector3.BACK, ang), Vector3(meio.x, meio.y, z + 0.001))])
		p.acento.append([_caixa(Vector3(comp, 0.007, 0.01)), Transform3D(Basis(Vector3.BACK, ang), Vector3(meio.x, meio.y, z + 0.004))])
	_chanfrada(Vector3(0.07, 0.035, 0.06), 0.01, Vector3(0.07, base + h + 0.05, -0.04), p.marca)
	_chanfrada(Vector3(0.05, 0.03, 0.05), 0.01, Vector3(-0.08, base + h + 0.010, 0.03), p.marca)
	return _montar(p)


## A raposa ferreira: caixa de 0,28 × 0,24 × 0,26; a metade de baixo da
## cara em creme (ETIQUETA_SOMBRA), com o focinho de 0,11 × 0,07 × 0,08 e a
## ponta do nariz em TINTA (as bochechas na cor da marca liam como bigode, e
## em placas soltas, como dentes); duas orelhas, prismas de 0,08 × 0,10 (a ponta é a
## marca); os olhos de 0,03 em TINTA.
static func raposa(_marca: Color) -> Dictionary:
	var p := {"pele": [], "tinta": [], "marca": [], "janela": [], "clara": []}
	var t := Vector3(0.28, 0.24, 0.26)
	var c := Vector3(0, t.y * 0.5, 0)
	_chanfrada(t, 0.02, c, p.pele)
	var zf := t.z * 0.5
	# a máscara creme: uma placa só na metade de baixo da cara, de bochecha a
	# bochecha (0,26 × 0,10), e o focinho de 0,11 × 0,07 × 0,08 sobre ela
	p.clara.append([_caixa(Vector3(0.26, 0.10, 0.01)), Transform3D(Basis(), Vector3(0, 0.05, zf + 0.001))])
	p.clara.append([_caixa(Vector3(0.11, 0.07, 0.08)), Transform3D(Basis(), Vector3(0, 0.055, zf + 0.04))])
	# a ponta do nariz em TINTA, em cima da frente do focinho
	p.tinta.append([_caixa(Vector3(0.045, 0.028, 0.02)), Transform3D(Basis(), Vector3(0, 0.078, zf + 0.075))])
	for s in [-1.0, 1.0]:
		p.tinta.append([_caixa(Vector3(0.03, 0.03, 0.01)), Transform3D(Basis(), Vector3(s * 0.065, 0.14, zf + 0.002))])
		# a orelha: o prisma em pé, e a ponta (o terço de cima) na marca
		var xo: float = s * 0.085
		_prisma(Vector3(0.08, 0.10, 0.04), Transform3D(Basis(Vector3.BACK, -s * 0.15), Vector3(xo, t.y + 0.05, -0.02)), p.pele)
		_prisma(Vector3(0.027, 0.034, 0.042), Transform3D(Basis(Vector3.BACK, -s * 0.15), Vector3(xo - s * 0.012, t.y + 0.085, -0.02)), p.marca)
	return _montar(p)


## A pinça do autômato (dois dedos de 0,02 × 0,05) ou o punho de pedra do
## golem (cubo chanfrado de 0,075), no punho que Montar.mao acha.
static func _mao(esq: Skeleton3D, osso: String, punho: Vector3, raca: String, cor: Color, contorno: bool) -> void:
	var presa := BoneAttachment3D.new()
	presa.name = "raca-" + osso
	presa.bone_name = osso
	esq.add_child(presa)
	var pose := esq.get_bone_global_pose(esq.find_bone(osso))
	var lista := []
	if raca == "automato":
		lista.append([_caixa(Vector3(0.05, 0.02, 0.05)), Transform3D(Basis(), Vector3(0, -0.01, 0))])
		for s in [-1.0, 1.0]:
			lista.append([_caixa(Vector3(0.02, 0.05, 0.02)), Transform3D(Basis(Vector3.RIGHT, s * 0.25), Vector3(0, -0.04, s * 0.016))])
	else:
		_chanfrada(Vector3(0.075, 0.075, 0.075), 0.012, Vector3(0, -0.01, 0), lista)
	var n := Node3D.new()
	presa.add_child(n)
	n.transform = pose.affine_inverse() * Transform3D(Basis(), punho)
	_por(n, "mao", _juntar(lista), _liso(PELE[raca], 0.9 if raca == "golem" else 0.55, 0.2 if raca == "automato" else 0.0, cor))
	if contorno:
		Mundo.contornar(n, cor, 0.008, 1.6)


## A cauda da raposa: o `tail` do animal-fox a ×0,33 (0,30 de comprimento),
## no osso `root` em (0; 0,20; −0,10), virada 8° para o lado (o balanço).
static func _cauda(esq: Skeleton3D, cor: Color, contorno: bool) -> void:
	var cena: Node = (load(RAPOSA_CAUDA) as PackedScene).instantiate()
	var tail: MeshInstance3D = cena.find_child("tail", true, false)
	var presa := BoneAttachment3D.new()
	presa.name = "raca-cauda"
	presa.bone_name = "root"
	esq.add_child(presa)
	var resto := esq.get_bone_global_rest(esq.find_bone("root"))
	var n := Node3D.new()
	presa.add_child(n)
	n.transform = resto.affine_inverse() * Transform3D(Basis(Vector3.UP, deg_to_rad(8.0)).scaled(Vector3.ONE * 0.33), Vector3(0, 0.20, -0.10))
	var mi := MeshInstance3D.new()
	mi.name = "cauda"
	mi.mesh = tail.mesh
	n.add_child(mi)
	cena.free()
	if contorno:
		Mundo.contornar(n, cor, 0.012 / 0.33, 1.6)
