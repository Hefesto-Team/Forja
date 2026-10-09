extends Node3D
## Quadro 12 — A prancha das reações (09; PRODUCAO, item 3): os oito
## adesivos nas quatro cores a 112 px sobre o casco, uma linha deles a 144 px
## sobre a arena da Centelha, a roda de 240 px aberta num cartão e os seis
## carimbos do jogo no tamanho da tela. Tudo desenhado por reacoes.gd.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Prancha := preload("res://estudos/direcao/prancha.gd")
const Cena := preload("res://estudos/direcao/cena_centelha.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")
const Reacoes := preload("res://estudos/direcao/reacoes.gd")

var espera := 10
var arquivo := "12_reacoes"
var folha: SubViewport
const LARGURA := 1920
const ALTURA := 1960
## A grade dos 32: uma linha por dono, uma coluna por adesivo.
const GRADE_X := 196.0
const GRADE_Y := 266.0
const PASSO_X := 146.0
const PASSO_Y := 130.0
## A faixa da arena: a câmera da Centelha, o meio da tela de 1080 cortado.
const ARENA := Rect2(0, 860, 1920, 600)
## Os carimbos: duas linhas.
const CARIMBO_Y := [1580.0, 1810.0]
const DIRECOES := ["↑", "↗", "→", "↘", "↓", "↙", "←", "↖"]


## O estudo pede olhar(); a célula da arena responde pela câmera dela.
class Olho:
	var cam: Camera3D
	func olhar(pos: Vector3, alvo: Vector3, fov: float) -> void:
		cam.position = pos
		cam.look_at(alvo)
		# a faixa é o meio da tela: o fov vertical encolhe na mesma razão
		cam.fov = rad_to_deg(2.0 * atan(tan(deg_to_rad(fov * 0.5)) * ARENA.size.y / 1080.0))


func montar(_estudo) -> void:
	folha = Prancha.folha(self, Vector2i(LARGURA, ALTURA), Fita.FITA)
	var vp := Prancha.celula(self, Vector2i(ARENA.size), false)
	var raiz := Node3D.new()
	vp.add_child(raiz)
	var olho := Olho.new()
	olho.cam = Prancha.camera(vp)
	Cena.montar(raiz, olho)
	Mundo.pos(vp, 5, {"grao": 0.02})
	Prancha.pregar(folha, vp, ARENA)
	Prancha.por_cima(folha, _desenho)


func foto() -> Image:
	return await Prancha.foto(folha)


func _desenho(ci: CanvasItem) -> void:
	Hud.etiqueta(ci, Rect2(56, 28, 640, 140), "As reações", "PRANCHA  ·  ITEM 3", Fita.SECAO[1], 56, -0.01)
	Hud.texto(ci, Fita.archivo(500), 30, Vector2(760, 44), "O adesivo é do jogador: papel recortado, a cor do dono, as lâmpadas dele no canto.", Color(Fita.ETIQUETA, 0.85))
	Hud.texto(ci, Fita.archivo(500), 30, Vector2(760, 86), "O carimbo é do jogo: tinta batida, sem fundo, com o desregistro da impressão.", Color(Fita.ETIQUETA, 0.85))
	Hud.texto(ci, Fita.archivo(500), 30, Vector2(760, 128), "Tudo por código (reacoes.gd), em qualquer tamanho e qualquer cor de dono.", Color(Fita.ETIQUETA, 0.85))
	_grade(ci)
	_roda(ci)
	_arena(ci)
	_carimbos(ci)


func _grade(ci: CanvasItem) -> void:
	Hud.texto(ci, Fita.archivo(600), 30, Vector2(56, 176), "Os oito, nas quatro cores, a 112 px sobre o casco", Fita.ETIQUETA)
	for j in 8:
		var id: String = Reacoes.ADESIVOS[j]
		var x := GRADE_X + j * PASSO_X
		Hud.texto(ci, Fita.vt(), 26, Vector2(x - 70, GRADE_Y + 4 * PASSO_Y - 62), DIRECOES[j] + " " + Reacoes.NOME[id], Fita.MUDO, HORIZONTAL_ALIGNMENT_CENTER, 140)
	for i in 4:
		var y := GRADE_Y + i * PASSO_Y
		Hud.texto(ci, Fita.bungee(), 34, Vector2(56, y - 20), "P%d" % (i + 1), Fita.JOGADOR[i])
		for j in 8:
			Reacoes.adesivo(ci, Vector2(GRADE_X + j * PASSO_X, y), 112.0, Reacoes.ADESIVOS[j], i)


