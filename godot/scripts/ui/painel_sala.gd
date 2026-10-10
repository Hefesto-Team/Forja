class_name PainelSala
extends Control
## O painel de uma sala que mede: no aviso, o objetivo e as features que ela
## prova, e quem já está pronto; no jogo, o tempo que resta. O fim é da
## TelaResultado (resultado.gd).

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
	var do_kit := sala is Minigame and bool(sala.com_entrada)
	match str(sala.fase):
		"entrada":
			_entrada()
		"aviso":
			if do_kit:
				_jcard()
			else:
				_aviso()
		"jogo":
			_tempo()
			if do_kit:
				_jcard()


func _aviso() -> void:
	# a arena fica à mostra: o quadro sobe e o boneco de cada um mostra o gesto
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.FITA, 0.25))
	var larg := 1120.0
	# mostrar, não contar: o nome, o verbo numa linha e um ícone da parte do
	# controle que a sala usa. O resto a sala ensina jogando, pelas dicas curtas
	# na raia. O dispositivo de som achado é ferramenta: só no Modo bancada.
	var poucos := str(sala.com_poucos())
	var papel: int = sala.papel_som
	var som := papel >= 0 and Forja.bancada
	var alt := 368.0 + (40.0 if poucos != "" else 0.0) + (ALTURA_SOM if som else 0.0)
	var r := Rect2(Vector2((size.x - larg) * 0.5, 176), Vector2(larg, alt))
	# o quadro entra deslizando (a sala nova chega, não aparece)
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
	# com menos de quatro, o que muda: um selo, não uma frase
	if poucos != "":
		Desenho.selo(self, Vector2(x, r.position.y + 180), poucos, Tema.ETIQUETA, Tema.T_SELO)
	# o ícone da parte do controle que a sala usa
	var icone := Desenho.glifo(str(sala.icone))
	if icone:
		draw_texture_rect(icone, Rect2(Vector2(r.end.x - 48 - 96, r.position.y + 40), Vector2(96, 96)), false, Tema.ETIQUETA)
	# quem já está pronto, na ordem dos lugares
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
	# o aviso não espera para sempre: o trilho esvazia até a sala começar sozinha
	var trilho := Rect2(Vector2(x, y + 64.0 + (ALTURA_SOM if som else 0.0) + 16.0), Vector2(larg - 96.0, 8.0))
	draw_rect(trilho, Tema.GRAFITE)
	var resta := 1.0 - clampf(float(sala.t_fase) / SalaJogo.AVISO_MAX, 0.0, 1.0)
	draw_rect(Rect2(trilho.position, Vector2(trilho.size.x * resta, 8.0)), Tema.ETIQUETA)
	# os botões, embaixo à direita (a linha dos lugares é dos quatro)
	var dicas := [["cruz", "Pronto"]]
	if som:
		dicas = [["esquerda", "Trocar"], ["triangulo", "Testar"], ["cruz", "Pronto"]]
		if papel == Forja.PAPEL_MICROFONE:
			dicas = [["esquerda", "Trocar"], ["cruz", "Pronto"]]
	Desenho.dicas_a_direita(self, Vector2(r.end.x - 48, trilho.position.y + 52), dicas, Tema.T_ROTULO)


## O que o chip de cada lugar cresce numa sala de som.
const ALTURA_SOM := 190.0


## O dispositivo do papel de um lugar, no aviso de uma sala de som: o nome que
## o jogo mostra, como foi achado e, no microfone, a barra que sobe com a voz.
func _som_do_lugar(chip: Rect2, l: int, papel: int) -> void:
	var x := chip.position.x + 20.0
	var w := chip.size.x - 40.0
	var tem := Forja.som_tem(l, papel)
	var nome := Forja.som_nome(l, papel)
	var f := Tema.archivo(500)
	var f2 := Tema.archivo(500)
	# o nome do aparelho em até três linhas a 30 px (é o que diz qual é qual)
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


