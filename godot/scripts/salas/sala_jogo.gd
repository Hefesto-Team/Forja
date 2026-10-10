class_name SalaJogo
extends Sala
## Uma sala que mede, em três fases (o desenho das salas de docs/SALAS.md):
##
##   aviso  o objetivo numa frase e as features que a sala prova; cada um
##          aperta ✕ quando pronto (sem relógio). Enquanto isso, os analógicos
##          soltos medem a deriva;
##   jogo   a sala pede (a runa, o círculo, a mira...), o módulo mede a cada
##          quadro; acaba quando todos terminam ou o tempo da sala passa;
##   fim    o veredito de cada um, por feature, com o que foi medido. ✕ volta
##          ao salão.
##
## Com --robo, o robô aperta ✕ no aviso e joga nos controles simulados.

var fase := "aviso"
var t_fase := 0.0
## O tempo da sala, em segundos (0: sem limite).
var duracao := 90.0
## O tempo que vale, em segundos: só corre fora do treino, e é o que o relógio
## do painel e o fim por tempo leem. O `duracao` nunca muda depois de `entrar`.
var t_jogo := 0.0
## Quanto o aviso espera: sem ✕ de todos, a sala começa sozinha.
const AVISO_MAX := 8.0
## Os lugares que jogaram, do primeiro ao último (a `vencedor()` do fim).
var colocacao: Array = []
## Sala cooperativa: o resultado diz "venceram" ou não (a Prova e as salas
## futuras ligam).
var coop := false
var coop_venceu := false
var _celebrou := false
var _robo_confirmou := false
var _fps_min := INF
var _fps_soma := 0.0
var _fps_n := 0
## As regras por extenso, para quem desenha a sala (o docs/SALAS.md). A tela
## não as mostra: o aviso diz o verbo (`acao`) e a sala ensina jogando.
var objetivo := ""
## As features que a sala mede (chaves do catálogo), na ordem do veredito.
var features: Array = []
## O glifo da parte do controle que a sala usa (assets/glifos/): o único ícone do
## aviso. A `FICHA.icone` do kit, na H04.
var icone := ""
## A máscara dos botões que a sala vai pedir (Forja.mascara).
var botoes_pedidos := 0
var prontos := [false, false, false, false]
var acabou := [false, false, false, false]
var jogando := [false, false, false, false]
var pontos := [0, 0, 0, 0]
## Quantas vezes cada um já pontuou na sala: depois de APRENDEU acertos, a dica
## da raia perde as palavras e fica só o glifo (mostrar, não contar).
var acertos := [0, 0, 0, 0]
const APRENDEU := 3
## O gesto que o boneco repete no aviso, para mostrar o que a sala pede (o
## Astro faz assim); vazio: o boneco só espera. "lados" alterna esquerda e direita.
var gesto_do_aviso := ""
var _gesto_aviso_t := [0.0, 0.0, 0.0, 0.0]
## O ritmo do nível (Forja.ritmo): as salas multiplicam as janelas de tempo.
var ritmo_nivel := 1.0
var _gesto_aviso_lado := false
## lugar -> Array de vereditos ({feature, nome, resultado, rotulo, medido, obs})
var vereditos := {}
var rng := RandomNumberGenerator.new()
## A variação de conteúdo da noite (0 ou 1), pela semente e fora do sorteio do
## jogo: quantos alvos, quantos sinos, onde ficam os pilares. O que a sala
## mede não muda.
var variante := 0
## true enquanto a pausa ou o diagnóstico estão por cima: o jogo e a medida
## param (o ✕ do menu não é o ✕ da runa)
var congelada := false
var _itens := {}  ## lugar -> o que o boneco levava antes da sala
## true numa prova às cegas (as salas de saída): enquanto se joga, o
## diagnóstico fica fechado — ele mostraria a luz e o motor do controle
var cega := false
## Nas salas de som, o papel que o aviso deixa conferir, trocar (◀ ▶) e testar
## (△): Forja.PAPEL_ALTO_FALANTE, _HAPTICA ou _MICROFONE; -1 nas outras.
var papel_som := -1
## false: a sala não toca efeitos no alto-falante do controle (a bancada)
var sfx_no_controle := true
## A rodada de treino: o jogo começa valendo nada. Os acertos ensinam (a dica
## segue cheia) e não somam, o erro não tira; acaba quando cada um acertou
## TREINO_ACERTOS vezes, ou em TREINO_MAX s — e aí "Valendo!". O relógio da
## sala (`t_jogo`) não conta o tempo do treino. As medidas seguem contando: uma
## tentativa de treino também é uma tentativa honesta do controle. false: a sala
## tem o treino dela.
var com_treino := true
var treinando := false
var valendo_t := 0.0  ## o "Valendo!" na tela (s que faltam)
var _treino_ok := [false, false, false, false]
var _treino_acertos := [0, 0, 0, 0]
const TREINO_ACERTOS := 3  ## quantos acertos cada um faz no treino
const TREINO_MAX := 15.0
## Na Prova de Fogo: "Prova de Fogo · sala 3 de 9" (vazio fora dela), e o que
## o ✕ do veredito faz.
var na_prova_de_fogo := ""
var seguir := "Voltar ao salão"
var _teste_dir := [0.0, 0.0, 0.0, 0.0]  ## o segundo pulso do teste da háptica
## true: a sala usa o L2 (a Galeria, A Prova, a Bancada); o item não mexe nele (G03)
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
		# o som de cada um, achado como um jogo acha; o aviso mostra e deixa trocar
		Forja.som_preparar(papel_som)
	elif sfx_no_controle and not Forja.som_pronto():
		# a placa abre na entrada do lugar (main.gd); aqui só se ainda não abriu
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
		# a placa fica aberta: volta ao papel de sempre (o alto-falante)
		Forja.som_preparar(Forja.PAPEL_ALTO_FALANTE)
	super()


