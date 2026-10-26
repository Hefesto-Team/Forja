class_name Colecao
extends RefCounted

const ARQUIVO := "user://colecao.cfg"
const DESBLOQUEIOS := {
	"Dourado": "o primeiro troféu da noite",
	"Cromado": "três seções acesas",
	"Néon": "um coop sem erro",
}
const SECOES := 9
const NOITES_GUARDADAS := 14

static var noite := ""
static var vencidos := {}
static var recordes := {}
static var trofeus: Array = []
static var desbloqueados: Array = []
static var _robo := false


static func carregar(robo: bool) -> void:
	_robo = robo
	zerar()
	noite = Opcoes.noite()
	if robo:
		return
	ler(ARQUIVO)


static func ler(arquivo: String) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(arquivo) != OK or not cfg.has_section(noite):
		return
	var v = cfg.get_value(noite, "vencidos", {})
	vencidos = (v as Dictionary).duplicate() if v is Dictionary else {}
	var r = cfg.get_value(noite, "recordes", {})
	recordes = (r as Dictionary).duplicate() if r is Dictionary else {}
	var t = cfg.get_value(noite, "trofeus", [])
	trofeus = (t as Array).duplicate() if t is Array else []
	var d = cfg.get_value(noite, "desbloqueados", [])
	desbloqueados = (d as Array).duplicate() if d is Array else []


static func guardar() -> void:
	gravar(_robo)


static func gravar(robo: bool, arquivo := ARQUIVO) -> void:
	if robo:
		return
	var cfg := ConfigFile.new()
	cfg.load(arquivo)
	var secoes := cfg.get_sections()
	secoes.sort()
	while secoes.size() >= NOITES_GUARDADAS and not cfg.has_section(noite):
		cfg.erase_section(secoes[0])
		secoes.remove_at(0)
	cfg.set_value(noite, "vencidos", vencidos)
	cfg.set_value(noite, "recordes", recordes)
	cfg.set_value(noite, "trofeus", trofeus)
	cfg.set_value(noite, "desbloqueados", desbloqueados)
	cfg.save(arquivo)


static func zerar() -> void:
	vencidos = {}
	recordes = {}
	trofeus = []
	desbloqueados = []


static func registrar(id: String, pontos: Array, presentes: Array, coop := false, sem_erro := false) -> Dictionary:
	var novos: Array = []
	var recorde := -1
	var vencedor := -1
	var maior := 0
	for l in presentes:
		var p := int(pontos[l]) if int(l) < pontos.size() else 0
		if p > maior or (p == maior and vencedor >= 0 and int(l) < vencedor and p > 0):
			maior = p
			vencedor = int(l)
	if vencedor >= 0:
		if not vencidos.has(id):
			vencidos[id] = vencedor
			trofeus.append({"id": id, "lugar": vencedor, "tipo": "vitoria"})
			novos.append("vitoria")
		if recordes.has(id) and maior > int(recordes[id]):
			trofeus.append({"id": id, "lugar": vencedor, "tipo": "recorde"})
			novos.append("recorde")
			recorde = vencedor
		recordes[id] = maxi(int(recordes.get(id, 0)), maior)
	if coop and sem_erro:
		trofeus.append({"id": id, "lugar": -1, "tipo": "coop"})
		novos.append("coop")
	var ganhos: Array = []
	var condicoes := {
		"Dourado": trofeus.size() >= 1,
		"Cromado": secoes_acesas() >= 3,
		"Néon": trofeus.any(func(t): return t.get("tipo") == "coop"),
	}
	for nome in DESBLOQUEIOS:
		if condicoes[nome] and not (nome in desbloqueados):
			desbloqueados.append(nome)
			ganhos.append(nome)
	Forja.evento("colecao", 0, {"id": id, "trofeus": novos, "desbloqueou": ganhos})
	Forja.registrar("coleção: %s %s%s" % [id, novos, (" · " + ", ".join(ganhos)) if not ganhos.is_empty() else ""])
	guardar()
	return {"desbloqueou": ganhos, "recorde": recorde}


static func minigames_da_secao(id_do_portao: String) -> Array:
	return [id_do_portao]


static func secao_acesa(id_do_portao: String) -> bool:
	var todos := minigames_da_secao(id_do_portao)
	if todos.is_empty():
		return false
	for m in todos:
		if not vencidos.has(m):
			return false
	return true


static func secoes_acesas() -> int:
	var n := 0
	for p in Salao.PORTOES:
		if secao_acesa(str(p.id)):
			n += 1
	if vencidos.has("prova"):
		n += 1
	return n


static func marcas(id_do_portao: String) -> Array:
	var m: Array = []
	for id in minigames_da_secao(id_do_portao):
		m.append(vencidos.has(id))
	return m


static func desbloqueado(nome: String) -> bool:
	return nome in desbloqueados
