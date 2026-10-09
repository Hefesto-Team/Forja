class_name SalaProva
extends SalaJogo
## A Prova — duas equipes, tudo ligado.
##
## O padrão é o jogo de ação do PS5 inteiro de uma vez, que é onde um
## intermediário se prova: noventa segundos de partida com tudo ligado ao mesmo
## tempo, nos quatro controles —
##
##   - o analógico esquerdo anda; o direito e o giroscópio miram (L2 afina a
##     mira, e o gatilho resiste); R2 atira, com a parede e o clique da arma;
##   - a munição na tela (no Modo bancada, nas cinco luzinhas); vazia, o gatilho
##     solta e o clique seco sai no alto-falante do controle; □ recarrega;
##   - o tiro que vem da esquerda treme o motor da esquerda; a luz é a cor do
##     lugar (a da equipe é o disco no chão), pisca vermelho no golpe e
##     escurece com a vida, nunca abaixo de 30%;
##   - o passo no chão da arena (grama, cascalho, metal, água) nos atuadores;
##   - ✕ corre; o clique do touchpad solta a martelada quando o sino do
##     especial toca no controle de quem a carregou.
##
## A sala mede o que um jogo não mede: se, com tudo isso junto, a entrada
## continuou chegando (o giroscópio sem buraco) e se o SDL aceitou todas as
## saídas. No fim, a prova final às cegas: as luzinhas e a cor de cada
## controle, depois de noventa segundos de carga. O microfone fica de fora: no
## ar de uma sala, a voz de um é ouvida por todos (A Voz mede em turnos).

const F := preload("res://scripts/forja.gd")
const CONTAGEM_S := 3.0
const PARTIDA_S := 90.0
const VIDA_MAX := 3
const MUNICAO := 5
const RECARGA_S := 1.0
const VOLTA_S := 2.5
const TIRO_V := 15.5
const TIRO_VIDA := 1.6
const RAIO := 0.45
const ESPECIAL_S := 20.0
const MARTELADA_RAIO := 3.2
const VEL := 4.4
const PASSO_S := 0.42
const PERGUNTA_ESPERA := 1.0
const PERGUNTA_S := 8.0
const PLACAR_S := 3.0
const ARENA_X := 11.3
const ARENA_Z := 6.9
## Os pilares: nos quatro cantos, ou (a variante 1) em cata-vento — sempre
## simétricos pelo centro, para a Brasa e a Maré terem a mesma arena.
const PILARES := [Vector3(-4.4, 0, -3.4), Vector3(4.4, 0, -3.4), Vector3(-4.4, 0, 3.4), Vector3(4.4, 0, 3.4)]
const PILARES_CATAVENTO := [Vector3(-6.8, 0, 2.8), Vector3(6.8, 0, -2.8), Vector3(-2.2, 0, -4.2), Vector3(2.2, 0, 4.2)]
static var pilares: Array = PILARES
const RAIO_PILAR := 0.7
const METAL_X := 3.0  ## a faixa de metal no meio
const AGUA_Z := 0.9  ## o riacho que corta a arena
const CASCALHO := 1.7  ## o cascalho em volta dos pilares
const CORES := [
	{"nome": "âmbar", "cor": Color(1.0, 0.59, 0.0)},
	{"nome": "ciano", "cor": Color(0.0, 0.82, 1.0)},
	{"nome": "violeta", "cor": Color(0.67, 0.27, 1.0)},
	{"nome": "branco", "cor": Color(1.0, 1.0, 1.0)},
]
## a cor que a prova final não pode sortear: a que lembra a da equipe
const COR_PARECIDA := [0, 1]
const NOME_EQUIPE := ["Brasa", "Maré"]
const LUZ_EQUIPE := [Color(1.0, 0.27, 0.0), Color(0.0, 0.35, 1.0)]
const BOTAO := [F.CRUZ, F.CIRCULO, F.QUADRADO, F.TRIANGULO]
const GLIFO := ["cross", "circle", "square", "triangle"]
const COR_CHAO := [Tema.SECAO[2], Tema.OXIDO_BRILHO, Tema.MUDO, Tema.SECAO[1]]  ## grama, cascalho, metal, água

enum { CONTAGEM, PARTIDA, LEDS, COR, PLACAR, ACABOU }

var etapa := CONTAGEM
var t_etapa := 0.0
var lut: Array = []  ## os lutadores: os jogadores e os bonecos de treino
var lut_do_lugar := {}  ## lugar -> índice em lut
var tiros: Array = []  ## {no, pos, vel, vida, dono, equipe}
var placar := [0, 0]
var fin := {}  ## lugar -> a prova final e o que ela precisa


func _init() -> void:
	usa_gatilho = true
	id = "prova"
	nome = "A Prova"
	acao = "Brasa contra Maré."
	icone = "stick_l"
	gesto_do_aviso = "holding-right-shoot"
	objetivo = "Noventa segundos de partida com tudo ligado: o analógico esquerdo anda, o direito e o giroscópio miram (L2 afina, e o gatilho resiste), R2 atira com a parede e o clique da arma. A munição está nas cinco luzinhas; vazia, o gatilho solta e o clique sai no controle — □ recarrega. ✕ corre. O tiro da esquerda treme o motor da esquerda; a luz é a da sua equipe e apaga com a vida. Quando o sino tocar no seu controle, o clique do touchpad solta a martelada. No fim, diga as luzinhas e a cor do controle, sem olhar a tela."
	features = ["tudo_junto"]
	cega = true
	botoes_pedidos = F.mascara([F.CRUZ, F.CIRCULO, F.QUADRADO, F.TRIANGULO, F.TOUCHPAD])
	duracao = 0.0
	camera_pos = Vector3(0, 17.5, 13.2)
	camera_olhar = Vector3(0, 0, 0.9)
	# a arena de 22,6 × 13,8 m cabia a 24 m com 40°; a 35 mm são 24 × 1,0616 = 25,5 m
	camera_modo = "grupo"
	camera_distancia = Vector2(17.0, 25.5)


