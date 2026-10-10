class_name Montar
extends RefCounted
## O corpo do cavaleiro em três peças (G13; arte/04, o corte): a cabeça de um
## personagem do Mini Characters, o superior de outro, o inferior de um
## terceiro, no mesmo esqueleto de 7 ossos. Os 12 têm o mesmo esqueleto e as
## mesmas poses de descanso: qualquer cabeça encaixa em qualquer tronco. As
## peças saem do `godot/testes/cortar_pecas.gd`, uma vez.

const PECAS := "res://assets/kenney/mini-characters/pecas/%s-%s.res"
## As malhas de cada parte no esqueleto, na ordem [cabeça, superior, inferior].
const MALHAS := ["head", "body-sup", "body-inf"]


## Troca a head-mesh e a body-mesh do Mini Characters `m` por três peças
## cortadas: [cabeça, superior, inferior], cada uma o nome do personagem.
## Cria os MeshInstance3D "head", "body-sup" e "body-inf" no Skeleton3D, com
## o transform da body-mesh antiga.
static func trocar(m: Node3D, pecas: Array) -> Skeleton3D:
	var esq: Skeleton3D = m.find_child("Skeleton3D", true, false)
	var molde: MeshInstance3D = m.find_child("body-mesh", true, false)
	if esq == null or molde == null:
		return esq
	var xf := molde.transform
	for velho in [m.find_child("head-mesh", true, false), molde]:
		if velho:
			velho.get_parent().remove_child(velho)
			velho.free()
	for k in 3:
		parte(esq, k, str(pecas[k]), xf)
	return esq


## Põe (ou troca) a malha da parte `k` (0 cabeça, 1 superior, 2 inferior) do personagem no esqueleto.
static func parte(esq: Skeleton3D, k: int, personagem: String, xf := Transform3D.IDENTITY) -> MeshInstance3D:
	var velho := esq.get_node_or_null(MALHAS[k]) as MeshInstance3D
	if velho:
		xf = velho.transform
		esq.remove_child(velho)
		velho.free()
	var mi := MeshInstance3D.new()
	mi.name = MALHAS[k]
	mi.mesh = load(PECAS % [personagem, ["cabeca", "superior", "inferior"][k]])
	mi.skin = load(PECAS % [personagem, "pele-cabeca" if k == 0 else "pele"])
	mi.transform = xf
	esq.add_child(mi)
	mi.skeleton = mi.get_path_to(esq)
	return mi


## O punho, no espaço do esqueleto e na pose de agora: o meio do quarto mais
## distante do ombro entre os vértices do superior que o osso do braço move. O
## eixo dos ossos dos Mini Characters não corre ao longo do braço, por isso
## o punho sai da malha, não do osso.
static func mao(esq: Skeleton3D, osso: String) -> Vector3:
	var mi: MeshInstance3D = esq.get_node("body-sup")
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
	var pose := esq.get_bone_global_pose(b)
	var pts := []
	for v in vs.size():
		var melhor := 0
		for j in k:
			if pesos[v * k + j] > pesos[v * k + melhor]:
				melhor = j
		var bi := ossos[v * k + melhor]
		if binds.has(bi) and pesos[v * k + melhor] > 0.5:
			pts.append(pose * skin.get_bind_pose(bi) * vs[v])
	if pts.is_empty():
		return pose.origin
	pts.sort_custom(func(a, c): return a.distance_squared_to(pose.origin) > c.distance_squared_to(pose.origin))
	var n := maxi(1, pts.size() / 4)
	var soma := Vector3.ZERO
	for i in n:
		soma += pts[i]
	return soma / n
