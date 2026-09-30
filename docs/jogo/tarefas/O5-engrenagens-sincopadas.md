# O5 — Engrenagens Sincopadas

**Sprint:** O · **Slot:** S07_J35 · **Tamanho:** M · **Estimativa:** US$ 1,5 · **Depende de:** H04, F09, H07, G03, G05, O1

## Por quê

A dupla da seção. Duas torres de engrenagens; cada dupla sobe alternando
saltos na síncope. Os dentes da engrenagem passam sob a mão — três cliques —
e o salto é no vão que vem depois: no "e" do 2 para um, no "e" do 4 para o
outro. A dupla divide o acorde (fundamental e quinta, o princípio 3) e só
sobe se os dois encaixam.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) e [o kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A ficha-mãe da seção](O-os-caminhos.md) e a [O1](O1-os-caminhos.md) (o `_pista`, o `_respondeu`, a troca)
- [A ficha-mãe d'A Prova](Q-a-prova.md), "As equipes" (a mesma regra de duplas, as mesmas cores)
- A G03 (`usa_gatilho`) e a G05 (a câmera `grupo`)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S07_J35",
	"titulo": "Engrenagens Sincopadas",
	"verbo": "Encaixe!",
	"genero": "2v2",
	"icone": "haptica",
	"entradas": [Forja.CRUZ],
	"camera": "grupo",
	"faixa": "MUS_S07_J35",
	"duracao": 90.0,
	"fim": "primeiro_a_chegar",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "metal",
	"microjogo": {"verbo": "Encaixe!", "segundos": 6.0},
	"gesto": "jump",
}
```

## Como se joga

A faixa é `MUS_S07_J35`, 130 bpm (uma batida ≈ 0,46 s). `ENTRADA := 4`.

- **As equipes** (a regra da ficha-mãe d'A Prova): `presentes()` na ordem;
  os dois primeiros são a **Brasa** (âmbar `#e8a33c`), os dois seguintes a
  **Maré** (turquesa `#2fb3b3`). Em cada equipe, o primeiro é **A** e o
  segundo **B**. Falta gente: o **Aprendiz** (um boneco do jogo, não um
  jogador) completa a dupla — ver "Com menos de quatro".
- **Um compasso** (4 batidas, a partir de `c0 = ENTRADA + 4 * m`):

  | batida | A | B |
  | --- | --- | --- |
  | `c0`, `c0 + 0.5`, `c0 + 1.0` | três cliques dos dentes na mão (`material:metal`, dois atuadores, ganho 0,8) | — |
  | `c0 + 1.5` | **o salto** (a nota) | — |
  | `c0 + 2`, `c0 + 2.5`, `c0 + 3.0` | — | três cliques na mão |
  | `c0 + 3.5` | — | **o salto** (a nota) |

  O primeiro clique de cada salto vai pelo `_pista` (`o_que` = `"encaixe"`);
  os outros dois, `Forja.som_haptica` direto. O vão depois do terceiro clique
  é o encaixe: a mão conta "um, e, dois" e salta no "e".
- **As duas equipes jogam ao mesmo tempo**, cada uma na sua torre: os A das
  duas saltam juntos no "e" do 2, os B no "e" do 4. A nota de cada lugar
  soa na TV (kit): A e B de uma dupla fazem fundamental e quinta.
- **A entrada:** ✕. A nota do salto é aberta com `nova_nota` no primeiro
  clique e julgada com `julgar_toque(l, Ritmo.t_da_batida(c0 + 1.5), n, true)`
  (a engrenagem é perigo físico). Sem ✕ até a nota passar →
  `nota_perdida(l, n)`.
- **A subida:** cada salto julgado sobe a **equipe** uma engrenagem
  (`_altura[e] += 1`); `marcar(l, [0, 50, 75, 100][j])`.
- **A meta:** `META := 16` engrenagens.
- **A partitura simples** (`Ritmo.simples[l]`): o lugar salta só nos
  compassos pares; nos ímpares, nem clique nem nota para ele.
- **O pico — a engrenagem-mestra:** os 4 compassos a partir de
  `_pico_m := floor((duracao / _t_batida() - ENTRADA) / 4 / 2)`: A e B saltam
  **juntos** nas duas síncopes (`c0 + 1.5` e `c0 + 3.5`), cada um com os seus
  cliques e a sua nota. Cada salto certo sobe 1, como sempre; quando os
  **dois** da dupla acertam a mesma síncope, a equipe sobe **mais 1**
  (`_acertou_no_pico["%d:%d:%d" % [m, s, e]]` conta os acertos daquela
  síncope; no segundo, `_subir(e, 1)` extra). A TV: `Som.tocar("sobe")` na
  entrada do pico.

