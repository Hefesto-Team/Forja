class_name SalaCaminhos
extends SalaJogo
## Os Caminhos — o chão que se sente na mão.
##
## O padrão é o da háptica dos jogos de PS5: o passo na grama não é o passo no
## metal, e a mão sabe antes do olho. Aqui cada um anda no escuro; a lanterna
## mostra só o boneco, e o chão fica por conta dos atuadores do controle — os
## canais 3 e 4 da placa de áudio do DualSense no cabo (ou o nó "Háptica do
## Controle N" que o Hefesto cria). A prova é às cegas:
##
##   - o treino: os quatro chãos, um de cada vez, com o nome e o chão à vista;
##   - depois, oito trechos no escuro: três passos e a pergunta "que chão é
##     esse?" (✕ grama, ○ cascalho, □ metal, △ água; o touchpad é "não
##     senti"); só depois da resposta o chão do trecho aparece;
##   - no meio do caminho, às vezes, uma pedra: o tropeço treme UM lado só, e
##     a pessoa diz qual (L1 esquerda, R1 direita). O boneco cambaleia para
##     os dois lados; a pedra só aparece depois da resposta.
##
## O "não senti" é resposta, e é a evidência: quem diz "não senti" o caminho
## inteiro mostra que a háptica não chega à mão. A TV fica calada sobre o
## chão: o passo só existe no controle.

const F := preload("res://scripts/forja.gd")
const RAIAS := [-6.0, -2.0, 2.0, 6.0]
const Z_JOGADOR := 1.6
const LADRILHO := 1.5  ## a fundura de um trecho do caminho
const RODADAS := 8
const PASSOS := 3
const TROPECOS := 4
const PRIMEIRO_S := 0.35
const PASSO_S := 0.9  ## entre um passo e outro: a cauda do metal (0,55 s) cabe
const TREINO_S := 2.1
const PERGUNTA_MAX := 6.0
const TROPECO_MAX := 2.5
const REVELA_S := 1.1
const ENV_MAX := 64
const CAMINHO_NADA := 4  ## "não senti" no chão (cegas.h)
const CAMINHO_NADA_LADO := 2  ## "não senti" no tropeço
const NOME_CHAO := ["grama", "cascalho", "metal", "água"]
const SENTE := ["um baque macio", "quatro estalos", "um golpe que ressoa", "duas ondas"]
const BOTAO_CHAO := [F.CRUZ, F.CIRCULO, F.QUADRADO, F.TRIANGULO]
const GLIFO_CHAO := ["cross", "circle", "square", "triangle"]
const COR_CHAO := [Color("#4f9a45"), Color("#9a8a70"), Color("#8c98aa"), Color("#3a7fd0")]

enum { TREINO, ANDA, PERGUNTA, REVELA, FIM }

var j := {}  ## lugar -> o estado do jogador
var n := {}  ## lugar -> os nós da raia
var _escuro: StandardMaterial3D


func _init() -> void:
	id = "caminhos"
	nome = "Os Caminhos"
	acao = "Sinta o chão na mão e diga qual é."
	objetivo = "No escuro, o chão só existe no controle: a grama é um baque macio, o cascalho são quatro estalos, o metal um golpe que ressoa, a água duas ondas. Primeiro o treino, com o chão à vista; depois, a cada três passos, diga o chão — ✕ grama, ○ cascalho, □ metal, △ água, o touchpad é \"não senti\". Se tropeçar numa pedra, diga o lado que tremeu: L1 esquerda, R1 direita. Confira a sua háptica aqui embaixo: △ dá um pulso na esquerda e outro na direita, ◀ ▶ troca."
	features = ["haptica_audio"]
	cega = true
	papel_som = F.PAPEL_HAPTICA
	botoes_pedidos = F.mascara([F.CRUZ, F.CIRCULO, F.QUADRADO, F.TRIANGULO, F.L1, F.R1, F.TOUCHPAD])
	duracao = 0.0
	camera_pos = Vector3(0, 7.2, 10.6)
	camera_olhar = Vector3(0, 0.4, -1.8)


