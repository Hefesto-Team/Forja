extends RefCounted

const Cortar := preload("res://estudos/direcao/cavaleiro/cortar.gd")


static func trocar(m: Node3D, pecas: Array) -> Skeleton3D:
	var esq: Skeleton3D = m.find_child("Skeleton3D", true, false)
	var molde: MeshInstance3D = m.find_child("body-mesh", true, false)
	var xf := molde.transform
	for velho in [m.find_child("head-mesh", true, false), molde]:
		velho.get_parent().remove_child(velho)
		velho.queue_free()
	var cab := Cortar.partes(pecas[0])
	var sup := Cortar.partes(pecas[1])
	var inf := Cortar.partes(pecas[2])
	parte(esq, "head", cab.cabeca, cab.pele_cabeca, xf)
	parte(esq, "body-sup", sup.superior, sup.pele, xf)
	parte(esq, "body-inf", inf.inferior, inf.pele, xf)
	return esq


static func parte(esq: Skeleton3D, nome: String, malha: Mesh, pele: Skin, xf: Transform3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.mesh = malha
	mi.skin = pele
	mi.transform = xf
	esq.add_child(mi)
	mi.skeleton = mi.get_path_to(esq)
	return mi
