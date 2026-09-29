class_name SalaViga
extends SalaJogo
## A Viga — equilíbrio e mira por movimento.
##
## Três trechos, um atrás do outro, cada um com o uso de sensor de um tipo de
## jogo:
##
##   1. a travessia: o boneco anda sozinho por uma viga sobre a lava e o vento
##      empurra; você o equilibra INCLINANDO o controle para os lados (a
##      rolagem) — o equilíbrio dos jogos de plataforma;
##   2. os sinos: três sinos pendurados no fundo; a mira anda quando você GIRA
##      o controle (guinada e arfagem), como a mira por giroscópio dos jogos de
##      tiro; R1 ou ✕ arremessa o martelo, L1 centraliza a mira;
##   3. a pedra: uma MARTELADA — sacudir o controle para baixo, um pico no
##      acelerômetro — quebra a pedra que guarda o baú.
##
## O módulo mede o pico de giro em cada eixo, a taxa declarada contra a medida,
## se o giro anda para o mesmo lado da gravidade (um eixo invertido no caminho
## aparece aqui), a gravidade parado (1 g), a inclinação que a gravidade viu e
## as marteladas. Sem giroscópio, a sala joga com os analógicos e o ✕, e o
## veredito é NÃO MEDIDO, com o porquê.

const F := preload("res://scripts/forja.gd")
const RAIAS := [-6.0, -2.0, 2.0, 6.0]
## o caminho do boneco: da plataforma da largada à do fim, passando pela viga
## (o poço de lava vai de z = +3 a z = -2)
const Z_LARGADA := 3.5
const Z_CHEGADA := -2.5
const Z_VIGA_INI := 3.2
const Z_VIGA_FIM := -2.2
const Z_PEDRA := -3.55
const Z_BAU := -5.0
const Z_SINOS := -5.6
const ROLAGEM_CHEIA := 0.45  ## rad (~26°): a inclinação que vale "tudo"
const SENSIBILIDADE := 2.2  ## metros da mira por radiano girado
const N_SINOS := 3
const G_MARTELADA := 1.8
const RAIO_ACERTO := 0.32
## a área da mira em cada raia: meia largura e a faixa de altura
const MIRA_X := 1.45
const MIRA_Y0 := 1.2
const MIRA_Y1 := 2.45
const TETO := 4.1

enum { VIGA, SINOS, PEDRA, FIM }

var j := {}  ## lugar -> o estado do jogador
var n := {}  ## lugar -> os nós da raia
var _mat_ouro: StandardMaterial3D
var _mat_ferro: StandardMaterial3D


func _init() -> void:
	id = "viga"
	nome = "A Viga"
	acao = "Equilibre, mire e martele com o controle."
	gesto_do_aviso = "attack-melee-right"
	objetivo = "Na viga, o vento empurra: incline o controle para o outro lado. Nos sinos, gire o controle para mirar e arremesse com R1 (L1 centraliza). Na pedra, sacuda o controle para baixo, com vontade."
	features = ["giroscopio", "acelerometro"]
	duracao = 80.0
	camera_pos = Vector3(0, 10.2, 9.6)
	camera_olhar = Vector3(0, 0.84, -1.4)


func montar() -> void:
	_mat_ouro = Kit.material(Color("#e2b04a"), 0.25, 0.3)
	_mat_ouro.metallic = 0.8
	_mat_ferro = Kit.material(Color("#4a4e5e"), 0.0, 0.5)
	_cenario()
	for p in jogadores:
		var l: int = p.lugar
		j[l] = _novo_jogador(l)
		n[l] = _montar_raia(l, p)
		Forja.gatilhos_off(l)


func sair() -> void:
	for p in jogadores:
		var l: int = p.lugar
		p.preso = false
		if p.modelo:
			p.modelo.rotation = Vector3.ZERO
		# a vara fica na sala (o que ele levava volta pela base)
		if n.has(l) and is_instance_valid(n[l].vara):
			n[l].vara.queue_free()
	super()


