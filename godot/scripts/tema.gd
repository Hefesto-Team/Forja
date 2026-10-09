class_name Tema
extends RefCounted
## A cor e a letra da Fita Magnética (docs/jogo/arte/02-cor-e-letra.md): um
## arquivo só de tokens. Código pede `Tema.ETIQUETA`, nunca `Color("#efe4c8")`.
## Quatro fontes, cada uma com o seu trabalho: Bungee no grito, VT323 no que a
## máquina mede, Archivo Narrow na voz, Permanent Marker na caneta.
##
## Os tamanhos são na tela lógica de 1920×1080, que se joga de longe: nada que
## se lê fica abaixo de 30 px.

# --- a fita: as superfícies (do mais fundo ao mais claro) ---
const FITA := Color("#0d0a16")       ## o fundo de tudo, atrás das placas
const CASCO := Color("#17121f")      ## o plástico do cassete: placa do HUD, cartão
const CASCO_ALTO := Color("#241c30")  ## a borda iluminada do plástico, o casco em foco
const GRAFITE := Color("#3a3346")    ## trilho, segmento apagado do VU, linha estrutural (nunca texto)
const JANELA := Color("#07050c")     ## o vidro escuro da janela do cassete, o fundo da célula do leader
const SOMBRA := Color(0, 0, 0, 0.45)  ## a sombra deslocada de placa, etiqueta e adesivo (nunca traço)

# --- a etiqueta: o papel e a caneta ---
const ETIQUETA := Color("#efe4c8")   ## o papel; o texto claro sobre o casco
const ETIQUETA_SOMBRA := Color("#cfc2a0")  ## a dobra do papel, a linha pautada
const TINTA := Color("#1c1626")      ## a caneta sobre a etiqueta
const TINTA_SUAVE := Color("#5a4f66")  ## o rótulo impresso na etiqueta
const MUDO := Color("#857a95")       ## o texto secundário sobre o casco (o desligado, a dica)

# --- o cenário: o par próprio, escuro, que nunca encosta nos jogadores ---
const VIOLETA := Color("#4a3aa8")    ## o néon da arquitetura (tubo na parede, beira do palco); L ≤ 0,50
const VIOLETA_FUNDO := Color("#1d1638")  ## a névoa e o preenchimento do salão
const TUNGSTENIO := Color("#ffd9a8")  ## a luz de lâmpada (pódio, foco da bigorna): luz, nunca traço nem texto
const OXIDO := Color("#3b2a22")      ## a fita magnética em si: o rolo, a tira do confete no escuro
const OXIDO_BRILHO := Color("#7a5640")  ## o óxido que pega luz: a face da tira que vira, o cabo do martelo

# --- os jogadores: os únicos néons saturados da tela ---
## A cor da lightbar do controle segue esta mesma tabela (LUZ_DO_LUGAR, nativo/nucleo/pads.c).
const JOGADOR := [
	Color("#29e6ff"),  ## P1 ciano
	Color("#ff3ea5"),  ## P2 magenta
	Color("#d4ff4a"),  ## P3 limão
	Color("#ee9a1e"),  ## P4 âmbar
]

# --- as tintas das seções: impressas, nunca néon ---
const SECAO := [
	Color("#c8432f"),  ## vermelhão: S1, S9
	Color("#2f55c4"),  ## cobalto: S2, S6
	Color("#1f8a7e"),  ## petróleo: S3, S7
	Color("#c79a2a"),  ## mostarda: S4, o pódio
	Color("#86409a"),  ## ameixa: S5, S8
]

# --- o erro ---
const ERRO_R := Color("#ff2a4a")     ## só no deslocamento de cor da Dissonância
const ERRO_B := Color("#2a6bff")

# --- as peles das raças (o rosto e as mãos) ---
const PELE_ORC := Color("#89aa77")
const PELE_LATAO := Color("#bda978")
const PELE_ESCORIA := Color("#a3958e")
const PELE_RAPOSA := Color("#cd8d6d")

# --- tamanhos (px na tela lógica de 1920×1080; a escala do 02) ---
const T_VERBO := 160    ## o verbo da entrada (Bungee)
const T_DISPLAY := 112  ## o nome do vencedor no pódio (Bungee)
const T_TITULO := 64    ## o título da tela (Bungee)
const T_PONTOS := 64    ## os pontos grandes do HUD (VT323)
const T_ETIQUETA := 56  ## o título da seção na etiqueta (Permanent Marker)
const T_AVISO := 46     ## o aviso que some sozinho (Archivo Narrow 600)
const T_CARIMBO := 46   ## o carimbo do julgamento (Bungee)
const T_SUBTITULO := 44  ## o «como jogar» do J-card
const T_PSHARP := 40    ## o P# no cartão do HUD (Bungee)
const T_CORPO := 34     ## o corpo, a frase (Archivo Narrow 500)
const T_NOME := 32      ## o nome no HUD (Archivo Narrow 600)
const T_ROTULO := 30    ## o rótulo, a dica, o stat: nada que se lê abaixo de 30 px
const T_MONO := 30
const T_SELO := 30

const RAIO_QUADRO := 18
const RAIO_CARTAO := 14
const RAIO_BOTAO := 14
const RAIO_SELO := 8
const BORDA := 2
const MARGEM_X := 96
const MARGEM_Y := 60  ## a área segura da TV (o estudo 02, item 5: y de 60 a 1020)

const BUNGEE := "res://assets/fontes/Bungee-Regular.ttf"
const VT323 := "res://assets/fontes/VT323-Regular.ttf"
const ARCHIVO := "res://assets/fontes/ArchivoNarrow-wght.ttf"
const MARCADOR := "res://assets/fontes/PermanentMarker-Regular.ttf"

