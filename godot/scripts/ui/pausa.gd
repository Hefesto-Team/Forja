class_name Pausa
extends Control
## A pausa da fita (arte/06, a pausa): a tela parada e desbotada (o pós, que o main.gd ajusta), a barra de pausa
## subindo a tela a cada 2 s e o J-card que entra pela direita com as linhas. Quem pausou navega; ✕ escolhe, ○ volta.

signal escolheu(acao: String)

const JCARD := Rect2(760, 90, 1064, 830)
const ENTRA_DE := 1100.0  ## o J-card entra de x + 1100 até o lugar dele
const ENTRA_MS := 500.0   ## em 1 batida a 120, `SAI`
const LINHA_Y := 160.0    ## a primeira linha, dentro do cartão
const LINHA_ALTURA := 84.0
const LINHA_LETRA := 44
const BARRA_ALTURA := 24.0
const BARRA_S := 2.0      ## a barra sobe a tela inteira a cada 2 s, `RETA`
const LISTRA := 2.0

var opcoes: Array = []  # [[acao, texto]]
var escolhida := 0
var quem := 0  ## o lugar que pausou
var tinta := Tema.GRAFITE  ## a tinta da seção da sala; fora da sala, grafite
var aberta_ha := 0.0  ## os segundos desde que abriu (a entrada do J-card e a barra)
var _quadro := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func abrir(lugar: int, na_sala: bool, com_diagnostico := true, bancada := true, tinta_da_sala := Tema.GRAFITE) -> void:
	quem = lugar
	escolhida = 0
	tinta = tinta_da_sala
	aberta_ha = 0.0
	opcoes = [["continuar", "Continuar"]]
	if com_diagnostico and bancada:
		opcoes.append(["diagnostico", "Diagnóstico"])
	if bancada:
		opcoes.append(["livro", "O livro da sessão"])
	opcoes.append(["opcoes", "Opções"])
	if na_sala:
		opcoes.append(["salao", "Voltar ao salão"])
	else:
		opcoes.append(["lobby", "Voltar ao lobby"])
	opcoes.append(["sair", "Sair"])


func navegar(dy: int) -> void:
	escolhida = wrapi(escolhida + dy, 0, opcoes.size())


func confirmar() -> void:
	escolheu.emit(opcoes[escolhida][0])


func _process(dt: float) -> void:
	if visible:
		aberta_ha += dt
		_quadro += 1
		queue_redraw()


## Quanto o J-card ainda está à direita do lugar dele (px): de 1100 a 0 em 500 ms, `SAI` (a cúbica que freia).
func deslocamento() -> float:
	var k := clampf(aberta_ha * 1000.0 / ENTRA_MS, 0.0, 1.0)
	return ENTRA_DE * (1.0 - float(Tween.interpolate_value(0.0, 1.0, k, 1.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)))


## O alto da barra de pausa agora: de y 1080 a −24, em linha reta, a cada 2 s.
func altura_da_barra() -> float:
	var k := fmod(aberta_ha, BARRA_S) / BARRA_S
	return lerpf(size.y, -BARRA_ALTURA, k)


## A barra de pausa: 24 px de ruído, listras de 2 px em grafite e mudo que trocam a cada quadro. É piscar: sem os
## Flashes, ela não aparece (arte/10).
func _barra() -> void:
	var y := altura_da_barra()
	var n := int(BARRA_ALTURA / LISTRA)
	for i in n:
		var cor := Tema.GRAFITE if (i + _quadro) % 2 == 0 else Tema.MUDO
		draw_rect(Rect2(Vector2(0, y + i * LISTRA), Vector2(size.x, LISTRA)), cor)


func _draw() -> void:
	if Opcoes.flashes:
		_barra()
	var dx := deslocamento()
	var r := Rect2(JCARD.position + Vector2(dx, 0), JCARD.size)
	# o cartão que ainda entra sai da tela: a coleta da prova visual mede o cartão parado
	var coleta := Desenho.coletar_retangulos
	if dx > 0.5:
		Desenho.coletar_retangulos = false
	Desenho.jcard(self, r, tinta, "PAUSA · P%d" % (quem + 1))
	Desenho.inclinar(self, r.get_center(), Desenho.JCARD_INCLINACAO)
	var dono: Color = Forja.cor_do_lugar(quem)
	var f := Tema.archivo(600)
	var x0 := r.position.x + Desenho.JCARD_LOMBADA + 44.0
	var x_texto := x0 + 20.0 + Desenho.LADO_DA_DICA + 16.0
	for i in opcoes.size():
		var b := Rect2(Vector2(x0, r.position.y + LINHA_Y + i * LINHA_ALTURA), Vector2(r.end.x - 44.0 - x0, LINHA_ALTURA - 12.0))
		if i == escolhida:
			Desenho.caixa(self, b, Color(Tema.ETIQUETA, 0.0), Tema.RAIO_ETIQUETA, dono, Tema.BORDA_PLACA)
			Glifo.desenhar(self, "cruz", Rect2(Vector2(x0 + 20.0, b.get_center().y - Desenho.LADO_DA_DICA * 0.5),
				Vector2(Desenho.LADO_DA_DICA, Desenho.LADO_DA_DICA)), Tema.TINTA)
		# «Sair» também em tinta: o vermelhão só passa sobre a etiqueta a 48 px ou mais (arte/06)
		Desenho.texto(self, Vector2(x_texto, b.get_center().y + f.get_ascent(Tema.t(LINHA_LETRA)) * 0.36), opcoes[i][1], f,
			LINHA_LETRA, Tema.TINTA)
	var y_dica := r.end.y - 44.0 - Desenho.LADO_DA_DICA
	var x := x0
	x += Desenho.dica(self, Vector2(x, y_dica), "cruz", "Escolher", true) + Desenho.VAO_DAS_DICAS
	Desenho.dica(self, Vector2(x, y_dica), "circulo", "Voltar", true)
	Desenho.inclinar(self, Vector2.ZERO, 0.0)
	Desenho.coletar_retangulos = coleta
