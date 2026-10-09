class_name MapaDoControle
extends Control
## O mapa do controle: o desenho do DualSense do app Hefesto, com o que o
## controle do lugar faz AGORA. A casca na cor de luz do jogador (a borda diz
## QUAL); o botão apertado acende na cor da etiqueta, o analógico anda, o gatilho enche,
## o dedo no touchpad é um ponto claro; a barra de luz mostra a cor que o jogo
## mandou, as cinco lâmpadas o padrão do lugar, o motor que vibra fica mostarda.
##
## As camadas saem do SVG por scripts/mapa_do_controle.js (assets/mapa/).

const PASTA := "res://assets/mapa/"

## botão -> peça do desenho (o id do pecas-do-dualsense.csv)
const PECA_DO_BOTAO := {
	0: "cross", 1: "circle", 2: "square", 3: "triangle",
	4: "share", 5: "ps", 6: "options", 9: "l1", 10: "r1",
	11: "dpad_up", 12: "dpad_down", 13: "dpad_left", 14: "dpad_right",
	15: "mic",
}

var lugar := 0
## false: o desenho parado (um lugar vazio, ou a figura da tela de título)
var ao_vivo := true
## a cor da casca; sem ela, a do lugar
var cor_casca := Color.TRANSPARENT

static var _texturas := {}
static var _camadas := {}
static var _pecas := {}
static var _viewbox := [6.399, 22.990, 116.684, 80.472]


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carregar_indice()


func _process(_dt: float) -> void:
	if ao_vivo and is_visible_in_tree():
		queue_redraw()


static func _carregar_indice() -> void:
	if not _camadas.is_empty():
		return
	var f := FileAccess.open(PASTA + "pecas.json", FileAccess.READ)
	if f == null:
		push_error("mapa do controle: falta assets/mapa/pecas.json (rode scripts/mapa_do_controle.js)")
		return
	var j: Dictionary = JSON.parse_string(f.get_as_text())
	_camadas = j.get("camadas", {})
	_pecas = j.get("pecas", {})
	_viewbox = j.get("viewbox", _viewbox)


## A camada, com mipmaps: o desenho é de 1160 px e aparece bem menor.
static func _tex(nome: String) -> Texture2D:
	if _texturas.has(nome):
		return _texturas[nome]
	var t: Texture2D = load(PASTA + nome + ".png")
	var tex: Texture2D = null
	if t:
		var img := t.get_image()
		if img:
			img.decompress()
			img.generate_mipmaps()
			tex = ImageTexture.create_from_image(img)
	_texturas[nome] = tex
	return tex


## Onde o desenho inteiro (1160×800) cabe no controle, sem deformar.
func area() -> Rect2:
	var proporcao := 1160.0 / 800.0
	var w := size.x
	var h := size.x / proporcao
	if h > size.y:
		h = size.y
		w = h * proporcao
	return Rect2((size.x - w) * 0.5, (size.y - h) * 0.5, w, h)


func _camada(nome: String, cor := Tema.ETIQUETA, desloc := Vector2.ZERO) -> void:
	var t := _tex(nome)
	if t == null or not _camadas.has(nome):
		return
	var a := area()
	var k := a.size.x / 1160.0
	var c: Array = _camadas[nome]
	var r := Rect2(a.position + Vector2(c[0], c[1]) * k + desloc * k, Vector2(c[2], c[3]) * k)
	draw_texture_rect(t, r, false, cor)


## Um ponto do viewBox do SVG, na tela.
func ponto_do_desenho(vx: float, vy: float) -> Vector2:
	var a := area()
	return a.position + Vector2((vx - _viewbox[0]) / _viewbox[2] * a.size.x, (vy - _viewbox[1]) / _viewbox[3] * a.size.y)


## A caixa de uma peça (do CSV) na tela.
func caixa_da_peca(id: String) -> Rect2:
	if not _pecas.has(id):
		return Rect2()
	var c: Array = _pecas[id]["caixa"]
	var p1 := ponto_do_desenho(c[0], c[1])
	var p2 := ponto_do_desenho(c[2], c[3])
	return Rect2(p1, p2 - p1)


