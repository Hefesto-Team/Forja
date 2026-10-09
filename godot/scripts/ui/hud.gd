class_name HudJogo
extends Control
## A HUD do salão e das salas, mínima: o que decide o próximo segundo. Em cima,
## os lugares (P1..P4, sempre na mesma ordem) com a conexão e a bateria; perto
## de um portão, a dica presa à cabeça de quem chegou; nas salas, o nome e a ação
## numa linha. O salão conta a noite (G06): o contador n/9, os chips com os nomes e
## a dica presa. Os avisos do módulo aparecem no alto e somem sozinhos.

## As seções acesas de 9 (os 8 portões e A Prova); -1 fora do salão (não desenha o contador).
var vencidas := -1
## A dica presa à cabeça de quem está perto de um portão ou da bigorna:
## {lugar, cabeca (a posição no mundo), linhas: [[glifo, frase]], fechado}; vazio sem ninguém perto.
var dica_presa := {}
## O mundo para onde a dica olha: a dica segue a cabeça do cavaleiro (o main põe).
var camera: Camera3D
## O nome do cavaleiro de cada lugar, para o chip do salão (o main põe).
var nomes := ["", "", "", ""]
## A sala em curso: {nome, acao} ou vazio.
var sala := {}
## Uma linha por lugar, dita pela sala (vida, pontos, o que falta).
var status_da_sala := ["", "", "", ""]
## false numa sala que usa o Create (a runa d'A Centelha): o rodapé não o oferece
var create_livre := true

var _avisos: Array = []  # [texto, restante]
var _rets: Array[Rect2] = []   ## o que o salão desenhou neste quadro (a prova confere que cabe na tela)


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
		draw_rect(Rect2(0, i * 7, w, 7), Color(Tema.FITA, 0.55 * (1.0 - i / 20.0)))

	if sala.is_empty():
		Desenho.cabecalho(self, Vector2(Tema.MARGEM_X, 40), 60.0)
	else:
		# o nome e a ação num quadro: a arena é clara e o texto não pode sumir nela
		var fn := Tema.archivo(700)
		var fa := Tema.archivo(500)
		var nome := str(sala.get("nome", ""))
		var acao := str(sala.get("acao", ""))
		var larg := maxf(Desenho.largura(nome, fn, Tema.T_SUBTITULO), Desenho.largura(acao, fa, Tema.T_ROTULO)) + 56
		var q := Rect2(Vector2(Tema.MARGEM_X - 28, 40), Vector2(larg, 118))
		Desenho.moldura(self, q, Color(Tema.CASCO, 0.94), Tema.GRAFITE, 2, Tema.RAIO_QUADRO)
		Desenho.texto(self, q.position + Vector2(28, 56), nome, fn, Tema.T_SUBTITULO, Tema.ETIQUETA)
		Desenho.texto(self, q.position + Vector2(28, 96), acao, fa, Tema.T_ROTULO, Tema.ETIQUETA)

	_lugares(Vector2(w - Tema.MARGEM_X, 40))

	_rets.clear()
	if vencidas >= 0:
		_salao(w, h)

	# as dicas de baixo
	var pares := [["create", "Diagnóstico"], ["options", "Pausa"]] if create_livre and Forja.bancada else [["options", "Pausa"]]
	Desenho.dicas_a_direita(self, Vector2(w - Tema.MARGEM_X, h - Tema.MARGEM_Y), pares, Tema.T_SELO)

	# os avisos
	# o texto que some sozinho é grande e curto: 46 px, até duas linhas
	var y := 190.0
	for a in _avisos:
		var alfa := clampf(a[1] / 0.4, 0.0, 1.0)
		var f := Tema.archivo(500)
		var larg_max := 1100.0
		var s := Desenho.caber(a[0], f, Tema.T_AVISO, larg_max, 2)
		var tw := minf(Desenho.largura(s, f, Tema.T_AVISO), larg_max)
		var th := Desenho.altura_paragrafo(s, f, Tema.T_AVISO, larg_max)
		var r2 := Rect2(Vector2((w - tw) * 0.5 - 32, y), Vector2(tw + 64, th + 28))
		Desenho.moldura(self, r2, Color(Tema.CASCO_ALTO, 0.95 * alfa), Color(Tema.GRAFITE, alfa), 2, 12)
		Desenho.paragrafo(self, Vector2(r2.position.x + 32, y + 14 + f.get_ascent(Tema.t(Tema.T_AVISO))), s, f,
			Tema.T_AVISO, Color(Tema.ETIQUETA, alfa), larg_max + 1.0, 2)
		y += r2.size.y + 12.0


## O que o salão põe na tela: o contador, «Salas vencidas», os chips e a dica presa.
func _salao(w: float, h: float) -> void:
	# o contador fica logo abaixo dos lugares (a faixa de cima é deles)
	var topo := 40.0 + 92.0 + 16.0
	var c := Desenho.contador(self, Vector2(w - Tema.MARGEM_X - 121.0, topo), "%d/9" % vencidas, 64)
	_rets.append(c)
	var f := Tema.archivo(500)
	var rotulo := Desenho.t("Salas vencidas")
	var lw := Desenho.largura(rotulo, f, 32)
	Desenho.texto(self, Vector2(c.position.x - 20.0 - lw, c.position.y + 48.0), rotulo, f, 32, Tema.ETIQUETA)
	_rets.append(Rect2(Vector2(c.position.x - 20.0 - lw, c.position.y + 16.0), Vector2(lw, 40)))
	# os chips, uma fileira de quatro, só dos lugares ocupados, acima das dicas de baixo
	var y := h - Tema.MARGEM_Y - 64.0 - 70.0
	var x0 := (w - (4 * 400.0 + 3 * 16.0)) * 0.5
	for l in 4:
		if not Forja.ocupado(l):
			continue
		var r := Rect2(Vector2(x0 + l * 416.0, y), Vector2(400, 64))
		var info: Dictionary = Forja.lugar(l)
		var com_controle: bool = info.get("conectado", false)
		Desenho.chip(self, r, l, com_controle, str(nomes[l]) if com_controle else Desenho.t("Sem controle"))
		_rets.append(r)
	_dica_presa(w, h)


