class_name Sala
extends Node3D
## Uma sala: um jogo curto que usa uma feature do DualSense do jeito que os
## jogos comerciais usam. A sala monta a arena dela, põe os jogadores, manda as
## saídas pelo lugar (0..3) e devolve os lugares ao repouso quando sai.

signal terminou

## A seção de cada sala na noite (arte/01, a luz das cinco tintas): a tinta e a luz saem do número.
const SECAO_DE := {
	"centelha": 1, "viga": 2, "molde": 3, "impacto": 4, "galeria": 5,
	"canto": 6, "caminhos": 7, "voz": 8, "prova": 9,
}

var id := ""
var nome := ""
var acao := ""
var jogadores: Array = []  ## os ForjaPlayer dos lugares ocupados
var camera_pos := Vector3(0, 13, 13)
var camera_olhar := Vector3.ZERO
## O tremor da câmera agora (0: parada), para o susto e os golpes grandes.
var tremor := 0.0
## Como a câmera filma (G05): "fixa", "dupla", "grupo" ou "corrida"; a lente em mm (0: a do modo); a distância
## mínima e a máxima, em m (grupo e corrida); para onde se corre e o quanto quem fica para trás pode se afastar do
## líder (corrida); onde está a ação agora (dupla; ZERO: nenhuma).
var camera_modo := "fixa"
var camera_lente := 0.0
var camera_distancia := Vector2(9.0, 18.0)
var camera_frente := Vector3(0, 0, -1)
var camera_alcance := 14.0
var camera_foco := Vector3.ZERO
## A amplitude do tremor do evento agora, em m (cai em linha reta até 0).
var abalo := 0.0
var _abalo_ini := 0.0
var _abalo_dura := 0.0  ## s

const LENTE_DO_MODO := {"fixa": 35.0, "dupla": 50.0, "grupo": 35.0, "corrida": 28.0}
const TREMOR_GOLPE := 0.02  ## 1 batida
const TREMOR_ESTRONDO := 0.05  ## 2 batidas
const TREMOR_EXPLOSAO := 0.05  ## o nome que as fichas de minigame já usam: o estrondo
const TREMOR_CATASTROFE := 0.08  ## 4 batidas
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
	if abalo > 0.0:
		abalo = maxf(0.0, abalo - _abalo_ini * dt / maxf(_abalo_dura, 0.001))


## A lente desta sala agora, em mm (24 a 100).
func lente() -> float:
	return clampf(camera_lente if camera_lente > 0.0 else float(LENTE_DO_MODO.get(camera_modo, 35.0)), 24.0, 100.0)


## As posições que a câmera enquadra: os bonecos visíveis (a sala troca por «só os que estão na partida»).
func alvos_da_camera() -> Array:
	var alvos: Array = []
	for p in jogadores:
		if p.visible:
			alvos.append(p.global_position)
	return alvos


## O tremor do evento: amplitude em m; o degrau sai dela (até 0,02 golpe, até 0,05 estrondo, senão catástrofe).
## Um tremor novo só substitui o vivo se a amplitude dele é maior ou igual ao `abalo` de agora.
func tremer(amplitude: float) -> void:
	var a := clampf(amplitude, 0.0, TREMOR_CATASTROFE)
	if a <= 0.0 or a < abalo:
		return
	var batidas := 1.0 if a <= TREMOR_GOLPE else (2.0 if a <= TREMOR_ESTRONDO else 4.0)
	_abalo_ini = a
	_abalo_dura = batidas * 60.0 / maxf(1.0, Ritmo.bpm if Ritmo.bpm > 0.0 else 120.0)
	abalo = a


## Corrida: a borda empurra, não mata. Quem ficou mais de `camera_alcance` atrás do líder volta para a borda.
func puxar_os_de_tras() -> void:
	var visiveis: Array = []
	var posicoes: Array = []
	for p in jogadores:
		if p.visible:
			visiveis.append(p)
			posicoes.append(p.global_position)
	if visiveis.size() < 2:
		return
	var novas := Enquadramento.puxar(posicoes, camera_frente, camera_alcance)
	for i in visiveis.size():
		if novas[i] != posicoes[i]:
			visiveis[i].global_position = novas[i]


func jogador(lugar: int) -> ForjaPlayer:
	for p in jogadores:
		if p.lugar == lugar:
			return p
	return null


## O número da seção desta sala (1 a 9); 0 para a que não é da noite (a bancada), na tinta do pódio.
func numero() -> int:
	return int(SECAO_DE.get(id, 0))


## A luz da sala: tochas na chave da seção e um enchimento no preenchimento dela. `acender` as põe na luz da seção
## quando a sala entra (o main) e quando a noite vira (o lado B).
func luzes(tochas: Array) -> void:
	for pos in tochas:
		var l := OmniLight3D.new()
		l.position = pos
		l.omni_range = 9.0
		add_child(l)
		na_chave(l, true)
	var cima := OmniLight3D.new()
	cima.position = Vector3(0, 9, 2)
	cima.light_energy = 0.55
	cima.omni_range = 22.0
	add_child(cima)
	enchimento(cima)


var _chaves: Array[Light3D] = []  ## as luzes de chave (tochas, fogo): a cor da seção, e a energia se `com_energia`
var _chaves_com_energia: Array[Light3D] = []
var _enchimentos: Array[Light3D] = []  ## as luzes de preenchimento: a cor da seção


## Faz desta luz uma chave da seção: a cor `chave` agora e a cada `acender`; `com_energia`: a energia também.
func na_chave(l: Light3D, com_energia := false) -> Light3D:
	_chaves.append(l)
	if com_energia:
		_chaves_com_energia.append(l)
	var luz := Tema.luz_da_secao(numero())
	l.light_color = luz.chave
	if com_energia:
		l.light_energy = luz.energia_chave
	return l


## Faz desta luz um preenchimento da seção: a cor `preenchimento` agora e a cada `acender`.
func enchimento(l: Light3D) -> Light3D:
	_enchimentos.append(l)
	l.light_color = Tema.luz_da_secao(numero()).preenchimento
	return l


## Põe a luz da seção (`Tema.luz_da_secao`) nas luzes da sala: a chave nas tochas, o preenchimento no resto.
func acender(luz: Dictionary) -> void:
	for l in _chaves:
		if is_instance_valid(l):
			l.light_color = luz.chave
			if _chaves_com_energia.has(l):
				l.light_energy = luz.energia_chave
	for l in _enchimentos:
		if is_instance_valid(l):
			l.light_color = luz.preenchimento
