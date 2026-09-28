extends Node
## A sessão do jogo (autoload «Forja»): o módulo nativo, os lugares P1..P4, a
## entrada por lugar e as saídas por lugar.
##
## O módulo (a GDExtension com o SDL3 dentro, ver nativo/) fala com os DualSense
## como a Sony e a Steam documentam: o payload USB 0x02 que o SDL monta, player
## index 0..3, os quatro modos de gatilho. O jogo nunca vê endereço de aparelho:
## só o lugar (0..3) e o índice do controle na lista do módulo.
##
## Sem o módulo (a biblioteca não foi compilada), o jogo ainda abre: o teclado
## joga como P1 e as saídas não vão a lugar nenhum — a tela diz isso.
##
## Argumentos (depois de `--`):
##   --simular[=N]      N DualSense de mentira (4 se só --simular); o teclado joga no escolhido
##   --robo             o robô joga nos simulados (a prova de ponta a ponta)
##   --semente=N        os sorteios repetem
##   --relatorios=PASTA onde gravar o relatório (sem ele: ao lado do jogo)
##   --sala=ID          abre direto numa sala
##   --prova-de-fogo    abre na Prova de Fogo: todas as salas, na ordem, e o livro
##   --sair-no-fim      no fim da Prova de Fogo, grava o relatório e fecha o jogo
##   --experimento=ID   a bancada do experimental/ no lugar do salão
##   --defeitos=LISTA   defeitos de mentira nos simulados (a prova que morde)
##   --sem-modulo       finge que o módulo não existe

signal pads_mudaram
signal aviso(texto: String)

# Os botões e eixos, como o SDL3 os numera (e o módulo confere na abertura).
const CRUZ := 0
const CIRCULO := 1
const QUADRADO := 2
const TRIANGULO := 3
const CREATE := 4
const PS := 5
const OPTIONS := 6
const L3 := 7
const R3 := 8
const L1 := 9
const R1 := 10
const CIMA := 11
const BAIXO := 12
const ESQUERDA := 13
const DIREITA := 14
const MICROFONE := 15
const TOUCHPAD := 20

const LX := 0
const LY := 1
const RX := 2
const RY := 3
const L2 := 4
const R2 := 5

# Os quatro modos oficiais de gatilho. Nenhum outro existe neste jogo.
const GATILHO_OFF := 0
const GATILHO_RESISTENCIA := 1
const GATILHO_ARMA := 2
const GATILHO_VIBRACAO := 3

const PASSOU := 1
const FALHOU := 2
const NAO_MEDIDO := 0
const NIVEL_MONTOU := 1
const NIVEL_SAIU := 2
const NIVEL_OBEDECEU := 3
const NIVEL_REAGIU := 4

## As cores de luz dos lugares (as mesmas que o módulo manda à lightbar).
const COR_DO_LUGAR := [
	Color8(0, 72, 255), Color8(255, 24, 8), Color8(0, 255, 64), Color8(255, 8, 168),
]
## O padrão dos LEDs de jogador de cada lugar: 1 | vão | 3 | vão | 1.
const LEDS_DO_LUGAR := [0x04, 0x0A, 0x15, 0x1B]

var ctl = null  ## o ForjaControles, ou null sem o módulo (sem tipo: os métodos são do módulo)
var modulo := false
var simular := 0
var robo := false
var semente := 0
var pasta_relatorios := ""
var sala_pedida := ""
var experimento := ""  ## --experimento=CHAVE: a bancada do experimental/ no lugar do salão
var sim_teclado := 0  ## qual controle simulado o teclado dirige

var _args := {}
var _aviso_seq := 0
var _assinatura_pads := ""
var _teclas_antes := {}
var _teclas_agora := {}
var _mouse_giro := Vector2.ZERO