## O cenário

- **Chão:** `Kit.arena(self, 5, 3)`. Sem as raias do kit (a dupla sobe na
  torre): o minigame **não** chama `raia(l)` nem `posicionar(l)`.
- **As torres:** Brasa em `x = -3.6`, Maré em `x = 3.6`, `z = -1.0`. Cada
  torre: um eixo `Kit.caixa(self, Vector3(0.4, ALTURA_ENG * (META + 2), 0.4), ...)`
  de ferro `#3b3f4c`; `META + 1` engrenagens, uma a cada `ALTURA_ENG := 0.9`
  de altura, cada uma `Kit.cilindro(no, 1.1, 0.25, Vector3.ZERO, ferro)` (8
  lados, G08) com 8 dentes `Kit.caixa(no, Vector3(0.3, 0.25, 0.3), <no raio 1.2, a cada 45°>, ferro)`
  (`ferro := Kit.material(Color("#5b6275"), 0.0, 0.6)`, `metallic` 0,2). Cada
  engrenagem gira: `rotation.y = (1 if nivel % 2 == 0 else -1) * Ritmo.batida() * PI / 4`
  (pela batida).
- **A cor da equipe, no mundo:** uma laje `Kit.caixa(self, Vector3(3.0, 0.03, 3.0), Vector3(x_torre, 0.02, -1.0), cor_equipe)`
  na base da torre e um disco `Kit.cilindro(self, 0.55, 0.03, ..., cor_equipe)`
  sob os pés de cada cavaleiro (acompanha o boneco); as engrenagens já
  subidas ganham um anel de dentes na cor da equipe (troca o material dos
  dentes, sem emissivo). A barra de luz fica na cor do **lugar**.
- **Os cavaleiros:** A em `x_torre - 0.9`, B em `x_torre + 0.9`, na altura
  `ALTURA_ENG * _altura[e] + 0.15`, de frente para a câmera
  (`rotation.y = 0`), `p.preso = true`. O salto: `p.gesto("jump", 0.35)` e a
  altura anda por `lerpf` na meia batida depois do salto (pela batida).
- **O Aprendiz** (quando falta alguém): `load("res://assets/kenney/character-orc.glb").instantiate()`,
  `scale = Vector3.ONE * ForjaPlayer.ESCALA`, tingido de `#b9a98a` (o
  `_tingir` de `prova.gd:199-209`, copiado), no lugar do membro que falta;
  anima pelo `AnimationPlayer` dele (`jump`, `idle`).
- **A luz:** a da casa: `luzes([Vector3(-8, 3, 3), Vector3(8, 3, 3)])`,
  `atmosfera(Color("#ffb070"), Tema.CIANO, true, 40, 22.0, -7.8, 0.3)`.
- **A câmera:** `camera: "grupo"` (G05 enquadra os cavaleiros subindo);
  `camera_pos = Vector3(0, 5.5, 13.0)`, `camera_olhar = Vector3(0, 3.0, -1.0)`
  no começo do `montar()`, para antes da G05.
- **Checklist de arte (11):** engrenagens de 8 lados em blocos; `metallic`
  0,2; as cores das equipes não são as dos lugares (âmbar e turquesa); o
  Aprendiz é boneco do kit tingido de areia; a prancha com os cavaleiros nas
  torres.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **háptica (protagonista)** | os três cliques dos dentes (`material:metal`), o vão é o encaixe | antes de cada salto do lugar |
| háptica por material | o encaixe: o kit toca `material:metal` | no toque |
| barra de luz | a cor do lugar | — |
| alto-falante do dono | a nota dele (kit); `Forja.som_falante(l, "coleta", 0.7)` a cada 4 engrenagens da equipe (os dois ouvem) | no marco |
| vibração | o kit; a queda de engrenagem: `Forja.sentir(l, "golpe")` | na falha |
| **gatilho** | a mão na engrenagem: `Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, 3)` (R2) o jogo inteiro; `usa_gatilho = true` no `montar()` (o L2 fica com o item, G03) | do começo ao fim |
| TV | a música da máquina engasgando; a nota de cada um (kit); `Som.tocar("martelo", pos, -6.0)` no escorregão; `Som.tocar("portao")` no topo | — |

**No rádio:** os cliques viram `Forja.sentir(l, "toque")`; a `troca` gravada
uma vez. O microfone não é usado.

## A falha

