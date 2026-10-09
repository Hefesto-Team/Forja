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
const TOPO := 150.0
const ALTURA_MAPA := 150.0
const LIN := 38.0  ## o passo de uma linha de número (letra de 30 px)
const ROT := 132.0  ## onde começa o valor, depois do rótulo


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
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.FITA, 0.94))
	Desenho.texto(self, Vector2(Tema.MARGEM_X, 108), "Diagnóstico", Tema.bungee(), Tema.T_TITULO, Tema.ETIQUETA)
	var pulso := 0.6 + 0.4 * absf(sin(_t * PI))
	Desenho.selo(self, Vector2(Tema.MARGEM_X + 430, 70), "AO VIVO", Color(Tema.SECAO[3], pulso))
	Desenho.texto(self, Vector2(Tema.MARGEM_X + 600, 102), "O que cada controle manda ao jogo, e o que o jogo manda a ele.",
		Tema.archivo(500), Tema.T_ROTULO, Tema.ETIQUETA_SOMBRA, HORIZONTAL_ALIGNMENT_LEFT, size.x - Tema.MARGEM_X * 2 - 600 - 230)
	for l in 4:
		_coluna(l, Vector2(_x0() + l * (COLUNA + CALHA), TOPO))
	Desenho.dicas_a_direita(self, Vector2(size.x - Tema.MARGEM_X, 102), [["circulo", "Fechar"]], Tema.T_SELO)


## Um número sem o "-0" do zero negativo.
func _n(v: float, casas := 2) -> String:
	if absf(v) < 0.5 * pow(10.0, -casas):
		v = 0.0
	return ("%+." + str(casas) + "f") % v


func _rotulo(pos: Vector2, texto: String) -> void:
	Desenho.texto(self, pos, texto, Tema.archivo(600), Tema.T_ROTULO, Tema.ETIQUETA)


func _valor(pos: Vector2, texto: String, cor := Tema.ETIQUETA, larg := 230.0) -> void:
	Desenho.texto(self, pos, texto, Tema.vt(), Tema.T_MONO, cor, HORIZONTAL_ALIGNMENT_LEFT, larg)


func _barra(pos: Vector2, v: float, cor: Color, larg := 200.0) -> void:
	draw_rect(Rect2(pos + Vector2(0, -12), Vector2(larg, 8)), Tema.GRAFITE)
	draw_rect(Rect2(pos + Vector2(0, -12), Vector2(larg * clampf(v, 0, 1), 8)), cor)


## O analógico como no app: o anel, a cruz do centro e o ponto claro onde ele está.
func _analogico(centro: Vector2, v: Vector2, apertado: bool) -> void:
	var raio := 30.0
	draw_arc(centro, raio, 0, TAU, 40, Tema.ETIQUETA if apertado else Tema.GRAFITE, 2.0, true)
	draw_line(centro - Vector2(raio, 0), centro + Vector2(raio, 0), Tema.GRAFITE, 1.0)
	draw_line(centro - Vector2(0, raio), centro + Vector2(0, raio), Tema.GRAFITE, 1.0)
	draw_circle(centro + v.limit_length(1.0) * (raio - 5), 6.0, Tema.ETIQUETA)


## O gatilho analógico: o trilho em pé, cheio até o curso.
func _gatilho(pos: Vector2, v: float, nome: String) -> void:
	var h := 60.0
	draw_rect(Rect2(pos, Vector2(12, h)), Tema.GRAFITE)
	draw_rect(Rect2(pos + Vector2(0, h * (1.0 - clampf(v, 0, 1))), Vector2(12, h * clampf(v, 0, 1))), Tema.ETIQUETA)
	Desenho.texto(self, pos + Vector2(-6, h + 30), nome, Tema.vt(), Tema.T_MONO, Tema.ETIQUETA_SOMBRA)


