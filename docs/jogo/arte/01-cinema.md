# 01 O cinema

A Forja é filmada como um filme de uma noite só. Cada momento tem um plano,
uma lente, uma altura, um movimento e um jeito de cortar. Este arquivo decide
os cinco e diz como a luz muda de seção para seção.

## As regras da câmera

1. **A câmera não corta durante o jogo.** Do apito de início ao apito de fim,
   o plano é um só. Ela pode andar, mas não pula. Quem joga precisa achar o
   próprio cavaleiro sem procurar.
2. **O corte cai no tempo 1 do compasso.** Fora do jogo, toda troca de plano
   acontece no primeiro tempo do compasso da faixa que está tocando, com
   tolerância de um quadro. Corte fora do tempo 1 é erro de montagem.
3. **O movimento dura batidas inteiras.** Um push-in, uma órbita ou um
   travelling dura 1, 2, 4 ou 8 batidas, e termina num tempo. A curva é
   `ease_in_out` com o meio na metade exata.
4. **A câmera não gira no próprio eixo.** O roll é zero. A única exceção é a
   Dissonância, que inclina o quadro 6° quando a fita enrosca.
5. **O tremor é do evento, não da câmera.** A câmera treme quando algo cai,
   bate ou explode, por no máximo 4 batidas, e a amplitude vem do evento (doc
   05, o mesmo número da háptica). Nunca há tremor de ambiente.
6. **O hit-stop é visual.** No julgamento perfeito ("Ressonância!"), a imagem
   do cavaleiro que acertou congela 2 quadros (33 ms). O relógio de áudio, o
   julgamento e a física nunca param.
7. **Toda câmera é vertical em KEEP_HEIGHT.** A lente se diz em milímetros e
   vira FOV vertical pela tabela abaixo. O jogo hoje usa 40° em 16:9
   (`godot/scripts/main.gd:947`), que é perto de 33 mm.

### A tabela de lente

Sensor full frame (24 mm de altura). FOV vertical = 2·atan(12/f).

| lente | FOV vertical | uso |
| --- | --- | --- |
| 14 mm | 81,2° | nunca (distorce o cavaleiro) |
| 18 mm | 67,4° | nunca no jogo; só a Dissonância no auge |
| 21 mm | 59,5° | nunca |
| 24 mm | 53,1° | o plano de estabelecimento de uma seção |
| 28 mm | 46,4° | a corrida |
| 35 mm | 37,8° | o salão, a arena, o pódio |
| 40 mm | 33,4° | o padrão do jogo de hoje |
| 50 mm | 27,0° | a montagem, a dupla, o vencedor |
| 65 mm | 20,9° | o cartão |
| 85 mm | 16,1° | o título, os insertos, os créditos |
| 100 mm | 13,7° | o close do último colocado |
| 135 mm | 10,2° | nunca (achata demais a cena de sofá) |

## O plano de cada momento

