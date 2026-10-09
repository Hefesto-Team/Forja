class_name ForjaPlayer
extends CharacterBody3D
## Um jogador no mundo: o boneco do kit Mini Dungeon (Kenney, CC0) com a roupa
## na cor de luz do lugar, um aro no chão da mesma cor e o "P1" em cima. Anda
## pelo analógico esquerdo do controle do lugar (o d-pad também serve).
##
## O visual é do jogador: o boneco (humano ou orc) e o que ele leva nas mãos,
## escolhidos no lobby. A cor não se escolhe — é a do lugar, a mesma da
## lightbar do controle.

const VELOCIDADE := 4.6
const CORRIDA := 6.8
const ESCALA := 2.0
const MODELOS := ["character-human", "character-orc"]
const NOME_DO_MODELO := ["humano", "orc"]
## O intervalo do pio de cada modelo (arte/03), alinhado com MODELOS.
const INTERVALO_DO_MODELO := ["segunda", "quinta_baixo"]
## O item: o índice é o de Itens (G03). "id" é o de docs/jogo/sistemas/itens.csv.
## O corpo leva o item que o _segurar() monta; a regra é a da classe Itens.
const ITENS := [
	{"id": "", "nome": "Mãos livres", "icone": ""},
	{"id": "martelo", "nome": "Martelo", "icone": "item_martelo"},
	{"id": "escudo", "nome": "Escudo", "icone": "item_escudo"},
	{"id": "fole", "nome": "Fole", "icone": "item_fole"},
	{"id": "lanterna", "nome": "Lanterna", "icone": "item_lanterna"},
	{"id": "diapasao", "nome": "Diapasão", "icone": "item_diapasao"},
	{"id": "ancora", "nome": "Âncora", "icone": "item_ancora"},
]
## Cada lugar nasce com um visual diferente dos outros: [boneco, item].
const VISUAL_DO_LUGAR := [[0, 1], [1, 2], [0, 3], [1, 4]]
## O acabamento muda como a luz bate, nunca a cor: o corpo não se tinge
## (arte/04). "livre": false até a coleção (G06). metallic nunca passa de 0,2.
const ACABAMENTOS := [
	{"nome": "Fosco", "rugoso": 0.95, "metal": 0.0},
	{"nome": "Polido", "rugoso": 0.45, "metal": 0.2},
	{"nome": "Riscado", "rugoso": 0.75, "metal": 0.1},
	{"nome": "Dourado", "rugoso": 0.5, "metal": 0.2, "livre": false},
]
## As malhas da Kenney dos itens que as têm (a G10 troca o caminho por Kit.caminho).
const MALHA_DO_ITEM := {
	"martelo": "res://assets/kenney/survival-kit/tool-hammer.glb",
	"escudo": "res://assets/kenney/shield-round.glb",
}
## O emblema em relevo de cada amuleto no disco do medalhão (G03): [tamanho x y, posição x y].
const EMBLEMA := {
	"fole": [[Vector2(0.022, 0.026), Vector2(0, 0.002)], [Vector2(0.006, 0.010), Vector2(0, -0.016)]],
	"lanterna": [[Vector2(0.016, 0.022), Vector2(0, -0.002)], [Vector2(0.012, 0.003), Vector2(0, 0.012)]],
	"diapasao": [[Vector2(0.004, 0.024), Vector2(-0.006, 0.004)], [Vector2(0.004, 0.024), Vector2(0.006, 0.004)],
		[Vector2(0.016, 0.004), Vector2(0, -0.008)], [Vector2(0.004, 0.012), Vector2(0, -0.016)]],
}

