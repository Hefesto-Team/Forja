extends SceneTree
## A medida da peça (PRODUCAO, item 17). Sem tela:
##
##   godot --headless --path godot -s res://estudos/direcao/medir_pecas.gd
##
## Para cada uma das 36 peças do corte (a cabeça, o superior e o inferior dos
## 12 Mini Characters) lê as faces que olham para a frente (normal z > 0), a
## área de cada uma projetada no plano da frente e a cor do colormap graduado
## da peça no meio da face (a cabeça no `colormap.png`, o superior no
## `colormap-tecido.png`, o inferior no `colormap-couro.png`). Escreve
## `docs/jogo/arte/dados/pecas_medidas.csv`:
##
##   l_mediana     a L do OKLab no meio da área (mediana ponderada pela área);
##                 no superior e no inferior, só nas faces de pano (a UV fora
##                 de PELE_UV): a mão, o braço e a perna de fora são pele, não
##                 a peça (a bermuda do male-f, 04, o critério do rosto)
##   l_pele        a mesma mediana só nas faces de pele (a UV em PELE_UV): o
##                 rosto, na cabeça; vazio onde a peça não mostra pele
##   croma_mediana o croma no meio da área; croma_max, o maior de toda face
##   de_p1..de_p4  o menor ΔE OKLab de uma face da peça até cada JOGADOR
##   acento_pct    a área de frente do friso (superior) ou da costura
##                 (inferior) sobre a área de frente da peça, sem o contorno
##
## Embaixo, no terminal, cada critério do item 17 com o pior caso. A ordem
## das linhas e dos números é fixa: duas rodadas dão o mesmo CSV byte a byte.
## Sai com 1 se algum critério falha.
##
## O rosto (04, o critério do rosto): sem faixa absoluta na cabeça humana (a
## pele não se clareia). Cada par rosto e superior, de quaisquer dois
## personagens, passa por |ΔL| de 0,10 ou mais entre o `l_pele` da cabeça e o
## `l_mediana` do superior; o par que não chega passa pela gola acesa, se o
## superior tem o friso da gola de frente e a cabeça não desce sobre ela. As
## peles das raças (tokens) ficam na faixa de 0,68 a 0,80.

const Fita := preload("res://estudos/direcao/fita.gd")
const Cortar := preload("res://estudos/direcao/cavaleiro/cortar.gd")
const Acento := preload("res://estudos/direcao/cavaleiro/acento.gd")

const PASTA_TEX := "res://estudos/direcao/kenney/mini-characters/Textures/"
const COLORMAP := {"cabeca": "colormap.png", "superior": "colormap-tecido.png", "inferior": "colormap-couro.png"}
const SAIDA := "res://../docs/jogo/arte/dados/pecas_medidas.csv"
## As faixas do 02 (a escada de valor) e os tetos do item 17.
const FAIXA := {"superior": [0.46, 0.58], "inferior": [0.22, 0.36]}
## A faixa do rosto, só nas raças (a pele é token).
const FAIXA_RACA := [0.68, 0.80]
const PELES_RACA := {"orc": Fita.PELE_ORC, "automato": Fita.PELE_LATAO, "golem": Fita.PELE_ESCORIA, "raposa": Fita.PELE_RAPOSA}
const TETO_CROMA := 0.10
const DE_MIN := 0.08
const VIZINHO := 0.10
const ACENTO_MAX := 8.0


