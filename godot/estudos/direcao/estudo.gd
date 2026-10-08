extends Node3D
## O estudo de direção de arte (Fita Magnética): monta um quadro e fotografa.
## Nada do jogo roda aqui; só os modelos da Kenney recoloridos, a luz, o pós
## e o HUD novo, para a aprovação da direção.
##
##   QUADRO=01_centelha SAIDA=<pasta> xvfb-run -a -s "-screen 0 1920x1080x24" godot \
##       --rendering-driver opengl3 --path godot --resolution 1920x1080 res://estudos/direcao/estudo.tscn
##
## (o render.sh desta pasta faz todos.)

var camera: Camera3D
var quadro: Node


func _ready() -> void:
	get_window().size = Vector2i(1920, 1080)
	camera = Camera3D.new()
	camera.fov = 40.0
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	add_child(camera)
	camera.current = true
	var nome := OS.get_environment("QUADRO")
	var script: GDScript = load("res://estudos/direcao/quadros/%s.gd" % nome)
	quadro = script.new()
	add_child(quadro)
	quadro.montar(self)
	var espera := int(quadro.get("espera")) if quadro.get("espera") != null else 10
	for i in espera:
		await get_tree().process_frame
	if quadro.has_method("antes_da_foto"):
		await quadro.antes_da_foto()
	await RenderingServer.frame_post_draw
	var saida := OS.get_environment("SAIDA")
	var img := get_viewport().get_texture().get_image()
	var arquivo: String = quadro.get("arquivo") if quadro.get("arquivo") != null else nome
	img.save_png(saida.path_join(arquivo + ".png"))
	print("foto: ", arquivo)
	if quadro.has_method("depois_da_foto"):
		await quadro.depois_da_foto(saida)
	get_tree().quit()


## A câmera do quadro (a pose, o olhar, o campo).
func olhar(pos: Vector3, alvo: Vector3, fov := 40.0) -> void:
	camera.position = pos
	camera.look_at(alvo)
	camera.fov = fov
