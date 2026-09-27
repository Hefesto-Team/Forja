# As salas — o que cada uma pede, mede e decide

O Salão da Forja é o hub da Hefesto Tech Demo (ver [ADR-002](adr/002-hubs-e-salas.md)).
Cada porta é uma sala; cada sala é um jeito que os jogos comerciais usam o
DualSense, jogado de verdade — e, enquanto se joga, a sala mede o que chegou do
controle e dá, por jogador, um veredito para cada feature que ela valida.

Três vereditos, e só três:

| veredito | quando |
| --- | --- |
| **PASSOU** | a sala viu o comportamento inteiro |
| **FALHOU** | a sala pediu, o controle estava vivo (outras coisas chegavam) e o que chegou foi pouco ou torto — o `medido` diz o quê |
| **NÃO MEDIDO** | não houve como saber: o controle não mexeu nada, não publica a capacidade (um pad Xbox não tem giroscópio) ou a sala não chegou a pedir |

**FALHOU só com evidência.** Se o jogador não alcançou uma parte da sala (não
chegou à pedra da Viga, não chegou ao carimbo do Molde), a feature daquela
parte fica NÃO MEDIDO, com o porquê. Um defeito no começo da sala não reprova,
em cascata, o que vem depois.

Todo veredito vai para o livro (a tela do relatório), para o
`relatorio-<sessão>.json` e `.txt`, e para a linha do tempo
`linha-do-tempo-<sessão>.jsonl` (eventos `"tipo": "veredito"`). As entradas
que chegam pela primeira vez viram eventos `"tipo": "entrada"`.

Cada sala entra com o defeito que ela tem de pegar (`--defeito`, ver
[ADR-003](adr/003-o-gauntlet.md)); `scripts/gauntlet.sh` confere todos.

---

## A Centelha — runas que acendem ao apertar

**O padrão:** o QTE e o jogo de ritmo. Cada jogador tem a sua pedra; a runa
acende com um símbolo e o anel em volta vai se apagando.

**Como jogar:** aperte o botão da runa antes do anel apagar. Na runa de um
analógico, gire-o em volta até a borda (as oito marcas acendem). No fole,
segure L2 (ou R2) dentro da faixa dourada e depois aperte até o fundo. A fila
de cada jogador passa por todos os botões que um jogo usa — ✕ ○ □ △, L1, R1,
L3, R3, as quatro setas e o Create —, pelos dois analógicos e pelos dois
gatilhos, numa ordem sorteada pela semente. Runa perdida volta para o fim da
fila (até três vezes).

O Options é a pausa; o PS fica de fora (o sistema costuma tomá-lo); o botão do
microfone é da Cripta; o clique do touchpad é do Molde.

| feature | PASSOU | FALHOU |
| --- | --- | --- |
| Botões | os 13 chegaram, cada um com a runa dele acesa | um botão pedido nunca chegou; ou chegava **outro** no lugar dele (duas vezes ou mais, e nunca ele na hora): o mapa dos botões está trocado |
| Analógicos | cada analógico chegou à borda (85%) nas oito direções | o círculo foi pedido e o analógico não chegou à borda em todas as direções (curso cortado), ou nunca se mexeu |
| Gatilhos analógicos | cada gatilho foi de ≤ 8% a ≥ 90%, passando por pelo menos 8 níveis | chegou digital (só solto e no fundo), não chega ao fundo, não volta ao zero, ou passa por poucos níveis |

A deriva dos analógicos é medida no aviso da sala ("solte os analógicos"): se
um deles fica acima de 12% solto, vira observação.

**Defeitos que ela pega:** `troca-cruz-circulo`, `analogico-curto`,
`gatilho-digital`.

## A Viga — equilíbrio e mira por movimento

**O padrão:** o equilíbrio por inclinação dos jogos de plataforma e a mira por
giroscópio dos jogos de tiro. Três trechos:

1. **a travessia** — o autômato anda sozinho pela viga e o vento empurra;
   incline o controle para o lado contrário (rolagem). Cair volta ao último
   ponto de retorno;
2. **os sinos** — gire o controle para mirar (guinada e arfagem), R1 ou ✕
   arremessa o martelo, L1 centraliza a mira;
3. **a pedra** — uma martelada: sacuda o controle para baixo.

| feature | PASSOU | FALHOU |
| --- | --- | --- |
| Giroscópio | os três eixos passaram de 0,5 rad/s, chegam ≥ 60 amostras por segundo e o giro anda para o mesmo lado da gravidade | o sinal de um eixo chega invertido; um eixo pedido nunca girou; a taxa é baixa demais para mirar; o controle diz ter giroscópio e não manda nada |
| Acelerômetro | parado, mede 1 g (± 15%); a gravidade viu ao menos 20° de inclinação; a martelada (pico ≥ 1,8 g) chegou | a escala está errada (parado não dá 1 g); a inclinação não aparece; a martelada foi pedida e não chegou |