func _init() -> void:
	var imgs := {}
	for parte in COLORMAP:
		imgs[parte] = Image.load_from_file(ProjectSettings.globalize_path(PASTA_TEX + COLORMAP[parte]))
	var jog := []
	for c in Fita.JOGADOR:
		jog.append(Fita.para_oklab(c))
	var linhas := ["parte,personagem,l_mediana,l_pele,croma_mediana,croma_max,de_p1,de_p2,de_p3,de_p4,acento_pct"]
	var l_de := {"cabeca": {}, "superior": {}, "inferior": {}}
	var rosto := {}
	var gola := {}
	var desce := {}
	var falhas := []
	var pior_croma := 0.0
	var pior_de := 9.0
	var pior_acento := 0.0
	for parte in ["cabeca", "superior", "inferior"]:
		for p in Cortar.PERSONAGENS:
			var d: Dictionary = Cortar.partes(p)
			var m: Dictionary = _medir(d[parte], imgs[parte], jog, parte != "cabeca")
			var acento := 0.0
			if parte != "cabeca":
				var dados: Array = Acento.friso(d[parte]) if parte == "superior" else Acento.costura(d[parte])
				acento = 100.0 * Acento.area_frente(dados[0], dados[1]) / maxf(m.area_toda, 1e-9)
			l_de[parte][p] = m.l
			if parte == "cabeca":
				rosto[p] = m.l_pele if m.area_pele > 0.0 else m.l
				desce[p] = (d.cabeca as Mesh).get_aabb().position.y
			if parte == "superior":
				var g: Array = Acento.gola(d.superior)
				gola[p] = [Acento.area_frente(g[0], g[1]), minf(Acento.caixa(d.superior, [3]).end.y, Acento.PESCOCO)]
			pior_croma = maxf(pior_croma, m.croma_max)
			pior_acento = maxf(pior_acento, acento)
			for j in 4:
				pior_de = minf(pior_de, m.de[j])
			var pele := "%.3f" % m.l_pele if m.area_pele > 0.0 else ""
			linhas.append("%s,%s,%.3f,%s,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.2f" % [parte, p, m.l, pele, m.croma, m.croma_max,
				m.de[0], m.de[1], m.de[2], m.de[3], acento])
			var faixa: Array = FAIXA.get(parte, [0.0, 1.0])
			if m.l < faixa[0] or m.l > faixa[1]:
				falhas.append("%s %s: L %.3f fora de %.2f a %.2f" % [parte, p, m.l, faixa[0], faixa[1]])
	var f := FileAccess.open(ProjectSettings.globalize_path(SAIDA), FileAccess.WRITE)
	f.store_string("\n".join(linhas) + "\n")
	f.close()
	# os vizinhos: cada par de quaisquer duas peças, de qualquer personagem
	var sup_min := _menor(l_de.superior)
	var inf_max := _maior(l_de.inferior)
	var pares_si := 0
	var pares_dl := 0
	var pares_gola := 0
	var menor_dl := 9.0
	for q in Cortar.PERSONAGENS:
		for r in Cortar.PERSONAGENS:
			if l_de.superior[q] - l_de.inferior[r] >= VIZINHO:
				pares_si += 1
		for p in Cortar.PERSONAGENS:
			var dl := absf(float(rosto[p]) - float(l_de.superior[q]))
			menor_dl = minf(menor_dl, dl)
			if dl >= VIZINHO:
				pares_dl += 1
			elif gola[q][0] > 0.0 and float(desce[p]) >= float(gola[q][1]):
				pares_gola += 1
			else:
				falhas.append("rosto %s e superior %s: |ΔL| %.3f, e a gola não aparece" % [p, q, dl])
	var n := Cortar.PERSONAGENS.size()
	if pares_si < n * n:
		falhas.append("superior e inferior: %d de %d pares a %.2f ou mais" % [pares_si, n * n, VIZINHO])
	for raca in PELES_RACA:
		# a L com três casas, como o CSV (o #a3958e da escória dá 0,6799)
		var lr: float = snappedf(Fita.para_oklab(PELES_RACA[raca]).x, 0.001)
		if lr < FAIXA_RACA[0] or lr > FAIXA_RACA[1]:
			falhas.append("pele da raça %s: L %.3f fora de %.2f a %.2f" % [raca, lr, FAIXA_RACA[0], FAIXA_RACA[1]])
	print("pecas_medidas.csv: %d linhas" % (linhas.size() - 1))
	print("croma: o maior %.3f (teto %.2f) %s" % [pior_croma, TETO_CROMA, "ok" if pior_croma <= TETO_CROMA + 1e-6 else "PASSA DO TETO"])
	print("ΔE até um JOGADOR: o menor %.3f (piso %.2f) %s" % [pior_de, DE_MIN, "ok" if pior_de >= DE_MIN else "PERTO DEMAIS"])
	print("acento: o maior %.2f %% (teto %.0f %%) %s" % [pior_acento, ACENTO_MAX, "ok" if pior_acento <= ACENTO_MAX else "PASSA"])
	print("superior e inferior: %d de %d pares a %.2f ou mais; o pior, superior %.3f − inferior %.3f = %.3f" % [
		pares_si, n * n, VIZINHO, sup_min, inf_max, sup_min - inf_max])
	print("rosto e superior: %d de %d pares pelo |ΔL| de %.2f ou mais, %d pela gola acesa (o menor |ΔL| %.3f)" % [
		pares_dl, n * n, VIZINHO, pares_gola, menor_dl])
	for x in falhas:
		print("falha: " + x)
	if falhas.is_empty():
		print("todos os critérios passam")
	quit(1 if not falhas.is_empty() else 0)


