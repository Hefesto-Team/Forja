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
	# a arena fica à mostra: o quadro sobe e o boneco de cada um mostra o gesto
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.CASA, 0.25))
	var larg := 1120.0
	# mostrar, não contar: o nome, o verbo numa linha e o que se sente na mão
	# (os glifos). O resto a sala ensina jogando, pelas dicas curtas na raia.
	var poucos := str(sala.com_poucos())
	var papel: int = sala.papel_som
	# os glifos das features, em quantas linhas couberem na largura
	var filas := 1
	var fila_x := 0.0
	for f in sala.features:
		var w := 64.0 + Desenho.largura(_nome_da_feature(f), Tema.fonte(500), Tema.T_ROTULO) + 48.0
		if fila_x > 0.0 and fila_x + w - 48.0 > larg - 96.0:
			filas += 1
			fila_x = 0.0
		fila_x += w
	var alt := 410.0 + 64.0 * (filas - 1) + (40.0 if poucos != "" else 0.0) + (ALTURA_SOM if papel >= 0 else 0.0)
	var r := Rect2(Vector2((size.x - larg) * 0.5, 176), Vector2(larg, alt))
	# o quadro entra deslizando (a sala nova chega, não aparece)
	var k := clampf(float(sala.t_fase) / 0.35, 0.0, 1.0)
	r.position.x += (1.0 - k * k * (3.0 - 2.0 * k)) * 520.0
	Desenho.moldura(self, r, Color(Tema.PAINEL, 0.97), Tema.LINHA, 2, Tema.RAIO_QUADRO)
	var x := r.position.x + 48
	Desenho.texto(self, Vector2(x, r.position.y + 92), str(sala.nome), Tema.fonte(700), Tema.T_TITULO, Tema.FG)
	if str(sala.na_prova_de_fogo) != "":
		Desenho.texto(self, Vector2(x + Desenho.largura(str(sala.nome), Tema.fonte(700), Tema.T_TITULO) + 28, r.position.y + 88),
			str(sala.na_prova_de_fogo), Tema.fonte(600), Tema.T_SELO, Tema.LARANJA)
	Desenho.texto(self, Vector2(x, r.position.y + 156), str(sala.acao), Tema.fonte(500), Tema.T_SUBTITULO, Tema.ROSA,
		HORIZONTAL_ALIGNMENT_LEFT, larg - 96)
	# com menos de quatro, o que muda: um selo, não uma frase
	if poucos != "":
		Desenho.selo(self, Vector2(x, r.position.y + 180), poucos, Tema.CIANO, Tema.T_SELO)
	# o que a sala prova: glifo e nome
	var y := r.position.y + 186 + (40.0 if poucos != "" else 0.0)
	var fx := x
	for f in sala.features:
		var tex := Desenho.glifo(Desenho.GLIFO_DA_FEATURE.get(f, ""))
		var nome := _nome_da_feature(f)
		var w := 64.0 + Desenho.largura(nome, Tema.fonte(500), Tema.T_ROTULO) + 48.0
		if fx > x and fx + w - 48.0 > x + larg - 96.0:
			fx = x
			y += 64.0
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
		var chip := Rect2(Vector2(cx, y), Vector2(250, 64.0 + (ALTURA_SOM if papel >= 0 else 0.0)))
		Desenho.moldura(self, chip, Tema.SEL if pronto else Tema.APP, cor_id, 3, 12)
		Desenho.texto(self, chip.position + Vector2(20, 42), "P%d" % (l + 1), Tema.fonte(700), Tema.T_ROTULO, cor_id)
		if pronto:
			Desenho.texto(self, chip.position + Vector2(62, 42), "✓ pronto", Tema.fonte(600), Tema.T_SELO, Tema.VERDE, HORIZONTAL_ALIGNMENT_LEFT, 180)
		else:
			# encolhe em vez de cortar (com o texto grande não caberia)
			var tam_ag := Tema.T_SELO
			while tam_ag > 20 and Desenho.largura("aguardando", Tema.fonte(400), tam_ag) > 180.0:
				tam_ag -= 1
			Desenho.texto(self, chip.position + Vector2(62, 42), "aguardando", Tema.fonte(400), tam_ag, Tema.MUDO, HORIZONTAL_ALIGNMENT_LEFT, 180)
		if papel >= 0:
			_som_do_lugar(chip, l, papel)
		cx += 258
	# os botões, no alto à direita (a linha dos lugares é dos quatro)
	var dicas := [["cruz", "pronto"]]
	if papel >= 0:
		dicas = [["esquerda", "trocar"], ["triangulo", "testar"], ["cruz", "pronto"]]
		if papel == Forja.PAPEL_MICROFONE:
			dicas = [["esquerda", "trocar"], ["cruz", "pronto"]]
	Desenho.dicas_a_direita(self, Vector2(r.end.x - 48, r.position.y + 84), dicas, Tema.T_ROTULO)


