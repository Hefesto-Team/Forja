class_name TelaLobby
extends Control

const CABECA := 0
const SUPERIOR := 1
const INFERIOR := 2
const ITEM := 3
const NOME := 4
const LINHAS := ["Cabeça", "Superior", "Inferior", "Arma ou amuleto", "Nome"]
const ROTULO_CURTO := ["Cabeça", "Superior", "Inferior", "Arma", "Nome"]
const ROLETA_S := 0.25
const TOM_DA_PARTE := [1.4983, 1.2599, 1.0, 0.7492]
const JUNTA := [1.25, 0.95, 0.45, 0.95]
const POSE := ["emote-yes", "holding-both", "attack-kick-right"]
const EDITANDO := 0
const FORJANDO := 1
const FORJADO := 2
const GUARDADO := 3
const MARTELADAS := 8
const ROBO_ATRASO_S := 0.033
const NOMES := ["Basalto", "Granito", "Bronze", "Tenaz", "Rebite", "Ferrugem",
	"Obsidiana", "Ônix", "Titânio", "Cobalto", "Quartzo", "Cinzel",
	"Brasa", "Carvão", "Latão", "Estanho", "Níquel", "Âmbar",
	"Faísca", "Magnésio", "Cromo", "Safira", "Pirita", "Grafite"]
const LARGURA_DA_COLUNA := 432.0

var prontos := [false, false, false, false]
var contagem := -1.0
var etapa := [EDITANDO, EDITANDO, EDITANDO, EDITANDO]
var linha := [0, 0, 0, 0]
var golpes := [[], [], [], []]
var desvio := [0.0, 0.0, 0.0, 0.0]
var jogadores: Array = []
var salao: Node = null
var cartoes: Array[CartaoJogador] = []
var _robo_espera := [0.0, 0.0, 0.0, 0.0]
var _robo_batida := [0, 0, 0, 0]
var _robo_erro := [0.0, 0.0, 0.0, 0.0]
var _batida_vista := -1
var _sorteios := [0, 0, 0, 0]
var _entrou_agora := [false, false, false, false]
var teclados: Array = [null, null, null, null]
var nome_escrito := [false, false, false, false]
var t_nome_ms := [0, 0, 0, 0]
var _nome_antes := ["", "", "", ""]
var _robo_teclado := [0, 0, 0, 0]
var _robo_erro_do_teclado := [false, false, false, false]
var corpo := [{}, {}, {}, {}]
var _encaixe := [{}, {}, {}, {}]
var _ultimo_toque := [-1.0, -1.0, -1.0, -1.0]
var _pose := [-1.0, -1.0, -1.0, -1.0]
var _pose_linha := [0, 0, 0, 0]
var _na_batida := [{}, {}, {}, {}]
var _troca_do_pre := [{}, {}, {}, {}]
var _robo_trocou := [false, false, false, false]
var _robo_toques := [0, 0, 0, 0]
var visor: Visor = null
var ultimo_encaixe := [{}, {}, {}, {}]
var ligou := [0, 0, 0, 0]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 4:
		var c := CartaoJogador.new()
		c.lugar = i
		add_child(c)
		cartoes.append(c)
	resized.connect(_posicionar)
	_posicionar()


func _posicionar() -> void:
	for i in 4:
		cartoes[i].position = Vector2(96.0 + LARGURA_DA_COLUNA * i, 0.0)
		cartoes[i].size = Vector2(LARGURA_DA_COLUNA, 1080.0)


func _process(_dt: float) -> void:
	queue_redraw()


func abrir() -> void:
	for l in 4:
		prontos[l] = false
		etapa[l] = EDITANDO
		linha[l] = 0
		golpes[l] = []
		desvio[l] = 0.0
		_sorteios[l] = 0
		_robo_espera[l] = 0.0
		_robo_batida[l] = 0
		_robo_erro[l] = 0.0
		teclados[l] = null
		nome_escrito[l] = false
		t_nome_ms[l] = 0
		_robo_teclado[l] = 0
		_robo_erro_do_teclado[l] = false
	contagem = -1.0
	_batida_vista = -1
	Itens.novo_minigame()
	for l in 4:
		if Forja.ocupado(l):
			entrou(l)
	_entrou_agora = [false, false, false, false]


