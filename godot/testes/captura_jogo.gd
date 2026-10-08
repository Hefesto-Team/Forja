extends Node
## As fotos do jogo para a revisão de cada marco: abre a cena principal com
## quatro DualSense simulados e passa pelas telas apertando os botões DELES
## (o caminho inteiro do módulo roda). Nada de aparelho, nada de janela real:
##
##   godot --fixed-fps 60 --path godot --resolution 1920x1080 res://testes/captura_jogo.tscn -- --simular=4 --robo --semente=7
##
## O --fixed-fps 60 é obrigatório: o roteiro espera pelo relógio do jogo, e sem
## ele as fotos saem nos momentos errados.
##
## SAIDA=<pasta> diz onde gravar os PNG; FOTOS=titulo,lobby,... escolhe quais.
## ROTEIRO=salas passa pelas salas que medem (aviso, jogo e veredito de cada
## uma, com o robô jogando); SALAS=impacto,galeria escolhe quais. SEM_TREMOR=1
## desliga o tremor da câmera (para medir o clarão d'A Voz).
## O diagnóstico e o livro, só com `-- --bancada` (sem ele o jogo não os tem).
## ROTEIRO=bancada, com -- --experimento=ID, fotografa a bancada do
## experimental/. ROTEIRO=partida joga uma partida curta: a placa da bigorna,
## a escolha, o placar entre as salas e o pódio. RAPIDO=1 roda numa janela pequena entre as fotos e volta ao
## tamanho cheio só para cada foto (num renderizador por software, é o que
## cabe no tempo).

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
	# a medida do clarão d'A Voz (scripts/medir_clarao.gd) compara dois quadros
	# parados: sem o tremor da câmera, o que muda é a luz
	if OS.get_environment("SEM_TREMOR") == "1":
		Opcoes.tremor = false
	if _rapido:
		_janela(false)
	match OS.get_environment("ROTEIRO"):
		"salas":
			roteiro = _roteiro_das_salas()
		"bancada":
			roteiro = _roteiro_da_bancada()
		"partida":
			roteiro = _roteiro_da_partida()
		"extras":
			roteiro = _roteiro_dos_extras()
		"trailer":
			roteiro = _roteiro_do_trailer()
		_:
			roteiro = _roteiro_das_telas()
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
		["aviso", "P2 saiu do cabo: ligue de novo para voltar ao mesmo lugar"], ["aviso", "P2 voltou"],
		["espera", 12], ["foto", "aviso"],
		["segura", 0, Forja.CRUZ, true], ["eixo", 1, Forja.R2, 0.8], ["eixo", 0, Forja.LX, -0.9],
		["dedo", 2, 0, true, 0.3, 0.4], ["dedo", 2, 1, true, 0.72, 0.62],
		["aperta", 0, Forja.CREATE], ["espera", 30], ["foto", "diagnostico"] if Forja.bancada else ["espera", 1],
		["segura", 0, Forja.CRUZ, false], ["eixo", 1, Forja.R2, 0.0], ["eixo", 0, Forja.LX, 0.0],
		["dedo", 2, 0, false, 0.0, 0.0], ["dedo", 2, 1, false, 0.0, 0.0],
		["aperta", 0, Forja.CIRCULO], ["espera", 20],
		["vereditos"], ["aperta", 0, Forja.OPTIONS], ["espera", 20], ["foto", "pausa"],
		["aperta", 0, Forja.BAIXO] if Forja.bancada else ["espera", 1], ["espera", 6],
		["aperta", 0, Forja.BAIXO] if Forja.bancada else ["espera", 1], ["espera", 6],
		["aperta", 0, Forja.CRUZ] if Forja.bancada else ["espera", 1], ["espera", 40],
		["foto", "livro"] if Forja.bancada else ["espera", 1],
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
	var na_sala := func(cond: Callable) -> Callable:
		return func() -> bool:
			return jogo.sala is SalaJogo and jogo.sala.fase == "jogo" and cond.call(jogo.sala)
	# os momentos de cada sala: [a foto, quando]
	var momentos := {
		"centelha": [
			["centelha_jogo", fase.call("jogo", 7.0)],
			["centelha_analogico", p1.call(func(sala, e) -> bool:
				var r = sala._runa_atual(0)
				return r != null and r.tipo == "analogico" and SalaCentelha._contar(int(e.setores)) >= 4)],
			["centelha_fole", p1.call(func(sala, e) -> bool:
				var r = sala._runa_atual(0)
				return r != null and r.tipo == "gatilho" and e.estagio == 1)],
		],
		"viga": [
			["viga_travessia", fase.call("jogo", 6.0)],
			["viga_sinos", p1.call(func(_sala, e) -> bool: return e.trecho == 1 and e.t > 1.2)],
			["viga_pedra", p1.call(func(_sala, e) -> bool: return e.trecho == 2 and e.golpes >= 1)],
		],
		"molde": [
			["molde_tracar", p1.call(func(_sala, e) -> bool: return e.passo == 0 and e.ponto >= 2)],
			["molde_abrir", p1.call(func(_sala, e) -> bool: return e.passo == 1 and e.abertura > 0.3)],
			["molde_carimbar", p1.call(func(sala, e) -> bool: return e.passo == 2 and sala._no_ponto(e))],
		],
		"impacto": [
			["impacto_golpe", na_sala.call(func(sala) -> bool: return sala.estado == SalaImpacto.GOLPE and sala.t_estado > 0.25)],
			["impacto_escudo", na_sala.call(func(sala) -> bool:
				return sala.estado == SalaImpacto.VOANDO and sala.t_estado > 0.22 and sala.resposta == sala.atual.y)],
			["impacto_pergunta", na_sala.call(func(sala) -> bool: return sala.estado == SalaImpacto.PERGUNTA and sala.t_estado > 1.2)],
			["impacto_resposta", na_sala.call(func(sala) -> bool: return sala.estado == SalaImpacto.RESPOSTA and sala.t_estado > 0.3)],
		],
		"galeria": [
			["galeria_escuro", p1.call(func(_sala, e) -> bool: return e.passo == SalaGaleria.IDENTIFICAR and e.puxou)],
			["galeria_revela", p1.call(func(_sala, e) -> bool:
				return e.passo == SalaGaleria.REVELANDO and e.arma != SalaGaleria.NENHUMA and e.t > 0.5)],
			["galeria_tiro", p1.call(func(_sala, e) -> bool: return e.passo == SalaGaleria.ATIRAR and e.t > 2.0)],
			["galeria_municao", p1.call(func(_sala, e) -> bool: return e.passo == SalaGaleria.MUNICAO and e.t > 0.4)],
		],
		"canto": [
			["canto_canto", na_sala.call(func(sala) -> bool: return sala.estado == SalaCanto.CANTO and sala.notas_tocadas >= 2)],
			["canto_pergunta", na_sala.call(func(sala) -> bool: return sala.estado == SalaCanto.PERGUNTA and sala.t_estado > 0.9)],
			["canto_revela", na_sala.call(func(sala) -> bool:
				return sala.estado == SalaCanto.REVELA and sala.fonte != SalaCanto.TV and sala.t_estado > 0.5)],
			["canto_repete", na_sala.call(func(sala) -> bool:
				return sala.estado == SalaCanto.REPETE and sala.j[sala.fonte].toques.size() >= 3)],
		],
		"caminhos": [
			["caminhos_treino", p1.call(func(_sala, e) -> bool: return e.estado == SalaCaminhos.TREINO and e.treino == 1 and e.t > 0.9)],
			["caminhos_anda", p1.call(func(_sala, e) -> bool: return e.estado == SalaCaminhos.ANDA and e.rodada >= 1 and e.passos >= 2)],
			["caminhos_tropeco", p1.call(func(_sala, e) -> bool: return e.trop_aberto and e.trop_t > 0.25)],
			["caminhos_revela", p1.call(func(_sala, e) -> bool: return e.estado == SalaCaminhos.REVELA and e.rodada >= 3 and e.t > 0.3)],
		],
		"prova": [
			["prova_partida", na_sala.call(func(sala) -> bool: return sala.etapa == SalaProva.PARTIDA and sala.t_etapa > 24.0)],
			["prova_tiroteio", na_sala.call(func(sala) -> bool:
				return sala.etapa == SalaProva.PARTIDA and sala.t_etapa > 55.0 and sala.tiros.size() >= 3)],
			["prova_luzinhas", na_sala.call(func(sala) -> bool: return sala.etapa == SalaProva.LEDS and sala.t_etapa > 2.4)],
			["prova_cor", na_sala.call(func(sala) -> bool: return sala.etapa == SalaProva.COR and sala.t_etapa > 2.4)],
		],
		"voz": [
			["voz_chamado", na_sala.call(func(sala) -> bool:
				return sala.estado == SalaVoz.CHAMADO and sala.vez >= 0 and sala.j[sala.vez].chama > 0.45)],
			["voz_mudo", na_sala.call(func(sala) -> bool:
				var n := 0
				for l in sala.j:
					if sala.j[l].apertou_mudo:
						n += 1
				return sala.estado == SalaVoz.MUDO and n >= 2)],
			["voz_luz", na_sala.call(func(sala) -> bool: return sala.estado == SalaVoz.LUZ and sala.j[0].fase == SalaVoz.REVELA_LUZ)],
			["voz_antes_do_susto", na_sala.call(func(sala) -> bool:
				return sala.estado == SalaVoz.ESPERA and sala.t_estado > SalaVoz.ESPERA_S - 0.5)],
			["voz_clarao", na_sala.call(func(sala) -> bool: return sala.estado == SalaVoz.SUSTO and sala.t_estado > 0.02)],
			["voz_susto", na_sala.call(func(sala) -> bool: return sala.estado == SalaVoz.SUSTO and sala.t_estado > 0.3)],
		],
	}
	var roteiro_salas: Array = [
		["espera", 10], ["aperta", 0, Forja.CRUZ], ["espera", 40],
		["aperta", 0, Forja.CRUZ], ["aperta", 1, Forja.CRUZ], ["aperta", 2, Forja.CRUZ], ["aperta", 3, Forja.CRUZ], ["espera", 10],
		["aperta", 0, Forja.CRUZ], ["aperta", 1, Forja.CRUZ], ["aperta", 2, Forja.CRUZ], ["aperta", 3, Forja.CRUZ],
		["ate", no_salao],
	]
	var pedidas := OS.get_environment("SALAS")
	var salas: Array = Array(pedidas.split(",")) if pedidas != "" else ["centelha", "viga", "molde"]
	for id in salas:
		roteiro_salas.append_array([["sala", id], ["ate", fase.call("aviso", 1.7)], ["foto", id + "_aviso"]])
		for m in momentos.get(id, []):
			roteiro_salas.append_array([["ate", m[1]], ["foto", m[0]]])
		roteiro_salas.append_array([["ate", fase.call("fim", 1.4)], ["foto", id + "_fim"], ["ate", no_salao]])
	roteiro_salas.append_array([["foto", "salao_depois"]])
	if "prova" in salas:
		# a placa da bigorna: ✕ A Prova, △ a Prova de Fogo
		roteiro_salas.append_array([["posiciona", 0, Vector3(0.0, 0.05, 2.1), PI], ["espera", 40], ["foto", "salao_bigorna"]])
	roteiro_salas.append_array([["fim"]])
	return roteiro_salas


