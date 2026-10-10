class_name TelaLobby
extends Control
## A construção do cavaleiro (o estado continua "lobby"): cada lugar ocupado tem
## a sua coluna de 432 px, três linhas (Boneco, Arma ou amuleto, Nome) e as
## oito marteladas na batida que forjam o cavaleiro e, sem ninguém ver, medem o
## atraso de cada controle. A tela inteira roda na música da construção, a 120
## BPM. Quem volta na mesma noite acha o cavaleiro guardado. A partida começa
## 1,6 s depois de todo lugar ocupado e com controle estar forjado.

const BONECO := 0
const ITEM := 1
const NOME := 2
const LINHAS := ["Boneco", "Arma ou amuleto", "Nome"]
## O que a coluna escreve: "Arma ou amuleto" mede 243 px e o rótulo tem 124.
const ROTULO_CURTO := ["Boneco", "Arma", "Nome"]
const EDITANDO := 0
const FORJANDO := 1
const FORJADO := 2
const GUARDADO := 3
const MARTELADAS := 8
const ROBO_ATRASO_S := 0.033   ## o robô do lugar l martela l × 33 ms depois da batida
## Os 24 de docs/jogo/sistemas/nomes.csv, na ordem do arquivo (a G13 passa a ler o csv).
const NOMES := ["Basalto", "Granito", "Bronze", "Tenaz", "Rebite", "Ferrugem",
	"Obsidiana", "Ônix", "Titânio", "Cobalto", "Quartzo", "Cinzel",
	"Brasa", "Carvão", "Latão", "Estanho", "Níquel", "Âmbar",
	"Faísca", "Magnésio", "Cromo", "Safira", "Pirita", "Grafite"]
const LARGURA_DA_COLUNA := 432.0

var prontos := [false, false, false, false]   ## continua: o main conta por ele
var contagem := -1.0
var etapa := [EDITANDO, EDITANDO, EDITANDO, EDITANDO]
var linha := [0, 0, 0, 0]
var golpes := [[], [], [], []]                ## o desvio de cada martelada, em s
var desvio := [0.0, 0.0, 0.0, 0.0]
var jogadores: Array = []                     ## o main põe em _interface()
var salao: Node = null                        ## idem
var cartoes: Array[CartaoJogador] = []
var _robo_espera := [0.0, 0.0, 0.0, 0.0]
var _robo_batida := [0, 0, 0, 0]
var _robo_erro := [0.0, 0.0, 0.0, 0.0]
var _batida_vista := -1
var _sorteios := [0, 0, 0, 0]
var _entrou_agora := [false, false, false, false]   ## o ✕ que confirmou o lugar não é o da forja
## O teclado do nome de cada lugar (G09): aberto com R1 na linha Nome, um por lugar.
var teclados: Array = [null, null, null, null]
var nome_escrito := [false, false, false, false]    ## o nome gravado foi digitado (não o sorteado sem mudança)
var t_nome_ms := [0, 0, 0, 0]                       ## quanto tempo o teclado ficou aberto, em ms de parede
var _nome_antes := ["", "", "", ""]                 ## o nome de antes de abrir: volta com o campo vazio e ◯
var _robo_teclado := [0, 0, 0, 0]                   ## o passo do robô no teclado
var _robo_erro_do_teclado := [false, false, false, false]


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


## Zera tudo ao entrar no lobby; cada lugar já ocupado passa por entrou(l).
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
	Itens.novo_minigame()   # o Escudo volta inteiro na construção: a última sala pode tê-lo quebrado (G03)
	for l in 4:
		if Forja.ocupado(l):
			entrou(l)
	_entrou_agora = [false, false, false, false]


