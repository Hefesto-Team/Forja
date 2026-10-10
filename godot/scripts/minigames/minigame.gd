class_name Minigame
extends SalaJogo
## O kit do minigame (docs/jogo/13-arquitetura.md#o-kit-do-minigame--h04): o
## que todo minigame tem e nenhum repete — a ficha de dados, as raias, quem
## está conectado, o relógio da faixa, o julgamento do toque, o registro da
## nota e do toque, as falas e a colocação. O minigame escreve a FICHA (um
## const no próprio script: docs/jogo/tarefas/molde-de-minigame.md) e os
## ganchos: montar, iniciar_jogo, jogar, toque, falha, vencedor e robo.
##
## O kit não sabe de robô: chama robo(l, dt) de todo lugar em jogo, a cada
## quadro, e só o gancho do minigame olha Forja.robo (docs/jogo/13, a
## paridade entre a prova e o jogo).
##
## Os eventos `minigame` e `desempenho` têm um dono só: a SalaJogo. A
## colocação é a `var colocacao` dela, preenchida pelo `vencedor()` (por
## padrão, pelos pontos); o kit não declara `func colocacao()`.

## As chaves que toda FICHA tem.
const CHAVES := ["slot", "titulo", "verbo", "genero", "icone", "entradas", "camera", "faixa", "duracao",
	"fim", "sensacoes", "material", "microjogo"]
const GENEROS := ["tct", "2v2", "coop", "corrida", "sobrevivencia", "terror", "sabotagem"]
const FINS := ["tempo", "ultimo_em_pe", "primeiro_a_chegar", "meta_coletiva"]
const CAMERAS := ["fixa", "grupo", "corrida"]
const MATERIAIS := ["metal", "pedra", "areia", "gelo", "grama", "lama", "plasma", "madeira"]
## A FICHA.icone pode dizer a parte do controle; o aviso desenha o glifo dela
## (assets/glifos/). Um nome de glifo passa como está.
const ICONE_DA_PARTE := {"botoes": "cross", "analogicos": "stick_l", "gatilhos": "l2", "gatilho_adaptativo": "r2",
	"vibracao": "rumble_esquerdo", "haptica": "rumble_direito", "alto_falante": "alto-falante", "microfone": "mic",
	"barra_de_luz": "lightbar"}

## As quatro raias: o x de cada lugar, e onde o boneco fica nela.
const RAIAS := [-6.0, -2.0, 2.0, 6.0]
const Z_JOGADOR := 1.4
## A nota de cada lugar na TV (o hoqueto, docs/jogo/02#3): dó, ré, fá e sol
## sobre o som "nota".
const TOM_DO_LUGAR := [1.0, 1.1225, 1.3348, 1.4983]
## Uma fala por lugar a cada FALA_S segundos, no máximo (G07).
const FALA_S := 20.0

var ficha := {}  ## a FICHA do script do minigame (lida no _init)
var _raias := {}  ## lugar -> {raiz, mat_borda, luz}
var _ultima_fala := [-FALA_S, -FALA_S, -FALA_S, -FALA_S]
const COMBO := 8  ## quantos perfeitos seguidos fazem a música brilhar (H07)
var _perfeitos_seguidos := [0, 0, 0, 0]

# ---------------------------------------------------------------- H08: as decisões comuns --
# docs/jogo/13-arquitetura.md#as-decisões-comuns-dos-minigames--h08

## O teto do minigame, já com o ritmo do nível.
const DURACAO_MAX := 120.0
## Depois disto (s de música além do alvo, já sem a calibração), a nota passou.
const FOLGA_PERDIDA := 0.140
## Até onde um toque procura a nota em aberto, para os dois lados (s de música).
const ALCANCE_DO_TOQUE := 0.5
## A barra de luz no toque julgado: o perfeito pisca branco; o erro escurece a cor do lugar.
const PISCA_PERFEITO_S := 0.15
const PISCA_ERRO_S := 0.5
## Os eventos do jogo (o 13) e o que eles aceitam.
const TIPOS_DO_JOGO := ["entrada", "jogo", "pista", "troca", "voz", "estacao"]
const CANAIS_DA_PISTA := ["haptica", "alto_falante", "rumble", "tela", "tv"]
## As trocas de canal por falta de recurso (13, os eventos do jogo): de -> para.
const TROCAS := {"giroscopio": ["analogico"], "haptica": ["rumble"], "microfone": ["sem_microfone"],
	"alto_falante": ["tv", "rumble"], "touchpad": ["botoes"]}
