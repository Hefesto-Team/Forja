class_name SalaImpacto
extends SalaJogo
## O Impacto — dano direcional e a vida na luz.
##
## O padrão dos jogos de ação do PS5: o golpe da esquerda treme SÓ o motor da
## esquerda, a barra de luz pisca vermelho no golpe e apaga conforme a vida
## cai. (A barra de luz do DualSense é uma cor só: o lado vem do motor.)
##
## E é uma prova às cegas (cegas.h), porque saída o jogo não mede: no escuro,
## os golpes vêm um de cada vez, para um controle só, e a tela não diz de que
## lado — o aviso "!" não tem lado e o som sai no meio. Quem sente levanta o
## escudo daquele lado (L1 esquerda, R1 direita); só depois da resposta a tela
## mostra a sentinela que atirou e o golpe batendo no escudo ou no boneco. Quem
## levanta o escudo com o golpe indo para OUTRO controle sentiu uma vibração
## que não era dele: é o isolamento. No fim de cada onda, cada controle acende
## uma cor sorteada, e a pessoa diz qual é olhando o plástico.

const F := preload("res://scripts/forja.gd")
const RAIAS := [-6.0, -2.0, 2.0, 6.0]
const Z_JOGADOR := 1.4
const POR_LADO := 5
const ONDAS := 3
const JANELA := 1.3  ## s para levantar o escudo depois do golpe
const MOSTRA := 0.5  ## s do golpe voando, depois da resposta
const GOLPE_MS := 260
const DANO := 0.14
const VIDA_MIN := 0.12
const PERGUNTA_MAX := 9.0
const MAX_PERGUNTAS := 5
## longe das cores dos lugares (azul, vermelho, verde, rosa), para não confundir
const CORES := [
	{"nome": "âmbar", "cor": Color(1.0, 0.59, 0.0)},
	{"nome": "ciano", "cor": Color(0.0, 0.82, 1.0)},
	{"nome": "violeta", "cor": Color(0.67, 0.27, 1.0)},
	{"nome": "branco", "cor": Color(1.0, 1.0, 1.0)},
]
const BOTAO_COR := [F.CRUZ, F.CIRCULO, F.QUADRADO, F.TRIANGULO]
const GLIFO_COR := ["cross", "circle", "square", "triangle"]
const NEUTRO := Color(0.55, 0.55, 0.6)

enum { PAUSA, GOLPE, VOANDO, PERGUNTA, RESPOSTA, ACABOU }

var estado := PAUSA
var t_estado := 0.0
var espera := 1.2
var plano: Array = []  ## Vector2i(lugar, lado); lado 0 = esquerda (o motor forte)
var i_plano := 0
var fim_onda := [0, 0, 0]
var onda := 0
var atual := Vector2i(-1, 0)
var resposta := -1
var respondido := false
var j := {}  ## lugar -> o estado do jogador
var n := {}  ## lugar -> os nós da raia


func _init() -> void:
	id = "impacto"
	nome = "O Impacto"
	acao = "Sinta o golpe e levante o escudo do lado."
	gesto_do_aviso = "lados"
	objetivo = "No escuro, os golpes vêm um de cada vez, para um controle só, e a tela não diz o lado: sinta no controle e levante o escudo — L1 esquerda, R1 direita. Só no seu golpe! A luz do controle pisca vermelho no golpe e apaga com a vida; no fim de cada onda, diga a cor dela."
	features = ["vibracao_forte", "vibracao_fraca", "vibracao_isolamento", "lightbar"]
	cega = true
	botoes_pedidos = F.mascara([F.L1, F.R1, F.CRUZ, F.CIRCULO, F.QUADRADO, F.TRIANGULO])
	duracao = 0.0
	camera_pos = Vector3(0, 6.4, 10.8)
	camera_olhar = Vector3(0, 1.0, -0.4)


func montar() -> void:
	Kit.arena(self, 5, 3)
	# no escuro: um enchimento frio e fraco; a luz de cada raia é a lanterna dele
	var frio := OmniLight3D.new()
	frio.position = Vector3(0, 8.0, 3.0)
	frio.light_color = Color("#6b6fb0")
	frio.light_energy = 0.45
	frio.omni_range = 26.0
	add_child(frio)
	for x in [-10.0, 10.0]:
		var tocha := OmniLight3D.new()
		tocha.position = Vector3(x, 2.4, -5.0)
		tocha.light_color = Color("#ff9a50")
		tocha.light_energy = 0.8
		tocha.omni_range = 7.0
		add_child(tocha)
	for p in jogadores:
		var l: int = p.lugar
		j[l] = _novo_jogador()
		n[l] = _montar_raia(l, p)
		Forja.gatilhos_off(l)


