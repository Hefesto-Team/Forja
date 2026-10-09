extends RefCounted
## A montagem do cavaleiro (04): três peças de personagens diferentes no mesmo
## esqueleto, cada uma com a pele de onde veio (o esqueleto e as poses de
## descanso são os mesmos nos 12, então qualquer cabeça encaixa em qualquer
## tronco), a cadeira de rodas no lugar das pernas e o item no corpo.

const Fita := preload("res://estudos/direcao/fita.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")
const Cortar := preload("res://estudos/direcao/cavaleiro/cortar.gd")

## Onde cada item fica (04, a arma ou o amuleto).
const OSSO_DO_ITEM := {"martelo": "arm-right", "ancora": "arm-right", "escudo": "arm-left",
	"fole": "torso", "lanterna": "torso", "diapasao": "torso"}


## Um cavaleiro montado. `pecas` = [cabeça, superior, inferior] pelo
## personagem ("male-c"); `opcoes` vai para o Mundo.vestir, e mais:
##   item: o id do itens.csv ("" para nenhum)
##   cadeira: "" (pernas) ou o nome da cadeira ("wheelchair-deluxe")
##   anim, t_anim: a pose
##   so: "cabeca", "superior" ou "inferior" para mostrar só uma parte
static func cavaleiro(pai: Node3D, lugar: int, pos: Vector3, pecas: Array, opcoes := {}) -> Node3D:
	var cor: Color = Fita.JOGADOR[lugar]
	var raiz := Node3D.new()
	raiz.name = "P%d" % (lugar + 1)
	raiz.position = pos
	raiz.rotation.y = float(opcoes.get("yaw", 0.0))
	pai.add_child(raiz)
	var m := Mundo.peca(raiz, "mini-characters/character-" + String(pecas[0]), Vector3.ZERO)
	var esq: Skeleton3D = m.find_child("Skeleton3D", true, false)
	var molde: MeshInstance3D = m.find_child("body-mesh", true, false)
	var xf := molde.transform
	for velho in [m.find_child("head-mesh", true, false), molde]:
		velho.get_parent().remove_child(velho)
		velho.queue_free()
	var cab := Cortar.partes(pecas[0])
	var sup := Cortar.partes(pecas[1])
	var inf := Cortar.partes(pecas[2])
	_parte(esq, "head", cab.cabeca, cab.pele_cabeca, xf)
	_parte(esq, "body-sup", sup.superior, sup.pele, xf)
	_parte(esq, "body-inf", inf.inferior, inf.pele, xf)
	# só uma parte (a prancha das peças)
	var so := String(opcoes.get("so", ""))
	if so != "":
		for nome in {"cabeca": ["body-sup", "body-inf"], "superior": ["head", "body-inf"], "inferior": ["head", "body-sup"]}[so]:
			esq.get_node(nome).visible = false
	var cadeira := String(opcoes.get("cadeira", ""))
	var anim := String(opcoes.get("anim", "wheelchair-sit" if cadeira != "" else "idle"))
	var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	if ap and ap.has_animation(anim):
		ap.play(anim)
		ap.seek(float(opcoes.get("t_anim", 0.3)), true)
		ap.pause()
	Mundo.vestir(m, cor, opcoes)
	if cadeira != "":
		var c := Mundo.peca(raiz, "mini-characters/" + cadeira, Vector3.ZERO)
		Mundo.contornar(c, cor, 0.010, 1.2)
	var item := String(opcoes.get("item", ""))
	if item != "":
		por_item(esq, item, cor)
	if opcoes.get("anel", true):
		Mundo.anel(raiz, cor, lugar)
	raiz.set_meta("modelo", m)
	return raiz


