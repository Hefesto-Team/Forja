class_name Salao
extends Node3D
## O salão da forja: o lugar de onde se sai para cada sala. Paredes de pedra do
## kit Mini Dungeon (Kenney, CC0) com oito portões — um por sala, na ordem do
## percurso, no sentido do relógio —, a bigorna de A Prova no meio e os quatro
## pedestais do lobby na frente.
##
## O kit é pequeno (o bloco de parede tem 1×1,1); tudo sai na escala K.

const K := 2.0

## As salas, na ordem do percurso. `lado`: a parede do portão; `aberta`: a sala
## já existe neste marco (as outras ficam de portão fechado).
const PORTOES := [
	{"id": "centelha", "nome": "A Centelha", "lado": "oeste", "t": 3.0, "aberta": true},
	{"id": "viga", "nome": "A Viga", "lado": "oeste", "t": -3.0, "aberta": true},
	{"id": "molde", "nome": "O Molde", "lado": "norte", "t": -6.0, "aberta": true},
	{"id": "impacto", "nome": "O Impacto", "lado": "norte", "t": -2.0, "aberta": true},
	{"id": "galeria", "nome": "A Galeria", "lado": "norte", "t": 2.0, "aberta": true},
	{"id": "voz", "nome": "A Voz", "lado": "norte", "t": 6.0, "aberta": true},
	{"id": "caminhos", "nome": "Os Caminhos", "lado": "leste", "t": -3.0, "aberta": true},
	{"id": "canto", "nome": "O Canto", "lado": "leste", "t": 3.0, "aberta": true},
]

## A luz do portão: acesa quando a seção foi vencida na noite, apagada a de quadro (arte/02).
const FOCO_ACESO := 3.2
const FOCO_APAGADO := 0.55
const VITRINE_MAX := 18   ## os troféus que a vitrine mostra: os 18 últimos

const X_OESTE := -12.0
const X_LESTE := 12.0
const Z_NORTE := -9.0
const Z_SUL := 9.0

var portoes := {}  ## id -> {no, porta, anim, frente, placa, luzes, aberto}
var pedestais: Array[Vector3] = []
var pedestais_no: Node3D  ## os quatro pedestais do lobby (somem no título)
var luzes_das_bigornas: Array[OmniLight3D] = []  ## a luz quente da bigorna de cada lugar
var _tw_bigorna := [null, null, null, null]
var vitrine_no: Node3D
var trofeus_no: Node3D
var _cores_dos_trofeus: Array[Color] = []   ## o albedo do copo (ou do cubo) de cada troféu da vitrine
var _amb: AudioStreamPlayer3D
var _mat_do_tubo: ShaderMaterial
var bigorna: Node3D
var _cenas := {}
var _tochas: Array[OmniLight3D] = []
var _t := 0.0
var luz_da_forja: OmniLight3D  ## a luz de _bigorna(), fora de _tochas
var pulso := -1.0  ## 0..1: o título e a introdução mandam; -1: tremula como as tochas
var apagado := 0.0  ## 0..1: a Dissonância apaga tochas e forja


func _ready() -> void:
	_chao()
	_paredes()
	for p in PORTOES:
		_portao(p)
	_bigorna()
	_pedestais()
	_enfeites()
	_vitrine()
	mostrar_colecao()
	# o fogo do salão: um laço de 8 s preso à bigorna (só toca com o salão à mostra)
	_amb = Som.laco("amb_salao", self, bigorna.position, 0.0)


func _process(dt: float) -> void:
	_t += dt
	# as tochas tremem, cada uma no seu passo
	for i in _tochas.size():
		var l := _tochas[i]
		l.light_energy = (1.6 + 0.25 * sin(_t * 7.3 + i * 1.7) + 0.15 * sin(_t * 13.1 + i * 0.9)) * (1.0 - apagado)
	if luz_da_forja:
		luz_da_forja.light_energy = ((0.5 + 3.0 * pulso) if pulso >= 0.0 else (1.6 + 0.25 * sin(_t * 7.3))) * (1.0 - apagado)


func peca(nome: String, pos: Vector3, rot_y := 0.0, escala := K) -> Node3D:
	if not _cenas.has(nome):
		_cenas[nome] = load(Kit.caminho(nome))
	var cena: PackedScene = _cenas[nome]
	if cena == null:
		return Node3D.new()
	var n: Node3D = cena.instantiate()
	n.position = pos
	n.rotation.y = rot_y
	n.scale = Vector3.ONE * escala
	add_child(n)
	return n


