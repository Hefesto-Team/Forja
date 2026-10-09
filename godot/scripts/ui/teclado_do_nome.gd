class_name TecladoDoNome
extends RefCounted
## O teclado de tela do nome (G09): um por lugar, na coluna de 432 px da
## construção, escrito pelo próprio controle. A grade é de 7 colunas por 5
## linhas; ✕ põe a letra, ◯ apaga, △ sorteia, R1 leva a "Pronto". O estado é do
## lugar, nunca global: quatro teclados abertos ao mesmo tempo.
##
## O texto guardado já vem com a caixa certa (a primeira letra de cada palavra
## em maiúscula, as outras minúsculas). A repetição do direcional segurado conta
## em segundos de parede, não em quadros: com --fixed-fps o robô andaria rápido.

const GRADE := [
	["A", "B", "C", "D", "E", "F", "G"],
	["H", "I", "J", "K", "L", "M", "N"],
	["O", "P", "Q", "R", "S", "T", "U"],
	["V", "W", "X", "Y", "Z", "Ç", " "],
	["´", "~", "^", "⌫", "PRONTO", "PRONTO", "PRONTO"],
]
## Sobre a última letra, em maiúscula.
const ACENTOS := {
	"´": {"A": "Á", "E": "É", "I": "Í", "O": "Ó", "U": "Ú"},
	"~": {"A": "Ã", "O": "Õ"},
	"^": {"A": "Â", "E": "Ê", "O": "Ô"},
}
const COLUNAS := 7
const LINHAS := 5
const PRIMEIRA_DO_PRONTO := 4      ## o Pronto ocupa as colunas 4 a 6 da última linha
const MAXIMO := 12                  ## caracteres, contando o espaço
const MINIMO := 2                   ## letras (o espaço não conta)
const TECLA := 52.0
const VAO := 6.0
const RAIO := 6
const CAMPO := Rect2(16, 660, 400, 44)
const GRADE_X := 16.0
const GRADE_Y := 716.0
const LIMIAR := 0.5                 ## o direcional além disto anda o cursor
const REPETE_PRIMEIRA_MS := 400
const REPETE_DEPOIS_MS := 150
const CURSOR_MS := 67               ## 4 quadros a 60

var cursor := Vector2i(0, 0)        ## (coluna, linha)
var texto := ""
var outros: Array = []              ## os nomes dos outros lugares, já formatados (o único na mesa)
var digitou := false                ## alguma tecla de letra, acento ou espaço entrou (o nome é escrito, não sorteado)
var abriu_em_ms := 0

var _dir := Vector2i.ZERO
var _proxima_ms := 0
var _anda_de := Rect2()             ## de onde o cursor vem, em coordenadas da coluna (animação)
var _anda_em_ms := -10000


## A largura da grade: 7 teclas de 52 e 6 vãos de 6.
static func largura_da_grade() -> float:
	return COLUNAS * TECLA + (COLUNAS - 1) * VAO


## A altura da grade: 5 teclas e 4 vãos.
static func altura_da_grade() -> float:
	return LINHAS * TECLA + (LINHAS - 1) * VAO


## A caixa do nome: a primeira letra de cada palavra em maiúscula, as outras em
## minúscula. Não apara o espaço do fim (quem escreve ainda vai pôr a próxima letra).
static func formatar(t: String) -> String:
	var saida := ""
	var comeco := true
	for i in t.length():
		var c := t[i]
		saida += c.to_upper() if comeco else c.to_lower()
		comeco = c == " "
	return saida


## O nome que se grava: com a caixa e sem o espaço do fim.
static func nome_final(t: String) -> String:
	return formatar(t).strip_edges()


## Quantas letras o texto tem (o espaço não conta).
static func letras(t: String) -> int:
	return t.replace(" ", "").length()


## Abre com um nome (o atual do lugar).
func abrir(nome: String, agora_ms: int) -> void:
	texto = formatar(nome)
	cursor = Vector2i(PRIMEIRA_DO_PRONTO, LINHAS - 1) if letras(texto) >= MINIMO else Vector2i(0, 0)
	digitou = false
	abriu_em_ms = agora_ms
	_dir = Vector2i.ZERO
	_anda_em_ms = -10000
	_anda_de = _retangulo_da_tecla(cursor)


func no_pronto() -> bool:
	return cursor.y == LINHAS - 1 and cursor.x >= PRIMEIRA_DO_PRONTO