| momento | plano | lente | altura e ângulo | movimento | como entra e sai |
| --- | --- | --- | --- | --- | --- |
| título | o cassete na mesa, a forja atrás fora de foco | 85 mm | à altura da mesa, frontal | push-in de 3 % em 8 compassos, e recomeça | entra no fade do PLAY; sai em corte seco no tempo 1 depois do ✕ |
| montagem | os quatro lugares lado a lado, um por coluna de 480 px | 50 mm | à altura do peito, frontal | parado | entra em corte; quando todos estão prontos, corte para o plano dos prontos |
| os prontos | os quatro cavaleiros vistos de baixo | 85 mm | baixo, contra-plongée de 10° | travelling lateral pelos quatro, 1 compasso por cavaleiro | sai em corte para o salão |
| salão | a forja inteira, os portões das seções | 35 mm | alto, 3/4 | deriva lenta de 2 % em 16 compassos | entra em corte; sai na cortina da entrada |
| estabelecimento da seção | o lugar da seção, vazio, na luz da tinta | 24 mm | à altura dos olhos | grua de 1 compasso, subindo 1,5 m | só na primeira faixa de cada seção |
| entrada do minigame | cortina 2D na tinta da seção, o verbo em Bungee | sem lente | 2D | o rasgo da fita, 900 ms | o impacto do rasgo cai no tempo 1 |
| cartão (como jogar) | o encarte da fita sobre a arena parada | 65 mm | frontal, um pouco acima | parado | corte seco |
| arena (jogo) | a arena inteira | 35 mm | plongée de cerca de 50° | o enquadramento de grupo da G05, nunca corta | entra no apito; sai no apito |
| corrida (jogo) | quem corre e o caminho à frente | 28 mm | atrás e acima, 30° | segue o líder (G05, modo corrida) | idem |
| dupla (jogo) | dois cavaleiros frente a frente | 50 mm | de lado, à altura do peito | parado, empurra 15 % na direção da ação | idem |
| apito | o último quadro do jogo | o do jogo | o do jogo | congela 3 quadros | corte seco para o resultado |
| resultado | o vencedor, contra-luz na cor dele | 50 mm | baixo, contra-plongée de 8° | órbita de 15° em 4 batidas | no fim da órbita, um inserto |
| inserto do último | o rosto do último colocado | 85 mm (100 mm se cabe) | à altura dos olhos | parado, 1 batida | corte para o placar |
| placar | a etiqueta com os números | sem lente | 2D | os VUs sobem na batida | corte no tempo 1 |
| virar a fita | o deck aberto, a fita na mão | 50 mm | de cima, 60° | a fita gira 180° em 2 compassos | corte para o salão |
| pódio | os três degraus, simétrico | 35 mm | baixo, contra-plongée de 8°, centro exato | push-in de 5 % em 8 compassos | entra em corte; sai no fade de 1 compasso |
| créditos | cada faixa da noite e quem venceu | 85 mm | à altura dos olhos | travelling lateral contínuo | cross-fade de 1 compasso entre faixas |
| fim da fita | o deck, o contador, a etiqueta | 85 mm | frontal | parado | ver "O fim da fita" |

A montagem é o único lugar em que o jogador se vê de frente e de perto. O
plano é de retrato: a câmera está onde estaria um fotógrafo de estúdio. O
contra-luz de cada coluna é a cor do jogador daquela coluna, e a luz de
frente é tungstênio. Enquanto ninguém forjou, a coluna fica violeta. Quando o
jogador forja (as 8 marteladas), a luz de frente da coluna dele passa de
violeta a tungstênio em 1 compasso. Quem olha a TV vê quem já terminou sem
ler nada.

## A montagem na batida

Os BPM de cada tela (o doc 04 manda; aqui é o que o corte usa):

| tela | BPM | 1 batida | 1 compasso (4/4) |
| --- | --- | --- | --- |
| título | 115 | 522 ms | 2087 ms |
| construção do cavaleiro | 120 | 500 ms | 2000 ms |
| salão | 110 | 545 ms | 2182 ms |
| pódio | 130 | 462 ms | 1846 ms |
| créditos | 90 | 667 ms | 2667 ms |
| minigame | o da faixa | 60000/BPM | 4 batidas |

Quando a ação manda trocar o plano fora do tempo 1 (alguém apertou ✕ no
título), a troca espera o próximo tempo 1. A espera máxima é um compasso; se
passar de 1,5 s, a troca vai para o próximo tempo forte (1 ou 3). Quem apertou
recebe o clique na hora, no controle e no som; só o corte espera.

## A luz das cinco tintas

Cada seção tem uma tinta (doc [02 A cor e a letra](02-cor-e-letra.md)). A
tinta não pinta o cavaleiro: ela pinta a névoa, o preenchimento e esquenta
um pouco a chave. Os cavaleiros continuam sendo o único néon saturado.

| seção | lado | tinta |
| --- | --- | --- |
| S1 A Centelha | A | vermelhão |
| S2 A Viga | A | cobalto |
| S3 O Molde | A | petróleo |
| S4 O Impacto | A | mostarda |
| S5 A Galeria | A | ameixa |
| S6 O Canto | B | cobalto |
| S7 Os Caminhos | B | petróleo |
| S8 A Voz | B | ameixa |
| S9 A Prova | B | vermelhão (fecha o círculo) |
| pódio | | mostarda (o ouro) |

A conta que tira as três luzes da tinta, no OKLab:

- **névoa** (a cor do ar ao longe): L 0,17, croma a 30 % do da tinta, o mesmo
  matiz;
- **preenchimento** (a luz ambiente que enche a sombra): L 0,34, croma a
  55 %;
- **chave** (o foco principal): tungstênio `#ffd9a8` (`Fita.TUNGSTENIO`) misturado com 20 % da
  tinta.

