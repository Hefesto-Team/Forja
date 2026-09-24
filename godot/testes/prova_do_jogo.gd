extends SceneTree
## A prova do som e do movimento DENTRO do jogo, sem janela e sem aparelho.
##
##   godot --headless --path godot --script res://testes/prova_do_jogo.gd
##
## Roda com o pactl de mentira na frente do PATH (o PACTL_DE_MENTIRA_DIR diz o
## que ele responde) — nunca com o servidor de som de alguém. A segunda metade
## abre a cena inteira e lê a HUD: é o G5 do roteiro («a HUD diz o nome do
## alto-falante achado») medido sem mão nenhuma.
##
## ESPERADO=<texto> é o que a linha do som tem de conter.

var falhas := 0
var _quadros := 0
var _principal: Node


func _esperar(cond: bool, msg: String) -> void:
	if not cond:
		printerr("FAIL ", msg)
		falhas += 1


func _initialize() -> void:
	_prova_a_lista()
	_prova_o_microfone()
	_prova_o_movimento()
	_esperar(DualSensePad.bin_irmao("forja-speak") != "", "o forja-speak irmão está no bin/")
	_principal = load("res://scenes/main.tscn").instantiate()
	root.add_child(_principal)


func _process(_delta: float) -> bool:
	_quadros += 1
	match _quadros:
		45:
			## G5: a HUD diz o nome do alto-falante achado.
			var hud: String = _principal.som_hud.text
			var esperado := OS.get_environment("ESPERADO")
			print("HUD do som: ", hud)
			if esperado != "":
				_esperar(hud.contains(esperado), "a HUD do som diz «%s» (disse «%s»)" % [esperado, hud])
			_principal.start_mode("galeria")
		50:
			## o tiro do P1 na Galeria pede o SFX ao forja-speak — sem mesa, ele
			## recusa com rc próprio, e o jogo segue.
			_principal._fire(0)
			_principal.start_mode("giro")
		80:
			## G9/G10 sem controle: a Viga diz «stick», não finge IMU.
			var pads: String = _principal.pad_hud.text
			_esperar(pads.contains("stick"), "a Viga sem IMU diz stick (disse «%s»)" % pads)
			_principal.start_mode("voz")
		110:
			## G7: o modo Voz liga o microfone padrão e mostra a barra.
			_esperar(_principal.microfone.ligado, "o modo Voz liga o microfone")
			_esperar(str(_principal.thesis).begins_with("microfone "), "a Voz mostra a barra")
			_principal.reset_hub()
		115:
			## E desliga ao sair: microfone aberto fora da Voz é luz acesa sem motivo.
			_esperar(not _principal.microfone.ligado, "o hub desliga o microfone")
			for m in _principal.movimentos:
				_esperar(not m.tem_imu and m._pid == -1, "o hub desliga o forja-read")
			if falhas > 0:
				printerr("%d falha(s)" % falhas)
				quit(1)
			else:
				print("prova do jogo ok — a lista, o microfone, o movimento e a HUD")
				quit(0)
			return true
	return false


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
	_esperar(nome == "alsa_output.usb-Sony_DualSense-00.HiFi__Speaker__sink", "o primeiro é o nó")
	_esperar(achado[0] == "DualSense wireless controller (PS5)", "o sinal leva o nome que o jogo mostra")
	_esperar(af.achados.size() == 2, "os dois alto-falantes")
	_esperar(af.achados[1]["canais"] == 2 and not af.achados[1]["sozinho"], "o do rádio: 2 canais, pela lista")
	_esperar(af.linha_da_hud() == "alto-falante: DualSense wireless controller (PS5) (+1)", "a linha da HUD")

	var motivo := [""]
	af.sem_alto_falante.connect(func(m: String) -> void: motivo[0] = m)
	af.ler_a_lista("# 7 saídas no servidor, 0 de DualSense\n")
	_esperar(motivo[0] == "nenhum alto-falante de controle na lista (7 dispositivos)", "a recusa diz a conta")
	_esperar(af.linha_da_hud() == motivo[0], "e a HUD diz a recusa")
	af.ler_a_lista("# forja-speak ausente — rode make")
	_esperar(motivo[0] == "forja-speak ausente — rode make", "sem o binário, a HUD diz o que fazer")
	## sem alto-falante, tomar a saída é recusado — e headless, sem servidor, o
	## motor recusa qualquer nome: a pós-condição relida diz a verdade.
	_esperar(not af.tomar_a_saida(), "sem nó, nada se toma")
	af.ler_a_lista(lista)
	_esperar(not af.tomar_a_saida(), "o motor que não lista o nó não o toma")
	_esperar(AudioServer.output_device == "Default", "e a saída continua a de antes")
	af.free()


func _prova_o_microfone() -> void:
	var silencio := PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
	_esperar(MicrofoneDoControle.nivel_de(silencio) == MicrofoneDoControle.SILENCIO_DB, "o mudo zera a barra")
	var meio := PackedVector2Array([Vector2(0.5, -0.25), Vector2(-0.1, 0.0)])
	_esperar(absf(MicrofoneDoControle.nivel_de(meio) - linear_to_db(0.5)) < 0.01, "o pico em dB")
	_esperar(MicrofoneDoControle.barra(-80.0) == "▯".repeat(20), "barra vazia no silêncio")
	_esperar(MicrofoneDoControle.barra(0.0) == "▮".repeat(20), "barra cheia no teto")
	_esperar(ProjectSettings.get_setting("audio/driver/enable_input", false), "o jogo nasce com entrada de áudio")


func _prova_o_movimento() -> void:
	var l := MovimentoDoControle.ler_linha("giro 0.1 -30.0 0.0 graus/s | acel 0.012 -0.998 0.031 g")
	_esperar(not l.is_empty(), "a linha do forja-read se lê")
	if not l.is_empty():
		_esperar(is_equal_approx(l["giro"].y, -30.0), "o yaw é o segundo número")
		_esperar(is_equal_approx(l["acel"].y, -0.998), "o acelerômetro")
	_esperar(MovimentoDoControle.ler_linha("recusa: outro relatório").is_empty(), "lixo não vira IMU")
	var m := MovimentoDoControle.new()
	_esperar(m.linha_da_hud() == "stick", "sem IMU a HUD diz stick, não finge")
	m.free()
