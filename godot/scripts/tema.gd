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
const AMBIENTE_SALAO := Color("#2a2738")  ## o preenchimento do salão, a luz ambiente da casa (arte/01, a luz das cinco tintas)

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

## A chave de cada tinta (arte/01, a luz das cinco tintas): o tungstênio esquentado pela tinta. É uma
## constante, não uma conta: `TUNGSTENIO.lerp(tinta, 0.2)` dá `#f4bb90` no vermelhão, e a tabela do 01 diz `#ffc99c`.
const CHAVE_SECAO := [
	Color("#ffc99c"),  ## vermelhão
	Color("#e5d3c6"),  ## cobalto
	Color("#e5d7ad"),  ## petróleo
	Color("#f8d096"),  ## mostarda
	Color("#f8ccba"),  ## ameixa
]

# --- o erro ---
const ERRO_R := Color("#ff2a4a")     ## só no deslocamento de cor da Dissonância
const ERRO_B := Color("#2a6bff")

# --- as peles das raças (o rosto e as mãos) ---
const PELE_ORC := Color("#89aa77")
const PELE_LATAO := Color("#bda978")
const PELE_ESCORIA := Color("#a3958e")
const PELE_RAPOSA := Color("#cd8d6d")

# --- a luz que não é de lugar: a pergunta, o alarme, as equipes, o ar e a matéria acesa das salas (G14b) ---
## As quatro cores que a luz do controle pergunta (O Impacto, A Prova): verde, azul, violeta e branco.
## Longe das quatro de JOGADOR (ΔE no OKLab de 0,15 ou mais; a prova confere): a pergunta nunca é a cor de um lugar.
const PERGUNTA := [Color("#00c853"), Color("#1f3dff"), Color("#ab45ff"), Color("#ffffff")]
const LANTERNA_NEUTRA := Color("#8c8c99")  ## a lanterna enquanto a pergunta corre: a tela não sopra a cor
## O vermelho do golpe e do susto, na luz do controle e na chama; a fase escura é `ALARME.darkened(k)`.
const ALARME := Color("#ff0000")
const EQUIPE := [Color("#ff4500"), Color("#0059ff")]  ## a luz da Brasa e a da Maré (o disco, a bala, a faísca do acerto)
## O ar de cada sala (as partículas da `atmosfera`: a poeira ou as brasas), pelo id da sala.
const AR := {
	"centelha": Color("#ff9a52"), "caminhos": Color("#7ff0b0"), "canto": Color("#b88cff"),
	"galeria": Color("#c28bff"), "impacto": Color("#6fa8ff"), "molde": Color("#f1c86a"),
	"prova": Color("#ffb86c"), "viga": Color("#ff6a3d"), "voz": Color("#7fe8ff"),
}
const BRONZE := Color("#b07838")         ## o sino grande d'O Canto
const BRONZE_CLARO := Color("#c08a42")   ## o sino pequeno de cada jogador d'O Canto
const METAL_FRIO := Color("#5a1a08")     ## o metal do molde, brasa apagada
const METAL_QUENTE := Color("#ff7a2a")   ## o metal do molde aquecido
const METAL_NO_PONTO := Color("#ff9a3a")  ## o metal do molde no ponto do carimbo (com OURO a 60 %)
const OURO := Color("#ffd479")           ## o ouro que o metal do molde puxa no ponto
const FAISCA := Color("#ff9a50")         ## a faísca do tiro no pilar d'A Prova
const RACHA := Color("#ffb040")          ## a rachadura que acende na pedra d'A Viga
const BONECO_DE_TREINO := Color("#b9a98a")  ## o orc de treino d'A Prova, desbotado

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
const AREA_SEGURA := 0.05  ## a margem de cada lado da tela: 5% (a régua da prova visual lê o mesmo número)
const LETRA_MINIMA := 30  ## nada que se lê é desenhado abaixo disto, a escala do texto que for

