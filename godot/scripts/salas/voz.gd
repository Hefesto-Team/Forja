class_name SalaVoz
extends SalaJogo
## A Voz — a voz, o silêncio e o susto.
##
## O padrão é o dos jogos de terror que escutam quem joga: o guardião que ouve
## pelo microfone do controle, o botão de mudo que salva, a luz laranja que diz
## que o microfone está fechado — e o susto que sai da mão: a vibração forte e
## o grito no alto-falante do controle, enquanto a TV bate. A sala mede:
##
##   - o microfone: o silêncio de todos (o piso) e a voz de cada um, na vez
##     dele, chamando o guardião — a chama do braseiro sobe com a voz;
##   - o mudo: o botão do microfone (MISC1 no SDL) e, falando baixinho já
##     mudo, se o sistema também cortou o som ou se o mudo ficou com o jogo;
##   - o LED do microfone, às cegas: o jogo apaga, acende ou faz piscar a luz,
##     a tela não mostra, e a pessoa diz como está.
##
## O som do ar é de todos: quando um fala, os microfones dos outros também
## ouvem. Por isso a voz é medida em turnos, e o silêncio de todos junto. O
## microfone de cada um é o do próprio controle, achado como um jogo acha.

const F := preload("res://scripts/forja.gd")
const RAIAS := [-6.0, -2.0, 2.0, 6.0]
const Z_JOGADOR := 1.5
const SILENCIO_S := 4.0
const CHAMADO_MAX := 5.0
const MUDO_MAX := 8.0
const SUSSURRO_S := 3.0
const LUZ_ESPERA := 1.0  ## a luz muda e a pessoa olha, antes de valer a resposta
const LUZ_MAX := 7.0
const LUZ_REVELA := 0.8
const LUZ_RODADAS := 5
const ESPERA_S := 2.2
const SUSTO_S := 1.9
const VOZ_ACIMA := 0.25 + 0.05  ## a voz acima do silêncio (MED_VOZ_ACIMA, com folga)
const NOME_LUZ := ["apagada", "acesa", "piscando"]
const BOTAO_LUZ := [F.CRUZ, F.CIRCULO, F.QUADRADO]
const GLIFO_LUZ := ["cross", "circle", "square"]
const GUARDIAO := Vector3(0.0, 3.05, -4.35)

enum { SILENCIO, CHAMADO, MUDO, SUSSURRO, LUZ, ESPERA, SUSTO, ACABOU }
enum { OLHAR, REVELA_LUZ, FIM_LUZ }

var estado := SILENCIO
var t_estado := 0.0
var _luz_do_susto := false  ## o vermelho do susto ainda está aceso (a cor do lugar volta aos 0,4 s)
var vez := -1  ## no chamado: o lugar que fala
var ordem: Array = []  ## os lugares, na ordem do chamado
var i_vez := 0
var olhos := 0.0  ## 0 fechados .. 1 abertos e acesos
var grito := 0.0  ## a boca do guardião, no susto
var flash := 0.0
var j := {}  ## lugar -> o estado do jogador
var n := {}  ## lugar -> os nós da raia
var g := {}  ## os nós do guardião


func _init() -> void:
	id = "voz"
	nome = "A Voz"
	acao = "Chame o guardião e fique mudo."
	icone = "mic"
	objetivo = "O guardião da cripta escuta pelo microfone do controle. Primeiro, todos em silêncio. Depois, cada um na sua vez chama o guardião falando alto — os outros, quietos. Quando ele acordar, fiquem mudos com o botão do microfone; e digam, olhando o controle, como está a luz dele: ✕ apagada, ○ acesa, □ piscando. Confira o seu microfone aqui embaixo: fale e a barra sobe; ◀ ▶ troca."
	features = ["microfone", "microfone_mudo", "led_microfone"]
	cega = true
	# Sem o Modo bancada não há a luz para dizer: o chamado e o mudo são uma vez
	# só por pessoa, nunca os três acertos do treino. Com treino, eles cairiam
	# nele e não somariam — a sala acabaria sempre em zero a zero.
	com_treino = Forja.bancada
	papel_som = F.PAPEL_MICROFONE
	botoes_pedidos = F.mascara([F.MICROFONE, F.CRUZ, F.CIRCULO, F.QUADRADO])
	duracao = 0.0
	camera_pos = Vector3(0, 5.4, 10.8)
	camera_olhar = Vector3(0, 1.7, -1.2)