**Salta fora do encaixe** (erro ou nota perdida): o cavaleiro bate no dente,
`p.gesto("fall", 0.5)`, e a **equipe escorrega uma engrenagem**
(`_altura[e] = maxi(0, _altura[e] - 1)`); os dois sentem o golpe; faíscas
na cor da equipe no dente. **A recuperação:** o próximo salto já sobe.

## O fim e o vencedor

A primeira equipe com `_altura[e] >= META` chega ao topo: `Som.tocar("portao")`,
os dois fazem `emote-yes`, e todos acabam no fim daquele compasso. Sem
chegada, o kit fecha no `duracao`. **O vencedor:** a equipe mais alta (no
empate, a de mais pontos somados); `vencedor()` devolve os lugares da equipe
vencedora (pelos pontos) e depois os da outra.

## Com menos de quatro

- **Três:** Brasa = os dois primeiros; Maré = o terceiro (A) + o Aprendiz (B).
- **Dois:** Brasa = o primeiro + o Aprendiz; Maré = o segundo + o Aprendiz.
- **Um:** Brasa = ele + o Aprendiz; Maré = dois Aprendizes.
- **O Aprendiz** salta nos tempos dele e acerta com `ACERTO_APRENDIZ := 0.8`
  (sorteado com o `rng` do kit): acerto sobe a equipe 1, erro desce 1. Não é
  lugar, não marca pontos, não entra na colocação nem no registro de notas.
- **O controle que cai:** as notas dele não abrem (nem cliques); a equipe
  segue com o outro; ninguém o substitui. Quando volta, entra no próximo
  compasso.
- `com_poucos()`: `"Com o Aprendiz"` quando há Aprendiz.

## O robô

Pelo relógio da música: o salto é na síncope, sempre no mesmo lugar do
compasso.

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var n: int = _nota[l]
	if n < 0 or _robo_apertou[l] == n:
		return
	if _robo_nota[l] != n:
		_robo_nota[l] = n
		# quando não acerta, salta no tempo (sem a síncope) ou atrasado
		_robo_mira[l] = 0.0 if Forja.robo_acerta() else (-0.23 if _robo_rng.randf() < 0.5 else 0.25)
	if Ritmo.t_musica() >= float(_alvo[l]) + float(_robo_mira[l]):
		Forja.robo_apertar(l, Forja.CRUZ, 0.05)
		_robo_apertou[l] = n
```

## Os ganchos

`godot/scripts/minigames/s07/engrenagens_sincopadas.gd`, `extends Minigame`.

```gdscript
extends Minigame
## Engrenagens Sincopadas (S07_J35). Duas duplas escalam duas torres de
## engrenagens. Três cliques dos dentes na mão, e ✕ no vão que vem depois — o
## "e" do 2 para um, o "e" do 4 para o outro: cada encaixe sobe a dupla.
##
## A falha: bate no dente e a dupla escorrega uma engrenagem. O vencedor: a
## primeira dupla no topo (ou a mais alta). O alto-falante do dono: a coleta a
## cada quatro engrenagens. O registro mede: os cliques (pista) e o salto
## depois deles, por controle. O robô: salta na síncope pelo relógio. Com
## menos de quatro: o Aprendiz completa a dupla. A régua: a síncope se sente
## na mão antes de se ouvir.

const FICHA := { ... }

const ENTRADA := 4
const META := 16
const ALTURA_ENG := 0.9
const PONTOS := [0, 50, 75, 100]
const ACERTO_APRENDIZ := 0.8
const X_TORRE := [-3.6, 3.6]
const COR_EQUIPE := [Color("#e8a33c"), Color("#2fb3b3")]   ## Brasa, Maré
const SINCOPE := [1.5, 3.5]   ## o salto de A e de B no compasso

var _equipe := {}             ## lugar -> 0 (Brasa) ou 1 (Maré)
var _papel := {}              ## lugar -> 0 (A) ou 1 (B)
var _aprendiz := [[], []]     ## equipe -> os papéis (0/1) que o Aprendiz faz
var _altura := [0, 0]
var _m_feito := -1            ## o último compasso já aberto
var _nota := [-1, -1, -1, -1]
var _alvo := [0.0, 0.0, 0.0, 0.0]
var _n := [0, 0, 0, 0]
var _cliques := [[], [], [], []]   ## as batidas dos cliques que faltam mandar
var _acertou_no_pico := {}    ## "m:s:e" -> quantos da equipe acertaram aquela síncope
var _chegou := -1             ## a equipe que chegou
var _fim_batida := -1.0
var _pico_m := 999
var _rumble := [false, false, false, false]
var _fora := [false, false, false, false]
var _nos := {}
var _robo_nota := [-1, -1, -1, -1]
var _robo_apertou := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	papel_som = Forja.PAPEL_HAPTICA
	usa_gatilho = true
	camera_pos = Vector3(0, 5.5, 13.0)
	camera_olhar = Vector3(0, 3.0, -1.0)
	_formar_equipes()             # a regra de "As equipes" e de "Com menos de quatro"
	# as torres, as lajes da equipe, os discos, os Aprendizes