## A câmera enquadra quem está na partida; no aviso, todos os visíveis.
func alvos_da_camera() -> Array:
	var alvos: Array = []
	for p in jogadores:
		if p.visible and jogando[p.lugar]:
			alvos.append(p.global_position)
	return alvos if not alvos.is_empty() else super()


func montar() -> void:
	pilares = PILARES_CATAVENTO if variante == 1 else PILARES
	Kit.arena(self, 6, 4)
	# a arena: a Brasa de um lado, a Maré do outro
	atmosfera(Color("#ffb86c"), Tema.TUNGSTENIO, true, 40, 24.0, -9.8)
	Efeitos.poeira(self, Vector3(0, 1.8, 0), Vector3(24, 3.5, 9), Tema.VIOLETA, 30)
	luzes([Vector3(-10, 3.0, -6), Vector3(10, 3.0, -6), Vector3(-10, 3.0, 6), Vector3(10, 3.0, 6)])
	_montar_chao()
	for c in pilares:
		Kit.peca(self, "column", c, 0.0, 2.2)
		Kit.cilindro(self, CASCALHO, 0.03, c + Vector3(0, 0.03, 0), Kit.material(COR_CHAO[1], 0.0, 0.95))
	# o clique seco, o sino do especial e os passos saem do controle de cada um
	if not Forja.som_pronto():
		Forja.som_preparar(F.PAPEL_ALTO_FALANTE)
	_montar_lutadores()


## O chão da arena: grama nos campos das equipes, a faixa de metal no meio, o
## riacho que corta de lado a lado. O passo sentido na mão é o do chão.
func _montar_chao() -> void:
	for lado in [-1.0, 1.0]:
		var campo := Kit.caixa(self, Vector3(ARENA_X - METAL_X + 0.6, 0.03, ARENA_Z * 2 + 0.6),
			Vector3(lado * (METAL_X + (ARENA_X - METAL_X) * 0.5), 0.015, 0), Kit.material(COR_CHAO[0], 0.0, 0.95))
		campo.name = "campo"
		var base := Kit.cilindro(self, 1.3, 0.04, Vector3(lado * (ARENA_X - 1.5), 0.04, 0),
			Kit.material(LUZ_EQUIPE[0 if lado < 0 else 1].darkened(0.55), 0.3, 0.8))
		base.name = "base"
	var metal := Kit.material(COR_CHAO[2], 0.0, 0.5)
	metal.metallic = 0.2
	Kit.caixa(self, Vector3(METAL_X * 2, 0.04, ARENA_Z * 2 + 0.6), Vector3(0, 0.02, 0), metal)
	var agua := Kit.material(COR_CHAO[3], 0.4, 0.2)
	agua.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	agua.albedo_color.a = 0.8
	Kit.caixa(self, Vector3(ARENA_X * 2 + 0.6, 0.05, AGUA_Z * 2), Vector3(0, 0.035, 0), agua)


## O chão debaixo de um ponto (chao.h: 0 grama, 1 cascalho, 2 metal, 3 água).
static func chao_em(p: Vector3) -> int:
	for c in pilares:
		if Vector2(p.x - c.x, p.z - c.z).length() < CASCALHO:
			return 1
	if absf(p.x) < METAL_X:
		return 2
	if absf(p.z) < AGUA_Z:
		return 3
	return 0


func _novo_lutador(lugar: int, equipe: int) -> Dictionary:
	return {"lugar": lugar, "equipe": equipe, "pos": Vector3.ZERO, "mira": 0.0, "vida": VIDA_MAX, "fora": 0.0,
		"atordoado": 0.0, "dano": 0.0, "municao": MUNICAO, "recarga": 0.0, "corrida": 0.0, "corrida_espera": 0.0,
		"especial": 0.0, "avisou": false, "passo_t": 0.0, "passo_n": 0, "luz_pisca": 0.0, "pulso_t": 0.0,
		"luz_estado": -1, "arma": false, "r2_ant": 0.0, "acertos": 0, "derrubou": 0, "tiros": 0, "andando": 0.0,
		"ia_t": 0.0, "ia_alvo": Vector3.ZERO, "tiro_t": 1.0, "robo_tiro": 0.0, "robo_lado_t": 0.0, "robo_lado": 1,
		"robo_recarregou": false, "no": null, "anim": null, "disco": null, "mat_disco": null}


