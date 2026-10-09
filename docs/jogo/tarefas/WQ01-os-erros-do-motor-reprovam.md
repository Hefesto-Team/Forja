# WQ01 — Os erros do motor reprovam a prova

**Sprint:** W · **Tamanho:** M · **Depende de:** [WE01](WE01-a-caixa-unica.md) (o `tests/caixa.sh`, onde o critério
mora) e [WQ02](WQ02-o-x-do-robo-nao-cai-na-tela-seguinte.md) (sem ela, a prova fica vermelha no dia em que esta
entrar)

## Por quê

A prova do jogo e a prova de poucos só reprovam pelo código de saída do Godot, e o Godot sai com 0 quando um erro do
motor ou de script acontece no meio da rodada: a função que errou para, o jogo segue, e a prova sai verde. Nos
registros de hoje há 14 «ERROR: Lambda capture at index 0 was freed» (o defeito da WQ02), e nenhuma prova os
viu. A prova da bancada já reprova por «SCRIPT ERROR»; as outras duas, não. Com 45 minigames a caminho, um erro que
derruba metade de uma sala passa verde.

## Ler antes

- [WE01 — A caixa única das provas](WE01-a-caixa-unica.md)
- [WE — o mapa da esteira e das provas](../revisao/WE-mapa.md)

## O estado de hoje (medido em 09/10/2026, `85f24c3`)

- `tests/prova_do_jogo.sh:80-81`, o critério:
  ```bash
  grep -E "alto-falante do sistema|FAIL|SCRIPT ERROR|prova do jogo ok" "$TMP/$nome.log"
  [ "$rc" -eq 0 ] || { echo "FAIL a prova com o servidor «$nome» (rc=$rc)"; FALHAS=$((FALHAS + 1)); }
  ```
  O «SCRIPT ERROR» é mostrado, não reprova.
- `tests/prova_de_poucos.sh:38-39`: o mesmo, só pelo `rc`.
- `tests/prova_da_bancada.sh:42`: `if [ "$rc" -ne 0 ] || grep -q "SCRIPT ERROR" "$TMP/$nome.log"` (o único que
  reprova pelo texto).
- Os registros da rodada de 09/10 (prova do jogo, semente 7, módulo da fonte do topo): 7 «Lambda capture» em cada
  rodada (`forma-a` e `antes`), em grupos de 3 e 4, sem nenhum FAIL a mais.
- Os erros de propósito: `godot/testes/prova_do_jogo.gd:426-432` (a FICHA sem «faixa» e o gênero
  `genero_que_nao_existe`, que o `conferir_a_ficha` acusa).

## O alvo

Toda prova que abre o Godot reprova por qualquer linha de erro do motor ou de script que não esteja numa lista curta
de esperados, cada um com o motivo. As três provas usam o mesmo critério, num lugar só. Nada muda no jogo.

## Arquivos que mudam

- `tests/caixa.sh` (da WE01): a função que julga o registro
- `tests/erros_esperados.txt` (novo): uma expressão por linha, com o motivo em comentário
- `tests/prova_do_jogo.sh`, `tests/prova_de_poucos.sh`, `tests/prova_da_bancada.sh`, `scripts/gauntlet.sh`
- `tests/prova_dos_portoes.sh` (a mordida do critério)

## Passos

1. No `tests/caixa.sh`, `caixa_julgar <registro>`: conta as linhas que começam por `ERROR:` ou `SCRIPT ERROR:` e
   não casam com `tests/erros_esperados.txt`, imprime cada uma (com as duas linhas seguintes, que trazem o `at:`) como
   `FAIL erro do motor: …` e devolve 1 se houver alguma.
2. As três provas e o gauntlet chamam o `caixa_julgar` depois de cada rodada, somando à contagem de falhas.
3. A lista começa com os erros de propósito de `prova_do_jogo.gd:426-432`, cada um com o motivo. Rodar uma vez com a
   WQ02 feita: o que mais aparecer é defeito (vira ficha) ou entra na lista com o motivo escrito, nunca sem.
4. A mordida em `tests/prova_dos_portoes.sh`: um registro de mentira com um `ERROR:` desconhecido reprova; com um da
   lista, passa.

## Armadilhas

- **O fim do processo** pode imprimir erro de recurso ainda em uso (o som da vitória que ainda toca, achado na
  rodada de 09/10). A cura certa é parar o tocador antes do `quit`; só entra na lista se não houver como, com o
  motivo.
- **O `WARNING:`** não reprova: só `ERROR:` e `SCRIPT ERROR:`.
- **As linhas que o registro do jogo escreve com a palavra «erro»** (em português) não são do motor; case pelo
  prefixo em maiúsculas no começo da linha.
- **A ordem com a WQ02:** com esta ficha e sem a WQ02, a prova do jogo fica vermelha. Costurar a WQ02 antes.

## Não fazer

