class_name TelaCreditos
extends Control

var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func abrir() -> void:
	_t = 0.0


func _process(dt: float) -> void:
	_t += dt
	if visible:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Tema.FITA.darkened(0.55))
	var a := clampf(_t / 0.8, 0.0, 1.0)
	var osd := Color(Tema.ETIQUETA, 0.9 * a)
	draw_rect(Rect2(100, 70, 38, 38), osd)
	Desenho.texto(self, Vector2(156, 112), "STOP", Tema.vt(), 60, osd)
	var e := Rect2(Vector2(size.x * 0.5 - 600.0, 300.0), Vector2(1200, 440))
	Desenho.caixa(self, Rect2(e.position + Vector2(10, 16), e.size), Color(0, 0, 0, 0.45 * a), 14)
	Desenho.caixa(self, e, Color(Tema.ETIQUETA, a), 14)
	draw_rect(Rect2(e.position + Vector2(0, 30), Vector2(e.size.x, 22)), Color(Tema.SECAO[0], a))
	draw_rect(Rect2(e.position + Vector2(0, 58), Vector2(e.size.x, 7)), Color(Tema.SECAO[3], a))
	draw_texture_rect(Desenho.LOGO, Rect2(e.position + Vector2(56, 110), Vector2(250, 250)), false, Color(1, 1, 1, a))
	var x := e.position.x + 350.0
	Desenho.texto(self, Vector2(x + 9, e.position.y + 229.0), "A FORJA", Tema.bungee(), 112, Color(Tema.SECAO[0], 0.9 * a))
	Desenho.texto(self, Vector2(x, e.position.y + 220.0), "A FORJA", Tema.bungee(), 112, Color(Tema.TINTA, a))
	Desenho.texto(self, Vector2(x, e.position.y + 300.0), "Feito à mão por", Tema.archivo(500), Tema.T_SUBTITULO, Color(Tema.TINTA_SUAVE, a))
	var cor := Color(Tema.TINTA, a)
	Desenho.texto(self, Vector2(x, e.position.y + 380.0), "Vitória, André e Amanda", Tema.marcador(), 62, cor)
	if _t > 1.0:
		Desenho.dicas_a_direita(self, Vector2(size.x - Tema.MARGEM_X, size.y - Tema.MARGEM_Y), [["circulo", "Voltar"]], Tema.T_SELO)
