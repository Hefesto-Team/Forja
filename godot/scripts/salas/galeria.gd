class_name SalaGaleria
extends SalaJogo
## A Galeria — armas com gatilho adaptativo.
##
## O padrão dos jogos de tiro do PS5: cada arma tem o seu gatilho. A pistola
## tem parede e clique (Weapon), a metralhadora treme (Vibration), o arco pesa
## (Feedback); sem arma, o gatilho fica solto (Off). A munição fica na tela (no
## Modo bancada, nas cinco luzinhas brancas embaixo do touchpad, os LEDs de
## jogador; fora dele, as luzinhas são o número do lugar) e, quando acaba, o
## gatilho solta — "clique seco" — até recarregar. Só os quatro modos oficiais
## entram (CONTRATO.md).
##
## E é uma prova às cegas (cegas.h): a arma chega no baú fechado. A pessoa
## aperta R2, sente, e diz qual é (✕ pistola, ○ metralhadora, □ arco, △ sem
## arma) antes de ver; o baú abre e ela atira. No fim de cada rodada (no Modo
## bancada), o armeiro recarrega sem ninguém ver, e a pessoa diz quantas balas
## tem contando as luzinhas do controle — a tela não mostra. Cada arma aparece duas vezes, em
## ordem sorteada, e a que ficar no meio do caminho ganha rodada de desempate.

const F := preload("res://scripts/forja.gd")
const RAIAS := [-6.0, -2.0, 2.0, 6.0]
const Z_JOGADOR := 1.0
const Z_BAU := -0.35
const Z_ALVOS := -6.4
const VEZES := 2
const MAX_EXTRAS := 4
const IDENTIFICA_MAX := 14.0
const REVELA := 1.0
const ATIRA := 5.5
const MUNICAO_MAX := 9.0
const N_ALVOS := 3  ## na variante 1, um a mais
var n_alvos := N_ALVOS
const BALAS := 5
const BALAS_MG := 30
const MIRA_LARG := 2.8
const MIRA_Y0 := 0.8
const MIRA_Y1 := 2.7

enum { PISTOLA, METRALHADORA, ARCO, NENHUMA }
enum { IDENTIFICAR, REVELANDO, ATIRAR, MUNICAO, MUNICAO_RESP, PRONTO }

const NOME_ARMA := ["pistola", "metralhadora", "arco", "sem arma"]
const SENTE := ["parede e clique", "o tremor", "o peso", "solto"]
const BOTAO_OPCAO := [F.CRUZ, F.CIRCULO, F.QUADRADO, F.TRIANGULO]
const GLIFO_OPCAO := ["cross", "circle", "square", "triangle"]

var j := {}  ## lugar -> o estado do jogador
var n := {}  ## lugar -> os nós da raia


func _init() -> void:
	usa_gatilho = true
	id = "galeria"
	nome = "A Galeria"
	acao = "Sinta o gatilho e atire."
	icone = "r2"
	gesto_do_aviso = "holding-right-shoot"
	objetivo = "A arma chega no baú fechado. Aperte R2 e sinta: parede e clique é a pistola, tremor é a metralhadora, peso é o arco, solto é sem arma — diga qual (✕ ○ □ △) e o baú abre. Atire nos alvos com R2 (o analógico esquerdo mira, □ recarrega). No fim, o armeiro recarrega no escuro: conte as luzinhas do controle."
	features = ["gatilho_resistencia", "gatilho_arma", "gatilho_vibracao", "leds_jogador"]
	botoes_pedidos = F.mascara([F.CRUZ, F.CIRCULO, F.QUADRADO, F.TRIANGULO])
	cega = true
	duracao = 0.0
	camera_pos = Vector3(0, 7.5, 11.0)
	camera_olhar = Vector3(0, 0.2, -2.2)


func montar() -> void:
	n_alvos = N_ALVOS + variante
	Kit.arena(self, 5, 3)
	# o estande: o synthwave inteiro — poeira roxa e neon ciano
	atmosfera(Color("#c28bff"), Tema.VIOLETA, false, 50)
	luzes([Vector3(-9, 2.6, -5), Vector3(9, 2.6, -5), Vector3(0, 3.0, 5)])
	for p in jogadores:
		var l: int = p.lugar
		j[l] = _novo_jogador()
		n[l] = _montar_raia(l, p)
		Forja.gatilhos_off(l)


