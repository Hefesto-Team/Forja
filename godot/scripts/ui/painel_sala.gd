class_name PainelSala
extends Control
## O painel de uma sala que mede: no aviso, o objetivo e as features que ela
## prova, e quem já está pronto; no jogo, o tempo que resta; no fim, o
## veredito de cada um, por feature, com o que foi medido — ícone e palavra,
## nunca só a cor.

var sala: Node = null  ## a SalaJogo em curso, ou null
var escondido := false  ## a pausa ou o diagnóstico estão por cima


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
		"fim":
			_fim()


func _aviso() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.CASA, 0.55))
	var larg := 1120.0
	var fo := Tema.fonte(400)
	var objetivo := str(sala.objetivo)
	var alt_obj := Desenho.altura_paragrafo(objetivo, fo, Tema.T_CORPO, larg - 96)
	var alt := 420.0 + alt_obj
	var r := Rect2(Vector2((size.x - larg) * 0.5, (size.y - alt) * 0.5 - 10), Vector2(larg, alt))
	Desenho.moldura(self, r, Color(Tema.PAINEL, 0.97), Tema.LINHA, 2, Tema.RAIO_QUADRO)
	var x := r.position.x + 48
	Desenho.texto(self, Vector2(x, r.position.y + 92), str(sala.nome), Tema.fonte(700), Tema.T_TITULO, Tema.FG)
	Desenho.paragrafo(self, Vector2(x, r.position.y + 150), objetivo, fo, Tema.T_CORPO, Tema.SUAVE, larg - 96)
	# o que a sala prova: glifo e nome
	var y := r.position.y + 150 + alt_obj + 36
	Desenho.texto(self, Vector2(x, y), "O que esta sala mede", Tema.fonte(600), Tema.T_SELO, Tema.ROXO)
	y += 24
	var fx := x
	for f in sala.features:
		var tex := Desenho.glifo(Desenho.GLIFO_DA_FEATURE.get(f, ""))
		var nome := _nome_da_feature(f)
		var w := 64.0 + Desenho.largura(nome, Tema.fonte(500), Tema.T_ROTULO) + 48.0
		if tex:
			draw_texture_rect(tex, Rect2(Vector2(fx, y + 8), Vector2(48, 48)), false, Tema.CIANO)
		Desenho.texto(self, Vector2(fx + 60, y + 44), nome, Tema.fonte(500), Tema.T_ROTULO, Tema.FG)
		fx += w
	# quem já está pronto, na ordem dos lugares
	y += 120
	var cx := x
	for l in 4:
		if not Forja.ocupado(l):
			continue
		var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
		var pronto: bool = sala.prontos[l]
		var chip := Rect2(Vector2(cx, y), Vector2(236, 64))
		Desenho.moldura(self, chip, Tema.SEL if pronto else Tema.APP, cor_id, 3, 12)
		Desenho.texto(self, chip.position + Vector2(20, 42), "P%d" % (l + 1), Tema.fonte(700), Tema.T_ROTULO, cor_id)
		if pronto:
			Desenho.texto(self, chip.position + Vector2(76, 42), "✓ pronto", Tema.fonte(600), Tema.T_SELO, Tema.VERDE)
		else:
			Desenho.texto(self, chip.position + Vector2(76, 42), "aguardando", Tema.fonte(400), Tema.T_SELO, Tema.MUDO)
		cx += 252
	# o botão, no alto à direita (a linha dos lugares é dos quatro)
	Desenho.dicas_a_direita(self, Vector2(r.end.x - 48, r.position.y + 84), [["cruz", "pronto"]], Tema.T_ROTULO)


func _nome_da_feature(chave: String) -> String:
	for f in Forja.features():
		if f.chave == chave:
			return f.nome
	return chave


## As dicas de cada lugar, embaixo da raia de cada um: uma pílula com a frase
## e os glifos dos botões, com a borda na cor do lugar.
func _dicas() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var f := Tema.fonte(500)
	var tam := 22
	for l in 4:
		if not Forja.ocupado(l):
			continue
		var d: Dictionary = sala.dica(l)
		if d.is_empty() or not d.has("pos"):
			continue
		var partes: Array = d.get("partes", [])
		var larg := 0.0
		for parte in partes:
			var s := str(parte)
			larg += (34.0 if s.begins_with("@") else Desenho.largura(s, f, tam)) + 10.0
		larg += 36.0 - 10.0
		var centro := cam.unproject_position(d.pos)
		var r := Rect2(Vector2(centro.x - larg * 0.5, centro.y - 26.0), Vector2(larg, 52.0))
		r.position.x = clampf(r.position.x, 12.0, size.x - larg - 12.0)
		r.position.y = clampf(r.position.y, 12.0, size.y - 140.0)
		var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
		Desenho.moldura(self, r, Color(Tema.PAINEL, 0.92), cor_id, 2, 12)
		var x := r.position.x + 18.0
		for parte in partes:
			var s := str(parte)
			if s.begins_with("@"):
				var tex := Desenho.glifo(s.substr(1))
				if tex:
					draw_texture_rect(tex, Rect2(Vector2(x, r.position.y + 9.0), Vector2(34, 34)), false, Tema.ROSA)
				x += 34.0 + 10.0
			else:
				Desenho.texto(self, Vector2(x, r.position.y + 34.0), s, f, tam, Tema.FG)
				x += Desenho.largura(s, f, tam) + 10.0


