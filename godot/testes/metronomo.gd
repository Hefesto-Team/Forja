extends Node
## O metrônomo do relógio de áudio (ficha H01): a prova que só o ouvido faz.
##
## Toca a trilha d'A Centelha e põe um tique e um clarão em cada tempo inteiro,
## pelo «Ritmo». Se o relógio segue a placa de som, o tique cai no bumbo do
## começo ao fim; se ele soma delta, vai se afastando.
##
##   tools/Godot_v4.4.1-stable_linux.x86_64 --path godot --max-fps 20 res://testes/metronomo.tscn
##   SLOT=MUS_S02_J06 tools/Godot_v4.4.1-stable_linux.x86_64 --path godot res://testes/metronomo.tscn
##   tools/Godot_v4.4.1-stable_linux.x86_64 --path godot --max-fps 60 res://testes/metronomo.tscn
##
## Nos dois, por três minutos. A 20 quadros o clarão treme (é o quadro), mas o
## tique não pode escorregar.

const CLARAO_S := 0.06
const FIM_S := 190.0
const RELATO_S := 10.0

## O slot a conferir: SLOT=MUS_S02_J06 na linha de comando (H05).
var slot := "MUS_S01_J01"
var _clarao: ColorRect = null
var _apaga_em := 0.0
var _proximo_relato := 0.0


func _ready() -> void:
	var pedido := OS.get_environment("SLOT")
	if pedido != "":
		slot = pedido
	var fundo := ColorRect.new()
	fundo.color = Color.BLACK
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	_clarao = ColorRect.new()
	_clarao.color = Color.WHITE
	_clarao.set_anchors_preset(Control.PRESET_FULL_RECT)
	_clarao.modulate.a = 0.0
	add_child(_clarao)

	var m := Musica.mapa(slot)
	print("metrônomo: %s a %.4f bpm (%s), primeiro tempo em %.3f s" % [
		slot, float(m.bpm), "sintetizada" if m.sintetizada else "gerada", float(m.primeiro_tempo)])
	Ritmo.batida_cheia.connect(_no_tempo)
	Ritmo.tocar(slot, float(m.bpm), float(m.primeiro_tempo))


func _no_tempo(_n: int) -> void:
	Som.tocar("tique", null, 0.0)
	_clarao.modulate.a = 1.0
	_apaga_em = Ritmo.t_musica() + CLARAO_S


func _process(_dt: float) -> void:
	var t := Ritmo.t_musica()
	if _clarao.modulate.a > 0.0 and t >= _apaga_em:
		_clarao.modulate.a = 0.0
	if t >= _proximo_relato:
		print("%.1f s: batida %.3f" % [t, Ritmo.batida()])
		_proximo_relato += RELATO_S
	if t >= FIM_S:
		Ritmo.parar()
		get_tree().quit(0)
