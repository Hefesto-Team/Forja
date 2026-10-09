class_name TelaOpcoes
extends Control
## As opções: as de quem abriu (o gatilho e a vibração do lugar dele) e as da
## sessão (volumes, movimento, flashes, reações, tela, texto, idioma). ▲▼ escolhe a linha, ◀▶ troca
## o valor e o controle já sente (a vibração dá um toque na força escolhida);
## ○ volta, e o que mudou fica guardado.

signal mudou(chave: String)

var quem := 0  ## o lugar que abriu
var linha := 0
var _linhas: Array = []  # [chave, rótulo, seção]
var _rolar := 0.0  ## o quanto a lista já subiu, em px
var _rolar_alvo := 0.0  ## onde ela para (sempre no alto de uma linha, ou no fim)
var _lista: Control  ## o desenho da lista, recortado no retângulo dela

## O metrônomo da linha Tempo: um tique na TV a cada batida; ✕ no tique deixa
## um ponto na régua embaixo da linha — no centro, o tempo do lugar está certo.
const METRONOMO_BPM := 100.0
const REGUA_MS := 200.0  ## a régua vai de −REGUA_MS a +REGUA_MS
const REGUA_RESERVA := 48.0  ## o espaço sempre guardado embaixo da linha Tempo (a lista não pula ao navegar)
const CAIXA := 66.0  ## a altura da caixa de cada linha
const ALTO_DA_LINHA := 72.0  ## a linha com 66 px (CAIXA): focável de 64 ou mais (o estudo 02, item 6)
const ALTO_DO_TITULO := 40.0  ## o título de cada seção (Gatilhos... / Sessão)
const QUADRO_MAX := 1000.0  ## o quadro nunca passa disto (40 px de margem em 1080): o que não cabe, desliza
const CABECA := 124.0  ## do alto do quadro ao começo da lista
const RODAPE := 70.0  ## do fim da lista ao fim do quadro (a faixa das dicas)
## Uma batida achada mais tarde que isto (a linha Tempo acabou de ser escolhida,
## um quadro preso) passa calada: o tique nunca soa fora da batida.
const TIQUE_TARDE_US := 50000
var _metronomo_us := 0
var _batida_tocada := -1
## O instante em que o último tique chega ao ouvido: o som sai no próximo mix,
## mais a latência de saída, como o zero do Ritmo. O ✕ se mede contra ele.
var _ouvido_us := 0
var _latencia := 0.0
var _toques: Array = []  ## os últimos 8 desvios, em ms, já corrigidos pelo tempo do lugar


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lista = Control.new()
	_lista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lista.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lista.draw.connect(_desenhar_lista)
	add_child(_lista)


func abrir(lugar: int) -> void:
	quem = lugar
	linha = 0
	_linhas = [
		["gatilho", "Gatilhos", "P%d" % (lugar + 1)],
		["vibracao", "Vibração", "P%d" % (lugar + 1)],
		["tempo", "Tempo", "P%d" % (lugar + 1)],
		["volume_tv", "Volume da TV", "sessao"],
		["volume_controle", "Volume do controle", "sessao"],
		["movimento", "Movimento", "sessao"],
		["flashes", "Flashes", "sessao"],
		["reacoes", "Reações", "sessao"],
		["tela_cheia", "Tela", "sessao"],
		["texto", "Texto", "sessao"],
		["idioma", "Idioma", "sessao"],
	]
	_rolar = 0.0
	_rolar_alvo = 0.0
	_toques = []
	_latencia = AudioServer.get_output_latency()  # cara: uma vez ao abrir, nunca por quadro
	_metronomo_us = Time.get_ticks_usec()
	_ouvido_us = _metronomo_us + _ate_o_ouvido_us()
	_batida_tocada = -1


func navegar(dy: int) -> void:
	linha = wrapi(linha + dy, 0, _linhas.size())
	_rolar_alvo = _alvo_da_rolagem()
	if Opcoes.reduzido():
		_rolar = _rolar_alvo


