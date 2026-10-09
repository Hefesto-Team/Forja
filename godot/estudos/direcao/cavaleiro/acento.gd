extends RefCounted
## O acento do cavaleiro (04, a peça se distingue): o néon do dono mora numa
## malha à parte, nunca num tom do corpo. Cada acento é recortado da própria
## peça (os triângulos do osso dela, cortados por planos), descolado 0,0012
## pela normal da face e preso à mesma pele, para seguir a animação.
##
##   o friso do superior: faixa de 0,010 na barra e na gola do osso `torso`
##   (a gola logo abaixo do pescoço, y 0,343);
##   a costura do inferior: linha de 0,008 no lado de fora de cada perna.
##
## Medidas nas unidades do personagem (0,67 de altura no male-a).

const Fita := preload("res://estudos/direcao/fita.gd")

const FRISO := 0.010
const COSTURA := 0.008
const DESCOLA := 0.0012
const ENERGIA := 1.6
## Onde a cabeça começa: o y do osso `head` em descanso (Racas.PESCOCO).
const PESCOCO := 0.343


## Os triângulos de `malha` cujo primeiro vértice pesa nos `ossos`, que
## passam no `filtro` (pela normal da face) e cortados pelos `planos`
## ([normal, d]: fica o que tem normal·v >= d). Devolve [posições, normais,
## ossos, pesos] por vértice, já descolados.
static func recortar(malha: Mesh, ossos: Array, filtro: Callable, planos: Array) -> Array:
	var arr := malha.surface_get_arrays(0)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ob: PackedInt32Array = arr[Mesh.ARRAY_BONES]
	var ow: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var k := ob.size() / vs.size()
	var out := [PackedVector3Array(), PackedVector3Array(), PackedInt32Array(), PackedFloat32Array()]
	for t in idx.size() / 3:
		var i0 := idx[t * 3]
		if not ob[i0 * k] in ossos:
			continue
		var a := vs[i0]
		var b := vs[idx[t * 3 + 1]]
		var c := vs[idx[t * 3 + 2]]
		var fn := (c - a).cross(b - a)
		if fn.length() < 1e-9:
			continue
		fn = fn.normalized()
		var nv: Vector3 = (arr[Mesh.ARRAY_NORMAL] as PackedVector3Array)[i0]
		if fn.dot(nv) < 0.0:
			fn = -fn
		if not filtro.call(fn):
			continue
		var pol: Array = [a, b, c]
		for pl in planos:
			pol = _cortar(pol, pl[0], pl[1])
			if pol.size() < 3:
				break
		if pol.size() < 3:
			continue
		for j in range(1, pol.size() - 1):
			for v in [pol[0], pol[j], pol[j + 1]]:
				out[0].append(v + fn * DESCOLA)
				out[1].append(fn)
				for q in 4:
					out[2].append(ob[i0 * k + q] if q < k else 0)
					out[3].append(ow[i0 * k + q] if q < k else 0.0)
	return out


static func _cortar(pol: Array, n: Vector3, d: float) -> Array:
	var out := []
	for i in pol.size():
		var a: Vector3 = pol[i]
		var b: Vector3 = pol[(i + 1) % pol.size()]
		var da := n.dot(a) - d
		var db := n.dot(b) - d
		if da >= 0.0:
			out.append(a)
		if (da >= 0.0) != (db >= 0.0):
			out.append(a.lerp(b, da / (da - db)))
	return out


## A caixa dos vértices de `malha` que pesam nos `ossos` (acima de `y_min`).
static func caixa(malha: Mesh, ossos: Array, y_min := -1.0) -> AABB:
	var arr := malha.surface_get_arrays(0)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ob: PackedInt32Array = arr[Mesh.ARRAY_BONES]
	var k := ob.size() / vs.size()
	var cx := AABB()
	var primeiro := true
	for i in vs.size():
		if not ob[i * k] in ossos or vs[i].y < y_min:
			continue
		if primeiro:
			cx = AABB(vs[i], Vector3.ZERO)
			primeiro = false
		else:
			cx = cx.expand(vs[i])
	return cx


