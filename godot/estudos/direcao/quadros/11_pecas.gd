extends Node3D
## Quadro 11 — A prancha das peças (PRODUCAO, item 2): as 36 peças do corte
## (cabeça, superior e inferior dos 12 personagens), de frente, na mesma
## escala, sobre o casco, cada uma com o emblema e os pontos que dá; e os
## seis itens com o que pedem e a liga. 42 células, nenhuma vazia.
## Refeita no item 16: cada peça no material dela (tecido, couro, pele), sem
## tom de jogador no corpo; o acento (friso, costura, runa) aceso em P1.
## Na conferência: o inferior a 1,8× (só as pernas: saía com cerca de
## 42 px de altura e a calça não se lia); o rótulo diz a escala.
## 1920×1440: um mundo só, câmera ortográfica, um píxel = ESCALA m.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")
const Mundo := preload("res://estudos/direcao/mundo.gd")
const Prancha := preload("res://estudos/direcao/prancha.gd")
const Montar := preload("res://estudos/direcao/cavaleiro/montar.gd")
const Cortar := preload("res://estudos/direcao/cavaleiro/cortar.gd")
const Sis := preload("res://estudos/direcao/cavaleiro/sistemas.gd")

var espera := 10
var arquivo := "11_pecas"
var folha: SubViewport
const TAM := Vector2i(1920, 1440)
const ESCALA := 0.0084          ## metros por píxel (o tronco superior de braços abertos cabe na coluna)
const X0 := 48.0
const COL := 152.0
## As linhas: o topo de cada uma e a área do boneco dentro dela.
const LINHA_Y := [196.0, 486.0, 776.0]
const LINHA_H := 290.0
const BONECO_H := 168.0
const ITENS_Y := 1080.0
const ITEM_W := 304.0
const PARTES := ["cabeca", "superior", "inferior"]
const ROTULO := ["Cabeça", "Tronco superior", "Tronco inferior (a 1,8×)"]
## A escala de cada linha sobre a ESCALA: o inferior a 1,8× (cabe na coluna
## de 152 px: as pernas mais largas dão cerca de 140).
const AMPLIA := [1.0, 1.0, 1.8]
const ITENS := ["martelo", "ancora", "escudo", "fole", "lanterna", "diapasao"]


func _mundo(px: Vector2) -> Vector3:
	return Vector3((px.x - TAM.x * 0.5) * ESCALA, (TAM.y * 0.5 - px.y) * ESCALA, 0.0)


func montar(_estudo) -> void:
	folha = Prancha.folha(self, TAM, Fita.CASCO)
	var vp := Prancha.celula(self, TAM, false)
	var raiz := Node3D.new()
	vp.add_child(raiz)
	Mundo.ambiente(raiz, {"ambiente": Color("#2a2738"), "ambiente_energia": 0.55, "nevoa": false,
		"glow": false, "fundo": Fita.CASCO})
	var sol := DirectionalLight3D.new()
	raiz.add_child(sol)
	sol.rotation_degrees = Vector3(-30, -28, 0)
	sol.light_color = Fita.TUNGSTENIO
	sol.light_energy = 1.0
	var contra := DirectionalLight3D.new()
	raiz.add_child(contra)
	contra.rotation_degrees = Vector3(-20, 160, 0)
	contra.light_color = Color("#8a7cff")
	contra.light_energy = 0.5
	var cam := Prancha.camera(vp)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = TAM.y * ESCALA
	cam.position = Vector3(0, 0, 20)
	cam.far = 60.0
	for linha in 3:
		var parte: String = PARTES[linha]
		for c in 12:
			var p: String = Cortar.PERSONAGENS[c]
			var caixa: AABB = Cortar.partes(p).caixa[parte]
			var centro_px := Vector2(X0 + c * COL + COL * 0.5, LINHA_Y[linha] + 40.0 + BONECO_H * 0.5)
			# a peça no meio da célula: o centro da caixa dela (na escala K) no centro
			var amplia: float = AMPLIA[linha]
			var pos := _mundo(centro_px) - caixa.get_center() * Mundo.K * amplia
			pos.z = 0.0
			# cada peça no material dela (tecido, couro, pele) e o acento
			# aceso na cor de P1; sem contorno, para a peça se ler sozinha
			var peca := Montar.cavaleiro(raiz, 0, pos, [p, p, p], {"so": parte, "contorno": false,
				"acento": true, "anel": false, "anim": "idle", "t_anim": 0.0})
			peca.scale = Vector3.ONE * amplia
	for i in 6:
		_item(raiz, ITENS[i], Vector2(X0 + i * ITEM_W + ITEM_W * 0.5, ITENS_Y + 134.0))
	Prancha.pregar(folha, vp, Rect2(Vector2.ZERO, Vector2(TAM)))
	Prancha.por_cima(folha, _texto)


func foto() -> Image:
	return await Prancha.foto(folha)


