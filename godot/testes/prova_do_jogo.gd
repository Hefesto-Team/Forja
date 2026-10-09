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
	_prova_das_faixas()
	_prova_da_paridade()
	_prova_das_contas_da_camera()
	Desenho._coletar = "memoria"  # colhe cada frase desenhada (F02, F07)
	jogo = load("res://scenes/main.tscn").instantiate()
	add_child(jogo)
	await _prova_do_percurso()
	await _prova_do_motor_que_vence()
	await _prova_do_aviso_sozinho()
	await _prova_do_relatorio()
	await _prova_de_fogo()
	await _prova_da_camera_na_prova()
	_prova_das_contas_da_partida()
	await _prova_da_partida()
	_prova_do_modo()
	_prova_das_frases()
	_prova_das_maiusculas()
	_prova_da_identidade()
	_prova_das_sensacoes()
	_prova_do_registro_v2()
	await _prova_da_cor_e_da_letra()
	_prova_da_letra_e_da_margem()
	await _prova_da_luz()
	_prova_do_conforto()
	_prova_do_virar_pura()
	await _prova_da_noite_da_fita()
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

	await _aperta(0, Forja.CRUZ)
	await _quadros(40)
	_esperar(jogo.estado == "lobby", "✕ no título leva ao lobby")
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
		await _aperta(s, Forja.CRUZ)
	await _quadros(4)
	for s in 4:
		_esperar(Forja.pad_do_lugar(s) == _pad_do_sim(s), "o ✕ confirma: o simulado %d é P%d, mesmo apertando por último" % [s + 1, s + 1])
	_esperar(Forja.jogadores() == 4, "os quatro entraram")
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


## Entra na sala e espera o jogo começar (o robô fica pronto no aviso).
## Devolve a sala, ou null se ela não abriu.
func _comeca_a_sala(id: String):
	jogo._entrar_na_sala(id, false)
	await _quadros(2)
	var sala = jogo.sala
	_esperar(sala is SalaJogo and sala.id == id, "%s: a sala abriu" % id)
	if not sala is SalaJogo:
		return null
	_esperar(str(sala.icone) != "" and Desenho.glifo(str(sala.icone)) != null, "%s: o aviso tem o ícone da parte do controle" % id)
	# o fim: quando a sala emitir `terminou` e quanto era o relógio no começo
	var fim := [-1.0]  # o t_fase da sala quando ela emitiu terminou
	sala.terminou.connect(func() -> void: fim[0] = float(sala.t_fase))
	sala.set_meta("fim", fim)
	sala.set_meta("duracao_no_inicio", float(sala.duracao))
	var q := 0
	while is_instance_valid(sala) and sala.fase == "aviso" and q < 600:
		await _quadros(1)
		q += 1
	_esperar(is_instance_valid(sala) and sala.fase == "jogo", "%s: o aviso passou com os quatro prontos" % id)
	# o ✕ do robô chegou pelo controle simulado (F08): passou antes dos 8 s do relógio
	_esperar(q < int(SalaJogo.AVISO_MAX * 60) - 60, "%s: o ✕ dos quatro veio do controle, não do relógio (%d quadros)" % [id, q])
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
	_esperar(fim[0] >= TelaResultado.AVANCA_S - 0.05 and fim[0] <= TelaResultado.AVANCA_S + 0.1,
		"%s: o fim avança sozinho em 6 s, robô ou não (%.2f s)" % [id, fim[0]])
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


## A Prova de Fogo: todas as salas na ordem, sem voltar ao salão. Aqui só a
## costura: a primeira abre com "sala 1 de 9", o ✕ do veredito leva à segunda
## (a primeira acaba na hora: as salas já foram provadas jogadas), e a pausa
## desiste e volta ao salão.
func _prova_de_fogo() -> void:
	jogo._comecar_a_prova_de_fogo(false)
	await _quadros(3)
	var sala = jogo.sala
	_esperar(sala is SalaJogo and sala.id == "centelha" and sala.na_prova_de_fogo == "Prova de Fogo · sala 1 de 9",
		"Prova de Fogo: começa n'A Centelha, sala 1 de 9")
	if not sala is SalaJogo:
		return
	var q := 0
	while is_instance_valid(sala) and sala.fase == "aviso" and q < 600:
		await _quadros(1)
		q += 1
	sala.terminar()
	q = 0
	while (not jogo.sala is SalaJogo or jogo.sala.id != "viga" or jogo._trocando) and q < 900:
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


