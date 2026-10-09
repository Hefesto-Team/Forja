extends RefCounted
## As reações (09), desenhadas por código em qualquer tamanho e na cor de
## qualquer dono: os oito adesivos (papel recortado, a cor do dono, o traço
## em TINTA, as lâmpadas do dono no canto) e os seis carimbos do jogo (tinta
## batida, sem fundo, com o desregistro da impressão).
##
## Todo desenho do adesivo é feito no quadro de 112 px (a medida do 09) e
## escalado: Reacoes.adesivo(ci, centro, 144, "rea_riso", 2).

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")

const ADESIVOS := ["rea_martelada", "rea_brasa", "rea_acorde", "rea_riso", "rea_chororo", "rea_susto", "rea_bronca", "rea_de_olho"]
const NOME := {"rea_martelada": "Martelada", "rea_brasa": "Brasa", "rea_acorde": "Acorde", "rea_riso": "Riso",
	"rea_chororo": "Chororô", "rea_susto": "Susto", "rea_bronca": "Bronca", "rea_de_olho": "De olho"}
const CARIMBOS := ["car_virada", "car_em_chamas", "car_por_um_fio", "car_liga", "car_acorde", "car_emburrado"]
const VISOR := {"car_virada": ["VIRADA!", 64], "car_em_chamas": ["EM CHAMAS", 46], "car_por_um_fio": ["POR UM FIO", 64],
	"car_liga": ["LIGA!", 46], "car_acorde": ["ACORDE MAIOR!", 112], "car_emburrado": ["", 160]}
## O recorte: a caixa do papel no quadro de 112 (o desenho cabe em 100 × 84,
## mais 6 px de borda; embaixo, a faixa das lâmpadas).
const RECORTE := Rect2(-56, -50, 112, 104)
const TRACO := 6.0


# ------------------------------------------------------------- o adesivo --
static func adesivo(ci: CanvasItem, centro: Vector2, tam: float, id: String, lugar: int, rot := 0.0) -> void:
	var k := tam / 112.0
	var cor: Color = Fita.JOGADOR[lugar]
	ci.draw_set_transform(centro + Vector2(4, 6) * k, rot, Vector2(k, k))
	Hud.caixa(ci, RECORTE, Fita.SOMBRA, 14)
	ci.draw_set_transform(centro, rot, Vector2(k, k))
	Hud.caixa(ci, RECORTE, Fita.ETIQUETA, 14)
	match id:
		"rea_martelada":
			_martelada(ci, cor)
		"rea_brasa":
			_brasa(ci, cor)
		"rea_acorde":
			_coracao(ci, cor)
		_:
			_cara(ci, cor, id)
	# as lâmpadas do dono: 5 posições de 10 × 5, vão de 3, embaixo à direita
	for i in 5:
		if (int(Fita.LEDS[lugar]) >> i) & 1 == 1:
			ci.draw_rect(Rect2(Vector2(RECORTE.end.x - 8 - 62 + i * 13, RECORTE.end.y - 10), Vector2(10, 5)), Fita.TINTA)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _linha(ci: CanvasItem, pts: PackedVector2Array, fechada := true) -> void:
	var p := pts.duplicate()
	if fechada:
		p.append(p[0])
	ci.draw_polyline(p, Fita.TINTA, TRACO, true)
	for q in p:
		ci.draw_circle(q, TRACO * 0.5, Fita.TINTA)


static func _forma(ci: CanvasItem, pts: PackedVector2Array, cor: Color) -> void:
	ci.draw_colored_polygon(pts, cor)
	_linha(ci, pts)


static func _ret(r: Rect2, raio: float, passos := 3) -> PackedVector2Array:
	var p := PackedVector2Array()
	var cantos := [Vector2(r.end.x - raio, r.position.y + raio), Vector2(r.end.x - raio, r.end.y - raio),
		Vector2(r.position.x + raio, r.end.y - raio), Vector2(r.position.x + raio, r.position.y + raio)]
	var a0 := [-PI * 0.5, 0.0, PI * 0.5, PI]
	for c in 4:
		for i in passos + 1:
			var a: float = a0[c] + PI * 0.5 * i / passos
			p.append(cantos[c] + Vector2(cos(a), sin(a)) * raio)
	return p


