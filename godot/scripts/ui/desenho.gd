class_name Desenho
extends RefCounted
## As peças de desenho da interface, no padrão do app Hefesto: moldura chapada
## com borda, selo cheio em mono, as cinco lâmpadas do LED de jogador, a barra
## de bateria, o texto com alinhamento. Tudo em cima da API 2D do Godot.

const LOGO := preload("res://assets/hefesto-logo.png")

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


static func texto(ci: CanvasItem, pos: Vector2, s: String, f: Font, tam: int, cor: Color,
		alinhamento := HORIZONTAL_ALIGNMENT_LEFT, largura := -1.0) -> void:
	ci.draw_string(f, pos, s, alinhamento, largura, tam, cor)


## Um parágrafo que quebra a linha na `largura` (`pos` é a base da primeira
## linha). Devolve a altura que ele ocupou.
static func paragrafo(ci: CanvasItem, pos: Vector2, s: String, f: Font, tam: int, cor: Color, largura: float,
		max_linhas := -1) -> float:
	ci.draw_multiline_string(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, largura, tam, max_linhas, cor)
	return altura_paragrafo(s, f, tam, largura, max_linhas)


static var _cabe := {}


## O texto que cabe em `linhas` linhas da `largura`: se não cabe, corta numa
## palavra e fecha com reticências.
static func caber(s: String, f: Font, tam: int, largura: float, linhas: int) -> String:
	var chave := "%s|%d|%d|%d" % [s, tam, int(largura), linhas]
	if _cabe.has(chave):
		return _cabe[chave]
	var limite := f.get_height(tam) * linhas + 1.0
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
	return f.get_multiline_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, largura, tam, max_linhas).y


static func largura(s: String, f: Font, tam: int) -> float:
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x


## O selo: mono 600 em fundo cheio, texto escuro (texto sobre acento é #21222c).
static func selo(ci: CanvasItem, pos: Vector2, s: String, cor: Color, tam := Tema.T_SELO) -> float:
	var f := Tema.mono(600)
	var w := largura(s, f, tam) + tam * 0.9
	var h := tam * 1.45
	var r := Rect2(pos, Vector2(w, h))
	moldura(ci, r, cor, cor, 0, Tema.RAIO_SELO)
	ci.draw_string(f, Vector2(pos.x + tam * 0.45, pos.y + h * 0.5 + tam * 0.36), s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Tema.APP)
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
		var w := Glifo.largura_dica(par[0], par[1], tam)
		x -= w
		Glifo.dica(ci, Vector2(x, fim.y), par[0], par[1], tam, Tema.FG, Tema.SUAVE)
		x -= 40.0


static func dicas_a_esquerda(ci: CanvasItem, inicio: Vector2, pares: Array, tam := Tema.T_ROTULO) -> void:
	var x := inicio.x
	for par in pares:
		x += Glifo.dica(ci, Vector2(x, inicio.y), par[0], par[1], tam, Tema.FG, Tema.SUAVE)
		x += 40.0
