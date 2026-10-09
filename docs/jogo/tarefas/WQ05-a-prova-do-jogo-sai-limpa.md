# WQ05 — A prova do jogo sai limpa

**Sprint:** W · **Tamanho:** M · **Depende de:** [WQ01](WQ01-os-erros-do-motor-reprovam.md) (o `caixa_julgar` e a
lista `tests/erros_esperados.txt`, de onde três linhas saem)

Nasceu da WQ01: o resto que não coube nela.

## Por quê

A WQ01 fez o erro do motor reprovar a prova. Na prova de poucos o fim saía sujo só pelo som que ainda tocava, e
calar os tocadores antes do `quit` bastou. Na prova do jogo, não: o motor acusa no fim do processo centenas de
objetos e recursos vivos, e a WQ01 teve de pôr três expressões de «na saída» na lista dos esperados, com o motivo.
Essas três linhas valem para toda prova: enquanto estiverem lá, um vazamento novo no fim de qualquer prova (o som que
volta a tocar no `quit`, por exemplo) passa verde.

## Ler antes

- [WQ01 — Os erros do motor reprovam a prova](WQ01-os-erros-do-motor-reprovam.md)
- `tests/erros_esperados.txt` (as três linhas da saída e o motivo)

## O estado de hoje (medido em 09/10/2026, na árvore da WQ01)

- Uma rodada «antes» da prova do jogo com `--verbose` (o `godot/testes/prova_do_jogo.gd` já cala os tocadores antes
  do `quit`):
  ```text
  WARNING: 775 ObjectDB instances were leaked at exit
  ERROR: 515 RID allocations of type 'PN18TextServerAdvanced22ShapedTextDataAdvancedE' were leaked at exit.
  ERROR: 94 RID allocations of type 'PN13RendererDummy14TextureStorage12DummyTextureE' were leaked at exit.
  ERROR: 57 resources still in use at exit.
  ```
  e mais quatro linhas de RID (malha, material, shader e fonte), e o `Pages in use exist at exit in PagedAllocator`.
- Os objetos vivos, pela lista do `--verbose`: 333 `TextLine`, 210 `Image`, 92 `ImageTexture`, 41 `TextParagraph`,
  22 `ArrayMesh`, 10 `PackedScene`, 9 `StandardMaterial3D`, 8 `FontVariation`.
- Os recursos ainda em uso: os scripts com cache estático (`scripts/tema.gd`, `scripts/ui/desenho.gd`,
  `scripts/mundo/kit.gd`, `scripts/traducoes.gd`, `scripts/opcoes.gd`, `scripts/partida.gd`,
  `scripts/ui/glifo.gd`), as duas fontes e os `.glb` do kit Kenney.
- `print_orphan_nodes()` logo antes do `quit` não lista nenhum nó: não é nó tirado da árvore sem `free`.
- Os caches estáticos: `Kit._cenas` (`scripts/mundo/kit.gd:8`), `Tema._fontes`, `_tema` e `_borda`
  (`scripts/tema.gd:57-152`), `MapaDoControle._texturas`, `_camadas` e `_pecas` (`scripts/ui/mapa_controle.gd:27-29`),
  `Desenho._glifos`, `_coletados`, `_desenhos` e `_cabe` (`scripts/ui/desenho.gd:20-152`).
- A prova de poucos, que também abre o `main.tscn`, sai sem nenhum `ERROR:` depois que cala os tocadores.

## O alvo

A prova do jogo sai sem nenhum `ERROR:` de «na saída», e as três linhas saem de `tests/erros_esperados.txt`.

## Arquivos que mudam

- `godot/testes/prova_do_jogo.gd` (o que solta antes do `quit`), ou os scripts dos caches, se a causa for do jogo
- `tests/erros_esperados.txt` (as três linhas saem)

## Passos

1. Achar quem segura os 333 `TextLine` e as 210 `Image`: rodar a prova com `--verbose` cortando as partes
   (`_prova_das_frases`, `_prova_do_catalogo`, o `Desenho._coletar = "memoria"`) até o número cair.
2. Se for cache estático, soltar antes do `quit`. Se o jogo de verdade também sair sujo (o `main.gd`), a cura é do
   jogo, e a prova de poucos (que não acusa nada) diz se o caminho do jogo está limpo.
3. Tirar as três linhas da lista e rodar a prova do jogo, a de poucos, a da bancada e o gauntlet.

## Armadilhas

- **Não confundir com o som:** o `resources still in use` também é o que o som tocando no `quit` deixa; o
  `--verbose` diz qual é.
- **A prova do kit** mede no relógio de parede e reprova com a máquina carregada (a
  [WE02](WE02-o-kit-no-relogio-do-quadro.md)): um vermelho do kit não é desta ficha.

## Não fazer

- Não esvaziar o cache no meio do jogo para a prova passar.
- Não deixar as três linhas na lista depois da cura.

## Pronto quando

`tests/erros_esperados.txt` só tem os erros de propósito, e a prova do jogo, a de poucos, a da bancada e o gauntlet
passam com ela.

## Provas

- `bash tests/prova_do_jogo.sh`, `bash tests/prova_de_poucos.sh`, `bash tests/prova_da_bancada.sh` e
  `scripts/gauntlet.sh`, pela caixa e pelo semáforo da máquina.

## Para o André (local)

Nada além das provas: o fim do processo não se vê na tela.

## Ao terminar

Pôr a linha da WQ05 no [quadro](README.md) como **feito**, com o commit.
