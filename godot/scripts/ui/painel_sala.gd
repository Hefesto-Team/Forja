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
	# com menos de quatro, a sala diz o que muda, logo depois do objetivo
	var poucos := str(sala.com_poucos())
	var fp := Tema.fonte(500)
	var alt_poucos := Desenho.altura_paragrafo(poucos, fp, Tema.T_ROTULO, larg - 96) + 16.0 if poucos != "" else 0.0
	var papel: int = sala.papel_som
	var alt := 420.0 + alt_obj + alt_poucos + (104.0 if papel >= 0 else 0.0)
	var r := Rect2(Vector2((size.x - larg) * 0.5, (size.y - alt) * 0.5 - 10), Vector2(larg, alt))
	Desenho.moldura(self, r, Color(Tema.PAINEL, 0.97), Tema.LINHA, 2, Tema.RAIO_QUADRO)
	var x := r.position.x + 48
	Desenho.texto(self, Vector2(x, r.position.y + 92), str(sala.nome), Tema.fonte(700), Tema.T_TITULO, Tema.FG)
	if str(sala.na_prova_de_fogo) != "":
		Desenho.texto(self, Vector2(x + Desenho.largura(str(sala.nome), Tema.fonte(700), Tema.T_TITULO) + 28, r.position.y + 88),
			str(sala.na_prova_de_fogo), Tema.fonte(600), Tema.T_SELO, Tema.LARANJA)
	Desenho.paragrafo(self, Vector2(x, r.position.y + 150), objetivo, fo, Tema.T_CORPO, Tema.SUAVE, larg - 96)
	if poucos != "":
		Desenho.paragrafo(self, Vector2(x, r.position.y + 150 + alt_obj + 16), poucos, fp, Tema.T_ROTULO, Tema.CIANO, larg - 96)
	# o que a sala prova: glifo e nome
	var y := r.position.y + 150 + alt_obj + alt_poucos + 36
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
		var chip := Rect2(Vector2(cx, y), Vector2(236, 64 + (104 if papel >= 0 else 0)))
		Desenho.moldura(self, chip, Tema.SEL if pronto else Tema.APP, cor_id, 3, 12)
		Desenho.texto(self, chip.position + Vector2(20, 42), "P%d" % (l + 1), Tema.fonte(700), Tema.T_ROTULO, cor_id)
		if pronto:
			Desenho.texto(self, chip.position + Vector2(76, 42), "✓ pronto", Tema.fonte(600), Tema.T_SELO, Tema.VERDE)
		else:
			Desenho.texto(self, chip.position + Vector2(76, 42), "aguardando", Tema.fonte(400), Tema.T_SELO, Tema.MUDO)
		if papel >= 0:
			_som_do_lugar(chip, l, papel)
		cx += 252
	# os botões, no alto à direita (a linha dos lugares é dos quatro)
	var dicas := [["cruz", "pronto"]]
	if papel >= 0:
		dicas = [["esquerda", "trocar"], ["triangulo", "testar"], ["cruz", "pronto"]]
		if papel == Forja.PAPEL_MICROFONE:
			dicas = [["esquerda", "trocar"], ["cruz", "pronto"]]
	Desenho.dicas_a_direita(self, Vector2(r.end.x - 48, r.position.y + 84), dicas, Tema.T_ROTULO)


