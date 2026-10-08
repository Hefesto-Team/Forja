class_name HudJogo
extends Control
## A HUD do salão e das salas, mínima: o que decide o próximo segundo. Em cima,
## os lugares (P1..P4, sempre na mesma ordem) com a conexão e a bateria; perto
## de um portão, a placa da sala e o botão; nas salas, o nome e a ação numa
## linha. Os avisos do módulo aparecem no alto e somem sozinhos.

## A placa do portão perto: {nome, sobre, aberta} ou vazio.
var placa := {}
## A sala em curso: {nome, acao} ou vazio.
var sala := {}
## Uma linha por lugar, dita pela sala (vida, pontos, o que falta).
var status_da_sala := ["", "", "", ""]
## false numa sala que usa o Create (a runa d'A Centelha): o rodapé não o oferece
var create_livre := true

var _avisos: Array = []  # [texto, restante]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Forja.aviso.connect(mostrar_aviso)


func mostrar_aviso(texto: String) -> void:
	if texto == "":
		return
	_avisos.append([texto, 3.5])
	if _avisos.size() > 3:
		_avisos.pop_front()


func _process(dt: float) -> void:
	for a in _avisos:
		a[1] -= dt
	_avisos = _avisos.filter(func(a): return a[1] > 0.0)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	# a tarja de cima, leve
	for i in 20:
		draw_rect(Rect2(0, i * 7, w, 7), Color(Tema.CASA, 0.55 * (1.0 - i / 20.0)))

	if sala.is_empty():
		Desenho.cabecalho(self, Vector2(Tema.MARGEM_X, 40), 60.0)
	else:
		# o nome e a ação num quadro: a arena é clara e o texto não pode sumir nela
		var fn := Tema.fonte(700)
		var fa := Tema.fonte(500)
		var nome := str(sala.get("nome", ""))
		var acao := str(sala.get("acao", ""))
		var larg := maxf(Desenho.largura(nome, fn, 44), Desenho.largura(acao, fa, Tema.T_ROTULO)) + 56
		var q := Rect2(Vector2(Tema.MARGEM_X - 28, 40), Vector2(larg, 118))
		Desenho.moldura(self, q, Color(Tema.PAINEL, 0.94), Tema.LINHA, 2, Tema.RAIO_QUADRO)
		Desenho.texto(self, q.position + Vector2(28, 56), nome, fn, 44, Tema.FG)
		Desenho.texto(self, q.position + Vector2(28, 96), acao, fa, Tema.T_ROTULO, Tema.ROXO)

	_lugares(Vector2(w - Tema.MARGEM_X, 40))

	# a placa do portão
	if not placa.is_empty():
		var aberta: bool = placa.get("aberta", false)
		var nome_p := str(placa.get("nome", ""))
		var sobre := str(placa.get("sobre", ""))
		var fn_p := Tema.fonte(700)
		var fs_p := Tema.fonte(500)
		var s := "Em breve"
		var fs := Tema.fonte(600)
		var wd := Glifo.largura_dica("cruz", "Entrar", Tema.T_CORPO) if aberta else Desenho.largura(s, fs, Tema.T_ROTULO)
		# a placa cresce com o texto: o "✕ entrar" nunca fica por cima do que ela diz
		var texto_w := maxf(Desenho.largura(nome_p, fn_p, 40), Desenho.largura(sobre, fs_p, Tema.T_ROTULO))
		var larg_p := clampf(texto_w + wd + 32 * 2 + 40, 620.0, w - 2 * Tema.MARGEM_X)
		var r := Rect2(Vector2((w - larg_p) * 0.5, h - 230), Vector2(larg_p, 150))
		Desenho.moldura(self, r, Color(Tema.PAINEL, 0.96), Tema.LINHA, 2, Tema.RAIO_QUADRO)
		Desenho.texto(self, r.position + Vector2(32, 58), nome_p, fn_p, 40, Tema.FG)
		Desenho.texto(self, r.position + Vector2(32, 100), sobre, fs_p, Tema.T_ROTULO, Tema.ROXO)
		if aberta:
			Glifo.dica(self, Vector2(r.end.x - 32 - wd, r.position.y + 84), "cruz", "Entrar", Tema.T_CORPO, Tema.ROSA, Tema.FG)
		else:
			Desenho.texto(self, Vector2(r.end.x - 32 - wd, r.position.y + 84), s, fs, Tema.T_ROTULO, Tema.COMMENT)

	# as dicas de baixo
	var pares := [["create", "Diagnóstico"], ["options", "Pausa"]] if create_livre and Forja.bancada else [["options", "Pausa"]]
	Desenho.dicas_a_direita(self, Vector2(w - Tema.MARGEM_X, h - Tema.MARGEM_Y), pares, Tema.T_SELO)

	# os avisos
	# o texto que some sozinho é grande e curto: 46 px, até duas linhas
	var y := 190.0
	for a in _avisos:
		var alfa := clampf(a[1] / 0.4, 0.0, 1.0)
		var f := Tema.fonte(500)
		var larg_max := 1100.0
		var s := Desenho.caber(a[0], f, Tema.T_AVISO, larg_max, 2)
		var tw := minf(Desenho.largura(s, f, Tema.T_AVISO), larg_max)
		var th := Desenho.altura_paragrafo(s, f, Tema.T_AVISO, larg_max)
		var r2 := Rect2(Vector2((w - tw) * 0.5 - 32, y), Vector2(tw + 64, th + 28))
		Desenho.moldura(self, r2, Color(Tema.ELEVADO, 0.95 * alfa), Color(Tema.LINHA, alfa), 2, 12)
		Desenho.paragrafo(self, Vector2(r2.position.x + 32, y + 14 + f.get_ascent(Tema.t(Tema.T_AVISO))), s, f,
			Tema.T_AVISO, Color(Tema.FG, alfa), larg_max + 1.0, 2)
		y += r2.size.y + 12.0


