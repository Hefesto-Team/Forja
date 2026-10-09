# J2, Pêndulos do Caos: a pesquisa do DualSense

Slot S02_J07 · golpe de pulso · o verbo é **girar o controle rápido no ápice do pêndulo**. A
[ficha](../tarefas/J2-pendulos-do-caos.md), a [diversão](../diversao/J-a-viga.md) e o
[catálogo](dualsense.md#10-o-giroscópio-e-o-acelerômetro).

## O recurso

- **O giro rápido** de 2,5 rad/s ou mais, para o centro, no ápice do arco.
- **O fantasma** sopra vento no líder, que passa a precisar de 3,5 rad/s.
- **O R2** fica em `RESISTENCIA` zona 0, força 6, quando o perigo é 1.
- O grito: o arremesso.

## O que se sabe fora

| jogo ou projeto | a técnica | a fonte |
| --- | --- | --- |
| WarioWare: Move It! (2023) | as Formas: poses e golpes de pulso; a leitura falha se a pose inicial estiver errada | [GamingTrend](https://gamingtrend.com/reviews/warioware-move-it-review-detrimental-discombobulation/), [TechRadar](https://www.techradar.com/gaming/nintendo-switch/warioware-move-it-review-innovative-and-ambitious) |
| o flick stick e o giro no Fortnite v19.30 (fev/2022) | o giro lido no espaço do jogador, não no do controle | [Fortnite](https://www.fortnite.com/news/gyro-aiming-and-flick-stick-come-to-fortnite-in-v19-30-more-controller-options), [Game Informer](https://gameinformer.com/2022/02/15/how-a-community-creator-helped-completely-revamp-fortnites-gyro-aiming-controls) |
| JoyShockMapper e o GyroWiki | o «player space»: o giro lido em relação à gravidade, não ao controle | [GyroWiki](http://gyrowiki.jibbsmart.com/blog:player-space-gyro-and-alternatives-explained), [JoyShockMapper](https://github.com/Electronicks/JoyShockMapper/releases/tag/v3.2.0), MIT |

O WarioWare mostra a pose antes de cada golpe. É a mesma cura para a pose errada aqui.

## O risco no Linux

1. **O eixo do giro depende de como se segura.** Quem segura o controle em pé gira no eixo da guinada; quem segura
   deitado gira na rolagem. Ler no espaço do jogador (o JoyShockMapper): a soma do giro projetada na vertical da
   gravidade. Medir na bancada: o eixo dominante do golpe em 5 pessoas.
2. **O limiar de 2,5 rad/s é 143 °/s.** Um gesto distraído passa disso. O giro satura em ±2048 °/s (35,7 rad/s, o
   `DS_GYRO_RANGE` do [hid-playstation.c](https://github.com/torvalds/linux/blob/master/drivers/hid/hid-playstation.c)),
   longe dos 3,5 rad/s: não há risco de corte. Medir: o pico de giro sem querer, segurando o controle por 60 s.
3. **A 250 Hz no cabo**, um golpe de 50 ms tem 12 amostras. Basta. O ruído do simulador é ±0,005 rad/s; o real não
   está medido.
4. **A vibração entra no giro.** O R2 em resistência não vibra; o rumble sim. O simulador não acopla. Medir com o motor
   forte a 1,0: o desvio do giro parado.

## As mágicas

### 1. O vento do fantasma (`usa`)

- **Quem joga:** o líder sente o vento: a háptica corre do lado do fantasma para o outro em 400 ms, a cada 2 tempos,
  ganho 0,5. É a mágica 9 do catálogo. Ele sabe que o limiar subiu para 3,5 rad/s sem ler nada.
- **Os outros:** veem o fantasma soprar no líder e torcem.
- **Como se prova:** com o lugar 1 líder, `Forja.som_virtual(1).esq` e `.dir` alternam com 400 ms entre os picos; nos
  outros lugares, nada. O robô com 3,0 rad/s acerta nos outros e erra no líder. Reprovam: `haptica-trocada` e
  `som-vizinho`.

### 2. O arremesso atravessa a sala (`usa`)

- **Quem joga:** o arremessador sente o motor fraco a 1,0 por 60 ms no golpe. O alvo sente o forte a 0,8 por 120 ms,
  300 ms depois, quando o pêndulo chega.
- **Os outros:** veem o pêndulo voar de um cavaleiro ao outro e a mão do alvo tremer na hora da batida.
- **Como se prova:** `Forja.robo_girar` a 3,0 rad/s por 0,06 s no ápice; `Forja.percepcao(l).fraco` vai a 1,0 no
  arremessador e, 300 ms depois, `forte` a 0,8 no alvo. Reprovam: `motores-trocados` e `vibra-vizinho`.

### 3. O ápice no pulso (`usa`)

- **Quem joga:** no ápice, um tique de 150 Hz por 12 ms nos dois atuadores marca o instante do golpe. Só na 1.ª frase;
  depois, o tique sai e o golpe vem de memória.
- **Os outros:** nada no controle deles.
- **Como se prova:** `Forja.som_virtual(l)` tem um pico em cada ápice da 1.ª frase e nenhum na 2.ª. Reprova:
  `haptica-muda`.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| ler o golpe no espaço do jogador (a projeção na gravidade) | o arquiteto, na `postura()` |
| o eixo dominante do golpe em 5 pessoas e o pico de giro sem querer | a bancada F01 |
| o defeito «vibração no giro» no simulador | o arquiteto |
| a pose mostrada antes da 1.ª frase | o diretor de jogo |
</content>
</invoke>