O `medido` do giroscópio traz, lado a lado, a taxa que o SDL **declara** e a
que **chega** — pelo relógio do computador e pelo relógio do próprio controle
(o `sensor_timestamp`). A diferença acima de 20% vira observação: é o que o
Hefesto quer ver de um DualSense virtual.

**O sinal:** a cada 0,3 s a sala compara quanto o giro integrado andou com
quanto o ângulo da gravidade andou (rolagem e arfagem). Janelas em que os dois
andam mais de 4° votam "concorda" ou "discorda"; com três votos ou mais, dois
contra um decide. Um intermediário que troque o sinal de um eixo aparece aqui.

Sem giroscópio (um pad Xbox por uinput, por exemplo), a sala joga com os
analógicos e o ✕, e o veredito é NÃO MEDIDO com a origem do controle.

**Defeitos que ela pega:** `giro-invertido`, `acel-escala`.

## O Molde — desenhar e moldar no touchpad

**O padrão:** os três usos do touchpad nos jogos. Três passos:

1. **traçar** — uma letra grega (zeta, lambda, sigma, eta, mi) aparece no
   molde; toque os pontos na ordem;
2. **abrir** — dois dedos no touchpad: afaste até o molde abrir e junte até
   ele fechar;
3. **carimbar** — o metal esquenta e esfria; clique o touchpad quando ele
   brilhar, três vezes.

| feature | PASSOU | FALHOU |
| --- | --- | --- |
| Touchpad, dois dedos | dois dedos ao mesmo tempo, a letra completa, os toques cobriram ≥ 60% da largura e ≥ 45% da altura, e os dedos abriram (≥ 45% da largura) e fecharam (≤ 15%) | no passo dos dois dedos, só um chegou; a letra não foi completada (algum canto não chega); a área coberta é pequena (escala ou recorte errados); dois dedos chegaram mas não andam separados |
| Touchpad, clique | o clique chegou | no carimbo, com o controle vivo, o clique nunca chegou |

As distâncias do touchpad são medidas em larguras dele, com a altura valendo
meia largura (o touchpad do DualSense é cerca de duas vezes mais largo que
alto).

**Defeitos que ela pega:** `um-dedo`, `sem-clique`.

---

## As salas de saída: a prova às cegas

Uma saída — vibração, cor, gatilho, LED — o jogo não mede sozinho. Ele sabe o
que **montou** (o payload existe) e se o SDL **aceitou** a chamada (saiu), mas
não se o plástico obedeceu. Quem sabe é quem segura o controle, desde que não
possa adivinhar pela tela. Então as salas de saída escondem a resposta e
perguntam; a estatística decide com folga para o acaso (passar chutando é
improvável), e o inconclusivo vira NÃO MEDIDO com o pedido de refazer. O
veredito dessas salas leva o nível **obedeceu** no relatório.

## O Cerco — dano direcional e a vida na luz

**O padrão:** os jogos de ação do PS5 — o tiro da esquerda treme **só** o
motor da esquerda, a lightbar pisca vermelho no golpe e apaga conforme a vida
cai. (A lightbar do DualSense é uma cor só para as duas fendas: o lado vem do
motor; a luz inteira pisca.)

**Como jogar:** no escuro, os golpes vêm um de cada vez, para um controle só.
A tela não diz de que lado (o aviso "!" não tem lado, e o som sai no meio):
sinta no controle e levante o escudo — L1 esquerda, R1 direita. Só depois da
resposta a tela mostra o golpe voando e batendo no escudo ou no autômato. Cada
jogador leva cinco golpes de cada lado, em três ondas; no fim de cada onda, a
luz de cada controle acende uma cor sorteada (âmbar, ciano, violeta ou branco)
e a pessoa diz qual é, olhando o plástico.

| feature | PASSOU | FALHOU |
| --- | --- | --- |
| Motor forte (esquerda) | 4 de 5 golpes da esquerda (80%) bloqueados do lado certo | três ou mais do lado errado e mais erros que acertos: os motores chegam **trocados**; ou três ou mais sem resposta: o motor **não chega** |
| Motor fraco (direita) | o mesmo, para a direita | o mesmo |
| Vibração só no controle certo | no máximo um escudo levantado com o golpe indo para **outro** controle, e ao menos 60% dos próprios golpes sentidos | três ou mais escudos "fantasma" (este controle vibrou com o golpe de outro); ou menos da metade dos próprios golpes sentidos (a vibração dele foi para outro) |
| Lightbar | três cores certas com no máximo uma errada | duas erradas (e não mais certas que erradas) |

