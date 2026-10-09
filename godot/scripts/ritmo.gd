extends Node

signal batida_cheia(n: int)
signal compasso(n: int)

var slot := ""
var dono := ""
var bpm := 120.0
var primeiro_tempo := 0.0

var _tocador: AudioStreamPlayer = null
var _laco_s := 0.0
var _voltas := 0
var _pos_anterior := 0.0
var _latencia := 0.0
var _t := 0.0
var _pelo_audio := false
var _base_us := 0
var _base_t := 0.0
var _pausado := false
var _batida_anterior := -1
var _no_jogo := false
var pelo_relogio_de_verdade := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -90
	Input.use_accumulated_input = false
	_base_us = _agora_us()
	ler_das_opcoes()


func ler_das_opcoes() -> void:
	for l in 4:
		desvio[l] = int(Opcoes.tempo_ms[l]) / 1000.0


func _process(_dt: float) -> void:
	_t = maxf(_t, _medir())
	if _calada_ate >= 0.0 and batida() >= _calada_ate:
		_calada_ate = -1.0
		_rampa(Musica.VOLUME_DB)
	var b := int(floor(batida()))
	while _batida_anterior < b:
		_batida_anterior += 1
		if _batida_anterior >= 0:
			batida_cheia.emit(_batida_anterior)
			if _batida_anterior % 4 == 0:
				compasso.emit(int(_batida_anterior / 4.0))


func tocar(slot_da_faixa: String, bpm_da_faixa: float, primeiro_tempo_s: float) -> void:
	_calada_ate = -1.0
	if _tw_calar:
		_tw_calar.kill()
	slot = slot_da_faixa
	bpm = maxf(bpm_da_faixa, 1.0)
	primeiro_tempo = primeiro_tempo_s
	_latencia = AudioServer.get_output_latency()
	_voltas = 0
	_pos_anterior = 0.0
	_pausado = false
	_t = 0.0
	_batida_anterior = -1
	_tocador = Musica.tocar_do_zero(slot)
	_pelo_audio = _tocador != null
	_laco_s = Musica.laco_s(_tocador)
	_base_t = 0.0
	_base_us = _agora_us() + int((AudioServer.get_time_to_next_mix() + _latencia) * 1000000.0)


func parar() -> void:
	_calada_ate = -1.0
	if _tw_calar:
		_tw_calar.kill()
	slot = ""
	dono = ""
	_tocador = null
	if _pelo_audio:
		_para_o_sistema(_agora_us())


func pausar(sim: bool) -> void:
	if sim == _pausado:
		return
	_pausado = sim
	if is_instance_valid(_tocador):
		_tocador.stream_paused = sim
	if not sim and (not _pelo_audio or _no_jogo):
		_base_t = _t
		_base_us = _agora_us()


func t_musica() -> float:
	return _t


func batida() -> float:
	return (_t - primeiro_tempo) * bpm / 60.0


func t_da_batida(n: float) -> float:
	return primeiro_tempo + n * 60.0 / bpm


func registrar_nota(l: int, n: int, t_alvo: float) -> void:
	Forja.evento("nota", l + 1, {"slot": dono, "faixa": slot, "lugar": l, "n": n,
		"t_alvo": snappedf(t_alvo, 0.001), "t_musica": snappedf(_t, 0.001)})


static func posicao_continua(pos: float, anterior: float, voltas: int, laco_s: float) -> Array:
	if laco_s > 0.0 and pos < anterior - laco_s * 0.5:
		voltas += 1
	return [voltas * laco_s + pos, voltas]


func _medir() -> float:
	if _pausado:
		return _t
	var agora_us := _agora_us()
	if _pelo_audio and not _no_jogo:
		if is_instance_valid(_tocador) and _tocador.playing:
			var pos := _tocador.get_playback_position() + AudioServer.get_time_since_last_mix()
			var r := posicao_continua(pos, _pos_anterior, _voltas, _laco_s)
			_voltas = int(r[1])
			_pos_anterior = pos
			return float(r[0]) - _latencia
		_para_o_sistema(agora_us)
	return _base_t + (agora_us - _base_us) / 1000000.0


func _agora_us() -> int:
	var no_jogo := Forja.acelerada() and not pelo_relogio_de_verdade
	var agora := Forja.agora_us() if no_jogo else Time.get_ticks_usec()
	if no_jogo != _no_jogo:
		_no_jogo = no_jogo
		_base_t = _t
		_base_us = agora
	return agora


