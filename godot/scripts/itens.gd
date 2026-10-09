class_name Itens
extends RefCounted
## O item que cada lugar escolheu na construção, como regra (G03). Cada um dos
## seis é um poder pequeno com um preço; todo minigame pergunta aqui, e a conta
## é a mesma nos 45. A fonte dos números é docs/jogo/sistemas/itens.csv.
##
## O índice é o de ForjaPlayer.ITENS. A mecânica lê `escolhido`, não o item
## visual do boneco: a sala pode tirar o item da mão (SalaJogo.maos_livres) e
## a regra segue valendo.

enum { NENHUM, MARTELO, ESCUDO, FOLE, LANTERNA, DIAPASAO, ANCORA }
## O julgamento, na numeração do Ritmo (13): ERRO 0, BOM 1, OTIMO 2, PERFEITO 3.
const PERFEITO := 3
## Os tons das peças (arte/02, a escada de valor), medidos em OKLab.
const METAL := Color("#9ba6b1")     ## L 0,72, croma 0,020: a arma
const CERAMICA := Color("#c9b08f")  ## L 0,77, croma 0,053: o disco do amuleto
const LATAO := Color("#b59b63")     ## L 0,70, croma 0,080: o emblema

## O item de cada lugar, para a mecânica (a construção escreve; a sala não mexe).
static var escolhido := [NENHUM, NENHUM, NENHUM, NENHUM]
## O item em liga com o cavaleiro (a G13 escreve ao forjar, pelos stats; até lá, false).
static var em_liga := [false, false, false, false]
static var _escudo := [true, true, true, true]


## O item do lugar (NENHUM fora de 0..3).
static func do_lugar(l: int) -> int:
	return int(escolhido[l]) if l >= 0 and l < 4 else NENHUM


static func _e(l: int, item: int) -> bool:
	return do_lugar(l) == item


static func _liga(l: int) -> bool:
	return l >= 0 and l < 4 and bool(em_liga[l])


## Martelo: o perfeito no tempo forte vale o dobro; o acerto fora do tempo forte
## vale 85 % (em liga, 100 %).
static func pontos_do_acerto(l: int, pontos: int, julgamento: int, no_tempo_forte: bool) -> int:
	if not _e(l, MARTELO):
		return pontos
	if julgamento == PERFEITO and no_tempo_forte:
		return pontos * 2
	if not no_tempo_forte and not _liga(l):
		return int(round(pontos * 0.85))
	return pontos


## Escudo: absorve o primeiro erro de cada minigame. Quem pergunta é quem erra:
## responder gasta o escudo e registra.
static func absorve_erro(l: int) -> bool:
	if not _e(l, ESCUDO) or not bool(_escudo[l]):
		return false
	_escudo[l] = false
	registrar(l, "absorveu")
	return true


## O Escudo ainda está inteiro neste minigame (a HUD da G04 lê).
static func escudo_inteiro(l: int) -> bool:
	return _e(l, ESCUDO) and bool(_escudo[l])


## Escudo: começa o minigame com o combo em 0; em liga, com o bônus de entrada.
static func combo_inicial(l: int, normal: int) -> int:
	return 0 if _e(l, ESCUDO) and not _liga(l) else normal


## Fole: depois de um erro, o combo volta na metade dos acertos.
static func acertos_para_voltar_o_combo(l: int, normal: int) -> int:
	return int(ceil(normal / 2.0)) if _e(l, FOLE) else normal


## Fole: o combo máximo é 3/4 (em liga, o normal).
static func combo_maximo(l: int, normal: int) -> int:
	return int(normal * 3 / 4) if _e(l, FOLE) and not _liga(l) else normal


## Lanterna: a pista chega meio tempo antes (30 / BPM s).
static func antecipacao_s(l: int, bpm: float) -> float:
	return 30.0 / bpm if _e(l, LANTERNA) and bpm > 0.0 else 0.0


## Lanterna: a janela do perfeito encolhe 10 ms, 5 de cada lado (em liga, não encolhe).
static func janela_perfeito(l: int, janela: Vector2) -> Vector2:
	if _e(l, LANTERNA) and not _liga(l):
		return Vector2(janela.x + 0.005, janela.y - 0.005)
	return janela


## Diapasão: a nota soa a × 1,3; no todos contra todos ("tct"), só em liga.
static func ganho_da_nota(l: int, genero: String) -> float:
	if _e(l, DIAPASAO) and (genero != "tct" or _liga(l)):
		return 1.3
	return 1.0


## Diapasão: o perfeito puxa o combo da equipe (2v2 e coop).
static func puxa_o_combo_da_equipe(l: int, genero: String) -> bool:
	return _e(l, DIAPASAO) and genero in ["2v2", "coop"]


## Âncora: sofre metade do empurrão.
static func resiste_a_empurrao(l: int) -> float:
	return 0.5 if _e(l, ANCORA) else 0.0


## Âncora: anda a 0,9 na corrida (em liga, 1,0).
static func velocidade(l: int, genero: String) -> float:
	return 0.9 if _e(l, ANCORA) and genero == "corrida" and not _liga(l) else 1.0


## O item se sente no L2 (só o lado 0; o R2 é das salas): o Escudo inteiro firma,
## a Âncora pesa pouco, o resto solta.
static func sentir(l: int) -> void:
	if escudo_inteiro(l):
		Forja.gatilho(l, 0, Forja.GATILHO_RESISTENCIA, 2, 4)
	elif _e(l, ANCORA):
		Forja.gatilho(l, 0, Forja.GATILHO_RESISTENCIA, 2, 2)
	else:
		Forja.gatilho(l, 0, Forja.GATILHO_OFF)


## Cada minigame começa com o Escudo dos quatro inteiro.
static func novo_minigame() -> void:
	_escudo = [true, true, true, true]


## Uma linha `item` na linha do tempo e no registro. Os efeitos desta ficha:
## "leva" (ao entrar num minigame), "absorveu" e "quebrou"; os do kit
## ("dobrou", "antecipou", "puxou", "resistiu") vêm com a H04.
static func registrar(l: int, efeito: String) -> void:
	var nome: String = ForjaPlayer.ITENS[do_lugar(l)].nome
	Forja.evento("item", l + 1, {"item": nome, "efeito": efeito, "em_liga": _liga(l)})
	Forja.registrar("P%d: %s %s" % [l + 1, nome, efeito])
