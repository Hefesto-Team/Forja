# K1 — O Molde

**Sprint:** K · **Slot:** S03_J11 · **Tamanho:** G · **Depende de:** H04, H08, F09, F03, F05, H07, G05, G10, G12, G14, G15

## Por quê

O Molde de hoje (`godot/scripts/salas/molde.gd`) traça uma letra em silêncio, de olho no dedo, e a peça leva 8
tempos. O novo traça a letra no tempo, em coro, e os quatro moldes abrem juntos no carimbo: as peças inteiras e as
tortas saem lado a lado para a estante. É o primeiro da seção: passa a sala para o kit e cria o `secao.gd` que a K2
e a K5 usam.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (a FICHA, os ganchos, o que o kit dá pronto)
- [`godot/scripts/salas/molde.gd`](../../../godot/scripts/salas/molde.gd) (inteiro: esta ficha o desmonta)
- [O índice da seção](K-o-molde.md) (as convenções do toque; a tabela do `secao.gd` de lá é a velha, e vale a desta ficha)

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão, o RPG e a G15) já está copiado nesta ficha, com os
números. Não abra outro documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s03/secao.gd` | novo: a oficina e as funções da seção | **da seção**: a K1 cria; K2 a K5 só chamam, nenhuma o reescreve |
| `godot/scripts/minigames/s03/o_molde.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/minigame.gd` | `"momento"` em `TIPOS_DO_JOGO` e a função `momento()` | **de todos**: se a L1 ou outra já pôs, não escreva de novo |
| `godot/scripts/minigames/catalogo.gd` | `"S03_J11"` em `MINIGAMES` e na lista `minigames` da S03; sai `"molde"` de `SALAS_ANTIGAS` | **da seção**: K2 a K5 acrescentam uma linha cada |
| `godot/scripts/traducoes.gd` | `"Molde!"` e o placar `Peças:` | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_do_molde()` e a linha `"S03_J11"` no `match` de `_prova_da_ficha` | **de todos** |
| `godot/testes/captura_jogo.gd` | os momentos de `"molde"` | **de todos** |
| `docs/jogo/13-arquitetura.md` | a linha `momento` na tabela «Os eventos do jogo» | **de todos**: se já existe, não escreva de novo |
| `godot/scripts/salas/molde.gd` e o `.uid` dele | `git rm` | só desta |

Os dois `.uid` novos (`o_molde.gd.uid` e `secao.gd.uid`) saem do import
(`"$GODOT" --headless --path godot --import --quit`) e entram no commit. O apelido `molde` continua abrindo a seção:
o `Catalogo.resolver("molde")` devolve o primeiro minigame da S03, que passa a ser o `S03_J11`.

### O que muda de hoje

| hoje (`salas/molde.gd`) | depois |
| --- | --- |
| a peça de 8 tempos, um passo a cada 2 tempos | a primeira de 8 tempos (a bancada); depois, a de 4 tempos, um passo por tempo |
| cada um no seu tempo | os quatro em coro: toda peça de 4 tempos começa no tempo 1 de um compasso |
| a falha zera a peça | a falha deixa a peça torta, com forma (a espada em S, o escudo dobrado, o elmo achatado), e ela vale 0,5 |
| a peça some | a peça salta para a estante do lugar e fica lá até o fim (o placar no mundo) |
| o mesmo pulso do começo ao fim | de 30 a 60 s, a fornada de 3 tempos, contra o compasso |
| as cores soltas (o roxo, `#f1c86a`, o verde e o vermelho) | só os tokens da G14 |
| a câmera e a luz da sala | a oficina da seção (`SECAO.montar`) e o pico |

### O kit que esta ficha usa

As funções que a H04 e a H08 deixam no `Minigame` (não reimplemente):

```gdscript
presentes() -> Array; conectado(l) -> bool; na_raia(l) -> bool; jogador(l) -> ForjaPlayer
acender_raia(l, forca); martelo_na_mao(p); maos_livres(p); atmosfera(cor_ar, cor_neon, brasas, n)
julgar_toque(l, t_alvo, n := -1, perigo := false) -> int   # chama toque() ou falha()
nota_perdida(l, n); nova_nota(l, n, t_alvo); anotar(tipo, l, campos := {}); marcar(l, pontos)
andamento() -> float (0..1, em tempo de música); no_pico() -> bool; tremer(forca)  # G05
const RAIAS := [-6.0, -2.0, 2.0, 6.0]; const Z_JOGADOR := 1.4; const FOLGA_PERDIDA := 0.140
const BATIDA_DA_PRIMEIRA_NOTA := 4
var camera_pos; var camera_olhar; var rng; var treinando; var jogadores; var pontos; var fase; var acabou; var duracao; var coop
```

Do `Forja`: `Forja.dedo(l, i)` (um Vector3: `x` e `y` de 0 a 1, y para baixo; `z = 1` é o dedo encostado),
`Forja.capacidade(l, "toque")`, `Forja.apertou(l, Forja.TOUCHPAD)`, `Forja.gatilho(l, 1, Forja.GATILHO_OFF)`,
`Forja.sentir(l, nome)` (F05), `Forja.vibrar(l, forte, fraco, ms)`, `Forja.textura(l, mat)`,
`Forja.som_falante(l, som, ganho)`, `Forja.som_tem(l, Forja.PAPEL_HAPTICA)`, `Forja.robo`,
`Forja.robo_tocar(l, dedo, x, y, s)`, `Forja.robo_apertar(l, botao, s)`, `Forja.robo_acerta()`,
`Forja.med_pedir(l, o)` e `Forja.med_tracou(l)`.

Do `Ritmo`, do `Som`, do `Tema`, do `Kit` e dos `Itens`: `Ritmo.t_musica()`, `Ritmo.batida()`,
`Ritmo.t_da_batida(b)`, `Ritmo.bpm`, `Ritmo.simples[l]`, `Ritmo.PERFEITO`, `Ritmo.ERRO`; `Som.tocar(nome, pos, db,
tom)`, `Som.no_controle(l, nome, ganho)`; `Tema.luz_da_secao("S03", "A")` (G15: um `Dictionary` com `nevoa`,
`preenchimento` e `chave`, três cores), `Tema.neon(cor, energia, dono)`, `Tema.emissivo(material, energia, dono)`
(o dono é o lugar, com teto 3,0; `"forja"`, com teto 2,4 e `TUNGSTENIO`; `"mundo"`, com teto 1,2), os tokens da
G14 e `Tema.archivo(peso)`; `Kit.arena(sala, largura, fundo)`, `Kit.peca(pai, nome, pos, rot_y, escala := 2.0)`,
`Kit.caminho(nome)` (G10), `Kit.caixa(pai, tamanho, pos, mat)`, `Kit.material(cor, brilho, rugoso)`,
`Kit.chapado(cor)`; `Efeitos.faiscas(pai, pos, cor, n, forca)`; `Itens.antecipacao_s(l, bpm)` (a Lanterna, G03).

### A função `momento` (em `minigame.gd`, de todos)

O tipo `momento` é o da régua da diversão (itens 4 e 8). Se a L1 já o pôs, pule este passo. Em `TIPOS_DO_JOGO`,
acrescente `"momento"` ao fim da lista. Ao fim do arquivo:

```gdscript
## Um momento de grito (docs/jogo/diversao/README.md, itens 4 e 8): a linha
## `momento` com o nome, o tempo de música e onde o objeto dele está na tela
## (x_tela e altura_tela, de 0 a 1). `l` é -1 quando o momento é de todos.
func momento(nome: String, l: int, pos: Vector3, altura_m: float, campos := {}) -> void:
	var c: Dictionary = campos.duplicate()
	c["nome"] = nome
	c["t_musica"] = snappedf(Ritmo.t_musica(), 0.001)
	var cam := get_viewport().get_camera_3d()
	var tam := get_viewport().get_visible_rect().size
	if cam and tam.y > 0.0:
		var base := cam.unproject_position(pos)
		var topo := cam.unproject_position(pos + Vector3.UP * altura_m)
		c["x_tela"] = snappedf(base.x / tam.x, 0.001)
		c["altura_tela"] = snappedf(absf(base.y - topo.y) / tam.y, 0.001)
	anotar("momento", l, c)
```

No [13](../13-arquitetura.md), na tabela «Os eventos do jogo», depois da linha `estacao`, se ainda faltar:
`| \`momento\` | o momento de grito do minigame: \`nome\`, \`t_musica\`, \`x_tela\` e \`altura_tela\` (0 a 1); \`lugar\` 0 quando é de todos (docs/jogo/diversao/README.md) |`.

### `godot/scripts/minigames/s03/secao.gd` (novo, o arquivo inteiro)