## As equipes do 2v2: a cor vai no chão e na armadura, nunca na barra de luz.
const BRASA := 0
const MARE := 1
const NOMES_DAS_EQUIPES := ["A Brasa", "A Maré"]
const FRASES_DAS_EQUIPES := ["A Brasa venceu!", "A Maré venceu!"]
const CORES_DAS_EQUIPES := [Color(0.910, 0.639, 0.235), Color(0.184, 0.702, 0.702)]  # #e8a33c, #2fb3b3

var equipe := [-1, -1, -1, -1]  ## lugar -> BRASA, MARE, ou -1 (fora do 2v2)
var aprendizes := [0, 0]  ## quantos Aprendizes completam cada equipe (docs/jogo/tarefas/Q-a-prova.md)
var _pontos_sem_lugar := [0, 0]  ## os pontos da equipe que só tem Aprendizes
var _notas := [{}, {}, {}, {}]  ## lugar -> {n: [t_alvo, perigo]}: as notas em aberto
var _inicio_valendo := -1.0  ## o t_musica em que o jogo passou a valer (-1: ainda não)
var _tempo_final := -1.0  ## o tempo jogado no instante do fim (-1: não acabou)
var _julgando := [-1, -1, -1, -1]  ## o julgamento do toque em curso (o marcar dentro do toque() passa pelo item)
var _tempo_forte := [false, false, false, false]
var _nota_no_falante := true
var _textura_no_acerto := true


## Lê a FICHA do script do minigame. O minigame não escreve _init(); se
## escrever, a primeira linha é super().
func _init() -> void:
	var achada = get_script().get_script_constant_map().get("FICHA", {})
	ficha = (achada as Dictionary).duplicate(true)
	id = str(ficha.get("slot", ""))
	nome = str(ficha.get("titulo", ""))
	acao = str(ficha.get("verbo", ""))
	duracao = float(ficha.get("duracao", 90.0))
	var parte := str(ficha.get("icone", ""))
	icone = str(ICONE_DA_PARTE.get(parte, parte))
	# as chaves opcionais (o molde): o que a bancada mede, o gesto do aviso, o treino
	features = Array(ficha.get("features", []))
	botoes_pedidos = Forja.mascara(Array(ficha.get("botoes_medidos", [])))
	gesto_do_aviso = str(ficha.get("gesto", ""))
	com_treino = bool(ficha.get("treino", true))
	# H08: o que sai da FICHA sem ninguém repetir
	coop = str(ficha.get("genero", "")) == "coop"
	_nota_no_falante = bool(ficha.get("nota_no_falante", true))
	_textura_no_acerto = bool(ficha.get("textura_no_acerto", true))
	if ficha.has("papel_som"):
		papel_som = int(ficha.papel_som)


func entrar(js: Array) -> void:
	conferir_a_ficha()
	if str(ficha.get("genero", "")) == "2v2":
		# antes do montar(): o chão e a armadura já sabem a equipe
		var lugares: Array = []
		for p in js:
			lugares.append(int(p.lugar))
		montar_equipes(lugares)
	super(js)
	# a SalaJogo multiplicou pelo ritmo do nível; o teto fica
	duracao = minf(duracao, DURACAO_MAX)


