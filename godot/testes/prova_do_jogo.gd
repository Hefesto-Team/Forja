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

## As features que só a pergunta às cegas mede: fora do Modo bancada, «não medido».
const SO_COM_PERGUNTA := {
	"galeria": ["gatilho_resistencia", "gatilho_arma", "gatilho_vibracao", "leds_jogador"],
	"impacto": ["lightbar"],
	"canto": ["alto_falante"],
	"voz": ["led_microfone"],
	"prova": ["tudo_junto"],
}


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
	await _prova_do_relogio()
	_prova_das_janelas()
	_prova_dos_jingles()
	await _prova_da_musica_que_reage()
	_prova_das_faixas()
	_prova_da_paridade()
	_prova_das_contas_da_camera()
	Desenho._coletar = "memoria"  # colhe cada frase desenhada (F02, F07)
	jogo = load("res://scenes/main.tscn").instantiate()
	add_child(jogo)
	_prova_do_catalogo()
	await _prova_do_percurso()
	_prova_das_falas()
	await _prova_do_motor_que_vence()
	await _prova_do_aviso_sozinho()
	await _prova_do_relatorio()
	await _prova_de_fogo()
	await _prova_da_camera_na_prova()
	_prova_das_contas_da_partida()
	_prova_das_contas_da_colecao()
	_prova_do_kit_da_kenney()
	_prova_das_contas_dos_itens()
	_prova_do_teclado()
	await _prova_da_partida()
	await _prova_da_virada()
	_prova_do_modo()
	_prova_das_frases()
	_prova_das_maiusculas()
	_prova_da_identidade()
	_prova_das_sensacoes()
	_prova_do_nome_na_linha_do_tempo()
	_prova_do_registro_v2()
	_prova_dos_sons_em_pcm()
	await _prova_da_cor_e_da_letra()
	_prova_da_letra_e_da_margem()
	await _prova_da_luz()
	_prova_do_conforto()
	_prova_do_virar_pura()
	await _prova_da_noite_da_fita()
	_prova_das_cores_da_pergunta()
	if falhas > 0:
		printerr("%d falha(s)" % falhas)
		get_tree().quit(1)
	else:
		print("prova do jogo ok — lobby, player index, salas, diagnóstico e relatório")
		get_tree().quit(0)


## O pad (o índice do módulo) do controle simulado `s` (0..3).
func _pad_do_sim(s: int) -> int:
	for p in Forja.pads():
		if str(p.nome) == "DualSense simulado %d" % (s + 1):
			return int(p.pad)
	return -1


func _perc_do_sim(s: int) -> Dictionary:
	return Forja.ctl.percepcao(_pad_do_sim(s))


## Os simulados `sims`, tirados e postos de volta nessa ordem.
func _religar(sims: Array) -> void:
	for s in sims:
		Forja.ctl.simulador_cabo(s, false)
	await _quadros(4)
	for s in sims:
		Forja.ctl.simulador_cabo(s, true)
		await _quadros(4)


## A mesma cor, com outro brilho (a barra de luz escurece com a vida, mas não muda de cor).
func _mesmo_tom(a: Color, b: Color) -> bool:
	var ma := maxf(a.r, maxf(a.g, a.b))
	var mb := maxf(b.r, maxf(b.g, b.b))
	if ma < 0.01 or mb < 0.01:
		return false
	return absf(a.r / ma - b.r / mb) < 0.08 and absf(a.g / ma - b.g / mb) < 0.08 and absf(a.b / ma - b.b / mb) < 0.08


func _perc(lugar: int) -> Dictionary:
	return Forja.ctl.percepcao(Forja.pad_do_lugar(lugar))


func _prova_do_percurso() -> void:
	await _quadros(10)
	_esperar(Forja.modulo, "o módulo nativo carregou")
	_esperar(Forja.conectados() == 4, "quatro DualSense simulados (%d)" % Forja.conectados())
	_esperar(Forja.jogadores() == 0, "ninguém no lugar antes do lobby")
	_esperar(jogo.estado == "titulo", "o jogo abre no título")
	Forja.robo_confirma = false  # o robô do fluxo espera: as checagens de conexão não têm botão nenhum
	for s in 4:
		var p := _perc_do_sim(s)
		_esperar(int(p.get("player_index", -9)) == s and int(p.get("leds_jogador", 0)) == Forja.LEDS_DO_LUGAR[s]
			and (p.get("luz", Color.BLACK) as Color).is_equal_approx(Forja.cor_do_lugar(s)),
			"conexão: o simulado %d já é P%d, com as luzinhas e a cor, antes de qualquer botão" % [s + 1, s + 1])
	# conectar na ordem 3, 2, 1 (os simulados de índice 2, 1 e 0): P1, P2 e P3
	await _religar([2, 1, 0])
	for par in [[2, 0], [1, 1], [0, 2]]:
		var s: int = par[0]
		var l: int = par[1]
		_esperar(int(Forja.pad(_pad_do_sim(s)).get("reserva", -9)) == l and int(_perc_do_sim(s).get("player_index", -9)) == l
			and int(_perc_do_sim(s).get("leds_jogador", 0)) == Forja.LEDS_DO_LUGAR[l],
			"ordem trocada: o simulado %d, o %dº a chegar, é P%d" % [s + 1, l + 1, l + 1])
	await _religar([0, 1, 2])  # de volta: o simulado N é o PN

	# o título: quem aperta ✕ é o robô do fluxo (main.gd _robo), no controle do P1
	Forja.robo_confirma = true
	var pio := [0.0, 0.0]
	var fita := 0.0
	var nq := 0
	var nq_play := -1
	# a batida do título segue a placa de som, que anda em tempo de parede; o
	# jogo, sem janela, anda muito mais depressa: o laço espera pelo relógio de parede
	var t_parede := Time.get_ticks_msec()
	while jogo.estado == "titulo" and Time.get_ticks_msec() - t_parede < 20000:
		await _quadros(1)
		nq += 1
		for l in 2:
			pio[l] = maxf(pio[l], float(Forja.som_virtual(l).get("falante", 0.0)))
		if jogo.play_ms >= 0:
			if nq_play < 0:
				nq_play = nq
			# depois dos 60 ms do toque do pio, só o motor da fita (400 ms) segue na mão
			if nq - nq_play >= 8:
				fita = maxf(fita, float(_perc(0).get("fraco", 0.0)))
	_esperar(jogo.play_ms >= 0, "o ✕ no título deu o PLAY")
	_esperar(fita > 0.0, "o PLAY vibrou no controle do P1 (%.2f)" % fita)
	_esperar(pio[0] > 0.05, "o pio do P1 saiu no alto-falante do P1 (%.2f)" % pio[0])
	_esperar(pio[1] < 0.02, "e não no do P2 (%.2f)" % pio[1])
	_esperar(jogo.estado == "intro", "o PLAY leva à introdução")
	_esperar(int(round(jogo._batidas_do_titulo())) % 4 <= 1, "o corte caiu no tempo 1")
	var armaduras := 0
	var martelou := [false, false, false, false]
	var grafite := [true, true, true, true]
	var da_cor := [true, true, true, true]
	var viu_antes := [false, false, false, false]
	var viu_depois := [false, false, false, false]
	var vazia := [false, false, false, false]
	var tremeu_sem_lugar := [false, false, false, false]
	var texto_no_mundo := 0
	nq = 0
	while jogo.estado == "intro" and nq < 1800:
		await _quadros(1)
		nq += 1
		for l in 4:
			martelou[l] = martelou[l] or float(_perc(l).get("forte", 0.0)) > 0.0
		if jogo.intro.t > 18.0:
			var n := 0
			for p in jogo.jogadores:
				if p.visible:
					n += 1
			armaduras = maxi(armaduras, n)
		# a cor da armadura: grafite antes da primeira acender, a do dono depois da última
		for l in 4:
			var r: Array = jogo.jogadores[l]._mats_corpo
			if r.is_empty():
				vazia[l] = true
				continue
			var acesa := float(r[0].get_shader_parameter("acesa"))
			if jogo.intro.t < 12.0:
				grafite[l] = grafite[l] and is_zero_approx(acesa)
				viu_antes[l] = true
			elif jogo.intro.t > 18.0:
				da_cor[l] = da_cor[l] and is_equal_approx(acesa, 1.0)
				viu_depois[l] = true
		for s in 4:
			if not Forja.ocupado(s):
				tremeu_sem_lugar[s] = tremeu_sem_lugar[s] or float(_perc_do_sim(s).get("forte", 0.0)) > 0.0
		# nenhuma palavra na introdução: nem as placas das salas, nem o «P1» em cima dos bonecos
		if jogo.estado == "intro":
			for id in jogo.salao.portoes:
				if (jogo.salao.portoes[id].placa as Node3D).is_visible_in_tree():
					texto_no_mundo += 1
			for p in jogo.jogadores:
				if p.etiqueta.is_visible_in_tree():
					texto_no_mundo += 1
	_esperar(armaduras == 4, "a introdução acende as quatro armaduras (%d)" % armaduras)
	for l in 4:
		_esperar(not vazia[l] and viu_antes[l] and grafite[l], "introdução: a armadura do P%d é grafite antes de acender" % (l + 1))
		_esperar(not vazia[l] and viu_depois[l] and da_cor[l], "introdução: a armadura do P%d acende na cor dela" % (l + 1))
		if not Forja.ocupado(l):
			_esperar(not tremeu_sem_lugar[l], "introdução: o controle do P%d, sem lugar, não recebe martelada" % (l + 1))
	for l in 4:
		if Forja.ocupado(l):
			_esperar(martelou[l], "a martelada do P%d chegou à mão dele" % (l + 1))
	_esperar(nq >= 60 * 20, "a introdução dura mais de 20 s sem ninguém apertar (%d quadros)" % nq)
	_esperar(jogo.estado == "lobby", "a introdução acaba sozinha e leva à construção")
	_esperar(texto_no_mundo == 0, "a introdução não mostra placa nem «P1» no mundo (%d)" % texto_no_mundo)
	var placas_de_volta := true
	for id in jogo.salao.portoes:
		placas_de_volta = placas_de_volta and (jogo.salao.portoes[id].placa as Node3D).visible
	for p in jogo.jogadores:
		placas_de_volta = placas_de_volta and p.etiqueta.visible
	_esperar(placas_de_volta, "depois da introdução as placas e o «P1»…«P4» voltam")
	Forja.robo_confirma = false  # o robô do fluxo espera: as checagens do lobby apertam à mão
	# ◻ segurado um segundo, antes de confirmar: a reserva passa ao próximo lugar livre
	Forja.ctl.simulador_cabo(1, false)  # o P2 vaga
	await _quadros(4)
	Forja.ctl.simulador_botao(3, Forja.QUADRADO, true)
	await _quadros(70)
	Forja.ctl.simulador_botao(3, Forja.QUADRADO, false)
	await _quadros(2)
	_esperar(int(Forja.pad(_pad_do_sim(3)).get("reserva", -9)) == 1 and int(_perc_do_sim(3).get("player_index", -9)) == 1,
		"◻ por um segundo: o simulado 4 passa de P4 para P2, o próximo livre")
	Forja.ctl.simulador_cabo(3, false)
	await _quadros(4)
	await _religar([1, 3])  # o simulado 2 volta a P2 e o 4 a P4
	# o ✕ só confirma: em ordem inversa, cada um fica com o lugar que a conexão deu
	for s in [3, 2, 1, 0]:
		if int(Forja.pad(_pad_do_sim(s)).get("lugar", -1)) < 0:  # o P1 já se sentou no título
			await _aperta(s, Forja.CRUZ)
			# o pio do cavaleiro sai no controle de quem entrou, e só nele (H07)
			var nivel := float(Forja.som_virtual(s).get("falante", 0.0))
			var outros := 0.0
			for o in 4:
				if o != s:
					outros = maxf(outros, float(Forja.som_virtual(o).get("falante", 0.0)))
			_esperar(nivel > 0.1 and outros < 0.05, "P%d entrou: o pio no controle dele (%.2f; os outros %.2f)" % [s + 1, nivel, outros])
			await _quadros(20)
	await _quadros(4)
	for s in 4:
		_esperar(Forja.pad_do_lugar(s) == _pad_do_sim(s), "o ✕ confirma: o simulado %d é P%d, mesmo apertando por último" % [s + 1, s + 1])
	_esperar(Forja.jogadores() == 4, "os quatro entraram")
	_esperar(Forja.som_pronto(), "a placa de áudio dos quatro abriu na entrada")
	# um som por vez no alto-falante (H07): o sino longo soa; o clique chega,
	# o sino sai pela rampa, e quando o clique (20 ms) acaba não sobra nada
	Forja.som_falante(0, "sino", 0.9)
	await _quadros(5)
	var com_sino := float(Forja.som_virtual(0).get("falante", 0.0))
	Forja.som_falante(0, "clique", 0.5)
	await _quadros(4)
	var depois := float(Forja.som_virtual(0).get("falante", 0.0))
	_esperar(com_sino > 0.1 and depois < 0.05, "o alto-falante toca um som por vez: o clique tira o sino (%.2f, depois %.2f)" % [com_sino, depois])
	_prova_da_calibracao()
	await _prova_do_tempo_nas_opcoes()
	for l in 4:
		var e: Dictionary = Forja.estado_saida(l)
		var p := _perc(l)
		_esperar(p.get("player_index", -9) == l, "P%d: o SDL deu o player index %d ao controle" % [l + 1, l])
		_esperar(int(p.get("leds_jogador", 0)) == Forja.LEDS_DO_LUGAR[l], "P%d: as lâmpadas do lugar chegaram" % (l + 1))
		var luz: Color = p.get("luz", Color.BLACK)
		_esperar(luz.is_equal_approx(Forja.cor_do_lugar(l)), "P%d: a barra de luz na cor do lugar" % (l + 1))
		_esperar(int(e.get("leds_jogador", 0)) == Forja.LEDS_DO_LUGAR[l], "P%d: o estado das lâmpadas" % (l + 1))
		_esperar(not jogo.lobby.prontos[l], "P%d: entrar não é ficar pronto" % (l + 1))
	_prova_da_peca()
	# a construção: ◀▶ e ▼ mexem só no próprio lugar; o robô forja os quatro na batida
	var visuais := {}
	var nomes0 := {}
	var arqs0 := {}
	for l in 4:
		visuais[str(jogo.jogadores[l].pecas[0]) if jogo.jogadores[l].pecas.size() == 3 else ""] = true
		arqs0[str(jogo.lobby.corpo[l].get("arquetipo", {}).get("id", ""))] = true
		nomes0[jogo.jogadores[l].nome] = true
	_esperar(visuais.size() == 4 and not visuais.has(""), "os quatro nascem com cabeças diferentes (%s)" % [visuais.keys()])
	_esperar(arqs0.size() == 4 and not arqs0.has(""), "e com arquétipos diferentes (%s)" % [arqs0.keys()])
	_esperar(nomes0.size() == 4 and not nomes0.has(""), "os quatro nascem com nomes diferentes (%s)" % [nomes0.keys()])
	_esperar(Ritmo.slot == "MUS_TELA_CONSTRUCAO" and absf(Ritmo.bpm - 120.0) < 0.001, "a construção roda na faixa dela, a 120 BPM (%s, %.1f)" % [Ritmo.slot, Ritmo.bpm])
	await _prova_do_encaixe()
	await _aperta(2, Forja.BAIXO)
	await _aperta(2, Forja.BAIXO)
	await _aperta(2, Forja.BAIXO)
	_esperar(jogo.lobby.linha[2] == TelaLobby.ITEM and jogo.lobby.linha[0] == TelaLobby.CABECA, "▼▼▼ leva o P3 à linha do item, e só o P3")
	var i3: int = jogo.jogadores[2].item_i
	var alcanca3: Array = Cavaleiro.alcancaveis(jogo.lobby.corpo[2].stats)
	await _aperta(2, Forja.DIREITA)
	await _espera_o_encaixe(2)
	_esperar((jogo.jogadores[2].item_i != i3 or alcanca3.size() == 1) and jogo.jogadores[2].item_i >= 1,
		"◀▶ troca o item do P3, entre os que o corpo alcança (%s)" % [alcanca3])
	for vez in 7:
		await _aperta(2, Forja.DIREITA)
		await _espera_o_encaixe(2)
		var id3 := str(ForjaPlayer.ITENS[jogo.jogadores[2].item_i].id)
		_esperar(jogo.jogadores[2].item_i >= 1 and id3 in alcanca3, "◀▶ nunca chega às mãos livres nem a um item fora do alcance (%s)" % id3)
	var n1: String = jogo.jogadores[0].nome
	for vez in 5:
		await _aperta(0, Forja.BAIXO)
	_esperar(jogo.lobby.linha[0] == TelaLobby.NOME, "▼ para na última linha (Nome)")
	await _aperta(0, Forja.DIREITA)
	var n1b: String = jogo.jogadores[0].nome
	var outros := [jogo.jogadores[1].nome, jogo.jogadores[2].nome, jogo.jogadores[3].nome]
	_esperar(n1b != n1 and n1b in TelaLobby.NOMES and not (n1b in outros), "◀▶ no Nome troca para um que nenhum outro usa (%s → %s)" % [n1, n1b])
	await _aperta(3, Forja.TRIANGULO)
	var item4: int = jogo.jogadores[3].item_i
	var nomes4 := [jogo.jogadores[0].nome, jogo.jogadores[1].nome, jogo.jogadores[2].nome]
	_esperar(item4 >= 1 and not (jogo.jogadores[3].nome in nomes4) and jogo.jogadores[3].nome in TelaLobby.NOMES,
		"△ sorteia boneco, item e um nome livre (%s)" % jogo.jogadores[3].nome)
	var c4: Dictionary = Cavaleiro.corpo(jogo.jogadores[3].pecas)
	_esperar(c4.valido and Cavaleiro.no_corpo(str(ForjaPlayer.ITENS[item4].id), c4.stats) != "fora",
		"△ sorteia um corpo válido e um item que ele alcança (%s)" % [jogo.jogadores[3].pecas])
	await _aperta(0, Forja.CIRCULO)
	_esperar(jogo.lobby.linha[0] == TelaLobby.CABECA and Forja.ocupado(0), "○ numa linha de baixo volta à primeira, sem sair do lugar")
	await _prova_do_teclado_na_mesa()
	# o cavaleiro guarda-se como dado: ida e volta pelo arquivo, e o acabamento só muda a luz
	_prova_do_cavaleiro_guardado()
	_prova_do_cavaleiro()
	# o robô forja os quatro, só apertando botões: ✕ para forjar e as oito marteladas na batida
	Forja.robo_confirma = true
	var perfeito := [false, false, false, false]
	var pio_f := [false, false, false, false]
	var cruzes := 0
	var nq_f := 0
	var t_forja := Time.get_ticks_msec()
	while (jogo.estado != "salao" or jogo._trocando) and Time.get_ticks_msec() - t_forja < 60000:
		await _quadros(1)
		nq_f += 1
		if jogo.estado != "lobby":
			continue
		for l in 4:
			if float(Forja.percepcao(l).get("fraco", 0.0)) >= 0.79:
				perfeito[l] = true
			if jogo.lobby.etapa[l] == TelaLobby.FORJADO and float(Forja.som_virtual(l).get("falante", 0.0)) > 0.05:
				pio_f[l] = true
	_esperar(jogo.estado == "salao", "com os quatro forjados, o salão (%d quadros, %d ms)" % [nq_f, Time.get_ticks_msec() - t_forja])
	await _quadros(2)
	_confere_o_hud("no salão")
	_esperar(nq_f / 60.0 <= 90.0, "a montagem do robô, com o nome, fecha em 90 s de jogo ou menos (%.1f s)" % (nq_f / 60.0))
	_esperar(jogo.jogadores[0].nome == "Dona Brasa", "o robô escreveu «Dona Brasa» no lugar 1, letra a letra (%s)" % jogo.jogadores[0].nome)
	# o robô do P1 fez a troca do pré-montado (G13): o item entra em liga, e a forja guarda os stats
	var troca0: Dictionary = jogo.lobby._troca_do_pre[0]
	_esperar(troca0.is_empty() or (str(jogo.jogadores[0].pecas[int(troca0.parte)]) == str(troca0.personagem) and Itens.em_liga[0]),
		"o robô do P1 fez a troca do pré-montado e o item ficou em liga (%s, %s)" % [troca0, jogo.jogadores[0].pecas])
	_esperar(troca0.is_empty() or int(jogo.lobby.ligou[0]) > 0, "a troca do P1 bateu o «LIGA!» pelo visor (%d)" % int(jogo.lobby.ligou[0]))
	_esperar(jogo.lobby.visor == jogo.visor, "o lobby carimba pelo visor do jogo")
	for l in 4:
		_esperar(Cavaleiro.stats[l] == Cavaleiro.corpo(jogo.jogadores[l].pecas).stats, "P%d: a forja guardou os stats do corpo (%s)" % [l + 1, Cavaleiro.stats[l]])
	for l in range(1, 4):
		_esperar(jogo.jogadores[l].nome in TelaLobby.NOMES and jogo.lobby.nome_escrito[l] == false,
			"P%d: △ e ✕ deram um nome sorteado (%s)" % [l + 1, jogo.jogadores[l].nome])
	for l in 4:
		var pi: ForjaPlayer = jogo.jogadores[l]
		_esperar(Itens.escolhido[l] == pi.item_i and Itens.escolhido[l] >= 1,
			"P%d: a mecânica leva o item escolhido (%d)" % [l + 1, Itens.escolhido[l]])
		var esqueleto: Skeleton3D = pi.modelo.find_child("Skeleton3D", true, false)
		var presa: BoneAttachment3D = esqueleto.find_child("Item", false, false)
		_esperar(presa != null, "P%d: o item no corpo" % (l + 1))
		if presa == null:
			continue
		var osso: String = {Itens.MARTELO: "arm-right", Itens.ANCORA: "arm-right", Itens.ESCUDO: "arm-left"}.get(pi.item_i, "torso")
		_esperar(presa.bone_name == osso, "P%d: o item no osso %s" % [l + 1, osso])
		# o tamanho do item é o do maior lado dele no espaço dele (a pose do braço não entra),
		# contra o boneco inteiro (0,755 × a escala do kit)
		var uniao := AABB()
		var primeiro := true
		for mi in presa.find_children("*", "MeshInstance3D", true, false):
			var a: AABB = presa.global_transform.affine_inverse() * mi.global_transform * mi.get_aabb()
			uniao = a if primeiro else uniao.merge(a)
			primeiro = false
		var alto := uniao.get_longest_axis_size() * presa.global_transform.basis.get_scale().y
		var corpo := 0.755 * ForjaPlayer.ESCALA
		var faixa := Vector2(0.06, 0.14) if osso == "torso" else Vector2(0.12, 0.60)
		_esperar(alto >= faixa.x * corpo and alto <= faixa.y * corpo,
			"P%d: o item no tamanho (%.2f do corpo)" % [l + 1, alto / corpo])
		_esperar(pi._mats_runa.size() >= 1, "P%d: o item tem a runa" % (l + 1))
		if ForjaPlayer.MALHA_DO_ITEM.has(ForjaPlayer.ITENS[pi.item_i].id):
			# a malha do Kenney leva o colormap na faixa dos objetos (G08), o do item, não o cru
			var faixa_do_objeto := Pintura.textura(String(ForjaPlayer.MALHA_DO_ITEM[ForjaPlayer.ITENS[pi.item_i].id]).get_base_dir() + "/Textures/colormap.png", "objeto")
			var cheio := true
			var visto := 0
			for mi in presa.find_children("*", "MeshInstance3D", true, false):
				for k in (mi as MeshInstance3D).mesh.get_surface_count():
					var mat := (mi as MeshInstance3D).get_surface_override_material(k)
					if mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture != null:
						visto += 1
						cheio = cheio and (mat as StandardMaterial3D).albedo_texture == faixa_do_objeto
			_esperar(visto >= 1 and cheio, "P%d: o item de malha na faixa dos objetos (%d superfícies)" % [l + 1, visto])
		_esperar(pi._area_runa <= 0.12 * pi._area_item, "P%d: a runa em até 12 %% do item (%.3f)" % [l + 1, pi._area_runa / maxf(pi._area_item, 0.0001)])
	_confere_a_arte(jogo.salao, "o salão")
	for l in 4:
		var cont: ShaderMaterial = jogo.jogadores[l]._mats_corpo[0].next_pass
		_esperar(is_equal_approx(float(cont.get_shader_parameter("energia")), 2.4), "P%d: o contorno a 2,4 fora da montagem" % (l + 1))
	var nomes_f := {}
	for l in 4:
		_esperar(perfeito[l], "P%d: a oitava vibrou o perfeito no controle" % (l + 1))
		_esperar(pio_f[l], "P%d: o pio saiu no alto-falante do dono" % (l + 1))
		_esperar(jogo.lobby.golpes[l].size() == TelaLobby.MARTELADAS, "P%d: as oito marteladas" % (l + 1))
		_esperar(Opcoes.tempo_ms[l] == clampi(roundi(jogo.lobby.desvio[l] * 1000.0), Opcoes.TEMPO_MIN, Opcoes.TEMPO_MAX),
			"P%d: o desvio foi para as opções (%d ms)" % [l + 1, Opcoes.tempo_ms[l]])
		_esperar(not Opcoes.cavaleiro[l].is_empty() and Opcoes.cavaleiro[l] == jogo.jogadores[l].cavaleiro(),
			"P%d: o cavaleiro ficou guardado" % (l + 1))
		nomes_f[jogo.jogadores[l].nome] = true
	_esperar(Opcoes.guardadas >= 4 and Opcoes.noite_dos_cavaleiros == Opcoes.noite(), "o cavaleiro mandou guardar nas opções (%d)" % Opcoes.guardadas)
	_esperar(nomes_f.size() == 4 and not nomes_f.has(""), "quatro nomes diferentes (%s)" % [nomes_f.keys()])
	var d0: float = jogo.lobby.desvio[0]
	var dif: float = jogo.lobby.desvio[3] - d0
	# o robô aperta no primeiro quadro depois da hora: com a máquina carregada um quadro leva dezenas de ms, então a banda é larga
	_esperar(d0 >= -0.01 and d0 <= 0.15, "P1 martelou no tempo: desvio %d ms" % int(d0 * 1000.0))
	_esperar(dif >= 0.07 and dif <= 0.25, "P4 martelou uns 100 ms depois do P1: %d ms" % int(dif * 1000.0))
	_esperar(absf(TelaLobby.mediana([0.3, -0.1, 0.0, 0.5, 0.1]) - 0.1) < 0.0001
		and absf(TelaLobby.mediana([0.0, 0.2, 0.4, 1.0]) - 0.3) < 0.0001
		and TelaLobby.mediana([]) == 0.0, "a mediana: ímpar, par e vazia")
	_esperar(Ritmo.slot == "", "fora do lobby o Ritmo não segue a faixa da construção")
	# quem volta ao lobby na mesma noite (pela pausa) acha o cavaleiro guardado: ✕ confirma, ○ refaz
	var antes_n: Array = []
	for l in 4:
		antes_n.append(jogo.jogadores[l].cavaleiro())
	Forja.robo_confirma = false
	Itens._escudo = [false, false, false, false]   # o Escudo quebrado na última sala: a construção o devolve inteiro
	# pela pausa de verdade: Options no salão, desce até «Voltar ao lobby» e ✕
	var t_volta := Time.get_ticks_msec()
	while jogo._trocando and Time.get_ticks_msec() - t_volta < 10000:
		await _quadros(2)
	await _aperta(0, Forja.OPTIONS)
	_esperar(jogo.overlay == "pausa", "Options no salão abre a pausa (%s)" % jogo.overlay)
	var ate_o_lobby := 0
	for i in jogo.pausa.opcoes.size():
		if jogo.pausa.opcoes[i][0] == "lobby":
			ate_o_lobby = i
	_esperar(ate_o_lobby > 0, "a pausa tem «Voltar ao lobby»")
	for vez in ate_o_lobby:
		await _aperta(0, Forja.BAIXO)
	_esperar(jogo.pausa.opcoes[jogo.pausa.escolhida][0] == "lobby", "▼ na pausa chega a «Voltar ao lobby»")
	await _aperta(0, Forja.CRUZ)
	t_volta = Time.get_ticks_msec()
	while (jogo.estado != "lobby" or jogo._trocando) and Time.get_ticks_msec() - t_volta < 10000:
		await _quadros(2)
	_esperar(jogo.estado == "lobby", "a pausa leva de volta à construção")
	await _quadros(2)
	for l in 4:
		var l2 := 0x21 if Itens.escolhido[l] in [Itens.ESCUDO, Itens.ANCORA] else 0x05
		_esperar(int(_perc(l).get("gatilho_esq", 0)) == l2,
			"P%d: de volta à construção, o L2 diz o item %d (o Escudo inteiro de novo)" % [l + 1, Itens.escolhido[l]])
	_esperar(Itens.escolhido.has(Itens.ESCUDO), "a volta à construção tem um Escudo para conferir")
	for l in 4:
		_esperar(jogo.lobby.etapa[l] == TelaLobby.GUARDADO and jogo.jogadores[l].cavaleiro() == antes_n[l],
			"P%d: voltou ao lobby e achou o cavaleiro guardado" % (l + 1))
	await _aperta(1, Forja.CRUZ)
	_esperar(jogo.lobby.etapa[1] == TelaLobby.FORJADO and jogo.lobby.prontos[1], "✕ no guardado confirma: o P2 fica forjado")
	await _aperta(0, Forja.CIRCULO)
	_esperar(jogo.lobby.etapa[0] == TelaLobby.EDITANDO and not jogo.lobby.prontos[0], "○ no guardado refaz: o P1 volta a editar")
	await _aperta(0, Forja.CRUZ)
	_esperar(jogo.lobby.etapa[0] == TelaLobby.FORJANDO, "✕ começa a forja do P1")
	await _aperta(0, Forja.CRUZ)
	_esperar(jogo.lobby.golpes[0].size() == 1, "cada ✕ em seguida é uma martelada")
	await _aperta(0, Forja.CIRCULO)
	_esperar(jogo.lobby.etapa[0] == TelaLobby.EDITANDO and jogo.lobby.golpes[0].is_empty(), "○ forjando cancela: as marteladas zeram")
	for s in [2, 3]:
		await _aperta(s, Forja.CRUZ)
	Forja.robo_confirma = true   # o robô forja o P1 de novo e fecha a contagem
	t_volta = Time.get_ticks_msec()
	while (jogo.estado != "salao" or jogo._trocando) and Time.get_ticks_msec() - t_volta < 60000:
		await _quadros(2)
	_esperar(jogo.estado == "salao", "com os quatro de novo prontos, o salão")
	_esperar(jogo.lobby.golpes[0].size() == TelaLobby.MARTELADAS, "o P1 refez as oito marteladas")
	Forja.robo_confirma = true  # o robô do fluxo volta para as salas

	await _aperta(0, Forja.CREATE)
	if Forja.bancada:
		_esperar(jogo.overlay == "diagnostico", "bancada: Create abre o diagnóstico")
		await _aperta(0, Forja.CIRCULO)
		_esperar(jogo.overlay == "", "○ fecha o diagnóstico")
	else:
		_esperar(jogo.overlay == "", "jogo: Create não abre o diagnóstico")
	jogo._abrir_overlay("pausa", 0)
	await _quadros(2)
	var acoes: Array = jogo.pausa.opcoes.map(func(o): return o[0])
	_esperar(("livro" in acoes) == Forja.bancada and ("diagnostico" in acoes) == Forja.bancada,
		"a pausa tem o livro e o diagnóstico só na bancada (%s)" % [acoes])
	jogo._fechar_overlay()

	# As salas de entrada, jogadas pelo robô do começo ao fim: cada lugar sai
	# com PASSOU em cada feature da sala. Com um defeito de mentira ligado, a
	# feature que ele quebra tem de sair FALHOU (a prova da prova).
	var centelha = await _comeca_a_sala("centelha")
	if centelha:
		Itens.escolhido[1] = Itens.ESCUDO
		Itens.escolhido[0] = Itens.MARTELO
		Itens.novo_minigame()
		var qt := 0
		while is_instance_valid(centelha) and centelha.treinando and qt < 1200:
			await _quadros(2)
			qt += 2
		Itens.sentir(1)
		await _quadros(2)
		_esperar(int(_perc(1).get("gatilho_esq", 0)) == 0x21, "Centelha: o L2 do P2 firme com o Escudo inteiro")
		await _prova_da_pausa_da_fita()
		var golpe := 0.0
		var metal := 0.0
		_esperar(centelha.errou(1), "Centelha: o Escudo do P2 absorve o primeiro erro")
		for q in 20:
			await _quadros(1)
			golpe = maxf(golpe, float(_perc(1).get("forte", 0.0)))
			metal = maxf(metal, float(Forja.som_virtual(1).get("falante", 0.0)))
		_esperar(golpe > 0.0, "Centelha: o golpe chegou à mão do P2 (%.2f)" % golpe)
		_esperar(metal > 0.0, "Centelha: o metal saiu no alto-falante do P2 (%.2f)" % metal)
		_esperar(int(_perc(1).get("gatilho_esq", 0)) == 0x05, "Centelha: o L2 do P2 afrouxa quando o escudo quebra")
		_esperar(not centelha.errou(1), "Centelha: o segundo erro do P2 é de verdade")
		_esperar(not centelha.errou(0), "Centelha: o P1, sem Escudo, erra de verdade")
		# a Centelha pergunta errou() na runa perdida: com o Escudo inteiro, o combo fica
		Itens.novo_minigame()
		var e2: Dictionary = centelha.j[1]
		var r2 = centelha._runa_atual(1)
		if r2 != null:
			e2.fila.append(r2.duplicate())   # a runa volta ao fim da fila: o robô ainda a joga
			e2.combo = 4
			centelha._perdeu(1, centelha.jogador(1))
			_esperar(int(e2.combo) == 4 and not Itens.escudo_inteiro(1), "Centelha: a runa perdida com o Escudo passa sem zerar o combo")
		await _prova_do_julgamento(centelha)
		await _termina_a_sala(centelha, ["botoes", "analogicos", "gatilhos_analogicos"])
		for l in 2:
			Itens.escolhido[l] = jogo.jogadores[l].item_i
	await _prova_do_kit()
	# o P4 entra na Viga de mãos livres: o registro diz o item dele assim mesmo (G03)
	Itens.escolhido[3] = Itens.NENHUM
	await _joga_a_sala("viga", ["giroscopio", "acelerometro"])
	Itens.escolhido[3] = jogo.jogadores[3].item_i
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
		while Forja.bancada and impacto.estado != SalaImpacto.PERGUNTA and q < 3000:
			await _quadros(1)
			q += 1
		await _quadros(2)
		for l in 4:
			var pedida: int = impacto.j[l].cor_pedida
			if pedida < 0 or not Forja.bancada:
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
		_esperar(voz.g.pivo.find_children("*", "MeshInstance3D", true, false).all(func(m): return not (m.mesh is SphereMesh)),
			"o guardião d'A Voz não tem esfera")
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

	# A Prova: noventa segundos de tudo ligado. Na partida, R2 arma e L2
	# resistência em todos, e a luz é a da equipe; no fim, a prova final às
	# cegas, e cada um sai com PASSOU em tudo junto
	var prova = await _comeca_a_sala("prova")
	if prova:
		var q := 0
		while is_instance_valid(prova) and prova.etapa != SalaProva.PARTIDA and q < 600:
			await _quadros(1)
			q += 1
		await _quadros(4)
		for l in 4:
			var p := _perc(l)
			_esperar(int(p.get("gatilho_dir", 0)) == 0x25, "Prova P%d: R2 arma (0x25)" % (l + 1))
			_esperar(int(p.get("gatilho_esq", 0)) == 0x21, "Prova P%d: L2 resistência (0x21)" % (l + 1))
			var luz: Color = p.get("luz", Color.BLACK)
			_esperar(_mesmo_tom(luz, Forja.cor_do_lugar(l)), "Prova P%d: a luz é a do lugar, não a da equipe" % (l + 1))
		await _termina_a_sala(prova, ["tudo_junto"])

	for l in 4:
		var p := _perc(l)
		_esperar(int(p.get("gatilho_dir", 0)) == 0x05, "de volta ao salão, o R2 do P%d solto" % (l + 1))
	jogo._abrir_overlay("livro", 0)
	await _quadros(2)
	_esperar(jogo.overlay == ("livro" if Forja.bancada else ""), "o livro abre só na bancada")
	if jogo.overlay != "":
		jogo._fechar_overlay()