const BUNGEE := "res://assets/fontes/Bungee-Regular.ttf"
const VT323 := "res://assets/fontes/VT323-Regular.ttf"
const ARCHIVO := "res://assets/fontes/ArchivoNarrow-wght.ttf"
const MARCADOR := "res://assets/fontes/PermanentMarker-Regular.ttf"

static var _fontes := {}
## O tamanho do texto (as opções: normal ou grande): Desenho e Glifo
## multiplicam todo tamanho por ele.
static var escala_texto := 1.0


static func t(tam: int) -> int:
	return maxi(LETRA_MINIMA, int(round(tam * escala_texto)))
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


## Cor <-> OKLab (L, a, b), de godot/estudos/direcao/fita.gd: a conta da luz das seções pensa em luminosidade e croma.
static func _lin(v: float) -> float:
	return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)


static func _srgb(v: float) -> float:
	v = clampf(v, 0.0, 1.0)
	return v * 12.92 if v <= 0.0031308 else 1.055 * pow(v, 1.0 / 2.4) - 0.055


static func para_oklab(c: Color) -> Vector3:
	var r := _lin(c.r)
	var g := _lin(c.g)
	var b := _lin(c.b)
	var l := pow(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b, 1.0 / 3.0)
	var m := pow(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b, 1.0 / 3.0)
	var s := pow(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b, 1.0 / 3.0)
	return Vector3(0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
		1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
		0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)


