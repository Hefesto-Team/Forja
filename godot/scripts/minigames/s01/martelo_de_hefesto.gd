extends Minigame

const BOTOES := [Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO, Forja.TRIANGULO, Forja.L1, Forja.R1, Forja.L3,
	Forja.R3, Forja.CIMA, Forja.BAIXO, Forja.ESQUERDA, Forja.DIREITA, Forja.CREATE]

const FICHA := {
	"slot": "S01_J01",
	"titulo": "O Martelo de Hefesto",
	"verbo": "Martele!",
	"genero": "tct",
	"icone": "botoes",
	"entradas": BOTOES,
	"camera": "fixa",
	"faixa": "MUS_S01_J01",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "erro"],
	"material": "metal",
	"microjogo": {"verbo": "Martele!", "segundos": 6.0},
	"nota_no_falante": false,
	"features": ["botoes", "analogicos", "gatilhos_analogicos"],
	"botoes_medidos": BOTOES,
	"gesto": "attack-melee-right",
	"como_jogar": [["cross", "Bata no tempo da runa"], ["stick_l", "Gire até a borda"],
		["r2", "Segure o fole no dourado"]],
}

const GLIFO := {
	Forja.CRUZ: "cross", Forja.CIRCULO: "circle", Forja.QUADRADO: "square", Forja.TRIANGULO: "triangle",
	Forja.L1: "l1", Forja.R1: "r1", Forja.L3: "stick_l", Forja.R3: "stick_r", Forja.CIMA: "dpad_up",
	Forja.BAIXO: "dpad_down", Forja.ESQUERDA: "dpad_left", Forja.DIREITA: "dpad_right", Forja.CREATE: "share",
}
const PASSO := 2.0
const AVISO_B := 2.0
const ANEL_ABERTO := 1.7
const ANEL_FECHADO := 0.74
const PONTOS := [0, 60, 80, 100]
const MIRA := [0.0, 0.015, 0.03, -0.01]
const JANELA_ANALOGICO := 7.0
const JANELA_GATILHO := 8.0
const MAX_TENTATIVAS := 3
const BORDA := 0.85

var j := {}
var runas := {}
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]


func montar() -> void:
	camera_pos = Vector3(0, 7.2, 12.4)
	camera_olhar = Vector3(0, 1.2, -0.2)
	Kit.arena(self, 5, 3)
	atmosfera(Tema.AR["centelha"], Tema.VIOLETA, true, 60)
	luzes([Vector3(-9, 2.5, -4), Vector3(9, 2.5, -4), Vector3(0, 3.0, 4)])
	for p in jogadores:
		var l: int = p.lugar
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
		runas[l]["forja"] = forja
		j[l] = _novo_jogador()


static func _bigorna(l: int) -> Vector3:
	return Vector3(RAIAS[l] + 0.45, 0.0, 0.3)


func _fila_da_volta(volta: int) -> Array:
	var ordem: Array = BOTOES.duplicate() if volta == 0 else [Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO, Forja.TRIANGULO, Forja.L1, Forja.R1]
	for i in range(ordem.size() - 1, 0, -1):
		var k := rng.randi_range(0, i)
		var tmp = ordem[i]
		ordem[i] = ordem[k]
		ordem[k] = tmp
	var lado := rng.randi_range(0, 1)
	var extras: Array = []
	var posicoes: Array = []
	if volta == 0:
		extras = [{"tipo": "analogico", "alvo": lado}, {"tipo": "gatilho", "alvo": lado},
			{"tipo": "analogico", "alvo": 1 - lado}, {"tipo": "gatilho", "alvo": 1 - lado}]
		posicoes = [3, 6, 9, 12]
	else:
		extras = [{"tipo": "analogico", "alvo": lado}, {"tipo": "gatilho", "alvo": 1}]
		posicoes = [3, 6]
	var fila: Array = []
	var e := 0
	for b in ordem:
		while e < extras.size() and posicoes[e] == fila.size():
			fila.append(extras[e].duplicate())
			e += 1
		fila.append({"tipo": "botao", "alvo": b})
	while e < extras.size():
		fila.append(extras[e].duplicate())
		e += 1
	for r in fila:
		r["tentativas"] = 0
	return fila


func _novo_jogador() -> Dictionary:
	return {"fila": _fila_da_volta(0), "volta": 0, "atual": 0, "t": 0.0, "n": 0, "b": 0.0, "setores": 0, "estagio": 0,
		"segurou": 0.0, "combo": 0, "tremor": 0.0, "pop": 0.0,
		"robo_reacao": -1.0, "robo_passo": 0, "robo_ang": 0.0, "robo_gatilho": 0.0, "robo_n": -1, "robo_mira": 0.0}