func entrou(l: int) -> void:
	var p: ForjaPlayer = jogadores[l]
	golpes[l] = []
	prontos[l] = false
	linha[l] = 0
	teclados[l] = null
	nome_escrito[l] = false
	t_nome_ms[l] = 0
	_robo_teclado[l] = 0
	_encaixe[l] = {}
	_na_batida[l] = {}
	_pose[l] = -1.0
	_troca_do_pre[l] = {}
	_robo_trocou[l] = false
	_robo_toques[l] = 0
	var guardado: Dictionary = Opcoes.cavaleiro[l]
	if Opcoes.noite_dos_cavaleiros == Opcoes.noite() and not guardado.is_empty():
		p.vestir(guardado)
		desvio[l] = Opcoes.tempo_ms[l] / 1000.0
		etapa[l] = GUARDADO
	else:
		etapa[l] = EDITANDO
		var pm := Cavaleiro.pre_montado(l, _ocupados(l))
		p.vestir_pecas(pm.pecas, _indice_do_item(str(pm.item)))
		_troca_do_pre[l] = pm.troca.duplicate()
		if not pm.troca.is_empty():
			_troca_do_pre[l]["item"] = str(pm.item)
		p.nome = str(pm.nome) if str(pm.nome) != "" and not (str(pm.nome) in _nomes_dos_outros(l)) \
			else _nome_livre(l, 1, (Forja.semente * 7 + l * 5) % NOMES.size() - 1)
	corpo[l] = Cavaleiro.corpo(p.pecas)
	Itens.escolhido[l] = p.item_i
	Itens.sentir(l)
	p.acender(1.0)
	salao.acender_bigorna(l, 1.5)
	_robo_espera[l] = 1.2
	_entrou_agora[l] = true


func _nome_livre(l: int, passo: int, base := -99) -> String:
	var i := base
	if base == -99:
		i = maxi(NOMES.find(jogadores[l].nome), 0)
	for n in NOMES.size():
		i = wrapi(i + passo, 0, NOMES.size())
		var usado := false
		for j in 4:
			if j != l and Forja.ocupado(j) and jogadores[j].nome == NOMES[i]:
				usado = true
		if not usado:
			return NOMES[i]
	return NOMES[i]


func quadro(dt: float, dx: Array, dy: Array) -> void:
	var b := floori(Ritmo.batida())
	if b != _batida_vista:
		_batida_vista = b
		for l in 4:
			if Forja.ocupado(l) and etapa[l] == FORJANDO:
				Som.tocar("tique", null, -10.0)
				break
	for l in 4:
		if Forja.ocupado(l):
			_servir_o_encaixe(l)
	for l in 4:
		if not Forja.ocupado(l):
			continue
		var p: ForjaPlayer = jogadores[l]
		if teclados[l] != null:
			_quadro_do_teclado(l)
			continue
		var cruz: bool = Forja.apertou(l, Forja.CRUZ) and not _entrou_agora[l]
		var circulo: bool = Forja.apertou(l, Forja.CIRCULO)
		match etapa[l]:
			EDITANDO:
				if circulo:
					_voltar(l)
				elif cruz:
					_comecar_a_forja(l)
				elif Forja.apertou(l, Forja.TRIANGULO):
					_sortear(l)
				elif Forja.apertou(l, Forja.R1) and linha[l] == NOME:
					_abrir_o_teclado(l)
				elif dy[l] != 0:
					var nova := clampi(linha[l] + dy[l], CABECA, NOME)
					if nova != linha[l]:
						linha[l] = nova
						Som.no_controle(l, "tique", 0.6)
						Forja.sentir(l, "toque")
				elif dx[l] != 0:
					_trocar(l, dx[l])
			FORJANDO:
				if circulo:
					golpes[l] = []
					p.acender(1.0)
					salao.acender_bigorna(l, 1.5)
					etapa[l] = EDITANDO
					_som_de_voltar(l)
				elif cruz:
					martelar(l)
			FORJADO:
				if circulo:
					prontos[l] = false
					etapa[l] = EDITANDO
					_som_de_voltar(l)
			GUARDADO:
				if circulo:
					etapa[l] = EDITANDO
					linha[l] = 0
					_som_de_voltar(l)
				elif cruz:
					etapa[l] = FORJADO
					prontos[l] = true
					Som.tocar("ui_confirma", null, -12.0)
					Som.no_controle(l, "ui_confirma", 0.85)
					Forja.sentir(l, "acerto")
					Forja.registrar("P%d confirmou o cavaleiro guardado" % (l + 1))
	_entrou_agora = [false, false, false, false]