## Entra na sala, espera o aviso (o robô fica pronto sozinho), o jogo e o
## veredito; confere o veredito de cada lugar e espera a volta ao salão.
func _joga_a_sala(id: String, features: Array) -> void:
	var sala = await _comeca_a_sala(id)
	if sala:
		await _termina_a_sala(sala, features)


## A sala aberta é a do id pedido (o apelido da seção abre o primeiro minigame dela)?
func _e_a_sala(sala, id: String) -> bool:
	return sala.id == id or Catalogo.apelido(sala.id) == id


## O catálogo (H04): os apelidos abrem o primeiro minigame da seção, os ids
## de hoje continuam abrindo, e toda FICHA tem as chaves do molde. Pura.
func _prova_do_catalogo() -> void:
	_esperar(Catalogo.resolver("centelha") == "S01_J01", "catálogo: centelha abre o S01_J01")
	_esperar(Catalogo.apelido("S01_J01") == "centelha", "catálogo: o apelido do S01_J01 é centelha")
	_esperar(Catalogo.resolver("giro") == "viga", "catálogo: o nome antigo da Viga ainda abre a Viga")
	for id in jogo.ORDEM_DO_FOGO + ["bancada"]:
		_esperar(Catalogo.existe(id), "catálogo: --sala=%s continua abrindo" % id)
	_esperar(not Catalogo.existe("nao_existe") and Catalogo.criar("nao_existe") == null, "catálogo: id desconhecido não abre")
	var apelidos := {}
	for s in Catalogo.SECOES:
		apelidos[s.apelido] = true
		for slot in s.minigames:
			_esperar(Catalogo.MINIGAMES.has(slot), "catálogo: %s está em MINIGAMES" % slot)
	_esperar(apelidos.size() == 9, "catálogo: nove seções, nove apelidos")
	for slot in Catalogo.MINIGAMES:
		var mg: Minigame = Catalogo.MINIGAMES[slot].new()
		_esperar(mg.id == slot and mg.conferir_a_ficha(), "catálogo: a FICHA de %s está completa" % slot)
		_esperar(not mg.ficha.is_empty() and mg.nome == str(mg.ficha.titulo), "catálogo: %s leu a FICHA no _init" % slot)
		# a conferência reprova de verdade: sem chave, e com valor fora da lista
		var quebrada: Minigame = Catalogo.MINIGAMES[slot].new()
		quebrada.ficha = quebrada.ficha.duplicate()
		quebrada.ficha.erase("faixa")
		_esperar(not quebrada.conferir_a_ficha(), "catálogo: a FICHA sem chave é reprovada (%s)" % slot)
		quebrada.free()
		var torta: Minigame = Catalogo.MINIGAMES[slot].new()
		torta.ficha = torta.ficha.duplicate()
		torta.ficha["genero"] = "genero_que_nao_existe"
		_esperar(not torta.conferir_a_ficha(), "catálogo: a FICHA com valor fora da lista é reprovada (%s)" % slot)
		torta.free()
		mg.free()


## O kit (H04): o minigame de prova (godot/testes/minigame_de_prova.gd) joga
## com o robô de cada lugar mirando um desvio, e o Ritmo julga cada toque.
## As fases esperam em quadros; a música, pelo relógio de parede.
func _prova_do_kit() -> void:
	var mg: Minigame = load("res://testes/minigame_de_prova.gd").new()
	jogo._entrar_na_sala(mg.id, false, mg)
	await _quadros(2)
	_esperar(jogo.sala == mg and mg.fase in ["entrada", "aviso"], "kit: o minigame de prova abriu")
	await _prova_da_entrada(mg)
	var q := 0
	while is_instance_valid(mg) and mg.fase == "aviso" and q < 600:
		await _quadros(1)
		q += 1
	# a contagem de entrada (H06): tique nos tempos 0 a 2 da faixa, o "vai" no 3, e some
	Som.ultimo_jingle = ""
	var t_conta := Time.get_ticks_usec()
	while is_instance_valid(mg) and mg.fase == "jogo" and Ritmo.batida() < 2.3 and Time.get_ticks_usec() - t_conta < 5000000:
		await _quadros(1)
	_esperar(Som.ultimo_jingle == "JIN_ENTRADA", "kit: a contagem de entrada tocou o tique no tempo da faixa (%s, tempo %.1f)" % [Som.ultimo_jingle, Ritmo.batida()])
	while is_instance_valid(mg) and mg.fase == "jogo" and Ritmo.batida() < 3.3 and Time.get_ticks_usec() - t_conta < 5000000:
		await _quadros(1)
	_esperar(is_instance_valid(mg) and not Ritmo.batida_cheia.is_connected(mg._contar_a_entrada), "kit: a contagem acaba no quarto tempo e solta o relógio")
	# o cabo do P3 sai depois da terceira nota e volta 0,8 s depois: o minigame segue
	var inicio := Time.get_ticks_usec()
	while is_instance_valid(mg) and mg.fase == "jogo" and mg._julgadas[2] < 3 and Time.get_ticks_usec() - inicio < 20000000:
		await _quadros(1)
	_esperar(Forja.ctl.simulador_cabo(2, false), "kit: o cabo do P3 saiu no meio")
	var fora := Time.get_ticks_usec()
	while Time.get_ticks_usec() - fora < 800000:
		await _quadros(1)
	_esperar(is_instance_valid(mg) and mg.fase == "jogo", "kit: sem o P3, o minigame seguiu")
	# G04: sem o cabo, o cartão do P3 fica no canto dele e diz «Sem controle»
	_esperar(not bool(Forja.lugar(2).get("conectado", true)) and jogo.hud.retangulos().has(HudJogo.cartao(2, jogo.hud.size)),
		"G04: sem o cabo, o cartão do P3 continua no canto dele, «Sem controle»")
	# com o cabo, o nó de áudio do controle some: a placa refeita agora fica sem
	# o P3, e só a volta do controle (Main._ao_mudar_os_controles) o devolve
	Forja.som_preparar(Forja.PAPEL_ALTO_FALANTE)
	_esperar(not Forja.som_tem(2, Forja.PAPEL_ALTO_FALANTE), "kit: sem o cabo, a placa refeita fica sem o P3")
	_esperar(Forja.ctl.simulador_cabo(2, true), "kit: o cabo do P3 voltou")
	while is_instance_valid(mg) and mg.fase == "jogo" and Time.get_ticks_usec() - inicio < 40000000:
		await _quadros(1)
	_esperar(is_instance_valid(mg) and mg.fase == "fim", "kit: o minigame acabou pelo próprio jogo (%.1f s)" % ((Time.get_ticks_usec() - inicio) / 1e6))
	if not is_instance_valid(mg):
		return
	_esperar(Musica.atual == "" and Som.ultimo_jingle == "JIN_APITO", "kit: o apito parou a música em seco (%s)" % Som.ultimo_jingle)
	_esperar(Ritmo.dono == "", "kit: no fim o relógio solta a faixa (dono «%s»)" % Ritmo.dono)
	var esperado := [Ritmo.PERFEITO, Ritmo.OTIMO, Ritmo.BOM, Ritmo.ERRO]
	for l in 4:
		var c: Array = mg.contagem[l]
		var total := int(c[0]) + int(c[1]) + int(c[2]) + int(c[3])
		var certos := int(c[esperado[l]])
		# a maioria, não um piso: o toque é julgado no quadro seguinte, e com a
		# máquina carregada o quadro passa dos 25 ms de folga da mira
		_esperar(total == mg.NOTAS and certos == c.max(),
			"kit P%d: %s em %d de %d notas %s" % [l + 1, Ritmo.NOMES_DO_JULGAMENTO[esperado[l]], certos, total, c])
	_esperar(mg.vencedor() == [0, 1, 2, 3], "kit: a colocação pelos pontos (%s, pontos %s)" % [mg.vencedor(), mg.pontos])
	q = 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "kit: de volta ao salão pelo fechamento")
	_esperar(not Ritmo._pausado and Ritmo.slot == "", "kit: o relógio solto ao sair")
	_esperar(Forja.som_tem(2, Forja.PAPEL_ALTO_FALANTE), "kit: o P3 voltou com o alto-falante")


## Entra na sala e espera o jogo começar (o robô fica pronto no aviso).
## Devolve a sala, ou null se ela não abriu.
func _comeca_a_sala(id: String):
	jogo._entrar_na_sala(id, false)
	await _quadros(2)
	var sala = jogo.sala
	_esperar(sala is SalaJogo and _e_a_sala(sala, id), "%s: a sala abriu" % id)
	if not sala is SalaJogo:
		return null
	_esperar(str(sala.icone) != "" and Desenho.glifo(str(sala.icone)) != null, "%s: o aviso tem o ícone da parte do controle" % id)
	# o fim: quando a sala emitir `terminou` e quanto era o relógio no começo
	var fim := [-1.0]  # o t_fase da sala quando ela emitiu terminou
	sala.terminou.connect(func() -> void: fim[0] = float(sala.t_fase))
	sala.set_meta("fim", fim)
	sala.set_meta("duracao_no_inicio", float(sala.duracao))
	var q := 0
	await _passar_a_entrada(sala)
	while is_instance_valid(sala) and sala.fase == "aviso" and q < 600:
		await _quadros(1)
		q += 1
	_esperar(is_instance_valid(sala) and sala.fase == "jogo", "%s: o aviso passou com os quatro prontos" % id)
	# o ✕ do robô chegou pelo controle simulado (F08): passou antes dos 8 s do relógio
	_esperar(q < int(SalaJogo.AVISO_MAX * 60) - 60, "%s: o ✕ dos quatro veio do controle, não do relógio (%d quadros)" % [id, q])
	if is_instance_valid(sala):
		_confere_a_arte(sala, id)
	return sala if is_instance_valid(sala) else null


## Espera o veredito, confere cada lugar em cada feature (e o que foi para o
## relatório) e espera a volta ao salão, com os controles no repouso.
func _termina_a_sala(sala, features: Array) -> void:
	var id: String = sala.id
	var q := 0
	var viu_pergunta := false
	var fim: Array = sala.get_meta("fim")  # pega antes: depois do `terminou` a sala é liberada
	var duracao_no_inicio: float = sala.get_meta("duracao_no_inicio")
	var resta_antes := INF
	var subiu := false
	var amostras := 0
	var fora_do_tom := 0
	var leds_ok := true
	while is_instance_valid(sala) and sala.fase != "fim" and q < 12000:
		await _quadros(10)
		q += 10
		if not Forja.bancada:
			for l in 4:
				var pc := _perc(l)
				amostras += 1
				leds_ok = leds_ok and int(pc.get("leds_jogador", 0)) == Forja.LEDS_DO_LUGAR[l] and int(pc.get("player_index", -9)) == l
				if not _mesmo_tom(pc.get("luz", Color.BLACK), Forja.cor_do_lugar(l)):
					fora_do_tom += 1
		if is_instance_valid(sala) and sala.duracao > 0.0 and not sala.treinando:
			var resta: float = sala.duracao - sala.t_jogo
			subiu = subiu or resta > resta_antes + 0.01
			resta_antes = resta
		if not Forja.bancada and is_instance_valid(sala) and sala.fase == "jogo":
			viu_pergunta = viu_pergunta or _em_pergunta(sala)
	if not Forja.bancada:
		_esperar(not viu_pergunta, "%s: nenhuma pergunta na tela" % id)
		_esperar(leds_ok, "%s: as luzinhas e o player index de cada um nunca mudaram" % id)
		_esperar(fora_do_tom * 4 <= amostras, "%s: a barra de luz ficou na cor do lugar (%d de %d amostras fora)" % [id, fora_do_tom, amostras])
	_esperar(is_instance_valid(sala) and sala.fase == "fim", "%s: o robô jogou até o fim (%d quadros)" % [id, q])
	if not is_instance_valid(sala):
		return
	_esperar(Musica.atual == "" and Som.ultimo_jingle.begins_with("JIN_"), "%s: o apito parou a música em seco (%s)" % [id, Som.ultimo_jingle])
	# o fim é visto no máximo 10 quadros depois do apito, antes dos APITO_S do
	# jingle do resultado: o que soou por último é o apito desta sala, não um
	# jingle que sobrou de antes
	_esperar(Som.ultimo_jingle == "JIN_APITO", "%s: o apito soou no fim (%s)" % [id, Som.ultimo_jingle])
	var jingle_certo := Som.jingle_do_resultado(sala.pontos, sala._presentes_do_fim(), sala.coop, sala.coop_venceu)
	for l in 4:
		var lista: Array = sala.vereditos.get(l, [])
		for f in features:
			var v := {}
			for item in lista:
				if item.get("feature", "") == f:
					v = item
			var so_pergunta: Array = [] if Forja.bancada else SO_COM_PERGUNTA.get(id, [])
			var esperado := Forja.NAO_MEDIDO if f in so_pergunta else Forja.PASSOU
			var ok := int(v.get("resultado", -1)) == esperado
			var porque := str(v.get("obs", "")) if str(v.get("obs", "")) != "" else str(v.get("medido", "sem veredito"))
			_esperar(ok, "%s P%d: %s → %s (%s)" % [id, l + 1, f, str(v.get("rotulo", "sem veredito")), porque])
			var gravado := Forja.ultimo_veredito(l, f)
			_esperar(int(gravado.get("resultado", -1)) == int(v.get("resultado", -2)), "%s P%d: %s gravado no relatório" % [id, l + 1, f])
	# o fechamento é o mesmo para todos: o relógio não volta a encher, o
	# resultado mostra quem venceu e os quatro, e a sala avança sozinha em 6 s
	_esperar(not subiu and is_equal_approx(float(sala.duracao), duracao_no_inicio),
		"%s: o relógio nunca volta a encher" % id)
	# o fim filmado (G07): a tabela só abre depois da cena (o vencedor e, quando há, o inserto)
	var cena: float = sala.fim_da_cena()
	_esperar(sala.plano_do_fim() == "resultado" and not jogo.resultado.visible,
		"%s: o fim começa no plano do vencedor, sem a tabela (%s)" % [id, sala.plano_do_fim()])
	q = 0
	while is_instance_valid(sala) and sala.plano_do_fim() != "" and q < 900:
		await _quadros(1)
		q += 1
	await _quadros(40)
	var col: Array = jogo.resultado.colocacao
	var melhor := -1
	for l in 4:
		melhor = maxi(melhor, int(sala.pontos[l]))
	_esperar(jogo.resultado.visible and col.size() == 4 and int(sala.pontos[col[0]]) == melhor,
		"%s: o resultado mostra quem venceu (P%d) e os quatro" % [id, int(col[0]) + 1 if not col.is_empty() else 0])
	q = 0
	while fim[0] < 0.0 and q < 900:
		await _quadros(1)
		q += 1
	_esperar(fim[0] >= cena + TelaResultado.AVANCA_S - 0.05 and fim[0] <= cena + TelaResultado.AVANCA_S + 0.1,
		"%s: o fim avança sozinho em 6 s depois da cena de %.2f s, robô ou não (%.2f s)" % [id, cena, fim[0]])
	_esperar(Som.ultimo_jingle == jingle_certo, "%s: o jingle do resultado é o certo (%s; esperado %s)" % [id, Som.ultimo_jingle, jingle_certo])
	# o robô aperta ✕ no veredito; a cortina leva de volta ao salão
	q = 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 600:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "%s: de volta ao salão pelo veredito" % id)
	_esperar(Forja.som_pronto(), "%s: a placa de áudio continua aberta" % id)
	for l in 4:
		var p := _perc(l)
		_esperar(int(p.get("gatilho_dir", 0)) == 0x05 and float(p.get("forte", 1.0)) == 0.0,
			"%s: o P%d voltou ao repouso" % [id, l + 1])


## A Prova de Fogo: todas as salas na ordem, sem voltar ao salão. Aqui só a
## costura: a primeira abre com "sala 1 de 9", o ✕ do veredito leva à segunda
## (a primeira acaba na hora: as salas já foram provadas jogadas), e a pausa
## desiste e volta ao salão.
func _prova_de_fogo() -> void:
	jogo._comecar_a_prova_de_fogo(false)
	await _quadros(3)
	var sala = jogo.sala
	_esperar(sala is SalaJogo and _e_a_sala(sala, "centelha") and sala.na_prova_de_fogo == "Prova de Fogo · sala 1 de 9",
		"Prova de Fogo: começa n'A Centelha, sala 1 de 9")
	if not sala is SalaJogo:
		return
	var q := 0
	await _passar_a_entrada(sala)
	while is_instance_valid(sala) and sala.fase == "aviso" and q < 600:
		await _quadros(1)
		q += 1
	sala.terminar()
	q = 0
	while (not jogo.sala is SalaJogo or not _e_a_sala(jogo.sala, "viga") or jogo._trocando) and q < 900:
		await _quadros(2)
		q += 2
	var viga = jogo.sala
	_esperar(viga is SalaJogo and viga.id == "viga" and viga.na_prova_de_fogo == "Prova de Fogo · sala 2 de 9",
		"Prova de Fogo: o ✕ do veredito leva à Viga, sala 2 de 9")
	jogo._na_pausa("salao")
	q = 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 600:
		await _quadros(2)
		q += 2
	_esperar(jogo.estado == "salao" and jogo.fogo == -1, "Prova de Fogo: pela pausa, desiste e volta ao salão")


## O cavaleiro como dado (G02): vestir e cavaleiro() são inversos; o acabamento
## muda só a rugosidade e o metal, nunca a cor; o arquivo devolve o que se guardou.
func _prova_do_cavaleiro_guardado() -> void:
	var p := ForjaPlayer.new()
	add_child(p)
	p.montar(0)
	var c := {"cabeca": "male-c", "superior": "female-f", "inferior": "male-a", "cadeira": "", "item": "escudo", "nome": "Cromo", "acabamento": 1}
	p.vestir(c)
	_esperar(p.cavaleiro() == c, "o cavaleiro: vestir e cavaleiro() são inversos (%s)" % [p.cavaleiro()])
	var m: ShaderMaterial = p._mats_corpo[0]
	var tex_antes = m.get_shader_parameter("textura_cima")
	_esperar(is_equal_approx(float(m.get_shader_parameter("rugoso_cima")), 0.45) and is_equal_approx(float(m.get_shader_parameter("rugoso_baixo")), 0.45)
		and is_equal_approx(float(m.get_shader_parameter("metal")), 0.2), "o acabamento Polido mexe na rugosidade e no metal")
	p.vestir({"cabeca": "male-c", "superior": "female-f", "inferior": "male-a", "cadeira": "", "item": "escudo", "nome": "Cromo", "acabamento": 0})
	var m0: ShaderMaterial = p._mats_corpo[0]
	_esperar(is_equal_approx(float(m0.get_shader_parameter("rugoso_cima")), ForjaPlayer.RUGOSO_CIMA)
		and is_equal_approx(float(m0.get_shader_parameter("rugoso_baixo")), ForjaPlayer.RUGOSO_BAIXO)
		and float(m0.get_shader_parameter("metal")) == 0.0 and m0.get_shader_parameter("textura_cima") == tex_antes,
		"e o Fosco volta à rugosidade de cada parte, com a mesma cor")
	var maior := 0.0
	for a in ForjaPlayer.ACABAMENTOS:
		maior = maxf(maior, float(a.metal))
	_esperar(maior <= 0.2, "o metal de nenhum acabamento passa de 0,2 (%.2f)" % maior)
	var colecao_antes := [Colecao.vencidos.duplicate(), Colecao.recordes.duplicate(), Colecao.trofeus.duplicate(), Colecao.desbloqueados.duplicate()]
	Colecao.zerar()
	_esperar(ForjaPlayer.acabamentos_disponiveis() == [0, 1, 2], "os acabamentos livres são três (%s)" % [ForjaPlayer.acabamentos_disponiveis()])
	Colecao.desbloqueados = ["Dourado", "Cromado", "Néon"]
	_esperar(ForjaPlayer.acabamentos_disponiveis() == [0, 1, 2, 3, 4, 5], "com a coleção, o Dourado, o Cromado e o Néon se oferecem (%s)" % [ForjaPlayer.acabamentos_disponiveis()])
	Colecao.vencidos = colecao_antes[0]
	Colecao.recordes = colecao_antes[1]
	Colecao.trofeus = colecao_antes[2]
	Colecao.desbloqueados = colecao_antes[3]
	_esperar(ForjaPlayer.ITENS.size() == 7 and ForjaPlayer.ITENS[0].id == "" and ForjaPlayer.ITENS[1].id == "martelo", "os sete itens, o 0 de mãos livres")
	# o dicionário antigo da G02 (com "boneco") vira o pré-montado, com o item e o nome que tinha (G13)
	p.vestir({"boneco": 1, "item": "escudo", "nome": "Cromo", "acabamento": 0})
	var velho := p.cavaleiro()
	_esperar(p.pecas.size() == 3 and Cavaleiro.corpo(p.pecas).valido and velho.get("item", "") == "escudo" and velho.get("nome", "") == "Cromo",
		"o cavaleiro antigo, com boneco, vira o pré-montado de três peças (%s)" % [velho])
	remove_child(p)
	p.free()
	var guardados_antes: Array = Opcoes.cavaleiro.duplicate(true)
	var noite_antes := Opcoes.noite_dos_cavaleiros
	var arquivo := "user://opcoes-da-prova-g02.cfg"
	Opcoes.cavaleiro = [c, {}, {}, {"boneco": 0, "item": "ancora", "nome": "Ônix", "acabamento": 2}]
	Opcoes.noite_dos_cavaleiros = "2026-10-08"
	Opcoes.gravar(false, arquivo)
	Opcoes.cavaleiro = [{}, {}, {}, {}]
	Opcoes.noite_dos_cavaleiros = ""
	Opcoes.ler(arquivo)
	_esperar(Opcoes.cavaleiro[0] == c and Opcoes.cavaleiro[1].is_empty() and Opcoes.cavaleiro[3].get("item", "") == "ancora"
		and Opcoes.noite_dos_cavaleiros == "2026-10-08", "o cavaleiro e a noite voltam do arquivo (%s)" % [Opcoes.cavaleiro])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(arquivo))
	var noite := Opcoes.noite()
	_esperar(noite.length() == 10 and noite[4] == "-" and noite[7] == "-", "a noite é uma data (%s)" % noite)
	Opcoes.cavaleiro = guardados_antes
	Opcoes.noite_dos_cavaleiros = noite_antes


func _prova_do_relatorio() -> void:
	Forja.veredito(0, "botoes", Forja.PASSOU, Forja.NIVEL_REAGIU, "apertar ✕", "✕ chegou")
	_esperar(Forja.gravar_relatorio(), "o relatório grava")
	if pasta == "":
		return
	var arquivos := DirAccess.get_files_at(pasta)
	# o kit (H04): na linha do tempo, os quatro julgamentos do minigame de
	# prova, e todo minigame que terminou tem vencedor
	var julgamentos := {}
	var sem_vencedor: Array = []
	var terminados := 0
	for f in arquivos:
		if not (f.begins_with("linha-do-tempo-") and f.ends_with(".jsonl")):
			continue
		var comecou := {}  # slot -> a fase jogo começou (o `minigame` `comecou`)
		for linha in FileAccess.get_file_as_string(pasta.path_join(f)).split("\n", false):
			var ev = JSON.parse_string(linha)
			if not ev is Dictionary:
				continue
			if ev.get("tipo", "") == "toque" and ev.get("slot", "") == "T00_J00":
				julgamentos[ev.get("julgamento", "?")] = true
			if ev.get("tipo", "") == "minigame" and ev.get("evento", "") == "comecou":
				comecou[str(ev.get("slot", ""))] = true
			# a sala fechada ainda no aviso (a prova do motor) não jogou: só conta quem começou
			if ev.get("tipo", "") == "minigame" and ev.get("evento", "") == "terminou" and comecou.get(str(ev.get("slot", "")), false):
				comecou.erase(str(ev.get("slot", "")))
				terminados += 1
				if int(ev.get("vencedor", -1)) < 0:
					sem_vencedor.append(ev)
	_esperar(julgamentos.has("perfeito") and julgamentos.has("otimo") and julgamentos.has("bom") and julgamentos.has("erro"),
		"registro: os quatro julgamentos do minigame de prova (%s)" % [julgamentos.keys()])
	_esperar(terminados >= 2 and sem_vencedor.is_empty(), "registro: %d minigames terminaram, todos com vencedor (%s)" % [terminados, sem_vencedor])
	# o registro v2 do ritmo: os toques da prova das janelas (n 900 e 901)
	var julgado := {}
	var perdido := {}
	var ruins: Array = []
	var calibracoes: Array = []
	var absorveu := 0
	var leva := {}
	for f in arquivos:
		if not (f.begins_with("linha-do-tempo-") and f.ends_with(".jsonl")):
			continue
		for linha in FileAccess.get_file_as_string(pasta.path_join(f)).split("\n", false):
			var ev = JSON.parse_string(linha)
			if not ev is Dictionary:
				ruins.append(linha.left(80))
			elif ev.get("tipo", "") == "toque":
				if int(ev.get("n", -1)) == 900:
					julgado = ev
				elif int(ev.get("n", -1)) == 901:
					perdido = ev
			elif ev.get("tipo", "") == "calibracao":
				calibracoes.append(ev)
			if ev is Dictionary and str(ev.get("tipo", "")) == "item" and str(ev.get("efeito", "")) == "absorveu":
				absorveu += 1
			if ev is Dictionary and str(ev.get("tipo", "")) == "item" and str(ev.get("efeito", "")) == "leva":
				leva[int(ev.get("lugar", -1))] = true
				if str(ev.get("item", "")) == str(ForjaPlayer.ITENS[Itens.NENHUM].nome):
					leva["livres"] = true
	_esperar(ruins.is_empty(), "linha do tempo: toda linha é JSON (%d não: %s)" % [ruins.size(), ruins.slice(0, 2)])
	_esperar(julgado.get("julgamento", "") == "perfeito" and absf(float(julgado.get("desvio_ms", 0.0)) - 12.0) < 0.01,
		"registro: o toque julgado, com o desvio (%s)" % [julgado])
	_esperar(perdido.get("julgamento", "") == "erro" and perdido.get("perdida", false) and not perdido.has("desvio_ms"),
		"registro: a nota perdida, sem desvio (%s)" % [perdido])
	_esperar(calibracoes.any(func(ev): return int(ev.get("desvio_ms", 0)) == 80 and ev.get("transporte", "") == "simulado"),
		"registro: a calibração de +80 ms, com o transporte do controle")
	# o som em todo evento (H07): cada lugar recebeu sons no controle, com a
	# placa (a virtual, nos simulados), o pio na entrada e a nota do perfeito
	var sons := [0, 0, 0, 0]
	var pios := 0
	var notas := 0
	var materiais := 0
	var quebradas := 0
	var cliques := 0
	for f in arquivos:
		if not (f.begins_with("linha-do-tempo-") and f.ends_with(".jsonl")):
			continue
		for linha in FileAccess.get_file_as_string(pasta.path_join(f)).split("\n", false):
			var ev = JSON.parse_string(linha)
			if not ev is Dictionary or ev.get("tipo", "") != "som_controle":
				continue
			var l := int(ev.get("lugar", -1))
			if l >= 0 and l < 4 and ev.get("placa", false):
				sons[l] += 1
			pios += 1 if str(ev.get("som", "")).begins_with("pio:") else 0
			notas += 1 if str(ev.get("som", "")) == "nota:0" else 0
			materiais += 1 if str(ev.get("som", "")).begins_with("material:") else 0
			# o P4 do minigame de prova nunca aperta: a nota dele quebra, no controle dele
			quebradas += 1 if l == 3 and str(ev.get("som", "")) == "nota_quebrada:3" else 0
			# o P2 andou nas opções: o clique baixinho (0,5) só no controle dele
			cliques += 1 if l == 1 and str(ev.get("som", "")) == "clique" and is_equal_approx(float(ev.get("ganho", 0.0)), 0.5) else 0
	_esperar(sons.all(func(n): return n > 0), "registro: cada controle recebeu som, com a placa (%s)" % [sons])
	_esperar(pios >= 4 and notas >= 1, "registro: o pio de cada um e a nota do perfeito (%d pios, %d notas)" % [pios, notas])
	_esperar(materiais > 0, "registro: a textura do material chegou ao controle (%d)" % materiais)
	_esperar(quebradas > 0, "registro: o erro quebra a nota no controle do dono (%d)" % quebradas)
	_esperar(cliques > 0, "registro: a navegação clica no controle de quem navegou (%d)" % cliques)
	var da_construcao := calibracoes.filter(func(ev): return str(ev.get("origem", "")) == "construcao" and int(ev.get("amostras", 0)) == 8)
	var lugares_c := {}
	for ev in da_construcao:
		lugares_c[int(ev.get("lugar", -1))] = true
	_esperar(lugares_c.size() == 4 and da_construcao.size() >= 4, "a linha do tempo tem a calibração dos quatro (%d linhas, %d lugares)" % [da_construcao.size(), lugares_c.size()])
	_esperar(absorveu >= 1, "o registro tem o Escudo agindo")
	var de_maos_livres: bool = leva.erase("livres")
	_esperar(leva.size() == 4 and de_maos_livres,
		"o registro tem o item dos quatro ao entrar na sala, mãos livres também (%d lugares, mãos livres: %s)" % [leva.size(), de_maos_livres])
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


