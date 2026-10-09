# O2 — Neblina de Dados (S07_J32): a nota de pesquisa

A ficha: [O2 — Neblina de Dados](../tarefas/O2-neblina-de-dados.md). O catálogo: [o DualSense](dualsense.md), recursos
2 (a háptica), 3 (o rumble) e 8 (a barra de luz), e a mágica 9 (o vento que aponta). Pesquisa de 08/10/2026.

## O recurso

A **háptica como informação privada**: a pedra (`material:pedra`) bate na palma meia batida antes de cada batida firme
(300 ms a 100 bpm; 150 ms no pico). Na neblina, nada: o silêncio é a pista. Coadjuvante: a barra de luz na cor do
lugar a 30 %.

## O que se sabe fora

| quem | o que faz | o que ensina aqui | fonte |
| --- | --- | --- | --- |
| Ghost of Tsushima Director's Cut (Sucker Punch, 2021) | o vento-guia corre na háptica e aponta o caminho | a háptica guia sem imagem | já no catálogo (GamingBolt; Can I Play That) |
| A Blind Legend (DOWiNO e France Culture, 2015) | um jogo só de som: o cavaleiro cego anda guiado pela filha, por áudio binaural | a navegação inteira pode morar fora da tela | página na Steam (app 437530); Games for Change |
| The Last of Us Part I (Naughty Dog, 2022) | um ajuste deixa a háptica dar pistas de navegação e de combate | o mesmo canal serve de mapa | Can I Play That, a análise de acessibilidade |

## O risco no Linux

1. **O silêncio é ambíguo.** Se a háptica morre (o nó de som some, o cabo de áudio cai, o canal errado), o jogador
   sente neblina em toda batida e cai sempre. Hoje nada distingue «neblina» de «háptica muda» na mão dele.
2. **A latência come a antecedência.** A pedra sai pelo fluxo do SDL (1024 quadros a 48 kHz, 21,3 ms) e pelo quantum do
   PipeWire (1024, 21,3 ms): pelo menos 42,7 ms antes do USB. Dos 300 ms de aviso sobram ≤ 257 ms; no pico, dos 150
   ms sobram ≤ 107 ms. Detalhe na [O3](O3-passo-no-fosso.md).
3. **O rumble e a háptica no mesmo instante** se anulam (a suspeita (e) do 05). A ficha já afasta a queda (250 ms) da
   pedra seguinte (300 ms).
4. **A luz a 30 %** é o piso da F04; a barra pelo SDL (`SDL_SetGamepadLED`) não tem brilho separado: o brilho é a cor
   escurecida.

## As mágicas, em ordem

### 1. A neblina respira

- **Quem joga:** a neblina não é silêncio total: um sopro grave e contínuo nos dois atuadores, quase no limite do tato.
  A pedra corta o sopro. A mão sabe que está viva, e o silêncio de verdade passa a querer dizer «algo quebrou».
- **Os outros:** nada.
- **Os números:** 40 Hz, ganho 0,08, nos dois lados, do aviso ao fim; a pedra por cima, ganho 1,0, 60 ms; o sopro cala
  100 ms antes de cada pedra para o contraste.
- **Como se prova sem o controle:** a prova lê `Forja.som_virtual(l)` e exige `esq` e `dir` entre 0,02 e 0,15 fora das
  pedras. Com `--defeitos=haptica-muda`, o sopro some, o robô (que só salta onde sente) para de saltar, e o registro
  mostra 0 % de resposta à pista: o defeito aparece em vez de virar «o jogador é ruim».
- **O que falta:** um som `neblina` no `sons_salas.c` (síntese, sem amostra gravada).

### 2. O marco acende a mão no escuro

- **Quem joga:** a cada marco (4 plataformas), a barra de luz sobe de 30 % a 70 % e volta em uma batida.
- **Os outros:** na sala escura, as quatro luzes no colo dizem quem avança; ninguém precisa olhar a TV para saber.
- **Os números:** 30 % → 70 % em 0,1 s, volta a 30 % em 0,5 s (uma batida a 100 bpm). Nunca abaixo de 30 %, nunca
  outra cor.
- **Como se prova sem o controle:** a prova lê `Forja.percepcao(l).luz` no marco e 0,6 s depois: o canal mais forte da
  cor do lugar acima de 0,6 × o da cor cheia, e de volta a ≤ 0,35 ×. Com `--defeitos=luz-parada`, a prova reprova.
- **O que falta:** nada no módulo.

### 3. No rádio, a pedra é o motor fraco

- **Quem joga:** a pedra vira um toque curto no motor fraco (o direito, mais agudo); a queda, no forte. Duas coisas
  que a mão separa sem placa.
- **Os outros:** nada.
- **Os números:** pedra `[0.0, 0.5, 60]` (forte, fraco, ms); queda `[1.0, 0.0, 250]`.
- **Como se prova sem o controle:** com a placa virtual fora, o robô lê `percepcao(l)`: salta quando `fraco > 0,3` e
  `forte == 0`. Com `--defeitos=motores-trocados`, a pedra chega no forte e o robô cai: o registro vê.
- **O que falta:** as duas sensações na tabela da F05.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| o som `neblina` (a mágica 1) e a regra «a neblina nunca é silêncio total» na bíblia de háptica | o diretor de som e háptica |
| adiantar a pista pela latência medida da placa (ver a O3) | o arquiteto |
