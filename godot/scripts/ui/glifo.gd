class_name Glifo
extends RefCounted
## Os glifos dos botões, na geometria do app Hefesto (assets/glyphs: grade de
## 32, traço 2, pontas redondas, só contorno; as setas cheias). Desenhados com
## a API 2D do Godot: qualquer tamanho, qualquer cor. O logo da PlayStation é
## marca da Sony e não entra.

const BOTAO := {
	0: "cruz", 1: "circulo", 2: "quadrado", 3: "triangulo", 4: "create", 6: "options",
	9: "l1", 10: "r1", 11: "cima", 12: "baixo", 13: "esquerda", 14: "direita",
	15: "microfone", 20: "touchpad",
}


## Desenha o glifo `nome` dentro de `r` (quadrado), na cor `cor`.
static func desenhar(ci: CanvasItem, nome: String, r: Rect2, cor: Color, peso := 1.0) -> void:
	var k := minf(r.size.x, r.size.y) / 32.0
	var o := r.position + (r.size - Vector2(32, 32) * k) * 0.5
	var t := maxf(2.0 * k * peso, 1.5)
	var p := func(x: float, y: float) -> Vector2:
		return o + Vector2(x, y) * k
	match nome:
		"cruz":
			ci.draw_line(p.call(8, 8), p.call(24, 24), cor, t, true)
			ci.draw_line(p.call(24, 8), p.call(8, 24), cor, t, true)
			_pontas(ci, [p.call(8, 8), p.call(24, 24), p.call(24, 8), p.call(8, 24)], t, cor)
		"circulo":
			ci.draw_arc(p.call(16, 16), 9.0 * k, 0.0, TAU, 48, cor, t, true)
		"quadrado":
			_contorno(ci, [p.call(8, 8), p.call(24, 8), p.call(24, 24), p.call(8, 24)], cor, t)
		"triangulo":
			_contorno(ci, [p.call(16, 7), p.call(25, 23), p.call(7, 23)], cor, t)
		"cima":
			ci.draw_colored_polygon(PackedVector2Array([p.call(16, 8), p.call(24, 20), p.call(8, 20)]), cor)
		"baixo":
			ci.draw_colored_polygon(PackedVector2Array([p.call(8, 12), p.call(24, 12), p.call(16, 24)]), cor)
		"esquerda":
			ci.draw_colored_polygon(PackedVector2Array([p.call(8, 16), p.call(20, 8), p.call(20, 24)]), cor)
		"direita":
			ci.draw_colored_polygon(PackedVector2Array([p.call(24, 16), p.call(12, 8), p.call(12, 24)]), cor)
		"options":
			for y in [10, 16, 22]:
				ci.draw_line(p.call(7, y), p.call(25, y), cor, t, true)
				_pontas(ci, [p.call(7, y), p.call(25, y)], t, cor)
		"create":
			ci.draw_line(p.call(10, 9), p.call(13, 23), cor, t, true)
			ci.draw_line(p.call(16, 8), p.call(16, 23), cor, t, true)
			ci.draw_line(p.call(22, 9), p.call(19, 23), cor, t, true)
			_pontas(ci, [p.call(10, 9), p.call(13, 23), p.call(16, 8), p.call(16, 23), p.call(22, 9), p.call(19, 23)], t, cor)
		"touchpad":
			_retangulo_arred(ci, Rect2(p.call(5, 9), Vector2(22, 14) * k), 3.0 * k, cor, t)
		"microfone":
			_retangulo_arred(ci, Rect2(p.call(12, 5), Vector2(8, 14) * k), 4.0 * k, cor, t)
			ci.draw_arc(p.call(16, 15), 7.0 * k, 0.0, PI, 24, cor, t, true)
			ci.draw_line(p.call(16, 22), p.call(16, 27), cor, t, true)
		"item_martelo":
			_contorno(ci, [p.call(14, 6), p.call(26, 14), p.call(22, 20), p.call(10, 12)], cor, t)
			ci.draw_line(p.call(16, 16), p.call(8, 28), cor, t, true)
		"item_escudo":
			_contorno(ci, [p.call(8, 7), p.call(24, 7), p.call(24, 16), p.call(16, 26), p.call(8, 16)], cor, t)
		"item_fole":
			_contorno(ci, [p.call(6, 10), p.call(20, 6), p.call(20, 26), p.call(6, 22)], cor, t)
			ci.draw_line(p.call(20, 16), p.call(28, 16), cor, t, true)
		"item_lanterna":
			_retangulo_arred(ci, Rect2(p.call(10, 10), Vector2(12, 16) * k), 3.0 * k, cor, t)
			ci.draw_arc(p.call(16, 10), 4.0 * k, PI, TAU, 16, cor, t, true)
			ci.draw_line(p.call(16, 15), p.call(16, 21), cor, t, true)
		"item_diapasao":
			ci.draw_line(p.call(12, 6), p.call(12, 18), cor, t, true)
			ci.draw_line(p.call(20, 6), p.call(20, 18), cor, t, true)
			ci.draw_arc(p.call(16, 18), 4.0 * k, 0.0, PI, 16, cor, t, true)
			ci.draw_line(p.call(16, 22), p.call(16, 28), cor, t, true)
		"item_ancora":
			ci.draw_line(p.call(16, 8), p.call(16, 26), cor, t, true)
			ci.draw_arc(p.call(16, 6), 2.5 * k, 0.0, TAU, 16, cor, t, true)
			ci.draw_line(p.call(11, 11), p.call(21, 11), cor, t, true)
			ci.draw_arc(p.call(16, 18), 8.0 * k, 0.0, PI, 24, cor, t, true)
		"l1", "r1", "l2", "r2":
			var forma := Rect2(p.call(4, 9), Vector2(24, 14) * k)
			_retangulo_arred(ci, forma, 5.0 * k, cor, t)
			var f := Tema.archivo(700)
			var tam := int(10.0 * k)
			var texto := nome.to_upper()
			var larg := f.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
			ci.draw_string(f, Vector2(forma.get_center().x - larg * 0.5, forma.get_center().y + tam * 0.36),
				texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, cor)
		"analogico_l", "analogico_r":
			ci.draw_arc(p.call(16, 16), 11.0 * k, 0.0, TAU, 48, cor, t, true)
			var f2 := Tema.archivo(700)
			var tam2 := int(12.0 * k)
			var letra := "L" if nome == "analogico_l" else "R"
			var l2 := f2.get_string_size(letra, HORIZONTAL_ALIGNMENT_LEFT, -1, tam2).x
			ci.draw_string(f2, p.call(16, 16) + Vector2(-l2 * 0.5, tam2 * 0.36), letra,
				HORIZONTAL_ALIGNMENT_LEFT, -1, tam2, cor)