func _novo_jogador() -> Dictionary:
	var cegas: Array = []
	for k in 4:
		cegas.append(Cega.nova())
	return {"plano": Array(Forja.cega_plano_armas(VEZES, rng.randi())), "rodada": 0, "extras": 0,
		"passo": IDENTIFICAR, "t": 0.0, "arma": NENHUMA, "puxou": false, "resposta": -1,
		"balas": 0, "balas_mg": 0, "recarga": 0.0, "mira": Vector2(0.5, 0.5), "alvos": [],
		"cadencia": 0.0, "corda": 0.0, "armado": true, "acertos": 0, "cegas": cegas, "leds": Cega.nova(),
		"leds_pedido": 0, "leds_resposta": -1, "opcoes": [1, 2, 3, 4], "efeito_ok": false, "leds_ok": false,
		"comecou": false, "robo_t": 0.0, "robo_r2": 0.0, "robo_passo": 0}


func _montar_raia(l: int, p: ForjaPlayer) -> Dictionary:
	var x: float = RAIAS[l]
	var cor: Color = Forja.cor_do_lugar(l)
	# a raia: a faixa no chão na cor do lugar, do jogador até o muro dos alvos
	Kit.caixa(self, Vector3(1.5, 0.02, Z_JOGADOR - Z_ALVOS + 0.6), Vector3(x, 0.02, (Z_JOGADOR + Z_ALVOS) * 0.5),
		Kit.material(cor.darkened(0.6), 0.25, 0.8, l))
	# o baú do armeiro, numa mesa baixa na frente do jogador
	Kit.caixa(self, Vector3(1.3, 0.5, 0.9), Vector3(x, 0.25, Z_BAU), Kit.material(Tema.GRAFITE, 0.0, 0.9))
	var bau := Kit.peca(self, "chest", Vector3(x, 0.5, Z_BAU - 0.1), 0.0, 1.9)
	var interroga := Label3D.new()
	interroga.text = "?"
	interroga.font = Tema.archivo(700)
	interroga.font_size = 120
	interroga.pixel_size = 0.005
	interroga.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	interroga.modulate = Tema.ETIQUETA
	interroga.outline_size = 16
	interroga.outline_modulate = Color(Tema.FITA, 0.9)
	interroga.position = Vector3(x, 1.75, Z_BAU)
	add_child(interroga)
	# a arma revelada, flutuando sobre o baú
	var vitrine := Node3D.new()
	vitrine.position = Vector3(x, 1.45, Z_BAU)
	add_child(vitrine)
	# os alvos no muro do fundo
	var alvos: Array = []
	for k in n_alvos:
		alvos.append(_alvo_no())
	# a mira, no plano dos alvos
	var mira := Node3D.new()
	add_child(mira)
	var tinta := Kit.chapado(Tema.tom_para_a_borda(cor), true)
	var anel := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.rings = 8
	tor.ring_segments = 6
	tor.inner_radius = 0.16
	tor.outer_radius = 0.2
	anel.mesh = tor
	anel.rotation.x = PI * 0.5
	anel.material_override = tinta
	mira.add_child(anel)
	Kit.esfera(mira, 0.03, Vector3.ZERO, Kit.chapado(Tema.ETIQUETA, true))
	mira.visible = false
	p.position = Vector3(x, 0.05, Z_JOGADOR)
	p.rotation.y = PI
	p.preso = true  # a sala escolhe a pose (a mira com a arma)
	maos_livres(p)
	return {"bau": bau, "interroga": interroga, "vitrine": vitrine, "alvos": alvos, "mira": mira,
		"arma_mao": null, "aberto": false}


## Um alvo: três discos (branco, vermelho, branco) de frente para o jogador.
func _alvo_no() -> Node3D:
	var a := Node3D.new()
	add_child(a)
	var cores := [Tema.ETIQUETA, Tema.SECAO[0], Tema.ETIQUETA]
	for i in 3:
		var disco := Kit.cilindro(a, 0.42 - 0.13 * i, 0.04, Vector3(0, 0, 0.012 * i), Kit.material(cores[i], 0.15 if i == 1 else 0.0, 0.6))
		disco.rotation.x = PI * 0.5
	return a


