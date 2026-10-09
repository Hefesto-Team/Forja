# L1 — O Cerco

**Sprint:** L · **Slot:** S04_J16 · **Tamanho:** G · **Depende de:** H04, H08, F09, F01, F04, F05, F06, H06, H07, G04, G05, G08, G12, G14, G15

## Por quê

O Impacto de hoje (`godot/scripts/salas/impacto.gd`) é uma prova às cegas com cara de jogo; O Cerco é a mesma
arena e a mesma ideia (a mão sente o lado antes do olho) tocada no tempo da faixa, em hoqueto, com o aríete que
faz a sala gritar, e é o primeiro minigame da seção: muda a sala para o kit e cria o cenário comum que L2 a L5 usam.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (a FICHA, os ganchos, o que o kit dá pronto)
- [`godot/scripts/salas/impacto.gd`](../../../godot/scripts/salas/impacto.gd) (inteiro: esta ficha o desmonta)
- [O índice da seção](L-o-impacto.md) (o que fica fora destas fichas)

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão, o RPG) já está copiado nesta ficha, com os
números. Não abra outro documento. Onde o índice da seção dá uma cor em hex, outra câmera ou outra assinatura (a
`lanterna(pai, pos, cor, ...)` de lá), vale esta ficha.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s04/o_cerco.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/s04/cenario_do_impacto.gd` | novo: o cenário comum da seção | **da seção**: a L1 cria; L2 a L5 só chamam (nenhuma o reescreve) |
| `godot/scripts/minigames/minigame.gd` | `"momento"` em `TIPOS_DO_JOGO` e a função `momento()` | **de todos**: se outra ficha já pôs, não escreva de novo |
| `godot/scripts/minigames/catalogo.gd` | `S04_J16` em `MINIGAMES` e em `SECOES`; sai `"impacto"` de `SALAS_ANTIGAS` | **da seção**: L2 a L5 acrescentam uma linha cada |
| `godot/scripts/traducoes.gd` | `"O Cerco"`, `"Defenda!"` | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_do_cerco()` e a chamada no percurso | **de todos** |
| `docs/jogo/13-arquitetura.md` | a linha `momento` na tabela «Os eventos do jogo» | **de todos**: se já existe, não escreva de novo |
| `godot/scripts/salas/impacto.gd` e `.uid` | `git rm` | só desta |

Os dois `.uid` novos (`o_cerco.gd.uid`, `cenario_do_impacto.gd.uid`) saem do import:
`"$GODOT" --headless --path godot --import --quit`, e entram no commit.

### O que muda de hoje

Hoje o Impacto tem golpes um de cada vez, sem tempo de música, e uma pergunta de cor no fim de cada onda. O
Cerco tem o golpe na batida do dono (o hoqueto), a pista uma batida antes só no motor do lado, o aríete no pico
e as duas sentinelas juntas na reta. A pergunta da cor fica só no Modo bancada, onde ela mede a barra de luz.

### O kit que esta ficha usa

As funções que a H04 e a H08 deixam no `Minigame` (não reimplemente):

```gdscript
presentes() -> Array; conectado(l) -> bool; na_raia(l) -> bool; raia(l) -> Node3D
acender_raia(l, forca); posicionar(l)          # posicionar põe o boneco na raia, de mãos livres
julgar_toque(l, t_alvo, n := -1, perigo := false) -> int   # chama toque() ou falha()
nota_perdida(l, n); nova_nota(l, n, t_alvo); anotar(tipo, l, campos := {})
andamento() -> float (0..1); no_pico() -> bool; marcar(l, pontos); aprendeu(l) -> bool
const RAIAS := [-6.0, -2.0, 2.0, 6.0]; const Z_JOGADOR := 1.4; const FOLGA_PERDIDA := 0.140
const BATIDA_DA_PRIMEIRA_NOTA := 4
var j := {}; var n := {}; var rng; var treinando; var jogadores; var pontos
```

Do `Forja` e do `Ritmo`: `Forja.sentir(l, nome, ms := -1)` (F05: `toque`, `acerto`, `perfeito`, `erro`, `golpe`,
`explosao`, `aviso`, `golpe_esq`, `golpe_dir`), `Forja.gatilho(l, lado, modo, a, b, c)` (lado 0 = L2, 1 = R2),
`Forja.gatilhos_off(l)`, `Forja.luz(l, cor)`, `Forja.cor_do_lugar(l)`, `Forja.percepcao(l)` (`forte`, `fraco`,
`luz`, `gatilho_esq`, `gatilho_dir`), `Forja.robo_apertar(l, botao, s)`, `Forja.robo_acerta()` (F09),
`Ritmo.t_musica()`, `Ritmo.batida()`, `Ritmo.t_da_batida(b)`, `Ritmo.bpm`, `Ritmo.simples[l]`, `Ritmo.PERFEITO`.
Do G03: `Itens.antecipacao_s(l, bpm)` (a Lanterna) e `Itens.resiste_a_empurrao(l)` (a Âncora, 0,5 ou 1,0).

### A função `momento` (em `minigame.gd`, de todos)