## O que o chip de cada lugar cresce numa sala de som.
const ALTURA_SOM := 190.0


## O dispositivo do papel de um lugar, no aviso de uma sala de som: o nome que
## o jogo mostra, como foi achado e, no microfone, a barra que sobe com a voz.
func _som_do_lugar(chip: Rect2, l: int, papel: int) -> void:
	var x := chip.position.x + 20.0
	var w := chip.size.x - 40.0
	var tem := Forja.som_tem(l, papel)
	var nome := Forja.som_nome(l, papel)
	var f := Tema.fonte(500)
	var f2 := Tema.fonte(400)
	# o nome do aparelho em até três linhas a 30 px (é o que diz qual é qual)
	var tam := Tema.T_SELO
	var nome_cabe := Desenho.caber(nome, f, tam, w, 3)
	var topo := chip.position.y + 64.0 + 8.0
	var alt_nome := Desenho.paragrafo(self, Vector2(x, topo + f.get_ascent(Tema.t(tam))), nome_cabe, f, tam,
		Tema.FG if tem else Tema.LARANJA, w, 3)
	var como := Forja.som_como(l, papel) if tem else "não achado"
	var y_como := topo + alt_nome + f2.get_ascent(Tema.t(tam))
	Desenho.texto(self, Vector2(x, y_como), Desenho.caber(como, f2, tam, w, 1), f2, tam, Tema.MUDO)
	if papel == Forja.PAPEL_MICROFONE and tem:
		var nivel := float(Forja.som_mic(l).get("nivel", 0.0))
		var trilho := Rect2(Vector2(x, y_como + 14.0), Vector2(w, 8))
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
	var tam := Tema.T_SELO
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
	# as dicas: onde cada uma cairia, afastadas como as perguntas, e desenhadas
	var pilulas: Array = []  # [lugar, partes, retângulo]
	for l in 4:
		if not Forja.ocupado(l) or not sala.pergunta(l).is_empty():
			continue
		var d: Dictionary = sala.dica(l)
		if d.is_empty() or not d.has("pos"):
			continue
		var partes: Array = d.get("partes", [])
		if sala.aprendeu(l):
			# aprendeu: a dica perde as palavras e fica só o glifo; sem glifo, some
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
		r.position.x = clampf(r.position.x, 12.0, size.x - larg - 12.0)
		r.position.y = clampf(r.position.y, 12.0, size.y - 140.0)
		pilulas.append([l, partes, r])
	_afastar(pilulas)
	for item in pilulas:
		var l: int = item[0]
		var partes: Array = item[1]
		var r: Rect2 = item[2]
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
## As respostas numa coluna só, a 30 px (quatro painéis lado a lado não cabem
## duas respostas por linha nesse tamanho: "metralhadora" não caberia).
const T_PERGUNTA := Tema.T_SELO
const LINHA_RESPOSTA := 52.0