## As armas, em blocos como as peças do kit: a pega na origem, o cano para +x.
static func _arma(pai: Node, qual: int) -> Node3D:
	var a := Node3D.new()
	pai.add_child(a)
	var ferro := Kit.material(Tema.GRAFITE, 0.0, 0.4)
	var claro := Kit.material(Tema.OXIDO_BRILHO, 0.0, 0.35)
	var madeira := Kit.material(Tema.OXIDO_BRILHO, 0.0, 0.8)
	match qual:
		PISTOLA:
			Kit.caixa(a, Vector3(0.36, 0.11, 0.08), Vector3(0.1, 0.07, 0), ferro)
			Kit.caixa(a, Vector3(0.14, 0.05, 0.05), Vector3(0.33, 0.09, 0), claro)
			var pega := Kit.caixa(a, Vector3(0.08, 0.2, 0.07), Vector3(-0.02, -0.06, 0), madeira)
			pega.rotation.z = 0.25
		METRALHADORA:
			Kit.caixa(a, Vector3(0.62, 0.13, 0.1), Vector3(0.18, 0.08, 0), ferro)
			var cano := Kit.cilindro(a, 0.03, 0.34, Vector3(0.64, 0.1, 0), claro)
			cano.rotation.z = PI * 0.5
			var tambor := Kit.cilindro(a, 0.09, 0.08, Vector3(0.2, -0.03, 0), claro)
			tambor.rotation.x = PI * 0.5
			var pega := Kit.caixa(a, Vector3(0.08, 0.18, 0.07), Vector3(-0.02, -0.05, 0), madeira)
			pega.rotation.z = 0.25
			Kit.caixa(a, Vector3(0.2, 0.1, 0.07), Vector3(-0.18, 0.06, 0), madeira)
		ARCO:
			# o arco em nove pedaços, e a corda
			for k in 9:
				var ang := lerpf(-1.05, 1.05, k / 8.0)
				var pedaco := Kit.caixa(a, Vector3(0.05, 0.13, 0.05), Vector3(cos(ang) * 0.42 - 0.3, sin(ang) * 0.42, 0), madeira)
				pedaco.rotation.z = ang
			var corda := Kit.cilindro(a, 0.006, 0.72, Vector3(cos(1.05) * 0.42 - 0.3, 0, 0), claro)
			corda.rotation.z = 0.0
	return a


func _gatilho(l: int, arma: int) -> void:
	var ok := false
	match arma:
		PISTOLA:
			ok = Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, 8)
		METRALHADORA:
			ok = Forja.gatilho(l, 1, Forja.GATILHO_VIBRACAO, 0, 7, 30)
		ARCO:
			ok = Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 1, 6, 0)
		_:
			ok = Forja.gatilho(l, 1, Forja.GATILHO_OFF)
	if ok:
		j[l].efeito_ok = true


func _leds(l: int, quantos: int) -> void:
	if not Forja.bancada:
		return  # as luzinhas são o número do lugar; só a bancada as usa de munição
	var mascara := (1 << clampi(quantos, 0, 5)) - 1
	if Forja.leds_jogador(l, mascara):
		j[l].leds_ok = true


static func _luzes_da_mg(balas: int) -> int:
	return (balas + 5) / 6


# ------------------------------------------------------------------ o jogo --

func _sortear_alvos(e: Dictionary) -> void:
	var alvos: Array = []
	for k in n_alvos:
		alvos.append({"x": rng.randf(), "y": 0.18 + 0.6 * k / (n_alvos - 1),
			"v": (0.18 + 0.18 * rng.randf()) * (-1.0 if k % 2 else 1.0), "vivo": true, "quebra": 0.0})
	e.alvos = alvos


func _nova_rodada(l: int) -> void:
	var e: Dictionary = j[l]
	e.arma = int(e.plano[e.rodada])
	e.passo = IDENTIFICAR
	e.t = 0.0
	e.puxou = false
	e.resposta = -1
	e.robo_passo = 0
	e.robo_t = 0.0
	_gatilho(l, e.arma)
	Forja.leds_do_lugar(l)  # na identificação, as luzinhas não contam nada
	_fechar_bau(l)
	Forja.evento("jogo", l + 1, {"sala": id, "o": "arma_no_escuro", "arma": NOME_ARMA[e.arma]})
	if not Forja.bancada:
		if e.arma == NENHUMA:
			_proxima_rodada(l)  # sem pergunta, a rodada sem arma não tem jogo
			return
		e.passo = REVELANDO  # o baú abre na hora; REVELANDO leva a ATIRAR
		e.t = 0.0
		_abrir_bau(l, e.arma)
		return
	Forja.evento("jogo", l + 1, {"sala": id, "o": "pergunta", "qual": "arma"})