func _prova_do_relatorio() -> void:
	Forja.veredito(0, "botoes", Forja.PASSOU, Forja.NIVEL_REAGIU, "apertar ✕", "✕ chegou")
	_esperar(Forja.gravar_relatorio(), "o relatório grava")
	if pasta == "":
		return
	var arquivos := DirAccess.get_files_at(pasta)
	# o registro v2 do ritmo: os toques da prova das janelas (n 900 e 901)
	var julgado := {}
	var perdido := {}
	var ruins: Array = []
	var calibracoes: Array = []
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
	_esperar(ruins.is_empty(), "linha do tempo: toda linha é JSON (%d não: %s)" % [ruins.size(), ruins.slice(0, 2)])
	_esperar(julgado.get("julgamento", "") == "perfeito" and absf(float(julgado.get("desvio_ms", 0.0)) - 12.0) < 0.01,
		"registro: o toque julgado, com o desvio (%s)" % [julgado])
	_esperar(perdido.get("julgamento", "") == "erro" and perdido.get("perdida", false) and not perdido.has("desvio_ms"),
		"registro: a nota perdida, sem desvio (%s)" % [perdido])
	_esperar(calibracoes.any(func(ev): return int(ev.get("desvio_ms", 0)) == 80 and ev.get("transporte", "") == "simulado"),
		"registro: a calibração de +80 ms, com o transporte do controle")
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
		while (not jogo.sala is SalaJogo or jogo.sala.id != ids[i] or jogo._trocando) and q < 900:
			await _quadros(2)
			q += 2
		var sala = jogo.sala
		_esperar(sala is SalaJogo and sala.id == ids[i] and sala.na_prova_de_fogo == "Partida · sala %d de 3" % (i + 1),
			"partida: %s é a sala %d de 3" % [ids[i], i + 1])
		if not sala is SalaJogo:
			return
		q = 0
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
		_esperar(jogo.overlay == "placar" and jogo.partida.historico.size() == i + 1, "partida: o placar depois d%s" % Placar._contracao(sala.nome))
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
	await _quadros(60)
	await _aperta(0, Forja.CIRCULO)
	q = 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 600:
		await _quadros(2)
		q += 2
	_esperar(jogo.estado == "salao" and jogo.partida == null and not jogo.placar.visible, "partida: ○ no pódio volta ao salão")


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
		var c := mg.filter(func(e): return e.get("slot") == id and e.get("evento") == "comecou").size()
		var t := mg.filter(func(e): return e.get("slot") == id and e.get("evento") == "terminou" and int(e.get("vencedor", -1)) >= 0).size()
		_esperar(c >= 1 and t >= 1, "linha do tempo: %s começou e terminou com vencedor" % id)
		# vencer é fazer ponto: a sala em que ninguém soma (A Voz sem a pergunta,
		# com o treino engolindo o chamado e o mudo) acaba sempre em zero a zero
		var somou := mg.any(func(e):
			var pts = JSON.parse_string(str(e.get("pontos", "[]")))
			return e.get("slot") == id and e.get("evento") == "terminou" and pts is Array \
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
		if e.get("tipo") == "saida":
			saidas += 1
			var chave := int(e.get("lugar", -1))
			var n := int(e.get("seq", 0))
			seq_ok = seq_ok and n == int(seq.get(chave, 0)) + 1
			seq[chave] = n
	var processo := Time.get_ticks_msec() / 1000.0
	_esperar(t_ok, "o t nunca anda para trás")
	_esperar(t_antes <= processo + 0.5, "o t é o relógio de parede (%.1f s na linha, %.1f s de processo)" % [t_antes, processo])
	_esperar(lugar_ok, "toda linha com jogador tem o lugar (jogador - 1)")
	_esperar(saidas > 100 and seq_ok, "toda saída tem seq, de 1 em 1 por lugar (%d saídas)" % saidas)
	var con := linhas.filter(func(e): return e.get("tipo") == "conexao" and e.get("evento") == "conectou")
	var con_ok := con.size() >= 4
	for e in con:
		con_ok = con_ok and e.get("transporte") == "virtual" and str(e.get("firmware", "")).begins_with("0x") and e.has("vid_pid")
	_esperar(con_ok, "a conexão diz o transporte (virtual, no simulado), o firmware e o VID:PID")
	var fim := linhas.filter(func(e): return e.get("tipo") == "minigame" and e.get("evento") == "terminou")
	_esperar(not fim.is_empty() and fim.all(func(e): return e.get("pontos") is Array),
		"os pontos do minigame são um array JSON de verdade")
	# nota e toque (o Ritmo) trazem o t_musica deles como campo; a cabeça só o ganha de Forja.t_musica
	_esperar(not linhas.any(func(e): return e.has("t_musica") and not e.get("tipo") in ["nota", "toque"]),
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
				_esperar(m == null or (m is StandardMaterial3D and base is StandardMaterial3D and m.albedo_color == base.albedo_color),
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
		for id in jogo.SALAS:
			var sl = jogo.SALAS[id].new()
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
		_esperar(p.aro.material_override is ShaderMaterial and p.aro.material_override.get_shader_parameter("cor") == Tema.JOGADOR[l]
			and is_equal_approx(p.aro.material_override.get_shader_parameter("energia"), 1.5), "boneco P%d: o anel no chão é néon do lugar a 1,5" % (l + 1))
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
	_esperar(fonte.contains("Opcoes.confete(22)") and fonte.contains("0.0 if Opcoes.reduzido() else _t * 0.08")
		and fonte.contains('estado == "sala" and sala and not Opcoes.reduzido()'), "movimento: o confete, o giro do título e o tremor da câmera leem o Reduzido")
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
	tela.linha = 5
	tela.trocar(1)
	_esperar(Opcoes.movimento == 1 and tela.valor("movimento") == "Reduzido", "opções: ▶ em Movimento liga o Reduzido")
	tela.trocar(1)
	_esperar(Opcoes.movimento == 0, "opções: ▶ de novo volta ao Inteiro")
	tela.linha = 7
	Opcoes.reacoes = 0
	tela.trocar(-1)
	_esperar(Opcoes.reacoes == 2 and tela.valor("reacoes") == "Nenhuma", "opções: ◀ em Reações do começo vai para o fim")
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
		while (not jogo.sala is SalaJogo or jogo.sala.id != p.salas[i] or jogo._trocando) and q < 900:
			await _quadros(2)
			q += 2
		var sala = jogo.sala
		if not sala is SalaJogo or sala.id != p.salas[i]:
			_esperar(false, "noite: a faixa %d (%s) não abriu (estado %s, overlay %s, sala %s, trocando %s, t %s, pronto %s, robo %s, rodada %s)" % [i + 1, p.salas[i], jogo.estado, jogo.overlay, jogo.sala, jogo._trocando, jogo.placar._t, jogo.placar.pronto(), Forja.robo, jogo._robo_placar_rodada])
			return
		_esperar(is_equal_approx(jogo.env.fog_density, Tema.luz_da_secao(sala.numero(), false).densidade), "noite: a faixa %d acende no lado A" % (i + 1))
		q = 0
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
	while (not jogo.sala is SalaJogo or jogo.sala.id != p.salas[3] or jogo._trocando) and q < 600:
		await _quadros(2)
		q += 2
	_esperar(jogo.estado != "intervalo" and jogo.sala is SalaJogo and jogo.sala.id == p.salas[3], "noite: o ✕ depois dos 500 ms segue para a 4ª faixa (%s)" % jogo.sala.id)
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
