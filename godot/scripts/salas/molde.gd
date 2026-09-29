class_name SalaMolde
extends SalaJogo
## O Molde — desenhar e moldar no touchpad.
##
## Os jogos usam o touchpad do DualSense de três jeitos, e a sala pede os três,
## em sequência, para cada jogador. O molde na bancada é o touchpad dele, na
## mesma proporção (duas vezes mais largo que alto), virado para a câmera: o
## dedo aparece no molde onde o jogo o vê.
##
##   1. traçar: uma letra grega aparece no molde, ponto por ponto; o dedo passa
##      por eles na ordem (o gesto de desenhar um símbolo);
##   2. abrir: dois dedos no touchpad, afastar até o molde abrir e juntar até
##      ele fechar (o gesto de pinça do mapa);
##   3. carimbar: o metal esquenta e esfria; o CLIQUE do touchpad carimba
##      quando ele brilha (o touchpad como botão).
##
## O módulo mede quantos dedos chegaram juntos, que pedaço do touchpad os
## toques cobriram (um recorte ou uma escala errada no caminho aparece aqui),
## a abertura entre os dedos e se o clique chegou. Sem touchpad (um pad Xbox,
## por exemplo), a sala não tem o que pedir: o veredito é NÃO MEDIDO, com o
## porquê.

const F := preload("res://scripts/forja.gd")
const RAIAS := [-6.3, -2.1, 2.1, 6.3]
const RAIO_PONTO := 0.07  ## em larguras do touchpad
const CARIMBOS := 3
const ASPECTO := 2.0  ## o touchpad é cerca de duas vezes mais largo que alto
const LARGURA := 2.4  ## o molde no mundo, em metros (2:1, como o touchpad)
const ALTURA := 1.2
const INCLINACAO := 32.0  ## graus: a borda de longe sobe, para a câmera ver o molde de frente
const N_RASTRO := 14

## As letras: cada uma leva o dedo aos quatro cantos do touchpad.
const LETRAS := [
	{"nome": "zeta", "dica": "trace o zeta, em ordem",
		"x": [0.10, 0.90, 0.10, 0.90], "y": [0.14, 0.14, 0.86, 0.86]},
	{"nome": "lambda", "dica": "trace o lambda, em ordem",
		"x": [0.08, 0.50, 0.92], "y": [0.88, 0.12, 0.88]},
	{"nome": "sigma", "dica": "trace o sigma, em ordem",
		"x": [0.88, 0.12, 0.50, 0.12, 0.88], "y": [0.14, 0.14, 0.50, 0.86, 0.86]},
	{"nome": "eta", "dica": "trace o eta, o H de Hefesto",
		"x": [0.12, 0.12, 0.12, 0.88, 0.88, 0.88], "y": [0.12, 0.88, 0.50, 0.50, 0.12, 0.88]},
	{"nome": "mi", "dica": "trace o mi, em ordem",
		"x": [0.10, 0.10, 0.50, 0.90, 0.90], "y": [0.86, 0.14, 0.62, 0.14, 0.86]},
]

enum { TRACAR, ABRIR, CARIMBAR, PRONTO }

var j := {}  ## lugar -> o estado do jogador
var n := {}  ## lugar -> os nós da bancada


func _init() -> void:
	id = "molde"
	nome = "O Molde"
	acao = "O touchpad é o molde: trace, abra, carimbe."
	gesto_do_aviso = "interact-right"
	objetivo = "O touchpad é o molde. Trace a letra tocando os pontos na ordem; depois, dois dedos: afaste até o molde abrir e junte até fechar; por fim, clique o touchpad quando o metal brilhar — três carimbos."
	features = ["touchpad_dois_dedos", "touchpad_clique"]
	botoes_pedidos = F.mascara([F.TOUCHPAD])
	duracao = 90.0
	camera_pos = Vector3(0, 8.6, 12.7)
	camera_olhar = Vector3(0, 0.8, -0.1)


