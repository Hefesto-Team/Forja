class_name Desenho
extends RefCounted
## As peças de desenho da interface, no padrão do app Hefesto: moldura chapada
## com borda, selo cheio em mono, as cinco lâmpadas do LED de jogador, a barra
## de bateria, o texto com alinhamento. Tudo em cima da API 2D do Godot.

const LOGO := preload("res://assets/forja-logo.png")

## O glifo de cada feature do relatório (os de assets/glifos, do app Hefesto).
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


## Um glifo de feature (branco, para tingir), com mipmaps.
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
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.draw_center = fundo.a > 0.0
	s.border_color = borda
	s.set_border_width_all(largura)
	s.set_corner_radius_all(raio)
	s.anti_aliasing = true
	ci.draw_style_box(s, r)


## A borda tracejada: o "pendente" do app (laranja) ou o lugar sem controle.
static func tracejado(ci: CanvasItem, r: Rect2, cor: Color, largura := 2.0, traco := 12.0) -> void:
	var cantos := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		ci.draw_dashed_line(cantos[i], cantos[(i + 1) % 4], cor, largura, traco, true)


## A língua das telas: todo texto passa por aqui (e pelo Glifo) e sai
## traduzido pela tabela do idioma escolhido (scripts/traducoes.gd); o que
## não tem tradução sai como está. Com FORJA_COLETAR_TEXTOS=<arquivo>, anota
## cada texto desenhado (para montar a tabela). Com FORJA_COLETAR_TEXTOS=memoria
## (ou `_coletar = "memoria"`, como a prova faz), só guarda em `_coletados`.
static var _coletar := ""
static var _coletados := {}


## A frase com a primeira letra em maiúscula (o nome solto, em lista ou botão).
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
			return Traducoes.traduzir(s)  # só na memória: a prova lê `_coletados`
		var f := FileAccess.open(_coletar, FileAccess.READ_WRITE if FileAccess.file_exists(_coletar) else FileAccess.WRITE)
		if f:
			f.seek_end()
			f.store_line(s.c_escape())
			f.close()
	return Traducoes.traduzir(s)


## A coleta dos retângulos (F09): com `coletar_retangulos` ligado, cada texto
## desenhado guarda a frase, o retângulo que ocupa na tela (em pixels do jogo,
## 1920×1080), o tamanho da letra e a cor. A prova visual liga, força um
## redesenho, lê e esvazia; fora dela, ninguém liga e nada custa.
static var coletar_retangulos := false
static var retangulos: Array = []
## Qual desenho do nó guardou o texto, contado pelo sinal `draw` do próprio nó. O
## número do quadro não basta: sem `--fixed-fps`, o mesmo nó se desenha mais de uma
## vez num quadro (um a cada passo de física), e o cartão que desliza sairia
## «encavalado com ele mesmo».
static var _desenhos := {}


## Guarda um texto já traduzido que acaba de ser desenhado em `pos` (a linha de
## base, no espaço do `ci`). `largura` > 0 é a caixa em que ele se alinha.
static func anotar(ci: CanvasItem, pos: Vector2, traduzido: String, f: Font, px: int, cor: Color,
		alinhamento := HORIZONTAL_ALIGNMENT_LEFT, largura := -1.0, max_linhas := 0) -> void:
	# a caixa da TINTA, não a da linha: do alto das letras altas (0,78 do corpo acima da
	# linha de base) à ponta das descendentes (0,22 abaixo). A caixa da linha traz o
	# espaço do acento e do entrelinha, e dois títulos de entrelinha justa «encavalariam»
	# sem que nenhuma letra se tocasse.
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


