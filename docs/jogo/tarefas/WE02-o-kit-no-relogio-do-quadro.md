# WE02 — A prova do kit no relógio do quadro

**Sprint:** W · **Tamanho:** M · **Depende de:** — (vai antes da [V02](V02-a-prova-do-jogo-em-partes.md) e da
[X03](X03-o-pacote-do-ritmo.md), que mudam de lugar os dois arquivos; se elas forem antes, a cura vai para a casa
nova)

## Por quê

A prova do kit afrouxou a régua do julgamento para passar com a máquina carregada. Era «70% das notas no julgamento
esperado» e virou «o julgamento esperado é o mais frequente», que aceita empate e aceita acertar só um terço. A
causa não é o kit: a prova mede o `Ritmo`, que corre no relógio de parede, com um robô que aperta por quadro. Com a
máquina carregada, um quadro passa dos 25 ms de folga, e o mesmo toque muda de julgamento.

## Ler antes

- [H04 — O kit do minigame](H04-o-kit-do-minigame.md) («Espera por fase em quadros, por música em relógio» e o
  «Cuidado conhecido»)
- [godot/scripts/ritmo.gd](../../../godot/scripts/ritmo.gd) (o `_medir`)
- [godot/testes/minigame_de_prova.gd](../../../godot/testes/minigame_de_prova.gd) (a `MIRA` e o `robo`)

## O estado de hoje

- O commit `c2ff3cc` trocou, em `godot/testes/prova_do_jogo.gd:486`:

  ```gdscript
  -		_esperar(total == mg.NOTAS and certos * 10 >= total * 7,
  +		_esperar(total == mg.NOTAS and certos == c.max(),
  ```

  Com doze notas, `[0, 6, 6, 0]` passa para o ÓTIMO, e `[3, 4, 3, 2]` passa com 4 de 12.
- O robô mira `MIRA := [0.0, -0.065, -0.115, NUNCA]` (`minigame_de_prova.gd:32`) e aperta no quadro em que
  `Ritmo.t_musica() >= t_da_batida(n) + mira` (`:105`). O toque é julgado no quadro seguinte, com
  `var t_toque := Ritmo.t_musica()` (`godot/scripts/minigames/minigame.gd:228`). Entre a mira e a borda da janela
  há 25 ms: o P2 mira −65 e o PERFEITO começa em −40; o P3 mira −115 e o ÓTIMO acaba em −90.
- O `Ritmo._medir` (`ritmo.gd:133-146`) anda por `Time.get_ticks_usec()` ou pela posição da faixa, que no driver
  mudo também anda no tempo de parede. Com `--fixed-fps 60` sem janela, o quadro não tem duração fixa: com a
  máquina livre ele leva ~1 ms, e com ela carregada passa dos 25 ms.
- Os prazos da prova do kit também são de parede: `Time.get_ticks_usec() - t_conta < 5000000` (`:452`, `:455`),
  `< 20000000` (`:460`), `< 40000000` (`:472`).
- O `--acelerado` já existe para a linha do tempo (`godot/scripts/forja.gd:29` e `:137`, e
  `nativo/godot/forja_controles.cpp:566`), mas o `Ritmo` não o lê, e nenhuma prova o passa.
- A H04 registrou o defeito como «Cuidado conhecido: rode com a máquina calma», sem ficha.

## O alvo

Na sessão com `--simular` e `--acelerado`, o `Ritmo` mede o tempo do jogo, que o `Forja` já soma a cada quadro
(`_agora`, `forja.gd:512` e `:245`), nos dois caminhos (com faixa e sem faixa). A prova do kit roda assim, conta os prazos em
quadros, e a régua volta ao piso de 70%, sem empate.

## Passos

1. No `Ritmo`, um `_agora_us()` único: o tempo do jogo quando o `Forja` diz que a sessão é acelerada, o
   `Time.get_ticks_usec()` quando não. As cinco chamadas de `ritmo.gd` (`:41`, `:79`, `:89`, `:101`, `:136`) passam
   por ele. Com a sessão acelerada, o `_medir` não lê a posição da faixa.
2. O `Forja` expõe se a sessão é acelerada (a mesma condição de `forja.gd:137`).
3. `tests/prova_do_jogo.sh` passa `--acelerado` na rodada que tem a prova do kit.
4. Na `_prova_do_kit`, os três prazos viram quadros (5 s = 300 quadros, e assim por diante), e a régua vira uma
   função pura `_julgamento_basta(contagem, esperado) -> bool`: piso de 70% e o esperado maior que cada um dos
   outros.
5. Um caso da função na própria prova: `[0, 6, 6, 0]` com o ÓTIMO esperado reprova, `[0, 2, 10, 0]` passa.

## Armadilhas

- A `_prova_do_relogio` (`prova_do_jogo.gd:897`) confere justamente o relógio pela placa. Na rodada acelerada ela
  tem de desligar o modo do jogo enquanto mede, ou rodar só na rodada sem `--acelerado`. Escolher uma das duas e
  escrever qual.
- O `--acelerado` muda o `t` da linha do tempo para o tempo do jogo. Rodar a prova inteira com ele antes de mexer
  no `Ritmo`, para separar o que muda só pela linha do tempo.
- A regra de [04 — O relógio de áudio](../04-ritmo-e-audio.md) («ninguém soma delta para saber o tempo da música»)
  continua valendo no jogo. O tempo do jogo entra só na sessão acelerada, que só existe com `--simular`.
- Não tocar no kit (`minigame.gd`): a H04 proíbe caminho de prova nele, e a cura está no relógio.

## Não fazer

- Não manter a régua da maioria nem afrouxar o piso de 70%.
- Não mudar as janelas de julgamento nem a `MIRA` do robô para caber no quadro.

## Pronto quando

A régua do kit é o piso de 70% sem empate, e a prova do kit passa com a máquina ocupada de propósito.

## Provas

- `bash tests/prova_do_jogo.sh` verde.
- Com a máquina ocupada de propósito (quatro laços ocupados presos aos mesmos núcleos com `taskset`, pelo semáforo da
  máquina), a prova do kit com o piso antigo e sem `--acelerado` reprova; com a cura, passa.
- O caso `[0, 6, 6, 0]` reprova na função nova.

## Para o André (local)

Rodar `bash tests/prova_do_jogo.sh` com um jogo aberto ao lado e conferir que o kit passa com o piso de 70%.

## Ao terminar

Pôr a linha da WE02 no [quadro](README.md) como **feito**, com o commit, e trocar o «Cuidado conhecido» da
[H04](H04-o-kit-do-minigame.md) por um apontador para esta ficha.
