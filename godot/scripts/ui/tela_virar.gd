class_name TelaVirar
extends Control
## O virar da fita e o intervalo (G16). No meio da noite o cassete sai do deck, vira
## e entra de volta com o lado B para cima: 4000 ms contados desde `T0`, sem botão.
## Depois, o intervalo: o salão na luz do lado B, a etiqueta «Lado B» em cima e a dica
## de seguir. 2D na tela lógica de 1920×1080; o salão do intervalo é o 3D de trás.
##
## O desenho do cassete é próprio daqui: a placa e a etiqueta de verdade (G01, G11)
## entram no lugar quando elas existirem.

const TOTAL_MS := 4000.0  ## o plano inteiro, fixo
const CLUNK_MS := 1380.0  ## o cassete entra de volta no deck
const CANETA_MS := 2000.0  ## «LADO B» começa a ser escrito
const CANETA_DURACAO_MS := 400.0
const CORTE_REDUZIDO_MS := 690.0  ## no Reduzido a face troca num corte seco

const DECK := Rect2(300, 110, 1320, 860)
const BERCO := Rect2(370, 150, 1180, 750)
const TAMPA := Rect2(370, 900, 1180, 40)
const CASSETE := Rect2(400, 170, 1120, 690)
const ETIQUETA := Rect2(456, 218, 1008, 360)
const CENTRO := Vector2(960, 515)

var modo := ""  ## "", "virar" ou "intervalo"
var ms := 0.0  ## o tempo do virar, em ms desde `T0`
var rotulo := ""  ## «Partida · sala 4 de 5», no intervalo
var _caneta: Control  ## «LADO B» recortado, para aparecer da esquerda para a direita


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_caneta = Control.new()
	_caneta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caneta.clip_contents = true
	_caneta.draw.connect(_desenhar_caneta)
	add_child(_caneta)


## O virar começa agora (`T0`).
func virar() -> void:
	modo = "virar"
	ms = 0.0
	queue_redraw()


func intervalo(texto_do_rotulo: String) -> void:
	modo = "intervalo"
	rotulo = texto_do_rotulo
	queue_redraw()


func parar() -> void:
	modo = ""
	queue_redraw()


func andar(dt: float) -> void:
	ms += dt * 1000.0


func _process(_dt: float) -> void:
	if visible and modo != "":
		queue_redraw()


# ------------------------------------------------------------------ as curvas --

## SAI (arte/05): o cúbico que chega devagar.
static func sai(u: float) -> float:
	return 1.0 - pow(1.0 - clampf(u, 0.0, 1.0), 3.0)


## ENTRA: o cúbico que parte devagar.
static func entra(u: float) -> float:
	return pow(clampf(u, 0.0, 1.0), 3.0)


## A pose do cassete no tempo `t` do virar: a escala, o deslocamento para cima (px, negativo sobe), a largura (cos do giro)
## e a face de cima. No Reduzido o cassete não se mexe: só a face troca, em corte.
static func pose(t: float, reduzido: bool) -> Dictionary:
	if reduzido:
		return {"esc": 1.0, "dy": 0.0, "sx": 1.0, "face": "B" if t >= CORTE_REDUZIDO_MS else "A"}
	var esc := 1.0
	var dy := 0.0
	var sx := 1.0
	var face := "A"
	if t < 60.0:
		dy = -12.0 * sai(t / 60.0)
	elif t < 360.0:
		var k := sai((t - 60.0) / 300.0)
		dy = -12.0 + (-28.0) * k
		esc = 1.0 + 0.08 * k
	elif t < 1080.0:
		dy = -40.0
		esc = 1.08
		var u := (t - 360.0) / 720.0
		sx = absf(cos(PI * u))
		face = "A" if u < 0.5 else "B"
	elif t < CLUNK_MS:
		var k := entra((t - 1080.0) / 300.0)
		dy = -40.0 * (1.0 - k)
		esc = 1.08 - 0.08 * k
		face = "B"
	else:
		face = "B"
		if t < CLUNK_MS + 34.0:
			dy = 6.0  # o clunk: afunda 6 px por 2 quadros
	return {"esc": esc, "dy": dy, "sx": sx, "face": face}


