extends Node
## A música da TV (autoload «Musica»): synthwave sintetizado pelo módulo — a
## mesma síntese dos sons (som/sintese.c, `sint_trilha`), nenhum arquivo de
## áudio de fora. Uma faixa para o salão (e o título, o lobby, o pódio) e uma
## por sala, cada uma com a sua tônica, o seu andamento e a sua energia.
##
## A música se cala onde a sala pede silêncio: A Voz (o microfone ouve a sala)
## e O Canto (a pergunta é de onde veio o som). Troca com um fade curto.

## id -> [tônica MIDI, bpm, energia]; sem entrada: silêncio
const FAIXAS := {
	"salao": [57, 92, 0],
	"titulo": [60, 115, 1],
	"centelha": [60, 108, 2],
	"viga": [55, 96, 1],
	"molde": [62, 100, 1],
	"impacto": [52, 112, 2],
	"galeria": [59, 104, 1],
	"caminhos": [53, 94, 0],
	"prova": [57, 118, 2],
	"podio": [64, 124, 2],
	"bancada": [],
	"voz": [],
	"canto": [],
}
const VOLUME_DB := -9.0  ## a música fica por baixo dos efeitos
const FADE_S := 0.8

## O slot de uma faixa (MUS_Sxx_Jyy) enquanto as faixas geradas não chegam
## (H05): a trilha sintetizada da seção. S01 é A Centelha ... S09 é A Prova
## (a ordem das seções de docs/jogo/03).
const SALA_DA_SECAO := ["", "centelha", "viga", "molde", "impacto", "galeria", "canto", "caminhos", "voz", "prova"]
const TAXA := 48000  ## a taxa da síntese (SINT_TAXA, nativo/som/sintese.h)

var atual := ""
var _tocadores: Array[AudioStreamPlayer] = []
var _ativo := 0
var _streams := {}
var _tw: Tween = null  ## o fade em curso (um só: o novo mata o velho)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_criar_o_barramento()
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		p.bus = BUS
		add_child(p)
		_tocadores.append(p)


func _stream(id: String) -> AudioStreamWAV:
	if _streams.has(id):
		return _streams[id]
	var wav: AudioStreamWAV = null
	var f: Array = FAIXAS.get(id, [])
	if Forja.modulo and f.size() == 3:
		var pcm: PackedByteArray = Forja.ctl.sintetizar_pcm16("trilha",
			{"tonica": f[0], "bpm": f[1], "energia": f[2], "semente": hash(id) & 0xFFFF})
		if pcm.size() > 0:
			wav = AudioStreamWAV.new()
			wav.format = AudioStreamWAV.FORMAT_16_BITS
			wav.mix_rate = 48000
			wav.stereo = false
			wav.data = pcm
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = pcm.size() / 2
	_streams[id] = wav
	return wav


## Toca a faixa do lugar (o id da sala, a tela, ou "salao"); o mesmo não reinicia.
## A tela sem faixa própria (o título, o lobby, os créditos, o Relâmpago) e o id
## desconhecido tocam a do salão: a gerada, quando existe, senão a sintetizada.
func tocar(id: String) -> void:
	var slot: String = TELAS.get(id, "")
	if (slot == "" or mapa_gerado(slot).is_empty()) and not FAIXAS.has(id):
		id = "salao"
		slot = TELAS.salao
	var gerada := slot != "" and not mapa_gerado(slot).is_empty()
	var chave := slot if gerada else id
	if chave == atual:
		return
	atual = chave
	var velho := _tocadores[_ativo]
	_ativo = 1 - _ativo
	var novo := _tocadores[_ativo]
	if _tw:
		_tw.kill()
	_tw = create_tween().set_parallel(true)
	_tw.tween_property(velho, "volume_db", -80.0, FADE_S)
	var s: AudioStream = _ogg(slot) if gerada else _stream(id)
	if s == null:
		return
	novo.stream = s
	novo.volume_db = -40.0
	novo.play()
	_tw.tween_property(novo, "volume_db", VOLUME_DB, FADE_S)


