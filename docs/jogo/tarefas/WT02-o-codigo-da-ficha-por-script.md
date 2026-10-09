# WT02 — O código da ficha sai por script

**Sprint:** W · **Tamanho:** M · **Depende de:** nada; vale mais antes de um conjunto de minigame entrar em voo
(mexe só nas cercas dos blocos de código das fichas I a Q)

## Por quê

As fichas dos minigames trazem o arquivo inteiro do minigame num bloco de código: 51 blocos `gdscript` de mais de 80
linhas, somando 11.892 linhas, em 43 fichas. Quem pega a ficha copia o bloco à mão para o arquivo, linha por linha,
e quem confere lê o bloco de novo para achar a diferença. Copiar à mão é trabalho mecânico, lento e que erra (uma
tabulação trocada vira erro de análise no Godot). Um script faz isso em um segundo, e o que sobra para a pessoa é o
que pede julgamento: o que mudou na API desde que a ficha foi escrita.

## Ler antes

- [12 — Como trabalhar](../12-como-trabalhar.md) (o passo de fazer uma ficha)

## O estado de hoje (medido em 09/10/2026, `85f24c3`)

- Os blocos são cercas simples, sem dizer para onde vão:
  ```bash
  grep -c '^```gdscript arquivo=' docs/jogo/tarefas/*.md | awk -F: '{s+=$2} END {print s}'   # 0
  ```
- O caminho de destino aparece só na prosa antes do bloco (por exemplo, «o `godot/scripts/salas/marcha.gd`
  inteiro:»), cada ficha de um jeito.
- Não existe script que tire o código de uma ficha nem que compare a ficha com o arquivo.

## O alvo

Cada bloco de arquivo inteiro numa ficha diz para onde vai (` ```gdscript arquivo=godot/scripts/salas/marcha.gd `).
`python3 scripts/ficha_codigo.py <ficha> --escrever` grava os blocos nos arquivos; `--conferir` mostra a diferença
entre os blocos e os arquivos de hoje e sai 1 se diferem. A pessoa lê a diferença, não o bloco.

## Arquivos que mudam

- `scripts/ficha_codigo.py` (novo)
- as fichas `docs/jogo/tarefas/I*.md` a `Q*.md`, só a primeira linha das cercas dos blocos de arquivo inteiro
- `docs/jogo/12-como-trabalhar.md` (o passo novo)
- `tests/prova_dos_portoes.sh` (a mordida do script)

## Passos

1. O script, com três modos: `--marcar` (para cada bloco de mais de 80 linhas, procura o caminho em crase na prosa
   logo acima e propõe o `arquivo=`; só escreve com `--sim`), `--escrever` (grava cada bloco com `arquivo=`; recusa
   caminho fora de `godot/`, `scripts/` e `tests/`) e `--conferir` (diff unificado por arquivo).
2. Rodar o `--marcar` nas fichas I a Q, ler as propostas e gravar. Bloco sem caminho claro fica sem `arquivo=` e vai
   numa lista no relato.
3. O passo no 12: «o código de arquivo inteiro sai por `scripts/ficha_codigo.py --escrever`; depois, leia o diff e
   conserte só o que diverge da API de hoje».
4. A mordida: uma ficha de mentira com um bloco `arquivo=` escreve o arquivo numa pasta temporária; o `--conferir`
   sai 0 sem mudança e 1 com uma linha trocada; um `arquivo=../fora` é recusado.

## Armadilhas

- **Tabulação.** O GDScript da casa usa tabulação: o script grava o bloco byte a byte, sem trocar espaço por
  tabulação nem tirar a linha em branco do fim.
- **Bloco que é trecho, não arquivo.** Só bloco de arquivo inteiro ganha `arquivo=`. Trecho fica como está (o
  `--escrever` não toca arquivo de bloco sem a marca).
- **Ficha em voo**: pular as fichas que um conjunto está fazendo agora, como na [WT01](WT01-o-ler-antes-pela-ancora.md).
- **O markdown renderizado**: a palavra depois da língua da cerca não muda o realce no GitHub nem no leitor do
  repositório; conferir numa ficha antes de marcar todas.