func _nomes_dos_outros(l: int) -> Array:
	var nomes: Array = []
	for j in 4:
		if j != l and Forja.ocupado(j) and jogadores.size() > j and str(jogadores[j].nome) != "":
			nomes.append(TecladoDoNome.nome_final(str(jogadores[j].nome)))
	return nomes


func _abrir_o_teclado(l: int) -> void:
	var t := TecladoDoNome.new()
	_nome_antes[l] = str(jogadores[l].nome)
	t.outros = _nomes_dos_outros(l)
	t.abrir(_nome_antes[l], Time.get_ticks_msec())
	teclados[l] = t
	_robo_teclado[l] = 1
	_robo_erro_do_teclado[l] = false
	Som.tocar("ui_tique", null, -12.0)
	Som.no_controle(l, "ui_tique", 0.6)
	Forja.sentir(l, "toque")


func _som_da_tecla(l: int) -> void:
	Som.tocar("ui_tecla", null, -12.0)
	Forja.som_falante(l, "clique")
	Forja.sentir(l, "toque")


func _som_do_cursor(l: int) -> void:
	Som.tocar("ui_tique", null, -12.0)
	Som.no_controle(l, "ui_tique", 0.6)
	Forja.sentir(l, "toque")


var relogio_do_teclado := func() -> int: return Time.get_ticks_msec()


func _quadro_do_teclado(l: int) -> void:
	var t: TecladoDoNome = teclados[l]
	t.outros = _nomes_dos_outros(l)
	if _entrou_agora[l]:
		return
	if t.quadro(Forja.mover(l), relogio_do_teclado.call()):
		_som_do_cursor(l)
	if Forja.apertou(l, Forja.CRUZ):
		var estava_no_pronto := t.no_pronto()
		match t.escolher():
			"tecla":
				_som_da_tecla(l)
			"pronto":
				_fechar_o_teclado(l, true)
			_:
				if estava_no_pronto:
					Forja.sentir(l, "toque")
	elif Forja.apertou(l, Forja.CIRCULO):
		if t.apagar():
			_som_da_tecla(l)
		else:
			_fechar_o_teclado(l, false)
	elif Forja.apertou(l, Forja.TRIANGULO):
		_sortear_o_nome(l)
	elif Forja.apertou(l, Forja.R1):
		if not t.no_pronto():
			t.para_o_pronto()
			_som_do_cursor(l)


func _sortear_o_nome(l: int) -> void:
	var t: TecladoDoNome = teclados[l]
	var livres := nomes_para_sortear(l)
	var rng := RandomNumberGenerator.new()
	rng.seed = Forja.semente * 31 + l + 1000 * _sorteios[l]
	_sorteios[l] += 1
	t.sortear(str(livres[rng.randi_range(0, livres.size() - 1)]))
	_som_da_tecla(l)


func nomes_para_sortear(l: int) -> Array:
	var usados := _nomes_dos_outros(l)
	var livres: Array = []
	for n in NOMES:
		if not (n in usados):
			livres.append(n)
	return livres if not livres.is_empty() else NOMES.duplicate()


func _fechar_o_teclado(l: int, grava: bool) -> void:
	var t: TecladoDoNome = teclados[l]
	var ms := Time.get_ticks_msec() - t.abriu_em_ms
	t_nome_ms[l] += ms
	if grava:
		jogadores[l].nome = TecladoDoNome.nome_final(t.texto)
		Som.tocar("ui_confirma", null, -12.0)
		Som.no_controle(l, "ui_confirma", 0.85)
		Forja.sentir(l, "toque")
		if t.digitou:
			nome_escrito[l] = true
			Forja.evento("momento", l + 1, {"slot": "montagem", "nome": "nome_escrito", "t_musica": Ritmo.t_musica()})
		Forja.registrar("P%d escreveu o nome %s" % [l + 1, jogadores[l].nome])
	else:
		jogadores[l].nome = _nome_antes[l]
		_som_de_voltar(l)
	teclados[l] = null


