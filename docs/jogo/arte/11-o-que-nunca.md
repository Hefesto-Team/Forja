# 11 O que nunca

A lista do que não entra na Forja. Cada linha diz o que fica de fora e por
quê. Uma exceção só entra escrita aqui, com a data e o motivo.

## A imagem

| nunca | por quê |
| --- | --- |
| imagem, textura, música ou voz gerada por modelo | a fita é feita à mão: o que se vê é desenhado por código, recolorido da Kenney ou escrito por pessoas |
| as cores dos jogadores fora do jogador | o néon tem dono ([07](07-vfx.md#o-que-conta-como-brilho)); um ciano no cenário apaga o P1 |
| cor escrita fora do arquivo de tokens | uma cor sem nome não tem trabalho ([02](02-cor-e-letra.md)) |
| vermelho de "errou", verde de "acertou" | o erro não tem cor; o acerto é a cor de quem acertou |
| `ERRO_R` e `ERRO_B` fora da Dissonância | é a cor do vilão |
| brilho sem dono, ou acima do teto do dono | idem |
| vidro, cromo, holograma, metal espelhado (`metallic` acima de 0,2) | não cabe numa fita feita em casa |
| gradiente arco-íris, brilho de "raridade", estrela que gira | parece loja, não fita |
| tela dividida | uma câmera só, compartilhada ([06 Telas](../06-telas-e-fluxo.md#a-câmera)) |
| sprite com borda suave sobre o 3D (partícula de fumaça, lens flare) | a Forja é de blocos |
| a lente abaixo de 24 mm ou acima de 100 mm | distorce ou achata ([01](01-cinema.md#a-tabela-de-lente)) |
| roll da câmera | só a Dissonância inclina, 6° |
| corte durante o jogo | quem joga perde o próprio cavaleiro |
| tremor de ambiente | o tremor é do evento |
| SSAO, sombra de mais de uma luz | o Compatibility não dá, e o que ele finge fica sujo |

## A letra

| nunca | por quê |
| --- | --- |
| uma quinta fonte, ou Space Grotesk e JetBrains Mono no jogo | quatro fontes, quatro trabalhos ([02](02-cor-e-letra.md#as-quatro-fontes)) |
| texto abaixo de 30 px | o sofá fica a 3 m ([10](10-acessibilidade.md#o-texto-mínimo)) |
| emoji Unicode na tela ou em `traducoes.gd` | as reações são adesivos e carimbos desenhados ([09](09-reacoes.md)) |
| caixa alta decorativa em frase | só o Bungee é caixa alta, e só no grito |
| PERFECT, MISS, GOOD, nota de prova, "Errou", "Você perdeu" | o vocabulário é o do doc [07](../07-narrativa-e-voz.md#o-vocabulário-do-visor); o erro não tem palavra |
| palavra técnica na tela (mesa, uinput, hidraw, MAC, relatório, veredito, módulo nativo) | o jogador não está na bancada |
| texto que pulsa, treme ou gira depois de pousado | texto é para ler |
| cor de jogador como letra sobre a etiqueta | contraste de 1,2 a 2,6 ([02](02-cor-e-letra.md#texto-sobre-a-etiqueta)) |

## O movimento

| nunca | por quê |
| --- | --- |
| impacto fora da grade da batida (mais de 1 quadro) | tudo cai na batida ([05](05-movimento.md)) |
| transição fora das doze do [06](06-interface-e-texto.md#as-transições) (dissolve, wipe em estrela, zoom de tela, página que vira) | cada transição é um objeto de fita |
| `QUICA` em placa, texto ou câmera | o quique é o humor do corpo |
| zoom que pulsa no tempo durante o jogo | a câmera anda pelas regras do [01](01-cinema.md) |
| mais de 3 piscadas por segundo, clarão em mais de 20 % da tela | [10](10-acessibilidade.md#o-piscar) |
| hit-stop que para o relógio de áudio, a física ou o julgamento | só a imagem congela |

## O tom

| nunca | por quê |
| --- | --- |
| rir de quem perdeu com palavra | o humor mora no corpo e na física ([pilar 4](README.md#os-pilares)) |
| adesivo que xinga, aponta ou mostra dente | rivalidade de sofá, não ofensa |
| tela de loja, moeda premium, anúncio, cronômetro de oferta | a fita é nossa |
| tutorial em texto corrido | o jogo ensina em 1 a 3 linhas e no treino que não vale |
| créditos de quem fez o jogo no fim da noite | o fim da noite é das pessoas que jogaram ([01](01-cinema.md#os-créditos-são-o-encarte)) |
| a palavra "Afinado" para outra coisa que não o julgamento ótimo | é vocabulário do visor |

## O som e a mão

| nunca | por quê |
| --- | --- |
| "buzz" de erro | o erro é a nota do cavaleiro saindo desafinada ([03](03-som.md#o-carimbo-de-cada-julgamento)) |
| um evento só com imagem, sem som e sem vibração | ver, ouvir e sentir no mesmo quadro ([pilar 5](README.md#os-pilares)) |
| vibração para avisar adesivo de outra pessoa | a vibração é informação de jogo |
| som que toca no alto-falante da máquina em teste ou prova | a prova é muda |
