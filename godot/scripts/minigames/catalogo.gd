class_name Catalogo
extends RefCounted

const SECOES := [
	{"id": "S01", "nome": "A Centelha", "apelido": "centelha", "minigames": ["S01_J01"]},
	{"id": "S02", "nome": "A Viga", "apelido": "viga", "minigames": []},
	{"id": "S03", "nome": "O Molde", "apelido": "molde", "minigames": []},
	{"id": "S04", "nome": "O Impacto", "apelido": "impacto", "minigames": []},
	{"id": "S05", "nome": "A Galeria", "apelido": "galeria", "minigames": []},
	{"id": "S06", "nome": "O Canto", "apelido": "canto", "minigames": []},
	{"id": "S07", "nome": "Os Caminhos", "apelido": "caminhos", "minigames": []},
	{"id": "S08", "nome": "A Voz", "apelido": "voz", "minigames": []},
	{"id": "S09", "nome": "A Prova", "apelido": "prova", "minigames": []},
]
const MINIGAMES := {
	"S01_J01": preload("res://scripts/minigames/s01/martelo_de_hefesto.gd"),
}
const SALAS_ANTIGAS := {
	"viga": preload("res://scripts/salas/viga.gd"),
	"molde": preload("res://scripts/salas/molde.gd"),
	"impacto": preload("res://scripts/salas/impacto.gd"),
	"galeria": preload("res://scripts/salas/galeria.gd"),
	"canto": preload("res://scripts/salas/canto.gd"),
	"caminhos": preload("res://scripts/salas/caminhos.gd"),
	"voz": preload("res://scripts/salas/voz.gd"),
	"prova": preload("res://scripts/salas/prova.gd"),
	"bancada": preload("res://scripts/salas/bancada.gd"),
}
const NOMES_VELHOS := {"giro": "viga"}


static func resolver(id: String) -> String:
	var chave: String = NOMES_VELHOS.get(id, id)
	for s in SECOES:
		if s.apelido == chave and not s.minigames.is_empty():
			return s.minigames[0]
	return chave


static func existe(id: String) -> bool:
	var chave := resolver(id)
	return MINIGAMES.has(chave) or SALAS_ANTIGAS.has(chave)


static func criar(id: String) -> Sala:
	var chave := resolver(id)
	if MINIGAMES.has(chave):
		return MINIGAMES[chave].new()
	if SALAS_ANTIGAS.has(chave):
		return SALAS_ANTIGAS[chave].new()
	return null


static func apelido(id: String) -> String:
	for s in SECOES:
		if id in s.minigames:
			return s.apelido
	return id


static func secao(id: String) -> Dictionary:
	var chave: String = NOMES_VELHOS.get(id, id)
	for s in SECOES:
		if s.apelido == chave or s.id == chave or chave in s.minigames:
			return s
	return {}


static func ordem(lista: Array, chave: String, semente: int) -> Array:
	var r := lista.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d" % [chave, semente])
	for i in range(r.size() - 1, 0, -1):
		var k := rng.randi_range(0, i)
		var tmp = r[i]
		r[i] = r[k]
		r[k] = tmp
	return r


static func sortear(apelido: String, semente: int, vez: int) -> String:
	var s := secao(apelido)
	if s.is_empty():
		return str(NOMES_VELHOS.get(apelido, apelido))
	var lista: Array = s.minigames
	if lista.is_empty():
		return str(s.apelido)
	var o := ordem(lista, str(s.apelido), semente)
	return str(o[posmod(vez, o.size())])


static func proximo(apelido: String, semente: int, jogados: Dictionary) -> String:
	var s := secao(apelido)
	if s.is_empty() or s.minigames.is_empty():
		return sortear(apelido, semente, 0)
	for vez in s.minigames.size():
		var slot := sortear(apelido, semente, vez)
		if not jogados.has(slot):
			return slot
	return sortear(apelido, semente, 0)


static func titulo(slot: String) -> String:
	if not MINIGAMES.has(slot):
		return ""
	var f = (MINIGAMES[slot] as Script).get_script_constant_map().get("FICHA", {})
	return str((f as Dictionary).get("titulo", slot))
