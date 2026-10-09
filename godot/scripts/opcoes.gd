class_name Opcoes
extends RefCounted
## As opções de conforto (o estudo 04, regra 11; o GT7 e a XAG 110): por
## lugar, o gatilho (desligado, fraco, forte) e a vibração (0 a 100%); da
## sessão, o volume da TV e o do alto-falante do controle, o movimento (Inteiro ou Reduzido: o tremor, o giro do
## título, a parada, o esmagar e o confete), os flashes, as reações, tela cheia ou janela e o tamanho do texto.
##
## Guardadas em user://opcoes.cfg — por máquina, nunca por aparelho (o lugar
## P1..P4 é o índice, não o controle). Com o robô (as provas), nada se lê nem
## se grava: a prova joga sempre com as opções de fábrica.

const GATILHO := ["Desligado", "Fraco", "Forte"]
const GATILHO_DESLIGADO := 0
const GATILHO_FRACO := 1
const GATILHO_FORTE := 2
const PASSO := 25  ## a vibração e os volumes andam de 25 em 25%
const TEXTO := ["Normal", "Grande"]
const ESCALA_DO_TEXTO := [1.0, 1.15]
## O movimento: o Reduzido corta o tremor, o giro do título, a parada de quadros e o esmagar, e o confete cai a um quarto.
const MOVIMENTO := ["Inteiro", "Reduzido"]
## As reações: o adesivo de quem joga («Todas»), só o carimbo do jogo («Só do jogo») ou nenhum («Nenhuma»).
const REACOES := ["Todas", "Só do jogo", "Nenhuma"]
const ARQUIVO := "user://opcoes.cfg"
## As línguas das telas: o português é o padrão.
const IDIOMAS := ["pt_BR", "en"]
const NOMES_DOS_IDIOMAS := ["Português", "English"]

## As features que a vibração e o gatilho carregam: com o recurso desligado
## nas opções, o veredito delas é "não medido", nunca "falhou".
const FEATURES_DA_VIBRACAO := ["vibracao_forte", "vibracao_fraca", "vibracao_isolamento", "haptica_audio"]
const FEATURES_DO_GATILHO := ["gatilho_resistencia", "gatilho_arma", "gatilho_vibracao"]

## O tempo de cada lugar (a calibração), em ms: o quanto o toque daquele
## controle chega atrasado (negativo: adiantado). A construção do cavaleiro
## mede (G02); as opções ajustam à mão, de 10 em 10.
const TEMPO_PASSO := 10
const TEMPO_MIN := -150
const TEMPO_MAX := 250

static var gatilho := [GATILHO_FORTE, GATILHO_FORTE, GATILHO_FORTE, GATILHO_FORTE]
static var vibracao := [100, 100, 100, 100]
static var tempo_ms := [0, 0, 0, 0]
static var volume_tv := 100
static var volume_controle := 100
static var movimento := 0
static var flashes := true
static var reacoes := 0
static var tela_cheia := false
static var texto := 0
static var idioma := 0
static var cavaleiro := [{}, {}, {}, {}]   ## ForjaPlayer.cavaleiro() de cada lugar
static var noite_dos_cavaleiros := ""      ## Opcoes.noite() de quando foram forjados
static var _robo := false                  ## posto por carregar(robo)
static var guardadas := 0                  ## quantas vezes a construção mandou guardar (a prova conta)
static var _carregou := false


static func de_fabrica() -> void:
	gatilho = [GATILHO_FORTE, GATILHO_FORTE, GATILHO_FORTE, GATILHO_FORTE]
	vibracao = [100, 100, 100, 100]
	tempo_ms = [0, 0, 0, 0]
	volume_tv = 100
	volume_controle = 100
	movimento = 0
	flashes = true
	reacoes = 0
	tela_cheia = false
	texto = 0
	idioma = 0
	cavaleiro = [{}, {}, {}, {}]
	noite_dos_cavaleiros = ""


## A noite: a data de seis horas atrás (a noite que passa da meia-noite continua a mesma).
static func noite() -> String:
	return Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) - 6 * 3600)


## Grava sem quem chama saber do robô (a paridade da F08).
static func guardar() -> void:
	guardadas += 1
	gravar(_robo)


static func carregar(robo: bool) -> void:
	if _carregou:
		return
	_carregou = true
	_robo = robo
	de_fabrica()
	if robo:
		return
	ler(ARQUIVO)


