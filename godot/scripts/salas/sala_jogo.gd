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
## Com --robo, o robô fica pronto sozinho e joga nos controles simulados.

var fase := "aviso"
var t_fase := 0.0
## O tempo da sala, em segundos (0: sem limite).
var duracao := 90.0
## A frase do aviso: o que fazer, com um verbo.
var objetivo := ""
## As features que a sala mede (chaves do catálogo), na ordem do veredito.
var features: Array = []
## A máscara dos botões que a sala vai pedir (Forja.mascara).
var botoes_pedidos := 0
var prontos := [false, false, false, false]
var acabou := [false, false, false, false]
var jogando := [false, false, false, false]
var pontos := [0, 0, 0, 0]
## lugar -> Array de vereditos ({feature, nome, resultado, rotulo, medido, obs})
var vereditos := {}
var rng := RandomNumberGenerator.new()
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
## Na Prova de Fogo: "Prova de Fogo · sala 3 de 9" (vazio fora dela), e o que
## o ✕ do veredito faz.
var na_prova_de_fogo := ""
var seguir := "voltar ao salão"
var _teste_dir := [0.0, 0.0, 0.0, 0.0]  ## o segundo pulso do teste da háptica


func entrar(js: Array) -> void:
	rng.seed = int(Forja.semente) * 131 + hash(id)
	super(js)
	for p in jogadores:
		Forja.med_comecar(p.lugar, botoes_pedidos)
		Forja.med_repouso(p.lugar, true)
		p.controlavel = false
	if papel_som >= 0:
		# o som de cada um, achado como um jogo acha; o aviso mostra e deixa trocar
		Forja.som_preparar(papel_som)


func sair() -> void:
	for p in jogadores:
		Forja.med_parar(p.lugar)
		p.preso = false
		if _itens.has(p.lugar):
			p.visual(p.modelo_i, int(_itens[p.lugar]))
	if papel_som >= 0:
		Forja.som_encerrar()
	super()


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
			_quadro_aviso()
		"jogo":
			jogar(dt)
			var todos := true
			for p in jogadores:
				if jogando[p.lugar] and not acabou[p.lugar] and Forja.lugar(p.lugar).get("conectado", false):
					todos = false
			if todos or (duracao > 0.0 and t_fase >= duracao):
				terminar()
		"fim":
			_quadro_fim()


func _quadro_aviso() -> void:
	var presentes := 0
	var n_prontos := 0
	for p in jogadores:
		var l: int = p.lugar
		if not Forja.lugar(l).get("conectado", false):
			continue
		presentes += 1
		if papel_som >= 0:
			_afinar_som(l, p)
		if not prontos[l] and t_fase > 0.5:
			if Forja.apertou(l, Forja.CRUZ) or (Forja.robo and t_fase > 1.4 + 0.2 * l):
				prontos[l] = true
				Forja.vibrar(l, 0.0, 0.3, 60)
				Som.tocar("tique", p.global_position + Vector3(0, 1, 0))
		if prontos[l]:
			n_prontos += 1
	if presentes > 0 and n_prontos == presentes and t_fase > 0.9:
		comecar()


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
	for p in jogadores:
		jogando[p.lugar] = true
		Forja.med_repouso(p.lugar, false)
	Forja.evento("sala", 0, {"sala": id, "evento": "jogo_comecou"})
	Som.tocar("confirma")
	iniciar_jogo()


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
	for p in jogadores:
		var l: int = p.lugar
		if jogando[l]:
			vereditos[l] = dar_vereditos(l)
		Forja.med_parar(l)
		Forja.silencio(l)
	Forja.evento("sala", 0, {"sala": id, "evento": "jogo_terminou"})
	Forja.gravar_relatorio()
	Som.tocar("sucesso")
	ao_terminar()


func ao_terminar() -> void:
	pass


func _quadro_fim() -> void:
	if t_fase < 0.8:
		return
	for p in jogadores:
		if Forja.apertou(p.lugar, Forja.CRUZ):
			terminou.emit()
			return
	if Forja.robo and t_fase > 3.0:
		terminou.emit()


## A linha da HUD de cada lugar: pontos, ou "terminou".
func status(lugar: int) -> String:
	if fase == "aviso":
		return "pronto" if prontos[lugar] else "✕ quando pronto"
	if fase == "fim":
		return "%d pontos" % pontos[lugar]
	if acabou[lugar]:
		return "terminou · %d" % pontos[lugar]
	return "%d pontos" % pontos[lugar]


func marcar(lugar: int, n: int) -> void:
	pontos[lugar] += n


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
