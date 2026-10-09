# J4, O Balão dos Foles: a pesquisa do DualSense

Slot S02_J09 · dupla contra dupla · o verbo é **sacudir o controle, um no tempo e o parceiro no contratempo**. A
[ficha](../tarefas/J4-o-balao-dos-foles.md), a [diversão](../diversao/J-a-viga.md) e o
[catálogo](dualsense.md#10-o-giroscópio-e-o-acelerômetro).

## O recurso

- **O acelerômetro pelo pico:** a sacudida conta com 1,8 g. As duplas são Brasa e Maré.
- **Um sacode no tempo, o parceiro no contratempo.** A 120 bpm, cada um sacode a cada 500 ms (2 Hz).
- O grito: a ultrapassagem. A regra da seção: todo gesto forte é feito no ar.

## O que se sabe fora

| jogo ou projeto | a técnica | a fonte |
| --- | --- | --- |
| 1-2-Switch, Soda Shake (2017) | sacudir a garrafa e passar ao próximo antes de estourar | [Looper](https://looper.com/40850/1-2-switch-includes-safe-cracking-crying-baby-simulators), [1-2-Switch Wiki](https://nintendo-switch.fandom.com/wiki/1-2-Switch) |
| Dungeon Dash (Mario Party 2 e Superstars, 2 contra 2) | cada jogador é uma perna; só a alternância certa avança | [MarioWiki](https://www.mariowiki.com/Dungeon_Dash) |
| a alça do Wii (15/12/2006) | cerca de 2 milhões de alças trocadas depois de controles voarem contra TVs | [CPSC](https://www.cpsc.gov/Recalls/2006/nintendo-of-america-initiates-replacement-program-for-wrist-straps-used-with), [NBC](https://www.nbcnews.com/id/wbna16222369) |

O Dungeon Dash é a alternância a dois; o J4 só troca o analógico pelo sacode.

## O risco no Linux

1. **O cabo.** A Forja joga no cabo. Sacudir a 2 Hz por 60 s puxa o conector. Uma desconexão no meio cai no caminho
   de reconexão do [05](../05-haptica-e-controle.md). Medir na bancada: quantas desconexões em 5 minutos de sacode, com cabo de 2 m e com cabo de
   3 m.
2. **O acelerômetro satura em ±4 g** ([hid-playstation.c](https://github.com/torvalds/linux/blob/master/drivers/hid/hid-playstation.c)).
   Uma sacudida forte passa de 4 g; o pico achata, mas fica acima de 1,8 g. O simulador não satura.
3. **Um sacode, vários picos.** A pancada do simulador vale `sacode · G · |sin(40t)|`: em 200 ms são 2 ou 3 picos. A
   sacudida real também tem volta. Contar um sacode só quando o valor caiu abaixo de 1,3 g antes, como no pino da J1.
4. **O SDL corta a háptica por áudio sob rumble.** As mágicas abaixo usam só a háptica e o alto-falante.

## As mágicas

### 1. A vez do parceiro na mão (`usa`)

- **Quem joga:** cada sacode certo dá um pulso de 80 Hz por 30 ms, ganho 0,4, no controle **do parceiro**, meio tempo
  antes da vez dele. Quem sacode avisa quem vem. A dupla vira um fole só.
- **Os outros:** a outra dupla não sente nada; vê a dupla rival entrar no ritmo.
- **Como se prova:** `Forja.robo_sacudir(1, 1.8)` no tempo; `Forja.som_virtual(2)` tem pico no meio tempo seguinte, e
  os lugares 3 e 4 não. Reprovam: `acel-escala` e `som-vizinho`.

### 2. O sopro sobe no alto-falante (`usa`)

- **Quem joga:** cada sacode certo solta um «fuu» no alto-falante do dono, 1 semitom mais alto a cada 4 m de altura.
- **Os outros:** ouvem a dupla em roda, Brasa e Maré alternadas, e sabem pelo ouvido quem está subindo mais.
- **Como se prova:** os robôs 1 e 2 sacodem em tempo e contratempo; `Forja.som_virtual(1).falante` e
  `Forja.som_virtual(2).falante` alternam, 250 ms entre os picos. Reprova: `sem-alto-falante`.

### 3. A ultrapassagem sopra (`usa`)

- **Quem joga:** a dupla ultrapassada sente o vento: a háptica corre de um lado ao outro em 400 ms, ganho 0,6. É a
  mágica 9 do catálogo.
- **Os outros:** a dupla que passou ouve o tinido da vitória no próprio alto-falante.
- **Como se prova:** os robôs da dupla A sacodem certo e os da B erram; no quadro da ultrapassagem,
  `Forja.som_virtual` da dupla B tem `.esq` e `.dir` com 400 ms entre os picos. Reprova: `haptica-trocada`.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| a medida das desconexões do cabo sob sacode | a bancada F01 |
| o simulador saturar em 4 g | o arquiteto |
| o rearme abaixo de 1,3 g também na J4 | o designer de sistemas |
| a tela «no ar, para cima, cabo solto» antes da 1.ª frase | o diretor de jogo |
</content>
</invoke>
