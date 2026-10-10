class_name HudJogo
extends Control

var vencidas := -1
var dica_presa := {}
var camera: Camera3D
var nomes := ["", "", "", ""]
var sala := {}
var status_da_sala := ["", "", "", ""]
var create_livre := true
var da_sala: Node = null
var combo := [0, 0, 0, 0]
var combo_max := [0, 0, 0, 0]
var pontos := [-1, -1, -1, -1]
var lado := "A"
var etiqueta := {}

var _avisos: Array = []
var _rets: Array[Rect2] = []
var _giro := 0.0

const LARG_CHIP := 340.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Forja.aviso.connect(mostrar_aviso)


func mostrar_aviso(texto: String) -> void:
	if texto == "":
		return
	_avisos.append([texto, maxf(2.0, 0.06 * texto.length())])
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

	for i in _avisos.size():
		var a: Array = _avisos[i]
		var r2: Rect2 = cx["aviso%d" % i]
		var alfa := clampf(a[1] / 0.4, 0.0, 1.0)
		var f := Tema.archivo(500)
		var s := Desenho.caber(a[0], f, Tema.T_AVISO, LARG_AVISO, 2)
		Desenho.moldura(self, r2, Color(Tema.CASCO_ALTO, 0.95 * alfa), Color(Tema.GRAFITE, alfa), 2, 12)
		Desenho.paragrafo(self, Vector2(r2.position.x + 32, r2.position.y + 14 + f.get_ascent(Tema.t(Tema.T_AVISO))), s, f,
			Tema.T_AVISO, Color(Tema.ETIQUETA, alfa), LARG_AVISO + 1.0, 2)


func _salao(w: float, h: float) -> void:
	var topo := float(Tema.MARGEM_Y)
	var c := Desenho.contador(self, Vector2(w - Tema.MARGEM_X - 121.0, topo), "%d/9" % vencidas, 64)
	_rets.append(c)
	var f := Tema.archivo(500)
	var rotulo := Desenho.t("Salas vencidas")
	var lw := Desenho.largura(rotulo, f, 32)
	Desenho.texto(self, Vector2(c.position.x - 20.0 - lw, c.position.y + 48.0), rotulo, f, 32, Tema.ETIQUETA)
	_rets.append(Rect2(Vector2(c.position.x - 20.0 - lw, c.position.y + 16.0), Vector2(lw, 40)))
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
	var py := r.position.y + 40.0
	if lado_direito:
		draw_colored_polygon(PackedVector2Array([Vector2(r.position.x, py), Vector2(r.position.x - 16, py + 16), Vector2(r.position.x, py + 32)]), Tema.ETIQUETA)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(r.end.x, py), Vector2(r.end.x + 16, py + 16), Vector2(r.end.x, py + 32)]), Tema.ETIQUETA)
	for i in linhas.size():
		Glifo.dica(self, r.position + Vector2(24, 34 + 62.0 * i + 44.0), str(linhas[i][0]), str(linhas[i][1]), Tema.T_CORPO, Tema.TINTA, Tema.TINTA)
	_rets.append(r)


func retangulos() -> Array:
	var r: Array = _caixas().values()
	if sala.is_empty():
		r.append_array(_rets)
	return r


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


static func linha_do_status(linha: String) -> String:
	return Desenho.caber(linha, Tema.archivo(500), Tema.T_SELO, LARG_CHIP - 40.0, 1)


const CARTAO := Vector2(420, 132)
const ETIQUETA_DA_SALA := Rect2(548, 60, 430, 136)
const DECK := Rect2(996, 60, 376, 116)
const ETIQUETA_DO_SALAO := Rect2(96, 60, 520, 150)
const INCLINACAO_DO_SALAO := -0.6
const TOPO_DAS_DICAS := 150.0
const LARG_AVISO := 1100.0
const TOPO_DOS_AVISOS := 352.0


static func cartao(l: int, tela: Vector2) -> Rect2:
	var tam := Vector2(CARTAO.x, CARTAO.y * Tema.escala_texto)
	var x: float = float(Tema.MARGEM_X) if l % 2 == 0 else tela.x - Tema.MARGEM_X - tam.x
	var y: float = float(Tema.MARGEM_Y) if l < 2 else tela.y - Tema.MARGEM_Y - tam.y
	return Rect2(Vector2(x, y), tam)


