class_name Visor
extends Control
## O visor acima de cada cavaleiro (G04; arte/07 o carimbo, arte/09 os carimbos do jogo): uma camada acima do HUD.
## A vaga 0 é o carimbo do julgamento; a vaga 1, um carimbo do jogo ou a fala (nunca os dois). O ponto de cada
## cavaleiro se recalcula a cada quadro: o carimbo acompanha o boneco. O tempo é o `dt` somado, não o quadro.

const ORDEM := ["car_acorde", "car_virada", "car_em_chamas", "car_por_um_fio", "car_liga"]
const NO_VISOR := {"car_virada": "VIRADA!", "car_em_chamas": "EM CHAMAS", "car_por_um_fio": "POR UM FIO",
	"car_liga": "LIGA!", "car_acorde": "ACORDE MAIOR!", "car_emburrado": ""}
const LETRA := {"car_virada": 64, "car_em_chamas": 46, "car_por_um_fio": 64, "car_liga": 46, "car_acorde": 112}
## As fases do carimbo (arte/07): bate em 80 ms, fica, some em 170 ms; espirra por 6 quadros.
const BATE := 0.08
const SOME := 0.17
const FICA_JULGAMENTO := 0.25
const ESPIRRA := 6.0 / 60.0
const GRAUS := -4.0
## Movimento reduzido: só opacidade, em 4 quadros.
const QUATRO_QUADROS := 4.0 / 60.0
## A fala: a etiqueta pequena, até 420 px, Archivo 600 34, até 2 linhas, 24 px de margem.
const LARG_FALA := 420.0

var jogadores: Array = []  ## os ForjaPlayer, pelo lugar (o main põe)
var vivos: Array = []  ## os carimbos e as falas na tela: {l, id, palavra, vaga, t, fica, tam, onde, respingos}
## O HUD que o visor segue: visível com ele, ou com um carimbo preso a um ponto da tela (o placar, a montagem).
var hud: CanvasItem = null

var _t := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(dt: float) -> void:
	_t += dt
	_limpar()
	visible = hud == null or hud.visible or vivos.any(func(c): return c.onde is Vector2)
	queue_redraw()


## O carimbo do julgamento na vaga 0 do lugar (500 ms). O erro (palavra "") não desenha.
func julgamento(l: int, _j: int, palavra: String) -> void:
	vivos = vivos.filter(func(c): return not (c.l == l and c.vaga == 0))
	if palavra == "" or l < 0 or l > 3:
		return
	vivos.append(_novo(l, "julgamento", palavra, 0, FICA_JULGAMENTO, Tema.T_CARIMBO, null))


## Um carimbo do jogo. `onde`: o cavaleiro do lugar (vaga 1), um Vector2 na tela (o placar, a montagem) ou nada
## (o acorde, no centro). Devolve false se a vez não deixou.
func bater(l: int, id: String, onde: Variant = null) -> bool:
	if not NO_VISOR.has(id) or not Opcoes.reacao_do_jogo():
		return false
	_limpar()
	var ordem := _ordem(id)
	var do_jogo := vivos.filter(func(c): return c.vaga == 1 and c.id != "fala")
	# o emburrado só existe sozinho
	if id == "car_emburrado" and not do_jogo.is_empty():
		return false
	# a vaga do dono: o novo substitui o vivo só se vem antes na ordem
	if l >= 0:
		var do_dono := do_jogo.filter(func(c): return c.l == l)
		if not do_dono.is_empty():
			if ordem >= _ordem(str(do_dono[0].id)):
				return false
			vivos.erase(do_dono[0])
			do_jogo.erase(do_dono[0])
	# dois na tela: o novo substitui o de ordem mais baixa, se vem antes dele
	if do_jogo.size() >= 2:
		var pior: Dictionary = do_jogo[0]
		for c in do_jogo:
			if _ordem(str(c.id)) > _ordem(str(pior.id)):
				pior = c
		if ordem >= _ordem(str(pior.id)):
			return false
		vivos.erase(pior)
	# a fala do dono cede a vaga
	vivos = vivos.filter(func(c): return not (c.l == l and c.id == "fala"))
	var batidas := 2.0 if id == "car_virada" else 4.0
	var fica := clampf(batidas * 60.0 / maxf(Ritmo.bpm, 1.0), 1.6, 2.8) if id != "car_virada" else batidas * 60.0 / maxf(Ritmo.bpm, 1.0)
	vivos.append(_novo(l, id, str(NO_VISOR[id]), 1, fica, int(LETRA.get(id, 46)), onde))
	# o som de cada carimbo, com o id escrito na chamada para o portão de som conferir no mapa
	match id:
		"car_virada": Som.tocar("jin_virada", null, -9.0)
		"car_em_chamas": Som.tocar("car_em_chamas", null, -9.0)
		"car_por_um_fio": Som.tocar("car_por_um_fio", null, -9.0)
		"car_liga": Som.tocar("car_liga", null, -9.0)
		"car_acorde": Som.tocar("car_acorde", null, -9.0)
	# 0,3/0,6/80: o «acerto» da tabela de sensações
	if id == "car_acorde":
		for k in 4:
			if Forja.ocupado(k):
				Forja.sentir(k, "acerto")
	elif l >= 0:
		Forja.sentir(l, "acerto")
	return true