## As dicas de cada lugar, embaixo da raia de cada um: uma pílula com a frase
## e os glifos dos botões, com a borda na cor do lugar.
func _dicas() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var f := Tema.archivo(500)
	var tam := Tema.T_SELO
	# as perguntas primeiro: onde cada uma cairia, e depois lado a lado, sem
	# uma cobrir a outra (numa câmera mais perto, as raias vizinhas se tocam)
	if Forja.bancada:  # a pergunta às cegas é do Modo bancada
		var perguntas: Array = []  # [lugar, pergunta, retângulo]
		for l in 4:
			if not Forja.ocupado(l):
				continue
			var q: Dictionary = sala.pergunta(l)
			if not q.is_empty():
				perguntas.append([l, q, _rect_pergunta(cam, q)])
		_afastar(perguntas, FOLGA_PERGUNTA)
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
		# o texto da pílula (18 px de folga) fica dentro da área segura
		r.position.x = clampf(r.position.x, Tema.MARGEM_X - FOLGA_PILULA, size.x - Tema.MARGEM_X + FOLGA_PILULA - larg)
		r.position.y = clampf(r.position.y, 12.0, size.y - 140.0)
		pilulas.append([l, partes, r])
	_afastar(pilulas, FOLGA_PILULA)
	# G04: a pílula que cruza um cartão do HUD sai dele (em cima, para baixo do cartão; embaixo, para cima)
	if bool(sala.com_hud):
		for it in pilulas:
			var rp: Rect2 = it[2]
			for k in 4:
				var c := HudJogo.cartao(k, size)
				if rp.intersects(c):
					rp.position.y = c.end.y + 8.0 if k < 2 else c.position.y - rp.size.y - 8.0
			it[2] = rp
	# a dica que cairia em cima do «Valendo!» espera ele sumir (1,4 s)
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


## O quanto a moldura passa do texto (a pílula e a pergunta): o texto, e não a
## moldura, é o que fica dentro da área segura.
const FOLGA_PILULA := 18.0
const FOLGA_PERGUNTA := 20.0
const LARG_PERGUNTA := 400.0
## As respostas numa coluna só, a 30 px (quatro painéis lado a lado não cabem
## duas respostas por linha nesse tamanho: "metralhadora" não caberia).
const T_PERGUNTA := Tema.T_SELO
const LINHA_RESPOSTA := 52.0


## A altura do título e a do rodapé (até duas linhas cada).
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


## Onde a pergunta cai: embaixo da raia, dentro da tela.
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


## Lado a lado, na ordem das raias: da esquerda para a direita empurra para a
## direita o que encosta; da direita para a esquerda, devolve o que passou da
## tela.
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
		# o texto não passa da margem da esquerda nem quando a fila se aperta
		b.position.x = maxf(b.position.x, esq)
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
			borda = cor_id  # o acerto é a cor de quem acertou
		elif certa >= 0 and i == escolhida:
			borda = Tema.MUDO  # o erro não tem cor (02, «O erro»)
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
		# a letra não encolhe (nada abaixo de 30 px): a palavra que não cabe fecha com «…»
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
	# G04: o deck do HUD é o relógio da faixa; aqui fica só a linha de progresso da sala sem relógio
	var q := _rect_progresso()
	if q.size.x > 0.0:
		Desenho.placa(self, q)
		Desenho.texto(self, q.position + Vector2(28, 36), str(sala.progresso()), Tema.archivo(500), Tema.T_SELO, Tema.ETIQUETA)


## A linha de progresso (sala sem relógio): uma placa centrada em y 214, de 52 de altura. Vazia sem linha.
func _rect_progresso() -> Rect2:
	if sala == null or not is_instance_valid(sala) or not sala is SalaJogo or float(sala.duracao) > 0.0:
		return Rect2()
	var linha := str(sala.progresso())
	if linha == "":
		return Rect2()
	var lw := Desenho.largura(linha, Tema.archivo(500), Tema.T_SELO) + 56.0
	return Rect2(Vector2((size.x - lw) * 0.5, 214.0), Vector2(lw, 52.0))


