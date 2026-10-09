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
		var pronta := Fita.recolorir(img, papel)
		# o orc: o verde da pele vira o PELE_ORC (o matiz e o croma; a luz de
		# cada degrau fica), para a cabeça e a mão serem da mesma pele
		if pacote == "mini-dungeon-personagens":
			pronta = Fita.trocar_matiz(pronta, Fita.PELE_ORC, -0.05)
		pronta.save_png(destino)
		print("%s (%s) -> %s" % [pacote, papel, destino])
		# o corpo do cavaleiro: o tronco superior em tecido, o inferior em
		# couro, a pele (a mão, a perna de fora) como a da cabeça (04, a peça se
		# distingue)
		if pacote == "mini-characters":
			for parte in ["tecido", "couro"]:
				var d := ProjectSettings.globalize_path("%s/%s/Textures/colormap-%s.png" % [RAIZ, pacote, parte])
				Fita.recolorir(img, parte, papel).save_png(d)
				print("%s (%s) -> %s" % [pacote, parte, d])
	quit(0)