## A fala na vaga 1, se ela está livre (com um carimbo do jogo vivo no lugar, a fala não aparece).
func fala(l: int, texto: String, segundos: float) -> bool:
	if l < 0 or l > 3 or texto == "":
		return false
	_limpar()
	if vivos.any(func(c): return c.l == l and c.vaga == 1 and c.id != "fala"):
		return false
	vivos = vivos.filter(func(c): return not (c.l == l and c.id == "fala"))
	vivos.append(_novo(l, "fala", texto, 1, maxf(segundos, 0.1), 34, null))
	return true


## Onde o adesivo de 112 px se cola (só a conta; o desenho é de outra ficha): metade para fora do cartão, na borda
## de dentro em y, perto do canto de dentro em x.
func ancora_do_adesivo(l: int) -> Vector2:
	var r := HudJogo.cartao(l, size)
	var y := r.end.y if l < 2 else r.position.y
	var x := r.end.x - 56.0 if l % 2 == 0 else r.position.x + 56.0
	return Vector2(x, y)


## Os carimbos e a fala vivos do lugar (a prova lê).
func do_lugar(l: int) -> Array:
	return vivos.filter(func(c): return c.l == l)


func _novo(l: int, id: String, palavra: String, vaga: int, fica: float, tam: int, onde: Variant) -> Dictionary:
	var respingos: Array = []
	for i in _rng.randi_range(4, 6):
		var lado := float(_rng.randi_range(4, 10))
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(0.2, 0.6) * tam
		respingos.append(Rect2(Vector2(cos(a), sin(a)) * d - Vector2(lado, lado) * 0.5, Vector2(lado, lado)))
	return {"l": l, "id": id, "palavra": palavra, "vaga": vaga, "t": _t, "fica": fica, "tam": tam, "onde": onde,
		"respingos": respingos}


func _ordem(id: String) -> int:
	var k := ORDEM.find(id)
	return k if k >= 0 else ORDEM.size()


func _vida(c: Dictionary) -> float:
	return BATE + float(c.fica) + SOME


func _limpar() -> void:
	vivos = vivos.filter(func(c): return _t - float(c.t) <= _vida(c))


## O ponto do carimbo do lugar na tela: 1,75 m acima dos pés, 20 px acima. null se o cavaleiro não está à vista.
func _ponto(l: int) -> Variant:
	var cam := get_viewport().get_camera_3d()
	if cam == null or l < 0 or l >= jogadores.size():
		return null
	var p = jogadores[l]
	if p == null or not is_instance_valid(p) or not p.visible:
		return null
	var mundo: Vector3 = p.global_position + Vector3(0, 1.75, 0)
	if cam.is_position_behind(mundo):
		return null
	return cam.unproject_position(mundo) + Vector2(0, -20)