func _draw() -> void:
	var cor := cor_casca if cor_casca.a > 0.0 else Tema.tom_para_a_borda(Forja.cor_do_lugar(lugar))
	var vivo: bool = ao_vivo and Forja.ocupado(lugar) and bool(Forja.lugar(lugar).get("conectado", false))
	var saida: Dictionary = Forja.estado_saida(lugar) if vivo else {}

	_camada("base")
	_camada("corpo", cor if vivo or not ao_vivo else Color(Tema.GRAFITE, 1.0))

	# o motor que vibra: a empunhadura fica mostarda e treme (esquerda = forte)
	if vivo:
		var forte: float = saida.get("forte", 0.0)
		var fraco: float = saida.get("fraco", 0.0)
		var t := Time.get_ticks_msec() / 1000.0
		if forte > 0.01:
			var j := Vector2(sin(t * 91.0), cos(t * 77.0)) * 2.5 * forte
			_camada("feat-rumble-esquerdo", Color(Tema.SECAO[3], 0.35 + 0.5 * forte), j)
		if fraco > 0.01:
			var j := Vector2(sin(t * 133.0), cos(t * 117.0)) * 1.5 * fraco
			_camada("feat-rumble-direito", Color(Tema.SECAO[3], 0.35 + 0.5 * fraco), j)

	# a barra de luz: a cor que o jogo mandou (luz, não plástico)
	var luz: Color = saida.get("luz", Color.TRANSPARENT)
	if vivo and luz.a > 0.0 and luz.get_luminance() > 0.01:
		_camada("lightbar", Color(luz, 0.95))

	# as cinco lâmpadas: o padrão que diz o número do lugar
	var leds: int = saida.get("leds_jogador", 0) if vivo else 0
	for i in 5:
		if leds & (1 << i):
			_camada("led-jogador-%d" % (i + 1), Tema.ETIQUETA)

	# o LED do mudo
	if vivo and int(saida.get("led_mic", 0)) != 0:
		var pisca := int(saida.get("led_mic", 0)) >= 2
		if not pisca or fmod(Time.get_ticks_msec() / 1000.0, 1.0) < 0.5:
			_camada("mic", Tema.SECAO[3])

	if not vivo:
		_camada("miolo_l")
		_camada("miolo_r")
		return

	# os gatilhos: enchem com o curso
	for par in [[Forja.L2, "l2"], [Forja.R2, "r2"]]:
		var v := Forja.eixo(lugar, par[0])
		if v > 0.02:
			_camada(par[1], Color(Tema.ETIQUETA, 0.25 + 0.6 * v))
			_camada("glifo-" + par[1], Tema.ETIQUETA)

	# os botões
	for botao in PECA_DO_BOTAO:
		if Forja.segura(lugar, botao):
			var peca: String = PECA_DO_BOTAO[botao]
			_camada(peca, Color(Tema.ETIQUETA, 0.30))
			_camada("glifo-" + peca, Tema.ETIQUETA)

	# o touchpad: o clique acende a superfície; cada dedo é um ponto
	if Forja.segura(lugar, Forja.TOUCHPAD):
		_camada("touchpad", Color(Tema.ETIQUETA, 0.35))
	var tp := caixa_da_peca("touchpad")
	for i in 2:
		var d := Forja.dedo(lugar, i)
		if d.z > 0.5:
			var p := tp.position + Vector2(d.x * tp.size.x, d.y * tp.size.y)
			var raio := maxf(4.0, tp.size.y * 0.07)
			draw_circle(p, raio * 1.8, Color(Tema.ETIQUETA, 0.25))
			draw_circle(p, raio, Tema.ETIQUETA)

	# os analógicos: o miolo anda com o eixo; o clique acende
	var alcance := 30.0  # px do desenho (1160 de largura)
	var l := Vector2(Forja.eixo(lugar, Forja.LX), Forja.eixo(lugar, Forja.LY))
	var r := Vector2(Forja.eixo(lugar, Forja.RX), Forja.eixo(lugar, Forja.RY))
	if Forja.segura(lugar, Forja.L3):
		_camada("stick_l", Color(Tema.ETIQUETA, 0.35))
	if Forja.segura(lugar, Forja.R3):
		_camada("stick_r", Color(Tema.ETIQUETA, 0.35))
	_camada("miolo_l", Tema.ETIQUETA, l * alcance)
	_camada("miolo_r", Tema.ETIQUETA, r * alcance)
	if l.length() > 0.2 or Forja.segura(lugar, Forja.L3):
		_camada("glifo-stick_l", Tema.ETIQUETA, l * alcance)
	if r.length() > 0.2 or Forja.segura(lugar, Forja.R3):
		_camada("glifo-stick_r", Tema.ETIQUETA, r * alcance)
