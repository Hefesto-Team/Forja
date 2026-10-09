# 09 As reações

As reações são os emojis da Forja. São de dois tipos, e o tipo diz quem
mandou:

- **o adesivo** é do jogador. Ele cola na fita o que sente: riso, susto,
  bronca. É papel recortado, colorido, com a cara desenhada;
- **o carimbo** é do jogo. O jogo carimba o que aconteceu: a virada, a
  sequência, o acorde. É tinta batida, sem fundo.

Nenhum dos dois é emoji Unicode, nenhum é imagem pronta de fora e nenhum é
gerado: todos são desenhados por código, como o HUD do estudo
(`godot/estudos/direcao/hud.gd`). A lista em dado está em
[dados/reacoes.csv](dados/reacoes.csv).

## O adesivo: a cara de fita

A cara de quase todo adesivo é um cassete visto de frente: **os dois
carretéis são os olhos e a janela da fita é a boca.** É o rosto que a Forja
já tem em todo canto (o deck, a etiqueta), e se lê do sofá.

| parte | medida (no adesivo de 112 px) | cor |
| --- | --- | --- |
| o recorte (die-cut) | borda de 6 px em volta do desenho, cantos de 14 px | `ETIQUETA` |
| o fundo | a forma do desenho | a cor do dono |
| o traço | 6 px, pontas redondas | `TINTA` |
| os carretéis (olhos) | círculos de 22 px, com 6 dentes de 3 px | `TINTA`, o cubo em `ETIQUETA` |
| a janela (boca) | 44 × 16 px, raio 6 | `TINTA` |
| as lâmpadas do dono | 5 posições de 10 × 5 px, vão de 3, no canto de baixo à direita, por dentro do recorte | `TINTA` acesas, apagadas sem traço |
| a sombra | deslocada (4, 6) | `SOMBRA` |