func montar() -> void:
	Kit.arena(self, 5, 3)
	luzes([Vector3(-9, 2.5, -4), Vector3(9, 2.5, -4), Vector3(0, 3.0, 4)])
	for p in jogadores:
		var l: int = p.lugar
		j[l] = _novo_jogador(l)
		n[l] = _montar_bancada(l, p)
		Forja.gatilhos_off(l)


func _novo_jogador(l: int) -> Dictionary:
	return {"passo": TRACAR, "t": 0.0, "letra": rng.randi_range(0, LETRAS.size() - 1), "ponto": 0,
		"aberto": false, "abertura": 0.0, "carimbos": 0, "fora": 0, "calor_fase": rng.randf() * TAU,
		"pancada": 0.0, "rastro": [], "sem_touchpad": false, "tem_toque": Forja.capacidade(l, "toque"),
		"robo_x": 0.5, "robo_y": 0.5, "robo_s": 0.0, "robo_espera": -1.0, "robo_ponto": 0}


## Um ponto do touchpad (x e y de 0 a 1, y para baixo) no molde, a `altura`
## da face.
static func _no_molde(x: float, y: float, altura := 0.12) -> Vector3:
	return Vector3((x - 0.5) * LARGURA, altura, (y - 0.5) * ALTURA)


## A distância entre dois toques, em larguras do touchpad (como o núcleo mede).
static func _distancia(a: Vector2, b: Vector2) -> float:
	return Vector2((b.x - a.x) * ASPECTO, b.y - a.y).length() / ASPECTO


func _calor(e: Dictionary) -> float:
	return 0.5 + 0.5 * sin(float(e.t) * 2.3 + float(e.calor_fase))


func _no_ponto(e: Dictionary) -> bool:
	return _calor(e) > 0.8


# ------------------------------------------------------------------ a bancada --