## As contas da partida, sem abrir sala: o roteiro, a colocação com empate e o
## pódio com o desempate pelas salas vencidas.
func _prova_das_contas_da_partida() -> void:
	var ordem: Array = jogo.ORDEM_DO_FOGO
	_esperar(Partida.roteiro(3, false, 7, ordem) == ["centelha", "galeria", "prova"], "partida: três salas na ordem")
	_esperar(Partida.roteiro(9, false, 7, ordem) == ordem, "partida: nove salas na ordem são o percurso")
	var s1 := Partida.roteiro(5, true, 7, ordem)
	var s2 := Partida.roteiro(5, true, 7, ordem)
	var unicas := {}
	for id in s1:
		unicas[id] = true
	_esperar(s1 == s2, "partida sorteada: a mesma semente, o mesmo sorteio")
	_esperar(s1.size() == 5 and unicas.size() == 5 and s1[4] == "prova", "partida sorteada: cinco salas sem repetir, A Prova no fim (%s)" % [s1])
	var s9 := Partida.roteiro(9, true, 7, ordem)
	var todas := s9.duplicate()
	todas.sort()
	var esperadas := ordem.duplicate()
	esperadas.sort()
	_esperar(todas == esperadas and s9 != ordem, "partida sorteada de nove: as nove, noutra ordem")
	var col := Partida.colocacoes([300, 100, 300, 0], [0, 1, 2, 3])
	_esperar(col == [1, 3, 1, 4], "partida: o empate divide a colocação de cima (%s)" % [col])
	_esperar(Partida.colocacoes([50, 0, 90, 0], [0, 2]) == [2, 0, 1, 0], "partida: quem não jogou fica sem colocação")
	var p := Partida.nova(3, false, 7, ordem)
	var e := p.registrar("centelha", [300, 100, 300, 0], [0, 1, 2, 3])
	_esperar(e.ganhos == [4, 2, 4, 1], "partida: 1º 4, 3º 2, 4º 1, e o empate em primeiro dá 4 aos dois")
	p.registrar("galeria", [0, 10, 20, 30], [0, 1, 2, 3])
	# P1 4+1=5, P2 2+2=4, P3 4+3=7, P4 1+4=5: P3 primeiro; P1 e P4 empatam em 5
	# e numa sala vencida cada: a última sala desempata (P4 1º, P1 4º)
	var podio := p.podio([0, 1, 2, 3])
	_esperar(int(podio[0].lugar) == 2 and int(podio[0].degrau) == 1, "partida: P3 no topo do pódio")
	_esperar(int(podio[1].lugar) == 3 and int(podio[2].lugar) == 0 and str(podio[1].criterio) == "a última sala",
		"partida: o empate em pontos e em salas vencidas, a última sala desempata")
	var degraus := {}
	for item in podio:
		degraus[int(item.degrau)] = true
	_esperar(degraus.size() == 4, "partida: nenhum degrau dividido — alguém sempre ganha")
	_esperar(Placar.frase_do_vencedor(podio) == "P3 venceu a noite", "partida: a frase do pódio")
	# o empate total (mesmos pontos, nenhuma sala vencida a mais, as mesmas
	# colocações): o sorteio da semente decide, e decide igual sempre
	var q := Partida.nova(3, false, 7, ordem)
	q.registrar("centelha", [10, 10, 10, 10], [0, 1, 2, 3])
	var pq := q.podio([0, 1, 2, 3])
	_esperar(str(pq[0].criterio) == "o sorteio" and Placar.frase_do_vencedor(pq).ends_with("desempate: o sorteio"),
		"partida: o empate de todos, o sorteio decide (%s)" % Placar.frase_do_vencedor(pq))
	_esperar(int(q.podio([0, 1, 2, 3])[0].lugar) == int(pq[0].lugar), "partida: o sorteio é o mesmo a cada consulta")
	p.registrar("prova", [0, 0, 0, 0], [0, 1, 2, 3])
	_esperar(p.acabou(), "partida: acabou depois da terceira sala")


## A partida jogada: três salas, o placar entre elas (o robô aperta ✕), o
## pódio no salão e ○ de volta ao salão.
func _prova_da_partida() -> void:
	jogo._comecar_a_partida(3, false, false)
	await _quadros(3)
	var ids := ["centelha", "galeria", "prova"]
	var pontos := [[10, 40, 30, 20], [0, 50, 10, 20], [5, 60, 0, 0]]
	for i in ids.size():
		var q := 0
		while (not jogo.sala is SalaJogo or not _e_a_sala(jogo.sala, ids[i]) or jogo._trocando) and q < 900:
			await _quadros(2)
			q += 2
		var sala = jogo.sala
		_esperar(sala is SalaJogo and _e_a_sala(sala, ids[i]) and sala.na_prova_de_fogo == "Partida · sala %d de 3" % (i + 1),
			"partida: %s é a sala %d de 3" % [ids[i], i + 1])
		if not sala is SalaJogo:
			return
		q = 0
		await _passar_a_entrada(sala)
		while is_instance_valid(sala) and sala.fase == "aviso" and q < 600:
			await _quadros(1)
			q += 1
		for l in 4:
			sala.pontos[l] = pontos[i][l]
		sala.terminar()
		if i == 0:
			await _prova_do_fim_filmado(sala)
		q = 0
		while jogo.overlay != "placar" and q < 600:
			await _quadros(2)
			q += 2
		_esperar(jogo.overlay == "placar" and jogo.partida.historico.size() == i + 1, "partida: o placar depois d%s" % Placar._contracao(sala.nome))
		# a partida fala pelo apelido (H04): o slot do minigame não chega ao placar
		_esperar(not jogo.partida.historico.is_empty() and str(jogo.partida.historico[-1].sala) == ids[i],
			"partida: o placar guarda a sala pelo apelido (%s)" % [jogo.partida.historico[-1].sala if not jogo.partida.historico.is_empty() else "-"])
	var q := 0
	while (jogo.estado != "podio" or jogo._trocando) and q < 900:
		await _quadros(2)
		q += 2
	_esperar(jogo.estado == "podio" and jogo.placar.visible and jogo.placar.no_podio, "partida: o pódio no fim")
	# P2 venceu as três: 12; P3 e P4 empatam em 7 e dividem o 2º; P1 fica com 5
	var lista: Array = jogo.partida.podio(jogo.partida.presentes())
	_esperar(int(lista[0].lugar) == 1 and int(lista[0].total) == 12, "partida: P2 venceu a noite com 12 (%s)" % [lista])
	_esperar(Placar.frase_do_vencedor(lista) == "P2 venceu a noite", "partida: a frase diz quem venceu")
	for l in 4:
		_esperar(not jogo.jogadores[l].controlavel, "partida: no pódio, o P%d fica no pedestal" % (l + 1))
	_esperar(Forja.som_pronto(), "partida: no pódio, a placa de áudio continua aberta")
	await _quadros(60)
	await _aperta(0, Forja.CIRCULO)
	q = 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 600:
		await _quadros(2)
		q += 2
	_esperar(jogo.estado == "salao" and jogo.partida == null and not jogo.placar.visible, "partida: ○ no pódio volta ao salão")
	_esperar(Forja.som_pronto(), "partida: ○ no pódio, a placa de áudio continua aberta")
	await _prova_da_colecao_no_salao()


## O salão depois da partida (G06): o portão aceso, o contador, a vitrine, a dica presa e os sons do ✕.
func _prova_da_colecao_no_salao() -> void:
	await _quadros(4)
	_esperar(Colecao.vencidos.has("centelha"), "coleção: A Centelha foi vencida nesta noite")
	_esperar(jogo.salao.portao_aceso("centelha"), "o portão d'A Centelha acendeu")
	# o robô já venceu os outros portões no percurso: tira o d'A Voz da noite para ver um apagado
	var voz_antes = Colecao.vencidos.get("voz", null)
	Colecao.vencidos.erase("voz")
	jogo.salao.mostrar_colecao()
	var foco: SpotLight3D = jogo.salao.portoes["centelha"].foco
	var foco_fechado: SpotLight3D = jogo.salao.portoes["voz"].foco
	_esperar(is_equal_approx(foco.light_energy, Salao.FOCO_ACESO) and is_equal_approx(foco_fechado.light_energy, Salao.FOCO_APAGADO), "o foco: %.2f aceso, %.2f apagado" % [foco.light_energy, foco_fechado.light_energy])
	_esperar((jogo.salao.portoes["centelha"].tubo as Node3D).visible and not (jogo.salao.portoes["voz"].tubo as Node3D).visible, "o tubo de tungstênio só no portão aceso")
	_esperar(not jogo.salao.portao_aceso("voz"), "um portão que ninguém venceu não acende")
	if voz_antes != null:
		Colecao.vencidos["voz"] = voz_antes
	jogo.salao.mostrar_colecao()
	_esperar(jogo.hud.vencidas == Colecao.secoes_acesas() and jogo.hud.vencidas >= 1, "o contador do salão (%d/9)" % jogo.hud.vencidas)
	_esperar(jogo.salao.trofeus_na_vitrine() == mini(Colecao.trofeus.size(), 18), "a vitrine mostra os troféus (%d)" % Colecao.trofeus.size())
	var dono: int = int(Colecao.vencidos["centelha"])
	var primeiro := -1
	for i in Colecao.trofeus.size():
		if Colecao.trofeus[i].id == "centelha" and Colecao.trofeus[i].tipo == "vitoria":
			primeiro = i
	var de := maxi(0, Colecao.trofeus.size() - 18)
	_esperar(primeiro >= de and jogo.salao.cor_do_trofeu(primeiro - de).is_equal_approx(Tema.JOGADOR[dono]), "a taça tem a cor de quem venceu")
	_esperar(ForjaPlayer.acabamentos_disponiveis().has(3), "a construção oferece o Dourado")
	# a dica presa e o som do ✕, sem entrar
	jogo.jogadores[0].global_position = jogo.salao.saida_do_portao("centelha", 0)
	await _quadros(3)
	_esperar(jogo.hud.dica_presa.get("lugar", -1) == 0, "perto do portão, a dica presa ao P1")
	var tela := Rect2(Vector2.ZERO, jogo.hud.size)
	_esperar(jogo.hud.retangulos().all(func(r): return tela.encloses(r)), "o contador, os chips e a dica presa cabem na tela")
	var linhas_da_dica: Array = jogo.hud.dica_presa.get("linhas", [])
	_esperar(not linhas_da_dica.is_empty() and str(linhas_da_dica[0][1]) == "Tocar a faixa", "a dica presa diz «Tocar a faixa» (%s)" % [linhas_da_dica])
	# o ✕ pelo controle simulado, no portão: o alto-falante do P1 cala antes, soa depois, e a sala abre
	var t_parede := Time.get_ticks_msec()   # o som de 90 ms anda em tempo de parede; o jogo, sem janela, anda mais depressa
	while Time.get_ticks_msec() - t_parede < 600 and float(Forja.som_virtual(0).get("falante", 0.0)) > 0.0:
		await _quadros(1)
	var calado := float(Forja.som_virtual(0).get("falante", 0.0)) == 0.0
	var onde_estavam: Array = jogo.jogadores.map(func(p): return p.global_position)
	Forja.ctl.simulador_botao(0, Forja.CRUZ, true)
	var falante := 0.0
	t_parede = Time.get_ticks_msec()
	var q := 0
	while Time.get_ticks_msec() - t_parede < 400:
		await _quadros(1)
		q += 1
		if q == 2:
			Forja.ctl.simulador_botao(0, Forja.CRUZ, false)
		falante = maxf(falante, float(Forja.som_virtual(0).get("falante", 0.0)))
	Forja.ctl.simulador_botao(0, Forja.CRUZ, false)
	_esperar((calado and falante > 0.0) or not Forja.modulo, "o ✕ no portão soa no alto-falante de quem apertou (%.2f)" % falante)
	q = 0
	while jogo.estado != "sala" and q < 300:
		await _quadros(1)
		q += 1
	_esperar(jogo.estado == "sala" and jogo.sala_id == "centelha", "o ✕ no portão aberto entra na sala (%s)" % jogo.estado)
	q = 0
	while jogo._trocando and q < 120:   # a cortina termina de abrir
		await _quadros(1)
		q += 1
	jogo._ir_para_o_salao(false)
	await _quadros(3)
	_esperar(jogo.estado == "salao", "de volta ao salão sem jogar a sala")
	for l in range(1, jogo.jogadores.size()):   # a volta põe todos na boca do portão: os outros voltam para onde estavam
		jogo.jogadores[l].global_position = onde_estavam[l]
	jogo.jogadores[0].global_position = Vector3(-3.0, 0.05, 3.2)
	await _quadros(3)
	_esperar(jogo.hud.dica_presa.is_empty(), "longe do portão, nenhuma dica")


## As contas da coleção, sem sala (G06).
func _prova_das_contas_da_colecao() -> void:
	var antes := [Colecao.vencidos.duplicate(), Colecao.recordes.duplicate(), Colecao.trofeus.duplicate(), Colecao.desbloqueados.duplicate()]
	Colecao.zerar()
	_esperar(Colecao.registrar("molde", [0, 0, 0, 0], [0, 1]).desbloqueou == [], "coleção: ninguém pontuou, nada se ganha")
	_esperar(Colecao.trofeus.is_empty() and not Colecao.vencidos.has("molde"), "coleção: zero pontos não é vitória")
	_esperar(Colecao.registrar("molde", [10, 40, 40, 0], [0, 1, 2]).desbloqueou == ["Dourado"], "coleção: a primeira vitória desbloqueia o Dourado")
	_esperar(Colecao.vencidos["molde"] == 1, "coleção: o empate em cima vai para o menor lugar")
	var r := Colecao.registrar("molde", [90, 0, 0, 0], [0, 1])
	var tipos := Colecao.trofeus.map(func(t): return str(t.tipo))
	_esperar(tipos == ["vitoria", "recorde"] and r.recorde == 0, "coleção: vencer de novo com mais pontos é recorde (%s)" % [tipos])
	_esperar(Colecao.secao_acesa("molde") and not Colecao.secao_acesa("viga"), "coleção: a seção acende só com os minigames dela vencidos")
	Colecao.registrar("viga", [5, 0, 0, 0], [0])
	Colecao.registrar("canto", [0, 5, 0, 0], [1])
	_esperar(Colecao.secoes_acesas() == 3 and Colecao.desbloqueado("Cromado"), "coleção: três seções acesas desbloqueiam o Cromado")
	Colecao.registrar("caminhos", [1, 1, 1, 1], [0, 1, 2, 3], true, true)
	_esperar(Colecao.desbloqueado("Néon"), "coleção: o coop sem erro desbloqueia o Néon")
	_esperar(Colecao.registrar("caminhos", [1, 1, 1, 1], [0, 1, 2, 3], true, false).desbloqueou == [], "coleção: nada se ganha duas vezes")
	# o arquivo: outra noite começa vazia e a mais velha se apaga
	var arq := "user://prova_colecao.cfg"
	var noite_antes := Colecao.noite
	Colecao.noite = "2026-10-01"
	Colecao.gravar(false, arq)
	Colecao.zerar()
	Colecao.noite = "2026-10-02"
	Colecao.ler(arq)
	_esperar(Colecao.vencidos.is_empty() and Colecao.trofeus.is_empty(), "coleção: outra noite começa vazia")
	Colecao.noite = "2026-10-01"
	Colecao.ler(arq)
	_esperar(Colecao.vencidos.has("molde") and Colecao.desbloqueado("Néon"), "coleção: a mesma noite volta do arquivo")
	for k in Colecao.NOITES_GUARDADAS + 2:
		Colecao.noite = "2026-11-%02d" % (k + 1)
		Colecao.gravar(false, arq)
	var cfg := ConfigFile.new()
	cfg.load(arq)
	_esperar(cfg.get_sections().size() <= Colecao.NOITES_GUARDADAS and not cfg.has_section("2026-10-01"), "coleção: o arquivo guarda só as %d noites mais novas (%d)" % [Colecao.NOITES_GUARDADAS, cfg.get_sections().size()])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(arq))
	Colecao.gravar(true, arq)   # o robô não grava
	_esperar(not FileAccess.file_exists(arq), "coleção: com o robô nada se grava")
	Colecao.noite = noite_antes
	for a in ForjaPlayer.ACABAMENTOS:
		_esperar(float(a.get("metal", 0.0)) <= 0.2 and float(a.get("acento", 1.6)) <= 3.0, "acabamento %s: metal até 0,2 e acento até 3,0" % a.nome)
	_esperar(ForjaPlayer.ACABAMENTOS[5].nome == "Néon" and float(ForjaPlayer.ACABAMENTOS[5].acento) == 2.4, "o Néon tem o acento de 2,4")
	Colecao.vencidos = antes[0]
	Colecao.recordes = antes[1]
	Colecao.trofeus = antes[2]
	Colecao.desbloqueados = antes[3]


## O relógio (H01): a volta do laço (a conta pura), o relógio do sistema sem
## faixa e o da placa com a trilha sintetizada. Espera pelo relógio de
## parede: com --fixed-fps 60 sem janela, o jogo anda mais depressa que ele.
func _prova_do_relogio() -> void:
	var r := Ritmo.posicao_continua(0.2, 17.6, 0, 17.8)
	_esperar(int(r[1]) == 1 and absf(float(r[0]) - 18.0) < 0.0001, "relógio: a volta do laço soma a duração (%s)" % [r])
	r = Ritmo.posicao_continua(5.0, 4.98, 1, 17.8)
	_esperar(int(r[1]) == 1 and absf(float(r[0]) - 22.8) < 0.0001, "relógio: sem volta, a posição segue")
	var b := Musica.bpm_sintetizado(108.0)
	_esperar(absf(b - 108.0027) < 0.0001, "relógio: o andamento de verdade da síntese (%.4f)" % b)
	await _medir_o_relogio("", 0.8, "sem faixa", false)
	await _medir_o_relogio("MUS_S01_J01", 1.5, "com a faixa", Forja.modulo)
	Ritmo.parar()


func _medir_o_relogio(slot: String, segundos: float, rotulo: String, pela_placa: bool) -> void:
	var mapa := Musica.mapa(slot)
	Ritmo.tocar(slot, float(mapa.bpm), float(mapa.primeiro_tempo))
	_esperar(Ritmo._pelo_audio == pela_placa, "relógio %s: %s" % [rotulo, "pela placa" if pela_placa else "pelo sistema"])
	var sinais := [0]
	var conta := func(_n: int) -> void: sinais[0] += 1
	Ritmo.batida_cheia.connect(conta)
	var inicio := Time.get_ticks_usec()
	var antes := Ritmo.t_musica()
	var recuou := false
	var batida_certa := true
	while Time.get_ticks_usec() - inicio < int(segundos * 1000000.0):
		await _quadros(1)
		var t := Ritmo.t_musica()
		recuou = recuou or t < antes
		antes = t
		var esperada := (t - Ritmo.primeiro_tempo) * Ritmo.bpm / 60.0
		batida_certa = batida_certa and absf(Ritmo.batida() - esperada) < 0.000001
	Ritmo.batida_cheia.disconnect(conta)
	var andou := Ritmo.t_musica()
	_esperar(not recuou, "relógio %s: nunca anda para trás" % rotulo)
	_esperar(batida_certa, "relógio %s: a batida é (t_musica − primeiro tempo) × bpm / 60" % rotulo)
	_esperar(andou > segundos * 0.7 and andou < segundos * 1.3,
		"relógio %s: andou %.3f s em %.1f s de relógio" % [rotulo, andou, segundos])
	var tempos := int(floor(andou * float(mapa.bpm) / 60.0)) + 1  # o tempo 0 também conta
	_esperar(absi(sinais[0] - tempos) <= 1, "relógio %s: um sinal por tempo (%d sinais, %d tempos)" % [rotulo, sinais[0], tempos])


## A calibração (H03): o desvio do lugar vale no julgamento, a linha Tempo
## das opções anda de 10 em 10 e para nas bordas. Devolve tudo como achou.
func _prova_da_calibracao() -> void:
	var guardado: Array = Opcoes.tempo_ms.duplicate()
	Ritmo.definir_desvio(2, 0.080, "opcoes")
	_esperar(Opcoes.tempo_ms[2] == 80 and is_equal_approx(Ritmo.desvio[2], 0.080), "calibração: +80 ms nas opções e no Ritmo")
	_esperar(Ritmo.julgar(2, 10.080, 10.0) == Ritmo.PERFEITO, "calibração: com +80 ms, 80 ms atrasado é perfeito")
	var tela := TelaOpcoes.new()
	tela.abrir(1)
	var i := -1
	for k in tela._linhas.size():
		if tela._linhas[k][0] == "tempo":
			i = k
	_esperar(i >= 0 and tela._linhas[i][2] == "P2", "calibração: a linha Tempo é do lugar que abriu")
	if i >= 0:
		tela.linha = i
		Ritmo.definir_desvio(1, 0.0, "opcoes")
		tela.trocar(1)
		_esperar(Opcoes.tempo_ms[1] == 10 and is_equal_approx(Ritmo.desvio[1], 0.010), "calibração: ▶ soma 10 ms")
		tela.trocar(-1)
		tela.trocar(-1)
		_esperar(Opcoes.tempo_ms[1] == -10 and tela.valor("tempo") == "-10 ms", "calibração: ◀ tira 10 ms, e a linha mostra")
		Ritmo.definir_desvio(1, 0.250, "opcoes")
		tela.trocar(1)
		_esperar(Opcoes.tempo_ms[1] == Opcoes.TEMPO_MAX, "calibração: para em +%d ms" % Opcoes.TEMPO_MAX)
		Ritmo.definir_desvio(1, -0.150, "opcoes")
		tela.trocar(-1)
		_esperar(Opcoes.tempo_ms[1] == Opcoes.TEMPO_MIN, "calibração: para em %d ms" % Opcoes.TEMPO_MIN)
		# o metrônomo: ✕ 30 ms depois do tique ouvido e ✕ 70 ms antes do próximo, já corrigidos pelo tempo do lugar
		Ritmo.definir_desvio(1, 0.020, "opcoes")
		tela._toques = []
		tela._ouvido_us = Time.get_ticks_usec() - 30000
		tela.tocou()
		tela._ouvido_us = Time.get_ticks_usec() - (tela._periodo_us() - 70000)
		tela.tocou()
		_esperar(tela._toques.size() == 2 and absf(float(tela._toques[0]) - 10.0) < 5.0 and absf(float(tela._toques[1]) + 90.0) < 5.0,
			"calibração: o metrônomo mede o toque contra a batida mais perto, menos o tempo do lugar (%s)" % [tela._toques])
		tela.linha = 0
		tela.tocou()
		_esperar(tela._toques.size() == 2, "calibração: ✕ fora da linha Tempo não deixa ponto")
		tela.linha = i
		for k in 9:
			tela.tocou()
		_esperar(tela._toques.size() == 8, "calibração: a régua guarda os últimos 8 toques")
		# o tique: um por batida, só no começo dela; a batida achada tarde passa calada
		var per := tela._periodo_us()
		tela._metronomo_us = 0
		tela._batida_tocada = -1
		var t1 := tela._tique(10000)
		var t2 := tela._tique(20000)
		var t3 := tela._tique(3 * per + 250000)
		var t4 := tela._tique(4 * per + 5000)
		_esperar(t1 and not t2 and not t3 and t4,
			"calibração: o tique soa uma vez por batida e nunca fora dela (%s %s %s %s)" % [t1, t2, t3, t4])
		# o ✕ se mede contra o tique que se ouve: o som sai depois da latência de saída, como no Ritmo
		tela._latencia = 0.030
		_esperar(tela._ate_o_ouvido_us() >= 30000, "calibração: o tique ouvido conta a latência de saída (%d µs)" % tela._ate_o_ouvido_us())
	tela.free()
	# o tempo sobrevive a fechar e abrir (num arquivo da prova, nunca o da pessoa); e o que passa da borda volta para ela
	var arquivo := "user://opcoes-da-prova-h03.cfg"
	Opcoes.tempo_ms = [-150, 0, 80, 250]
	Opcoes.gravar(false, arquivo)
	Opcoes.tempo_ms = [0, 0, 0, 0]
	Opcoes.ler(arquivo)
	_esperar(Opcoes.tempo_ms == [-150, 0, 80, 250], "calibração: o tempo de cada lugar volta do arquivo (%s)" % [Opcoes.tempo_ms])
	var cfg := ConfigFile.new()
	cfg.set_value("P1", "tempo_ms", 9999)
	cfg.set_value("P2", "tempo_ms", -9999)
	cfg.save(arquivo)
	Opcoes.ler(arquivo)
	_esperar(Opcoes.tempo_ms[0] == Opcoes.TEMPO_MAX and Opcoes.tempo_ms[1] == Opcoes.TEMPO_MIN, "calibração: um arquivo fora da régua volta para as bordas (%s)" % [Opcoes.tempo_ms])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(arquivo))
	# o Ritmo começa com o que as opções guardam
	Opcoes.tempo_ms = [0, 30, 0, -20]
	Ritmo.ler_das_opcoes()
	_esperar(is_equal_approx(Ritmo.desvio[1], 0.030) and is_equal_approx(Ritmo.desvio[3], -0.020) and Ritmo.desvio[0] == 0.0,
		"calibração: o Ritmo lê o desvio de cada lugar das opções (%s)" % [Ritmo.desvio])
	for l in 4:
		Ritmo.definir_desvio(l, int(guardado[l]) / 1000.0, "opcoes")


## O Tempo pelas opções de verdade (H03): ▼ chega à linha Tempo, ▶ soma 10 ms,
## o ✕ de quem abriu deixa um ponto na régua e o de outro lugar não. Devolve
## tudo como achou.
func _prova_do_tempo_nas_opcoes() -> void:
	var antes := int(Opcoes.tempo_ms[1])
	jogo._abrir_overlay("opcoes", 1)
	await _quadros(2)
	var t: TelaOpcoes = jogo.tela_opcoes
	for k in 2:
		await _aperta(1, Forja.BAIXO)
	_esperar(jogo.overlay == "opcoes" and t._linhas[t.linha][0] == "tempo", "opções: ▼▼ chega à linha Tempo (%s)" % [t._linhas[t.linha]])
	await _aperta(1, Forja.DIREITA)
	_esperar(int(Opcoes.tempo_ms[1]) == antes + Opcoes.TEMPO_PASSO, "opções: ▶ na linha Tempo soma 10 ms (%d)" % Opcoes.tempo_ms[1])
	await _aperta(1, Forja.ESQUERDA)
	await _aperta(1, Forja.CRUZ)
	_esperar(t._toques.size() == 1, "opções: o ✕ de quem abriu deixa um ponto na régua (%d)" % t._toques.size())
	await _aperta(0, Forja.CRUZ)
	_esperar(t._toques.size() == 1, "opções: o ✕ de outro lugar não deixa ponto")
	jogo._fechar_overlay()
	await _quadros(2)
	_esperar(int(Opcoes.tempo_ms[1]) == antes and jogo.estado == "lobby", "opções: fechadas, o tempo volta ao que era e o lobby segue")


