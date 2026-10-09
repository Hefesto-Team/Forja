extends RefCounted
## A bigorna própria da Forja, por código (ArrayMesh), nas unidades do Mini
## Characters (o cavaleiro tem 0,72 de altura). A forma é a do PRODUCAO, item
## 8: o rabo e a face chata com o furo quadrado, o chifre redondo de 8 lados
## separado do corpo por um vão, a cintura fina e a base com quatro pés
## chanfrados. Sombreamento chapado (uma normal por face); a cor sai do
## colormap do Survival Kit recolorido no papel "objeto", a mesma coluna de
## degradê da workbench-anvil (claro em cima, escuro embaixo).
##
##   var m := Bigorna.malha()     # ArrayMesh, menos de 600 triângulos

const ALTURA := 0.30
const FACE := Vector3(0.29, 0.0, 0.12)   ## comprimento × largura da face chata
const CHIFRE := 0.17                     ## de 0,10 a 0,015 de diâmetro
const FURO := 0.025
const CINTURA := Vector3(0.14, 0.08, 0.07)
const BASE := Vector3(0.30, 0.0, 0.18)
## A coluna do colormap da Kenney que a workbench-anvil usa no metal: o u fixo
## e o v de 0,775 (no topo) a 0,975 (no pé).
const UV_U := 0.344
const UV_V := Vector2(0.775, 0.975)

static var _malha: ArrayMesh
static var _tri := 0


static func _uv(p: Vector3) -> Vector2:
	return Vector2(UV_U, lerpf(UV_V.y, UV_V.x, clampf(p.y / ALTURA, 0.0, 1.0)))


## Um triângulo com a normal da face, virado para fora do centro da peça.
static func _t(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, centro: Vector3) -> void:
	var n := (b - a).cross(c - a).normalized()
	if n.dot((a + b + c) / 3.0 - centro) < 0.0:
		var x := b
		b = c
		c = x
		n = -n
	# o Godot desenha a frente no sentido horário
	for p in [a, c, b]:
		st.set_normal(n)
		st.set_uv(_uv(p))
		st.add_vertex(p)
	_tri += 1


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, centro: Vector3) -> void:
	_t(st, a, b, c, centro)
	_t(st, a, c, d, centro)


## Um sólido entre dois anéis de pontos (o de baixo e o de cima), com as tampas.
static func _lofte(st: SurfaceTool, baixo: Array, cima: Array, tampas := true) -> void:
	var centro := Vector3.ZERO
	for p in baixo + cima:
		centro += p
	centro /= float(baixo.size() + cima.size())
	var n := baixo.size()
	for i in n:
		var j := (i + 1) % n
		_quad(st, baixo[i], baixo[j], cima[j], cima[i], centro)
	if tampas:
		for i in range(1, n - 1):
			_t(st, baixo[0], baixo[i], baixo[i + 1], centro)
			_t(st, cima[0], cima[i], cima[i + 1], centro)


static func _ret(cx: float, y: float, cz: float, dx: float, dz: float, chanfro := 0.0) -> Array:
	if chanfro <= 0.0:
		return [Vector3(cx - dx, y, cz - dz), Vector3(cx + dx, y, cz - dz), Vector3(cx + dx, y, cz + dz), Vector3(cx - dx, y, cz + dz)]
	var c := chanfro
	return [Vector3(cx - dx + c, y, cz - dz), Vector3(cx + dx - c, y, cz - dz), Vector3(cx + dx, y, cz - dz + c),
		Vector3(cx + dx, y, cz + dz - c), Vector3(cx + dx - c, y, cz + dz), Vector3(cx - dx + c, y, cz + dz),
		Vector3(cx - dx, y, cz + dz - c), Vector3(cx - dx, y, cz - dz + c)]


