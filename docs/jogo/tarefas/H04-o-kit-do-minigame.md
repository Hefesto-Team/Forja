# H04 — O kit do minigame

**Sprint:** H · **Tamanho:** G · **Depende de:** F00, F03, F05, F08, F09, H01, H02

## Por quê

Cada minigame novo tem de ser a ficha de dados mais o que é só dele. O kit
(`Minigame`) faz o que todos repetiriam — a ficha, as raias, quem está
conectado, o relógio da faixa, o julgamento do toque, o registro, o fim com
vencedor — e o catálogo (`Catalogo`) substitui a lista de salas do
`main.gd`. É o que põe os 45 no orçamento. A prova do kit é A Centelha de
hoje morando no kit (`S01_J01`), sem mudar a regra, e um minigame de prova
que mostra os quatro julgamentos saindo do `Ritmo`.

## Ler antes

- [A arquitetura: o kit do minigame](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A paridade entre a prova e o jogo](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08) e [a prova visual](../13-arquitetura.md#a-prova-visual--f09)
- [O molde de minigame](molde-de-minigame.md) (esta ficha o deixa verdadeiro)

## O estado de hoje

- **A lista de salas** é um `const` em `godot/scripts/main.gd:13-24`:

  ```gdscript
  const SALAS := {
  	"centelha": preload("res://scripts/salas/centelha.gd"),
  	...
  	"bancada": preload("res://scripts/salas/bancada.gd"),
  }
  ```

  Usada em `main.gd:186` (`--sala=`), `main.gd:299` e `main.gd:306`
  (`_entrar_na_sala`: `sala = SALAS[id].new()`). O `sala_id` do `main.gd` é o
  id pedido, e é ele que a música (`main.gd:214`), o salão
  (`main.gd:281`, `salao.saida_do_portao(sala_id, ...)`) e a partida
  (`partida.gd:22-30`, `NA_ORDEM` e `NOMES` por id) usam. Mas a partida
  registra o `sala.id`, não o `sala_id` (`main.gd:400` e `main.gd:405`).
- **As fases** são da `SalaJogo` (`godot/scripts/salas/sala_jogo.gd`):
  `entrar` (79-97), `sair` (100-108), `congelar` (189-199), `_process`
  (202-223, chama `jogar(dt)` na fase `jogo`), `comecar` (282-293, chama
  `iniciar_jogo()`), `terminar` (317-333), `marcar` (402-414). Os ganchos que
  já existem: `montar()` (da `Sala`), `iniciar_jogo()`, `jogar(dt)`.
- **O que as salas repetem**: `const RAIAS := [-6.0, -2.0, 2.0, 6.0]` em sete
  salas (`caminhos.gd:24`, `canto.gd:22`, `centelha.gd:25`, `galeria.gd:20`,
  `impacto.gd:19`, `viga.gd:25`, `voz.gd:22`; o Molde tem outras,
  `molde.gd:24`), o `Z_JOGADOR` em cinco, `_conectado(l)` idêntico em cinco
  (`caminhos.gd:240`, `canto.gd:268`, `impacto.gd:211`, `prova.gd:306`,
  `voz.gd:244`), a montagem da raia (laje, borda na cor do lugar, luz) em
  `canto.gd:181-236`, `impacto.gd:108-160`, `voz.gd:167-215`, e o robô
  chamado de dentro do `jogar` (`if Forja.robo: _robo(l, dt)`,
  `centelha.gd:245-246`). São umas 30 a 60 linhas por sala — a economia
  maior do kit é o que **ainda não existe** em sala nenhuma: o relógio, o
  julgamento, o registro da nota e do toque, o fim com vencedor.
- **A Centelha** (`godot/scripts/salas/centelha.gd`, 422 linhas) quase não
  tem repetição: não monta raia, não tem `_conectado`, não tem `dica`. O
  `_init()` (37-47) diz id, nome, ação, gesto, features, botões e duração; o
  resto é a regra dela.
- **Os ids nas provas**: `godot/testes/prova_do_jogo.gd:292`
  (`sala.id == id`), `:346` (`sala.id == "centelha"`), `:495` e `:499`
  (`jogo.sala.id != ids[i]`); `godot/testes/prova_de_poucos.gd:69`
  (`sala.id != id`); `godot/testes/captura_jogo.gd:116`
  (`SalaCentelha._contar(...)`, o `class_name` que vai sumir).
- **Medido nesta preparação** (Godot 4.4.1, projeto de rascunho):
  - `const FICHA := {"entradas": [Forja.CRUZ, Forja.CIRCULO]}` funciona: a
    constante do autoload vale dentro de `const`;
  - `get_script().get_script_constant_map().get("FICHA")` no `_init()` da
    classe-mãe acha a `FICHA` da filha;
  - um `_init()` na filha **sem** `super()` faz o `_init()` da mãe não rodar
    (a ficha não é lida); com `super()` na primeira linha, roda uma vez;
  - redeclarar na filha uma constante da mãe (`const RAIAS` no minigame) é
    erro de análise: `The member "RAIAS" already exists in parent class`.
  - O kit inteiro desta ficha (o código de "O alvo") foi rodado numa cópia
    do projeto com a prova do jogo: verde, com a Centelha no kit passando os
    vereditos, e o minigame de prova dando P1 12/12 perfeito, P2 12/12
    ótimo, P3 11/12 bom (com o cabo saindo no meio), P4 12/12 erro, em 6,9 s
    de relógio (114 s de jogo: com `--fixed-fps 60` sem janela, o jogo anda
    ~16 vezes mais depressa que o relógio).

## O alvo

A API do [13](../13-arquitetura.md#o-kit-do-minigame--h04). O que não está
lá (marcado **novo**) entra no 13 no mesmo commit (passo 11).

### `godot/scripts/minigames/minigame.gd`

O arquivo inteiro:

```gdscript
class_name Minigame
extends SalaJogo
## O kit do minigame (docs/jogo/13-arquitetura.md#o-kit-do-minigame--h04): o
## que todo minigame tem e nenhum repete — a ficha de dados, as raias, quem
## está conectado, o relógio da faixa, o julgamento do toque, o registro da
## nota e do toque, as falas e a colocação. O minigame escreve a FICHA (um
## const no próprio script: docs/jogo/tarefas/molde-de-minigame.md) e os
## ganchos: montar, iniciar_jogo, jogar, toque, falha, vencedor e robo.
##
## O kit não sabe de robô: chama robo(l, dt) de todo lugar em jogo, a cada
## quadro, e só o gancho do minigame olha Forja.robo (docs/jogo/13, a
## paridade entre a prova e o jogo).

## As chaves que toda FICHA tem.
const CHAVES := ["slot", "titulo", "verbo", "genero", "icone", "entradas", "camera", "faixa", "duracao",
	"fim", "sensacoes", "material", "microjogo"]
const GENEROS := ["tct", "2v2", "coop", "corrida", "sobrevivencia", "terror", "sabotagem"]
const FINS := ["tempo", "ultimo_em_pe", "primeiro_a_chegar", "meta_coletiva"]
const CAMERAS := ["fixa", "grupo", "corrida"]
const MATERIAIS := ["metal", "pedra", "areia", "gelo", "grama", "lama", "plasma", "madeira"]

## As quatro raias: o x de cada lugar, e onde o boneco fica nela.
const RAIAS := [-6.0, -2.0, 2.0, 6.0]
const Z_JOGADOR := 1.4
## A nota de cada lugar na TV (o hoqueto, docs/jogo/02#3): dó, ré, fá e sol
## sobre o som "nota".
const TOM_DO_LUGAR := [1.0, 1.1225, 1.3348, 1.4983]
## Uma fala por lugar a cada FALA_S segundos, no máximo (G07).
const FALA_S := 20.0

var ficha := {}  ## a FICHA do script do minigame (lida no _init)
var _raias := {}  ## lugar -> {raiz, mat_borda, luz}
var _ultima_fala := [-FALA_S, -FALA_S, -FALA_S, -FALA_S]
var _fps_min := INF  ## o desempenho da fase jogo (o evento `desempenho`)
var _fps_soma := 0.0
var _fps_n := 0


## Lê a FICHA do script do minigame. O minigame não escreve _init(); se
## escrever, a primeira linha é super().
func _init() -> void:
	var achada = get_script().get_script_constant_map().get("FICHA", {})
	ficha = (achada as Dictionary).duplicate(true)
	id = str(ficha.get("slot", ""))
	nome = str(ficha.get("titulo", ""))
	acao = str(ficha.get("verbo", ""))
	duracao = float(ficha.get("duracao", 90.0))
	# as chaves opcionais (o molde): o que a bancada mede, o gesto do aviso, o treino
	features = Array(ficha.get("features", []))
	botoes_pedidos = Forja.mascara(Array(ficha.get("botoes_medidos", [])))
	gesto_do_aviso = str(ficha.get("gesto", ""))
	com_treino = bool(ficha.get("treino", true))


func entrar(js: Array) -> void:
	conferir_a_ficha()
	super(js)


## Falta chave, ou um valor fora da lista? Falha alto (push_error) e diz qual.
func conferir_a_ficha() -> bool:
	var ok := true
	for k in CHAVES:
		if not ficha.has(k):
			push_error("minigame %s: a FICHA não tem «%s»" % [get_script().resource_path, k])
			ok = false
	if not ok:
		return false
	for par in [["genero", GENEROS], ["fim", FINS], ["camera", CAMERAS], ["material", MATERIAIS]]:
		if not str(ficha[par[0]]) in par[1]:
			push_error("minigame %s: «%s» não vale em %s" % [id, ficha[par[0]], par[0]])
			ok = false
	return ok


# ---------------------------------------------------------------- as fases --

## A fase jogo: a faixa da ficha começa do zero, e o relógio parte dela.
func comecar() -> void:
	var faixa := str(ficha.get("faixa", ""))
	var mapa := Musica.mapa(faixa)
	Ritmo.tocar(faixa, float(mapa.bpm), float(mapa.primeiro_tempo))
	Ritmo.dono = id
	Ritmo.zerar_ajuda()
	super()
	Forja.evento("minigame", 0, {"slot": id, "evento": "comecou", "presentes": _lista(presentes())})


## O fim: o relógio solta a faixa, e o registro ganha o desempenho da fase
## jogo e o `minigame` `terminou` com o vencedor (nunca sem).
func terminar() -> void:
	if fase == "fim":
		return
	Ritmo.parar()
	var c := vencedor()
	colocacao = c   # a var da SalaJogo (F03); o kit não declara func colocacao(): o nome colidiria
	Forja.evento("desempenho", 0, {"slot": id, "fps_min": snappedf(_fps_min if _fps_n > 0 else 0.0, 0.1),
		"fps_media": snappedf(_fps_soma / maxi(_fps_n, 1), 0.1)})
	Forja.evento("minigame", 0, {"slot": id, "evento": "terminou", "vencedor": int(c[0]) if not c.is_empty() else -1,
		"colocacao": _lista(c), "pontos": _lista(pontos), "duracao": snappedf(t_fase, 0.1)})
	super()


## Uma lista de números como texto ("0,1,2,3"): o registro de hoje não grava listas.
static func _lista(a: Array) -> String:
	return ",".join(a.map(func(x): return str(x)))


func sair() -> void:
	Ritmo.pausar(false)
	Ritmo.parar()
	super()


## A pausa por cima: o jogo e o relógio da música param juntos.
func congelar(sim: bool) -> void:
	super(sim)
	Ritmo.pausar(sim)


func _process(dt: float) -> void:
	if not congelada and fase == "jogo":
		var fps := Engine.get_frames_per_second()
		_fps_min = minf(_fps_min, fps)
		_fps_soma += fps
		_fps_n += 1
		for p in jogadores:
			var l: int = p.lugar
			if jogando[l] and not acabou[l] and conectado(l):
				robo(l, dt)
	super(dt)


# ---------------------------------------------------------------- os ganchos --
# montar(), iniciar_jogo() e jogar(dt) são da Sala e da SalaJogo; o minigame
# os escreve. Estes quatro são do kit.

## A consequência de um toque julgado BOM, OTIMO ou PERFEITO (o ERRO vai para falha).
func toque(_l: int, _julgamento: int) -> void:
	pass


## A falha física: o toque ERRO, ou a nota que passou sem toque.
func falha(_l: int) -> void:
	pass


## Os lugares na ordem de colocação (o primeiro venceu). Por padrão, pelos pontos.
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b): return int(pontos[a]) > int(pontos[b]))
	return lista


## Como o robô joga o lugar neste quadro, pelo controle simulado
## (Forja.robo_apertar, robo_eixo...). É o único lugar do minigame que olha
## Forja.robo: a primeira linha é `if not Forja.robo: return`.
func robo(_l: int, _dt: float) -> void:
	pass


# ---------------------------------------------------------------- o kit --

func conectado(l: int) -> bool:
	return bool(Forja.lugar(l).get("conectado", false))


## Os lugares que estão jogando este minigame.
func presentes() -> Array:
	var r: Array = []
	for p in jogadores:
		if jogando[p.lugar]:
			r.append(p.lugar)
	return r


## O lugar está jogando agora (em jogo, e com controle)? A guarda da dica e do status.
func na_raia(l: int) -> bool:
	return fase == "jogo" and bool(jogando[l]) and conectado(l)


## A raia do lugar: a laje, a borda na cor do lugar e a luz da vez (apagada).
func raia(l: int) -> Node3D:
	var cor := Forja.cor_do_lugar(l)
	var raiz := Node3D.new()
	raiz.name = "Raia%d" % (l + 1)
	raiz.position = Vector3(RAIAS[l], 0.0, Z_JOGADOR)
	add_child(raiz)
	Kit.cilindro(raiz, 1.45, 0.06, Vector3(0, 0.03, 0), Kit.material(Color("#2a2233"), 0.0, 0.9))
	var borda := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 1.4
	tor.outer_radius = 1.5
	tor.rings = 48
	borda.mesh = tor
	borda.position = Vector3(0, 0.08, 0)
	borda.scale = Vector3(1, 0.35, 1)
	var mat := Kit.material(cor.darkened(0.45), 0.0, 0.7)
	mat.emission_enabled = true
	mat.emission = cor
	mat.emission_energy_multiplier = 0.4
	borda.material_override = mat
	raiz.add_child(borda)
	var luz := OmniLight3D.new()
	luz.position = Vector3(0, 2.2, 0.6)
	luz.light_color = cor
	luz.light_energy = 0.0
	luz.omni_range = 3.5
	raiz.add_child(luz)
	_raias[l] = {"raiz": raiz, "mat_borda": mat, "luz": luz}
	return raiz


## Acende a raia do lugar (0 apagada, 1 a vez dele).
func acender_raia(l: int, forca: float) -> void:
	if not _raias.has(l):
		return
	var r: Dictionary = _raias[l]
	(r.mat_borda as StandardMaterial3D).emission_energy_multiplier = 0.4 + 2.0 * forca
	(r.luz as OmniLight3D).light_energy = 1.6 * forca


## O boneco do lugar no meio da raia, de frente, de mãos livres.
func posicionar(l: int) -> void:
	var p := jogador(l)
	if p == null:
		return
	p.position = Vector3(RAIAS[l], 0.1, Z_JOGADOR)
	p.rotation.y = 0.0
	maos_livres(p)


## Julga o toque do lugar agora contra a nota em t_alvo (tempo de música) e
## faz o que todo toque julgado faz: a folga de quem está em último (só se a
## nota é um perigo físico), o registro, a ajuda, a sensação e o som da nota
## na TV — e chama toque() nos acertos ou falha() no erro. Devolve o julgamento.
func julgar_toque(l: int, t_alvo: float, n := -1, perigo := false) -> int:
	var t_toque := Ritmo.t_musica()
	var folga := Ritmo.folga_para(l, pontos, presentes()) if perigo else 0.0
	var j := Ritmo.julgar(l, t_toque, t_alvo, folga)
	# G03: o item entra aqui (Itens.ajustar_julgamento e o Escudo, Itens.absorve_erro)
	Ritmo.registrar_toque(l, n, j, Ritmo.desvio_ms(l, t_toque, t_alvo))
	Ritmo.contar_para_ajuda(l, j)
	_reagir(l, j)
	if j == Ritmo.ERRO:
		falha(l)
	else:
		toque(l, j)
	return j


## A nota n do lugar passou sem toque: é erro, com a falha física.
func nota_perdida(l: int, n: int) -> void:
	Ritmo.registrar_toque(l, n, Ritmo.ERRO)
	Ritmo.contar_para_ajuda(l, Ritmo.ERRO)
	_reagir(l, Ritmo.ERRO)
	falha(l)


## Uma nota nova do lugar, no registro (a G03 põe a Lanterna aqui).
func nova_nota(l: int, n: int, t_alvo: float) -> void:
	Ritmo.registrar_nota(l, n, t_alvo)


## Uma fala do cavaleiro do lugar, no máximo uma a cada FALA_S s. Devolve se
## falou. A G07 põe a fala de verdade aqui.
func falar(l: int, _evento: String) -> bool:
	if t - float(_ultima_fala[l]) < FALA_S:
		return false
	_ultima_fala[l] = t
	return true


func _reagir(l: int, j: int) -> void:
	var p := jogador(l)
	var pos := p.global_position + Vector3(0, 1.2, 0) if p else Vector3(RAIAS[l], 1.2, Z_JOGADOR)
	if j == Ritmo.ERRO:
		Forja.sentir(l, "erro")
		Som.tocar("falha", pos, -6.0)
	else:
		Forja.sentir(l, "perfeito" if j == Ritmo.PERFEITO else "acerto")
		Som.tocar("nota", pos, -4.0 if j == Ritmo.PERFEITO else -9.0, TOM_DO_LUGAR[l])
```

**Novo** (entra no 13): `conferir_a_ficha()`, `presentes()`, `na_raia(l)`,
`acender_raia(l, forca)`, `nota_perdida(l, n)`, `nova_nota(l, n, t_alvo)`;
`julgar_toque` ganha dois parâmetros opcionais
(`n := -1, perigo := false`); as chaves opcionais da FICHA (`features`,
`botoes_medidos`, `gesto`, `treino`); o registro `minigame` com
`colocacao` e `pontos` em texto (`"0,1,2,3"`, porque o registro de hoje não
grava listas) e `vencedor` = o lugar 0..3 do primeiro; o `desempenho`.

### `godot/scripts/minigames/catalogo.gd`

O arquivo inteiro:

```gdscript
class_name Catalogo
extends RefCounted
## O catálogo: as nove seções, os minigames de cada uma e as salas de hoje que
## ainda não viraram minigame (docs/jogo/13-arquitetura.md#o-kit-do-minigame--h04).
## Substitui o SALAS do main.gd. Os ids antigos (centelha, viga...) continuam
## valendo em --sala=, na Prova de Fogo e na partida: são os apelidos das
## seções, e abrem o primeiro minigame da seção quando ele existe.

const SECOES := [
	{"id": "S01", "nome": "A Centelha", "apelido": "centelha", "minigames": ["S01_J01"]},
	{"id": "S02", "nome": "A Viga", "apelido": "viga", "minigames": []},
	{"id": "S03", "nome": "O Molde", "apelido": "molde", "minigames": []},
	{"id": "S04", "nome": "O Impacto", "apelido": "impacto", "minigames": []},
	{"id": "S05", "nome": "A Galeria", "apelido": "galeria", "minigames": []},
	{"id": "S06", "nome": "O Canto", "apelido": "canto", "minigames": []},
	{"id": "S07", "nome": "Os Caminhos", "apelido": "caminhos", "minigames": []},
	{"id": "S08", "nome": "A Voz", "apelido": "voz", "minigames": []},
	{"id": "S09", "nome": "A Prova", "apelido": "prova", "minigames": []},
]
const MINIGAMES := {
	"S01_J01": preload("res://scripts/minigames/s01/martelo_de_hefesto.gd"),
}
## As salas de hoje que ainda não se mudaram para minigames/ (cada ficha de
## seção tira a sua daqui), e a bancada, que não é seção.
const SALAS_ANTIGAS := {
	"viga": preload("res://scripts/salas/viga.gd"),
	"molde": preload("res://scripts/salas/molde.gd"),
	"impacto": preload("res://scripts/salas/impacto.gd"),
	"galeria": preload("res://scripts/salas/galeria.gd"),
	"canto": preload("res://scripts/salas/canto.gd"),
	"caminhos": preload("res://scripts/salas/caminhos.gd"),
	"voz": preload("res://scripts/salas/voz.gd"),
	"prova": preload("res://scripts/salas/prova.gd"),
	"bancada": preload("res://scripts/salas/bancada.gd"),
}
## Os nomes de antes que ainda abrem alguma coisa.
const NOMES_VELHOS := {"giro": "viga"}


## O que o id abre: o apelido de uma seção vira o primeiro minigame dela
## (quando existe); um slot ou o id de uma sala de hoje fica como está.
static func resolver(id: String) -> String:
	var chave: String = NOMES_VELHOS.get(id, id)
	for s in SECOES:
		if s.apelido == chave and not s.minigames.is_empty():
			return s.minigames[0]
	return chave


static func existe(id: String) -> bool:
	var chave := resolver(id)
	return MINIGAMES.has(chave) or SALAS_ANTIGAS.has(chave)


## Uma sala nova pelo id (o apelido, o slot ou o id de hoje); null se não existe.
static func criar(id: String) -> Sala:
	var chave := resolver(id)
	if MINIGAMES.has(chave):
		return MINIGAMES[chave].new()
	if SALAS_ANTIGAS.has(chave):
		return SALAS_ANTIGAS[chave].new()
	return null


## O apelido da seção de um slot ("S01_J01" → "centelha"); o próprio id se não é de seção.
static func apelido(id: String) -> String:
	for s in SECOES:
		if id in s.minigames:
			return s.apelido
	return id
```

### `godot/scripts/minigames/s01/martelo_de_hefesto.gd`

A Centelha de hoje, **com a mesma regra**, morando no kit. O começo do
arquivo (o cabeçalho, as constantes e a FICHA) é este:

```gdscript
extends Minigame
## O Martelo de Hefesto (S01_J01) — por enquanto, A Centelha de antes no kit:
## runas que acendem ao apertar. Cada jogador tem a sua bigorna; em cima dela
## acende uma runa com um símbolo e um anel que vai se fechando. Apertar o
## botão da runa antes do anel fechar faz o boneco martelar a bigorna. A fila
## de cada um passa por todos os botões que um jogo usa (✕ ○ □ △, L1, R1, L3,
## R3, as quatro setas e o Create), por dois círculos (cada analógico até a
## borda, nas oito direções) e pelo fole (cada gatilho segurado na faixa
## dourada e depois apertado até o fundo), numa ordem sorteada pela semente.
## Runa perdida volta para o fim da fila (até três vezes).
##
## A regra é a de antes: a H04 só mudou a casa. O Martelo no tempo da faixa,
## com as quatro bigornas e a nota de cada um, é da ficha da seção (I).
##
## A falha: a runa treme e o boneco balança a cabeça. O vencedor: mais pontos.
## O registro mede: cada botão, analógico e gatilho pedido e respondido (as
## medidas do núcleo, que servem à bancada). O robô: vê a runa e reage como
## gente — às vezes o dedo escorrega para o vizinho e corrige; gira o
## analógico em volta; segura o gatilho no meio e aperta.
##
## O Options é a pausa, o PS fica de fora (o sistema toma), o botão do
## microfone é d'A Voz e o clique do touchpad é d'O Molde.

const BOTOES := [Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO, Forja.TRIANGULO, Forja.L1, Forja.R1, Forja.L3,
	Forja.R3, Forja.CIMA, Forja.BAIXO, Forja.ESQUERDA, Forja.DIREITA, Forja.CREATE]

const FICHA := {
	"slot": "S01_J01",
	"titulo": "O Martelo de Hefesto",
	"verbo": "Bata!",
	"genero": "tct",
	"icone": "botoes",
	"entradas": BOTOES,
	"camera": "fixa",
	"faixa": "MUS_S01_J01",
	"duracao": 100.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "erro"],
	"material": "metal",
	"microjogo": {"verbo": "Bata!", "segundos": 6.0},
	# o que a bancada mede (o veredito é das medidas do núcleo)
	"features": ["botoes", "analogicos", "gatilhos_analogicos"],
	"botoes_medidos": BOTOES,
	"gesto": "attack-melee-right",
}

const GLIFO := {
	Forja.CRUZ: "cross", Forja.CIRCULO: "circle", Forja.QUADRADO: "square", Forja.TRIANGULO: "triangle",
	Forja.L1: "l1", Forja.R1: "r1", Forja.L3: "stick_l", Forja.R3: "stick_r", Forja.CIMA: "dpad_up",
	Forja.BAIXO: "dpad_down", Forja.ESQUERDA: "dpad_left", Forja.DIREITA: "dpad_right", Forja.CREATE: "share",
}
const JANELA_INICIAL := 2.8
const JANELA_MINIMA := 1.5
const JANELA_ANALOGICO := 7.0
const JANELA_GATILHO := 8.0
const MAX_TENTATIVAS := 3
const BORDA := 0.85
```

O resto é o `godot/scripts/salas/centelha.gd` de hoje, **copiado a partir
da linha `var j := {}`** (linha 33) até o fim, com estas trocas e nenhuma
outra:

1. apague o `func _init()` inteiro (linhas 37-47): a FICHA faz o trabalho;
2. no começo do `montar()`, as duas linhas que estavam no `_init`:
   `camera_pos = Vector3(0, 7.2, 12.4)` e `camera_olhar = Vector3(0, 1.2, -0.2)`;
3. no `jogar(dt)`, apague o `if Forja.robo:` e o `_robo(l, dt)` (linhas
   245-246): quem chama o robô agora é o kit, antes do `jogar`;
4. renomeie `func _robo(l: int, dt: float)` para `func robo(l: int, dt: float)`
   e ponha como primeiras linhas `if not Forja.robo:` / `return`; troque o
   comentário acima dele por
   `# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.`;
5. o temperamento do robô (F09): logo depois de
   `e.robo_reacao = 0.35 + 0.55 * rng.randf()`, acrescente

   ```gdscript
   		# o temperamento (--robo=bom|medio|ruim): quando não acerta, chega tarde e perde a runa
   		if not Forja.robo_acerta():
   			e.robo_reacao += JANELA_GATILHO + 1.0
   ```

6. o que a F05 e a F08 já tiverem mudado no `centelha.gd` (o `sentir` no
   lugar do `vibrar`, o robô) vem junto: copie o arquivo **de hoje**, não o
   desta ficha.

`RAIAS` agora é do kit (não redeclare). O `class_name SalaCentelha` some:
minigame não tem `class_name` (o catálogo os carrega pelo caminho).

### `godot/testes/minigame_de_prova.gd`

O minigame de prova do kit (menos de 200 linhas), fora do jogo e da
exportação (`godot/export_presets.cfg:18` já exclui `testes/*`). O arquivo
inteiro:

```gdscript
extends Minigame
## O minigame de prova do kit (fica em testes/: não entra no jogo nem na
## exportação). Quatro raias, uma nota por tempo para cada lugar, ✕ no tempo.
## O robô de cada lugar mira um desvio combinado, para a prova ver os quatro
## julgamentos saírem do Ritmo pelo caminho inteiro: o controle simulado, o
## módulo, o Forja.apertou, o julgar_toque do kit e o registro.
##
## Sem faixa (o relógio do sistema), 120 bpm; cada lugar julga NOTAS notas e
## acaba; o minigame acaba quando todos acabam.

const FICHA := {
	"slot": "T00_J00",
	"titulo": "O Metrônomo",
	"verbo": "Bata!",
	"genero": "tct",
	"icone": "botoes",
	"entradas": [Forja.CRUZ],
	"camera": "fixa",
	"faixa": "",
	"duracao": 0.0,
	"fim": "meta_coletiva",
	"sensacoes": ["acerto", "perfeito", "erro"],
	"material": "metal",
	"microjogo": {"verbo": "Bata!", "segundos": 6.0},
	"treino": false,
}
const NOTAS := 12
## A primeira nota: dá tempo de o robô adiantado mirar antes dela.
const PRIMEIRA := 2
## O desvio que o robô de cada lugar mira, em s (NUNCA: não aperta).
const NUNCA := 99.0
const MIRA := [0.0, -0.065, -0.115, NUNCA]
## Os pontos de cada julgamento (ERRO, BOM, OTIMO, PERFEITO).
const PONTOS := [0, 1, 2, 3]

var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]  ## [lugar][julgamento]
var _nota := [PRIMEIRA, PRIMEIRA, PRIMEIRA, PRIMEIRA]  ## a nota da vez de cada lugar
var _julgadas := [0, 0, 0, 0]
var _robo_apertou := [-1, -1, -1, -1]  ## a última nota em que o robô apertou
var _robo_nota := [-1, -1, -1, -1]  ## a nota que o robô já mirou
var _robo_mira := [0.0, 0.0, 0.0, 0.0]
var _fora := [false, false, false, false]  ## o lugar estava sem controle


func montar() -> void:
	camera_pos = Vector3(0, 7.5, 12.0)
	camera_olhar = Vector3(0, 0.8, 0)
	Kit.arena(self, 5, 3)
	luzes([Vector3(-6, 3.0, 3), Vector3(6, 3.0, 3)])
	for p in jogadores:
		raia(p.lugar)
		posicionar(p.lugar)


func iniciar_jogo() -> void:
	for p in jogadores:
		nova_nota(p.lugar, _nota[p.lugar], Ritmo.t_da_batida(_nota[p.lugar]))


func jogar(_dt: float) -> void:
	for p in jogadores:
		var l: int = p.lugar
		if acabou[l]:
			continue
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			# voltou: a nota da vez é a próxima que ainda não passou
			_fora[l] = false
			_nota[l] = maxi(_nota[l], ceili(Ritmo.batida() + 0.3))
			nova_nota(l, _nota[l], Ritmo.t_da_batida(_nota[l]))
		var n: int = _nota[l]
		var alvo := Ritmo.t_da_batida(n)
		acender_raia(l, clampf(1.0 - absf(Ritmo.t_musica() - alvo) * 4.0, 0.0, 1.0))
		if Forja.apertou(l, Forja.CRUZ):
			contagem[l][julgar_toque(l, alvo, n)] += 1
			_proxima(l)
		elif Ritmo.t_musica() > alvo + Ritmo.JANELA_BOM:
			nota_perdida(l, n)
			contagem[l][Ritmo.ERRO] += 1
			_proxima(l)


func toque(l: int, julgamento: int) -> void:
	marcar(l, PONTOS[julgamento])
	jogador(l).gesto("attack-melee-right", 0.3)


func falha(l: int) -> void:
	jogador(l).gesto("emote-no", 0.4)


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var n: int = _nota[l]
	if MIRA[l] == NUNCA or _robo_apertou[l] == n:
		return
	if _robo_nota[l] != n:
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, aperta tarde demais
		_robo_nota[l] = n
		_robo_mira[l] = MIRA[l] if Forja.robo_acerta() else 0.25
	if Ritmo.t_musica() >= Ritmo.t_da_batida(n) + float(_robo_mira[l]):
		Forja.robo_apertar(l, Forja.CRUZ, 0.05)
		_robo_apertou[l] = n


func _proxima(l: int) -> void:
	_julgadas[l] += 1
	_nota[l] += 1
	if _julgadas[l] >= NOTAS:
		acabou[l] = true
		acender_raia(l, 0.0)
	else:
		nova_nota(l, _nota[l], Ritmo.t_da_batida(_nota[l]))
```

### `godot/scripts/main.gd`

- apague o `const SALAS := {...}` (linhas 13-24);
- `main.gd:186`: `if sala_pedida != "" and Catalogo.existe(sala_pedida):`;
- `_entrar_na_sala` ganha a sala pronta (é como a prova abre o minigame de
  prova, pelo mesmo caminho do jogo):

  ```gdscript
  func _entrar_na_sala(id: String, com_cortina := true, pronta: Sala = null) -> void:
  	if pronta == null and not Catalogo.existe(id):
  		return
  	var feito := func():
  		...
  		sala_id = id
  		sala = pronta if pronta != null else Catalogo.criar(id)
  ```

- `main.gd:400` e `main.gd:405`: `sala_id` no lugar de `sj.id` (a partida e
  o placar falam pelo apelido: `NOMES` da `Partida` é por apelido).

## Passos

Rode a prova rápida (`bash tests/prova_do_jogo.sh`) no fim de cada passo
marcado com **(prova)**. Se reprovar, conserte antes de seguir.

1. **Antes de tudo (prova).** A prova tem de estar verde. Confira as
   dependências: `grep -n "func sentir" godot/scripts/forja.gd` (F05),
   `grep -n "func robo_acerta" godot/scripts/forja.gd` (F09),
   `grep -n "func t_da_batida\|func julgar" godot/scripts/ritmo.gd` (H01,
   H02). Faltou alguma: pare e diga qual.
2. **O que a F03 e a F09 já gravam.** Rode
   `grep -n "\"minigame\"\|\"desempenho\"\|colocacao" godot/scripts/salas/sala_jogo.gd`.
   - Se a `SalaJogo` já grava o `desempenho` (F09, passo 6): apague do
     `terminar()` do kit a linha do `desempenho` e as variáveis `_fps_*`, e
     o cálculo no `_process`.
   - Se a `SalaJogo` já grava o `minigame` (F03): apague do kit os dois
     `Forja.evento("minigame", ...)` e confira que a `SalaJogo` tira o
     vencedor do `vencedor()` do kit e grava na `var colocacao` (F03). **Não**
     declare `func colocacao()` no kit: a F03 já tem `var colocacao` na
     `SalaJogo`, e o mesmo nome não compila.
   Anote na ficha o que ficou de cada lado.
3. **`godot/scripts/minigames/minigame.gd`**: crie com o código de "O alvo".
   Importe (`"$GODOT" --headless --path godot --import --quit`) e confira o
   `.uid`.
4. **`godot/scripts/minigames/s01/martelo_de_hefesto.gd`**: crie pelo
   caminho de "O alvo" (o começo dado, e o resto copiado com as seis trocas).
5. **`godot/scripts/minigames/catalogo.gd`**: crie com o código de "O alvo".
   Importe.
6. **`godot/scripts/main.gd`**: as quatro mudanças de "O alvo". Apague
   `godot/scripts/salas/centelha.gd` e `centelha.gd.uid` (`git rm`).
7. **As provas que olham o id** (a Centelha agora abre com id `S01_J01`):
   - `godot/testes/prova_do_jogo.gd`: acrescente `_e_a_sala(sala, id)` (em
     "Provas") e use-a nas quatro comparações de `sala.id` (linhas 292,
     346, 495 e 499 de hoje);
   - `godot/testes/prova_de_poucos.gd:69`:
     `if not sala is SalaJogo or (sala.id != id and Catalogo.apelido(sala.id) != id):`;
   - `godot/testes/captura_jogo.gd:116`: `SalaCentelha._contar(...)` vira
     `sala._contar(...)` (a função estática se chama pela instância).
   **(prova)** — a Centelha tem de sair com os três vereditos como antes
   (as linhas agora dizem `S01_J01 P1: botoes → passou`).
8. **`godot/scripts/traducoes.gd`**: `"O Martelo de Hefesto": "Hephaestus's Hammer"`,
   `"Bata!": "Strike!"`, e o que mais a tela mostrar de novo.
9. **`godot/testes/minigame_de_prova.gd`**: crie com o código de "O alvo" e
   importe.
10. **`godot/testes/prova_do_jogo.gd`**: acrescente `_prova_do_catalogo()`
    (chamada em `_ready()` logo depois de `add_child(jogo)`, antes de
    `_prova_do_percurso()`), `_prova_do_kit()` (chamada no percurso, logo
    depois de `_joga_a_sala("centelha", ...)`) e a checagem da linha do tempo
    em `_prova_do_relatorio()`. **(prova)**
11. **O 13** e o **molde**: acrescente ao 13, na seção do kit, o que está
    marcado **novo** em "O alvo", e troque o exemplo do catálogo pelo de
    verdade (com `apelido`, `SALAS_ANTIGAS` e `NOMES_VELHOS`). Confira que o
    [molde](molde-de-minigame.md) bate com o kit que ficou (o nome de cada
    gancho e de cada chave); se não bater, o molde muda.
12. **A prova visual** (F09): `bash tests/prova_visual.sh`, e olhe a prancha
    das partidas em que A Centelha aparece. **(prova)** no fim.

## Armadilhas

- **O `_init()` do minigame.** O minigame não escreve `_init()`. Se
  precisar, a primeira linha é `super()` — sem ela, a FICHA não é lida
  (medido).
- **Constante da mãe não se redeclara** (medido): nada de `const RAIAS`,
  `const Z_JOGADOR` ou `const FICHA` no `minigame.gd`; a FICHA é só da filha.
- **`class_name` nos minigames, não.** Os 45 viriam a disputar nomes; o
  catálogo carrega pelo caminho. Quem precisar de uma função estática do
  minigame chama pela instância (`sala._contar(...)`).
- **`Forja.robo` só no gancho `robo()`.** O kit chama `robo(l, dt)` para todo
  lugar em jogo, conectado e que não acabou, **antes** de `jogar(dt)`, e o
  gancho decide. A checagem estática da F08 reprova `Forja.robo` fora dele.
- **O kit nunca pula o aviso nem o fim.** O fim avança sozinho em 6 s para
  todo mundo (F03); o robô, se quiser, aperta ✕ pelo controle (F08).
- **O relógio e a pausa.** `congelar()` pausa o `Ritmo`; `sair()` solta a
  pausa e para o relógio. Sem o `pausar(false)` no `sair()`, quem desiste
  pela pausa deixa o `Ritmo` parado para o próximo minigame.
- **Espera por fase em quadros, por música em relógio.** Com `--fixed-fps 60`
  sem janela, o jogo anda ~16 vezes mais depressa que o relógio de parede, e
  o `Ritmo` anda pelo relógio (ou pela placa). A prova espera a fase `jogo`
  do minigame de prova pelo relógio de parede (limite de 40 s), e as outras
  fases por quadros.
- **O lugar desconectado.** O `presentes()` conta quem joga; `conectado(l)`
  diz quem tem controle agora. A nota de quem está sem controle não vira
  erro, e quando o controle volta, a nota da vez é a próxima que ainda não
  passou (veja `_fora` no minigame de prova). A `SalaJogo` já não espera
  quem está sem controle para acabar (`sala_jogo.gd:218`).
- **1, 2, 3 e 4 jogadores.** Nada no kit supõe quatro: tudo passa por
  `jogadores` e `presentes()`. A prova de poucos
  (`bash tests/prova_de_poucos.sh`, do André) roda A Centelha com dois e
  com um.
- **O treino** julga igual e não soma (o `marcar()` da `SalaJogo`); o
  minigame de prova desliga o treino pela FICHA (`"treino": false`) para a
  conta dos julgamentos fechar.
- **`NAN`/`INF` e listas no registro**: o `Forja.evento` de hoje escreve
  `nan` (JSON quebrado) e converte lista em texto. Por isso `_lista()` e o
  `vencedor` como número.
- **`.uid`**: `minigame.gd.uid`, `catalogo.gd.uid`, `martelo_de_hefesto.gd.uid`
  e `minigame_de_prova.gd.uid` entram no commit; o `centelha.gd.uid` sai.
- **A prova do jogo ficou mais longa** uns 10 s (o minigame de prova e o
  catálogo). Se o `timeout 1200` do `tests/prova_do_jogo.sh` apertar, é
  outra coisa: investigue.

## Não fazer

- Não mudar a regra da Centelha (runas, anel, fila, fole): quem a
  transforma no Martelo de Hefesto de verdade é a ficha [I](I-a-centelha.md).
- Não mudar `Partida`, o salão nem a `Musica` para falar em slots: eles
  continuam pelo apelido.
- Não mover as outras oito salas para `minigames/` (cada uma vai com a sua
  ficha de seção).
- Não pôr no kit caminho de prova, `Forja.robo` ou `--fixed-fps`.

## Pronto quando

A Centelha joga do aviso ao fim morando no kit (`S01_J01`), com os mesmos
vereditos, sem `RAIAS`, sem `_init`, sem `if Forja.robo` fora do `robo()`;
`--sala=centelha`, a Prova de Fogo e a partida continuam abrindo tudo; o
minigame de prova sai com menos de 200 linhas e mostra os quatro
julgamentos saindo do `Ritmo`, com o cabo de um controle saindo e voltando
no meio; todo `minigame` `terminou` tem `vencedor` na linha do tempo; a
prova do jogo passa; e `bash tests/prova_visual.sh` passa com a prancha
olhada.

## Provas

**Na sessão:**

```bash
bash tests/prova_do_jogo.sh
bash tests/prova_visual.sh
```

As checagens novas em `godot/testes/prova_do_jogo.gd`:

```gdscript
## A sala aberta é a do id pedido (o apelido da seção abre o primeiro minigame dela)?
func _e_a_sala(sala, id: String) -> bool:
	return sala.id == id or Catalogo.apelido(sala.id) == id


## O catálogo (H04): os apelidos abrem o primeiro minigame da seção, os ids
## de hoje continuam abrindo, e toda FICHA tem as chaves do molde. Pura.
func _prova_do_catalogo() -> void:
	_esperar(Catalogo.resolver("centelha") == "S01_J01", "catálogo: centelha abre o S01_J01")
	_esperar(Catalogo.apelido("S01_J01") == "centelha", "catálogo: o apelido do S01_J01 é centelha")
	_esperar(Catalogo.resolver("giro") == "viga", "catálogo: o nome antigo da Viga ainda abre a Viga")
	for id in jogo.ORDEM_DO_FOGO + ["bancada"]:
		_esperar(Catalogo.existe(id), "catálogo: --sala=%s continua abrindo" % id)
	_esperar(not Catalogo.existe("nao_existe") and Catalogo.criar("nao_existe") == null, "catálogo: id desconhecido não abre")
	var apelidos := {}
	for s in Catalogo.SECOES:
		apelidos[s.apelido] = true
		for slot in s.minigames:
			_esperar(Catalogo.MINIGAMES.has(slot), "catálogo: %s está em MINIGAMES" % slot)
	_esperar(apelidos.size() == 9, "catálogo: nove seções, nove apelidos")
	for slot in Catalogo.MINIGAMES:
		var mg: Minigame = Catalogo.MINIGAMES[slot].new()
		_esperar(mg.id == slot and mg.conferir_a_ficha(), "catálogo: a FICHA de %s está completa" % slot)
		_esperar(not mg.ficha.is_empty() and mg.nome == str(mg.ficha.titulo), "catálogo: %s leu a FICHA no _init" % slot)
		mg.free()


## O kit (H04): o minigame de prova (godot/testes/minigame_de_prova.gd) joga
## com o robô de cada lugar mirando um desvio, e o Ritmo julga cada toque.
## As fases esperam em quadros; a música, pelo relógio de parede.
func _prova_do_kit() -> void:
	var mg: Minigame = load("res://testes/minigame_de_prova.gd").new()
	jogo._entrar_na_sala(mg.id, false, mg)
	await _quadros(2)
	_esperar(jogo.sala == mg and mg.fase == "aviso", "kit: o minigame de prova abriu")
	var q := 0
	while is_instance_valid(mg) and mg.fase == "aviso" and q < 600:
		await _quadros(1)
		q += 1
	# o cabo do P3 sai depois da terceira nota e volta 0,8 s depois: o minigame segue
	var inicio := Time.get_ticks_usec()
	while is_instance_valid(mg) and mg.fase == "jogo" and mg._julgadas[2] < 3 and Time.get_ticks_usec() - inicio < 20000000:
		await _quadros(1)
	_esperar(Forja.ctl.simulador_cabo(2, false), "kit: o cabo do P3 saiu no meio")
	var fora := Time.get_ticks_usec()
	while Time.get_ticks_usec() - fora < 800000:
		await _quadros(1)
	_esperar(is_instance_valid(mg) and mg.fase == "jogo", "kit: sem o P3, o minigame seguiu")
	_esperar(Forja.ctl.simulador_cabo(2, true), "kit: o cabo do P3 voltou")
	while is_instance_valid(mg) and mg.fase == "jogo" and Time.get_ticks_usec() - inicio < 40000000:
		await _quadros(1)
	_esperar(is_instance_valid(mg) and mg.fase == "fim", "kit: o minigame acabou pelo próprio jogo (%.1f s)" % ((Time.get_ticks_usec() - inicio) / 1e6))
	if not is_instance_valid(mg):
		return
	var esperado := [Ritmo.PERFEITO, Ritmo.OTIMO, Ritmo.BOM, Ritmo.ERRO]
	for l in 4:
		var c: Array = mg.contagem[l]
		var total := int(c[0]) + int(c[1]) + int(c[2]) + int(c[3])
		var certos := int(c[esperado[l]])
		_esperar(total == mg.NOTAS and certos * 10 >= total * 7,
			"kit P%d: %s em %d de %d notas %s" % [l + 1, Ritmo.NOMES_DO_JULGAMENTO[esperado[l]], certos, total, c])
	_esperar(mg.vencedor() == [0, 1, 2, 3], "kit: a colocação pelos pontos (%s, pontos %s)" % [mg.vencedor(), mg.pontos])
	q = 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "kit: de volta ao salão pelo fechamento")
	_esperar(not Ritmo._pausado and Ritmo.slot == "", "kit: o relógio solto ao sair")
```

Em `_prova_do_relatorio()`, depois de `var arquivos := ...` (se a H02 já pôs
o laço que lê a linha do tempo, junte as duas checagens no mesmo laço):

```gdscript
	# o kit (H04): na linha do tempo, os quatro julgamentos do minigame de
	# prova, e todo minigame que terminou tem vencedor
	var julgamentos := {}
	var sem_vencedor: Array = []
	var terminados := 0
	for f in arquivos:
		if not (f.begins_with("linha-do-tempo-") and f.ends_with(".jsonl")):
			continue
		for linha in FileAccess.get_file_as_string(pasta.path_join(f)).split("\n", false):
			var ev = JSON.parse_string(linha)
			if not ev is Dictionary:
				continue
			if ev.get("tipo", "") == "toque" and ev.get("slot", "") == "T00_J00":
				julgamentos[ev.get("julgamento", "?")] = true
			if ev.get("tipo", "") == "minigame" and ev.get("evento", "") == "terminou":
				terminados += 1
				if int(ev.get("vencedor", -1)) < 0:
					sem_vencedor.append(ev)
	_esperar(julgamentos.has("perfeito") and julgamentos.has("otimo") and julgamentos.has("bom") and julgamentos.has("erro"),
		"registro: os quatro julgamentos do minigame de prova (%s)" % [julgamentos.keys()])
	_esperar(terminados >= 2 and sem_vencedor.is_empty(), "registro: %d minigames terminaram, todos com vencedor (%s)" % [terminados, sem_vencedor])
```

**Com o André, local:** ver abaixo.

## Para o André (local)

```bash
scripts/gauntlet.sh
bash tests/prova_de_poucos.sh
./run-local.sh -- --sala=centelha
```

A Centelha tem de jogar igual a antes (o título na tela agora é "O Martelo de
Hefesto", o verbo "Bata!"). Na prova visual da sua máquina, olhe a prancha
das partidas: a Centelha fecha com vencedor, com dois e com um jogador.

## Ao terminar

- Marque a H04 como **feito** no [quadro](README.md), com o commit e o gasto
  real. As fichas de seção (I a Q) passam a poder começar.
- Commit sugerido (sem trailer):
  `feat: o kit do minigame — a ficha de dados, o catálogo e A Centelha morando no kit`

## O que foi feito (leva 1, o-kit)

**O que entrou:** `Minigame` (`godot/scripts/minigames/minigame.gd`), o
`Catalogo` (`catalogo.gd`) no lugar do `SALAS` do `main.gd`, e A Centelha
morando no kit como `S01_J01`, «O Martelo de Hefesto», verbo «Bata!»
(`godot/scripts/minigames/s01/martelo_de_hefesto.gd`; a sala antiga saiu de
`godot/scripts/salas/`). O minigame de prova do kit é
`godot/testes/minigame_de_prova.gd`. Os ids antigos (`centelha`, `viga`…)
seguem abrindo em `--sala=`, na Prova de Fogo e na partida, como apelidos.

**Onde o kit ficou diferente do passo 2 (porque a `SalaJogo` já faz):** os
eventos `minigame` e `desempenho`, `var minigame`, `desempenho`,
`var colocacao` e `vencedor()` (com o desempate pelo lugar) são da
`SalaJogo`; o kit não os repete. O `terminar()` do kit só solta o relógio
(`Ritmo.parar()`), e o `_process` só chama `robo(l, dt)` antes do da
`SalaJogo`. Acrescentado ao kit: `ICONE_DA_PARTE` (sem ele o aviso perdia o
glifo da Centelha) e a laje da raia na cor `Tema.PAINEL`.

**Provas:** `bash tests/prova_do_jogo.sh` ganhou `_prova_do_catalogo` (os
apelidos, os ids de hoje, a FICHA completa e a FICHA quebrada reprovada) e
`_prova_do_kit` (quatro lugares, um por julgamento, o cabo do P3 que sai e
volta, o fim pelo próprio jogo, a colocação pelos pontos, o relógio solto);
no relatório, os quatro julgamentos do minigame de prova e todo minigame
jogado terminando com vencedor. Medido antes e depois: a base tinha só o
flake de tempo «relógio sem faixa»; depois, a prova inteira verde. Mordidas:
sem `ICONE_DA_PARTE`, sem o registro do toque, sem o `Ritmo.parar()` e sem a
conferência da FICHA, a prova reprova cada defeito (e volta ao verde ao devolver).

**Para a mão dela / do André:** `scripts/gauntlet.sh`,
`bash tests/prova_de_poucos.sh`, `./run-local.sh -- --sala=centelha`, e a
prancha das partidas com dois e com um jogador. Jogar a Centelha na mão e ver
o aviso com o glifo, as runas, o vencedor, o título «O Martelo de Hefesto» e o
verbo «Bata!».

**Cuidado conhecido:** a prova do kit (e o «relógio sem faixa», que já era
assim) mede pelo relógio de parede; com a máquina sob carga forte (outro jogo
ou outro Godot com janela), o quadro engasga e as notas saem erradas. Rode com
a máquina calma.

**A prova visual da leva:** nas partidas com dois e com um jogador (passada
fixa), a Centelha fecha com vencedor: título «O Martelo de Hefesto», verbo
«Bata!», runas, «P1 venceu» e o placar «Depois d'A Centelha» (a partida fala
pela seção). A prancha mostrou o título novo encavalado com a dica
«Continuar» na tela de resultado (`godot/scripts/ui/resultado.gd`). **Isso
fica aberto:** a linha do título é a mesma que a F09b e a G14 trocam no
conjunto da fita (a fonte e o tamanho da bíblia), e o arquivo não é desta
ficha; o encolhimento medido com a fonte de hoje foi tirado para não brigar
na costura. A cura vai depois da fita, medida com a letra nova. O resto das
reprovações da prova visual (letra abaixo de 30 px, área segura, contraste,
tela parada) é o que a [F09b](F09b-os-achados-da-prova-visual.md) já lista;
as quatro partidas nas duas passadas não rodaram (cada partida levou dezenas
de minutos com a máquina carregada).

**A conferência:** a prova do relatório conta o minigame que **começou** e
terminou (antes contava pela duração maior que zero, o que deixava de fora a
Centelha da Prova de Fogo, que começa e fecha no treino); a prova da partida
confere que o placar guarda a sala pelo apelido, não pelo slot (mordida:
`partida.registrar(sj.id, ...)` no `main.gd` reprova, e antes passava). A
prova de poucos rodou na caixa: verde com um, dois e três controles, os
ritmos, as opções e o cabo que cai. Sob carga (load 25 a 30 em 16 núcleos),
a prova do kit reprova às vezes no P1 ou no P2: o atraso medido entre o
aperto do robô e o julgamento chegou a 70 ms (calma: 1 a 19 ms), e a janela
do ótimo tem 25 ms de folga de cada lado da mira.
