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
	if com_entrada:
		_comecar_a_entrada()


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
		"entrada":
			_quadro_entrada()
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
				Som.ui(l, "ui_confirma")
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
	_emburrou = false
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
	var jingle := Som.jingle_do_resultado(pontos, _presentes_do_fim(), coop, coop_venceu)
	var w := vencedor_do_fim()
	var espera := 0.0
	if w >= 0:
		var p := jogador(w)
		if p != null and is_instance_valid(p):
			p.gesto("emote-yes", 1.4)
			Efeitos.faiscas(self, p.global_position + Vector3(0, 2.2, 0), Forja.cor_do_lugar(w), 40, 1.3)
		Som.tocar(["fx_vitoria_p1", "fx_vitoria_p2", "fx_vitoria_p3", "fx_vitoria_p4"][w], p.global_position if p != null and is_instance_valid(p) else null, -9.0)
		Som.no_controle(w, ["fx_vitoria_p1", "fx_vitoria_p2", "fx_vitoria_p3", "fx_vitoria_p4"][w], 0.85)
		Forja.batimento_duplo(w)
		if por_um_fio():
			carimbou.emit(w, "car_por_um_fio")
		else:
			falar(w, "vencedor")
		espera = FX_VITORIA_S
	elif coop and coop_venceu:
		for l in _presentes_do_fim():
			Forja.batimento_duplo(l)
	elif coop:
		Som.tocar("fx_derrota", null, -6.0)
		for l in _presentes_do_fim():
			Forja.desmaio(l)
		espera = FX_DERROTA_S
	if espera > 0.0:
		get_tree().create_timer(espera).timeout.connect(Som.jingle.bind(jingle))
	else:
		Som.jingle(jingle)


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
	if t_fase >= batida_do_fim() and not _celebrou:
		_celebrou = true
		_celebrar()
	if t_fase >= BATIDAS_DO_RESULTADO * batida_do_fim() and not _emburrou and ultimo_do_inserto() >= 0:
		_emburrou = true
		_no_inserto()
	if t_fase >= fim_da_cena() + TelaResultado.AVANCA_S:
		terminou.emit()
		return
	if t_fase < fim_da_cena() + 0.8:
		return
	for p in jogadores:
		if Forja.apertou(p.lugar, Forja.CRUZ):
			terminou.emit()
			return


func status(lugar: int) -> String:
	if fase in ["entrada", "aviso"]:
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


const PALAVRA := ["", "Quase", "Afinado", "Ressonância!"]
const JUL := ["erro", "quase", "afinado", "ressonancia"]
const SENSACAO_DO_JULGAMENTO := ["erro", "acerto", "acerto", "perfeito"]
var _ressonancias := [0, 0, 0, 0]
var _acorde := [-1, -1, -1, -1]


func julgar(l: int, j: int, palavra := "", no_tempo_1 := false, desvio_s := 0.0) -> void:
	if l < 0 or l > 3 or j < 0 or j > 3:
		return
	if palavra == "" and treinando:
		palavra = Falas.do_julgamento(j, true, desvio_s)
	var id := "jul_%s_p%d" % [JUL[j], l + 1]
	var p := jogador(l)
	Som.tocar(id, p.global_position + Vector3(0, 1.2, 0) if p else null, -12.0)
	Som.no_controle(l, id, 0.85)
	Forja.sentir(l, SENSACAO_DO_JULGAMENTO[j])
	julgou.emit(l, j, palavra if palavra != "" or j == 0 else PALAVRA[j])
	if treinando:
		return
	_falas_do_julgamento(l, j, desvio_s)
	_ressonancias[l] = _ressonancias[l] + 1 if j == 3 else 0
	if _ressonancias[l] >= 5:
		_ressonancias[l] = 0
		carimbou.emit(l, "car_em_chamas")
	if j != 3:
		_acorde[l] = -1
		return
	if not no_tempo_1:
		return
	_acorde[l] = roundi(Ritmo.batida() / 4.0)
	var quem: Array = []
	for k in 4:
		if jogando[k]:
			quem.append(k)
	if quem.size() >= 3 and quem.all(func(k): return _acorde[k] == _acorde[l]):
		_acorde = [-1, -1, -1, -1]
		carimbou.emit(-1, "car_acorde")