func _montar_bancada(l: int, p: ForjaPlayer) -> Dictionary:
	var x: float = RAIAS[l]
	var cx := x + 0.45
	var cor: Color = Forja.cor_do_lugar(l)
	var e: Dictionary = j[l]
	var letra: Dictionary = LETRAS[e.letra]
	Kit.caixa(self, Vector3(2.8, 0.8, 1.7), Vector3(cx, 0.4, 0.3), Kit.material(Color("#4b4558"), 0.0, 0.9))
	Kit.caixa(self, Vector3(2.9, 0.08, 1.8), Vector3(cx, 0.82, 0.3), Kit.material(Color("#6a6180"), 0.0, 0.8))
	var fogo := OmniLight3D.new()
	fogo.position = Vector3(cx, 2.4, 1.2)
	fogo.light_color = cor.lerp(Color("#ffb070"), 0.55)
	fogo.light_energy = 0.8
	fogo.omni_range = 4.5
	add_child(fogo)
	# o ferreiro ao lado da bancada, de perfil para a câmera, com o martelo
	p.position = Vector3(x - 1.45, 0.05, 0.35)
	p.rotation.y = PI * 0.5
	martelo_na_mao(p)
	# o molde: duas metades de pedra com o metal no fundo
	var placa := Node3D.new()
	placa.position = Vector3(cx, 1.12, 0.3)
	placa.rotation.x = deg_to_rad(INCLINACAO)
	add_child(placa)
	var metades: Array = []
	var metal := Kit.material(Color("#3a1a10"), 0.4, 0.55)
	for lado in [-1.0, 1.0]:
		var metade := Node3D.new()
		placa.add_child(metade)
		Kit.caixa(metade, Vector3(LARGURA * 0.5 + 0.12, 0.16, ALTURA + 0.26), Vector3(lado * (LARGURA * 0.25 + 0.06), 0, 0),
			Kit.material(Color("#5d566d"), 0.0, 0.85))
		Kit.caixa(metade, Vector3(LARGURA * 0.5 - 0.02, 0.03, ALTURA), Vector3(lado * LARGURA * 0.25, 0.085, 0), metal)
		metades.append(metade)
	# a letra: o sulco entre os pontos e os pontos numerados
	var sulco := Kit.material(Color("#1c1622"), 0.0, 0.9)
	var sulcos: Array = []
	var n_pts: int = letra.x.size()
	for k in n_pts - 1:
		var a := _no_molde(letra.x[k], letra.y[k], 0.108)
		var b := _no_molde(letra.x[k + 1], letra.y[k + 1], 0.108)
		var s := Kit.caixa(placa, Vector3(0.07, 0.02, a.distance_to(b)), (a + b) * 0.5, sulco)
		s.rotation.y = atan2(b.x - a.x, b.z - a.z)
		sulcos.append(s)
	var pontos: Array = []
	for k in n_pts:
		var c := _no_molde(letra.x[k], letra.y[k], 0.11)
		var disco := Kit.cilindro(placa, 0.07, 0.03, c, Kit.material(Color("#1c1622")))
		var rotulo := Label3D.new()
		rotulo.text = str(k + 1)
		rotulo.font = Tema.fonte(700)
		rotulo.font_size = 56
		rotulo.pixel_size = 0.004
		rotulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		rotulo.outline_size = 12
		rotulo.outline_modulate = Color(Tema.CASA, 0.9)
		rotulo.modulate = Tema.SUAVE
		rotulo.position = c + Vector3(0, 0.2, -0.14)
		placa.add_child(rotulo)
		pontos.append({"disco": disco, "rotulo": rotulo})
	var alvo := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = RAIO_PONTO * LARGURA * 0.84
	tor.outer_radius = RAIO_PONTO * LARGURA
	tor.rings = 40
	alvo.mesh = tor
	alvo.material_override = Kit.chapado(Tema.AMARELO)
	placa.add_child(alvo)
	# os dedos, onde o jogo os vê, e o rastro do que desenha
	var dedos: Array = []
	for d in 2:
		var cd := cor if d == 0 else cor.lerp(Color.WHITE, 0.45)
		var esf := Kit.esfera(placa, 0.07, Vector3.ZERO, Kit.material(cd, 2.2))
		esf.visible = false
		dedos.append(esf)
	var ligacao := Kit.caixa(placa, Vector3(0.025, 0.01, 1.0), Vector3.ZERO, Kit.chapado(Color(Tema.FG, 0.6)))
	ligacao.visible = false
	var rastro: Array = []
	for k in N_RASTRO:
		var r := Kit.esfera(placa, 0.035, Vector3.ZERO, Kit.chapado(Color(Tema.AMARELO, 0.0)))
		r.visible = false
		rastro.append(r)
	# a régua da abertura (fechar abaixo de 15%, abrir além de 45%), na borda de perto
	var regua := Node3D.new()
	regua.position = Vector3(0, 0.1, ALTURA * 0.5 + 0.3)
	placa.add_child(regua)
	Kit.caixa(regua, Vector3(2.2, 0.02, 0.09), Vector3.ZERO, Kit.chapado(Tema.TRILHO))
	var enche := Kit.caixa(regua, Vector3(2.2, 0.025, 0.09), Vector3(0, 0.005, 0), Kit.chapado(Tema.AMARELO))
	for marca in [0.15, 0.45]:
		Kit.caixa(regua, Vector3(0.03, 0.03, 0.2), Vector3(-1.1 + 2.2 * marca / 0.7, 0.01, 0), Kit.chapado(Tema.FG))
	regua.visible = false
	# o termômetro do metal, à direita, com a faixa quente em cima
	var termo := Node3D.new()
	termo.position = Vector3(LARGURA * 0.5 + 0.36, 0.1, 0)
	placa.add_child(termo)
	Kit.caixa(termo, Vector3(0.12, 0.02, ALTURA), Vector3.ZERO, Kit.chapado(Tema.TRILHO))
	Kit.caixa(termo, Vector3(0.16, 0.022, ALTURA * 0.2), Vector3(0, 0.002, -ALTURA * 0.4), Kit.chapado(Color(Tema.AMARELO, 0.35)))
	var nivel := Kit.caixa(termo, Vector3(0.09, 0.03, ALTURA), Vector3(0, 0.006, 0), Kit.chapado(Tema.LARANJA))
	termo.visible = false
	# as três lâmpadas dos carimbos, na borda de longe
	var lampadas: Array = []
	for k in CARIMBOS:
		var lp := Kit.esfera(placa, 0.07, Vector3(-0.3 + k * 0.3, 0.12, -ALTURA * 0.5 - 0.06), Kit.material(Color("#2a2433")))
		lampadas.append(lp)
	var ouro := OmniLight3D.new()
	ouro.position = Vector3(cx, 1.9, 1.0)
	ouro.light_color = Color("#ffd479")
	ouro.light_energy = 0.0
	ouro.omni_range = 3.5
	add_child(ouro)
	return {"placa": placa, "metades": metades, "metal": metal, "sulcos": sulcos, "pontos": pontos,
		"alvo": alvo, "dedos": dedos, "ligacao": ligacao, "rastro": rastro, "regua": regua, "enche": enche,
		"termo": termo, "nivel": nivel, "lampadas": lampadas, "ouro": ouro,
		"placa_y": placa.position.y}