## A altura do título e a do rodapé (até duas linhas cada).
func _alturas(q: Dictionary) -> Array:
	var ft := Tema.fonte(600)
	var fo := Tema.fonte(500)
	var titulo := str(q.get("titulo", ""))
	var rodape := str(q.get("rodape", ""))
	var th := Desenho.altura_paragrafo(Desenho.caber(titulo, ft, T_PERGUNTA, LARG_PERGUNTA - 40, 2), ft, T_PERGUNTA, LARG_PERGUNTA - 40, 2)
	var rh := 0.0
	if rodape != "":
		rh = Desenho.altura_paragrafo(Desenho.caber(rodape, fo, T_PERGUNTA, LARG_PERGUNTA - 40, 2), fo, T_PERGUNTA, LARG_PERGUNTA - 40, 2)
	return [th, rh]


## Onde a pergunta cai: embaixo da raia, dentro da tela.
func _rect_pergunta(cam: Camera3D, q: Dictionary) -> Rect2:
	var larg := LARG_PERGUNTA
	var n := Array(q.get("opcoes", [])).size()
	var h := _alturas(q)
	var alt := 16.0 + float(h[0]) + 10.0 + LINHA_RESPOSTA * n + (float(h[1]) + 14.0 if float(h[1]) > 0.0 else 10.0)
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
	itens.sort_custom(func(p, q): return (p[2] as Rect2).position.x < (q[2] as Rect2).position.x)
	for i in range(1, itens.size()):
		var a: Rect2 = itens[i - 1][2]
		var b: Rect2 = itens[i][2]
		if b.position.x < a.end.x + vao and _mesma_faixa(a, b):
			b.position.x = a.end.x + vao
			itens[i][2] = b
	for i in range(itens.size() - 1, -1, -1):
		var b: Rect2 = itens[i][2]
		var limite := size.x - 12.0
		if i < itens.size() - 1 and _mesma_faixa(b, itens[i + 1][2]):
			limite = (itens[i + 1][2] as Rect2).position.x - vao
		if b.end.x > limite:
			b.position.x = limite - b.size.x
			itens[i][2] = b


## Duas caixas na mesma altura da tela (uma empurra a outra só se se cruzam na vertical).
func _mesma_faixa(a: Rect2, b: Rect2) -> bool:
	return a.position.y < b.end.y and b.position.y < a.end.y