```gdscript
extends RefCounted
## A seção O Molde (S03): o que os cinco minigames têm em comum. A oficina na
## luz petróleo, a bancada com a placa na proporção do touchpad (o dedo aparece
## onde o jogo o vê), os dedos na placa, as peças facetadas, a textura sob o
## dedo, o pico (a câmera recua e a chave sobe), os degraus do impacto, a reta e
## os ganchos do cavaleiro. Sem class_name:
## const SECAO := preload("res://scripts/minigames/s03/secao.gd").

const LARGURA := 2.4  ## a placa no mundo, em m (2:1, como o touchpad)
const ALTURA := 1.2
const ASPECTO := 2.0
const INCLINACAO := 40.0  ## graus: a borda de longe sobe e a placa fica de frente para a plongée de 50°
## A chave da seção: um OmniLight3D alto, na frente da cena.
const CHAVE_POS := Vector3(0, 7.5, 5.0)
const CHAVE_ENERGIA := 1.4
const CHAVE_ALCANCE := 26.0
## A luz de cada bancada (tungstênio, dono "forja").
const FOGO_ENERGIA := 0.8
## O pico: a câmera recua 10 %, a chave sobe 20 % e a névoa cai a 80 %. Sobe em 1 batida e volta em 2.
const PICO_RECUO := 1.1
const PICO_CHAVE := 1.2
const PICO_NEVOA := 0.8
## O main treme a câmera 0,12 m por unidade de tremor.
const METROS_POR_TREMOR := 0.12
## Os degraus do impacto (a régua da diversão, «O exagero do impacto»): o tremor
## em m e por quantas batidas, a parada (hit-stop) em quadros, só no cavaleiro, e as faíscas.
const DEGRAUS := {
	"golpe": {"tremor": 0.02, "batidas": 1.0, "parada": 2, "faiscas": 24},
	"estrondo": {"tremor": 0.05, "batidas": 2.0, "parada": 3, "faiscas": 50},
	"catastrofe": {"tremor": 0.08, "batidas": 4.0, "parada": 0, "faiscas": 60},
}
## As últimas 16 batidas são a reta.
const RETA_BATIDAS := 16.0
## O aviso nunca abaixo de 0,45 s (o olho do sofá a 3 m).
const AVISO_MIN_S := 0.45
## Os ganchos dos stats no neutro (o stat 3), enquanto a classe Cavaleiro (G13) não existe.
const NEUTRO := {"levantar": 1.0, "pista": 0.0, "empurrao": 1.0, "velocidade": 1.0}

static var _textura_b := [-99.0, -99.0, -99.0, -99.0]


## A oficina: o chão e as paredes do kit, a luz petróleo da seção, o fundo e a
## câmera. Guarda o estado da seção em `sala.get_meta("s03")` e devolve a névoa
## do main como estava quando a sala sai.
static func montar(sala: Minigame, cam_pos: Vector3, cam_olhar: Vector3) -> void:
	_textura_b = [-99.0, -99.0, -99.0, -99.0]
	sala.camera_pos = cam_pos
	sala.camera_olhar = cam_olhar
	Kit.arena(sala, 5, 3)
	var luz: Dictionary = Tema.luz_da_secao("S03", "A")
	sala.atmosfera(luz.preenchimento, Tema.VIOLETA, false, 50)
	var chave := OmniLight3D.new()
	chave.position = CHAVE_POS
	chave.light_color = luz.chave
	chave.light_energy = CHAVE_ENERGIA
	chave.omni_range = CHAVE_ALCANCE
	sala.add_child(chave)
	var env: Environment = sala.get_viewport().find_world_3d().environment
	var nevoa := 0.0
	if env:
		nevoa = env.fog_density
		var cor_antes := env.fog_light_color
		env.fog_light_color = luz.nevoa
		sala.tree_exiting.connect(func() -> void:
			env.fog_density = nevoa
			env.fog_light_color = cor_antes)
	peca(sala, "survival-kit/workbench", "table", Vector3(-9.5, 0, -6.0))
	peca(sala, "survival-kit/workbench", "table", Vector3(9.5, 0, -6.0), PI)
	peca(sala, "factory-kit/machine-bed", "barrel", Vector3(0, 0, -8.0))
	peca(sala, "survival-kit/barrel", "barrel", Vector3(-10.6, 0, 2.0))
	peca(sala, "survival-kit/barrel", "barrel", Vector3(10.6, 0, 2.0), 0.7)
	sala.set_meta("s03", {"pos": cam_pos, "olhar": cam_olhar, "chave": chave, "env": env, "nevoa": nevoa,
		"k": 0.0, "tremor": 0.0, "tremor_ate": -99.0, "clarao_ate": -99.0, "apagao_ate": -99.0,
		"so_um": -1, "so_um_ate": -99.0, "fogos": {}, "reta": false})


## Uma peça de pacote (G10). Sem o pacote importado, a reserva do mini-dungeon.
static func peca(pai: Node, nome: String, reserva: String, pos: Vector3, rot_y := 0.0, escala := 2.0) -> Node3D:
	if ResourceLoader.exists(Kit.caminho(nome)):
		return Kit.peca(pai, nome, pos, rot_y, escala)
	push_warning("S03: a peça %s não está importada; vai a reserva %s" % [nome, reserva])
	return Kit.peca(pai, reserva, pos, rot_y, escala)


## Um ponto do touchpad (x e y de 0 a 1, y para baixo) na placa, à `altura` da face.
static func no_molde(x: float, y: float, altura := 0.12) -> Vector3:
	return Vector3((x - 0.5) * LARGURA, altura, (y - 0.5) * ALTURA)


## A distância entre dois toques, em larguras do touchpad (como o núcleo mede).
static func distancia(a: Vector2, b: Vector2) -> float:
	return Vector2((b.x - a.x) * ASPECTO, b.y - a.y).length() / ASPECTO


## Um disco de 8 lados (no lugar da esfera e do cilindro lisos).
static func disco8(pai: Node, raio: float, altura: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = raio
	c.bottom_radius = raio
	c.height = altura
	c.radial_segments = 8
	c.rings = 1
	mi.mesh = c
	mi.position = pos
	mi.material_override = mat
	pai.add_child(mi)
	return mi


## Um anel de 8 lados (no lugar do toro liso; nunca Efeitos.anel).
static func anel8(pai: Node, raio: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = raio * 0.84
	t.outer_radius = raio
	t.rings = 8
	t.ring_segments = 4
	mi.mesh = t
	mi.position = pos
	mi.material_override = mat
	pai.add_child(mi)
	return mi


## A bancada do lugar e a placa (o touchpad no mundo). Com o molde, as duas
## metades de pedra e o metal no fundo; sem ele, só a moldura de pedra.
static func bancada(sala: Minigame, l: int, com_molde := true) -> Dictionary:
	var cx: float = Minigame.RAIAS[l] + 0.45
	Kit.caixa(sala, Vector3(2.8, 0.8, 1.7), Vector3(cx, 0.4, 0.3), Kit.material(Tema.CASCO_ALTO, 0.0, 0.9))
	Kit.caixa(sala, Vector3(2.9, 0.08, 1.8), Vector3(cx, 0.82, 0.3), Kit.material(Tema.GRAFITE, 0.0, 0.8))
	var fogo := OmniLight3D.new()
	fogo.position = Vector3(cx, 2.4, 1.2)
	fogo.light_color = Tema.TUNGSTENIO
	fogo.light_energy = FOGO_ENERGIA
	fogo.omni_range = 4.5
	sala.add_child(fogo)
	sala.get_meta("s03").fogos[l] = fogo
	var placa := Node3D.new()
	placa.position = Vector3(cx, 1.12, 0.3)
	placa.rotation.x = deg_to_rad(INCLINACAO)
	sala.add_child(placa)
	var metades: Array = []
	var metal := Kit.material(Tema.OXIDO, 0.0, 0.55)
	Tema.emissivo(metal, 0.3, "forja")
	var pedra := Kit.material(Tema.GRAFITE, 0.0, 0.85)
	if com_molde:
		for lado in [-1.0, 1.0]:
			var metade := Node3D.new()
			placa.add_child(metade)
			Kit.caixa(metade, Vector3(LARGURA * 0.5 + 0.12, 0.16, ALTURA + 0.26), Vector3(lado * (LARGURA * 0.25 + 0.06), 0, 0), pedra)
			Kit.caixa(metade, Vector3(LARGURA * 0.5 - 0.02, 0.03, ALTURA), Vector3(lado * LARGURA * 0.25, 0.085, 0), metal)
			metades.append(metade)
	else:
		Kit.caixa(placa, Vector3(LARGURA + 0.24, 0.16, ALTURA + 0.26), Vector3.ZERO, pedra)
	var dedos: Array = []
	for d in 2:
		var disco := disco8(placa, 0.08, 0.03, Vector3.ZERO, Tema.neon(Tema.JOGADOR[l], 1.8 if d == 0 else 1.2, l))
		disco.visible = false
		dedos.append(disco)
	var ligacao := Kit.caixa(placa, Vector3(0.025, 0.01, 1.0), Vector3.ZERO, Kit.chapado(Color(Tema.ETIQUETA, 0.6)))
	ligacao.visible = false
	var pronta := Kit.material(Tema.SECAO[3], 0.0, 0.6)
	pronta.metallic = 0.15  # fosco: a mostarda é cor, não reflexo
	return {"placa": placa, "metades": metades, "metal": metal, "dedos": dedos, "ligacao": ligacao,
		"pronta": pronta, "fogo": fogo, "cx": cx}


## Os dois dedos do lugar na placa e, quando são dois, a ligação entre eles.
static func mostrar_dedos(sala: Minigame, l: int, nos: Dictionary) -> void:
	var d := [Forja.dedo(l, 0), Forja.dedo(l, 1)]
	for k in 2:
		var disco: MeshInstance3D = nos.dedos[k]
		disco.visible = sala.fase == "jogo" and d[k].z > 0.5
		if disco.visible:
			disco.position = no_molde(d[k].x, d[k].y, 0.16)
	var lig: MeshInstance3D = nos.ligacao
	lig.visible = sala.fase == "jogo" and d[0].z > 0.5 and d[1].z > 0.5
	if lig.visible:
		var a := no_molde(d[0].x, d[0].y, 0.15)
		var b := no_molde(d[1].x, d[1].y, 0.15)
		lig.position = (a + b) * 0.5
		lig.rotation.y = atan2(b.x - a.x, b.z - a.z)
		lig.scale = Vector3(1, 1, maxf(0.01, a.distance_to(b)))


## A textura do material sob o dedo, só nos atuadores (`Forja.textura`, H08: a
## háptica, sem o alto-falante), no máximo a cada quarto de tempo. No rádio,
## nada: a pista vai pela nota e pela tela.
static func textura(l: int, material: String) -> void:
	var b := Ritmo.batida()
	if b - float(_textura_b[l]) < 0.25 or not Forja.som_tem(l, Forja.PAPEL_HAPTICA):
		return
	_textura_b[l] = b
	Forja.textura(l, material)


## A cada quadro, chamada do jogar() de cada minigame: o pico (a câmera recua,
## a chave sobe, a névoa abre), o tremor dos degraus, o clarão da catástrofe, o
## apagão do erro, as bancadas do "só um" e a linha `momento` `reta`.
static func pico(sala: Minigame) -> void:
	var m: Dictionary = sala.get_meta("s03")
	var b := Ritmo.batida()
	var batidas_no_quadro := sala.get_process_delta_time() * Ritmo.bpm / 60.0
	var alvo := 1.0 if sala.no_pico() else 0.0
	var passo := batidas_no_quadro if alvo > float(m.k) else batidas_no_quadro * 0.5
	m.k = move_toward(float(m.k), alvo, passo)
	var olhar: Vector3 = m.olhar
	sala.camera_pos = olhar + (Vector3(m.pos) - olhar) * lerpf(1.0, PICO_RECUO, float(m.k))
	var energia := CHAVE_ENERGIA * lerpf(1.0, PICO_CHAVE, float(m.k))
	if b < float(m.clarao_ate):
		energia *= 1.4
	if b < float(m.apagao_ate):
		energia *= 0.7
	(m.chave as OmniLight3D).light_energy = energia
	var env: Environment = m.env
	if env:
		env.fog_density = float(m.nevoa) * lerpf(1.0, PICO_NEVOA, float(m.k))
	if b < float(m.tremor_ate):
		sala.tremer(float(m.tremor))
	for l in m.fogos:
		var so_os_outros := b < float(m.so_um_ate) and int(m.so_um) != int(l)
		(m.fogos[l] as OmniLight3D).light_energy = FOGO_ENERGIA * (0.7 if so_os_outros else 1.0)
	if not bool(m.reta) and sala.fase == "jogo" and na_reta(sala):
		m.reta = true
		var ordem: Array = [] if sala.coop else sala.vencedor()
		sala.momento("reta", -1, Vector3(0, 1.0, -1.6), 2.0, {"ordem": ordem})


## Um degrau do impacto, no mesmo quadro: o tremor, as faíscas e a parada do cavaleiro.
static func degrau(sala: Minigame, l: int, nome: String, onde: Vector3, cor: Color) -> void:
	var d: Dictionary = DEGRAUS[nome]
	var m: Dictionary = sala.get_meta("s03")
	m.tremor = float(d.tremor) / METROS_POR_TREMOR
	m.tremor_ate = Ritmo.batida() + float(d.batidas)
	Efeitos.faiscas(sala, onde, cor, int(d.faiscas), 1.0)
	if nome == "catastrofe":
		m.clarao_ate = Ritmo.batida() + 1.0
	if int(d.parada) > 0 and l >= 0:
		_parar(sala.jogador(l), int(d.parada))


## A parada (hit-stop): a animação do cavaleiro congela por `quadros` quadros; a música não para.
static func _parar(p: ForjaPlayer, quadros: int) -> void:
	if p == null or p.anim == null:
		return
	p.anim.speed_scale = 0.0
	for i in quadros:
		await p.get_tree().process_frame
	if is_instance_valid(p) and p.anim:
		p.anim.speed_scale = 1.0


## O erro sem cor (K3): a luz da seção cai 30 % por 1 batida.
static func apagao(sala: Minigame) -> void:
	sala.get_meta("s03").apagao_ate = Ritmo.batida() + 1.0


## O momento de um só: as bancadas dos outros a 70 % por 1 batida.
static func so_um(sala: Minigame, l: int) -> void:
	var m: Dictionary = sala.get_meta("s03")
	m.so_um = l
	m.so_um_ate = Ritmo.batida() + 1.0


## As últimas 16 batidas da música.
static func na_reta(sala: Minigame) -> bool:
	return (1.0 - sala.andamento()) * sala.duracao <= RETA_BATIDAS * 60.0 / Ritmo.bpm


## O gancho do stat (docs/jogo/sistemas/stats.csv): o da classe Cavaleiro (G13)
## quando ela existe; o neutro enquanto não existe.
static func gancho(l: int, nome: String) -> float:
	for c in ProjectSettings.get_global_class_list():
		if c["class"] == "Cavaleiro":
			return float(load(c["path"]).gancho(l, nome))
	return float(NEUTRO[nome])


## A queda em tempos: `tempos` × levantar (o Fôlego), arredondada à semicolcheia, no mínimo uma.
static func queda(l: int, tempos: float) -> float:
	return maxf(0.25, roundf(tempos * gancho(l, "levantar") * 4.0) / 4.0)


## O aviso antes da nota, em s: 1 batida (2 se 1 batida não chega a 0,45 s), mais
## a Lanterna (meio tempo) e o Faro (a pista, em ms). Nunca abaixo de 0,45 s.
static func aviso_s(l: int) -> float:
	var batida := 60.0 / Ritmo.bpm
	if batida < AVISO_MIN_S:
		batida *= 2.0
	return maxf(AVISO_MIN_S, batida + Itens.antecipacao_s(l, Ritmo.bpm) + gancho(l, "pista") / 1000.0)
```

