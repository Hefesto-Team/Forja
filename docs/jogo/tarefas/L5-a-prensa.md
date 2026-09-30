# L5 — A Prensa

**Sprint:** L · **Slot:** S04_J20 · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 1,5 · **Depende de:** H04, H08, F09, L1

## Por quê

O terror da seção. Luz baixa, prensas de ferro no escuro em cima de cada
raia, e a mão que avisa um tempo antes: a prensa vai descer **em você**.
Na entrada basta sair de baixo; no meio, descem duas e a mão diz também
**para que lado** fugir. Quem é esmagado três vezes vira fantasma e passa a
acender a luz no caminho dos outros. O verbo da vibração aqui é
**esquivar**: o corpo inteiro (o analógico) sai do lugar.

## Ler antes

- [O índice da seção](L-o-impacto.md) e a [L1](L1-o-cerco.md) (o cenário comum com `escuro`, a lanterna da vida, o `_joga_o_minigame`)
- [O molde de minigame](molde-de-minigame.md) e o [kit](../13-arquitetura.md#o-kit-do-minigame--h04)
- [Os princípios](../02-principios.md#6-a-falha-é-física) (quem cai continua como fantasma)

## A ficha de dados

`godot/scripts/minigames/s04/a_prensa.gd`:

```gdscript
extends Minigame
## A Prensa (S04_J20) — cada raia tem três lugares (esquerda, meio, direita)
## e uma prensa no escuro em cima de cada um. Na batida do dono, a prensa
## desce onde ele está; a mão avisa uma batida antes. Esquive com o
## analógico esquerdo (um toque para um lado) na batida. No pico e na saída,
## descem duas e a pista diz o lado seguro: só o motor da esquerda, fuja
## para a esquerda; só o da direita, para a direita.
##
## A falha: esmagado — o cavaleiro fica achatado por uma batida e perde uma
## brasa; na terceira, vira fantasma (caído, com uma lanterna flutuando).
## O vencedor: o último sem ser esmagado três vezes; depois, quem tem mais
## vida; os fantasmas pela ordem em que caíram (quem caiu depois, na frente).
## O alto-falante do dono: o esmagamento ("golpe").
## O registro mede: cada pista (os dois motores, ou o lado seguro) e para
## onde o cavaleiro foi, no tempo; esquiva para o lado errado com a pista
## de um lado só é o motor que não chegou.
## O robô: sente a pista (os dois motores: qualquer lado; um só: aquele lado)
## e esquiva na batida seguinte; quando não acerta, 250 ms tarde.
## Com menos de quatro: as batidas se dividem; sozinho, só as pares, e o
## minigame vai até o fim dos 90 s.
## A régua: (1) "Esquive!" com as prensas descendo no aviso; (2) sim: no
## escuro, a mão avisa antes do olho; (3) não pergunta nada.

const FICHA := {
	"slot": "S04_J20",
	"titulo": "A Prensa",
	"verbo": "Esquive!",
	"genero": "sobrevivencia",
	"icone": "rumble_esquerdo",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S04_J20",
	"duracao": 90.0,
	"fim": "ultimo_em_pe",
	"sensacoes": ["golpe", "golpe_esq", "golpe_dir", "explosao", "acerto", "perfeito", "erro"],
	"material": "metal",
	"microjogo": {"verbo": "Esquive!", "segundos": 6.0},
	"gesto": "lados",
}

const PONTOS := [0, 40, 70, 100]  ## ERRO, BOM, OTIMO, PERFEITO
const LUGARES_X := [-1.3, 0.0, 1.3]  ## os três lugares da raia, somados a RAIAS[l]
const VIDA_MAX := 3
const BRILHO := [0.4, 0.45, 0.7, 1.0]  ## a barra de luz por vida (0 = fantasma: o piso)
const FANTASMA_LUZ := 20  ## o fantasma que acende a luz no tempo
const ESCURO := 0.35  ## o cenário comum escurecido (o terror)
const ESCURO_SAIDA := 0.25
const LX_VAI := 0.6
const LX_VOLTA := 0.3
## A chance de prensa na batida do dono: entrada, pico, saída.
const DENSIDADE := [0.6, 1.0, 1.0]
```

## Como se joga

**O dono da batida** é o do Cerco (L1): `presentes()` vivos e fantasmas, em
ordem, `lista[b % k]`; sozinho, só as pares. O fantasma continua dono das
batidas dele (é nelas que ele acende a luz). A contagem é o compasso 0; a
geração, um compasso antes.

**A nota do vivo:** `{"n": b, "b": b, "t": Ritmo.t_da_batida(b), "avisada": false, "caem": [], "seguro": -1}`,
com `nova_nota(l, b, t)`. **Na pista** (`b − 1`), a nota decide onde caem as
prensas, pelo lugar em que o cavaleiro está **agora** (`pos[l]` 0, 1 ou 2):

| parte | música (`progresso()` do kit) | caem | a pista (`Forja.sentir`, `ms = 0,4 batida`) |
| --- | --- | --- | --- |
| entrada | 0–30 s | só `pos[l]` | `"golpe"` (os dois motores: fuja para qualquer lado) |
| **pico** | 30–60 s | no meio (`pos == 1`): o meio e um lado sorteado; num canto: só o canto | meio: `"golpe_esq"` se o seguro é a esquerda, `"golpe_dir"` se é a direita; canto: `"golpe"` |
| saída | 60–90 s | como no pico; a luz cai para `ESCURO_SAIDA` | como no pico |

O `seguro` é o lugar para onde a pista manda (no `"golpe"`, qualquer lugar
fora de `caem`). Registro:
`Forja.evento("pista", l + 1, {"slot": id, "n": b, "evento": "mandou", "via": "rumble", "o_que": "ambos"/"esq"/"dir", "ok": ok})`.
Quem está com `Ritmo.simples[l]` recebe só a regra da entrada.

**A esquiva:** o analógico esquerdo passando de `LX_VAI` (±0,6) para um lado,
rearmando abaixo de `LX_VOLTA`. O cavaleiro pula para o lugar vizinho
daquele lado na hora (`gesto("jump", 0.3)`, tween de x em 0,12 s); para
fora da raia (do canto para a parede), ele bate e não sai.

- **Com uma nota avisada e ainda não resolvida:** se o toque está a até
  `FOLGA_PERDIDA` do tempo → a esquiva é julgada.
  O lugar novo fora de `caem` → `julgar_toque(l, t, n, true)` (é perigo: a
  folga de quem está em último); dentro de `caem` (o lado errado, ou a
  parede) → `nota_perdida(l, n)`. Fora da janela, depois da pista → cedo
  demais: `nota_perdida(l, n)` (a prensa corrige o rumo e desce onde ele
  foi). Grave a linha `entrada` `{"o": "resposta", "n": b, "lado_pedido": ..., "lado_feito": "esq"/"dir"}`.
- **Sem nota avisada:** o cavaleiro só muda de lugar, sem julgamento
  (reposicionar entre as prensas vale).
- A nota que passa de `t + FOLGA_PERDIDA` (o kit) sem esquiva é `nota_perdida(l, n)`.

Um julgamento ERRO (a esquiva no lugar certo, mas fora do tempo) também é
esmagamento: é o `falha()` do kit.

**As prensas descem pela batida:** a cabeça da prensa do lugar `x` fica em
`y = 3.2` e, para cada nota que a tem em `caem`, desce de `b − 0,25` a `b`
até `y = 0.25`, fica até `b + 0,5` e sobe até `b + 1,5`.

**O fantasma** (vida 0): nas batidas dele, ✕ a até `JANELA_BOM` da batida →
a luz acende por uma batida (`_luz_do_fantasma` de 0,6 a 2,0 de energia e a
cabeça de todas as prensas com emissivo 0,8) e `marcar(l, FANTASMA_LUZ)`.
Sem julgamento do kit (não é nota) e sem erro. Os pontos do fantasma não
mudam a colocação.

**Os pontos:** `marcar(l, PONTOS[julgamento])` (o item, `Itens.pontos_do_acerto`, o kit já aplica no `julgar_toque`: H08).

## O cenário

- `CenarioDoImpacto.montar(self, ESCURO)`; aos 60 s, as luzes do cenário vão
  para `ESCURO_SAIDA` em um compasso (guarde as três `OmniLight3D` que o
  `montar` pôs: `get_children()` filtradas por tipo, logo depois de montar).
- A câmera d'O Impacto, um pouco mais alta para as prensas:
  `camera_pos = Vector3(0, 7.0, 11.2)`, `camera_olhar = Vector3(0, 1.4, -0.4)`.
- Por lugar: `raia(l)` com `acender_raia(l, 0.35)` sempre (a única luz
  perto do cavaleiro), `posicionar(l)`, `preso = true`, `rotation.y = 0.0`,
  `pos[l] = 1` (o meio), e a lanterna da vida:
  `CenarioDoImpacto.lanterna(self, Vector3(RAIAS[l] + 1.9, 0, Z_JOGADOR + 0.6), Forja.cor_do_lugar(l), VIDA_MAX)`.
- **As prensas** (três por raia): para cada `x` de `LUGARES_X`, um `Node3D`
  em `(RAIAS[l] + x, 3.2, Z_JOGADOR)` com o pistão
  `Kit.caixa(p, Vector3(0.22, 3.0, 0.22), Vector3(0, 1.75, 0), Kit.material(Color("#3a3a44"), 0.0, 0.6))`
  e a cabeça `Kit.caixa(p, Vector3(1.1, 0.5, 1.1), Vector3.ZERO, mat)` com
  `mat = Kit.material(Color("#4a4e5e"), 0.0, 0.7)` (o emissivo liga só na
  luz do fantasma). Em cima, uma viga `Kit.peca(self, "wood-structure", Vector3(RAIAS[l], 5.2, Z_JOGADOR), 0.0, 2.0)`.
- **A luz do fantasma:** uma `OmniLight3D` `_luz_do_fantasma`, `#b9b0ff`, em
  `(0, 6.0, Z_JOGADOR)`, alcance 24, energia 0.
- O checklist do 11: caixas foscas; o terror escurece a luz da casa, não troca.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **vibração (protagonista)** | `golpe` (qualquer lado) / `golpe_esq` / `golpe_dir` (o lado seguro), 0,4 batida | a pista, em `b − 1`, só no dono vivo |
| vibração | `acerto` / `perfeito` / `erro` (o kit) | na esquiva julgada |
| vibração | `explosao` | esmagado |
| barra de luz | `CenarioDoImpacto.luz_com_brilho(l, BRILHO[vida])` | ao começar e a cada vida perdida (o fantasma fica no piso de 40%) |
| barra de luz | o kit escurece a cor no erro (H08); 0,5 s depois, `_piscar` põe o brilho da vida, um degrau abaixo | esmagado |
| barra de luz | o kit (`_reagir`, H08): branco no perfeito, a cor do lugar escurecida no erro | no toque julgado |
| luzinhas de jogador | o número, sempre (também o fantasma) | — |
| alto-falante do dono | `Som.no_controle(l, "golpe", 0.8)` | esmagado |
| alto-falante do dono | `Forja.som_falante(l, "coleta", 0.6)` | o fantasma acende a luz |
| gatilho | `Forja.gatilho(l, 1, Forja.GATILHO_OFF)` no `montar` | nada a segurar; o L2 é do item |
| háptica por material | `"metal"` (o kit, na esquiva) | — |
| som na TV | `"pedra"` na prensa que bate no chão vazio; `"golpe"` no esmagamento | — |

## A falha

- **Esmagado:** a prensa bate; o cavaleiro fica achatado (`scale.y` 0,3 por
  uma batida, pela batida, e volta com um tween de 0,15 s), `gesto("fall", 0.6)`;
  `Forja.sentir(l, "explosao")`, a barra de luz escurece (o kit), `Som.no_controle(l, "golpe", 0.8)`,
  `Som.tocar("golpe", pos, 0.0)`, `tremer(TREMOR_EXPLOSAO)`; uma brasa da
  lanterna apaga (`CenarioDoImpacto.acender_lanterna(mats, vida)`). No
  treino, nada se perde.
- **A terceira:** o cavaleiro vira fantasma: `animar("die")` e fica caído;
  uma lanterna pequena da cor do lugar
  (`Kit.caixa(self, Vector3(0.2, 0.2, 0.2), pos + Vector3(0, 1.8, 0), Kit.material(Forja.cor_do_lugar(l), 2.0))`)
  flutua em cima dele (`y` sobe e desce com `sin(PI * Ritmo.batida())`);
  `caiu_em[l] = Ritmo.t_musica()`.
- **A recuperação:** entre uma nota e outra do mesmo lugar há pelo menos
  uma batida (o hoqueto); o fantasma continua jogando.

## O fim e o vencedor

`fim` `ultimo_em_pe`: com dois ou mais no começo, quando só resta um vivo,
todos `acabou`. Senão, os 90 s.

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if int(vida[a]) != int(vida[b]):
			return int(vida[a]) > int(vida[b])
		if int(vida[a]) == 0:
			return float(caiu_em[a]) > float(caiu_em[b])
		return int(pontos[a]) > int(pontos[b]))
	return lista
```

## Com menos de quatro

- **Três e dois:** a roda do dono; o último vivo acaba o minigame.
- **Um:** só as pares; o minigame vai até os 90 s (ou até a terceira
  esmagada: aí `acabou` e o kit fecha).
- **O controle que cai:** as prensas dele não descem enquanto está fora (as
  notas somem sem erro); a vida fica. Quem cai do controle não conta como
  vivo para o "último em pé" até voltar.

## O robô

```gdscript
# O robô sente a pista no controle simulado: os dois motores (o golpe, forte
# acima de 0,9 e fraco entre 0,4 e 0,8) é "saia", para o lado com espaço; um
# motor só é o lado seguro. Esquiva na batida seguinte, pelo relógio da
# música. O fantasma aperta ✕ nas batidas dele.
var _robo_ligado := [false, false, false, false]
var _robo_alvo := [-1.0, -1.0, -1.0, -1.0]
var _robo_para := [0, 0, 0, 0]  ## -1 esquerda, +1 direita
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	if int(vida[l]) == 0:
		_robo_fantasma(l)
		return
	var pc := Forja.percepcao(l)
	if pc.is_empty():
		return
	var forte := float(pc.get("forte", 0.0))
	var fraco := float(pc.get("fraco", 0.0))
	var para := 0
	if forte > 0.9 and fraco > 0.4 and fraco < 0.8:
		para = 1 if int(pos[l]) == 0 else (-1 if int(pos[l]) == 2 else (1 if rng.randf() < 0.5 else -1))
	elif forte > 0.3 and fraco < 0.05:
		para = -1
	elif fraco > 0.3 and forte < 0.05:
		para = 1
	var pista := para != 0
	if pista and not _robo_ligado[l] and _robo_alvo[l] < 0.0:
		_robo_alvo[l] = roundf(Ritmo.batida()) + 1.0
		_robo_para[l] = para
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 250 ms tarde
		_robo_atraso[l] = 0.0 if Forja.robo_acerta() else 0.25
	_robo_ligado[l] = pista
	if _robo_alvo[l] >= 0.0 and Ritmo.t_musica() >= Ritmo.t_da_batida(_robo_alvo[l]) + float(_robo_atraso[l]):
		Forja.robo_eixo(l, Forja.LX, float(_robo_para[l]), 0.1)
		_robo_alvo[l] = -1.0


## O fantasma: ✕ em toda batida dele, pelo relógio da música.
func _robo_fantasma(l: int) -> void:
	var b := ceilf(Ritmo.batida())
	if _dono(int(b)) == l and float(_robo_alvo[l]) != b and Ritmo.t_musica() >= Ritmo.t_da_batida(b) - 0.02:
		_robo_alvo[l] = b
		if Forja.robo_acerta():
			Forja.robo_apertar(l, Forja.CRUZ, 0.06)
```

(A `explosao` do esmagamento liga os dois motores cheios: o fraco acima de
0,8 a separa da pista `golpe`. As sensações do kit têm o forte abaixo de 0,9.)

## Os ganchos

```gdscript
var _notas := [[], [], [], []]
var _ultima := [{}, {}, {}, {}]
var _gerado := 1
var _fora := [false, false, false, false]
var pos := [1, 1, 1, 1]  ## o lugar do cavaleiro na raia: 0 esquerda, 1 meio, 2 direita
var vida := [VIDA_MAX, VIDA_MAX, VIDA_MAX, VIDA_MAX]
var caiu_em := [0.0, 0.0, 0.0, 0.0]
var _armado := [true, true, true, true]  ## o analógico voltou ao meio
var _prensas := {}  ## lugar -> [três Node3D]
var _lanternas := {}  ## lugar -> as brasas
var _comecaram := 0  ## quantos estavam presentes no começo
var _pisca := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	camera_pos = Vector3(0, 7.0, 11.2)
	camera_olhar = Vector3(0, 1.4, -0.4)
	CenarioDoImpacto.montar(self, ESCURO)
	_guardar_as_luzes_do_cenario()
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		acender_raia(l, 0.35)
		posicionar(l)
		p.preso = true
		_prensas[l] = _montar_as_prensas(l)
		_lanternas[l] = CenarioDoImpacto.lanterna(self, Vector3(RAIAS[l] + 1.9, 0, Z_JOGADOR + 0.6), Forja.cor_do_lugar(l), VIDA_MAX)
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


func iniciar_jogo() -> void:
	_comecaram = presentes().size()
	for l in presentes():
		CenarioDoImpacto.luz_com_brilho(l, BRILHO[vida[l]])


func jogar(dt: float) -> void:
	while _gerado <= int(floor(Ritmo.batida() / 4.0)) + 1:
		_gerar_compasso(_gerado)
		_gerado += 1
	var agora := Ritmo.t_musica()
	for l in presentes():
		_piscar(l, dt)
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_notas[l] = _notas[l].filter(func(nt): return float(nt.t) > agora)
		if int(vida[l]) == 0:
			_fantasma_joga(l)
			continue
		for nt in _notas[l]:
			if not nt.avisada and agora >= Ritmo.t_da_batida(float(nt.b) - 1.0):
				_avisar(l, nt)  # decide caem e seguro pelo pos[l] de agora; manda a pista
		var lx := Forja.eixo(l, Forja.LX)
		if _armado[l] and absf(lx) >= LX_VAI:
			_armado[l] = false
			_esquivar(l, 1 if lx > 0.0 else -1)
		elif absf(lx) <= LX_VOLTA:
			_armado[l] = true
		while not _notas[l].is_empty() and agora > float(_notas[l][0].t) + FOLGA_PERDIDA:
			var nt: Dictionary = _notas[l].pop_front()
			_ultima[l] = nt
			nota_perdida(l, int(nt.n))
	_mover_as_prensas()  # pela batida, de todas as notas avisadas
	_escurecer_na_saida()
	_conferir_o_ultimo_em_pe()


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	marcar(l, PONTOS[julgamento])  # o item, o kit já aplicou (H08)
	Som.tocar("pedra", _pos_da_prensa(l, nt.caem[0]), -6.0)  # o piscar do perfeito é do kit (H08)


func falha(l: int) -> void:
	_esmagar(l)  # A falha: achatado, explosao, brasa (a barra escurece pelo kit); na terceira, fantasma
```

`_esquivar(l, dir)` muda `pos[l]` (preso entre 0 e 2), mexe o boneco, e,
havendo nota avisada, resolve pelo "Como se joga" (pondo a nota em
`_ultima[l]` e tirando-a da lista antes de chamar `julgar_toque` ou
`nota_perdida`). `_dono(b)` é o do Cerco. `_conferir_o_ultimo_em_pe()`: com
`_comecaram >= 2`, quando só um presente tem `vida > 0`, todos `acabou`.
`_piscar` como na L1: o `_esmagar` põe `_pisca[l] = CenarioDoImpacto.PISCA_MAX`, e depois
do piscar do kit (H08) a barra volta a `BRILHO[vida[l]]`.

Catálogo: `"S04_J20"` em `MINIGAMES` e na lista da seção `S04`. O `.uid`.
Traduções: `"A Prensa": "The Press"`, `"Esquive!": "Dodge!"`. `dica(l)`:
`{"partes": ["@stick_l", "Esquive"], ...}` para o vivo e
`{"partes": ["@cross", "Luz"], ...}` para o fantasma, com `na_raia(l)` e
`not aprendeu(l)` (`"Esquive": "Dodge"`, `"Luz": "Light"`).

## O que o registro mede

- `sensacao` `golpe` / `golpe_esq` / `golpe_dir` e a `saida` de vibração.
- `pista` (`via` `rumble`) (qualquer lado, ou o lado seguro) e `entrada` `resposta` (o
  lado para onde foi); o `toque` do kit. Pista de um lado com `ok` e
  esquiva para o outro lado, repetida num controle, é o motor daquele lado
  que não chegou (ou chegou trocado).
- `{"o": "fantasma_luz", "n": b}` quando o fantasma acende a luz (o botão no
  tempo de quem já caiu).

## Armadilhas

- **A pista decide onde a prensa cai pelo lugar de agora:** reposicionar
  entre a pista e a batida, fora da janela, é "cedo demais" (esmagado).
- **O canto e a parede:** do canto, fugir para a parede não sai do lugar
  (e é esmagado). A pista de um lado só nunca manda para a parede (no canto,
  a pista é sempre `golpe`).
- **`golpe` × `explosao`:** a pista é o `golpe` (fraco 0,6); o esmagamento é
  a `explosao` (fraco 1,0). O robô e o registro contam com a diferença.
- **O fantasma não é nota:** não chame `nova_nota`, `julgar_toque` nem
  `nota_perdida` para ele.
- **`preso = true`:** o analógico é entrada do minigame; sem ele, o boneco
  anda sozinho pela física.
- **O terror escurece a luz da casa** (11, regra 7): nenhuma luz de outra cor.
- **Os pontos e o item:** o kit aplica `Itens.pontos_do_acerto` no `julgar_toque`
  (H08); marque cru.

## Pronto quando

A Prensa joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos
três temperamentos (o ruim vira fantasma e acende a luz); aguenta o cabo que
cai e volta; fecha com vencedor (o último em pé, ou os 90 s); a prova do jogo
passa; e `bash tests/prova_visual.sh` passa com a **prancha olhada** com A
Prensa nela (o `Catalogo.sortear` da H08 põe o `S04_J20` na noite: rode a prova visual com a semente que o sorteia, `--semente=N`) — no escuro da nuvem a prancha
confere a disposição; a aparência do escuro é o André quem aprova.

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, depois das outras da seção:

```gdscript
## A Prensa (S04_J20): a pista chega (os dois motores ou um lado), o
## cavaleiro fica num dos três lugares, e a colocação respeita vida e queda.
func _prova_da_prensa() -> void:
	var pista := [false]
	var fora_da_raia := [0]
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			var pc := Forja.percepcao(l)
			var forte := float(pc.get("forte", 0.0))
			var fraco := float(pc.get("fraco", 0.0))
			if (forte > 0.9 and fraco > 0.4 and fraco < 0.8) or (forte > 0.3 and fraco < 0.05) or (fraco > 0.3 and forte < 0.05):
				pista[0] = true
			if int(mg.pos[l]) < 0 or int(mg.pos[l]) > 2:
				fora_da_raia[0] += 1
	var mg = await _joga_o_minigame("S04_J20", 130.0, olhar)
	if mg == null:
		return
	_esperar(pista[0], "Prensa: a pista chegou a um controle simulado")
	_esperar(fora_da_raia[0] == 0, "Prensa: o cavaleiro sempre num dos três lugares (%d quadros fora)" % fora_da_raia[0])
	var v := mg.vencedor()
	for i in range(1, v.size()):
		_esperar(int(mg.vida[v[i - 1]]) >= int(mg.vida[v[i]]), "Prensa: a colocação pela vida (%s)" % [v])
	var sensacoes := _linha_do_tempo().filter(func(e): return e.get("tipo") == "sensacao" and e.get("nome") in ["golpe", "golpe_esq", "golpe_dir"])
	_esperar(sensacoes.size() >= 1, "Prensa: %d pistas no registro" % sensacoes.size())
```

**O que o André joga e sente** (`./run-local.sh -- --sala=S04_J20`, com a luz da sala apagada):

- no escuro, a mão avisa antes de a prensa aparecer; dá para jogar sem olhar;
- no meio, "só a esquerda" e "só a direita" se distinguem dos "dois lados";
- o esmagamento é forte e engraçado; o fantasma acendendo a luz ajuda de verdade;
- a barra de luz escurece com a vida, na cor do lugar, e nunca apaga.

## Ao terminar

- No [quadro](README.md): a linha **L5** (se não existir, acrescente
  `| [L5](L5-a-prensa.md) | L | S4 — A Prensa | M | Sonnet | 1,5 | feito (<commit>) | <gasto> |`),
  com o commit e o gasto real. Com as cinco feitas, a linha **L** da seção
  também vira **feito**.
- Commit sugerido (sem trailer):
  `feat: A Prensa — o terror d'O Impacto, a mão que avisa antes do olho`