## As equipes: quatro, dois contra dois (P1 e P2 contra P3 e P4); três, dois
## contra um e um boneco de treino; dois, um contra um; sozinho, contra dois
## bonecos.
func _montar_lutadores() -> void:
	var lugares: Array = []
	for p in jogadores:
		lugares.append(p.lugar)
	var n_j := lugares.size()
	for i in n_j:
		var equipe := (0 if i < 2 else 1) if n_j >= 3 else i % 2
		var e := _novo_lutador(lugares[i], equipe)
		var p := jogador(lugares[i])
		p.preso = true
		p.controlavel = false
		martelo_na_mao(p)
		e.no = p
		lut_do_lugar[lugares[i]] = lut.size()
		lut.append(e)
	var bonecos := 2 if n_j == 1 else (1 if n_j == 3 else 0)
	for k in bonecos:
		var e := _novo_lutador(-1, 1)
		var modelo: Node3D = load(Kit.caminho("mini-dungeon-personagens/character-orc")).instantiate()
		modelo.scale = Vector3.ONE * ForjaPlayer.ESCALA
		add_child(modelo)
		_tingir(modelo, Color("#b9a98a"))
		e.no = modelo
		e.anim = modelo.find_child("AnimationPlayer", true, false)
		lut.append(e)
	for e in lut:
		# o disco da equipe debaixo de cada um
		var disco := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		cil.top_radius = 0.7
		cil.radial_segments = 8
		cil.bottom_radius = 0.7
		cil.height = 0.02
		disco.mesh = cil
		var mat := Kit.material(LUZ_EQUIPE[e.equipe], 1.0, 0.6, "forja")
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.55
		disco.material_override = mat
		add_child(disco)
		e.disco = disco
		e.mat_disco = mat
		_voltar(e)


static func _tingir(n: Node, cor: Color) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				var mat := StandardMaterial3D.new()
				mat.albedo_color = cor
				mat.roughness = 0.9
				mi.set_surface_override_material(s, mat)
	for filho in n.get_children():
		_tingir(filho, cor)


# ------------------------------------------------------------------ as saídas --
# Cada saída mandada na partida conta para a carga: o SDL aceitou?

func _saida(l: int, ok: bool) -> void:
	# com o cabo fora, a saída não chega a controle nenhum: não é o SDL recusando
	if l >= 0 and Forja.lugar(l).get("conectado", false):
		Forja.carga_saida(l, ok)


static func _mascara(n: int) -> int:
	return 0 if n <= 0 else (1 << mini(n, 5)) - 1


func _mostrar_municao(e: Dictionary) -> void:
	if not Forja.bancada:
		return  # o status já mostra as balas; as luzinhas são o número do lugar
	if e.lugar >= 0:
		_saida(e.lugar, Forja.leds_jogador(e.lugar, _mascara(int(e.municao))))


func _armar(e: Dictionary, arma: bool) -> void:
	if e.lugar < 0 or e.arma == arma:
		return
	e.arma = arma
	if arma:
		_saida(e.lugar, Forja.gatilho(e.lugar, 1, F.GATILHO_ARMA, 2, 6, 8))
	else:
		_saida(e.lugar, Forja.gatilho(e.lugar, 1, F.GATILHO_OFF))


## A luz: a cor do lugar, mais fraca com a vida (nunca abaixo de 30%); o
## vermelho do golpe; o pulso de quem está por um fio; a 30% derrubado. Só sai
## quando muda.
func _atualizar_luz(e: Dictionary, dt: float) -> void:
	e.luz_pisca = maxf(0.0, float(e.luz_pisca) - dt)
	e.pulso_t = float(e.pulso_t) + dt
	var c: Color = Forja.cor_do_lugar(e.lugar)  # a cor do lugar; a da equipe vai para o mundo
	var estado := 0
	var k := 1.0
	if float(e.fora) > 0.0:
		estado = 10
		k = 0.3
	elif float(e.luz_pisca) > 0.0:
		estado = 11
		c = Color(1, 0, 0)
	elif int(e.vida) <= 1:
		var fase_p := int(float(e.pulso_t) * 4.0) % 2
		estado = 20 + fase_p
		k = 0.6 if fase_p == 1 else 0.35
	else:
		estado = int(e.vida)
		k = 1.0 if int(e.vida) >= 3 else 0.7
	if estado == int(e.luz_estado):
		return
	e.luz_estado = estado
	_saida(e.lugar, Forja.luz(e.lugar, Color(c.r * k, c.g * k, c.b * k)))


static func _base(equipe: int, ordem: int) -> Vector3:
	return Vector3(-(ARENA_X - 1.5) if equipe == 0 else ARENA_X - 1.5, 0.05, -2.2 + 4.4 * (ordem % 2))


func _voltar(e: Dictionary) -> void:
	var ordem := 0
	for o in lut:
		if o != e and o.equipe == e.equipe:
			ordem += 1
	e.pos = _base(int(e.equipe), ordem + int(t_etapa * 3.0) % 2)
	e.vida = VIDA_MAX
	e.fora = 0.0
	e.atordoado = 0.0
	e.mira = 0.0 if e.equipe == 0 else PI
	e.luz_estado = -1
	if e.lugar >= 0:
		e.municao = MUNICAO
		e.recarga = 0.0
		e.arma = false
		if etapa == PARTIDA:
			_armar(e, true)
			_mostrar_municao(e)


# ------------------------------------------------------------------ o jogo --

func iniciar_jogo() -> void:
	for e in lut:
		if e.lugar < 0:
			continue
		var l: int = e.lugar
		fin[l] = {"leds": Cega.nova(), "cor": Cega.nova(), "leds_pedido": -1, "cor_pedida": -1, "resp": -1,
			"t": 0.0, "robo_espera": -1.0}
		Forja.carga_comecar(l)
		_saida(l, Forja.gatilho(l, 0, F.GATILHO_RESISTENCIA, 2, 4))
	etapa = CONTAGEM
	t_etapa = 0.0


