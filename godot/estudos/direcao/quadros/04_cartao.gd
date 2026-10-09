extends Node3D
## Quadro 04 — O cartão do minigame como a capa de uma fita (o J-card): a
## lombada com o nome, a tarja da seção, o título a caneta, o gênero, o
## «Como jogar» com os glifos do controle, o contador da fita e os quatro
## lugares (quem está pronto, quem ainda treina). Ao lado, o boneco no gesto.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")

var espera := 8
var arquivo := "04_cartao"


func montar(e) -> void:
	e.olhar(Vector3(2.2, 1.5, 5.8), Vector3(1.75, 0.8, 0.0), 30.0)
	Mundo.ambiente(self, {"ambiente": Color("#2a2738"), "ambiente_energia": 0.35, "nevoa": false, "glow_intensidade": 0.7})
	for i in range(-2, 3):
		for j in range(-2, 2):
			Mundo.peca(self, "mini-dungeon/floor", Vector3(i * 2.0, 0, j * 2.0), (i + j) % 4 * PI * 0.5)
	Mundo.cavaleiro(self, 0, Vector3(-0.2, 0, 0.2), 0.95, "attack-melee-right", 0.1, "", {"martelo": true})
	var b := Mundo.peca(self, "survival-kit/workbench-anvil", Vector3(0.75, 0, -0.55), -PI * 0.3, 3.0)
	var m := b.find_child("hammer", true, false)
	if m:
		m.visible = false
	Mundo.foco(self, Vector3(0.6, 4.5, 2.2), Vector3(0.3, 0.6, 0.1), Fita.TUNGSTENIO, 5.0, 22.0, 9.0)
	var contra := DirectionalLight3D.new()
	add_child(contra)
	contra.rotation_degrees = Vector3(-25, 160, 0)
	contra.light_color = Color("#8a7cff")
	contra.light_energy = 0.55
	Mundo.neon_sem_sombra(self)
	Mundo.pos(self, 5)
	Hud.camada(self, _hud)


func _hud(ci: CanvasItem) -> void:
	var r := Rect2(760, 90, 1064, 830)
	var tinta: Color = Fita.SECAO[0]
	ci.draw_set_transform(r.get_center(), 0.008, Vector2.ONE)
	var rr := Rect2(-r.size * 0.5, r.size)
	Hud.caixa(ci, Rect2(rr.position + Vector2(8, 12), rr.size), Fita.SOMBRA, 8)
	Hud.caixa(ci, rr, Fita.ETIQUETA, 8)
	# a lombada: a dobra do J-card, com o nome deitado
	var lombada := 104.0
	ci.draw_rect(Rect2(rr.position, Vector2(lombada, rr.size.y)), Fita.ETIQUETA_SOMBRA)
	ci.draw_rect(Rect2(rr.position + Vector2(0, 0), Vector2(lombada, 22)), tinta)
	ci.draw_line(rr.position + Vector2(lombada, 0), rr.position + Vector2(lombada, rr.size.y), Color(Fita.TINTA, 0.25), 2.0)
	ci.draw_set_transform(r.get_center() + Vector2(rr.position.x + 30, rr.end.y - 40).rotated(0.008), 0.008 - PI * 0.5, Vector2.ONE)
	Hud.texto(ci, Fita.vt(), 46, Vector2.ZERO, "S1  ·  O MARTELO DE HEFESTO  ·  LADO A", Fita.TINTA)
	ci.draw_set_transform(r.get_center(), 0.008, Vector2.ONE)
	var x0 := rr.position.x + lombada + 44
	# a tarja da seção e o título a caneta
	ci.draw_rect(Rect2(Vector2(rr.position.x + lombada, rr.position.y + 22), Vector2(rr.size.x - lombada, 16)), tinta)
	Hud.texto(ci, Fita.vt(), 40, Vector2(x0, rr.position.y + 62), "A CENTELHA", Fita.TINTA_SUAVE)
	Hud.texto(ci, Fita.marcador(), 74, Vector2(x0 - 6, rr.position.y + 108), "O Martelo de Hefesto", Fita.TINTA)
	# o gênero, carimbado
	var g := Rect2(Vector2(x0, rr.position.y + 228), Vector2(330, 54))
	Hud.caixa(ci, g, Color(Fita.FITA, 0.0), 6, tinta, 3)
	Hud.texto(ci, Fita.archivo(700), 34, g.position + Vector2(0, 7), "Todos contra todos", Fita.TINTA, HORIZONTAL_ALIGNMENT_CENTER, g.size.x)
	# o contador da fita: a faixa no lado
	Hud.texto(ci, Fita.vt(), 40, Vector2(rr.end.x - 330, rr.position.y + 236), "LADO A", Fita.TINTA_SUAVE)
	ci.draw_set_transform(r.get_center(), 0.008, Vector2.ONE)
	Hud.contador(ci, Vector2(rr.end.x - 200, rr.position.y + 216), "03", 64)
	# as linhas pautadas e o como-se-joga
	var y := rr.position.y + 318
	ci.draw_line(Vector2(x0, y), Vector2(rr.end.x - 44, y), Fita.ETIQUETA_SOMBRA, 2.0)
	Hud.texto(ci, Fita.vt(), 40, Vector2(x0, y + 16), "COMO JOGAR", Fita.TINTA_SUAVE)
	var linhas := [["cross", "Bata no tempo do bumbo"], ["r2", "Segure para o golpe forte"]]
	for i in linhas.size():
		var yl := y + 76 + i * 92
		Hud.glifo(ci, linhas[i][0], Rect2(Vector2(x0, yl), Vector2(64, 64)), Fita.TINTA)
		Hud.texto(ci, Fita.archivo(600), 44, Vector2(x0 + 88, yl + 6), linhas[i][1], Fita.TINTA)
		ci.draw_line(Vector2(x0, yl + 80), Vector2(rr.end.x - 44, yl + 80), Fita.ETIQUETA_SOMBRA, 2.0)
	# os quatro lugares: o treino não vale ponto
	var yc := rr.end.y - 232
	Hud.texto(ci, Fita.vt(), 40, Vector2(x0, yc), "TREINO  ·  NÃO VALE PONTO", Fita.TINTA_SUAVE)
	Hud.texto(ci, Fita.archivo(600), 34, Vector2(x0, yc + 4), "Começa em 6", Fita.TINTA, HORIZONTAL_ALIGNMENT_RIGHT, rr.end.x - 44 - x0)
	var w := (rr.end.x - 44 - x0 - 16) / 2.0
	for l in 4:
		Hud.chip(ci, Rect2(Vector2(x0 + (l % 2) * (w + 16), yc + 56 + (l / 2) * 76), Vector2(w, 64)), l, l != 2)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