## As janelas (H02): as bordas de cada julgamento, a folga de quem está
## atrás, o desvio do lugar e a partitura mais simples. Pura: sem sala.
func _prova_das_janelas() -> void:
	var guardado: Array = Ritmo.desvio.duplicate()
	Ritmo.desvio = [0.0, 0.0, 0.0, 0.0]
	var P := Ritmo.PERFEITO
	var O := Ritmo.OTIMO
	var B := Ritmo.BOM
	var E := Ritmo.ERRO
	# [desvio do toque em s, folga, julgamento esperado]; o alvo em 10 s (o float de verdade)
	var casos := [
		[0.0, 0.0, P], [-0.040, 0.0, P], [0.060, 0.0, P],
		[-0.041, 0.0, O], [0.061, 0.0, O], [-0.090, 0.0, O], [0.090, 0.0, O],
		[-0.091, 0.0, B], [0.091, 0.0, B], [-0.140, 0.0, B], [0.140, 0.0, B],
		[-0.141, 0.0, E], [0.141, 0.0, E], [0.500, 0.0, E],
		[0.170, 0.040, B], [-0.180, 0.040, B], [0.181, 0.040, E],
		[0.061, 0.040, O], [0.041, 0.040, P],
	]
	for c in casos:
		var j := Ritmo.julgar(0, 10.0 + float(c[0]), 10.0, float(c[1]))
		_esperar(j == int(c[2]), "janela: %+.0f ms (folga %.0f) → %s (deu %s)" % [
			float(c[0]) * 1000.0, float(c[1]) * 1000.0, Ritmo.NOMES_DO_JULGAMENTO[int(c[2])], Ritmo.NOMES_DO_JULGAMENTO[j]])
	# o desvio do lugar sai do toque: +80 ms de calibração, 80 ms atrasado é perfeito
	Ritmo.desvio[2] = 0.080
	_esperar(Ritmo.julgar(2, 10.080, 10.0) == P, "janela: com +80 ms de desvio, 80 ms atrasado é perfeito")
	_esperar(Ritmo.julgar(2, 10.0, 10.0) == O, "janela: com +80 ms de desvio, o toque em cima é −80 ms (ótimo)")
	_esperar(Ritmo.julgar(1, 10.080, 10.0) == O, "janela: o desvio de um lugar não mexe no outro")
	_esperar(is_equal_approx(Ritmo.desvio_ms(2, 10.1, 10.0), 20.0), "janela: o desvio_ms já vem corrigido")
	# a folga de quem está atrás: só o último, sozinho
	_esperar(Ritmo.folga_para(3, [30, 20, 10, 0], [0, 1, 2, 3]) == Ritmo.FOLGA_DO_ULTIMO, "ajuda: o último sozinho ganha a folga")
	_esperar(Ritmo.folga_para(2, [30, 20, 10, 0], [0, 1, 2, 3]) == 0.0, "ajuda: o penúltimo não")
	_esperar(Ritmo.folga_para(3, [30, 0, 10, 0], [0, 1, 2, 3]) == 0.0, "ajuda: empate em último não")
	_esperar(Ritmo.folga_para(2, [30, 20, 10, 0], [0, 1, 2]) == Ritmo.FOLGA_DO_ULTIMO, "ajuda: só conta quem está presente")
	_esperar(Ritmo.folga_para(0, [0, 0, 0, 0], [0]) == 0.0, "ajuda: sozinho na sala, ninguém está atrás")
	# a partitura mais simples: três erros ligam, quatro acertos desligam
	Ritmo.zerar_ajuda()
	for k in 2:
		Ritmo.contar_para_ajuda(1, E)
	_esperar(not Ritmo.simples[1], "ajuda: dois erros ainda não simplificam")
	Ritmo.contar_para_ajuda(1, E)
	_esperar(Ritmo.simples[1] and not Ritmo.simples[0], "ajuda: o terceiro erro seguido simplifica só aquele lugar")
	for k in 3:
		Ritmo.contar_para_ajuda(1, B)
	_esperar(Ritmo.simples[1], "ajuda: três acertos ainda não devolvem")
	Ritmo.contar_para_ajuda(1, P)
	_esperar(not Ritmo.simples[1], "ajuda: o quarto acerto seguido devolve a partitura")
	Ritmo.zerar_ajuda()
	# o registro: um toque julgado e um perdido (a prova do relatório os procura)
	Ritmo.registrar_toque(0, 900, P, Ritmo.desvio_ms(0, 10.012, 10.0))
	Ritmo.registrar_toque(0, 901, E)
	Ritmo.desvio = guardado


## As faixas (H05): o caminho de cada tipo, o mapa lido do JSON, e cada faixa
## de exemplo — sem ela, a trilha sintetizada; com ela e o mapa conferido, a
## gerada, com o laço do tipo dela. Pura (não toca nada).
func _prova_das_faixas() -> void:
	_esperar(Musica.caminho("MUS_S01_J01") == "res://assets/ost/S01/MUS_S01_J01.ogg", "faixas: o caminho de uma faixa de minigame")
	_esperar(Musica.caminho("MUS_TELA_SALAO") == "res://assets/ost/telas/MUS_TELA_SALAO.ogg", "faixas: o caminho de uma tela")
	_esperar(Musica.caminho("MUS_RELAMPAGO") == "res://assets/ost/telas/MUS_RELAMPAGO.ogg", "faixas: o caminho do Relâmpago")
	_esperar(Musica.caminho("JIN_APITO") == "res://assets/ost/jingles/JIN_APITO.ogg", "faixas: o caminho de um jingle")
	var m := Musica.ler_mapa('{"slot": "MUS_S01_J01", "bpm": 122.0, "primeiro_tempo_s": 0.372, "compassos": 64, "secoes": [], "conferido": true}')
	_esperar(is_equal_approx(float(m.get("bpm", 0.0)), 122.0) and is_equal_approx(float(m.get("primeiro_tempo", 0.0)), 0.372) and bool(m.get("conferido", false)),
		"faixas: o mapa se lê (%s)" % [m])
	_esperar(Musica.ler_mapa('{"bpm": 0}').is_empty() and Musica.ler_mapa("não é json").is_empty(), "faixas: mapa ruim não vale")
	_esperar(not bool(Musica.ler_mapa('{"bpm": 120.0, "primeiro_tempo_s": 0.0}').get("conferido", true)), "faixas: sem «conferido», não conferido")
	_esperar(AudioServer.get_mix_rate() == 48000.0, "faixas: a mistura a 48 kHz (%d)" % AudioServer.get_mix_rate())
	for slot: String in ["MUS_S01_J01", "MUS_S02_J06", "MUS_TELA_SALAO"]:
		if not ResourceLoader.exists(Musica.caminho(slot)):
			# sem a faixa na pasta (a nuvem nunca tem), a sintetizada da seção
			if slot.begins_with("MUS_S"):
				_esperar(Musica.mapa_gerado(slot).is_empty() and bool(Musica.mapa(slot).get("sintetizada", false)) == Forja.modulo,
					"faixas: sem a faixa %s, a trilha sintetizada" % slot)
			continue
		var g := Musica.mapa_gerado(slot)
		_esperar(not g.is_empty() and not bool(Musica.mapa(slot).get("sintetizada", true)),
			"faixas: %s, com o mapa conferido, no lugar da sintetizada (%s)" % [slot, g])
		var s := Musica._ogg(slot)
		var volta: bool = not String(slot).begins_with("MUS_S")
		_esperar(s != null and s.loop == volta and is_zero_approx(s.loop_offset),
			"faixas: %s com o laço do tipo dela (volta: %s)" % [slot, volta])


## A sala está num estado de pergunta às cegas, ou desenha uma? Só a bancada deixa.
func _em_pergunta(sala) -> bool:
	for l in 4:
		if not sala.pergunta(l).is_empty():
			return true
	match sala.id:
		"galeria":
			for l in sala.j:
				if int(sala.j[l].passo) in [SalaGaleria.IDENTIFICAR, SalaGaleria.MUNICAO, SalaGaleria.MUNICAO_RESP]:
					return true
		"impacto":
			return sala.estado in [SalaImpacto.PERGUNTA, SalaImpacto.RESPOSTA]
		"canto":
			return sala.estado == SalaCanto.PERGUNTA
		"caminhos":
			for l in sala.j:
				if int(sala.j[l].estado) == SalaCaminhos.PERGUNTA:
					return true
		"voz":
			return sala.estado == SalaVoz.LUZ
		"prova":
			return sala.etapa in [SalaProva.LEDS, SalaProva.COR]
	return false


## As linhas da linha do tempo desta sessão, na ordem (as fichas seguintes usam também).
func _linha_do_tempo() -> Array:
	var linhas: Array = []
	if pasta == "":
		return linhas
	for f in DirAccess.get_files_at(pasta):
		if f.begins_with("linha-do-tempo-") and f.ends_with(".jsonl"):
			for s in FileAccess.get_file_as_string(pasta.path_join(f)).split("\n", false):
				var e = JSON.parse_string(s)
				if e is Dictionary:
					linhas.append(e)
	return linhas


func _scripts(pasta: String) -> Array:
	var lista: Array = []
	for f in DirAccess.get_files_at(pasta):
		if f.ends_with(".gd"):
			lista.append(pasta.path_join(f))
	for d in DirAccess.get_directories_at(pasta):
		lista.append_array(_scripts(pasta.path_join(d)))
	return lista


## Toda vibração passa pela tabela de sensações (13): Forja.vibrar só no forja.gd,
## e nenhum outro dono do motor (o start_joy_vibration do Godot, o ctl.intensidade).
func _prova_das_sensacoes() -> void:
	var achados: Array = []
	for arq in _scripts("res://scripts"):
		var n := 0
		for linha in FileAccess.get_file_as_string(arq).split("\n"):
			n += 1
			var codigo: String = linha.split("#")[0]
			var vibra_fora: bool = (codigo.contains("Forja.vibrar(") or codigo.contains("ctl.vibrar(")) and not arq.ends_with("/forja.gd")
			# a força solta (F10) é exceção declarada: só o experimento `forca` da bancada a pede
			var forca_fora: bool = codigo.contains("sentir_forca(") and not arq.ends_with("/forja.gd") and not arq.ends_with("/bancada.gd")
			if vibra_fora or forca_fora or codigo.contains("start_joy_vibration") or codigo.contains(".intensidade("):
				achados.append("%s:%d" % [arq.get_file(), n])
	_esperar(achados.is_empty(), "nenhuma vibração fora da tabela de sensações (%s)" % [achados])
	var piso := {"toque": [0.0, 0.45, 60], "acerto": [0.3, 0.6, 80], "perfeito": [0.5, 0.8, 100],
		"erro": [0.7, 0.3, 160], "golpe": [1.0, 0.6, 250], "explosao": [1.0, 1.0, 400], "aviso": [0.6, 0.0, 200]}
	for nome in piso:
		_esperar(Forja.SENSACOES.get(nome, []) == piso[nome], "a sensação «%s» é a do piso de 05" % nome)
	# toda vibração que saiu na sessão é uma sensação da tabela (e as opções de fábrica: escala 1)
	var permitidos := {}
	for nome in Forja.SENSACOES:
		var s: Array = Forja.SENSACOES[nome]
		permitidos["%.2f/%.2f" % [s[0], s[1]]] = true
	var fora: Array = []
	var sensacoes := 0
	for e in _linha_do_tempo():
		if e.get("tipo") == "sensacao":
			sensacoes += 1
		if e.get("tipo") == "saida" and e.get("o") == "vibracao" and float(e.get("forte", 0.0)) + float(e.get("fraco", 0.0)) > 0.0:
			var k := "%.2f/%.2f" % [float(e.get("forte", 0.0)), float(e.get("fraco", 0.0))]
			if not permitidos.has(k):
				fora.append(k)
	_esperar(sensacoes > 20 and fora.is_empty(), "toda vibração da sessão veio da tabela (%d sensações; fora: %s)" % [sensacoes, fora.slice(0, 5)])
	var opcoes := _linha_do_tempo().filter(func(e): return e.get("tipo") == "sessao" and e.get("evento") == "opcoes")
	_esperar(not opcoes.is_empty(), "a linha do tempo tem a escala de vibração de cada lugar")
	var conexoes := _linha_do_tempo().filter(func(e): return e.get("tipo") == "conexao" and e.get("evento") == "conectou")
	_esperar(conexoes.size() >= 4 and conexoes.all(func(e): return str(e.get("firmware", "")).begins_with("0x") and e.has("rumble_escala_cheia")),
		"toda conexão registra o firmware e o rumble inteiro ou pela metade")


## O motor vence: com o lugar vibrando, a háptica por áudio dele espera.
func _prova_do_motor_que_vence() -> void:
	jogo._entrar_na_sala("caminhos", false)
	await _quadros(2)
	_esperar(Forja.som_tem(0, Forja.PAPEL_HAPTICA), "Caminhos: o P1 tem a háptica (a placa virtual)")
	Forja.sentir(0, "golpe")
	_esperar(Forja.som_haptica(0, "pulso", "pulso") == -1, "com o motor do P1 vibrando, a háptica dele não toca")
	await _quadros(20)
	_esperar(Forja.som_haptica(0, "pulso", "pulso") != -1, "o motor parou: a háptica volta")
	jogo.sala.terminar()
	var q := 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5


## O lugar nasce na conexão (F04): a linha do tempo diz que os quatro reservaram P1..P4, na ordem.
func _prova_da_identidade() -> void:
	var reservas := _linha_do_tempo().filter(func(e): return e.get("tipo") == "conexao" and e.get("evento") == "reservou")
	_esperar(reservas.size() >= 4 and reservas.slice(0, 4).map(func(e): return int(e.get("lugar", -1))) == [0, 1, 2, 3],
		"linha do tempo: os quatro reservaram P1..P4 na conexão, na ordem")


## O Modo bancada, pelo registro: a linha do tempo diz o modo, e só na bancada
## as salas às cegas perguntam.
func _prova_do_modo() -> void:
	var linhas := _linha_do_tempo()
	var modo := linhas.filter(func(e): return e.get("tipo") == "sessao" and e.get("evento") == "modo")
	_esperar(modo.size() == 1 and bool(modo[0].get("bancada", false)) == Forja.bancada,
		"a linha do tempo diz o modo (bancada: %s)" % Forja.bancada)
	var perguntas := linhas.filter(func(e): return e.get("o") == "pergunta")
	if Forja.bancada:
		for id in ["galeria", "impacto", "canto", "caminhos", "voz", "prova"]:
			_esperar(perguntas.any(func(e): return e.get("sala") == id), "bancada: %s perguntou às cegas" % id)
	else:
		_esperar(perguntas.is_empty(), "jogo: nenhuma pergunta sobre o controle (%d)" % perguntas.size())
	# a linha do tempo tem o tipo `minigame`: cada sala começou e terminou com vencedor
	var mg := linhas.filter(func(e): return e.get("tipo") == "minigame")
	for id in ["centelha", "viga", "molde", "impacto", "galeria", "canto", "caminhos", "voz", "prova"]:
		var c := mg.filter(func(e): return Catalogo.apelido(str(e.get("slot"))) == id and e.get("evento") == "comecou").size()
		var t := mg.filter(func(e): return Catalogo.apelido(str(e.get("slot"))) == id and e.get("evento") == "terminou" and int(e.get("vencedor", -1)) >= 0).size()
		_esperar(c >= 1 and t >= 1, "linha do tempo: %s começou e terminou com vencedor" % id)
		# vencer é fazer ponto: a sala em que ninguém soma (A Voz sem a pergunta,
		# com o treino engolindo o chamado e o mudo) acaba sempre em zero a zero
		var somou := mg.any(func(e):
			var pts = JSON.parse_string(str(e.get("pontos", "[]")))
			return Catalogo.apelido(str(e.get("slot"))) == id and e.get("evento") == "terminou" and pts is Array \
				and pts.any(func(v): return int(v) > 0))
		_esperar(somou, "linha do tempo: em %s alguém fez ponto" % id)


## O aviso não espera ninguém para sempre: sem ✕ de ninguém, começa em 8 s.
func _prova_do_aviso_sozinho() -> void:
	# um robô que simplesmente não aperta: nenhum lugar fica pronto no aviso
	Forja.robo_confirma = false
	jogo._entrar_na_sala("centelha", false)
	await _quadros(2)
	var sala = jogo.sala
	var q := 0
	await _passar_a_entrada(sala)
	while is_instance_valid(sala) and sala.fase == "aviso" and q < 900:
		await _quadros(1)
		q += 1
	_esperar(is_instance_valid(sala) and sala.fase == "jogo" and q >= int(SalaJogo.AVISO_MAX * 60) - 2,
		"o aviso começa sozinho em 8 s (%d quadros)" % q)
	Forja.robo_confirma = true
	sala.terminar()
	q = 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5


## O que nunca aparece na tela do jogador (06, a voz do texto; as regras de ouro).
const PROIBIDAS := "(?i)\\b(olhe|relatórios?|veredito|módulo|vid|hidraw|uinput|mac|mesa|vibração|giroscópio|acelerômetro|háptica|barra de luz|luzinhas?|alto-falante|gatilhos? adaptativos?|não medido)\\b|saiu d[oa] s(eu|ua)|\\b[0-9a-f]{4}:[0-9a-f]{4}\\b|só a entrada|\\bleds?\\b"


## Tudo o que o jogo desenhou até aqui (as telas, as salas e as placas do salão)
## não fala do controle como prova. A bancada mostra o que o jogador não vê.
## O nome de um ajuste nas Opções pode dizer a parte do controle, como em todo
## jogo de console: a régua da F02 vale para as telas do jogo, não para o ajuste.
const PERMITIDAS_NAS_OPCOES := ["Vibração"]


func _prova_das_frases() -> void:
	if Forja.bancada:
		return
	var r := RegEx.create_from_string(PROIBIDAS)
	var achadas: Array = []
	for s in Desenho._coletados:
		if r.search(str(s)) != null and not str(s) in PERMITIDAS_NAS_OPCOES:
			achadas.append(s)
	_esperar(Desenho._coletados.size() > 50, "as frases da tela foram colhidas (%d)" % Desenho._coletados.size())
	_esperar(achadas.is_empty(), "jogo: nenhuma frase fala do controle como prova (%s)" % [achadas])


## A primeira letra de uma frase de tela é maiúscula; número no começo vale (F07).
static func _comeca_com_maiuscula(s: String) -> bool:
	for i in s.length():
		var c := s.substr(i, 1)
		if c >= "0" and c <= "9":
			return true
		if c.to_upper() != c.to_lower():  # é letra
			return c == c.to_upper()
	return true  # só símbolos


func _prova_das_maiusculas() -> void:
	if Forja.bancada:
		return  # o texto do núcleo (os vereditos) fica como está
	var achadas: Array = []
	for s in Desenho._coletados:
		if not _comeca_com_maiuscula(str(s)):
			achadas.append(s)
	_esperar(achadas.is_empty(), "jogo: toda frase de tela começa com maiúscula (%d: %s)" % [achadas.size(), achadas.slice(0, 60)])
	_esperar(Desenho._coletados.has("Botão"), "as dicas de botão dizem \"Botão\"")


## O registro v2 (F06): o relógio de parede, o lugar em toda linha, o seq em toda saída,
## o transporte na conexão e as listas do GDScript como listas JSON.
func _prova_do_registro_v2() -> void:
	var linhas := _linha_do_tempo()
	_esperar(not linhas.is_empty() and linhas[0].get("formato") == "hefesto-tech-demo/linha-do-tempo/2"
		and linhas[0].get("relogio") == "parede", "a linha do tempo é a v2, no relógio de parede")
	var t_antes := -1.0
	var t_ok := true
	var lugar_ok := true
	var seq := {}
	var seq_ok := true
	var saidas := 0
	for e in linhas:
		var t := float(e.get("t", -1.0))
		t_ok = t_ok and t >= t_antes
		t_antes = t
		if int(e.get("jogador", 0)) > 0:
			lugar_ok = lugar_ok and int(e.get("lugar", -1)) == int(e.get("jogador")) - 1
		# o seq é um contador só por lugar: a saída e o som mandado ao controle (H07) saem numa ordem
		if e.get("tipo") == "saida" or e.get("tipo") == "som_controle":
			saidas += 1 if e.get("tipo") == "saida" else 0
			var chave := int(e.get("lugar", -1))
			var n := int(e.get("seq", 0))
			seq_ok = seq_ok and n == int(seq.get(chave, 0)) + 1
			seq[chave] = n
	var processo := Time.get_ticks_msec() / 1000.0
	_esperar(t_ok, "o t nunca anda para trás")
	_esperar(t_antes <= processo + 0.5, "o t é o relógio de parede (%.1f s na linha, %.1f s de processo)" % [t_antes, processo])
	_esperar(lugar_ok, "toda linha com jogador tem o lugar (jogador - 1)")
	_esperar(saidas > 100 and seq_ok, "toda saída e todo som no controle têm seq, de 1 em 1 por lugar (%d saídas)" % saidas)
	var con := linhas.filter(func(e): return e.get("tipo") == "conexao" and e.get("evento") == "conectou")
	var con_ok := con.size() >= 4
	for e in con:
		con_ok = con_ok and e.get("transporte") == "virtual" and str(e.get("firmware", "")).begins_with("0x") and e.has("vid_pid")
	_esperar(con_ok, "a conexão diz o transporte (virtual, no simulado), o firmware e o VID:PID")
	var fim := linhas.filter(func(e): return e.get("tipo") == "minigame" and e.get("evento") == "terminou")
	_esperar(not fim.is_empty() and fim.all(func(e): return e.get("pontos") is Array),
		"os pontos do minigame são um array JSON de verdade")
	# nota e toque (o Ritmo) trazem o t_musica deles como campo; a cabeça só o ganha de Forja.t_musica
	_esperar(not linhas.any(func(e): return e.has("t_musica") and not e.get("tipo") in ["nota", "toque", "momento"]),
		"sem música informada, nenhuma linha tem t_musica na cabeça")
	# a sonda: listas de inteiros, de números e de textos, um NaN, e a posição da música
	Forja.t_musica(12.5)
	Forja.evento("sonda", 2, {"inteiros": [1, 2, 3], "reais": [0.5, 1.5], "textos": ["a", "b"], "misto": [1, "a"], "nao_numero": NAN})
	Forja.t_musica(-1.0)
	Forja.evento("sonda", 0, {"fim": true})
	var sondas := _linha_do_tempo().filter(func(e): return e.get("tipo") == "sonda")
	_esperar(sondas.size() == 2, "as duas linhas da sonda são JSON de verdade (%d lidas)" % sondas.size())
	if sondas.size() == 2:
		var a: Dictionary = sondas[0]
		_esperar(a.get("inteiros") is Array and a.inteiros == [1.0, 2.0, 3.0] and a.get("reais") == [0.5, 1.5]
			and a.get("textos") == ["a", "b"], "as listas do GDScript saem como listas JSON")
		_esperar(a.get("misto") is String and a.get("nao_numero") == null and a.has("nao_numero"),
			"a lista mista segue texto e o NaN vira null")
		_esperar(is_equal_approx(float(a.get("t_musica", -1.0)), 12.5) and int(a.get("lugar", -1)) == 1,
			"com a música informada a linha leva t_musica, e o lugar vem com o jogador")
		_esperar(not (sondas[1] as Dictionary).has("t_musica"), "sem a música (-1) a linha volta a não ter t_musica")
	# a cabeça vence: um campo com o nome de uma chave da cabeça não entra de novo (JSON com chave
	# repetida quebra leitor estrito, e o Ritmo e a reserva mandam lugar como campo)
	Forja.t_musica(3.0)
	Forja.evento("sonda", 3, {"lugar": 9, "jogador": 9, "t_musica": 99.0, "tipo": "outro", "dupla": true})
	Forja.t_musica(-1.0)
	var repetidas := 0
	var cruas := 0
	for f in DirAccess.get_files_at(pasta):
		if f.begins_with("linha-do-tempo-") and f.ends_with(".jsonl"):
			for s in FileAccess.get_file_as_string(pasta.path_join(f)).split("\n", false):
				cruas += 1
				for chave in ["\"t\": ", "\"tipo\": ", "\"jogador\": ", "\"lugar\": ", "\"t_musica\": "]:
					if s.count(chave) > 1:
						repetidas += 1
	_esperar(cruas > 100 and repetidas == 0, "nenhuma linha repete chave da cabeça (%d repetidas em %d linhas)" % [repetidas, cruas])
	var dupla := _linha_do_tempo().filter(func(e): return e.get("tipo") == "sonda" and e.get("dupla") == true)
	_esperar(dupla.size() == 1 and int(dupla[0].get("lugar", -1)) == 2 and int(dupla[0].get("jogador", -1)) == 3
		and is_equal_approx(float(dupla[0].get("t_musica", -1.0)), 3.0),
		"o campo repetido cede à cabeça: lugar 2, jogador 3 e t_musica 3")


## A paridade (F08): `Forja.robo` só aparece no gancho do robô. Nenhum script do
## jogo sabe que é um robô fora de `forja.gd`, de uma linha `if Forja.robo:` (o
## gancho, que chama o robô da sala ou da tela) e das funções `_robo*`/`robo*`.
## O resto é atalho: a prova passaria por um caminho que ninguém joga.
## O único aceito de fora é `Opcoes.gravar(Forja.robo)` (não sujar o opcoes.cfg).
const ROBO_PERMITIDO_FORA := {"main.gd": ["Opcoes.gravar(Forja.robo)"]}


func _prova_da_paridade() -> void:
	var arquivos := _scripts_do_jogo("res://scripts")
	_esperar(arquivos.size() > 40, "paridade: os scripts do jogo foram lidos (%d)" % arquivos.size())
	var achados: Array = []
	for caminho in arquivos:
		if caminho.get_file() == "forja.gd":
			continue
		var f := FileAccess.open(caminho, FileAccess.READ)
		achados.append_array(atalhos_do_robo(f.get_as_text(), caminho.get_file()))
	_esperar(achados.is_empty(), "paridade: nenhum atalho do robô no código do jogo (%s)" % [achados])
	# a régua morde: um atalho plantado de propósito reprova, o gancho passa
	var plantado := "func _quadro_aviso() -> void:\n\tif Forja.apertou(0, 0) or (Forja.robo and t_fase > 1.4):\n\t\tpass\n"
	_esperar(atalhos_do_robo(plantado, "plantado.gd").size() == 1, "paridade: a régua reprova um atalho plantado")
	var gancho := "func jogar(dt):\n\tif Forja.robo:\n\t\t_robo(dt)\nfunc _robo_do_aviso():\n\tif not Forja.robo:\n\t\treturn\n"
	_esperar(atalhos_do_robo(gancho, "gancho.gd").is_empty(), "paridade: a régua aceita o gancho e as funções do robô")
	# o atalho escondido DENTRO do gancho também reprova: o corpo do `if Forja.robo:`
	# só chama o robô (o fechamento sozinho da bancada era assim)
	var escondido := "func _process(dt):\n\tif Forja.robo:\n\t\t_te += dt\n\t\tif _te > 2.0:\n\t\t\tget_tree().quit()\n"
	_esperar(atalhos_do_robo(escondido, "escondido.gd").size() == 2, "paridade: a régua reprova o atalho dentro do gancho (%s)" % [atalhos_do_robo(escondido, "escondido.gd")])
	var gancho_com_laco := "func jogar(dt):\n\tif Forja.robo:\n\t\tfor p in jogadores:\n\t\t\tvar l: int = p.lugar\n\t\t\tif _conectado(l):\n\t\t\t\t_robo(l, dt)\n\t_jogar(dt)\n"
	_esperar(atalhos_do_robo(gancho_com_laco, "laco.gd").is_empty(), "paridade: a régua aceita o gancho que percorre os lugares")
	var depois := "func _robo_x():\n\tpass\nvar pronto = Forja.robo\n"
	_esperar(atalhos_do_robo(depois, "depois.gd").size() == 1, "paridade: a linha de fora de função, depois de uma função do robô, não herda a licença")
	var comentario := "# Forja.robo fica no gancho\nvar a := 1  # e Forja.robo aqui é só prosa\n"
	_esperar(atalhos_do_robo(comentario, "prosa.gd").is_empty(), "paridade: a régua ignora comentário")


func _scripts_do_jogo(pasta_res: String) -> Array:
	var achados: Array = []
	for d in DirAccess.get_directories_at(pasta_res):
		achados.append_array(_scripts_do_jogo(pasta_res.path_join(d)))
	for a in DirAccess.get_files_at(pasta_res):
		if a.ends_with(".gd"):
			achados.append(pasta_res.path_join(a))
	return achados


## As linhas de um script que usam `Forja.robo` fora do que a paridade aceita.
static func atalhos_do_robo(texto: String, arquivo: String) -> Array:
	var r := RegEx.create_from_string("Forja\\.robo(?![\\w])")
	var funcao := RegEx.create_from_string("^\\s*(?:static\\s+)?func\\s+(\\w+)")
	var atual := ""
	var achados: Array = []
	var n := 0
	var gancho := -1  ## a indentação do `if Forja.robo:` aberto; -1: fora de um gancho
	for linha in texto.split("\n"):
		n += 1
		var m := funcao.search(linha)
		if m != null:
			atual = m.get_string(1)
		var codigo := _sem_comentario(linha).strip_edges()
		if codigo == "":
			continue
		var recuo := _recuo(linha)
		if recuo == 0 and m == null:
			atual = ""  # uma linha da classe, fora de qualquer função
		if gancho >= 0 and recuo <= gancho:
			gancho = -1
		if gancho >= 0 and not atual.begins_with("_robo") and not atual.begins_with("robo") \
				and not _linha_do_gancho(codigo):
			achados.append("%s:%d %s (dentro do gancho do robô)" % [arquivo, n, codigo])
			continue
		if r.search(codigo) == null:
			continue
		if codigo == "if Forja.robo:":
			gancho = recuo
			continue
		if atual.begins_with("_robo") or atual.begins_with("robo"):
			continue
		if codigo in ROBO_PERMITIDO_FORA.get(arquivo, []):
			continue
		achados.append("%s:%d %s" % [arquivo, n, codigo])
	return achados


## O que cabe no corpo do gancho `if Forja.robo:`: percorrer os lugares e chamar
## o robô (`_robo*`, `robo*`, `Forja.robo_*`), guardar o que o robô sentiu
## (`_robo...`), ler numa variável local e decidir. Mudar o jogo ali (somar um
## relógio, fechar a sala, emitir um sinal) é atalho.
static func _linha_do_gancho(codigo: String) -> bool:
	for inicio in ["for ", "if ", "elif ", "else:", "while ", "var ", "return", "continue", "break", "pass"]:
		if codigo.begins_with(inicio):
			return true
	if codigo.begins_with("_robo"):
		return true
	return RegEx.create_from_string("^(?:Forja\\.)?_?robo\\w*\\(").search(codigo) != null


static func _recuo(linha: String) -> int:
	var n := 0
	for c in linha:
		if c == "\t":
			n += 4
		elif c == " ":
			n += 1
		else:
			break
	return n


## A linha sem o comentário `#` (que não esteja dentro de um texto entre aspas).
static func _sem_comentario(linha: String) -> String:
	var aspas := ""
	for i in linha.length():
		var c := linha[i]
		if aspas != "":
			if c == aspas and (i == 0 or linha[i - 1] != "\\"):
				aspas = ""
		elif c == "\"" or c == "'":
			aspas = c
		elif c == "#":
			return linha.substr(0, i)
	return linha


## Os jingles (H06): qual toca no resultado, e cada um tem som (com o módulo,
## a síntese e as gravações da Kenney). Pura: não abre sala.
func _prova_dos_jingles() -> void:
	var todos := [0, 1, 2, 3]
	_esperar(Som.jingle_do_resultado([10, 5, 3, 0], todos, false, false) == "JIN_VITORIA", "jingle: um vencedor, a vitória")
	_esperar(Som.jingle_do_resultado([10, 10, 3, 0], todos, false, false) == "JIN_EMPATE", "jingle: empate em primeiro, o empate")
	_esperar(Som.jingle_do_resultado([10, 10, 3, 0], [0, 2], false, false) == "JIN_VITORIA", "jingle: só conta quem jogou")
	_esperar(Som.jingle_do_resultado([0, 0, 0, 0], [0], false, false) == "JIN_VITORIA", "jingle: sozinho, a vitória")
	_esperar(Som.jingle_do_resultado([5, 5, 5, 5], todos, true, true) == "JIN_COOP_VITORIA", "jingle: coop, todos venceram")
	_esperar(Som.jingle_do_resultado([5, 5, 5, 5], todos, true, false) == "JIN_DERROTA", "jingle: coop, ninguém venceu")
	if Forja.modulo:
		for nome in Som.JINGLES:
			_esperar(Som.jingle(nome) > 0.0 and Som.ultimo_jingle == nome, "jingle: %s tem som" % nome)


