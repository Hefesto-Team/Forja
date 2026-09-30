# F09 — A prova visual

**Sprint:** F · **Tamanho:** G · **Estimativa:** US$ 4,0 · **Depende de:** F00, F02 (a coleta de texto), F03 (o fim), F08 (o robô só pelo controle)

## Por quê

Na primeira noite, as fotos e os GIFs mostravam tudo certo, e a partida
jogada mostrou erros grosseiros. A prova visual passa a ver o que o jogador
vê: a partida inteira, pelo caminho de verdade, com o robô errando, e com
checagens automáticas sobre todos os quadros — não só sobre fotos escolhidas.

## Ler antes

- [A arquitetura — a prova visual](../13-arquitetura.md#a-prova-visual--f09)
- [A arquitetura — a paridade](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08)

## O estado de hoje

- `godot/testes/captura_jogo.gd` abre `res://scenes/main.tscn` com quatro
  controles simulados e fotografa momentos escolhidos por roteiro
  (`ROTEIRO=salas|bancada|partida`, `FOTOS=`, `SALAS=`), com `RAPIDO=1`
  encolhendo a janela entre as fotos e `SEM_TREMOR=1` tirando o tremor.
- `godot/scripts/main.gd:156-200` (`_abrir_pelos_args`): `--sala=`,
  `--tela=`, `--partida=` e `--prova-de-fogo` chamam `_todos_entram()`
  (todos entram por código) e pulam o título e o lobby.
- `scripts/trailer.sh` grava com `--write-movie` o mesmo roteiro de
  `captura_jogo.gd`.
- `tests/telas.sh` tira as fotos e compara pastas.
- O simulador já sabe tirar e pôr o cabo: `ctl.simulador_cabo(...)`
  (`nativo/godot/`), além de `simulador_botao`, `_eixo`, `_giro`, `_dedo`,
  `_falar`.
- Na nuvem **não há** `ffmpeg` nem Pillow. O Godot tem tudo o que falta:
  `get_viewport().get_texture().get_image()`, `Image.blit_rect`,
  `Image.save_png`.

## O alvo

Um roteiro novo, `godot/testes/prova_visual.gd` (+ `.tscn`), e um script
`tests/prova_visual.sh` que:

1. roda **quatro partidas** pelo fluxo de verdade, começando no título, cada
   jogador entrando pelo ✕ do seu controle simulado:
   - quatro jogadores, `--robo=bom`, partida de 5;
   - quatro jogadores, `--robo=ruim`, partida de 5;
   - dois jogadores, `--robo=medio`, partida de 3;
   - um jogador, `--robo=medio`, partida de 3, com o controle desconectando
     no meio do segundo minigame (`simulador_cabo`) e voltando no terceiro;
2. a cada 2 s de jogo guarda um quadro (PNG pequeno, 480×270) com a hora;
3. no fim de cada partida monta a **prancha**: uma grade de 6 colunas com
   todos os quadros e a hora embaixo de cada um, em `SAIDA/prancha-<n>.png`;
4. roda as **checagens** sobre todos os quadros e sobre a linha do tempo e
   escreve `SAIDA/checagens.txt` — e sai com erro se alguma reprovou.

## Passos

1. **Os temperamentos do robô.** Em `godot/scripts/forja.gd`, `--robo`
   aceita `=bom|medio|ruim` (sem valor: `bom`). `Forja.robo` continua `bool`;
   `Forja.robo_acerta() -> bool` sorteia pela semente (bom 95%, médio 66%,
   ruim 30%) e o `_robo` de cada sala passa a consultá-la antes de apertar
   no tempo certo (quando não acerta, aperta atrasado ou não aperta). Só o
   gancho do robô muda.
2. **Entrar pelo ✕.** O roteiro não usa `--sala=` nem `--tela=`. Com
   `--robo`, quem aperta do título à construção é o robô do fluxo
   (`main._robo`, `TelaLobby.robo`, da G01/G02), pelo controle simulado; o
   roteiro **só observa** — um ✕ a mais do roteiro pularia a introdução.
   Antes da G01, o roteiro aperta ✕ no controle simulado de cada lugar, com
   intervalo, como um jogador.
3. **Os quadros.** A cada 2 s de `t` do jogo, `get_viewport().get_texture().get_image()`,
   `resize(480, 270)`, guardar em memória com a hora e o estado de
   `main.gd` (`estado`, `sala_id`).
4. **A prancha.** `Image.create(6 * 480, linhas * 290, false, FORMAT_RGB8)`,
   `blit_rect` de cada quadro, e a hora escrita embaixo (um `Label` num
   `SubViewport`, ou pixels de um dígito desenhado — o que for mais simples;
   a prancha é para olho humano).
5. **As checagens** (`godot/testes/checagens_visuais.gd`, `class_name ChecagensVisuais`):
   - `tela_parada(quadros)`: dois quadros seguidos com diferença média de
     pixel abaixo de 0,5% por mais de 5 s, fora de `pausa`;
   - `tela_vazia(quadro)`: mais de 97% dos pixels a menos de 8 níveis da
     mesma cor;
   - `texto(frases)`: pela coleta de `Desenho` (F02), com o retângulo de cada
     frase: sobreposição entre dois retângulos, retângulo fora da área segura
     (5% de cada borda) e altura de fonte abaixo de 30 px;
   - `relogio_sobe(linha_do_tempo)`: o relógio do minigame nunca aumenta
     durante a fase `jogo`;
   - `fim_sem_vencedor(linha_do_tempo)`: todo `minigame` `terminou` tem
     `vencedor`;
   - `minuscula(frases)`: frase de tela começando com minúscula.
6. **O quadro por segundo.** Em `godot/scripts/salas/sala_jogo.gd`, medir o
   `Engine.get_frames_per_second()` na fase `jogo` e gravar ao terminar
   `Forja.evento("desempenho", 0, {"slot": id, "fps_min": ..., "fps_media": ...})`.
   A checagem só **avisa** (não reprova) abaixo de 55, porque na nuvem o
   renderizador é por software.
7. **`tests/prova_visual.sh`**: roda as quatro partidas **sem**
   `--fixed-fps` e **com** `--fixed-fps 60` (duas passadas), com a
   `SAIDA` numa pasta temporária por padrão ou na pasta pedida, e imprime o
   resumo das checagens.
8. Aposentar os atalhos de foto: `captura_jogo.gd` continua para as fotos de
   divulgação, mas `tests/telas.sh` passa a chamar a prova visual. Documentar
   em `docs/DESENVOLVER.md` e em `AGENTS.md` (os comandos).

## Armadilhas

- `get_image()` num Godot `--headless` devolve imagem vazia: a prova visual
  roda **com** janela (na nuvem, o Godot sem `--headless` usa o renderizador
  por software; se não abrir, rodar dentro de `xvfb-run`, instalado pela
  F00). Conferir antes de escrever o resto.
- Sem `--fixed-fps`, a partida dura o tempo real: quatro partidas levam uns
  15 minutos. A passada com `--fixed-fps 60` é a que roda na sessão; a sem
  é a do André.
- A semente fixa (`--semente=7`) tem de dar o mesmo resultado nas duas
  passadas; se não der, é bug de jogo, não da prova.
- Guardar os quadros em memória a 480×270 ocupa pouco (cerca de 400 kB por
  quadro em RGB8); não gravar PNG cheio a cada 2 s.
- A coleta de texto da F02 precisa guardar o retângulo, não só a frase; se
  a F02 não guardou, acrescentar lá.

## Não fazer

- Não aprovar aparência (luz, cor, brilho, arte) pela prancha da nuvem: o
  renderizador por software não é a placa de vídeo. A aparência é do André.
- Não trocar o jogo para a prova passar.

## Pronto quando

`bash tests/prova_visual.sh` roda as quatro partidas pelo fluxo de verdade,
gera as quatro pranchas e as checagens, e uma falha plantada de propósito
(um texto encavalado, um relógio que sobe, um minigame sem vencedor) é
reprovada — e depois tirada.

## Provas

- Na sessão: `bash tests/prova_visual.sh` (passada com `--fixed-fps 60`) e
  as três falhas plantadas.
- Com o André, local: `bash tests/prova_visual.sh` sem `--fixed-fps`, com
  placa de vídeo; olhar as quatro pranchas.

## Para o André (local)

Rodar a prova visual, abrir as pranchas e anotar no diário (hora, minigame,
o que viu) tudo o que parecer errado — inclusive a aparência. A partir
daqui, toda ficha de tela, arte, câmera, HUD ou minigame só fecha com a
prancha olhada.

## Ao terminar

Marcar F09 como **feito** no [quadro](README.md), com o gasto. Commit
sugerido: `feat: a prova visual — a partida inteira, o robô que erra, a prancha e as checagens de cada quadro`.
