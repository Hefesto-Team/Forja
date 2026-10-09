class_name TelaResultado
extends Control
## O resultado de toda sala que fecha: o nome da sala, quem venceu numa frase
## e a colocação dos que jogaram, com os pontos. É a mesma tela para todos, com
## robô ou com gente: o apito toca em 0 s, o resultado vale a partir de
## APITO_S e a sala volta sozinha em AVANCA_S (o ✕ pula).
##
## No Modo bancada, a tabela de veredito de cada lugar vem embaixo do quadro.

const APITO_S := 0.5
const AVANCA_S := 6.0

var colocacao: Array = []  ## os lugares, do primeiro ao último
var pontos: Array = [0, 0, 0, 0]
var coop := false
var coop_venceu := false
var titulo := ""  ## o nome da sala
var frase := ""  ## a frase do vencedor que o minigame dá (coop, dupla); vazia: a de sempre
var sala_da_bancada: SalaJogo = null  ## só no Modo bancada: a tabela de veredito embaixo

var _t := 0.0

const LARG := 900.0
const COL_NOME := 440.0
const COLUNA := 300.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func abrir(col: Array, pts: Array, eh_coop := false, venceu := false, nome := "", frase_do_minigame := "") -> void:
	frase = frase_do_minigame
	colocacao = col.duplicate()
	pontos = pts.duplicate()
	coop = eh_coop
	coop_venceu = venceu
	titulo = nome
	_t = 0.0
	visible = true
	queue_redraw()


func fechar() -> void:
	visible = false
	sala_da_bancada = null
	colocacao = []


func _process(dt: float) -> void:
	if not visible:
		return
	_t += dt
	queue_redraw()


## O nome de uma feature do catálogo, como a tela o diz.
static func nome_da_feature(chave: String) -> String:
	for f in Forja.features():
		if f.chave == chave:
			return f.nome
	return chave


## Quantos lugares dividem o primeiro posto (0 sem ninguém).
func _empatados_no_topo() -> int:
	if colocacao.is_empty():
		return 0
	var n := 0
	for l in colocacao:
		if int(pontos[l]) == int(pontos[colocacao[0]]):
			n += 1
	return n


## A frase de quem venceu e a cor dela.
func _frase() -> Array:
	if frase != "":
		# a do minigame (coop, dupla); a derrota do coop na cor de sempre da derrota
		return [frase, Tema.SECAO[3] if coop and not coop_venceu else Tema.ETIQUETA]
	if coop:
		return ["Vocês venceram!", Tema.ETIQUETA] if coop_venceu else ["Não deu desta vez.", Tema.SECAO[3]]
	if colocacao.is_empty():
		return ["", Tema.ETIQUETA]
	var n := _empatados_no_topo()
	if n == 2:
		return ["P%d e P%d empatam!" % [int(colocacao[0]) + 1, int(colocacao[1]) + 1], Tema.ETIQUETA]
	if n >= 3:
		return ["Empate!", Tema.ETIQUETA]
	var l: int = colocacao[0]
	return ["P%d venceu!" % (l + 1), Tema.tom_para_a_borda(Forja.cor_do_lugar(l))]


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.FITA, 0.6))
	var n := colocacao.size()
	var compacto := sala_da_bancada != null
	var alt_primeira := 60.0 if compacto else 84.0
	var alt_linha := 48.0 if compacto else 64.0
	var alt := 190.0 + 40.0
	if n > 0:
		alt += alt_primeira + alt_linha * (n - 1)
	var alt_tabela := 0.0
	if compacto:
		alt_tabela = _altura_da_tabela()
	var total := alt + (24.0 + alt_tabela if compacto else 0.0)
	# o quadro da HUD ocupa o alto: com a tabela embaixo, o resultado desce abaixo dele
	var topo := maxf(170.0 if compacto else 24.0, (size.y - total) * 0.5)
	var r := Rect2(Vector2((size.x - LARG) * 0.5, topo), Vector2(LARG, alt))
	Desenho.moldura(self, r, Color(Tema.CASCO, 0.97), Tema.GRAFITE, 2, Tema.RAIO_QUADRO)
	Desenho.texto(self, r.position + Vector2(48, 84), titulo, Tema.bungee(), Tema.T_TITULO, Tema.ETIQUETA)
	var dita := _frase()
	if str(dita[0]) != "":
		Desenho.texto(self, r.position + Vector2(48, 148), str(dita[0]), Tema.archivo(700), Tema.T_CORPO + 8, dita[1],
			HORIZONTAL_ALIGNMENT_LEFT, LARG - 96)
	var cols := Partida.colocacoes(pontos, colocacao)
	var y := r.position.y + 190.0
	for i in n:
		var l: int = colocacao[i]
		var h := alt_primeira if i == 0 else alt_linha
		var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
		var tam_nome := Tema.T_CORPO + (8 if i == 0 else 0)
		var base := y + h * 0.5 + tam_nome * 0.36
		Desenho.texto(self, Vector2(r.position.x + 48, base), "%dº" % int(cols[l]), Tema.vt(), tam_nome, Tema.ETIQUETA_SOMBRA)
		Desenho.texto(self, Vector2(r.position.x + 170, base), "P%d" % (l + 1), Tema.bungee(), tam_nome, cor_id)
		Desenho.texto(self, Vector2(r.position.x + 300, base), "%d" % int(pontos[l]), Tema.vt(), tam_nome, Tema.ETIQUETA)
		y += h
	if _t >= 0.8:
		Desenho.dicas_a_direita(self, Vector2(r.end.x - 48, r.position.y + 84), [["cruz", "Continuar"]], Tema.T_ROTULO)
	if compacto:
		_tabela(Rect2(Vector2((size.x - maxf(LARG, _largura_da_tabela())) * 0.5, r.end.y + 24.0),
			Vector2(maxf(LARG, _largura_da_tabela()), alt_tabela)))


