class_name Livro
extends Control
## O livro da sessão: o relatório na tela. Cada linha é uma feature, cada
## coluna um lugar; a célula diz o veredito com ícone e palavra (passou,
## falhou, não medido — este com forma própria). A célula escolhida abre à
## direita: o que foi pedido, o que foi medido e o degrau da evidência. O mesmo
## conteúdo está gravado em relatorio-<sessão>.json e .txt, ao lado do jogo.

const NIVEIS := ["—", "montou o pedido", "o SDL aceitou", "a pessoa sentiu, às cegas", "o jogo leu de volta"]

var linha := 0
var coluna := 0
var _linhas: Array = []  # [{tipo: "sala"|"feature", ...}]
var _rolagem := 0.0

const ALTURA := 46.0
const TOPO := 236.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func abrir() -> void:
	_linhas.clear()
	var salas := Forja.salas()
	var feats := Forja.features()
	for s in salas:
		_linhas.append({"tipo": "sala", "nome": s.nome})
		for f in feats:
			if int(f.sala) == int(s.id):
				_linhas.append({"tipo": "feature", "chave": f.chave, "nome": f.nome})
	linha = _proxima_feature(0, 1)
	coluna = 0
	for l in 4:
		if Forja.ocupado(l):
			coluna = l
			break


func _proxima_feature(de: int, passo: int) -> int:
	var i := de
	for _n in _linhas.size():
		if i >= 0 and i < _linhas.size() and _linhas[i].tipo == "feature":
			return i
		i = wrapi(i + passo, 0, _linhas.size())
	return 0


## A navegação: qualquer lugar mexe (o d-pad ou o analógico).
func navegar(dx: int, dy: int) -> void:
	if dy != 0 and not _linhas.is_empty():
		linha = _proxima_feature(wrapi(linha + dy, 0, _linhas.size()), dy)
	if dx != 0:
		coluna = wrapi(coluna + dx, 0, 4)


func _process(_dt: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.FITA, 0.95))
	Desenho.texto(self, Vector2(Tema.MARGEM_X, 118), "O livro da sessão", Tema.bungee(), Tema.T_TITULO, Tema.ETIQUETA)
	var sessao := Forja.sessao()
	var sub := "sessão %s  ·  gravado ao lado do jogo em relatorio-%s.json e .txt" % [sessao, sessao] if sessao != "" \
		else "sem o módulo nativo, nada é medido nem gravado"
	Desenho.texto(self, Vector2(Tema.MARGEM_X, 164), sub, Tema.vt(), Tema.T_MONO, Tema.ETIQUETA_SOMBRA, HORIZONTAL_ALIGNMENT_LEFT, size.x - 2 * Tema.MARGEM_X)

	var x0 := float(Tema.MARGEM_X)
	# a coluna cabe "não medido" a 30 px; o detalhe fica com o que sobra
	var larg_feat := 420.0
	var larg_cel := 214.0
	# o cabeçalho das colunas
	for l in 4:
		var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
		var xc := x0 + larg_feat + l * larg_cel
		var ocupado := Forja.ocupado(l)
		Desenho.texto(self, Vector2(xc + 16, TOPO - 20), "P%d" % (l + 1), Tema.bungee(), Tema.T_ROTULO, cor_id if ocupado else Tema.MUDO)
	draw_line(Vector2(x0, TOPO - 6), Vector2(x0 + larg_feat + 4 * larg_cel, TOPO - 6), Tema.GRAFITE, 2)

	# as linhas (rolando para a escolhida ficar à vista)
	var visiveis := int((size.y - TOPO - 120) / ALTURA)
	var alvo := clampf(linha - visiveis * 0.5, 0, maxf(0, _linhas.size() - visiveis))
	_rolagem = lerpf(_rolagem, alvo, 0.25)
	var primeira := int(_rolagem)
	for i in range(primeira, mini(_linhas.size(), primeira + visiveis)):
		var y := TOPO + (i - primeira) * ALTURA
		var item: Dictionary = _linhas[i]
		if item.tipo == "sala":
			Desenho.texto(self, Vector2(x0, y + 34), item.nome, Tema.archivo(600), Tema.T_SELO, Tema.ETIQUETA)
			continue
		var tg := Desenho.glifo(Desenho.GLIFO_DA_FEATURE.get(item.chave, ""))
		if tg:
			draw_texture_rect(tg, Rect2(Vector2(x0 + 8, y + 8), Vector2(30, 30)), false, Tema.ETIQUETA_SOMBRA)
		Desenho.texto(self, Vector2(x0 + 50, y + 32), item.nome, Tema.archivo(500), Tema.T_ROTULO, Tema.ETIQUETA, HORIZONTAL_ALIGNMENT_LEFT, larg_feat - 60)
		for l in 4:
			var xc := x0 + larg_feat + l * larg_cel
			var cel := Rect2(Vector2(xc + 4, y + 4), Vector2(larg_cel - 8, ALTURA - 8))
			if i == linha and l == coluna:
				Desenho.moldura(self, cel, Tema.CASCO_ALTO, Tema.tom_para_a_borda(Forja.cor_do_lugar(coluna)), 3, 8)
			_celula(cel, Forja.ultimo_veredito(l, item.chave) if Forja.ocupado(l) else {}, Forja.ocupado(l))

	# o detalhe da célula escolhida
	var dr := Rect2(Vector2(x0 + larg_feat + 4 * larg_cel + 40, TOPO - 40), Vector2(0, 0))
	dr.size = Vector2(size.x - Tema.MARGEM_X - dr.position.x, size.y - dr.position.y - 120)
	Desenho.moldura(self, dr, Tema.CASCO, Tema.GRAFITE, 2, Tema.RAIO_QUADRO)
	if not _linhas.is_empty() and _linhas[linha].tipo == "feature":
		var item2: Dictionary = _linhas[linha]
		var v: Dictionary = Forja.ultimo_veredito(coluna, item2.chave) if Forja.ocupado(coluna) else {}
		var px := dr.position.x + 28
		var py := dr.position.y + 56
		Desenho.texto(self, Vector2(px, py), item2.nome, Tema.archivo(600), Tema.T_CORPO, Tema.ETIQUETA, HORIZONTAL_ALIGNMENT_LEFT, dr.size.x - 56)
		py += 40
		Desenho.texto(self, Vector2(px, py), "P%d" % (coluna + 1), Tema.bungee(), Tema.T_ROTULO, Tema.tom_para_a_borda(Forja.cor_do_lugar(coluna)))
		py += 56
		if v.is_empty():
			Desenho.texto(self, Vector2(px, py), "Não medido.", Tema.archivo(600), Tema.T_ROTULO, Tema.MUDO)
			py += 40
			var onde := ""
			for f in Forja.features():
				if f.chave == item2.chave:
					onde = f.sala_nome
			if onde != "":
				Desenho.texto(self, Vector2(px, py), "Quem mede é %s." % onde, Tema.archivo(500), Tema.T_ROTULO, Tema.ETIQUETA_SOMBRA, HORIZONTAL_ALIGNMENT_LEFT, dr.size.x - 56)
			return
		var res := int(v.get("resultado", 0))
		var cor: Color = [Tema.MUDO, Tema.ETIQUETA, Tema.SECAO[0]][clampi(res, 0, 2)]
		var palavra: String = ["— NÃO MEDIDO", "✓ PASSOU", "✗ FALHOU"][clampi(res, 0, 2)]
		Desenho.selo(self, Vector2(px, py - 30), palavra, cor)
		py += 60
		var campos := [
			["Evidência", NIVEIS[clampi(int(v.get("nivel", 0)), 0, 4)]],
			["Pedido", str(v.get("pedido", ""))],
			["Medido", str(v.get("medido", ""))],
			["Observação", str(v.get("obs", ""))],
		]
		for c in campos:
			if str(c[1]) == "":
				continue
			if py > dr.end.y - 60:
				break
			Desenho.texto(self, Vector2(px, py), c[0], Tema.archivo(600), Tema.T_SELO, Tema.ETIQUETA)
			py += Tema.t(Tema.T_SELO) * 1.3
			py = _paragrafo(Vector2(px, py), str(c[1]), dr.size.x - 56, dr.end.y - 24)
			py += 14

	Desenho.dicas_a_direita(self, Vector2(size.x - Tema.MARGEM_X, size.y - Tema.MARGEM_Y), [["cima", "Linha"], ["esquerda", "Lugar"], ["circulo", "Fechar"]], Tema.T_SELO)


