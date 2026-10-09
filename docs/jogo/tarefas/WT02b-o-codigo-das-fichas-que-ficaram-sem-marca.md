# WT02b — O código das fichas que ficaram sem marca

**Sprint:** W · **Tamanho:** M · **Depende de:** WT02; vale mais antes de um conjunto de L, M, N, O, P ou Q entrar
em voo (mexe nas cercas e, onde a ficha pede, no texto das fichas I1 e L a Q)

## Por quê

A [WT02](WT02-o-codigo-da-ficha-por-script.md) marcou com `arquivo=` os arquivos que a ficha monta sem julgamento:
22 arquivos em 19 fichas (os minigames I2 a I5, J1 a J5 e K1 a K5, os `secao.gd` da I1, da J1 e da K1, e os cenários
da L1, da M1, da N1 e da P1). O resto ficou sem marca, porque o arquivo não sai das cercas como estão: o script
juntaria um arquivo que o Godot não analisa, ou um pedaço dele. Quem pega essas fichas segue copiando à mão.

## Ler antes

- [O `scripts/ficha_codigo.py`](../../../scripts/ficha_codigo.py) (os três modos e o `parte=N`, no começo do arquivo)
- [12 — Como trabalhar, «O ciclo de uma ficha»](../12-como-trabalhar.md#o-ciclo-de-uma-ficha)

## O estado de hoje (medido em 09/10/2026, no ramo da WT02)

```bash
python3 scripts/ficha_codigo.py docs/jogo/tarefas/[I-Q][1-5]-*.md --marcar
```

lista 29 blocos de mais de 80 linhas sem marca, em três casos:

- **O1 a O5 e Q1 a Q5** (10 fichas): o corpo traz `const FICHA := { ... }   # a de cima` no lugar da ficha de dados.
  Marcado como está, o arquivo gravado tem `{ ... }`, que não é GDScript.
- **O minigame da I1** (`martelo_de_hefesto.gd`, linha 312, 509 linhas): além do corpo, da FICHA e do robô, a ficha
  traz `_montar_runa` e `_mostrar_runa` em blocos à parte (linhas 829 e 903), e falta decidir onde cada um entra.
- **L1 a L5, M1 a M5, N1 a N5, P1, P2 e P4** (18 blocos): o arquivo vem em pedaços (o cabeçalho, os ganchos como
  trecho, o robô, o cavaleiro, o fim), e o maior bloco não começa por `extends`; o `--marcar` o lista como trecho.
  A P3 e a P5 não têm bloco de mais de 80 linhas.

## O alvo

Cada ficha I a Q cujo arquivo a ficha descreve inteiro grava esse arquivo por `--escrever`, e o arquivo gravado se
analisa no Godot. A ficha que só descreve pedaços diz isso numa linha, e fica sem marca.

## Arquivos que mudam

- as fichas `docs/jogo/tarefas/I1-*.md` e `L*.md` a `Q*.md`
- `scripts/ficha_codigo.py`, só se o caso de O e Q pedir um mecanismo de troca (por exemplo, a parte que substitui
  uma linha marcada, em vez de vir depois)
- `tests/prova_dos_portoes.sh` (a mordida do mecanismo novo, se houver)

## Passos

1. O e Q: decidir entre trocar a linha `const FICHA := { ... }` pela FICHA de verdade dentro do corpo (muda o texto
   da ficha, que a WT02 não podia) ou um mecanismo no script; marcar o corpo, a FICHA e o robô com `parte=N`.
2. I1: pôr `_montar_runa` e `_mostrar_runa` no lugar que a prosa diz e marcar.
3. L a P: ler cada ficha e decidir, por seção, se os pedaços somam o arquivo inteiro. Se somam, marcar com `parte=N`;
   se não, uma linha na ficha dizendo que o arquivo se monta à mão.
4. Para cada ficha marcada: `--escrever` numa árvore à parte e abrir no Godot com `--headless --check-only`.

## Armadilhas

- **A FICHA no fim.** Na WT02, o corpo de I e J traz o comentário `# (a FICHA vem aqui)` e a FICHA cai no fim do
  arquivo, depois do corpo. O GDScript aceita a constante em qualquer lugar da classe, mas quem lê o arquivo gerado
  acha a FICHA longe do comentário. Decidir junto com o caso de O e Q.
- **Ficha em voo:** pular a ficha que um conjunto está fazendo agora.

## Não fazer

- Não mudar a lógica do código dentro dos blocos; só o que é marcador (`{ ... }`, «a de cima»).
- Não tirar o código das fichas para arquivos separados.

## Pronto quando

`python3 scripts/ficha_codigo.py docs/jogo/tarefas/[I-Q][1-5]-*.md --marcar` só lista blocos que a ficha diz, numa
linha, que se montam à mão; e cada arquivo gravado por `--escrever` passa no `--check-only` do Godot.

## Provas

- `bash tests/prova_dos_portoes.sh`.
- `bash scripts/portoes/rodar.sh`.

## Para o André (local)

Numa árvore à parte, `--escrever` na O1 e abrir o arquivo no editor do Godot: a FICHA tem de estar lá, com os dados,
e o editor não pode acusar erro.

## Ao terminar

Pôr a linha da WT02b no [quadro](README.md) como **feito**, com o commit.