func _para_o_sistema(agora_us: int) -> void:
	_pelo_audio = false
	_base_t = _t
	_base_us = agora_us


enum { ERRO, BOM, OTIMO, PERFEITO }
const JANELA_PERFEITO := Vector2(-0.040, 0.060)
const JANELA_OTIMO := 0.090
const JANELA_BOM := 0.140
const NOMES_DO_JULGAMENTO := ["erro", "bom", "otimo", "perfeito"]
const FOLGA_DO_ULTIMO := 0.040
const ERROS_PARA_SIMPLIFICAR := 3
const ACERTOS_PARA_VOLTAR := 4

var desvio := [0.0, 0.0, 0.0, 0.0]
var simples := [false, false, false, false]
var _erros_seguidos := [0, 0, 0, 0]
var _acertos_seguidos := [0, 0, 0, 0]


func julgar(l: int, t_toque: float, t_alvo: float, folga_bom := 0.0) -> int:
	var d := desvio_ms(l, t_toque, t_alvo)
	if d >= _ms(JANELA_PERFEITO.x) and d <= _ms(JANELA_PERFEITO.y):
		return PERFEITO
	if absf(d) <= _ms(JANELA_OTIMO):
		return OTIMO
	if absf(d) <= _ms(JANELA_BOM + maxf(folga_bom, 0.0)):
		return BOM
	return ERRO


func desvio_ms(l: int, t_toque: float, t_alvo: float) -> float:
	return _ms(t_toque - float(desvio[clampi(l, 0, 3)]) - t_alvo)


static func folga_para(l: int, pontos: Array, presentes: Array) -> float:
	if presentes.size() < 2 or not l in presentes:
		return 0.0
	for o in presentes:
		if o != l and int(pontos[o]) <= int(pontos[l]):
			return 0.0
	return FOLGA_DO_ULTIMO


func contar_para_ajuda(l: int, j: int) -> void:
	if j == ERRO:
		_erros_seguidos[l] += 1
		_acertos_seguidos[l] = 0
		if _erros_seguidos[l] >= ERROS_PARA_SIMPLIFICAR:
			simples[l] = true
	else:
		_acertos_seguidos[l] += 1
		_erros_seguidos[l] = 0
		if simples[l] and _acertos_seguidos[l] >= ACERTOS_PARA_VOLTAR:
			simples[l] = false


func definir_desvio(l: int, segundos: float, origem: String, amostras := 0) -> void:
	l = clampi(l, 0, 3)
	var ms := clampi(roundi(segundos * 1000.0), Opcoes.TEMPO_MIN, Opcoes.TEMPO_MAX)
	desvio[l] = ms / 1000.0
	Opcoes.tempo_ms[l] = ms
	var p := Forja.pad_do_lugar(l)
	var transporte := str(Forja.pad(p).get("conexao_curta", "")).to_lower() if p >= 0 else ""
	Forja.evento("calibracao", l + 1, {"lugar": l, "desvio_ms": ms, "amostras": amostras, "origem": origem,
		"transporte": transporte})


func zerar_ajuda() -> void:
	simples = [false, false, false, false]
	_erros_seguidos = [0, 0, 0, 0]
	_acertos_seguidos = [0, 0, 0, 0]


func registrar_toque(l: int, n: int, j: int, desvio_em_ms := NAN) -> void:
	var campos := {"slot": dono, "faixa": slot, "lugar": l, "n": n, "julgamento": NOMES_DO_JULGAMENTO[j],
		"t_musica": snappedf(_t, 0.001)}
	if is_nan(desvio_em_ms):
		campos["perdida"] = true
	else:
		campos["desvio_ms"] = desvio_em_ms
	Forja.evento("toque", l + 1, campos)


static func _ms(s: float) -> float:
	return roundf(s * 10000.0) / 10.0


var _calada_ate := -1.0
var _tw_calar: Tween = null


func calar(batidas: float) -> void:
	if not is_instance_valid(_tocador) or batidas <= 0.0:
		return
	_calada_ate = batida() + batidas
	_rampa(-80.0)


func calada() -> bool:
	return _calada_ate >= 0.0


func _rampa(db: float) -> void:
	if _tw_calar:
		_tw_calar.kill()
	if not is_instance_valid(_tocador):
		return
	_tw_calar = create_tween()
	_tw_calar.tween_property(_tocador, "volume_db", db, 0.02)