## A partida curta: a bigorna, a escolha (na ordem e sorteada), cada sala um
## pouco jogada pelo robô, o placar depois de cada uma e o pódio no fim.
func _roteiro_da_partida() -> Array:
	var no_salao := func() -> bool:
		return jogo.estado == "salao" and not jogo._trocando
	var jogo_andou := func() -> bool:
		return jogo.sala is SalaJogo and jogo.sala.fase == "jogo" and not jogo.sala.treinando and jogo.sala.t_fase >= 9.0 and not jogo._trocando
	var no_treino := func() -> bool:
		return jogo.sala is SalaJogo and jogo.sala.fase == "jogo" and jogo.sala.t_fase > 0.4
	var no_placar := func() -> bool:
		return jogo.overlay == "placar" and jogo.placar._t > Placar.T_PRONTO + 0.2
	var no_podio := func() -> bool:
		return jogo.estado == "podio" and not jogo._trocando and jogo.placar._t > 2.0
	var r: Array = [
		["espera", 10], ["aperta", 0, Forja.CRUZ], ["espera", 40],
		["aperta", 0, Forja.CRUZ], ["aperta", 1, Forja.CRUZ], ["aperta", 2, Forja.CRUZ], ["aperta", 3, Forja.CRUZ], ["espera", 10],
		["aperta", 0, Forja.CRUZ], ["aperta", 1, Forja.CRUZ], ["aperta", 2, Forja.CRUZ], ["aperta", 3, Forja.CRUZ],
		["ate", no_salao],
		["posiciona", 0, Vector3(0.0, 0.05, 2.1), PI], ["espera", 40], ["foto", "partida_bigorna"],
		["aperta", 0, Forja.QUADRADO], ["espera", 20], ["foto", "partida_escolha"],
		["aperta", 0, Forja.DIREITA], ["espera", 10], ["aperta", 0, Forja.BAIXO], ["espera", 6], ["aperta", 0, Forja.DIREITA], ["espera", 6],
		["aperta", 0, Forja.BAIXO], ["espera", 6], ["aperta", 0, Forja.ESQUERDA], ["espera", 20], ["foto", "partida_escolha_sorteada"],
		["aperta", 0, Forja.DIREITA], ["espera", 6], ["aperta", 0, Forja.CIMA], ["espera", 6], ["aperta", 0, Forja.ESQUERDA], ["espera", 6],
		["aperta", 0, Forja.CIMA], ["espera", 6], ["aperta", 0, Forja.ESQUERDA], ["aperta", 0, Forja.ESQUERDA], ["espera", 10],
		["aperta", 0, Forja.CRUZ],
	]
	for i in 3:
		if i == 0:
			r.append_array([["ate", no_treino], ["foto", "partida_treino"]])
		r.append_array([["ate", jogo_andou]])
		if i == 0:
			r.append_array([["foto", "partida_sala"]])
		r.append_array([["termina"], ["ate", func() -> bool: return jogo.overlay == "placar" and jogo.placar._t > 0.9],
			["foto", "partida_placar_%d_contando" % (i + 1)], ["ate", no_placar], ["foto", "partida_placar_%d" % (i + 1)]])
	r.append_array([["ate", no_podio], ["foto", "partida_podio"], ["fim"]])
	return r


