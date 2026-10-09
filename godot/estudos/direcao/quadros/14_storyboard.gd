extends Node3D
## Quadro 14 — O storyboard da noite (01; PRODUCAO, item 5): os 18 planos,
## de quem liga o jogo a quem desliga, cada um uma miniatura de 448×252
## renderizada com a lente, a altura e a luz do plano. Onde o plano já tem
## quadro no estudo, a miniatura é esse quadro (a mesma cena montada numa
## célula); os outros são montados aqui. Os planos 2D (a entrada, o placar,
## os créditos) são o HUD em miniatura.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")
const Prancha := preload("res://estudos/direcao/prancha.gd")
const Cena := preload("res://estudos/direcao/cena_centelha.gd")
const Montar := preload("res://estudos/direcao/cavaleiro/montar.gd")
const Bigorna := preload("res://estudos/direcao/bigorna.gd")
const Reacoes := preload("res://estudos/direcao/reacoes.gd")

var espera := 14
var arquivo := "14_storyboard"
var folha: SubViewport
const MINI := Vector2i(448, 252)
const PASSO := Vector2(470, 297)
const X0 := 22.0
const Y0 := 14.0
## Os 18 planos: o número, o momento, a lente e a duração, e de onde sai a
## miniatura (um quadro do estudo, ou uma função daqui).
const PLANOS := [
	[1, "Título", "85 mm", "até o ✕", "q:07_titulo"],
	[2, "PLAY", "85 mm", "4 batidas", "f:_play"],
	[3, "A introdução", "35 mm", "24 s", "f:_introducao"],
	[4, "Montagem", "50 mm", "até todos", "q:10_montagem"],
	[5, "Os prontos", "85 mm", "4 compassos", "q:08_cavaleiros"],
	[6, "Salão", "35 mm", "até escolher", "q:02_salao"],
	[7, "Estabelecimento", "24 mm", "1 compasso", "f:_estabelecimento"],
	[8, "Entrada", "2D", "900 ms", "q:03_entrada"],
	[9, "Cartão", "65 mm", "até todos ✕", "q:04_cartao"],
	[10, "Minigame", "35 mm", "a faixa", "q:01_centelha"],
	[11, "Apito", "o do jogo", "3 quadros", "f:_apito"],
	[12, "Resultado", "50 mm", "4 batidas", "f:_resultado"],
	[13, "Inserto", "85 mm", "1 batida", "f:_inserto"],
	[14, "Placar", "2D", "4 compassos", "f:_placar"],
	[15, "Virar a fita", "50 mm", "2 compassos", "f:_virar"],
	[16, "Pódio", "35 mm", "8 compassos", "q:06_podio"],
	[17, "Créditos", "85 mm", "1 por compasso", "f:_creditos"],
	[18, "Fim da fita", "85 mm", "até ✕ ou ◯", "q:15_fim_da_fita"],
]


## O estudo de mentira de cada célula: a câmera dela e o olhar().
class Olho:
	var camera: Camera3D
	func olhar(pos: Vector3, alvo: Vector3, fov := 40.0) -> void:
		camera.position = pos
		camera.look_at(alvo)
		camera.fov = fov


func montar(_estudo) -> void:
	folha = Prancha.folha(self, Vector2i(1920, 1500), Fita.CASCO)
	for i in PLANOS.size():
		var vp := Prancha.celula(self, MINI * 2)
		var raiz := Node3D.new()
		vp.add_child(raiz)
		var olho := Olho.new()
		olho.camera = Prancha.camera(vp)
		olho.camera.fov = 40.0
		var fonte: String = PLANOS[i][4]
		if fonte.begins_with("q:"):
			var q: Node = (load("res://estudos/direcao/quadros/%s.gd" % fonte.substr(2)) as GDScript).new()
			raiz.add_child(q)
			q.montar(olho)
		else:
			call(fonte.substr(2), raiz, olho)
		Prancha.pregar(folha, vp, Rect2(_pos(i), Vector2(MINI)))
	Prancha.por_cima(folha, _legendas)


func foto() -> Image:
	return await Prancha.foto(folha)


func _pos(i: int) -> Vector2:
	return Vector2(X0 + (i % 4) * PASSO.x, Y0 + (i / 4) * PASSO.y)