func _som_de_voltar(l: int) -> void:
	Som.tocar("ui_volta", null, -12.0)
	Som.no_controle(l, "ui_volta", 0.85)
	Forja.sentir(l, "toque")


func _voltar(l: int) -> void:
	_som_de_voltar(l)
	if linha[l] > CABECA:
		linha[l] = CABECA
		return
	Forja.sair(l)
	Forja.registrar("P%d saiu do lobby" % (l + 1))
	prontos[l] = false
	golpes[l] = []


func _comecar_a_forja(l: int) -> void:
	etapa[l] = FORJANDO
	golpes[l] = []
	jogadores[l].acender(0.0)
	_robo_batida[l] = floori(Ritmo.batida()) + 1
	_robo_erro[l] = 0.0
	Som.tocar("ui_confirma", null, -12.0)
	Som.no_controle(l, "ui_confirma", 0.85)
	Forja.sentir(l, "acerto")


func _trocar(l: int, passo: int) -> void:
	var p: ForjaPlayer = jogadores[l]
	match linha[l]:
		CABECA, SUPERIOR, INFERIOR:
			var k: int = linha[l]
			var atual := str(_pecas_pedidas(l)[k])
			var nova := _proxima_peca(l, k, atual, passo)
			if nova != atual:
				_pedir_encaixe(l, k, nova)
		ITEM:
			var atual_item := int(_encaixe[l].get(ITEM, {}).get("valor", p.item_i))
			var novo := _proximo_item(l, atual_item, passo)
			if novo != atual_item:
				_pedir_encaixe(l, ITEM, novo)
		NOME:
			p.nome = _nome_livre(l, passo)
			Som.tocar("fx_caneta", null, -6.0)
			Forja.sentir(l, "metal")


func _sortear(l: int) -> void:
	var p: ForjaPlayer = jogadores[l]
	var rng := RandomNumberGenerator.new()
	rng.seed = Forja.semente * 31 + l + 1000 * _sorteios[l]
	_sorteios[l] += 1
	_encaixe[l] = {}
	var sorteado := _corpo_sorteado(l, rng)
	var alcanca := Cavaleiro.alcancaveis(Cavaleiro.corpo(sorteado).stats)
	p.vestir_pecas(sorteado, _indice_do_item(str(alcanca[rng.randi_range(0, alcanca.size() - 1)])))
	corpo[l] = Cavaleiro.corpo(p.pecas)
	p.nome = _nome_livre(l, 1, rng.randi_range(0, NOMES.size() - 1) - 1)
	p.gesto("interact-right", 0.5)
	_som_do_boneco(l)
	_sentir_o_item(l)


func _som_do_boneco(l: int) -> void:
	Som.tocar("ui_peca", null, -12.0, 1.0)
	Som.no_controle(l, "ui_peca", 0.85)
	Forja.sentir(l, "metal")


func _sentir_o_item(l: int) -> void:
	Itens.escolhido[l] = jogadores[l].item_i
	Itens.sentir(l)
	Som.tocar("ui_peca", null, -12.0, 0.7492)
	Som.no_controle(l, "ui_peca", 0.85)
	Forja.sentir(l, "acerto")
	jogadores[l].acender_acento()


func martelar(l: int) -> void:
	var t := Ritmo.t_musica()
	var d := t - Ritmo.t_da_batida(roundf(Ritmo.batida()))
	golpes[l].append(d)
	var k: float = golpes[l].size() / float(MARTELADAS)
	_acender_a_parte(l, golpes[l].size())
	jogadores[l].gesto("attack-melee-right", 0.35)
	Som.tocar("martelo", jogadores[l].global_position, -4.0)
	Forja.sentir(l, "acerto")
	salao.acender_bigorna(l, 2.5 + k, 1.5 * k)
	if golpes[l].size() >= MARTELADAS:
		_forjou(l)