func montar() -> void:
	Kit.arena(self, 5, 3)
	# quase breu: um enchimento frio e fraco; a luz de cada raia é a lanterna dele
	var frio := OmniLight3D.new()
	frio.position = Vector3(0, 9.0, 5.0)
	frio.light_color = Color("#50548a")
	frio.light_energy = 0.3
	frio.omni_range = 28.0
	add_child(frio)
	_escuro = Kit.material(Color("#17141f"), 0.0, 0.95)
	for p in jogadores:
		var l: int = p.lugar
		j[l] = _novo_jogador()
		n[l] = _montar_raia(l, p)
		Forja.gatilhos_off(l)


func _novo_jogador() -> Dictionary:
	var tl: Array = []
	var tp: Array = []
	for r in RODADAS:
		tl.append(-1)
		tp.append(0)
	return {"estado": TREINO, "t": 0.0, "treino": 0, "rodada": 0, "plano": [], "trop_lado": tl, "trop_passo": tp,
		"passos": 0, "trop_aberto": false, "trop_t": 0.0, "trop_agora": 0, "trop_disse": -1, "trop_msg": 0.0,
		"resp": -1, "chao": Cega.nova(), "le": Cega.nova(), "ld": Cega.nova(), "estereo": false, "certos": 0,
		"cambaleio": 0.0, "desloc": -0.5 * LADRILHO, "andando": 0.0,
		"env": [], "gravando": false, "silencio": 0, "soma_e": 0.0, "soma_d": 0.0, "votos": [0, 0, 0, 0],
		"robo_lado": -1, "robo_espera": -1.0, "robo_espera_trop": -1.0}


## Um trecho do caminho no chão que ele é (visto) ou no escuro.
func _vestir_ladrilho(lad: Dictionary, chao: int, visto: bool) -> void:
	var m: MeshInstance3D = lad.malha
	m.material_override = lad.mats[chao] if visto else _escuro
	for k in 4:
		var e: Node3D = lad.enfeites[k]
		e.visible = visto and k == chao
	lad.visto = visto


func _novo_ladrilho(pai: Node3D, z: float) -> Dictionary:
	var m := Kit.caixa(pai, Vector3(2.2, 0.08, LADRILHO - 0.08), Vector3(0, 0.04, z), _escuro)
	var mats: Array = []
	for k in 4:
		var mat := Kit.material(COR_CHAO[k], 0.25, 0.9 if k < 2 else 0.35)
		if k == 2:
			mat.metallic = 0.8
		if k == 3:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.85
			mat.emission_energy_multiplier = 0.5
		mats.append(mat)
	# o que dá para ver de cada chão quando ele aparece
	var enfeites: Array = []
	var grama := Node3D.new()
	pai.add_child(grama)
	for k in 9:
		var tufo := Kit.cilindro(grama, 0.035, 0.22, Vector3(-0.8 + 0.2 * k, 0.18, z + (0.25 if k % 2 == 0 else -0.3)),
			Kit.material(Color("#6fcf5a"), 0.2), 0.0)
		tufo.rotation.z = (k % 3 - 1) * 0.25
	enfeites.append(grama)
	var cascalho := Node3D.new()
	pai.add_child(cascalho)
	for k in 12:
		Kit.esfera(cascalho, 0.07 + 0.03 * (k % 3), Vector3(-0.9 + 0.16 * k, 0.1, z + 0.35 * sin(k * 2.3)),
			Kit.material(Color("#b8ab94").darkened(0.12 * (k % 3)), 0.0, 0.9))
	enfeites.append(cascalho)
	var metal := Node3D.new()
	pai.add_child(metal)
	for cx in [-0.9, 0.9]:
		for cz in [-0.5, 0.5]:
			Kit.esfera(metal, 0.06, Vector3(cx, 0.1, z + cz), Kit.material(Color("#d0d6e0"), 0.3, 0.3))
	enfeites.append(metal)
	var agua := Node3D.new()
	pai.add_child(agua)
	for k in 3:
		var onda := MeshInstance3D.new()
		var tor := TorusMesh.new()
		tor.inner_radius = 0.18 + 0.16 * k
		tor.outer_radius = tor.inner_radius + 0.03
		onda.mesh = tor
		onda.position = Vector3(0, 0.1, z)
		onda.scale = Vector3(1, 0.2, 1)
		onda.material_override = Kit.material(Color("#9fd4ff"), 1.0)
		agua.add_child(onda)
	enfeites.append(agua)
	for e in enfeites:
		e.visible = false
	return {"malha": m, "mats": mats, "enfeites": enfeites, "visto": false, "z": z}


