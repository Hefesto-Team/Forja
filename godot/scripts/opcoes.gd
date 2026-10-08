class_name Opcoes
extends RefCounted
## As opções de conforto (o estudo 04, regra 11; o GT7 e a XAG 110): por
## lugar, o gatilho (desligado, fraco, forte) e a vibração (0 a 100%); da
## sessão, o volume da TV e o do alto-falante do controle, o movimento da câmera (o tremor e o giro do título),
## os flashes, tela cheia ou janela e o tamanho do texto.
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
static var tremor := true
static var flashes := true
static var tela_cheia := false
static var texto := 0
static var idioma := 0
static var _carregou := false


static func de_fabrica() -> void:
	gatilho = [GATILHO_FORTE, GATILHO_FORTE, GATILHO_FORTE, GATILHO_FORTE]
	vibracao = [100, 100, 100, 100]
	tempo_ms = [0, 0, 0, 0]
	volume_tv = 100
	volume_controle = 100
	tremor = true
	flashes = true
	tela_cheia = false
	texto = 0
	idioma = 0


static func carregar(robo: bool) -> void:
	if _carregou:
		return
	_carregou = true
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
	volume_tv = _passo(int(cfg.get_value("sessao", "volume_tv", 100)))
	volume_controle = _passo(int(cfg.get_value("sessao", "volume_controle", 100)))
	tremor = bool(cfg.get_value("sessao", "tremor", true))
	flashes = bool(cfg.get_value("sessao", "flashes", true))
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
	cfg.set_value("sessao", "volume_tv", volume_tv)
	cfg.set_value("sessao", "volume_controle", volume_controle)
	cfg.set_value("sessao", "tremor", tremor)
	cfg.set_value("sessao", "flashes", flashes)
	cfg.set_value("sessao", "tela_cheia", tela_cheia)
	cfg.set_value("sessao", "texto", texto)
	cfg.set_value("sessao", "idioma", idioma)
	cfg.save(arquivo)


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