## Falta chave, ou um valor fora da lista? Falha alto (push_error) e diz qual.
func conferir_a_ficha() -> bool:
	var ok := true
	for k in CHAVES:
		if not ficha.has(k):
			push_error("minigame %s: a FICHA não tem «%s»" % [get_script().resource_path, k])
			ok = false
	if not ok:
		return false
	for par in [["genero", GENEROS], ["fim", FINS], ["camera", CAMERAS], ["material", MATERIAIS]]:
		if not str(ficha[par[0]]) in par[1]:
			push_error("minigame %s: «%s» não vale em %s" % [id, ficha[par[0]], par[0]])
			ok = false
	if not ResourceLoader.exists("res://assets/glifos/%s.png" % icone):
		push_error("minigame %s: o ícone «%s» não é um glifo de assets/glifos/ (o molde lista)" % [id, ficha.icone])
		ok = false
	var d := float(ficha.duracao)
	if d > DURACAO_MAX:
		push_error("minigame %s: a duração passa de %d s" % [id, int(DURACAO_MAX)])
		ok = false
	if d <= 0.0 and str(ficha.fim) == "tempo":
		push_error("minigame %s: fim «tempo» sem duração (0.0 só vale para o fim do próprio jogo)" % id)
		ok = false
	if ficha.has("papel_som") and not int(ficha.papel_som) in [Forja.PAPEL_ALTO_FALANTE, Forja.PAPEL_HAPTICA, Forja.PAPEL_MICROFONE]:
		push_error("minigame %s: «papel_som» não é um Forja.PAPEL_*" % id)
		ok = false
	return ok


# ---------------------------------------------------------------- as fases --

## A fase jogo: a faixa da ficha começa do zero, e o relógio parte dela.
func comecar() -> void:
	_notas = [{}, {}, {}, {}]
	_inicio_valendo = -1.0
	_tempo_final = -1.0
	var faixa := str(ficha.get("faixa", ""))
	var mapa := Musica.mapa(faixa)
	Ritmo.tocar(faixa, float(mapa.bpm), float(mapa.primeiro_tempo))
	Ritmo.dono = id
	Ritmo.zerar_ajuda()
	super()
	if not treinando:
		_inicio_valendo = Ritmo.t_musica()


## O fim: o relógio solta a faixa. O registro (`minigame` `terminou` com o
## vencedor, `desempenho`) é da SalaJogo.
func terminar() -> void:
	if fase == "fim":
		return
	_tempo_final = tempo_jogado()
	Ritmo.parar()
	super()


func sair() -> void:
	if Ritmo.batida_cheia.is_connected(_contar_a_entrada):
		Ritmo.batida_cheia.disconnect(_contar_a_entrada)
	Ritmo.pausar(false)
	Ritmo.parar()
	super()


## A pausa por cima: o jogo e o relógio da música param juntos.
func congelar(sim: bool) -> void:
	super(sim)
	Ritmo.pausar(sim or esperando_controle)


## O kit chama robo(l, dt) de quem ainda joga, antes do jogar(dt) da SalaJogo.
func _process(dt: float) -> void:
	if not congelada and fase == "jogo":
		if not treinando and _inicio_valendo < 0.0:
			_inicio_valendo = Ritmo.t_musica()  # o treino acabou: daqui vale
		for p in jogadores:
			var l: int = p.lugar
			if jogando[l] and not acabou[l] and conectado(l):
				robo(l, dt)
	super(dt)


# ---------------------------------------------------------------- os ganchos --
# montar(), iniciar_jogo(), jogar(dt) e vencedor() são da Sala e da SalaJogo; o
# minigame os escreve. Estes três são do kit.

## A consequência de um toque julgado BOM, OTIMO ou PERFEITO (o ERRO vai para falha).
func toque(_l: int, _julgamento: int) -> void:
	pass


## A falha física: o toque ERRO, ou a nota que passou sem toque.
func falha(_l: int) -> void:
	pass


## Como o robô joga o lugar neste quadro, pelo controle simulado
## (Forja.robo_apertar, robo_eixo...). É o único lugar do minigame que olha
## Forja.robo: a primeira linha é `if not Forja.robo: return`.
func robo(_l: int, _dt: float) -> void:
	pass


