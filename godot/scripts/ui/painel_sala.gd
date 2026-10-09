class_name PainelSala
extends Control

var sala: Node = null
var escondido := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(_dt: float) -> void:
	visible = not escondido and sala != null and is_instance_valid(sala) and sala is SalaJogo
	if visible:
		queue_redraw()


func _draw() -> void:
	if sala == null or not is_instance_valid(sala) or not sala is SalaJogo:
		return
	match str(sala.fase):
		"aviso":
			_aviso()
		"jogo":
			_tempo()


func _aviso() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.FITA, 0.25))
	var larg := 1120.0
	var poucos := str(sala.com_poucos())
	var papel: int = sala.papel_som
	var som := papel >= 0 and Forja.bancada
	var alt := 368.0 + (40.0 if poucos != "" else 0.0) + (ALTURA_SOM if som else 0.0)
	var r := Rect2(Vector2((size.x - larg) * 0.5, 176), Vector2(larg, alt))
	var k := clampf(float(sala.t_fase) / 0.35, 0.0, 1.0)
	r.position.x += (1.0 - k * k * (3.0 - 2.0 * k)) * 520.0
	Desenho.moldura(self, r, Color(Tema.CASCO, 0.97), Tema.GRAFITE, 2, Tema.RAIO_QUADRO)
	var x := r.position.x + 48
	Desenho.texto(self, Vector2(x, r.position.y + 92), str(sala.nome), Tema.bungee(), Tema.T_TITULO, Tema.ETIQUETA)
	if str(sala.na_prova_de_fogo) != "":
		Desenho.texto(self, Vector2(x + Desenho.largura(str(sala.nome), Tema.bungee(), Tema.T_TITULO) + 28, r.position.y + 88),
			str(sala.na_prova_de_fogo), Tema.archivo(600), Tema.T_SELO, Tema.SECAO[3])
	Desenho.texto(self, Vector2(x, r.position.y + 156), str(sala.acao), Tema.archivo(500), Tema.T_SUBTITULO, Tema.ETIQUETA,
		HORIZONTAL_ALIGNMENT_LEFT, larg - 96)
	if poucos != "":
		Desenho.selo(self, Vector2(x, r.position.y + 180), poucos, Tema.ETIQUETA, Tema.T_SELO)
	var icone := Desenho.glifo(str(sala.icone))
	if icone:
		draw_texture_rect(icone, Rect2(Vector2(r.end.x - 48 - 96, r.position.y + 40), Vector2(96, 96)), false, Tema.ETIQUETA)
	var y := r.position.y + 216 + (40.0 if poucos != "" else 0.0)
	var cx := x
	for l in 4:
		if not Forja.ocupado(l):
			continue
		var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
		var pronto: bool = sala.prontos[l]
		var chip := Rect2(Vector2(cx, y), Vector2(250, 64.0 + (ALTURA_SOM if som else 0.0)))
		Desenho.moldura(self, chip, Tema.CASCO_ALTO if pronto else Tema.CASCO, cor_id, 3, 12)
		Desenho.texto(self, chip.position + Vector2(20, 42), "P%d" % (l + 1), Tema.bungee(), Tema.T_PSHARP, cor_id)
		if pronto:
			Desenho.texto(self, chip.position + Vector2(86, 42), "✓ Pronto", Tema.archivo(600), Tema.T_SELO, cor_id, HORIZONTAL_ALIGNMENT_LEFT, 150)
		else:
			Desenho.texto(self, chip.position + Vector2(86, 42), Desenho.caber("Aguardando", Tema.archivo(500), Tema.T_SELO, 150.0, 1),
				Tema.archivo(500), Tema.T_SELO, Tema.MUDO, HORIZONTAL_ALIGNMENT_LEFT, 150)
		if som:
			_som_do_lugar(chip, l, papel)
		cx += 258
	var trilho := Rect2(Vector2(x, y + 64.0 + (ALTURA_SOM if som else 0.0) + 16.0), Vector2(larg - 96.0, 8.0))
	draw_rect(trilho, Tema.GRAFITE)
	var resta := 1.0 - clampf(float(sala.t_fase) / SalaJogo.AVISO_MAX, 0.0, 1.0)
	draw_rect(Rect2(trilho.position, Vector2(trilho.size.x * resta, 8.0)), Tema.ETIQUETA)
	var dicas := [["cruz", "Pronto"]]
	if som:
		dicas = [["esquerda", "Trocar"], ["triangulo", "Testar"], ["cruz", "Pronto"]]
		if papel == Forja.PAPEL_MICROFONE:
			dicas = [["esquerda", "Trocar"], ["cruz", "Pronto"]]
	Desenho.dicas_a_direita(self, Vector2(r.end.x - 48, trilho.position.y + 52), dicas, Tema.T_ROTULO)


