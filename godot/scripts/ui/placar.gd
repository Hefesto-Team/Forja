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


## A linha do tempo do placar entre as salas (s): o quadro entra; o "+N"
## estoura e o total sobe contando; as linhas trocam de lugar; o líder ganha
## o selo (e a virada, o aviso). ✕ antes do fim pula para o fim.
const T_CONTA := 0.5
const T_CONTA_FIM := 1.6
const T_TROCA := 1.8
const T_TROCA_FIM := 2.3
const T_LIDER := 2.4
const T_PRONTO := 2.6

var _antes: Array = []  ## o pódio antes da sala que acabou
var _depois: Array = []
var _virada := false
var _soou := {}


func abrir(p: Partida, podio: bool) -> void:
	partida = p
	no_podio = podio
	_t = 0.0
	_soou = {}
	_depois = p.podio(p.presentes())
	_antes = _podio_antes(p)
	# a virada: um líder sozinho, e não é o de antes
	_virada = false
	if p.historico.size() > 1 and _antes.size() > 1 and _depois.size() > 1:
		_virada = int(_depois[1].degrau) > 1 and int(_antes[0].lugar) != int(_depois[0].lugar)


## O pódio como estava antes da última sala (os totais menos o que ela deu).
static func _podio_antes(p: Partida) -> Array:
	var ult: Dictionary = p.historico[p.historico.size() - 1]
	var tot := []
	var vit := []
	for l in 4:
		tot.append(int(p.total[l]) - int(ult.ganhos[l]))
		vit.append(int(p.vitorias[l]) - (1 if int(ult.colocacao[l]) == 1 else 0))
	var lista: Array = []
	var pres := p.presentes()
	for l in pres:
		var acima := 0
		for o in pres:
			if tot[o] > tot[l] or (tot[o] == tot[l] and vit[o] > vit[l]):
				acima += 1
		lista.append({"lugar": l, "total": tot[l], "degrau": acima + 1})
	lista.sort_custom(func(a, b): return a.degrau < b.degrau or (a.degrau == b.degrau and a.lugar < b.lugar))
	return lista


## Pronto para o ✕ (o botão que fechou o veredito não passa direto por aqui).
func pronto() -> bool:
	return _t > (0.8 if no_podio else T_PRONTO)


## ✕ antes do fim: a animação pula para o fim.
func pular() -> void:
	if not no_podio and _t < T_PRONTO:
		_t = T_PRONTO
		_soou = {"conta": true, "troca": true, "lider": true}


func _process(dt: float) -> void:
	_t += dt
	if visible and not no_podio:
		_sons()
	if visible:
		queue_redraw()


func _sons() -> void:
	if _t >= T_CONTA and not _soou.has("conta"):
		_soou["conta"] = true
		Som.tocar("ponto")
	if _t >= T_TROCA and not _soou.has("troca"):
		_soou["troca"] = true
		Som.tocar("sobe")
	if _t >= T_LIDER and not _soou.has("lider"):
		_soou["lider"] = true
		Som.tocar("placar" if _virada else "confirma")


## A frase do pódio: "P2 venceu a noite" — e, se foi no desempate, o que
## decidiu. Alguém sempre ganha.
static func frase_do_vencedor(lista: Array) -> String:
	if lista.is_empty():
		return ""
	var frase := "P%d venceu a noite" % (int(lista[0].lugar) + 1)
	var criterio := str(lista[0].get("criterio", ""))
	if criterio != "":
		frase += " · desempate: " + criterio
	return frase


static func _suave(k: float) -> float:
	k = clampf(k, 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)


