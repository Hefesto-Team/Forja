class_name Colecao
extends RefCounted
## A coleção da noite (G06): o que o grupo conquistou jogando. Uma taça na cor de quem
## venceu um minigame primeiro, uma moeda para o recorde, quatro cubos para o coop sem
## erro. Uma seção acende quando todos os minigames dela foram vencidos na noite. Nada
## daqui muda stat: só aparência (o Dourado, o Cromado, o Néon).
##
## É da noite (`Opcoes.noite()`): outra noite começa vazia. Guardada em user://colecao.cfg,
## uma seção por noite. Com o robô (as provas), nada se lê nem se grava.

const ARQUIVO := "user://colecao.cfg"
## Os acabamentos que a coleção desbloqueia, e o que desbloqueia cada um.
const DESBLOQUEIOS := {
	"Dourado": "o primeiro troféu da noite",
	"Cromado": "três seções acesas",
	"Néon": "um coop sem erro",
}
const SECOES := 9                      ## os 8 portões e A Prova
const NOITES_GUARDADAS := 14           ## as seções mais velhas do arquivo se apagam

static var noite := ""                 ## Opcoes.noite() da coleção carregada
static var vencidos := {}              ## id do minigame -> lugar que venceu primeiro na noite
static var recordes := {}              ## id do minigame -> os pontos mais altos da noite
static var trofeus: Array = []         ## [{"id", "lugar", "tipo": "vitoria" | "recorde" | "coop"}]
static var desbloqueados: Array = []   ## os nomes de DESBLOQUEIOS já ganhos na noite
static var _robo := false


## Lê a seção da noite de hoje; outra noite começa vazia.
static func carregar(robo: bool) -> void:
	_robo = robo
	zerar()
	noite = Opcoes.noite()
	if robo:
		return
	ler(ARQUIVO)


## Lê o arquivo por cima do que há (a prova lê um arquivo dela, não o da pessoa).
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


## Grava (nada com o robô).
static func guardar() -> void:
	gravar(_robo)


static func gravar(robo: bool, arquivo := ARQUIVO) -> void:
	if robo:
		return
	var cfg := ConfigFile.new()
	cfg.load(arquivo)   # as outras noites ficam
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


## A coleção vazia (a prova usa).
static func zerar() -> void:
	vencidos = {}
	recordes = {}
	trofeus = []
	desbloqueados = []


## Um minigame acabou: devolve {"desbloqueou": [nomes], "recorde": lugar ou -1}.
static func registrar(id: String, pontos: Array, presentes: Array, coop := false, sem_erro := false) -> Dictionary:
	var novos: Array = []
	var recorde := -1
	# o vencedor: entre os presentes, o de mais pontos, se for > 0; empate em cima: o menor lugar
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
	# os desbloqueios, na ordem, cada um uma vez
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


## Os minigames de uma seção. Hoje cada seção tem um só, o do apelido dela; com o catálogo
## das seções (`catalogo.gd`, H04) viram os `"minigames"` da seção cujo primeiro é `id`.
static func minigames_da_secao(id_do_portao: String) -> Array:
	return [id_do_portao]


## A seção acende quando todos os minigames dela foram vencidos na noite.
static func secao_acesa(id_do_portao: String) -> bool:
	var todos := minigames_da_secao(id_do_portao)
	if todos.is_empty():
		return false
	for m in todos:
		if not vencidos.has(m):
			return false
	return true


## De 0 a SECOES: os 8 portões e A Prova (ela conta pela vitória, sem portão).
static func secoes_acesas() -> int:
	var n := 0
	for p in Salao.PORTOES:
		if secao_acesa(str(p.id)):
			n += 1
	if vencidos.has("prova"):
		n += 1
	return n


## Um bool por minigame da seção: vencido na noite?
static func marcas(id_do_portao: String) -> Array:
	var m: Array = []
	for id in minigames_da_secao(id_do_portao):
		m.append(vencidos.has(id))
	return m


static func desbloqueado(nome: String) -> bool:
	return nome in desbloqueados
