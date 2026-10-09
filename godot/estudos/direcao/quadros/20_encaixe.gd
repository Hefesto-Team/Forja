extends Node3D
## Quadro 20 — O encaixe (PRODUCAO, item 18; 04, o primeiro minuto): uma
## troca do superior de P1, em seis instantes da linha do tempo do 04, cada
## um numa miniatura de 640×540 (renderizada a 2×). A 120 BPM a semicolcheia
## tem 125 ms, a colcheia 250 ms, a batida 500 ms.
##
##     0 ms  a seta apertada cresce a 1,2; a peça velha afunda a 0,92
##   125 ms  o encaixe, na semicolcheia (o pior caso: o toque logo depois
##            de uma): a peça nova a 0,06 acima e na escala 0,9, as 8
##            faíscas e o acento a 2,6, no mesmo quadro
##   190 ms  4 quadros depois: a peça assentada na escala 1,0; as faíscas
##            ainda no ar (12 quadros); o acento descendo, `SAI`
##   375 ms  o encaixe + a colcheia: a pose da linha (holding-both), o
##            acento de volta a 1,6, o giro começa
##   500 ms  a plataforma a 25° (a ida de 120 ms acabou em 495 ms)
##  1000 ms  o descanso: a pose (500 ms) e a volta do giro acabam em 875 ms,
##            o idle chega em 120 ms; a troca inteira cabe em 1 s
##
## 1920×1080, 50 mm frontal à altura do peito, como a montagem (10).

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")
const Prancha := preload("res://estudos/direcao/prancha.gd")
const Montar := preload("res://estudos/direcao/cavaleiro/montar.gd")
const Cortar := preload("res://estudos/direcao/cavaleiro/cortar.gd")
const Sis := preload("res://estudos/direcao/cavaleiro/sistemas.gd")

var espera := 12
var arquivo := "20_encaixe"
var folha: SubViewport
const TAM := Vector2i(1920, 1080)
const MINI := Vector2i(640, 540)
## O cavaleiro: o P1 da montagem (o orc), trocando o superior.
const RACA := "orc"
const VELHO := ["male-c", "female-f", "male-a"]
const NOVO := ["male-c", "male-e", "male-a"]
const CAI := 0.06               ## a queda da peça nova, nas unidades do personagem
## Os instantes: o ms, as duas linhas da legenda e o estado da cena.
##   pecas: 0 a velha, 1 a nova; queda: a fração dos 0,06 que falta cair;
##   escala: a da peça que muda; acento: a energia; faiscas: o leque (0 sem
##   faísca); anim; yaw (°);
##   seta: a escala da seta ▶
const INSTANTES := [
	{"ms": 0, "l1": "0 ms · o toque", "l2": "a seta a 1,2, a peça velha a 0,92",
		"pecas": 0, "queda": 0.0, "escala": 0.92, "acento": 1.6, "faiscas": 0.0, "anim": "idle", "t": 0.30, "yaw": 0.0, "seta": 1.2},
	{"ms": 125, "l1": "125 ms · o encaixe", "l2": "a peça a 0,06 acima, 8 faíscas, acento 2,6",
		"pecas": 1, "queda": 1.0, "escala": 0.9, "acento": 2.6, "faiscas": 1.0, "anim": "idle", "t": 0.36, "yaw": 0.0, "seta": 1.0},
	{"ms": 190, "l1": "190 ms · a peça assentada", "l2": "escala 1,0; as faíscas no ar",
		"pecas": 1, "queda": 0.0, "escala": 1.0, "acento": 2.0, "faiscas": 1.8, "anim": "idle", "t": 0.42, "yaw": 0.0, "seta": 1.0},
	{"ms": 375, "l1": "375 ms · a pose da linha", "l2": "holding-both, o acento em 1,6",
		"pecas": 1, "queda": 0.0, "escala": 1.0, "acento": 1.6, "faiscas": 0.0, "anim": "holding-both", "t": 0.20, "yaw": 0.0, "seta": 1.0},
	{"ms": 500, "l1": "500 ms · a plataforma a 25°", "l2": "o giro para o centro da tela",
		"pecas": 1, "queda": 0.0, "escala": 1.0, "acento": 1.6, "faiscas": 0.0, "anim": "holding-both", "t": 0.45, "yaw": 25.0, "seta": 1.0},
	{"ms": 1000, "l1": "1000 ms · o descanso", "l2": "o idle, pronto para outra troca",
		"pecas": 1, "queda": 0.0, "escala": 1.0, "acento": 1.6, "faiscas": 0.0, "anim": "idle", "t": 0.30, "yaw": 0.0, "seta": 1.0},
]


func montar(_estudo) -> void:
	folha = Prancha.folha(self, TAM, Fita.FITA)
	for i in 6:
		var vp := Prancha.celula(self, MINI * 2, false)
		var raiz := Node3D.new()
		vp.add_child(raiz)
		_cena(raiz, Prancha.camera(vp), INSTANTES[i])
		Prancha.pregar(folha, vp, Rect2(_pos(i), Vector2(MINI)))
	Prancha.por_cima(folha, _texto)


func foto() -> Image:
	return await Prancha.foto(folha)


func _pos(i: int) -> Vector2:
	return Vector2((i % 3) * MINI.x, (i / 3) * MINI.y)


