class_name SalaJogo
extends Sala

var fase := "aviso"
var t_fase := 0.0
var duracao := 90.0
var t_jogo := 0.0
const AVISO_MAX := 8.0
var colocacao: Array = []
var coop := false
var coop_venceu := false
var _celebrou := false
var _robo_confirmou := false
var _fps_min := INF
var _fps_soma := 0.0
var _fps_n := 0
var objetivo := ""
var features: Array = []
var icone := ""
var botoes_pedidos := 0
var prontos := [false, false, false, false]
var acabou := [false, false, false, false]
var jogando := [false, false, false, false]
var pontos := [0, 0, 0, 0]
var acertos := [0, 0, 0, 0]
const APRENDEU := 3
var gesto_do_aviso := ""
var _gesto_aviso_t := [0.0, 0.0, 0.0, 0.0]
var ritmo_nivel := 1.0
var _gesto_aviso_lado := false
var vereditos := {}
var rng := RandomNumberGenerator.new()
var variante := 0
var congelada := false
var _itens := {}
var cega := false
var papel_som := -1
var sfx_no_controle := true
var com_treino := true
var treinando := false
var valendo_t := 0.0
var _treino_ok := [false, false, false, false]
var _treino_acertos := [0, 0, 0, 0]
const TREINO_ACERTOS := 3
const TREINO_MAX := 15.0
var na_prova_de_fogo := ""
var seguir := "Voltar ao salão"
var _teste_dir := [0.0, 0.0, 0.0, 0.0]
var usa_gatilho := false


func entrar(js: Array) -> void:
	rng.seed = int(Forja.semente) * 131 + hash(id)
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = hash("%d:%s" % [int(Forja.semente), id])
	variante = sorteio.randi() % 2
	ritmo_nivel = Forja.ritmo()
	if duracao > 0.0:
		duracao *= ritmo_nivel
	super(js)
	for p in jogadores:
		Forja.med_comecar(p.lugar, botoes_pedidos)
		Forja.med_repouso(p.lugar, true)
		p.controlavel = false
	Itens.novo_minigame()
	for p in jogadores:
		Itens.registrar(p.lugar, "leva")
	if papel_som >= 0:
		Forja.som_preparar(papel_som)
	elif sfx_no_controle and not Forja.som_pronto():
		Forja.som_preparar(Forja.PAPEL_ALTO_FALANTE)


func sair() -> void:
	for p in jogadores:
		Forja.med_parar(p.lugar)
		p.preso = false
		if _itens.has(p.lugar):
			p.visual(p.modelo_i, int(_itens[p.lugar]))
	if papel_som >= 0:
		Forja.som_preparar(Forja.PAPEL_ALTO_FALANTE)
	super()


func errou(l: int) -> bool:
	var p := jogador(l)
	if p == null or treinando or not Itens.absorve_erro(l):
		return false
	Som.tocar("escudo", p.global_position + Vector3(0, 1.2, 0), -4.0)
	Som.no_controle(l, "escudo", 0.8)
	Forja.sentir(l, "golpe")
	if not usa_gatilho:
		Itens.sentir(l)
	Itens.registrar(l, "quebrou")
	return true


func maos_livres(p: ForjaPlayer) -> void:
	if not _itens.has(p.lugar):
		_itens[p.lugar] = p.item_i
	p.visual(p.modelo_i, 0)


func martelo_na_mao(p: ForjaPlayer) -> void:
	maos_livres(p)
	var esqueleto: Skeleton3D = p.modelo.find_child("Skeleton3D", true, false)
	if esqueleto == null:
		return
	var presa := BoneAttachment3D.new()
	presa.bone_name = "arm-right"
	esqueleto.add_child(presa)
	var m := Kit.martelo(presa, 0.5)
	m.position = Vector3(-0.035, -0.12, 0.05)
	m.rotation_degrees = Vector3(0, 0, 14)


var _preenchimento: OmniLight3D = null
var _energia_preenchimento := 0.0


