# 15 — Os módulos importáveis

O Forja tem sete peças que outro jogo de Godot poderia usar sem levar o Forja junto: o controle e a háptica do
DualSense, o relógio de ritmo e o julgamento, o kit de minigame, o robô de prova, o placar, o texto de tela e a costura
das telas. Hoje nenhuma delas sai sozinha: todas falam com o autoload `Forja` ou com o `Tema`. Esta página diz, para
cada uma, o que ela oferece, do que depende, o que tem de soltar e como vira pacote. Cada extração é uma ficha da
seção X do [quadro](tarefas/README.md).

A regra que vale para todas: **extrair é mudar de lugar e cortar dependência, não reescrever.** A ficha de extração
não muda comportamento; a prova do jogo de antes passa igual depois.

## O pacote

| o que | como |
| --- | --- |
| lugar | `godot/addons/forja_<nome>/`, com `plugin.cfg`, `plugin.gd`, `LEIA-ME.md`, `LICENSE` e `testes/` |
| `plugin.cfg` | `name="Forja <Nome>"`, `description` numa frase, `author="Forja"`, `version="0.1.0"`, `script="plugin.gd"` |
| `plugin.gd` | `@tool extends EditorPlugin`; registra os autoloads do pacote em `_enable_plugin` (`add_autoload_singleton`) e tira em `_disable_plugin` |
| nomes | todo `class_name` e todo autoload começa com `Forja` (`ForjaDesenho`, `ForjaRitmo`): `Tema`, `Desenho`, `Partida` colidiriam com o projeto de quem importa |
| o nativo | GDExtension dentro do pacote: `forja_dualsense.gdextension` com `res://addons/forja_dualsense/bin/…`; o núcleo em C (`forja_ds5`, `forja_nucleo`) não conhece o Godot e serve a outro motor |
| a versão | `version` do `plugin.cfg` sobe junto com o `CHANGELOG` do pacote; o jogo usa sempre a da árvore |
| a dependência entre pacotes | escrita no `LEIA-ME.md` do pacote e conferida no `plugin.gd` (`_enable_plugin` avisa se o outro pacote não está ligado) |
| a prova do importável | `tests/prova_do_importavel.sh <nome>`: cria um projeto vazio numa pasta temporária, copia só o pacote (e os que ele declara), roda `godot --headless` com a prova de `testes/` do pacote. Passa sem nada do Forja: é o que prova que a dependência foi cortada |
| o arquivo para levar | `scripts/empacotar_addon.sh <nome>` faz `forja_<nome>-<versão>.zip` só com a pasta do pacote |

## Os sete

### 1. O texto de tela — `forja_texto`

O desenho de texto, glifo e moldura, e a tradução por tabela.

**Hoje:** `godot/scripts/ui/desenho.gd` (`Desenho`, 201 linhas), `godot/scripts/ui/glifo.gd` (`Glifo`, 128),
`godot/scripts/traducoes.gd` (`Traducoes`, 387) e `godot/scripts/tema.gd` (`Tema`, 191: os tokens do jogo e as funções
de fonte).

**A interface pública:**

```gdscript
class_name ForjaDesenho  # estático
static func configurar(estilo: ForjaEstilo) -> void
static func texto(ci: CanvasItem, pos: Vector2, s: String, f: Font, tam: int, cor: Color, ...) -> void
static func paragrafo(ci: CanvasItem, pos: Vector2, s: String, f: Font, tam: int, cor: Color, largura: float, ...) -> float
static func selo(ci: CanvasItem, pos: Vector2, s: String, cor: Color, tam := -1) -> float
static func moldura(ci: CanvasItem, r: Rect2, fundo: Color, borda: Color, largura := 2, raio := -1) -> void
static func largura(s: String, f: Font, tam: int) -> float
static func caber(s: String, f: Font, tam: int, largura: float, linhas: int) -> String
static func dicas_a_direita(ci: CanvasItem, fim: Vector2, pares: Array, tam := -1) -> void

class_name ForjaGlifo  # estático
static func desenhar(ci: CanvasItem, nome: String, r: Rect2, cor: Color, peso := 1.0) -> void
static func dica(ci: CanvasItem, pos: Vector2, glifo: String, texto: String, tam: int, cor_glifo: Color, ...) -> void
static func largura_dica(glifo: String, texto: String, tam: int, com_botao := true) -> float

class_name ForjaTraducao  # estático
static var idioma := "pt_BR"
static func juntar(tabela: Dictionary, padroes: Array) -> void   # cada área do jogo junta a dela
static func traduzir(s: String) -> String

class_name ForjaEstilo extends Resource   # o que o jogo injeta
@export var fonte: Font, fonte_mono: Font
@export var tam_rotulo: int, tam_selo: int, tam_minimo: int = 30
@export var raio_quadro: int
@export var cor_texto: Color, cor_suave: Color, cor_linha: Color
```

