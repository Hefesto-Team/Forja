extends Node3D
## Quadro 01 — A Centelha depois: a mesma câmera da foto de hoje
## (docs/imagens/centelha.jpg), com a fita.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Cena := preload("res://estudos/direcao/cena_centelha.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")

var espera := 8
var arquivo := "01_centelha_depois"
var e
var pes: Array[Vector2] = []
const NOMES := ["Basalto", "Obsidiana", "Latão", "Faísca"]  ## os da montagem (10): a mesma noite em todos os quadros
const PONTOS := ["1138", "1130", "0772", "1140"]
const COMBO := [9, 6, 2, 12]


func montar(estudo) -> void:
	e = estudo
	Cena.montar(self, e)
	Mundo.pos(self, 5)
	Hud.camada(self, _hud)


func _hud(ci: CanvasItem) -> void:
	if pes.is_empty():
		for l in 4:
			pes.append(e.camera.unproject_position(Cena.cavaleiro_de(l) + Vector3(0, 1.75, 0)))
	desenhar_hud(ci, pes, PONTOS, COMBO)


static func desenhar_hud(ci: CanvasItem, cabecas: Array, pontos: Array, combo: Array, julgar := true) -> void:
	# no alto, no meio: a etiqueta da faixa que está tocando e o deck (os
	# carretéis andam com o tempo, o contador diz quanto falta)
	Hud.etiqueta(ci, Rect2(548, 48, 430, 136), "A Centelha", "LADO A  ·  FAIXA 01", Fita.SECAO[0], 52, -0.012)
	Hud.deck(ci, Rect2(996, 58, 376, 116), 0.22, 0.85, "096")
	# Nenhuma frase de instrução na fase de jogo (diversão, item 3): o jogo ensina sem texto.
	for l in 4:
		Hud.cartao(ci, l, NOMES[l], pontos[l], combo[l], 13 if l == 3 else -1)
	if julgar:
		Hud.julgamento(ci, cabecas[3] + Vector2(10, -20), "Ressonância!", Fita.JOGADOR[3])
		Hud.julgamento(ci, cabecas[1] + Vector2(0, -20), "Afinado", Fita.JOGADOR[1], 38, 0.05)