func _cena(raiz: Node3D, cam: Camera3D, s: Dictionary) -> void:
	Mundo.ambiente(raiz, {"ambiente": Color("#2a2738"), "ambiente_energia": 0.30, "nevoa": true,
		"nevoa_densidade": 0.012, "glow_intensidade": 0.7})
	for i in range(-3, 4):
		for j in range(-3, 1):
			Mundo.peca(raiz, "mini-dungeon/floor", Vector3(i * 2.0, 0, j * 2.0))
	Mundo.caixa(raiz, Vector3(24, 6, 0.3), Vector3(0, 3, -6.2), Fita.fosco(Fita.graduar(Color("#3a3346"), "cenario")))
	var cor: Color = Fita.JOGADOR[0]
	Mundo.foco(raiz, Vector3(1.6, 3.6, 3.2), Vector3(0, 0.8, 0), Fita.TUNGSTENIO, 3.2, 22.0, 9.0, true)
	Mundo.foco(raiz, Vector3(-0.4, 2.8, -2.6), Vector3(0, 1.0, 0), cor, 1.2, 26.0, 7.0)
	# a lente: 50 mm, à altura do peito, o cavaleiro inteiro no quadro
	Prancha.lente(cam, 50.0)
	cam.position = Vector3(0, 1.0, 6.0)
	cam.look_at(Vector3(0, 0.78, 0))
	cam.far = 60.0
	var pecas: Array = VELHO if int(s.pecas) == 0 else NOVO
	var yaw := deg_to_rad(float(s.yaw))
	var c := Montar.cavaleiro(raiz, 0, Vector3.ZERO, pecas, {"raca": RACA, "anim": s.anim, "t_anim": s.t,
		"yaw": yaw, "acento_energia": s.acento, "anel": true})
	# a peça que muda vai à parte, para cair e crescer sozinha
	var esq: Skeleton3D = c.get_meta("esqueleto")
	for nome in ["body-sup", "acento-friso"]:
		var n := esq.get_node_or_null(NodePath(nome))
		if n:
			n.visible = false
	var caixa: AABB = Cortar.partes(String(pecas[1])).caixa["superior"]
	var centro := caixa.get_center() * Mundo.K
	var e := float(s.escala)
	var pos := centro * (1.0 - e) + Vector3(0, CAI * Mundo.K * float(s.queda), 0)
	var peca := Montar.cavaleiro(raiz, 0, Vector3.ZERO, pecas, {"raca": RACA, "so": "superior", "anim": s.anim,
		"t_anim": s.t, "yaw": yaw, "acento_energia": s.acento, "anel": false})
	peca.scale = Vector3.ONE * e
	peca.position = pos.rotated(Vector3.UP, yaw)
	if float(s.faiscas) > 0.0:
		_faiscas(raiz, Vector3(0, caixa.end.y * Mundo.K, 0.25), cor, float(s.faiscas))
	Mundo.neon_sem_sombra(raiz)
	Mundo.pos(raiz, 5, {"grao": 0.025})


## As 8 faíscas do encaixe, na junta (a gola), quatro em cada ombro, em
## leque para fora, energia 2,4. `abre` é quanto o leque já se abriu: 1,0 no
## quadro do encaixe, 1,8 quatro quadros depois.
func _faiscas(raiz: Node3D, c: Vector3, cor: Color, abre: float) -> void:
	for i in 8:
		var lado := -1.0 if i < 4 else 1.0
		var k := i % 4
		var ang := deg_to_rad(-30.0 + 25.0 * k)
		var d := Vector3(lado * cos(ang), sin(ang), 0.2).normalized()
		var p := c + Vector3(lado * 0.36, -0.10, 0.0) + d * (0.12 + 0.05 * k) * abre
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.025, 0.12, 0.025)
		mi.mesh = b
		mi.material_override = Fita.neon(cor.lerp(Color.WHITE, 0.35), 2.4)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(mi)
		mi.position = p
		mi.look_at(p + d, Vector3.UP)
		mi.rotate_object_local(Vector3.RIGHT, PI * 0.5)


func _texto(ci: CanvasItem) -> void:
	var cor: Color = Fita.JOGADOR[0]
	for i in 6:
		var s: Dictionary = INSTANTES[i]
		var p := _pos(i)
		# a linha da montagem, no alto: ◀ Superior ▶, a seta apertada maior
		var r := Rect2(p + Vector2(24, 20), Vector2(MINI.x - 48, 44))
		Hud.caixa(ci, r, Fita.CASCO, 6, cor, 2)
		Hud.texto(ci, Fita.archivo(600), 30, r.position + Vector2(14, 3), "Superior", Fita.ETIQUETA)
		Hud.texto(ci, Fita.archivo(600), 30, r.position + Vector2(200, 3), "◀", Fita.MUDO)
		var nome: String = Sis.peca("superior", String((VELHO if int(s.pecas) == 0 else NOVO)[1])).nome
		Hud.texto(ci, Fita.archivo(500), 30, r.position + Vector2(230, 3), nome, Fita.ETIQUETA, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 290)
		var tam := int(round(30.0 * float(s.seta)))
		Hud.texto(ci, Fita.archivo(600), tam, r.position + Vector2(r.size.x - 40, 3 - (tam - 30) * 0.5), "▶",
			cor if float(s.seta) > 1.0 else Fita.MUDO)
		# a legenda, embaixo, numa faixa escura
		var faixa := Rect2(p + Vector2(0, MINI.y - 84), Vector2(MINI.x, 84))
		ci.draw_rect(faixa, Color(Fita.FITA, 0.82))
		Hud.texto(ci, Fita.vt(), 30, faixa.position + Vector2(20, 6), String(s.l1), Fita.ETIQUETA)
		Hud.texto(ci, Fita.vt(), 30, faixa.position + Vector2(20, 42), String(s.l2), Fita.MUDO)
		ci.draw_rect(Rect2(p, Vector2(MINI)), Fita.GRAFITE, false, 2.0)
