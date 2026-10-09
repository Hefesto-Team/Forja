extends Node
## Os sons da forja (autoload «Som»): sintetizados pelo módulo nativo — a
## mesma síntese do núcleo (som/sintese.c), nenhum arquivo de áudio de fora —,
## montados numa AudioStreamWAV na primeira vez e tocados em 3D: cada raia soa
## do seu lado.
##
## Este é o som da TV. O som de cada controle (o alto-falante, a háptica pelos
## atuadores) sai pelo módulo (Forja.som_falante, Forja.som_haptica).
##
## Os efeitos de sabor (o martelo, o golpe, o tiro, o sino, a interface, os
## jingles) são gravações CC0 da Kenney em assets/sons/, várias versões de
## cada, tocadas com um tom levemente sorteado; sem gravação, a síntese. Os
## sons que as salas MEDEM (as notas do Canto, os passos dos Caminhos, o sino
## e o pulso de teste) seguem sintetizados: a assinatura deles é a régua.

## nome -> [receita, parâmetros]
const RECEITAS := {
	"bigorna_aguda": ["bigorna", {"freq": 880.0, "dur": 0.9, "brilho": 0.85, "semente": 3}],
	"bigorna": ["bigorna", {"freq": 440.0, "dur": 1.2, "brilho": 0.6, "semente": 5}],
	"sino": ["bigorna", {"freq": 1318.5, "dur": 2.2, "brilho": 0.9, "semente": 9}],
	"martelo": ["martelada", {"freq": 196.0, "semente": 2}],
	"tique": ["blip", {"freq": 1760.0, "dur": 0.035}],
	"apito": ["tom", {"freq": 2400.0, "dur": 0.45, "rampa": 0.01}],
	"falha": ["tom", {"freq": 150.0, "dur": 0.22, "rampa": 0.02}],
	"confirma": ["acorde", {"freqs": [659.25, 987.77], "espaco": 0.06, "dur_nota": 0.25}],
	"sucesso": ["acorde", {"freqs": [523.25, 659.25, 783.99, 1046.5], "espaco": 0.08, "dur_nota": 0.45}],
	"sopro": ["sopro", {"dur": 0.7, "semente": 4}],
	"vento": ["sopro", {"dur": 1.4, "semente": 8}],
	"carimbo": ["martelada", {"freq": 294.0, "semente": 7}],
	"fogo": ["fogo", {"dur": 4.0, "semente": 6}],
	# os mesmos sons que o módulo toca no controle (som/sons_salas.c): no Canto,
	# o ritmo da TV tem o timbre do ritmo do controle
	"nota": ["bigorna", {"freq": 784.0, "dur": 0.42, "brilho": 1.1, "semente": 23}],
	"nota_alta": ["bigorna", {"freq": 1174.7, "dur": 0.42, "brilho": 1.2, "semente": 29}],
	"grito": ["grito", {"dur": 0.9, "semente": 31}],
}

## O nome que as salas usam -> o nome da gravação em assets/sons/ (<nome>_N.wav).
const GRAVADOS := {
	"martelo": "martelo", "tique": "tique", "confirma": "confirma", "falha": "falha",
	"carimbo": "carimbo", "sucesso": "vitoria_sala", "golpe": "golpe", "escudo": "escudo",
	"tiro": "tiro", "alvo": "alvo", "pedra": "pedra", "sino_viga": "sino", "vazio": "vazio",
	"recarga": "recarga", "ponto": "ponto", "portao": "portao", "transicao": "transicao",
	"especial": "especial", "sobe": "sobe", "placar": "placar", "vitoria_noite": "vitoria_noite",
	"seleciona": "seleciona", "volta": "volta", "passo_salao": "passo",
}

