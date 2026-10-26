class_name Enquadramento
extends RefCounted

const MARGEM := 0.15
const ALTURA_DO_BONECO := 1.6


static func grupo(alvos: Array, dir: Vector3, dist: Vector2, tan_v: float, tan_h: float) -> Array:
	var pontos := _com_cabeca(alvos)
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	for p in pontos:
		mn = mn.min(p)
		mx = mx.max(p)
	return _caber(pontos, (mn + mx) * 0.5, dir, dist, tan_v, tan_h)


static func corrida(alvos: Array, frente: Vector3, dir: Vector3, dist: Vector2, tan_v: float, tan_h: float) -> Array:
	var lider: Vector3 = alvos[0]
	var ultimo: Vector3 = alvos[0]
	for a in alvos:
		if a.dot(frente) > lider.dot(frente):
			lider = a
		if a.dot(frente) < ultimo.dot(frente):
			ultimo = a
	var centro := ultimo.lerp(lider, 0.65) + Vector3(0, ALTURA_DO_BONECO * 0.5, 0)
	return _caber(_com_cabeca([lider, ultimo]), centro, dir, dist, tan_v, tan_h)


static func puxar(posicoes: Array, frente: Vector3, alcance: float) -> Array:
	var topo := -INF
	for p in posicoes:
		topo = maxf(topo, p.dot(frente))
	var saida: Array = []
	for p in posicoes:
		var atras: float = topo - p.dot(frente)
		saida.append(p + frente * (atras - alcance) if atras > alcance else p)
	return saida


static func _com_cabeca(alvos: Array) -> Array:
	var pontos: Array = []
	for a in alvos:
		pontos.append(a)
		pontos.append(a + Vector3(0, ALTURA_DO_BONECO, 0))
	return pontos


static func _caber(pontos: Array, centro: Vector3, dir: Vector3, dist: Vector2, tan_v: float, tan_h: float) -> Array:
	var f := -dir
	var r := f.cross(Vector3.UP).normalized()
	var u := r.cross(f)
	var k := 1.0 + MARGEM
	var d := dist.x
	for p in pontos:
		var v: Vector3 = p - centro
		var z0 := v.dot(f)
		d = maxf(d, absf(v.dot(r)) * k / tan_h - z0)
		d = maxf(d, absf(v.dot(u)) * k / tan_v - z0)
	d = minf(d, dist.y)
	return [centro + dir * d, centro]
