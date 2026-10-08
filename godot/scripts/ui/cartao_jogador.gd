class_name CartaoJogador
extends Control
## O cartão do lugar no lobby: a borda na cor do lugar diz QUAL; dentro, só o
## que o jogador entende — o nome do controle, USB ou BT, a bateria e se está
## pronto. O que o aparelho é por dentro (VID:PID, a origem, o que o jogo
## mandou à luz) é do Modo bancada, não deste cartão.
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

	if not ocupado:
		Desenho.moldura(self, r, Color(Tema.APP, 0.92), Tema.SUTIL, 2, Tema.RAIO_CARTAO)
		var reservado: bool = info.get("reservado", false)
		Desenho.texto(self, Vector2(x, 52), rotulo, Tema.fonte(700), Tema.T_CORPO, cor_id if reservado else Tema.MUDO)
		Desenho.texto(self, Vector2(x + 52, 52), "·  —", fonte, Tema.T_ROTULO, Tema.MUDO)
		if reservado:
			_dica(Vector2(x, size.y - 70), "cruz", "Entrar", Tema.SUAVE, Tema.MUDO)
			_dica(Vector2(x, size.y - 32), "quadrado", "Segure para trocar", Tema.SUAVE, Tema.MUDO, false)
		else:
			_dica(Vector2(x, size.y - 40), "cruz", "Entrar", Tema.SUAVE, Tema.MUDO)
		return

	var p: Dictionary = Forja.pad(int(info.get("pad", -1))) if conectado else {}
	var interior := Tema.SEL if pronto else Color(Tema.APP, 0.94)
	Desenho.moldura(self, r, interior, cor_id, 4, Tema.RAIO_CARTAO)
	if not conectado:
		Desenho.moldura(self, r, Color(Tema.APP, 0.94), Tema.SUTIL, 2, Tema.RAIO_CARTAO)
		Desenho.tracejado(self, r.grow(-6), Tema.LARANJA, 2.0, 14.0)

	# linha 1: "P1 · USB" e a bateria
	Desenho.texto(self, Vector2(x, 52), rotulo, Tema.fonte(700), Tema.T_CORPO, cor_id)
	var conexao: String = p.get("conexao_curta", "Sem controle") if conectado else "Sem controle"
	Desenho.texto(self, Vector2(x + 52, 52), "·  " + conexao, fonte, Tema.T_ROTULO, Tema.FG if conectado else Tema.LARANJA)
	if conectado:
		var pct: int = p.get("bateria", -1)
		if pct >= 0:
			var w_bat := Desenho.largura("100%", Tema.mono(500), Tema.T_MONO) + 12 + 48
			Desenho.bateria(self, Vector2(size.x - 28 - w_bat, 52), pct, p.get("carregando", false), 48.0)

	if not conectado:
		Desenho.texto(self, Vector2(x, 104), "O controle saiu.", fonte, Tema.T_ROTULO, Tema.FG)
		Desenho.texto(self, Vector2(x, 144), "Religue o mesmo para voltar.", Tema.fonte(400), Tema.T_ROTULO, Tema.SUAVE)
		_dica(Vector2(x, size.y - 40), "circulo", "Liberar o lugar", Tema.SUAVE, Tema.MUDO)
		return

	# linha 2: o nome que o controle dá
	# o nome encolhe até caber (em inglês, "Simulated DualSense 2" é mais longo)
	var nome := str(p.get("nome", "controle"))
	var tam_nome := 30
	while tam_nome > 22 and Desenho.largura(nome, Tema.fonte(500), tam_nome) > size.x - 56:
		tam_nome -= 1
	Desenho.texto(self, Vector2(x, 98), nome, Tema.fonte(500), tam_nome, Tema.FG, HORIZONTAL_ALIGNMENT_LEFT, size.x - 56)

	# rodapé: pronto, ou as ações do dono do lugar
	# as ações vão uma sob a outra: "Botão ✕ (Pronto)" não cabe ao lado de outra em 384 px
	if pronto:
		Desenho.selo(self, Vector2(x, size.y - 100), "✓ Pronto", Tema.VERDE)
		_dica(Vector2(x, size.y - 32), "circulo", "Voltar", Tema.SUAVE, Tema.MUDO)
	else:
		_dica(Vector2(x, size.y - 70), "cruz", "Pronto", Tema.FG, Tema.SUAVE)
		_dica(Vector2(x, size.y - 32), "circulo", "Sair", Tema.SUAVE, Tema.MUDO, false)


## Uma dica do rodapé do cartão: encolhe até caber na largura do cartão.
func _dica(pos: Vector2, glifo: String, texto: String, cor_glifo: Color, cor_texto: Color, com_botao := true) -> void:
	var tam := Tema.T_ROTULO
	while tam > 18 and Glifo.largura_dica(glifo, texto, tam, com_botao) > size.x - 2.0 * pos.x:
		tam -= 1
	Glifo.dica(self, pos, glifo, texto, tam, cor_glifo, cor_texto, com_botao)
