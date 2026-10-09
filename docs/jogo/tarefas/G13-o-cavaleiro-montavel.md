# G13 — O cavaleiro montável

**Sprint:** G · **Tamanho:** G · **Depende de:** F00, F07, F09, G02, G10, G14

## Por quê

Hoje cada pessoa escolhe um de dois bonecos e um item. A bíblia decidiu que
cada pessoa monta o cavaleiro com três peças de personagens diferentes e uma
arma ou um amuleto, e dá o nome. Esta ficha faz o corte das peças, a
montagem no mesmo esqueleto e a tela de montagem.

## Ler antes

- [04 O cavaleiro montável](../arte/04-o-cavaleiro.md) (o corte, os perfis,
  a tela de montagem, a forja, o nome)
- [06b A construção do cavaleiro](../06b-a-construcao-do-cavaleiro.md)
- Os stats, os perfis, os itens e os nomes em dado:
  `docs/jogo/sistemas/` (do designer de sistemas)

## O estado de hoje

- `godot/scripts/player.gd:14`: `MODELOS := ["character-human",
  "character-orc"]`, carregados de `res://assets/kenney/`; o item vem do
  mesmo lugar (`player.gd:147`).
- `godot/scripts/partida.gd:26`: os `NOMES`.
- A tela é a do lobby da G02 (`ui/tela_lobby.gd`, `main.gd:586-642`).
- Os 12 personagens do Mini Characters estão em `oficina/kenney/`
  (`python3 scripts/kenney.py onde "Mini Characters"`); o estudo tem 4 em
  `godot/estudos/direcao/kenney/mini-characters/`.

## O alvo

- **O corte**, uma vez, por script: `scripts/cortar_pecas.gd` (headless) lê
  os 12 glb e grava três malhas por personagem (cabeça, tronco superior,
  tronco inferior) em `godot/assets/kenney/mini-characters/pecas/`, pelo osso
  de cada triângulo, como no [04](../arte/04-o-cavaleiro.md#o-corte). Ele
  imprime a contagem de triângulos de cada parte.
- **A montagem:** um `Skeleton3D` do Mini Characters com as três malhas
  escolhidas e o item no osso da mão; as 32 animações servem a todas.
- **A tela:** a de [04](../arte/04-o-cavaleiro.md#a-tela-de-montagem):
  quatro colunas de 432 px, as cinco linhas, os quatro VUs, os botões da
  tabela, a forja de 8 marteladas na batida (que é também a calibração da
  G02), e o nome.
- **Os stats** saem dos CSV de `docs/jogo/sistemas/`, copiados para
  `godot/dados/` por script; o jogo não escreve número de stat no código.
- A cor segue a 02 pelo `Tema` (a G14); a cadeira de rodas é uma escolha do
  tronco inferior (R1), com os mesmos pontos.

## Passos

1. Copiar os 12 personagens com a `License.txt` (o script da G10).
2. O corte e a contagem.
3. A montagem e as animações na batida
   ([05](../arte/05-movimento.md#as-animações-da-kenney-na-batida)).
4. A tela de montagem no lugar do seletor do lobby.
5. A forja, ligada à calibração da G02.
6. Os stats pelos CSV.

## Armadilhas

- O corte é por osso, e nenhum triângulo da `body-mesh` é misto. Se um
  personagem novo tiver triângulo misto, o script para e diz qual.
- A G02 e a G03 descrevem passos e itens que esta ficha muda: o que vale é o
  04 e o 06b.

## Não fazer

- Não decidir número de stat: é do designer de sistemas e dela.
- Não fazer o acabamento nem os acessórios (são da coleção, G06).

## Pronto quando

Os quatro montam um cavaleiro de três personagens diferentes, a forja cai
nas 8 batidas e calibra, o nome vai na etiqueta, e a tela bate com o
`10_montagem.jpg` ([PRODUÇÃO](../arte/PRODUCAO.md), item 1).

## Provas

- `bash tests/prova_do_jogo.sh`: o robô monta os quatro e forja.
- `bash tests/prova_visual.sh`: a tela de montagem ao lado do
  `10_montagem.jpg`.
- O corte: a contagem de triângulos impressa bate com a tabela do 04.

## Ao terminar

Marcar G13 como **feito** no [quadro](README.md). Commit sugerido:
`feat(montagem): o cavaleiro montado com três peças e forjado na batida`.