static func inclinacao_da_faixa(semente: int, n: int) -> float:
	return lerpf(-1.5, 1.5, float(absi(hash([semente, n])) % 1000) / 999.0)


func trocar_etiqueta(titulo: String, impresso: String, tinta: Color, inclinacao: float, lado_b: bool) -> void:
	etiqueta = {"titulo": titulo, "impresso": impresso, "tinta": tinta, "inclinacao": inclinacao, "lado_b": lado_b}


func _com_cartoes() -> bool:
	return not sala.is_empty() and da_sala != null and is_instance_valid(da_sala) and da_sala is SalaJogo \
		and bool(da_sala.com_hud) and str(da_sala.fase) == "jogo"


func _lado_da_dica() -> float:
	return Desenho.LADO_DA_DICA


func _caixas() -> Dictionary:
	var d := {}
	var w := size.x
	if sala.is_empty():
		d["etiqueta"] = _caixa_girada(ETIQUETA_DO_SALAO, INCLINACAO_DO_SALAO)
		var pares := [["create", "Diagnóstico"], ["options", "Pausa"]] if create_livre and Forja.bancada else [["options", "Pausa"]]
		var total := Desenho.largura_das_dicas(pares)
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


static func _caixa_girada(r: Rect2, graus: float) -> Rect2:
	var a := deg_to_rad(absf(graus))
	var meio := Vector2(r.size.x * cos(a) + r.size.y * sin(a), r.size.x * sin(a) + r.size.y * cos(a)) * 0.5
	return Rect2(r.get_center() - meio, meio * 2.0)


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
	var item := Itens.do_lugar(l)
	var icone := str(ForjaPlayer.ITENS[item].icone)
	if icone != "":
		var ri := Rect2(o + Vector2(132, 58 * e), Vector2(36, 36))
		var quebrado := item == Itens.ESCUDO and not Itens.escudo_inteiro(l)
		Glifo.desenhar(self, icone, ri, Tema.MUDO if quebrado else (cor if Itens.em_liga[l] else Tema.ETIQUETA))
		if quebrado:
			draw_line(Vector2(ri.position.x, ri.end.y), Vector2(ri.end.x, ri.position.y), Tema.MUDO, 3.0, true)
	var c := int(combo[l])
	var cm := int(combo_max[l])
	Desenho.vu(self, Rect2(o + Vector2(18, 98 * e), Vector2(302, 18)), 14, mini(c, 14), cor, mini(cm, 14) - 1 if cm > c else -1)
	if c >= 2:
		var s := "×%d" % c
		Desenho.texto(self, o + Vector2(402.0 - Desenho.largura(s, fv, 40), 124 * e), s, fv, 40, Tema.ETIQUETA)


func _etiqueta(r: Rect2, titulo: String, impresso: String, tinta: Color, graus: float, lado_b: bool, tam_titulo: int) -> void:
	var papel := r
	Desenho.etiqueta(self, papel, tinta, graus, lado_b)
	var fm := Tema.marcador()
	var dito := Desenho.caber(titulo, fm, tam_titulo, papel.size.x - 48.0, 1)
	var base_impresso := papel.size.y - 12.0
	_texto_girado(papel.get_center(), graus, Vector2(24, 80) - papel.size * 0.5, dito, fm, tam_titulo, Tema.TINTA)
	_texto_girado(papel.get_center(), graus, Vector2(24, base_impresso) - papel.size * 0.5, impresso, Tema.vt(), 34, Tema.TINTA_SUAVE)


func _texto_girado(centro: Vector2, graus: float, pos: Vector2, s: String, f: Font, tam: int, cor: Color) -> void:
	var dito := Desenho.t(s)
	draw_set_transform(centro, deg_to_rad(graus), Vector2.ONE)
	draw_string(f, pos, dito, HORIZONTAL_ALIGNMENT_LEFT, -1, Tema.t(tam), cor)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if Desenho.coletar_retangulos:
		Desenho.anotar(self, centro + pos, dito, f, Tema.t(tam), cor)


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
