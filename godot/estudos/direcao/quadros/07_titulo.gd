extends Node3D
## Quadro 07 — O título: a fita da noite no deck. O cassete grande no meio,
## com o logo e o nome na etiqueta; atrás, a forja acendendo devagar; o
## mostrador do videocassete no canto (PLAY e o contador) e o «Começar»
## pulsando no tempo da faixa.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")

var espera := 8
var arquivo := "07_titulo"
var logo: Texture2D


func montar(e) -> void:
	e.olhar(Vector3(0, 2.2, 7.5), Vector3(0, 1.4, 0), 40.0)
	Mundo.ambiente(self, {"ambiente": Color("#2a2738"), "ambiente_energia": 0.3, "nevoa_densidade": 0.03,
		"nevoa_cor": Color("#15101f"), "glow_intensidade": 0.9})
	for i in range(-4, 5):
		for j in range(-3, 3):
			Mundo.peca(self, "mini-dungeon/floor", Vector3(i * 2.0, 0, j * 2.0), (i * 3 + j) % 4 * PI * 0.5)
	for i in range(-5, 6):
		Mundo.peca(self, "mini-dungeon/wall", Vector3(i * 2.0, 0, -4.0))
	var b := Mundo.peca(self, "survival-kit/workbench-anvil", Vector3(0, 0, 0.5), -PI * 0.5, 3.4)
	var m := b.find_child("hammer", true, false)
	if m:
		m.visible = false
	Mundo.foco(self, Vector3(0, 6.0, 2.0), Vector3(0, 0.8, 0.5), Fita.TUNGSTENIO, 3.5, 22.0, 10.0)
	Mundo.luz(self, Vector3(0, 0.6, 1.6), Color("#ff8a3a"), 1.6, 3.0)
	for lado in [-1.0, 1.0]:
		Mundo.tubo(self, Vector3(6.5, 0.07, 0.07), Vector3(lado * 4.6, 2.3, -3.4), Fita.VIOLETA, 1.3)
	Mundo.neon_sem_sombra(self)
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://assets/forja-logo.png"))
	img.generate_mipmaps()
	logo = ImageTexture.create_from_image(img)
	Hud.camada(self, _hud, 10)
	Mundo.pos(self, 15, {"aberracao": 1.6, "rasgo": 0.025, "semente": 6.0, "varredura": 0.1, "grao": 0.03})


func _hud(ci: CanvasItem) -> void:
	# o mostrador do videocassete
	var osd := Color(Fita.ETIQUETA, 0.9)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(100, 70), Vector2(100, 116), Vector2(138, 93)]), osd)
	Hud.texto(ci, Fita.vt(), 60, Vector2(156, 62), "PLAY", osd)
	Hud.texto(ci, Fita.vt(), 60, Vector2(0, 62), "SP  0:00:00", osd, HORIZONTAL_ALIGNMENT_RIGHT, 1820)
	# o cassete
	var r := Rect2(400, 170, 1120, 690)
	Hud.caixa(ci, Rect2(r.position + Vector2(10, 16), r.size), Color(0, 0, 0, 0.55), 34)
	Hud.caixa(ci, r, Fita.CASCO, 34, Fita.CASCO_ALTO, 4)
	for p in [Vector2(30, 30), Vector2(r.size.x - 30, 30), Vector2(30, r.size.y - 30), Vector2(r.size.x - 30, r.size.y - 30)]:
		ci.draw_circle(r.position + p, 11, Fita.GRAFITE)
		ci.draw_line(r.position + p - Vector2(6, 6), r.position + p + Vector2(6, 6), Fita.CASCO, 3.0)
	# a etiqueta: o logo, o nome, a linha impressa
	var et := Rect2(r.position + Vector2(56, 48), Vector2(r.size.x - 112, 360))
	Hud.caixa(ci, et, Fita.ETIQUETA, 12)
	ci.draw_rect(Rect2(et.position + Vector2(0, 26), Vector2(et.size.x, 18)), Fita.SECAO[0])
	ci.draw_rect(Rect2(et.position + Vector2(0, 50), Vector2(et.size.x, 6)), Fita.SECAO[3])
	ci.draw_texture_rect(logo, Rect2(et.position + Vector2(36, 76), Vector2(260, 260)), false)
	var f := Fita.bungee()
	var tam := 128
	var nome := "A FORJA"
	var pos := et.position + Vector2(330, 104)
	# o pulso: o eco do nome na batida anterior, em vermelhão impresso
	Hud.texto(ci, f, tam, pos + Vector2(10, 10), nome, Color(Fita.SECAO[0], 0.9))
	Hud.texto(ci, f, tam, pos, nome, Fita.TINTA)
	Hud.texto(ci, Fita.marcador(), 40, et.position + Vector2(338, 268), "Nove salas, quatro cavaleiros", Fita.TINTA)
	for i in 2:
		ci.draw_line(Vector2(et.position.x + 330, et.end.y - 30 - i * 0), Vector2(et.end.x - 36, et.end.y - 30), Fita.ETIQUETA_SOMBRA, 2.0)
	# a janela com os carretéis
	var jan := Rect2(Vector2(r.get_center().x - 300, et.end.y + 34), Vector2(600, 170))
	Hud.caixa(ci, jan, Color("#07050c"), 22, Fita.GRAFITE, 3)
	var c1 := jan.position + Vector2(140, jan.size.y * 0.5)
	var c2 := jan.position + Vector2(jan.size.x - 140, jan.size.y * 0.5)
	ci.draw_line(c1 + Vector2(0, 66), c2 + Vector2(0, 40), Color("#3b2a22"), 4.0, true)
	Hud.carretel(ci, c1, 70, 0.95)
	Hud.carretel(ci, c2, 70, 0.3)
	# o pé do cassete (o trapézio com os furos da cabeça)
	var pe := PackedVector2Array([Vector2(r.position.x + 230, r.end.y), Vector2(r.position.x + 290, r.end.y - 80),
		Vector2(r.end.x - 290, r.end.y - 80), Vector2(r.end.x - 230, r.end.y)])
	ci.draw_colored_polygon(pe, Fita.CASCO_ALTO)
	for x in [-180.0, -60.0, 60.0, 180.0]:
		ci.draw_circle(Vector2(r.get_center().x + x, r.end.y - 36), 14, Color("#07050c"))
	# o começar, pulsando: o eco é a batida que passou
	var bt := Rect2(760, 920, 400, 82)
	Hud.caixa(ci, bt.grow(10), Color(Fita.ETIQUETA, 0.12), 18)
	Hud.caixa(ci, bt, Fita.ETIQUETA, 14)
	Hud.glifo(ci, "cross", Rect2(bt.position + Vector2(22, 13), Vector2(56, 56)), Fita.TINTA)
	Hud.texto(ci, Fita.archivo(700), 44, bt.position + Vector2(98, 14), "Começar", Fita.TINTA)
