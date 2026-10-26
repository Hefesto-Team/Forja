class_name HudJogo
extends Control

var vencidas := -1
var dica_presa := {}
var camera: Camera3D
var nomes := ["", "", "", ""]
var sala := {}
var status_da_sala := ["", "", "", ""]
var create_livre := true

var _avisos: Array = []
var _rets: Array[Rect2] = []

const LARG_CHIP := 340.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Forja.aviso.connect(mostrar_aviso)


func mostrar_aviso(texto: String) -> void:
	if texto == "":
		return
	_avisos.append([texto, 3.5])
	if _avisos.size() > 3:
		_avisos.pop_front()


func _process(dt: float) -> void:
	for a in _avisos:
		a[1] -= dt
	_avisos = _avisos.filter(func(a): return a[1] > 0.0)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	for i in 20:
		draw_rect(Rect2(0, i * 7, w, 7), Color(Tema.FITA, 0.55 * (1.0 - i / 20.0)))

	if sala.is_empty():
		var lado := 60.0
		var tam_c := maxi(int(lado * 0.36), Tema.LETRA_MINIMA)
		var larg_c := lado + 18.0 + maxf(Desenho.largura("Hefesto", Tema.bungee(), tam_c), Desenho.largura("Tech Demo", Tema.archivo(700), tam_c))
		Desenho.moldura(self, Rect2(Vector2(Tema.MARGEM_X - 20.0, Tema.MARGEM_Y - 16.0), Vector2(larg_c + 40.0, lado + 32.0)),
			Color(Tema.CASCO, 0.9), Tema.GRAFITE, 2, 12)
		Desenho.cabecalho(self, Vector2(Tema.MARGEM_X, Tema.MARGEM_Y), lado)
	else:
		var qd := quadro_da_sala(str(sala.get("nome", "")), str(sala.get("acao", "")), w)
		var q: Rect2 = qd["rect"]
		Desenho.moldura(self, q, Color(Tema.CASCO, 0.94), Tema.GRAFITE, 2, Tema.RAIO_QUADRO)
		Desenho.texto(self, q.position + Vector2(28, 56), qd["nome"], Tema.archivo(700), Tema.T_SUBTITULO, Tema.ETIQUETA)
		Desenho.paragrafo(self, q.position + Vector2(28, 96), qd["acao"], Tema.archivo(500), Tema.T_ROTULO, Tema.ETIQUETA,
			q.size.x - 56.0 + 1.0, LINHAS_DA_ACAO)

	_lugares(Vector2(w - Tema.MARGEM_X, 40))

	_rets.clear()
	if vencidas >= 0:
		_salao(w, h)

	var pares := [["create", "Diagnóstico"], ["options", "Pausa"]] if create_livre and Forja.bancada else [["options", "Pausa"]]
	Desenho.dicas_a_direita(self, Vector2(w - Tema.MARGEM_X, h - Tema.MARGEM_Y), pares, Tema.T_SELO, not sala.is_empty())

	var y := 190.0
	for a in _avisos:
		var alfa := clampf(a[1] / 0.4, 0.0, 1.0)
		var f := Tema.archivo(500)
		var larg_max := 1100.0
		var s := Desenho.caber(a[0], f, Tema.T_AVISO, larg_max, 2)
		var tw := minf(Desenho.largura(s, f, Tema.T_AVISO), larg_max)
		var th := Desenho.altura_paragrafo(s, f, Tema.T_AVISO, larg_max)
		var r2 := Rect2(Vector2((w - tw) * 0.5 - 32, y), Vector2(tw + 64, th + 28))
		Desenho.moldura(self, r2, Color(Tema.CASCO_ALTO, 0.95 * alfa), Color(Tema.GRAFITE, alfa), 2, 12)
		Desenho.paragrafo(self, Vector2(r2.position.x + 32, y + 14 + f.get_ascent(Tema.t(Tema.T_AVISO))), s, f,
			Tema.T_AVISO, Color(Tema.ETIQUETA, alfa), larg_max + 1.0, 2)
		y += r2.size.y + 12.0


func _salao(w: float, h: float) -> void:
	var topo := 40.0 + 92.0 + 16.0
	var c := Desenho.contador(self, Vector2(w - Tema.MARGEM_X - 121.0, topo), "%d/9" % vencidas, 64)
	_rets.append(c)
	var f := Tema.archivo(500)
	var rotulo := Desenho.t("Salas vencidas")
	var lw := Desenho.largura(rotulo, f, 32)
	Desenho.texto(self, Vector2(c.position.x - 20.0 - lw, c.position.y + 48.0), rotulo, f, 32, Tema.ETIQUETA)
	_rets.append(Rect2(Vector2(c.position.x - 20.0 - lw, c.position.y + 16.0), Vector2(lw, 40)))
	var y := h - Tema.MARGEM_Y - 64.0 - 70.0
	var x0 := (w - (4 * 400.0 + 3 * 16.0)) * 0.5
	for l in 4:
		if not Forja.ocupado(l):
			continue
		var r := Rect2(Vector2(x0 + l * 416.0, y), Vector2(400, 64))
		var info: Dictionary = Forja.lugar(l)
		var com_controle: bool = info.get("conectado", false)
		Desenho.chip(self, r, l, com_controle, str(nomes[l]) if com_controle else Desenho.t("Sem controle"))
		_rets.append(r)
	_dica_presa(w, h)