O tipo `momento` é o da [régua da diversão](../diversao/README.md#4-um-momento-de-grito-com-nome): esta ficha o
acrescenta, porque é a primeira da seção a precisar dele. Em `TIPOS_DO_JOGO`, acrescente `"momento"` ao fim da
lista. Ao fim do arquivo:

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

No [13](../13-arquitetura.md), na tabela «Os eventos do jogo», depois da linha `estacao`:
`| \`momento\` | o momento de grito do minigame: \`nome\`, \`t_musica\`, \`x_tela\` e \`altura_tela\` (0 a 1); \`lugar\` 0 quando é de todos (docs/jogo/diversao/README.md) |`.

## Como se joga

### A ficha de dados

```gdscript
extends Minigame
## O Cerco (S04_J16) — O Impacto de antes, no tempo da faixa. Cada batida tem
## um dono (o hoqueto); na batida dele, uma sentinela de pedra ataca de um
## lado. A mão sente o lado uma batida antes (só o motor daquele lado); a tela
## só mostra um "!" sem lado. Defenda com L1 (esquerda) ou R1 (direita) na
## batida do golpe. Na reta, as duas sentinelas juntas: L1 e R1 juntos.
##
## A falha: o golpe passa, o cavaleiro é empurrado 0,6 m para trás por 2
## tempos, a lanterna perde uma brasa e a barra de luz perde um degrau.
## O vencedor: quem termina com mais brasas (vida); no empate, mais pontos.
## O alto-falante do dono: o julgamento do kit; sem vibração, a pista em tiques.
## O registro mede: cada pista (lado, ok), a resposta (lado feito, julgamento),
## os apertos sem pista (os fantasmas) e os momentos `ariete` e `reta`.
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
	"sensacoes": ["golpe_esq", "golpe_dir", "golpe", "explosao", "acerto", "perfeito", "erro"],
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
const VIDA_MIN := 1  ## a luz nunca apaga: ninguém sai
## O brilho da barra de luz por vida (índice = vida): 40% a 100%, nunca abaixo (F04).
const BRILHO := [0.4, 0.4, 0.55, 0.7, 0.85, 1.0]
const PERFEITOS_PARA_CURAR := 4
## A chance de golpe em cada batida do dono, por terço: ensina, pico, reta.
const DENSIDADE := [0.5, 1.0, 0.75]
const ARIETE_A_CADA := 4  ## no pico, o compasso c com c % 4 == 3 é um aríete
## Ninguém fica mais de 8 batidas sem nota (a régua, item 7).
const MAX_SEM_NOTA := 8
## As últimas 16 batidas são a reta: metade das notas são duplas (L1 e R1).
const BATIDAS_DA_RETA := 16
const JUNTOS_S := 0.08  ## L1 e R1 contam juntos até 80 ms um do outro
## A falha: o empurrão para trás, em m, e a queda em tempos (minigames.csv: 2).
const EMPURRAO_M := 0.6
const EMPURRAO_MIN_M := 0.5  ## a régua, item 6: a silhueta anda 0,5 m ou mais
const QUEDA_TEMPOS := 2.0
const ARIETE_M := 1.0  ## no aríete, quem errou voa 1 passo (1 m) para trás
## As perguntas da bancada (a cor da barra de luz): nos compassos 16 e 32.
const COMPASSOS_DA_PERGUNTA := [16, 32]
```

Do `impacto.gd` de hoje continuam, **iguais**: `PERGUNTA_MAX`, `MAX_PERGUNTAS`, `BOTAO_COR`, `GLIFO_COR`,
`NEUTRO`, `MOSTRA` (linhas 24 e 28-39). `CORES` muda: as quatro cores de hoje (âmbar, ciano, violeta, branco)
batem com as novas cores dos lugares (ciano e âmbar), então a pergunta passa a usar quatro tintas que nenhum
lugar usa:

```gdscript
## A pergunta da bancada: quatro cores longe das quatro dos lugares (G14).
const CORES := [
	{"nome": "vermelhão", "cor": Tema.SECAO[0]},
	{"nome": "cobalto", "cor": Tema.SECAO[1]},
	{"nome": "ameixa", "cor": Tema.SECAO[4]},
	{"nome": "branco", "cor": Tema.ETIQUETA},
]
```

Saem: `F` (use `Forja`), `RAIAS` e `Z_JOGADOR` (são do kit), `POR_LADO`, `ONDAS`, `JANELA`, `GOLPE_MS`, `DANO`,
o `VIDA_MIN` de 0,12 e o `enum` de estados (o tempo agora é da música).

### O dono da batida (o hoqueto)

As batidas contam de `Ritmo.batida()`; o compasso `c` tem as batidas `4c` a `4c+3`. O dono da batida `b` é
`presentes()` em ordem crescente, `lista[b % lista.size()]`: com quatro, P1 tem a 0, P2 a 1, P3 a 2, P4 a 3 de
cada compasso; com dois, um as pares e outro as ímpares; com três, a roda gira pelo compasso. **Sozinho, só as
batidas pares**: o mesmo lugar nunca tem golpe em duas batidas seguidas (a pista de uma cairia no instante da
defesa da outra).

**A nota** é um golpe: `{"n": b, "b": b, "t": Ritmo.t_da_batida(b), "lado": 0, 1 ou 2, "avisada": false, "ariete": false}`.
Lado 0 é a esquerda, 1 a direita, 2 os dois (só na reta). O compasso 0 é a contagem de entrada (H06): a primeira
nota possível é a batida `BATIDA_DA_PRIMEIRA_NOTA` (4).

### Os 90 segundos, em três terços

| terço | música | a batida do dono tem golpe com chance | o que acontece |
| --- | --- | --- | --- |
| 1. ensina | 0–30 s | 0,5 | aprende-se o lado |
| 2. **o pico** | 30–60 s (`no_pico()`) | 1,0 | **o aríete**: no compasso `c` com `c % 4 == 3`, o compasso inteiro é um golpe só, de todos, na batida `4c + 2` (cada um com o seu lado sorteado; a pista na `4c + 1`); as outras três batidas desse compasso ficam vazias |
| 3. a reta | 60–90 s | 0,75 | nas **últimas 16 batidas**, cada nota sorteia o lado entre 0, 1 e 2 com pesos 1/4, 1/4 e 1/2: metade das notas são as duas sentinelas juntas |

A 140 BPM, o pico vai do compasso 18 ao 35, e os aríetes caem nos compassos 19, 23, 27 e 31 (quatro aríetes).
A última batida da faixa é `B_FIM = floor(duracao * Ritmo.bpm / 60.0)`; a reta começa em `B_FIM - 16`.

**Ninguém espera mais de 8 batidas.** Se pular a batida do dono deixaria a próxima chance dele a mais de
`MAX_SEM_NOTA` batidas da última nota (`b - _ultima_b[l] + passo > 8`, com `passo` = `lista.size()`, ou 2
sozinho), a chance dessa batida é 1,0. `_ultima_b[l]` começa em 0.

Quem está errando (`Ritmo.simples[l]`) fica com a chance no máximo 0,5, fora do aríete e sem nota dupla. O
compasso é gerado um compasso antes de começar (`_gerar_compasso(c)` quando `Ritmo.batida() >= 4c − 4`), com
`rng` (a semente da partida) sorteando chance e lado.

### A pista

Na batida `b − 1`, menos a antecedência do cavaleiro: `t_pista = Ritmo.t_da_batida(b - 1) - CenarioDoImpacto.antecedencia(l)`,
nunca antes de `Ritmo.t_da_batida(b - 2) + 0.25` (a vibração do julgamento anterior do mesmo lugar já acabou).

- `Forja.sentir(l, "golpe_esq")` (lado 0) ou `"golpe_dir"` (lado 1): só o motor daquele lado, 250 ms. Lado 2:
  `Forja.sentir(l, "explosao", 250)` (os dois motores iguais, 1,0 / 1,0). Se devolver `true`, `j[l].rumble_ok = true`;
- **sem vibração** (`sentir` devolveu `false`: a vibração desligada nas Opções, ou o controle sem motor): o
  alto-falante do dono toca `Som.no_controle(l, "tique", 0.7)` uma vez (lado 0), duas (lado 1) ou três (lado 2),
  uma semicolcheia entre elas, e a pista vai ao registro com `canal` `alto_falante`;
- o `!` acima do boneco (sem lado) e a raia acesa pelo kit (`acender_raia(l, forca)`, com
  `forca = clampf(1.0 - absf(Ritmo.t_musica() - t) * 3.0, 0.0, 1.0)` da nota mais perto);
- o sopro no meio (`Som.tocar("sopro", null, -6.0)`): o som não entrega o lado;
- os outros presentes com controle ganham uma `chance` (o isolamento);
- o registro: `anotar("pista", l, {"n": b, "evento": "mandou", "canal": "rumble", "o_que": "esq"/"dir"/"ambos", "ok": ok})`.

### A defesa

Na batida `b`: L1 é a esquerda, R1 a direita. O aperto casa com a nota em aberto mais perto pelo
`casar_toque(l)` do kit (H08). Antes de chamar `julgar_toque` ou `nota_perdida`, ponha a nota em `_ultima[l]` (o
`toque` e a `falha` a leem).

- **lado certo** (lado 0 ou 1) → `julgar_toque(l, t, n, true)` (é perigo físico: a folga de quem está em último
  vale) e `Cega.certo(cega)`;
- **nota dupla** (lado 2) → o primeiro aperto guarda `_meio[l] = Ritmo.t_musica()`; o outro botão até `JUNTOS_S`
  depois → `julgar_toque(l, t, n, true)` (o julgamento é o do segundo aperto); os dois no mesmo quadro também
  valem; passados `JUNTOS_S` com um botão só → `nota_perdida(l, n)`;
- **lado errado** → `nota_perdida(l, n)` (o kit registra o erro e chama `falha()`) e `Cega.errado(cega, lado_feito)`;
- **nenhuma nota perto** → o fantasma (como hoje): `j[l].fantasmas += 1`, `marcar(l, FANTASMA)`, o `?` por 1 s,
  e `anotar("entrada", l, {"o": "fantasma", "golpe_de": "P%d" % (dono + 1)})` com o dono da nota dos outros mais
  perto no tempo.

Toda resposta grava a linha `entrada` `{"o": "resposta", "n": b, "lado_pedido": "esq"/"dir"/"ambos", "lado_feito": "esq"/"dir"/"ambos"/"nenhum"}`.
A nota que passa de `FOLGA_PERDIDA` (0,14 s) sem defesa é `nota_perdida(l, n)` e `Cega.perdido(cega)`.

**Os pontos** (no `toque`): `marcar(l, PONTOS[julgamento])`; o item (`Itens.pontos_do_acerto`) o kit já aplica.

**A vida:** começa em 5. Cada falha tira 1; **na reta, tira 2** (o objeto do placar vale o dobro). Nunca abaixo de
1; no treino, nada tira. Quatro perfeitos seguidos devolvem 1 (na reta, 2), até 5.

### O aríete

Na batida `4c + 2` de um compasso de aríete, além da defesa de cada um:

- o tronco do aríete (o objeto do cenário, abaixo) recua 1,5 m em `4c + 1` (curva `ENTRA`, 1 batida) e bate no
  portão no tempo `4c + 2` (curva `SAI`, 3 quadros);
- a rachadura do portão cresce: mais 3 traços (abaixo);
- o degrau **catástrofe**: `CenarioDoImpacto.exagero(self, _cenario, "catastrofe")` (tremor de 0,08 m por 4 batidas, sem
  hit-stop, a chave da luz +40 % por 1 batida);
- `Som.tocar("pedra", POS_PORTAO, 0.0)` e `Som.tocar("golpe", POS_PORTAO, -2.0)` na TV;
- `Forja.sentir(l, "golpe", 400)` em todos os presentes com controle;
- quem errou a defesa do aríete voa para trás: `ARIETE_M × gancho("empurrao") × Itens.resiste_a_empurrao(l)`,
  nunca menos de `EMPURRAO_MIN_M`, com o `fall` e o quique (abaixo);
- `momento("ariete", -1, POS_PORTAO, 2.6, {"compasso": c, "errou": "<lugares que erraram, P1,P3>"})`.

### A reta

Na batida `B_FIM - 16`: `momento("reta", -1, Vector3(0, 0, Z_JOGADOR), 1.8, {"objeto": "lanterna", "valores": "5,3,4,2"})`,
com a vida de cada lugar na ordem P1 a P4 (`-` para quem não está). Daí ao fim: a vida conta 2 por falha e 2 por
cura, e metade das notas são duplas.

### A bancada

Só com `Forja.bancada`. O `_bancada(dt)` é o `PAUSA`/`PERGUNTA`/`RESPOSTA` de hoje reduzido à cor: no começo
do compasso 16 e do 32 (`Ritmo.batida() >= 4 * c`), `_iniciar_pergunta()` (com o evento `pergunta` da F01,
`qual` = `"cor"`); em `PERGUNTA`, o laço de hoje (`impacto.gd:432-447`); em `RESPOSTA`, depois de 1,6 s,
`_luz_da_vida(l)` de cada um e `estado_bancada = JOGO`. Com a pergunta aberta, o `_piscar` não mexe na barra de
luz e `_gerar_compasso` não gera nada nesses compassos. Fora da bancada, nenhum `pergunta()` devolve nada e o
`lightbar` sai «não medido» (é o esperado: `SO_COM_PERGUNTA` da F01).

### O fim e o vencedor

Acaba pelo tempo (90 s de música, contados pelo kit). O vencedor é quem tem mais vida; no empate, mais pontos:

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if int(j[a].vida) != int(j[b].vida):
			return int(j[a].vida) > int(j[b].vida)
		return int(pontos[a]) > int(pontos[b]))
	return lista