## As faces de frente de `malha`: a área total, a mediana de L e de croma
## ponderadas pela área, o croma maior e o menor ΔE até cada jogador.
func _medir(malha: Mesh, img: Image, jog: Array, so_pano := false) -> Dictionary:
	var arr := malha.surface_get_arrays(0)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var nv: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var faces := []
	var pele := []
	var area := 0.0
	var area_pele := 0.0
	var area_toda := 0.0
	var croma_max := 0.0
	var de := [9.0, 9.0, 9.0, 9.0]
	var w := img.get_width()
	var h := img.get_height()
	for t in idx.size() / 3:
		var i0 := idx[t * 3]
		var i1 := idx[t * 3 + 1]
		var i2 := idx[t * 3 + 2]
		var a := vs[i0]
		var b := vs[i1]
		var c := vs[i2]
		var fn := (c - a).cross(b - a)
		if fn.length() < 1e-12:
			continue
		fn = fn.normalized()
		if fn.dot(nv[i0]) < 0.0:
			fn = -fn
		if fn.z <= 0.0:
			continue
		var s := absf((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)) * 0.5
		if s <= 0.0:
			continue
		var u := (uv[i0] + uv[i1] + uv[i2]) / 3.0
		var px := clampi(int(floor(u.x * w)), 0, w - 1)
		var py := clampi(int(floor(u.y * h)), 0, h - 1)
		var ok := Fita.para_oklab(img.get_pixel(px, py))
		var croma := Vector2(ok.y, ok.z).length()
		croma_max = maxf(croma_max, croma)
		for j in 4:
			de[j] = minf(de[j], ok.distance_to(jog[j]))
		area_toda += s
		var e_pele := Fita.PELE_UV.has_point(u)
		if e_pele:
			pele.append([ok.x, croma, s])
			area_pele += s
		if so_pano and e_pele:
			continue
		faces.append([ok.x, croma, s])
		area += s
	return {"area": area, "area_toda": area_toda, "area_pele": area_pele, "l_pele": _mediana(pele, 0, area_pele), "l": _mediana(faces, 0, area), "croma": _mediana(faces, 1, area), "croma_max": croma_max, "de": de}


## A mediana ponderada da coluna `k` (o peso é a área, na coluna 2).
func _mediana(faces: Array, k: int, total: float) -> float:
	var ord := faces.duplicate()
	ord.sort_custom(func(x, y): return x[k] < y[k] or (x[k] == y[k] and x[2] < y[2]))
	var soma := 0.0
	for f in ord:
		soma += f[2]
		if soma >= total * 0.5:
			return f[k]
	return 0.0


func _menor(d: Dictionary) -> float:
	var v := 9.0
	for k in d:
		v = minf(v, d[k])
	return v


func _maior(d: Dictionary) -> float:
	var v := -9.0
	for k in d:
		v = maxf(v, d[k])
	return v