func _caixa_solida(centro: Vector3, tamanho: Vector3) -> void:
	var corpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = tamanho
	forma.shape = caixa
	corpo.position = centro
	corpo.add_child(forma)
	add_child(corpo)


func _chao() -> void:
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 7
	for i in range(-5, 6):
		for j in range(-4, 5):
			var pos := Vector3(i * K, 0, j * K)
			var detalhe := sorteio.randf() < 0.07
			peca("floor-detail" if detalhe else "floor", pos, sorteio.randi_range(0, 3) * PI * 0.5)
	# o chão sólido
	_caixa_solida(Vector3(0, -0.5, 0), Vector3(40, 1, 40))
	# a passarela: dos pedestais do lobby até o tablado da bigorna
	var passarela := CSGBox3D.new()
	passarela.size = Vector3(2.6, 0.03, 7.4)
	passarela.position = Vector3(0, 0.015, 5.3)
	var pano := StandardMaterial3D.new()
	pano.albedo_color = Color("#3a2f56")
	pano.roughness = 1.0
	passarela.material = pano
	add_child(passarela)
	for lado in [-1.0, 1.0]:
		var friso := CSGBox3D.new()
		friso.size = Vector3(0.08, 0.035, 7.4)
		friso.position = Vector3(lado * 1.3, 0.018, 5.3)
		var rosa := StandardMaterial3D.new()
		rosa.albedo_color = Tema.ROSA
		rosa.emission_enabled = true
		rosa.emission = Tema.ROSA
		rosa.emission_energy_multiplier = 0.9
		friso.material = rosa
		add_child(friso)


func _eh_abertura(lado: String, t: float) -> bool:
	for p in PORTOES:
		if p.lado == lado and absf(p.t - t) < 0.1:
			return true
	return false


func _paredes() -> void:
	# norte: de ponta a ponta
	for i in range(-6, 7):
		var x := i * K
		if not _eh_abertura("norte", x):
			peca("wall", Vector3(x, 0, Z_NORTE))
	# oeste e leste
	for j in range(-4, 5):
		var z := j * K
		if not _eh_abertura("oeste", z):
			peca("wall", Vector3(X_OESTE, 0, z))
		if not _eh_abertura("leste", z):
			peca("wall", Vector3(X_LESTE, 0, z))
	# sul: sem parede à vista (é o lado da câmera, como num diorama); só o sólido
	# os sólidos das paredes
	_caixa_solida(Vector3(0, 1.1, Z_NORTE), Vector3(26, 2.2, 2))
	_caixa_solida(Vector3(X_OESTE, 1.1, 0), Vector3(2, 2.2, 20))
	_caixa_solida(Vector3(X_LESTE, 1.1, 0), Vector3(2, 2.2, 20))
	_caixa_solida(Vector3(0, 1.0, Z_SUL), Vector3(26, 2.0, 2))