func jogar(dt: float) -> void:
	for p in jogadores:
		var l: int = p.lugar
		var e: Dictionary = j[l]
		if acabou[l] or not Forja.lugar(l).get("conectado", false):
			continue
		if not e.comecou:
			e.comecou = true
			_sortear_alvos(e)
			_nova_rodada(l)
		if Forja.robo:
			_robo(l, e, dt)
		_jogar(l, p, e, dt)


func _jogar(l: int, p: ForjaPlayer, e: Dictionary, dt: float) -> void:
	e.t = float(e.t) + dt
	var r2 := Forja.eixo(l, F.R2)
	match int(e.passo):
		IDENTIFICAR:
			if r2 >= 0.25:
				e.puxou = true
			if e.puxou and e.t > 0.4:
				for k in 4:
					if Forja.apertou(l, BOTAO_OPCAO[k]):
						_responder_arma(l, p, k)
						return
			if e.t > IDENTIFICA_MAX:
				_responder_arma(l, p, -1)
		REVELANDO:
			if e.t >= REVELA:
				if e.arma == NENHUMA:
					_perguntar_municao(l)
				else:
					e.passo = ATIRAR
					e.t = 0.0
					e.balas = BALAS
					e.balas_mg = BALAS_MG
					e.armado = true
					e.corda = 0.0
					_leds(l, _luzes_da_mg(e.balas_mg) if e.arma == METRALHADORA else int(e.balas))
					_sortear_alvos(e)
					_arma_na_mao(l, p, e.arma)
		ATIRAR:
			var m: Vector2 = e.mira
			m.x = clampf(m.x + Forja.eixo(l, F.LX) * 1.1 * dt, 0.0, 1.0)
			m.y = clampf(m.y + Forja.eixo(l, F.LY) * 1.1 * dt, 0.0, 1.0)
			e.mira = m
			for a in e.alvos:
				a.x = float(a.x) + float(a.v) * dt
				if a.x < 0.05 or a.x > 0.95:
					a.v = -float(a.v)
				a.x = clampf(float(a.x), 0.05, 0.95)
				if not a.vivo:
					a.quebra = float(a.quebra) - dt
					if a.quebra < -0.8:
						a.vivo = true
						a.x = rng.randf()
			if e.recarga > 0.0:
				e.recarga = float(e.recarga) - dt
				if e.recarga <= 0.0:
					e.balas = BALAS
					e.balas_mg = BALAS_MG
					_leds(l, _luzes_da_mg(e.balas_mg) if e.arma == METRALHADORA else int(e.balas))
					_gatilho(l, e.arma)
					Som.tocar("confirma", p.global_position + Vector3(0, 1, 0), -8.0)
			elif _vazia(e):
				if Forja.apertou(l, F.QUADRADO):
					e.recarga = 0.8
			else:
				match int(e.arma):
					PISTOLA:
						# dispara ao passar do clique; rearma ao soltar
						if e.armado and r2 >= 0.62:
							e.armado = false
							_atirar(l, p, e)
						elif r2 <= 0.3:
							e.armado = true
					METRALHADORA:
						e.cadencia = float(e.cadencia) - dt
						if r2 >= 0.35 and e.cadencia <= 0.0:
							e.cadencia = 0.09
							_atirar(l, p, e)
					ARCO:
						# puxar contra a resistência, soltar para disparar
						if r2 >= 0.15:
							e.corda = maxf(float(e.corda), r2)
						elif e.corda > 0.55:
							_atirar(l, p, e)
							e.corda = 0.0
						else:
							e.corda = 0.0
			if e.t >= ATIRA * ritmo_nivel:
				_perguntar_municao(l)
		MUNICAO:
			if e.t > 0.5:
				for k in 4:
					if Forja.apertou(l, BOTAO_OPCAO[k]):
						e.leds_resposta = k
						break
			if e.leds_resposta >= 0 or e.t > MUNICAO_MAX:
				var res := ""
				if e.leds_resposta < 0:
					Cega.perdido(e.leds)
					res = "perdido"
				elif int(e.opcoes[e.leds_resposta]) == int(e.leds_pedido):
					Cega.certo(e.leds)
					marcar(l, 100)
					res = "certo"
				else:
					Cega.errado(e.leds, int(e.opcoes[e.leds_resposta]))
					res = "errado"
				Forja.evento("jogo", l + 1, {"sala": id, "o": "resposta_municao", "resultado": res})
				Som.tocar("confirma" if res == "certo" else "falha", p.global_position + Vector3(0, 1, 0), -8.0)
				e.passo = MUNICAO_RESP
				e.t = 0.0
		MUNICAO_RESP:
			if e.t >= REVELA:
				_proxima_rodada(l)