func _tempo() -> void:
	_dicas()
	var d: float = sala.duracao
	if d <= 0.0:
		return
	# o tempo que resta, logo abaixo do nome da sala (o quadro da HUD)
	var resta := maxf(0.0, d - float(sala.t_fase))
	var larg := 480.0
	var p := Vector2(Tema.MARGEM_X - 28, 184)
	var cor := Tema.LARANJA if resta < 15.0 else Tema.ROXO
	var r := Rect2(p - Vector2(0, 22), Vector2(larg + 110, 52))
	Desenho.moldura(self, r, Color(Tema.PAINEL, 0.9), Tema.LINHA, 2, 12)
	var trilho := Rect2(p + Vector2(20, 0), Vector2(larg, 8))
	draw_rect(trilho, Tema.TRILHO)
	draw_rect(Rect2(trilho.position, Vector2(larg * resta / d, 8)), cor)
	var s := "%d s" % int(ceil(resta))
	var f := Tema.mono(500)
	Desenho.texto(self, Vector2(trilho.end.x + 18, p.y + 12), s, f, Tema.T_SELO, cor)


func _fim() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.CASA, 0.7))
	var lugares: Array = []
	for l in 4:
		if sala.vereditos.has(l):
			lugares.append(l)
	var coluna := 380.0
	var bloco := 178.0
	var larg := maxf(900.0, 96.0 + coluna * lugares.size())
	var alt: float = 220.0 + bloco * float(sala.features.size())
	var r := Rect2(Vector2((size.x - larg) * 0.5, (size.y - alt) * 0.5), Vector2(larg, alt))
	Desenho.moldura(self, r, Color(Tema.PAINEL, 0.97), Tema.LINHA, 2, Tema.RAIO_QUADRO)
	Desenho.texto(self, r.position + Vector2(48, 84), str(sala.nome), Tema.fonte(700), 52, Tema.FG)
	Desenho.texto(self, r.position + Vector2(48 + Desenho.largura(str(sala.nome), Tema.fonte(700), 52) + 24, 84),
		"o veredito", Tema.fonte(500), Tema.T_CORPO, Tema.ROXO)
	for i in lugares.size():
		var l: int = lugares[i]
		var x := r.position.x + 48 + i * coluna
		var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
		Desenho.texto(self, Vector2(x, r.position.y + 150), "P%d" % (l + 1), Tema.fonte(700), Tema.T_CORPO, cor_id)
		Desenho.texto(self, Vector2(x + 60, r.position.y + 150), "%d pontos" % sala.pontos[l], Tema.mono(500), Tema.T_SELO, Tema.SUAVE)
		var lista: Array = sala.vereditos[l]
		var y := r.position.y + 190
		for v in lista:
			var res := int(v.get("resultado", 0))
			var cor: Color = [Tema.MUDO, Tema.VERDE, Tema.VERMELHO][clampi(res, 0, 2)]
			var palavra: String = ["— NÃO MEDIDO", "✓ PASSOU", "✗ FALHOU"][clampi(res, 0, 2)]
			Desenho.texto(self, Vector2(x, y + 26), str(v.get("nome", "")), Tema.fonte(600), Tema.T_SELO, Tema.FG, HORIZONTAL_ALIGNMENT_LEFT, coluna - 40)
			Desenho.selo(self, Vector2(x, y + 40), palavra, cor, 20)
			# o que foi medido; se não passou, o porquê (a observação diz)
			var medido := str(v.get("medido", ""))
			if res != 1 and str(v.get("obs", "")) != "":
				medido = str(v.get("obs", ""))
			medido = Desenho.caber(medido, Tema.fonte(400), 20, coluna - 40, 3)
			Desenho.paragrafo(self, Vector2(x, y + 102), medido, Tema.fonte(400), 20, Tema.SUAVE, coluna - 40, 3)
			y += bloco
	if float(sala.t_fase) > 0.8:
		Desenho.dicas_a_direita(self, Vector2(r.end.x - 48, r.position.y + 84), [["cruz", "voltar ao salão"]], Tema.T_ROTULO)