func iniciar_jogo() -> void:
	_pico_m = int(floor((duracao / _t_batida() - ENTRADA) / 4.0 / 2.0))
	for l in presentes():
		Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, 3)
		# o rádio: _rumble e a troca (o O1)


func jogar(_dt: float) -> void:
	var b := Ritmo.batida()
	var m := int(floor((b - ENTRADA) / 4.0))
	if b >= ENTRADA and m > _m_feito:
		_m_feito = m
		_abrir_compasso(m)        # agenda os cliques e abre as notas de quem salta neste compasso
	for l in presentes():
		if not conectado(l):
			_fora[l] = true
			_nota[l] = -1
			_cliques[l].clear()
			continue
		_fora[l] = false
		_mandar_cliques(l, b)     # o primeiro pelo _pista, os outros direto
		if _nota[l] >= 0:
			if Forja.apertou(l, Forja.CRUZ):
				var n: int = _nota[l]
				_nota[l] = -1
				julgar_toque(l, float(_alvo[l]), n, true)
			elif Ritmo.t_musica() > float(_alvo[l]) + Ritmo.JANELA_BOM:
				var n2: int = _nota[l]
				_nota[l] = -1
				_respondeu(l, n2, "nenhuma")
				nota_perdida(l, n2)
	_aprendizes(b)                # os saltos do Aprendiz, na síncope dele
	if _fim_batida > 0.0 and b >= _fim_batida:
		for l in presentes():
			acabou[l] = true
	_mostrar(b)


func toque(l: int, j: int) -> void:
	marcar(l, PONTOS[j])
	_respondeu(l, _n[l] - 1, "certo")
	_subir(_equipe[l], 1)         # e, no pico, o extra quando os dois acertam a mesma síncope


func falha(l: int) -> void:
	jogador(l).gesto("fall", 0.5)
	_subir(_equipe[l], -1)
	for o in presentes():
		if _equipe.get(o, -1) == _equipe[l] and conectado(o):
			Forja.sentir(o, "golpe")


func vencedor() -> Array:
	var e := _chegou
	if e < 0:
		e = 0 if _altura[0] > _altura[1] else (1 if _altura[1] > _altura[0] else _mais_pontos())
	var primeiro := presentes().filter(func(l): return _equipe[l] == e)
	var outro := presentes().filter(func(l): return _equipe[l] != e)
	primeiro.sort_custom(func(a, b): return pontos[a] > pontos[b])
	outro.sort_custom(func(a, b): return pontos[a] > pontos[b])
	return primeiro + outro