## Um erro do lugar. Devolve true se o item absorveu (o Escudo): a sala não
## quebra o combo nem pune; o escudo quebra, o L2 afrouxa e o som diz (G03).
## No treino o Escudo não se gasta.
func errou(l: int) -> bool:
	var p := jogador(l)
	if p == null or treinando or not Itens.absorve_erro(l):
		return false
	Som.tocar("escudo", p.global_position + Vector3(0, 1.2, 0), -4.0)
	Som.no_controle(l, "escudo", 0.8)
	Forja.sentir(l, "golpe")   # 1,0 / 0,6 / 250 ms
	if not usa_gatilho:
		Itens.sentir(l)   # o escudo quebrado solta o L2
	Itens.registrar(l, "quebrou")
	return true


## As mãos livres para a sala; o que o boneco levava volta na saída.
func maos_livres(p: ForjaPlayer) -> void:
	if not _itens.has(p.lugar):
		_itens[p.lugar] = p.item_i
	p.visual(p.modelo_i, 0)


## O martelo do Hefesto na mão direita do boneco (as salas da forja).
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


# ------------------------------------------------------------------ o clima --

var _preenchimento: OmniLight3D = null
var _energia_preenchimento := 0.0


## O clima da sala: as partículas do ar (brasas que sobem ou poeira que
## flutua), um preenchimento de cor por cima e dois neons na parede do fundo
## (o synthwave da trilha). O ambiente é constante: numa prova às cegas, a luz
## da sala não diz nada que a mão tenha de descobrir.
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


var _tubos: Array[ShaderMaterial] = []  ## os dois tubos de néon do fundo (o mundo, VIOLETA)


## Os tubos do fundo sobem a 1,1 no tempo 1 de cada compasso e voltam a 1,0 em uma colcheia (arte/07).
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


## Um pulso no preenchimento (o "Valendo!", o fim da sala), na cor pedida.
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
			if todos or (duracao > 0.0 and t_jogo >= duracao):
				terminar()
		"fim":
			_quadro_fim()


## O robô do aviso: aperta ✕ no controle simulado de cada lugar, uma vez, depois
## de ler (a F08: nenhum atalho, o ✕ chega pelo mesmo caminho do dedo).
func _robo_do_aviso() -> void:
	if _robo_confirmou:
		return
	_robo_confirmou = true
	for p in jogadores:
		Forja.robo_confirmar(p.lugar, 1.4 + 0.2 * p.lugar, self)


## Os quadros por segundo da fase `jogo`, para o evento `desempenho` do fim (F09).
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


## O boneco de quem ainda não está pronto repete o gesto da sala.
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


## No aviso de uma sala de som: ◀ ▶ aponta outro dispositivo para o papel, △
## toca o teste nele (o sino no alto-falante; um pulso na esquerda e depois na
## direita, na háptica). No microfone, a barra do aviso sobe com a voz.
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


## O som do começo do jogo (o Minigame troca pela contagem de entrada, H06).
func _som_do_comeco() -> void:
	Som.tocar("confirma")


## A sala monta o que precisa quando o jogo começa.
func iniciar_jogo() -> void:
	pass


## Um quadro de jogo (as salas escrevem).
func jogar(_dt: float) -> void:
	pass


