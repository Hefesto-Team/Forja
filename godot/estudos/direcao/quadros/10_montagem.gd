extends Node3D
## Quadro 10 — A tela de montagem (04): quatro colunas de 432 px, cada uma um
## corpo misturado (a cabeça de um personagem, o superior de outro, o
## inferior de um terceiro). P1 já forjado (a chave em tungstênio e a build
## boa sublinhada), P2 com a linha do inferior travada e a fita das 12
## cabeças aberta, P3 de cadeira de rodas, P4 passando por um item que o corpo
## não alcança. 50 mm, frontal, à altura do peito.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")
const Montar := preload("res://estudos/direcao/cavaleiro/montar.gd")
const Sis := preload("res://estudos/direcao/cavaleiro/sistemas.gd")

var espera := 8
var arquivo := "10_montagem"
var e

## Cada coluna: as três peças pelo personagem, o item, o nome e o estado.
const COLUNAS := [
	{"pecas": ["male-c", "female-f", "male-a"], "item": "ancora", "nome": "Basalto", "forjado": true, "linha": -1},
	{"pecas": ["male-b", "female-c", "male-e"], "item": "martelo", "nome": "Obsidiana", "trava": 2, "linha": 0, "fita": true},
	{"pecas": ["female-d", "female-b", "male-b"], "item": "diapasao", "nome": "Latão", "cadeira": "wheelchair-deluxe", "linha": 2},
	{"pecas": ["female-a", "male-d", "female-d"], "item": "escudo", "nome": "Faísca", "passando": "martelo", "linha": 3},
]
## A câmera: 50 mm, à altura do peito, a lente deslocada para o cavaleiro cair
## na faixa de 160 a 600 px sem a câmera olhar para baixo.
const DIST := 9.0
const ALTURA_CAM := 0.95
const PX_POR_M := 1080.0 / (2.0 * DIST * 0.24)  # tan(13,5°) ≈ 0,24
const PASSO := 432.0 / PX_POR_M
var corpos := []
## A pose de quem segura o item: a arma na mão pede o braço de segurar.
const ANIM := {"martelo": "holding-right", "ancora": "holding-right", "escudo": "holding-left"}


func montar(estudo) -> void:
	e = estudo
	var cam: Camera3D = e.camera
	cam.projection = Camera3D.PROJECTION_FRUSTUM
	cam.near = 0.1
	cam.size = 2.0 * cam.near * 0.24
	# o cavaleiro (0,79·K = 1,58 m com o cabelo, o meio a 0,79 m) no meio da
	# faixa de 160 a 600 px, os pés em cerca de 580
	var desce := (ALTURA_CAM - 0.79) + (540.0 - 375.0) / PX_POR_M
	cam.frustum_offset = Vector2(0, -desce * cam.near / DIST)
	cam.position = Vector3(0, ALTURA_CAM, DIST)
	cam.rotation = Vector3.ZERO
	cam.far = 60.0
	Mundo.ambiente(self, {"ambiente": Color("#2a2738"), "ambiente_energia": 0.30, "nevoa": true,
		"nevoa_densidade": 0.012, "glow_intensidade": 0.7})
	for i in range(-5, 6):
		for j in range(-3, 1):
			Mundo.peca(self, "mini-dungeon/floor", Vector3(i * 2.0, 0, j * 2.0))
	# a parede de fundo e o néon da arquitetura, baixo
	Mundo.caixa(self, Vector3(24, 6, 0.3), Vector3(0, 3, -6.2), Fita.fosco(Fita.graduar(Color("#3a3346"), "cenario")))
	var sol := DirectionalLight3D.new()
	add_child(sol)
	sol.rotation_degrees = Vector3(-35, -18, 0)
	sol.light_color = Fita.VIOLETA_FUNDO.lightened(0.55)
	sol.light_energy = 0.35
	for i in 4:
		var c: Dictionary = COLUNAS[i]
		var x := ((96.0 + 432.0 * i + 216.0) - 960.0) / PX_POR_M
		var cor: Color = Fita.JOGADOR[i]
		var corpo := Sis.corpo(c.pecas)
		corpos.append(corpo)
		Montar.cavaleiro(self, i, Vector3(x, 0, 0), c.pecas, {"item": c.item, "cadeira": c.get("cadeira", ""),
			"anim": ANIM.get(c.item, "idle") if not c.has("cadeira") else "wheelchair-sit", "t_anim": 0.25, "anel": true,
			"yaw": 0.0})
		# a chave: violeta até forjar, tungstênio depois; o contra-luz na cor do lugar
		var chave: Color = Fita.TUNGSTENIO if c.get("forjado", false) else Color("#8a7cff")
		Mundo.foco(self, Vector3(x + 1.6, 3.6, 3.2), Vector3(x, 0.8, 0), chave, 5.5 if c.get("forjado", false) else 3.2, 22.0, 9.0, true)
		Mundo.foco(self, Vector3(x - 0.4, 2.8, -2.6), Vector3(x, 1.0, 0), cor, 3.0, 26.0, 7.0)
	Mundo.neon_sem_sombra(self)
	Mundo.pos(self, 5, {"grao": 0.025})
	Hud.camada(self, _hud)