### `godot/scripts/minigames/s03/o_molde.gd` (novo, o arquivo inteiro)

```gdscript
extends Minigame
## O Molde (S03_J11), o primeiro da seção O Molde. O touchpad é a placa do molde
## na bancada. O dedo passa pelos pontos da letra, um por tempo, e o clique
## carimba: o molde abre sozinho e a peça sai para a estante. Os quatro juntos,
## como um coro: os quatro moldes abrem na mesma batida (o desmolde). A primeira
## peça de cada um ainda abre e fecha com dois dedos (a bancada mede).
## No pico, a fornada: a peça de 3 tempos, contra o compasso.
##
## A falha: o metal escorre e a peça sai torta, com forma (a espada em S, o
## escudo dobrado, o elmo achatado), e vale meia peça.
## O vencedor: mais peças (a torta vale 0,5; a inteira da reta vale 2).
## O alto-falante do dono: o carimbo no clique, o clique nos pontos, a nota no perfeito.
## O registro mede: dois dedos, a área do touchpad, a abertura e o clique (as
## medidas do núcleo, os vereditos da bancada); a posição de cada toque (a
## linha `entrada`); o tempo (o kit); o `momento` `desmolde` de cada peça e o `reta`.
## O robô desliza pelo sulco e chega ao ponto na nota, clica na nota, abre e
## fecha na primeira peça (ou 200 ms atrasado).
## Com menos de quatro: nada muda.
## A régua: "Molde!" e o touchpad bastam; sem a tela, não (a letra é visual);
## nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s03/secao.gd")

const FICHA := {
	"slot": "S03_J11",
	"titulo": "O Molde",
	"verbo": "Molde!",
	"genero": "tct",
	"icone": "touchpad",
	"entradas": [Forja.TOUCHPAD],
	"camera": "fixa",
	"faixa": "MUS_S03_J11",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "pedra",
	"microjogo": {"verbo": "Molde!", "segundos": 6.0},
	# o que a bancada mede (o veredito é das medidas do núcleo)
	"features": ["touchpad_dois_dedos", "touchpad_clique"],
	"botoes_medidos": [Forja.TOUCHPAD],
	"gesto": "interact-right",
}

const CAMERA_POS := Vector3(0.2, 11.2, 8.4)
const CAMERA_OLHAR := Vector3(0.2, 0.9, -0.3)
const LETRAS := [
	{"x": [0.08, 0.50, 0.92], "y": [0.88, 0.12, 0.88]},  # Λ: o elmo
	{"x": [0.08, 0.50, 0.92], "y": [0.12, 0.88, 0.12]},  # V: o escudo
	{"x": [0.12, 0.12, 0.88], "y": [0.88, 0.12, 0.12]},  # Γ: a espada
	{"x": [0.88, 0.88, 0.12], "y": [0.88, 0.12, 0.12]},  # Γ espelhado: a espada
]
const FORMAS := ["elmo", "escudo", "espada", "espada"]
## Os roteiros: [o que a mão faz, a batida a partir do começo da peça, o ponto da letra].
const PRIMEIRA := [["ponto", 0.0, 0], ["ponto", 1.0, 1], ["ponto", 2.0, 2], ["carimbo", 3.0, -1], ["abre", 4.0, -1], ["fecha", 6.0, -1]]
const PECA := [["ponto", 0.0, 0], ["ponto", 1.0, 1], ["ponto", 2.0, 2], ["carimbo", 3.0, -1]]
const FORNADA := [["ponto", 0.0, 0], ["ponto", 1.0, 2], ["carimbo", 2.0, -1]]
const SIMPLES := [["ponto", 0.0, 0], ["ponto", 2.0, 1], ["ponto", 4.0, 2], ["carimbo", 6.0, -1]]
const TAMANHOS := {"PRIMEIRA": 8.0, "PECA": 4.0, "FORNADA": 3.0, "SIMPLES": 8.0}
const RAIO_PONTO := 0.09
const ABERTO := 0.45
const FECHADO := 0.15
const PONTOS := [0, 20, 35, 50]
const INTEIRA := 100
const TORTA := 50
const ALVO_ENERGIA := 2.0
const ALVO_ACERTO := 2.6
## A queda (o Fôlego) depois do erro, em tempos (docs/jogo/sistemas/minigames.csv: 1).
const QUEDA_TEMPOS := 1.0
const ESTANTE_Z := -1.6
## Os quatro carimbos a menos disto uns dos outros são o desmolde dos quatro (a vibração do coro).
const CORO_S := 0.4

var j := {}
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
var coro := {"t": -99.0, "n": 0}


func montar() -> void:
	SECAO.montar(self, CAMERA_POS, CAMERA_OLHAR)
	var sulco := Kit.material(Tema.FITA, 0.0, 0.9)
	for p in jogadores:
		var l: int = p.lugar
		var nos := SECAO.bancada(self, l)
		var placa: Node3D = nos.placa
		var sulcos: Array = []
		for k in 2:
			sulcos.append(Kit.caixa(placa, Vector3(0.07, 0.02, 1.0), Vector3.ZERO, sulco))
		var pontos_nos: Array = []
		for k in 3:
			var disco := SECAO.disco8(placa, 0.07, 0.03, Vector3.ZERO, sulco)
			var rotulo := Label3D.new()
			rotulo.text = str(k + 1)
			rotulo.font = Tema.archivo(700)
			rotulo.font_size = 56
			rotulo.pixel_size = 0.004
			rotulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			rotulo.outline_size = 12
			rotulo.outline_modulate = Color(Tema.FITA, 0.9)
			rotulo.modulate = Tema.MUDO
			placa.add_child(rotulo)
			pontos_nos.append({"disco": disco, "rotulo": rotulo})
		nos["sulcos"] = sulcos
		nos["pontos"] = pontos_nos
		nos["sulco"] = sulco
		nos["alvo_mat"] = Tema.neon(Tema.JOGADOR[l], ALVO_ENERGIA, l)
		nos["alvo"] = SECAO.anel8(placa, 0.17, Vector3.ZERO, nos.alvo_mat)
		nos["prox"] = SECAO.disco8(placa, 0.07, 0.035, Vector3.ZERO, nos.alvo_mat)
		nos["aceso"] = Tema.neon(Tema.JOGADOR[l], 1.4, l)
		nos["torta_mat"] = Kit.material(Tema.OXIDO, 0.0, 0.8)
		var dourada := Kit.material(Tema.SECAO[3], 0.0, 0.5)
		dourada.metallic = 0.15
		Tema.emissivo(dourada, 1.2, "forja")
		nos["dourada"] = dourada
		Kit.peca(self, "wood-structure", Vector3(float(nos.cx), 0, ESTANTE_Z), 0.0, 1.2)
		p.position = Vector3(RAIAS[l] - 1.45, 0.05, 0.35)
		p.rotation.y = PI * 0.5
		martelo_na_mao(p)
		j[l] = {"n": 0, "s": -1.0, "tam": 8.0, "roteiro": [], "passo": 0, "letra": 0, "prox_letra": -1,
			"feitos": 0, "torta": false, "armada": false, "aberto_ate": -99.0, "valor": 0.0, "inteiras": 0,
			"tortas": 0, "volta": 0, "antes": false, "aberta": false, "calado_ate": -99.0, "acerto_q": 0,
			"fora": false, "nos": nos, "estante": 0, "robo_n": -1, "robo_mira": 0.0, "robo_feito": false}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


func iniciar_jogo() -> void:
	for l in presentes():
		if not Forja.capacidade(l, "toque"):
			anotar("entrada", l, {"o": "sensores", "toque": false})
			acabou[l] = true
			continue
		_nova_peca(l, BATIDA_DA_PRIMEIRA_NOTA)


## O roteiro da peça que começa na batida `s`: a primeira de cada um abre e
## fecha (a bancada); na partitura simples, a de 8 tempos; no terço do meio da
## música, a fornada; fora dele, a de 4 tempos. Decide pela batida, não pelo agora.
func _roteiro_em(l: int, s: float) -> String:
	if int(j[l].volta) == 0:
		return "PRIMEIRA"
	if Ritmo.simples[l]:
		return "SIMPLES"
	var u := Ritmo.t_da_batida(s) / duracao
	if u >= 1.0 / 3.0 and u < 2.0 / 3.0:
		return "FORNADA"
	return "PECA"


## Uma peça nova do lugar, começando na batida `s`. Fora da fornada, a peça
## começa no primeiro tempo de um compasso (o coro: os quatro no mesmo tempo 1).
## A letra é a que o disco `prox` já mostrava; a seguinte se sorteia agora.
func _nova_peca(l: int, s: float) -> void:
	var e: Dictionary = j[l]
	var nome := _roteiro_em(l, s)
	if nome != "FORNADA":
		s = 4.0 * ceilf(s / 4.0 - 0.001)
		nome = _roteiro_em(l, s)
	e.s = s
	e.roteiro = get(nome)
	e.tam = float(TAMANHOS[nome])
	e.passo = 0
	e.letra = int(e.prox_letra) if int(e.prox_letra) >= 0 else rng.randi_range(0, LETRAS.size() - 1)
	e.prox_letra = rng.randi_range(0, LETRAS.size() - 1)
	var seguinte: Dictionary = LETRAS[int(e.prox_letra)]
	(e.nos.prox as MeshInstance3D).position = SECAO.no_molde(seguinte.x[0], seguinte.y[0], 0.12)
	e.feitos = 0
	e.torta = false
	_desenhar_a_letra(l)
	_armar(l)


## A batida de um passo da peça.
func _batida_do_passo(e: Dictionary, i: int) -> float:
	return float(e.s) + float(e.roteiro[i][1])


## A nota do passo da vez: no registro e no pedido às medidas do núcleo. O passo
## que cai dentro da queda (o Fôlego, depois de um erro) sai calado: sem nota.
func _armar(l: int) -> void:
	var e: Dictionary = j[l]
	var passo: Array = e.roteiro[int(e.passo)]
	e.aberta = false
	e.antes = false
	e.armada = _batida_do_passo(e, int(e.passo)) >= float(e.calado_ate)
	if not bool(e.armada):
		return
	match str(passo[0]):
		"carimbo":
			Forja.med_pedir(l, "clique")
		"abre":
			Forja.med_pedir(l, "dois_dedos")
	nova_nota(l, int(e.n), Ritmo.t_da_batida(_batida_do_passo(e, int(e.passo))))


func jogar(_dt: float) -> void:
	SECAO.pico(self)
	var agora := Ritmo.t_musica()
	for l in presentes():
		var e: Dictionary = j[l]
		SECAO.mostrar_dedos(self, l, e.nos)
		_mostrar(l)
		if acabou[l] or e.roteiro.is_empty():
			continue
		if not conectado(l):
			e.fora = true
			continue
		if bool(e.fora):
			e.fora = false
			_nova_peca(l, Ritmo.batida() + 0.01)
		_nota(l, e, agora)


func _dedos(l: int) -> Array:
	return [Forja.dedo(l, 0), Forja.dedo(l, 1)]


func _condicao(l: int, e: Dictionary, o: String) -> bool:
	var d := _dedos(l)
	var dois: bool = d[0].z > 0.5 and d[1].z > 0.5
	match o:
		"ponto":
			var letra: Dictionary = LETRAS[int(e.letra)]
			var i := int(e.roteiro[int(e.passo)][2])
			var alvo := Vector2(letra.x[i], letra.y[i])
			for k in 2:
				if d[k].z > 0.5 and SECAO.distancia(Vector2(d[k].x, d[k].y), alvo) < RAIO_PONTO:
					return true
			return false
		"carimbo":
			return Forja.apertou(l, Forja.TOUCHPAD)
		"abre":
			return dois and SECAO.distancia(Vector2(d[0].x, d[0].y), Vector2(d[1].x, d[1].y)) >= ABERTO
		"fecha":
			return dois and SECAO.distancia(Vector2(d[0].x, d[0].y), Vector2(d[1].x, d[1].y)) <= FECHADO
	return false


func _nota(l: int, e: Dictionary, agora: float) -> void:
	var passo: Array = e.roteiro[int(e.passo)]
	var o := str(passo[0])
	var alvo := Ritmo.t_da_batida(_batida_do_passo(e, int(e.passo)))
	if not bool(e.armada):
		# a queda: o passo passa calado, sem nota e sem erro
		if agora >= alvo:
			_avancar(l)
		return
	var d := _dedos(l)
	if o == "ponto" and (d[0].z > 0.5 or d[1].z > 0.5):
		SECAO.textura(l, "pedra")
	var sim := _condicao(l, e, o)
	if agora < alvo - 0.5 * 60.0 / Ritmo.bpm:
		e.antes = sim
		return
	var cruzou := sim and (not bool(e.antes) or not bool(e.aberta))
	e.aberta = true
	e.antes = sim
	if cruzou:
		anotar("entrada", l, {"o": "touchpad", "passo": o, "d0": [snappedf(d[0].x, 0.01), snappedf(d[0].y, 0.01)],
			"d1": [snappedf(d[1].x, 0.01), snappedf(d[1].y, 0.01)], "dedos": int(d[0].z > 0.5) + int(d[1].z > 0.5), "n": int(e.n)})
		julgar_toque(l, alvo, int(e.n))
	elif agora > alvo + FOLGA_PERDIDA:
		var n_antes := int(e.n)
		nota_perdida(l, n_antes)  # chama falha(), que avança
		if int(e.n) == n_antes:  # o Escudo absorveu o erro e falha() não veio: avança sem entortar
			_avancar(l)


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	var placa: Node3D = nos.placa
	marcar(l, PONTOS[julgamento])
	var passo: Array = e.roteiro[int(e.passo)]
	var p := jogador(l)
	e.acerto_q = 4  # o alvo a 2,6 por 4 quadros
	match str(passo[0]):
		"ponto":
			var letra: Dictionary = LETRAS[int(e.letra)]
			var i := int(passo[2])
			var onde := placa.to_global(SECAO.no_molde(letra.x[i], letra.y[i], 0.14))
			Efeitos.faiscas(self, onde, Tema.JOGADOR[l], 10, 0.6)
			Som.tocar("tique", onde, -4.0, 1.0 + 0.08 * int(e.feitos))
			e.feitos = int(e.feitos) + 1
			if int(e.feitos) == 3:
				Forja.med_tracou(l)
			if julgamento != Ritmo.PERFEITO:
				Forja.som_falante(l, "clique", 0.4)
		"carimbo":
			var centro := placa.to_global(SECAO.no_molde(0.5, 0.5, 0.16))
			Efeitos.faiscas(self, centro, Tema.JOGADOR[l], 12, 1.0)
			Som.tocar("carimbo", centro, 0.0)
			if julgamento != Ritmo.PERFEITO:
				Som.no_controle(l, "carimbo", 0.6)
			if p:
				p.gesto("attack-melee-right", 0.45)
		"abre":
			e.aberto_ate = 99999.0
			Som.tocar("sopro", placa.global_position, -2.0)
			if p:
				p.gesto("interact-right", 0.4)
		"fecha":
			e.aberto_ate = -99.0
			Forja.sentir(l, "golpe")  # o molde fecha
			Som.tocar("bigorna", placa.global_position, -8.0)
	_avancar(l)


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	var e: Dictionary = j[l]
	e.torta = true
	e.calado_ate = Ritmo.batida() + SECAO.queda(l, QUEDA_TEMPOS)
	var placa: Node3D = e.nos.placa
	Efeitos.faiscas(self, placa.to_global(SECAO.no_molde(0.5, 1.0, 0.1)), Tema.TUNGSTENIO, 24, 0.6)
	_avancar(l)


## O passo seguinte. O `n` só sobe quando o passo teve nota (os calados não gravam).
func _avancar(l: int) -> void:
	var e: Dictionary = j[l]
	if bool(e.armada):
		e.n = int(e.n) + 1
	e.passo = int(e.passo) + 1
	if int(e.passo) < e.roteiro.size():
		_armar(l)
		return
	_desmolde(l)
	_nova_peca(l, float(e.s) + float(e.tam))


## A peça sai do molde: o molde abre 1 batida (sozinho) e a peça salta para a
## estante. A inteira canta (golpe); a torta entorta no ar e cai com som de
## lata (estrondo). Uma linha `momento` `desmolde` por peça.
func _desmolde(l: int) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	var placa: Node3D = nos.placa
	e.volta = int(e.volta) + 1
	e.aberto_ate = Ritmo.batida() + 1.0
	if treinando:
		return
	var torta := bool(e.torta)
	var dourada := not torta and SECAO.na_reta(self)
	var forma: String = FORMAS[int(e.letra)]
	var k := int(e.estante)
	e.estante = k + 1
	var ate := Vector3(float(nos.cx) - 0.75 + 0.5 * (k % 4), 0.95 + 0.4 * int(k / 4.0), ESTANTE_Z)
	var mat: Material = nos.torta_mat if torta else (nos.dourada if dourada else nos.pronta)
	var peca := _peca(forma, torta, mat)
	add_child(peca)
	peca.global_position = placa.to_global(SECAO.no_molde(0.5, 0.5, 0.2))
	var meio := (peca.global_position + ate) * 0.5 + Vector3(0, 1.4, 0)
	var batida := 60.0 / Ritmo.bpm
	var tw := peca.create_tween()
	tw.tween_property(peca, "global_position", meio, batida * 0.5).set_ease(Tween.EASE_OUT)
	tw.tween_property(peca, "global_position", ate, batida * 0.5).set_ease(Tween.EASE_IN)
	if torta:
		e.tortas = int(e.tortas) + 1
		e.valor = float(e.valor) + 0.5
		marcar(l, TORTA)
		tw.parallel().tween_property(peca, "rotation:z", deg_to_rad(-35.0), batida)
		Som.tocar("falha", ate, -4.0)
		SECAO.degrau(self, l, "estrondo", ate, Tema.TUNGSTENIO)
		var p := jogador(l)
		if p:
			p.gesto("emote-no", 0.5)
	else:
		e.inteiras = int(e.inteiras) + 1
		e.valor = float(e.valor) + (2.0 if dourada else 1.0)
		marcar(l, INTEIRA * (2 if dourada else 1))
		Som.tocar("bigorna", ate, -2.0)
		if dourada:
			Som.tocar("sucesso", ate, -6.0)
		SECAO.degrau(self, l, "golpe", ate, Tema.JOGADOR[l])
		peca.scale = Vector3.ONE * 1.3
		tw.parallel().tween_property(peca, "scale", Vector3.ONE, batida * 0.5)
	momento("desmolde", l, ate, 0.5, {"torta": torta, "forma": forma, "dourada": dourada})
	_coro()


## O desmolde dos quatro: quando todos os presentes desmoldam a menos de 0,4 s
## do primeiro, os controles dos quatro sentem o par (forte, pausa, fraco), uma vez.
func _coro() -> void:
	var agora := Ritmo.t_musica()
	if agora - float(coro.t) > CORO_S:
		coro.t = agora
		coro.n = 0
	coro.n = int(coro.n) + 1
	var vivos := presentes().filter(func(x): return not acabou[x] and conectado(x))
	if int(coro.n) != vivos.size() or vivos.size() < 2:
		return
	for x in vivos:
		Forja.vibrar(x, 1.0, 0.6, 120)
	await get_tree().create_timer(0.12).timeout
	for x in vivos:
		Forja.vibrar(x, 0.7, 0.4, 120)


## A peça pronta, de caixas: a espada (lâmina e guarda), o escudo, o elmo. A
## torta tem forma: a espada em S, o escudo dobrado, o elmo achatado.
func _peca(forma: String, torta: bool, mat: Material) -> Node3D:
	var n := Node3D.new()
	match forma:
		"espada":
			for s in 3:
				var lamina := Kit.caixa(n, Vector3(0.08, 0.04, 0.24), Vector3(0, 0, -0.24 * (s - 1)), mat)
				if torta:
					lamina.rotation.y = deg_to_rad(25.0 * (1 - s))
					lamina.position.x = 0.08 * (1 - s)
			Kit.caixa(n, Vector3(0.3, 0.05, 0.06), Vector3(0, 0, 0.38), mat)
		"escudo":
			var a := Kit.caixa(n, Vector3(0.24, 0.06, 0.5), Vector3(-0.12, 0, 0), mat)
			var b := Kit.caixa(n, Vector3(0.24, 0.06, 0.5), Vector3(0.12, 0, 0), mat)
			if torta:
				a.rotation.z = deg_to_rad(35.0)
				a.position.y = 0.07
				b.rotation.z = deg_to_rad(-10.0)
		"elmo":
			Kit.caixa(n, Vector3(0.36, 0.3, 0.36), Vector3(0, 0.15, 0), mat)
			Kit.caixa(n, Vector3(0.3, 0.06, 0.04), Vector3(0, 0.18, 0.19), Kit.material(Tema.FITA, 0.0, 0.9))
			if torta:
				n.scale = Vector3(1.3, 0.3, 1.3)
	return n


## A letra da peça nova na placa: os sulcos entre os pontos e os pontos numerados.
func _desenhar_a_letra(l: int) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	var letra: Dictionary = LETRAS[int(e.letra)]
	for k in 2:
		var a := SECAO.no_molde(letra.x[k], letra.y[k], 0.108)
		var b := SECAO.no_molde(letra.x[k + 1], letra.y[k + 1], 0.108)
		var s: MeshInstance3D = nos.sulcos[k]
		s.position = (a + b) * 0.5
		s.rotation.y = atan2(b.x - a.x, b.z - a.z)
		s.scale = Vector3(1, 1, a.distance_to(b))
	for k in 3:
		var c := SECAO.no_molde(letra.x[k], letra.y[k], 0.11)
		var pt: Dictionary = nos.pontos[k]
		(pt.disco as MeshInstance3D).position = c
		(pt.rotulo as Label3D).position = c + Vector3(0, 0.2, -0.14)


## A cada quadro: o ponto aceso 1 aviso antes da nota dele (o dedo segue a luz),
## o alvo da vez, o primeiro ponto da próxima peça, o metal que brilha na batida
## do carimbo e esfria na torta, e as metades que abrem.
func _mostrar(l: int) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	var em_jogo := fase == "jogo" and not acabou[l] and not e.roteiro.is_empty()
	var agora := Ritmo.t_musica()
	var aviso := SECAO.aviso_s(l)
	var letra: Dictionary = LETRAS[int(e.letra)]
	var passo_i := mini(int(e.passo), e.roteiro.size() - 1) if em_jogo else 0
	for k in 3:
		var pt: Dictionary = nos.pontos[k]
		var disco: MeshInstance3D = pt.disco
		disco.visible = em_jogo
		var aceso := false
		var feito := false
		for i in e.roteiro.size():
			if str(e.roteiro[i][0]) == "ponto" and int(e.roteiro[i][2]) == k:
				feito = i < int(e.passo)
				aceso = not feito and agora >= Ritmo.t_da_batida(_batida_do_passo(e, i)) - aviso
		disco.material_override = nos.pronta if feito else (nos.aceso if aceso else nos.sulco)
		(pt.rotulo as Label3D).visible = em_jogo and (aceso or feito)
		(pt.rotulo as Label3D).modulate = Tema.ETIQUETA if feito else Tema.MUDO
	for k in 2:
		(nos.sulcos[k] as MeshInstance3D).visible = em_jogo
	var alvo: MeshInstance3D = nos.alvo
	var o := str(e.roteiro[passo_i][0]) if em_jogo else ""
	alvo.visible = em_jogo and o == "ponto" and agora >= Ritmo.t_da_batida(_batida_do_passo(e, passo_i)) - aviso
	if alvo.visible:
		var i := int(e.roteiro[passo_i][2])
		alvo.position = SECAO.no_molde(letra.x[i], letra.y[i], 0.13)
		alvo.scale = Vector3.ONE * (0.92 + 0.1 * sin(Ritmo.batida() * TAU))
	var energia := ALVO_ACERTO if int(e.acerto_q) > 0 else ALVO_ENERGIA
	e.acerto_q = maxi(0, int(e.acerto_q) - 1)
	Tema.emissivo(nos.alvo_mat, energia, l)
	# o primeiro ponto da próxima peça acende 1 aviso antes dela, enquanto a vez é o carimbo
	var prox: MeshInstance3D = nos.prox
	var fim := float(e.s) + float(e.tam)
	prox.visible = em_jogo and o == "carimbo" and agora >= Ritmo.t_da_batida(fim) - aviso
	# o metal brilha na batida do carimbo e esfria na peça torta
	var quente := 0.0
	if em_jogo:
		for i in e.roteiro.size():
			if str(e.roteiro[i][0]) == "carimbo":
				quente = clampf(1.0 - absf(Ritmo.batida() - _batida_do_passo(e, i)), 0.0, 1.0)
		if bool(e.torta):
			quente = 0.0
	var metal: StandardMaterial3D = nos.metal
	metal.albedo_color = Tema.OXIDO.lerp(Tema.OXIDO_BRILHO, quente)
	Tema.emissivo(metal, lerpf(0.3, 2.4, quente), "forja")
	# as metades se afastam 0,3 m enquanto o molde está aberto
	var meio := 0.3 if Ritmo.batida() < float(e.aberto_ate) else 0.0
	for k in nos.metades.size():
		var metade: Node3D = nos.metades[k]
		metade.position.x = lerpf(metade.position.x, meio * (-1.0 if k == 0 else 1.0), 0.2)


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(_antes)
	return lista


func _antes(a: int, b: int) -> bool:
	if float(j[a].valor) != float(j[b].valor):
		return float(j[a].valor) > float(j[b].valor)
	if int(pontos[a]) != int(pontos[b]):
		return int(pontos[a]) > int(pontos[b])
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		var v := float(j[lugar].valor)
		return "Peças: %d,5" % int(v) if v - floorf(v) > 0.25 else "Peças: %d" % int(v)
	return super(lugar)
```