## O veredito de cada feature do lugar, pela régua do núcleo. As salas podem
## trocar (uma feature que não se mede pelo módulo, por exemplo).
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
	Forja.evento("minigame", 0, {"slot": id, "evento": "terminou",
		"vencedor": colocacao[0] if not colocacao.is_empty() else -1,
		"pontos": pontos, "duracao": snappedf(t_jogo, 0.1)})
	Forja.gravar_relatorio()
	# o apito fecha a sala: a música para em seco e o jingle do resultado vem
	# em seguida (no _celebrar, aos APITO_S da tela de resultado)
	Musica.parar_seco()
	Som.jingle("JIN_APITO")
	pulso_de_luz(Tema.TUNGSTENIO, 1.6)
	ao_terminar()


## Os lugares que jogaram, do maior ponto ao menor; no empate, o lugar menor
## primeiro. A Prova e as salas futuras podem trocar a regra.
func vencedor() -> Array:
	var lugares: Array = []
	for l in 4:
		if jogando[l]:
			lugares.append(l)
	lugares.sort_custom(func(a: int, b: int) -> bool:
		return int(pontos[a]) > int(pontos[b]) or (int(pontos[a]) == int(pontos[b]) and a < b))
	return lugares


## 1 batida depois do apito (G07): quem venceu pula de alegria, com faíscas na cor do lugar, o arpejo dele na TV e
## na mão, o batimento duplo e «POR UM FIO» ou a fala do vencedor. Ninguém balança a cabeça: o veredito é do Modo
## bancada, não do boneco. O jingle do resultado (H06) vem depois do som da vitória ou da derrota (o mapa do áudio).
func _celebrar() -> void:
	var jingle := Som.jingle_do_resultado(pontos, _presentes_do_fim(), coop, coop_venceu)
	var w := vencedor_do_fim()
	var espera := 0.0
	if w >= 0:
		var p := jogador(w)
		if p != null and is_instance_valid(p):
			p.gesto("emote-yes", 1.4)
			Efeitos.faiscas(self, p.global_position + Vector3(0, 2.2, 0), Forja.cor_do_lugar(w), 40, 1.3)
		Som.tocar(FX_VITORIA[w], p.global_position if p != null and is_instance_valid(p) else null, -9.0)
		Som.no_controle(w, FX_VITORIA[w], 0.85)
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


## Os lugares que jogaram (os que o resultado conta).
func _presentes_do_fim() -> Array:
	var lugares: Array = []
	for l in 4:
		if jogando[l]:
			lugares.append(l)
	return lugares


## O recurso desligado nas opções do lugar (a vibração em 0%, o gatilho
## desligado) não é defeito: o veredito da feature que ele carrega vira "não
## medido", com o porquê, na tela e no relatório.
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


## O fim filmado (G07): o vencedor em 1 batida, o inserto do último em 4, a tabela depois da cena. O ✕ só vale
## 0,8 s depois da cena; sem ele, a sala avança sozinha em AVANCA_S depois da cena.
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


## A linha da HUD de cada lugar: pontos, ou "terminou".
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
		# no treino, nada soma nem tira: o acerto só ensina
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


## O treino acaba quando cada um acertou TREINO_ACERTOS vezes (ou no tempo máximo).
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


## A dica já foi aprendida: fica só o glifo.
func aprendeu(lugar: int) -> bool:
	return acertos[lugar] >= APRENDEU


## O diagnóstico pode abrir agora? Numa prova às cegas em jogo, não.
func diagnostico_livre() -> bool:
	return not (cega and fase == "jogo")


## Uma pergunta às cegas para o lugar, embaixo da raia dele (no lugar da dica):
## {titulo, opcoes: [[glifo, cor ou null, texto]...], escolhida, certa,
## rodape, pos}. `certa` fica -1 até a resposta ser revelada. Vazio: nada.
func pergunta(_lugar: int) -> Dictionary:
	return {}


## Uma linha de progresso da sala, no lugar do tempo quando ela não tem
## relógio ("onda 1 de 3 · golpe 4 de 30"). Vazio: nada.
func progresso() -> String:
	return ""


## A dica de cada lugar durante o jogo, embaixo da raia dele: {partes, pos}.
## `partes` é a frase em pedaços ("@r1" é o glifo do R1); `pos` é o ponto do
## mundo onde ela fica (o painel projeta na tela). Vazio: sem dica.
func dica(_lugar: int) -> Dictionary:
	return {}


## Com menos de quatro, o que muda na sala, em poucas palavras para o selo do
## aviso (vazio quando nada muda). Só as salas que mudam dizem o delas.
func com_poucos() -> String:
	return ""


