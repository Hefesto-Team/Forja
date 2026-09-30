# G02 — A construção do cavaleiro

**Sprint:** G · **Tamanho:** G · **Modelo:** Opus · **Estimativa:** US$ 4,0 · **Depende de:** F00, F04, F05, F06, F07, F08, G01 · **H01:** opcional (sem ele, o relógio local e o gancho descrito abaixo)

## Por quê

Não há criação de personagem. A construção dá identidade a cada um, é o
lobby, e mede o atraso de cada controle sem ninguém ver (a calibração).

## Ler antes

- [A construção do cavaleiro](../06b-a-construcao-do-cavaleiro.md) (a tela, os seis passos)
- [A calibração que ninguém vê](../04-ritmo-e-audio.md#a-calibração-que-ninguém-vê)
- [O relógio de áudio e o julgamento](../13-arquitetura.md#o-relógio-de-áudio-e-o-julgamento--h01-h02-h03) (o `Ritmo.desvio`) e [o registro v2](../13-arquitetura.md#o-registro-v2--f06-h01-h02-g02-h07) (o tipo `calibracao`)
- [Os tokens de cor](../../estudos/03-o-sistema-visual-do-app-hefesto.md#1-tokens-de-cor)

## O estado de hoje

- `godot/scripts/ui/tela_lobby.gd` (113 linhas) desenha "Quem joga", a linha
  de estado e um seletor no pé de cada pedestal (◀▶ boneco, ▲▼ o que leva,
  `_seletor`, 164-185). Guarda `prontos`, `contagem`, `pes`, `visual` e os
  quatro `CartaoJogador`.
- `godot/scripts/ui/cartao_jogador.gd` (96 linhas) mostra o que 06 manda
  tirar: nome do aparelho, VID:PID, origem, "Luz", "LEDs", bateria.
- `godot/scripts/main.gd:586-642`, `_quadro_lobby(dt)`: ✕ de pad sem lugar
  entra; ◀▶/▲▼ chamam `p.visual(p.modelo_i + dx, p.item_i + dy)`; ✕ fica
  pronto e grava `Forja.evento("visual", …)`; ○ volta ou sai; △ abre as
  opções do lugar; com todos prontos, `lobby.contagem = 1.6` e o salão.
  (A F04 mudou a entrada: o lugar vem na conexão e ✕ confirma.)
- `godot/scripts/main.gd:540-543`: a cada quadro o main põe `lobby.pes[l]`
  (o pé do pedestal na tela) e `lobby.visual[l]`.
- `godot/scripts/player.gd:14-27`: `MODELOS` (2), `NOME_DO_MODELO`, `ITENS`
  (7 visuais: mãos livres, espada, lança…, poção, chave — sem mecânica) e
  `VISUAL_DO_LUGAR := [[0, 3], [1, 2], [0, 5], [1, 4]]`. `visual(m, item)`
  (107-124) só chama `_vestir` quando troca de modelo; `_segurar()` (132-152)
  apaga **todo** `BoneAttachment3D` do esqueleto e prende as peças da mão;
  `_vestir()` (156-166) pinta as malhas `body*` com
  `cor.lerp(Color.WHITE, 0.25)`. A G01 deixou `tingir(k)`, `cabeca(v)`,
  `PIO_DO_MODELO` e `_roupas`.
- `godot/scripts/opcoes.gd`: guarda gatilho, vibração, volumes, texto e
  idioma por lugar em `user://opcoes.cfg`; com o robô não lê nem grava
  (`carregar(robo)`, `gravar(robo)`); não há cavaleiro nem desvio.
- `godot/scripts/mundo/salao.gd:361-392`, `_pedestais()`: quatro discos em
  `Vector3(-4.2 + i * 2.8, 0, 4.4)` com o aro na cor do lugar; não há
  bigorna por lugar. `Kit.bigorna(pai, pos, escala)` existe
  (`godot/scripts/mundo/kit.gd:138-167`).
- A câmera do lobby: `main.gd:916-917`,
  `[Vector3(0, 2.9, 14.2), Vector3(0, 0.55, 4.4)]`.
- Não existe relógio de música (`Ritmo`, H01). O main tem `_passo(l, vertical)`
  (`main.gd:802-811`), a borda do analógico/d-pad.
- A G01 deixou em `main.gd` o `_robo(dt)` com o ramo `"lobby"` (✕ a cada
  0,6 s em quem não está pronto).

## O alvo

**O estado continua se chamando `"lobby"`** (a pausa, o `--tela=lobby` e as
provas usam o nome); o que muda é a tela e as regras. As classes
`TelaLobby` e `CartaoJogador` continuam (sem script novo, sem `.uid` novo).

### Os passos de cada lugar ([06b](../06b-a-construcao-do-cavaleiro.md#a-tela))

Constantes em `TelaLobby`:

```gdscript
const BONECO := 0
const ACABAMENTO := 1
const PECA := 2
const ITEM := 3
const NOME := 4
const FORJAR := 5
const PRONTO := 6
const ROTULO := ["Boneco", "Acabamento", "Peça", "Item", "Nome", "Forjar"]
const BPM := 120.0        ## o MUS_TELA_CONSTRUCAO (04): o metrônomo da bigorna
const MARTELADAS := 8
const ROBO_ATRASO_S := 0.033   ## o robô do lugar l martela l × 33 ms depois da batida
const NOMES := ["Brasa", "Faísca", "Cobalto", "Estanho", "Cinzel", "Tenaz", "Rebite", "Ferrugem",
	"Âmbar", "Quartzo", "Basalto", "Granito", "Obsidiana", "Carvão", "Magnésio", "Titânio",
	"Níquel", "Bronze", "Latão", "Cromo", "Grafite", "Ônix", "Pirita", "Safira"]
```

| passo | ◀▶ | ✕ | ○ | △ |
| --- | --- | --- | --- | --- |
| BONECO | `modelo_i ± 1`, e o pio do boneco novo (`Som.pio`) | próximo passo | sair do lugar (`Forja.sair(l)`, como hoje) | as opções do lugar |
| ACABAMENTO | entre `ForjaPlayer.acabamentos_disponiveis()` | próximo | passo anterior | as opções |
| PECA | `peca_i ± 1` | próximo | anterior | as opções |
| ITEM | `item_i` entre 1 e 6 (nunca 0), e `_sentir_o_item(l)` | próximo | anterior | as opções |
| NOME | o nome seguinte/anterior de `NOMES` que ninguém usa | FORJAR | anterior | sortear um nome livre |
| FORJAR | — | uma martelada (abaixo) | anterior (zera as marteladas) | — |
| PRONTO, não confirmado (cavaleiro guardado) | — | confirma (`prontos[l] = true`) | refazer (volta a BONECO) | — |
| PRONTO, confirmado | — | — | desconfirma (`prontos[l] = false`) | — |

Toda troca: `jogadores[l].gesto("interact-right", 0.5)`, `Forja.sentir(l, "toque")`
(F05) e `Som.no_controle(l, "tique", 0.6)`. Todo ✕ que avança:
`Forja.sentir(l, "acerto")`. O nome inicial de cada lugar:
`NOMES[(Forja.semente * 7 + l * 5) % NOMES.size()]` (quatro diferentes).
O sorteio usa um `RandomNumberGenerator` com `seed = Forja.semente * 31 + l`.

### As oito marteladas (a calibração)

- `t_bigorna` soma o `dt` desde que a tela abriu; a batida `n` cai em
  `n * 60.0 / BPM`. A cada batida nova, se algum lugar está em FORJAR:
  `Som.tocar("martelo", null, -6.0)` e `salao.acender_bigorna(l, 1.0)` nos
  lugares em FORJAR.
- Ao entrar em FORJAR: `golpes[l].clear()`, `jogadores[l].tingir(0.0)`.
- Cada ✕ em FORJAR:
  ```gdscript
  var t := _agora()
  var d := t - roundf(t / periodo()) * periodo()   # o desvio até a batida mais perto, em s
  golpes[l].append(d)
  jogadores[l].gesto("attack-melee-right", 0.35)
  jogadores[l].tingir(golpes[l].size() / float(MARTELADAS))
  Som.no_controle(l, "martelo", 0.8)
  Forja.sentir(l, "acerto")
  salao.acender_bigorna(l, 2.5)
  if golpes[l].size() >= MARTELADAS:
  	_forjou(l)
  ```
- `_forjou(l)`: `desvio[l] = mediana(golpes[l])`; `passo[l] = PRONTO`;
  `prontos[l] = true`; `jogadores[l].gesto("emote-yes", 1.2)`;
  `Efeitos.faiscas(salao, jogadores[l].global_position + Vector3(0, 1.6, 0), Forja.cor_do_lugar(l), 30, 1.0)`;
  e grava:
  ```gdscript
  var ms := int(round(desvio[l] * 1000.0))
  Opcoes.desvio_ms[l] = ms
  Opcoes.cavaleiro[l] = jogadores[l].cavaleiro()
  Opcoes.noite_dos_cavaleiros = Opcoes.noite()
  Opcoes.guardar()
  var ritmo := get_node_or_null("/root/Ritmo")   # H01 feito: o julgamento passa a descontar
  if ritmo:
  	ritmo.desvio[l] = desvio[l]
  Forja.evento("calibracao", l + 1, {"desvio_ms": ms, "amostras": golpes[l].size()})
  Forja.evento("cavaleiro", l + 1, jogadores[l].cavaleiro())
  Forja.registrar("P%d forjou o cavaleiro: desvio %d ms" % [l + 1, ms])
  ```
- **O gancho do relógio:** uma função só,
  ```gdscript
  ## O agora do metrônomo, em s. Sem o Ritmo (H01), o relógio local; a H03
  ## troca por Ritmo.t_musica() e a batida pela da faixa.
  func _agora() -> float:
  	return t_bigorna
  ```
- `static func mediana(v: Array) -> float` (ordenar; ímpar: o do meio; par:
  a média dos dois do meio; vazio: 0.0).
- Nenhum número na tela: a calibração é "a armadura ficando pronta".

### O que se guarda ([06b](../06b-a-construcao-do-cavaleiro.md#a-tela): "quem volta na mesma noite pula a construção")

Em `godot/scripts/opcoes.gd`:

```gdscript
static var cavaleiro := [{}, {}, {}, {}]   ## {boneco, acabamento, peca, item, nome} de cada lugar
static var desvio_ms := [0, 0, 0, 0]      ## a calibração de cada lugar (H03 ajusta à mão, em passos de 10 ms)
static var noite_dos_cavaleiros := ""      ## Opcoes.noite() de quando foram forjados
static var _robo := false                  ## posto por carregar(robo)
## A noite: a data de seis horas atrás (a noite que passa da meia-noite continua a mesma).
static func noite() -> String:
	return Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) - 6 * 3600)
## Grava sem precisar saber do robô (quem chama não usa Forja.robo; a paridade da F08).
static func guardar() -> void:
	gravar(_robo)
```

No `user://opcoes.cfg`: seção `P%d`, chaves `"cavaleiro"` (o dicionário) e
`"desvio_ms"`; seção `sessao`, `"noite_dos_cavaleiros"`. `de_fabrica()` zera
os três. Com o robô nada vai ao disco, mas os valores ficam na memória da
sessão (voltar ao lobby pela pausa acha o cavaleiro guardado).

Quem **confirma o lugar** (o ✕ da F04) com um cavaleiro guardado desta noite
(`noite_dos_cavaleiros == Opcoes.noite()` e `cavaleiro[l]` não vazio) veste o
guardado e cai em PRONTO **não confirmado**: mais um ✕ e está pronto; ○
refaz. Sem guardado: começa em BONECO.

### O boneco (`godot/scripts/player.gd`)

```gdscript
## O acabamento: a cor é sempre a do lugar (a da barra de luz); muda como a luz bate.
## "livre": false até a coleção (G06) desbloquear. metallic nunca passa de 0,2 (11).
const ACABAMENTOS := [
	{"nome": "Fosco", "rugoso": 0.95, "metal": 0.0, "claro": 0.25},
	{"nome": "Polido", "rugoso": 0.35, "metal": 0.2, "claro": 0.25},
	{"nome": "Riscado", "rugoso": 0.75, "metal": 0.1, "claro": 0.0, "escuro": 0.18},
	{"nome": "Dourado", "rugoso": 0.5, "metal": 0.2, "claro": 0.1, "ouro": 0.35, "livre": false},
]
## A peça de identidade (11, "montar peças"): caixas presas a um osso.
const PECAS := ["Nenhuma", "Elmo", "Capa", "Ombreira"]
## O item: o índice é o de Itens (G03): 0 nenhum, 1..6 os seis. O ícone é um
## glifo de ui/glifo.gd; a peça nas costas vem na G03.
const ITENS := [
	{"nome": "Mãos livres", "icone": ""},
	{"nome": "Martelo", "icone": "item_martelo"},
	{"nome": "Escudo", "icone": "item_escudo"},
	{"nome": "Fole", "icone": "item_fole"},
	{"nome": "Lanterna", "icone": "item_lanterna"},
	{"nome": "Diapasão", "icone": "item_diapasao"},
	{"nome": "Âncora", "icone": "item_ancora"},
]
const VISUAL_DO_LUGAR := [[0, 1], [1, 2], [0, 3], [1, 4]]

var acabamento_i := 0
var peca_i := 0
var nome := ""

static func acabamentos_disponiveis() -> Array   # os índices com "livre" ausente ou true (a G06 soma a coleção)
func cavaleiro() -> Dictionary                   # {"boneco", "acabamento", "peca", "item", "nome"}
func vestir(c: Dictionary) -> void               # aplica tudo e chama visual()
```

A cor da roupa em `_aplicar_acabamento()` (chamada sempre no fim de
`visual()`, troque o modelo ou não):
`base = cor.lerp(Color.WHITE, a.claro)`; com `"escuro"`,
`base = base.lerp(Tema.CASA, a.escuro)`; com `"ouro"`,
`base = base.lerp(Color("#d9a74a"), a.ouro)`; `roughness = a.rugoso`,
`metallic = a.metal`. `tingir(k)` passa a partir desta `base` (guarde-a em
`var _cor_da_roupa`).

As peças, em `_prender_peca()` (chamada depois de `_segurar()`), cada uma num
`BoneAttachment3D` chamado `"Peca"` (`_segurar()` passa a apagar só os
`BoneAttachment3D` cujo nome **não** começa com `"Peca"`; `_prender_peca()`
apaga os `"Peca"` antes de prender). Medidas no espaço do osso, em unidades
do modelo (a cabeça ocupa x ±0,23, y 0 a 0,41, z −0,16 a 0,20 a partir do
osso `head`); material `Kit.material(Color("#8a8fa8"), 0.0, 0.6)` para metal
e `Kit.material(cor.darkened(0.35), 0.0, 0.9)` para pano:

| peça | osso | caixas (`Kit.caixa(presa, tamanho, posição, material)`) |
| --- | --- | --- |
| Elmo | `head` | `(0.50, 0.14, 0.44)` em `(0, 0.40, 0.02)`; crista `(0.06, 0.10, 0.36)` em `(0, 0.50, 0)`; viseira `(0.48, 0.05, 0.08)` em `(0, 0.33, 0.21)` |
| Capa | `torso` | pano `(0.34, 0.30, 0.02)` em `(0, 0.04, -0.15)`; gola `(0.36, 0.04, 0.08)` em `(0, 0.18, -0.12)` |
| Ombreira | `arm-left` e `arm-right` | `(0.14, 0.06, 0.16)` em `(0.02, 0.03, 0)` no esquerdo e `(-0.02, 0.03, 0)` no direito |

Confira as medidas na foto (`construcao.png`) e ajuste em passos de 0,02 se
algo atravessa a malha.

### A bigorna de cada lugar (`godot/scripts/mundo/salao.gd`)

Em `_pedestais()`, para cada `i`: `Kit.bigorna(pedestais_no, pos + Vector3(0.55, 0.32, 0.55), 0.3)`
com `rotation.y = -0.5`, e uma `OmniLight3D` em
`pos + Vector3(0.55, 1.1, 0.85)`, cor `Forja.cor_do_lugar(i)`, `omni_range 2.5`,
energia 0. Novo:

```gdscript
var luzes_das_bigornas: Array[OmniLight3D] = []
func acender_bigorna(l: int, energia: float) -> void   # a energia cai a 0,8 em 0,3 s (tween) se o lugar está ocupado, a 0 se não
```

Quem confirma o lugar acende a sua (`acender_bigorna(l, 1.5)`) e ouve o pio
(`Som.pio(l, jogadores[l].modelo_i)`).

### A tela (`TelaLobby._draw()` e `CartaoJogador._draw()`, tela lógica 1920×1080)

| o quê | medida | tokens |
| --- | --- | --- |
| tarja de cima | `Rect2(0, 0, w, 150)` + degradê de 24 faixas de 5 px | `Color(Tema.CASA, 0.86)` (como hoje) |
| cabeçalho | `Desenho.cabecalho(self, Vector2(Tema.MARGEM_X, Tema.MARGEM_Y), 72.0)` | — |
| título "Os cavaleiros" | centrado, base y 118, `Tema.fonte(700)`, `Tema.T_TITULO` | `Tema.FG` |
| linha de estado | centrada, base y 172, `Tema.T_CORPO` | "Aperte ✕ no seu controle" (`Tema.SUAVE`) sem ninguém; "Falta 1 cavaleiro" / "Faltam N cavaleiros" (`Tema.SUAVE`); "Todos prontos" (`Tema.VERDE`, peso 500) na contagem |
| os quatro cartões | largura `minf(400 * Tema.escala_texto, (w - 2 * Tema.MARGEM_X - 3 * 24) / 4)`, altura `320 * Tema.escala_texto`, vão 24, centrados, base em `h - Tema.MARGEM_Y` | ver abaixo |
| tarja de baixo | do topo dos cartões − 180 até o fim, degradê para `Color(Tema.CASA, 0.82)` | como hoje |

**O cartão** (`CartaoJogador`, x interno 28 = margem):

| linha | medida (y a partir do topo, × `Tema.escala_texto`) | conteúdo e tokens |
| --- | --- | --- |
| moldura | raio `Tema.RAIO_CARTAO`, borda 4 | fundo `Color(Tema.APP, 0.94)`; confirmado pronto: `Tema.SEL`; borda `Tema.tom_para_a_borda(Forja.cor_do_lugar(l))` |
| cabeça | base 52 | "P1" `Tema.fonte(700)` `Tema.T_CORPO` na cor da borda; o nome do cavaleiro em x 72, `Tema.fonte(500)`, `Tema.T_CORPO`, `Tema.FG`, cortado com `Desenho.caber(…, 1 linha)` na largura que sobra |
| os seis passos | centro y 78, círculos de raio 7 a cada 26 px a partir de x 35 | feito: cheio na cor da borda; atual: anel de 2 px na cor da borda; por fazer: `Tema.TRILHO` |
| rótulo do passo | base 124 | `ROTULO[passo]`, `Tema.fonte(600)`, `Tema.T_ROTULO`, `Tema.VERDE` (rótulo de campo) |
| a escolha | base 186 | glifo `"esquerda"` 36×36 em x 28, `"direita"` em `largura − 64`; o valor centrado, `Tema.fonte(500)`, começa em `Tema.T_SUBTITULO` e encolhe até 30 para caber; no passo ITEM, o ícone (`Glifo.desenhar(self, ITENS[i].icone, Rect2(…, 48×48), Tema.FG)`) à esquerda do nome |
| FORJAR | y 150 a 190 | oito bigornas pequenas (retângulo 24×10 sobre um 12×10), vão 10: feitas na cor da borda, por fazer `Tema.TRILHO` |
| PRONTO | base 186 | selo `"✓ Pronto"` (`Desenho.selo`, `Tema.VERDE`) quando confirmado; senão a dica de ✕ "Pronto" |
| dicas | bases 232, 270, 308, uma por linha, `Tema.T_ROTULO` | ✕ (Seguir / Forjar / Pronto) em `Tema.FG`; ○ (Voltar / Sair / Refazer) em `Tema.SUAVE`; △ (Opções / Sortear) em `Tema.SUAVE`, só nos passos em que vale |
| lugar sem jogador | — | borda `Tema.SUTIL` 2 px, fundo `Color(Tema.APP, 0.6)`, "P3" em `Tema.MUDO`, a dica de ✕ "Entrar" em `Tema.MUDO`; sem controle no lugar: só "P3 · —" |

Nada de VID:PID, bateria, "Luz", "LEDs" ou nome do aparelho (06).

### O ícone do item (`godot/scripts/ui/glifo.gd`, em `desenhar()`, grade de 32, traço `t`)

| nome | desenho |
| --- | --- |
| `item_martelo` | `_contorno(ci, [p(14,6), p(26,14), p(22,20), p(10,12)], cor, t)`; cabo `draw_line(p(16,16), p(8,28))` |
| `item_escudo` | `_contorno(ci, [p(8,7), p(24,7), p(24,16), p(16,26), p(8,16)], cor, t)` |
| `item_fole` | `_contorno(ci, [p(6,10), p(20,6), p(20,26), p(6,22)], cor, t)`; bico `draw_line(p(20,16), p(28,16))` |
| `item_lanterna` | `_retangulo_arred(ci, Rect2(p(10,10), Vector2(12,16)*k), 3*k, cor, t)`; alça `draw_arc(p(16,10), 4*k, PI, TAU, 16, cor, t, true)`; chama `draw_line(p(16,15), p(16,21))` |
| `item_diapasao` | `draw_line(p(12,6), p(12,18))`, `draw_line(p(20,6), p(20,18))`, `draw_arc(p(16,18), 4*k, 0, PI, 16, cor, t, true)`, `draw_line(p(16,22), p(16,28))` |
| `item_ancora` | `draw_line(p(16,8), p(16,26))`; argola `draw_arc(p(16,6), 2.5*k, 0, TAU, 16, cor, t, true)`; travessa `draw_line(p(11,11), p(21,11))`; curva `draw_arc(p(16,18), 8*k, 0, PI, 24, cor, t, true)` |

(`p(x, y)` é o `p.call(x, y)` que a função já usa; a G04 usa os mesmos ícones
no HUD.)

### O robô da construção

`TelaLobby.robo(l, dt)` (o nome que a checagem da F08 aceita), chamado pelo
`_robo(dt)` do main no estado `"lobby"` para os quatro lugares, a cada quadro:

```gdscript
## O robô (--robo) constrói pelo controle simulado, como uma pessoa: ✕ em
## cada passo e as oito marteladas no tempo, o lugar l atrasado l × 33 ms
## (a prova confere o desvio medido).
func robo(l: int, dt: float) -> void:
	if not Forja.lugar(l).get("conectado", false):
		return
	_robo_espera[l] -= dt
	if Forja.ocupado(l) and passo[l] == FORJAR:
		if _agora() >= _robo_batida[l] * periodo() + ROBO_ATRASO_S * l:
			Forja.robo_apertar(l, Forja.CRUZ)
			_robo_batida[l] += 1
		return
	if _robo_espera[l] > 0.0 or prontos[l]:
		return
	Forja.robo_apertar(l, Forja.CRUZ)
	_robo_espera[l] = 0.9 + 0.1 * l
```

Ao entrar em FORJAR: `_robo_batida[l] = floori(_agora() / periodo()) + 1`.

## Passos

Rodar `bash tests/prova_do_jogo.sh` depois dos passos 3, 6 e 8.

1. **Antes do código:** acrescentar ao
   [13](../13-arquitetura.md#o-relógio-de-áudio-e-o-julgamento--h01-h02-h03),
   na seção do relógio, a linha: "`Opcoes.desvio_ms[l]` guarda a calibração
   (G02 mede, H03 ajusta à mão); o `Ritmo` lê de lá ao abrir, e
   `Ritmo.desvio[l] = Opcoes.desvio_ms[l] / 1000.0`", e na tabela do
   registro v2 a linha `cavaleiro` (`boneco`, `acabamento`, `peca`, `item`,
   `nome` — G02).
2. **`godot/scripts/opcoes.gd`:** `cavaleiro`, `desvio_ms`,
   `noite_dos_cavaleiros`, `_robo`, `noite()`, `guardar()`; ler e gravar no
   cfg; `carregar(robo)` guarda `_robo = robo` **antes** do `return` do robô.
3. **`godot/scripts/player.gd`:** `ACABAMENTOS`, `PECAS`, os `ITENS` novos,
   `VISUAL_DO_LUGAR` novo, `acabamento_i`, `peca_i`, `nome`,
   `acabamentos_disponiveis()`, `cavaleiro()`, `vestir()`,
   `_aplicar_acabamento()`, `_prender_peca()`; `_segurar()` só apaga o que
   não é `"Peca"`. `descricao_do_visual()` passa a
   `"%s · %s" % [NOME_DO_MODELO[modelo_i], ITENS[item_i].nome]` (igual).
4. **`godot/scripts/ui/glifo.gd`:** os seis ícones.
5. **`godot/scripts/mundo/salao.gd`:** as bigornas, as luzes e
   `acender_bigorna()`.
6. **`godot/scripts/ui/tela_lobby.gd` e `cartao_jogador.gd`:** reescrever.
   `TelaLobby` guarda `prontos`, `contagem`, `pes` (continuam),
   `passo`, `golpes`, `desvio`, `t_bigorna`, `jogadores`, `salao`,
   `pediu_opcoes := -1`, `_robo_espera`, `_robo_batida`; funções
   `abrir()` (zera tudo; lugares já ocupados seguem a regra do guardado),
   `entrou(l)` (o lugar acabou de confirmar), `quadro(dt, dx: Array)` (a
   tabela de botões; `dx[l]` vem do `_passo(l, false)` do main), `periodo()`,
   `_agora()`, `mediana()`, `_forjou(l)`, `_sentir_o_item(l)` (hoje só
   `Forja.sentir(l, "toque")`; a G03 troca) e `robo(l, dt)`. Sai `visual`.
   `CartaoJogador` lê `jogadores[l]` e `passo[l]` pela `TelaLobby` pai
   (`get_parent()`).
7. **`godot/scripts/main.gd`:**
   - `_interface()`: `lobby.jogadores = jogadores` e `lobby.salao = salao`;
   - `_process`: tirar a linha de `lobby.visual[l]` (543);
   - `_mostrar("lobby")`: `Musica.tocar("construcao")` e `lobby.abrir()`;
     `musica.gd` ganha `"construcao": [60, 120, 1]`;
   - `_quadro_lobby(dt)`: manter o bloco da F04 que confirma o lugar; logo
     depois de um lugar confirmar, `lobby.entrou(l)`. Tirar o bloco de
     ◀▶/▲▼/✕/○ (606-625) e pôr
     `var dx := [0, 0, 0, 0]`, `dx[l] = _passo(l, false)` para os quatro,
     `lobby.quadro(dt, dx)`; se `lobby.pediu_opcoes >= 0`, abrir
     `"opcoes"` para esse lugar, zerar `pediu_opcoes` e `return`. A contagem
     de 1,6 s continua igual. Se a F04 pôs o "◻ segurado passa o lugar"
     aqui, ele fica;
   - `_robo(dt)`, ramo `"lobby"`: `for l in 4: lobby.robo(l, dt)` a cada
     quadro, sem a espera de 0,6 s da G01;
   - ao sair do lobby para o salão, `Forja.gatilhos_off(l)` nos quatro (o
     item pode ter deixado peso no gatilho).
8. **`godot/scripts/traducoes.gd`:** as entradas novas (tabela abaixo) e os
   padrões `["^Faltam (\\d+) cavaleiros$", "$1 knights to go"]`.
9. **As provas e as fotos** (ver Provas).

| português | inglês |
| --- | --- |
| Os cavaleiros | The knights |
| Aperte ✕ no seu controle | Press ✕ on your controller |
| Falta 1 cavaleiro | 1 knight to go |
| Boneco / Acabamento / Peça / Item / Nome / Forjar | Figure / Finish / Piece / Item / Name / Forge |
| Fosco / Polido / Riscado / Dourado | Matte / Polished / Scratched / Golden |
| Nenhuma / Elmo / Capa / Ombreira | None / Helmet / Cape / Pauldron |
| Mãos livres / Martelo / Escudo / Fole / Lanterna / Diapasão / Âncora | Empty hands / Hammer / Shield / Bellows / Lantern / Tuning fork / Anchor |
| Humano / Orc | Human / Orc |
| Seguir / Voltar / Sair / Refazer / Sortear / Opções / Pronto / Entrar | Next / Back / Leave / Redo / Shuffle / Options / Ready / Join |
| ✓ Pronto | ✓ Ready |

Os nomes de `NOMES` são nomes próprios: não entram na tabela. `NOME_DO_MODELO`
passa a `["Humano", "Orc"]`.

## Armadilhas

- **Sem script novo** (as classes continuam), então sem `.uid` novo; se
  criar um, importe e commite o `.uid`.
- **Tudo em `_draw()`**, com `Desenho` e `Glifo`: nenhum `Label`.
- **Texto com maiúscula e por `Traducoes`**; nada abaixo de 30 px (o valor
  da escolha encolhe até 30 e para; o nome se corta com reticências).
- **A escala 1,15:** a largura do cartão é limitada pela tela; confira a
  foto com `FORJA_TEXTO=grande` se a G04 já pôs a variável, ou pondo
  `Opcoes.texto = 1` à mão numa rodada local.
- **O robô só aperta:** nenhum `Forja.robo` fora de `robo()`/`_robo()`;
  `Opcoes.guardar()` existe para a tela não precisar saber do robô.
- **O ✕ que confirma o lugar não é o ✕ do passo:** no quadro em que o
  lugar confirma, `quadro()` não trata o ✕ dele (hoje é o `chegou[l]` do
  main; mantenha a guarda).
- **Lugar vazio e quem sai:** `Forja.sair(l)` no BONECO; o cartão volta a
  vazio; `_sincronizar_jogadores()` esconde o boneco; a contagem só conta os
  ocupados.
- **O desvio da prova depende de quadros:** a 60 quadros fixos, o desvio sai
  em degraus de ~17 ms; as tolerâncias da prova já contam com isso.
- **O `_segurar()` de hoje apaga as peças:** se o elmo some quando se troca
  o item, o filtro por `"Peca"` não pegou.
- **Os roteiros da captura sem robô** precisam montar os cavaleiros: o passo
  novo `["ate_pronto", sim]` (ver Provas).

## Não fazer

- O teclado de tela para o nome (fica para uma ficha nova, se o André pedir):
  aqui é a lista e o sorteio.
- A mecânica e a peça 3D do item (G03), os bonecos novos e as peças novas
  (G08), o desbloqueio do Dourado (G06).
- Mostrar o desvio, "calibração" ou qualquer número de latência na tela.
- Usar a barra de luz ou as luzinhas para marcar o passo.

## Pronto quando

Quatro pessoas constroem os quatro cavaleiros em menos de dois minutos; a
linha do tempo tem uma linha `calibracao` por lugar; quem volta ao lobby
pela pausa acha o seu cavaleiro pronto para confirmar; e o robô constrói os
quatro sozinho, só apertando botões.

## Provas

**Na sessão:** `bash tests/prova_do_jogo.sh`.

Em `godot/testes/prova_do_jogo.gd`, `_prova_do_percurso()`: depois de
`_esperar(jogo.estado == "lobby", …)` e das checagens por lugar da F04,
**trocar** o bloco dos visuais (os `visuais`, ◀▶ do P2, ▲▼ do P3 e os ✕ de
pronto) por:

```gdscript
	# a construção: o robô de cada lugar aperta ✕ passo a passo e martela no tempo
	var q := 0
	while not (Forja.ocupado(1) and jogo.lobby.passo[1] == TelaLobby.BONECO) and q < 600:
		await _quadros(1)
		q += 1
	var m1: int = jogo.jogadores[0].modelo_i
	var m2: int = jogo.jogadores[1].modelo_i
	await _aperta(1, Forja.DIREITA)
	_esperar(jogo.jogadores[1].modelo_i != m2, "◀▶ troca o boneco do P2")
	_esperar(jogo.jogadores[0].modelo_i == m1, "e o do P1 fica como estava")
	q = 0
	while jogo.lobby.passo[2] != TelaLobby.ITEM and q < 900:
		await _quadros(1)
		q += 1
	var i3: int = jogo.jogadores[2].item_i
	await _aperta(2, Forja.DIREITA)
	_esperar(jogo.jogadores[2].item_i != i3 and jogo.jogadores[2].item_i >= 1, "◀▶ troca o item do P3, entre os seis")
	q = 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 3600:
		await _quadros(2)
		q += 2
	_esperar(jogo.estado == "salao", "com os quatro forjados, o salão (%d quadros)" % q)
	var nomes := {}
	for l in 4:
		_esperar(jogo.lobby.golpes[l].size() == TelaLobby.MARTELADAS, "P%d: as oito marteladas" % (l + 1))
		_esperar(Opcoes.desvio_ms[l] == int(round(jogo.lobby.desvio[l] * 1000.0)), "P%d: o desvio foi para as opções (%d ms)" % [l + 1, Opcoes.desvio_ms[l]])
		nomes[jogo.jogadores[l].nome] = true
	_esperar(nomes.size() == 4 and not nomes.has(""), "quatro nomes diferentes (%s)" % [nomes.keys()])
	var d0: float = jogo.lobby.desvio[0]
	var dif: float = jogo.lobby.desvio[3] - d0
	_esperar(d0 >= -0.01 and d0 <= 0.07, "P1 martelou no tempo: desvio %d ms" % int(d0 * 1000.0))
	_esperar(dif >= 0.07 and dif <= 0.13, "P4 martelou uns 100 ms depois do P1: %d ms" % int(dif * 1000.0))
	_esperar(absf(TelaLobby.mediana([0.3, -0.1, 0.0, 0.5, 0.1]) - 0.1) < 0.0001
		and absf(TelaLobby.mediana([0.0, 0.2, 0.4, 1.0]) - 0.3) < 0.0001, "a mediana, ímpar e par")
```

Em `_prova_do_relatorio()`, depois de `_esperar(json != "", …)`:

```gdscript
	var calibracoes := 0
	for f in arquivos:
		if f.begins_with("linha-do-tempo-") and f.ends_with(".jsonl"):
			for linha in FileAccess.get_file_as_string(pasta.path_join(f)).split("\n", false):
				var d = JSON.parse_string(linha)
				if d is Dictionary and str(d.get("tipo", "")) == "calibracao" and int(d.get("amostras", 0)) == 8:
					calibracoes += 1
	_esperar(calibracoes == 4, "a linha do tempo tem a calibração dos quatro (%d)" % calibracoes)
```

Em `godot/testes/captura_jogo.gd`: um passo novo no `match` de `_rodar()`,

```gdscript
			"ate_pronto":
				# sem robô: aperta ✕ no simulado até o lugar ficar pronto (as marteladas contam fora do tempo também)
				var n := 0
				while not jogo.lobby.prontos[p[1]] and n < 40:
					Forja.ctl.simulador_botao(p[1], Forja.CRUZ, true)
					for i in 3:
						await get_tree().process_frame
					Forja.ctl.simulador_botao(p[1], Forja.CRUZ, false)
					for i in 17:
						await get_tree().process_frame
					n += 1
```

e em `_roteiro_das_telas`, depois de pular a introdução: ✕ nos simulados
0, 1 e 2; `["espera", 40]`; `["aperta", 1, Forja.DIREITA]`;
`["aperta", 0, Forja.CRUZ]`; três ✕ no 2; `["espera", 30], ["foto", "construcao"]`;
`["aperta", 0, Forja.CRUZ]` × 4 (P1 chega ao FORJAR),
`["espera", 30], ["foto", "construcao_forjar"]`; depois
`["ate_pronto", 0], ["ate_pronto", 1], ["ate_pronto", 2]` e `["espera", 150], ["foto", "salao"]`.
O `_roteiro_dos_extras` continua (△ no BONECO abre as opções).

## Para o André (local)

1. `bash tests/telas.sh fotos /tmp/fotos-g02`: olhar `construcao.png` e
   `construcao_forjar.png` (cartões sem texto encostando; a armadura cinza
   ficando colorida; o elmo, a capa e a ombreira no lugar).
2. Quatro DualSense (dois no cabo, dois no rádio): construir os quatro em
   menos de dois minutos; cada pio sai do seu controle.
3. Depois, no `relatorios/linha-do-tempo-*.jsonl`, as quatro linhas
   `calibracao`: colar aqui o `desvio_ms` de cada um com o transporte (a
   linha `conexao` do mesmo lugar). Esperado: o rádio com desvio maior que o
   cabo.
4. Fechar e abrir o jogo na mesma noite: ✕ confirma e o cavaleiro já vem
   pronto; ○ refaz.

## Ao terminar

No [quadro](README.md), G02 **feito** com o commit e o gasto. Commit
sugerido (sem trailer):

```
feat: a construção do cavaleiro — boneco, acabamento, peça, item, nome e as oito marteladas que calibram
```