func _forjou(l: int) -> void:
	desvio[l] = mediana(golpes[l])
	Ritmo.definir_desvio(l, desvio[l], "construcao", golpes[l].size())
	Itens.escolhido[l] = jogadores[l].item_i
	corpo[l] = Cavaleiro.corpo(jogadores[l].pecas)
	var id_do_item := str(ForjaPlayer.ITENS[jogadores[l].item_i].id)
	Itens.em_liga[l] = Cavaleiro.no_corpo(id_do_item, corpo[l].stats) == "liga"
	Cavaleiro.stats[l] = corpo[l].stats.duplicate()
	Opcoes.cavaleiro[l] = jogadores[l].cavaleiro()
	Opcoes.noite_dos_cavaleiros = Opcoes.noite()
	Opcoes.guardar()
	etapa[l] = FORJADO
	prontos[l] = true
	jogadores[l].acender(1.0)
	salao.acender_bigorna(l, 2.5)
	jogadores[l].gesto("emote-yes", 1.2)
	Efeitos.faiscas(salao, jogadores[l].global_position + Vector3(0, 1.6, 0), Forja.cor_do_lugar(l), 24, 1.0)
	Forja.sentir(l, "perfeito")
	Som.pio(l, jogadores[l].modelo_i)
	var ev: Dictionary = jogadores[l].cavaleiro()
	ev["nome_escrito"] = nome_escrito[l]
	ev["t_nome_ms"] = t_nome_ms[l]
	ev["stats"] = corpo[l].stats
	ev["arquetipo"] = str(corpo[l].arquetipo.get("id", ""))
	ev["liga"] = Itens.em_liga[l]
	ev["boa"] = Cavaleiro.build_boa(corpo[l], id_do_item)
	ev["perdidos"] = corpo[l].perdidos
	Forja.evento("cavaleiro", l + 1, ev)
	Forja.registrar("P%d forjou o cavaleiro" % (l + 1))


static func mediana(v: Array) -> float:
	if v.is_empty():
		return 0.0
	var o := v.duplicate()
	o.sort()
	var n := o.size()
	if n % 2 == 1:
		return float(o[n / 2])
	return (float(o[n / 2 - 1]) + float(o[n / 2])) * 0.5


func robo(l: int, dt: float) -> void:
	_robo_espera[l] -= dt
	if not Forja.ocupado(l):
		if bool(Forja.lugar(l).get("reservado", false)) and _robo_espera[l] <= 0.0:
			Forja.robo_apertar(l, Forja.CRUZ)
			_robo_espera[l] = 0.6
		return
	if not Forja.lugar(l).get("conectado", false):
		return
	if etapa[l] == FORJANDO:
		if Ritmo.t_musica() >= Ritmo.t_da_batida(_robo_batida[l]) + ROBO_ATRASO_S * l + _robo_erro[l]:
			Forja.robo_apertar(l, Forja.CRUZ)
			_robo_batida[l] += 1
			_robo_erro[l] = 0.0 if Forja.robo_acerta() else 0.12
		return
	if teclados[l] != null:
		_robo_escreve(l)
		return
	if _robo_espera[l] > 0.0 or etapa[l] == FORJADO:
		return
	if etapa[l] == EDITANDO and l == 0 and not _robo_trocou[l] and _robo_troca(l):
		return
	if etapa[l] == EDITANDO and _robo_teclado[l] == 0:
		if linha[l] < NOME:
			Forja.robo_apertar(l, Forja.BAIXO)
		else:
			Forja.robo_apertar(l, Forja.R1)
		_robo_espera[l] = 0.4
		return
	Forja.robo_apertar(l, Forja.CRUZ)
	_robo_espera[l] = 0.9 + 0.1 * l + (0.0 if Forja.robo_acerta() else 1.5)


const ROBO_NOME := "DONA BRASA"


func _robo_escreve(l: int) -> void:
	var t: TecladoDoNome = teclados[l]
	if _robo_espera[l] > 0.0:
		return
	_robo_espera[l] = 0.12
	if l != 0:
		if _robo_teclado[l] == 1:
			_robo_teclado[l] = 2
			Forja.robo_apertar(l, Forja.TRIANGULO)
		elif t.no_pronto() and not t.pode_gravar():
			Forja.robo_apertar(l, Forja.TRIANGULO)
		elif t.no_pronto():
			Forja.robo_apertar(l, Forja.CRUZ)
		return
	var alvo := ROBO_NOME
	var feito := t.texto
	var certo := TecladoDoNome.formatar(alvo)
	if feito == certo:
		_robo_alvo_do_cursor(l, Vector2i(TecladoDoNome.PRIMEIRA_DO_PRONTO, TecladoDoNome.LINHAS - 1))
		return
	if not certo.begins_with(feito):
		_robo_erro_do_teclado[l] = false
		Forja.robo_apertar(l, Forja.CIRCULO)
		return
	if _robo_teclado[l] == 1 and feito.length() == 3:
		_robo_teclado[l] = 2
		_robo_erro_do_teclado[l] = not Forja.robo_acerta()
	var proxima := certo.substr(feito.length(), 1).to_upper()
	if _robo_erro_do_teclado[l]:
		proxima = "Z"
	if proxima == " ":
		_robo_alvo_do_cursor(l, Vector2i(6, 3))
		return
	_robo_alvo_do_cursor(l, _tecla_da_letra(proxima))


