# M3 — Metralhadora de Feitiços: a pesquisa do DualSense

Ficha: [M3](../tarefas/M3-metralhadora-de-feiticos.md). Seção: [M — A Galeria](../tarefas/M-a-galeria.md).
Catálogo: [dualsense.md](dualsense.md). Data: 08/10/2026.

## O recurso

- **A rajada treme no dedo:** R2 em `Vibration` (posição 1, amplitude 6), frequência = bpm ÷ 60 × 4, as
  semicolcheias da faixa: 7 Hz a 104 bpm, 10 Hz a 155 bpm.
- **O superaquecimento:** atirar fora da vez trava o R2 por um compasso com `Feedback` na posição 0 e força toda;
  barra de luz laranja 0,4 s; `tropeco` no alto-falante do dono, 0,7.
- **A nau capitânia** sobe aos 30 s; o canhão dela, no pico, é `golpe` em todos.
- Sala da prova: `S05_J23`.

## O que se sabe fora

| jogo ou projeto | o que faz | fonte |
| --- | --- | --- |
| Gran Turismo 7 (2022) | o ABS pulsa no gatilho do freio | GTPlanet, `gtplanet.net/gt7-dualsense-feel-abs-20200821`; a Forza no Xbox One (gatilhos de impulso) veio antes |
| Astro Bot (Team Asobi, 2024) | o jato do Barkster se sente no gatilho junto da animação | TechRadar, «Team Asobi says Astro Bot will push the DualSense» |
| Call of Duty: Black Ops Cold War (2020) | o gatilho treme no tiro automático, afinado por arma | KitGuru |
| Hi-Fi Rush, PS5 (Tango, 2024) | a batida da música na háptica | catálogo (TechRadar) |
| Deathloop (2021) | o gatilho trava quando a arma emperra | KitGuru; catálogo, mágica 5 |
| Gerador do Nielk1 | o Vibration: posição, amplitude 0–8, frequência 0–255 Hz | catálogo |

## O risco no Linux

1. **O tremor do gatilho não sabe da música.** O Vibration é um oscilador dentro do controle; o jogo dá a frequência,
   não a fase. Numa rajada de 4 compassos a 7 Hz, a semicolcheia do dedo pode escorregar da batida. **Não achei**
   fonte pública que diga se reenviar o efeito reinicia a fase. **Medir na bancada:** reenviar o Vibration a cada
   batida e gravar, com o microfone da bancada perto do gatilho, o atraso entre a batida e o primeiro tique; meta:
   menos de 20 ms em 16 batidas.
2. **Frequência inteira:** o byte é em Hz inteiro. 104 bpm dá 6,93 Hz, que vira 7. Em 32 semicolcheias, 0,07 Hz de
   erro somam 0,32 s de deriva se a fase nunca for reiniciada. Mais um motivo para o risco 1.
3. **A trava não pode exigir o fundo:** Feedback na posição 0 com força 8 endurece desde o começo; nunca pedir 100%.
4. **O Steam Input** pode reescrever o gatilho; o SDL do Godot nunca manda o 0x02.

## As propostas

### 1. A semicolcheia presa na batida (para quem atira)

- **Quem atira:** o Vibration é reenviado a cada batida da música, com a mesma frequência, para que a fase recomece no
  tempo. A rajada fica presa à faixa, como o ABS do GT7 pulsa no ritmo do freio.
- **Os outros:** R2 em Off fora da vez deles.
- **Como se prova sem o controle:** `--simular=4 --robo=bom --semente=7 --sala=S05_J23`. O registro grava cada
  `saida` de gatilho com a batida; a prova confere um reenvio por batida durante a rajada, a frequência
  `round(bpm ÷ 60 × 4)` e o byte do modo 0x26 só no dono da vez. O robô da seção já lê o 0x21 da trava (a ficha
  tem `travada := ... == 0x21`). **A que morde:** `--defeitos=engasga` atrasa os relatórios; a prova vê o reenvio fora
  da batida.
- **Na bancada:** a medida da fase (risco 1). Se reenviar não reiniciar a fase, a proposta cai e fica o envio único.

### 2. A arma esfria no dedo (para quem superaqueceu)

- **Quem superaqueceu:** no último tempo do compasso travado, a força do Feedback cai 8 → 4 → 0, uma colcheia cada.
  O dedo sente a arma esfriar e sabe quando volta, sem olhar.
- **Os outros:** veem a fumaça sumir.
- **Como se prova:** o modo é 0x21 no compasso travado e 0x26 depois (a vez volta) ou 0x05 (não é a vez). **A força
  8, 4, 0 só se prova com os 11 bytes do gatilho** (pedido ao arquiteto); até lá, o registro grava a sequência.

### 3. O canhão da nau dispara em todos os dedos (para todos)

- **Todos:** no pico, no tiro do canhão, o R2 de todos vira `Weapon` (início 3, fim 6, força 8) por uma batida, e o
  `golpe` vem junto. Quem puxar o R2 na batida dispara o canhão com a nau: um tiro de todos.
- **Os outros:** é coletivo; a sala atira junto.
- **Como se prova:** na batida do canhão, `percepcao(l)["gatilho_dir"]` é 0x25 em todos os lugares com controle e
  volta ao modo anterior na batida seguinte. Com `--defeitos=gatilho-mudo`, o lugar mudo fica 0x05 e a prova acusa.

## O que preciso de outras cabeças

- **Bancada (F01):** a medida da fase do Vibration (proposta 1), com o microfone da bancada.
- **Arquiteto:** os 11 bytes do gatilho na `percepcao`.
- **Diretor de jogo:** o canhão coletivo (proposta 3), os pontos dele.