func _novo_jogador(l: int) -> Dictionary:
	var sinos: Array = []
	for i in N_SINOS:
		# espalhados na largura e alternando alto e baixo: mirar pede guinada E arfagem
		var fx := 0.1 + 0.8 * (i + 0.2 + 0.6 * rng.randf()) / N_SINOS
		var fy := (0.72 if i % 2 else 0.12) + 0.16 * rng.randf()
		sinos.append({"x": -MIRA_X + 2.0 * MIRA_X * fx, "y": MIRA_Y1 - (MIRA_Y1 - MIRA_Y0) * fy,
			"vivo": true, "balanco": rng.randf() * 6.0})
	return {"trecho": VIGA, "t": 0.0, "progresso": 0.0, "checkpoint": 0.0, "inclinacao": 0.0,
		"bambo": 0.0, "caindo": 0.0, "quedas": 0, "fase_vento": rng.randf() * TAU,
		"freq_vento": 0.22 + 0.12 * rng.randf(), "rajada": 0.0, "rajada_t": 2.5 + 2.0 * rng.randf(),
		"sinos": sinos, "mira": _mira_centro(), "acertos": 0, "arremessos": 0,
		"golpes": 0, "pancada": 0.0, "acima": false, "robo_espera": -1.0,
		"tem_giro": Forja.capacidade(l, "giro"), "tem_acel": Forja.capacidade(l, "acel")}


static func _mira_centro() -> Vector2:
	return Vector2(0.0, (MIRA_Y0 + MIRA_Y1) * 0.5)


static func _aproximar(atual: float, alvo: float, taxa: float, dt: float) -> float:
	return alvo + (atual - alvo) * exp(-taxa * dt)


# ------------------------------------------------------------------ o cenário --

## A caverna da forja: as plataformas de pedra nas duas pontas, o poço de lava
## no meio, as paredes do kit em volta, as brasas subindo.
func _cenario() -> void:
	var K := Kit.K
	for i in range(-5, 6):
		var x := i * K
		for z in [4.0, -3.0, -5.0]:
			Kit.peca(self, "floor-detail" if (i + int(z)) % 5 == 0 else "floor", Vector3(x, 0, z), (absi(i) % 4) * PI * 0.5)
		Kit.peca(self, "wall", Vector3(x, 0, -7.0))
		Kit.peca(self, "wall-half", Vector3(x, 0, 6.0))
	for z in [-5.0, -3.0, -1.0, 1.0, 3.0, 5.0]:
		Kit.peca(self, "wall", Vector3(-12.0, 0, z))
		Kit.peca(self, "wall", Vector3(12.0, 0, z))
	# os blocos de pedra que seguram as plataformas e as paredes do poço
	var pedra := Kit.material(Color("#5a5270"), 0.0, 0.95)
	Kit.caixa(self, Vector3(24, 3.0, 2.0), Vector3(0, -1.5, 4.0), pedra)
	Kit.caixa(self, Vector3(24, 3.0, 4.0), Vector3(0, -1.5, -4.0), pedra)
	for lado in [-1.0, 1.0]:
		Kit.caixa(self, Vector3(2.0, 3.0, 5.0), Vector3(lado * 12.0, -1.5, 0.5), pedra)
	# a lava: a superfície ondula e brilha
	var lava := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(24, 5.0)
	lava.mesh = plano
	lava.position = Vector3(0, -1.45, 0.5)
	var sm := ShaderMaterial.new()
	sm.shader = _shader_lava()
	lava.material_override = sm
	add_child(lava)
	for x in [-8.0, 0.0, 8.0]:
		var brilho := OmniLight3D.new()
		brilho.position = Vector3(x, -0.7, 0.5)
		brilho.light_color = Color("#ff7a2a")
		brilho.light_energy = 1.7
		brilho.omni_range = 7.5
		add_child(brilho)
	Efeitos.brasas(self, Vector3(0, -1.2, 0.5), Vector3(22, 0.2, 4.6), Tema.LARANJA, 70)
	luzes([Vector3(-10, 2.8, -5.4), Vector3(10, 2.8, -5.4), Vector3(0, 3.4, 4.8)])
	# a lava: o preenchimento vermelho e o neon laranja
	atmosfera(Color("#ff6a3d"), Tema.LARANJA, false, 30, 22.0, -7.8, 0.3)


func _shader_lava() -> Shader:
	var s := Shader.new()
	s.code = """
shader_type spatial;
uniform vec3 quente : source_color = vec3(1.0, 0.56, 0.14);
uniform vec3 escuro : source_color = vec3(0.32, 0.05, 0.02);
float onda(vec2 p, float t) {
	return sin(p.x * 1.9 + t * 1.3) * sin(p.y * 2.3 - t * 0.9)
		+ 0.6 * sin((p.x - p.y) * 1.1 + t * 0.7)
		+ 0.35 * sin(p.x * 4.1 - p.y * 3.3 + t * 2.1);
}
void fragment() {
	vec2 p = UV * vec2(24.0, 6.4) * 0.55;
	float n = clamp((onda(p, TIME) * 0.5 + 0.5) / 1.3, 0.0, 1.0);
	vec3 c = mix(escuro, quente, smoothstep(0.25, 0.85, n));
	ALBEDO = c * 0.25;
	ROUGHNESS = 0.55;
	EMISSION = c * (0.9 + 2.4 * smoothstep(0.62, 1.0, n));
}
"""
	return s