Sozinho na mesa, o isolamento fica NÃO MEDIDO: não há vizinho para a vibração
vazar. Se a intensidade da vibração estiver baixa na pausa, a sala avisa e o
veredito diz o valor.

**Defeitos que ela pega:** `motores-trocados`, `vibra-vizinho`, `luz-parada`.

## A Galeria — armas com gatilho adaptativo

**O padrão:** os jogos de tiro do PS5 — cada arma com o seu gatilho, e a
munição nas cinco luzinhas brancas embaixo do touchpad (os LEDs de jogador).
Quando a munição acaba, o gatilho solta ("clique seco") até recarregar.

**Como jogar:** a arma chega no escuro. Aperte R2 e sinta: **parede e clique**
é a pistola (modo Weapon), **tremor** é a metralhadora (Vibration), **peso** é
o arco (Feedback) e **solto** é sem arma (Off). Diga qual é — ✕ pistola, ○
metralhadora, □ arco, △ sem arma — e a caixa abre. Depois, atire nos alvos
(analógico esquerdo mira, R2 atira; □ recarrega). No fim da rodada, o armeiro
recarrega sem ninguém ver e a pessoa conta as luzinhas do controle: quantas
balas restam? Cada arma aparece duas vezes, em ordem sorteada, e a que ficar
no meio do caminho ganha rodada de desempate.

| feature | PASSOU | FALHOU |
| --- | --- | --- |
| Gatilho: resistência | o arco reconhecido 2 de 2 (ou 3 com no máximo 1 erro) | duas ou mais erradas com no máximo uma certa: "o dedo não sentiu nada" (o efeito não chega) ou "pareceu outra arma" (o modo chega trocado) |
| Gatilho: arma | a pistola, idem | idem |
| Gatilho: vibração | a metralhadora, idem | idem |
| LEDs de jogador | três ou mais contagens certas, com no máximo um erro para cada quatro acertos | três ou mais erradas e mais erros que acertos |

Se as rodadas sem arma forem respondidas como alguma arma, o veredito avisa
que o gatilho não solta. Só os quatro modos oficiais entram no jogo — Off,
Feedback, Weapon, Vibration ([CONTRATO.md](../CONTRATO.md)).

**Defeitos que ela pega:** `gatilho-mudo`, `leds-errados`.

---

## As salas de som

O som de cada controle — o alto-falante, os atuadores da háptica e o
microfone — é um **segundo dispositivo de áudio**, além da TV. O aviso de cada
sala de som mostra, para cada jogador, o dispositivo achado e **como** foi
achado (pelo aparelho, pelo número, pelo nome); ◀ ▶ troca, △ testa. O caminho
inteiro, com as fontes, está em
[COMO-O-SOM-CHEGA-AO-CONTROLE.md](COMO-O-SOM-CHEGA-AO-CONTROLE.md). Sem o
dispositivo, a feature fica NÃO MEDIDO, com o porquê — é o caso de um controle
no rádio sem os nós de som do Hefesto.

Como nas salas de saída, são provas às cegas: a tela não mostra de onde veio o
som, e quem joga diz o que ouviu ou sentiu.

## O Canto — o ritmo no alto-falante do controle

**O padrão:** o alto-falante do DualSense nos jogos — o som que sai **da mão**,
paralelo ao da TV: o rádio de Deathloop, as vozes de Ghostwire.

**Como jogar:** a bigorna canta um ritmo de quatro notas, às vezes no
alto-falante de UM controle, às vezes na TV. Todo mundo ouve; a pergunta é
outra: o canto saiu da **sua** mão? ✕ "foi no meu", ○ "não foi". A tela revela
de onde veio, e o dono do canto repete o ritmo com ✕ (pontos por intervalo
certo, com folga de 120 ms). Cada jogador é o dono de dois cantos (três,
sozinho), e a TV canta duas vezes (três, sozinho), em ordem sorteada.

| feature | PASSOU | FALHOU |
| --- | --- | --- |
| Alto-falante | reconheceu o próprio canto ao menos duas vezes, com no máximo um erro, e disse "foi no meu" no máximo uma vez com o canto em outro lugar | o próprio canto não saiu (duas ou mais erradas e não mais certas); ou o canto dos outros saiu aqui (dois ou mais "foi no meu" fantasmas, na metade das chances ou mais): o som não fica no controle certo |

**Defeitos que ela pega:** `sem-alto-falante`, `som-vizinho`.

## Os Caminhos — o chão que se sente na mão

**O padrão:** a háptica de terreno dos jogos de PS5 (Astro's Playroom,
Returnal): o passo na grama não é o passo no metal, e a mão sabe antes do
olho. A háptica é **som** nos canais 3 e 4 da placa do controle.

