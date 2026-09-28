class_name Sala
extends Node3D
## Uma sala: um jogo curto que usa uma feature do DualSense do jeito que os
## jogos comerciais usam. A sala monta a arena dela, põe os jogadores, manda as
## saídas pelo lugar (0..3) e devolve os lugares ao repouso quando sai.

signal terminou

var id := ""
var nome := ""
var acao := ""
var jogadores: Array = []  ## os ForjaPlayer dos lugares ocupados
var camera_pos := Vector3(0, 13, 13)
var camera_olhar := Vector3.ZERO
## O tremor da câmera agora (0: parada), para o susto e os golpes grandes.
var tremor := 0.0
## false: a sala desenha o próprio painel no lugar do HUD do jogo (a bancada).
var com_hud := true
var t := 0.0


## Chamado uma vez, antes de a sala aparecer.
func entrar(js: Array) -> void:
	jogadores = js
	Forja.em_sala(true)
	Forja.evento("sala", 0, {"sala": id, "evento": "entrou"})
	Forja.registrar("entrou em %s" % nome)
	montar()


## Chamado quando a sala some: os controles voltam ao repouso do lugar.
func sair() -> void:
	Forja.em_sala(false)
	for p in jogadores:
		Forja.silencio(p.lugar)
	Forja.evento("sala", 0, {"sala": id, "evento": "saiu"})


func montar() -> void:
	pass


## Uma linha por lugar, para a HUD (vida, pontos, o que falta).
func status(_lugar: int) -> String:
	return ""


func _process(dt: float) -> void:
	t += dt


func jogador(lugar: int) -> ForjaPlayer:
	for p in jogadores:
		if p.lugar == lugar:
			return p
	return null


## A luz da sala: tochas quentes e um enchimento lilás, como o salão.
func luzes(tochas: Array) -> void:
	for pos in tochas:
		var l := OmniLight3D.new()
		l.position = pos
		l.light_color = Color("#ffb070")
		l.light_energy = 1.8
		l.omni_range = 9.0
		add_child(l)
	var cima := OmniLight3D.new()
	cima.position = Vector3(0, 9, 2)
	cima.light_color = Color("#b9b0ff")
	cima.light_energy = 0.55
	cima.omni_range = 22.0
	add_child(cima)