# ---------------------------------------------------------------- o kit --

func conectado(l: int) -> bool:
	return bool(Forja.lugar(l).get("conectado", false))


## Os lugares que estão jogando este minigame.
func presentes() -> Array:
	var r: Array = []
	for p in jogadores:
		if jogando[p.lugar]:
			r.append(p.lugar)
	return r


## O lugar está jogando agora (em jogo, e com controle)? A guarda da dica e do status.
func na_raia(l: int) -> bool:
	return fase == "jogo" and bool(jogando[l]) and conectado(l)


## A raia do lugar: a laje, a borda na cor do lugar e a luz da vez (apagada).
func raia(l: int) -> Node3D:
	var cor := Forja.cor_do_lugar(l)
	var raiz := Node3D.new()
	raiz.name = "Raia%d" % (l + 1)
	raiz.position = Vector3(RAIAS[l], 0.0, Z_JOGADOR)
	add_child(raiz)
	Kit.cilindro(raiz, 1.45, 0.06, Vector3(0, 0.03, 0), Kit.material(Tema.CASCO, 0.0, 0.9))
	var borda := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 1.4
	tor.outer_radius = 1.5
	tor.rings = 48
	borda.mesh = tor
	borda.position = Vector3(0, 0.08, 0)
	borda.scale = Vector3(1, 0.35, 1)
	var mat := Kit.material(cor.darkened(0.45), 0.0, 0.7)
	Tema.emissivo(mat, 0.4, l)
	borda.material_override = mat
	raiz.add_child(borda)
	var luz := OmniLight3D.new()
	luz.position = Vector3(0, 2.2, 0.6)
	luz.light_color = cor
	luz.light_energy = 0.0
	luz.omni_range = 3.5
	raiz.add_child(luz)
	_raias[l] = {"raiz": raiz, "mat_borda": mat, "luz": luz}
	return raiz


## Acende a raia do lugar (0 apagada, 1 a vez dele).
func acender_raia(l: int, forca: float) -> void:
	if not _raias.has(l):
		return
	var r: Dictionary = _raias[l]
	Tema.emissivo(r.mat_borda, 0.4 + 2.0 * forca, l)
	(r.luz as OmniLight3D).light_energy = 1.6 * forca


## O boneco do lugar no meio da raia, de frente, de mãos livres.
func posicionar(l: int) -> void:
	var p := jogador(l)
	if p == null:
		return
	p.position = Vector3(RAIAS[l], 0.1, Z_JOGADOR)
	p.rotation.y = 0.0
	maos_livres(p)


## Uma fala do cavaleiro do lugar, no máximo uma a cada FALA_S s. Devolve se
## falou. A G07 põe a fala de verdade aqui.
func falar(l: int, _evento: String) -> bool:
	if t - float(_ultima_fala[l]) < FALA_S:
		return false
	_ultima_fala[l] = t
	return true


## O que todo toque julgado faz no controle do dono, na TV e na barra de luz.
## A textura vai só aos atuadores (o alto-falante fica para a nota); a FICHA
## desliga a nota (nota_no_falante) ou a textura (textura_no_acerto) quando
## aquele canal é a pista do minigame. Depois do piscar, a barra volta à
## luz_de_repouso.
func _reagir(l: int, j: int) -> void:
	var p := jogador(l)
	var pos := p.global_position + Vector3(0, 1.2, 0) if p else Vector3(RAIAS[l], 1.2, Z_JOGADOR)
	_musica_reage(l, j)
	if j == Ritmo.ERRO:
		Forja.piscar(l, Forja.cor_do_lugar(l).darkened(0.7), PISCA_ERRO_S)
		Forja.luz(l, luz_de_repouso(l))
		Forja.sentir(l, "erro")
		if _nota_no_falante:
			Forja.som_falante(l, "nota_quebrada:%d" % l, 0.7)
		Som.tocar("falha", pos, -6.0)
		return
	var perfeito := j == Ritmo.PERFEITO
	# o acerto na mão: a textura do material nos atuadores; sem háptica (o rádio), pelo rumble
	if _textura_no_acerto and not Forja.textura(l, str(ficha.material), 1.0 if perfeito else 0.7):
		Forja.sentir(l, "perfeito" if perfeito else "acerto")
	Som.tocar("nota", pos, -4.0 if perfeito else -9.0, TOM_DO_LUGAR[l])
	if perfeito:
		Forja.piscar(l, Color.WHITE, PISCA_PERFEITO_S)
		Forja.luz(l, luz_de_repouso(l))
		if _nota_no_falante:
			Forja.som_falante(l, "nota:%d" % l, 0.8)


