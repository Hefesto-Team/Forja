extends RefCounted
## O HUD da fita: a interface é objeto. A etiqueta do cassete escrita a
## caneta, o contador de fita, os carretéis, a faixa de cada jogador com o VU
## no canto. Tudo desenhado com _draw, em px da tela lógica de 1920×1080.

const Fita := preload("res://estudos/direcao/fita.gd")


## Uma camada de interface que se desenha por uma função.
class Tela extends Control:
	var desenhar: Callable

	func _init(f: Callable) -> void:
		desenhar = f
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		desenhar.call(self)


static func camada(pai: Node, f: Callable, n := 10) -> Tela:
	var cl := CanvasLayer.new()
	cl.layer = n
	pai.add_child(cl)
	var t := Tela.new(f)
	cl.add_child(t)
	return t


# ------------------------------------------------------------- primitivas --
static func caixa(ci: CanvasItem, r: Rect2, fundo: Color, raio := 10, borda := Color(0, 0, 0, 0), largura := 0) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.draw_center = fundo.a > 0.0
	s.set_corner_radius_all(raio)
	if largura > 0:
		s.border_color = borda
		s.set_border_width_all(largura)
	s.anti_aliasing = true
	ci.draw_style_box(s, r)


## O texto, com o ponto de partida no canto de cima à esquerda (não na linha
## de base): fica fácil compor pela caixa.
static func texto(ci: CanvasItem, f: Font, tam: int, pos: Vector2, s: String, cor: Color,
		alinha := HORIZONTAL_ALIGNMENT_LEFT, largura := -1.0, contorno := 0, cor_contorno := Color.BLACK) -> void:
	var base := pos + Vector2(0, f.get_ascent(tam))
	if contorno > 0:
		ci.draw_string_outline(f, base, s, alinha, largura, tam, contorno, cor_contorno)
	ci.draw_string(f, base, s, alinha, largura, tam, cor)


static func largura_do(f: Font, tam: int, s: String) -> float:
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x


static var _glifos := {}


## O glifo do botão (godot/assets/glifos), descomprimido como o Desenho.glifo
## do jogo faz: comprimido, ele vira um quadrado no renderizador por software.
static func glifo(ci: CanvasItem, nome: String, r: Rect2, cor := Color.WHITE) -> void:
	if not _glifos.has(nome):
		var img: Image = (load("res://assets/glifos/%s.png" % nome) as Texture2D).get_image()
		img.decompress()
		img.generate_mipmaps()
		_glifos[nome] = ImageTexture.create_from_image(img)
	ci.draw_texture_rect(_glifos[nome], r, false, cor)


# ------------------------------------------------------------- o cassete --
## Um carretel: o cubo com seis dentes e a fita enrolada (0 a 1).
static func carretel(ci: CanvasItem, c: Vector2, raio: float, fita: float, cor_cubo := Fita.ETIQUETA) -> void:
	var r_fita := lerpf(raio * 0.42, raio, fita)
	ci.draw_circle(c, r_fita, Color("#3b2a22"))  # a fita magnética: marrom de óxido
	ci.draw_arc(c, r_fita - 1.5, PI * 1.05, PI * 1.45, 18, Color("#6b4a38"), 2.0, true)
	ci.draw_circle(c, raio * 0.42, cor_cubo)
	ci.draw_circle(c, raio * 0.2, Fita.CASCO)
	for i in 6:
		var a := i * TAU / 6.0 + 0.3
		var d := Vector2(cos(a), sin(a))
		ci.draw_line(c + d * raio * 0.2, c + d * raio * 0.33, Fita.CASCO, 3.0, true)