func atmosfera(cor_ar: Color, cor_neon: Color, brasas := false, n := 48, largura := 22.0, fundo := -7.8,
		preenche := 0.35) -> void:
	var caixa := Vector3(largura, 3.5, 9.0)
	if brasas:
		Efeitos.brasas(self, Vector3(0, 0.2, 0), Vector3(largura, 0.2, 9.0), cor_ar, n)
	else:
		Efeitos.poeira(self, Vector3(0, 1.8, 0), caixa, cor_ar, n)
	_preenchimento = OmniLight3D.new()
	_preenchimento.position = Vector3(0, 6.5, 1.0)
	_preenchimento.light_energy = preenche
	_preenchimento.omni_range = 24.0
	add_child(_preenchimento)
	enchimento(_preenchimento)
	_energia_preenchimento = _preenchimento.light_energy
	for lado in [-1.0, 1.0]:
		var neon := MeshInstance3D.new()
		var barra := BoxMesh.new()
		barra.size = Vector3(largura * 0.32, 0.08, 0.08)
		neon.mesh = barra
		var mat := Tema.neon(Tema.VIOLETA, 1.0, "mundo")
		_tubos.append(mat)
		neon.material_override = mat
		neon.position = Vector3(lado * largura * 0.27, 2.3, fundo)
		add_child(neon)
		var brilho := OmniLight3D.new()
		brilho.light_color = Tema.VIOLETA
		brilho.light_energy = 0.8
		brilho.omni_range = 5.0
		brilho.position = neon.position + Vector3(0, -0.3, 0.6)
		add_child(brilho)
	if not Ritmo.compasso.is_connected(_tubos_no_tempo_1):
		Ritmo.compasso.connect(_tubos_no_tempo_1)


var _tubos: Array[ShaderMaterial] = []


func _tubos_no_tempo_1(_n: int) -> void:
	for m in _tubos:
		m.set_shader_parameter("energia", 1.1)
	var colcheia := 30.0 / maxf(1.0, Ritmo.bpm if Ritmo.bpm > 0.0 else 120.0)
	var tw := create_tween()
	tw.tween_interval(colcheia)
	tw.tween_callback(func() -> void:
		for m in _tubos:
			m.set_shader_parameter("energia", 1.0))


func _exit_tree() -> void:
	if Ritmo.compasso.is_connected(_tubos_no_tempo_1):
		Ritmo.compasso.disconnect(_tubos_no_tempo_1)


func pulso_de_luz(cor: Color, forca := 2.2) -> void:
	if _preenchimento == null or not Opcoes.flashes:
		return
	var original := _preenchimento.light_color
	_preenchimento.light_color = cor
	_preenchimento.light_energy = _energia_preenchimento + forca
	var tw := create_tween()
	tw.tween_property(_preenchimento, "light_energy", _energia_preenchimento, 0.9).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void: _preenchimento.light_color = original)


func congelar(sim: bool) -> void:
	if congelada == sim:
		return
	congelada = sim
	if fase == "fim":
		return
	for p in jogadores:
		if sim:
			Forja.med_parar(p.lugar)
		else:
			Forja.med_retomar(p.lugar)


func _process(dt: float) -> void:
	super(dt)
	if congelada:
		return
	if fase == "jogo" and _esperar_o_controle():
		return
	t_fase += dt
	match fase:
		"aviso":
			if Forja.robo:
				_robo_do_aviso()
			_quadro_aviso()
		"jogo":
			if treinando:
				_quadro_treino()
			if valendo_t > 0.0:
				valendo_t -= dt
			if not treinando:
				t_jogo += dt
			_medir_quadros()
			jogar(dt)
			var todos := true
			for p in jogadores:
				if jogando[p.lugar] and not acabou[p.lugar] and Forja.lugar(p.lugar).get("conectado", false):
					todos = false
			if todos or tempo_acabou():
				terminar()
		"fim":
			_quadro_fim()


func _robo_do_aviso() -> void:
	if _robo_confirmou:
		return
	_robo_confirmou = true
	for p in jogadores:
		Forja.robo_confirmar(p.lugar, 1.4 + 0.2 * p.lugar, self)


func _medir_quadros() -> void:
	var fps := float(Engine.get_frames_per_second())
	if fps <= 0.0:
		return
	_fps_min = minf(_fps_min, fps)
	_fps_soma += fps
	_fps_n += 1


func _quadro_aviso() -> void:
	var presentes := 0
	var n_prontos := 0
	for p in jogadores:
		var l: int = p.lugar
		if not Forja.lugar(l).get("conectado", false):
			continue
		presentes += 1
		if papel_som >= 0 and Forja.bancada:
			_afinar_som(l, p)
		if not prontos[l] and t_fase > 0.5:
			if Forja.apertou(l, Forja.CRUZ):
				prontos[l] = true
				Forja.sentir(l, "toque")
				Som.tocar("tique", p.global_position + Vector3(0, 1, 0))
		if prontos[l]:
			n_prontos += 1
		elif gesto_do_aviso != "":
			_mostrar_o_gesto(l, p)
	if presentes > 0 and (n_prontos == presentes or t_fase >= AVISO_MAX) and t_fase > 0.9:
		comecar()


