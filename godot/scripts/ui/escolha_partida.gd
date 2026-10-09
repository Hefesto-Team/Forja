class_name EscolhaPartida
extends Control
## A escolha da partida, na bigorna: três linhas, cada uma com o seu valor —
## quantas salas, em que ordem e em que ritmo. ▲▼ escolhe a linha, ◀▶ troca o
## valor, ✕ começa, ○ volta. As salas da escolha aparecem ao lado, na ordem em
## que se jogam.

signal escolheu(n: int, sorteada: bool)

const TAMANHOS := [[3, "3 salas", "Uns 10 min"], [5, "5 salas", "Uns 15 min"], [9, "As 9 salas", "Uns 30 min"]]
const ORDENS := ["A do percurso", "Sorteada"]

var quem := 0  ## o lugar que abriu
var linha := 0  ## 0 salas, 1 ordem, 2 nível
var tamanho := 1
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
	linha = 0


func navegar(dy: int) -> void:
	linha = wrapi(linha + dy, 0, 3)


## ◀▶ na linha escolhida.
func trocar(dx: int) -> void:
	match linha:
		0: tamanho = wrapi(tamanho + dx, 0, TAMANHOS.size())
		1: sorteada = not sorteada
		2: Forja.nivel = wrapi(Forja.nivel + dx, 0, Forja.NIVEIS.size())


func confirmar() -> void:
	escolheu.emit(int(TAMANHOS[tamanho][0]), sorteada)


func _process(_dt: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.CASCO, 0.84))
	var larg := 1280.0
	var alt := 640.0
	var r := Rect2(Vector2((size.x - larg) * 0.5, (size.y - alt) * 0.5), Vector2(larg, alt))
	Desenho.moldura(self, r, Tema.CASCO, Tema.GRAFITE, 2, Tema.RAIO_QUADRO)
	Desenho.texto(self, r.position + Vector2(48, 84), "A partida", Tema.bungee(), Tema.T_TITULO, Tema.ETIQUETA)
	var cor_id := Tema.tom_para_a_borda(Forja.cor_do_lugar(quem))
	var q := "P%d escolhe" % (quem + 1)
	var fq := Tema.archivo(600)
	Desenho.texto(self, Vector2(r.end.x - 48 - Desenho.largura(q, fq, Tema.T_SELO), r.position.y + 76), q, fq, Tema.T_SELO, cor_id)
	var valores := [
		[TAMANHOS[tamanho][1], TAMANHOS[tamanho][2]],
		[ORDENS[1 if sorteada else 0], ""],
		[Forja.NIVEIS[Forja.nivel], ""],
	]
	var rotulos := ["Salas", "Ordem", "Ritmo"]
	var col := 600.0
	for i in 3:
		var b := Rect2(r.position + Vector2(48, 136 + i * 124), Vector2(col, 104))
		var sel := i == linha
		Desenho.moldura(self, b, Tema.CASCO_ALTO if sel else Tema.CASCO, cor_id if sel else Tema.GRAFITE, 4 if sel else 2, Tema.RAIO_BOTAO)
		Desenho.texto(self, b.position + Vector2(28, 38), rotulos[i], Tema.archivo(600), Tema.T_SELO, Tema.ETIQUETA)
		var v := str(valores[i][0])
		Desenho.texto(self, b.position + Vector2(28, 82), v, Tema.archivo(600 if sel else 500), Tema.T_CORPO, Tema.ETIQUETA if sel else Tema.ETIQUETA_SOMBRA)
		if str(valores[i][1]) != "":
			Desenho.texto(self, b.position + Vector2(44 + Desenho.largura(v, Tema.archivo(600), Tema.T_CORPO), 82),
				str(valores[i][1]), Tema.archivo(500), Tema.T_SELO, Tema.MUDO)
		if sel:
			# as setas dizem que ◀▶ troca esta linha
			Glifo.desenhar(self, "esquerda", Rect2(Vector2(b.end.x - 100, b.position.y + 34), Vector2(36, 36)), Tema.ETIQUETA)
			Glifo.desenhar(self, "direita", Rect2(Vector2(b.end.x - 56, b.position.y + 34), Vector2(36, 36)), Tema.ETIQUETA)
	# as salas da escolha, à direita
	var x2 := r.position.x + 48 + col + 56
	var salas := Partida.roteiro(int(TAMANHOS[tamanho][0]), sorteada, semente, percurso)
	var tam := Tema.T_ROTULO if salas.size() > 5 else Tema.T_CORPO
	var passo_y := 46.0 if salas.size() > 5 else 60.0
	for i in salas.size():
		var y := r.position.y + 170 + i * passo_y
		Desenho.texto(self, Vector2(x2, y), "%d" % (i + 1), Tema.vt(), tam, Tema.ETIQUETA)
		Desenho.texto(self, Vector2(x2 + 48, y), str(Partida.NOMES.get(salas[i], salas[i])), Tema.archivo(500), tam, Tema.ETIQUETA)
	Desenho.dicas_a_direita(self, Vector2(r.end.x - 48, r.end.y + 60),
		[["cima", "Linha"], ["esquerda", "Trocar"], ["cruz", "Começar"], ["circulo", "Voltar"]], Tema.T_SELO)
