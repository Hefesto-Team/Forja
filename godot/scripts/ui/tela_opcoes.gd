class_name TelaOpcoes
extends Control
## As opções: as de quem abriu (o gatilho e a vibração do lugar dele) e as da
## sessão (volumes, tremor, flashes, tela, texto). ▲▼ escolhe a linha, ◀▶ troca
## o valor e o controle já sente (a vibração dá um toque na força escolhida);
## ○ volta, e o que mudou fica guardado.

signal mudou(chave: String)

var quem := 0  ## o lugar que abriu
var linha := 0
var _linhas: Array = []  # [chave, rótulo, seção]

## O metrônomo da linha Tempo: um tique na TV a cada batida; ✕ no tique deixa
## um ponto na régua embaixo da linha — no centro, o tempo do lugar está certo.
const METRONOMO_BPM := 100.0
const REGUA_MS := 200.0  ## a régua vai de −REGUA_MS a +REGUA_MS
const REGUA_RESERVA := 48.0  ## o espaço sempre guardado embaixo da linha Tempo (a lista não pula ao navegar)
const CAIXA := 66.0  ## a altura da caixa de cada linha
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


func abrir(lugar: int) -> void:
	quem = lugar
	linha = 0
	_linhas = [
		["gatilho", "Gatilhos", "P%d" % (lugar + 1)],
		["vibracao", "Vibração", "P%d" % (lugar + 1)],
		["tempo", "Tempo", "P%d" % (lugar + 1)],
		["volume_tv", "Volume da TV", "sessao"],
		["volume_controle", "Volume do controle", "sessao"],
		["tremor", "Movimento da câmera", "sessao"],
		["flashes", "Flashes", "sessao"],
		["tela_cheia", "Tela", "sessao"],
		["texto", "Texto", "sessao"],
		["idioma", "Idioma", "sessao"],
	]
	_toques = []
	_latencia = AudioServer.get_output_latency()  # cara: uma vez ao abrir, nunca por quadro
	_metronomo_us = Time.get_ticks_usec()
	_ouvido_us = _metronomo_us + _ate_o_ouvido_us()
	_batida_tocada = -1


func navegar(dy: int) -> void:
	linha = wrapi(linha + dy, 0, _linhas.size())


func trocar(dx: int) -> void:
	var chave: String = _linhas[linha][0]
	match chave:
		"gatilho":
			Opcoes.gatilho[quem] = wrapi(int(Opcoes.gatilho[quem]) + dx, 0, Opcoes.GATILHO.size())
		"vibracao":
			Opcoes.vibracao[quem] = clampi(int(Opcoes.vibracao[quem]) + dx * Opcoes.PASSO, 0, 100)
			# mostrar, não contar: o controle sente a força nova
			Forja.vibrar(quem, 0.6, 0.6, 160)
		"tempo":
			var ms := clampi(int(Opcoes.tempo_ms[quem]) + dx * Opcoes.TEMPO_PASSO, Opcoes.TEMPO_MIN, Opcoes.TEMPO_MAX)
			Ritmo.definir_desvio(quem, ms / 1000.0, "opcoes")
		"volume_tv":
			Opcoes.volume_tv = clampi(Opcoes.volume_tv + dx * Opcoes.PASSO, 0, 100)
		"volume_controle":
			Opcoes.volume_controle = clampi(Opcoes.volume_controle + dx * Opcoes.PASSO, 0, 100)
		"tremor":
			Opcoes.tremor = not Opcoes.tremor
		"flashes":
			Opcoes.flashes = not Opcoes.flashes
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
		"tremor": return "ligado" if Opcoes.tremor else "desligado"
		"flashes": return "ligados" if Opcoes.flashes else "desligados"
		"tela_cheia": return "tela cheia" if Opcoes.tela_cheia else "janela"
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


