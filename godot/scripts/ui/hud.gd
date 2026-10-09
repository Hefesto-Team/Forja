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

const LARG_CHIP := 340.0


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
		Desenho.cabecalho(self, Vector2(Tema.MARGEM_X, Tema.MARGEM_Y), 60.0)
	else:
		# o nome e a ação num quadro: a arena é clara e o texto não pode sumir nela
		var qd := quadro_da_sala(str(sala.get("nome", "")), str(sala.get("acao", "")), w)
		var q: Rect2 = qd["rect"]
		Desenho.moldura(self, q, Color(Tema.CASCO, 0.94), Tema.GRAFITE, 2, Tema.RAIO_QUADRO)
		Desenho.texto(self, q.position + Vector2(28, 56), qd["nome"], Tema.archivo(700), Tema.T_SUBTITULO, Tema.ETIQUETA)
		Desenho.paragrafo(self, q.position + Vector2(28, 96), qd["acao"], Tema.archivo(500), Tema.T_ROTULO, Tema.ETIQUETA,
			q.size.x - 56.0 + 1.0, 2)

	_lugares(Vector2(w - Tema.MARGEM_X, 40))

	# a placa do portão
	if not placa.is_empty():
		var aberta: bool = placa.get("aberta", false)
		var nome_p := str(placa.get("nome", ""))
		var sobre := str(placa.get("sobre", ""))
		var fn_p := Tema.archivo(700)
		var fs_p := Tema.archivo(500)
		var s := "Em breve"
		var fs := Tema.archivo(600)
		var wd := Glifo.largura_dica("cruz", "Entrar", Tema.T_CORPO) if aberta else Desenho.largura(s, fs, Tema.T_ROTULO)
		# a placa cresce com o texto: o "✕ entrar" nunca fica por cima do que ela diz
		var texto_w := maxf(Desenho.largura(nome_p, fn_p, 40), Desenho.largura(sobre, fs_p, Tema.T_ROTULO))
		var larg_p := clampf(texto_w + wd + 32 * 2 + 40, 620.0, w - 2 * Tema.MARGEM_X)
		var r := Rect2(Vector2((w - larg_p) * 0.5, h - 230), Vector2(larg_p, 150))
		Desenho.moldura(self, r, Color(Tema.CASCO, 0.96), Tema.GRAFITE, 2, Tema.RAIO_QUADRO)
		Desenho.texto(self, r.position + Vector2(32, 58), nome_p, fn_p, 40, Tema.ETIQUETA)
		Desenho.texto(self, r.position + Vector2(32, 100), sobre, fs_p, Tema.T_ROTULO, Tema.ETIQUETA)
		if aberta:
			Glifo.dica(self, Vector2(r.end.x - 32 - wd, r.position.y + 84), "cruz", "Entrar", Tema.T_CORPO, Tema.ETIQUETA, Tema.ETIQUETA)
		else:
			Desenho.texto(self, Vector2(r.end.x - 32 - wd, r.position.y + 84), s, fs, Tema.T_ROTULO, Tema.MUDO)

	# as dicas de baixo
	var pares := [["create", "Diagnóstico"], ["options", "Pausa"]] if create_livre and Forja.bancada else [["options", "Pausa"]]
	Desenho.dicas_a_direita(self, Vector2(w - Tema.MARGEM_X, h - Tema.MARGEM_Y), pares, Tema.T_SELO, not sala.is_empty())

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


## O quadro do nome e da ação da sala: do recuo da margem até antes do primeiro
## chip de lugar, nunca por cima dele. A ação cabe em até duas linhas. Devolve
## {rect, nome, acao}; o painel da sala desce as faixas dele para baixo do `rect`.
static func quadro_da_sala(nome: String, acao: String, w: float) -> Dictionary:
	var x := float(Tema.MARGEM_X - 28)
	var x_chips := w - Tema.MARGEM_X - (LARG_CHIP * 4 + 16.0 * 3)
	var larg := x_chips - 24.0 - x
	var fn := Tema.archivo(700)
	var fa := Tema.archivo(500)
	var dito_nome := Desenho.caber(nome, fn, Tema.T_SUBTITULO, larg - 56.0, 1)
	var dita_acao := Desenho.caber(acao, fa, Tema.T_ROTULO, larg - 56.0, 2)
	var uma := fa.get_height(Tema.t(Tema.T_ROTULO))
	var extra := maxf(0.0, Desenho.altura_paragrafo(dita_acao, fa, Tema.T_ROTULO, larg - 56.0, 2) - uma)
	return {"rect": Rect2(Vector2(x, 40), Vector2(larg, 118.0 + ceilf(extra))), "nome": dito_nome, "acao": dita_acao}


## A linha de status de um chip, cortada no chip: nunca passa para o chip do lado
## (dois chips com «Brasa · vida 1 · 1 balas» e «Brasa · derrubado» se tocavam).
static func linha_do_status(linha: String) -> String:
	return Desenho.caber(linha, Tema.archivo(500), Tema.T_SELO, LARG_CHIP - 40.0, 1)


## Os lugares, da direita para a esquerda a partir de `fim` (P4 mais à direita).
func _lugares(fim: Vector2) -> void:
	var larg := LARG_CHIP
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
			Desenho.texto(self, r.position + Vector2(20, 76), linha_do_status(linha), Tema.archivo(500), Tema.T_SELO,
				Tema.ETIQUETA_SOMBRA, HORIZONTAL_ALIGNMENT_LEFT, larg - 40)
		else:
			Desenho.leds(self, r.position + Vector2(20, 60), int(info.get("leds", 0)), 10.0)
