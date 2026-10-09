extends Node3D
## FORJA, a Hefesto Tech Demo: quatro jogadores no mesmo sofá, cada um com um
## DualSense, num salão de forja com uma sala por feature do controle.
##
## Título → lobby (quem joga: cada controle ganha um lugar P1..P4, a luz e as
## lâmpadas do lugar) → salão (os portões das salas) ⇄ salas. Na bigorna, a
## partida: 3, 5 ou 9 salas seguidas, o placar entre elas e o pódio no fim. Por
## cima de tudo: o diagnóstico ao vivo (Create), o livro da sessão e a pausa
## (Options).
##
## Toda entrada e toda saída passam pelo autoload Forja, por lugar (0..3).

## A Prova de Fogo: todas as salas, na ordem do percurso, e o livro no fim.
const ORDEM_DO_FOGO := ["centelha", "viga", "molde", "impacto", "galeria", "canto", "caminhos", "voz", "prova"]

var estado := "titulo"
var fogo := -1  ## a sala da Prova de Fogo em curso (índice em ORDEM_DO_FOGO); -1 fora dela
var partida: Partida = null  ## a partida em curso; null fora dela
var _partidas := 0
var _blocos_do_podio: Node3D = null
var _confete_t := 0.0  ## quantas partidas a sessão já começou (a próxima sorteia outra)
var salao: Salao
var jogadores: Array[ForjaPlayer] = []
var sala: Sala
var sala_id := ""
var camera: Camera3D
var _cam_pos := Vector3(0, 6, 14)
var _cam_olhar := Vector3(0, 1, 0)
var _t := 0.0

var ui: Control
var titulo: TelaTitulo
var lobby: TelaLobby
var hud: HudJogo
var painel: PainelSala
var resultado: TelaResultado
var diagnostico: Diagnostico
var livro: Livro
var pausa: Pausa
var escolha: EscolhaPartida
var placar: Placar
var tela_opcoes: TelaOpcoes
var tela_virar: TelaVirar  ## o virar da fita e o intervalo (G16)
var creditos: TelaCreditos
var cortina: ColorRect
var overlay := ""  ## "", "diagnostico", "livro", "pausa", "partida" (a escolha), "placar", "opcoes", "creditos"
var _trocando := false
var _stick_antes := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var _portao_perto := ""
var _robo_placar_rodada := -1  ## o placar em que o robô já apertou ✕ (partida × 100 + sala)
var _robo_placar_t := 0.0  ## o `placar._t` do último ✕ do robô: se não chegou, ele aperta de novo
var _som_de_quem := ""  ## os lugares com a placa de áudio aberta ("013")
var _caiu := {}  ## os lugares cujo controle caiu (e ainda não voltou)
var intro: TelaIntro
var _viu_a_intro := false  ## a introdução é só na primeira vez da sessão
var _t_titulo := 0.0  ## os segundos desde que o título abriu (o relógio quando não há música)
var play_ms := -1  ## o instante (ms) em que alguém deu o PLAY; -1 até lá. A G07 lê no fim da fita
var _toca_titulo: AudioStreamPlayer
var _mapa_titulo := {}
var _titulo_pos_ant := 0.0
var _titulo_voltas := 0
var _foco_do_titulo: CameraAttributesPractical
var _robo_estado := ""
var _robo_espera := 0.0
var _virar_espera := -1.0  ## s até o próximo tempo 1 da música, depois do ✕ do placar da metade (-1: não espera)
var _virar_clunk := false  ## o momento «fita_virada» já foi escrito
var _virar_caneta := false  ## a caneta já soou
var _intervalo_ms := 0.0  ## o tempo do intervalo, em ms (o ✕ só vale depois de 500)
var _intervalo_gesto := 0.0  ## s até o próximo gesto de pedestal
var _intervalo_vez := 0  ## de quem é o próximo gesto
var _robo_intervalo_t := -1.0  ## o `_intervalo_ms` do último ✕ do robô
var jogados_na_noite := {}  ## slot -> true: os minigames que a noite já abriu (o sorteio não repete)
const INTERVALO_GUARDA_MS := 500.0


func _ready() -> void:
	camera = $Camera3D
	_ambiente()
	salao = Salao.new()
	salao.name = "Salao"
	add_child(salao)
	for l in 4:
		var p := ForjaPlayer.new()
		p.montar(l)
		p.visible = false
		p.controlavel = false
		add_child(p)
		p.global_position = salao.pedestais[l]
		jogadores.append(p)
	_interface()
	pausa.escolheu.connect(_na_pausa)
	# um controle que cai e volta pode voltar noutro nó de áudio: a placa se refaz
	Forja.pads_mudaram.connect(_ao_mudar_os_controles)
	escolha.escolheu.connect(_comecar_a_partida.bind(true))
	Forja.registrar("FORJA %s" % Forja.versao())
	_mostrar("titulo")
	_abrir_pelos_args.call_deferred()


## Numa sala, o salão fica fora da árvore; fechando o jogo ali (a pausa, ou
## --sair-no-fim), ninguém mais o solta.
func _exit_tree() -> void:
	if salao and salao.get_parent() == null:
		salao.free()


var env: Environment  ## o ambiente do mundo: a luz de cada seção o acende (acender)


func _ambiente() -> void:
	RenderingServer.set_default_clear_color(Tema.FITA)  # o fundo atrás de tudo, que era do project.godot
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Tema.FITA
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.82
	env.ssao_enabled = false
	env.fog_enabled = true
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	acender(-1)


## A luz de uma seção (arte/01, a luz das cinco tintas), tirada da tinta pelo Tema: o preenchimento no ambiente,
## a névoa e a chave nas luzes da sala. `numero` -1 é o salão, 0 o pódio.
func acender(numero: int, lado_b := false) -> void:
	var luz := Tema.luz_da_secao(numero, lado_b)
	env.background_color = Tema.FITA
	env.ambient_light_color = luz.preenchimento
	env.ambient_light_energy = 0.42
	env.fog_light_color = luz.nevoa
	env.fog_density = luz.densidade
	var sol := get_node_or_null("Sol") as DirectionalLight3D
	if sol:
		sol.light_color = luz.preenchimento
	if sala and numero > 0:
		sala.acender(luz)
	elif salao:
		salao.acender(luz)


func _interface() -> void:
	ui = Control.new()
	ui.name = "UI"
	ui.theme = Tema.tema()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$Interface.add_child(ui)
	titulo = TelaTitulo.new()
	lobby = TelaLobby.new()
	lobby.jogadores = jogadores
	lobby.salao = salao
	hud = HudJogo.new()
	hud.camera = camera
	painel = PainelSala.new()
	resultado = TelaResultado.new()
	diagnostico = Diagnostico.new()
	livro = Livro.new()
	pausa = Pausa.new()
	escolha = EscolhaPartida.new()
	placar = Placar.new()
	tela_opcoes = TelaOpcoes.new()
	creditos = TelaCreditos.new()
	intro = TelaIntro.new()
	tela_virar = TelaVirar.new()
	for c in [titulo, lobby, hud, painel, resultado, diagnostico, livro, tela_virar, pausa, escolha, placar, tela_opcoes, creditos, intro]:
		ui.add_child(c)
	cortina = ColorRect.new()
	cortina.color = Color(Tema.FITA, 0.0)
	cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cortina.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(cortina)
	resultado.visible = false
	diagnostico.visible = false
	livro.visible = false
	pausa.visible = false
	escolha.visible = false
	placar.visible = false
	tela_virar.visible = false
	tela_opcoes.visible = false
	creditos.visible = false
	intro.visible = false
	intro.musica_do_titulo_volta.connect(_tocar_o_titulo)
	tela_opcoes.mudou.connect(func(_c: String) -> void: Forja.aplicar_opcoes())


