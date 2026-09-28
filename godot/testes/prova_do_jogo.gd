extends Node
## A prova do jogo, sem janela e sem aparelho: abre a cena principal com quatro
## DualSense simulados (o módulo nativo inteiro roda, o SDL inclusive) e confere,
## pelo que cada controle simulado RECEBEU, que cada saída chegou só no lugar
## certo — o player index 0..3, a luz e as lâmpadas do lugar, os modos de
## gatilho, o motor do lado do golpe, o LED do mudo. No fim, o relatório gravado:
## JSON que se lê, os quatro controles, nenhum endereço de aparelho e nenhum
## caminho da máquina dentro dos arquivos.
##
##   godot --headless --fixed-fps 60 --path godot res://testes/prova_do_jogo.tscn \
##     -- --simular=4 --robo --semente=7 --relatorios=<pasta vazia>
##
## Com o pactl de mentira na frente do PATH (tests/prova_do_jogo.sh), ESPERADO
## diz o nome do alto-falante que o jogo tem de achar.

var falhas := 0
var jogo: Node
var pasta := ""


func _esperar(cond: bool, msg: String) -> void:
	if cond:
		print("ok   ", msg)
	else:
		printerr("FAIL ", msg)
		falhas += 1


func _quadros(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _aperta(sim: int, botao: int) -> void:
	Forja.ctl.simulador_botao(sim, botao, true)
	await _quadros(2)
	Forja.ctl.simulador_botao(sim, botao, false)
	await _quadros(2)


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--relatorios="):
			pasta = a.substr(13)
	_prova_a_lista()
	_prova_o_microfone()
	_prova_o_alto_falante_do_sistema()
	jogo = load("res://scenes/main.tscn").instantiate()
	add_child(jogo)
	await _prova_do_percurso()
	await _prova_do_relatorio()
	if falhas > 0:
		printerr("%d falha(s)" % falhas)
		get_tree().quit(1)
	else:
		print("prova do jogo ok — lobby, player index, salas, diagnóstico e relatório")
		get_tree().quit(0)


func _perc(lugar: int) -> Dictionary:
	return Forja.ctl.percepcao(Forja.pad_do_lugar(lugar))


func _prova_do_percurso() -> void:
	await _quadros(10)
	_esperar(Forja.modulo, "o módulo nativo carregou")
	_esperar(Forja.conectados() == 4, "quatro DualSense simulados (%d)" % Forja.conectados())
	_esperar(Forja.jogadores() == 0, "ninguém no lugar antes do lobby")
	_esperar(jogo.estado == "titulo", "o jogo abre no título")

	await _aperta(0, Forja.CRUZ)
	await _quadros(40)
	_esperar(jogo.estado == "lobby", "✕ no título leva ao lobby")
	for s in 4:
		await _aperta(s, Forja.CRUZ)
	await _quadros(4)
	_esperar(Forja.jogadores() == 4, "os quatro entraram")
	for l in 4:
		var e: Dictionary = Forja.estado_saida(l)
		var p := _perc(l)
		_esperar(p.get("player_index", -9) == l, "P%d: o SDL deu o player index %d ao controle" % [l + 1, l])
		_esperar(int(p.get("leds_jogador", 0)) == Forja.LEDS_DO_LUGAR[l], "P%d: as lâmpadas do lugar chegaram" % (l + 1))
		var luz: Color = p.get("luz", Color.BLACK)
		_esperar(luz.is_equal_approx(Forja.cor_do_lugar(l)), "P%d: a barra de luz na cor do lugar" % (l + 1))
		_esperar(int(e.get("leds_jogador", 0)) == Forja.LEDS_DO_LUGAR[l], "P%d: o estado das lâmpadas" % (l + 1))
		_esperar(not jogo.lobby.prontos[l], "P%d: entrar não é ficar pronto" % (l + 1))
	# cada um nasce com um visual diferente, e escolhe o seu antes de ficar pronto
	var visuais := {}
	for l in 4:
		visuais["%d-%d" % [jogo.jogadores[l].modelo_i, jogo.jogadores[l].item_i]] = true
	_esperar(visuais.size() == 4, "os quatro lugares nascem com visuais diferentes")
	var m1: int = jogo.jogadores[0].modelo_i
	var m2: int = jogo.jogadores[1].modelo_i
	var i3: int = jogo.jogadores[2].item_i
	await _aperta(1, Forja.DIREITA)
	await _aperta(2, Forja.BAIXO)
	_esperar(jogo.jogadores[1].modelo_i != m2, "◀▶ troca o boneco do P2")
	_esperar(jogo.jogadores[0].modelo_i == m1, "e o do P1 fica como estava")
	_esperar(jogo.jogadores[2].item_i != i3, "▲▼ troca o que o P3 leva")
	for s in 4:
		await _aperta(s, Forja.CRUZ)
	await _quadros(150)
	_esperar(jogo.estado == "salao", "com os quatro prontos, o salão")

	await _aperta(0, Forja.CREATE)
	_esperar(jogo.overlay == "diagnostico", "Create abre o diagnóstico")
	await _aperta(0, Forja.CIRCULO)
	_esperar(jogo.overlay == "", "○ fecha o diagnóstico")

	# A Galeria: o R2 de cada um em Vibration; o L2 solto
	jogo._entrar_na_sala("galeria", false)
	await _quadros(6)
	for l in 4:
		var p := _perc(l)
		_esperar(int(Forja.estado_saida(l).get("r2", -1)) == Forja.GATILHO_VIBRACAO, "Galeria P%d: R2 em Vibration" % (l + 1))
		_esperar(int(p.get("gatilho_dir", 0)) == 0x26, "Galeria P%d: o controle recebeu o modo 0x26" % (l + 1))
		_esperar(int(p.get("gatilho_esq", 0)) == 0x05, "Galeria P%d: o L2 solto (0x05)" % (l + 1))

	# O Impacto: o golpe da esquerda no P3 treme só o motor esquerdo do P3
	jogo._entrar_na_sala("impacto", false)
	await _quadros(4)
	jogo.sala._golpe(jogo.jogadores[2], true)
	await _quadros(2)
	var p3 := _perc(2)
	_esperar(float(p3.get("forte", 0.0)) > 0.5 and float(p3.get("fraco", 1.0)) == 0.0, "Impacto: da esquerda, só o motor forte do P3")
	for l in [0, 1, 3]:
		var p := _perc(l)
		_esperar(float(p.get("forte", 0.0)) == 0.0 and float(p.get("fraco", 0.0)) == 0.0, "Impacto: o P%d não tremeu" % (l + 1))
	var luz3: Color = p3.get("luz", Color.BLACK)
	_esperar(luz3.get_luminance() < Forja.cor_do_lugar(2).get_luminance(), "Impacto: a luz do P3 caiu com a vida")
	jogo.sala._golpe(jogo.jogadores[1], false)
	await _quadros(2)
	var p2 := _perc(1)
	_esperar(float(p2.get("fraco", 0.0)) > 0.5 and float(p2.get("forte", 1.0)) == 0.0, "Impacto: da direita, só o motor fraco do P2")

	# A Viga: o giro do controle do P2 vira o P2, e só ele
	jogo._entrar_na_sala("viga", false)
	await _quadros(4)
	var antes: Array = jogo.sala.yaw.duplicate()
	Forja.ctl.simulador_giro(1, Vector3(0, 2.5, 0))
	await _quadros(30)
	Forja.ctl.simulador_giro(1, Vector3.ZERO)
	var depois: Array = jogo.sala.yaw
	_esperar(absf(depois[1] - antes[1]) > 0.3, "Viga: o giro virou o P2 (%.2f rad)" % (depois[1] - antes[1]))
	_esperar(absf(depois[0] - antes[0]) < 0.05 and absf(depois[3] - antes[3]) < 0.05, "Viga: o P1 e o P4 ficaram parados")

	# A Voz: o mudo do P3 acende o LED do P3, e só o dele
	jogo._entrar_na_sala("voz", false)
	await _quadros(4)
	await _aperta(2, Forja.MICROFONE)
	await _quadros(2)
	for l in 4:
		var aceso := int(_perc(l).get("led_mic", 0)) != 0
		_esperar(aceso == (l == 2), "Voz: LED do mudo do P%d %s" % [l + 1, "aceso" if l == 2 else "apagado"])

	# A Prova: R2 arma, L2 resistência, em todos
	jogo._entrar_na_sala("prova", false)
	await _quadros(4)
	for l in 4:
		var p := _perc(l)
		_esperar(int(p.get("gatilho_dir", 0)) == 0x25, "Prova P%d: R2 arma (0x25)" % (l + 1))
		_esperar(int(p.get("gatilho_esq", 0)) == 0x21, "Prova P%d: L2 resistência (0x21)" % (l + 1))

	jogo._ir_para_o_salao(false)
	await _quadros(4)
	for l in 4:
		var p := _perc(l)
		_esperar(int(p.get("gatilho_dir", 0)) == 0x05, "de volta ao salão, o R2 do P%d solto" % (l + 1))
	jogo._abrir_overlay("livro", 0)
	await _quadros(2)
	_esperar(jogo.overlay == "livro", "o livro abre")
	jogo._fechar_overlay()


func _prova_do_relatorio() -> void:
	Forja.veredito(0, "botoes", Forja.PASSOU, Forja.NIVEL_REAGIU, "apertar ✕", "✕ chegou")
	_esperar(Forja.gravar_relatorio(), "o relatório grava")
	if pasta == "":
		return
	var arquivos := DirAccess.get_files_at(pasta)
	var json := ""
	for f in arquivos:
		if f.begins_with("relatorio-") and f.ends_with(".json"):
			json = f
	_esperar(json != "", "relatorio-<sessão>.json existe")
	var tipos := {"txt": false, "log": false, "jsonl": false}
	for f in arquivos:
		for t in tipos:
			if f.ends_with("." + t):
				tipos[t] = true
	_esperar(tipos.txt and tipos.log and tipos.jsonl, "o texto, o registro e a linha do tempo existem")
	if json == "":
		return
	var dados = JSON.parse_string(FileAccess.get_file_as_string(pasta.path_join(json)))
	_esperar(dados is Dictionary, "o JSON se lê")
	# nenhum endereço de aparelho e nenhum caminho da máquina dentro dos arquivos
	var mac := RegEx.create_from_string("(?i)\\b([0-9a-f]{2}:){5}[0-9a-f]{2}\\b")
	for f in arquivos:
		var texto := FileAccess.get_file_as_string(pasta.path_join(f))
		_esperar(mac.search(texto) == null, "%s: nenhum endereço de aparelho" % f)
		_esperar(not texto.contains(pasta), "%s: nenhum caminho da máquina" % f)


func _prova_a_lista() -> void:
	var af := AltoFalanteDoControle.new()
	var achado := [""]
	af.alto_falante_achado.connect(func(n: String) -> void: achado[0] = n)
	var lista := (
		"alto-falante 0\talsa_output.usb-Sony_DualSense-00.HiFi__Speaker__sink\t"
		+ "DualSense wireless controller (PS5)\t4 canais\tacha sozinho\n"
		+ "alto-falante 1\tno_do_radio_000002\t"
		+ "Alto-falante do Controle 2 (DualSense Wireless Controller)\t2 canais\tpela lista\n"
		+ "# 5 saídas no servidor, 2 de DualSense\n"
	)
	var nome := af.ler_a_lista(lista)
	_esperar(nome == "alsa_output.usb-Sony_DualSense-00.HiFi__Speaker__sink", "alto-falante: o primeiro é o nó")
	_esperar(achado[0] == "DualSense wireless controller (PS5)", "alto-falante: o sinal leva o nome que o jogo mostra")
	_esperar(af.achados.size() == 2, "alto-falante: os dois")
	_esperar(af.achados[1]["canais"] == 2 and not af.achados[1]["sozinho"], "alto-falante: o do rádio, 2 canais, pela lista")
	var motivo := [""]
	af.sem_alto_falante.connect(func(m: String) -> void: motivo[0] = m)
	af.ler_a_lista("# 7 saídas no servidor, 0 de DualSense\n")
	_esperar(motivo[0] == "nenhum alto-falante de controle na lista (7 dispositivos)", "alto-falante: a recusa diz a conta")
	_esperar(not af.tomar_a_saida(), "alto-falante: sem nó, nada se toma")
	af.free()


func _prova_o_microfone() -> void:
	var silencio := PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
	_esperar(MicrofoneDoControle.nivel_de(silencio) == MicrofoneDoControle.SILENCIO_DB, "microfone: o mudo zera a barra")
	var meio := PackedVector2Array([Vector2(0.5, -0.25), Vector2(-0.1, 0.0)])
	_esperar(absf(MicrofoneDoControle.nivel_de(meio) - linear_to_db(0.5)) < 0.01, "microfone: o pico em dB")
	_esperar(ProjectSettings.get_setting("audio/driver/enable_input", false), "o jogo nasce com entrada de áudio")


## Com o pactl de mentira (tests/prova_do_jogo.sh), o forja-speak --list acha
## — ou não acha — o alto-falante pelo nome que o sistema publica.
func _prova_o_alto_falante_do_sistema() -> void:
	var esperado := OS.get_environment("ESPERADO")
	if esperado == "":
		return
	var af := AltoFalanteDoControle.new()
	af.procurar()
	var linha := af.linha_da_hud()
	print("alto-falante do sistema: ", linha)
	_esperar(linha.contains(esperado), "o alto-falante do sistema: «%s» (disse «%s»)" % [esperado, linha])
	af.free()
