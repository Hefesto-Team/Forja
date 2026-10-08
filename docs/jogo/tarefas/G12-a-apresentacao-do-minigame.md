# G12 — A apresentação do minigame

**Sprint:** G · **Tamanho:** M · **Depende de:** H04 (o aviso mora no kit), H06 (o `JIN_ENTRADA`), G08 (o boneco e o gesto), G11 (os prompts do UI Pack), F07 (a voz), F09 (a prova visual)

## Por quê

Entre um minigame e outro, quem joga precisa saber em três segundos o nome do
jogo e o que fazer com as mãos, como no Mario Party (o cartão de instruções,
com treino e "pronto" de cada um) e no WarioWare (o verbo gigante, de uma
palavra, que entra com estrondo). Pedido dela, 08/10/2026.

## Ler antes

- [06 — as telas](../06-telas-e-fluxo.md#as-telas), a linha **aviso do minigame**
- [O molde de minigame](molde-de-minigame.md), as chaves `verbo`, `icone`, `gesto`, `treino`
- [H04 — o kit](H04-o-kit-do-minigame.md), o que o kit faz com o aviso

## O estado de hoje

O aviso do minigame (`SalaJogo._aviso()` e `_quadro_aviso()`, em
`godot/scripts/salas/sala_jogo.gd`) mostra o título, o verbo, o ícone da
parte do controle e o gênero, com dez segundos de treino que não valem ponto;
pela F03, começa sozinho em `AVISO_MAX` (8 s) ou antes, se todos apertarem ✕.
Ele aparece de uma vez, sem transição, e não diz como se joga: o ícone mostra a
parte do controle, mas não o que fazer com ela. Meça de novo na hora de
começar: a F03, a H04 e a G11 mexem nesse trecho antes desta ficha.

## O alvo

Dois tempos, os dois no kit (nenhum minigame desenha a apresentação dele):

1. **A entrada, no estilo WarioWare (cerca de 1,5 s):** a tela do minigame
   anterior (ou do salão) é cortada por uma cortina na cor da seção, e o verbo
   de uma palavra entra grande, no centro, no tempo do `JIN_ENTRADA`
   ("Martele!", "Equilibre!", "Cante!"). O controle de cada um dá um toque
   (`aviso`, do F05). Qualquer botão não pula a entrada: ela é curta de
   propósito.
2. **O cartão, no estilo Mario Party:** o título do minigame, o gênero
   ("Todos contra todos", "Dupla", "Um contra três"), o boneco fazendo o
   `gesto` e o bloco **Como jogar**: de uma a três linhas, cada uma com o
   prompt do botão ou da parte do controle (o glifo do UI Pack) e o verbo
   ("✕ Martelar", "Inclinar o controle: Equilibrar", "L2: Soprar o fole").
   Embaixo, o treino que já existe e um chip por lugar que vira "Pronto" no
   ✕. Começa quando todos estão prontos ou em `AVISO_MAX`, como hoje.

A ficha de dados de cada minigame ganha a chave **`como_jogar`**: uma lista
de pares `[glifo, verbo]`, de uma a três linhas. Minigame sem ela reprova na
prova do kit; os 45 a preenchem nas fichas I a Q.

## Arquivos que mudam

- `godot/scripts/salas/sala_jogo.gd`: a entrada e o cartão no lugar do `_aviso()` de hoje
- `godot/scripts/minigames/minigame.gd` e `godot/scripts/minigames/catalogo.gd`: a chave `como_jogar`
- `godot/scripts/traducoes.gd`: os verbos e os rótulos novos, nas duas línguas
- `docs/jogo/tarefas/molde-de-minigame.md`: a chave `como_jogar` na tabela
- `docs/jogo/06-telas-e-fluxo.md`: a linha do aviso do minigame
- `godot/testes/prova_do_jogo.gd` e a prova visual: as réguas abaixo

## Passos

1. Medir o aviso de hoje: o que se desenha, em que fase, quanto dura.
2. A chave `como_jogar` no molde, no `minigame.gd` e no catálogo, com a
   recusa do minigame que não a tem; preencher a do minigame de prova e a da
   `S01_J01`.
3. A entrada: a cortina na cor da seção, o verbo grande no tempo do
   `JIN_ENTRADA`, o toque no controle de cada lugar.
4. O cartão: o título, o gênero, o boneco no gesto, o bloco Como jogar com os
   prompts do UI Pack, o treino e os chips "Pronto".
5. As traduções, pela voz da F07; o `scripts/check_texto_de_tela.py` passa.
6. As réguas: a entrada dura o que diz; o cartão mostra cada linha do
   `como_jogar`; minigame sem a chave reprova; a prova visual não acha
   colisão em nenhuma escala nem língua, de 1 a 4 jogadores.

## Armadilhas

- A apresentação não pode atrasar a partida: a entrada é curta e o cartão
  mantém o `AVISO_MAX` da F03.
- Texto de tela sem metalinguagem: "Como jogar" fala do mundo ("Martelar"),
  nunca do teste ("aperte para provar o gatilho").
- O prompt é o glifo do UI Pack (G11), não letra solta.

## Não fazer

- Não pôr a apresentação em cada minigame: é do kit.
- Não criar tela de pular: o cartão já começa sozinho.

## Pronto quando

Todo minigame do kit entra pelo verbo gigante e mostra o cartão com o título,
o gênero, o boneco e o Como jogar da ficha de dados dele; minigame sem
`como_jogar` reprova; e a prova visual passa em todas as escalas e línguas.

## Provas

- Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.
- Com ela: jogar dois minigames seguidos e dizer se a entrada e o cartão têm
  o ritmo certo (nem longos, nem apressados).