func _ready() -> void:
	process_priority = -101
	_ler_args()
	pasta_relatorios = _resolver_pasta()
	if ClassDB.class_exists("ForjaControles") and not _args.has("sem-modulo"):
		ctl = ClassDB.instantiate("ForjaControles")
		ctl.name = "Controles"
		ctl.process_priority = -100
		add_child(ctl)
		if _args.has("defeitos"):
			var erro: String = ctl.defeitos(str(_args["defeitos"]))
			if erro != "":
				push_warning("defeitos: " + erro)
		modulo = ctl.abrir(pasta_relatorios, simular, robo, semente)
		if modulo:
			_conferir_numeros()
			semente = ctl.semente()
	if not modulo:
		push_warning("FORJA sem o módulo nativo: só o teclado, e nenhuma saída chega a controle")


func _exit_tree() -> void:
	if modulo:
		ctl.fechar()


func _ler_args() -> void:
	var todos := OS.get_cmdline_user_args()
	for a in todos:
		if not a.begins_with("--"):
			continue
		var kv := a.substr(2).split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else ""
	if _args.has("simular"):
		simular = int(_args["simular"]) if str(_args["simular"]) != "" else 4
		simular = clampi(simular, 1, 4)
	robo = _args.has("robo")
	if robo and simular == 0:
		simular = 4
	semente = int(_args.get("semente", "0"))
	sala_pedida = str(_args.get("sala", ""))
	experimento = str(_args.get("experimento", ""))


## A pasta do relatório, resolvida agora e nunca escrita no código: a pedida,
## ou ao lado do executável (o que quem valida acha sem procurar), ou a pasta
## de dados do usuário quando ali não dá para escrever. Rodando do projeto, a
## pasta `relatorios/` da raiz do repositório.
func _resolver_pasta() -> String:
	if _args.has("relatorios"):
		return str(_args["relatorios"])
	var candidata := ""
	if OS.has_feature("editor"):
		candidata = ProjectSettings.globalize_path("res://").path_join("../relatorios").simplify_path()
	else:
		candidata = OS.get_executable_path().get_base_dir().path_join("relatorios")
	if DirAccess.make_dir_recursive_absolute(candidata) == OK and _da_para_escrever(candidata):
		return candidata
	return ProjectSettings.globalize_path("user://relatorios")


func _da_para_escrever(pasta: String) -> bool:
	var teste := pasta.path_join(".forja-escreve")
	var f := FileAccess.open(teste, FileAccess.WRITE)
	if f == null:
		return false
	f.close()
	DirAccess.remove_absolute(teste)
	return true


func _conferir_numeros() -> void:
	var pares := [
		[CRUZ, ctl.BOTAO_CRUZ], [CIRCULO, ctl.BOTAO_CIRCULO], [OPTIONS, ctl.BOTAO_OPTIONS],
		[CREATE, ctl.BOTAO_CREATE], [TOUCHPAD, ctl.BOTAO_TOUCHPAD], [MICROFONE, ctl.BOTAO_MICROFONE],
		[R2, ctl.EIXO_R2], [GATILHO_ARMA, ctl.GATILHO_ARMA], [PASSOU, ctl.PASSOU],
		[NIVEL_REAGIU, ctl.NIVEL_REAGIU],
	]
	for p in pares:
		assert(p[0] == p[1], "a numeração do jogo e a do módulo discordam")


func _process(_dt: float) -> void:
	_teclas_antes = _teclas_agora
	_teclas_agora = {}
	for k in _TECLAS:
		if Input.is_physical_key_pressed(k):
			_teclas_agora[k] = true
	if modulo and simular > 0 and not robo:
		_teclado_no_simulado()
	if not modulo:
		return
	var seq: int = ctl.aviso_seq()
	if seq != _aviso_seq:
		_aviso_seq = seq
		aviso.emit(ctl.aviso())
	var assinatura := ""
	for p in ctl.pads():
		assinatura += "%d:%d:%s;" % [p.pad, p.lugar, p.conexao_curta]
	if assinatura != _assinatura_pads:
		_assinatura_pads = assinatura
		pads_mudaram.emit()


# ---------------------------------------------------------------- o teclado --