**Depende de:** nada (só o Godot).

**O acoplamento a soltar:** `Desenho` e `Glifo` leem `Tema.RAIO_QUADRO`, `Tema.T_SELO`, `Tema.T_ROTULO`,
`Tema.fonte()` e as cores direto. Passam a ler o `ForjaEstilo` que o jogo entrega em `ForjaDesenho.configurar` no
`_ready` do `main`. O `Tema` (os tokens da bíblia) **fica no jogo**: é a cara do Forja, não da biblioteca. A tabela de
frases também fica no jogo; o pacote leva só o motor (`traduzir`, os padrões). Depois da [V03](tarefas/V03-o-texto-de-tela-inteiro.md),
cada área já junta a própria tabela, e o `juntar` é o que ela chama.

### 2. O placar — `forja_placar`

As contas da partida e a tela do placar e do pódio.

**Hoje:** `godot/scripts/partida.gd` (`Partida`, 172 linhas, pura) e `godot/scripts/ui/placar.gd` (`Placar`, 222).

**A interface pública:**

```gdscript
class_name ForjaPartida extends RefCounted
static func nova(n: int, sortear: bool, semente: int, percurso: Array) -> ForjaPartida
static func colocacoes(pontos: Array, presentes: Array) -> Array
func sala_atual() -> String
func acabou() -> bool
func registrar(id: String, pontos: Array, presentes: Array) -> Dictionary
func podio(presentes: Array) -> Array

class_name ForjaPlacar extends Control
signal pediu_som(id: String)          # o jogo toca; o placar não conhece o Som
signal fechou
var cores: Array[Color]               # a cor de cada lugar, entregue pelo jogo
var nomes: Callable                   # func(id: String) -> String
func abrir(p: ForjaPartida, podio: bool) -> void
func pronto() -> bool
func pular() -> void
static func frase_do_vencedor(lista: Array) -> String
```

**Depende de:** `forja_texto`.

**O acoplamento a soltar:** `placar.gd` chama `Forja.cor_do_lugar`, `Som.tocar` e `Tema.fonte/mono/tom_para_a_borda`;
`partida.gd` tem `NOMES` e `NA_ORDEM` com as salas do Forja (`:22-28`). As cores e os nomes entram por variável, o som
sai por sinal, e o roteiro das partidas (quais salas, em que ordem) vem do jogo como `percurso`. Depois da
[V04](tarefas/V04-as-secoes-num-lugar-so.md), os nomes vêm do `Catalogo`.

### 3. O relógio de ritmo e o julgamento — `forja_ritmo`

O tempo da música como relógio, a batida, o julgamento do toque e a ajuda para quem erra seguido.

