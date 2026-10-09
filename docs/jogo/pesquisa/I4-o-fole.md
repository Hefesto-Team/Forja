# I4, O Fole: a pesquisa do DualSense

Slot S01_J04 · acorde a quatro · o verbo é **afundar o R2 até a altura da própria nota**. A
[ficha](../tarefas/I4-o-fole.md), a [diversão](../diversao/I-a-centelha.md) e o
[catálogo](dualsense.md#7-o-degrau-da-nota).

## O recurso

- **A profundidade do R2 é a nota.** As faixas: P1 0,30, P2 0,48, P3 0,66, P4 0,84, cada uma ±0,07.
- **A nota** é entrar na faixa e segurar 1 tempo, com ±0,02 de folga.
- **O `FEEDBACK`** nas zonas [2, 4, 5, 7], força 4: a parede começa na nota de cada lugar.
- O acorde dos quatro fecha a chama. O grito: a forja chega ao branco.

## O que se sabe fora

| jogo ou projeto | a técnica | a fonte |
| --- | --- | --- |
| Astro Bot (2024) | a esponja que se espreme pelo gatilho adaptativo | [TechRadar](https://www.techradar.com/gaming/consoles-pc/team-asobi-says-astro-bot-will-push-the-dualsense-controller-to-a-new-level), [Push Square](https://www.pushsquare.com/features/preview-astro-bot-on-ps5-could-be-the-best-3d-platformer-this-side-of-nintendo) |
| Astro's Playroom (2020) | o foguete: o gatilho vibra e cresce até soltar | [PlayStation Country](https://playstationcountry.com/astros-playroom-ps5-review), [GameSkinny](https://www.gameskinny.com/0w47r/astros-playroom-review-pure-imaginative-fun) |
| 1-2-Switch, Safe Cracker (2017) | girar até sentir o clique do segredo no HD rumble | [Looper](https://looper.com/40850/1-2-switch-includes-safe-cracking-crying-baby-simulators) |
| o gerador do Nielk1 (rev. 6) | o `FEEDBACK` de zona 0 a 9 e força 0 a 8; o modo de várias posições | [gist](https://gist.github.com/Nielk1/6d54cc2c00d2201ccb8c2720ad7538db), MIT |
| `isteamdualsense.h` (Steamworks no Proton) | lista o `MULTIPLE_POSITION_FEEDBACK` | [Proton](https://github.com/ValveSoftware/Proton/blob/proton_9.0/lsteamclient/steamworks_sdk_165/isteamdualsense.h), só leitura |

## O risco no Linux

1. **A zona contra o eixo não tem medida.** A ficha supõe as zonas [2, 4, 5, 7] para 0,30, 0,48, 0,66 e 0,84. O
   catálogo, na mágica 7, usa [2, 4, 6, 8]. As duas tabelas não batem, e nenhuma foi medida. Medir na bancada F01:
   o eixo em que a parede começa, zona por zona, em 3 controles.
2. **Segurar ±0,02 por 1 tempo.** O eixo do gatilho tem 8 bits, um passo de 0,004. O tremor do dedo contra uma parede
   de força 4 não está medido. Medir: o desvio do eixo parado na parede, por 500 ms, em 10 tentativas por pessoa.
3. **A trava do Edge.** Com a trava curta, a faixa P4 (0,84) não chega. Quem cai em P4 com um Edge travado perde a
   nota sem saber por quê. O aviso da trava falta (o catálogo).
4. **A opção «gatilho fraco»** corta a força pela metade: força 4 vira 2. A parede fica macia e a faixa some do dedo.

## As mágicas

### 1. A parede na nota (`usa`)

- **Quem joga:** o `FEEDBACK` começa na zona da nota dele. Afundar até a parede é achar a nota sem olhar a barra. É a
  meia mágica 7 do catálogo, sem a emenda.
- **Os outros:** ouvem a nota de cada um subir no alto-falante do dono quando ele entra na faixa.
- **Como se prova:** o robô faz `Forja.robo_eixo(l, Forja.R2, 0.48)` por 1 tempo; a nota conta. Com 0,40, não conta.
  `Forja.percepcao(l).gatilho_dir` é `0x21`. Reprovam: `gatilho-mudo` e `gatilho-digital`. A zona só se prova quando
  `percepcao` expuser os 11 bytes.

### 2. A chama acorda no dedo (`usa`)

- **Quem joga:** quando o acorde fecha, o R2 passa a `VIBRATION` na zona da nota, amplitude 3, 40 Hz, por 1 compasso.
  O fogo ronca no dedo dos quatro ao mesmo tempo.
- **Os outros:** veem a forja ir ao branco no mesmo quadro.
- **Como se prova:** os 4 robôs seguram as 4 faixas por 1 tempo; nos 4 lugares, `Forja.percepcao(l).gatilho_dir` vai
  de `0x21` a `0x26` no mesmo quadro e volta em 1 compasso. Reprova: `gatilho-mudo`.

### 3. O degrau da nota (`emenda`)

- **Quem joga:** a mágica 7 inteira: com `MULTIPLE_POSITION_FEEDBACK`, um dente de força 6 na zona da nota e força 1 no
  resto do curso. A nota vira um degrau que o dedo sente passar.
- **Os outros:** os mesmos da mágica 1.
- **Como se prova:** precisa da emenda e dos 11 bytes em `percepcao`: o byte do modo e a máscara de forças por zona
  conferem com a tabela da nota.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| qual tabela vale, [2, 4, 5, 7] da ficha ou [2, 4, 6, 8] do catálogo, depois da medida | o designer de sistemas, com a medida da bancada F01 |
| a emenda `MULTIPLE_POSITION_FEEDBACK` | a Vitória decide; o arquiteto escreve |
| expor os 11 bytes do gatilho em `percepcao` | o arquiteto |
| o que a opção «gatilho fraco» faz no Fole: força mínima de 3 na parede da nota | o diretor de jogo |
</content>
</invoke>