static func _vazia(e: Dictionary) -> bool:
	return int(e.balas_mg) <= 0 if int(e.arma) == METRALHADORA else int(e.balas) <= 0


func _atirar(l: int, p: ForjaPlayer, e: Dictionary) -> void:
	var m: Vector2 = e.mira
	var acertou := false
	for a in e.alvos:
		if not a.vivo:
			continue
		var dx := (float(a.x) - m.x) * 1.4
		var dy := float(a.y) - m.y
		if dx * dx + dy * dy < 0.09 * 0.09:
			a.vivo = false
			a.quebra = 1.0
			acertou = true
			e.acertos += 1
			marcar(l, 50)
			Efeitos.faiscas(self, _no_muro(l, Vector2(a.x, a.y)), Tema.TUNGSTENIO, 18, 0.8)
			Som.tocar("alvo", _no_muro(l, Vector2(a.x, a.y)), -4.0)
			break
	p.gesto("holding-right-shoot", 0.2)
	_rastro(l, p, _no_muro(l, m))
	Som.tocar("bigorna_aguda" if acertou else "tique", _no_muro(l, m), -6.0 if acertou else -12.0)
	# a arma já foi revelada: o tiro soa na mão (a metralhadora só no gatilho)
	if e.arma != METRALHADORA:
		Som.tocar("tiro", p.global_position + Vector3(0, 1.2, 0), -10.0)
		Som.no_controle(l, "tiro", 0.45)
	if e.arma == METRALHADORA:
		var antes := _luzes_da_mg(int(e.balas_mg))
		e.balas_mg -= 1
		var agora := _luzes_da_mg(int(e.balas_mg))
		if agora != antes:
			_leds(l, agora)
		if e.balas_mg <= 0:
			_gatilho(l, NENHUMA)  # sem munição, o gatilho solta
	else:
		e.balas -= 1
		_leds(l, int(e.balas))
		if e.balas <= 0:
			_gatilho(l, NENHUMA)


## O ponto do muro dos alvos para uma posição da mira (x e y de 0 a 1).
func _no_muro(l: int, m: Vector2) -> Vector3:
	return Vector3(RAIAS[l] + (m.x - 0.5) * MIRA_LARG, lerpf(MIRA_Y1, MIRA_Y0, m.y), Z_ALVOS + 0.12)


## O risco do tiro, da mão até o muro.
func _rastro(l: int, p: ForjaPlayer, ate: Vector3) -> void:
	var de := p.global_position + Vector3(0.25, 1.05, -0.4)
	var risco := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.018
	c.radial_segments = 8
	c.bottom_radius = 0.018
	c.height = de.distance_to(ate)
	risco.mesh = c
	var m := Kit.chapado(Color(Tema.TUNGSTENIO, 0.9))
	risco.material_override = m
	add_child(risco)
	risco.global_position = (de + ate) * 0.5
	risco.look_at(ate, Vector3.UP)
	risco.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	var tw := risco.create_tween()
	tw.tween_property(m, "albedo_color:a", 0.0, 0.12)
	tw.tween_callback(risco.queue_free)
	Efeitos.faiscas(self, de, Tema.TUNGSTENIO, 6, 0.3)


func _responder_arma(l: int, p: ForjaPlayer, r: int) -> void:
	var e: Dictionary = j[l]
	e.resposta = r
	var c: Dictionary = e.cegas[e.arma]
	var res := ""
	if r < 0:
		Cega.perdido(c)
		res = "perdido"
	elif r == e.arma:
		Cega.certo(c)
		marcar(l, 150)
		res = "certo"
	else:
		Cega.errado(c, r)
		res = "errado"
	Forja.evento("jogo", l + 1, {"sala": id, "o": "resposta_arma", "resultado": res})
	Som.tocar("confirma" if r == e.arma else "falha", p.global_position + Vector3(0, 1, 0), -6.0)
	e.passo = REVELANDO
	e.t = 0.0
	_abrir_bau(l, e.arma)


