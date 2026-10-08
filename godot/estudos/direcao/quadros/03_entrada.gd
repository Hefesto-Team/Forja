extends Node3D
## Quadro 03 — A entrada da faixa: a cortina na tinta da seção desce com o
## corte em diagonal, o verbo gigante pulsa no tempo (os ecos são a batida
## anterior) e treme como a fita no cabeçote. Atrás, a bigorna e o martelo
## no meio do golpe, na luz de lâmpada.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")

var espera := 8
var arquivo := "03_entrada"
const VERBO := "MARTELE!"


func montar(e) -> void:
	e.olhar(Vector3(-1.2, 2.1, 3.6), Vector3(-1.3, 0.85, 0.0), 34.0)
	Mundo.ambiente(self, {"ambiente": Color("#2a2738"), "ambiente_energia": 0.25, "nevoa": false, "glow_intensidade": 0.9})
	for i in range(-2, 4):
		for j in range(-3, 2):
			Mundo.peca(self, "mini-dungeon/floor", Vector3(i * 2.0, 0, j * 2.0), (i + j) % 4 * PI * 0.5)
	var b := Mundo.peca(self, "survival-kit/workbench-anvil", Vector3(0, 0, 0), -PI * 0.5, 3.4)
	var m := b.find_child("hammer", true, false)
	if m:
		m.visible = false
	# o martelo grande, a um dedo da bigorna (a cabeça é a origem do modelo)
	var h := Mundo.peca(self, "survival-kit/tool-hammer-upgraded", Vector3(-0.2, 0.86, 0.1), 0.0, 4.6)
	h.rotation_degrees = Vector3(0, 0, -52)
	Mundo.foco(self, Vector3(-0.6, 5.0, 2.4), Vector3(0, 0.9, 0), Fita.TUNGSTENIO, 6.0, 26.0, 10.0)
	var contra := DirectionalLight3D.new()
	add_child(contra)
	contra.rotation_degrees = Vector3(-20, 150, 0)
	contra.light_color = Color("#8a7cff")
	contra.light_energy = 0.5
	_faiscas(Vector3(0.0, 1.16, 0.05))
	Mundo.neon_sem_sombra(self)
	Mundo.pos(self, 15, {"aberracao": 2.2, "rasgo": 0.07, "semente": 11.0, "varredura": 0.1, "grao": 0.03})
	Hud.camada(self, _hud, 10)


## As faíscas do golpe: luz de lâmpada, sem dono (ninguém bateu ainda).
func _faiscas(c: Vector3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 30:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.1, 1.3), rng.randf_range(-0.5, 0.8)).normalized()
		var p := c + d * rng.randf_range(0.15, 0.9)
		var s := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.025, rng.randf_range(0.05, 0.14), 0.025)
		s.mesh = bm
		s.material_override = Fita.neon(Fita.TUNGSTENIO, 2.4)
		add_child(s)
		s.position = p
		s.look_at(p + d, Vector3.FORWARD if absf(d.y) > 0.99 else Vector3.UP)
		s.rotate_object_local(Vector3.RIGHT, PI * 0.5)


func _hud(ci: CanvasItem) -> void:
	var tinta: Color = Fita.SECAO[0]
	# a cortina impressa, com o corte em diagonal; a trama da impressão por cima
	var corte := PackedVector2Array([Vector2(0, 0), Vector2(1240, 0), Vector2(930, 1080), Vector2(0, 1080)])
	ci.draw_colored_polygon(corte, tinta)
	for y in range(0, 1080, 6):
		var x_fim := lerpf(1240.0, 930.0, y / 1080.0)
		ci.draw_line(Vector2(0, y), Vector2(x_fim, y), tinta.darkened(0.12), 2.0)
	# a borda do corte: a fita (a tira escura com o fio de papel)
	ci.draw_line(Vector2(1240, 0), Vector2(930, 1080), Fita.FITA, 26.0)
	ci.draw_line(Vector2(1262, 0), Vector2(952, 1080), Fita.ETIQUETA, 4.0)
	# a faixa: o número e o andamento, impressos
	Hud.texto(ci, Fita.vt(), 56, Vector2(110, 120), "LADO A  ·  FAIXA 01  ·  120 BPM", Fita.ETIQUETA)
	Hud.texto(ci, Fita.marcador(), 72, Vector2(104, 186), "O Martelo de Hefesto", Fita.FITA)
	# o verbo: gigante, a cavalo do corte; os ecos são o pulso da batida
	var f := Fita.bungee()
	var tam := 252
	var w := Hud.largura_do(f, tam, VERBO)
	var centro := Vector2(905, 560)
	for k in [2, 1]:
		var esc: float = 1.0 + k * 0.07
		ci.draw_set_transform(centro, -0.045, Vector2(esc, esc))
		Hud.texto(ci, f, tam, Vector2(-w * 0.5, -tam * 0.5), VERBO, Color(Fita.ETIQUETA, 0.16 / float(k)))
	ci.draw_set_transform(centro, -0.045, Vector2.ONE)
	# o desregistro da impressão: a chapa escura escorregou para baixo
	Hud.texto(ci, f, tam, Vector2(-w * 0.5 + 16, -tam * 0.5 + 18), VERBO, Fita.FITA)
	Hud.texto(ci, f, tam, Vector2(-w * 0.5, -tam * 0.5), VERBO, Fita.ETIQUETA)
	# (o tremor do cabeçote, as fatias que escorregam, é o rasgo do pós)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# o como-se-joga, uma linha, com o botão
	var r := Rect2(110, 900, 760, 76)
	Hud.caixa(ci, Rect2(r.position + Vector2(6, 8), r.size), Color(0, 0, 0, 0.35), 10)
	Hud.caixa(ci, r, Fita.ETIQUETA, 10)
	Hud.glifo(ci, "cross", Rect2(r.position + Vector2(16, 12), Vector2(52, 52)), Fita.TINTA)
	Hud.texto(ci, Fita.archivo(700), 38, r.position + Vector2(84, 14), "Bata no tempo do bumbo", Fita.TINTA)
	Hud.texto(ci, Fita.vt(), 44, Vector2(1100, 990), "TODOS CONTRA TODOS", Color(Fita.ETIQUETA, 0.85), HORIZONTAL_ALIGNMENT_RIGHT, 710)