## O friso: a barra (o y mais baixo do torso) e a gola (o mais alto), nas
## faces de pé.
static func friso(superior: Mesh) -> Array:
	var cx := caixa(superior, [3])
	var em_pe := func(fn: Vector3) -> bool: return absf(fn.y) < 0.5
	var barra := recortar(superior, [3], em_pe, [[Vector3.DOWN, -(cx.position.y + FRISO)]])
	return _somar([barra, gola(superior)])


## Só a gola do friso: a faixa de 0,010 logo abaixo do pescoço, que marca o
## corte entre o rosto e o superior quando os dois têm L parecida (04, o
## critério do rosto). No y mais alto do torso, ou no pescoço se a peça sobe
## além dele: a gola em pé da Jaqueta preta (até y 0,385), as alças do
## Macacão e da Regata verde (até 0,357) ficam atrás da cabeça, e a faixa lá
## em cima não se via de frente.
static func gola(superior: Mesh) -> Array:
	var cx := caixa(superior, [3])
	var topo := minf(cx.end.y, PESCOCO)
	var em_pe := func(fn: Vector3) -> bool: return absf(fn.y) < 0.5
	return recortar(superior, [3], em_pe, [[Vector3.UP, topo - FRISO], [Vector3.DOWN, -topo]])


## A costura: na frente de cada perna, a faixa de 0,008 junto ao lado de
## fora; no lado de fora, a linha de 0,008 no meio da profundidade da perna.
static func costura(inferior: Mesh) -> Array:
	var partes_ := []
	for osso in [1, 2]:
		var toda := caixa(inferior, [osso])
		if toda.size == Vector3.ZERO:
			continue
		# o lado de fora pela calça, não pelo sapato (acima de um quarto da perna)
		var cx := caixa(inferior, [osso], toda.position.y + toda.size.y * 0.25)
		var s := signf(toda.get_center().x)
		var fora := maxf(s * cx.position.x, s * cx.end.x)
		var zc := cx.get_center().z
		var frente := func(fn: Vector3) -> bool: return fn.z > 0.5
		var lado := func(fn: Vector3) -> bool: return s * fn.x > 0.5
		partes_.append(recortar(inferior, [osso], frente, [[Vector3(s, 0, 0), fora - COSTURA]]))
		partes_.append(recortar(inferior, [osso], lado, [[Vector3.BACK, zc - COSTURA * 0.5],
			[Vector3.FORWARD, -(zc + COSTURA * 0.5)]]))
	return _somar(partes_)


static func _somar(lista: Array) -> Array:
	var out := [PackedVector3Array(), PackedVector3Array(), PackedInt32Array(), PackedFloat32Array()]
	for p in lista:
		for i in 4:
			out[i].append_array(p[i])
	return out


## A malha de acento, pronta para pôr no esqueleto.
static func malha(dados: Array) -> ArrayMesh:
	var m := ArrayMesh.new()
	if (dados[0] as PackedVector3Array).is_empty():
		return m
	var a := []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = dados[0]
	a[Mesh.ARRAY_NORMAL] = dados[1]
	a[Mesh.ARRAY_BONES] = dados[2]
	a[Mesh.ARRAY_WEIGHTS] = dados[3]
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	return m


## A área de frente (projetada no plano xy, só as faces que olham para +z).
static func area_frente(vs: PackedVector3Array, ns: PackedVector3Array) -> float:
	var s := 0.0
	for t in vs.size() / 3:
		if ns[t * 3].z <= 0.0:
			continue
		var a := vs[t * 3]
		var b := vs[t * 3 + 1]
		var c := vs[t * 3 + 2]
		s += absf((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)) * 0.5
	return s


## Põe o friso e a costura num esqueleto que já tem body-sup e body-inf.
static func vestir(esq: Skeleton3D, cor: Color, energia := ENERGIA) -> void:
	for par in [["body-sup", "acento-friso", true], ["body-inf", "acento-costura", false]]:
		if not esq.has_node(NodePath(par[0])):
			continue
		var base: MeshInstance3D = esq.get_node(NodePath(par[0]))
		var dados := friso(base.mesh) if par[2] else costura(base.mesh)
		var mi := MeshInstance3D.new()
		mi.name = par[1]
		mi.mesh = malha(dados)
		mi.skin = base.skin
		mi.transform = base.transform
		mi.material_override = Fita.neon(cor, energia)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = base.visible
		esq.add_child(mi)
		mi.skeleton = mi.get_path_to(esq)
