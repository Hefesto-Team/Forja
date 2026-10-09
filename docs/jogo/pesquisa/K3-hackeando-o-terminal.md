# K3, Hackeando o Terminal: a pesquisa do DualSense

Slot S03_J13 · memória e chamada · o verbo é **tocar o quadrante certo na sua vez**. A
[ficha](../tarefas/K3-hackeando-o-terminal.md), a [diversão](../diversao/K-o-molde.md) e o
[catálogo](dualsense.md#2-o-segredo-no-ouvido).

## O recurso

- **Os 4 quadrantes do touchpad.** Cada nota da senha é de um jogador e de um quadrante.
- **O alto-falante do dono:** na chamada, a nota dele toca só no controle dele.
- O grito: a senha longa.

## O que se sabe fora

| jogo ou projeto | a técnica | a fonte |
| --- | --- | --- |
| Simon (Milton Bradley, 1978) | quatro quadrantes coloridos, cada um com um tom; repetir a sequência que cresce | [Wikipedia](https://en.wikipedia.org/wiki/Simon_(game)) |
| Death Stranding e Ghostwire: Tokyo | a voz que sai do alto-falante do controle | o catálogo, a mágica 2 |
| Hi-Fi Rush, versão de PS5 (2024) | a háptica refeita como parte da música | [TechRadar](https://www.techradar.com/gaming/hi-fi-rush-review) |
| o touchpad no desktop Linux | o touchpad do DualSense move o cursor e clica | [Arch BBS 277941](https://bbs.archlinux.org/viewtopic.php?id=277941), [libinput](https://wayland.freedesktop.org/libinput/doc/latest/ignoring-devices.html) |

O Simon toca a senha para todos. O K3 parte a senha em quatro ouvidos: cada um só ouve a própria nota.

## O risco no Linux

1. **O touchpad move o cursor do desktop.** A mesma cura da [K1](K1-o-molde.md), com sudo.
2. **A cruz do meio.** O touchpad tem 1920 × 1070. Um toque a 2 % da linha que separa os quadrantes cai num ou noutro
   conforme o tremor. Uma faixa neutra de 0,06 na largura e na altura evita a nota trocada. Medir na bancada: quantos
   toques mirados no centro de um quadrante caem no vizinho, em 40 toques por pessoa.
3. **Um som por vez por controle** (o [05](../05-haptica-e-controle.md)). Se a nota da senha e o tinido do acerto
   chegam juntos, um corta o outro. Separar 120 ms.
4. **4 alto-falantes por USB no mesmo hub** abrem 4 placas ([WirePlumber](https://gitlab.com/TYcommand/Gamepads/-/issues/11)).
   Medir com `lsusb -t`, `dmesg` e os 4 tocando juntos.

## As mágicas

### 1. O segredo no ouvido (`usa`)

- **Quem joga:** a nota dele toca só no alto-falante do controle dele, a `0x64`, pré-amp `2`. Com fone no controle, vai
  para o fone (essa parte `falta`: o bit do fone no byte 53).
- **Os outros:** veem a etiqueta do dono «falar» e não sabem que nota foi. Nasce o blefe.
- **Como se prova:** na chamada do lugar 2, `Forja.som_virtual(2).falante` passa de 0,3 e os outros três ficam abaixo de
  0,05. Reprovam: `som-vizinho` e `sem-alto-falante`.

### 2. O canto sob o dedo (`usa`)

- **Quem joga:** tocar um quadrante dá um tique de 150 Hz por 12 ms no atuador do lado dele: os quadrantes da
  esquerda no esquerdo, os da direita no direito.
- **Os outros:** nada no controle deles.
- **Como se prova:** `Forja.robo_tocar(l, 0, 0.25, 0.25)`; `Forja.som_virtual(l).esq` tem o pico e `.dir` não. Com
  x = 0,75, o contrário. Reprovam: `haptica-trocada` e `sem-clique`.

### 3. A senha corre em roda (`usa`)

- **Quem joga:** na senha longa, enquanto o terminal toca, cada controle dá um pulso de 80 Hz por 30 ms na nota do seu
  dono, ganho 0,35. É a mágica 3 do catálogo em chamada e resposta. A mão lembra a vez que o ouvido esquece.
- **Os outros:** os quatro controles pulsam em roda, na ordem da senha.
- **Como se prova:** com a senha 2, 4, 1, 3, `Forja.som_virtual` tem picos nos lugares 2, 4, 1 e 3, nessa ordem, um por
  tempo. Reprova: `haptica-muda`.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| a regra udev do Touchpad e a instalação com sudo | o arquiteto escreve; a Vitória instala |
| a faixa neutra de 0,06 na cruz do meio | o designer de sistemas |
| a ficha do fone no controle (o bit do byte 53 liga a rota `0`) | o arquiteto |
| os 4 alto-falantes no mesmo hub, medidos | a bancada F01 |
</content>
</invoke>