func _montar_raia(l: int, p: ForjaPlayer) -> Dictionary:
	var x: float = RAIAS[l]
	# o caminho: os quatro trechos do treino e os oito da prova, um atrás do
	# outro; ele desliza para trás a cada passo (quem anda fica no lugar)
	var trilha := Node3D.new()
	trilha.position = Vector3(x, 0.0, Z_JOGADOR)
	add_child(trilha)
	var ladrilhos: Array = []
	for s in 4 + RODADAS:
		ladrilhos.append(_novo_ladrilho(trilha, -s * LADRILHO))
	# as bordas de pedra do caminho
	for lado in [-1.0, 1.0]:
		for s in range(0, 4 + RODADAS, 2):
			Kit.peca(trilha, "rocks", Vector3(lado * 1.3, 0.0, -s * LADRILHO), rng.randf() * TAU, 0.34 + 0.08 * (s % 3))
	# a pedra do tropeço, que só aparece depois da resposta
	var pedra_trop := Kit.peca(self, "rocks", Vector3(x, 0.0, Z_JOGADOR), 0.0, 0.9)
	pedra_trop.visible = false
	# a lanterna do boneco: só ele à vista
	var lanterna := OmniLight3D.new()
	lanterna.position = Vector3(x, 2.6, Z_JOGADOR + 0.6)
	lanterna.light_color = Forja.cor_do_lugar(l).lerp(Color.WHITE, 0.55)
	lanterna.light_energy = 1.3
	lanterna.omni_range = 2.8
	add_child(lanterna)
	# o nome do chão no treino, e o "!" do tropeço (sem lado)
	var placa := Label3D.new()
	placa.font = Tema.fonte(700)
	placa.font_size = 60
	placa.pixel_size = 0.005
	placa.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	placa.no_depth_test = true
	placa.outline_size = 14
	placa.outline_modulate = Color(Tema.CASA, 0.9)
	# nas raias da ponta, puxada para dentro: o nome inteiro na tela
	placa.position = Vector3(x * 0.84, 2.75, Z_JOGADOR - 0.4)
	placa.visible = false
	add_child(placa)
	var aviso := placa.duplicate() as Label3D
	aviso.text = "!"
	aviso.font_size = 150
	aviso.modulate = Tema.LARANJA
	aviso.position = Vector3(x * 0.9, 2.7, Z_JOGADOR)
	add_child(aviso)
	p.position = Vector3(x, 0.1, Z_JOGADOR)
	p.rotation.y = PI
	p.preso = true
	maos_livres(p)
	return {"trilha": trilha, "ladrilhos": ladrilhos, "pedra": pedra_trop, "placa": placa, "aviso": aviso,
		"lanterna": lanterna}


# ------------------------------------------------------------------ o jogo --