## Uma pergunta às cegas embaixo da raia: o título, as quatro respostas (o
## glifo do botão, a cor quando a pergunta é de cor, a palavra) e, revelada, a
## certa em verde e a escolhida errada em vermelho, com a frase do resultado.
func _pergunta(l: int, q: Dictionary, r: Rect2) -> void:
	var larg := LARG_PERGUNTA
	var opcoes: Array = q.get("opcoes", [])
	var rodape := str(q.get("rodape", ""))
	var ft := Tema.fonte(600)
	var fo := Tema.fonte(500)
	var h := _alturas(q)
	var titulo := Desenho.caber(str(q.get("titulo", "")), ft, T_PERGUNTA, larg - 40, 2)
	var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
	Desenho.moldura(self, r, Color(Tema.PAINEL, 0.95), cor_id, 2, 14)
	Desenho.paragrafo(self, r.position + Vector2(20, 16 + ft.get_ascent(Tema.t(T_PERGUNTA))), titulo, ft, T_PERGUNTA,
		Tema.FG, larg - 40, 2)
	var escolhida := int(q.get("escolhida", -1))
	var certa := int(q.get("certa", -1))
	var y0 := r.position.y + 16.0 + float(h[0]) + 10.0
	for i in opcoes.size():
		var o: Array = opcoes[i]
		var caixa := Rect2(Vector2(r.position.x + 20.0, y0 + i * LINHA_RESPOSTA), Vector2(larg - 40.0, LINHA_RESPOSTA - 6.0))
		var borda := Tema.LINHA
		var fundo := Color(Tema.APP, 0.9)
		if i == escolhida:
			fundo = Tema.SEL
		if certa >= 0 and i == certa:
			borda = Tema.VERDE
		elif certa >= 0 and i == escolhida:
			borda = Tema.VERMELHO
		Desenho.moldura(self, caixa, fundo, borda, 2 if borda == Tema.LINHA else 3, 10)
		var meio := caixa.position.y + caixa.size.y * 0.5
		var tex := Desenho.glifo(str(o[0]))
		if tex:
			draw_texture_rect(tex, Rect2(Vector2(caixa.position.x + 10, meio - 16), Vector2(32, 32)), false, Tema.ROSA)
		var tx := caixa.position.x + 54.0
		if o.size() > 1 and o[1] is Color:
			draw_circle(Vector2(tx + 12.0, meio), 12.0, o[1])
			draw_arc(Vector2(tx + 12.0, meio), 12.0, 0.0, TAU, 24, Tema.LINHA, 1.5)
			tx += 34.0
		# a palavra encolhe para caber inteira em vez de cortar (só se precisar)
		var palavra := str(o[o.size() - 1])
		var cabe := caixa.end.x - tx - 10.0
		var tam := T_PERGUNTA
		while tam > 22 and Desenho.largura(palavra, fo, tam) > cabe:
			tam -= 1
		Desenho.texto(self, Vector2(tx, meio + fo.get_ascent(Tema.t(tam)) * 0.36 + 2.0), palavra, fo, tam, Tema.FG,
			HORIZONTAL_ALIGNMENT_LEFT, cabe + 2.0)
	if rodape != "":
		var bom := certa >= 0 and escolhida == certa
		var ry := y0 + opcoes.size() * LINHA_RESPOSTA + 4.0
		Desenho.paragrafo(self, Vector2(r.position.x + 20, ry + fo.get_ascent(Tema.t(T_PERGUNTA))),
			Desenho.caber(rodape, fo, T_PERGUNTA, larg - 40, 2), fo, T_PERGUNTA, Tema.VERDE if bom else Tema.LARANJA, larg - 40, 2)