func trocar(dx: int) -> void:
	var chave: String = _linhas[linha][0]
	match chave:
		"gatilho":
			Opcoes.gatilho[quem] = wrapi(int(Opcoes.gatilho[quem]) + dx, 0, Opcoes.GATILHO.size())
		"vibracao":
			Opcoes.vibracao[quem] = clampi(int(Opcoes.vibracao[quem]) + dx * Opcoes.PASSO, 0, 100)
			# mostrar, não contar: o controle sente a força nova
			Forja.sentir(quem, "golpe")
		"tempo":
			var ms := clampi(int(Opcoes.tempo_ms[quem]) + dx * Opcoes.TEMPO_PASSO, Opcoes.TEMPO_MIN, Opcoes.TEMPO_MAX)
			Ritmo.definir_desvio(quem, ms / 1000.0, "opcoes")
		"volume_tv":
			Opcoes.volume_tv = clampi(Opcoes.volume_tv + dx * Opcoes.PASSO, 0, 100)
		"volume_controle":
			Opcoes.volume_controle = clampi(Opcoes.volume_controle + dx * Opcoes.PASSO, 0, 100)
		"movimento":
			Opcoes.movimento = wrapi(Opcoes.movimento + dx, 0, Opcoes.MOVIMENTO.size())
			Forja.sentir(quem, "toque")
		"flashes":
			Opcoes.flashes = not Opcoes.flashes
		"reacoes":
			Opcoes.reacoes = wrapi(Opcoes.reacoes + dx, 0, Opcoes.REACOES.size())
			Forja.sentir(quem, "toque")
		"tela_cheia":
			Opcoes.tela_cheia = not Opcoes.tela_cheia
		"texto":
			Opcoes.texto = wrapi(Opcoes.texto + dx, 0, Opcoes.TEXTO.size())
		"idioma":
			Opcoes.idioma = wrapi(Opcoes.idioma + dx, 0, Opcoes.IDIOMAS.size())
	mudou.emit(chave)


func valor(chave: String) -> String:
	match chave:
		"gatilho": return Opcoes.GATILHO[int(Opcoes.gatilho[quem])]
		"vibracao": return "%d%%" % int(Opcoes.vibracao[quem])
		"tempo": return "%+d ms" % int(Opcoes.tempo_ms[quem])
		"volume_tv": return "%d%%" % Opcoes.volume_tv
		"volume_controle": return "%d%%" % Opcoes.volume_controle
		"movimento": return Opcoes.MOVIMENTO[Opcoes.movimento]
		"flashes": return "Ligados" if Opcoes.flashes else "Desligados"
		"reacoes": return Opcoes.REACOES[Opcoes.reacoes]
		"tela_cheia": return "Tela cheia" if Opcoes.tela_cheia else "Janela"
		"texto": return Opcoes.TEXTO[Opcoes.texto]
		"idioma": return Opcoes.NOMES_DOS_IDIOMAS[Opcoes.idioma]
	return ""


## A fração do valor, para a barra (os que são porcentagem); -1 sem barra.
func _fracao(chave: String) -> float:
	match chave:
		"vibracao": return Opcoes.vibracao[quem] / 100.0
		"volume_tv": return Opcoes.volume_tv / 100.0
		"volume_controle": return Opcoes.volume_controle / 100.0
		"gatilho": return int(Opcoes.gatilho[quem]) / 2.0
	return -1.0


func _periodo_us() -> int:
	return int(60.0 / METRONOMO_BPM * 1000000.0)


## Do tique tocado agora até ele chegar ao ouvido, em µs.
func _ate_o_ouvido_us() -> int:
	return int((AudioServer.get_time_to_next_mix() + _latencia) * 1000000.0)


## true quando uma batida nova do metrônomo começou agora e o tique deve soar.
func _tique(agora_us: int) -> bool:
	var desde := agora_us - _metronomo_us
	var batida := floori(float(desde) / float(_periodo_us()))
	if batida <= _batida_tocada:
		return false
	_batida_tocada = batida
	return posmod(desde, _periodo_us()) < TIQUE_TARDE_US


## ✕ na linha Tempo: onde o toque caiu em relação à batida ouvida mais perto.
func tocou() -> void:
	if _linhas.is_empty() or _linhas[linha][0] != "tempo":
		return
	var fase := posmod(Time.get_ticks_usec() - _ouvido_us, _periodo_us())
	var ms := fase / 1000.0
	if ms > _periodo_us() / 2000.0:
		ms -= _periodo_us() / 1000.0
	_toques.append(ms - float(Opcoes.tempo_ms[quem]))
	if _toques.size() > 8:
		_toques.pop_front()


