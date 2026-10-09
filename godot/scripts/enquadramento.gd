class_name Enquadramento
extends RefCounted
## As contas da câmera dos quatro (G05): estáticas, sem nó e sem viewport. Dado onde estão os cavaleiros, a direção
## que a sala desenhou e as tangentes da lente, devolvem [posição, olhar] com todos na tela.

const MARGEM := 0.15
const ALTURA_DO_BONECO := 1.6  ## cobre o cavaleiro mais alto das quatro raças (1,55 m com a antena)


## [posição, olhar] que põe todos os alvos (os pés e a cabeça) na tela.
static func grupo(alvos: Array, dir: Vector3, dist: Vector2, tan_v: float, tan_h: float) -> Array:
	var pontos := _com_cabeca(alvos)
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	for p in pontos:
		mn = mn.min(p)
		mx = mx.max(p)
	return _caber(pontos, (mn + mx) * 0.5, dir, dist, tan_v, tan_h)


## O líder e o último sempre na tela; o centro puxado para o líder (65 %).
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


## As posições com quem ficou mais de `alcance` atrás do líder trazido para a borda.
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


## A menor distância (entre dist.x e dist.y) em que todos os pontos cabem com a margem.
## Câmera em C = centro + dir · d, olhando para o centro: o ponto p tem profundidade
## (p − centro)·f + d, com f = −dir; cabe se |x| e |y| ≤ profundidade × tan / (1 + MARGEM).
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
