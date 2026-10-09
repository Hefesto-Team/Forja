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


func entrar(js: Array) -> void:
	conferir_a_ficha()
	super(js)


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
	return ok


# ---------------------------------------------------------------- as fases --

## A fase jogo: a faixa da ficha começa do zero, e o relógio parte dela.
func comecar() -> void:
	var faixa := str(ficha.get("faixa", ""))
	var mapa := Musica.mapa(faixa)
	Ritmo.tocar(faixa, float(mapa.bpm), float(mapa.primeiro_tempo))
	Ritmo.dono = id
	Ritmo.zerar_ajuda()
	super()


## O fim: o relógio solta a faixa. O registro (`minigame` `terminou` com o
## vencedor, `desempenho`) é da SalaJogo.
func terminar() -> void:
	if fase == "fim":
		return
	Ritmo.parar()
	super()


func sair() -> void:
	Ritmo.pausar(false)
	Ritmo.parar()
	super()


## A pausa por cima: o jogo e o relógio da música param juntos.
func congelar(sim: bool) -> void:
	super(sim)
	Ritmo.pausar(sim)


## O kit chama robo(l, dt) de quem ainda joga, antes do jogar(dt) da SalaJogo.
func _process(dt: float) -> void:
	if not congelada and fase == "jogo":
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
	Kit.cilindro(raiz, 1.45, 0.06, Vector3(0, 0.03, 0), Kit.material(Tema.PAINEL, 0.0, 0.9))
	var borda := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 1.4
	tor.outer_radius = 1.5
	tor.rings = 48
	borda.mesh = tor
	borda.position = Vector3(0, 0.08, 0)
	borda.scale = Vector3(1, 0.35, 1)
	var mat := Kit.material(cor.darkened(0.45), 0.0, 0.7)
	mat.emission_enabled = true
	mat.emission = cor
	mat.emission_energy_multiplier = 0.4
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
	(r.mat_borda as StandardMaterial3D).emission_energy_multiplier = 0.4 + 2.0 * forca
	(r.luz as OmniLight3D).light_energy = 1.6 * forca


## O boneco do lugar no meio da raia, de frente, de mãos livres.
func posicionar(l: int) -> void:
	var p := jogador(l)
	if p == null:
		return
	p.position = Vector3(RAIAS[l], 0.1, Z_JOGADOR)
	p.rotation.y = 0.0
	maos_livres(p)


## Julga o toque do lugar agora contra a nota em t_alvo (tempo de música) e
## faz o que todo toque julgado faz: a folga de quem está em último (só se a
## nota é um perigo físico), o registro, a ajuda, a sensação e o som da nota
## na TV — e chama toque() nos acertos ou falha() no erro. Devolve o julgamento.
func julgar_toque(l: int, t_alvo: float, n := -1, perigo := false) -> int:
	var t_toque := Ritmo.t_musica()
	var folga := Ritmo.folga_para(l, pontos, presentes()) if perigo else 0.0
	var j := Ritmo.julgar(l, t_toque, t_alvo, folga)
	# G03: o item entra aqui (Itens.ajustar_julgamento e o Escudo, Itens.absorve_erro)
	Ritmo.registrar_toque(l, n, j, Ritmo.desvio_ms(l, t_toque, t_alvo))
	Ritmo.contar_para_ajuda(l, j)
	_reagir(l, j)
	if j == Ritmo.ERRO:
		falha(l)
	else:
		toque(l, j)
	return j


## A nota n do lugar passou sem toque: é erro, com a falha física.
func nota_perdida(l: int, n: int) -> void:
	Ritmo.registrar_toque(l, n, Ritmo.ERRO)
	Ritmo.contar_para_ajuda(l, Ritmo.ERRO)
	_reagir(l, Ritmo.ERRO)
	falha(l)


## Uma nota nova do lugar, no registro (a G03 põe a Lanterna aqui).
func nova_nota(l: int, n: int, t_alvo: float) -> void:
	Ritmo.registrar_nota(l, n, t_alvo)


## Uma fala do cavaleiro do lugar, no máximo uma a cada FALA_S s. Devolve se
## falou. A G07 põe a fala de verdade aqui.
func falar(l: int, _evento: String) -> bool:
	if t - float(_ultima_fala[l]) < FALA_S:
		return false
	_ultima_fala[l] = t
	return true


func _reagir(l: int, j: int) -> void:
	var p := jogador(l)
	var pos := p.global_position + Vector3(0, 1.2, 0) if p else Vector3(RAIAS[l], 1.2, Z_JOGADOR)
	if j == Ritmo.ERRO:
		Forja.sentir(l, "erro")
		Som.tocar("falha", pos, -6.0)
	else:
		Forja.sentir(l, "perfeito" if j == Ritmo.PERFEITO else "acerto")
		Som.tocar("nota", pos, -4.0 if j == Ritmo.PERFEITO else -9.0, TOM_DO_LUGAR[l])
