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
		var r := Rect2(Vector2((w - 620) * 0.5, h - 230), Vector2(620, 150))
		Desenho.moldura(self, r, Color(Tema.PAINEL, 0.96), Tema.LINHA, 2, Tema.RAIO_QUADRO)
		Desenho.texto(self, r.position + Vector2(32, 58), str(placa.get("nome", "")), Tema.fonte(700), 40, Tema.FG)
		Desenho.texto(self, r.position + Vector2(32, 100), str(placa.get("sobre", "")), Tema.fonte(500), Tema.T_ROTULO, Tema.ROXO)
		if aberta:
			var wd := Glifo.largura_dica("cruz", "entrar", Tema.T_CORPO)
			Glifo.dica(self, Vector2(r.end.x - 32 - wd, r.position.y + 84), "cruz", "entrar", Tema.T_CORPO, Tema.ROSA, Tema.FG)
		else:
			var s := "em breve"
			var fs := Tema.fonte(600)
			Desenho.texto(self, Vector2(r.end.x - 32 - Desenho.largura(s, fs, Tema.T_ROTULO), r.position.y + 84), s, fs, Tema.T_ROTULO, Tema.COMMENT)

	# as dicas de baixo
	var pares := [["create", "diagnóstico"], ["options", "pausa"]]
	Desenho.dicas_a_direita(self, Vector2(w - Tema.MARGEM_X, h - Tema.MARGEM_Y), pares, Tema.T_SELO)

	# os avisos
	var y := 190.0
	for a in _avisos:
		var alfa := clampf(a[1] / 0.4, 0.0, 1.0)
		var f := Tema.fonte(500)
		var tw := Desenho.largura(a[0], f, Tema.T_ROTULO)
		var r2 := Rect2(Vector2((w - tw) * 0.5 - 28, y), Vector2(tw + 56, 56))
		Desenho.moldura(self, r2, Color(Tema.ELEVADO, 0.95 * alfa), Color(Tema.LINHA, alfa), 2, 12)
		Desenho.texto(self, Vector2(r2.position.x + 28, y + 38), a[0], f, Tema.T_ROTULO, Color(Tema.FG, alfa))
		y += 68.0


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
			Desenho.texto(self, r.position + Vector2(66, 40), "sem controle", Tema.fonte(600), Tema.T_SELO, Tema.LARANJA)
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
			Desenho.texto(self, r.position + Vector2(20, 76), linha, Tema.fonte(500), 22, Tema.SUAVE, HORIZONTAL_ALIGNMENT_LEFT, larg - 40)
		else:
			Desenho.leds(self, r.position + Vector2(20, 60), int(info.get("leds", 0)), 10.0)
