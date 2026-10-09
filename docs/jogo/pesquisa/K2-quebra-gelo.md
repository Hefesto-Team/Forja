# K2, Quebra-Gelo: a pesquisa do DualSense

Slot S03_J12 · golpe no contratempo · o verbo é **riscar o touchpad de um lado ao outro num golpe só**. A
[ficha](../tarefas/K2-quebra-gelo.md), a [diversão](../diversao/K-o-molde.md) e o
[catálogo](dualsense.md#11-o-touchpad).

## O recurso

- **O risco:** o dedo anda 0,35 da largura num golpe, no contratempo. Conta quanto ele anda e para que lado, não onde
  está.
- **A textura `gelo`** na háptica.
- A troca da diversão: **o gelo vai para o líder**, com avalanche.

## O que se sabe fora

| jogo ou projeto | a técnica | a fonte |
| --- | --- | --- |
| Fruit Ninja (2010) | o corte é o risco do dedo na tela; conta a direção e o comprimento | [Wikipedia](https://en.wikipedia.org/wiki/Fruit_Ninja) |
| Rhythm Heaven (DS, 2008) | o piparote da caneta no tempo, julgado pelo instante e não pelo lugar | [devlog no itch.io](https://peaceful-illumination.itch.io/rhythm-cataclysm/devlog/168773/getting-back-into-development-rhythm-heaven-breakdown-rc-devlog-1) |
| Tearaway Unfolded (PS4, 2015) | deslizar no touchpad faz vento no mundo | [God is a Geek](https://www.godisageek.com/reviews/tearaway-unfolded-review/) |
| o touchpad no desktop Linux | o touchpad do DualSense move o cursor e clica | [Arch BBS 277941](https://bbs.archlinux.org/viewtopic.php?id=277941), [libinput](https://wayland.freedesktop.org/libinput/doc/latest/ignoring-devices.html) |

## O risco no Linux

1. **O touchpad move o cursor do desktop**, e o risco rápido vira arrasto do mouse. A cura é a mesma da
   [K1](K1-o-molde.md): `LIBINPUT_IGNORE_DEVICE=1` no event do Touchpad, com sudo.
2. **Um golpe rápido some entre quadros.** Um risco de 0,35 em 50 ms cabe em 3 quadros de 16,7 ms. Se o jogo lê só a
   posição no quadro, o primeiro e o último ponto podem cair fora. Medir o golpe pela primeira posição com o dedo e
   pela última antes de soltar, não pelo quadro. Medir na bancada: o menor tempo de golpe que o jogo ainda conta, em
   20 golpes.
3. **O dedo que solta e volta.** Um golpe na borda solta o dedo e o SDL dá um dedo novo. O defeito `um-dedo` cobre
   parte disso.

## As mágicas

### 1. A racha corre na mão (`usa`)

- **Quem joga:** o risco certo faz a háptica correr na direção do dedo em 80 ms: 40 ms no atuador de onde o dedo saiu
  e 40 ms no de chegada. O gelo racha dentro do controle.
- **Os outros:** veem a racha no gelo no mesmo quadro.
- **Como se prova:** `Forja.robo_tocar(l, 0, x, 0.5)` com x de 0,3 a 0,7 em 4 passos de 0,015 s, no contratempo;
  `Forja.som_virtual(l).esq` sobe antes de `.dir`. Ao contrário, o contrário. Reprovam: `haptica-trocada` e
  `um-dedo`.

### 2. O gelo vai para o líder (`usa`)

- **Quem joga:** o líder sente o gelo chegar: a textura `gelo` contínua, ganho 0,3, por 1 compasso, e um estalo de
  150 Hz por 12 ms a cada risco dos outros.
- **Os outros:** veem o gelo crescer em volta do líder e sabem que cada risco deles chega na mão dele.
- **Como se prova:** com o lugar 1 líder, os robôs 2, 3 e 4 riscam; `Forja.som_virtual(1)` tem energia contínua e um
  pico por risco; os lugares 2, 3 e 4 não têm a textura. Reprova: `som-vizinho`.

### 3. A avalanche (`usa`)

- **Quem joga:** quem solta a avalanche ouve o estrondo no próprio alto-falante. Os outros três sentem o motor forte
  subir de 0 a 1,0 em 600 ms e cair em 200 ms.
- **Os outros:** a sala ouve o estrondo sair de uma mão só e sente a avalanche nas outras.
- **Como se prova:** no quadro da avalanche, `Forja.som_virtual(l).falante` passa de 0,3 só no causador e
  `Forja.percepcao(l).forte` chega a 1,0 nos outros três em 600 ms. Reprovam: `vibra-vizinho` e `sem-alto-falante`.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| a regra udev do Touchpad e a instalação com sudo | o arquiteto escreve; a Vitória instala |
| medir o golpe pela primeira e pela última posição do dedo, não pelo quadro | o designer de sistemas |
| o menor tempo de golpe medido | a bancada F01 |
| o estalo do gelo e a avalanche na bíblia de háptica | o diretor de som e háptica |
</content>
</invoke>