## Cada um tem o caminho dele, da mesma semente: os oito chãos (cada um duas
## vezes, sem repetir seguido) e os quatro tropeços (dois de cada lado, nunca
## no primeiro trecho nem no último passo). Sem háptica estéreo, não há lado a
## perguntar: o caminho fica sem pedras.
func iniciar_jogo() -> void:
	for p in jogadores:
		var l: int = p.lugar
		if not jogando[l]:
			continue
		var e: Dictionary = j[l]
		e.plano = Array(Forja.cega_plano_fontes([0, 1, 2, 3], [2, 2, 2, 2], rng.randi()))
		e.estereo = Forja.som_estereo(l, F.PAPEL_HAPTICA)
		if e.estereo:
			var trechos := Array(Forja.cega_plano_fontes([1, 2, 3, 4, 5, 6, 7], [1, 1, 1, 1, 1, 1, 1], rng.randi()))
			var lados := Array(Forja.cega_plano_fontes([0, 1], [TROPECOS / 2, TROPECOS / 2], rng.randi()))
			for k in mini(TROPECOS, mini(trechos.size(), lados.size())):
				e.trop_lado[trechos[k]] = lados[k]
				e.trop_passo[trechos[k]] = rng.randi_range(0, PASSOS - 2)
		# o treino: os quatro chãos à vista, na ordem
		var ladrilhos: Array = n[l].ladrilhos
		for s in 4:
			_vestir_ladrilho(ladrilhos[s], s, true)
		e.estado = TREINO
		e.t = 0.0


func _conectado(l: int) -> bool:
	return Forja.lugar(l).get("conectado", false)


func _tocar_passo(l: int, chao: int, variacao: int) -> void:
	var som := "passo:%d:%d" % [chao, variacao % 3]
	Forja.som_haptica(l, som, som)
	j[l].andando = 0.45


func _comecar_trecho(e: Dictionary) -> void:
	e.estado = ANDA
	e.t = 0.0
	e.passos = 0
	e.resp = -1
	e.votos = [0, 0, 0, 0]
	e.robo_espera = -1.0


func _fechar_tropeco(l: int, e: Dictionary, disse: int) -> void:
	var c: Dictionary = e.le if int(e.trop_agora) == 0 else e.ld
	var res := ""
	if disse == int(e.trop_agora):
		Cega.certo(c)
		marcar(l, 100)
		res = "certo"
	elif disse >= 0:
		Cega.errado(c, disse)
		res = "não senti" if disse == CAMINHO_NADA_LADO else "errado"
	else:
		Cega.perdido(c)
		res = "perdido"
	e.trop_aberto = false
	e.trop_disse = disse
	e.trop_msg = 1.3
	# agora a pedra aparece, do lado em que estava
	var pedra: Node3D = n[l].pedra
	pedra.position = Vector3(RAIAS[l] + (-0.75 if int(e.trop_agora) == 0 else 0.75), 0.0, Z_JOGADOR - 0.2)
	pedra.visible = true
	Forja.evento("jogo", l + 1, {"sala": id, "o": "tropeço", "lado": "direita" if int(e.trop_agora) == 1 else "esquerda",
		"resultado": res})


func _fechar_pergunta(l: int, e: Dictionary) -> void:
	var r: int = e.rodada
	var certo: int = e.plano[r]
	var res := ""
	var p := jogador(l)
	if e.resp == certo:
		Cega.certo(e.chao)
		e.certos = int(e.certos) + 1
		marcar(l, 100)
		Som.tocar("confirma", p.global_position + Vector3(0, 1, 0), -8.0)
		res = "certo"
	elif e.resp >= 0:
		Cega.errado(e.chao, e.resp)
		Som.tocar("falha", p.global_position + Vector3(0, 1, 0), -10.0)
		res = "não senti" if e.resp == CAMINHO_NADA else "errado"
	else:
		Cega.perdido(e.chao)
		res = "perdido"
	# o chão do trecho aparece
	_vestir_ladrilho(n[l].ladrilhos[4 + r], certo, true)
	e.estado = REVELA
	e.t = 0.0
	Forja.evento("jogo", l + 1, {"sala": id, "o": "resposta", "chão": NOME_CHAO[certo], "resultado": res})


func jogar(dt: float) -> void:
	for p in jogadores:
		var l: int = p.lugar
		if not jogando[l] or not _conectado(l):
			continue
		var e: Dictionary = j[l]
		if Forja.robo:
			_robo(l, e, dt)
		_atualizar_jogador(l, e, dt)


