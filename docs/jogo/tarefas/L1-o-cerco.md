# L1 — O Cerco

**Sprint:** L · **Slot:** S04_J16 · **Tamanho:** G · **Depende de:** H04, H08, F09, F01, F04, F05, F06, H06, H07, G04, G05, G08

## Por quê

O Impacto de hoje (`godot/scripts/salas/impacto.gd`) é uma prova às cegas
com cara de jogo: golpes um de cada vez, sem tempo de música, uma pergunta
de cor no fim de cada onda. O Cerco é a mesma arena e a mesma ideia — a mão
sente o lado antes do olho — tocada no tempo da faixa, em hoqueto, sem
pergunta no modo do jogador. É o primeiro minigame da seção: ele muda a
sala para o kit, cria o cenário comum que os outros quatro usam e deixa a
pergunta da cor só no Modo bancada, onde ela mede a barra de luz.

## Ler antes

- [O índice da seção](L-o-impacto.md) (o cenário comum, o registro)
- [O molde de minigame](molde-de-minigame.md) e o [kit](../13-arquitetura.md#o-kit-do-minigame--h04)
- [O Modo bancada](../13-arquitetura.md#o-modo-bancada--f01) e [as sensações](../13-arquitetura.md#as-sensações--f05)
- [A identidade](../05-haptica-e-controle.md#a-identidade-p1p4) (a barra de luz sempre na cor do lugar)
- O código de hoje: `godot/scripts/salas/impacto.gd` (inteiro) e `godot/testes/minigame_de_prova.gd`

## A ficha de dados

O script novo é `godot/scripts/minigames/s04/o_cerco.gd`. O começo:

```gdscript
extends Minigame
## O Cerco (S04_J16) — O Impacto de antes, no tempo da faixa. Cada batida tem
## um dono (o hoqueto); na batida dele, uma sentinela de pedra ataca de um
## lado. A mão sente o lado um tempo antes (só o motor daquele lado); a tela
## só mostra um "!" sem lado. Defenda com L1 (esquerda) ou R1 (direita) na
## batida do golpe.
##
## A falha: o golpe passa, a lanterna perde uma brasa, a barra de luz perde
## um degrau de brilho e o cavaleiro cambaleia.
## O vencedor: quem termina com mais luz (vida); no empate, mais pontos.
## O alto-falante do dono: o escudo que segura ("escudo") e o golpe que entra ("golpe").
## O registro mede: cada pista (lado, ok), a resposta (lado feito, julgamento)
## e os apertos sem pista (os fantasmas: a vibração que vazou para o vizinho).
## O robô: sente o motor que ligou no controle simulado e defende daquele lado
## na batida seguinte; quando não acerta, defende 250 ms atrasado.
## Com menos de quatro: as batidas se dividem entre quem está; sozinho, só as pares.
## A régua: (1) "Defenda!" com o escudo dos dois lados no aviso; (2) sim: a
## tela não diz o lado, só a mão; (3) não pergunta nada (a cor, só na bancada).

const FICHA := {
	"slot": "S04_J16",
	"titulo": "O Cerco",
	"verbo": "Defenda!",
	"genero": "sobrevivencia",
	"icone": "vibracao",
	"entradas": [Forja.L1, Forja.R1],
	"camera": "fixa",
	"faixa": "MUS_S04_J16",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["golpe_esq", "golpe_dir", "golpe", "acerto", "perfeito", "erro"],
	"material": "pedra",
	"microjogo": {"verbo": "Defenda!", "segundos": 6.0},
	# o que a bancada mede (o veredito é do núcleo, como hoje)
	"features": ["vibracao_forte", "vibracao_fraca", "vibracao_isolamento", "lightbar"],
	"botoes_medidos": [Forja.L1, Forja.R1, Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO, Forja.TRIANGULO],
	"gesto": "lados",
}

const PONTOS := [0, 40, 70, 100]  ## ERRO, BOM, OTIMO, PERFEITO
const FANTASMA := -20  ## o escudo levantado sem golpe (como hoje)
const VIDA_MAX := 5
const VIDA_MIN := 1  ## a luz nunca apaga
## O brilho da barra de luz por vida (índice = vida): 40% a 100%, nunca abaixo (F04).
const BRILHO := [0.4, 0.4, 0.55, 0.7, 0.85, 1.0]
const PERFEITOS_PARA_CURAR := 4
## A chance de golpe em cada batida do dono, por parte: entrada, pico, saída.
const DENSIDADE := [0.5, 1.0, 0.75]
const ARIETE_A_CADA := 4  ## no pico, um compasso de aríete a cada quatro
## As perguntas da bancada (a cor da barra de luz): nos compassos 16 e 32.
const COMPASSOS_DA_PERGUNTA := [16, 32]
```

Do `impacto.gd` de hoje continuam, **iguais**: `PERGUNTA_MAX`,
`MAX_PERGUNTAS`, `CORES`, `BOTAO_COR`, `GLIFO_COR`, `NEUTRO`, `MOSTRA`
(linhas 28-39 e 24). Saem: `F` (use `Forja`), `RAIAS` e `Z_JOGADOR` (são do
kit), `POR_LADO`, `ONDAS`, `JANELA`, `GOLPE_MS`, `DANO`, `VIDA_MIN` de 0,12
e o `enum` de estados (o tempo agora é da música).

## Como se joga

**O dono da batida (o hoqueto).** As batidas contam de `Ritmo.batida()`; o
compasso `c` tem as batidas `4c` a `4c+3`. O dono da batida `b` é
`presentes()` em ordem crescente, `lista[b % lista.size()]`: com quatro, P1
tem a 0, P2 a 1, P3 a 2, P4 a 3 de cada compasso; com dois, P_a as pares e
P_b as ímpares; com três, a roda gira pelo compasso. **Sozinho, só as
batidas pares** — o mesmo lugar nunca tem golpe em duas batidas seguidas
(a pista de uma cairia no instante da defesa da outra).

**A nota** é um golpe: `{"n": b, "b": b, "t": Ritmo.t_da_batida(b), "lado": 0 ou 1, "avisada": false, "ariete": false}`
(lado 0 é a esquerda). O compasso 0 é a contagem de entrada (H06): a
primeira nota possível é a batida `BATIDA_DA_PRIMEIRA_NOTA` (4).

**A pista**, na batida `b − 1` (`Ritmo.t_musica() >= Ritmo.t_da_batida(b - 1)`):

- `Forja.sentir(l, "golpe_esq" if lado == 0 else "golpe_dir")` — só o motor
  daquele lado, 250 ms. Se devolver `true`, `j[l].rumble_ok = true`;
- o `!` acima do boneco (sem lado) e a raia acesa pelo kit
  (`acender_raia(l, forca)`, com `forca = clampf(1.0 - absf(Ritmo.t_musica() - t) * 3.0, 0.0, 1.0)`
  da nota mais perto);
- o sopro no meio (`Som.tocar("sopro", null, -6.0)`): o som não entrega o lado;
- os outros presentes com controle ganham uma `chance` (o isolamento);
- o registro: `anotar("pista", l, {"n": b, "evento": "mandou", "canal": "rumble", "o_que": "esq"/"dir", "ok": ok})`.

**A defesa**, na batida `b`: L1 é a esquerda, R1 a direita. O aperto casa
com a nota em aberto mais perto pelo `casar_toque(l)` do kit (H08):

- **lado certo** → `julgar_toque(l, t, n, true)` (é perigo físico: a folga
  de quem está em último vale) e `Cega.certo(cega)` — a mão acertou o lado,
  qualquer que seja o tempo; o kit chama `toque()` ou `falha()`;
- **lado errado** → `nota_perdida(l, n)` (o kit registra o erro e chama
  `falha()`) e `Cega.errado(cega, lado_feito)`;
- **nenhuma nota perto** → o fantasma (como hoje): `j[l].fantasmas += 1`,
  `marcar(l, FANTASMA)`, o `?` amarelo por 1 s, e
  `anotar("entrada", l, {"o": "fantasma", "golpe_de": "P%d" % (dono + 1)})`
  com o dono da nota dos outros mais perto no tempo.

Toda resposta grava a linha `entrada` `{"o": "resposta", "n": b, "lado_pedido": "esq"/"dir", "lado_feito": "esq"/"dir"/"nenhum"}`.
A nota que passa de `FOLGA_PERDIDA` (o kit, 0,14 s) sem defesa é
`nota_perdida(l, n)` e `Cega.perdido(cega)`.

**Os pontos** (no `toque`): `marcar(l, PONTOS[julgamento])`; o item
(`Itens.pontos_do_acerto`) o kit já aplica no `julgar_toque` (H08).

**A vida:** começa em 5. Cada falha tira 1 (nunca abaixo de 1; no treino,
nada tira). Quatro perfeitos seguidos devolvem 1 (até 5).

**Os 90 segundos de música**, pela parte (`andamento()` do kit, H08):

| parte | música | a batida do dono tem golpe com chance | o que acontece |
| --- | --- | --- | --- |
| entrada | 0–30 s | 0,5 | aprende-se o lado |
| **pico** | 30–60 s | 1,0 | **o aríete**: em todo compasso `c` com `c % ARIETE_A_CADA == 3`, o compasso inteiro é um golpe só, de todos, na batida `4c + 2` (cada um com o seu lado sorteado; a pista na `4c + 1`); as outras três batidas desse compasso ficam vazias |
| saída | 60–90 s | 0,75 | — |

Quem está errando (`Ritmo.simples[l]`) fica com a chance 0,5 e fora do
aríete. O compasso é gerado um compasso antes de começar
(`_gerar_compasso(c)` quando `Ritmo.batida() >= 4c − 4`), com `rng` (a
semente da partida) sorteando chance e lado.

## O cenário

- `CenarioDoImpacto.montar(self)` — o cenário comum (o arquivo novo, abaixo).
- A câmera: `camera_pos = Vector3(0, 6.4, 10.8)`, `camera_olhar = Vector3(0, 1.0, -0.4)`.
- Por lugar presente: `raia(l)`; `posicionar(l)`, depois
  `jogador(l).rotation.y = PI` (de costas para a câmera, de frente para as
  sentinelas, como hoje) e `jogador(l).preso = true`.
- As duas sentinelas de cada raia:
  `CenarioDoImpacto.sentinela(self, Vector3(RAIAS[l] + (-1.35 if lado == 0 else 1.35), 0.0, Z_JOGADOR - 1.45), Vector3(RAIAS[l], 0, Z_JOGADOR))`.
- Os dois escudos: como hoje (`impacto.gd:136-141`, `shield-round` na escala
  2,4, escondidos em 0,001), em `Z_JOGADOR − 0,2`.
- O `!` e o `?`: os `Label3D` de hoje (`impacto.gd:143-161`), com o `!`
  em `(RAIAS[l], 2.55, Z_JOGADOR)`.
- A lanterna da vida: `CenarioDoImpacto.lanterna(self, Vector3(RAIAS[l] + 1.25, 0, Z_JOGADOR + 0.45), Forja.cor_do_lugar(l), VIDA_MAX)`
  no lugar do poste com a esfera de hoje; mais uma `OmniLight3D` da cor do
  lugar em cima dela (energia `0.6 + 0.24 * vida`, alcance 3,2).
- O checklist do [11](../11-arte-e-personagens.md#o-checklist-de-aprovação):
  o olho da sentinela e a brasa são caixas (nenhuma esfera), nada metálico;
  o projétil do golpe, que hoje é `Kit.esfera`, vira
  `Kit.caixa(self, Vector3(0.18, 0.18, 0.18), de, Kit.material(Color("#ff7a2a"), 3.0))`.

### O cenário comum (`godot/scripts/minigames/s04/cenario_do_impacto.gd`)

O arquivo inteiro:

```gdscript
class_name CenarioDoImpacto
extends RefCounted
## O cenário comum d'O Impacto (S04, docs/jogo/tarefas/L-o-impacto.md): a
## arena no escuro, as sentinelas de pedra com o olho que acende, a lanterna
## da vida de cada raia e a barra de luz com brilho. Os cinco minigames da
## seção montam com isto; o que é só de um fica no script dele.

const AR := Color("#6fa8ff")  ## a poeira fria
const NEON := Color("#3b6bff")  ## o neon azul do fundo
const FRIO := Color("#6b6fb0")  ## o enchimento
const TOCHA := Color("#ffb070")  ## a tocha da casa (docs/jogo/11)
const OLHO := Color("#ff4a2a")  ## o olho da sentinela: o único brilho do monstro
const FERRO := Color("#4a4e5e")
## O brilho mínimo da barra de luz na seção (o piso do F04 é 30%).
const BRILHO_MIN := 0.4
## O piscar de outra cor, no máximo (F04).
const PISCA_MAX := 0.5


## A arena no escuro. `escuro` 1,0 é O Impacto; 0,35 é o terror d'A Prensa
## (a luz da casa escurece, não troca: docs/jogo/11, regra 7).
static func montar(sala: SalaJogo, escuro := 1.0) -> void:
	Kit.arena(sala, 5, 3)
	sala.atmosfera(AR, NEON, false, 30, 22.0, -7.8, 0.1 * escuro)
	var frio := OmniLight3D.new()
	frio.position = Vector3(0, 8.0, 3.0)
	frio.light_color = FRIO
	frio.light_energy = 0.45 * escuro
	frio.omni_range = 26.0
	sala.add_child(frio)
	for x in [-10.0, 10.0]:
		var tocha := OmniLight3D.new()
		tocha.position = Vector3(x, 2.4, -5.0)
		tocha.light_color = TOCHA
		tocha.light_energy = 0.8 * escuro
		tocha.omni_range = 7.0
		sala.add_child(tocha)


## Uma sentinela: a coluna do kit virada para `alvo`, com o olho (uma caixa
## emissiva) na frente — o modelo de monstro do docs/jogo/11. Devolve
## {corpo, olho, mat}; `mat.emission_energy_multiplier` acende o olho.
static func sentinela(pai: Node3D, pos: Vector3, alvo: Vector3, escala := 1.35) -> Dictionary:
	var corpo := Kit.peca(pai, "column", pos, 0.0, escala)
	var d := Vector3(alvo.x - pos.x, 0.0, alvo.z - pos.z).normalized()
	corpo.rotation.y = atan2(d.x, d.z)
	var mat := Kit.material(OLHO, 1.2)
	var olho := Kit.caixa(pai, Vector3(0.2, 0.12, 0.08), pos + Vector3(0, 0.95 * escala, 0) + d * 0.3, mat)
	olho.rotation.y = corpo.rotation.y
	return {"corpo": corpo, "olho": olho, "mat": mat}


## A lanterna da vida: um poste de ferro com `n` brasas (caixas) na cor do
## lugar, de baixo para cima. Devolve os materiais das brasas.
static func lanterna(pai: Node3D, pos: Vector3, cor: Color, n := 5) -> Array:
	Kit.caixa(pai, Vector3(0.08, 1.3, 0.08), pos + Vector3(0, 0.65, 0), Kit.material(FERRO, 0.0, 0.5))
	var mats: Array = []
	for k in n:
		var m := Kit.material(cor.darkened(0.6), 0.0, 0.7)
		m.emission_enabled = true
		m.emission = cor
		m.emission_energy_multiplier = 1.6
		Kit.caixa(pai, Vector3(0.16, 0.12, 0.16), pos + Vector3(0, 1.38 + 0.15 * k, 0), m)
		mats.append(m)
	return mats


## Acende as `acesas` primeiras brasas e apaga as outras.
static func acender_lanterna(mats: Array, acesas: int) -> void:
	for k in mats.size():
		(mats[k] as StandardMaterial3D).emission_energy_multiplier = 1.6 if k < acesas else 0.0


## A barra de luz do lugar na cor dele, com o brilho pedido (nunca abaixo de
## BRILHO_MIN). Devolve o que o Forja.luz devolveu (o SDL aceitou).
static func luz_com_brilho(l: int, brilho: float) -> bool:
	var c := Forja.cor_do_lugar(l)
	var k := clampf(brilho, BRILHO_MIN, 1.0)
	return Forja.luz(l, Color(c.r * k, c.g * k, c.b * k))
```

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **vibração (protagonista)** | `golpe_esq` / `golpe_dir` | a pista, na batida `b − 1`, só no dono da nota |
| vibração | `acerto` / `perfeito` / `erro` (o kit) | na defesa julgada |
| vibração | `golpe` | quando o golpe entra (a falha), por cima do `erro` do kit |
| barra de luz | `CenarioDoImpacto.luz_com_brilho(l, BRILHO[vida])` | ao começar e a cada mudança de vida |
| barra de luz | o kit (`_reagir`, H08): branco no perfeito, a cor do lugar escurecida no erro | na defesa julgada; 0,5 s depois, `_piscar` põe de volta o brilho da vida |
| luzinhas de jogador | o número do lugar, sempre | nunca se mexe nelas (fora da bancada) |
| alto-falante do dono | `Som.no_controle(l, "escudo", 0.7)` | na defesa (não no perfeito: aí o kit toca a nota do jogador) |
| alto-falante do dono | `Som.no_controle(l, "golpe", 0.7)` | na falha |
| gatilho | `Forja.gatilhos_off(l)` no `montar` | nada a segurar: o R2 fica solto; o L2 é do item (G03) |
| háptica por material | `"pedra"` (a FICHA; o kit toca no acerto) | — |
| som na TV | `"sopro"` no meio (a pista); `"escudo"` / `"golpe"` e `"bigorna"` / `"falha"` no lugar do boneco | na pista e na resposta |

A barra de luz nunca mostra lado, munição nem pergunta fora da bancada; a
cor é sempre a do lugar.

## A falha

- O projétil sai do olho da sentinela do lado da nota (o `_mostrar_golpe`
  de hoje, `impacto.gd:276-300`, com o projétil em caixa) e bate no boneco:
  faíscas `Tema.VERMELHO`, `Som.tocar("falha", ...)`.
- O cavaleiro cambaleia: `jogador(l).gesto("emote-no", 0.5)` e um tween
  que empurra o boneco 0,25 para o lado oposto ao golpe e volta em meia
  batida (`60.0 / Ritmo.bpm * 0.5` s).
- A brasa de cima da lanterna apaga com um estalo de faíscas da cor do
  lugar (`Efeitos.faiscas(self, pos_da_brasa, Forja.cor_do_lugar(l), 10, 0.5)`);
  a barra de luz perde um degrau; `tremer(TREMOR_GOLPE)`.
- **A recuperação:** a próxima nota do lugar é pelo menos duas batidas
  depois (o hoqueto); quatro perfeitos seguidos acendem a brasa de volta
  (faíscas douradas, `Som.tocar("confirma", ...)`).

## O fim e o vencedor

Acaba pelo tempo (90 s de música, contados pelo kit: H08). O vencedor é quem tem mais vida; no
empate, mais pontos:

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if int(j[a].vida) != int(j[b].vida):
			return int(j[a].vida) > int(j[b].vida)
		return int(pontos[a]) > int(pontos[b]))
	return lista
```

## Com menos de quatro

- **Três:** a roda do dono gira (`b % 3`): cada um tem uma batida a cada três.
- **Dois:** P_a as pares, P_b as ímpares; o aríete é dos dois.
- **Um:** só as batidas pares, todas dele; o isolamento não se mede (sem
  vizinho, nenhuma `chance`). `com_poucos()` devolve `"Só você na arena"`
  com um jogador (o texto da F02) e `""` com mais.
- **O controle que cai:** a pista não vai para quem está sem controle; as
  notas dele que passam enquanto está fora **não** viram erro (somem). Quando
  volta, as notas que já passaram somem e a próxima é a primeira que ainda
  não chegou (o `_fora` do minigame de prova). A vida dele fica como estava.

## O robô

```gdscript
# O robô sente o motor que ligou no controle simulado: só um motor, e forte,
# é a pista; defende daquele lado na batida seguinte, pelo relógio da música.
# As sensações do kit ligam os dois motores juntos: não são pista.
var _robo_ligado := [false, false, false, false]
var _robo_alvo := [-1.0, -1.0, -1.0, -1.0]  ## a batida da defesa (-1: nenhuma)
var _robo_lado := [0, 0, 0, 0]
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var pc := Forja.percepcao(l)
	if pc.is_empty():
		return
	var forte := float(pc.get("forte", 0.0))
	var fraco := float(pc.get("fraco", 0.0))
	var pista := (forte > 0.3 and fraco < 0.05) or (fraco > 0.3 and forte < 0.05)
	if pista and not _robo_ligado[l] and _robo_alvo[l] < 0.0:
		_robo_alvo[l] = roundf(Ritmo.batida()) + 1.0
		_robo_lado[l] = 0 if forte > fraco else 1
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, chega 250 ms tarde
		_robo_atraso[l] = 0.0 if Forja.robo_acerta() else 0.25
	_robo_ligado[l] = pista
	if _robo_alvo[l] >= 0.0 and Ritmo.t_musica() >= Ritmo.t_da_batida(_robo_alvo[l]) + float(_robo_atraso[l]):
		Forja.robo_apertar(l, Forja.L1 if _robo_lado[l] == 0 else Forja.R1, 0.06)
		_robo_alvo[l] = -1.0
	# a bancada: a pergunta da cor, como hoje (impacto.gd:584-592), com _cor_mais_perto
	if Forja.bancada and estado_bancada == PERGUNTA and j[l].cor_pedida >= 0 and j[l].cor_resposta < 0:
		j[l].robo_cor = float(j[l].robo_cor) - _dt
		if j[l].robo_cor <= 0.0:
			Forja.robo_apertar(l, BOTAO_COR[_cor_mais_perto(pc.get("luz", Color.BLACK))], 0.08)
			j[l].robo_cor = 10.0
```

(Com o `robo_cor` posto em `0.7 + 0.8 * rng.randf()` quando a pergunta
abre, e a função `_cor_mais_perto` de hoje, `impacto.gd:595-604`, copiada
igual.) Na defesa, o robô **não** lê a partitura: se a vibração não chegou
ao controle simulado, ele não defende — a prova do caminho inteiro.

## Os ganchos

O que muda do `impacto.gd` de hoje, na ordem do arquivo:

| hoje | no Cerco |
| --- | --- |
| `class_name SalaImpacto`, `extends SalaJogo`, o cabeçalho | `extends Minigame`, sem `class_name`, o cabeçalho de "A ficha de dados" |
| `const F`, `RAIAS`, `Z_JOGADOR`, `POR_LADO`, `ONDAS`, `JANELA`, `GOLPE_MS`, `DANO`, `VIDA_MIN` | saem (kit, ou não servem mais) |
| `enum { PAUSA, GOLPE, VOANDO, PERGUNTA, RESPOSTA, ACABOU }` | `enum { JOGO, PERGUNTA, RESPOSTA }` em `estado_bancada` (só a bancada sai de `JOGO`) |
| `plano`, `i_plano`, `fim_onda`, `onda`, `atual`, `resposta`, `respondido` | `_notas := [[], [], [], []]`, `_gerado := 1`, `_fora := [false, false, false, false]`, `_ultima := [{}, {}, {}, {}]` (a nota em resolução) |
| `_init()` | sai (a FICHA; a câmera vai para o `montar`) |
| `montar()`, `_montar_raia()` | o de "O cenário" |
| `_novo_jogador()` | fica, sem `escudo_lado` de onda; `vida` vira `VIDA_MAX` (int); ganha `"perfeitos": 0`, `"pisca": 0.0` |
| `_cor_da_vida`, `_luz`, `_luz_da_vida` | `_luz_da_vida(l)` = `if CenarioDoImpacto.luz_com_brilho(l, BRILHO[j[l].vida]): j[l].luz_ok = true` |
| `iniciar_jogo()` com `cega_plano_tiros` | o de baixo |
| `_conectado` | `conectado` (kit) |
| `_iniciar_golpe`, `_resolver`, o `match estado` do `jogar` | `_avisar`, `_defender`, `toque`, `falha`, `_golpe_passou` e o `jogar` de baixo |
| `_mostrar_golpe` (276-300) | fica, com o projétil em caixa |
| `_iniciar_pergunta`, `_alguem_pergunta`, `_fechar_pergunta`, `_precisa_mais_cor`, `pergunta()` | ficam iguais, **só na bancada** (abaixo) |
| `dar_vereditos()` (456-469) | fica igual |
| `_process` / `_mostrar` (474-516) | `_mostrar(l, dt)` chamado do fim do `jogar`: escudos, `?`, a lanterna (`acender_lanterna`), a luz dela; o `!` visível entre a pista e a resposta; sem o `super` extra |
| `status()` | `"Luz %d" % j[l].vida` quando `na_raia(l)`; senão `super` |
| `progresso()` | sai (a barra de tempo do kit) |
| `dica()` | `{"partes": ["@l1", "Esquerda", "@r1", "Direita"], "pos": Vector3(RAIAS[l], 0.0, 4.6)}` quando `na_raia(l)` e `not aprendeu(l)`; com `aprendeu`, só os dois glifos |
| `_robo` | `robo(l, dt)` de cima |
| `com_poucos()` | o de "Com menos de quatro" |
| — | `combo(l)` (G04): `return int(j[l].perfeitos) if j.has(l) else 0` |

O esqueleto:

```gdscript
func montar() -> void:
	camera_pos = Vector3(0, 6.4, 10.8)
	camera_olhar = Vector3(0, 1.0, -0.4)
	CenarioDoImpacto.montar(self)
	for p in jogadores:
		var l: int = p.lugar
		j[l] = _novo_jogador()
		raia(l)
		posicionar(l)
		p.rotation.y = PI
		p.preso = true
		n[l] = _montar_raia(l, p)  # sentinelas, escudos, !, ?, lanterna
		Forja.gatilhos_off(l)


func iniciar_jogo() -> void:
	for l in presentes():
		_luz_da_vida(l)


func jogar(dt: float) -> void:
	while _gerado <= int(floor(Ritmo.batida() / 4.0)) + 1:
		_gerar_compasso(_gerado)
		_gerado += 1
	if Forja.bancada:
		_bancada(dt)  # abre a pergunta nos COMPASSOS_DA_PERGUNTA; PERGUNTA/RESPOSTA como hoje (impacto.gd:429-453)
	var agora := Ritmo.t_musica()
	var folga := FOLGA_PERDIDA  # o kit (H08)
	for l in presentes():
		_piscar(l, dt)
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_notas[l] = _notas[l].filter(func(nt): return float(nt.t) > agora)
		for nt in _notas[l]:
			if not nt.avisada and agora >= Ritmo.t_da_batida(float(nt.b) - 1.0):
				_avisar(l, nt)
		if Forja.apertou(l, Forja.L1):
			_defender(l, 0)
		elif Forja.apertou(l, Forja.R1):
			_defender(l, 1)
		while not _notas[l].is_empty() and agora > float(_notas[l][0].t) + folga:
			_golpe_passou(l, _notas[l].pop_front())
		_mostrar(l, dt)


## As notas do compasso c (uma por batida do dono, pela chance da parte).
func _gerar_compasso(c: int) -> void:
	if c < 1 or (Forja.bancada and (estado_bancada != JOGO or c in COMPASSOS_DA_PERGUNTA)):
		return
	var lista := presentes()
	lista.sort()
	if lista.is_empty():
		return
	var parte := 0 if andamento() < 1.0 / 3.0 else (1 if no_pico() else 2)  # o kit, em tempo de música
	if parte == 1 and c % ARIETE_A_CADA == 3:
		for l in lista:
			if not Ritmo.simples[l]:
				_nova(l, 4 * c + 2, true)
		return
	for k in 4:
		var b := 4 * c + k
		if lista.size() == 1 and b % 2 == 1:
			continue
		var l: int = lista[b % lista.size()]
		var chance: float = minf(DENSIDADE[parte], 0.5) if Ritmo.simples[l] else DENSIDADE[parte]
		if rng.randf() < chance:
			_nova(l, b, false)


func _nova(l: int, b: int, ariete: bool) -> void:
	var nt := {"n": b, "b": b, "t": Ritmo.t_da_batida(b), "lado": rng.randi_range(0, 1), "avisada": false, "ariete": ariete}
	_notas[l].append(nt)
	nova_nota(l, b, float(nt.t))


func toque(l: int, julgamento: int) -> void:
	var e: Dictionary = j[l]
	var nt: Dictionary = _ultima[l]
	marcar(l, PONTOS[julgamento])  # o item, o kit já aplicou (H08)
	e.bloqueios += 1
	e.escudo = 1.0
	e.escudo_lado = int(nt.lado)
	if julgamento == Ritmo.PERFEITO:
		e.perfeitos += 1
		e.pisca = CenarioDoImpacto.PISCA_MAX  # o kit pisca branco; depois, o brilho da vida
		if e.perfeitos % PERFEITOS_PARA_CURAR == 0 and e.vida < VIDA_MAX and not treinando:
			e.vida += 1
			_luz_da_vida(l)
	else:
		e.perfeitos = 0
		Som.no_controle(l, "escudo", 0.7)
	Som.tocar("escudo", jogador(l).global_position + Vector3(0, 1.2, 0), -2.0)
	_mostrar_golpe(l, int(nt.lado), true)


func falha(l: int) -> void:
	var e: Dictionary = j[l]
	var nt: Dictionary = _ultima[l]
	e.perfeitos = 0
	Forja.sentir(l, "golpe")
	Som.no_controle(l, "golpe", 0.7)
	Som.tocar("golpe", jogador(l).global_position + Vector3(0, 1.2, 0), -2.0)
	if not treinando:
		e.vida = maxi(VIDA_MIN, int(e.vida) - 1)
	e.pisca = CenarioDoImpacto.PISCA_MAX  # o kit escurece a cor; depois, o brilho da vida um degrau abaixo
	tremer(TREMOR_GOLPE)
	_mostrar_golpe(l, int(nt.get("lado", 0)), false)
	_cambalear(l, int(nt.get("lado", 0)))


## Depois do piscar do kit (H08: no máximo 0,5 s), o brilho da vida volta.
func _piscar(l: int, dt: float) -> void:
	if float(j[l].pisca) > 0.0:
		j[l].pisca = float(j[l].pisca) - dt
		if float(j[l].pisca) <= 0.0:
			_luz_da_vida(l)
```

`_avisar(l, nt)`, `_defender(l, lado)`, `_golpe_passou(l, nt)` e
`_cambalear(l, lado)` fazem o que "Como se joga" e "A falha" dizem; antes de
chamar `julgar_toque` ou `nota_perdida`, ponha a nota em `_ultima[l]` (o
`toque` e a `falha` a leem). O `_bancada(dt)` é o `PAUSA`/`PERGUNTA`/`RESPOSTA`
de hoje reduzido à cor: no começo do compasso 16 e do 32 (`Ritmo.batida() >= 4 * c`),
`_iniciar_pergunta()` (com o evento `pergunta` da F01, `qual` = `"cor"`); em
`PERGUNTA`, o laço de hoje (`impacto.gd:430-444`); em `RESPOSTA`, depois de
1,6 s, `_luz_da_vida(l)` de cada um e `estado_bancada = JOGO`. Com a
pergunta aberta, o `_piscar` não mexe na barra de luz.

Onde mora e o catálogo: `godot/scripts/minigames/s04/o_cerco.gd`;
`Catalogo.MINIGAMES["S04_J16"] = preload("res://scripts/minigames/s04/o_cerco.gd")`;
na seção `S04` de `SECOES`, `"minigames": ["S04_J16"]`; e sai `"impacto"` de
`SALAS_ANTIGAS`. `git rm godot/scripts/salas/impacto.gd godot/scripts/salas/impacto.gd.uid`.
Importe (`"$GODOT" --headless --path godot --import --quit`) e commite os
dois `.uid` novos (`o_cerco.gd.uid`, `cenario_do_impacto.gd.uid`).
Em `godot/scripts/traducoes.gd`: `"O Cerco": "The Siege"`, `"Defenda!": "Defend!"`,
`"Esquerda": "Left"`, `"Direita": "Right"`, `"Luz %d": "Light %d"` (as que
ainda não existirem).

## O que o registro mede

- `sensacao` `golpe_esq`/`golpe_dir` (F05) e a `saida` de vibração com `seq`
  e `ok` (F06), sozinhas.
- `pista` (`canal` `rumble`) (n, lado, ok) na pista; `entrada` `resposta` (n, lado pedido,
  lado feito); `entrada` `fantasma` (golpe de quem); e o `toque` do kit.
- Na bancada, além disso, a `pergunta` da cor e a `resposta_cor` de hoje, e
  os quatro vereditos (`dar_vereditos`), calculados e gravados nos dois modos.

## Armadilhas

- **A pista e a sensação do kit não podem cair juntas no mesmo controle.**
  O `acerto`/`erro` do kit liga os dois motores; se cair no instante de uma
  pista, o lado se perde. Por isso o mesmo lugar nunca tem golpe em duas
  batidas seguidas (sozinho, só as pares; no aríete, as outras batidas do
  compasso ficam vazias).
- **`Forja.vibrar` não existe para a sala** (F05): só `Forja.sentir`.
- **A barra de luz:** nunca `Forja.luz` com cor que não seja a do lugar, a
  não ser a pergunta da bancada; o piscar do perfeito e do erro é do kit
  (H08), e o minigame só põe de volta o brilho da vida. A prova da F04 confere
  o tom de cada lugar durante a sala.
- **O `_ultima[l]`** tem de estar posto antes de `julgar_toque`/`nota_perdida`:
  o kit chama `toque`/`falha` de dentro deles, na mesma linha.
- **O mundo se mexe pela batida:** o `!`, a raia acesa e o projétil tomam o
  tempo de `Ritmo.t_musica()`; o piscar e o escudo que abaixa podem usar `dt`
  (são enfeite).
- **Os pontos e o item:** o kit aplica `Itens.pontos_do_acerto` no
  `julgar_toque` (H08); o minigame marca `PONTOS[julgamento]` cru.
- **O treino** julga igual e não soma (`marcar`); a vida também não cai no treino.
- **A pergunta da cor só com `Forja.bancada`.** Fora dela, nenhum
  `pergunta()` devolve nada e o `lightbar` sai "não medido" — é o esperado
  (`SO_COM_PERGUNTA` da F01).
- **`preso = true`:** sem ele, o boneco anda com o analógico e a física troca
  a animação a cada quadro. A `SalaJogo.sair` já devolve `preso = false`.

## Pronto quando

O Cerco joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos
três temperamentos; aguenta o cabo que cai e volta; fecha sempre com
vencedor; `--sala=impacto` abre o `S04_J16`; com `--bancada`, a pergunta da
cor aparece nos compassos 16 e 32 e os quatro vereditos saem como antes; a
prova do jogo passa (as duas rodadas: sem e com `--bancada`); e
`bash tests/prova_visual.sh` passa com a **prancha olhada** — O Cerco está na
partida de 5 da prova visual (é o `impacto`).

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, a checagem do Cerco usa o
`_joga_o_minigame(slot, limite_s, a_cada_quadro)` da H08 (abre pelo
catálogo, deixa o aviso passar em quadros e espera o fim pelo relógio de
parede: 90 s de música e o treino cabem em 130 s). A checagem do Cerco, chamada no percurso logo depois da última sala de
hoje (antes do relatório):

```gdscript
## O Cerco (S04_J16): o apelido abre o minigame; a pista chega só no motor do
## lado; a barra de luz fica na cor do lugar; o registro tem a pista e a resposta.
func _prova_do_cerco() -> void:
	var lados := {}
	var fora_do_tom := [0]
	var amostras := [0]
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			var pc := Forja.percepcao(l)
			var forte := float(pc.get("forte", 0.0))
			var fraco := float(pc.get("fraco", 0.0))
			if forte > 0.3 and fraco < 0.05:
				lados["esq"] = true
			if fraco > 0.3 and forte < 0.05:
				lados["dir"] = true
			amostras[0] += 1
			if not _mesmo_tom(pc.get("luz", Color.BLACK), Forja.cor_do_lugar(l)):
				fora_do_tom[0] += 1
	var mg = await _joga_o_minigame("impacto", 130.0, olhar)
	if mg == null:
		return
	_esperar(mg.id == "S04_J16", "Cerco: --sala=impacto abre o S04_J16")
	_esperar(not lados.is_empty(), "Cerco: a pista chegou a um controle só no motor de um lado (%s)" % [lados.keys()])
	_esperar(fora_do_tom[0] * 4 <= amostras[0], "Cerco: a barra de luz na cor do lugar (%d de %d fora)" % [fora_do_tom[0], amostras[0]])
	var v := mg.vencedor()
	_esperar(not v.is_empty() and int(mg.j[v[0]].vida) == v.map(func(l): return int(mg.j[l].vida)).max(), "Cerco: o vencedor tem a maior vida")
	var pistas := _linha_do_tempo().filter(func(e): return e.get("tipo") == "pista" and e.get("slot") == "S04_J16" and e.get("evento") == "mandou")
	var toques := _linha_do_tempo().filter(func(e): return e.get("tipo") == "toque" and e.get("slot") == "S04_J16")
	_esperar(pistas.size() >= 1 and toques.size() >= 1, "Cerco: o registro tem %d pistas e %d toques" % [pistas.size(), toques.size()])
	if not Forja.bancada:
		_esperar(_linha_do_tempo().filter(func(e): return e.get("o") == "pergunta" and e.get("sala", e.get("slot", "")) == "S04_J16").is_empty(), "Cerco: fora da bancada, nenhuma pergunta")
```

(`_mesmo_tom` é da F04 e `_linha_do_tempo` da F01; as duas já estão na
prova. As checagens que hoje olham `"impacto"` pelo id, como as de
`SO_COM_PERGUNTA`, passam a olhar pelo apelido com `_e_a_sala` da H04.)

**O que o André joga e sente** (`./run-local.sh -- --sala=impacto`, com
quatro DualSense, dois no cabo e dois no rádio):

- de olhos fechados, a pista esquerda é só na mão esquerda, a direita só na
  direita, e a vibração de um vizinho não se sente no seu controle;
- a pista chega uma batida antes e dá tempo de defender no tempo;
- o aríete no meio assusta (todos juntos) e a sala fica no ritmo;
- a barra de luz escurece com a vida e nunca troca de cor (o vermelho do
  golpe é um relâmpago); as luzinhas mostram o número o tempo todo;
- com `--bancada`, a pergunta da cor aparece duas vezes e some sem ela.

## Ao terminar

- No [quadro](README.md): a linha **L1** (se o quadro só tem a linha **L**
  da seção, acrescente abaixo dela a linha
  `| [L1](L1-o-cerco.md) | L | S4 — O Cerco | G | feito (<commit>) |`),
  com o commit.
- Commit sugerido (sem trailer):
  `feat: O Cerco — O Impacto no kit, no tempo da faixa, e o cenário comum da seção`