func _montar_raia(l: int, p: ForjaPlayer) -> Dictionary:
	var x: float = RAIAS[l]
	var cor: Color = Forja.cor_do_lugar(l)
	var e: Dictionary = j[l]
	# a viga: a tábua, as cintas de ferro, as bandeirolas dos pontos de volta
	var madeira := Kit.material(Color("#8a5a33"), 0.0, 0.85)
	Kit.caixa(self, Vector3(0.46, 0.22, Z_VIGA_INI - Z_VIGA_FIM), Vector3(x, -0.11, (Z_VIGA_INI + Z_VIGA_FIM) * 0.5), madeira)
	for k in range(1, 7):
		Kit.caixa(self, Vector3(0.5, 0.25, 0.08), Vector3(x, -0.11, lerpf(Z_VIGA_INI, Z_VIGA_FIM, k / 7.0)), _mat_ferro)
	var bandeiras: Array = []
	for k in [1, 2]:
		var z := lerpf(Z_LARGADA, Z_CHEGADA, k / 3.0)
		Kit.cilindro(self, 0.025, 0.9, Vector3(x + 0.3, 0.45, z), _mat_ferro)
		var b := Kit.caixa(self, Vector3(0.36, 0.22, 0.03), Vector3(x + 0.48, 0.78, z), Kit.material(Color("#6b4a2e")))
		bandeiras.append(b)
	# os sinos: cada um pendurado por uma corrente, balançando
	var sinos: Array = []
	for i in N_SINOS:
		var s: Dictionary = e.sinos[i]
		var pivo := Node3D.new()
		pivo.position = Vector3(x + float(s.x), TETO, Z_SINOS)
		add_child(pivo)
		var comprimento := TETO - float(s.y) - 0.22
		Kit.cilindro(pivo, 0.016, comprimento, Vector3(0, -comprimento * 0.5, 0), _mat_ferro)
		var sino := Node3D.new()
		sino.position = Vector3(0, -comprimento - 0.22, 0)
		pivo.add_child(sino)
		Kit.esfera(sino, 0.11, Vector3(0, 0.2, 0), _mat_ouro)
		Kit.cilindro(sino, 0.28, 0.4, Vector3.ZERO, _mat_ouro, 0.11)
		Kit.esfera(sino, 0.055, Vector3(0, -0.22, 0), _mat_ferro)
		sinos.append(pivo)
	# a mira: um anel na cor do lugar, com as quatro marcas e o ponto
	var mira := Node3D.new()
	add_child(mira)
	var tinta := Kit.chapado(Tema.tom_para_a_borda(cor), true)
	var anel := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.2
	tor.outer_radius = 0.25
	tor.rings = 40
	anel.mesh = tor
	anel.rotation.x = PI * 0.5
	anel.material_override = tinta
	mira.add_child(anel)
	for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		var tam := Vector3(0.2, 0.04, 0.02) if d.y == 0 else Vector3(0.04, 0.2, 0.02)
		Kit.caixa(mira, tam, Vector3(d.x * 0.36, d.y * 0.36, 0), tinta)
	Kit.esfera(mira, 0.035, Vector3.ZERO, Kit.chapado(Tema.FG, true))
	mira.visible = false
	# a pedra que guarda o baú, com as rachaduras que acendem na primeira martelada
	var pedra := Kit.peca(self, "rocks", Vector3(x, 0, Z_PEDRA), l * 1.3, 1.6)
	var racha := Node3D.new()
	racha.position = Vector3(x, 0.4, Z_PEDRA + 0.8)
	add_child(racha)
	var brasa := Kit.chapado(Color("#ffb040"))
	var r1 := Kit.caixa(racha, Vector3(0.05, 0.36, 0.02), Vector3(-0.08, 0.02, 0), brasa)
	r1.rotation.z = 0.5
	var r2 := Kit.caixa(racha, Vector3(0.05, 0.3, 0.02), Vector3(0.06, -0.14, 0), brasa)
	r2.rotation.z = -0.4
	racha.visible = false
	var fogo_pedra := OmniLight3D.new()
	fogo_pedra.position = Vector3(x, 0.6, Z_PEDRA + 1.1)
	fogo_pedra.light_color = Color("#ff8a3a")
	fogo_pedra.light_energy = 0.0
	fogo_pedra.omni_range = 3.0
	add_child(fogo_pedra)
	var bau := Kit.peca(self, "chest", Vector3(x, 0, Z_BAU), 0.0, 2.0)
	# a régua do equilíbrio, em cima do boneco
	var regua := Node3D.new()
	add_child(regua)
	Kit.caixa(regua, Vector3(1.6, 0.09, 0.02), Vector3.ZERO, Kit.chapado(Color(Tema.TRILHO, 0.92), true))
	for lado in [-1.0, 1.0]:
		Kit.caixa(regua, Vector3(0.2, 0.11, 0.02), Vector3(lado * 0.7, 0, 0.001), Kit.chapado(Color(Tema.VERMELHO, 0.85), true))
	var marca := Kit.caixa(regua, Vector3(0.09, 0.3, 0.02), Vector3(0, 0, 0.002), Kit.chapado(Tema.AMARELO, true))
	# os riscos do vento
	var riscos: Array = []
	for k in 10:
		var r := Kit.caixa(self, Vector3(0.55, 0.018, 0.018), Vector3.ZERO, Kit.chapado(Color(1, 1, 1, 0.0)))
		riscos.append(r)
	# o boneco: mãos livres, a vara de equilíbrio na altura das mãos
	maos_livres(p)
	p.preso = true
	p.position = Vector3(x, 0.0, Z_LARGADA)
	p.rotation.y = PI
	var vara := Node3D.new()
	vara.position = Vector3(0, 0.36, 0.13)
	p.modelo.add_child(vara)
	var cabo := Kit.cilindro(vara, 0.011, 1.3, Vector3.ZERO, madeira)
	cabo.rotation.z = PI * 0.5
	for lado in [-1.0, 1.0]:
		Kit.esfera(vara, 0.03, Vector3(lado * 0.65, 0, 0), _mat_ferro)
	return {"sinos": sinos, "bandeiras": bandeiras, "mira": mira, "pedra": pedra, "racha": racha,
		"fogo_pedra": fogo_pedra, "bau": bau, "regua": regua, "marca": marca, "riscos": riscos,
		"vara": vara}


