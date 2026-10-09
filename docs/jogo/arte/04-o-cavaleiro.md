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
   em pele (rosto com L de 0,68 a 0,80), superior em tecido (0,46 a 0,58),
   inferior em couro e lona (0,22 a 0,36), arma em metal batido e amuleto em
   cerâmica (0,68 a 0,80).
3. **Vizinhas nunca se igualam.** Duas peças que se tocam (cabeça e superior,
   superior e inferior, o item e o braço ou o peito) têm L com diferença de
   0,10 ou mais, medida na mediana de L dos pixels de cada parte. As faixas já
   garantem isso; o matiz da Kenney (a blusa amarela, a camisa verde, a calça
   social cinza) fica, com a croma de até 0,10.
4. **O néon é acento, com dono e nome.** Cada parte tem um acento só, na cor do
   lugar:

| parte | o acento | onde, na malha | área máxima da parte | energia |
| --- | --- | --- | --- | --- |
| cabeça humana | nenhum | o rosto fica limpo; o contorno lê a forma | 0 % | — |
| cabeça de raça | o visor (autômato), a rachadura (golem) | um vão `JANELA` com a linha de acento dentro; o orc e a raposa não têm | 6 % | 1,6 |
| tronco superior | o friso | a barra do tronco e a gola: faixa de 0,010 de altura no y mais baixo e no mais alto dos triângulos do osso `torso` | 8 % | 1,6 |
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

- a mediana de L da cabeça, do superior e do inferior cai cada uma na faixa
  da parte, e vizinhas diferem em 0,10 ou mais;
- na máscara (só a silhueta, sem cor), a cabeça, o tronco com os braços e as
  pernas se separam: o pescoço ou a gola marcam o corte de cima, o vão entre
  as pernas o de baixo;
- as cinco cabeças (a humana e as quatro raças) se distinguem pela máscara de
  64 px, sem cor;
- a área de acento fica nos tetos da tabela.

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
| R1 | no tronco inferior: Pernas ou cadeira |
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