## Os erros do grupo numa sala cooperativa (a coleção só dá os quatro cubos a um coop sem erro).
## O padrão é 0; o kit de minigames (H04) soma os `julgar` e a sala que erra sobrescreve.
func erros_do_grupo() -> int:
	return 0


# ---------------------------------------------------------------- o julgamento (G04) --

## A numeração do Ritmo (13): ERRO 0, BOM 1, OTIMO 2, PERFEITO 3.
const PALAVRA := ["", "Quase", "Afinado", "Ressonância!"]
const JUL := ["erro", "quase", "afinado", "ressonancia"]
## A vibração de cada nota pela tabela de sensações: erro 0,7/0,3/160, acerto 0,3/0,6/80, perfeito 0,5/0,8/100.
const SENSACAO_DO_JULGAMENTO := ["erro", "acerto", "acerto", "perfeito"]
var _ressonancias := [0, 0, 0, 0]  ## «Ressonância!» seguidas, por lugar
var _acorde := [-1, -1, -1, -1]  ## o compasso da última «Ressonância!» no tempo 1


## O julgamento de um toque: o som do lugar na TV e na mão, a vibração e o carimbo.
## `palavra` vazia usa PALAVRA[j] (a G07 passa «Cedo»/«Tarde» no treino).
## O kit (H04) chama; o erro chega aqui só se `errou(l)` (G03) devolveu false. `desvio_s`: o desvio do toque em
## segundos (negativo: cedo; G07); quem não mede passa 0 e nunca ouve «Cedo», «Tarde» nem a fala do lado.
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


## O combo do lugar, para o cartão. As salas com combo devolvem o delas.
func combo(_l: int) -> int:
	return 0


# ---------------------------------------------------------------- a entrada (G12) --
## A cortina da fita antes do aviso (arte/06, a cortina diagonal): só nos minigames do kit (o `Minigame` liga).
## Nenhum botão pula. O impacto (o verbo carimbado) cai no tempo 1 `_t_impacto` do relógio da música, o primeiro
## a pelo menos ENTRADA_ESPERA s do `entrar()`; a contagem soa nos três tempos antes. Depois de 900 ms, no tempo 1
## seguinte, a cortina sai e o J-card entra em 1 batida; com ele parado, o aviso começa (`t_fase` do zero).
var com_entrada := false
const ENTRADA_ESPERA := 1.6  ## s do `entrar()` ao impacto, no mínimo
const ENTRADA_ANTES := 0.6  ## a cortina começa 600 ms antes do impacto (o `fx_entrada` tem o impacto em 600 ms)
const ENTRADA_SEGURA := 0.3  ## o verbo segura 300 ms depois do impacto (os 900 ms fixos)
var _t_impacto := 0.0  ## o t_musica do impacto
var _n_impacto := 0  ## a batida do impacto (múltiplo de 4)
var _t_saida := 0.0  ## o t_musica em que a cortina começa a sair (o tempo 1 depois dos 900 ms)
var _entrada_feito := {}  ## o que da entrada já aconteceu ("tique0", "cortina", "impacto", "luz"...)


## O tempo 1 do impacto e o da saída, pelo relógio da música (que sempre anda: a faixa, ou o sistema no mesmo bpm).
func _comecar_a_entrada() -> void:
	fase = "entrada"
	t_fase = 0.0
	_entrada_feito = {}
	var n := ceilf(Ritmo.batida() + ENTRADA_ESPERA * Ritmo.bpm / 60.0)
	_n_impacto = int(ceilf(n / 4.0) * 4.0)
	_t_impacto = Ritmo.t_da_batida(_n_impacto)
	var depois := ceilf((_n_impacto + ENTRADA_SEGURA * Ritmo.bpm / 60.0) / 4.0) * 4.0
	_t_saida = Ritmo.t_da_batida(depois)


## Os ms desde o começo da cortina (negativos antes dela), pelo relógio da música: o painel desenha por eles.
func ms_da_entrada() -> float:
	return (Ritmo.t_musica() - (_t_impacto - ENTRADA_ANTES)) * 1000.0


## Os ms desde que a cortina começou a sair (negativos antes).
func ms_da_saida() -> float:
	return (Ritmo.t_musica() - _t_saida) * 1000.0


## Uma batida, em ms, no relógio de agora.
func ms_da_batida() -> float:
	return 60000.0 / maxf(Ritmo.bpm, 1.0)


func _uma_vez(nome: String) -> bool:
	if _entrada_feito.has(nome):
		return false
	_entrada_feito[nome] = true
	return true


