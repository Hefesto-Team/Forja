class_name Desenho
extends RefCounted

const LOGO := preload("res://assets/forja-logo.png")

const GLIFO_DA_FEATURE := {
	"botoes": "cross", "analogicos": "stick_l", "gatilhos_analogicos": "l2",
	"giroscopio": "giroscopio", "acelerometro": "acelerometro",
	"touchpad_dois_dedos": "touchpad", "touchpad_clique": "touchpad",
	"vibracao_forte": "rumble_esquerdo", "vibracao_fraca": "rumble_direito", "vibracao_isolamento": "rumble_esquerdo",
	"lightbar": "lightbar", "gatilho_resistencia": "r2", "gatilho_arma": "r2", "gatilho_vibracao": "r2",
	"leds_jogador": "led-jogador", "microfone": "mic", "microfone_mudo": "mic", "led_microfone": "mic",
	"haptica_audio": "rumble_direito", "alto_falante": "alto-falante",
}

static var _glifos := {}


static func glifo(nome: String) -> Texture2D:
	if nome == "":
		return null
	if _glifos.has(nome):
		return _glifos[nome]
	var t: Texture2D = load("res://assets/glifos/%s.png" % nome)
	var tex: Texture2D = null
	if t:
		var img := t.get_image()
		if img:
			img.decompress()
			img.generate_mipmaps()
			tex = ImageTexture.create_from_image(img)
	_glifos[nome] = tex
	return tex


static func moldura(ci: CanvasItem, r: Rect2, fundo: Color, borda: Color, largura := 2, raio := Tema.RAIO_QUADRO) -> void:
	var cor_da_borda := borda if largura >= Tema.BORDA_PLACA and borda.a > 0.0 else Color(Tema.CASCO_ALTO, fundo.a)
	caixa(ci, Rect2(r.position + Tema.SOMBRA_PLACA, r.size), Color(Tema.SOMBRA, Tema.SOMBRA.a * fundo.a), Tema.RAIO_PLACA)
	caixa(ci, r, fundo, Tema.RAIO_PLACA, cor_da_borda, Tema.BORDA_PLACA)


static func tracejado(ci: CanvasItem, r: Rect2, cor: Color, largura := 2.0, traco := 12.0) -> void:
	var cantos := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		ci.draw_dashed_line(cantos[i], cantos[(i + 1) % 4], cor, largura, traco, true)


static var _coletar := ""
static var _coletados := {}


static func maiusc(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)


static func t(s: String) -> String:
	if _coletar == "":
		_coletar = OS.get_environment("FORJA_COLETAR_TEXTOS")
		if _coletar == "":
			_coletar = "-"
	if _coletar != "-" and not _coletados.has(s):
		_coletados[s] = true
		if _coletar == "memoria":
			return Traducoes.traduzir(s)
		var f := FileAccess.open(_coletar, FileAccess.READ_WRITE if FileAccess.file_exists(_coletar) else FileAccess.WRITE)
		if f:
			f.seek_end()
			f.store_line(s.c_escape())
			f.close()
	return Traducoes.traduzir(s)


static var coletar_retangulos := false
static var retangulos: Array = []
static var _desenhos := {}