func _montar_runa(l: int) -> Dictionary:
	var raiz := Node3D.new()
	raiz.position = _bigorna(l) + Vector3(0, 2.55, 0)
	raiz.visible = false
	add_child(raiz)
	var glifo := Sprite3D.new()
	glifo.pixel_size = 0.0062
	glifo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glifo.shaded = false
	glifo.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	raiz.add_child(glifo)
	var anel := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.rings = 8
	t.ring_segments = 6
	t.inner_radius = 0.66
	t.outer_radius = 0.74
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
		esf.radial_segments = 8
		esf.rings = 4
		esf.height = 0.14
		m.mesh = esf
		var ang := s * PI / 4.0
		m.position = Vector3(cos(ang) * 0.95, -sin(ang) * 0.95, 0)
		m.material_override = Kit.material(Tema.GRAFITE, 0.0)
		raiz.add_child(m)
		marcas.append(m)
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
	n.raiz.visible = r != null and fase == "jogo" and not acabou[l]
	if r == null:
		_forja_na_espera(l, -1.0)
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
	glifo.scale = Vector3.ONE * brilho
	glifo.position.x = sin(t * 60.0) * 0.08 * e.tremor
	var resto := 1.0
	var anel: MeshInstance3D = n.anel
	if r.tipo == "botao":
		var alvo := alvo_da(l, e.n)
		resto = clampf((alvo - Ritmo.t_musica()) / (AVISO_B * 60.0 / Ritmo.bpm), 0.0, 1.0) if alvo >= 0.0 else 0.0
		anel.scale = Vector3.ONE * lerpf(ANEL_FECHADO, ANEL_ABERTO, resto) * (1.0 + 0.08 * amplitude_da_espera() * pulso_da_batida())
		glifo.modulate = Tema.ETIQUETA if resto < 1.0 else Tema.ETIQUETA * Color(1, 1, 1, 0.55)
		_forja_na_espera(l, 1.0 - resto if resto < 1.0 else 0.0)
	else:
		var janela: float = JANELA_ANALOGICO if r.tipo == "analogico" else JANELA_GATILHO
		resto = clampf(1.0 - e.t / janela, 0.0, 1.0)
		anel.scale = Vector3.ONE * lerpf(ANEL_FECHADO, 1.0, resto)
		glifo.modulate = Tema.ETIQUETA
		_forja_na_espera(l, 1.0 - resto)
	anel.visible = true
	for s in 8:
		var m: MeshInstance3D = n.marcas[s]
		m.visible = r.tipo == "analogico"
		var aceso := (int(e.setores) >> s) & 1
		m.material_override = Kit.material(Tema.TUNGSTENIO if aceso else Tema.GRAFITE, 2.0 if aceso else 0.0, 0.8, "forja")
	var fole: Node3D = n.fole
	fole.visible = r.tipo == "gatilho"
	if r.tipo == "gatilho":
		var v := Forja.eixo(l, Forja.R2 if r.alvo == 1 else Forja.L2)
		var nivel: MeshInstance3D = n.nivel
		nivel.scale = Vector3(1, maxf(0.02, v * 1.4), 1)
		nivel.position.y = v * 1.4 * 0.5
		n.faixa.visible = e.estagio == 0
		n.topo.visible = e.estagio == 1


func jogar(dt: float) -> void:
	_calor = 0.0
	for p in jogadores:
		var l: int = p.lugar
		var e: Dictionary = j[l]
		e.pop = move_toward(e.pop, 0.0, dt * 5.0)
		e.tremor = move_toward(e.tremor, 0.0, dt * 4.0)
		if not acabou[l]:
			_jogar(l, p, dt)
		_mostrar_runa(l)
	_chaves_na_espera()


func iniciar_jogo() -> void:
	for p in jogadores:
		_armar(p.lugar, 0.0)


func _armar(l: int, desde: float) -> void:
	var e: Dictionary = j[l]
	var r = _runa_atual(l)
	if r == null:
		return
	if r.tipo == "botao":
		e.b = proxima_batida(l, desde, PASSO, 0.5 * l)
		e.n += 1
		nova_nota(l, e.n, Ritmo.t_da_batida(e.b))
	elif r.tipo == "gatilho" and r.alvo == 1:
		Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 3, 4)


