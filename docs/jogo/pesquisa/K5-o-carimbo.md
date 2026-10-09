# K5, O Carimbo: a pesquisa do DualSense

Slot S03_J15 · vez e roubo · o verbo é **clicar o touchpad na síncope**. A
[ficha](../tarefas/K5-o-carimbo.md), a [diversão](../diversao/K-o-molde.md) e o
[catálogo](dualsense.md#11-o-touchpad).

## O recurso

- **O clique do touchpad** (`Forja.TOUCHPAD`), na síncope.
- **O lingote do centro** é da vez de um, mas qualquer um pode carimbar por cima. O selo mais firme fica.
- **O touchpad não tem pressão** (o catálogo). «Mais firme» só pode ser o mais perto da síncope, julgado em ms.
- O grito: o selo por cima.

## O que se sabe fora

| jogo ou projeto | a técnica | a fonte |
| --- | --- | --- |
| Papers, Please (2013) | o carimbo de aprovar ou negar é o verbo do jogo; o baque do carimbo é a recompensa | [Wikipedia](https://en.wikipedia.org/wiki/Papers,_Please) |
| Tearaway Unfolded (PS4, 2015) | apertar o touchpad afunda o tambor no mundo | [God is a Geek](https://www.godisageek.com/reviews/tearaway-unfolded-review/), [Tampere PlayLab](https://blogs.tuni.fi/playlab/game-reviews/tearaway-unfolded/) |
| o SDL `SDL_hidapi_ps5.c` | o touchpad manda pressão fixa: 1,0 com o dedo, 0,0 sem | [SDL](https://github.com/libsdl-org/SDL/blob/main/src/joystick/hidapi/SDL_hidapi_ps5.c), zlib |
| o touchpad no desktop Linux | o clique do touchpad vira clique do mouse | [Arch BBS 277941](https://bbs.archlinux.org/viewtopic.php?id=277941), [libinput](https://wayland.freedesktop.org/libinput/doc/latest/ignoring-devices.html) |

## O risco no Linux

1. **O clique do touchpad vira clique do mouse.** Na tela cheia, o clique cai na própria janela do jogo, e um botão
   da interface pode ser apertado sem querer. A cura é a da [K1](K1-o-molde.md), com sudo.
2. **Dois carimbos quase juntos.** Se o jogo julga pelo quadro, dois cliques a 10 ms de distância caem no mesmo
   quadro de 16,7 ms e o «mais firme» vira sorteio. O catálogo diz que o carimbo do sensor julga a 4 ms. Medir na
   bancada: o carimbo do clique contra o do quadro, em 100 cliques.
3. **O curso do clique.** O touchpad afunda antes de clicar. O tempo entre o toque e o clique não está medido; se
   passar de 30 ms, a síncope fica atrasada para quem encosta antes. Medir: o intervalo entre o dedo encostado e o
   botão, em 40 cliques.

## As mágicas

### 1. O baque do carimbo (`usa`)

- **Quem joga:** o clique dá um baque de 90 Hz por 40 ms nos dois atuadores, ganho 0,7, e um «tum» no alto-falante
  dele. O carimbo pesa na mão.
- **Os outros:** ouvem o «tum» vir da mão de quem carimbou.
- **Como se prova:** `Forja.robo_apertar(l, Forja.TOUCHPAD)` na síncope; `Forja.som_virtual(l)` tem `.esq` e `.dir`
  acima de 0,5 e `.falante` acima de 0,3. Reprovam: `sem-clique` e `haptica-muda`.

### 2. O selo por cima (`usa`)

- **Quem joga:** quem foi carimbado por cima sente dois toques secos de 120 Hz por 20 ms, com 60 ms entre eles: o selo
  dele rachou.
- **Os outros:** veem o selo novo cobrir o velho e sabem pelo «tum» quem carimbou.
- **Como se prova:** o robô do lugar 1 clica 40 ms fora da síncope e o do lugar 2 clica 5 ms fora; o selo fica com o 2,
  e `Forja.som_virtual(1)` tem os dois picos com 60 ms entre eles. Reprovam: `som-vizinho` e `haptica-trocada`.

### 3. A síncope na mão (`usa`)

- **Quem joga:** na 1.ª frase, um pulso de 80 Hz por 30 ms, ganho 0,35, marca a síncope no controle de quem tem a vez.
  Na 2.ª frase, sai.
- **Os outros:** nada no controle deles.
- **Como se prova:** sem o robô apertar, `Forja.som_virtual(l)` tem um pico na síncope de cada compasso da 1.ª frase,
  só no lugar da vez; na 2.ª frase, nenhum. Reprova: `haptica-muda`.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| a regra udev do Touchpad e a instalação com sudo | o arquiteto escreve; a Vitória instala |
| julgar o carimbo pelo carimbo do sensor, a 4 ms | o arquiteto |
| o intervalo entre o toque e o clique | a bancada F01 |
| o baque de 90 Hz e o selo rachado na bíblia de háptica | o diretor de som e háptica |
</content>
</invoke>