## Os lugares, da direita para a esquerda a partir de `fim` (P4 mais à direita).
func _lugares(fim: Vector2) -> void:
	var larg := 250.0
	var alt := 92.0
	var x := fim.x - (larg * 4 + 16 * 3)
	for l in 4:
		var r := Rect2(Vector2(x + l * (larg + 16), fim.y), Vector2(larg, alt))
		var info: Dictionary = Forja.lugar(l)
		var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
		if not info.get("ocupado", false):
			Desenho.moldura(self, r, Color(Tema.APP, 0.7), Tema.SUTIL, 2, 12)
			Desenho.texto(self, r.position + Vector2(20, 40), "P%d  ·  —" % (l + 1), Tema.fonte(600), Tema.T_SELO, Tema.MUDO)
			continue
		var conectado: bool = info.get("conectado", false)
		Desenho.moldura(self, r, Color(Tema.APP, 0.9), cor_id if conectado else Tema.LARANJA, 3, 12)
		Desenho.texto(self, r.position + Vector2(20, 40), "P%d" % (l + 1), Tema.fonte(700), Tema.T_ROTULO, cor_id)
		if not conectado:
			Desenho.texto(self, r.position + Vector2(66, 40), "Sem controle", Tema.fonte(600), Tema.T_SELO, Tema.LARANJA)
			continue
		var p: Dictionary = Forja.pad(int(info.get("pad", -1)))
		Desenho.texto(self, r.position + Vector2(66, 40), str(p.get("conexao_curta", "")), Tema.fonte(600), Tema.T_SELO, Tema.FG)
		var pct: int = p.get("bateria", -1)
		if pct >= 0:
			var s := "%d%%" % pct
			var fm := Tema.mono(500)
			Desenho.texto(self, Vector2(r.end.x - 20 - Desenho.largura(s, fm, Tema.T_SELO), r.position.y + 40), s, fm, Tema.T_SELO, Tema.VERDE)
		var linha: String = status_da_sala[l]
		if linha != "":
			# a linha encolhe até caber (cortada, "4 bala" viraria "4 bal")
			var fl := Tema.fonte(500)
			var tam := Tema.T_SELO
			while tam > 20 and Desenho.largura(linha, fl, tam) > larg - 40:
				tam -= 1
			Desenho.texto(self, r.position + Vector2(20, 76), linha, fl, tam, Tema.SUAVE, HORIZONTAL_ALIGNMENT_LEFT, larg - 40)
		else:
			Desenho.leds(self, r.position + Vector2(20, 60), int(info.get("leds", 0)), 10.0)
