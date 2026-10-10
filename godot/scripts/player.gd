class_name ForjaPlayer
extends CharacterBody3D
## Um jogador no mundo: o boneco do kit Mini Dungeon (Kenney, CC0) com a roupa
## sem tom no corpo; o dono é o contorno de néon, o anel no chão e a luz, os três
## na cor de luz do lugar, e o "P1" em cima. Anda
## pelo analógico esquerdo do controle do lugar (o d-pad também serve).
##
## O visual é do jogador: o boneco (humano ou orc) e o que ele leva nas mãos,
## escolhidos no lobby. A cor não se escolhe — é a do lugar, a mesma da
## lightbar do controle.

const VELOCIDADE := 4.6
const CORRIDA := 6.8
const ESCALA := 2.0
const CONTORNO_LARGURA := 0.012
## Os bonecos registrados: o arquivo e o intervalo do pio (arte/03). A G10
## acrescenta os 12 do Mini Characters; a G13 troca por peças.
const BONECOS := [
	{"nome": "Humano", "arquivo": "character-human", "intervalo": "segunda"},
	{"nome": "Orc", "arquivo": "character-orc", "intervalo": "quinta_baixo"},
	# os 12 do Mini Characters (G13), na ordem de Cavaleiro.PERSONAGENS: o nome é o da
	# cabeça em pecas.csv, o intervalo é o da letra (a segunda … f oitava)
	{"nome": "Coque preto", "arquivo": "mini-characters/character-female-a", "intervalo": "segunda"},
	{"nome": "Duas bolotas", "arquivo": "mini-characters/character-female-b", "intervalo": "terca"},
	{"nome": "Touca listrada", "arquivo": "mini-characters/character-female-c", "intervalo": "quarta"},
	{"nome": "Coque ruivo", "arquivo": "mini-characters/character-female-d", "intervalo": "quinta"},
	{"nome": "Franja preta", "arquivo": "mini-characters/character-female-e", "intervalo": "quinta_baixo"},
	{"nome": "Cabelo longo", "arquivo": "mini-characters/character-female-f", "intervalo": "oitava"},
	{"nome": "Óculos redondo", "arquivo": "mini-characters/character-male-a", "intervalo": "segunda"},
	{"nome": "Barba ruiva", "arquivo": "mini-characters/character-male-b", "intervalo": "terca"},
	{"nome": "Quepe azul", "arquivo": "mini-characters/character-male-c", "intervalo": "quarta"},
	{"nome": "Ruivo curto", "arquivo": "mini-characters/character-male-d", "intervalo": "quinta"},
	{"nome": "Óculos de obra", "arquivo": "mini-characters/character-male-e", "intervalo": "quinta_baixo"},
	{"nome": "Topete preto", "arquivo": "mini-characters/character-male-f", "intervalo": "oitava"},
]
## Onde os 12 do Mini Characters começam em BONECOS (o Humano e o Orc vêm antes).
const PRIMEIRO_PERSONAGEM := 2
## Os shaders do cavaleiro (arte/04): a roupa por faixa de valor, o contorno e o néon.
const SH_CAVALEIRO := preload("res://shaders/cavaleiro.gdshader")
## O contorno: 1,6 na montagem, 2,4 no resto (arte/07).
const CONTORNO_MONTAGEM := 1.6
const CONTORNO_JOGO := 2.4
## A rugosidade de cada parte (A cena da G08); o acabamento Fosco as deixa como estão.
const RUGOSO_CIMA := 0.85
const RUGOSO_BAIXO := 0.70
const RUGOSO_CABECA := 0.90
## O item: o índice é o de Itens (G03). "id" é o de docs/jogo/sistemas/itens.csv.
## O corpo leva o item que o _segurar() monta; a regra é a da classe Itens.
const ITENS := [
	{"id": "", "nome": "Mãos livres", "icone": ""},
	{"id": "martelo", "nome": "Martelo", "icone": "item_martelo"},
	{"id": "escudo", "nome": "Escudo", "icone": "item_escudo"},
	{"id": "fole", "nome": "Fole", "icone": "item_fole"},
	{"id": "lanterna", "nome": "Lanterna", "icone": "item_lanterna"},
	{"id": "diapasao", "nome": "Diapasão", "icone": "item_diapasao"},
	{"id": "ancora", "nome": "Âncora", "icone": "item_ancora"},
]
## Cada lugar nasce com um visual diferente dos outros: [boneco, item].
const VISUAL_DO_LUGAR := [[0, 1], [1, 2], [0, 3], [1, 4]]
## O acabamento muda como a luz bate, nunca a cor: o corpo não se tinge
## (arte/04). "livre": false até a coleção (G06). metallic nunca passa de 0,2.
const ACABAMENTOS := [
	{"nome": "Fosco", "rugoso": 0.95, "metal": 0.0},
	{"nome": "Polido", "rugoso": 0.45, "metal": 0.2},
	{"nome": "Riscado", "rugoso": 0.75, "metal": 0.1},
	{"nome": "Dourado", "rugoso": 0.5, "metal": 0.2, "livre": false},
	{"nome": "Cromado", "rugoso": 0.25, "metal": 0.2, "claro": 0.0, "livre": false},
	{"nome": "Néon", "rugoso": 0.6, "metal": 0.0, "claro": 0.0, "acento": 2.4, "livre": false},
]
## A energia de repouso do acento do corpo (G08: 1,6); o Néon sobe a 2,4. Teto 3,0.
const ACENTO_REPOUSO := 1.6
const ACENTO_TETO := 3.0
## As malhas da Kenney dos itens que as têm (o martelo e o escudo, por pasta de pacote).
const MALHA_DO_ITEM := {
	"martelo": "res://assets/kenney/survival-kit/tool-hammer.glb",
	"escudo": "res://assets/kenney/mini-dungeon/shield-round.glb",
}
## O emblema em relevo de cada amuleto no disco do medalhão (G03): [tamanho x y, posição x y].
const EMBLEMA := {
	"fole": [[Vector2(0.022, 0.026), Vector2(0, 0.002)], [Vector2(0.006, 0.010), Vector2(0, -0.016)]],
	"lanterna": [[Vector2(0.016, 0.022), Vector2(0, -0.002)], [Vector2(0.012, 0.003), Vector2(0, 0.012)]],
	"diapasao": [[Vector2(0.004, 0.024), Vector2(-0.006, 0.004)], [Vector2(0.004, 0.024), Vector2(0.006, 0.004)],
		[Vector2(0.016, 0.004), Vector2(0, -0.008)], [Vector2(0.004, 0.012), Vector2(0, -0.016)]],
}