func _legendas(ci: CanvasItem) -> void:
	for i in PLANOS.size():
		var p := _pos(i)
		var pl: Array = PLANOS[i]
		ci.draw_rect(Rect2(p, Vector2(MINI)), Fita.GRAFITE, false, 2.0)
		Hud.texto(ci, Fita.archivo(600), 30, p + Vector2(0, MINI.y + 2), "%d · %s" % [pl[0], pl[1]], Fita.ETIQUETA)
		Hud.texto(ci, Fita.vt(), 30, p + Vector2(0, MINI.y + 2), "%s · %s" % [pl[2], pl[3]], Fita.MUDO, HORIZONTAL_ALIGNMENT_RIGHT, MINI.x)
	# o canto que sobra: a legenda da prancha
	var p := _pos(18)
	Hud.etiqueta(ci, Rect2(p + Vector2(40, 40), Vector2(820, 150)), "O storyboard da noite", "PRANCHA  ·  ITEM 5  ·  18 PLANOS", Fita.SECAO[0], 50, -0.01)


# --------------------------------------------------- os planos daqui --
func _fundo(raiz: Node3D, chave: Color, energia: float, chao := true) -> void:
	Mundo.ambiente(raiz, {"ambiente": Color("#2a2738"), "ambiente_energia": 0.35, "nevoa_densidade": 0.02, "glow_intensidade": 0.6})
	if chao:
		for i in range(-3, 4):
			for j in range(-3, 2):
				Mundo.peca(raiz, "mini-dungeon/floor", Vector3(i * 2.0, 0, j * 2.0))
	Mundo.foco(raiz, Vector3(1.0, 5.0, 2.6), Vector3(0, 0.6, 0), chave, energia, 26.0, 10.0, true)


func _deck(raiz: Node3D, olho, tempo: String, osd: String, lado: String) -> void:
	var q: Node = (load("res://estudos/direcao/quadros/15_fim_da_fita.gd") as GDScript).new()
	q.tempo = tempo
	q.osd = osd
	q.lado = lado
	q.saidas = false
	q.fim = false
	raiz.add_child(q)
	q.montar(olho)


func _play(raiz: Node3D, olho) -> void:
	_deck(raiz, olho, "0:00:00", "PLAY", "LADO A")


func _virar(raiz: Node3D, olho) -> void:
	_deck(raiz, olho, "0:52:30", "LADO B", "LADO B")


## 3: a bigorna sozinha no foco, a 35 mm, baixo; os pedestais no escuro.
func _introducao(raiz: Node3D, olho) -> void:
	_fundo(raiz, Fita.TUNGSTENIO, 6.0)
	var b := MeshInstance3D.new()
	b.mesh = Bigorna.malha()
	b.scale = Vector3.ONE * Mundo.K * 1.6
	raiz.add_child(b)
	for l in 4:
		Mundo.anel(raiz, Fita.JOGADOR[l], l).position = Vector3(-3.0 + l * 2.0, 0.03, -2.5)
	Mundo.neon_sem_sombra(raiz)
	olho.olhar(Vector3(0.6, 0.9, 3.4), Vector3(0, 0.45, 0), 37.8)
	Mundo.pos(raiz, 5, {"grao": 0.03})


## 7: o lugar da seção, a 24 mm, alto e aberto; o nome da seção.
func _estabelecimento(raiz: Node3D, olho) -> void:
	Cena.montar(raiz, olho)
	olho.olhar(Vector3(-9.0, 9.0, 14.0), Vector3(0, 0.6, -1.0), 53.1)
	Mundo.pos(raiz, 5, {"grao": 0.02})
	Hud.camada(raiz, func(ci): Hud.etiqueta(ci, Rect2(620, 420, 680, 170), "A Centelha", "LADO A  ·  FAIXA 01", Fita.SECAO[0], 64, -0.012), 10)


## 11: o apito, o último quadro congelado, sem texto.
func _apito(raiz: Node3D, olho) -> void:
	Cena.montar(raiz, olho)
	Mundo.pos(raiz, 5, {"grao": 0.03, "varredura": 0.12, "desbota": 0.35})


## 12: o vencedor a 50 mm, o nome dele carimbado na cor dele.
func _resultado(raiz: Node3D, olho) -> void:
	_fundo(raiz, Fita.TUNGSTENIO, 5.5)
	Montar.cavaleiro(raiz, 1, Vector3.ZERO, ["male-b", "female-c", "male-e"], {"item": "martelo", "anim": "emote-yes", "t_anim": 0.3})
	Mundo.neon_sem_sombra(raiz)
	olho.olhar(Vector3(0, 1.1, 5.4), Vector3(0, 0.95, 0), 27.0)
	Mundo.pos(raiz, 5, {"grao": 0.02})
	Hud.camada(raiz, func(ci): Hud.julgamento(ci, Vector2(960, 150), "OBSIDIANA", Fita.JOGADOR[1], 150, -0.03), 10)