func _hud(ci: CanvasItem) -> void:
	for i in 4:
		_coluna(ci, i)
	# as dicas, na voz do texto
	var dicas := [["cross", "Botão ✕ (Forjar)"], ["triangle", "Botão △ (Sortear)"], ["square", "Botão □ (Travar)"], ["dpad_left", "Botão ◀ ▶ (Trocar)"]]
	var x := 196.0
	for d in dicas:
		Hud.glifo(ci, d[0], Rect2(x, 1030, 36, 36), Fita.ETIQUETA)
		Hud.texto(ci, Fita.archivo(600), 30, Vector2(x + 46, 1031), d[1], Color(Fita.ETIQUETA, 0.85))
		x += 400.0


func _coluna(ci: CanvasItem, i: int) -> void:
	var c: Dictionary = COLUNAS[i]
	var corpo: Dictionary = corpos[i]
	var cor: Color = Fita.JOGADOR[i]
	var x0 := 96.0 + 432.0 * i + 10.0
	var w := 412.0
	# a placa do lugar (60 a 150)
	var placa := Rect2(x0, 60, w, 90)
	Hud.caixa(ci, Rect2(placa.position + Vector2(0, 6), placa.size), Fita.SOMBRA, 10)
	Hud.caixa(ci, placa, Fita.CASCO, 10, Fita.CASCO_ALTO, 2)
	ci.draw_rect(Rect2(placa.position + Vector2(12, 0), Vector2(w - 24, 5)), cor)
	Hud.texto(ci, Fita.bungee(), 40, placa.position + Vector2(18, 10), "P%d" % (i + 1), cor)
	Hud.lampadas(ci, placa.position + Vector2(20, 64), i, cor, 14.0)
	Hud.texto(ci, Fita.archivo(600), 32, placa.position + Vector2(0, 26), c.nome, Fita.ETIQUETA, HORIZONTAL_ALIGNMENT_RIGHT, w - 20)
	if c.get("forjado", false):
		Hud.texto(ci, Fita.vt(), 30, placa.position + Vector2(0, 58), "FORJADO", Fita.TUNGSTENIO, HORIZONTAL_ALIGNMENT_RIGHT, w - 20)
	# a etiqueta do arquétipo (610 a 650), em Permanent Marker, em TINTA
	var et := Rect2(x0 + 26, 608, w - 52, 44)
	Hud.caixa(ci, Rect2(et.position + Vector2(4, 5), et.size), Fita.SOMBRA, 6)
	Hud.caixa(ci, et, Fita.ETIQUETA, 6)
	ci.draw_rect(Rect2(et.position + Vector2(0, 6), Vector2(8, et.size.y - 12)), cor)
	var titulo := "%s · %s" % [c.nome, corpo.arquetipo]
	Hud.texto(ci, Fita.marcador(), 30, et.position + Vector2(0, 0), titulo, Fita.TINTA, HORIZONTAL_ALIGNMENT_CENTER, et.size.x)
	if Sis.build_boa(corpo, c.item):
		# a build boa: os dois sublinhados de caneta
		var lw := Hud.largura_do(Fita.marcador(), 30, titulo)
		var sx := et.position.x + (et.size.x - lw) * 0.5
		for k in 2:
			var y := et.end.y - 7 + k * 6
			ci.draw_line(Vector2(sx - 4, y + k), Vector2(sx + lw + 4, y - 1), Fita.TINTA, 2.5, true)
	# as cinco linhas (660 a 860)
	var rotulos := ["Cabeça", "Superior", "Inferior", "Item", "Nome"]
	var valores := [corpo.pecas[0].nome, corpo.pecas[1].nome, corpo.pecas[2].nome, Sis.item(c.item).nome, c.nome]
	if c.has("cadeira"):
		valores[2] = "Cadeira"
	if c.has("passando"):
		valores[3] = Sis.item(c.passando).nome
	for k in 5:
		var r := Rect2(x0, 660 + k * 40, w, 38)
		var escolhida := int(c.get("linha", -1)) == k
		if escolhida:
			Hud.caixa(ci, r, Fita.CASCO_ALTO, 6, cor, 3)
		Hud.texto(ci, Fita.archivo(600), 30, r.position + Vector2(12, 1), rotulos[k], Fita.MUDO if not escolhida else Fita.ETIQUETA)
		var vx := r.position.x + 136.0
		var vw := w - 148.0
		var cor_valor := Fita.ETIQUETA
		Hud.texto(ci, Fita.archivo(600), 30, Vector2(vx, r.position.y + 1), "◀", Fita.MUDO)
		Hud.texto(ci, Fita.archivo(600), 30, Vector2(vx, r.position.y + 1), "▶", Fita.MUDO, HORIZONTAL_ALIGNMENT_RIGHT, vw)
		Hud.texto(ci, Fita.archivo(500), 30, Vector2(vx + 22, r.position.y + 1), valores[k], cor_valor, HORIZONTAL_ALIGNMENT_CENTER, vw - 44)
		if k == 3 and c.has("passando"):
			# o item que o corpo não alcança: riscado
			var lw := Hud.largura_do(Fita.archivo(500), 30, valores[k])
			var cx := vx + 22 + (vw - 44) * 0.5
			ci.draw_line(Vector2(cx - lw * 0.5 - 6, r.position.y + 21), Vector2(cx + lw * 0.5 + 6, r.position.y + 19), cor, 3.0, true)
		if int(c.get("trava", -1)) == k:
			_cadeado(ci, Vector2(r.position.x + 134, r.position.y + 6), Fita.ETIQUETA)
	if c.get("fita", false):
		_fita_das_cabecas(ci, i, Rect2(x0, 700, w, 52))
	# os quatro VUs (870 a 1010)
	for k in 4:
		var y := 872.0 + k * 35.0
		Hud.texto(ci, Fita.vt(), 30, Vector2(x0 + 12, y - 2), Sis.NOME_ST[k], Fita.MUDO)
		var r := Rect2(x0 + 136, y + 4, w - 190, 24)
		var n: int = corpo.stats[k]
		Hud.vu(ci, r, 5, n, cor)
		Hud.texto(ci, Fita.vt(), 30, Vector2(r.end.x + 12, y - 2), str(n), Fita.ETIQUETA)
		if c.has("passando"):
			var it := Sis.item(c.passando)
			var pede := int(it["pede_" + Sis.ST[k]])
			var liga := int(it["liga_" + Sis.ST[k]])
			if pede > 0:
				# as duas marcas do item no VU: o que pede e a liga
				for nivel in [pede, liga]:
					var seg := (r.size.x - 16.0) / 5.0
					var mx: float = r.position.x + nivel * (seg + 4.0) - 2.0
					ci.draw_line(Vector2(mx, r.position.y - 6), Vector2(mx, r.end.y + 6), Fita.ETIQUETA, 3.0)