static func _pontas(ci: CanvasItem, pts: Array, t: float, cor: Color) -> void:
	for q in pts:
		ci.draw_circle(q, t * 0.5, cor)


static func _contorno(ci: CanvasItem, pts: Array, cor: Color, t: float) -> void:
	var v := PackedVector2Array(pts)
	v.append(pts[0])
	ci.draw_polyline(v, cor, t, true)
	_pontas(ci, pts, t, cor)


static func _retangulo_arred(ci: CanvasItem, r: Rect2, raio: float, cor: Color, t: float) -> void:
	var s := StyleBoxFlat.new()
	s.draw_center = false
	s.border_color = cor
	s.set_border_width_all(int(maxf(t, 1.0)))
	s.set_corner_radius_all(int(raio))
	s.anti_aliasing = true
	ci.draw_style_box(s, r)


## O texto de uma dica de botão: "(Iniciar)", entre parênteses.
static func _acao(texto: String) -> String:
	return "(%s)" % Desenho.t(texto)


## Largura de uma dica "Botão [glifo] (ação)" no tamanho `tam`. `com_botao` é
## falso na segunda dica em diante de uma fileira: só a primeira diz "Botão".
static func largura_dica(glifo: String, texto: String, tam: int, com_botao := true) -> float:
	var f := Tema.archivo(600)
	tam = Tema.t(tam)
	var acao := "(%s)" % Traducoes.traduzir(texto)
	var w := tam * 1.25 + 10.0 + f.get_string_size(acao, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	if com_botao:
		w += f.get_string_size(Traducoes.traduzir("Botão"), HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x + 10.0
	return w


## Uma dica: "Botão ✕ (Iniciar)", na linha de base `pos` (canto esquerdo).
static func dica(ci: CanvasItem, pos: Vector2, glifo: String, texto: String, tam: int, cor_glifo: Color,
		cor_texto: Color, com_botao := true) -> float:
	tam = Tema.t(tam)
	var acao := _acao(texto)
	var lado := tam * 1.25
	var f := Tema.archivo(600)
	var x := 0.0
	if com_botao:
		var botao := Desenho.t("Botão")
		ci.draw_string(f, pos, botao, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, cor_texto)
		if Desenho.coletar_retangulos:
			Desenho.anotar(ci, pos, botao, f, tam, cor_texto)
		x += f.get_string_size(botao, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x + 10.0
	desenhar(ci, glifo, Rect2(pos + Vector2(x, -lado * 0.82), Vector2(lado, lado)), cor_glifo)
	ci.draw_string(f, pos + Vector2(x + lado + 10.0, 0), acao, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, cor_texto)
	if Desenho.coletar_retangulos:
		Desenho.anotar(ci, pos + Vector2(x + lado + 10.0, 0), acao, f, tam, cor_texto)
	return x + lado + 10.0 + f.get_string_size(acao, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
