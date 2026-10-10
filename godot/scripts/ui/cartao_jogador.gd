class_name CartaoJogador
extends Control
## A coluna do lugar na construção do cavaleiro (432 px da tela de 1920 × 1080):
## a placa em cima (P#, o nome do cavaleiro, as lâmpadas do lugar e se está
## forjado), o cavaleiro em 3D no meio (nada desenhado), a etiqueta do
## arquétipo, as cinco linhas e os quatro VUs do corpo (G13). A borda na cor do lugar diz QUAL. O que o
## aparelho é por dentro (VID:PID, a origem, a bateria) é do Modo bancada.
## Lugar vazio: placa de borda sutil e «Entrar». Tudo em _draw(), sem Label.

var lugar := 0

const X0 := 10.0
const LARGURA := 412.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## O VU anda um segmento a cada 30 ms até o stat do corpo (G13, o encaixe): os segmentos mostrados agora.
const VU_PASSO := 0.03
var vu_mostrado := [0, 0, 0, 0]
var _vu_tempo := 0.0


func _process(dt: float) -> void:
	_andar_os_vus(dt)
	queue_redraw()


func _andar_os_vus(dt: float) -> void:
	var t := get_parent() as TelaLobby
	if t == null or lugar >= t.corpo.size():
		return
	var st: Array = t.corpo[lugar].get("stats", [0, 0, 0, 0])
	var parado := true
	for k in 4:
		parado = parado and int(vu_mostrado[k]) == int(st[k])
	if parado:
		_vu_tempo = 0.0
		return
	_vu_tempo += dt
	while _vu_tempo >= VU_PASSO:
		_vu_tempo -= VU_PASSO
		for k in 4:
			vu_mostrado[k] = int(vu_mostrado[k]) + signi(int(st[k]) - int(vu_mostrado[k]))