O traço em `TINTA` sobre a cor do jogador tem contraste de 5,44 (magenta) a
15,3 (limão) ([02](02-cor-e-letra.md#texto-sobre-a-cor)). As lâmpadas no
adesivo garantem que a cor nunca está sozinha.

### Os oito adesivos

O jogador tem uma roda de oito. A direção é sempre a mesma, para a mão
aprender.

| direção | id | nome | o desenho | o que diz |
| --- | --- | --- | --- | --- |
| ↑ | `rea_martelada` | Martelada | um martelo batendo, com três traços de impacto | "boa!" |
| ↗ | `rea_brasa` | Brasa | uma chama de três línguas | "tá pegando fogo" |
| → | `rea_acorde` | Acorde | um coração feito de uma volta de fita | "amo vocês" |
| ↘ | `rea_riso` | Riso | a cara de fita com os carretéis em arco (^ ^) e a janela aberta | "kkk" |
| ↓ | `rea_chororo` | Chororô | a cara de fita com uma tira de fita escorrendo de cada carretel | "sofri" |
| ↙ | `rea_susto` | Susto | a cara de fita com carretéis de 32 px e a janela em O | "eita!" |
| ← | `rea_bronca` | Bronca | a cara de fita com sobrancelhas em V e a janela reta | "você me paga" |
| ↖ | `rea_de_olho` | De olho | a cara de fita com os cubos dos carretéis puxados para o lado | "tô de olho" |

Nenhum adesivo xinga, reprova ou aponta para outro jogador. A Bronca é
rivalidade de sofá, não ofensa: as sobrancelhas são de fita e a boca é reta,
nunca dentes.

## Os carimbos do jogo

O carimbo é tinta: sem fundo, sem recorte. A letra é Bungee com o
desregistro da impressão e o contorno `FITA` de 6 px
([07](07-vfx.md#o-carimbo)). A cor é a do jogador de quem o carimbo fala.

| id | no visor | quando o jogo manda | onde | letra | de quem |
| --- | --- | --- | --- | --- | --- |
| `car_virada` | VIRADA! | no placar, quem passa a ser o primeiro | ao lado da linha dele no placar | Bungee 64 | quem virou |
| `car_em_chamas` | EM CHAMAS | 5 julgamentos "Ressonância!" seguidos do mesmo jogador | acima da cabeça dele | Bungee 46 | ele |
| `car_por_um_fio` | POR UM FIO | o vencedor do minigame ganha por 2 % dos pontos ou menos | acima da cabeça do vencedor, no resultado | Bungee 64 | o vencedor |
| `car_liga` | LIGA! | a peça entra em liga com o corpo ([04](04-o-cavaleiro.md#a-liga)) | sobre a linha "Arma ou amuleto" da coluna dele | Bungee 46 | ele |
| `car_acorde` | ACORDE MAIOR! | os quatro acertam "Ressonância!" no mesmo tempo 1 | centro da tela, y = 300 | Bungee 112 | os quatro |
| `car_emburrado` | (sem palavra) | o último colocado, no inserto do resultado | acima da cabeça dele | a cara de fita de 160 px, em tinta, carretéis meio fechados e a janela virada para baixo | ele |

O `car_acorde` é o único carimbo de quatro donos: a palavra em `ETIQUETA`, e
embaixo dela quatro tarjas de 12 × 80 px, uma por lugar, na ordem P1 a P4,
cada uma com o P# em Bungee 30 em `TINTA`.

O `car_emburrado` é o único sem palavra, porque o humor nunca usa palavra de
reprovação ([pilar 4](README.md#os-pilares)).

Quando um evento tem carimbo, a fala do mesmo evento
([07 Narrativa e voz](../07-narrativa-e-voz.md#as-falas)) não aparece: um
dos dois, nunca os dois.

## Quando o jogador manda

**O gesto:** o touchpad. Encostar o dedo abre a roda de oito no cartão do
jogador; deslizar escolhe a direção; soltar cola. Soltar a menos de 15 % da
largura do touchpad do ponto de partida cancela. No teclado, as teclas 1 a 8
na ordem da tabela (↑ é o 1, no sentido do relógio).

| tela | pode mandar |
| --- | --- |
| título, montagem, os prontos, salão | sim |
| a cortina da entrada, o apito | não |
| o J-card (treino) | sim |
| o minigame | só quem está fora da rodada (eliminado, ou esperando a vez na dupla) |
| resultado, placar, virar a fita, pódio, créditos, fim da fita | sim |
| a pausa | não |

Nos minigames da seção 3 (o touchpad é o controle), ninguém manda adesivo
durante o jogo.

**O limite:** um adesivo vivo por jogador; o novo substitui o velho, que
descola em 4 quadros. No máximo 3 adesivos por jogador a cada 4 batidas; o
quarto não sai, e a roda fica em `GRAFITE` até a janela abrir.

## Quando o jogo manda

O jogo manda só os seis carimbos acima, nos eventos da tabela. No máximo um
carimbo do jogo vivo por jogador e dois na tela. Quando dois disputam a vez,
vale a ordem: `car_acorde`, `car_virada`, `car_em_chamas`, `car_por_um_fio`,
`car_liga`. O `car_emburrado` só existe no inserto, sozinho.

Cada ficha de minigame diz, na parte **As reações**
([A ficha pronta](../o-time/ficha-pronta.md#as-partes)), quais destes carimbos
ela pode disparar e em que evento dela. Nesta leva não há carimbo próprio de
minigame.

## Onde aparecem

| o quê | onde | tamanho |
| --- | --- | --- |
| o adesivo, com o cavaleiro grande na tela (montagem, os prontos, salão, resultado, pódio) | acima da cabeça do dono, 0,4 m acima do osso `head`, projetado | 144 px |
| o adesivo, nas outras telas | preso à borda de dentro do cartão do dono, metade para fora | 112 px |
| a roda | centrada na borda de dentro do cartão do dono | 240 px de diâmetro, oito adesivos de 64 px |
| o carimbo do jogo | a coluna "onde" da tabela | a letra da tabela |

O adesivo nunca cobre o cartão de outro jogador, o J-card nem a etiqueta. Se
a cabeça do dono sai da tela, o adesivo vai para o cartão.

## Quanto duram

| fase | adesivo | carimbo do jogo |
| --- | --- | --- |
| entra | cola em 120 ms: escala 1,35 a 1,0, `MOLA`, rotação sorteada entre −8° e +8° | bate em 80 ms: escala 1,35 a 1,0, `MOLA`, rotação −4° |
| fica | 4 batidas (2000 ms a 120), entre 1600 e 2800 ms | 4 batidas, entre 1600 e 2800 ms; o `car_virada`, 2 batidas |
| sai | descola em 1 colcheia: a ponta de cima levanta (escala Y de 1 a 0, pivô na base), `ENTRA` | some em 170 ms (opacidade) |
| o som | `reacao_pop` a −18 dB na TV e no alto-falante do controle do dono ([03](03-som.md#a-interface)) | pedido ao diretor de som: um id por carimbo no mapa do áudio |
| a vibração | o toque de interface no controle do dono (piso do doc 05) | nenhuma; a vibração é do evento |

A entrada do adesivo cai na próxima colcheia depois de soltar o dedo.

## Com o conforto

- **Movimento reduzido** ([10](10-acessibilidade.md#o-movimento-reduzido)):
  sem escala e sem rotação; o adesivo e o carimbo aparecem e somem em 4
  quadros de opacidade.
- **As Opções** ganham a linha "Reações": Todas, Só do jogo, Nenhuma. O
  padrão é Todas. Proposta: vai para a ficha G16.

## A prova

A prancha das reações ([PRODUÇÃO](PRODUCAO.md)) mostra os oito adesivos nas
quatro cores e os seis carimbos, no tamanho do jogo, sobre o casco e sobre a
arena, e passa pelo simulador de daltonismo (`scripts/daltonismo.gd`).
