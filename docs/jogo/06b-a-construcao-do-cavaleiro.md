# 06b — A construção do cavaleiro

A tela de criação do jogador. Ela substitui o lobby de hoje (◀▶ boneco, ▲▼ item) e faz três trabalhos de uma vez:
cada pessoa monta um cavaleiro que é só dela, o controle se calibra sem ninguém perceber, e o cavaleiro leva um item
que muda o jeito de jogar.

O sistema (as peças, os stats, as regras, os números) está em [sistemas/](sistemas/README.md). A arte (o corte das
malhas, a coluna, a forja, a luz) está em [arte/04](arte/04-o-cavaleiro.md). Esta página conta a tela como quem joga
a vive.

## O que a pessoa sente

1. **Já tem um cavaleiro quando chega.** O lugar nasce com um pré-montado sorteado, bom e de um tipo que ninguém na
   mesa tem. Com ✕ ✕ já se joga.
2. **Cada troca muda alguma coisa que se vê.** A peça troca no boneco, o VU do stat sobe ou desce, a chave do deck
   pode virar, o arquétipo na etiqueta pode mudar.
3. **Uma escolha impede outra.** Bigorna não anda com Mola, Brasa não anda com Lume. A cabeça que outro pegou não está
   na lista. Não dá para ter tudo.
4. **Uma troca fecha a build.** O pré-montado está a uma troca da liga. Quando a build fica boa, o arquétipo ganha dois
   sublinhados de caneta e o acorde do lugar toca no controle.
5. **O nome é dela.** Escrito na caneta, na etiqueta, e mostrado no pódio.

## A tela

Os quatro lugares lado a lado, cada um com a sua coluna e a sua bigorna na cor do lugar. Cada coluna tem cinco linhas
e os quatro VUs dos stats:

| linha | o que se escolhe | como |
| --- | --- | --- |
| **Cabeça** | uma das 12 cabeças | ◀▶; a cabeça de outro jogador e a travada pela regra ficam riscadas na fita de 12 marcas e ◀▶ pula |
| **Superior** | um dos 12 troncos superiores | ◀▶, com a mesma fita |
| **Inferior** | uma das 12 pernas; R1 troca as pernas por uma das quatro cadeiras | ◀▶; a cadeira não muda stat |
| **Arma ou amuleto** | um dos 6 itens que o corpo alcança | ◀▶; o VU do stat pedido mostra o traço do mínimo e o da liga; o controle deixa sentir o item na hora (o peso no gatilho, o pulso na mão) |
| **Nome** | o sorteado do arquétipo, ou o teclado de tela | ◀▶ entre os nomes livres; ✕ abre o teclado ([G09](tarefas/G09-o-teclado-do-nome.md)) |

