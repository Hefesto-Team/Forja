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
				Som.tocar("tique", p.global_position + Vector3(0, 1, 0))
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


## Quem venceu pula de alegria, com faíscas na cor do lugar. Ninguém balança a
## cabeça: o veredito é do Modo bancada, não do boneco.
func _celebrar() -> void:
	if not colocacao.is_empty():
		var l: int = colocacao[0]
		var p := jogador(l)
		if p != null and is_instance_valid(p):
			p.gesto("emote-yes", 1.4)
			Efeitos.faiscas(self, p.global_position + Vector3(0, 2.2, 0), Forja.cor_do_lugar(l), 40, 1.3)
	# o jingle do resultado (H06): vitória, empate ou, no coop, a de todos ou a derrota
	Som.jingle(Som.jingle_do_resultado(pontos, _presentes_do_fim(), coop, coop_venceu))


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


## A linha da HUD de cada lugar: pontos, ou "terminou".
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