func _atualizar_jogador(l: int, e: Dictionary, dt: float) -> void:
	e.t = float(e.t) + dt
	e.trop_msg = maxf(0.0, float(e.trop_msg) - dt)
	if e.trop_aberto:
		e.trop_t = float(e.trop_t) + dt
		var disse := -1
		if Forja.apertou(l, F.L1):
			disse = 0
		elif Forja.apertou(l, F.R1):
			disse = 1
		elif Forja.apertou(l, F.TOUCHPAD):
			disse = CAMINHO_NADA_LADO
		if disse >= 0 or float(e.trop_t) >= TROPECO_MAX:
			_fechar_tropeco(l, e, disse)
	match int(e.estado):
		TREINO:
			if int(e.passos) < 2 and float(e.t) >= PRIMEIRO_S + int(e.passos) * PASSO_S:
				_tocar_passo(l, int(e.treino), int(e.passos))
				e.passos = int(e.passos) + 1
			if float(e.t) >= TREINO_S:
				e.treino = int(e.treino) + 1
				e.passos = 0
				e.t = 0.0
				if int(e.treino) >= 4:
					_comecar_trecho(e)
		ANDA:
			var r: int = e.rodada
			if int(e.passos) < PASSOS and float(e.t) >= PRIMEIRO_S + int(e.passos) * PASSO_S:
				if int(e.trop_lado[r]) >= 0 and int(e.passos) == int(e.trop_passo[r]):
					var lado: int = e.trop_lado[r]
					Forja.som_haptica(l, "tropeco" if lado == 0 else "", "tropeco" if lado == 1 else "")
					e.trop_aberto = true
					e.trop_t = 0.0
					e.trop_agora = lado
					e.trop_disse = -1
					e.cambaleio = 1.0
					e.robo_lado = -1
					e.robo_espera_trop = -1.0
					n[l].pedra.visible = false
				else:
					_tocar_passo(l, int(e.plano[r]), int(e.passos) + r)
				e.passos = int(e.passos) + 1
			if int(e.passos) >= PASSOS and not e.trop_aberto and float(e.t) >= PRIMEIRO_S + (PASSOS - 1) * PASSO_S + 0.7:
				e.estado = PERGUNTA
				e.t = 0.0
		PERGUNTA:
			if e.resp < 0 and float(e.t) > 0.25:
				for c in 4:
					if Forja.apertou(l, BOTAO_CHAO[c]):
						e.resp = c
						break
				if e.resp < 0 and Forja.apertou(l, F.TOUCHPAD):
					e.resp = CAMINHO_NADA
			if e.resp >= 0 or float(e.t) >= PERGUNTA_MAX:
				_fechar_pergunta(l, e)
		REVELA:
			if float(e.t) >= REVELA_S:
				e.rodada = int(e.rodada) + 1
				n[l].pedra.visible = false
				if int(e.rodada) >= RODADAS:
					e.estado = FIM
					acabou[l] = true
					var p := jogador(l)
					if p:
						p.gesto("emote-yes", 0.9)
				else:
					_comecar_trecho(e)


func dar_vereditos(l: int) -> Array:
	var e: Dictionary = j[l]
	if e.trop_aberto:
		_fechar_tropeco(l, e, -1)
	var tem := Forja.som_tem(l, F.PAPEL_HAPTICA)
	var v := Forja.cega_veredito(l, "haptica_audio", {"cega": e.chao, "esq": e.le, "dir": e.ld, "tem": tem})
	if v.is_empty():
		return []
	if tem and not e.estereo and int(v.get("resultado", 0)) != F.NAO_MEDIDO:
		var obs := str(v.get("obs", ""))
		v.obs = obs + ("; " if obs != "" else "") + "a háptica achada tem um canal só: o lado do tropeço não foi perguntado"
	return [v]


# ------------------------------------------------------------------ o que se vê --

func _process(dt: float) -> void:
	super(dt)
	for p in jogadores:
		_mostrar(p, dt)


