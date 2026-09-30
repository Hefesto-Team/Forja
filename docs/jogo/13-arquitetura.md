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
    main.gd                a máquina de estados: titulo, lobby, salao, sala, podio (+ overlays)
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
    mundo/efeitos.gd       Efeitos: faíscas, brasas, poeira
    mundo/salao.gd         Salao: o hub, os portões
    ui/*.gd                as telas e o HUD, todos desenhados em _draw()
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
- **Nada de caminho fixo e nada de endereço de aparelho** no código, no registro ou no relatório (regra do [AGENTS](../../AGENTS.md)).
- **Toda saída ao controle passa pelo `Forja`**, por lugar. Nenhuma sala fala com o `Forja.ctl` direto.
- **A dica de botão** é `Glifo.dica(..., com_botao := true)`: escreve "Botão ✕ (Ação)" (F07). O ícone da parte do controle usada vive em `SalaJogo.icone` (F02) e, nos minigames, em `FICHA.icone`.
- **A coleta de texto para a prova:** `Desenho._coletar = "memoria"` guarda cada frase desenhada, para a prova conferir o que a tela mostrou (F02).
- **O texto que vem do núcleo em C** (o porquê dos vereditos, os experimentos) fica fora da regra de maiúscula por enquanto: só aparece no Modo bancada.
- **O que não se sabe, não se inventa:** se o comportamento do SDL, do Godot ou do controle não está na ficha nem aqui, a sessão mede ou para e anota.

## O ambiente de uma sessão

Hoje uma sessão nova na nuvem começa sem o Godot e sem o módulo. A ficha
[F00](tarefas/F00-o-ambiente-da-sessao.md) põe um gancho de início de sessão
que deixa tudo pronto. Até ela existir, os passos são:

```bash
scripts/compilar.sh linux                    # o módulo (SDL3 + godot-cpp); a primeira vez baixa e compila
mkdir -p tools && curl -fsSL -o /tmp/g.zip \
  https://github.com/godotengine/godot/releases/download/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64.zip \
  && unzip -o -q /tmp/g.zip -d tools
bash tests/prova_do_jogo.sh                  # a prova rápida
```

Nunca rode `./run-local.sh` numa sessão da nuvem: ele abre a janela do jogo
no fim.

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
[05](05-haptica-e-controle.md#o-piso-de-força).

### O registro v2 — F06, H01, H02, G02, H07

**Hoje:** `linha-do-tempo-<sessão>.jsonl`, formato
`hefesto-tech-demo/linha-do-tempo/1` (`nativo/nucleo/linha_tempo.h:11`),
uma linha por evento com `t`, `tipo`, `jogador` (1..4, 0 = a mesa). O `t`
hoje é **sempre** o tempo do jogo: `relogio_do_jogo(&f->t)` é chamado
incondicionalmente em `nativo/nucleo/forja.c:179`, e o comentário de
`nativo/nucleo/relogio.h` (que fala num `--acelerado`) está errado — esse
argumento não existe. Os `Array` vindos do GDScript em `Forja.evento` hoje
são gravados como texto.

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
- `Array` do GDScript vira array JSON.

Os tipos, e quem os escreve:

| tipo | campos | quem |
| --- | --- | --- |
| `conexao` | `transporte` (`"usb"`, `"bt"`, `"virtual"` para o simulado, `"desconhecido"`), `firmware` (ex.: `"0x0224"`), `rumble_escala_cheia` (se o SDL manda o rumble sem o corte pela metade), `vid_pid`; `"evento": "reservou"` quando o lugar é dado na conexão (F04) | F05 (firmware), F06 (o resto), F04 (reserva) |
| `saida` | `seq` (por lugar, cresce, nunca repete), `o` (`vibracao`, `gatilho`, `lightbar`, `leds_jogador`, `player_index`, `led_microfone`, `audio_hid`), os valores, `ok` | F06 (C) |
| `som_controle` | `seq`, `papel` (`alto_falante`/`haptica`), `som`, `ganho`, `placa` (`true`/`false`) | H07 (C) |
| `sensacao` | `nome` (da tabela de sensações), `escala`, `ms` | F05 |
| `minigame` | `slot`, `evento` (`comecou`/`terminou`), `vencedor` (o lugar 0..3, ou -1 no coop), `pontos`, `itens`, `duracao` | F03 |
| `nota` | `slot`, `n` (índice), `t_alvo` (em tempo de música) | H01 |
| `toque` | `slot`, `n`, `desvio_ms`, `julgamento` (`perfeito`/`otimo`/`bom`/`erro`) | H02 |
| `calibracao` | `desvio_ms`, `amostras` | G02 |
| `item` | `item`, `efeito` | G03 |
| `sessao` | amplia o de hoje com `escala_vibracao` e `gatilho` de cada lugar | F05 |

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
func julgar(l: int, t_toque: float, t_alvo: float, folga_bom := 0.0) -> int
var desvio := [0.0, 0.0, 0.0, 0.0]   # a calibração de cada lugar, em s (G02/H03)
```

`julgar` subtrai o `desvio[l]` do toque antes de comparar. A `folga_bom` é
a ajuda escondida de quem está em último ([02](02-principios.md#8-ninguém-fica-para-trás-ninguém-é-punido-por-ser-bom)).
Sem faixa tocando, `t_musica()` anda pelo relógio do sistema, para as
provas sem som.

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

**O que o kit faz** (e o minigame não repete):

| o kit | como |
| --- | --- |
| as raias | `raia(l) -> Node3D` monta a laje, a borda na cor do lugar e a luz da vez em `RAIAS[l]`; `posicionar(l)` põe o boneco nela |
| quem está conectado | `conectado(l) -> bool` |
| o relógio | `Ritmo.tocar(...)` com a faixa da ficha na fase `jogo` |
| o julgamento | `julgar_toque(l, t_alvo) -> int`: chama `Ritmo.julgar`, aplica o item (G03), grava o `toque`, chama `sentir` e o som da nota |
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
hoje não quebrarem.

**Onde mora cada minigame:** `godot/scripts/minigames/sNN/<nome>.gd`. As
nove salas de hoje se mudam para lá quando são reescritas (ficha da seção),
e a sala antiga sai de `godot/scripts/salas/`.

### O item — G03

**Hoje:** `player.gd` tem `ITENS` (mãos livres, espada, lança, espada e
escudo, lança e escudo, poção, chave), só visual.

**Alvo:** `godot/scripts/itens.gd` (`class_name Itens`, estático):

```gdscript
enum { NENHUM, MARTELO, ESCUDO, FOLE, LANTERNA, DIAPASAO, ANCORA }
static func do_lugar(l: int) -> int
static func ajustar_julgamento(l: int, j: int, no_tempo_forte: bool) -> int   # Martelo
static func absorve_erro(l: int) -> bool                                     # Escudo (uma vez por minigame)
static func acertos_para_voltar_o_combo(l: int, normal: int) -> int          # Fole
static func antecipacao_s(l: int) -> float                                   # Lanterna
static func ganho_da_nota(l: int) -> float                                   # Diapasão
static func resiste_a_empurrao(l: int) -> float                              # Âncora (0..1)
static func novo_minigame() -> void                                          # repõe o Escudo
```

O item visual (`player.gd`) e o item de mecânica são o mesmo índice: a
construção do cavaleiro (G02) escolhe um dos seis, e cada um tem a peça que o
boneco leva nas costas.

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
- no Modo bancada, a tabela de veredito aparece **abaixo** do resultado.

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
   código do jogo. **Hoje há atalhos**: o aviso marca o robô como pronto sem
   ✕ (`godot/scripts/salas/sala_jogo.gd:237`), o fim da sala avança sozinho
   (`sala_jogo.gd:385`), o placar e o pódio também (`godot/scripts/main.gd:493`,
   `main.gd:873`). A F08 os troca por ✕ apertado no controle simulado.
2. **`Forja.robo` só aparece em um lugar por minigame:** no gancho `robo(l, dt)`
   (e, até o kit, na função `_robo` de cada sala). Fora disso, o jogo não
   sabe que é um robô. A prova do jogo confere isso com `grep`.
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

## Como uma ficha prova o que fez

| o que mudou | a prova |
| --- | --- |
| GDScript de sala ou minigame | uma checagem nova em `godot/testes/prova_do_jogo.gd` (o padrão `_esperar(cond, "mensagem")`) e `bash tests/prova_do_jogo.sh` |
| C do núcleo ou do som | um teste em `nativo/testes/` e `scripts/compilar.sh testes`, mais a prova do jogo |
| tela | `bash tests/telas.sh` (com o André, local) e as fotos na ficha |
| sensação no controle | o André, com o controle na mão |

Uma ficha termina com a prova rápida passando na sessão. O que só a mão e o
ouvido provam fica listado para o André.
