class_name Minigame
extends SalaJogo

const CHAVES := ["slot", "titulo", "verbo", "genero", "icone", "entradas", "camera", "faixa", "duracao",
	"fim", "sensacoes", "material", "microjogo"]
const GENEROS := ["tct", "2v2", "coop", "corrida", "sobrevivencia", "terror", "sabotagem"]
const FINS := ["tempo", "ultimo_em_pe", "primeiro_a_chegar", "meta_coletiva"]
const CAMERAS := ["fixa", "grupo", "corrida"]
const MATERIAIS := ["metal", "pedra", "areia", "gelo", "grama", "lama", "plasma", "madeira"]
const ICONE_DA_PARTE := {"botoes": "cross", "analogicos": "stick_l", "gatilhos": "l2", "gatilho_adaptativo": "r2",
	"vibracao": "rumble_esquerdo", "haptica": "rumble_direito", "alto_falante": "alto-falante", "microfone": "mic",
	"barra_de_luz": "lightbar"}

const RAIAS := [-6.0, -2.0, 2.0, 6.0]
const Z_JOGADOR := 1.4
const TOM_DO_LUGAR := [1.0, 1.1225, 1.3348, 1.4983]
const FALA_S := 20.0

var ficha := {}
var _raias := {}
var _ultima_fala := [-FALA_S, -FALA_S, -FALA_S, -FALA_S]
const COMBO := 8
var _perfeitos_seguidos := [0, 0, 0, 0]


func _init() -> void:
	var achada = get_script().get_script_constant_map().get("FICHA", {})
	ficha = (achada as Dictionary).duplicate(true)
	id = str(ficha.get("slot", ""))
	nome = str(ficha.get("titulo", ""))
	acao = str(ficha.get("verbo", ""))
	duracao = float(ficha.get("duracao", 90.0))
	var parte := str(ficha.get("icone", ""))
	icone = str(ICONE_DA_PARTE.get(parte, parte))
	features = Array(ficha.get("features", []))
	botoes_pedidos = Forja.mascara(Array(ficha.get("botoes_medidos", [])))
	gesto_do_aviso = str(ficha.get("gesto", ""))
	com_treino = bool(ficha.get("treino", true))


func entrar(js: Array) -> void:
	conferir_a_ficha()
	super(js)


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


func comecar() -> void:
	var faixa := str(ficha.get("faixa", ""))
	var mapa := Musica.mapa(faixa)
	Ritmo.tocar(faixa, float(mapa.bpm), float(mapa.primeiro_tempo))
	Ritmo.dono = id
	Ritmo.zerar_ajuda()
	super()


func terminar() -> void:
	if fase == "fim":
		return
	Ritmo.parar()
	super()


func sair() -> void:
	if Ritmo.batida_cheia.is_connected(_contar_a_entrada):
		Ritmo.batida_cheia.disconnect(_contar_a_entrada)
	Ritmo.pausar(false)
	Ritmo.parar()
	super()


func congelar(sim: bool) -> void:
	super(sim)
	Ritmo.pausar(sim)


func _process(dt: float) -> void:
	if not congelada and fase == "jogo":
		for p in jogadores:
			var l: int = p.lugar
			if jogando[l] and not acabou[l] and conectado(l):
				robo(l, dt)
	super(dt)


func toque(_l: int, _julgamento: int) -> void:
	pass


func falha(_l: int) -> void:
	pass


func robo(_l: int, _dt: float) -> void:
	pass


func conectado(l: int) -> bool:
	return bool(Forja.lugar(l).get("conectado", false))


func presentes() -> Array:
	var r: Array = []
	for p in jogadores:
		if jogando[p.lugar]:
			r.append(p.lugar)
	return r


func na_raia(l: int) -> bool:
	return fase == "jogo" and bool(jogando[l]) and conectado(l)


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


func acender_raia(l: int, forca: float) -> void:
	if not _raias.has(l):
		return
	var r: Dictionary = _raias[l]
	Tema.emissivo(r.mat_borda, 0.4 + 2.0 * forca, l)
	(r.luz as OmniLight3D).light_energy = 1.6 * forca


func posicionar(l: int) -> void:
	var p := jogador(l)
	if p == null:
		return
	p.position = Vector3(RAIAS[l], 0.1, Z_JOGADOR)
	p.rotation.y = 0.0
	maos_livres(p)


func julgar_toque(l: int, t_alvo: float, n := -1, perigo := false) -> int:
	var t_toque := Ritmo.t_musica()
	var folga := Ritmo.folga_para(l, pontos, presentes()) if perigo else 0.0
	var j := Ritmo.julgar(l, t_toque, t_alvo, folga)
	Ritmo.registrar_toque(l, n, j, Ritmo.desvio_ms(l, t_toque, t_alvo))
	Ritmo.contar_para_ajuda(l, j)
	_reagir(l, j)
	if j == Ritmo.ERRO:
		falha(l)
	else:
		toque(l, j)
	return j


func nota_perdida(l: int, n: int) -> void:
	Ritmo.registrar_toque(l, n, Ritmo.ERRO)
	Ritmo.contar_para_ajuda(l, Ritmo.ERRO)
	_reagir(l, Ritmo.ERRO)
	falha(l)


func nova_nota(l: int, n: int, t_alvo: float) -> void:
	Ritmo.registrar_nota(l, n, t_alvo)


func falar(l: int, _evento: String) -> bool:
	if t - float(_ultima_fala[l]) < FALA_S:
		return false
	_ultima_fala[l] = t
	return true


func _reagir(l: int, j: int) -> void:
	var p := jogador(l)
	var pos := p.global_position + Vector3(0, 1.2, 0) if p else Vector3(RAIAS[l], 1.2, Z_JOGADOR)
	if j == Ritmo.ERRO:
		_perfeitos_seguidos[l] = 0
		Forja.sentir(l, "erro")
		Forja.som_falante(l, "nota_quebrada:%d" % l, 0.7)
		Som.tocar("falha", pos, -6.0)
		Musica.reagir("erro")
		return
	var perfeito := j == Ritmo.PERFEITO
	Forja.tocar_material(l, str(ficha.material), "perfeito" if perfeito else "acerto", 1.0 if perfeito else 0.7)
	Som.tocar("nota", pos, -4.0 if perfeito else -9.0, TOM_DO_LUGAR[l])
	if perfeito:
		Forja.som_falante(l, "nota:%d" % l, 0.8)
		_perfeitos_seguidos[l] += 1
		if _perfeitos_seguidos[l] >= COMBO:
			_perfeitos_seguidos[l] = 0
			Musica.reagir("combo")
		else:
			Musica.reagir("perfeito")
	else:
		_perfeitos_seguidos[l] = 0


const BATIDA_DA_PRIMEIRA_NOTA := 4


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