func _mostrar_o_gesto(l: int, p: ForjaPlayer) -> void:
	_gesto_aviso_t[l] -= get_process_delta_time()
	if _gesto_aviso_t[l] > 0.0:
		return
	_gesto_aviso_t[l] = 1.6
	var g := gesto_do_aviso
	if g == "lados":
		g = "interact-left" if _gesto_aviso_lado else "interact-right"
		if l == 0:
			_gesto_aviso_lado = not _gesto_aviso_lado
	p.gesto(g, 0.5)


func _afinar_som(l: int, p: ForjaPlayer) -> void:
	if Forja.apertou(l, Forja.ESQUERDA) or Forja.apertou(l, Forja.DIREITA):
		Forja.som_trocar(l, papel_som, -1 if Forja.apertou(l, Forja.ESQUERDA) else 1)
		Som.tocar("tique", p.global_position + Vector3(0, 1, 0))
	if Forja.apertou(l, Forja.TRIANGULO):
		if papel_som == Forja.PAPEL_ALTO_FALANTE:
			Forja.som_falante(l, "sino", 0.9)
		elif papel_som == Forja.PAPEL_HAPTICA:
			Forja.som_haptica(l, "pulso", "")
			_teste_dir[l] = 0.35
	if _teste_dir[l] > 0.0:
		_teste_dir[l] -= get_process_delta_time()
		if _teste_dir[l] <= 0.0:
			Forja.som_haptica(l, "", "pulso")


func comecar() -> void:
	fase = "jogo"
	t_fase = 0.0
	t_jogo = 0.0
	treinando = com_treino
	_treino_ok = [false, false, false, false]
	_treino_acertos = [0, 0, 0, 0]
	for p in jogadores:
		jogando[p.lugar] = true
		Forja.med_repouso(p.lugar, false)
		if not usa_gatilho:
			Itens.sentir(p.lugar)
	Forja.evento("sala", 0, {"sala": id, "evento": "jogo_comecou"})
	Forja.evento("minigame", 0, {"slot": id, "evento": "comecou"})
	_som_do_comeco()
	iniciar_jogo()


func _som_do_comeco() -> void:
	Som.tocar("confirma")


func iniciar_jogo() -> void:
	pass


func jogar(_dt: float) -> void:
	pass


func dar_vereditos(lugar: int) -> Array:
	var lista: Array = []
	for f in features:
		var v := Forja.med_veredito(lugar, f)
		if not v.is_empty():
			lista.append(v)
	return lista


func terminar() -> void:
	if fase == "fim":
		return
	fase = "fim"
	t_fase = 0.0
	_celebrou = false
	colocacao = vencedor()
	for p in jogadores:
		var l: int = p.lugar
		if jogando[l]:
			vereditos[l] = _pelas_opcoes(l, dar_vereditos(l))
		Forja.med_parar(l)
		Forja.silencio(l)
	Forja.evento("sala", 0, {"sala": id, "evento": "jogo_terminou"})
	Forja.evento("desempenho", 0, {"slot": id, "fps_min": snappedf(_fps_min if _fps_n > 0 else 0.0, 0.1),
		"fps_media": snappedf(_fps_soma / _fps_n if _fps_n > 0 else 0.0, 0.1)})
	Forja.evento("minigame", 0, campos_do_fim())
	Forja.gravar_relatorio()
	Musica.parar_seco()
	Som.jingle("JIN_APITO")
	pulso_de_luz(Tema.TUNGSTENIO, 1.6)
	ao_terminar()


func tempo_jogado() -> float:
	return t_jogo


func tempo_acabou() -> bool:
	return duracao > 0.0 and tempo_jogado() >= duracao


func tempo_que_resta() -> float:
	return maxf(0.0, duracao - tempo_jogado())


func campos_do_fim() -> Dictionary:
	return {"slot": id, "evento": "terminou", "vencedor": int(colocacao[0]) if not colocacao.is_empty() else -1,
		"pontos": pontos, "duracao": snappedf(tempo_jogado(), 0.1)}


func frase_do_resultado() -> String:
	return ""


func quem_comemora() -> Array:
	return [colocacao[0]] if not colocacao.is_empty() else []


func quem_brilha() -> int:
	return int(colocacao[0]) if not colocacao.is_empty() else -1


func vencedor() -> Array:
	var lugares: Array = []
	for l in 4:
		if jogando[l]:
			lugares.append(l)
	lugares.sort_custom(func(a: int, b: int) -> bool:
		return int(pontos[a]) > int(pontos[b]) or (int(pontos[a]) == int(pontos[b]) and a < b))
	return lugares


func _celebrar() -> void:
	for l in quem_comemora():
		var p := jogador(int(l))
		if p != null and is_instance_valid(p):
			p.gesto("emote-yes", 1.4)
	var b := quem_brilha()
	var pb := jogador(b) if b >= 0 else null
	if pb != null and is_instance_valid(pb):
		Efeitos.faiscas(self, pb.global_position + Vector3(0, 2.2, 0), Forja.cor_do_lugar(b), 40, 1.3)
	Som.jingle(Som.jingle_do_resultado(pontos, _presentes_do_fim(), coop, coop_venceu))