const ALTURA_SOM := 190.0


func _som_do_lugar(chip: Rect2, l: int, papel: int) -> void:
	var x := chip.position.x + 20.0
	var w := chip.size.x - 40.0
	var tem := Forja.som_tem(l, papel)
	var nome := Forja.som_nome(l, papel)
	var f := Tema.archivo(500)
	var f2 := Tema.archivo(500)
	var tam := Tema.T_SELO
	var nome_cabe := Desenho.caber(nome, f, tam, w, 3)
	var topo := chip.position.y + 64.0 + 8.0
	var alt_nome := Desenho.paragrafo(self, Vector2(x, topo + f.get_ascent(Tema.t(tam))), nome_cabe, f, tam,
		Tema.ETIQUETA if tem else Tema.SECAO[3], w, 3)
	var como := Forja.som_como(l, papel) if tem else "Não achado"
	var y_como := topo + alt_nome + f2.get_ascent(Tema.t(tam))
	Desenho.texto(self, Vector2(x, y_como), Desenho.caber(como, f2, tam, w, 1), f2, tam, Tema.MUDO)
	if papel == Forja.PAPEL_MICROFONE and tem:
		var nivel := float(Forja.som_mic(l).get("nivel", 0.0))
		var trilho := Rect2(Vector2(x, y_como + 14.0), Vector2(w, 8))
		draw_rect(trilho, Tema.GRAFITE)
		draw_rect(Rect2(trilho.position, Vector2(w * clampf(nivel, 0.0, 1.0), 8)), Tema.ETIQUETA)


func _dicas() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var f := Tema.archivo(500)
	var tam := Tema.T_SELO
	if Forja.bancada:
		var perguntas: Array = []
		for l in 4:
			if not Forja.ocupado(l):
				continue
			var q: Dictionary = sala.pergunta(l)
			if not q.is_empty():
				perguntas.append([l, q, _rect_pergunta(cam, q)])
		_afastar(perguntas, FOLGA_PERGUNTA)
		for item in perguntas:
			_pergunta(item[0], item[1], item[2])
	var pilulas: Array = []
	for l in 4:
		if not Forja.ocupado(l) or not sala.pergunta(l).is_empty():
			continue
		var d: Dictionary = sala.dica(l)
		if d.is_empty() or not d.has("pos"):
			continue
		var partes: Array = d.get("partes", [])
		if sala.aprendeu(l):
			partes = partes.filter(func(s): return str(s).begins_with("@"))
			if partes.is_empty():
				continue
		var larg := 0.0
		for parte in partes:
			var s := str(parte)
			larg += (34.0 if s.begins_with("@") else Desenho.largura(s, f, tam)) + 10.0
		larg += 36.0 - 10.0
		var centro := cam.unproject_position(d.pos)
		var r := Rect2(Vector2(centro.x - larg * 0.5, centro.y - 26.0), Vector2(larg, 52.0))
		r.position.x = clampf(r.position.x, Tema.MARGEM_X - FOLGA_PILULA, size.x - Tema.MARGEM_X + FOLGA_PILULA - larg)
		r.position.y = clampf(r.position.y, 12.0, size.y - 140.0)
		pilulas.append([l, partes, r])
	_afastar(pilulas, FOLGA_PILULA)
	var valendo := _rect_valendo()
	if valendo.size.x > 0.0:
		pilulas = pilulas.filter(func(it): return not (it[2] as Rect2).intersects(valendo))
	for item in pilulas:
		var l: int = item[0]
		var partes: Array = item[1]
		var r: Rect2 = item[2]
		var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
		Desenho.moldura(self, r, Color(Tema.CASCO, 0.92), cor_id, 2, 12)
		var x := r.position.x + 18.0
		for parte in partes:
			var s := str(parte)
			if s.begins_with("@"):
				var tex := Desenho.glifo(s.substr(1))
				if tex:
					draw_texture_rect(tex, Rect2(Vector2(x, r.position.y + 9.0), Vector2(34, 34)), false, Tema.ETIQUETA)
				x += 34.0 + 10.0
			else:
				Desenho.texto(self, Vector2(x, r.position.y + 34.0), s, f, tam, Tema.ETIQUETA)
				x += Desenho.largura(s, f, tam) + 10.0


