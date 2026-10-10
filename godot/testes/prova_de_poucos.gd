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


## OPCOES_DE_TESTE=1: a vibração do P2 em 0% e o gatilho do P3 desligado
## (as opções do lugar), e as contas do gatilho fraco.
var com_opcoes := false
## CABO=1: no meio de cada sala, o cabo do P2 sai por 3 s e volta.
var com_cabo := false


func _ready() -> void:
	com_opcoes = OS.get_environment("OPCOES_DE_TESTE") == "1"
	com_cabo = OS.get_environment("CABO") == "1"
	com_cabo_sozinho = OS.get_environment("CABO_SOZINHO") == "1"
	if com_opcoes:
		_prova_das_contas_das_opcoes()
		Opcoes.vibracao[1] = 0
		Opcoes.gatilho[2] = Opcoes.GATILHO_DESLIGADO
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
	if not sala is SalaJogo or (sala.id != id and Catalogo.apelido(sala.id) != id):
		_esperar(false, "%s: a sala abriu" % id)
		return
	# só as salas que mudam dizem; A Prova sempre muda com menos de quatro
	if id == "prova":
		_esperar(sala.com_poucos() != "" if n < 4 else sala.com_poucos() == "",
			"%s com %d: o selo diz o que muda (%s)" % [id, n, sala.com_poucos()])
	var q := 0
	if com_cabo:
		await _tira_e_poe_o_cabo(sala, id)
	if com_cabo_sozinho:
		await _sozinho_sem_cabo(sala, id)
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
			if com_cabo:
				if l == 1:
					# o cabo que cai não é defeito: passou ou não medido, nunca falhou
					_esperar(int(v.get("resultado", -1)) != Forja.FALHOU, "%s: o P2, que perdeu o cabo, %s → %s (%s)" % [
						id, str(v.get("feature", "")), str(v.get("rotulo", "")), str(v.get("obs", ""))])
				else:
					_esperar(int(v.get("resultado", -1)) == Forja.PASSOU, "%s: com o cabo do P2 fora, o P%d %s passou" % [
						id, l + 1, str(v.get("feature", ""))])
				continue
			if com_opcoes:
				var motivo := Opcoes.por_que_nao_mede(l, str(v.get("feature", "")))
				if motivo != "":
					_esperar(int(v.get("resultado", -1)) == Forja.NAO_MEDIDO and str(v.get("obs", "")) == motivo,
						"%s: P%d %s desligado nas opções → não medido" % [id, l + 1, str(v.get("feature", ""))])
					var gravado := Forja.ultimo_veredito(l, str(v.get("feature", "")))
					_esperar(int(gravado.get("resultado", -1)) == Forja.NAO_MEDIDO, "%s: P%d e o relatório diz o mesmo" % [id, l + 1])
				elif l != 1 and l != 2:
					_esperar(int(v.get("resultado", -1)) == Forja.PASSOU, "%s: P%d %s, com as opções de fábrica, passou" % [
						id, l + 1, str(v.get("feature", ""))])
			# faltar gente nunca é defeito: sem vizinho, o isolamento fica «não medido»
			_esperar(int(v.get("resultado", -1)) != Forja.FALHOU, "%s com %d: P%d %s não falhou (%s)" % [
				id, n, l + 1, str(v.get("feature", "")), str(v.get("obs", v.get("medido", "")))])
	q = 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "%s com %d: de volta ao salão" % [id, n])


func _prova_das_contas_das_opcoes() -> void:
	Opcoes.gatilho[0] = Opcoes.GATILHO_FRACO
	_esperar(Opcoes.ajustar_gatilho(0, Forja.GATILHO_ARMA, 2, 6, 8) == [Forja.GATILHO_ARMA, 2, 6, 4], "gatilho fraco: a arma com metade da força")
	_esperar(Opcoes.ajustar_gatilho(0, Forja.GATILHO_RESISTENCIA, 1, 6, 0) == [Forja.GATILHO_RESISTENCIA, 1, 3, 0], "gatilho fraco: a resistência com metade")
	Opcoes.gatilho[0] = Opcoes.GATILHO_DESLIGADO
	_esperar(Opcoes.ajustar_gatilho(0, Forja.GATILHO_VIBRACAO, 0, 7, 30) == [Forja.GATILHO_OFF, 0, 0, 0], "gatilho desligado: sempre Off")
	Opcoes.gatilho[0] = Opcoes.GATILHO_FORTE
	_esperar(Opcoes.ajustar_gatilho(0, Forja.GATILHO_ARMA, 2, 6, 8) == [Forja.GATILHO_ARMA, 2, 6, 8], "gatilho forte: como a sala mandou")
	Opcoes.vibracao[0] = 50
	_esperar(is_equal_approx(Opcoes.escala_vibracao(0), 0.5), "vibração em 50%: metade")
	Opcoes.vibracao[0] = 100