## O nome do campo é igual ao de outro lugar (a comparação é depois de formatar).
func repetido() -> bool:
	var f := nome_final(texto)
	for o in outros:
		if str(o) == f:
			return true
	return false


## O Pronto fecha: o mínimo de letras e nenhum outro lugar com o mesmo nome.
func pode_gravar() -> bool:
	return letras(texto) >= MINIMO and not repetido()


## Anda o cursor uma tecla. Nas bordas para, não dá a volta. Devolve se andou.
func mover(d: Vector2i) -> bool:
	var novo := cursor
	if no_pronto() and d.x != 0:
		novo.x = PRIMEIRA_DO_PRONTO - 1 if d.x < 0 else cursor.x
	else:
		novo = Vector2i(clampi(cursor.x + d.x, 0, COLUNAS - 1), clampi(cursor.y + d.y, 0, LINHAS - 1))
	if novo == cursor:
		return false
	_anda_de = _retangulo_da_tecla(cursor)
	_anda_em_ms = Time.get_ticks_msec()
	cursor = novo
	return true


## O direcional ou o analógico esquerdo, a cada quadro: anda uma tecla ao passar de
## 0,5; segurando, repete depois de 0,40 s e a cada 0,15 s (segundos de parede).
## Devolve se o cursor andou.
func quadro(eixo: Vector2, agora_ms: int) -> bool:
	var d := Vector2i.ZERO
	if maxf(absf(eixo.x), absf(eixo.y)) > LIMIAR:
		if absf(eixo.x) >= absf(eixo.y):
			d = Vector2i(1 if eixo.x > 0.0 else -1, 0)
		else:
			d = Vector2i(0, 1 if eixo.y > 0.0 else -1)
	if d == Vector2i.ZERO:
		_dir = d
		return false
	if d != _dir:
		_dir = d
		_proxima_ms = agora_ms + REPETE_PRIMEIRA_MS
		return mover(d)
	if agora_ms >= _proxima_ms:
		_proxima_ms = agora_ms + REPETE_DEPOIS_MS
		return mover(d)
	return false


## ✕ na tecla do cursor. Devolve "pronto" (fecha e grava), "tecla" (algo entrou ou
## saiu do campo) ou "" (nada mudou: a tecla não entra).
func escolher() -> String:
	var tecla: String = GRADE[cursor.y][cursor.x]
	match tecla:
		"PRONTO":
			return "pronto" if pode_gravar() else ""
		"⌫":
			return "tecla" if apagar() else ""
		" ":
			if texto == "" or texto.ends_with(" ") or texto.length() >= MAXIMO:
				return ""
			texto += " "
			digitou = true
			return "tecla"
		"´", "~", "^":
			if texto == "":
				return ""
			var ultima := texto.substr(texto.length() - 1).to_upper()
			var acentuada: String = ACENTOS[tecla].get(ultima, "")
			if acentuada == "":
				return ""
			texto = formatar(texto.left(texto.length() - 1) + acentuada)
			digitou = true
			return "tecla"
	if texto.length() >= MAXIMO:
		return ""
	texto = formatar(texto + tecla)
	digitou = true
	return "tecla"


## Apaga a última letra. false com o campo vazio.
func apagar() -> bool:
	if texto == "":
		return false
	texto = formatar(texto.left(texto.length() - 1))
	return true


## △: pões no campo o nome sorteado e levas o cursor a Pronto.
func sortear(nome: String) -> void:
	texto = formatar(nome)
	digitou = false
	para_o_pronto()


## R1: o cursor vai a Pronto.
func para_o_pronto() -> void:
	if no_pronto():
		return
	_anda_de = _retangulo_da_tecla(cursor)
	_anda_em_ms = Time.get_ticks_msec()
	cursor = Vector2i(PRIMEIRA_DO_PRONTO, LINHAS - 1)


# ------------------------------------------------------------ o desenho --

## A tecla (c, l) na coluna: o Pronto é uma tecla só, de 3 colunas.
static func _retangulo_da_tecla(c: Vector2i) -> Rect2:
	if c.y == LINHAS - 1 and c.x >= PRIMEIRA_DO_PRONTO:
		return Rect2(GRADE_X + PRIMEIRA_DO_PRONTO * (TECLA + VAO), GRADE_Y + c.y * (TECLA + VAO),
			3.0 * TECLA + 2.0 * VAO, TECLA)
	return Rect2(GRADE_X + c.x * (TECLA + VAO), GRADE_Y + c.y * (TECLA + VAO), TECLA, TECLA)


