class_name HudJogo
extends Control
## A HUD do salão e das salas (G04): nas salas, o cartão de cada jogador no canto dele (a tira do console: P#,
## lâmpadas, nome, pontos, item, VU e combo), a etiqueta da faixa e o deck no alto, que é o relógio; perto de um
## portão, a dica presa à cabeça de quem chegou. O salão conta a noite (G06): a etiqueta «O Salão», o contador n/9,
## os chips com os nomes e a dica presa. Os avisos do módulo aparecem no meio e somem sozinhos. Um cálculo só
## (`retangulos()`) serve ao desenho e à prova.

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
## Uma linha por lugar, dita pela sala (vida, pontos, o que falta). G04: o cartão não a mostra mais (o 06: «Nada
## mais»); o que a sala diz por lugar está na dica presa à raia. O main ainda a escreve.
var status_da_sala := ["", "", "", ""]
## false numa sala que usa o Create (a runa d'A Centelha): o rodapé não o oferece
var create_livre := true
## A SalaJogo em curso (o main põe): a fase, o relógio do deck e o treino.
var da_sala: Node = null
## O combo de cada lugar e o maior da sala (o pico do VU); o main põe o combo a cada quadro e zera o maior ao entrar.
var combo := [0, 0, 0, 0]
var combo_max := [0, 0, 0, 0]
## Os pontos de cada lugar; -1: não mostra.
var pontos := [-1, -1, -1, -1]
## O lado da fita (a partida, G12), para a etiqueta do salão.
var lado := "A"
## A etiqueta da faixa: {titulo, impresso, tinta, inclinacao, lado_b}; vazia, nenhuma.
var etiqueta := {}

var _avisos: Array = []  # [texto, restante]
var _rets: Array[Rect2] = []   ## o que o salão desenhou neste quadro (a prova confere que cabe na tela)
var _giro := 0.0  ## o giro dos carretéis do deck (para no apito)

const LARG_CHIP := 340.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Forja.aviso.connect(mostrar_aviso)


func mostrar_aviso(texto: String) -> void:
	if texto == "":
		return
	_avisos.append([texto, maxf(2.0, 0.06 * texto.length())])  # 06: o texto que some
	if _avisos.size() > 3:
		_avisos.pop_front()


func _process(dt: float) -> void:
	for a in _avisos:
		a[1] -= dt
	_avisos = _avisos.filter(func(a): return a[1] > 0.0)
	for l in 4:
		combo_max[l] = maxi(int(combo_max[l]), int(combo[l]))
	if _com_cartoes() and str(da_sala.fase) == "jogo" and not da_sala.treinando:
		_giro = TAU * Ritmo.batida() / 2.0
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	# a tarja de cima, leve
	for i in 20:
		draw_rect(Rect2(0, i * 7, w, 7), Color(Tema.FITA, 0.55 * (1.0 - i / 20.0)))
	var cx := _caixas()
	if sala.is_empty():
		_etiqueta(ETIQUETA_DO_SALAO, "O Salão", "A FORJA · LADO %s" % lado, Tema.SECAO[0], INCLINACAO_DO_SALAO, false, 56)
		var pares := [["create", "Diagnóstico"], ["options", "Pausa"]] if create_livre and Forja.bancada else [["options", "Pausa"]]
		Desenho.dicas_a_direita(self, Vector2(w - Tema.MARGEM_X, TOPO_DAS_DICAS + _lado_da_dica() * 0.82), pares, Tema.T_SELO)
	elif cx.has("cartao0"):
		for l in 4:
			_cartao(l, cx["cartao%d" % l])
		if not etiqueta.is_empty():
			_etiqueta(ETIQUETA_DA_SALA, str(etiqueta.get("titulo", "")), str(etiqueta.get("impresso", "")),
				etiqueta.get("tinta", Tema.SECAO[0]), float(etiqueta.get("inclinacao", 0.0)), bool(etiqueta.get("lado_b", false)), 52)
		_deck(cx["deck"])

	_rets.clear()
	if vencidas >= 0:
		_salao(w, h)

	# os avisos: centrados a partir de y 352, até 1100 px, duas linhas
	for i in _avisos.size():
		var a: Array = _avisos[i]
		var r2: Rect2 = cx["aviso%d" % i]
		var alfa := clampf(a[1] / 0.4, 0.0, 1.0)
		var f := Tema.archivo(500)
		var s := Desenho.caber(a[0], f, Tema.T_AVISO, LARG_AVISO, 2)
		Desenho.moldura(self, r2, Color(Tema.CASCO_ALTO, 0.95 * alfa), Color(Tema.GRAFITE, alfa), 2, 12)
		Desenho.paragrafo(self, Vector2(r2.position.x + 32, r2.position.y + 14 + f.get_ascent(Tema.t(Tema.T_AVISO))), s, f,
			Tema.T_AVISO, Color(Tema.ETIQUETA, alfa), LARG_AVISO + 1.0, 2)