## A placa presa à cabeça de quem está perto de um portão ou da bigorna: o verbo, na cor do dono.
func _dica_presa(w: float, h: float) -> void:
	if dica_presa.is_empty() or camera == null:
		return
	var l := int(dica_presa.get("lugar", -1))
	var linhas: Array = dica_presa.get("linhas", [])
	if l < 0 or l > 3 or linhas.is_empty():
		return
	var cabeca: Vector3 = dica_presa.get("cabeca", Vector3.ZERO)
	var c := camera.unproject_position(cabeca)
	var mais := 0.0
	for ln in linhas:
		mais = maxf(mais, Glifo.largura_dica(str(ln[0]), str(ln[1]), Tema.T_CORPO))
	var larg := 24.0 + mais + 24.0
	var alt := 34.0 + 62.0 * linhas.size() + 10.0
	var x := c.x + 60.0
	var lado_direito := true
	if x + larg > w - Tema.MARGEM_X:
		x = c.x - 60.0 - larg
		lado_direito = false
	var y := clampf(c.y - 60.0, Tema.MARGEM_Y, h - Tema.MARGEM_Y - alt)
	var r := Rect2(Vector2(x, y), Vector2(larg, alt))
	var fechado: bool = dica_presa.get("fechado", false)
	var tarja: Color = Tema.ETIQUETA_SOMBRA if fechado else Tema.JOGADOR[l]
	draw_rect(Rect2(r.position + Vector2(4, 4), r.size), Tema.SOMBRA)
	draw_rect(r, Tema.ETIQUETA)
	draw_rect(Rect2(r.position + Vector2(0, 14), Vector2(r.size.x, 12)), tarja)
	# a ponta, do lado do cavaleiro
	var py := r.position.y + 40.0   # a ponta vai de 40 a 72 px do topo
	if lado_direito:
		draw_colored_polygon(PackedVector2Array([Vector2(r.position.x, py), Vector2(r.position.x - 16, py + 16), Vector2(r.position.x, py + 32)]), Tema.ETIQUETA)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(r.end.x, py), Vector2(r.end.x + 16, py + 16), Vector2(r.end.x, py + 32)]), Tema.ETIQUETA)
	for i in linhas.size():
		Glifo.dica(self, r.position + Vector2(24, 34 + 62.0 * i + 44.0), str(linhas[i][0]), str(linhas[i][1]), Tema.T_CORPO, Tema.TINTA, Tema.TINTA)
	_rets.append(r)


## Os retângulos do salão neste quadro (o contador, o rótulo, os chips, a dica presa).
func retangulos() -> Array[Rect2]:
	return _rets


## Os lugares, da direita para a esquerda a partir de `fim` (P4 mais à direita).
func _lugares(fim: Vector2) -> void:
	var larg := 340.0
	var alt := 92.0
	var x := fim.x - (larg * 4 + 16 * 3)
	for l in 4:
		var r := Rect2(Vector2(x + l * (larg + 16), fim.y), Vector2(larg, alt))
		var info: Dictionary = Forja.lugar(l)
		var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
		if not info.get("ocupado", false):
			Desenho.moldura(self, r, Color(Tema.CASCO, 0.7), Tema.GRAFITE, 2, 12)
			Desenho.texto(self, r.position + Vector2(20, 40), "P%d  ·  —" % (l + 1), Tema.archivo(600), Tema.T_SELO, Tema.MUDO)
			continue
		var conectado: bool = info.get("conectado", false)
		Desenho.moldura(self, r, Color(Tema.CASCO, 0.9), cor_id if conectado else Tema.SECAO[3], 3, 12)
		Desenho.texto(self, r.position + Vector2(20, 44), "P%d" % (l + 1), Tema.bungee(), Tema.T_PSHARP, cor_id)
		if not conectado:
			Desenho.texto(self, r.position + Vector2(92, 40), "Sem controle", Tema.archivo(600), Tema.T_SELO, Tema.SECAO[3])
			continue
		var p: Dictionary = Forja.pad(int(info.get("pad", -1)))
		Desenho.texto(self, r.position + Vector2(92, 40), str(p.get("conexao_curta", "")), Tema.archivo(600), Tema.T_SELO, Tema.ETIQUETA)
		var pct: int = p.get("bateria", -1)
		if pct >= 0:
			var s := "%d%%" % pct
			var fm := Tema.vt()
			Desenho.texto(self, Vector2(r.end.x - 20 - Desenho.largura(s, fm, Tema.T_SELO), r.position.y + 40), s, fm, Tema.T_SELO, Tema.ETIQUETA)
		var linha: String = status_da_sala[l]
		if linha != "":
			# a linha encolhe até caber (cortada, "4 bala" viraria "4 bal")
			# a letra não encolhe (nada abaixo de 30 px): a linha que não cabe fecha com «…»
			var fl := Tema.archivo(500)
			var dita := Desenho.caber(linha, fl, Tema.T_SELO, larg - 40, 1)
			Desenho.texto(self, r.position + Vector2(20, 76), dita, fl, Tema.T_SELO, Tema.ETIQUETA_SOMBRA, HORIZONTAL_ALIGNMENT_LEFT, larg - 40)
		else:
			Desenho.leds(self, r.position + Vector2(20, 60), int(info.get("leds", 0)), 10.0)
