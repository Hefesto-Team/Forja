class_name Placar
extends Control
## O placar da partida. Entre as salas: a colocação de cada um na sala que
## acabou, os pontos da noite que ela deu e o total, do primeiro ao último, e
## a sala seguinte. No fim: o pódio, com quem venceu a noite numa frase.
## Sempre com o número do lugar e a palavra — nunca só a cor.

var partida: Partida = null
var no_podio := false
var _t := 0.0

const ORDINAL := ["", "1º", "2º", "3º", "4º"]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func abrir(p: Partida, podio: bool) -> void:
	partida = p
	no_podio = podio
	_t = 0.0


## Pronto para o ✕ (o botão que fechou o veredito não passa direto por aqui).
func pronto() -> bool:
	return _t > 0.8


func _process(dt: float) -> void:
	_t += dt
	if visible:
		queue_redraw()


## A frase do pódio: "P2 venceu a noite", ou quem divide o primeiro degrau.
static func frase_do_vencedor(lista: Array) -> String:
	var primeiros: PackedStringArray = []
	for e in lista:
		if int(e.degrau) == 1:
			primeiros.append("P%d" % (int(e.lugar) + 1))
	if primeiros.size() == 1:
		return "%s venceu a noite" % primeiros[0]
	return "%s dividem a noite" % " e ".join(primeiros)


func _draw() -> void:
	if partida == null or partida.historico.is_empty():
		return
	if no_podio:
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, size.y)), Color(Tema.CASA, 0.35))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.APP, 0.86))
	var lista := partida.podio(partida.presentes())
	var ultima: Dictionary = partida.historico[partida.historico.size() - 1]
	var larg := 1180.0
	var linha := 104.0
	var alt := 300.0 + linha * lista.size()
	var r := Rect2(Vector2((size.x - larg) * 0.5, (size.y - alt) * 0.5), Vector2(larg, alt))
	if no_podio:
		# o pódio fica à esquerda: os bonecos nos pedestais aparecem à direita
		r.position = Vector2(Tema.MARGEM_X, (size.y - alt) * 0.5)
		larg = 860.0
		r.size.x = larg
	Desenho.moldura(self, r, Color(Tema.PAINEL, 0.97), Tema.LINHA, 2, Tema.RAIO_QUADRO)
	var x := r.position.x + 48
	if no_podio:
		Desenho.texto(self, Vector2(x, r.position.y + 84), "O pódio", Tema.fonte(700), Tema.T_TITULO, Tema.FG)
		Desenho.texto(self, Vector2(x, r.position.y + 140), frase_do_vencedor(lista), Tema.fonte(600), Tema.T_CORPO, Tema.VERDE)
	else:
		Desenho.texto(self, Vector2(x, r.position.y + 84), "O placar", Tema.fonte(700), Tema.T_TITULO, Tema.FG)
		var depois := "depois d%s · sala %d de %d" % [_contracao(str(ultima.nome)), partida.historico.size(), partida.salas.size()]
		Desenho.texto(self, Vector2(x, r.position.y + 140), depois, Tema.fonte(500), Tema.T_ROTULO, Tema.ROXO)
	# o cabeçalho das colunas
	var y := r.position.y + 206
	var c_total := r.end.x - 48 - 150
	var c_sala := c_total - 300
	if no_podio:
		Desenho.texto(self, Vector2(c_sala, y), "salas vencidas", Tema.fonte(600), Tema.T_SELO, Tema.MUDO)
	else:
		Desenho.texto(self, Vector2(c_sala, y), "nesta sala", Tema.fonte(600), Tema.T_SELO, Tema.MUDO)
	Desenho.texto(self, Vector2(c_total, y), "da noite", Tema.fonte(600), Tema.T_SELO, Tema.MUDO)
	y += 22
	for e in lista:
		var l := int(e.lugar)
		var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
		var b := Rect2(Vector2(x, y), Vector2(larg - 96, linha - 14))
		var primeiro := int(e.degrau) == 1
		Desenho.moldura(self, b, Tema.SEL if primeiro else Tema.APP, cor_id, 3, 12)
		var cy := b.position.y + b.size.y * 0.5 + 12
		Desenho.texto(self, Vector2(b.position.x + 24, cy), ORDINAL[clampi(int(e.degrau), 0, 4)], Tema.fonte(700), Tema.T_CORPO,
			Tema.VERDE if primeiro else Tema.FG)
		Desenho.texto(self, Vector2(b.position.x + 110, cy), "P%d" % (l + 1), Tema.fonte(700), Tema.T_CORPO, cor_id)
		if no_podio:
			Desenho.texto(self, Vector2(c_sala, cy), "%d" % int(e.vitorias), Tema.mono(500), Tema.T_MONO, Tema.SUAVE)
		else:
			var col := int(ultima.colocacao[l])
			var s := "%s  +%d" % [ORDINAL[clampi(col, 0, 4)], int(ultima.ganhos[l])] if col > 0 else "—"
			Desenho.texto(self, Vector2(c_sala, cy), s, Tema.fonte(600), Tema.T_CORPO, Tema.CIANO)
		Desenho.texto(self, Vector2(c_total, cy), "%d" % int(e.total), Tema.mono(700), Tema.T_CORPO, Tema.FG)
		y += linha
	if not pronto():
		return
	if no_podio:
		Desenho.dicas_a_esquerda(self, Vector2(r.position.x + 48, r.end.y + 60),
			[["cruz", "outra partida"], ["circulo", "voltar ao salão"]], Tema.T_ROTULO)
	else:
		var seguinte := partida.sala_atual()
		var texto := "a seguir: %s" % Partida.NOMES.get(seguinte, seguinte) if seguinte != "" else "o pódio"
		Desenho.dicas_a_direita(self, Vector2(r.end.x - 48, r.end.y + 60), [["cruz", texto]], Tema.T_ROTULO)


## "depois d'A Galeria", "depois d'O Impacto", "depois dos Caminhos".
static func _contracao(nome: String) -> String:
	if nome.begins_with("Os "):
		return "os " + nome.substr(3)
	if nome.begins_with("As "):
		return "as " + nome.substr(3)
	return "'" + nome
