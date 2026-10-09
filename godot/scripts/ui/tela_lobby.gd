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
	contagem = -1.0
	_batida_vista = -1
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
	var guardado: Dictionary = Opcoes.cavaleiro[l]
	if Opcoes.noite_dos_cavaleiros == Opcoes.noite() and not guardado.is_empty():
		p.vestir(guardado)
		desvio[l] = Opcoes.tempo_ms[l] / 1000.0
		etapa[l] = GUARDADO
	else:
		etapa[l] = EDITANDO
		p.visual(ForjaPlayer.VISUAL_DO_LUGAR[l][0], ForjaPlayer.VISUAL_DO_LUGAR[l][1])
		p.nome = _nome_livre(l, 1, (Forja.semente * 7 + l * 5) % NOMES.size() - 1)
	p.acender(1.0)
	salao.acender_bigorna(l, 1.5)
	Som.pio(l, p.modelo_i)
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


## A troca do item, na TV e na mão (a G03 troca o corpo: o gatilho do item).
func _sentir_o_item(l: int) -> void:
	Som.tocar("ui_peca", null, -12.0, 0.7492)
	Som.no_controle(l, "ui_peca", 0.85)
	Forja.sentir(l, "acerto")


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
	Forja.evento("cavaleiro", l + 1, jogadores[l].cavaleiro())
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
	if _robo_espera[l] > 0.0 or etapa[l] == FORJADO:
		return
	Forja.robo_apertar(l, Forja.CRUZ)   # EDITANDO: começa a forja; GUARDADO: confirma
	_robo_espera[l] = 0.9 + 0.1 * l + (0.0 if Forja.robo_acerta() else 1.5)


func _draw() -> void:
	# a tarja de baixo, atrás das marteladas e das dicas
	for i in 30:
		draw_rect(Rect2(0, 800 + i * 6, size.x, 6), Color(Tema.CASA, 0.82 * i / 30.0))
	draw_rect(Rect2(0, 980, size.x, size.y - 980), Color(Tema.CASA, 0.82))
	if contagem >= 0.0:
		Desenho.texto(self, Vector2(0, 1000), "Todos prontos", Tema.fonte(600), Tema.T_CORPO, Tema.VERDE,
			HORIZONTAL_ALIGNMENT_CENTER, size.x)
	else:
		Desenho.dicas_a_esquerda(self, Vector2(196, 1000),
			[["cruz", "Forjar"], ["triangulo", "Sortear"], ["esquerda", "Trocar"], ["circulo", "Voltar"]])
