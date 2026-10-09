extends Node3D
## Quadro 13 — A luz das cinco tintas (01; PRODUCAO, item 4): a mesma arena
## (a Centelha) e a mesma câmera (35 mm, plongée de 50°) nas cinco tintas. A
## tinta pinta a névoa, o preenchimento e esquenta a chave; não pinta o
## cavaleiro. A coluna da direita é o lado B: a chave a ×0,85 e a névoa a
## ×1,3, e a etiqueta com a tarja dupla.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")
const Prancha := preload("res://estudos/direcao/prancha.gd")
const Cena := preload("res://estudos/direcao/cena_centelha.gd")

var espera := 12
var arquivo := "13_luz"
var folha: SubViewport
## A tabela de luz do 01: a tinta, a névoa, o preenchimento e a chave.
const TINTAS := [
	{"nome": "vermelhão", "nevoa": Color("#210502"), "preench": Color("#602016"), "chave": Color("#ffc99c"), "a": "S1 A Centelha", "b": "S9 A Prova"},
	{"nome": "cobalto", "nevoa": Color("#050d26"), "preench": Color("#1f346a"), "chave": Color("#e5d3c6"), "a": "S2 A Viga", "b": "S6 O Canto"},
	{"nome": "petróleo", "nevoa": Color("#011311"), "preench": Color("#11413b"), "chave": Color("#e5d7ad"), "a": "S3 O Molde", "b": "S7 Os Caminhos"},
	{"nome": "mostarda", "nevoa": Color("#170e00"), "preench": Color("#493400"), "chave": Color("#f8d096"), "a": "S4 O Impacto", "b": "o pódio"},
	{"nome": "ameixa", "nevoa": Color("#18081c"), "preench": Color("#4a2854"), "chave": Color("#f8ccba"), "a": "S5 A Galeria", "b": "S8 A Voz"},
]
const NEVOA_A := 0.016
const CEL := Vector2i(960, 540)


class Olho:
	func olhar(_p: Vector3, _a: Vector3, _f: float) -> void:
		pass


func montar(_estudo) -> void:
	folha = Prancha.folha(self, Vector2i(1920, 2700), Fita.FITA)
	for linha in 5:
		for lado in 2:
			var vp := Prancha.celula(self, CEL)
			_celula(vp, linha, lado == 1)
			Prancha.pregar(folha, vp, Rect2(lado * CEL.x, linha * CEL.y, CEL.x, CEL.y))
	Prancha.por_cima(folha, _etiquetas)


func foto() -> Image:
	return await Prancha.foto(folha)


func _celula(vp: SubViewport, linha: int, lado_b: bool) -> void:
	var raiz := Node3D.new()
	vp.add_child(raiz)
	Cena.montar(raiz, Olho.new())
	var t: Dictionary = TINTAS[linha]
	for we in raiz.find_children("*", "WorldEnvironment", false, false):
		var env: Environment = we.environment
		env.fog_light_color = t.nevoa
		env.fog_density = NEVOA_A * (1.3 if lado_b else 1.0)
		env.ambient_light_color = t.preench
	# a chave: os focos de lâmpada da cena viram a chave da tinta
	for l in raiz.find_children("*", "SpotLight3D", true, false):
		var s: SpotLight3D = l
		if s.light_color.is_equal_approx(Fita.TUNGSTENIO):
			s.light_color = t.chave
			s.light_energy *= 0.85 if lado_b else 1.0
	for l in raiz.find_children("*", "DirectionalLight3D", false, false):
		(l as DirectionalLight3D).light_color = t.preench.lightened(0.5)
	var cam := Prancha.camera(vp)
	Prancha.lente(cam, 35.0)
	var alvo := Vector3(0, 0.6, 0.2)
	var d := 17.0
	var a := deg_to_rad(50.0)
	cam.position = alvo + Vector3(0, d * sin(a), d * cos(a))
	cam.look_at(alvo)
	Mundo.pos(vp, 5, {"grao": 0.02})


func _etiquetas(ci: CanvasItem) -> void:
	for linha in 5:
		for lado in 2:
			var t: Dictionary = TINTAS[linha]
			var tinta: Color = Fita.SECAO[linha]
			var o := Vector2(lado * CEL.x, linha * CEL.y)
			var et := Rect2(o + Vector2(24, 22), Vector2(330, 92))
			ci.draw_set_transform(et.get_center(), -0.012, Vector2.ONE)
			var r := Rect2(-et.size * 0.5, et.size)
			Hud.caixa(ci, Rect2(r.position + Vector2(4, 6), r.size), Fita.SOMBRA, 6)
			Hud.caixa(ci, r, Fita.ETIQUETA, 6)
			if lado == 0:
				ci.draw_rect(Rect2(r.position + Vector2(0, 10), Vector2(r.size.x, 12)), tinta)
			else:
				ci.draw_rect(Rect2(r.position + Vector2(0, 8), Vector2(r.size.x, 7)), tinta)
				ci.draw_rect(Rect2(r.position + Vector2(0, 19), Vector2(r.size.x, 7)), tinta)
			Hud.texto(ci, Fita.marcador(), 30, r.position + Vector2(14, 28), String(t.b if lado == 1 else t.a), Fita.TINTA)
			Hud.texto(ci, Fita.vt(), 24, r.position + Vector2(14, 64), "LADO %s  ·  %s" % ["B" if lado == 1 else "A", t.nome.to_upper()], Fita.TINTA_SUAVE)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)  # a etiqueta torta não entorta o resto
			# os valores, embaixo
			var v := "chave %s ×%s · névoa %s ×%s · preench. %s" % [t.chave.to_html(false), "0,85" if lado == 1 else "1", t.nevoa.to_html(false), "1,3" if lado == 1 else "1", t.preench.to_html(false)]
			ci.draw_rect(Rect2(o + Vector2(0, CEL.y - 40), Vector2(CEL.x, 40)), Color(Fita.FITA, 0.8))
			Hud.texto(ci, Fita.vt(), 24, o + Vector2(16, CEL.y - 36), v, Fita.ETIQUETA)
			ci.draw_rect(Rect2(o, Vector2(CEL)), Fita.FITA, false, 2.0)
