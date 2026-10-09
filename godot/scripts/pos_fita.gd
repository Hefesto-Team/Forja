extends Node
## O pós da fita: o desgaste da fita sobre o jogo inteiro, em duas passadas.
## A de baixo (camada 5, entre o 3D e a `Interface`) leva o desgaste, o rasgo e a
## aberração; a de cima (camada 20, por cima de tudo) leva só a varredura e o grão
## e, nos rasgos, uma sombra do que a de baixo faz. O desgaste cresce com a faixa
## da partida (`gastar`); o rasgo só vem na entrada da sala, na volta da pausa e na
## Dissonância (`rasgo_curto`) e nunca sem os Flashes ligados.

const SHADER := preload("res://shaders/pos_fita.gdshader")
const CAMADA_DE_BAIXO := 5
const CAMADA_DE_CIMA := 20
## A passada de cima, fixa: varredura e grão; o rasgo é 1/3 do de baixo e a aberração para em 2,0.
const CIMA := {"varredura": 0.06, "grao": 0.02, "vinheta": 0.0, "desbota": 0.0}
const ABERRACAO_DE_CIMA := 2.0
const RASGO_VALOR := 0.35
const RASGO_ABERRACAO := 2.2
## Quadros do rasgo: sobe, fica, desce.
const RASGO_SUBIDA := 2
const RASGO_PLATO := 2
const RASGO_DESCIDA := 6
const RASGOS_POR_SEGUNDO := 3

var _baixo: ShaderMaterial
var _cima: ShaderMaterial
var _faixa := 1
var _desgaste := {}  ## o que a faixa de agora manda no grão, no desbota, na varredura e na vinheta
var _tweens := {}
var _rasgo_q := -1  ## o quadro do rasgo em curso (-1: nenhum)
var _rasgos: Array[int] = []  ## quando (ms) começaram os últimos rasgos


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_baixo = _passada(CAMADA_DE_BAIXO)
	_cima = _passada(CAMADA_DE_CIMA)
	for k in CIMA:
		_cima.set_shader_parameter(k, CIMA[k])
	_medir()
	get_window().size_changed.connect(_medir)
	gastar(1)


func _passada(camada: int) -> ShaderMaterial:
	var cl := CanvasLayer.new()
	cl.layer = camada
	add_child(cl)
	var r := ColorRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = SHADER
	r.material = m
	cl.add_child(r)
	return m


## O desgaste da faixa `faixa` (1 a 12 na partida; 1 fora dela): o grão, a varredura e a
## vinheta sobem de leve, o desbotar também, cada um até o teto. Virar a fita não zera.
func gastar(faixa: int) -> void:
	_faixa = maxi(1, faixa)
	var k := float(_faixa - 1)
	_desgaste = {
		"grao": minf(0.018 + 0.002 * k, 0.040),
		"desbota": minf(0.01 * k, 0.10),
		"varredura": minf(0.07 + 0.002 * k, 0.09),
		"vinheta": minf(0.38 + 0.003 * k, 0.45),
	}
	for nome in _desgaste:
		if not _tweens.has(nome):
			_por(nome, _desgaste[nome])


func faixa() -> int:
	return _faixa


## O valor de agora de um parâmetro da passada de baixo.
func valor(nome: String) -> float:
	if _baixo == null:
		return 0.0
	var v = _baixo.get_shader_parameter(nome)
	return float(v) if v != null else 0.0


## Leva um parâmetro da passada de baixo ao `valor`, em `ms` (0: de uma vez).
func ajustar(nome: String, valor_: float, ms := 0) -> void:
	if _tweens.has(nome):
		var antigo: Tween = _tweens[nome]
		if antigo and antigo.is_valid():
			antigo.kill()
		_tweens.erase(nome)
	if ms <= 0:
		_por(nome, valor_)
		return
	var tw := create_tween()
	_tweens[nome] = tw
	tw.tween_method(func(v: float): _por(nome, v), valor(nome), valor_, float(ms) / 1000.0)
	tw.finished.connect(func():
		if _tweens.get(nome) == tw:
			_tweens.erase(nome))


## Devolve um parâmetro ao valor do desgaste da faixa (0 no rasgo e na aberração).
func soltar(nome: String, ms := 0) -> void:
	ajustar(nome, float(_desgaste.get(nome, 0.0)), ms)


## O rasgo curto da fita enroscada: sobe em 2 quadros, fica 2, desce em 6; a semente muda a cada 2
## quadros enquanto dura. No máximo 3 por segundo (o quarto é ignorado); sem os Flashes, nenhum.
func rasgo_curto() -> void:
	if not Opcoes.flashes:
		_por("rasgo", 0.0)
		_por("aberracao", 0.0)
		return
	var agora := Time.get_ticks_msec()
	while not _rasgos.is_empty() and agora - _rasgos[0] >= 1000:
		_rasgos.pop_front()
	if _rasgos.size() >= RASGOS_POR_SEGUNDO:
		return
	_rasgos.append(agora)
	_rasgo_q = 0
	_quadro_do_rasgo()


func _process(_dt: float) -> void:
	if _rasgo_q < 0:
		return
	_rasgo_q += 1
	_quadro_do_rasgo()


func _quadro_do_rasgo() -> void:
	if not Opcoes.flashes or _rasgo_q >= RASGO_SUBIDA + RASGO_PLATO + RASGO_DESCIDA:
		_rasgo_q = -1
		_por("rasgo", 0.0)
		_por("aberracao", 0.0)
		return
	var k := 1.0
	if _rasgo_q < RASGO_SUBIDA:
		k = float(_rasgo_q + 1) / float(RASGO_SUBIDA)
	elif _rasgo_q >= RASGO_SUBIDA + RASGO_PLATO:
		k = 1.0 - float(_rasgo_q - RASGO_SUBIDA - RASGO_PLATO + 1) / float(RASGO_DESCIDA + 1)
	if _rasgo_q % 2 == 0:
		_por("semente", randf() * 100.0)
	_por("rasgo", RASGO_VALOR * k)
	_por("aberracao", RASGO_ABERRACAO * k)


## Escreve um parâmetro na passada de baixo e o que ele vale na de cima. Sem os Flashes, o rasgo e a
## aberração ficam em 0.
func _por(nome: String, v: float) -> void:
	if nome in ["rasgo", "aberracao"] and not Opcoes.flashes:
		v = 0.0
	_baixo.set_shader_parameter(nome, v)
	match nome:
		"rasgo":
			_cima.set_shader_parameter("rasgo", v / 3.0)
		"aberracao":
			_cima.set_shader_parameter("aberracao", minf(v, ABERRACAO_DE_CIMA))
		"semente":
			_cima.set_shader_parameter("semente", v)


## O tamanho da tela em pixels, que o grão e a varredura medem.
func _medir() -> void:
	var t := Vector2(get_window().size)
	if t.x < 1.0 or t.y < 1.0:
		return
	_baixo.set_shader_parameter("tamanho", t)
	_cima.set_shader_parameter("tamanho", t)
