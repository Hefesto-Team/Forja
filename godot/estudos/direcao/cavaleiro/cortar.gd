extends SceneTree
## O corte do cavaleiro (04, o corte): cada personagem do Mini Characters vira
## três malhas, cabeça, tronco superior e tronco inferior, pelo osso de cada
## triângulo. Na body-mesh nenhum triângulo é misto (o osso do primeiro peso
## de cada vértice é o mesmo nos três), então o corte não abre buraco.
##
## Como biblioteca: Cortar.partes("female-b") devolve as três malhas, a pele
## e a caixa de cada parte.
## Como script, imprime a contagem de triângulos de cada parte:
##
##   godot --headless --path godot -s res://estudos/direcao/cavaleiro/cortar.gd

const RAIZ := "res://estudos/direcao/kenney/mini-characters/character-%s.glb"
const PERSONAGENS := ["female-a", "female-b", "female-c", "female-d", "female-e", "female-f",
	"male-a", "male-b", "male-c", "male-d", "male-e", "male-f"]
## Os ossos de cada parte do corpo (o índice no esqueleto de 7 ossos).
const OSSOS := {"superior": [3, 4, 5], "inferior": [1, 2]}
const NOME_DO_OSSO := ["root", "leg-left", "leg-right", "torso", "arm-left", "arm-right", "head"]

static var _cache := {}


## As três malhas de um personagem: {"cabeca", "superior", "inferior"} são
## ArrayMesh; "pele" é o Skin da body-mesh; "contagem" é {osso: triângulos}.
static func partes(personagem: String) -> Dictionary:
	if _cache.has(personagem):
		return _cache[personagem]
	var cena: Node = (load(RAIZ % personagem) as PackedScene).instantiate()
	var cabeca: MeshInstance3D = cena.find_child("head-mesh", true, false)
	var corpo: MeshInstance3D = cena.find_child("body-mesh", true, false)
	var arr: Array = corpo.mesh.surface_get_arrays(0)
	var mat: Material = corpo.mesh.surface_get_material(0)
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var ossos: PackedInt32Array = arr[Mesh.ARRAY_BONES]
	var por_parte := {"superior": PackedInt32Array(), "inferior": PackedInt32Array()}
	var contagem := {}
	for t in idx.size() / 3:
		var o := ossos[idx[t * 3] * 4]
		contagem[o] = int(contagem.get(o, 0)) + 1
		for parte in OSSOS:
			if o in OSSOS[parte]:
				por_parte[parte].append_array([idx[t * 3], idx[t * 3 + 1], idx[t * 3 + 2]])
	var out := {"pele": corpo.skin, "pele_cabeca": cabeca.skin, "contagem": contagem,
		"tri_cabeca": cabeca.mesh.surface_get_array_index_len(0) / 3}
	out["cabeca"] = cabeca.mesh
	# a caixa de cada parte na pose de descanso (só os vértices que a parte usa)
	out["caixa"] = {"cabeca": cabeca.mesh.get_aabb()}
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for parte in por_parte:
		var cx := AABB(vs[por_parte[parte][0]], Vector3.ZERO)
		for k in por_parte[parte]:
			cx = cx.expand(vs[k])
		out["caixa"][parte] = cx
	for parte in por_parte:
		var a := arr.duplicate()
		a[Mesh.ARRAY_INDEX] = por_parte[parte]
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
		m.surface_set_material(0, mat)
		out[parte] = m
	cena.free()
	_cache[personagem] = out
	return out


func _init() -> void:
	print("personagem   cabeça  torso  braço-e  braço-d  perna-e  perna-d   superior  inferior")
	for p in PERSONAGENS:
		var d := partes(p)
		var c: Dictionary = d.contagem
		var sup := int(c.get(3, 0)) + int(c.get(4, 0)) + int(c.get(5, 0))
		var inf := int(c.get(1, 0)) + int(c.get(2, 0))
		print("%-11s  %6d  %5d  %7d  %7d  %7d  %7d   %8d  %8d" % [p, d.tri_cabeca, c.get(3, 0), c.get(4, 0),
			c.get(5, 0), c.get(1, 0), c.get(2, 0), sup, inf])
	quit()