## A música que reage (H07): o erro abafa e abre, o perfeito abaixa e volta.
## Os tweens andam no tempo do jogo: a espera é em quadros.
func _prova_da_musica_que_reage() -> void:
	Musica.reagir("erro")
	_esperar(Musica._passa_baixa.cutoff_hz < 1000.0, "música: o erro abafa (%.0f Hz)" % Musica._passa_baixa.cutoff_hz)
	await _quadros(40)
	_esperar(is_equal_approx(Musica._passa_baixa.cutoff_hz, Musica.ABERTO_HZ), "música: e abre de novo")
	Musica.reagir("perfeito")
	_esperar(is_equal_approx(AudioServer.get_bus_volume_db(Musica._bus), -2.0), "música: o perfeito abaixa 2 dB")
	await _quadros(12)
	_esperar(is_equal_approx(AudioServer.get_bus_volume_db(Musica._bus), 0.0), "música: e volta")
	Musica.reagir("combo")
	_esperar(is_equal_approx(AudioServer.get_bus_volume_db(Musica._bus), 1.5), "música: o combo sobe 1,5 dB")
	await _quadros(150)
	_esperar(is_equal_approx(AudioServer.get_bus_volume_db(Musica._bus), 0.0), "música: e desce de novo")


## Todo som de assets/sons é PCM de 16 bits (compress/mode=0 no .import): o
## alto-falante do controle recebe `w.data` como PCM16 (Som.no_controle), e um
## arquivo comprimido sai ali como ruído. O medidor do falante não distingue
## PCM de dado comprimido; esta conta é a que distingue (G02).
func _prova_dos_sons_em_pcm() -> void:
	var dir := DirAccess.open("res://assets/sons")
	_esperar(dir != null, "sons: a pasta assets/sons abre")
	if dir == null:
		return
	var vistos := 0
	for f in dir.get_files():
		if not f.ends_with(".wav.import"):
			continue
		var id := f.trim_suffix(".wav.import")
		var w := Som.arquivo(id)
		vistos += 1
		_esperar(w != null and w.format == AudioStreamWAV.FORMAT_16_BITS,
			"sons: %s.wav carrega em PCM de 16 bits (formato %s)" % [id, str(w.format) if w != null else "nenhum"])
	_esperar(vistos > 0, "sons: a pasta tem sons para conferir (%d)" % vistos)


## As contas dos seis itens, sem sala (como as da partida), com e sem liga (G03).
func _prova_das_contas_dos_itens() -> void:
	var antes: Array = Itens.escolhido.duplicate()
	var liga_antes: Array = Itens.em_liga.duplicate()
	Itens.em_liga = [false, false, false, false]
	Itens.escolhido = [Itens.MARTELO, Itens.ESCUDO, Itens.FOLE, Itens.LANTERNA]
	_esperar(Itens.pontos_do_acerto(0, 100, Itens.PERFEITO, true) == 200, "Martelo: o perfeito no tempo forte vale o dobro")
	_esperar(Itens.pontos_do_acerto(0, 100, Itens.PERFEITO, false) == 85, "Martelo: fora do tempo forte, 85%")
	_esperar(Itens.pontos_do_acerto(1, 100, Itens.PERFEITO, true) == 100, "sem Martelo, os pontos não mudam")
	Itens.novo_minigame()
	_esperar(Itens.absorve_erro(1) and not Itens.absorve_erro(1), "Escudo: absorve o primeiro erro, só ele")
	_esperar(not Itens.escudo_inteiro(1), "Escudo: quebrou")
	Itens.novo_minigame()
	_esperar(Itens.escudo_inteiro(1), "Escudo: inteiro de novo no minigame seguinte")
	_esperar(Itens.combo_inicial(1, 3) == 0, "Escudo: começa com o combo em 0")
	_esperar(not Itens.absorve_erro(0), "sem Escudo, nada se absorve")
	_esperar(Itens.acertos_para_voltar_o_combo(2, 10) == 5 and Itens.combo_maximo(2, 20) == 15, "Fole: volta na metade, teto de 3/4")
	_esperar(is_equal_approx(Itens.antecipacao_s(3, 120.0), 0.25), "Lanterna: meio tempo antes")
	_esperar(Itens.janela_perfeito(3, Vector2(-0.040, 0.060)).is_equal_approx(Vector2(-0.035, 0.055)), "Lanterna: o perfeito encolhe 10 ms")
	Itens.em_liga = [true, true, true, true]
	_esperar(Itens.pontos_do_acerto(0, 100, Itens.PERFEITO, false) == 100, "Martelo em liga: fora do tempo forte, 100%")
	_esperar(Itens.combo_inicial(1, 3) == 3, "Escudo em liga: começa com o bônus")
	_esperar(Itens.combo_maximo(2, 20) == 20, "Fole em liga: o combo máximo é o normal")
	_esperar(Itens.janela_perfeito(3, Vector2(-0.040, 0.060)).is_equal_approx(Vector2(-0.040, 0.060)), "Lanterna em liga: não encolhe")
	Itens.em_liga = [false, false, false, false]
	Itens.escolhido = [Itens.DIAPASAO, Itens.ANCORA, Itens.NENHUM, Itens.NENHUM]
	_esperar(is_equal_approx(Itens.ganho_da_nota(0, "coop"), 1.3) and is_equal_approx(Itens.ganho_da_nota(0, "tct"), 1.0), "Diapasão: nada no todos contra todos")
	_esperar(Itens.puxa_o_combo_da_equipe(0, "2v2") and not Itens.puxa_o_combo_da_equipe(0, "tct"), "Diapasão: puxa o combo só em equipe")
	_esperar(is_equal_approx(Itens.resiste_a_empurrao(1), 0.5) and is_equal_approx(Itens.velocidade(1, "corrida"), 0.9), "Âncora: resiste e anda mais devagar")
	Itens.em_liga = [true, true, false, false]
	_esperar(is_equal_approx(Itens.ganho_da_nota(0, "tct"), 1.3), "Diapasão em liga: a nota mais alta no todos contra todos")
	_esperar(is_equal_approx(Itens.velocidade(1, "corrida"), 1.0), "Âncora em liga: a velocidade normal")
	for c in [Itens.METAL, Itens.CERAMICA, Itens.LATAO]:
		var v := Pintura.para_oklab(c)
		_esperar(v.x >= 0.68 and v.x <= 0.80 and Vector2(v.y, v.z).length() <= 0.0805, "o tom %s na faixa do item" % c.to_html(false))
		for j in Tema.JOGADOR:
			_esperar(Pintura.delta_e(c, j) >= 0.08, "o tom %s longe do néon %s" % [c.to_html(false), j.to_html(false)])
	Itens.escolhido = antes
	Itens.em_liga = liga_antes
	Itens.novo_minigame()


## A peça se distingue (arte/04): as faixas de L, o croma, a distância até os
## néons e a área do acento.
func _prova_da_peca() -> void:
	for p in jogo.jogadores:
		var m: Dictionary = Pintura.medianas(p.modelo)
		_esperar(m.superior >= 0.46 and m.superior <= 0.58, "P%d: o superior na faixa (%.3f)" % [p.lugar + 1, m.superior])
		_esperar(m.inferior >= 0.22 and m.inferior <= 0.36, "P%d: o inferior na faixa (%.3f)" % [p.lugar + 1, m.inferior])
		_esperar(m.superior - m.inferior >= 0.10, "P%d: superior e inferior diferem 0,10 (%.3f)" % [p.lugar + 1, m.superior - m.inferior])
		var ruins := []
		for c in m.cores:
			var v := Pintura.para_oklab(c)
			if Vector2(v.y, v.z).length() > 0.1001:
				ruins.append("croma %s" % c.to_html(false))
			for j in Tema.JOGADOR:
				if Pintura.delta_e(c, j) < 0.08:
					ruins.append("perto do néon %s" % c.to_html(false))
		_esperar(ruins.is_empty(), "P%d: a peça nunca é néon %s" % [p.lugar + 1, ruins])
		var mat: ShaderMaterial = p._mats_corpo[0]
		var area: float = 2.0 * float(mat.get_shader_parameter("friso_alto")) * p._medidas.largura_torso \
			+ 2.0 * float(mat.get_shader_parameter("costura_larg")) * p._medidas.altura_perna
		_esperar(area <= 0.0801 * (p._medidas.frente_cima + p._medidas.frente_baixo), "P%d: o acento em até 8 %% da frente" % (p.lugar + 1))
		# o aro: o valor que o material leva; sem valor escrito, vale o padrão do shader
		var aro = mat.get_shader_parameter("aro")
		_esperar(is_equal_approx(float(aro), 0.25) if aro != null else mat.shader.code.contains("uniform float aro = 0.25;"),
			"P%d: o aro a 0,25" % (p.lugar + 1))
		_esperar(not mat.shader.code.contains("tingir"), "P%d: nada se tinge" % (p.lugar + 1))
		p.acender(0.0)
		_esperar(is_zero_approx(float(mat.get_shader_parameter("acesa"))), "P%d: acender(0) apaga a armadura" % (p.lugar + 1))
		p.acender(1.0)
		_esperar(is_equal_approx(float(mat.get_shader_parameter("acesa")), 1.0), "P%d: acender(1) volta" % (p.lugar + 1))
		var cont: ShaderMaterial = mat.next_pass
		_esperar(is_equal_approx(float(cont.get_shader_parameter("energia")), 1.6), "P%d: o contorno a 1,6 na montagem" % (p.lugar + 1))


## O checklist que se confere sem olho: nada liso, nada metálico.
func _confere_a_arte(raiz: Node, onde: String) -> void:
	var lisas: Array = []
	var metalicos: Array = []
	for n in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var m := mi.mesh
		if (m is SphereMesh and (m as SphereMesh).radial_segments > 8) \
				or (m is TorusMesh and (m as TorusMesh).rings > 8) \
				or (m is CylinderMesh and (m as CylinderMesh).radial_segments > 8):
			lisas.append(str(raiz.get_path_to(mi)))
		var mat := mi.material_override
		if mat is StandardMaterial3D and (mat as StandardMaterial3D).metallic > 0.2001:   # 0,2 em float de 32 bits passa de 0,2
			metalicos.append(str(raiz.get_path_to(mi)))
	for n in raiz.find_children("*", "CSGCylinder3D", true, false):
		if (n as CSGCylinder3D).sides > 8:
			lisas.append(str(raiz.get_path_to(n)))
	for n in raiz.find_children("*", "CSGTorus3D", true, false):
		if (n as CSGTorus3D).sides > 8:
			lisas.append(str(raiz.get_path_to(n)))
	_esperar(lisas.is_empty(), "%s: nenhuma curva lisa %s" % [onde, lisas])
	_esperar(metalicos.is_empty(), "%s: nada metálico acima de 0,2 %s" % [onde, metalicos])


# ----------------------------------------------------------- o teclado do nome --

## As contas do teclado (G09), sem tela nem controle.
func _prova_do_teclado() -> void:
	var t := TecladoDoNome.new()
	_esperar(t.formatar("DONA BRASA") == "Dona Brasa", "teclado: maiúscula em cada palavra")
	_esperar(t.formatar("ÁGUA VIVA") == "Água Viva", "teclado: a maiúscula com acento")
	_esperar("ÁGUA".to_lower() == "água", "teclado: «ÁGUA».to_lower() dá «água»")
	t.texto = "AGUA"
	t.cursor = Vector2i(0, 4)   # a tecla ´
	t.escolher()
	_esperar(t.formatar(t.texto) == "Aguá", "teclado: o agudo acentua a última letra")
	t.texto = "Z"
	t.cursor = Vector2i(1, 4)   # a tecla ~
	_esperar(t.escolher() == "" and t.texto == "Z", "teclado: til em letra que não aceita não faz nada")
	t.texto = "ABCDEF GHIJK"
	t.cursor = Vector2i(0, 0)
	_esperar(t.escolher() == "" and t.texto.length() == 12, "teclado: no máximo 12 caracteres")
	t.texto = ""
	t.cursor = Vector2i(6, 3)   # o espaço
	t.escolher()
	_esperar(t.texto == "", "teclado: o espaço não começa o nome")
	t.texto = "Dona "
	t.escolher()
	_esperar(t.texto == "Dona ", "teclado: nunca dois espaços seguidos")
	t.cursor = Vector2i(1, 0)   # B
	t.escolher()
	_esperar(t.texto == "Dona B", "teclado: a letra depois do espaço sai maiúscula (%s)" % t.texto)
	t.texto = "Ana"
	t.cursor = Vector2i(4, 4)   # Pronto
	t.outros = ["Ana"]
	_esperar(t.no_pronto() and t.escolher() == "" and not t.pode_gravar(), "teclado: o nome igual ao de outro lugar não fecha")
	t.outros = ["Bia"]
	_esperar(t.escolher() == "pronto", "teclado: com o nome livre, ✕ no Pronto fecha")
	t.texto = "A"
	_esperar(t.escolher() == "", "teclado: com uma letra só, o Pronto está apagado")
	t.texto = "Dona Brasa"
	_esperar(t.escolher() == "pronto" and TecladoDoNome.nome_final("DONA BRASA ") == "Dona Brasa", "teclado: o espaço do fim sai ao gravar")
	# as bordas: não dá a volta; o Pronto é uma tecla de três colunas
	t.cursor = Vector2i(0, 0)
	_esperar(not t.mover(Vector2i(-1, 0)) and not t.mover(Vector2i(0, -1)), "teclado: nas bordas o cursor para")
	t.cursor = Vector2i(6, 4)
	_esperar(not t.mover(Vector2i(1, 0)) and not t.mover(Vector2i(0, 1)) and t.mover(Vector2i(-1, 0)) and t.cursor == Vector2i(3, 4),
		"teclado: do Pronto, ◀ vai ao ◯ e ▶ e ▼ param (%s)" % t.cursor)
	# a repetição do direcional segurado: 0,40 s e depois a cada 0,15 s, em ms de parede
	t.cursor = Vector2i(0, 0)
	var andou := 0
	for ms in range(0, 1000, 10):
		if t.quadro(Vector2(1.0, 0.0), 1000 + ms):
			andou += 1
	_esperar(andou == 5 and t.cursor.x == 5,
		"teclado: segurado, anda já, repete depois de 0,40 s e a cada 0,15 s (%d passos em 1 s)" % andou)
	_esperar(not t.quadro(Vector2(0.0, 0.0), 3000) and t.quadro(Vector2(0.0, 1.0), 3010),
		"teclado: soltar zera a espera, e o eixo dominante manda")
	_esperar(TecladoDoNome.largura_da_grade() == 400.0, "teclado: a grade cabe na coluna de 432 px")
	_esperar(TecladoDoNome.altura_da_grade() == 284.0 and TecladoDoNome.CAMPO.position.y == 660.0 and TecladoDoNome.GRADE_Y + 284.0 == 1000.0,
		"teclado: a faixa vai de y 660 a 1000")
	# o pior caso de largura, 12 «W», no tamanho de texto de 1,0× e de 1,15×: a letra cabe na tecla, o nome no campo
	var escala_antes := Tema.escala_texto
	for escala in [1.0, 1.15]:
		Tema.escala_texto = escala
		var f := Tema.archivo(600)
		_esperar(Desenho.largura_do_nome("W", f, 36) <= TecladoDoNome.TECLA - 4.0,
			"teclado: o «W» cabe na tecla a %.2f× (%.1f px de 52)" % [escala, Desenho.largura_do_nome("W", f, 36)])
		var corte := Desenho.nome_que_cabe("Wwwwwwwwwwww", f, 32, TecladoDoNome.CAMPO.size.x - 12.0 - 8.0 - 3.0)
		_esperar(Desenho.largura_do_nome(corte, f, 32) <= TecladoDoNome.CAMPO.size.x - 12.0 - 8.0 - 3.0,
			"teclado: «WWWWWWWWWWWW» cabe no campo a %.2f× (%s)" % [escala, corte])
		_esperar(Desenho.largura_do_nome("Pronto", Tema.archivo(700), 34) <= 3.0 * TecladoDoNome.TECLA + 2.0 * TecladoDoNome.VAO - 8.0,
			"teclado: «Pronto» cabe na tecla larga a %.2f×" % escala)
	Tema.escala_texto = escala_antes


## Os quatro escrevem ao mesmo tempo, cada um na sua coluna (G09).
var _janela_do_teclado := Vector2i.ZERO   ## [de, até) nas linhas da linha do tempo: a fase em que só o P1 apertou


func _prova_do_teclado_na_mesa() -> void:
	var l0: TelaLobby = jogo.lobby
	# a repetição do direcional anda no relógio do jogo aqui: com a máquina carregada, dois quadros podiam passar de 0,40 s
	l0.relogio_do_teclado = func() -> int: return int(Engine.get_process_frames() * 1000 / 60)
	var original: String = jogo.jogadores[0].nome
	for vez in TelaLobby.NOME - TelaLobby.CABECA:
		await _aperta(0, Forja.BAIXO)
	_esperar(l0.linha[0] == TelaLobby.NOME, "teclado: ▼ ▼ ▼ ▼ leva o P1 à linha Nome")
	_janela_do_teclado.x = _linha_do_tempo().size()
	await _aperta(0, Forja.R1)
	_esperar(l0.teclados[0] != null and l0.teclados[1] == null and l0.teclados[2] == null and l0.teclados[3] == null,
		"teclado: R1 na linha Nome abre o teclado do P1, e só o dele")
	var t: TecladoDoNome = l0.teclados[0]
	_esperar(t.texto == original, "teclado: abre com o nome de agora no campo (%s)" % t.texto)
	# ◯ apaga letra a letra; com o campo vazio, fecha e o nome volta ao de antes
	for i in original.length():
		await _aperta(0, Forja.CIRCULO)
	_esperar(l0.teclados[0] != null and t.texto == "", "teclado: ◯ apaga a última letra, uma a uma")
	await _aperta(0, Forja.CIRCULO)
	_esperar(l0.teclados[0] == null and jogo.jogadores[0].nome == original,
		"teclado: ◯ com o campo vazio fecha e o nome volta ao de antes")
	# escreve «Ed» com o direcional: do Pronto, ▲ quatro vezes e ✕ põe o E; ◀ e ✕ põe o D
	await _aperta(0, Forja.R1)
	t = l0.teclados[0]
	for i in original.length():
		await _aperta(0, Forja.CIRCULO)
	for i in 4:
		await _aperta(0, Forja.CIMA)
	await _aperta(0, Forja.CRUZ)
	_esperar(t.texto == "E", "teclado: ✕ põe a letra da tecla (%s)" % t.texto)
	await _aperta(0, Forja.ESQUERDA)
	await _aperta(0, Forja.CRUZ)
	_esperar(t.texto == "Ed", "teclado: só a primeira letra da palavra é maiúscula (%s)" % t.texto)
	_esperar(l0.teclados[1] == null and jogo.jogadores[1].nome != "Ed", "teclado: o P2 não ouviu o teclado do P1")
	# o único na mesa: o nome do P2 forçado igual ao do campo do P1 não fecha
	var nome_p2: String = jogo.jogadores[1].nome
	jogo.jogadores[1].nome = "Ed"
	await _quadros(2)
	await _aperta(0, Forja.R1)
	_esperar(t.no_pronto() and not t.pode_gravar(), "teclado: o nome igual ao do P2 deixa o Pronto apagado")
	await _aperta(0, Forja.CRUZ)
	_esperar(l0.teclados[0] != null and jogo.jogadores[0].nome == original, "teclado: dois lugares com o mesmo nome não fecham")
	jogo.jogadores[1].nome = nome_p2
	await _quadros(2)
	await _aperta(0, Forja.CRUZ)
	_esperar(l0.teclados[0] == null and jogo.jogadores[0].nome == "Ed", "teclado: ✕ no Pronto grava o nome e fecha (%s)" % jogo.jogadores[0].nome)
	_janela_do_teclado.y = _linha_do_tempo().size()
	_esperar(l0.nome_escrito[0], "teclado: o nome digitado conta como escrito")
	# △ sorteia do que ninguém usa e leva o cursor ao Pronto
	await _aperta(0, Forja.R1)
	t = l0.teclados[0]
	await _aperta(0, Forja.TRIANGULO)
	var outros_n := [jogo.jogadores[1].nome, jogo.jogadores[2].nome, jogo.jogadores[3].nome]
	_esperar(t.no_pronto() and t.texto in TelaLobby.NOMES and not (t.texto in outros_n), "teclado: △ sorteia um nome livre e vai ao Pronto (%s)" % t.texto)
	await _aperta(0, Forja.CIRCULO)
	await _aperta(0, Forja.CIRCULO)
	for i in 10:
		if l0.teclados[0] == null:
			break
		await _aperta(0, Forja.CIRCULO)
	_esperar(l0.teclados[0] == null, "teclado: ◯ até o campo esvaziar fecha o teclado")
	jogo.jogadores[0].nome = original   # o robô refaz o nome do P1 pelo teclado, depois
	l0.nome_escrito[0] = false
	l0.t_nome_ms[0] = 0
	l0.linha[0] = TelaLobby.CABECA
	l0._robo_teclado[0] = 0   # o robô escreve o nome do P1 do começo


## O nome e a sensação, na linha do tempo: o P1 escreveu e o toque saiu só na mão dele;
## o evento do cavaleiro diz o nome e o tempo no teclado.
func _prova_do_nome_na_linha_do_tempo() -> void:
	var linhas := _linha_do_tempo()
	var toques := [0, 0, 0, 0]
	for i in range(_janela_do_teclado.x, mini(_janela_do_teclado.y, linhas.size())):
		var e: Dictionary = linhas[i]
		if e.get("tipo") == "sensacao" and e.get("nome") == "toque":
			toques[int(e.get("lugar", 0))] += 1
	_esperar(toques[0] > 4 and toques[1] == 0 and toques[2] == 0 and toques[3] == 0,
		"teclado: o toque das teclas chegou só ao P1 enquanto só ele escrevia (%s)" % [toques])
	var nomes := {}
	var escritos := {}
	for e in linhas:
		if e.get("tipo") == "cavaleiro" and not escritos.has(int(e.get("lugar", -1))):   # o primeiro de cada lugar: a montagem da noite
			nomes[int(e.get("lugar", -1))] = str(e.get("nome", ""))
			escritos[int(e.get("lugar", -1))] = e
	var distintos := {}
	for l in 4:
		distintos[nomes.get(l, "")] = true
	_esperar(nomes.get(0, "") == "Dona Brasa" and nomes.get(1, "") in TelaLobby.NOMES and nomes.get(2, "") in TelaLobby.NOMES
		and nomes.get(3, "") in TelaLobby.NOMES and distintos.size() == 4,
		"teclado: o evento «cavaleiro» traz os quatro nomes, nenhum repetido (%s)" % [nomes])
	_esperar(escritos.has(0) and escritos[0].get("nome_escrito") == true and int(escritos[0].get("t_nome_ms", 0)) > 0
		and escritos.has(1) and escritos[1].get("nome_escrito") == false,
		"teclado: o evento «cavaleiro» diz quem escreveu e quanto tempo levou")
	var momentos := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "nome_escrito")
	_esperar(momentos.size() >= 1 and momentos.all(func(e): return e.get("slot") == "montagem" and int(e.get("lugar", -1)) == 0),
		"teclado: o momento «nome_escrito» é do lugar que escreveu (%d)" % momentos.size())


## O caminho de cada peça da Kenney e a escala por pasta (G10).
func _prova_do_kit_da_kenney() -> void:
	_esperar(Kit.caminho("floor") == "res://assets/kenney/mini-dungeon/floor.glb", "kit: sem pasta, o mini-dungeon")
	_esperar(Kit.caminho("castle-kit/tower-base") == "res://assets/kenney/castle-kit/tower-base.glb", "kit: a pasta antes da barra")
	_esperar(ResourceLoader.exists(Kit.caminho("floor")), "kit: o mini-dungeon abre da pasta nova")
	_esperar(ResourceLoader.exists(Kit.caminho("mini-dungeon-personagens/character-orc")), "kit: o orc abre")
	_esperar(ResourceLoader.exists(Kit.caminho("cube-pets/animal-fox")), "kit: a raposa abre")
	_esperar(ResourceLoader.exists(Kit.caminho("mini-characters/character-female-a")) and ResourceLoader.exists(Kit.caminho("mini-characters/character-male-f")), "kit: os 12 do Mini Characters abrem")
	_esperar(ResourceLoader.exists(Kit.caminho("graveyard-kit/character-skeleton")), "kit: o esqueleto do Graveyard abre")
	_esperar(is_equal_approx(Kit.escala_do_pacote("castle-kit/tower-base"), 1.4), "kit: o castle-kit vale 1,4")
	_esperar(is_equal_approx(Kit.escala_do_pacote("factory-kit/door"), 0.5), "kit: o factory-kit vale 0,5")
	_esperar(is_equal_approx(Kit.escala_do_pacote("floor"), 1.0) and is_equal_approx(Kit.escala_do_pacote("mini-dungeon/floor"), 1.0), "kit: o mini-dungeon vale 1")
	var pai := Node3D.new()
	add_child(pai)
	var torre := Kit.peca(pai, "castle-kit/tower-base", Vector3.ZERO)
	var chao := Kit.peca(pai, "floor", Vector3.ZERO)
	_esperar(is_equal_approx(torre.scale.x, Kit.K * 1.4), "kit: Kit.peca multiplica a escala pela da pasta (%.2f)" % torre.scale.x)
	_esperar(is_equal_approx(chao.scale.x, Kit.K), "kit: a peça sem pasta fica na escala pedida (%.2f)" % chao.scale.x)
	pai.queue_free()
	var soltas := 0
	for f in DirAccess.get_files_at("res://assets/kenney"):
		if f.ends_with(".glb"):
			soltas += 1
	_esperar(soltas == 0, "kit: nenhuma peça solta em assets/kenney (%d)" % soltas)


## G14: a cor e a letra da Fita. A tabela dos jogadores é uma só (o jogo, a
## lightbar), as tintas das seções vêm do tema, as duas fontes do app saíram e o
## boneco não leva o tom do dono (o dono é o contorno e o aro, G15).
func _prova_da_cor_e_da_letra() -> void:
	_esperar(Forja.COR_DO_LUGAR == Tema.JOGADOR, "tema: a cor do lugar é a do 02")
	for l in 4:
		Forja.luz_do_lugar(l)
		await _quadros(2)
		var luz: Color = Forja.estado_saida(l).luz
		var alvo: Color = Tema.JOGADOR[l]
		_esperar(absf(luz.r - alvo.r) <= 1.0 / 255.0 and absf(luz.g - alvo.g) <= 1.0 / 255.0
			and absf(luz.b - alvo.b) <= 1.0 / 255.0, "lightbar: P%d na cor do 02" % (l + 1))
	_esperar(Tema.tinta_da_secao(6) == Tema.SECAO[1], "tema: S6 é cobalto")
	_esperar(not FileAccess.file_exists("res://assets/fontes/SpaceGrotesk-wght.ttf"), "tema: Space Grotesk saiu")
	_esperar(not FileAccess.file_exists("res://assets/fontes/JetBrainsMono-wght.ttf"), "tema: JetBrains Mono saiu")
	var corpos := 0
	for p in jogo.jogadores:
		for mi in p.find_children("body*", "MeshInstance3D", true, false):
			for s in mi.mesh.get_surface_count():
				corpos += 1
				var m = mi.get_surface_override_material(s)
				var base = mi.mesh.surface_get_material(s)
				# a roupa da G08 é um material de shader que não tinge (o dono só no acento, no contorno e no aro);
				# o resto leva a cópia do material do kit, com a mesma cor
				_esperar(m == null or (m is ShaderMaterial and not (m as ShaderMaterial).shader.code.contains("tingir"))
					or (m is StandardMaterial3D and base is StandardMaterial3D and m.albedo_color == base.albedo_color),
					"boneco P%d: o corpo sem o tom do dono" % (p.lugar + 1))
	_esperar(corpos > 0, "boneco: a prova achou o corpo (%d superfícies)" % corpos)


## F09b: a letra mínima e a margem segura moram no tema, e o HUD parte delas.
func _prova_da_letra_e_da_margem() -> void:
	var antes := Tema.escala_texto
	Tema.escala_texto = 1.0
	_esperar(Tema.LETRA_MINIMA == 30, "tema: a letra mínima é 30")
	_esperar(Tema.t(20) == Tema.LETRA_MINIMA, "tema: nada se desenha abaixo da letra mínima (%d)" % Tema.t(20))
	_esperar(Tema.t(Tema.T_SELO) == 30, "tema: o selo continua em 30")
	Tema.escala_texto = 1.15
	_esperar(Tema.t(Tema.T_SELO) > 30, "tema: a escala grande ainda cresce a letra (%d)" % Tema.t(Tema.T_SELO))
	Tema.escala_texto = antes
	_esperar(is_equal_approx(Tema.AREA_SEGURA, 0.05), "tema: a área segura é de 5%")
	_esperar(Tema.MARGEM_X >= 1920 * Tema.AREA_SEGURA and Tema.MARGEM_Y >= 1080 * Tema.AREA_SEGURA, "tema: as margens cobrem a área segura")
	# o quadro da sala no HUD acaba antes do primeiro chip de lugar
	var x_chips := 1920.0 - Tema.MARGEM_X - (HudJogo.LARG_CHIP * 4 + 16.0 * 3)
	for par in [["O Impacto", "Sinta o golpe e levante o escudo do lado."], ["A Centelha", "Aperte o botão da runa antes do anel fechar."],
			["Os Caminhos", "Ande no escuro e sinta o caminho."]]:
		var q: Dictionary = HudJogo.quadro_da_sala(par[0], par[1], 1920.0)
		var r: Rect2 = q["rect"]
		_esperar(r.end.x <= x_chips - 24.0 + 0.5, "HUD: o quadro de «%s» acaba antes dos chips (%.0f)" % [par[0], r.end.x])
		_esperar(r.position.x + 28.0 >= Tema.MARGEM_X, "HUD: o texto do quadro de «%s» começa na margem" % par[0])
		_esperar(r.end.y > 150.0 and r.end.y < 260.0, "HUD: o quadro de «%s» tem altura de quadro (%.0f)" % [par[0], r.end.y])
	# a ação de toda sala cabe inteira no quadro, também com o texto grande das Opções
	var antes_q := Tema.escala_texto
	for esc in [1.0, 1.15]:
		Tema.escala_texto = esc
		for id in Catalogo.MINIGAMES.keys() + Catalogo.SALAS_ANTIGAS.keys():
			var sl = Catalogo.criar(id)
			var qs: Dictionary = HudJogo.quadro_da_sala(str(sl.nome), str(sl.acao), 1920.0)
			sl.free()
			_esperar(not str(qs["acao"]).ends_with("…"), "HUD: a ação de «%s» cabe inteira (%.2f×: %s)" % [id, esc, qs["acao"]])
			_esperar((qs["rect"] as Rect2).end.x <= x_chips - 24.0 + 0.5 and (qs["rect"] as Rect2).end.y < 300.0,
				"HUD: o quadro de «%s» fica antes dos chips (%.2f×)" % [id, esc])
	Tema.escala_texto = antes_q
	# a linha de status cabe no chip: não passa para o texto do chip do lado
	for linha in ["Brasa · vida 100 · 99 balas", "Maré · vida 100 · 99 balas", "Brasa · derrubado", "Rodada 12 de 12 · 9999 ✓", "Brasa · vida 100 · 99 balas · recarregando a arma agora"]:
		var dita := HudJogo.linha_do_status(linha)
		_esperar(Desenho.largura(dita, Tema.archivo(500), Tema.T_SELO) <= HudJogo.LARG_CHIP - 40.0 + 0.5,
			"HUD: a linha «%s» cabe no chip" % linha)
	# as dicas e as perguntas na raia não saem da margem, nem com a fila apertada
	var painel := PainelSala.new()
	painel.size = Vector2(1920, 1080)
	for folga in [PainelSala.FOLGA_PILULA, PainelSala.FOLGA_PERGUNTA]:
		var itens := [[0, [], Rect2(Vector2(30, 600), Vector2(300, 52))], [1, [], Rect2(Vector2(74, 600), Vector2(300, 52))],
			[2, [], Rect2(Vector2(1700, 600), Vector2(300, 52))], [3, [], Rect2(Vector2(1838, 600), Vector2(300, 52))]]
		painel._afastar(itens, folga)
		for it in itens:
			var rr: Rect2 = it[2]
			_esperar(rr.position.x + folga >= Tema.MARGEM_X - 0.5 and rr.end.x - folga <= 1920 - Tema.MARGEM_X + 0.5,
				"painel: o texto do lugar %d fica na área segura (%.0f a %.0f)" % [it[0] + 1, rr.position.x + folga, rr.end.x - folga])
	painel.free()