static func de_oklab(v: Vector3, a := 1.0) -> Color:
	var l := pow(v.x + 0.3963377774 * v.y + 0.2158037573 * v.z, 3.0)
	var m := pow(v.x - 0.1055613458 * v.y - 0.0638541728 * v.z, 3.0)
	var s := pow(v.x - 0.0894841775 * v.y - 1.2914855480 * v.z, 3.0)
	return Color(_srgb(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
		_srgb(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
		_srgb(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s), a)


## A luz de uma seção (arte/01, a luz das cinco tintas), tirada da tinta no OKLab: a névoa (L 0,17, croma a 30 %),
## o preenchimento (L 0,34, croma a 55 %) e a chave (a constante CHAVE_SECAO da tinta). `numero` -1 é o salão.
## O lado B adensa a névoa (×1,3) e baixa a chave (×0,85).
static func luz_da_secao(numero: int, lado_b := false) -> Dictionary:
	var luz := {
		"densidade": 0.012 * (1.3 if lado_b else 1.0),
		"energia_chave": 1.8 * (0.85 if lado_b else 1.0),
	}
	if numero < 0:
		luz["nevoa"] = VIOLETA_FUNDO
		luz["preenchimento"] = AMBIENTE_SALAO
		luz["chave"] = TUNGSTENIO
		return luz
	var tinta := tinta_da_secao(numero)
	var o := para_oklab(tinta)
	luz["nevoa"] = de_oklab(Vector3(0.17, o.y * 0.30, o.z * 0.30))
	luz["preenchimento"] = de_oklab(Vector3(0.34, o.y * 0.55, o.z * 0.55))
	luz["chave"] = CHAVE_SECAO[maxi(0, SECAO.find(tinta))]
	return luz


# --- o brilho com dono (arte/07, a tabela do brilho; arte/12, o portão 6) ---
## Todo material que brilha nasce destas três funções, e cada uma pede o dono: um lugar (0 a 3, a cor dele, teto 3,0),
## "mundo" (VIOLETA, teto 1,2) ou "forja" (TUNGSTENIO, teto 2,4). Energia acima do teto, ou dono que não existe,
## dá `push_error` com o arquivo que chamou, e a energia é cortada no teto.
const TETO_LUGAR := 3.0
const TETO_MUNDO := 1.2
const TETO_FORJA := 2.4
const SHADER_NEON := "res://shaders/neon.gdshader"
const SHADER_CONTORNO := "res://shaders/contorno.gdshader"


## A cor e o teto de um dono: {"cor": Color, "teto": float}; sem dono válido, {"cor": cor_dada, "teto": 1.0}.
static func dono_do_brilho(dono: Variant, cor_dada := Color.WHITE) -> Dictionary:
	if typeof(dono) == TYPE_INT and int(dono) >= 0 and int(dono) < JOGADOR.size():
		return {"cor": JOGADOR[int(dono)], "teto": TETO_LUGAR, "valido": true}
	if typeof(dono) == TYPE_STRING or typeof(dono) == TYPE_STRING_NAME:
		if str(dono) == "mundo":
			return {"cor": VIOLETA, "teto": TETO_MUNDO, "valido": true}
		if str(dono) == "forja":
			return {"cor": TUNGSTENIO, "teto": TETO_FORJA, "valido": true}
	return {"cor": cor_dada, "teto": 1.0, "valido": false}


## Quem chamou (o primeiro quadro fora deste arquivo), para o erro dizer onde.
static func _quem_chamou() -> String:
	for q in get_stack():
		var fonte := str(q.get("source", ""))
		if not fonte.ends_with("tema.gd"):
			return "%s:%d" % [fonte.get_file(), int(q.get("line", 0))]
	return "?"


static func _energia_do_dono(energia: float, d: Dictionary, dono: Variant) -> float:
	if not d.valido:
		push_error("Tema: dono do brilho inválido (%s) em %s" % [str(dono), _quem_chamou()])
	elif energia > d.teto + 0.0001:
		push_error("Tema: energia %.2f acima do teto %.2f do dono %s em %s" % [energia, d.teto, str(dono), _quem_chamou()])
	return clampf(energia, 0.0, d.teto)


static func _cor_do_dono(cor: Color, d: Dictionary, dono: Variant) -> Color:
	if d.valido and not cor.is_equal_approx(d.cor):
		push_error("Tema: a cor do dono %s é %s; %s ignorada em %s" % [str(dono), d.cor.to_html(false), cor.to_html(false), _quem_chamou()])
	return d.cor if d.valido else cor


## O néon que trabalha: chapado, a energia acima de 1 para o glow pegar (shaders/neon.gdshader).
static func neon(cor: Color, energia: float, dono: Variant) -> ShaderMaterial:
	var d := dono_do_brilho(dono, cor)
	var m := ShaderMaterial.new()
	m.shader = load(SHADER_NEON)
	m.set_shader_parameter("cor", _cor_do_dono(cor, d, dono))
	m.set_shader_parameter("energia", _energia_do_dono(energia, d, dono))
	return m


## O contorno de néon, para o `next_pass` de uma superfície (shaders/contorno.gdshader).
static func contorno(cor: Color, largura: float, energia: float, dono: Variant) -> ShaderMaterial:
	var d := dono_do_brilho(dono, cor)
	var m := ShaderMaterial.new()
	m.shader = load(SHADER_CONTORNO)
	m.set_shader_parameter("cor", _cor_do_dono(cor, d, dono))
	m.set_shader_parameter("largura", largura)
	m.set_shader_parameter("energia", _energia_do_dono(energia, d, dono))
	m.set_shader_parameter("normal_suave", true)
	return m


## A energia com que um material brilha agora (0 se não brilha): quem anima o brilho lê daqui e escreve por `emissivo`.
static func brilho_de(material: StandardMaterial3D) -> float:
	return material.emission_energy_multiplier if material.emission_enabled else 0.0


## Liga o brilho de um material do corpo (emissão na cor do dono); energia 0 desliga. Devolve o próprio material.
static func emissivo(material: StandardMaterial3D, energia: float, dono: Variant) -> StandardMaterial3D:
	var d := dono_do_brilho(dono, material.albedo_color)
	var e := _energia_do_dono(energia, d, dono)
	material.emission_enabled = e > 0.0
	material.emission = d.cor
	material.emission_energy_multiplier = e
	return material


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