static var _fontes := {}
## O tamanho do texto (as opções: normal ou grande): Desenho e Glifo
## multiplicam todo tamanho por ele.
static var escala_texto := 1.0


static func t(tam: int) -> int:
	return int(round(tam * escala_texto))
static var _tema: Theme


## Bungee: o grito (o verbo da entrada, o carimbo, o P#, o vencedor).
static func bungee() -> Font:
	return _variacao(BUNGEE, 0)


## VT323: o que a máquina mede (pontos, tempo, rótulo de stat).
static func vt() -> Font:
	return _variacao(VT323, 0)


## Archivo Narrow: a voz. 500 no texto, 600 no nome e no rótulo, 700 no botão.
static func archivo(peso := 500) -> Font:
	return _variacao(ARCHIVO, peso)


## Permanent Marker: a caneta (o que alguém escreveu na etiqueta).
static func marcador() -> Font:
	return _variacao(MARCADOR, 0)


## A tinta da seção (1 a 9; 0 é o pódio): S1 e S9 vermelhão, S2 e S6 cobalto,
## S3 e S7 petróleo, S4 e o pódio mostarda, S5 e S8 ameixa.
static func tinta_da_secao(numero: int) -> Color:
	match numero:
		1, 9:
			return SECAO[0]
		2, 6:
			return SECAO[1]
		3, 7:
			return SECAO[2]
		5, 8:
			return SECAO[4]
	return SECAO[3]


static func _variacao(caminho: String, peso: int) -> Font:
	var chave := "%s@%d" % [caminho, peso]
	if _fontes.has(chave):
		return _fontes[chave]
	var base: FontFile = load(caminho)
	var f: Font = base
	if peso > 0:
		var fv := FontVariation.new()
		fv.base_font = base
		fv.variation_opentype = {"wght": peso}
		f = fv
	_fontes[chave] = f
	return f


## O tema dos Controls: aplicado uma vez na raiz de cada camada de interface.
static func tema() -> Theme:
	if _tema:
		return _tema
	var t := Theme.new()
	t.default_font = archivo(500)
	t.default_font_size = T_CORPO
	t.set_color("font_color", "Label", ETIQUETA)
	t.set_constant("line_spacing", "Label", 4)

	_variante(t, "Titulo", archivo(600), T_CORPO, ETIQUETA)
	_variante(t, "TituloTela", bungee(), T_TITULO, ETIQUETA)
	_variante(t, "Subtitulo", archivo(500), T_SUBTITULO, ETIQUETA)
	_variante(t, "Display", bungee(), T_DISPLAY, ETIQUETA)
	_variante(t, "Rotulo", archivo(600), T_ROTULO, ETIQUETA)
	_variante(t, "Suave", archivo(500), T_ROTULO, ETIQUETA_SOMBRA)
	_variante(t, "Mudo", archivo(500), T_ROTULO, MUDO)
	_variante(t, "Nome", archivo(600), T_NOME, ETIQUETA)
	_variante(t, "Mono", vt(), T_MONO, ETIQUETA_SOMBRA)
	_variante(t, "MonoValor", vt(), T_MONO, ETIQUETA)
	_variante(t, "Marca", archivo(700), T_CORPO, ETIQUETA)

	t.set_stylebox("panel", "PanelContainer", quadro())
	t.set_stylebox("panel", "Panel", quadro())
	return t


static func _variante(t: Theme, nome: String, f: Font, tam: int, cor: Color) -> void:
	t.set_type_variation(nome, "Label")
	t.set_font("font", nome, f)
	t.set_font_size("font_size", nome, tam)
	t.set_color("font_color", nome, cor)


## O quadro: chapado, borda estrutural de 2 px, raio 18.
static func quadro(fundo := CASCO, borda := GRAFITE, raio := RAIO_QUADRO, folga := 28) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.border_color = borda
	s.set_border_width_all(BORDA)
	s.set_corner_radius_all(raio)
	s.set_content_margin_all(folga)
	s.anti_aliasing = true
	return s


## A cor de identidade de um controle como borda: a luz do jogador clareada até
## ter contraste contra o painel (o `tom_para_a_borda` do app) — na visão comum
## e também na protanopia, na deuteranopia e na tritanopia (Machado 2009): o
## "P2" vermelho não pode virar um oliva que some no painel.
static func tom_para_a_borda(c: Color) -> Color:
	if _borda.has(c):
		return _borda[c]
	var r := c
	for i in 20:
		if _pior_contraste(r) >= 3.0:
			break
		r = r.lerp(Color.WHITE, 0.05)
	_borda[c] = r
	return r


static var _borda := {}

const _DALTONISMO := [
	[0.152286, 1.052583, -0.204868, 0.114503, 0.786281, 0.099216, -0.003882, -0.048116, 1.051998],
	[0.367322, 0.860646, -0.227968, 0.280085, 0.672501, 0.047413, -0.011820, 0.042940, 0.968881],
	[1.255528, -0.076749, -0.178779, -0.078411, 0.930809, 0.147602, 0.004733, 0.691367, 0.303900],
]


static func _pior_contraste(c: Color) -> float:
	var pior := contraste(c, CASCO)
	var lin := c.srgb_to_linear()
	for m in _DALTONISMO:
		var s := Color(m[0] * lin.r + m[1] * lin.g + m[2] * lin.b, m[3] * lin.r + m[4] * lin.g + m[5] * lin.b,
			m[6] * lin.r + m[7] * lin.g + m[8] * lin.b).clamp().linear_to_srgb()
		pior = minf(pior, contraste(s, CASCO))
	return pior


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
