# Q — S9 — A Prova: os cinco minigames

**Sprint:** Q · **Tamanho:** G (cinco fichas) (a soma das cinco: Q1, Q4 e Q5 G, 2,0; Q2 e Q3 M, 1,5) · **Depende de:** H04, H08, H07, F01, F09, G03, e as seções S1 a S8 prontas antes dos medleys (Q4, Q5)

Esta é a ficha-mãe: o índice. O trabalho anda pelas cinco fichas abaixo, uma
por sessão, na ordem.

## A feature protagonista

**Tudo junto.** O fim de cada noite: o controle inteiro trabalha ao mesmo
tempo, em equipe — o gatilho com a parede e o clique da arma, a vibração do
lado de onde vem o golpe, a textura na mão, o som pessoal no alto-falante, a
barra de luz na cor do lugar. Por baixo, o registro mede a **carga**: as
saídas por segundo, as recusas sob carga, os quatro controles ao mesmo tempo.

## O cenário comum

- A arena da Prova: `Kit.arena` larga, a luz da casa cheia (tocha `#ffb070`,
  lilás `#b9b0ff`), as bandeiras (`Kit.peca(..., "banner")`) das duas equipes
  no fundo.
- **As equipes** (a mesma regra em Q1, Q3, na O5 e nos 2v2 das outras
  seções: J4, M4, M5): `presentes()` na ordem; os dois primeiros são a
  **Brasa**, os dois seguintes a **Maré**. O kit as monta (`equipe[l]`,
  `aprendizes[e]`, `montar_equipes`, H08). Falta gente, o **Aprendiz**
  completa:

  | jogadores | Brasa | Maré |
  | --- | --- | --- |
  | 4 | 1º e 2º | 3º e 4º |
  | 3 | 1º e 2º | 3º e o Aprendiz |
  | 2 | 1º e o Aprendiz | 2º e o Aprendiz |
  | 1 | 1º e o Aprendiz | dois Aprendizes |

  O **Aprendiz** é um boneco do jogo (o `character-orc.glb` tingido de
  `#b9a98a`, o `_tingir` de `prova.gd:199-209`), não um jogador: faz a parte
  dele acertando `ACERTO_APRENDIZ := 0.8` das vezes (sorteado com o `rng` do
  kit), sempre como BOM; não é lugar, não pontua, não entra no registro de
  notas. Não é robô (nada de `Forja.robo` nele).
- **As cores das equipes** vão **no mundo**: âmbar `#e8a33c` (Brasa) e
  turquesa `#2fb3b3` (Maré) — longe das quatro cores dos lugares —, no chão
  do campo, no disco sob os pés de cada cavaleiro e nas bandeiras. A barra de
  luz é **sempre** a cor do lugar; as luzinhas, **sempre** o número do
  jogador (nada de munição nas luzinhas). Os pontos da equipe vão para os
  dois da dupla (`marcar_equipe`, H08), e a tela diz "A Brasa venceu!".
- A Q2 (pega-bandeira) tem a regra dela para 3, 2 e 1 (sem Aprendiz: um
  boneco não carrega bateria).
- `usa_gatilho = true` no `montar()` de quem usa gatilho (G03: o L2 fica
  livre do item).
- **Os medleys** (Q4, Q5) são os únicos da seção com `"duracao": 0.0`: o fim
  é do próprio jogo (a plataforma, o dragão). Os outros três contam a
  `duracao` em tempo de música (H08).

## Os medleys (Q4, Q5): mini-versões, não o catálogo em modo trecho

Os dois medleys **reimplementam** versões pequenas das mecânicas das outras
seções (as "estações"), dentro do próprio script, num palco só, numa faixa
só, num relógio só. A outra saída — chamar os minigames do catálogo "em modo
trecho" — foi descartada porque:

- cada minigame é uma `Sala` inteira no único lugar de sala do `main.gd`:
  trocar de sala a cada 20 s é cortina, `montar()` do cenário todo, placa de
  som refeita e `Ritmo.tocar()` recomeçando a faixa — a música pararia a cada
  trecho, e o medley é "sem pausa";
- o kit não tem "modo trecho" (sem aviso, sem treino, sem fechamento), e
  acrescentá-lo mexeria nos 45;
- uma estação de 40 a 70 linhas não quebra quando o minigame de origem muda.

O preço é repetir um pouco de regra (bater, inclinar, traçar, defender,
atirar, repetir, sentir, soprar), cada uma no seu menor tamanho.

## A ordem

Q1 primeiro (tira a sala de hoje e põe a seção no catálogo). Depois Q2, Q3,
e os medleys por último: Q4 (S1 a S4) e Q5 (S5 a S8), que dependem do ouvido
da P1 e da pista da O1.

## Os cinco

| ficha | gênero | verbo |
| --- | --- | --- |
| [Q1 — A Prova](Q1-a-prova.md) | 2v2 | "Vença a outra equipe!" |
| [Q2 — Roubo de Bateria](Q2-roubo-de-bateria.md) | 2v2 | "Roube!" |
| [Q3 — Mecha de Dois Pilotos](Q3-mecha-de-dois-pilotos.md) | 2v2 | "Pilote juntos!" |
| [Q4 — Ruge o Reator](Q4-ruge-o-reator.md) | coop (medley) | "Aguentem!" |
| [Q5 — O Último Acorde](Q5-o-ultimo-acorde.md) | coop (medley) | "O acorde final!" |

Os cinco verbos: empurrar a frente, roubar, pilotar em sincronia, aguentar,
fechar o acorde.

## O que o registro mede

- **a carga:** cada `saida` (vibração, gatilho, luz) com `seq` e `ok`, e
  `som_controle`, dos quatro controles ao mesmo tempo; a Q1 conta as recusas
  sob carga (`Forja.carga_*`) para a bancada (`tudo_junto`);
- as `pista` só do controle (o sino da martelada, o pulso da bateria, o
  golpe que vem de um lado) e a resposta a elas;
- os medleys: o desvio de cada estação, por controle — a noite compara, no
  fim da noite, o tempo de cada um em cada recurso com o do começo.

## Ao começar a seção

No [quadro](README.md), troque a linha **Q** pelas cinco linhas (Q1 a Q5),
com o tamanho e a estimativa da tabela acima, e a soma no fim do
quadro.
