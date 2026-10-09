# 13 — A arquitetura

A base comum de todas as fichas. Uma ficha nunca inventa uma API: ela usa as
daqui. Se uma ficha precisar de algo que não está aqui, a primeira coisa que
ela faz é acrescentar aqui, no mesmo commit.

Cada seção diz **o que existe hoje** (com o arquivo) e **o alvo** (o que as
fichas constroem, com a ficha que constrói).

## O mapa do código

```
godot/
  project.godot            autoloads: Forja, Som, Musica  (+ Ritmo, na H01)
  scenes/main.tscn         a cena única; tudo é montado em código
  scripts/
    forja.gd               autoload Forja: entrada e saída por lugar 0..3, argumentos, módulo nativo
    main.gd                a máquina de estados: titulo, intro (G01), lobby (vira a construção, G02), salao, sala, podio (+ overlays)
    player.gd              ForjaPlayer: o boneco, o item na mão, a cor do lugar
    partida.gd             Partida: a partida de 3, 5 ou 9, o placar, o pódio
    opcoes.gd              Opcoes (estático): vibração, gatilho, volumes, texto, idioma
    musica.gd              autoload Musica: a trilha sintetizada por sala
    som.gd                 autoload Som: os efeitos da TV (WAV Kenney) e os sintetizados
    tema.gd                Tema: cores, tamanhos, fontes
    traducoes.gd           Traducoes: o português é a chave, o inglês o valor
    salas/sala.gd          Sala: a base (entrar, sair, montar, status, luzes)
    salas/sala_jogo.gd     SalaJogo: as fases aviso → jogo → fim, treino, pontos, vereditos
    salas/<id>.gd          as nove salas de hoje e a bancada
    mundo/kit.gd           Kit: peças do Kenney, caixas, cilindros, materiais
    mundo/pintura.gd       Pintura: o OKLab, a grade de tons de cada papel, a recoloração do colormap, a malha preparada (G08)
    mundo/efeitos.gd       Efeitos: faíscas, brasas, poeira
    mundo/salao.gd         Salao: o hub, os portões
    ui/*.gd                as telas e o HUD, todos desenhados em _draw()
  shaders/                 cavaleiro (o corpo na faixa e o néon só no acento), contorno e neon (G08)
  testes/prova_do_jogo.gd  a prova sem janela (quatro controles simulados + robô)
nativo/
  nucleo/                  C: pads (SDL3), medidas, vereditos, registro, linha do tempo, relatório
  som/                     C: o som em cada controle (placa USB de 4 canais), mixer, síntese
  godot/                   C++: a GDExtension ForjaControles (o `Forja.ctl`)
include/forja_dualsense.h  o bloco de 47 bytes do USB 0x02
tests/*.sh                 as provas; scripts/*.sh a compilação, o gauntlet, a exportação
```

## O vocabulário do código

| palavra | o que é |
| --- | --- |
| **lugar** | o jogador, 0..3 (P1..P4). Toda entrada e saída passa por ele: `Forja.apertou(l, Forja.CRUZ)`, `Forja.vibrar(l, …)` |
| **pad** | o controle físico (índice do SDL); o lugar é que importa, o pad nunca aparece no jogo |
| **sala** | hoje, cada um dos nove jogos; no alvo, cada sala vira o primeiro **minigame** da sua **seção** |
| **fase** | `aviso` → `jogo` → `fim` (`SalaJogo.fase`) |
| **treino** | o começo do jogo que não vale ponto (`SalaJogo.treinando`) |
| **variante** | 0 ou 1, sorteado pela semente: muda conteúdo, não regra (`SalaJogo.variante`) |
| **med_\*** | as medidas do núcleo: a sala diz o que pede, o módulo mede e dá o veredito |
| **veredito** | PASSOU/FALHOU/NÃO MEDIDO por feature do controle. No alvo, só no registro e no Modo bancada |
| **cega** | sala que prova um recurso de saída perguntando ao jogador. No alvo, as perguntas só no Modo bancada |
| **robô** | `--robo`: joga sozinho nos controles simulados; toda sala e todo minigame precisam de um |
| **registro** | `registro-<sessão>.log` (texto), `linha-do-tempo-<sessão>.jsonl`, `relatorio-<sessão>.json/.txt` |

## As convenções

- **Nome em português**, sem abreviação obscura, como o resto do código.
- **Todo texto de tela passa por `Traducoes`** (as funções de `ui/desenho.gd` e `ui/glifo.gd` já passam) e começa com maiúscula. Frase nova = uma entrada nova em `godot/scripts/traducoes.gd`.
- **Script novo precisa do `.uid`.** O Godot 4.4 cria o `<arquivo>.gd.uid` ao importar. Depois de criar um `.gd`, rode `"$GODOT" --headless --path godot --import --quit` e commite o `.uid` junto. A prova do jogo já importa antes de rodar.
- **`class_name` em todo script que outro usa pelo nome**; os autoloads não têm `class_name`.
- **Nada de caminho fixo e nada de endereço de aparelho** no código, no registro ou no relatório (regra do [COMO-CONTRIBUIR](../COMO-CONTRIBUIR.md)).
- **Toda saída ao controle passa pelo `Forja`**, por lugar. Nenhuma sala fala com o `Forja.ctl` direto.
- **A dica de botão** é `Glifo.dica(..., com_botao := true)`: escreve "Botão ✕ (Ação)" (F07). O ícone da parte do controle usada vive em `SalaJogo.icone` (F02) e, nos minigames, em `FICHA.icone`.
- **A coleta de texto para a prova:** `Desenho._coletar = "memoria"` guarda cada frase desenhada, para a prova conferir o que a tela mostrou (F02).
- **O texto que vem do núcleo em C** (o porquê dos vereditos, os experimentos) fica fora da regra de maiúscula por enquanto: só aparece no Modo bancada.
- **O que não se sabe, não se inventa:** se o comportamento do SDL, do Godot ou do controle não está na ficha nem aqui, a sessão mede ou para e anota.

## O ambiente de uma sessão

Uma sessão nova na nuvem começa sem os pacotes de sistema, sem o módulo e sem
o Godot. A ficha [F00](tarefas/F00-o-ambiente-da-sessao.md) põe um gancho de
início de sessão (na configuração da própria sessão, fora do repositório) que
chama `scripts/preparar_sessao.sh`: ele instala o que falta, baixa o Godot que
o `scripts/engine.sh` fixa e compila o módulo. Depois dele, a primeira coisa
de qualquer ficha é a prova rápida:

```bash
bash tests/prova_do_jogo.sh
```

Fora da nuvem o script não faz nada. Nunca rode `./run-local.sh` numa sessão
da nuvem: ele abre a janela do jogo no fim.

## Os contratos internos

### O Modo bancada — F01

**Hoje:** as perguntas, os vereditos na tela, o diagnóstico e o livro estão
sempre ligados.

