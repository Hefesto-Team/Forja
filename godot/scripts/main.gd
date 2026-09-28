extends Node3D
## FORJA, a Hefesto Tech Demo: quatro jogadores no mesmo sofá, cada um com um
## DualSense, num salão de forja com uma sala por feature do controle.
##
## Título → lobby (quem joga: cada controle ganha um lugar P1..P4, a luz e as
## lâmpadas do lugar) → salão (os portões das salas) ⇄ salas. Por cima de
## tudo: o diagnóstico ao vivo (Create), o livro da sessão e a pausa (Options).
##
## Toda entrada e toda saída passam pelo autoload Forja, por lugar (0..3).

const SALAS := {
	"centelha": preload("res://scripts/salas/centelha.gd"),
	"molde": preload("res://scripts/salas/molde.gd"),
	"galeria": preload("res://scripts/salas/galeria.gd"),
	"impacto": preload("res://scripts/salas/impacto.gd"),
	"viga": preload("res://scripts/salas/viga.gd"),
	"voz": preload("res://scripts/salas/voz.gd"),
	"caminhos": preload("res://scripts/salas/caminhos.gd"),
	"canto": preload("res://scripts/salas/canto.gd"),
	"prova": preload("res://scripts/salas/prova.gd"),
	"bancada": preload("res://scripts/salas/bancada.gd"),
}

## A Prova de Fogo: todas as salas, na ordem do percurso, e o livro no fim.
const ORDEM_DO_FOGO := ["centelha", "viga", "molde", "impacto", "galeria", "canto", "caminhos", "voz", "prova"]

var estado := "titulo"
var fogo := -1  ## a sala da Prova de Fogo em curso (índice em ORDEM_DO_FOGO); -1 fora dela
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
var diagnostico: Diagnostico
var livro: Livro
var pausa: Pausa
var cortina: ColorRect
var overlay := ""  ## "", "diagnostico", "livro", "pausa"
var _trocando := false
var _stick_antes := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var _portao_perto := ""


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
	_mostrar("titulo")
	_abrir_pelos_args.call_deferred()


func _ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Tema.CASA
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#6d64a0")
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.9
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.6
	env.fog_enabled = true
	env.fog_light_color = Color("#241f33")
	env.fog_density = 0.012
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _interface() -> void:
	ui = Control.new()
	ui.name = "UI"
	ui.theme = Tema.tema()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$Interface.add_child(ui)
	titulo = TelaTitulo.new()
	lobby = TelaLobby.new()
	hud = HudJogo.new()
	painel = PainelSala.new()
	diagnostico = Diagnostico.new()
	livro = Livro.new()
	pausa = Pausa.new()
	for c in [titulo, lobby, hud, painel, diagnostico, livro, pausa]:
		ui.add_child(c)
	cortina = ColorRect.new()
	cortina.color = Color(Tema.CASA, 0.0)
	cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cortina.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(cortina)
	diagnostico.visible = false
	livro.visible = false
	pausa.visible = false


## `-- --sala=galeria` abre direto na sala, com todo controle já dentro (é o que
## uma folha de teste pede: "abra na Galeria"). `--tela=` abre numa tela.
func _abrir_pelos_args() -> void:
	var tela := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tela="):
			tela = a.substr(7)
	var sala_pedida := Forja.sala_pedida
	if sala_pedida == "giro":
		sala_pedida = "viga"
	var pede_o_fogo := "--prova-de-fogo" in OS.get_cmdline_user_args()
	var bancada := Forja.experimento != ""
	if sala_pedida != "" or pede_o_fogo or bancada or tela in ["lobby", "salao", "diagnostico", "livro"]:
		await get_tree().process_frame
		await get_tree().process_frame
		_todos_entram()
	if bancada:
		# a bancada do experimental/ no lugar do salão
		_ir_para_o_salao(false)
		_entrar_na_sala("bancada", false)
		return
	if pede_o_fogo:
		_ir_para_o_salao(false)
		_comecar_a_prova_de_fogo(false)
		return
	if sala_pedida != "" and SALAS.has(sala_pedida):
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


# ------------------------------------------------------------------ estados --

func _mostrar(qual: String) -> void:
	estado = qual
	titulo.visible = qual == "titulo"
	lobby.visible = qual == "lobby"
	hud.visible = qual in ["salao", "sala"] and overlay == ""
	salao.pedestais_no.visible = qual == "lobby"
	if qual == "lobby":
		for l in 4:
			var p := jogadores[l]
			p.controlavel = false
			p.global_position = salao.pedestais[l]
			p.rotation.y = 0.0
		_sincronizar_jogadores()


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