const FOLGA_PILULA := 18.0
const FOLGA_PERGUNTA := 20.0
const LARG_PERGUNTA := 400.0
const T_PERGUNTA := Tema.T_SELO
const LINHA_RESPOSTA := 52.0


func _alturas(q: Dictionary) -> Array:
	var ft := Tema.archivo(600)
	var fo := Tema.archivo(500)
	var titulo := str(q.get("titulo", ""))
	var rodape := str(q.get("rodape", ""))
	var th := Desenho.altura_paragrafo(Desenho.caber(titulo, ft, T_PERGUNTA, LARG_PERGUNTA - 40, 2), ft, T_PERGUNTA, LARG_PERGUNTA - 40, 2)
	var rh := 0.0
	if rodape != "":
		rh = Desenho.altura_paragrafo(Desenho.caber(rodape, fo, T_PERGUNTA, LARG_PERGUNTA - 40, 2), fo, T_PERGUNTA, LARG_PERGUNTA - 40, 2)
	return [th, rh]


func _rect_pergunta(cam: Camera3D, q: Dictionary) -> Rect2:
	var larg := LARG_PERGUNTA
	var n := Array(q.get("opcoes", [])).size()
	var h := _alturas(q)
	var alt := 16.0 + float(h[0]) + 10.0 + LINHA_RESPOSTA * n + (float(h[1]) + 14.0 if float(h[1]) > 0.0 else 10.0)
	var centro := cam.unproject_position(q.get("pos", Vector3.ZERO))
	var r := Rect2(Vector2(centro.x - larg * 0.5, centro.y - alt * 0.5), Vector2(larg, alt))
	r.position.x = clampf(r.position.x, Tema.MARGEM_X - FOLGA_PERGUNTA, size.x - Tema.MARGEM_X + FOLGA_PERGUNTA - larg)
	r.position.y = clampf(r.position.y, 230.0, size.y - alt - 90.0)
	return r


func _afastar(itens: Array, folga: float) -> void:
	var vao := 10.0
	var esq := Tema.MARGEM_X - folga
	var dir := size.x - Tema.MARGEM_X + folga
	itens.sort_custom(func(p, q): return (p[2] as Rect2).position.x < (q[2] as Rect2).position.x)
	for i in range(1, itens.size()):
		var a: Rect2 = itens[i - 1][2]
		var b: Rect2 = itens[i][2]
		if b.position.x < a.end.x + vao and _mesma_faixa(a, b):
			b.position.x = a.end.x + vao
			itens[i][2] = b
	for i in range(itens.size() - 1, -1, -1):
		var b: Rect2 = itens[i][2]
		var limite := dir
		if i < itens.size() - 1 and _mesma_faixa(b, itens[i + 1][2]):
			limite = (itens[i + 1][2] as Rect2).position.x - vao
		if b.end.x > limite:
			b.position.x = limite - b.size.x
		b.position.x = maxf(b.position.x, esq)
		itens[i][2] = b


