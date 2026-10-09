# J5, Mira Óptica: a pesquisa do DualSense

Slot S02_J10 · tiro no tempo · o verbo é **mirar girando o controle e disparar com o R2 na batida**. A
[ficha](../tarefas/J5-mira-optica.md), a [diversão](../diversao/J-a-viga.md) e o
[catálogo](dualsense.md#5-o-gatilho-que-trava).

## O recurso

- **A guinada e a arfagem** levam a mira.
- **O tiro** é o R2 cruzar 75 % vindo de menos de 50 %, com `WEAPON` início 2, fim 6, força 8
  (`Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, 8)`).
- A falha embaça a mira. O L2 é do item. O grito: o escudo de ouro.

## O que se sabe fora

| jogo ou projeto | a técnica | a fonte |
| --- | --- | --- |
| Splatoon | 70 a 80 % dos jogadores ficam no giroscópio | [GamesBeat](https://gamesbeat.com/around-75-of-splatoon-players-use-the-gyroscope-control-method/) |
| o giro e o flick stick no Fortnite v19.30 (fev/2022) | o giro como mouse, com o recentrar | [Fortnite](https://www.fortnite.com/news/gyro-aiming-and-flick-stick-come-to-fortnite-in-v19-30-more-controller-options), [GyroWiki](http://gyrowiki.jibbsmart.com/blog:good-gyro-controls-part-1:the-gyro-is-a-mouse) |
| Deathloop e Returnal | o gatilho que trava quando a arma emperra; os dois estágios | o catálogo, a mágica 5 |
| o gerador do Nielk1 (rev. 6) | o `WEAPON`: início de 2 a 7, fim até 8 | [gist](https://gist.github.com/Nielk1/6d54cc2c00d2201ccb8c2720ad7538db), MIT |
| `nondebug/dualsense` | a fase do efeito no relatório de entrada | [GitHub](https://github.com/nondebug/dualsense) |

## O risco no Linux

1. **O clique e os 75 % podem não coincidir.** O `WEAPON` com fim na zona 6 solta a parede onde a zona 6 cair no
   eixo. Se cair em 60 %, o dedo sente o tiro em 60 % e o jogo julga em 75 %: 15 pontos de curso sem nada. Medir na
   bancada F01: o eixo no instante do clique do `WEAPON` 2→6.
2. **A trava do Edge** corta o fim do curso; com a trava curta, 75 % não chega.
3. **O coice entra na mira.** O rumble do tiro pode tremer o giro. O simulador não acopla. Medir: o desvio do giro nos
   100 ms depois de `vibrar(l, 0, 0.8, 40)`, com o controle parado.
4. **A deriva.** 60 s de mira acumulam deriva na guinada. O Splatoon recentra com um botão; aqui, o recentrar entra
   no R3. Medir: a deriva da guinada parada por 60 s.
5. **O Steam Input** pode transformar o giro em mouse. Conferir que o jogo recebe o DualSense cru.

## As mágicas

### 1. O coice sem tremer a mira (`usa`)

- **Quem joga:** cada tiro dá o motor fraco a 0,8 por 40 ms. Nos 60 ms depois do tiro, a mira ignora o giro abaixo de
  0,3 rad/s, para o coice não tremer a mira.
- **Os outros:** veem o clarão do tiro no quadro do clique.
- **Como se prova:** o robô cruza o R2 de 0,4 a 0,8 com `Forja.robo_eixo(l, Forja.R2, 0.8)`;
  `Forja.percepcao(l).fraco` vai a 0,8 por 40 ms e `.gatilho_dir` é `0x25`. Reprovam: `gatilho-digital`,
  `motores-trocados` e `gatilho-mudo`. O tremor do coice só se prova com o defeito «vibração no giro» no simulador.

### 2. O escudo de ouro (`usa`)

- **Quem joga:** acertar o escudo de ouro dá o batimento da vitória: 1,0 por 120 ms, pausa de 120 ms, 0,7 por 120 ms,
  e o tinido de ouro no alto-falante do dono.
- **Os outros:** ouvem o tinido vir da mão de quem acertou e olham para ela.
- **Como se prova:** o robô mira e atira no alvo de ouro; `Forja.percepcao(l).forte` segue 1,0, 0, 0,7 e
  `Forja.som_virtual(l).falante` passa de 0,3. Reprova: `som-vizinho`.

### 3. O tiro é o clique (`falta`)

- **Quem joga:** a mágica 5 do catálogo: o tiro conta no instante em que a fase do `WEAPON` passa de 1 para 2 (o byte
  41 do relatório cru), não quando o eixo cruza 75 %. O dedo e o jogo concordam.
- **Os outros:** os mesmos da mágica 1.
- **Como se prova:** o simulador precisa escrever a fase nos bytes 41 e 42 do relatório que ele finge, conforme o eixo
  do robô cruza a zona do fim. Hoje não confirmei se o pad simulado tem esses bytes.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| ler a fase do efeito (bytes 41 e 42) no módulo e no simulador | o arquiteto |
| o eixo no instante do clique do `WEAPON` 2→6 e o tremor do coice no giro | a bancada F01 |
| o recentrar no R3 | o diretor de jogo |
| o defeito «vibração no giro» no simulador | o arquiteto |
</content>
</invoke>
