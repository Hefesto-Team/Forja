extends SceneTree

const Fita := preload("res://estudos/direcao/fita.gd")
const RAIZ := "res://estudos/direcao/kenney"


func _init() -> void:
	for pacote in DirAccess.get_directories_at(RAIZ):
		var papel: String = Fita.PAPEL_DO_PACOTE.get(pacote, "")
		if papel == "":
			printerr("pacote sem papel: ", pacote)
			continue
		var origem := ProjectSettings.globalize_path("%s/%s/Textures/colormap-kenney.png" % [RAIZ, pacote])
		var destino := ProjectSettings.globalize_path("%s/%s/Textures/colormap.png" % [RAIZ, pacote])
		var img := Image.load_from_file(origem)
		var pronta := Fita.recolorir(img, papel)
		if pacote == "mini-dungeon-personagens":
			pronta = Fita.trocar_matiz(pronta, Fita.PELE_ORC, -0.05)
		pronta.save_png(destino)
		print("%s (%s) -> %s" % [pacote, papel, destino])
		if pacote == "mini-characters":
			for parte in ["tecido", "couro"]:
				var d := ProjectSettings.globalize_path("%s/%s/Textures/colormap-%s.png" % [RAIZ, pacote, parte])
				Fita.recolorir(img, parte, papel).save_png(d)
				print("%s (%s) -> %s" % [pacote, parte, d])
	quit(0)