func _draw() -> void:
	if partida == null or partida.historico.is_empty():
		return
	if no_podio:
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, size.y)), Color(Tema.CASA, 0.35))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.APP, 0.86 * _suave(_t / 0.3)))
	var lista: Array = _depois if not _depois.is_empty() else partida.podio(partida.presentes())
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
	else:
		# o quadro entra subindo
		r.position.y += 60.0 * (1.0 - _suave(_t / 0.35))
	Desenho.moldura(self, r, Color(Tema.PAINEL, 0.97), Tema.LINHA, 2, Tema.RAIO_QUADRO)
	var x := r.position.x + 48
	if no_podio:
		Desenho.texto(self, Vector2(x, r.position.y + 84), "O pódio", Tema.fonte(700), Tema.T_TITULO, Tema.FG)
		Desenho.texto(self, Vector2(x, r.position.y + 140), frase_do_vencedor(lista), Tema.fonte(600), Tema.T_CORPO, Tema.VERDE)
	else:
		Desenho.texto(self, Vector2(x, r.position.y + 84), "O placar", Tema.fonte(700), Tema.T_TITULO, Tema.FG)
		var depois := "depois d%s · sala %d de %d" % [_contracao(str(ultima.nome)), partida.historico.size(), partida.salas.size()]
		Desenho.texto(self, Vector2(x, r.position.y + 140), depois, Tema.fonte(500), Tema.T_ROTULO, Tema.ROXO)
		if _virada and _t >= T_LIDER:
			var fv := Tema.fonte(700)
			var pulso := 1.0 + 0.06 * sin(_t * 8.0)
			var tv := int(Tema.T_SUBTITULO * pulso)
			Desenho.texto(self, Vector2(r.end.x - 48 - Desenho.largura("virada!", fv, tv), r.position.y + 90), "virada!", fv, tv, Tema.ROSA)
	# o cabeçalho das colunas
	var y0 := r.position.y + 206
	var c_total := r.end.x - 48 - 150
	var c_sala := c_total - 300
	if no_podio:
		Desenho.texto(self, Vector2(c_sala, y0), "salas vencidas", Tema.fonte(600), Tema.T_SELO, Tema.MUDO)
	else:
		Desenho.texto(self, Vector2(c_sala, y0), "nesta sala", Tema.fonte(600), Tema.T_SELO, Tema.MUDO)
	Desenho.texto(self, Vector2(c_total, y0), "da noite", Tema.fonte(600), Tema.T_SELO, Tema.MUDO)
	y0 += 22
	# a posição de cada lugar antes e depois (as linhas deslizam entre as duas)
	var pos_antes := {}
	for i in _antes.size():
		pos_antes[int(_antes[i].lugar)] = i
	var k_troca := 1.0 if no_podio else _suave((_t - T_TROCA) / (T_TROCA_FIM - T_TROCA))
	var k_conta := 1.0 if no_podio else _suave((_t - T_CONTA) / (T_CONTA_FIM - T_CONTA))
	for i in lista.size():
		var e: Dictionary = lista[i]
		var l := int(e.lugar)
		var i_antes: int = pos_antes.get(l, i)
		var y := y0 + linha * lerpf(float(i_antes), float(i), k_troca)
		var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(l))
		var b := Rect2(Vector2(x, y), Vector2(larg - 96, linha - 14))
		var mostra_lider := no_podio or _t >= T_LIDER
		var primeiro := int(e.degrau) == 1 and mostra_lider
		Desenho.moldura(self, b, Tema.SEL if primeiro else Tema.APP, cor_id, 4 if primeiro else 3, 12)
		var cy := b.position.y + b.size.y * 0.5 + 12
		var degrau := int(e.degrau) if k_troca >= 1.0 else i_antes + 1
		Desenho.texto(self, Vector2(b.position.x + 24, cy), ORDINAL[clampi(degrau, 0, 4)], Tema.fonte(700), Tema.T_CORPO,
			Tema.VERDE if primeiro else Tema.FG)
		Desenho.texto(self, Vector2(b.position.x + 110, cy), "P%d" % (l + 1), Tema.fonte(700), Tema.T_CORPO, cor_id)
		if primeiro and not no_podio:
			Desenho.selo(self, Vector2(b.position.x + 180, cy - 30), "lidera", Tema.VERDE)
		if no_podio:
			Desenho.texto(self, Vector2(c_sala, cy), "%d" % int(e.vitorias), Tema.mono(500), Tema.T_MONO, Tema.SUAVE)
		else:
			var col := int(ultima.colocacao[l])
			var ganho := int(ultima.ganhos[l])
			if col > 0:
				Desenho.texto(self, Vector2(c_sala, cy), ORDINAL[clampi(col, 0, 4)], Tema.fonte(600), Tema.T_CORPO, Tema.CIANO)
				# o "+N" estoura quando a conta começa
				if _t >= T_CONTA:
					var estouro := 1.0 + 0.5 * maxf(0.0, 1.0 - (_t - T_CONTA) / 0.25)
					var tg := int(Tema.T_CORPO * estouro)
					Desenho.texto(self, Vector2(c_sala + 76, cy + (tg - Tema.T_CORPO) * 0.3), "+%d" % ganho, Tema.fonte(700), tg,
						Tema.VERDE if ganho >= 4 else Tema.CIANO)
			else:
				Desenho.texto(self, Vector2(c_sala, cy), "—", Tema.fonte(600), Tema.T_CORPO, Tema.MUDO)
		var total := int(e.total)
		if not no_podio:
			total = int(round(lerpf(float(total - int(ultima.ganhos[l])), float(total), k_conta)))
		Desenho.texto(self, Vector2(c_total, cy), "%d" % total, Tema.mono(700), Tema.T_CORPO, Tema.FG)
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
