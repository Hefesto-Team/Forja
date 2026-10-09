extends Node3D
## Quadro 17 — A forja na batida (PRODUCAO, item 10). Em cima, as quatro
## fases de uma martelada (05): antecipação, impacto, parada e recuperação,
## com a escala do corpo de cada uma e a pose do golpe no contato medido
## (dados/contatos.csv: attack-melee-right acerta aos 0,208 s). Embaixo, as
## 8 marteladas da forja (04), cada uma acendendo em tungstênio a parte da
## tabela; o número de cada quadro em batidas e em ms a 120 BPM.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")
const Prancha := preload("res://estudos/direcao/prancha.gd")
const Montar := preload("res://estudos/direcao/cavaleiro/montar.gd")
const Bigorna := preload("res://estudos/direcao/bigorna.gd")

var espera := 10
var arquivo := "17_forja"
var folha: SubViewport
const PECAS := ["male-c", "female-f", "male-a"]
const CONTATO := 0.208
## As fases: o nome, o instante da animação, a escala do corpo, o tempo.
const FASES := [
	{"nome": "Antecipação", "t": 0.11, "escala": Vector3(1.0, 0.96, 1.0), "batida": "−0,5 batida", "ms": "−250 ms", "nota": "Y 0,96, o braço recua 10°, ENTRA"},
	{"nome": "Impacto", "t": CONTATO, "escala": Vector3(1.12, 0.80, 1.12), "batida": "0 (o tempo)", "ms": "0 ms", "nota": "Y 0,80, X e Z 1,12, 3 quadros"},
	{"nome": "Parada", "t": CONTATO, "escala": Vector3(1.12, 0.80, 1.12), "batida": "+0,1 batida", "ms": "+50 ms", "nota": "congela 2 quadros (Ressonância!)"},
	{"nome": "Recuperação", "t": 0.27, "escala": Vector3(0.97, 1.06, 0.97), "batida": "+0,17 batida", "ms": "+83 ms", "nota": "Y 1,06, X e Z 0,97, volta em MOLA"},
]
## A forja: o que cada martelada acende.
const ACENDE := ["a cabeça", "a cabeça", "o superior", "o superior", "o inferior", "o inferior", "a arma", "o nome"]
const CEL_A := Vector2i(440, 440)
const CEL_B := Vector2i(214, 300)
const Y_A := 180.0
const Y_B := 790.0


func montar(_estudo) -> void:
	folha = Prancha.folha(self, Vector2i(1920, 1250), Fita.FITA)
	for k in 4:
		var vp := Prancha.celula(self, CEL_A * 2)
		_fase(vp, FASES[k], k == 1)
		Prancha.pregar(folha, vp, Rect2(_xa(k), Y_A, CEL_A.x, CEL_A.y))
	for k in 8:
		var vp := Prancha.celula(self, CEL_B * 2)
		_martelada(vp, k + 1)
		Prancha.pregar(folha, vp, Rect2(_xb(k), Y_B, CEL_B.x, CEL_B.y))
	Prancha.por_cima(folha, _texto)


func foto() -> Image:
	return await Prancha.foto(folha)


func _xa(k: int) -> float:
	return 50.0 + k * (CEL_A.x + 20.0)


func _xb(k: int) -> float:
	return 58.0 + k * (CEL_B.x + 12.0)


func _palco(raiz: Node3D, chave: Color, energia: float) -> void:
	Mundo.ambiente(raiz, {"ambiente": Color("#2a2738"), "ambiente_energia": 0.35, "fundo": Fita.CASCO, "glow_intensidade": 0.6})
	for i in range(-2, 3):
		for j in range(-2, 2):
			Mundo.peca(raiz, "mini-dungeon/floor", Vector3(i * 2.0, 0, j * 2.0))
	Mundo.foco(raiz, Vector3(1.4, 4.0, 3.0), Vector3(0, 0.8, 0), chave, energia, 26.0, 9.0, true)
	var contra := DirectionalLight3D.new()
	raiz.add_child(contra)
	contra.rotation_degrees = Vector3(-25, 160, 0)
	contra.light_color = Color("#8a7cff")
	contra.light_energy = 0.4


func _fase(vp: SubViewport, f: Dictionary, faiscas: bool) -> void:
	var raiz := Node3D.new()
	vp.add_child(raiz)
	_palco(raiz, Fita.TUNGSTENIO, 4.5)
	var c := Montar.cavaleiro(raiz, 0, Vector3(-0.35, 0, 0), PECAS, {"item": "martelo", "anim": "attack-melee-right",
		"t_anim": f.t, "anel": false, "yaw": 0.55})
	c.scale = f.escala
	var b := MeshInstance3D.new()
	b.mesh = Bigorna.malha()
	b.scale = Vector3.ONE * Mundo.K
	b.position = Vector3(0.75, 0, 0.55)
	b.rotation.y = -0.4
	raiz.add_child(b)
	if faiscas:
		Mundo.luz(raiz, Vector3(0.7, 0.75, 0.65), Fita.TUNGSTENIO, 2.5, 2.2)
	Mundo.neon_sem_sombra(raiz)
	var cam := Prancha.camera(vp)
	Prancha.lente(cam, 50.0)
	cam.position = Vector3(0.4, 1.5, 5.2)
	cam.look_at(Vector3(0.15, 0.75, 0))
	Mundo.pos(vp, 5, {"grao": 0.02})