func _perguntar_municao(l: int) -> void:
	# o armeiro recarregou no escuro: quantas balas há agora?
	var e: Dictionary = j[l]
	if not Forja.bancada:
		_guardar_arma(l)
		_gatilho(l, NENHUMA)
		_proxima_rodada(l)
		return
	var quantas := rng.randi_range(1, 5)
	e.leds_pedido = quantas
	e.leds_resposta = -1
	var pos := rng.randi_range(0, 3)
	var usados := {quantas: true}
	var opcoes: Array = [0, 0, 0, 0]
	for k in 4:
		if k == pos:
			opcoes[k] = quantas
			continue
		var o := rng.randi_range(1, 5)
		while usados.has(o):
			o = rng.randi_range(1, 5)
		usados[o] = true
		opcoes[k] = o
	e.opcoes = opcoes
	_leds(l, quantas)
	_gatilho(l, NENHUMA)
	_guardar_arma(l)
	e.passo = MUNICAO
	e.t = 0.0
	Forja.evento("jogo", l + 1, {"sala": id, "o": "pergunta_municao", "luzes": quantas})
	Forja.evento("jogo", l + 1, {"sala": id, "o": "pergunta", "qual": "luzes"})


func _proxima_rodada(l: int) -> void:
	var e: Dictionary = j[l]
	e.rodada += 1
	var plano: Array = e.plano
	if e.rodada >= plano.size():
		# desempate: a arma que ficou no meio do caminho ganha mais uma rodada
		for k in [PISTOLA, METRALHADORA, ARCO]:
			if e.extras < MAX_EXTRAS and not Forja.cega_decidida("arma", e.cegas[k]) and Cega.total(e.cegas[k]) > 0 \
					and (plano.is_empty() or int(plano[plano.size() - 1]) != k):
				plano.append(k)
				e.extras += 1
	if e.rodada >= plano.size():
		e.passo = PRONTO
		acabou[l] = true
		_gatilho(l, NENHUMA)
		Forja.leds_do_lugar(l)
		_fechar_bau(l)
		var p := jogador(l)
		if p:
			p.gesto("emote-yes", 1.4)
		return
	_nova_rodada(l)


func dar_vereditos(l: int) -> Array:
	var e: Dictionary = j[l]
	var lista: Array = [
		Forja.cega_veredito(l, "gatilho_resistencia", {"cega": e.cegas[ARCO], "nenhuma": e.cegas[NENHUMA], "sdl_aceitou": e.efeito_ok}),
		Forja.cega_veredito(l, "gatilho_arma", {"cega": e.cegas[PISTOLA], "nenhuma": e.cegas[NENHUMA], "sdl_aceitou": e.efeito_ok}),
		Forja.cega_veredito(l, "gatilho_vibracao", {"cega": e.cegas[METRALHADORA], "nenhuma": e.cegas[NENHUMA], "sdl_aceitou": e.efeito_ok}),
		Forja.cega_veredito(l, "leds_jogador", {"cega": e.leds, "sdl_aceitou": e.leds_ok or not Forja.bancada}),
	]
	return lista.filter(func(v): return not v.is_empty())


# ------------------------------------------------------------------ o baú e a arma --

func _fechar_bau(l: int) -> void:
	var nos: Dictionary = n[l]
	if nos.aberto:
		var anim: AnimationPlayer = nos.bau.find_child("AnimationPlayer", true, false)
		if anim and anim.has_animation("close"):
			anim.play("close")
	nos.aberto = false
	for filho in nos.vitrine.get_children():
		filho.queue_free()


func _abrir_bau(l: int, arma: int) -> void:
	var nos: Dictionary = n[l]
	var anim: AnimationPlayer = nos.bau.find_child("AnimationPlayer", true, false)
	if anim and anim.has_animation("open"):
		anim.play("open")
	nos.aberto = true
	var bau_topo := Vector3(RAIAS[l], 1.0, Z_BAU)
	if arma == NENHUMA:
		Efeitos.faiscas(self, bau_topo, Tema.ETIQUETA_SOMBRA, 12, 0.4)
		return
	var a := _arma(nos.vitrine, arma)
	a.scale = Vector3.ONE * 2.2
	a.position.x = -0.25
	Efeitos.faiscas(self, bau_topo, Tema.TUNGSTENIO, 20, 0.7)


func _guardar_arma(l: int) -> void:
	var nos: Dictionary = n[l]
	if nos.arma_mao and is_instance_valid(nos.arma_mao):
		nos.arma_mao.queue_free()
	nos.arma_mao = null
	_fechar_bau(l)