func _conectado(l: int) -> bool:
	return Forja.lugar(l).get("conectado", false)


func _comecar_partida() -> void:
	etapa = PARTIDA
	t_etapa = 0.0
	for e in lut:
		_voltar(e)
	Som.tocar("bigorna", null, -2.0)


func _atirar(i: int, ang: float) -> void:
	var e: Dictionary = lut[i]
	var dir := Vector3(cos(ang), 0, sin(ang))
	var pos: Vector3 = e.pos + dir * 0.6 + Vector3(0, 1.0, 0)
	var bala := Kit.esfera(self, 0.13, pos, Kit.material(LUZ_EQUIPE[e.equipe].lightened(0.35), 2.4, 0.8, "forja"))
	tiros.append({"no": bala, "pos": pos, "vel": dir * TIRO_V, "vida": TIRO_VIDA, "dono": i, "equipe": e.equipe})
	Som.tocar("tiro", pos, -14.0 if e.lugar < 0 else -10.0)
	if e.lugar >= 0:
		Som.no_controle(e.lugar, "tiro", 0.4)
		var p: ForjaPlayer = e.no
		p.gesto("holding-right-shoot", 0.22)


func _golpe(alvo: Dictionary, autor: int, vx: float) -> void:
	alvo.vida = int(alvo.vida) - 1
	alvo.dano = 1.0
	Som.tocar("golpe", alvo.pos + Vector3(0, 1.0, 0), -4.0)
	if alvo.lugar >= 0:
		Som.no_controle(alvo.lugar, "golpe", 0.7)  # o golpe se ouve na mão de quem apanhou
	var quem: Dictionary = lut[autor]
	if quem.lugar >= 0:
		quem.acertos = int(quem.acertos) + 1
		quem.especial = minf(1.0, float(quem.especial) + 0.12)
		marcar(quem.lugar, 50)
	if alvo.lugar >= 0:
		# o tiro que anda para a direita veio da esquerda: o motor da esquerda
		var da_esquerda := vx > 0.0
		_saida(alvo.lugar, Forja.sentir(alvo.lugar, "golpe_esq" if da_esquerda else "golpe_dir"))
		alvo.luz_pisca = 0.16
	if int(alvo.vida) <= 0:
		alvo.fora = VOLTA_S
		placar[quem.equipe] += 1
		if quem.lugar >= 0:
			quem.derrubou = int(quem.derrubou) + 1
			marcar(quem.lugar, 150)
		Efeitos.faiscas(self, alvo.pos + Vector3(0, 1.0, 0), LUZ_EQUIPE[alvo.equipe], 30, 1.2)
		Som.tocar("martelo", alvo.pos, -4.0)
		if alvo.lugar >= 0:
			_armar(alvo, false)
			alvo.municao = 0
			_mostrar_municao(alvo)
			var p: ForjaPlayer = alvo.no
			p.gesto("die", VOLTA_S)
	else:
		Efeitos.faiscas(self, alvo.pos + Vector3(0, 1.1, 0), Tema.SECAO[0], 12, 0.7)


func _martelada(i: int) -> void:
	var e: Dictionary = lut[i]
	e.especial = 0.0
	e.avisou = false
	tremor = 0.7
	Efeitos.faiscas(self, e.pos + Vector3(0, 0.4, 0), Tema.TUNGSTENIO, 50, 1.6)
	Efeitos.anel(self, e.pos + Vector3(0, 0.15, 0), Tema.TUNGSTENIO, MARTELADA_RAIO, Vector3.UP, "forja")
	Som.tocar("martelo", e.pos, 2.0)
	_saida(e.lugar, Forja.sentir(e.lugar, "perfeito"))
	for k in lut.size():
		var o: Dictionary = lut[k]
		if o.equipe == e.equipe or float(o.fora) > 0.0:
			continue
		var d := Vector2(o.pos.x - e.pos.x, o.pos.z - e.pos.z)
		if d.length() > MARTELADA_RAIO:
			continue
		o.atordoado = 1.2
		if o.lugar >= 0:
			_saida(o.lugar, Forja.sentir(o.lugar, "explosao"))
		_golpe(o, i, d.x)


func _empurrar(p: Vector3) -> Vector3:
	for c in pilares:
		var d := Vector2(p.x - c.x, p.z - c.z)
		var minimo := RAIO_PILAR + RAIO
		if d.length() < minimo and d.length() > 0.01:
			var n := d.normalized() * minimo
			p.x = c.x + n.x
			p.z = c.z + n.y
	p.x = clampf(p.x, -ARENA_X + RAIO, ARENA_X - RAIO)
	p.z = clampf(p.z, -ARENA_Z + RAIO, ARENA_Z - RAIO)
	return p