## O selo do treino: uma placa centrada em y 282, de 56 de altura. Vazia fora do treino.
func _rect_selo() -> Rect2:
	if sala == null or not is_instance_valid(sala) or not sala is SalaJogo or not sala.treinando or _do_kit():
		return Rect2()
	var w := Desenho.largura("Treino — não vale ponto", Tema.archivo(600), Tema.T_ROTULO) + 56.0
	return Rect2(Vector2((size.x - w) * 0.5, 282.0), Vector2(w, 56.0))


## As caixas que o painel ocupa na fase de jogo (a linha de progresso e o selo, quando aparecem): a prova
## confere, com as do HUD, que nenhuma encosta.
func retangulos() -> Array:
	var r: Array = []
	if sala == null or not is_instance_valid(sala) or not sala is SalaJogo or str(sala.fase) != "jogo":
		return r
	for q in [_rect_progresso(), _rect_selo()]:
		if q.size.x > 0.0:
			r.append(q)
	return r


## O selo do treino no alto, e o "Valendo!" grande quando ele acaba.
func _treino_e_valendo() -> void:
	if sala.treinando and _do_kit():
		pass  # o treino do kit é a linha do J-card (G12)
	elif sala.treinando:
		var s := "Treino — não vale ponto"
		var f := Tema.archivo(600)
		var r := _rect_selo()
		Desenho.placa(self, r)
		Desenho.texto(self, r.position + Vector2(28, 38), s, f, Tema.T_ROTULO, Tema.ETIQUETA)
	elif float(sala.valendo_t) > 0.0:
		var k: float = 1.4 - float(sala.valendo_t)
		var escala := 1.0 + 0.35 * maxf(0.0, 1.0 - k / 0.25)
		var alfa := clampf(float(sala.valendo_t) / 0.4, 0.0, 1.0)
		var s2 := "Valendo!"
		var f2 := Tema.bungee()
		var tam := int(Tema.T_DISPLAY * escala)
		var w2 := Desenho.largura(s2, f2, tam)
		# a placa atrás: a arena é clara e a palavra, sozinha, some nela; a placa
		# esvazia antes do texto, para a palavra não ficar sem fundo ao sumir
		var placa := _rect_valendo()
		var alfa_placa := 0.92 * clampf(alfa * 2.5, 0.0, 1.0)
		Desenho.moldura(self, placa, Color(Tema.CASCO, alfa_placa), Color(Tema.GRAFITE, alfa_placa), 2, Tema.RAIO_QUADRO)
		Desenho.texto(self, Vector2((size.x - w2) * 0.5, size.y * 0.42), s2, f2, tam, Color(Tema.ETIQUETA, alfa))


## A placa do «Valendo!» (no tamanho cheio dele, com o folguedo do pulo): vazia
## quando a palavra não está na tela. As dicas que cairiam em cima dela esperam.
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


