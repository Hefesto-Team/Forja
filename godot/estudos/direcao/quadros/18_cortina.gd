extends Node3D
## Quadro 18 — A cortina diagonal (06; PRODUCAO, item 11): seis instantes da
## entrada de um minigame, cada um uma célula de 960×540 com o mundo, a
## cortina e o pós da fita (o `rasgo` e a `aberracao` daquele instante).
## A geometria é a do 06: o polígono (0, 0), (1240, 0), (930, 1080),
## (0, 1080), a borda a 16,0° da vertical, a tira FITA de 26 px e o fio
## ETIQUETA de 4 px a 22 px dela. O impacto é no tempo 1, aos 600 ms.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")
const Prancha := preload("res://estudos/direcao/prancha.gd")

var espera := 10
var arquivo := "18_cortina"
var folha: SubViewport
const VERBO := "MARTELE!"
const BORDA_X0 := -330.0
const BORDA_X1 := 1240.0
const INCLINA := 310.0  # 1080 · tan(16,0°)
## Cada instante: o tempo, a borda (x no alto da tela), a escala do verbo, os
## ecos, o tremor, o rasgo e a aberração, e a linha que vai embaixo.
var INSTANTES := [
	{"ms": 0, "borda": _borda(0.0), "verbo": 0.0, "rasgo": 0.0, "aberracao": 0.0,
		"nota": "0 ms · a borda em x = −330 · rasgo 0 · fx_entrada começa"},
	{"ms": 300, "borda": _borda(0.5), "verbo": 0.0, "rasgo": 0.175, "aberracao": 1.1,
		"nota": "300 ms · ENTRA na metade: x = −134 (ainda fora) · rasgo 0,175"},
	{"ms": 600, "borda": BORDA_X1, "verbo": 1.35, "tremor": 8.0, "rasgo": 0.35, "aberracao": 2.2,
		"nota": "600 ms · o tempo 1: o verbo carimba a 1,35 · tremor 8 px · rasgo 0,35"},
	{"ms": 680, "borda": BORDA_X1, "verbo": 1.0, "rasgo": 0.126, "aberracao": 0.8,
		"nota": "680 ms · MOLA chega a 1,0 · rasgo caindo: 0,126 (a 0,07 em 6 quadros)"},
	{"ms": 900, "borda": BORDA_X1, "verbo": 1.0, "ecos": true, "rasgo": 0.07, "aberracao": 0.44,
		"nota": "900 ms · o verbo segura, ecos 1,07 e 1,14 (0,16 e 0,08) · rasgo 0,07"},
	{"ms": -1, "borda": BORDA_X1, "verbo": 1.0, "sai": 0.75, "jcard": 0.75, "rasgo": 0.0, "aberracao": 0.0,
		"nota": "o tempo 1 seguinte + 3/4 de batida · a cortina sai (ENTRA), o J-card entra"},
]


static func _borda(t: float) -> float:
	return lerpf(BORDA_X0, BORDA_X1, t * t * t)  # ENTRA: cúbica, acelerando


func montar(_estudo) -> void:
	folha = Prancha.folha(self, Vector2i(1920, 1620), Fita.FITA)
	for k in 6:
		var vp := Prancha.celula(self, Vector2i(960, 540))
		var raiz := Node3D.new()
		vp.add_child(raiz)
		_mundo(raiz, Prancha.camera(vp))
		var inst: Dictionary = INSTANTES[k]
		Hud.camada(raiz, func(ci): _cortina(ci, inst), 10)
		Mundo.pos(raiz, 15, {"aberracao": inst.aberracao, "rasgo": inst.rasgo, "semente": 11.0 + k, "varredura": 0.1, "grao": 0.03})
		Prancha.pregar(folha, vp, Rect2((k % 2) * 960, (k / 2) * 540, 960, 540))
	Prancha.por_cima(folha, _notas)


func foto() -> Image:
	return await Prancha.foto(folha)


## O mundo do 03: a bigorna e o martelo no meio do golpe, na luz de lâmpada.
func _mundo(raiz: Node3D, cam: Camera3D) -> void:
	cam.fov = 34.0
	cam.position = Vector3(-1.2, 2.1, 3.6)
	cam.look_at(Vector3(-1.3, 0.85, 0.0))
	Mundo.ambiente(raiz, {"ambiente": Color("#2a2738"), "ambiente_energia": 0.25, "nevoa": false, "glow_intensidade": 0.9})
	for i in range(-2, 4):
		for j in range(-3, 2):
			Mundo.peca(raiz, "mini-dungeon/floor", Vector3(i * 2.0, 0, j * 2.0), (i + j) % 4 * PI * 0.5)
	var b := Mundo.peca(raiz, "survival-kit/workbench-anvil", Vector3(0, 0, 0), -PI * 0.5, 3.4)
	var m := b.find_child("hammer", true, false)
	if m:
		m.visible = false
	var h := Mundo.peca(raiz, "survival-kit/tool-hammer-upgraded", Vector3(-0.2, 0.86, 0.1), 0.0, 4.6)
	h.rotation_degrees = Vector3(0, 0, -52)
	Mundo.foco(raiz, Vector3(-0.6, 5.0, 2.4), Vector3(0, 0.9, 0), Fita.TUNGSTENIO, 6.0, 26.0, 10.0)
	var contra := DirectionalLight3D.new()
	raiz.add_child(contra)
	contra.rotation_degrees = Vector3(-20, 150, 0)
	contra.light_color = Color("#8a7cff")
	contra.light_energy = 0.5
	Mundo.neon_sem_sombra(raiz)


