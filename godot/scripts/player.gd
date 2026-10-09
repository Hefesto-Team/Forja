class_name ForjaPlayer
extends CharacterBody3D
## Um jogador no mundo: o boneco do kit Mini Dungeon (Kenney, CC0) com a roupa
## sem tom no corpo; o dono é o contorno de néon, o anel no chão e a luz, os três
## na cor de luz do lugar, e o "P1" em cima. Anda
## pelo analógico esquerdo do controle do lugar (o d-pad também serve).
##
## O visual é do jogador: o boneco (humano ou orc) e o que ele leva nas mãos,
## escolhidos no lobby. A cor não se escolhe — é a do lugar, a mesma da
## lightbar do controle.

const VELOCIDADE := 4.6
const CORRIDA := 6.8
const ESCALA := 2.0
const CONTORNO_LARGURA := 0.012
const MODELOS := ["character-human", "character-orc"]
const NOME_DO_MODELO := ["humano", "orc"]
## O que o boneco leva: o item da mão direita e o do braço esquerdo (peças do kit).
const ITENS := [
	{"nome": "mãos livres"},
	{"nome": "espada", "direita": "weapon-sword"},
	{"nome": "lança", "direita": "weapon-spear"},
	{"nome": "espada e escudo", "direita": "weapon-sword", "esquerda": "shield-round"},
	{"nome": "lança e escudo", "direita": "weapon-spear", "esquerda": "shield-round"},
	{"nome": "poção", "direita": "potion"},
	{"nome": "chave", "direita": "key"},
]
## Cada lugar nasce com um visual diferente dos outros.
const VISUAL_DO_LUGAR := [[0, 3], [1, 2], [0, 5], [1, 4]]
## Onde cada item senta no osso do braço (espaço do osso, unidades do kit; o
## braço solto aponta para baixo, a frente do boneco é +z): deslocamento,
## rotação em graus e escala. De frente, a espada fica em pé ao lado do corpo,
## a lança apoiada no chão e o escudo de frente no braço esquerdo.
const POSE_DO_ITEM := {
	"weapon-sword": {"pos": Vector3(-0.035, -0.1, 0.05), "rot": Vector3(0, 0, 14), "escala": 0.85},
	"weapon-spear": {"pos": Vector3(-0.03, -0.29, 0.05), "rot": Vector3(0, 0, 4), "escala": 1.0},
	"potion": {"pos": Vector3(-0.01, -0.2, 0.04), "rot": Vector3.ZERO, "escala": 0.5},
	"key": {"pos": Vector3(-0.02, -0.17, 0.05), "rot": Vector3(0, 0, 90), "escala": 0.45},
	"shield-round": {"pos": Vector3(0.03, -0.07, 0.075), "rot": Vector3.ZERO, "escala": 0.9},
}

var lugar := 0
var cor: Color  ## a cor do lugar (Forja.cor_do_lugar), posta em `montar`
var hp := 100.0
var cooldown := 0.0
## false: parado pelo jogo (lobby, transição); a entrada não mexe nele
var controlavel := true:
	set(v):
		controlavel = v
		if luz_de_dono:
			luz_de_dono.visible = v
## true: a sala posiciona e anima o boneco (na viga, caindo na lava); a física
## e a escolha da animação ficam paradas
var preso := false
var modelo: Node3D
var modelo_i := 0
var item_i := 0
var anim: AnimationPlayer
var aro: MeshInstance3D
var luz_de_dono: OmniLight3D  ## a luz do lugar no chão em volta de quem se mexe (só com `controlavel`)
var _energia_do_contorno := 2.4
var etiqueta: Label3D
var _anim_atual := ""
var _yaw := PI
var _gesto := 0.0