func _mesma_faixa(a: Rect2, b: Rect2) -> bool:
	return a.position.y < b.end.y and b.position.y < a.end.y


func _pergunta(l: int, q: Dictionary, r: Rect2) -> void:
	var larg := LARG_PERGUNTA
	var opcoes: Array = q.get("opcoes", [])
	var rodape := str(q.get("rodape", ""))
	var ft := Tema.archivo(600)
	var fo := Tema.archivo(500)
	var h := _alturas(q)
	var titulo := Desenho.caber(str(q.get("titulo", "")), ft, T_PERGUNTA, larg - 40, 2)
	var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
	Desenho.moldura(self, r, Color(Tema.CASCO, 0.95), cor_id, 2, 14)
	Desenho.paragrafo(self, r.position + Vector2(20, 16 + ft.get_ascent(Tema.t(T_PERGUNTA))), titulo, ft, T_PERGUNTA,
		Tema.ETIQUETA, larg - 40, 2)
	var escolhida := int(q.get("escolhida", -1))
	var certa := int(q.get("certa", -1))
	var y0 := r.position.y + 16.0 + float(h[0]) + 10.0
	for i in opcoes.size():
		var o: Array = opcoes[i]
		var caixa := Rect2(Vector2(r.position.x + 20.0, y0 + i * LINHA_RESPOSTA), Vector2(larg - 40.0, LINHA_RESPOSTA - 6.0))
		var borda := Tema.GRAFITE
		var fundo := Color(Tema.CASCO, 0.9)
		if i == escolhida:
			fundo = Tema.CASCO_ALTO
		if certa >= 0 and i == certa:
			borda = cor_id
		elif certa >= 0 and i == escolhida:
			borda = Tema.MUDO
		Desenho.moldura(self, caixa, fundo, borda, 2 if borda == Tema.GRAFITE else 3, 10)
		var meio := caixa.position.y + caixa.size.y * 0.5
		var tex := Desenho.glifo(str(o[0]))
		if tex:
			draw_texture_rect(tex, Rect2(Vector2(caixa.position.x + 10, meio - 16), Vector2(32, 32)), false, Tema.ETIQUETA)
		var tx := caixa.position.x + 54.0
		if o.size() > 1 and o[1] is Color:
			draw_circle(Vector2(tx + 12.0, meio), 12.0, o[1])
			draw_arc(Vector2(tx + 12.0, meio), 12.0, 0.0, TAU, 24, Tema.GRAFITE, 1.5)
			tx += 34.0
		var palavra := str(o[o.size() - 1])
		var cabe := caixa.end.x - tx - 10.0
		var tam := T_PERGUNTA
		Desenho.texto(self, Vector2(tx, meio + fo.get_ascent(Tema.t(tam)) * 0.36 + 2.0), Desenho.caber(palavra, fo, tam, cabe, 1), fo, tam, Tema.ETIQUETA,
			HORIZONTAL_ALIGNMENT_LEFT, cabe + 2.0)
	if rodape != "":
		var bom := certa >= 0 and escolhida == certa
		var ry := y0 + opcoes.size() * LINHA_RESPOSTA + 4.0
		Desenho.paragrafo(self, Vector2(r.position.x + 20, ry + fo.get_ascent(Tema.t(T_PERGUNTA))),
			Desenho.caber(rodape, fo, T_PERGUNTA, larg - 40, 2), fo, T_PERGUNTA, Tema.ETIQUETA if bom else Tema.ETIQUETA_SOMBRA, larg - 40, 2)