func _draw() -> void:
	var reduzido := Opcoes.movimento == 1
	for c in vivos:
		var centro: Vector2
		if c.onde is Vector2:
			centro = c.onde
		elif c.id == "car_acorde":
			centro = Vector2(size.x * 0.5, 300.0)
		else:
			var pt = _ponto(int(c.l))
			if pt == null:
				continue
			centro = pt
			if int(c.vaga) == 1:
				centro -= Vector2(0, 72)
			if c.id != "fala":
				centro = na_area_segura(centro, str(c.palavra), int(c.tam), size)
		var idade := _t - float(c.t)
		var vida := _vida(c)
		var alfa := 1.0
		var escala := 1.0
		var graus := GRAUS
		if reduzido:
			graus = 0.0
			alfa = clampf(idade / QUATRO_QUADROS, 0.0, 1.0) * clampf((vida - idade) / QUATRO_QUADROS, 0.0, 1.0)
		else:
			if idade < BATE:
				escala = lerpf(1.35, 1.0, _mola(idade / BATE))
			if idade > BATE + float(c.fica):
				alfa = clampf(1.0 - (idade - BATE - float(c.fica)) / SOME, 0.0, 1.0)
		if c.id == "fala":
			_fala(int(c.l), centro, str(c.palavra), alfa)
			continue
		var cor: Color = Tema.ETIQUETA if c.id == "car_acorde" or int(c.l) < 0 else Tema.JOGADOR[int(c.l)]
		if not reduzido and idade < ESPIRRA:
			for r in c.respingos:
				draw_rect(Rect2(centro + (r as Rect2).position, (r as Rect2).size), Color(cor, alfa))
		Desenho.carimbo(self, centro, str(c.palavra), cor, int(c.tam), graus, escala, alfa)
		if c.id == "car_acorde":
			_tarjas_do_acorde(centro + Vector2(0, Tema.t(int(c.tam)) * 0.5 + 24.0), alfa)


## Embaixo do «ACORDE MAIOR!», uma tarja por lugar, com o P# no papel.
func _tarjas_do_acorde(topo: Vector2, alfa: float) -> void:
	var larg := 80.0
	var vao := 16.0
	var x0 := topo.x - (4 * larg + 3 * vao) * 0.5
	var f := Tema.bungee()
	for k in 4:
		var r := Rect2(Vector2(x0 + k * (larg + vao), topo.y), Vector2(larg, 12))
		var papel := Rect2(r.position + Vector2(0, 12), Vector2(larg, 44))
		draw_rect(papel, Color(Tema.ETIQUETA, alfa))
		draw_rect(r, Color(Tema.JOGADOR[k], alfa))
		Desenho.texto(self, Vector2(papel.position.x, papel.position.y + 34), "P%d" % (k + 1), f, 30, Color(Tema.TINTA, alfa),
			HORIZONTAL_ALIGNMENT_CENTER, larg)


## A fala: uma etiqueta pequena na cor do dono, o texto em até 2 linhas.
func _fala(l: int, centro: Vector2, texto: String, alfa: float) -> void:
	var f := Tema.archivo(600)
	var cabe := LARG_FALA - 48.0
	var dito := Desenho.caber(texto, f, 34, cabe, 2)
	var larg := minf(Desenho.largura(dito, f, 34), cabe) + 48.0
	var alto := Desenho.altura_paragrafo(dito, f, 34, cabe, 2) + 48.0 + 12.0
	var r := Rect2(centro - Vector2(larg * 0.5, alto), Vector2(larg, alto))
	r.position += _empurrao(r, size)
	if alfa < 0.5:
		return  # o papel não tem alfa: a fala sai inteira na metade do sumiço
	Desenho.etiqueta(self, r, Tema.JOGADOR[l])
	Desenho.paragrafo(self, r.position + Vector2(24, 24 + 12 + f.get_ascent(Tema.t(34))), dito, f, 34, Tema.TINTA, cabe + 1.0, 2)


## O centro do carimbo que segue o cavaleiro, empurrado para dentro da área segura: o cavaleiro na borda
## da tela não leva a palavra para fora dela. A caixa cresce a sombra e a folga do giro de 4 graus.
static func na_area_segura(centro: Vector2, palavra: String, tam: int, tela: Vector2) -> Vector2:
	var caixa := Desenho.caixa_do_carimbo(centro, palavra, tam).grow(float(maxi(3, roundi(0.08 * tam))) + 12.0)
	return centro + _empurrao(caixa, tela)


## O quanto a caixa anda para caber na área segura da tela (zero se já cabe).
static func _empurrao(caixa: Rect2, tela: Vector2) -> Vector2:
	var seguro := Rect2(tela * Tema.AREA_SEGURA, tela * (1.0 - 2.0 * Tema.AREA_SEGURA))
	var dx := maxf(0.0, seguro.position.x - caixa.position.x) - maxf(0.0, caixa.end.x - seguro.end.x)
	var dy := maxf(0.0, seguro.position.y - caixa.position.y) - maxf(0.0, caixa.end.y - seguro.end.y)
	return Vector2(dx, dy)


## A curva MOLA (arte/05): passa um pouco e volta.
static func _mola(k: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	var x := k - 1.0
	return 1.0 + c3 * x * x * x + c1 * x * x
