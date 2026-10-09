class_name ChecagensVisuais
extends RefCounted
## As checagens da prova visual (F09): funções puras sobre os dados que a prova
## colhe, para valer em todo quadro e não só nas fotos escolhidas. Cada uma
## devolve a lista de defeitos achados (texto para a pessoa ler); lista vazia é
## aprovada. Medem disposição (colisão, corte, tamanho, contraste, tela parada,
## relógio, fim sem vencedor), nunca a aparência da arte: nenhuma delas conhece
## uma cor do tema.
##
## Um quadro: {t: float (s de jogo), estado, sala, pausa: bool, pq: PackedByteArray
## (o quadro em 96×54 RGB8, para parada e vazia)}.
## Um texto: {frase, rect: Rect2 (pixels do jogo), tam: int (px), cor: Color,
## contraste: float (-1: não medido)}.

const AREA_SEGURA := 0.05  ## 5% de cada borda
const FONTE_MIN := 30  ## px, a letra que se lê do sofá
const PARADA_DIFERENCA := 0.005  ## 0,5% de diferença média de pixel
const PARADA_SEGUNDOS := 5.0
const VAZIA_FRACAO := 0.97
const VAZIA_NIVEIS := 8  ## níveis de 0 a 255
const CONTRASTE_MIN := 3.0  ## a razão da WCAG para letra grande
const SOBREPOSICAO_MIN := 0.10  ## da área do menor retângulo
const FPS_AVISO := 55.0
const PQ_L := 96
const PQ_A := 54


## O quadro pequeno (96×54 RGB8) que as checagens de imagem leem.
static func pequeno(img: Image) -> PackedByteArray:
	var m := img.duplicate() as Image
	m.convert(Image.FORMAT_RGB8)
	m.resize(PQ_L, PQ_A, Image.INTERPOLATE_BILINEAR)
	return m.get_data()


## A diferença média de pixel entre dois quadros pequenos, de 0 a 1.
static func diferenca(a: PackedByteArray, b: PackedByteArray) -> float:
	var n := mini(a.size(), b.size())
	if n == 0:
		return 0.0
	var soma := 0
	for i in n:
		soma += absi(int(a[i]) - int(b[i]))
	return float(soma) / (float(n) * 255.0)


## O mesmo quadro por mais de 5 s seguidos, fora da pausa.
static func tela_parada(quadros: Array) -> Array:
	var achados: Array = []
	var inicio := -1.0
	var avisado := false
	for i in range(1, quadros.size()):
		var a: Dictionary = quadros[i - 1]
		var b: Dictionary = quadros[i]
		if bool(a.pausa) or bool(b.pausa) or diferenca(a.pq, b.pq) >= PARADA_DIFERENCA:
			inicio = -1.0
			avisado = false
			continue
		if inicio < 0.0:
			inicio = float(a.t)
		if float(b.t) - inicio > PARADA_SEGUNDOS and not avisado:
			avisado = true
			achados.append("tela parada de %s a %s (%s)" % [hora(inicio), hora(float(b.t)), _onde(b)])
	return achados


## Quase todo o quadro de uma cor só.
static func tela_vazia(quadro: Dictionary) -> bool:
	var d: PackedByteArray = quadro.pq
	var n := d.size() / 3
	if n == 0:
		return false
	var canais: Array = [[], [], []]
	for i in n:
		for c in 3:
			canais[c].append(int(d[i * 3 + c]))
	var medio: Array = []
	for c in 3:
		canais[c].sort()
		medio.append(canais[c][n / 2])
	var perto := 0
	for i in n:
		if absi(int(d[i * 3]) - medio[0]) <= VAZIA_NIVEIS and absi(int(d[i * 3 + 1]) - medio[1]) <= VAZIA_NIVEIS \
				and absi(int(d[i * 3 + 2]) - medio[2]) <= VAZIA_NIVEIS:
			perto += 1
	return float(perto) / float(n) > VAZIA_FRACAO


static func telas_vazias(quadros: Array) -> Array:
	var achados: Array = []
	for q in quadros:
		if tela_vazia(q):
			achados.append("tela vazia em %s (%s)" % [hora(float(q.t)), _onde(q)])
	return achados


