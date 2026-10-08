class_name Diagnostico
extends Control
## O diagnóstico ao vivo: uma coluna por lugar, com o mapa do controle e os
## números — o que o controle manda ao jogo (entrada) e o que o jogo manda a
## ele (saída), com as últimas saídas por extenso. Serve para quem valida ver,
## antes de qualquer sala, que cada coisa chega e sai no controle certo.

const MODOS := ["solto", "resistência", "arma", "vibração"]
const LED_MIC := ["apagado", "aceso", "piscando", "piscando lento"]

var mapas: Array[MapaDoControle] = []
var _t := 0.0

const COLUNA := 408.0
const CALHA := 32.0
const TOPO := 170.0
const ALTURA_MAPA := 190.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 4:
		var m := MapaDoControle.new()
		m.lugar = i
		add_child(m)
		mapas.append(m)
	resized.connect(_posicionar)
	_posicionar()


func _x0() -> float:
	return (size.x - (COLUNA * 4 + CALHA * 3)) * 0.5


func _posicionar() -> void:
	for i in 4:
		mapas[i].position = Vector2(_x0() + i * (COLUNA + CALHA) + 24, TOPO + 64)
		mapas[i].size = Vector2(COLUNA - 48, ALTURA_MAPA)


func _process(dt: float) -> void:
	_t += dt
	if visible:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.CASA, 0.94))
	Desenho.texto(self, Vector2(Tema.MARGEM_X, 108), "Diagnóstico", Tema.fonte(700), 56, Tema.FG)
	var pulso := 0.6 + 0.4 * absf(sin(_t * PI))
	Desenho.selo(self, Vector2(Tema.MARGEM_X + 370, 70), "AO VIVO", Color(Tema.LARANJA, pulso))
	Desenho.texto(self, Vector2(Tema.MARGEM_X + 530, 102), "O que cada controle manda ao jogo, e o que o jogo manda a ele.",
		Tema.fonte(400), Tema.T_ROTULO, Tema.SUAVE)
	for l in 4:
		_coluna(l, Vector2(_x0() + l * (COLUNA + CALHA), TOPO))
	Desenho.dicas_a_direita(self, Vector2(size.x - Tema.MARGEM_X, size.y - 40), [["circulo", "Fechar"]], Tema.T_SELO)


## Um número sem o "-0" do zero negativo.
func _n(v: float, casas := 2) -> String:
	if absf(v) < 0.5 * pow(10.0, -casas):
		v = 0.0
	return ("%+." + str(casas) + "f") % v


func _rotulo(pos: Vector2, texto: String) -> void:
	Desenho.texto(self, pos, texto, Tema.fonte(600), 22, Tema.VERDE)


func _valor(pos: Vector2, texto: String, cor := Tema.CIANO, larg := 230.0) -> void:
	Desenho.texto(self, pos, texto, Tema.mono(500), 22, cor, HORIZONTAL_ALIGNMENT_LEFT, larg)


func _barra(pos: Vector2, v: float, cor: Color, larg := 200.0) -> void:
	draw_rect(Rect2(pos + Vector2(0, -12), Vector2(larg, 8)), Tema.TRILHO)
	draw_rect(Rect2(pos + Vector2(0, -12), Vector2(larg * clampf(v, 0, 1), 8)), cor)


## O analógico como no app: o anel, a cruz do centro e o ponto rosa onde ele está.
func _analogico(centro: Vector2, v: Vector2, apertado: bool) -> void:
	var raio := 30.0
	draw_arc(centro, raio, 0, TAU, 40, Tema.ROSA if apertado else Tema.LINHA, 2.0, true)
	draw_line(centro - Vector2(raio, 0), centro + Vector2(raio, 0), Tema.SUTIL, 1.0)
	draw_line(centro - Vector2(0, raio), centro + Vector2(0, raio), Tema.SUTIL, 1.0)
	draw_circle(centro + v.limit_length(1.0) * (raio - 5), 6.0, Tema.ROSA)