func _jogador(i: int, dt: float) -> void:
	var e: Dictionary = lut[i]
	var l: int = e.lugar
	e.corrida = maxf(0.0, float(e.corrida) - dt)
	e.corrida_espera = maxf(0.0, float(e.corrida_espera) - dt)
	var r2 := Forja.eixo(l, F.R2)
	var apertou_r2 := r2 > 0.6 and float(e.r2_ant) <= 0.6
	e.r2_ant = r2
	e.andando = 0.0
	if float(e.fora) > 0.0 or float(e.atordoado) > 0.0:
		return
	# andar: o analógico esquerdo; L2 afina (e anda devagar); ✕ corre
	var mv := Vector2(Forja.eixo(l, F.LX), Forja.eixo(l, F.LY))
	if mv.length() < 0.15:
		mv = Vector2.ZERO
	var afina := Forja.eixo(l, F.L2) > 0.3
	if Forja.apertou(l, F.CRUZ) and float(e.corrida_espera) <= 0.0:
		e.corrida = 0.18
		e.corrida_espera = 1.2
	var v := VEL * (0.55 if afina else 1.0) * (2.3 if float(e.corrida) > 0.0 else 1.0)
	e.pos = _empurrar(e.pos + Vector3(mv.x, 0, mv.y) * v * dt)
	e.andando = mv.length() * (2.0 if float(e.corrida) > 0.0 else 1.0)
	# mirar: o analógico direito e o giroscópio (a guinada gira a mira)
	var mira := Vector2(Forja.eixo(l, F.RX), Forja.eixo(l, F.RY))
	if mira.length() > 0.35:
		e.mira = atan2(mira.y, mira.x)
	elif mv.length() > 0.0 and not afina:
		e.mira = atan2(mv.y, mv.x)
	if Forja.capacidade(l, "giro"):
		e.mira = float(e.mira) - Forja.giro(l).y * dt * (2.2 if afina else 1.2)
	# atirar e recarregar
	if float(e.recarga) > 0.0:
		e.recarga = float(e.recarga) - dt
		if float(e.recarga) <= 0.0:
			e.municao = MUNICAO
			_mostrar_municao(e)
			_armar(e, true)
	elif Forja.apertou(l, F.QUADRADO) and int(e.municao) < MUNICAO:
		e.recarga = RECARGA_S
	if apertou_r2 and float(e.recarga) <= 0.0:
		if int(e.municao) > 0:
			_atirar(i, float(e.mira))
			e.municao = int(e.municao) - 1
			e.tiros = int(e.tiros) + 1
			_mostrar_municao(e)
			_saida(l, Forja.sentir(l, "toque"))
			if int(e.municao) == 0:
				_armar(e, false)
		else:
			Forja.som_falante(l, "clique", 0.9)  # o clique seco sai da mão
	# a martelada
	if float(e.especial) < 1.0:
		e.especial = minf(1.0, float(e.especial) + dt / ESPECIAL_S)
	if float(e.especial) >= 1.0 and not e.avisou:
		e.avisou = true
		Forja.som_falante(l, "pronto", 0.8)  # o sino só no controle de quem tem
	if float(e.especial) >= 1.0 and Forja.apertou(l, F.TOUCHPAD):
		_martelada(i)
	# o passo no chão, nos atuadores
	if mv.length() > 0.0:
		e.passo_t = float(e.passo_t) - dt * (1.8 if float(e.corrida) > 0.0 else 1.0)
		if float(e.passo_t) <= 0.0:
			e.passo_t = PASSO_S
			e.passo_n = int(e.passo_n) + 1
			var som := "passo:%d:%d" % [chao_em(e.pos), int(e.passo_n) % 3]
			Forja.som_haptica(l, som, som, 0.55)


func _inimigo_mais_perto(i: int) -> int:
	var melhor := -1
	var md := INF
	var e: Dictionary = lut[i]
	for k in lut.size():
		var o: Dictionary = lut[k]
		if o.equipe == e.equipe or float(o.fora) > 0.0:
			continue
		var d := Vector2(o.pos.x - e.pos.x, o.pos.z - e.pos.z).length()
		if d < md:
			md = d
			melhor = k
	return melhor


func _angulo_para(de: Dictionary, para: Dictionary) -> float:
	return atan2(float(para.pos.z) - float(de.pos.z), float(para.pos.x) - float(de.pos.x))


func _boneco(i: int, dt: float) -> void:
	var e: Dictionary = lut[i]
	e.andando = 0.0
	if float(e.fora) > 0.0 or float(e.atordoado) > 0.0:
		return
	e.ia_t = float(e.ia_t) - dt
	if float(e.ia_t) <= 0.0:
		e.ia_t = 1.4 + 1.2 * rng.randf()
		var x0 := -ARENA_X * 0.92 if e.equipe == 0 else ARENA_X * 0.14
		e.ia_alvo = Vector3(x0 + ARENA_X * 0.78 * rng.randf(), 0.05, -ARENA_Z * 0.8 + ARENA_Z * 1.6 * rng.randf())
	var d: Vector3 = e.ia_alvo - e.pos
	d.y = 0.0
	if d.length() > 0.12:
		e.pos = _empurrar(e.pos + d.normalized() * VEL * 0.5 * dt)
		e.andando = 0.5
	var alvo := _inimigo_mais_perto(i)
	if alvo >= 0:
		e.mira = _angulo_para(e, lut[alvo])
		e.tiro_t = float(e.tiro_t) - dt
		if float(e.tiro_t) <= 0.0:
			e.tiro_t = 1.8
			_atirar(i, float(e.mira) + (rng.randf() - 0.5) * 0.5)