## O que o salão põe na tela: o contador, «Salas vencidas», os chips e a dica presa.
func _salao(w: float, h: float) -> void:
	# o contador fica no alto à direita (G04: os chips de lugar saíram do alto; as dicas vêm abaixo dele)
	var topo := float(Tema.MARGEM_Y)
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


## As caixas que o HUD ocupa agora (cartões, etiqueta, deck, avisos, dicas de baixo e, no salão, o contador, o
## rótulo, os chips e a dica presa do último quadro): o _draw desenha nelas e a prova confere que nenhuma encosta.
func retangulos() -> Array:
	var r: Array = _caixas().values()
	if sala.is_empty():
		r.append_array(_rets)
	return r


## O quadro do nome e da ação da sala: do recuo da margem até antes do primeiro
## chip de lugar, nunca por cima dele. A ação cabe em até três linhas (com o texto
## grande, a da Centelha não cabe em duas). Devolve {rect, nome, acao}; o painel
## da sala desce as faixas dele para baixo do `rect`.
const LINHAS_DA_ACAO := 3


static func quadro_da_sala(nome: String, acao: String, w: float) -> Dictionary:
	var x := float(Tema.MARGEM_X - 28)
	var x_chips := w - Tema.MARGEM_X - (LARG_CHIP * 4 + 16.0 * 3)
	var larg := x_chips - 24.0 - x
	var fn := Tema.archivo(700)
	var fa := Tema.archivo(500)
	var dito_nome := Desenho.caber(nome, fn, Tema.T_SUBTITULO, larg - 56.0, 1)
	var dita_acao := Desenho.caber(acao, fa, Tema.T_ROTULO, larg - 56.0, LINHAS_DA_ACAO)
	var uma := fa.get_height(Tema.t(Tema.T_ROTULO))
	var extra := maxf(0.0, Desenho.altura_paragrafo(dita_acao, fa, Tema.T_ROTULO, larg - 56.0, LINHAS_DA_ACAO) - uma)
	return {"rect": Rect2(Vector2(x, 40), Vector2(larg, 118.0 + ceilf(extra))), "nome": dito_nome, "acao": dita_acao}


## A linha de status de um chip, cortada no chip: nunca passa para o chip do lado
## (dois chips com «Brasa · vida 1 · 1 balas» e «Brasa · derrubado» se tocavam).
static func linha_do_status(linha: String) -> String:
	return Desenho.caber(linha, Tema.archivo(500), Tema.T_SELO, LARG_CHIP - 40.0, 1)


# ------------------------------------------------------------- o cartão, a etiqueta e o deck (G04) --

const CARTAO := Vector2(420, 132)
const ETIQUETA_DA_SALA := Rect2(548, 60, 430, 136)
const DECK := Rect2(996, 60, 376, 116)
const ETIQUETA_DO_SALAO := Rect2(96, 60, 520, 150)
const INCLINACAO_DO_SALAO := -0.6
const TOPO_DAS_DICAS := 150.0
const LARG_AVISO := 1100.0
const TOPO_DOS_AVISOS := 352.0


## O retângulo do cartão do lugar: o canto dele, 96 px das laterais e 60 do alto ou de baixo.
## A largura não cresce com o texto grande (senão o P1 encosta na etiqueta); a altura, sim.
static func cartao(l: int, tela: Vector2) -> Rect2:
	var tam := Vector2(CARTAO.x, CARTAO.y * Tema.escala_texto)
	var x: float = float(Tema.MARGEM_X) if l % 2 == 0 else tela.x - Tema.MARGEM_X - tam.x
	var y: float = float(Tema.MARGEM_Y) if l < 2 else tela.y - Tema.MARGEM_Y - tam.y
	return Rect2(Vector2(x, y), tam)


## A inclinação da etiqueta da faixa (graus): sorteada pela semente da partida e pela seção; nunca se anima.
static func inclinacao_da_faixa(semente: int, n: int) -> float:
	return lerpf(-1.5, 1.5, float(absi(hash([semente, n])) % 1000) / 999.0)