**Hoje:** `godot/scripts/ritmo.gd` (autoload `Ritmo`, 260 linhas); o contrato está no
[13](13-arquitetura.md#o-relógio-de-áudio-e-o-julgamento--h01-h02-h03).

**A interface pública:**

```gdscript
# autoload ForjaRitmo
signal batida_cheia(n: int)
signal compasso(n: int)
signal julgou(lugar: int, n: int, julgamento: int, desvio_ms: float)   # NAN: a nota passou sem toque
signal nota_marcada(lugar: int, n: int, t_alvo: float)
enum { ERRO, BOM, OTIMO, PERFEITO }                                     # os julgamentos, e as janelas JANELA_*
func tocar(tocador: AudioStreamPlayer, bpm: float, primeiro_tempo_s: float, laco_s := 0.0) -> void
func parar() -> void
func pausar(sim: bool) -> void
func t_musica() -> float
func batida() -> float
func t_da_batida(n: float) -> float
func julgar(l: int, t_toque: float, t_alvo: float, folga_bom := 0.0) -> int
func desvio_ms(l: int, t_toque: float, t_alvo: float) -> float
func definir_desvio(l: int, segundos: float, origem: String, amostras := 0) -> void
func zerar_ajuda() -> void
static func posicao_continua(pos: float, anterior: float, voltas: int, laco_s: float) -> Array
static func folga_para(l: int, pontos: Array, presentes: Array) -> float
```

**Depende de:** nada.

**O acoplamento a soltar:** `ritmo.gd` chama `Forja.evento` (o registro, em `registrar_nota` e `registrar_toque`),
`Forja.pad`/`Forja.pad_do_lugar` (o desvio por controle), `Musica.tocar_do_zero` e `Musica.laco_s` (quem toca a faixa)
e `Opcoes.tempo_ms` (`ler_das_opcoes`). O registro vira os sinais `julgou` e `nota_marcada`, que o jogo liga ao
`Forja.evento`; o tocador entra pronto em `tocar`; o desvio por controle e as opções ficam num conector do jogo
(`godot/scripts/ritmo_do_forja.gd`) que lê `Opcoes` e chama `definir_desvio`.

### 4. O controle e a háptica do DualSense — `forja_dualsense`

Quatro DualSense por lugar: a entrada, a vibração, os gatilhos, a luz, o alto-falante e o microfone, o simulador.

**Hoje:** o módulo nativo (`nativo/nucleo`, `nativo/som`, `nativo/godot`, `src/forja_dualsense.c`, `include/`;
CMake em `nativo/CMakeLists.txt`, alvos `forja_ds5`, `forja_nucleo`, `forja_sdl`, `forja`), a classe
`ForjaControles` (123 métodos e 40 constantes em `nativo/godot/forja_controles.cpp:593`), o
`godot/forja.gdextension` e a metade de entrada e saída do autoload `Forja` (`godot/scripts/forja.gd`, 923 linhas).

**A interface pública** (a fachada em GDScript; o nativo por baixo segue como é):

```gdscript
# autoload ForjaControle
signal pads_mudaram
signal aviso(texto: String)
# os lugares
func conectados() -> int
func pads() -> Array
func pad_do_lugar(lugar: int) -> int
func lugar(l: int) -> Dictionary
func entrar(indice: int) -> int
func sair(l: int) -> void
# a entrada
func apertou(l: int, botao: int) -> bool
func segura(l: int, botao: int) -> bool
func soltou(l: int, botao: int) -> bool
func eixo(l: int, e: int) -> float
func mover(l: int) -> Vector2
func giro(l: int) -> Vector3
func acel(l: int) -> Vector3
func dedo(l: int, i: int) -> Vector3
# as saídas
func vibrar(l: int, forte: float, fraco: float, ms: int) -> bool
func gatilho(l: int, lado: int, modo: int, a := 0, b := 0, c := 0) -> bool
func luz(l: int, cor: Color) -> bool
func leds_jogador(l: int, mascara: int) -> bool
func led_mic(l: int, modo: int) -> bool
func silencio(l: int) -> void
func som_falante(l: int, som: String, ganho := 0.9) -> int
func som_haptica(l: int, esq: String, dir: String, ganho := 1.0) -> int
func som_mic(l: int) -> Dictionary
func capacidade(l: int, qual: String) -> bool
# a cor de cada lugar
var cores: Array[Color]          # o jogo entrega a paleta
func cor_do_lugar(l: int) -> Color
```

**Depende de:** nada (o SDL3 entra estático no binário, como hoje).

**O acoplamento a soltar:** `forja.gd` mistura sete coisas (os comentários de seção em `:229`, `:293`, `:353`, `:449`,
`:514`, `:587`, `:658`, `:692`, `:731`, `:823`, `:877`). O pacote leva **os lugares, a entrada, as saídas e o som de
cada controle**. Ficam no jogo: os argumentos (`--robo`, `--bancada`), o relatório e os vereditos, as medidas, A Prova
(a carga), as provas às cegas e a bancada, que são o diagnóstico do Forja e não do controle. O `aplicar_opcoes`
(`:131`) lê `Opcoes`, `Tema` e `Traducoes`: vira o jogo chamando `ForjaControle.cores = …` e
`ForjaControle.escala_vibracao(l, x)`. Os avisos saem em português pelo sinal `aviso` com a chave, e quem mostra traduz.
O `Som` e a `Musica` usam `Forja.ctl.sintetizar_pcm16` (`som.gd:79`, `musica.gd:56`) e `ctl.som_registrar`
(`som.gd:164`): passam a ser `ForjaControle.sintetizar(receita, parametros) -> PackedByteArray` e
`ForjaControle.registrar_som(chave, dados, taxa) -> int`.

**O empacotamento do nativo:** `godot/forja.gdextension` vai para `godot/addons/forja_dualsense/forja_dualsense.gdextension`;
as bibliotecas, de `godot/bin/` para `godot/addons/forja_dualsense/bin/`. O `scripts/compilar.sh`, o
`scripts/exportar.sh` e os artefatos do CI (`forja-modulo-linux-x86_64`, `forja-modulo-windows-x86_64`) mudam o caminho
juntos, na mesma ficha.

### 5. O robô de prova — `forja_robo`

Quem joga no lugar das pessoas: aperta, inclina, gira, sacode, toca no touchpad e fala no microfone, sempre pelo
simulador do controle, e a régua das checagens.

**Hoje:** `Forja.robo_apertar/eixo/girar/sacudir/tocar/falar` (`godot/scripts/forja.gd:881-919`), a bandeira
`Forja.robo`, o `_robo` de cada sala e os ajudantes `_esperar`, `_quadros`, `_aperta` da prova do jogo
(`godot/testes/prova_do_jogo.gd:30-49`; a [V02](tarefas/V02-a-prova-do-jogo-em-partes.md) os põe em `ForjaChecagem`).

**A interface pública:**

```gdscript
class_name ForjaRobo  # estático, sobre o simulador do ForjaControle
static func apertar(l: int, botao: int, segundos := 0.09) -> void
static func eixo(l: int, e: int, v: float, segundos := 0.06) -> void
static func girar(l: int, g: Vector3, segundos := 0.06) -> void
static func sacudir(l: int, g: float, segundos := 0.2) -> void
static func tocar(l: int, dedo: int, x: float, y: float, segundos := 0.06) -> void
static func falar(l: int, nivel: float, segundos: float) -> void
static func sente(l: int) -> Dictionary      # o que a placa virtual do lugar toca agora (H08)

class_name ForjaChecagem extends Node
var falhas: int
func esperar(cond: bool, msg: String) -> void   # «ok» ou «FAIL»
func quadros(n: int) -> void
func aperta(sim: int, botao: int) -> void
```

**Depende de:** `forja_dualsense`.

**O acoplamento a soltar:** o robô só existe dentro do autoload do jogo; a régua só existe dentro da prova. A
[F08](tarefas/F08-a-paridade.md) já pede que o robô passe só pelo controle, sem atalho no jogo: é a condição para ele
sair. O `_robo` de cada minigame fica no minigame (é o jeito de jogar daquele jogo).

### 6. A costura das telas — `forja_costura`

Quem está na tela, a cortina entre uma e outra, as camadas por cima (pausa, opções, placar) e quem tem o foco.

**Hoje:** `godot/scripts/main.gd` (989 linhas): `estado` (`:29`), `overlay` (`:58`), `_mostrar` (`:215`), `_trocar`
com a cortina (`:246`), e um `_ir_para_*` por destino (`:264-527`); a vez de cada tela em `_process` (`:542`).

**A interface pública:**

```gdscript
# autoload ForjaCostura
signal entrou(tela: StringName, dados: Dictionary)
signal saiu(tela: StringName)
signal camada_abriu(camada: StringName)
signal camada_fechou(camada: StringName)
func registrar(tela: StringName, no: Node) -> void      # o nó tem entrar(dados), sair(), quadro(dt)
func ir(tela: StringName, dados := {}, com_cortina := true) -> void
func abrir_camada(camada: StringName, no: Node) -> void
func fechar_camada() -> void
func atual() -> StringName
func camada() -> StringName
func trocando() -> bool
var cortina_s := 0.35
```

**Depende de:** nada.

**O acoplamento a soltar:** o `main.gd` sabe tudo de todo mundo (as treze telas em `:44-57`, a câmera, o salão, a
partida). A costura leva só o mecanismo (estado, cortina, camada, a vez de cada uma); cada tela do Forja implementa
`entrar/sair/quadro` e o `main` fica com a montagem e as regras do Forja (o que vem depois do quê). É a extração que
mais toca código que outras fichas editam (`grep -l main.gd docs/jogo/tarefas/*.md` dá 25): vai depois das telas G.

### 7. O kit de minigame — `forja_minigame`

O que todo minigame tem e nenhum repete: a ficha de dados, as raias, quem está conectado, o relógio da faixa, o
julgamento com o item, as notas, as falas, o fechamento, o registro.

**Hoje:** `godot/scripts/salas/sala.gd`, `sala_jogo.gd` (`SalaJogo`, as fases aviso → jogo → fim) e, depois da
[H04](tarefas/H04-o-kit-do-minigame.md) e da [H08](tarefas/H08-os-acrescimos-do-kit.md), `godot/scripts/minigames/minigame.gd`
(`Minigame`) e `catalogo.gd` (`Catalogo`). A interface está no
[13](13-arquitetura.md#o-kit-do-minigame--h04).

**A interface pública:** a do 13, com o prefixo: `ForjaMinigame extends ForjaSala`, os ganchos (`montar`,
`iniciar_jogo`, `jogar(dt)`, `toque(l, julgamento)`, `falha(l)`, `vencedor()`, `robo(l, dt)`), o que o kit faz
(`raia(l)`, `conectado(l)`, `julgar_toque(l, t_alvo, n, perigo)`, `nova_nota`, `nota_perdida`, `presentes()`,
`na_raia(l)`, `falar(l, evento)`), e `signal terminou`. O catálogo vira `ForjaCatalogo` com `registrar(id, script)`
no lugar da constante: o jogo registra os dele.

**Depende de:** `forja_dualsense`, `forja_ritmo`, `forja_texto`, `forja_costura` (o fechamento devolve a vez).

**O acoplamento a soltar:** `sala_jogo.gd` chama `Forja` (55 chamadas), `Som`, `Musica`, `Kit`, `Efeitos` e
`TelaResultado`. As chamadas ao `Forja` passam para `ForjaControle`; o som e a música, para sinais
(`pediu_som(id, lugar)`, `pediu_faixa(slot)`) que um conector do jogo atende; o `Kit` e os `Efeitos` (as peças da
Kenney, a cara do Forja) ficam no jogo e entram como `montador: Object` com `raia(l) -> Node3D`; a tela de resultado
vira `signal resultado(vencedores: Array)`. É a última: só sai quando a primeira seção (I) estiver feita com ele, para
o molde estar provado.

## A ordem

| ordem | pacote | depende de (pacote) | depende de (ficha) | por que nesta vez |
| --- | --- | --- | --- | --- |
| 1 | `forja_texto` | — | V03 | não depende de nada e todos os outros desenham texto |
| 2 | `forja_placar` | texto | X01, V04 | pequeno; prova o molde do pacote |
| 3 | `forja_ritmo` | — | H01, H02, H03 | o contrato do 13 já é a interface |
| 4 | `forja_dualsense` | — | F04, F05, F06, F10 | o maior; espera o conjunto do controle fechar |
| 5 | `forja_robo` | dualsense | X04, V02, F08 | precisa da fachada do controle e da régua |
| 6 | `forja_costura` | — | X01, as telas G | o `main.gd` é de todos |
| 7 | `forja_minigame` | dualsense, ritmo, texto, costura | X03, X04, X06, H04, H08, a seção I | o último, com o molde provado |

Duas extrações ao mesmo tempo só com arquivos disjuntos: 1 e 3 podem; 4 e 5 não.

## O que não vira pacote

- **O `Tema` e os tokens:** são a bíblia do Forja.
- **O `Kit`, os `Efeitos`, o salão:** a cara do Forja, feita de Kenney.
- **O relatório, as medidas, as cegas, a bancada:** o diagnóstico do Forja; usam o nativo, mas o pacote do controle
  não precisa deles.
- **A trilha e as ferramentas de `scripts/`:** são da oficina, não do jogo.