## O lugar acabou de confirmar (F04): o cavaleiro guardado desta noite, ou o
## inicial dele.
func entrou(l: int) -> void:
	var p: ForjaPlayer = jogadores[l]
	golpes[l] = []
	prontos[l] = false
	linha[l] = 0
	teclados[l] = null
	nome_escrito[l] = false
	t_nome_ms[l] = 0
	_robo_teclado[l] = 0
	var guardado: Dictionary = Opcoes.cavaleiro[l]
	if Opcoes.noite_dos_cavaleiros == Opcoes.noite() and not guardado.is_empty():
		p.vestir(guardado)
		desvio[l] = Opcoes.tempo_ms[l] / 1000.0
		etapa[l] = GUARDADO
	else:
		etapa[l] = EDITANDO
		p.visual(ForjaPlayer.VISUAL_DO_LUGAR[l][0], ForjaPlayer.VISUAL_DO_LUGAR[l][1])
		p.nome = _nome_livre(l, 1, (Forja.semente * 7 + l * 5) % NOMES.size() - 1)
	Itens.escolhido[l] = p.item_i
	Itens.sentir(l)
	p.acender(1.0)
	salao.acender_bigorna(l, 1.5)
	# o pio de quem entra é o do main.gd (_abrir_o_som), um só por entrada (H07b)
	_robo_espera[l] = 1.2   # o robô espera um instante antes de forjar (a tela da construção não fica parada mais de 5 s)
	_entrou_agora[l] = true


## O próximo nome (a `passo` ±1) que nenhum outro lugar ocupado usa, a partir
## de `base` (o índice atual, se omitido).
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


## Os botões da tabela, nos quatro lugares. `dx` e `dy` são o passo do analógico
## ou do d-pad de cada um (-1, 0 ou 1).
func quadro(dt: float, dx: Array, dy: Array) -> void:
	var b := floori(Ritmo.batida())
	if b != _batida_vista:
		_batida_vista = b
		for l in 4:
			if Forja.ocupado(l) and etapa[l] == FORJANDO:
				Som.tocar("tique", null, -10.0)
				break
	for l in 4:
		if not Forja.ocupado(l):
			continue
		var p: ForjaPlayer = jogadores[l]
		if teclados[l] != null:
			_quadro_do_teclado(l)   # o teclado aberto toma os botões deste lugar, e só deste
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
					var nova := clampi(linha[l] + dy[l], BONECO, NOME)
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


# ------------------------------------------------------------ o teclado --

## Os nomes que os outros lugares ocupados já têm (o único na mesa).
func _nomes_dos_outros(l: int) -> Array:
	var nomes: Array = []
	for j in 4:
		if j != l and Forja.ocupado(j) and jogadores.size() > j and str(jogadores[j].nome) != "":
			nomes.append(TecladoDoNome.nome_final(str(jogadores[j].nome)))
	return nomes


## R1 na linha Nome: abre o teclado com o nome de agora no campo.
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


## O som de uma tecla que entrou: a TV a −12 dB e o clique do módulo na mão do dono.
func _som_da_tecla(l: int) -> void:
	Som.tocar("ui_tecla", null, -12.0)
	Forja.som_falante(l, "clique")
	Forja.sentir(l, "toque")


func _som_do_cursor(l: int) -> void:
	Som.tocar("ui_tique", null, -12.0)
	Som.no_controle(l, "ui_tique", 0.6)
	Forja.sentir(l, "toque")


## O relógio da repetição do direcional no teclado: o de parede, como a ficha G09 manda. A prova troca
## pelo relógio do jogo, para um aperto de dois quadros não repetir a tecla quando a máquina está carregada.
var relogio_do_teclado := func() -> int: return Time.get_ticks_msec()


## Os botões do lugar com o teclado aberto (a tabela da ficha G09).
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
					Forja.sentir(l, "toque")   # o Pronto apagado: só a mão responde
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


## △ no teclado: um nome do arquétipo que ninguém usa, no campo, e o cursor em Pronto.
func _sortear_o_nome(l: int) -> void:
	var t: TecladoDoNome = teclados[l]
	var livres := nomes_para_sortear(l)
	var rng := RandomNumberGenerator.new()
	rng.seed = Forja.semente * 31 + l + 1000 * _sorteios[l]
	_sorteios[l] += 1
	t.sortear(str(livres[rng.randi_range(0, livres.size() - 1)]))
	_som_da_tecla(l)


## Os nomes que o △ do teclado pode pôr: os do arquétipo do lugar que ninguém da mesa usa.
## Hoje o lugar ainda não tem arquétipo (vem com a montagem em peças, G13): são os 24.
## Sem nenhum livre, qualquer um dos 24.
func nomes_para_sortear(l: int) -> Array:
	var usados := _nomes_dos_outros(l)
	var livres: Array = []
	for n in NOMES:
		if not (n in usados):
			livres.append(n)
	return livres if not livres.is_empty() else NOMES.duplicate()