func _novo_jogador() -> Dictionary:
	return {"vida": 1.0, "pisca": 0.0, "vermelho": false, "esq": Cega.nova(), "dir": Cega.nova(),
		"fantasmas": 0, "chances": 0, "reagiu": false, "rumble_ok": false, "luz_ok": false,
		"cor": Cega.nova(), "perguntas": 0, "cor_pedida": -1, "cor_resposta": -1, "cor_antes": -1,
		"escudo": 0.0, "escudo_lado": 0, "interroga": 0.0, "dano": 0.0, "bloqueios": 0, "combo": 0,
		"robo_forte": 0.0, "robo_fraco": 0.0, "robo_reage": -1.0, "robo_lado": 0, "robo_cor": 0.0}


static func _sentinela_pos(l: int, lado: int) -> Vector3:
	return Vector3(RAIAS[l] + (-1.35 if lado == 0 else 1.35), 0.0, Z_JOGADOR - 1.45)


func _montar_raia(l: int, p: ForjaPlayer) -> Dictionary:
	var x: float = RAIAS[l]
	var alvo := Vector3(x, 0, Z_JOGADOR)
	# o chão da raia: um círculo de pedra escura com a borda que pulsa no golpe
	Kit.cilindro(self, 1.55, 0.04, Vector3(x, 0.02, Z_JOGADOR - 0.3), Kit.material(Color("#231c30"), 0.0, 0.95))
	var borda := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 1.5
	tor.outer_radius = 1.62
	tor.rings = 48
	borda.mesh = tor
	borda.position = Vector3(x, 0.05, Z_JOGADOR - 0.3)
	borda.scale = Vector3(1, 0.4, 1)
	var mat_borda := Kit.material(Color("#3a3150"), 0.0, 0.8)
	borda.material_override = mat_borda
	add_child(borda)
	# as sentinelas de pedra, à frente e dos dois lados, com o olho que acende
	var sentinelas: Array = []
	var olhos: Array = []
	for lado in [0, 1]:
		var pos := _sentinela_pos(l, lado)
		var s := Kit.peca(self, "column", pos, 0.0, 1.35)
		var d := alvo - pos
		s.rotation.y = atan2(d.x, d.z)
		var olho := Kit.esfera(self, 0.09, pos + Vector3(0, 1.28, 0) + d.normalized() * 0.3, Kit.material(Color("#ff4a2a"), 1.2))
		sentinelas.append(s)
		olhos.append(olho)
	# os dois escudos, um de cada lado do boneco (aparecem quando levantados)
	var escudos: Array = []
	for lado in [0, 1]:
		var e := Kit.peca(self, "shield-round", Vector3(x + (-0.62 if lado == 0 else 0.62), 0.95, Z_JOGADOR - 0.2), 0.0, 2.4)
		e.rotation.y = -2.36 if lado == 0 else 2.36
		e.scale = Vector3.ONE * 0.001
		escudos.append(e)
	# o aviso sem lado e a dúvida do escudo à toa
	var aviso := Label3D.new()
	aviso.text = "!"
	aviso.font = Tema.fonte(700)
	aviso.font_size = 160
	aviso.pixel_size = 0.005
	aviso.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	aviso.no_depth_test = true
	aviso.modulate = Tema.LARANJA
	aviso.outline_size = 18
	aviso.outline_modulate = Color(Tema.CASA, 0.9)
	aviso.position = Vector3(x, 2.55, Z_JOGADOR)
	aviso.visible = false
	add_child(aviso)
	var duvida := aviso.duplicate() as Label3D
	duvida.text = "?"
	duvida.font_size = 110
	duvida.modulate = Tema.AMARELO
	duvida.position = Vector3(x + 0.55, 2.3, Z_JOGADOR)
	add_child(duvida)
	# a lanterna da raia: a luz do controle, apagando com a vida (neutra na pergunta)
	var poste := Vector3(x + 1.25, 0, Z_JOGADOR + 0.45)
	Kit.cilindro(self, 0.04, 1.3, poste + Vector3(0, 0.65, 0), Kit.material(Color("#4a4e5e"), 0.0, 0.5))
	var chama := Kit.esfera(self, 0.13, poste + Vector3(0, 1.42, 0), Kit.material(Forja.cor_do_lugar(l), 2.5))
	var luz := OmniLight3D.new()
	luz.position = poste + Vector3(0, 1.45, 0)
	luz.light_energy = 1.4
	luz.omni_range = 3.2
	add_child(luz)
	p.position = Vector3(x, 0.05, Z_JOGADOR)
	p.rotation.y = PI
	maos_livres(p)
	return {"borda": borda, "mat_borda": mat_borda, "sentinelas": sentinelas, "olhos": olhos, "escudos": escudos,
		"aviso": aviso, "duvida": duvida, "chama": chama, "luz": luz}