func montar() -> void:
	Kit.arena(self, 5, 3)
	# a cripta: brasas frias, fantasmas, e o neon verde
	atmosfera(Color("#7fe8ff"), Tema.VERDE, true, 40, 22.0, -7.8, 0.15)
	var frio := OmniLight3D.new()
	frio.position = Vector3(0, 8.0, 4.0)
	frio.light_color = Color("#5a4f8f")
	frio.light_energy = 0.35
	frio.omni_range = 26.0
	add_child(frio)
	# as velas do fundo
	for x in [-8.5, -5.0, 5.0, 8.5]:
		var base := Vector3(x, 0.0, -4.6)
		Kit.cilindro(self, 0.1, 0.5, base + Vector3(0, 0.25, 0), Kit.material(Color("#e8dcc0"), 0.0, 0.9))
		Kit.esfera(self, 0.07, base + Vector3(0, 0.58, 0), Kit.material(Color("#ffb050"), 3.0))
		var vela := OmniLight3D.new()
		vela.position = base + Vector3(0, 0.8, 0.3)
		vela.light_color = Color("#ff9a40")
		vela.light_energy = 0.9
		vela.omni_range = 4.0
		add_child(vela)
	g = _montar_guardiao()
	for p in jogadores:
		var l: int = p.lugar
		j[l] = _novo_jogador()
		n[l] = _montar_raia(l, p)
		Forja.gatilhos_off(l)


func _novo_jogador() -> Dictionary:
	return {"tem": false, "piso": 0.0, "viu_piso": false, "soma_piso": 0.0, "n_piso": 0, "voz": 0.0, "mudo_nivel": 0.0,
		"viu_mudo": false, "apertou_mudo": false, "pediu_mudo": false, "quadros_ini": 0, "mexeu": false,
		"chamou": false, "acima_t": 0.0, "mudo": false, "luz": Cega.nova(), "luz_ok": false, "plano": [],
		"rodada": 0, "modo": 0, "resp": -1, "fase": OLHAR, "t": 0.0, "chama": 0.0,
		"robo_espera": -1.0, "robo_falou": false}