func _portao(p: Dictionary) -> void:
	var pos := Vector3.ZERO
	var rot := 0.0
	var frente := Vector3.ZERO  # para dentro do salão
	match p.lado:
		"norte":
			pos = Vector3(p.t, 0, Z_NORTE)
			rot = 0.0
			frente = Vector3(0, 0, 1)
		"oeste":
			pos = Vector3(X_OESTE, 0, p.t)
			rot = PI * 0.5
			frente = Vector3(1, 0, 0)
		"leste":
			pos = Vector3(X_LESTE, 0, p.t)
			rot = -PI * 0.5
			frente = Vector3(-1, 0, 0)
	var moldura := peca("wall-opening", pos, rot)
	var portao := peca("gate", pos + frente * 0.2, rot, K)
	var anim: AnimationPlayer = portao.find_child("AnimationPlayer", true, false)

	# a placa vira a etiqueta do cassete, em 3D: o papel, a tarja na tinta da seção, o nome
	# na caneta, a linha impressa e uma marca por minigame da seção (arte/02)
	var placa := Node3D.new()
	placa.position = pos + frente * 1.15 + Vector3(0, 2.75, 0)
	placa.rotation.y = rot
	add_child(placa)
	var n := Musica.SALA_DA_SECAO.find(str(p.id))
	var papel := Kit.caixa(placa, Vector3(2.9, 0.95, 0.04), Vector3.ZERO, Kit.material(Tema.ETIQUETA_SOMBRA, 0.0, 0.9))
	papel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tarjas: Array = []
	for i in 2:
		var t := Kit.caixa(placa, Vector3(2.9, 0.10, 0.05), Vector3(0, 0.33, 0.01), Kit.material(Tema.tinta_da_secao(n), 0.0, 0.9))
		t.visible = i == 0
		tarjas.append(t)
	var nome := Label3D.new()
	nome.text = Desenho.t(p.nome)
	nome.font = Tema.marcador()
	nome.font_size = 88
	nome.pixel_size = 0.0042
	nome.modulate = Tema.TINTA
	nome.shaded = true
	nome.outline_size = 0
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	nome.position = Vector3(-1.3, -0.03, 0.03)
	placa.add_child(nome)
	var faixas := Label3D.new()
	faixas.font = Tema.vt()
	faixas.font_size = 72
	faixas.pixel_size = 0.0036
	faixas.modulate = Tema.TINTA_SUAVE
	faixas.shaded = true
	faixas.outline_size = 0
	faixas.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	faixas.position = Vector3(-1.3, -0.32, 0.03)
	placa.add_child(faixas)
	var marcas: Array = []
	var minis := Colecao.minigames_da_secao(str(p.id))
	for i in minis.size():
		marcas.append(Kit.caixa(placa, Vector3(0.12, 0.12, 0.01), Vector3(1.25 - 0.18 * i, -0.32, 0.03), Kit.material(Tema.ETIQUETA_SOMBRA, 0.0, 0.9)))
	var foco := SpotLight3D.new()
	foco.position = pos + frente * 5.0 + Vector3(0, 6.5, 0)
	foco.light_color = Tema.TUNGSTENIO
	foco.light_energy = FOCO_APAGADO
	foco.spot_range = 24.0
	foco.spot_angle = 12.0
	foco.shadow_enabled = false
	add_child(foco)
	foco.look_at_from_position(foco.position, pos + frente * 0.6 + Vector3(0, 1.4, 0), Vector3.UP)
	var tubo := Kit.caixa(placa, Vector3(3.1, 0.06, 0.06), Vector3(0, 0.57, 0.01), _material_do_tubo())
	tubo.visible = false

	# as tochas dos dois lados do portão
	var luzes: Array[OmniLight3D] = []
	var lado := frente.cross(Vector3.UP)
	for s in [-1.0, 1.0]:
		var base: Vector3 = pos + frente * 1.0 + lado * s * 1.45 + Vector3(0, 1.55, 0)
		luzes.append(_tocha(base, p.aberta))

	portoes[p.id] = {
		"no": moldura, "porta": portao, "anim": anim, "frente": frente, "pos": pos,
		"placa": placa, "luzes": luzes, "aberta": p.aberta, "aberto": false, "dados": p,
		"n": n, "papel": papel, "tarjas": tarjas, "marcas": marcas, "tubo": tubo, "foco": foco, "faixas": faixas,
		"aceso": false,
	}
	_etiqueta(str(p.id), false)


func _tocha(pos: Vector3, acesa: bool) -> OmniLight3D:
	var cabo := CSGCylinder3D.new()
	cabo.radius = 0.05
	cabo.height = 0.5
	cabo.position = pos + Vector3(0, -0.25, 0)
	var madeira := StandardMaterial3D.new()
	madeira.albedo_color = Color("#8a4b2a")
	cabo.material = madeira
	add_child(cabo)
	var chama := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.1
	esfera.radial_segments = 8
	esfera.rings = 4
	esfera.height = 0.26
	chama.mesh = esfera
	var fogo := StandardMaterial3D.new()
	fogo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fogo.albedo_color = Tema.LARANJA if acesa else Tema.TRILHO
	fogo.emission_enabled = acesa
	fogo.emission = Tema.LARANJA
	fogo.emission_energy_multiplier = 3.0
	chama.material_override = fogo
	chama.position = pos + Vector3(0, 0.08, 0)
	add_child(chama)
	var luz := OmniLight3D.new()
	luz.position = pos + Vector3(0, 0.25, 0)
	luz.light_color = Color("#ffb070")
	luz.omni_range = 5.5
	luz.omni_attenuation = 1.4
	luz.light_energy = 1.6 if acesa else 0.0
	luz.shadow_enabled = false
	add_child(luz)
	if acesa:
		_tochas.append(luz)
	return luz