```

### Com menos de quatro

- **Três:** a roda do dono gira (`b % 3`): cada um tem uma batida a cada três.
- **Dois:** um as pares, outro as ímpares; o aríete é dos dois.
- **Um:** só as batidas pares, todas dele; o isolamento não se mede (sem vizinho, nenhuma `chance`).
  `com_poucos()` devolve `"Só você na arena"` com um jogador (o texto da F02) e `""` com mais.
- **O controle que cai:** a pista não vai para quem está sem controle; as notas dele que passam enquanto está
  fora **não** viram erro (somem). Quando volta, as notas que já passaram somem e a próxima é a primeira que
  ainda não chegou. A vida dele fica como estava.

### Os ganchos

O que muda do `impacto.gd` de hoje, na ordem do arquivo:

| hoje | no Cerco |
| --- | --- |
| `class_name SalaImpacto`, `extends SalaJogo`, o cabeçalho | `extends Minigame`, sem `class_name`, o cabeçalho de «A ficha de dados» |
| `const F`, `RAIAS`, `Z_JOGADOR`, `POR_LADO`, `ONDAS`, `JANELA`, `GOLPE_MS`, `DANO`, `VIDA_MIN` | saem |
| `enum { PAUSA, GOLPE, VOANDO, PERGUNTA, RESPOSTA, ACABOU }` | `enum { JOGO, PERGUNTA, RESPOSTA }` em `estado_bancada` (só a bancada sai de `JOGO`) |
| `plano`, `i_plano`, `fim_onda`, `onda`, `atual`, `resposta`, `respondido` | `_notas := [[], [], [], []]`, `_gerado := 1`, `_fora := [false, false, false, false]`, `_ultima := [{}, {}, {}, {}]`, `_ultima_b := [0, 0, 0, 0]`, `_meio := [-1.0, -1.0, -1.0, -1.0]`, `_lanternas := [[], [], [], []]`, `_cenario := {}` |
| `_init()` | sai (a FICHA; a câmera vai para o `montar`) |
| `montar()`, `_montar_raia()` | o de «A cena» |
| `_novo_jogador()` | fica, sem `escudo_lado` de onda; `vida` vira `VIDA_MAX` (int); ganha `"perfeitos": 0`, `"pisca": 0.0`, `"volta": -1.0` (o t_musica em que o empurrão volta) |
| `_cor_da_vida`, `_luz`, `_luz_da_vida` | `_luz_da_vida(l)` = `if CenarioDoImpacto.luz_com_brilho(l, BRILHO[j[l].vida]): j[l].luz_ok = true` |
| `_conectado` | `conectado` (kit) |
| `_iniciar_golpe`, `_resolver`, o `match estado` do `jogar` | `_avisar`, `_defender`, `toque`, `falha`, `_golpe_passou`, `_ariete` e o `jogar` de baixo |
| `_mostrar_golpe` (277-300) | fica, com quatro trocas: o olho sai de 4,0 (linhas 284-285 e 296) para 1,2, o teto do mundo; o bloco das linhas 290-295 (`Som.tocar("bigorna")`, `falha`, `emote-no`) sai, porque o som e o gesto já moram em `toque`, `falha` e `_empurrar`; a bola `Kit.esfera` `#ff7a2a` vira a caixa 0,18 em `Tema.neon(Tema.VIOLETA, 1.2, "mundo")`; as faíscas viram `Forja.cor_do_lugar(l)` na defesa e `Tema.TUNGSTENIO` no golpe (sem `Tema.AMARELO`/`Tema.VERMELHO`) |
| `_iniciar_pergunta`, `_alguem_pergunta`, `_fechar_pergunta`, `_precisa_mais_cor`, `pergunta()` | ficam iguais, **só na bancada** |
| `dar_vereditos()` (459-472) | fica igual |
| `_process` / `_mostrar` (477-522) | `_mostrar(l, dt)` chamado do fim do `jogar`: escudos, `?`, a lanterna (`CenarioDoImpacto.acender_lanterna(_lanternas[l], j[l].vida, l)`); o `!` visível entre a pista e a resposta |
| `status()` | `""` quando `na_raia(l)` (o placar mora na lanterna); senão `super` |
| `progresso()` | sai (a barra de tempo do kit) |
| `dica()` | `{"partes": ["@l1", "@r1"], "pos": Vector3(RAIAS[l], 0.0, 4.6)}` quando `na_raia(l)` e `not aprendeu(l)`; senão `{}`. Sem palavra: durante o jogo, zero frase |
| `_robo` | `robo(l, dt)` de «O controle» |
| `com_poucos()` | o de «Com menos de quatro» |
| — | `combo(l)` (G04): `return int(j[l].perfeitos) if j.has(l) else 0` |

O esqueleto:

```gdscript
func montar() -> void:
	var pose := CenarioDoImpacto.pose_da_camera()
	camera_pos = pose[0]
	camera_olhar = pose[1]
	_cenario = CenarioDoImpacto.montar(self)
	_montar_cerco()  # o portão, o aríete (A cena)
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
		_bancada(dt)
	CenarioDoImpacto.passar(self, _cenario, no_pico())  # o pico da luz e da câmera, o tremor que acaba
	_ariete_no_tempo()  # recua em 4c+1, bate em 4c+2 (O aríete)
	_reta_no_tempo()  # a linha `reta` em B_FIM - 16
	var agora := Ritmo.t_musica()
	for l in presentes():
		_piscar(l, dt)
		_voltar(l)  # o empurrão volta depois da queda
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_notas[l] = _notas[l].filter(func(nt): return float(nt.t) > agora)
		for nt in _notas[l]:
			if not nt.avisada and agora >= _t_pista(l, nt):
				_avisar(l, nt)
		var esq := Forja.apertou(l, Forja.L1)
		var dir := Forja.apertou(l, Forja.R1)
		if esq or dir:
			_defender(l, 2 if esq and dir else (0 if esq else 1))
		_meio_passou(l, agora)  # a dupla com um botão só, depois de JUNTOS_S
		while not _notas[l].is_empty() and agora > float(_notas[l][0].t) + FOLGA_PERDIDA:
			_golpe_passou(l, _notas[l].pop_front())
		_mostrar(l, dt)


## As notas do compasso c (uma por batida do dono, pela chance do terço).
func _gerar_compasso(c: int) -> void:
	if c < 1 or (Forja.bancada and (estado_bancada != JOGO or c in COMPASSOS_DA_PERGUNTA)):
		return
	var lista := presentes()
	lista.sort()
	if lista.is_empty():
		return
	var terco := 0 if andamento() < 1.0 / 3.0 else (1 if no_pico() else 2)
	if terco == 1 and c % ARIETE_A_CADA == 3:
		for l in lista:
			if not Ritmo.simples[l]:
				_nova(l, 4 * c + 2, true)
		return
	var passo := 2 if lista.size() == 1 else lista.size()
	var b_fim := int(floor(duracao * Ritmo.bpm / 60.0))
	for k in 4:
		var b := 4 * c + k
		if lista.size() == 1 and b % 2 == 1:
			continue
		var l: int = lista[b % lista.size()]
		var chance: float = minf(DENSIDADE[terco], 0.5) if Ritmo.simples[l] else DENSIDADE[terco]
		if b - int(_ultima_b[l]) + passo > MAX_SEM_NOTA:
			chance = 1.0
		if rng.randf() < chance:
			var na_reta := b >= b_fim - BATIDAS_DA_RETA and not Ritmo.simples[l]
			_nova(l, b, false, na_reta)


func _nova(l: int, b: int, ariete: bool, na_reta := false) -> void:
	var lado := rng.randi_range(0, 1)
	if na_reta and rng.randf() < 0.5:
		lado = 2
	var nt := {"n": b, "b": b, "t": Ritmo.t_da_batida(b), "lado": lado, "avisada": false, "ariete": ariete}
	_notas[l].append(nt)
	_ultima_b[l] = b
	nova_nota(l, b, float(nt.t))


func _t_pista(l: int, nt: Dictionary) -> float:
	var b := float(nt.b)
	return maxf(Ritmo.t_da_batida(b - 1.0) - CenarioDoImpacto.antecedencia(l), Ritmo.t_da_batida(b - 2.0) + 0.25)


func toque(l: int, julgamento: int) -> void:
	var e: Dictionary = j[l]
	var nt: Dictionary = _ultima[l]
	marcar(l, PONTOS[julgamento])
	e.bloqueios += 1
	e.escudo = 1.0
	e.escudo_lado = int(nt.lado)
	if julgamento == Ritmo.PERFEITO:
		e.perfeitos += 1
		e.pisca = CenarioDoImpacto.PISCA_MAX  # o kit pisca branco; depois, o brilho da vida
		if e.perfeitos % PERFEITOS_PARA_CURAR == 0 and e.vida < VIDA_MAX and not treinando:
			e.vida = mini(VIDA_MAX, int(e.vida) + _vale())
			_luz_da_vida(l)
	else:
		e.perfeitos = 0
	Som.tocar("escudo", jogador(l).global_position + Vector3(0, 1.2, 0), -2.0)
	_mostrar_golpe(l, int(nt.lado), true)


func falha(l: int) -> void:
	var e: Dictionary = j[l]
	var nt: Dictionary = _ultima[l]
	e.perfeitos = 0
	Forja.sentir(l, "golpe")
	Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, 4)
	e.gatilho_ate = Ritmo.t_musica() + 0.25  # o _voltar põe o R2 em Off
	Som.tocar("golpe", jogador(l).global_position + Vector3(0, 1.2, 0), -2.0)
	if not treinando:
		e.vida = maxi(VIDA_MIN, int(e.vida) - _vale())
	e.pisca = CenarioDoImpacto.PISCA_MAX  # o kit escurece a cor; depois, o brilho da vida
	CenarioDoImpacto.exagero(self, _cenario, "golpe", jogador(l))
	_mostrar_golpe(l, int(nt.get("lado", 0)), false)
	_empurrar(l, ARIETE_M if bool(nt.get("ariete", false)) else EMPURRAO_M)


## O objeto do placar vale 2 na reta (a régua, item 5).
func _vale() -> int:
	return 2 if Ritmo.batida() >= floor(duracao * Ritmo.bpm / 60.0) - BATIDAS_DA_RETA else 1


## Depois do piscar do kit (H08: no máximo 0,5 s), o brilho da vida volta.
func _piscar(l: int, dt: float) -> void:
	if float(j[l].pisca) > 0.0:
		j[l].pisca = float(j[l].pisca) - dt
		if float(j[l].pisca) <= 0.0:
			_luz_da_vida(l)
```