static func anotar(ci: CanvasItem, pos: Vector2, traduzido: String, f: Font, px: int, cor: Color,
		alinhamento := HORIZONTAL_ALIGNMENT_LEFT, largura := -1.0, max_linhas := 0) -> void:
	var tam: Vector2
	var folga_linha := maxf(0.0, f.get_height(px) - float(px))
	if max_linhas == 0:
		tam = Vector2(f.get_string_size(traduzido, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x, float(px))
	else:
		tam = f.get_multiline_string_size(traduzido, HORIZONTAL_ALIGNMENT_LEFT, largura, px, max_linhas)
		tam.y = maxf(float(px), tam.y - folga_linha)
	var x := pos.x
	if largura > 0.0 and max_linhas == 0:
		if alinhamento == HORIZONTAL_ALIGNMENT_CENTER:
			x += (largura - tam.x) * 0.5
		elif alinhamento == HORIZONTAL_ALIGNMENT_RIGHT:
			x += largura - tam.x
	var local := Rect2(Vector2(x, pos.y - 0.78 * px), tam)
	var m := ci.get_global_transform_with_canvas()
	var no := ci.get_instance_id()
	if not _desenhos.has(no):
		_desenhos[no] = 0
		ci.draw.connect(func(): _desenhos[no] = int(_desenhos.get(no, 0)) + 1)
	retangulos.append({"frase": traduzido, "rect": m * local, "tam": px, "cor": cor, "no": no, "quadro": int(_desenhos[no])})


static func texto(ci: CanvasItem, pos: Vector2, s: String, f: Font, tam: int, cor: Color,
		alinhamento := HORIZONTAL_ALIGNMENT_LEFT, largura := -1.0) -> void:
	var dito := t(s)
	ci.draw_string(f, pos, dito, alinhamento, largura, Tema.t(tam), cor)
	if coletar_retangulos:
		anotar(ci, pos, dito, f, Tema.t(tam), cor, alinhamento, largura)


static func paragrafo(ci: CanvasItem, pos: Vector2, s: String, f: Font, tam: int, cor: Color, largura: float,
		max_linhas := -1) -> float:
	var dito := t(s)
	ci.draw_multiline_string(f, pos, dito, HORIZONTAL_ALIGNMENT_LEFT, largura, Tema.t(tam), max_linhas, cor)
	if coletar_retangulos:
		anotar(ci, pos, dito, f, Tema.t(tam), cor, HORIZONTAL_ALIGNMENT_LEFT, largura, max_linhas if max_linhas != 0 else -1)
	return altura_paragrafo(s, f, tam, largura, max_linhas)


static var _cabe := {}


static func caber(s: String, f: Font, tam: int, largura: float, linhas: int) -> String:
	s = t(s)
	var chave := "%s|%d|%d|%d" % [s, Tema.t(tam), int(largura), linhas]
	if _cabe.has(chave):
		return _cabe[chave]
	var limite := f.get_height(Tema.t(tam)) * linhas + 1.0
	var r := s
	if altura_paragrafo(s, f, tam, largura) > limite:
		var palavras := s.split(" ")
		while palavras.size() > 1:
			palavras.resize(palavras.size() - 1)
			r = " ".join(palavras).trim_suffix(",").trim_suffix(";") + "…"
			if altura_paragrafo(r, f, tam, largura) <= limite:
				break
	_cabe[chave] = r
	return r


static func altura_paragrafo(s: String, f: Font, tam: int, largura: float, max_linhas := -1) -> float:
	return f.get_multiline_string_size(Traducoes.traduzir(s), HORIZONTAL_ALIGNMENT_LEFT, largura, Tema.t(tam), max_linhas).y


static func largura(s: String, f: Font, tam: int) -> float:
	return f.get_string_size(Traducoes.traduzir(s), HORIZONTAL_ALIGNMENT_LEFT, -1, Tema.t(tam)).x


static func selo(ci: CanvasItem, pos: Vector2, s: String, cor: Color, tam := Tema.T_SELO) -> float:
	var f := Tema.vt()
	var w := largura(s, f, tam) + tam * 0.9
	var h := tam * 1.45
	var r := Rect2(pos, Vector2(w, h))
	caixa(ci, r, cor, Tema.RAIO_SELO)
	var dito := t(s)
	ci.draw_string(f, Vector2(pos.x + tam * 0.45, pos.y + h * 0.5 + tam * 0.36), dito, HORIZONTAL_ALIGNMENT_LEFT, -1, Tema.t(tam), Tema.TINTA)
	if coletar_retangulos:
		anotar(ci, Vector2(pos.x + tam * 0.45, pos.y + h * 0.5 + tam * 0.36), dito, f, Tema.t(tam), Tema.TINTA)
	return w


static func leds(ci: CanvasItem, pos: Vector2, mascara: int, lado := 12.0) -> float:
	var x := pos.x
	var vao := lado * 0.5
	for i in 5:
		var aceso := (mascara >> i) & 1
		var r := Rect2(Vector2(x, pos.y), Vector2(lado, lado))
		if aceso:
			ci.draw_rect(r.grow(lado * 0.35), Color(Tema.ETIQUETA, 0.18))
			ci.draw_rect(r, Tema.ETIQUETA)
		else:
			ci.draw_rect(r, Tema.GRAFITE)
		x += lado + (vao * 2.0 if i == 0 or i == 3 else vao)
	return x - pos.x


static func bateria(ci: CanvasItem, pos: Vector2, pct: int, carregando: bool, largura_trilho := 90.0) -> float:
	var h := 8.0
	ci.draw_rect(Rect2(pos + Vector2(0, -h - 6), Vector2(largura_trilho, h)), Tema.GRAFITE)
	if pct >= 0:
		ci.draw_rect(Rect2(pos + Vector2(0, -h - 6), Vector2(largura_trilho * clampf(pct / 100.0, 0, 1), h)), Tema.ETIQUETA)
	var f := Tema.vt()
	var s := ("%d%%" % pct) if pct >= 0 else "—"
	if carregando:
		s += " ⚡"
	ci.draw_string(f, pos + Vector2(largura_trilho + 12, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, Tema.T_MONO, Tema.ETIQUETA)
	return largura_trilho + 12 + largura(s, f, Tema.T_MONO)


static func cabecalho(ci: CanvasItem, pos: Vector2, lado := 88.0) -> void:
	ci.draw_texture_rect(LOGO, Rect2(pos, Vector2(lado, lado)), false)
	var tam := maxi(int(lado * 0.36), Tema.LETRA_MINIMA)
	texto(ci, pos + Vector2(lado + 18, lado * 0.46), "Hefesto", Tema.bungee(), tam, Tema.ETIQUETA)
	texto(ci, pos + Vector2(lado + 18, lado * 0.46 + tam * 1.12), "Tech Demo", Tema.archivo(700), tam, Tema.ETIQUETA)


const LADO_DA_DICA := 52.0
const VAO_DAS_DICAS := 40.0


static func largura_das_dicas(pares: Array) -> float:
	var total := VAO_DAS_DICAS * maxi(pares.size() - 1, 0)
	for par in pares:
		total += largura_da_dica(str(par[1]))
	return total


static func largura_da_dica(frase: String) -> float:
	return LADO_DA_DICA + 12.0 + largura(frase, Tema.archivo(600), 34)


static func dicas_a_direita(ci: CanvasItem, fim: Vector2, pares: Array, _tam := Tema.T_ROTULO, placa := false) -> void:
	if placa and not pares.is_empty():
		var total := largura_das_dicas(pares)
		moldura(ci, Rect2(Vector2(fim.x - total - 24.0, fim.y - LADO_DA_DICA * 0.82 - 14.0), Vector2(total + 48.0, LADO_DA_DICA + 28.0)),
			Color(Tema.CASCO, 0.92), Tema.GRAFITE)
	var x := fim.x
	for i in range(pares.size() - 1, -1, -1):
		var par: Array = pares[i]
		x -= largura_da_dica(str(par[1]))
		dica(ci, Vector2(x, fim.y - LADO_DA_DICA * 0.82), str(par[0]), str(par[1]))
		x -= VAO_DAS_DICAS


static func dicas_a_esquerda(ci: CanvasItem, inicio: Vector2, pares: Array, _tam := Tema.T_ROTULO) -> void:
	var x := inicio.x
	for i in pares.size():
		var par: Array = pares[i]
		x += dica(ci, Vector2(x, inicio.y - LADO_DA_DICA * 0.82), str(par[0]), str(par[1]))
		x += VAO_DAS_DICAS


static func caixa(ci: CanvasItem, r: Rect2, fundo: Color, raio := 10, borda := Color(Tema.FITA, 0.0), largura := 0) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.draw_center = fundo.a > 0.0
	s.set_corner_radius_all(raio)
	if largura > 0:
		s.border_color = borda
		s.set_border_width_all(largura)
	s.anti_aliasing = true
	ci.draw_style_box(s, r)


static func carretel(ci: CanvasItem, c: Vector2, raio: float, fita: float, cor_cubo := Tema.ETIQUETA, giro := 0.0) -> void:
	var r_fita := lerpf(raio * 0.42, raio, fita)
	ci.draw_circle(c, r_fita, Tema.OXIDO)
	ci.draw_arc(c, r_fita - 1.5, PI * 1.05, PI * 1.45, 18, Tema.OXIDO_BRILHO, 2.0, true)
	ci.draw_circle(c, raio * 0.42, cor_cubo)
	ci.draw_circle(c, raio * 0.2, Tema.CASCO)
	for i in 6:
		var a := i * TAU / 6.0 + 0.3 + giro
		var d := Vector2(cos(a), sin(a))
		ci.draw_line(c + d * raio * 0.2, c + d * raio * 0.33, Tema.CASCO, 3.0, true)


static func contador(ci: CanvasItem, pos: Vector2, digitos: String, tam := 60) -> Rect2:
	var f := Tema.vt()
	var w_d := f.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x + 10.0
	var r := Rect2(pos, Vector2(w_d * digitos.length() + 14, tam * 0.95 + 12))
	caixa(ci, r, Tema.JANELA, 6, Tema.GRAFITE, 2)
	for i in digitos.length():
		var cel := Rect2(pos + Vector2(7 + i * w_d, 6), Vector2(w_d - 4, tam * 0.95))
		caixa(ci, cel, Tema.CASCO, 3)
		var base := Vector2(cel.position.x, cel.position.y - tam * 0.1 + f.get_ascent(tam))
		texto(ci, base, digitos[i], f, tam, Tema.ETIQUETA, HORIZONTAL_ALIGNMENT_CENTER, cel.size.x)
		ci.draw_line(Vector2(cel.position.x, cel.get_center().y), Vector2(cel.end.x, cel.get_center().y), Color(Tema.JANELA, 0.55), 2.0)
	return r


static func nome(ci: CanvasItem, pos: Vector2, s: String, f: Font, tam: int, cor: Color,
		alinhamento := HORIZONTAL_ALIGNMENT_LEFT, largura_da_caixa := -1.0) -> void:
	ci.draw_string(f, pos, s, alinhamento, largura_da_caixa, Tema.t(tam), cor)
	if coletar_retangulos:
		anotar(ci, pos, s, f, Tema.t(tam), cor, alinhamento, largura_da_caixa)


static func nome_que_cabe(s: String, f: Font, tam: int, largura_da_caixa: float) -> String:
	var r := s
	while r.length() > 1 and f.get_string_size(r, HORIZONTAL_ALIGNMENT_LEFT, -1, Tema.t(tam)).x > largura_da_caixa:
		s = s.left(s.length() - 1)
		r = s + "…"
	return r


static func largura_do_nome(s: String, f: Font, tam: int) -> float:
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, Tema.t(tam)).x


static func chip(ci: CanvasItem, r: Rect2, lugar: int, pronto: bool, palavra := "") -> void:
	var cor: Color = Tema.JOGADOR[clampi(lugar, 0, 3)]
	caixa(ci, r, Tema.CASCO, 10, cor if pronto else Tema.GRAFITE, 3)
	ci.draw_rect(Rect2(r.position + Vector2(6, 10), Vector2(8, r.size.y - 20)), cor if pronto else Tema.GRAFITE)
	var f6 := Tema.archivo(700)
	var f5 := Tema.archivo(600)
	var base := r.position.y + r.size.y * 0.5 + 11.0
	texto(ci, Vector2(r.position.x + 28, base), "P%d" % (lugar + 1), f6, 32, Tema.tom_para_a_borda(cor) if pronto else Tema.MUDO)
	var x := r.position.x + 28 + largura("P4", f6, 32) + 18.0
	var cabe := r.end.x - 18.0 - x
	if palavra != "":
		if pronto:
			var nm := nome_que_cabe(palavra, f5, 32, cabe)
			nome(ci, Vector2(x, base), nm, f5, 32, Tema.ETIQUETA)
		else:
			texto(ci, Vector2(x, base), caber(palavra, f5, 32, cabe, 1), f5, 32, Tema.SECAO[3])


static func placa(ci: CanvasItem, r: Rect2, foco := Color.TRANSPARENT) -> void:
	caixa(ci, Rect2(r.position + Tema.SOMBRA_PLACA, r.size), Tema.SOMBRA, Tema.RAIO_PLACA)
	var com_foco := foco.a > 0.0
	caixa(ci, r, Tema.CASCO_ALTO if com_foco else Tema.CASCO, Tema.RAIO_PLACA, foco if com_foco else Tema.CASCO_ALTO,
		Tema.BORDA_PLACA)


static func etiqueta(ci: CanvasItem, r: Rect2, tinta: Color, inclinacao := 0.0, lado_b := false) -> void:
	ci.draw_set_transform(r.get_center(), deg_to_rad(inclinacao), Vector2.ONE)
	var rr := Rect2(-r.size * 0.5, r.size)
	caixa(ci, Rect2(rr.position + Tema.SOMBRA_ETIQUETA, rr.size), Tema.SOMBRA, Tema.RAIO_ETIQUETA)
	caixa(ci, rr, Tema.ETIQUETA, Tema.RAIO_ETIQUETA)
	if lado_b:
		ci.draw_rect(Rect2(rr.position + Vector2(0, 14), Vector2(rr.size.x, 7)), tinta)
		ci.draw_rect(Rect2(rr.position + Vector2(0, 25), Vector2(rr.size.x, 7)), tinta)
	else:
		ci.draw_rect(Rect2(rr.position + Vector2(0, 14), Vector2(rr.size.x, 12)), tinta)
	for i in 2:
		var y := rr.end.y - 22.0 - i * 46.0
		ci.draw_line(Vector2(rr.position.x + 22, y), Vector2(rr.end.x - 22, y), Tema.ETIQUETA_SOMBRA, 2.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func lampadas(ci: CanvasItem, pos: Vector2, lugar: int, apagadas := false) -> void:
	var l := clampi(lugar, 0, 3)
	for i in 5:
		var aceso := not apagadas and (int(Forja.LEDS_DO_LUGAR[l]) >> i) & 1 == 1
		ci.draw_rect(Rect2(pos + Vector2(i * 20.0, 0), Vector2(15, 8)), Tema.JOGADOR[l] if aceso else Tema.GRAFITE)


static func dica(ci: CanvasItem, pos: Vector2, glifo_nome: String, frase: String, sobre_etiqueta := false) -> float:
	var cor := Tema.TINTA if sobre_etiqueta else Tema.ETIQUETA
	Glifo.desenhar(ci, glifo_nome, Rect2(pos, Vector2(LADO_DA_DICA, LADO_DA_DICA)), cor)
	var f := Tema.archivo(600)
	var dito := t(frase)
	texto(ci, Vector2(pos.x + LADO_DA_DICA + 12.0, pos.y + LADO_DA_DICA * 0.5 + f.get_ascent(Tema.t(34)) * 0.36 + 2.0), frase, f, 34, cor)
	return LADO_DA_DICA + 12.0 + f.get_string_size(dito, HORIZONTAL_ALIGNMENT_LEFT, -1, Tema.t(34)).x


static func vu(ci: CanvasItem, r: Rect2, n: int, aceso: int, cor: Color, pico := -1) -> void:
	var gap := 4.0
	var w := (r.size.x - gap * (n - 1)) / n
	for i in n:
		var cel := Rect2(r.position + Vector2(i * (w + gap), 0), Vector2(w, r.size.y))
		var c := Tema.GRAFITE
		if i < aceso:
			c = cor.darkened(0.25 * (1.0 - float(i) / n))
		if i == pico:
			c = Tema.ETIQUETA
		ci.draw_rect(cel, c)


static func deck(ci: CanvasItem, r: Rect2, esquerda: float, direita: float, digitos: String, giro := 0.0) -> void:
	caixa(ci, Rect2(r.position + Vector2(4, 6), r.size), Tema.SOMBRA, 14)
	caixa(ci, r, Tema.CASCO, 14, Tema.CASCO_ALTO, 3)
	var jan := Rect2(r.position + Vector2(16, 14), Vector2(196, r.size.y - 28))
	caixa(ci, jan, Tema.JANELA, 10)
	var c1 := jan.position + Vector2(48, jan.size.y * 0.5)
	var c2 := jan.position + Vector2(jan.size.x - 48, jan.size.y * 0.5)
	var raio := jan.size.y * 0.5 - 6
	ci.draw_line(c1 + Vector2(0, lerpf(raio * 0.42, raio, esquerda)), c2 + Vector2(0, lerpf(raio * 0.42, raio, direita)), Tema.OXIDO, 3.0, true)
	carretel(ci, c1, raio, esquerda, Tema.ETIQUETA, giro)
	carretel(ci, c2, raio, direita, Tema.ETIQUETA, giro)
	var tam := 64
	contador(ci, Vector2(jan.end.x + 16, r.position.y + (r.size.y - tam * 0.95 - 12) * 0.5), digitos, tam)


static func carimbo(ci: CanvasItem, centro: Vector2, palavra: String, cor: Color, tam: int, graus := 0.0, escala := 1.0,
		alfa := 1.0, sobre_3d := true) -> void:
	if palavra == "" or alfa <= 0.0:
		return
	var f := Tema.bungee()
	var px := Tema.t(tam)
	var dito := t(palavra)
	var sz := f.get_string_size(dito, HORIZONTAL_ALIGNMENT_LEFT, -1, px)
	var d := float(maxi(3, roundi(0.08 * tam)))
	var base := Vector2(-sz.x * 0.5, f.get_ascent(px) * 0.5 - f.get_descent(px) * 0.25)
	ci.draw_set_transform(centro, deg_to_rad(graus), Vector2(escala, escala))
	var chapa := Color(Tema.FITA, alfa)
	ci.draw_string(f, base + Vector2(d, d), dito, HORIZONTAL_ALIGNMENT_LEFT, -1, px, chapa)
	if sobre_3d:
		ci.draw_string_outline(f, base, dito, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 6, chapa)
	ci.draw_string(f, base, dito, HORIZONTAL_ALIGNMENT_LEFT, -1, px, Color(cor, alfa))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if coletar_retangulos:
		anotar(ci, centro + base, dito, f, px, Color(cor, alfa))


static func caixa_do_carimbo(centro: Vector2, palavra: String, tam: int) -> Rect2:
	var f := Tema.bungee()
	var px := Tema.t(tam)
	var sz := f.get_string_size(t(palavra), HORIZONTAL_ALIGNMENT_LEFT, -1, px)
	return Rect2(centro - Vector2(sz.x * 0.5, px * 0.5), Vector2(sz.x, px))


const JCARD_LOMBADA := 104.0
const JCARD_INCLINACAO := 0.5


static func inclinar(ci: CanvasItem, centro: Vector2, graus: float) -> void:
	ci.draw_set_transform_matrix(Transform2D(deg_to_rad(graus), centro) * Transform2D(0.0, -centro))


static func jcard(ci: CanvasItem, r: Rect2, tinta: Color, lombada: String) -> void:
	inclinar(ci, r.get_center(), JCARD_INCLINACAO)
	caixa(ci, Rect2(r.position + Tema.SOMBRA_ETIQUETA, r.size), Tema.SOMBRA, Tema.RAIO_ETIQUETA)
	caixa(ci, r, Tema.ETIQUETA, Tema.RAIO_ETIQUETA)
	var dobra := StyleBoxFlat.new()
	dobra.bg_color = Tema.ETIQUETA_SOMBRA
	dobra.corner_radius_top_left = Tema.RAIO_ETIQUETA
	dobra.corner_radius_bottom_left = Tema.RAIO_ETIQUETA
	dobra.anti_aliasing = true
	ci.draw_style_box(dobra, Rect2(r.position, Vector2(JCARD_LOMBADA, r.size.y)))
	var tarja := dobra.duplicate() as StyleBoxFlat
	tarja.bg_color = tinta
	tarja.corner_radius_bottom_left = 0
	ci.draw_style_box(tarja, Rect2(r.position, Vector2(JCARD_LOMBADA, 22)))
	ci.draw_rect(Rect2(r.position + Vector2(JCARD_LOMBADA, 22), Vector2(r.size.x - JCARD_LOMBADA, 16)), tinta)
	var f := Tema.vt()
	var px := Tema.t(46)
	var base := Vector2(r.position.x + JCARD_LOMBADA * 0.5 + px * 0.3, r.end.y - 40.0)
	ci.draw_set_transform_matrix(Transform2D(deg_to_rad(JCARD_INCLINACAO), r.get_center()) * Transform2D(0.0, -r.get_center())
		* Transform2D(-PI * 0.5, base))
	ci.draw_string(f, Vector2.ZERO, t(lombada), HORIZONTAL_ALIGNMENT_LEFT, -1, px, Tema.TINTA_SUAVE)
	inclinar(ci, Vector2.ZERO, 0.0)


const EMBURRADA := Vector2(160, 104)
const EMBURRADA_TRACO := 6.0


static func cara_emburrada(ci: CanvasItem, centro: Vector2, cor: Color, graus := 0.0, escala := 1.0, alfa := 1.0) -> void:
	if alfa <= 0.0:
		return
	var tinta := Color(cor, alfa)
	var fita := Color(Tema.FITA, alfa)
	var r := Rect2(-EMBURRADA * 0.5, EMBURRADA)
	ci.draw_set_transform(centro, deg_to_rad(graus), Vector2(escala, escala))
	caixa(ci, Rect2(r.position + Vector2(9, 9), r.size), fita, Tema.RAIO_PLACA)
	caixa(ci, r, fita, Tema.RAIO_PLACA, tinta, int(EMBURRADA_TRACO))
	for x in [-40.0, 40.0]:
		var olho := Vector2(x, -10.0)
		ci.draw_arc(olho, 18.0 - EMBURRADA_TRACO * 0.5, 0.0, TAU, 32, tinta, EMBURRADA_TRACO, true)
		ci.draw_rect(Rect2(olho - Vector2(18.0 + 1.0, 18.0 + 1.0), Vector2(38.0, 18.0 + 1.0)), fita)
		ci.draw_line(olho - Vector2(18.0, 0.0), olho + Vector2(18.0, 0.0), tinta, EMBURRADA_TRACO, true)
	ci.draw_arc(Vector2(0.0, 44.0), 32.0, deg_to_rad(200.0), deg_to_rad(340.0), 24, tinta, EMBURRADA_TRACO, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