## Fecha o teclado. `grava`: o Pronto (o nome do campo vai para o cavaleiro); senão o nome volta
## ao de antes de abrir.
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


## ○ editando: da linha 2 ou 3 à linha 1; da linha 1, sai do lugar.
func _voltar(l: int) -> void:
	_som_de_voltar(l)
	if linha[l] > BONECO:
		linha[l] = BONECO
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


## ◀ ▶ na linha escolhida.
func _trocar(l: int, passo: int) -> void:
	var p: ForjaPlayer = jogadores[l]
	match linha[l]:
		BONECO:
			p.visual(p.modelo_i + passo, p.item_i)
			_som_do_boneco(l)
		ITEM:
			p.visual(p.modelo_i, (p.item_i - 1 + passo + 6) % 6 + 1)   # os seis, em laço (nunca Mãos livres)
			_sentir_o_item(l)
		NOME:
			p.nome = _nome_livre(l, passo)
			Som.tocar("fx_caneta", null, -6.0)
			Forja.sentir(l, "metal")
	p.gesto("interact-right", 0.5)


## △: sorteia o boneco, o item e um nome livre. A semente é a da noite e o
## número de sorteios do lugar: a mesma noite sorteia igual.
func _sortear(l: int) -> void:
	var p: ForjaPlayer = jogadores[l]
	var rng := RandomNumberGenerator.new()
	rng.seed = Forja.semente * 31 + l + 1000 * _sorteios[l]
	_sorteios[l] += 1
	p.visual(rng.randi_range(0, 1), rng.randi_range(1, 6))
	p.nome = _nome_livre(l, 1, rng.randi_range(0, NOMES.size() - 1) - 1)
	p.gesto("interact-right", 0.5)
	_som_do_boneco(l)
	_sentir_o_item(l)


func _som_do_boneco(l: int) -> void:
	Som.tocar("ui_peca", null, -12.0, 1.0)
	Som.no_controle(l, "ui_peca", 0.85)
	Forja.sentir(l, "metal")


## A troca do item, na TV e na mão: a mecânica passa a ser a do que se escolheu
## (Itens.escolhido) e o L2 diz o item (Itens.sentir, G03).
func _sentir_o_item(l: int) -> void:
	Itens.escolhido[l] = jogadores[l].item_i
	Itens.sentir(l)
	Som.tocar("ui_peca", null, -12.0, 0.7492)
	Som.no_controle(l, "ui_peca", 0.85)
	Forja.sentir(l, "acerto")
	jogadores[l].acender_acento()   # o acento e a runa sobem a 2,6 e voltam (G08)


## Uma martelada: o desvio até a batida mais perto é a medida.
func martelar(l: int) -> void:
	var t := Ritmo.t_musica()
	var d := t - Ritmo.t_da_batida(roundf(Ritmo.batida()))   # até a batida mais perto, em s
	golpes[l].append(d)
	var k: float = golpes[l].size() / float(MARTELADAS)
	jogadores[l].acender(k)
	jogadores[l].gesto("attack-melee-right", 0.35)
	Som.tocar("martelo", jogadores[l].global_position, -4.0)
	Forja.sentir(l, "acerto")
	salao.acender_bigorna(l, 2.5 + k, 1.5 * k)   # a bigorna fica mais acesa a cada martelada
	if golpes[l].size() >= MARTELADAS:
		_forjou(l)


func _forjou(l: int) -> void:
	desvio[l] = mediana(golpes[l])
	Ritmo.definir_desvio(l, desvio[l], "construcao", golpes[l].size())  # Opcoes.tempo_ms e o evento calibracao
	Itens.escolhido[l] = jogadores[l].item_i
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
	Forja.evento("cavaleiro", l + 1, ev)
	Forja.registrar("P%d forjou o cavaleiro" % (l + 1))


