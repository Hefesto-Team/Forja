extends Node3D
## Quadro 16 — A bigorna própria (PRODUCAO, item 8): a malha por código
## (bigorna.gd), em quatro vistas, e ao lado a workbench-anvil do Survival
## Kit nas mesmas quatro. De lado, a silhueta mostra o chifre separado do
## corpo por um vão; na câmera do jogo (35 mm, plongée de 50°), o chifre se
## vê sem procurar.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")
const Prancha := preload("res://estudos/direcao/prancha.gd")
const Bigorna := preload("res://estudos/direcao/bigorna.gd")

var espera := 10
var arquivo := "16_bigorna"
var folha: SubViewport
const VISTAS := ["De lado", "3/4", "De cima", "Câmera do jogo"]
const CEL := Vector2i(420, 330)
const X0 := 112.0
const PASSO_X := 436.0
const LINHAS_Y := [212.0, 640.0]


func montar(_estudo) -> void:
	folha = Prancha.folha(self, Vector2i(1920, 1080), Fita.FITA)
	for linha in 2:
		for v in 4:
			var vp := Prancha.celula(self, CEL * 2)
			_cena(vp, linha == 0, v)
			Prancha.pregar(folha, vp, Rect2(X0 + v * PASSO_X, LINHAS_Y[linha], CEL.x, CEL.y))
	Prancha.por_cima(folha, _texto)


func foto() -> Image:
	return await Prancha.foto(folha)


func _cena(vp: SubViewport, propria: bool, vista: int) -> void:
	var raiz := Node3D.new()
	vp.add_child(raiz)
	var jogo := vista == 3
	Mundo.ambiente(raiz, {"ambiente": Color("#2a2738"), "ambiente_energia": 0.45, "nevoa": jogo,
		"fundo": Fita.CASCO, "glow_intensidade": 0.5})
	var obj: Node3D
	if propria:
		var mi := MeshInstance3D.new()
		mi.mesh = Bigorna.malha()
		mi.scale = Vector3.ONE * Mundo.K
		raiz.add_child(mi)
		obj = mi
	else:
		obj = Mundo.peca(raiz, "survival-kit/workbench-anvil", Vector3.ZERO, 0.0)
		var martelo := obj.find_child("hammer", true, false)
		if martelo:
			martelo.visible = false
	var sol := DirectionalLight3D.new()
	raiz.add_child(sol)
	sol.rotation_degrees = Vector3(-50, -35, 0)
	sol.light_color = Fita.TUNGSTENIO
	sol.light_energy = 1.1
	sol.shadow_enabled = jogo
	var contra := DirectionalLight3D.new()
	raiz.add_child(contra)
	contra.rotation_degrees = Vector3(-25, 150, 0)
	contra.light_color = Color("#8a7cff")
	contra.light_energy = 0.45
	var cam := Prancha.camera(vp)
	var alto := 0.3 * Mundo.K if propria else 0.34 * Mundo.K * 1.4
	match vista:
		0:
			cam.projection = Camera3D.PROJECTION_ORTHOGONAL
			cam.size = 1.25
			cam.position = Vector3(0, alto * 0.5, 6)
			cam.look_at(Vector3(0, alto * 0.5, 0))
		1:
			Prancha.lente(cam, 50.0)
			cam.position = Vector3(2.4, 1.7, 2.6)
			cam.look_at(Vector3(0, alto * 0.45, 0))
		2:
			cam.projection = Camera3D.PROJECTION_ORTHOGONAL
			cam.size = 1.25
			cam.position = Vector3(0, 6, 0.001)
			cam.look_at(Vector3.ZERO, Vector3.FORWARD)
		3:
			# o chão da arena, um cavaleiro ao lado para a escala, e a câmera
			# do jogo: 35 mm, plongée de 50°, de cima e de frente como na Centelha
			for i in range(-2, 3):
				for j in range(-2, 2):
					Mundo.peca(raiz, "mini-dungeon/floor", Vector3(i * 2.0, 0, j * 2.0))
			Mundo.cavaleiro(raiz, 0, Vector3(-0.95, 0, 0.35), 0.5, "idle", 0.3, "", {"martelo": true})
			if propria:
				_contorno_da_propria(obj)
			else:
				Mundo.contornar(obj, Fita.JOGADOR[0], 0.010, 1.6)
			Prancha.lente(cam, 35.0)
			var d := 4.2
			var a := deg_to_rad(50.0)
			cam.position = Vector3(0.0, d * sin(a), d * cos(a))
			cam.look_at(Vector3(-0.3, 0.3, 0))
			Mundo.neon_sem_sombra(raiz)
			Mundo.pos(vp, 5, {"grao": 0.02})


## O contorno de dono numa MeshInstance avulsa (o Mundo.contornar anda pelos
## filhos).
func _contorno_da_propria(mi: MeshInstance3D) -> void:
	var m: Material = Bigorna.material().duplicate()
	m.next_pass = Fita.contorno(Fita.JOGADOR[0], 0.006, 1.6)
	mi.material_override = m


func _texto(ci: CanvasItem) -> void:
	Hud.etiqueta(ci, Rect2(56, 28, 640, 140), "A bigorna própria", "PRANCHA  ·  ITEM 8", Fita.SECAO[0], 52, -0.01)
	Hud.texto(ci, Fita.archivo(500), 30, Vector2(760, 52), "%d triângulos, por código (ArrayMesh), sombreamento chapado." % Bigorna.triangulos(), Color(Fita.ETIQUETA, 0.85))
	Hud.texto(ci, Fita.archivo(500), 30, Vector2(760, 94), "A cor: o colormap do Survival Kit no papel «objeto», metallic 0,2.", Color(Fita.ETIQUETA, 0.85))
	for linha in 2:
		var y: float = LINHAS_Y[linha]
		Hud.texto(ci, Fita.archivo(600), 30, Vector2(X0, y - 42), "A da Forja: 0,30 de altura, face de 0,46, chifre de 8 lados" if linha == 0 else "A workbench-anvil da Kenney (Survival Kit), recolorida", Fita.ETIQUETA)
		for v in 4:
			var r := Rect2(X0 + v * PASSO_X, y, CEL.x, CEL.y)
			ci.draw_rect(r, Fita.GRAFITE, false, 2.0)
			Hud.texto(ci, Fita.vt(), 30, Vector2(r.position.x + 4, r.end.y + 4), VISTAS[v] + ("  ·  35 mm, 50°" if v == 3 else ""), Fita.MUDO)