## O guardião: a máscara de bronze na parede do fundo. Os olhos abrem e
## acendem com as vozes; a boca abre, com os dentes, no susto.
func _montar_guardiao() -> Dictionary:
	var pivo := Node3D.new()
	pivo.position = GUARDIAO
	pivo.scale = Vector3.ONE * 0.86
	add_child(pivo)
	var bronze := Kit.material(Color("#6a4a2c"), 0.0, 0.5)
	bronze.metallic = 0.6
	var rosto := Kit.esfera(pivo, 1.0, Vector3.ZERO, bronze)
	rosto.scale = Vector3(1.55, 1.95, 0.55)
	var escuro := Kit.material(Color("#2a1a10"), 0.0, 0.8)
	# a testa franzida e o nariz
	for lado in [-1.0, 1.0]:
		var sob := Kit.caixa(pivo, Vector3(0.75, 0.13, 0.2), Vector3(lado * 0.45, 0.55, 0.5), escuro)
		sob.rotation.z = lado * -0.32
	var nariz := Kit.caixa(pivo, Vector3(0.22, 0.6, 0.3), Vector3(0, 0.05, 0.52), bronze)
	nariz.rotation.x = -0.25
	# os olhos, com a pálpebra de bronze por cima
	var olhos_n: Array = []
	var palpebras: Array = []
	var mat_olho := Kit.material(Color("#ff3a1a"), 0.0)
	mat_olho.emission_enabled = true
	mat_olho.emission = Color("#ff3a1a")
	mat_olho.emission_energy_multiplier = 0.0
	for lado in [-1.0, 1.0]:
		var o := Kit.esfera(pivo, 0.2, Vector3(lado * 0.48, 0.28, 0.42), mat_olho)
		olhos_n.append(o)
		var pa := Kit.caixa(pivo, Vector3(0.5, 0.44, 0.12), Vector3(lado * 0.48, 0.28, 0.56), bronze)
		palpebras.append(pa)
	# a boca e os dentes
	var boca := Node3D.new()
	boca.position = Vector3(0, -0.78, 0.42)
	pivo.add_child(boca)
	var fundo := Kit.caixa(boca, Vector3(0.9, 1.0, 0.1), Vector3.ZERO, Kit.material(Color("#120806"), 0.0, 1.0))
	var dentes := Node3D.new()
	boca.add_child(dentes)
	var osso := Kit.material(Color("#e8dcc8"), 0.0, 0.7)
	for k in 5:
		Kit.caixa(dentes, Vector3(0.12, 0.16, 0.06), Vector3(-0.3 + 0.15 * k, 0.4, 0.06), osso)
		Kit.caixa(dentes, Vector3(0.12, 0.16, 0.06), Vector3(-0.3 + 0.15 * k, -0.4, 0.06), osso)
	boca.scale = Vector3(1, 0.12, 1)
	var brilho := OmniLight3D.new()
	brilho.position = GUARDIAO + Vector3(0, 0.2, 1.6)
	brilho.light_color = Color("#ff4020")
	brilho.light_energy = 0.0
	brilho.omni_range = 7.0
	add_child(brilho)
	var foco := SpotLight3D.new()
	foco.position = GUARDIAO + Vector3(0, 3.0, 3.0)
	foco.look_at_from_position(foco.position, GUARDIAO)
	foco.light_color = Color("#b0a0ff")
	foco.light_energy = 1.4
	foco.spot_range = 8.0
	foco.spot_angle = 30.0
	add_child(foco)
	return {"pivo": pivo, "mat_olho": mat_olho, "palpebras": palpebras, "boca": boca, "dentes": dentes,
		"brilho": brilho, "fundo": fundo}


func _montar_raia(l: int, p: ForjaPlayer) -> Dictionary:
	var x: float = RAIAS[l]
	# o chão da raia: a laje de pedra com a borda na cor do lugar
	Kit.cilindro(self, 1.4, 0.06, Vector3(x, 0.03, Z_JOGADOR), Kit.material(Color("#211b2b"), 0.0, 0.95))
	var borda := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 1.35
	tor.outer_radius = 1.45
	tor.rings = 48
	borda.mesh = tor
	borda.position = Vector3(x, 0.07, Z_JOGADOR)
	borda.scale = Vector3(1, 0.35, 1)
	var cor_l := Forja.cor_do_lugar(l)
	var mat_borda := Kit.material(cor_l.darkened(0.5), 0.0, 0.7)
	mat_borda.emission_enabled = true
	mat_borda.emission = cor_l
	mat_borda.emission_energy_multiplier = 0.1
	borda.material_override = mat_borda
	add_child(borda)
	# o braseiro da voz, à frente do boneco: a chama sobe com o que o microfone
	# ouve (e apaga no mudo)
	var bras := Vector3(x, 0.0, Z_JOGADOR - 1.05)
	var pedra := Kit.material(Color("#4a4452"), 0.0, 0.9)
	Kit.cilindro(self, 0.18, 0.55, bras + Vector3(0, 0.27, 0), pedra)
	Kit.cilindro(self, 0.28, 0.22, bras + Vector3(0, 0.62, 0), pedra, 0.42)
	var mat_chama := Kit.material(Color("#ff8a2a"), 0.0)
	mat_chama.emission_enabled = true
	mat_chama.emission = Color("#ff7a1a")
	mat_chama.emission_energy_multiplier = 2.5
	var chama := Kit.cilindro(self, 0.24, 1.0, bras + Vector3(0, 1.2, 0), mat_chama, 0.0)
	var brasa := Kit.esfera(self, 0.2, bras + Vector3(0, 0.75, 0), Kit.material(Color("#ff5a1a"), 1.2))
	var luz := OmniLight3D.new()
	luz.position = bras + Vector3(0, 1.3, 0.3)
	luz.light_color = Color("#ff9a40")
	luz.light_energy = 0.4
	luz.omni_range = 3.2
	add_child(luz)
	# o foco de quem tem a vez de chamar
	var foco := SpotLight3D.new()
	foco.position = Vector3(x, 5.5, Z_JOGADOR + 1.6)
	foco.look_at_from_position(foco.position, Vector3(x, 0.8, Z_JOGADOR))
	foco.light_color = cor_l.lerp(Color.WHITE, 0.5)
	foco.light_energy = 0.0
	foco.spot_range = 8.0
	foco.spot_angle = 22.0
	add_child(foco)
	p.position = Vector3(x, 0.08, Z_JOGADOR)
	p.rotation.y = PI
	p.preso = true
	maos_livres(p)
	return {"mat_borda": mat_borda, "chama": chama, "brasa": brasa, "luz": luz, "foco": foco, "bras": bras}