## O trailer de 60 s (scripts/trailer.sh grava com o --write-movie): o título,
## o lobby, as salas com o robô jogando — A Galeria, O Impacto, A Viga, O
## Molde, A Prova —, o pódio e os créditos. Os tempos são em quadros (60 por
## segundo).
func _roteiro_do_trailer() -> Array:
	var r: Array = [
		["espera", 200],
		["aperta", 0, Forja.CRUZ], ["espera", 30],
		["aperta", 0, Forja.CRUZ], ["aperta", 1, Forja.CRUZ], ["aperta", 2, Forja.CRUZ], ["aperta", 3, Forja.CRUZ],
		["espera", 60], ["aperta", 1, Forja.DIREITA], ["aperta", 2, Forja.BAIXO], ["espera", 50],
		["aperta", 0, Forja.CRUZ], ["aperta", 1, Forja.CRUZ], ["aperta", 2, Forja.CRUZ], ["aperta", 3, Forja.CRUZ],
		["espera", 150],
	]
	# cada sala: o aviso com o gesto, e o jogo andando (o robô joga)
	for s in [["galeria", 520], ["impacto", 520], ["viga", 460], ["molde", 400], ["prova", 700]]:
		r.append_array([["sala_cortina", s[0]], ["espera", 110 + int(s[1])]])
	r.append_array([["podio_de_mentira"], ["espera", 300], ["creditos"], ["espera", 200], ["fim"]])
	return r