func _dica_presa(w: float, h: float) -> void:
	if dica_presa.is_empty() or camera == null:
		return
	var l := int(dica_presa.get("lugar", -1))
	var linhas: Array = dica_presa.get("linhas", [])
	if l < 0 or l > 3 or linhas.is_empty():
		return
	var cabeca: Vector3 = dica_presa.get("cabeca", Vector3.ZERO)
	var c := camera.unproject_position(cabeca)
	var mais := 0.0
	for ln in linhas:
		mais = maxf(mais, Glifo.largura_dica(str(ln[0]), str(ln[1]), Tema.T_CORPO))
	var larg := 24.0 + mais + 24.0
	var alt := 34.0 + 62.0 * linhas.size() + 10.0
	var x := c.x + 60.0
	var lado_direito := true
	if x + larg > w - Tema.MARGEM_X:
		x = c.x - 60.0 - larg
		lado_direito = false
	var y := clampf(c.y - 60.0, Tema.MARGEM_Y, h - Tema.MARGEM_Y - alt)
	var r := Rect2(Vector2(x, y), Vector2(larg, alt))
	var fechado: bool = dica_presa.get("fechado", false)
	var tarja: Color = Tema.ETIQUETA_SOMBRA if fechado else Tema.JOGADOR[l]
	draw_rect(Rect2(r.position + Vector2(4, 4), r.size), Tema.SOMBRA)
	draw_rect(r, Tema.ETIQUETA)
	draw_rect(Rect2(r.position + Vector2(0, 14), Vector2(r.size.x, 12)), tarja)
	var py := r.position.y + 40.0
	if lado_direito:
		draw_colored_polygon(PackedVector2Array([Vector2(r.position.x, py), Vector2(r.position.x - 16, py + 16), Vector2(r.position.x, py + 32)]), Tema.ETIQUETA)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(r.end.x, py), Vector2(r.end.x + 16, py + 16), Vector2(r.end.x, py + 32)]), Tema.ETIQUETA)
	for i in linhas.size():
		Glifo.dica(self, r.position + Vector2(24, 34 + 62.0 * i + 44.0), str(linhas[i][0]), str(linhas[i][1]), Tema.T_CORPO, Tema.TINTA, Tema.TINTA)
	_rets.append(r)


func retangulos() -> Array[Rect2]:
	return _rets


const LINHAS_DA_ACAO := 3


static func quadro_da_sala(nome: String, acao: String, w: float) -> Dictionary:
	var x := float(Tema.MARGEM_X - 28)
	var x_chips := w - Tema.MARGEM_X - (LARG_CHIP * 4 + 16.0 * 3)
	var larg := x_chips - 24.0 - x
	var fn := Tema.archivo(700)
	var fa := Tema.archivo(500)
	var dito_nome := Desenho.caber(nome, fn, Tema.T_SUBTITULO, larg - 56.0, 1)
	var dita_acao := Desenho.caber(acao, fa, Tema.T_ROTULO, larg - 56.0, LINHAS_DA_ACAO)
	var uma := fa.get_height(Tema.t(Tema.T_ROTULO))
	var extra := maxf(0.0, Desenho.altura_paragrafo(dita_acao, fa, Tema.T_ROTULO, larg - 56.0, LINHAS_DA_ACAO) - uma)
	return {"rect": Rect2(Vector2(x, 40), Vector2(larg, 118.0 + ceilf(extra))), "nome": dito_nome, "acao": dita_acao}


static func linha_do_status(linha: String) -> String:
	return Desenho.caber(linha, Tema.archivo(500), Tema.T_SELO, LARG_CHIP - 40.0, 1)


func _lugares(fim: Vector2) -> void:
	var larg := LARG_CHIP
	var alt := 92.0
	var x := fim.x - (larg * 4 + 16 * 3)
	for l in 4:
		var r := Rect2(Vector2(x + l * (larg + 16), fim.y), Vector2(larg, alt))
		var info: Dictionary = Forja.lugar(l)
		var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
		if not info.get("ocupado", false):
			Desenho.moldura(self, r, Color(Tema.CASCO, 0.7), Tema.GRAFITE, 2, 12)
			Desenho.texto(self, r.position + Vector2(20, 40), "P%d  ·  —" % (l + 1), Tema.archivo(600), Tema.T_SELO, Tema.MUDO)
			continue
		var conectado: bool = info.get("conectado", false)
		Desenho.moldura(self, r, Color(Tema.CASCO, 0.9), cor_id if conectado else Tema.SECAO[3], 3, 12)
		Desenho.texto(self, r.position + Vector2(20, 44), "P%d" % (l + 1), Tema.bungee(), Tema.T_PSHARP, cor_id)
		if not conectado:
			Desenho.texto(self, r.position + Vector2(92, 40), "Sem controle", Tema.archivo(600), Tema.T_SELO, Tema.SECAO[3])
			continue
		var p: Dictionary = Forja.pad(int(info.get("pad", -1)))
		Desenho.texto(self, r.position + Vector2(92, 40), str(p.get("conexao_curta", "")), Tema.archivo(600), Tema.T_SELO, Tema.ETIQUETA)
		var pct: int = p.get("bateria", -1)
		if pct >= 0:
			var s := "%d%%" % pct
			var fm := Tema.vt()
			Desenho.texto(self, Vector2(r.end.x - 20 - Desenho.largura(s, fm, Tema.T_SELO), r.position.y + 40), s, fm, Tema.T_SELO, Tema.ETIQUETA)
		var linha: String = status_da_sala[l]
		if linha != "":
			Desenho.texto(self, r.position + Vector2(20, 76), linha_do_status(linha), Tema.archivo(500), Tema.T_SELO,
				Tema.ETIQUETA_SOMBRA, HORIZONTAL_ALIGNMENT_LEFT, larg - 40)
		else:
			Desenho.leds(self, r.position + Vector2(20, 60), int(info.get("leds", 0)), 10.0)