## 13: o último colocado, a 85 mm, e o emburrado em cima dele.
func _inserto(raiz: Node3D, olho) -> void:
	_fundo(raiz, Color("#8a7cff"), 2.2)
	Montar.cavaleiro(raiz, 3, Vector3.ZERO, ["female-a", "male-d", "female-d"], {"item": "escudo", "anim": "idle", "t_anim": 0.6})
	Mundo.neon_sem_sombra(raiz)
	olho.olhar(Vector3(0, 1.3, 6.0), Vector3(0, 1.2, 0), 16.0)
	Mundo.pos(raiz, 5, {"grao": 0.03})
	Hud.camada(raiz, func(ci): Reacoes.carimbo(ci, Vector2(960, 140), "car_emburrado", 3), 10)


## 14: o placar, 2D: a etiqueta com os pontos e o VU de cada um.
func _placar(raiz: Node3D, _olho) -> void:
	Mundo.ambiente(raiz, {"fundo": Fita.FITA})
	Hud.camada(raiz, func(ci):
		var et := Rect2(360, 140, 1200, 800)
		Hud.caixa(ci, Rect2(et.position + Vector2(8, 12), et.size), Fita.SOMBRA, 10)
		Hud.caixa(ci, et, Fita.ETIQUETA, 10)
		ci.draw_rect(Rect2(et.position + Vector2(0, 30), Vector2(et.size.x, 18)), Fita.SECAO[0])
		Hud.texto(ci, Fita.marcador(), 72, et.position + Vector2(50, 70), "O placar", Fita.TINTA)
		var nomes := ["Basalto", "Obsidiana", "Latão", "Faísca"]
		var pontos := [1240, 1310, 860, 990]
		for l in 4:
			var y := et.position.y + 230 + l * 140
			ci.draw_rect(Rect2(et.position.x + 50, y, 16, 90), Fita.JOGADOR[l])
			Hud.texto(ci, Fita.bungee(), 46, Vector2(et.position.x + 90, y + 10), "P%d" % (l + 1), Fita.TINTA)
			Hud.texto(ci, Fita.archivo(600), 48, Vector2(et.position.x + 200, y + 12), nomes[l], Fita.TINTA)
			Hud.vu(ci, Rect2(et.position.x + 520, y + 24, 380, 44), 10, int(pontos[l] / 140), Fita.JOGADOR[l])
			Hud.texto(ci, Fita.vt(), 64, Vector2(et.position.x + 920, y + 6), str(pontos[l]), Fita.TINTA)
		Reacoes.carimbo(ci, Vector2(1480, 470), "car_virada", 1), 10)


## 17: os créditos, o encarte da noite: as faixas e quem venceu cada uma.
func _creditos(raiz: Node3D, _olho) -> void:
	Mundo.ambiente(raiz, {"fundo": Fita.FITA})
	Hud.camada(raiz, func(ci):
		var r := Rect2(300, 80, 1320, 920)
		Hud.caixa(ci, Rect2(r.position + Vector2(8, 12), r.size), Fita.SOMBRA, 8)
		Hud.caixa(ci, r, Fita.ETIQUETA, 8)
		ci.draw_rect(Rect2(r.position, Vector2(110, r.size.y)), Fita.ETIQUETA_SOMBRA)
		Hud.texto(ci, Fita.marcador(), 70, r.position + Vector2(150, 40), "A noite na fita", Fita.TINTA)
		var faixas := ["A Centelha", "A Viga", "O Molde", "O Impacto", "A Galeria", "O Canto", "Os Caminhos", "A Voz", "A Prova"]
		var donos := [1, 0, 3, 1, 2, 0, 1, 3, 1]
		for i in faixas.size():
			var y := r.position.y + 170 + i * 80
			Hud.texto(ci, Fita.vt(), 46, Vector2(r.position.x + 150, y), "%02d" % (i + 1), Fita.TINTA_SUAVE)
			Hud.texto(ci, Fita.archivo(600), 46, Vector2(r.position.x + 240, y), faixas[i], Fita.TINTA)
			ci.draw_rect(Rect2(r.end.x - 240, y + 8, 14, 44), Fita.JOGADOR[donos[i]])
			Hud.texto(ci, Fita.bungee(), 40, Vector2(r.end.x - 210, y + 4), "P%d" % (donos[i] + 1), Fita.TINTA), 10)