## A etiqueta do cassete: papel, a tarja na tinta da seção, o título a
## caneta e a linha impressa embaixo.
static func etiqueta(ci: CanvasItem, r: Rect2, titulo: String, impresso: String, tinta_secao: Color,
		tam_titulo := 56, inclina := 0.0) -> void:
	ci.draw_set_transform(r.position + r.size * 0.5, inclina, Vector2.ONE)
	var rr := Rect2(-r.size * 0.5, r.size)
	caixa(ci, Rect2(rr.position + Vector2(5, 7), rr.size), Color(0, 0, 0, 0.45), 8)
	caixa(ci, rr, Fita.ETIQUETA, 8)
	# a tarja da seção e as linhas pautadas do papel
	ci.draw_rect(Rect2(rr.position + Vector2(0, 14), Vector2(rr.size.x, 12)), tinta_secao)
	for i in 2:
		var y := rr.position.y + rr.size.y - 40 - i * 46
		ci.draw_line(Vector2(rr.position.x + 22, y), Vector2(rr.end.x - 22, y), Fita.ETIQUETA_SOMBRA, 2.0)
	texto(ci, Fita.marcador(), tam_titulo, rr.position + Vector2(24, 30), titulo, Fita.TINTA)
	texto(ci, Fita.vt(), 34, Vector2(rr.position.x + 24, rr.end.y - 38), impresso, Fita.TINTA_SUAVE)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## O contador de fita: três ou quatro rodas de número numa janela preta.
static func contador(ci: CanvasItem, pos: Vector2, digitos: String, tam := 60) -> Rect2:
	var f := Fita.vt()
	var w_d := largura_do(f, tam, "0") + 10
	var r := Rect2(pos, Vector2(w_d * digitos.length() + 14, tam * 0.95 + 12))
	caixa(ci, r, Color("#07050c"), 6, Fita.GRAFITE, 2)
	for i in digitos.length():
		var cel := Rect2(pos + Vector2(7 + i * w_d, 6), Vector2(w_d - 4, tam * 0.95))
		caixa(ci, cel, Color("#141019"), 3)
		texto(ci, f, tam, cel.position + Vector2(0, -tam * 0.1), digitos[i], Fita.ETIQUETA, HORIZONTAL_ALIGNMENT_CENTER, cel.size.x)
		# a dobra da roda: a linha do meio
		ci.draw_line(Vector2(cel.position.x, cel.get_center().y), Vector2(cel.end.x, cel.get_center().y), Color(0, 0, 0, 0.55), 2.0)
	return r


## O deck: a janela do cassete (dois carretéis, a fita entre eles) e o
## contador de fita ao lado, numa placa só.
static func deck(ci: CanvasItem, r: Rect2, esquerda: float, direita: float, digitos: String) -> void:
	caixa(ci, Rect2(r.position + Vector2(4, 6), r.size), Color(0, 0, 0, 0.45), 14)
	caixa(ci, r, Fita.CASCO, 14, Fita.CASCO_ALTO, 3)
	var jan := Rect2(r.position + Vector2(16, 14), Vector2(228, r.size.y - 28))
	caixa(ci, jan, Color("#07050c"), 10)
	var c1 := jan.position + Vector2(56, jan.size.y * 0.5)
	var c2 := jan.position + Vector2(jan.size.x - 56, jan.size.y * 0.5)
	var raio := jan.size.y * 0.5 - 6
	ci.draw_line(c1 + Vector2(0, lerpf(raio * 0.42, raio, esquerda)), c2 + Vector2(0, lerpf(raio * 0.42, raio, direita)), Color("#3b2a22"), 3.0, true)
	carretel(ci, c1, raio, esquerda)
	carretel(ci, c2, raio, direita)
	var tam := 64
	contador(ci, Vector2(jan.end.x + 16, r.position.y + (r.size.y - tam * 0.95 - 12) * 0.5), digitos, tam)


## As lâmpadas do lugar, no padrão do LED de jogador do controle (as cinco
## posições: 1 | 2 | 3 | 4 acesas).
static func lampadas(ci: CanvasItem, pos: Vector2, lugar: int, cor: Color, tam := 10.0) -> void:
	for i in 5:
		var aceso := (int(Fita.LEDS[lugar]) >> i) & 1 == 1
		var r := Rect2(pos + Vector2(i * (tam + 5), 0), Vector2(tam, tam * 0.55))
		ci.draw_rect(r, cor if aceso else Fita.GRAFITE)


