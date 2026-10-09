class_name SalaCentelha
extends SalaJogo
## A Centelha — runas que acendem ao apertar (o QTE e o jogo de ritmo).
##
## Cada jogador tem a sua bigorna; em cima dela acende uma runa com um símbolo
## e um anel que vai se fechando. Apertar o botão da runa antes do anel fechar
## faz o boneco martelar a bigorna. A fila de cada um passa por todos os botões
## que um jogo usa (✕ ○ □ △, L1, R1, L3, R3, as quatro setas e o Create), por
## dois círculos (cada analógico até a borda, nas oito direções) e pelo fole
## (cada gatilho segurado na faixa dourada e depois apertado até o fundo), numa
## ordem sorteada pela semente. Runa perdida volta para o fim da fila (até três
## vezes).
##
## O Options é a pausa, o PS fica de fora (o sistema toma), o botão do
## microfone é d'A Voz e o clique do touchpad é d'O Molde.

const F := preload("res://scripts/forja.gd")
const BOTOES := [F.CRUZ, F.CIRCULO, F.QUADRADO, F.TRIANGULO, F.L1, F.R1, F.L3, F.R3,
	F.CIMA, F.BAIXO, F.ESQUERDA, F.DIREITA, F.CREATE]
const GLIFO := {
	F.CRUZ: "cross", F.CIRCULO: "circle", F.QUADRADO: "square", F.TRIANGULO: "triangle",
	F.L1: "l1", F.R1: "r1", F.L3: "stick_l", F.R3: "stick_r", F.CIMA: "dpad_up", F.BAIXO: "dpad_down",
	F.ESQUERDA: "dpad_left", F.DIREITA: "dpad_right", F.CREATE: "share",
}
const RAIAS := [-6.0, -2.0, 2.0, 6.0]
const JANELA_INICIAL := 2.8
const JANELA_MINIMA := 1.5
const JANELA_ANALOGICO := 7.0
const JANELA_GATILHO := 8.0
const MAX_TENTATIVAS := 3
const BORDA := 0.85

var j := {}  ## lugar -> o estado do jogador
var runas := {}  ## lugar -> os nós da runa (glifo, anel, marcas, fole)


func _init() -> void:
	id = "centelha"
	nome = "A Centelha"
	acao = "Aperte o botão da runa antes do anel fechar."
	icone = "cross"
	gesto_do_aviso = "attack-melee-right"
	objetivo = "Aperte o botão da runa antes do anel fechar. Na runa do analógico, gire até a borda; no fole, segure o gatilho na faixa e aperte até o fundo."
	features = ["botoes", "analogicos", "gatilhos_analogicos"]
	botoes_pedidos = F.mascara(BOTOES)
	duracao = 100.0
	camera_pos = Vector3(0, 7.2, 12.4)
	camera_olhar = Vector3(0, 1.2, -0.2)


func montar() -> void:
	Kit.arena(self, 5, 3)
	# a forja: brasas subindo, e o neon rosa do Hefesto
	atmosfera(Color("#ff9a52"), Tema.VIOLETA, true, 60)
	luzes([Vector3(-9, 2.5, -4), Vector3(9, 2.5, -4), Vector3(0, 3.0, 4)])
	for p in jogadores:
		var l: int = p.lugar
		# o ferreiro ao lado da bigorna, em três-quartos para a câmera: a
		# martelada aparece
		Kit.bigorna(self, _bigorna(l), 0.62)
		p.position = Vector3(RAIAS[l] - 1.05, 0.05, 1.15)
		p.olhar_para(_bigorna(l))
		martelo_na_mao(p)
		var forja := OmniLight3D.new()
		forja.position = _bigorna(l) + Vector3(0, 1.4, 0.8)
		forja.light_color = Forja.cor_do_lugar(l).lerp(Tema.TUNGSTENIO, 0.5)
		forja.light_energy = 0.9
		forja.omni_range = 4.0
		add_child(forja)
		runas[l] = _montar_runa(l)
		j[l] = _novo_jogador()
		Forja.gatilhos_off(l)


