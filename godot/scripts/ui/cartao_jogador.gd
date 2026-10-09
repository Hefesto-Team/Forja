class_name CartaoJogador
extends Control
## A coluna do lugar na construção do cavaleiro (432 px da tela de 1920 × 1080):
## a placa em cima (P#, o nome do cavaleiro, as lâmpadas do lugar e se está
## forjado), o cavaleiro em 3D no meio (nada desenhado) e embaixo as três
## linhas e as oito marteladas. A borda na cor do lugar diz QUAL. O que o
## aparelho é por dentro (VID:PID, a origem, a bateria) é do Modo bancada.
## Lugar vazio: placa de borda sutil e «Entrar». Tudo em _draw(), sem Label.

var lugar := 0

const X0 := 10.0
const LARGURA := 412.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_dt: float) -> void:
	queue_redraw()


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
		Desenho.moldura(self, placa, Color(Tema.APP, 0.92), Tema.SUTIL, 2, Tema.RAIO_CARTAO)
		Desenho.texto(self, Vector2(X0 + 18, 104), rotulo, Tema.fonte(700), Tema.T_CORPO, cor_id if reservado else Tema.MUDO)
		# a dica fica numa placa escura: sobre a cena clara a letra não se lia (contraste de 1,8:1)
		var placa_dica := Rect2(X0 + 60, 352, LARGURA - 120, 100 if reservado else 56)
		Desenho.moldura(self, placa_dica, Color(Tema.APP, 0.82), Tema.SUTIL, 2, 8)
		Glifo.dica(self, Vector2(X0 + 100, 392), "cruz", "Entrar", Tema.T_ROTULO, Tema.FG, Tema.FG)
		if reservado:
			Glifo.dica(self, Vector2(X0 + 80, 436), "quadrado", "Segure para trocar", Tema.T_ROTULO, Tema.SUAVE, Tema.SUAVE, false)
		return

	var etapa: int = t.etapa[lugar]
	var jogador = t.jogadores[lugar] if lugar < t.jogadores.size() else null
	# a placa
	if conectado:
		Desenho.moldura(self, placa, Tema.PAINEL, cor_id, 3, Tema.RAIO_CARTAO)
	else:
		Desenho.moldura(self, placa, Tema.PAINEL, Tema.SUTIL, 2, Tema.RAIO_CARTAO)
		Desenho.tracejado(self, placa, Tema.LARANJA, 3.0)
	Desenho.texto(self, Vector2(X0 + 18, 104), rotulo, Tema.fonte(700), Tema.T_CORPO, cor_id)
	var teclado: TecladoDoNome = t.teclados[lugar]
	var nome_dele := str(jogador.nome) if jogador != null else ""
	if teclado != null:
		nome_dele = TecladoDoNome.formatar(teclado.texto)   # a placa mostra o campo enquanto se escreve (G09)
	if not conectado:
		Desenho.texto(self, Vector2(X0 + LARGURA - 18 - 260, 104), "Sem controle", Tema.fonte(600), Tema.T_CORPO, Tema.LARANJA,
			HORIZONTAL_ALIGNMENT_RIGHT, 260)
	else:
		var f := Tema.fonte(600)
		Desenho.nome(self, Vector2(X0 + LARGURA - 18 - 260, 104), Desenho.nome_que_cabe(nome_dele, f, Tema.T_CORPO, 260),
			f, Tema.T_CORPO, Tema.FG, HORIZONTAL_ALIGNMENT_RIGHT, 260)
	Desenho.leds(self, Vector2(X0 + 20, 120), Forja.LEDS_DO_LUGAR[lugar], 12.0)
	if etapa == TelaLobby.FORJADO:
		Desenho.texto(self, Vector2(X0 + LARGURA - 18 - 200, 142), "Forjado", Tema.mono(500), Tema.T_MONO, Tema.VERDE,
			HORIZONTAL_ALIGNMENT_RIGHT, 200)
	elif etapa == TelaLobby.GUARDADO:
		Desenho.texto(self, Vector2(X0 + LARGURA - 18 - 200, 142), "Guardado", Tema.mono(500), Tema.T_MONO, Tema.SUAVE,
			HORIZONTAL_ALIGNMENT_RIGHT, 200)

	# o teclado do nome toma a faixa das três linhas e das marteladas (y 660 a 1000)
	if teclado != null:
		teclado.desenhar(self, 0.0, Tema.JOGADOR[lugar])
		return

	# as três linhas
	if jogador != null:
		for k in 3:
			_linha(t, jogador, k, Rect2(X0, 660 + 40 * k, LARGURA, 38), etapa, cor_luz)

	# as oito marteladas
	var feitas: int = t.golpes[lugar].size() if etapa == TelaLobby.FORJANDO \
		else (TelaLobby.MARTELADAS if etapa >= TelaLobby.FORJADO else 0)
	for k in TelaLobby.MARTELADAS:
		draw_rect(Rect2(X0 + 75 + k * 34, 880, 24, 24), cor_luz if k < feitas else Tema.TRILHO)


func _linha(t: TelaLobby, jogador, k: int, r: Rect2, etapa: int, cor_luz: Color) -> void:
	var escolhida: bool = etapa == TelaLobby.EDITANDO and t.linha[lugar] == k
	if escolhida:
		Desenho.moldura(self, r, Tema.SEL, cor_luz, 3, 6)
	else:
		Desenho.moldura(self, r, Color(Tema.APP, 0.78), Tema.SUTIL, 2, 6)
	Desenho.texto(self, Vector2(X0 + 12, r.position.y + 30), TelaLobby.ROTULO_CURTO[k], Tema.fonte(600), Tema.T_ROTULO,
		Tema.FG if escolhida else Tema.SUAVE)
	# o valor: ◀ à esquerda, ▶ à direita, o valor no meio
	var area := Rect2(X0 + 136, r.position.y, LARGURA - 136 - 12, r.size.y)
	Glifo.desenhar(self, "esquerda", Rect2(area.position.x, r.position.y + 4, 30, 30), Tema.MUDO)
	Glifo.desenhar(self, "direita", Rect2(area.end.x - 30, r.position.y + 4, 30, 30), Tema.MUDO)
	var f := Tema.fonte(500)
	var base := r.position.y + 30
	match k:
		TelaLobby.BONECO:
			var valor := ForjaPlayer.nome_do_boneco(jogador.modelo_i)
			Desenho.texto(self, Vector2(area.position.x, base), Desenho.caber(valor, f, 30, 220, 1), f, 30, Tema.FG,
				HORIZONTAL_ALIGNMENT_CENTER, area.size.x)
		TelaLobby.ITEM:
			var item: Dictionary = ForjaPlayer.ITENS[jogador.item_i]
			if str(item.icone) != "":
				Glifo.desenhar(self, str(item.icone), Rect2(X0 + 160, r.position.y + 3, 32, 32), Tema.FG)
			var x_nome := X0 + 160 + 32 + 8.0
			var largura := area.end.x - 30 - x_nome - 4.0
			Desenho.texto(self, Vector2(x_nome, base), Desenho.caber(str(item.nome), f, 30, largura, 1), f, 30, Tema.FG,
				HORIZONTAL_ALIGNMENT_CENTER, largura)
		TelaLobby.NOME:
			Desenho.nome(self, Vector2(area.position.x, base), Desenho.nome_que_cabe(str(jogador.nome), f, 30, 220), f, 30, Tema.FG,
				HORIZONTAL_ALIGNMENT_CENTER, area.size.x)