static func _parte(esq: Skeleton3D, nome: String, malha: Mesh, pele: Skin, xf: Transform3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.mesh = malha
	mi.skin = pele
	mi.transform = xf
	esq.add_child(mi)
	mi.skeleton = mi.get_path_to(esq)


# ------------------------------------------------------------- os itens --
## O item preso ao osso dele, com o contorno na cor do dono. A pose já está
## aplicada quando ele entra: o item é posto em pé no espaço do cavaleiro (o
## cabo para cima, saindo do punho; o escudo de frente; o medalhão no peito)
## e só então preso ao osso, para acompanhar a animação dali em diante.
## Medidas nas unidades do personagem (0,79 de altura).
static func por_item(esq: Skeleton3D, item: String, cor: Color) -> Node3D:
	var presa := BoneAttachment3D.new()
	presa.bone_name = OSSO_DO_ITEM[item]
	esq.add_child(presa)
	esq.force_update_all_bone_transforms()
	var pose := esq.get_bone_global_pose(esq.find_bone(presa.bone_name))
	var punho := mao(esq, presa.bone_name)
	var lado := -1.0 if presa.bone_name == "arm-right" else 1.0
	var n: Node3D
	var alvo: Transform3D
	match item:
		"martelo":
			n = Mundo.peca(presa, "survival-kit/tool-hammer", Vector3.ZERO, 0.0, 1.0)
			alvo = Transform3D(Basis(Vector3.BACK, lado * deg_to_rad(-12)).scaled(Vector3.ONE * 1.8), punho + Vector3(0, -0.07, 0.02))
		"ancora":
			n = _malha(presa, ancora())
			# empunhada pela haste, as unhas para cima, como arma
			alvo = Transform3D(Basis(Vector3.BACK, PI + lado * deg_to_rad(-12)).scaled(Vector3.ONE * 2.0), punho + Vector3(0, 0.07, 0.03))
		"escudo":
			n = Mundo.peca(presa, "mini-dungeon/shield-round", Vector3.ZERO, 0.0, 1.0)
			alvo = Transform3D(Basis().scaled(Vector3.ONE * 0.5), punho + Vector3(0, 0.0, 0.07))
		_:
			n = _malha(presa, medalhao(item))
			var torso := esq.get_bone_global_pose(esq.find_bone("torso"))
			alvo = Transform3D(Basis().scaled(Vector3.ONE * 2.2), torso.origin + Vector3(0, 0.15, 0.135))
	n.transform = pose.affine_inverse() * alvo
	Mundo.contornar(n, cor, 0.008, 1.4)
	if n is MeshInstance3D:
		Mundo.contornar(presa, cor, 0.008, 1.4)
	return n


## O punho, no espaço do esqueleto e na pose de agora: o meio do quarto mais
## distante do ombro entre os vértices do tronco que o osso do braço move. O
## eixo dos ossos dos Mini Characters não corre ao longo do braço, por isso
## o punho sai da malha, não do osso.
static func mao(esq: Skeleton3D, osso: String) -> Vector3:
	var mi: MeshInstance3D = esq.get_node("body-sup")
	var skin: Skin = mi.skin
	var b := esq.find_bone(osso)
	var binds := {}
	for i in skin.get_bind_count():
		var bb := skin.get_bind_bone(i)
		if bb == b or (bb < 0 and String(skin.get_bind_name(i)) == osso):
			binds[i] = true
	var arr := mi.mesh.surface_get_arrays(0)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ossos: PackedInt32Array = arr[Mesh.ARRAY_BONES]
	var pesos: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
	var k := ossos.size() / vs.size()
	var pose := esq.get_bone_global_pose(b)
	var pts := []
	for v in vs.size():
		var melhor := 0
		for j in k:
			if pesos[v * k + j] > pesos[v * k + melhor]:
				melhor = j
		var bi := ossos[v * k + melhor]
		if binds.has(bi) and pesos[v * k + melhor] > 0.5:
			pts.append(pose * skin.get_bind_pose(bi) * vs[v])
	if pts.is_empty():
		return pose.origin
	pts.sort_custom(func(a, c): return a.distance_squared_to(pose.origin) > c.distance_squared_to(pose.origin))
	var n := maxi(1, pts.size() / 4)
	var soma := Vector3.ZERO
	for i in n:
		soma += pts[i]
	return soma / n


static func _malha(pai: Node3D, malha: Mesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	pai.add_child(mi)
	return mi


## O metal do item: a cor sai do papel "objeto" do recolorir, metallic 0,2.
static func metal(base: Color, rugoso := 0.62) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Fita.graduar(base, "objeto")
	m.metallic = 0.2
	m.roughness = rugoso
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return m


## Junta primitivas numa ArrayMesh só, com normais chapadas por face.
static func juntar(partes_: Array, mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in partes_:
		var malha: Mesh = p[0]
		var xf: Transform3D = p[1]
		st.append_from(malha, 0, xf)
	st.deindex()
	st.generate_normals()
	st.set_material(mat)
	return st.commit()


## A âncora (arma, mão direita): a haste, o cepo, o anel e os dois braços
## curvos com as unhas. 0,17 de altura, nas unidades do personagem.
static func ancora() -> ArrayMesh:
	var p := []
	var haste := BoxMesh.new()
	haste.size = Vector3(0.018, 0.15, 0.018)
	p.append([haste, Transform3D(Basis(), Vector3(0, 0.0, 0))])
	var cepo := BoxMesh.new()
	cepo.size = Vector3(0.09, 0.016, 0.016)
	p.append([cepo, Transform3D(Basis(), Vector3(0, 0.055, 0))])
	var anel := TorusMesh.new()
	anel.inner_radius = 0.012
	anel.outer_radius = 0.022
	anel.rings = 8
	anel.ring_segments = 4
	p.append([anel, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.092, 0))])
	# os braços: cinco gomos num arco de 130°, de cada lado
	for lado in [-1.0, 1.0]:
		for i in 5:
			var a := deg_to_rad(-90.0 + lado * (10.0 + i * 15.0))
			var c := Vector3(cos(a) * 0.06, -0.035 + sin(a) * 0.06 + 0.06 * 0.0, 0)
			var g := BoxMesh.new()
			g.size = Vector3(0.022, 0.016, 0.016)
			p.append([g, Transform3D(Basis(Vector3.FORWARD, a + PI * 0.5), c)])
		var unha := PrismMesh.new()
		unha.size = Vector3(0.04, 0.035, 0.012)
		var au := deg_to_rad(-90.0 + lado * 78.0)
		p.append([unha, Transform3D(Basis(Vector3.FORWARD, au + PI * 0.5 + lado * 0.6), Vector3(cos(au) * 0.064, -0.035 + sin(au) * 0.064, 0))])
	return juntar(p, metal(Color("#c9ced8"), 0.5))


## O medalhão do amuleto (peito): um disco de 12 cm (0,05 nas unidades do
## personagem) com o emblema em relevo. Fole: o fole de duas tábuas; Lanterna:
## a gaiola com a chama; Diapasão: o garfo de dois dentes.
static func medalhao(item: String) -> ArrayMesh:
	var p := []
	var disco := CylinderMesh.new()
	disco.top_radius = 0.026
	disco.bottom_radius = 0.026
	disco.height = 0.008
	disco.radial_segments = 12
	disco.rings = 1
	p.append([disco, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO)])
	var z := 0.006
	match item:
		"fole":
			var tabua := PrismMesh.new()
			tabua.size = Vector3(0.028, 0.026, 0.006)
			p.append([tabua, Transform3D(Basis(Vector3.FORWARD, PI), Vector3(0, 0.002, z))])
			var bico := BoxMesh.new()
			bico.size = Vector3(0.006, 0.014, 0.006)
			p.append([bico, Transform3D(Basis(), Vector3(0, -0.016, z))])
		"lanterna":
			var gaiola := BoxMesh.new()
			gaiola.size = Vector3(0.018, 0.026, 0.006)
			p.append([gaiola, Transform3D(Basis(), Vector3(0, -0.002, z))])
			var alca := TorusMesh.new()
			alca.inner_radius = 0.004
			alca.outer_radius = 0.007
			alca.rings = 6
			alca.ring_segments = 3
			p.append([alca, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.015, z))])
		"diapasao":
			for lado in [-1.0, 1.0]:
				var dente := BoxMesh.new()
				dente.size = Vector3(0.005, 0.022, 0.006)
				p.append([dente, Transform3D(Basis(), Vector3(lado * 0.007, 0.006, z))])
			var base := BoxMesh.new()
			base.size = Vector3(0.019, 0.005, 0.006)
			p.append([base, Transform3D(Basis(), Vector3(0, -0.006, z))])
			var cabo := BoxMesh.new()
			cabo.size = Vector3(0.005, 0.014, 0.006)
			p.append([cabo, Transform3D(Basis(), Vector3(0, -0.015, z))])
	return juntar(p, metal(Color("#f0cf78"), 0.45))
