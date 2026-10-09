extends Node3D
## Quadro 19 — As raças (PRODUCAO, item 16; 04, as raças): cinco linhas
## (Humana, Orc, Autômato, Golem, Raposa) por quatro colunas (P1 a P4), cada
## cavaleiro de frente e a 3/4, com o contorno e o acento do lugar. Embaixo, o
## teste do 04: as cinco cabeças a 64 px, em cinza (a L do OKLab) e na
## silhueta em preto chapado. 1920×1440, câmera ortográfica.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")
const Prancha := preload("res://estudos/direcao/prancha.gd")
const Montar := preload("res://estudos/direcao/cavaleiro/montar.gd")
const Racas := preload("res://estudos/direcao/cavaleiro/racas.gd")

var espera := 10
var arquivo := "19_racas"
var folha: SubViewport
const TAM := Vector2i(1920, 1440)
const ESCALA := 0.0086          ## metros por píxel
const X0 := 230.0               ## onde começam as colunas (à esquerda, o nome da raça)
const COL := 410.0
const LINHA_Y := 192.0          ## o topo da primeira linha
const LINHA_H := 186.0
const TESTE_Y := 1140.0         ## o topo do teste de 64 px
const TESTE_DX := 330.0         ## de uma raça à outra no teste
## As peças de cada cavaleiro: [cabeça (o perfil), superior, inferior], por
## raça e por lugar. O perfil dá a marca (a cor do cabelo dele).
const PECAS := {
	"humana": [["male-c", "female-f", "male-a"], ["female-b", "male-b", "female-d"], ["male-e", "female-c", "male-d"], ["female-a", "male-d", "female-e"]],
	"orc": [["male-a", "male-e", "male-b"], ["female-c", "female-a", "male-f"], ["male-f", "male-c", "female-b"], ["female-e", "female-d", "male-c"]],
	"automato": [["female-d", "male-a", "female-c"], ["male-b", "female-e", "male-e"], ["female-f", "male-f", "female-a"], ["male-d", "female-b", "male-a"]],
	"golem": [["male-b", "male-d", "female-f"], ["female-a", "male-c", "male-d"], ["male-c", "female-b", "female-e"], ["female-b", "male-a", "male-f"]],
	"raposa": [["female-e", "female-c", "male-e"], ["male-d", "male-f", "female-c"], ["female-c", "female-d", "male-b"], ["male-f", "male-e", "female-d"]],
}
## As cabeças do teste de 64 px: uma de cada raça, pelo mesmo perfil.
const TESTE_PERFIL := "male-b"
var celulas_64 := []


func _mundo(px: Vector2) -> Vector3:
	return Vector3((px.x - TAM.x * 0.5) * ESCALA, (TAM.y * 0.5 - px.y) * ESCALA, 0.0)


func montar(_estudo) -> void:
	folha = Prancha.folha(self, TAM, Fita.CASCO)
	var vp := Prancha.celula(self, TAM, false)
	var raiz := Node3D.new()
	vp.add_child(raiz)
	Mundo.ambiente(raiz, {"ambiente": Color("#2a2738"), "ambiente_energia": 0.55, "nevoa": false,
		"glow": true, "glow_intensidade": 0.45, "fundo": Fita.CASCO})
	_luz(raiz)
	var cam := Prancha.camera(vp)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = TAM.y * ESCALA
	cam.position = Vector3(0, 0, 20)
	cam.far = 60.0
	for r in 5:
		var raca: String = Racas.RACAS[r]
		for l in 4:
			var pecas: Array = PECAS[raca][l]
			for vista in 2:
				var cx := X0 + l * COL + COL * (0.27 + 0.46 * vista)
				var pe := _mundo(Vector2(cx, LINHA_Y + r * LINHA_H + LINHA_H - 14.0))
				pe.z = 0.0
				Montar.cavaleiro(raiz, l, pe, pecas, {"raca": raca, "anel": false, "anim": "idle", "t_anim": 0.35,
					"yaw": -PI * 0.25 if vista == 1 else 0.0})
	Mundo.neon_sem_sombra(raiz)
	Prancha.pregar(folha, vp, Rect2(Vector2.ZERO, Vector2(TAM)))
	# o teste: as cinco cabeças a 64 px, cada uma numa célula própria
	for r in 5:
		var c := _cabeca_64(Racas.RACAS[r])
		celulas_64.append(c)
		for modo in 2:
			var t := Prancha.pregar(folha, c, Rect2(Vector2(X0 + r * TESTE_DX + modo * 136, TESTE_Y + 52), Vector2(128, 128)))
			t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var sm := ShaderMaterial.new()
			sm.shader = _SH_TESTE
			sm.set_shader_parameter("modo", modo)
			sm.set_shader_parameter("papel", Fita.ETIQUETA)
			t.material = sm
	Prancha.por_cima(folha, _texto)


