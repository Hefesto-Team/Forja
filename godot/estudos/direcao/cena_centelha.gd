extends RefCounted
## A Centelha na fita: a mesma arena, a mesma câmera e as mesmas raias da sala
## de hoje (godot/scripts/salas/centelha.gd), com os modelos da Kenney
## recoloridos, a luz do estúdio e os néons só nos jogadores.

const Fita := preload("res://estudos/direcao/fita.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")
const RAIAS := [-6.0, -2.0, 2.0, 6.0]
const CAMERA_POS := Vector3(0, 7.2, 12.4)
const CAMERA_OLHAR := Vector3(0, 1.2, -0.2)
## A runa de cada um: o glifo, o quanto o anel já fechou (1 aberto) e o pulso.
const RUNAS := [
	{"glifo": "dpad_left", "anel": 0.82},
	{"glifo": "cross", "anel": 0.55},
	{"glifo": "l2", "anel": 0.9, "fole": 0.48},
	{"glifo": "square", "anel": 1.0, "acerto": true},
]
const POSE := [["attack-melee-right", 0.12], ["idle", 0.6], ["attack-melee-right", 0.02], ["attack-melee-right", 0.3]]


static func bigorna_de(l: int) -> Vector3:
	return Vector3(RAIAS[l] + 0.45, 0.0, 0.3)


static func cavaleiro_de(l: int) -> Vector3:
	return Vector3(RAIAS[l] - 1.05, 0.05, 1.15)


## `apagada` (0 a 1): a Dissonância tira a luz da sala e deixa os jogadores.
static func montar(raiz: Node3D, e, apagada := 0.0) -> void:
	e.olhar(CAMERA_POS, CAMERA_OLHAR, 40.0)
	Mundo.ambiente(raiz, {"ambiente": Color("#2a2738"), "ambiente_energia": lerpf(0.55, 0.18, apagada),
		"nevoa_densidade": 0.016, "nevoa_cor": Color("#15101f"), "glow_intensidade": 0.75})
	_arena(raiz)
	_estudio(raiz, apagada)
	var sol := DirectionalLight3D.new()
	raiz.add_child(sol)
	sol.rotation_degrees = Vector3(-62, -28, 0)
	sol.light_color = Color("#b8b0ff")
	sol.light_energy = lerpf(0.32, 0.08, apagada)
	sol.shadow_enabled = true
	sol.shadow_opacity = 0.75
	sol.shadow_bias = 0.08
	sol.shadow_normal_bias = 2.0
	for l in 4:
		var cor: Color = Fita.JOGADOR[l]
		# a bigorna: o objeto do jogo, num foco de lâmpada (a estação de cada um)
		var b := Mundo.peca(raiz, "survival-kit/workbench-anvil", bigorna_de(l), -PI * 0.5, 3.4)
		var martelo_da_mesa := b.find_child("hammer", true, false)
		if martelo_da_mesa:
			martelo_da_mesa.visible = false
		Mundo.foco(raiz, bigorna_de(l) + Vector3(0, 6.5, 1.2), bigorna_de(l), Fita.TUNGSTENIO,
			lerpf(4.0, 1.2, apagada), 21.0, 12.0, false)
		# o cavaleiro e a luz de dono que pinta o chão em volta dele
		var pos := cavaleiro_de(l)
		var d := bigorna_de(l) - pos
		# virado para a bigorna, mas abrindo para a câmera: o rosto aparece
		var para_camera := CAMERA_POS - pos
		var yaw := lerp_angle(atan2(d.x, d.z), atan2(para_camera.x, para_camera.z), 0.55)
		Mundo.cavaleiro(raiz, l, pos, yaw, POSE[l][0], POSE[l][1], "", {"martelo": true})
		Mundo.luz(raiz, pos + Vector3(0.2, 1.4, 0.9), cor, 0.9, 3.4)
		_runa(raiz, l)
	if apagada < 0.5:
		_faiscas(raiz, bigorna_de(3) + Vector3(0, 0.95, 0), Fita.JOGADOR[3])
	Mundo.neon_sem_sombra(raiz)


static func _arena(raiz: Node3D) -> void:
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 11
	for i in range(-5, 6):
		for j in range(-3, 4):
			var detalhe := sorteio.randf() < 0.15
			Mundo.peca(raiz, "mini-dungeon/floor-detail" if detalhe else "mini-dungeon/floor", Vector3(i * 2.0, 0, j * 2.0),
				sorteio.randi_range(0, 3) * PI * 0.5)
	for i in range(-6, 7):
		Mundo.peca(raiz, "mini-dungeon/wall", Vector3(i * 2.0, 0, -8.0))
		Mundo.peca(raiz, "mini-dungeon/wall-half", Vector3(i * 2.0, 0, 8.0))
	for j in range(-3, 4):
		Mundo.peca(raiz, "mini-dungeon/wall", Vector3(-12.0, 0, j * 2.0))
		Mundo.peca(raiz, "mini-dungeon/wall", Vector3(12.0, 0, j * 2.0))