| tinta | hex | névoa | preenchimento | chave |
| --- | --- | --- | --- | --- |
| vermelhão | `#c8432f` | `#210502` | `#602016` | `#ffc99c` |
| cobalto | `#2f55c4` | `#050d26` | `#1f346a` | `#e5d3c6` |
| petróleo | `#1f8a7e` | `#011311` | `#11413b` | `#e5d7ad` |
| mostarda | `#c79a2a` | `#170e00` | `#493400` | `#f8d096` |
| ameixa | `#86409a` | `#18081c` | `#4a2854` | `#f8ccba` |

O salão é a casa: névoa `Fita.VIOLETA_FUNDO` (`#1d1638`), ambiente `#2a2738` a 0,5,
chave tungstênio. São os valores do estudo
(`godot/estudos/direcao/`), e ficam.

### O lado B

O lado B é o mesmo jogo, mais tarde da noite. Três coisas mudam e nada mais:

1. a chave cai para ×0,85 da energia do lado A;
2. a densidade da névoa sobe para ×1,3;
3. a etiqueta da seção ganha tarja dupla (duas tarjas de 7 px com 4 px de vão),
   onde o lado A tem uma só.

### O pico

No pico de um minigame (a música dobra), a chave sobe 20 % em 1 batida e a
névoa abre (densidade ×0,8). Volta em 2 batidas quando o pico acaba.

## A fita gasta

O pós da fita (`godot/estudos/direcao/shaders/pos_fita.gdshader`) tem uma
semente e um desgaste. A cada faixa jogada na noite, a fita gasta um pouco:

| uniform | faixa 1 | a cada faixa | teto |
| --- | --- | --- | --- |
| `grao` | 0,018 | +0,002 | 0,040 |
| `desbota` | 0,00 | +0,01 | 0,10 |
| `varredura` | 0,07 | +0,002 | 0,09 |
| `vinheta` | 0,38 | +0,003 | 0,45 |

`aberracao` e `rasgo` não gastam: são só da Dissonância e da entrada. Virar a
fita não zera o desgaste. A noite que durou doze faixas parece uma fita
que tocou doze faixas.

Com `Opcoes.flashes` desligado, `rasgo` e `aberracao` ficam em zero e o
desgaste continua (ele não pisca).

## A Dissonância

A Dissonância é a fita enroscando. É a única hora em que a câmera quebra as
regras, e por isso ela assusta.