`_avisar(l, nt)`, `_defender(l, lado)`, `_meio_passou(l, agora)`, `_golpe_passou(l, nt)`, `_ariete_no_tempo()`,
`_reta_no_tempo()`, `_empurrar(l, metros)` e `_voltar(l)` fazem o que as partes desta ficha dizem.
`_empurrar` e `_voltar` estão em «O cavaleiro».

O catálogo: `Catalogo.MINIGAMES["S04_J16"] = preload("res://scripts/minigames/s04/o_cerco.gd")`; na seção `S04`
de `SECOES`, `"minigames": ["S04_J16"]`; e sai `"impacto"` de `SALAS_ANTIGAS`.
`git rm godot/scripts/salas/impacto.gd godot/scripts/salas/impacto.gd.uid`.
Em `godot/scripts/traducoes.gd`: `"O Cerco": "The Siege"`, `"Defenda!": "Defend!"` (as que ainda não existirem).

## A cena

### A câmera

A arena do [cinema](../arte/01-cinema.md): lente de 35 mm (FOV vertical 37,8°), plongée de 50°, o modo `fixa` da
G05, e **não corta** do apito ao apito. `CenarioDoImpacto.pose_da_camera()` devolve
`[Vector3(0, 11.14, 7.68), Vector3(0, 0.8, -1.0)]`: o centro `(0, 0,8, −1,0)` visto a 13,5 m, 50° abaixo da
horizontal. Com 35 mm em 16:9, o quadro cobre de x = −8,2 a 8,2 no centro e, no chão, de z = 3,4 (a borda de
baixo) a z = −10,8 (a de cima): as quatro raias, as sentinelas, o portão e as lanternas cabem inteiros. A lente é
a da G05 (`main.gd` passa de 40° a 37,8°); até a G05 entrar, os 40° de hoje mostram 6 % a mais em volta e nada
sai do quadro.

- **O pico** (`no_pico()`): a câmera recua 10 % (`pose_da_camera(1.1)`: a 14,85 m) e volta ao sair do pico; o
  `lerp` do main faz o caminho (nunca salta).
- **O tremor é do evento**: só o de `CenarioDoImpacto.exagero` (abaixo). Nenhum tremor de ambiente, roll zero.

### A luz da seção

S4 é a tinta mostarda (`Tema.tinta_da_secao(4)`, que é `Tema.SECAO[3]`, `#c79a2a`), lado A. `Tema.luz_da_secao(4)` (G15) devolve a névoa
`#170e00`, o preenchimento `#493400` e a chave `#f8d096`. A névoa é do main (a G15 a põe pela seção do slot). O
cenário comum põe o preenchimento (o `atmosfera` da sala) e a chave (uma `OmniLight3D` em `(0, 8, 3)`, energia
0,9, alcance 26). As duas tochas do fundo, em `(±10, 2,4, −5)`, são `Tema.TUNGSTENIO`, energia 0,8, alcance 7.

- **O pico:** a chave sobe 20 % em 1 batida (curva `ENTRA_SAI`) e volta em 2 batidas quando o pico acaba. Com
  `Opcoes.flashes` desligado: +10 % em 2 batidas.
- **A catástrofe (o aríete):** a chave sobe 40 % por 1 batida e volta (a régua, o degrau catástrofe). Sem flashes: +20 %.

### As peças Kenney e o papel de cada uma

| peça | onde | papel |
| --- | --- | --- |
| `floor`, `floor-detail`, `wall`, `wall-half` | `Kit.arena(sala, 5, 3)` | o chão e as paredes da arena (de x −10 a 10, z −6 a 6) |
| `column` (escala 1,35) | duas por raia: `(RAIAS[l] ± 1.35, 0, Z_JOGADOR − 1.45)`, viradas para o boneco | a sentinela de pedra |
| `shield-round` (escala 2,4) | dois por raia, em `(RAIAS[l] ± 0.62, 0.95, Z_JOGADOR − 0.2)`, escondidos em 0,001 | o escudo que sobe na defesa (como hoje, `impacto.gd:136-141`) |
| `gate` (escala 2) | `POS_PORTAO = Vector3(0, 0, -7.0)`, de frente para a câmera | o portão do fundo, que o aríete racha |
| `wood-support` (escala 2) | dois, em `(±1.6, 0, −5.4)` | o cavalete que segura o aríete |

O que não é peça Kenney (caixas e cilindros do `Kit`, nenhuma esfera, nada metálico, `metallic` 0):

| objeto | forma | material |
| --- | --- | --- |
| o olho da sentinela | caixa 0,2 × 0,12 × 0,08 | `Tema.neon(Tema.VIOLETA, 1.2, "mundo")`; no tiro, 1,2 por 6 quadros (o teto do mundo) |
| o projétil | caixa 0,18 × 0,18 × 0,18 | `Tema.neon(Tema.VIOLETA, 1.2, "mundo")` |
| o aríete | `Kit.cilindro(raio 0.35, altura 3.0)` deitado no eixo z, de `(0, 1.1, −5.4)` | `Kit.material(Tema.OXIDO, 0.0, 0.9)`; as duas pontas, caixas 0,8 × 0,8 × 0,15 em `Kit.material(Tema.GRAFITE, 0.0, 0.7)` |
| a rachadura | caixas 0,08 × 1,2 × 0,02 na face do portão, em `POS_PORTAO + (x, y, 0.35)` | `Kit.material(Tema.JANELA, 0.0, 1.0)` |
| o poste da lanterna | caixa 0,08 × 1,3 × 0,08 | `Kit.material(Tema.GRAFITE, 0.0, 0.5)` |
| a brasa da lanterna | caixa 0,16 × 0,12 × 0,16 | `Tema.emissivo(m, 1.8, l)` acesa, 0 apagada (as lâmpadas do brilho) |
| o `!` | `Label3D`, `Tema.bungee()`, 160 px, `pixel_size` 0,005, billboard | `Tema.ETIQUETA`, contorno 18 em `Tema.FITA` |
| o `?` | `Label3D`, `Tema.bungee()`, 110 px | `Tema.MUDO`, contorno 18 em `Tema.FITA` |