## O estúdio dentro da forja: o tubo violeta da arquitetura no alto da parede
## do fundo (o único néon que não é de jogador, e que pulsa na batida), as
## caixas de som nos cantos e os cabos no chão.
static func _estudio(raiz: Node3D, apagada: float) -> void:
	var energia := lerpf(1.25, 0.25, apagada)
	for lado in [-1.0, 1.0]:
		Mundo.tubo(raiz, Vector3(7.2, 0.07, 0.07), Vector3(lado * 6.6, 2.32, -6.92), Fita.VIOLETA, energia)
		Mundo.luz(raiz, Vector3(lado * 6.6, 1.9, -6.2), Fita.VIOLETA, lerpf(1.4, 0.3, apagada), 5.5)
	# as caixas de som: dois caixotes da Kenney, um em cima do outro, com o cone
	for lado in [-1.0, 1.0]:
		var x: float = lado * 10.2
		var base := Mundo.peca(raiz, "survival-kit/box-large", Vector3(x, 0, -6.4), lado * -0.35)
		var topo := Mundo.peca(raiz, "survival-kit/box", Vector3(x, 1.35, -6.4), lado * -0.35)
		for alvo in [[base, 0.75, 0.42], [topo, 1.75, 0.26]]:
			var cone := MeshInstance3D.new()
			var t := TorusMesh.new()
			t.inner_radius = alvo[2] * 0.62
			t.outer_radius = alvo[2]
			t.rings = 8
			t.ring_segments = 4
			cone.mesh = t
			cone.material_override = Fita.fosco(Color("#1a1524"), 0.6)
			raiz.add_child(cone)
			cone.position = Vector3(x, alvo[1], -6.4) + Vector3(sin(lado * -0.35), 0, cos(lado * -0.35)) * 0.74
			cone.rotation = Vector3(PI * 0.5, lado * -0.35, 0)
			var miolo := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = alvo[2] * 0.62
			cm.bottom_radius = alvo[2] * 0.2
			cm.height = 0.12
			cm.radial_segments = 8
			miolo.mesh = cm
			miolo.material_override = Fita.fosco(Color("#0a0810"), 0.9)
			cone.add_child(miolo)
			miolo.position.y = -0.04


static func _runa(raiz: Node3D, l: int) -> void:
	var r: Dictionary = RUNAS[l]
	var cor: Color = Fita.JOGADOR[l]
	var no := Node3D.new()
	no.position = bigorna_de(l) + Vector3(0, 2.55, 0)
	raiz.add_child(no)
	var g := Sprite3D.new()
	g.texture = load("res://assets/glifos/%s.png" % r.glifo)
	g.pixel_size = 0.0062
	g.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	g.shaded = false
	g.modulate = Fita.ETIQUETA
	g.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	no.add_child(g)
	# o anel de oito lados que fecha; e o rastro do tamanho cheio, apagado
	for k in 2:
		var a := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = 0.66 if k == 0 else 0.715
		t.outer_radius = 0.76 if k == 0 else 0.735
		t.rings = 8
		t.ring_segments = 4
		a.mesh = t
		a.rotation = Vector3(PI * 0.5, 0, PI / 8.0)
		var s: float = lerpf(0.4, 1.0, float(r.anel)) if k == 0 else 1.0
		a.scale = Vector3.ONE * s
		a.material_override = Fita.neon(cor, 2.1) if k == 0 else Fita.neon(Fita.GRAFITE, 1.0)
		no.add_child(a)
	no.look_at(no.global_position + (CAMERA_POS - no.global_position).normalized(), Vector3.UP)
	if r.has("fole"):
		var f := Node3D.new()
		f.position = Vector3(1.05, -0.7, 0)
		no.add_child(f)
		Mundo.caixa(f, Vector3(0.16, 1.4, 0.04), Vector3(0, 0.7, 0), Fita.neon(Fita.GRAFITE, 1.0))
		Mundo.caixa(f, Vector3(0.24, 1.4 * 0.27, 0.05), Vector3(0, 1.4 * 0.485, 0), Fita.neon(Fita.ETIQUETA, 0.75))
		var v: float = r.fole
		Mundo.caixa(f, Vector3(0.1, v * 1.4, 0.07), Vector3(0, v * 0.7, 0.01), Fita.neon(cor, 2.0))
	if r.get("acerto", false):
		var onda := MeshInstance3D.new()
		var t2 := TorusMesh.new()
		t2.inner_radius = 0.98
		t2.outer_radius = 1.02
		t2.rings = 8
		t2.ring_segments = 4
		onda.mesh = t2
		onda.rotation = Vector3(PI * 0.5, 0, PI / 8.0)
		onda.material_override = Fita.neon(Color(cor, 1.0), 1.1)
		no.add_child(onda)
		g.scale = Vector3.ONE * 1.15


## As faíscas do acerto, na cor de quem acertou (o brilho tem dono).
static func _faiscas(raiz: Node3D, c: Vector3, cor: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 22:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.2, 1.2), rng.randf_range(-0.6, 0.6)).normalized()
		var p := c + d * rng.randf_range(0.2, 1.1)
		var s := MeshInstance3D.new()
		var b := BoxMesh.new()
		var len := rng.randf_range(0.05, 0.16)
		b.size = Vector3(0.035, len, 0.035)
		s.mesh = b
		s.material_override = Fita.neon(cor.lerp(Color.WHITE, 0.35), 2.6)
		raiz.add_child(s)
		s.position = p
		s.look_at(p + d, Vector3.FORWARD if absf(d.y) > 0.99 else Vector3.UP)
		s.rotate_object_local(Vector3.RIGHT, PI * 0.5)