## As teclas que o jogo lê. Com o módulo e controles simulados, elas viram o
## controle simulado escolhido (o caminho inteiro do módulo roda); sem módulo,
## elas são o P1.
const _TECLAS := [
	KEY_W, KEY_A, KEY_S, KEY_D, KEY_I, KEY_J, KEY_K, KEY_L,
	KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT,
	KEY_SPACE, KEY_ENTER, KEY_BACKSPACE, KEY_Q, KEY_E, KEY_ESCAPE, KEY_TAB,
	KEY_F, KEY_G, KEY_R, KEY_T, KEY_C, KEY_V, KEY_M, KEY_P, KEY_Z, KEY_1, KEY_2, KEY_3, KEY_4,
]
const _TECLA_BOTAO := {
	KEY_SPACE: CRUZ, KEY_ENTER: CRUZ, KEY_BACKSPACE: CIRCULO, KEY_Q: QUADRADO, KEY_E: TRIANGULO,
	KEY_UP: CIMA, KEY_DOWN: BAIXO, KEY_LEFT: ESQUERDA, KEY_RIGHT: DIREITA,
	KEY_R: L1, KEY_T: R1, KEY_C: L3, KEY_V: R3, KEY_ESCAPE: OPTIONS, KEY_TAB: CREATE,
	KEY_M: MICROFONE, KEY_P: TOUCHPAD,
}


func tecla(k: int) -> bool:
	return _teclas_agora.has(k)


func tecla_apertou(k: int) -> bool:
	return _teclas_agora.has(k) and not _teclas_antes.has(k)


func _eixo_teclas(menos: int, mais: int) -> float:
	return (1.0 if tecla(mais) else 0.0) - (1.0 if tecla(menos) else 0.0)


func _teclado_no_simulado() -> void:
	# Ctrl+1..4 troca o controle simulado que o teclado dirige
	if Input.is_key_pressed(KEY_CTRL):
		for i in 4:
			if tecla_apertou(KEY_1 + i) and i < simular:
				sim_teclado = i
				ctl.simulador_selecionar(i)
		return
	var s := sim_teclado
	for k in _TECLA_BOTAO:
		if tecla_apertou(k) or (_teclas_antes.has(k) and not tecla(k)):
			ctl.simulador_botao(s, _TECLA_BOTAO[k], tecla(k))
	ctl.simulador_eixo(s, LX, _eixo_teclas(KEY_A, KEY_D))
	ctl.simulador_eixo(s, LY, _eixo_teclas(KEY_W, KEY_S))
	ctl.simulador_eixo(s, RX, _eixo_teclas(KEY_J, KEY_L))
	ctl.simulador_eixo(s, RY, _eixo_teclas(KEY_I, KEY_K))
	ctl.simulador_eixo(s, L2, 1.0 if tecla(KEY_G) else 0.0)
	ctl.simulador_eixo(s, R2, 1.0 if tecla(KEY_F) else 0.0)
	# Z segurado é falar no microfone do controle simulado
	ctl.simulador_falar(s, 0.8 if tecla(KEY_Z) else 0.0)
	# o mouse com o botão direito apertado vira o giroscópio
	var g := Vector3.ZERO
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		g = Vector3(_mouse_giro.y, _mouse_giro.x, 0.0) * 0.6
	_mouse_giro = Vector2.ZERO
	ctl.simulador_giro(s, g)


func _input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		_mouse_giro += e.relative


# ---------------------------------------------------------------- os lugares --

func conectados() -> int:
	return ctl.conectados() if modulo else 0


func jogadores() -> int:
	if modulo:
		return ctl.jogadores()
	return 1


## A lista dos controles que o módulo vê, na ordem dele.
func pads() -> Array:
	return ctl.pads() if modulo else []


func pad(indice: int) -> Dictionary:
	return ctl.pad(indice) if modulo else {}


func pad_do_lugar(lugar: int) -> int:
	return ctl.pad_do_lugar(lugar) if modulo else -1


## O estado do lugar: ocupado, conectado, qual controle, a cor, os LEDs.
func lugar(l: int) -> Dictionary:
	if modulo:
		return ctl.lugar(l)
	return {
		"lugar": l, "rotulo": "P%d" % (l + 1), "ocupado": l == 0, "conectado": l == 0, "pad": -1,
		"desconectado_ha": 0.0, "reconexoes": 0, "cor": COR_DO_LUGAR[l], "leds": LEDS_DO_LUGAR[l],
	}