func _mostrar(p: ForjaPlayer, dt: float) -> void:
	var l: int = p.lugar
	var e: Dictionary = j[l]
	var nos: Dictionary = n[l]
	# o caminho desliza: um trecho por rodada, um terço dele por passo
	var seg := int(e.treino) if int(e.estado) == TREINO else 4 + mini(int(e.rodada), RODADAS - 1)
	var por := 2.0 if int(e.estado) == TREINO else float(PASSOS)
	var passos := int(e.passos)
	if int(e.estado) == PERGUNTA or int(e.estado) == REVELA:
		passos = PASSOS
	elif int(e.estado) == FIM:
		seg = 4 + RODADAS
		passos = 0
	var alvo := (seg - 0.5 + passos / por) * LADRILHO
	e.desloc = move_toward(float(e.desloc), alvo, dt * LADRILHO * 1.6)
	var trilha: Node3D = nos.trilha
	trilha.position.z = Z_JOGADOR + float(e.desloc)
	# o boneco anda enquanto o passo soa, e cambaleia para os dois lados no
	# tropeço (o lado é da mão, não da tela)
	e.andando = maxf(0.0, float(e.andando) - dt)
	e.cambaleio = move_toward(float(e.cambaleio), 0.0, dt * 2.0)
	if fase == "jogo" and float(e.andando) > 0.0:
		p.animar("walk", 1.1)
	else:
		p.animar("idle")
	if p.modelo:
		p.modelo.rotation.z = sin(t * 26.0) * 0.16 * float(e.cambaleio)
	# o nome do chão no treino; o "!" no tropeço
	var placa: Label3D = nos.placa
	placa.visible = fase == "jogo" and int(e.estado) == TREINO
	if placa.visible:
		placa.text = Traducoes.traduzir(NOME_CHAO[int(e.treino)])
		placa.modulate = COR_CHAO[int(e.treino)].lightened(0.35)
	var aviso: Label3D = nos.aviso
	aviso.visible = e.trop_aberto
	aviso.scale = Vector3.ONE * (1.0 + 0.1 * sin(t * 16.0))
	# a água respira
	for lad in nos.ladrilhos:
		var ond: Node3D = lad.enfeites[3]
		if ond.visible:
			ond.scale = Vector3.ONE * (1.0 + 0.06 * sin(t * 3.0 + float(lad.z)))


# ------------------------------------------------------------------ a HUD --

func status(lugar: int) -> String:
	if fase == "jogo" and j.has(lugar):
		var e: Dictionary = j[lugar]
		if int(e.estado) == TREINO:
			return "treino · %s" % NOME_CHAO[mini(int(e.treino), 3)]
		if int(e.estado) == FIM:
			return "chegou · %d ✓" % int(e.certos)
		return "trecho %d de %d · %d ✓" % [mini(int(e.rodada) + 1, RODADAS), RODADAS, int(e.certos)]
	return super(lugar)


func dica(lugar: int) -> Dictionary:
	if not j.has(lugar) or fase != "jogo":
		return {}
	var e: Dictionary = j[lugar]
	var pos := Vector3(RAIAS[lugar], 0.0, 4.6)
	if e.trop_aberto:
		return {"partes": ["tropeçou!", "@l1", "esquerda", "@r1", "direita"], "pos": pos}
	if float(e.trop_msg) > 0.0:
		var lado := "esquerda" if int(e.trop_agora) == 0 else "direita"
		var disse: int = e.trop_disse
		if disse == int(e.trop_agora):
			return {"partes": ["isso: a pedra era da %s" % lado], "pos": pos}
		return {"partes": ["a pedra era da %s" % lado], "pos": pos}
	match int(e.estado):
		TREINO:
			return {"partes": ["treino: sinta %s" % SENTE[mini(int(e.treino), 3)]], "pos": pos}
		ANDA:
			return {"partes": ["ande e sinta o chão"], "pos": pos}
		FIM:
			return {"partes": ["chegou"], "pos": pos}
	return {}