func _robo_alvo_do_cursor(l: int, alvo: Vector2i) -> void:
	var t: TecladoDoNome = teclados[l]
	var c := t.cursor
	if t.no_pronto() and alvo.y == TecladoDoNome.LINHAS - 1 and alvo.x >= TecladoDoNome.PRIMEIRA_DO_PRONTO:
		Forja.robo_apertar(l, Forja.CRUZ)
		return
	if c == alvo:
		Forja.robo_apertar(l, Forja.CRUZ)
	elif c.x != alvo.x:
		Forja.robo_apertar(l, Forja.DIREITA if alvo.x > c.x else Forja.ESQUERDA)
	else:
		Forja.robo_apertar(l, Forja.BAIXO if alvo.y > c.y else Forja.CIMA)


static func _tecla_da_letra(letra: String) -> Vector2i:
	for r in TecladoDoNome.LINHAS:
		for c in TecladoDoNome.COLUNAS:
			if TecladoDoNome.GRADE[r][c] == letra:
				return Vector2i(c, r)
	return Vector2i(0, 0)


func _draw() -> void:
	for i in 30:
		draw_rect(Rect2(0, 800 + i * 6, size.x, 6), Color(Tema.FITA, 0.82 * i / 30.0))
	draw_rect(Rect2(0, 980, size.x, size.y - 980), Color(Tema.FITA, 0.82))
	if contagem >= 0.0:
		Desenho.texto(self, Vector2(0, 1000), "Todos prontos", Tema.archivo(600), Tema.T_CORPO, Tema.ETIQUETA,
			HORIZONTAL_ALIGNMENT_CENTER, size.x)
	else:
		var escrevendo := false
		for t in teclados:
			escrevendo = escrevendo or t != null
		if escrevendo:
			Desenho.dicas_a_esquerda(self, Vector2(196, 1022),
				[["cruz", "Escolher"], ["circulo", "Apagar"], ["triangulo", "Sortear"], ["r1", "Pronto"]])
		else:
			Desenho.dicas_a_esquerda(self, Vector2(196, 1000),
				[["cruz", "Forjar"], ["triangulo", "Sortear"], ["esquerda", "Trocar"], ["r1", "Escrever"], ["circulo", "Voltar"]])


func _ocupados(l: int) -> Dictionary:
	var o := {}
	for j in 4:
		if j != l and Forja.ocupado(j) and jogadores.size() > j and jogadores[j].pecas.size() == 3:
			o[j] = jogadores[j].cavaleiro()
	return o


static func _indice_do_item(id: String) -> int:
	for i in ForjaPlayer.ITENS.size():
		if str(ForjaPlayer.ITENS[i].id) == id:
			return i
	return 1


func _pecas_pedidas(l: int) -> Array:
	var v: Array = jogadores[l].pecas.duplicate()
	for k in 3:
		if _encaixe[l].has(k):
			v[k] = _encaixe[l][k].valor
	return v


func _proxima_peca(l: int, k: int, atual: String, passo: int) -> String:
	var P := Cavaleiro.PERSONAGENS
	var i := maxi(0, P.find(atual))
	var unica := Cavaleiro.regra("cabeca_unica_na_mesa") == "sim"
	var cabecas_dos_outros: Array = []
	for c in _ocupados(l).values():
		cabecas_dos_outros.append(str(c.get("cabeca", "")))
	var base := _pecas_pedidas(l)
	for n in P.size() - 1:
		i = wrapi(i + passo, 0, P.size())
		var t := base.duplicate()
		t[k] = P[i]
		if not Cavaleiro.corpo(t).valido:
			continue
		if k == CABECA and unica and P[i] in cabecas_dos_outros:
			continue
		return P[i]
	return atual


