extends Node
## As fotos do jogo para a revisão de cada marco: abre a cena principal com
## quatro DualSense simulados e passa pelas telas apertando os botões DELES
## (o caminho inteiro do módulo roda). Nada de aparelho, nada de janela real:
##
##   godot --path godot --resolution 1920x1080 res://testes/captura_jogo.tscn -- --simular=4 --robo --semente=7
##
## SAIDA=<pasta> diz onde gravar os PNG; FOTOS=titulo,lobby,... escolhe quais.
## ROTEIRO=salas passa pelas salas que medem (aviso, jogo e veredito de cada
## uma, com o robô jogando). RAPIDO=1 roda numa janela pequena entre as fotos
## e volta ao tamanho cheio só para cada foto (num renderizador por software,
## é o que cabe no tempo).

var jogo: Node
var q := 0
var pasta := ""
var roteiro: Array = []
var _passo := 0
var _espera := 0
var _rodando := false  ## um passo com espera dentro não deixa o próximo começar
var _rapido := false


func _ready() -> void:
	pasta = OS.get_environment("SAIDA")
	if pasta == "":
		pasta = OS.get_user_data_dir()
	jogo = load("res://scenes/main.tscn").instantiate()
	add_child(jogo)
	var pedidas := OS.get_environment("FOTOS")
	_rapido = OS.get_environment("RAPIDO") == "1"
	if _rapido:
		_janela(false)
	roteiro = _roteiro_das_telas() if OS.get_environment("ROTEIRO") != "salas" else _roteiro_das_salas()
	if pedidas != "":
		var so := pedidas.split(",")
		for i in roteiro.size():
			if roteiro[i][0] == "foto" and not (roteiro[i][1] in so):
				roteiro[i] = ["espera", 1]


func _roteiro_das_telas() -> Array:
	return [
		["espera", 70], ["foto", "titulo"],
		["aperta", 0, Forja.CRUZ], ["espera", 40],
		["aperta", 0, Forja.CRUZ], ["aperta", 1, Forja.CRUZ], ["aperta", 2, Forja.CRUZ], ["espera", 40],
		["aperta", 0, Forja.CRUZ], ["aperta", 1, Forja.DIREITA], ["aperta", 2, Forja.CIMA], ["espera", 50], ["foto", "lobby"],
		["aperta", 1, Forja.CRUZ], ["aperta", 2, Forja.CRUZ], ["espera", 150], ["foto", "salao"],
		["posiciona", 0, Vector3(2.0, 0.05, -6.0), PI], ["posiciona", 1, Vector3(-2.6, 0.05, 2.4), PI * 0.8],
		["posiciona", 2, Vector3(4.8, 0.05, 1.0), PI * 1.2],
		["anda", 0, Vector2(0.0, -0.5), 12], ["espera", 40], ["foto", "salao_portao"],
		["segura", 0, Forja.CRUZ, true], ["eixo", 1, Forja.R2, 0.8], ["eixo", 0, Forja.LX, -0.9],
		["dedo", 2, 0, true, 0.3, 0.4], ["dedo", 2, 1, true, 0.72, 0.62],
		["aperta", 0, Forja.CREATE], ["espera", 30], ["foto", "diagnostico"],
		["segura", 0, Forja.CRUZ, false], ["eixo", 1, Forja.R2, 0.0], ["eixo", 0, Forja.LX, 0.0],
		["dedo", 2, 0, false, 0.0, 0.0], ["dedo", 2, 1, false, 0.0, 0.0],
		["aperta", 0, Forja.CIRCULO], ["espera", 20],
		["vereditos"], ["aperta", 0, Forja.OPTIONS], ["espera", 20], ["foto", "pausa"],
		["aperta", 0, Forja.BAIXO], ["espera", 6], ["aperta", 0, Forja.BAIXO], ["espera", 6],
		["aperta", 0, Forja.CRUZ], ["espera", 40], ["foto", "livro"],
		["aperta", 0, Forja.CIRCULO], ["espera", 20],
		["sala", "galeria"], ["espera", 70], ["eixo", 0, Forja.R2, 1.0], ["eixo", 2, Forja.R2, 1.0], ["espera", 14], ["foto", "sala_galeria"],
		["eixo", 0, Forja.R2, 0.0], ["eixo", 2, Forja.R2, 0.0],
		["sala", "impacto"], ["espera", 150], ["foto", "sala_impacto"],
		["sala", "voz"], ["espera", 70], ["foto", "sala_voz"],
		["sala", "prova"], ["espera", 90], ["foto", "sala_prova"],
		["fim"],
	]


