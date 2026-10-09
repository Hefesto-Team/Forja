class_name TelaTitulo
extends Control
## A tela de título, por cima do salão: o logo e o nome, o que o jogo vê de
## controle agora, e o único botão que importa.

var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	# a tarja da esquerda: o texto nunca fica em cima do fogo
	var tarja := Rect2(0, 0, 900, h)
	draw_rect(tarja, Color(Tema.FITA, 0.72))
	for i in 24:
		draw_rect(Rect2(900 + i * 10, 0, 10, h), Color(Tema.FITA, 0.72 * (1.0 - i / 24.0)))

	var x := 120.0
	draw_texture_rect(Desenho.LOGO, Rect2(x, 170, 200, 200), false)
	var marca := Tema.bungee()
	Desenho.texto(self, Vector2(x, 480), "Hefesto", marca, Tema.T_DISPLAY, Tema.ETIQUETA)
	Desenho.texto(self, Vector2(x, 590), "Tech Demo", marca, Tema.T_DISPLAY, Tema.ETIQUETA)
	Desenho.texto(self, Vector2(x + 4, 660), "Quatro DualSense no mesmo sofá.", Tema.archivo(500), Tema.T_SUBTITULO, Tema.ETIQUETA_SOMBRA)

	# o que o jogo vê
	var y := 770.0
	var n := Forja.conectados()
	# sem o módulo, nada a dizer na tela (o forja.gd já registra o aviso)
	if Forja.modulo and n == 0:
		Desenho.texto(self, Vector2(x, y), "Nenhum controle encontrado.", Tema.archivo(600), Tema.T_CORPO, Tema.SECAO[3])
		Desenho.texto(self, Vector2(x, y + 44), "Conecte um DualSense por USB ou Bluetooth.", Tema.archivo(500), Tema.T_ROTULO, Tema.ETIQUETA_SOMBRA)
	elif Forja.modulo:
		var usb := 0
		var bt := 0
		var sim := 0
		for p in Forja.pads():
			match str(p.conexao_curta):
				"USB": usb += 1
				"BT": bt += 1
				"Simulado": sim += 1
		var partes: PackedStringArray = []
		if usb: partes.append("%d USB" % usb)
		if bt: partes.append("%d BT" % bt)
		if sim: partes.append("%d simulado%s" % [sim, "s" if sim > 1 else ""])
		draw_circle(Vector2(x + 10, y - 11), 8, Tema.ETIQUETA)
		var txt := "%d controle%s  ·  %s" % [n, "s" if n > 1 else "", " · ".join(partes)]
		Desenho.texto(self, Vector2(x + 30, y), txt, Tema.archivo(600), Tema.T_CORPO, Tema.ETIQUETA)

	# o botão
	var pulso := 0.75 + 0.25 * sin(_t * 3.0)
	var yb := 900.0
	if Forja.modulo and n == 0:
		Glifo.dica(self, Vector2(x, yb), "cruz", "Jogar no teclado · Enter", Tema.T_CORPO, Color(Tema.ETIQUETA, pulso), Tema.ETIQUETA)
	else:
		var wc := Glifo.dica(self, Vector2(x, yb), "cruz", "Começar", 40, Color(Tema.ETIQUETA, pulso), Tema.ETIQUETA)
		Glifo.dica(self, Vector2(x + wc + 56, yb), "triangulo", "Créditos", Tema.T_ROTULO, Tema.ETIQUETA, Tema.ETIQUETA_SOMBRA, false)

	# o rodapé
	var rodape := "FORJA %s" % Forja.versao()
	Desenho.texto(self, Vector2(x, h - 56), rodape, Tema.vt(), Tema.T_SELO, Tema.MUDO)