func _coluna(l: int, o: Vector2) -> void:
	var r := Rect2(o, Vector2(COLUNA, size.y - o.y - Tema.MARGEM_Y))
	var info: Dictionary = Forja.lugar(l)
	var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
	var ocupado: bool = info.get("ocupado", false)
	var conectado: bool = info.get("conectado", false)
	mapas[l].visible = ocupado
	if not ocupado:
		Desenho.moldura(self, r, Color(Tema.CASCO, 0.6), Tema.GRAFITE, 2, Tema.RAIO_QUADRO)
		Desenho.texto(self, o + Vector2(24, 48), "P%d  ·  —" % (l + 1), Tema.archivo(600), Tema.T_ROTULO, Tema.MUDO)
		return
	Desenho.moldura(self, r, Tema.CASCO, cor_id if conectado else Tema.SECAO[3], 3, Tema.RAIO_QUADRO)
	var p: Dictionary = Forja.pad(int(info.get("pad", -1))) if conectado else {}
	Desenho.texto(self, o + Vector2(24, 46), "P%d" % (l + 1), Tema.bungee(), Tema.T_PSHARP, cor_id)
	var cabeca := "%s  ·  %s" % [p.get("conexao_curta", "Sem controle"), p.get("origem_curta", "")] if conectado else "Sem controle"
	Desenho.texto(self, o + Vector2(92, 46), Desenho.caber(cabeca, Tema.archivo(600), Tema.T_ROTULO, COLUNA - 116, 1), Tema.archivo(600), Tema.T_ROTULO, Tema.ETIQUETA if conectado else Tema.SECAO[3], HORIZONTAL_ALIGNMENT_LEFT, COLUNA - 116)
	if not conectado:
		return

	var x := o.x + 24.0
	var y := o.y + 64.0 + ALTURA_MAPA + 36.0
	Desenho.texto(self, Vector2(x, y), "Entrada", Tema.archivo(600), Tema.T_SELO, Tema.ETIQUETA)
	# os dois analógicos e os dois gatilhos, desenhados
	var lv := Vector2(Forja.eixo(l, Forja.LX), Forja.eixo(l, Forja.LY))
	var rv := Vector2(Forja.eixo(l, Forja.RX), Forja.eixo(l, Forja.RY))
	_analogico(Vector2(x + 34, y + 52), lv, Forja.segura(l, Forja.L3))
	_analogico(Vector2(x + 118, y + 52), rv, Forja.segura(l, Forja.R3))
	_gatilho(Vector2(x + 186, y + 22), Forja.eixo(l, Forja.L2), "L2")
	_gatilho(Vector2(x + 232, y + 22), Forja.eixo(l, Forja.R2), "R2")
	_valor(Vector2(x + 268, y + 46), _n(Forja.eixo(l, Forja.L2)).substr(1), Tema.ETIQUETA, 90)
	_valor(Vector2(x + 268, y + 80), _n(Forja.eixo(l, Forja.R2)).substr(1), Tema.ETIQUETA, 90)
	y += 120
	Desenho.texto(self, Vector2(x, y), "L %s %s  R %s %s" % [_n(lv.x), _n(lv.y), _n(rv.x), _n(rv.y)],
		Tema.vt(), Tema.T_MONO, Tema.ETIQUETA_SOMBRA, HORIZONTAL_ALIGNMENT_LEFT, COLUNA - 48)
	y += LIN
	var g := Forja.giro(l) * (180.0 / PI)
	_rotulo(Vector2(x, y), "Giro")
	_valor(Vector2(x + ROT, y), "%s %s %s °/s" % [_n(g.x, 0), _n(g.y, 0), _n(g.z, 0)], Tema.ETIQUETA, COLUNA - 48 - ROT)
	y += LIN
	var a := Forja.acel(l) / 9.80665
	_rotulo(Vector2(x, y), "Acel")
	_valor(Vector2(x + ROT, y), "%s %s %s g" % [_n(a.x), _n(a.y), _n(a.z)], Tema.ETIQUETA, COLUNA - 48 - ROT)
	y += LIN
	var hz := Forja.giro_hz(l)
	_rotulo(Vector2(x, y), "Taxa")
	_valor(Vector2(x + ROT, y), ("%.0f Hz" % hz) if hz > 0.5 else "sem amostras", Tema.ETIQUETA_SOMBRA, COLUNA - 48 - ROT)
	y += LIN
	var toque := "—"
	for i in 2:
		var d := Forja.dedo(l, i)
		if d.z > 0.5:
			toque = ("" if toque == "—" else toque + "  ") + "%.2f %.2f" % [d.x, d.y]
	_rotulo(Vector2(x, y), "Toque")
	_valor(Vector2(x + ROT, y), toque, Tema.ETIQUETA, COLUNA - 48 - ROT)

	y += LIN + 12.0
	Desenho.texto(self, Vector2(x, y), "Saída", Tema.archivo(600), Tema.T_SELO, Tema.ETIQUETA)
	y += LIN
	var s: Dictionary = Forja.estado_saida(l)
	_rotulo(Vector2(x, y), "Motores")
	_barra(Vector2(x + ROT, y), float(s.get("forte", 0.0)), Tema.SECAO[3], 96)
	_barra(Vector2(x + ROT + 114, y), float(s.get("fraco", 0.0)), Tema.SECAO[3], 96)
	y += LIN
	var luz: Color = s.get("luz", Color.TRANSPARENT)
	_rotulo(Vector2(x, y), "Luz")
	Desenho.moldura(self, Rect2(Vector2(x + ROT, y - 24), Vector2(48, 28)), luz, Tema.GRAFITE, 2, 6)
	_valor(Vector2(x + ROT + 60, y), "#" + luz.to_html(false), Tema.ETIQUETA, 160)
	y += LIN
	_rotulo(Vector2(x, y), "Gatilho L2")
	Desenho.texto(self, Vector2(x + ROT + 24, y), MODOS[clampi(int(s.get("l2", 0)), 0, 3)], Tema.archivo(500), Tema.T_ROTULO,
		Tema.ETIQUETA, HORIZONTAL_ALIGNMENT_LEFT, COLUNA - 48 - ROT - 24)
	y += LIN
	_rotulo(Vector2(x, y), "Gatilho R2")
	Desenho.texto(self, Vector2(x + ROT + 24, y), MODOS[clampi(int(s.get("r2", 0)), 0, 3)], Tema.archivo(500), Tema.T_ROTULO,
		Tema.ETIQUETA, HORIZONTAL_ALIGNMENT_LEFT, COLUNA - 48 - ROT - 24)
	y += LIN
	_rotulo(Vector2(x, y), "LEDs")
	Desenho.leds(self, Vector2(x + ROT, y - 16), int(s.get("leds_jogador", 0)), 12.0)
	y += LIN
	var mic := int(s.get("led_mic", 0))
	_rotulo(Vector2(x, y), "Mudo")
	Desenho.texto(self, Vector2(x + ROT, y), LED_MIC[clampi(mic, 0, 3)], Tema.archivo(500), Tema.T_ROTULO,
		Tema.SECAO[3] if mic else Tema.ETIQUETA_SOMBRA, HORIZONTAL_ALIGNMENT_LEFT, COLUNA - 48 - ROT)
	# a última saída, por extenso (sem o tempo: é a mais nova)
	var ult: PackedStringArray = Forja.saidas(l)
	if ult.size() > 0:
		y += LIN
		draw_line(Vector2(x, y - 28), Vector2(x + COLUNA - 48, y - 28), Tema.GRAFITE, 1.0)
		var linha := ult[0].strip_edges()
		var corte := linha.find("  ")
		if corte > 0:
			linha = linha.substr(corte).strip_edges()
		Desenho.texto(self, Vector2(x, y), Desenho.caber(linha, Tema.vt(), Tema.T_MONO, COLUNA - 48, 1), Tema.vt(), Tema.T_MONO, Tema.ETIQUETA_SOMBRA, HORIZONTAL_ALIGNMENT_LEFT, COLUNA - 48)
