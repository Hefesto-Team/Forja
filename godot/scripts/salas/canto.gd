class_name SalaCanto
extends SalaJogo
## O Canto — o ritmo no alto-falante do controle.
##
## O padrão é o do alto-falante do DualSense nos jogos: o som que sai DA MÃO,
## paralelo ao som da TV — a espada que zune no controle enquanto a música toca
## na sala. Aqui a bigorna canta um ritmo curto, e a pergunta é a das salas de
## saída, às cegas:
##
##   - o canto sai no alto-falante de UM controle, ou na TV (a prova de
##     controle: nessas vezes ninguém deveria dizer "foi no meu");
##   - todos respondem: ✕ "cantou no meu controle", ○ "não foi no meu";
##   - a tela revela de onde saiu, e o dono do canto repete o ritmo com ✕.
##
## O som anda no ar, e todo mundo ouve todo canto: a pergunta não é "ouviu?",
## é "saiu da sua mão?". Quem diz "foi no meu" com o canto saindo em outro
## lugar ouviu o próprio controle cantar o canto de outro — o som não ficou
## no alto-falante certo. Enquanto canta, o sino grande balança e as notas
## sobem do meio: a tela não aponta ninguém.

const F := preload("res://scripts/forja.gd")
const RAIAS := [-6.0, -2.0, 2.0, 6.0]
const Z_JOGADOR := 1.2
const TV := 9
const NOTAS := 4
const INTERVALOS := [0.24, 0.36, 0.52]
const PERGUNTA_MAX := 5.0
const REPETE_MAX := 5.0
const REVELA_S := 1.4
const FOLGA_RITMO := 0.12  ## s de folga em cada intervalo repetido
const SINO_TV := Vector3(0.0, 3.9, -4.3)
## O perfil do sino (raio, altura), da coroa à boca: a silhueta da sala 2D,
## girada em volta do eixo.
const PERFIL := [
	Vector2(0.0, 1.0), Vector2(0.18, 0.98), Vector2(0.34, 0.89), Vector2(0.43, 0.73), Vector2(0.48, 0.5),
	Vector2(0.5, 0.23), Vector2(0.55, -0.05), Vector2(0.64, -0.32), Vector2(0.77, -0.55), Vector2(0.93, -0.7),
	Vector2(1.0, -0.8), Vector2(0.68, -0.85), Vector2(0.34, -0.875), Vector2(0.0, -0.886),
]

enum { PREPARO, CANTO, PERGUNTA, REVELA, REPETE, ACABOU }

var estado := PREPARO
var t_estado := 0.0
var relogio := 0.0  ## desde o começo do jogo; não volta a zero (os ataques do robô)
var plano: PackedInt32Array = PackedInt32Array()
var rodada := 0
var fonte := -1
var ritmo: Array = [0.0, 0.0, 0.0, 0.0]  ## os instantes das notas, desde o começo do canto
var notas_tocadas := 0
var j := {}  ## lugar -> o estado do jogador
var n := {}  ## lugar -> os nós da raia
var sino_tv: Node3D
var brilho_tv: OmniLight3D
var _mat_tv: StandardMaterial3D
var _notas_no_ar: Array = []  ## [Label3D, idade, lado]


func _init() -> void:
	id = "canto"
	nome = "O Canto"
	acao = "Ouça o canto e repita o ritmo."
	icone = "alto-falante"
	objetivo = "A bigorna canta um ritmo: às vezes no alto-falante de UM controle, às vezes na TV. Todo mundo ouve — a pergunta é outra: o canto saiu da SUA mão? ✕ foi no meu, ○ não foi. Depois, o dono do canto repete o ritmo com ✕. Confira o seu alto-falante aqui embaixo: △ toca um sino nele, ◀ ▶ troca."
	features = ["alto_falante"]
	cega = true
	papel_som = F.PAPEL_ALTO_FALANTE
	botoes_pedidos = F.mascara([F.CRUZ, F.CIRCULO])
	duracao = 0.0
	camera_pos = Vector3(0, 5.6, 11.2)
	camera_olhar = Vector3(0, 1.6, -1.0)