func ocupado(l: int) -> bool:
	return bool(lugar(l).get("ocupado", false))


func entrar(indice: int) -> int:
	return ctl.entrar(indice) if modulo else -1


func sair(l: int) -> void:
	if modulo:
		ctl.sair(l)


## O jogo sem controle nenhum: o teclado vira um DualSense simulado (o caminho
## inteiro do módulo roda, e o relatório diz que foi de mentira).
func jogar_no_teclado() -> bool:
	if not modulo or simular > 0:
		return false
	if ctl.simular(1):
		simular = 1
		sim_teclado = 0
		return true
	return false


# ---------------------------------------------------------------- a entrada --

func apertou(l: int, botao: int) -> bool:
	if modulo:
		return ctl.apertou(l, botao)
	return l == 0 and _teclado_apertou(botao)


func segura(l: int, botao: int) -> bool:
	if modulo:
		return ctl.segura(l, botao)
	return l == 0 and _teclado_segura(botao)


func soltou(l: int, botao: int) -> bool:
	return ctl.soltou(l, botao) if modulo else false


func pad_apertou(indice: int, botao: int) -> bool:
	return ctl.pad_apertou(indice, botao) if modulo else false


## Algum lugar apertou o botão? Devolve o lugar, ou -1.
func quem_apertou(botao: int) -> int:
	for l in 4:
		if apertou(l, botao):
			return l
	return -1


func eixo(l: int, e: int) -> float:
	if modulo:
		return ctl.eixo(l, e)
	if l != 0:
		return 0.0
	match e:
		LX: return _eixo_teclas(KEY_A, KEY_D)
		LY: return _eixo_teclas(KEY_W, KEY_S)
		RX: return _eixo_teclas(KEY_J, KEY_L)
		RY: return _eixo_teclas(KEY_I, KEY_K)
		L2: return 1.0 if tecla(KEY_G) else 0.0
		R2: return 1.0 if tecla(KEY_F) else 0.0
	return 0.0


## O analógico esquerdo (e o d-pad), com zona morta e limitado ao círculo.
func mover(l: int) -> Vector2:
	var v := Vector2(eixo(l, LX), eixo(l, LY))
	if segura(l, ESQUERDA):
		v.x -= 1.0
	if segura(l, DIREITA):
		v.x += 1.0
	if segura(l, CIMA):
		v.y -= 1.0
	if segura(l, BAIXO):
		v.y += 1.0
	if v.length() < 0.16:
		return Vector2.ZERO
	return v.limit_length(1.0)


func giro(l: int) -> Vector3:
	return ctl.giro(l) if modulo else Vector3.ZERO


func acel(l: int) -> Vector3:
	return ctl.acel(l) if modulo else Vector3.ZERO


## Um dedo no touchpad: x e y de 0 a 1, z = 1 se encostado.
func dedo(l: int, i: int) -> Vector3:
	return ctl.dedo(l, i) if modulo else Vector3.ZERO


func postura(l: int) -> Vector2:
	return ctl.postura(l) if modulo else Vector2.ZERO


func giro_hz(l: int) -> float:
	return ctl.giro_hz(l) if modulo else 0.0


func _teclado_apertou(botao: int) -> bool:
	for k in _TECLA_BOTAO:
		if _TECLA_BOTAO[k] == botao and tecla_apertou(k):
			return true
	return false


func _teclado_segura(botao: int) -> bool:
	for k in _TECLA_BOTAO:
		if _TECLA_BOTAO[k] == botao and tecla(k):
			return true
	return false


# ---------------------------------------------------------------- as saídas --

## Os dois motores: forte (esquerda, o contrapeso grande) e fraco (direita).
func vibrar(l: int, forte: float, fraco: float, ms: int) -> bool:
	return ctl.vibrar(l, forte, fraco, ms) if modulo else false


func luz(l: int, cor: Color) -> bool:
	return ctl.luz(l, cor) if modulo else false


func luz_do_lugar(l: int) -> bool:
	return ctl.luz_do_lugar(l) if modulo else false