func _proximo_item(l: int, atual: int, passo: int) -> int:
	var st: Array = Cavaleiro.corpo(_pecas_pedidas(l)).stats
	var i := atual
	for n in 5:
		i = (i - 1 + passo + 6) % 6 + 1
		if Cavaleiro.no_corpo(str(ForjaPlayer.ITENS[i].id), st) != "fora":
			return i
	return atual


func _pedir_encaixe(l: int, k: int, valor) -> void:
	var agora := Ritmo.t_musica()
	var roleta: bool = _ultimo_toque[l] >= 0.0 and agora - _ultimo_toque[l] < ROLETA_S
	_ultimo_toque[l] = agora
	_encaixe[l][k] = {"t": Ritmo.t_da_batida(ceilf(Ritmo.batida() * 4.0) / 4.0), "valor": valor,
		"quadro": Engine.get_process_frames(), "roleta": roleta, "toque": agora}
	_pose[l] = -1.0


func _servir_o_encaixe(l: int) -> void:
	var agora := Ritmo.t_musica()
	for k in _encaixe[l].keys():
		var e: Dictionary = _encaixe[l][k]
		if agora >= float(e.t) and Engine.get_process_frames() > int(e.quadro):
			_encaixe[l].erase(k)
			ultimo_encaixe[l] = {"linha": int(k), "t": float(e.t), "toque": float(e.toque), "quadro_do_toque": int(e.quadro),
				"quadro": Engine.get_process_frames(), "agora": agora}
			_encaixar(l, int(k), e)
	if _pose[l] >= 0.0 and agora >= _pose[l] and _encaixe[l].is_empty():
		_pose[l] = -1.0
		_fazer_a_pose(l, _pose_linha[l])
	if not _na_batida[l].is_empty() and agora >= float(_na_batida[l].t) and _encaixe[l].is_empty():
		_bater_a_batida(l)


func _encaixar(l: int, k: int, e: Dictionary) -> void:
	var p: ForjaPlayer = jogadores[l]
	var antes: Dictionary = corpo[l]
	if _na_batida[l].is_empty() and not antes.is_empty():
		var id_antes := str(ForjaPlayer.ITENS[p.item_i].id)
		_na_batida[l] = {"arquetipo": str(antes.arquetipo.get("id", "")),
			"liga": Cavaleiro.no_corpo(id_antes, antes.stats) == "liga", "boa": Cavaleiro.build_boa(antes, id_antes)}
	if k == ITEM:
		p.visual(p.modelo_i, int(e.valor))
		_sentir_o_item(l)
	else:
		p.trocar_peca(k, str(e.valor))
		Som.tocar("ui_peca", null, -12.0, TOM_DA_PARTE[k])
		Som.no_controle(l, "ui_peca", 0.85)
		Forja.sentir(l, "metal")
		p.acender_acento()
		corpo[l] = Cavaleiro.corpo(p.pecas)
		_ajustar_o_item(l)
	corpo[l] = Cavaleiro.corpo(p.pecas)
	if salao:
		Efeitos.faiscas(salao, p.global_position + Vector3(0, JUNTA[k], 0), Tema.JOGADOR[l], 4 if bool(e.roleta) else 8, 2.4)
	_pose[l] = Ritmo.t_musica() + ROLETA_S
	_pose_linha[l] = k
	_na_batida[l]["t"] = Ritmo.t_da_batida(floorf(Ritmo.batida()) + 1.0)


func _ajustar_o_item(l: int) -> void:
	var p: ForjaPlayer = jogadores[l]
	if Cavaleiro.no_corpo(str(ForjaPlayer.ITENS[p.item_i].id), corpo[l].stats) != "fora":
		return
	var novo := _proximo_item(l, p.item_i, 1)
	if novo != p.item_i:
		p.visual(p.modelo_i, novo)
		Itens.escolhido[l] = p.item_i
		Itens.sentir(l)