## A caixa da tecla sob o cursor, em coordenadas da coluna (a que se desenha agora).
func retangulo_do_cursor() -> Rect2:
	return _retangulo_da_tecla(cursor)


## O campo e a grade, a partir do canto de cima à esquerda da coluna (`x0` no `ci`).
## A cor do dono é a do lugar: a borda do campo, a tecla sob o cursor e o Pronto.
func desenhar(ci: CanvasItem, x0: float, cor_do_dono: Color) -> void:
	var batida := Ritmo.batida()
	# o campo: o nome e a barra do cursor de texto (parada, não pisca)
	var campo := Rect2(CAMPO.position + Vector2(x0, 0), CAMPO.size)
	Desenho.caixa(ci, campo, Tema.CASCO_ALTO, RAIO, cor_do_dono, 3)
	var f_campo := Tema.archivo(600)
	var cor_do_nome := Tema.ETIQUETA
	if repetido():
		cor_do_nome = Tema.ETIQUETA if int(floorf(batida)) % 2 == 0 else Tema.MUDO
	var mostrado := Desenho.nome_que_cabe(formatar(texto), f_campo, 32, CAMPO.size.x - 12.0 - 8.0 - 3.0)
	Desenho.nome(ci, Vector2(campo.position.x + 12.0, campo.position.y + 34.0), mostrado, f_campo, 32, cor_do_nome)
	var fim := Desenho.largura_do_nome(mostrado, f_campo, 32)
	ci.draw_rect(Rect2(campo.position.x + 12.0 + fim + 2.0, campo.position.y + 6.0, 3.0, 32.0), Tema.ETIQUETA)
	# a grade: a tecla sob o cursor leva o fundo alto, e a borda do dono anda por cima
	var f_tecla := Tema.archivo(600)
	for l in LINHAS:
		for c in COLUNAS:
			var tecla: String = GRADE[l][c]
			if tecla == "PRONTO" and c != PRIMEIRA_DO_PRONTO:
				continue
			var r := _retangulo_da_tecla(Vector2i(c, l))
			r.position.x += x0
			var sob_o_cursor := _retangulo_da_tecla(cursor) == _retangulo_da_tecla(Vector2i(c, l))
			if tecla == "PRONTO":
				Desenho.caixa(ci, r, cor_do_dono if pode_gravar() else (Tema.CASCO_ALTO if sob_o_cursor else Tema.CASCO), RAIO)
				Desenho.texto(ci, Vector2(r.position.x, r.position.y + 38.0), "Pronto", Tema.archivo(700), 34,
					Tema.TINTA if pode_gravar() else Tema.MUDO, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
				continue
			Desenho.caixa(ci, r, Tema.CASCO_ALTO if sob_o_cursor else Tema.CASCO, RAIO)
			match tecla:
				" ":
					ci.draw_rect(Rect2(r.position.x + (TECLA - 24.0) * 0.5, r.end.y - 14.0 - 4.0, 24.0, 4.0), Tema.ETIQUETA)
				"⌫":
					Glifo.desenhar(ci, "circulo", Rect2(r.position + Vector2(6, 6), Vector2(40, 40)), Tema.ETIQUETA)
				_:
					Desenho.texto(ci, Vector2(r.position.x, r.position.y + 39.0), tecla, f_tecla, 36, Tema.ETIQUETA,
						HORIZONTAL_ALIGNMENT_CENTER, TECLA)
	# a borda: anda em 4 quadros (SAI); sem tremor (movimento reduzido), pula. No quadro de cada
	# batida vai a 5 px e volta a 3 px em 1 colcheia.
	var alvo := _retangulo_da_tecla(cursor)
	var k := clampf(float(Time.get_ticks_msec() - _anda_em_ms) / CURSOR_MS, 0.0, 1.0)
	if not Opcoes.tremor:
		k = 1.0
	k = 1.0 - pow(1.0 - k, 3.0)
	var onde := Rect2(_anda_de.position.lerp(alvo.position, k), _anda_de.size.lerp(alvo.size, k))
	onde.position.x += x0
	var p := minf((batida - floorf(batida)) / 0.5, 1.0)
	var largura := 3.0 + 2.0 * pow(1.0 - p, 3.0)
	Desenho.caixa(ci, onde, Color(Tema.CASCO, 0.0), RAIO, cor_do_dono, int(roundf(largura)))
