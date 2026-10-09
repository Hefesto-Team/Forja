extends Node
## A prova visual (F09): UMA partida, do título ao pódio, pelo fluxo que o
## jogador percorre, com os controles simulados e o robô de temperamento
## escolhido. A cada 2 s de jogo guarda um quadro pequeno (480×270) e os
## retângulos de todo texto desenhado; no fim monta a prancha (grade de 6
## colunas, a hora embaixo de cada quadro) e roda as checagens sobre TODOS os
## quadros e sobre a linha do tempo. Sai com erro se alguma reprovou.
##
## Precisa de janela (Xvfb com OpenGL por software): o `--headless` não devolve
## imagem. Quem junta as quatro partidas é tests/prova_visual.sh.
##
##   xvfb-run -a godot --rendering-driver opengl3 --path godot res://testes/prova_visual.tscn \
##     -- --simular=4 --robo=bom --semente=7 --saida=<pasta> --salas=5 --indice=1 [--cabo]
##
## `--autoteste` não joga: confere que cada checagem reprova o seu defeito
## plantado e aprova o quadro limpo (roda sem janela).
##
## Aparência (luz, cor, brilho, arte) não se aprova aqui: o renderizador por
## software não é a placa de vídeo. A prova confere disposição.

const AMOSTRA_S := 2.0
const TELA := Vector2(1920, 1080)
const COLUNAS := 6
const QUADRO := Vector2i(480, 270)
const CELULA_A := 290
const POR_PAGINA := 60
const LIMITE_S := 5400.0  ## o teto de uma partida, em s de jogo

var jogo: Node
var t := 0.0
var _proximo := 1.0  ## o primeiro quadro um segundo depois de abrir: o contador de quadros ainda não andou
var saida := ""
var indice := 1
var n_salas := 5
var com_cabo := false
var quadros: Array = []
var textos: Array = []
var observacoes: Array = []
var falhas: Array = []
var falhas_da_prancha: Array = []   ## as da prancha cinza da montagem: entram mesmo com o roteiro inteiro
var _cabo_fora := false
var _batida := 30.0


