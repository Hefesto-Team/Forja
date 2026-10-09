# K1, O Molde: a pesquisa do DualSense

Slot S03_J11 · traço no tempo · o verbo é **levar o dedo de ponto a ponto e carimbar com o clique**. A
[ficha](../tarefas/K1-o-molde.md), a [diversão](../diversao/K-o-molde.md) e o
[catálogo](dualsense.md#11-o-touchpad).

## O recurso

- **O touchpad.** O dedo traça 3 pontos da letra, um trecho por tempo, e clica no último.
- **A textura `pedra`** na háptica enquanto o dedo arrasta.
- A troca da diversão: o abrir e fechar dos dois dedos **sai**. O grito: o desmolde dos quatro.

## O que se sabe fora

| jogo ou projeto | a técnica | a fonte |
| --- | --- | --- |
| Tearaway Unfolded (PS4, 2015) | desenhar e recortar formas no touchpad, que entram no mundo; as resenhas acharam o touchpad impreciso para desenhar | [Tampere PlayLab](https://blogs.tuni.fi/playlab/game-reviews/tearaway-unfolded/), [God is a Geek](https://www.godisageek.com/reviews/tearaway-unfolded-review/), [GamingTrend](https://gamingtrend.com/reviews/tearaway-unfolded-arts-and-crafts/) |
| Astro's Playroom (2020) | fechar o zíper do traje deslizando o dedo no touchpad | [GameSkinny](https://www.gameskinny.com/0w47r/astros-playroom-review-pure-imaginative-fun) |
| Rhythm Heaven (DS, 2008) | tocar, deslizar e dar piparote com a caneta, no tempo | [devlog no itch.io](https://peaceful-illumination.itch.io/rhythm-cataclysm/devlog/168773/getting-back-into-development-rhythm-heaven-breakdown-rc-devlog-1) |
| o touchpad no desktop Linux | o touchpad do DualSense move o cursor e clica | [Arch BBS 277941](https://bbs.archlinux.org/viewtopic.php?id=277941), [dev.to](https://dev.to/gordinmitya/disable-dualsence-touchpad-on-ubuntu-2j2i), [Universal Blue](https://universal-blue.discourse.group/t/disable-ps5-controller-touchpad/4140) |

O Tearaway pede formas livres e a crítica foi a precisão. O K1 pede 3 pontos com raio de acerto: a imprecisão cabe
no raio.

## O risco no Linux

1. **O touchpad move o cursor do desktop.** O kernel cria o dispositivo «Touchpad» com `INPUT_PROP_BUTTONPAD`
   ([hid-playstation.c](https://github.com/torvalds/linux/blob/master/drivers/hid/hid-playstation.c)), e o libinput o
   pega como touchpad de notebook. O clique vira clique do mouse, no jogo ou atrás dele. O parâmetro `touchpad_mouse`
   ([lore.kernel.org](https://lore.kernel.org/all/YnQBkd5V3lmC9cGr)) não entrou na linha principal. A cura é a
   propriedade udev `LIBINPUT_IGNORE_DEVICE=1` no event do Touchpad
   ([libinput](https://wayland.freedesktop.org/libinput/doc/latest/ignoring-devices.html)). A regra
   `udev/99-forja-dualsense.rules` só trata o hidraw. Instalar pede sudo.
2. **A proporção.** O touchpad tem 1920 × 1070, 1,8 para 1. Uma letra desenhada num quadrado fica achatada se o jogo
   mapear 0 a 1 nos dois eixos. Mapear com a mesma escala nos dois.
3. **As bordas.** O dedo perto da borda some antes de chegar ao fim. Manter os pontos a 10 % da borda. Medir na
   bancada: a menor distância da borda em que o dedo ainda é lido, nos 4 lados.

## As mágicas

### 1. O ponto se sente (`usa`)

- **Quem joga:** chegar ao ponto, dentro do raio, dá um tique de 150 Hz por 12 ms. O dedo acha o ponto sem olhar.
- **Os outros:** veem o ponto acender no quadro do tique.
- **Como se prova:** `Forja.robo_tocar(l, 0, x, y)` no ponto; `Forja.som_virtual(l)` tem um pico. Fora do raio, nada.
  Reprovam: `um-dedo` e `haptica-muda`.

### 2. A pedra sob o dedo (`usa`)

- **Quem joga:** a textura `pedra` enquanto o dedo arrasta, com o ganho de 0,15 a 0,5 conforme a velocidade. Parado,
  silêncio.
- **Os outros:** nada no controle deles.
- **Como se prova:** o robô arrasta em 5 toques seguidos de 0,06 s; a energia de `Forja.som_virtual(l).esq` passa de
  0,3. Com o dedo parado, fica abaixo de 0,1. Reprova: `haptica-muda`.

### 3. O desmolde dos quatro (`usa`)

- **Quem joga:** quando os quatro clicam o último ponto numa janela de 400 ms, os quatro controles batem juntos: 1,0
  por 120 ms, pausa de 120 ms, 0,7 por 120 ms.
- **Os outros:** são os outros. O molde se abre na TV no mesmo quadro.
- **Como se prova:** `Forja.robo_apertar(l, Forja.TOUCHPAD)` nos 4 lugares, com 100 ms entre o 1.º e o 4.º; nos 4,
  `Forja.percepcao(l).forte` segue 1,0, 0, 0,7. Com 500 ms, não. Reprova: `sem-clique`.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| a regra udev `LIBINPUT_IGNORE_DEVICE=1` no event do Touchpad, na ficha do arquiteto | o arquiteto escreve |
| instalar a regra (precisa de sudo) | a Vitória, na lista ESPERA-ELA |
| a borda medida nos 4 lados | a bancada F01 |
| o mapa com a mesma escala nos dois eixos | o designer de sistemas |
</content>
</invoke>