var lugar := 0
var cor: Color  ## a cor do lugar (Forja.cor_do_lugar), posta em `montar`
var hp := 100.0
var cooldown := 0.0
## false: parado pelo jogo (lobby, transição); a entrada não mexe nele
var controlavel := true:
	set(v):
		controlavel = v
		if luz_de_dono:
			luz_de_dono.visible = v
## true: a sala posiciona e anima o boneco (na viga, caindo na lava); a física
## e a escolha da animação ficam paradas
var preso := false
var modelo: Node3D
var modelo_i := 0
var item_i := 0
var acabamento_i := 0
var nome := ""
var anim: AnimationPlayer
var aro: Node3D   ## o anel de 8 lados no chão e as lâmpadas do lugar (Kit.anel_do_dono)
var luz_de_dono: OmniLight3D  ## a luz do lugar no chão em volta de quem se mexe (só com `controlavel`)
var etiqueta: Label3D
var _anim_atual := ""
var _mats_corpo: Array[ShaderMaterial] = []    ## os do body*, para o acento, o acabamento e o acender
var _mats_cabeca: Array[ShaderMaterial] = []   ## os do head*, para o acender
var _contornos: Array[ShaderMaterial] = []     ## o casco de cada malha, na cor do dono
var _medidas := {}                             ## o que Pintura.preparar mediu no corpo (a área do acento)
var _brilho_do_contorno := CONTORNO_JOGO
var _arquivo := ""                             ## o .glb do modelo vestido (o colormap mora ao lado)
var _mats_runa: Array[Material] = []  ## a linha da runa do item, para acender e o encaixe
var _area_runa := 0.0   ## a área de frente das linhas da runa
var _area_item := 0.0   ## a área de frente do item (o AABB das malhas)
var _acesa := 1.0       ## o último acender(k): o item que se troca nasce com a mesma luz
var _yaw := PI
## O cavaleiro de três peças (G13): o personagem da cabeça, do superior e do
## inferior. Vazio enquanto o boneco é um inteiro (o Humano ou o Orc).
var pecas: Array = []
var cadeira := ""   ## "" = pernas; ou um dos quatro de regras.csv `cadeiras` (G13b)
var _gesto := 0.0


func montar(l: int) -> void:
	lugar = l
	cor = Forja.cor_do_lugar(l)
	name = "P%d" % (l + 1)
	visual(VISUAL_DO_LUGAR[l][0], VISUAL_DO_LUGAR[l][1])

	var forma := CollisionShape3D.new()
	var capsula := CapsuleShape3D.new()
	capsula.radius = 0.42
	capsula.height = 1.5
	forma.shape = capsula
	forma.position.y = 0.75
	add_child(forma)

	aro = Kit.anel_do_dono(self, l)

	luz_de_dono = OmniLight3D.new()
	luz_de_dono.light_color = cor
	luz_de_dono.light_energy = 0.9
	luz_de_dono.omni_range = 3.4
	luz_de_dono.shadow_enabled = false
	luz_de_dono.position.y = 0.6
	luz_de_dono.visible = controlavel
	add_child(luz_de_dono)

	etiqueta = Label3D.new()
	etiqueta.text = "P%d" % (l + 1)
	etiqueta.font = Tema.bungee()
	etiqueta.font_size = 72
	etiqueta.pixel_size = 0.0036
	etiqueta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	etiqueta.no_depth_test = true
	etiqueta.modulate = Tema.tom_para_a_borda(cor)
	etiqueta.outline_size = 16
	etiqueta.outline_modulate = Color(Tema.FITA, 0.9)
	etiqueta.position.y = 1.95
	add_child(etiqueta)
	_animar("idle")


