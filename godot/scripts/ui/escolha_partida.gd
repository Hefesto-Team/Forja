class_name EscolhaPartida
extends Control
## A escolha da partida, na bigorna: quantas salas e em que ordem. Quem abriu
## navega; ▲▼ escolhe a linha, ◀▶ troca a ordem, ✕ começa, ○ volta. As salas
## da partida escolhida aparecem ao lado, na ordem em que se jogam.

signal escolheu(n: int, sorteada: bool)

const LINHAS := [[3, "Partida curta", "três salas, uns 10 minutos"],
	[5, "Partida", "cinco salas, uns 15 minutos"],
	[9, "A noite inteira", "as nove salas, uns 30 minutos"]]

var quem := 0  ## o lugar que abriu
var escolhida := 1
var sorteada := false
var semente := 0
var percurso: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func abrir(lugar: int, semente_da_sessao: int, ordem_do_percurso: Array) -> void:
	quem = lugar
	semente = semente_da_sessao
	percurso = ordem_do_percurso


func navegar(dy: int) -> void:
	escolhida = wrapi(escolhida + dy, 0, LINHAS.size())


func trocar_ordem() -> void:
	sorteada = not sorteada


func confirmar() -> void:
	escolheu.emit(int(LINHAS[escolhida][0]), sorteada)


func _process(_dt: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.APP, 0.84))
	var larg := 1280.0
	var alt := 700.0
	var r := Rect2(Vector2((size.x - larg) * 0.5, (size.y - alt) * 0.5), Vector2(larg, alt))
	Desenho.moldura(self, r, Tema.PAINEL, Tema.LINHA, 2, Tema.RAIO_QUADRO)
	Desenho.texto(self, r.position + Vector2(48, 84), "A partida", Tema.fonte(700), Tema.T_TITULO, Tema.FG)
	var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(quem))
	var q := "P%d escolhe" % (quem + 1)
	var fq := Tema.fonte(600)
	Desenho.texto(self, Vector2(r.end.x - 48 - Desenho.largura(q, fq, Tema.T_SELO), r.position.y + 76), q, fq, Tema.T_SELO, cor_id)
	# os tamanhos, à esquerda
	var col := 600.0
	for i in LINHAS.size():
		var b := Rect2(r.position + Vector2(48, 190 + i * 118), Vector2(col, 100))
		var sel := i == escolhida
		Desenho.moldura(self, b, Tema.SEL if sel else Tema.APP, Tema.ROXO if sel else Tema.LINHA, 4 if sel else 2, Tema.RAIO_BOTAO)
		Desenho.texto(self, b.position + Vector2(28, 44), str(LINHAS[i][1]), Tema.fonte(600 if sel else 500), Tema.T_CORPO,
			Tema.FG if sel else Tema.SUAVE)
		Desenho.texto(self, b.position + Vector2(28, 80), str(LINHAS[i][2]), Tema.fonte(400), Tema.T_SELO, Tema.MUDO)
	# a ordem, embaixo dos tamanhos
	var ordem := "Ordem: sorteada" if sorteada else "Ordem: a do percurso"
	var yo := r.position.y + 190 + LINHAS.size() * 118 + 44
	Glifo.dica(self, Vector2(r.position.x + 48, yo), "esquerda", ordem, Tema.T_ROTULO, Tema.ROSA, Tema.FG)
	# as salas da escolha, à direita
	var x2 := r.position.x + 48 + col + 56
	Desenho.texto(self, Vector2(x2, r.position.y + 214), "As salas", Tema.fonte(600), Tema.T_SELO, Tema.ROXO)
	var salas := Partida.roteiro(int(LINHAS[escolhida][0]), sorteada, semente, percurso)
	var tam := Tema.T_ROTULO if salas.size() > 5 else Tema.T_CORPO
	var passo_y := 42.0 if salas.size() > 5 else 58.0
	for i in salas.size():
		var y := r.position.y + 262 + i * passo_y
		Desenho.texto(self, Vector2(x2, y), "%d" % (i + 1), Tema.mono(500), tam, Tema.CIANO)
		Desenho.texto(self, Vector2(x2 + 48, y), str(Partida.NOMES.get(salas[i], salas[i])), Tema.fonte(500), tam, Tema.FG)
	Desenho.dicas_a_direita(self, Vector2(r.end.x - 48, r.end.y + 60),
		[["cima", "tamanho"], ["esquerda", "ordem"], ["cruz", "começar"], ["circulo", "voltar"]], Tema.T_SELO)