### `godot/scripts/minigames/catalogo.gd`

Tire `"molde"` de `SALAS_ANTIGAS`. Em `MINIGAMES`: `"S03_J11": preload("res://scripts/minigames/s03/o_molde.gd"),`.
Na S03 de `SECOES`: `"minigames": ["S03_J11"]`. Depois:
`git rm godot/scripts/salas/molde.gd godot/scripts/salas/molde.gd.uid`.

### `godot/scripts/traducoes.gd`

`"Molde!": "Mold it!"` (o título `"O Molde"` já existe). Em `EN_PADROES`, nesta ordem:
`["^Peças: (\\d+),5$", "Pieces: $1.5"]` e `["^Peças: (\\d+)$", "Pieces: $1"]`. A linha velha
`"Trace, abra e carimbe o molde."` sai junto com a sala.

## Como se joga

- **A faixa:** `mus_s03_j11`, 122 BPM, Dó menor. Até a H05, a sintetizada da seção a 100 bpm (0,6 s por tempo).
- **Os quatro juntos, como um coro.** Não há hoqueto: os quatro traçam no mesmo tempo, cada um com a sua nota (o
  kit), e o carimbo dos quatro cai na mesma batida. É a exceção da seção.
- **A primeira peça de cada um** (8 tempos, da batida 4 à 12): em `S+0`, `S+1` e `S+2`, o dedo chega aos pontos 1,
  2 e 3 da letra; em `S+3`, o clique do touchpad carimba; em `S+4`, dois dedos abrem (a distância passa de 0,45 da
  largura); em `S+6`, os dois fecham (abaixo de 0,15) e a peça sai do molde. É a que a bancada mede.
