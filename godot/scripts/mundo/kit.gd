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
