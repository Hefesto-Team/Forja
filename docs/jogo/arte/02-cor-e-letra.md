# 02 A cor e a letra

A cor e a letra da Forja saem de um arquivo só. No estudo é
`godot/estudos/direcao/fita.gd`. No jogo, a G14 leva estes tokens ao
`godot/scripts/tema.gd`, que hoje ainda tem a paleta Drácula do app.

Regra: **nenhuma cor se escreve fora do arquivo de tokens.** Código pede
`Tema.ETIQUETA`, nunca `Color("#efe4c8")`. Hoje há 102 `Color("#` fora do
`tema.gd` (forja.gd, main.gd, mundo/kit.gd, mundo/salao.gd, salas/*.gd); a G14
os troca e o portão da [12](12-portoes.md) impede que voltem.

## Os tokens de cor

### A fita: as superfícies

Do mais fundo ao mais claro. Nenhuma brilha.

| token | hex | trabalho |
| --- | --- | --- |
| `FITA` | `#0d0a16` | o fundo de tudo, atrás das placas |
| `CASCO` | `#17121f` | o plástico do cassete: placa do HUD, cartão |
| `CASCO_ALTO` | `#241c30` | a borda iluminada do plástico, o casco em foco |
| `GRAFITE` | `#3a3346` | trilho, segmento apagado do VU, linha estrutural (nunca texto) |
| `JANELA` | `#07050c` | novo: o vidro escuro da janela do cassete, o fundo da célula do leader |
| `SOMBRA` | `Color(0, 0, 0, 0.45)` | novo: a sombra deslocada de placa, etiqueta e adesivo (nunca cor de traço) |

### A etiqueta: o papel e a caneta

| token | hex | trabalho |
| --- | --- | --- |
| `ETIQUETA` | `#efe4c8` | o papel; o texto claro sobre o casco |
| `ETIQUETA_SOMBRA` | `#cfc2a0` | a dobra do papel, a linha pautada |
| `TINTA` | `#1c1626` | a caneta sobre a etiqueta |
| `TINTA_SUAVE` | `#5a4f66` | o rótulo impresso na etiqueta |
| `MUDO` | `#857a95` | novo: o texto secundário sobre o casco (o "desligado", a dica) |

### O cenário

| token | hex | trabalho |
| --- | --- | --- |
| `VIOLETA` | `#4a3aa8` | o néon da arquitetura (tubo na parede, beira do palco); L ≤ 0,50 no OKLab, sempre |
| `VIOLETA_FUNDO` | `#1d1638` | a névoa e o preenchimento do salão |
| `TUNGSTENIO` | `#ffd9a8` | a luz de lâmpada (pódio, foco da bigorna); é luz, nunca traço nem texto |
| `OXIDO` | `#3b2a22` | novo: a fita magnética em si, o rolo, a tira do confete no escuro |
| `OXIDO_BRILHO` | `#7a5640` | novo: o óxido que pega luz, a face da tira que vira, o cabo do martelo |

### Os jogadores

Os únicos néons saturados da tela. Cada um pertence a um lugar e não aparece
em mais nada.

| lugar | token | hex | nome | LEDs do controle |
| --- | --- | --- | --- | --- |
| P1 | `JOGADOR[0]` | `#29e6ff` | ciano | `0x04` (a do meio) |
| P2 | `JOGADOR[1]` | `#ff3ea5` | magenta | `0x0A` (duas) |
| P3 | `JOGADOR[2]` | `#d4ff4a` | limão | `0x15` (três) |
| P4 | `JOGADOR[3]` | `#ee9a1e` | âmbar | `0x1B` (quatro) |

No jogo, `forja.gd:71` `COR_DO_LUGAR` ainda tem as cores antigas
(`Color8(0,72,255)`, `(255,24,8)`, `(0,255,64)`, `(255,8,168)`). A G14 troca
pelas quatro acima. A cor da lightbar do controle segue a mesma tabela.

A cor de um jogador nunca aparece sozinha: o P# e o desenho das lâmpadas vão
junto, em todo lugar onde ela marca quem é quem.

### O cavaleiro: a cor da peça e o néon do dono

O corpo do cavaleiro nunca é tingido na cor do lugar (decisão de 09/10/2026: a
montagem pintava as três peças no mesmo néon e nada se distinguia). Cada peça
tem material e cor próprios; o néon do dono vira acento. As regras inteiras e
a área de cada acento estão no [04](04-o-cavaleiro.md#a-peça-se-distingue).

**A escada de valor.** Cada parte mora numa faixa de luz (L do OKLab). A cor
da peça é a da Kenney, recolorida: o matiz fica, a luz cai na faixa da parte.

| parte | material | faixa de L | croma | rugosidade | metallic | papel do recolorir (`fita.gd` `GRADE`) |
| --- | --- | --- | --- | --- | --- | --- |
| cabeça | pele e cabelo | o rosto humano no tom da Kenney, a 0,10 do superior ou com a gola acesa; a pele de raça de 0,68 a 0,80 | até 0,10 | 0,90 | 0 | `personagem` (como hoje) |
| tronco superior | tecido | de 0,46 a 0,58 | de 0,03 a 0,10 | 0,85 | 0 | novo `tecido`: `l0` 0,46, `l1` 0,12, `sat` 0,55 |
| tronco inferior | couro e lona | de 0,22 a 0,36 | de 0,02 a 0,07 | 0,70 | 0 | novo `couro`: `l0` 0,22, `l1` 0,14, `sat` 0,40 |
| arma | metal batido (a face do escudo também) | de 0,68 a 0,80 | até 0,03 | de 0,45 a 0,62 | 0,2 | `objeto` (como hoje) |
| amuleto | cerâmica esmaltada, o emblema em latão | de 0,68 a 0,80 | de 0,04 a 0,08 | 0,35 | 0 (o latão 0,2) | `objeto` |

Entre duas faixas vizinhas sobra sempre 0,10 de L: o rosto (0,68) fica 0,10
acima do tecido mais claro (0,58), e o tecido mais escuro (0,46) fica 0,10
acima do couro mais claro (0,36). Em cinza, o cavaleiro tem três faixas: a
cabeça clara, o tronco médio, as pernas escuras. O item, claro, se lê contra
o tecido do braço que o segura.

O rosto humano é a exceção: a pele da Kenney vai de L 0,52 a 0,72 e não se
clareia, para manter os tons de pele. Ele se mede pelo contraste com o
superior: |ΔL| de 0,10 ou mais, ou a gola acesa do friso entre os dois. Dos
144 pares de rosto e superior, 93 passam pelo ΔL e 51 pela gola. O critério
inteiro está no [04](04-o-cavaleiro.md#o-critério-do-rosto).

**A peça nunca é néon.** Duas condições, conferidas por script:

- croma de até 0,10 (o néon de jogador mais fraco, o ciano, tem croma 0,141);
- distância OKLab (ΔE) de pelo menos 0,08 até cada um dos quatro `JOGADOR`.

**As peles das raças.** As quatro raças do [04](04-o-cavaleiro.md#as-raças)
trocam a pele (o rosto e as mãos) por um destes tokens novos. Todos ficam na
faixa da cabeça e passam nas duas condições acima (medido em 09/10/2026).

| token | hex | L | croma | o ΔE mais perto |
| --- | --- | --- | --- | --- |
| `PELE_ORC` | `#89aa77` | 0,70 | 0,081 | 0,154 (âmbar) |
| `PELE_LATAO` | `#bda978` | 0,74 | 0,070 | 0,095 (âmbar) |
| `PELE_ESCORIA` | `#a3958e` | 0,68 | 0,020 | 0,157 (âmbar) |
| `PELE_RAPOSA` | `#cd8d6d` | 0,70 | 0,090 | 0,097 (âmbar) |

**O néon do dono no cavaleiro.** O acento (o friso, a costura, a runa, o
visor) é sempre `JOGADOR[lugar]`, nunca a cor da peça. Ele só encosta em base
com L de até 0,58 (o tecido, o couro): o magenta, o néon mais escuro, tem L
0,68 e fica 0,10 acima. Na cabeça e no item, que são claros, o acento mora num
vão em `JANELA` com 1,5 vez a largura dele.

### As tintas das seções

Impressas, nunca néon. Pintam a tarja da etiqueta, a cortina da entrada e a
luz da seção ([01 O cinema](01-cinema.md#a-luz-das-cinco-tintas)).

| token | hex | seções |
| --- | --- | --- |
| `SECAO[0]` vermelhão | `#c8432f` | S1, S9 |
| `SECAO[1]` cobalto | `#2f55c4` | S2, S6 |
| `SECAO[2]` petróleo | `#1f8a7e` | S3, S7 |
| `SECAO[3]` mostarda | `#c79a2a` | S4, pódio |
| `SECAO[4]` ameixa | `#86409a` | S5, S8 |

### O erro

| token | hex | trabalho |
| --- | --- | --- |
| `ERRO_R` | `#ff2a4a` | só no deslocamento de cor da Dissonância |
| `ERRO_B` | `#2a6bff` | idem |

Não existe vermelho de "errou". O erro de um julgamento não tem cor nem palavra
([03 O som](03-som.md#o-carimbo-de-cada-julgamento)).

### A luz que não é de lugar

Cor que é luz (a luz do controle numa pergunta, o alarme, a luz das equipes)
ou matéria acesa do cenário 3D. Nunca traço nem texto na interface 2D.

**A pergunta da luz** (O Impacto, A Prova: «que cor está a sua luz?»). As
quatro ficam a ΔE OKLab de 0,15 ou mais de cada `JOGADOR` (a prova do jogo
confere): a luz da pergunta nunca parece a de um lugar. Até 09/10/2026 eram
âmbar e ciano, as cores do P4 e do P1.

| token | hex | nome | o ΔE mais perto |
| --- | --- | --- | --- |
| `PERGUNTA[0]` | `#00c853` | verde | 0,223 (limão) |
| `PERGUNTA[1]` | `#1f3dff` | azul | 0,402 (magenta) |
| `PERGUNTA[2]` | `#ab45ff` | violeta | 0,216 (magenta) |
| `PERGUNTA[3]` | `#ffffff` | branco | 0,206 (ciano) |
| `LANTERNA_NEUTRA` | `#8c8c99` | a lanterna enquanto a pergunta corre (a tela não sopra a cor) | — |

**O alarme e as equipes.**

| token | hex | trabalho |
| --- | --- | --- |
| `ALARME` | `#ff0000` | o vermelho do golpe e do susto, na luz do controle e na chama; a fase escura é `ALARME.darkened(k)` |
| `EQUIPE[0]` | `#ff4500` | a luz da Brasa (A Prova): o disco, a bala, a faísca do acerto |
| `EQUIPE[1]` | `#0059ff` | a luz da Maré |

**O ar e a matéria acesa das salas.**

| token | hex | trabalho |
| --- | --- | --- |
| `AR["centelha"]` | `#ff9a52` | as brasas d'A Centelha |
| `AR["caminhos"]` | `#7ff0b0` | a poeira d'Os Caminhos |
| `AR["canto"]` | `#b88cff` | a poeira d'O Canto |
| `AR["galeria"]` | `#c28bff` | a poeira d'A Galeria |
| `AR["impacto"]` | `#6fa8ff` | a poeira d'O Impacto |
| `AR["molde"]` | `#f1c86a` | a poeira d'O Molde |
| `AR["prova"]` | `#ffb86c` | as brasas d'A Prova |
| `AR["viga"]` | `#ff6a3d` | a poeira d'A Viga |
| `AR["voz"]` | `#7fe8ff` | as brasas frias d'A Voz |
| `BRONZE` | `#b07838` | o sino grande d'O Canto |
| `BRONZE_CLARO` | `#c08a42` | o sino pequeno de cada jogador d'O Canto |
| `METAL_FRIO` | `#5a1a08` | o metal do molde, brasa apagada |
| `METAL_QUENTE` | `#ff7a2a` | o metal do molde aquecido |
| `METAL_NO_PONTO` | `#ff9a3a` | o metal do molde no ponto do carimbo |
| `OURO` | `#ffd479` | o ouro que o metal do molde puxa no ponto |
| `FAISCA` | `#ff9a50` | a faísca do tiro no pilar d'A Prova |
| `RACHA` | `#ffb040` | a rachadura que acende na pedra d'A Viga |
| `BONECO_DE_TREINO` | `#b9a98a` | o orc de treino d'A Prova, desbotado |

### Do Drácula para a Fita

A tabela que a G14 usa para trocar sem pensar:

| Tema hoje | vira | observação |
| --- | --- | --- |
| `CASA` `#11121a` | `FITA` | |
| `APP` `#21222c` | `CASCO` | |
| `PAINEL` `#282a36` | `CASCO` | |
| `ELEVADO` `#2b2d3a` | `CASCO_ALTO` | |
| `LINHA`, `TRILHO`, `SUTIL` | `GRAFITE` | |
| `SEL` `#403b55` | `CASCO_ALTO` com borda na cor do dono | a seleção tem dono |
| `FG` `#f8f8f2` | `ETIQUETA` | |
| `SUAVE` `#c8ccda` | `ETIQUETA_SOMBRA` | |
| `MUDO`, `COMMENT` | `MUDO` `#857a95` | |
| `ROXO` (foco, título) | a cor do dono do foco; sem dono, `ETIQUETA` | |
| `ROSA` (a marca) | `VIOLETA` no logo, nada mais | |
| `VERDE` (confirma) | a cor do jogador que confirmou | |
| `LARANJA` (atenção) | a tarja mostarda na etiqueta, texto em `TINTA` | |
| `VERMELHO` (falhou, perigo) | a tarja vermelhão na etiqueta, texto em `TINTA` | só para falha do sistema (controle caiu) |
| `CIANO` (informa) | `ETIQUETA` em VT323 | ciano agora é o P1 |
| `AMARELO` (logo) | sai | |
| `LED_ACESO` `#e8ecf5` | `ETIQUETA` | |

## Os pares de contraste permitidos

Medidos pela conta WCAG 2.1. Texto abaixo de 48 px pede 4,5; texto a partir
de 48 px e símbolo pedem 3,0. Um par que não está aqui não vira texto.

### Texto sobre o casco e a fita

| texto | fundo | contraste | até |
| --- | --- | --- | --- |
| `ETIQUETA` | `CASCO` | 14,5 | qualquer tamanho |
| `ETIQUETA` | `FITA` | 15,5 | qualquer tamanho |
| `ETIQUETA` | `CASCO_ALTO` | 12,9 | qualquer tamanho |
| `ETIQUETA_SOMBRA` | `CASCO` | 10,4 | qualquer tamanho |
| `MUDO` | `CASCO` | 4,56 | qualquer tamanho (no limite) |
| `MUDO` | `FITA` | 4,86 | qualquer tamanho |
| `MUDO` | `CASCO_ALTO` | 4,06 | só 48 px ou mais |
| ciano P1 | `CASCO` | 12,1 | qualquer tamanho |
| magenta P2 | `CASCO` | 5,67 | qualquer tamanho |
| limão P3 | `CASCO` | 15,9 | qualquer tamanho |
| âmbar P4 | `CASCO` | 8,12 | qualquer tamanho |
| mostarda | `CASCO` | 7,07 | qualquer tamanho |
| petróleo | `CASCO` | 4,37 | só 48 px ou mais |
| vermelhão | `CASCO` | 3,76 | só 48 px ou mais |
| cobalto, ameixa | `CASCO` | 2,8 | nunca texto |
| `GRAFITE` | `CASCO` | 1,52 | nunca texto, só traço estrutural |
| `VIOLETA` | `CASCO` | 2,15 | nunca texto |

### Texto sobre a etiqueta

| texto | fundo | contraste | até |
| --- | --- | --- | --- |
| `TINTA` | `ETIQUETA` | 13,9 | qualquer tamanho |
| `TINTA_SUAVE` | `ETIQUETA` | 6,05 | qualquer tamanho |
| `TINTA` | `ETIQUETA_SOMBRA` | 9,96 | qualquer tamanho |
| `TINTA_SUAVE` | `ETIQUETA_SOMBRA` | 4,33 | só 48 px ou mais |
| violeta, ameixa, cobalto | `ETIQUETA` | 6,74 / 5,17 / 5,16 | qualquer tamanho |
| vermelhão | `ETIQUETA` | 3,86 | só 48 px ou mais |
| petróleo | `ETIQUETA` | 3,32 | só 48 px ou mais |
| mostarda | `ETIQUETA` | 2,05 | nunca texto |
| ciano, magenta e limão | `ETIQUETA` | 1,2 a 2,6 | **nunca** |

A cor de jogador nunca é texto sobre a etiqueta. Na etiqueta, o nome de um
jogador se escreve em `TINTA`, e a cor dele vem num traço de caneta de 6 px
embaixo do nome (a "sublinha do dono").

### Texto sobre a cor

| texto | fundo | contraste |
| --- | --- | --- |
| `TINTA` | ciano P1 | 11,6 |
| `TINTA` | magenta P2 | 5,44 |
| `TINTA` | limão P3 | 15,3 |
| `TINTA` | âmbar P4 | 7,78 |
| `TINTA` | mostarda | 6,78 |
| `TINTA` | petróleo | 4,19 (só 48 px ou mais) |
| `ETIQUETA` | cobalto | 5,16 |
| `ETIQUETA` | ameixa | 5,17 |
| `ETIQUETA` | vermelhão | 3,86 (só 48 px ou mais) |
| `ETIQUETA` | `VIOLETA` | 6,74 |

A placa "Pronto" (fundo na cor do jogador, texto em `FITA`) do estudo
(`godot/estudos/direcao/hud.gd:201-203`) obedece a esta tabela.

## As quatro fontes

Quatro e só quatro. Cada uma tem um trabalho, e nenhuma faz o trabalho da
outra. Os arquivos estão em `godot/assets/fontes/`, com as licenças ao lado.

| fonte | arquivo | trabalho | nunca |
| --- | --- | --- | --- |
| **Bungee** | `Bungee-Regular.ttf` | o grito: o verbo da entrada, o carimbo do julgamento, o P#, o nome do vencedor no pódio | frase com mais de três palavras |
| **VT323** | `VT323-Regular.ttf` | o que a máquina mede: pontos, contador, tempo, rótulo dos VUs, stats | texto corrido |
| **Archivo Narrow** | `ArchivoNarrow-wght.ttf` | a voz: frases, dicas, o cartão, os menus, o nome do jogador no HUD | grito |
| **Permanent Marker** | `PermanentMarker-Regular.ttf` | a caneta: o que alguém escreveu na etiqueta (título da seção, "Lado B", a data, o arquétipo, o vencedor nos créditos) | texto que muda a cada quadro |

Os pesos do Archivo Narrow: 500 no texto, 600 no nome e no rótulo, 700 no
botão e no "Pronto".

Space Grotesk e JetBrains Mono saem do jogo (são do app Hefesto). A G14 tira
os dois de `tema.gd:54-55`.

## A escala de tamanhos

Na tela lógica de 1920×1080. Nada que se lê fica abaixo de 30 px. Com o
texto grande nas Opções, tudo ×1,15 (`ESCALA_DO_TEXTO` em `godot/scripts/opcoes.gd`;
o `Tema.t()` de hoje faz a conta).

| papel | fonte | px |
| --- | --- | --- |
| o verbo da entrada | Bungee | 160 |
| o nome do vencedor (pódio) | Bungee | 112 |
| o título da tela | Bungee | 64 |
| os pontos grandes do HUD | VT323 | 64 |
| o título da seção na etiqueta | Permanent Marker | 56 |
| o carimbo do julgamento | Bungee | 46 |
| o aviso que some sozinho | Archivo Narrow 600 | 46 |
| o P# no cartão do HUD | Bungee | 40 |
| o corpo, a frase | Archivo Narrow 500 | 34 |
| o nome no HUD | Archivo Narrow 600 | 32 |
| o rótulo, a dica, o stat | Archivo Narrow 600 ou VT323 | 30 |

## A margem e a forma

- Área segura: x de 96 a 1824, y de 60 a 1020 (`tema.gd` MARGEM_X e
  MARGEM_Y). Nada que se lê sai dela.
- Placas de casco com raio de 14 px e borda de 3 px em `CASCO_ALTO`; a sombra
  é `SOMBRA` deslocada (4, 6).
- A etiqueta tem raio de 8 px, a tarja da seção a 14 px do topo com 12 px de
  altura, e a sombra (5, 7).
- O VU tem segmentos com 4 px de vão, apagados em `GRAFITE`, acesos na cor do
  dono.

## O texto como letra

- Maiúscula no começo da frase, minúscula no resto, sempre. A exceção é o
  Bungee, que só tem caixa alta.
- Nenhum emoji Unicode em `traducoes.gd`. Os símbolos de botão são os ícones
  do controle desenhados ([06 A interface e o texto](06-interface-e-texto.md)).
- Números em VT323 alinham pela direita.