## As salas que medem, jogadas pelo robô: o aviso (quem já está pronto), o
## jogo em dois momentos e o veredito.
func _roteiro_das_salas() -> Array:
	var no_salao := func() -> bool:
		return jogo.estado == "salao" and not jogo._trocando
	var fase := func(f: String, t: float) -> Callable:
		return func() -> bool:
			return jogo.sala is SalaJogo and jogo.sala.fase == f and jogo.sala.t_fase >= t
	var p1 := func(cond: Callable) -> Callable:
		return func() -> bool:
			return jogo.sala is SalaJogo and jogo.sala.fase == "jogo" and cond.call(jogo.sala, jogo.sala.j[0])
	var runa_analogica := func(sala, e) -> bool:
		var r = sala._runa_atual(0)
		return r != null and r.tipo == "analogico" and SalaCentelha._contar(int(e.setores)) >= 4
	var fole_no_fundo := func(sala, e) -> bool:
		var r = sala._runa_atual(0)
		return r != null and r.tipo == "gatilho" and e.estagio == 1
	var nos_sinos := func(_sala, e) -> bool:
		return e.trecho == 1 and e.t > 1.2
	var na_pedra := func(_sala, e) -> bool:
		return e.trecho == 2 and e.golpes >= 1
	var tracando := func(_sala, e) -> bool:
		return e.passo == 0 and e.ponto >= 2
	var abrindo := func(_sala, e) -> bool:
		return e.passo == 1 and e.abertura > 0.3
	var carimbando := func(sala, e) -> bool:
		return e.passo == 2 and sala._no_ponto(e)
	return [
		["espera", 10], ["aperta", 0, Forja.CRUZ], ["espera", 40],
		["aperta", 0, Forja.CRUZ], ["aperta", 1, Forja.CRUZ], ["aperta", 2, Forja.CRUZ], ["aperta", 3, Forja.CRUZ], ["espera", 10],
		["aperta", 0, Forja.CRUZ], ["aperta", 1, Forja.CRUZ], ["aperta", 2, Forja.CRUZ], ["aperta", 3, Forja.CRUZ],
		["ate", no_salao],
		["sala", "centelha"], ["ate", fase.call("aviso", 1.7)], ["foto", "centelha_aviso"],
		["ate", fase.call("jogo", 7.0)], ["foto", "centelha_jogo"],
		["ate", p1.call(runa_analogica)], ["foto", "centelha_analogico"],
		["ate", p1.call(fole_no_fundo)], ["foto", "centelha_fole"],
		["ate", fase.call("fim", 1.4)], ["foto", "centelha_fim"],
		["ate", no_salao],
		["sala", "viga"], ["ate", fase.call("aviso", 1.7)], ["foto", "viga_aviso"],
		["ate", fase.call("jogo", 6.0)], ["foto", "viga_travessia"],
		["ate", p1.call(nos_sinos)], ["foto", "viga_sinos"],
		["ate", p1.call(na_pedra)], ["foto", "viga_pedra"],
		["ate", fase.call("fim", 1.4)], ["foto", "viga_fim"],
		["ate", no_salao],
		["sala", "molde"], ["ate", fase.call("aviso", 1.7)], ["foto", "molde_aviso"],
		["ate", p1.call(tracando)], ["foto", "molde_tracar"],
		["ate", p1.call(abrindo)], ["foto", "molde_abrir"],
		["ate", p1.call(carimbando)], ["foto", "molde_carimbar"],
		["ate", fase.call("fim", 1.4)], ["foto", "molde_fim"],
		["ate", no_salao], ["foto", "salao_depois"],
		["fim"],
	]


## Cheia para a foto; pequena (e o 3D pela metade) para andar depressa.
func _janela(cheia: bool) -> void:
	get_window().size = Vector2i(1920, 1080) if cheia else Vector2i(480, 270)
	get_viewport().scaling_3d_scale = 1.0 if cheia else 0.5


func _process(_dt: float) -> void:
	q += 1
	if q % 300 == 0:
		print("quadro %d em %.0f s (janela %s)" % [q, Time.get_ticks_msec() / 1000.0, get_window().size])
	if _rodando:
		return
	if _espera > 0:
		_espera -= 1
		return
	_rodando = true
	await _rodar()
	_rodando = false


func _rodar() -> void:
	while _passo < roteiro.size():
		var p: Array = roteiro[_passo]
		_passo += 1
		match p[0]:
			"espera":
				_espera = p[1]
				return
			"foto":
				if _rapido:
					_janela(true)
					for i in 6:
						await get_tree().process_frame
				var img := get_viewport().get_texture().get_image()
				img.save_png(pasta.path_join(p[1] + ".png"))
				print("foto: ", p[1], " (quadro ", q, ")")
				if _rapido:
					_janela(false)
			"ate":
				var cond: Callable = p[1]
				var n := 0
				while not cond.call() and n < 20000:
					await get_tree().process_frame
					n += 1
				if n >= 20000:
					printerr("o momento não chegou: passo %d" % _passo)
			"aperta":
				Forja.ctl.simulador_botao(p[1], p[2], true)
				await get_tree().process_frame
				await get_tree().process_frame
				Forja.ctl.simulador_botao(p[1], p[2], false)
				await get_tree().process_frame
			"segura":
				Forja.ctl.simulador_botao(p[1], p[2], p[3])
			"eixo":
				Forja.ctl.simulador_eixo(p[1], p[2], p[3])
			"giro":
				Forja.ctl.simulador_giro(p[1], p[2])
			"dedo":
				Forja.ctl.simulador_dedo(p[1], p[2], p[3], p[4], p[5])
			"anda":
				Forja.ctl.simulador_eixo(p[1], Forja.LX, p[2].x)
				Forja.ctl.simulador_eixo(p[1], Forja.LY, p[2].y)
				for i in p[3]:
					await get_tree().process_frame
				Forja.ctl.simulador_eixo(p[1], Forja.LX, 0.0)
				Forja.ctl.simulador_eixo(p[1], Forja.LY, 0.0)
			"posiciona":
				var j: Node3D = jogo.jogadores[p[1]]
				j.global_position = p[2]
				j.rotation.y = p[3]
			"vereditos":
				Forja.veredito(0, "botoes", Forja.PASSOU, Forja.NIVEL_REAGIU, "apertar ✕ ○ □ △", "os quatro chegaram")
				Forja.veredito(1, "vibracao_forte", Forja.FALHOU, Forja.NIVEL_OBEDECEU, "motor esquerdo, às cegas", "a pessoa disse direita duas vezes")
				Forja.veredito(2, "lightbar", Forja.PASSOU, Forja.NIVEL_OBEDECEU, "cor sorteada: verde", "a pessoa disse verde")
			"sala":
				jogo._entrar_na_sala(p[1], false)
			"fim":
				get_tree().quit()
				return