## A música reage e o combo conta (H07: Musica.reagir, COMBO, _perfeitos_seguidos).
func _musica_reage(l: int, j: int) -> void:
	if j == Ritmo.ERRO:
		_perfeitos_seguidos[l] = 0
		Musica.reagir("erro")
	elif j != Ritmo.PERFEITO:
		_perfeitos_seguidos[l] = 0
	else:
		_perfeitos_seguidos[l] += 1
		if _perfeitos_seguidos[l] >= COMBO:
			_perfeitos_seguidos[l] = 0
			Musica.reagir("combo")
		else:
			Musica.reagir("perfeito")


## A cor a que a barra de luz do lugar volta depois do piscar (13, a barra de
## luz reage no kit). O minigame que carrega estado na barra (a vida, o
## silêncio) sobrescreve: sempre a cor do lugar, só com outro brilho, nunca
## abaixo de 30% (Forja.luz põe o piso).
func luz_de_repouso(l: int) -> Color:
	return Forja.cor_do_lugar(l)


# ---------------------------------------------------------------- a contagem de entrada (H06) --

## A primeira nota de um minigame vem neste tempo ou depois: os quatro
## primeiros são a contagem de entrada (JIN_ENTRADA, H06).
const BATIDA_DA_PRIMEIRA_NOTA := 4


## A contagem de entrada no tempo da faixa: tique nos tempos 0, 1 e 2 e o
## "vai" no 3 (no lugar do "confirma" solto da SalaJogo).
func _som_do_comeco() -> void:
	if not Ritmo.batida_cheia.is_connected(_contar_a_entrada):
		Ritmo.batida_cheia.connect(_contar_a_entrada)


func _contar_a_entrada(n: int) -> void:
	if n <= 2:
		Som.jingle("JIN_ENTRADA")
	elif n == 3:
		Som.tocar("confirma")
	if n >= 3 and Ritmo.batida_cheia.is_connected(_contar_a_entrada):
		Ritmo.batida_cheia.disconnect(_contar_a_entrada)


# ---------------------------------------------------------------- o tempo (H08) --

## O tempo que já valeu (o treino fora), em s de música: com faixa, a placa
## de som; sem faixa, o relógio do sistema — os dois pelo Ritmo. Congela no
## fim e na pausa. O fim da SalaJogo (tempo_acabou) e a barra do painel
## (tempo_que_resta) leem daqui.
func tempo_jogado() -> float:
	if _tempo_final >= 0.0:
		return _tempo_final
	if _inicio_valendo < 0.0:
		return 0.0
	return maxf(0.0, Ritmo.t_musica() - _inicio_valendo)


## 0..1 da duração (0 sem duração: o fim é do próprio jogo). É o `progresso`
## do 13: `progresso()` já é a linha de texto da SalaJogo.
func andamento() -> float:
	return clampf(tempo_jogado() / duracao, 0.0, 1.0) if duracao > 0.0 else 0.0


## O terço do meio da duração: o pico da faixa.
func no_pico() -> bool:
	var a := andamento()
	return a >= 1.0 / 3.0 and a < 2.0 / 3.0


# ---------------------------------------------------------------- a fila de notas (H08) --