func _mover_tiros(dt: float) -> void:
	var ficam: Array = []
	for t in tiros:
		t.pos = t.pos + t.vel * dt
		t.vida = float(t.vida) - dt
		var vivo := float(t.vida) > 0.0 and absf(t.pos.x) < ARENA_X + 0.5 and absf(t.pos.z) < ARENA_Z + 0.5
		if vivo:
			for c in pilares:
				if Vector2(t.pos.x - c.x, t.pos.z - c.z).length() < RAIO_PILAR:
					vivo = false
					Efeitos.faiscas(self, t.pos, Color("#ff9a50"), 6, 0.5)
					break
		if vivo:
			for o in lut:
				if o.equipe == t.equipe or float(o.fora) > 0.0:
					continue
				if Vector2(o.pos.x - t.pos.x, o.pos.z - t.pos.z).length() > RAIO:
					continue
				vivo = false
				_golpe(o, t.dono, t.vel.x)
				break
		if vivo:
			var no: Node3D = t.no
			no.position = t.pos
			ficam.append(t)
		else:
			var no2: Node3D = t.no
			no2.queue_free()
	tiros = ficam


# ------------------------------------------------------------------ a prova final --

func _perguntar_leds() -> void:
	for e in lut:
		var l: int = e.lugar
		if l < 0 or not _conectado(l) or not fin.has(l):
			continue
		var f: Dictionary = fin[l]
		var atual := 0 if float(e.fora) > 0.0 else int(e.municao)
		var k := rng.randi_range(1, 4)
		while k == atual:
			k = rng.randi_range(1, 4)
		f.resp = -1
		f.t = 0.0
		f.robo_espera = -1.0
		f.leds_pedido = k if Forja.leds_jogador(l, _mascara(k)) else -1
		if int(f.leds_pedido) >= 0:
			Forja.evento("jogo", l + 1, {"sala": id, "o": "pergunta", "qual": "leds"})
	etapa = LEDS
	t_etapa = 0.0


func _perguntar_cor() -> void:
	for e in lut:
		var l: int = e.lugar
		if l < 0 or not _conectado(l) or not fin.has(l):
			continue
		var f: Dictionary = fin[l]
		var c := rng.randi_range(0, 3)
		while c == COR_PARECIDA[e.equipe]:
			c = rng.randi_range(0, 3)
		f.resp = -1
		f.t = 0.0
		f.robo_espera = -1.0
		f.cor_pedida = c if Forja.luz(l, CORES[c].cor) else -1
		if int(f.cor_pedida) >= 0:
			Forja.evento("jogo", l + 1, {"sala": id, "o": "pergunta", "qual": "cor"})
	etapa = COR
	t_etapa = 0.0


## Uma rodada da prova final: true quando todos responderam (ou o tempo acabou).
func _rodada_final(leds: bool, dt: float) -> bool:
	var todos := true
	for l in fin:
		var f: Dictionary = fin[l]
		var pedido: int = f.leds_pedido if leds else f.cor_pedida
		if not _conectado(l) or pedido < 0 or int(f.resp) == -2:
			continue
		f.t = float(f.t) + dt
		if int(f.resp) < 0 and float(f.t) >= PERGUNTA_ESPERA:
			for k in 4:
				if Forja.apertou(l, BOTAO[k]):
					f.resp = k
					Som.tocar("tique", null, -8.0)
					break
		if int(f.resp) >= 0 or float(f.t) >= PERGUNTA_ESPERA + PERGUNTA_S:
			var certo := pedido - 1 if leds else pedido
			var c: Dictionary = f.leds if leds else f.cor
			if int(f.resp) == certo:
				Cega.certo(c)
				marcar(l, 100)
			elif int(f.resp) >= 0:
				Cega.errado(c, int(f.resp))
			else:
				Cega.perdido(c)
			f.ultima = int(f.resp)
			f.certa = certo
			f.resp = -2  # fechada
			f.revela = 0.9
		else:
			todos = false
	return todos


func jogar(dt: float) -> void:
	if Forja.robo:
		for i in lut.size():
			var e: Dictionary = lut[i]
			if e.lugar >= 0 and _conectado(e.lugar):
				_robo(i, dt)
	tremor = maxf(0.0, tremor - dt * 1.5)
	t_etapa += dt
	for l in fin:
		var f: Dictionary = fin[l]
		f.revela = maxf(0.0, float(f.get("revela", 0.0)) - dt)
	match etapa:
		CONTAGEM:
			if t_etapa >= CONTAGEM_S:
				_comecar_partida()
		PARTIDA:
			for i in lut.size():
				var e: Dictionary = lut[i]
				e.dano = move_toward(float(e.dano), 0.0, dt * 4.0)
				e.atordoado = maxf(0.0, float(e.atordoado) - dt)
				if float(e.fora) > 0.0:
					e.fora = float(e.fora) - dt
					if float(e.fora) <= 0.0:
						_voltar(e)
				if e.lugar >= 0:
					if _conectado(e.lugar):
						_jogador(i, dt)
						_atualizar_luz(e, dt)
				else:
					_boneco(i, dt)
			_mover_tiros(dt)
			if t_etapa >= PARTIDA_S * ritmo_nivel:
				for t in tiros:
					var no: Node3D = t.no
					no.queue_free()
				tiros.clear()
				for e in lut:
					if e.lugar >= 0:
						_armar(e, false)
						Forja.carga_parar(e.lugar)
				Som.tocar("sucesso", null, -4.0)
				if Forja.bancada:  # a prova final às cegas é do Modo bancada
					_perguntar_leds()
				else:
					_ir_para_o_placar()
		LEDS:
			if _rodada_final(true, dt) and _sem_revelar():
				_perguntar_cor()
		COR:
			if _rodada_final(false, dt) and _sem_revelar():
				_ir_para_o_placar()
		PLACAR:
			if t_etapa >= PLACAR_S:
				etapa = ACABOU
				for p in jogadores:
					acabou[p.lugar] = true