## A cara de fita: o cassete de frente; os carretéis são os olhos e a janela
## é a boca. Cada adesivo de cara muda os olhos e a boca.
static func _cara(ci: CanvasItem, cor: Color, id: String) -> void:
	var casco := Rect2(-48, -42, 96, 76)
	_forma(ci, _ret(casco, 12), cor)
	var olho_e := Vector2(-21, -10)
	var olho_d := Vector2(21, -10)
	match id:
		"rea_riso":
			for o in [olho_e, olho_d]:
				ci.draw_arc(o + Vector2(0, 5), 10.0, PI * 1.1, PI * 1.9, 10, Fita.TINTA, TRACO, true)
			# a janela aberta: a boca de riso, larga e funda
			var boca := PackedVector2Array([Vector2(-22, 10), Vector2(22, 10), Vector2(16, 26), Vector2(-16, 26)])
			ci.draw_colored_polygon(boca, Fita.TINTA)
			_linha(ci, boca)
		"rea_chororo":
			for o in [olho_e, olho_d]:
				_carretel(ci, o, 11.0)
				# a tira de fita escorrendo do carretel
				var t := PackedVector2Array([o + Vector2(0, 11), o + Vector2(-3, 22), o + Vector2(2, 32), o + Vector2(-2, 44)])
				ci.draw_polyline(t, Fita.TINTA, 5.0, true)
			Hud.caixa(ci, Rect2(-14, 18, 28, 10), Fita.TINTA, 5)
		"rea_susto":
			for o in [olho_e + Vector2(-2, -2), olho_d + Vector2(2, -2)]:
				_carretel(ci, o, 16.0)
			ci.draw_circle(Vector2(0, 21), 9.0, Fita.TINTA)
			ci.draw_circle(Vector2(0, 21), 4.0, cor)
		"rea_bronca":
			for o in [olho_e, olho_d]:
				_carretel(ci, o, 11.0)
			_linha(ci, PackedVector2Array([Vector2(-36, -32), Vector2(-12, -22)]), false)
			_linha(ci, PackedVector2Array([Vector2(36, -32), Vector2(12, -22)]), false)
			_linha(ci, PackedVector2Array([Vector2(-20, 20), Vector2(20, 20)]), false)
		"rea_de_olho":
			for o in [olho_e, olho_d]:
				_carretel(ci, o, 11.0, Vector2(5, 0))
			Hud.caixa(ci, Rect2(-22, 13, 44, 16), Fita.TINTA, 6)
		_:
			for o in [olho_e, olho_d]:
				_carretel(ci, o, 11.0)
			Hud.caixa(ci, Rect2(-22, 13, 44, 16), Fita.TINTA, 6)
	# os dois parafusos do casco
	ci.draw_circle(Vector2(-40, 26), 2.5, Fita.TINTA)
	ci.draw_circle(Vector2(40, 26), 2.5, Fita.TINTA)


## O carretel-olho: círculo de TINTA, o cubo em ETIQUETA com 6 dentes.
static func _carretel(ci: CanvasItem, c: Vector2, raio: float, cubo := Vector2.ZERO) -> void:
	ci.draw_circle(c, raio, Fita.TINTA)
	var cc := c + cubo * (raio / 11.0)
	ci.draw_circle(cc, raio * 0.48, Fita.ETIQUETA)
	for i in 6:
		var a := TAU * i / 6.0
		ci.draw_line(cc + Vector2(cos(a), sin(a)) * raio * 0.2, cc + Vector2(cos(a), sin(a)) * raio * 0.48, Fita.TINTA, 3.0)


static func _martelada(ci: CanvasItem, cor: Color) -> void:
	# o martelo inclinado batendo, e os três traços do impacto embaixo à esquerda
	var xf := Transform2D(-0.6, Vector2(8, -4))
	var cabeca := PackedVector2Array([Vector2(-30, -34), Vector2(22, -34), Vector2(22, -10), Vector2(-30, -10)])
	var cabo := PackedVector2Array([Vector2(-6, -10), Vector2(4, -10), Vector2(4, 40), Vector2(-6, 40)])
	_forma(ci, xf * cabo, cor.darkened(0.25))
	_forma(ci, xf * cabeca, cor)
	for t in [[Vector2(-44, 0), Vector2(-30, 8)], [Vector2(-46, 18), Vector2(-30, 18)], [Vector2(-40, 34), Vector2(-28, 26)]]:
		_linha(ci, PackedVector2Array(t), false)


