class_name Visor
extends Control

const ORDEM := ["car_acorde", "car_virada", "car_em_chamas", "car_por_um_fio", "car_liga"]
const NO_VISOR := {"car_virada": "VIRADA!", "car_em_chamas": "EM CHAMAS", "car_por_um_fio": "POR UM FIO",
	"car_liga": "LIGA!", "car_acorde": "ACORDE MAIOR!", "car_emburrado": ""}
const LETRA := {"car_virada": 64, "car_em_chamas": 46, "car_por_um_fio": 64, "car_liga": 46, "car_acorde": 112}
const SOM := {"car_virada": "jin_virada", "car_em_chamas": "car_em_chamas", "car_por_um_fio": "car_por_um_fio",
	"car_liga": "car_liga", "car_acorde": "car_acorde"}
const BATE := 0.08
const SOME := 0.17
const FICA_JULGAMENTO := 0.25
const ESPIRRA := 6.0 / 60.0
const GRAUS := -4.0
const QUATRO_QUADROS := 4.0 / 60.0
const LARG_FALA := 420.0

var jogadores: Array = []
var vivos: Array = []
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


func julgamento(l: int, _j: int, palavra: String) -> void:
	vivos = vivos.filter(func(c): return not (c.l == l and c.vaga == 0))
	if palavra == "" or l < 0 or l > 3:
		return
	vivos.append(_novo(l, "julgamento", palavra, 0, FICA_JULGAMENTO, Tema.T_CARIMBO, null))


func bater(l: int, id: String, onde: Variant = null) -> bool:
	if not NO_VISOR.has(id) or not Opcoes.reacao_do_jogo():
		return false
	_limpar()
	var ordem := _ordem(id)
	var do_jogo := vivos.filter(func(c): return c.vaga == 1 and c.id != "fala")
	if id == "car_emburrado" and not do_jogo.is_empty():
		return false
	if l >= 0:
		var do_dono := do_jogo.filter(func(c): return c.l == l)
		if not do_dono.is_empty():
			if ordem >= _ordem(str(do_dono[0].id)):
				return false
			vivos.erase(do_dono[0])
			do_jogo.erase(do_dono[0])
	if do_jogo.size() >= 2:
		var pior: Dictionary = do_jogo[0]
		for c in do_jogo:
			if _ordem(str(c.id)) > _ordem(str(pior.id)):
				pior = c
		if ordem >= _ordem(str(pior.id)):
			return false
		vivos.erase(pior)
	vivos = vivos.filter(func(c): return not (c.l == l and c.id == "fala"))
	var batidas := 2.0 if id == "car_virada" else 4.0
	var fica := clampf(batidas * 60.0 / maxf(Ritmo.bpm, 1.0), 1.6, 2.8) if id != "car_virada" else batidas * 60.0 / maxf(Ritmo.bpm, 1.0)
	vivos.append(_novo(l, id, str(NO_VISOR[id]), 1, fica, int(LETRA.get(id, 46)), onde))
	if SOM.has(id):
		Som.tocar(SOM[id], null, -9.0)
	if id == "car_acorde":
		for k in 4:
			if Forja.ocupado(k):
				Forja.sentir(k, "acerto")
	elif l >= 0:
		Forja.sentir(l, "acerto")
	return true


func fala(l: int, texto: String, segundos: float) -> bool:
	if l < 0 or l > 3 or texto == "":
		return false
	_limpar()
	if vivos.any(func(c): return c.l == l and c.vaga == 1 and c.id != "fala"):
		return false
	vivos = vivos.filter(func(c): return not (c.l == l and c.id == "fala"))
	vivos.append(_novo(l, "fala", texto, 1, maxf(segundos, 0.1), 34, null))
	return true


func ancora_do_adesivo(l: int) -> Vector2:
	var r := HudJogo.cartao(l, size)
	var y := r.end.y if l < 2 else r.position.y
	var x := r.end.x - 56.0 if l % 2 == 0 else r.position.x + 56.0
	return Vector2(x, y)


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


func _fala(l: int, centro: Vector2, texto: String, alfa: float) -> void:
	var f := Tema.archivo(600)
	var cabe := LARG_FALA - 48.0
	var dito := Desenho.caber(texto, f, 34, cabe, 2)
	var larg := minf(Desenho.largura(dito, f, 34), cabe) + 48.0
	var alto := Desenho.altura_paragrafo(dito, f, 34, cabe, 2) + 48.0 + 12.0
	var r := Rect2(centro - Vector2(larg * 0.5, alto), Vector2(larg, alto))
	r.position += _empurrao(r, size)
	if alfa < 0.5:
		return
	Desenho.etiqueta(self, r, Tema.JOGADOR[l])
	Desenho.paragrafo(self, r.position + Vector2(24, 24 + 12 + f.get_ascent(Tema.t(34))), dito, f, 34, Tema.TINTA, cabe + 1.0, 2)


static func na_area_segura(centro: Vector2, palavra: String, tam: int, tela: Vector2) -> Vector2:
	var caixa := Desenho.caixa_do_carimbo(centro, palavra, tam).grow(float(maxi(3, roundi(0.08 * tam))) + 12.0)
	return centro + _empurrao(caixa, tela)


static func _empurrao(caixa: Rect2, tela: Vector2) -> Vector2:
	var seguro := Rect2(tela * Tema.AREA_SEGURA, tela * (1.0 - 2.0 * Tema.AREA_SEGURA))
	var dx := maxf(0.0, seguro.position.x - caixa.position.x) - maxf(0.0, caixa.end.x - seguro.end.x)
	var dy := maxf(0.0, seguro.position.y - caixa.position.y) - maxf(0.0, caixa.end.y - seguro.end.y)
	return Vector2(dx, dy)


static func _mola(k: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	var x := k - 1.0
	return 1.0 + c3 * x * x * x + c1 * x * x
