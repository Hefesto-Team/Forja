# P2 — O Sopro no Fole (S08_J37): a nota de pesquisa

A ficha: [P2 — O Sopro no Fole](../tarefas/P2-o-sopro-no-fole.md). O catálogo: [o DualSense](dualsense.md), recurso 6
(o microfone) e a mágica 10 (o sopro e o silêncio). Pesquisa de 08/10/2026.

## O recurso

O **microfone pelo nível sustentado**: a nota longa `DUR` 1,5 batida (3,5 no pico), a 112 bpm (uma batida = 0,54 s; o
pico dura 1,9 s). `LATENCIA_FIM` 0,12 s. A falha é a fuligem.

## O que se sabe fora

| quem | o que faz | o que ensina aqui | fonte |
| --- | --- | --- | --- |
| WarioWare: Touched!, Lung Capacity (Nintendo, 2004) | soprar até o fim; parar antes perde | o sopro longo é legível e engraçado | mariowiki.com/Lung_Capacity |
| Don't Stop! Eighth Note (YASUHATI, 2017) | o volume da voz controla o pulo | o nível sustentado aguenta um jogo | App Store (id1215691000) |
| Astro's Playroom (Team Asobi, 2020) | soprar no microfone do controle gira o cata-vento | o sopro é um verbo que todo mundo entende na hora | já no catálogo, a mágica 10 |

## O risco no Linux

1. **O cancelamento de ruído come o sopro.** A base do áudio é `FORJA_AUDIO_BASE 0x0D`: microfone interno, eco (bit
   2) e ruído (bit 3). Um sopro longo é ruído largo e estável, o que um cancelador aprende e atenua. Hipótese: o nível
   cai depois de 1 s. A 1,9 s no pico, pode morrer antes do fim.
2. **O mudo herdado da P1.** Se a P1 terminou com a conta ímpar, o microfone chega mudo no hardware. Ver a
   [P1](P1-a-voz.md).
3. **A háptica no microfone.** A labareda na mão durante o sopro suja o nível (a regra da Sony).

## As mágicas, em ordem

### 1. A barra de luz é o fole

- **Quem joga:** enquanto sopra, a barra sobe de 40 % a 100 % ao longo de `DUR`; parou, cai a 40 %. A luz é
  silenciosa e não suja o microfone.
- **Os outros:** veem quem segura o fole.
- **Os números:** 40 % + 60 % × (tempo soprado / `DUR`); a queda em 0,1 s.
- **Como se prova sem o controle:** `robo_falar(l, 0,5, 0,8)` e a prova lê `percepcao(l).luz` em 0,4 s e 0,8 s
  (sobe). Com `--defeitos=mic-surdo`, a luz fica a 40 %. Com `luz-parada`, reprova.
- **O que falta:** nada no módulo.

### 2. A labareda na mão só depois

- **Quem joga:** a recompensa tátil vem depois de julgada a saída (`fim + LATENCIA_FIM`), nunca durante.
- **Os outros:** nada.
- **Os números:** labareda 200 ms, ganho 0,8, em `fim + 0,12 s`; nada de háptica nem rumble durante o sopro.
- **Como se prova sem o controle:** a prova lê `som_virtual(l)` e `percepcao(l).forte/fraco` durante o sopro: tudo
  abaixo de 0,02.
- **O que falta:** nada no módulo.

### 3. O sopro com o cancelamento de ruído desligado

- **Quem joga:** o sopro longo segura até o fim.
- **Os outros:** nada.
- **Os números:** medir 0x05 (sem o bit 3) contra 0x0D num sopro de 3 s, 10 vezes cada; se o nível cair mais de 30 %
  em 0x0D depois de 1 s, a P2 pede 0x05 só na janela do sopro.
- **Como se prova sem o controle:** não se prova; é medida de bancada com `som_escutar`.
- **O que falta:** a medida (o arquiteto).

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| o experimento do bit 3 (0x05 contra 0x0D) | o arquiteto |
| a paridade do mudo herdada da P1 | o arquiteto |