# ------------------------------------------------------------------ o jogo --

func jogar(dt: float) -> void:
	for p in jogadores:
		var l: int = p.lugar
		var e: Dictionary = j[l]
		if acabou[l] or not Forja.lugar(l).get("conectado", false):
			continue
		if Forja.robo:
			_robo(l, e, dt)
		e.t += dt
		match int(e.trecho):
			VIGA:
				_travessia(l, p, e, dt)
			SINOS:
				_sinos(l, p, e, dt)
			PEDRA:
				_pedra(l, p, e, dt)


## O vento: uma onda lenta que cresce ao longo da viga, e as rajadas.
func _vento(e: Dictionary) -> float:
	var amp := 0.3 + 0.45 * float(e.progresso)
	var v := amp * sin(t_fase * float(e.freq_vento) * TAU + float(e.fase_vento))
	v += 0.12 * sin(t_fase * 1.7 + float(e.fase_vento) * 2.0)
	return v + float(e.rajada)


## Quanto o jogador inclina: a rolagem do controle (lado direito para baixo é
## rolagem negativa e inclina o boneco para a direita); sem giroscópio, a
## gravidade; sem nada, o analógico esquerdo.
func _controle(l: int, e: Dictionary) -> float:
	if e.tem_giro:
		return -Forja.postura(l).x / ROLAGEM_CHEIA
	if e.tem_acel:
		var a := Forja.acel(l)
		return -atan2(a.x, sqrt(a.y * a.y + a.z * a.z)) / ROLAGEM_CHEIA
	return Forja.eixo(l, F.LX)