func _arma_na_mao(l: int, p: ForjaPlayer, arma: int) -> void:
	var nos: Dictionary = n[l]
	for filho in nos.vitrine.get_children():
		filho.queue_free()
	var esqueleto: Skeleton3D = p.modelo.find_child("Skeleton3D", true, false)
	if esqueleto == null:
		return
	var presa := BoneAttachment3D.new()
	presa.bone_name = "arm-right"
	esqueleto.add_child(presa)
	var a := _arma(presa, arma)
	a.scale = Vector3.ONE * 0.9
	a.position = Vector3(-0.03, -0.2, 0.06)
	a.rotation_degrees = Vector3(0, -90, -90)
	nos.arma_mao = presa


# ------------------------------------------------------------------ o que se vê --

func _process(dt: float) -> void:
	super(dt)
	for p in jogadores:
		_mostrar(p.lugar, p)


func _mostrar(l: int, p: ForjaPlayer) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = n[l]
	var passo := int(e.passo) if fase == "jogo" else -1
	var interroga: Label3D = nos.interroga
	interroga.visible = passo == IDENTIFICAR or fase == "aviso"
	interroga.position.y = 1.75 + 0.06 * sin(t * 3.0 + l)
	var vitrine: Node3D = nos.vitrine
	vitrine.position.y = 1.5 + 0.05 * sin(t * 2.4 + l)
	var mira: Node3D = nos.mira
	mira.visible = passo == ATIRAR
	if mira.visible:
		mira.position = _no_muro(l, e.mira) + Vector3(0, 0, 0.06)
	for k in n_alvos:
		var no: Node3D = nos.alvos[k]
		var dados: Dictionary = e.alvos[k] if k < e.alvos.size() else {}
		no.visible = passo == ATIRAR and not dados.is_empty() and (dados.vivo or float(dados.quebra) > 0.0)
		if no.visible:
			no.position = _no_muro(l, Vector2(dados.x, dados.y))
			no.scale = Vector3.ONE if dados.vivo else Vector3.ONE * maxf(0.01, float(dados.quebra))
	if passo == ATIRAR:
		p.animar("holding-right")
	else:
		p.animar("idle")


# ------------------------------------------------------------------ a HUD --

func status(lugar: int) -> String:
	if fase == "jogo" and j.has(lugar) and not acabou[lugar]:
		var e: Dictionary = j[lugar]
		if int(e.passo) == ATIRAR and not Forja.bancada:
			# na bancada a munição é contada nas luzinhas, às cegas: a tela não mostra
			var balas := int(e.balas_mg) if int(e.arma) == METRALHADORA else int(e.balas)
			return "1 bala" if balas == 1 else "%d balas" % balas
		return "Rodada %d de %d · %d ✓" % [int(e.rodada) + 1, e.plano.size(), e.acertos]
	return super(lugar)


func dica(lugar: int) -> Dictionary:
	if not j.has(lugar):
		return {}
	var e: Dictionary = j[lugar]
	if int(e.passo) != ATIRAR:
		return {}
	var partes: Array = ["@square", "Recarrega"] if _vazia(e) else ["@stick_l", "Mira", "@r2", "Atira"]
	return {"partes": partes, "pos": Vector3(RAIAS[lugar], 0.0, 4.6)}


func pergunta(lugar: int) -> Dictionary:
	if not Forja.bancada:
		return {}  # a pergunta às cegas é do Modo bancada
	if not j.has(lugar) or fase != "jogo":
		return {}
	var e: Dictionary = j[lugar]
	var pos := Vector3(RAIAS[lugar], 0.0, 4.6)
	match int(e.passo):
		IDENTIFICAR, REVELANDO:
			var opcoes: Array = []
			for k in 4:
				opcoes.append([GLIFO_OPCAO[k], Desenho.maiusc(NOME_ARMA[k])])
			var titulo := "Aperte R2 e sinta: que arma é?" if e.puxou or int(e.passo) == REVELANDO else "Aperte R2 e sinta o gatilho."
			var certa := -1
			var rodape := ""
			if int(e.passo) == REVELANDO:
				certa = int(e.arma)
				if e.resposta < 0:
					rodape = "Sem resposta — era %s" % NOME_ARMA[e.arma]
				elif e.resposta == e.arma:
					rodape = "Isso: %s" % SENTE[e.arma]
				else:
					rodape = "Era %s (%s)" % [NOME_ARMA[e.arma], SENTE[e.arma]]
			return {"titulo": titulo, "opcoes": opcoes, "escolhida": e.resposta, "certa": certa, "rodape": rodape, "pos": pos}
		MUNICAO, MUNICAO_RESP:
			var opcoes2: Array = []
			for k in 4:
				opcoes2.append([GLIFO_OPCAO[k], "%d luzinha%s" % [e.opcoes[k], "" if int(e.opcoes[k]) == 1 else "s"]])
			var certa2 := -1
			var rodape2 := ""
			if int(e.passo) == MUNICAO_RESP:
				certa2 = e.opcoes.find(e.leds_pedido)
				if e.leds_resposta < 0:
					rodape2 = "Sem resposta — eram %d" % e.leds_pedido
				elif int(e.opcoes[e.leds_resposta]) == int(e.leds_pedido):
					rodape2 = "Isso: as luzinhas obedeceram"
				else:
					rodape2 = "Não — o jogo acendeu %d" % e.leds_pedido
			return {"titulo": "O armeiro recarregou. Quantas luzinhas acesas?", "opcoes": opcoes2,
				"escolhida": e.leds_resposta, "certa": certa2, "rodape": rodape2, "pos": pos}
	return {}


