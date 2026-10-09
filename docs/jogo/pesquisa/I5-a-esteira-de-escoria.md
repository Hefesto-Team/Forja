# I5, A Esteira de Escória: a pesquisa do DualSense

Slot S01_J05 · vez e roubo · o verbo é **prensar o lingote com o botão que ele pede**. A
[ficha](../tarefas/I5-a-esteira-de-escoria.md), a [diversão](../diversao/I-a-centelha.md) e o
[catálogo](dualsense.md#4-o-alto-falante).

## O recurso

- **Os botões ✕, ○ e □**, um por compasso, no lingote da vez.
- **O roubo.** Apertar o mesmo botão no lingote do outro até 90 ms antes do dono.
- **O emperro.** Quem rouba errado fica 2 tempos sem prensar.
- O grito: o lingote de ouro.

## O que se sabe fora

| jogo ou projeto | a técnica | a fonte |
| --- | --- | --- |
| 1-2-Switch (2017) | duelos de reflexo cara a cara, sem olhar a tela | [Looper](https://looper.com/40850/1-2-switch-includes-safe-cracking-crying-baby-simulators), [Vooks](https://vooks.net/1-2-switch-review/amp) |
| Death Stranding e Ghostwire: Tokyo | a voz e o clique saindo do alto-falante do controle | o catálogo, a mágica 2 |
| o SDL `SDL_hidapi_ps5.c` | o carimbo do sensor no relatório de entrada, a 4 ms no cabo | [SDL](https://github.com/libsdl-org/SDL/blob/main/src/joystick/hidapi/SDL_hidapi_ps5.c), zlib |

## O risco no Linux

1. **O roubo de 90 ms precisa de relógio justo.** Se o jogo julga pelo quadro, a resolução é 16,7 ms: 90 ms viram 5
   ou 6 quadros, conforme a fase. Dois jogadores com 10 ms de diferença podem cair no mesmo quadro. O catálogo diz que
   o carimbo do sensor julga a 4 ms. Medir na bancada: o carimbo do aperto contra o carimbo do quadro, em 100 apertos.
2. **4 controles no mesmo hub.** O relatório de cada um chega a 250 Hz; atrás de um hub, a ordem de chegada pode mudar
   em até 1 ms. Medir com 4 controles, `lsusb -t` e o desvio do intervalo entre relatórios.
3. **O ✕ e o ○ trocados** pelo Steam Input ou por um layout japonês. O defeito `troca-cruz-circulo` cobre isso.

## As mágicas

### 1. O roubo se ouve no controle do roubado (`usa`)

- **Quem joga:** quem é roubado ouve um «tlim» de ouro no próprio alto-falante, no quadro do roubo, e sente um puxão
  de 40 ms no motor forte, a 0,7.
- **Os outros:** a sala vê o lingote voar e ouve de que controle saiu o «tlim». Todo mundo olha para a mão do roubado.
- **Como se prova:** o robô do lugar 2 aperta o botão do lingote do lugar 1 100 ms antes do tempo;
  `Forja.som_virtual(1).falante` passa de 0,3 e `Forja.percepcao(1).forte` vai a 0,7 por 40 ms; o lugar 2 não toca.
  Reprovam: `som-vizinho` e `sem-alto-falante`.

### 2. O emperro trava a mão (`usa`)

- **Quem joga:** errar o roubo emperra a prensa: os 2 tempos sem prensar são 2 pulsos secos de 120 Hz por 40 ms nos
  dois atuadores, um em cada tempo.
- **Os outros:** veem a prensa do emperrado soltar vapor.
- **Como se prova:** o robô aperta ○ no lingote de ✕ do outro; `Forja.som_virtual(l)` tem 2 picos, um por tempo, e
  nenhum aperto do robô conta nos 2 tempos. Reprova: `haptica-muda`.

### 3. O lingote de ouro pesa (`usa`)

- **Quem joga:** prensar o lingote de ouro dá o batimento da vitória da bíblia: 1,0 por 120 ms, pausa de 120 ms, 0,7
  por 120 ms.
- **Os outros:** a barra de luz do kit pisca dourado no controle do dono por 360 ms; as luzinhas não mudam.
- **Como se prova:** `Forja.percepcao(l).forte` segue 1,0, 0, 0,7 nas janelas de 120 ms; `luz` muda e volta;
  `leds_jogador` fica igual. Reprovam: `luz-parada` e `leds-errados`.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| julgar o roubo pelo carimbo do sensor, a 4 ms | o arquiteto |
| a medição da ordem de chegada com 4 controles num hub | o arquiteto, na bancada F01 |
| o «tlim» e o puxão de 40 ms na bíblia de háptica | o diretor de som e háptica |
| se o dourado na barra de luz cabe na regra «a barra de luz fica com o kit» | o diretor de jogo |
</content>
</invoke>
