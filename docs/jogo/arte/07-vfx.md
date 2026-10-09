# 07 O brilho e os efeitos

O mundo da Forja é tinta e sombra. Os jogadores são as luzes. Este arquivo
decide o que brilha, de quem é cada brilho, as partículas, o carimbo e o
erro ([pilar 2](README.md#os-pilares)).

## O que conta como brilho

No renderizador Compatibility, o glow pega o pixel acima do limiar
`glow_hdr_threshold` = 0,82 (`godot/estudos/direcao/mundo.gd`). Brilho é
tudo o que passa do limiar: um material `neon` ou `contorno` com energia
acima de 1,0, um `emission_energy_multiplier` acima de 1,0, uma luz que
estoura a superfície.

**Todo brilho tem dono.** São quatro donos possíveis, e cada um tem um teto.

| dono | cor | energia máxima | onde |
| --- | --- | --- | --- |
| um jogador (P1 a P4) | a dele, `JOGADOR[lugar]` | 3,0 | o cavaleiro, o anel, as lâmpadas do chão, as faíscas que ele causou, o confete dele |
| o mundo | `VIOLETA` | 1,2 | o tubo da arquitetura, a beira do palco |
| a forja | `TUNGSTENIO` | 2,4 | as faíscas sem dono (a entrada, a introdução), a chama do salão, o foco da bigorna |
| a fita | nenhuma (é o pós) | não se aplica | o grão, a varredura, o rasgo |

As tintas das seções nunca brilham: são impressas (energia 1,0, sem glow). O
`ERRO_R` e o `ERRO_B` existem só no pós da Dissonância.

## A tabela do brilho

| elemento | dono | material | energia | quando |
| --- | --- | --- | --- | --- |
| o contorno do cavaleiro | o jogador | `contorno`, largura 0,012 | 2,4 | sempre que está vivo |
| o anel de oito lados no chão | o jogador | `neon` | 1,5 | no jogo |
| as lâmpadas no chão, à frente do anel | o jogador | `neon` | 1,8 | junto com o anel |
| a luz de dono (omni que pinta o chão) | o jogador | `OmniLight3D` | 0,9, alcance 3,4 m | no jogo, ao lado do cavaleiro |
| a runa ou o alvo do minigame | o jogador | `neon` | 2,0; 2,6 no acerto, por 4 quadros | o que é dele |
| as faíscas do golpe dele | o jogador | `neon` | 2,4 | 12 quadros |
| o contra-luz no resultado | o vencedor | `DirectionalLight3D` | 0,8 | 4 batidas |
| o confete do vencedor | o vencedor | `neon` | 1,0 (sem glow) | o pódio |
| o tubo da arquitetura | o mundo | `neon` | 1,0 a 1,1 no tempo 1 | sempre |
| as faíscas da entrada | a forja | `neon` | 2,4 | a cortina |
| a chama do salão | a forja | `neon` | 1,8 | sempre |
| o foco da bigorna | a forja | `SpotLight3D` | 1,2 a 4,0 | a cena pede |

Fora desta tabela, nada passa de 1,0. Um elemento novo que precisa brilhar
entra aqui antes, com o dono e a energia.

Hoje o jogo tem 17 materiais com `emission_enabled` e 6 com energia acima de
1,0 (`godot/scripts/`), sem dono escrito (o salão usa `Tema.ROSA` e
`Tema.LARANJA`). A G15 dá o dono a cada um, e o portão
[12](12-portoes.md#6-emissivo-com-dono) impede que um sem dono volte.

## As partículas

Todas são malhas pequenas (`BoxMesh`), nunca sprite com textura suave: a
Forja é feita de blocos.

| partícula | tamanho | quantas | vida | cor | dono |
| --- | --- | --- | --- | --- | --- |
| a faísca | 0,025 × 0,05 a 0,14 × 0,025 m | 12 por golpe, 30 na entrada | 12 quadros | a do dono ou `TUNGSTENIO` | quem bateu |
| o estilhaço (pedra, gelo, lingote) | cubo de 0,04 a 0,08 m | 8 por quebra | 0,6 s, cai com gravidade | a do material, recolorida | o mundo |
| a poeira do foco | 0,01 m | 0,5 por segundo | 4 s | `TUNGSTENIO`, energia 1,0 | a forja |
| o confete de fita | ver abaixo | | | | o vencedor |

**O teto:** 300 partículas vivas na tela, somadas todas. Quando passa, a mais
velha some. Nenhuma partícula projeta sombra.

### O confete de fita

O confete da Forja é fita cortada: tiras de fita magnética e de etiqueta, e
a cor de quem venceu.

| tira | tamanho | parte | material |
| --- | --- | --- | --- |
| fita magnética | 0,05 × 0,22 × 0,008 m | 50 % | `OXIDO_BRILHO`, fosco, rugosidade 0,6 |
| etiqueta | 0,05 × 0,22 × 0,008 m | 20 % | `ETIQUETA`, fosco, rugosidade 0,7 |
| a cor do dono | 0,05 × 0,22 × 0,008 m | 30 % | `neon` na cor do vencedor, energia 1,0 |

- **Quantas:** 160 no pódio, 40 no resultado de um minigame.
- **Como cai:** nasce de 4 a 5 m de altura em 1 batida; cai a 0,8 m/s, gira
  1,5 volta por segundo em torno do comprimento, balança ±0,3 m de lado.
- **Quanto dura:** 4 compassos; depois para de nascer e o que está no ar cai
  até o chão.
- **Com o movimento reduzido:** 40 no pódio, 10 no resultado, sem giro.

O estudo (`06_podio.gd`) usa 35 % de cor do dono e o óxido `#5a3a2a`, fora
dos tokens. O jogo usa a tabela acima.

## O carimbo

O carimbo é como a Forja diz "aconteceu": o julgamento, o verbo da entrada,
a virada, o nome do vencedor. É tinta batida no papel, por isso pousa de uma
vez.

| carimbo | letra | cor | escala | inclinação | fica | som |
| --- | --- | --- | --- | --- | --- | --- |
| o julgamento | Bungee 46 | a do dono | 1,35 a 1,0 em 80 ms, `MOLA` | −4° | 250 ms, some em 170 ms | `jul_*_p{n}` ([03](03-som.md#o-carimbo-de-cada-julgamento)) |
| o verbo da entrada | Bungee 160 a 252 | `ETIQUETA` | 1,35 a 1,0 em 80 ms | −2,6° | até a cortina sair | `fx_entrada` |
| a virada no placar | Bungee 64 | a de quem virou | 1,35 a 1,0 em 80 ms | −4° | 2 batidas | o do diretor de som |
| o nome do vencedor | Bungee 112 a 150 | a do vencedor | 1,35 a 1,0 em 80 ms | −1,7° | a tela inteira | o jingle |
| os carimbos do jogo | [09 As reações](09-reacoes.md#os-carimbos-do-jogo) | | | | | |

Todo carimbo tem o desregistro da impressão: uma chapa `FITA` deslocada
round(0,08 × tamanho) px para baixo e para a direita
([06](06-interface-e-texto.md#o-texto-como-voz)). Sobre a cena 3D, o contorno
`FITA` de 6 px. No impacto do carimbo, a tinta "espirra": 4 a 6 respingos
retangulares de 4 a 10 px, na cor do carimbo, a até 0,6× o tamanho da letra
do centro, por 6 quadros.

## O desregistro do erro

O erro não tem palavra, não tem vermelho e não tem "X". O erro é a nota do
cavaleiro saindo desafinada ([03](03-som.md#o-carimbo-de-cada-julgamento)),
e a imagem dele desafina junto: **o registro da impressão sai do lugar.**

| o que | quanto | quanto tempo |
| --- | --- | --- |
| o contorno do cavaleiro | duas cópias deslocadas ±0,012 m de lado, na cor do dono a 50 % | 6 quadros |
| a energia do contorno | de 2,4 cai a 0,6, volta em 1 batida, `SAI` | 1 batida |
| o anel no chão | apaga a 0,4 | 1 batida |
| o corpo | o tremor de lado do [05](05-movimento.md#o-golpe-antecipação-impacto-recuperação) | 3 quadros |
| a luz do controle | a cor do lugar escurece a 30 % | 0,5 s (o `_reagir` do molde) |
| o combo no VU | os segmentos caem um por quadro, do topo para a base | até zerar |

O erro nunca usa `ERRO_R` nem `ERRO_B` (são da Dissonância) e nunca pinta a
cor de outro jogador. Quem erra fica mais apagado, não marcado.

## O pós da fita

O pós (`pos_fita.gdshader`) vai em duas passadas:

| passada | camada | o que leva |
| --- | --- | --- |
| a de baixo | entre o 3D e o HUD | o desgaste inteiro ([01](01-cinema.md#a-fita-gasta)), o rasgo e a aberração |
| a de cima | por cima do HUD | `varredura` 0,06, `grao` 0,02, `aberracao` no máximo 2,0, `rasgo` a 1/3 do de baixo, `vinheta` 0 |

O HUD precisa seguir legível no pior quadro da Dissonância. O
`05_dissonancia.jpg` é a prova.

## A Dissonância

O efeito inteiro está no [01](01-cinema.md#a-dissonância). O que é VFX:

- **a fita enroscada:** a fita sai da janela do deck e cai pela tela em
  laçadas (6,5 voltas, laço de 70 a 120 px), linha de 12 px em `OXIDO` com
  sombra `SOMBRA` de 18 px e o brilho `OXIDO_BRILHO` de 2,5 px;
- **o mundo:** `aberracao` 7,0, `rasgo` 0,24, `desbota` 0,3, `vinheta` 0,55
  (o `05_dissonancia.jpg`);
- **os jogadores seguem acesos:** o contorno e o anel não perdem energia. O
  néon é deles, e nem a Dissonância apaga.

## O controle também é luz

A luz do controle (lightbar) é a cor do lugar, sempre, e as lâmpadas são o
padrão do lugar ([02](02-cor-e-letra.md#os-jogadores)). O que pisca na luz
está no [doc 05](../05-haptica-e-controle.md#a-identidade-p1p4) e cai no mesmo
quadro do som e da vibração ([03, o casamento](03-som.md#o-casamento-evento-por-evento)); o branco do perfeito (0,15 s)
conta como piscar ([10](10-acessibilidade.md#o-piscar)).
