# J1, A Viga: a pesquisa do DualSense

Slot S02_J06 · equilíbrio · o verbo é **inclinar o controle contra o empurrão da viga e cravar o pino**. A
[ficha](../tarefas/J1-a-viga.md), a [diversão](../diversao/J-a-viga.md) e o
[catálogo](dualsense.md#10-o-giroscópio-e-o-acelerômetro).

## O recurso

- **A postura.** Rolagem e arfagem de 0,25 rad ou mais. O volante, de 1,2 rad/s ou mais, sai depois da 1.ª frase (a
  diversão).
- **O pino.** Uma pancada de 1,8 g vinda de menos de 1,3 g, a cada 16 batidas.
- **O R2 endurece com o perigo:** `RESISTENCIA` zona 0, força `2 + 2·perigo`.
- O metal range no alto-falante. O grito: o pino dos quatro. A regra da seção: todo gesto forte é feito no ar.

## O que se sabe fora

| jogo ou projeto | a técnica | a fonte |
| --- | --- | --- |
| Super Monkey Ball (2001) | inclinar o mundo para levar a bola | [Wikipedia](https://en.wikipedia.org/wiki/Super_Monkey_Ball) |
| Mario Kart Wii (2008) | o volante pela inclinação do controle | [Wikipedia](https://en.wikipedia.org/wiki/Mario_Kart_Wii) |
| Astro's Playroom (2020) | o planador dirigido pela inclinação | [PlayStation Country](https://playstationcountry.com/astros-playroom-ps5-review) |
| a alça do Wii (15/12/2006) | cerca de 2 milhões de alças trocadas depois de controles voarem contra TVs | [CPSC](https://www.cpsc.gov/Recalls/2006/nintendo-of-america-initiates-replacement-program-for-wrist-straps-used-with), [NBC](https://www.nbcnews.com/id/wbna16222369) |
| Until Dawn, PC (2024) | um relato de quem falhava o «Don't Move» segurando parado e culpava a vibração | [Steam](https://steamcommunity.com/app/2172010/discussions/0/4851030529135895077), um relato só |

O DualSense não tem alça. A regra «no ar» da seção J vem da alça do Wii: a pancada é para cima, não para a frente.

## O risco no Linux

1. **O acelerômetro satura em ±4 g** (`DS_ACC_RANGE` = 4 × 8192 no
   [hid-playstation.c](https://github.com/torvalds/linux/blob/master/drivers/hid/hid-playstation.c)). O pino pede 1,8 g;
   uma pancada animada passa de 4 g e o pico fica achatado, sem dano ao limiar. O simulador não satura: a prova não vê
   o achatamento.
2. **A vibração entra no IMU.** O R2 em resistência não vibra, mas o rumble e a háptica sim. Se o metal range na
   háptica no quadro do pino, o acelerômetro pode ler o tremor. O simulador não acopla a vibração no IMU. Medir na
   bancada: o desvio do acelerômetro parado com o motor forte a 0, 0,5 e 1,0.
3. **A deriva do giro.** A postura vem da fusão `postura()`; 60 s de viga sem recentrar acumulam deriva. O catálogo
   pede o «zerar» por gesto. Medir: a deriva da rolagem parada por 60 s.
4. **O Steam Input** pode tomar o giroscópio e mandar mouse. Conferir que o jogo recebe o DualSense cru.

## As mágicas

### 1. A viga pende na mão (`usa`)

- **Quem joga:** a háptica bate do lado para onde a viga pende, a cada tempo, 80 Hz por 30 ms. O ganho cresce de 0 a
  0,6 conforme a rolagem vai de 0 a 0,25 rad. O corpo sabe para onde cai antes de olhar.
- **Os outros:** veem a viga balançar no mesmo quadro.
- **Como se prova:** `Forja.robo_girar` a 0,5 rad/s no eixo da rolagem por 0,6 s inclina 0,3 rad para um lado;
  `Forja.som_virtual(l).esq` passa de `.dir` nos tempos seguintes. Reprovam: `giro-invertido` e `haptica-trocada`.

### 2. O pino dos quatro (`usa`)

- **Quem joga:** quando os quatro cravam o pino numa janela de 400 ms, os quatro controles batem juntos: 1,0 por
  120 ms, pausa de 120 ms, 0,7 por 120 ms. É a mágica 8 do catálogo, dentro do minigame.
- **Os outros:** são os outros. A viga trava no lugar e a fita solta faísca.
- **Os números:** 50 ms antes da janela do pino, o rumble e a háptica calam, para o tremor não entrar no acelerômetro.
- **Como se prova:** `Forja.robo_sacudir(l, 1.8)` nos 4 lugares, com 100 ms entre o 1.º e o 4.º; nos 4,
  `Forja.percepcao(l).forte` segue 1,0, 0, 0,7. Com 500 ms entre eles, não bate. Reprova: `acel-escala`.

### 3. O metal range no dedo (`usa`)

- **Quem joga:** a força do R2 sobe com o perigo, de 2 a 6, e o rangido do metal sai do alto-falante do dono quando o
  perigo passa de 0,5.
- **Os outros:** ouvem a viga de quem está em perigo ranger na mão dele.
- **Como se prova:** com o robô inclinado a 0,3 rad, `Forja.percepcao(l).gatilho_dir` é `0x21` e
  `Forja.som_virtual(l).falante` passa de 0,3. A força só se prova com os 11 bytes. Reprovam: `gatilho-mudo` e
  `sem-alto-falante`.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| o simulador saturar o acelerômetro em 4 g e ganhar o defeito «vibração no giro» | o arquiteto |
| a medida do tremor no acelerômetro com o motor ligado | a bancada F01 |
| o «zerar» por gesto antes da 1.ª frase | o arquiteto |
| os 50 ms de silêncio antes do pino | o diretor de som e háptica |
| a tela de segurança «no ar, para cima» antes da seção J | o diretor de jogo |
</content>
</invoke>