## A próxima batida do lugar **depois** de `desde`, num passo de `passo`
## batidas deslocado de `desloc` (o hoqueto: a vez de cada um), nunca antes de
## BATIDA_DA_PRIMEIRA_NOTA. Quem está na partitura mais simples
## (Ritmo.simples) tem o passo dobrado.
func proxima_batida(l: int, desde: float, passo: float, desloc := 0.0) -> float:
	if Ritmo.simples[l]:
		passo *= 2.0
	passo = maxf(passo, 0.25)
	var k := floorf((desde - desloc) / passo) + 1.0
	return maxf(k * passo + desloc, BATIDA_DA_PRIMEIRA_NOTA + desloc)


## Uma nota nova do lugar: vai para o registro e para a fila das notas em
## aberto (casar_toque, notas_perdidas). `perigo`: a folga de quem está em
## último vale nela (docs/jogo/02#8).
func nova_nota(l: int, n: int, t_alvo: float, perigo := false) -> void:
	_notas[l][n] = [t_alvo, perigo]
	Ritmo.registrar_nota(l, n, t_alvo)


## Os n das notas em aberto do lugar, da mais velha à mais nova.
func notas_em_aberto(l: int) -> Array:
	var r: Array = _notas[l].keys()
	r.sort()
	return r


## O t_alvo da nota n do lugar (-1 se ela não está em aberto).
func alvo_da(l: int, n: int) -> float:
	var nota: Array = _notas[l].get(n, [])
	return float(nota[0]) if not nota.is_empty() else -1.0


## A nota em aberto do lugar mais perto do toque de agora (o toque já
## corrigido pela calibração do lugar), dentro de ALCANCE_DO_TOQUE; -1: nenhuma.
func casar_toque(l: int) -> int:
	var agora := Ritmo.t_musica() - float(Ritmo.desvio[l])
	var melhor := -1
	var perto := ALCANCE_DO_TOQUE
	for n in _notas[l]:
		var d := absf(agora - float(_notas[l][n][0]))
		if d <= perto:
			perto = d
			melhor = int(n)
	return melhor


## Julga o toque de agora contra a nota n do lugar (a da fila) e a fecha.
## -1 se a nota não está em aberto.
func julgar_nota(l: int, n: int) -> int:
	var nota: Array = _notas[l].get(n, [])
	if nota.is_empty():
		return -1
	return julgar_toque(l, float(nota[0]), n, bool(nota[1]))


## As notas do lugar que passaram de FOLGA_PERDIDA (mais a folga de quem está
## em último, nas de perigo) sem toque: saem da fila e cada uma vira
## nota_perdida (o erro, a falha). Sem controle, saem caladas — não é erro de
## quem caiu. Devolve os n que viraram erro.
func notas_perdidas(l: int) -> Array:
	var agora := Ritmo.t_musica() - float(Ritmo.desvio[l])
	var passaram: Array = []
	for n in _notas[l].keys():
		var nota: Array = _notas[l][n]
		var folga := Ritmo.folga_para(l, pontos, presentes()) if bool(nota[1]) else 0.0
		if agora > float(nota[0]) + FOLGA_PERDIDA + folga:
			_notas[l].erase(n)
			passaram.append(int(n))
	if not conectado(l) or not jogando[l] or acabou[l]:
		return []
	passaram.sort()
	for n in passaram:
		nota_perdida(l, n)
	return passaram


## Julga o toque do lugar agora contra a nota em t_alvo (tempo de música) e
## faz o que todo toque julgado faz: fecha a nota n, a folga de quem está em
## último (só se a nota é perigo), o registro, a ajuda, a reação (controle,
## TV, barra de luz) — e chama toque() nos acertos ou falha() no erro. O
## Escudo (G03, errou) absorve o primeiro erro; o Martelo mexe nos pontos que
## o toque() marcar (o marcar do kit). Devolve o julgamento.
func julgar_toque(l: int, t_alvo: float, n := -1, perigo := false) -> int:
	if n >= 0:
		_notas[l].erase(n)
	var t_toque := Ritmo.t_musica()
	var folga := Ritmo.folga_para(l, pontos, presentes()) if perigo else 0.0
	var j := Ritmo.julgar(l, t_toque, t_alvo, folga)
	Ritmo.registrar_toque(l, n, j, Ritmo.desvio_ms(l, t_toque, t_alvo))
	Ritmo.contar_para_ajuda(l, j)
	_reagir(l, j)
	if j == Ritmo.ERRO:
		if not errou(l):
			falha(l)
		return j
	_julgando[l] = j
	_tempo_forte[l] = _no_tempo_forte(t_alvo)
	toque(l, j)
	_julgando[l] = -1
	return j