```

`_subir(e, d)`: `_altura[e] = clampi(_altura[e] + d, 0, META)`; o marco da
coleta a cada 4; se chegou a `META` e `_chegou < 0`: `_chegou = e`,
`_fim_batida = ENTRADA + 4 * (_m_feito + 1)` (o fim do compasso).
`_mais_pontos()`: a equipe com mais pontos somados (0 no empate).
`_abrir_compasso(m)`: para cada lugar conectado cujo papel salta neste
compasso (os dois papéis no pico; só os compassos pares com
`Ritmo.simples[l]`): os três cliques em `c0 + SINCOPE[papel] - 1.5`, `- 1.0`,
`- 0.5`, e a nota `_n[l]` com alvo `Ritmo.t_da_batida(c0 + SINCOPE[papel])`
(`nova_nota` aberta já, `_nota[l] = _n[l]`, `_n[l] += 1`). No pico, cada
lugar tem duas notas no compasso: abra a segunda quando a primeira fechar
(guarde a fila em `_fila[l]`). `_aprendizes(b)`: para cada papel que o
Aprendiz faz, na batida da síncope, sorteia com `rng` e sobe ou desce a
equipe (sem nota, sem registro de toque), e anima o boneco dele. O `_pista`
e o `_respondeu` são os do O1.

Dica: `["@cross"]` sob o cavaleiro enquanto `not aprendeu(l)` (a `pos` da
dica é o pé do boneco, `jogador(l).global_position`). `status(l)`:
`"Brasa %d" % _altura[0]` ou `"Maré %d" % _altura[1]`.

Catálogo: `"S07_J35"` em `MINIGAMES` e na seção `S07`. Traduções:
`"Engrenagens Sincopadas": "Syncopated Gears"`, `"Encaixe!": "Lock in!"`,
`"Brasa %d": "Ember %d"`, `"Maré %d": "Tide %d"`, `"Com o Aprendiz": "With the Apprentice"`.

`_t_batida()` (a duração de uma batida, em s, para o pico):
`return Ritmo.t_da_batida(1.0) - Ritmo.t_da_batida(0.0)`.

## O que o registro mede

- `pista` `mandou` do primeiro clique de cada salto (`via`) e `respondeu`
  (`certo`/`nenhuma`); o `toque` com o desvio de cada salto na síncope — a
  noite compara o desvio na síncope entre cabo e rádio;
- `saida` do gatilho R2 (a resistência leve) de cada um, uma vez;
- `troca` no rádio.

## Armadilhas

- **O robô sorteia no dele.** `var _robo_rng := RandomNumberGenerator.new()`, com
  `_robo_rng.seed = rng.seed + 99` no `iniciar_jogo()`: o `rng` do kit é do jogo
  (os caminhos, os lados, o Aprendiz), e o robô não pode mudar o que o jogo sorteia
  (a paridade: com robô ou com gente, o mesmo jogo).
- **O Aprendiz não é robô.** É regra do jogo (como os bonecos de treino
  d'A Prova): nada de `Forja.robo` nele, nada de controle simulado.
- **Não chame `raia(l)`/`posicionar(l)`:** os cavaleiros estão nas torres;
  o kit não os põe de volta nas raias.
- **O gatilho no R2 só:** o L2 é do item (G03). `usa_gatilho = true` no
  `montar()`, antes de o kit começar.
- **As cores das equipes** (âmbar e turquesa) são só do mundo; nunca
  `Forja.luz` com elas.
- **Na prova o pico não chega** (o fim é pelo `duracao`).
- **`ENTRADA`**: se o kit tiver `BATIDA_DA_PRIMEIRA_NOTA`, use-a.

## Pronto quando

Joga do aviso ao resultado com 4, 3, 2 e 1 jogador (com o Aprendiz) e com o
robô nos três temperamentos; aguenta o cabo que cai e volta; fecha com
vencedor (uma equipe); o R2 fica em resistência e o L2 com o item; a prova
do jogo passa; e `bash tests/prova_visual.sh` passa com a prancha olhada (as
duas torres, os cavaleiros subindo, a câmera acompanhando).

## Provas

Em `godot/testes/prova_do_jogo.gd`, uma `_prova_engrenagens()`:

```gdscript
## S07_J35: os cliques chegam à mão dos quatro, o R2 de cada um fica em
## resistência (0x21), as duas equipes sobem, e fecha com vencedor.
func _prova_engrenagens() -> void:
	var sala = await _comeca_a_sala("S07_J35")
	if sala == null:
		return
	await _quadros(4)
	for l in 4:
		_esperar(int(_perc(l).get("gatilho_dir", 0)) == 0x21, "engrenagens P%d: o R2 em resistência" % (l + 1))
	var sentiu := [false, false, false, false]
	var q := 0
	while is_instance_valid(sala) and sala.fase == "jogo" and q < 12000:
		for l in 4:
			if float(Forja.som_virtual(l).get("esq", 0.0)) > 0.05:
				sentiu[l] = true
		await _quadros(1)
		q += 1
	_esperar(sentiu.all(func(s): return s), "engrenagens: os cliques chegaram aos quatro %s" % [sentiu])
	_esperar(is_instance_valid(sala) and sala.fase == "fim", "engrenagens: fechou")
	if is_instance_valid(sala):
		_esperar(sala._altura[0] + sala._altura[1] >= 1, "engrenagens: alguém subiu (%s)" % [sala._altura])
		var c: Array = sala.colocacao
		_esperar(c.size() == 4 and sala._equipe[c[0]] == sala._equipe[c[1]], "engrenagens: os dois primeiros são da mesma equipe (%s)" % [c])
```

`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**Com o André (local):** `./run-local.sh -- --sala=S07_J35`, com duas duplas.
Os três cliques têm de ensinar a síncope sem explicação; o salto em dupla no
pico tem de dar vontade de gritar; com três jogadores, o Aprendiz não pode
ser nem inútil nem imbatível.

## Ao terminar

- No [quadro](README.md), a linha O5: **feito**, com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: Engrenagens Sincopadas — a dupla sobe no vão dos dentes`