## Troca o boneco e o que ele leva. A animação recomeça do "parado".
func visual(m: int, item: int) -> void:
	# um dos 12 do Mini Characters vira o cavaleiro de três peças do mesmo personagem (G13)
	if wrapi(m, 0, BONECOS.size()) >= PRIMEIRO_PERSONAGEM and (pecas.is_empty() or wrapi(m, 0, BONECOS.size()) != modelo_i):
		var p: String = Cavaleiro.PERSONAGENS[wrapi(m, 0, BONECOS.size()) - PRIMEIRO_PERSONAGEM]
		vestir_pecas([p, p, p], item)
		return
	if wrapi(m, 0, BONECOS.size()) < PRIMEIRO_PERSONAGEM:
		pecas = []
	var trocou_modelo := modelo == null or wrapi(m, 0, BONECOS.size()) != modelo_i
	modelo_i = wrapi(m, 0, BONECOS.size())
	item_i = wrapi(item, 0, ITENS.size())
	if trocou_modelo:
		if modelo:
			_soltar_contorno(modelo)
			modelo.queue_free()
		_arquivo = Kit.caminho("mini-dungeon-personagens/" + str(BONECOS[modelo_i].arquivo))
		modelo = load(_arquivo).instantiate()
		modelo.scale = Vector3.ONE * ESCALA
		add_child(modelo)
		_mats_corpo.clear()
		_mats_cabeca.clear()
		_contornos.clear()
		_medidas = {}
		anim = modelo.find_child("AnimationPlayer", true, false)
		for nome in ["idle", "walk", "sprint"]:
			if anim and anim.has_animation(nome):
				anim.get_animation(nome).loop_mode = Animation.LOOP_LINEAR
		_vestir(modelo)
		_anim_atual = ""
		_animar("idle")
	_segurar()
	_aplicar_acabamento()
	contornar(_brilho_do_contorno)


## Os índices de ACABAMENTOS que já são do jogador: os livres e os que a coleção da
## noite desbloqueou (Dourado, Cromado, Néon).
static func acabamentos_disponiveis() -> Array:
	var v: Array = []
	for i in ACABAMENTOS.size():
		if bool(ACABAMENTOS[i].get("livre", true)) or Colecao.desbloqueado(str(ACABAMENTOS[i].nome)):
			v.append(i)
	return v


## O que se guarda do cavaleiro (Opcoes.cavaleiro e o registro): o boneco, o
## item (pelo id), o nome e o acabamento.
func cavaleiro() -> Dictionary:
	if pecas.size() == 3:
		return {"cabeca": pecas[0], "superior": pecas[1], "inferior": pecas[2], "cadeira": cadeira,
			"item": ITENS[item_i].id, "nome": nome, "acabamento": acabamento_i}
	return {"boneco": modelo_i, "item": ITENS[item_i].id, "nome": nome, "acabamento": acabamento_i}


## O inverso de cavaleiro(): acha o item pelo id e veste o corpo.
func vestir(c: Dictionary) -> void:
	var item := 0
	for i in ITENS.size():
		if ITENS[i].id == str(c.get("item", "")):
			item = i
	nome = str(c.get("nome", ""))
	acabamento_i = clampi(int(c.get("acabamento", 0)), 0, ACABAMENTOS.size() - 1)
	# o cavaleiro de três peças (G13); o dicionário antigo da G02 (com "boneco") vira o pré-montado do lugar
	if c.has("cabeca") or c.has("boneco"):
		var novas: Array = [str(c.get("cabeca", "")), str(c.get("superior", "")), str(c.get("inferior", ""))]
		if not c.has("cabeca") or Cavaleiro.peca("cabeca", novas[0]).is_empty():
			novas = Cavaleiro.pre_montado(lugar, {}).pecas
		cadeira = str(c.get("cadeira", ""))
		vestir_pecas(novas, item)
		return
	visual(int(c.get("boneco", 0)), item)


## O acabamento nos materiais do corpo: só a rugosidade e o metal, nunca a cor.
## O Fosco (o 0, o de todo mundo) deixa cada parte como a tabela dela (A cena da
## G08); os outros põem a rugosidade e o metal do acabamento no superior e no
## inferior.
func _aplicar_acabamento() -> void:
	var a: Dictionary = ACABAMENTOS[clampi(acabamento_i, 0, ACABAMENTOS.size() - 1)]
	var padrao := acabamento_i == 0
	for m in _mats_corpo:
		m.set_shader_parameter("rugoso_cima", RUGOSO_CIMA if padrao else float(a.rugoso))
		m.set_shader_parameter("rugoso_baixo", RUGOSO_BAIXO if padrao else float(a.rugoso))
		m.set_shader_parameter("metal", 0.0 if padrao else float(a.metal))
		m.set_shader_parameter("acento", _acento_de_repouso())


## A energia de repouso do acento do acabamento de agora (o Néon sobe; o resto, 1,6).
func _acento_de_repouso() -> float:
	var a: Dictionary = ACABAMENTOS[clampi(acabamento_i, 0, ACABAMENTOS.size() - 1)]
	return minf(float(a.get("acento", ACENTO_REPOUSO)), ACENTO_TETO)


