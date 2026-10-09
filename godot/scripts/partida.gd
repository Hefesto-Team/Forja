class_name Partida
extends RefCounted
## A partida de festa: uma sequência de salas, e no fim um vencedor.
##
## Cada sala conta pontos na régua dela (uma runa d'A Centelha não vale o mesmo
## que um molde d'O Molde), então a partida não soma os pontos crus: soma a
## colocação em cada sala. O primeiro da sala leva 4 pontos da noite, o segundo
## 3, o terceiro 2, o quarto 1; quem empata divide a colocação de cima. No fim,
## o pódio — e alguém sempre ganha: mais pontos da noite; no empate, mais
## salas vencidas; depois, quem foi melhor na última sala (e na anterior, e
## assim para trás); e, se ainda empatar, o sorteio da semente decide.
##
## Tudo aqui é lógica pura (sem nó, sem controle): a prova do jogo confere as
## contas sem abrir uma sala.

## Os tamanhos que o jogo oferece.
const TAMANHOS := [3, 5, 9]
## Os pontos da noite pela colocação na sala (1º, 2º, 3º, 4º).
const PELA_COLOCACAO := [4, 3, 2, 1]
## As partidas na ordem, por seção (o apelido). A de cinco tem O Canto (o
## alto-falante do controle é do jogo, docs/jogo/13 H08); A Prova sempre no
## fim. A de nove é o percurso.
const NA_ORDEM := {
	3: ["centelha", "galeria", "prova"],
	5: ["centelha", "impacto", "canto", "galeria", "prova"],
}
const NOMES := {
	"centelha": "A Centelha", "viga": "A Viga", "molde": "O Molde", "impacto": "O Impacto",
	"galeria": "A Galeria", "canto": "O Canto", "caminhos": "Os Caminhos", "voz": "A Voz",
	"prova": "A Prova",
}

var secoes: Array = []  ## os apelidos das seções, na ordem (o roteiro)
var salas: Array = []  ## o que se abre, na ordem: o slot sorteado de cada seção (o apelido, se a seção ainda não tem minigame)
var semente := 0  ## o sorteio do último desempate
var sorteada := false
var passo := 0  ## a sala em curso (índice em `salas`)
var total := [0, 0, 0, 0]  ## os pontos da noite de cada lugar
var vitorias := [0, 0, 0, 0]  ## as salas em que cada lugar ficou em primeiro
## Uma entrada por sala jogada: {sala, nome, pontos: [4], colocacao: [4], ganhos: [4]}.
## Quem não jogou a sala tem colocação 0 e ganho 0.
var historico: Array = []
var virou := false  ## a fita já virou nesta noite (o intervalo já aconteceu)


## As salas de uma partida de `n` salas. Na ordem: as de NA_ORDEM, ou o
## percurso inteiro. Sorteada: `n - 1` salas do percurso, embaralhadas pela
## semente, e A Prova fechando.
static func roteiro(n: int, sortear: bool, semente: int, percurso: Array) -> Array:
	if not sortear:
		if NA_ORDEM.has(n):
			return NA_ORDEM[n].duplicate()
		return percurso.duplicate()
	var outras: Array = percurso.filter(func(s): return s != "prova")
	var rng := RandomNumberGenerator.new()
	rng.seed = semente * 977 + n
	# Fisher–Yates com o gerador da semente: o mesmo sorteio em toda máquina
	for i in range(outras.size() - 1, 0, -1):
		var k := rng.randi_range(0, i)
		var tmp = outras[i]
		outras[i] = outras[k]
		outras[k] = tmp
	var r: Array = outras.slice(0, clampi(n - 1, 0, outras.size()))
	r.append("prova")
	return r


## A partida: o roteiro das seções e, de cada uma, o próximo minigame que a
## noite ainda não jogou (Catalogo.proximo, pela semente da noite).
static func nova(n: int, sortear: bool, semente: int, percurso: Array, jogados := {}, semente_da_noite := 0) -> Partida:
	var p := Partida.new()
	p.secoes = roteiro(n, sortear, semente, percurso)
	var ja: Dictionary = jogados.duplicate()
	for ap in p.secoes:
		var slot := Catalogo.proximo(str(ap), semente_da_noite, ja)
		ja[slot] = true
		p.salas.append(slot)
	p.sorteada = sortear
	p.semente = semente
	return p


