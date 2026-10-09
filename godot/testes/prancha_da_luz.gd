extends Node
## A prancha da luz: a Centelha, com os quatro bonecos, nas cinco tintas (linhas) e nos
## lados A e B (colunas), 960x540 cada, na câmera de 35 mm em plongée de 50 graus, pelo
## jogo de verdade (a luz de cada seção, o pós, o contorno e o anel). Grava
## docs/imagens/jogo/luz.jpg, 1920x2700, para ficar ao lado de docs/imagens/direcao/13_luz.jpg.
## Precisa de janela (o Xvfb, com o OpenGL por software; o --headless não devolve imagem):
##
##   env -u WAYLAND_DISPLAY xvfb-run -a -s "-screen 0 960x540x24" godot --display-driver x11 \
##     --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --resolution 960x540 \
##     --path godot res://testes/prancha_da_luz.tscn -- --simular=4 [--saida=<arquivo.jpg>]
##
## A aparência não se aprova aqui: o renderizador por software não é a placa de vídeo. A
## olhada final é de quem joga, ao lado do 13_luz.jpg.

const CEL := Vector2i(960, 540)
const FOLHA := Vector2i(1920, 2700)
## A tinta de cada linha: o número de uma seção que tem essa tinta, e como a prancha a chama.
const LINHAS := [
	{"secao": 1, "nome": "VERMELHÃO", "a": "S1 A Centelha", "b": "S9 A Prova"},
	{"secao": 2, "nome": "COBALTO", "a": "S2 A Viga", "b": "S6 O Canto"},
	{"secao": 3, "nome": "PETRÓLEO", "a": "S3 O Molde", "b": "S7 Os Caminhos"},
	{"secao": 4, "nome": "MOSTARDA", "a": "S4 O Impacto", "b": "o pódio"},
	{"secao": 5, "nome": "AMEIXA", "a": "S5 A Galeria", "b": "S8 A Voz"},
]

var jogo: Node
var folha: Image
var legenda: Label
var faixa: ColorRect
var rodape: Label
var _camera_alvo := Vector3(0, 0.6, 0.2)
var _saida := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			_saida = a.substr(8)
	if _saida == "":
		_saida = ProjectSettings.globalize_path("res://").path_join("../docs/imagens/jogo/luz.jpg").simplify_path()
	folha = Image.create(FOLHA.x, FOLHA.y, false, Image.FORMAT_RGB8)
	folha.fill(Tema.FITA)
	jogo = load("res://scenes/main.tscn").instantiate()
	add_child(jogo)
	_legendas()
	RenderingServer.frame_pre_draw.connect(_enquadrar)
	await _quadros(4)
	for p in jogo.jogadores:
		p.visible = true
	jogo._entrar_na_sala("centelha", false)
	await _quadros(8)
	# só a sala e os bonecos: nada de HUD nem de painel
	jogo.get_node("Interface").visible = false
	var vistos := 0
	for p in jogo.jogadores:
		if p.visible:
			vistos += 1
	print("bonecos na sala: %d" % vistos)
	for linha in LINHAS.size():
		for lado in 2:
			var t: Dictionary = LINHAS[linha]
			jogo.acender(int(t.secao), lado == 1)
			PosFita.gastar(1)
			var luz := Tema.luz_da_secao(int(t.secao), lado == 1)
			legenda.text = "%s  ·  LADO %s  ·  %s" % [t.b if lado == 1 else t.a, "B" if lado == 1 else "A", t.nome]
			rodape.text = "chave %s ×%s · névoa %s ×%s · preench. %s" % [luz.chave.to_html(false), "0,85" if lado == 1 else "1",
				luz.nevoa.to_html(false), "1,3" if lado == 1 else "1", luz.preenchimento.to_html(false)]
			await _quadros(10)
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			img.convert(Image.FORMAT_RGB8)
			if img.get_size() != Vector2i(CEL):
				img.resize(CEL.x, CEL.y, Image.INTERPOLATE_LANCZOS)
			folha.blit_rect(img, Rect2i(Vector2i.ZERO, CEL), Vector2i(lado * CEL.x, linha * CEL.y))
	DirAccess.make_dir_recursive_absolute(_saida.get_base_dir())
	var erro := folha.save_jpg(_saida, 0.9)
	print("prancha da luz: %s (%s)" % [_saida, "ok" if erro == OK else "erro %d" % erro])
	get_tree().quit(0 if erro == OK else 1)


func _quadros(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## A câmera de 35 mm em plongée de 50 graus, posta logo antes de cada desenho (por cima do que o jogo faz).
func _enquadrar() -> void:
	var cam: Camera3D = jogo.camera
	if cam == null:
		return
	cam.fov = rad_to_deg(2.0 * atan(12.0 / 35.0))
	var a := deg_to_rad(50.0)
	var d := 17.0
	cam.position = _camera_alvo + Vector3(0, d * sin(a), d * cos(a))
	cam.look_at(_camera_alvo)


func _legendas() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 30
	add_child(camada)
	faixa = ColorRect.new()
	faixa.color = Color(Tema.FITA, 0.8)
	faixa.position = Vector2(0, 0)
	faixa.size = Vector2(1920, 80)
	camada.add_child(faixa)
	legenda = Label.new()
	legenda.position = Vector2(24, 8)
	legenda.add_theme_font_override("font", Tema.archivo(700))
	legenda.add_theme_font_size_override("font_size", 40)
	legenda.add_theme_color_override("font_color", Tema.ETIQUETA)
	camada.add_child(legenda)
	var baixo := ColorRect.new()
	baixo.color = Color(Tema.FITA, 0.8)
	baixo.position = Vector2(0, 1080 - 80)
	baixo.size = Vector2(1920, 80)
	camada.add_child(baixo)
	rodape = Label.new()
	rodape.position = Vector2(24, 1080 - 72)
	rodape.add_theme_font_override("font", Tema.archivo(500))
	rodape.add_theme_font_size_override("font_size", 40)
	rodape.add_theme_color_override("font_color", Tema.ETIQUETA)
	camada.add_child(rodape)