func _quadro_entrada() -> void:
	var b := Ritmo.batida()
	# a contagem: os tempos 2, 3 e 4 do compasso antes do impacto; no primeiro, os gatilhos soltam
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
	# a cortina sai e o J-card entra juntos, em 1 batida; com o J-card parado, o aviso
	if ms_da_saida() >= ms_da_batida():
		fase = "aviso"
		t_fase = 0.0


## O impacto, no tempo 1: o vai na TV e em cada controle, o golpe em todos, a luz que pisca, o rasgo e o momento.
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


# ---------------------------------------------------------------- as falas e o fim filmado (G07) --
## As falas (07): uma por lugar a cada Falas.INTERVALO_S, uma só na tela, sorteada pela semente da sala (`rng`).
var _t_da_ultima_fala := [-INF, -INF, -INF, -INF]  ## o `t` da última fala de cada lugar
var _fala_ate := -INF  ## até quando há uma fala na tela
var _acertos_da_equipe := 0  ## acertos seguidos da equipe (fora do treino)
var _erros_seguidos := [0, 0, 0, 0]
var _ultimo_erro := [-INF, -INF, -INF, -INF]
var _lado_seguido := [0, 0, 0, 0]  ## +n: n toques tarde seguidos; −n: n cedo


## Uma fala do cavaleiro do lugar por um evento do 07. Devolve false (e não fala) se o lugar falou há menos de 20 s,
## se outra fala está na tela ou se o evento não tem frase.
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


## As falas que o julgamento puxa (fora do treino): o combo da equipe, a volta depois dos erros, todos errando
## juntos e o lado (arrastando, correndo).
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


## O fim filmado (01: o resultado e o inserto): o vencedor de baixo por 4 batidas, o rosto do último por 1, e então
## a câmera da sala com a tabela. O main lê `plano_do_fim()` para a pose e a lente.
const BATIDAS_DO_RESULTADO := 4
const BATIDAS_DO_INSERTO := 1
const POR_UM_FIO := 0.02  ## venceu por 2 % ou menos
const FX_VITORIA := ["fx_vitoria_p1", "fx_vitoria_p2", "fx_vitoria_p3", "fx_vitoria_p4"]
const FX_VITORIA_S := 1.0  ## o arpejo do vencedor (o mapa: 1000 ms)
const FX_DERROTA_S := 1.4  ## a fita que desacelera (o mapa: 1400 ms)
var _emburrou := false


## Uma batida do fim, em s (sem música, a 120).
func batida_do_fim() -> float:
	return 60.0 / (Ritmo.bpm if Ritmo.bpm > 0.0 else 120.0)


## Quem venceu a faixa: fora do coop, o primeiro de `vencedor()` com pontos e à frente do segundo (sozinho, basta
## pontuar); -1 no empate em cima, sem pontos ou no coop.
func vencedor_do_fim() -> int:
	if coop:
		return -1
	var ordem := vencedor()
	if ordem.is_empty() or int(pontos[ordem[0]]) <= 0:
		return -1
	if ordem.size() >= 2 and int(pontos[ordem[1]]) >= int(pontos[ordem[0]]):
		return -1
	return int(ordem[0])


## O último do inserto: fora do coop, com 2 ou mais jogando, o último de `vencedor()` se fez menos que o penúltimo e
## não é o vencedor; senão -1 (sem inserto).
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


## Por um fio: há vencedor, o segundo pontuou e a diferença é de 2 % do vencedor ou menos.
func por_um_fio() -> bool:
	var w := vencedor_do_fim()
	var ordem := vencedor()
	if w < 0 or ordem.size() < 2 or int(pontos[ordem[1]]) <= 0:
		return false
	return int(pontos[w]) - int(pontos[ordem[1]]) <= POR_UM_FIO * int(pontos[w])


## Quando a câmera volta à sala e a tabela abre: 5 batidas com inserto, 4 sem.
func fim_da_cena() -> float:
	var n := BATIDAS_DO_RESULTADO + (BATIDAS_DO_INSERTO if ultimo_do_inserto() >= 0 else 0)
	return n * batida_do_fim()


## "resultado", "inserto" ou "" (a câmera da sala, a tabela). Fora do fim, "".
func plano_do_fim() -> String:
	if fase != "fim":
		return ""
	if t_fase < BATIDAS_DO_RESULTADO * batida_do_fim():
		return "resultado"
	if t_fase < fim_da_cena() and ultimo_do_inserto() >= 0:
		return "inserto"
	return ""


## O começo do inserto: a cara emburrada acima do último, ele senta, a fita desacelera na TV e na mão dele, e o
## controle dele desmaia.
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