## A luz da prancha: a chave em tungstênio, o contra em violeta.
func _luz(raiz: Node3D) -> void:
	var sol := DirectionalLight3D.new()
	raiz.add_child(sol)
	sol.rotation_degrees = Vector3(-30, -28, 0)
	sol.light_color = Fita.TUNGSTENIO
	sol.light_energy = 1.0
	var contra := DirectionalLight3D.new()
	raiz.add_child(contra)
	contra.rotation_degrees = Vector3(-20, 160, 0)
	contra.light_color = Color("#8a7cff")
	contra.light_energy = 0.5


## A cabeça sozinha, de frente, sem contorno nem acento, 64 × 64 px, fundo
## transparente: o que o teste do 04 mede.
func _cabeca_64(raca: String) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(64, 64)
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var raiz := Node3D.new()
	vp.add_child(raiz)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#2a2738")
	env.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	raiz.add_child(we)
	_luz(raiz)
	Montar.cavaleiro(raiz, 0, Vector3.ZERO, [TESTE_PERFIL, TESTE_PERFIL, TESTE_PERFIL], {"raca": raca, "so": "cabeca",
		"contorno": false, "acento": false, "anel": false, "aro": 0.0, "anim": "idle", "t_anim": 0.0})
	var cam := Camera3D.new()
	vp.add_child(cam)
	cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	# a cabeça (y de 0,30 a 0,86 nas unidades do personagem, ×K) cabe nos 64 px
	cam.size = 0.60 * Mundo.K
	cam.position = Vector3(0, 0.585 * Mundo.K, 10)
	return vp


const _SH_TESTE := preload("res://estudos/direcao/shaders/teste_64.gdshader")


func foto() -> Image:
	return await Prancha.foto(folha)


func _texto(ci: CanvasItem) -> void:
	Hud.etiqueta(ci, Rect2(48, 14, 640, 124), "As raças", "PRANCHA  ·  ITEM 16  ·  5 × 4", Fita.SECAO[0], 54, -0.01)
	Hud.texto(ci, Fita.archivo(500), 30, Vector2(760, 44), "A raça é aparência: troca a cabeça, a pele e a cauda. O superior e", Color(Fita.ETIQUETA, 0.85))
	Hud.texto(ci, Fita.archivo(500), 30, Vector2(760, 86), "o inferior são as peças humanas. Sem stat, sem colisão. De frente e a 3/4.", Color(Fita.ETIQUETA, 0.85))
	for l in 4:
		var x := X0 + l * COL
		var cor: Color = Fita.JOGADOR[l]
		Hud.texto(ci, Fita.bungee(), 30, Vector2(x + 14, LINHA_Y - 34), "P%d" % (l + 1), cor)
		Hud.lampadas(ci, Vector2(x + 76, LINHA_Y - 22), l, cor, 10.0)
		if l > 0:
			ci.draw_line(Vector2(x, LINHA_Y - 30), Vector2(x, LINHA_Y + 5 * LINHA_H), Color(Fita.GRAFITE, 0.6), 1.0)
	for r in 5:
		var y := LINHA_Y + r * LINHA_H
		ci.draw_line(Vector2(48, y), Vector2(X0 + 4 * COL, y), Fita.GRAFITE, 2.0)
		var raca: String = Racas.RACAS[r]
		Hud.texto(ci, Fita.archivo(600), 30, Vector2(56, y + 12), Racas.NOME[raca], Fita.ETIQUETA)
		var de_onde: String = {"humana": "Mini Characters", "orc": "Mini Dungeon", "automato": "por código", "golem": "por código", "raposa": "código + Cube Pets"}[raca]
		Hud.texto(ci, Fita.vt(), 30, Vector2(56, y + 50), de_onde, Fita.MUDO)
	var yt := TESTE_Y
	ci.draw_line(Vector2(48, yt), Vector2(X0 + 4 * COL, yt), Fita.GRAFITE, 2.0)
	Hud.texto(ci, Fita.archivo(600), 30, Vector2(56, yt + 6), "O teste do 04: a cabeça a 64 px (ampliada ×2)", Fita.ETIQUETA)
	Hud.texto(ci, Fita.vt(), 30, Vector2(56, yt + 60), "cinza e", Fita.MUDO)
	Hud.texto(ci, Fita.vt(), 30, Vector2(56, yt + 92), "silhueta", Fita.MUDO)
	for r in 5:
		var x := X0 + r * TESTE_DX
		Hud.texto(ci, Fita.vt(), 30, Vector2(x, yt + 186), Racas.NOME[Racas.RACAS[r]], Fita.ETIQUETA)
