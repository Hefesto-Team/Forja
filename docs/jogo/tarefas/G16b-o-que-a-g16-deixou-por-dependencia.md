# G16b — O que a G16 deixou por dependência

**Sprint:** G · **Tamanho:** P · **Depende de:** G01 (`Desenho.caixa`, `Desenho.cassete`), G05, G11 (`Desenho.etiqueta`,
`Desenho.dica`, `Som.ui`), G12 (`partida.lado()`, a cortina)

## Por quê

A [G16](G16-o-virar-da-fita-e-o-conforto.md) entrou na leva 1 sem a G01, a G11 e a G12 no chão. Ela fez o núcleo (o virar
de 4000 ms, o intervalo, o lado B na luz, Movimento, Reações, a lista que desliza) com peças provisórias. Esta ficha
troca as provisórias pelas de verdade, quando as donas existirem, e fecha os itens da tabela do
[10](../arte/10-acessibilidade.md#o-movimento-reduzido) que ainda não têm onde morar.

## O estado de hoje

- `godot/scripts/ui/tela_virar.gd` desenha o deck, o cassete e a etiqueta à mão (`_cassete`, `_etiqueta`), porque
  `Desenho.caixa`, `Desenho.cassete` e `Desenho.etiqueta` não existem. A etiqueta do lado B leva a tarja dupla
  desenhada ali mesmo, e a dica do intervalo vem de `Glifo.dica` numa placa própria (`Desenho.dica` não existe).
- `Partida.lado()`, `Partida.metade()` e `Partida.virou` são os mínimos da G16. A G12 também faz `lado()`: no encontro
  das duas, vale a da G12 e a `metade()` continua (`ceili(salas.size() / 2.0)`).
- O ✕ do intervalo toca `Som.tocar("confirma")` (não há `Som.ui`), e as linhas Movimento e Reações das Opções trocam
  sem som e sem `Forja.sentir(quem, "toque")`.
- As chamadas de `Desenho.etiqueta` da noite (a etiqueta de seção das salas) não passam `lado_b`: só a luz e o intervalo
  mudam no lado B.
- Itens da tabela do 10 sem dona pronta: push-in, órbita e travelling (G01, G05), o roll da Dissonância (Q5), o
  esmagar e esticar do boneco e dos minigames (`Opcoes.esmagar`), o hit-stop (`Opcoes.parada`; hoje nenhum arquivo
  escreve `speed_scale = 0.0`), o corpo que abaixa no tempo (G08), a tela que treme na cortina (G12), o adesivo e o
  carimbo (a ficha das reações).
- A prova visual não tem as Opções com 11 linhas (1,0× e 1,15×, em português e em inglês, a linha Idioma à vista), os
  quadros do virar (0, 720, 1380 e 2400 ms, no Inteiro e no Reduzido) nem o intervalo.

## O que fazer

1. Quando a G01 e a G11 existirem, trocar o desenho à mão de `tela_virar.gd` por `Desenho.cassete`, `Desenho.caixa`,
   `Desenho.etiqueta(..., lado_b)` e `Desenho.dica`, sem mudar as posições da ficha G16.
2. Na G11, `Som.ui(l, "ui_confirma")` no ✕ do intervalo, e `Som.ui(quem, "ui_tique")` mais
   `Forja.sentir(quem, "toque")` nas linhas novas das Opções.
3. Em toda chamada de `Desenho.etiqueta` da noite, passar `lado_b = partida != null and partida.lado() == "B"`.
4. Para cada item da tabela do 10 acima cuja dona já esteja feita, pôr a leitura de `Opcoes.reduzido()`,
   `Opcoes.parada(...)` ou `Opcoes.esmagar(...)` no lugar exato e citar arquivo e linha no commit.
5. Pôr no `prova_visual.sh` as telas das Opções (11 linhas, duas escalas, duas línguas) e os quadros do virar e do
   intervalo.

## Pronto quando

- Nenhum desenho de cassete, etiqueta ou dica mora fora do `Desenho`.
- Mexer em Movimento ou Reações toca `ui_tique` e vibra `toque` no lugar de quem mexeu.
- `bash tests/prova_visual.sh` mostra as Opções e o virar nos quadros acima, sem achado novo.
- Cada item da tabela do 10 com dona pronta tem a leitura de `Opcoes.reduzido()` (a leitura dos scripts da prova do
  jogo confere o `speed_scale = 0.0`).

## Provas

- `bash tests/prova_do_jogo.sh` (as checagens da G16 seguem verdes).
- `bash tests/prova_visual.sh` e `bash scripts/portoes/rodar.sh`.