func _jogar(l: int, p: ForjaPlayer, dt: float) -> void:
	var e: Dictionary = j[l]
	var r = _runa_atual(l)
	if r == null:
		return
	if r.tipo == "botao":
		_jogar_botao(l, e, r)
		return
	Forja.med_pedido(l, -1)
	Forja.med_pedir(l, ("analogico_r" if r.alvo == 1 else "analogico_l") if r.tipo == "analogico" else ("gatilho_r2" if r.alvo == 1 else "gatilho_l2"))
	e.t += dt
	match str(r.tipo):
		"analogico":
			var x := Forja.eixo(l, Forja.RX if r.alvo == 1 else Forja.LX)
			var y := Forja.eixo(l, Forja.RY if r.alvo == 1 else Forja.LY)
			if Vector2(x, y).length() >= BORDA:
				var antes: int = e.setores
				e.setores = int(e.setores) | (1 << _setor(x, y))
				if e.setores != antes:
					Som.tocar("tique", runas[l].raiz.global_position, -6.0, 1.0 + 0.06 * _contar(e.setores))
					Forja.sentir(l, "acerto")
			if e.setores == 0xFF:
				Forja.evento("entrada", l + 1, {"o": "analogico", "detalhe": ("direito" if r.alvo == 1 else "esquerdo") + ": as oito direções"})
				_acerto_especial(l, p, 250)
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
					if r.alvo == 1:
						Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, 8)
				else:
					Forja.evento("entrada", l + 1, {"o": "gatilho", "detalhe": ("R2" if r.alvo == 1 else "L2") + ": meio e fundo"})
					_acerto_especial(l, p, 250)
			elif e.t > JANELA_GATILHO:
				_perdeu(l, p)


func _jogar_botao(l: int, e: Dictionary, r: Dictionary) -> void:
	var alvo := alvo_da(l, e.n)
	if alvo >= 0.0:
		var dentro := absf(Ritmo.t_musica() - alvo) <= ALCANCE_DO_TOQUE
		Forja.med_pedido(l, r.alvo if dentro else -1)
		for b in BOTOES:
			if not dentro or not Forja.apertou(l, b) or casar_toque(l) != e.n:
				continue
			if b == r.alvo:
				julgar_nota(l, e.n)
			else:
				nota_perdida(l, e.n)
			break
		notas_perdidas(l)
	if alvo_da(l, e.n) < 0.0:
		_proxima(l)


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


func _faiscas(l: int, forca: float, cor: Color) -> void:
	var topo := _bigorna(l) + Vector3(0, 0.8, 0)
	Efeitos.faiscas(self, topo, cor, int(26.0 * forca), forca)
	Efeitos.anel(self, runas[l].raiz.global_position, Forja.cor_do_lugar(l), 0.7, Vector3.BACK, l)
	Som.tocar("bigorna_aguda" if forca <= 1.0 else "bigorna", topo, -2.0)
	Som.tocar("martelo", topo, -6.0)


func toque(l: int, julgamento: int) -> void:
	var e: Dictionary = j[l]
	e.combo += 1
	contagem[l][julgamento] += 1
	marcar(l, int(PONTOS[julgamento]) + mini(10 * (int(e.combo) - 1), 100))
	e.pop = 1.0
	_faiscas(l, 1.0 if julgamento < Ritmo.PERFEITO else 1.4, Tema.TUNGSTENIO)
	julgar(l, julgamento, "", _tempo_forte[l])
	var p := jogador(l)
	if p:
		p.gesto("attack-melee-right", 0.45)
	if julgamento < Ritmo.PERFEITO:
		Forja.piscar(l, Forja.cor_do_lugar(l).lightened(0.4), PISCA_PERFEITO_S)


func falha(l: int) -> void:
	var r = _runa_atual(l)
	if r != null:
		_queda(l, r)


func _queda(l: int, r: Dictionary) -> void:
	var e: Dictionary = j[l]
	e.combo = 0
	e.tremor = 1.0
	contagem[l][0] += 1
	julgar(l, 0)
	var p := jogador(l)
	if p:
		p.gesto("emote-no", 0.6)
	Efeitos.faiscas(self, _bigorna(l) + Vector3(0, 0.8, 0), Tema.GRAFITE, 10, 0.5)
	r.tentativas = int(r.tentativas) + 1
	if r.tentativas < MAX_TENTATIVAS:
		e.fila.append(r.duplicate())


func _acerto_especial(l: int, p: ForjaPlayer, base: int) -> void:
	var e: Dictionary = j[l]
	e.combo += 1
	contagem[l][Ritmo.OTIMO] += 1
	marcar(l, base + mini(10 * (int(e.combo) - 1), 100))
	e.pop = 1.0
	_faiscas(l, 1.6, Tema.TUNGSTENIO)
	julgar(l, Ritmo.OTIMO)
	Forja.piscar(l, Color.WHITE, PISCA_PERFEITO_S)
	p.gesto("attack-melee-right", 0.45)
	_proxima(l, 1.5)


