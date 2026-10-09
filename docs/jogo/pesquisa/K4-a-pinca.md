# K4, A Pinça: a pesquisa do DualSense

Slot S03_J14 · dois dedos · o verbo é **pegar, esticar e soltar a peça quente**. A
[ficha](../tarefas/K4-a-pinca.md), a [diversão](../diversao/K-o-molde.md) e o
[catálogo](dualsense.md#11-o-touchpad).

## O recurso

- **Os dois dedos no touchpad.** O segundo dedo chega na nota (pegar), os dedos se afastam 0,45 ou mais enquanto a
  nota longa dura (esticar) e saem no fim (soltar). Perder um dedo conta como soltar.
- **A textura `metal`** na háptica.
- A troca da diversão: **o puxa-ferro**, com um estalo escondido entre 0,72 e 0,90 de abertura.

## O que se sabe fora

| jogo ou projeto | a técnica | a fonte |
| --- | --- | --- |
| 1-2-Switch, Safe Cracker (2017) | girar o controle até sentir o clique escondido do segredo | [Looper](https://looper.com/40850/1-2-switch-includes-safe-cracking-crying-baby-simulators), [Vooks](https://vooks.net/1-2-switch-review/amp) |
| Astro Bot (2024) | a esponja espremida pelo gatilho adaptativo; a força na mão | [TechRadar](https://www.techradar.com/gaming/consoles-pc/team-asobi-says-astro-bot-will-push-the-dualsense-controller-to-a-new-level) |
| Astro's Playroom (2020) | o zíper do traje e a bola deslizados no touchpad | [GameSkinny](https://www.gameskinny.com/0w47r/astros-playroom-review-pure-imaginative-fun) |
| o libinput | dois dedos num touchpad viram rolagem ou pinça do desktop | [libinput](https://wayland.freedesktop.org/libinput/doc/latest/ignoring-devices.html), [Arch BBS 277941](https://bbs.archlinux.org/viewtopic.php?id=277941) |

O estalo escondido do puxa-ferro é o Safe Cracker com dois dedos: a mão acha o que o olho não vê.

## O risco no Linux

1. **Dois dedos viram rolagem ou zoom no desktop.** É o pior caso da seção K: o libinput lê a pinça como gesto. A cura é
   a mesma da [K1](K1-o-molde.md), `LIBINPUT_IGNORE_DEVICE=1` no event do Touchpad, com sudo.
2. **Dois dedos juntos viram um.** Com os dedos colados, o touchpad pode ler um dedo só, e perder um dedo conta como
   soltar. A distância mínima entre dois dedos lidos como dois não está medida. Medir na bancada: a menor distância
   com 2 dedos lidos, em 20 pegadas. O defeito `um-dedo` cobre o caso extremo.
3. **A abertura num retângulo.** O touchpad tem 1920 × 1070. Uma abertura de 0,90 na horizontal cabe; na diagonal,
   medida em unidades normalizadas, a conta muda. Medir a abertura em pixels, não em 0 a 1.

## As mágicas

### 1. O estalo escondido (`usa`)

- **Quem joga:** no puxa-ferro, cada rodada sorteia um ponto entre 0,72 e 0,90 de abertura. Ali, um tique de 150 Hz
  por 12 ms, ganho 0,6, só na mão de quem puxa. Soltar no estalo vale o ferro.
- **Os outros:** veem a peça esticar e não sabem onde está o estalo. Leem a cara do dono.
- **Como se prova:** com o estalo sorteado em 0,80, o robô abre os dedos de 0,5 a 0,9 em passos de 0,02;
  `Forja.som_virtual(l)` tem um pico só, no passo de 0,80; os outros lugares, nada. Reprovam: `um-dedo` e
  `som-vizinho`.

### 2. O metal estica na mão (`usa`)

- **Quem joga:** a textura `metal` cresce com a abertura, ganho de 0,1 a 0,45 até 0,6 a 0,90. O ferro fica tenso entre
  os dedos.
- **Os outros:** nada no controle deles.
- **Como se prova:** com os dois dedos do robô a 0,5 de distância, `Forja.chao_do_envelope` do envelope sentido
  devolve 2 (metal); a energia a 0,85 é maior que a 0,5. Reprova: `haptica-muda`.

### 3. A peça cai (`usa`)

- **Quem joga:** perder um dedo no meio da nota derruba a peça: o motor forte a 0,8 por 80 ms e um «clang» no
  alto-falante do dono.
- **Os outros:** ouvem o «clang» vir da mão de quem deixou cair.
- **Como se prova:** o robô tira o dedo 1 no meio da nota longa; `Forja.percepcao(l).forte` vai a 0,8 por 80 ms e
  `Forja.som_virtual(l).falante` passa de 0,3. Reprovam: `um-dedo` (a nota tem de cair também sem o robô soltar) e
  `motores-trocados`.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| a regra udev do Touchpad e a instalação com sudo; na K4 ela é obrigatória | o arquiteto escreve; a Vitória instala |
| a menor distância entre dois dedos lidos como dois | a bancada F01 |
| a abertura em pixels, não em 0 a 1 | o designer de sistemas |
| o sorteio do estalo e o tique de 12 ms na bíblia de háptica | o diretor de som e háptica |
</content>
</invoke>