func montar() -> void:
	Kit.arena(self, 5, 3)
	# a capela: poeira violeta, e o neon roxo
	atmosfera(Color("#b88cff"), Tema.VIOLETA, false, 36, 22.0, -7.8, 0.2)
	var frio := OmniLight3D.new()
	frio.position = Vector3(0, 8.0, 4.0)
	frio.light_color = Color("#8a80c8")
	frio.light_energy = 0.55
	frio.omni_range = 26.0
	add_child(frio)
	for x in [-9.5, 9.5]:
		var tocha := OmniLight3D.new()
		tocha.position = Vector3(x, 2.6, -4.5)
		tocha.light_color = Color("#ffa060")
		tocha.light_energy = 1.1
		tocha.omni_range = 8.0
		add_child(tocha)
	_montar_torre()
	for p in jogadores:
		var l: int = p.lugar
		j[l] = _novo_jogador()
		n[l] = _montar_raia(l, p)
		Forja.gatilhos_off(l)


func _novo_jogador() -> Dictionary:
	return {"meus": Cega.nova(), "fantasmas": 0, "chances": 0, "resposta": -1, "toques": [], "acertos_ritmo": 0,
		"certos": 0, "robo_nivel": 0.0, "robo_vale": 1.0, "robo_desde": 1.0, "robo_ouviu": false, "robo_onsets": [],
		"robo_espera": -1.0, "robo_toque": 0}


## O sino: o perfil girado em volta do eixo (uma malha), pendurado pela coroa
## num pivô — é o pivô que balança. O badalo balança atrasado, por dentro.
static func sino(pai: Node3D, pos: Vector3, escala: float, cor: Color) -> Dictionary:
	var pivo := Node3D.new()
	pivo.position = pos
	pai.add_child(pivo)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lados := 28
	for i in PERFIL.size() - 1:
		var a: Vector2 = PERFIL[i]
		var b: Vector2 = PERFIL[i + 1]
		for k in lados:
			var t0 := TAU * k / lados
			var t1 := TAU * (k + 1) / lados
			var p00 := Vector3(cos(t0) * a.x, a.y, sin(t0) * a.x)
			var p01 := Vector3(cos(t1) * a.x, a.y, sin(t1) * a.x)
			var p10 := Vector3(cos(t0) * b.x, b.y, sin(t0) * b.x)
			var p11 := Vector3(cos(t1) * b.x, b.y, sin(t1) * b.x)
			for q in [p00, p10, p11, p00, p11, p01]:
				st.add_vertex(q)
	st.generate_normals()
	var malha := MeshInstance3D.new()
	malha.mesh = st.commit()
	var mat := Kit.material(cor, 0.0, 0.5)
	mat.metallic = 0.2
	mat.emission_enabled = true
	mat.emission = Tema.TUNGSTENIO
	mat.emission_energy_multiplier = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	malha.material_override = mat
	malha.position = Vector3(0, -1.0, 0) * escala
	malha.scale = Vector3.ONE * escala
	pivo.add_child(malha)
	var argola := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.rings = 8
	tor.ring_segments = 6
	tor.inner_radius = 0.07
	tor.outer_radius = 0.13
	argola.mesh = tor
	argola.rotation.x = PI * 0.5
	argola.scale = Vector3.ONE * escala
	argola.position = Vector3(0, 0.08, 0) * escala
	argola.material_override = mat
	pivo.add_child(argola)
	var badalo_pivo := Node3D.new()
	badalo_pivo.position = Vector3(0, -0.4, 0) * escala
	pivo.add_child(badalo_pivo)
	var badalo := Kit.esfera(badalo_pivo, 0.13 * escala, Vector3(0, -1.35, 0) * escala, Kit.material(Color("#5a3c1c"), 0.0, 0.6))
	badalo.name = "badalo"
	return {"pivo": pivo, "mat": mat, "badalo": badalo_pivo}


