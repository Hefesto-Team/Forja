# O — S7 — Os Caminhos: os cinco minigames

**Sprint:** O · **Tamanho:** G (cinco fichas) · **Estimativa:** US$ 8,0 (a soma das cinco) · **Depende de:** H04, H08, H07, F01, F09

Esta é a ficha-mãe: o índice. O trabalho anda pelas cinco fichas abaixo, uma
por sessão, na ordem.

## A feature protagonista

A **háptica por áudio**: o chão fala com a mão. No cabo, os dois atuadores
(os canais 3 e 4 da placa de quatro canais do controle) tocam a textura do
material; no rádio não há placa, e a mesma pista vai pelo rumble
(`Forja.sentir`), mais grosseira, com a troca no registro. A pista é
**privada**: só o dono sente, a TV fica calada sobre ela. Coadjuvantes: o som
dos passos no alto-falante do dono, a barra de luz que escurece (na cor do
lugar, nunca abaixo de 30%) nos minigames de terror, o gatilho com peso só em
O5.

## O cenário comum

- Um corredor de pedra da casa: `Kit.arena`, as quatro raias do kit em
  x = −6, −2, 2, 6 (`RAIAS`), o boneco de costas para a câmera, andando para
  o fundo; o mundo desliza sob ele **pela batida** (nunca somando `dt`).
- A luz da casa (doc 11): tocha `#ffb070`, enchimento lilás `#b9b0ff`, névoa
  `#241f33`. O terror (O2, O4) é a **mesma luz, escurecida**: tochas a 0,35,
  enchimento a 0,05, e a lanterna de cada boneco na cor do lugar clareada.
- Os chãos que a mão reconhece são os quatro de hoje — grama, cascalho,
  metal, água (`passo:<chão>:<variação>`, `nativo/som/sons_salas.c`) — porque
  o robô e a bancada já os distinguem (`Forja.chao_do_envelope`, `chao.c`).
  Os outros materiais da H07 (`material:<nome>`) são a textura dos eventos.
- `"papel_som": Forja.PAPEL_HAPTICA` na FICHA (a chave da H08): o kit
  prepara a placa para a háptica no `entrar()`, e o aviso deixa cada um
  testar a sua (△).
- As linhas `pista` e `troca` do [13](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08)
  (a `troca` com `de` e `para`: `haptica` → `rumble`), e o mesmo `_pista()`
  nas cinco.

## A ordem

O1 primeiro (tira a sala de hoje e põe a seção no catálogo). Depois O2, O3,
O4, O5, uma por sessão.

## Os cinco

| ficha | gênero | verbo | estimativa |
| --- | --- | --- | --- |
| [O1 — Os Caminhos](O1-os-caminhos.md) | corrida | "Sinta o chão!" | US$ 2,0 |
| [O2 — Neblina de Dados](O2-neblina-de-dados.md) | terror | "Salte no firme!" | US$ 1,5 |
| [O3 — Passo no Fosso](O3-passo-no-fosso.md) | corrida | "Pise no contratempo!" | US$ 1,5 |
| [O4 — Fuga do Mecha Cego](O4-fuga-do-mecha-cego.md) | sobrevivência | "Esconda-se!" | US$ 1,5 |
| [O5 — Engrenagens Sincopadas](O5-engrenagens-sincopadas.md) | 2v2 | "Encaixe!" | US$ 1,5 |

Os cinco verbos: escolher a trilha, saltar, pisar no contratempo, esconder-se,
encaixar.

## O que o registro mede

Por baixo, sem perguntar nada a ninguém:

- cada textura mandada aos atuadores (`som_controle`, papel `haptica`, com
  `placa`), e cada pista com o caminho que tomou (`pista`, `canal` =
  `haptica`/`rumble`);
- a troca para o rumble quando o lugar não tem placa (`troca`, `de`
  `haptica`, `para` `rumble`, motivo `sem_placa`) ou só tem um canal
  (`sem_estereo`, em O4);
- a resposta a cada pista (a `entrada` `resposta`: `certo`, `errado`,
  `nenhuma`) — a antiga pergunta "que chão é esse?" agora é o caminho que o
  jogador toma;
- o tempo de cada resposta (`nota` e `toque`, do kit).

O cruzamento da noite (ficha [S](S-a-noite-de-seis-horas.md)) compara, por
controle e por transporte, os acertos depois de uma pista na háptica com os
acertos depois de uma pista no rumble.

## Ao começar a seção

No [quadro](README.md), troque a linha **O** pelas cinco linhas (O1 a O5),
com o tamanho e a estimativa da tabela acima, e a soma no fim do
quadro.