# ------------------------------------------------------------------ as saídas --

func _cor_da_vida(l: int) -> Color:
	var k := 0.12 + 0.88 * clampf(float(j[l].vida), 0.0, 1.0)
	return Forja.cor_do_lugar(l) * k


func _luz(l: int, cor: Color) -> void:
	if Forja.luz(l, cor):
		j[l].luz_ok = true


func _luz_da_vida(l: int) -> void:
	_luz(l, _cor_da_vida(l))


# ------------------------------------------------------------------ o jogo --

func iniciar_jogo() -> void:
	var lugares: Array = []
	for p in jogadores:
		if jogando[p.lugar]:
			lugares.append(p.lugar)
	plano = Forja.cega_plano_tiros(lugares, POR_LADO, rng.randi())
	for k in ONDAS:
		fim_onda[k] = plano.size() * (k + 1) / ONDAS
	for l in lugares:
		_luz_da_vida(l)
	estado = PAUSA
	t_estado = 0.0
	espera = 1.2


func _conectado(l: int) -> bool:
	return Forja.lugar(l).get("conectado", false)


func _iniciar_golpe() -> void:
	# o próximo alvo com controle; quem caiu da mesa perde o golpe (não conta)
	while i_plano < plano.size() and not _conectado(plano[i_plano].x):
		i_plano += 1
	if i_plano >= plano.size():
		return
	atual = plano[i_plano]
	i_plano += 1
	respondido = false
	resposta = -1
	estado = GOLPE
	t_estado = 0.0
	var l := atual.x
	if Forja.vibrar(l, 1.0 if atual.y == 0 else 0.0, 1.0 if atual.y == 1 else 0.0, GOLPE_MS):
		j[l].rumble_ok = true
	for p in jogadores:
		if jogando[p.lugar] and p.lugar != l and _conectado(p.lugar):
			j[p.lugar].chances += 1
	Forja.evento("jogo", l + 1, {"sala": id, "o": "golpe", "lado": "esquerda" if atual.y == 0 else "direita"})
	# no meio: o som não entrega o lado
	Som.tocar("sopro", null, -6.0)


func _resolver(r: int) -> void:
	var l := atual.x
	var e: Dictionary = j[l]
	respondido = true
	resposta = r
	var cega: Dictionary = e.esq if atual.y == 0 else e.dir
	var res := ""
	if r == atual.y:
		Cega.certo(cega)
		e.bloqueios += 1
		e.combo += 1
		marcar(l, 100 + (50 if t_estado < 0.6 else 0) + 10 * (int(e.combo) - 1))
		res = "certo"
	else:
		if r < 0:
			Cega.perdido(cega)
			res = "perdido"
		else:
			Cega.errado(cega, r)
			res = "errado"
		e.combo = 0
		e.vida = maxf(VIDA_MIN, float(e.vida) - DANO)
		e.dano = 1.0
		e.pisca = 0.34
		e.vermelho = false
	Forja.evento("jogo", l + 1, {"sala": id, "o": "bloqueio", "resultado": res})
	_mostrar_golpe(l, atual.y, r == atual.y)
	estado = VOANDO
	t_estado = 0.0


