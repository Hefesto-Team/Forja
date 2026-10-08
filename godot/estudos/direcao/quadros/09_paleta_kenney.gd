extends Node3D
## Quadro 09 — A Kenney na fita: o colormap de cada pacote como veio e como
## a regra da fita o recolore (recolorir.gd, pelo papel do pacote), e o mesmo
## objeto antes e depois, na mesma luz.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")

var espera := 8
var arquivo := "09_paleta_kenney"
var e
const PACOTES := ["mini-dungeon", "mini-arena", "mini-arcade", "survival-kit", "mini-characters"]
const PARES := [
	["mini-arcade/arcade-machine", "Fliperama", -3.4],
	["survival-kit/workbench-anvil", "Bigorna", 0.0],
	["mini-characters/character-male-e", "Cavaleiro", 3.12],
]
const MEIO := 0.74
var mapas := {}
var recortes := {}
const NOMES := {"mini-dungeon": "Mini Dungeon", "mini-arena": "Mini Arena", "mini-arcade": "Mini Arcade",
	"survival-kit": "Survival Kit", "mini-characters": "Mini Characters"}
const PAPEIS := {"cenario": "Cenário", "maquina": "Máquina", "objeto": "Objeto", "personagem": "Personagem"}


func montar(estudo) -> void:
	e = estudo
	var cam: Camera3D = e.camera
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 5.4
	cam.position = Vector3(0, 3.4, 12.0)
	cam.look_at(Vector3(0, 1.8, 0))
	Mundo.ambiente(self, {"ambiente": Color("#2a2738"), "ambiente_energia": 0.45, "nevoa": false, "glow_intensidade": 0.5})
	var sol := DirectionalLight3D.new()
	add_child(sol)
	sol.rotation_degrees = Vector3(-40, -30, 0)
	sol.light_color = Color("#fff2e0")
	sol.light_energy = 0.9
	sol.shadow_enabled = true
	sol.shadow_bias = 0.08
	sol.shadow_normal_bias = 2.0
	for i in range(-4, 5):
		for j in range(-1, 5):
			Mundo.peca(self, "mini-dungeon/floor", Vector3(i * 2.0, 0, j * 2.0))
	for par in PARES:
		var nome: String = par[0]
		var x: float = par[2]
		var pacote := nome.get_slice("/", 0)
		var original: Texture2D = load("res://estudos/direcao/kenney/%s/Textures/colormap-kenney.png" % pacote)
		var escala := 3.4 if pacote == "survival-kit" else -1.0
		var antes := Mundo.peca(self, nome, Vector3(x - MEIO, 0, 0), 0.35, escala)
		Mundo.trocar_textura(antes, original)
		if pacote == "mini-characters":
			Mundo.cavaleiro(self, 2, Vector3(x + MEIO, 0, 0), 0.35, "idle", 0.3, "character-male-e", {"anel": false})
		else:
			Mundo.peca(self, nome, Vector3(x + MEIO, 0, 0), 0.35, escala)
	Mundo.neon_sem_sombra(self)
	for p in PACOTES:
		var a := _imagem("res://estudos/direcao/kenney/%s/Textures/colormap-kenney.png" % p)
		recortes[p] = _usado(a)
		mapas[p] = [ImageTexture.create_from_image(a),
			ImageTexture.create_from_image(_imagem("res://estudos/direcao/kenney/%s/Textures/colormap.png" % p))]
	Mundo.pos(self, 5, {"grao": 0.01, "varredura": 0.03})
	Hud.camada(self, _hud)


func _imagem(caminho: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(caminho))
	img.convert(Image.FORMAT_RGBA8)
	return img


## O retângulo pintado do colormap (a Kenney deixa o resto preto).
func _usado(img: Image) -> Rect2:
	var r := Rect2i()
	var achou := false
	for y in range(0, img.get_height(), 2):
		for x in range(0, img.get_width(), 2):
			var c := img.get_pixel(x, y)
			if c.r + c.g + c.b > 0.12:
				if not achou:
					r = Rect2i(x, y, 1, 1)
					achou = true
				else:
					r = r.expand(Vector2i(x, y))
	return Rect2(r.position, r.size + Vector2i(2, 2))


func _hud(ci: CanvasItem) -> void:
	Hud.etiqueta(ci, Rect2(96, 40, 560, 130), "A Kenney na fita", "COLORMAP  ·  ANTES E DEPOIS", Fita.SECAO[0], 50, -0.01)
	Hud.texto(ci, Fita.archivo(500), 32, Vector2(700, 60), "Cada pacote tem um papel. A cor passa pelo OKLab: a luz cai na faixa", Color(Fita.ETIQUETA, 0.85))
	Hud.texto(ci, Fita.archivo(500), 32, Vector2(700, 102), "do papel, o croma encolhe e um fio do violeta do cenário entra por cima.", Color(Fita.ETIQUETA, 0.85))
	var lado := 158.0
	for i in PACOTES.size():
		var p: String = PACOTES[i]
		var x := 96.0 + i * 352.0
		var y := 210.0
		var fonte: Rect2 = recortes[p]
		var alto := lado * fonte.size.y / fonte.size.x
		var base := y + 124.0
		for k in 2:
			var r := Rect2(x + k * (lado + 12), y, lado, alto)
			Hud.caixa(ci, r.grow(4), Fita.CASCO_ALTO, 4)
			ci.draw_texture_rect_region(mapas[p][k], r, fonte)
		Hud.texto(ci, Fita.vt(), 32, Vector2(x, base + 12), "KENNEY", Fita.TINTA_SUAVE.lightened(0.4))
		Hud.texto(ci, Fita.vt(), 32, Vector2(x + lado + 12, base + 12), "FITA", Fita.ETIQUETA)
		Hud.texto(ci, Fita.archivo(600), 34, Vector2(x, base + 48), NOMES[p], Fita.ETIQUETA)
		Hud.texto(ci, Fita.archivo(500), 30, Vector2(x, base + 88), _papel(p), Color(Fita.ETIQUETA, 0.7))
	for par in PARES:
		var x: float = par[2]
		for k in 2:
			var s: Vector2 = e.camera.unproject_position(Vector3(x + (MEIO if k == 1 else -MEIO), 0, 1.0))
			var rotulo := "Fita" if k == 1 else "Kenney"
			Hud.texto(ci, Fita.vt(), 34, Vector2(s.x - 100, s.y + 14), rotulo.to_upper(), Fita.ETIQUETA if k == 1 else Fita.TINTA_SUAVE.lightened(0.4), HORIZONTAL_ALIGNMENT_CENTER, 200)


func _papel(p: String) -> String:
	var papel: String = Fita.PAPEL_DO_PACOTE[p]
	var g: Dictionary = Fita.GRADE[papel]
	return "%s · luz %d–%d %%" % [PAPEIS[papel], roundi(g.l0 * 100), roundi((g.l0 + g.l1) * 100)]