var lugar := 0
var cor := Color.WHITE
var hp := 100.0
var cooldown := 0.0
## false: parado pelo jogo (lobby, transição); a entrada não mexe nele
var controlavel := true
## true: a sala posiciona e anima o boneco (na viga, caindo na lava); a física
## e a escolha da animação ficam paradas
var preso := false
var modelo: Node3D
var modelo_i := 0
var item_i := 0
var acabamento_i := 0
var nome := ""
var anim: AnimationPlayer
var aro: MeshInstance3D
var etiqueta: Label3D
var _anim_atual := ""
var _roupas: Array = []  ## [material do corpo, a cor que o _vestir deu], para o acender
var _mats_runa: Array[Material] = []  ## a linha da runa do item, para acender e o encaixe
var _area_runa := 0.0   ## a área de frente das linhas da runa
var _area_item := 0.0   ## a área de frente do item (o AABB das malhas)
var _acesa := 1.0       ## o último acender(k): o item que se troca nasce com a mesma luz
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
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = cor
	m.emission_enabled = true
	m.emission = cor
	m.emission_energy_multiplier = 1.4
	aro.material_override = m
	aro.scale = Vector3(1, 0.25, 1)
	aro.position.y = 0.04
	add_child(aro)

	etiqueta = Label3D.new()
	etiqueta.text = "P%d" % (l + 1)
	etiqueta.font = Tema.fonte(700)
	etiqueta.font_size = 72
	etiqueta.pixel_size = 0.0036
	etiqueta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	etiqueta.no_depth_test = true
	etiqueta.modulate = Tema.tom_para_a_borda(cor)
	etiqueta.outline_size = 16
	etiqueta.outline_modulate = Color(Tema.CASA, 0.9)
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
			modelo.queue_free()
		modelo = load("res://assets/kenney/%s.glb" % MODELOS[modelo_i]).instantiate()
		modelo.scale = Vector3.ONE * ESCALA
		add_child(modelo)
		_roupas.clear()
		anim = modelo.find_child("AnimationPlayer", true, false)
		for nome in ["idle", "walk", "sprint"]:
			if anim and anim.has_animation(nome):
				anim.get_animation(nome).loop_mode = Animation.LOOP_LINEAR
		_vestir(modelo)
		_anim_atual = ""
		_animar("idle")
	_segurar()
	_aplicar_acabamento()


## Os índices de ACABAMENTOS que já são do jogador ("livre" ausente ou true; a
## G06 soma a coleção).
static func acabamentos_disponiveis() -> Array:
	var v: Array = []
	for i in ACABAMENTOS.size():
		if bool(ACABAMENTOS[i].get("livre", true)):
			v.append(i)
	return v


## O que se guarda do cavaleiro (Opcoes.cavaleiro e o registro): o boneco, o
## item (pelo id), o nome e o acabamento.
func cavaleiro() -> Dictionary:
	return {"boneco": modelo_i, "item": ITENS[item_i].id, "nome": nome, "acabamento": acabamento_i}


## O inverso de cavaleiro(): acha o item pelo id e veste o corpo.
func vestir(c: Dictionary) -> void:
	var item := 0
	for i in ITENS.size():
		if ITENS[i].id == str(c.get("item", "")):
			item = i
	nome = str(c.get("nome", ""))
	acabamento_i = clampi(int(c.get("acabamento", 0)), 0, ACABAMENTOS.size() - 1)
	visual(int(c.get("boneco", 0)), item)


## O acabamento nos materiais do corpo: só a rugosidade e o metal, nunca o
## albedo. A G08 escreve o mesmo nos ShaderMaterial de _mats_corpo.
func _aplicar_acabamento() -> void:
	var a: Dictionary = ACABAMENTOS[clampi(acabamento_i, 0, ACABAMENTOS.size() - 1)]
	for par in _roupas:
		var m: StandardMaterial3D = par[0]
		m.roughness = float(a.rugoso)
		m.metallic = float(a.metal)


func descricao_do_visual() -> String:
	return "%s · %s" % [NOME_DO_MODELO[modelo_i], ITENS[item_i].nome]