## O dispositivo do papel de um lugar, no aviso de uma sala de som: o nome que
## o jogo mostra, como foi achado e, no microfone, a barra que sobe com a voz.
func _som_do_lugar(chip: Rect2, l: int, papel: int) -> void:
	var x := chip.position.x + 20.0
	var w := chip.size.x - 40.0
	var tem := Forja.som_tem(l, papel)
	var nome := Forja.som_nome(l, papel)
	var f := Tema.fonte(500)
	var f2 := Tema.fonte(400)
	var nome_cabe := Desenho.caber(nome, f, 18, w, 2)
	Desenho.paragrafo(self, Vector2(x, chip.position.y + 86), nome_cabe, f, 18, Tema.FG if tem else Tema.LARANJA, w, 2)
	var como := Forja.som_como(l, papel) if tem else "não achado"
	Desenho.texto(self, Vector2(x, chip.position.y + 138), Desenho.caber(como, f2, 16, w, 1), f2, 16, Tema.MUDO)
	if papel == Forja.PAPEL_MICROFONE and tem:
		var nivel := float(Forja.som_mic(l).get("nivel", 0.0))
		var trilho := Rect2(Vector2(x, chip.position.y + 150), Vector2(w, 8))
		draw_rect(trilho, Tema.TRILHO)
		draw_rect(Rect2(trilho.position, Vector2(w * clampf(nivel, 0.0, 1.0), 8)), Tema.VERDE)


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
	# as perguntas primeiro: onde cada uma cairia, e depois lado a lado, sem
	# uma cobrir a outra (numa câmera mais perto, as raias vizinhas se tocam)
	var perguntas: Array = []  # [lugar, pergunta, retângulo]
	for l in 4:
		if not Forja.ocupado(l):
			continue
		var q: Dictionary = sala.pergunta(l)
		if not q.is_empty():
			perguntas.append([l, q, _rect_pergunta(cam, q)])
	_afastar(perguntas)
	for item in perguntas:
		_pergunta(item[0], item[1], item[2])
	for l in 4:
		if not Forja.ocupado(l) or not sala.pergunta(l).is_empty():
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


const LARG_PERGUNTA := 400.0


## O título quebra em até duas linhas; a segunda empurra as respostas.
func _extra_do_titulo(q: Dictionary) -> float:
	var ft := Tema.fonte(600)
	return maxf(0.0, Desenho.altura_paragrafo(str(q.get("titulo", "")), ft, 22, LARG_PERGUNTA - 40, 2) - ft.get_height(22))


## Onde a pergunta cai: embaixo da raia, dentro da tela.
func _rect_pergunta(cam: Camera3D, q: Dictionary) -> Rect2:
	var larg := LARG_PERGUNTA
	var linhas := int(ceil(Array(q.get("opcoes", [])).size() / 2.0))
	var rodape := str(q.get("rodape", ""))
	var alt := 70.0 + _extra_do_titulo(q) + 58.0 * linhas + (40.0 if rodape != "" else 10.0)
	var centro := cam.unproject_position(q.get("pos", Vector3.ZERO))
	var r := Rect2(Vector2(centro.x - larg * 0.5, centro.y - alt * 0.5), Vector2(larg, alt))
	r.position.x = clampf(r.position.x, 12.0, size.x - larg - 12.0)
	r.position.y = clampf(r.position.y, 230.0, size.y - alt - 90.0)
	return r


## Lado a lado, na ordem das raias: da esquerda para a direita empurra para a
## direita o que encosta; da direita para a esquerda, devolve o que passou da
## tela.
func _afastar(itens: Array) -> void:
	var vao := 10.0
	for i in range(1, itens.size()):
		var a: Rect2 = itens[i - 1][2]
		var b: Rect2 = itens[i][2]
		if b.position.x < a.end.x + vao:
			b.position.x = a.end.x + vao
			itens[i][2] = b
	for i in range(itens.size() - 1, -1, -1):
		var b: Rect2 = itens[i][2]
		var limite := size.x - 12.0 if i == itens.size() - 1 else (itens[i + 1][2] as Rect2).position.x - vao
		if b.end.x > limite:
			b.position.x = limite - b.size.x
			itens[i][2] = b