func _process(dt: float) -> void:
	if visible:
		_rolar = move_toward(_rolar, _rolar_alvo, 2400.0 * dt)
		# o tique da linha Tempo: o relógio do sistema, não o Ritmo (que está pausado aqui)
		var agora := Time.get_ticks_usec()
		if not _linhas.is_empty() and _linhas[linha][0] == "tempo" and _tique(agora):
			_ouvido_us = agora + _ate_o_ouvido_us()
			Som.tocar("tique", null, -4.0)
		queue_redraw()


## Os blocos da lista, de cima para baixo: o título da seção (na primeira linha dela), a linha e, na Tempo, o lugar
## da régua. `topo` conta do começo da lista, sem a rolagem.
func _blocos() -> Array:
	var blocos: Array = []
	var y := 0.0
	var secao := ""
	for item in _linhas:
		var titulo: bool = item[2] != secao
		secao = item[2]
		var alto := ALTO_DA_LINHA + (ALTO_DO_TITULO if titulo else 0.0) + (REGUA_RESERVA if item[0] == "tempo" else 0.0)
		blocos.append({"topo": y, "alto": alto, "titulo": titulo})
		y += alto
	return blocos


func _conteudo() -> float:
	var h := 0.0
	for b in _blocos():
		h += float(b.alto)
	return h


## O alto do quadro: o que a lista pede, até QUADRO_MAX.
func _alto_do_quadro() -> float:
	return minf(QUADRO_MAX, CABECA + _conteudo() + RODAPE)


func _alto_da_lista() -> float:
	return _alto_do_quadro() - CABECA - RODAPE


## Onde a lista para para a linha escolhida ficar inteira à vista, com uma linha de folga de cada lado: o alto de uma
## linha (ou o fim da lista), o mais perto de onde ela já está.
func _alvo_da_rolagem() -> float:
	var vp := _alto_da_lista()
	var fim := maxf(0.0, _conteudo() - vp)
	if fim <= 0.0 or _linhas.is_empty():
		return 0.0
	var bl := _blocos()
	var lo: float = bl[maxi(0, linha - 1)].topo
	var ult: Dictionary = bl[mini(bl.size() - 1, linha + 1)]
	var hi: float = float(ult.topo) + float(ult.alto)
	var candidatos: Array = [0.0, fim]
	for b in bl:
		if float(b.topo) <= fim:
			candidatos.append(float(b.topo))
	var melhor := -1.0
	var dist := INF
	for c in candidatos:
		if c <= lo + 0.01 and c + vp >= hi - 0.01 and absf(c - _rolar_alvo) < dist:
			melhor = c
			dist = absf(c - _rolar_alvo)
	return melhor if melhor >= 0.0 else clampf(lo, 0.0, fim)


## A caixa do quadro, no meio da tela.
func _quadro() -> Rect2:
	var larg := 980.0
	var alt := _alto_do_quadro()
	return Rect2(Vector2((size.x - larg) * 0.5, (size.y - alt) * 0.5), Vector2(larg, alt))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.CASCO, 0.86))
	var r := _quadro()
	Desenho.moldura(self, r, Tema.CASCO, Tema.GRAFITE, 2, Tema.RAIO_QUADRO)
	Desenho.texto(self, r.position + Vector2(48, 84), "Opções", Tema.bungee(), Tema.T_TITULO, Tema.ETIQUETA)
	# a lista desliza dentro do retângulo dela: o glifo marca o lado cortado
	var fim := maxf(0.0, _conteudo() - _alto_da_lista())
	if _rolar > 0.5:
		Glifo.desenhar(self, "cima", Rect2(Vector2(r.end.x - 80, r.position.y + 52), Vector2(32, 32)), Tema.MUDO)
	if _rolar < fim - 0.5:
		Glifo.desenhar(self, "baixo", Rect2(Vector2(r.position.x + 48, r.end.y - 52), Vector2(32, 32)), Tema.MUDO)
	if _lista:
		var area := Rect2(r.position + Vector2(0, CABECA), Vector2(r.size.x, _alto_da_lista()))
		_lista.position = area.position
		_lista.size = area.size
		_lista.clip_contents = true
		_lista.queue_redraw()
	var dicas := [["cima", "Linha"], ["esquerda", "Trocar"], ["circulo", "Voltar"]]
	if not _linhas.is_empty() and _linhas[linha][0] == "tempo":
		dicas.insert(2, ["cruz", "Tocar no tempo"])
	Desenho.dicas_a_direita(self, Vector2(r.end.x - 48, r.end.y - 26), dicas, Tema.T_SELO)