## Depois da resposta, a tela conta: a sentinela do lado acende e atira, e o
## golpe bate no escudo (faíscas douradas) ou no boneco (vermelho).
func _mostrar_golpe(l: int, lado: int, bloqueou: bool) -> void:
	var nos: Dictionary = n[l]
	var p := jogador(l)
	var de: Vector3 = nos.olhos[lado].global_position
	var ate := Vector3(RAIAS[l] + (-0.62 if lado == 0 else 0.62), 0.95, Z_JOGADOR - 0.2) if bloqueou else Vector3(RAIAS[l], 1.0, Z_JOGADOR)
	var bola := Kit.esfera(self, 0.12, de, Kit.material(Color("#ff7a2a"), 3.0))
	var olho: MeshInstance3D = nos.olhos[lado]
	var mo: StandardMaterial3D = olho.material_override
	mo.emission_energy_multiplier = 4.0
	var tw := bola.create_tween()
	tw.tween_property(bola, "global_position", ate, MOSTRA * 0.6)
	var bateu := func() -> void:
		Efeitos.faiscas(self, ate, Tema.AMARELO if bloqueou else Tema.VERMELHO, 28, 1.0)
		if bloqueou:
			Som.tocar("bigorna", ate, -4.0)
		else:
			Som.tocar("falha", ate, -4.0)
			if p:
				p.gesto("emote-no", 0.5)
		mo.emission_energy_multiplier = 1.2
	tw.tween_callback(bateu)
	tw.tween_callback(bola.queue_free)
	if bloqueou and p:
		p.gesto("interact-left" if lado == 0 else "interact-right", 0.4)


func _iniciar_pergunta() -> void:
	estado = PERGUNTA
	t_estado = 0.0
	for p in jogadores:
		var l: int = p.lugar
		var e: Dictionary = j[l]
		e.cor_pedida = -1
		e.cor_resposta = -1
		if not jogando[l] or not _conectado(l) or Forja.cega_decidida("cor", e.cor) or e.perguntas >= MAX_PERGUNTAS:
			continue
		var c := rng.randi_range(0, 3)
		while c == e.cor_antes:
			c = rng.randi_range(0, 3)
		e.cor_pedida = c
		e.cor_antes = c
		e.perguntas += 1
		e.pisca = 0.0
		_luz(l, CORES[c].cor)
		Forja.evento("jogo", l + 1, {"sala": id, "o": "pergunta_cor", "cor": CORES[c].nome})
	Som.tocar("confirma", null, -6.0)


func _alguem_pergunta() -> bool:
	for l in j:
		if j[l].cor_pedida >= 0:
			return true
	return false


func _fechar_pergunta() -> void:
	for l in j:
		var e: Dictionary = j[l]
		if e.cor_pedida < 0:
			continue
		var res := ""
		if e.cor_resposta < 0:
			Cega.perdido(e.cor)
			res = "perdido"
		elif e.cor_resposta == e.cor_pedida:
			Cega.certo(e.cor)
			marcar(l, 150)
			res = "certo"
		else:
			Cega.errado(e.cor, e.cor_resposta)
			res = "errado"
		Forja.evento("jogo", l + 1, {"sala": id, "o": "resposta_cor", "resultado": res})
	estado = RESPOSTA
	t_estado = 0.0


func _precisa_mais_cor() -> bool:
	for p in jogadores:
		var l: int = p.lugar
		if jogando[l] and _conectado(l) and not Forja.cega_decidida("cor", j[l].cor) and j[l].perguntas < MAX_PERGUNTAS:
			return true
	return false


func _acabar() -> void:
	estado = ACABOU
	for p in jogadores:
		acabou[p.lugar] = true