## Prende o item escolhido num BoneAttachment3D "Item" (G03): o Martelo na mão
## direita, a Âncora na mão direita, o Escudo no braço esquerdo, os três amuletos
## num medalhão no peito. Apaga só o "Item" anterior. A runa é o acento do
## item, no néon do dono.
func _segurar() -> void:
	var esqueleto: Skeleton3D = modelo.find_child("Skeleton3D", true, false)
	if esqueleto == null:
		return
	var velho := esqueleto.find_child("Item", false, false)
	if velho:
		esqueleto.remove_child(velho)
		velho.queue_free()
	_mats_runa.clear()
	_area_runa = 0.0
	_area_item = 0.0
	var id := String(ITENS[item_i].id)
	if id == "":
		return
	var presa := BoneAttachment3D.new()
	presa.name = "Item"
	presa.bone_name = "torso" if id in EMBLEMA else ("arm-left" if id == "escudo" else "arm-right")
	esqueleto.add_child(presa)
	match id:
		"martelo":
			var m := _malha_do_item(presa, id, Vector3(-0.01, -0.13, 0.0), Vector3(60, 0, 0), 2.3)
			var c := _caixa_em(m, m)
			var h := c.size.y
			_medir_o_item(presa)
			_runa(m, Vector3(0.002, 0.25 * h, 0.8 * c.size.z),
				Vector3(c.end.x + 0.001, c.end.y - 0.125 * h, c.position.z + c.size.z * 0.5), 0.0, 0)
		"escudo":
			var m := _malha_do_item(presa, id, Vector3(0.03, -0.07, 0.075), Vector3.ZERO, 0.9)
			var c := _caixa_em(m, m)
			var r := maxf(c.size.x, c.size.y) * 0.5
			var centro := Vector2(c.position.x + c.size.x * 0.5, c.position.y + c.size.y * 0.5)
			_medir_o_item(presa)
			# o aro: um octógono regular de 8 caixas, de vértice a 0,975 r do centro
			var apotema := 0.975 * r * cos(deg_to_rad(22.5))
			for i in 8:
				var giro := deg_to_rad(45.0 * i)
				var dir := Vector2.from_angle(giro + PI * 0.5)
				_runa(m, Vector3(0.746 * r, 0.05 * r, 0.004),
					Vector3(centro.x + dir.x * apotema, centro.y + dir.y * apotema, c.end.z + 0.002), giro)
		"ancora":
			var raiz := Node3D.new()
			raiz.position = Vector3(-0.01, -0.13, 0.0)
			raiz.rotation_degrees = Vector3(60, 0, 0)
			presa.add_child(raiz)
			var metal := Kit.material(Itens.METAL, 0.0, 0.55)
			metal.metallic = 0.2
			Kit.caixa(raiz, Vector3(0.025, 0.20, 0.025), Vector3(0, 0.10, 0), metal)
			Kit.caixa(raiz, Vector3(0.06, 0.02, 0.02), Vector3(0, 0.21, 0), metal)
			Kit.caixa(raiz, Vector3(0.10, 0.02, 0.02), Vector3(0, 0.17, 0), metal)
			var pontas: Array[Vector3] = []
			for lado in [-1.0, 1.0]:
				var braco := Kit.caixa(raiz, Vector3(0.07, 0.02, 0.02), Vector3(lado * 0.04, 0.015, 0), metal)
				braco.rotation.z = lado * 0.6
				pontas.append(Vector3(lado * (0.04 + 0.035 * cos(0.6)), 0.015 + 0.035 * sin(0.6), 0.0))
			_medir_o_item(presa)
			for ponta in pontas:
				_runa(raiz, Vector3(0.02, 0.02, 0.02), ponta)
		_:
			var rest := esqueleto.get_bone_global_rest(esqueleto.find_bone("torso"))
			var raiz := Node3D.new()
			raiz.transform = Transform3D(rest.basis.inverse(), rest.affine_inverse() * Vector3(0, 0.28, 0.105))
			presa.add_child(raiz)
			var disco := MeshInstance3D.new()
			var cil := CylinderMesh.new()
			cil.top_radius = 0.03
			cil.bottom_radius = 0.03
			cil.height = 0.008
			cil.radial_segments = 8
			cil.rings = 1
			disco.mesh = cil
			disco.material_override = Kit.material(Itens.CERAMICA, 0.0, 0.35)
			disco.rotation_degrees = Vector3(90, 0, 0)
			raiz.add_child(disco)
			var latao := Kit.material(Itens.LATAO, 0.0, 0.5)
			latao.metallic = 0.2
			for par in EMBLEMA[id]:
				Kit.caixa(raiz, Vector3(par[0].x, par[0].y, 0.004), Vector3(par[1].x, par[1].y, 0.006), latao)
			_medir_o_item(presa)
			# o quadro em volta do emblema: quatro linhas de 0,002, um quadrado de 0,030 de lado
			for lado in [-1.0, 1.0]:
				_runa(raiz, Vector3(0.030, 0.002, 0.004), Vector3(0, lado * 0.014, 0.006))
				_runa(raiz, Vector3(0.002, 0.030, 0.004), Vector3(lado * 0.014, 0, 0.006))