## O VU: segmentos acesos na cor do jogador, o de pico em papel.
static func vu(ci: CanvasItem, r: Rect2, n: int, aceso: int, cor: Color, pico := -1) -> void:
	var gap := 4.0
	var w := (r.size.x - gap * (n - 1)) / n
	for i in n:
		var cel := Rect2(r.position + Vector2(i * (w + gap), 0), Vector2(w, r.size.y))
		var c := Fita.GRAFITE
		if i < aceso:
			c = cor.darkened(0.25 * (1.0 - float(i) / n))
		if i == pico:
			c = Fita.ETIQUETA
		ci.draw_rect(cel, c)


## O cartão de um jogador, preso ao canto dele (P1 no alto à esquerda, P2 no
## alto à direita, P3 embaixo à esquerda, P4 embaixo à direita; doc 06): a tira
## do console de mixagem. A cor e o número com as lâmpadas do lugar, o nome do
## cavaleiro, os pontos no contador e o combo no VU.
const CARTAO := Vector2(420, 132)


static func canto(lugar: int) -> Vector2:
	var x := 96.0 if lugar % 2 == 0 else 1920.0 - 96.0 - CARTAO.x
	var y := 54.0 if lugar < 2 else 1080.0 - 54.0 - CARTAO.y
	return Vector2(x, y)


static func cartao(ci: CanvasItem, lugar: int, nome: String, pontos: String, combo: int, pico := -1) -> void:
	var cor: Color = Fita.JOGADOR[lugar]
	var r := Rect2(canto(lugar), CARTAO)
	caixa(ci, Rect2(r.position + Vector2(0, 6), r.size), Color(0, 0, 0, 0.5), 10)
	caixa(ci, r, Color(Fita.CASCO, 0.94), 10)
	ci.draw_rect(Rect2(r.position + Vector2(10, 0), Vector2(r.size.x - 20, 5)), cor)
	texto(ci, Fita.bungee(), 40, r.position + Vector2(18, 16), "P%d" % (lugar + 1), cor)
	lampadas(ci, r.position + Vector2(20, 66), lugar, cor, 15.0)
	texto(ci, Fita.archivo(600), 32, r.position + Vector2(112, 18), nome, Fita.ETIQUETA)
	texto(ci, Fita.vt(), 64, r.position + Vector2(0, 4), pontos, Fita.ETIQUETA, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 18)
	vu(ci, Rect2(r.position + Vector2(18, r.size.y - 34), Vector2(r.size.x - 118, 18)), 14, combo, cor, pico)
	texto(ci, Fita.vt(), 40, Vector2(r.position.x, r.end.y - 50), "×%d" % combo, Color(Fita.ETIQUETA, 0.8), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 18)


## O julgamento do toque, preso em cima do boneco, na cor dele (some em meio
## segundo): tinta grossa com o desregistro da impressão por baixo.
static func julgamento(ci: CanvasItem, centro: Vector2, palavra: String, cor: Color, tam := 46, inclina := -0.06) -> void:
	var f := Fita.bungee()
	var w := largura_do(f, tam, palavra)
	ci.draw_set_transform(centro, inclina, Vector2.ONE)
	texto(ci, f, tam, Vector2(-w * 0.5 + 4, -tam * 0.5 + 4), palavra, Fita.FITA, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Fita.FITA)
	texto(ci, f, tam, Vector2(-w * 0.5, -tam * 0.5), palavra, cor, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Fita.FITA)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## O chip de "Pronto" de um lugar.
static func chip(ci: CanvasItem, r: Rect2, lugar: int, pronto: bool) -> void:
	var cor: Color = Fita.JOGADOR[lugar]
	if pronto:
		caixa(ci, r, cor, 8)
		texto(ci, Fita.bungee(), 30, r.position + Vector2(16, 13), "P%d" % (lugar + 1), Fita.FITA)
		texto(ci, Fita.archivo(700), 34, r.position + Vector2(0, 10), "Pronto", Fita.FITA, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 18)
	else:
		caixa(ci, r, Color(Fita.CASCO, 0.9), 8, cor, 3)
		texto(ci, Fita.bungee(), 30, r.position + Vector2(16, 13), "P%d" % (lugar + 1), cor)
		texto(ci, Fita.archivo(500), 34, r.position + Vector2(0, 10), "Treinando", Color(Fita.ETIQUETA, 0.75), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 18)