func jogar(dt: float) -> void:
	# o pisca vermelho: vermelho, escuro, vermelho, e volta à cor da vida
	for l in j:
		var e: Dictionary = j[l]
		if e.pisca <= 0.0 or estado == PERGUNTA or estado == RESPOSTA:
			continue
		e.pisca = float(e.pisca) - dt
		var vermelho: bool = e.pisca > 0.22 or (e.pisca > 0.0 and e.pisca < 0.12)
		if e.pisca <= 0.0:
			_luz_da_vida(l)
		elif vermelho != e.vermelho:
			_luz(l, Color(1, 0, 0) if vermelho else Color(0.16, 0, 0))
		e.vermelho = vermelho
	if Forja.robo:
		for p in jogadores:
			if _conectado(p.lugar):
				_robo(p.lugar, j[p.lugar], dt)
	t_estado += dt
	match estado:
		PAUSA:
			if t_estado < espera:
				return
			if onda < ONDAS and i_plano >= fim_onda[onda]:
				onda += 1
				_iniciar_pergunta()
				if not _alguem_pergunta():
					estado = PAUSA
			elif i_plano < plano.size():
				_iniciar_golpe()
			elif _precisa_mais_cor():
				_iniciar_pergunta()
			else:
				_acabar()
		GOLPE:
			for p in jogadores:
				var l: int = p.lugar
				if not _conectado(l):
					continue
				var l1 := Forja.apertou(l, F.L1)
				var r1 := Forja.apertou(l, F.R1)
				if not l1 and not r1:
					continue
				var e: Dictionary = j[l]
				e.reagiu = true
				e.escudo = 1.0
				e.escudo_lado = 0 if l1 else 1
				if l == atual.x:
					if not respondido:
						_resolver(0 if l1 else 1)
						break
				else:
					# o escudo à toa: este controle sentiu um golpe que não era dele?
					e.fantasmas += 1
					e.interroga = 1.0
					marcar(l, -20)
					Forja.evento("jogo", l + 1, {"sala": id, "o": "fantasma", "golpe_de": "P%d" % (atual.x + 1)})
			if estado == GOLPE and t_estado >= JANELA * ritmo_nivel:
				_resolver(-1)
		VOANDO:
			if t_estado >= MOSTRA:
				estado = PAUSA
				t_estado = 0.0
				espera = 0.55 + 0.45 * rng.randf()
		PERGUNTA:
			var todos := true
			for p in jogadores:
				var l: int = p.lugar
				var e: Dictionary = j[l]
				if e.cor_pedida < 0:
					continue
				if _conectado(l) and e.cor_resposta < 0 and t_estado > 0.6:
					for c in 4:
						if Forja.apertou(l, BOTAO_COR[c]):
							e.cor_resposta = c
							Som.tocar("tique", p.global_position + Vector3(0, 1, 0), -6.0)
				if e.cor_resposta < 0 and _conectado(l):
					todos = false
			if todos or t_estado >= PERGUNTA_MAX:
				_fechar_pergunta()
		RESPOSTA:
			if t_estado >= 1.6:
				for l in j:
					if j[l].cor_pedida >= 0:
						j[l].cor_pedida = -1
						_luz_da_vida(l)
				estado = PAUSA
				t_estado = 0.0
				espera = 1.0


func dar_vereditos(l: int) -> Array:
	var e: Dictionary = j[l]
	var vizinhos := -1
	for p in jogadores:
		if jogando[p.lugar]:
			vizinhos += 1
	var lista: Array = [
		Forja.cega_veredito(l, "vibracao_forte", {"cega": e.esq, "sdl_aceitou": e.rumble_ok, "reagiu": e.reagiu}),
		Forja.cega_veredito(l, "vibracao_fraca", {"cega": e.dir, "sdl_aceitou": e.rumble_ok, "reagiu": e.reagiu}),
		Forja.cega_veredito(l, "vibracao_isolamento", {"fantasmas": e.fantasmas, "chances": e.chances,
			"vizinhos": vizinhos, "proprios": Cega.somar(e.esq, e.dir)}),
		Forja.cega_veredito(l, "lightbar", {"cega": e.cor, "sdl_aceitou": e.luz_ok}),
	]
	return lista.filter(func(v): return not v.is_empty())


# ------------------------------------------------------------------ o que se vê --

func _process(dt: float) -> void:
	super(dt)
	for p in jogadores:
		_mostrar(p.lugar, dt)


func _mostrar(l: int, dt: float) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = n[l]
	e.escudo = move_toward(float(e.escudo), 0.0, dt * 1.6)
	e.interroga = move_toward(float(e.interroga), 0.0, dt * 1.2)
	e.dano = move_toward(float(e.dano), 0.0, dt * 3.0)
	var alvo: bool = fase == "jogo" and estado == GOLPE and atual.x == l
	var aviso: Label3D = nos.aviso
	aviso.visible = alvo
	aviso.scale = Vector3.ONE * (1.0 + 0.12 * sin(t * 18.0))
	# a borda pulsa sem lado: o aviso é do golpe, não de onde ele vem
	var mb: StandardMaterial3D = nos.mat_borda
	if alvo:
		mb.emission_enabled = true
		mb.emission = Tema.VERMELHO
		mb.emission_energy_multiplier = 1.0 + 1.2 * (0.5 + 0.5 * sin(t * 18.0))
	else:
		mb.emission_enabled = false
	var duvida: Label3D = nos.duvida
	duvida.visible = e.interroga > 0.02
	duvida.modulate.a = float(e.interroga)
	for lado in [0, 1]:
		var esc: Node3D = nos.escudos[lado]
		var k: float = e.escudo if int(e.escudo_lado) == lado else 0.0
		esc.scale = Vector3.ONE * maxf(0.001, 2.4 * minf(1.0, k * 1.6))
	# a lanterna: a luz do controle; na pergunta da cor, neutra (a tela não sopra)
	var perguntando: bool = (estado == PERGUNTA or estado == RESPOSTA) and e.cor_pedida >= 0
	var cor := NEUTRO if perguntando else _cor_da_vida(l)
	if e.pisca > 0.0 and not perguntando:
		cor = Color(1, 0, 0) if e.vermelho else Color(0.3, 0, 0)
	var chama: MeshInstance3D = nos.chama
	var mc: StandardMaterial3D = chama.material_override
	mc.albedo_color = cor
	mc.emission = cor
	var luz: OmniLight3D = nos.luz
	luz.light_color = cor
	luz.light_energy = 0.6 + 1.2 * (1.0 if perguntando else float(e.vida))


