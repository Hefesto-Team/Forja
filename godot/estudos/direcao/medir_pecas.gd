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
##   l_mediana     a L do OKLab no meio da área (mediana ponderada pela área)
##   l_pele        a mesma mediana só nas faces de pele (a UV em PELE_UV): o
##                 rosto, na cabeça; vazio onde a peça não mostra pele
##   croma_mediana o croma no meio da área; croma_max, o maior de toda face
##   de_p1..de_p4  o menor ΔE OKLab de uma face da peça até cada JOGADOR
##   acento_pct    a área de frente do friso (superior) ou da costura
##                 (inferior) sobre a área de frente da peça, sem o contorno
##
## Embaixo, no terminal, cada critério do item 17 com o pior caso. A ordem
## das linhas e dos números é fixa: duas rodadas dão o mesmo CSV byte a byte.

const Fita := preload("res://estudos/direcao/fita.gd")
const Cortar := preload("res://estudos/direcao/cavaleiro/cortar.gd")
const Acento := preload("res://estudos/direcao/cavaleiro/acento.gd")

const PASTA_TEX := "res://estudos/direcao/kenney/mini-characters/Textures/"
const COLORMAP := {"cabeca": "colormap.png", "superior": "colormap-tecido.png", "inferior": "colormap-couro.png"}
const SAIDA := "res://../docs/jogo/arte/dados/pecas_medidas.csv"
## As faixas do 02 (a escada de valor) e os tetos do item 17.
const FAIXA := {"cabeca": [0.68, 0.80], "superior": [0.46, 0.58], "inferior": [0.22, 0.36]}
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
	var falhas := []
	var pior_croma := 0.0
	var pior_de := 9.0
	var pior_acento := 0.0
	for parte in ["cabeca", "superior", "inferior"]:
		for p in Cortar.PERSONAGENS:
			var d: Dictionary = Cortar.partes(p)
			var m: Dictionary = _medir(d[parte], imgs[parte], jog)
			var acento := 0.0
			if parte != "cabeca":
				var dados: Array = Acento.friso(d[parte]) if parte == "superior" else Acento.costura(d[parte])
				acento = 100.0 * Acento.area_frente(dados[0], dados[1]) / maxf(m.area, 1e-9)
			l_de[parte][p] = m.l
			pior_croma = maxf(pior_croma, m.croma_max)
			pior_acento = maxf(pior_acento, acento)
			for j in 4:
				pior_de = minf(pior_de, m.de[j])
			var pele := "%.3f" % m.l_pele if m.area_pele > 0.0 else ""
			if parte == "cabeca" and m.area_pele > 0.0 and (m.l_pele < FAIXA.cabeca[0] or m.l_pele > FAIXA.cabeca[1]):
				falhas.append("rosto %s: L %.3f fora de %.2f a %.2f" % [p, m.l_pele, FAIXA.cabeca[0], FAIXA.cabeca[1]])
			linhas.append("%s,%s,%.3f,%s,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.2f" % [parte, p, m.l, pele, m.croma, m.croma_max,
				m.de[0], m.de[1], m.de[2], m.de[3], acento])
			var faixa: Array = FAIXA[parte]
			if m.l < faixa[0] or m.l > faixa[1]:
				falhas.append("%s %s: L %.3f fora de %.2f a %.2f" % [parte, p, m.l, faixa[0], faixa[1]])
	var f := FileAccess.open(ProjectSettings.globalize_path(SAIDA), FileAccess.WRITE)
	f.store_string("\n".join(linhas) + "\n")
	f.close()
	# os vizinhos: a pior combinação de quaisquer duas peças, de qualquer personagem
	var cab_min := _menor(l_de.cabeca)
	var sup_min := _menor(l_de.superior)
	var sup_max := _maior(l_de.superior)
	var inf_max := _maior(l_de.inferior)
	print("pecas_medidas.csv: %d linhas" % (linhas.size() - 1))
	print("croma: o maior %.3f (teto %.2f) %s" % [pior_croma, TETO_CROMA, "ok" if pior_croma <= TETO_CROMA + 1e-6 else "PASSA DO TETO"])
	print("ΔE até um JOGADOR: o menor %.3f (piso %.2f) %s" % [pior_de, DE_MIN, "ok" if pior_de >= DE_MIN else "PERTO DEMAIS"])
	print("acento: o maior %.2f %% (teto %.0f %%) %s" % [pior_acento, ACENTO_MAX, "ok" if pior_acento <= ACENTO_MAX else "PASSA"])
	print("vizinhos, pior caso: cabeça %.3f − superior %.3f = %.3f; superior %.3f − inferior %.3f = %.3f (piso %.2f)" % [
		cab_min, sup_max, cab_min - sup_max, sup_min, inf_max, sup_min - inf_max, VIZINHO])
	for x in falhas:
		print("faixa: " + x)
	quit()


## As faces de frente de `malha`: a área total, a mediana de L e de croma
## ponderadas pela área, o croma maior e o menor ΔE até cada jogador.
func _medir(malha: Mesh, img: Image, jog: Array) -> Dictionary:
	var arr := malha.surface_get_arrays(0)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var nv: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var faces := []
	var pele := []
	var area := 0.0
	var area_pele := 0.0
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
		faces.append([ok.x, croma, s])
		area += s
		if Fita.PELE_UV.has_point(u):
			pele.append([ok.x, croma, s])
			area_pele += s
	return {"area": area, "area_pele": area_pele, "l_pele": _mediana(pele, 0, area_pele), "l": _mediana(faces, 0, area), "croma": _mediana(faces, 1, area), "croma_max": croma_max, "de": de}


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