## Os carretéis de cada face (esquerda, direita): o lado A acabou, o B está cheio.
static func carreteis(face: String) -> Vector2:
	return Vector2(0.30, 0.95) if face == "A" else Vector2(0.95, 0.30)


# ------------------------------------------------------------------ o desenho --

func _draw() -> void:
	if modo == "virar":
		_desenhar_o_virar()
	elif modo == "intervalo":
		_desenhar_o_intervalo()
	if _caneta:
		var aparece := modo == "virar" and ms >= CANETA_MS
		_caneta.visible = aparece
		if aparece:
			var f := clampf((ms - CANETA_MS) / CANETA_DURACAO_MS, 0.0, 1.0)
			_caneta.position = Vector2(630, 310)
			_caneta.size = Vector2(660.0 * f, 190)
			_caneta.queue_redraw()


func _desenhar_o_virar() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Tema.FITA)
	draw_rect(Rect2(DECK.position + Vector2(10, 16), DECK.size), Tema.SOMBRA)
	Desenho.moldura(self, DECK, Tema.CASCO, Tema.CASCO_ALTO, 4, 40)
	Desenho.moldura(self, BERCO, Tema.JANELA, Color.TRANSPARENT, 0, 28)
	Desenho.moldura(self, TAMPA, Tema.GRAFITE, Color.TRANSPARENT, 0, 8)
	var p := pose(ms, Opcoes.reduzido())
	var animando: bool = not (is_equal_approx(float(p.esc), 1.0) and is_equal_approx(float(p.sx), 1.0) and is_zero_approx(float(p.dy)))
	var coleta := Desenho.coletar_retangulos
	if animando:
		# o texto que gira não tem retângulo certo para a régua da tela: ela mede o plano parado
		Desenho.coletar_retangulos = false
		var t1 := Transform2D(0.0, Vector2(float(p.sx) * float(p.esc), float(p.esc)), 0.0, CENTRO + Vector2(0, float(p.dy)))
		var t2 := Transform2D(0.0, Vector2.ONE, 0.0, -CENTRO)
		draw_set_transform_matrix(t1 * t2)
	_cassete(str(p.face))
	if animando:
		draw_set_transform_matrix(Transform2D.IDENTITY)
		Desenho.coletar_retangulos = coleta


## O cassete: o casco, os parafusos, a etiqueta da face, a janela com os dois carretéis e o pé.
func _cassete(face: String) -> void:
	Desenho.moldura(self, CASSETE, Tema.CASCO_ALTO, Tema.MUDO, 4, 36)
	for canto in [Vector2(44, 44), Vector2(CASSETE.size.x - 44, 44), Vector2(44, CASSETE.size.y - 44), Vector2(CASSETE.size.x - 44, CASSETE.size.y - 44)]:
		var c: Vector2 = CASSETE.position + canto
		draw_circle(c, 15.0, Tema.GRAFITE)
		draw_line(c + Vector2(-9, -3), c + Vector2(9, 3), Tema.MUDO, 3.0, true)
	_etiqueta(face)
	# a janela e os carretéis
	var janela := Rect2(560, 610, 800, 150)
	Desenho.moldura(self, janela, Tema.JANELA, Tema.GRAFITE, 3, 20)
	var cheios := carreteis(face)
	var esq := Vector2(760, 685)
	var dir := Vector2(1160, 685)
	draw_line(esq, dir, Tema.OXIDO_BRILHO, 3.0, true)
	for par in [[esq, cheios.x], [dir, cheios.y]]:
		var c2: Vector2 = par[0]
		draw_circle(c2, 36.0 + float(par[1]) * 30.0, Tema.OXIDO)
		draw_circle(c2, 24.0, Tema.ETIQUETA_SOMBRA)
		draw_circle(c2, 11.0, Tema.JANELA)
	# o pé
	draw_colored_polygon(PackedVector2Array([Vector2(660, 860), Vector2(700, 800), Vector2(1220, 800), Vector2(1260, 860)]), Tema.CASCO)
	draw_circle(Vector2(760, 832), 11.0, Tema.JANELA)
	draw_circle(Vector2(1160, 832), 11.0, Tema.JANELA)