static func malha() -> ArrayMesh:
	if _malha:
		return _malha
	_tri = 0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# o eixo x vai do rabo (−) à ponta do chifre (+); a face toda mede 0,46
	var x_rabo := -0.23
	var x_chifre := x_rabo + FACE.x          # onde a face acaba e o chifre começa
	var cx_face := x_rabo + FACE.x * 0.5
	var cx_base := cx_face - 0.01
	# os quatro pés: blocos com o canto de fora chanfrado (0 a 0,03)
	var pe := Vector3(0.05, 0.03, 0.045)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var px: float = cx_base + sx * (BASE.x * 0.5 - pe.x * 0.5)
			var pz: float = sz * (BASE.z * 0.5 - pe.z * 0.5)
			_lofte(st, _ret(px, 0.0, pz, pe.x * 0.5 - 0.008, pe.z * 0.5 - 0.008, 0.01), _ret(px, pe.y, pz, pe.x * 0.5, pe.z * 0.5, 0.012))
	# a base: a laje e o ombro que sobe até a cintura
	_lofte(st, _ret(cx_base, 0.03, 0.0, BASE.x * 0.5, BASE.z * 0.5, 0.02), _ret(cx_base, 0.05, 0.0, BASE.x * 0.5, BASE.z * 0.5, 0.02))
	_lofte(st, _ret(cx_base, 0.05, 0.0, BASE.x * 0.5 - 0.02, BASE.z * 0.5 - 0.02), _ret(cx_face, 0.09, 0.0, CINTURA.x * 0.5, CINTURA.z * 0.5), false)
	# a cintura (0,09 a 0,17)
	_lofte(st, _ret(cx_face, 0.09, 0.0, CINTURA.x * 0.5, CINTURA.z * 0.5), _ret(cx_face, 0.17, 0.0, CINTURA.x * 0.5, CINTURA.z * 0.5), false)
	# o corpo: abre da cintura para a face (0,17 a 0,25), e o bloco da face (0,25 a 0,30)
	_lofte(st, _ret(cx_face, 0.17, 0.0, CINTURA.x * 0.5, CINTURA.z * 0.5), _ret(cx_face, 0.25, 0.0, FACE.x * 0.5, FACE.z * 0.5), false)
	var y0 := 0.25
	var y1 := ALTURA
	var hx := FACE.x * 0.5
	var hz := FACE.z * 0.5
	var centro_face := Vector3(cx_face, (y0 + y1) * 0.5, 0.0)
	# os lados do bloco
	var b := _ret(cx_face, y0, 0.0, hx, hz)
	var c := _ret(cx_face, y1, 0.0, hx, hz)
	for i in 4:
		var j := (i + 1) % 4
		_quad(st, b[i], b[j], c[j], c[i], centro_face)
	# o topo com o furo quadrado perto do rabo: quatro quadros em volta e as paredes
	var fx := x_rabo + 0.05
	var f := FURO * 0.5
	var centro_baixo := Vector3(cx_face, 0.0, 0.0)
	_quad(st, Vector3(x_rabo, y1, -hz), Vector3(fx - f, y1, -hz), Vector3(fx - f, y1, hz), Vector3(x_rabo, y1, hz), centro_baixo)
	_quad(st, Vector3(fx + f, y1, -hz), Vector3(x_chifre, y1, -hz), Vector3(x_chifre, y1, hz), Vector3(fx + f, y1, hz), centro_baixo)
	_quad(st, Vector3(fx - f, y1, -hz), Vector3(fx + f, y1, -hz), Vector3(fx + f, y1, -f), Vector3(fx - f, y1, -f), centro_baixo)
	_quad(st, Vector3(fx - f, y1, f), Vector3(fx + f, y1, f), Vector3(fx + f, y1, hz), Vector3(fx - f, y1, hz), centro_baixo)
	var fundo := y1 - 0.03
	var parede := [Vector3(fx - f, y1, -f), Vector3(fx + f, y1, -f), Vector3(fx + f, y1, f), Vector3(fx - f, y1, f)]
	for i in 4:
		var j := (i + 1) % 4
		var a: Vector3 = parede[i]
		var d: Vector3 = parede[j]
		# a parede do furo olha para dentro dele
		_quad(st, a, d, d - Vector3(0, y1 - fundo, 0), a - Vector3(0, y1 - fundo, 0), _fora_do_furo(a, d, fx))
	_quad(st, parede[0] - Vector3(0, y1 - fundo, 0), parede[1] - Vector3(0, y1 - fundo, 0), parede[2] - Vector3(0, y1 - fundo, 0), parede[3] - Vector3(0, y1 - fundo, 0), Vector3(fx, fundo - 1.0, 0))
	# o chifre: um cone de 8 lados, de 0,10 a 0,015 de diâmetro, com o topo
	# rente à face e a ponta um pouco acima do eixo (como o bico de uma bigorna)
	var r0 := 0.05
	var r1 := 0.0075
	var eixo0 := Vector3(x_chifre, y1 - r0, 0.0)
	var eixo1 := Vector3(x_chifre + CHIFRE, y1 - 0.03, 0.0)
	var anel0 := []
	var anel1 := []
	for i in 8:
		var a := TAU * (i + 0.5) / 8.0
		anel0.append(eixo0 + Vector3(0, sin(a), cos(a)) * r0)
		anel1.append(eixo1 + Vector3(0, sin(a), cos(a)) * r1)
	_lofte(st, anel0, anel1)
	st.set_material(material())
	_malha = st.commit()
	return _malha


## Um ponto atrás de uma parede do furo (no metal): a normal da parede
## sai dele, para dentro do furo.
static func _fora_do_furo(a: Vector3, d: Vector3, fx: float) -> Vector3:
	var meio := (a + d) * 0.5
	var c := Vector3(fx, meio.y, 0.0)
	return meio + (meio - c)


static func triangulos() -> int:
	malha()
	return _tri


## O material: a textura recolorida do Survival Kit (papel "objeto"),
## metallic 0,2.
static func material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://estudos/direcao/kenney/survival-kit/Textures/colormap.png")
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.metallic = 0.2
	m.roughness = 0.55
	return m