**A rachadura cresce a cada aríete.** O aríete `k` (1 a 4) acrescenta 3 traços. Os traços são fixos (nada de
sorteio): em x `[-0.3, 0.1, 0.4]`, y `[1.1, 1.5, 0.8]`, rotação em z `[-20°, 15°, -35°]` para o primeiro aríete,
e o mesmo deslocado de x +0,35 × (k − 1) e y +0,25 × (k − 1) para os outros. Ficam até o fim: é o rastro do
momento.

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08) |
| a brasa acesa da lanterna | o lugar | 1,8 |
| a luz da lanterna (`OmniLight3D` em cima dela) | o lugar | `0.6 + 0.06 * vida` (0,9 com 5 brasas), alcance 3,4 |
| as faíscas da defesa | o lugar | `Efeitos.faiscas(self, ate, Forja.cor_do_lugar(l), 28, 1.0)` |
| as faíscas do golpe que entra | a forja | `Efeitos.faiscas(self, ate, Tema.TUNGSTENIO, 28, 1.0)` |
| o olho e o projétil da sentinela | o mundo | 1,2 (o teto do mundo), `Tema.VIOLETA` |
| as tochas | a forja | `Tema.TUNGSTENIO`, luz 0,8 |

Nenhuma cor fora dos tokens: os `#6fa8ff`, `#3b6bff`, `#6b6fb0`, `#ffb070`, `#ff4a2a`, `#4a4e5e` e `#ff7a2a` de
hoje somem. O vermelho do golpe não existe: o golpe que entra é tungstênio, e quem diz que errou é a silhueta.

### O cenário comum (`godot/scripts/minigames/s04/cenario_do_impacto.gd`)

O arquivo inteiro:

```gdscript
class_name CenarioDoImpacto
extends RefCounted
## O cenário comum d'O Impacto (S04, docs/jogo/tarefas/L-o-impacto.md): a
## arena da tinta mostarda, as sentinelas de pedra com o olho do mundo, a
## lanterna da vida de cada raia, a barra de luz com brilho, a câmera da
## arena, o exagero do impacto e os ganchos do cavaleiro. Os cinco minigames
## da seção montam com isto; o que é só de um fica no script dele.

const SECAO := 4  ## a S4: Tema.tinta_da_secao(4) é Tema.SECAO[3], a mostarda
## O brilho mínimo da barra de luz na seção (o piso do F04 é 30%).
const BRILHO_MIN := 0.4
## O piscar de outra cor, no máximo (F04).
const PISCA_MAX := 0.5
## A arena (docs/jogo/arte/01-cinema.md): 35 mm, plongée de 50°, a 13,5 m.
const CAMERA_OLHAR := Vector3(0, 0.8, -1.0)
const CAMERA_ANGULO := 50.0
const CAMERA_DISTANCIA := 13.5
## O exagero do impacto (docs/jogo/diversao/README.md#o-exagero-do-impacto).
const DEGRAUS := {
	"golpe": {"tremor_m": 0.02, "batidas": 1.0, "hit_stop": 2, "luz": 0.0},
	"estrondo": {"tremor_m": 0.05, "batidas": 2.0, "hit_stop": 3, "luz": 0.0},
	"catastrofe": {"tremor_m": 0.08, "batidas": 4.0, "hit_stop": 0, "luz": 0.4},
}
## O main treme a câmera 0,12 m por unidade de `tremor` (main.gd:986-988).
const METROS_POR_TREMOR := 0.12
## Os ganchos dos stats no neutro (stat 3), enquanto a classe Cavaleiro (G13)
## não existe (docs/jogo/sistemas/stats.csv).
const NEUTRO := {"empurrao": 1.0, "tranco": 1.0, "ruido": 1.0, "velocidade": 1.0, "levantar": 1.0, "pista": 0.0, "raio": 1.0}


## A pose da câmera da arena: [posição, alvo]. `recuo` 1,1 no pico.
static func pose_da_camera(recuo := 1.0, olhar := CAMERA_OLHAR) -> Array:
	var a := deg_to_rad(CAMERA_ANGULO)
	return [olhar + Vector3(0, sin(a), cos(a)) * CAMERA_DISTANCIA * recuo, olhar]


## A arena da tinta mostarda. `escuro` 1,0 é O Impacto; 0,35 é o terror d'A
## Prensa (a luz da casa escurece, não troca). Devolve {chave, chave_energia,
## pico, tremor_ate, luz_ate}: o que `passar` e `exagero` mexem.
static func montar(sala: SalaJogo, escuro := 1.0) -> Dictionary:
	Kit.arena(sala, 5, 3)
	var luz: Dictionary = Tema.luz_da_secao(SECAO)
	sala.atmosfera(luz.preenchimento, Tema.VIOLETA, false, 30, 22.0, -7.8, 0.35 * escuro)
	var chave := OmniLight3D.new()
	chave.position = Vector3(0, 8.0, 3.0)
	chave.light_color = luz.chave
	chave.light_energy = 0.9 * escuro
	chave.omni_range = 26.0
	sala.add_child(chave)
	for x in [-10.0, 10.0]:
		var tocha := OmniLight3D.new()
		tocha.position = Vector3(x, 2.4, -5.0)
		tocha.light_color = Tema.TUNGSTENIO
		tocha.light_energy = 0.8 * escuro
		tocha.omni_range = 7.0
		sala.add_child(tocha)
	return {"chave": chave, "chave_energia": chave.light_energy, "pico": false, "tremor_ate": -1.0,
		"luz_ate": -1.0, "luz_extra": 0.0, "pose": pose_da_camera()}


## A cada quadro: o pico (a chave +20 % em 1 batida, a câmera recua 10 %), o
## tremor que acaba e a luz da catástrofe que volta.
static func passar(sala: SalaJogo, c: Dictionary, no_pico: bool) -> void:
	var agora := Ritmo.t_musica()
	var batida := 60.0 / Ritmo.bpm
	if no_pico != bool(c.pico):
		c.pico = no_pico
		var pose := pose_da_camera(1.1 if no_pico else 1.0)
		sala.camera_pos = pose[0]
		sala.camera_olhar = pose[1]
		var sobe := (0.2 if Opcoes.flashes else 0.1) if no_pico else 0.0
		var em := (1.0 if Opcoes.flashes else 2.0) if no_pico else 2.0
		var tw := sala.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(c.chave, "light_energy", float(c.chave_energia) * (1.0 + sobe), em * batida)
	if float(c.tremor_ate) >= 0.0 and agora >= float(c.tremor_ate):
		sala.tremor = 0.0
		c.tremor_ate = -1.0
	if float(c.luz_ate) >= 0.0 and agora >= float(c.luz_ate):
		(c.chave as OmniLight3D).light_energy = float(c.chave_energia) * (1.2 if c.pico and Opcoes.flashes else 1.0)
		c.luz_ate = -1.0


## O exagero do impacto, pelo degrau: o tremor (em m, por batidas), o hit-stop
## do boneco (em quadros) e a luz da catástrofe (por 1 batida).
static func exagero(sala: SalaJogo, c: Dictionary, degrau: String, boneco: Node3D = null) -> void:
	var d: Dictionary = DEGRAUS[degrau]
	var batida := 60.0 / Ritmo.bpm
	sala.tremor = maxf(sala.tremor, float(d.tremor_m) / METROS_POR_TREMOR)
	c.tremor_ate = Ritmo.t_musica() + float(d.batidas) * batida
	if int(d.hit_stop) > 0 and boneco and Opcoes.tremor:
		congelar(boneco, int(d.hit_stop))
	if float(d.luz) > 0.0:
		var k := float(d.luz) if Opcoes.flashes else float(d.luz) * 0.5
		(c.chave as OmniLight3D).light_energy = float(c.chave_energia) * (1.0 + k)
		c.luz_ate = Ritmo.t_musica() + batida


## O hit-stop visual: a animação do boneco para `quadros` quadros (60 por s).
## O relógio, o julgamento e a física nunca param.
static func congelar(boneco: Node3D, quadros: int) -> void:
	var anim: AnimationPlayer = boneco.get("anim")
	if anim == null:
		return
	var antes := anim.speed_scale
	anim.speed_scale = 0.0
	boneco.get_tree().create_timer(quadros / 60.0).timeout.connect(func(): anim.speed_scale = antes)


## A luz das outras raias cai 30 % por 1 batida (o momento de um só).
static func so_o_dono(sala: Minigame, dono: int) -> void:
	var batida := 60.0 / Ritmo.bpm
	for l in sala.presentes():
		if l == dono:
			continue
		var r: Dictionary = sala._raias.get(l, {})
		if r.is_empty():
			continue
		var luz: OmniLight3D = r.luz
		var antes := luz.light_energy
		luz.light_energy = antes * 0.7
		sala.get_tree().create_timer(batida).timeout.connect(func(): luz.light_energy = antes)


## O gancho do stat do cavaleiro do lugar (docs/jogo/sistemas/README.md#os-stats):
## o da classe Cavaleiro (G13) quando ela existe; o neutro enquanto não.
static func gancho(l: int, nome: String) -> float:
	for c in ProjectSettings.get_global_class_list():
		if c["class"] == "Cavaleiro":
			return float(load(c["path"]).gancho(l, nome))
	return float(NEUTRO[nome])


## A antecedência do aviso do lugar, em s: o Faro (±40 ms) e a Lanterna (meio tempo).
static func antecedencia(l: int) -> float:
	return gancho(l, "pista") / 1000.0 + Itens.antecipacao_s(l, Ritmo.bpm)


## A queda do lugar, em s: `tempos` × o Fôlego, arredondada à semicolcheia, no
## mínimo uma (docs/jogo/sistemas/README.md, o levantar).
static func queda_s(l: int, tempos: float) -> float:
	var semi := 60.0 / Ritmo.bpm / 4.0
	return maxf(semi, roundf(tempos * gancho(l, "levantar") * 4.0) * semi)


## Uma sentinela: a coluna do kit virada para `alvo`, com o olho (uma caixa
## no néon do mundo) na frente. Devolve {corpo, olho, mat}.
static func sentinela(pai: Node3D, pos: Vector3, alvo: Vector3, escala := 1.35) -> Dictionary:
	var corpo := Kit.peca(pai, "column", pos, 0.0, escala)
	var d := Vector3(alvo.x - pos.x, 0.0, alvo.z - pos.z).normalized()
	corpo.rotation.y = atan2(d.x, d.z)
	var mat := Tema.neon(Tema.VIOLETA, 1.2, "mundo")
	var olho := Kit.caixa(pai, Vector3(0.2, 0.12, 0.08), pos + Vector3(0, 0.95 * escala, 0) + d * 0.3, mat)
	olho.rotation.y = corpo.rotation.y
	return {"corpo": corpo, "olho": olho, "mat": mat}


## A lanterna da vida: um poste de grafite com `n` brasas (caixas) na cor do
## lugar, de baixo para cima. Devolve os materiais das brasas.
static func lanterna(pai: Node3D, pos: Vector3, l: int, n := 5) -> Array:
	Kit.caixa(pai, Vector3(0.08, 1.3, 0.08), pos + Vector3(0, 0.65, 0), Kit.material(Tema.GRAFITE, 0.0, 0.5))
	var mats: Array = []
	for k in n:
		var m := Kit.material(Tema.JOGADOR[l].darkened(0.6), 0.0, 0.7)
		Tema.emissivo(m, 1.8, l)
		Kit.caixa(pai, Vector3(0.16, 0.12, 0.16), pos + Vector3(0, 1.38 + 0.15 * k, 0), m)
		mats.append(m)
	return mats


## Acende as `acesas` primeiras brasas (1,8, as lâmpadas) e apaga as outras.
## O brilho passa sempre pelo Tema.emissivo (o portão 6 reprova emission fora do tema.gd).
static func acender_lanterna(mats: Array, acesas: int, l: int) -> void:
	for k in mats.size():
		Tema.emissivo(mats[k], 1.8 if k < acesas else 0.0, l)


## A barra de luz do lugar na cor dele, com o brilho pedido (nunca abaixo de
## BRILHO_MIN). Devolve o que o Forja.luz devolveu (o SDL aceitou).
static func luz_com_brilho(l: int, brilho: float) -> bool:
	var c := Forja.cor_do_lugar(l)
	var k := clampf(brilho, BRILHO_MIN, 1.0)
	return Forja.luz(l, Color(c.r * k, c.g * k, c.b * k))
```

