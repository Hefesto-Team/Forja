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

	# As salas de entrada, jogadas pelo robô do começo ao fim: cada lugar sai
	# com PASSOU em cada feature da sala. Com um defeito de mentira ligado, a
	# feature que ele quebra tem de sair FALHOU (a prova da prova).
	await _joga_a_sala("centelha", ["botoes", "analogicos", "gatilhos_analogicos"])
	await _joga_a_sala("viga", ["giroscopio", "acelerometro"])
	await _joga_a_sala("molde", ["touchpad_dois_dedos", "touchpad_clique"])

	# A Galeria, às cegas: a arma do escuro chega ao R2 de cada um no modo dela
	# (e o L2 fica solto); o robô sente o gatilho, responde e conta as luzinhas
	var galeria = await _comeca_a_sala("galeria")
	if galeria:
		await _quadros(4)
		for l in 4:
			var arma: int = galeria.j[l].arma
			var esperado: int = [0x25, 0x26, 0x21, 0x05][arma]
			var pg := _perc(l)
			_esperar(int(pg.get("gatilho_dir", 0)) == esperado,
				"Galeria P%d: a arma do escuro (%s) chegou ao R2 como 0x%02x" % [l + 1, SalaGaleria.NOME_ARMA[arma], esperado])
			_esperar(int(pg.get("gatilho_esq", 0)) == 0x05, "Galeria P%d: o L2 solto (0x05)" % (l + 1))
		await _termina_a_sala(galeria, ["gatilho_resistencia", "gatilho_arma", "gatilho_vibracao", "leds_jogador"])

	# O Impacto, às cegas: o golpe treme só o motor do lado dele, e só no
	# controle do alvo; na pergunta da onda, a luz de cada um é a cor sorteada
	var impacto = await _comeca_a_sala("impacto")
	if impacto:
		var q := 0
		while impacto.estado != SalaImpacto.GOLPE and q < 900:
			await _quadros(1)
			q += 1
		await _quadros(2)
		var alvo: int = impacto.atual.x
		var lado: int = impacto.atual.y
		for l in 4:
			var pe := _perc(l)
			var forte := float(pe.get("forte", 0.0))
			var fraco := float(pe.get("fraco", 0.0))
			if l == alvo:
				var certo := (forte > 0.5 and fraco == 0.0) if lado == 0 else (fraco > 0.5 and forte == 0.0)
				_esperar(certo, "Impacto: o golpe da %s treme só o motor %s do P%d" % [
					"esquerda" if lado == 0 else "direita", "forte" if lado == 0 else "fraco", l + 1])
			else:
				_esperar(forte == 0.0 and fraco == 0.0, "Impacto: o golpe no P%d não treme o P%d" % [alvo + 1, l + 1])
		q = 0
		while impacto.estado != SalaImpacto.PERGUNTA and q < 3000:
			await _quadros(1)
			q += 1
		await _quadros(2)
		for l in 4:
			var pedida: int = impacto.j[l].cor_pedida
			if pedida < 0:
				continue
			var luz: Color = _perc(l).get("luz", Color.BLACK)
			var cor: Color = SalaImpacto.CORES[pedida].cor
			# a cor passa por 8 bits no caminho: um degrau de folga
			var perto := absf(luz.r - cor.r) < 0.01 and absf(luz.g - cor.g) < 0.01 and absf(luz.b - cor.b) < 0.01
			_esperar(perto, "Impacto P%d: a luz acendeu %s para a pergunta" % [l + 1, SalaImpacto.CORES[pedida].nome])
		await _termina_a_sala(impacto, ["vibracao_forte", "vibracao_fraca", "vibracao_isolamento", "lightbar"])

	# O Canto, às cegas: o canto de um controle toca só no alto-falante daquele
	# controle (a placa virtual, que o robô ouve); o canto da TV, em nenhum
	var canto = await _comeca_a_sala("canto")
	if canto:
		var viu_controle := false
		var viu_tv := false
		var q := 0
		while is_instance_valid(canto) and canto.fase == "jogo" and not (viu_controle and viu_tv) and q < 6000:
			await _quadros(1)
			q += 1
			if canto.estado != SalaCanto.CANTO or canto.notas_tocadas == 0 or canto.t_estado < 0.05:
				continue
			var fonte: int = canto.fonte
			if fonte == SalaCanto.TV and not viu_tv:
				viu_tv = true
				for l in 4:
					var nivel := float(Forja.som_virtual(l).get("falante", 1.0))
					_esperar(nivel < 0.05, "Canto: o canto da TV não sai no alto-falante do P%d (%.2f)" % [l + 1, nivel])
			elif fonte != SalaCanto.TV and not viu_controle:
				viu_controle = true
				for l in 4:
					var nivel := float(Forja.som_virtual(l).get("falante", 0.0))
					var certo := nivel > 0.1 if l == fonte else nivel < 0.05
					_esperar(certo, "Canto: o canto do P%d %s no alto-falante do P%d (%.2f)" % [
						fonte + 1, "sai" if l == fonte else "não sai", l + 1, nivel])
		_esperar(viu_controle and viu_tv, "Canto: cantou num controle e na TV")
		await _termina_a_sala(canto, ["alto_falante"])

	# Os Caminhos, às cegas: o tropeço treme só o atuador do lado da pedra, no
	# controle de quem tropeçou (o passo vai aos dois lados)
	var caminhos = await _comeca_a_sala("caminhos")
	if caminhos:
		var viu := false
		var q := 0
		while is_instance_valid(caminhos) and caminhos.fase == "jogo" and not viu and q < 9000:
			await _quadros(1)
			q += 1
			for l in 4:
				var e: Dictionary = caminhos.j[l]
				if not e.trop_aberto or float(e.trop_t) < 0.03 or float(e.trop_t) > 0.12:
					continue
				var v := Forja.som_virtual(l)
				var lado: int = e.trop_agora
				var dele := float(v.get("esq" if lado == 0 else "dir", 0.0))
				var outro := float(v.get("dir" if lado == 0 else "esq", 1.0))
				_esperar(dele > 0.05 and outro < 0.02, "Caminhos P%d: o tropeço da %s treme só aquele atuador (%.2f × %.2f)" % [
					l + 1, "esquerda" if lado == 0 else "direita", dele, outro])
				viu = true
				break
		_esperar(viu, "Caminhos: alguém tropeçou")
		await _termina_a_sala(caminhos, ["haptica_audio"])

	# A Voz: o robô chama o guardião no microfone do controle dele, fica mudo
	# e olha a luz; o mudo acende o LED de quem apertou, e só o dele
	var voz = await _comeca_a_sala("voz")
	if voz:
		var viu := false
		var q := 0
		while is_instance_valid(voz) and voz.fase == "jogo" and not viu and q < 6000:
			await _quadros(1)
			q += 1
			if voz.estado != SalaVoz.MUDO:
				continue
			var mudos := 0
			for l in 4:
				if voz.j[l].apertou_mudo:
					mudos += 1
			if mudos == 0 or mudos == 4:
				continue
			await _quadros(2)
			viu = true
			for l in 4:
				var aceso := int(_perc(l).get("led_mic", 0)) != 0
				var deve: bool = voz.j[l].apertou_mudo
				_esperar(aceso == deve, "Voz: o LED do mudo do P%d %s" % [l + 1, "aceso" if deve else "apagado"])
		_esperar(viu, "Voz: o mudo chegou de uns antes dos outros")
		await _termina_a_sala(voz, ["microfone", "microfone_mudo", "led_microfone"])

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