# ------------------------------------------------------------------ o jogo --

func iniciar_jogo() -> void:
	ordem.clear()
	for p in jogadores:
		var l: int = p.lugar
		if not jogando[l]:
			continue
		var e: Dictionary = j[l]
		e.tem = Forja.som_tem(l, F.PAPEL_MICROFONE)
		e.quadros_ini = int(Forja.som_mic(l).get("quadros", 0))
		e.plano = Array(Forja.cega_plano_fontes([0, 1, 2], [2, 2, 1], rng.randi()))
		Forja.led_mic(l, 0)
		ordem.append(l)
	estado = SILENCIO
	t_estado = 0.0


## No silêncio, nem o ambiente chegou: o microfone está mudo no sistema. A
## sala segue sem a voz dele (a vez passa) e o veredito fica "não medido".
func _mudo_no_sistema(e: Dictionary) -> bool:
	return e.tem and e.viu_piso and float(e.piso) <= 0.001


func _conectado(l: int) -> bool:
	return Forja.lugar(l).get("conectado", false)


## A próxima vez no chamado, pulando quem não tem controle ou microfone.
func _proxima_vez() -> int:
	while i_vez < ordem.size():
		var l: int = ordem[i_vez]
		if _conectado(l) and j[l].tem and not _mudo_no_sistema(j[l]):
			return l
		i_vez += 1
	return -1


func _luz_rodada(l: int, e: Dictionary) -> void:
	var r: int = e.rodada
	e.modo = int(e.plano[r]) if r < e.plano.size() else 0
	e.resp = -1
	e.t = 0.0
	e.fase = OLHAR
	e.robo_espera = -1.0
	var ok := Forja.led_mic(l, int(e.modo))
	if ok:
		e.luz_ok = true
		Forja.evento("jogo", l + 1, {"sala": id, "o": "pergunta", "qual": "luz_mic"})
	else:
		e.fase = FIM_LUZ  # o que o SDL não manda não se pergunta


func _comecar_luz() -> void:
	estado = LUZ
	t_estado = 0.0
	for l in j:
		if not jogando[l] or not _conectado(l):
			continue
		var e: Dictionary = j[l]
		e.rodada = 0
		e.mudo = false
		_luz_rodada(l, e)


func _susto() -> void:
	for p in jogadores:
		var l: int = p.lugar
		if not jogando[l] or not _conectado(l):
			continue
		Forja.sentir(l, "explosao", 700)
		Forja.luz(l, Color(1.0, 0.08, 0.04))
		_luz_do_susto = true
		Forja.som_falante(l, "grito", 1.0)
		p.gesto("emote-no", 1.2)
	Som.tocar("grito", GUARDIAO, 0.0)
	Som.tocar("martelo", GUARDIAO, 2.0)
	# o clarão do susto; com os flashes desligados nas opções, só um brilho
	flash = 1.0 if Opcoes.flashes else 0.2
	Forja.evento("jogo", 0, {"sala": id, "o": "susto"})