## A bigorna do logo do Hefesto, em pedra e nas cores dele: tampo claro com o
## chifre, cintura roxa, base azul-ardósia. É o centro de A Prova.
func _bigorna() -> void:
	bigorna = Node3D.new()
	bigorna.position = Vector3(0, 0, -1.0)
	add_child(bigorna)
	var pedra := func(cor: Color, rugoso := 0.8) -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = cor
		m.roughness = rugoso
		return m
	# o tablado redondo
	var tablado := CSGCylinder3D.new()
	tablado.radius = 3.0
	tablado.height = 0.3
	tablado.sides = 8
	tablado.position.y = 0.15
	tablado.material = pedra.call(Color("#7d7aa8"))
	bigorna.add_child(tablado)
	var borda := CSGTorus3D.new()
	borda.inner_radius = 2.95
	borda.outer_radius = 3.12
	borda.sides = 8
	borda.ring_sides = 8
	borda.position.y = 0.3
	var brilho := StandardMaterial3D.new()
	brilho.albedo_color = Tema.ROXO
	brilho.emission_enabled = true
	brilho.emission = Tema.ROXO
	brilho.emission_energy_multiplier = 1.6
	borda.material = brilho
	bigorna.add_child(borda)
	# a base, a cintura, o tampo e o chifre
	var base := CSGBox3D.new()
	base.size = Vector3(1.5, 0.45, 1.0)
	base.position.y = 0.3 + 0.225
	base.material = pedra.call(Color("#6272a4"))
	bigorna.add_child(base)
	var cintura := CSGBox3D.new()
	cintura.size = Vector3(0.8, 0.45, 0.62)
	cintura.position.y = 0.75 + 0.225
	cintura.material = pedra.call(Tema.ROXO, 0.5)
	bigorna.add_child(cintura)
	var tampo := CSGBox3D.new()
	tampo.size = Vector3(1.9, 0.38, 0.8)
	tampo.position = Vector3(-0.1, 1.2 + 0.19, 0)
	tampo.material = pedra.call(Color("#e9e7f2"), 0.35)
	bigorna.add_child(tampo)
	var chifre := CSGCylinder3D.new()
	chifre.cone = true
	chifre.radius = 0.19
	chifre.height = 0.9
	chifre.sides = 8
	chifre.rotation.z = -PI * 0.5
	chifre.position = Vector3(1.28, 1.39, 0)
	chifre.material = pedra.call(Color("#e9e7f2"), 0.35)
	bigorna.add_child(chifre)
	# o fogo da forja: brasa rosa e laranja embaixo da bigorna
	var forja := OmniLight3D.new()
	forja.position = Vector3(0, 0.9, 0.9)
	forja.light_color = Color("#ff8a70")
	forja.light_energy = 2.2
	forja.omni_range = 7.0
	bigorna.add_child(forja)
	luz_da_forja = forja
	var acima := OmniLight3D.new()
	acima.position = Vector3(0, 3.5, 0)
	acima.light_color = Tema.ROSA
	acima.light_energy = 0.8
	acima.omni_range = 6.0
	bigorna.add_child(acima)
	_brasas(bigorna)
	_caixa_solida(Vector3(0, 0.8, -1.0), Vector3(2.2, 1.6, 1.2))


func _brasas(onde: Node3D) -> void:
	var p := GPUParticles3D.new()
	p.amount = 48
	p.lifetime = 2.6
	p.position = Vector3(0, 1.6, 0)
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = 0.8
	m.direction = Vector3(0, 1, 0)
	m.spread = 25.0
	m.initial_velocity_min = 0.3
	m.initial_velocity_max = 0.9
	m.gravity = Vector3(0, 0.25, 0)
	m.scale_min = 0.5
	m.scale_max = 1.0
	var grad := Gradient.new()
	grad.set_color(0, Color(Tema.LARANJA, 1.0))
	grad.set_color(1, Color(Tema.ROSA, 0.0))
	var tg := GradientTexture1D.new()
	tg.gradient = grad
	m.color_ramp = tg
	p.process_material = m
	var q := QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Tema.LARANJA
	mat.emission_energy_multiplier = 2.0
	q.material = mat
	p.draw_pass_1 = q
	onde.add_child(p)