## O gatilho analógico: o trilho em pé, cheio de rosa até o curso.
func _gatilho(pos: Vector2, v: float, nome: String) -> void:
	var h := 60.0
	draw_rect(Rect2(pos, Vector2(12, h)), Tema.TRILHO)
	draw_rect(Rect2(pos + Vector2(0, h * (1.0 - clampf(v, 0, 1))), Vector2(12, h * clampf(v, 0, 1))), Tema.ROSA)
	Desenho.texto(self, pos + Vector2(-4, h + 26), nome, Tema.mono(500), 20, Tema.SUAVE)


func _coluna(l: int, o: Vector2) -> void:
	var r := Rect2(o, Vector2(COLUNA, size.y - o.y - 80))
	var info: Dictionary = Forja.lugar(l)
	var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
	var ocupado: bool = info.get("ocupado", false)
	var conectado: bool = info.get("conectado", false)
	mapas[l].visible = ocupado
	if not ocupado:
		Desenho.moldura(self, r, Color(Tema.PAINEL, 0.6), Tema.SUTIL, 2, Tema.RAIO_QUADRO)
		Desenho.texto(self, o + Vector2(24, 48), "P%d  ·  —" % (l + 1), Tema.fonte(600), Tema.T_ROTULO, Tema.MUDO)
		return
	Desenho.moldura(self, r, Tema.PAINEL, cor_id if conectado else Tema.LARANJA, 3, Tema.RAIO_QUADRO)
	var p: Dictionary = Forja.pad(int(info.get("pad", -1))) if conectado else {}
	Desenho.texto(self, o + Vector2(24, 46), "P%d" % (l + 1), Tema.fonte(700), Tema.T_CORPO, cor_id)
	var cabeca := "%s  ·  %s" % [p.get("conexao_curta", "Sem controle"), p.get("origem_curta", "")] if conectado else "Sem controle"
	Desenho.texto(self, o + Vector2(76, 46), cabeca, Tema.fonte(600), 22, Tema.FG if conectado else Tema.LARANJA, HORIZONTAL_ALIGNMENT_LEFT, COLUNA - 100)
	if not conectado:
		return

	var x := o.x + 24.0
	var y := o.y + 64.0 + ALTURA_MAPA + 34.0
	Desenho.texto(self, Vector2(x, y), "Entrada", Tema.fonte(600), Tema.T_SELO, Tema.ROXO)
	# os dois analógicos e os dois gatilhos, desenhados
	var lv := Vector2(Forja.eixo(l, Forja.LX), Forja.eixo(l, Forja.LY))
	var rv := Vector2(Forja.eixo(l, Forja.RX), Forja.eixo(l, Forja.RY))
	_analogico(Vector2(x + 34, y + 52), lv, Forja.segura(l, Forja.L3))
	_analogico(Vector2(x + 118, y + 52), rv, Forja.segura(l, Forja.R3))
	_gatilho(Vector2(x + 186, y + 22), Forja.eixo(l, Forja.L2), "L2")
	_gatilho(Vector2(x + 232, y + 22), Forja.eixo(l, Forja.R2), "R2")
	_valor(Vector2(x + 268, y + 44), _n(Forja.eixo(l, Forja.L2)).substr(1), Tema.CIANO, 90)
	_valor(Vector2(x + 268, y + 76), _n(Forja.eixo(l, Forja.R2)).substr(1), Tema.CIANO, 90)
	y += 132
	Desenho.texto(self, Vector2(x, y), "L %s %s  R %s %s" % [_n(lv.x), _n(lv.y), _n(rv.x), _n(rv.y)],
		Tema.mono(500), 20, Tema.SUAVE, HORIZONTAL_ALIGNMENT_LEFT, COLUNA - 48)
	y += 36
	var g := Forja.giro(l) * (180.0 / PI)
	_rotulo(Vector2(x, y), "Giro")
	_valor(Vector2(x + 80, y), "%s %s %s °/s" % [_n(g.x, 0), _n(g.y, 0), _n(g.z, 0)], Tema.CIANO, 280)
	y += 32
	var a := Forja.acel(l) / 9.80665
	_rotulo(Vector2(x, y), "Acel")
	_valor(Vector2(x + 80, y), "%s %s %s g" % [_n(a.x), _n(a.y), _n(a.z)], Tema.CIANO, 280)
	y += 32
	var hz := Forja.giro_hz(l)
	_rotulo(Vector2(x, y), "Taxa")
	_valor(Vector2(x + 80, y), ("%.0f Hz" % hz) if hz > 0.5 else "sem amostras", Tema.SUAVE, 280)
	y += 32
	var toque := "—"
	for i in 2:
		var d := Forja.dedo(l, i)
		if d.z > 0.5:
			toque = ("" if toque == "—" else toque + "  ") + "%.2f %.2f" % [d.x, d.y]
	_rotulo(Vector2(x, y), "Toque")
	_valor(Vector2(x + 80, y), toque, Tema.CIANO, 280)

	y += 50
	Desenho.texto(self, Vector2(x, y), "Saída", Tema.fonte(600), Tema.T_SELO, Tema.ROXO)
	y += 34
	var s: Dictionary = Forja.estado_saida(l)
	_rotulo(Vector2(x, y), "Motores")
	_barra(Vector2(x + 110, y), float(s.get("forte", 0.0)), Tema.LARANJA, 100)
	_barra(Vector2(x + 236, y), float(s.get("fraco", 0.0)), Tema.LARANJA, 100)
	y += 32
	var luz: Color = s.get("luz", Color.BLACK)
	_rotulo(Vector2(x, y), "Luz")
	Desenho.moldura(self, Rect2(Vector2(x + 110, y - 20), Vector2(48, 24)), luz, Tema.LINHA, 2, 6)
	_valor(Vector2(x + 170, y), "#" + luz.to_html(false), Tema.CIANO, 180)
	y += 32
	_rotulo(Vector2(x, y), "Gatilhos")
	var modos := "L2 %s · R2 %s" % [MODOS[clampi(int(s.get("l2", 0)), 0, 3)], MODOS[clampi(int(s.get("r2", 0)), 0, 3)]]
	Desenho.texto(self, Vector2(x + 110, y), modos, Tema.fonte(500), 22, Tema.CIANO, HORIZONTAL_ALIGNMENT_LEFT, COLUNA - 158)
	y += 32
	_rotulo(Vector2(x, y), "LEDs")
	Desenho.leds(self, Vector2(x + 110, y - 16), int(s.get("leds_jogador", 0)), 12.0)
	y += 32
	var mic := int(s.get("led_mic", 0))
	_rotulo(Vector2(x, y), "Mudo")
	Desenho.texto(self, Vector2(x + 110, y), LED_MIC[clampi(mic, 0, 3)], Tema.fonte(500), 22,
		Tema.LARANJA if mic else Tema.SUAVE, HORIZONTAL_ALIGNMENT_LEFT, COLUNA - 158)
	# a última saída, por extenso (sem o tempo: é a mais nova)
	var ult: PackedStringArray = Forja.saidas(l)
	if ult.size() > 0:
		y += 30
		draw_line(Vector2(x, y - 20), Vector2(x + COLUNA - 48, y - 20), Tema.SUTIL, 1.0)
		var linha := ult[0].strip_edges()
		var corte := linha.find("  ")
		if corte > 0:
			linha = linha.substr(corte).strip_edges()
		Desenho.texto(self, Vector2(x, y + 4), linha, Tema.mono(400), 20, Tema.SUAVE, HORIZONTAL_ALIGNMENT_LEFT, COLUNA - 48)