func _medir(dt: float) -> void:
	for l in j:
		if not jogando[l]:
			continue
		var e: Dictionary = j[l]
		var nivel := float(Forja.som_mic(l).get("nivel", 0.0))
		e.chama = lerpf(float(e.chama), 0.0 if e.mudo else nivel, minf(1.0, dt * 8.0))
		if not e.tem:
			continue
		match estado:
			SILENCIO:
				if t_estado >= 1.0:  # o primeiro segundo é de quem ainda está calando
					e.soma_piso = float(e.soma_piso) + nivel
					e.n_piso = int(e.n_piso) + 1
					e.piso = float(e.soma_piso) / float(e.n_piso)
					e.viu_piso = true
			CHAMADO:
				if vez == l:
					e.voz = maxf(float(e.voz), nivel)
					if nivel - float(e.piso) >= VOZ_ACIMA:
						e.acima_t = float(e.acima_t) + dt
			SUSSURRO:
				if e.mudo:
					e.mudo_nivel = maxf(float(e.mudo_nivel), nivel)
					e.viu_mudo = true


func _atualizar_luz(l: int, e: Dictionary, dt: float) -> void:
	e.t = float(e.t) + dt
	if int(e.fase) == OLHAR:
		if float(e.t) >= LUZ_ESPERA and e.resp < 0:
			for k in 3:
				if Forja.apertou(l, BOTAO_LUZ[k]):
					e.resp = k
					e.mexeu = true
					Som.tocar("tique", jogador(l).global_position + Vector3(0, 1, 0), -6.0)
					break
		if e.resp >= 0 or float(e.t) >= LUZ_ESPERA + LUZ_MAX:
			var res := ""
			if e.resp == e.modo:
				Cega.certo(e.luz)
				marcar(l, 100)
				res = "certo"
			elif e.resp >= 0:
				Cega.errado(e.luz, e.resp)
				res = "errado"
			else:
				Cega.perdido(e.luz)
				res = "perdido"
			Forja.evento("jogo", l + 1, {"sala": id, "o": "luz", "resultado": "%s (era %s)" % [res, NOME_LUZ[int(e.modo)]]})
			e.fase = REVELA_LUZ
			e.t = 0.0
	elif int(e.fase) == REVELA_LUZ and float(e.t) >= LUZ_REVELA:
		e.rodada = int(e.rodada) + 1
		if Forja.cega_decidida("led_mic", e.luz) or int(e.rodada) >= LUZ_RODADAS:
			e.fase = FIM_LUZ
			Forja.led_mic(l, 0)
		else:
			_luz_rodada(l, e)