## A nota n do lugar passou sem toque: é erro, com a falha física (o Escudo
## absorve o primeiro).
func nota_perdida(l: int, n: int) -> void:
	_notas[l].erase(n)
	Ritmo.registrar_toque(l, n, Ritmo.ERRO)
	Ritmo.contar_para_ajuda(l, Ritmo.ERRO)
	_reagir(l, Ritmo.ERRO)
	if not errou(l):
		falha(l)


## Os pontos de um toque julgado passam pelo item (G03, o Martelo): o
## minigame chama marcar(l, n) dentro do toque() e nunca
## Itens.pontos_do_acerto.
func marcar(l: int, n: int) -> void:
	if _julgando[l] > Ritmo.ERRO and n > 0:
		n = Itens.pontos_do_acerto(l, n, _julgando[l], _tempo_forte[l])
	super(l, n)


## A nota cai no primeiro tempo do compasso (o tempo forte do Martelo)?
func _no_tempo_forte(t_alvo: float) -> bool:
	var b := (t_alvo - Ritmo.primeiro_tempo) * Ritmo.bpm / 60.0
	var inteira := roundf(b)
	return absf(b - inteira) < 0.05 and posmod(int(inteira), 4) == 0


# ---------------------------------------------------------------- o fim (H08) --

## Quem jogou melhor: o coop e a dupla mostram (as faíscas) e o registro
## leva. Padrão: o primeiro do vencedor(); no 2v2, pelos acertos de cada um
## (os pontos da dupla são os mesmos). O minigame troca quando o critério é
## outro.
func destaque() -> int:
	if str(ficha.get("genero", "")) == "2v2":
		var melhor := -1
		for l in presentes():
			if melhor < 0 or int(acertos[l]) > int(acertos[melhor]):
				melhor = int(l)
		return melhor
	var v := vencedor()
	return int(v[0]) if not v.is_empty() else -1


## O `minigame` `terminou`: o gênero sempre; no coop, vencedor -1 (todos
## venceram ou todos perderam), coop_venceu e o destaque; na dupla, a equipe.
func campos_do_fim() -> Dictionary:
	var c := super()
	var genero := str(ficha.get("genero", ""))
	c["genero"] = genero
	if coop:
		c["vencedor"] = -1
		c["coop_venceu"] = coop_venceu
		c["destaque"] = destaque()
	elif genero == "2v2":
		c["equipe"] = equipe_vencedora()
		c["equipes"] = equipe.duplicate()
	return c


func frase_do_resultado() -> String:
	if coop:
		return "Todos venceram!" if coop_venceu else "A forja apagou."
	if str(ficha.get("genero", "")) == "2v2":
		var e := equipe_vencedora()
		return "Empate!" if e < 0 else str(FRASES_DAS_EQUIPES[e])
	return super()


func quem_comemora() -> Array:
	if coop:
		return presentes() if coop_venceu else []
	if str(ficha.get("genero", "")) == "2v2":
		var e := equipe_vencedora()
		return da_equipe(e) if e >= 0 else []
	return super()


func quem_brilha() -> int:
	if coop or str(ficha.get("genero", "")) == "2v2":
		return destaque()
	return super()


# ---------------------------------------------------------------- as equipes (H08) --