func combo(_l: int) -> int:
	return 0


var com_entrada := false
const ENTRADA_ESPERA := 1.6
const ENTRADA_ANTES := 0.6
const ENTRADA_SEGURA := 0.3
var _t_impacto := 0.0
var _n_impacto := 0
var _t_saida := 0.0
var _entrada_feito := {}


func _comecar_a_entrada() -> void:
	fase = "entrada"
	t_fase = 0.0
	_entrada_feito = {}
	var n := ceilf(Ritmo.batida() + ENTRADA_ESPERA * Ritmo.bpm / 60.0)
	_n_impacto = int(ceilf(n / 4.0) * 4.0)
	_t_impacto = Ritmo.t_da_batida(_n_impacto)
	var depois := ceilf((_n_impacto + ENTRADA_SEGURA * Ritmo.bpm / 60.0) / 4.0) * 4.0
	_t_saida = Ritmo.t_da_batida(depois)


func ms_da_entrada() -> float:
	return (Ritmo.t_musica() - (_t_impacto - ENTRADA_ANTES)) * 1000.0


func ms_da_saida() -> float:
	return (Ritmo.t_musica() - _t_saida) * 1000.0


func ms_da_batida() -> float:
	return 60000.0 / maxf(Ritmo.bpm, 1.0)


func _uma_vez(nome: String) -> bool:
	if _entrada_feito.has(nome):
		return false
	_entrada_feito[nome] = true
	return true


func _quadro_entrada() -> void:
	var b := Ritmo.batida()
	for k in 3:
		if b >= _n_impacto - 3 + k and _uma_vez("tique%d" % k):
			Som.tocar("jin_entrada_tique", null, -9.0)
			for p in jogadores:
				if k == 0:
					Forja.gatilhos_off(p.lugar)
				Forja.sentir(p.lugar, "toque")
	var ms := ms_da_entrada()
	if ms >= 0.0 and _uma_vez("cortina"):
		Som.tocar("fx_entrada", null, -6.0)
		PosFita.ajustar("rasgo", 0.35, int(ENTRADA_ANTES * 1000.0))
	if ms >= ENTRADA_ANTES * 1000.0 and _uma_vez("impacto"):
		_impacto()
	elif _entrada_feito.has("impacto") and not _entrada_feito.has("luz") and ms >= ENTRADA_ANTES * 1000.0 + 33.0:
		_entrada_feito["luz"] = true
		for p in jogadores:
			Forja.luz_do_lugar(p.lugar)
	if ms_da_saida() >= ms_da_batida():
		fase = "aviso"
		t_fase = 0.0


func _impacto() -> void:
	Som.tocar("jin_entrada_vai", null, -6.0)
	for p in jogadores:
		Som.no_controle(p.lugar, "jin_entrada_vai")
		Forja.sentir(p.lugar, "golpe")
		if Opcoes.flashes:
			Forja.luz(p.lugar, Tema.ETIQUETA)
	PosFita.rasgo_curto()
	Forja.evento("momento", 0, {"slot": id, "nome": "verbo_carimbado", "lugar": -1,
		"t_musica": snappedf(Ritmo.t_musica(), 0.001), "t_alvo": snappedf(_t_impacto, 0.001)})


var _t_da_ultima_fala := [-INF, -INF, -INF, -INF]
var _fala_ate := -INF
var _acertos_da_equipe := 0
var _erros_seguidos := [0, 0, 0, 0]
var _ultimo_erro := [-INF, -INF, -INF, -INF]
var _lado_seguido := [0, 0, 0, 0]


func falar(l: int, evento: String) -> bool:
	if l < 0 or l > 3 or not Falas.DO_EVENTO.has(evento):
		return false
	if t < _fala_ate or t - float(_t_da_ultima_fala[l]) < Falas.INTERVALO_S:
		return false
	var frases: Array = Falas.DO_EVENTO[evento]
	var texto: String = frases[rng.randi() % frases.size()]
	_t_da_ultima_fala[l] = t
	_fala_ate = t + Falas.DURACAO_S
	falou.emit(l, texto, Falas.DURACAO_S)
	Forja.evento("fala", l + 1, {"evento": evento})
	return true


