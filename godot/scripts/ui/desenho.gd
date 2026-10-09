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


## Guarda um texto já traduzido que acaba de ser desenhado em `pos` (a linha de
## base, no espaço do `ci`). `largura` > 0 é a caixa em que ele se alinha.
static func anotar(ci: CanvasItem, pos: Vector2, traduzido: String, f: Font, px: int, cor: Color,
		alinhamento := HORIZONTAL_ALIGNMENT_LEFT, largura := -1.0, max_linhas := 0) -> void:
	var tam: Vector2
	if max_linhas == 0:
		# uma linha só (`texto`, `selo`, `dica`): a largura da frase e a altura da linha
		tam = Vector2(f.get_string_size(traduzido, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x, f.get_height(px))
	else:
		tam = f.get_multiline_string_size(traduzido, HORIZONTAL_ALIGNMENT_LEFT, largura, px, max_linhas)
	var x := pos.x
	if largura > 0.0 and max_linhas == 0:
		if alinhamento == HORIZONTAL_ALIGNMENT_CENTER:
			x += (largura - tam.x) * 0.5
		elif alinhamento == HORIZONTAL_ALIGNMENT_RIGHT:
			x += largura - tam.x
	var local := Rect2(Vector2(x, pos.y - f.get_ascent(px)), tam)
	var m := ci.get_global_transform_with_canvas()
	retangulos.append({"frase": traduzido, "rect": m * local, "tam": px, "cor": cor, "no": ci.get_instance_id()})


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