# ---------------------------------------------------------------- a cortina e o J-card do kit (G12) --
## A cortina diagonal da fita (arte/06): o polígono na tinta da seção, a trama, a tira `FITA` e o fio `ETIQUETA`,
## com o verbo carimbado no tempo 1. Os instantes são os ms da `SalaJogo.ms_da_entrada()` (0 = a cortina começa).
const CORTINA := [Vector2(0, 0), Vector2(1240, 0), Vector2(930, 1080), Vector2(0, 1080)]
const CORTINA_DE := -330.0  ## a borda de cima começa aqui e varre até 1240 em 600 ms
const CORTINA_X := 1240.0
const CORTINA_PE := 310.0  ## o quanto a borda de baixo fica à esquerda da de cima
const TIRA := 26.0
const FIO_VAO := 22.0
const FIO := 4.0
const VERBO_CENTRO := Vector2(905, 560)
const VERBO_GRAUS := -2.58  ## −0,045 rad
const VERBO_MAX := 252
const VERBO_MIN := 160
const VERBO_LARGURA := 1100.0
const TREMOR := 8.0
const TREMOR_QUADROS := 4
## O J-card do minigame (arte/06): 1064 × 830 em (760, 90); entra da direita em 1 batida e sai em 1 colcheia.
const JCARD_KIT := Rect2(760, 90, 1064, 830)
const JCARD_DE := 1100.0
const CHIP := Vector2(400, 64)
const CHIP_VAO := 16.0
const COMO_JOGAR_GLIFO := 64.0
## A frase do gênero da FICHA (a caixa do J-card).
const GENERO_FRASE := {"tct": "Todos contra todos", "2v2": "Dupla contra dupla", "coop": "Todos juntos",
	"corrida": "Corrida", "sobrevivencia": "Sobrevivência", "terror": "Terror", "sabotagem": "Sabotagem"}

var _quadro_do_impacto := -1  ## o quadro em que o verbo carimbou (o tremor conta 4 a partir dele)


## O tamanho do verbo na cortina: Bungee 252 se couber em 1100 px; senão, o maior inteiro que caiba, até 160; 0 se
## nem a 160 cabe (o `Minigame.validar` reprova). Mede a palavra como ela sai na tela (traduzida, na escala do texto).
static func tamanho_do_verbo(s: String) -> int:
	var f := Tema.bungee()
	var dito := Traducoes.traduzir(s)
	for tam in range(VERBO_MAX, VERBO_MIN - 1, -1):
		if f.get_string_size(dito, HORIZONTAL_ALIGNMENT_LEFT, -1, Tema.t(tam)).x <= VERBO_LARGURA:
			return tam
	return 0


## A sala é um minigame do kit (a cortina e o J-card no lugar do aviso de antes).
func _do_kit() -> bool:
	return sala != null and is_instance_valid(sala) and sala is Minigame and bool(sala.com_entrada)


## A seção da sala pelo slot («S01_J01» dá 1; o minigame de prova, «T00_J00», dá 0).
func _secao() -> int:
	var slot := str(sala.id)
	return int(slot.substr(1, 2)) if slot.length() >= 3 and slot.substr(1, 2).is_valid_int() else 0


## A etiqueta da faixa que o HUD imprimiu para esta sala («LADO A · FAIXA 01»); fora de uma partida, a faixa 01.
func _impresso() -> String:
	for c in get_parent().get_children() if get_parent() else []:
		if c is HudJogo and str((c as HudJogo).etiqueta.get("impresso", "")) != "":
			return str((c as HudJogo).etiqueta.impresso)
	return "LADO A · FAIXA 01"


static func _entra(k: float) -> float:
	var x := clampf(k, 0.0, 1.0)
	return x * x * x


static func _sai(k: float) -> float:
	var x := 1.0 - clampf(k, 0.0, 1.0)
	return 1.0 - x * x * x