func _trocar(acao: Callable) -> void:
	if _trocando:
		return
	_trocando = true
	var tw := create_tween()
	tw.tween_property(cortina, "color:a", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	acao.call()
	_cam_pos = _pose_da_camera()[0]
	_cam_olhar = _pose_da_camera()[1]
	var tw2 := create_tween()
	tw2.tween_property(cortina, "color:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
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
			var volta := salao.saida_do_portao(sala_id, p.lugar) if sala_id != "" else Vector3(-3.0 + i * 2.0, 0.05, 3.2)
			p.global_position = volta
			p.rotation.y = PI
			p.controlavel = true
			p.visible = Forja.ocupado(p.lugar)
			i += 1
		_mostrar("salao")
		hud.sala = {}
		hud.status_da_sala = ["", "", "", ""]
	if com_cortina:
		_trocar(feito)
	else:
		feito.call()
		_cam_pos = _pose_da_camera()[0]
		_cam_olhar = _pose_da_camera()[1]


func _entrar_na_sala(id: String, com_cortina := true) -> void:
	if not SALAS.has(id):
		return
	var feito := func():
		_sair_da_sala()
		if salao.get_parent() != null:
			remove_child(salao)
		sala_id = id
		sala = SALAS[id].new()
		sala.name = "Sala"
		add_child(sala)
		var js: Array = []
		for p in jogadores:
			if p.visible:
				js.append(p)
		if fogo >= 0 and sala is SalaJogo:
			var sj := sala as SalaJogo
			sj.na_prova_de_fogo = "Prova de Fogo · sala %d de %d" % [fogo + 1, ORDEM_DO_FOGO.size()]
			sj.seguir = "seguir a Prova de Fogo" if fogo + 1 < ORDEM_DO_FOGO.size() else "o livro da sessão"
		sala.entrar(js)
		sala.terminou.connect(_ao_terminar_a_sala)
		painel.sala = sala
		hud.create_livre = not (sala is SalaJogo and (((sala as SalaJogo).botoes_pedidos >> Forja.CREATE) & 1
			or (sala as SalaJogo).cega))
		_mostrar("sala")
		hud.sala = {"nome": sala.nome, "acao": sala.acao}
		hud.placa = {}
	if com_cortina:
		_trocar(feito)
	else:
		feito.call()
		_cam_pos = _pose_da_camera()[0]
		_cam_olhar = _pose_da_camera()[1]


## A sala acabou e alguém apertou ✕ no veredito: de volta ao salão — ou, na
## Prova de Fogo, a sala seguinte, e o livro no fim.
func _ao_terminar_a_sala() -> void:
	# o robô aperta ✕ a cada quadro até a cortina fechar: uma troca só
	if estado != "sala" or overlay != "" or _trocando:
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
		_ir_para_o_salao()
		get_tree().create_timer(0.9).timeout.connect(func() -> void:
			if estado == "salao" and overlay == "":
				_abrir_overlay("livro", 0))
		return
	_ir_para_o_salao()


## Todas as salas que medem, na ordem do percurso, sem voltar ao salão.
func _comecar_a_prova_de_fogo(com_cortina := true) -> void:
	fogo = 0
	Forja.registrar("Prova de Fogo: começou (semente %d)" % Forja.semente)
	Forja.evento("sala", 0, {"evento": "prova_de_fogo", "o": "começou"})
	_entrar_na_sala(ORDEM_DO_FOGO[0], com_cortina)


func _sair_da_sala() -> void:
	painel.sala = null
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
	if estado == "lobby" or estado == "titulo":
		_sincronizar_jogadores()
	if estado == "lobby":
		for l in 4:
			lobby.pes[l] = camera.unproject_position(salao.pedestais[l])
			lobby.visual[l] = [ForjaPlayer.NOME_DO_MODELO[jogadores[l].modelo_i], ForjaPlayer.ITENS[jogadores[l].item_i].nome]
	if not _trocando:
		if overlay != "":
			_quadro_overlay()
		else:
			match estado:
				"titulo": _quadro_titulo()
				"lobby": _quadro_lobby(dt)
				"salao": _quadro_salao()
				"sala": _quadro_sala()
	if sala:
		for l in 4:
			hud.status_da_sala[l] = sala.status(l) if Forja.ocupado(l) else ""
	_mover_camera(dt)
	for l in 4:
		_stick_antes[l] = Forja.mover(l)


func _algum_pad_apertou(botao: int) -> int:
	for p in Forja.pads():
		if Forja.pad_apertou(int(p.pad), botao):
			return int(p.pad)
	return -1


func _quadro_titulo() -> void:
	if not Forja.modulo:
		if Forja.apertou(0, Forja.CRUZ):
			_trocar(_ir_para_o_lobby)
		return
	if Forja.conectados() == 0:
		if Forja.tecla_apertou(KEY_ENTER) or Forja.tecla_apertou(KEY_SPACE):
			if Forja.jogar_no_teclado():
				_trocar(_ir_para_o_lobby)
		return
	if _algum_pad_apertou(Forja.CRUZ) >= 0 or _algum_pad_apertou(Forja.OPTIONS) >= 0:
		_trocar(_ir_para_o_lobby)


func _quadro_lobby(dt: float) -> void:
	# quem ainda não tem lugar entra com ✕ (e esse ✕ não conta como pronto)
	var chegou := [false, false, false, false]
	for p in Forja.pads():
		if int(p.lugar) < 0 and Forja.pad_apertou(int(p.pad), Forja.CRUZ):
			var l := Forja.entrar(int(p.pad))
			if l >= 0:
				chegou[l] = true
				Forja.registrar("P%d entrou no lobby" % (l + 1))
	# sem módulo, o teclado é o P1
	if not Forja.modulo:
		lobby.prontos[0] = lobby.prontos[0] or Forja.apertou(0, Forja.CRUZ)
	for l in 4:
		if not Forja.ocupado(l) or chegou[l]:
			continue
		# antes de ficar pronto, cada um escolhe o visual: ◀▶ o boneco, ▲▼ o que leva
		if not lobby.prontos[l]:
			var dx := _passo(l, false)
			var dy := _passo(l, true)
			if dx != 0 or dy != 0:
				var p := jogadores[l]
				p.visual(p.modelo_i + dx, p.item_i + dy)
				p.gesto("interact-right", 0.5)
				Forja.vibrar(l, 0.0, 0.25, 40)
		if Forja.apertou(l, Forja.CRUZ) and not lobby.prontos[l]:
			lobby.prontos[l] = true
			jogadores[l].gesto("emote-yes", 1.2)
			Forja.vibrar(l, 0.0, 0.5, 90)
			Forja.evento("visual", l + 1, {"boneco": ForjaPlayer.NOME_DO_MODELO[jogadores[l].modelo_i],
				"leva": ForjaPlayer.ITENS[jogadores[l].item_i].nome})
		elif Forja.apertou(l, Forja.CIRCULO):
			if lobby.prontos[l]:
				lobby.prontos[l] = false
			else:
				Forja.sair(l)
				Forja.registrar("P%d saiu do lobby" % (l + 1))
	_sincronizar_jogadores()
	var ocupados := 0
	var prontos := 0
	for l in 4:
		if Forja.ocupado(l):
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
		_portao_perto = perto
	if perto == "":
		_perto_da_bigorna()
		return
	var dados: Dictionary = salao.portoes[perto].dados
	hud.placa = {"nome": dados.nome, "sobre": dados.sobre, "aberta": dados.aberta}
	if dados.aberta:
		for p in jogadores:
			if p.visible and Forja.apertou(p.lugar, Forja.CRUZ):
				_entrar_na_sala(perto)
				return
	elif quem >= 0 and Forja.apertou(quem, Forja.CRUZ):
		Forja.vibrar(quem, 0.2, 0.0, 60)


## A bigorna no meio do salão: ✕ entra n'A Prova, △ acende a Prova de Fogo.
func _perto_da_bigorna() -> void:
	var centro := salao.bigorna.global_position
	for p in jogadores:
		if not p.visible:
			continue
		if Vector2(p.global_position.x - centro.x, p.global_position.z - centro.z).length() > 3.1:
			continue
		hud.placa = {"nome": "A Prova", "sobre": "tudo junto, duas equipes · △ a Prova de Fogo", "aberta": true}
		for q in jogadores:
			if not q.visible:
				continue
			if Forja.apertou(q.lugar, Forja.CRUZ):
				_entrar_na_sala("prova")
				return
			if Forja.apertou(q.lugar, Forja.TRIANGULO):
				Som.tocar("martelo", centro + Vector3(0, 1, 0))
				_comecar_a_prova_de_fogo()
				return
		return
	hud.placa = {}


func _quadro_sala() -> void:
	_atalhos_de_overlay()


## Create abre o diagnóstico, Options a pausa. Devolve true se abriu: o resto
## do quadro não roda (um ✕ no mesmo quadro não entra numa sala por baixo).
## Numa sala que pede o Create (a runa d'A Centelha), ele é da sala: o
## diagnóstico abre pela pausa.
func _atalhos_de_overlay() -> bool:
	var create_livre := not (sala is SalaJogo and ((sala as SalaJogo).botoes_pedidos >> Forja.CREATE) & 1)
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
	if qual == "diagnostico" and not _diagnostico_livre():
		hud.mostrar_aviso("prova às cegas: o diagnóstico volta no fim da sala")
		return
	overlay = qual
	diagnostico.visible = qual == "diagnostico"
	livro.visible = qual == "livro"
	pausa.visible = qual == "pausa"
	for p in jogadores:
		p.controlavel = false
	hud.visible = false
	painel.escondido = true
	if sala is SalaJogo:
		(sala as SalaJogo).congelar(true)
	if qual == "livro":
		livro.abrir()
	if qual == "pausa":
		pausa.abrir(lugar, estado == "sala", _diagnostico_livre())
	get_tree().paused = false


## Numa prova às cegas em jogo, o diagnóstico não abre: ele mostraria a luz e
## o motor do controle, e a resposta viria da tela.
func _diagnostico_livre() -> bool:
	return not (estado == "sala" and sala is SalaJogo and not (sala as SalaJogo).diagnostico_livre())


func _fechar_overlay() -> void:
	overlay = ""
	hud.visible = estado in ["salao", "sala"]
	painel.escondido = false
	# a sala volta no quadro seguinte: o botão que fechou o menu não vale nela
	if sala is SalaJogo:
		(sala as SalaJogo).congelar.call_deferred(false)
	diagnostico.visible = false
	livro.visible = false
	pausa.visible = false
	var pode := estado == "salao"
	for p in jogadores:
		p.controlavel = pode and p.visible


## Uma borda do analógico ou do d-pad: -1, 0 ou 1 no eixo pedido.
func _passo(l: int, vertical: bool) -> int:
	var agora: Vector2 = Forja.mover(l)
	var antes: Vector2 = _stick_antes[l]
	var a := agora.y if vertical else agora.x
	var b := antes.y if vertical else antes.x
	if a > 0.6 and b <= 0.6:
		return 1
	if a < -0.6 and b >= -0.6:
		return -1
	return 0


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


func _na_pausa(acao: String) -> void:
	match acao:
		"continuar":
			_fechar_overlay()
		"diagnostico":
			_abrir_overlay("diagnostico", pausa.quem)
		"livro":
			_abrir_overlay("livro", pausa.quem)
		"salao":
			_fechar_overlay()
			fogo = -1
			_ir_para_o_salao()
		"lobby":
			_fechar_overlay()
			fogo = -1
			_trocar(_ir_para_o_lobby)
		"sair":
			Forja.gravar_relatorio()
			get_tree().quit()


# ------------------------------------------------------------------ câmera --

func _pose_da_camera() -> Array:
	match estado:
		"titulo":
			var a := _t * 0.08
			var centro := salao.bigorna.global_position + Vector3(0, 1.3, 0)
			return [centro + Vector3(sin(a) * 7.5 + 3.0, 3.2, cos(a) * 7.5 + 2.0), centro]
		"lobby":
			return [Vector3(0, 2.9, 14.2), Vector3(0, 0.55, 4.4)]
		"sala":
			if sala:
				return [sala.camera_pos, sala.camera_olhar]
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
	return [c + Vector3(0, dist * 0.92, dist * 0.7), c + Vector3(0, 0.6, -3.2)]


func _mover_camera(dt: float) -> void:
	var pose := _pose_da_camera()
	var k := minf(1.0, dt * (1.2 if estado == "titulo" else 4.0))
	_cam_pos = _cam_pos.lerp(pose[0], k)
	_cam_olhar = _cam_olhar.lerp(pose[1], k)
	camera.global_position = _cam_pos
	camera.look_at(_cam_olhar)
	if estado == "sala" and sala and sala.tremor > 0.0:
		var k2: float = sala.tremor
		camera.global_position += Vector3(sin(_t * 71.0), sin(_t * 53.0 + 1.3), 0.0) * 0.12 * k2
		camera.rotate_object_local(Vector3.BACK, sin(_t * 47.0) * 0.012 * k2)
