class_name Partida
extends RefCounted

const TAMANHOS := [3, 5, 9]
const PELA_COLOCACAO := [4, 3, 2, 1]
const NA_ORDEM := {
	3: ["centelha", "galeria", "prova"],
	5: ["centelha", "impacto", "canto", "galeria", "prova"],
}
const NOMES := {
	"centelha": "A Centelha", "viga": "A Viga", "molde": "O Molde", "impacto": "O Impacto",
	"galeria": "A Galeria", "canto": "O Canto", "caminhos": "Os Caminhos", "voz": "A Voz",
	"prova": "A Prova",
}

var secoes: Array = []
var salas: Array = []
var semente := 0
var sorteada := false
var passo := 0
var total := [0, 0, 0, 0]
var vitorias := [0, 0, 0, 0]
var historico: Array = []
var virou := false


static func roteiro(n: int, sortear: bool, semente: int, percurso: Array) -> Array:
	if not sortear:
		if NA_ORDEM.has(n):
			return NA_ORDEM[n].duplicate()
		return percurso.duplicate()
	var outras: Array = percurso.filter(func(s): return s != "prova")
	var rng := RandomNumberGenerator.new()
	rng.seed = semente * 977 + n
	for i in range(outras.size() - 1, 0, -1):
		var k := rng.randi_range(0, i)
		var tmp = outras[i]
		outras[i] = outras[k]
		outras[k] = tmp
	var r: Array = outras.slice(0, clampi(n - 1, 0, outras.size()))
	r.append("prova")
	return r


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


static func nome(id: String) -> String:
	var t := Catalogo.titulo(id)
	return t if t != "" else str(NOMES.get(Catalogo.apelido(id), id))


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


func metade() -> int:
	return ceili(salas.size() / 2.0)


func lado() -> String:
	return "B" if passo >= metade() else "A"


func rotulo() -> String:
	return "Partida · sala %d de %d" % [mini(passo + 1, salas.size()), salas.size()]


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


func podio(presentes: Array) -> Array:
	var lista: Array = []
	for l in presentes:
		lista.append({"lugar": l, "total": total[l], "vitorias": vitorias[l]})
	lista.sort_custom(func(a, b): return _acima(int(a.lugar), int(b.lugar)))
	for i in lista.size():
		lista[i]["degrau"] = i + 1
		lista[i]["criterio"] = _criterio(int(lista[i].lugar), int(lista[i + 1].lugar)) if i + 1 < lista.size() else ""
	return lista


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


func _sorteio(l: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente * 7919 + 104729 * (l + 1)
	return rng.randi()


func presentes() -> Array:
	var r: Array = []
	for l in 4:
		for h in historico:
			if int(h.colocacao[l]) > 0:
				r.append(l)
				break
	return r