## O nome de um boneco, na língua do jogo.
static func nome_do_boneco(i: int) -> String:
	return Traducoes.traduzir(BONECOS[wrapi(i, 0, BONECOS.size())].nome)


func descricao_do_visual() -> String:
	return "%s · %s" % [str(BONECOS[modelo_i].nome).to_lower(), ITENS[item_i].nome]


## O contorno de néon do lugar em todas as superfícies do boneco e do que ele leva
## (`next_pass`, o casco que cresce pela normal suavizada): 2,4 no jogo, 1,6 na
## montagem. Chamar de novo troca a energia.
func contornar(energia: float) -> void:
	_brilho_do_contorno = energia
	if modelo == null:
		return
	_contornar_em(modelo)
	for c in _contornos:
		c.set_shader_parameter("energia", energia * _acesa)


func _contornar_em(n: Node) -> void:
	if n.is_queued_for_deletion():
		return
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			if not _ja_contornado(mi.get_surface_override_material(0)):
				_suavizar(mi)
				for s in mi.mesh.get_surface_count():
					var base: Material = mi.get_surface_override_material(s)
					if base == null:
						base = mi.mesh.surface_get_material(s)
					if base == null:
						continue
					var m: Material = base.duplicate()
					m.next_pass = _novo_contorno()
					mi.set_surface_override_material(s, m)
	for filho in n.get_children():
		_contornar_em(filho)


## O corpo e a cabeça já levam o contorno da roupa (_vestir); o que já tem contorno só troca a energia.
func _ja_contornado(m: Material) -> bool:
	return m != null and m.next_pass is ShaderMaterial and _contornos.has(m.next_pass)


## O casco de néon do lugar, na energia de agora; entra na lista que `acender` e `contornar` regulam.
func _novo_contorno() -> ShaderMaterial:
	var c := Tema.contorno(cor, CONTORNO_LARGURA, _brilho_do_contorno * _acesa, lugar)
	_contornos.append(c)
	return c