func _ir_para_o_placar() -> void:
	etapa = PLACAR
	t_etapa = 0.0
	for l in fin:
		if _conectado(l):
			Forja.luz_do_lugar(l)


func _sem_revelar() -> bool:
	for l in fin:
		if float(fin[l].get("revela", 0.0)) > 0.0:
			return false
	return true


func dar_vereditos(l: int) -> Array:
	if not lut_do_lugar.has(l) or not fin.has(l):
		return []
	var e: Dictionary = lut[lut_do_lugar[l]]
	var f: Dictionary = fin[l]
	Forja.carga_placar(l, int(e.tiros), int(e.acertos), int(e.derrubou))
	var v := Forja.carga_veredito(l, f.leds, f.cor, int(e.tiros) > 0 or Cega.total(f.leds) > 0)
	return [] if v.is_empty() else [v]


# ------------------------------------------------------------------ o que se vê --

func _process(dt: float) -> void:
	super(dt)
	for e in lut:
		_mostrar(e, dt)


func _mostrar(e: Dictionary, dt: float) -> void:
	var no: Node3D = e.no
	if no == null:
		return
	var fora := float(e.fora) > 0.0 and etapa == PARTIDA
	var pos: Vector3 = e.pos
	no.position = Vector3(pos.x, 0.05, pos.z)
	var mira := float(e.mira)
	no.rotation.y = atan2(cos(mira), sin(mira))
	var disco: MeshInstance3D = e.disco
	disco.position = Vector3(pos.x, 0.06, pos.z)
	var md: StandardMaterial3D = e.mat_disco
	Tema.emissivo(md, (1.0 + 2.5 * float(e.dano)) * 2.4 / 3.5, "forja")
	disco.visible = not fora
	var andando := float(e.andando)
	if e.lugar >= 0:
		var p: ForjaPlayer = no
		if fora:
			return
		if andando > 1.2:
			p.animar("sprint", 1.2)
		elif andando > 0.05:
			p.animar("walk", 0.8 + andando * 0.5)
		elif e.arma and etapa == PARTIDA:
			p.animar("holding-right-shoot" if float(e.r2_ant) > 0.6 else "holding-right", 1.0)
		else:
			p.animar("idle")
	else:
		no.visible = not fora
		var anim: AnimationPlayer = e.anim
		if anim:
			var qual := "walk" if andando > 0.05 else "idle"
			if anim.current_animation != qual and anim.has_animation(qual):
				anim.play(qual, 0.2)


# ------------------------------------------------------------------ a HUD --

func status(lugar: int) -> String:
	if fase != "jogo" or not lut_do_lugar.has(lugar):
		return super(lugar)
	var e: Dictionary = lut[lut_do_lugar[lugar]]
	var equipe: String = NOME_EQUIPE[e.equipe]
	if etapa == PARTIDA:
		if float(e.fora) > 0.0:
			return "%s · derrubado" % equipe
		return "%s · vida %d · %d balas" % [equipe, int(e.vida), int(e.municao)]
	return "%s · %d pontos" % [equipe, pontos[lugar]]


func progresso() -> String:
	if fase != "jogo":
		return ""
	match etapa:
		CONTAGEM:
			return "A partida começa em %d" % ceili(CONTAGEM_S - t_etapa)
		PARTIDA:
			var resta := maxi(0, ceili(PARTIDA_S * ritmo_nivel - t_etapa))
			return "Brasa %d × %d Maré · %d:%02d" % [placar[0], placar[1], resta / 60, resta % 60]
		LEDS, COR:
			return "A prova final, às cegas"
		PLACAR:
			return "Brasa %d × %d Maré" % [placar[0], placar[1]]
	return ""


func dica(lugar: int) -> Dictionary:
	if fase != "jogo" or etapa != PARTIDA or not lut_do_lugar.has(lugar):
		return {}
	var e: Dictionary = lut[lut_do_lugar[lugar]]
	var pos := Vector3(e.pos.x, 0.0, e.pos.z + 1.6)
	if float(e.especial) >= 1.0:
		return {"partes": ["@touchpad", "Martelada!"], "pos": pos}
	if int(e.municao) == 0 and float(e.recarga) <= 0.0:
		return {"partes": ["@square", "Recarregue"], "pos": pos}
	return {}


