# WQ04 — O registro fica quando a prova reprova

**Sprint:** W · **Tamanho:** P · **Depende de:** [WE01](WE01-a-caixa-unica.md) (o `tests/caixa.sh` vira o dono da
pasta temporária e do `trap`)

Achado por dois estudos (o QA jogando e o custo de leitura): é a mesma causa.

## Por quê

Toda prova pesada apaga a pasta temporária na saída, com verde ou com vermelho. Quando reprova, sobra na tela só o
que casa com «FAIL», e o registro inteiro do Godot (a linha do tempo, os erros do motor e os relatórios por rodada)
some. Para ler a causa, é preciso rodar de novo uma prova de 4 a 20 minutos, na fila do semáforo, ou abrir o Godot
à mão, que é o caminho que a regra do controle proíbe. Se a prova acaba por tempo (`timeout`, rc 124), sobra uma
linha só: «FAIL a prova com o servidor «forma-a» (rc=124)». Foi assim que o salto de 1,7 s do relógio da música e os
14 «Lambda capture» só apareceram numa cópia da prova sem o `trap`.

## Ler antes

- [WE01 — A caixa única das provas](WE01-a-caixa-unica.md)

## O estado de hoje (medido em 09/10/2026, `85f24c3`)

- `tests/prova_do_jogo.sh:21-22`:
  ```bash
  TMP="$(mktemp -d /tmp/forja-prova-do-jogo-XXXXXX)"
  trap 'rm -rf "$TMP"' EXIT
  ```
  e `:80-81`, o que sobra na tela (`grep -E "…|FAIL|SCRIPT ERROR|prova do jogo ok"`).
- O mesmo `trap` em `tests/prova_de_poucos.sh:19`, `tests/prova_da_bancada.sh:16`, `tests/prova_do_som.sh:11`,
  `tests/prova_da_exportacao.sh:31` e `scripts/gauntlet.sh:29`. A `tests/prova_visual.sh:46` só guarda a prancha quando recebe uma pasta.
- O `.cache/` já está no `.gitignore` (`:6`).

## O alvo

No vermelho, a pasta da rodada é copiada para `.cache/provas/<prova>-<AAAAMMDD-HHMMSS>/`, e a última coisa na tela é
«o registro: <caminho>» e as últimas 20 linhas do registro que reprovou. No verde, apaga como hoje. A saída curta do
verde não muda.

## Arquivos que mudam

- `tests/caixa.sh` (da WE01): a pasta temporária e o `trap`, uma vez
- `tests/prova_do_jogo.sh`, `tests/prova_de_poucos.sh`, `tests/prova_da_bancada.sh`, `tests/prova_do_som.sh`,
  `tests/prova_da_exportacao.sh`, `scripts/gauntlet.sh` (trocam o bloco próprio pelo da caixa)
- `tests/prova_dos_portoes.sh` (a mordida)

## Passos

1. No `tests/caixa.sh`, `caixa_pasta <nome>`: cria a pasta temporária e põe o `trap` que olha o código de saída.
   Diferente de 0, copia a pasta para `$RAIZ/.cache/provas/<nome>-<data>/`, imprime o caminho e as últimas 20 linhas
   do maior registro da pasta; igual a 0, apaga.
2. Guardar só as cinco pastas mais novas de cada prova em `.cache/provas/`, para não encher o disco.
3. As provas e o gauntlet trocam o `mktemp` e o `trap` próprios pelo `caixa_pasta`.
4. A mordida: rodar a prova do jogo com um `GODOT` de mentira que sai com 124 sem imprimir nada. Hoje sai 1, imprime
   uma linha, e não sobra arquivo; depois, sai 1, imprime o caminho, e a pasta existe. Com um `GODOT` de mentira que
   sai 0, a pasta não fica.

## Armadilhas

- **O código de saída dentro do `trap`** é o do script: capture `$?` na primeira linha do `trap`, antes de qualquer
  comando.
- **A prova visual** já guarda o que importa quando recebe a pasta: não mude o comportamento dela com pasta.
- **A CI** não precisa da cópia (o runner morre), mas não faz mal; o caminho impresso basta para o log.

## Não fazer