func jogar(dt: float) -> void:
	if Forja.robo:
		for p in jogadores:
			if jogando[p.lugar] and _conectado(p.lugar):
				_robo(p.lugar, j[p.lugar], dt)
	t_estado += dt
	_medir(dt)
	match estado:
		SILENCIO:
			if t_estado >= SILENCIO_S:
				for l in j:
					if jogando[l] and j[l].viu_piso:
						Forja.evento("jogo", l + 1, {"sala": id, "o": "silêncio", "piso": snappedf(float(j[l].piso), 0.01)})
				for l in j:
					if jogando[l] and _mudo_no_sistema(j[l]):
						Forja.registrar("A Voz: o microfone do P%d está mudo no sistema; a vez dele passa" % (l + 1))
						Forja.evento("jogo", l + 1, {"sala": id, "o": "mudo no sistema"})
				estado = CHAMADO
				t_estado = 0.0
				i_vez = 0
				vez = _proxima_vez()
				if vez < 0:
					_ir_para_o_mudo()
		CHAMADO:
			var e: Dictionary = j[vez]
			if not e.chamou and float(e.acima_t) >= 0.5:
				e.chamou = true
				Som.tocar("bigorna", GUARDIAO, -4.0)
				marcar(vez, 150)
				t_estado = maxf(t_estado, CHAMADO_MAX - 0.8)  # ainda um instante de chama acesa
			if t_estado >= CHAMADO_MAX or not _conectado(vez):
				Forja.evento("jogo", vez + 1, {"sala": id, "o": "chamado", "voz": snappedf(float(e.voz), 0.01)})
				t_estado = 0.0
				i_vez += 1
				vez = _proxima_vez()
				if vez < 0:
					_ir_para_o_mudo()
		MUDO:
			var todos := true
			for p in jogadores:
				var l: int = p.lugar
				if not jogando[l] or not _conectado(l):
					continue
				var e: Dictionary = j[l]
				e.pediu_mudo = true
				if not e.apertou_mudo and Forja.apertou(l, F.MICROFONE):
					e.apertou_mudo = true
					e.mudo = true
					e.mexeu = true
					# o jogo fica mudo: a luz laranja acende, como no console
					if Forja.led_mic(l, 1):
						e.luz_ok = true
					Som.tocar("tique", p.global_position + Vector3(0, 1, 0), -4.0)
					marcar(l, 100)
				if not e.apertou_mudo:
					todos = false
			if todos or t_estado >= MUDO_MAX:
				estado = SUSSURRO
				t_estado = 0.0
				for l in j:
					j[l].robo_falou = false
		SUSSURRO:
			if t_estado >= SUSSURRO_S:
				if Forja.bancada:  # a pergunta da luz do microfone é do Modo bancada
					_comecar_luz()
				else:
					estado = ESPERA
					t_estado = 0.0
		LUZ:
			var todos := true
			for p in jogadores:
				var l: int = p.lugar
				if not jogando[l] or not _conectado(l):
					continue
				var e: Dictionary = j[l]
				if int(e.fase) != FIM_LUZ:
					_atualizar_luz(l, e, dt)
				if int(e.fase) != FIM_LUZ:
					todos = false
			if todos:
				estado = ESPERA
				t_estado = 0.0
		ESPERA:
			if t_estado >= ESPERA_S:
				estado = SUSTO
				t_estado = 0.0
				_susto()
		SUSTO:
			# o vermelho do susto dura 0,4 s; a cor do lugar nunca fica de fora
			if t_estado >= 0.4 and _luz_do_susto:
				_luz_do_susto = false
				for l in j:
					if _conectado(l):
						Forja.luz_do_lugar(l)
			if t_estado >= SUSTO_S:
				for l in j:
					if _conectado(l):
						Forja.luz_do_lugar(l)
				estado = ACABOU
				for p in jogadores:
					acabou[p.lugar] = true


func _ir_para_o_mudo() -> void:
	estado = MUDO
	t_estado = 0.0
	vez = -1
	Som.tocar("sopro", GUARDIAO, -4.0)


func dar_vereditos(l: int) -> Array:
	var e: Dictionary = j[l]
	var quadros := int(Forja.som_mic(l).get("quadros", 0)) - int(e.quadros_ini)
	var dados := {"tem": e.tem, "piso": e.piso, "viu_piso": e.viu_piso, "voz": e.voz, "mudo": e.mudo_nivel,
		"viu_mudo": e.viu_mudo, "apertou_mudo": e.apertou_mudo, "pediu_mudo": e.pediu_mudo, "quadros": quadros,
		"mexeu": e.mexeu or e.apertou_mudo or Cega.total(e.luz) > 0}
	var mandou: bool = e.luz_ok or Cega.total(e.luz) > 0
	var lista: Array = [
		Forja.mic_veredito(l, "microfone", dados),
		Forja.mic_veredito(l, "microfone_mudo", dados),
		Forja.cega_veredito(l, "led_microfone", {"cega": e.luz, "sdl_aceitou": mandou}),
	]
	return lista.filter(func(v): return not v.is_empty())


# ------------------------------------------------------------------ o que se vê --