## Entra na sala, espera o aviso (o robô fica pronto sozinho), o jogo e o
## veredito; confere o veredito de cada lugar e espera a volta ao salão.
func _joga_a_sala(id: String, features: Array) -> void:
	var sala = await _comeca_a_sala(id)
	if sala:
		await _termina_a_sala(sala, features)


## Entra na sala e espera o jogo começar (o robô fica pronto no aviso).
## Devolve a sala, ou null se ela não abriu.
func _comeca_a_sala(id: String):
	jogo._entrar_na_sala(id, false)
	await _quadros(2)
	var sala = jogo.sala
	_esperar(sala is SalaJogo and sala.id == id, "%s: a sala abriu" % id)
	if not sala is SalaJogo:
		return null
	var q := 0
	while is_instance_valid(sala) and sala.fase == "aviso" and q < 600:
		await _quadros(1)
		q += 1
	_esperar(is_instance_valid(sala) and sala.fase == "jogo", "%s: o aviso passou com os quatro prontos" % id)
	return sala if is_instance_valid(sala) else null


## Espera o veredito, confere cada lugar em cada feature (e o que foi para o
## relatório) e espera a volta ao salão, com os controles no repouso.
func _termina_a_sala(sala, features: Array) -> void:
	var id: String = sala.id
	var q := 0
	while is_instance_valid(sala) and sala.fase != "fim" and q < 12000:
		await _quadros(10)
		q += 10
	_esperar(is_instance_valid(sala) and sala.fase == "fim", "%s: o robô jogou até o fim (%d quadros)" % [id, q])
	if not is_instance_valid(sala):
		return
	for l in 4:
		var lista: Array = sala.vereditos.get(l, [])
		for f in features:
			var v := {}
			for item in lista:
				if item.get("feature", "") == f:
					v = item
			var ok := int(v.get("resultado", -1)) == Forja.PASSOU
			var porque := str(v.get("obs", "")) if str(v.get("obs", "")) != "" else str(v.get("medido", "sem veredito"))
			_esperar(ok, "%s P%d: %s → %s (%s)" % [id, l + 1, f, str(v.get("rotulo", "sem veredito")), porque])
			var gravado := Forja.ultimo_veredito(l, f)
			_esperar(int(gravado.get("resultado", -1)) == int(v.get("resultado", -2)), "%s P%d: %s gravado no relatório" % [id, l + 1, f])
	# o robô aperta ✕ no veredito; a cortina leva de volta ao salão
	q = 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 600:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "%s: de volta ao salão pelo veredito" % id)
	for l in 4:
		var p := _perc(l)
		_esperar(int(p.get("gatilho_dir", 0)) == 0x05 and float(p.get("forte", 1.0)) == 0.0,
			"%s: o P%d voltou ao repouso" % [id, l + 1])


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