func _montar_torre() -> void:
	# o sino grande da TV, num pórtico de madeira no fundo
	var madeira := Kit.material(Color("#6b4526"), 0.0, 0.85)
	for x in [-2.1, 2.1]:
		Kit.caixa(self, Vector3(0.36, 5.2, 0.36), Vector3(x, 2.6, SINO_TV.z), madeira)
	Kit.caixa(self, Vector3(4.9, 0.4, 0.46), Vector3(0, 5.2, SINO_TV.z), madeira)
	Kit.cilindro(self, 0.035, 0.9, SINO_TV + Vector3(0, 0.75, 0), Kit.material(Color("#3c3c44"), 0.0, 0.5))
	var s := sino(self, SINO_TV, 1.35, Color("#b07838"))
	sino_tv = s.pivo
	_mat_tv = s.mat
	brilho_tv = OmniLight3D.new()
	brilho_tv.position = SINO_TV + Vector3(0, -1.2, 1.4)
	brilho_tv.light_color = Tema.TUNGSTENIO
	brilho_tv.light_energy = 0.0
	brilho_tv.omni_range = 6.0
	add_child(brilho_tv)
	var foco := SpotLight3D.new()
	foco.position = SINO_TV + Vector3(0, 2.5, 3.5)
	foco.look_at_from_position(foco.position, SINO_TV + Vector3(0, -0.8, 0))
	foco.light_color = Color("#ffd9a0")
	foco.light_energy = 2.2
	foco.spot_range = 9.0
	foco.spot_angle = 26.0
	add_child(foco)


func _montar_raia(l: int, p: ForjaPlayer) -> Dictionary:
	var x: float = RAIAS[l]
	var cor_l := Forja.cor_do_lugar(l)
	# o chão da raia: um tablado de madeira com a borda na cor do lugar
	Kit.cilindro(self, 1.45, 0.08, Vector3(x, 0.04, Z_JOGADOR), Kit.material(Color("#3a2a24"), 0.0, 0.9))
	var borda := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.rings = 8
	tor.ring_segments = 6
	tor.inner_radius = 1.4
	tor.outer_radius = 1.5
	borda.mesh = tor
	borda.position = Vector3(x, 0.09, Z_JOGADOR)
	borda.scale = Vector3(1, 0.35, 1)
	var mat_borda := Kit.material(cor_l.darkened(0.45), 0.0, 0.7)
	mat_borda.emission_enabled = true
	mat_borda.emission = cor_l
	mat_borda.emission_energy_multiplier = 0.0
	borda.material_override = mat_borda
	add_child(borda)
	# o sino pequeno do jogador, num suporte ao lado: o alto-falante na mão
	var base := Vector3(x + 1.05, 0.0, Z_JOGADOR - 0.35)
	var madeira := Kit.material(Color("#7a5230"), 0.0, 0.85)
	Kit.caixa(self, Vector3(0.12, 1.9, 0.12), base + Vector3(0, 0.95, 0), madeira)
	Kit.caixa(self, Vector3(0.62, 0.1, 0.12), base + Vector3(-0.25, 1.88, 0), madeira)
	var s := sino(self, base + Vector3(-0.45, 1.8, 0), 0.34, Color("#c08a42"))
	var luz := OmniLight3D.new()
	luz.position = base + Vector3(-0.45, 1.3, 0.5)
	luz.light_color = Tema.TUNGSTENIO
	luz.light_energy = 0.0
	luz.omni_range = 3.0
	add_child(luz)
	# a partitura do ritmo: as quatro notas (ouro) e os toques de quem repete
	var partitura := Node3D.new()
	partitura.position = Vector3(x, 2.75, Z_JOGADOR)
	partitura.visible = false
	add_child(partitura)
	Kit.caixa(partitura, Vector3(2.3, 0.03, 0.03), Vector3.ZERO, Kit.material(Color("#8a6a3a"), 0.4, 0.6))
	var pontos: Array = []
	for k in NOTAS:
		pontos.append(Kit.esfera(partitura, 0.09, Vector3.ZERO, Kit.material(Tema.TUNGSTENIO, 1.2)))
	var toques: Array = []
	for k in NOTAS:
		var anel := MeshInstance3D.new()
		var ta := TorusMesh.new()
		ta.rings = 8
		ta.ring_segments = 6
		ta.inner_radius = 0.1
		ta.outer_radius = 0.15
		anel.mesh = ta
		anel.rotation.x = PI * 0.5
		anel.material_override = Kit.material(cor_l, 1.6)
		anel.visible = false
		partitura.add_child(anel)
		toques.append(anel)
	p.position = Vector3(x, 0.1, Z_JOGADOR)
	p.rotation.y = 0.0
	maos_livres(p)
	return {"mat_borda": mat_borda, "sino": s.pivo, "mat_sino": s.mat, "badalo": s.badalo, "luz": luz,
		"partitura": partitura, "pontos": pontos, "toques": toques}


