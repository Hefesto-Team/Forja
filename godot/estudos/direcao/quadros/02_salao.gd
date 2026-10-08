extends Node3D
## Quadro 02 — O salão como estúdio: um portão por seção na parede do fundo,
## cada um com a etiqueta do lado dele (a tarja na tinta da seção); a bigorna
## da partida no meio, no palco; as caixas de som nos cantos. O portão
## vencido acende; os outros esperam no escuro.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")

var espera := 8
var arquivo := "02_salao"
var e
const SECOES := ["A Centelha", "A Viga", "O Molde", "O Impacto", "A Galeria"]
const MAQUINA := ["arcade-machine", "pinball", "claw-machine", "basketball-game", "dance-machine"]
const PORTAO_X := [-8.0, -4.0, 0.0, 4.0, 8.0]
const FUNDO_Z := -8.0
## Quem venceu: a Centelha (o portão aceso).
const VENCIDA := 0
const NOMES := ["Brasa", "Faísca", "Rebite", "Bigorna"]
var p1_cabeca := Vector2.ZERO


func montar(estudo) -> void:
	e = estudo
	e.olhar(Vector3(0, 7.4, 9.6), Vector3(0, 1.3, -3.6), 44.0)
	Mundo.ambiente(self, {"ambiente": Color("#2a2738"), "ambiente_energia": 0.4, "nevoa_densidade": 0.012,
		"nevoa_cor": Color("#15101f"), "glow_intensidade": 0.7})
	_sala()
	for i in 5:
		_portao(i)
	_palco()
	_caixas_de_som()
	var sol := DirectionalLight3D.new()
	add_child(sol)
	sol.rotation_degrees = Vector3(-58, -24, 0)
	sol.light_color = Color("#b8b0ff")
	sol.light_energy = 0.22
	sol.shadow_enabled = true
	sol.shadow_bias = 0.08
	sol.shadow_normal_bias = 2.0
	# os cavaleiros: o P1 vai para o portão aceso, o P2 dança na máquina de
	# dança, o P3 tropeçou no treino (o humor mora no boneco), o P4 bate
	# na bigorna da partida
	var p1 := Vector3(-5.7, 0, -2.6)
	Mundo.cavaleiro(self, 0, p1, PI * 0.82, "walk", 0.2, "", {"martelo": true})
	Mundo.cavaleiro(self, 1, Vector3(6.6, 0, -4.4), PI * 0.15, "emote-yes", 0.25, "", {"martelo": true})
	Mundo.cavaleiro(self, 2, Vector3(-2.7, 0, -0.9), 0.9, "fall", 0.3, "", {"martelo": true})
	Mundo.cavaleiro(self, 3, Vector3(1.05, 1.0, -0.85), -PI * 0.4, "attack-melee-right", 0.14, "", {"martelo": true, "anel": false})
	Mundo.neon_sem_sombra(self)
	Mundo.pos(self, 5)
	p1_cabeca = e.camera.unproject_position(p1 + Vector3(0, 1.9, 0))
	Hud.camada(self, _hud)


func _sala() -> void:
	for i in range(-5, 6):
		for j in range(-4, 4):
			Mundo.peca(self, "mini-dungeon/floor", Vector3(i * 2.0, 0, j * 2.0), (i * 7 + j * 3) % 4 * PI * 0.5)
	for i in range(-6, 7):
		Mundo.peca(self, "mini-arcade/wall-window" if absi(i) == 6 else "mini-arcade/wall", Vector3(i * 2.0, 0, FUNDO_Z - 0.6))
	for j in range(-4, 4):
		for lado in [-1.0, 1.0]:
			Mundo.peca(self, "mini-arcade/wall", Vector3(lado * 12.4, 0, j * 2.0), PI * 0.5)
	# o tubo da arquitetura, no alto da parede do fundo, interrompido nos portões
	for i in 4:
		var x: float = (PORTAO_X[i] + PORTAO_X[i + 1]) * 0.5
		Mundo.tubo(self, Vector3(2.0, 0.07, 0.07), Vector3(x, 2.15, FUNDO_Z - 0.25), Fita.VIOLETA, 1.2)