▲▼ escolhe a linha. Botão △ (Sortear) sorteia tudo o que não está travado. □ trava a linha para o sorteio. Botão L1
(Gaveta) abre os cavaleiros guardados. ✕ forja. A tabela inteira dos botões está em
[arte/04, os botões](arte/04-o-cavaleiro.md#os-botões).

Acima dos VUs, as **duas chaves do deck**: `CORPO` (Bigorna ou Mola) e `ESPÍRITO` (Brasa ou Lume). Elas viram sozinhas
com as peças e dizem, de longe, de que tipo é o cavaleiro.

**A forja.** O ✕ começa as oito marteladas no tempo da bigorna. Na tela, cada golpe acende uma parte: a cabeça, o
superior, o inferior, o item e, no oitavo, o nome escrito na caneta. Por baixo, as oito marteladas são a calibração
([04](04-ritmo-e-audio.md#a-calibração-que-ninguém-vê)): a mediana do atraso vira o desvio do controle. Para o
jogador, é só a armadura ficando pronta, parte por parte, a cada golpe no tempo.

Quando os presentes estão prontos, a contagem de sempre leva ao salão. Quem volta na mesma noite pula a construção:
o cavaleiro fica guardado, com o controle dele.

## O cavaleiro

Cada peça dá +2 num stat (o emblema) e +1 noutro. Os quatro stats vão de 1 a 5:

| stat | emblema | o que muda no jogo |
| --- | --- | --- |
| **Peso** | Bigorna | o quanto o cavaleiro é empurrado, e o quanto ele empurra |
| **Passo** | Mola | a velocidade de andar, correr e fugir |
| **Fôlego** | Brasa | o tempo para levantar depois de cair |
| **Faro** | Lume | o aviso antes da nota, e o quanto se vê no escuro |

Os stats mudam o corpo, nunca o ouvido: a janela de julgamento e os pontos de um acerto são iguais para todos. A
conta de cada um, de 1 a 5, está em [sistemas, os stats](sistemas/README.md#os-stats); o que cada stat muda em cada
um dos 45 está em [sistemas/minigames.csv](sistemas/minigames.csv).

Os dois stats mais altos dão o arquétipo: **Muralha**, **Torre**, **Corrente** ou **Relâmpago**, e os raros
**Aríete** e **Eco** ([o arquétipo](sistemas/README.md#o-arquétipo)).

## O item tem mecânica

Cada item é um poder passivo pequeno, que vale nos 45 minigames, se vê na tela e se sente no controle. Nenhum item
ganha sozinho; cada um muda o jeito de jogar. Cada um pede um mínimo de stat, e com o stat no nível da liga **a troca
some**. Os números estão em [sistemas/itens.csv](sistemas/itens.csv).

| item | pede | o que faz | como se sente | a troca | em liga |
| --- | --- | --- | --- | --- | --- |
| **Martelo** | Peso 4 | o acerto perfeito no tempo forte (o 1 do compasso) vale em dobro | o golpe perfeito no 1 vibra mais pesado | o acerto fora do tempo forte vale 85 % | Peso 5: o acerto fora do tempo forte vale 100 % |
| **Âncora** | Peso 3 e Fôlego 3 | sofre metade do empurrão, da sabotagem e do coice do próprio erro | o gatilho pesa um pouco sempre | anda 10 % mais devagar nas corridas | Peso 4 e Fôlego 4: anda na velocidade normal |
| **Escudo** | Passo 3 e Faro 3 | absorve o primeiro erro de cada minigame | o gatilho fica firme enquanto o escudo está inteiro; afrouxa quando ele quebra | começa cada minigame com o combo em zero | Passo 4 e Faro 4: começa com o bônus de entrada |
| **Fole** | Fôlego 4 | depois de um erro, o combo volta na metade dos acertos | um sopro curto no alto-falante quando o combo volta | o combo máximo é 3/4 do normal | Fôlego 5: o combo máximo é o normal |
| **Lanterna** | Faro 4 | a pista (a vibração, a textura, o bipe) chega meio tempo antes | a pista antecipada é mais fraca | a janela perfeito encolhe 10 ms | Faro 5: a janela não encolhe |
| **Diapasão** | Passo 4 | a nota soa 1,3 vez mais alta, e o perfeito puxa o combo da equipe nos minigames de dupla e coop | a nota tem um brilho a mais | no todos contra todos, não dá bônus nenhum | Passo 5: no todos contra todos, a nota soa mais alta |

O item aparece no cartão do HUD, com a carga quando tem (o Escudo inteiro ou quebrado), e com a troca riscada quando
está em liga. O registro anota o cavaleiro inteiro de cada lugar, para a noite de seis horas medir se algum arquétipo
ou item vence demais ([o que a noite mede](sistemas/README.md#o-que-a-noite-de-seis-horas-mede)).

## Poucos assets, muita identidade

A identidade vem de cinco camadas, todas com o que o jogo já tem:

1. **a silhueta**: a cabeça, única na mesa, e as duas peças do corpo (12³ combinações, 756 que passam na regra);
2. **a cor**: a do lugar, no contorno, no aro e na barra de luz;
3. **o item**: na mão, no braço ou no peito, e no cartão;
4. **o som**: o pio da cabeça no alto-falante, que diz "sou eu" sem olhar;
5. **o nome**: escolhido, escrito na caneta.

## A coleção

Nada que muda stat se ganha jogando: as 36 peças e os 6 itens estão livres desde a primeira noite, e as cadeiras e
os auxílios também. O que cresce é a história de cada cavaleiro e da mesa:

- **os riscos**: cada minigame vencido com o cavaleiro põe um risco de caneta na etiqueta dele, em grupos de cinco;
- **a gaveta**: o cavaleiro se guarda ao forjar, pelo nome, e volta em outra noite pelo Botão L1 (Gaveta), com os
  riscos; o começo continua sendo o pré-montado;
- **os acabamentos**: dourado, cromado e néon, ganhos na noite ([G06](tarefas/G06-o-salao-e-a-colecao.md)); o
  cavaleiro guarda o que ganhou;
- **os troféus**: na vitrine do salão.

Não há loja nem moeda. A coleção cresce jogando: vencer um minigame pela primeira vez, fechar um coop sem erro, bater
um recorde. O salão cheio e a etiqueta riscada são a história da noite. As regras da progressão estão em
[sistemas, a progressão](sistemas/README.md#a-progressão-e-a-coleção).

## O que mudou desta página

A versão anterior tinha seis passos (boneco inteiro, acabamento, uma peça de identidade, item, nome, forjar) e itens
sem requisito. Agora:

- o boneco inteiro virou três peças (cabeça, superior, inferior), com stats;
- a peça de identidade (elmo, capa, ombreira) saiu: a cabeça é a identidade, e é única na mesa;
- o acabamento saiu da montagem e foi para a coleção;
- cada item pede um mínimo de stat e tem a liga;
- o pré-montado é sorteado bom e a uma troca da liga, e o nome sorteado vem do arquétipo.

As fichas que mudam com isso estão em [sistemas, o que vira ficha](sistemas/README.md#o-que-vira-ficha).
