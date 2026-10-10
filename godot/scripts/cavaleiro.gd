class_name Cavaleiro
extends RefCounted

const ST := ["peso", "passo", "folego", "faro"]
const NOME_ST := ["Peso", "Passo", "Fôlego", "Faro"]
const EMBLEMA := {"peso": "emb_bigorna", "passo": "emb_mola", "folego": "emb_brasa", "faro": "emb_lume"}
const PARTES := ["cabeca", "superior", "inferior"]
const PERSONAGENS := ["female-a", "female-b", "female-c", "female-d", "female-e", "female-f",
	"male-a", "male-b", "male-c", "male-d", "male-e", "male-f"]
const ITENS := ["martelo", "escudo", "fole", "lanterna", "diapasao", "ancora"]

static var stats := [[3, 3, 3, 3], [3, 3, 3, 3], [3, 3, 3, 3], [3, 3, 3, 3]]
static var no_relampago := false

static var _tabelas := {}
static var _pecas := {}


static func tabela(nome: String) -> Array:
	if _tabelas.has(nome):
		return _tabelas[nome]
	var linhas: Array = []
	var f := FileAccess.open("res://dados/%s.csv" % nome.trim_suffix(".csv"), FileAccess.READ)
	if f == null:
		push_error("Cavaleiro: sem res://dados/%s.csv (rode scripts/dados_do_cavaleiro.py)" % nome)
		return linhas
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


static func regra(chave: String) -> String:
	for r in tabela("regras"):
		if r.chave == chave:
			return str(r.valor)
	return ""


static func opostos() -> Dictionary:
	var o := {}
	for par in regra("opostos").split(";", false):
		var ab := par.split(":")
		if ab.size() == 2:
			o[ab[0]] = ab[1]
			o[ab[1]] = ab[0]
	return o


static func peca(parte: String, personagem: String) -> Dictionary:
	if _pecas.is_empty():
		for p in tabela("pecas"):
			_pecas["%s|%s" % [p.parte, p.personagem]] = p
	return _pecas.get("%s|%s" % [parte, personagem], {})


static func item(id: String) -> Dictionary:
	for i in tabela("itens"):
		if i.id == id:
			return i
	return {}


static func corpo(personagens: Array) -> Dictionary:
	var base := int(regra("stat_base"))
	var teto := int(regra("stat_teto"))
	var cru := [base, base, base, base]
	var principais: Array = []
	for i in 3:
		var p := peca(PARTES[i], str(personagens[i]))
		if p.is_empty():
			return {"stats": [base, base, base, base], "perdidos": 0, "arquetipo": {}, "valido": false, "principais": []}
		principais.append(str(p.principal))
		for j in 4:
			cru[j] += int(p[ST[j]])
	var st: Array = []
	var perdidos := 0
	for j in 4:
		st.append(mini(cru[j], teto))
		perdidos += cru[j] - st[j]
	var ordem := [0, 1, 2, 3]
	ordem.sort_custom(func(a: int, b: int) -> bool:
		if st[a] != st[b]:
			return st[a] > st[b]
		var ca := principais.count(ST[a])
		var cb := principais.count(ST[b])
		if ca != cb:
			return ca > cb
		return a < b)
	var par := [ST[ordem[0]], ST[ordem[1]]]
	var arq := {}
	for a in tabela("arquetipos"):
		if (a.stat_a == par[0] and a.stat_b == par[1]) or (a.stat_a == par[1] and a.stat_b == par[0]):
			arq = a
	var op := opostos()
	var valido := true
	for e in principais:
		if op.get(e, "") in principais:
			valido = false
	return {"stats": st, "perdidos": perdidos, "arquetipo": arq, "valido": valido, "principais": principais}


static func no_corpo(id: String, st: Array) -> String:
	var it := item(id)
	if it.is_empty():
		return "fora"
	for j in 4:
		if int(st[j]) < int(it["pede_" + ST[j]]):
			return "fora"
	for j in 4:
		if int(st[j]) < int(it["liga_" + ST[j]]):
			return "alcanca"
	return "liga"


static func coerente(id: String, st: Array) -> bool:
	var it := item(id)
	var ordem := [0, 1, 2, 3]
	ordem.sort_custom(func(a: int, b: int) -> bool: return st[a] > st[b] if st[a] != st[b] else a < b)
	for j in 4:
		if int(it.get("pede_" + ST[j], "0")) > 0 and not (j in [ordem[0], ordem[1]]):
			return false
	return true