func _fazer_a_pose(l: int, k: int) -> void:
	var p: ForjaPlayer = jogadores[l]
	if k < ITEM:
		p.gesto(POSE[k], 0.8)
		if k == CABECA:
			Som.pio(l, p.modelo_i)
	elif k == ITEM:
		var id := str(ForjaPlayer.ITENS[p.item_i].id)
		if str(Cavaleiro.item(id).get("tipo", "")) == "amuleto":
			p.gesto("interact-right", 0.8)
		else:
			p.gesto("attack-melee-left" if id == "escudo" else "attack-melee-right", 0.8)


func _bater_a_batida(l: int) -> void:
	var antes: Dictionary = _na_batida[l]
	_na_batida[l] = {}
	var id := str(ForjaPlayer.ITENS[jogadores[l].item_i].id)
	var c: Dictionary = corpo[l]
	if str(c.arquetipo.get("id", "")) != str(antes.get("arquetipo", "")):
		Som.tocar("fx_caneta", null, -6.0)
	if Cavaleiro.no_corpo(id, c.stats) == "liga" and not bool(antes.get("liga", false)):
		ligou[l] += 1
		if visor:
			visor.bater(l, "car_liga", cartoes[l].position + Vector2(CartaoJogador.X0 + CartaoJogador.LARGURA * 0.5, 630.0))
		else:
			Som.tocar("car_liga", null, -9.0)
			Forja.sentir(l, "acerto")
	if Cavaleiro.build_boa(c, id) and not bool(antes.get("boa", false)):
		Som.tocar("fx_caneta", null, -6.0)


func _acender_a_parte(l: int, n: int) -> void:
	var p: ForjaPlayer = jogadores[l]
	var k := clampi(floori((n - 1) / 2.0), 0, 3)
	if n <= 6:
		p.acender_parte(Cavaleiro.PARTES[k], 0.5 if n % 2 == 1 else 1.0)
	elif n == 7:
		p.acender_parte("item", 1.0)
	else:
		Som.tocar("fx_caneta", null, -6.0)
	if salao and n <= 7:
		var luz := OmniLight3D.new()
		luz.light_color = Tema.TUNGSTENIO
		luz.light_energy = 1.2
		luz.omni_range = 1.2
		luz.shadow_enabled = false
		salao.add_child(luz)
		luz.global_position = p.global_position + Vector3(0, JUNTA[k], 0.3)
		var tw := luz.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(luz, "light_energy", 0.0, 0.25)
		tw.tween_callback(luz.queue_free)


func _corpo_sorteado(l: int, rng: RandomNumberGenerator) -> Array:
	var P := Cavaleiro.PERSONAGENS
	var cabecas_dos_outros: Array = []
	for c in _ocupados(l).values():
		cabecas_dos_outros.append(str(c.get("cabeca", "")))
	for vez in 400:
		var t := [P[rng.randi_range(0, 11)], P[rng.randi_range(0, 11)], P[rng.randi_range(0, 11)]]
		if Cavaleiro.corpo(t).valido and not (t[0] in cabecas_dos_outros):
			return t
	return jogadores[l].pecas.duplicate()


func _robo_troca(l: int) -> bool:
	var tr: Dictionary = _troca_do_pre[l]
	if tr.is_empty() or _robo_toques[l] > 14:
		_robo_trocou[l] = true
		return false
	var k := int(tr.parte)
	var falta_a_peca := str(_pecas_pedidas(l)[k]) != str(tr.personagem)
	if falta_a_peca and linha[l] != k:
		Forja.robo_apertar(l, Forja.BAIXO if linha[l] < k else Forja.CIMA)
		_robo_espera[l] = 0.25
		return true
	if falta_a_peca:
		Forja.robo_apertar(l, Forja.DIREITA)
		_robo_toques[l] += 1
		_robo_espera[l] = 0.25
		return true
	if not _encaixe[l].is_empty() or not _na_batida[l].is_empty():
		return true
	var i_pre := _indice_do_item(str(tr.get("item", "")))
	if jogadores[l].item_i != i_pre and _robo_toques[l] <= 14:
		if linha[l] != ITEM:
			Forja.robo_apertar(l, Forja.BAIXO if linha[l] < ITEM else Forja.CIMA)
		else:
			Forja.robo_apertar(l, Forja.DIREITA)
			_robo_toques[l] += 1
		_robo_espera[l] = 0.25
		return true
	_robo_trocou[l] = true
	return false