## A etiqueta de papel. A face A leva o logo e o nome; a B vem em branco (a caneta escreve «Lado B»), com a tarja dupla.
func _etiqueta(face: String) -> void:
	var e := ETIQUETA
	Desenho.moldura(self, e, Tema.ETIQUETA, Color.TRANSPARENT, 0, 10)
	draw_rect(Rect2(e.position, Vector2(e.size.x, 40)), Tema.SECAO[0])
	if face == "B":
		draw_rect(Rect2(e.position + Vector2(0, 52), Vector2(e.size.x, 14)), Tema.SECAO[0])
		for i in 3:
			var y := e.position.y + 150.0 + i * 70.0
			draw_line(Vector2(e.position.x + 40, y), Vector2(e.end.x - 40, y), Tema.ETIQUETA_SOMBRA, 3.0)
		return
	draw_texture_rect(Desenho.LOGO, Rect2(e.position + Vector2(48, 100), Vector2(180, 180)), false)
	Desenho.texto(self, e.position + Vector2(268, 200), "A Forja", Tema.bungee(), 96, Tema.TINTA)
	draw_line(e.position + Vector2(268, 236), e.position + Vector2(e.size.x - 48, 236), Tema.ETIQUETA_SOMBRA, 3.0)
	Desenho.texto(self, e.position + Vector2(268, 296), "Quatro DualSense no mesmo sofá.", Tema.archivo(500), Tema.T_SUBTITULO, Tema.TINTA_SUAVE)


## «LADO B» na caneta: Permanent Marker, girado −3°, dentro do recorte que cresce.
func _desenhar_caneta() -> void:
	var f := Tema.marcador()
	var texto := Desenho.t("Lado B").to_upper()
	var w := Desenho.largura(texto, f, 120)
	var pivo := Vector2(330, 95)
	_caneta.draw_set_transform(pivo, deg_to_rad(-3.0), Vector2.ONE)
	Desenho.texto(_caneta, Vector2(-w * 0.5, 42), texto, f, 120, Tema.TINTA)
	_caneta.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _desenhar_o_intervalo() -> void:
	var e := Rect2(660, 60, 600, 150)
	draw_rect(Rect2(e.position + Vector2(8, 12), e.size), Tema.SOMBRA)
	Desenho.moldura(self, e, Tema.ETIQUETA, Color.TRANSPARENT, 0, 10)
	draw_rect(Rect2(e.position, Vector2(e.size.x, 18)), Tema.SECAO[0])
	draw_rect(Rect2(e.position + Vector2(0, 26), Vector2(e.size.x, 8)), Tema.SECAO[0])
	Desenho.texto(self, Vector2(660, 124), "Lado B", Tema.marcador(), 72, Tema.TINTA, HORIZONTAL_ALIGNMENT_CENTER, 600.0)
	Desenho.texto(self, Vector2(660, 188), rotulo, Tema.vt(), 46, Tema.TINTA_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, 600.0)
	# a dica de seguir, numa placa para a letra não se perder no salão
	var tam := Tema.t(Tema.T_ROTULO)
	var larg := Glifo.largura_dica("cruz", "Seguir", Tema.T_ROTULO, false)
	var placa := Rect2(Vector2(960.0 - larg * 0.5 - 28.0, 1000.0 - tam - 22.0), Vector2(larg + 56.0, tam + 44.0))
	Desenho.moldura(self, placa, Color(Tema.CASCO, 0.9), Tema.GRAFITE, 2, Tema.RAIO_BOTAO)
	Glifo.dica(self, Vector2(960.0 - larg * 0.5, 1000.0), "cruz", "Seguir", Tema.T_ROTULO, Tema.ETIQUETA, Tema.ETIQUETA, false)