func _tempo() -> void:
	_dicas()
	_treino_e_valendo()
	var topo_das_faixas: float = (HudJogo.quadro_da_sala(str(sala.nome), str(sala.acao), size.x)["rect"] as Rect2).end.y + 8.0
	var d: float = sala.duracao
	if d <= 0.0:
		var linha := str(sala.progresso())
		if linha != "":
			var fp := Tema.archivo(500)
			var lw := Desenho.largura(linha, fp, Tema.T_SELO)
			var q := Rect2(Vector2(Tema.MARGEM_X - 28, topo_das_faixas), Vector2(lw + 56, 52))
			Desenho.moldura(self, q, Color(Tema.CASCO, 0.9), Tema.GRAFITE, 2, 12)
			Desenho.texto(self, q.position + Vector2(28, 34), linha, fp, Tema.T_SELO, Tema.ETIQUETA_SOMBRA)
		return
	if sala.treinando:
		return
	var resta := float(sala.tempo_que_resta())
	var larg := 480.0
	var p := Vector2(Tema.MARGEM_X - 28, topo_das_faixas + 22.0)
	var cor := Tema.SECAO[3] if resta < 15.0 else Tema.ETIQUETA
	var r := Rect2(p - Vector2(0, 22), Vector2(larg + 110, 52))
	Desenho.moldura(self, r, Color(Tema.CASCO, 0.9), Tema.GRAFITE, 2, 12)
	var trilho := Rect2(p + Vector2(20, 0), Vector2(larg, 8))
	draw_rect(trilho, Tema.GRAFITE)
	draw_rect(Rect2(trilho.position, Vector2(larg * resta / d, 8)), cor)
	var s := "%d s" % int(ceil(resta))
	var f := Tema.vt()
	Desenho.texto(self, Vector2(trilho.end.x + 18, p.y + 12), s, f, Tema.T_SELO, cor)


func _treino_e_valendo() -> void:
	if sala.treinando:
		var s := "Treino — não vale ponto"
		var f := Tema.archivo(600)
		var w := Desenho.largura(s, f, Tema.T_ROTULO) + 56
		var r := Rect2(Vector2((size.x - w) * 0.5, 176), Vector2(w, 56))
		Desenho.moldura(self, r, Color(Tema.CASCO, 0.94), Tema.ETIQUETA, 3, 14)
		Desenho.texto(self, r.position + Vector2(28, 38), s, f, Tema.T_ROTULO, Tema.ETIQUETA)
	elif float(sala.valendo_t) > 0.0:
		var k: float = 1.4 - float(sala.valendo_t)
		var escala := 1.0 + 0.35 * maxf(0.0, 1.0 - k / 0.25)
		var alfa := clampf(float(sala.valendo_t) / 0.4, 0.0, 1.0)
		var s2 := "Valendo!"
		var f2 := Tema.bungee()
		var tam := int(Tema.T_DISPLAY * escala)
		var w2 := Desenho.largura(s2, f2, tam)
		var placa := _rect_valendo()
		var alfa_placa := 0.92 * clampf(alfa * 2.5, 0.0, 1.0)
		Desenho.moldura(self, placa, Color(Tema.CASCO, alfa_placa), Color(Tema.GRAFITE, alfa_placa), 2, Tema.RAIO_QUADRO)
		Desenho.texto(self, Vector2((size.x - w2) * 0.5, size.y * 0.42), s2, f2, tam, Color(Tema.ETIQUETA, alfa))


func _rect_valendo() -> Rect2:
	if sala == null or sala.treinando or float(sala.valendo_t) <= 0.0:
		return Rect2()
	var f2 := Tema.bungee()
	var tam := int(Tema.T_DISPLAY * 1.35)
	var w2 := Desenho.largura("Valendo!", f2, tam)
	var asc := f2.get_ascent(Tema.t(tam))
	var desc := f2.get_descent(Tema.t(tam))
	var base := size.y * 0.42
	return Rect2(Vector2((size.x - w2) * 0.5 - 48.0, base - asc - 20.0), Vector2(w2 + 96.0, asc + desc + 40.0))
