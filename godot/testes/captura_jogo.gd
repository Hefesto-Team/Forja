extends Node
## As fotos do jogo para a revisão de cada marco: abre a cena principal com
## quatro DualSense simulados e passa pelas telas apertando os botões DELES
## (o caminho inteiro do módulo roda). Nada de aparelho, nada de janela real:
##
##   godot --path godot --resolution 1920x1080 res://testes/captura_jogo.tscn -- --simular=4 --robo --semente=7
##
## SAIDA=<pasta> diz onde gravar os PNG; FOTOS=titulo,lobby,... escolhe quais.

var jogo: Node
var q := 0
var pasta := ""
var roteiro: Array = []
var _passo := 0
var _espera := 0
var _rodando := false  ## um passo com espera dentro não deixa o próximo começar


func _ready() -> void:
	pasta = OS.get_environment("SAIDA")
	if pasta == "":
		pasta = OS.get_user_data_dir()
	jogo = load("res://scenes/main.tscn").instantiate()
	add_child(jogo)
	var pedidas := OS.get_environment("FOTOS")
	roteiro = [
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
		["sala", "viga"], ["giro", 0, Vector3(0, 2.0, 0)], ["espera", 70], ["giro", 0, Vector3.ZERO], ["foto", "sala_viga"],
		["sala", "voz"], ["espera", 70], ["foto", "sala_voz"],
		["sala", "prova"], ["espera", 90], ["foto", "sala_prova"],
		["fim"],
	]
	if pedidas != "":
		var so := pedidas.split(",")
		for i in roteiro.size():
			if roteiro[i][0] == "foto" and not (roteiro[i][1] in so):
				roteiro[i] = ["espera", 1]


func _process(_dt: float) -> void:
	q += 1
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
				var img := get_viewport().get_texture().get_image()
				img.save_png(pasta.path_join(p[1] + ".png"))
				print("foto: ", p[1])
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
