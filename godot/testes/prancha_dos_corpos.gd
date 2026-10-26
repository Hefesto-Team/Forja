extends SceneTree

const COLUNAS := 6
const LINHAS := 3
const CELULA := Vector2i(320, 360)
const FAIXA := 64
const FOV := 27.0
const DISTANCIA := 2.2
const ALTURA := 0.45
const QUADRO := 0.5
const ESCALA_DA_CAUDA := 0.33
const VIOLETA_FUNDO := Color("#1d1638")
const KENNEY := "res://assets/kenney/%s.glb"

const CORPOS := [
	["mini-characters/character-female-a", "humana"], ["mini-characters/character-female-b", "humana"],
	["mini-characters/character-female-c", "humana"], ["mini-characters/character-female-d", "humana"],
	["mini-characters/character-female-e", "humana"], ["mini-characters/character-female-f", "humana"],
	["mini-characters/character-male-a", "humano"], ["mini-characters/character-male-b", "humano"],
	["mini-characters/character-male-c", "humano"], ["mini-characters/character-male-d", "humano"],
	["mini-characters/character-male-e", "humano"], ["mini-characters/character-male-f", "humano"],
	["mini-dungeon-personagens/character-orc", "orc"], ["mini-dungeon-personagens/character-human", "humano de hoje"],
	["cube-pets/animal-fox", "só a cauda, 0,33"], ["graveyard-kit/character-skeleton", "monstro"],
	["graveyard-kit/character-zombie", "monstro"], ["graveyard-kit/character-vampire", "monstro"],
]

var _celulas: Array = []
var _folha: Control


func _initialize() -> void:
	root.size = Vector2i(1920, 1080)
	_folha = Control.new()
	_folha.size = Vector2(1920, 1080)
	root.add_child(_folha)
	var fundo := ColorRect.new()
	fundo.color = Tema.CASCO
	fundo.size = Vector2(1920, 1080)
	_folha.add_child(fundo)
	for i in CORPOS.size():
		_celulas.append(_montar(i))
	_rodar.call_deferred()


func _montar(i: int) -> Dictionary:
	var col := i % COLUNAS
	var lin := i / COLUNAS
	var origem := Vector2(col * CELULA.x, lin * CELULA.y)
	var area := Vector2i(CELULA.x, CELULA.y - FAIXA)
	var cont := SubViewportContainer.new()
	cont.position = origem
	cont.size = Vector2(area)
	cont.stretch = true
	_folha.add_child(cont)
	var vp := SubViewport.new()
	vp.size = area
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	cont.add_child(vp)
	var amb := Environment.new()
	amb.background_mode = Environment.BG_COLOR
	amb.background_color = VIOLETA_FUNDO
	amb.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	amb.ambient_light_color = VIOLETA_FUNDO.lightened(0.35)
	amb.ambient_light_energy = 1.0
	amb.fog_enabled = true
	amb.fog_light_color = VIOLETA_FUNDO
	amb.fog_density = 0.02
	var we := WorldEnvironment.new()
	we.environment = amb
	vp.add_child(we)
	var luz := DirectionalLight3D.new()
	luz.light_color = Tema.TUNGSTENIO
	luz.light_energy = 1.2
	luz.rotation_degrees = Vector3(-30, -25, 0)
	vp.add_child(luz)
	var cam := Camera3D.new()
	cam.fov = FOV
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.position = Vector3(0, ALTURA, DISTANCIA)
	vp.add_child(cam)
	var caminho: String = CORPOS[i][0]
	var cena = load(KENNEY % caminho)
	var modelo: Node3D = cena.instantiate() if cena else Node3D.new()
	vp.add_child(modelo)
	if caminho.begins_with("cube-pets/"):
		_so_a_cauda(modelo)
	var ap := modelo.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap and ap.has_animation("idle"):
		ap.play("idle")
		ap.seek(QUADRO, true)
		ap.pause()
	var faixa := ColorRect.new()
	faixa.color = Tema.CASCO
	faixa.position = origem + Vector2(0, area.y)
	faixa.size = Vector2(CELULA.x, FAIXA)
	_folha.add_child(faixa)
	var nome := Label.new()
	nome.text = "%s\n%s" % [caminho.get_file(), CORPOS[i][1]]
	nome.position = faixa.position
	nome.size = faixa.size
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nome.add_theme_font_override("font", Tema.vt())
	nome.add_theme_font_size_override("font_size", 30)
	nome.add_theme_color_override("font_color", Tema.ETIQUETA)
	nome.add_theme_constant_override("line_spacing", -6)
	_folha.add_child(nome)
	return {"vp": vp, "modelo": modelo, "amb": amb, "luz": luz, "cont": cont}


func _so_a_cauda(modelo: Node3D) -> void:
	var cauda := modelo.find_child("tail", true, false) as MeshInstance3D
	if cauda == null:
		push_error("animal-fox sem o nó tail")
		return
	for m in modelo.find_children("*", "MeshInstance3D", true, false):
		if m != cauda:
			(m as MeshInstance3D).mesh = null
	var no: Node3D = cauda
	var origem := Vector3.ZERO
	while no != modelo:
		origem = no.transform * origem
		no = no.get_parent() as Node3D
	modelo.scale = Vector3.ONE * ESCALA_DA_CAUDA
	modelo.position = Vector3(0, ALTURA, 0) - origem * ESCALA_DA_CAUDA


func _rodar() -> void:
	for _i in 12:
		await process_frame
	var pasta := OS.get_environment("SAIDA")
	if pasta == "":
		pasta = ProjectSettings.globalize_path("res://").path_join("../docs/imagens/kenney").simplify_path()
	DirAccess.make_dir_recursive_absolute(pasta)
	await _gravar(pasta.path_join("corpos.jpg"))
	_silhueta()
	await _gravar(pasta.path_join("corpos_silhueta.jpg"))
	quit(0)


func _gravar(arquivo: String) -> void:
	for _i in 6:
		await process_frame
	var img := root.get_texture().get_image()
	if img.get_size() != Vector2i(1920, 1080):
		img.resize(1920, 1080, Image.INTERPOLATE_LANCZOS)
	var rc := img.save_jpg(arquivo, 0.9)
	print("%s: %s (%d×%d)" % [arquivo, "ok" if rc == OK else "erro %d" % rc, img.get_width(), img.get_height()])


func _silhueta() -> void:
	var chapa := StandardMaterial3D.new()
	chapa.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	chapa.albedo_color = Tema.FITA
	for c in _celulas:
		var amb: Environment = c["amb"]
		amb.background_color = Tema.ETIQUETA
		amb.fog_enabled = false
		for m in (c["modelo"] as Node3D).find_children("*", "MeshInstance3D", true, false):
			(m as MeshInstance3D).material_override = chapa
