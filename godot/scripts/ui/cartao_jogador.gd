class_name CartaoJogador
extends Control
## O cartão do lugar no lobby, como o cartão de jogador do app: a borda na cor
## de luz do lugar diz QUAL; dentro, o que o módulo leu do controle — nome,
## VID:PID, USB ou BT, a origem (DualSense nativo, Edge virtual, Xbox virtual),
## a bateria — e o que o jogo mandou: a cor da barra de luz e as cinco lâmpadas.
## Lugar vazio: borda sutil e travessão, sem desenho de controle.

var lugar := 0
var pronto := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_dt: float) -> void:
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var info: Dictionary = Forja.lugar(lugar)
	var ocupado: bool = info.get("ocupado", false)
	var conectado: bool = info.get("conectado", false)
	var cor_luz: Color = Forja.cor_do_lugar(lugar)
	var cor_id := Tema.tom_para_a_borda(cor_luz)
	var rotulo := "P%d" % (lugar + 1)
	var x := 28.0
	var fonte := Tema.fonte(600)
	var mono := Tema.mono(400)

	if not ocupado:
		Desenho.moldura(self, r, Color(Tema.APP, 0.92), Tema.SUTIL, 2, Tema.RAIO_CARTAO)
		Desenho.texto(self, Vector2(x, 52), rotulo, Tema.fonte(700), Tema.T_CORPO, Tema.MUDO)
		Desenho.texto(self, Vector2(x + 52, 52), "·  —", fonte, Tema.T_ROTULO, Tema.MUDO)
		Glifo.dica(self, Vector2(x, size.y - 40), "cruz", "entrar", Tema.T_ROTULO, Tema.SUAVE, Tema.MUDO)
		return

	var p: Dictionary = Forja.pad(int(info.get("pad", -1))) if conectado else {}
	var interior := Tema.SEL if pronto else Color(Tema.APP, 0.94)
	Desenho.moldura(self, r, interior, cor_id, 4, Tema.RAIO_CARTAO)
	if not conectado:
		Desenho.moldura(self, r, Color(Tema.APP, 0.94), Tema.SUTIL, 2, Tema.RAIO_CARTAO)
		Desenho.tracejado(self, r.grow(-6), Tema.LARANJA, 2.0, 14.0)

	# linha 1: "P1 · USB" e a bateria
	Desenho.texto(self, Vector2(x, 52), rotulo, Tema.fonte(700), Tema.T_CORPO, cor_id)
	var conexao: String = p.get("conexao_curta", "sem controle") if conectado else "sem controle"
	Desenho.texto(self, Vector2(x + 52, 52), "·  " + conexao, fonte, Tema.T_ROTULO, Tema.FG if conectado else Tema.LARANJA)
	if conectado:
		var pct: int = p.get("bateria", -1)
		if pct >= 0:
			var w_bat := Desenho.largura("100%", Tema.mono(500), Tema.T_MONO) + 12 + 48
			Desenho.bateria(self, Vector2(size.x - 28 - w_bat, 52), pct, p.get("carregando", false), 48.0)

	if not conectado:
		Desenho.texto(self, Vector2(x, 104), "O controle saiu.", fonte, Tema.T_ROTULO, Tema.FG)
		Desenho.texto(self, Vector2(x, 144), "Religue o mesmo para voltar.", Tema.fonte(400), Tema.T_ROTULO, Tema.SUAVE)
		Glifo.dica(self, Vector2(x, size.y - 40), "circulo", "liberar o lugar", Tema.T_ROTULO, Tema.SUAVE, Tema.MUDO)
		return

	# linha 2: o nome que o controle dá
	Desenho.texto(self, Vector2(x, 98), p.get("nome", "controle"), Tema.fonte(500), 30, Tema.FG, HORIZONTAL_ALIGNMENT_LEFT, size.x - 56)
	# linha 3: VID:PID; linha 4: a origem (o que o jogo concluiu do aparelho)
	Desenho.texto(self, Vector2(x, 136), p.get("vidpid", "----:----"), mono, Tema.T_SELO, Tema.SUAVE)
	var origem: String = p.get("origem_curta", "")
	if p.get("so_entrada", false):
		origem += " · no rádio, só a entrada"
	Desenho.texto(self, Vector2(x, 172), origem, Tema.fonte(600), Tema.T_SELO,
		Tema.LARANJA if p.get("so_entrada", false) else Tema.CIANO, HORIZONTAL_ALIGNMENT_LEFT, size.x - 56)

	# linha 4: a barra de luz (a cor que o jogo mandou) e as cinco lâmpadas
	var saida: Dictionary = Forja.estado_saida(lugar)
	var luz: Color = saida.get("luz", cor_luz)
	var y4 := size.y - 104
	Desenho.texto(self, Vector2(x, y4 + 22), "Luz", Tema.fonte(600), Tema.T_SELO, Tema.VERDE)
	var chip := Rect2(Vector2(x + 58, y4), Vector2(64, 30))
	Desenho.moldura(self, chip, luz, Tema.LINHA, 2, 8)
	Desenho.texto(self, Vector2(x + 146, y4 + 22), "LEDs", Tema.fonte(600), Tema.T_SELO, Tema.VERDE)
	Desenho.leds(self, Vector2(x + 214, y4 + 8), int(saida.get("leds_jogador", info.get("leds", 0))), 14.0)

	# rodapé: pronto, ou as ações do dono do lugar
	if pronto:
		Desenho.selo(self, Vector2(x, size.y - 62), "✓ PRONTO", Tema.VERDE)
		Glifo.dica(self, Vector2(size.x - 28 - Glifo.largura_dica("circulo", "voltar", Tema.T_ROTULO), size.y - 32),
			"circulo", "voltar", Tema.T_ROTULO, Tema.SUAVE, Tema.MUDO)
	else:
		var w := Glifo.dica(self, Vector2(x, size.y - 32), "cruz", "pronto", Tema.T_ROTULO, Tema.FG, Tema.SUAVE)
		Glifo.dica(self, Vector2(x + w + 36, size.y - 32), "circulo", "sair", Tema.T_ROTULO, Tema.SUAVE, Tema.MUDO)