- **A peça** (4 tempos, depois da primeira, de 0 a 30 s e de 60 s ao fim): os três pontos em `S+0`, `S+1` e `S+2`,
  e o carimbo em `S+3`. O molde abre sozinho no carimbo, por 1 batida. `S` é sempre o tempo 1 de um compasso.
- **A fornada** (3 tempos, de 30 a 60 s, o terço do meio da música): o ponto 1 em `S+0`, o ponto 3 pelo sulco reto
  em `S+1` e o carimbo em `S+2`. O desmolde cai a cada 3 tempos, contra o compasso de 4: o mundo muda de pulso.
- **A partitura simples** (`Ritmo.simples[l]`): a peça de 8 tempos, uma nota a cada 2 tempos, sem abrir e fechar.
- **As letras** (sorteadas pela semente a cada peça; cada uma leva o dedo de um canto a outro do touchpad):
  - Λ: `x [0,08; 0,50; 0,92]`, `y [0,88; 0,12; 0,88]`;
  - V: `x [0,08; 0,50; 0,92]`, `y [0,12; 0,88; 0,12]`;
  - Γ: `x [0,12; 0,12; 0,88]`, `y [0,88; 0,12; 0,12]`;
  - o Γ espelhado: `x [0,88; 0,88; 0,12]`, `y [0,88; 0,12; 0,12]`.
  O ponto conta com qualquer dedo a menos de 0,09 da largura dele.
