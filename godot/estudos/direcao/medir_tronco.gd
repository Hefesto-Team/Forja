extends SceneTree
## O superior que a cabeça deixa à vista (04, as raças: a cabeça e o
## superior). Precisa de tela (conta píxeis), pela tela virtual:
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 \
##       --audio-driver Dummy --path godot -s res://estudos/direcao/medir_tronco.gd
##
## Para cada raça, cada um dos 12 superiores e cada pose (em pé: `idle`,
## `holding-right`, `holding-left`, o aceno `emote-yes` em quatro tempos e
## `interact-right`; sentada, na `wheelchair-deluxe`: `wheelchair-sit` e
## `wheelchair-look-left`), renderiza o cavaleiro de frente, câmera
## ortográfica, em cor chapada por parte, sem item, sem contorno e sem
## acento. Três fotos:
##
##   so          o superior sozinho (a área de frente dele);
##   sem_cabeca  o cavaleiro sem a cabeça (o que a cadeira, as pernas e os
##               braços deixam do superior);
##   tudo        o cavaleiro inteiro.
##
##   aparece_pct        tudo ÷ sem_cabeca: o critério do 04, piso de 60 %
##   aparece_total_pct  tudo ÷ so: quanto do superior se vê com tudo à frente
##
## Escreve `docs/jogo/arte/dados/tronco_aparece.csv` e, no terminal, o pior
## caso de cada raça em pé e sentada. A ordem é fixa: duas rodadas dão o
## mesmo CSV.

const Montar := preload("res://estudos/direcao/cavaleiro/montar.gd")
const Racas := preload("res://estudos/direcao/cavaleiro/racas.gd")
const Cortar := preload("res://estudos/direcao/cavaleiro/cortar.gd")

const SAIDA := "res://../docs/jogo/arte/dados/tronco_aparece.csv"
const PISO := 60.0
const TAM := 384
## [a pose, a fração da animação, a cadeira]
const POSES := [["idle", 0.5, ""], ["holding-right", 0.5, ""], ["holding-left", 0.5, ""],
	["emote-yes", 0.2, ""], ["emote-yes", 0.4, ""], ["emote-yes", 0.6, ""], ["emote-yes", 0.8, ""],
	["interact-right", 0.5, ""],
	["wheelchair-sit", 0.5, "wheelchair-deluxe"], ["wheelchair-look-left", 0.5, "wheelchair-deluxe"]]
const COR_SUP := Color(0, 1, 0)
const COR_CAB := Color(1, 0, 0)
const COR_RESTO := Color(0, 0, 1)

var vp: SubViewport
var duracao := {}


func _initialize() -> void:
	_rodar()


func _rodar() -> void:
	var molde: Node = (load("res://estudos/direcao/kenney/mini-characters/character-male-a.glb") as PackedScene).instantiate()
	var ap: AnimationPlayer = molde.find_child("AnimationPlayer", true, false)
	for pose in POSES:
		duracao[pose[0]] = ap.get_animation(pose[0]).length
	molde.free()
	vp = SubViewport.new()
	vp.size = Vector2i(TAM, TAM)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	we.environment = env
	vp.add_child(we)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.0
	cam.position = Vector3(0, 0.70, 9.0)
	cam.far = 30.0
	vp.add_child(cam)
	cam.current = true
	var linhas := ["raca,pose,tempo,superior,sup_px,aparece_pct,aparece_total_pct"]
	var pior := {}
	for raca in Racas.RACAS:
		for pose in POSES:
			for p in Cortar.PERSONAGENS:
				var r := await _medir(raca, pose, p)
				linhas.append("%s,%s,%.1f,%s,%d,%.1f,%.1f" % [raca, pose[0], pose[1], p, r[0], r[1], r[2]])
				var k: String = raca + ("|sentada" if pose[2] != "" else "|em pé")
				if not pior.has(k) or r[1] < pior[k][0]:
					pior[k] = [r[1], pose[0], p]
				var kt: String = k + "|total"
				if not pior.has(kt) or r[2] < pior[kt]:
					pior[kt] = r[2]
	var f := FileAccess.open(ProjectSettings.globalize_path(SAIDA), FileAccess.WRITE)
	f.store_string("\n".join(linhas) + "\n")
	f.close()
	print("tronco_aparece.csv: %d linhas" % (linhas.size() - 1))
	var falhou := false
	for raca in Racas.RACAS:
		for jeito in ["em pé", "sentada"]:
			var v: Array = pior[raca + "|" + jeito]
			falhou = falhou or v[0] < PISO
			print("%s, %s: a cabeça deixa %.1f %% no pior caso (%s, superior do %s) %s; com tudo à frente, o menor total é %.1f %%" % [
				raca, jeito, v[0], v[1], v[2], "ok" if v[0] >= PISO else "ABAIXO DE %.0f %%" % PISO,
				pior[raca + "|" + jeito + "|total"]])
	quit(1 if falhou else 0)


## [píxeis do superior sozinho, aparece_pct, aparece_total_pct]
func _medir(raca: String, pose: Array, p: String) -> Array:
	var palco := Node3D.new()
	vp.add_child(palco)
	var k := Montar.cavaleiro(palco, 0, Vector3.ZERO, [p, p, p], {"raca": raca, "cadeira": pose[2],
		"anim": pose[0], "t_anim": float(pose[1]) * float(duracao[pose[0]]), "anel": false, "acento": false,
		"contorno": false, "yaw": 0.0})
	var esq: Skeleton3D = k.get_meta("esqueleto")
	_chapar(k, COR_RESTO)
	for filho in esq.get_children():
		var nome := String(filho.name)
		if nome == "body-sup":
			_chapar(filho, COR_SUP)
		elif nome in ["head", "raca-cabeca"]:
			_chapar(filho, COR_CAB)
	var vis := {}
	var cab := {}
	for mi in k.find_children("*", "MeshInstance3D", true, false):
		vis[mi] = mi.visible
		cab[mi] = _da_cabeca(mi, esq)
	for mi in vis:
		mi.visible = vis[mi] and String(mi.name) == "body-sup"
	var so := await _contar()
	for mi in vis:
		mi.visible = vis[mi] and not cab[mi]
	var sem_cabeca := await _contar()
	for mi in vis:
		mi.visible = vis[mi]
	var tudo := await _contar()
	palco.queue_free()
	await process_frame
	return [so, 100.0 * tudo / maxf(sem_cabeca, 1.0), 100.0 * tudo / maxf(so, 1.0)]


## A malha é da cabeça: o `head` (a humana e o orc) ou o que pende do
## `raca-cabeca` (as cabeças por código).
func _da_cabeca(mi: Node, esq: Node) -> bool:
	var n := mi
	while n != null and n != esq:
		if String(n.name) in ["head", "raca-cabeca"]:
			return true
		n = n.get_parent()
	return false


func _chapar(n: Node, cor: Color) -> void:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = cor
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).material_override = m
	for mi in n.find_children("*", "GeometryInstance3D", true, false):
		(mi as GeometryInstance3D).material_override = m


## Os píxeis do superior (o verde) na foto.
func _contar() -> int:
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.g > 0.5 and c.r < 0.5 and c.b < 0.5:
				n += 1
	return n