- Não esconder um erro novo na lista para a prova passar: cada entrada leva o porquê.
- Não mudar o que cada prova confere além do critério de erro.
- Não pôr o critério em cada script: ele mora no `tests/caixa.sh`.

## Pronto quando

Com a WQ02 desfeita de propósito, a prova do jogo reprova com «FAIL erro do motor: Lambda capture at index 0…»; com a
WQ02, volta ao verde. Os erros de propósito da `prova_do_jogo.gd` não reprovam.

## Provas

- `bash tests/prova_dos_portoes.sh` (a mordida).
- `bash tests/prova_do_jogo.sh`, `bash tests/prova_de_poucos.sh` e `bash tests/prova_da_bancada.sh`, pela caixa e
  pelo semáforo da máquina.

## Para o André (local)

Rodar `bash tests/prova_de_poucos.sh` e ver que a saída diz o mesmo de antes. Pôr um `push_error("teste")` de mentira
numa sala, rodar de novo e ver a prova reprovar com a linha; tirar.

## Ao terminar

Pôr a linha da WQ01 no [quadro](README.md) como **feito**, com o commit, e citar o `tests/erros_esperados.txt` no
[WE-mapa](../revisao/WE-mapa.md) (ou no documento das provas que a WE01 atualizar).

## O que foi feito (leva 1, a-caixa)

- **`tests/caixa.sh`, `caixa_julgar <registro>`:** lê o registro com o `awk`, e toda linha que começa por `ERROR:` ou
  `SCRIPT ERROR:` e não casa com `tests/erros_esperados.txt` sai como `FAIL erro do motor: …`, com as duas linhas
  seguintes (o `at:`); devolve 1 se houver alguma. O `WARNING:` e a palavra «erro» no meio da linha não reprovam.
- **`tests/erros_esperados.txt` (novo):** os dois erros de propósito da `_prova_do_catalogo` (a FICHA sem «faixa» e o
  gênero que não existe), cada um com o motivo, e três linhas «na saída» que só a prova do jogo imprime (RID, recursos
  e páginas ainda vivos no fim do processo), com o motivo e a ficha que as tira: a
  [WQ05](WQ05-a-prova-do-jogo-sai-limpa.md), nova.
- **As provas:** `tests/prova_do_jogo.sh` (cada rodada), `tests/prova_de_poucos.sh` (cada rodada),
  `tests/prova_da_bancada.sh` e `scripts/gauntlet.sh` (a rodada limpa e cada defeito) chamam o `caixa_julgar` depois
  do código de saída e somam à contagem de falhas.
- **O som no fim:** `godot/testes/prova_de_poucos.gd` e `prova_do_jogo.gd` param todo `AudioStreamPlayer` da árvore e
  esperam o misturador antes do `quit` (`_calar_o_som_antes_de_sair`). Com isso a prova de poucos sai sem nenhum
  `ERROR:`; antes, o som da vitória e o da transição ainda tocavam e o motor acusava o `AudioStreamPlayback` vivo.
- **`tests/prova_dos_portoes.sh`:** quatro casos de «erro do motor» (o `ERROR:` desconhecido reprova e a linha diz o
  que o motor disse; o `SCRIPT ERROR:` reprova; os da lista, o `WARNING:` e o «erro» do meio da linha passam).
- **`docs/jogo/revisao/WE-mapa.md`:** um parágrafo sobre o critério e a lista.

**Provas:**

- O «Pronto quando», com o `forja.gd` de antes da WQ02 (pela caixa e pelo semáforo): a prova do jogo reprova, rc 1,
  com 14 `FAIL erro do motor: Lambda capture at index 0 was freed. Passed "null" instead.`, cada uma com o `at:`. Na
  rodada «antes», o Godot disse «prova do jogo ok» e saiu 0: só o erro do motor a reprovou. (Na rodada «forma-a» também
  caiu o relógio do kit, com a máquina em carga 31: a WE02.) Com a WQ02 de volta, o `forja.gd` igual ao do commit.
- Com a cura, pela caixa e pelo semáforo (carga de 18 a 3): `bash tests/prova_do_jogo.sh`, `bash
  tests/prova_de_poucos.sh` (as oito rodadas) e `bash tests/prova_da_bancada.sh` verdes, com 0 «FAIL erro do motor».
- A mordida do critério: com o `caixa_julgar` trocado para sempre sair 0, `bash tests/prova_dos_portoes.sh` reprova os
  dois casos que esperam 1 («2 de 54 casos falharam»); de volta, «54 casos» ok.
- O gauntlet não rodou (cerca de 90 minutos): ele chama o mesmo `caixa_julgar` depois de cada rodada.

**Fica para a mão (o André):** rodar `bash tests/prova_de_poucos.sh` e ver que a saída diz o mesmo de antes; pôr um
`push_error("teste")` de mentira numa sala, rodar de novo e ver a prova reprovar com `FAIL erro do motor: teste`;
tirar.
