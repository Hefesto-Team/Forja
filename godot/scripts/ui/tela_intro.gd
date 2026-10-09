class_name TelaIntro
extends Control
## A introdução (arte/01), 24 s sem uma palavra, só na primeira vez da sessão:
## a forja acesa na batida, a Dissonância que apaga tudo e a estática que cresce,
## as quatro armaduras vazias que acendem uma a uma, e a forja que reacende.
## O salão e os bonecos são do mundo; esta tela guarda a linha do tempo e
## desenha a estática por cima.

signal musica_do_titulo_volta  ## aos 19 s: o main religa a faixa do título

const DURACAO := 24.0
const TOM_DO_LUGAR := [1.0, 1.1225, 1.3348, 1.4983]  ## Dó, Ré, Fá, Sol
const ACENDE := [12.5, 14.0, 15.5, 17.0]
const ACENDER_S := 4.0 / 60.0  ## a armadura acende em 4 quadros
const COMPASSO_S := 4.0 * 60.0 / 115.0  ## o compasso da faixa do título

var t := 0.0
var acabou := false
var salao: Salao = null
var jogadores: Array = []
var _estatica := 0.0  ## 0..1: a densidade da estática
var _acendeu := [false, false, false, false]
var _vento := [false, false]
var _calou := false
var _voltou := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Zera a linha do tempo e mostra os quatro bonecos vazios nos pedestais.
func comecar(sala: Salao, bonecos: Array) -> void:
	salao = sala
	jogadores = bonecos
	t = 0.0
	acabou = false
	_estatica = 0.0
	_acendeu = [false, false, false, false]
	_vento = [false, false]
	_calou = false
	_voltou = false
	for l in 4:
		var p: ForjaPlayer = jogadores[l]
		p.visible = true
		p.controlavel = false
		p.preso = true  # o boneco não volta ao idle a cada tick e deixa a estática
		p.global_position = salao.pedestais[l]
		p.rotation.y = 0.0
		p.animar("static")
		p.cabeca(false)
		p.acender(0.0)
	_texto_do_mundo(false)
	queue_redraw()


## Devolve o salão e os bonecos ao normal (também quando se pula).
func terminar() -> void:
	if salao:
		salao.pulso = -1.0
		salao.apagado = 0.0
	for p in jogadores:
		p.preso = false
		p.cabeca(true)
		p.acender(1.0)
		p.animar("idle")
	_texto_do_mundo(true)
	_estatica = 0.0
	queue_redraw()


## A curva ENTRA_SAI (cúbica) do 05.
static func entra_sai(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return 4.0 * x * x * x if x < 0.5 else 1.0 - pow(-2.0 * x + 2.0, 3.0) * 0.5


## Anda a linha do tempo e toca o que a tabela manda; o main chama no estado "intro".
func quadro(dt: float) -> void:
	if salao == null:
		return
	t += dt
	# a Dissonância: apaga em 4 a 9 s, reacende em 19 a 21 s
	if t < 19.0:
		salao.apagado = entra_sai((t - 4.0) / 5.0)
	else:
		salao.apagado = 1.0 - entra_sai((t - 19.0) / 2.0)
	# a estática: cresce, cai a 0,35 no escuro, some quando a forja volta
	if t < 4.0:
		_estatica = 0.0
	elif t < 9.0:
		_estatica = entra_sai((t - 4.0) / 5.0)
	elif t < 12.0:
		_estatica = lerpf(1.0, 0.35, entra_sai((t - 9.0) / 3.0))
	elif t < 19.0:
		_estatica = 0.35
	else:
		_estatica = lerpf(0.35, 0.0, clampf((t - 19.0) / 2.0, 0.0, 1.0))
	# o vento e a música que cala
	if t >= 4.0 and not _calou:
		_calou = true
		Som.tocar("vento")
		Musica.calar()
	if t >= 6.5 and not _vento[1]:
		_vento[1] = true
		Som.tocar("vento")
	# cada armadura que acende
	for l in 4:
		if t >= ACENDE[l] and not _acendeu[l]:
			_acendeu[l] = true
			_acender_a_armadura(l)
		var p: ForjaPlayer = jogadores[l]
		if t >= ACENDE[l]:
			p.acender(clampf((t - ACENDE[l]) / ACENDER_S, 0.0, 1.0))
	if t >= 19.0 and not _voltou:
		_voltou = true
		musica_do_titulo_volta.emit()
	if t >= DURACAO:
		acabou = true
	queue_redraw()


func _acender_a_armadura(l: int) -> void:
	Som.tocar("bigorna", null, 0.0, TOM_DO_LUGAR[l])
	# uma martelada na mão do dono, se ele está lá
	if Forja.ocupado(l):
		Forja.sentir(l, "acerto")
	var p: ForjaPlayer = jogadores[l]
	var pouco := Opcoes.reduzido()
	Efeitos.faiscas(salao, p.global_position + Vector3(0, 1.6, 0), Tema.JOGADOR[l], 8 if pouco else 24, 0.8)


## A introdução não tem uma palavra: as placas das salas e o «P1»…«P4» em cima
## dos bonecos somem enquanto ela dura e voltam no fim.
func _texto_do_mundo(visivel: bool) -> void:
	if salao:
		for id in salao.portoes:
			var placa = salao.portoes[id].get("placa")
			if placa is Node3D:
				placa.visible = visivel
	for p in jogadores:
		if p.etiqueta:
			p.etiqueta.visible = visivel


## A câmera da introdução: a bigorna parada até 9 s; depois, em 2 compassos,
## até os quatro pedestais.
func pose_da_camera() -> Array:
	var b := Vector3(0, 0, -1.0)
	if salao and salao.bigorna:
		b = salao.bigorna.global_position
	var bigorna := [b + Vector3(3.2, 2.2, 4.2), b + Vector3(0, 1.2, 0)]
	var pedestais := [Vector3(0, 2.4, 11.0), Vector3(0, 1.0, 4.4)]
	var k := entra_sai((t - 9.0) / (2.0 * COMPASSO_S))
	return [bigorna[0].lerp(pedestais[0], k), bigorna[1].lerp(pedestais[1], k)]


func _draw() -> void:
	if _estatica <= 0.0:
		return
	var densidade := _estatica
	if Opcoes.reduzido():
		densidade = 0.0  # o movimento reduzido: sem estática, só o véu
	elif not Opcoes.flashes:
		densidade *= 0.4
	var rng := RandomNumberGenerator.new()
	rng.seed = int(t * 24.0)
	for i in int(60 * densidade):
		var y := rng.randf() * size.y
		var h := rng.randf_range(2.0, 10.0)
		var cor: Color = Tema.GRAFITE if rng.randf() < 0.5 else Tema.ETIQUETA
		cor.a = rng.randf_range(0.05, 0.25) * densidade
		draw_rect(Rect2(0, y, size.x, h), cor)
	# o véu: a fita por cima, mais escura com a forja apagada
	var escuro := salao.apagado if salao else 0.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.FITA, 0.35 * escuro))