## A bigorna de cada um, à frente e à direita do ferreiro; a runa acende em
## cima dela.
static func _bigorna(l: int) -> Vector3:
	return Vector3(RAIAS[l] + 0.45, 0.0, 0.3)


func _novo_jogador() -> Dictionary:
	var ordem := BOTOES.duplicate()
	# embaralha pela semente da sala
	for i in range(ordem.size() - 1, 0, -1):
		var k := rng.randi_range(0, i)
		var tmp = ordem[i]
		ordem[i] = ordem[k]
		ordem[k] = tmp
	var extras := [
		{"tipo": "analogico", "alvo": 0}, {"tipo": "gatilho", "alvo": 0},
		{"tipo": "analogico", "alvo": 1}, {"tipo": "gatilho", "alvo": 1},
	]
	if rng.randi_range(0, 1) == 1:
		extras[0].alvo = 1
		extras[2].alvo = 0
	var fila: Array = []
	var posicoes := [3, 6, 9, 12]
	var e := 0
	for b in ordem:
		while e < 4 and posicoes[e] == fila.size():
			fila.append(extras[e].duplicate())
			e += 1
		fila.append({"tipo": "botao", "alvo": b})
	while e < 4:
		fila.append(extras[e].duplicate())
		e += 1
	for r in fila:
		r["tentativas"] = 0
	return {"fila": fila, "atual": 0, "t": 0.0, "janela": JANELA_INICIAL * ritmo_nivel, "setores": 0, "estagio": 0,
		"segurou": 0.0, "combo": 0, "tremor": 0.0, "pop": 0.0,
		"robo_reacao": -1.0, "robo_passo": 0, "robo_ang": 0.0, "robo_gatilho": 0.0}


# ------------------------------------------------------------------ a runa --

func _montar_runa(l: int) -> Dictionary:
	var raiz := Node3D.new()
	raiz.position = _bigorna(l) + Vector3(0, 2.55, 0)
	raiz.visible = false  # acende quando o jogo começa
	add_child(raiz)
	var glifo := Sprite3D.new()
	glifo.pixel_size = 0.0062
	glifo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glifo.shaded = false
	glifo.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	raiz.add_child(glifo)
	var anel := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.66
	t.outer_radius = 0.74
	t.rings = 48
	anel.mesh = t
	anel.rotation.x = PI * 0.5
	var cor: Color = Forja.cor_do_lugar(l)
	anel.material_override = Kit.material(cor, 2.2, 0.8, l)
	raiz.add_child(anel)
	var marcas: Array = []
	for s in 8:
		var m := MeshInstance3D.new()
		var esf := SphereMesh.new()
		esf.radius = 0.07
		esf.height = 0.14
		m.mesh = esf
		var ang := s * PI / 4.0
		# setor 0 = direita, sentido horário na tela (y do analógico para baixo)
		m.position = Vector3(cos(ang) * 0.95, -sin(ang) * 0.95, 0)
		m.material_override = Kit.material(Tema.GRAFITE, 0.0)
		raiz.add_child(m)
		marcas.append(m)
	# o fole: o trilho, a faixa dourada (35–62%), o topo (92%) e o nível
	var fole := Node3D.new()
	fole.position = Vector3(1.05, -0.7, 0)
	raiz.add_child(fole)
	var trilho := MeshInstance3D.new()
	var bt := BoxMesh.new()
	bt.size = Vector3(0.16, 1.4, 0.04)
	trilho.mesh = bt
	trilho.position.y = 0.7
	trilho.material_override = Kit.material(Tema.GRAFITE)
	fole.add_child(trilho)
	var faixa := MeshInstance3D.new()
	var bf := BoxMesh.new()
	bf.size = Vector3(0.22, 1.4 * 0.27, 0.05)
	faixa.mesh = bf
	faixa.position.y = 1.4 * (0.35 + 0.62) * 0.5
	faixa.material_override = Kit.material(Tema.TUNGSTENIO, 0.9, 0.8, "forja")
	fole.add_child(faixa)
	var topo := MeshInstance3D.new()
	var btp := BoxMesh.new()
	btp.size = Vector3(0.22, 1.4 * 0.08, 0.05)
	topo.mesh = btp
	topo.position.y = 1.4 * 0.96
	topo.material_override = Kit.material(Tema.TUNGSTENIO, 0.9, 0.8, "forja")
	fole.add_child(topo)
	var nivel := MeshInstance3D.new()
	var bn := BoxMesh.new()
	bn.size = Vector3(0.1, 1.0, 0.07)
	nivel.mesh = bn
	nivel.material_override = Kit.material(Tema.VIOLETA, 1.0)
	fole.add_child(nivel)
	return {"raiz": raiz, "glifo": glifo, "anel": anel, "marcas": marcas, "fole": fole, "nivel": nivel,
		"faixa": faixa, "topo": topo}


