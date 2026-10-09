# WE03 — O gauntlet no CI

**Sprint:** W · **Tamanho:** M · **Depende de:** [WE01](WE01-a-caixa-unica.md) (a caixa), [V01](V01-a-engine-conferida.md)
(o passo único do Godot no CI)

## Por quê

O gauntlet é a prova da prova: roda a prova do jogo com cada um dos 20 defeitos de mentira do simulador e exige que
cada um seja pego. Ele nunca entrou no CI nem no `ci-local`, e as fichas feitas o deixaram «com o André». Só que a
régua que ele confere (`godot/testes/prova_do_jogo.gd`) muda a cada leva, e a [V02](V02-a-prova-do-jogo-em-partes.md)
vai dividi-la em partes. Se uma mudança deixa um defeito passar, hoje ninguém fica sabendo.

## Ler antes

- [ADR-003 — o gauntlet](../../adr/003-o-gauntlet.md)
- [scripts/gauntlet.sh](../../../scripts/gauntlet.sh)
- [scripts/ci-local.sh](../../../scripts/ci-local.sh) (a `TABELA`)

## O estado de hoje

- `git grep -n gauntlet .github/workflows/forja.yml scripts/ci-local.sh run.sh` não acha nada. O gauntlet só aparece
  como passo à mão: `.github/CONTRIBUTING.md:26`, `.github/PULL_REQUEST_TEMPLATE.md:19` e
  `docs/COMO-CONTRIBUIR.md:56`.
- [F01](F01-o-modo-bancada.md), linha 348: «`scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh` ficam com o
  André». [F08](F08-a-paridade.md), linhas 94 e 152: «Fica para a mão dela ou do André». As duas estão como feitas.
- A lista do gauntlet (`scripts/gauntlet.sh:24-26`) tem os mesmos 20 defeitos de `nativo/nucleo/simulador.c:54-63`,
  escritos de novo à mão.
- `scripts/gauntlet.sh:40` engole a falha do import: `"$GODOT" --headless --path "$RAIZ/godot" --import >/dev/null 2>&1 || true`.
- Cada perna roda a prova inteira, em série: são 21 rodadas da prova do jogo, cada uma com até 600 s (`:36`).

## O alvo

Um job `gauntlet` no `forja.yml`, com `needs: linux`, que usa a `.so` do artefato do `linux` e roda em pernas
paralelas. Na tabela do `ci-local`, ele entra como `ROLA|gauntlet|completo`. A lista dos defeitos vem do simulador, não
de uma cópia.

## Passos

1. `scripts/gauntlet.sh` ganha `--so <defeito,...>` (e `limpo`) para rodar uma parte, e lê a lista inteira da
   tabela `DEFEITOS[]` de `nativo/nucleo/simulador.c` (as entradas `{"nome", DEFEITO_...}`), com uma guarda: lista
   vazia sai 2. A cópia das linhas 24-26 sai.
2. O `|| true` do import sai: o import que falha reprova, com as últimas linhas do log.
3. O Godot do gauntlet passa pela caixa da WE01.
4. O job `gauntlet` no `forja.yml`: `needs: linux`, baixa o artefato da `.so`, o Godot pelo passo único da V01, e uma
   matriz de quatro pernas (a limpa com cinco defeitos e três pernas de cinco). Cada perna sobe o log de quem falhou.
5. A linha `ROLA|gauntlet|completo` na `TABELA` do `ci-local`, com a medida do tempo de uma perna no comentário.
6. Trocar o «fica com o André» do CONTRIBUTING, do modelo de PR e do `COMO-CONTRIBUIR.md` por «o CI roda o
   gauntlet».

## Armadilhas

- A primeira rodada no CI pode achar um defeito que a prova deixou de pegar desde a última vez que alguém rodou o
  gauntlet à mão. Isso é achado, não defeito do job: vira ficha, e o job fica vermelho até ela.
- O tempo: medir uma perna no `ci-local --job gauntlet` antes de escolher quantas pernas. Se o minuto de CI pesar, o
  job roda só no `push` para `main` e no PR que toca `nativo/`, `godot/scripts/salas/`, `godot/scripts/minigames/`
  ou `godot/testes/`.
- Defeito novo no `simulador.c` sem sala que o pegue faz o gauntlet reprovar. É de propósito: a lista sai do simulador
  justamente para isso. Defeito que não tem como ser pego sem aparelho sai do
  simulador, não da lista.
- O `forja.yml` é de todos: esta ficha vai depois da V01 e da WE01, e sozinha no arquivo.

## Não fazer

- Não tirar defeito da lista para o job ficar verde.
- Não juntar as pernas num laço só dentro de um passo: a perna que falha tem de dizer o defeito no nome.

## Pronto quando

O CI tem o job `gauntlet` verde, `bash scripts/ci-local.sh --listar` mostra o gauntlet, e `git grep -n
'troca-cruz-circulo' scripts/gauntlet.sh` não acha nada.

## Provas

- Numa árvore de prova, tirar a conferência do ✕ trocado pelo ○ (`troca-cruz-circulo`) da prova do jogo: a perna
  desse defeito fica vermelha; devolvida a conferência, volta o verde.
- Um import quebrado de propósito (um `.tscn` com erro de sintaxe, numa árvore de prova) faz o gauntlet sair 1.
- `bash scripts/ci-local.sh --job gauntlet`.

## Para o André (local)

Rodar `scripts/gauntlet.sh` uma vez na máquina dele, com a caixa, e comparar com a saída do job do CI: os mesmos
defeitos pegos.

## Ao terminar

Pôr a linha da WE03 no [quadro](README.md) como **feito**, com o commit, e o tempo medido de uma perna.