# ------------------------------------------------------------------ o jogo --

func jogar(dt: float) -> void:
	for p in jogadores:
		var l: int = p.lugar
		var e: Dictionary = j[l]
		if acabou[l] or not Forja.lugar(l).get("conectado", false):
			continue
		if not e.tem_toque:
			# sem touchpad não há o que pedir: o veredito diz o porquê
			e.sem_touchpad = true
			acabou[l] = true
			continue
		if Forja.robo:
			_robo(l, e, dt)
		_jogar(l, p, e, dt)


func _jogar(l: int, p: ForjaPlayer, e: Dictionary, dt: float) -> void:
	e.t += dt
	e.pancada = move_toward(e.pancada, 0.0, dt * 5.0)
	var d: Array = [Forja.dedo(l, 0), Forja.dedo(l, 1)]
	var baixo: Array = [d[0].z > 0.5, d[1].z > 0.5]
	# o rastro do dedo que desenha
	var rastro: Array = e.rastro
	var qual := 0 if baixo[0] else (1 if baixo[1] else -1)
	if qual >= 0 and e.passo == TRACAR:
		rastro.push_front(Vector2(d[qual].x, d[qual].y))
		if rastro.size() > N_RASTRO:
			rastro.pop_back()
	elif not rastro.is_empty():
		rastro.pop_back()
	var letra: Dictionary = LETRAS[e.letra]
	match int(e.passo):
		TRACAR:
			var n_pts: int = letra.x.size()
			for k in 2:
				if not baixo[k] or e.ponto >= n_pts:
					continue
				var alvo := Vector2(letra.x[e.ponto], letra.y[e.ponto])
				if _distancia(Vector2(d[k].x, d[k].y), alvo) < RAIO_PONTO:
					var onde: Vector3 = n[l].placa.to_global(_no_molde(alvo.x, alvo.y, 0.14))
					Efeitos.faiscas(self, onde, Tema.AMARELO, 14, 0.6)
					Som.tocar("tique", onde, -4.0, 1.0 + 0.08 * int(e.ponto))
					e.ponto += 1
					p.gesto("interact-right", 0.4)
			if e.ponto >= n_pts:
				Forja.med_tracou(l)
				marcar(l, 300 + int(maxf(0.0, 200.0 - e.t * 12.0)))
				_novo_passo(l, p, e, ABRIR)
		ABRIR:
			e.abertura = _distancia(Vector2(d[0].x, d[0].y), Vector2(d[1].x, d[1].y)) if baixo[0] and baixo[1] else 0.0
			if not e.aberto and e.abertura >= 0.45:
				e.aberto = true
				Som.tocar("sopro", p.global_position + Vector3(1.5, 1.2, 0), -2.0)
				p.gesto("interact-right", 0.4)
			elif e.aberto and baixo[0] and baixo[1] and e.abertura <= 0.15:
				marcar(l, 250)
				_novo_passo(l, p, e, CARIMBAR)
		CARIMBAR:
			if Forja.apertou(l, F.TOUCHPAD):
				e.pancada = 1.0
				p.gesto("attack-melee-right", 0.45)
				var centro: Vector3 = n[l].placa.to_global(_no_molde(0.5, 0.5, 0.16))
				if _no_ponto(e):
					e.carimbos += 1
					marcar(l, 120)
					Efeitos.faiscas(self, centro, Tema.AMARELO, 30, 1.0)
					Efeitos.anel(self, centro, Tema.AMARELO, 0.6)
					Som.tocar("carimbo", centro, 0.0)
					Forja.vibrar(l, 0.5, 0.3, 90)
				else:
					e.fora += 1
					Som.tocar("bigorna", centro, -12.0)
			if e.carimbos >= CARIMBOS:
				_novo_passo(l, p, e, PRONTO)


