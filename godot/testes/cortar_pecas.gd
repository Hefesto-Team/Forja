extends SceneTree
## O corte do cavaleiro (G13; arte/04, o corte), uma vez, por script: cada um
## dos 12 do Mini Characters vira cabeça, superior e inferior, pelo osso de
## maior peso de cada vértice do triângulo. Grava em
## `res://assets/kenney/mini-characters/pecas/` as três `ArrayMesh` e as duas
## peles (`Skin`) de cada personagem: 12 × 5 = 60 arquivos. O orc do Mini
## Dungeon só entra na contagem.
##
##   "$GODOT" --headless --path godot -s res://testes/cortar_pecas.gd
##
## Sai com 1 se algum triângulo tem vértices em partes diferentes (o corte
## abriria um buraco), dizendo qual.

const RAIZ := "res://assets/kenney/mini-characters/character-%s.glb"
const ORC := "res://assets/kenney/mini-dungeon-personagens/character-orc.glb"
const SAIDA := "res://assets/kenney/mini-characters/pecas/"
const PERSONAGENS := ["female-a", "female-b", "female-c", "female-d", "female-e", "female-f",
	"male-a", "male-b", "male-c", "male-d", "male-e", "male-f"]
## Os ossos do esqueleto de 7: root 0, leg-left 1, leg-right 2, torso 3, arm-left 4, arm-right 5, head 6.
const OSSOS := {"superior": [3, 4, 5], "inferior": [1, 2]}


## O osso de maior peso do vértice `v`.
static func _osso(ossos: PackedInt32Array, pesos: PackedFloat32Array, v: int, k: int) -> int:
	var melhor := 0
	for j in k:
		if pesos[v * k + j] > pesos[v * k + melhor]:
			melhor = j
	return ossos[v * k + melhor]


## As partes de um personagem: {"cabeca", "superior", "inferior"} (ArrayMesh), "pele", "pele_cabeca" (Skin),
## "tri" (triângulos por parte) e "misturados".
static func partes(caminho: String) -> Dictionary:
	var cena: Node = (load(caminho) as PackedScene).instantiate()
	var cabeca: MeshInstance3D = cena.find_child("head-mesh", true, false)
	var corpo: MeshInstance3D = cena.find_child("body-mesh", true, false)
	var arr: Array = corpo.mesh.surface_get_arrays(0)
	var mat: Material = corpo.mesh.surface_get_material(0)
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var ossos: PackedInt32Array = arr[Mesh.ARRAY_BONES]
	var pesos: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var k := ossos.size() / vs.size()
	var por_parte := {"superior": PackedInt32Array(), "inferior": PackedInt32Array()}
	var misturados := 0
	for t in idx.size() / 3:
		var o := _osso(ossos, pesos, idx[t * 3], k)
		if _osso(ossos, pesos, idx[t * 3 + 1], k) != o or _osso(ossos, pesos, idx[t * 3 + 2], k) != o:
			misturados += 1
		for parte in OSSOS:
			if o in OSSOS[parte]:
				por_parte[parte].append_array([idx[t * 3], idx[t * 3 + 1], idx[t * 3 + 2]])
	var out := {"cabeca": cabeca.mesh, "pele": corpo.skin, "pele_cabeca": cabeca.skin, "misturados": misturados,
		"tri": {"cabeca": cabeca.mesh.surface_get_array_index_len(0) / 3}}
	for parte in por_parte:
		var a := arr.duplicate()
		a[Mesh.ARRAY_INDEX] = por_parte[parte]
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
		m.surface_set_material(0, mat)
		out[parte] = m
		out.tri[parte] = por_parte[parte].size() / 3
	cena.free()
	return out


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SAIDA)
	var falhou := false
	print("personagem   cabeça  superior  inferior  misturados")
	for p in PERSONAGENS + ["orc"]:
		var d := partes(ORC if p == "orc" else RAIZ % p)
		print("%-11s  %6d  %8d  %8d  %10d" % [p, d.tri.cabeca, d.tri.superior, d.tri.inferior, d.misturados])
		if int(d.misturados) > 0:
			printerr("FAIL %s: %d triângulo(s) com vértices em partes diferentes" % [p, d.misturados])
			falhou = true
		if p == "orc":
			continue
		var gravar := {"cabeca": d.cabeca, "superior": d.superior, "inferior": d.inferior, "pele": d.pele,
			"pele-cabeca": d.pele_cabeca}
		for nome in gravar:
			var res: Resource = gravar[nome].duplicate(true)
			var erro := ResourceSaver.save(res, SAIDA + "%s-%s.res" % [p, nome])
			if erro != OK:
				printerr("FAIL %s-%s.res: não gravou (%d)" % [p, nome, erro])
				falhou = true
	quit(1 if falhou else 0)