## Um gatilho (lado 0 = L2, 1 = R2) num dos quatro modos oficiais.
func gatilho(l: int, lado: int, modo: int, a := 0, b := 0, c := 0) -> bool:
	return ctl.gatilho(l, lado, modo, a, b, c) if modulo else false


func gatilhos_off(l: int) -> bool:
	return ctl.gatilhos_off(l) if modulo else false


func led_mic(l: int, modo: int) -> bool:
	return ctl.led_mic(l, modo) if modulo else false


func leds_do_lugar(l: int) -> bool:
	return ctl.leds_do_lugar(l) if modulo else false


func leds_jogador(l: int, mascara: int) -> bool:
	return ctl.leds_jogador(l, mascara) if modulo else false


## O lugar volta ao repouso: motores parados, gatilhos soltos, a luz e os LEDs do lugar.
func silencio(l: int) -> void:
	if modulo:
		ctl.silencio(l)


func silencio_todos() -> void:
	if modulo:
		ctl.silencio_todos()


## O que o jogo mandou ao controle do lugar, do mais novo ao mais velho.
func saidas(l: int) -> PackedStringArray:
	return ctl.saidas(l) if modulo else PackedStringArray()


## O estado das saídas do lugar: motores, luz, modos dos gatilhos, LEDs.
func estado_saida(l: int) -> Dictionary:
	return ctl.estado_saida(l) if modulo else {}


func cor_do_lugar(l: int) -> Color:
	return COR_DO_LUGAR[clampi(l, 0, 3)]


# ---------------------------------------------------------------- o relatório --

func versao() -> String:
	return ctl.versao() if modulo else "sem módulo"


func sessao() -> String:
	return ctl.sessao() if modulo else ""


func salas() -> Array:
	return ctl.salas() if modulo else []


func features() -> Array:
	return ctl.features() if modulo else []


## O id de uma feature pela chave estável ("lightbar", "gatilho_arma"...).
func feature(chave: String) -> int:
	for f in features():
		if f.chave == chave:
			return f.id
	return -1


func veredito(l: int, chave: String, resultado: int, nivel: int, pedido: String, medido: String, obs := "") -> void:
	if modulo:
		ctl.veredito(l, feature(chave), resultado, nivel, pedido, medido, obs)


func ultimo_veredito(l: int, chave: String) -> Dictionary:
	return ctl.ultimo_veredito(l, feature(chave)) if modulo else {}


func controle_do_relatorio(l: int) -> Dictionary:
	return ctl.controle_do_relatorio(l) if modulo else {}


func nota(texto: String) -> void:
	if modulo:
		ctl.nota(texto)


func registrar(linha: String) -> void:
	if modulo:
		ctl.registrar(linha)


func evento(tipo: String, jogador: int, campos := {}) -> void:
	if modulo:
		ctl.evento(tipo, jogador, campos)


func gravar_relatorio() -> bool:
	return ctl.gravar_relatorio() if modulo else false


func registro_recente(n: int) -> PackedStringArray:
	return ctl.registro_recente(n) if modulo else PackedStringArray()


## Os defeitos de mentira só valem dentro das salas.
func em_sala(sim: bool) -> void:
	if modulo:
		ctl.em_sala(sim)


# ---------------------------------------------------------------- as medidas --
# As salas de entrada dizem o que estão pedindo; o módulo amostra os controles a
# cada quadro e, no fim, dá o veredito de cada feature pela régua do núcleo
# (medidas.h) e o grava no relatório.

## A máscara de botões que a sala vai pedir (bit = botão do SDL).
static func mascara(botoes: Array) -> int:
	var m := 0
	for b in botoes:
		m |= 1 << int(b)
	return m


func med_comecar(l: int, botoes := 0) -> bool:
	return ctl.med_comecar(l, botoes) if modulo else false


func med_parar(l: int) -> void:
	if modulo:
		ctl.med_parar(l)


## Volta a medir depois da pausa, sem zerar o que já foi medido.
func med_retomar(l: int) -> void:
	if modulo:
		ctl.med_retomar(l)


