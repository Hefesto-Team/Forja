class_name Pausa
extends Control
## A pausa: uma lista curta, navegada por quem pausou. ✕ escolhe, ○ volta.

signal escolheu(acao: String)

var opcoes: Array = []  # [[acao, texto]]
var escolhida := 0
var quem := 0  ## o lugar que pausou


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func abrir(lugar: int, na_sala: bool, com_diagnostico := true) -> void:
	quem = lugar
	escolhida = 0
	opcoes = [["continuar", "Continuar"]]
	if com_diagnostico:
		opcoes.append(["diagnostico", "Diagnóstico"])
	opcoes.append(["livro", "O livro da sessão"])
	if na_sala:
		opcoes.append(["salao", "Voltar ao salão"])
	opcoes.append(["lobby", "Voltar ao lobby"])
	opcoes.append(["sair", "Sair do jogo"])


func navegar(dy: int) -> void:
	escolhida = wrapi(escolhida + dy, 0, opcoes.size())


func confirmar() -> void:
	escolheu.emit(opcoes[escolhida][0])


func _process(_dt: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.APP, 0.82))
	var larg := 620.0
	var alt := 150.0 + opcoes.size() * 84.0
	var r := Rect2(Vector2((size.x - larg) * 0.5, (size.y - alt) * 0.5), Vector2(larg, alt))
	Desenho.moldura(self, r, Tema.PAINEL, Tema.LINHA, 2, Tema.RAIO_QUADRO)
	Desenho.texto(self, r.position + Vector2(40, 72), "Pausa", Tema.fonte(700), 48, Tema.FG)
	var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(quem))
	var q := "P%d pausou" % (quem + 1)
	var fq := Tema.fonte(600)
	Desenho.texto(self, Vector2(r.end.x - 40 - Desenho.largura(q, fq, Tema.T_SELO), r.position.y + 68), q, fq, Tema.T_SELO, cor_id)
	for i in opcoes.size():
		var b := Rect2(r.position + Vector2(40, 110 + i * 84), Vector2(larg - 80, 68))
		if i == escolhida:
			Desenho.moldura(self, b, Tema.SEL, Tema.ROXO, 3, Tema.RAIO_BOTAO)
		else:
			Desenho.moldura(self, b, Tema.APP, Tema.LINHA, 2, Tema.RAIO_BOTAO)
		var cor := Tema.FG if i == escolhida else Tema.SUAVE
		if opcoes[i][0] == "sair":
			cor = Tema.VERMELHO
		Desenho.texto(self, b.position + Vector2(28, 45), opcoes[i][1], Tema.fonte(600 if i == escolhida else 500), Tema.T_CORPO, cor)
	Desenho.dicas_a_direita(self, Vector2(r.end.x - 40, r.end.y + 60), [["cruz", "escolher"], ["circulo", "voltar"]], Tema.T_SELO)
