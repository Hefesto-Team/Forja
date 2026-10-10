# G04c — O texto grande fora do HUD

**Sprint:** G · **Tamanho:** P · **Estimativa:** meio dia · **Depende de:** G04 (as partidas 5 e 6 da prova visual, em
inglês e em português com o texto grande), F09b (a régua do contraste dos textos esmaecidos) · **Usado por:** nenhuma

## Por quê

A G04 acrescentou à prova visual duas partidas com o texto grande: a 5, em inglês, e a 6, em português. O HUD da G04
passou nas duas, depois de o carimbo do cavaleiro na borda ser empurrado para dentro da área segura. As outras telas
reprovaram, e nenhuma delas é do HUD. Com o texto a 1,15, o título, o cartão do resultado e o placar encavalam ou
perdem contraste. Quem liga o texto grande para ler melhor encontra justamente essas telas piores.

## Ler antes

- [06 — o texto](../arte/06-interface-e-texto.md): o piso de 30 px, a área segura e o contraste de 3:1.
- [F09b](F09b-os-achados-da-prova-visual.md): os achados da prova visual no texto normal. A tela parada já está lá e
  na F09d, por isso não entra aqui.
- [G04, «O que foi feito»](G04-o-hud-de-cada-jogador.md#o-que-foi-feito-leva-1-as-telas).

## O estado de hoje

A medida é a passada fixa de 09/10, o `checagens.txt` das partidas 5 e 6:

| tela | achado (inglês / português) | onde mora |
| --- | --- | --- |
| o título | «A FORJA» com contraste 2,8:1; «A FORJA» encavalada com «Nine rooms, four knights» / «Nove salas, quatro cavaleiros» (796,367 656×146 e 794,502 570×46 / 673×46) | `godot/scripts/ui/tela_titulo.gd:64`: o subtítulo em `et.position + Vector2(338, 268)` não desce quando o título cresce |
| o cartão do resultado da sala | «Hephaestus's Hammer» / «O Martelo de Hefesto» e «The Gallery» encavalados com «Button» e «(Continue)» / «Botão» e «(Continuar)» (558,313 943×74 e 1079,343 83×35); «(Continuar)» com 1,6:1 | `godot/scripts/ui/resultado.gd:125`: `Desenho.dicas_a_direita` em `r.position.y + 84`, na mesma faixa do título largo |
| o placar | «4» / «1» com contraste 1,0:1, 22 vezes | `godot/scripts/ui/placar.gd`: os números da coluna da noite (1,0:1 é o número com a mesma luz do que está em volta; a causa ainda não foi medida) |
| o carimbo do julgamento | «Ressonância!» com 2,8:1 (01:27, o rosa do P2 e o amarelo do P3 lado a lado, sobre o chão aceso) | `godot/scripts/ui/visor.gd`, `_draw`; a régua lê o anel a 3 px da caixa sem o giro, que cai entre o contorno de 6 px da `FITA` e o chão |

## O alvo

- O título: o subtítulo desce com a altura do título (`Tema.t`), sem encostar, e o «A FORJA» passa de 3:1 sobre a
  etiqueta.
- O resultado: a dica «Botão ✕ (Continuar)» vai para baixo do título quando os dois não cabem na mesma linha, e tem
  o contraste da placa.
- O placar: medir qual número é (a coleta e a prancha do 02:39 e do 02:55) e dar a ele o contraste de 3:1.
- O carimbo: medir antes, com a coleta do anel desenhada sobre a prancha, para decidir se o contraste de 2,8 é do
  carimbo (a cor do lugar sobre o chão aceso) ou da régua (o anel cai fora do contorno). Se for do carimbo, a cura é a
  chapa da `FITA` mais larga, pelo 07, nunca outra cor.

## Passos

1. Ler as duas checagens e as pranchas `prancha-en-grande*.png` e `prancha-pt-grande*.png`.
2. O título, o resultado e o placar, um commit cada.
3. O carimbo: a medida primeiro, depois a decisão (com a dela, se mudar o 07).
4. `PASSADAS=fixa PARTIDAS="5 6" bash tests/prova_visual.sh`.

## Armadilhas

- A largura do cartão do resultado não cresce com o texto grande; a dica tem de descer, não encolher.
- Não afrouxar a régua (o mínimo de 30 px, os 5 % de margem, o contraste de 3:1).

## Não fazer

- O HUD da G04 (os cartões, a etiqueta, o deck): já passa nas duas línguas e nas duas escalas.
- A tela parada (F09b, F09d).

## Pronto quando

As partidas 5 e 6 da prova visual não têm reprovação de texto fora a tela parada.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`.
- `PASSADAS=fixa PARTIDAS="5 6" bash tests/prova_visual.sh`: o `checagens.txt` sem colisão, contraste ou área segura.

## Para o André (local)

1. Opções › Texto › Grande, Idioma › English e depois Português: o título, uma sala até o resultado e o placar, na
   TV do sofá.

## Ao terminar

No [quadro](README.md), G04c **feito** com o commit.