static func _brasa(ci: CanvasItem, cor: Color) -> void:
	var pts := PackedVector2Array([Vector2(0, 38), Vector2(-26, 30), Vector2(-36, 8), Vector2(-28, -14), Vector2(-20, -2),
		Vector2(-14, -30), Vector2(-4, -12), Vector2(4, -44), Vector2(14, -12), Vector2(22, -26), Vector2(30, -6),
		Vector2(36, 12), Vector2(26, 30)])
	_forma(ci, pts, cor)
	# a língua de dentro
	var dentro := PackedVector2Array([Vector2(0, 30), Vector2(-12, 22), Vector2(-12, 6), Vector2(-4, 12), Vector2(2, -6),
		Vector2(8, 10), Vector2(14, 4), Vector2(12, 22)])
	_forma(ci, dentro, Fita.ETIQUETA)


static func _coracao(ci: CanvasItem, cor: Color) -> void:
	# o coração de uma volta de fita: a fita larga na cor do dono, a borda em
	# TINTA, e o cruzamento embaixo
	var pts := PackedVector2Array()
	for i in 33:
		var t := TAU * i / 32.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		pts.append(Vector2(x, y) * 2.6 + Vector2(0, -4))
	ci.draw_polyline(pts, Fita.TINTA, 22.0, true)
	ci.draw_polyline(pts, cor, 12.0, true)
	ci.draw_line(Vector2(-10, 30), Vector2(10, 46), Fita.TINTA, 6.0, true)
	ci.draw_line(Vector2(10, 30), Vector2(-10, 46), Fita.TINTA, 6.0, true)


# ------------------------------------------------------------- o carimbo --
## O carimbo do jogo: Bungee com a chapa FITA deslocada round(0,08 × tam) px
## e o contorno FITA de 6 px; inclinado −4°.
static func carimbo(ci: CanvasItem, centro: Vector2, id: String, lugar: int) -> Vector2:
	var visor: String = VISOR[id][0]
	var tam: int = VISOR[id][1]
	var rot := deg_to_rad(-4.0)
	if id == "car_emburrado":
		_emburrado(ci, centro, tam, Fita.JOGADOR[lugar], rot)
		return Vector2(tam, tam)
	var f := Fita.bungee()
	var w := Hud.largura_do(f, tam, visor)
	var cor: Color = Fita.ETIQUETA if id == "car_acorde" else Fita.JOGADOR[lugar]
	var d := roundf(0.08 * tam)
	ci.draw_set_transform(centro, rot, Vector2.ONE)
	Hud.texto(ci, f, tam, Vector2(-w * 0.5 + d, -tam * 0.5 + d), visor, Fita.FITA, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Fita.FITA)
	Hud.texto(ci, f, tam, Vector2(-w * 0.5, -tam * 0.5), visor, cor, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Fita.FITA)
	if id == "car_acorde":
		# as quatro tarjas, P1 a P4, cada uma com o P# em TINTA
		for i in 4:
			var r := Rect2(Vector2(-190 + i * 96, tam * 0.5 + 18), Vector2(80, 40))
			Hud.caixa(ci, r, Fita.JOGADOR[i], 4)
			Hud.texto(ci, f, 30, r.position + Vector2(0, 4), "P%d" % (i + 1), Fita.TINTA, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return Vector2(w, tam)


## O emburrado: a cara de fita de 160 px em tinta (a cor do dono), sem fundo,
## os carretéis meio fechados e a janela virada para baixo.
static func _emburrado(ci: CanvasItem, centro: Vector2, tam: float, cor: Color, rot: float) -> void:
	var k := tam / 112.0
	for camada in 2:
		var c := Fita.FITA if camada == 0 else cor
		var desl := Vector2(1, 1) * roundf(0.08 * tam) if camada == 0 else Vector2.ZERO
		ci.draw_set_transform(centro + desl, rot, Vector2(k, k))
		var casco := _ret(Rect2(-48, -42, 96, 76), 12)
		casco.append(casco[0])
		ci.draw_polyline(casco, c, 7.0, true)
		for o in [Vector2(-21, -10), Vector2(21, -10)]:
			ci.draw_arc(o, 11.0, 0.0, TAU, 16, c, 6.0, true)
			# a pálpebra: meio fechado
			ci.draw_rect(Rect2(o + Vector2(-13, -13), Vector2(26, 12)), c)
		ci.draw_arc(Vector2(0, 30), 14.0, PI * 1.15, PI * 1.85, 10, c, 6.0, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