## Um parágrafo que quebra a linha na `largura` (`pos` é a base da primeira
## linha). Devolve a altura que ele ocupou.
static func paragrafo(ci: CanvasItem, pos: Vector2, s: String, f: Font, tam: int, cor: Color, largura: float,
		max_linhas := -1) -> float:
	var dito := t(s)
	ci.draw_multiline_string(f, pos, dito, HORIZONTAL_ALIGNMENT_LEFT, largura, Tema.t(tam), max_linhas, cor)
	if coletar_retangulos:
		anotar(ci, pos, dito, f, Tema.t(tam), cor, HORIZONTAL_ALIGNMENT_LEFT, largura, max_linhas if max_linhas != 0 else -1)
	return altura_paragrafo(s, f, tam, largura, max_linhas)


static var _cabe := {}


## O texto que cabe em `linhas` linhas da `largura`: se não cabe, corta numa
## palavra e fecha com reticências.
static func caber(s: String, f: Font, tam: int, largura: float, linhas: int) -> String:
	# corta o texto já traduzido (cortado em português, a tradução não o acharia)
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


## O selo: mono 600 em fundo cheio, texto escuro (texto sobre acento é #21222c).
static func selo(ci: CanvasItem, pos: Vector2, s: String, cor: Color, tam := Tema.T_SELO) -> float:
	var f := Tema.mono(600)
	var w := largura(s, f, tam) + tam * 0.9
	var h := tam * 1.45
	var r := Rect2(pos, Vector2(w, h))
	moldura(ci, r, cor, cor, 0, Tema.RAIO_SELO)
	var dito := t(s)
	ci.draw_string(f, Vector2(pos.x + tam * 0.45, pos.y + h * 0.5 + tam * 0.36), dito, HORIZONTAL_ALIGNMENT_LEFT, -1, Tema.t(tam), Tema.APP)
	if coletar_retangulos:
		anotar(ci, Vector2(pos.x + tam * 0.45, pos.y + h * 0.5 + tam * 0.36), dito, f, Tema.t(tam), Tema.APP)
	return w


## As cinco lâmpadas do indicador de jogador: 1 | vão | 3 | vão | 1.
static func leds(ci: CanvasItem, pos: Vector2, mascara: int, lado := 12.0) -> float:
	var x := pos.x
	var vao := lado * 0.5
	for i in 5:
		var aceso := (mascara >> i) & 1
		var r := Rect2(Vector2(x, pos.y), Vector2(lado, lado))
		if aceso:
			ci.draw_rect(r.grow(lado * 0.35), Color(Tema.LED_ACESO, 0.18))
			ci.draw_rect(r, Tema.LED_ACESO)
		else:
			ci.draw_rect(r, Tema.TRILHO)
		x += lado + (vao * 2.0 if i == 0 or i == 3 else vao)
	return x - pos.x


