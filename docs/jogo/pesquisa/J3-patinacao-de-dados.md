# J3, Patinação de Dados: a pesquisa do DualSense

Slot S02_J08 · corrida de direção · o verbo é **dirigir inclinando o controle**. A
[ficha](../tarefas/J3-patinacao-de-dados.md), a [diversão](../diversao/J-a-viga.md) e o
[catálogo](dualsense.md#10-o-giroscópio-e-o-acelerômetro).

## O recurso

- **A inclinação contínua dirige:** `x = clamp(rolagem / 0,35) · 1,1`. A 0,32 rad o patinador chega à borda.
- **A textura `gelo`** na háptica por áudio.
- A troca da diversão: **a pista de todos**, com trombada. O grito vem dela.

## O que se sabe fora

| jogo ou projeto | a técnica | a fonte |
| --- | --- | --- |
| Mario Kart Wii (2008) | o volante pela inclinação do controle | [Wikipedia](https://en.wikipedia.org/wiki/Mario_Kart_Wii) |
| Super Monkey Ball (2001) | a inclinação contínua leva a bola por pistas estreitas | [Wikipedia](https://en.wikipedia.org/wiki/Super_Monkey_Ball) |
| Astro's Playroom (2020) | o planador pela inclinação; a háptica muda com o chão | [PlayStation Country](https://playstationcountry.com/astros-playroom-ps5-review), [blog da PlayStation](https://blog.playstation.com/?p=343436) |
| o GyroWiki, de quem trouxe o giro ao Fortnite | o «tightening»: uma zona pequena perto do zero para o tremor não mexer | [GyroWiki](http://gyrowiki.jibbsmart.com/blog:good-gyro-controls-part-1:the-gyro-is-a-mouse), [Game Informer](https://gameinformer.com/2022/02/15/how-a-community-creator-helped-completely-revamp-fortnites-gyro-aiming-controls) |

## O risco no Linux

1. **A deriva.** A rolagem vem da fusão `postura()`. Uma deriva de 0,02 rad em 60 s puxa o patinador 6 % para o lado.
   Recentrar no início de cada frase. Medir na bancada: a deriva da rolagem parada por 60 s.
2. **O tremor da mão.** Sem zona morta, o tremor de ±0,01 rad mexe o patinador ±3 %. Uma zona de 0,02 rad perto do
   zero (o «tightening») resolve. Medir: o desvio da rolagem segurando parado, em 5 pessoas.
3. **O SDL corta a háptica por áudio sob rumble.** Se a trombada usar o motor, o gelo some por 60 ms. A trombada vai
   pela háptica também.
4. **O mapa de canais** varia por driver: a AnyPS5 usa os canais 4 e 5 com o pulseaudio (o catálogo). O gelo pode cair
   no alto-falante. O defeito `som-vizinho` não cobre a troca de canal; medir na bancada F01.

## As mágicas

### 1. A trombada vem do lado certo (`usa`)

- **Quem joga:** na pista de todos, trombar dá 0,8 por 60 ms no atuador do lado da batida. Quem foi batido pela
  esquerda sente na esquerda.
- **Os outros:** os dois que trombaram sentem ao mesmo tempo, em lados opostos. A sala vê a faísca e o riso vem junto.
- **Como se prova:** o robô do lugar 1 inclina à direita e o do lugar 2 à esquerda até se cruzarem;
  `Forja.som_virtual(1).dir` e `Forja.som_virtual(2).esq` passam de 0,5 no mesmo quadro. Reprovam: `haptica-trocada`
  e `giro-invertido`.

### 2. O gelo canta com a velocidade (`usa`)

- **Quem joga:** a textura `gelo` contínua, com o ganho de 0,15 parado a 0,5 na velocidade máxima. O patinador desliza
  na mão.
- **Os outros:** nada no controle deles; o som do gelo fica na TV.
- **Como se prova:** com o robô parado, a energia de `Forja.som_virtual(l).esq` é menor que 0,2; correndo, passa de
  0,4. Reprova: `haptica-muda`.

### 3. A borda raspa (`usa`)

- **Quem joga:** com `x` acima de 0,9, a textura do lado da borda vira cascalho. A mão sabe que vai cair.
- **Os outros:** veem a faísca na borda.
- **Como se prova:** o robô inclina 0,35 rad; `Forja.chao_do_envelope` do lado da borda devolve 1 (cascalho) e o do
  outro lado não. Reprova: `haptica-trocada`.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| recentrar a rolagem no início de cada frase e a zona de 0,02 rad | o arquiteto, na `postura()` |
| a deriva e o tremor medidos | a bancada F01 |
| a trombada pela háptica, não pelo motor, na bíblia de háptica | o diretor de som e háptica |
| o mapa de canais da háptica no pulseaudio e no PipeWire | o arquiteto, na bancada |
</content>
</invoke>