- roll de 6° em 2 batidas, volta em 1;
- a lente abre até 18 mm em 1 batida (só no auge);
- `aberracao` vai a 0,8 e `rasgo` a 0,6, e volta em 2 batidas;
- a música perde tom (`pitch_scale` 1,0 para 0,94 em 1 batida, volta em 2);
- o som ganha os dropouts do tratamento de fita
  ([03 O som](03-som.md#o-tratamento-de-fita)).

## O virar da fita

Depois de `ceil(n/2)` faixas, onde `n` é o total de faixas da noite, a fita
vira. É o intervalo da noite: água, banheiro, conversa.

1. corte no tempo 1 para o deck aberto, 50 mm de cima;
2. a fita sai do deck, gira 180° na mão em 2 compassos, entra de novo;
3. o som do virar (`fx_virar`, 1,6 s) cobre o giro;
4. a etiqueta mostra "Lado B" na caneta;
5. o salão volta com a luz do lado B.

Quem quer pode reagir enquanto a fita vira ([09 As reações](09-reacoes.md)).
Qualquer jogador aperta ✕ para seguir; não há tempo limite.

É uma proposta de design de jogo: a ficha G18 a leva ao jogo.

## Os créditos são o encarte

Os créditos não listam quem fez o jogo (isso mora nas Opções). Eles listam a
noite: cada faixa que vocês jogaram, na ordem, e quem venceu cada uma, na
caneta, na cor do vencedor. É o encarte que alguém escreveria à mão depois.

- uma linha por faixa: número, nome do minigame em Archivo Narrow, o nome do
  vencedor em Permanent Marker na cor dele;
- entre o lado A e o lado B, a linha "Lado B" com a tarja dupla;
- 85 mm em travelling lateral, uma faixa por compasso de 90 BPM;
- cross-fade de 1 compasso entre a última faixa e o fim da fita.

## O fim da fita

O último plano da noite.

1. a fita chega ao fim: o leader (a ponta transparente) passa pela cabeça;
2. o auto-stop dá o clique (`fx_autostop`), no controle de todos;
3. o contador para no tempo real da noite, do PLAY até aqui (ex.: `1:47:12`);
4. a caneta escreve a data na etiqueta (`fx_caneta`, 400 ms);
5. as duas saídas aparecem: "Botão ✕ (Gravar outra noite)" e "Botão ◯
   (Ejetar)".

Nada pisca, nada sobe, nenhum número além do contador. É o silêncio depois da
festa.

## O storyboard da noite

Plano a plano, de quem liga o jogo a quem desliga. A duração está em batidas
no BPM da tela.

| # | momento | plano | lente | duração | som | háptica | texto |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | título | o cassete na mesa | 85 mm | até o ✕ | trilha do título, 115 BPM | nada | o logo; "Botão ✕ (Gravar)" |
| 2 | PLAY | o cassete entra no deck | 85 mm | 4 batidas | `fx_play` | clique no controle de quem apertou | o contador em 0:00:00 |
| 3 | a introdução (G01) | a bigorna, depois os pedestais | 35 mm | 24 s | vento, bigorna por lugar | uma martelada por lugar, ao acender | nenhum |
| 4 | montagem | quatro colunas | 50 mm | até todos prontos | trilha da construção, 120 BPM | o tique de cada troca de peça | as partes, os stats, o nome |
| 5 | os prontos | travelling pelos quatro | 85 mm | 4 compassos | o acorde da Forja, uma nota por cavaleiro | o batimento no controle de cada um, na vez dele | o nome de cada um na cor dele |
| 6 | salão | a forja inteira | 35 mm | até alguém escolher | trilha do salão, 110 BPM | nada | o nome do portão sob o cursor |
| 7 | estabelecimento | o lugar da seção | 24 mm | 1 compasso | a primeira nota da faixa | nada | o nome da seção |
| 8 | entrada | a cortina na tinta | 2D | 900 ms | `fx_entrada` | o impacto no tempo 1, em todos | o verbo em Bungee |
| 9 | cartão | o encarte | 65 mm | até todos ✕ | o laço da faixa, abafado | nada | uma a três linhas |
| 10 | minigame | arena, corrida ou dupla | 35, 28 ou 50 mm | a faixa | a faixa, a nota de cada um | a do minigame | o carimbo de cada julgamento |
| 11 | apito | o último quadro | o do jogo | 3 quadros | o apito; a música para seco | um pulso forte em todos | nenhum |
| 12 | resultado | o vencedor | 50 mm | 4 batidas | `fx_vitoria_p{n}`, depois o jingle | batimento duplo no vencedor | o nome do vencedor |
| 13 | inserto | o último colocado | 85 mm | 1 batida | `fx_derrota` | o rumble que cai no controle dele | nenhum |
| 14 | placar | a etiqueta com os números | 2D | 4 compassos | os VUs; o carimbo da virada | um tique por ponto subido, no dono | os pontos |
| 15 | virar a fita | o deck aberto | 50 mm | 2 compassos | `fx_virar` | rumble fraco em todos | "Lado B" |
| 16 | pódio | os três degraus | 35 mm | 8 compassos | trilha do pódio, 130 BPM | batimento duplo no primeiro | os nomes em Bungee |
| 17 | créditos | o encarte da noite | 85 mm | uma faixa por compasso | trilha dos créditos, 90 BPM | nada | as faixas e os vencedores |
| 18 | fim da fita | o deck parado | 85 mm | até ✕ ou ◯ | `fx_autostop`, `fx_caneta` | o clique do auto-stop em todos | o contador, a data, as duas saídas |

Os planos 7 a 14 se repetem a cada faixa; o 7 só na primeira faixa de cada
seção. O 15 acontece uma vez, no meio da noite.

## O que muda nos outros documentos

- O doc [06 Telas e fluxo](../06-telas-e-fluxo.md#a-câmera) segue valendo
  para o que a câmera enquadra. Este arquivo acrescenta a lente, a altura e
  o corte.
- A G05 (a câmera dos quatro) segue valendo dentro do jogo. A regra 1 (não
  corta) é dela também.
- A G17 leva a luz por seção, o pós e o desgaste ao jogo.