## Cada canal de `a` a menos de 1/255 de `b` (a conta OKLab pode errar um passo num canal).
func _cor_quase(a: Color, b_hex: String) -> bool:
	var b := Color(b_hex)
	return absf(a.r - b.r) <= 1.0 / 255.0 + 0.0001 and absf(a.g - b.g) <= 1.0 / 255.0 + 0.0001 and absf(a.b - b.b) <= 1.0 / 255.0 + 0.0001


## G15: a luz de cada seção, o ambiente do jogo, o brilho com dono, o contorno e o anel dos bonecos, a luz de
## dono e o pós da fita.
func _prova_da_luz() -> void:
	# a luz das cinco tintas bate com a tabela do 01
	var tabela := [
		[1, "210502", "602016", "ffc99c"], [2, "050d26", "1f346a", "e5d3c6"], [3, "011311", "11413b", "e5d7ad"],
		[4, "170e00", "493400", "f8d096"], [5, "18081c", "4a2854", "f8ccba"]]
	for linha in tabela:
		var v := Tema.luz_da_secao(int(linha[0]))
		_esperar(_cor_quase(v.nevoa, "#" + linha[1]) and _cor_quase(v.preenchimento, "#" + linha[2]) and _cor_quase(v.chave, "#" + linha[3]),
			"luz: a seção %d como o 01 (névoa %s, preenchimento %s, chave %s)" % [linha[0], v.nevoa.to_html(false), v.preenchimento.to_html(false), v.chave.to_html(false)])
	_esperar(Tema.luz_da_secao(6).chave == Tema.luz_da_secao(2).chave and Tema.luz_da_secao(9).nevoa == Tema.luz_da_secao(1).nevoa,
		"luz: a seção 6 é cobalto e a 9 é vermelhão")
	var a := Tema.luz_da_secao(1)
	var b := Tema.luz_da_secao(1, true)
	_esperar(is_equal_approx(a.densidade, 0.012) and is_equal_approx(b.densidade, 0.0156), "luz: o lado B adensa a névoa (0,012 para 0,0156)")
	_esperar(is_equal_approx(a.energia_chave, 1.8) and is_equal_approx(b.energia_chave, 1.53), "luz: o lado B baixa a chave (1,8 para 1,53)")
	var salao_luz := Tema.luz_da_secao(-1)
	_esperar(salao_luz.nevoa == Tema.VIOLETA_FUNDO and salao_luz.preenchimento == Tema.AMBIENTE_SALAO and salao_luz.chave == Tema.TUNGSTENIO,
		"luz: o salão é violeta, ambiente do salão e tungstênio")
	# o ambiente do jogo
	_esperar(jogo.env.ssao_enabled == false and is_equal_approx(jogo.env.glow_hdr_threshold, 0.82), "luz: sem SSAO, limiar do glow 0,82")
	jogo._entrar_na_sala("viga", false)
	await _quadros(3)
	var luz_viga := Tema.luz_da_secao(jogo.sala.numero())
	_esperar(jogo.sala.numero() == 2 and jogo.env.ambient_light_color == luz_viga.preenchimento and is_equal_approx(jogo.env.fog_density, 0.012),
		"luz: a viga acende na seção 2 (cobalto)")
	var tochas_na_chave := 0
	for t in jogo.sala._chaves:
		if t.light_color == luz_viga.chave:
			tochas_na_chave += 1
	_esperar(jogo.sala._chaves.size() > 0 and tochas_na_chave == jogo.sala._chaves.size(), "luz: as tochas da viga na chave da seção (%d)" % tochas_na_chave)
	var sol := jogo.get_node("Sol") as DirectionalLight3D
	_esperar(sol.light_color == luz_viga.preenchimento, "luz: o sol da cena no preenchimento da seção")
	# o brilho com dono: o teto de cada um
	var mm := Tema.emissivo(StandardMaterial3D.new(), 9.0, "mundo")
	_esperar(is_equal_approx(mm.emission_energy_multiplier, 1.2) and mm.emission == Tema.VIOLETA, "brilho: o mundo para em 1,2 e brilha violeta")
	var mf := Tema.emissivo(StandardMaterial3D.new(), 9.0, "forja")
	_esperar(is_equal_approx(mf.emission_energy_multiplier, 2.4) and mf.emission == Tema.TUNGSTENIO, "brilho: a forja para em 2,4 e brilha tungstênio")
	var ml := Tema.emissivo(StandardMaterial3D.new(), 9.0, 2)
	_esperar(is_equal_approx(ml.emission_energy_multiplier, 3.0) and ml.emission == Tema.JOGADOR[2], "brilho: o lugar para em 3,0 e brilha na cor dele")
	_esperar(Tema.emissivo(StandardMaterial3D.new(), 0.0, "mundo").emission_enabled == false, "brilho: a energia 0 desliga")
	_esperar(is_equal_approx(Kit.material(Tema.VIOLETA, 3.0).emission_energy_multiplier, 1.2), "brilho: o Kit.material leva o dono (o mundo, 1,2)")
	var nm := Tema.neon(Tema.TUNGSTENIO, 9.0, 1)
	_esperar(nm.get_shader_parameter("cor") == Tema.JOGADOR[1] and is_equal_approx(nm.get_shader_parameter("energia"), 3.0), "brilho: o néon de um lugar tem a cor dele, no teto")
	var cm := Tema.contorno(Tema.JOGADOR[0], 0.012, 2.4, 0)
	_esperar(cm.get_shader_parameter("normal_suave") == true and is_equal_approx(cm.get_shader_parameter("largura"), 0.012), "brilho: o contorno com a normal suave")
	# o boneco: o anel, o contorno e a luz de dono
	for p in jogo.jogadores:
		var l: int = p.lugar
		var anel: MeshInstance3D = p.aro.get_child(0)   # o anel de 8 lados (Kit.anel_do_dono); as lâmpadas vêm depois
		_esperar(anel.material_override is ShaderMaterial and anel.material_override.get_shader_parameter("cor") == Tema.JOGADOR[l]
			and is_equal_approx(anel.material_override.get_shader_parameter("energia"), 1.5), "boneco P%d: o anel no chão é néon do lugar a 1,5" % (l + 1))
		var com_contorno := 0
		var sem_contorno := 0
		var quais := []
		for mi in p.modelo.find_children("*", "MeshInstance3D", true, false):
			if mi.material_override != null:
				continue  # o que a sala pendura no boneco (a vara, o martelo) tem o material da sala
			for s in mi.mesh.get_surface_count():
				var m = mi.get_surface_override_material(s)
				if m and m.next_pass is ShaderMaterial and m.next_pass.get_shader_parameter("cor") == Tema.JOGADOR[l] \
						and is_equal_approx(m.next_pass.get_shader_parameter("energia"), 2.4):
					com_contorno += 1
				else:
					sem_contorno += 1
					var np = m.next_pass if m else null
					quais.append("%s/%d:%s" % [mi.name, s, "sem material" if m == null else ("sem passe" if np == null else "cor %s energia %s" % [np.get_shader_parameter("cor"), np.get_shader_parameter("energia")])])
		_esperar(com_contorno > 0 and sem_contorno == 0, "boneco P%d: toda superfície leva o contorno do lugar a 2,4 (%d com, sem: %s)" % [l + 1, com_contorno, ", ".join(quais)])
		var ld: OmniLight3D = p.luz_de_dono
		_esperar(ld.light_color == Tema.JOGADOR[l] and is_equal_approx(ld.light_energy, 0.9) and is_equal_approx(ld.omni_range, 3.4)
			and not ld.shadow_enabled and is_equal_approx(ld.position.y, 0.6), "boneco P%d: a luz de dono (0,9, 3,4 m, sem sombra, a 0,6 m)" % (l + 1))
		_esperar(ld.visible == p.controlavel, "boneco P%d: a luz de dono só com o controle livre" % (l + 1))
	var p0 = jogo.jogadores[0]
	p0.contornar(1.6)
	var mi0: MeshInstance3D = p0.modelo.find_children("*", "MeshInstance3D", true, false)[0]
	_esperar(is_equal_approx(mi0.get_surface_override_material(0).next_pass.get_shader_parameter("energia"), 1.6), "boneco: o contorno da montagem vai a 1,6")
	p0.contornar(2.4)
	p0.controlavel = true
	_esperar(p0.luz_de_dono.visible, "boneco: a luz de dono acende com o controle livre")
	p0.controlavel = false
	_esperar(not p0.luz_de_dono.visible, "boneco: a luz de dono apaga sem o controle")
	# o pós da fita
	_esperar(PosFita.get_child(0).layer == 5 and PosFita.get_child(1).layer == 20, "pós: as duas passadas, na camada 5 e na 20")
	PosFita.gastar(1)
	_esperar(is_equal_approx(PosFita.valor("grao"), 0.018) and is_equal_approx(PosFita.valor("vinheta"), 0.38), "pós: a faixa 1 no começo do desgaste")
	PosFita.gastar(12)
	_esperar(is_equal_approx(PosFita.valor("grao"), 0.040), "pós: a faixa 12 no teto do grão")
	_esperar(is_equal_approx(PosFita.valor("desbota"), 0.10) and is_equal_approx(PosFita.valor("varredura"), 0.09), "pós: o desbotar e a varredura no teto na faixa 12")
	PosFita.gastar(40)
	_esperar(is_equal_approx(PosFita.valor("grao"), 0.040) and is_equal_approx(PosFita.valor("vinheta"), 0.45), "pós: o desgaste para no teto")
	PosFita.ajustar("grao", 0.1)
	_esperar(is_equal_approx(PosFita.valor("grao"), 0.1), "pós: ajustar põe o valor")
	PosFita.soltar("grao")
	_esperar(is_equal_approx(PosFita.valor("grao"), 0.040), "pós: soltar volta ao desgaste da faixa")
	Opcoes.flashes = false
	PosFita.rasgo_curto()
	_esperar(PosFita.valor("rasgo") == 0.0 and PosFita.valor("aberracao") == 0.0, "pós: sem Flashes, sem rasgo")
	Opcoes.flashes = true
	PosFita._rasgos.clear()
	PosFita.rasgo_curto()
	Opcoes.flashes = false
	await _quadros(2)
	_esperar(PosFita.valor("rasgo") == 0.0 and PosFita.valor("aberracao") == 0.0, "pós: desligar os Flashes no meio do rasgo o apaga")
	Opcoes.flashes = true
	await _quadros(14)
	PosFita._rasgos.clear()
	PosFita.rasgo_curto()
	await _quadros(3)
	_esperar(PosFita.valor("rasgo") > 0.0 and PosFita.valor("rasgo") <= 0.35 + 0.0001, "pós: com Flashes o rasgo corre (%.2f)" % PosFita.valor("rasgo"))
	await _quadros(14)
	_esperar(PosFita.valor("rasgo") == 0.0 and PosFita.valor("aberracao") == 0.0, "pós: o rasgo acaba em 10 quadros")
	PosFita._rasgos.clear()
	for i in 5:
		PosFita.rasgo_curto()
	_esperar(PosFita._rasgos.size() == 3, "pós: no máximo 3 rasgos por segundo (%d)" % PosFita._rasgos.size())
	await _quadros(14)
	# a sala gasta a fita pela posição na partida: faixa 1 fora dela, passo + 1 nela
	jogo._entrar_na_sala("centelha", false)
	await _quadros(3)
	_esperar(is_equal_approx(PosFita.valor("grao"), 0.018), "pós: fora da partida, a sala entra na faixa 1")
	jogo._comecar_a_partida(9, false, false)
	await _quadros(3)
	jogo.partida.passo = 8
	jogo._entrar_na_sala(jogo.partida.sala_atual(), false)
	await _quadros(3)
	_esperar(is_equal_approx(PosFita.valor("grao"), 0.018 + 0.002 * 8.0), "pós: a nona sala da partida entra na faixa 9 (grão %.3f)" % PosFita.valor("grao"))


# ------------------------------------------------------------------ G16: o virar da fita e o conforto --

## As opções novas (G16): o arquivo antigo, as ajudas do Movimento, as Reações, a leitura dos scripts e a lista que desliza.
func _prova_do_conforto() -> void:
	var g_gatilho: Array = Opcoes.gatilho.duplicate()
	var g_vibracao: Array = Opcoes.vibracao.duplicate()
	var g_tempo: Array = Opcoes.tempo_ms.duplicate()
	var g_volumes := [Opcoes.volume_tv, Opcoes.volume_controle]
	var g_resto := [Opcoes.movimento, Opcoes.reacoes, Opcoes.flashes, Opcoes.tela_cheia, Opcoes.texto, Opcoes.idioma]
	var antigo := "user://opcoes_antigo.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("sessao", "tremor", false)
	cfg.save(antigo)
	Opcoes.de_fabrica()
	Opcoes.ler(antigo)
	_esperar(Opcoes.movimento == 1, "opções: o tremor desligado antigo vira Reduzido")
	cfg.set_value("sessao", "tremor", true)
	cfg.save(antigo)
	Opcoes.ler(antigo)
	_esperar(Opcoes.movimento == 0, "opções: o tremor ligado antigo vira Inteiro")
	cfg.set_value("sessao", "movimento", 9)
	cfg.set_value("sessao", "reacoes", 9)
	cfg.save(antigo)
	Opcoes.ler(antigo)
	_esperar(Opcoes.movimento == Opcoes.MOVIMENTO.size() - 1 and Opcoes.reacoes == Opcoes.REACOES.size() - 1,
		"opções: um arquivo fora da lista volta para a borda (%d, %d)" % [Opcoes.movimento, Opcoes.reacoes])
	Opcoes.movimento = 1
	Opcoes.reacoes = 2
	Opcoes.gravar(false, antigo)
	Opcoes.de_fabrica()
	_esperar(Opcoes.movimento == 0 and Opcoes.reacoes == 0, "opções: de fábrica, Inteiro e Todas")
	Opcoes.ler(antigo)
	_esperar(Opcoes.movimento == 1 and Opcoes.reacoes == 2, "opções: Movimento e Reações voltam do arquivo (%d, %d)" % [Opcoes.movimento, Opcoes.reacoes])
	var gravado := ConfigFile.new()
	gravado.load(antigo)
	_esperar(not gravado.has_section_key("sessao", "tremor") and gravado.has_section_key("sessao", "movimento") and gravado.has_section_key("sessao", "reacoes"),
		"opções: o arquivo novo guarda Movimento e Reações e não o tremor")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(antigo))
	# o Movimento
	Opcoes.movimento = 0
	_esperar(Opcoes.parada(2) == 2 and is_equal_approx(Opcoes.esmagar(1.3), 1.2) and is_equal_approx(Opcoes.esmagar(0.7), 0.8) and Opcoes.confete(22) == 22,
		"movimento: Inteiro, a parada de 2 quadros, squash até 20 %, o confete inteiro")
	Opcoes.movimento = 1
	_esperar(Opcoes.parada(2) == 0 and is_equal_approx(Opcoes.esmagar(1.3), 1.05) and is_equal_approx(Opcoes.esmagar(0.7), 0.95),
		"movimento: sem parada, squash até 5 %")
	_esperar(Opcoes.confete(22) == 6 and Opcoes.confete(1) == 1 and Opcoes.confete(0) == 0, "movimento: o confete a um quarto, arredondado para cima")
	# as Reações
	Opcoes.reacoes = 0
	_esperar(Opcoes.reacao_do_jogador() and Opcoes.reacao_do_jogo(), "reações: todas")
	Opcoes.reacoes = 1
	_esperar(not Opcoes.reacao_do_jogador() and Opcoes.reacao_do_jogo(), "reações: só do jogo")
	Opcoes.reacoes = 2
	_esperar(not Opcoes.reacao_do_jogador() and not Opcoes.reacao_do_jogo(), "reações: nenhuma")
	# a partida
	var p := Partida.new()
	p.salas = ["prova", "a", "b", "c", "d"]
	p.passo = 3
	_esperar(p.metade() == 3 and p.lado() == "B", "partida: a 4ª faixa de 5 é lado B")
	p.passo = 2
	_esperar(p.lado() == "A", "partida: a 3ª faixa de 5 é lado A")
	p.salas = ["a", "b", "c"]
	p.passo = 2
	_esperar(p.metade() == 2 and p.lado() == "B", "partida: a 3ª faixa de 3 é lado B")
	# a leitura dos scripts
	var tremor_velho: Array = []
	var parada_sem_ajuda: Array = []
	var nome_velho := "Opcoes." + "tremor"
	for raiz in ["res://scripts", "res://testes"]:
		for arq in _scripts(raiz):
			var texto := FileAccess.get_file_as_string(arq)
			if arq.ends_with("/prova_do_jogo.gd"):
				continue
			if texto.contains(nome_velho):
				tremor_velho.append(arq.get_file())
			if texto.contains("speed_scale = 0.0") and not texto.contains("Opcoes.parada("):
				parada_sem_ajuda.append(arq.get_file())
	var fonte := FileAccess.get_file_as_string("res://scripts/main.gd")
	_esperar(fonte.contains("Opcoes.confete(22)") and fonte.contains("0.0 if Opcoes.reduzido() else 0.03 * TelaIntro.entra_sai")
		and fonte.contains('estado == "sala" and sala and not Opcoes.reduzido()'), "movimento: o confete, o push-in do título e o tremor da câmera leem o Reduzido")
	_esperar(tremor_velho.is_empty(), "movimento: nenhum script lê o tremor antigo (%s)" % [tremor_velho])
	_esperar(parada_sem_ajuda.is_empty(), "movimento: toda parada de quadros passa por Opcoes.parada (%s)" % [parada_sem_ajuda])
	# a lista que desliza
	var tela := TelaOpcoes.new()
	var tela_cheia_pai := Control.new()
	tela_cheia_pai.size = Vector2(1920, 1080)
	add_child(tela_cheia_pai)
	tela_cheia_pai.add_child(tela)
	tela.abrir(0)
	_esperar(tela._linhas.size() == 11 and tela._linhas[5][0] == "movimento" and tela._linhas[7][0] == "reacoes",
		"opções: 11 linhas, com Movimento e Reações (%d)" % tela._linhas.size())
	_esperar(tela._alto_do_quadro() <= 1000.0 and tela._quadro().end.y <= 1040.0 and tela._quadro().position.y >= 40.0,
		"opções: o quadro cabe na tela com 40 px de margem (%.0f)" % tela._alto_do_quadro())
	_esperar(tela._conteudo() > tela._alto_da_lista(), "opções: a lista é maior que o seu retângulo, então desliza (%.0f > %.0f)" % [tela._conteudo(), tela._alto_da_lista()])
	_esperar(tela._rolar_alvo == 0.0, "opções: aberta, a lista está no alto")
	var sempre_a_vista := true
	var maior_rolagem := 0.0
	for k in 11:
		var b: Dictionary = tela._blocos()[tela.linha]
		var vp := tela._alto_da_lista()
		if not (tela._rolar_alvo <= float(b.topo) + 0.01 and tela._rolar_alvo + vp >= float(b.topo) + float(b.alto) - 0.01):
			sempre_a_vista = false
		maior_rolagem = maxf(maior_rolagem, tela._rolar_alvo)
		tela.navegar(1)
	_esperar(sempre_a_vista, "opções: a linha escolhida fica inteira à vista em todas as 11")
	_esperar(maior_rolagem > 0.0, "opções: ao descer, a lista rola (%.0f)" % maior_rolagem)
	tela.navegar(-1)
	_esperar(tela._linhas[tela.linha][0] == "idioma" and tela._rolar_alvo == maxf(0.0, tela._conteudo() - tela._alto_da_lista()),
		"opções: de cima para baixo pela borda, o Idioma fica no fim da lista (%.0f)" % tela._rolar_alvo)
	# o Reduzido salta; o Inteiro anda
	tela.linha = 0
	tela._rolar = 0.0
	tela._rolar_alvo = 0.0
	Opcoes.movimento = 1
	for k in 10:
		tela.navegar(1)
	_esperar(is_equal_approx(tela._rolar, tela._rolar_alvo) and tela._rolar_alvo > 0.0, "opções: no Reduzido a lista salta, sem deslizar")
	Opcoes.movimento = 0
	tela.linha = 0
	tela._rolar = 0.0
	tela._rolar_alvo = 0.0
	for k in 10:
		tela.navegar(1)
	_esperar(tela._rolar < tela._rolar_alvo, "opções: no Inteiro a lista desliza até lá")
	# as linhas novas trocam e voltam
	var antes_dos_toques := _linha_do_tempo().size()
	tela.linha = 5
	tela.trocar(1)
	_esperar(Opcoes.movimento == 1 and tela.valor("movimento") == "Reduzido", "opções: ▶ em Movimento liga o Reduzido")
	tela.trocar(1)
	_esperar(Opcoes.movimento == 0, "opções: ▶ de novo volta ao Inteiro")
	tela.linha = 7
	Opcoes.reacoes = 0
	tela.trocar(-1)
	_esperar(Opcoes.reacoes == 2 and tela.valor("reacoes") == "Nenhuma", "opções: ◀ em Reações do começo vai para o fim")
	var toques_das_linhas := _linha_do_tempo().slice(antes_dos_toques).filter(
		func(e): return e.get("tipo") == "sensacao" and e.get("nome") == "toque" and int(e.get("jogador", 0)) == tela.quem + 1)
	_esperar(toques_das_linhas.size() == 3, "opções: ◀ ▶ em Movimento e Reações dão o toque em quem mexeu (%d)" % toques_das_linhas.size())
	tela_cheia_pai.free()
	# devolve tudo como achou
	Opcoes.gatilho = g_gatilho
	Opcoes.vibracao = g_vibracao
	Opcoes.tempo_ms = g_tempo
	Opcoes.volume_tv = g_volumes[0]
	Opcoes.volume_controle = g_volumes[1]
	Opcoes.movimento = g_resto[0]
	Opcoes.reacoes = g_resto[1]
	Opcoes.flashes = g_resto[2]
	Opcoes.tela_cheia = g_resto[3]
	Opcoes.texto = g_resto[4]
	Opcoes.idioma = g_resto[5]


## O cassete (G16): a pose em cada tempo do virar, no Inteiro e no Reduzido. Pura.
func _prova_do_virar_pura() -> void:
	_esperar(TelaVirar.TOTAL_MS == 4000.0 and TelaVirar.CLUNK_MS == 1380.0, "virar: 4000 ms no total e o clunk em 1380")
	var p0 := TelaVirar.pose(0.0, false)
	_esperar(p0.face == "A" and is_equal_approx(p0.sx, 1.0) and is_equal_approx(p0.esc, 1.0) and is_zero_approx(p0.dy), "virar: em 0 ms o cassete está parado, de face A")
	var p360 := TelaVirar.pose(360.0, false)
	_esperar(is_equal_approx(p360.dy, -40.0) and is_equal_approx(p360.esc, 1.08), "virar: em 360 ms ele subiu 40 px e cresceu 8 %")
	var p719 := TelaVirar.pose(719.0, false)
	var p721 := TelaVirar.pose(721.0, false)
	_esperar(p719.face == "A" and p721.face == "B", "virar: a face B aparece no meio do giro (720 ms)")
	_esperar(TelaVirar.pose(720.0, false).sx < 0.001, "virar: no meio do giro o cassete está de lado")
	_esperar(TelaVirar.pose(540.0, false).sx > 0.0 and TelaVirar.pose(540.0, false).sx < 1.0, "virar: o giro encolhe a largura")
	_esperar(is_equal_approx(TelaVirar.pose(1080.0, false).sx, 1.0), "virar: o giro acaba em 1080 ms")
	_esperar(TelaVirar.pose(1379.0, false).dy < 0.0, "virar: antes do clunk o cassete ainda desce")
	_esperar(is_equal_approx(TelaVirar.pose(1390.0, false).dy, 6.0) and is_zero_approx(TelaVirar.pose(1420.0, false).dy) and TelaVirar.pose(1390.0, false).face == "B",
		"virar: o clunk afunda 6 px por 34 ms, de face B")
	var parado := true
	for t in range(0, 4001, 25):
		var pr := TelaVirar.pose(float(t), true)
		parado = parado and is_equal_approx(pr.sx, 1.0) and is_equal_approx(pr.esc, 1.0) and is_zero_approx(pr.dy)
	_esperar(parado, "virar: no Reduzido o cassete não gira, não sobe e não afunda")
	_esperar(TelaVirar.pose(689.0, true).face == "A" and TelaVirar.pose(690.0, true).face == "B", "virar: no Reduzido a face troca num corte, em 690 ms")
	_esperar(TelaVirar.carreteis("A") == Vector2(0.30, 0.95) and TelaVirar.carreteis("B") == Vector2(0.95, 0.30), "virar: os carretéis trocam de lado com a face")


## Uma noite de 5 faixas (centelha, viga, impacto, galeria, prova): a fita vira depois da 3ª, 4000 ms, e para no
## intervalo até um ✕; o momento, as sensações e a luz do lado B. O ✕ cedo demais não vale.
func _prova_da_noite_da_fita() -> void:
	var antes := _linha_do_tempo().size()
	jogo._comecar_a_partida(5, false, false)
	await _quadros(3)
	var p: Partida = jogo.partida
	_esperar(p.salas.size() == 5 and p.metade() == 3 and p.lado() == "A" and not p.virou, "noite: cinco faixas, a fita vira depois da 3ª (%s)" % [p.salas])
	var vistos := {}
	var pontos := [[10, 40, 30, 20], [0, 50, 10, 20], [5, 60, 0, 0]]
	for i in 3:
		var q := 0
		while (not jogo.sala is SalaJogo or Catalogo.apelido(jogo.sala.id) != p.salas[i] or jogo._trocando) and q < 900:
			await _quadros(2)
			q += 2
		var sala = jogo.sala
		if not sala is SalaJogo or Catalogo.apelido(sala.id) != p.salas[i]:
			_esperar(false, "noite: a faixa %d (%s) não abriu (estado %s, overlay %s, sala %s, trocando %s, t %s, pronto %s, robo %s, rodada %s)" % [i + 1, p.salas[i], jogo.estado, jogo.overlay, jogo.sala, jogo._trocando, jogo.placar._t, jogo.placar.pronto(), Forja.robo, jogo._robo_placar_rodada])
			return
		_esperar(is_equal_approx(jogo.env.fog_density, Tema.luz_da_secao(sala.numero(), false).densidade), "noite: a faixa %d acende no lado A" % (i + 1))
		q = 0
		await _passar_a_entrada(sala)
		while is_instance_valid(sala) and sala.fase == "aviso" and q < 600:
			await _quadros(1)
			q += 1
		for l in 4:
			sala.pontos[l] = pontos[i][l]
		sala.terminar()
		q = 0
		while jogo.overlay != "placar" and q < 600:
			await _quadros(2)
			q += 2
		_esperar(jogo.overlay == "placar" and p.historico.size() == i + 1, "noite: o placar da faixa %d" % (i + 1))
	# o ✕ do robô no placar da 3ª: a fita vira no próximo compasso; o placar fica até lá
	var q := 0
	while jogo.estado != "virar" and q < 900:
		await _quadros(1)
		q += 1
	_esperar(jogo.estado == "virar" and jogo.tela_virar.visible and jogo.tela_virar.modo == "virar", "noite: depois do placar da 3ª, a fita vira (%d quadros de espera)" % q)
	for l in 4:
		_esperar(not jogo.jogadores[l].controlavel, "noite: no virar, o P%d está no pedestal" % (l + 1))
	# o virar corre sozinho: 4000 ms, sem botão
	await _aperta(1, Forja.CRUZ)
	_esperar(jogo.estado == "virar", "noite: o ✕ não pula o virar")
	var quadros_do_virar := 0
	q = 0
	while jogo.estado == "virar" and q < 600:
		await _quadros(1)
		quadros_do_virar += 1
		q += 1
	_esperar(jogo.estado == "intervalo" and p.virou and p.lado() == "B", "noite: o virar acaba no intervalo, no lado B")
	_esperar(absf(quadros_do_virar - 240.0) <= 12.0, "noite: o virar dura 4000 ms (%d quadros restantes depois do ✕)" % quadros_do_virar)
	# o intervalo: o salão na luz do lado B
	var luz_b := Tema.luz_da_secao(-1, true)
	_esperar(is_equal_approx(jogo.env.fog_density, luz_b.densidade) and not is_equal_approx(luz_b.densidade, Tema.luz_da_secao(-1, false).densidade),
		"noite: o intervalo é o salão na luz do lado B (névoa %.4f)" % jogo.env.fog_density)
	_esperar(jogo.salao.pedestais_no.visible and jogo.tela_virar.modo == "intervalo" and jogo.tela_virar.rotulo == "Partida · sala 4 de 5",
		"noite: o intervalo mostra os pedestais e «%s»" % jogo.tela_virar.rotulo)
	# o ✕ cedo demais não vale; depois de 500 ms, sim
	await _aperta(0, Forja.CRUZ)
	_esperar(jogo.estado == "intervalo" and not jogo._trocando, "noite: o ✕ nos primeiros 500 ms do intervalo não vale")
	await _quadros(40)
	await _aperta(0, Forja.CRUZ)
	q = 0
	while (not jogo.sala is SalaJogo or Catalogo.apelido(jogo.sala.id) != p.salas[3] or jogo._trocando) and q < 600:
		await _quadros(2)
		q += 2
	_esperar(jogo.estado != "intervalo" and jogo.sala is SalaJogo and Catalogo.apelido(jogo.sala.id) == p.salas[3], "noite: o ✕ depois dos 500 ms segue para a 4ª faixa (%s)" % jogo.sala.id)
	await _quadros(3)
	_esperar(is_equal_approx(jogo.env.fog_density, Tema.luz_da_secao(jogo.sala.numero(), true).densidade), "noite: a 4ª faixa acende no lado B")
	_esperar(is_equal_approx(PosFita.valor("grao"), 0.018 + 0.002 * 3.0) or PosFita.valor("grao") > 0.018, "noite: a 4ª faixa gasta a fita (grão %.3f)" % PosFita.valor("grao"))
	# a linha do tempo conta a história
	var linhas := _linha_do_tempo().slice(antes)
	var virou := linhas.filter(func(e): return e.get("tipo") == "sala" and e.get("o") == "virou")
	var intervalos := linhas.filter(func(e): return e.get("tipo") == "sala" and e.get("o") == "intervalo")
	_esperar(virou.size() == 1 and intervalos.size() == 1, "noite: o virar e o intervalo uma vez cada (%d, %d)" % [virou.size(), intervalos.size()])
	var clunks := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "fita_virada")
	_esperar(clunks.size() == 1 and int(clunks[0].get("ms_desde_o_corte", 0)) >= 1380 and int(clunks[0].get("ms_desde_o_corte", 0)) <= 1400,
		"noite: o momento fita_virada entre 1380 e 1400 ms do corte (%s)" % [clunks])
	var fitas := linhas.filter(func(e): return e.get("tipo") == "sensacao" and e.get("nome") == "fita")
	var lugares := fitas.map(func(e): return int(e.get("jogador", 0)))
	lugares.sort()
	_esperar(fitas.size() == 4 and lugares == [1, 2, 3, 4] and fitas.all(func(e): return int(e.get("ms", 0)) == 1600),
		"noite: a sensação «fita» de 1600 ms em cada um dos quatro (%s)" % [fitas])
	var depois := linhas.slice(linhas.find(intervalos[0]) + 1) if not intervalos.is_empty() else []
	var toques := depois.filter(func(e): return e.get("tipo") == "sensacao" and e.get("nome") == "toque")
	_esperar(toques.size() >= 1 and toques.all(func(e): return int(e.get("jogador", 0)) == 1),
		"noite: o toque do ✕ do intervalo só no P1, quem apertou (%s)" % [toques])
	# fecha a noite sem jogar as faixas que sobram
	jogo._ir_para_o_salao(false)
	await _quadros(5)