## O nome de um slot ou de um apelido: o título do minigame, ou o da seção.
static func nome(id: String) -> String:
	var t := Catalogo.titulo(id)
	return t if t != "" else str(NOMES.get(Catalogo.apelido(id), id))


## A colocação de cada lugar presente pelos pontos da sala: 1 + quantos fizeram
## mais (o empate divide a de cima). Quem não está presente fica com 0.
static func colocacoes(pontos: Array, presentes: Array) -> Array:
	var c := [0, 0, 0, 0]
	for l in presentes:
		var acima := 0
		for o in presentes:
			if int(pontos[o]) > int(pontos[l]):
				acima += 1
		c[l] = acima + 1
	return c


func sala_atual() -> String:
	return salas[passo] if passo < salas.size() else ""


func acabou() -> bool:
	return passo >= salas.size()


## As faixas do lado A: depois de `ceil(n / 2)` faixas a fita vira (2 de 3, 3 de 5, 5 de 9).
func metade() -> int:
	return ceili(salas.size() / 2.0)


## "A" até a metade da noite; "B" daí até o pódio.
func lado() -> String:
	return "B" if passo >= metade() else "A"


## "Partida · sala 2 de 5".
func rotulo() -> String:
	return "Partida · sala %d de %d" % [mini(passo + 1, salas.size()), salas.size()]


## A sala em curso acabou com estes pontos: soma a colocação e anda um passo.
func registrar(id: String, pontos: Array, presentes: Array) -> Dictionary:
	var col := colocacoes(pontos, presentes)
	var ganhos := [0, 0, 0, 0]
	for l in presentes:
		ganhos[l] = PELA_COLOCACAO[clampi(col[l] - 1, 0, 3)]
		total[l] += ganhos[l]
		if col[l] == 1:
			vitorias[l] += 1
	var entrada := {"sala": id, "nome": nome(id), "pontos": pontos.duplicate(),
		"colocacao": col, "ganhos": ganhos}
	historico.append(entrada)
	passo += 1
	return entrada


## O pódio: [{lugar, total, vitorias, degrau, criterio}], do primeiro ao
## último, sem degrau dividido. `criterio` diz o que separou o lugar do de
## baixo: "" (os pontos), "salas vencidas", "a última sala" ou "o sorteio".
func podio(presentes: Array) -> Array:
	var lista: Array = []
	for l in presentes:
		lista.append({"lugar": l, "total": total[l], "vitorias": vitorias[l]})
	lista.sort_custom(func(a, b): return _acima(int(a.lugar), int(b.lugar)))
	for i in lista.size():
		lista[i]["degrau"] = i + 1
		lista[i]["criterio"] = _criterio(int(lista[i].lugar), int(lista[i + 1].lugar)) if i + 1 < lista.size() else ""
	return lista


## A ordem da noite entre dois lugares: true se `a` fica acima de `b`.
func _acima(a: int, b: int) -> bool:
	if total[a] != total[b]:
		return total[a] > total[b]
	if vitorias[a] != vitorias[b]:
		return vitorias[a] > vitorias[b]
	for k in range(historico.size() - 1, -1, -1):
		var ca := int(historico[k].colocacao[a])
		var cb := int(historico[k].colocacao[b])
		if ca != cb and ca > 0 and cb > 0:
			return ca < cb
	return _sorteio(a) > _sorteio(b)


## O que separou `a` de `b` (o de baixo).
func _criterio(a: int, b: int) -> String:
	if total[a] != total[b]:
		return ""
	if vitorias[a] != vitorias[b]:
		return "salas vencidas"
	for k in range(historico.size() - 1, -1, -1):
		var ca := int(historico[k].colocacao[a])
		var cb := int(historico[k].colocacao[b])
		if ca != cb and ca > 0 and cb > 0:
			return "a última sala" if k == historico.size() - 1 else "as salas, de trás para a frente"
	return "o sorteio"


## O número do sorteio de um lugar: fixo pela semente, diferente por lugar.
func _sorteio(l: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente * 7919 + 104729 * (l + 1)
	return rng.randi()


## Quem joga agora: os lugares que jogaram alguma sala da partida.
func presentes() -> Array:
	var r: Array = []
	for l in 4:
		for h in historico:
			if int(h.colocacao[l]) > 0:
				r.append(l)
				break
	return r
