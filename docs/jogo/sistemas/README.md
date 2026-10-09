# O RPG da Forja

Cada pessoa monta o seu cavaleiro: cabeça, tronco superior, tronco inferior e uma arma ou um amuleto. Dá o nome a ele.
Os stats diferenciam um cavaleiro do outro, uma escolha impede outra, e todo lugar nasce com um pré-montado sorteado.
O alvo é uma frase: **"este é meu, eu montei, e a minha build é boa"**.

Esta pasta é o sistema inteiro. A arte do cavaleiro (o corte das malhas, a tela, a forja) mora em
[arte/04 O cavaleiro montável](../arte/04-o-cavaleiro.md). A tela da construção, contada para quem joga, mora em
[06b A construção do cavaleiro](../06b-a-construcao-do-cavaleiro.md).

**Os números são proposta.** Todos os CSV desta pasta têm a coluna `estado` em `proposta`. A noite de seis horas
mede (veja [o que a noite mede](#o-que-a-noite-de-seis-horas-mede)) e só então um valor vira `medido`. Quando este
texto e um CSV discordam, vale o CSV, e o texto se corrige.

## O mantra

> **No corpo, Bigorna ou Mola. No espírito, Brasa ou Lume.**

Quatro stats, em dois eixos. O corpo é Peso (Bigorna) contra Passo (Mola). O espírito é Fôlego (Brasa) contra Faro
(Lume). Cada cavaleiro fica de um lado de cada eixo, e isso dá os quatro tipos de cavaleiro. É o mesmo corte da fita:
lado A é o corpo, lado B é o espírito ([a alma](../arte/README.md#a-noite-é-uma-fita)).

|  | **Brasa** (Fôlego) | **Lume** (Faro) |
| --- | --- | --- |
| **Bigorna** (Peso) | Muralha: não sai do lugar e levanta logo | Torre: não sai do lugar e vê o golpe chegando |
| **Mola** (Passo) | Corrente: corre e levanta logo | Relâmpago: corre e vê o caminho antes |

## Montar um cavaleiro no papel

Cinco passos, com a tabela das [peças](#as-peças) na mão.

1. **Escolha as três peças.** Cada uma dá +2 no stat principal (o emblema) e +1 no secundário.
2. **Confira a regra.** Nenhuma Bigorna junto com Mola, nenhuma Brasa junto com Lume (só o emblema conta, o +1 não).
3. **Some.** Cada stat começa em 1. Some as peças. O que passar de 5 se perde.
4. **Leia o arquétipo.** Os dois stats mais altos dão o nome ([o arquétipo](#o-arquétipo)).
5. **Escolha o item.** Ele pede um mínimo. Com o stat no nível da liga, a troca do item some ([o item](#a-arma-ou-o-amuleto)).

**Um exemplo.** Quepe azul (Brasa: Fôlego +2, Passo +1), Jaqueta preta (Brasa: Fôlego +2, Peso +1), Tênis amarelo
(Bigorna: Peso +2, Faro +1).

| stat | base | Quepe | Jaqueta | Tênis | total |
| --- | --- | --- | --- | --- | --- |
| Peso | 1 | | +1 | +2 | **4** |
| Passo | 1 | +1 | | | **2** |
| Fôlego | 1 | +2 | +2 | | **5** |
| Faro | 1 | | | +1 | **2** |

- A regra: Brasa, Brasa e Bigorna. Nenhum oposto. Vale.
- Nenhum ponto perdido (nada passou de 5).
- Os dois mais altos: Fôlego 5 e Peso 4. É uma **Muralha**.
- Os itens que o corpo alcança: Martelo (pede Peso 4), Âncora (Peso 3 e Fôlego 3), Fole (Fôlego 4).
- Com o Martelo, fora da liga (a liga pede Peso 5). Com a Âncora ou o Fole, **em liga**. Âncora ou Fole é a
  [build boa](#a-build-boa).
- No jogo: cai 25 % menos tempo (Fôlego 5), sofre 8 % menos empurrão (Peso 4), corre 3 % mais devagar (Passo 2) e
  recebe o aviso 20 ms mais tarde (Faro 2).

O mesmo exemplo sai de um comando:

```
python3 docs/jogo/sistemas/conferir.py male-c female-f male-a ancora
```

**Um travado.** Barba ruiva (Bigorna) com Terno (Mola) não se monta: Bigorna e Mola no mesmo corpo. Na tela, com a
Barba ruiva na cabeça, o Terno nem aparece como opção do superior.

## As peças

O corpo vem do Kenney Mini Characters: 12 personagens, o mesmo esqueleto, o corte em três malhas
([arte/04, o corte](../arte/04-o-cavaleiro.md#o-corte)). São **36 peças**: 12 cabeças, 12 superiores e 12
inferiores. A tabela inteira é [pecas.csv](pecas.csv).

Cada peça dá **3 pontos**: +2 no stat principal e +1 num secundário, sempre diferente do principal. Os 12 pares
(principal, secundário) possíveis aparecem **uma vez em cada parte**. Por isso nenhuma parte favorece um stat: cada
stat é principal em 3 cabeças, 3 superiores e 3 inferiores.

O principal dá o emblema da peça:

| emblema | stat principal |
| --- | --- |
| Bigorna | Peso |
| Mola | Passo |
| Brasa | Fôlego |
| Lume | Faro |

| personagem | cabeça | superior | inferior | o original (Peso, Passo, Fôlego, Faro) |
| --- | --- | --- | --- | --- |
| female-a | Coque preto (Lume: Faro +2, Peso +1) | Blusa roxa (Lume: Faro +2, Peso +1) | Short claro (Mola: Passo +2, Fôlego +1) | 3, 3, 2, 5, Relâmpago |
| female-b | Duas bolotas (Lume: Faro +2, Passo +1) | Blusa amarela (Mola: Passo +2, Peso +1) | Saia roxa (Lume: Faro +2, Peso +1) | 3, 4, 1, 5, Relâmpago |
| female-c | Touca listrada (Brasa: Fôlego +2, Peso +1) | Camisa azul (Bigorna: Peso +2, Passo +1) | Short laranja (Brasa: Fôlego +2, Faro +1) | 4, 2, 5, 2, Muralha |
| female-d | Coque ruivo (Brasa: Fôlego +2, Faro +1) | Terninho (Brasa: Fôlego +2, Passo +1) | Calça social (Mola: Passo +2, Faro +1) | 1, 4, 5, 3, Corrente |
| female-e | Franja preta (Bigorna: Peso +2, Fôlego +1) | Jaleco (Lume: Faro +2, Passo +1) | Calça branca (Bigorna: Peso +2, Passo +1) | 5, 3, 2, 3, Torre |
| female-f | Cabelo longo (Mola: Passo +2, Faro +1) | Jaqueta preta (Brasa: Fôlego +2, Peso +1) | Saia lilás (Mola: Passo +2, Peso +1) | 3, 5, 3, 2, Corrente |
| male-a | Óculos redondo (Bigorna: Peso +2, Passo +1) | Camisa verde (Lume: Faro +2, Fôlego +1) | Tênis amarelo (Bigorna: Peso +2, Faro +1) | 5, 2, 2, 4, Torre |
| male-b | Barba ruiva (Bigorna: Peso +2, Faro +1) | Camisa laranja (Brasa: Fôlego +2, Faro +1) | Short azul (Brasa: Fôlego +2, Passo +1) | 3, 2, 5, 3, Muralha |
| male-c | Quepe azul (Brasa: Fôlego +2, Passo +1) | Farda azul (Bigorna: Peso +2, Faro +1) | Calça da farda (Bigorna: Peso +2, Fôlego +1) | 5, 2, 4, 2, Muralha |
| male-d | Ruivo curto (Mola: Passo +2, Peso +1) | Terno (Mola: Passo +2, Fôlego +1) | Calça preta (Brasa: Fôlego +2, Peso +1) | 3, 5, 4, 1, Corrente |
| male-e | Óculos de obra (Lume: Faro +2, Fôlego +1) | Macacão (Bigorna: Peso +2, Fôlego +1) | Botina de obra (Lume: Faro +2, Passo +1) | 3, 2, 3, 5, Torre |
| male-f | Topete preto (Mola: Passo +2, Fôlego +1) | Regata verde (Mola: Passo +2, Faro +1) | Bermuda (Lume: Faro +2, Fôlego +1) | 1, 5, 3, 4, Relâmpago |

Os 12 personagens originais passam na regra, não perdem ponto, e cada canto do quadrado tem três deles. Quem monta o
personagem da Kenney inteiro tem um cavaleiro coerente.

Os nomes das peças (até 14 letras) são provisórios: foram lidos das miniaturas da Kenney. O diretor de arte os
confere olhando a malha.

### O que não tem stat

- **As cadeiras de rodas** (`wheelchair`, `wheelchair-deluxe`, `wheelchair-power`, `wheelchair-power-deluxe`):
  trocam as pernas pela cadeira. O stat é o da peça inferior escolhida. Em corrida, a cadeira anda na velocidade do
  Passo, como as pernas.
- **Os auxílios** (`aid-glasses`, `aid-sunglasses`, `aid_hearing`, `aid-cane`): acabamento, sem stat.
- **Os dois ficam livres desde a primeira noite.** Nenhum auxílio e nenhuma cadeira é prêmio da coleção.

## Os stats

Quatro, de 1 a 5. Cada um começa em 1, e as três peças somam 9 pontos. O total é 13, então **todo cavaleiro tem
pelo menos um stat em 4 ou mais** (13 em quatro stats de no máximo 3 dá 12). Nenhum stat passa de 5: o ponto que
passaria se perde, e o VU mostra o segmento perdido piscando uma vez em `GRAFITE`.

**Os stats mudam o corpo, nunca o ouvido.** Nenhum stat mexe na janela de julgamento
([04, as janelas](../04-ritmo-e-audio.md#as-janelas)) nem nos pontos de um acerto. Quem joga bem no tempo ganha
com qualquer cavaleiro. O minigame é afinado para o stat 3; cada ponto acima ou abaixo move o gancho um passo.

| stat | gancho | o que muda | 1 | 2 | 3 | 4 | 5 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Peso** | `empurrao` | a distância do empurrão que ele sofre: golpe, coice do próprio erro, estouro, vento de fantasma | ×1,16 | ×1,08 | ×1 | ×0,92 | ×0,84 |
| | `tranco` | a distância do empurrão que ele dá: a onda do grito, a trombada, o vento que sopra como fantasma | ×0,84 | ×0,92 | ×1 | ×1,08 | ×1,16 |
| | `ruido` | o raio em que o inimigo ouve os passos dele (terror) | ×0,8 | ×0,9 | ×1 | ×1,1 | ×1,2 |
| **Passo** | `velocidade` | andar, correr, patinar, subir, sair de baixo | ×0,94 | ×0,97 | ×1 | ×1,03 | ×1,06 |
| **Fôlego** | `levantar` | a duração da queda: caído, congelado, atordoado, arma travada | ×1,25 | ×1,125 | ×1 | ×0,875 | ×0,75 |
| **Faro** | `pista` | o aviso antes da nota (a luz, o tremor, o bipe, a textura); a nota cai no mesmo tempo | −40 ms | −20 ms | 0 | +20 ms | +40 ms |
| | `raio` | o quanto se vê e se ouve no escuro e na neblina | ×0,8 | ×0,9 | ×1 | ×1,1 | ×1,2 |

A conta de cada gancho: `neutro + por_ponto × (stat − 3)`, em [stats.csv](stats.csv). A queda do `levantar` se
arredonda à semicolcheia (pilar 3: [tudo cai na batida](../arte/README.md#os-pilares)), e nunca fica menor que uma.

**O quanto se sente**, do stat 1 ao 5:

- Peso: o leve voa 38 % mais longe que o pesado no mesmo golpe (1,16 contra 0,84).
- Passo: numa corrida de 90 s, o rápido termina 12 % à frente do lento com os mesmos acertos.
- Fôlego: numa queda de 2 tempos a 120 BPM, 2,5 tempos (1,25 s) contra 1,5 tempo (0,75 s).
- Faro: 80 ms de aviso a mais; no escuro, o raio é 1,5 vez maior (1,2 contra 0,8).

O Peso tem o seu preço dentro do próprio stat: no terror, o passo pesado se ouve 20 % mais longe.

Faro e Fôlego são **largos**: agem em 39 dos 45, o Faro com pouco efeito, o Fôlego com efeito médio. Peso é
**estreito e fundo**: age em 14, com efeito grande. Passo age em 17, quase todos de corrida, fuga e esquiva. A noite
mede se isso se equilibra.

## A regra que impede

**Bigorna e Mola não convivem. Brasa e Lume não convivem.** Uma peça cujo emblema é o oposto do emblema de outra
peça já escolhida fica travada. Só o emblema conta: a Calça branca (Bigorna, com Passo +1) não trava nada por causa
do Passo dela.

**Por quê.** O pesado não é rápido; quem aguenta o tranco não é quem fareja o caminho. A regra obriga a escolher um
lado de cada eixo, e o lado escolhido é o tipo do cavaleiro. Sem ela, a melhor build seria pegar o maior número de
cada peça, e todo mundo convergiria para o mesmo cavaleiro.

**Os números** (conferidos por [conferir.py](conferir.py)):

- dos 1728 corpos possíveis, **756 passam** na regra (44 %);
- numa linha, a regra trava **no máximo 6 das 12 peças** (quando as outras duas peças têm emblemas de eixos
  diferentes) e no mínimo 3 (quando as outras duas têm o mesmo emblema);
- dos 756, 432 não perdem ponto no teto, 216 perdem 1 e 108 perdem 2. Montar mal é possível, e se vê.

**Como a tela mostra.** Nada de frase de erro (princípio 6). Quatro sinais, que o diretor de arte posiciona na
coluna do lugar ([arte/04, uma coluna](../arte/04-o-cavaleiro.md#uma-coluna)):

1. **O emblema na linha.** Cada peça mostra o emblema do principal, 24 px, antes do nome; o secundário, um emblema
   de 16 px depois.
2. **As duas chaves do deck.** Duas chaves de três posições, como as de um tape deck: `CORPO` (Bigorna, meio, Mola) e
   `ESPÍRITO` (Brasa, meio, Lume). A alavanca vai para o lado dos emblemas que o cavaleiro tem; fica no meio quando
   nenhuma peça é daquele eixo. A chave diz, de longe, o canto do quadrado.
3. **A fita de 12 marcas.** Embaixo da linha escolhida, uma marca por peça: a atual acesa na cor do lugar, a travada
   pela regra riscada em `GRAFITE`, a ocupada por outro jogador (só a cabeça, veja abaixo) na cor dele com o P#.
   ◀▶ pula as riscadas e as ocupadas.
4. **O VU que pisca.** Enquanto a pessoa passa por uma peça, os segmentos que ela mudaria piscam na batida
   ([arte/04](../arte/04-o-cavaleiro.md#uma-coluna)).

Para pegar uma peça travada, a pessoa troca primeiro a peça que trava. A marca riscada mostra que ela existe.

## Entre jogadores

A fala dela: "com um impedindo o outro de escolher tal coisa". A regra dos opostos é a escolha que impede outra
dentro do cavaleiro. Entre os jogadores, a proposta é:

- **A cabeça é única na mesa.** A cabeça é o que se lê do sofá (o teste 3 da
  [alma](../arte/README.md#o-teste-que-decide-se-algo-entra)). Quem pegou a Barba ruiva primeiro fica com ela; nos
  outros, a marca dela aparece na cor de quem pegou, com o P#, e ◀▶ pula. Com a regra dos opostos (até 6 travadas)
  e três outros jogadores (até 3 ocupadas), **sobram sempre pelo menos 3 cabeças** livres.
- **O nome é único na mesa** ([o nome](#o-nome)).
- **O item não é único.** Dois Martelos na mesa podem. Com item único, o quarto a montar pode ficar sem item que o
  corpo alcance (dos 756 corpos, 96 alcançam um item só), e a montagem vira fila em vez de escolha. A chave
  `item_unico_na_mesa` em [regras.csv](regras.csv) liga a outra leitura para a noite testar; com ela ligada, o item
  ocupado aparece como a cabeça ocupada, e o corpo que fica sem item possível tem a linha do item riscada até a
  pessoa trocar uma peça ou sortear.

**Falta ela confirmar** se a leitura dela é esta (a cabeça entre jogadores, os opostos dentro), ou se queria o item
único.

## A arma ou o amuleto

Seis itens: três armas e três amuletos. Cada um pede um mínimo de stat. Com o stat no nível da liga, o item fica
**em liga**: **a liga tira o preço**, e a troca do item some. A tabela é [itens.csv](itens.csv); o que cada item
faz no jogo, e como se sente no controle, está no
[06b](../06b-a-construcao-do-cavaleiro.md#o-item-tem-mecânica).

| item | tipo | pede | em liga com | o canto |
| --- | --- | --- | --- | --- |
| **Martelo** | arma | Peso 4 | Peso 5 | Muralha e Torre |
| **Âncora** | arma | Peso 3 e Fôlego 3 | Peso 4 e Fôlego 4 | Muralha |
| **Escudo** | arma | Passo 3 e Faro 3 | Passo 4 e Faro 4 | Relâmpago |
| **Fole** | amuleto | Fôlego 4 | Fôlego 5 | Muralha e Corrente |
| **Lanterna** | amuleto | Faro 4 | Faro 5 | Torre e Relâmpago |
| **Diapasão** | amuleto | Passo 4 | Passo 5 | Relâmpago e Corrente |

O Diapasão pede Passo porque o passo é a cadência: quem tem o passo certo dá o tom da equipe.

**Todo corpo alcança pelo menos um item**: todo cavaleiro tem um stat em 4 ou mais, e cada stat tem um item que
pede 4. Dos 756 corpos válidos, 96 alcançam um item, 380 alcançam dois, 280 alcançam três.

| item | corpos que alcançam | corpos em liga |
| --- | --- | --- |
| Martelo, Diapasão, Fole, Lanterna | 294 cada | 207 cada |
| Âncora, Escudo | 260 cada | 98 cada |

A Âncora e o Escudo pedem dois stats e entram em liga em menos corpos. São os mais difíceis de afinar, e os que
mais pagam: a liga deles tira o preço de um item que já vale nos 45.

**Na tela.** Na linha do item, o VU do stat pedido ganha duas marcas: um traço no nível que o item pede e outro no
nível da liga. O item que o corpo não alcança fica riscado e ◀▶ pula. Quando o item entra em liga, a linha da troca
some do cartão do item com um risco de caneta.

## O arquétipo

Os dois stats mais altos dão o nome, escrito na etiqueta em Permanent Marker. No empate, vence o stat com mais peças
de emblema dele; depois, a ordem Peso, Passo, Fôlego, Faro. A tabela é [arquetipos.csv](arquetipos.csv).

| os dois mais altos | arquétipo | corpos |
| --- | --- | --- |
| Peso e Fôlego | Muralha | 176 |
| Peso e Faro | Torre | 176 |
| Passo e Fôlego | Corrente | 170 |
| Passo e Faro | Relâmpago | 170 |
| Peso e Passo | **Aríete** (raro) | 38 |
| Fôlego e Faro | **Eco** (raro) | 26 |

Os quatro cantos saem dos emblemas. O Aríete e o Eco são os dois opostos que a regra proíbe nos emblemas; eles só
saem pelos secundários (+1). São achados: o pré-montado nunca os sorteia, e quem chega num deles vê o nome raro na
etiqueta.

## A build boa

Uma build é **boa** quando três coisas valem ao mesmo tempo:

1. **Nenhum ponto perdido** no teto de 5.
2. **O item no seu canto:** o stat (ou os dois) que o item pede está entre os dois mais altos do cavaleiro.
3. **O item em liga.**

Dos 756 corpos válidos, **432 têm uma build boa possível**, e são exatamente os que não perdem ponto. Ou seja: quem
não desperdiça ponto sempre tem um item que fecha a build. O trabalho de quem monta é não estourar o teto e achar o
item certo.

**Na tela.** Quando a build fica boa, o arquétipo na etiqueta ganha dois sublinhados de caneta (`fx_caneta`) e o
acorde do lugar toca uma vez no alto-falante do controle dele. Quando deixa de ser, os sublinhados somem sem som.
A build boa se ouve.

## O pré-montado

Todo lugar nasce montado, com um cavaleiro **bom, mas não fechado**: a pessoa fecha a build com uma troca. É o
primeiro "eu que fiz".

O sorteio usa um `RandomNumberGenerator` com `seed = Forja.semente * 31 + lugar` (o mesmo de hoje, para o robô
repetir). Ele escolhe, de uma vez, entre os candidatos que cumprem tudo:

1. o corpo passa na regra dos opostos e **não perde ponto**;
2. o arquétipo é um dos quatro cantos (nunca raro) e **nenhum outro lugar presente tem o mesmo**;
3. a cabeça não está com ninguém;
4. o item está no seu canto, **fora da liga**, e **uma troca de peça põe ele em liga**;
5. o nome é um dos seis do arquétipo ([nomes.csv](nomes.csv)) que ninguém usa; sem nenhum livre, qualquer um livre.

São **270 corpos sorteáveis** (Muralha 81, Torre 63, Corrente 63, Relâmpago 63), cada um com exatamente um item que
cumpre o passo 4. Com quatro presentes, o quarto lugar tem pelo menos 31 candidatos (o pior de 2000 mesas simuladas). A mesa nasce com os quatro cantos: quatro silhuetas e quatro jeitos de jogar
no primeiro segundo.

Um cavaleiro ruim, nesta regra, é um que perde ponto, que leva um item fora do seu canto, ou que repete o tipo de
outro. O sorteio não deixa sair nenhum deles.

Botão △ (Sortear) refaz o sorteio de tudo o que não está travado (□), com os mesmos critérios.

## O nome

- **O teclado** é o da G09 ([a ficha](../tarefas/G09-o-teclado-do-nome.md#o-alvo)): a grade 7 × 5, ✕ põe a letra,
  ○ apaga, △ sorteia, R1 vai para "Pronto".
- **O tamanho:** de 2 a 12 letras. Doze cabem na coluna de 432 px nas três fontes em que o nome aparece (a placa, a
  etiqueta, o pódio).
- **O filtro:** só o alfabeto da grade (A a Z, Ç, á é í ó ú, ã õ, â ê ô e o espaço entre palavras). **Nenhuma lista
  de palavras proibidas**: é um jogo entre amigos no sofá, e toda lista em português veta nome inocente. O nome não
  passa pela tabela de traduções.
- **A maiúscula:** a primeira letra de cada palavra sai maiúscula, as outras minúsculas ("Dona Brasa", não "Dona
  brasa"). A G09 hoje só põe a maiúscula na primeira letra do nome: muda.
- **Único na mesa.** O "Pronto" fica apagado e o nome pisca, sem frase de erro (G09).
- **O sorteado** vem do arquétipo: a Muralha sorteia entre Basalto, Granito, Bronze, Tenaz, Rebite e Ferrugem. Os 24
  são os de `NOMES` da G02, divididos em quatro grupos de seis ([nomes.csv](nomes.csv)). Trocar de arquétipo depois
  não troca o nome: o nome já é da pessoa.
- **Onde aparece:** na placa do lugar, na etiqueta, no HUD e no pódio (as fontes de cada um estão em
  [arte/04, o nome](../arte/04-o-cavaleiro.md#o-nome)).

## A progressão e a coleção

**Nada que muda stat se ganha jogando.** As 36 peças e os 6 itens estão livres desde o primeiro minuto da primeira
noite. Quem chega no meio da noite, ou pela primeira vez, monta qualquer cavaleiro. O que cresce é a história.

| o que cresce | como | onde se vê |
| --- | --- | --- |
| **os riscos** | +1 por minigame vencido com aquele cavaleiro (o vencedor, ou o destaque no coop) | na etiqueta, em Permanent Marker, em grupos de cinco (quatro riscos e um atravessado) |
| **a gaveta** | o cavaleiro se guarda ao forjar, pela chave do nome; o mesmo nome com peças novas atualiza e mantém os riscos | Botão L1 (Gaveta) na montagem: a lista, com o nome, o arquétipo, as noites e os riscos |
| **os acabamentos** | Dourado, Cromado e Néon, pela coleção da noite ([G06](../tarefas/G06-o-salao-e-a-colecao.md#o-alvo)); o cavaleiro guarda o que ganhou | no corpo; nenhum muda stat |
| **os troféus** | os da G06, na vitrine do salão | no salão |

- **A gaveta** guarda até 12 cavaleiros por máquina. Cheia, sai o que está há mais tempo sem jogar. O robô não lê
  nem grava a gaveta.
- **Carregar da gaveta** traz as peças, o item, o nome e o acabamento, e passa pelas regras da mesa: cabeça ocupada
  troca pela cabeça livre mais próxima com o mesmo emblema; nome ocupado não carrega (o nome pisca).
- **O pré-montado continua sendo o começo.** A gaveta é escolha da pessoa, nunca o padrão: "sempre começa com um
  pré-montado aleatório".
- Se uma noite futura mudar os CSV e o cavaleiro guardado deixar de passar na regra, ele carrega com a peça que trava
  trocada pela vizinha válida, e a linha pisca uma vez.

## Os stats em cada gênero

Os gêneros são os do [03](../03-os-45-minigames.md). Os 45, um por um, estão em [minigames.csv](minigames.csv): o
que cada stat muda naquele minigame, os ganchos que ele chama e a queda proposta em tempos.

| gênero | Peso | Passo | Fôlego | Faro |
| --- | --- | --- | --- | --- |
| **todos contra todos** (12) | só no Grito de Guerra: a onda empurra mais e é empurrado menos | só no Grito de Guerra: a volta ao centro | em todos: o tempo fora depois da falha (balançando, congelado, queimado), de 1 a 3 tempos | em 9: o aviso antes da nota; não age n'O Canto nem no Código do Dragão (são de memória) nem no Grito de Guerra |
| **dupla** (7) | a trombada no Roubo de Bateria, o soco do Mecha, o escorregão nas Engrenagens | correr com a bateria, o salto, o passo do mecha | em todos: a peça, o fole ou a corda que volta | em todos: o tempo e o contratempo da dupla avisam antes |
| **coop** (9) | o tranco do vagão (Fuga do Titã), o chão que empurra (Hackeando) | voltar ao lugar, chegar à caldeira | o engasgo, a arma travada, a nota que falta: quem cai menos segura o acorde do grupo | em todos: a sua vez avisa antes |
| **corrida** (6) | só o tropeço na Marcha dos Escudeiros | **o principal**: a velocidade, de ×0,94 a ×1,06 | o tempo caído (o lamaçal, o plasma, o andar que despenca) | o aviso do obstáculo; o raio no Eco do Abismo |
| **sobrevivência** (6) | **o principal**: não ser jogado da viga, do pêndulo, do golpe do Cerco | a esquiva (Prensa, Mecha Cego, Zero Absoluto) | levantar do cambaleio e do tombo | o aviso do golpe e do balanço |
| **terror** (5) | **o preço**: o passo pesado se ouve mais longe (Neblina, Mecha Cego, Zero Absoluto) | fugir e alcançar | voltar do escuro e do gelo | **o principal**: o raio no escuro, de ×0,8 a ×1,2, e o aviso |
| **sabotagem** (4) | o estouro do Curto-Circuito arremessa menos | não age: a sabotagem é parada | o tempo fora depois do estouro ou do borrão | o aviso do lingote, da síncope, do bipe certo |

Os números entre parênteses contam os minigames do gênero; os que têm dois gêneros (a Prensa é sobrevivência e
terror) contam nos dois. Nos dois medleys (Ruge o Reator e O Último Acorde), cada trecho usa os ganchos do minigame
de origem. No modo Relâmpago (os microjogos de 5 a 8 s), **nenhum stat e nenhum item age**: o microjogo é curto
demais para o corpo pesar.

### Os itens em cada gênero

Os itens valem nos 45 ([06b](../06b-a-construcao-do-cavaleiro.md#o-item-tem-mecânica)). Onde eles mudam:

| item | onde muda |
| --- | --- |
| Martelo | todo minigame em que o acerto vale ponto ou impulso: o perfeito no tempo forte dobra |
| Âncora | todo empurrão (soma com o Peso: Peso 5 com Âncora sofre 0,84 × 0,5 = 42 % do empurrão); na corrida, −10 % de velocidade fora da liga |
| Escudo | todo minigame: o primeiro erro não conta |
| Fole | todo minigame com combo |
| Lanterna | todo minigame com aviso (soma com o Faro: Faro 5 com Lanterna recebe o aviso meio tempo e mais 40 ms antes) |
| Diapasão | dupla e coop: o perfeito puxa o combo da equipe; no todos contra todos, só em liga, e só o volume da nota |

## O que a noite de seis horas mede

O registro grava um evento ao forjar e o junta ao resultado de cada minigame pelo lugar:

```
Forja.evento("cavaleiro", lugar, {"cabeca", "superior", "inferior", "item", "nome",
    "stats": [peso, passo, folego, faro], "arquetipo", "liga", "boa", "perdidos"})
```

| o que se mede | o alvo | se passar do alvo |
| --- | --- | --- |
| vitórias por arquétipo, em cada gênero com 20 minigames ou mais na noite | nenhum acima de 35 % (com quatro jogadores, o justo é 25 %) | o gancho principal daquele arquétipo naquele gênero cai à metade (`por_ponto` ÷ 2) |
| vitórias por item | nenhum acima de 35 % dos lugares que o levaram | a troca do item dobra |
| cavaleiros forjados em build boa até a terceira partida | pelo menos 50 % | a tela não ensina: vira ficha para o diretor de arte (as marcas do VU, as chaves) |
| tempo da primeira montagem, do primeiro ✕ à forja | no máximo 90 s | o pré-montado passa a vir em liga |
| quem forja sem trocar nada | no máximo 50 % na segunda noite | a montagem não convida: vira ficha |

O valor que a noite confirma passa de `proposta` a `medido` no CSV, com a data no commit.

## Os arquivos

| arquivo | o que guarda |
| --- | --- |
| [pecas.csv](pecas.csv) | as 36 peças: a parte, o personagem, o nome, os pontos e o emblema |
| [stats.csv](stats.csv) | os 4 stats e os 7 ganchos: a conta, o valor de 1 a 5, o eixo e o oposto |
| [itens.csv](itens.csv) | os 6 itens: o que pedem, a liga, o efeito, a troca e o que a liga tira |
| [arquetipos.csv](arquetipos.csv) | os 6 arquétipos e os dois stats de cada um |
| [nomes.csv](nomes.csv) | os 24 nomes sorteáveis, seis por canto |
| [regras.csv](regras.csv) | as constantes: a base, o teto, os opostos, o que é único na mesa, o tamanho do nome, a gaveta |
| [minigames.csv](minigames.csv) | os 45: o que cada stat muda, os ganchos e a queda proposta |
| [conferir.py](conferir.py) | confere as tabelas, imprime as contas deste texto e monta um cavaleiro pela linha de comando |

O jogo lê os CSV com `FileAccess.get_csv_line()`. Os decimais usam ponto. As colunas `valor_1` a `valor_5` do
stats.csv são para quem lê; o jogo usa `neutro` e `por_ponto`, e o `conferir.py` garante que os dois batem.

```
python3 docs/jogo/sistemas/conferir.py          # confere tudo e imprime as contas; sai com 1 se algo falhar
python3 docs/jogo/sistemas/conferir.py female-b female-e female-d escudo
```

## O que vira ficha

Aplicar no jogo é trabalho de ficha, não desta pasta. O que este RPG pede:

| ficha | o que muda |
| --- | --- |
| a montagem (a G13 que o [arte/04](../arte/04-o-cavaleiro.md) cita) | as cinco linhas, a regra dos opostos, a cabeça única, as chaves, a fita de 12 marcas, as marcas do item no VU, a build boa, o pré-montado deste texto; uma classe `Cavaleiro` estática que lê os CSV |
| [G02](../tarefas/G02-a-construcao-do-cavaleiro.md) | os passos BONECO, ACABAMENTO, PECA e ITEM viram Cabeça, Superior, Inferior e Arma ou amuleto; `NOMES` passa a vir de nomes.csv |
| [G03](../tarefas/G03-o-item-com-mecanica.md) | o que cada item pede, a liga (a troca some) e o Diapasão em liga no todos contra todos |
| [G09](../tarefas/G09-o-teclado-do-nome.md) | a maiúscula em cada palavra; o △ sorteia do arquétipo |
| [G06](../tarefas/G06-o-salao-e-a-colecao.md) | os riscos, a gaveta entre noites, o acabamento que fica com o cavaleiro; auxílios e cadeiras nunca são desbloqueio |
| [H04](../tarefas/H04-o-kit-do-minigame.md) | os sete ganchos no kit (`Cavaleiro.gancho(lugar, "levantar")`), que todo minigame chama, e a coluna `ganchos` do minigames.csv como lista do que cada um usa |

## Em aberto

- **Para a Vitória:** a leitura de "um impedindo o outro" ([entre jogadores](#entre-jogadores)): a cabeça única na
  mesa e os opostos dentro do cavaleiro, ou o item único na mesa.
- **Para o diretor de arte:** conferir os 36 nomes de peça olhando a malha; pôr na coluna do lugar as duas chaves do
  deck, a fita de 12 marcas, o emblema na linha e as duas marcas do item no VU; o Botão L1 (Gaveta) na tabela de
  botões; os quatro emblemas (Bigorna, Mola, Brasa, Lume) como glifos de 24 e 16 px.
- **Para o diretor de som:** o id do som da build boa (o acorde do lugar no alto-falante, uma vez) e o do ponto
  perdido.
- **Para o diretor de jogo:** a queda de cada minigame em tempos (a coluna `queda_tempos` do minigames.csv é
  proposta), e conferir que nenhum gancho tira a graça de um minigame. A regra que fica: a diferença entre um bom e
  um perfeito pesa mais que a diferença entre o stat 1 e o 5.