## Os textos de um quadro: sobreposição, fora da área segura, letra pequena e
## contraste. `tela` é o tamanho do jogo (1920×1080).
static func texto(t: float, frases: Array, tela: Vector2) -> Array:
	var achados: Array = []
	var seguro := Rect2(tela * AREA_SEGURA, tela * (1.0 - 2.0 * AREA_SEGURA))
	for i in frases.size():
		var f: Dictionary = frases[i]
		var r: Rect2 = f.rect
		if not seguro.encloses(r):
			achados.append("%s: «%s» fora da área segura (%s)" % [hora(t), _curta(f.frase), _ret(r)])
		if int(f.tam) < FONTE_MIN:
			achados.append("%s: «%s» com letra de %d px (o mínimo é %d)" % [hora(t), _curta(f.frase), int(f.tam), FONTE_MIN])
		var c := float(f.get("contraste", -1.0))
		if c >= 0.0 and c < CONTRASTE_MIN:
			achados.append("%s: «%s» com contraste %.1f:1 (o mínimo é %.1f)" % [hora(t), _curta(f.frase), c, CONTRASTE_MIN])
		for j in range(i + 1, frases.size()):
			var g: Dictionary = frases[j]
			if g.frase == f.frase:
				continue  # a mesma frase duas vezes é sombra ou contorno, não colisão
			var inter := r.intersection(g.rect)
			if inter.get_area() <= 0.0:
				continue
			var menor := minf(r.get_area(), g.rect.get_area())
			if menor > 0.0 and inter.get_area() / menor >= SOBREPOSICAO_MIN:
				achados.append("%s: «%s» encavalada com «%s» (%s e %s)" % [hora(t), _curta(f.frase), _curta(g.frase), _ret(r), _ret(g.rect)])
	return achados


## O relógio de um minigame nunca sobe durante a fase `jogo`.
## `observacoes`: {t, slot, fase, resta (s; -1 sem relógio ou no treino)}.
static func relogio_sobe(observacoes: Array) -> Array:
	var achados: Array = []
	var antes := {}
	for o in observacoes:
		if str(o.fase) != "jogo" or float(o.resta) < 0.0:
			antes.erase(o.slot)
			continue
		var slot := str(o.slot)
		if antes.has(slot) and float(o.resta) > float(antes[slot]) + 0.01:
			achados.append("o relógio de %s subiu de %.1f para %.1f s em %s" % [slot, antes[slot], float(o.resta), hora(float(o.t))])
		antes[slot] = float(o.resta)
	return achados


## Todo `minigame` `terminou` da linha do tempo tem `vencedor`.
static func fim_sem_vencedor(eventos: Array) -> Array:
	var achados: Array = []
	for e in eventos:
		if str(e.get("evento", "")) == "terminou" and str(e.get("tipo", "minigame")) == "minigame" and e.has("slot") \
				and not e.has("vencedor"):
			achados.append("o minigame %s terminou sem vencedor" % e.slot)
	return achados


## Frase de tela que começa com minúscula (número no começo vale).
static func minuscula(frases: Array) -> Array:
	var achados: Array = []
	for s in frases:
		if not comeca_com_maiuscula(str(s)):
			achados.append("frase começa com minúscula: «%s»" % _curta(str(s)))
	return achados


static func comeca_com_maiuscula(s: String) -> bool:
	for i in s.length():
		var c := s.substr(i, 1)
		if c >= "0" and c <= "9":
			return true
		if c.to_upper() != c.to_lower():
			return c == c.to_upper()
	return true


## O quadro por segundo de cada minigame: só avisa.
static func desempenho(eventos: Array) -> Array:
	var avisos: Array = []
	for e in eventos:
		if str(e.get("evento", "")) == "desempenho" and float(e.get("fps_min", 999.0)) < FPS_AVISO:
			avisos.append("%s: mínimo de %.0f quadros por segundo, média de %.0f" % [e.get("slot", "?"), float(e.fps_min), float(e.get("fps_media", 0.0))])
	return avisos


## A razão de contraste entre a cor do texto e a luminância do fundo.
static func razao(luz_a: float, luz_b: float) -> float:
	return (maxf(luz_a, luz_b) + 0.05) / (minf(luz_a, luz_b) + 0.05)


static func luminancia(c: Color) -> float:
	return 0.2126 * pow(c.r, 2.2) + 0.7152 * pow(c.g, 2.2) + 0.0722 * pow(c.b, 2.2)


static func hora(s: float) -> String:
	return "%02d:%02d" % [int(s) / 60, int(s) % 60]


static func _onde(q: Dictionary) -> String:
	return "%s%s" % [q.estado, " · " + str(q.sala) if str(q.sala) != "" else ""]


static func _curta(s: String) -> String:
	return s if s.length() <= 40 else s.substr(0, 39) + "…"


static func _ret(r: Rect2) -> String:
	return "%d,%d %dx%d" % [r.position.x, r.position.y, r.size.x, r.size.y]
