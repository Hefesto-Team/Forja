# G04b — As placas que entram e a troca de etiqueta

**Sprint:** G · **Tamanho:** P · **Estimativa:** meio dia · **Depende de:** G04 (o cartão, a etiqueta, o deck, o
`Visor`), G16 (`Opcoes.movimento`) · **Usado por:** nenhuma

## Por quê

A G04 pôs os quatro cartões nos cantos, a etiqueta e o deck no alto da sala e o carimbo acima do cavaleiro. O que ela
deixou de fora é só movimento. Hoje, quando a fase vira `"jogo"`, as placas aparecem de um quadro para o outro e somem
do mesmo jeito no apito. A etiqueta da sala nova troca de texto sem descolar nem ser escrita. O 06 pede as duas
transições, e sem elas a entrada na sala é um corte seco.

## Ler antes

- [06 — os objetos](../arte/06-interface-e-texto.md#os-objetos): a troca de etiqueta e as placas que entram.
- [05 — as curvas](../arte/05-movimento.md): `SAI`, `ENTRA`, `MOLA`, `RETA`.
- [G04](G04-o-hud-de-cada-jogador.md), seção «A cena», os parágrafos «As placas entram» e «A troca de etiqueta». Os
  números desta ficha foram copiados de lá.

## O estado de hoje

- `godot/scripts/ui/hud.gd`, `trocar_etiqueta(titulo, impresso, tinta, inclinacao, lado_b)`, só guarda a etiqueta
  em `etiqueta`. O `_draw` a desenha parada, e não há `_secao_mostrada`.
- `godot/scripts/ui/hud.gd`, `_com_cartoes()`: os cartões, a etiqueta e o deck aparecem inteiros no primeiro quadro
  da fase `"jogo"` e somem quando ela acaba.
- `godot/scripts/main.gd`, `_entrar_na_sala`: chama `hud.trocar_etiqueta(...)` a cada sala, mesmo quando a seção é
  a mesma.
- `fx_caneta` já está em `godot/assets/sons/` e no `mapa.csv`, mas nada o toca.

## O alvo

| quando | o quê | quanto |
| --- | --- | --- |
| o primeiro quadro da fase `"jogo"` | cada cartão chega 160 px de fora do seu canto (P1 e P3 da esquerda, P2 e P4 da direita), opacidade de 0 a 1 | 1 batida, `SAI`. O P1 entra no quadro 0, o P2 1 colcheia depois, o P3 2 colcheias, o P4 3 colcheias |
| junto com o P1 | a etiqueta e o deck descem de −40 px | 1 batida, `SAI` |
| o apito | as seis placas saem juntas, 160 px para fora (a etiqueta e o deck para cima) | 1 colcheia, `ENTRA` |
| a seção da sala nova difere de `_secao_mostrada` | a etiqueta velha descola: sobe 40 px, gira +4° e some | 1 batida, `ENTRA` |
| logo depois | a nova cola, descendo de −40 px | 1 batida, `MOLA` |
| quando a caneta começa | o título é escrito da esquerda para a direita, por recorte (um `Control` filho com `clip_contents = true`, a mesma `rotation` e o `size.x` de 0 à largura do título); nunca letra por letra. `fx_caneta` toca na TV a −6 dB | 400 ms, `RETA` |
| movimento reduzido (`Opcoes.movimento == 1`) | só opacidade | 4 quadros |

A batida é `60.0 / Ritmo.bpm` s: 500 ms a 120 BPM sem música.

## Passos

1. Em `hud.gd`, guardar o tempo de entrada da fase `"jogo"` e o do apito, e calcular o deslocamento e a opacidade de
   cada placa no `_draw`. `retangulos()` devolve o retângulo final, não o do meio da animação, porque a prova de
   sobreposição lê o lugar de repouso.
2. Em `hud.gd`, `_secao_mostrada` e o descolar e colar da etiqueta, com o recorte da caneta e o `fx_caneta` pelo id
   do mapa.
3. Em `main.gd`, só acrescentar: a seção da sala nova vai para `trocar_etiqueta`.
4. Na prova do jogo, um passo do relógio confere que, 1 batida depois de a fase virar `"jogo"`, o cartão do P4 está no
   canto dele com opacidade 1. Outro confere que a troca para outra seção pede o `fx_caneta`.

## Armadilhas

- A batida muda com a faixa. Sem música, use 120 BPM, não um número fixo.
- `Desenho.anotar` (a coleta da F09) não vê a rotação de `draw_set_transform`. O texto girado da etiqueta tem de ser
  anotado sem ela, como a G04 já faz em `_texto_girado`.

## Não fazer

- Mudar o lugar de repouso de qualquer placa (é da G04).
- Animar o carimbo do visor (já anima).

## Pronto quando

As placas entram e saem como o 06 diz, a etiqueta descola e cola com a caneta só quando a seção muda, e o movimento
reduzido troca tudo isso por 4 quadros de opacidade.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`.
- `bash tests/prova_visual.sh`: nenhuma reprovação nova de texto.

## Para o André (local)

1. `./run-local.sh`, entrar em duas salas de seções diferentes: as placas entram uma depois da outra, e a etiqueta
   descola e é escrita.
2. Opções › Movimento › Reduzido: as mesmas duas salas, só com opacidade.

## Ao terminar

No [quadro](README.md), G04b **feito** com o commit.
