extends RefCounted
## As peças do estudo: os modelos da Kenney recoloridos (cada pacote com a sua
## cópia do colormap), o cavaleiro com o néon de dono, a luz e o pós da fita.

const Fita := preload("res://estudos/direcao/fita.gd")
const RAIZ := "res://estudos/direcao/kenney/%s.glb"
const K := 2.0
## A escala de cada pacote sobre o K (a tabela do doc 14).
const ESCALA := {"survival-kit": 1.4}

static var _cenas := {}
static var _malhas_suaves := {}


static func peca(pai: Node, nome: String, pos: Vector3, rot_y := 0.0, escala := -1.0) -> Node3D:
	if not _cenas.has(nome):
		_cenas[nome] = load(RAIZ % nome)
	var cena: PackedScene = _cenas[nome]
	var n: Node3D = cena.instantiate()
	if escala < 0.0:
		escala = K * float(ESCALA.get(nome.get_slice("/", 0), 1.0))
	n.position = pos
	n.rotation.y = rot_y
	n.scale = Vector3.ONE * escala
	pai.add_child(n)
	return n


## Troca o colormap de todas as superfícies (o "antes" da prancha 09).
static func trocar_textura(n: Node, tex: Texture2D) -> void:
	for filho in n.get_children():
		if filho is MeshInstance3D:
			var mi: MeshInstance3D = filho
			for s in mi.mesh.get_surface_count():
				var base := mi.mesh.surface_get_material(s)
				if base is StandardMaterial3D:
					var m: StandardMaterial3D = base.duplicate()
					m.albedo_texture = tex
					mi.set_surface_override_material(s, m)
		trocar_textura(filho, tex)


## A normal suavizada de cada vértice (a média das faces que dividem a mesma
## posição), gravada no TANGENT: o casco do contorno cresce por ela e não abre
## nos cantos dos blocos.
static func suavizar(mi: MeshInstance3D) -> void:
	var original: Mesh = mi.mesh
	if _malhas_suaves.has(original):
		mi.mesh = _malhas_suaves[original]
		return
	var nova := ArrayMesh.new()
	for s in original.get_surface_count():
		var arr: Array = original.surface_get_arrays(s)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
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
		nova.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		nova.surface_set_material(s, original.surface_get_material(s))
	_malhas_suaves[original] = nova
	mi.mesh = nova


## O contorno de néon num modelo inteiro (objetos que importam: a bigorna de
## cada um, o troféu).
static func contornar(n: Node, cor: Color, largura := 0.012, energia := 2.4) -> void:
	for filho in n.get_children():
		if filho is MeshInstance3D:
			var mi: MeshInstance3D = filho
			suavizar(mi)
			for s in mi.mesh.get_surface_count():
				var base: Material = mi.get_surface_override_material(s)
				if base == null:
					base = mi.mesh.surface_get_material(s)
				var m: Material = base.duplicate()
				m.next_pass = Fita.contorno(cor, largura, energia)
				mi.set_surface_override_material(s, m)
		contornar(filho, cor, largura, energia)


# ----------------------------------------------------------- o cavaleiro --
const MODELOS := ["character-male-b", "character-female-b", "character-male-e", "character-female-d"]


## Um cavaleiro: o boneco do Mini Characters com o corpo na cor do lugar, o
## aro de luz e o contorno na mesma cor; o anel de oito lados no chão, com as
## lâmpadas do lugar (1 a 4) marcadas nele.
static func cavaleiro(pai: Node, lugar: int, pos: Vector3, yaw := 0.0, anim := "idle", t_anim := 0.3,
		modelo := "", opcoes := {}) -> Node3D:
	var cor: Color = Fita.JOGADOR[lugar]
	var raiz := Node3D.new()
	raiz.name = "P%d" % (lugar + 1)
	raiz.position = pos
	raiz.rotation.y = yaw
	pai.add_child(raiz)
	if modelo == "":
		modelo = MODELOS[lugar]
	var m := peca(raiz, "mini-characters/" + modelo, Vector3.ZERO)
	vestir(m, cor, opcoes)
	var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	if ap and ap.has_animation(anim):
		ap.play(anim)
		ap.seek(t_anim, true)
		ap.pause()
	if opcoes.get("martelo", false):
		martelo(m)
	if opcoes.get("anel", true):
		anel(raiz, cor, lugar)
	return raiz


static func vestir(m: Node, cor: Color, opcoes := {}) -> void:
	for filho in m.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = filho
		suavizar(mi)
		var corpo := String(mi.name).begins_with("body")
		for s in mi.mesh.get_surface_count():
			var base: StandardMaterial3D = mi.mesh.surface_get_material(s)
			var sm := ShaderMaterial.new()
			sm.shader = Fita.SH_CAVALEIRO
			sm.set_shader_parameter("textura", base.albedo_texture)
			sm.set_shader_parameter("tinta", cor)
			sm.set_shader_parameter("tingir", 1.0 if corpo and opcoes.get("tingir", true) else 0.0)
			sm.set_shader_parameter("aro_cor", cor)
			sm.set_shader_parameter("aro", float(opcoes.get("aro", 0.6)))
			sm.set_shader_parameter("brilho_proprio", float(opcoes.get("brilho", 0.10)) if corpo else 0.0)
			if opcoes.get("contorno", true):
				sm.next_pass = Fita.contorno(cor, float(opcoes.get("largura", 0.014)), float(opcoes.get("energia", 1.6)))
			mi.set_surface_override_material(s, sm)


