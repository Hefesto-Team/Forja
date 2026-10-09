extends SceneTree
## A prancha dos corpos (G10): os 12 do Mini Characters, o orc, o humano, a cauda da raposa e
## três monstros do Graveyard, um por célula, de frente, com o nome do arquivo embaixo. Grava
## duas folhas de 1920×1080 em docs/imagens/kenney/: `corpos.jpg` (a luz do salão, o
## colormap original) e `corpos_silhueta.jpg` (cada malha chapada em FITA sobre ETIQUETA).
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --audio-driver Dummy \
##     --path godot --resolution 1920x1080 --script res://testes/prancha_dos_corpos.gd
##
## SAIDA=<pasta> muda onde gravar. A câmera é a de 50 mm (FOV vertical 2·atan(12/50) = 27,0°),
## de frente, a 2,2 m, na altura de 0,45 m, e o quadro é o de 0,5 s do `idle`.

const COLUNAS := 6
const LINHAS := 3
const CELULA := Vector2i(320, 360)
const FAIXA := 64               ## a faixa do nome, embaixo de cada célula
const FOV := 27.0
const DISTANCIA := 2.2
const ALTURA := 0.45
const QUADRO := 0.5
const ESCALA_DA_CAUDA := 0.33   ## a escala em que a G13 a põe no cavaleiro
## A névoa e o preenchimento do salão (arte/02). Ainda não é token do Tema.
const VIOLETA_FUNDO := Color("#1d1638")
const KENNEY := "res://assets/kenney/%s.glb"

## [pasta/arquivo, o papel escrito na faixa]
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

var _celulas: Array = []        ## cada uma: {"vp", "modelo", "caixa"}
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
	# a faixa do nome
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


## O Cube Pets é rígido: a cauda é o nó `tail`, filho do `body`. Tira a malha de tudo o que não é
## ela (sem esconder o nó, que esconderia os filhos) e leva a cauda para o meio da célula.
func _so_a_cauda(modelo: Node3D) -> void:
	var cauda := modelo.find_child("tail", true, false) as MeshInstance3D
	if cauda == null:
		push_error("animal-fox sem o nó tail")
		return
	for m in modelo.find_children("*", "MeshInstance3D", true, false):
		if m != cauda:
			(m as MeshInstance3D).mesh = null
	# a posição da cauda no modelo, de pai em filho (o nó ainda não tem transformada global)
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


## Cada malha chapada em FITA sobre ETIQUETA: só a silhueta.
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