## O botão da runa acesa agora (-1: nenhuma).
func med_pedido(l: int, botao: int) -> void:
	if modulo:
		ctl.med_pedido(l, botao)


func med_repouso(l: int, sim: bool) -> void:
	if modulo:
		ctl.med_repouso(l, sim)


## A sala chegou a pedir: "analogico_l", "analogico_r", "gatilho_l2",
## "gatilho_r2", "dois_dedos", "clique", "mira", "martelada".
func med_pedir(l: int, o_que: String) -> void:
	if modulo:
		ctl.med_pedir(l, o_que)


func med_faixa(l: int, lado: int) -> void:
	if modulo:
		ctl.med_faixa(l, lado)


func med_tracou(l: int) -> void:
	if modulo:
		ctl.med_tracou(l)


func med_martelada(l: int) -> void:
	if modulo:
		ctl.med_martelada(l)


func med_estado(l: int) -> Dictionary:
	return ctl.med_estado(l) if modulo else {}


## O veredito da feature pelo que foi medido; grava no relatório e devolve
## {resultado, rotulo, nivel, pedido, medido, obs, nome}.
func med_veredito(l: int, chave: String, nivel := NIVEL_REAGIU) -> Dictionary:
	return ctl.med_veredito(l, chave, nivel) if modulo else {}


# ---------------------------------------------------------------- A Prova: a carga --
# Com tudo ligado ao mesmo tempo, a entrada continuou chegando (o giroscópio
# sem buraco) e o SDL aceitou todas as saídas? O módulo conta a cada quadro.

func carga_comecar(l: int) -> bool:
	return ctl.carga_comecar(l) if modulo else false


func carga_parar(l: int) -> void:
	if modulo:
		ctl.carga_parar(l)


## Uma saída mandada no meio da partida, e se o SDL aceitou.
func carga_saida(l: int, ok: bool) -> void:
	if modulo:
		ctl.carga_saida(l, ok)


func carga_placar(l: int, tiros: int, acertos: int, derrubadas: int) -> void:
	if modulo:
		ctl.carga_placar(l, tiros, acertos, derrubadas)


func carga_estado(l: int) -> Dictionary:
	return ctl.carga_estado(l) if modulo else {}


## O veredito de "tudo junto": a carga e a prova final às cegas (as luzinhas e
## a cor); grava no relatório.
func carga_veredito(l: int, leds: Dictionary, cor: Dictionary, mexeu: bool) -> Dictionary:
	return ctl.carga_veredito(l, leds, cor, mexeu) if modulo else {}


# ---------------------------------------------------------------- as provas às cegas --
# As salas de saída escondem a resposta e perguntam; a sala guarda o que a
# pessoa disse (Cega) e o módulo dá o veredito pela régua do núcleo (cegas.c),
# no degrau que a prova alcançou. Os planos saem do mesmo sorteio do núcleo.

## A ordem dos golpes: `por_lado` de cada lado para cada lugar, um de cada vez.
## Cada item é Vector2i(lugar, lado), lado 0 = esquerda (o motor forte).
func cega_plano_tiros(lugares: Array, por_lado: int, semente: int) -> Array:
	return ctl.cega_plano_tiros(PackedInt32Array(lugares), por_lado, semente) if modulo else []


## A ordem das armas: cada uma `vezes` vezes (0 pistola, 1 metralhadora, 2 arco, 3 nenhuma).
func cega_plano_armas(vezes: int, semente: int) -> PackedInt32Array:
	return ctl.cega_plano_armas(vezes, semente) if modulo else PackedInt32Array()


## Um plano genérico: fontes[i] aparece vezes[i] vezes, sem repetir em seguida.
func cega_plano_fontes(fontes: Array, vezes: Array, semente: int) -> PackedInt32Array:
	return ctl.cega_plano_fontes(PackedInt32Array(fontes), PackedInt32Array(vezes), semente) if modulo else PackedInt32Array()


## A pergunta já decidiu ("cor", "arma", "led_mic"), ou vale mais uma rodada?
func cega_decidida(tipo: String, c: Dictionary) -> bool:
	return ctl.cega_decidida(tipo, c) if modulo else true