**Alvo:** `Forja.bancada: bool`, ligado por `--bancada` (e também por
`--experimento=` e `--prova-de-fogo`, que já são de bancada). Quem pergunta:

```gdscript
if Forja.bancada:
    # pergunta às cegas, tabela de veredito, diagnóstico (Create), livro (pausa)
```

Os vereditos continuam sendo **calculados e gravados** nos dois modos. Só a
tela muda.

- Fora da bancada, a sala às cegas **pula o estado de pergunta** e segue para
  o que vem depois da resposta. Reflexo não é pergunta: o escudo do Impacto e
  o tropeço dos Caminhos ficam nos dois modos.
- As perguntas de luzinhas e de cor (Galeria, Prova) **continuam no Modo
  bancada**: sem elas, os vereditos `leds_jogador` e `lightbar` não se medem.
- O registro diz o modo: evento `sessao` com `"evento": "modo"`, e uma linha
  `saida` com `"o": "pergunta"` a cada pergunta aberta.
- O gauntlet e a prova de poucos são provas **da bancada** (conferem os
  vereditos das perguntas) e rodam com `--bancada`.

### As sensações — F05

**Hoje:** as salas chamam `Forja.vibrar(l, forte, fraco, ms)` com números
soltos (`godot/scripts/forja.gd:447`).

**Alvo:** uma tabela de sensações em `forja.gd`, e as salas pedem pelo nome:

```gdscript
const SENSACOES := {
    "toque":    [0.0, 0.45,  60],   # navegar na interface
    "acerto":   [0.3, 0.6,   80],
    "perfeito": [0.5, 0.8,  100],
    "erro":     [0.7, 0.3,  160],
    "golpe":    [1.0, 0.6,  250],   # golpe recebido, queda
    "explosao": [1.0, 1.0,  400],   # explosão, fim de rodada
    "aviso":    [0.6, 0.0,  200],   # perigo um tempo antes (a duração pode ser trocada pela do tempo da faixa)
}
func sentir(l: int, nome: String, ms := -1) -> bool
```

A tabela ganha também as direcionais, já na F05, porque o Impacto e a Prova
vibram de um lado só hoje:

```gdscript
    "golpe_esq": [1.0, 0.0, 250],
    "golpe_dir": [0.0, 1.0, 250],
```