var _streams := {}
var _gravados := {}  ## nome da gravação -> Array[AudioStreamWAV]
var _arquivos := {}  ## id do mapa -> o AudioStreamWAV do arquivo (null: não há)
var _no_controle := {}  ## "nome_k" já registrado no módulo
var _rng := RandomNumberGenerator.new()
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
## As versões gravadas de um efeito (vazio: não há gravação).
func versoes(gravacao: String) -> Array:
	if _gravados.has(gravacao):
		return _gravados[gravacao]
	var lista: Array = []
	for k in 10:
		var caminho := "res://assets/sons/%s_%d.wav" % [gravacao, k]
		if not ResourceLoader.exists(caminho):
			break
		lista.append(load(caminho))
	_gravados[gravacao] = lista
	return lista


## O som de um arquivo pelo id do mapa (assets/sons/<id>.wav), sem tom sorteado: o
## que tem o nome do id é a versão única e aprovada. null: não há arquivo.
func arquivo(nome: String) -> AudioStreamWAV:
	if _arquivos.has(nome):
		return _arquivos[nome]
	var caminho := "res://assets/sons/%s.wav" % nome
	var w: AudioStreamWAV = load(caminho) if ResourceLoader.exists(caminho) else null
	_arquivos[nome] = w
	return w


func tocar(nome: String, pos: Variant = null, volume_db := 0.0, tom := 1.0) -> void:
	var s: AudioStream = arquivo(nome)
	if s == null:
		var lista := versoes(GRAVADOS.get(nome, ""))
		if not lista.is_empty():
			s = lista[_rng.randi() % lista.size()]
			tom *= _rng.randf_range(0.95, 1.05)
		else:
			s = stream(nome)
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
	var s: AudioStream = _arquivo_em_laco(nome)
	if s == null:
		s = stream(nome, true)
	var p := AudioStreamPlayer3D.new()
	p.stream = s
	p.volume_db = volume_db
	p.unit_size = 5.0
	p.autoplay = s != null
	p.position = pos
	pai.add_child(p)
	return p


## O arquivo do id do mapa (assets/sons/<id>.wav) em laço, do primeiro ao último quadro;
## uma cópia, para o `tocar` do mesmo id não herdar o laço. null: não há arquivo.
func _arquivo_em_laco(nome: String) -> AudioStreamWAV:
	var base := arquivo(nome)
	if base == null:
		return null
	var w := base.duplicate() as AudioStreamWAV
	var por_quadro := 2 * (2 if w.stereo else 1)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = w.data.size() / por_quadro
	return w


## O mesmo efeito no alto-falante do controle do lugar (o módulo recebe a
## gravação na primeira vez). Só depois da resposta nas provas às cegas: um
## som no controle não pode entregar o que a mão tem de descobrir.
func no_controle(lugar: int, nome: String, ganho := 0.7) -> void:
	if not Forja.modulo:
		return
	var inteiro := arquivo(nome)
	if inteiro != null:
		if not _no_controle.has(nome):
			_no_controle[nome] = Forja.ctl.som_registrar(nome, inteiro.data, inteiro.mix_rate)
		if _no_controle[nome]:
			Forja.som_falante(lugar, nome, ganho)
		return
	var gravacao: String = GRAVADOS.get(nome, "")
	var lista := versoes(gravacao)
	if lista.is_empty():
		return
	var k := _rng.randi() % lista.size()
	var chave := "%s_%d" % [gravacao, k]
	if not _no_controle.has(chave):
		var w: AudioStreamWAV = lista[k]
		_no_controle[chave] = Forja.ctl.som_registrar(chave, w.data, w.mix_rate)
	if _no_controle[chave]:
		Forja.som_falante(lugar, chave, ganho)


## O pio do cavaleiro do lugar (arte/03): a nota do lugar e o intervalo da
## cabeça, na TV e no alto-falante do dono.
func pio(lugar: int, boneco: int) -> void:
	var i := wrapi(boneco, 0, ForjaPlayer.BONECOS.size())
	var id := "pio_p%d_%s" % [lugar + 1, ForjaPlayer.BONECOS[i].intervalo]
	tocar(id, null, -12.0)
	no_controle(lugar, id, 0.85)
