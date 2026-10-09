# O4 — Fuga do Mecha Cego (S07_J34): a nota de pesquisa

A ficha: [O4 — Fuga do Mecha Cego](../tarefas/O4-fuga-do-mecha-cego.md). O catálogo: [o DualSense](dualsense.md),
recursos 2 (a háptica), 3 (o rumble) e 8 (a barra de luz), e a mágica 9 (o vento que aponta). Pesquisa de 08/10/2026.

## O recurso

A **háptica com lado**: os passos do mecha num atuador só, com o ganho pela distância, a 140 bpm (uma batida = 0,43
s). Foge-se para o lado oposto na batida 4; na batida 6, a varredura. No rádio, `golpe_esq` e `golpe_dir`. A TV nunca
diz o lado.

## O que se sabe fora

| quem | o que faz | o que ensina aqui | fonte |
| --- | --- | --- | --- |
| A Blind Legend (DOWiNO, 2015) | o inimigo se localiza só pelo som estéreo, e quem joga se vira para ele | o lado sem imagem é jogável por leigos | página na Steam (app 437530) |
| Ghost of Tsushima Director's Cut (Sucker Punch, 2021) | o vento na háptica aponta a direção | a direção mora na mão | já no catálogo, a mágica 9 |
| Astro's Playroom (Team Asobi, 2020) | os passos alternam esquerda e direita | a mão separa os dois atuadores sem treino | prévias da GameSpot e da Stevivor |

## O risco no Linux

1. **O lado trocado.** Se o mapa de canais vier invertido, todos fogem para o mecha. O defeito `haptica-trocada` do
   simulador imita; no cabo de verdade, só a bancada vê.
2. **O rumble no rádio.** No SDL, o `low_frequency` vai para `ucRumbleLeft` e o `high_frequency` para `ucRumbleRight`
   (`SDL_hidapi_ps5.c`, linhas 1023–1024). O motor esquerdo é mais pesado: um passo a 0,5 à esquerda não pesa o mesmo
   que a 0,5 à direita. O defeito `motores-trocados` imita a troca.
3. **O rumble cala a háptica** (a suspeita (e) do 05): nenhum rumble pode tocar durante os passos no cabo.
4. **Firmware antigo.** Abaixo de `0x0224`, o SDL divide o rumble por 2; o passo distante a 0,3 vira 0,15, perto do
   piso. Ler o firmware na conexão e subir o piso para 0,4 nesses controles.

## As mágicas, em ordem

### 1. O mecha atravessa a mão no pico

- **Quem joga:** no pico, o mecha não fica num lado: ele cruza a palma (esquerda → centro → direita) e para. Foge-se
  do lado onde ele terminou. Fica mais difícil sem ficar injusto.
- **Os outros:** nada.
- **Os números:** 4 passos numa batida: esquerda 1,0/0; 0,7/0,3; 0,3/0,7; direita 0/1,0 (ou o espelho). O fim
  decide.
- **Como se prova sem o controle:** a prova lê `som_virtual(l)` em cada passo e confere a razão `esq/dir`; o robô foge
  pelo último passo. Com `--defeitos=haptica-trocada`, o robô foge para o lado errado e o registro mostra.
- **O que falta:** nada no módulo.

### 2. O holofote acende a luz de quem foi pego

- **Quem joga:** pego pela varredura, a barra dele vai de 30 % a 100 % por uma batida e volta.
- **Os outros:** veem no colo quem foi pego, sem a TV dizer o lado.
- **Os números:** 30 % → 100 % em 0,05 s, volta em 0,43 s.
- **Como se prova sem o controle:** `percepcao(l).luz` no instante do pego e uma batida depois. Com
  `--defeitos=luz-parada`, reprova.
- **O que falta:** nada no módulo.

### 3. O lado no rádio, pesado igual

- **Quem joga:** no rádio, o passo à esquerda e à direita pesam igual, mesmo com motores diferentes.
- **Os outros:** nada.
- **Os números:** `golpe_esq` `[1.0, 0.0, 250]`; `golpe_dir` `[0.0, 1.0, 250]`; o distante a 0,4 no esquerdo e 0,55 no
  direito (o direito é mais leve).
- **Como se prova sem o controle:** o robô lê `percepcao(l)` e foge para o lado do motor parado. Com
  `--defeitos=motores-trocados`, foge errado; o registro anota.
- **O que falta:** a correção de peso na tabela da F05; o valor de 0,55 se mede na bancada com quatro pessoas.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| o mapa de canais e o firmware lido na conexão (o piso 0,4 abaixo de `0x0224`) | o arquiteto |
| o peso igual dos dois motores no rádio, medido com gente | o diretor de som e háptica |