- Não mudar o que cada prova confere nem o filtro do verde.
- Não guardar no `/tmp` (some no reinício) nem fora do `.cache/`.

## Pronto quando

A mordida do passo 4 passa, e uma prova vermelha de verdade deixa a pasta em `.cache/provas/` com o caminho na última
linha da saída.

## Provas

- `bash tests/prova_dos_portoes.sh`.
- `bash tests/prova_de_poucos.sh` verde não deixa pasta nova em `.cache/provas/`.

## Para o André (local)

Forçar uma falha (por exemplo, trocar o `ESPERADO` da rodada «antes» de `tests/prova_do_jogo.sh`), rodar, abrir o
caminho impresso e achar o registro; desfazer.

## Ao terminar

Pôr a linha da WQ04 no [quadro](README.md) como **feito**, com o commit, e dizer no documento das provas onde o
registro de uma prova vermelha fica.

## O que foi feito (leva 1, a-caixa)

- **`tests/caixa.sh`, `caixa_pasta <nome>`:** cria a pasta temporária (`/tmp/forja-<nome>-XXXXXX`, em `CAIXA_PASTA`)
  e põe o `trap` da saída, que pega o `$?` antes de qualquer comando. Saída 0: apaga a pasta, como antes. Outra
  saída: copia a pasta para `.cache/provas/<nome>-<AAAAMMDD-HHMMSS>/`, apaga as mais velhas da mesma prova até
  sobrarem cinco, mostra as últimas 20 linhas do maior registro (`*.log`) não vazio e termina com
  «o registro: <caminho>». O código de saída da prova não muda.
- **As provas:** `tests/prova_do_jogo.sh`, `tests/prova_de_poucos.sh`, `tests/prova_da_bancada.sh`,
  `tests/prova_do_som.sh`, `tests/prova_da_exportacao.sh` e `scripts/gauntlet.sh` trocaram o `mktemp` e o `trap`
  próprios pelo `caixa_pasta`. Na exportação, a pasta nasce depois da conferência do binário (o «sem forja.x86_64» sai
  2 sem deixar pasta). A prova visual não mudou. O que cada prova confere e o filtro do verde também não.
- **`tests/prova_dos_portoes.sh`:** a mordida do passo 4, com a `tests/prova_do_jogo.sh` de verdade numa árvore de
  mentira e um `GODOT` de mentira (seis casos): com rc 124 a prova sai 1, a pasta fica com o `forma-a.log` e o
  `antes.log`, a última linha é «o registro: <caminho>» e o caminho existe, e das seis pastas velhas e a nova ficam
  só as cinco mais novas; com rc 0 a prova sai 0 e a pasta não fica.
- **`docs/jogo/revisao/WE-mapa.md`:** onde fica o registro de uma prova vermelha.

**Provas:**

- A mordida: com o `trap` apagando sempre (o de antes), 3 dos 60 casos da prova dos portões reprovam (a pasta, a
  última linha e as cinco); com o `trap` guardando sempre, reprova o caso do verde. De volta, «60 casos» ok.
- A saída vermelha, na árvore de mentira:
  ```text
  FAIL a prova com o servidor «forma-a» (rc=124)
  FAIL a prova com o servidor «antes» (rc=124)
  o registro: /tmp/acx/wq04-arvore/.cache/provas/prova-do-jogo-20261009-190245
  ```
- Uma prova vermelha de verdade, sem querer: a `tests/prova_do_som.sh` (na caixa) sem o `bin/forja-send` compilado
  saiu 1 com «GUARDA: a mesa de mentira não montou», e a última linha foi
  «o registro: …/.cache/provas/prova-do-som-20261009-190313», com a pasta lá. Com o binário, «prova do som ok» e
  nenhuma pasta nova.
- `bash tests/prova_de_poucos.sh` verde (pela caixa e pelo semáforo, carga 5 a 3): nenhuma pasta nova em
  `.cache/provas/`.

**Fica para a mão (o André):** forçar uma falha (por exemplo, trocar o `ESPERADO` da rodada «antes» de
`tests/prova_do_jogo.sh`), rodar, abrir o caminho impresso e achar o registro; desfazer.