- **O julgamento, no cruzamento** (o dedo entra no ponto, o clique, a distância passa do limiar), dentro da janela
  que abre meio tempo antes. As janelas são as do Ritmo: Ressonância de −40 a +60 ms, ótimo ±90 ms, bom ±140 ms.
  Nada até `FOLGA_PERDIDA` (140 ms) depois: nota perdida.
- **A peça inteira** teve todas as notas sem erro. Com um erro, ela sai **torta**.
- **Os pontos** por julgamento (erro, bom, ótimo, Ressonância): `[0, 20, 35, 50]`. A inteira, +100 (+200 na reta);
  a torta, +50.
- **O placar** (`valor`): a inteira vale 1 e a torta, 0,5. Nas últimas 16 batidas, a inteira vale 2 e sai dourada.
- **O fim** é do kit, em tempo de música (H08): os 90 s contam em `Ritmo.t_musica()`.
- **O vencedor:** o maior `valor`; no empate, os pontos; depois, o lugar.
- **Com menos de quatro:** nada muda. **O controle que cai:** a peça dele para, sem erro; ao voltar, uma peça nova
  começa no próximo tempo 1. **Sem touchpad** (`Forja.capacidade(l, "toque")` falso): o lugar acaba no
  `iniciar_jogo()`, sem erro, grava `entrada` `sensores` `toque: false`, e o veredito da bancada diz "não medido".

### O robô

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var e: Dictionary = j[l]
	if e.roteiro.is_empty():
		return
	if int(e.robo_n) != int(e.n):
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado
		e.robo_n = int(e.n)
		e.robo_mira = 0.0 if Forja.robo_acerta() else 0.20
		e.robo_feito = false
	var i := int(e.passo)
	var passo: Array = e.roteiro[i]
	var quando := Ritmo.t_da_batida(_batida_do_passo(e, i)) + float(e.robo_mira)
	var agora := Ritmo.t_musica()
	var letra: Dictionary = LETRAS[int(e.letra)]
	match str(passo[0]):
		"ponto":
			var k := int(passo[2])
			var ate := Vector2(letra.x[k], letra.y[k])
			if i == 0:
				if agora >= quando:  # encosta no primeiro ponto na nota
					Forja.robo_tocar(l, 0, ate.x, ate.y, 0.06)
				return
			# desliza pelo sulco nos 250 ms antes da nota e chega nela
			var k0 := int(e.roteiro[i - 1][2])
			var de := Vector2(letra.x[k0], letra.y[k0])
			var pos := de.lerp(ate, clampf((agora - (quando - 0.25)) / 0.25, 0.0, 1.0))
			Forja.robo_tocar(l, 0, pos.x, pos.y, 0.06)
		"carimbo":
			if not bool(e.robo_feito) and agora >= quando:
				Forja.robo_apertar(l, Forja.TOUCHPAD, 0.05)
				e.robo_feito = true
		"abre":
			if agora >= quando - 0.2:
				var s := lerpf(0.05, 0.30, clampf((agora - (quando - 0.2)) / 0.27, 0.0, 1.0))
				Forja.robo_tocar(l, 0, 0.5 - s, 0.5, 0.06)
				Forja.robo_tocar(l, 1, 0.5 + s, 0.5, 0.06)
		"fecha":
			var s2 := 0.30
			if agora >= quando - 0.2:
				s2 = lerpf(0.30, 0.03, clampf((agora - (quando - 0.2)) / 0.27, 0.0, 1.0))
			Forja.robo_tocar(l, 0, 0.5 - s2, 0.5, 0.06)
			Forja.robo_tocar(l, 1, 0.5 + s2, 0.5, 0.06)
```

Entre o último ponto e o carimbo, e entre o carimbo e o abrir, o robô não toca: os dedos sobem sozinhos.

## A cena

- **A câmera:** fixa (`"camera": "fixa"`), com a lente da arena (35 mm, 37,8°, o fov do main pela G05) e plongée de
  50°: `camera_pos = Vector3(0.2, 11.2, 8.4)`, `camera_olhar = Vector3(0.2, 0.9, -0.3)`. Não corta durante o jogo.
  **No pico** (o terço do meio), ela recua 10 % (`pos = olhar + (pos − olhar) × 1,1`) em 1 batida e volta em 2
  (`SECAO.pico`).
- **A luz:** petróleo, a da S03 lado A (`Tema.luz_da_secao("S03", "A")`: a névoa `#011311`, o preenchimento
  `#11413b` e a chave `#e5d7ad`). A chave é um OmniLight3D em (0; 7,5; 5,0), com energia 1,4 e alcance 26. No pico,
  a chave vai a ×1,2 e a névoa a ×0,8. A névoa do main volta como estava quando a sala sai. O neon do ar é
  `Tema.VIOLETA` (`atmosfera(preenchimento, VIOLETA, false, 50)`). Cada bancada tem a sua luz de tungstênio
  (`TUNGSTENIO`, energia 0,8, alcance 4,5, em `(cx; 2,4; 1,2)`).
- **O fundo (as peças Kenney, pelo `SECAO.peca`):**
  - `survival-kit/workbench` em (−9,5; 0; −6,0) e em (9,5; 0; −6,0), girada 180°: as bancadas vizinhas (reserva:
    `table`);
  - `factory-kit/machine-bed` em (0; 0; −8,0): a forja do fundo (reserva: `barrel`);
  - `survival-kit/barrel` em (±10,6; 0; 2,0): os barris da água de têmpera (reserva: `barrel`);
  - `wood-structure` (o mini-dungeon que já está em `godot/assets/kenney`, pelo `Kit.peca` direto), escala 1,2, em
    `(cx; 0; −1,6)`: a estante de cada um.