func _pedestais() -> void:
	pedestais_no = Node3D.new()
	pedestais_no.name = "Pedestais"
	add_child(pedestais_no)
	for i in 4:
		var pos := Vector3(-4.2 + i * 2.8, 0, 4.4)
		pedestais.append(pos + Vector3(0, 0.32, 0))
		var disco := CSGCylinder3D.new()
		disco.radius = 0.95
		disco.height = 0.32
		disco.sides = 8
		disco.position = pos + Vector3(0, 0.16, 0)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color("#8784b3")
		m.roughness = 0.7
		disco.material = m
		pedestais_no.add_child(disco)
		var aro := CSGTorus3D.new()
		aro.inner_radius = 0.92
		aro.outer_radius = 1.02
		aro.sides = 8
		aro.ring_sides = 6
		aro.position = pos + Vector3(0, 0.32, 0)
		var brilho := StandardMaterial3D.new()
		var cor: Color = Forja.cor_do_lugar(i)
		brilho.albedo_color = cor
		brilho.emission_enabled = true
		brilho.emission = cor
		brilho.emission_energy_multiplier = 1.2
		aro.material = brilho
		aro.name = "Aro%d" % i
		pedestais_no.add_child(aro)
		# a bigorna do lugar e a luz quente dela: baixa, não tinge o cavaleiro
		var bigorna_do_lugar := Kit.bigorna(pedestais_no, pos + Vector3(0.62, 0.32, -0.5), 0.3)
		bigorna_do_lugar.rotation.y = -0.5
		var luz := OmniLight3D.new()
		luz.position = pos + Vector3(0.62, 0.9, -0.5)
		luz.light_color = Tema.LARANJA
		luz.omni_range = 1.6
		luz.shadow_enabled = false
		luz.light_energy = 0.0
		pedestais_no.add_child(luz)
		luzes_das_bigornas.append(luz)


