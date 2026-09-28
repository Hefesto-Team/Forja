class_name Tema
extends RefCounted
## A cara do jogo é a cara do app Hefesto: a paleta Drácula com um trabalho
## por cor, Space Grotesk no texto, JetBrains Mono no que o controle mede,
## quadros chapados com borda de 2 px, maiúscula só no começo da frase.
##
## Os tamanhos são os do app vezes dois (a tela lógica é 1920×1080 e se joga
## de longe): nada de texto abaixo de 28 px.

# --- superfícies ---
const CASA := Color("#11121a")      ## atrás de tudo, as tarjas
const APP := Color("#21222c")       ## o fundo, o "afundado": campo, chip, moldura interna
const PAINEL := Color("#282a36")    ## o quadro, o cartão
const ELEVADO := Color("#2b2d3a")   ## o balão
const LINHA := Color("#53576f")     ## a borda estrutural (nunca borda que carrega informação)
const TRILHO := Color("#44475a")    ## trilho de medidor
const SUTIL := Color("#343746")     ## divisória interna, lugar vazio
const SEL := Color("#403b55")       ## o interior do que foi escolhido (roxo a 16%)

# --- texto ---
const FG := Color("#f8f8f2")
const SUAVE := Color("#c8ccda")
const MUDO := Color("#9a9eb8")
const COMMENT := Color("#8896c4")

# --- acentos: um trabalho cada ---
const ROXO := Color("#bd93f9")      ## seleção, título de quadro, foco
const ROSA := Color("#ff79c6")      ## a marca; o que o controle faz AGORA
const VERDE := Color("#50fa7b")     ## confirma, ligado, rótulo de campo, deu certo
const LARANJA := Color("#ffb86c")   ## atenção, pendente, motor vibrando
const VERMELHO := Color("#ff5555")  ## falhou, perigo (só texto e traço)
const CIANO := Color("#8be9fd")     ## informa: valores, toque, onda do microfone
const AMARELO := Color("#f1fa8c")   ## só no logo
const LED_ACESO := Color("#e8ecf5") ## a lâmpada do LED de jogador acesa

# --- tamanhos (px na tela lógica de 1920×1080) ---
const T_DISPLAY := 112
const T_TITULO := 64
const T_SUBTITULO := 44
const T_CORPO := 32
const T_ROTULO := 28
const T_MONO := 28
const T_SELO := 24

const RAIO_QUADRO := 18
const RAIO_CARTAO := 14
const RAIO_BOTAO := 14
const RAIO_SELO := 8
const BORDA := 2
const MARGEM_X := 96
const MARGEM_Y := 56

const _SG := "res://assets/fontes/SpaceGrotesk-wght.ttf"
const _MONO := "res://assets/fontes/JetBrainsMono-wght.ttf"

static var _fontes := {}
static var _tema: Theme


## Space Grotesk no peso pedido (400 texto, 500 nome, 600 rótulo e título, 700 marca).
static func fonte(peso := 400) -> Font:
	return _variacao(_SG, peso)


## JetBrains Mono: o que o controle mede, os valores, os selos.
static func mono(peso := 400) -> Font:
	return _variacao(_MONO, peso)


static func _variacao(caminho: String, peso: int) -> Font:
	var chave := "%s@%d" % [caminho, peso]
	if _fontes.has(chave):
		return _fontes[chave]
	var base: FontFile = load(caminho)
	var fv := FontVariation.new()
	fv.base_font = base
	fv.variation_opentype = {"wght": peso}
	_fontes[chave] = fv
	return fv


## O tema dos Controls: aplicado uma vez na raiz de cada camada de interface.
static func tema() -> Theme:
	if _tema:
		return _tema
	var t := Theme.new()
	t.default_font = fonte(400)
	t.default_font_size = T_CORPO
	t.set_color("font_color", "Label", FG)
	t.set_constant("line_spacing", "Label", 4)

	_variante(t, "Titulo", fonte(600), T_CORPO, ROXO)
	_variante(t, "TituloTela", fonte(700), T_TITULO, FG)
	_variante(t, "Subtitulo", fonte(500), T_SUBTITULO, FG)
	_variante(t, "Display", fonte(700), T_DISPLAY, FG)
	_variante(t, "Rotulo", fonte(600), T_ROTULO, VERDE)
	_variante(t, "Suave", fonte(400), T_ROTULO, SUAVE)
	_variante(t, "Mudo", fonte(400), T_ROTULO, MUDO)
	_variante(t, "Nome", fonte(500), T_CORPO, FG)
	_variante(t, "Mono", mono(400), T_MONO, SUAVE)
	_variante(t, "MonoValor", mono(500), T_MONO, CIANO)
	_variante(t, "Marca", fonte(700), T_CORPO, ROSA)

	t.set_stylebox("panel", "PanelContainer", quadro())
	t.set_stylebox("panel", "Panel", quadro())
	return t


static func _variante(t: Theme, nome: String, f: Font, tam: int, cor: Color) -> void:
	t.set_type_variation(nome, "Label")
	t.set_font("font", nome, f)
	t.set_font_size("font_size", nome, tam)
	t.set_color("font_color", nome, cor)


## O quadro: chapado, borda estrutural de 2 px, raio 18.
static func quadro(fundo := PAINEL, borda := LINHA, raio := RAIO_QUADRO, folga := 28) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.border_color = borda
	s.set_border_width_all(BORDA)
	s.set_corner_radius_all(raio)
	s.set_content_margin_all(folga)
	s.anti_aliasing = true
	return s


## A cor de identidade de um controle como borda: a luz do jogador clareada até
## ter contraste contra o painel (o `tom_para_a_borda` do app).
static func tom_para_a_borda(c: Color) -> Color:
	var r := c
	for i in 20:
		if contraste(r, PAINEL) >= 3.0:
			break
		r = r.lerp(Color.WHITE, 0.05)
	return r


static func luminancia(c: Color) -> float:
	var canal := func(v: float) -> float:
		return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * canal.call(c.r) + 0.7152 * canal.call(c.g) + 0.0722 * canal.call(c.b)


static func contraste(a: Color, b: Color) -> float:
	var la := luminancia(a)
	var lb := luminancia(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## Um Label pronto, na variante pedida.
static func rotulo(texto: String, variante := "", tam := 0) -> Label:
	var l := Label.new()
	l.text = texto
	if variante != "":
		l.theme_type_variation = variante
	if tam > 0:
		l.add_theme_font_size_override("font_size", tam)
	return l
