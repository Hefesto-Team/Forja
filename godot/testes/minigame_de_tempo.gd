extends Minigame

const FICHA := {
	"slot": "T00_J01",
	"titulo": "A Forja de Todos",
	"verbo": "Juntos!",
	"genero": "coop",
	"icone": "botoes",
	"entradas": [Forja.CRUZ],
	"camera": "fixa",
	"faixa": "MUS_S01_J01",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro"],
	"material": "metal",
	"microjogo": {"verbo": "Juntos!", "segundos": 6.0},
	"treino": false,
}
const PASSO := 2.0
const A_FRENTE := 2
const NUNCA := 99.0
const MIRA := [0.0, NUNCA, 0.110, -0.070]
const PONTOS := [0, 1, 2, 3]
const META := 20
const CALA_NA_BATIDA := 40.0
const CALA_POR := 4.0

var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
var perdidas := [0, 0, 0, 0]
var sem_nota := [0, 0, 0, 0]
var calou := false
var _n := [0, 0, 0, 0]
var _b := [0.0, 0.0, 0.0, 0.0]
var _robo_apertou := [-1, -1, -1, -1]
var _robo_nota := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]


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
		_encher(p.lugar)
	anotar("estacao", -1, {"nome": "a forja", "evento": "comecou"})
	anotar("jogo", -1, {"o": "brasa", "calor": 0})
	anotar("pista", 0, {"canal": "tela", "o": "nota"})
	anotar("troca", 3, {"de": "haptica", "para": "rumble"})
	anotar("voz", 1, {"nivel": 0.0, "limiar": 0.5})
	anotar("entrada", 2, {"o": "botao", "chegou": "cross"})


func jogar(_dt: float) -> void:
	if not calou and Ritmo.batida() >= CALA_NA_BATIDA:
		calou = true
		Ritmo.calar(CALA_POR)
	var perfeitos := 0
	for p in jogadores:
		var l: int = p.lugar
		perfeitos += int(contagem[l][Ritmo.PERFEITO])
		if not conectado(l):
			notas_perdidas(l)
			continue
		if Forja.apertou(l, Forja.CRUZ):
			var n := casar_toque(l)
			if n >= 0:
				contagem[l][julgar_nota(l, n)] += 1
			else:
				sem_nota[l] += 1
		perdidas[l] += notas_perdidas(l).size()
		_encher(l)
		var abertas := notas_em_aberto(l)
		var perto := not abertas.is_empty() and absf(Ritmo.t_musica() - alvo_da(l, abertas[0])) < 0.15
		acender_raia(l, 1.0 if perto else 0.15)
	coop_venceu = perfeitos >= META


func toque(l: int, julgamento: int) -> void:
	marcar(l, PONTOS[julgamento])
	var p := jogador(l)
	if p:
		p.gesto("attack-melee-right", 0.3)


func falha(l: int) -> void:
	var p := jogador(l)
	if p:
		p.gesto("emote-no", 0.4)


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	if MIRA[l] == NUNCA:
		return
	var abertas := notas_em_aberto(l)
	if abertas.is_empty():
		return
	var n: int = abertas[0]
	if _robo_apertou[l] == n:
		return
	if _robo_nota[l] != n:
		_robo_nota[l] = n
		_robo_mira[l] = (MIRA[l] + float(Ritmo.desvio[l])) if Forja.robo_acerta() else 0.25
	if Ritmo.t_musica() >= alvo_da(l, n) + float(_robo_mira[l]):
		Forja.robo_apertar(l, Forja.CRUZ, 0.05)
		_robo_apertou[l] = n


func _encher(l: int) -> void:
	while notas_em_aberto(l).size() < A_FRENTE:
		_b[l] = proxima_batida(l, maxf(float(_b[l]), Ritmo.batida()), PASSO, 0.5 * l)
		_n[l] += 1
		nova_nota(l, _n[l], Ritmo.t_da_batida(_b[l]))