## As linhas, no retângulo da lista (a origem é o canto dele). Parada, só se desenha o que cabe inteiro; deslizando,
## o recorte esconde o que passa da borda.
func _desenhar_lista() -> void:
	var larg := 980.0
	var vp := _alto_da_lista()
	var parada := absf(_rolar - _rolar_alvo) < 0.5
	var cor_dono := Tema.tom_para_a_borda(Forja.cor_do_lugar(quem))  ## o foco tem dono: quem abriu as Opções
	var blocos := _blocos()
	for i in _linhas.size():
		var item: Array = _linhas[i]
		var topo: float = float(blocos[i].topo) - _rolar
		var alto: float = blocos[i].alto
		if topo + alto <= 0.0 or topo >= vp:
			continue
		if parada and (topo < -0.5 or topo + alto > vp + 0.5):
			continue
		var y := topo
		if blocos[i].titulo:
			var secao: String = item[2]
			var titulo := "Sessão" if secao == "sessao" else secao
			var cor_t := Tema.ETIQUETA if secao == "sessao" else Tema.tom_para_a_borda(Forja.cor_do_lugar(quem))
			Desenho.texto(_lista, Vector2(48, y + 30), titulo, Tema.archivo(600), Tema.T_SELO, cor_t)
			y += ALTO_DO_TITULO
		var b := Rect2(Vector2(48, y), Vector2(larg - 96, CAIXA))
		var sel := i == linha
		Desenho.moldura(_lista, b, Tema.CASCO_ALTO if sel else Tema.CASCO, cor_dono if sel else Tema.GRAFITE, 4 if sel else 2, Tema.RAIO_BOTAO)
		Desenho.texto(_lista, b.position + Vector2(24, 42), str(item[1]), Tema.archivo(600 if sel else 500), Tema.T_ROTULO,
			Tema.ETIQUETA if sel else Tema.ETIQUETA_SOMBRA)
		var v := valor(item[0])
		var fv := Tema.archivo(600)
		var xv := b.end.x - 110 - Desenho.largura(v, fv, Tema.T_ROTULO)
		Desenho.texto(_lista, Vector2(xv, b.position.y + 42), v, fv, Tema.T_ROTULO, Tema.ETIQUETA)
		var fr := _fracao(item[0])
		if fr >= 0.0:
			var trilho := Rect2(Vector2(b.position.x + 380, b.position.y + b.size.y * 0.5 - 4), Vector2(220, 8))
			_lista.draw_rect(trilho, Tema.GRAFITE)
			_lista.draw_rect(Rect2(trilho.position, Vector2(trilho.size.x * fr, 8)), cor_dono)
		if sel:
			Glifo.desenhar(_lista, "esquerda", Rect2(Vector2(b.end.x - 92, b.position.y + 15), Vector2(32, 32)), cor_dono)
			Glifo.desenhar(_lista, "direita", Rect2(Vector2(b.end.x - 50, b.position.y + 15), Vector2(32, 32)), cor_dono)
			if item[0] == "tempo":
				_desenhar_regua(b)


## A régua da linha Tempo: 440 × 8 px no meio do quadro, com o traço do tempo
## no centro (pisca quando o tique chega ao ouvido) e um ponto por toque. Nada de número.
func _desenhar_regua(caixa: Rect2) -> void:
	var cx := caixa.position.x + caixa.size.x * 0.5
	var y := caixa.end.y + 22.0
	_lista.draw_rect(Rect2(Vector2(cx - 220.0, y), Vector2(440, 8)), Tema.GRAFITE)
	var na_batida := posmod(Time.get_ticks_usec() - _ouvido_us, _periodo_us())
	var cor_traco := Tema.ETIQUETA if na_batida < 80000 else Tema.GRAFITE
	_lista.draw_rect(Rect2(Vector2(cx - 2.0, y - 10.0), Vector2(4, 28)), cor_traco)
	var cor := Forja.cor_do_lugar(quem)
	for i in _toques.size():
		var ms: float = _toques[i]
		var alfa := 1.0 if i == _toques.size() - 1 else 0.25
		_lista.draw_circle(Vector2(cx + clampf(ms / REGUA_MS, -1.0, 1.0) * 220.0, y + 4.0), 7.0, Color(cor, alfa))
