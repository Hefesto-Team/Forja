# A diversão da Forja

Esta pasta é do diretor de jogo. Ela decide o que faz um minigame ser bom, e
diz, para cada um dos 45 e para o Relâmpago, o momento em que o sofá grita.
Quem escreve, enriquece, implementa ou joga um minigame lê aqui antes.

Quando a diversão e outra regra brigam, vale esta pasta
([papéis](../o-time/papeis.md#o-diretor-de-jogo)). A estética se decide junto
com o diretor de arte: onde esta pasta pede algo da arte, o pedido está em
[O que preciso de outras cabeças](#o-que-preciso-de-outras-cabeças).

| arquivo | o que tem |
| --- | --- |
| este | a mesa de teste, a régua da diversão, as regras de estética de jogo, a curva padrão, as notas de hoje e as trocas propostas |
| [I — A Centelha](I-a-centelha.md) · [J — A Viga](J-a-viga.md) · [K — O Molde](K-o-molde.md) | lado A, o corpo: a mão, o equilíbrio, o toque |
| [L — O Impacto](L-o-impacto.md) · [M — A Galeria](M-a-galeria.md) | lado A: o golpe e a mira |
| [N — O Canto](N-o-canto.md) · [O — Os Caminhos](O-os-caminhos.md) · [P — A Voz](P-a-voz.md) | lado B, o espírito: o ouvido, o chão, a voz |
| [Q — A Prova](Q-a-prova.md) · [R — O Relâmpago](R-o-relampago.md) | o fim da noite e o modo à parte |
| [momentos.csv](momentos.csv) | os 46 momentos de grito como dado: o id, a janela em segundos, a mesa, o mínimo, o rastro na prancha; um script do portão lê este arquivo |

## A mesa de teste

Todo teste desta pasta roda numa destas mesas, pela prova visual
([F09](../tarefas/F09-a-prova-visual.md)), semente 7, sem a bancada.

| mesa | os quatro lugares | para quê |
| --- | --- | --- |
| **a mesa padrão** | P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim` | todos contra todos, corrida, sobrevivência, sabotagem |
| **a mesa das duplas** | P1 `bom` e P2 `ruim` (a Brasa) contra P3 `medio` e P4 `medio` (a Maré) | 2v2: as duas duplas acertam perto de 63 % e 66 %, então a disputa fica aberta |
| **a mesa boa** | os quatro `bom` | coop: o caminho da vitória tem de existir |
| **a mesa fraca** | os quatro `medio` | coop: a quase derrota tem de acontecer |

O robô por lugar (`--robo=bom,medio,medio,ruim`) ainda não existe: hoje o
temperamento é um só para a mesa. É pedido ao arquiteto.

**A linha `momento`.** Todo momento de grito escreve uma linha no registro:
`{"tipo": "momento", "slot": "S01_J01", "nome": "racha_no_quinto", "lugar": 2, "t_musica": 41.2}`
(`lugar` −1 quando é de todos). O teste pelo robô conta essas linhas. É
pedido ao arquiteto (o tipo, no [13](../13-arquitetura.md)) e ao roteirista
(a chamada em cada ficha). Até a linha existir, o jogador do time confere o
momento só pela prancha.

**A prancha.** Um quadro de 480 × 270 a cada 2 s de jogo, em grade de 6
colunas, com a hora embaixo ([F09](../tarefas/F09-a-prova-visual.md#o-alvo)).
"O quadro de 40 s" é o 21.º da partida daquele minigame. Um momento que dura
menos de 2 s pode cair entre dois quadros; por isso todo momento de grito
deixa um **rastro** que fica 2 s ou mais (régua, item 6), e é o rastro que a
prancha mostra.

## A régua da diversão

Dez itens. Um minigame passa quando os dez passam. Cada item tem o teste
pela partida do robô e o teste pela prancha.

### 1. A graça aparece em 10 s

Do apito de início até 10 s de música, cada lugar já fez pelo menos uma nota
que conta, e a sala já viu uma falha física ou o objeto central reagindo.

- **Robô (mesa padrão):** cada lugar presente tem uma linha `toque` com
  `t_musica` até 10,0; a mesa inteira tem pelo menos uma linha `toque` com
  `erro` até 10,0.
- **Prancha:** os quadros de 2 a 10 s mostram o objeto do verbo (a bigorna,
  a bomba, o pêndulo) com a cor de pelo menos dois donos.

### 2. Uma ideia só

Um verbo, um objeto, uma regra que cabe numa frase de até 25 palavras.

- **Script:** a FICHA tem no máximo 3 `entradas` (a única exceção é a
  primeira volta da bancada na I1, que se encerra na volta 2); o `verbo` tem
  de 1 a 3 palavras; a linha "como se joga" do [03](../03-os-45-minigames.md)
  tem até 25 palavras.
- **Prancha:** em todos os quadros de jogo há um só tipo de alvo por raia.

### 3. Ensina sem falar

Durante o jogo não há frase na tela. O que ensina é o objeto: ele anuncia o
tempo antes de pedir (a runa que acende, a prensa que range, a toupeira que
sobe), e a contagem de 4 batidas mostra o cavaleiro fazendo o gesto no ar.

- **Robô:** a coleta de texto da [F02](../tarefas/F02-sem-metalinguagem.md)
  na fase de jogo só acha o verbo, os nomes, os P#, os números do placar e o
  julgamento ("Ressonância!", "Afinado", "Quase", as palavras do
  [doc 07](../07-narrativa-e-voz.md#o-vocabulário-do-visor)).
- **Prancha:** nenhum quadro de jogo tem uma frase. O quadro de conceito
  [01](../../imagens/direcao/01_centelha_depois.jpg) não tem mais a linha "Aperte
  o botão da runa antes do anel fechar." no pé da tela (saiu em 08/10).

### 4. Um momento de grito, com nome

Cada minigame tem um evento que faz o sofá gritar, escrito no arquivo da
seção, com nome, janela em segundos e rastro.

- **Robô:** a linha `momento` com aquele `nome` aparece, na mesa dita pelo
  [momentos.csv](momentos.csv), pelo menos o mínimo de vezes, dentro da
  janela.
- **Prancha:** um quadro dentro da janela mostra o rastro do momento.

### 5. A curva sobe até o fim

O primeiro terço ensina, o segundo é o pico, o terceiro é a reta (veja
[A curva padrão](#a-curva-padrão-dos-três-terços)). O terceiro terço nunca é
cópia do primeiro.

- **Robô:** pelas linhas `nota` de cada lugar, notas por segundo no 2.º terço
  ≥ 1,5 × as do 1.º, e no 3.º terço ≥ 1,0 × as do 1.º; nas últimas 16 batidas
  há a linha `momento` `reta` (de todos).
- **Prancha:** o quadro do meio do 2.º terço tem a luz da seção 20 % acima
  do quadro do meio do 1.º ([01 O cinema, o pico](../arte/01-cinema.md#o-pico)),
  e os quadros das últimas 16 batidas mostram o sinal da reta (o carretel).

### 6. A falha é engraçada e fica à vista

O erro muda a silhueta do cavaleiro (escala de 30 % ou mais, ou deslocamento
de 0,5 m ou mais) por pelo menos 1 batida, e deixa um rastro que dura 2 s ou
mais: a lasca no chão, a casca de gelo, a lama, a fuligem, o fantasma, o
confete. `emote-no` sozinho não é falha: é a reação a ela.

- **Robô (mesa padrão):** o P4 (`ruim`) tem pelo menos 10 linhas `toque`
  com `erro` em 90 s.
- **Prancha:** pelo menos 1 quadro em cada 5 mostra um rastro de falha no P4.

### 7. Quem perde segue jogando

Ninguém fica mais de 8 batidas sem nada para fazer, nem o último, nem o
fantasma. Quem está atrás tem uma ação que muda o jogo de alguém (o vento,
a luz, o roubo, o bipe falso), ou a distância dele para o primeiro se
recupera em 30 s de jogo bom.

- **Robô (mesa padrão):** para cada lugar, a maior distância entre duas
  linhas `nota` seguidas é de até 8 batidas (o fantasma conta pelas linhas
  `momento` dele); o P4 tem pelo menos uma linha `toque` BOM ou melhor em
  cada terço.
- **Prancha:** o P4 aparece no quadro em 100 % dos quadros de jogo (ninguém
  sai do enquadramento).

### 8. A câmera mostra a graça

O momento de grito acontece dentro dos 60 % do meio da largura do quadro,
com o objeto dele ocupando pelo menos 8 % da altura da tela. Nenhuma placa do
HUD cobre o centro.

- **Robô:** a prova visual grava a posição na tela do objeto do momento
  junto com a linha `momento` (`x_tela`, `altura_tela`, de 0 a 1); o teste
  confere 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,08.
- **Prancha:** no quadro do rastro, o rastro se vê no tamanho 480 × 270 sem
  ampliar.

### 9. O impacto é exagerado e cai na batida

O acerto grande e a falha grande têm imagem, som na TV, som no controle do
dono e vibração no mesmo quadro de 16,7 ms (o [pilar 5](../arte/README.md#os-pilares)).
O tamanho da reação cresce com o tamanho do evento (a tabela de
[O exagero do impacto](#o-exagero-do-impacto)).

- **Robô:** para cada linha `momento`, há uma linha `sensacao` do mesmo
  lugar a até 16,7 ms, e o instante dela cai a até 1 quadro de uma batida ou
  colcheia da faixa.
- **Prancha:** o quadro seguinte ao momento ainda mostra a consequência (o
  tremor acabou, o rastro não).

### 10. Quem está na frente se vê no mundo

O placar mora no cenário: a estante de espadas, a pilha de lingotes, a
altura do balão, a distância na pista, as brasas da lanterna. Olhando a
cena por 1 s, qualquer um diz quem está na frente sem ler número.

- **Robô:** no fim, a ordem do `vencedor()` bate com a ordem do objeto do
  mundo (o minigame grava o objeto no `momento` `reta`).
- **Prancha:** no quadro de 60 s, quem olha diz a ordem dos quatro pelo
  objeto, e ela bate com os pontos do registro naquele instante. O jogador do
  time anota a resposta na ficha.

## As regras de estética que são de jogo

A bíblia de arte decide a cor, a lente e o som. Estas regras decidem como a
imagem serve à brincadeira.

### O tempo de leitura

| o quê | quanto | por quê |
| --- | --- | --- |
| aviso antes de toda nota | pelo menos 1 batida e pelo menos 0,45 s (a 135 bpm, 1 batida = 0,44 s: o aviso passa a 2 batidas) | o olho do sofá, a 3 m de uma TV de 50", leva 250 a 400 ms para achar o próprio objeto |
| objeto novo (que o jogador ainda não viu nesta partida) | aparece parado 2 batidas antes de pedir alguma coisa | ver antes de usar |
| o verbo na tela | some na batida 4, antes da primeira nota | durante o jogo, ninguém lê |
| regra nova nas últimas 16 batidas | nenhuma; a reta só aumenta o que já se viu | a surpresa do fim é tamanho, não regra |
| julgamento escrito ("Ressonância!") | 1 batida na tela, Bungee, na cor do dono, acima da cabeça dele | o nome do acerto é o único texto do jogo |
| leitura de quem venceu o lance | 1 s, sem número | a régua, item 10 |

### A câmera que mostra a graça

O cinema já manda: a câmera não corta durante o jogo
([01](../arte/01-cinema.md#as-regras-da-câmera)). Por cima disso:

1. **Ninguém sai do quadro.** Na corrida, quem sai do quadro é o primeiro,
   nunca o último. A câmera enquadra do segundo colocado ao último e deixa o
   líder escapar pela borda de cima. Ver o líder sumir é tensão para os
   outros; perder o próprio cavaleiro é frustração.
2. **O grito acontece no meio.** O objeto do momento nasce dentro dos 60 % do
   meio do quadro. Se o objeto é de um lugar de canto (P1 ou P4), ele se
   mostra puxado para o centro: a bomba que voa sobe até o meio da tela antes
   de cair.
3. **O pico abre o quadro, não fecha.** No pico, a câmera de arena recua 10 %
   (o enquadramento de grupo da [G05](../tarefas/G05-a-camera-dos-quatro.md)
   com folga de 1,1) para caber o caos. Push-in só no fim, no resultado.
4. **A luz aponta o dono do grito.** No quadro do momento de um só (o
   estouro, o esmagado, o congelado), a luz das outras raias cai 30 % por
   1 batida e volta em 1 batida. A câmera não se mexe; a luz é que olha.
   Pedido ao diretor de arte.

### O exagero do impacto

O tamanho da reação segue o tamanho do evento. Quatro degraus; cada evento
de cada ficha cai num deles.

| degrau | exemplo | imagem | tremor | parada (hit-stop) | duração da consequência |
| --- | --- | --- | --- | --- | --- |
| **toque** | o acerto comum | faísca de 8 a 12 partículas, o julgamento escrito | nenhum | nenhuma | 1 batida |
| **golpe** | o perfeito, a falha comum | escala do objeto a 130 % e volta em 1/2 batida; a falha muda a silhueta do cavaleiro em 30 % | 1 batida, amplitude 0,02 | 2 quadros (33 ms) só no cavaleiro | 1 a 2 batidas |
| **estrondo** | o estouro, o esmagado, a queda na lava | o cavaleiro voa 2,5 m ou fica achatado a 30 %; 40 a 60 partículas | 2 batidas, 0,05 | 3 quadros (50 ms) no cavaleiro | 4 batidas, com rastro de 2 s ou mais |
| **catástrofe** | o castelo cai, o titã alcança, a plataforma cede, o dragão cai | o objeto maior que o cavaleiro em 1,5 vez ou mais; a luz da seção sobe 40 % por 1 batida | 4 batidas, 0,08 | nenhuma (a música não para) | 1 compasso, e o rastro fica até o fim |

A amplitude do tremor é a mesma escala da vibração (o diretor de som e
háptica casa os dois números). Nenhum evento passa de 4 batidas de tremor.

### O humor do perdedor

1. **O corpo ri, a tela não.** A falha é física (o
   [princípio 6](../02-principios.md#6-a-falha-é-física)). Nenhuma palavra,
   nenhum som de vaia, nenhuma risada gravada.
2. **O tombo tem estilo.** Cada minigame tem uma falha própria (lista nos
   arquivos de seção). `emote-no` em 40 dos 45 é a mesma piada 40 vezes: cada
   seção usa no máximo 2 minigames em que a falha é só o `emote-no` com uma
   faísca.
3. **O tombo é de todos.** A falha grande acontece no meio da raia, no
   tamanho de "estrondo", para a sala apontar. Quem caiu ri junto porque o
   cavaleiro dele é o protagonista daquele segundo.
4. **O último tem um verbo.** Em todo minigame o último colocado tem algo
   que mexe no jogo dos outros, ou uma chance de virada que se vê. O
   fantasma que sopra vento (J2), acende a luz (L5) e faz barulho (O4) é o
   modelo.
5. **O inserto do último é carinho.** O close de 1 batida do resultado
   ([01](../arte/01-cinema.md#o-plano-de-cada-momento)) mostra o último
   fazendo uma pose de "na próxima" (cruza os braços, bate a poeira, ajeita o
   elmo), nunca chorando nem caído. Pedido ao diretor de arte: três poses,
   sorteadas.
6. **O tombo da faixa.** No resultado, depois do inserto do último, 2
   batidas mostram de novo o maior tombo do minigame (o `momento` de degrau
   "estrondo" ou "catástrofe" que mais se repetiu), em câmera lenta a 50 %,
   com o nome do dono em Permanent Marker. É a única glória que o último
   pode levar, e ele leva com o nome. Pedido ao diretor de arte e cinema
   (mexe no plano do resultado).

## A curva padrão dos três terços

As fichas de hoje fazem o terceiro terço igual ao primeiro: a música desce e
a tensão cai no fim. A régua muda isso.

| terço | em 90 s | o que é | o que muda |
| --- | --- | --- | --- |
| **1. ensina** | 0 a 30 s | a regra aparece sozinha | uma nota a cada 2 tempos por lugar; o erro custa pouco; o primeiro grito pequeno antes de 10 s |
| **2. o pico** | 30 a 60 s | uma virada de situação, não só o dobro de notas | a densidade sobe 1,5 a 2 vezes **e** o mundo muda (o ringue encolhe, a neblina engrossa, a ordem embaralha); a luz sobe 20 % |
| **3. a reta** | 60 s ao fim | a disputa se decide | a densidade fica entre a do 1.º e a do 2.º; nas **últimas 16 batidas**, a reta: o objeto do placar vale o dobro, para todos |

**A reta (as últimas 16 batidas).** A fita está acabando. O carretel da
esquerda, no HUD da fita (o quadro [01](../../imagens/direcao/01_centelha_depois.jpg),
em cima, no meio), fica vazio e pisca na batida; o contador do deck fica
vermelho. A música entra na última frase (pedido ao diretor de som: um
corte de bumbo e a virada de 1 compasso na batida −16 de toda faixa). O que o
placar conta (espada, lingote, alvo, metro) vale 2 para todos. Não é ajuda
para o último: é a mesma regra para todos, e por isso a virada é justa. Nos
coop, a reta é o último fôlego: o que pesa contra a turma (o vento, o titã,
a queda da chama) dobra, e a vitória ainda dá.

Em minigames de outra duração, os terços se medem pela duração: 75 s
(25/50), 80 s (27/53), 100 s (33/67), 120 s (40/80).

## As notas de hoje

A nota é do minigame como a ficha está escrita hoje: 1 não diverte, 2 tem
uma graça escondida, 3 diverte quem joga, 4 faz a sala reagir, 5 faz a sala
gritar. Os motivos estão nos arquivos de seção.

| ficha | minigame | o momento de grito (`nome`) | nota hoje | troca? |
| --- | --- | --- | --- | --- |
| I1 | O Martelo de Hefesto | a espada racha no quinto golpe (`racha_no_quinto`) | 3 | não |
| I2 | Marcha dos Escudeiros | arrastado pela ladeira (`arrastado_na_ladeira`) | 4 | não |
| I3 | Portões de Néon | a panqueca (`achatado`) | 4 | não |
| I4 | O Fole | a forja chega ao branco (`branco`) | 2 | não; o fole se vê |
| I5 | A Esteira de Escória | o lingote de ouro (`lingote_de_ouro`) | 4 | não |
| J1 | A Viga | o pino dos quatro (`pino`) | 3 | não |
| J2 | Pêndulos do Caos | o arremesso (`arremesso`) | 4 | não |
| J3 | Patinação de Dados | a trombada (`trombada`) | 2 | **sim**: a pista de todos |
| J4 | O Balão dos Foles | a ultrapassagem (`ultrapassa`) | 4 | não |
| J5 | Mira Óptica | o escudo de ouro (`escudo_de_ouro`) | 3 | não |
| K1 | O Molde | o desmolde dos quatro (`desmolde`) | 2 | não; corta o abrir e fechar |
| K2 | Quebra-Gelo | a avalanche no líder (`avalanche`) | 2 | **sim**: o gelo vai para o líder |
| K3 | Hackeando o Terminal | a senha longa abre (`senha_longa`) | 4 | não |
| K4 | A Pinça | o estalo (`estalo`) | 2 | **sim**: o puxa-ferro |
| K5 | O Carimbo | o selo por cima (`selo_por_cima`) | 4 | não |
| L1 | O Cerco | o aríete (`ariete`) | 3 | não |
| L2 | Fuga do Titã | o braço do titã (`quase_pego`) | 4 | não |
| L3 | Curto-Circuito | o estouro (`estouro`) | 5 | não |
| L4 | Martelos Térmicos | as duas quentes (`dupla_quente`) | 3 | não |
| L5 | A Prensa | o esmagado (`esmagado`) | 4 | não |
| M1 | A Galeria | o alvo de ouro de todos (`alvo_de_ouro`) | 3 | não |
| M2 | Arco de Néon | a flecha de fogo (`flecha_de_fogo`) | 3 | não |
| M3 | Metralhadora de Feitiços | a nau capitânia cai (`nau_cai`) | 3 | não |
| M4 | Espada de Fita | o corte (`corte`) | 4 | não |
| M5 | A Catapulta | a pedra no próprio muro (`pedra_propria`) | 4 | não |
| N1 | O Canto | o sino torto (`sino_torto`) | 2 | não; o coro na TV |
| N2 | Eco do Abismo | despenca um andar (`despenca`) | 3 | não |
| N3 | Coral dos Quatro | o acorde dos quatro (`acorde`) | 3 | não |
| N4 | Código do Dragão | a fumaça grande (`fumaca_grande`) | 3 | não |
| N5 | Corta-Fio | caiu no bipe falso (`caiu_no_falso`) | 4 | não |
| O1 | Os Caminhos | a lama (`lama`) | 3 | não |
| O2 | Neblina de Dados | o salto no nada (`salto_no_nada`) | 3 | não |
| O3 | Passo no Fosso | o empurrão no plasma (`empurrao`) | 2 | **sim**: a dança das placas |
| O4 | Fuga do Mecha Cego | o holofote (`pego`) | 5 | não |
| O5 | Engrenagens Sincopadas | a engrenagem-mestra (`mestra`) | 3 | não |
| P1 | A Voz | o rugido (`rugido`) | 3 | não |
| P2 | O Sopro no Fole | a fuligem (`fuligem`) | 3 | não |
| P3 | Zero Absoluto | congelou no silêncio (`congelou`) | 5 | não |
| P4 | Grito de Guerra | fora do ringue (`fora_do_ringue`) | 5 | não |
| P5 | Palmas da Forja | a espada lendária (`lendaria`) | 3 | não |
| Q1 | A Prova | a virada da frente (`virada`) | 4 | não |
| Q2 | Roubo de Bateria | caiu na porta da base (`caiu_na_porta`) | 2 | não; corta a interferência |
| Q3 | Mecha de Dois Pilotos | o soco na própria cabeça (`autossoco`) | 5 | não |
| Q4 | Ruge o Reator | o rugido do meio (`rugido_do_meio`) | 4 | não |
| Q5 | O Último Acorde | o dragão se levanta de novo (`levanta`) | 4 | não |
| R | O Relâmpago | ninguém perde (`todos_falharam`) | 3 | não; uma cena por carta |

Média dos 45 hoje: 3,4 (152 pontos em 45). Cinco com nota 5, quinze com nota
4, dezessete com 3, oito com 2, nenhum com 1. A seção mais fraca é O Molde
(2,8); as mais fortes são O Impacto, A Voz e A Prova (3,8 cada). Com as
trocas e as mudanças feitas, a meta é nenhuma nota abaixo de 3 e média 3,8.

## As trocas propostas

Quatro minigames trocam a ideia central. Cada troca mantém a feature, o
verbo da seção e o que o registro mede; muda o que acontece entre os
jogadores. A justificativa inteira está no arquivo da seção.

| ficha | hoje | a troca | por quê, numa linha |
| --- | --- | --- | --- |
| J3 | quatro pistas separadas, cada um coleta os seus dados | [a pista de todos](J-a-viga.md#j3--patinação-de-dados): uma laje só, o dado branco de ninguém, a trombada | coletar sozinho em raia própria não tem um segundo de contato; gelo com contato é comédia |
| K2 | cada um racha os seus blocos | [o gelo vai para o líder](K-o-molde.md#k2--quebra-gelo): cada bloco quebrado manda um bloco duro para quem está na frente | o "para, para!" de quem recebe é o grito; o ambiente pesa na liderança (princípio 8) |
| K4 | passar de 0,45 da largura é a regra, e ninguém vê | [o puxa-ferro](K-o-molde.md#k4--a-pinça): esticar quanto der, soltar antes de estalar | um limite que se vê e se arrisca faz a sala gritar "solta!" |
| O3 | a mesma ideia da O2 (a mão pulsa, salte para avançar na sua raia) | [a dança das placas](O-os-caminhos.md#o3--passo-no-fosso): menos placas que cavaleiros, quem chega primeiro fica | a seção tinha dois verbos iguais; a troca dá à seção o único minigame de contato |

Mais quatro mudam sem trocar a ideia: I4 (o fole se vê), K1 (o abrir e
fechar sai), N1 (o coro na TV) e Q2 (a interferência sai). As trocas e as
mudanças são decisão da Vitória junto com a direção: a linha para o
[ESPERA-ELA](../o-time/ESPERA-ELA.md) está em
[O que preciso de outras cabeças](#o-que-preciso-de-outras-cabeças).

## As regras que valem para os 45

1. **A primeira volta é da bancada; o resto é do jogo.** Quando a ficha usa
   entradas a mais para medir o controle (I1: os 13 botões; J1: o volante;
   K1: os dois dedos), a primeira volta pede tudo, e da segunda em diante o
   minigame fica só com o que diverte.
2. **O robô tenta a graça.** Todo minigame de sabotagem tem um robô que
   rouba, borra ou manda o falso (I5, K5 e N5 já têm). Nas trocas, o robô
   faz a interação nova (a trombada, a avalanche, o estalo, o empurrão).
3. **Dois congelamentos nunca na mesma partida de 5.** O4 (pare quando ele
   para) e P3 (cale quando ele escuta) são a mesma brincadeira de "estátua";
   o sorteio da noite não põe os dois na mesma partida de 3 ou de 5. Pedido
   a quem cuida do sorteio (o [03](../03-os-45-minigames.md#a-noite-sorteada)).
4. **O microfone é relativo.** Na seção P, quatro microfones ouvem a mesma
   sala. A voz conta para o dono quando o microfone dele está 6 dB ou mais
   acima da média dos outros três no mesmo quadro. Sem isso, a risada de um
   congela os quatro em Zero Absoluto, e um grito empurra todo mundo em Grito
   de Guerra.
5. **O stat muda o como, nunca o quem ri.** Nenhum stat do cavaleiro muda a
   janela de julgamento em mais de 15 ms, nem tira a falha física, nem o
   momento de grito. Pedido ao designer de sistemas.

## O que preciso de outras cabeças

| de quem | o quê |
| --- | --- |
| o arquiteto e DevOps | o robô por lugar (`--robo=bom,medio,medio,ruim`); o tipo `momento` no registro, com `x_tela` e `altura_tela` gravados pela prova visual; um portão que lê o [momentos.csv](momentos.csv) e reprova o minigame cujo momento não aparece na mesa dita |
| o diretor de arte e cinema | tirar a frase de instrução do quadro 01; o rastro de 2 s ou mais em toda falha; a luz que cai 30 % fora do dono do grito; as três poses do inserto do último; o plano do "tombo da faixa" no resultado (2 batidas a 50 %); o carretel que pisca na reta |
| o diretor de som e háptica | o sinal da reta em toda faixa (o corte de bumbo e a virada de 1 compasso na batida −16); o coro das respostas na TV da N1; casar a amplitude do tremor da tabela de impacto com a vibração |
| o pesquisador do DualSense | medir quanto um sopro, uma palma, uma risada e um grito vazam para o microfone de um controle a 50 cm e a 1 m (a regra dos 6 dB depende disso) |
| o designer de sistemas | o teto dos stats (15 ms na janela, nenhum efeito no momento de grito) |
| o roteirista | copiar para a parte **A diversão** de cada ficha o momento, a curva, o rastro e o teste deste arquivo, e escrever a chamada da linha `momento` |
| quem guarda o [ESPERA-ELA](../o-time/ESPERA-ELA.md) | a linha: «08/10/2026 · aprovar as quatro trocas de ideia (J3, K2, K4, O3) e as quatro mudanças (I4, K1, N1, Q2) da [diversão](../diversao/README.md#as-trocas-propostas) · o enriquecimento de J, K, O, I, N e Q» |
| quem cuida do [03](../03-os-45-minigames.md) | o sorteio: O4 e P3 nunca na mesma partida de 3 ou de 5; e, aprovadas as trocas, as linhas de J3, K2, K4 e O3 reescritas |

## O que muda em outros documentos

- O [02, princípio 9](../02-principios.md#9-um-momento-a-cada-trinta-segundos)
  ganha a reta: além do pico no meio, as últimas 16 batidas são a reta, e o
  terceiro terço nunca repete o primeiro.
- O [02, princípio 10](../02-principios.md#10-pouco-texto) fica mais duro:
  durante o jogo, zero frase.
- A parte **A diversão** da [ficha pronta](../o-time/ficha-pronta.md) passa a
  pedir quatro coisas: o `nome` do momento, a janela em segundos, a mesa e o
  rastro na prancha.
