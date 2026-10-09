extends SceneTree
## A tabela dos contatos (PRODUCAO, item 9): para cada uma das 32 animações
## do Mini Characters, o instante em que o golpe acerta ou o pé pousa. É
## o número que a sala usa para casar o impacto com o tempo da música.
##
##   godot --headless --path godot -s res://estudos/direcao/medir_contatos.gd
##
## Grava docs/jogo/arte/dados/contatos.csv. Amostra a 120 quadros por
## segundo, sem relógio e sem acaso: rodar duas vezes dá a mesma tabela.
##
## O golpe (ataque, interação, pegar, tiro): o quadro de maior velocidade
## angular do osso que bate (o braço; a perna no chute). O passo e o pulo: o
## quadro em que o pé chega mais baixo (no pulo, depois do ponto mais alto).
## As outras (parado, sentado, emoções, a cadeira) não têm contato.

const MODELO := "res://estudos/direcao/kenney/mini-characters/character-male-a.glb"
const SAIDA := "res://../docs/jogo/arte/dados/contatos.csv"
const FPS := 120.0


func _init() -> void:
	var m: Node3D = (load(MODELO) as PackedScene).instantiate()
	root.add_child(m)
	var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	var esq: Skeleton3D = m.find_child("Skeleton3D", true, false)
	var corpo: MeshInstance3D = m.find_child("body-mesh", true, false)
	var linhas := PackedStringArray(["animacao,duracao_s,contato_s,osso,metodo"])
	var nomes := Array(ap.get_animation_list())
	nomes.sort()
	for nome in nomes:
		var a := ap.get_animation(nome)
		var dur := a.length
		var r := _medir(ap, esq, corpo, String(nome), dur)
		linhas.append("%s,%.3f,%s,%s,%s" % [nome, dur, r[0], r[1], r[2]])
	var f := FileAccess.open(ProjectSettings.globalize_path(SAIDA), FileAccess.WRITE)
	f.store_string("\n".join(linhas) + "\n")
	f.close()
	print("\n".join(linhas))
	quit()


## A pose no instante t, lida das trilhas da animação (sem o mixer: fora do
## laço de quadros ele não aplica nada, e assim o resultado não depende dele).
func _pose(ap: AnimationPlayer, esq: Skeleton3D, nome: String, t: float) -> void:
	var a := ap.get_animation(nome)
	esq.reset_bone_poses()
	for tr in a.get_track_count():
		var b := esq.find_bone(a.track_get_path(tr).get_concatenated_subnames())
		if b < 0:
			continue
		match a.track_get_type(tr):
			Animation.TYPE_ROTATION_3D:
				esq.set_bone_pose_rotation(b, a.rotation_track_interpolate(tr, t))
			Animation.TYPE_POSITION_3D:
				esq.set_bone_pose_position(b, a.position_track_interpolate(tr, t))
			Animation.TYPE_SCALE_3D:
				esq.set_bone_pose_scale(b, a.scale_track_interpolate(tr, t))


func _medir(ap: AnimationPlayer, esq: Skeleton3D, corpo: MeshInstance3D, nome: String, dur: float) -> Array:
	var n := int(floor(dur * FPS))
	if n < 2:
		return ["", "", "sem contato"]
	var lado := "right" if nome.contains("right") else "left"
	if nome.begins_with("attack-kick"):
		return _golpe(ap, esq, nome, n, "leg-" + lado)
	if nome.begins_with("attack-melee") or nome.begins_with("interact") or nome.ends_with("-shoot"):
		var osso := "arm-" + lado
		if nome.begins_with("holding-both"):
			osso = "arm-right"
		return _golpe(ap, esq, nome, n, osso)
	if nome == "pick-up":
		return _golpe(ap, esq, nome, n, "arm-right")
	if nome in ["walk", "sprint"]:
		return _pe(ap, esq, corpo, nome, n, false)
	if nome == "jump":
		return _pe(ap, esq, corpo, nome, n, true)
	return ["", "", "sem contato"]


## O quadro de maior velocidade angular do osso (a rotação entre dois quadros).
func _golpe(ap: AnimationPlayer, esq: Skeleton3D, nome: String, n: int, osso: String) -> Array:
	var b := esq.find_bone(osso)
	var antes := Quaternion()
	var melhor := -1.0
	var quando := 0.0
	for i in n + 1:
		var t := i / FPS
		_pose(ap, esq, nome, t)
		var q := _global(esq, b).basis.get_rotation_quaternion()
		if i > 0:
			var v := antes.angle_to(q) * FPS
			# o meio do intervalo é o quadro do contato; empate fica com o primeiro
			if v > melhor + 1e-4:
				melhor = v
				quando = t
		antes = q
	return ["%.3f" % quando, osso, "maior velocidade angular (%.0f graus/s)" % rad_to_deg(melhor)]


## O quadro em que o pé chega mais baixo: o vértice mais baixo da malha que
## cada perna move, no espaço do esqueleto. No pulo, só depois do ponto mais
## alto (a aterrissagem, não o chão de onde ele saiu).
func _pe(ap: AnimationPlayer, esq: Skeleton3D, corpo: MeshInstance3D, nome: String, n: int, pulo: bool) -> Array:
	var pernas := {}
	for lado in ["left", "right"]:
		pernas["leg-" + lado] = _vertices(esq, corpo, "leg-" + lado)
	var alturas := []
	var ossos := []
	for i in n + 1:
		_pose(ap, esq, nome, i / FPS)
		var baixo := INF
		var qual := ""
		for o in pernas:
			var pose := _global(esq, esq.find_bone(o))
			for v in pernas[o]:
				var y: float = (pose * v).y
				if y < baixo - 1e-6:
					baixo = y
					qual = o
		alturas.append(baixo)
		ossos.append(qual)
	var de := 0
	if pulo:
		var alto := -INF
		for i in alturas.size():
			if alturas[i] > alto + 1e-6:
				alto = alturas[i]
				de = i
	var melhor := de
	for i in range(de, alturas.size()):
		if alturas[i] < alturas[melhor] - 1e-6:
			melhor = i
	var met := "pé mais baixo depois do ponto mais alto" if pulo else "pé mais baixo"
	return ["%.3f" % (melhor / FPS), ossos[melhor], met]


## Os vértices que a perna move (peso maior que 0,5), já no espaço do osso.
func _vertices(esq: Skeleton3D, mi: MeshInstance3D, osso: String) -> PackedVector3Array:
	var skin: Skin = mi.skin
	var b := esq.find_bone(osso)
	var binds := {}
	for i in skin.get_bind_count():
		var bb := skin.get_bind_bone(i)
		if bb == b or (bb < 0 and String(skin.get_bind_name(i)) == osso):
			binds[i] = true
	var arr := mi.mesh.surface_get_arrays(0)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ossos: PackedInt32Array = arr[Mesh.ARRAY_BONES]
	var pesos: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
	var k := ossos.size() / vs.size()
	var out := PackedVector3Array()
	for v in vs.size():
		for j in k:
			if binds.has(ossos[v * k + j]) and pesos[v * k + j] > 0.5:
				out.append(skin.get_bind_pose(ossos[v * k + j]) * vs[v])
	return out


## A pose global do osso, montada pelos pais a partir das poses locais (a
## global do esqueleto fica em cache fora do laço de quadros).
func _global(esq: Skeleton3D, b: int) -> Transform3D:
	var t := esq.get_bone_pose(b)
	var p := esq.get_bone_parent(b)
	return t if p < 0 else _global(esq, p) * t
