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
	"centelha": [60, 108, 2],
	"viga": [55, 96, 1],
	"molde": [62, 100, 1],
	"impacto": [52, 112, 2],
	"galeria": [59, 104, 1],
	"caminhos": [53, 94, 0],
	"prova": [57, 118, 2],
	"bancada": [],
	"voz": [],
	"canto": [],
}
const VOLUME_DB := -9.0  ## a música fica por baixo dos efeitos
const FADE_S := 0.8

var atual := ""
var _tocadores: Array[AudioStreamPlayer] = []
var _ativo := 0
var _streams := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
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


## Toca a faixa do lugar (o id da sala, ou "salao"); o mesmo id não reinicia.
func tocar(id: String) -> void:
	if not FAIXAS.has(id):
		id = "salao"
	if id == atual:
		return
	atual = id
	var velho := _tocadores[_ativo]
	_ativo = 1 - _ativo
	var novo := _tocadores[_ativo]
	var tw := create_tween().set_parallel(true)
	tw.tween_property(velho, "volume_db", -80.0, FADE_S)
	var s := _stream(id)
	if s == null:
		return
	novo.stream = s
	novo.volume_db = -40.0
	novo.play()
	tw.tween_property(novo, "volume_db", VOLUME_DB, FADE_S)


func calar() -> void:
	tocar("voz")
