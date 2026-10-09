extends RefCounted
## O corpo do cavaleiro em três peças (04, o corte): a cabeça de um
## personagem, o superior de outro, o inferior de um terceiro, no mesmo
## esqueleto de 7 ossos. O esqueleto e as poses de descanso são os mesmos nos
## 12 (e no orc), então qualquer cabeça encaixa em qualquer tronco.
##
## Serve à montagem (Montar) e ao cavaleiro inteiro do Mundo, que é o mesmo
## personagem nas três peças: assim todo cavaleiro do estudo tem cada peça na
## faixa dela e o acento à parte.

const Cortar := preload("res://estudos/direcao/cavaleiro/cortar.gd")


## Tira a head-mesh e a body-mesh do modelo e põe as três peças no lugar.
## `pecas` = [cabeça, superior, inferior] pelo personagem ("male-c").
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
