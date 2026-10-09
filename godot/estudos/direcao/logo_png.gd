extends SceneTree
## Os PNG do logo refeitos a partir do SVG (o SVG manda): 512 px para o
## ícone do projeto e o título, 256 px para o resto, sem ferramenta de fora.
## Também grava a prova de 64 px (os quatro martelos têm de se contar).
##
##   godot --headless --path godot -s res://estudos/direcao/logo_png.gd [-- <pasta da prova>]

func _init() -> void:
	var svg := FileAccess.get_file_as_string("res://assets/forja-logo.svg")
	for par in [[1.0, "res://assets/forja-logo.png"], [0.5, "res://assets/forja-logo-256.png"]]:
		var img := Image.new()
		var err := img.load_svg_from_string(svg, par[0])
		assert(err == OK)
		img.save_png(ProjectSettings.globalize_path(par[1]))
		print("logo: ", par[1], " ", img.get_size())
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		for nome in ["forja-logo", "forja-logo-etiqueta"]:
			var img := Image.new()
			img.load_svg_from_string(FileAccess.get_file_as_string("res://assets/%s.svg" % nome), 0.125)
			img.save_png(args[0].path_join(nome + "-64.png"))
			print("prova: ", nome, "-64 ", img.get_size())
	quit()