## As equipes do 2v2 (a regra de docs/jogo/tarefas/Q-a-prova.md): os lugares
## na ordem; os dois primeiros são A Brasa, os dois seguintes A Maré; falta
## gente, o Aprendiz completa (aprendizes[e] diz quantos em cada equipe).
func montar_equipes(lugares: Array) -> void:
	equipe = [-1, -1, -1, -1]
	aprendizes = [0, 0]
	_pontos_sem_lugar = [0, 0]
	var ls := lugares.duplicate()
	ls.sort()
	match ls.size():
		4:
			for i in 4:
				equipe[ls[i]] = BRASA if i < 2 else MARE
		3:
			equipe[ls[0]] = BRASA
			equipe[ls[1]] = BRASA
			equipe[ls[2]] = MARE
			aprendizes = [0, 1]
		2:
			equipe[ls[0]] = BRASA
			equipe[ls[1]] = MARE
			aprendizes = [1, 1]
		1:
			equipe[ls[0]] = BRASA
			aprendizes = [1, 2]


## Os lugares da equipe (sem os Aprendizes).
func da_equipe(e: int) -> Array:
	return range(4).filter(func(l): return equipe[l] == e)


## Os pontos da equipe (os da dupla são os mesmos: marcar_equipe).
func pontos_da_equipe(e: int) -> int:
	var lista := da_equipe(e)
	return int(pontos[lista[0]]) if not lista.is_empty() else int(_pontos_sem_lugar[e])


## Pontos para a equipe inteira: vão para os dois da dupla (o item de quem
## tocou vale uma vez para a equipe). O acerto (o destaque, a dica aprendida)
## é só de quem tocou: o parceiro leva os pontos, não o acerto. Equipe só de
## Aprendizes: fica nela.
func marcar_equipe(e: int, n: int) -> void:
	var quem := -1
	for l in 4:
		if equipe[l] == e and _julgando[l] > Ritmo.ERRO and n > 0:
			n = Itens.pontos_do_acerto(l, n, _julgando[l], _tempo_forte[l])
			quem = l
			break
	var lista := da_equipe(e)
	if lista.is_empty():
		if not treinando:
			_pontos_sem_lugar[e] += n
		return
	for l in lista:
		if quem < 0 or l == quem:
			super.marcar(l, n)
		elif not treinando:
			pontos[l] += n


## A equipe que venceu (BRASA ou MARE); -1 no empate.
func equipe_vencedora() -> int:
	var b := pontos_da_equipe(BRASA)
	var m := pontos_da_equipe(MARE)
	if b == m:
		return -1
	return BRASA if b > m else MARE


# ---------------------------------------------------------------- os eventos do jogo (H08) --

## Um evento do jogo (docs/jogo/13, os eventos do jogo), com o slot. `l` é o
## lugar (0..3), ou -1 para o que é do minigame todo. Tipo fora da lista,
## canal de pista ou troca que não existe: push_error, e não grava.
func anotar(tipo: String, l: int, campos := {}) -> void:
	if not tipo in TIPOS_DO_JOGO:
		push_error("minigame %s: o evento «%s» não existe (13, os eventos do jogo)" % [id, tipo])
		return
	if tipo == "pista" and not str(campos.get("canal", "")) in CANAIS_DA_PISTA:
		push_error("minigame %s: pista por um canal que não existe (%s)" % [id, campos.get("canal", "")])
		return
	if tipo == "troca" and not str(campos.get("para", "")) in Array(TROCAS.get(str(campos.get("de", "")), [])):
		push_error("minigame %s: troca que não existe (%s → %s)" % [id, campos.get("de", ""), campos.get("para", "")])
		return
	var c: Dictionary = campos.duplicate()
	c["slot"] = id
	Forja.evento(tipo, l + 1 if l >= 0 else 0, c)


## A espera do controle que cai (F09c) para a música junto, como a pausa: o
## tempo jogado do minigame é o relógio da faixa.
func esperar_o_controle(sim: bool, lugares: Array) -> void:
	var antes := esperando_controle
	super(sim, lugares)
	if antes != esperando_controle:
		Ritmo.pausar(esperando_controle or congelada)