# ------------------------------------------------------------------ o jogo --

func iniciar_jogo() -> void:
	var fontes: Array = []
	var vezes: Array = []
	var n_jog := 0
	for p in jogadores:
		if jogando[p.lugar]:
			n_jog += 1
	var cada := 3 if n_jog <= 1 else 2
	for p in jogadores:
		if not jogando[p.lugar]:
			continue
		if not Forja.som_tem(p.lugar, F.PAPEL_ALTO_FALANTE):
			# sem alto-falante achado, o controle não canta: ele só responde, e o
			# veredito dele fica "não medido"
			Forja.registrar("O Canto: sem alto-falante achado no P%d; ele só responde" % (p.lugar + 1))
			continue
		fontes.append(p.lugar)
		vezes.append(cada)
	fontes.append(TV)
	vezes.append(3 if n_jog <= 1 else 2)
	plano = Forja.cega_plano_fontes(fontes, vezes, rng.randi())
	rodada = 0
	estado = PREPARO
	t_estado = 0.0


func _conectado(l: int) -> bool:
	return Forja.lugar(l).get("conectado", false)


func _comecar_canto() -> void:
	fonte = plano[rodada]
	ritmo[0] = 0.0
	for k in range(1, NOTAS):
		ritmo[k] = float(ritmo[k - 1]) + float(INTERVALOS[rng.randi_range(0, 2)])
	notas_tocadas = 0
	estado = CANTO
	t_estado = 0.0
	for l in j:
		var e: Dictionary = j[l]
		e.resposta = -1
		e.toques = []
		e.robo_ouviu = false
		e.robo_vale = 1.0
		e.robo_desde = 1.0
		e.robo_onsets = []
		e.robo_espera = -1.0
		e.robo_toque = 0
	Forja.evento("jogo", 0 if fonte == TV else fonte + 1, {"sala": id, "o": "canto", "fonte": "tv" if fonte == TV else "P%d" % (fonte + 1)})


func _tocar_nota(k: int) -> void:
	var qual := "nota_alta" if k % 2 == 1 else "nota"
	if fonte == TV:
		Som.tocar(qual, SINO_TV, -2.0)
	else:
		Forja.som_falante(fonte, qual, 0.9)
	# a nota sobe do meio, sem apontar ninguém
	var nota := Label3D.new()
	nota.text = "♪" if k % 2 == 0 else "♫"
	nota.font = Tema.archivo(700)
	nota.font_size = 150
	nota.pixel_size = 0.005
	nota.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nota.modulate = Tema.ETIQUETA
	nota.outline_size = 14
	nota.outline_modulate = Color(Tema.FITA, 0.8)
	nota.position = SINO_TV + Vector3(0, -0.6, 0.9)
	add_child(nota)
	_notas_no_ar.append([nota, 0.0, -1.0 if k % 2 == 0 else 1.0])


func _fechar_pergunta() -> void:
	for p in jogadores:
		var l: int = p.lugar
		if not jogando[l] or not _conectado(l):
			continue
		var e: Dictionary = j[l]
		var res := ""
		if fonte == l:
			if e.resposta == 1:
				Cega.certo(e.meus)
				e.certos = int(e.certos) + 1
				marcar(l, 100)
				res = "certo"
			elif e.resposta == 0:
				Cega.errado(e.meus, 0)
				res = "errado"
			else:
				Cega.perdido(e.meus)
				res = "perdido"
		else:
			e.chances = int(e.chances) + 1
			if e.resposta == 1:
				e.fantasmas = int(e.fantasmas) + 1
				res = "fantasma"
			elif e.resposta == 0:
				e.certos = int(e.certos) + 1
				marcar(l, 50)
				res = "certo"
			else:
				res = "perdido"
		Forja.evento("jogo", l + 1, {"sala": id, "o": "resposta", "resultado": res})
	_revelar()