## Devolve as superfícies ao material do kit antes de o nó sair: um material
## duplicado com `next_pass` que morre na fila de deleção deixa o servidor de
## desenho pedindo um material nulo ("Parameter material is null") no quadro em
## que outro boneco nasce. Chamar antes de todo `queue_free` de quem tem contorno.
func _soltar_contorno(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				mi.set_surface_override_material(s, null)
	for filho in n.get_children():
		_soltar_contorno(filho)


## A normal suavizada (a soma das normais dos vértices no mesmo ponto) gravada no
## TANGENT: os blocos do kit têm a normal partida em cada face, e sem isto o casco
## do contorno abriria nos cantos. Uma vez por malha (o resultado fica em cache).
static var _malhas_suaves := {}


static func _suavizar(mi: MeshInstance3D) -> void:
	var original := mi.mesh as ArrayMesh
	if original == null or _malhas_suaves.values().has(original):
		return
	if _malhas_suaves.has(original):
		mi.mesh = _malhas_suaves[original]
		return
	var nova := ArrayMesh.new()
	for s in original.get_surface_count():
		var arr: Array = original.surface_get_arrays(s)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		if ns.size() == vs.size():
			var soma := {}
			for i in vs.size():
				var k := vs[i].snapped(Vector3.ONE * 0.0005)
				soma[k] = soma.get(k, Vector3.ZERO) + ns[i]
			var tg := PackedFloat32Array()
			tg.resize(vs.size() * 4)
			for i in vs.size():
				var n: Vector3 = soma[vs[i].snapped(Vector3.ONE * 0.0005)]
				n = n.normalized() if n.length() > 0.0001 else ns[i]
				tg[i * 4] = n.x
				tg[i * 4 + 1] = n.y
				tg[i * 4 + 2] = n.z
				tg[i * 4 + 3] = 1.0
			arr[Mesh.ARRAY_TANGENT] = tg
		var flags: int = original.surface_get_format(s) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		nova.add_surface_from_arrays(original.surface_get_primitive_type(s), arr, [], {}, flags)
		nova.surface_set_material(s, original.surface_get_material(s))
	_malhas_suaves[original] = nova
	mi.mesh = nova


## Prende o item escolhido num BoneAttachment3D "Item" (G03): o Martelo na mão
## direita, a Âncora na mão direita, o Escudo no braço esquerdo, os três amuletos
## num medalhão no peito. Apaga só o "Item" anterior. A runa é o acento do
## item, no néon do dono.
func _segurar() -> void:
	var esqueleto: Skeleton3D = modelo.find_child("Skeleton3D", true, false)
	if esqueleto == null:
		return
	var velho := esqueleto.find_child("Item", false, false)
	if velho:
		esqueleto.remove_child(velho)
		_soltar_contorno(velho)
		velho.queue_free()
	_mats_runa.clear()
	_area_runa = 0.0
	_area_item = 0.0
	var id := String(ITENS[item_i].id)
	if id == "":
		return
	var presa := BoneAttachment3D.new()
	presa.name = "Item"
	presa.bone_name = "torso" if id in EMBLEMA else ("arm-left" if id == "escudo" else "arm-right")
	esqueleto.add_child(presa)
	match id:
		"martelo":
			var m := _malha_do_item(presa, id, Vector3(-0.01, -0.13, 0.0), Vector3(60, 0, 0), 2.3)
			var c := _caixa_em(m, m)
			var h := c.size.y
			_medir_o_item(presa)
			_runa(m, Vector3(0.002, 0.25 * h, 0.8 * c.size.z),
				Vector3(c.end.x + 0.001, c.end.y - 0.125 * h, c.position.z + c.size.z * 0.5), 0.0, 0)
		"escudo":
			var m := _malha_do_item(presa, id, Vector3(0.03, -0.07, 0.075), Vector3.ZERO, 0.9)
			var c := _caixa_em(m, m)
			var r := maxf(c.size.x, c.size.y) * 0.5
			var centro := Vector2(c.position.x + c.size.x * 0.5, c.position.y + c.size.y * 0.5)
			_medir_o_item(presa)
			# o aro: um octógono regular de 8 caixas, de vértice a 0,975 r do centro
			var apotema := 0.975 * r * cos(deg_to_rad(22.5))
			for i in 8:
				var giro := deg_to_rad(45.0 * i)
				var dir := Vector2.from_angle(giro + PI * 0.5)
				_runa(m, Vector3(0.746 * r, 0.05 * r, 0.004),
					Vector3(centro.x + dir.x * apotema, centro.y + dir.y * apotema, c.end.z + 0.002), giro)
		"ancora":
			var raiz := Node3D.new()
			raiz.position = Vector3(-0.01, -0.13, 0.0)
			raiz.rotation_degrees = Vector3(60, 0, 0)
			presa.add_child(raiz)
			var metal := Kit.material(Itens.METAL, 0.0, 0.55)
			metal.metallic = 0.2
			Kit.caixa(raiz, Vector3(0.025, 0.20, 0.025), Vector3(0, 0.10, 0), metal)
			Kit.caixa(raiz, Vector3(0.06, 0.02, 0.02), Vector3(0, 0.21, 0), metal)
			Kit.caixa(raiz, Vector3(0.10, 0.02, 0.02), Vector3(0, 0.17, 0), metal)
			var pontas: Array[Vector3] = []
			for lado in [-1.0, 1.0]:
				var braco := Kit.caixa(raiz, Vector3(0.07, 0.02, 0.02), Vector3(lado * 0.04, 0.015, 0), metal)
				braco.rotation.z = lado * 0.6
				pontas.append(Vector3(lado * (0.04 + 0.035 * cos(0.6)), 0.015 + 0.035 * sin(0.6), 0.0))
			_medir_o_item(presa)
			for ponta in pontas:
				_runa(raiz, Vector3(0.02, 0.02, 0.02), ponta)
		_:
			var rest := esqueleto.get_bone_global_rest(esqueleto.find_bone("torso"))
			var raiz := Node3D.new()
			raiz.transform = Transform3D(rest.basis.inverse(), rest.affine_inverse() * Vector3(0, 0.28, 0.105))
			presa.add_child(raiz)
			var disco := MeshInstance3D.new()
			var cil := CylinderMesh.new()
			cil.top_radius = 0.03
			cil.bottom_radius = 0.03
			cil.height = 0.008
			cil.radial_segments = 8
			cil.rings = 1
			disco.mesh = cil
			disco.material_override = Kit.material(Itens.CERAMICA, 0.0, 0.35)
			disco.rotation_degrees = Vector3(90, 0, 0)
			raiz.add_child(disco)
			var latao := Kit.material(Itens.LATAO, 0.0, 0.5)
			latao.metallic = 0.2
			for par in EMBLEMA[id]:
				Kit.caixa(raiz, Vector3(par[0].x, par[0].y, 0.004), Vector3(par[1].x, par[1].y, 0.006), latao)
			_medir_o_item(presa)
			# o quadro em volta do emblema: quatro linhas de 0,002, um quadrado de 0,030 de lado
			for lado in [-1.0, 1.0]:
				_runa(raiz, Vector3(0.030, 0.002, 0.004), Vector3(0, lado * 0.014, 0.006))
				_runa(raiz, Vector3(0.002, 0.030, 0.004), Vector3(lado * 0.014, 0, 0.006))


## A malha da Kenney do item, presa e com o material do jogo (rugosidade 0,55 e
## metal 0,2 no máximo: arte/02, a arma em metal batido).
func _malha_do_item(presa: Node3D, id: String, pos: Vector3, rot_graus: Vector3, escala: float) -> Node3D:
	var item: Node3D = load(MALHA_DO_ITEM[id]).instantiate()
	item.position = pos
	item.rotation_degrees = rot_graus
	item.scale = Vector3.ONE * escala
	presa.add_child(item)
	var malhas: Array = item.find_children("*", "MeshInstance3D", true, false)
	if item is MeshInstance3D:
		malhas.append(item)
	for n in malhas:
		var mi: MeshInstance3D = n
		for s in mi.mesh.get_surface_count():
			var base := mi.mesh.surface_get_material(s)
			if base is StandardMaterial3D:
				var peca: StandardMaterial3D = base.duplicate()
				peca.roughness = 0.55
				peca.metallic = 0.2
				if peca.albedo_texture != null:   # o colormap do item, na faixa dos objetos (G08)
					peca.albedo_texture = Pintura.textura(String(MALHA_DO_ITEM[id]).get_base_dir() + "/Textures/colormap.png", "objeto")
				mi.set_surface_override_material(s, peca)
	return item


## O AABB das malhas de `no` (e dele mesmo) no espaço de `ate`, só pelas
## transformações locais: o jogador pode ainda não estar na árvore.
static func _caixa_em(no: Node3D, ate: Node3D) -> AABB:
	var uniao := AABB()
	var primeiro := true
	var lista: Array = no.find_children("*", "MeshInstance3D", true, false)
	if no is MeshInstance3D:
		lista.append(no)
	for n in lista:
		var mi: MeshInstance3D = n
		var t := Transform3D.IDENTITY
		var c: Node = mi
		while c != null and c != ate:
			t = (c as Node3D).transform * t
			c = c.get_parent()
		var a: AABB = t * mi.get_aabb()
		uniao = a if primeiro else uniao.merge(a)
		primeiro = false
	return uniao


## A área de frente do item (x × y do AABB das malhas, no espaço do "Item").
func _medir_o_item(presa: Node3D) -> void:
	var c := _caixa_em(presa, presa)
	_area_item = c.size.x * c.size.y


## A runa: o vão em Tema.JANELA (1,5 vez a linha) 0,001 atrás e a linha no néon
## do dono a 1,6. `eixo` é a normal da face (0 x, 1 y, 2 z); `giro_z` gira as
## duas caixas em z (o aro do escudo).
func _runa(pai: Node3D, tamanho: Vector3, pos: Vector3, giro_z := 0.0, eixo := 2) -> void:
	var normal := Vector3.ZERO
	normal[eixo] = 1.0
	var vao := tamanho * 1.5
	vao[eixo] = 0.001
	var fundo := Kit.caixa(pai, vao, pos - normal * 0.001, Kit.material(Tema.JANELA, 0.0, 0.9))
	var mat := Kit.material(Tema.JOGADOR[lugar], 0.0, 0.8)
	Tema.emissivo(mat, 1.6 * _acesa, lugar)
	var linha := Kit.caixa(pai, tamanho, pos, mat)
	fundo.rotation.z = giro_z
	linha.rotation.z = giro_z
	_mats_runa.append(mat)
	# a área no espaço do "Item", o mesmo de _area_item: a malha do Kenney leva a
	# escala dela (2,3 no martelo, 0,9 no escudo) e a runa, filha dela, também
	var k := 1.0
	var no: Node = pai
	while no != null and not (no is BoneAttachment3D):
		k *= (no as Node3D).scale.x
		no = no.get_parent()
	_area_runa += tamanho.x * tamanho.y * k * k


## A roupa (arte/04): cada parte na sua faixa de valor, o néon do dono só no
## acento (o friso e a costura), no contorno e no aro. O corpo nunca é tingido.
## O colormap fica ao lado do .glb; num boneco do Mini Characters a pele fica
## com a graduação da cabeça (pp = "personagem"), nos outros o colormap inteiro
## vai pelo papel da parte.
func _vestir(n: Node) -> void:
	var esqueleto: Skeleton3D = n.find_child("Skeleton3D", true, false)
	var colormap := _arquivo.get_base_dir() + "/Textures/colormap.png"
	var pp := "personagem" if "/mini-characters/" in _arquivo else ""
	n.set_meta("so_pano", pp != "")
	for filho in n.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = filho
		var nome_da_malha := String(mi.name)
		var corpo := nome_da_malha.begins_with("body")
		if not corpo and not nome_da_malha.begins_with("head"):
			continue
		var medidas := Pintura.preparar(mi, esqueleto)
		for s in mi.mesh.get_surface_count():
			var m := ShaderMaterial.new()
			m.shader = SH_CAVALEIRO
			if corpo:
				m.set_shader_parameter("textura_cima", Pintura.textura(colormap, "tecido", pp))
				m.set_shader_parameter("textura_baixo", Pintura.textura(colormap, "couro", pp))
				m.set_shader_parameter("rugoso_cima", RUGOSO_CIMA)
				m.set_shader_parameter("rugoso_baixo", RUGOSO_BAIXO)
				for k in ["friso_y0", "friso_y1", "friso_alto", "costura_x", "costura_larg"]:
					m.set_shader_parameter(k, float(medidas[k]))
				if _medidas.is_empty():
					_medidas = medidas
			else:
				var cabeca := Pintura.textura(colormap, "personagem", "personagem" if pp != "" else "")
				m.set_shader_parameter("textura_cima", cabeca)
				m.set_shader_parameter("textura_baixo", cabeca)
				m.set_shader_parameter("rugoso_cima", RUGOSO_CABECA)
				m.set_shader_parameter("rugoso_baixo", RUGOSO_CABECA)
				m.set_shader_parameter("tem_acento", false)
			var ctn := Tema.contorno(Tema.JOGADOR[lugar], CONTORNO_LARGURA, _brilho_do_contorno * _acesa, lugar)
			m.next_pass = ctn
			m.set_shader_parameter("dono", Tema.JOGADOR[lugar])
			m.set_shader_parameter("apagado", Tema.GRAFITE)
			m.set_shader_parameter("acesa", _acesa)
			m.set_shader_parameter("pele_uv", Vector4(Pintura.PELE_UV.position.x, Pintura.PELE_UV.position.y,
				Pintura.PELE_UV.end.x, Pintura.PELE_UV.end.y))
			mi.set_surface_override_material(s, m)
			_contornos.append(ctn)
			(_mats_corpo if corpo else _mats_cabeca).append(m)


## O encaixe de uma peça (a G13 chama; a G03 chama ao trocar o item): o acento do
## corpo e a runa do item sobem a 2,6 e voltam a 1,6 em 0,25 s (SAI). É luz, não
## movimento: vale também com o movimento reduzido.
func acender_acento() -> void:
	if not is_inside_tree():
		return
	var t := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var repouso := _acento_de_repouso()
	t.tween_method(_acento_em, minf(repouso + 1.0, ACENTO_TETO), repouso, 0.25)


func _acento_em(v: float) -> void:
	for m in _mats_corpo:
		m.set_shader_parameter("acento", v)
	for m in _mats_runa:
		Tema.emissivo(m, v * _acesa, lugar)


## A armadura apagada (0: o corpo em Tema.GRAFITE, sem acento, sem aro, sem
## contorno) ou acesa (1: como o _vestir deixou).
func acender(k: float) -> void:
	k = clampf(k, 0.0, 1.0)
	_acesa = k
	for m in _mats_corpo:
		m.set_shader_parameter("acesa", k)
	for m in _mats_cabeca:
		m.set_shader_parameter("acesa", k)
	for c in _contornos:
		c.set_shader_parameter("energia", _brilho_do_contorno * k)
	for m in _mats_runa:
		Tema.emissivo(m, 1.6 * k, lugar)
	if aro:
		aro.visible = k >= 0.5


## Mostra ou esconde a cabeça (a malha "head-mesh" do boneco).
func cabeca(visivel: bool) -> void:
	var c := modelo.find_child("head-mesh", true, false) if modelo else null
	if c == null and modelo:
		c = modelo.find_child("head", true, false)   # a cabeça do cavaleiro de três peças (G13)
	if c is Node3D:
		c.visible = visivel


func _animar(nome: String, velocidade := 1.0) -> void:
	if anim == null or not anim.has_animation(nome):
		return
	if _anim_atual != nome:
		_anim_atual = nome
		anim.play(nome, 0.15)
	anim.speed_scale = velocidade


## A animação de base, pedida pela sala (um gesto em curso tem a vez).
func animar(nome: String, velocidade := 1.0) -> void:
	if _gesto <= 0.0:
		_animar(nome, velocidade)


## Um gesto que roda uma vez (comemorar, levar dano, cair).
func gesto(nome: String, duracao := 1.0) -> void:
	if anim == null or not anim.has_animation(nome):
		return
	_anim_atual = nome
	anim.play(nome, 0.1)
	_gesto = duracao


func _ready() -> void:
	_notification(NOTIFICATION_VISIBILITY_CHANGED)


## Lugar vazio: o boneco some e deixa de ocupar espaço (não trava quem anda).
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		collision_layer = 1 if visible else 0
		collision_mask = 1 if visible else 0
	elif what == NOTIFICATION_PREDELETE and is_instance_valid(modelo):
		_soltar_contorno(modelo)


func olhar_para(alvo: Vector3) -> void:
	var d := alvo - global_position
	if Vector2(d.x, d.z).length() > 0.01:
		_yaw = atan2(d.x, d.z)
		rotation.y = _yaw


func _physics_process(dt: float) -> void:
	if cooldown > 0.0:
		cooldown -= dt
	if _gesto > 0.0:
		_gesto -= dt
	if preso:
		velocity = Vector3.ZERO
		return
	var mv := Forja.mover(lugar) if controlavel else Vector2.ZERO
	var rapido := mv.length() > 0.92
	var v := Vector3(mv.x, 0, mv.y) * (CORRIDA if rapido else VELOCIDADE)
	velocity.x = v.x
	velocity.z = v.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - 18.0 * dt
	move_and_slide()
	if mv.length() > 0.05:
		_yaw = lerp_angle(_yaw, atan2(mv.x, mv.y), minf(1.0, dt * 14.0))
		rotation.y = _yaw
	if _gesto > 0.0:
		return
	if mv.length() > 0.05:
		_animar("sprint" if rapido else "walk", 0.8 + mv.length() * 0.5)
	else:
		_animar("idle")


## O índice em BONECOS de um dos 12 do Mini Characters (o que `modelo_i` guarda da cabeça).
static func indice_do_personagem(personagem: String) -> int:
	return PRIMEIRO_PERSONAGEM + maxi(0, Cavaleiro.PERSONAGENS.find(personagem))


## Veste o cavaleiro de três peças (G13): `novas` é o personagem da cabeça, do
## superior e do inferior. O esqueleto e as animações são os do superior (os 12
## têm o mesmo esqueleto); `modelo_i` passa a ser o da cabeça (é o que o pio lê).
## Com `item` < 0, o item fica o de agora.
func vestir_pecas(novas: Array, item := -1) -> void:
	pecas = [str(novas[0]), str(novas[1]), str(novas[2])]
	if item >= 0:
		item_i = wrapi(item, 0, ITENS.size())
	modelo_i = indice_do_personagem(pecas[0])
	if modelo:
		_soltar_contorno(modelo)
		modelo.queue_free()
	_arquivo = Kit.caminho(str(BONECOS[indice_do_personagem(pecas[1])].arquivo))
	modelo = load(_arquivo).instantiate()
	Montar.trocar(modelo, pecas)
	modelo.scale = Vector3.ONE * ESCALA
	add_child(modelo)
	_mats_corpo.clear()
	_mats_cabeca.clear()
	_contornos.clear()
	_medidas = {}
	anim = modelo.find_child("AnimationPlayer", true, false)
	for nome_da_anim in ["idle", "walk", "sprint"]:
		if anim and anim.has_animation(nome_da_anim):
			anim.get_animation(nome_da_anim).loop_mode = Animation.LOOP_LINEAR
	_vestir(modelo)
	_juntar_as_medidas()
	_anim_atual = ""
	_animar("idle")
	_segurar()
	_aplicar_acabamento()
	contornar(_brilho_do_contorno)


## Troca uma peça só (0 cabeça, 1 superior, 2 inferior), sem remontar o
## esqueleto: a animação não reinicia. As três malhas se repintam.
func trocar_peca(parte: int, personagem: String) -> void:
	if pecas.size() != 3 or modelo == null:
		vestir_pecas([personagem, personagem, personagem])
		return
	pecas[parte] = personagem
	if parte == 0:
		modelo_i = indice_do_personagem(personagem)
	var esq: Skeleton3D = modelo.find_child("Skeleton3D", true, false)
	var velha := esq.get_node_or_null(Montar.MALHAS[parte])
	if velha:
		_soltar_contorno(velha)
	for m in _mats_corpo + _mats_cabeca:
		_contornos.erase(m.next_pass)
	_mats_corpo.clear()
	_mats_cabeca.clear()
	_medidas = {}
	Montar.parte(esq, parte, personagem)
	_vestir(modelo)
	_juntar_as_medidas()
	_aplicar_acabamento()


## As medidas do acento de duas peças: o friso do superior, a costura do
## inferior (Pintura.juntar_medidas), em todo material do corpo.
func _juntar_as_medidas() -> void:
	var esq: Skeleton3D = modelo.find_child("Skeleton3D", true, false) if modelo else null
	var sup := esq.get_node_or_null("body-sup") as MeshInstance3D if esq else null
	var inf := esq.get_node_or_null("body-inf") as MeshInstance3D if esq else null
	if sup == null or inf == null:
		return
	_medidas = Pintura.juntar_medidas(Pintura.medidas_da(sup), Pintura.medidas_da(inf))
	for m in _mats_corpo:
		for k in ["friso_y0", "friso_y1", "friso_alto", "costura_x", "costura_larg"]:
			m.set_shader_parameter(k, float(_medidas[k]))


## Acende uma parte só (a forja da G13): "cabeca", "superior", "inferior" ou
## "item", de 0 (apagada, como o acender(0) naquela malha) a 1.
func acender_parte(parte: String, k: float) -> void:
	k = clampf(k, 0.0, 1.0)
	var esq: Skeleton3D = modelo.find_child("Skeleton3D", true, false) if modelo else null
	if esq == null:
		return
	if parte == "item":
		var item := esq.find_child("Item", false, false)
		var malhas: Array[Node] = []
		if item:
			malhas = item.find_children("*", "MeshInstance3D", true, false)
		for n in malhas:
			var mi := n as MeshInstance3D
			for s in mi.mesh.get_surface_count():
				var m := mi.get_surface_override_material(s)
				if m and m.next_pass is ShaderMaterial:
					(m.next_pass as ShaderMaterial).set_shader_parameter("energia", _brilho_do_contorno * k)
		for m in _mats_runa:
			Tema.emissivo(m, 1.6 * k, lugar)
		return
	var mi := esq.get_node_or_null(["head", "body-sup", "body-inf"][maxi(0, ["cabeca", "superior", "inferior"].find(parte))]) as MeshInstance3D
	if mi == null:
		return
	for s in mi.mesh.get_surface_count():
		var m := mi.get_surface_override_material(s) as ShaderMaterial
		if m:
			m.set_shader_parameter("acesa", k)
			if m.next_pass is ShaderMaterial:
				(m.next_pass as ShaderMaterial).set_shader_parameter("energia", _brilho_do_contorno * k)
