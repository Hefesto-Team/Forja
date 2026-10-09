# Q4 — Ruge o Reator (S09_J44): a nota de pesquisa

A ficha: [Q4 — Ruge o Reator](../tarefas/Q4-ruge-o-reator.md). O catálogo: [o DualSense](dualsense.md), recursos 10 (o
giroscópio e o acelerômetro), 11 (o touchpad), 3 (o rumble) e 8 (a barra de luz). Pesquisa de 08/10/2026.

## O recurso

Um **medley** a 120 bpm (uma batida = 0,5 s): Bater, Equilibrar (rolagem ±0,35 rad), Traçar (touchpad, 0,25) e
Defender (L1/R1, rumble uma batida antes). A integridade da plataforma é de todos.

## O que se sabe fora

| quem | o que faz | o que ensina aqui | fonte |
| --- | --- | --- | --- |
| Rhythm Heaven (Nintendo), os remixes | os jogos já vistos voltam juntos, sem treino | o medley funciona se cada estação já foi ensinada | rhythmheaven.fandom.com/wiki/Remix |
| WarioWare (Nintendo) | a troca rápida de regra é a graça | o anúncio da próxima regra é tudo | en.wikipedia.org/wiki/WarioWare |
| 1-2-Switch, Safe Crack (Nintendo, 2017) | girar até sentir o clique | o giro sem tela é jogável | já no catálogo |

## O risco no Linux

1. **O zero do giro deriva.** O giroscópio integra erro. Em Equilibrar, depois de 50 batidas, o zero que vale foi pego
   lá no início. A Sony tem `scePadResetOrientation`; o Linux não tem, o jogo zera sozinho.
2. **O rumble corta a háptica** (a suspeita (e) do 05): o aviso de Defender apaga a háptica da estação.
3. **O touchpad no rádio** chega igual; nada a temer.

## As mágicas, em ordem

### 1. O prenúncio da próxima estação na mão

- **Quem joga:** uma batida antes da troca, a mão sente a textura da próxima estação.
- **Os outros:** o mesmo.
- **Os números:** nas batidas 51, 107 e 155; 150 ms; Bater um golpe, Equilibrar uma rampa, Traçar um arranhão,
  Defender dois golpes.
- **Como se prova sem o controle:** `som_virtual(l)` nas batidas 51, 107 e 155.
- **O que falta:** os quatro sons no `sons_salas.c`.

### 2. Zerar a postura antes de Equilibrar

- **Quem joga:** a rolagem começa do jeito que ele segura o controle agora.
- **Os outros:** nada.
- **Os números:** o zero é a média das batidas 50 e 51.
- **Como se prova sem o controle:** `robo_girar(l, 0,2)` antes e a prova confere a rolagem 0 na batida 52. Com
  `--defeitos=giro-invertido`, o registro anota.
- **O que falta:** nada no módulo.

### 3. As quatro barras mostram a integridade

- **Quem joga:** a luz dele cai com a plataforma.
- **Os outros:** veem a mesma queda no colo de todos.
- **Os números:** brilho 40 % + 60 % × integridade.
- **Como se prova sem o controle:** `percepcao(l).luz` contra a integridade do registro.
- **O que falta:** nada.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| os quatro sons do prenúncio | o diretor de som e háptica |