## O canto se revela: o sino na TV ou as faíscas de quem era a fonte. Depois da
## pergunta (Modo bancada) ou direto do canto (o jogo).
func _revelar() -> void:
	estado = REVELA
	t_estado = 0.0
	if fonte == TV:
		Som.tocar("bigorna_aguda", SINO_TV, -8.0)
	else:
		var dono := jogador(fonte)
		if dono:
			Efeitos.faiscas(self, dono.global_position + Vector3(0, 2.2, 0), Tema.TUNGSTENIO, 20, 0.8)


func _fechar_repeticao() -> void:
	var e: Dictionary = j[fonte]
	var toques: Array = e.toques
	var bons := 0
	for k in range(1, mini(toques.size(), NOTAS)):
		var quer := float(ritmo[k]) - float(ritmo[k - 1])
		var fez := float(toques[k]) - float(toques[k - 1])
		if absf(quer - fez) < FOLGA_RITMO:
			bons += 1
	e.acertos_ritmo = int(e.acertos_ritmo) + bons
	marcar(fonte, 100 * bons)
	Forja.evento("jogo", fonte + 1, {"sala": id, "o": "ritmo", "acertos": bons})
	if bons == NOTAS - 1:
		Som.tocar("sucesso", null, -6.0)
		var dono := jogador(fonte)
		if dono:
			dono.gesto("emote-yes", 0.8)
			Efeitos.faiscas(self, dono.global_position + Vector3(0, 2.6, 0), Tema.TUNGSTENIO, 36, 1.2)
	_proxima_rodada()


func _proxima_rodada() -> void:
	rodada += 1
	estado = PREPARO
	t_estado = 0.0


func _acabar() -> void:
	estado = ACABOU
	for p in jogadores:
		acabou[p.lugar] = true


func jogar(dt: float) -> void:
	if Forja.robo:
		for p in jogadores:
			if _conectado(p.lugar) and jogando[p.lugar]:
				_robo(p.lugar, j[p.lugar], dt)
	t_estado += dt
	relogio += dt
	match estado:
		PREPARO:
			if t_estado >= 1.0:
				if rodada >= plano.size():
					_acabar()
				else:
					_comecar_canto()
		CANTO:
			while notas_tocadas < NOTAS and t_estado >= float(ritmo[notas_tocadas]):
				_tocar_nota(notas_tocadas)
				notas_tocadas += 1
			if t_estado >= float(ritmo[NOTAS - 1]) + 0.5:
				if Forja.bancada:  # a pergunta às cegas é do Modo bancada
					estado = PERGUNTA
					t_estado = 0.0
					Forja.evento("jogo", 0, {"sala": id, "o": "pergunta", "qual": "canto"})
				else:
					_revelar()
		PERGUNTA:
			var todos := true
			for p in jogadores:
				var l: int = p.lugar
				if not jogando[l] or not _conectado(l):
					continue
				var e: Dictionary = j[l]
				if e.resposta < 0:
					if Forja.apertou(l, F.CRUZ):
						e.resposta = 1
					elif Forja.apertou(l, F.CIRCULO):
						e.resposta = 0
					if e.resposta >= 0:
						Som.tocar("tique", p.global_position + Vector3(0, 1, 0), -6.0)
						p.gesto("emote-yes" if e.resposta == 1 else "emote-no", 0.7)
				if e.resposta < 0:
					todos = false
			if todos or t_estado >= PERGUNTA_MAX:
				_fechar_pergunta()
		REVELA:
			if t_estado >= REVELA_S:
				t_estado = 0.0
				if fonte != TV and _conectado(fonte) and jogando[fonte]:
					estado = REPETE
				else:
					_proxima_rodada()
		REPETE:
			var e: Dictionary = j[fonte]
			var toques: Array = e.toques
			if toques.size() < NOTAS and Forja.apertou(fonte, F.CRUZ):
				toques.append(t_estado)
				Forja.som_falante(fonte, "nota_alta" if (toques.size() - 1) % 2 == 1 else "nota", 0.6)
			if toques.size() >= NOTAS or t_estado >= REPETE_MAX or not _conectado(fonte):
				_fechar_repeticao()


