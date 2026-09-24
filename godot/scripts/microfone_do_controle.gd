class_name MicrofoneDoControle
extends Node
## O nível do microfone na HUD. Pede o microfone PADRÃO do sistema — é assim
## que um jogo pede, e é por isso que a prova vale com qualquer máscara no
## controle: quem elege o microfone padrão é o sistema, e é esse fio que o jogo
## usa.
##
## SÓ OUVE QUANDO LIGADO (o modo Voz). Um jogo que abre o microfone ao nascer
## deixa a luz do microfone acesa a partida inteira, e ninguém sabe por quê.
##
## Requer, no project.godot: audio/driver/enable_input = true

signal nivel(db: float)
signal sem_entrada(motivo: String)

const BUS := "MicDoControle"
## O piso da barra. Silêncio de verdade (o botão de mudo apertado) é zero
## absoluto nas amostras, e vira este número — a barra CAI, em vez de parar
## onde estava.
const SILENCIO_DB := -80.0

var ligado := false
var ultimo_db := SILENCIO_DB
var _captura: AudioEffectCapture
var _tocador: AudioStreamPlayer


func _ready() -> void:
	var idx := AudioServer.get_bus_index(BUS)
	if idx < 0:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, BUS)
	## O bus é MUDO de propósito: sem isto o microfone do controle volta pelo
	## alto-falante do controle e realimenta — a microfonia que estraga o gesto.
	AudioServer.set_bus_mute(idx, true)
	_captura = AudioEffectCapture.new()
	AudioServer.add_bus_effect(idx, _captura)
	_tocador = AudioStreamPlayer.new()
	_tocador.stream = AudioStreamMicrophone.new()
	_tocador.bus = BUS
	add_child(_tocador)


func ligar() -> bool:
	if not ProjectSettings.get_setting("audio/driver/enable_input", false):
		sem_entrada.emit("o jogo nasceu sem entrada de áudio (audio/driver/enable_input)")
		return false
	usar_o_padrao()
	_captura.clear_buffer()
	_tocador.play()
	ligado = true
	return true


func desligar() -> void:
	_tocador.stop()
	ligado = false
	ultimo_db = SILENCIO_DB


## "Default" é a resposta CERTA, não a preguiçosa: quem elege a fonte padrão é
## o sistema, e é exatamente esse fio que o jogo usa.
func usar_o_padrao() -> void:
	AudioServer.input_device = "Default"


## E o outro lado, para o gesto de contraste: apontar nominalmente.
func dispositivos() -> PackedStringArray:
	return AudioServer.get_input_device_list()


func _process(_dt: float) -> void:
	if not ligado or _captura == null:
		return
	var n := _captura.get_frames_available()
	if n <= 0:
		return
	ultimo_db = nivel_de(_captura.get_buffer(n))
	nivel.emit(ultimo_db)


## O pico de um bloco, em dB. Função pura: a prova headless a chama.
static func nivel_de(quadros: PackedVector2Array) -> float:
	var pico := 0.0
	for q in quadros:
		pico = maxf(pico, maxf(absf(q.x), absf(q.y)))
	if pico <= 0.0:
		return SILENCIO_DB
	return maxf(linear_to_db(pico), SILENCIO_DB)


## A barra da HUD: 20 casas de -60 dB a 0 dB.
static func barra(db: float) -> String:
	var cheias := clampi(int(round((db + 60.0) / 3.0)), 0, 20)
	return "▮".repeat(cheias) + "▯".repeat(20 - cheias)
