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
