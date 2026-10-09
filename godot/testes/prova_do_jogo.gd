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
	Desenho._coletar = "memoria"  # colhe cada frase desenhada (F02, F07)
	jogo = load("res://scenes/main.tscn").instantiate()
	add_child(jogo)
	await _prova_do_percurso()
	await _prova_do_motor_que_vence()
	await _prova_do_aviso_sozinho()
	await _prova_do_relatorio()
	await _prova_de_fogo()
	_prova_das_contas_da_partida()
	await _prova_da_partida()
	_prova_do_modo()
	_prova_das_frases()
	_prova_das_maiusculas()
	_prova_da_identidade()
	_prova_das_sensacoes()
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
			var vibra_fora: bool = codigo.contains("Forja.vibrar(") and not arq.ends_with("/forja.gd")
			if vibra_fora or codigo.contains("start_joy_vibration") or codigo.contains(".intensidade("):
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
	jogo._entrar_na_sala("centelha", false)
	await _quadros(2)
	var sala = jogo.sala
	# segura o ✕ do robô: nenhum lugar fica pronto no aviso
	var robo := Forja.robo
	Forja.robo = false
	var q := 0
	while is_instance_valid(sala) and sala.fase == "aviso" and q < 900:
		await _quadros(1)
		q += 1
	Forja.robo = robo
	_esperar(is_instance_valid(sala) and sala.fase == "jogo" and q >= int(SalaJogo.AVISO_MAX * 60) - 2,
		"o aviso começa sozinho em 8 s (%d quadros)" % q)
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