## `-- --sala=galeria` abre direto na sala, com todo controle já dentro (é o que
## uma folha de teste pede: "abra na Galeria"). `--tela=` abre numa tela.
## `--partida=5` começa uma partida de cinco salas (`--sorteada`: na ordem do
## sorteio).
func _abrir_pelos_args() -> void:
	var tela := ""
	var n_partida := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tela="):
			tela = a.substr(7)
		if a.begins_with("--partida="):
			n_partida = int(a.substr(10))
	var sala_pedida := Forja.sala_pedida
	if sala_pedida == "giro":
		sala_pedida = "viga"
	var pede_o_fogo := "--prova-de-fogo" in OS.get_cmdline_user_args()
	var experimento := Forja.experimento != ""
	if sala_pedida != "" or pede_o_fogo or experimento or n_partida > 0 or tela in ["lobby", "salao", "diagnostico", "livro"]:
		await get_tree().process_frame
		await get_tree().process_frame
		_todos_entram()
	if experimento:
		# a bancada do experimental/ no lugar do salão
		_ir_para_o_salao(false)
		_entrar_na_sala("bancada", false)
		return
	if pede_o_fogo:
		_ir_para_o_salao(false)
		_comecar_a_prova_de_fogo(false)
		return
	if n_partida > 0:
		_ir_para_o_salao(false)
		_comecar_a_partida(n_partida, "--sorteada" in OS.get_cmdline_user_args(), false)
		return
	if sala_pedida != "" and Catalogo.existe(sala_pedida):
		_ir_para_o_salao(false)
		_entrar_na_sala(sala_pedida, false)
		return
	match tela:
		"lobby":
			_mostrar("lobby")
		"salao":
			_ir_para_o_salao(false)
		"diagnostico":
			_ir_para_o_salao(false)
			_abrir_overlay("diagnostico", 0)
		"livro":
			_ir_para_o_salao(false)
			_abrir_overlay("livro", 0)


func _todos_entram() -> void:
	for p in Forja.pads():
		if int(p.lugar) < 0:
			Forja.entrar(int(p.pad))
	_sincronizar_jogadores()
	for l in 4:
		if Forja.ocupado(l):
			Itens.escolhido[l] = jogadores[l].item_i


# ------------------------------------------------------------------ estados --

func _mostrar(qual: String) -> void:
	var antes := estado
	var era_lobby := antes == "lobby"
	estado = qual
	if antes == "titulo" and qual != "titulo":
		Forja.som_encerrar()  # o alto-falante dos controles era só do pio
	if era_lobby and qual != "lobby":
		Ritmo.parar()  # o salão não segue o relógio da construção
		Forja.som_encerrar()  # o alto-falante dos controles era só do pio e do tique
		for l in 4:
			Forja.gatilhos_off(l)
	if qual == "titulo":
		_t_titulo = 0.0
		_som_de_quem = ""  # a placa se refaz no título (a construção a fechou ao sair)
		titulo.play_desde = -1.0
		_tocar_o_titulo()
	elif qual == "lobby":
		_toca_titulo = null
		var m := Musica.mapa("MUS_TELA_CONSTRUCAO")
		Ritmo.tocar("MUS_TELA_CONSTRUCAO", m.bpm, m.primeiro_tempo)
		_som_de_quem = ""  # o alto-falante de quem se senta é achado a cada quadro da construção
	elif qual == "virar":
		_toca_titulo = null
		Musica.calar()  # a fita para no eject
	elif qual != "intro":
		_toca_titulo = null
		Musica.tocar(Catalogo.apelido(sala_id) if qual == "sala" else ("salao" if qual == "intervalo" else qual))
	titulo.visible = qual == "titulo"
	intro.visible = qual == "intro"
	lobby.visible = qual == "lobby"
	tela_virar.visible = qual in ["virar", "intervalo"]
	hud.visible = _hud_visivel()
	if qual != "salao":
		hud.vencidas = -1
		hud.dica_presa = {}
	salao.pausar_ambiente(not qual in ["salao", "intervalo"])
	if qual == "salao":
		Forja.som_preparar(Forja.PAPEL_ALTO_FALANTE)  # o ✕ do salão soa na mão de quem apertou
	salao.pedestais_no.visible = qual in ["lobby", "podio", "intro", "intervalo"]
	_focar_o_titulo(qual == "titulo")
	# o contorno de néon do dono: 1,6 na montagem, 2,4 no resto (G08)
	for p in jogadores:
		p.contornar(ForjaPlayer.CONTORNO_MONTAGEM if qual == "lobby" else ForjaPlayer.CONTORNO_JOGO)
	if qual != "sala":
		# o intervalo é do lado B; o pós continua gasto pela faixa em que a noite está (virar não zera)
		acender(0 if qual == "podio" else -1, qual == "intervalo")
		PosFita.gastar(partida.passo + 1 if partida and qual in ["virar", "intervalo"] else 1)
	if qual == "lobby" or qual == "intervalo":
		for l in 4:
			var p := jogadores[l]
			p.controlavel = false
			p.global_position = salao.pedestais[l]
			p.rotation.y = 0.0
		_sincronizar_jogadores()
		lobby.abrir()


func _sincronizar_jogadores() -> void:
	for l in 4:
		var ocupado := Forja.ocupado(l)
		var p := jogadores[l]
		if ocupado and not p.visible:
			p.visible = true
			if estado == "lobby":
				p.global_position = salao.pedestais[l]
				p.rotation.y = 0.0
				p.gesto("emote-yes", 1.0)
		elif not ocupado and p.visible:
			p.visible = false
			lobby.prontos[l] = false
	_abrir_o_som()


## Um controle que caiu e voltou pode ter voltado noutro nó de áudio: a
## placa se refaz (sem pio: quem está não mudou).
func _ao_mudar_os_controles() -> void:
	var voltou := false
	for l in 4:
		if not Forja.ocupado(l):
			_caiu.erase(l)
		elif not Forja.lugar(l).get("conectado", false):
			_caiu[l] = true
		elif _caiu.has(l):
			_caiu.erase(l)
			voltou = true
	if voltou:
		_abrir_o_som(true)


## A placa de áudio de cada controle abre na entrada do lugar e fica aberta
## (docs/jogo/05#a-agenda-do-alto-falante); só se refaz quando muda quem está
## (ou quando um controle volta). Quem acabou de entrar ouve o pio do seu
## cavaleiro, no próprio controle.
func _abrir_o_som(refazer := false) -> void:
	var quem := ""
	for l in 4:
		if Forja.ocupado(l):
			quem += str(l)
	if quem == _som_de_quem and not refazer:
		return
	var antes := _som_de_quem
	_som_de_quem = quem
	var papel := Forja.PAPEL_ALTO_FALANTE
	if estado == "sala" and sala is SalaJogo and (sala as SalaJogo).papel_som >= 0:
		papel = (sala as SalaJogo).papel_som
	Forja.som_preparar(papel)
	for l in 4:
		if Forja.ocupado(l) and not str(l) in antes:
			Forja.som_falante(l, "pio:%d" % jogadores[l].modelo_i, 0.8)