func _tempo() -> void:
	_dicas()
	_treino_e_valendo()
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
	# o veredito enxuto: uma linha por feature (o glifo e o nome), uma coluna
	# por lugar; na célula, o selo com ícone e palavra. O porquê só aparece no
	# que não passou — o resto mora no livro da sessão.
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.CASA, 0.6))
	var lugares: Array = []
	for l in 4:
		if sala.vereditos.has(l):
			lugares.append(l)
	var col_nome := 440.0
	var coluna := 300.0
	var linhas: Array = []  # as features, na ordem da sala, com a altura de cada linha
	for f in sala.features:
		var alta := false
		for l in lugares:
			var v := _veredito_de(l, f)
			if not v.is_empty() and int(v.get("resultado", 0)) != Forja.PASSOU:
				alta = true
		linhas.append([f, 156.0 if alta else 76.0])
	var alt := 200.0
	for li in linhas:
		alt += li[1]
	var larg := maxf(900.0, 96.0 + col_nome + coluna * lugares.size())
	var r := Rect2(Vector2((size.x - larg) * 0.5, (size.y - alt) * 0.5), Vector2(larg, alt))
	Desenho.moldura(self, r, Color(Tema.PAINEL, 0.97), Tema.LINHA, 2, Tema.RAIO_QUADRO)
	Desenho.texto(self, r.position + Vector2(48, 84), str(sala.nome), Tema.fonte(700), 52, Tema.FG)
	var x0 := r.position.x + 48 + col_nome
	for i in lugares.size():
		var l: int = lugares[i]
		var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
		var x := x0 + i * coluna
		Desenho.texto(self, Vector2(x, r.position.y + 150), "P%d" % (l + 1), Tema.fonte(700), Tema.T_CORPO, cor_id)
		Desenho.texto(self, Vector2(x + 60, r.position.y + 150), "%d" % sala.pontos[l], Tema.mono(500), Tema.T_MONO, Tema.SUAVE)
	var y := r.position.y + 180
	for li in linhas:
		var f: String = li[0]
		var tex := Desenho.glifo(Desenho.GLIFO_DA_FEATURE.get(f, ""))
		if tex:
			draw_texture_rect(tex, Rect2(Vector2(r.position.x + 48, y + 8), Vector2(40, 40)), false, Tema.CIANO)
		var nome := _nome_da_feature(f)
		var tam := Tema.T_ROTULO
		while tam > 20 and Desenho.largura(nome, Tema.fonte(500), tam) > col_nome - 76:
			tam -= 1
		Desenho.texto(self, Vector2(r.position.x + 100, y + 40), nome, Tema.fonte(500), tam, Tema.FG)
		for i in lugares.size():
			var v := _veredito_de(lugares[i], f)
			if v.is_empty():
				continue
			var x := x0 + i * coluna
			var res := clampi(int(v.get("resultado", 0)), 0, 2)
			var cor: Color = [Tema.MUDO, Tema.VERDE, Tema.VERMELHO][res]
			var palavra: String = ["— NÃO MEDIDO", "✓ PASSOU", "✗ FALHOU"][res]
			Desenho.selo(self, Vector2(x, y + 10), palavra, cor, Tema.T_SELO)
			if res != 1:
				var porque := str(v.get("obs", "")) if str(v.get("obs", "")) != "" else str(v.get("medido", ""))
				porque = Desenho.caber(porque, Tema.fonte(400), Tema.T_SELO, coluna - 24, 2)
				Desenho.paragrafo(self, Vector2(x, y + 70), porque, Tema.fonte(400), Tema.T_SELO, Tema.SUAVE, coluna - 24, 2)
		y += li[1]
	if float(sala.t_fase) > 0.8:
		Desenho.dicas_a_direita(self, Vector2(r.end.x - 48, r.position.y + 84), [["cruz", str(sala.seguir)]], Tema.T_ROTULO)


func _veredito_de(l: int, f: String) -> Dictionary:
	for v in sala.vereditos.get(l, []):
		if str(v.get("feature", "")) == f:
			return v
	return {}


## O selo do treino no alto, e o "Valendo!" grande quando ele acaba.
func _treino_e_valendo() -> void:
	if sala.treinando:
		var s := "treino — não vale ponto"
		var f := Tema.fonte(600)
		var w := Desenho.largura(s, f, Tema.T_ROTULO) + 56
		var r := Rect2(Vector2((size.x - w) * 0.5, 176), Vector2(w, 56))
		Desenho.moldura(self, r, Color(Tema.PAINEL, 0.94), Tema.CIANO, 3, 14)
		Desenho.texto(self, r.position + Vector2(28, 38), s, f, Tema.T_ROTULO, Tema.CIANO)
	elif float(sala.valendo_t) > 0.0:
		var k: float = 1.4 - float(sala.valendo_t)
		var escala := 1.0 + 0.35 * maxf(0.0, 1.0 - k / 0.25)
		var alfa := clampf(float(sala.valendo_t) / 0.4, 0.0, 1.0)
		var s2 := "Valendo!"
		var f2 := Tema.fonte(700)
		var tam := int(Tema.T_DISPLAY * escala)
		var w2 := Desenho.largura(s2, f2, tam)
		Desenho.texto(self, Vector2((size.x - w2) * 0.5 + 4, size.y * 0.42 + 4), s2, f2, tam, Color(Tema.CASA, 0.6 * alfa))
		Desenho.texto(self, Vector2((size.x - w2) * 0.5, size.y * 0.42), s2, f2, tam, Color(Tema.ROSA, alfa))
