extends Node
## Os sons da forja (autoload «Som»): sintetizados pelo módulo nativo — a
## mesma síntese do núcleo (som/sintese.c), nenhum arquivo de áudio de fora —,
## montados numa AudioStreamWAV na primeira vez e tocados em 3D: cada raia soa
## do seu lado.
##
## Este é o som da TV. O som de cada controle (o alto-falante, a háptica pelos
## atuadores) chega no marco do áudio.

## nome -> [receita, parâmetros]
const RECEITAS := {
	"bigorna_aguda": ["bigorna", {"freq": 880.0, "dur": 0.9, "brilho": 0.85, "semente": 3}],
	"bigorna": ["bigorna", {"freq": 440.0, "dur": 1.2, "brilho": 0.6, "semente": 5}],
	"sino": ["bigorna", {"freq": 1318.5, "dur": 2.2, "brilho": 0.9, "semente": 9}],
	"martelo": ["martelada", {"freq": 196.0, "semente": 2}],
	"tique": ["blip", {"freq": 1760.0, "dur": 0.035}],
	"falha": ["tom", {"freq": 150.0, "dur": 0.22, "rampa": 0.02}],
	"confirma": ["acorde", {"freqs": [659.25, 987.77], "espaco": 0.06, "dur_nota": 0.25}],
	"sucesso": ["acorde", {"freqs": [523.25, 659.25, 783.99, 1046.5], "espaco": 0.08, "dur_nota": 0.45}],
	"sopro": ["sopro", {"dur": 0.7, "semente": 4}],
	"vento": ["sopro", {"dur": 1.4, "semente": 8}],
	"carimbo": ["martelada", {"freq": 294.0, "semente": 7}],
	"fogo": ["fogo", {"dur": 4.0, "semente": 6}],
}

var _streams := {}
var _players: Array[AudioStreamPlayer3D] = []
var _players_2d: Array[AudioStreamPlayer] = []
var _proximo := 0


func _ready() -> void:
	for i in 16:
		var p := AudioStreamPlayer3D.new()
		p.unit_size = 6.0
		p.max_db = 3.0
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(p)
		_players.append(p)
	for i in 4:
		var q := AudioStreamPlayer.new()
		add_child(q)
		_players_2d.append(q)


## A AudioStreamWAV de um som, montada uma vez.
func stream(nome: String, laco := false) -> AudioStreamWAV:
	var chave := nome + ("@laco" if laco else "")
	if _streams.has(chave):
		return _streams[chave]
	var wav: AudioStreamWAV = null
	if Forja.modulo and RECEITAS.has(nome):
		var r: Array = RECEITAS[nome]
		var pcm: PackedByteArray = Forja.ctl.sintetizar_pcm16(r[0], r[1])
		if pcm.size() > 0:
			wav = AudioStreamWAV.new()
			wav.format = AudioStreamWAV.FORMAT_16_BITS
			wav.mix_rate = 48000
			wav.stereo = false
			wav.data = pcm
			if laco:
				wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
				wav.loop_begin = 0
				wav.loop_end = pcm.size() / 2
	_streams[chave] = wav
	return wav


## Toca um som: em `pos` (3D, do lado da raia) ou sem posição (a tela toda).
func tocar(nome: String, pos: Variant = null, volume_db := 0.0, tom := 1.0) -> void:
	var s := stream(nome)
	if s == null:
		return
	if pos is Vector3:
		var p := _players[_proximo]
		_proximo = (_proximo + 1) % _players.size()
		p.global_position = pos
		p.stream = s
		p.volume_db = volume_db
		p.pitch_scale = tom
		p.play()
	else:
		for q in _players_2d:
			if not q.playing:
				q.stream = s
				q.volume_db = volume_db
				q.pitch_scale = tom
				q.play()
				return


## Um som em laço preso num lugar do mundo (o fogo da forja).
func laco(nome: String, pai: Node3D, pos: Vector3, volume_db := -8.0) -> AudioStreamPlayer3D:
	var s := stream(nome, true)
	var p := AudioStreamPlayer3D.new()
	p.stream = s
	p.volume_db = volume_db
	p.unit_size = 5.0
	p.autoplay = s != null
	p.position = pos
	pai.add_child(p)
	return p