func _trocar(acao: Callable) -> void:
	if _trocando:
		return
	_trocando = true
	Som.tocar("transicao", null, -10.0)
	var tw := create_tween()
	# a troca de cena em até 400 ms (o estudo 02, item 26): 150 fechando, 220 abrindo
	tw.tween_property(cortina, "color:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	acao.call()
	_cam_pos = _pose_da_camera()[0]
	_cam_olhar = _pose_da_camera()[1]
	var tw2 := create_tween()
	tw2.tween_property(cortina, "color:a", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw2.finished
	_trocando = false


func _ir_para_o_lobby() -> void:
	_sair_da_sala()
	if salao.get_parent() == null:
		add_child(salao)
	for l in 4:
		lobby.prontos[l] = false
	lobby.contagem = -1.0
	Forja.silencio_todos()
	_mostrar("lobby")


func _ir_para_o_salao(com_cortina := true) -> void:
	var feito := func():
		_sair_da_sala()
		if salao.get_parent() == null:
			add_child(salao)
		var i := 0
		for p in jogadores:
			if not p.visible:
				continue
			var volta := salao.saida_do_portao(Catalogo.apelido(sala_id), p.lugar) if sala_id != "" else Vector3(-3.0 + i * 2.0, 0.05, 3.2)
			p.global_position = volta
			p.rotation.y = PI
			p.controlavel = true
			p.visible = Forja.ocupado(p.lugar)
			i += 1
		_mostrar("salao")
		salao.mostrar_colecao(partida != null and partida.lado() == "B")
		hud.vencidas = Colecao.secoes_acesas()
		hud.sala = {}
		hud.status_da_sala = ["", "", "", ""]
	if com_cortina:
		_trocar(feito)
	else:
		feito.call()
		_cam_pos = _pose_da_camera()[0]
		_cam_olhar = _pose_da_camera()[1]


func _entrar_na_sala(id: String, com_cortina := true, pronta: Sala = null) -> void:
	if pronta == null and not Catalogo.existe(id):
		return
	var feito := func():
		_sair_da_sala()
		if salao.get_parent() != null:
			remove_child(salao)
		sala_id = id
		sala = pronta if pronta != null else Catalogo.criar(id)
		_marcar_jogado(sala.id)
		sala.name = "Sala"
		add_child(sala)
		var js: Array = []
		for p in jogadores:
			if p.visible:
				js.append(p)
		if fogo >= 0 and sala is SalaJogo:
			var sj := sala as SalaJogo
			sj.na_prova_de_fogo = "Prova de Fogo · sala %d de %d" % [fogo + 1, ORDEM_DO_FOGO.size()]
			sj.seguir = "Seguir a Prova de Fogo" if fogo + 1 < ORDEM_DO_FOGO.size() else "O livro da sessão"
		elif partida and sala is SalaJogo:
			var sj := sala as SalaJogo
			sj.na_prova_de_fogo = partida.rotulo()
			sj.seguir = "O placar"
		painel.escondido = false
		sala.entrar(js)
		sala.terminou.connect(_ao_terminar_a_sala)
		painel.sala = sala
		hud.create_livre = not (sala is SalaJogo and (((sala as SalaJogo).botoes_pedidos >> Forja.CREATE) & 1
			or (sala as SalaJogo).cega))
		_mostrar("sala")
		acender(sala.numero(), partida != null and partida.lado() == "B")
		PosFita.gastar(partida.passo + 1 if partida else 1)
		PosFita.rasgo_curto()
		hud.sala = {"nome": sala.nome, "acao": sala.acao}
		hud.dica_presa = {}
	if com_cortina:
		_trocar(feito)
	else:
		feito.call()
		_cam_pos = _pose_da_camera()[0]
		_cam_olhar = _pose_da_camera()[1]


## O minigame entrou na noite. Os da seção todos jogados: a volta recomeça
## (sem o que acabou de sair, para não repetir em seguida).
func _marcar_jogado(slot: String) -> void:
	var s := Catalogo.secao(slot)
	if s.is_empty() or not slot in s.minigames:
		return
	jogados_na_noite[slot] = true
	for m in s.minigames:
		if not jogados_na_noite.has(m):
			return
	for m in s.minigames:
		jogados_na_noite.erase(m)
	jogados_na_noite[slot] = true


## A sala acabou e alguém apertou ✕ no veredito: de volta ao salão — ou, na
## Prova de Fogo, a sala seguinte, e o livro no fim.
func _ao_terminar_a_sala() -> void:
	# o robô aperta ✕ a cada quadro até a cortina fechar: uma troca só
	if estado != "sala" or overlay != "" or _trocando:
		return
	if sala_id == "bancada":
		return  # a bancada fica no painel dela: ✕ repete, ○ fecha
	if sala is SalaJogo:
		_registrar_na_colecao(sala as SalaJogo)
	if partida and sala is SalaJogo:
		_placar_da_sala(sala as SalaJogo)
		return
	if fogo >= 0:
		fogo += 1
		if fogo < ORDEM_DO_FOGO.size():
			_entrar_na_sala(ORDEM_DO_FOGO[fogo])
			return
		fogo = -1
		Forja.registrar("Prova de Fogo: terminou")
		Forja.evento("sala", 0, {"evento": "prova_de_fogo", "o": "terminou"})
		Forja.gravar_relatorio()
		if "--sair-no-fim" in OS.get_cmdline_user_args():
			# sem ninguém olhando (a prova da exportação): o relatório gravado, e fecha
			get_tree().quit()
			return
		_ir_para_o_salao()
		get_tree().create_timer(0.9).timeout.connect(func() -> void:
			if estado == "salao" and overlay == "":
				_abrir_overlay("livro", 0))
		return
	_ir_para_o_salao()


## O fim de uma sala vai para a coleção da noite: o troféu, o recorde, o que se desbloqueou.
func _registrar_na_colecao(sj: SalaJogo) -> void:
	var presentes: Array = []
	for l in 4:
		if sj.jogando[l]:
			presentes.append(l)
	# a coleção fala pelo apelido do portão (H04): o slot do minigame (S01_J01) não acende portão
	var r := Colecao.registrar(Catalogo.apelido(sj.id), sj.pontos, presentes, sj.coop, sj.coop and sj.coop_venceu and sj.erros_do_grupo() == 0)
	for nome in r.desbloqueou:
		Forja.aviso.emit("%s na forja" % nome)
	if r.recorde >= 0:
		Forja.aviso.emit("Recorde da noite: P%d" % (r.recorde + 1))
		Musica.jingle("JIN_RECORDE")
		Forja.sentir(r.recorde, "acerto")


## Todas as salas que medem, na ordem do percurso, sem voltar ao salão.
func _comecar_a_prova_de_fogo(com_cortina := true) -> void:
	fogo = 0
	Forja.registrar("Prova de Fogo: começou (semente %d)" % Forja.semente)
	Forja.evento("sala", 0, {"evento": "prova_de_fogo", "o": "começou"})
	_entrar_na_sala(ORDEM_DO_FOGO[0], com_cortina)


# ----------------------------------------------------------------- partida --

## Uma partida de `n` salas (na ordem, ou sorteadas pela semente): a primeira
## sala abre na hora; entre as salas, o placar; no fim, o pódio.
func _comecar_a_partida(n: int, sorteada: bool, com_cortina := true) -> void:
	if overlay != "":
		_fechar_overlay()
	fogo = -1
	partida = Partida.nova(n, sorteada, Forja.semente + _partidas, ORDEM_DO_FOGO, jogados_na_noite, Forja.semente)
	_partidas += 1
	var ids := ", ".join(partida.salas)
	Forja.registrar("Partida: começou, %d salas%s, nível %s (%s)" % [partida.salas.size(), ", sorteadas" if sorteada else "",
		Forja.NIVEIS[Forja.nivel], ids])
	Forja.evento("sala", 0, {"evento": "partida", "o": "começou", "salas": ids})
	_entrar_na_sala(partida.sala_atual(), com_cortina)


## A sala da partida acabou: a colocação de cada um vira pontos da noite, e o
## placar aparece por cima do veredito.
func _placar_da_sala(sj: SalaJogo) -> void:
	var presentes: Array = []
	for l in 4:
		if sj.jogando[l]:
			presentes.append(l)
	var e := partida.registrar(sala_id, sj.pontos, presentes)
	var linha: PackedStringArray = []
	for l in presentes:
		linha.append("P%d %dº +%d" % [l + 1, int(e.colocacao[l]), int(e.ganhos[l])])
	Forja.registrar("Partida: %s — %s" % [sj.nome, " · ".join(linha)])
	Forja.evento("sala", 0, {"evento": "partida", "o": "placar", "sala": sala_id, "ganhos": e.ganhos})
	_abrir_overlay("placar", 0)


## ✕ no placar: a sala seguinte, ou o pódio.
func _seguir_a_partida() -> void:
	if partida.acabou():
		overlay = ""
		placar.visible = false
		_trocar(_ir_para_o_podio)
	elif partida.passo == partida.metade() and not partida.virou:
		# a fita vira no próximo tempo 1 da música; o placar fica até lá
		_virar_espera = _ate_o_proximo_compasso()
		if _virar_espera <= 0.0:
			_virar_a_fita()
	else:
		overlay = ""
		placar.visible = false
		_entrar_na_sala(partida.sala_atual())


## Quanto falta, em s, para o próximo tempo 1 da música que toca (o compasso de 4 batidas); 0 sem música.
func _ate_o_proximo_compasso() -> float:
	var tocador: AudioStreamPlayer = null
	for c in Musica.get_children():
		if c is AudioStreamPlayer and c.playing and c.volume_db > -30.0:
			tocador = c
	if tocador == null:
		return 0.0
	var mapa := Musica.mapa(Musica.atual)
	var compasso := 4.0 * 60.0 / maxf(float(mapa.get("bpm", 120.0)), 30.0)
	var fase := fposmod(tocador.get_playback_position() - float(mapa.get("primeiro_tempo", 0.0)), compasso)
	return compasso - fase if fase > 0.02 else 0.0


## A fita vira: o deck aberto, o cassete sai, gira e entra com o lado B para cima (4000 ms fixos desde `T0`),
## e o corte seco para o intervalo. Sem botão: o Options abre a pausa, como em toda tela.
func _virar_a_fita() -> void:
	_virar_espera = -1.0
	overlay = ""
	placar.visible = false
	_sair_da_sala()
	if salao.get_parent() == null:
		add_child(salao)
	_bonecos_nos_pedestais()
	_mostrar("virar")
	tela_virar.virar()
	_virar_clunk = false
	_virar_caneta = false
	Som.tocar("fx_virar", null, -6.0)
	for l in 4:
		if Forja.ocupado(l):
			Forja.sentir(l, "fita", 1600)
			Forja.gatilhos_off(l)
	Forja.evento("sala", 0, {"evento": "partida", "o": "virou", "passo": partida.passo})


func _bonecos_nos_pedestais() -> void:
	for p in jogadores:
		p.controlavel = false
		p.global_position = salao.pedestais[p.lugar]
		p.rotation.y = 0.0


func _quadro_virar(dt: float) -> void:
	if _atalhos_de_overlay():
		return
	tela_virar.andar(dt)
	if not _virar_clunk and tela_virar.ms >= TelaVirar.CLUNK_MS:
		_virar_clunk = true
		Forja.evento("momento", 0, {"slot": "virar", "nome": "fita_virada", "lugar": -1, "ms_desde_o_corte": int(round(tela_virar.ms))})
	if not _virar_caneta and tela_virar.ms >= TelaVirar.CANETA_MS:
		_virar_caneta = true
		Som.tocar("fx_caneta", null, -6.0)
	if tela_virar.ms >= TelaVirar.TOTAL_MS:
		_ir_para_o_intervalo()


## O corte seco: o salão na luz do lado B, os bonecos nos pedestais, sem tempo limite.
func _ir_para_o_intervalo() -> void:
	partida.virou = true
	_intervalo_ms = 0.0
	_intervalo_gesto = 0.0
	_intervalo_vez = 0
	_robo_intervalo_t = -1.0
	_mostrar("intervalo")
	tela_virar.intervalo(partida.rotulo())
	_cam_pos = _pose_da_camera()[0]
	_cam_olhar = _pose_da_camera()[1]
	Forja.evento("sala", 0, {"evento": "partida", "o": "intervalo", "passo": partida.passo})


## O intervalo: o ✕ de qualquer lugar ocupado (depois de 500 ms) segue a noite; ◯ não faz nada.
func _quadro_intervalo(dt: float) -> void:
	if _atalhos_de_overlay():
		return
	_intervalo_ms += dt * 1000.0
	# um gesto de cada vez, a cada 4 compassos
	_intervalo_gesto -= dt
	if _intervalo_gesto <= 0.0:
		var mapa := Musica.mapa(Musica.atual)
		_intervalo_gesto = 16.0 * 60.0 / maxf(float(mapa.get("bpm", 120.0)), 30.0)
		for k in 4:
			var l := (_intervalo_vez + k) % 4
			if Forja.ocupado(l):
				jogadores[l].gesto("emote-yes", 1.0)
				_intervalo_vez = l + 1
				break
	if Forja.robo:
		_robo_do_intervalo()
	if _intervalo_ms < INTERVALO_GUARDA_MS:
		return
	for l in 4:
		if Forja.ocupado(l) and Forja.apertou(l, Forja.CRUZ):
			Forja.sentir(l, "toque")
			Som.tocar("ui_confirma", null, -6.0)
			_entrar_na_sala(partida.sala_atual())
			return


## O robô no intervalo: aperta o ✕ do primeiro lugar ocupado depois de 2 s, e de novo a cada 4 s se a primeira não chegou.
func _robo_do_intervalo() -> void:
	if _intervalo_ms <= 2000.0 or (_robo_intervalo_t >= 0.0 and _intervalo_ms - _robo_intervalo_t <= 4000.0):
		return
	_robo_intervalo_t = _intervalo_ms
	for l in 4:
		if Forja.ocupado(l):
			Forja.robo_confirmar(l, 0.0)
			return


## O pódio: de volta ao salão, cada boneco no pedestal do seu lugar, e o placar
## final ao lado. Quem venceu comemora (e o controle dele sente).
func _ir_para_o_podio() -> void:
	_sair_da_sala()
	if salao.get_parent() == null:
		add_child(salao)
	painel.escondido = false
	var lista := partida.podio(partida.presentes())
	for p in jogadores:
		p.controlavel = false
		p.preso = true  # sem gravidade: o bloco leva o boneco para cima
		p.global_position = salao.pedestais[p.lugar]
		p.rotation.y = 0.0
	# o pódio de verdade: um bloco sobe debaixo de cada um, mais alto para quem
	# ficou na frente, e leva o boneco junto
	_blocos_do_podio = Node3D.new()
	salao.add_child(_blocos_do_podio)
	if not Forja.som_pronto():
		Forja.som_preparar(Forja.PAPEL_ALTO_FALANTE)
	for e in lista:
		var l := int(e.lugar)
		var altura: float = [1.1, 0.7, 0.45, 0.25][clampi(int(e.degrau) - 1, 0, 3)]
		var bloco := CSGBox3D.new()
		bloco.size = Vector3(1.5, 1.0, 1.5)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Tema.OXIDO_BRILHO.lerp(Forja.cor_do_lugar(l), 0.25)
		Tema.emissivo(mat, 0.6 if int(e.degrau) == 1 else 0.0, l)
		bloco.material = mat
		var base: Vector3 = salao.pedestais[l]
		bloco.position = base + Vector3(0, -0.5, 0)
		bloco.scale = Vector3(1, 0.01, 1)
		_blocos_do_podio.add_child(bloco)
		var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var espera := 0.25 * (4 - int(e.degrau))
		tw.tween_property(bloco, "scale", Vector3(1, altura, 1), 0.7).set_delay(espera)
		tw.tween_property(bloco, "position", base + Vector3(0, altura * 0.5, 0), 0.7).set_delay(espera)
		tw.tween_property(jogadores[l], "global_position", base + Vector3(0, altura, 0), 0.7).set_delay(espera)
		if int(e.degrau) == 1:
			jogadores[l].gesto("emote-yes", 2.0)
			Forja.sentir(l, "perfeito", 400)
			# a fanfarra na TV e na mão de quem venceu
			get_tree().create_timer(0.9).timeout.connect(func() -> void:
				Som.tocar("vitoria_noite")
				Som.no_controle(l, "vitoria_noite", 0.8))
	_confete_t = 0.0
	_mostrar("podio")
	Musica.tocar("podio")
	hud.sala = {}
	hud.dica_presa = {}
	placar.abrir(partida, true)
	placar.visible = true
	var frase := Placar.frase_do_vencedor(lista)
	Forja.registrar("Partida: terminou — %s" % frase)
	Forja.evento("sala", 0, {"evento": "partida", "o": "terminou", "podio": lista.map(func(e): return int(e.lugar) + 1)})
	Forja.gravar_relatorio()


## No pódio: ✕ outra partida do mesmo tamanho (outro sorteio), ○ o salão.
## Quem venceu segue comemorando.
func _quadro_podio() -> void:
	if not placar.pronto():
		return
	for e in partida.podio(partida.presentes()):
		if int(e.degrau) == 1 and jogadores[int(e.lugar)]._gesto <= 0.0:
			jogadores[int(e.lugar)].gesto("emote-yes", 2.0)
	# o confete: faíscas nas quatro cores caindo sobre o primeiro degrau
	_confete_t -= get_process_delta_time()
	if _confete_t <= 0.0:
		_confete_t = 0.45
		for e in partida.podio(partida.presentes()):
			if int(e.degrau) == 1:
				var alto: Vector3 = jogadores[int(e.lugar)].global_position + Vector3(randf_range(-1.2, 1.2), 3.2, randf_range(-0.6, 0.6))
				Efeitos.faiscas(salao, alto, Forja.cor_do_lugar(randi() % 4), Opcoes.confete(22), 0.9)
	if Forja.robo:
		if _robo_do_podio():
			return
	for l in 4:
		if not Forja.ocupado(l):
			continue
		if Forja.apertou(l, Forja.CRUZ):
			var n := partida.salas.size()
			var sorteada := partida.sorteada
			_sair_do_podio()
			_comecar_a_partida(n, sorteada)
			return
		if Forja.apertou(l, Forja.CIRCULO):
			_sair_do_podio()
			partida = null
			_ir_para_o_salao()
			return


## O robô do pódio: com --sair-no-fim, fecha o processo depois de olhar o
## pódio por 3 s. Não é um caminho do jogo, é o fim da prova: nenhuma tela é
## pulada (o jogo não tem botão que feche o pódio sozinho).
func _robo_do_podio() -> bool:
	if "--sair-no-fim" in OS.get_cmdline_user_args() and placar._t > 3.0:
		get_tree().quit()
		return true
	return false


## O robô do placar: depois da conta, aperta ✕ no controle simulado do primeiro
## lugar, como quem leu e quer seguir (F08). Se o ✕ não chegou (o controle
## estava fora do cabo, o robô ruim não apertou), aperta de novo em 4 s, como
## a pessoa que vê que a tela não andou.
func _robo_do_placar() -> void:
	var rodada: int = _partidas * 100 + partida.historico.size() if partida else -1
	if placar._t <= Placar.T_PRONTO + 0.6:
		return
	if rodada == _robo_placar_rodada and placar._t - _robo_placar_t < 4.0:
		return
	_robo_placar_rodada = rodada
	_robo_placar_t = placar._t
	for l in 4:
		if Forja.ocupado(l):
			Forja.robo_confirmar(l, 0.0)
			return


func _sair_do_podio() -> void:
	placar.visible = false
	for p in jogadores:
		p.preso = false
	if is_instance_valid(_blocos_do_podio):
		_blocos_do_podio.queue_free()
	_blocos_do_podio = null


func _sair_da_sala() -> void:
	painel.sala = null
	resultado.fechar()
	hud.create_livre = true
	if sala:
		sala.sair()
		sala.queue_free()
		sala = null
		for p in jogadores:
			p.controlavel = true
			p.visible = Forja.ocupado(p.lugar)


# ------------------------------------------------------------------ quadro --

func _process(dt: float) -> void:
	_t += dt
	if estado == "lobby":
		_sincronizar_jogadores()
	if not _trocando:
		if overlay != "":
			_quadro_overlay()
		else:
			match estado:
				"titulo": _quadro_titulo(dt)
				"intro": _quadro_intro(dt)
				"lobby": _quadro_lobby(dt)
				"salao": _quadro_salao()
				"sala": _quadro_sala()
				"podio": _quadro_podio()
				"virar": _quadro_virar(dt)
				"intervalo": _quadro_intervalo(dt)
	if sala:
		for l in 4:
			hud.status_da_sala[l] = sala.status(l) if Forja.ocupado(l) else ""
	if estado == "sala" and sala and sala.camera_modo == "corrida":
		sala.puxar_os_de_tras()
	_mover_camera(dt)
	for l in 4:
		_stick_antes[l] = Forja.mover(l)
	if Forja.robo:
		_robo(dt)


func _algum_pad_apertou(botao: int) -> int:
	for p in Forja.pads():
		if Forja.pad_apertou(int(p.pad), botao):
			return int(p.pad)
	return -1


## O título: a forja pulsa na batida; qualquer botão de um controle com lugar dá
## o pio dele; ✕ ou Options dá o PLAY (e senta o controle que ainda não tinha
## lugar); △ abre os créditos. O corte espera o próximo tempo 1 depois das 4
## batidas do cassete descendo.
func _quadro_titulo(dt: float) -> void:
	_t_titulo += dt
	var batidas := _batidas_do_titulo()
	titulo.batidas = batidas
	_achar_os_alto_falantes()
	var pulso := _pulso_da_forja(batidas, clampf(_t_titulo / 2.0, 0.0, 1.0))
	titulo.pulso = pulso
	salao.pulso = pulso
	titulo.contador_s = float(Time.get_ticks_msec() - play_ms) / 1000.0 if play_ms >= 0 else 0.0
	if not Forja.modulo:
		if titulo.play_desde < 0.0 and Forja.apertou(0, Forja.CRUZ):
			_dar_play(0)
	elif Forja.conectados() == 0:
		if titulo.play_desde < 0.0 and (Forja.tecla_apertou(KEY_ENTER) or Forja.tecla_apertou(KEY_SPACE)):
			if Forja.jogar_no_teclado():
				_dar_play(0)
	else:
		for p in Forja.pads():
			var i := int(p.pad)
			var l := int(p.lugar)
			var play := Forja.pad_apertou(i, Forja.CRUZ) or Forja.pad_apertou(i, Forja.OPTIONS)
			# o controle sem lugar que aperta ✕ ou Options se senta, para ter pio e vibração
			if l < 0 and play and titulo.play_desde < 0.0:
				l = Forja.entrar(i)
				if l >= 0:
					Forja.registrar("P%d entrou" % (l + 1))
					_achar_os_alto_falantes()
			if l >= 0:
				for b in [Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO, Forja.TRIANGULO, Forja.OPTIONS]:
					if Forja.pad_apertou(i, b):
						Som.pio(l, jogadores[l].modelo_i)
						Forja.sentir(l, "toque")
						Forja.gatilhos_off(l)
						break
			if titulo.play_desde >= 0.0:
				continue
			if Forja.pad_apertou(i, Forja.TRIANGULO):
				_abrir_overlay("creditos", 0)
				return
			if play and l >= 0:
				_dar_play(l)
	# o corte: no primeiro tempo 1 depois das 4 batidas do PLAY
	if titulo.play_desde >= 0.0 and batidas >= ceil((titulo.play_desde + 4.0) / 4.0) * 4.0:
		_trocar(_ir_para_a_intro if not _viu_a_intro else _ir_para_o_lobby)


## O alto-falante de cada controle com lugar, achado de novo quando um se senta
## (o módulo só acha o som de quem já ocupa o lugar). A placa é uma só, a do
## `_abrir_o_som`: refazê-la aqui de novo cortaria o pio de quem acabou de entrar.
func _achar_os_alto_falantes() -> void:
	_abrir_o_som()


## A energia da forja na batida (0..1): sobe com o `entrada` e cai em cada tempo.
func _pulso_da_forja(batidas: float, entrada: float) -> float:
	return entrada * (0.55 + 0.45 * pow(1.0 - fposmod(batidas, 1.0), 3.0))


## O PLAY: o clunk na TV, o motor da fita na mão de quem apertou, o cassete desce.
func _dar_play(l: int) -> void:
	Som.tocar("fx_play", null, -6.0)
	Forja.sentir(l, "fita")
	titulo.play_desde = _batidas_do_titulo()
	play_ms = Time.get_ticks_msec()
	Forja.registrar("PLAY (P%d)" % (l + 1))


func _ir_para_a_intro() -> void:
	_viu_a_intro = true
	_mostrar("intro")
	intro.comecar(salao, jogadores)


## A introdução: 24 s sem uma palavra. Qualquer botão a pula, depois de 0,5 s
## (o ✕ que deu o PLAY não conta).
func _quadro_intro(dt: float) -> void:
	_t_titulo += dt
	salao.pulso = _pulso_da_forja(_batidas_do_titulo(), 1.0)
	intro.quadro(dt)
	var pulou := false
	if intro.t > 0.5:
		if Forja.modulo:
			for p in Forja.pads():
				for b in [Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO, Forja.TRIANGULO, Forja.OPTIONS]:
					if Forja.pad_apertou(int(p.pad), b):
						pulou = true
		elif Forja.apertou(0, Forja.CRUZ):
			pulou = true
	if pulou or intro.acabou:
		_trocar(func() -> void:
			intro.terminar()
			_ir_para_o_lobby())


## A faixa do título, do zero (o relógio da batida parte dela). A gerada, se
## existe; senão a sintetizada de reserva.
func _tocar_o_titulo() -> void:
	var slot: String = Musica.TELAS.titulo if not Musica.mapa_gerado(Musica.TELAS.titulo).is_empty() else "titulo"
	_toca_titulo = Musica.tocar_do_zero(slot)
	_mapa_titulo = Musica.mapa(slot)
	_titulo_pos_ant = 0.0
	_titulo_voltas = 0


## As batidas desde o começo da faixa do título, pelo relógio de áudio (sem
## música, pelo tempo do título a 115 BPM).
func _batidas_do_titulo() -> float:
	if _toca_titulo == null or not _toca_titulo.playing:
		return _t_titulo * 115.0 / 60.0
	var pos := _toca_titulo.get_playback_position() + AudioServer.get_time_since_last_mix()
	var r := Ritmo.posicao_continua(pos, _titulo_pos_ant, _titulo_voltas, Musica.laco_s(_toca_titulo))
	_titulo_voltas = int(r[1])
	_titulo_pos_ant = pos
	var s := float(r[0]) - AudioServer.get_output_latency() - float(_mapa_titulo.get("primeiro_tempo", 0.0))
	return s * float(_mapa_titulo.get("bpm", 115.0)) / 60.0


## O foco do título (arte/01): a forja fora de foco atrás do cassete.
func _focar_o_titulo(ligado: bool) -> void:
	if _foco_do_titulo == null:
		_foco_do_titulo = CameraAttributesPractical.new()
		_foco_do_titulo.dof_blur_far_distance = 3.0
		_foco_do_titulo.dof_blur_far_transition = 2.0
		_foco_do_titulo.dof_blur_amount = 0.06
		camera.attributes = _foco_do_titulo
	_foco_do_titulo.dof_blur_far_enabled = ligado


## O robô do fluxo (--robo): só aperta botões no controle simulado, como uma
## pessoa. Título: espera 3,0 s e aperta ✕ no primeiro lugar com controle.
## Construção: o robô do lobby (TelaLobby.robo) confirma o lugar, forja e martela
## na batida, lugar a lugar, a cada quadro. A introdução ele não pula.
func _robo(dt: float) -> void:
	if _trocando or overlay != "" or not Forja.robo_confirma:
		return
	if estado != _robo_estado:
		_robo_estado = estado
		_robo_espera = 3.0 if estado == "titulo" else 0.6
	if estado == "lobby":
		# a construção: ✕ para forjar e as oito marteladas na batida, a cada quadro
		for l in 4:
			lobby.robo(l, dt)
		return
	_robo_espera -= dt
	if _robo_espera > 0.0:
		return
	match estado:
		"titulo":
			if titulo.play_desde >= 0.0:
				return
			for l in 4:
				var lg := Forja.lugar(l)
				if bool(lg.get("conectado", false)) or bool(lg.get("reservado", false)):
					Forja.robo_apertar(l, Forja.CRUZ)
					_robo_espera = 3.0  # se o aperto se perder (temperamento), tenta de novo
					return


var _quadrado_t := {}  ## pad → quanto tempo o ◻ está segurado (antes de confirmar o lugar)


func _quadro_lobby(dt: float) -> void:
	_achar_os_alto_falantes()
	if _atalhos_de_overlay():
		return
	# ◻ segurado um segundo, antes de confirmar: a reserva passa ao próximo lugar livre
	for p in Forja.pads():
		var i := int(p.pad)
		if int(p.lugar) >= 0 or not Forja.pad_segura(i, Forja.QUADRADO):
			_quadrado_t.erase(i)
			continue
		_quadrado_t[i] = float(_quadrado_t.get(i, 0.0)) + dt
		if float(_quadrado_t[i]) >= 1.0:
			Forja.trocar_lugar(i)
			_quadrado_t[i] = -INF  # só de novo depois de soltar
	# quem ainda não tem lugar entra com ✕ (e esse ✕ não é o da forja)
	for p in Forja.pads():
		if int(p.lugar) < 0 and Forja.pad_apertou(int(p.pad), Forja.CRUZ):
			var l := Forja.entrar(int(p.pad))
			if l >= 0:
				Forja.registrar("P%d entrou no lobby" % (l + 1))
				_sincronizar_jogadores()
				lobby.entrou(l)
	var dx := [0, 0, 0, 0]
	var dy := [0, 0, 0, 0]
	for l in 4:
		dx[l] = _passo(l, false)
		dy[l] = _passo(l, true)
	lobby.quadro(dt, dx, dy)
	_sincronizar_jogadores()
	# a partida começa 1,6 s depois de todo lugar ocupado e com controle estar forjado
	var ocupados := 0
	var prontos := 0
	for l in 4:
		if Forja.ocupado(l) and bool(Forja.lugar(l).get("conectado", false)):
			ocupados += 1
			if lobby.prontos[l]:
				prontos += 1
	if ocupados > 0 and prontos == ocupados:
		if lobby.contagem < 0.0:
			lobby.contagem = 1.6
		lobby.contagem -= dt
		if lobby.contagem <= 0.0:
			lobby.contagem = -1.0
			_ir_para_o_salao()
	else:
		lobby.contagem = -1.0


func _quadro_salao() -> void:
	if _atalhos_de_overlay():
		return
	for q in jogadores:
		hud.nomes[q.lugar] = q.nome
	# o portão mais perto de algum jogador
	var perto := ""
	var quem := -1
	for p in jogadores:
		if not p.visible:
			continue
		var g := salao.portao_perto(p.global_position)
		if g != "":
			perto = g
			quem = p.lugar
			break
	if perto != _portao_perto:
		if _portao_perto != "":
			salao.abrir_portao(_portao_perto, false)
		if perto != "":
			salao.abrir_portao(perto, true)
			Som.tocar("portao", salao.centro_do_portao(perto), -8.0)
		_portao_perto = perto
	if perto == "":
		_perto_da_bigorna()
		return
	var dados: Dictionary = salao.portoes[perto].dados
	var cabeca := Vector3.ZERO
	for p in jogadores:
		if p.lugar == quem:
			cabeca = p.global_position + Vector3(0, 1.9, 0)
	hud.dica_presa = {"lugar": quem, "cabeca": cabeca, "fechado": not dados.aberta,
		"linhas": [["cruz", "Tocar a faixa" if dados.aberta else "Em breve"]]}
	if dados.aberta:
		for p in jogadores:
			if p.visible and Forja.apertou(p.lugar, Forja.CRUZ):
				_som_do_cruz(p.lugar, true)
				_entrar_na_sala(Catalogo.proximo(perto, Forja.semente, jogados_na_noite))
				return
	elif quem >= 0 and Forja.apertou(quem, Forja.CRUZ):
		_som_do_cruz(quem, false)


## O ✕ no salão: `ui_confirma` num portão aberto ou na bigorna, `ui_volta` no fechado, na TV e no
## alto-falante de quem apertou, com o toque na mão.
func _som_do_cruz(lugar: int, confirma: bool) -> void:
	if confirma:
		Som.tocar("ui_confirma", null, -12.0)
		Som.no_controle(lugar, "ui_confirma", 0.85)
	else:
		Som.tocar("ui_volta", null, -12.0)
		Som.no_controle(lugar, "ui_volta", 0.85)
	Forja.sentir(lugar, "toque")


## A bigorna no meio do salão: ✕ entra n'A Prova, □ escolhe uma partida, △
## acende a Prova de Fogo.
func _perto_da_bigorna() -> void:
	var centro := salao.bigorna.global_position
	for p in jogadores:
		if not p.visible:
			continue
		if Vector2(p.global_position.x - centro.x, p.global_position.z - centro.z).length() > 3.1:
			continue
		hud.dica_presa = {"lugar": p.lugar, "cabeca": p.global_position + Vector3(0, 1.9, 0), "fechado": false,
			"linhas": [["cruz", "Tocar A Prova"], ["quadrado", "Partida"], ["triangulo", "Prova de Fogo"]]}
		for q in jogadores:
			if not q.visible:
				continue
			if Forja.apertou(q.lugar, Forja.CRUZ):
				_som_do_cruz(q.lugar, true)
				_entrar_na_sala("prova")
				return
			if Forja.apertou(q.lugar, Forja.QUADRADO):
				_som_do_cruz(q.lugar, true)
				_abrir_overlay("partida", q.lugar)
				return
			if Forja.apertou(q.lugar, Forja.TRIANGULO):
				_som_do_cruz(q.lugar, true)
				Som.tocar("martelo", centro + Vector3(0, 1, 0))
				_comecar_a_prova_de_fogo()
				return
		return
	hud.dica_presa = {}


func _quadro_sala() -> void:
	# o fim da sala: a tela de resultado abre sozinha (e reabre ao sair da pausa)
	if sala is SalaJogo and (sala as SalaJogo).fase == "fim" and not resultado.visible and overlay == "":
		var sj := sala as SalaJogo
		resultado.abrir(sj.colocacao, sj.pontos, sj.coop, sj.coop_venceu, sj.nome, sj.frase_do_resultado())
		resultado.sala_da_bancada = sj if Forja.bancada else null
	_atalhos_de_overlay()


## Create abre o diagnóstico, Options a pausa. Devolve true se abriu: o resto
## do quadro não roda (um ✕ no mesmo quadro não entra numa sala por baixo).
## Numa sala que pede o Create (a runa d'A Centelha), ele é da sala: o
## diagnóstico abre pela pausa.
func _atalhos_de_overlay() -> bool:
	var create_livre := Forja.bancada and not (sala is SalaJogo and ((sala as SalaJogo).botoes_pedidos >> Forja.CREATE) & 1)
	for l in 4:
		if not Forja.ocupado(l):
			continue
		if create_livre and Forja.apertou(l, Forja.CREATE):
			_abrir_overlay("diagnostico", l)
			return true
		if Forja.apertou(l, Forja.OPTIONS):
			_abrir_overlay("pausa", l)
			return true
	return false


func _abrir_overlay(qual: String, lugar: int) -> void:
	if qual in ["diagnostico", "livro"] and not Forja.bancada:
		return  # o diagnóstico e o livro são do Modo bancada
	if qual == "diagnostico" and not _diagnostico_livre():
		hud.mostrar_aviso("Prova às cegas: o diagnóstico volta no fim da sala")
		return
	overlay = qual
	resultado.fechar()
	diagnostico.visible = qual == "diagnostico"
	livro.visible = qual == "livro"
	pausa.visible = qual == "pausa"
	escolha.visible = qual == "partida"
	placar.visible = qual == "placar"
	tela_opcoes.visible = qual == "opcoes"
	creditos.visible = qual == "creditos"
	if qual in ["opcoes", "creditos"]:
		titulo.visible = false
		lobby.visible = false
	for p in jogadores:
		p.controlavel = false
	hud.visible = false
	painel.escondido = true
	if sala is SalaJogo:
		(sala as SalaJogo).congelar(true)
	if qual == "livro":
		livro.abrir()
	if qual == "pausa":
		pausa.abrir(lugar, estado == "sala", _diagnostico_livre(), Forja.bancada)
	if qual == "partida":
		escolha.abrir(lugar, Forja.semente + _partidas, ORDEM_DO_FOGO)
	if qual == "placar":
		placar.abrir(partida, false)
	if qual == "opcoes":
		tela_opcoes.abrir(lugar)
	if qual == "creditos":
		creditos.abrir()
	get_tree().paused = false


## Numa prova às cegas em jogo, o diagnóstico não abre: ele mostraria a luz e
## o motor do controle, e a resposta viria da tela.
func _diagnostico_livre() -> bool:
	return not (estado == "sala" and sala is SalaJogo and not (sala as SalaJogo).diagnostico_livre())


## O HUD aparece no salão e nas salas, sem menu aberto — menos na sala que
## desenha o próprio painel no lugar dele.
func _hud_visivel() -> bool:
	return estado in ["salao", "sala"] and overlay == "" and not (estado == "sala" and sala and not sala.com_hud)


func _fechar_overlay() -> void:
	var overlay_antes_de_fechar := overlay
	overlay = ""
	hud.visible = _hud_visivel()
	painel.escondido = false
	# a sala volta no quadro seguinte: o botão que fechou o menu não vale nela
	if sala is SalaJogo:
		(sala as SalaJogo).congelar.call_deferred(false)
	diagnostico.visible = false
	livro.visible = false
	pausa.visible = false
	escolha.visible = false
	placar.visible = false
	if overlay_antes_de_fechar == "pausa":
		PosFita.rasgo_curto()
	if overlay_antes_de_fechar == "opcoes":
		Opcoes.gravar(Forja.robo)
		Forja.registrar_opcoes()
	tela_opcoes.visible = false
	creditos.visible = false
	titulo.visible = estado == "titulo"
	lobby.visible = estado == "lobby"
	var pode := estado == "salao"
	for p in jogadores:
		p.controlavel = pode and p.visible


## Uma borda do analógico ou do d-pad: -1, 0 ou 1 no eixo pedido.
func _passo(l: int, vertical: bool) -> int:
	var agora: Vector2 = Forja.mover(l)
	var antes: Vector2 = _stick_antes[l]
	var a := agora.y if vertical else agora.x
	var b := antes.y if vertical else antes.x
	var passo := 0
	if a > 0.6 and b <= 0.6:
		passo = 1
	elif a < -0.6 and b >= -0.6:
		passo = -1
	if passo != 0:
		# a navegação clica baixinho, só no controle de quem navegou (H07)
		Forja.som_falante(l, "clique", 0.5)
	return passo


func _quadro_overlay() -> void:
	match overlay:
		"diagnostico":
			for l in 4:
				if Forja.apertou(l, Forja.CIRCULO) or Forja.apertou(l, Forja.CREATE):
					_fechar_overlay()
					return
		"livro":
			for l in 4:
				if Forja.apertou(l, Forja.CIRCULO):
					_fechar_overlay()
					return
				var dy := _passo(l, true)
				var dx := _passo(l, false)
				if dx != 0 or dy != 0:
					livro.navegar(dx, dy)
		"pausa":
			var q := pausa.quem
			var dy2 := _passo(q, true)
			if dy2 != 0:
				pausa.navegar(dy2)
			if Forja.apertou(q, Forja.CRUZ):
				pausa.confirmar()
			elif Forja.apertou(q, Forja.CIRCULO) or Forja.apertou(q, Forja.OPTIONS):
				_fechar_overlay()
		"partida":
			var qp := escolha.quem
			var dy3 := _passo(qp, true)
			if dy3 != 0:
				escolha.navegar(dy3)
			var dx3 := _passo(qp, false)
			if dx3 != 0:
				escolha.trocar(dx3)
			if Forja.apertou(qp, Forja.CRUZ):
				escolha.confirmar()
			elif Forja.apertou(qp, Forja.CIRCULO):
				_fechar_overlay()
		"opcoes":
			var qo := tela_opcoes.quem
			var dyo := _passo(qo, true)
			if dyo != 0:
				tela_opcoes.navegar(dyo)
			var dxo := _passo(qo, false)
			if dxo != 0:
				tela_opcoes.trocar(dxo)
			if Forja.apertou(qo, Forja.CRUZ):
				tela_opcoes.tocou()
			if Forja.apertou(qo, Forja.CIRCULO) or Forja.apertou(qo, Forja.OPTIONS):
				_fechar_overlay()
		"creditos":
			for p in Forja.pads():
				if Forja.pad_apertou(int(p.pad), Forja.CIRCULO) or Forja.pad_apertou(int(p.pad), Forja.CRUZ):
					_fechar_overlay()
					return
		"placar":
			if _virar_espera > 0.0:
				# o ✕ já foi: a fita vira no próximo tempo 1 da música
				_virar_espera -= get_process_delta_time()
				if _virar_espera <= 0.0:
					_virar_a_fita()
				return
			if not placar.pronto():
				# ✕ no meio da animação pula para o fim dela
				for l in 4:
					if Forja.ocupado(l) and Forja.apertou(l, Forja.CRUZ):
						placar.pular()
				return
			if Forja.robo:
				_robo_do_placar()
			for l in 4:
				if Forja.ocupado(l) and Forja.apertou(l, Forja.CRUZ):
					_seguir_a_partida()
					return


func _na_pausa(acao: String) -> void:
	match acao:
		"continuar":
			_fechar_overlay()
		"diagnostico":
			_abrir_overlay("diagnostico", pausa.quem)
		"livro":
			_abrir_overlay("livro", pausa.quem)
		"opcoes":
			_abrir_overlay("opcoes", pausa.quem)
		"salao":
			_fechar_overlay()
			fogo = -1
			partida = null
			_ir_para_o_salao()
		"lobby":
			_fechar_overlay()
			fogo = -1
			partida = null
			_trocar(_ir_para_o_lobby)
		"sair":
			Forja.gravar_relatorio()
			get_tree().quit()


# ------------------------------------------------------------------ câmera --

func _pose_da_camera() -> Array:
	match estado:
		"titulo":
			# a forja de frente, o push-in de 3 % da distância em 8 compassos (parado
			# com o movimento desligado)
			var b := salao.bigorna.global_position
			var olhar := b + Vector3(0, 1.0, 0)
			var k := 1.0 - (0.0 if Opcoes.reduzido() else 0.03 * TelaIntro.entra_sai(fmod(titulo.batidas, 32.0) / 32.0))
			return [olhar + Vector3(0, 0, 9.0) * k, olhar]
		"intro":
			return intro.pose_da_camera()
		"lobby", "intervalo":
			return [Vector3(0, 2.9, 14.2), Vector3(0, 0.55, 4.4)]
		"podio":
			# os pedestais à direita: o placar final fica à esquerda
			var olhar_do_podio := Vector3(-4.6, 0.9, 4.4)
			var pos_do_podio := Vector3(-4.6, 4.0, 19.5)
			return [olhar_do_podio + (pos_do_podio - olhar_do_podio) * Lente.recuo(_lente()), olhar_do_podio]
		"sala":
			if sala:
				return _pose_da_sala()
	# o salão: enquadra quem está jogando
	var soma := Vector3.ZERO
	var n := 0
	var mn := Vector3(INF, 0, INF)
	var mx := Vector3(-INF, 0, -INF)
	for p in jogadores:
		if p.visible:
			var q := p.global_position
			soma += q
			n += 1
			mn = Vector3(minf(mn.x, q.x), 0, minf(mn.z, q.z))
			mx = Vector3(maxf(mx.x, q.x), 0, maxf(mx.z, q.z))
	var c := soma / n if n > 0 else Vector3(0, 0, 2)
	var abertura := maxf(mx.x - mn.x, (mx.z - mn.z) * 1.6) if n > 1 else 0.0
	var dist := clampf(11.5 + abertura * 0.5, 11.5, 18.0)
	c.x = clampf(c.x, -6.0, 6.0)
	c.z = clampf(c.z, -4.0, 5.0)
	# a deriva (arte/01): um pan lateral de 2 % da distância, ida e volta em 32 compassos
	if not Opcoes.reduzido():
		c.x += dist * 0.02 * (_deriva_do_salao() - 0.5)
	return [c + Vector3(0, dist * 0.92, dist * 0.7), c + Vector3(0, 0.6, -3.2)]


## A deriva do salão: 0..1..0 em 32 compassos, curva seno (ENTRA_SAI).
func _deriva_do_salao() -> float:
	var bpm := Ritmo.bpm if Ritmo.bpm > 0.0 else 110.0
	var f := fmod(_t * bpm / 60.0 / 64.0, 2.0)
	var k := f if f < 1.0 else 2.0 - f
	return (1.0 - cos(PI * k)) * 0.5


## A lente de agora, em mm (arte/01); o FOV vem de `Lente.fov`. A G13 põe "lobby".
func _lente() -> float:
	match estado:
		"titulo":
			return 85.0
		"intro":
			return 35.0
		"sala":
			return sala.lente() if sala else 35.0
		"salao", "podio":
			return 35.0
	return Lente.PADRAO


## A tangente de meio campo de visão: (vertical, horizontal).
func _tangentes() -> Vector2:
	_enquadrar()
	var tam := get_viewport().get_visible_rect().size
	var aspecto := tam.x / maxf(tam.y, 1.0)
	var t := tan(deg_to_rad(camera.fov) * 0.5)
	if camera.keep_aspect == Camera3D.KEEP_HEIGHT:
		return Vector2(t, t * aspecto)
	return Vector2(t / aspecto, t)


## A pose da sala pelo modo dela (G05). A direção é sempre a que a sala desenhou; só o centro e a distância mudam.
## `tangentes` (vertical, horizontal) só a prova passa, para fixar uma tela de 16:9; sem ela, vale a da câmera.
func _pose_da_sala(tangentes := Vector2.ZERO) -> Array:
	var olhar: Vector3 = sala.camera_olhar
	var dir: Vector3 = (sala.camera_pos - olhar).normalized()
	var recuo := Lente.recuo(sala.lente())
	var modo: String = sala.camera_modo
	if modo == "grupo" or modo == "corrida":
		var alvos: Array = sala.alvos_da_camera()
		if not alvos.is_empty():
			var tg := tangentes if tangentes != Vector2.ZERO else _tangentes()
			if modo == "grupo":
				return Enquadramento.grupo(alvos, dir, sala.camera_distancia, tg.x, tg.y)
			return Enquadramento.corrida(alvos, sala.camera_frente, dir, sala.camera_distancia, tg.x, tg.y)
		# sem ninguém: a pose fixa da sala, com a distância mínima
		var parada: Vector3 = olhar + (sala.camera_pos - olhar) * recuo
		return [parada, olhar]
	var puxa := Vector3.ZERO
	if modo == "dupla" and sala.camera_foco != Vector3.ZERO:
		puxa = (sala.camera_foco - olhar) * 0.15
		puxa.y = 0.0
		puxa = puxa.limit_length(1.5)
	return [olhar + (sala.camera_pos - olhar) * recuo + puxa, olhar + puxa]


## As salas são desenhadas para 16:9. Numa tela mais estreita (o Steam Deck,
## 16:10), a câmera guarda a largura em vez da altura: as quatro raias
## continuam inteiras, e sobra chão em cima e embaixo. O FOV vem da lente do
## momento (`_lente()`, em mm).
func _enquadrar() -> void:
	var tam := get_viewport().get_visible_rect().size
	if tam.y <= 0.0:
		return
	var fov_v := Lente.fov(_lente())
	if tam.x / tam.y < 16.0 / 9.0 - 0.01:
		camera.keep_aspect = Camera3D.KEEP_WIDTH
		camera.fov = rad_to_deg(2.0 * atan(tan(deg_to_rad(fov_v) * 0.5) * 16.0 / 9.0))
	else:
		camera.keep_aspect = Camera3D.KEEP_HEIGHT
		camera.fov = fov_v


func _mover_camera(dt: float) -> void:
	_enquadrar()
	var pose := _pose_da_camera()
	var k := minf(1.0, dt * (1.2 if estado in ["titulo", "intro"] else 4.0))
	_cam_pos = _cam_pos.lerp(pose[0], k)
	_cam_olhar = _cam_olhar.lerp(pose[1], k)
	camera.global_position = _cam_pos
	camera.look_at(_cam_olhar)
	if estado == "sala" and sala and not Opcoes.reduzido():
		# o tremor anda no plano da câmera, sem roll (01, regra 4); nada passa de 0,08 m
		var a: float = maxf(sala.abalo, minf(0.08, 0.12 * sala.tremor))
		if a > 0.0:
			var b := camera.global_basis
			camera.global_position += (b.x * sin(_t * 71.0) + b.y * sin(_t * 53.0 + 1.3)) * a