- **A bancada** (`SECAO.bancada`): o corpo em `CASCO_ALTO`, o tampo em `GRAFITE` e a placa de 2,4 × 1,2 m (o
  touchpad, 2:1) em `(cx; 1,12; 0,3)`, com `cx = RAIAS[l] + 0,45`, inclinada 40°: o dedo aparece onde o jogo o vê.
  As duas metades do molde em pedra `GRAFITE`. O metal no fundo é `OXIDO`, que vai a `OXIDO_BRILHO`, com emissão de
  0,3 a 2,4 (dono `"forja"`, tungstênio) no pico da batida do carimbo; na peça torta, esfria a 0,3.
- **A letra:** os dois sulcos (`Kit.caixa` de 0,07 × 0,02 × o comprimento) e os três pontos (`disco8`, raio 0,07),
  em `FITA`. O número de cada ponto vai num `Label3D` (Archivo 700, 56 px, `MUDO`, contorno `FITA`), visível só
  quando aceso.
- **O que brilha e de quem é:**
  - o ponto aceso: o neon do jogador a 1,4 (dono `l`);
  - o alvo da vez (`anel8`, raio 0,17): o neon do jogador a 2,0, e 2,6 por 4 quadros no acerto;
  - o primeiro ponto da próxima peça: o mesmo neon, a 2,0;
  - os dois dedos: o neon do jogador a 1,8 e a 1,2;
  - o metal: o tungstênio da forja. Nada mais brilha.
- **As peças prontas:** mostarda `SECAO[3]`, sem emissão, metallic 0,15. A dourada (as últimas 16 batidas): a mesma
  mostarda com emissão 1,2 (dono `"forja"`). A torta: `OXIDO`, sem emissão. Na estante, 4 por prateleira:
  `(cx − 0,75 + 0,5·(k % 4); 0,95 + 0,4·⌊k/4⌋; −1,6)`.
- **A forma de cada peça** (pela letra): Λ é o elmo (caixa de 0,36 × 0,3 × 0,36 e a viseira em `FITA`); V é o
  escudo (duas metades de 0,24 × 0,06 × 0,5); Γ e o Γ espelhado são a espada (três trechos de lâmina de 0,08 ×
  0,04 × 0,24 e a guarda de 0,3). **A torta:** a espada em S (os trechos girados +25°, 0° e −25°), o escudo dobrado
  (a metade esquerda girada 35° e erguida 0,07 m) e o elmo achatado (escala 1,3 × 0,3 × 1,3).
- **O ferreiro:** o cavaleiro do lugar em `(RAIAS[l] − 1,45; 0,05; 0,35)`, de perfil (`rotation.y = PI/2`), com o
  martelo na mão direita (`martelo_na_mao`).
- **Nada liso:** discos e anéis de 8 lados; nunca `Efeitos.anel` (o toro liso).
- **Nenhuma cor fora do tema:** nenhuma cor escrita em hexadecimal no arquivo. O erro não tem cor própria: as faíscas da falha são
  `TUNGSTENIO`.

## O som

Os ids são os do [mapa do áudio](../o-time/o-mapa-do-audio.md); o nome curto é o que `Som.tocar` recebe.

| evento | na TV | no controle do dono |
| --- | --- | --- |
| cada ponto acertado | `tique` (`tique_0..2`, `sint_tique`), −4 dB, com o tom subindo 8 % por ponto | Ressonância: a nota (o kit); bom e ótimo: `Forja.som_falante(l, "clique", 0.4)` (`mod_clique`) |
| o clique carimba | `carimbo` (`carimbo_0..4`, `sint_carimbo`), 0 dB | Ressonância: a nota (o kit); bom e ótimo: `Som.no_controle(l, "carimbo", 0.6)` |
| o abrir (só na primeira peça) | `sopro` (`sint_sopro`), −2 dB | — |
| o fechar (só na primeira peça) | `bigorna` (`sint_bigorna`), −8 dB | — |
| o desmolde da peça inteira | `bigorna`, −2 dB (o metal canta); na dourada, mais `sucesso` (`vitoria_sala_0..1`, `sint_sucesso`), −6 dB | — |
| o desmolde da peça torta | `falha` (vira `fx_tropeco_0..2` pelo mapa), −4 dB: a lata | — |
| o erro | a nota quebrada (o kit) | a nota quebrada (o kit) |

**A faixa:** `mus_s03_j11` (122 BPM, Dó menor, a fazer); até a H05, a sintetizada da seção a 100 bpm. A seção pede
os tempos 1 e 3 pesados: o carimbo da peça de 4 tempos cai no 4, a resposta ao peso.

## O controle

| evento | vibração | háptica e alto-falante | luz | gatilho | para os outros |
| --- | --- | --- | --- | --- | --- |
| o dedo traçando | — | a textura `pedra` nos atuadores, no máximo a cada quarto de tempo (`SECAO.textura(l, "pedra")`); no rádio, nada | — | R2 Off (`Forja.gatilho(l, 1, Forja.GATILHO_OFF)`) | nada |
| o ponto acerta | o kit: acerto 0,3/0,6/80 ms; Ressonância 0,5/0,8/100 ms | o clique (`mod_clique`) a 0,4, ou a nota no perfeito | o kit: branco no perfeito | — | nada |
| o carimbo | o kit | `carimbo` a 0,6 no alto-falante | o kit | — | nada |
| o molde fecha (primeira peça) | `Forja.sentir(l, "golpe")`: 1,0/0,6/250 ms | — | — | — | nada |
| o desmolde dos quatro (todos desmoldam a menos de 0,4 s) | nos quatro: `Forja.vibrar(l, 1.0, 0.6, 120)`, pausa de 120 ms, `Forja.vibrar(l, 0.7, 0.4, 120)` (`_coro`) | — | — | — | é para todos |
| o erro | o kit: 0,7/0,3/160 ms | a nota quebrada | o kit: a cor do lugar escurecida | — | nada |

**Sem o controle na mão:** o robô toca e clica pelo `Forja.robo_tocar` e pelo `Forja.robo_apertar`; a prova lê cada
sensação no registro (a linha `sensacao`, F05) e a `saida` de vibração com `seq` e `ok` (F06).

**O que espera ela** (o ESPERA-ELA do quadro): no Linux, o touchpad também vira mouse; a regra udev
`LIBINPUT_IGNORE_DEVICE=1` pede o sudo dela. Esta ficha não depende da regra: o jogo lê o touchpad pelo SDL e o
cursor que anda junto não atrapalha a tela de jogo. Quando a regra entrar, nada muda aqui. A onda própria do tique
(150 Hz, 12 ms) é do diretor de som; até ela ter id no mapa, o tique da textura é `Forja.sentir(l, "toque")`
(0/0,45/60 ms). O gatilho fica Off; a emenda do gatilho (SLOPE, MULTIPLE) não se usa.

## O cavaleiro

O cavaleiro é o da montagem (G13): a cabeça, a parte de cima e a de baixo que a pessoa escolheu aparecem como estão.
O `martelo_na_mao` troca só a mão direita durante o minigame (o ferreiro trabalha de martelo); o resto da montagem
fica inteiro. O cavaleiro pode ser de outra raça (G13): esta ficha usa só o esqueleto comum e as animações
`attack-melee-right`, `interact-right` e `emote-no`.

| stat | gancho | o que muda n'O Molde | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | não age: ninguém é empurrado | — | — | — |
| Passo | `velocidade` | não age: o ferreiro não anda | — | — | — |
| Fôlego | `levantar` | a queda depois do erro: os passos da peça que caem antes de `falha + 1 tempo × levantar` saem calados (sem nota e sem erro) | 1,25 tempo | 1 tempo | 0,75 tempo |
| Faro | `pista` | o ponto acende antes; a nota cai no mesmo tempo | −40 ms | 0 | +40 ms |

Os itens: o Martelo (o perfeito no tempo forte vale o dobro) e o Escudo (absorve o primeiro erro) são do kit. A
Lanterna adianta o aviso em meio tempo (`Itens.antecipacao_s`, dentro de `SECAO.aviso_s`). Nenhum stat muda a janela
de julgamento em mais de 15 ms (aqui, em nenhum).

## As reações

- **Carimbos que O Molde pode disparar** (todos do kit e do HUD, G04; o minigame só garante o evento):
  - `car_em_chamas`: 5 Ressonâncias seguidas do mesmo lugar;
  - `car_acorde`: os quatro na Ressonância no mesmo tempo 1. Acontece no coro, no ponto 1 da peça de 4 tempos, que
    sempre começa no tempo 1;
  - `car_por_um_fio`: o vencedor por 2 % ou menos, no resultado;
  - `car_virada`: do placar;
  - `car_emburrado`: do inserto do resultado.
- **Adesivos:** na seção 3, ninguém está fora da rodada, e ninguém manda adesivo durante o jogo.
- Nenhum carimbo próprio deste minigame.

## A diversão

**O momento: o desmolde dos quatro** (`desmolde`). Os quatro traçam no mesmo tempo, como um coro, e na batida do
carimbo os quatro moldes abrem juntos. A sala vê as quatro peças saltarem lado a lado. As inteiras brilham e cantam
(degrau golpe: escala 130 % que volta em meia batida, tremor de 0,02 m por 1 batida, 2 quadros de parada no
ferreiro). As tortas entortam no ar e caem com som de lata (degrau estrondo: tremor de 0,05 m por 2 batidas, 3
quadros de parada, 50 faíscas).

- **O rastro:** a peça torta vai para a estante e fica lá até o fim, entre as boas. A estante é o placar e é a piada.
- **A curva:** de 0 a 30 s, a peça de 4 tempos; de 30 a 60 s, a fornada de 3 tempos (o desmolde contra o compasso,
  a luz 20 % acima); de 60 s ao fim, a de 4 tempos de novo. Nas últimas 16 batidas, a inteira vale 2 e sai dourada
  (tamanho, não regra nova).
