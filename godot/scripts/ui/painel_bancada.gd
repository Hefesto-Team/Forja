class_name PainelBancada
extends Control
## O painel da bancada: o experimento e a pergunta dele, o que está
## acontecendo agora e cada resultado, com o lugar (ou "todos", quando a
## medida é dos quatro juntos) e o selo — medido, falhou ou não medido (o que
## não deu para medir também é resultado, com o porquê).

var bancada: SalaBancada


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(_dt: float) -> void:
	queue_redraw()


func _draw() -> void:
	if bancada == null or not is_instance_valid(bancada):
		return
	var larg := minf(1500.0, size.x - 2 * Tema.MARGEM_X)
	var x := (size.x - larg) * 0.5
	var fo := Tema.fonte(400)
	var pergunta := str(SalaBancada.EXPERIMENTOS[bancada.chave][1])
	var alt_perg := Desenho.altura_paragrafo(pergunta, fo, Tema.T_ROTULO, larg - 96)
	var y0 := 40.0
	var r := Rect2(Vector2(x, y0), Vector2(larg, size.y - y0 - 110))
	Desenho.moldura(self, r, Color(Tema.PAINEL, 0.93), Tema.LINHA, 2, Tema.RAIO_QUADRO)
	var cx := x + 48
	var y := y0 + 58
	Desenho.texto(self, Vector2(cx, y), "experimental/ · a bancada dos experimentos", Tema.fonte(600), Tema.T_SELO, Tema.ROXO)
	y += 58
	Desenho.texto(self, Vector2(cx, y), str(bancada.nome), Tema.fonte(700), Tema.T_SUBTITULO, Tema.FG)
	y += 22
	Desenho.paragrafo(self, Vector2(cx, y + 26), pergunta, fo, Tema.T_ROTULO, Tema.SUAVE, larg - 96)
	y += alt_perg + 48
	Desenho.texto(self, Vector2(cx, y), str(bancada.agora), Tema.fonte(600), Tema.T_ROTULO,
		Tema.VERDE if bancada.acabou else Tema.FG, HORIZONTAL_ALIGNMENT_LEFT, larg - 96)
	y += 34
	var cores := [Tema.VERDE, Tema.VERMELHO, Tema.MUDO]
	var ft := Tema.fonte(400)
	for linha in bancada.linhas:
		var l: int = linha[0]
		var res: int = linha[1]
		var texto := str(linha[2])
		var alt := Desenho.altura_paragrafo(texto, ft, 22, larg - 400)
		if y + alt + 24 > r.end.y - 20:
			break
		y += 16
		if l >= 0:
			Desenho.texto(self, Vector2(cx, y + 24), "P%d" % (l + 1), Tema.fonte(700), Tema.T_ROTULO,
				Tema.tom_para_a_borda(Forja.cor_do_lugar(l)))
		else:
			Desenho.texto(self, Vector2(cx, y + 24), "todos", Tema.fonte(600), Tema.T_SELO, Tema.SUAVE)
		Desenho.selo(self, Vector2(cx + 80, y + 2), SalaBancada.NOME_RES[res], cores[res], 20)
		Desenho.paragrafo(self, Vector2(cx + 280, y + 22), texto, ft, 22, Tema.FG, larg - 400)
		y += maxf(alt, 32.0) + 8
	var dicas := [["cruz", "repetir"], ["circulo", "sair"]] if bancada.acabou else [["options", "pausa"]]
	Desenho.dicas_a_direita(self, Vector2(size.x - Tema.MARGEM_X, size.y - Tema.MARGEM_Y), dicas, Tema.T_SELO)