## A bigorna do lugar acende em `energia` e cai a 0,8 em 0,3 s (SAI, a curva do
## arte/05: cúbica, rápida no começo, assenta no fim) se o lugar está ocupado, a
## 0 se não. `a_mais` soma ao repouso: a forja que avança deixa a bigorna mais
## acesa a cada martelada, e a construção não fica parada na tela.
func acender_bigorna(l: int, energia: float, a_mais := 0.0) -> void:
	l = clampi(l, 0, 3)
	if l >= luzes_das_bigornas.size():
		return
	var luz := luzes_das_bigornas[l]
	if _tw_bigorna[l] != null and is_instance_valid(_tw_bigorna[l]):
		(_tw_bigorna[l] as Tween).kill()
	var repouso := (0.8 + a_mais) if Forja.ocupado(l) else 0.0
	if not luz.is_inside_tree():
		luz.light_energy = repouso
		return
	luz.light_energy = energia
	var tw := luz.create_tween()
	tw.tween_property(luz, "light_energy", repouso, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tw_bigorna[l] = tw


func _enfeites() -> void:
	# colunas entre os portões do norte
	for x in [-8.0, -4.0, 0.0, 4.0, 8.0]:
		peca("column", Vector3(x, 0, Z_NORTE + 1.4), 0.0, K * 1.1)
	# estandartes nas paredes do norte, acima das colunas
	for x in [-10.0, 10.0]:
		peca("banner", Vector3(x, 0.4, Z_NORTE + 1.0 + 1.06), PI, K)
	# barris, caixotes, pedras nos cantos
	peca("barrel", Vector3(-10.2, 0, -7.2), 0.3)
	peca("barrel", Vector3(-9.3, 0, -7.6), 1.2)
	peca("barrel", Vector3(10.1, 0, -7.3), 0.7)
	peca("wood-structure", Vector3(9.8, 0, 7.0), 0.0, K * 0.9)
	peca("rocks", Vector3(-10.3, 0, 7.3), 0.4, K * 0.8)
	peca("chest", Vector3(-10.0, 0.1, 0.0), PI * 0.5, K)
	peca("table", Vector3(8.6, 0, 6.6), 0.2, K)
	peca("pot", Vector3(7.7, 0, 7.3), 0.0, K * 0.9)
	# o suporte de armas ao lado do baú
	var escudo := peca("shield-round", Vector3(-11.0, 1.4, 1.4), PI * 0.5, K)
	escudo.rotation.x = 0.0
	peca("weapon-sword", Vector3(-11.0, 1.1, 2.0), PI * 0.5, K)
	peca("weapon-spear", Vector3(-11.1, 0.0, 2.5), PI * 0.5, K)


## O portão mais perto de `pos` (dentro do alcance), ou "".
func portao_perto(pos: Vector3, alcance := 2.4) -> String:
	var melhor := ""
	var dist := alcance
	for id in portoes:
		var g: Dictionary = portoes[id]
		var frente_do_portao: Vector3 = g.pos + g.frente * 1.4
		var d := Vector2(pos.x - frente_do_portao.x, pos.z - frente_do_portao.z).length()
		if d < dist:
			dist = d
			melhor = id
	return melhor


func abrir_portao(id: String, abrir: bool) -> void:
	if not portoes.has(id):
		return
	var g: Dictionary = portoes[id]
	if not g.aberta or g.aberto == abrir:
		return
	g.aberto = abrir
	if g.anim:
		g.anim.play("open" if abrir else "close")


## Onde o jogador para, de frente para o portão, ao voltar da sala.
func saida_do_portao(id: String, lugar: int) -> Vector3:
	var g: Dictionary = portoes.get(id, {})
	if g.is_empty():
		return Vector3((lugar - 1.5) * 1.4, 0, 3.0)
	var lado: Vector3 = g.frente.cross(Vector3.UP)
	return g.pos + g.frente * 2.6 + lado * (lugar - 1.5) * 1.1


func centro_do_portao(id: String) -> Vector3:
	var g: Dictionary = portoes.get(id, {})
	return g.get("pos", Vector3.ZERO)


# ----------------------------------------------------------------- a coleção --

func _material_do_tubo() -> ShaderMaterial:
	if _mat_do_tubo == null:
		# o dono do tubo é a forja (teto 2,4 do arte/07); 1,3 de energia, para o glow pegar sem estourar
		_mat_do_tubo = Kit.neon(Tema.TUNGSTENIO, 1.3)
	return _mat_do_tubo


## O estado de uma etiqueta: o papel, a tarja, o texto impresso, as marcas, a luz e o tubo.
func _etiqueta(id: String, acesa: bool, lado_b := false) -> void:
	var g: Dictionary = portoes[id]
	var dados: Dictionary = g.dados
	var n: int = g.n
	g.aceso = acesa
	((g.papel as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = Tema.ETIQUETA if acesa else Tema.ETIQUETA_SOMBRA
	var tinta := Tema.tinta_da_secao(n)
	var tarjas: Array = g.tarjas
	for i in tarjas.size():
		var t := tarjas[i] as MeshInstance3D
		(t.material_override as StandardMaterial3D).albedo_color = tinta if acesa else tinta.darkened(0.15)
		# o lado B: duas caixas finas de 0,058 com 0,033 de vão no lugar da inteira
		t.visible = i == 0 and not lado_b
	if lado_b:
		_tarja_dupla(g, tinta if acesa else tinta.darkened(0.15))
	else:
		for k in 2:
			var b := (g.placa as Node3D).get_node_or_null("TarjaB%d" % k) as Node3D
			if b:
				b.visible = false
	var marcas: Array = g.marcas
	var vencidas := Colecao.marcas(id)
	for i in marcas.size():
		var m := marcas[i] as MeshInstance3D
		var feita: bool = i < vencidas.size() and vencidas[i]
		var cor := Tema.TINTA if feita else (Tema.ETIQUETA_SOMBRA if acesa else Tema.TINTA_SUAVE)
		(m.material_override as StandardMaterial3D).albedo_color = cor
	var total := marcas.size()
	var linha := "S%d · EM BREVE" % n
	if dados.aberta:
		linha = "S%d · %d FAIXA%s" % [n, total, "" if total == 1 else "S"]
	(g.faixas as Label3D).text = Desenho.t(linha)
	(g.foco as SpotLight3D).light_energy = FOCO_ACESO if acesa else FOCO_APAGADO
	(g.tubo as MeshInstance3D).visible = acesa


func _tarja_dupla(g: Dictionary, cor: Color) -> void:
	var placa: Node3D = g.placa
	for k in 2:
		var nome := "TarjaB%d" % k
		var t := placa.get_node_or_null(nome) as MeshInstance3D
		if t == null:
			t = Kit.caixa(placa, Vector3(2.9, 0.058, 0.05), Vector3(0, 0.33 + (0.0165 + 0.029) * (1.0 if k == 0 else -1.0), 0.01), Kit.material(cor, 0.0, 0.9))
			t.name = nome
		(t.material_override as StandardMaterial3D).albedo_color = cor
		t.visible = true


## Acende etiquetas, marcas e tubos pela Colecao, refaz a vitrine; `lado_b` põe a tarja dupla.
func mostrar_colecao(lado_b := false) -> void:
	for p in PORTOES:
		_etiqueta(str(p.id), Colecao.secao_acesa(str(p.id)), lado_b)
	_refazer_a_vitrine()


func portao_aceso(id: String) -> bool:
	return bool(portoes.get(id, {}).get("aceso", false))


func trofeus_na_vitrine() -> int:
	return trofeus_no.get_child_count() if trofeus_no else 0


## O albedo do copo da taça i (ou do cubo de um coop): a cor de quem venceu.
func cor_do_trofeu(i: int) -> Color:
	return _cores_dos_trofeus[i] if i >= 0 and i < _cores_dos_trofeus.size() else Color()


## O som de fundo do salão só corre com o salão à mostra.
func pausar_ambiente(pausado: bool) -> void:
	if _amb:
		_amb.stream_paused = pausado


## A vitrine da parede leste, entre os dois portões: dois montantes e três prateleiras.
func _vitrine() -> void:
	vitrine_no = Node3D.new()
	vitrine_no.name = "Vitrine"
	vitrine_no.position = Vector3(10.6, 0.0, 0.0)
	vitrine_no.rotation.y = -PI * 0.5
	add_child(vitrine_no)
	var madeira := Kit.material(Tema.OXIDO, 0.0, 0.9)
	for lado in [-1.0, 1.0]:
		Kit.caixa(vitrine_no, Vector3(0.08, 1.9, 0.5), Vector3(lado * 1.25, 0.95, 0), madeira)
	for y in [0.6, 1.2, 1.8]:
		Kit.caixa(vitrine_no, Vector3(2.5, 0.08, 0.5), Vector3(0, y, 0), madeira)
	trofeus_no = Node3D.new()
	trofeus_no.name = "Trofeus"
	vitrine_no.add_child(trofeus_no)


func _refazer_a_vitrine() -> void:
	for c in trofeus_no.get_children():
		trofeus_no.remove_child(c)
		c.queue_free()
	_cores_dos_trofeus.clear()
	var lista: Array = Colecao.trofeus
	var de := maxi(0, lista.size() - VITRINE_MAX)
	var madeira := Kit.material(Tema.OXIDO, 0.0, 0.9)
	for i in range(de, lista.size()):
		var k := i - de
		var t := Node3D.new()
		t.position = Vector3(-1.0 + (k % 6) * 0.4, 0.64 + floorf(k / 6.0) * 0.6, 0)
		trofeus_no.add_child(t)
		var trofeu: Dictionary = lista[i]
		var lugar := int(trofeu.get("lugar", 0))
		var cor: Color = Tema.JOGADOR[clampi(lugar, 0, 3)]
		match str(trofeu.get("tipo", "vitoria")):
			"recorde":
				Kit.caixa(t, Vector3(0.16, 0.04, 0.16), Vector3(0, 0.02, 0), madeira)
				var moeda := Kit.peca(t, "coin", Vector3(0, 0.12, 0), 0.0, 0.8)
				moeda.rotation.x = PI * 0.5
				_cores_dos_trofeus.append(cor)
			"coop":
				var cubos: Array[Color] = []
				for q in 4:
					var mc := Kit.material(Tema.JOGADOR[q], 0.0, 0.6)
					Kit.caixa(t, Vector3(0.07, 0.07, 0.07), Vector3(-0.105 + q * 0.07, 0.035, 0), mc)
					cubos.append(mc.albedo_color)
				_cores_dos_trofeus.append(cubos[0])   # o coop não tem dono: a prova lê o primeiro cubo
			_:
				var m := Kit.material(cor, 0.0, 0.6)
				Kit.caixa(t, Vector3(0.16, 0.04, 0.16), Vector3(0, 0.02, 0), m)
				Kit.cilindro(t, 0.03, 0.10, Vector3(0, 0.09, 0), m)
				var copo := Kit.cilindro(t, 0.06, 0.14, Vector3(0, 0.21, 0), m, 0.09)
				_cores_dos_trofeus.append((copo.material_override as StandardMaterial3D).albedo_color)