## As contas da câmera e da lente, com uma câmera de verdade (35 mm, 16:9) (G05).
func _prova_das_contas_da_camera() -> void:
	_esperar(absf(Lente.fov(35.0) - 37.85) < 0.01, "a lente de 35 mm é 37,8° (%.2f)" % Lente.fov(35.0))
	_esperar(absf(Lente.fov(28.0) - 46.4) < 0.1 and absf(Lente.fov(50.0) - 27.0) < 0.1, "28 mm é 46,4° e 50 mm é 27,0°")
	_esperar(absf(Lente.fov(Lente.PADRAO) - 40.0) < 0.01, "o padrão continua 40°")
	_esperar(absf(Lente.recuo(35.0) - 1.0616) < 0.001 and absf(Lente.recuo(50.0) - 1.5165) < 0.001 and absf(Lente.recuo(28.0) - 0.8493) < 0.001,
		"a fixa recua 6,16 % a 35 mm, 51,65 % a 50 mm e 85 % a 28 mm")
	# a lente de cada modo e os limites de 24 a 100 mm
	var s := Sala.new()
	var por_modo := {}
	for modo in ["fixa", "dupla", "grupo", "corrida"]:
		s.camera_modo = modo
		por_modo[modo] = s.lente()
	_esperar(por_modo == {"fixa": 35.0, "dupla": 50.0, "grupo": 35.0, "corrida": 28.0}, "a lente de cada modo (%s)" % [por_modo])
	s.camera_lente = 10.0
	var baixa := s.lente()
	s.camera_lente = 300.0
	var alta := s.lente()
	s.camera_lente = 85.0
	_esperar(baixa == 24.0 and alta == 100.0 and s.lente() == 85.0, "a lente da ficha vale, entre 24 e 100 mm (%.0f, %.0f, %.0f)" % [baixa, alta, s.lente()])
	# o tremor: três degraus, em batidas, e o maior não é trocado por um menor
	var bat := 60.0 / (Ritmo.bpm if Ritmo.bpm > 0.0 else 120.0)
	var degraus := []
	for amp in [Sala.TREMOR_GOLPE, Sala.TREMOR_ESTRONDO, Sala.TREMOR_EXPLOSAO, Sala.TREMOR_CATASTROFE, 0.03, 0.06, 1.0]:
		s.abalo = 0.0
		s.tremer(amp)
		degraus.append([roundi(s.abalo * 1000.0), roundi(s._abalo_dura / bat)])
	_esperar(degraus == [[20, 1], [50, 2], [50, 2], [80, 4], [30, 2], [60, 4], [80, 4]],
		"tremer: golpe 1 batida, estrondo 2, catástrofe 4, e o teto de 0,08 m (mm e batidas: %s)" % [degraus])
	# a batida é 60 / bpm: a 60 BPM o golpe dura 1 s
	var bpm_antes: float = Ritmo.bpm
	Ritmo.bpm = 60.0
	s.abalo = 0.0
	s.tremer(Sala.TREMOR_GOLPE)
	_esperar(is_equal_approx(s._abalo_dura, 1.0), "tremer: a batida é 60 / bpm (%.2f s a 60 BPM)" % s._abalo_dura)
	Ritmo.bpm = bpm_antes
	s.abalo = 0.0
	s.tremer(Sala.TREMOR_CATASTROFE)
	s.tremer(Sala.TREMOR_GOLPE)
	_esperar(is_equal_approx(s.abalo, 0.08) and is_equal_approx(s._abalo_dura / bat, 4.0), "um tremor menor não substitui o vivo")
	s.tremer(0.0)
	_esperar(is_equal_approx(s.abalo, 0.08), "amplitude zero não zera o tremor vivo")
	# o desconto é linear, pelo dt somado
	s._process(bat * 2.0)
	_esperar(absf(s.abalo - 0.04) < 0.0005, "o abalo cai em linha reta: a meia duração, a metade (%.4f)" % s.abalo)
	s._process(bat * 2.5)
	_esperar(s.abalo == 0.0, "o abalo acaba em zero, não abaixo")
	# os alvos da sala de base: só os visíveis, e a borda da corrida com nós de verdade
	add_child(s)
	for i in 3:
		var n := Node3D.new()
		s.add_child(n)
		n.global_position = Vector3(i, 0, -4.0 * i)
		s.jogadores.append(n)
	s.jogadores[1].visible = false
	_esperar(s.alvos_da_camera() == [Vector3(0, 0, 0), Vector3(2, 0, -8)], "a sala de base enquadra só os visíveis (%s)" % [s.alvos_da_camera()])
	s.jogadores[1].visible = true
	s.camera_frente = Vector3(0, 0, -1)
	s.camera_alcance = 5.0
	s.jogadores[2].global_position = Vector3(2, 0, -12)  # o líder: a corrida vai para −z
	s.jogadores[1].global_position = Vector3(1, 0, -10)
	s.puxar_os_de_tras()
	var zs_puxados := s.jogadores.map(func(n): return snappedf(n.global_position.z, 0.01))
	_esperar(zs_puxados == [-7.0, -10.0, -12.0], "puxar_os_de_tras: quem ficou 12 m atrás vai para 5 m do líder, sem mexer em quem está perto (%s)" % [zs_puxados])
	s.free()
	_esperar(Enquadramento.ALTURA_DO_BONECO >= 1.55 and Enquadramento.ALTURA_DO_BONECO <= 1.7, "o cavaleiro mais alto tem 1,55 m: a altura do enquadramento o cobre")
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = Lente.fov(35.0)
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	var tv := tan(deg_to_rad(cam.fov) * 0.5)
	var tam := get_viewport().get_visible_rect().size
	var th := tv * tam.x / maxf(tam.y, 1.0)
	var dir := Vector3(0, 17.5, 12.3).normalized()
	var cantos := [Vector3(-10, 0, -6), Vector3(10, 0, -6), Vector3(-10, 0, 6), Vector3(10, 0, 6)]
	var pose := Enquadramento.grupo(cantos, dir, Vector2(8.0, 40.0), tv, th)
	cam.global_position = pose[0]
	cam.look_at(pose[1])
	var dentro := 0
	for c in cantos:
		if cam.is_position_in_frustum(c) and cam.is_position_in_frustum(c + Vector3(0, 1.6, 0)):
			dentro += 1
	_esperar(dentro == 4, "câmera grupo: os quatro cantos da arena na tela (%d)" % dentro)
	# a margem de 15 %: o canto mais apertado fica a pelo menos 15 % de folga da borda
	var folga := INF
	for c in cantos:
		for h in [0.0, Enquadramento.ALTURA_DO_BONECO]:
			var tela := cam.unproject_position(c + Vector3(0, h, 0))
			folga = minf(folga, minf(minf(tela.x, tam.x - tela.x) / tam.x, minf(tela.y, tam.y - tela.y) / tam.y))
	# 15 %% de margem: o ponto mais apertado fica a (1 − 1/1,15) / 2 = 6,5 %% da borda
	_esperar(folga > 0.055 and folga < 0.075, "câmera grupo: sobra a margem de 15 %%, justa (%.3f da tela)" % folga)
	var perto := Enquadramento.grupo([Vector3.ZERO, Vector3(0.5, 0, 0)], dir, Vector2(12.0, 40.0), tv, th)
	_esperar(is_equal_approx((perto[0] - perto[1]).length(), 12.0), "câmera grupo: dois juntos, a distância mínima")
	var longe := Enquadramento.grupo([Vector3(-80, 0, 0), Vector3(80, 0, 0)], dir, Vector2(12.0, 30.0), tv, th)
	_esperar(is_equal_approx((longe[0] - longe[1]).length(), 30.0), "câmera grupo: longe demais, a câmera para na distância máxima")
	var corrida := [Vector3(0, 0, -20), Vector3(1, 0, -12), Vector3(-1, 0, -6), Vector3(0, 0, -2)]
	var pc := Enquadramento.corrida(corrida, Vector3(0, 0, -1), dir, Vector2(8.0, 40.0), tv, th)
	cam.global_position = pc[0]
	cam.look_at(pc[1])
	_esperar(cam.is_position_in_frustum(corrida[0]) and cam.is_position_in_frustum(corrida[3]), "câmera corrida: o líder e o último na tela")
	_esperar(absf(pc[1].z - (-2.0 + (-20.0 + 2.0) * 0.65)) < 0.001, "câmera corrida: o centro puxado 65 %% para o líder (%.2f)" % pc[1].z)
	var puxadas := Enquadramento.puxar(corrida, Vector3(0, 0, -1), 10.0)
	_esperar(is_equal_approx(puxadas[3].z, -10.0) and puxadas[0] == corrida[0] and puxadas[2].z == -10.0 and puxadas[1] == corrida[1],
		"câmera corrida: quem ficou 18 m e 14 m atrás volta para 10 m do líder, quem estava perto fica")
	cam.queue_free()


## A Prova no modo grupo, com o robô jogando: ninguém sai da tela; o tremor por degrau, sem roll (G05).
func _prova_da_camera_na_prova() -> void:
	var sala = await _comeca_a_sala("prova")
	if sala == null:
		return
	_esperar(sala.camera_modo == "grupo" and sala.camera_distancia == Vector2(17.0, 25.5), "A Prova enquadra o grupo, de 17 a 25,5 m")
	var tam_tela := jogo.get_viewport().get_visible_rect().size
	var cabe_16_9: bool = tam_tela.x / tam_tela.y >= 16.0 / 9.0 - 0.01
	var fov_certo: float = Lente.fov(35.0) if cabe_16_9 else rad_to_deg(2.0 * atan(tan(deg_to_rad(Lente.fov(35.0)) * 0.5) * 16.0 / 9.0))
	_esperar(absf(jogo.camera.fov - fov_certo) < 0.05 and (jogo.camera.keep_aspect == Camera3D.KEEP_HEIGHT) == cabe_16_9,
		"a sala filma a 35 mm (%.2f°, esperado %.2f°)" % [jogo.camera.fov, fov_certo])
	var tg: Vector2 = jogo._tangentes()
	var tmeio := tan(deg_to_rad(jogo.camera.fov) * 0.5)
	var asp := tam_tela.x / tam_tela.y
	_esperar((absf(tg.x - tmeio) < 0.001 and absf(tg.y - tmeio * asp) < 0.001) if cabe_16_9 else (absf(tg.y - tmeio) < 0.001 and absf(tg.x - tmeio / asp) < 0.001),
		"as tangentes de meio campo: (vertical, horizontal) = (%.3f, %.3f)" % [tg.x, tg.y])
	await _quadros(60)
	var fora := 0
	for i in 300:
		await _quadros(1)
		for p in jogo.jogadores:
			if not p.visible:
				continue
			for h in [0.0, Enquadramento.ALTURA_DO_BONECO]:
				if not jogo.camera.is_position_in_frustum(p.global_position + Vector3(0, h, 0)):
					fora += 1
	_esperar(fora == 0, "A Prova: em 300 quadros, nenhum pé nem cabeça fora da tela (%d)" % fora)
	# os três degraus: a duração em batidas (no relógio da sala), sem roll
	var batida := 60.0 / (Ritmo.bpm if Ritmo.bpm > 0.0 else 120.0)
	for caso in [[Sala.TREMOR_GOLPE, 1.0], [Sala.TREMOR_ESTRONDO, 2.0], [Sala.TREMOR_CATASTROFE, 4.0]]:
		sala.abalo = 0.0
		sala.tremer(caso[0])
		_esperar(is_equal_approx(sala.abalo, caso[0]), "o degrau %.2f m começa inteiro" % caso[0])
		var t0: float = sala.t
		var roll := 0.0
		var q := 0
		while sala.abalo > 0.0 and q < 600:
			await _quadros(1)
			q += 1
			roll = maxf(roll, absf(jogo.camera.global_basis.x.y))
		var durou: float = sala.t - t0
		_esperar(absf(durou - caso[1] * batida) < 0.1, "o degrau %.2f m dura %d batida(s) (%.2f s)" % [caso[0], int(caso[1]), durou])
		_esperar(roll < 0.001, "o tremor não gira o quadro (%.4f)" % roll)
	sala.abalo = 0.0
	sala.tremer(1.0)
	_esperar(sala.abalo <= Sala.TREMOR_CATASTROFE, "nada treme mais que 0,08 m")
	# o grupo no main usa as tangentes da câmera de verdade: a pose do main é a da conta
	var dist_antes: Vector2 = sala.camera_distancia
	sala.camera_distancia = Vector2(3.0, 60.0)  # sem o piso de 17 m, a conta é que manda
	var cantos_da_arena := [Vector3(-10, 0, -6), Vector3(10, 0, -6), Vector3(-10, 0, 6), Vector3(10, 0, 6)]
	for l in 4:  # os quatro nos cantos, na hora (a Prova os recoloca no quadro seguinte)
		jogo.jogadores[l].global_position = cantos_da_arena[l]
	var tela_16_9 := Vector2(0.34, 0.34 * 16.0 / 9.0)  # a tela de verdade desta passada pode ser quadrada
	var esperada: Array = Enquadramento.grupo(sala.alvos_da_camera(), (sala.camera_pos - sala.camera_olhar).normalized(), sala.camera_distancia, tela_16_9.x, tela_16_9.y)
	var do_main: Array = jogo._pose_da_sala(tela_16_9)
	var do_main_real: Array = jogo._pose_da_camera()
	var da_conta_real: Array = Enquadramento.grupo(sala.alvos_da_camera(), (sala.camera_pos - sala.camera_olhar).normalized(), sala.camera_distancia, tg.x, tg.y)
	_esperar(do_main_real[0].distance_to(da_conta_real[0]) < 0.001, "A Prova: a pose do main usa as tangentes da câmera de verdade")
	_esperar(do_main[0].distance_to(esperada[0]) < 0.001 and do_main[1].distance_to(esperada[1]) < 0.001, "A Prova: a pose do main é a do Enquadramento.grupo")
	sala.camera_modo = "corrida"
	var dir_da_sala: Vector3 = (sala.camera_pos - sala.camera_olhar).normalized()
	var esperada_c: Array = Enquadramento.corrida(sala.alvos_da_camera(), sala.camera_frente, dir_da_sala, sala.camera_distancia, tela_16_9.x, tela_16_9.y)
	var do_main_c: Array = jogo._pose_da_sala(tela_16_9)
	_esperar(do_main_c[0].distance_to(esperada_c[0]) < 0.001 and do_main_c[1].distance_to(esperada_c[1]) < 0.001, "a corrida: a pose do main é a do Enquadramento.corrida")
	sala.camera_modo = "grupo"
	sala.camera_distancia = dist_antes
	# o balanço, conta por conta: no plano da câmera, na amplitude do evento, sem girar
	var movimento_antes: int = Opcoes.movimento
	Opcoes.movimento = 0
	sala.abalo = 0.0
	sala.tremor = 0.0
	jogo._mover_camera(0.0)
	var base: Vector3 = jogo.camera.global_position
	var giro: Basis = jogo.camera.global_basis
	for caso in [[0.05, 0.0, 0.05], [0.0, 0.7, 0.08], [0.0, 0.3, 0.036], [0.02, 0.3, 0.036], [0.08, 0.0, 0.08]]:
		sala.abalo = caso[0]
		sala.tremor = caso[1]
		jogo._mover_camera(0.0)
		var esperado: Vector3 = (giro.x * sin(jogo._t * 71.0) + giro.y * sin(jogo._t * 53.0 + 1.3)) * caso[2]
		var delta: Vector3 = jogo.camera.global_position - base
		_esperar(delta.distance_to(esperado) < 0.0005, "o balanço de abalo %.2f e tremor %.1f é de %.3f m no plano da câmera (%.4f)" % [caso[0], caso[1], caso[2], delta.distance_to(esperado)])
		_esperar(jogo.camera.global_basis.is_equal_approx(giro), "o balanço não gira a câmera")
	# o movimento reduzido: nem o abalo nem o tremor antigo
	Opcoes.movimento = 1
	sala.abalo = Sala.TREMOR_CATASTROFE
	sala.tremor = 0.7
	jogo._mover_camera(0.0)
	var parado: float = (jogo.camera.global_position - base).length()
	_esperar(parado < 0.0005, "com o movimento reduzido, a câmera não treme (%.4f m)" % parado)
	Opcoes.movimento = movimento_antes
	sala.abalo = 0.0
	sala.tremor = 0.0
	# a fixa recua, a dupla empurra, o pódio recua: a pose sai da direção da sala
	var modo_antes: String = sala.camera_modo
	var olhar: Vector3 = sala.camera_olhar
	var pos: Vector3 = sala.camera_pos
	sala.camera_modo = "fixa"
	var pf: Array = jogo._pose_da_camera()
	_esperar(pf[0].distance_to(olhar + (pos - olhar) * Lente.recuo(35.0)) < 0.001 and pf[1] == olhar, "fixa: a posição recua 6,16 % sobre o olhar a 35 mm")
	sala.camera_modo = "dupla"
	sala.camera_foco = olhar + Vector3(40, 3, 0)
	var pd: Array = jogo._pose_da_camera()
	_esperar(pd[1].distance_to(olhar + Vector3(1.5, 0, 0)) < 0.001, "dupla: o empurrão de 15 %% para a ação para em 1,5 m e não sobe (%s)" % [pd[1]])
	_esperar(pd[0].distance_to(olhar + Vector3(1.5, 0, 0) + (pos - olhar) * Lente.recuo(50.0)) < 0.001, "dupla: a 50 mm, a posição recua e leva o empurrão")
	sala.camera_foco = olhar + Vector3(4, 0, 0)
	var pd2: Array = jogo._pose_da_camera()
	_esperar(pd2[1].distance_to(olhar + Vector3(0.6, 0, 0)) < 0.001, "dupla: o empurrão é 15 % da distância até a ação")
	sala.camera_modo = modo_antes
	sala.camera_foco = Vector3.ZERO
	var estado_antes: String = jogo.estado
	jogo.estado = "podio"
	var pp: Array = jogo._pose_da_camera()
	jogo.estado = estado_antes
	var olhar_p := Vector3(-4.6, 0.9, 4.4)
	_esperar(pp[1] == olhar_p and pp[0].distance_to(olhar_p + (Vector3(-4.6, 4.0, 19.5) - olhar_p) * 1.0616) < 0.001, "pódio: o olhar fica e a posição recua para 35 mm")
	# os alvos: só quem está visível, e A Prova só quem está na partida
	var jogando_antes: Array = sala.jogando.duplicate()
	_esperar(sala.alvos_da_camera().size() == 4, "A Prova: os quatro são alvo (%d)" % sala.alvos_da_camera().size())
	sala.jogando[1] = false
	_esperar(sala.alvos_da_camera().size() == 3, "A Prova: quem saiu da partida não é alvo (%d)" % sala.alvos_da_camera().size())
	for l in 4:
		sala.jogando[l] = false
	_esperar(sala.alvos_da_camera().size() == 4, "A Prova: sem ninguém na partida, a câmera olha os visíveis (%d)" % sala.alvos_da_camera().size())
	for l in 4:
		sala.jogando[l] = jogando_antes[l]
	jogo.jogadores[2].visible = false
	_esperar(sala.alvos_da_camera().size() == 3, "A Prova: o boneco escondido não é alvo (%d)" % sala.alvos_da_camera().size())
	jogo.jogadores[2].visible = true
	# a corrida: a borda empurra (a Prova recoloca os bonecos a cada quadro: a conta se confere na hora)
	sala.camera_modo = "corrida"
	var alcance_antes: float = sala.camera_alcance
	sala.camera_alcance = 4.0  # a arena tem 13,8 m: com 14 ninguém ficaria para trás
	var zs := [-6.0, -5.0, 6.0, -3.0]
	for l in 4:
		var b: Vector3 = jogo.jogadores[l].global_position
		jogo.jogadores[l].global_position = Vector3(b.x, b.y, zs[l])
	sala.puxar_os_de_tras()
	var z2: float = jogo.jogadores[2].global_position.z
	var z3: float = jogo.jogadores[3].global_position.z
	_esperar(z2 < -0.5 and z2 > -3.5 and absf(z3 - (-3.0)) < 1.5, "corrida: quem ficou 12 m atrás volta para 4 m do líder, quem estava a 3 m fica (%.2f, %.2f)" % [z2, z3])
	sala.camera_alcance = alcance_antes
	sala.camera_modo = modo_antes
	var fonte_main := FileAccess.get_file_as_string("res://scripts/main.gd")
	var chamada := fonte_main.find('if estado == "sala" and sala and sala.camera_modo == "corrida":\n\t\tsala.puxar_os_de_tras()\n\t_mover_camera(dt)')
	_esperar(chamada >= 0, "corrida: o main puxa os de trás a cada quadro, antes de mover a câmera")
	jogo._ir_para_o_salao(false)
	await _quadros(5)


## G14b: a cor que a luz do controle pergunta nunca parece a de um lugar (ΔE OKLab de 0,15 ou mais
## até cada JOGADOR), e a cor que a prova final não sorteia é a única que lembra a luz da equipe.
func _prova_das_cores_da_pergunta() -> void:
	for sala in [SalaImpacto, SalaProva]:
		for c in sala.CORES:
			var perto := INF
			for l in 4:
				perto = minf(perto, Tema.para_oklab(c.cor).distance_to(Tema.para_oklab(Tema.JOGADOR[l])))
			_esperar(perto >= 0.15, "pergunta: o %s fica longe das quatro cores de lugar (ΔE %.3f)" % [c.nome, perto])
	for e in 2:
		for k in SalaProva.CORES.size():
			var d := Tema.para_oklab(SalaProva.CORES[k].cor).distance_to(Tema.para_oklab(SalaProva.LUZ_EQUIPE[e]))
			_esperar((d < 0.15) == (k == SalaProva.COR_PARECIDA[e]),
				"pergunta: o %s %s a luz da %s (ΔE %.3f)" % [SalaProva.CORES[k].nome,
				"lembra" if k == SalaProva.COR_PARECIDA[e] else "não lembra", SalaProva.NOME_EQUIPE[e], d])


## G04: o HUD nas duas escalas e nas duas línguas: nada encosta e tudo cabe (06).
func _confere_o_hud(onde: String) -> void:
	var escala_antes := Tema.escala_texto
	var idioma_antes := Traducoes.idioma
	var tela := Rect2(Vector2.ZERO, jogo.hud.size).grow(-0.5)
	for idioma in ["pt_BR", "en"]:
		for escala in Opcoes.ESCALA_DO_TEXTO:
			Tema.escala_texto = escala
			Traducoes.idioma = idioma
			var caixas: Array = jogo.hud.retangulos() + jogo.painel.retangulos()
			var ruins: Array = []
			for i in caixas.size():
				var a: Rect2 = caixas[i]
				if not tela.grow(0.5).encloses(a):
					ruins.append("fora %s" % a)
				for k in range(i + 1, caixas.size()):
					if a.intersects(caixas[k]):
						ruins.append("%s × %s" % [a, caixas[k]])
			_esperar(ruins.is_empty(), "HUD %s, %s, %.2f: nada encosta e tudo cabe %s" % [onde, idioma, escala, ruins])
	Tema.escala_texto = escala_antes
	Traducoes.idioma = idioma_antes
	for l in 4:
		var r := HudJogo.cartao(l, jogo.hud.size)
		_esperar(r.position.x >= Tema.MARGEM_X - 0.5 and r.end.x <= jogo.hud.size.x - Tema.MARGEM_X + 0.5
			and r.position.y >= Tema.MARGEM_Y - 0.5 and r.end.y <= jogo.hud.size.y - Tema.MARGEM_Y + 0.5,
			"%s: o cartão do P%d no canto, dentro da área segura" % [onde, l + 1])


## G04: n'A Centelha, o julgamento bate o carimbo acima do cavaleiro, com a nota do lugar na TV e na mão; cinco
## «Ressonância!» seguidas batem «EM CHAMAS»; os quatro no tempo 1, «ACORDE MAIOR!»; a vez e a fala.
func _prova_do_julgamento(centelha) -> void:
	_confere_o_hud("n'A Centelha")
	_esperar(jogo.hud.retangulos().size() >= 6, "Centelha: os quatro cartões, a etiqueta e o deck (%d caixas)" % jogo.hud.retangulos().size())
	_esperar(jogo.hud.etiqueta.get("titulo", "") == centelha.nome and str(jogo.hud.etiqueta.get("impresso", "")).begins_with("LADO "),
		"Centelha: a etiqueta da faixa diz a sala e o lado (%s)" % [jogo.hud.etiqueta])
	_esperar(Som.arquivo("jul_ressonancia_p4") != null and Som.arquivo("car_em_chamas") != null, "o jul_* e o car_* estão em assets/sons")
	# o julgamento: o carimbo, o som e a vibração do P4, sem o controle na mão
	centelha.julgar(3, 3)
	var sentiu := false
	var nota := 0.0
	var carimbo: Array = jogo.visor.do_lugar(3).filter(func(c): return c.vaga == 0 and c.palavra == "Ressonância!")
	for q in 6:
		await _quadros(1)
		var pc := _perc(3)
		sentiu = sentiu or (is_equal_approx(float(pc.get("forte", 0.0)), 0.5) and is_equal_approx(float(pc.get("fraco", 0.0)), 0.8))
		nota = maxf(nota, float(Forja.som_virtual(3).get("falante", 0.0)))
	_esperar(not carimbo.is_empty(), "o carimbo «Ressonância!» acima do P4")
	_esperar(sentiu, "a mão do P4 sente o perfeito (0,5/0,8)")
	_esperar(nota > 0.0, "a nota do P4 sai no alto-falante dele (%.2f)" % nota)
	await get_tree().create_timer(0.6).timeout
	_esperar(not carimbo.is_empty() and not jogo.visor.vivos.any(func(c): return is_same(c, carimbo[0])),
		"o carimbo do julgamento some em meio segundo")
	# EM CHAMAS: o 5º seguido, e nem um antes (a conta parte do zero e o visor do P4 vazio)
	centelha._ressonancias[3] = 0
	jogo.visor.vivos = jogo.visor.vivos.filter(func(c): return c.l != 3)
	for k in 4:
		centelha.julgar(3, 3)
	_esperar(not jogo.visor.do_lugar(3).any(func(c): return c.id == "car_em_chamas"), "quatro seguidas: ainda sem EM CHAMAS")
	centelha.julgar(3, 3)
	_esperar(jogo.visor.do_lugar(3).any(func(c): return c.id == "car_em_chamas"), "cinco seguidas: EM CHAMAS acima do P4")
	# o erro não desenha
	centelha.julgar(0, 0)
	_esperar(not jogo.visor.do_lugar(0).any(func(c): return c.vaga == 0), "o erro não tem palavra")
	# o cavaleiro na borda da tela não leva o carimbo para fora da área segura (a prova visual achou -49 px)
	var seguro := Rect2(Vector2(1920, 1080) * Tema.AREA_SEGURA, Vector2(1920, 1080) * (1.0 - 2.0 * Tema.AREA_SEGURA))
	for ponta in [Vector2(40, 512), Vector2(1900, 512), Vector2(960, 20), Vector2(960, 1070)]:
		var cc := Visor.na_area_segura(ponta, "Resonance!", 64, Vector2(1920, 1080))
		_esperar(seguro.encloses(Desenho.caixa_do_carimbo(cc, "Resonance!", 64)),
			"o carimbo com o cavaleiro em %s fica dentro da área segura (%s)" % [ponta, cc])
	_esperar(Visor.na_area_segura(Vector2(960, 540), "Afinado", 64, Vector2(1920, 1080)) == Vector2(960, 540),
		"o carimbo no meio da tela fica onde está")
	# o acorde: os quatro no mesmo tempo 1
	for l in 4:
		centelha.julgar(l, 3, "", true)
	_esperar(jogo.visor.vivos.any(func(c): return c.id == "car_acorde"), "os quatro no tempo 1: ACORDE MAIOR!")
	# a vez: um carimbo de ordem mais baixa não sai com dois vivos
	_esperar(not jogo.visor.bater(0, "car_liga"), "a vez: no máximo dois carimbos na tela")
	# a fala não divide a vaga com o carimbo
	_esperar(not jogo.visor.fala(3, "Deixa comigo o refrão!", 2.0), "a fala não aparece com o carimbo vivo do P4")