- **Ensina sem falar:** a letra acende no molde ponto a ponto, 1 aviso antes; o touchpad do controle é a placa na TV,
  do mesmo tamanho relativo e na mesma orientação.
- **Quem está perdendo:** a torta vale meia peça (não zero); a partitura simples fica.
- **O que saiu:** o abrir e fechar dos dois dedos, da segunda peça em diante. A primeira mantém (a bancada mede).
- **A nota de hoje:** 2; com o desmolde e a torta com forma, 3.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7, sem a
bancada, pela prova visual da F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem uma linha `toque` com `t_musica` ≤ 10,0; a primeira `momento` `desmolde` tem `t_musica` < 10,0 | os quadros de 2 a 10 s mostram a letra acesa na cor de pelo menos dois donos |
| 4. o momento | uma linha `momento` `desmolde` por peça; pelo menos 3 grupos de desmolde (linhas a menos de 0,4 s umas das outras) com uma `torta: true` e uma `torta: false` juntas | o quadro de 60 s mostra pelo menos 1 peça torta na estante do P4 |
| 5. a curva | notas por segundo no 2.º terço ≥ 1,0 × as do 1.º (a fornada: 3 notas em 3 tempos), com desmoldes por segundo ≥ 1,3 × as do 1.º; a linha `momento` `reta` existe | o quadro do meio do 2.º terço tem a câmera mais longe que o do meio do 1.º |
| 6. a falha | o P4 tem pelo menos 10 linhas `toque` com `erro` | 1 quadro em 5 mostra uma torta do P4 na estante |
| 7. quem perde joga | a maior distância entre duas linhas `nota` seguidas de cada lugar é de até 8 batidas; o P4 tem um `toque` bom ou melhor em cada terço | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | cada `desmolde` tem 0,1 ≤ `x_tela` ≤ 0,9 e `altura_tela` ≥ 0,02 | a estante se vê no quadro de 480 × 270 sem ampliar |
| 9. o impacto | para cada `desmolde`, uma linha `sensacao` do mesmo lugar a até 16,7 ms (o golpe do kit no carimbo) | o quadro seguinte ao desmolde ainda mostra a peça na estante |
| 10. o placar no mundo | a ordem do `vencedor()` bate com a ordem das estantes (`valor`) no `momento` `reta` e no fim | no quadro de 60 s, quem olha diz a ordem pelas estantes, e ela bate com o registro |

Até o robô por lugar (`--robo=bom,medio,medio,ruim`, pedido ao arquiteto na régua) existir, a prova roda com
`--robo=medio` nos quatro e confere os itens 1, 4, 5, 8, 9 e 10; os itens 6 e 7 esperam o robô por lugar.

## Pronto quando

O Molde joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos. O cabo que cai e
volta começa uma peça nova no próximo tempo 1. A primeira peça pede os três pontos, o clique e os dois dedos, e os
vereditos `touchpad_dois_dedos` e `touchpad_clique` passam na prova limpa (o `um-dedo` e o `sem-clique` continuam
pegos no gauntlet). A fornada aparece entre 30 e 60 s. As linhas `momento` `desmolde` e `reta` estão no registro, com
os mínimos da diversão. O fim tem sempre vencedor, e `--sala=molde` abre o `S03_J11`. O `secao.gd` e o `o_molde.gd`
existem com os `.uid`; o catálogo e as traduções têm as linhas desta ficha; `godot/scripts/salas/molde.gd` não existe
mais. `SALA=S03_J11 bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh` passam, com a prancha olhada. O
commit, sem trailer, é `feat(molde): O Molde no tempo da música, o desmolde dos quatro e a oficina da seção`.

## Provas

Na sessão: `SALA=S03_J11 bash tests/prova_do_jogo.sh`, `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

### `godot/testes/prova_do_jogo.gd`

No `match` de `_prova_da_ficha` (H08): `"S03_J11", "molde": await _prova_do_molde()`. A linha
`await _joga_a_sala("molde", ["touchpad_dois_dedos", "touchpad_clique"])` (hoje na 145) fica: a primeira peça pede
os dois.

```gdscript
## O Molde (S03_J11): o apelido abre o minigame; a primeira peça pede os dois
## vereditos; os desmoldes têm linha `momento`, com tortas e inteiras juntas; a
## fornada cai no terço do meio; a reta aparece uma vez.
func _prova_do_molde() -> void:
	var fornada := [false]
	var olhar := func(mg: Minigame) -> void:
		var e: Dictionary = mg.j.get(0, {})
		if not e.is_empty() and float(e.tam) == 3.0:
			fornada[0] = true
	var mg = await _joga_o_minigame("molde", 140.0, olhar)
	if mg == null:
		return
	_esperar(mg.FICHA.slot == "S03_J11", "Molde: --sala=molde abre o S03_J11")
	_confere_os_vereditos(mg, ["touchpad_dois_dedos", "touchpad_clique"])
	_esperar(fornada[0], "Molde: a fornada de 3 tempos aconteceu")
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S03_J11")
	var desm := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "desmolde")
	var reta := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "reta")
	_esperar(not desm.is_empty() and float(desm[0].get("t_musica", 99.0)) < 10.0,
		"Molde: o primeiro desmolde antes de 10 s (%s)" % [desm.slice(0, 1)])
	# os grupos de desmolde (a menos de 0,4 s) com uma torta e uma inteira juntas
	var mistos := 0
	var i := 0
	while i < desm.size():
		var t0 := float(desm[i].t_musica)
		var tortas := 0
		var inteiras := 0
		var k := i
		while k < desm.size() and float(desm[k].t_musica) - t0 < 0.4:
			if bool(desm[k].get("torta", false)):
				tortas += 1
			else:
				inteiras += 1
			k += 1
		if tortas >= 1 and inteiras >= 1:
			mistos += 1
		i = k
	_esperar(mistos >= 3, "Molde: %d grupos com torta e inteira juntas (o mínimo é 3)" % mistos)
	_esperar(reta.size() == 1, "Molde: a linha momento reta aparece uma vez")
	for d in desm:
		var x := float(d.get("x_tela", 0.0))
		_esperar(x >= 0.1 and x <= 0.9 and float(d.get("altura_tela", 0.0)) >= 0.02,
			"Molde: o desmolde dentro da tela (%s)" % [d])
	var v: Array = mg.vencedor()
	_esperar(not v.is_empty() and float(mg.j[v[0]].valor) >= float(mg.j[v[-1]].valor), "Molde: o vencedor tem a maior estante")
```

O `_confere_os_vereditos` e o `_joga_o_minigame` são os da H08; o `_linha_do_tempo` é o da F01. Com `--robo=medio`
nos quatro, as tortas vêm dos 200 ms atrasados do temperamento.

### `godot/testes/captura_jogo.gd`

Os momentos de `"molde"` (hoje nas linhas 129 a 133) passam a:

```gdscript
		"molde": [
			["molde_tracar", p1.call(func(_sala, e) -> bool: return int(e.feitos) >= 2 and int(e.passo) <= 2)],
			["molde_desmolde", p1.call(func(_sala, e) -> bool: return Ritmo.batida() < float(e.aberto_ate) and int(e.volta) >= 2)],
			["molde_fornada", p1.call(func(_sala, e) -> bool: return float(e.tam) == 3.0 and int(e.feitos) >= 1)],
		],
```

### O que o registro mede

- As medidas do núcleo, como hoje: quantos dedos chegaram juntos, que pedaço do touchpad os toques cobriram, a
  abertura máxima, o abrir e fechar e o clique (`med_tracou` quando os três pontos saem; `med_pedir("clique")` e
  `med_pedir("dois_dedos")` ao armar o carimbo e o abrir). São os vereditos `touchpad_dois_dedos` e
  `touchpad_clique` da bancada, só na primeira peça.
- O kit: `nota` e `toque`. A linha `entrada` em cada toque julgado: o passo, a posição dos dois dedos e quantos
  estavam encostados. A `momento` `desmolde` (`torta`, `forma`, `dourada`, `x_tela`, `altura_tela`) e a `reta`
  (`ordem`).

### As pranchas que o jogador do time olha

A prancha da prova visual (um quadro de 480 × 270 a cada 2 s):
- de 4 a 10 s: a letra acesa e o primeiro desmolde;
- aos 45 s: a fornada, a câmera mais longe e a luz mais alta;
- aos 60 s: a torta na estante do P4 e a ordem das estantes, que se confere com o registro;
- nas últimas 16 batidas: as peças douradas.

### O que o André joga e sente

`scripts/gauntlet.sh` (o `um-dedo` e o `sem-clique` têm de sair pegos) e `bash tests/prova_de_poucos.sh`; depois,
`./run-local.sh -- --sala=molde`. Ele confere: o traço de um ponto por tempo cabe no dedo; o ponto aceso 1 batida
antes se segue sem olhar o touchpad; o clique na batida é claro; a pedra se sente no cabo; os quatro moldes abrem
juntos; e a torta faz rir.

### Armadilhas

- **O clique é um evento** (`Forja.apertou`, um quadro): o cruzamento dele é o próprio quadro. Um clique antes da
  janela se perde (não é erro).
- **`med_tracou` só com os três pontos acertados** (bom ou melhor): é o que o veredito chama de letra completa.
- **As metades andam em `x` local da placa** (ela é inclinada): nunca `global_position`.
- **O `n` não sobe nos passos calados** (`e.armada` falso): a queda não grava nota, e o kit não vê nota que não existe.
- **A fornada não se alinha ao compasso** (é a graça); a peça de 4 tempos, sim (`_nova_peca` arredonda `S` ao
  próximo tempo 1).
- **`_roteiro_em` decide pela batida**, não pelo agora: as quatro peças do coro trocam de roteiro na mesma batida.
- **O tremor respeita as opções:** com `Opcoes.tremor` desligado, o main não treme.
