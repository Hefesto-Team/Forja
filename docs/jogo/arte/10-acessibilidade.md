# 10 A acessibilidade

Quatro pessoas no sofá não enxergam, não ouvem e não se mexem do mesmo jeito.
A Forja se joga inteira com qualquer um dos três canais faltando, e nada na
tela machuca quem é sensível a luz ou a movimento.

## O daltonismo: a cor nunca sozinha

As quatro cores dos jogadores foram escolhidas para se separar nas três
visões de cor mais comuns. Medido no OKLab, com as matrizes de Machado,
Oliveira e Fernandes (2009), severidade 1 (as mesmas de
`scripts/daltonismo.gd`):

| visão | o par mais próximo | ΔE OKLab | o par mais distante |
| --- | --- | --- | --- |
| normal | P3 limão e P4 âmbar | 0,248 | P2 e P3, 0,477 |
| protanopia | P3 e P4 | 0,238 | P2 e P3, 0,447 |
| deuteranopia | P1 ciano e P2 magenta | 0,165 | P2 e P3, 0,301 |
| tritanopia | P2 magenta e P4 âmbar | 0,143 | P1 e P2, 0,446 |

**O piso:** nenhum par de jogadores fica abaixo de 0,12 em nenhuma das quatro
visões. Uma cor de jogador nova (ou ajustada) passa por esta conta antes de
entrar ([12](12-portoes.md#5-contraste)).

Mesmo assim, 0,143 é pouco para quem está a três metros. Por isso **a cor
nunca é o único sinal de quem é quem.** Todo lugar onde a cor marca o dono
leva também um destes, e quase sempre dois:

| sinal | onde | medida |
| --- | --- | --- |
| o P# | o cartão, o chip, a montagem, o placar, o pódio, o carimbo de quatro donos | Bungee, 30 px no mínimo |
| as lâmpadas | o cartão, a montagem, o anel no chão, o adesivo | as 5 posições do LED de jogador: 1, 2, 3 ou 4 acesas |
| o canto | o cartão do HUD | P1 alto à esquerda, P2 alto à direita, P3 baixo à esquerda, P4 baixo à direita |
| o controle na mão | a luz do controle e as lâmpadas dele | a mesma cor e o mesmo padrão da tela |
| o nome | o cartão, o pódio, os créditos | o nome que a pessoa escolheu |

No 3D, o anel de oito lados no chão tem as lâmpadas do lugar na frente dele
(1 a 4 barras de 0,09 × 0,14 m, `godot/estudos/direcao/mundo.gd`). O
`08b_daltonismo.jpg` é a prova: nas quatro visões, cada cavaleiro se acha
pelo P#, pelas barras e pelo canto.

## O contraste medido

A conta é a do WCAG 2.1. Os pares permitidos estão no
[02](02-cor-e-letra.md#os-pares-de-contraste-permitidos) e, em dado, em
[dados/contraste.csv](dados/contraste.csv).

| o que | o mínimo |
| --- | --- |
| texto abaixo de 48 px | 4,5 |
| texto a partir de 48 px | 3,0 |
| símbolo, glifo de botão, traço que informa | 3,0 |
| traço estrutural que não informa (trilho, segmento apagado) | sem mínimo |

Sobre a cena 3D o fundo muda a cada quadro. Por isso o texto sobre a cena tem
sempre uma de duas proteções: uma placa (casco ou etiqueta) por baixo, ou o
contorno `FITA` de 6 px em volta da letra. O carimbo usa o contorno; a dica e
o rodapé usam a placa.

As cores dos jogadores sobre `FITA` vão de 6,05 (magenta) a 17,0 (limão):
o carimbo na cor do dono, com o contorno `FITA`, passa em qualquer tamanho.

## O texto mínimo

- **30 px na tela lógica de 1920×1080**, para tudo o que se lê. Numa TV de 50
  polegadas a 3 m, 30 px são 1,7 cm de altura: cerca de 20 minutos de arco,
  a letra mínima confortável de longe.
- **O texto grande** nas Opções multiplica tudo por 1,15 (`Opcoes.texto`,
  `ESCALA_DO_TEXTO` em `godot/scripts/opcoes.gd`). Com ele, o mínimo vira 34,5
  px. A prova das telas fotografa as duas escalas nas duas línguas
  ([06 Telas](../06-telas-e-fluxo.md#o-hud-de-cada-jogador)).
- **O tempo de leitura:** texto que some sozinho fica max(2 s, 60 ms por
  caractere) ([06](06-interface-e-texto.md#o-texto-como-voz)). O carimbo do
  julgamento fica 500 ms porque o som e a vibração dizem a mesma coisa.

## O movimento reduzido

Hoje as Opções têm "Tremor" (`Opcoes.tremor`), que desliga o tremor da
câmera. A proposta é que ele vire "Movimento: Inteiro ou Reduzido", e que o
Reduzido faça tudo isto:

| o que | inteiro | reduzido |
| --- | --- | --- |
| tremor da câmera | até 4 batidas, amplitude do evento | nenhum |
| push-in, órbita, travelling, grua | os do [01](01-cinema.md#o-plano-de-cada-momento) | corte seco para o plano final |
| roll da Dissonância (6°) e a lente a 18 mm | sim | não |
| squash e stretch | até 20 % | até 5 % |
| hit-stop | 2 quadros | nenhum |
| o corpo que abaixa no tempo | 2 % | nenhum |
| a tela que treme na cortina | 8 px | nenhuma |
| o confete | 160 no pódio, girando | 40, sem giro |
| o adesivo e o carimbo | escala e rotação | 4 quadros de opacidade |
| a fita girando no virar da fita | 180° em 2 compassos | corte |

O jogo continua o mesmo: nenhum julgamento, janela ou ponto muda. A proposta
vai para a ficha G16.

## O piscar

A regra é a do WCAG 2.3.1, a mesma que `scripts/medir_clarao.gd` já mede:

- **no máximo 3 piscadas por segundo**, somadas todas (rasgo, branco do
  perfeito na luz do controle, acerto que acende, pico da luz);
- **nenhum clarão cobre mais de 20 % da tela.** Um pixel conta quando a
  luminância relativa muda 10 % ou mais e o mais escuro dos dois está abaixo
  de 0,8. A Voz (o clarão do susto) já passa por esta medida;
- **nada pisca em vermelho saturado** (o `ERRO_R` só aparece deslocado, em
  faixa fina, na Dissonância).

Com "Flashes" desligado (`Opcoes.flashes`):

| o que | com flashes | sem flashes |
| --- | --- | --- |
| `rasgo` e `aberracao` | os do [06](06-interface-e-texto.md#o-rasgo-de-vhs) | zero |
| a barra da pausa | sobe a cada 2 s | não existe |
| o branco do perfeito na luz do controle | 0,15 s | a cor do lugar fica parada |
| o acerto que acende (2,6 por 4 quadros) | sim | fica em 2,0 |
| o pico da luz | +20 % em 1 batida | +10 % em 2 batidas |
| o desgaste da fita | sim | sim (ele não pisca) |

## Quando falta um canal

Todo evento de jogo chega por pelo menos dois dos três canais: ver, ouvir e
sentir ([pilar 5](README.md#os-pilares)).

| falta | o que segura |
| --- | --- |
| a visão de cor | o P#, as lâmpadas, o canto, o controle na mão |
| a audição | o carimbo do julgamento na tela, a vibração do julgamento, o VU; a pista sonora de cada minigame tem uma pista visual (a ficha diz qual) |
| a vibração (desligada, ou no rádio sem háptica) | o som no alto-falante do controle e a imagem |
| o movimento fino da mão | o modo "Jogar no teclado" e a janela de julgamento que não muda com o stat |

## As reações

Com "Reações: Nenhuma" ([09](09-reacoes.md#com-o-conforto)), nenhum adesivo e
nenhum carimbo do jogo aparece. O julgamento continua: ele é jogo, não reação.

## A prova

- O `08b_daltonismo.jpg` refeito a cada mudança de cor (`scripts/daltonismo.gd`).
- O portão de contraste e o de texto mínimo ([12](12-portoes.md)).
- A medida de clarão (`scripts/medir_clarao.gd`) em cada quadro de pico das
  pranchas de VFX.