`Forja.vibrar` continua existindo, mas **só é chamado dentro de `forja.gd`**.
`sentir` grava a linha `sensacao` com `nome`, `escala` e `ms`. Com o motor
vibrando, `Forja.som_haptica` daquele lugar devolve -1 (rumble e háptica por
áudio nunca juntos, suspeita (e) de [05](05-haptica-e-controle.md#por-que-o-háptico-está-fraco)). A prova do jogo confere com `grep` que nenhum
outro script chama `Forja.vibrar`. Valores e o porquê em
[05](05-haptica-e-controle.md#o-piso-de-força). A única exceção declarada é
`Forja.sentir_forca` (F10): a força solta nos dois motores, sem a escala das
opções, que só o experimento `forca` da bancada pede (a medição às cegas do
rumble seco); a prova confere que nenhum outro script a chama.

### O registro v2 — F06, H01, H02, G02, H07

**Antes da F06:** formato `hefesto-tech-demo/linha-do-tempo/1`, uma linha por
evento com `t`, `tipo`, `jogador` (1..4, 0 = a mesa); o `t` era **sempre** o
tempo do jogo e os `Array` do GDScript saíam como texto. **A F06 entregou o
v2** (`LINHA_TEMPO_FORMATO` em `nativo/nucleo/linha_tempo.h`; `lt_t_musica`,
`ev_nums` e `ev_strs` no núcleo; `Forja.t_musica(s)`; `--acelerado`; `seq` em
`ev_saida`; `pad_transporte` em `nativo/nucleo/pads.c`). O alvo abaixo é o
que ela escreve.

**Alvo:** formato `hefesto-tech-demo/linha-do-tempo/2`. Toda linha:

```json
{"t": 12.345, "t_musica": 8.120, "tipo": "saida", "jogador": 3, "lugar": 2, ...}
```

- `t`: segundos desde o início da sessão, **relógio monotônico de parede**.
  O tempo do jogo só com `ctl.acelerar(true)`, que só se aceita com
  `--simular`; a linha `sessao` diz qual: `"relogio": "parede"` ou `"jogo"`.
- `t_musica`: a posição da música, quando há; ausente quando não há. O C
  recebe do GDScript por `Forja.t_musica(s)` (`lt_t_musica` no núcleo),
  chamado pelo `Ritmo` a cada quadro (H01).
- `jogador` continua 1..4 para não quebrar leitores, e `lugar` (0..3) vai
  **junto** dele. Linha da mesa (`jogador` 0) não tem `lugar`.
- `Array` do GDScript vira array JSON (inteiros, números ou textos, até 16
  itens), e NaN vira `null` (medido na F06: `tb_json_num` já fazia, o `nan`
  que se temia não existe; a prova grava um NaN e um array de propósito).
- O transporte e o firmware de cada controle ficam também no dicionário do
  pad (`Forja.pad(i)["transporte"]`, `["firmware"]`), para o jogo repetir
  o transporte onde o cruzamento precisa (a `calibracao`).

Os tipos, e quem os escreve:

| tipo | campos | quem |
| --- | --- | --- |
| `conexao` | `transporte` (`"usb"`, `"bt"`, `"virtual"` para o simulado, `"desconhecido"`), `firmware` (ex.: `"0x0224"`), `rumble_escala_cheia` (se o SDL manda o rumble sem o corte pela metade), `vid_pid`; `"evento": "reservou"` quando o lugar é dado na conexão (F04) | F05 (firmware), F06 (o resto), F04 (reserva) |
| `saida` | `seq` (por lugar, cresce, nunca repete; é o mesmo contador do `som_controle`), `o` (`vibracao`, `gatilho`, `lightbar`, `leds_jogador`, `player_index`, `led_microfone`, `audio_hid`), os valores, `ok` | F06 (C) |
| `som_controle` | `lugar`, `seq` (o mesmo contador por lugar das `saida`, uma ordem só), `papel` (`alto_falante`/`haptica`), `som` (o nome que o jogo pediu; na háptica `esquerdo\|direito` quando os dois lados diferem), `ganho`, `placa` (`true` se o lugar tinha alto-falante ou atuador; `false`: o som não saiu) | H07 (C) |
| `sensacao` | `nome` (da tabela de sensações), `escala`, `ms` | F05 |
| `minigame` | `slot`, `evento` (`comecou`/`terminou`), `vencedor` (o lugar 0..3, ou -1 no coop), `pontos`, `itens`, `duracao` | F03 |
| `nota` | `slot`, `n` (índice), `t_alvo` (em tempo de música) | H01 |
| `toque` | `slot`, `faixa`, `lugar`, `n`, `t_musica`, `julgamento` (`perfeito`/`otimo`/`bom`/`erro`), `desvio_ms`; `perdida` (`true`) no lugar de `desvio_ms` quando a nota passou sem toque | H02 |
| `calibracao` | `lugar`, `desvio_ms`, `amostras`, `origem` (`opcoes`/`construcao`), `transporte` (o `conexao_curta` do controle do lugar, repetido para o cruzamento não precisar juntar) | H03 (à mão), G02 (a construção) |
| `item` | `item`, `efeito` | G03 |
| `sessao` | amplia o de hoje com `escala_vibracao` e `gatilho` de cada lugar | F05 |
| `cavaleiro` | `boneco`, `item`, `nome`, `acabamento` (a G13 troca `boneco` por `cabeca`, `superior`, `inferior`) | G02 |
| `colecao` | `desbloqueou` (o que), `por` (a conquista) | G06 |
| `fala` | `evento`, `texto` | G07 |
| `desempenho` | `slot`, `fps_min`, `fps_media` | F09 |

O gauntlet, a bancada e a prova leem as versões 1 e 2 enquanto houver
arquivos das duas.

### O relógio de áudio e o julgamento — H01, H02, H03

**Hoje:** não existe; `musica.gd` sintetiza oito compassos por sala.

**Alvo:** o autoload `Ritmo` (`godot/scripts/ritmo.gd`):

```gdscript
# o relógio
func tocar(slot: String, bpm: float, primeiro_tempo_s: float) -> void   # agenda no próximo mix
func t_musica() -> float          # a posição que se ouve agora (nunca anda para trás)
func batida() -> float            # t_musica() * bpm / 60, contada do primeiro tempo
signal batida_cheia(n: int)       # a cada tempo inteiro
signal compasso(n: int)           # a cada 4 tempos

# o julgamento
enum { ERRO, BOM, OTIMO, PERFEITO }
const JANELA_PERFEITO := Vector2(-0.040, 0.060)   # (adiantado, atrasado), em s
const JANELA_OTIMO := 0.090
const JANELA_BOM := 0.140
const NOMES_DO_JULGAMENTO := ["erro", "bom", "otimo", "perfeito"]   # os do registro, na ordem do enum
const FOLGA_DO_ULTIMO := 0.040                    # a ajuda escondida, só na janela BOM dos perigos físicos
func julgar(l: int, t_toque: float, t_alvo: float, folga_bom := 0.0) -> int
func desvio_ms(l: int, t_toque: float, t_alvo: float) -> float   # o desvio já corrigido pelo lugar, em ms, uma casa
static func folga_para(l: int, pontos: Array, presentes: Array) -> float   # FOLGA_DO_ULTIMO só para o último sozinho
var desvio := [0.0, 0.0, 0.0, 0.0]   # a calibração de cada lugar, em s, lida de Opcoes.tempo_ms (G02/H03)
```

A calibração **persiste** em `Opcoes.tempo_ms[l]` (em ms, de `TEMPO_MIN` −150
a `TEMPO_MAX` +250, no `user://opcoes.cfg`, seção do lugar). Quem muda o
tempo chama `Ritmo.definir_desvio(l, segundos, origem, amostras)`: ela põe o
desvio no `Ritmo`, o tempo nas `Opcoes` (quem grava o arquivo é quem chama) e
escreve a linha `calibracao`; as opções chamam com `"opcoes"` (a linha Tempo,
de 10 em 10 ms) e a construção do cavaleiro (G02) com `"construcao"`. O
`Ritmo` lê `Opcoes.tempo_ms` ao começar (`ler_das_opcoes`). `Opcoes.tempo_ms[l]` guarda
a calibração: a G02 mede nas 8 marteladas, as Opções ajustam à mão; o `Ritmo` lê de lá ao abrir. O cavaleiro inteiro
também vive em `Opcoes`: `Opcoes.cavaleiro[l]`, `Opcoes.noite()` (o que vale
só para a noite corrente) e `Opcoes.guardar()` — que as telas chamam sem
saber se é robô (quem não grava com robô é o próprio `Opcoes`).

`julgar` subtrai o `desvio[l]` do toque antes de comparar. A borda vale
dentro; desvio e bordas arredondados a 0,1 ms: medido,
`(10.06 - 10) * 1000` dá `60.0000000000005`, e o `Vector2` guarda 32 bits
(−0,040 vira −39,99999); sem arredondar, o toque exato na borda seria
reprovado.

O `Ritmo` tem ainda:

```gdscript
func parar() -> void
func pausar(sim: bool) -> void          # a pausa congela a música e as notas
func t_da_batida(n: float) -> float     # o tempo de música da batida n
func registrar_nota(l: int, n: int, t_alvo: float) -> void   # o tipo `nota` do registro v2
static func posicao_continua(pos, anterior, voltas, laco_s) -> Array  # a volta do laço; pura, para a prova
var dono := ""                          # o slot do minigame que vai no registro (o slot do Ritmo é a faixa)
var simples := [false, false, false, false]   # a partitura mais simples de quem está errando
func contar_para_ajuda(l: int, j: int) -> void   # três erros seguidos ligam `simples`, quatro acertos seguidos desligam
func zerar_ajuda() -> void                       # todo minigame começa sem ajuda (o kit chama)
func registrar_toque(l: int, n: int, j: int, desvio_em_ms := NAN) -> void   # o tipo `toque`; sem desvio, `perdida`
```

E a `Musica` ganha `tocar_do_zero(slot)`, `mapa(slot)`, `laco_s()`,
`bpm_sintetizado()` e um tween por vez. **A trilha sintetizada escorrega:** a
síntese arredonda o tempo para um número inteiro de amostras (108 bpm vira
108,0027), cerca de 4,5 ms em 3 minutos; o `Ritmo` usa o `bpm_sintetizado()`,
não o nominal. A `folga_bom` é
a ajuda escondida de quem está em último ([02](02-principios.md#8-ninguém-fica-para-trás-ninguém-é-punido-por-ser-bom)).
**Os relógios, medidos:** com faixa, `t_musica()` é o da placa de som —
também nas provas sem janela, onde o driver Dummy do Godot mistura (cerca de
0,3% mais devagar que a parede). Sem faixa (`"faixa": ""`), anda pelo
relógio do sistema. Com `--fixed-fps 60` o **jogo** anda cerca de 16 vezes
mais depressa que a música. Por isso: o mundo se mexe **pela batida**, o
robô mira pelo relógio da música, as provas esperam **fase** em quadros e
**música** pelo relógio de parede.

### O kit do minigame — H04

**Hoje:** cada sala estende `SalaJogo` e repete a raia, `_conectado`,
`RAIAS := [-6.0, -2.0, 2.0, 6.0]` e as guardas de `dica`/`status`.

**Alvo:** `class_name Minigame extends SalaJogo`
(`godot/scripts/minigames/minigame.gd`). Os 45 estendem `Minigame`.
`SalaJogo` continua com as fases, o treino, as medidas e os vereditos (que
servem à bancada); `Minigame` acrescenta o resto.

**A ficha de dados** é um dicionário constante no próprio script do
minigame. Sem `.tres`: é texto, cabe no diff e se escreve sem o editor.

```gdscript
extends Minigame

const FICHA := {
    "slot": "S01_J01",
    "titulo": "O Martelo de Hefesto",
    "verbo": "Bata!",
    "genero": "tct",            # tct, 2v2, coop, corrida, sobrevivencia, terror, sabotagem
    "icone": "botoes",           # a parte do controle, para o aviso
    "entradas": [Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO, Forja.TRIANGULO],
    "camera": "fixa",            # fixa, grupo, corrida
    "faixa": "MUS_S01_J01",
    "duracao": 90.0,             # 0: acaba pelo fim do próprio jogo
    "fim": "tempo",              # tempo, ultimo_em_pe, primeiro_a_chegar, meta_coletiva
    "sensacoes": ["acerto", "perfeito", "erro"],
    "material": "metal",
    "microjogo": {"verbo": "Bata!", "segundos": 6.0},
}
```

`Minigame._init()` lê a `FICHA` e preenche `id`, `nome`, `acao`, `duracao`;
`Minigame.entrar()` confere as chaves obrigatórias e falha alto (`push_error`)
se faltar alguma.

**GDScript, medido:** o minigame que escreve `_init()` sem `super()` não lê a
FICHA; redeclarar `RAIAS` na filha é erro de análise; o minigame **não tem**
`class_name` (o catálogo carrega pelo caminho); `Forja.CRUZ` dentro do
`const FICHA` funciona.

**O que o kit faz** (e o minigame não repete):

| o kit | como |
| --- | --- |
| as raias | `raia(l) -> Node3D` monta a laje, a borda na cor do lugar e a luz da vez em `RAIAS[l]`; `posicionar(l)` põe o boneco nela |
| quem está conectado | `conectado(l) -> bool` |
| o relógio | `Ritmo.tocar(...)` com a faixa da ficha na fase `jogo` |
| o julgamento | `julgar_toque(l, t_alvo, n := -1, perigo := false) -> int`: chama `Ritmo.julgar` (com a folga de quem está em último se `perigo`) com a janela de `Itens.janela_perfeito`, aplica `Itens.pontos_do_acerto`, `Itens.absorve_erro` e `Itens.ganho_da_nota` (G03), grava o `toque` com o número da nota, chama `sentir` e o som da nota |
| as notas | `nova_nota(l, n, t_alvo)` registra a nota; `nota_perdida(l, n)` registra o erro sem toque e chama `falha` |
| quem joga | `presentes()`, `na_raia(l)` (a guarda de `dica`/`status`), `acender_raia(l, forca)` |
| a ficha | `conferir_a_ficha()` no `entrar()`, com `Minigame.CHAVES` |
| as falas | `falar(l, evento)` com o limite de uma a cada 20 s por lugar (G07) |
| o fechamento | na fase `fim`: apito, resultado com `vencedor()`, jingle, volta em 6 s (F03) |
| o registro | `minigame`, `nota`, `toque` |
| a câmera | pelo modo da ficha (G05) |

**Os ganchos** que o minigame implementa:

```gdscript
func montar() -> void                         # o cenário (peças do kit, doc 11)
func iniciar_jogo() -> void                   # a fase jogo começou
func jogar(dt: float) -> void                 # um quadro
func toque(l: int, julgamento: int) -> void   # a consequência de um toque julgado
func falha(l: int) -> void                    # a falha física (erro ou nota perdida)
func vencedor() -> Array                      # os lugares na ordem de colocação
func robo(l: int, dt: float) -> void          # como o robô joga
```

**O catálogo:** `godot/scripts/minigames/catalogo.gd` (`class_name Catalogo`)
substitui o `SALAS` de `godot/scripts/main.gd:13-24`:

```gdscript
const SECOES := [
    {"id": "S01", "nome": "A Centelha", "minigames": ["S01_J01", ...]},
    ...
]
const MINIGAMES := {
    "S01_J01": preload("res://scripts/minigames/s01/martelo_de_hefesto.gd"),
    ...
}
```

Os ids antigos (`centelha`, `viga`…) continuam valendo em `--sala=` como
apelidos do primeiro minigame de cada seção, para as provas e os roteiros de
hoje não quebrarem. A partida, o salão e a música falam pelo apelido; o
`main` usa o `sala_id` (o que foi pedido), não o `sala.id`. Cada seção em
`SECOES` tem `apelido`; o catálogo tem `SALAS_ANTIGAS` e `NOMES_VELHOS`.

Os eventos `minigame` e `desempenho` têm **um dono só: a `SalaJogo`**. A
colocação é a `var colocacao` da `SalaJogo` (F03), preenchida pelo
`vencedor()`; o kit **não** declara uma `func colocacao()` (o nome
colidiria).

**Onde mora cada minigame:** `godot/scripts/minigames/sNN/<nome>.gd`. As
nove salas de hoje se mudam para lá quando são reescritas (ficha da seção),
e a sala antiga sai de `godot/scripts/salas/`.

**Como ficou na leva 1 (o que o kit acrescentou ao desenho acima):**

- As chaves **opcionais** da FICHA: `features` (o que a bancada mede),
  `botoes_medidos`, `gesto` (o gesto do aviso) e `treino` (padrão `true`).
  O `icone` da FICHA pode ser a parte do controle: a tabela
  `Minigame.ICONE_DA_PARTE` a traduz para o glifo do aviso (`botoes` vira
  `cross`); um nome de glifo passa como está.
- `julgar_toque(l, t_alvo, n := -1, perigo := false)` e `conferir_a_ficha()`
  (sem chave, ou valor fora de `GENEROS`/`FINS`/`CAMERAS`/`MATERIAIS`,
  devolve `false` e fala alto com `push_error`).
- O kit chama `robo(l, dt)` de todo lugar em jogo, a cada quadro, e não
  olha `Forja.robo`: quem olha é o gancho do minigame.
- A `SalaJogo` continua dona de `minigame`, `desempenho`, `var colocacao` e
  `vencedor()`; o kit só solta o relógio (`Ritmo.parar()`) no `terminar()`
  e no `sair()`.
- O catálogo real tem `apelido` em cada seção, `SALAS_ANTIGAS` (as salas
  que ainda não viraram minigame, mais a bancada) e `NOMES_VELHOS`
  (`giro` abre a Viga). `Catalogo.apelido(slot)` devolve o apelido da seção
  de um slot (`S01_J01` vira `centelha`), e o próprio id se não é de seção.
- A linha do tempo grava o **slot** do minigame (`S01_J01`), não o apelido.
- **A contagem de entrada (H06).** `Minigame.BATIDA_DA_PRIMEIRA_NOTA := 4`: os
  quatro primeiros tempos da faixa são a contagem, e a primeira nota vem
  depois. `Minigame._som_do_comeco()` (que a `SalaJogo` chama no lugar do
  «confirma» solto) escuta `Ritmo.batida_cheia`: `JIN_ENTRADA` nos tempos 0, 1
  e 2 e o «confirma» no 3; o `sair()` desconecta. Sala fora do kit não tem
  `Ritmo` e fica com o «confirma».
- A primeira moradora: `godot/scripts/minigames/s01/martelo_de_hefesto.gd`
  (A Centelha, `S01_J01`, «O Martelo de Hefesto», verbo «Bata!»). O minigame
  de prova do kit é `godot/testes/minigame_de_prova.gd` (`T00_J00`).

### O som em todo evento — H07

Todo evento tem som na TV **e** algo no controle do dono (docs/jogo/05).

- **A placa fica aberta.** `Main._abrir_o_som()` abre a placa de áudio dos
  controles quando muda quem está (`_sincronizar_jogadores`) e ela fica
  aberta pelas salas, pelo placar e pelo pódio; as salas só abrem se ainda
  não abriu (`Forja.som_pronto()`), e só as de som (`papel_som >= 0`)
  refazem, porque deixam trocar o dispositivo. Um controle que cai e volta
  refaz a placa (`_caiu` e `_ao_mudar_os_controles`), sem pio. Quem acabou
  de entrar ouve o pio do cavaleiro (`pio:<boneco>`), só no controle dele.
- **Um som por vez no alto-falante.** `somc_falante` leva o anterior daquele
  alto-falante a zero pela rampa (`nativo/som/rampa.h`, `RAMPA_SAIDA_MS`
  20 ms); `mixer_parar_tudo` também sai pela rampa. Os nomes novos do módulo:
  `pio:<boneco>` (12), `nota:<lugar>`, `nota_quebrada:<lugar>`, `coleta`,
  `material:<nome>` (o tipo C é `MaterialHaptico`: `Material` é nome do
  godot-cpp; `plasma` é a lama).
- **O GDScript.** `Forja.som_pronto()`; `Forja.tocar_material(l, material,
  sensacao, forca)`: no cabo, a onda nos atuadores e, mais baixa, no
  alto-falante; sem placa, o rumble, nunca os dois. `Musica.reagir(evento)`
  em cima do barramento `Musica` (passa-baixa): o erro abafa por 300 ms, o
  perfeito abaixa 2 dB por 80 ms, o combo (`Minigame.COMBO`, oito perfeitos
  seguidos do lugar) sobe 1,5 dB por 2 s. No kit, `_reagir` toca a nota
  limpa do lugar no perfeito, a quebrada no erro, e o material no acerto.
- **A navegação** (`Main._passo`) clica baixinho (`clique`, 0,5) no controle
  de quem navegou.

### Os acréscimos das telas — G01 a G08

Cada ficha G acrescenta aqui, no mesmo commit, o que cria. O que já está
decidido:

| onde | o quê | ficha |
| --- | --- | --- |
| `main.gd` | estado `intro` (24 s, acaba sozinha; qualquer botão pula); `ui/tela_intro.gd` | G01 |
| `Som` | `Som.pio(l)`: o pio do cavaleiro no alto-falante do controle | G01 |
| `player.gd` | `BONECOS`, `PECAS`, `tingir`, `cabeca`, `vestir`, `cavaleiro` | G02, G08 |
| `SalaJogo` | o sinal `no_visor`, `combo(l)` | G04 |
| `SalaJogo` | `camera_modo`, `camera_distancia`, `camera_frente`, `camera_alcance`, `camera_foco`, `tremer()`, `abalo`, `TREMOR_GOLPE`, `TREMOR_EXPLOSAO`; `godot/scripts/enquadramento.gd` (`class_name Enquadramento`) | G05 |
| `SalaJogo` | `usa_gatilho`, `errou(l)` | G03 |
| `player.gd` | `BONECOS` com o `intervalo` do pio (saem `MODELOS`, `NOME_DO_MODELO`, `INTERVALO_DO_MODELO`), `nome_do_boneco`, `brilho_do_contorno`, `acender_acento`; `Kit.anel_do_dono` | G08 |
| `SalaJogo` | `falar(l, evento)`, `mostrar_julgamento(l, j)` — em `SalaJogo`, para as salas de hoje usarem antes do kit; `godot/scripts/falas.gd` | G07 |
| `Salao` | `pulso`, `apagado`, `acender_bigorna`, `mostrar_colecao`; `godot/scripts/colecao.gd` | G06 |
| `scripts/` | `conferir_bonecos.py`: confere os sete ossos e as animações de um `.glb` | G08 |

Os pacotes Kenney entram cada um na sua pasta, `godot/assets/kenney/<pacote>/`
(o Mini Dungeon de hoje se muda para `godot/assets/kenney/mini-dungeon/`),
porque o `Textures/colormap.png` de um pacote sobrescreveria o do outro. O
caminho de toda peça sai de `Kit.caminho(nome)`: `"castle-kit/tower-base"`
vai para `res://assets/kenney/castle-kit/tower-base.glb`; sem pacote no nome,
vale o `mini-dungeon`. A curadoria (o que entra e o que não) é o
[14](14-os-assets-kenney.md); a importação, a [G10](tarefas/G10-a-biblioteca-kenney.md).

### O item — G03

**Hoje:** o `player.gd` tem `ITENS` com os sete (0 «Mãos livres», 1 Martelo,
2 Escudo, 3 Fole, 4 Lanterna, 5 Diapasão, 6 Âncora), cada um com `"icone"`; o
corpo leva o item no `BoneAttachment3D` `"Item"` e a runa acende no néon do
dono. A mecânica é a classe `Itens`.

**Alvo:** `godot/scripts/itens.gd` (`class_name Itens`, estático). O índice é o
mesmo do `ITENS`; a mecânica lê `Itens.escolhido`, porque a sala pode tirar o
item visual (`SalaJogo.maos_livres`).

```gdscript
enum { NENHUM, MARTELO, ESCUDO, FOLE, LANTERNA, DIAPASAO, ANCORA }
const PERFEITO := 3                                   # o julgamento, na numeração do Ritmo (ERRO 0, BOM 1, OTIMO 2, PERFEITO 3)
static var escolhido := [NENHUM, NENHUM, NENHUM, NENHUM]   # a construção escreve; a sala não mexe
static var em_liga := [false, false, false, false]         # a G13 escreve ao forjar; até lá, false
static func do_lugar(l: int) -> int
static func pontos_do_acerto(l: int, pontos: int, julgamento: int, no_tempo_forte: bool) -> int  # Martelo: mexe em pontos, não no julgamento
static func absorve_erro(l: int) -> bool                                                   # Escudo, uma vez por minigame
static func escudo_inteiro(l: int) -> bool
static func combo_inicial(l: int, normal: int) -> int
static func acertos_para_voltar_o_combo(l: int, normal: int) -> int                        # Fole
static func combo_maximo(l: int, normal: int) -> int
static func antecipacao_s(l: int, bpm: float) -> float                                     # Lanterna: meio tempo da faixa
static func janela_perfeito(l: int, janela: Vector2) -> Vector2                            # Lanterna encolhe 10 ms
static func ganho_da_nota(l: int, genero: String) -> float                                 # Diapasão
static func puxa_o_combo_da_equipe(l: int, genero: String) -> bool                         # Diapasão, só em dupla e coop
static func resiste_a_empurrao(l: int) -> float                                            # Âncora, 0..1
static func velocidade(l: int, genero: String) -> float                                    # Âncora anda mais devagar na corrida
static func sentir(l: int) -> void                                                         # o item se sente no controle (L2)
static func novo_minigame() -> void                                                        # repõe o Escudo dos quatro
static func registrar(l: int, efeito: String) -> void                                      # linha `item` da linha do tempo
```

O gatilho do item mexe **só no L2**; o R2 fica com o minigame. Até o kit
(H04), o Escudo age só onde a sala chama `SalaJogo.errou(l)` (a Centelha); nas
salas às cegas, nunca.

### A tela de resultado — F03

**Hoje:** a fase `fim` desenha a tabela de veredito
(`godot/scripts/ui/painel_sala.gd:356-415`) e espera ✕
(`godot/scripts/salas/sala_jogo.gd` `_quadro_fim`).

**Alvo:** `godot/scripts/ui/resultado.gd` (`class_name TelaResultado`),
aberta pela fase `fim` para toda sala e todo minigame:

- `abrir(titulo: String, colocacao: Array, pontos: Array, coop: bool, coop_venceu: bool)`;
- `SalaJogo.vencedor() -> Array` com um padrão (os lugares pela ordem dos
  pontos); o minigame troca quando o critério é outro;
- `SalaJogo.t_jogo`: o tempo de jogo valendo (o treino não conta), para o
  relógio da tela nunca voltar;
- `SalaJogo.AVISO_MAX := 8.0`: o aviso começa sozinho;
- sequência: apito (0,5 s), resultado com o vencedor em destaque (o boneco
  faz `emote-yes`, faíscas na cor), jingle, "Botão ✕ (Continuar)";
- avança sozinha em 6 s, **para todo mundo** — sem atalho de robô
  ([a paridade](#a-paridade-entre-a-prova-e-o-jogo--f08));
- no Modo bancada, a tabela de veredito aparece **abaixo** do resultado;
- **O som do fim (H06).** O apito é `Musica.parar_seco()` (a música a zero em
  20 ms, nunca de uma vez) mais `Som.jingle("JIN_APITO")`, no `terminar()` da
  `SalaJogo`; aos `APITO_S` o `_celebrar()` toca
  `Som.jingle(Som.jingle_do_resultado(pontos, presentes, coop, coop_venceu))`:
  a vitória, o empate em primeiro, e no coop a de todos ou a derrota.
  `Som.jingle(nome) -> float` devolve a duração (0: sem som) e guarda
  `Som.ultimo_jingle` (a prova lê); o arquivo próprio
  `assets/ost/jingles/<nome>.ogg` ganha de `Som.JINGLES`, a tabela do
  provisório (gravação da Kenney ou síntese). A virada do placar toca
  `JIN_VIRADA`. O `JIN_RECORDE` espera quem guarde o recorde da noite.

### A identidade — F04

**Hoje:** o lugar é escolhido no ✕ do lobby (`nativo/nucleo/pads.c:506-570`).

**Alvo:** o lugar é dado **na conexão** (`conectou()` em `pads.c`), com
`SDL_SetGamepadPlayerIndex`, as luzinhas e a cor na hora. O ✕ do lobby só
confirma. Regras em [05](05-haptica-e-controle.md#a-identidade-p1p4).

A API da reserva:

| onde | o quê |
| --- | --- |
| C (`nativo/nucleo/pads.c`) | `Pad.reserva` (o lugar reservado ao pad), `Slot.reservado_por`, `pad_lugar(pad)`, `pads_trocar_reserva(pad)` |
| jogo (`godot/scripts/forja.gd`) | `Forja.trocar_lugar(l)`, `Forja.pad_segura(indice, botao)`, `pad(i)["reserva"]`, `lugar(l)["reservado"]` |

A barra de luz nunca fica abaixo de 30% de brilho, e um piscar de outra cor
dura no máximo 0,5 s: a cor do lugar sempre volta.

## A paridade entre a prova e o jogo — F08

O que a prova valida tem de ser **o mesmo jogo** que as pessoas jogam.
Uma prova que passa por um caminho que o jogador nunca percorre não prova
nada. As regras:

1. **O robô só age pelo controle.** Ele aperta, inclina, toca e fala pelos
   controles simulados (`Forja.robo_apertar`, `robo_eixo`, `robo_girar`,
   `robo_tocar`, `robo_falar`, `robo_sacudir`) — nunca por um atalho no
   código do jogo. A F08 tirou os que havia (o aviso que marcava o robô pronto
   sem ✕ e o placar que avançava sozinho): o ✕ chega por
   `Forja.robo_confirmar(l, depois_s)`, pelo controle simulado, e o fim da sala
   avança em 6 s para todo mundo.
2. **`Forja.robo` só aparece em um lugar por minigame:** no gancho `robo(l, dt)`
   (e, até o kit, na função `_robo` de cada sala). Nas telas com entrada no
   tempo, o mesmo: `main._robo(dt)` e `TelaLobby.robo(l, dt)`, chamados numa
   linha `if Forja.robo: _robo(dt)`. Fora disso, o jogo não sabe que é um
   robô. A prova do jogo confere isso lendo cada `.gd` de `res://scripts/`
   (`atalhos_do_robo`), aceitando só essa linha, as funções `_robo*`/`robo*` e
   `Opcoes.gravar(Forja.robo)`; a régua reprova um atalho plantado.
3. **O modo do jogador é o modo provado.** A prova do jogo roda **sem**
   `--bancada`, pelo fluxo inteiro (título → construção → salão → partida →
   pódio). O Modo bancada tem a sua própria prova, e só **acrescenta** camadas
   (perguntas, veredito, diagnóstico); nunca muda regra, tempo ou tela do jogo
   por baixo.
4. **As fotos são do jogo.** `tests/telas.sh` fotografa o mesmo fluxo, sem
   cena de teste montada à mão.
5. **O controle simulado recebe o que o de verdade receberia.** A prova
   confere pelo que chegou em cada controle simulado (player index, luz,
   luzinhas, gatilhos, motores) e pela linha do tempo — os mesmos dados que a
   noite de seis horas cruza.
6. **A noite roda o pacote exportado**, não o jogo aberto pelo código: o
   AppImage ou o `.exe` que `scripts/exportar.sh` gera, com o mesmo roteiro
   de robô passando antes em `bash tests/prova_da_exportacao.sh`.
7. **O único argumento que muda o tempo** é `--fixed-fps 60` (e, depois da
   F06, `ctl.acelerar` com `--simular`, que só troca o relógio da linha do
   tempo); nenhum argumento de prova encurta sala, treino ou fechamento.

## A prova visual — F09

Na primeira noite, as fotos e os GIFs mostravam tudo certo, e a partida
jogada mostrou erros grosseiros. As imagens de hoje
(`godot/testes/captura_jogo.gd`, `scripts/trailer.sh`) apertam botões de
verdade, mas **enxergam um jogo arrumado para a câmera**:

| o que esconde o erro | onde |
| --- | --- |
| todo mundo entra por código, e o jogo abre direto na sala ou na tela | `_todos_entram()` e `--sala=`/`--tela=` em `godot/scripts/main.gd:156-200` |
| a foto sai em momentos escolhidos (aviso, meio, veredito) | o roteiro de `captura_jogo.gd` |
| o robô acerta sempre: falha, empate, lugar vazio e controle que cai nunca são filmados | o `_robo` de cada sala |
| sempre quatro controles | `--simular=4` |
| `--fixed-fps 60` esconde as travadas de quadro | as provas e as fotos |
| entre as fotos, a janela encolhe (`RAPIDO=1`) | `captura_jogo.gd` |
| na nuvem, o renderizador é por software: luz, brilho e névoa não são os da máquina de verdade | o Godot sem GPU |

As regras:

1. **Vídeo da partida inteira, não foto escolhida.** A prova visual grava
   do título ao pódio pelo fluxo que o jogador percorre (sem `--sala=`, sem
   `--tela=`, sem `_todos_entram()`): cada um entra apertando ✕ no seu
   controle simulado.
2. **A prancha.** Do vídeo sai uma prancha com um quadro a cada 2 s, em
   grade, com a hora de cada quadro. Olhar a prancha inteira leva um minuto
   e mostra o que estava entre as fotos.
3. **O robô erra.** Três temperamentos, escolhidos por `--robo=bom`,
   `--robo=medio`, `--robo=ruim`: o bom acerta quase tudo, o médio erra um
   terço, o ruim erra a maioria e às vezes não aperta. Todos agem só pelo
   controle simulado ([a paridade](#a-paridade-entre-a-prova-e-o-jogo--f08)).
4. **Os casos que quebram jogo.** Toda prova visual roda, além dos quatro,
   uma partida com dois jogadores, uma com um jogador, e uma em que um
   controle desconecta no meio de um minigame e volta no seguinte (o
   simulador desconecta, como o cabo que sai).
5. **As checagens automáticas sobre todos os quadros,** não só as fotos:
   - **tela parada:** o mesmo quadro por mais de 5 s fora da pausa;
   - **tela vazia:** quadro quase todo de uma cor;
   - **texto encavalado ou fora da tela:** cada frase desenhada é guardada
     com o seu retângulo (a coleta de `Desenho` da F02), e a checagem
     reprova sobreposição, retângulo fora da área segura e texto abaixo de
     30 px;
   - **relógio que sobe** durante o jogo;
   - **fim sem vencedor:** um `minigame` `terminou` sem `vencedor` na linha
     do tempo;
   - **minúscula** no começo de frase de tela.
6. **O quadro por segundo real.** O jogo grava na linha do tempo o mínimo e
   a média de quadros por segundo de cada minigame (tipo `desempenho`). Menos
   de 55 no mínimo é um aviso na prancha.
7. **A verdade da imagem é a máquina do André.** Na nuvem, a prova visual
   confere **disposição** (texto, tela parada, fim, relógio). A **aparência**
   (luz, cor, brilho, névoa, a arte do [11](11-arte-e-personagens.md)) só se
   aprova pela prova visual rodada na máquina do André, com placa de vídeo,
   sem `--fixed-fps`.
8. **O diário do André.** Quando o André joga, ele anota o que viu num
   formato curto que casa com o vídeo e a linha do tempo: a hora, o minigame,
   o que viu. Cada linha do diário vira um item na ficha ou uma ficha nova.
9. **Nenhuma ficha visual fecha só com fotos.** Tela, arte, câmera, HUD e
   minigame só ficam **feito** depois da prova visual e da prancha olhada.

## As decisões comuns dos minigames — H08

Escritas depois das 45 fichas, para que todas falem a mesma língua. A
[H08](tarefas/H08-os-acrescimos-do-kit.md) as constrói; toda ficha de
minigame depende dela.

**O fim conta em tempo de música.** Com faixa, a `duracao` da FICHA é medida
em `Ritmo.t_musica()` desde o início do jogo valendo; sem faixa, pelo relógio
de parede. Nunca em `t_fase` (tempo de jogo), que com `--fixed-fps 60` corre
cerca de 16 vezes mais depressa e faria o minigame acabar antes do pico — o
que fere a [paridade](#a-paridade-entre-a-prova-e-o-jogo--f08). Por isso
**nenhum minigame usa `"duracao": 0.0` como remendo**: `0.0` só vale para o
fim que é do próprio jogo (os medleys, o último em pé). E `duracao *
ritmo_nivel` nunca passa de 120 s.

**O custo, assumido:** 90 s de minigame são 90 s de verdade na prova. A prova
rápida da sessão (`SALA=<slot> bash tests/prova_do_jogo.sh`) roda o percurso
(que força o fim de cada minigame, para caber no tempo) e o minigame da ficha
inteiro; os 45 inteiros rodam no gauntlet e na prova visual, na máquina do
André.

**Os eventos do jogo:**

| tipo | o que é |
| --- | --- |
| `entrada` | o que o jogador fez: o toque cru (já existe hoje, `godot/scripts/salas/centelha.gd:286`) |
| `jogo` | o que o minigame fez no mundo: `slot`, `o` (o nome da coisa), valores |
| `pista` | a pista que o minigame deu a um jogador, por qual canal (`haptica`, `alto_falante`, `rumble`, `tela`, `tv`) |
| `troca` | o minigame trocou de canal por falta de recurso: `de`, `para` (`giroscopio` → `analogico`, `haptica` → `rumble`, `alto_falante` → `rumble`, `alto_falante` → `tv`, `microfone` → `sem_microfone`, `touchpad` → `botoes`) |
| `voz` | o nível do microfone e o limiar, nos minigames de voz |
| `estacao` | o trecho de um medley que começou ou acabou |

**O sorteio dos 45.** `Catalogo.sortear(apelido: String, semente: int, vez: int) -> String`
devolve o slot de um dos cinco da seção, sem repetir até os cinco saírem. A
`Partida` guarda **slots**, não apelidos; `Partida.NA_ORDEM` inclui o Canto.
O portão da seção no salão abre o próximo minigame da seção que ainda não se
jogou na noite.

**A fila de notas, no kit.** O que as 45 fichas repetiam vira do kit:

```gdscript
const BATIDA_DA_PRIMEIRA_NOTA := 4      # as quatro primeiras são a contagem de entrada
const FOLGA_PERDIDA := 0.140            # depois disso, a nota passou
func proxima_batida(l: int, desde: float, passo: float, desloc := 0.0) -> float   # o hoqueto: a vez do lugar
func casar_toque(l: int) -> int         # o n da nota em aberto mais perto do toque de agora (-1: nenhuma)
func notas_perdidas(l: int) -> Array    # as que passaram de FOLGA_PERDIDA sem toque; chama nota_perdida
func no_pico() -> bool                  # o terço do meio da duração
func andamento() -> float               # 0..1 da duração (não `progresso`: esse já é a linha de texto do painel)
```

**O ícone** da FICHA é o nome da **parte do controle** (`botoes`,
`analogicos`, `gatilhos`, `giroscopio`, `touchpad`, `vibracao`,
`gatilho_adaptativo`, `alto_falante`, `haptica`, `microfone`). O kit traduz
por `ICONE_DA_PARTE` para os desenhos de `godot/assets/glifos/` (que
`Desenho.glifo` carrega) e copia para `SalaJogo.icone`. Os nomes de
`ui/glifo.gd` são outros (`cruz`, `circulo`…) e não servem aqui.

**A barra de luz reage no kit.** No `_reagir` do kit: o perfeito pisca branco
por 0,15 s; o erro escurece a cor do lugar para 30% por 0,5 s. `Forja.piscar(l,
cor, s)` (no máximo 0,5 s) e `Forja.luz(l, cor)` com piso de 30% de brilho.
Depois do piscar, a barra volta à **luz de repouso**: o gancho
`luz_de_repouso(l) -> Color` do kit, que por padrão é a cor do lugar e que o
minigame sobrescreve quando a barra carrega estado (a vida no Cerco e na
Prensa, os 30% do terror, o silêncio do Zero Absoluto) — sempre a cor do
lugar, só com o brilho mudado, nunca abaixo de 30%. Nenhuma ficha "repõe o
brilho depois" à mão.

**Coop e dupla no fechamento.**
- Coop: o `vencedor` é −1 (todos venceram ou todos perderam), e a prova
  aceita −1 quando o gênero é `coop`. O destaque (quem jogou melhor) sai de
  `destaque() -> int`. A tela diz "Todos venceram!" ou "A forja apagou.".
- 2v2: as equipes são **A Brasa** (âmbar `#e8a33c`) e **A Maré** (turquesa
  `#2fb3b3`) — longe do azul do P1 e do vermelho do P2. A cor da equipe vai
  no chão e na armadura, nunca na barra de luz. Os pontos da equipe vão para
  os dois da dupla, e a tela diz "A Brasa venceu!". Com 3 jogadores, o
  terceiro entra como **o Aprendiz**, pela tabela fixa de
  [Q](tarefas/Q-a-prova.md); com 1, joga contra o robô de treino.
- `coop` sai do gênero da FICHA; ninguém põe `coop = true` à mão.
- No 2v2, `marcar_equipe` dá os pontos aos dois da dupla, e o `destaque()`
  sai dos **acertos individuais** (`acertos[l]`), não dos pontos — assim ele
  separa quem jogou melhor dentro da equipe.
- Na Prova com `--bancada`, as perguntas vêm depois do apito: elas não
  contam no tempo do minigame (ressalva na [Q1](tarefas/Q1-a-prova.md)).

**As chaves opcionais novas da FICHA:**

| chave | o que é | sem ela |
| --- | --- | --- |
| `nota_no_falante` | `false`: o kit não toca a nota do perfeito no alto-falante (quando o alto-falante é a pista) | toca |
| `textura_no_acerto` | `false`: o kit não toca a textura na háptica no acerto (quando a háptica é a pista) | toca |
| `papel_som` | o papel de som que o minigame abre (`Forja.PAPEL_*`) | o alto-falante |

**O que mais o kit aplica:** `Itens.pontos_do_acerto` no `julgar_toque`
(nenhuma ficha aplica de novo). **O que mais o `Forja` ganha:**
`Forja.textura(l, material)` (só a háptica, sem o alto-falante), as
sensações leves de um lado `"toque_esq": [0.4, 0.0, 80]` e
`"toque_dir": [0.0, 0.4, 80]`, `Forja.som_virtual(l)` devolvendo também o
nome do último som (para o robô ouvir a altura), e `Ritmo.calar(batidas)`
(a música cala por N batidas e o relógio segue — o Zero Absoluto).

**Os nomes do kit** (H08): `nova_nota(l, n, t_alvo, perigo)`, `julgar_nota`,
`anotar(tipo, l, campos)` para os seis eventos do jogo, e
`tempo_jogado()`, `tempo_acabou()`, `tempo_que_resta()` para o fim em tempo
de música.

**Na prova:** `_joga_o_minigame(slot, limite_s, a_cada_quadro)` em
`godot/testes/prova_do_jogo.gd`, que abre o minigame por `--sala=<slot>`,
espera pelo relógio de parede e chama a checagem a cada quadro. O n.º1 de
cada seção sobrescreve `dar_vereditos` e `pergunta` para a bancada (o molde
diz como).

**A medir na bancada** (valores provisórios nas fichas da S08):
`LATENCIA_MIC` 0,08 s, `LATENCIA_FIM` 0,12 s, `MARGEM_AR` 0,12 s, e se a
háptica chega com o papel de som do microfone aberto.

## Os limites conhecidos

- **O toque tem a resolução do quadro** (16,7 ms a 60 fps). O SDL já guarda o
  instante de cada aperto (`b_quando` em `nativo/nucleo/pads.c:377`); uma
  ficha futura expõe `Forja.apertou_ha(l, botao)` para julgar pelo instante
  do aperto, não pelo quadro.
- **Nomes em C:** o tipo C da háptica por material se chama `MaterialHaptico`,
  porque `Material` colide com o `godot::Material` do godot-cpp.
- **`pads_mudaram` também dispara na entrada do lobby:** refazer a placa de
  áudio ali corta o pio (medido); a placa só se refaz depois de ver o
  controle cair (H07).

## Como uma ficha prova o que fez

| o que mudou | a prova |
| --- | --- |
| GDScript de sala ou minigame | uma checagem nova em `godot/testes/prova_do_jogo.gd` (o padrão `_esperar(cond, "mensagem")`) e `bash tests/prova_do_jogo.sh` |
| C do núcleo ou do som | um teste em `nativo/testes/` e `scripts/compilar.sh testes`, mais a prova do jogo |
| tela | `bash tests/telas.sh` (com o André, local) e as fotos na ficha |
| sensação no controle | o André, com o controle na mão |

Uma ficha termina com a prova rápida passando na sessão. O que só a mão e o
ouvido provam fica listado para o André.