func _process(dt: float) -> void:
	super(dt)
	# os olhos do guardião: fechados no silêncio, abrindo com as vozes
	var alvo_olhos := 0.0
	if fase == "jogo":
		match estado:
			SILENCIO:
				alvo_olhos = 0.0
			CHAMADO:
				alvo_olhos = 0.35 + (0.4 if vez >= 0 and j[vez].chamou else 0.0)
			ESPERA:
				alvo_olhos = 0.15
			_:
				alvo_olhos = 1.0
	olhos = lerpf(olhos, alvo_olhos, minf(1.0, dt * 3.0))
	grito = lerpf(grito, 1.0 if fase == "jogo" and estado == SUSTO else 0.0, minf(1.0, dt * (14.0 if estado == SUSTO else 3.0)))
	flash = maxf(0.0, flash - dt * 0.9)
	tremor = flash * 1.4
	var mo: StandardMaterial3D = g.mat_olho
	mo.emission_energy_multiplier = 0.2 + 3.2 * olhos + 4.0 * flash
	for pa in g.palpebras:
		var pal: Node3D = pa
		pal.scale = Vector3(1, maxf(0.02, 1.0 - olhos), 1)
		pal.position.y = 0.28 + 0.2 * olhos
	var boca: Node3D = g.boca
	boca.scale = Vector3(1, 0.12 + 0.75 * grito, 1)
	var brilho: OmniLight3D = g.brilho
	brilho.light_energy = 0.6 * olhos + 5.0 * flash
	var pivo: Node3D = g.pivo
	pivo.position = GUARDIAO + Vector3(0, 0, 0.35 * grito)
	for p in jogadores:
		_mostrar(p.lugar, dt)


func _mostrar(l: int, dt: float) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = n[l]
	var k := clampf(float(e.chama), 0.0, 1.0)
	var chama: MeshInstance3D = nos.chama
	var altura := 0.08 + 1.5 * k
	chama.scale = Vector3(0.6 + 0.6 * k, altura, 0.6 + 0.6 * k)
	var bras: Vector3 = nos.bras
	chama.position = bras + Vector3(0, 0.72 + altura * 0.5, 0)
	chama.visible = altura > 0.1
	var luz: OmniLight3D = nos.luz
	luz.light_energy = 0.35 + 2.6 * k
	var foco: SpotLight3D = nos.foco
	var da_vez: bool = fase == "jogo" and estado == CHAMADO and vez == l
	foco.light_energy = lerpf(foco.light_energy, 5.0 if da_vez else 0.0, minf(1.0, dt * 6.0))
	var mb: StandardMaterial3D = nos.mat_borda
	mb.emission_energy_multiplier = lerpf(mb.emission_energy_multiplier, 1.6 if da_vez else 0.1, minf(1.0, dt * 6.0))
	var p := jogador(l)
	if p:
		p.animar("interact-right" if da_vez and float(e.chama) > 0.35 else "idle", 1.0)


# ------------------------------------------------------------------ a HUD --

func status(lugar: int) -> String:
	if fase != "jogo" or not j.has(lugar):
		return super(lugar)
	var e: Dictionary = j[lugar]
	match estado:
		SILENCIO:
			return "Silêncio"
		CHAMADO:
			if _mudo_no_sistema(e):
				return "Microfone mudo"
			if vez == lugar:
				return "Chamou ✓" if e.chamou else "Sua vez: chame!"
			return "Chamou ✓" if e.chamou else "Quieto"
		MUDO, SUSSURRO:
			return "Mudo ✓" if e.apertou_mudo else "Fique mudo"
		LUZ:
			return "%d ✓" % int(e.luz.certos)
	return "%d pontos" % pontos[lugar]


func progresso() -> String:
	if fase != "jogo":
		return ""
	match estado:
		SILENCIO:
			return "O silêncio de todos"
		CHAMADO:
			return "O chamado · P%d" % (vez + 1) if vez >= 0 else "O chamado"
		MUDO:
			return "O mudo"
		SUSSURRO:
			return "Mudos, sussurrem"
		LUZ:
			return "A luz do microfone"
	return ""