func _falas_do_julgamento(l: int, j: int, desvio_s: float) -> void:
	if j > Falas.ERRO:
		_acertos_da_equipe += 1
		if _acertos_da_equipe >= Falas.COMBO_DA_EQUIPE:
			_acertos_da_equipe = 0
			falar(l, "combo_equipe")
		if int(_erros_seguidos[l]) >= Falas.VOLTOU:
			falar(l, "voltou")
		_erros_seguidos[l] = 0
	else:
		_ultimo_erro[l] = t
		_erros_seguidos[l] = int(_erros_seguidos[l]) + 1
		_acertos_da_equipe = 0
		var todos := true
		for k in 4:
			if jogando[k] and Forja.ocupado(k) and t - float(_ultimo_erro[k]) > Falas.TODOS_S:
				todos = false
		if todos:
			falar(l, "todos_erraram")
	if desvio_s > Falas.ARRASTA_S:
		_lado_seguido[l] = maxi(int(_lado_seguido[l]), 0) + 1
	elif desvio_s < Falas.CORRE_S:
		_lado_seguido[l] = mini(int(_lado_seguido[l]), 0) - 1
	else:
		_lado_seguido[l] = 0
	if int(_lado_seguido[l]) >= Falas.SEGUIDOS:
		_lado_seguido[l] = 0
		falar(l, "arrastando")
	elif int(_lado_seguido[l]) <= -Falas.SEGUIDOS:
		_lado_seguido[l] = 0
		falar(l, "correndo")


const BATIDAS_DO_RESULTADO := 4
const BATIDAS_DO_INSERTO := 1
const POR_UM_FIO := 0.02
const FX_VITORIA_S := 1.0
const FX_DERROTA_S := 1.4
var _emburrou := false


func batida_do_fim() -> float:
	return 60.0 / (Ritmo.bpm if Ritmo.bpm > 0.0 else 120.0)


func vencedor_do_fim() -> int:
	if coop:
		return -1
	var ordem := vencedor()
	if ordem.is_empty() or int(pontos[ordem[0]]) <= 0:
		return -1
	if ordem.size() >= 2 and int(pontos[ordem[1]]) >= int(pontos[ordem[0]]):
		return -1
	return int(ordem[0])


func ultimo_do_inserto() -> int:
	if coop:
		return -1
	var ordem := vencedor()
	if ordem.size() < 2:
		return -1
	var u := int(ordem[ordem.size() - 1])
	if int(pontos[u]) >= int(pontos[ordem[ordem.size() - 2]]) or u == vencedor_do_fim():
		return -1
	return u


func por_um_fio() -> bool:
	var w := vencedor_do_fim()
	var ordem := vencedor()
	if w < 0 or ordem.size() < 2 or int(pontos[ordem[1]]) <= 0:
		return false
	return int(pontos[w]) - int(pontos[ordem[1]]) <= POR_UM_FIO * int(pontos[w])


func fim_da_cena() -> float:
	var n := BATIDAS_DO_RESULTADO + (BATIDAS_DO_INSERTO if ultimo_do_inserto() >= 0 else 0)
	return n * batida_do_fim()


func plano_do_fim() -> String:
	if fase != "fim":
		return ""
	if t_fase < BATIDAS_DO_RESULTADO * batida_do_fim():
		return "resultado"
	if t_fase < fim_da_cena() and ultimo_do_inserto() >= 0:
		return "inserto"
	return ""


func _no_inserto() -> void:
	var u := ultimo_do_inserto()
	if u < 0:
		return
	carimbou.emit(u, "car_emburrado")
	var p := jogador(u)
	if p != null and is_instance_valid(p):
		p.gesto("sit", batida_do_fim() + 0.7)
	Som.tocar("fx_derrota", null, -6.0)
	Som.no_controle(u, "fx_derrota", 0.85)
	Forja.desmaio(u)