func _draw() -> void:
	var t := get_parent() as TelaLobby
	if t == null:
		return
	var info: Dictionary = Forja.lugar(lugar)
	var ocupado: bool = info.get("ocupado", false)
	var conectado: bool = info.get("conectado", false)
	var cor_luz: Color = Forja.cor_do_lugar(lugar)
	var cor_id := Tema.tom_para_a_borda(cor_luz)
	var rotulo := "P%d" % (lugar + 1)
	var placa := Rect2(X0, 60, LARGURA, 90)

	if not ocupado:
		var reservado: bool = info.get("reservado", false)
		Desenho.moldura(self, placa, Color(Tema.CASCO, 0.92), Tema.GRAFITE, 2, Tema.RAIO_CARTAO)
		Desenho.texto(self, Vector2(X0 + 18, 104), rotulo, Tema.archivo(700), Tema.T_CORPO, cor_id if reservado else Tema.MUDO)
		# a dica fica numa placa escura: sobre a cena clara a letra não se lia (contraste de 1,8:1)
		var placa_dica := Rect2(X0 + 60, 352, LARGURA - 120, 100 if reservado else 56)
		Desenho.moldura(self, placa_dica, Color(Tema.CASCO, 0.82), Tema.GRAFITE, 2, 8)
		Glifo.dica(self, Vector2(X0 + 100, 392), "cruz", "Entrar", Tema.T_ROTULO, Tema.ETIQUETA, Tema.ETIQUETA)
		if reservado:
			Glifo.dica(self, Vector2(X0 + 80, 436), "quadrado", "Segure para trocar", Tema.T_ROTULO, Tema.ETIQUETA_SOMBRA, Tema.ETIQUETA_SOMBRA, false)
		return

	var etapa: int = t.etapa[lugar]
	var jogador = t.jogadores[lugar] if lugar < t.jogadores.size() else null
	# a placa
	if conectado:
		Desenho.moldura(self, placa, Tema.CASCO, cor_id, 3, Tema.RAIO_CARTAO)
	else:
		Desenho.moldura(self, placa, Tema.CASCO, Tema.GRAFITE, 2, Tema.RAIO_CARTAO)
		Desenho.tracejado(self, placa, Tema.SECAO[3], 3.0)
	Desenho.texto(self, Vector2(X0 + 18, 104), rotulo, Tema.archivo(700), Tema.T_CORPO, cor_id)
	var teclado: TecladoDoNome = t.teclados[lugar]
	var nome_dele := str(jogador.nome) if jogador != null else ""
	if teclado != null:
		nome_dele = TecladoDoNome.formatar(teclado.texto)   # a placa mostra o campo enquanto se escreve (G09)
	if not conectado:
		Desenho.texto(self, Vector2(X0 + LARGURA - 18 - 260, 104), "Sem controle", Tema.archivo(600), Tema.T_CORPO, Tema.SECAO[3],
			HORIZONTAL_ALIGNMENT_RIGHT, 260)
	else:
		var f := Tema.archivo(600)
		Desenho.nome(self, Vector2(X0 + LARGURA - 18 - 260, 104), Desenho.nome_que_cabe(nome_dele, f, Tema.T_CORPO, 260),
			f, Tema.T_CORPO, Tema.ETIQUETA, HORIZONTAL_ALIGNMENT_RIGHT, 260)
	Desenho.leds(self, Vector2(X0 + 20, 120), Forja.LEDS_DO_LUGAR[lugar], 12.0)
	if etapa == TelaLobby.FORJADO:
		Desenho.texto(self, Vector2(X0 + LARGURA - 18 - 200, 142), "Forjado", Tema.vt(), Tema.T_MONO, cor_id,
			HORIZONTAL_ALIGNMENT_RIGHT, 200)
	elif etapa == TelaLobby.GUARDADO:
		Desenho.texto(self, Vector2(X0 + LARGURA - 18 - 200, 142), "Guardado", Tema.vt(), Tema.T_MONO, Tema.ETIQUETA_SOMBRA,
			HORIZONTAL_ALIGNMENT_RIGHT, 200)

	# o teclado do nome toma a faixa das três linhas e das marteladas (y 660 a 1000)
	if teclado != null:
		teclado.desenhar(self, 0.0, Tema.JOGADOR[lugar])
		return

	# a etiqueta do arquétipo (G13): «nome · arquétipo» em Permanent Marker, a tira do lugar à esquerda
	if jogador != null and jogador.pecas.size() == 3:
		_etiqueta(t, jogador)
	# as cinco linhas (660 a 848) e os quatro VUs (852 a 924, em duas colunas)
	if jogador != null:
		for k in TelaLobby.LINHAS.size():
			_linha(t, jogador, k, Rect2(X0, 660 + 38 * k, LARGURA, 36), etapa, cor_luz)
		if jogador.pecas.size() == 3:
			_vus(t)


## A etiqueta de 44 px em y 608: o nome da pessoa não passa pela tabela; o arquétipo, sim.
func _etiqueta(t: TelaLobby, jogador) -> void:
	var et := Rect2(X0 + 26, 608, LARGURA - 52, 44)
	Desenho.caixa(self, Rect2(et.position + Vector2(4, 5), et.size), Tema.SOMBRA, 6)
	Desenho.caixa(self, et, Tema.ETIQUETA, 6)
	draw_rect(Rect2(et.position + Vector2(0, 6), Vector2(8, et.size.y - 12)), Tema.JOGADOR[lugar])
	var arq: Dictionary = t.corpo[lugar].get("arquetipo", {})
	var titulo := str(jogador.nome)
	if not arq.is_empty():
		titulo += " · " + Traducoes.traduzir(str(arq.nome))
	var f := Tema.marcador()
	Desenho.nome(self, Vector2(et.position.x + 12, et.position.y + 33), Desenho.nome_que_cabe(titulo, f, Tema.T_ROTULO, et.size.x - 24),
		f, Tema.T_ROTULO, Tema.TINTA, HORIZONTAL_ALIGNMENT_CENTER, et.size.x - 24)


