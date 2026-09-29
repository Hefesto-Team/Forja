extends SceneTree
## Os avisos de licença do Godot e de tudo o que ele embute (FreeType, HarfBuzz,
## e o resto), tirados do próprio binário: a exportação junta este texto ao
## LICENCAS-DE-TERCEIROS.md e o põe ao lado do jogo.
##
##   godot --headless -s scripts/licencas.gd -- <arquivo de saída>


func _init() -> void:
	var saida: String = OS.get_cmdline_user_args()[0]
	var t := "Godot Engine\n============\n\n" + Engine.get_license_text() + "\n\n"
	var info := Engine.get_license_info()
	for nome in info:
		t += "%s\n%s\n\n%s\n\n" % [nome, "-".repeat(str(nome).length()), info[nome]]
	var partes := Engine.get_copyright_info()
	t += "As partes do Godot e os seus autores\n====================================\n\n"
	for p in partes:
		t += "%s\n" % p.name
		for parte in p.parts:
			t += "  arquivos: %s\n  licença: %s\n" % [", ".join(parte.files), parte.license]
			for c in parte.copyright:
				t += "  © %s\n" % c
		t += "\n"
	var f := FileAccess.open(saida, FileAccess.WRITE)
	f.store_string(t)
	f.close()
	quit(0)