static func build_boa(c: Dictionary, id: String) -> bool:
	return int(c.perdidos) == 0 and no_corpo(id, c.stats) == "liga" and coerente(id, c.stats)


static func chaves(personagens: Array) -> Array:
	var p: Array = corpo(personagens).principais
	var c := -1 if "peso" in p else (1 if "passo" in p else 0)
	var e := -1 if "folego" in p else (1 if "faro" in p else 0)
	return [c, e]


static func alcancaveis(st: Array) -> Array:
	var v: Array = []
	for id in ITENS:
		if no_corpo(id, st) != "fora":
			v.append(id)
	return v


static func troca_da_liga(personagens: Array, id: String) -> Dictionary:
	for k in 3:
		for nova in PERSONAGENS:
			if nova == personagens[k]:
				continue
			var t := personagens.duplicate()
			t[k] = nova
			var c := corpo(t)
			if c.valido and no_corpo(id, c.stats) == "liga":
				return {"parte": k, "personagem": nova}
	return {}


static func gancho(l: int, nome: String) -> float:
	for g in tabela("stats"):
		if g.gancho == nome:
			var neutro := float(g.neutro)
			if no_relampago and regra("stats_no_relampago") == "nao":
				return neutro
			var j := ST.find(str(g.stat))
			return neutro + float(g.por_ponto) * (int(stats[clampi(l, 0, 3)][j]) - 3)
	return 1.0


static func pre_montado(lugar: int, ocupados: Dictionary, travado := {}) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = Forja.semente * 31 + lugar
	var arqs_dos_outros: Array = []
	var cabecas_dos_outros: Array = []
	var nomes_dos_outros: Array = []
	for k in ocupados:
		if int(k) == lugar:
			continue
		var c: Dictionary = ocupados[k]
		var pc: Array = [str(c.get("cabeca", "")), str(c.get("superior", "")), str(c.get("inferior", ""))]
		cabecas_dos_outros.append(pc[0])
		nomes_dos_outros.append(str(c.get("nome", "")))
		var co := corpo(pc)
		if not co.arquetipo.is_empty():
			arqs_dos_outros.append(str(co.arquetipo.id))
	var unica := regra("cabeca_unica_na_mesa") == "sim"
	var candidatos: Array = []
	for a in PERSONAGENS:
		if travado.has(0) and travado[0] != a:
			continue
		if unica and a in cabecas_dos_outros:
			continue
		for b in PERSONAGENS:
			if travado.has(1) and travado[1] != b:
				continue
			for c in PERSONAGENS:
				if travado.has(2) and travado[2] != c:
					continue
				for id in ITENS:
					if travado.has("item") and travado["item"] != id:
						continue
					candidatos.append([a, b, c, id])
	for i in range(candidatos.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = candidatos[i]
		candidatos[i] = candidatos[j]
		candidatos[j] = t
	for nivel in [4, 2, 1, 0]:
		for cand in candidatos:
			var pc: Array = [cand[0], cand[1], cand[2]]
			var co := corpo(pc)
			if not co.valido or no_corpo(str(cand[3]), co.stats) == "fora":
				continue
			if nivel >= 1 and int(co.perdidos) > 0:
				continue
			if nivel >= 2 and (co.arquetipo.is_empty() or co.arquetipo.raro != "nao" or str(co.arquetipo.id) in arqs_dos_outros):
				continue
			var troca := {}
			if nivel >= 4:
				if not coerente(str(cand[3]), co.stats) or no_corpo(str(cand[3]), co.stats) != "alcanca":
					continue
				troca = troca_da_liga(pc, str(cand[3]))
				if troca.is_empty():
					continue
			return {"pecas": pc, "item": cand[3], "nome": _nome(rng, co.arquetipo, nomes_dos_outros), "troca": troca}
	return {"pecas": ["male-a", "male-a", "male-a"], "item": "martelo", "nome": _nome(rng, {}, nomes_dos_outros), "troca": {}}


static func _nome(rng: RandomNumberGenerator, arq: Dictionary, usados: Array) -> String:
	var do_arq: Array = []
	var todos: Array = []
	for n in tabela("nomes"):
		if str(n.nome) in usados:
			continue
		todos.append(str(n.nome))
		if not arq.is_empty() and n.arquetipo == arq.id:
			do_arq.append(str(n.nome))
	var lista := do_arq if not do_arq.is_empty() else todos
	if lista.is_empty():
		return ""
	return str(lista[rng.randi_range(0, lista.size() - 1)])