func dar_vereditos(l: int) -> Array:
	var e: Dictionary = j[l]
	var v := Forja.cega_veredito(l, "alto_falante", {"cega": e.meus, "fantasmas": e.fantasmas,
		"chances": e.chances, "tem": Forja.som_tem(l, F.PAPEL_ALTO_FALANTE)})
	return [] if v.is_empty() else [v]


# ------------------------------------------------------------------ o que se vê --

func _process(dt: float) -> void:
	super(dt)
	# o sino grande balança enquanto canta (qualquer que seja a fonte: a tela
	# não aponta) e na revelação, quando o canto era da TV
	var canta := fase == "jogo" and estado == CANTO
	var revela_tv := fase == "jogo" and estado == REVELA and fonte == TV
	var amp := 0.22 if revela_tv else (0.12 if canta else 0.0)
	sino_tv.rotation.x = lerpf(sino_tv.rotation.x, sin(t * 6.0) * amp, minf(1.0, dt * 8.0))
	_mat_tv.emission_energy_multiplier = lerpf(_mat_tv.emission_energy_multiplier, 1.1 if revela_tv else 0.0, minf(1.0, dt * 6.0))
	brilho_tv.light_energy = lerpf(brilho_tv.light_energy, 3.0 if revela_tv else 0.0, minf(1.0, dt * 6.0))
	for k in range(_notas_no_ar.size() - 1, -1, -1):
		var item: Array = _notas_no_ar[k]
		var nota: Label3D = item[0]
		item[1] = float(item[1]) + dt
		var idade: float = item[1]
		nota.position = SINO_TV + Vector3(float(item[2]) * (0.6 + idade * 0.7), -0.4 + idade * 1.3, 0.9)
		nota.modulate.a = clampf(1.2 - idade, 0.0, 1.0)
		if idade > 1.2:
			nota.queue_free()
			_notas_no_ar.remove_at(k)
	for p in jogadores:
		_mostrar(p.lugar, dt)


func _mostrar(l: int, dt: float) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = n[l]
	var dono: bool = fase == "jogo" and (estado == REVELA or estado == REPETE) and fonte == l
	var sino_p: Node3D = nos.sino
	var badalo: Node3D = nos.badalo
	var amp := 0.3 if dono else 0.0
	sino_p.rotation.z = lerpf(sino_p.rotation.z, sin(t * 10.0) * amp, minf(1.0, dt * 8.0))
	badalo.rotation.z = lerpf(badalo.rotation.z, sin(t * 10.0 - 0.6) * amp * 1.4, minf(1.0, dt * 8.0))
	var ms: StandardMaterial3D = nos.mat_sino
	ms.emission_energy_multiplier = lerpf(ms.emission_energy_multiplier, 1.4 if dono else 0.0, minf(1.0, dt * 6.0))
	var luz: OmniLight3D = nos.luz
	luz.light_energy = lerpf(luz.light_energy, 2.2 if dono else 0.0, minf(1.0, dt * 6.0))
	var mb: StandardMaterial3D = nos.mat_borda
	mb.emission_energy_multiplier = lerpf(mb.emission_energy_multiplier, 1.6 if dono else 0.15, minf(1.0, dt * 6.0))
	# a partitura: só na vez do dono repetir
	var part: Node3D = nos.partitura
	part.visible = fase == "jogo" and estado == REPETE and fonte == l
	if part.visible:
		var total := float(ritmo[NOTAS - 1]) + 0.3
		for k in NOTAS:
			var ponto: Node3D = nos.pontos[k]
			ponto.position = Vector3(-1.1 + 2.2 * float(ritmo[k]) / total, 0, 0)
		var toques: Array = e.toques
		for k in NOTAS:
			var anel: Node3D = nos.toques[k]
			anel.visible = k < toques.size()
			if anel.visible:
				var tk := float(toques[k]) - float(toques[0])
				anel.position = Vector3(-1.1 + 2.2 * minf(tk / total, 1.0), 0, 0.02)