## O veredito de uma feature de saída; grava no relatório e devolve
## {resultado, rotulo, nivel, pedido, medido, obs, nome}.
func cega_veredito(l: int, chave: String, dados: Dictionary) -> Dictionary:
	return ctl.cega_veredito(l, chave, dados) if modulo else {}


## O que o controle SIMULADO do lugar sentiu (vibração, luz, gatilhos, LEDs):
## é o que o robô "sente na mão". Vazio num controle de verdade.
func percepcao(l: int) -> Dictionary:
	var p := pad_do_lugar(l)
	return ctl.percepcao(p) if modulo and p >= 0 else {}


# ---------------------------------------------------------------- o som de cada controle --
# O alto-falante, os dois atuadores e o microfone de cada jogador, achados como
# um jogo acha (pelo aparelho, pelo número, pelo nome) e tocados pelo módulo,
# ao lado do som da TV. Controle simulado tem uma placa virtual de quatro
# canais, que o robô ouve e sente (docs/COMO-O-SOM-CHEGA-AO-CONTROLE.md).

const PAPEL_ALTO_FALANTE := 0
const PAPEL_HAPTICA := 1
const PAPEL_MICROFONE := 2


## Acha o som de cada um (ao entrar numa sala de som). No alto-falante e no
## microfone, manda também a rota do alto-falante interno (o bloco de efeitos).
func som_preparar(papel: int) -> void:
	if modulo:
		ctl.som_preparar(papel)


func som_encerrar() -> void:
	if modulo:
		ctl.som_encerrar()


func som_tem(l: int, papel: int) -> bool:
	return ctl.som_tem(l, papel) if modulo else false


## A háptica tem os dois lados (o tropeço pergunta o lado)?
func som_estereo(l: int, papel: int) -> bool:
	return ctl.som_estereo(l, papel) if modulo else false


## O nome que o jogo mostra do dispositivo achado, e como foi achado.
func som_nome(l: int, papel: int) -> String:
	return ctl.som_nome(l, papel) if modulo else ""


func som_como(l: int, papel: int) -> String:
	return ctl.som_como(l, papel) if modulo else ""


func som_plataforma() -> String:
	return ctl.som_plataforma() if modulo else ""


## A pessoa aponta outro dispositivo para o papel (◀ -1, ▶ +1).
func som_trocar(l: int, papel: int, direcao: int) -> void:
	if modulo:
		ctl.som_trocar(l, papel, direcao)


## Um som da forja no alto-falante do controle ("sino", "nota", "grito"...).
func som_falante(l: int, som: String, ganho := 0.9) -> int:
	return ctl.som_falante(l, som, ganho) if modulo else -1


## Um som nos atuadores: `esq` no esquerdo, `dir` no direito ("" = nenhum).
## "passo:<chão>:<variação>" é o passo dos Caminhos.
func som_haptica(l: int, esq: String, dir: String, ganho := 1.0) -> int:
	return ctl.som_haptica(l, esq, dir, ganho) if modulo else -1


func som_parar(l: int) -> void:
	if modulo:
		ctl.som_parar(l)


## O microfone do lugar: {nivel, pico} (0 = -54 dB, 1 = 0 dB) e {quadros}.
func som_mic(l: int) -> Dictionary:
	return ctl.som_mic(l) if modulo else {}


## O que a placa virtual do controle simulado do lugar toca agora, 0..1:
## {falante, esq, dir}. É o que o robô ouve e sente.
func som_virtual(l: int) -> Dictionary:
	return ctl.som_virtual(l) if modulo else {}


## O veredito do microfone ("microfone") ou do botão do mudo
## ("microfone_mudo"), pelo que a sala mediu; grava no relatório.
func mic_veredito(l: int, chave: String, dados: Dictionary) -> Dictionary:
	return ctl.mic_veredito(l, chave, dados) if modulo else {}


## O volume, a rota e o pré-amplificador do alto-falante do controle (o bloco
## de efeitos do relatório USB 0x02).
func alto_falante(l: int, volume: int, rota: int, preamp: int) -> bool:
	return ctl.alto_falante(l, volume, rota, preamp) if modulo else false


