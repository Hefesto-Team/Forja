extends Node3D
## Quadro 15 — O fim da fita (01; PRODUCAO, item 6): o último plano da
## noite. O deck parado, de frente, a 85 mm (sem fuga: a frente do aparelho é
## um plano só). O leader, a ponta transparente, cruza a janela; o carretel
## da esquerda vazio, o da direita cheio. O contador parado no tempo real da
## noite, a data escrita a caneta na etiqueta e as duas saídas. Nenhuma cor
## de jogador e nenhum número além do contador.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")

var espera := 8
var arquivo := "15_fim_da_fita"
const TEMPO := "1:47:12"
const DATA := "8 de outubro de 2026"
## O storyboard (14) usa o mesmo deck no PLAY e no virar da fita.
var tempo := TEMPO
var osd := "STOP"
var lado := "LADO B"
var saidas := true
var fim := true


func montar(e) -> void:
	# a sala atrás, apagada: a forja já esfriou, só o violeta da arquitetura
	e.olhar(Vector3(0, 1.6, 9.0), Vector3(0, 1.2, 0), 16.0)  # 85 mm
	Mundo.ambiente(self, {"ambiente": Color("#2a2738"), "ambiente_energia": 0.16, "nevoa_densidade": 0.035,
		"nevoa_cor": Color("#120d1a"), "glow_intensidade": 0.6})
	for i in range(-3, 4):
		Mundo.peca(self, "mini-dungeon/floor", Vector3(i * 2.0, 0, 0))
		Mundo.peca(self, "mini-dungeon/wall", Vector3(i * 2.0, 0, -3.0))
	var b := Mundo.peca(self, "survival-kit/workbench-anvil", Vector3(0, 0, -0.5), -PI * 0.5, 3.4)
	var m := b.find_child("hammer", true, false)
	if m:
		m.visible = false
	Mundo.luz(self, Vector3(0, 0.5, 0.6), Color("#ff8a3a"), 0.25, 2.0)  # a brasa que sobrou
	Mundo.tubo(self, Vector3(9.0, 0.06, 0.06), Vector3(0, 2.6, -2.6), Fita.VIOLETA, 0.6)
	Mundo.neon_sem_sombra(self)
	Hud.camada(self, _hud, 10)
	Mundo.pos(self, 15, {"aberracao": 0.8, "rasgo": 0.0, "varredura": 0.08, "grao": 0.03})