## O martelo da Kenney (Survival Kit) na mão direita.
static func martelo(m: Node) -> void:
	var esq: Skeleton3D = m.find_child("Skeleton3D", true, false)
	if esq == null:
		return
	var presa := BoneAttachment3D.new()
	presa.bone_name = "arm-right"
	esq.add_child(presa)
	# o boneco já vem na escala K: aqui a medida é a do osso (o braço tem 0,1)
	var h := peca(presa, "survival-kit/tool-hammer", Vector3(-0.01, -0.13, 0.0), 0.0, 2.3)
	h.rotation_degrees = Vector3(60, 0, 0)


## O anel de oito lados no chão, na cor do lugar, com as lâmpadas do lugar:
## a cor nunca sozinha.
static func anel(pai: Node3D, cor: Color, lugar: int, raio := 0.62) -> Node3D:
	var a := Node3D.new()
	a.position.y = 0.03
	pai.add_child(a)
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = raio - 0.05
	t.outer_radius = raio + 0.03
	t.rings = 8
	t.ring_segments = 4
	mi.mesh = t
	mi.scale = Vector3(1, 0.22, 1)
	mi.rotation.y = PI / 8.0
	mi.material_override = Fita.neon(cor, 1.5)
	a.add_child(mi)
	# as lâmpadas do controle, as cinco posições, na frente do anel
	for i in 5:
		if (int(Fita.LEDS[lugar]) >> i) & 1 == 0:
			continue
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.09, 0.02, 0.14)
		b.mesh = bm
		var x := (i - 2) * 0.16
		b.position = Vector3(x, 0.0, raio + 0.2)
		b.material_override = Fita.neon(cor, 1.8)
		a.add_child(b)
	return a


## O néon não faz sombra (é luz): sem isso, o anel da runa desenha um
## octógono escuro no chão.
static func neon_sem_sombra(raiz: Node) -> void:
	for n in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = n
		var m := mi.material_override
		if m is ShaderMaterial and (m as ShaderMaterial).shader == Fita.SH_NEON:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# ----------------------------------------------------------- a luz e o pós --
static func ambiente(pai: Node, opcoes := {}) -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	# com o glow ligado, o fundo do Compatibility sai ~3,5× mais claro e mais
	# azul (o #0d0a16 saía #2e1f5b, um lavanda que lavava a tela); medido no
	# num quadro de prova, o fator 0,45 devolve a fita
	var fundo: Color = opcoes.get("fundo", Fita.FITA)
	var k := 0.45 if opcoes.get("glow", true) else 1.0
	env.background_color = Color(fundo.r * k, fundo.g * k, fundo.b * k)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = opcoes.get("ambiente", Color("#2a2738"))
	env.ambient_light_energy = float(opcoes.get("ambiente_energia", 0.5))
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = float(opcoes.get("exposicao", 1.0))
	env.tonemap_white = 6.0
	env.glow_enabled = opcoes.get("glow", true)
	env.glow_intensity = float(opcoes.get("glow_intensidade", 0.8))
	env.glow_strength = 1.0
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = float(opcoes.get("glow_limiar", 0.82))
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	for i in 7:
		env.set_glow_level(i, [0.0, 0.0, 1.0, 0.8, 0.5, 0.2, 0.0][i])
	env.fog_enabled = opcoes.get("nevoa", true)
	env.fog_light_color = opcoes.get("nevoa_cor", Fita.VIOLETA_FUNDO)
	env.fog_density = float(opcoes.get("nevoa_densidade", 0.018))
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_saturation = float(opcoes.get("saturacao", 1.0))
	env.adjustment_contrast = float(opcoes.get("contraste", 1.05))
	var we := WorldEnvironment.new()
	we.environment = env
	pai.add_child(we)
	return env


static func pos(pai: Node, camada := 5, opcoes := {}) -> ShaderMaterial:
	var cl := CanvasLayer.new()
	cl.layer = camada
	pai.add_child(cl)
	var r := ColorRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = preload("res://estudos/direcao/shaders/pos_fita.gdshader")
	for k in opcoes:
		m.set_shader_parameter(k, opcoes[k])
	r.material = m
	cl.add_child(r)
	return m


static func luz(pai: Node3D, pos_: Vector3, cor: Color, energia: float, alcance: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos_
	l.light_color = cor
	l.light_energy = energia
	l.omni_range = alcance
	l.omni_attenuation = 1.2
	pai.add_child(l)
	return l


static func foco(pai: Node3D, pos_: Vector3, alvo: Vector3, cor: Color, energia: float, angulo := 28.0, alcance := 14.0, sombra := false) -> SpotLight3D:
	var l := SpotLight3D.new()
	pai.add_child(l)
	l.position = pos_
	l.look_at_from_position(pos_, alvo, Vector3.UP if absf((alvo - pos_).normalized().y) < 0.99 else Vector3.FORWARD)
	l.light_color = cor
	l.light_energy = energia
	l.spot_angle = angulo
	l.spot_range = alcance
	l.spot_angle_attenuation = 0.6
	l.shadow_enabled = sombra
	l.shadow_bias = 0.08
	l.shadow_normal_bias = 2.0
	return l


## Uma barra de néon (tubo) — da arquitetura (violeta) ou de um jogador.
static func tubo(pai: Node3D, tamanho: Vector3, pos_: Vector3, cor: Color, energia := 1.6) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tamanho
	mi.mesh = b
	mi.position = pos_
	mi.material_override = Fita.neon(cor, energia)
	pai.add_child(mi)
	return mi


static func caixa(pai: Node3D, tamanho: Vector3, pos_: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tamanho
	mi.mesh = b
	mi.position = pos_
	mi.material_override = mat
	pai.add_child(mi)
	return mi