O `so_o_dono` lê `_raias` do kit (H04: `lugar -> {raiz, mat_borda, luz}`). O néon da `atmosfera` (energia 3,0
hoje) é da G15, que passa os 17 materiais pelo `Tema.neon`: esta ficha não mexe nele.

### A montagem do Cerco

- Por lugar presente: `raia(l)`; `posicionar(l)`; `jogador(l).rotation.y = PI` (de costas para a câmera, de
  frente para as sentinelas) e `jogador(l).preso = true`.
- As duas sentinelas de cada raia:
  `CenarioDoImpacto.sentinela(self, Vector3(RAIAS[l] + (-1.35 if lado == 0 else 1.35), 0.0, Z_JOGADOR - 1.45), Vector3(RAIAS[l], 0, Z_JOGADOR))`.
- A lanterna da vida: `_lanternas[l] = CenarioDoImpacto.lanterna(self, Vector3(RAIAS[l] + 1.25, 0, Z_JOGADOR + 0.45), l, VIDA_MAX)`
  e a `OmniLight3D` da cor do lugar em cima dela.
- O portão, o cavalete e o aríete: `_montar_cerco()`, com as peças e as caixas das tabelas acima.

## O som

Os ids do [mapa do áudio](../audio/mapa.csv). Todos já existem; nenhum som novo.

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| a pista | `Som.tocar("sopro", null, -6.0)`, no meio (sem lado) | — (sem vibração: `tique` 1×, 2× ou 3×) | `sint_sopro`; `tique_0..2` |
| a defesa certa | `Som.tocar("escudo", pos, -2.0)`, no boneco | o julgamento do kit (`jul_*`, H11) | `escudo_0..4` |
| o golpe que entra | `Som.tocar("golpe", pos, -2.0)`, no boneco | o julgamento do kit (`jul_erro_p{n}`) | `golpe_0..4` |
| o aríete no portão | `Som.tocar("pedra", POS_PORTAO, 0.0)` e `Som.tocar("golpe", POS_PORTAO, -2.0)` | — | `pedra_0..4`, `golpe_0..4` |
| a brasa que volta | `Som.tocar("confirma", pos_da_brasa, -6.0)` | — | `confirma_0..2` |
| o fantasma | — | — | — |
| a faixa | `MUS_S04_J16`: 140 BPM, Dó menor, 150 s; até ela existir, a reserva `sint_trilha` da H05 | — | `mus_s04_j16` |

- **O `falha` sai.** O `Som.tocar("falha")` de hoje (`impacto.gd:293`) é um bipe de erro, que a bíblia proíbe. O
  golpe que entra soa como corpo (`golpe_*`); o erro de julgamento é do kit (`jul_erro_p{n}`, e o `fx_tropeco_*`
  quando a H11 trocar a falha da TV). O Cerco nunca chama `"falha"`.
- **O alto-falante toca um som por vez** e o julgamento tem a vez: o Cerco não põe `escudo` nem `golpe` no
  alto-falante, porque o `jul_*` do kit chega no mesmo quadro.
- **A mixagem é da H11**: o Ambiente −6 dB no minigame e +3 dB no último terço (a faixa pede «arena pesada: os
  golpes por cima»). O Cerco não mexe em barramento.
- O material `"pedra"` da FICHA: o kit toca `mod_material_pedra` nos atuadores no acerto (H07/H08).

## O controle

Evento por evento, para quem joga e para os outros. O piso é o da F05; o gatilho usa os modos de `forja.gd`.

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| a pista (lado 0 ou 1) | só o dono da nota | `golpe_esq` (1,0 / 0) ou `golpe_dir` (0 / 1,0), 250 ms | — | — | — |
| a pista dupla (reta) | só o dono | `explosao` com 250 ms (1,0 / 1,0) | — | — | — |
| a pista sem vibração | só o dono | — | — | — | `tique` 1×, 2× ou 3×, uma semicolcheia entre eles |
| a defesa julgada | o dono | `acerto`, `perfeito` ou `erro` (o kit) | — | o kit: branco 0,15 s no perfeito (sem flashes: parada); a cor escurecida 0,5 s no erro | `jul_*` (o kit) |
| o golpe que entra | o dono | `golpe` (1,0 / 0,6, 250 ms): os dois motores, para nunca parecer pista | R2 em Resistência (2, 4) por 250 ms, depois Off | um degrau abaixo (`BRILHO[vida]`) | `jul_erro_p{n}` (o kit) |
| o aríete no portão | todos com controle | `golpe` com 400 ms | — | — | — |
| a brasa que volta | o dono | — (o `perfeito` do kit já vibrou) | — | um degrau acima | — |
| começar | todos | — | `gatilhos_off(l)`: o R2 só se mexe no golpe; o L2 é do item (G03) | `BRILHO[5]` = 100 % | — |

- A barra de luz é **sempre a cor do lugar**, com o brilho da vida (40 % a 100 %, nunca abaixo do piso de 30 %
  da F04). Ela nunca mostra lado, munição nem pergunta fora da bancada.
- As luzinhas de jogador mostram o número do lugar, sempre; ninguém mexe nelas fora da bancada.
- O microfone não se usa.
- **Os outros não sentem nada** da pista de um: o isolamento é medido (as `chance` e os `fantasmas`).

### O robô

