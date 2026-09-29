extends SceneTree
## A cor nunca sozinha (o checklist do estudo 02, item 16): passa as fotos das
## telas por simuladores de protanopia, deuteranopia e tritanopia, e grava uma
## prancha com as quatro versões lado a lado para a revisão. As matrizes são
## as de Machado, Oliveira e Fernandes (2009), severidade 1, aplicadas em RGB
## linear.
##
##   godot --headless -s scripts/daltonismo.gd -- <pasta com os PNG> <pasta de saída>

const MATRIZES := {
	"protanopia": [0.152286, 1.052583, -0.204868, 0.114503, 0.786281, 0.099216, -0.003882, -0.048116, 1.051998],
	"deuteranopia": [0.367322, 0.860646, -0.227968, 0.280085, 0.672501, 0.047413, -0.011820, 0.042940, 0.968881],
	"tritanopia": [1.255528, -0.076749, -0.178779, -0.078411, 0.930809, 0.147602, 0.004733, 0.691367, 0.303900],
}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("uso: godot --headless -s scripts/daltonismo.gd -- <pasta dos PNG> <pasta de saída>")
		quit(2)
		return
	var entrada: String = args[0]
	var saida: String = args[1]
	DirAccess.make_dir_recursive_absolute(saida)
	var n := 0
	for f in DirAccess.get_files_at(entrada):
		if not f.ends_with(".png"):
			continue
		var img := Image.load_from_file(entrada.path_join(f))
		if img == null:
			continue
		img.convert(Image.FORMAT_RGB8)
		# metade do tamanho: a prancha 2×2 volta ao tamanho da foto
		img.resize(img.get_width() / 2, img.get_height() / 2, Image.INTERPOLATE_BILINEAR)
		var w := img.get_width()
		var h := img.get_height()
		var prancha := Image.create(w * 2, h * 2, false, Image.FORMAT_RGB8)
		prancha.blit_rect(img, Rect2i(0, 0, w, h), Vector2i(0, 0))
		var i := 1
		for nome in MATRIZES:
			var sim := _simular(img, MATRIZES[nome])
			prancha.blit_rect(sim, Rect2i(0, 0, w, h), Vector2i((i % 2) * w, (i / 2) * h))
			i += 1
		prancha.save_png(saida.path_join(f.get_basename() + "-daltonismo.png"))
		n += 1
		print("prancha: ", f)
	print("%d prancha(s) em %s (normal | protanopia / deuteranopia | tritanopia)" % [n, saida])
	quit(0)


static var _lin := PackedFloat32Array()


static func _linear(v: int) -> float:
	if _lin.is_empty():
		_lin.resize(256)
		for k in 256:
			var c := k / 255.0
			_lin[k] = c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)
	return _lin[v]


static func _srgb(c: float) -> int:
	c = clampf(c, 0.0, 1.0)
	var s := c * 12.92 if c <= 0.0031308 else 1.055 * pow(c, 1.0 / 2.4) - 0.055
	return int(round(s * 255.0))


static func _simular(img: Image, m: Array) -> Image:
	var dados := img.get_data()
	var out := PackedByteArray()
	out.resize(dados.size())
	for p in range(0, dados.size(), 3):
		var r := _linear(dados[p])
		var g := _linear(dados[p + 1])
		var b := _linear(dados[p + 2])
		out[p] = _srgb(m[0] * r + m[1] * g + m[2] * b)
		out[p + 1] = _srgb(m[3] * r + m[4] * g + m[5] * b)
		out[p + 2] = _srgb(m[6] * r + m[7] * g + m[8] * b)
	return Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGB8, out)