# ------------------------------------------------------------ a tabela --
# O veredito enxuto do Modo bancada: uma linha por feature (o glifo e o nome),
# uma coluna por lugar; na célula, o selo com ícone e palavra. O porquê só
# aparece no que não passou — o resto mora no livro da sessão.

func _lugares_da_tabela() -> Array:
	var lugares: Array = []
	for l in 4:
		if sala_da_bancada.vereditos.has(l):
			lugares.append(l)
	return lugares


func _largura_da_tabela() -> float:
	return 96.0 + COL_NOME + COLUNA * _lugares_da_tabela().size()


func _alturas_da_tabela() -> Array:
	var lugares := _lugares_da_tabela()
	var linhas: Array = []  # as features, com a altura de cada linha
	for f in sala_da_bancada.features:
		var alta := false
		for l in lugares:
			var v := _veredito_de(l, f)
			if not v.is_empty() and int(v.get("resultado", 0)) != Forja.PASSOU:
				alta = true
		linhas.append([f, 156.0 if alta else 76.0])
	return linhas


func _altura_da_tabela() -> float:
	var alt := 100.0
	for li in _alturas_da_tabela():
		alt += li[1]
	return alt


func _tabela(r: Rect2) -> void:
	var lugares := _lugares_da_tabela()
	var linhas := _alturas_da_tabela()
	Desenho.moldura(self, r, Color(Tema.CASCO, 0.97), Tema.GRAFITE, 2, Tema.RAIO_QUADRO)
	var x0 := r.position.x + 48 + COL_NOME
	for i in lugares.size():
		var l: int = lugares[i]
		var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
		var x := x0 + i * COLUNA
		Desenho.texto(self, Vector2(x, r.position.y + 62), "P%d" % (l + 1), Tema.bungee(), Tema.T_CORPO, cor_id)
		Desenho.texto(self, Vector2(x + 60, r.position.y + 62), "%d" % sala_da_bancada.pontos[l], Tema.vt(), Tema.T_MONO, Tema.ETIQUETA_SOMBRA)
	var y := r.position.y + 90
	for li in linhas:
		var f: String = li[0]
		var tex := Desenho.glifo(Desenho.GLIFO_DA_FEATURE.get(f, ""))
		if tex:
			draw_texture_rect(tex, Rect2(Vector2(r.position.x + 48, y + 8), Vector2(40, 40)), false, Tema.ETIQUETA)
		var nome := nome_da_feature(f)
		Desenho.texto(self, Vector2(r.position.x + 100, y + 40), Desenho.caber(nome, Tema.archivo(500), Tema.T_ROTULO, COL_NOME - 76, 1),
			Tema.archivo(500), Tema.T_ROTULO, Tema.ETIQUETA)
		for i in lugares.size():
			var v := _veredito_de(lugares[i], f)
			if v.is_empty():
				continue
			var x := x0 + i * COLUNA
			var res := clampi(int(v.get("resultado", 0)), 0, 2)
			var cor: Color = [Tema.MUDO, Tema.ETIQUETA, Tema.SECAO[0]][res]
			var palavra: String = ["— NÃO MEDIDO", "✓ PASSOU", "✗ FALHOU"][res]
			Desenho.selo(self, Vector2(x, y + 10), palavra, cor, Tema.T_SELO)
			if res != 1:
				var porque := str(v.get("obs", "")) if str(v.get("obs", "")) != "" else str(v.get("medido", ""))
				porque = Desenho.caber(porque, Tema.archivo(500), Tema.T_SELO, COLUNA - 24, 2)
				Desenho.paragrafo(self, Vector2(x, y + 70), porque, Tema.archivo(500), Tema.T_SELO, Tema.ETIQUETA_SOMBRA, COLUNA - 24, 2)
		y += li[1]


func _veredito_de(l: int, f: String) -> Dictionary:
	for v in sala_da_bancada.vereditos.get(l, []):
		if str(v.get("feature", "")) == f:
			return v
	return {}
