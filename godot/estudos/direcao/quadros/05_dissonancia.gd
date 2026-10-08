extends Node3D
## Quadro 05 — A Dissonância: a fita enroscou. A sala apaga, a cor escorrega
## (o vermelho para um lado, o azul para o outro), faixas da imagem
## escorregam de lado e a fita sai do cassete em laçadas por cima de tudo.
## Os jogadores continuam acesos (o néon é deles) e o HUD continua legível.
## Nenhuma palavra de erro: o erro é a fita.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Cena := preload("res://estudos/direcao/cena_centelha.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")
const Quadro01 := preload("res://estudos/direcao/quadros/01_centelha.gd")

var espera := 8
var arquivo := "05_dissonancia"
var e
var cabecas: Array = []


func montar(estudo) -> void:
	e = estudo
	Cena.montar(self, e, 1.0)
	# o mundo enrosca forte; o HUD fica por cima, só com a cor escorregando
	# um pouco (ele tem de continuar legível)
	Mundo.pos(self, 8, {"aberracao": 7.0, "rasgo": 0.24, "desbota": 0.3, "semente": 3.0, "varredura": 0.12,
		"vinheta": 0.55, "grao": 0.05})
	Hud.camada(self, _hud, 10)
	Mundo.pos(self, 15, {"aberracao": 2.0, "varredura": 0.06, "vinheta": 0.0, "grao": 0.02})


func _hud(ci: CanvasItem) -> void:
	if cabecas.is_empty():
		for l in 4:
			cabecas.append(e.camera.unproject_position(Cena.cavaleiro_de(l) + Vector3(0, 1.75, 0)))
	Quadro01.desenhar_hud(ci, cabecas, ["1138", "1130", "0772", "1140"], [0, 0, 0, 0], false)
	_fita_enroscada(ci)


## A fita sai da janela do deck e cai em laçadas pela tela (o óxido marrom,
## com o brilho da fita por cima).
func _fita_enroscada(ci: CanvasItem) -> void:
	var inicio := Vector2(1068, 132)
	var pontos := PackedVector2Array()
	var n := 260
	for i in n + 1:
		var t := float(i) / n
		var base := inicio.lerp(Vector2(700, 1160), t) + Vector2(sin(t * TAU) * 220.0, 0)
		var laco := 70.0 + 50.0 * sin(t * 3.0)
		var a := t * TAU * 6.5
		pontos.append(base + Vector2(cos(a) * laco - laco, sin(a) * laco * 0.55))
	ci.draw_polyline(pontos, Color(0, 0, 0, 0.45), 18.0, true)
	ci.draw_polyline(pontos, Color("#3b2a22"), 12.0, true)
	var brilho := PackedVector2Array()
	for p in pontos:
		brilho.append(p + Vector2(-1.5, -2.5))
	ci.draw_polyline(brilho, Color("#7a5640"), 2.5, true)
