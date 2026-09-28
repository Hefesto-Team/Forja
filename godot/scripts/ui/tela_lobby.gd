class_name TelaLobby
extends Control
## O lobby: quem joga. Cada controle aperta ✕ e ganha um lugar (P1..P4): o
## módulo acende a barra de luz na cor do lugar e as lâmpadas no padrão dele,
## e o cartão mostra o que foi lido e o que foi mandado. Com todos prontos, a
## partida começa.

var prontos := [false, false, false, false]
var contagem := -1.0
## Onde fica o pé de cada pedestal na tela, e o visual de cada boneco
## ([boneco, o que leva]) — o main atualiza a cada quadro.
var pes := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var visual := [["", ""], ["", ""], ["", ""], ["", ""]]
var cartoes: Array[CartaoJogador] = []

const LARGURA_CARTAO := 384.0
const ALTURA_CARTAO := 300.0
const CALHA := 48.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 4:
		var c := CartaoJogador.new()
		c.lugar = i
		add_child(c)
		cartoes.append(c)
	resized.connect(_posicionar)
	_posicionar()


func _posicionar() -> void:
	var total := LARGURA_CARTAO * 4 + CALHA * 3
	var x0 := (size.x - total) * 0.5
	for i in 4:
		cartoes[i].position = Vector2(x0 + i * (LARGURA_CARTAO + CALHA), size.y - Tema.MARGEM_Y - ALTURA_CARTAO - 40)
		cartoes[i].size = Vector2(LARGURA_CARTAO, ALTURA_CARTAO)


func _process(_dt: float) -> void:
	for i in 4:
		cartoes[i].pronto = prontos[i]
	queue_redraw()


func _draw() -> void:
	var h := size.y
	# a tarja de cima, atrás do título (as placas dos portões ficam por baixo)
	draw_rect(Rect2(0, 0, size.x, 150), Color(Tema.CASA, 0.86))
	for i in 24:
		draw_rect(Rect2(0, 150 + i * 5, size.x, 5), Color(Tema.CASA, 0.86 * (1.0 - i / 24.0)))
	# a tarja de baixo, atrás dos cartões
	var topo_cartoes := cartoes[0].position.y
	for i in 30:
		draw_rect(Rect2(0, topo_cartoes - 180 + i * 6, size.x, 6), Color(Tema.CASA, 0.82 * i / 30.0))
	draw_rect(Rect2(0, topo_cartoes, size.x, h - topo_cartoes), Color(Tema.CASA, 0.82))

	Desenho.cabecalho(self, Vector2(Tema.MARGEM_X, Tema.MARGEM_Y), 72.0)
	var f := Tema.fonte(700)
	var titulo := "Quem joga"
	Desenho.texto(self, Vector2(0, 118), titulo, f, Tema.T_TITULO, Tema.FG, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	# a linha de baixo do título diz o estado: quem falta, ou que todos estão prontos
	var sub := "Aperte ✕ no seu controle para entrar."
	var cor_sub := Tema.SUAVE
	if contagem >= 0.0:
		sub = "Todos prontos"
		cor_sub = Tema.VERDE
	elif Forja.jogadores() > 0:
		var faltam := 0
		for i in 4:
			if Forja.ocupado(i) and not prontos[i]:
				faltam += 1
		sub = "Falta 1 jogador ficar pronto" if faltam == 1 else "Faltam %d jogadores ficarem prontos" % faltam
	Desenho.texto(self, Vector2(0, 172), sub, Tema.fonte(500 if contagem >= 0.0 else 400), Tema.T_CORPO, cor_sub,
		HORIZONTAL_ALIGNMENT_CENTER, size.x)
	for i in 4:
		if Forja.ocupado(i):
			_seletor(i)

	# à direita: quantos controles o jogo vê
	var n := Forja.conectados()
	var txt := "%d controle%s" % [n, "s" if n != 1 else ""]
	var ftxt := Tema.fonte(600)
	var wt := Desenho.largura(txt, ftxt, Tema.T_ROTULO)
	var xd := size.x - Tema.MARGEM_X - wt
	draw_circle(Vector2(xd - 20, Tema.MARGEM_Y + 32), 7, Tema.VERDE if n > 0 else Tema.LARANJA)
	Desenho.texto(self, Vector2(xd, Tema.MARGEM_Y + 42), txt, ftxt, Tema.T_ROTULO, Tema.VERDE if n > 0 else Tema.LARANJA)



## O seletor do visual, no pé do pedestal: ◀ boneco ▶ e ▲ o que leva ▼. Pronto,
## ele some (a escolha fica no boneco).
func _seletor(l: int) -> void:
	if prontos[l] or pes[l] == Vector2.ZERO:
		return
	var boneco: String = visual[l][0]
	var leva: String = visual[l][1]
	var f1 := Tema.fonte(600)
	var f2 := Tema.fonte(500)
	var larg := maxf(Desenho.largura(boneco, f1, 26), Desenho.largura(leva, f2, 24)) + 120.0
	var r := Rect2(Vector2(pes[l].x - larg * 0.5, pes[l].y + 8), Vector2(larg, 84))
	Desenho.moldura(self, r, Color(Tema.PAINEL, 0.94), Tema.ROXO, 2, 12)
	var cx := r.get_center().x
	Glifo.desenhar(self, "esquerda", Rect2(Vector2(r.position.x + 12, r.position.y + 10), Vector2(30, 30)), Tema.SUAVE)
	Glifo.desenhar(self, "direita", Rect2(Vector2(r.end.x - 42, r.position.y + 10), Vector2(30, 30)), Tema.SUAVE)
	Desenho.texto(self, Vector2(cx - Desenho.largura(boneco, f1, 26) * 0.5, r.position.y + 35), boneco, f1, 26, Tema.FG)
	Glifo.desenhar(self, "cima", Rect2(Vector2(r.position.x + 12, r.position.y + 48), Vector2(30, 30)), Tema.SUAVE)
	Glifo.desenhar(self, "baixo", Rect2(Vector2(r.end.x - 42, r.position.y + 48), Vector2(30, 30)), Tema.SUAVE)
	Desenho.texto(self, Vector2(cx - Desenho.largura(leva, f2, 24) * 0.5, r.position.y + 72), leva, f2, 24, Tema.ROXO)