func _runa_atual(l: int) -> Variant:
	var e: Dictionary = j[l]
	return e.fila[e.atual] if e.atual < e.fila.size() else null


func _mostrar_runa(l: int) -> void:
	var n: Dictionary = runas[l]
	var e: Dictionary = j[l]
	var r = _runa_atual(l)
	n.raiz.visible = r != null and fase == "jogo"
	if r == null:
		return
	var glifo: Sprite3D = n.glifo
	var nome_glifo := ""
	match str(r.tipo):
		"botao":
			nome_glifo = GLIFO.get(r.alvo, "cross")
		"analogico":
			nome_glifo = "stick_r" if r.alvo == 1 else "stick_l"
		"gatilho":
			nome_glifo = "r2" if r.alvo == 1 else "l2"
	glifo.texture = Desenho.glifo(nome_glifo)
	var brilho: float = 1.0 + 0.6 * float(e.pop)
	glifo.modulate = Tema.ETIQUETA.lerp(Tema.ETIQUETA, e.pop)
	glifo.scale = Vector3.ONE * brilho
	glifo.position.x = sin(t * 60.0) * 0.08 * e.tremor
	# o anel fecha com o tempo da runa de botão; nas outras, com a janela maior
	var janela: float = e.janela if r.tipo == "botao" else (JANELA_ANALOGICO if r.tipo == "analogico" else JANELA_GATILHO)
	var resto := clampf(1.0 - e.t / janela, 0.0, 1.0)
	var anel: MeshInstance3D = n.anel
	anel.scale = Vector3.ONE * lerpf(0.35, 1.0, resto)
	anel.visible = true
	for s in 8:
		var m: MeshInstance3D = n.marcas[s]
		m.visible = r.tipo == "analogico"
		var aceso := (int(e.setores) >> s) & 1
		m.material_override = Kit.material(Tema.TUNGSTENIO if aceso else Tema.GRAFITE, 2.0 if aceso else 0.0, 0.8, "forja")
	var fole: Node3D = n.fole
	fole.visible = r.tipo == "gatilho"
	if r.tipo == "gatilho":
		var v := Forja.eixo(_lugar_da(l), Forja.R2 if r.alvo == 1 else Forja.L2)
		var nivel: MeshInstance3D = n.nivel
		nivel.scale = Vector3(1, maxf(0.02, v * 1.4), 1)
		nivel.position.y = v * 1.4 * 0.5
		n.faixa.visible = e.estagio == 0
		n.topo.visible = e.estagio == 1


func _lugar_da(l: int) -> int:
	return l


# ------------------------------------------------------------------ o jogo --

func jogar(dt: float) -> void:
	for p in jogadores:
		var l: int = p.lugar
		var e: Dictionary = j[l]
		e.pop = move_toward(e.pop, 0.0, dt * 5.0)
		e.tremor = move_toward(e.tremor, 0.0, dt * 4.0)
		if not acabou[l]:
			if Forja.robo:
				_robo(l, dt)
			_jogar(l, p, dt)
		_mostrar_runa(l)