func _novo_passo(l: int, p: ForjaPlayer, e: Dictionary, passo: int) -> void:
	e.passo = passo
	e.t = 0.0
	var onde := p.global_position + Vector3(1.5, 1.2, 0)
	match passo:
		ABRIR:
			Forja.med_pedir(l, "dois_dedos")
		CARIMBAR:
			Forja.med_pedir(l, "clique")
		PRONTO:
			acabou[l] = true
			Som.tocar("sucesso", onde)
			p.gesto("emote-yes", 1.6)
			var centro: Vector3 = n[l].placa.to_global(_no_molde(0.5, 0.5, 0.2))
			Efeitos.faiscas(self, centro, Tema.AMARELO, 48, 1.3)
			return
	Som.tocar("confirma", onde, -4.0)


# ------------------------------------------------------------------ o que se vê --

func _process(dt: float) -> void:
	super(dt)
	for p in jogadores:
		_mostrar(p.lugar)


func _mostrar(l: int) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = n[l]
	var passo := int(e.passo) if fase != "aviso" else TRACAR
	var letra: Dictionary = LETRAS[e.letra]
	var n_pts: int = letra.x.size()
	var placa: Node3D = nos.placa
	placa.position.y = float(nos.placa_y) - 0.05 * float(e.pancada)
	# as metades afastam quando os dedos abrem
	var meio := minf(float(e.abertura), 0.6) * 0.55 if passo == ABRIR else 0.0
	nos.metades[0].position.x = -meio
	nos.metades[1].position.x = meio
	# o metal: brasa apagada, e no carimbo esquenta e esfria
	var quente := _calor(e) if passo == CARIMBAR else (1.0 if passo == PRONTO else 0.25)
	var metal: StandardMaterial3D = nos.metal
	var cor_metal := Color("#5a1a08").lerp(Color("#ff7a2a"), quente)
	if passo == CARIMBAR and _no_ponto(e):
		cor_metal = Color("#ff9a3a").lerp(Color("#ffd479"), 0.6)
	metal.albedo_color = cor_metal.darkened(0.5)
	metal.emission = cor_metal
	metal.emission_energy_multiplier = 0.3 + 2.2 * quente
	# a letra: o sulco enche de ouro atrás do dedo; pronta, a peça é de ouro
	for k in nos.sulcos.size():
		var s: MeshInstance3D = nos.sulcos[k]
		var cheio: bool = passo == PRONTO or (passo == TRACAR and k + 1 < int(e.ponto)) or passo in [ABRIR, CARIMBAR]
		s.visible = passo != ABRIR or true
		s.material_override = _ouro(passo == PRONTO) if cheio else s.material_override
		s.scale = Vector3(2.2, 1.6, 1.0) if passo == PRONTO else Vector3.ONE
	for k in n_pts:
		var pt: Dictionary = nos.pontos[k]
		var feito := k < int(e.ponto)
		var disco: MeshInstance3D = pt.disco
		disco.visible = passo == TRACAR
		disco.material_override = _ouro(false) if feito else disco.material_override
		var rotulo: Label3D = pt.rotulo
		rotulo.visible = passo == TRACAR
		rotulo.modulate = Tema.AMARELO if feito else Tema.SUAVE
	var alvo: MeshInstance3D = nos.alvo
	alvo.visible = passo == TRACAR and int(e.ponto) < n_pts
	if alvo.visible:
		alvo.position = _no_molde(letra.x[e.ponto], letra.y[e.ponto], 0.13)
		alvo.scale = Vector3.ONE * (0.92 + 0.1 * sin(t * 6.0))
	# os dedos
	var d: Array = [Forja.dedo(l, 0), Forja.dedo(l, 1)]
	for k in 2:
		var esf: MeshInstance3D = nos.dedos[k]
		esf.visible = fase == "jogo" and d[k].z > 0.5
		if esf.visible:
			esf.position = _no_molde(d[k].x, d[k].y, 0.16)
	var ligacao: MeshInstance3D = nos.ligacao
	ligacao.visible = fase == "jogo" and d[0].z > 0.5 and d[1].z > 0.5
	if ligacao.visible:
		var a := _no_molde(d[0].x, d[0].y, 0.15)
		var b := _no_molde(d[1].x, d[1].y, 0.15)
		ligacao.position = (a + b) * 0.5
		ligacao.rotation.y = atan2(b.x - a.x, b.z - a.z)
		ligacao.scale = Vector3(1, 1, maxf(0.01, a.distance_to(b)))
	var rastro: Array = e.rastro
	for k in N_RASTRO:
		var r: MeshInstance3D = nos.rastro[k]
		r.visible = k < rastro.size()
		if r.visible:
			r.position = _no_molde(rastro[k].x, rastro[k].y, 0.13)
			var mr: StandardMaterial3D = r.material_override
			mr.albedo_color = Color(Tema.AMARELO, 1.0 - float(k) / N_RASTRO)
	# a régua da abertura, o termômetro, as lâmpadas
	var regua: Node3D = nos.regua
	regua.visible = passo == ABRIR
	var enche: MeshInstance3D = nos.enche
	var frac := minf(float(e.abertura) / 0.7, 1.0)
	enche.scale.x = maxf(0.001, frac)
	enche.position.x = -1.1 + 1.1 * frac
	var me: StandardMaterial3D = enche.material_override
	me.albedo_color = Tema.LARANJA if e.aberto else Tema.AMARELO
	var termo: Node3D = nos.termo
	termo.visible = passo == CARIMBAR
	var nivel: MeshInstance3D = nos.nivel
	nivel.scale.z = maxf(0.001, quente)
	nivel.position.z = ALTURA * 0.5 * (1.0 - quente)
	var mn: StandardMaterial3D = nivel.material_override
	mn.albedo_color = Tema.AMARELO if _no_ponto(e) else Tema.LARANJA
	for k in CARIMBOS:
		var lp: MeshInstance3D = nos.lampadas[k]
		lp.visible = passo >= CARIMBAR
		if k < int(e.carimbos) and lp.get_meta("aceso", false) == false:
			lp.set_meta("aceso", true)
			lp.material_override = Kit.material(Tema.AMARELO, 2.4)
	var ouro: OmniLight3D = nos.ouro
	ouro.light_energy = 1.6 if passo == PRONTO else 0.0


