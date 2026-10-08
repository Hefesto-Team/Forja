extends Node3D
## Quadro 08 — Os quatro cavaleiros: a prancha de frente e de 3/4, com o
## martelo na mão, o anel de oito lados e as lâmpadas do lugar. Câmera
## ortográfica, como a prancha de modelo de um estúdio.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")

var espera := 8
var arquivo := "08_cavaleiros"
var e
const COLUNAS := [-3.9, -1.3, 1.3, 3.9]
const FRENTE_Z := 1.8
const TRAS_Z := -2.4
## O gesto de cada um na fileira de 3/4: o humor mora no boneco.
const GESTO := [["holding-right", 0.1], ["attack-melee-right", 0.14], ["emote-yes", 0.3], ["interact-right", 0.35]]


func montar(estudo) -> void:
	e = estudo
	var cam: Camera3D = e.camera
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 6.4
	cam.position = Vector3(0, 5.0, 9.5)
	cam.look_at(Vector3(0, 0.9, -0.4))
	Mundo.ambiente(self, {"ambiente": Color("#2a2738"), "ambiente_energia": 0.32, "nevoa": false, "glow_intensidade": 0.6})
	# o chão: uma tábua de estúdio, do Mini Dungeon recolorido
	for i in range(-3, 4):
		for j in range(-2, 2):
			Mundo.peca(self, "mini-dungeon/floor", Vector3(i * 2.0, 0, j * 2.0 + 0.4))
	var sol := DirectionalLight3D.new()
	add_child(sol)
	sol.rotation_degrees = Vector3(-48, -24, 0)
	sol.light_color = Fita.TUNGSTENIO
	sol.light_energy = 0.75
	sol.shadow_enabled = true
	sol.shadow_bias = 0.08
	sol.shadow_normal_bias = 2.0
	var contra := DirectionalLight3D.new()
	add_child(contra)
	contra.rotation_degrees = Vector3(-30, 160, 0)
	contra.light_color = Color("#8a7cff")
	contra.light_energy = 0.28
	for l in 4:
		var x: float = COLUNAS[l]
		Mundo.cavaleiro(self, l, Vector3(x, 0.0, FRENTE_Z), 0.0, "idle", 0.35, "", {"martelo": true})
		Mundo.cavaleiro(self, l, Vector3(x, 0.0, TRAS_Z), -PI * 0.25, GESTO[l][0], GESTO[l][1], "", {"martelo": true})
	Mundo.neon_sem_sombra(self)
	Mundo.pos(self, 5, {"grao": 0.03})
	Hud.camada(self, _hud)


func _hud(ci: CanvasItem) -> void:
	Hud.etiqueta(ci, Rect2(56, 40, 620, 150), "Os cavaleiros", "PRANCHA  ·  FRENTE E 3/4", Fita.SECAO[0], 54, -0.01)
	Hud.texto(ci, Fita.archivo(500), 30, Vector2(1240, 70), "Mini Characters (Kenney), corpo tingido pela luz", Color(Fita.ETIQUETA, 0.75), HORIZONTAL_ALIGNMENT_RIGHT, 620)
	Hud.texto(ci, Fita.archivo(500), 30, Vector2(1240, 110), "do colormap, contorno e aro na cor do lugar", Color(Fita.ETIQUETA, 0.75), HORIZONTAL_ALIGNMENT_RIGHT, 620)
	for l in 4:
		var p: Vector2 = e.camera.unproject_position(Vector3(COLUNAS[l], 0, FRENTE_Z + 0.9))
		var cor: Color = Fita.JOGADOR[l]
		var r := Rect2(p.x - 150, 960, 300, 84)
		Hud.caixa(ci, Rect2(r.position + Vector2(0, 5), r.size), Color(0, 0, 0, 0.45), 10)
		Hud.caixa(ci, r, Color(Fita.CASCO, 0.95), 10)
		ci.draw_rect(Rect2(r.position + Vector2(10, 0), Vector2(r.size.x - 20, 5)), cor)
		Hud.texto(ci, Fita.bungee(), 40, r.position + Vector2(18, 16), "P%d" % (l + 1), cor)
		Hud.lampadas(ci, r.position + Vector2(98, 34), l, cor, 15.0)
		Hud.texto(ci, Fita.archivo(600), 32, r.position + Vector2(0, 20), Fita.NOME_DA_COR[l], Fita.ETIQUETA, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 18)