```gdscript
# O robô sente o motor que ligou no controle simulado. Pista: um motor só (o
# lado), ou os dois iguais (a dupla). O golpe (1,0/0,6) e as sensações do kit
# têm os motores diferentes: não são pista.
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
	var um := (forte > 0.3 and fraco < 0.05) or (fraco > 0.3 and forte < 0.05)
	var dois := forte > 0.3 and fraco > 0.3 and absf(forte - fraco) < 0.05
	var pista := um or dois
	if pista and not _robo_ligado[l] and _robo_alvo[l] < 0.0:
		_robo_alvo[l] = roundf(Ritmo.batida() + CenarioDoImpacto.antecedencia(l) * Ritmo.bpm / 60.0) + 1.0
		_robo_lado[l] = 2 if dois else (0 if forte > fraco else 1)
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, chega 250 ms tarde
		_robo_atraso[l] = 0.0 if Forja.robo_acerta() else 0.25
	_robo_ligado[l] = pista
	if _robo_alvo[l] >= 0.0 and Ritmo.t_musica() >= Ritmo.t_da_batida(_robo_alvo[l]) + float(_robo_atraso[l]):
		if _robo_lado[l] != 1:
			Forja.robo_apertar(l, Forja.L1, 0.06)
		if _robo_lado[l] != 0:
			Forja.robo_apertar(l, Forja.R1, 0.06)
		_robo_alvo[l] = -1.0
	# a bancada: a pergunta da cor, como hoje (impacto.gd:589-597), com _cor_mais_perto
	if Forja.bancada and estado_bancada == PERGUNTA and j[l].cor_pedida >= 0 and j[l].cor_resposta < 0:
		j[l].robo_cor = float(j[l].robo_cor) - _dt
		if j[l].robo_cor <= 0.0:
			Forja.robo_apertar(l, BOTAO_COR[_cor_mais_perto(pc.get("luz", Color.BLACK))], 0.08)
			j[l].robo_cor = 10.0
```

O `robo_cor` vai para `0.7 + 0.8 * rng.randf()` quando a pergunta abre, e a `_cor_mais_perto` de hoje
(`impacto.gd:600-609`) é copiada igual. Na defesa, o robô **não** lê a partitura: se a vibração não chegou ao
controle simulado, ele não defende. É a prova do caminho inteiro, e a do simulador: a mesma conta roda no
controle simulado da prova do jogo e no da prova visual.

## O cavaleiro

O cavaleiro é o da montagem (G13): a cabeça, a parte de cima e a de baixo que a pessoa escolheu aparecem como
estão, de costas para a câmera. `posicionar(l)` deixa as mãos livres: a arma ou o amuleto não aparece no Cerco
(os dois escudos do minigame são os da defesa), mas o efeito do item vale. O cavaleiro pode ser de outra raça
(G13, o ajuste dela de 09/10): esta ficha não supõe corpo humano; usa só o esqueleto comum de 7 ossos e as
animações `interact-left`, `interact-right`, `emote-no` e `fall`.

| stat | gancho | o que muda no Cerco | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | o quanto o golpe que entra empurra para trás | 0,70 m | 0,60 m | 0,50 m (o piso) |
| Passo | — | não age: o boneco fica preso na raia | — | — | — |
| Fôlego | `levantar` | quanto tempo o empurrão dura antes de voltar (a queda de 2 tempos) | 2,5 tempos | 2 tempos | 1,5 tempo |
| Faro | `pista` | a pista chega antes; a nota cai no mesmo tempo | −40 ms | 0 | +40 ms |

Os itens: o Escudo absorve o primeiro erro (o kit, G03); a Âncora divide o empurrão por 2 (até o piso de 0,5 m); a
Lanterna adianta a pista meio tempo (`Itens.antecipacao_s`); o Martelo dobra o perfeito no tempo forte (o kit). Os
números da régua: nenhum stat muda a janela de julgamento; o stat 5 nunca tira a falha física (o piso de 0,5 m) nem
o aríete.

```gdscript
## O golpe que entra: o boneco vai para trás (+z), em 1 colcheia, `QUICA`, e
## fica lá a queda do Fôlego; depois volta em 1 batida (`MOLA`).
func _empurrar(l: int, base_m: float) -> void:
	var p := jogador(l)
	var m := maxf(EMPURRAO_MIN_M, base_m * CenarioDoImpacto.gancho(l, "empurrao") * Itens.resiste_a_empurrao(l))
	var colcheia := 30.0 / Ritmo.bpm
	var tw := p.create_tween()
	tw.tween_property(p, "position:z", Z_JOGADOR + m, colcheia).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	p.gesto("fall" if m >= ARIETE_M * 0.9 else "emote-no", colcheia * 2.0)
	j[l].volta = Ritmo.t_musica() + CenarioDoImpacto.queda_s(l, QUEDA_TEMPOS)


func _voltar(l: int) -> void:
	var e: Dictionary = j[l]
	if float(e.get("gatilho_ate", -1.0)) >= 0.0 and Ritmo.t_musica() >= float(e.gatilho_ate):
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)
		e.gatilho_ate = -1.0
	if float(e.volta) >= 0.0 and Ritmo.t_musica() >= float(e.volta):
		e.volta = -1.0
		var p := jogador(l)
		p.create_tween().tween_property(p, "position:z", Z_JOGADOR, 60.0 / Ritmo.bpm) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
```

O erro não tem squash. O desregistro do erro (o contorno de 2,4 a 0,6, o tremor de ±0,02 m por 3 quadros, a
animação a 0,5×) é do kit e da G08; o Cerco só soma o empurrão.

## As reações

- **Carimbos que o Cerco pode disparar** (todos são do kit e do HUD, G04; o Cerco não chama nenhum):
  `car_em_chamas` (5 Ressonâncias seguidas do mesmo lugar: as defesas perfeitas contam), `car_acorde` (os quatro
  na Ressonância no mesmo tempo 1: só acontece no aríete, que cai no tempo 3, então não acontece; e na reta, por
  acaso do hoqueto, também não, porque cada batida tem um dono), `car_por_um_fio` (o vencedor por 2 % dos pontos
  ou menos, no resultado). O `car_virada` é do placar, não do minigame.
- **Adesivos:** ninguém está fora da rodada no Cerco (a vida nunca chega a 0), então ninguém manda adesivo
  durante o jogo.
- Nenhum carimbo próprio de minigame.

## A diversão

**O momento: o aríete** (`ariete`). No pico, o compasso inteiro vira um golpe só, de todos, na batida 3. As
quatro sentinelas disparam juntas, cada uma de um lado sorteado; os quatro apertam juntos. O aríete bate no portão
do fundo, e quem errou voa um passo para trás. Degrau catástrofe: o aríete tem 3 m, a luz sobe 40 %, o tremor é de
0,08 m por 4 batidas.

- **Rastro:** a rachadura no portão cresce a cada aríete e fica até o fim; quem errou fica com a brasa da
  lanterna apagada.
- **A curva:** de 0 a 30 s, chance 0,5 e aprende-se o lado; de 30 a 60 s, o pico (chance 1,0 e o aríete); de 60 s
  ao fim, a reta (chance 0,75, e nas últimas 16 batidas metade das notas são as duas sentinelas juntas: L1 e R1).
  Não é regra nova: é o aríete de um só.
- **Ensina sem falar:** o primeiro golpe de cada um vem só depois da pista; o projétil sai do olho da sentinela
  daquele lado. Na terceira vez, a mão já sabe.
- **Quem está perdendo:** a vida nunca cai abaixo de 1; quatro perfeitos seguidos devolvem uma brasa.
- **A regra da seção:** a pista é privada e a consequência é pública. Nada na tela diz o lado.
- **A nota de hoje:** 3. Gênero da FICHA: `sobrevivencia` (o RPG põe o Cerco aí: o Peso é o principal); a diversão
  o chama de todos contra todos porque cada um joga por si. Os dois valem; a FICHA fica com `sobrevivencia`.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7, sem a
bancada, pela prova visual da F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem uma linha `toque` com `t_musica` ≤ 10,0 | o quadro de 10 s mostra um escudo levantado ou um empurrão |
| 4. o momento | pelo menos 2 linhas `momento` `ariete` com `t_musica` entre 30 e 60 | o quadro de 60 s mostra o portão rachado |
| 5. a curva | notas por segundo no 2.º terço ≥ 1,5 × as do 1.º; no 3.º ≥ 1,0 ×; a linha `momento` `reta` existe | o quadro do meio do 2.º terço tem a luz 20 % acima do quadro do meio do 1.º |
| 6. a falha | o P4 tem pelo menos 10 linhas `toque` com `erro` | 1 quadro em 5 mostra o P4 fora do lugar ou com brasa apagada |
| 7. quem perde joga | a maior distância entre duas linhas `nota` seguidas de cada lugar é de até 8 batidas; o P4 tem um `toque` BOM ou melhor em cada terço | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | cada `ariete` tem 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,08 | a rachadura se vê no quadro de 480 × 270 sem ampliar |
| 9. o impacto | para cada `ariete`, uma linha `sensacao` `golpe` a até 16,7 ms, a até 1 quadro de uma batida | o quadro seguinte ao aríete ainda mostra a rachadura |
| 10. o placar no mundo | a ordem do `vencedor()` bate com a ordem das vidas no `momento` `reta` e no fim | no quadro de 60 s, quem olha diz a ordem pelas lanternas, e ela bate com o registro |