# ------------------------------------------------------------------ a HUD --

func status(lugar: int) -> String:
	if fase == "jogo" and j.has(lugar):
		return "%d ✓ · ritmo %d" % [int(j[lugar].certos), int(j[lugar].acertos_ritmo)]
	return super(lugar)


func progresso() -> String:
	if fase != "jogo" or plano.is_empty():
		return ""
	return "Canto %d de %d" % [mini(rodada + 1, plano.size()), plano.size()]


func dica(lugar: int) -> Dictionary:
	if not j.has(lugar) or fase != "jogo":
		return {}
	var pos := Vector3(RAIAS[lugar], 0.0, 4.4)
	if estado == REPETE and fonte == lugar:
		return {"partes": ["@cross", "Repita o ritmo"], "pos": pos}
	if estado == CANTO:
		return {"partes": ["Ouça o canto"], "pos": pos}
	return {}


func pergunta(lugar: int) -> Dictionary:
	if not Forja.bancada:
		return {}  # a pergunta às cegas é do Modo bancada
	if not j.has(lugar) or fase != "jogo" or not (estado == PERGUNTA or estado == REVELA):
		return {}
	var e: Dictionary = j[lugar]
	var escolhida := -1
	if e.resposta == 1:
		escolhida = 0
	elif e.resposta == 0:
		escolhida = 1
	var certa := -1
	var rodape := ""
	if estado == REVELA:
		certa = 0 if fonte == lugar else 1
		var de := "era seu" if fonte == lugar else ("era da TV" if fonte == TV else "era do P%d" % (fonte + 1))
		if e.resposta < 0:
			rodape = "Sem resposta — %s" % de
		elif escolhida == certa:
			rodape = "Isso: %s" % de
		else:
			rodape = "Não — %s" % de
	return {"titulo": "O canto saiu do seu controle?", "opcoes": [["cross", null, "Foi no meu"], ["circle", null, "Não foi"]],
		"escolhida": escolhida, "certa": certa, "rodape": rodape, "pos": Vector3(RAIAS[lugar], 0.0, 3.9)}


# ------------------------------------------------------------------ o robô --
# Ouve o alto-falante do controle dele (a placa virtual): o ataque de cada
# nota é o nível subindo acima do vale deixado pela anterior. Diz "foi no meu"
# quando ouviu o canto na mão, e repete os intervalos que ouviu.

func _robo(l: int, e: Dictionary, dt: float) -> void:
	var nivel := float(Forja.som_virtual(l).get("falante", 0.0))
	e.robo_nivel = nivel
	e.robo_desde = float(e.robo_desde) + dt
	var ataque: bool = nivel > 0.12 and nivel - float(e.robo_vale) > 0.10 and float(e.robo_desde) > 0.12
	if ataque:
		e.robo_vale = nivel
		e.robo_desde = 0.0
	else:
		e.robo_vale = minf(float(e.robo_vale), nivel)
	var onsets: Array = e.robo_onsets
	if ataque and (estado == CANTO or (estado == PERGUNTA and t_estado < 0.4)):
		e.robo_ouviu = true
		if onsets.size() < NOTAS + 2:
			onsets.append(relogio)
	if estado == PERGUNTA and e.resposta < 0:
		if e.robo_espera < 0.0:
			e.robo_espera = 0.5 + 0.6 * rng.randf()
		e.robo_espera = float(e.robo_espera) - dt
		if e.robo_espera <= 0.0:
			Forja.robo_apertar(l, F.CRUZ if e.robo_ouviu else F.CIRCULO, 0.08)
			e.robo_espera = 99.0
	if estado == REPETE and fonte == l and onsets.size() >= 2:
		# repete os intervalos que ouviu, a partir de 0,6 s
		var k: int = e.robo_toque
		if k < onsets.size() and k < NOTAS:
			var quando := 0.6 + (float(onsets[k]) - float(onsets[0]))
			if t_estado >= quando:
				Forja.robo_apertar(l, F.CRUZ, 0.06)
				e.robo_toque = k + 1


func com_poucos() -> String:
	match jogadores.size():
		1: return "3 cantos seus"
	return ""