func _perdeu(l: int, _p: ForjaPlayer) -> void:
	var e: Dictionary = j[l]
	var r = _runa_atual(l)
	if r == null:
		return
	if r.tipo == "botao":
		_notas[l].erase(e.n)
	if not errou(l):
		_queda(l, r)
	_proxima(l, 1.5)


func _proxima(l: int, folga := 0.8) -> void:
	var e: Dictionary = j[l]
	var r = _runa_atual(l)
	if r != null and r.tipo == "gatilho" and r.alvo == 1:
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)
	var desde := maxf(float(e.b), Ritmo.batida() + folga) if r != null and r.tipo == "botao" else Ritmo.batida() + folga
	e.atual += 1
	if e.atual >= e.fila.size():
		e.volta += 1
		e.fila.append_array(_fila_da_volta(e.volta))
	e.t = 0.0
	e.setores = 0
	e.estagio = 0
	e.segurou = 0.0
	e.robo_passo = 0
	e.robo_reacao = -1.0
	Forja.med_pedido(l, -1)
	_armar(l, desde)


func terminar() -> void:
	for p in jogadores:
		Forja.gatilho(p.lugar, 1, Forja.GATILHO_OFF)
	super()


func robo(l: int, dt: float) -> void:
	if not Forja.robo:
		return
	var e: Dictionary = j[l]
	var r = _runa_atual(l)
	if r == null:
		return
	if r.tipo == "botao":
		var alvo := alvo_da(l, e.n)
		if alvo < 0.0 or e.robo_n == e.n:
			return
		if e.robo_passo != e.n:
			e.robo_passo = e.n
			e.robo_mira = (float(MIRA[l]) + float(Ritmo.desvio[l])) if Forja.robo_acerta() else 0.25
		if Ritmo.t_musica() + dt >= alvo + float(e.robo_mira):
			Forja.robo_apertar(l, r.alvo, 0.05)
			e.robo_n = e.n
		return
	if e.robo_reacao < 0.0:
		e.robo_reacao = 0.35 + 0.55 * rng.randf()
		if not Forja.robo_acerta():
			e.robo_reacao += JANELA_GATILHO + 1.0
	match str(r.tipo):
		"analogico":
			if e.t >= e.robo_reacao:
				e.robo_ang += dt * TAU / 1.4
				Forja.robo_eixo(l, Forja.RX if r.alvo == 1 else Forja.LX, cos(e.robo_ang), 0.06)
				Forja.robo_eixo(l, Forja.RY if r.alvo == 1 else Forja.LY, sin(e.robo_ang), 0.06)
		"gatilho":
			var alvo_g := 0.0 if e.t < e.robo_reacao else (0.48 if e.estagio == 0 else 1.0)
			var lido := Forja.eixo(l, Forja.R2 if r.alvo == 1 else Forja.L2)
			if e.estagio == 0 and e.t > e.robo_reacao + 1.2 and lido < 0.2 and fmod(e.t, 1.6) < 0.5:
				alvo_g = 1.0
			e.robo_gatilho = move_toward(e.robo_gatilho, alvo_g, dt * 4.0)
			Forja.robo_eixo(l, Forja.R2 if r.alvo == 1 else Forja.L2, e.robo_gatilho, 0.06)


const FORJA_ENERGIA := 0.9
const FORJA_TENSAO := 1.8
const FORJA_BATIDA := 0.6


func _forja_na_espera(l: int, tensao: float) -> void:
	var luz: OmniLight3D = runas[l].get("forja")
	if luz == null:
		return
	if tensao < 0.0:
		luz.light_energy = FORJA_ENERGIA
		return
	luz.light_energy = FORJA_ENERGIA + amplitude_da_espera() * (FORJA_TENSAO * tensao + FORJA_BATIDA * pulso_da_batida())
	_calor = maxf(_calor, tensao)


const CHAVE_CALOR := 0.8
const CHAVE_BATIDA := 0.25

var _calor := 0.0
var _chaves_base := {}


func _chaves_na_espera() -> void:
	if _chaves_base.is_empty():
		for luz in _chaves_com_energia:
			_chaves_base[luz] = luz.light_energy
	var k := 1.0 + amplitude_da_espera() * (CHAVE_CALOR * _calor + CHAVE_BATIDA * pulso_da_batida())
	for luz in _chaves_base:
		if is_instance_valid(luz):
			luz.light_energy = float(_chaves_base[luz]) * k


func combo(l: int) -> int:
	return int(j[l].combo) if j.has(l) else 0