**Como jogar:** primeiro o treino, com o nome na tela: grama (um baque macio),
cascalho (quatro estalos), metal (um golpe que ressoa), água (duas ondas).
Depois, oito trechos no escuro: três passos e a pergunta "que chão é esse?" —
✕ grama, ○ cascalho, □ metal, △ água; o clique do touchpad é "não senti". No
meio do caminho, quatro pedras: o tropeço treme **um lado só**, e a pessoa diz
qual (L1 esquerda, R1 direita; o touchpad é "não senti"). A TV não toca o
passo: ele só existe no controle.

| feature | PASSOU | FALHOU |
| --- | --- | --- |
| Háptica por áudio | ao menos 75% dos chãos certos e ao menos 80% dos tropeços do lado certo | "não senti" em metade dos trechos ou mais (e três ou mais): a háptica não chega; três ou mais tropeços ditos do lado oposto, mais que os certos: os canais 3 e 4 chegam trocados; um lado que nunca foi sentido: o atuador daquele lado não recebe; menos da metade dos chãos certos com três ou mais trocas: a textura chega deformada |

O "não senti" dito é a evidência; não responder não reprova ninguém. Com uma
háptica de um canal só (um nó mono), o tropeço não é perguntado, e o veredito
diz isso.

**Defeitos que ela pega:** `haptica-trocada`, `haptica-muda`.

## A Cripta — a voz, o silêncio e o susto

**O padrão:** os jogos de terror que escutam quem joga — o monstro que ouve
pelo microfone, o botão de mudo que salva, a luz laranja do mudo — e o susto
que sai da mão: a vibração forte e o grito no alto-falante do controle,
enquanto a TV bate.

**Como jogar:**

1. **silêncio** — o guardião dorme; todos quietos (o piso de cada microfone);
2. **o chamado** — cada um na sua vez chama o guardião, falando alto perto do
   controle; os outros, quietos (o som do ar é de todos: um microfone ouve a
   voz dos vizinhos, por isso a voz é medida em turnos);
3. **o mudo** — o guardião acorda; cada um aperta o botão do microfone (a luz
   laranja acende) e depois fala baixinho;
4. **a luz** — o jogo apaga, acende ou faz piscar a luz do microfone de cada
   controle, a tela não mostra, e a pessoa diz como está: ✕ apagada, ○ acesa,
   □ piscando;
5. **o susto** — quando a cripta fica quieta demais.

| feature | PASSOU | FALHOU |
| --- | --- | --- |
| Microfone | a voz subiu ao menos 13,5 dB acima do silêncio | com o controle vivo: a voz não subiu o bastante; o microfone só manda silêncio absoluto (mudo no sistema?); ou o dispositivo abriu e nenhum som chegou |
| Mudo do microfone | o botão chegou; e o medido diz se, mudo, o sistema também cortou o som ou se o mudo ficou com o jogo | a sala pediu, o controle estava vivo, e o botão nunca chegou |
| LED do microfone | três respostas certas com no máximo uma errada | duas erradas e não mais certas que erradas: a luz não é a que o jogo mandou |

Se o SDL recusa o LED (o rádio nativo, que este jogo só lê), a luz não é
perguntada e o veredito explica. O susto não entra em veredito nenhum: é o
padrão de jogo, e acaba a sala.

**Defeitos que ela pega:** `mic-surdo`, `mudo-nao-chega`, `led-mic-parado`.

---

## A sala que vem

| sala | marco | valida |
| --- | --- | --- |
| A Prova | 5 | tudo junto, dois contra dois |

## Jogar sem controle

`--simular N` pendura N DualSense de mentira. O teclado dirige um deles (Tab
troca qual):

| tecla | controle |
| --- | --- |
| Z ou Enter · X ou Esc · C · V | ✕ · ○ · □ · △ |
| Q · E · 1 · 3 | L1 · R1 · L2 · R2 |
| F · G | L3 · R3 |
| O · P | Options · Create |
| T · M | clique do touchpad · botão do microfone |
| Espaço | falar no microfone de mentira (enquanto segura) |
| setas · WASD | direcional · analógico esquerdo |
| I/K · J/L · B/N | inclina para a frente e para trás · para os lados · vira |
| H | a martelada |
| mouse | o touchpad: botão esquerdo é um dedo; com os dois botões, o segundo dedo segue o mouse |

`--robo` põe um robô para jogar em todos os controles simulados. Ele só sabe o
que um jogador saberia: vê a tela (a runa, a mira, o autômato inclinado) e,
nas salas de saída, sente o que chega ao controle pelos callbacks do joystick
virtual. Nas salas de som, o controle simulado ganha uma placa virtual de
quatro canais: o robô ouve o canal do alto-falante do controle dele e sente os
dois atuadores (o chão, pelo envelope de cada passo; o lado, pelo canal que
tremeu), e fala no microfone de mentira na vez dele.