## O cavaleiro montável (G13): as contas do conferir.py pelo jogo, o pré-montado
## e o boneco de três peças.
func _prova_do_cavaleiro() -> void:
	# a mesma conta do conferir.py, pelo jogo
	var validos := 0
	var arq := {}
	var P := ["female-a", "female-b", "female-c", "female-d", "female-e", "female-f",
		"male-a", "male-b", "male-c", "male-d", "male-e", "male-f"]
	for a in P:
		for b in P:
			for c in P:
				var k := Cavaleiro.corpo([a, b, c])
				if not k.valido:
					continue
				validos += 1
				arq[k.arquetipo.nome] = arq.get(k.arquetipo.nome, 0) + 1
	_esperar(validos == 756, "756 corpos válidos (%d)" % validos)
	_esperar(arq.get("Torre", 0) == 176 and arq.get("Muralha", 0) == 176 and arq.get("Relâmpago", 0) == 170
		and arq.get("Corrente", 0) == 170 and arq.get("Aríete", 0) == 38 and arq.get("Eco", 0) == 26, "os arquétipos (%s)" % [arq])
	var k := Cavaleiro.corpo(["male-c", "female-f", "male-a"])
	_esperar(k.stats == [4, 2, 5, 2] and k.arquetipo.nome == "Muralha", "male-c, female-f, male-a: Muralha [4, 2, 5, 2]")
	_esperar(Cavaleiro.no_corpo("martelo", k.stats) == "alcanca", "o Martelo alcança, fora da liga, nesse corpo")
	_esperar(is_equal_approx(Cavaleiro.gancho(0, "empurrao"), 1.0), "sem forja, o gancho é o neutro")
	# o pré-montado: válido, sem ponto perdido, cabeças e arquétipos diferentes na mesa, o item ao alcance
	var ocupados := {}
	var cabecas := {}
	var arqs := {}
	var t0 := Time.get_ticks_msec()
	for l in 4:
		var pm := Cavaleiro.pre_montado(l, ocupados)
		var co := Cavaleiro.corpo(pm.pecas)
		_esperar(co.valido and int(co.perdidos) == 0 and Cavaleiro.no_corpo(str(pm.item), co.stats) != "fora",
			"P%d: o pré-montado é válido, sem ponto perdido, e alcança o item (%s)" % [l + 1, pm])
		cabecas[pm.pecas[0]] = true
		arqs[str(co.arquetipo.get("id", ""))] = true
		ocupados[l] = {"cabeca": pm.pecas[0], "superior": pm.pecas[1], "inferior": pm.pecas[2], "nome": pm.nome}
	_esperar(cabecas.size() == 4 and arqs.size() == 4, "os quatro pré-montados: cabeças e arquétipos diferentes (%s)" % [ocupados])
	_esperar(Time.get_ticks_msec() - t0 < 2000, "os quatro pré-montados em menos de 2 s (%d ms)" % (Time.get_ticks_msec() - t0))
	# o boneco de três peças: as três malhas no esqueleto do superior, a troca de uma só
	var p := ForjaPlayer.new()
	add_child(p)
	p.montar(0)
	p.vestir_pecas(["male-c", "female-f", "male-a"], 1)
	var esq: Skeleton3D = p.modelo.find_child("Skeleton3D", true, false)
	_esperar(esq.get_node_or_null("head") != null and esq.get_node_or_null("body-sup") != null and esq.get_node_or_null("body-inf") != null
		and p.modelo.find_child("body-mesh", true, false) == null, "três peças: head, body-sup e body-inf, sem a body-mesh inteira")
	_esperar(p.modelo_i == ForjaPlayer.indice_do_personagem("male-c") and ForjaPlayer.BONECOS[p.modelo_i].intervalo == "quarta",
		"o modelo_i é o da cabeça, e o pio dela é a quarta")
	var area: float = 2.0 * float(p._medidas.friso_alto) * p._medidas.largura_torso + 2.0 * float(p._medidas.costura_larg) * p._medidas.altura_perna
	_esperar(area <= 0.0801 * (p._medidas.frente_cima + p._medidas.frente_baixo), "o acento de duas peças em até 8 % da frente")
	var m_sup := Pintura.medidas_da(esq.get_node("body-sup") as MeshInstance3D)
	var m_inf := Pintura.medidas_da(esq.get_node("body-inf") as MeshInstance3D)
	_esperar(not m_sup.is_empty() and not m_inf.is_empty() and is_equal_approx(float(p._medidas.friso_y0), float(m_sup.friso_y0))
		and is_equal_approx(float(p._medidas.costura_x), float(m_inf.costura_x)) and is_equal_approx(float(p._medidas.altura_perna), float(m_inf.altura_perna)),
		"o friso vem do superior (female-f) e a costura e a perna, do inferior (male-a)")
	var cabeca_antes: Mesh = (esq.get_node("head") as MeshInstance3D).mesh
	var sup_antes: Mesh = (esq.get_node("body-sup") as MeshInstance3D).mesh
	p.trocar_peca(0, "female-b")
	_esperar(p.modelo.find_child("Skeleton3D", true, false) == esq and (esq.get_node("head") as MeshInstance3D).mesh != cabeca_antes
		and (esq.get_node("body-sup") as MeshInstance3D).mesh == sup_antes and p.pecas == ["female-b", "female-f", "male-a"],
		"trocar_peca troca só a cabeça, no mesmo esqueleto")
	p.acender(0.0)
	p.acender_parte("superior", 1.0)
	var mat_sup := (esq.get_node("body-sup") as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial
	var mat_inf := (esq.get_node("body-inf") as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial
	_esperar(is_equal_approx(float(mat_sup.get_shader_parameter("acesa")), 1.0) and is_zero_approx(float(mat_inf.get_shader_parameter("acesa"))),
		"acender_parte acende o superior e deixa o inferior apagado")
	p.acender(1.0)
	remove_child(p)
	p.free()


## Espera a troca pedida do lugar encaixar (a semicolcheia seguinte), até 60 quadros.
func _espera_o_encaixe(l: int) -> void:
	for q in 60:
		if jogo.lobby._encaixe[l].is_empty():
			return
		await _quadros(1)


## O encaixe (G13): ◀▶ na linha Cabeça do P2 muda só a cabeça do P2, e a malha
## "head" muda no quadro em que Ritmo.t_musica() passa da semicolcheia seguinte, não antes.
func _prova_do_encaixe() -> void:
	var p1: ForjaPlayer = jogo.jogadores[0]
	var p2: ForjaPlayer = jogo.jogadores[1]
	var cab1 := str(p1.pecas[0])
	var cab2 := str(p2.pecas[0])
	var esq2: Skeleton3D = p2.modelo.find_child("Skeleton3D", true, false)
	var malha_antes: Mesh = (esq2.get_node("head") as MeshInstance3D).mesh
	jogo.lobby.ultimo_encaixe[1] = {}
	var antes_do_toque := "etapa %d, linha %d, overlay «%s», estado %s" % [jogo.lobby.etapa[1], jogo.lobby.linha[1], jogo.overlay, jogo.estado]
	# um aperto que a tela ainda não lia (a saída de uma camada por cima) se repete, como o robô do placar; a medida da
	# semicolcheia é a do toque que valeu, guardada no registro do encaixe servido
	var toques := 0
	for vez in 3:
		toques += 1
		Forja.ctl.simulador_botao(1, Forja.DIREITA, true)
		await _quadros(2)
		Forja.ctl.simulador_botao(1, Forja.DIREITA, false)
		# o relógio da música anda na parede: o encaixe pode sair já no quadro seguinte. A prova lê o registro do servido.
		for q in 60:
			if (esq2.get_node("head") as MeshInstance3D).mesh != malha_antes:
				break
			if q >= 4 and jogo.lobby._encaixe[1].is_empty() and jogo.lobby.ultimo_encaixe[1].is_empty():
				break   # nenhum pedido: o aperto não chegou
			await _quadros(1)
		if not jogo.lobby.ultimo_encaixe[1].is_empty():
			break
	if toques > 1:
		print("aviso: o ◀▶ do P2 valeu no %dº aperto (antes do toque: %s)" % [toques, antes_do_toque])
	var e: Dictionary = jogo.lobby.ultimo_encaixe[1]
	_esperar(not e.is_empty() and int(e.linha) == TelaLobby.CABECA and (esq2.get_node("head") as MeshInstance3D).mesh != malha_antes,
		"◀▶ na Cabeça do P2 pede um encaixe, e a malha da cabeça troca (%s; antes do toque: %s)" % [e, antes_do_toque])
	_esperar(not e.is_empty() and float(e.agora) >= float(e.t) and int(e.quadro) > int(e.quadro_do_toque)
		and float(e.t) - float(e.toque) <= 0.25 * 60.0 / maxf(Ritmo.bpm, 1.0) + 0.001,
		"a cabeça do P2 encaixa na semicolcheia seguinte ao toque, nunca antes nem no quadro do toque (%s)" % [e])
	# a conta pelo relógio, fora do registro: o t do encaixe cai na grade de semicolcheias e não antes do toque
	var dezesseis := (float(e.get("t", 0.0)) - Ritmo.primeiro_tempo) * Ritmo.bpm / 60.0 * 4.0
	_esperar(not e.is_empty() and absf(dezesseis - roundf(dezesseis)) < 0.001 and float(e.t) >= float(e.toque) - 0.0001,
		"o encaixe do P2 cai na grade de semicolcheias (%.4f semicolcheias) e não antes do toque (%s)" % [dezesseis, e])
	_esperar(str(p2.pecas[0]) != cab2 and str(p1.pecas[0]) == cab1, "◀▶ na Cabeça do P2 muda a cabeça do P2 (%s → %s), e a do P1 fica" % [cab2, p2.pecas[0]])
	_esperar(jogo.lobby.corpo[1].valido and p2.modelo_i == ForjaPlayer.indice_do_personagem(str(p2.pecas[0])),
		"o corpo do P2 continua válido e o pio é o da cabeça nova")
	# a coluna do P2 com o corpo montado: nenhum texto encosta em outro (os quatro VUs, a etiqueta, as cinco linhas)
	var cartao: Control = jogo.lobby.cartoes[1]
	Desenho.retangulos.clear()
	Desenho.coletar_retangulos = true
	cartao.queue_redraw()
	await _quadros(2)
	Desenho.coletar_retangulos = false
	var no := cartao.get_instance_id()
	var textos: Array = Desenho.retangulos.filter(func(r): return int(r.no) == no)
	var ultimo := 0
	for r in textos:
		ultimo = maxi(ultimo, int(r.quadro))
	textos = textos.filter(func(r): return int(r.quadro) == ultimo)
	Desenho.retangulos.clear()
	var encostados: Array = []
	for i in textos.size():
		for j in range(i + 1, textos.size()):
			var a: Rect2 = textos[i].rect
			if a.intersects(textos[j].rect) and a.intersection(textos[j].rect).get_area() > 1.0:
				encostados.append("%s / %s" % [textos[i].frase, textos[j].frase])
	var stats := textos.filter(func(r): return Cavaleiro.NOME_ST.map(func(n): return Desenho.t(n)).has(str(r.frase)))
	_esperar(stats.size() == 4 and encostados.is_empty(),
		"a coluna do P2: os quatro VUs aparecem e nenhum texto encosta em outro (%d VUs; %s)" % [stats.size(), encostados])
	# o VU anda um segmento a cada 30 ms até o stat do corpo, sem pular
	var cj: CartaoJogador = jogo.lobby.cartoes[1]
	var alvo: Array = jogo.lobby.corpo[1].get("stats", [0, 0, 0, 0])
	cj.vu_mostrado = [0, 0, 0, 0]
	cj._vu_tempo = 0.0
	cj._andar_os_vus(0.031)
	var um_passo: Array = cj.vu_mostrado.duplicate()
	var passos := 0
	while cj.vu_mostrado != alvo.map(func(v): return int(v)) and passos < 10:
		cj._andar_os_vus(0.03)
		passos += 1
	_esperar(um_passo.all(func(v): return int(v) <= 1) and um_passo.any(func(v): return int(v) == 1)
		and cj.vu_mostrado == alvo.map(func(v): return int(v)) and passos == alvo.map(func(v): return int(v)).max() - 1,
		"o VU do P2 anda um segmento a cada 30 ms até o corpo (%s depois de 31 ms; %s em mais %d passos)" % [um_passo, alvo, passos])
	# a junta do item é o punho do osso que o segura (Montar.mao), não uma altura fixa
	var presa := esq2.get_node_or_null("Item") as BoneAttachment3D
	if presa != null:
		var punho: Vector3 = esq2.global_transform * Montar.mao(esq2, presa.bone_name)
		var j_item: Vector3 = jogo.lobby.junta(1, TelaLobby.ITEM)
		_esperar(j_item.is_equal_approx(punho) and not j_item.is_equal_approx(p2.global_position + Vector3(0, TelaLobby.JUNTA[TelaLobby.ITEM], 0)),
			"as faíscas do item do P2 saem do punho do %s (%s), não da altura fixa" % [presa.bone_name, j_item])
	else:
		_esperar(false, "o P2 segura um item num BoneAttachment3D «Item»")


## A interface da fita (G11): os seis ícones novos, o UI Pack de fora e a pausa aberta no meio da Centelha (o P2 com
## o L2 firme do Escudo): as linhas do 06, o `fx_stop`, os gatilhos Off nos quatro, a navegação que soa e vibra só
## em quem apertou, e ao fechar o L2 do P2 de volta.
func _prova_da_pausa_da_fita() -> void:
	for nome in ["mudo", "touchpad_esquerda", "touchpad_direita", "touchpad_deslizar", "touchpad_cima", "touchpad_baixo"]:
		var g := Desenho.glifo(nome)
		_esperar(g != null and g.get_width() == 128, "glifo novo: %s" % nome)
	_esperar(not DirAccess.dir_exists_absolute("res://assets/kenney/ui-pack"), "ui: o UI Pack não entrou")
	# a pausa fora da bancada: quatro linhas
	jogo.pausa.abrir(1, true, false, false)
	_esperar(jogo.pausa.opcoes.map(func(o): return o[0]) == ["continuar", "opcoes", "salao", "sair"],
		"pausa: as quatro do 06 (%s)" % [jogo.pausa.opcoes.map(func(o): return o[0])])
	# a pausa aberta como o jogo abre (overlay "pausa"), com a sala na tela
	jogo._abrir_overlay("pausa", 1)
	await _quadros(2)
	_esperar(Som.ultimo == "fx_stop", "pausa: abre com o fx_stop (%s)" % Som.ultimo)
	_esperar(Musica.abafada, "pausa: a música abafa")
	for l in 4:
		var s := Forja.estado_saida(l)
		_esperar(s.is_empty() or (int(s.l2) == Forja.GATILHO_OFF and int(s.r2) == Forja.GATILHO_OFF),
			"pausa: gatilhos Off em P%d (%s)" % [l + 1, s])
	# o som e o toque da navegação
	var antes := _contar_registro("sensacao", 1, "toque")
	var antes_p1 := _contar_registro("sensacao", 0, "toque")
	# ▼ e não ▲: do Continuar, ▲ daria a volta até «Sair»
	await _aperta(1, Forja.BAIXO)
	await _quadros(6)
	_esperar(jogo.overlay == "pausa", "pausa: segue aberta depois de navegar (%s)" % jogo.overlay)
	_esperar(_contar_registro("sensacao", 1, "toque") == antes + 1,
		"pausa: navegar vibra em quem apertou (%d -> %d)" % [antes, _contar_registro("sensacao", 1, "toque")])
	_esperar(_contar_registro("sensacao", 0, "toque") == antes_p1, "pausa: navegar não vibra em quem não apertou")
	_esperar(Som.ultimo == "ui_tique", "pausa: navegar soa ui_tique (%s)" % Som.ultimo)
	await _aperta(1, Forja.CIMA)
	jogo._fechar_overlay()
	await _quadros(4)
	_esperar(not Musica.abafada, "pausa: ao fechar, a música volta")
	_esperar(int(_perc(1).get("gatilho_esq", 0)) == 0x21,
		"pausa: ao fechar, o L2 do P2 volta firme (0x%02x)" % int(_perc(1).get("gatilho_esq", 0)))


## Quantas linhas da linha do tempo têm este `tipo`, este lugar (`"jogador"` a partir de 1) e este `nome`.
func _contar_registro(tipo: String, lugar: int, nome: String) -> int:
	var n := 0
	for e in _linha_do_tempo():
		if e.get("tipo", "") == tipo and e.get("nome", "") == nome and int(e.get("jogador", 0)) == lugar + 1:
			n += 1
	return n


## A entrada do minigame do kit (G12) passa sozinha: espera pelo relógio de parede (a cortina anda no tempo da
## música), até 8 s. Sala sem entrada passa direto.
func _passar_a_entrada(sala) -> void:
	var t0 := Time.get_ticks_usec()
	while is_instance_valid(sala) and str(sala.fase) == "entrada" and Time.get_ticks_usec() - t0 < 8000000:
		await _quadros(1)


## O último registro da linha do tempo com este tipo e este nome (vazio se não há).
func _ultimo_registro(tipo: String, nome: String) -> Dictionary:
	var ultimo := {}
	for e in _linha_do_tempo():
		if e.get("tipo", "") == tipo and e.get("nome", "") == nome:
			ultimo = e
	return ultimo


## G12: a cortina com o verbo no tempo 1 e o J-card. O minigame de prova acabou de abrir: a fase é a entrada, a
## contagem soa e vibra (um toque por tique, em cada lugar), o impacto cai num tempo 1 com um golpe em cada lugar e
## a luz em papel, e o J-card fica parado no aviso. Depois, o tamanho do verbo, a `como_jogar` que reprova e o lado.
func _prova_da_entrada(mg) -> void:
	_esperar(mg.fase == "entrada", "entrada: a sala abre pela cortina")
	var toques := []
	var golpes := []
	for l in 4:
		toques.append(_contar_registro("sensacao", l, "toque"))
		golpes.append(_contar_registro("sensacao", l, "golpe"))
	# o impacto: pelo relógio de parede, até 5 s; no quadro dele a lightbar pisca em papel
	var t0 := Time.get_ticks_usec()
	var luz_em_papel := 0
	while is_instance_valid(mg) and mg.fase == "entrada" and not mg._entrada_feito.has("luz") and Time.get_ticks_usec() - t0 < 5000000:
		await _quadros(1)
		if mg._entrada_feito.has("impacto") and not mg._entrada_feito.has("luz"):
			var n_em_papel := 0
			for l in 4:
				var luz: Color = Forja.estado_saida(l).get("luz", Color.BLACK)
				if absf(luz.r - Tema.ETIQUETA.r) <= 1.0 / 255.0 and absf(luz.g - Tema.ETIQUETA.g) <= 1.0 / 255.0 \
						and absf(luz.b - Tema.ETIQUETA.b) <= 1.0 / 255.0:
					n_em_papel += 1
			luz_em_papel = maxi(luz_em_papel, n_em_papel)
	_esperar(not Opcoes.flashes or luz_em_papel == 4, "entrada: no impacto a lightbar dos quatro pisca em papel (%d)" % luz_em_papel)
	var m := _ultimo_registro("momento", "verbo_carimbado")
	var nb: float = (float(m.get("t_musica", 0.0)) - Ritmo.primeiro_tempo) * Ritmo.bpm / 60.0
	var alvo: float = (float(m.get("t_alvo", -1.0)) - Ritmo.primeiro_tempo) * Ritmo.bpm / 60.0
	_esperar(not m.is_empty() and str(m.get("slot", "")) == mg.id and absf(alvo - 4.0 * roundf(alvo / 4.0)) < 0.001
		and absf(nb - 4.0 * roundf(nb / 4.0)) * 60.0 / Ritmo.bpm < 0.020,
		"entrada: o verbo carimba no tempo 1 (tempo %.3f, alvo %.3f)" % [nb, alvo])
	await _passar_a_entrada(mg)
	_esperar(is_instance_valid(mg) and mg.fase == "aviso", "entrada: a cortina sai e o aviso começa")
	for l in 4:
		var dt := _contar_registro("sensacao", l, "toque") - int(toques[l])
		var dg := _contar_registro("sensacao", l, "golpe") - int(golpes[l])
		_esperar(dt == 3 and dg == 1, "entrada P%d: um toque por tique e um golpe no impacto (%d toques, %d golpes)" % [l + 1, dt, dg])
	_esperar(jogo.painel._jcard_fora() == 0.0 and jogo.painel._do_kit(), "J-card: parado no aviso")
	# o tamanho do verbo: curto a 252, longo encolhe, comprido demais é 0
	_esperar(PainelSala.tamanho_do_verbo("Bata!") == 252, "entrada: verbo curto a 252 (%d)" % PainelSala.tamanho_do_verbo("Bata!"))
	var medio := PainelSala.tamanho_do_verbo("Martele!")
	_esperar(medio >= PainelSala.VERBO_MIN and medio < 252, "entrada: verbo mais longo encolhe (%d)" % medio)
	_esperar(PainelSala.tamanho_do_verbo("Inclinem juntos!") == 0, "entrada: verbo que não cabe a 160 é 0")
	# a chave nova reprova: sem ela, vazia, com glifo que não existe, frase longa, verbo longo
	_esperar(Minigame.validar(mg.ficha), "kit: a FICHA do minigame de prova passa")
	var f: Dictionary = mg.ficha.duplicate(true)
	f.erase("como_jogar")
	_esperar(not Minigame.validar(f), "kit: sem como_jogar reprova")
	for ruim in [[], [["glifo_que_nao_existe", "Bater"]], [["cross", "Uma frase comprida demais para o J-card"]],
			[["cross", "A"], ["cross", "B"], ["cross", "C"], ["cross", "D"]]]:
		f = mg.ficha.duplicate(true)
		f["como_jogar"] = ruim
		_esperar(not Minigame.validar(f), "kit: a como_jogar %s reprova" % [ruim])
	f = mg.ficha.duplicate(true)
	f["verbo"] = "Inclinem juntos!"
	_esperar(not Minigame.validar(f), "kit: verbo que não cabe na cortina reprova")
	var partida_de_teste := Partida.nova(3, false, 7, [])
	_esperar(partida_de_teste.lado() == "A", "partida: o lado A no começo")
	partida_de_teste.passo = 2
	_esperar(partida_de_teste.lado() == "B", "partida: o lado B na segunda metade")
	# o pronto dos quatro: mais um toque em cada um, no lugar do Forja.vibrar de antes
	for l in 4:
		toques[l] = _contar_registro("sensacao", l, "toque")
	var q := 0
	while is_instance_valid(mg) and mg.fase == "aviso" and not (mg.prontos as Array).all(func(x): return x) and q < 600:
		await _quadros(1)
		q += 1
	for l in 4:
		var dt := _contar_registro("sensacao", l, "toque") - int(toques[l])
		_esperar(dt == 1, "aviso P%d: o ✕ do pronto vibra um toque (%d)" % [l + 1, dt])



## As falas (G07): as regras do 07 (uma por vez, 20 s por lugar), o vocabulário, o lado no treino, as falas que o
## julgamento puxa e o «por um fio».
func _prova_das_falas() -> void:
	var s := SalaJogo.new()
	var ditas: Array = []
	s.falou.connect(func(l, texto, seg): ditas.append([l, texto, seg]))
	s.t = 100.0
	_esperar(s.falar(0, "vencedor") and ditas.size() == 1 and is_equal_approx(float(ditas[0][2]), Falas.DURACAO_S),
		"falas: a primeira fala sai, por 2 s (%s)" % [ditas])
	s.t = 101.0
	_esperar(not s.falar(1, "combo_equipe"), "falas: duas ao mesmo tempo, não")
	s.t = 102.1
	_esperar(s.falar(1, "combo_equipe"), "falas: passados 2 s, a fala do P2 sai")
	s.t = 110.0
	_esperar(not s.falar(0, "voltou"), "falas: o P1 não fala de novo antes de 20 s")
	s.t = 120.5
	_esperar(s.falar(0, "voltou"), "falas: passados 20 s, o P1 fala de novo")
	s.t = 200.0
	_esperar(not s.falar(2, "nao_existe"), "falas: evento sem frase não fala")
	s.free()
	_esperar(Falas.do_julgamento(Falas.PERFEITO) == "Ressonância!" and Falas.do_julgamento(Falas.OTIMO) == "Afinado"
		and Falas.do_julgamento(Falas.BOM) == "Quase" and Falas.do_julgamento(Falas.ERRO) == "", "falas: o vocabulário do visor")
	_esperar(Falas.do_julgamento(Falas.BOM, true, -0.08) == "Cedo" and Falas.do_julgamento(Falas.OTIMO, true, 0.07) == "Tarde"
		and Falas.do_julgamento(Falas.PERFEITO, true, 0.01) == "Ressonância!", "falas: no treino, cedo e tarde; o perfeito é perfeito")
	var sem := []
	for evento in Falas.DO_EVENTO:
		for frase in Falas.DO_EVENTO[evento]:
			if frase.substr(0, 1) != frase.substr(0, 1).to_upper() or not Traducoes.EN.has(frase):
				sem.append(frase)
	for palavra in ["Cedo", "Tarde"]:
		if not Traducoes.EN.has(palavra):
			sem.append(palavra)
	_esperar(sem.is_empty(), "falas: toda fala começa com maiúscula e tem inglês %s" % [sem])
	# o julgamento: a palavra do treino pelo desvio, e as falas que ele puxa fora do treino
	var j := SalaJogo.new()
	j.jogando = [true, true, false, false]
	var palavras: Array = []
	var faladas: Array = []
	j.julgou.connect(func(_l, _jj, palavra): palavras.append(palavra))
	j.falou.connect(func(l, texto, _seg): faladas.append([l, texto]))
	j.treinando = true
	j.julgar(0, Falas.BOM, "", false, -0.08)
	j.julgar(0, Falas.PERFEITO, "", false, 0.05)
	_esperar(palavras == ["Cedo", "Ressonância!"], "falas: no treino, o julgamento diz o lado (%s)" % [palavras])
	_esperar(faladas.is_empty(), "falas: o treino não fala")
	j.treinando = false
	j.t = 10.0
	for k in 3:
		j.julgar(0, Falas.OTIMO, "", false, 0.07)
	_esperar(faladas.size() == 1 and int(faladas[0][0]) == 0 and faladas[0][1] in Falas.DO_EVENTO.arrastando,
		"falas: três toques tarde seguidos, «arrastando» (%s)" % [faladas])
	j.t = 40.0
	j.julgar(1, Falas.ERRO)
	_esperar(faladas.size() == 1, "falas: um erro sozinho não é «todos erraram» (%s)" % [faladas])
	j.t = 40.5
	j.julgar(0, Falas.ERRO)
	_esperar(faladas.size() == 2 and faladas[1][1] in Falas.DO_EVENTO.todos_erraram,
		"falas: os dois erram em 1,5 s, «Tá tudo desafinado!» (%s)" % [faladas])
	j.free()
	# o fim: quem vence, quem vai ao inserto, por um fio (2 % ou menos)
	var f := SalaJogo.new()
	f.jogando = [true, true, false, false]
	f.pontos = [100, 99, 0, 0]
	_esperar(f.por_um_fio() and f.vencedor_do_fim() == 0 and f.ultimo_do_inserto() == 1, "fim: por um fio com 1 %")
	f.pontos = [100, 97, 0, 0]
	_esperar(not f.por_um_fio(), "fim: 3 % não é por um fio")
	f.pontos = [50, 50, 0, 0]
	_esperar(f.vencedor_do_fim() == -1 and f.ultimo_do_inserto() == -1, "fim: o empate não tem vencedor nem inserto")
	f.jogando = [true, false, false, false]
	f.pontos = [10, 0, 0, 0]
	_esperar(f.vencedor_do_fim() == 0 and f.ultimo_do_inserto() == -1, "fim: sozinho, vence e não há inserto")
	f.coop = true
	_esperar(f.vencedor_do_fim() == -1 and f.ultimo_do_inserto() == -1, "fim: o coop não tem vencedor nem inserto")
	f.free()


## O FOV que o main põe para a lente `mm` nesta tela (16:9 guarda a altura; mais estreita, a largura).
func _fov_de(mm: float) -> float:
	var tam := get_viewport().get_visible_rect().size
	if tam.y > 0.0 and tam.x / tam.y < 16.0 / 9.0 - 0.01:
		return rad_to_deg(2.0 * atan(tan(deg_to_rad(Lente.fov(mm)) * 0.5) * 16.0 / 9.0))
	return Lente.fov(mm)


## O fim filmado (G07), na primeira faixa da partida (pontos [10, 40, 30, 20], três jogando: o P2 vence, o P1 é o
## último): o plano do vencedor a 50 mm com o batimento na mão e o arpejo no alto-falante dele, o inserto a 85 mm
## com a cara emburrada e o controle que desmaia, e a tabela só depois da cena.
func _prova_do_fim_filmado(sala) -> void:
	await _quadros(2)
	_esperar(sala.vencedor_do_fim() == 1 and sala.ultimo_do_inserto() == 0,
		"fim: o P2 vence e o P1 vai ao inserto (%d, %d)" % [sala.vencedor_do_fim(), sala.ultimo_do_inserto()])
	_esperar(sala.plano_do_fim() == "resultado" and absf(jogo.camera.fov - _fov_de(50.0)) < 0.05,
		"fim: o plano do vencedor a 50 mm (%s, fov %.2f)" % [sala.plano_do_fim(), jogo.camera.fov])
	var b: float = sala.batida_do_fim()
	var pico := 0.0
	var falou := false
	var tabela := false
	var ate := Time.get_ticks_msec() + int(b * 4000.0) + 1500
	while is_instance_valid(sala) and sala.plano_do_fim() == "resultado" and Time.get_ticks_msec() < ate:
		pico = maxf(pico, float(_perc(1).get("forte", 0.0)))
		falou = falou or float(Forja.som_virtual(1).get("falante", 0.0)) > 0.0
		tabela = tabela or jogo.resultado.visible
		await _quadros(1)
	_esperar(pico >= 0.8 and falou, "fim: a vitória bate na mão do P2 (%.2f) e toca no alto-falante dele (%s)" % [pico, falou])
	_esperar(_contar_registro("sensacao", 1, "vitoria_eco") >= 1, "fim: o batimento duplo do P2 no registro")
	_esperar(is_instance_valid(sala) and sala.plano_do_fim() == "inserto" and absf(jogo.camera.fov - _fov_de(85.0)) < 0.05,
		"fim: o inserto do último a 85 mm (%s, fov %.2f)" % [sala.plano_do_fim() if is_instance_valid(sala) else "-", jogo.camera.fov])
	await _quadros(2)
	_esperar(jogo.visor.do_lugar(0).any(func(v): return v.id == "car_emburrado"), "fim: a cara emburrada acima do P1")
	_esperar(float(_perc(0).get("forte", 0.0)) > 0.3, "fim: o controle do P1 desmaia (%.2f)" % float(_perc(0).get("forte", 0.0)))
	ate = Time.get_ticks_msec() + int(b * 1000.0) + 1500
	while is_instance_valid(sala) and sala.plano_do_fim() != "" and Time.get_ticks_msec() < ate:
		tabela = tabela or jogo.resultado.visible
		await _quadros(1)
	_esperar(not tabela, "fim: a tabela não abre durante a cena")
	await _quadros(3)
	_esperar(not jogo.visor.vivos.any(func(v): return v.id == "car_emburrado"), "fim: a cara emburrada some no corte")
	_esperar(jogo.resultado.visible, "fim: depois da cena, a tabela")


## A virada no placar (G07): o líder muda e «VIRADA!» bate no cabeçalho, com o visor por cima do placar; ao fechar,
## o visor volta para cima do HUD.
func _prova_da_virada() -> void:
	var p := Partida.nova(2, false, 7, ["centelha", "galeria"])
	p.registrar("centelha", [40, 30, 10, 0], [0, 1, 2])
	p.registrar("galeria", [0, 40, 30, 0], [0, 1, 2])
	var virou: Array = []
	jogo.placar.virou.connect(func(l, _onde): virou.append(l), CONNECT_ONE_SHOT)
	jogo.placar.abrir(p, false)
	jogo.placar.visible = true
	await _quadros(int(60 * (Placar.T_LIDER + 0.3)))
	_esperar(virou == [1], "virada: o placar carimba o P2 (%s)" % [virou])
	var carimbo: Array = jogo.visor.vivos.filter(func(c): return c.id == "car_virada")
	_esperar(carimbo.size() == 1 and carimbo[0].onde == jogo.placar.ponto_da_virada(),
		"virada: «VIRADA!» no canto do cabeçalho (%s)" % [carimbo])
	_esperar(jogo.visor.get_index() > jogo.placar.get_index(), "virada: o visor por cima do placar")
	jogo.placar.visible = false
	await _quadros(1)
	_esperar(jogo.visor.get_index() == jogo.hud.get_index() + 1, "virada: o visor volta para cima do HUD")
	jogo.visor.vivos = jogo.visor.vivos.filter(func(c): return c.id != "car_virada")
