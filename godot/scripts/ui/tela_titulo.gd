class_name TelaTitulo
extends Control

var pulso := 0.0
var batidas := 0.0
var play_desde := -1.0
var contador_s := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(_dt: float) -> void:
	queue_redraw()


func _texto(topo: Vector2, s: String, f: Font, tam: int, cor: Color, alinha := HORIZONTAL_ALIGNMENT_LEFT, largura := -1.0) -> void:
	Desenho.texto(self, topo + Vector2(0, f.get_ascent(Tema.t(tam))), s, f, tam, cor, alinha, largura)


func _descida() -> float:
	if play_desde < 0.0:
		return 0.0
	return 720.0 * pow(clampf((batidas - play_desde) / 4.0, 0.0, 1.0), 3.0)


func _brasa(centro: Vector2) -> void:
	for i in 9:
		var k := float(i) / 8.0
		draw_set_transform(centro, 0.0, Vector2(1.0, 0.34))
		draw_circle(Vector2.ZERO, lerpf(760.0, 220.0, k), Color(Tema.OXIDO_BRILHO, (0.05 + 0.04 * pulso) * (0.4 + k)))
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw() -> void:
	var osd := Color(Tema.ETIQUETA, 0.9)
	draw_rect(Rect2(Vector2.ZERO, size), Tema.FITA.darkened(0.55))
	draw_rect(Rect2(0, 364, size.x, 8), Color(Tema.VIOLETA, 0.85))
	_brasa(Vector2(960, 930) + Vector2(0, _descida()))
	draw_colored_polygon(PackedVector2Array([Vector2(100, 70), Vector2(100, 116), Vector2(138, 93)]), osd)
	_texto(Vector2(156, 62), "PLAY", Tema.vt(), 60, osd)
	var s := int(contador_s)
	_texto(Vector2(0, 62), "SP  %d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60], Tema.vt(), 60, osd, HORIZONTAL_ALIGNMENT_RIGHT, 1820)

	var dy := Vector2(0, _descida())
	var r := Rect2(Vector2(400, 170) + dy, Vector2(1120, 690))
	Desenho.caixa(self, Rect2(r.position + Vector2(10, 16), r.size), Tema.SOMBRA, 34)
	Desenho.caixa(self, r, Tema.CASCO, 34, Tema.CASCO_ALTO, 4)
	for p in [Vector2(30, 30), Vector2(r.size.x - 30, 30), Vector2(30, r.size.y - 30), Vector2(r.size.x - 30, r.size.y - 30)]:
		draw_circle(r.position + p, 11, Tema.GRAFITE)
		draw_line(r.position + p - Vector2(6, 6), r.position + p + Vector2(6, 6), Tema.CASCO, 3.0)
	var et := Rect2(r.position + Vector2(56, 48), Vector2(r.size.x - 112, 360))
	Desenho.caixa(self, et, Tema.ETIQUETA, 12)
	draw_rect(Rect2(et.position + Vector2(0, 26), Vector2(et.size.x, 18)), Tema.SECAO[0])
	draw_rect(Rect2(et.position + Vector2(0, 50), Vector2(et.size.x, 6)), Tema.SECAO[3])
	draw_texture_rect(Desenho.LOGO, Rect2(et.position + Vector2(36, 76), Vector2(260, 260)), false)
	var nome := et.position + Vector2(330, 104)
	_texto(nome + Vector2(10, 10), "A FORJA", Tema.bungee(), 128, Color(Tema.SECAO[0], 0.9))
	_texto(nome, "A FORJA", Tema.bungee(), 128, Tema.TINTA)
	_texto(et.position + Vector2(338, 268), "Nove salas, quatro cavaleiros", Tema.marcador(), 40, Tema.TINTA)
	var jan := Rect2(Vector2(r.get_center().x - 300, et.end.y + 34), Vector2(600, 170))
	Desenho.caixa(self, jan, Tema.JANELA, 22, Tema.GRAFITE, 3)
	var c1 := jan.position + Vector2(140, jan.size.y * 0.5)
	var c2 := jan.position + Vector2(jan.size.x - 140, jan.size.y * 0.5)
	draw_line(c1 + Vector2(0, 66), c2 + Vector2(0, 40), Tema.OXIDO, 4.0, true)
	var giro := batidas * PI * 0.5
	Desenho.carretel(self, c1, 70, 0.95, Tema.ETIQUETA, giro)
	Desenho.carretel(self, c2, 70, 0.30, Tema.ETIQUETA, giro)
	var pe := PackedVector2Array([Vector2(r.position.x + 230, r.end.y), Vector2(r.position.x + 290, r.end.y - 80),
		Vector2(r.end.x - 290, r.end.y - 80), Vector2(r.end.x - 230, r.end.y)])
	draw_colored_polygon(pe, Tema.CASCO_ALTO)
	for x in [-180.0, -60.0, 60.0, 180.0]:
		draw_circle(Vector2(r.get_center().x + x, r.end.y - 36), 14, Tema.JANELA)

	var sem_controle := Forja.modulo and Forja.conectados() == 0
	var dica_do_botao := "Jogar no teclado" if sem_controle else "Começar"
	var largura := Glifo.largura_dica("cruz", dica_do_botao, 44, not sem_controle)
	var bt := Rect2(Vector2(760, 920) + dy, Vector2(maxf(400.0, largura + 60.0), 82))
	bt.position.x = 960.0 - bt.size.x * 0.5
	Desenho.caixa(self, bt.grow(10), Color(Tema.ETIQUETA, 0.12 + 0.18 * pulso), 18)
	Desenho.caixa(self, bt, Tema.ETIQUETA, 14)
	Glifo.dica(self, Vector2(bt.get_center().x - largura * 0.5, bt.position.y + 57), "cruz", dica_do_botao, 44,
		Tema.TINTA, Tema.TINTA, not sem_controle)
	if sem_controle:
		_texto(Vector2(0, 860) + dy, "Nenhum controle encontrado", Tema.archivo(600), 34, Tema.ETIQUETA,
			HORIZONTAL_ALIGNMENT_CENTER, size.x)
	else:
		var larg_c := Glifo.largura_dica("triangulo", "Créditos", 34, false)
		var pc := Rect2(Vector2(1180, 925) + dy, Vector2(larg_c + 40.0, 62))
		Desenho.caixa(self, pc, Color(Tema.ETIQUETA, 0.9), 14)
		Glifo.dica(self, Vector2(pc.position.x + 20.0, pc.position.y + 43), "triangulo", "Créditos", 34, Tema.TINTA, Tema.TINTA, false)
