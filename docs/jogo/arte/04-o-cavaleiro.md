# 04 O cavaleiro montável

Cada pessoa monta o seu cavaleiro: cabeça, tronco superior, tronco inferior
e uma arma ou um amuleto, e dá o nome a ele. A sensação que a tela tem que
dar é de posse: "este é meu, eu montei, e a minha build é boa".

Esta página é a arte do cavaleiro: o corte das malhas, a tela, a forja. As
peças com os seus stats, as regras que impedem, os itens, o pré-montado, o
nome e a coleção são o RPG, em [sistemas/](../sistemas/README.md).

## O que a pessoa sente

1. **Já tem um cavaleiro quando chega.** O lugar nasce com um pré-montado
   sorteado e válido. Com ✕ ✕ já se joga.
2. **Cada troca muda alguma coisa que se vê.** A peça troca no boneco, o VU
   do stat sobe ou desce, o arquétipo na etiqueta pode mudar.
3. **Uma escolha impede outra.** Não dá para ter tudo. A build é uma decisão.
4. **Ninguém na mesa tem um igual.** Nem a mesma cabeça, nem o mesmo nome
   ([entre jogadores](../sistemas/README.md#entre-jogadores)).
5. **O nome é dela.** Escrito na caneta, na etiqueta, e dito no pódio.

## As peças

O corpo vem do Kenney Mini Characters: 12 personagens (female-a a f, male-a
a f), todos com o mesmo esqueleto de 7 ossos (root, leg-left, leg-right,
torso, arm-left, arm-right, head) e as mesmas 32 animações.

### O corte

Cada glb tem duas malhas com pele: `head-mesh` e `body-mesh`. Na `body-mesh`,
**nenhum triângulo é misto**: cada um pertence a um osso só (conferido
triângulo a triângulo). O corte é limpo:

| parte | de onde vem | triângulos (female-b) |
| --- | --- | --- |
| cabeça | a `head-mesh` inteira | de 213 a 340, conforme o personagem (male-f 213, female-b 340) |
| tronco superior | os triângulos da `body-mesh` dos ossos torso, arm-left e arm-right | 50 + 72 + 72 |
| tronco inferior | os triângulos da `body-mesh` dos ossos leg-left e leg-right | 104 + 104 |

O corte se faz uma vez, por script, e gera três malhas por personagem. Como o
esqueleto é o mesmo, qualquer cabeça encaixa em qualquer superior e em
qualquer inferior, e as 32 animações servem para todas. São 12³ = 1728
corpos.

### O perfil de cada peça

Cada peça dá +2 num stat (o emblema: Bigorna, Mola, Brasa ou Lume) e +1
noutro. A peça de cada personagem, o nome que a pessoa lê e os pontos estão
em [sistemas, as peças](../sistemas/README.md#as-peças) e na tabela
[pecas.csv](../sistemas/pecas.csv).

O pio de cada cabeça ([03 O som](03-som.md#o-pio)):

| cabeça de | o pio |
| --- | --- |
| female-a, male-a | a segunda |
| female-b, male-b | a terça |
| female-c, male-c | a quarta |
| female-d, male-d | a quinta |
| female-e, male-e | a quinta de baixo |
| female-f, male-f | a oitava |

### A cadeira de rodas

O pacote traz quatro cadeiras (`wheelchair`, `wheelchair-deluxe`,
`wheelchair-power`, `wheelchair-power-deluxe`) e as animações
`wheelchair-sit`, `-look-left`, `-look-right`, `-move-forward`, `-back`,
`-left` e `-right`. No tronco inferior, ▲ e ▼ ficam na parte e um toque em
R1 alterna "Pernas" e as quatro cadeiras. A cadeira **não muda stat
nenhum**: o perfil é o da peça inferior escolhida. Em minigame de corrida, a
cadeira anda na mesma velocidade que as pernas com o mesmo Passo.

Os acessórios do mesmo pacote (`aid-glasses`, `aid-sunglasses`,
`aid_hearing`, `aid-cane`) entram como acabamento, sem stat. Eles e as
cadeiras ficam livres desde a primeira noite
([o que não tem stat](../sistemas/README.md#o-que-não-tem-stat)).

## A peça se distingue

A fala dela, ao aprovar a direção (09/10/2026): «as roupas superiores e
inferiores precisam se diferenciar. tudo tá num neon de uma única cor que nada
diferencia na hora da montagem. usamos neon mas não tão seco e uniforme
assim.» A causa estava no estudo: o `cavaleiro.gdshader` tingia o corpo
inteiro na cor do lugar (`tingir` 1,0 em `Mundo.vestir`), com o aro a 0,6 e o
brilho próprio a 0,10. Cabeça, superior e inferior saíam com o mesmo matiz e
quase o mesmo valor.

### A regra

1. **Nada se tinge.** `tingir` 0, `brilho_proprio` 0. A cor da peça é a da
   Kenney, recolorida pela faixa da parte.
2. **Cada parte tem material e faixa de valor.** A tabela é a do
   [02](02-cor-e-letra.md#o-cavaleiro-a-cor-da-peça-e-o-néon-do-dono): cabeça
   em pele (o rosto humano fica no tom da Kenney e se mede pelo contraste com
   o superior, em [o critério do rosto](#o-critério-do-rosto); a pele de raça
   é token, de 0,68 a 0,80), superior em tecido (0,46 a 0,58), inferior em
   couro e lona (0,22 a 0,36), medidos só no pano, arma em metal batido e
   amuleto em cerâmica (0,68 a 0,80).
3. **Vizinhas nunca se igualam.** Duas peças que se tocam (cabeça e superior,
   superior e inferior, o item e o braço ou o peito) têm L com diferença de
   0,10 ou mais, medida na mediana de L dos pixels de cada parte. As faixas já
   garantem isso; o matiz da Kenney (a blusa caramelo, a camisa verde, a calça
   social cinza) fica, com a croma de até 0,10.
4. **O néon é acento, com dono e nome.** Cada parte tem um acento só, na cor do
   lugar:

| parte | o acento | onde, na malha | área máxima da parte | energia |
| --- | --- | --- | --- | --- |
| cabeça humana | nenhum | o rosto fica limpo; o contorno lê a forma | 0 % | — |
| cabeça de raça | o visor (autômato), a rachadura (golem) | um vão `JANELA` com a linha de acento dentro; o orc e a raposa não têm | 6 % | 1,6 |
| tronco superior | o friso | a barra do tronco e a gola: faixa de 0,010 de altura no y mais baixo dos triângulos do osso `torso` e no mais alto deles, limitado ao pescoço (y 0,343) | 8 % | 1,6 |
| tronco inferior | a costura | uma linha de 0,008 de largura na lateral de fora de cada perna (o x de maior módulo dos triângulos de `leg-left` e `leg-right`) | 5 % | 1,6 |
| item | a runa | o emblema em relevo do amuleto; nas armas, o fio: a face de bater do martelo, as unhas da âncora, o aro do escudo | 12 % do item | 1,6 |

   - **O teto do cavaleiro:** somados os acentos, no máximo 8 % da área de
     frente do corpo (pixels de acento ÷ pixels do corpo, no render de frente,
     sem contar o contorno).
   - **O contorno** continua o do [07](07-vfx.md#a-tabela-do-brilho): linha de
     0,012, energia 1,6 na montagem e 2,4 no jogo. Ele é a silhueta do dono, e
     não conta na área.
   - **O aro de luz** (o fresnel do shader) cai de 0,6 para 0,25.
   - **No encaixe** de uma peça, o acento dela sobe a 2,6 e volta a 1,6 em
     250 ms (`SAI`): é o «pegou» ([o primeiro minuto](#o-primeiro-minuto)).
5. **O néon do dono convive com a cor da peça assim:** o acento é sempre
   `JOGADOR[lugar]`; a peça nunca tem croma acima de 0,10 nem fica a menos de
   0,08 (ΔE OKLab) de um `JOGADOR`; o acento encosta só em base com L de até
   0,58, e na cabeça e no item mora num vão `JANELA`. Uma camisa roxa no P2
   (magenta) se lê: o tecido é L 0,52 e croma 0,08, o friso é L 0,68 e croma
   0,24, e brilha acima do limiar do glow (0,82).

### O teste: 64 px e cinza

O produtor renderiza cada cavaleiro de frente com 64 px de altura e o
converte para L (OKLab). Passa quando:

- a mediana de L do superior e do inferior, no pano, cai cada uma na faixa
  da parte, e as duas diferem em 0,10 ou mais;
- o rosto humano e o superior diferem em 0,10 ou mais, ou a gola acesa
  aparece entre os dois; a pele de raça fica de 0,68 a 0,80;
- a cabeça deixa à vista 60 % ou mais da frente do superior, em pé e sentado
  ([a cabeça e o superior](#a-cabeça-e-o-superior));
- na máscara (só a silhueta, sem cor), a cabeça, o tronco com os braços e as
  pernas se separam: o pescoço ou a gola marcam o corte de cima, o vão entre
  as pernas o de baixo;
- as cinco cabeças (a humana e as quatro raças) se distinguem pela máscara de
  64 px, sem cor;
- a área de acento fica nos tetos da tabela.

### O que a medida deu, em 09/10

O `medir_pecas.gd` mede as 36 peças nas faces de frente e grava
[pecas_medidas.csv](dados/pecas_medidas.csv). Duas rodadas dão o mesmo
arquivo, byte a byte. Sai com 1 se um critério falha.

| critério | o pior caso | passa |
| --- | --- | --- |
| croma de toda face | 0,099 (teto 0,10) | sim |
| ΔE OKLab até um `JOGADOR` | 0,085 (piso 0,08) | sim |
| acento sobre a área de frente | 5,45 % no superior do male-e (teto 8 %) | sim |
| superior em L 0,46 a 0,58, no pano | 12 de 12, de 0,501 a 0,562 | sim |
| inferior em L 0,22 a 0,36, no pano | 12 de 12, de 0,269 a 0,332 | sim |
| superior e inferior a 0,10 ou mais | 144 de 144 pares; o pior, 0,501 − 0,332 = 0,169 | sim |
| rosto e superior | 144 de 144 pares: 93 pelo \|ΔL\| de 0,10 ou mais, 51 pela gola acesa (o menor \|ΔL\| é 0,006) | sim |
| pele de raça em L 0,68 a 0,80 | 4 de 4 (a escória no piso, 0,680) | sim |

**A decisão: a pele não se clareia.** Os 12 rostos da Kenney têm tons de
pele de 0,52 a 0,72. Subir todos para 0,68 apaga essa diversidade. O
`recolorir` deixa a pele como veio (papel `personagem`, `l0` 0,06 e `l1`
0,86) e só corta o croma.

### O critério do rosto

Decidido em 09/10. A faixa fixa de 0,68 a 0,80 passava 2 dos 12 rostos e
cobrava da pele o que é trabalho do corte. O rosto humano se mede pelo
contraste com o superior, qualquer que seja o par (o jogador monta a cabeça
de um com o superior de outro, então são 144 pares):

1. **|ΔL| de 0,10 ou mais** entre a mediana de L do rosto (só as faces de
   pele da cabeça) e a do superior (só o pano). Passam 93 pares.
2. **Senão, a gola acesa.** O par que não chega a 0,10 passa se o superior
   tem a faixa da gola do friso de frente e a cabeça não desce sobre ela (o
   y mais baixo da cabeça fica no topo da gola ou acima). Passam 51 pares.
   A female-e (a cabeça desce a 0,293) e o male-b (a barba, a 0,263) cobrem a
   gola, então só passam pelo ΔL: o rosto deles é 0,720 e 0,694, a 0,158 e
   a 0,132 do superior mais claro (0,562).
3. **A gola fica no pescoço.** A faixa da gola vai no menor entre o topo do
   tronco e y 0,343 (o pescoço). A Jaqueta preta da female-f subia a 0,385, o
   Macacão do male-e e a Regata verde do male-f a 0,357: a gola caía atrás da
   cabeça e não se via. As outras 9 não mudam.

A faixa de 0,68 a 0,80 fica só para as raças, cuja pele é token.

**O male-f.** O inferior dele é a bermuda: a mediana caía na pele das pernas
(0,694). O superior e o inferior agora se medem só no pano (a UV fora de
`PELE_UV`): a bermuda dá 0,298 e a Regata verde 0,532 (antes 0,593, com o
braço). O male-f fica no inferior; a perna de fora é pele, como a mão.

**A Blusa caramelo.** A peça da female-b se chamava Blusa amarela. A cor da
Kenney é #ffab42, laranja; no tecido (L 0,46 a 0,58, croma até 0,10) vira
#93693a, L 0,55 e croma 0,08, e sob a luz quente da forja sai salmão. Amarelo
não cabe na faixa do tecido, e o pixel do colormap é o mesmo do superior da
female-f e do male-e. Muda o nome, não a cor:
[pecas.csv](../sistemas/pecas.csv).

## As raças

A fala dela: «só temos assets de personagens humanos. Acho que podemos
explorar outras raças também.» Além da humana, quatro raças: o orc, o
autômato de latão, o golem de escória e a raposa ferreira.

### Como a raça entra na montagem

- **A raça é aparência.** Nenhuma muda stat, caixa de colisão, velocidade
  ou janela de julgamento. A caixa de colisão é a mesma cápsula para as cinco.
  O [sistemas](../sistemas/README.md#o-que-não-tem-stat) diz isso numa linha.
- **A raça dá a forma; as peças dão a roupa e o perfil.** A raça troca a
  cabeça inteira, a pele (o rosto e as mãos), e pode pôr cauda e mudar a
  proporção. O superior e o inferior continuam as 24 peças humanas, vestidas
  pela raça: um orc de Farda azul e Calça social.
- **O perfil da cabeça continua.** Na linha da cabeça, ◀ ▶ escolhe entre os
  12 perfis (os stats e o pio de [pecas.csv](../sistemas/pecas.csv)), em
  qualquer raça. A cor do cabelo daquele perfil vai para a marca do perfil da
  raça (a tabela abaixo). A cabeça única na mesa continua pelo perfil: dois
  orcs podem, com perfis e marcas de cores diferentes.
- **R1 na linha da cabeça** alterna Humana, Orc, Autômato, Golem e Raposa,
  com `ui_peca` a +7 semitons, como a troca de cabeça. Fora da humana, o
  rótulo «Cabeça» dá lugar ao nome da raça, na mesma letra (Archivo Narrow 600
  de 30 px; «Autômato» tem 8 letras, como «Superior»).
- **O pré-montado sorteia a raça:** metade das vezes humana, a outra metade
  uma das quatro, pela mesma semente do lugar. Quem chega já pode ter um
  golem.
- **Livres desde a primeira noite**, como as cadeiras: nenhuma raça é prêmio
  da coleção.
- **Com a cadeira de rodas:** toda raça senta; a cauda da raposa sai pelo vão
  do encosto, 0,05 mais alta.

### As quatro

Medidas nas unidades do personagem (o `male-a` tem 0,67 de altura; a cabeça
dele vai de y 0,34 a 0,67).

| raça | a cabeça | as mãos | a cauda | a proporção | a pele | a marca do perfil | de onde vem a malha |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Orc** | a `head-mesh` do orc: presas e orelhas de ponta; vai de y 0,34 a 0,78 (a cabeça 33 % mais alta que a humana) | as do superior, na pele da raça | nenhuma | só a cabeça muda | `PELE_ORC` | o tufo no alto da cabeça (por código, caixa de 0,06, se a malha não tiver cabelo) | Kenney Mini Dungeon, `character-orc.glb`: o mesmo esqueleto de 7 ossos e as mesmas 32 animações; corte limpo (0 triângulo misto): cabeça 176, superior 144, inferior 54 |
| **Autômato de latão** | caixa chanfrada de 0,30 × 0,28 × 0,28; o visor é um vão `JANELA` de 0,24 × 0,06 a 0,10 do topo, com a linha de acento de 0,22 × 0,02 dentro; antena de 0,08 com a bola de 0,025 | uma pinça de dois dedos (duas caixas de 0,02 × 0,05) presa ao punho de cada braço | nenhuma | a mesma do humano | `PELE_LATAO`, `metallic` 0,2 | a bola da antena | por código (`ArrayMesh`, como a bigorna), até 300 triângulos, presa ao osso `head` por `BoneAttachment3D` |
| **Golem de escória** | bloco facetado de 0,34 × 0,24 × 0,30, sem pescoço (desce 0,03); a rachadura: três traços de 0,005 num vão `JANELA` na testa, com o acento dentro | um punho de pedra (cubo chanfrado de 0,075) em cada punho | nenhuma | o osso `torso` a 1,15 em x e z (ombro e braço mais largos); a cabeça compensa a 0,87 | `PELE_ESCORIA` | dois tufos de líquen de 0,05 no alto | por código, até 400 triângulos, no osso `head`; os punhos no punho que `Montar.mao` acha |
| **Raposa ferreira** | caixa de 0,28 × 0,24 × 0,26; focinho em prisma de 0,12 × 0,08 × 0,10 com a ponta em `TINTA`; duas orelhas em prisma de 0,08 × 0,10; olhos de 0,03 em `TINTA` | as do superior, em pelo (`PELE_RAPOSA`) | o `tail` do `animal-fox` (Kenney Cube Pets) a ×0,33 (0,30 de comprimento), no osso `root` em (0; 0,20; −0,10), balança ±8° a cada batida, `ENTRA_SAI` | a mesma do humano | `PELE_RAPOSA` | a ponta das orelhas e a ponta da cauda | a cabeça por código, até 300 triângulos; a cauda da Kenney, com o colormap do Cube Pets na pasta dele |

A cabeça de cada raça passa no teste de 64 px e cinza: o rosto na faixa de
0,68 a 0,80 (a pele é token), e a silhueta própria (as presas e a cabeça alta do
orc, a antena do autômato, o bloco sem pescoço do golem, as orelhas e o
focinho da raposa).

### O que mudou no estudo, em 09/10

O produtor fez as quatro pelas medidas acima. Onde a prancha pediu outra
coisa, a medida mudou e ficou registrada aqui:

- **A cabeça de raça a 1,30.** As cabeças por código saíam 30 % menores que
  a humana (0,45 de altura com o cabelo). `Racas.ESCALA_CABECA` = 1,30, para
  as quatro; a medida do superior que ela deixa à vista está em
  [a cabeça e o superior](#a-cabeça-e-o-superior).
- **O golem é um tronco de pirâmide.** O bloco de 0,34 × 0,24 × 0,30 se lia,
  a 64 px, como a cabeça humana. Agora: a base de 0,36 × 0,30, o topo de
  0,26 × 0,24, 0,27 de altura, faces chapadas. Na frente: a sobrancelha de
  pedra de 0,30 × 0,045 × 0,07, os olhos e a boca em `TINTA`, duas pedras de
  0,08 × 0,075 × 0,12 nas bochechas (x ±0,165) e uma laje torta de
  0,15 × 0,05 × 0,14 no alto. A rachadura é um zigue-zague de três traços:
  o vão `JANELA` de 0,018, com o acento de 0,007 dentro. O líquen vai em dois
  tufos desencontrados.
- **A raposa ganhou a máscara creme.** Uma placa de 0,26 × 0,10 em
  `ETIQUETA_SOMBRA` cobre a metade de baixo da cara; o focinho é creme, de
  0,11 × 0,07 × 0,08, com o nariz em `TINTA` de 0,045 × 0,028. Sem ela, a
  cabeça laranja se perdia no superior laranja.
- **A boca do autômato.** Uma grade de três frestas `JANELA` de
  0,018 × 0,04, a 0,04 uma da outra.
- **O verde do orc.** O verde da pele do `character-orc` vira o matiz e o
  croma de `PELE_ORC` (#89aa77), com a luz 0,05 abaixo, no `recolorir`.
- **A costura vai também na frente da perna**, junto ao lado de fora (0,008
  de largura). Só na lateral, ela não aparecia de frente.
- **O teto e a folga.** O teto de croma no `recolorir` é 0,098 e o piso de
  ΔE até um `JOGADOR` é 0,085. A 0,10 e a 0,08, o arredondamento do sRGB de
  8 bits passava do limite (o croma 0,101; o cabelo ruivo do male-c a 0,057
  do âmbar antes da folga). O `graduar` baixa o croma 10 % por passo até a
  peça ficar a 0,085 de todo `JOGADOR`.

### A cabeça e o superior

Decidido em 09/10. Na 10, a cabeça de raça a 1,30 parecia cobrir o peito (a
raposa sentada; a sombra da cabeça do autômato no Terno do P4). O
`medir_tronco.gd` mede: as 5 cabeças × os 12 superiores × 10 poses (em pé:
`idle`, `holding-right`, `holding-left`, o aceno `emote-yes` em 0,2, 0,4, 0,6
e 0,8, `interact-right`; sentada, na `wheelchair-deluxe`: `wheelchair-sit` e
`wheelchair-look-left`), de frente, em cor chapada por parte, e grava
[tronco_aparece.csv](dados/tronco_aparece.csv) (600 linhas). Sai com 1 se
algum caso fica abaixo do piso.

**O critério:** a cabeça deixa à vista 60 % ou mais da área de frente do
superior que o resto do corpo deixa (o render inteiro ÷ o render sem a
cabeça). O piso vale para a cabeça, porque é ela que a escala muda.

| raça | em pé, o pior caso | sentada, o pior caso |
| --- | --- | --- |
| humana | 64,6 % (o aceno, a barba do male-b) | 85,8 % |
| orc | 81,2 % | 85,6 % |
| autômato | 80,6 % | 85,1 % |
| golem | 63,2 % (o aceno, superior da female-f; o mais apertado) | 80,1 % |
| raposa | 77,9 % | 85,6 % |

**A decisão: `ESCALA_CABECA` fica 1,30 para as quatro.** Todas passam o piso,
em pé e sentadas, e a 1,30 as cabeças de raça ficam dentro do envelope da
humana: de largura, o autômato 0,44, o golem 0,53 (já com a compensação de
0,87 do osso) e a raposa 0,36, contra 0,45 a 0,59 da humana; de fundura, de
0,34 a 0,42, contra 0,34 a 0,53.

**Sentado, o que tapa o peito é a cadeira.** Com tudo à frente, o superior
sentado aparece de 36,6 % a 40,2 % em toda raça, a humana inclusive
(38,0 %). As rodas e os braços da cadeira escondem os braços (cerca de 35
pontos) e as coxas sobem à frente da barra (cerca de 15); a cabeça tira
menos de 20 % do que sobra. Inclinar a câmera a 10° e a 20° piora (a cabeça
cobre mais), girar a plataforma de 20° a 40° também, e as três cadeiras
(`wheelchair`, a `deluxe` e a `power`) dão quase o mesmo. Fica como está.

**A sombra no P4** vem da luz principal (a uns 38° de elevação) e é a mesma
de uma cabeça humana da mesma fundura; o Terno é escuro (L 0,50, croma
0,008), por isso ela se nota. Não é a escala.

### O que se pesquisou e ficou de fora

Medido nos `.glb` do All-in-1 3.7.0 (`python3 scripts/kenney.py buscar
character`, `animal`) e conferido em kenney.nl, categoria 3D, em 09/10/2026:
nenhum pacote de personagem além destes.

| pacote | o que tem | por que não é raça |
| --- | --- | --- |
| Graveyard Kit: `character-skeleton`, `-zombie`, `-vampire`, `-ghost`, `-keeper` | peças rígidas, uma por osso, com as mesmas 32 animações | são os monstros do terror (o `character-skeleton` é o guardião de Zero Absoluto, o `character-ghost` anda na Neblina de Dados): um jogador com a cara do monstro quebra a leitura de quem é inimigo. A medida das peças deles serve de régua para as raças por código (a perna em y 0,223, o braço em x ±0,125) |
| Cube Pets: 24 animais | quadrúpedes rígidos, 8 animações, sem `holding` nem `attack` | não seguram item nem martelam; entram só como peça solta (a cauda da raposa) |
| Platformer Kit: `character-oobi`, `-oodi`, `-ooli`, `-oopi`, `-oozi` | 6 ossos, sem o osso `head`, 25 animações | não há cabeça para cortar nem para trocar |
| Blocky Characters, Animated Characters | outro esqueleto | já fora pela curadoria do [14](../14-os-assets-kenney.md#a-curadoria) |
| Mini Arena `character-soldier`, Mini Forest `character-archer`, Mini Skate, Mini Arcade, Mini Market, Mini Dungeon `character-human` | o mesmo esqueleto, cortes limpos | são humanos: ampliam as cabeças humanas, não as raças (para a próxima leva) |

## Os stats e as regras

Os quatro stats, a regra que impede, o que cada item pede, a liga, o
arquétipo, as regras entre jogadores e o pré-montado estão em
[sistemas/](../sistemas/README.md):

- [os stats](../sistemas/README.md#os-stats) e o que cada um muda em cada gênero;
- [a regra que impede](../sistemas/README.md#a-regra-que-impede) e como a tela a mostra;
- [entre jogadores](../sistemas/README.md#entre-jogadores);
- [a arma ou o amuleto](../sistemas/README.md#a-arma-ou-o-amuleto), com a liga;
- [o arquétipo](../sistemas/README.md#o-arquétipo) e [a build boa](../sistemas/README.md#a-build-boa);
- [o pré-montado](../sistemas/README.md#o-pré-montado).

## A arma ou o amuleto

Seis itens: três armas e três amuletos. O que cada um pede e faz está em
[sistemas](../sistemas/README.md#a-arma-ou-o-amuleto) e no doc
[06b](../06b-a-construcao-do-cavaleiro.md#o-item-tem-mecânica). Aqui, onde
cada um fica no corpo e de onde vem a malha:

| item | tipo | onde fica | a malha |
| --- | --- | --- | --- |
| Martelo | arma | mão direita | `tool-hammer` (Survival Kit) |
| Escudo | arma | braço esquerdo | `shield-round` (Mini Dungeon) |
| Âncora | arma | mão direita | por código (ArrayMesh) |
| Fole | amuleto | peito | por código |
| Lanterna | amuleto | peito | por código |
| Diapasão | amuleto | peito | por código |

Os amuletos são medalhões de 12 cm presos no peito, desenhados por código no
mesmo estilo da bigorna: o disco em cerâmica esmaltada (L de 0,68 a 0,80,
rugosidade 0,35), o emblema em relevo em latão (`metallic` 0,2) e a runa, o
acento na cor do dono, num vão `JANELA` em volta do emblema
([a peça se distingue](#a-peça-se-distingue)).

## A tela de montagem

O plano é o de [01 O cinema](01-cinema.md#o-plano-de-cada-momento): 50 mm,
frontal, à altura do peito, os quatro lugares lado a lado. A música é a da
construção, a 120 BPM, e toda troca cai na batida.

### Uma coluna

Cada lugar tem uma coluna de 432 px dentro da área segura (x = 96 + 432·i).

| y (px) | o que tem |
| --- | --- |
| 60 a 150 | a placa do lugar: P# em Bungee 40, as lâmpadas, o nome do cavaleiro em Archivo Narrow 600 de 32 px |
| 160 a 600 | o cavaleiro em 3D, de frente, no idle na batida; contra-luz na cor do lugar, chave violeta até forjar |
| 610 a 650 | a etiqueta do arquétipo, em Permanent Marker de 30 px, em `TINTA` |
| 660 a 860 | as cinco linhas: Cabeça, Superior, Inferior, Arma ou amuleto, Nome |
| 870 a 1010 | os quatro VUs: Peso, Passo, Fôlego, Faro |

Cada linha tem 40 px: o rótulo em Archivo Narrow 600 de 30 px, e
`◀ nome da peça ▶`. A linha escolhida fica em `CASCO_ALTO` com borda de 3 px
na cor do lugar. A linha travada tem um cadeado desenhado ao lado.

Cada VU tem 5 segmentos na cor do lugar, apagados em `GRAFITE`, e o rótulo
em VT323 de 30 px. Enquanto a pessoa passa por uma peça, os segmentos que
ela mudaria piscam em `ETIQUETA` na batida, antes de confirmar.

### Os botões

| botão | faz |
| --- | --- |
| ▲ ▼ | escolhe a linha |
| ◀ ▶ | troca a peça (ou o nome) |
| R1 | na cabeça: a raça ([as raças](#as-raças)); no tronco inferior: Pernas ou cadeira |
| △ | sorteia tudo o que não está travado |
| □ (toque) | trava ou destrava a linha |
| □ (segurar 1 s) | troca de lugar (doc 05) |
| ✕ | forja: as 8 marteladas |
| ○ | volta (desfaz a forja; da primeira linha, sai do lugar) |

As dicas na tela seguem a voz do texto: "Botão △ (Sortear)", "Botão ✕
(Forjar)".

### A forja

O ✕ começa as 8 marteladas a 120 BPM. Elas calibram o controle (doc 04) e,
na tela, forjam o cavaleiro parte por parte:

| martelada | o que acende em tungstênio |
| --- | --- |
| 1 e 2 | a cabeça |
| 3 e 4 | o tronco superior |
| 5 e 6 | o tronco inferior |
| 7 | a arma ou o amuleto |
| 8 | o nome, escrito na caneta na etiqueta (`fx_caneta`) |

Na oitava, a chave da coluna passa de violeta a tungstênio em 1 compasso, e
o pio do cavaleiro sai do controle. Quando todos estão prontos, o corte vai
para o plano dos prontos (85 mm, baixo, travelling pelos quatro).

## O primeiro minuto

A fala dela: «as pessoas precisam ter prazer no início do jogo.» A montagem é
o primeiro minuto da noite. Cada troca de peça tem que dar gosto: um encaixe
que se ouve, se sente na mão e se vê, e um cavaleiro que reage. A 120 BPM, a
batida tem 500 ms, a colcheia 250 ms e a semicolcheia 125 ms.

### Uma troca, do toque ao descanso

| quando | o que acontece | quanto dura |
| --- | --- | --- |
| o quadro do toque (0 ms) | a seta apertada (◀ ou ▶) cresce a 1,2 e volta, `MOLA`; a peça velha afunda à escala 0,92, `ENTRA` | 4 quadros; 2 quadros |
| **o encaixe**: a semicolcheia seguinte (de 0 a 125 ms depois do toque) | a peça nova cai de 0,06 acima e chega da escala 0,9 a 1,0, `MOLA`; `ui_peca` na altura da parte (cabeça +7, superior +4, inferior 0, item −5 semitons) no alto-falante do dono e na TV a −12 dB; o pulso de metal de 150 Hz nos atuadores (na arma e no amuleto, o pulso do item, 80 ms, pelo [03](03-som.md#o-casamento-evento-por-evento)); 8 faíscas na junta, na cor do dono, energia 2,4; o acento da peça nova sobe a 2,6 e volta a 1,6, `SAI`; o VU anda um segmento a cada 30 ms | tudo no mesmo quadro de 16,7 ms; o som 120 ms, o pulso 40 ms, as faíscas 12 quadros, o acento 250 ms |
| o encaixe + 250 ms (a colcheia), se nenhum toque novo chegou | a pose de reação e o giro da plataforma (as tabelas abaixo) | 500 ms (1 batida) |
| a mesma colcheia, na troca de cabeça ou de raça | o pio da cabeça nova, `pio_p{n}_{intervalo}`, na TV e no alto-falante | 300 ms |
| a batida seguinte, se o arquétipo mudou | a etiqueta vira (`ENTRA_SAI`) e a caneta reescreve o arquétipo com `fx_caneta` | 180 ms; 400 ms |
| a batida seguinte, se o item entrou em liga | `car_liga` (Dó5 e Sol5) e a marca da liga no VU acende | 400 ms |
| a batida seguinte, se a build ficou boa | os dois sublinhados de caneta (`fx_caneta`) e o acorde do lugar no alto-falante ([a build boa](../sistemas/README.md#a-build-boa); o id é do diretor de som) | 400 ms |
| o descanso | a pose volta ao `idle` | 120 ms |

Do toque ao descanso, uma troca leva 1 s (2 batidas). Dez trocas cabem em
10 s.

**A roleta e o prêmio.** Toques com menos de 250 ms entre eles são a roleta:
cada um faz o encaixe (som, pulso, peça), com 4 faíscas em vez de 8, e nada
mais. A pose, o giro e o pio esperam a pessoa parar 250 ms numa peça. Passar
rápido soa como roleta; parar é o prêmio.

**O sorteio (△)** segue o [05](05-movimento.md#as-poses-de-cada-momento): 6
trocas, uma por semicolcheia, a última em `MOLA` num tempo; depois, a reação
da cabeça (o aceno e o pio).

### A pose de cada linha

| linha | a pose (animação do Mini Characters) | o giro da plataforma | o que soa a mais |
| --- | --- | --- | --- |
| Cabeça e raça | `emote-yes`: o aceno | 25° para o centro da tela e volta | o pio da cabeça nova |
| Superior | `holding-both`: os braços sobem à frente, como quem veste | 25°, como a cabeça | — |
| Inferior | `attack-kick-right`: o chute que testa a bota; na cadeira, `wheelchair-move-forward` (a cadeira anda 0,1 e volta) | nenhum: o chute já move | — |
| Arma | `attack-melee-right` (com o escudo, `attack-melee-left`): o golpe de teste, com o contato na colcheia | nenhum | a vibração do item ([03](03-som.md#o-casamento-evento-por-evento)) |
| Amuleto | `interact-right`: a mão toca o peito | 25° | — |
| Nome | nenhuma | nenhum | `fx_caneta` a cada palavra confirmada |

**O giro é da plataforma, não da câmera.** Os quatro lugares dividem um plano
(50 mm, frontal, [01](01-cinema.md#o-plano-de-cada-momento)); mexer a câmera
para um mexeria os quatro. Quem gira é o cavaleiro sobre o anel: ida em
120 ms (`SAI`), fica 260 ms, volta em 120 ms (`ENTRA_SAI`). A câmera só se
mexe quando todos forjaram (o corte para os prontos).

### O carimbo do nome, na forja

Na oitava martelada:

- a plataforma dá uma volta inteira, 360° em 1 compasso (2 s), `ENTRA_SAI`;
- o nome na placa pousa como carimbo ([07](07-vfx.md#o-carimbo)): escala de
  1,35 a 1,0 em 80 ms, `MOLA`, inclinado −4°, com a chapa `FITA` deslocada
  3 px (round(0,08 × 32)); a letra continua a da placa, Archivo Narrow 600 de
  32 px;
- «Forjado», em VT323 de 30 px e `ETIQUETA`, aparece embaixo do nome na
  batida seguinte;
- a oitava martelada é do degrau «golpe» da
  [diversão](../diversao/README.md#o-exagero-do-impacto): parada de 2 quadros
  (33 ms) só no cavaleiro.

### Com o movimento reduzido

Pelo [10](10-acessibilidade.md#o-movimento-reduzido): o giro e a volta inteira
somem; a peça nova chega por opacidade em 4 quadros; o carimbo chega por
opacidade em 4 quadros; as faíscas caem para 4. A pose fica: é o corpo, não a
câmera. O som, o pulso e o pio não mudam.

### Conferido contra a régua da diversão

A [régua](../diversao/README.md#a-régua-da-diversão) é de minigame; a
montagem cumpre os itens que valem fora dele.

| item da régua | como a montagem cumpre |
| --- | --- |
| 1, a graça em 10 s | o pré-montado está a uma troca da build boa ([o pré-montado](../sistemas/README.md#o-pré-montado)): a primeira troca certa toca `car_liga` e sublinha o arquétipo, e uma troca leva 1 s |
| 3, ensina sem falar | o VU pisca o que a peça mudaria antes da troca; a pose mostra a peça nova; o texto na tela é só o nome das peças e as dicas de botão |
| 7, ninguém fica 8 batidas parado | o cavaleiro abaixa 2 % em toda batida ([05](05-movimento.md#as-poses-de-cada-momento)); quem já forjou faz `emote-yes` no tempo 1 do compasso dele |
| 9, o impacto no mesmo quadro e na batida | no encaixe, a peça, `ui_peca` na TV e no controle e o pulso saem no mesmo quadro de 16,7 ms, na semicolcheia |
| o exagero do impacto | a troca é do degrau «toque» (8 faíscas, a consequência de 1 batida: a pose); a oitava martelada é «golpe» |
| a medida da noite ([sistemas](../sistemas/README.md#o-que-a-noite-de-seis-horas-mede)) | a primeira montagem em até 90 s, e no máximo 50 % forjando sem trocar nada na segunda noite: é o que mede se a troca dá gosto |

Os itens 2, 4, 5, 6, 8 e 10 falam da partida de um minigame e não se aplicam
à montagem.

## O nome

As regras do nome (o sorteado, o tamanho, o filtro, a maiúscula) estão em
[sistemas, o nome](../sistemas/README.md#o-nome). O nome vai na etiqueta em Permanent Marker, no HUD
em Archivo Narrow, e no pódio em Bungee.

## O acabamento e a coleção

O acabamento (fosco, polido, riscado, dourado) sai da montagem: são cinco
linhas e bastam. Ele vira desbloqueio da coleção (G06), escolhido no salão.
Nenhum muda stat. As regras da coleção e da progressão estão em
[sistemas, a progressão](../sistemas/README.md#a-progressão-e-a-coleção).

## O que muda nos outros documentos

- O doc [06b](../06b-a-construcao-do-cavaleiro.md) foi reescrito com esta
  montagem.
- A G02 e a G03 ganham uma nota no topo: a G13 muda os passos e os itens.
- O doc [11](../11-arte-e-personagens.md#os-personagens) ganha uma linha que
  aponta para cá.