## Troca a etiqueta da faixa (06). A animação (a velha descola, a nova cola, a caneta escreve) é da G04b; aqui a
## nova entra no lugar.
func trocar_etiqueta(titulo: String, impresso: String, tinta: Color, inclinacao: float, lado_b: bool) -> void:
	etiqueta = {"titulo": titulo, "impresso": impresso, "tinta": tinta, "inclinacao": inclinacao, "lado_b": lado_b}


## A sala mostra cartões, etiqueta e deck: uma SalaJogo com HUD, na fase de jogo.
func _com_cartoes() -> bool:
	return not sala.is_empty() and da_sala != null and is_instance_valid(da_sala) and da_sala is SalaJogo \
		and bool(da_sala.com_hud) and str(da_sala.fase) == "jogo"


func _lado_da_dica() -> float:
	return Tema.t(Tema.T_SELO) * 1.25


## Um cálculo só para o desenho e para a prova: o nome da caixa -> o retângulo.
func _caixas() -> Dictionary:
	var d := {}
	var w := size.x
	if sala.is_empty():
		d["etiqueta"] = _caixa_girada(ETIQUETA_DO_SALAO, INCLINACAO_DO_SALAO)
		var pares := [["create", "Diagnóstico"], ["options", "Pausa"]] if create_livre and Forja.bancada else [["options", "Pausa"]]
		var total := 40.0 * (pares.size() - 1)
		for i in pares.size():
			total += Glifo.largura_dica(pares[i][0], pares[i][1], Tema.T_SELO, i == 0)
		d["dicas"] = Rect2(Vector2(w - Tema.MARGEM_X - total, TOPO_DAS_DICAS), Vector2(total, _lado_da_dica()))
	elif _com_cartoes():
		for l in 4:
			d["cartao%d" % l] = cartao(l, size)
		if not etiqueta.is_empty():
			d["etiqueta"] = _caixa_girada(ETIQUETA_DA_SALA, float(etiqueta.get("inclinacao", 0.0)))
		d["deck"] = DECK
	var y := TOPO_DOS_AVISOS
	var f := Tema.archivo(500)
	for i in _avisos.size():
		var s := Desenho.caber(_avisos[i][0], f, Tema.T_AVISO, LARG_AVISO, 2)
		var tw := minf(Desenho.largura(s, f, Tema.T_AVISO), LARG_AVISO)
		var th := Desenho.altura_paragrafo(s, f, Tema.T_AVISO, LARG_AVISO)
		var r := Rect2(Vector2((w - tw) * 0.5 - 32, y), Vector2(tw + 64, th + 28))
		d["aviso%d" % i] = r
		y += r.size.y + 12.0
	return d


## A caixa de um papel girado `graus` em volta do centro (o retângulo que o contém).
static func _caixa_girada(r: Rect2, graus: float) -> Rect2:
	var a := deg_to_rad(absf(graus))
	var meio := Vector2(r.size.x * cos(a) + r.size.y * sin(a), r.size.x * sin(a) + r.size.y * cos(a)) * 0.5
	return Rect2(r.get_center() - meio, meio * 2.0)