func _entrada() -> void:
	var ms: float = sala.ms_da_entrada()
	if ms < 0.0:
		_quadro_do_impacto = -1
		return
	var impacto := SalaJogo.ENTRADA_ANTES * 1000.0
	var saida: float = sala.ms_da_saida()
	var n := _secao()
	var tinta := Tema.tinta_da_secao(n)
	var borda := lerpf(CORTINA_DE, CORTINA_X, _entra(ms / impacto))
	var fora := _entra(saida / float(sala.ms_da_batida())) * size.x if saida >= 0.0 else 0.0
	var off := Vector2(borda - CORTINA_X + fora, 0.0)
	# o tremor do impacto: 8 px por 4 quadros (nenhum no Movimento Reduzido)
	if ms >= impacto and _quadro_do_impacto < 0:
		_quadro_do_impacto = Engine.get_process_frames()
	var q := Engine.get_process_frames() - _quadro_do_impacto
	if _quadro_do_impacto >= 0 and q < TREMOR_QUADROS and not Opcoes.reduzido():
		off += Vector2(TREMOR if q % 2 == 0 else -TREMOR, -TREMOR if q % 2 == 0 else TREMOR)
	var coleta := Desenho.coletar_retangulos
	Desenho.coletar_retangulos = false  # a cortina passa; a prova visual mede o J-card parado
	_cortina(off, tinta)
	# as duas linhas pequenas: aparecem quando a borda passa delas
	var cor := Tema.TINTA if n in [0, 3, 4, 7] else Tema.ETIQUETA
	var linha := "%s · %d BPM" % [_impresso(), roundi(Ritmo.bpm)]
	var fv := Tema.vt()
	var fm := Tema.marcador()
	if borda - CORTINA_PE * 120.0 / 1080.0 >= 110.0 + Desenho.largura(linha, fv, 56):
		Desenho.texto(self, Vector2(110, 120) + off, linha, fv, 56, cor)
	var titulo := Desenho.caber(str(sala.nome), fm, 72, 900.0, 1)
	if borda - CORTINA_PE * 186.0 / 1080.0 >= 104.0 + Desenho.largura(titulo, fm, 72):
		Desenho.texto(self, Vector2(104, 186) + off, titulo, fm, 72, cor)
	# o verbo: carimba no tempo 1 (escala 1,35 a 1,0 em 80 ms, MOLA), com dois ecos até os 900 ms
	if ms >= impacto:
		var verbo := str(sala.acao)
		var tam := maxi(tamanho_do_verbo(verbo), VERBO_MIN)
		var k := clampf((ms - impacto) / 80.0, 0.0, 1.0)
		var escala := lerpf(1.35, 1.0, float(Tween.interpolate_value(0.0, 1.0, k, 1.0, Tween.TRANS_BACK, Tween.EASE_OUT)))
		var centro := VERBO_CENTRO + off
		if ms < impacto + SalaJogo.ENTRADA_SEGURA * 1000.0:
			Desenho.carimbo(self, centro, verbo, Tema.ETIQUETA, tam, VERBO_GRAUS, escala * 1.14, 0.08, false)
			Desenho.carimbo(self, centro, verbo, Tema.ETIQUETA, tam, VERBO_GRAUS, escala * 1.07, 0.16, false)
		Desenho.carimbo(self, centro, verbo, Tema.ETIQUETA, tam, VERBO_GRAUS, escala, 1.0, false)
	Desenho.coletar_retangulos = coleta
	# o J-card entra junto da saída da cortina
	if saida >= 0.0:
		_jcard()


## O polígono chapado, a trama (2 px a cada 6, na tinta a ×0,88 de luz), a tira e o fio da borda.
func _cortina(off: Vector2, tinta: Color) -> void:
	var pts := PackedVector2Array()
	for p in CORTINA:
		pts.append(p + off)
	draw_colored_polygon(pts, tinta)
	var escura := Color(tinta.r * 0.88, tinta.g * 0.88, tinta.b * 0.88)
	for y in range(0, 1080, 6):
		draw_rect(Rect2(Vector2(off.x, y + off.y), Vector2(CORTINA_X - CORTINA_PE * y / 1080.0, 2.0)), escura)
	var tira := PackedVector2Array([Vector2(CORTINA_X, 0), Vector2(CORTINA_X + TIRA, 0),
		Vector2(CORTINA_X - CORTINA_PE + TIRA, 1080), Vector2(CORTINA_X - CORTINA_PE, 1080)])
	for i in tira.size():
		tira[i] += off
	draw_colored_polygon(tira, Tema.FITA)
	var x0 := CORTINA_X + TIRA + FIO_VAO
	draw_colored_polygon(PackedVector2Array([Vector2(x0, 0) + off, Vector2(x0 + FIO, 0) + off,
		Vector2(x0 + FIO - CORTINA_PE, 1080) + off, Vector2(x0 - CORTINA_PE, 1080) + off]), Tema.ETIQUETA)


