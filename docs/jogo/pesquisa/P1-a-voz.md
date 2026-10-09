# P1 — A Voz (S08_J36): a nota de pesquisa

A ficha: [P1 — A Voz](../tarefas/P1-a-voz.md). A seção: [P — A Voz](../tarefas/P-a-voz.md). O catálogo:
[o DualSense](dualsense.md), recursos 6 (o microfone), 7 (o botão e a luz do mudo) e 4 (o alto-falante), e a mágica 2 (o
segredo no ouvido). Pesquisa de 08/10/2026.

## O recurso

O **microfone do controle** como ouvido do jogo e o **botão do mudo** como escudo. O ouvido: `VOZ_ACIMA` 0,30 acima do
piso, `VOZ_FICA` 0,18, `MARGEM_AR` 0,12, `LATENCIA_MIC` 0,08 s. A 105 bpm (uma batida = 0,57 s): o chamado, o sopro, o
susto com a nota do mudo em `S0 + 3` e o rugido em `S0 + 4`.

## O que se sabe fora

| quem | o que faz | o que ensina aqui | fonte |
| --- | --- | --- | --- |
| Nintendogs (Nintendo, 2005) | chamar o cão pelo nome no microfone; o manual pede a boca a uns 15 cm | funciona «metade das vezes»: o reconhecimento falha, o **nível** não | manual de início rápido da Nintendo; en.wikipedia.org/wiki/Nintendogs |
| Don't Stop! Eighth Note (YASUHATI, 2017) | o volume da voz controla o pulo | o nível bruto basta para um jogo inteiro e é engraçado de ver | App Store (id1215691000) |
| Phasmophobia (Kinetic Games, 2020) | o fantasma escuta pelo volume; o sussurro passa | a regra «baixo passa, alto chama» é legível sem tutorial | GameSpot, «Phasmophobia adds scary feature...» |
| A Quiet Place: The Road Ahead (Stormind, 2024) | o microfone é opcional e a sala real vira ameaça | dar sempre o caminho sem microfone | Pure Xbox, outubro de 2024 |

## O risco no Linux

1. **O mudo é do hardware e o jogo não lê o estado.** No `hid-playstation.c`, cada aperto do botão alterna
   `mic_muted` e manda `mute_button_led` e `power_save_control |= MIC_MUTE`. Não há LED micmute no sysfs. O módulo
   nunca liga `FORJA_FX_POWER_SAVE` (`include/forja_dualsense.h:128,157`). **Um número ímpar de apertos deixa o
   microfone mudo no hardware depois do minigame:** o susto pede um aperto; a P2 começa «mudo no sistema».
2. **A paridade é rastreável.** O kernel começa desmutado na conexão, e o jogo vê o `BOTAO_MICROFONE`. Contar os
   apertos desde a conexão dá o estado.
3. **A háptica suja o microfone.** A Sony manda enfraquecer motor e gatilho enquanto o microfone escuta
   (`scePadSetVibrationTriggerEffectWeakWhileEmbeddedMicInUse`). O Linux não tem isso; o jogo tem de fazer.
4. **O volume do microfone** (byte 6 do relatório, 0x00–0x40) não chega ao GDScript. Hoje vale o padrão do módulo.
5. **O simulador** dá só o nível, sem vazamento entre controles, piso `SIM_PISO_DA_SALA` 0,12; não imita o mudo que
   alterna sozinho no kernel.

## As mágicas, em ordem

### 1. O escudo é o mudo de verdade, com a conta dos apertos

- **Quem joga:** a luz do mudo diz a verdade. O jogo conta os apertos desde a conexão; enquanto a conta é ímpar, o
  `led_mic` pisca (2). No fim do minigame, se ficou ímpar, a TV diz «aperte o mudo para voltar a falar» na raia dele.
- **Os outros:** veem quem está mudo de verdade.
- **Os números:** `led_mic` 2 com a conta ímpar; o aviso no fim por 2 batidas (1,14 s).
- **Como se prova sem o controle:** o robô aperta o mudo 1 vez (`robo_apertar`); a prova lê `percepcao(l).led_mic` = 2.
  Mais um aperto, 0. Com `--defeitos=led-mic-parado`, reprova. Com `--defeitos=mudo-nao-chega`, a conta não muda e o
  registro anota.
- **O que falta:** a paridade no módulo ou no `forja.gd` (o arquiteto).

### 2. O eco do chamado no alto-falante do dono

- **Quem joga:** chamou com BOM ou melhor, o controle dele responde uma batida depois com um eco curto.
- **Os outros:** ouvem de qual colo veio o eco.
- **Os números:** `S0 + 1`, 250 ms, volume 0,5; só fora da janela de escuta seguinte.
- **Como se prova sem o controle:** `som_virtual(l).falante` acima de 0,2 só no dono. Com `--defeitos=som-vizinho`, o
  eco sai no vizinho e a prova reprova. Na bancada: medir que o eco a 0,5 não faz o próprio microfone passar
  `VOZ_ACIMA` (`som_escutar`).
- **O que falta:** a medida na bancada.

### 3. A brasa na mão segue a voz, com teto

- **Quem joga:** enquanto fala, sente a brasa crescer na mão com a voz.
- **Os outros:** nada.
- **Os números:** háptica = nível × 1,5, teto 0,5 (a regra da Sony); rumble 0 durante a escuta.
- **Como se prova sem o controle:** o robô fala (`robo_falar(l, 0,6, 1,0)`); a prova lê `som_virtual(l)` e exige ≤
  0,5. Na bancada: medir que a háptica a 0,5 não passa piso + `VOZ_ACIMA` no próprio microfone.
- **O que falta:** a medida na bancada.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| a paridade do mudo e o aviso «aperte o mudo» | o arquiteto |
| o volume do microfone (byte 6) exposto ao GDScript | o arquiteto |
| a regra «motor mais fraco enquanto o microfone escuta» na bíblia | o diretor de som e háptica |