## O cadeado da linha travada, desenhado: a alça e o corpo.
func _cadeado(ci: CanvasItem, p: Vector2, cor: Color) -> void:
	ci.draw_arc(p + Vector2(-14, 12), 7.0, PI, TAU, 10, cor, 3.0, true)
	ci.draw_rect(Rect2(p + Vector2(-24, 11), Vector2(20, 16)), cor)
	ci.draw_rect(Rect2(p + Vector2(-15, 16), Vector2(2, 6)), Fita.CASCO)


## A fita das 12 marcas, embaixo da linha escolhida: a atual acesa na cor do
## lugar, as travadas pela regra riscadas em GRAFITE, as ocupadas por outro
## jogador na cor dele com o P#.
func _fita_das_cabecas(ci: CanvasItem, lugar: int, r: Rect2) -> void:
	Hud.caixa(ci, Rect2(r.position + Vector2(0, 5), r.size), Fita.SOMBRA, 6)
	Hud.caixa(ci, r, Fita.JANELA, 6, Fita.GRAFITE, 2)
	var c: Dictionary = COLUNAS[lugar]
	var outros := {}
	for j in 4:
		if j != lugar:
			outros[COLUNAS[j].pecas[0]] = j
	var emb_resto := [Sis.peca("superior", c.pecas[1]).principal, Sis.peca("inferior", c.pecas[2]).principal]
	var todos := ["female-a", "female-b", "female-c", "female-d", "female-e", "female-f",
		"male-a", "male-b", "male-c", "male-d", "male-e", "male-f"]
	var cel := (r.size.x - 16.0) / 12.0
	for k in 12:
		var m := Rect2(r.position + Vector2(8 + k * cel + 2, 8), Vector2(cel - 4, r.size.y - 16))
		var p: String = todos[k]
		var emb: String = Sis.peca("cabeca", p).principal
		if p == c.pecas[0]:
			ci.draw_rect(m, Fita.JOGADOR[lugar])
		elif outros.has(p):
			var dono: int = outros[p]
			ci.draw_rect(m, Color(Fita.JOGADOR[dono], 0.35))
			ci.draw_rect(Rect2(m.position, Vector2(m.size.x, 4)), Fita.JOGADOR[dono])
			Hud.texto(ci, Fita.vt(), 30, m.position + Vector2(0, 2), "P%d" % (dono + 1), Fita.ETIQUETA, HORIZONTAL_ALIGNMENT_CENTER, m.size.x)
		elif Sis.OPOSTO[emb] in emb_resto:
			ci.draw_rect(m, Fita.CASCO)
			ci.draw_line(m.position + Vector2(3, m.size.y - 4), m.end - Vector2(3, m.size.y - 4), Fita.GRAFITE, 4.0, true)
		else:
			ci.draw_rect(m, Fita.CASCO_ALTO)