func _jogar(l: int, p: ForjaPlayer, dt: float) -> void:
	var e: Dictionary = j[l]
	var r = _runa_atual(l)
	var pedido: int = r.alvo if r != null and r.tipo == "botao" else -1
	Forja.med_pedido(l, pedido)
	if r != null and r.tipo == "analogico":
		Forja.med_pedir(l, "analogico_r" if r.alvo == 1 else "analogico_l")
	elif r != null and r.tipo == "gatilho":
		Forja.med_pedir(l, "gatilho_r2" if r.alvo == 1 else "gatilho_l2")
	for b in BOTOES:
		if not Forja.apertou(l, b):
			continue
		if pedido >= 0 and b == pedido:
			_acertou(l, p, 100)
			return
		if pedido >= 0:
			e.combo = 0
			e.tremor = 0.6
			Som.tocar("falha", p.global_position + Vector3(0, 1.5, -2), -10.0)
	if r == null:
		return
	e.t += dt
	match str(r.tipo):
		"botao":
			if e.t > e.janela:
				_perdeu(l, p)
		"analogico":
			var x := Forja.eixo(l, Forja.RX if r.alvo == 1 else Forja.LX)
			var y := Forja.eixo(l, Forja.RY if r.alvo == 1 else Forja.LY)
			if Vector2(x, y).length() >= BORDA:
				var antes: int = e.setores
				e.setores = int(e.setores) | (1 << _setor(x, y))
				if e.setores != antes:
					Som.tocar("tique", runas[l].raiz.global_position, -6.0, 1.0 + 0.06 * _contar(e.setores))
			if e.setores == 0xFF:
				Forja.evento("entrada", l + 1, {"o": "analogico", "detalhe": ("direito" if r.alvo == 1 else "esquerdo") + ": as oito direções"})
				_acertou(l, p, 250)
			elif e.t > JANELA_ANALOGICO:
				_perdeu(l, p)
		"gatilho":
			var v := Forja.eixo(l, Forja.R2 if r.alvo == 1 else Forja.L2)
			var na_faixa := (v >= 0.35 and v <= 0.62) if e.estagio == 0 else v >= 0.92
			e.segurou = e.segurou + dt if na_faixa else maxf(0.0, e.segurou - dt * 2.0)
			var precisa := 0.6 if e.estagio == 0 else 0.35
			if e.segurou >= precisa:
				if e.estagio == 0:
					e.estagio = 1
					e.segurou = 0.0
					Forja.med_faixa(l, r.alvo)
					Som.tocar("sopro", runas[l].raiz.global_position)
				else:
					Forja.evento("entrada", l + 1, {"o": "gatilho", "detalhe": ("R2" if r.alvo == 1 else "L2") + ": meio e fundo"})
					_acertou(l, p, 250)
			elif e.t > JANELA_GATILHO:
				_perdeu(l, p)


## O setor do analógico (0 = direita, sentido horário na tela), como o núcleo.
static func _setor(x: float, y: float) -> int:
	var a := atan2(y, x)
	if a < 0.0:
		a += TAU
	return int(round(a / (PI / 4.0))) % 8


static func _contar(m: int) -> int:
	var n := 0
	while m:
		n += m & 1
		m >>= 1
	return n


func _acertou(l: int, p: ForjaPlayer, base: int) -> void:
	var e: Dictionary = j[l]
	var r = _runa_atual(l)
	var rapidez := clampf(1.0 - e.t / e.janela, 0.0, 1.0) if r != null and r.tipo == "botao" else 0.5
	e.combo += 1
	marcar(l, base + int(100.0 * rapidez) + 10 * (int(e.combo) - 1))
	e.pop = 1.0
	var bigorna_topo := _bigorna(l) + Vector3(0, 0.8, 0)
	Efeitos.faiscas(self, bigorna_topo, Tema.TUNGSTENIO, 26, 1.0)
	Efeitos.anel(self, runas[l].raiz.global_position, Forja.cor_do_lugar(l), 0.7, Vector3.BACK, l)
	Som.tocar("bigorna_aguda" if r != null and r.tipo == "botao" else "bigorna", bigorna_topo, -2.0)
	Som.tocar("martelo", bigorna_topo, -6.0)
	Som.no_controle(l, "martelo", 0.55)  # o martelo soa na mão de quem martelou
	p.gesto("attack-melee-right", 0.45)
	Forja.sentir(l, "acerto")
	if r != null and r.tipo == "botao" and e.janela > JANELA_MINIMA * ritmo_nivel:
		e.janela -= 0.08
	_proxima(l)
	if e.atual >= e.fila.size():
		acabou[l] = true
		Som.tocar("sucesso", bigorna_topo)
		Efeitos.faiscas(self, bigorna_topo + Vector3(0, 0.4, 0), Tema.VIOLETA, 48, 1.4)
		p.gesto("emote-yes", 1.5)


