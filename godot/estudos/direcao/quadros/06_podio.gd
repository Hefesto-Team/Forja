extends Node3D
## Quadro 06 — O pódio: o respiro dourado depois da noite. A luz vira
## tungstênio, a câmera desce (o vencedor fica grande), o confete é fita
## cortada (papel da etiqueta e a cor de quem venceu). O último lugar
## emburra no chão: o humor mora no boneco.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")

var espera := 8
var arquivo := "06_podio"
const VENCEDOR := 1
## Os blocos: x, quantos blocos de altura, o lugar em cima, a pose.
const DEGRAUS := [
	[0.0, 2, 1, "jump", 0.22],
	[-2.2, 1, 3, "emote-yes", 0.3],
	[2.2, 1, 0, "idle", 0.5],
]


func montar(e) -> void:
	e.olhar(Vector3(0, 1.7, 10.6), Vector3(0, 2.35, 0), 38.0)
	Mundo.ambiente(self, {"ambiente": Color("#3a2c26"), "ambiente_energia": 0.45, "nevoa_densidade": 0.02,
		"nevoa_cor": Color("#2a1a14"), "glow_intensidade": 0.75})
	for i in range(-4, 5):
		for j in range(-3, 3):
			Mundo.peca(self, "mini-arena/floor", Vector3(i * 2.0, 0, j * 2.0))
	for i in range(-5, 6):
		Mundo.peca(self, "mini-arena/wall", Vector3(i * 2.0, 0, -5.0))
	for x in [-6.0, -3.0, 3.0, 6.0]:
		Mundo.peca(self, "mini-arena/banner", Vector3(x, 1.2, -4.4))
	for x in [-8.0, 8.0]:
		Mundo.peca(self, "mini-arena/statue", Vector3(x, 0, -3.6))
	for d in DEGRAUS:
		var x: float = d[0]
		var altura: int = d[1]
		for k in altura:
			Mundo.peca(self, "mini-arena/block", Vector3(x, k * 1.0, 0))
		var numero := Label3D.new()
		numero.text = str(DEGRAUS.find(d) + 1)
		numero.font = Fita.bungee()
		numero.font_size = 160
		numero.pixel_size = 0.004
		numero.modulate = Fita.ETIQUETA
		numero.outline_size = 0
		numero.shaded = true
		numero.position = Vector3(x, altura * 0.5, 1.02)
		add_child(numero)
		Mundo.cavaleiro(self, d[2], Vector3(x, altura * 1.0 + (0.35 if d[3] == "jump" else 0.0), 0.1), 0.0, d[3], d[4], "",
			{"martelo": true, "anel": false})
	# o troféu do vencedor: o objeto de jogo em ouro de lâmpada
	var t := Mundo.peca(self, "mini-arena/trophy", Vector3(0.95, 2.0, 0.35), -0.4, 1.6)
	var ouro := StandardMaterial3D.new()
	ouro.albedo_color = Fita.SECAO[3]  # o ouro do pódio é a tinta mostarda
	ouro.metallic = 0.55
	ouro.roughness = 0.35
	for mi in t.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = ouro
	# o último lugar, emburrado no chão, de costas para o pódio
	Mundo.cavaleiro(self, 2, Vector3(4.3, 0, 2.6), -2.4, "sit", 0.1, "", {"anel": true})
	# a luz: três focos de lâmpada, o do vencedor mais forte
	Mundo.foco(self, Vector3(0, 7.5, 3.5), Vector3(0, 2.4, 0), Fita.TUNGSTENIO, 7.0, 18.0, 14.0)
	Mundo.foco(self, Vector3(-2.6, 7.0, 3.5), Vector3(-2.2, 1.4, 0), Fita.TUNGSTENIO, 3.2, 16.0, 14.0)
	Mundo.foco(self, Vector3(2.6, 7.0, 3.5), Vector3(2.2, 1.4, 0), Fita.TUNGSTENIO, 3.2, 16.0, 14.0)
	Mundo.luz(self, Vector3(0, 2.2, -2.5), Fita.JOGADOR[VENCEDOR], 2.2, 5.0)
	var sol := DirectionalLight3D.new()
	add_child(sol)
	sol.rotation_degrees = Vector3(-50, -20, 0)
	sol.light_color = Color("#ffcf96")
	sol.light_energy = 0.35
	sol.shadow_enabled = true
	sol.shadow_bias = 0.08
	sol.shadow_normal_bias = 2.0
	_confete()
	Mundo.neon_sem_sombra(self)
	Mundo.pos(self, 5, {"vinheta": 0.45})
	Hud.camada(self, _hud)


## O confete de fita (07, o confete de fita): 160 tiras de 0,05 × 0,22 ×
## 0,008 m, 50 % óxido que pega luz, 20 % etiqueta, 30 % a cor de quem venceu.
func _confete() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var papel := Fita.fosco(Fita.ETIQUETA, 0.7)
	var oxido := Fita.fosco(Fita.OXIDO_BRILHO, 0.6)
	var dono := Fita.neon(Fita.JOGADOR[VENCEDOR], 1.0)
	for i in 160:
		var s := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.05, 0.22, 0.008)
		s.mesh = b
		var r := rng.randf()
		s.material_override = dono if r < 0.30 else (oxido if r < 0.80 else papel)
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(s)
		s.position = Vector3(rng.randf_range(-6.5, 6.5), rng.randf_range(0.6, 5.2), rng.randf_range(-2.5, 3.5))
		s.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)


func _hud(ci: CanvasItem) -> void:
	var cor: Color = Fita.JOGADOR[VENCEDOR]
	# o nome de quem venceu, grande, com o desregistro da impressão
	var f := Fita.bungee()
	var palavra := "OBSIDIANA!"  ## o P2 da montagem (10)
	var tam := 150
	var w := Hud.largura_do(f, tam, palavra)
	# o nome cabe entre a etiqueta e a borda: no máximo 880 px de largura
	if w > 880.0:
		tam = int(tam * 880.0 / w)
		w = Hud.largura_do(f, tam, palavra)
	var c := Vector2(960, 150)
	ci.draw_set_transform(c, -0.03, Vector2.ONE)
	Hud.texto(ci, f, tam, Vector2(-w * 0.5 + 12, -tam * 0.5 + 12), palavra, Fita.FITA)
	Hud.texto(ci, f, tam, Vector2(-w * 0.5, -tam * 0.5), palavra, cor)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	Hud.texto(ci, Fita.vt(), 48, Vector2(0, 238), "P2  ·  VENCEU A NOITE  ·  4 210 PONTOS", Fita.ETIQUETA, HORIZONTAL_ALIGNMENT_CENTER, 1920)
	# a etiqueta da faixa do pódio
	Hud.etiqueta(ci, Rect2(96, 54, 400, 130), "O Pódio", "LADO B  ·  FIM", Fita.SECAO[3], 50, -0.015)
	# o que fazer agora
	var botoes := [["cross", "Outra partida"], ["circle", "Salão"]]
	var x := 690.0
	for b in botoes:
		var r := Rect2(x, 970, 300 if b[0] == "cross" else 200, 64)
		Hud.caixa(ci, Rect2(r.position + Vector2(0, 5), r.size), Fita.SOMBRA, 10)
		Hud.caixa(ci, r, Color(Fita.CASCO, 0.94), 10)
		Hud.glifo(ci, b[0], Rect2(r.position + Vector2(12, 10), Vector2(44, 44)), Fita.ETIQUETA)
		Hud.texto(ci, Fita.archivo(600), 32, r.position + Vector2(66, 12), b[1], Fita.ETIQUETA)
		x += r.size.x + 40