## Lê o arquivo por cima do que há (a prova lê um arquivo dela, não o da pessoa).
static func ler(arquivo: String) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(arquivo) != OK:
		return
	for l in 4:
		gatilho[l] = clampi(int(cfg.get_value("P%d" % (l + 1), "gatilho", GATILHO_FORTE)), 0, 2)
		vibracao[l] = _passo(int(cfg.get_value("P%d" % (l + 1), "vibracao", 100)))
		tempo_ms[l] = clampi(int(cfg.get_value("P%d" % (l + 1), "tempo_ms", 0)), TEMPO_MIN, TEMPO_MAX)
		var c = cfg.get_value("P%d" % (l + 1), "cavaleiro", {})
		cavaleiro[l] = (c as Dictionary).duplicate() if c is Dictionary else {}
	noite_dos_cavaleiros = str(cfg.get_value("sessao", "noite_dos_cavaleiros", ""))
	volume_tv = _passo(int(cfg.get_value("sessao", "volume_tv", 100)))
	volume_controle = _passo(int(cfg.get_value("sessao", "volume_controle", 100)))
	# o arquivo antigo guardava só o tremor: desligado vira Reduzido
	movimento = clampi(int(cfg.get_value("sessao", "movimento", 0 if bool(cfg.get_value("sessao", "tremor", true)) else 1)), 0, MOVIMENTO.size() - 1)
	flashes = bool(cfg.get_value("sessao", "flashes", true))
	reacoes = clampi(int(cfg.get_value("sessao", "reacoes", 0)), 0, REACOES.size() - 1)
	tela_cheia = bool(cfg.get_value("sessao", "tela_cheia", false))
	texto = clampi(int(cfg.get_value("sessao", "texto", 0)), 0, TEXTO.size() - 1)
	idioma = clampi(int(cfg.get_value("sessao", "idioma", 0)), 0, IDIOMAS.size() - 1)


static func gravar(robo: bool, arquivo := ARQUIVO) -> void:
	if robo:
		return
	var cfg := ConfigFile.new()
	for l in 4:
		cfg.set_value("P%d" % (l + 1), "gatilho", gatilho[l])
		cfg.set_value("P%d" % (l + 1), "vibracao", vibracao[l])
		cfg.set_value("P%d" % (l + 1), "tempo_ms", tempo_ms[l])
		cfg.set_value("P%d" % (l + 1), "cavaleiro", cavaleiro[l])
	cfg.set_value("sessao", "noite_dos_cavaleiros", noite_dos_cavaleiros)
	cfg.set_value("sessao", "volume_tv", volume_tv)
	cfg.set_value("sessao", "volume_controle", volume_controle)
	cfg.set_value("sessao", "movimento", movimento)
	cfg.set_value("sessao", "flashes", flashes)
	cfg.set_value("sessao", "reacoes", reacoes)
	cfg.set_value("sessao", "tela_cheia", tela_cheia)
	cfg.set_value("sessao", "texto", texto)
	cfg.set_value("sessao", "idioma", idioma)
	cfg.save(arquivo)


## O movimento reduzido está ligado.
static func reduzido() -> bool:
	return movimento == 1


## Os quadros de parada (hit-stop) que valem: nenhum no Reduzido.
static func parada(quadros: int) -> int:
	return 0 if reduzido() else quadros


## Limita o esmagar e esticar (squash e stretch) a um desvio de 1,0: ±20% no Inteiro, ±5% no Reduzido.
static func esmagar(fator: float) -> float:
	var teto := 0.05 if reduzido() else 0.20
	return 1.0 + clampf(fator - 1.0, -teto, teto)


## Quantas faíscas de confete saem: a um quarto (arredondado para cima) no Reduzido.
static func confete(n: int) -> int:
	return ceili(n / 4.0) if reduzido() else n


## O adesivo de quem joga se desenha (só em «Todas»).
static func reacao_do_jogador() -> bool:
	return reacoes == 0


## O carimbo do jogo se desenha (em «Todas» e em «Só do jogo»).
static func reacao_do_jogo() -> bool:
	return reacoes <= 1


static func _passo(v: int) -> int:
	return clampi(int(round(v / float(PASSO))) * PASSO, 0, 100)


## Os motores do lugar, na escala da vibração dele.
static func escala_vibracao(l: int) -> float:
	return vibracao[clampi(l, 0, 3)] / 100.0


## O gatilho do lugar pelas opções: desligado vira Off; fraco, metade da força
## (Feedback e Vibration: o b; Weapon: o c). Devolve [modo, a, b, c].
static func ajustar_gatilho(l: int, modo: int, a: int, b: int, c: int) -> Array:
	match int(gatilho[clampi(l, 0, 3)]):
		GATILHO_DESLIGADO:
			return [0, 0, 0, 0]
		GATILHO_FRACO:
			match modo:
				1, 3:  # resistência e vibração: a força é o b
					b = maxi(1, int(ceil(b / 2.0)))
				2:  # arma: a força é o c
					c = maxi(1, int(ceil(c / 2.0)))
	return [modo, a, b, c]


## Por que a feature não se mede neste lugar, pelas opções ("" se mede).
static func por_que_nao_mede(l: int, feature: String) -> String:
	if feature in FEATURES_DA_VIBRACAO and vibracao[clampi(l, 0, 3)] == 0:
		return "não medido: a vibração deste lugar está desligada nas opções"
	if feature in FEATURES_DO_GATILHO and gatilho[clampi(l, 0, 3)] == GATILHO_DESLIGADO:
		return "não medido: o gatilho deste lugar está desligado nas opções"
	return ""