func _hud(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(Fita.FITA, 0.55))
	# o mostrador: STOP, quadrado parado (nada pisca)
	var cor_osd := Color(Fita.ETIQUETA, 0.9)
	if osd == "PLAY":
		ci.draw_colored_polygon(PackedVector2Array([Vector2(100, 70), Vector2(100, 116), Vector2(138, 93)]), cor_osd)
	else:
		ci.draw_rect(Rect2(100, 74, 38, 38), cor_osd)
	Hud.texto(ci, Fita.vt(), 60, Vector2(156, 62), osd, cor_osd)
	# a frente do deck
	var d := Rect2(170, 170, 1580, 640)
	Hud.caixa(ci, Rect2(d.position + Vector2(10, 16), d.size), Color(0, 0, 0, 0.6), 22)
	Hud.caixa(ci, d, Fita.CASCO, 22, Fita.CASCO_ALTO, 4)
	for i in 6:
		var y := d.position.y + 30 + i * 6
		ci.draw_line(Vector2(d.position.x + 40, y), Vector2(d.end.x - 40, y), Color(Fita.CASCO_ALTO, 0.6), 2.0)
	Hud.texto(ci, Fita.vt(), 30, d.position + Vector2(44, 76), "AUTO-STOP   ·   DOLBY NR   ·   2 CABEÇAS", Fita.MUDO)
	# a porta do compartimento, com o cassete atrás do vidro
	var porta := Rect2(d.position + Vector2(44, 130), Vector2(980, 470))
	Hud.caixa(ci, porta, Fita.JANELA, 16, Fita.GRAFITE, 3)
	var k := Rect2(porta.position + Vector2(40, 34), porta.size - Vector2(80, 68))
	Hud.caixa(ci, k, Fita.CASCO_ALTO, 20)
	# a etiqueta do cassete: o nome impresso e a data a caneta
	var et := Rect2(k.position + Vector2(40, 28), Vector2(k.size.x - 80, 160))
	Hud.caixa(ci, et, Fita.ETIQUETA, 10)
	ci.draw_rect(Rect2(et.position + Vector2(0, 16), Vector2(et.size.x, 10)), Fita.SECAO[0])
	ci.draw_rect(Rect2(et.position + Vector2(0, 30), Vector2(et.size.x, 4)), Fita.SECAO[3])
	Hud.texto(ci, Fita.bungee(), 40, et.position + Vector2(22, 46), "A FORJA", Fita.TINTA)
	Hud.texto(ci, Fita.vt(), 30, et.position + Vector2(0, 52), lado, Fita.TINTA_SUAVE, HORIZONTAL_ALIGNMENT_RIGHT, et.size.x - 22)
	ci.draw_line(Vector2(et.position.x + 22, et.end.y - 24), Vector2(et.end.x - 22, et.end.y - 24), Fita.ETIQUETA_SOMBRA, 2.0)
	ci.draw_set_transform(et.position + Vector2(24, et.size.y - 74), -0.025, Vector2.ONE)
	if fim:
		Hud.texto(ci, Fita.marcador(), 44, Vector2.ZERO, DATA, Fita.TINTA)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# a janela do cassete: o carretel da esquerda vazio, o da direita cheio,
	# e entre eles o leader, transparente
	var jan := Rect2(Vector2(k.get_center().x - 280, et.end.y + 24), Vector2(560, 150))
	Hud.caixa(ci, jan, Fita.JANELA, 18, Fita.GRAFITE, 2)
	var c1 := jan.position + Vector2(120, jan.size.y * 0.5)
	var c2 := jan.position + Vector2(jan.size.x - 120, jan.size.y * 0.5)
	var raio := 66.0
	var leader := PackedVector2Array([c1 + Vector2(0, raio * 0.42), c1 + Vector2(40, raio * 0.95 + 4), c2 + Vector2(-30, raio + 2), c2 + Vector2(0, raio)])
	if fim:
		ci.draw_polyline(leader, Color(Fita.ETIQUETA, 0.28), 6.0, true)
		ci.draw_polyline(leader, Color(Fita.ETIQUETA, 0.55), 1.5, true)
	else:
		ci.draw_line(c1 + Vector2(0, raio), c2 + Vector2(0, raio * 0.42), Fita.OXIDO, 4.0, true)
	Hud.carretel(ci, c1, raio, 0.0 if fim else 1.0)
	Hud.carretel(ci, c2, raio, 1.0 if fim else 0.0)
	# o contador, parado no tempo da noite
	var cx := porta.end.x + 70
	Hud.texto(ci, Fita.vt(), 30, Vector2(cx, porta.position.y + 10), "CONTADOR", Fita.MUDO)
	Hud.contador(ci, Vector2(cx, porta.position.y + 50), tempo, 76)
	# as teclas do deck, em relevo, sem letra acesa
	for i in 6:
		var t := Rect2(Vector2(cx + i * 74, porta.end.y - 120), Vector2(62, 120))
		Hud.caixa(ci, t, Fita.CASCO_ALTO if i != 3 else Fita.GRAFITE, 6)
		ci.draw_rect(Rect2(t.position + Vector2(10, 12), Vector2(t.size.x - 20, 4)), Fita.CASCO)
	if not saidas:
		return
	# as duas saídas
	var botoes := [["cross", "Botão ✕ (Gravar outra noite)"], ["circle", "Botão ◯ (Ejetar)"]]
	var x := 400.0
	for s in botoes:
		var w := Hud.largura_do(Fita.archivo(700), 40, s[1]) + 110
		var bt := Rect2(x, 900, w, 76)
		Hud.caixa(ci, bt, Fita.ETIQUETA, 14)
		Hud.glifo(ci, s[0], Rect2(bt.position + Vector2(20, 12), Vector2(52, 52)), Fita.TINTA)
		Hud.texto(ci, Fita.archivo(700), 40, bt.position + Vector2(86, 14), s[1], Fita.TINTA)
		x += w + 60