func dica(lugar: int) -> Dictionary:
	if not j.has(lugar) or fase != "jogo":
		return {}
	var e: Dictionary = j[lugar]
	var pos := Vector3(RAIAS[lugar], 0.0, 4.4)
	match estado:
		SILENCIO:
			return {"partes": ["Silêncio: o guardião dorme"], "pos": pos}
		CHAMADO:
			if _mudo_no_sistema(e):
				return {"partes": ["@mic", "A sua vez passa"], "pos": pos}
			if vez == lugar:
				return {"partes": ["Fale alto: chame o guardião"], "pos": pos}
			return {"partes": ["Quieto: é a vez do P%d" % (vez + 1)], "pos": pos}
		MUDO:
			if not e.apertou_mudo:
				return {"partes": ["@mic", "Fique mudo"], "pos": pos}
			return {"partes": ["Mudo"], "pos": pos}
		SUSSURRO:
			return {"partes": ["Mudo, sussurre baixinho"], "pos": pos}
		ESPERA:
			return {"partes": ["…"], "pos": pos}
	return {}


func pergunta(lugar: int) -> Dictionary:
	if not Forja.bancada:
		return {}  # a pergunta às cegas é do Modo bancada
	if not j.has(lugar) or fase != "jogo" or estado != LUZ:
		return {}
	var e: Dictionary = j[lugar]
	if int(e.fase) == FIM_LUZ:
		return {}
	var opcoes: Array = []
	for k in 3:
		opcoes.append([GLIFO_LUZ[k], null, Desenho.maiusc(NOME_LUZ[k])])
	var certa := -1
	var rodape := ""
	if int(e.fase) == REVELA_LUZ:
		certa = e.modo
		if e.resp < 0:
			rodape = "Sem resposta — estava %s" % NOME_LUZ[int(e.modo)]
		elif e.resp == e.modo:
			rodape = "Isso: a luz obedeceu"
		else:
			rodape = "Não — o jogo mandou %s" % NOME_LUZ[int(e.modo)]
	elif float(e.t) < LUZ_ESPERA:
		rodape = "Olhe o controle…"
	return {"titulo": "Como está a luz do microfone?", "opcoes": opcoes, "escolhida": e.resp, "certa": certa,
		"rodape": rodape, "pos": Vector3(RAIAS[lugar], 0.0, 3.9)}


# ------------------------------------------------------------------ o robô --
# Fala na vez dele, fica mudo, sussurra, e olha a luz do microfone do
# controle simulado dele (o defeito de mentira fica no caminho, como no
# aparelho).

func _robo(l: int, e: Dictionary, dt: float) -> void:
	match estado:
		CHAMADO:
			if vez == l and not e.robo_falou and t_estado > 0.4:
				Forja.robo_falar(l, 0.8, 1.2)
				e.robo_falou = true
		MUDO:
			if not e.apertou_mudo:
				if float(e.robo_espera) < 0.0:
					e.robo_espera = 0.6 + 0.8 * rng.randf()
				e.robo_espera = float(e.robo_espera) - dt
				if float(e.robo_espera) <= 0.0:
					Forja.robo_apertar(l, F.MICROFONE, 0.08)
					e.robo_espera = 1.5  # se não chegou, tenta de novo
		SUSSURRO:
			if not e.robo_falou and t_estado > 0.5:
				Forja.robo_falar(l, 0.35, 1.5)
				e.robo_falou = true
		LUZ:
			if int(e.fase) == OLHAR and e.resp < 0:
				if float(e.robo_espera) < 0.0:
					e.robo_espera = LUZ_ESPERA + 0.2 + 0.8 * rng.randf()
				e.robo_espera = float(e.robo_espera) - dt
				if float(e.robo_espera) <= 0.0:
					var visto := int(Forja.percepcao(l).get("led_mic", 0))
					Forja.robo_apertar(l, BOTAO_LUZ[clampi(visto, 0, 2)], 0.08)
					e.robo_espera = 99.0
