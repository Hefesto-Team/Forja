# A produção

A lista fechada do que o produtor faz agora para a bíblia ficar provada em
imagem. Cada item tem os arquivos de saída e o critério de pronto. Item novo
só entra escrito aqui pelo diretor de arte; ideia que aparecer no caminho vira
uma linha em "Para a próxima leva", no fim.

## As regras da produção

- **Nada gerado por modelo:** toda imagem sai de render do Godot (o estudo em
  `godot/estudos/direcao/`), de desenho por código (`_draw`, `ArrayMesh`) ou
  de modelo da Kenney recolorido. Nenhuma textura, foto ou ilustração de fora.
- **Nenhuma janela na tela:** o render vai por
  `bash godot/estudos/direcao/render.sh <pasta> <quadro>` (Xvfb), e cada rodada
  pelo semáforo:
  `bash /mnt/Apate/Desenvolvimento/hefesto-dualsense4unix/docs/process/ferramentas-da-leva/vez-do-pytest.sh <cmd>`.
- **O quadro novo** é um script em `godot/estudos/direcao/quadros/` com o
  número seguinte (o último hoje é o 18) e entra na lista `QUADROS` do
  `render.sh`. A imagem sai em `docs/imagens/direcao/`, JPG de 1920×1080
  (ou o tamanho que o item pede), qualidade 90.
- **Os portões de arte** ([12](12-portoes.md)) valem para o estudo também,
  menos a regra do índice escrito em número (o quadro fixa um jogador de
  propósito). Cor só por token, as quatro fontes, texto de 30 px ou mais.
- **Um commit por item**, em português, só com os arquivos do item.
- **Os personagens que faltam:** o estudo tem 4 dos 12 do Mini Characters. Os
  outros 8 vêm de `oficina/kenney/` (`python3 scripts/kenney.py onde "Mini
  Characters"`) para `godot/estudos/direcao/kenney/mini-characters/`, com a
  `License.txt`.

## A lista

### 1 A tela de montagem do cavaleiro

**Saída:**

