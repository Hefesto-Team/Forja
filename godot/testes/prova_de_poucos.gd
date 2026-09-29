extends Node
## A prova de poucos: toda sala jogável com 1, 2 ou 3 controles. Abre o jogo
## com N DualSense simulados (--simular=N) e o robô joga cada sala do começo ao
## fim: a sala tem de acabar sozinha, sem erro, com um veredito para cada lugar
## presente e nenhum para o lugar vazio — e o aviso diz o que muda.
##
##   godot --headless --fixed-fps 60 --path godot res://testes/prova_de_poucos.tscn \
##     -- --simular=2 --robo --semente=7 --relatorios=<pasta vazia>

const SALAS := ["centelha", "viga", "molde", "impacto", "galeria", "canto", "caminhos", "voz", "prova"]

var falhas := 0
var jogo: Node


func _esperar(cond: bool, msg: String) -> void:
	if cond:
		print("ok   ", msg)
	else:
		printerr("FAIL ", msg)
		falhas += 1


func _quadros(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _ready() -> void:
	jogo = load("res://scenes/main.tscn").instantiate()
	add_child(jogo)
	await _quadros(10)
	var n := Forja.conectados()
	for p in Forja.pads():
		Forja.entrar(int(p.pad))
	jogo._sincronizar_jogadores()
	jogo._ir_para_o_salao(false)
	await _quadros(4)
	_esperar(Forja.jogadores() == n, "%d lugar(es) ocupado(s)" % n)
	var pedidas := OS.get_environment("SALAS")
	var salas: Array = Array(pedidas.split(",")) if pedidas != "" else SALAS
	for id in salas:
		await _joga(id, n)
	if falhas > 0:
		printerr("%d falha(s) com %d controle(s)" % [falhas, n])
		get_tree().quit(1)
	else:
		print("prova de poucos ok — as salas com %d controle(s)" % n)
		get_tree().quit(0)


func _joga(id: String, n: int) -> void:
	jogo._entrar_na_sala(id, false)
	await _quadros(2)
	var sala = jogo.sala
	if not sala is SalaJogo or sala.id != id:
		_esperar(false, "%s: a sala abriu" % id)
		return
	# só as salas que mudam dizem; A Prova sempre muda com menos de quatro
	if id == "prova":
		_esperar(sala.com_poucos() != "" if n < 4 else sala.com_poucos() == "",
			"%s com %d: o selo diz o que muda (%s)" % [id, n, sala.com_poucos()])
	var q := 0
	while is_instance_valid(sala) and sala.fase != "fim" and q < 20000:
		await _quadros(10)
		q += 10
	_esperar(is_instance_valid(sala) and sala.fase == "fim", "%s com %d: a sala acabou sozinha (%d quadros)" % [id, n, q])
	if not is_instance_valid(sala):
		return
	for l in 4:
		var tem: bool = sala.vereditos.has(l) and not Array(sala.vereditos[l]).is_empty()
		_esperar(tem == (l < n), "%s com %d: P%d %s" % [id, n, l + 1, "tem veredito" if l < n else "vazio, sem veredito"])
		for v in sala.vereditos.get(l, []):
			# faltar gente nunca é defeito: sem vizinho, o isolamento fica «não medido»
			_esperar(int(v.get("resultado", -1)) != Forja.FALHOU, "%s com %d: P%d %s não falhou (%s)" % [
				id, n, l + 1, str(v.get("feature", "")), str(v.get("obs", v.get("medido", "")))])
	q = 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "%s com %d: de volta ao salão" % [id, n])
