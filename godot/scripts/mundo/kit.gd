class_name Kit
extends RefCounted
## As peças do kit Mini Dungeon (Kenney, CC0), na escala do jogo.

const K := 2.0
const CAMINHO := "res://assets/kenney/%s.glb"

static var _cenas := {}


static func peca(pai: Node, nome: String, pos: Vector3, rot_y := 0.0, escala := K) -> Node3D:
	if not _cenas.has(nome):
		_cenas[nome] = load(CAMINHO % nome)
	var cena: PackedScene = _cenas[nome]
	var n: Node3D = cena.instantiate() if cena else Node3D.new()
	n.position = pos
	n.rotation.y = rot_y
	n.scale = Vector3.ONE * escala
	pai.add_child(n)
	return n


static func solido(pai: Node, centro: Vector3, tamanho: Vector3) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = tamanho
	forma.shape = caixa
	corpo.position = centro
	corpo.add_child(forma)
	pai.add_child(corpo)
	return corpo


static func material(cor: Color, brilho := 0.0, rugoso := 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = rugoso
	if brilho > 0.0:
		m.emission_enabled = true
		m.emission = cor
		m.emission_energy_multiplier = brilho
	return m


## Um material chapado (sem luz): o que é interface dentro do mundo (a mira,
## a régua do equilíbrio). `por_cima`: desenha na frente de tudo.
static func chapado(cor: Color, por_cima := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = cor
	if cor.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if por_cima:
		m.no_depth_test = true
		m.render_priority = 1
	return m


static func caixa(pai: Node, tamanho: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tamanho
	mi.mesh = b
	mi.position = pos
	mi.material_override = mat
	pai.add_child(mi)
	return mi


## Um cilindro em pé (`raio_topo` < 0: reto; senão, um tronco de cone).
static func cilindro(pai: Node, raio: float, altura: float, pos: Vector3, mat: Material, raio_topo := -1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.bottom_radius = raio
	c.top_radius = raio if raio_topo < 0.0 else raio_topo
	c.height = altura
	c.radial_segments = 20
	c.rings = 1
	mi.mesh = c
	mi.position = pos
	mi.material_override = mat
	pai.add_child(mi)
	return mi


static func esfera(pai: Node, raio: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = raio
	s.height = raio * 2.0
	s.radial_segments = 20
	s.rings = 10
	mi.mesh = s
	mi.position = pos
	mi.material_override = mat
	pai.add_child(mi)
	return mi


## O martelo do Hefesto: cabo de madeira e cabeça de ferro com a face clara,
## a pega na origem e a cabeça para cima (+y).
static func martelo(pai: Node, escala := 1.0) -> Node3D:
	var m := Node3D.new()
	m.scale = Vector3.ONE * escala
	pai.add_child(m)
	cilindro(m, 0.028, 0.52, Vector3(0, 0.22, 0), material(Color("#8a5a33"), 0.0, 0.8))
	caixa(m, Vector3(0.3, 0.13, 0.14), Vector3(0, 0.5, 0), material(Color("#5b6275"), 0.0, 0.35))
	caixa(m, Vector3(0.05, 0.15, 0.16), Vector3(0.165, 0.5, 0), material(Color("#d7d9e3"), 0.0, 0.3))
	return m


## Uma arena retangular: chão de lajotas e meia parede em volta.
static func arena(pai: Node, meia_largura: int, meia_fundura: int) -> void:
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 11
	for i in range(-meia_largura, meia_largura + 1):
		for j in range(-meia_fundura, meia_fundura + 1):
			var detalhe := sorteio.randf() < 0.15
			peca(pai, "floor-detail" if detalhe else "floor", Vector3(i * K, 0, j * K), sorteio.randi_range(0, 3) * PI * 0.5)
	var xw := (meia_largura + 1) * K
	var zw := (meia_fundura + 1) * K
	for i in range(-meia_largura - 1, meia_largura + 2):
		peca(pai, "wall", Vector3(i * K, 0, -zw))
		peca(pai, "wall-half", Vector3(i * K, 0, zw))
	for j in range(-meia_fundura, meia_fundura + 1):
		peca(pai, "wall", Vector3(-xw, 0, j * K))
		peca(pai, "wall", Vector3(xw, 0, j * K))
	solido(pai, Vector3(0, -0.5, 0), Vector3(60, 1, 60))
	solido(pai, Vector3(0, 1.1, -zw), Vector3(xw * 2 + 2, 2.2, 2))
	solido(pai, Vector3(0, 1.0, zw), Vector3(xw * 2 + 2, 2.0, 2))
	solido(pai, Vector3(-xw, 1.1, 0), Vector3(2, 2.2, zw * 2))
	solido(pai, Vector3(xw, 1.1, 0), Vector3(2, 2.2, zw * 2))


## A bigorna do logo do Hefesto, pequena: tampo claro com o chifre, cintura
## roxa, base azul-ardósia. A de cada jogador nas salas da forja.
static func bigorna(pai: Node, pos: Vector3, escala := 0.55) -> Node3D:
	var b := Node3D.new()
	b.position = pos
	b.scale = Vector3.ONE * escala
	pai.add_child(b)
	var base := CSGBox3D.new()
	base.size = Vector3(1.5, 0.45, 1.0)
	base.position.y = 0.225
	base.material = material(Color("#6272a4"))
	b.add_child(base)
	var cintura := CSGBox3D.new()
	cintura.size = Vector3(0.8, 0.45, 0.62)
	cintura.position.y = 0.675
	cintura.material = material(Tema.VIOLETA, 0.0, 0.5)
	b.add_child(cintura)
	var tampo := CSGBox3D.new()
	tampo.size = Vector3(1.9, 0.38, 0.8)
	tampo.position = Vector3(-0.1, 1.09, 0)
	tampo.material = material(Color("#e9e7f2"), 0.0, 0.35)
	b.add_child(tampo)
	var chifre := CSGCylinder3D.new()
	chifre.cone = true
	chifre.radius = 0.19
	chifre.height = 0.9
	chifre.sides = 16
	chifre.rotation.z = -PI * 0.5
	chifre.position = Vector3(1.28, 1.09, 0)
	chifre.material = material(Color("#e9e7f2"), 0.0, 0.35)
	b.add_child(chifre)
	return b