## A mediana: ordena; ímpar, o do meio; par, a média dos dois do meio; vazio, 0.
static func mediana(v: Array) -> float:
	if v.is_empty():
		return 0.0
	var o := v.duplicate()
	o.sort()
	var n := o.size()
	if n % 2 == 1:
		return float(o[n / 2])
	return (float(o[n / 2 - 1]) + float(o[n / 2])) * 0.5


## O robô (--robo) constrói pelo controle simulado, como uma pessoa: ✕ para
## forjar e as oito marteladas na batida, o lugar l atrasado l × 33 ms.
func robo(l: int, dt: float) -> void:
	_robo_espera[l] -= dt
	if not Forja.ocupado(l):
		# o lugar só reservado (F04): o ✕ que confirma, como o robô da G01
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
			_robo_erro[l] = 0.0 if Forja.robo_acerta() else 0.12   # a mediana absorve um ou dois
		return
	if teclados[l] != null:
		_robo_escreve(l)
		return
	if _robo_espera[l] > 0.0 or etapa[l] == FORJADO:
		return
	if etapa[l] == EDITANDO and _robo_teclado[l] == 0:
		# o nome primeiro, pelo teclado: o lugar 1 escreve «Dona Brasa», os outros sorteiam
		if linha[l] < NOME:
			Forja.robo_apertar(l, Forja.BAIXO)
		else:
			Forja.robo_apertar(l, Forja.R1)
		_robo_espera[l] = 0.4
		return
	Forja.robo_apertar(l, Forja.CRUZ)   # EDITANDO: começa a forja; GUARDADO: confirma
	_robo_espera[l] = 0.9 + 0.1 * l + (0.0 if Forja.robo_acerta() else 1.5)


## O nome que o robô do lugar 1 escreve; os outros lugares apertam △ e ✕.
const ROBO_NOME := "DONA BRASA"


## O robô com o teclado aberto, só pelo controle simulado e olhando o cursor a cada quadro (um aperto
## perdido se corrige sozinho): anda até a tecla da próxima letra, aperta ✕; se `Forja.robo_acerta()`
## falhar uma vez, escreve a tecla vizinha e a apaga com a tecla ◯ do botão. No fim, Pronto.
func _robo_escreve(l: int) -> void:
	var t: TecladoDoNome = teclados[l]
	if _robo_espera[l] > 0.0:
		return
	_robo_espera[l] = 0.12
	if l != 0:
		# △ sorteia e leva o cursor a Pronto; ✕ fecha
		if _robo_teclado[l] == 1:
			_robo_teclado[l] = 2
			Forja.robo_apertar(l, Forja.TRIANGULO)
		elif t.no_pronto() and not t.pode_gravar():
			# outro lugar gravou o mesmo nome antes: o Pronto apagou, sorteia de novo
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
		# o que sobrou de errado: apaga com o botão ◯
		_robo_erro_do_teclado[l] = false
		Forja.robo_apertar(l, Forja.CIRCULO)
		return
	if _robo_teclado[l] == 1 and feito.length() == 3:
		_robo_teclado[l] = 2   # decide uma vez: a quarta letra sai errada quando o robô não acerta
		_robo_erro_do_teclado[l] = not Forja.robo_acerta()
	var proxima := certo.substr(feito.length(), 1).to_upper()
	if _robo_erro_do_teclado[l]:
		proxima = "Z"   # um erro de mão, apagado em seguida com ◯
	if proxima == " ":
		_robo_alvo_do_cursor(l, Vector2i(6, 3))
		return
	_robo_alvo_do_cursor(l, _tecla_da_letra(proxima))


## Um passo do robô até a tecla `alvo`; no lugar, ✕.
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
	# a tarja de baixo, atrás das marteladas e das dicas
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
			# a última linha de teclas termina em y 1000: as dicas descem para dentro da área segura
			Desenho.dicas_a_esquerda(self, Vector2(196, 1022),
				[["cruz", "Escolher"], ["circulo", "Apagar"], ["triangulo", "Sortear"], ["r1", "Pronto"]])
		else:
			Desenho.dicas_a_esquerda(self, Vector2(196, 1000),
				[["cruz", "Forjar"], ["triangulo", "Sortear"], ["esquerda", "Trocar"], ["r1", "Escrever"], ["circulo", "Voltar"]])
