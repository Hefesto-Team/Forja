# I2, Marcha dos Escudeiros: a pesquisa do DualSense

Slot S01_J02 · corrida no tempo · o verbo é **marchar com os dois analógicos**. A
[ficha](../tarefas/I2-marcha-dos-escudeiros.md), a [diversão](../diversao/I-a-centelha.md) e o
[catálogo](dualsense.md#3-o-rumble-de-compatibilidade).

## O recurso

- **Os dois analógicos, alternados.** Um por tempo, os quatro juntos. O passo é cruzar −0,8 no Y vindo de acima de
  −0,5.
- A meta fica a 48 m. Na ladeira do pico, a esteira puxa 2,5 vezes mais.
- **O R2 fica `OFF`.** O rumble e a háptica são os únicos retornos do corpo.

## O que se sabe fora

| jogo ou projeto | a técnica | a fonte |
| --- | --- | --- |
| Mario Party (N64, 1998) | a rotação do analógico machucou palmas; mais de 90 queixas ao procurador de Nova York e luvas distribuídas | [TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/Trivia/MarioParty1), [Nintendo Life](https://nintendolife.com/news/2022/11/random-nintendo-doesnt-want-you-to-get-mario-party-blisters-this-time-around) |
| Mario Party Superstars (2021) | o aviso na tela «gire com o polegar» antes do minigame de analógico | [mynintendonews](https://mynintendonews.com/2021/10/26/tug-o-war-minigame-in-mario-party-superstars-includes-an-in-game-safety-warning/), [TechRaptor](https://Techraptor.net/gaming/news/oh-no-mario-party-superstars-minigames-have-joystick-rotating-controls) |
| Dungeon Dash (Mario Party 2 e Superstars, 2 contra 2) | cada jogador é uma perna e inclina o analógico; só os dois juntos avançam | [MarioWiki](https://www.mariowiki.com/Dungeon_Dash) |
| Control Schtick (Mario Party 6) | os dois analógicos são os dois braços | [MarioWiki](https://www.mariowiki.com/Control_Schtick) |
| a deriva do DualSense | o processo de 12/02/2021 no tribunal federal SDNY | [CNN](https://edition.cnn.com/2021/02/16/tech/sony-ps5-controller-drift-lawsuit), [Destructoid](https://destructoid.com/?p=264172) |

O I2 empurra, não gira: o risco do Mario Party é a palma. A lição é o aviso: polegar, não palma.

## O risco no Linux

1. **A diagonal pode não chegar a −0,8 no Y.** O SDL entrega o analógico em quadrado ou círculo conforme o driver.
   Num círculo, empurrar a 30° da vertical dá Y ≈ −0,87; a 40°, Y ≈ −0,77, e o passo não sai. Medir na bancada: o Y
   máximo a 0°, 20°, 30° e 40°, nos dois analógicos.
2. **A deriva.** Um analógico com repouso em −0,15 no Y está mais perto do limiar de rearme (−0,5). Se o repouso
   passar de −0,5, o passo nunca rearma e o jogador marcha só com um lado. Medir: o repouso de cada analógico no
   início da noite; avisar acima de 0,2.
3. **O rumble seco sob háptica.** O SDL corta a háptica por áudio quando há rumble (o catálogo). A ladeira não pode
   usar os dois.
4. **4 controles por USB no mesmo hub** abrem 4 placas de som (o
   [WirePlumber](https://gitlab.com/TYcommand/Gamepads/-/issues/11)). Não achei relato de falta de banda com 4
   DualSense; o caso parecido é áudio USB atrás de hub ([Arch BBS 177854](https://bbs.archlinux.org/viewtopic.php?id=177854)).
   Medir com `lsusb -t` e `dmesg` com os quatro ligados.

## As mágicas

### 1. O passo no pé certo (`usa`)

- **Quem joga:** cada passo certo bate no lado do analógico que marchou: o esquerdo vibra o atuador esquerdo, 90 Hz
  por 40 ms, ganho 0,5. O corpo sente esquerda, direita, esquerda.
- **Os outros:** veem o escudeiro dar o passo no mesmo quadro.
- **Como se prova:** o robô faz `Forja.robo_eixo(l, Forja.LY, -0.9)` no tempo 1 e `Forja.robo_eixo(l, Forja.RY, -0.9)` no tempo 2;
  `Forja.som_virtual(l).esq` tem energia no tempo 1 e `.dir` no tempo 2. Os defeitos `analogico-curto` (o robô chega
  só a −0,7) e `haptica-trocada` têm de reprovar.

### 2. A ladeira pesa na mão (`usa`)

- **Quem joga:** na ladeira do pico, o rumble forte sobe de 0 para 0,6 em 2 tempos e fica enquanto a esteira puxa 2,5
  vezes. Arrastado na ladeira (o grito), o controle pesa.
- **Os outros:** veem a esteira acelerar e o escudeiro escorregar.
- **Os números:** `Forja.vibrar(l, 0.6, 0.0, ms)`, renovado a cada tempo. Na ladeira o passo da mágica 1 sai da
  háptica e vai para o motor fraco, 0,4 por 40 ms, porque o SDL corta a háptica por áudio sob rumble.
- **Como se prova:** o robô para de marchar na ladeira; `Forja.percepcao(l).forte` sobe para 0,6 e `fraco` só pulsa no passo. O
  defeito `motores-trocados` tem de reprovar.

### 3. O aviso do polegar (`usa`)

- **Quem joga:** antes da 1.ª frase, a tela mostra «Empurre com o polegar» por 2 tempos, com o desenho do polegar
  empurrando. Copia o aviso do Superstars.
- **Os outros:** a mesma tela para os quatro.
- **Como se prova:** a prova visual F09 confere que o texto aparece por 2 tempos antes da primeira nota. Nenhum
  defeito do gauntlet cobre isso.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| o Y máximo nas diagonais e o repouso de cada analógico | a bancada F01 |
| o aviso de deriva acima de 0,2 no início da noite | o arquiteto |
| a medição dos 4 DualSense no mesmo hub (`lsusb -t`, `dmesg`) | o arquiteto, na bancada |
| o texto do aviso do polegar | o diretor de jogo |
</content>
</invoke>