func _presentes_do_fim() -> Array:
	var lugares: Array = []
	for l in 4:
		if jogando[l]:
			lugares.append(l)
	return lugares


func _pelas_opcoes(l: int, lista: Array) -> Array:
	for v in lista:
		var f := str(v.get("feature", ""))
		var motivo := Opcoes.por_que_nao_mede(l, f)
		if motivo == "" or int(v.get("resultado", 0)) == Forja.PASSOU:
			continue
		v["resultado"] = Forja.NAO_MEDIDO
		v["rotulo"] = "não medido"
		v["obs"] = motivo
		Forja.veredito(l, f, Forja.NAO_MEDIDO, Forja.NIVEL_MONTOU, "a sala pediu, as opções do lugar desligaram",
			str(v.get("medido", "")), motivo)
	return lista


func ao_terminar() -> void:
	pass


func _quadro_fim() -> void:
	if t_fase >= TelaResultado.APITO_S and not _celebrou:
		_celebrou = true
		_celebrar()
	if t_fase >= TelaResultado.AVANCA_S:
		terminou.emit()
		return
	if t_fase < 0.8:
		return
	for p in jogadores:
		if Forja.apertou(p.lugar, Forja.CRUZ):
			terminou.emit()
			return


func status(lugar: int) -> String:
	if fase == "aviso":
		return "Pronto" if prontos[lugar] else "✕ Quando pronto"
	if fase == "fim":
		return "%d pontos" % pontos[lugar]
	if acabou[lugar]:
		return "Terminou · %d" % pontos[lugar]
	if treinando:
		return "Treino ✓" if _treino_ok[lugar] else "Treino"
	return "%d pontos" % pontos[lugar]


func marcar(lugar: int, n: int) -> void:
	if treinando:
		if n > 0 and not _treino_ok[lugar]:
			_treino_acertos[lugar] += 1
			acertos[lugar] += 1
			Som.tocar("seleciona")
			if _treino_acertos[lugar] >= TREINO_ACERTOS:
				_treino_ok[lugar] = true
		return
	pontos[lugar] += n
	if n > 0:
		acertos[lugar] += 1


func _quadro_treino() -> void:
	var todos := true
	for p in jogadores:
		if jogando[p.lugar] and Forja.lugar(p.lugar).get("conectado", false) and not _treino_ok[p.lugar]:
			todos = false
	if todos or t_fase >= TREINO_MAX * ritmo_nivel:
		treinando = false
		valendo_t = 1.4
		Som.tocar("especial")
		pulso_de_luz(Tema.VIOLETA)
		Forja.evento("sala", 0, {"sala": id, "evento": "valendo", "treino_s": snappedf(t_fase, 0.1)})


func aprendeu(lugar: int) -> bool:
	return acertos[lugar] >= APRENDEU


func diagnostico_livre() -> bool:
	return not (cega and fase == "jogo")


func pergunta(_lugar: int) -> Dictionary:
	return {}


func progresso() -> String:
	return ""


func dica(_lugar: int) -> Dictionary:
	return {}


func com_poucos() -> String:
	return ""


func erros_do_grupo() -> int:
	return 0


var esperando_controle := false
var _tela_reconectar: TelaReconectar = null


func lugares_sem_controle() -> Array:
	var fora: Array = []
	for p in jogadores:
		if jogando[p.lugar] and not acabou[p.lugar]:
			if Forja.lugar(p.lugar).get("conectado", false):
				return []
			fora.append(p.lugar)
	return fora


func _esperar_o_controle() -> bool:
	var fora := lugares_sem_controle()
	esperar_o_controle(not fora.is_empty(), fora)
	return esperando_controle


func esperar_o_controle(sim: bool, lugares: Array) -> void:
	if sim and _tela_reconectar != null:
		_tela_reconectar.lugares = lugares
	if esperando_controle == sim:
		return
	esperando_controle = sim
	for p in jogadores:
		if sim:
			Forja.med_parar(p.lugar)
		else:
			Forja.med_retomar(p.lugar)
	if sim:
		var camada := CanvasLayer.new()
		camada.layer = 11
		_tela_reconectar = TelaReconectar.new()
		_tela_reconectar.lugares = lugares
		_tela_reconectar.sala = self
		camada.add_child(_tela_reconectar)
		add_child(camada)
	elif _tela_reconectar != null:
		_tela_reconectar.visible = false
		_tela_reconectar.get_parent().queue_free()
		_tela_reconectar = null