## Uma pergunta às cegas embaixo da raia: o título, as quatro respostas (o
## glifo do botão, a cor quando a pergunta é de cor, a palavra) e, revelada, a
## certa em verde e a escolhida errada em vermelho, com a frase do resultado.
func _pergunta(l: int, q: Dictionary, r: Rect2) -> void:
	var larg := LARG_PERGUNTA
	var opcoes: Array = q.get("opcoes", [])
	var rodape := str(q.get("rodape", ""))
	var ft := Tema.fonte(600)
	var fo := Tema.fonte(500)
	var titulo := str(q.get("titulo", ""))
	var extra := _extra_do_titulo(q)
	var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
	Desenho.moldura(self, r, Color(Tema.PAINEL, 0.95), cor_id, 2, 14)
	Desenho.paragrafo(self, r.position + Vector2(20, 38), titulo, ft, 22, Tema.FG, larg - 40, 2)
	var escolhida := int(q.get("escolhida", -1))
	var certa := int(q.get("certa", -1))
	var w := (larg - 40.0) * 0.5
	for i in opcoes.size():
		var o: Array = opcoes[i]
		var cx := r.position.x + 20.0 + (i % 2) * w
		var cy := r.position.y + 58.0 + extra + int(i / 2) * 58.0
		var caixa := Rect2(Vector2(cx, cy), Vector2(w - 8.0, 50.0))
		var borda := Tema.LINHA
		var fundo := Color(Tema.APP, 0.9)
		if i == escolhida:
			fundo = Tema.SEL
		if certa >= 0 and i == certa:
			borda = Tema.VERDE
		elif certa >= 0 and i == escolhida:
			borda = Tema.VERMELHO
		Desenho.moldura(self, caixa, fundo, borda, 2 if borda == Tema.LINHA else 3, 10)
		var tex := Desenho.glifo(str(o[0]))
		if tex:
			draw_texture_rect(tex, Rect2(caixa.position + Vector2(10, 9), Vector2(32, 32)), false, Tema.ROSA)
		var tx := caixa.position.x + 50.0
		if o.size() > 1 and o[1] is Color:
			draw_circle(Vector2(tx + 11.0, caixa.position.y + 25.0), 11.0, o[1])
			draw_arc(Vector2(tx + 11.0, caixa.position.y + 25.0), 11.0, 0.0, TAU, 24, Tema.LINHA, 1.5)
			tx += 30.0
		# a palavra encolhe para caber inteira ("metralhadora") em vez de cortar
		var palavra := str(o[o.size() - 1])
		var cabe := caixa.end.x - tx - 8.0
		var tam := 20
		while tam > 15 and Desenho.largura(palavra, fo, tam) > cabe:
			tam -= 1
		Desenho.texto(self, Vector2(tx, caixa.position.y + 32.0 + tam * 0.05), palavra, fo, tam, Tema.FG,
			HORIZONTAL_ALIGNMENT_LEFT, cabe + 2.0)
	if rodape != "":
		var bom := certa >= 0 and escolhida == certa
		# o rodapé também encolhe até caber ("mesmo com tudo ligado" saía "tudo lig")
		var tam_r := 20
		while tam_r > 14 and Desenho.largura(rodape, fo, tam_r) > larg - 40:
			tam_r -= 1
		Desenho.texto(self, Vector2(r.position.x + 20, r.end.y - 16), rodape, fo, tam_r, Tema.VERDE if bom else Tema.LARANJA,
			HORIZONTAL_ALIGNMENT_LEFT, larg - 40)


func _tempo() -> void:
	_dicas()
	var d: float = sala.duracao
	if d <= 0.0:
		# sem relógio: a linha de progresso da sala, no mesmo lugar
		var linha := str(sala.progresso())
		if linha != "":
			var fp := Tema.fonte(500)
			var lw := Desenho.largura(linha, fp, Tema.T_SELO)
			var q := Rect2(Vector2(Tema.MARGEM_X - 28, 162), Vector2(lw + 44, 52))
			Desenho.moldura(self, q, Color(Tema.PAINEL, 0.9), Tema.LINHA, 2, 12)
			Desenho.texto(self, q.position + Vector2(22, 34), linha, fp, Tema.T_SELO, Tema.SUAVE)
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
			# o nome da feature inteiro: a letra encolhe até caber na coluna
			var nome_f := str(v.get("nome", ""))
			var tam_nome := Tema.T_SELO
			while tam_nome > 16 and Desenho.largura(nome_f, Tema.fonte(600), tam_nome) > coluna - 40:
				tam_nome -= 1
			Desenho.texto(self, Vector2(x, y + 26), nome_f, Tema.fonte(600), tam_nome, Tema.FG, HORIZONTAL_ALIGNMENT_LEFT, coluna - 40)
			Desenho.selo(self, Vector2(x, y + 40), palavra, cor, 20)
			# o que foi medido; se não passou, o porquê (a observação diz)
			var medido := str(v.get("medido", ""))
			if res != 1 and str(v.get("obs", "")) != "":
				medido = str(v.get("obs", ""))
			medido = Desenho.caber(medido, Tema.fonte(400), 20, coluna - 40, 3)
			Desenho.paragrafo(self, Vector2(x, y + 102), medido, Tema.fonte(400), 20, Tema.SUAVE, coluna - 40, 3)
			y += bloco
	if float(sala.t_fase) > 0.8:
		Desenho.dicas_a_direita(self, Vector2(r.end.x - 48, r.position.y + 84), [["cruz", str(sala.seguir)]], Tema.T_ROTULO)
