class_name Kit
extends RefCounted

const K := 2.0
const CAMINHO := "res://assets/kenney/%s.glb"
const PACOTE_PADRAO := "mini-dungeon"
const ESCALA_DO_PACOTE := {
	"castle-kit": 1.4, "survival-kit": 1.4, "factory-kit": 0.5, "building-kit": 0.35,
	"pirate-kit": 0.4, "cube-pets": 0.4, "blaster-kit": 0.3, "modular-dungeon-kit": 0.25,
	"modular-cave-kit": 0.25, "modular-space-kit": 0.25,
}

static var _cenas := {}


static func caminho(nome: String) -> String:
	if "/" in nome:
		return CAMINHO % nome
	return CAMINHO % (PACOTE_PADRAO + "/" + nome)


static func escala_do_pacote(nome: String) -> float:
	if not "/" in nome:
		return 1.0
	return float(ESCALA_DO_PACOTE.get(nome.get_slice("/", 0), 1.0))


static func peca(pai: Node, nome: String, pos: Vector3, rot_y := 0.0, escala := K) -> Node3D:
	if not _cenas.has(nome):
		_cenas[nome] = load(caminho(nome))
	var cena: PackedScene = _cenas[nome]
	var n: Node3D = cena.instantiate() if cena else Node3D.new()
	n.position = pos
	n.rotation.y = rot_y
	n.scale = Vector3.ONE * escala * escala_do_pacote(nome)
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


static func material(cor: Color, brilho := 0.0, rugoso := 0.8, dono: Variant = "mundo") -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = rugoso
	if brilho > 0.0:
		Tema.emissivo(m, brilho, dono)
	return m


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


static func cilindro(pai: Node, raio: float, altura: float, pos: Vector3, mat: Material, raio_topo := -1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.bottom_radius = raio
	c.top_radius = raio if raio_topo < 0.0 else raio_topo
	c.height = altura
	c.radial_segments = 8
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
	s.radial_segments = 8
	s.rings = 4
	mi.mesh = s
	mi.position = pos
	mi.material_override = mat
	pai.add_child(mi)
	return mi


static func anel(pai: Node, raio_dentro: float, raio_fora: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = raio_dentro
	t.outer_radius = raio_fora
	t.rings = 8
	t.ring_segments = 6
	mi.mesh = t
	mi.position = pos
	mi.material_override = mat
	pai.add_child(mi)
	return mi


static func anel_do_dono(pai: Node3D, lugar: int) -> Node3D:
	var cor: Color = Tema.JOGADOR[lugar]
	var a := Node3D.new()
	a.name = "Anel"
	a.position.y = 0.03
	pai.add_child(a)
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.57
	t.outer_radius = 0.65
	t.rings = 8
	t.ring_segments = 4
	mi.mesh = t
	mi.scale = Vector3(1, 0.22, 1)
	mi.rotation.y = PI / 8.0
	mi.material_override = Tema.neon(cor, 1.5, lugar)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	a.add_child(mi)
	for i in 5:
		if (int(Forja.LEDS_DO_LUGAR[lugar]) >> i) & 1 == 0:
			continue
		var luz := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.09, 0.02, 0.14)
		luz.mesh = bm
		luz.position = Vector3((i - 2) * 0.16, 0.0, 0.82)
		luz.material_override = Tema.neon(cor, 1.8, lugar)
		luz.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		a.add_child(luz)
	return a


static func martelo(pai: Node, escala := 1.0) -> Node3D:
	var m := Node3D.new()
	m.scale = Vector3.ONE * escala
	pai.add_child(m)
	cilindro(m, 0.028, 0.52, Vector3(0, 0.22, 0), material(Tema.OXIDO_BRILHO, 0.0, 0.8))
	caixa(m, Vector3(0.3, 0.13, 0.14), Vector3(0, 0.5, 0), material(Tema.OXIDO_BRILHO, 0.0, 0.35))
	caixa(m, Vector3(0.05, 0.15, 0.16), Vector3(0.165, 0.5, 0), material(Tema.OXIDO_BRILHO, 0.0, 0.3))
	return m


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


static func bigorna(pai: Node, pos: Vector3, escala := 0.55) -> Node3D:
	var b := Node3D.new()
	b.position = pos
	b.scale = Vector3.ONE * escala
	pai.add_child(b)
	var corpo := MeshInstance3D.new()
	corpo.mesh = MalhaBigorna.malha()
	corpo.scale = Vector3.ONE * 4.2
	b.add_child(corpo)
	return b