func _arg(nome: String, padrao: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a == "--" + nome:
			return "1"
		if a.begins_with("--" + nome + "="):
			return a.substr(nome.length() + 3)
	return padrao


func _ready() -> void:
	saida = _arg("saida", OS.get_user_data_dir())
	DirAccess.make_dir_recursive_absolute(saida)
	if _arg("autoteste", "") != "":
		get_tree().quit(_autoteste())
		return
	indice = int(_arg("indice", "1"))
	n_salas = int(_arg("salas", "5"))
	com_cabo = _arg("cabo", "") != ""
	if DisplayServer.get_name() == "headless":
		printerr("FAIL a prova visual precisa de janela (xvfb-run), o --headless não devolve imagem")
		get_tree().quit(2)
		return
	Desenho._coletar = "memoria"  # colhe cada frase desenhada (as minúsculas)
	jogo = load("res://scenes/main.tscn").instantiate()
	add_child(jogo)
	var ok := await _roteiro()
	await _fechar(ok)


# ------------------------------------------------------------ o relógio --

## Um quadro de jogo: espera o quadro, anda o relógio, observa e, de 2 em 2 s,
## fotografa. TODA espera do roteiro passa por aqui.
func _quadro() -> void:
	await get_tree().process_frame
	t += get_process_delta_time()
	_observar()
	var depurar := OS.get_environment("PV_DEBUG") != "" and Engine.get_process_frames() % 120 == 0
	if t >= _batida or depurar:
		if t >= _batida:
			_batida += 30.0
		print("  %s de jogo (%d s de relógio), %s, %s" % [ChecagensVisuais.hora(t), Time.get_ticks_msec() / 1000, jogo.estado,
			str(jogo.sala.id) if jogo.sala is SalaJogo else "-"])
	if t >= _proximo:
		_proximo += AMOSTRA_S
		await _fotografar()


func _esperar_s(s: float) -> void:
	var fim := t + s
	while t < fim:
		await _quadro()


## Espera a condição, até `max_s` s de jogo. Devolve se ela veio.
func _ate(cond: Callable, max_s: float, o_que: String) -> bool:
	var fim := t + max_s
	while not cond.call():
		if t > fim:
			falhas.append("o roteiro não chegou a «%s» em %.0f s" % [o_que, max_s])
			return false
		await _quadro()
	return true


func _aperta(sim: int, botao: int) -> void:
	Forja.ctl.simulador_botao(sim, botao, true)
	await _quadro()
	await _quadro()
	Forja.ctl.simulador_botao(sim, botao, false)
	await _quadro()


func _observar() -> void:
	var sala = jogo.sala
	if sala is SalaJogo and sala.fase == "jogo" and not sala.treinando and sala.duracao > 0.0:
		observacoes.append({"t": t, "slot": sala.id, "fase": "jogo", "resta": float(sala.tempo_que_resta())})
	elif sala is SalaJogo:
		observacoes.append({"t": t, "slot": sala.id, "fase": str(sala.fase), "resta": -1.0})


# ------------------------------------------------------------ o roteiro --

func _roteiro() -> bool:
	var n: int = Forja.simular
	await _esperar_s(1.2)
	if jogo.estado != "titulo":
		falhas.append("o jogo não abriu no título (%s)" % jogo.estado)
		return false
	# a prancha do título (G01): o título, o PLAY com o cassete pela metade e as quatro armaduras acesas
	var do_titulo: Array = [null, null, null]
	do_titulo[0] = await _foto_solta()
	# o ✕ do P1 é o PLAY; da introdução ao salão, quem aperta é o robô do fluxo (main.gd _robo)
	await _aperta(0, Forja.CRUZ)
	# a descida é cúbica, 720 px em 4 batidas: a metade (360 px) cai em 4 × ∛0,5 ≈ 3,17 batidas
	await _ate(func() -> bool: return jogo.estado != "titulo" or (jogo.titulo.play_desde >= 0.0
		and jogo.titulo.batidas - jogo.titulo.play_desde >= 3.17), 10.0, "o cassete pela metade")
	if jogo.estado == "titulo":
		do_titulo[1] = await _foto_solta()
	if not await _ate(func() -> bool: return jogo.estado == "intro", 10.0, "a introdução"):
		return false
	await _ate(func() -> bool: return jogo.estado != "intro" or jogo.intro.t >= 17.5, 30.0, "as quatro armaduras acesas")
	if jogo.estado == "intro":
		do_titulo[2] = await _foto_solta()
	_prancha_do_titulo(do_titulo)
	if not await _ate(func() -> bool: return jogo.estado == "lobby", 40.0, "o lobby"):
		return false
	await _esperar_s(1.0)
	await _prancha_da_montagem_cinza()
	if not await _ate(func() -> bool: return jogo.estado == "salao" and not jogo._trocando, 40.0, "o salão"):
		return false
	await _esperar_s(1.5)
	if not await _ir_ate_a_bigorna():
		return false
	await _aperta(0, Forja.QUADRADO)  # □: escolher a partida
	if not await _ate(func() -> bool: return jogo.overlay == "partida", 5.0, "a escolha da partida"):
		return false
	await _esperar_s(0.8)
	if n_salas == 3:
		await _aperta(0, Forja.ESQUERDA)  # 5 → 3 salas
		await _esperar_s(0.4)
	await _aperta(0, Forja.CRUZ)
	if not await _ate(func() -> bool: return jogo.partida != null, 8.0, "a partida"):
		return false
	var salas_feitas := 0
	var fim := t + LIMITE_S
	while not (jogo.estado == "podio" and not jogo._trocando and jogo.placar._t > 3.0):
		if t > fim:
			falhas.append("a partida passou de %.0f s de jogo sem chegar ao pódio" % LIMITE_S)
			return false
		_cabo()
		await _quadro()
	await _esperar_s(AMOSTRA_S * 3.0)  # o pódio, uns quadros
	return true


## A partida de um jogador que perde o cabo no meio do segundo minigame e o
## recupera no terceiro.
func _cabo() -> void:
	if not com_cabo or jogo.partida == null:
		return
	var feitos: int = jogo.partida.historico.size()
	var sala = jogo.sala
	if not sala is SalaJogo:
		return
	if feitos == 1 and not _cabo_fora and sala.fase == "jogo" and sala.t_fase > 20.0:
		_cabo_fora = true
		Forja.ctl.simulador_cabo(0, false)
	elif feitos == 2 and _cabo_fora and sala.t_fase > 5.0:
		_cabo_fora = false
		Forja.ctl.simulador_cabo(0, true)


## O P1 anda até o pé da bigorna pelo analógico, olhando a posição (o mundo é o
## do controle: LX é x, LY é z).
func _ir_ate_a_bigorna() -> bool:
	var p = jogo.jogadores[0]
	var centro: Vector3 = jogo.salao.bigorna.global_position
	var fim := t + 40.0
	while Vector2(p.global_position.x - centro.x, p.global_position.z - centro.z).length() > 2.4:
		if t > fim:
			falhas.append("o P1 não chegou à bigorna em 40 s (parou em %s)" % [p.global_position])
			Forja.ctl.simulador_eixo(0, Forja.LX, 0.0)
			Forja.ctl.simulador_eixo(0, Forja.LY, 0.0)
			return false
		var d := Vector2(centro.x - p.global_position.x, centro.z - p.global_position.z).normalized()
		Forja.ctl.simulador_eixo(0, Forja.LX, d.x)
		Forja.ctl.simulador_eixo(0, Forja.LY, d.y)
		await _quadro()
	Forja.ctl.simulador_eixo(0, Forja.LX, 0.0)
	Forja.ctl.simulador_eixo(0, Forja.LY, 0.0)
	await _esperar_s(0.6)
	return true


# ------------------------------------------------------------ os quadros --

func _topo() -> Node:
	match str(jogo.overlay):
		"placar": return jogo.placar
		"pausa": return jogo.pausa
		"partida": return jogo.escolha
		"opcoes": return jogo.tela_opcoes
		"creditos": return jogo.creditos
		"livro": return jogo.livro
		"diagnostico": return jogo.diagnostico
	if jogo.resultado.visible:
		return jogo.resultado
	return null


func _redesenhar(no: Node) -> void:
	if no is CanvasItem:
		(no as CanvasItem).queue_redraw()
	for f in no.get_children():
		_redesenhar(f)


func _fotografar() -> void:
	Desenho.retangulos.clear()
	Desenho.coletar_retangulos = true
	_redesenhar(jogo)
	await RenderingServer.frame_post_draw
	Desenho.coletar_retangulos = false
	var img := get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		falhas.append("o Godot não devolveu imagem em %s (rode com janela, num Xvfb)" % ChecagensVisuais.hora(t))
		return
	var sala = jogo.sala
	var id := str(sala.id) if sala is SalaJogo else ""
	var estado := str(jogo.estado)
	var topo := _topo()
	var frases: Array = []
	# um nó que desenhou em mais de um quadro durante a coleta vale pelo último: o
	# que está na tela é o último desenho, e dois estados do mesmo texto («Nenhum
	# controle» e «4 controles») não se encavalam, um só foi apagado pelo outro; nem o
	# cartão que desliza, desenhado duas vezes no mesmo quadro
	var ultimo := {}
	for r in Desenho.retangulos:
		ultimo[r.no] = maxi(int(ultimo.get(r.no, -1)), int(r.quadro))
	if not jogo._trocando:
		for r in Desenho.retangulos:
			if int(r.quadro) != int(ultimo[r.no]):
				continue
			var no = instance_from_id(int(r.no))
			if topo != null and not (no == topo or (no is Node and topo.is_ancestor_of(no))):
				continue
			r.contraste = _contraste(img, r.rect, r.cor)
			frases.append(r)
	Desenho.retangulos.clear()
	# o relógio que a tela mostra também não sobe (a conta da sala é outra régua)
	if sala is SalaJogo and sala.fase == "jogo" and not sala.treinando:
		observacoes.append_array(ChecagensVisuais.relogios_na_tela(t, "%s#%d" % [id, sala.get_instance_id()], frases))
	var peq := ChecagensVisuais.pequeno(img)
	var quadro := img.duplicate() as Image
	quadro.convert(Image.FORMAT_RGB8)
	quadro.resize(QUADRO.x, QUADRO.y, Image.INTERPOLATE_BILINEAR)
	quadros.append({"t": t, "estado": estado, "sala": id, "pausa": jogo.overlay == "pausa" or estado == "podio",
		"trocando": bool(jogo._trocando), "pq": peq, "img": quadro})
	textos.append({"t": t, "estado": estado, "sala": id, "frases": frases})


## A razão de contraste entre a cor do texto e o fundo ao redor dele, lido nos
## pixels de verdade (um anel de 3 px fora do retângulo). -1: não deu para medir.
func _contraste(img: Image, r: Rect2, cor: Color) -> float:
	if cor.a < 0.3:
		return -1.0
	var k := Vector2(img.get_size()) / TELA
	var fora := r.grow(maxf(3.0, 2.0 / k.x))  # ao menos 2 pixels da imagem para fora do texto
	var pontos: Array = []
	for i in 8:
		var f := (i + 0.5) / 8.0
		pontos.append(Vector2(fora.position.x + fora.size.x * f, fora.position.y))
		pontos.append(Vector2(fora.position.x + fora.size.x * f, fora.end.y))
		pontos.append(Vector2(fora.position.x, fora.position.y + fora.size.y * f))
		pontos.append(Vector2(fora.end.x, fora.position.y + fora.size.y * f))
	var luzes: Array = []
	for p in pontos:
		var q := Vector2i(int(p.x * k.x), int(p.y * k.y))
		if q.x < 0 or q.y < 0 or q.x >= img.get_width() or q.y >= img.get_height():
			continue
		luzes.append(ChecagensVisuais.luminancia(img.get_pixelv(q)))
	if luzes.size() < 8:
		return -1.0
	luzes.sort()
	var fundo := float(luzes[luzes.size() / 2])
	# o texto esmaecido (alfa < 1) chega ao olho misturado com o fundo
	var luz_texto := ChecagensVisuais.luminancia(cor) * cor.a + fundo * (1.0 - cor.a)
	return ChecagensVisuais.razao(luz_texto, fundo)


# ------------------------------------------------------ o fim: as checagens --

func _linha_do_tempo() -> Array:
	var linhas: Array = []
	var pasta: String = Forja.pasta_relatorios
	for f in DirAccess.get_files_at(pasta):
		if f.begins_with("linha-do-tempo-") and f.ends_with(".jsonl"):
			for s in FileAccess.get_file_as_string(pasta.path_join(f)).split("\n", false):
				var e = JSON.parse_string(s)
				if e is Dictionary:
					linhas.append(e)
	return linhas


func _fechar(roteiro_ok: bool) -> void:
	Forja.gravar_relatorio()
	var eventos := _linha_do_tempo()
	var relato: Array = []
	var reprovados: Array = []
	var avisos: Array = []
	relato.append("partida %d: %d jogador(es), robô %s, %d salas%s, %d quadros em %s de jogo" % [indice, Forja.simular,
		Forja.robo_temperamento if Forja.robo_temperamento != "" else "padrão", n_salas, ", com o cabo que cai" if com_cabo else "",
		quadros.size(), ChecagensVisuais.hora(t)])
	relato.append("")
	var todos: Array = []
	if not roteiro_ok:
		todos.append_array(falhas)
	todos.append_array(falhas_da_prancha)
	todos.append_array(ChecagensVisuais.tela_parada(quadros))
	todos.append_array(ChecagensVisuais.telas_vazias(quadros))
	for tx in textos:
		todos.append_array(ChecagensVisuais.texto(float(tx.t), tx.frases, TELA))
	todos.append_array(ChecagensVisuais.relogio_sobe(observacoes))
	todos.append_array(ChecagensVisuais.fim_sem_vencedor(eventos))
	todos.append_array(ChecagensVisuais.minuscula(Desenho._coletados.keys()))
	var resumo := ChecagensVisuais.resumir(todos)  # o mesmo defeito, parado na tela, conta uma vez
	reprovados = resumo.linhas
	avisos.append_array(ChecagensVisuais.desempenho(eventos))
	if reprovados.is_empty():
		relato.append("REPROVADAS: nenhuma")
	else:
		relato.append("REPROVADAS (%d defeitos distintos, %d achados nos quadros):" % [reprovados.size(), todos.size()])
		for r in reprovados:
			relato.append("  FAIL " + str(r))
	relato.append("")
	relato.append("AVISOS (quadros por segundo, só avisa; abaixo de %d no renderizador por software é de esperar): %d" % [int(ChecagensVisuais.FPS_AVISO), avisos.size()])
	for a in avisos:
		relato.append("  aviso " + str(a))
	var marcados := _marcar(resumo.primeiros)
	var paginas := _pranchas(marcados)
	relato.append("")
	relato.append("pranchas: " + ", ".join(paginas))
	var arq := FileAccess.open(saida.path_join("checagens-%d.txt" % indice), FileAccess.WRITE)
	arq.store_string("\n".join(relato) + "\n")
	arq.close()
	print("\n".join(relato))
	get_tree().quit(1 if not reprovados.is_empty() else 0)


## Os quadros que uma reprovação cita pela hora, para a prancha marcar.
func _marcar(reprovados: Array) -> Dictionary:
	var m := {}
	var re := RegEx.create_from_string("(\\d\\d):(\\d\\d)")
	for r in reprovados:
		for achado in re.search_all(str(r)):
			var s := float(int(achado.get_string(1)) * 60 + int(achado.get_string(2)))
			var melhor := -1
			var d_melhor := 1e9
			for i in quadros.size():
				var d := absf(float(quadros[i].t) - s)
				if d < d_melhor:
					d_melhor = d
					melhor = i
			if melhor >= 0 and d_melhor < AMOSTRA_S * 1.5:
				m[melhor] = true
	return m


# ------------------------------------------------------------ a prancha --

const DIGITOS := {
	"0": [7, 5, 5, 5, 7], "1": [2, 6, 2, 2, 7], "2": [7, 1, 7, 4, 7], "3": [7, 1, 7, 1, 7], "4": [5, 5, 7, 1, 1],
	"5": [7, 4, 7, 1, 7], "6": [7, 4, 7, 5, 7], "7": [7, 1, 1, 1, 1], "8": [7, 5, 7, 5, 7], "9": [7, 5, 7, 1, 7],
	":": [0, 2, 0, 2, 0], "-": [0, 0, 7, 0, 0],
}


## Escreve `texto` (dígitos e dois-pontos) em pixels, `escala` vezes maior.
static func escrever(img: Image, x: int, y: int, texto: String, escala: int, cor: Color) -> void:
	for ch in texto:
		var linhas: Array = DIGITOS.get(ch, DIGITOS["-"])
		for ly in 5:
			for lx in 3:
				if (int(linhas[ly]) >> (2 - lx)) & 1:
					img.fill_rect(Rect2i(x + lx * escala, y + ly * escala, escala, escala), cor)
		x += 4 * escala


## As pranchas: 6 colunas, `POR_PAGINA` quadros cada (o PNG não passa de 16384
## px de altura). A primeira é prancha-<n>.png; as outras, prancha-<n>-2.png...
func _pranchas(marcados: Dictionary) -> Array:
	var nomes: Array = []
	var paginas := maxi(1, ceili(float(quadros.size()) / POR_PAGINA))
	for pg in paginas:
		var de := pg * POR_PAGINA
		var ate := mini(quadros.size(), de + POR_PAGINA)
		var linhas := maxi(1, ceili(float(ate - de) / COLUNAS))
		var prancha := Image.create(COLUNAS * QUADRO.x, linhas * CELULA_A, false, Image.FORMAT_RGB8)
		prancha.fill(Color(0.07, 0.07, 0.09))
		for i in range(de, ate):
			var k := i - de
			var x := (k % COLUNAS) * QUADRO.x
			var y := (k / COLUNAS) * CELULA_A
			prancha.blit_rect(quadros[i].img, Rect2i(Vector2i.ZERO, QUADRO), Vector2i(x, y))
			var faixa := Color(0.8, 0.1, 0.1) if marcados.has(i) else Color(0.2, 0.2, 0.26)
			prancha.fill_rect(Rect2i(x, y + QUADRO.y, QUADRO.x, CELULA_A - QUADRO.y), faixa)
			escrever(prancha, x + 8, y + QUADRO.y + 3, ChecagensVisuais.hora(float(quadros[i].t)), 3, Color.WHITE)
		var nome := "prancha-%d.png" % indice if pg == 0 else "prancha-%d-%d.png" % [indice, pg + 1]
		prancha.save_png(saida.path_join(nome))
		nomes.append(nome)
	return nomes


# ------------------------------------------------------------ o autoteste --

## Cada checagem reprova o defeito plantado e aprova o quadro limpo.
func _autoteste() -> int:
	var erros := [0]
	var ok := func(cond: bool, msg: String) -> void:
		print(("ok   " if cond else "FAIL ") + msg)
		if not cond:
			erros[0] += 1
	var limpo := [
		{"frase": "Pontos", "rect": Rect2(200, 200, 300, 40), "tam": 32, "cor": Color.WHITE, "contraste": 9.0},
		{"frase": "Tempo", "rect": Rect2(200, 260, 300, 40), "tam": 32, "cor": Color.WHITE, "contraste": 9.0},
	]
	ok.call(ChecagensVisuais.texto(10.0, limpo, TELA).is_empty(), "texto: o quadro limpo passa")
	var encavalado := limpo.duplicate(true)
	encavalado[1].rect = Rect2(200, 215, 300, 40)
	ok.call(ChecagensVisuais.texto(10.0, encavalado, TELA).size() == 1, "texto: dois textos encavalados reprovam")
	var fora := limpo.duplicate(true)
	fora[0].rect = Rect2(1800, 200, 300, 40)
	ok.call(ChecagensVisuais.texto(10.0, fora, TELA).size() == 1, "texto: um texto fora da área segura reprova")
	var miudo := limpo.duplicate(true)
	miudo[0].tam = 24
	ok.call(ChecagensVisuais.texto(10.0, miudo, TELA).size() == 1, "texto: a letra de 24 px reprova")
	var pouco := limpo.duplicate(true)
	pouco[0].contraste = 1.4
	ok.call(ChecagensVisuais.texto(10.0, pouco, TELA).size() == 1, "texto: o contraste de 1,4:1 reprova")
	var contador := limpo.duplicate(true)
	contador[0].frase = "Pontos 80"
	contador[1].frase = "Pontos 81"
	contador[1].rect = contador[0].rect
	ok.call(ChecagensVisuais.texto(10.0, contador, TELA).is_empty(), "texto: o contador com o número trocado no mesmo lugar passa")
	contador[1].frase = "Tempo 81"
	ok.call(ChecagensVisuais.texto(10.0, contador, TELA).size() == 1, "texto: duas frases diferentes no mesmo lugar reprovam")
	var linhas := limpo.duplicate(true)
	linhas[0].frase = "Brasa · vida 3"
	linhas[1].frase = "Brasa · vida 2"
	linhas[1].rect = Rect2(200, 212, 300, 40)
	ok.call(ChecagensVisuais.texto(10.0, linhas, TELA).size() == 1, "texto: duas linhas iguais exceto pelo número, uma sobre a outra, reprovam")
	linhas[1].frase = "Brasa · vida 3"
	ok.call(ChecagensVisuais.texto(10.0, linhas, TELA).size() == 1, "texto: a mesma frase duas vezes, uma sobre a outra, reprova")
	linhas[1].rect = Rect2(202, 202, 300, 40)
	ok.call(ChecagensVisuais.texto(10.0, linhas, TELA).is_empty(), "texto: a mesma frase deslocada 2 px (a sombra) passa")
	var sobe := [
		{"t": 1.0, "slot": "centelha", "fase": "jogo", "resta": 80.0},
		{"t": 2.0, "slot": "centelha", "fase": "jogo", "resta": 79.0},
		{"t": 3.0, "slot": "centelha", "fase": "jogo", "resta": 90.0},
	]
	ok.call(ChecagensVisuais.relogio_sobe(sobe).size() == 1, "relógio: um relógio que sobe reprova")
	sobe[2].resta = 78.0
	ok.call(ChecagensVisuais.relogio_sobe(sobe).is_empty(), "relógio: o relógio que desce passa")
	var na_tela: Array = []
	for par in [[10.0, "80 s"], [12.0, "78 s"], [14.0, "81 s"]]:
		na_tela.append_array(ChecagensVisuais.relogios_na_tela(par[0], "viga#1", [{"frase": par[1], "rect": Rect2(700, 170, 80, 30)}]))
	ok.call(ChecagensVisuais.relogio_sobe(na_tela).size() == 1, "relógio: o relógio da tela que sobe («78 s», «81 s») reprova")
	na_tela.clear()
	for par in [[10.0, "Brasa 0 × 0 Maré · 1:30"], [12.0, "Brasa 1 × 0 Maré · 1:28"], [14.0, "Brasa 1 × 0 Maré · 1:26"]]:
		na_tela.append_array(ChecagensVisuais.relogios_na_tela(par[0], "prova#1", [{"frase": par[1], "rect": Rect2(90, 172, 300, 30)}]))
	ok.call(na_tela.size() == 3 and ChecagensVisuais.relogio_sobe(na_tela).is_empty(), "relógio: o «1:30» da tela que desce passa")
	var sem := [{"tipo": "minigame", "evento": "terminou", "slot": "viga", "pontos": [1, 2]}]
	ok.call(ChecagensVisuais.fim_sem_vencedor(sem).size() == 1, "fim: um minigame sem vencedor reprova")
	sem[0]["vencedor"] = -1
	ok.call(ChecagensVisuais.fim_sem_vencedor(sem).size() == 1, "fim: o vencedor -1 (ninguém) reprova")
	sem[0]["vencedor"] = 1
	ok.call(ChecagensVisuais.fim_sem_vencedor(sem).is_empty(), "fim: com vencedor passa")
	ok.call(ChecagensVisuais.minuscula(["Pontos", "tempo"]).size() == 1, "minúscula: «tempo» reprova")
	ok.call(ChecagensVisuais.minuscula(["Pontos", "3 salas", "✕ Continuar"]).is_empty(), "minúscula: maiúscula, número e símbolo passam")
	var cinza := PackedByteArray()
	cinza.resize(ChecagensVisuais.PQ_L * ChecagensVisuais.PQ_A * 3)
	cinza.fill(90)
	var parados: Array = []
	for i in 5:
		parados.append({"t": i * 2.0, "estado": "sala", "sala": "viga", "pausa": false, "pq": cinza})
	ok.call(ChecagensVisuais.tela_parada(parados).size() == 1, "parada: cinco quadros iguais seguidos reprovam")
	for q in parados:
		q.pausa = true
	ok.call(ChecagensVisuais.tela_parada(parados).is_empty(), "parada: na pausa passa")
	ok.call(ChecagensVisuais.tela_vazia({"pq": cinza}), "vazia: um quadro de uma cor só reprova")
	ok.call(ChecagensVisuais.telas_vazias([{"t": 2.0, "estado": "sala", "sala": "viga", "trocando": false, "pq": cinza}]).size() == 1
		and ChecagensVisuais.telas_vazias([{"t": 2.0, "estado": "sala", "sala": "viga", "trocando": true, "pq": cinza}]).is_empty(),
		"vazia: o preto da troca de tela passa, o de fora dela reprova")
	var riscado := cinza.duplicate()
	for i in riscado.size() / 2:
		riscado[i] = 250 if i % 2 == 0 else 10
	ok.call(not ChecagensVisuais.tela_vazia({"pq": riscado}), "vazia: um quadro com conteúdo passa")
	var lento := [{"tipo": "desempenho", "slot": "viga", "fps_min": 31.0, "fps_media": 44.0},
		{"tipo": "desempenho", "slot": "prova", "fps_min": 59.0, "fps_media": 60.0}]
	ok.call(ChecagensVisuais.desempenho(lento).size() == 1, "desempenho: só o minigame abaixo de 55 quadros por segundo avisa")
	var iguais := ["00:12: «Runa 3 de 17 · 0» com letra de 28 px (o mínimo é 30)",
		"00:14: «Runa 4 de 17 · 9» com letra de 28 px (o mínimo é 30)", "00:14: «Pontos» com letra de 24 px (o mínimo é 30)"]
	var res := ChecagensVisuais.resumir(iguais)
	ok.call(res.linhas.size() == 2 and res.primeiros.size() == 2, "resumo: o mesmo defeito parado conta uma vez, o outro conta à parte")
	var colado := limpo.duplicate(true)
	colado[0].rect = Rect2(96, 51, 300, 40)
	ok.call(ChecagensVisuais.texto(10.0, colado, TELA).is_empty(), "texto: o rente à área segura, com a folga da linha, passa")
	# a coleta do retângulo: a caixa da tinta, de uma linha, com o tamanho da letra
	var no := Node2D.new()
	add_child(no)
	Desenho.retangulos.clear()
	Desenho.anotar(no, Vector2(100, 300), "Hefesto", ThemeDB.fallback_font, 100, Color.WHITE)
	var r: Rect2 = Desenho.retangulos[0].rect
	ok.call(absf(r.size.y - 100.0) < 0.5 and absf(r.position.y - 222.0) < 0.5 and r.size.x > 100.0 and absf(r.position.x - 100.0) < 0.5,
		"coleta: o retângulo de uma linha é a caixa da tinta (%s)" % [r])
	# um desenho do nó (o texto e a sombra) é um só; o desenho seguinte do mesmo nó,
	# no mesmo quadro (o sinal `draw`), é outro, e só o último vale na tela
	Desenho.retangulos.clear()
	Desenho.anotar(no, Vector2(100, 300), "Hefesto", ThemeDB.fallback_font, 40, Color.WHITE)
	Desenho.anotar(no, Vector2(102, 302), "Hefesto", ThemeDB.fallback_font, 40, Color.BLACK)
	no.draw.emit()
	Desenho.anotar(no, Vector2(131, 300), "Hefesto", ThemeDB.fallback_font, 40, Color.WHITE)
	var d: Array = Desenho.retangulos.map(func(x): return int(x.quadro))
	ok.call(d[0] == d[1] and d[2] != d[1],
		"coleta: o mesmo nó desenhado de novo é outro desenho (%s)" % [d])
	Desenho.retangulos.clear()
	no.queue_free()
	print("autoteste da prova visual: %s" % ("ok" if erros[0] == 0 else "%d falha(s)" % erros[0]))
	return 0 if erros[0] == 0 else 1


## Um quadro da tela agora, do tamanho dos da prancha, fora da amostra de 2 em 2 s
## (não entra nas checagens). null: o Godot não devolveu imagem.
func _foto_solta() -> Image:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		return null
	var quadro := img.duplicate() as Image
	quadro.convert(Image.FORMAT_RGB8)
	quadro.resize(QUADRO.x, QUADRO.y, Image.INTERPOLATE_BILINEAR)
	return quadro


## A prancha do título (G01): o título, o PLAY com o cassete pela metade e a
## introdução com as quatro armaduras acesas, lado a lado (1, 2 e 3 embaixo de
## cada um). Um quadro que não veio
## (o roteiro passou do ponto) fica vermelho e entra nas falhas.
func _prancha_do_titulo(fotos: Array) -> void:
	var rotulos := ["titulo", "play", "armaduras"]
	var prancha := Image.create(3 * QUADRO.x, CELULA_A, false, Image.FORMAT_RGB8)
	prancha.fill(Color(0.07, 0.07, 0.09))
	for i in 3:
		var x := i * QUADRO.x
		var f: Image = fotos[i] if i < fotos.size() else null
		if f != null:
			prancha.blit_rect(f, Rect2i(Vector2i.ZERO, QUADRO), Vector2i(x, 0))
		else:
			prancha.fill_rect(Rect2i(x, 0, QUADRO.x, QUADRO.y), Color(0.6, 0.1, 0.1))
			falhas.append("a prancha do título ficou sem o quadro «%s»" % rotulos[i])
		escrever(prancha, x + 8, QUADRO.y + 3, str(i + 1), 3, Color.WHITE)
	var nome := "prancha-titulo.png" if indice == 1 else "prancha-titulo-%d.png" % indice
	prancha.save_png(saida.path_join(nome))


## A prancha cinza da montagem (G08): o quadro da montagem sem cor, e embaixo
## cada cavaleiro reduzido a 64 px de altura, para o time apontar, sem a cor,
## qual parte é a cabeça, o tronco e as pernas, e anotar no diário.
func _prancha_da_montagem_cinza() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		falhas_da_prancha.append("a prancha cinza da montagem ficou sem imagem")
		return
	img.convert(Image.FORMAT_L8)
	img.convert(Image.FORMAT_RGB8)
	var cam := get_viewport().get_camera_3d()
	var tiras: Array = []
	# a posição na tela vem no tamanho do desenho (1920x1080); a imagem é a da janela
	var esc := Vector2(img.get_size()) / get_viewport().get_visible_rect().size
	if cam != null:
		for p in jogo.jogadores:
			var pes := cam.unproject_position(p.global_position) * esc
			var cab := cam.unproject_position(p.global_position + Vector3.UP * 1.6) * esc
			var alto := absf(pes.y - cab.y)
			var r := Rect2i(Vector2i(int(pes.x - alto * 0.5), int(cab.y - alto * 0.05)), Vector2i(int(alto), int(alto * 1.1)))
			r = r.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
			if r.size.x < 8 or r.size.y < 8:
				continue
			var tira := img.get_region(r)
			tira.resize(maxi(8, int(64.0 * r.size.x / r.size.y)), 64, Image.INTERPOLATE_BILINEAR)
			tiras.append(tira)
	if tiras.size() != jogo.jogadores.size():
		falhas_da_prancha.append("a prancha cinza da montagem achou %d dos %d cavaleiros" % [tiras.size(), jogo.jogadores.size()])
	var quadro := img.duplicate() as Image
	quadro.resize(QUADRO.x, QUADRO.y, Image.INTERPOLATE_BILINEAR)
	var prancha := Image.create(QUADRO.x, QUADRO.y + 64 + 12, false, Image.FORMAT_RGB8)
	prancha.fill(Color(0.07, 0.07, 0.09))
	prancha.blit_rect(quadro, Rect2i(Vector2i.ZERO, QUADRO), Vector2i.ZERO)
	var x := 8
	for t in tiras:
		prancha.blit_rect(t, Rect2i(Vector2i.ZERO, t.get_size()), Vector2i(x, QUADRO.y + 6))
		x += t.get_width() + 16
	var nome := "prancha-montagem-cinza.png" if indice == 1 else "prancha-montagem-cinza-%d.png" % indice
	prancha.save_png(saida.path_join(nome))
