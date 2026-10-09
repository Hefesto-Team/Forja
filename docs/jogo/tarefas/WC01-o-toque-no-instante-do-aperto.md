# WC01 — O toque julgado no instante do aperto

**Sprint:** W · **Tamanho:** M · **Depende de:** H01, H02, H04 (feitas) e [WE02](WE02-o-kit-no-relogio-do-quadro.md)
(a prova do kit no relógio do quadro); vai antes da X03 e da X04

## Por quê

O toque é julgado pela hora do quadro em que o jogo o lê, não pela hora em que o dedo apertou. Entre uma e outra cabe
até um quadro inteiro no controle de verdade. A 60 quadros por segundo, são até 17 ms; com a máquina carregada
(quadros de 30 a 40 ms), o escorregão já tira o toque da faixa certa. É o que o
[04 — O relógio de áudio](../04-ritmo-e-audio.md#o-relógio-de-áudio) condena: «um quadro de 40 ms numa explosão
empurra o jogo para longe da música».

A calibração absorve a média (meio quadro), mas não o espalhamento: a mesma mão firme ganha um perfeito e um ótimo
seguidos só porque um aperto caiu no começo do quadro e o outro no fim. Os 45 minigames vão julgar pelo mesmo
`julgar_toque`, e cada um herda isso.

A [WE02](WE02-o-kit-no-relogio-do-quadro.md) cura a **prova** do kit (o relógio do quadro na sessão acelerada e a régua
de 70 % de volta). Esta ficha cura o **jogo**: o instante do aperto, que o módulo já tem e joga fora.

## Ler antes

- [04 — O ritmo e o áudio](../04-ritmo-e-audio.md) (o relógio e as janelas)
- [H01 — O relógio de áudio](H01-o-relogio-de-audio.md), [H02 — As janelas](H02-as-janelas.md) e
  [H04 — O kit do minigame](H04-o-kit-do-minigame.md)
- [WE02 — A prova do kit no relógio do quadro](WE02-o-kit-no-relogio-do-quadro.md)
- [13 — O relógio de áudio e o julgamento](../13-arquitetura.md#o-relógio-de-áudio-e-o-julgamento--h01-h02-h03)

## O estado de hoje (medido em 09/10/2026)

- O julgamento lê a hora do quadro, `godot/scripts/minigames/minigame.gd:227-230`:

  ```gdscript
  func julgar_toque(l: int, t_alvo: float, n := -1, perigo := false) -> int:
  	var t_toque := Ritmo.t_musica()
  	...
  	var j := Ritmo.julgar(l, t_toque, t_alvo, folga)
  ```

  O `t_musica()` (`godot/scripts/ritmo.gd:105`) é o `_t` medido uma vez por quadro, em prioridade −90
  (`ritmo.gd:39`).
- O DualSense não passa pela entrada do Godot. O módulo bombeia os eventos do SDL no `_process` dele, em −100
  (`nativo/nucleo/forja.c:211-222`, o `while (SDL_PollEvent(&e)) pads_evento(f, &e);`). Por isso o
  `Input.use_accumulated_input = false` de `ritmo.gd:40`, que o 04 pede «para cada toque chegar com o quadro dele»,
  não alcança o controle.
- O instante do aperto já existe e se perde: `nativo/nucleo/pads.c:452` guarda o carimbo do evento do SDL em
  `p->b_quando[botao]` (`pads.h:55`, «ns do último aperto»), e só a conferência do espelho o lê (`pads.c:600`).
  Nenhum método do `ForjaControles` o entrega ao jogo.
- O robô aperta no primeiro quadro depois de alvo + mira (`godot/testes/minigame_de_prova.gd:104-105`); o simulador
  agenda o aperto (`nativo/nucleo/simulador.c:333`) e o SDL o entrega no bombeamento seguinte. O toque do robô
  carrega o mesmo escorregão do quadro, somado ao quadro em que ele percebeu que passou da mira.

## O alvo

Todo toque julgado carrega o instante em que aconteceu.

- O módulo entrega, para o aperto deste quadro, há quanto tempo ele aconteceu, medido no relógio do controle no
  instante do bombeamento: `idade_do_aperto_us(lugar, botao)` (0 quando não houve aperto). No controle de verdade, a
  idade sai do carimbo do evento do SDL; no simulado, do instante que o robô pediu, no relógio do simulado
  (`pad_agora_ns`, a soma dos `dt`).
- O `Ritmo` converte a idade para o tempo da música: `t_do_aperto(l, botao)` é o `_t` do quadro menos a idade,
  nunca antes do `_t` do quadro anterior menos um quadro.
- O `julgar_toque` recebe o botão (padrão ✕) e julga pelo `t_do_aperto`, não pelo `t_musica`.
- O robô aperta «no passado»: o `robo_apertar` ganha o quanto antes do pedido o aperto aconteceu, e o minigame de
  prova pede o aperto para o instante alvo + mira, não para o quadro em que percebeu que passou.

## Arquivos que mudam

- `nativo/nucleo/pads.c`, `nativo/nucleo/pads.h`, `nativo/nucleo/simulador.c`, `nativo/nucleo/simulador.h`
- `nativo/godot/forja_controles.cpp`, `nativo/godot/forja_controles.h`
- `nativo/testes/prova_basicos.c` (ou a prova do nativo que já cobre o simulador)
- `godot/scripts/forja.gd` (o envelope e o `robo_apertar`), `godot/scripts/ritmo.gd`,
  `godot/scripts/minigames/minigame.gd`
- `godot/testes/minigame_de_prova.gd`, `godot/testes/prova_do_jogo.gd` (a `_prova_do_kit`)
- `docs/jogo/13-arquitetura.md` (a linha do relógio), `docs/jogo/04-ritmo-e-audio.md` (a frase do
  `use_accumulated_input`)

## Passos

1. No nativo: o instante do aperto que o jogo lê, sem mudar o que o espelho compara (um campo novo, ou o mesmo
   `b_quando` se a prova do espelho continuar verde). O método `idade_do_aperto_us(lugar, botao)` no
   `ForjaControles`, registrado no `_bind_methods`.
2. No simulador: o `robo_apertar` recebe o atraso em segundos e carimba o aperto com o instante do pedido menos o
   atraso, no relógio do simulado.
3. A prova do nativo: um aperto simulado com atraso de 30 ms tem idade entre 30 ms e 30 ms + um quadro; sem atraso,
   a idade é a do bombeamento.
4. `Forja.idade_do_aperto(l, botao)` (o envelope) e `Ritmo.t_do_aperto(l, botao)`.
5. O `julgar_toque` passa a usar o `t_do_aperto`. O registro do toque (`Ritmo.registrar_toque`) leva o desvio
   calculado pelo instante do aperto.
6. O minigame de prova pede o aperto com o atraso de quanto o relógio já passou de alvo + mira.
7. A prova do kit (já com a régua da WE02) ganha a régua mais dura: todo toque que o robô mirou de propósito sai com
   o desvio da mira, a 1 ms, no registro.
8. Corrigir o 13 e o 04 (de onde vem o instante do toque).

## Armadilhas

- **Dois relógios.** O carimbo do SDL é `SDL_GetTicksNS`; o `Ritmo` mede pelo `Time.get_ticks_usec`, pela placa
  ou, na sessão acelerada da WE02, pelo tempo do jogo. Não converta carimbo absoluto de um relógio para o outro:
  trabalhe com a idade (a diferença dentro do mesmo relógio), medida no bombeamento, que acontece no mesmo quadro e
  logo antes da medida do `Ritmo` (−100 contra −90).
- **O controle simulado tem relógio próprio** (`pad_agora_ns`, `pads.c:29-31`). Na sessão acelerada, ele e o tempo
  do jogo da WE02 são a mesma soma dos `dt`: a idade do aperto do robô tem de sair nesse relógio, ou a prova acelerada
  julga com um relógio e mede com outro.
- **O espelho** (`pads.c:595-606`) compara o `b_quando` de dois controles reais para achar o mesmo dedo visto por
  dois caminhos. O carimbo do simulado não pode cair nessa conta.
- **A calibração.** O desvio das opções (`tela_opcoes.gd:74`) foi ajustado com o escorregão médio dentro dele (meio
  quadro). Com a cura, quem calibrou à mão pode ver tudo meio quadro adiantado (uns 8 ms a 60 quadros): dizer isso no «O que foi feito» e não
  mexer no valor gravado de ninguém. A medida automática da [G02](G02-a-construcao-do-cavaleiro.md) (a armadura
  forjada a marteladas) tem de usar o mesmo `t_do_aperto`; se a G02 entrar antes, ela troca para ele aqui.
- **O robô com temperamento** (`--robo=ruim`) às vezes aperta por um temporizador (`forja.gd:1018-1025`): esse
  aperto não tem mira, e a idade dele é a do bombeamento.

## Não fazer

- Não somar meio quadro de compensação no `julgar`: a cura é o instante de verdade, não uma média.
- Não afrouxar a janela nem a mira do robô.
- Não mexer no `t_musica` do quadro: a nota, o pêndulo e a prensa continuam desenhados por ele.
- Não refazer a cura da WE02 (o relógio da sessão acelerada e a régua de 70 %): esta ficha parte dela.

## Pronto quando

No registro de uma partida da prova, o desvio de cada toque mirado é a mira do robô, a 1 ms, com a máquina livre e
com um atraso de quadro artificial (um nó que faz `OS.delay_usec(30000)` a cada quadro durante o minigame). Hoje,
com esse atraso, o desvio do toque mirado escorrega até dois quadros.

## Provas

- `scripts/compilar.sh testes` (a prova nova da idade do aperto) e `scripts/compilar.sh linux`.
- `bash tests/prova_do_jogo.sh` (a `_prova_do_kit` com a régua do desvio e a rodada com o atraso de quadro; a
  `_prova_das_janelas` e a `_prova_da_calibracao` seguem verdes).
- `bash tests/prova_do_som.sh`.
- A rodada com atraso é pesada: pelo semáforo da máquina.

## Para o André (local)

Com o DualSense de verdade, abrir o minigame de prova preso a 30 quadros por segundo (o `--max-fps 30` vai antes do
`--` dos argumentos do jogo) e apertar no tempo da música por um minuto, antes e depois da cura. O registro tem o
desvio de cada toque: o espalhamento (o desvio padrão dos `toque`) tem de cair com a cura, e a média tem de ficar
perto do que era, meio quadro mais cedo (uns 17 ms a 30 quadros).

## Ao terminar

Marcar WC01 como **feito** no [quadro](README.md), com o gasto, e avisar na X03 que o `t_do_aperto` vai junto para o
pacote do ritmo.