func _travessia(l: int, p: ForjaPlayer, e: Dictionary, dt: float) -> void:
	if e.caindo > 0.0:
		e.caindo += dt
		if e.caindo > 1.3:
			# volta na última bandeirola
			e.caindo = 0.0
			e.progresso = e.checkpoint
			e.inclinacao = 0.0
			e.bambo = 0.0
			Efeitos.anel(self, _pos_do_boneco(l, e) + Vector3(0, 0.9, 0), Forja.cor_do_lugar(l), 0.6)
		return
	# as rajadas: um empurrão curto, para um lado sorteado
	e.rajada_t -= dt
	if e.rajada_t <= 0.0:
		var lado := -1.0 if rng.randf() < 0.5 else 1.0
		e.rajada = lado * (0.35 + 0.25 * rng.randf())
		e.rajada_t = 2.2 + 2.0 * rng.randf()
		Som.tocar("vento", p.global_position + Vector3(-lado * 3.0, 1.2, 0), -14.0)
	e.rajada = _aproximar(e.rajada, 0.0, 1.4, dt)
	var alvo := clampf(_vento(e) + _controle(l, e), -1.6, 1.6)
	e.inclinacao = _aproximar(e.inclinacao, alvo, 7.0, dt)
	var mod := absf(e.inclinacao)
	e.progresso += dt * (0.075 if mod < 0.6 else 0.035)
	for k in [1, 2]:
		if e.progresso >= k / 3.0 and e.checkpoint < k / 3.0:
			e.checkpoint = k / 3.0
			var b: MeshInstance3D = n[l].bandeiras[k - 1]
			b.material_override = Kit.material(Tema.AMARELO, 1.2)
			Som.tocar("tique", b.global_position, -6.0, 1.3)
	# em cima da viga (não nas plataformas), quem passa do limite cai
	var na_viga: bool = e.progresso > 0.08 and e.progresso < 0.93
	e.bambo = e.bambo + dt if mod > 1.0 and na_viga else maxf(0.0, e.bambo - dt)
	if e.bambo > 0.45:
		e.caindo = 0.001
		e.quedas += 1
		Som.tocar("falha", p.global_position, -4.0)
		p.gesto("fall", 1.3)
		Forja.vibrar(l, 0.6, 0.2, 180)
		var onde := _pos_do_boneco(l, e)
		Efeitos.faiscas(self, Vector3(onde.x + e.inclinacao * 0.8, -1.3, onde.z), Tema.LARANJA, 30, 0.9)
	if e.progresso >= 1.0:
		e.progresso = 1.0
		marcar(l, 500 - 80 * int(e.quedas) if e.quedas < 5 else 100)
		_novo_trecho(l, p, e, SINOS)


func _sinos(l: int, p: ForjaPlayer, e: Dictionary, dt: float) -> void:
	var m: Vector2 = e.mira
	if e.tem_giro:
		# girar para a esquerda (guinada positiva) leva a mira para a esquerda;
		# erguer a borda de longe (arfagem positiva) leva a mira para cima
		var g := Forja.giro(l)
		m.x -= g.y * SENSIBILIDADE * dt
		m.y += g.x * SENSIBILIDADE * dt
	else:
		m.x += Forja.eixo(l, F.RX) * 2.6 * dt
		m.y -= Forja.eixo(l, F.RY) * 2.6 * dt
	if Forja.apertou(l, F.L1):
		m = _mira_centro()
		Som.tocar("tique", p.global_position, -10.0, 0.8)
	m.x = clampf(m.x, -MIRA_X, MIRA_X)
	m.y = clampf(m.y, MIRA_Y0, MIRA_Y1)
	e.mira = m
	if Forja.apertou(l, F.R1) or Forja.apertou(l, F.CRUZ):
		e.arremessos += 1
		var alvo := Vector3(RAIAS[l] + m.x, m.y, Z_SINOS + 0.1)
		var acertou := -1
		for i in N_SINOS:
			var s: Dictionary = e.sinos[i]
			if s.vivo and Vector2(float(s.x) - m.x, float(s.y) - m.y).length() < RAIO_ACERTO:
				s.vivo = false
				acertou = i
				e.acertos += 1
				marcar(l, 150 + int(maxf(0.0, 100.0 - e.t * 5.0)))
				break
		_arremessar(l, p, alvo, acertou)
	if e.acertos >= N_SINOS:
		_novo_trecho(l, p, e, PEDRA)