func montar(l: int) -> void:
	lugar = l
	cor = Forja.cor_do_lugar(l)
	name = "P%d" % (l + 1)
	visual(VISUAL_DO_LUGAR[l][0], VISUAL_DO_LUGAR[l][1])

	var forma := CollisionShape3D.new()
	var capsula := CapsuleShape3D.new()
	capsula.radius = 0.42
	capsula.height = 1.5
	forma.shape = capsula
	forma.position.y = 0.75
	add_child(forma)

	aro = MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.52
	t.outer_radius = 0.64
	t.rings = 32
	aro.mesh = t
	aro.material_override = Tema.neon(cor, 1.5, l)
	aro.scale = Vector3(1, 0.25, 1)
	aro.position.y = 0.04
	add_child(aro)

	luz_de_dono = OmniLight3D.new()
	luz_de_dono.light_color = cor
	luz_de_dono.light_energy = 0.9
	luz_de_dono.omni_range = 3.4
	luz_de_dono.shadow_enabled = false
	luz_de_dono.position.y = 0.6
	luz_de_dono.visible = controlavel
	add_child(luz_de_dono)

	etiqueta = Label3D.new()
	etiqueta.text = "P%d" % (l + 1)
	etiqueta.font = Tema.bungee()
	etiqueta.font_size = 72
	etiqueta.pixel_size = 0.0036
	etiqueta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	etiqueta.no_depth_test = true
	etiqueta.modulate = Tema.tom_para_a_borda(cor)
	etiqueta.outline_size = 16
	etiqueta.outline_modulate = Color(Tema.FITA, 0.9)
	etiqueta.position.y = 1.95
	add_child(etiqueta)
	_animar("idle")


## Troca o boneco e o que ele leva. A animação recomeça do "parado".
func visual(m: int, item: int) -> void:
	var trocou_modelo := modelo == null or wrapi(m, 0, MODELOS.size()) != modelo_i
	modelo_i = wrapi(m, 0, MODELOS.size())
	item_i = wrapi(item, 0, ITENS.size())
	if trocou_modelo:
		if modelo:
			_soltar_contorno(modelo)
			modelo.queue_free()
		modelo = load("res://assets/kenney/%s.glb" % MODELOS[modelo_i]).instantiate()
		modelo.scale = Vector3.ONE * ESCALA
		add_child(modelo)
		anim = modelo.find_child("AnimationPlayer", true, false)
		for nome in ["idle", "walk", "sprint"]:
			if anim and anim.has_animation(nome):
				anim.get_animation(nome).loop_mode = Animation.LOOP_LINEAR
		_anim_atual = ""
		_animar("idle")
	_segurar()
	contornar(_energia_do_contorno)


func descricao_do_visual() -> String:
	return "%s · %s" % [NOME_DO_MODELO[modelo_i], ITENS[item_i].nome]


## O contorno de néon do lugar em todas as superfícies do boneco e do que ele leva
## (`next_pass`, o casco que cresce pela normal suavizada): 2,4 no jogo, 1,6 na
## montagem. Chamar de novo troca a energia.
func contornar(energia: float) -> void:
	_energia_do_contorno = energia
	if modelo == null:
		return
	_contornar_em(modelo)


func _contornar_em(n: Node) -> void:
	if n.is_queued_for_deletion():
		return
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			_suavizar(mi)
			for s in mi.mesh.get_surface_count():
				var base: Material = mi.get_surface_override_material(s)
				if base == null:
					base = mi.mesh.surface_get_material(s)
				if base == null:
					continue
				var m: Material = base.duplicate()
				m.next_pass = Tema.contorno(cor, CONTORNO_LARGURA, _energia_do_contorno, lugar)
				mi.set_surface_override_material(s, m)
	for filho in n.get_children():
		_contornar_em(filho)


