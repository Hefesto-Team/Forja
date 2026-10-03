extends Node
## O relógio do jogo de ritmo (autoload «Ritmo»): a posição da música que se
## ouve agora e a batida. Ninguém soma delta para saber o tempo da música:
## pergunta aqui (docs/jogo/04-ritmo-e-audio.md#o-relógio-de-áudio).
##
## Com uma faixa tocando, o relógio é a placa de som, como no guia do Godot
## 4.4 "Sync the gameplay with audio and music":
##   posição + AudioServer.get_time_since_last_mix() − latência de saída,
## com a latência lida uma vez por faixa (é cara). Sem faixa tocando (A Voz,
## O Canto, o jogo sem o módulo), o relógio do sistema. Nos dois, o tempo
## nunca anda para trás.
##
## O tempo é medido uma vez por quadro, antes das salas (process_priority), e
## todo mundo naquele quadro lê o mesmo número.

signal batida_cheia(n: int)  ## a cada tempo inteiro (n = 0 é o primeiro tempo da faixa)
signal compasso(n: int)  ## a cada 4 tempos (n = 0 é o primeiro compasso)

var slot := ""  ## a faixa que o relógio segue ("" = nenhuma)
var dono := ""  ## o slot do minigame que segue o relógio (o kit põe; vai no registro)
var bpm := 120.0
var primeiro_tempo := 0.0  ## s, em tempo de música: onde cai o tempo 0

var _tocador: AudioStreamPlayer = null
var _laco_s := 0.0  ## a duração do laço da faixa (0: não é laço)
var _voltas := 0
var _pos_anterior := 0.0
var _latencia := 0.0
var _t := 0.0  ## o t_musica deste quadro (nunca anda para trás)
var _pelo_audio := false
var _base_us := 0  ## o relógio do sistema: no instante _base_us, o t valia _base_t
var _base_t := 0.0
var _pausado := false
var _batida_anterior := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -90  # depois do Forja (-101) e do módulo (-100), antes das salas (0)
	Input.use_accumulated_input = false
	_base_us = Time.get_ticks_usec()


func _process(_dt: float) -> void:
	_t = maxf(_t, _medir())
	var b := int(floor(batida()))
	while _batida_anterior < b:
		_batida_anterior += 1
		if _batida_anterior >= 0:
			batida_cheia.emit(_batida_anterior)
			if _batida_anterior % 4 == 0:
				compasso.emit(int(_batida_anterior / 4.0))


## Começa a seguir a faixa do slot, do zero. O zero é agendado: o som sai no
## próximo mix, mais a latência (o guia do Godot). Slot vazio, ou sem faixa:
## o relógio do sistema, com o mesmo bpm.
func tocar(slot_da_faixa: String, bpm_da_faixa: float, primeiro_tempo_s: float) -> void:
	slot = slot_da_faixa
	bpm = maxf(bpm_da_faixa, 1.0)
	primeiro_tempo = primeiro_tempo_s
	_latencia = AudioServer.get_output_latency()  # cara: uma vez por faixa, nunca por quadro
	_voltas = 0
	_pos_anterior = 0.0
	_pausado = false
	_t = 0.0
	_batida_anterior = -1
	_tocador = Musica.tocar_do_zero(slot)
	_pelo_audio = _tocador != null
	_laco_s = Musica.laco_s(_tocador)
	_base_t = 0.0
	_base_us = Time.get_ticks_usec() + int((AudioServer.get_time_to_next_mix() + _latencia) * 1000000.0)


## Para de seguir a faixa (a música é da Musica: quem para o som é ela). O
## relógio continua pelo sistema, do ponto em que estava.
func parar() -> void:
	slot = ""
	dono = ""
	_tocador = null
	if _pelo_audio:
		_para_o_sistema(Time.get_ticks_usec())


## A pausa (e o diagnóstico) por cima do minigame: o tempo para, e a faixa também.
func pausar(sim: bool) -> void:
	if sim == _pausado:
		return
	_pausado = sim
	if is_instance_valid(_tocador):
		_tocador.stream_paused = sim
	if not sim and not _pelo_audio:
		_base_t = _t
		_base_us = Time.get_ticks_usec()


## A posição da música que se ouve agora, em s (nunca anda para trás).
func t_musica() -> float:
	return _t


## A batida agora: (t_musica − primeiro tempo) × bpm / 60. Negativa antes do primeiro tempo.
func batida() -> float:
	return (_t - primeiro_tempo) * bpm / 60.0


## O t_musica da batida n (n pode ser fracionário: 2,5 é o contratempo do 2).
func t_da_batida(n: float) -> float:
	return primeiro_tempo + n * 60.0 / bpm


## Uma nota nova do lugar, no registro (o tipo `nota` do registro v2).
func registrar_nota(l: int, n: int, t_alvo: float) -> void:
	Forja.evento("nota", l + 1, {"slot": dono, "faixa": slot, "lugar": l, "n": n,
		"t_alvo": snappedf(t_alvo, 0.001), "t_musica": snappedf(_t, 0.001)})


## A posição sem o salto do laço: quando a faixa volta ao começo, soma uma
## volta. Devolve [posição contínua, voltas]. Pura, para a prova.
static func posicao_continua(pos: float, anterior: float, voltas: int, laco_s: float) -> Array:
	if laco_s > 0.0 and pos < anterior - laco_s * 0.5:
		voltas += 1
	return [voltas * laco_s + pos, voltas]


func _medir() -> float:
	if _pausado:
		return _t
	var agora_us := Time.get_ticks_usec()
	if _pelo_audio:
		if is_instance_valid(_tocador) and _tocador.playing:
			var pos := _tocador.get_playback_position() + AudioServer.get_time_since_last_mix()
			var r := posicao_continua(pos, _pos_anterior, _voltas, _laco_s)
			_voltas = int(r[1])
			_pos_anterior = pos
			return float(r[0]) - _latencia
		# a faixa parou (outra entrou, o jingle cortou): segue pelo sistema
		_para_o_sistema(agora_us)
	return _base_t + (agora_us - _base_us) / 1000000.0


func _para_o_sistema(agora_us: int) -> void:
	_pelo_audio = false
	_base_t = _t
	_base_us = agora_us