## Toca a faixa do slot do zero, sem fade de entrada (o Ritmo parte dela);
## devolve o tocador, ou null quando a faixa é silêncio (e aí a música cala).
func tocar_do_zero(slot: String) -> AudioStreamPlayer:
	var id := _id_da_faixa(slot)
	var s: AudioStream = null
	if not mapa_gerado(slot).is_empty():
		s = _ogg(slot)
	elif id != "":
		s = _stream(id)
	if _tw:
		_tw.kill()
	var velho := _tocadores[_ativo]
	_tw = create_tween()
	_tw.tween_property(velho, "volume_db", -80.0, 0.03)
	atual = slot
	if s == null:
		return null
	_ativo = 1 - _ativo
	var novo := _tocadores[_ativo]
	novo.stream = s
	novo.volume_db = VOLUME_DB
	novo.play(0.0)
	return novo


## O mapa de batidas do slot: {bpm, primeiro_tempo, sintetizada}. Da trilha
## sintetizada, o andamento de verdade da síntese; sem faixa, 120. (A H05 lê
## o MUS_*.batidas.json quando a faixa gerada existe.)
func mapa(slot: String) -> Dictionary:
	var gerado := mapa_gerado(slot)
	if not gerado.is_empty():
		return gerado
	var f: Array = FAIXAS.get(_id_da_faixa(slot), [])
	if f.size() == 3:
		return {"bpm": bpm_sintetizado(float(f[1])), "primeiro_tempo": 0.0, "sintetizada": true}
	return {"bpm": 120.0, "primeiro_tempo": 0.0, "sintetizada": false}


## A duração do laço da faixa do tocador, em s (0: sem laço ou sem faixa).
static func laco_s(tocador: AudioStreamPlayer) -> float:
	if tocador != null and tocador.stream is AudioStreamOggVorbis:
		var o := tocador.stream as AudioStreamOggVorbis
		return o.get_length() if o.loop else 0.0
	if tocador == null or not tocador.stream is AudioStreamWAV:
		return 0.0
	var w := tocador.stream as AudioStreamWAV
	if w.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		return 0.0
	return float(w.loop_end - w.loop_begin) / float(w.mix_rate)


## O andamento que a síntese toca de verdade: o tempo vira um número inteiro
## de amostras (sintese.c, `por_tempo = (int)(tempo * SINT_TAXA)`).
static func bpm_sintetizado(bpm: float) -> float:
	var por_tempo := int(60.0 / maxf(bpm, 60.0) * TAXA)
	return 60.0 * TAXA / por_tempo


func _id_da_faixa(slot: String) -> String:
	if FAIXAS.has(slot):
		return slot
	if slot.begins_with("MUS_S") and slot.length() >= 7:
		var s := int(slot.substr(5, 2))
		if s >= 1 and s < SALA_DA_SECAO.size():
			return SALA_DA_SECAO[s]
	return ""


func calar() -> void:
	tocar("voz")


# ---------------------------------------------------------------- as faixas geradas (H05) --

const PASTA := "res://assets/ost"
## As telas e o Relâmpago (docs/jogo/04#as-telas-e-os-jingles): o id que o
## jogo pede à Musica -> o slot da faixa gerada.
const TELAS := {
	"titulo": "MUS_TELA_TITULO", "lobby": "MUS_TELA_CONSTRUCAO", "salao": "MUS_TELA_SALAO",
	"podio": "MUS_TELA_PODIO", "creditos": "MUS_TELA_CREDITOS", "relampago": "MUS_RELAMPAGO",
}

var _mapas := {}  ## slot -> o mapa conferido da faixa gerada ({} = não há)


## O caminho da faixa gerada de um slot, exista ou não:
## MUS_S01_J01 -> res://assets/ost/S01/MUS_S01_J01.ogg; JIN_* em jingles/;
## as telas e o Relâmpago em telas/.
static func caminho(slot: String) -> String:
	if slot.begins_with("MUS_S") and slot.length() >= 8:
		return "%s/%s/%s.ogg" % [PASTA, slot.substr(4, 3), slot]
	if slot.begins_with("JIN_"):
		return "%s/jingles/%s.ogg" % [PASTA, slot]
	return "%s/telas/%s.ogg" % [PASTA, slot]


## Um MUS_*.batidas.json já lido: {bpm, primeiro_tempo, compassos, secoes,
## conferido, sintetizada: false}; {} se o texto não é um mapa. Pura.
static func ler_mapa(texto: String) -> Dictionary:
	var leitor := JSON.new()
	if leitor.parse(texto) != OK or not leitor.data is Dictionary:
		return {}
	var d: Dictionary = leitor.data
	if float(d.get("bpm", 0.0)) <= 0.0 or not d.has("primeiro_tempo_s"):
		return {}
	return {"bpm": float(d.bpm), "primeiro_tempo": float(d.primeiro_tempo_s), "compassos": int(d.get("compassos", 0)),
		"secoes": d.get("secoes", []), "conferido": bool(d.get("conferido", false)), "sintetizada": false,
		"tom": String(d.get("tom", "")), "titulo": String(d.get("titulo", ""))}