## O item sozinho, em pé, na escala que cabe na célula (o medalhão de 12 cm
## sumiria ao lado do martelo; o tamanho de cada um está no 04).
func _item(raiz: Node3D, id: String, centro_px: Vector2) -> void:
	var n := Node3D.new()
	raiz.add_child(n)
	var malha: Node3D
	var esc := 1.0
	match id:
		"martelo":
			malha = Mundo.peca(n, "survival-kit/tool-hammer", Vector3.ZERO, 0.0, 1.0)
			esc = 9.0
		"escudo":
			malha = Mundo.peca(n, "mini-dungeon/shield-round", Vector3.ZERO, 0.0, 1.0)
			esc = 3.6
		"ancora":
			var mi := MeshInstance3D.new()
			mi.mesh = Montar.ancora()
			n.add_child(mi)
			malha = mi
			esc = 6.3
		_:
			var mi := MeshInstance3D.new()
			mi.mesh = Montar.medalhao(id)
			n.add_child(mi)
			malha = mi
			esc = 22.0
	esc *= ESCALA / 0.0064      # os tamanhos acima foram medidos na escala 0,0064
	n.scale = Vector3.ONE * esc
	var caixa := AABB()
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		caixa = (mi as MeshInstance3D).get_aabb()
	if malha is MeshInstance3D:
		caixa = (malha as MeshInstance3D).get_aabb()
	n.position = _mundo(centro_px) - caixa.get_center() * esc
	n.position.z = 0.0
	n.rotation.y = 0.0
	# a runa do item, acesa na cor de P1
	Montar.por_runa(malha, id, Fita.JOGADOR[0])


func _texto(ci: CanvasItem) -> void:
	Hud.etiqueta(ci, Rect2(48, 10, 660, 140), "As peças", "PRANCHA  ·  ITENS 2 E 16  ·  36 + 6", Fita.SECAO[0], 54, -0.01)
	Hud.texto(ci, Fita.archivo(500), 30, Vector2(760, 44), "O corte do 04: cada peça no material dela; o acento em néon de P1.", Color(Fita.ETIQUETA, 0.85))
	Hud.texto(ci, Fita.archivo(500), 30, Vector2(760, 86), "O friso, a costura e a runa são malhas à parte. Embaixo: os pontos.", Color(Fita.ETIQUETA, 0.85))
	for c in 12:
		Hud.texto(ci, Fita.vt(), 30, Vector2(X0 + c * COL, 158), Cortar.PERSONAGENS[c], Fita.MUDO, HORIZONTAL_ALIGNMENT_CENTER, COL)
	for linha in 3:
		var y: float = LINHA_Y[linha]
		ci.draw_line(Vector2(X0, y), Vector2(X0 + 12 * COL, y), Fita.GRAFITE, 2.0)
		Hud.texto(ci, Fita.archivo(600), 30, Vector2(X0 + 6, y + 4), ROTULO[linha], Fita.ETIQUETA)
		for c in 12:
			var p := Sis.peca(PARTES[linha], Cortar.PERSONAGENS[c])
			var x := X0 + c * COL
			var principal: String = p.principal
			var sec := ""
			for j in 4:
				if int(p[Sis.ST[j]]) == 1:
					sec = Sis.NOME_ST[j]
			var yt := y + 40.0 + BONECO_H + 6.0
			Hud.texto(ci, Fita.vt(), 30, Vector2(x, yt), "%s +2" % Sis.EMBLEMA[principal], Fita.ETIQUETA, HORIZONTAL_ALIGNMENT_CENTER, COL)
			Hud.texto(ci, Fita.vt(), 30, Vector2(x, yt + 32), "%s +1" % sec, Fita.MUDO, HORIZONTAL_ALIGNMENT_CENTER, COL)
			if c > 0:
				ci.draw_line(Vector2(x, y + 44), Vector2(x, y + LINHA_H - 8), Color(Fita.GRAFITE, 0.6), 1.0)
	# os itens
	ci.draw_line(Vector2(X0, ITENS_Y - 14), Vector2(X0 + 12 * COL, ITENS_Y - 14), Fita.GRAFITE, 2.0)
	Hud.texto(ci, Fita.archivo(600), 30, Vector2(X0 + 6, ITENS_Y - 10), "Os itens (cada um na escala que cabe)", Fita.ETIQUETA)
	for i in 6:
		var it := Sis.item(ITENS[i])
		var x := X0 + i * ITEM_W
		var pede := []
		var liga := []
		for j in 4:
			if int(it["pede_" + Sis.ST[j]]) > 0:
				pede.append("%s %s" % [Sis.NOME_ST[j], it["pede_" + Sis.ST[j]]])
				liga.append("%s %s" % [Sis.NOME_ST[j], it["liga_" + Sis.ST[j]]])
		var yt := ITENS_Y + 246.0
		Hud.texto(ci, Fita.archivo(600), 30, Vector2(x, yt), "%s (%s)" % [it.nome, it.tipo], Fita.ETIQUETA, HORIZONTAL_ALIGNMENT_CENTER, ITEM_W)
		Hud.texto(ci, Fita.vt(), 30, Vector2(x, yt + 38), "pede " + " e ".join(pede), Fita.ETIQUETA, HORIZONTAL_ALIGNMENT_CENTER, ITEM_W)
		Hud.texto(ci, Fita.vt(), 30, Vector2(x, yt + 70), "liga " + " e ".join(liga), Fita.MUDO, HORIZONTAL_ALIGNMENT_CENTER, ITEM_W)
		if i > 0:
			ci.draw_line(Vector2(x, ITENS_Y + 30), Vector2(x, ITENS_Y + 340), Color(Fita.GRAFITE, 0.6), 1.0)