## O cartão do lugar, nos três estados: jogando, sem controle, lugar vazio.
func _cartao(l: int, r: Rect2) -> void:
	var e := Tema.escala_texto
	var info: Dictionary = Forja.lugar(l)
	var ocupado: bool = info.get("ocupado", false)
	var conectado: bool = info.get("conectado", false)
	var cor: Color = Tema.JOGADOR[l]
	var o := r.position
	if ocupado:
		Desenho.caixa(self, Rect2(o + Vector2(0, 6), r.size), Tema.SOMBRA, 10)
		Desenho.caixa(self, r, Color(Tema.CASCO, 0.94), 10)
	else:
		Desenho.caixa(self, r, Color(Tema.CASCO, 0.5), 10)
	draw_rect(Rect2(o + Vector2(10, 0), Vector2(400, 5)), cor if ocupado and conectado else Tema.GRAFITE)
	Desenho.texto(self, o + Vector2(18, 52 * e), "P%d" % (l + 1), Tema.bungee(), Tema.T_PSHARP, cor if ocupado else Tema.MUDO)
	if not ocupado:
		Desenho.dica(self, o + Vector2(132, 62 * e), "cruz", "Entrar")
		return
	Desenho.lampadas(self, o + Vector2(20, 66 * e), l, not conectado)
	var fv := Tema.vt()
	var pts := "%04d" % int(pontos[l]) if int(pontos[l]) >= 0 else ""
	var lp := Desenho.largura(pts, fv, Tema.T_PONTOS) if pts != "" else 0.0
	if pts != "":
		Desenho.texto(self, o + Vector2(402.0 - lp, 54 * e), pts, fv, Tema.T_PONTOS, Tema.ETIQUETA)
	var larg_nome := 402.0 - lp - 16.0 - 112.0
	var fn := Tema.archivo(600)
	if conectado:
		Desenho.nome(self, o + Vector2(112, 48 * e), Desenho.nome_que_cabe(str(nomes[l]), fn, Tema.T_NOME, larg_nome), fn,
			Tema.T_NOME, Tema.ETIQUETA)
	else:
		Desenho.texto(self, o + Vector2(112, 48 * e), Desenho.caber("Sem controle", fn, Tema.T_NOME, larg_nome, 1), fn,
			Tema.T_NOME, Tema.ETIQUETA)
	# o item: em liga, a cor do dono; o Escudo quebrado, mudo e riscado; mãos livres, nada
	var item := Itens.do_lugar(l)
	var icone := str(ForjaPlayer.ITENS[item].icone)
	if icone != "":
		var ri := Rect2(o + Vector2(132, 58 * e), Vector2(36, 36))
		var quebrado := item == Itens.ESCUDO and not Itens.escudo_inteiro(l)
		Glifo.desenhar(self, icone, ri, Tema.MUDO if quebrado else (cor if Itens.em_liga[l] else Tema.ETIQUETA))
		if quebrado:
			draw_line(Vector2(ri.position.x, ri.end.y), Vector2(ri.end.x, ri.position.y), Tema.MUDO, 3.0, true)
	# o VU: o combo aceso na cor do dono, o pico da sala em papel
	var c := int(combo[l])
	var cm := int(combo_max[l])
	Desenho.vu(self, Rect2(o + Vector2(18, 98 * e), Vector2(302, 18)), 14, mini(c, 14), cor, mini(cm, 14) - 1 if cm > c else -1)
	if c >= 2:
		var s := "×%d" % c
		Desenho.texto(self, o + Vector2(402.0 - Desenho.largura(s, fv, 40), 124 * e), s, fv, 40, Tema.ETIQUETA)


## Uma etiqueta de papel com o título a caneta e a linha impressa, no giro do papel.
func _etiqueta(r: Rect2, titulo: String, impresso: String, tinta: Color, graus: float, lado_b: bool, tam_titulo: int) -> void:
	var papel := r
	Desenho.etiqueta(self, papel, tinta, graus, lado_b)
	var fm := Tema.marcador()
	var dito := Desenho.caber(titulo, fm, tam_titulo, papel.size.x - 48.0, 1)
	var base_impresso := papel.size.y - 12.0
	_texto_girado(papel.get_center(), graus, Vector2(24, 80) - papel.size * 0.5, dito, fm, tam_titulo, Tema.TINTA)
	_texto_girado(papel.get_center(), graus, Vector2(24, base_impresso) - papel.size * 0.5, impresso, Tema.vt(), 34, Tema.TINTA_SUAVE)


## Um texto no giro de um papel: desenhado girado, anotado (F09) sem o giro, no mesmo lugar.
func _texto_girado(centro: Vector2, graus: float, pos: Vector2, s: String, f: Font, tam: int, cor: Color) -> void:
	var dito := Desenho.t(s)
	draw_set_transform(centro, deg_to_rad(graus), Vector2.ONE)
	draw_string(f, pos, dito, HORIZONTAL_ALIGNMENT_LEFT, -1, Tema.t(tam), cor)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if Desenho.coletar_retangulos:
		Desenho.anotar(self, centro + pos, dito, f, Tema.t(tam), cor)


## O deck é o relógio da faixa: os segundos que faltam, ou o tempo jogado numa sala sem relógio; no treino, parado.
func _deck(r: Rect2) -> void:
	var d := float(da_sala.duracao)
	var digitos := ""
	var esq := 0.5
	if bool(da_sala.treinando):
		digitos = "%03d" % ceili(maxf(d, 0.0))
		esq = 1.0 if d > 0.0 else 0.5
	elif d > 0.0:
		var resta := maxf(0.0, d - float(da_sala.t_jogo))
		digitos = "%03d" % ceili(resta)
		esq = resta / d
	else:
		digitos = "%03d" % int(da_sala.t_jogo)
	Desenho.deck(self, r, esq, 1.0 - esq if d > 0.0 else 0.5, digitos, _giro)