## O título com os créditos, e as opções pelo lobby (△ de quem não está pronto).
func _roteiro_dos_extras() -> Array:
	return [
		["espera", 70], ["foto", "titulo"],
		["aperta", 0, Forja.TRIANGULO], ["espera", 70], ["foto", "creditos"],
		["aperta", 0, Forja.CIRCULO], ["espera", 20],
		["aperta", 0, Forja.CRUZ], ["espera", 40], ["aperta", 0, Forja.CRUZ], ["aperta", 1, Forja.CRUZ], ["espera", 30],
		["foto", "lobby"],
		["aperta", 1, Forja.TRIANGULO], ["espera", 10], ["aperta", 1, Forja.BAIXO], ["espera", 6],
		["aperta", 1, Forja.ESQUERDA], ["espera", 20], ["foto", "opcoes"], ["fim"],
	]


## A bancada (--experimento=CHAVE): no meio da medida e no fim.
func _roteiro_da_bancada() -> Array:
	var na_bancada := func(cond: Callable) -> Callable:
		return func() -> bool:
			return jogo.sala is SalaBancada and cond.call(jogo.sala)
	return [
		["ate", na_bancada.call(func(b) -> bool: return b.linhas.size() == 0 and b.agora.contains("fale agora"))],
		["espera", 30], ["foto", "bancada_medindo"],
		["ate", na_bancada.call(func(b) -> bool: return b.acabou)], ["foto", "bancada_fim"], ["fim"],
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
			"aviso":
				jogo.hud.mostrar_aviso(p[1])
			"vereditos":
				Forja.veredito(0, "botoes", Forja.PASSOU, Forja.NIVEL_REAGIU, "apertar ✕ ○ □ △", "os quatro chegaram")
				Forja.veredito(1, "vibracao_forte", Forja.FALHOU, Forja.NIVEL_OBEDECEU, "motor esquerdo, às cegas", "a pessoa disse direita duas vezes")
				Forja.veredito(2, "lightbar", Forja.PASSOU, Forja.NIVEL_OBEDECEU, "cor sorteada: verde", "a pessoa disse verde")
			"sala":
				jogo._entrar_na_sala(p[1], false)
			"termina":
				jogo.sala.terminar()
			"sala_cortina":
				jogo._entrar_na_sala(p[1], true)
			"podio_de_mentira":
				# uma noite de três salas, para o pódio do trailer
				var pa := Partida.nova(3, false, 7, jogo.ORDEM_DO_FOGO)
				pa.registrar("galeria", [40, 90, 60, 20], [0, 1, 2, 3])
				pa.registrar("impacto", [70, 80, 30, 50], [0, 1, 2, 3])
				pa.registrar("prova", [30, 100, 90, 10], [0, 1, 2, 3])
				jogo.partida = pa
				jogo._trocar(jogo._ir_para_o_podio)
			"creditos":
				jogo.placar.visible = false
				jogo.estado = "titulo"
				jogo._abrir_overlay("creditos", 0)
			"fim":
				get_tree().quit()
				return