# ---------------------------------------------------------------- a bancada --
# experimental/: a escuta crua do microfone, a análise provada sem aparelho, o
# report cru e o resultado de cada medida na linha do tempo.

## Grava os próximos `segundos` do microfone do controle (só um de verdade).
func som_escutar(l: int, segundos: float) -> bool:
	return ctl.som_escutar(l, segundos) if modulo else false


func som_escuta(l: int) -> PackedFloat32Array:
	return ctl.som_escuta(l) if modulo else PackedFloat32Array()


func som_escuta_parar(l: int) -> void:
	if modulo:
		ctl.som_escuta_parar(l)


## A primeira amostra em que o som sobe acima do fundo (-1: nenhuma).
func exp_ataque(a: PackedFloat32Array, vezes: float, minimo: float) -> int:
	return ctl.exp_ataque(a, vezes, minimo) if modulo else -1


func exp_rms_db(a: PackedFloat32Array, ini: int, n: int) -> float:
	return ctl.exp_rms_db(a, ini, n) if modulo else -90.0


func exp_mediana(v: Array) -> float:
	return ctl.exp_mediana(PackedFloat32Array(v)) if modulo else 0.0


## Quatro microfones: niveis[mic][quem fala] em 16 números; {certos, margem_db}.
func exp_diagonal(niveis: Array, n: int) -> Dictionary:
	return ctl.exp_diagonal(PackedFloat32Array(niveis), n) if modulo else {}


## O report cru USB 0x01 do controle (64 bytes), ou vazio sem ele.
func relatorio_cru(l: int) -> PackedByteArray:
	return ctl.relatorio_cru(l) if modulo else PackedByteArray()


## Um resultado da bancada (0 medido, 1 falhou, 2 não medido): a linha do tempo
## e o registro.
func resultado_experimento(l: int, chave: String, o: String, resultado: int, texto: String) -> void:
	if modulo:
		ctl.experimento(l, chave, o, resultado, texto)


## O chão de um envelope sentido nos atuadores (um nível por quadro): 0 grama,
## 1 cascalho, 2 metal, 3 água; -1 nada.
func chao_do_envelope(env: PackedFloat32Array) -> int:
	return ctl.chao_do_envelope(env) if modulo else -1


# ---------------------------------------------------------------- o robô --
# Com --robo, o robô joga nos controles simulados apertando os botões DELES
# (o caminho inteiro do módulo roda, e os defeitos de mentira pegam).

func robo_apertar(l: int, botao: int, segundos := 0.09) -> void:
	var p := pad_do_lugar(l)
	if modulo and p >= 0:
		ctl.robo_apertar(p, botao, segundos)


func robo_eixo(l: int, e: int, v: float, segundos := 0.06) -> void:
	var p := pad_do_lugar(l)
	if modulo and p >= 0:
		ctl.robo_eixo(p, e, v, segundos)


func robo_girar(l: int, g: Vector3, segundos := 0.06) -> void:
	var p := pad_do_lugar(l)
	if modulo and p >= 0:
		ctl.robo_girar(p, g, segundos)


func robo_sacudir(l: int, g: float, segundos := 0.2) -> void:
	var p := pad_do_lugar(l)
	if modulo and p >= 0:
		ctl.robo_sacudir(p, g, segundos)


func robo_tocar(l: int, dedo: int, x: float, y: float, segundos := 0.06) -> void:
	var p := pad_do_lugar(l)
	if modulo and p >= 0:
		ctl.robo_tocar(p, dedo, x, y, segundos)


## O robô fala no microfone do controle dele (nível 0..1).
func robo_falar(l: int, nivel: float, segundos: float) -> void:
	var p := pad_do_lugar(l)
	if modulo and p >= 0:
		ctl.robo_falar(p, nivel, segundos)


## As capacidades do controle do lugar (giro, acel, toque, efeitos...).
func capacidade(l: int, qual: String) -> bool:
	var p := pad_do_lugar(l)
	if p < 0:
		return false
	return bool(pad(p).get(qual, false))