# ------------------------------------------------------------------ o robô --
# Sente o gatilho, vê a galeria e conta as luzinhas, como quem segura o
# controle simulado: aperta R2, sente o modo que chegou ao dedo, responde;
# mira nos alvos e atira do jeito de cada arma; conta os LEDs acesos.

func _robo(l: int, e: Dictionary, dt: float) -> void:
	var pc := Forja.percepcao(l)
	if pc.is_empty():
		return
	e.robo_t = float(e.robo_t) + dt
	var alvo_r2 := 0.0
	match int(e.passo):
		IDENTIFICAR:
			if e.robo_t > 0.35 and e.robo_t < 1.1:
				alvo_r2 = 0.72
			if e.robo_t > 1.4 and e.robo_passo == 0:
				Forja.robo_apertar(l, BOTAO_OPCAO[_arma_sentida(int(pc.get("gatilho_dir", 0)))], 0.08)
				e.robo_passo = 1
		ATIRAR:
			if _vazia(e) and e.recarga <= 0.0:
				if e.robo_passo != 7:
					Forja.robo_apertar(l, F.QUADRADO, 0.08)
					e.robo_passo = 7
			else:
				if e.robo_passo == 7 and not _vazia(e):
					e.robo_passo = 0
				var alvo = null
				for a in e.alvos:
					if a.vivo:
						alvo = a
						break
				if alvo != null:
					var m: Vector2 = e.mira
					var dx: float = float(alvo.x) - m.x
					var dy: float = float(alvo.y) - m.y
					Forja.robo_eixo(l, F.LX, clampf(dx * 8.0, -1.0, 1.0), 0.06)
					Forja.robo_eixo(l, F.LY, clampf(dy * 8.0, -1.0, 1.0), 0.06)
					var perto := dx * dx * 1.96 + dy * dy < 0.05 * 0.05
					match int(e.arma):
						PISTOLA:
							alvo_r2 = 0.85 if perto and fmod(float(e.robo_t), 0.4) < 0.2 else 0.0
						METRALHADORA:
							alvo_r2 = 0.6 if perto else 0.0
						ARCO:
							alvo_r2 = 0.0 if perto and e.corda > 0.8 else 0.9
		MUNICAO:
			if e.robo_passo != 3:
				e.robo_t = 0.0
				e.robo_passo = 3
			if e.robo_t > 0.7 and e.leds_resposta < 0:
				var acesas := _luzes_acesas(int(pc.get("leds_jogador", 0)))
				var escolha := 0
				for k in 4:
					if int(e.opcoes[k]) == acesas:
						escolha = k
				Forja.robo_apertar(l, BOTAO_OPCAO[escolha], 0.08)
				e.robo_t = -100.0
	e.robo_r2 = alvo_r2 + (float(e.robo_r2) - alvo_r2) * exp(-9.0 * dt)
	Forja.robo_eixo(l, F.R2, float(e.robo_r2), 0.06)


## A arma pelo que chegou ao dedo: o primeiro byte do efeito do R2.
static func _arma_sentida(modo_hid: int) -> int:
	match modo_hid:
		0x25:
			return PISTOLA
		0x26:
			return METRALHADORA
		0x21:
			return ARCO
	return NENHUMA


static func _luzes_acesas(mascara: int) -> int:
	var total := 0
	for i in 5:
		total += (mascara >> i) & 1
	return total
