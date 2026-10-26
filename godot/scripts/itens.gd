class_name Itens
extends RefCounted

enum { NENHUM, MARTELO, ESCUDO, FOLE, LANTERNA, DIAPASAO, ANCORA }
const PERFEITO := 3
const METAL := Color("#9ba6b1")
const CERAMICA := Color("#c9b08f")
const LATAO := Color("#b59b63")

static var escolhido := [NENHUM, NENHUM, NENHUM, NENHUM]
static var em_liga := [false, false, false, false]
static var _escudo := [true, true, true, true]


static func do_lugar(l: int) -> int:
	return int(escolhido[l]) if l >= 0 and l < 4 else NENHUM


static func _e(l: int, item: int) -> bool:
	return do_lugar(l) == item


static func _liga(l: int) -> bool:
	return l >= 0 and l < 4 and bool(em_liga[l])


static func pontos_do_acerto(l: int, pontos: int, julgamento: int, no_tempo_forte: bool) -> int:
	if not _e(l, MARTELO):
		return pontos
	if julgamento == PERFEITO and no_tempo_forte:
		return pontos * 2
	if not no_tempo_forte and not _liga(l):
		return int(round(pontos * 0.85))
	return pontos


static func absorve_erro(l: int) -> bool:
	if not _e(l, ESCUDO) or not bool(_escudo[l]):
		return false
	_escudo[l] = false
	registrar(l, "absorveu")
	return true


static func escudo_inteiro(l: int) -> bool:
	return _e(l, ESCUDO) and bool(_escudo[l])


static func combo_inicial(l: int, normal: int) -> int:
	return 0 if _e(l, ESCUDO) and not _liga(l) else normal


static func acertos_para_voltar_o_combo(l: int, normal: int) -> int:
	return int(ceil(normal / 2.0)) if _e(l, FOLE) else normal


static func combo_maximo(l: int, normal: int) -> int:
	return int(normal * 3 / 4) if _e(l, FOLE) and not _liga(l) else normal


static func antecipacao_s(l: int, bpm: float) -> float:
	return 30.0 / bpm if _e(l, LANTERNA) and bpm > 0.0 else 0.0


static func janela_perfeito(l: int, janela: Vector2) -> Vector2:
	if _e(l, LANTERNA) and not _liga(l):
		return Vector2(janela.x + 0.005, janela.y - 0.005)
	return janela


static func ganho_da_nota(l: int, genero: String) -> float:
	if _e(l, DIAPASAO) and (genero != "tct" or _liga(l)):
		return 1.3
	return 1.0


static func puxa_o_combo_da_equipe(l: int, genero: String) -> bool:
	return _e(l, DIAPASAO) and genero in ["2v2", "coop"]


static func resiste_a_empurrao(l: int) -> float:
	return 0.5 if _e(l, ANCORA) else 0.0


static func velocidade(l: int, genero: String) -> float:
	return 0.9 if _e(l, ANCORA) and genero == "corrida" and not _liga(l) else 1.0


static func sentir(l: int) -> void:
	if escudo_inteiro(l):
		Forja.gatilho(l, 0, Forja.GATILHO_RESISTENCIA, 2, 4)
	elif _e(l, ANCORA):
		Forja.gatilho(l, 0, Forja.GATILHO_RESISTENCIA, 2, 2)
	else:
		Forja.gatilho(l, 0, Forja.GATILHO_OFF)


static func novo_minigame() -> void:
	_escudo = [true, true, true, true]


static func registrar(l: int, efeito: String) -> void:
	var nome: String = ForjaPlayer.ITENS[do_lugar(l)].nome
	Forja.evento("item", l + 1, {"item": nome, "efeito": efeito, "em_liga": _liga(l)})
	Forja.registrar("P%d: %s %s" % [l + 1, nome, efeito])