## O mapa da faixa gerada do slot, se ela existe e o mapa foi conferido à
## mão; {} se não (e aí toca a sintetizada).
func mapa_gerado(slot: String) -> Dictionary:
	if _mapas.has(slot):
		return _mapas[slot]
	var m := {}
	var ogg := caminho(slot)
	if slot.begins_with("MUS_") and ResourceLoader.exists(ogg):
		var json := ogg.get_basename() + ".batidas.json"
		if not FileAccess.file_exists(json):
			push_warning("%s: a faixa existe e o mapa de batidas não; toca a sintetizada" % slot)
		else:
			m = ler_mapa(FileAccess.get_file_as_string(json))
			if m.is_empty() or not bool(m.conferido):
				push_warning("%s: o mapa de batidas não foi conferido; toca a sintetizada" % slot)
				m = {}
	_mapas[slot] = m
	return m


## A faixa gerada, com o laço do tipo dela: a tela (e o Relâmpago) volta ao
## zero (o Ritmo conta as voltas a partir do 0); a de minigame não volta.
func _ogg(slot: String) -> AudioStreamOggVorbis:
	var s: AudioStreamOggVorbis = load(caminho(slot))
	s.loop = not slot.begins_with("MUS_S")
	s.loop_offset = 0.0
	return s


## A música para em seco (o apito): a zero em 20 ms — nunca de uma vez (as
## rampas do 04) —, e o próximo tocar() começa de novo.
func parar_seco() -> void:
	if _tw:
		_tw.kill()
	var p := _tocadores[_ativo]
	_tocadores[1 - _ativo].stop()
	_tw = create_tween()
	_tw.tween_property(p, "volume_db", -80.0, 0.02)
	_tw.tween_callback(p.stop)
	atual = ""


# ---------------------------------------------------------------- a música que reage (H07) --

const BUS := "Musica"
const ABERTO_HZ := 20000.0
var _bus := -1
var _passa_baixa: AudioEffectLowPassFilter = null
var _tw_reacao: Tween = null


## O barramento da música, com o passa-baixa aberto (chamado no _ready, antes
## dos tocadores). A música manda no Master, onde está o volume da TV.
func _criar_o_barramento() -> void:
	_bus = AudioServer.get_bus_index(BUS)
	if _bus < 0:
		_bus = AudioServer.bus_count
		AudioServer.add_bus(_bus)
		AudioServer.set_bus_name(_bus, BUS)
		AudioServer.set_bus_send(_bus, "Master")
		_passa_baixa = AudioEffectLowPassFilter.new()
		_passa_baixa.cutoff_hz = ABERTO_HZ
		AudioServer.add_bus_effect(_bus, _passa_baixa, 0)
	else:
		_passa_baixa = AudioServer.get_bus_effect(_bus, 0) as AudioEffectLowPassFilter


## A música reage ao jogo (docs/jogo/04#a-música-que-reage): "erro" abafa por
## 300 ms; "perfeito" abaixa 2 dB por 80 ms (o golpe aparece por cima);
## "combo" (oito perfeitos seguidos) sobe 1,5 dB por 2 s.
func reagir(evento: String) -> void:
	if _tw_reacao:
		_tw_reacao.kill()
	_passa_baixa.cutoff_hz = ABERTO_HZ
	_volume(0.0)
	_tw_reacao = create_tween()
	match evento:
		"erro":
			_passa_baixa.cutoff_hz = 600.0
			_tw_reacao.tween_property(_passa_baixa, "cutoff_hz", ABERTO_HZ, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		"perfeito":
			_volume(-2.0)
			_tw_reacao.tween_interval(0.08)
			_tw_reacao.tween_callback(_volume.bind(0.0))
		"combo":
			_volume(1.5)
			_tw_reacao.tween_interval(2.0)
			_tw_reacao.tween_method(_volume, 1.5, 0.0, 0.3)


func _volume(db: float) -> void:
	AudioServer.set_bus_volume_db(_bus, db)