## A roda: centrada na borda de dentro do cartão do dono (o cartão de baixo,
## então a borda de cima), 240 px, oito adesivos de 64 px, o ↑ primeiro.
func _roda(ci: CanvasItem) -> void:
	var lugar := 2
	var cor: Color = Fita.JOGADOR[lugar]
	var cartao := Rect2(1410, 620, Hud.CARTAO.x, Hud.CARTAO.y)
	Hud.texto(ci, Fita.archivo(600), 30, Vector2(1410, 176), "A roda aberta no cartão", Fita.ETIQUETA)
	Hud.texto(ci, Fita.vt(), 26, Vector2(1410, 214), "240 px, oito de 64, o dedo no touchpad", Fita.MUDO)
	Hud.caixa(ci, Rect2(cartao.position + Vector2(0, 6), cartao.size), Fita.SOMBRA, 10)
	Hud.caixa(ci, cartao, Fita.CASCO, 10, Fita.CASCO_ALTO, 2)
	ci.draw_rect(Rect2(cartao.position + Vector2(12, cartao.size.y - 5), Vector2(cartao.size.x - 24, 5)), cor)
	Hud.texto(ci, Fita.bungee(), 40, cartao.position + Vector2(18, 62), "P%d" % (lugar + 1), cor)
	Hud.texto(ci, Fita.archivo(600), 32, cartao.position + Vector2(0, 70), "Latão", Fita.ETIQUETA, HORIZONTAL_ALIGNMENT_RIGHT, cartao.size.x - 20)
	var c := Vector2(cartao.position.x + cartao.size.x * 0.5, cartao.position.y)
	ci.draw_circle(c + Vector2(4, 6), 120.0, Fita.SOMBRA)
	ci.draw_circle(c, 120.0, Fita.CASCO_ALTO)
	ci.draw_arc(c, 120.0, 0.0, TAU, 48, cor, 3.0, true)
	ci.draw_circle(c, 18.0, Fita.GRAFITE)
	# o dedo apontando o ↘ (o Riso): o gomo escolhido acende
	var escolhido := 3
	for j in 8:
		var a := -PI * 0.5 + TAU * j / 8.0
		var p := c + Vector2(cos(a), sin(a)) * 84.0
		if j == escolhido:
			ci.draw_line(c, p, cor, 6.0, true)
			ci.draw_circle(p, 38.0, cor)
		Reacoes.adesivo(ci, p, 64.0, Reacoes.ADESIVOS[j], lugar)


## A linha a 144 px sobre a arena: cada dono no ponto alto da faixa.
func _arena(ci: CanvasItem) -> void:
	Hud.texto(ci, Fita.archivo(600), 30, Vector2(56, ARENA.position.y - 48), "Uma linha a 144 px sobre a arena da Centelha (a faixa do meio da tela)", Fita.ETIQUETA)
	for j in 8:
		var x := 120.0 + j * 240.0
		Reacoes.adesivo(ci, Vector2(x, ARENA.position.y + 110), 144.0, Reacoes.ADESIVOS[j], j % 4)


func _carimbos(ci: CanvasItem) -> void:
	Hud.texto(ci, Fita.archivo(600), 30, Vector2(56, ARENA.end.y + 30), "Os seis carimbos do jogo, no tamanho da tela", Fita.ETIQUETA)
	var linha1 := ["car_virada", "car_em_chamas", "car_por_um_fio", "car_liga", "car_emburrado"]
	var donos := [1, 3, 0, 2, 3]
	var larguras := []
	var soma := 0.0
	for id in linha1:
		var w: float = 170.0 if id == "car_emburrado" else Hud.largura_do(Fita.bungee(), Reacoes.VISOR[id][1], Reacoes.VISOR[id][0])
		larguras.append(w)
		soma += w
	var vao := (LARGURA - 112.0 - soma) / (linha1.size() - 1)
	var x := 56.0
	for k in linha1.size():
		var id: String = linha1[k]
		var centro := Vector2(x + larguras[k] * 0.5, CARIMBO_Y[0])
		Reacoes.carimbo(ci, centro, id, donos[k])
		var rot := "%s  ·  Bungee %d" % [id, Reacoes.VISOR[id][1]] if id != "car_emburrado" else "car_emburrado  ·  160 px"
		Hud.texto(ci, Fita.vt(), 24, Vector2(centro.x - 150, CARIMBO_Y[0] + 96), rot, Fita.MUDO, HORIZONTAL_ALIGNMENT_CENTER, 300)
		x += larguras[k] + vao
	Reacoes.carimbo(ci, Vector2(LARGURA * 0.5, CARIMBO_Y[1] - 20), "car_acorde", 0)
	Hud.texto(ci, Fita.vt(), 24, Vector2(LARGURA - 300, CARIMBO_Y[1] - 60), "car_acorde", Fita.MUDO)
	Hud.texto(ci, Fita.vt(), 24, Vector2(LARGURA - 300, CARIMBO_Y[1] - 32), "Bungee 112, os quatro", Fita.MUDO)