- `godot/estudos/direcao/cavaleiro/cortar.gd`: corta cada personagem em três
  malhas (cabeça, tronco superior, tronco inferior) pelo osso de cada
  triângulo, como no [04](04-o-cavaleiro.md#o-corte);
- `godot/estudos/direcao/cavaleiro/montar.gd`: monta um cavaleiro com três
  peças de personagens diferentes, no mesmo esqueleto, e põe o item;
- `godot/estudos/direcao/quadros/10_montagem.gd` e
  `docs/imagens/direcao/10_montagem.jpg`.

**Pronto quando:**

- as quatro colunas seguem a tabela de [04](04-o-cavaleiro.md#uma-coluna)
  (x = 96 + 432·i; a placa, o cavaleiro, o arquétipo, as cinco linhas, os
  quatro VUs, nas alturas da tabela);
- cada coluna é um corpo misturado: a cabeça de um personagem, o superior de
  outro e o inferior de um terceiro, sem buraco nem costura visível a 50 mm;
- uma coluna está forjada (chave tungstênio), uma tem uma linha travada (o
  cadeado), uma está de cadeira de rodas, uma tem um item que o corpo não
  alcança riscado na lista;
- o nome de cada cavaleiro aparece na placa e na etiqueta, e o arquétipo bate
  com os stats pela tabela do [04](../sistemas/README.md#o-arquétipo);
- o `cortar.gd` imprime a contagem de triângulos de cada parte, e ela bate com
  a do 04.

### 2 A prancha das peças

**Saída:** `godot/estudos/direcao/quadros/11_pecas.gd` e
`docs/imagens/direcao/11_pecas.jpg` (1920×1440).

**Pronto quando:** três linhas (cabeça, superior, inferior) por 12 colunas
(os 12 personagens), mais uma linha com os seis itens; cada peça de frente, na
mesma escala, sobre `CASCO`, com o emblema (Bigorna, Mola, Brasa e Lume, os quatro do
[sistemas](../sistemas/README.md)) em VT323 30 e os pontos que dá; os itens com o stat que pedem. 42
células, nenhuma vazia.

### 3 A prancha das reações

**Saída:**

- `godot/estudos/direcao/reacoes.gd`: desenha por código os 8 adesivos e os 6
  carimbos de [09](09-reacoes.md), em qualquer tamanho e cor de dono;
- `godot/estudos/direcao/quadros/12_reacoes.gd`,
  `docs/imagens/direcao/12_reacoes.jpg` e
  `docs/imagens/direcao/12_reacoes_daltonismo.jpg`.

**Pronto quando:** os 8 adesivos nas quatro cores (32) a 112 px sobre o casco,
uma linha deles a 144 px sobre a arena da Centelha, a roda de 240 px aberta
num cartão, e os 6 carimbos no tamanho do jogo; as medidas são as de
[09](09-reacoes.md#o-adesivo-a-cara-de-fita) (recorte de 6 px, traço de 6 px,
carretéis de 22 px, as lâmpadas do dono no canto); a versão de daltonismo sai
de `scripts/daltonismo.gd`, e em cada uma das quatro visões cada adesivo se
liga ao dono pelas lâmpadas.

### 4 A prancha da luz das cinco seções

**Saída:** `godot/estudos/direcao/quadros/13_luz.gd` e
`docs/imagens/direcao/13_luz.jpg` (1920×2700: duas colunas, lado A e lado B,
por cinco linhas, uma por tinta; cada célula 960×540).

**Pronto quando:** a mesma arena e a mesma câmera (35 mm, plongée de 50°) nas
cinco tintas, com a névoa, o preenchimento e a chave da tabela do
[01](01-cinema.md#a-luz-das-cinco-tintas); a coluna do lado B com a chave a
×0,85 e a névoa a ×1,3; cada célula com a etiqueta da seção no canto (a tarja
dupla no lado B); os quatro cavaleiros com a mesma saturação em todas as dez
(a tinta não pinta o cavaleiro).

### 5 O storyboard da noite

**Saída:** `godot/estudos/direcao/quadros/14_storyboard.gd` e
`docs/imagens/direcao/14_storyboard.jpg` (1920×1500).

**Pronto quando:** os 18 planos do [01](01-cinema.md#o-storyboard-da-noite),
cada um uma miniatura de 448×252 renderizada (não desenhada) com a lente, a
altura e a luz do plano, em grade de 4 colunas; embaixo de cada uma, o número
e o momento em Archivo 600 30 e a lente e a duração em VT323 30, sobre
`CASCO`. Os planos 2D (a entrada, o placar) são os quadros do HUD em
miniatura.

### 6 O fim da fita

**Saída:** `godot/estudos/direcao/quadros/15_fim_da_fita.gd` e
`docs/imagens/direcao/15_fim_da_fita.jpg`.

**Pronto quando:** o plano de [01](01-cinema.md#o-fim-da-fita): o deck a 85
mm, frontal; o leader transparente na janela; o contador parado num tempo de
noite real (`1:47:12`); a etiqueta com a data em Permanent Marker; as duas
saídas "Botão ✕ (Gravar outra noite)" e "Botão ◯ (Ejetar)". Nenhuma cor de
jogador na tela, nada além do contador como número.

### 7 O logo nos tokens da Fita

**Saída:** `godot/assets/forja-logo.svg` (sobre o escuro),
`godot/assets/forja-logo-etiqueta.svg` (de uma cor, para a etiqueta), e
`godot/assets/forja-logo.png` e `godot/assets/forja-logo-256.png` refeitos a
partir do SVG por script do Godot (`Image.load_svg_from_string`), sem
ferramenta de fora.

**A troca de cor**, desenho igual ao de hoje:

| parte | hoje | vira |
| --- | --- | --- |
| a chama, fora | `#9dcef6` | `SECAO[0]` vermelhão |
| a chama, dentro | `#5ea4ea` a 0,5 | `SECAO[3]` mostarda, opaca |
| o arco | `#8b8dfd` | `VIOLETA` |
| os dois pontos do arco | `#8be9fd`, `#ff79c6` | `ETIQUETA` |
| o topo da bigorna | `#f8f8f2` | `ETIQUETA` |
| a cintura | `#bd93f9` | `ETIQUETA_SOMBRA` |
| a base | `#6272a4` | `TINTA_SUAVE` |
| o traço da bigorna | `#7a7a7a` | `TINTA` |
| o cabo dos martelos | `#ffb86c` | `OXIDO_BRILHO` |
| a cabeça dos martelos | `#909090` | `ETIQUETA_SOMBRA` |
| o traço dos martelos | `#666666` | `TINTA` |

A versão da etiqueta é toda em `TINTA`, com os vazios em `ETIQUETA`.

**Pronto quando:** todo `fill` e `stroke` dos dois SVG é um token (portão 1);
nenhuma cor de jogador; os quatro martelos se contam a 64 px; o `<title>` e o
`<desc>` ficam; o título do jogo e o ícone do executável usam o PNG novo
(conferido por `grep` em `godot/` e `scripts/icone_do_exe.py`, sem mudar
código: se mudar código, vira ficha).

### 8 A bigorna própria

**Saída:** `godot/estudos/direcao/bigorna.gd` (a malha por código,
`ArrayMesh`), `godot/estudos/direcao/quadros/16_bigorna.gd` e
`docs/imagens/direcao/16_bigorna.jpg`.

**A forma**, nas unidades do Mini Characters (o cavaleiro tem 0,72 de altura):

| parte | medida |
| --- | --- |
| altura total | 0,30 (cerca de 0,4 do cavaleiro) |
| comprimento da face, do rabo à ponta do chifre | 0,46 |
| o chifre | cone de seção redonda com 8 lados, 0,17 de comprimento (37 % da face), afinando de 0,10 a 0,015 |
| a face | 0,29 × 0,12, com o furo quadrado de 0,025 perto do rabo |
| a cintura | 0,07 de largura, 0,08 de altura |
| a base | 0,30 × 0,18, com os quatro pés chanfrados |

**Pronto quando:** no máximo 600 triângulos; sombreamento chapado; a cor sai
do colormap da Kenney recolorido no papel "objeto" (`fita.gd`), `metallic` até
0,2; a prancha tem quatro vistas (de lado, 3/4, de cima, e na câmera do jogo:
35 mm, plongée de 50°) e, ao lado, a `workbench-anvil` do Survival Kit nas
mesmas quatro; na vista do jogo, o chifre se vê sem procurar (a silhueta de
lado mostra o chifre separado do corpo por um vão).

### 9 A tabela dos contatos

**Saída:** `godot/estudos/direcao/medir_contatos.gd` e
`docs/jogo/arte/dados/contatos.csv`.

**Pronto quando:** uma linha por animação das 32 do Mini Characters, com as
colunas `animacao`, `duracao_s`, `contato_s`, `osso`, `metodo`. O contato do
golpe é o quadro de maior velocidade angular do osso do braço (ou da perna,
no chute); o do passo e do pulo, o quadro em que o pé chega mais baixo. O
script roda com `--headless`, e rodar duas vezes dá a mesma tabela.

### 10 A prancha da forja na batida

**Saída:** `godot/estudos/direcao/quadros/17_forja.gd` e
`docs/imagens/direcao/17_forja.jpg`.

**Pronto quando:** duas linhas. A de cima mostra as quatro fases de uma
martelada ([05](05-movimento.md#o-golpe-antecipação-impacto-recuperação)):
antecipação (Y 0,96, braço a −10°), impacto (Y 0,80, X e Z 1,12), parada,
recuperação (Y 1,06). A de baixo mostra as 8 marteladas da forja, cada uma
acendendo a parte da tabela do [04](04-o-cavaleiro.md#a-forja). O número de
cada quadro (em batidas e em ms a 120) embaixo, em VT323 30.

### 11 A prancha da cortina

**Saída:** `godot/estudos/direcao/quadros/18_cortina.gd` e
`docs/imagens/direcao/18_cortina.jpg` (1920×1620: seis miniaturas de 960×540).

**Pronto quando:** os instantes 0, 300, 600, 680, 900 ms e o J-card entrando,
com a geometria de [06](06-interface-e-texto.md#a-cortina-diagonal) (a borda
a 16,0°, a tira `FITA` de 26 px, o fio de 4 px); o verbo carimbado no quadro
de 600 ms; o `rasgo` do pós com os valores da tabela de cada instante, escritos
embaixo.

### 12 Os quadros que mudaram

**Saída:** `docs/imagens/direcao/01_centelha_depois.jpg`, `04_cartao.jpg`,
`06_podio.jpg` e `08b_daltonismo.jpg` refeitos, e os scripts deles.

**Pronto quando:**

- o 01 diz "Ressonância!" e "Afinado" (não "PERFEITO" e "ÓTIMO") e o cartão do
  jogador começa em y = 60;
- o 04 escreve o gênero em `TINTA`, com a borda na tinta da seção;
- o 06 usa o confete do [07](07-vfx.md#o-confete-de-fita) (`OXIDO_BRILHO`, 50
  / 20 / 30 %);
- o 08b é refeito a partir do 01 novo;
- nenhum dos quatro tem cor fora dos tokens: `fita.gd` ganha `OXIDO`,
  `OXIDO_BRILHO` e `JANELA` do [02](02-cor-e-letra.md#os-tokens-de-cor), e o
  estudo inteiro troca o `#3b2a22` por `OXIDO`, o `#7a5640` e o `#5a3a2a` por
  `OXIDO_BRILHO` e o `#07050c` por `JANELA` (`hud.gd`, `05_dissonancia.gd`,
  `06_podio.gd`, `07_titulo.gd`); um `grep` pelos quatro hex no estudo só
  acha `fita.gd`. As cores de luz e de ambiente do estudo (`#2a2738`,
  `#8a7cff` e as outras) ficam: são luz, e a tabela de luz do
  [01](01-cinema.md#a-luz-das-cinco-tintas) as nomeia na G15.

### 13 A página da direção

**Saída:** `docs/jogo/direcao-de-arte.html`.

**Pronto quando:** cada prancha nova (itens 1 a 11) tem uma seção na página,
com a etiqueta no estilo das que existem, a imagem por caminho relativo e uma
linha que aponta para o arquivo da bíblia que ela prova; a página continua
abrindo em `file://`; nenhuma imagem passa de 1 MB.

## O ajuste do cavaleiro

Pedido dela em 09/10: as peças se diferenciam na montagem, o néon deixa de
ser uma cor só, e o cavaleiro ganha raças. As regras estão no
[04](04-o-cavaleiro.md#a-peça-se-distingue), no
[02](02-cor-e-letra.md#o-cavaleiro-a-cor-da-peça-e-o-néon-do-dono) e no
[04, as raças](04-o-cavaleiro.md#as-raças). Seis itens, um commit cada, nesta
ordem: o 14 vem antes de qualquer prancha.

### 14 O estudo veste a peça na cor dela

**Saída:**

- `godot/estudos/direcao/fita.gd`: as GRADEs `tecido` (l0 0,46, l1 0,12, sat
  0,55) e `couro` (l0 0,22, l1 0,14, sat 0,40), o teto de croma 0,10 no
  `recolorir` de toda peça, e os tokens `PELE_ORC`, `PELE_LATAO`,
  `PELE_ESCORIA` e `PELE_RAPOSA`;
- `godot/estudos/direcao/mundo.gd`, no `vestir`, e
  `shaders/cavaleiro.gdshader`: `tingir` 0, `brilho_proprio` 0, `aro` 0,25; o
  acento (friso, costura, runa, visor, rachadura) é uma malha à parte em
  `neon` na cor do dono, energia 1,6, e nunca um tom no corpo;
- `cavaleiro/montar.gd`: o friso no superior (faixa de 0,010 m na barra e na
  gola), a costura no inferior (0,008 m no lado de fora das pernas), a runa do
  item, o medalhão em cerâmica e latão; e a opção `raca`.

**Pronto quando:**

- um `grep` por `tingir` no estudo só acha o valor 0;
- o contorno fica em 1,6 na montagem e 2,4 no jogo, como no [07](07-vfx.md#a-tabela-do-brilho);
- a medida do item 17 passa em todas as linhas.

### 15 As raças entram no estudo

**Saída:**

- `godot/estudos/direcao/kenney/mini-dungeon-personagens/character-orc.glb`,
  copiado de `oficina/kenney/3.7.0/3D assets/Mini Dungeon/Models/GLB format/`,
  com a `Textures/` e a `License.txt`. Fica numa pasta à parte porque o
  `recolorir.gd` dá um papel por pacote: o do orc é `personagem`, o do resto do
  Mini Dungeon é cenário;
- `godot/estudos/direcao/kenney/cube-pets/animal-fox.glb`, com a `Textures/` e
  a `License.txt`; só o nó `tail` é usado;
- `cavaleiro/racas.gd`: o Autômato, o Golem e a cabeça da Raposa por
  `ArrayMesh`, com as medidas da tabela do [04](04-o-cavaleiro.md#as-raças);
- `cavaleiro/cortar.gd` corta o orc também.

**Pronto quando:**

- o `cortar.gd` imprime o orc com 176, 144 e 54 triângulos e 0 misturados;
- o Autômato e a Raposa ficam em até 300 triângulos, o Golem em até 400;
- a cauda da Raposa (escala 0,33, no osso da raiz em (0; 0,20; −0,10)) passa
  pela abertura da cadeira de rodas sem cruzar o encosto;
- as mãos de pinça e os punhos de pedra seguem o osso da mão nas 32 animações.

### 16 As pranchas refeitas e a das raças

**Saída:**

- `docs/imagens/direcao/10_montagem.jpg` refeita: as quatro colunas com
  quatro raças diferentes (uma humana), as cores das peças sem tom;
- `docs/imagens/direcao/11_pecas.jpg` refeita: cada peça no material dela,
  com o acento aceso na cor de P1;
- `docs/imagens/direcao/08_cavaleiros.jpg` refeita, sem o corpo tingido;
- `godot/estudos/direcao/quadros/19_racas.gd` e
  `docs/imagens/direcao/19_racas.jpg` (1920×1440), com `19_racas` na lista
  `QUADROS` do `render.sh`.

**Pronto quando:**

- a 19 tem cinco linhas (Humana, Orc, Autômato, Golem, Raposa) por quatro
  colunas (P1 a P4), cada cavaleiro de frente e a 3/4; embaixo, uma linha das
  cinco cabeças a 64 px em cinza e uma da silhueta em preto chapado;
- nas duas linhas de baixo, as cinco cabeças se distinguem pela forma, sem a
  cor;
- na 10, a 64 px e em cinza, as três peças de cada coluna se separam a olho;
- a 10 e a 11 não têm nenhum pixel de peça com o néon do dono fora do acento;
- a mesma rodada gera as três imagens duas vezes, e elas saem iguais.

### 17 A medida da peça

**Saída:** `godot/estudos/direcao/medir_pecas.gd`, que roda sem tela
(`--headless -s`) e escreve `docs/jogo/arte/dados/pecas_medidas.csv`: por
peça, a mediana de L em OKLab, o croma, a área de acento sobre a área frontal
do corpo e o ΔE OKLab até cada `JOGADOR`.

**Pronto quando:**

- todo superior fica em L 0,46 a 0,58 e todo inferior em 0,22 a 0,36,
  medidos só no pano (a UV fora de `PELE_UV`); a pele de raça em 0,68 a
  0,80;
- nenhuma peça passa de croma 0,10, e nenhuma fica a menos de ΔE 0,08 de um
  `JOGADOR`;
- superior e inferior distam L 0,10 ou mais nos 144 pares; rosto e superior
  também, ou o superior tem a gola acesa de frente e a cabeça não desce
  sobre ela ([o critério do rosto](04-o-cavaleiro.md#o-critério-do-rosto));
- o acento soma até 8 % da área frontal, sem contar o contorno;
- rodar duas vezes dá o mesmo CSV, byte a byte.

### 18 O primeiro minuto em imagem

**Saída:** `godot/estudos/direcao/quadros/20_encaixe.gd` e
`docs/imagens/direcao/20_encaixe.jpg` (1920×1080: seis miniaturas de
640×540), com `20_encaixe` no `QUADROS`.

**Pronto quando:** os instantes 0, 125, 190, 375, 500 e 1000 ms da troca de
uma peça, pela linha do tempo do
[04](04-o-cavaleiro.md#o-primeiro-minuto), com o encaixe no pior caso (o
toque logo depois de uma semicolcheia): a seta e a peça velha a 0,92; o
encaixe, com a peça nova a 0,06 acima e na escala 0,9, as 8 faíscas e o
acento a 2,6 no mesmo quadro; a peça assentada 4 quadros depois; a pose da
linha na colcheia seguinte; o giro da plataforma a 25°; o descanso em
`idle`; o instante e o que acontece escritos embaixo de cada miniatura, em
VT323 30. Na conferência, os instantes de 60, 250 e 750 ms saíram: a peça
nova caía antes do encaixe, e a pose e o idle vinham 125 ms e 250 ms antes
da linha do tempo do 04.

### 19 A página

**Saída:** `docs/jogo/direcao-de-arte.html`.

**Pronto quando:** a legenda do 08 deixa de dizer "o corpo tingido pela cor
do lugar" e diz que a cor do lugar está no contorno e no acento; a 10 e a 11
trocam de imagem; a 19 e a 20 ganham seção, com a etiqueta no estilo das
outras e a linha para o 04; a página abre em `file://`; nenhuma imagem passa
de 1 MB.

### O que o ajuste deixou para decidir

Do produtor de arte, 09/10. Os seis itens saíram; os desvios e os números
estão no [04, o que a medida deu](04-o-cavaleiro.md#o-que-a-medida-deu-em-0910)
e no [04, o que mudou no estudo](04-o-cavaleiro.md#o-que-mudou-no-estudo-em-0910).

- **Item 17, as faixas não passam.** Do diretor de arte, 09/10: resolvido.
  O rosto humano se mede pelo contraste com o superior: 93 de 144 pares
  passam pelo |ΔL| de 0,10 ou mais e 51 pela gola acesa, que agora fica no
  pescoço (y 0,343). O superior e o inferior se medem só no pano: a bermuda
  do male-f dá 0,298 (era 0,694), e os 144 pares de superior e inferior
  passam (o pior a 0,169). O acento máximo é 5,45 % (male-e). O
  `medir_pecas.gd` sai com 1 se algo falha. A Blusa amarela virou Blusa
  caramelo: a cor sai caramelo na faixa do tecido, e amarelo não cabe nela.
  A cabeça de raça a 1,30 fica: a cabeça deixa 63,2 % ou mais do superior à
  vista em toda raça, em pé ou sentada (piso 60 %, `medir_tronco.gd`). Está
  no [04, a cabeça e o superior](04-o-cavaleiro.md#a-cabeça-e-o-superior).
- **Item 15, o que não se mediu.** A cauda pelo vão da cadeira não aparece
  em prancha nenhuma: a 10 é de frente e o encosto a esconde. As mãos de pinça e os punhos de pedra não foram conferidos nas 32
  animações, uma a uma; nas pranchas (idle e holding-both) seguem o osso.
- **Item 16, a linha das calças na 11.** Resolvido na conferência: o
  inferior sai a 1,8× (as pernas davam cerca de 42 px, agora 76), com o
  rótulo «Tronco inferior (a 1,8×)».

## Os sons

Os sons não estão nesta lista. Todo som e toda música da Forja estão no mapa
do áudio, `docs/jogo/audio/mapa.csv`, mantido pelo diretor de som
([o mapa do áudio](../o-time/o-mapa-do-audio.md)). O produtor faz os ids do
mapa marcados para ele, pela receita de cada linha, com o gerador do
[03](03-som.md#o-gerador), e marca o estado no mapa.

## Para a próxima leva

Do produtor de arte e som, 08/10. Os 13 itens estão feitos; o que segue não coube neles.

- **Item 1, a medida da cabeça.** Resolvido pelo conferente em 08/10: o 04 diz de 213 a 340 (male-f 213, female-b 340, medido pelo `cortar.gd`).
- **Item 2, os perfis.** Resolvido pelo conferente em 08/10: o critério fala dos quatro emblemas do `pecas.csv` (Bigorna, Mola, Brasa e Lume), como decide o `sistemas/`. Malha e Prumo saíram.
- **Item 2, a etiqueta.** Resolvido pelo conferente em 08/10: a etiqueta cresceu para 660 × 140 px e o título não encosta mais.
- **O female-a.** Tem 160 triângulos por braço e um bastão em cada mão, que vêm do modelo da Kenney. O corte leva o bastão junto com o tronco superior.
- **O medalhão do diapasão.** No P3 da cadeira ele não aparece. Subir para y +0,17 e z 0,16.
- **A prancha 13.** As cinco tintas ficaram escuras: a chave em ×1 mal passa da névoa. A arena do S1 mede L 7 de média (medida no PNG, Lab). Subir a chave até a média passar de L 15.
- **A prancha 17.** Resolvido pelo conferente em 08/10: a chave das marteladas 1 a 7 passou a tungstênio 3,5 e o contorno a 0,016 / 3,0. A peça que entra se lê.
- **A cortina.** No instante de 300 ms a borda está fora da tela (x = −134). A curva tem que pôr a borda na tela já aos 300 ms.
- **O ícone do exe.** O `forja.ico` vira ficha: o exe usa `scripts/forja.ico`, que não sai do PNG do logo. Gerar o .ico do `forja-logo.svg` em 16, 32, 48 e 256 px.
- **Os sons no jogo.** Os 77 estão em `godot/estudos/direcao/som/`. A cópia para `godot/assets/sons/` e a troca no jogo são da H11. O subcomando `kenney` do gerador não foi rodado.
- **A tarja do car_acorde.** Ficou com 80 × 40 px por jogador. Conferir na TV a 3 m.
- **O README da arte.** Resolvido pelo conferente em 08/10: diz Dó, Ré, Fá e Sol, o acorde suspenso do 03.
- **A trilha.** O LEIA-ME de `ost/` e o pedido do JIN_COOP_VITORIA ficam para o produtor de música ou a H09.
- **As cabeças humanas dos outros Mini.** Do diretor de arte, 09/10: o Mini Arena, o Forest, o Skate, o Arcade, o Market e os humanos do Mini Dungeon têm o mesmo esqueleto de 7 ossos. Viram perfis novos de cabeça na próxima leva, depois das raças.
- **O acorde da build boa.** O id do som ainda não existe no mapa do áudio. Pedir ao diretor de som.