func _process(_dt: float) -> void:
	if visible:
		# o tique da linha Tempo: o relógio do sistema, não o Ritmo (que está pausado aqui)
		var agora := Time.get_ticks_usec()
		if not _linhas.is_empty() and _linhas[linha][0] == "tempo" and _tique(agora):
			_ouvido_us = agora + _ate_o_ouvido_us()
			Som.tocar("tique", null, -4.0)
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.APP, 0.86))
	var larg := 980.0
	var alto := 72.0  ## a linha com 66 px (CAIXA): focável de 64 ou mais (o estudo 02, item 6)
	# as linhas, os dois títulos de seção, o lugar da régua do Tempo e a faixa das dicas
	var alt := 124.0 + 80.0 + _linhas.size() * alto + REGUA_RESERVA + 70.0
	var r := Rect2(Vector2((size.x - larg) * 0.5, (size.y - alt) * 0.5), Vector2(larg, alt))
	Desenho.moldura(self, r, Tema.PAINEL, Tema.LINHA, 2, Tema.RAIO_QUADRO)
	Desenho.texto(self, r.position + Vector2(48, 84), "Opções", Tema.fonte(700), Tema.T_TITULO, Tema.FG)
	var y := r.position.y + 124.0
	var secao := ""
	for i in _linhas.size():
		var item: Array = _linhas[i]
		if item[2] != secao:
			secao = item[2]
			var titulo := "Sessão" if secao == "sessao" else secao
			var cor_t := Tema.ROXO if secao == "sessao" else Tema.tom_para_a_borda(Forja.cor_do_lugar(quem))
			Desenho.texto(self, Vector2(r.position.x + 48, y + 30), titulo, Tema.fonte(600), Tema.T_SELO, cor_t)
			y += 40.0
		var b := Rect2(Vector2(r.position.x + 48, y), Vector2(larg - 96, CAIXA))
		var sel := i == linha
		Desenho.moldura(self, b, Tema.SEL if sel else Tema.APP, Tema.ROXO if sel else Tema.LINHA, 4 if sel else 2, Tema.RAIO_BOTAO)
		Desenho.texto(self, b.position + Vector2(24, 42), str(item[1]), Tema.fonte(600 if sel else 500), Tema.T_ROTULO,
			Tema.FG if sel else Tema.SUAVE)
		var v := valor(item[0])
		var fv := Tema.fonte(600)
		var xv := b.end.x - 110 - Desenho.largura(v, fv, Tema.T_ROTULO)
		Desenho.texto(self, Vector2(xv, b.position.y + 42), v, fv, Tema.T_ROTULO, Tema.CIANO)
		var fr := _fracao(item[0])
		if fr >= 0.0:
			var trilho := Rect2(Vector2(b.position.x + 380, b.position.y + b.size.y * 0.5 - 4), Vector2(220, 8))
			draw_rect(trilho, Tema.TRILHO)
			draw_rect(Rect2(trilho.position, Vector2(trilho.size.x * fr, 8)), Tema.ROXO)
		if sel:
			Glifo.desenhar(self, "esquerda", Rect2(Vector2(b.end.x - 92, b.position.y + 15), Vector2(32, 32)), Tema.ROSA)
			Glifo.desenhar(self, "direita", Rect2(Vector2(b.end.x - 50, b.position.y + 15), Vector2(32, 32)), Tema.ROSA)
		if item[0] == "tempo":
			if sel:
				_desenhar_regua(b)
			y += REGUA_RESERVA
		y += alto
	var dicas := [["cima", "linha"], ["esquerda", "trocar"], ["circulo", "voltar"]]
	if not _linhas.is_empty() and _linhas[linha][0] == "tempo":
		dicas.insert(2, ["cruz", "tocar no tempo"])
	Desenho.dicas_a_direita(self, Vector2(r.end.x - 48, r.end.y - 26), dicas, Tema.T_SELO)


## A régua da linha Tempo: 440 × 8 px no meio do quadro, com o traço do tempo
## no centro (pisca quando o tique chega ao ouvido) e um ponto por toque. Nada de número.
func _desenhar_regua(caixa: Rect2) -> void:
	var cx := size.x * 0.5
	var y := caixa.end.y + 22.0
	draw_rect(Rect2(Vector2(cx - 220.0, y), Vector2(440, 8)), Tema.TRILHO)
	var na_batida := posmod(Time.get_ticks_usec() - _ouvido_us, _periodo_us())
	var cor_traco := Tema.AMARELO if na_batida < 80000 else Tema.LINHA
	draw_rect(Rect2(Vector2(cx - 2.0, y - 10.0), Vector2(4, 28)), cor_traco)
	var cor := Forja.cor_do_lugar(quem)
	for i in _toques.size():
		var ms: float = _toques[i]
		var alfa := 1.0 if i == _toques.size() - 1 else 0.25
		draw_circle(Vector2(cx + clampf(ms / REGUA_MS, -1.0, 1.0) * 220.0, y + 4.0), 7.0, Color(cor, alfa))