var _mat_ouro := {}


func _ouro(forte: bool) -> StandardMaterial3D:
	if not _mat_ouro.has(forte):
		var m := Kit.material(Color("#e8b44c"), 2.2 if forte else 1.1, 0.3)
		m.metallic = 0.7
		_mat_ouro[forte] = m
	return _mat_ouro[forte]


# ------------------------------------------------------------------ a HUD --

func status(lugar: int) -> String:
	if fase == "jogo" and j.has(lugar) and not acabou[lugar]:
		var e: Dictionary = j[lugar]
		match int(e.passo):
			TRACAR:
				return "1 · ponto %d de %d" % [mini(int(e.ponto) + 1, LETRAS[e.letra].x.size()), LETRAS[e.letra].x.size()]
			ABRIR:
				return "2 · junte" if e.aberto else "2 · abra"
			CARIMBAR:
				return "3 · carimbo %d de %d" % [e.carimbos, CARIMBOS]
	if j.has(lugar) and j[lugar].sem_touchpad:
		return "sem touchpad"
	return super(lugar)


func dica(lugar: int) -> Dictionary:
	if not j.has(lugar):
		return {}
	var e: Dictionary = j[lugar]
	var partes: Array = []
	if e.sem_touchpad:
		partes = ["este controle não tem touchpad"]
	else:
		match int(e.passo):
			TRACAR:
				partes = ["@touchpad", str(LETRAS[e.letra].dica)]
			ABRIR:
				partes = ["agora junte os dedos"] if e.aberto else ["dois dedos: afaste"]
			CARIMBAR:
				partes = ["@touchpad", "clique quando brilhar"]
			PRONTO:
				partes = ["peça forjada!"]
	return {"partes": partes, "pos": Vector3(RAIAS[lugar] + 0.45, 0.0, 2.3)}