func _celula(r: Rect2, v: Dictionary, ocupado: bool) -> void:
	var y := r.position.y + r.size.y * 0.5 + 11
	var x := r.position.x + 12
	if not ocupado:
		Desenho.texto(self, Vector2(x, y), "·", Tema.archivo(600), Tema.T_SELO, Tema.MUDO)
		return
	var res := int(v.get("resultado", 0)) if not v.is_empty() else 0
	match res:
		1:
			Desenho.texto(self, Vector2(x, y), "✓ passou", Tema.archivo(600), Tema.T_SELO, Tema.ETIQUETA)
		2:
			Desenho.texto(self, Vector2(x, y), "✗ falhou", Tema.archivo(600), Tema.T_SELO, Tema.SECAO[0])
		_:
			# não medido tem forma própria: o anel vazado, e a palavra apagada
			draw_arc(Vector2(x + 8, y - 8), 7, 0, TAU, 20, Tema.MUDO, 2, true)
			Desenho.texto(self, Vector2(x + 24, y), "não medido", Tema.archivo(500), Tema.T_SELO, Tema.MUDO)


## Um parágrafo quebrado na largura (até 80 caracteres por linha, entrelinha
## de 1,5: o estudo 02, item 30); devolve o y depois dele. O que passa do
## `fundo` vira reticências: o texto inteiro está no relatório.
func _paragrafo(pos: Vector2, texto: String, largura: float, fundo: float) -> float:
	var f := Tema.archivo(500)
	var tam := Tema.T_ROTULO
	var passo := Tema.t(tam) * 1.5
	largura = minf(largura, Desenho.largura("n".repeat(80), f, tam))
	var palavras := texto.split(" ")
	var atual := ""
	var y := pos.y
	for p in palavras:
		var teste := p if atual == "" else atual + " " + p
		if Desenho.largura(teste, f, tam) > largura and atual != "":
			if y + 2 * passo > fundo:
				Desenho.texto(self, Vector2(pos.x, y), Desenho.caber(atual + " …", f, tam, largura, 1), f, tam, Tema.ETIQUETA)
				return y + passo
			Desenho.texto(self, Vector2(pos.x, y), atual, f, tam, Tema.ETIQUETA)
			y += passo
			atual = p
		else:
			atual = teste
	if atual != "":
		Desenho.texto(self, Vector2(pos.x, y), atual, f, tam, Tema.ETIQUETA)
		y += passo
	return y
