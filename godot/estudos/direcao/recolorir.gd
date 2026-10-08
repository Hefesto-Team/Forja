extends SceneTree
## Recolore os colormaps dos pacotes do estudo pela regra da fita
## (Fita.GRADE / Fita.PAPEL_DO_PACOTE). O original da Kenney fica ao lado,
## como Textures/colormap-kenney.png, e nunca se edita; a cópia recolorida é
## a Textures/colormap.png, a que os .glb do pacote pedem.
##
##   godot --headless --path godot -s res://estudos/direcao/recolorir.gd

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
		Fita.recolorir(img, papel).save_png(destino)
		print("%s (%s) -> %s" % [pacote, papel, destino])
	quit(0)
