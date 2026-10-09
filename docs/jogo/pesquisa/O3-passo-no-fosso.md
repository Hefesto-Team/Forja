# O3 — Passo no Fosso (S07_J33): a nota de pesquisa

A ficha: [O3 — Passo no Fosso](../tarefas/O3-passo-no-fosso.md). O catálogo: [o DualSense](dualsense.md), recurso 2 (a
háptica por áudio) e a mágica 3 (o metrônomo na mão). Pesquisa de 08/10/2026.

## O recurso

O **metrônomo na mão**: o pulso de metal em todo contratempo (ganho 0,7) e a nota do dono a 1,0, a 150 bpm (uma
batida = 0,4 s, meia batida = 0,2 s). A janela do pé é `JANELA_BOM` 140 ms. No pico, vapor na háptica. A latência da
saída para o controle decide se o pulso cai no tempo.

## O que se sabe fora

| quem | o que faz | o que ensina aqui | fonte |
| --- | --- | --- | --- |
| Ammirante, Russo e Patel (2016) | o metrônomo tátil fica perto do auditivo quando o estímulo é grande e o ritmo é simples | o pulso precisa de área (os dois atuadores) e de padrão simples (um por contratempo) | Acoustics Week in Canada 2016, artigo 326 (awc.caa-aca.ca) |
| Hi-Fi Rush, versão de PS5 (Tango, 2024) | o mundo pulsa no tempo e a háptica marca a batida | o ritmo na mão funciona num jogo inteiro, não só num truque | já no catálogo, a mágica 3 |
| Astro's Playroom (Team Asobi, 2020) | o metal clica; a areia espalha | o metal é a textura mais nítida para marcar tempo | prévias da GameSpot e da Stevivor |

## O risco no Linux

1. **A latência de saída.** O módulo abre o fluxo com `SDL_OpenAudioDeviceStream` (`nativo/som/som_controle.c:94`),
   sem hint de tamanho. O SDL3 escolhe 1024 quadros a 48 kHz, 21,3 ms (`SDL_GetDefaultSampleFramesFromFreq`,
   `SDL_audio.c:151`). O quantum padrão do PipeWire também é 1024 a 48000, mais 21,3 ms (o manual do `pipewire(1)`).
   Somados: **pelo menos 42,7 ms** antes do USB, mais o intervalo do áudio USB (`bInterval` 4, 1 ms em alta
   velocidade). Contra uma janela de 140 ms, o pulso chega com um terço da janela já gasto.
2. **Nada compensa hoje.** A calibração H03 e o 04 acertam a entrada contra a TV, não a saída para o controle.
3. **Quatro placas.** São quatro fluxos de 4 canais a 48 kHz num barramento. O descritor de entrada usa `bInterval` 6
   (o fórum MiSTer); em alta velocidade é 2^(6−1) × 125 µs = 4 ms, os 250 Hz conhecidos. Se fosse full-speed, quatro
   placas atrás de um hub de um TT não caberiam. Confirmar com `lsusb -t` na bancada.
4. **A placa virtual não tem latência.** O simulador entrega o som no mesmo quadro. A prova sem controle não vê o atraso;
   só a bancada mede.

## As mágicas, em ordem

### 1. O pulso sai adiantado pela latência medida

- **Quem joga:** o metal cai na mão no contratempo de verdade, não 43 ms depois. A janela inteira fica para o pé.
- **Os outros:** nada.
- **Os números:** adiantar cada `som_haptica` de `LATENCIA_PLACA` segundos. Valor de partida 0,043; o real vem da
  bancada. Medir com `exp_ataque`: o microfone do próprio controle grava o clique do atuador, e a diferença entre o
  pedido e o pico é a latência. 20 cliques, a mediana.
- **Como se prova sem o controle:** a prova põe `LATENCIA_PLACA` 0,043 e confere no registro que o pedido sai 43 ms
  antes da batida, e que o `som_virtual` (sem atraso) mostra o pico 43 ms antes. O robô `--robo=bom` segue acertando.
- **O que falta:** a constante e a medida (o arquiteto). O mesmo valor serve à O2, à O5 e à R.

### 2. A nota do dono é outro material

- **Quem joga:** o metrônomo é metal (ganho 0,7); a nota dele é uma pancada grave de 80 Hz a 1,0. A mão separa «o
  tempo» de «a minha vez» pelo material, não pela força.
- **Os outros:** nada.
- **Os números:** metrônomo `material:metal`, 0,7; nota do dono 80 Hz, 1,0, 60 ms.
- **Como se prova sem o controle:** o robô pisa só quando `som_virtual(l)` passa 0,85 (o forte). Com
  `--defeitos=haptica-muda`, o robô para de pisar e erra todas; o registro mostra que o defeito, não o tempo, derrubou.
- **O que falta:** o som de 80 Hz no `sons_salas.c` (síntese).

### 3. A luz pulsa no contratempo

- **Quem joga:** a barra de luz sobe de 60 % a 100 % em cada contratempo, por 80 ms. Quem olha para o colo tem um
  segundo metrônomo.
- **Os outros:** veem as quatro luzes pulsando juntas; quem pisa fora salta aos olhos.
- **Os números:** 60 % → 100 % por 80 ms, a cada 0,4 s; a cor do lugar.
- **Como se prova sem o controle:** a prova lê `percepcao(l).luz` a cada quadro e conta os picos: 1 por contratempo,
  ±1 quadro. Com `--defeitos=luz-parada`, reprova.
- **O que falta:** nada no módulo.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| medir a latência da placa (`exp_ataque`, 20 cliques) e criar `LATENCIA_PLACA` | o arquiteto |
| conferir alta velocidade com `lsusb -t` e as quatro placas juntas | o arquiteto |
| o som de 80 Hz e a regra «o dono é outro material» | o diretor de som e háptica |