## O quanto o J-card está à direita do lugar dele: entra em 1 batida depois da cortina sair (`SAI`), fica parado no
## aviso e no treino, e sai em 1 colcheia (`ENTRA`) quando o treino acaba (ou em `comecar()`, sem treino).
func _jcard_fora() -> float:
	var batida := float(sala.ms_da_batida()) / 1000.0
	match str(sala.fase):
		"entrada":
			return JCARD_DE * (1.0 - _sai(float(sala.ms_da_saida()) / 1000.0 / batida))
		"aviso":
			return 0.0
		"jogo":
			if sala.treinando:
				return 0.0
			var passou := 1.4 - float(sala.valendo_t) if sala.com_treino else float(sala.t_fase)
			if sala.com_treino and float(sala.valendo_t) <= 0.0:
				return JCARD_DE
			return JCARD_DE * _entra(passou / (batida * 0.5))
	return JCARD_DE


func _jcard() -> void:
	var dx := _jcard_fora()
	if dx >= JCARD_DE - 0.5:
		return
	var r := Rect2(JCARD_KIT.position + Vector2(dx, 0), JCARD_KIT.size)
	var coleta := Desenho.coletar_retangulos
	if dx > 0.5:
		Desenho.coletar_retangulos = false  # o cartão que ainda corre: a prova visual mede o parado
	var n := _secao()
	var tinta := Tema.tinta_da_secao(n)
	var impresso := _impresso()
	var lado := impresso.get_slice(" · ", 0)  # «LADO A»
	var faixa := impresso.right(2)
	var lombada := "%s%d · %s · %s" % ["S" if n > 0 else "T", n, Traducoes.traduzir(str(sala.nome)).to_upper(), lado]
	Desenho.jcard(self, r, tinta, Desenho.caber(lombada, Tema.vt(), 46, r.size.y - 80.0, 1))
	Desenho.inclinar(self, r.get_center(), Desenho.JCARD_INCLINACAO)
	var x0 := r.position.x + Desenho.JCARD_LOMBADA + 44.0
	var x1 := r.end.x - 44.0
	var w := x1 - x0
	var fv := Tema.vt()
	var y := r.position.y + 38.0 + 14.0
	# a seção
	if n > 0 and n <= Catalogo.SECOES.size():
		y += fv.get_ascent(Tema.t(40))
		Desenho.texto(self, Vector2(x0, y), Traducoes.traduzir(str(Catalogo.SECOES[n - 1].nome)).to_upper(), fv, 40, Tema.TINTA_SUAVE)
		y += fv.get_descent(Tema.t(40)) + 4.0
	# o título, à caneta
	var fm := Tema.marcador()
	var tam_titulo := 60 if Desenho.t(str(sala.nome)).length() > 22 else 74
	y += fm.get_ascent(Tema.t(tam_titulo))
	Desenho.texto(self, Vector2(x0, y), Desenho.caber(str(sala.nome), fm, tam_titulo, w, 1), fm, tam_titulo, Tema.TINTA)
	y += fm.get_descent(Tema.t(tam_titulo)) + 8.0
	# o gênero numa caixa com a borda na tinta; à direita, o lado e o número da faixa
	var fg := Tema.archivo(700)
	var genero := str(GENERO_FRASE.get(str(sala.ficha.get("genero", "")), ""))
	var alto := maxf(54.0, fg.get_height(Tema.t(34)) + 10.0)
	if genero != "":
		var caixa := Rect2(Vector2(x0, y), Vector2(maxf(330.0, Desenho.largura(genero, fg, 34) + 40.0), alto))
		Desenho.caixa(self, caixa, Color(Tema.ETIQUETA, 0.0), Tema.RAIO_ETIQUETA, tinta, 3)
		Desenho.texto(self, Vector2(caixa.position.x + 20.0, caixa.get_center().y + fg.get_ascent(Tema.t(34)) * 0.36), genero, fg, 34, Tema.TINTA)
	var base := y + alto
	var lw := Desenho.largura(faixa, fv, 64)
	Desenho.texto(self, Vector2(x1 - lw, base), faixa, fv, 64, Tema.TINTA)
	Desenho.texto(self, Vector2(x1 - lw - 16.0 - Desenho.largura(lado, fv, 40), base), lado, fv, 40, Tema.TINTA_SUAVE)
	y = base + 20.0
	# como jogar; à direita, a linha do treino
	y += fv.get_ascent(Tema.t(40))
	Desenho.texto(self, Vector2(x0, y), "Como jogar", fv, 40, Tema.TINTA_SUAVE)
	if sala.com_treino:
		var tr := "Treino · não vale ponto"
		Desenho.texto(self, Vector2(x1 - Desenho.largura(tr, fv, 40), y), tr, fv, 40, Tema.TINTA)
	y += fv.get_descent(Tema.t(40)) + 6.0
	var fc := Tema.archivo(600)
	var y_chips := r.end.y - 44.0 - CHIP.y * 2.0 - CHIP_VAO
	var y_comeca := y_chips - 12.0 - Desenho.LADO_DA_DICA
	var pares: Array = sala.ficha.get("como_jogar", [])
	var linha := clampf((y_comeca - 10.0 - y) / maxf(1.0, pares.size()), COMO_JOGAR_GLIFO, COMO_JOGAR_GLIFO + 16.0)
	for i in pares.size():
		var par: Array = pares[i]
		if i > 0:
			draw_line(Vector2(x0, y), Vector2(x1, y), Tema.ETIQUETA_SOMBRA, 2.0)
		var meio := y + linha * 0.5
		var tex := Desenho.glifo(str(par[0]))
		if tex:
			draw_texture_rect(tex, Rect2(Vector2(x0, meio - COMO_JOGAR_GLIFO * 0.5), Vector2(COMO_JOGAR_GLIFO, COMO_JOGAR_GLIFO)), false, Tema.TINTA)
		var xf := x0 + COMO_JOGAR_GLIFO + 20.0
		Desenho.texto(self, Vector2(xf, meio + fc.get_ascent(Tema.t(44)) * 0.36), Desenho.caber(str(par[1]), fc, 44, x1 - xf, 1), fc, 44, Tema.TINTA)
		y += linha
	# no aviso: quanto falta para começar, e o ✕ do pronto
	if str(sala.fase) == "aviso":
		var resta := maxi(1, ceili(SalaJogo.AVISO_MAX - float(sala.t_fase)))
		Desenho.texto(self, Vector2(x0, y_comeca + Desenho.LADO_DA_DICA * 0.5 + fc.get_ascent(Tema.t(34)) * 0.36), "Começa em %d" % resta, fc, 34, Tema.TINTA)
		var lp := Desenho.LADO_DA_DICA + 12.0 + Desenho.largura("Pronto", fc, 34)
		Desenho.dica(self, Vector2(x1 - lp, y_comeca), "cruz", "Pronto", true)
	# os chips, 2 × 2, um por lugar ocupado: pronto no aviso, ou o treino de cada um
	var i := 0
	for l in 4:
		if not Forja.ocupado(l):
			continue
		var pos := Vector2(x0 + (i % 2) * (CHIP.x + CHIP_VAO), y_chips + (i / 2) * (CHIP.y + CHIP_VAO))
		var pronto: bool = sala.prontos[l] if str(sala.fase) != "jogo" else bool(sala._treino_ok[l])
		var palavra := "Pronto" if pronto else ("Treinando" if str(sala.fase) == "jogo" else "Aguardando")
		Desenho.chip(self, Rect2(pos, CHIP), l, pronto, palavra)
		i += 1
	Desenho.inclinar(self, Vector2.ZERO, 0.0)
	Desenho.coletar_retangulos = coleta