## Não fazer

- Não mudar o código dentro dos blocos.
- Não tirar o código das fichas para arquivos separados: a ficha segue sendo o lugar onde o código se lê.

## Pronto quando

`grep -c '^```gdscript arquivo='` nas fichas I a Q acha os blocos de arquivo inteiro (hoje 0), e
`python3 scripts/ficha_codigo.py docs/jogo/tarefas/I2-marcha-dos-escudeiros.md --escrever` numa árvore limpa grava o
arquivo do minigame que a ficha descreve.

## Provas

- `bash tests/prova_dos_portoes.sh` (a mordida).
- `bash scripts/portoes/rodar.sh`.

## Para o André (local)

Numa árvore à parte, rodar o `--escrever` numa ficha de minigame ainda não feita e abrir o arquivo gerado no editor:
conferir que a tabulação e os acentos chegaram iguais.

## Ao terminar

Pôr a linha da WT02 no [quadro](README.md) como **feito**, com o commit e a lista dos blocos que ficaram sem marca.

## O que foi feito (leva 1, as-regras)

- **Entrou:** `scripts/ficha_codigo.py`, com `--marcar [--sim]`, `--escrever` e `--conferir` (e `--raiz` para a
  árvore). A escrita é byte a byte; caminho fora de `godot/`, `scripts/` e `tests/`, ou com «..», é recusado e nada
  é gravado. **O arquivo não vem num bloco só** (o corpo, a FICHA de «A ficha de dados» e o robô de «O robô» são
  blocos à parte), então a cerca ganhou `parte=N`: os blocos com o mesmo `arquivo=` se juntam pela parte (o sem
  parte é a 1), com uma linha em branco entre eles. A validar por ela: a FICHA cai no fim do arquivo, longe do
  comentário `# (a FICHA vem aqui)` do corpo (o GDScript aceita; quem lê estranha).
- **A medida:** cercas com `arquivo=` nas fichas I a Q, de 0 para 45, que gravam 22 arquivos em 19 fichas: os
  minigames I2 a I5, J1 a J5 e K1 a K5 (o corpo, a FICHA na parte 2 e o robô na 3; na K, a FICHA já está no corpo e
  o robô é a parte 2), os `secao.gd` da I1, da J1 e da K1, os cenários da L1, da M1 e da N1, e o `ouvido.gd` e o
  `cenario_da_voz.gd` da P1. O `--escrever` da I2 numa árvore limpa grava `marcha_dos_escudeiros.gd` com 478 linhas,
  com a tabulação, e o `--conferir` logo depois sai 0. O passo novo está no 12, «O ciclo de uma ficha», passo 4.
- **Ficaram sem marca** (29 blocos de mais de 80 linhas, na [WT02b](WT02b-o-codigo-das-fichas-que-ficaram-sem-marca.md)):
  O1 a O5 e Q1 a Q5 (o corpo traz `const FICHA := { ... }`, que gravado não é GDScript); o minigame da I1 (os
  blocos de `_montar_runa` e `_mostrar_runa` à parte); e L1 a L5, M1 a M5, N1 a N5, P1, P2 e P4 (o arquivo vem em
  pedaços que pedem julgamento).
- **Provas:** `bash tests/prova_dos_portoes.sh`, 55 casos; os seis novos (a escrita byte a byte com a parte 2, o
  `--conferir` igual e com uma linha trocada, `arquivo=../fora.gd`, `arquivo=godot/../../fora.gd` e a pasta de fora)
  reprovam com o script estragado de cinco jeitos (a tabulação trocada, a parte 2 esquecida, o `--conferir` que não
  sai 1, a recusa que grava, o «..» aceito).
- **Para o André:** numa árvore à parte, `python3 scripts/ficha_codigo.py docs/jogo/tarefas/J3-*.md --escrever
  --raiz <uma pasta vazia>` e abrir o arquivo no editor.