## A martelada n: as partes já forjadas acesas (contorno de lâmpada), as que
## faltam em grafite, e na oitava a chave inteira em tungstênio.
func _martelada(vp: SubViewport, n: int) -> void:
	var raiz := Node3D.new()
	vp.add_child(raiz)
	var feito := n == 8
	## A chave é sempre tungstênio: o violeta pintava a peça que entra. O que falta
	## fica em GRAFITE; a peça desta martelada ganha o contorno de lâmpada.
	_palco(raiz, Fita.TUNGSTENIO, 5.0 if feito else 3.5)
	var c := Montar.cavaleiro(raiz, 0, Vector3.ZERO, PECAS, {"item": "martelo", "anim": "holding-right", "t_anim": 0.1, "anel": false})
	var esq: Skeleton3D = c.find_child("Skeleton3D", true, false)
	var acesas := {"head": n >= 1, "body-sup": n >= 3, "body-inf": n >= 5}
	for parte in acesas:
		var mi: MeshInstance3D = esq.get_node(parte)
		_acender(mi, acesas[parte], _agora(parte, n))
	for ba in esq.find_children("*", "BoneAttachment3D", false, false):
		for mi in ba.find_children("*", "MeshInstance3D", true, false):
			_acender(mi, n >= 7, n == 7)
	Mundo.neon_sem_sombra(raiz)
	var cam := Prancha.camera(vp)
	Prancha.lente(cam, 50.0)
	cam.position = Vector3(0, 1.0, 4.6)
	cam.look_at(Vector3(0, 0.8, 0))
	Mundo.pos(vp, 5, {"grao": 0.02})


func _agora(parte: String, n: int) -> bool:
	return {"head": n in [1, 2], "body-sup": n in [3, 4], "body-inf": n in [5, 6]}[parte]


func _acender(mi: MeshInstance3D, acesa: bool, agora: bool) -> void:
	if not acesa:
		mi.material_override = Fita.fosco(Fita.GRAFITE)
		return
	if not agora:
		return
	# o acento (friso, costura, runa) já é néon, com material próprio: fica
	if mi.material_override != null:
		return
	for s in mi.mesh.get_surface_count():
		var base: Material = mi.get_surface_override_material(s)
		if base == null:
			base = mi.mesh.surface_get_material(s)
		if base == null:
			continue
		var m: Material = base.duplicate()
		m.next_pass = Fita.contorno(Fita.TUNGSTENIO, 0.016, 3.0)
		mi.set_surface_override_material(s, m)


func _texto(ci: CanvasItem) -> void:
	Hud.etiqueta(ci, Rect2(56, 20, 640, 140), "A forja na batida", "PRANCHA  ·  ITEM 10", Fita.SECAO[0], 52, -0.01)
	Hud.texto(ci, Fita.archivo(500), 30, Vector2(760, 40), "Em cima: as quatro fases de uma martelada, o impacto no tempo.", Color(Fita.ETIQUETA, 0.85))
	Hud.texto(ci, Fita.archivo(500), 30, Vector2(760, 82), "Embaixo: as 8 marteladas da forja a 120 BPM, uma por batida.", Color(Fita.ETIQUETA, 0.85))
	Hud.texto(ci, Fita.archivo(500), 30, Vector2(760, 124), "O contato do golpe vem de dados/contatos.csv (0,208 s).", Color(Fita.ETIQUETA, 0.85))
	for k in 4:
		var f: Dictionary = FASES[k]
		var x := _xa(k)
		ci.draw_rect(Rect2(x, Y_A, CEL_A.x, CEL_A.y), Fita.GRAFITE, false, 2.0)
		Hud.texto(ci, Fita.archivo(600), 30, Vector2(x, Y_A + CEL_A.y + 8), f.nome, Fita.ETIQUETA)
		Hud.texto(ci, Fita.vt(), 30, Vector2(x, Y_A + CEL_A.y + 8), "%s · %s" % [f.batida, f.ms], Fita.TUNGSTENIO, HORIZONTAL_ALIGNMENT_RIGHT, CEL_A.x)
		Hud.texto(ci, Fita.vt(), 26, Vector2(x, Y_A + CEL_A.y + 48), f.nota, Fita.MUDO)
	for k in 8:
		var x := _xb(k)
		ci.draw_rect(Rect2(x, Y_B, CEL_B.x, CEL_B.y), Fita.TUNGSTENIO if k == 7 else Fita.GRAFITE, false, 2.0)
		# a etiqueta da coluna: o nome sai na oitava, a caneta
		var et := Rect2(x + 14, Y_B + CEL_B.y - 52, CEL_B.x - 28, 40)
		Hud.caixa(ci, et, Fita.ETIQUETA, 5)
		if k == 7:
			Hud.texto(ci, Fita.marcador(), 28, et.position + Vector2(0, 2), "Basalto", Fita.TINTA, HORIZONTAL_ALIGNMENT_CENTER, et.size.x)
		Hud.texto(ci, Fita.vt(), 30, Vector2(x, Y_B + CEL_B.y + 8), "%d · %d ms" % [k + 1, k * 500], Fita.ETIQUETA, HORIZONTAL_ALIGNMENT_CENTER, CEL_B.x)
		Hud.texto(ci, Fita.archivo(500), 26, Vector2(x, Y_B + CEL_B.y + 46), ACENDE[k], Fita.MUDO, HORIZONTAL_ALIGNMENT_CENTER, CEL_B.x)