func _perdeu(l: int, p: ForjaPlayer) -> void:
	var e: Dictionary = j[l]
	var r: Dictionary = _runa_atual(l)
	e.combo = 0
	e.tremor = 1.0
	Som.tocar("falha", runas[l].raiz.global_position, -4.0)
	p.gesto("emote-no", 0.6)
	r.tentativas = int(r.tentativas) + 1
	if r.tentativas < MAX_TENTATIVAS:
		e.fila.append(r.duplicate())
	_proxima(l)
	if e.atual >= e.fila.size():
		acabou[l] = true


func _proxima(l: int) -> void:
	var e: Dictionary = j[l]
	e.atual += 1
	e.t = 0.0
	e.setores = 0
	e.estagio = 0
	e.segurou = 0.0
	e.robo_passo = 0
	e.robo_reacao = -1.0
	Forja.med_pedido(l, -1)


func status(lugar: int) -> String:
	if fase == "jogo" and j.has(lugar) and not acabou[lugar]:
		var e: Dictionary = j[lugar]
		return "Runa %d de %d · %d" % [mini(int(e.atual) + 1, e.fila.size()), e.fila.size(), pontos[lugar]]
	return super(lugar)


# ------------------------------------------------------------------ o robô --
# Vê a runa e reage como gente: às vezes o dedo escorrega para o vizinho e
# corrige; gira o analógico em volta; segura o gatilho no meio e aperta.

func _robo(l: int, dt: float) -> void:
	var e: Dictionary = j[l]
	var r = _runa_atual(l)
	if r == null:
		return
	if e.robo_reacao < 0.0:
		e.robo_reacao = 0.35 + 0.55 * rng.randf()
	match str(r.tipo):
		"botao":
			if e.robo_passo == 0 and e.t >= e.robo_reacao:
				if rng.randf() < 0.06:
					var errado: int = BOTOES[(l + int(e.atual) + 1) % BOTOES.size()]
					if errado == r.alvo:
						errado = BOTOES[(l + int(e.atual) + 2) % BOTOES.size()]
					Forja.robo_apertar(l, errado, 0.08)
					e.robo_reacao = e.t + 0.35
					e.robo_passo = 1
				else:
					Forja.robo_apertar(l, r.alvo, 0.09)
					e.robo_passo = 2
			elif e.robo_passo == 1 and e.t >= e.robo_reacao:
				Forja.robo_apertar(l, r.alvo, 0.09)
				e.robo_passo = 2
		"analogico":
			if e.t >= e.robo_reacao:
				e.robo_ang += dt * TAU / 1.4
				Forja.robo_eixo(l, Forja.RX if r.alvo == 1 else Forja.LX, cos(e.robo_ang), 0.06)
				Forja.robo_eixo(l, Forja.RY if r.alvo == 1 else Forja.LY, sin(e.robo_ang), 0.06)
		"gatilho":
			var alvo := 0.0 if e.t < e.robo_reacao else (0.48 if e.estagio == 0 else 1.0)
			var lido := Forja.eixo(l, Forja.R2 if r.alvo == 1 else Forja.L2)
			# o fole não enche (o jogo não vê o meio): aperta mais, como gente
			if e.estagio == 0 and e.t > e.robo_reacao + 1.2 and lido < 0.2 and fmod(e.t, 1.6) < 0.5:
				alvo = 1.0
			e.robo_gatilho = move_toward(e.robo_gatilho, alvo, dt * 4.0)
			Forja.robo_eixo(l, Forja.R2 if r.alvo == 1 else Forja.L2, e.robo_gatilho, 0.06)