## A bateria: trilho, preenchimento roxo e o número em mono verde.
static func bateria(ci: CanvasItem, pos: Vector2, pct: int, carregando: bool, largura_trilho := 90.0) -> float:
	var h := 8.0
	ci.draw_rect(Rect2(pos + Vector2(0, -h - 6), Vector2(largura_trilho, h)), Tema.TRILHO)
	if pct >= 0:
		ci.draw_rect(Rect2(pos + Vector2(0, -h - 6), Vector2(largura_trilho * clampf(pct / 100.0, 0, 1), h)), Tema.ROXO)
	var f := Tema.mono(500)
	var s := ("%d%%" % pct) if pct >= 0 else "—"
	if carregando:
		s += " ⚡"
	ci.draw_string(f, pos + Vector2(largura_trilho + 12, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, Tema.T_MONO, Tema.VERDE)
	return largura_trilho + 12 + largura(s, f, Tema.T_MONO)


## O cabeçalho do app: logo e o nome em duas linhas — "Hefesto" rosa, "Tech Demo" claro.
static func cabecalho(ci: CanvasItem, pos: Vector2, lado := 88.0) -> void:
	ci.draw_texture_rect(LOGO, Rect2(pos, Vector2(lado, lado)), false)
	var f := Tema.fonte(700)
	var tam := int(lado * 0.36)
	ci.draw_string(f, pos + Vector2(lado + 18, lado * 0.46), "Hefesto", HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Tema.ROSA)
	ci.draw_string(f, pos + Vector2(lado + 18, lado * 0.46 + tam * 1.12), "Tech Demo", HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Tema.FG)


## Uma fileira de dicas "[glifo] palavra", da direita para a esquerda a partir de `fim`.
static func dicas_a_direita(ci: CanvasItem, fim: Vector2, pares: Array, tam := Tema.T_ROTULO) -> void:
	var x := fim.x
	for i in range(pares.size() - 1, -1, -1):
		var par: Array = pares[i]
		var w := Glifo.largura_dica(par[0], par[1], tam, i == 0)
		x -= w
		Glifo.dica(ci, Vector2(x, fim.y), par[0], par[1], tam, Tema.FG, Tema.SUAVE, i == 0)
		x -= 40.0


static func dicas_a_esquerda(ci: CanvasItem, inicio: Vector2, pares: Array, tam := Tema.T_ROTULO) -> void:
	var x := inicio.x
	for i in pares.size():
		var par: Array = pares[i]
		x += Glifo.dica(ci, Vector2(x, inicio.y), par[0], par[1], tam, Tema.FG, Tema.SUAVE, i == 0)
		x += 40.0


# ------------------------------------------------------------- o cassete --
## A caixa chapada do cassete: fundo, raio e, se pedir, a borda (a placa, a etiqueta, o botão).
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


## Um carretel: o cubo com seis dentes e a fita enrolada (0 a 1).
static func carretel(ci: CanvasItem, c: Vector2, raio: float, fita: float, cor_cubo := Tema.ETIQUETA, giro := 0.0) -> void:
	var r_fita := lerpf(raio * 0.42, raio, fita)
	ci.draw_circle(c, r_fita, Tema.OXIDO)  # a fita magnética
	ci.draw_arc(c, r_fita - 1.5, PI * 1.05, PI * 1.45, 18, Tema.OXIDO_BRILHO, 2.0, true)
	ci.draw_circle(c, raio * 0.42, cor_cubo)
	ci.draw_circle(c, raio * 0.2, Tema.CASCO)
	for i in 6:
		var a := i * TAU / 6.0 + 0.3 + giro
		var d := Vector2(cos(a), sin(a))
		ci.draw_line(c + d * raio * 0.2, c + d * raio * 0.33, Tema.CASCO, 3.0, true)


## O contador de fita: rodas de número numa janela preta. `pos` é o canto de cima
## à esquerda; devolve o retângulo que ocupou.
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
		# a dobra da roda: a linha do meio
		ci.draw_line(Vector2(cel.position.x, cel.get_center().y), Vector2(cel.end.x, cel.get_center().y), Color(Tema.JANELA, 0.55), 2.0)
	return r


# ------------------------------------------------------------- o nome --
## O nome do cavaleiro é da pessoa: não passa pela tabela de traduções (G09). O mesmo desenho de
## `texto`, `caber` e `largura`, sem o `t()`.
static func nome(ci: CanvasItem, pos: Vector2, s: String, f: Font, tam: int, cor: Color,
		alinhamento := HORIZONTAL_ALIGNMENT_LEFT, largura_da_caixa := -1.0) -> void:
	ci.draw_string(f, pos, s, alinhamento, largura_da_caixa, Tema.t(tam), cor)
	if coletar_retangulos:
		anotar(ci, pos, s, f, Tema.t(tam), cor, alinhamento, largura_da_caixa)


## O nome que cabe na `largura` em uma linha: corta o fim e fecha com reticências.
static func nome_que_cabe(s: String, f: Font, tam: int, largura_da_caixa: float) -> String:
	var r := s
	while r.length() > 1 and f.get_string_size(r, HORIZONTAL_ALIGNMENT_LEFT, -1, Tema.t(tam)).x > largura_da_caixa:
		s = s.left(s.length() - 1)
		r = s + "…"
	return r


static func largura_do_nome(s: String, f: Font, tam: int) -> float:
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, Tema.t(tam)).x
