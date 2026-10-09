extends RefCounted
## O RPG da Forja lido das tabelas de docs/jogo/sistemas (as mesmas contas do
## conferir.py): os stats, o arquétipo, o item que o corpo alcança e a liga.

const ST := ["peso", "passo", "folego", "faro"]
const NOME_ST := ["Peso", "Passo", "Fôlego", "Faro"]
const EMBLEMA := {"peso": "Bigorna", "passo": "Mola", "folego": "Brasa", "faro": "Lume"}
const OPOSTO := {"peso": "passo", "passo": "peso", "folego": "faro", "faro": "folego"}
const PARTES := ["cabeca", "superior", "inferior"]

static var _tabelas := {}


static func tabela(nome: String) -> Array:
	if _tabelas.has(nome):
		return _tabelas[nome]
	var caminho := ProjectSettings.globalize_path("res://").path_join("../docs/jogo/sistemas/" + nome)
	var f := FileAccess.open(caminho.simplify_path(), FileAccess.READ)
	var linhas := []
	var cab := f.get_csv_line()
	while not f.eof_reached():
		var l := f.get_csv_line()
		if l.size() < cab.size():
			continue
		var d := {}
		for i in cab.size():
			d[cab[i]] = l[i]
		linhas.append(d)
	_tabelas[nome] = linhas
	return linhas


## A peça de uma parte pelo personagem.
static func peca(parte: String, personagem: String) -> Dictionary:
	for p in tabela("pecas.csv"):
		if p.parte == parte and p.personagem == personagem:
			return p
	return {}


static func item(id: String) -> Dictionary:
	for i in tabela("itens.csv"):
		if i.id == id:
			return i
	return {}


## As contas de um corpo: stats (com o teto), os pontos perdidos, o arquétipo
## (os dois mais altos; no empate, mais peças com o emblema; depois a ordem
## Peso, Passo, Fôlego, Faro) e se a regra dos opostos deixa.
static func corpo(personagens: Array) -> Dictionary:
	var ps := []
	for i in 3:
		ps.append(peca(PARTES[i], personagens[i]))
	var cru := [1, 1, 1, 1]
	var emblemas := []
	for p in ps:
		emblemas.append(p.principal)
		for j in 4:
			cru[j] += int(p[ST[j]])
	var st := []
	var perdidos := 0
	for j in 4:
		st.append(mini(cru[j], 5))
		perdidos += cru[j] - st[j]
	var ordem := [0, 1, 2, 3]
	ordem.sort_custom(func(a, b):
		if st[a] != st[b]:
			return st[a] > st[b]
		var ca := emblemas.count(ST[a])
		var cb := emblemas.count(ST[b])
		if ca != cb:
			return ca > cb
		return a < b)
	var dois := [ST[mini(ordem[0], ordem[1])], ST[maxi(ordem[0], ordem[1])]]
	var arq := ""
	for a in tabela("arquetipos.csv"):
		if (a.stat_a == dois[0] and a.stat_b == dois[1]) or (a.stat_a == dois[1] and a.stat_b == dois[0]):
			arq = a.nome
	var vale := true
	for e in emblemas:
		if OPOSTO[e] in emblemas:
			vale = false
	return {"pecas": ps, "stats": st, "perdidos": perdidos, "arquetipo": arq, "vale": vale,
		"emblemas": emblemas, "dois": dois}


## O item no corpo: "fora" (não alcança), "alcanca" ou "liga".
static func no_corpo(id: String, st: Array) -> String:
	var it := item(id)
	for j in 4:
		if st[j] < int(it["pede_" + ST[j]]):
			return "fora"
	for j in 4:
		if st[j] < int(it["liga_" + ST[j]]):
			return "alcanca"
	return "liga"


## A build boa: nada perdido, o item no canto (o que ele pede está entre os
## dois mais altos) e em liga.
static func build_boa(c: Dictionary, id: String) -> bool:
	if c.perdidos > 0 or no_corpo(id, c.stats) != "liga":
		return false
	var it := item(id)
	for j in 4:
		if int(it["pede_" + ST[j]]) > 0 and not (ST[j] in c.dois):
			return false
	return true