## O martelo voa da mão até a mira; se pegou um sino, ele toca e cai.
func _arremessar(l: int, p: ForjaPlayer, alvo: Vector3, sino: int) -> void:
	p.gesto("attack-melee-right", 0.45)
	var m := Kit.martelo(self, 1.1)
	var de := p.global_position + Vector3(0.3, 1.3, -0.3)
	m.global_position = de
	var tw := m.create_tween()
	var voo := func(k: float):
		var q := de.lerp(alvo, k)
		q.y += sin(k * PI) * 0.9
		m.global_position = q
		m.rotation.x = -k * TAU * 1.5
	tw.tween_method(voo, 0.0, 1.0, 0.32)
	if sino >= 0:
		var pivo: Node3D = n[l].sinos[sino]
		var some := func() -> void:
			pivo.visible = false
		var tocou := func() -> void:
			Som.tocar("sino_viga", alvo, 0.0, [1.0, 0.84, 1.19][sino])
			Som.no_controle(l, "sino_viga", 0.6)
			Efeitos.faiscas(self, alvo, Tema.AMARELO, 30, 1.0)
			Efeitos.anel(self, alvo, Tema.AMARELO, 0.5)
			Forja.vibrar(l, 0.0, 0.35, 70)
			var cai := pivo.create_tween()
			cai.tween_property(pivo, "rotation:z", 0.9 * (1.0 if sino % 2 else -1.0), 0.18)
			cai.tween_property(pivo, "scale", Vector3.ONE * 0.01, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			cai.tween_callback(some)
		tw.tween_callback(tocou)
	else:
		var errou := func() -> void:
			Som.tocar("tique", alvo, -8.0, 0.7)
		tw.tween_callback(errou)
	tw.tween_callback(m.queue_free)


func _pedra(l: int, p: ForjaPlayer, e: Dictionary, dt: float) -> void:
	e.pancada = move_toward(e.pancada, 0.0, dt * 5.0)
	var golpe := false
	if e.tem_acel:
		var g := Forja.acel(l).length() / 9.80665
		if g >= G_MARTELADA and not e.acima:
			e.acima = true
			golpe = true
		elif g < 1.3:
			e.acima = false
	else:
		golpe = Forja.apertou(l, F.CRUZ)
	if not golpe or e.t < 0.3:
		return
	e.golpes += 1
	e.pancada = 1.0
	if e.tem_acel:
		Forja.med_martelada(l)
	var x: float = RAIAS[l]
	var ponto := Vector3(x, 0.6, Z_PEDRA + 0.7)
	p.gesto("attack-melee-right", 0.45)
	Efeitos.faiscas(self, ponto, Tema.LARANJA, 34, 1.1)
	Som.tocar("martelo", ponto, 0.0)
	Som.no_controle(l, "pedra" if e.golpes >= 2 else "martelo", 0.7)
	Forja.vibrar(l, 0.8, 0.4, 120)
	var nos: Dictionary = n[l]
	nos.racha.visible = true
	nos.fogo_pedra.light_energy = 1.4
	if e.golpes >= 2:
		marcar(l, 200)
		_quebrar(l)
		_novo_trecho(l, p, e, FIM)


## A pedra se parte em cacos, o baú abre e o ouro brilha.
func _quebrar(l: int) -> void:
	var nos: Dictionary = n[l]
	var x: float = RAIAS[l]
	nos.pedra.visible = false
	nos.racha.visible = false
	Efeitos.faiscas(self, Vector3(x, 0.8, Z_PEDRA), Tema.AMARELO, 60, 1.4)
	for k in 6:
		var caco := Kit.peca(self, "stones", Vector3(x, 0.4, Z_PEDRA), rng.randf() * TAU, 0.55)
		var ang := k * TAU / 6.0 + rng.randf() * 0.5
		var de := Vector3(x, 0.4, Z_PEDRA)
		var destino := Vector3(x + cos(ang) * 1.6, -2.0, Z_PEDRA + sin(ang) * 1.2 + 0.6)
		var voa := func(q: float) -> void:
			var pos := de.lerp(destino, q)
			pos.y = 0.4 + sin(q * PI) * 1.4 - q * q * 2.4
			caco.position = pos
		var tw := caco.create_tween().set_parallel(true)
		tw.tween_method(voa, 0.0, 1.0, 0.9)
		tw.tween_property(caco, "rotation", Vector3(rng.randf() * 6.0, rng.randf() * 6.0, 0), 0.9)
		tw.chain().tween_callback(caco.queue_free)
	var anim: AnimationPlayer = nos.bau.find_child("AnimationPlayer", true, false)
	if anim and anim.has_animation("open"):
		anim.play("open")
	var ouro := OmniLight3D.new()
	ouro.position = Vector3(x, 1.0, Z_BAU + 0.4)
	ouro.light_color = Color("#ffd479")
	ouro.light_energy = 2.2
	ouro.omni_range = 3.5
	add_child(ouro)
	nos.fogo_pedra.light_energy = 0.0
	var moeda := Kit.peca(self, "coin", Vector3(x, 0.4, Z_BAU + 0.2), 0.0, 1.6)
	var tw2 := moeda.create_tween().set_parallel(true)
	tw2.tween_property(moeda, "position:y", 1.9, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw2.tween_property(moeda, "rotation:y", TAU * 3.0, 2.4)


func _novo_trecho(l: int, p: ForjaPlayer, e: Dictionary, trecho: int) -> void:
	e.trecho = trecho
	e.t = 0.0
	var onde := p.global_position + Vector3(0, 1.2, 0)
	match trecho:
		SINOS:
			Forja.med_pedir(l, "mira")
			e.mira = _mira_centro()
			n[l].vara.visible = false
		PEDRA:
			Forja.med_pedir(l, "martelada")
			martelo_na_mao(p)
		FIM:
			acabou[l] = true
			Som.tocar("sucesso", onde)
			p.gesto("emote-yes", 1.6)
			return
	Som.tocar("confirma", onde, -4.0)


# ------------------------------------------------------------------ o que se vê --

func _pos_do_boneco(l: int, e: Dictionary) -> Vector3:
	var x: float = RAIAS[l]
	match int(e.trecho):
		VIGA:
			return Vector3(x, 0.0, lerpf(Z_LARGADA, Z_CHEGADA, float(e.progresso)))
	return Vector3(x, 0.0, Z_CHEGADA)


func _process(dt: float) -> void:
	super(dt)
	for p in jogadores:
		_mostrar(p.lugar, p, dt)


func _mostrar(l: int, p: ForjaPlayer, dt: float) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = n[l]
	var x: float = RAIAS[l]
	var trecho := int(e.trecho) if fase != "aviso" else VIGA
	var pos := _pos_do_boneco(l, e)
	var incl: float = e.inclinacao if trecho == VIGA else 0.0
	if e.caindo > 0.0:
		var c: float = e.caindo
		pos.y -= c * c * 3.2
		pos.x += incl * c * 0.9
	p.position = pos
	p.rotation.y = PI
	if p.modelo:
		p.modelo.rotation.z = incl * 0.5 + (incl * float(e.caindo) * 1.2 if e.caindo > 0.0 else 0.0)
	var andando: bool = fase == "jogo" and trecho == VIGA and e.caindo == 0.0 and not acabou[l]
	if andando:
		p.animar("walk", 0.55 if absf(incl) < 0.6 else 0.3)
	else:
		p.animar("idle")
	# a vara acompanha o susto
	nos.vara.rotation.z = -incl * 0.25
	# a régua do equilíbrio, em cima do boneco
	var regua: Node3D = nos.regua
	regua.visible = fase == "jogo" and trecho == VIGA and e.caindo == 0.0
	regua.position = pos + Vector3(0, 2.35, 0)
	var marca: MeshInstance3D = nos.marca
	marca.position.x = clampf(incl / 1.15, -1.0, 1.0) * 0.72
	var tinta: StandardMaterial3D = marca.material_override
	tinta.albedo_color = Tema.VERMELHO if absf(incl) > 1.0 else Tema.AMARELO
	# o vento: riscos que correm para o lado dele
	var v := _vento(e) if fase == "jogo" and trecho == VIGA else 0.0
	var quantos := int(absf(v) * 12.0)
	for k in nos.riscos.size():
		var r: MeshInstance3D = nos.riscos[k]
		r.visible = k < quantos
		if not r.visible:
			continue
		var ciclo := fmod(t * (0.9 + 0.1 * k) + k * 0.37, 1.0)
		var dx := (ciclo - 0.5) * 3.4 * signf(v)
		r.position = Vector3(x + dx, 0.35 + fmod(k * 0.53, 1.7), pos.z + (k % 3 - 1) * 0.7)
		var mr: StandardMaterial3D = r.material_override
		mr.albedo_color = Color(1, 1, 1, 0.55 * (1.0 - absf(ciclo - 0.5) * 2.0))
	# os sinos balançam
	for i in N_SINOS:
		var pivo: Node3D = nos.sinos[i]
		var s: Dictionary = e.sinos[i]
		s.balanco = float(s.balanco) + dt * 2.2
		if s.vivo:
			pivo.rotation.z = sin(float(s.balanco)) * 0.12
	# a mira
	var mira: Node3D = nos.mira
	mira.visible = fase == "jogo" and trecho == SINOS and not acabou[l]
	var m: Vector2 = e.mira
	mira.position = Vector3(x + m.x, m.y, Z_SINOS + 0.35)
	# a pedra treme na martelada
	var pedra: Node3D = nos.pedra
	pedra.position.x = x + float(e.pancada) * 0.06 * sin(t * 70.0)


# ------------------------------------------------------------------ a HUD --

func status(lugar: int) -> String:
	if fase == "jogo" and j.has(lugar) and not acabou[lugar]:
		var e: Dictionary = j[lugar]
		match int(e.trecho):
			VIGA:
				return "1 · viga %d%%" % int(float(e.progresso) * 100.0)
			SINOS:
				return "2 · sinos %d de %d" % [e.acertos, N_SINOS]
			PEDRA:
				return "3 · pedra %d de 2" % e.golpes
	return super(lugar)


func dica(lugar: int) -> Dictionary:
	if not j.has(lugar):
		return {}
	var e: Dictionary = j[lugar]
	var partes: Array = []
	match int(e.trecho):
		VIGA:
			partes = ["incline contra o vento"] if e.tem_giro or e.tem_acel else ["@stick_l", "contra o vento"]
		SINOS:
			partes = ["gire para mirar", "@r1", "arremessa"] if e.tem_giro else ["@stick_r", "mira", "@r1", "arremessa"]
		PEDRA:
			partes = ["sacuda para baixo"] if e.tem_acel else ["@cross", "martela"]
		FIM:
			partes = ["atravessou!"]
	return {"partes": partes, "pos": Vector3(RAIAS[lugar], 0.0, 5.0)}


# ------------------------------------------------------------------ o robô --
# Vê a inclinação do boneco, a mira e os sinos, e mexe o controle simulado como
# gente: inclina contra a queda, gira até a mira pousar no sino, sacode.

func _robo(l: int, e: Dictionary, dt: float) -> void:
	var gx := 0.0
	var gy := 0.0
	var gz := 0.0
	var post := Forja.postura(l)
	match int(e.trecho):
		VIGA:
			gz = clampf(4.2 * float(e.inclinacao) + (rng.randf() - 0.5) * 0.4, -3.0, 3.0)
		SINOS:
			gz = -2.5 * post.x
			var alvo := -1
			for i in N_SINOS:
				if e.sinos[i].vivo:
					alvo = i
					break
			if alvo >= 0:
				var m: Vector2 = e.mira
				var dx: float = float(e.sinos[alvo].x) - m.x
				var dy: float = float(e.sinos[alvo].y) - m.y
				gy = clampf(-6.0 * dx / SENSIBILIDADE, -4.5, 4.5)
				gx = clampf(6.0 * dy / SENSIBILIDADE, -4.5, 4.5)
				if Vector2(dx, dy).length() < 0.1:
					if e.robo_espera < 0.0:
						e.robo_espera = 0.15 + 0.3 * rng.randf()
					e.robo_espera -= dt
					if e.robo_espera <= 0.0:
						Forja.robo_apertar(l, F.R1, 0.08)
						e.robo_espera = -1.0
		PEDRA:
			gz = -2.5 * post.x
			gx = -2.5 * post.y
			if e.robo_espera < 0.0:
				e.robo_espera = 0.7 + 0.5 * rng.randf()
			e.robo_espera -= dt
			if e.robo_espera <= 0.0:
				Forja.robo_sacudir(l, 1.6, 0.2)
				if not e.tem_acel:
					Forja.robo_apertar(l, F.CRUZ, 0.08)
				e.robo_espera = 0.8 + 0.4 * rng.randf()
		FIM:
			gz = -2.5 * post.x
			gx = -2.5 * post.y
	if e.tem_giro:
		Forja.robo_girar(l, Vector3(gx, gy, gz), 0.06)
	elif int(e.trecho) == VIGA:
		Forja.robo_eixo(l, F.LX, clampf(-1.5 * float(e.inclinacao), -1.0, 1.0), 0.06)
	elif int(e.trecho) == SINOS:
		var alvo2 := -1
		for i in N_SINOS:
			if e.sinos[i].vivo:
				alvo2 = i
				break
		if alvo2 >= 0:
			var m2: Vector2 = e.mira
			var d2 := Vector2(float(e.sinos[alvo2].x) - m2.x, float(e.sinos[alvo2].y) - m2.y)
			Forja.robo_eixo(l, F.RX, clampf(d2.x * 3.0, -1.0, 1.0), 0.06)
			Forja.robo_eixo(l, F.RY, clampf(-d2.y * 3.0, -1.0, 1.0), 0.06)
			if d2.length() < 0.1:
				Forja.robo_apertar(l, F.R1, 0.08)
