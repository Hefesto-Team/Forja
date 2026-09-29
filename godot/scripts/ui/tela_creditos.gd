class_name TelaCreditos
extends Control
## Os créditos: a bigorna e o nome de quem fez, e só. Os avisos de licença (os
## modelos, as fontes, o SDL, o Godot) vão junto com o jogo, em
## assets/LEIA-ME.md e nos textos ao lado de cada coisa. ○ volta.

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
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.CASA, 0.94))
	var a := clampf(_t / 0.8, 0.0, 1.0)
	var lado := 220.0
	var c := size * 0.5
	# o sol do synthwave atrás da bigorna: faixas que somem para baixo
	for i in 9:
		var y := c.y - 150.0 + i * 22.0
		var meia := sqrt(maxf(0.0, 200.0 * 200.0 - pow(y - (c.y - 60.0), 2.0)))
		var cor := Tema.ROSA.lerp(Tema.LARANJA, i / 8.0)
		draw_rect(Rect2(Vector2(c.x - meia, y), Vector2(meia * 2.0, 14.0 - i * 1.2)), Color(cor, 0.35 * a))
	draw_texture_rect(Desenho.LOGO, Rect2(Vector2(c.x - lado * 0.5, c.y - 250.0), Vector2(lado, lado)), false, Color(1, 1, 1, a))
	var f := Tema.fonte(700)
	var nome := "Hefesto Team"
	Desenho.texto(self, Vector2(c.x - Desenho.largura(nome, f, Tema.T_DISPLAY) * 0.5, c.y + 110.0), nome, f, Tema.T_DISPLAY,
		Color(Tema.FG, a))
	if _t > 1.0:
		Desenho.dicas_a_direita(self, Vector2(size.x - Tema.MARGEM_X, size.y - Tema.MARGEM_Y), [["circulo", "voltar"]], Tema.T_SELO)