## Os quatro VUs do corpo, em duas colunas de duas linhas (de 852 a 924): o rótulo do stat, os cinco segmentos na cor
## do lugar e o número. Quatro linhas de 26 px encavalavam o texto de 30 px, e quatro de 30 px esbarram nas dicas.
func _vus(_t: TelaLobby) -> void:
	var f := Tema.vt()
	var tam := Tema.t(Tema.T_MONO)
	var rotulo := 0.0
	for nome in Cavaleiro.NOME_ST:
		rotulo = maxf(rotulo, f.get_string_size(Desenho.t(nome), HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x)
	var numero := f.get_string_size("5", HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	var celula := (LARGURA - 24.0 - 8.0) * 0.5
	for k in 4:
		var x := X0 + 12.0 + (celula + 8.0) * (k % 2)
		var y := 852.0 + (tam + 6.0) * (1 if k >= 2 else 0)
		Desenho.texto(self, Vector2(x, y + tam - 7), Cavaleiro.NOME_ST[k], f, Tema.T_MONO, Tema.MUDO)
		var r := Rect2(x + rotulo + 8.0, y + (tam - 20) * 0.5 - 2.0, celula - rotulo - 16.0 - numero, 20)
		Desenho.vu(self, r, 5, int(vu_mostrado[k]), Tema.JOGADOR[lugar])
		Desenho.texto(self, Vector2(r.end.x + 8.0, y + tam - 7), str(vu_mostrado[k]), f, Tema.T_MONO, Tema.ETIQUETA)


func _linha(t: TelaLobby, jogador, k: int, r: Rect2, etapa: int, cor_luz: Color) -> void:
	var escolhida: bool = etapa == TelaLobby.EDITANDO and t.linha[lugar] == k
	if escolhida:
		Desenho.moldura(self, r, Tema.CASCO_ALTO, cor_luz, 3, 6)
	else:
		Desenho.moldura(self, r, Color(Tema.CASCO, 0.78), Tema.GRAFITE, 2, 6)
	Desenho.texto(self, Vector2(X0 + 12, r.position.y + 28), TelaLobby.ROTULO_CURTO[k], Tema.archivo(600), Tema.T_ROTULO,
		Tema.ETIQUETA if escolhida else Tema.MUDO)
	# o valor: ◀ à esquerda, ▶ à direita, o valor no meio
	var area := Rect2(X0 + 136, r.position.y, LARGURA - 136 - 12, r.size.y)
	Glifo.desenhar(self, "esquerda", Rect2(area.position.x, r.position.y + 3, 30, 30), Tema.MUDO)
	Glifo.desenhar(self, "direita", Rect2(area.end.x - 30, r.position.y + 3, 30, 30), Tema.MUDO)
	var f := Tema.archivo(500)
	var base := r.position.y + 28
	var x_valor := X0 + 158.0
	var largura_valor := LARGURA - 34.0 - 158.0
	match k:
		TelaLobby.CABECA, TelaLobby.SUPERIOR, TelaLobby.INFERIOR:
			var valor := ""
			if jogador.pecas.size() == 3:
				valor = str(Cavaleiro.peca(Cavaleiro.PARTES[k], str(jogador.pecas[k])).get("nome", ""))
			Desenho.texto(self, Vector2(x_valor, base), Desenho.caber(valor, f, 30, largura_valor, 1), f, 30, Tema.ETIQUETA,
				HORIZONTAL_ALIGNMENT_CENTER, largura_valor)
		TelaLobby.ITEM:
			var item: Dictionary = ForjaPlayer.ITENS[jogador.item_i]
			if str(item.icone) != "":
				Glifo.desenhar(self, str(item.icone), Rect2(X0 + 160, r.position.y + 2, 32, 32), Tema.ETIQUETA)
			var x_nome := X0 + 160 + 32 + 8.0
			var largura := area.end.x - 30 - x_nome - 4.0
			Desenho.texto(self, Vector2(x_nome, base), Desenho.caber(str(item.nome), f, 30, largura, 1), f, 30, Tema.ETIQUETA,
				HORIZONTAL_ALIGNMENT_CENTER, largura)
		TelaLobby.NOME:
			Desenho.nome(self, Vector2(area.position.x, base), Desenho.nome_que_cabe(str(jogador.nome), f, 30, 220), f, 30, Tema.ETIQUETA,
				HORIZONTAL_ALIGNMENT_CENTER, area.size.x)
