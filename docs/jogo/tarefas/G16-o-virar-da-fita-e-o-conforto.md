# G16 — O virar da fita, o movimento e as reações nas Opções

**Sprint:** G · **Tamanho:** M · **Depende de:** F00, F07, F09, G14

## Por quê

A bíblia propõe três coisas que mudam o jogo e não só a imagem: o intervalo
no meio da noite (a fita vira), a opção "Movimento" no lugar de "Tremor", e
a opção "Reações". Esta ficha leva as três ao jogo.

## Ler antes

- [01 O cinema](../arte/01-cinema.md#o-virar-da-fita) (o virar da fita)
- [10 A acessibilidade](../arte/10-acessibilidade.md#o-movimento-reduzido)
  (o movimento reduzido)
- [09 As reações](../arte/09-reacoes.md#com-o-conforto) (a opção Reações)

## O estado de hoje

- `godot/scripts/opcoes.gd`: `tremor` e `flashes` (bool), gravados em
  `user://opcoes.cfg` na seção `sessao`. O `tremor` só desliga o tremor da
  câmera e o giro do título (`main.gd:913` e `:970`).
- A tela das Opções é `godot/scripts/ui/tela_opcoes.gd`.
- A noite não tem intervalo: as faixas seguem uma depois da outra.

## O alvo

- **O virar da fita:** depois de `ceil(n/2)` faixas, os cinco passos do 01
  (o deck de cima a 50 mm, o giro de 180° em 2 compassos, `fx_virar`, a
  etiqueta "Lado B", o salão com a luz do lado B). Sem tempo limite; qualquer
  jogador segue com "Botão ✕ (Seguir)".
- **Movimento:** `Opcoes.movimento`, 0 Inteiro e 1 Reduzido, no lugar de
  `Opcoes.tremor`. O `opcoes.cfg` antigo com `tremor = false` vira Reduzido.
  O Reduzido faz a tabela inteira do 10 (sem tremor, corte seco no lugar do
  movimento de câmera, sem roll, squash e stretch até 5 %, sem hit-stop,
  confete 40 sem giro, adesivo e carimbo por opacidade em 4 quadros, a fita
  que vira por corte).
- **Reações:** `Opcoes.reacoes`, 0 Todas, 1 Só do jogo, 2 Nenhuma; padrão
  Todas. Até a ficha das reações existir, a linha grava e não muda nada.
- As duas linhas novas nas Opções seguem a voz do texto
  ([06](../arte/06-interface-e-texto.md#o-texto-como-voz)) e entram em
  `traducoes.gd`.

## Passos

1. `Opcoes.movimento` e a migração do `tremor`; a linha nas Opções.
2. Cada item da tabela do 10 lê `Opcoes.movimento`.
3. `Opcoes.reacoes` e a linha.
4. O virar da fita na noite.

## Armadilhas

- O movimento reduzido não muda nenhum julgamento, janela ou ponto: a prova
  do robô dá o mesmo placar nos dois modos com a mesma semente.
- O virar da fita é intervalo: o relógio de áudio para, e a calibração não
  se perde.

## Não fazer

- Não desenhar os adesivos (é uma ficha própria, depois da prancha das
  reações da [PRODUÇÃO](../arte/PRODUCAO.md), item 3).

## Pronto quando

A noite vira a fita na metade; "Movimento: Reduzido" faz a tabela do 10
inteira; "Reações" grava as três escolhas; o `opcoes.cfg` antigo abre sem
erro.

## Provas

- `bash tests/prova_do_jogo.sh` com a mesma semente nos dois modos de
  movimento: o mesmo placar.
- `bash tests/prova_visual.sh`: as Opções nas duas línguas e nas duas
  escalas de texto; o virar da fita.

## Ao terminar

Marcar G16 como **feito** no [quadro](README.md). Commit sugerido:
`feat(noite): a fita vira na metade, e as Opções ganham Movimento e Reações`.