Até o robô por lugar (`--robo=bom,medio,medio,ruim`, pedido ao arquiteto na régua) existir, a prova roda com
`--robo=medio` nos quatro e confere os itens 1, 4, 5, 8, 9 e 10; os itens 6 e 7 (que pedem o P4 `ruim`) esperam o
robô por lugar.

## Pronto quando

O Cerco joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos; aguenta o cabo
que cai e volta; fecha sempre com vencedor; `--sala=impacto` abre o `S04_J16`; o aríete aparece pelo menos 2 vezes
entre 30 e 60 s e racha o portão; com `--bancada`, a pergunta da cor aparece nos compassos 16 e 32 e os quatro
vereditos saem como antes; a prova do jogo passa (sem e com `--bancada`); e `bash tests/prova_visual.sh` passa
com a prancha olhada.

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, a checagem do Cerco usa o `_joga_o_minigame(slot, limite_s, a_cada_quadro)`
da H08 (abre pelo catálogo, deixa o aviso passar em quadros e espera o fim pelo relógio de parede: 90 s de música
e o treino cabem em 130 s). Chame-a no percurso logo depois da última sala de hoje (antes do relatório):

```gdscript
## O Cerco (S04_J16): o apelido abre o minigame; a pista chega só no motor do
## lado; o golpe que entra põe o R2 em Resistência; a barra de luz fica na cor
## do lugar; o registro tem a pista, a resposta e os momentos.
func _prova_do_cerco() -> void:
	var lados := {}
	var fora_do_tom := [0]
	var amostras := [0]
	var resistencia := [false]
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			var pc := Forja.percepcao(l)
			var forte := float(pc.get("forte", 0.0))
			var fraco := float(pc.get("fraco", 0.0))
			if forte > 0.3 and fraco < 0.05:
				lados["esq"] = true
			if fraco > 0.3 and forte < 0.05:
				lados["dir"] = true
			if int(pc.get("gatilho_dir", 0)) == 0x21:
				resistencia[0] = true
			amostras[0] += 1
			if not _mesmo_tom(pc.get("luz", Color.BLACK), Forja.cor_do_lugar(l)):
				fora_do_tom[0] += 1
	var mg = await _joga_o_minigame("impacto", 130.0, olhar)
	if mg == null:
		return
	_esperar(mg.id == "S04_J16", "Cerco: --sala=impacto abre o S04_J16")
	_esperar(lados.size() == 2, "Cerco: a pista chegou só no motor de um lado, dos dois lados (%s)" % [lados.keys()])
	_esperar(resistencia[0], "Cerco: o golpe que entra põe o R2 em Resistência (0x21)")
	_esperar(fora_do_tom[0] * 4 <= amostras[0], "Cerco: a barra de luz na cor do lugar (%d de %d fora)" % [fora_do_tom[0], amostras[0]])
	var v := mg.vencedor()
	_esperar(not v.is_empty() and int(mg.j[v[0]].vida) == v.map(func(l): return int(mg.j[l].vida)).max(), "Cerco: o vencedor tem a maior vida")
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S04_J16")
	var pistas := linhas.filter(func(e): return e.get("tipo") == "pista" and e.get("evento") == "mandou")
	var toques := linhas.filter(func(e): return e.get("tipo") == "toque")
	var arietes := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "ariete" \
		and float(e.get("t_musica", 0.0)) >= 30.0 and float(e.get("t_musica", 0.0)) <= 60.0)
	var reta := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "reta")
	_esperar(pistas.size() >= 1 and toques.size() >= 1, "Cerco: o registro tem %d pistas e %d toques" % [pistas.size(), toques.size()])
	_esperar(arietes.size() >= 2, "Cerco: %d aríetes entre 30 e 60 s (o mínimo é 2)" % arietes.size())
	_esperar(reta.size() == 1, "Cerco: a linha momento reta aparece uma vez")
	for a in arietes:
		_esperar(float(a.get("x_tela", 0.0)) >= 0.2 and float(a.get("x_tela", 0.0)) <= 0.8 \
			and float(a.get("altura_tela", 0.0)) >= 0.08, "Cerco: o aríete no meio da tela (%s)" % [a])
	if not Forja.bancada:
		_esperar(_linha_do_tempo().filter(func(e): return e.get("o") == "pergunta" and e.get("sala", e.get("slot", "")) == "S04_J16").is_empty(), "Cerco: fora da bancada, nenhuma pergunta")
```

(`_mesmo_tom` é da F04 e `_linha_do_tempo` da F01; as duas já estão na prova. As checagens que hoje olham
`"impacto"` pelo id, como as de `SO_COM_PERGUNTA`, passam a olhar pelo apelido com `_e_a_sala` da H04.)

### O que o registro mede

- `sensacao` `golpe_esq`/`golpe_dir`/`explosao`/`golpe` (F05) e a `saida` de vibração com `seq` e `ok` (F06).
- `pista` (`canal` `rumble`, ou `alto_falante` sem vibração) (n, lado, ok); `entrada` `resposta` (n, lado pedido,
  lado feito); `entrada` `fantasma` (golpe de quem); o `toque` do kit; `momento` `ariete` e `reta`.
- Na bancada, além disso, a `pergunta` da cor e a `resposta_cor` de hoje, e os quatro vereditos (`dar_vereditos`),
  calculados e gravados nos dois modos.

### As pranchas que o jogador do time olha

A prancha da prova visual (`SAIDA/prancha-<n>.png`, um quadro de 480 × 270 a cada 2 s): o quadro de 10 s (um
escudo ou um empurrão), o de 45 s (a luz do pico e a câmera mais longe), o de 60 s (o portão rachado; a ordem
das lanternas, anotada aqui na ficha), e os das últimas 16 batidas (as duplas: os dois escudos juntos).

### O que o André joga e sente

`./run-local.sh -- --sala=impacto`, com quatro DualSense, dois no cabo e dois no rádio:

- de olhos fechados, a pista esquerda é só na mão esquerda, a direita só na direita, a dupla nas duas; a
  vibração de um vizinho não se sente no seu controle;
- a pista chega uma batida antes e dá tempo de defender no tempo;
- o aríete no meio assusta (todos juntos), o portão racha, e a sala fica no ritmo;
- o golpe que entra empurra o cavaleiro e o R2 endurece por um instante;
- a barra de luz escurece com a vida e nunca troca de cor; as luzinhas mostram o número o tempo todo;
- com `--bancada`, a pergunta da cor aparece duas vezes e some sem ela.

### Armadilhas

- **A pista e a sensação do kit não caem juntas no mesmo controle.** O `acerto`/`erro` do kit liga os dois
  motores; se cair no instante de uma pista, o lado se perde. Por isso o mesmo lugar nunca tem golpe em duas
  batidas seguidas, e a pista nunca sai antes de `t_da_batida(b − 2) + 0,25`.
- **`Forja.vibrar` não é para a sala** (F05): só `Forja.sentir`.
- **A barra de luz:** nunca `Forja.luz` com cor que não seja a do lugar, a não ser a pergunta da bancada; o piscar
  do perfeito e do erro é do kit, e o minigame só põe de volta o brilho da vida.
- **O `_ultima[l]`** tem de estar posto antes de `julgar_toque`/`nota_perdida`: o kit chama `toque`/`falha` de
  dentro deles, na mesma linha.
- **O mundo se mexe pela batida:** o `!`, a raia acesa, o projétil e o aríete tomam o tempo de `Ritmo.t_musica()`;
  o piscar e o escudo que abaixa podem usar `dt` (são enfeite).
- **O treino** julga igual e não soma (`marcar`); a vida também não cai no treino.
- **`preso = true`:** sem ele, o boneco anda com o analógico. A `SalaJogo.sair` já devolve `preso = false`.
- **O tremor:** o `CenarioDoImpacto.exagero` põe `sala.tremor`, que o main já lê; com `Opcoes.tremor` desligado,
  o main não treme e o hit-stop não congela.
- **O `CenarioDoImpacto.gancho`** procura a classe `Cavaleiro` na lista de classes globais; sem a G13, devolve o
  neutro e o Cerco joga como o stat 3.

### Ao terminar

- No [quadro](README.md): a linha **L1**, com o commit (`feito (<commit>)`).
- Commit sugerido (sem trailer):
  `feat: O Cerco, O Impacto no kit, no tempo da faixa, com o aríete e o cenário comum da seção`
