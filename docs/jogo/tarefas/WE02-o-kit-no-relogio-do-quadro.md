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

## O que foi feito (leva 1, a-caixa)

- **`godot/scripts/forja.gd`:** `Forja.acelerada()` (o módulo, `--simular` e `--acelerado`, a mesma condição do
  `ctl.acelerar(true)`) e `Forja.agora_us()` (o `_agora` em µs).
- **`godot/scripts/ritmo.gd`:** o `_agora_us()` único, e as cinco chamadas passam por ele. Na sessão acelerada é o
  tempo do jogo e o `_medir` não lê a posição da faixa; quando a base troca, o relógio segue do ponto em que estava. A
  `pausar` refaz a base também no tempo do jogo. O `Ritmo.pelo_relogio_de_verdade` desliga o tempo do jogo enquanto a
  prova do relógio mede (a armadilha: a escolha foi desligar, não pular a prova).
- **`tests/prova_do_jogo.sh` e `scripts/gauntlet.sh`:** `--acelerado` nas duas rodadas da prova e no `rodar` do
  gauntlet. Todas jogam o kit, e o registro de cada uma confere os julgamentos dele. Com o kit pulado numa rodada, o
  registro dela reprova. Com os prazos em quadros e o relógio de parede, o kit do gauntlet não acaba a tempo.
- **`godot/testes/prova_do_jogo.gd`:**
  - os prazos do kit em quadros (300, 1200, 48 e 2400);
  - a régua `_julgamento_basta` (o piso de 70% e o esperado maior que cada um dos outros), com os dois casos na própria
    prova;
  - a prova do relógio liga o `pelo_relogio_de_verdade` enquanto mede e espera três quadros antes de medir;
  - no registro v2, a linha `sessao/relogio` recomeça a conta do «t nunca anda para trás»;
  - na sessão acelerada, o «processo» é o tempo do jogo com 0,5% de folga, porque o `t` do módulo é um `float` que
    deriva (a [WE06](WE06-a-linha-do-tempo-de-parede-com-prova.md)).
- **`godot/testes/minigame_de_prova.gd`:** o robô aperta quando o quadro do julgamento passa da mira
  (`t_musica() + dt`), não quando o quadro dele passa. A `MIRA` e as janelas são as mesmas.
- **A H04:** o «Cuidado conhecido» aponta para esta ficha.

**O que a medida mostrou além da ficha:**

- **O robô.** No relógio do quadro, o toque é julgado um quadro depois do aperto, e o aperto já sai até um quadro
  depois da mira. O desvio fica entre a mira mais 16,7 ms e a mira mais 33,3 ms, e os 25 ms de folga do P2 e do P3 só
  cabem em metade das fases da batida contra o quadro. A fase vem do `get_time_to_next_mix()` do `tocar`, de parede,
  e muda a cada rodada. Medido no registro de duas rodadas vermelhas: o P2 em −43,5 ms (passa) numa e em −34,9 ms (o
  PERFEITO, reprova) na outra, igual nas 12 notas. Com o robô mirando o quadro do julgamento, o desvio fica entre a
  mira e a mira mais um quadro em qualquer fase: o P2 em −51,0 e −64,1 ms, o P3 em −101,0 e −114,1 ms.
- **A prova do relógio.** O primeiro quadro da cena leva de 0,3 s a 0,5 s de parede com a máquina calma e chegou a
  10 s com ela ocupada. Ele caía dentro da janela de 0,8 s do «relógio sem faixa» («andou 11,084 s em 0,8 s» e
  «andou 10,190 s», as duas na rodada «forma-a»). A prova agora espera três quadros antes de medir; a faixa de 30% é
  a mesma.

**Provas:**

- `bash tests/prova_do_jogo.sh` verde pelo semáforo (carga 5,2 a 4,0).
- **O gauntlet curto**, o `scripts/gauntlet.sh` de verdade com a lista de defeitos trocada:
  - com `engasga`, `troca-cruz-circulo` e `haptica-muda`, os três foram pegos, cada um pela sua conferência;
  - a rodada limpa reprovou só no «o t é o relógio de parede (1465.5 s na linha, 1465.0 s de processo)»;
  - com a folga de 0,5%, a rodada limpa passou (687 conferências).
- **A máquina ocupada de propósito:** quatro laços presos aos núcleos 2 e 3 com `taskset`, o Godot preso aos mesmos,
  pelo semáforo, na rodada «antes».
  - Com a cura, verde, com a carga de 3,8 a 8,7: P1 12 de 12 perfeito, P2 12 de 12 ótimo, P3 11 de 12 bom (a nota do
    cabo fora é erro), P4 12 de 12 erro, e «o minigame acabou pelo próprio jogo (6,2 s)».
  - Sem `--acelerado` e com o piso de 70%, vermelha, com a carga de 8,7 a 9,1: «acabou (40,0 s)», a contagem de entrada,
    o apito e os quatro «kit P» (8 de 10, 8 de 10, 8 de 9).
- **A régua:** `[0, 6, 6, 0]` reprova e `[0, 2, 10, 0]` passa para o ÓTIMO, nas duas rodadas.
- **A mordida do robô:** sem a troca no `robo`, uma das duas rodadas da prova calma reprovou o P2 (12 de 12 no
  PERFEITO) e o P3 (11 de 12 no ÓTIMO).

**A validar por ela:**

- O robô que mira o quadro do julgamento. A ficha proíbe mudar a `MIRA` e as janelas, e isso não mudou; mas a ficha
  não previa que o relógio do quadro deixasse o P2 e o P3 na sorte da fase.
- O «relógio de verdade» desligado só durante a prova do relógio, em vez de rodar a prova só sem `--acelerado`.
- A espera de três quadros antes da prova do relógio.
- O `--acelerado` também no gauntlet, e a folga de 0,5% no «o t é o relógio de parede». Nenhuma prova roda mais a
  linha do tempo no relógio de parede; a [WE06](WE06-a-linha-do-tempo-de-parede-com-prova.md) devolve essa prova.

**Fica para a mão (o André):** rodar `bash tests/prova_do_jogo.sh` com um jogo aberto ao lado e conferir que o kit
passa com o piso de 70%.

**Fica de fora:** o gauntlet inteiro, com os 20 defeitos (uns 90 min), não foi rodado. A linha do tempo de parede sem
prova e o `t` do módulo em `float` estão na [WE06](WE06-a-linha-do-tempo-de-parede-com-prova.md).