func pergunta(lugar: int) -> Dictionary:
	if not j.has(lugar) or fase != "jogo":
		return {}
	var e: Dictionary = j[lugar]
	if not (int(e.estado) == PERGUNTA or int(e.estado) == REVELA) or e.trop_aberto or float(e.trop_msg) > 0.0:
		return {}
	var opcoes: Array = []
	for c in 4:
		opcoes.append([GLIFO_CHAO[c], COR_CHAO[c], NOME_CHAO[c]])
	opcoes.append(["touchpad", null, "não senti"])
	var escolhida: int = e.resp
	var certa := -1
	var rodape := ""
	if int(e.estado) == REVELA:
		var c2: int = e.plano[int(e.rodada)]
		certa = c2
		if e.resp < 0:
			rodape = "sem resposta — era %s" % NOME_CHAO[c2]
		elif e.resp == c2:
			rodape = "isso: %s" % SENTE[c2]
		else:
			rodape = "era %s (%s)" % [NOME_CHAO[c2], SENTE[c2]]
	return {"titulo": "Que chão é esse?", "opcoes": opcoes, "escolhida": escolhida, "certa": certa,
		"rodape": rodape, "pos": Vector3(RAIAS[lugar], 0.0, 4.0)}


# ------------------------------------------------------------------ o robô --
# Sente os atuadores do controle dele (a placa virtual): o envelope de cada
# toque, desde que o nível sobe até 0,2 s de silêncio. Dos dois lados por
# igual é um passo, e o envelope diz o chão (chao.c); de um lado só é o
# tropeço, e o lado mais forte é o da pedra.

func _robo_sentir(l: int, e: Dictionary) -> void:
	var v := Forja.som_virtual(l)
	var esq := float(v.get("esq", 0.0))
	var dir := float(v.get("dir", 0.0))
	var nivel := maxf(esq, dir)
	var env: Array = e.env
	if not e.gravando and nivel > 0.05:
		e.gravando = true
		env.clear()
		env.append(0.0)
		env.append(0.0)
		e.soma_e = 0.0
		e.soma_d = 0.0
		e.silencio = 0
	if not e.gravando:
		return
	if env.size() < ENV_MAX:
		env.append(nivel)
	e.soma_e = float(e.soma_e) + esq
	e.soma_d = float(e.soma_d) + dir
	e.silencio = int(e.silencio) + 1 if nivel < 0.02 else 0
	# 0,2 s de silêncio fecham o toque: a água tem um vão de 0,1 s entre as
	# duas ondas, que não pode partir um passo em dois
	if int(e.silencio) < 12 and env.size() < ENV_MAX:
		return
	e.gravando = false
	var mx := maxf(float(e.soma_e), float(e.soma_d))
	var mn := minf(float(e.soma_e), float(e.soma_d))
	if mx <= 0.0:
		return
	if mn < 0.3 * mx:
		e.robo_lado = 0 if float(e.soma_e) > float(e.soma_d) else 1
	else:
		var c := Forja.chao_do_envelope(PackedFloat32Array(env))
		if c >= 0 and c < 4:
			e.votos[c] = int(e.votos[c]) + 1


func _robo(l: int, e: Dictionary, dt: float) -> void:
	_robo_sentir(l, e)
	if e.trop_aberto:
		if float(e.robo_espera_trop) < 0.0:
			e.robo_espera_trop = 0.55 + 0.4 * rng.randf()
		e.robo_espera_trop = float(e.robo_espera_trop) - dt
		if float(e.robo_espera_trop) <= 0.0:
			var lado: int = e.robo_lado
			Forja.robo_apertar(l, F.L1 if lado == 0 else (F.R1 if lado == 1 else F.TOUCHPAD), 0.08)
			e.robo_espera_trop = 99.0
	if int(e.estado) == PERGUNTA and e.resp < 0:
		if float(e.robo_espera) < 0.0:
			e.robo_espera = 0.5 + 0.6 * rng.randf()
		e.robo_espera = float(e.robo_espera) - dt
		if float(e.robo_espera) <= 0.0:
			var melhor := -1
			var mv := 0
			for c in 4:
				if int(e.votos[c]) > mv:
					mv = int(e.votos[c])
					melhor = c
			Forja.robo_apertar(l, BOTAO_CHAO[melhor] if melhor >= 0 else F.TOUCHPAD, 0.08)
			e.robo_espera = 99.0