func _portao(i: int) -> void:
	var x: float = PORTAO_X[i]
	var aceso := i == VENCIDA
	var tinta: Color = Fita.SECAO[i]
	# a máquina da seção, entre duas colunas
	Mundo.peca(self, "mini-arcade/" + MAQUINA[i], Vector3(x, 0, FUNDO_Z + 1.0), 0.0, 2.6)
	# a etiqueta do portão: o papel, a tarja da seção, o nome a caneta
	var papel := Mundo.caixa(self, Vector3(2.9, 0.95, 0.04), Vector3(x, 2.75, FUNDO_Z + 0.25),
		Fita.fosco(Fita.ETIQUETA if aceso else Fita.ETIQUETA.darkened(0.55), 0.9))
	Mundo.caixa(self, Vector3(2.9, 0.1, 0.05), Vector3(x, 3.08, FUNDO_Z + 0.26),
		Fita.fosco(tinta if aceso else tinta.darkened(0.45), 0.9))
	var nome := Label3D.new()
	nome.text = SECOES[i]
	nome.font = Fita.marcador()
	nome.font_size = 88
	nome.pixel_size = 0.0042
	nome.modulate = Fita.TINTA
	nome.outline_size = 0
	nome.shaded = true
	nome.position = Vector3(x - 1.3, 2.72, FUNDO_Z + 0.28)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(nome)
	var faixa := Label3D.new()
	faixa.text = "S%d  ·  5 FAIXAS" % (i + 1)
	faixa.font = Fita.vt()
	faixa.font_size = 72
	faixa.pixel_size = 0.0036
	faixa.modulate = Fita.TINTA_SUAVE
	faixa.outline_size = 0
	faixa.shaded = true
	faixa.position = Vector3(x - 1.3, 2.43, FUNDO_Z + 0.28)
	faixa.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(faixa)
	papel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# a soleira: o tapete impresso na tinta da seção (tinta, não néon)
	Mundo.caixa(self, Vector3(2.2, 0.03, 2.4), Vector3(x, 0.015, FUNDO_Z + 2.6),
		Fita.fosco(tinta.darkened(0.15 if aceso else 0.6), 0.95))
	# a luz: o portão vencido ganha o foco de lâmpada e o contorno violeta
	Mundo.foco(self, Vector3(x, 6.5, FUNDO_Z + 5.0), Vector3(x, 1.4, FUNDO_Z + 0.6), Fita.TUNGSTENIO,
		3.2 if aceso else 0.55, 24.0, 12.0)
	if aceso:
		Mundo.tubo(self, Vector3(3.1, 0.06, 0.06), Vector3(x, 3.32, FUNDO_Z + 0.27), Fita.ETIQUETA, 1.3)
		Mundo.luz(self, Vector3(x, 1.2, FUNDO_Z + 2.4), Fita.TUNGSTENIO, 1.2, 4.0)


## O palco no meio: a bigorna da partida sobre os blocos da Mini Arena.
func _palco() -> void:
	Mundo.peca(self, "mini-arena/block", Vector3(0, 0, -1.0))
	Mundo.peca(self, "mini-arena/stairs", Vector3(0, 0, 1.0), PI)
	var b := Mundo.peca(self, "survival-kit/workbench-anvil", Vector3(0, 1.0, -1.0), 0.0, 3.6)
	var m := b.find_child("hammer", true, false)
	if m:
		m.visible = false
	Mundo.foco(self, Vector3(0, 8.0, 2.0), Vector3(0, 1.0, -1.0), Fita.TUNGSTENIO, 4.5, 20.0, 14.0)


func _caixas_de_som() -> void:
	for lado in [-1.0, 1.0]:
		var x: float = lado * 10.6
		for k in 3:
			var cx := Mundo.peca(self, "survival-kit/box-large", Vector3(x, k * 0.72, -5.6), PI * 0.5 + lado * -0.4, 2.9)
			cx.name = "caixa"
			var cone := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.3
			cm.bottom_radius = 0.12
			cm.height = 0.08
			cm.radial_segments = 8
			cone.mesh = cm
			cone.material_override = Fita.fosco(Color("#0a0810"), 0.9)
			add_child(cone)
			var frente := Vector3(sin(lado * -0.4), 0, cos(lado * -0.4))
			cone.position = Vector3(x, k * 0.72 + 0.36, -5.6) + frente * 0.38
			cone.rotation = Vector3(PI * 0.5, lado * -0.4, 0)


func _hud(ci: CanvasItem) -> void:
	Hud.etiqueta(ci, Rect2(96, 54, 520, 150), "O Salão", "A FORJA  ·  LADO A", Fita.SECAO[0], 56, -0.01)
	# o placar da noite: as salas vencidas no contador de fita
	Hud.texto(ci, Fita.archivo(500), 32, Vector2(1300, 76), "Salas vencidas", Color(Fita.ETIQUETA, 0.85), HORIZONTAL_ALIGNMENT_RIGHT, 260)
	Hud.contador(ci, Vector2(1580, 58), "1/9", 64)
	# a dica presa ao cavaleiro do P1: o botão e o verbo
	var r := Rect2(p1_cabeca + Vector2(60, -60), Vector2(300, 64))
	Hud.caixa(ci, Rect2(r.position + Vector2(0, 5), r.size), Color(0, 0, 0, 0.45), 10)
	Hud.caixa(ci, r, Fita.ETIQUETA, 10)
	Hud.glifo(ci, "cross", Rect2(r.position + Vector2(12, 10), Vector2(44, 44)), Fita.TINTA)
	Hud.texto(ci, Fita.archivo(700), 32, r.position + Vector2(66, 12), "Tocar a faixa", Fita.TINTA)
	ci.draw_colored_polygon(PackedVector2Array([r.position + Vector2(0, 26), r.position + Vector2(0, 46), r.position + Vector2(-16, 40)]), Fita.ETIQUETA)
	# os quatro lugares, embaixo: quem já está pronto
	for l in 4:
		Hud.chip(ci, Rect2(206 + l * 384, 966, 356, 60), l, l != 2)