# ------------------------------------------------------------------ a HUD --

func status(lugar: int) -> String:
	if fase == "jogo" and j.has(lugar):
		return "vida %d%% · %d ✓" % [int(float(j[lugar].vida) * 100.0), j[lugar].bloqueios]
	return super(lugar)


func progresso() -> String:
	if fase != "jogo" or plano.is_empty():
		return ""
	return "onda %d de %d · golpe %d de %d" % [mini(onda + 1, ONDAS), ONDAS, mini(i_plano, plano.size()), plano.size()]


func dica(lugar: int) -> Dictionary:
	if not j.has(lugar) or estado == ACABOU:
		return {}
	return {"partes": ["@l1", "esquerda", "@r1", "direita"], "pos": Vector3(RAIAS[lugar], 0.0, 4.6)}


func pergunta(lugar: int) -> Dictionary:
	if not j.has(lugar):
		return {}
	var e: Dictionary = j[lugar]
	if not (estado == PERGUNTA or estado == RESPOSTA) or e.cor_pedida < 0:
		return {}
	var opcoes: Array = []
	for c in 4:
		opcoes.append([GLIFO_COR[c], CORES[c].cor, CORES[c].nome])
	var rodape := ""
	var certa := -1
	if estado == RESPOSTA:
		certa = e.cor_pedida
		if e.cor_resposta < 0:
			rodape = "sem resposta — era %s" % CORES[e.cor_pedida].nome
		elif e.cor_resposta == e.cor_pedida:
			rodape = "isso: a luz obedeceu"
		else:
			rodape = "não — o jogo mandou %s" % CORES[e.cor_pedida].nome
	return {"titulo": "Que cor está a sua luz?", "opcoes": opcoes, "escolhida": e.cor_resposta,
		"certa": certa, "rodape": rodape, "pos": Vector3(RAIAS[lugar], 0.0, 3.8)}


# ------------------------------------------------------------------ o robô --
# Sente o motor e vê a própria luz, como quem segura o controle: levanta o
# escudo do lado que tremeu, e diz a cor mais parecida com a que o controle
# simulado acendeu (o defeito de mentira fica no caminho, como no aparelho).

func _robo(l: int, e: Dictionary, dt: float) -> void:
	var pc := Forja.percepcao(l)
	if pc.is_empty():
		return
	var forte := float(pc.get("forte", 0.0))
	var fraco := float(pc.get("fraco", 0.0))
	var subiu_forte: bool = forte > 0.3 and e.robo_forte <= 0.3
	var subiu_fraco: bool = fraco > 0.3 and e.robo_fraco <= 0.3
	e.robo_forte = forte
	e.robo_fraco = fraco
	if (subiu_forte or subiu_fraco) and e.robo_reage < 0.0:
		e.robo_lado = 0 if subiu_forte and not subiu_fraco else 1
		e.robo_reage = 0.22 + 0.3 * rng.randf()
	if e.robo_reage >= 0.0:
		e.robo_reage = float(e.robo_reage) - dt
		if e.robo_reage < 0.0:
			Forja.robo_apertar(l, F.L1 if e.robo_lado == 0 else F.R1, 0.08)
	if estado == PERGUNTA and e.cor_pedida >= 0 and e.cor_resposta < 0:
		if e.robo_cor <= 0.0:
			e.robo_cor = 0.7 + 0.8 * rng.randf()
		e.robo_cor = float(e.robo_cor) - dt
		if e.robo_cor <= 0.001:
			Forja.robo_apertar(l, BOTAO_COR[_cor_mais_perto(pc.get("luz", Color.BLACK))], 0.08)
			e.robo_cor = 10.0
	elif estado != PERGUNTA:
		e.robo_cor = 0.0


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


func com_poucos() -> String:
	match jogadores.size():
		1: return "sozinho: isolamento não medido"
	return ""
