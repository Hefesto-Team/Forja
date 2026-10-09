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
var _proximo := 0.0
var saida := ""
var indice := 1
var n_salas := 5
var com_cabo := false
var quadros: Array = []
var textos: Array = []
var observacoes: Array = []
var falhas: Array = []
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
		observacoes.append({"t": t, "slot": sala.id, "fase": "jogo", "resta": float(sala.duracao) - float(sala.t_jogo)})
	elif sala is SalaJogo:
		observacoes.append({"t": t, "slot": sala.id, "fase": str(sala.fase), "resta": -1.0})


# ------------------------------------------------------------ o roteiro --

func _roteiro() -> bool:
	var n: int = Forja.simular
	await _esperar_s(1.2)
	if jogo.estado != "titulo":
		falhas.append("o jogo não abriu no título (%s)" % jogo.estado)
		return false
	# antes do robô de fluxo (G01, G02), o roteiro aperta ✕ de cada lugar, com
	# intervalo, como um jogador: ninguém entra por código
	await _aperta(0, Forja.CRUZ)
	if not await _ate(func() -> bool: return jogo.estado == "lobby", 10.0, "o lobby"):
		return false
	await _esperar_s(0.6)
	for s in n:
		await _aperta(s, Forja.CRUZ)
		await _esperar_s(0.4)
	await _esperar_s(0.8)
	for s in n:
		await _aperta(s, Forja.CRUZ)  # ✕ de novo: pronto
		await _esperar_s(0.4)
	if not await _ate(func() -> bool: return jogo.estado == "salao" and not jogo._trocando, 25.0, "o salão"):
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
	# controle» e «4 controles») não se encavalam, um só foi apagado pelo outro
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
	var peq := ChecagensVisuais.pequeno(img)
	var quadro := img.duplicate() as Image
	quadro.convert(Image.FORMAT_RGB8)
	quadro.resize(QUADRO.x, QUADRO.y, Image.INTERPOLATE_BILINEAR)
	quadros.append({"t": t, "estado": estado, "sala": id, "pausa": jogo.overlay == "pausa" or estado == "podio", "pq": peq, "img": quadro})
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
	var sobe := [
		{"t": 1.0, "slot": "centelha", "fase": "jogo", "resta": 80.0},
		{"t": 2.0, "slot": "centelha", "fase": "jogo", "resta": 79.0},
		{"t": 3.0, "slot": "centelha", "fase": "jogo", "resta": 90.0},
	]
	ok.call(ChecagensVisuais.relogio_sobe(sobe).size() == 1, "relógio: um relógio que sobe reprova")
	sobe[2].resta = 78.0
	ok.call(ChecagensVisuais.relogio_sobe(sobe).is_empty(), "relógio: o relógio que desce passa")
	var sem := [{"tipo": "minigame", "evento": "terminou", "slot": "viga", "pontos": [1, 2]}]
	ok.call(ChecagensVisuais.fim_sem_vencedor(sem).size() == 1, "fim: um minigame sem vencedor reprova")
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
	Desenho.retangulos.clear()
	no.queue_free()
	print("autoteste da prova visual: %s" % ("ok" if erros[0] == 0 else "%d falha(s)" % erros[0]))
	return 0 if erros[0] == 0 else 1
