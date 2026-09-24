class_name MovimentoDoControle
extends Node
## O giro e o acelerômetro de UM DualSense, pelo forja-read (report 0x01).
##
## O Godot 4.4 não expõe sensor de gamepad; o forja-read lê o relatório de
## ENTRADA do USB, que é o que a SDL e a libScePad leem. No rádio ele recusa
## (outro relatório, outro jogo) — e aí quem joga a Viga usa o stick, e a HUD
## diz «stick»: não finge IMU.
##
## CONTRATO.md: player index 0..3, o mesmo do forja-send. Nunca MAC.

@export var player_index: int = 0

## Abaixo disto o giro parado na mesa é viés do sensor, não gesto: sem o
## corte, o boneco giraria sozinho com o controle deitado.
const PARADO_GRAUS_S := 2.0
## Leitura mais velha que isto não é IMU viva.
const VALIDADE_MS := 500

var giro := Vector3.ZERO ## graus/s — pitch, yaw, roll
var acel := Vector3.ZERO ## g
var tem_imu := false
var yaw_acumulado := 0.0 ## graus, desde o ligar()
var motivo := ""

var _pid := -1
var _fio: Thread
var _trava := Mutex.new()
var _correndo := false
var _ultimo_ms := 0


func ligar() -> bool:
	if _correndo:
		return true
	var bin := DualSensePad.bin_irmao("forja-read")
	if bin == "":
		motivo = "forja-read ausente — rode make"
		return false
	var info := OS.execute_with_pipe(bin, PackedStringArray(["--player", str(player_index)]))
	if info.is_empty():
		motivo = "forja-read não abriu"
		return false
	_pid = int(info["pid"])
	yaw_acumulado = 0.0
	_ultimo_ms = 0
	_correndo = true
	_fio = Thread.new()
	_fio.start(_ler.bind(info["stdio"]))
	return true


func desligar() -> void:
	_trava.lock()
	_correndo = false
	_trava.unlock()
	if _pid > 0:
		OS.kill(_pid) ## o PID é o que ESTE nó lançou — nunca por nome
		_pid = -1
	if _fio != null and _fio.is_started():
		_fio.wait_to_finish()
	_fio = null
	tem_imu = false


func _exit_tree() -> void:
	desligar()


func _ler(cano: FileAccess) -> void:
	while true:
		_trava.lock()
		var seguir := _correndo
		_trava.unlock()
		if not seguir:
			break
		var linha := cano.get_line()
		if linha == "" and cano.get_error() != OK:
			break ## o forja-read saiu: recusou o rádio, ou o controle saiu
		var leitura := ler_linha(linha)
		if leitura.is_empty():
			continue
		_trava.lock()
		giro = leitura["giro"]
		acel = leitura["acel"]
		_ultimo_ms = Time.get_ticks_msec()
		_trava.unlock()


## "giro 0.1 -0.3 0.0 graus/s | acel 0.012 -0.998 0.031 g" -> {giro, acel}.
## Função pura: a prova headless a chama.
static func ler_linha(linha: String) -> Dictionary:
	var p := linha.split(" ", false)
	if p.size() < 11 or p[0] != "giro" or p[6] != "acel":
		return {}
	return {
		"giro": Vector3(float(p[1]), float(p[2]), float(p[3])),
		"acel": Vector3(float(p[7]), float(p[8]), float(p[9])),
	}


func _process(dt: float) -> void:
	_trava.lock()
	var g := giro
	var visto := _ultimo_ms
	_trava.unlock()
	tem_imu = visto > 0 and Time.get_ticks_msec() - visto < VALIDADE_MS
	if tem_imu and absf(g.y) >= PARADO_GRAUS_S:
		yaw_acumulado += g.y * dt


## A linha da HUD deste jogador.
func linha_da_hud() -> String:
	if not tem_imu:
		return "stick"
	return "IMU %+.0f°/s · %+.0f° · acel %.2f g" % [giro.y, yaw_acumulado, acel.length()]