# ------------------------------------------------------------------ o robô --
# Vê a letra, o molde e o calor: vai até o centro de cada ponto como gente que
# traça inteiro, abre e fecha a pinça, e clica quando o metal brilha.

func _robo(l: int, e: Dictionary, dt: float) -> void:
	match int(e.passo):
		TRACAR:
			var letra: Dictionary = LETRAS[e.letra]
			var n_pts: int = letra.x.size()
			if e.robo_ponto < int(e.ponto) - 1:
				e.robo_ponto = int(e.ponto) - 1
			if e.robo_ponto >= n_pts:
				return
			var tx: float = letra.x[e.robo_ponto]
			var ty: float = letra.y[e.robo_ponto]
			var dx: float = tx - e.robo_x
			var dy: float = ty - e.robo_y
			var dist := sqrt(dx * dx + dy * dy)
			var passo := dt * (0.9 + 0.3 * rng.randf())
			if dist > passo:
				e.robo_x += dx / dist * passo
				e.robo_y += dy / dist * passo
			else:
				e.robo_x = tx
				e.robo_y = ty
				e.robo_ponto += 1
			Forja.robo_tocar(l, 0, e.robo_x, e.robo_y, 0.06)
		ABRIR:
			if e.t < 0.4:
				return
			if not e.aberto:
				e.robo_s = minf(0.33, e.robo_s + dt * 0.35)
			else:
				e.robo_s = maxf(0.03, e.robo_s - dt * 0.35)
			Forja.robo_tocar(l, 0, 0.5 - e.robo_s, 0.5, 0.06)
			Forja.robo_tocar(l, 1, 0.5 + e.robo_s, 0.52, 0.06)
		CARIMBAR:
			if _no_ponto(e) and _calor(e) > 0.86:
				if e.robo_espera < 0.0:
					e.robo_espera = 0.05 + 0.1 * rng.randf()
				e.robo_espera -= dt
				if e.robo_espera <= 0.0:
					Forja.robo_apertar(l, F.TOUCHPAD, 0.08)
					e.robo_espera = 10.0  # espera o metal esfriar e voltar
			elif not _no_ponto(e):
				e.robo_espera = -1.0
