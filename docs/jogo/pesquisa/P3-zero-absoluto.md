# P3 — Zero Absoluto (S08_J38): a nota de pesquisa

A ficha: [P3 — Zero Absoluto](../tarefas/P3-zero-absoluto.md). O catálogo: [o DualSense](dualsense.md), recursos 6 (o
microfone) e 7 (o botão e a luz do mudo), e a mágica 10 (o sopro e o silêncio). Pesquisa de 08/10/2026.

## O recurso

O **microfone como guarda do silêncio** e o **mudo como escudo**: `Ritmo.calar(4)` (8 no pico), a 120 bpm (uma batida
= 0,5 s). Três cargas de escudo, apertadas entre `M − 2` e `M`. `BARULHO_S` 0,15 s. O pé também é barulho.

## O que se sabe fora

| quem | o que faz | o que ensina aqui | fonte |
| --- | --- | --- | --- |
| Alien: Isolation (Creative Assembly, 2014) | o ruído da sala pela câmera ou Kinect atrai o alien | a Edge achou inconsistente: palmas não registradas, ataque sem motivo. **Injustiça mata o silêncio** | PC Gamer («The audio of Alien: Isolation»); Kotaku |
| Phasmophobia (Kinetic Games, 2020) | o fantasma escuta pelo volume | o limiar por volume é legível | GameSpot |
| WarioWare: Touched!, Tread Carefully (Nintendo, 2004) | não soprar | o «não faça nada» é um microjogo inteiro | mariowiki.com/Tread_Carefully_(microgame) |

## O risco no Linux

1. **O escudo que não desliga.** O escudo «desliga sozinho» só no LED do jogo. O hardware segue mudo (o
   `hid-playstation.c` alterna `mic_muted` a cada aperto, sem o jogo saber). Quem gastou uma carga fica **imune de
   graça** no silêncio seguinte.
2. **O vazamento entre microfones.** Quatro controles numa sala: quem ri alto aparece no microfone do vizinho, e a
   regra do ar congela o vizinho. Pior: quem tem escudo de hardware e ri alto fica imune e congela os outros.
3. **O simulador** não tem vazamento: a prova sem controle nunca vê esse caso.

## As mágicas, em ordem

### 1. O escudo de dois toques

- **Quem joga:** o escudo levanta num aperto e abaixa noutro, em `M + 4`, quando o jogo pede. Esquecer de abaixar
  custa mais uma carga, e o `led_mic` pisca até ele apertar. A conta de apertos fica sempre par.
- **Os outros:** veem quem esqueceu.
- **Os números:** o pedido em `M + 4` por 2 batidas (1 s); `led_mic` 2 enquanto a conta é ímpar; −1 carga se passar.
- **Como se prova sem o controle:** o robô aperta em `M − 1` e não aperta em `M + 4`; a prova lê `led_mic` 2 e a carga
  −1. Com `--defeitos=mudo-nao-chega`, o registro anota.
- **O que falta:** a paridade do mudo (ver a [P1](P1-a-voz.md)).

### 2. O barulho «de longe» não conta

- **Quem joga:** o riso do vizinho não o congela.
- **Os outros:** o mesmo.
- **Os números:** se 3 ou mais microfones passam `VOZ_ACIMA` a até 3 dB uns dos outros no mesmo quadro, é barulho da
  sala: ninguém congela. Só congela quem está 6 dB acima da mediana dos outros.
- **Como se prova sem o controle:** pedir ao arquiteto um vazamento no simulador (`--defeitos=mic-vaza`, 0,4 do nível
  de quem fala nos outros três). Na bancada: medir a matriz 4×4 com `exp_diagonal`.
- **O que falta:** o vazamento no simulador e a medida.

### 3. O olhar do guardião varre as luzes

- **Quem joga:** de `M + 1` a `M + 3`, a barra de luz sobe a 70 % raia a raia, uma por meia batida. Quando o olhar
  está nele, ele sabe.
- **Os outros:** veem o olhar passar no colo de cada um.
- **Os números:** 30 % → 70 % por 0,25 s, raias 1 a 4, a cada 0,25 s.
- **Como se prova sem o controle:** `percepcao(l).luz` de cada raia em ordem. Com `luz-parada`, reprova.
- **O que falta:** nada no módulo.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| a paridade do mudo | o arquiteto |
| o vazamento entre microfones no simulador e a matriz `exp_diagonal` | o arquiteto |
| a regra «3 ou mais a 3 dB é a sala» | o diretor de jogo |