## Devolve as superfícies ao material do kit antes de o nó sair: um material
## duplicado com `next_pass` que morre na fila de deleção deixa o servidor de
## desenho pedindo um material nulo ("Parameter material is null") no quadro em
## que outro boneco nasce. Chamar antes de todo `queue_free` de quem tem contorno.
func _soltar_contorno(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				mi.set_surface_override_material(s, null)
	for filho in n.get_children():
		_soltar_contorno(filho)


## A normal suavizada (a soma das normais dos vértices no mesmo ponto) gravada no
## TANGENT: os blocos do kit têm a normal partida em cada face, e sem isto o casco
## do contorno abriria nos cantos. Uma vez por malha (o resultado fica em cache).
static var _malhas_suaves := {}


static func _suavizar(mi: MeshInstance3D) -> void:
	var original := mi.mesh as ArrayMesh
	if original == null or _malhas_suaves.values().has(original):
		return
	if _malhas_suaves.has(original):
		mi.mesh = _malhas_suaves[original]
		return
	var nova := ArrayMesh.new()
	for s in original.get_surface_count():
		var arr: Array = original.surface_get_arrays(s)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		if ns.size() == vs.size():
			var soma := {}
			for i in vs.size():
				var k := vs[i].snapped(Vector3.ONE * 0.0005)
				soma[k] = soma.get(k, Vector3.ZERO) + ns[i]
			var tg := PackedFloat32Array()
			tg.resize(vs.size() * 4)
			for i in vs.size():
				var n: Vector3 = soma[vs[i].snapped(Vector3.ONE * 0.0005)]
				n = n.normalized() if n.length() > 0.0001 else ns[i]
				tg[i * 4] = n.x
				tg[i * 4 + 1] = n.y
				tg[i * 4 + 2] = n.z
				tg[i * 4 + 3] = 1.0
			arr[Mesh.ARRAY_TANGENT] = tg
		var flags: int = original.surface_get_format(s) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		nova.add_surface_from_arrays(original.surface_get_primitive_type(s), arr, [], {}, flags)
		nova.surface_set_material(s, original.surface_get_material(s))
	_malhas_suaves[original] = nova
	mi.mesh = nova


## Prende os itens nos ossos dos braços (a mão direita, o braço esquerdo).
func _segurar() -> void:
	var esqueleto: Skeleton3D = modelo.find_child("Skeleton3D", true, false)
	if esqueleto == null:
		return
	for filho in esqueleto.get_children():
		if filho is BoneAttachment3D:
			_soltar_contorno(filho)
			filho.queue_free()
	var escolha: Dictionary = ITENS[item_i]
	for lado in ["direita", "esquerda"]:
		if not escolha.has(lado):
			continue
		var peca: String = escolha[lado]
		var presa := BoneAttachment3D.new()
		presa.bone_name = "arm-right" if lado == "direita" else "arm-left"
		esqueleto.add_child(presa)
		var item: Node3D = load("res://assets/kenney/%s.glb" % peca).instantiate()
		var pose: Dictionary = POSE_DO_ITEM.get(peca, {})
		item.rotation_degrees = pose.get("rot", Vector3.ZERO)
		item.position = pose.get("pos", Vector3.ZERO)
		item.scale = Vector3.ONE * float(pose.get("escala", 1.0))
		presa.add_child(item)


func _animar(nome: String, velocidade := 1.0) -> void:
	if anim == null or not anim.has_animation(nome):
		return
	if _anim_atual != nome:
		_anim_atual = nome
		anim.play(nome, 0.15)
	anim.speed_scale = velocidade


## A animação de base, pedida pela sala (um gesto em curso tem a vez).
func animar(nome: String, velocidade := 1.0) -> void:
	if _gesto <= 0.0:
		_animar(nome, velocidade)


## Um gesto que roda uma vez (comemorar, levar dano, cair).
func gesto(nome: String, duracao := 1.0) -> void:
	if anim == null or not anim.has_animation(nome):
		return
	_anim_atual = nome
	anim.play(nome, 0.1)
	_gesto = duracao


func _ready() -> void:
	_notification(NOTIFICATION_VISIBILITY_CHANGED)


## Lugar vazio: o boneco some e deixa de ocupar espaço (não trava quem anda).
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		collision_layer = 1 if visible else 0
		collision_mask = 1 if visible else 0
	elif what == NOTIFICATION_PREDELETE and is_instance_valid(modelo):
		_soltar_contorno(modelo)


func olhar_para(alvo: Vector3) -> void:
	var d := alvo - global_position
	if Vector2(d.x, d.z).length() > 0.01:
		_yaw = atan2(d.x, d.z)
		rotation.y = _yaw


func _physics_process(dt: float) -> void:
	if cooldown > 0.0:
		cooldown -= dt
	if _gesto > 0.0:
		_gesto -= dt
	if preso:
		velocity = Vector3.ZERO
		return
	var mv := Forja.mover(lugar) if controlavel else Vector2.ZERO
	var rapido := mv.length() > 0.92
	var v := Vector3(mv.x, 0, mv.y) * (CORRIDA if rapido else VELOCIDADE)
	velocity.x = v.x
	velocity.z = v.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - 18.0 * dt
	move_and_slide()
	if mv.length() > 0.05:
		_yaw = lerp_angle(_yaw, atan2(mv.x, mv.y), minf(1.0, dt * 14.0))
		rotation.y = _yaw
	if _gesto > 0.0:
		return
	if mv.length() > 0.05:
		_animar("sprint" if rapido else "walk", 0.8 + mv.length() * 0.5)
	else:
		_animar("idle")