## A malha da Kenney do item, presa e com o material do jogo (rugosidade 0,55 e
## metal 0,2 no máximo: arte/02, a arma em metal batido).
func _malha_do_item(presa: Node3D, id: String, pos: Vector3, rot_graus: Vector3, escala: float) -> Node3D:
	var item: Node3D = load(MALHA_DO_ITEM[id]).instantiate()
	item.position = pos
	item.rotation_degrees = rot_graus
	item.scale = Vector3.ONE * escala
	presa.add_child(item)
	var malhas: Array = item.find_children("*", "MeshInstance3D", true, false)
	if item is MeshInstance3D:
		malhas.append(item)
	for n in malhas:
		var mi: MeshInstance3D = n
		for s in mi.mesh.get_surface_count():
			var base := mi.mesh.surface_get_material(s)
			if base is StandardMaterial3D:
				var peca: StandardMaterial3D = base.duplicate()
				peca.roughness = 0.55
				peca.metallic = 0.2
				mi.set_surface_override_material(s, peca)
	return item


## O AABB das malhas de `no` (e dele mesmo) no espaço de `ate`, só pelas
## transformações locais: o jogador pode ainda não estar na árvore.
static func _caixa_em(no: Node3D, ate: Node3D) -> AABB:
	var uniao := AABB()
	var primeiro := true
	var lista: Array = no.find_children("*", "MeshInstance3D", true, false)
	if no is MeshInstance3D:
		lista.append(no)
	for n in lista:
		var mi: MeshInstance3D = n
		var t := Transform3D.IDENTITY
		var c: Node = mi
		while c != null and c != ate:
			t = (c as Node3D).transform * t
			c = c.get_parent()
		var a: AABB = t * mi.get_aabb()
		uniao = a if primeiro else uniao.merge(a)
		primeiro = false
	return uniao


## A área de frente do item (x × y do AABB das malhas, no espaço do "Item").
func _medir_o_item(presa: Node3D) -> void:
	var c := _caixa_em(presa, presa)
	_area_item = c.size.x * c.size.y


## A runa: o vão em Tema.JANELA (1,5 vez a linha) 0,001 atrás e a linha no néon
## do dono a 1,6. `eixo` é a normal da face (0 x, 1 y, 2 z); `giro_z` gira as
## duas caixas em z (o aro do escudo).
func _runa(pai: Node3D, tamanho: Vector3, pos: Vector3, giro_z := 0.0, eixo := 2) -> void:
	var normal := Vector3.ZERO
	normal[eixo] = 1.0
	var vao := tamanho * 1.5
	vao[eixo] = 0.001
	var fundo := Kit.caixa(pai, vao, pos - normal * 0.001, Kit.material(Tema.JANELA, 0.0, 0.9))
	var mat := Kit.material(Tema.JOGADOR[lugar], 1.6)
	mat.emission_energy_multiplier = 1.6 * _acesa
	var linha := Kit.caixa(pai, tamanho, pos, mat)
	fundo.rotation.z = giro_z
	linha.rotation.z = giro_z
	_mats_runa.append(mat)
	_area_runa += tamanho.x * tamanho.y


## A roupa na cor do lugar: o corpo do boneco multiplicado pela cor (a cabeça fica).
func _vestir(n: Node) -> void:
	for filho in n.get_children():
		if filho is MeshInstance3D and String(filho.name).begins_with("body"):
			var mi: MeshInstance3D = filho
			for s in mi.mesh.get_surface_count():
				var base := mi.mesh.surface_get_material(s)
				if base is StandardMaterial3D:
					var roupa: StandardMaterial3D = base.duplicate()
					roupa.albedo_color = cor.lerp(Color.WHITE, 0.25)
					mi.set_surface_override_material(s, roupa)
					_roupas.append([roupa, roupa.albedo_color])
		_vestir(filho)


## A armadura apagada (0: o corpo em Tema.GRAFITE, sem o anel) ou acesa (1:
## como o _vestir deixou). A G08 mantém este contrato no shader novo.
func acender(k: float) -> void:
	k = clampf(k, 0.0, 1.0)
	for par in _roupas:
		var m: StandardMaterial3D = par[0]
		m.albedo_color = Tema.GRAFITE.lerp(par[1], k)
	_acesa = k
	for m in _mats_runa:
		(m as StandardMaterial3D).emission_energy_multiplier = 1.6 * k
	if aro:
		aro.visible = k >= 0.5


## Mostra ou esconde a cabeça (a malha "head-mesh" do boneco).
func cabeca(visivel: bool) -> void:
	var c := modelo.find_child("head-mesh", true, false) if modelo else null
	if c is Node3D:
		c.visible = visivel


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