## O cabo do P2 sai no meio do jogo e volta: a sala segue, o lugar espera, e o
## controle volta ao mesmo lugar, com o mesmo player index.
func _tira_e_poe_o_cabo(sala, id: String) -> void:
	var q := 0
	while is_instance_valid(sala) and (sala.fase != "jogo" or sala.t_fase < 2.0) and q < 3000:
		await _quadros(1)
		q += 1
	if not is_instance_valid(sala) or sala.fase != "jogo":
		_esperar(false, "%s: a sala chegou ao jogo para tirar o cabo" % id)
		return
	_esperar(Forja.ctl.simulador_cabo(1, false), "%s: o cabo do P2 saiu" % id)
	await _quadros(180)
	_esperar(is_instance_valid(sala) and sala.fase in ["jogo", "fim"], "%s: sem o P2, a sala seguiu" % id)
	_esperar(not Forja.lugar(1).get("conectado", true) and Forja.ocupado(1), "%s: o lugar do P2 espera, sem controle" % id)
	_esperar(Forja.ctl.simulador_cabo(1, true), "%s: o cabo do P2 voltou" % id)
	q = 0
	while not Forja.lugar(1).get("conectado", false) and q < 300:
		await _quadros(1)
		q += 1
	await _quadros(4)
	_esperar(Forja.lugar(1).get("conectado", false), "%s: o P2 voltou ao lugar" % id)
	var p: Dictionary = Forja.ctl.percepcao(Forja.pad_do_lugar(1))
	_esperar(int(p.get("player_index", -9)) == 1, "%s: com o mesmo player index (1)" % id)


## CABO_SOZINHO=1 (F09c): um jogador só, e o cabo dele cai no meio da sala.
var com_cabo_sozinho := false


## Sozinho, o cabo cai no meio do jogo: a sala espera (não termina, o relógio
## dela não anda, a tela de reconectar à vista) e, quando ele volta, a tela
## some e a sala segue de onde parou, até acabar sozinha.
func _sozinho_sem_cabo(sala, id: String) -> void:
	var q := 0
	while is_instance_valid(sala) and (sala.fase != "jogo" or sala.treinando or sala.t_fase < 2.0) and q < 6000:
		await _quadros(1)
		q += 1
	if not is_instance_valid(sala) or sala.fase != "jogo":
		_esperar(false, "%s: a sala chegou ao jogo para tirar o cabo" % id)
		return
	_esperar(Forja.ctl.simulador_cabo(0, false), "%s sozinho: o cabo do P1 saiu" % id)
	await _quadros(30)
	# os dois relógios: o da sala (t_jogo, em quadros de jogo) e o tempo jogado (no minigame, o da música)
	var t_sala: float = sala.t_jogo if is_instance_valid(sala) else -1.0
	var jogado: float = sala.tempo_jogado() if is_instance_valid(sala) else -1.0
	await _quadros(600)
	_esperar(is_instance_valid(sala) and sala.fase == "jogo", "%s sozinho: 10 s sem controle, a sala não terminou (%s)" % [
		id, str(sala.fase) if is_instance_valid(sala) else "fechada"])
	if not is_instance_valid(sala):
		return
	_esperar(absf(float(sala.t_jogo) - t_sala) < 0.05 and absf(float(sala.tempo_jogado()) - jogado) < 0.05,
		"%s sozinho: sem controle, o relógio da sala parou (%.2f → %.2f s; jogado %.2f → %.2f s)" % [
		id, t_sala, float(sala.t_jogo), jogado, float(sala.tempo_jogado())])
	_esperar(sala.esperando_controle and sala._tela_reconectar != null and sala._tela_reconectar.is_visible_in_tree(),
		"%s sozinho: a tela de reconectar está à vista" % id)
	_esperar(Forja.ctl.simulador_cabo(0, true), "%s sozinho: o cabo do P1 voltou" % id)
	q = 0
	while not Forja.lugar(0).get("conectado", false) and q < 300:
		await _quadros(1)
		q += 1
	await _quadros(2)
	_esperar(not sala.esperando_controle and sala._tela_reconectar == null, "%s sozinho: com o controle de volta, a tela sumiu" % id)
	t_sala = float(sala.t_jogo)
	await _quadros(60)
	_esperar(is_instance_valid(sala) and (sala.fase == "fim" or float(sala.t_jogo) > t_sala + 0.5),
		"%s sozinho: a sala seguiu de onde parou (%.2f → %.2f s)" % [id, t_sala, float(sala.t_jogo) if is_instance_valid(sala) else -1.0])
