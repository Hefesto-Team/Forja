extends Minigame
## O minigame de prova do kit (fica em testes/: não entra no jogo nem na
## exportação). Quatro raias, uma nota por tempo para cada lugar, ✕ no tempo.
## O robô de cada lugar mira um desvio combinado, para a prova ver os quatro
## julgamentos saírem do Ritmo pelo caminho inteiro: o controle simulado, o
## módulo, o Forja.apertou, o julgar_toque do kit e o registro.
##
## Sem faixa (o relógio do sistema), 120 bpm; cada lugar julga NOTAS notas e
## acaba; o minigame acaba quando todos acabam.

const FICHA := {
	"slot": "T00_J00",
	"titulo": "O Metrônomo",
	"verbo": "Bata!",
	"genero": "tct",
	"icone": "botoes",
	"entradas": [Forja.CRUZ],
	"camera": "fixa",
	"faixa": "",
	"duracao": 0.0,
	"fim": "meta_coletiva",
	"sensacoes": ["acerto", "perfeito", "erro"],
	"material": "metal",
	"microjogo": {"verbo": "Bata!", "segundos": 6.0},
	"treino": false,
}
const NOTAS := 12
## A primeira nota: dá tempo de o robô adiantado mirar antes dela.
const PRIMEIRA := BATIDA_DA_PRIMEIRA_NOTA
## O desvio que o robô de cada lugar mira, em s (NUNCA: não aperta).
const NUNCA := 99.0
const MIRA := [0.0, -0.065, -0.115, NUNCA]
## Os pontos de cada julgamento (ERRO, BOM, OTIMO, PERFEITO).
const PONTOS := [0, 1, 2, 3]

var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]  ## [lugar][julgamento]
var _nota := [PRIMEIRA, PRIMEIRA, PRIMEIRA, PRIMEIRA]  ## a nota da vez de cada lugar
var _julgadas := [0, 0, 0, 0]
var _robo_apertou := [-1, -1, -1, -1]  ## a última nota em que o robô apertou
var _robo_nota := [-1, -1, -1, -1]  ## a nota que o robô já mirou
var _robo_mira := [0.0, 0.0, 0.0, 0.0]
var _fora := [false, false, false, false]  ## o lugar estava sem controle


func montar() -> void:
	camera_pos = Vector3(0, 7.5, 12.0)
	camera_olhar = Vector3(0, 0.8, 0)
	Kit.arena(self, 5, 3)
	luzes([Vector3(-6, 3.0, 3), Vector3(6, 3.0, 3)])
	for p in jogadores:
		raia(p.lugar)
		posicionar(p.lugar)


func iniciar_jogo() -> void:
	for p in jogadores:
		nova_nota(p.lugar, _nota[p.lugar], Ritmo.t_da_batida(_nota[p.lugar]))


func jogar(_dt: float) -> void:
	for p in jogadores:
		var l: int = p.lugar
		if acabou[l]:
			continue
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			# voltou: a nota da vez é a próxima que ainda não passou
			_fora[l] = false
			_nota[l] = maxi(_nota[l], ceili(Ritmo.batida() + 0.3))
			nova_nota(l, _nota[l], Ritmo.t_da_batida(_nota[l]))
		var n: int = _nota[l]
		var alvo := Ritmo.t_da_batida(n)
		acender_raia(l, clampf(1.0 - absf(Ritmo.t_musica() - alvo) * 4.0, 0.0, 1.0))
		if Forja.apertou(l, Forja.CRUZ):
			contagem[l][julgar_toque(l, alvo, n)] += 1
			_proxima(l)
		elif Ritmo.t_musica() - float(Ritmo.desvio[l]) > alvo + Ritmo.JANELA_BOM:
			# a nota passa pela janela do lugar: o desvio calibrado (G02) a empurra junto
			nota_perdida(l, n)
			contagem[l][Ritmo.ERRO] += 1
			_proxima(l)


func toque(l: int, julgamento: int) -> void:
	marcar(l, PONTOS[julgamento])
	jogador(l).gesto("attack-melee-right", 0.3)


func falha(l: int) -> void:
	jogador(l).gesto("emote-no", 0.4)


func robo(l: int, dt: float) -> void:
	if not Forja.robo:
		return
	var n: int = _nota[l]
	if MIRA[l] == NUNCA or _robo_apertou[l] == n:
		return
	if _robo_nota[l] != n:
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, aperta tarde demais
		_robo_nota[l] = n
		# o robô toca como o cavaleiro que a construção calibrou: atrasado o
		# desvio do lugar (G02), que o Ritmo desconta; o julgamento vê a MIRA
		_robo_mira[l] = (MIRA[l] + float(Ritmo.desvio[l])) if Forja.robo_acerta() else 0.25
	# o toque é julgado no quadro seguinte (minigame.gd, julgar_toque): o robô aperta
	# quando o quadro do julgamento passa da mira, e o desvio fica entre a mira e a mira
	# mais um quadro, em qualquer fase da batida contra o quadro (a WE02)
	if Ritmo.t_musica() + dt >= Ritmo.t_da_batida(n) + float(_robo_mira[l]):
		Forja.robo_apertar(l, Forja.CRUZ, 0.05)
		_robo_apertou[l] = n


func _proxima(l: int) -> void:
	_julgadas[l] += 1
	_nota[l] += 1
	if _julgadas[l] >= NOTAS:
		acabou[l] = true
		acender_raia(l, 0.0)
	else:
		nova_nota(l, _nota[l], Ritmo.t_da_batida(_nota[l]))