func pergunta(lugar: int) -> Dictionary:
	if not Forja.bancada:
		return {}  # a pergunta às cegas é do Modo bancada
	if fase != "jogo" or not (etapa == LEDS or etapa == COR) or not fin.has(lugar):
		return {}
	var f: Dictionary = fin[lugar]
	var leds := etapa == LEDS
	var pedido: int = f.leds_pedido if leds else f.cor_pedida
	if pedido < 0:
		return {}
	var opcoes: Array = []
	for k in 4:
		if leds:
			opcoes.append([GLIFO[k], null, "%d luzinha%s" % [k + 1, "" if k == 0 else "s"]])
		else:
			opcoes.append([GLIFO[k], CORES[k].cor, Desenho.maiusc(CORES[k].nome)])
	var escolhida := int(f.resp)
	var certa := -1
	var rodape := ""
	if int(f.resp) == -2:
		escolhida = int(f.get("ultima", -1))
		certa = int(f.get("certa", -1))
		if escolhida < 0:
			rodape = "Sem resposta"
		elif escolhida == certa:
			rodape = "Isso: obedeceu, mesmo com tudo ligado"
		else:
			rodape = "Não — o jogo mandou %s" % (("%d" % pedido) if leds else CORES[pedido].nome)
	elif float(f.t) < PERGUNTA_ESPERA:
		rodape = "Olhe o controle…"
	var col: Dictionary = lut[lut_do_lugar[lugar]]
	return {"titulo": "Quantas luzinhas acesas?" if leds else "Que cor está a sua luz?", "opcoes": opcoes,
		"escolhida": escolhida, "certa": certa, "rodape": rodape, "pos": Vector3(col.pos.x, 0.0, col.pos.z + 1.2)}


# ------------------------------------------------------------------ o robô --
# Joga a partida como um jogador: chega perto do inimigo mais próximo sem
# colar, anda de lado, mira com o analógico direito e atira quando a mira
# está nele; recarrega vazio, solta a martelada de perto. Na prova final, vê
# as luzinhas e a cor do controle simulado dele.

static func _cor_mais_perto(c: Color) -> int:
	var melhor := 0
	var menor := INF
	for k in 4:
		var o: Color = CORES[k].cor
		var d := Vector3(c.r - o.r, c.g - o.g, c.b - o.b).length_squared()
		if d < menor:
			menor = d
			melhor = k
	return melhor


func _robo(i: int, dt: float) -> void:
	var e: Dictionary = lut[i]
	var l: int = e.lugar
	if etapa == LEDS or etapa == COR:
		var f: Dictionary = fin[l]
		var pedido: int = f.leds_pedido if etapa == LEDS else f.cor_pedida
		if pedido < 0 or int(f.resp) != -1:
			return
		if float(f.robo_espera) < 0.0:
			f.robo_espera = PERGUNTA_ESPERA + 0.3 + 0.8 * rng.randf()
		f.robo_espera = float(f.robo_espera) - dt
		if float(f.robo_espera) > 0.0:
			return
		var pc := Forja.percepcao(l)
		var k := 0
		if etapa == LEDS:
			var acesas := 0
			var m := int(pc.get("leds_jogador", 0))
			for b in 5:
				acesas += (m >> b) & 1
			k = clampi(acesas - 1, 0, 3)
		else:
			k = _cor_mais_perto(pc.get("luz", Color.TRANSPARENT))
		Forja.robo_apertar(l, BOTAO[k], 0.08)
		f.robo_espera = 99.0
		return
	if etapa != PARTIDA or float(e.fora) > 0.0:
		return
	var alvo := _inimigo_mais_perto(i)
	if alvo < 0:
		return
	var o: Dictionary = lut[alvo]
	var ang := _angulo_para(e, o)
	var d := Vector2(o.pos.x - e.pos.x, o.pos.z - e.pos.z).length()
	e.robo_lado_t = float(e.robo_lado_t) - dt
	if float(e.robo_lado_t) <= 0.0:
		e.robo_lado_t = 1.5 + rng.randf() * 1.5
		e.robo_lado = -1 if rng.randf() < 0.5 else 1
	var av := 1.0 if d > 6.2 else (-0.8 if d < 4.0 else 0.0)
	if float(e.especial) >= 1.0:
		av = 1.0 if d > 2.0 else 0.0  # o especial cheio: chega perto para a martelada
	var lado := float(e.robo_lado)
	var mv := Vector2(cos(ang) * av - sin(ang) * 0.7 * lado, sin(ang) * av + cos(ang) * 0.7 * lado)
	if mv.length() > 1.0:
		mv = mv.normalized()
	Forja.robo_eixo(l, F.LX, mv.x, 0.1)
	Forja.robo_eixo(l, F.LY, mv.y, 0.1)
	Forja.robo_eixo(l, F.RX, cos(ang), 0.1)
	Forja.robo_eixo(l, F.RY, sin(ang), 0.1)
	var erro := absf(wrapf(ang - float(e.mira), -PI, PI))
	e.robo_tiro = float(e.robo_tiro) - dt
	if int(e.municao) == 0 and float(e.recarga) <= 0.0:
		if not e.robo_recarregou:
			Forja.robo_apertar(l, F.QUADRADO, 0.08)
			e.robo_recarregou = true
	else:
		e.robo_recarregou = false
	if int(e.municao) > 0 and float(e.recarga) <= 0.0 and erro < 0.15 and float(e.robo_tiro) <= 0.0:
		Forja.robo_eixo(l, F.R2, 1.0, 0.08)
		e.robo_tiro = 0.35 + 0.3 * rng.randf()
	if float(e.especial) >= 1.0 and d < MARTELADA_RAIO * 0.8:
		Forja.robo_apertar(l, F.TOUCHPAD, 0.08)
	elif rng.randf() < 0.004:
		Forja.robo_apertar(l, F.CRUZ, 0.08)


func com_poucos() -> String:
	match jogadores.size():
		1: return "Você contra 2 bonecos"
		2: return "1 contra 1"
		3: return "2 contra 1 + boneco"
	return ""