## A cortina num instante, em px da tela de 1920×1080.
func _cortina(ci: CanvasItem, inst: Dictionary) -> void:
	var tinta: Color = Fita.SECAO[0]
	var dx: float = inst.borda - BORDA_X1
	var sai := float(inst.get("sai", 0.0))
	dx += 2240.0 * sai * sai * sai  # ENTRA: sai pela direita em 1 batida (a borda anda 2240 px)
	var tremor := Vector2(float(inst.get("tremor", 0.0)), -float(inst.get("tremor", 0.0)) * 0.5)
	ci.draw_set_transform(tremor, 0.0, Vector2.ONE)
	var corte := PackedVector2Array([Vector2(dx - 4000, 0), Vector2(BORDA_X1 + dx, 0), Vector2(BORDA_X1 - INCLINA + dx, 1080), Vector2(dx - 4000, 1080)])
	ci.draw_colored_polygon(corte, tinta)
	for y in range(0, 1080, 6):
		var x_fim := lerpf(BORDA_X1, BORDA_X1 - INCLINA, y / 1080.0) + dx
		ci.draw_line(Vector2(maxf(dx - 4000, -10), y), Vector2(x_fim, y), tinta.darkened(0.12), 2.0)
	ci.draw_line(Vector2(BORDA_X1 + dx, 0), Vector2(BORDA_X1 - INCLINA + dx, 1080), Fita.FITA, 26.0)
	ci.draw_line(Vector2(BORDA_X1 + 22 + dx, 0), Vector2(BORDA_X1 - INCLINA + 22 + dx, 1080), Fita.ETIQUETA, 4.0)
	if float(inst.verbo) > 0.0:
		Hud.texto(ci, Fita.vt(), 56, Vector2(110 + dx, 120), "LADO A  ·  FAIXA 01  ·  120 BPM", Fita.ETIQUETA)
		Hud.texto(ci, Fita.marcador(), 72, Vector2(104 + dx, 186), "O Martelo de Hefesto", Fita.FITA)
		var f := Fita.bungee()
		var tam := 252
		var w := Hud.largura_do(f, tam, VERBO)
		var centro := Vector2(905 + dx, 560) + tremor
		if inst.get("ecos", false):
			for k in [2, 1]:
				var esc: float = 1.0 + k * 0.07
				ci.draw_set_transform(centro, -0.045, Vector2(esc, esc))
				Hud.texto(ci, f, tam, Vector2(-w * 0.5, -tam * 0.5), VERBO, Color(Fita.ETIQUETA, 0.16 / float(k)))
		var e: float = inst.verbo
		ci.draw_set_transform(centro, -0.045, Vector2(e, e))
		Hud.texto(ci, f, tam, Vector2(-w * 0.5 + 16, -tam * 0.5 + 18), VERBO, Fita.FITA)
		Hud.texto(ci, f, tam, Vector2(-w * 0.5, -tam * 0.5), VERBO, Fita.ETIQUETA)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if inst.has("jcard"):
		# o J-card chega da direita a (760, 90), 1064 × 830, com a lombada
		var t: float = inst.jcard
		var chega := 1.0 - pow(1.0 - t, 3.0)
		var r := Rect2(Vector2(lerpf(1960.0, 760.0, chega), 90), Vector2(1064, 830))
		Hud.caixa(ci, Rect2(r.position + Vector2(8, 12), r.size), Fita.SOMBRA, 8)
		Hud.caixa(ci, r, Fita.ETIQUETA, 8)
		ci.draw_rect(Rect2(r.position, Vector2(96, r.size.y)), Fita.ETIQUETA_SOMBRA)
		ci.draw_rect(Rect2(r.position + Vector2(96, 30), Vector2(r.size.x - 96, 16)), tinta)
		Hud.texto(ci, Fita.marcador(), 64, r.position + Vector2(130, 70), "O Martelo de Hefesto", Fita.TINTA)
		Hud.texto(ci, Fita.vt(), 40, r.position + Vector2(132, 160), "LADO A  ·  FAIXA 01", Fita.TINTA_SUAVE)
		for i in 3:
			ci.draw_line(r.position + Vector2(130, 260 + i * 70), r.position + Vector2(r.size.x - 40, 260 + i * 70), Fita.ETIQUETA_SOMBRA, 2.0)


func _notas(ci: CanvasItem) -> void:
	for k in 6:
		var r := Rect2((k % 2) * 960, (k / 2) * 540, 960, 540)
		ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 44), Vector2(r.size.x, 44)), Color(Fita.FITA, 0.86))
		Hud.texto(ci, Fita.vt(), 26, r.position + Vector2(16, r.size.y - 38), INSTANTES[k].nota, Fita.ETIQUETA)
		ci.draw_rect(r, Fita.GRAFITE, false, 2.0)
