# G12b — A faixa no tempo 1 e a prancha da entrada

**Sprint:** G · **Tamanho:** P · **Depende de:** G12 (a cortina e o J-card), H06 (a contagem de entrada), F09 (a prova
visual)

## Por quê

A [G12](G12-a-apresentacao-do-minigame.md) entrou com a cortina, o verbo no tempo 1 e o J-card, provados na prova do
jogo. Três partes da ficha ficaram de fora por tocarem em código de outra frente (o começo da faixa e o apito) ou em
provas grandes (a prancha e a matriz da prova visual).

## Ler antes

- [G12, o som e a diversão](G12-a-apresentacao-do-minigame.md#o-som)
- [O kit do minigame, no 13](../13-arquitetura.md#o-kit-do-minigame--h04) (a contagem de entrada da H06)

## O estado de hoje

- A faixa do minigame começa em `comecar()` (`godot/scripts/minigames/minigame.gd`), com a contagem da H06
  (`_contar_a_entrada`, os tempos 0 a 2 da faixa e o vai no 3). A G12 pede que ela comece em `T`, o tempo 1 do
  impacto, com o vai do `jin_entrada_vai` sendo o tempo 1 dela. Hoje há duas contagens: a da cortina (`T` − 3 a
  `T` − 1, no relógio do sistema) e a da H06, no começo da faixa.
- O apito do começo (`_som_do_comeco`) ainda é o da H06; a G12 pede `ui_confirma` a −12 dB no tempo 1 depois do J-card
  sair.
- Não existe `godot/testes/prancha_da_entrada.gd` nem `docs/imagens/jogo/entrada.jpg`.
- A prova visual não tem a matriz do J-card: 1,0× e 1,15×, pt-BR e en, 1, 2, 3 e 4 jogadores.

## O que fazer

1. A faixa do minigame entra em `T` (`Ritmo.tocar` com o `primeiro_tempo` no impacto), e a contagem da H06 sai do
   `comecar()`; `BATIDA_DA_PRIMEIRA_NOTA` passa a contar do tempo 1 depois do J-card sair.
2. `_som_do_comeco` do kit toca `Som.tocar("ui_confirma", null, -12.0)` no tempo 1 depois do J-card sair.
3. `godot/testes/prancha_da_entrada.gd` (xvfb, `--audio-driver Dummy`): `docs/imagens/jogo/entrada.jpg`, 1920×1620,
   seis quadros de 960×540 (0, 300, 600, 680 e 900 ms e o J-card parado), o instante embaixo em VT323 30.
4. Na prova visual, o J-card parado nas duas escalas, nas duas línguas, com 1 a 4 jogadores.

## Pronto quando

A faixa do minigame começa no impacto, o apito cai no tempo 1 depois do J-card, a prancha da entrada existe ao lado do
`18_cortina.jpg` e a prova visual passa no J-card em toda a matriz.

## Provas

- `bash tests/prova_do_jogo.sh`: as checagens da H06 (o `JIN_ENTRADA` no tempo da faixa) passam a medir a partir de
  `T`, e as da G12 seguem verdes.
- `bash tests/prova_visual.sh` com as partidas 3 a 6.

## Armadilhas

- **A prova da H06** espera o tique nos tempos 0 a 2 da faixa: com a faixa em `T`, os tempos mudam de lugar.
- **O J-card com 3 linhas de Como jogar a 1,15×:** a altura das linhas se ajusta entre 64 e 80 px para os chips não
  subirem. Confira na prancha.

## Não fazer

- Não mudar a cortina nem o J-card: o desenho é da G12.

## Ao terminar

Commit sugerido: `feat(kit): a faixa do minigame entra no tempo 1 do verbo e a prancha da entrada`.
