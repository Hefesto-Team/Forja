# WT03 — Os portões falam curto

**Sprint:** W · **Tamanho:** P · **Depende de:** nada; não voar junto com a [WE01](WE01-a-caixa-unica.md), que
acrescenta um portão no mesmo `rodar.sh`; conversa com a [V08](V08-os-portoes-de-arte-e-som-reprovam.md)

## Por quê

Os portões rodam antes de todo commit. Hoje a saída inteira de cada portão vai para a tela: 385 linhas e quase 39 mil
caracteres, 362 delas avisos antigos que ninguém vai consertar agora. O que importa (um FAIL novo, no arquivo que a
pessoa mexeu) some no meio, e cada rodada custa o mesmo tanto de leitura para quem lê a saída.

## Ler antes

- [O LEIA-ME dos portões](../../../scripts/portoes/LEIA-ME.md)

## O estado de hoje (medido em 09/10/2026, `85f24c3`)

- `scripts/portoes/rodar.sh:35-50`, o `roda`:
  ```bash
  echo "==> $nome"
  "$@" 2>&1 | tee "$LOG"
  ```
  e o `LOG` é um `mktemp` só, sobrescrito a cada portão e apagado na saída (`:36`).
- `bash scripts/portoes/rodar.sh` na árvore de hoje: 385 linhas, 362 com `AVISO`.
- O resumo do fim (`ok`, `FAIL`, `ERRO` por portão) já existe e é curto.

## O alvo

A tela mostra o resumo por portão e, para cada portão que não deu `ok`, as linhas de `FAIL` e de `ERRO` e no máximo
12 linhas no total; a saída inteira de cada portão fica em `.cache/portoes/<nome>.log`, com o caminho no resumo.
`--desde <ref>` mostra também os avisos dos arquivos mudados desde a referência; `--tudo` volta à saída de hoje. O
código de saída não muda.

## Arquivos que mudam

- `scripts/portoes/rodar.sh`
- `scripts/portoes/LEIA-ME.md`
- `tests/prova_dos_portoes.sh` (a mordida)
- `.github/workflows/forja.yml` (o `--tudo` no passo dos portões)

## Passos

1. O `roda` grava a saída em `$RAIZ/.cache/portoes/<nome>.log` (o nome sem espaço nem acento), sem `tee`.
2. No fim, para cada portão `FAIL` ou `ERRO`: as linhas que começam com `FAIL` ou `ERRO` do log dele, cortadas em 12
   no total, e «o resto: .cache/portoes/<nome>.log».
3. `--desde <ref>`: os avisos cujo caminho está em `git diff --name-only <ref>` também aparecem (no mesmo corte).
4. `--tudo`: o `tee` de hoje.
5. A mordida: um portão de mentira que imprime 500 avisos e um FAIL deixa no máximo 20 linhas na tela, o FAIL entre
   elas, e o log inteiro no arquivo; com `--tudo`, as 500.

## Armadilhas

- **O código de saída** sai do `PIPESTATUS` de hoje; sem o `tee`, sai do `$?` direto. A mordida confere 0, 1 e 2.
- **A CI** roda os portões em `.github/workflows/forja.yml:111` e lê a saída: lá vai `--tudo`, para o log da CI
  seguir completo (o runner morre, e o `.cache/` com ele).
- **A WE01** acrescenta uma linha `roda` no mesmo arquivo: quem vier depois costura à mão.

## Não fazer

- Não mudar o que cada portão confere nem transformar aviso em falha (isso é da V08).
- Não apagar o `.cache/portoes/` na saída: o log é para ser lido depois.

## Pronto quando

`bash scripts/portoes/rodar.sh` na árvore de hoje imprime no máximo 30 linhas (hoje 385) e sai com o mesmo código;
`--tudo` imprime as 385.

## Provas

- `bash tests/prova_dos_portoes.sh` (a mordida).
- `bash scripts/portoes/rodar.sh` e `bash scripts/portoes/rodar.sh --tudo | wc -l`.

## Para o André (local)

Rodar `bash scripts/portoes/rodar.sh --desde origin/main` depois de mexer numa ficha e conferir que os avisos dela
aparecem e os dos outros arquivos não.

## Ao terminar

Pôr a linha da WT03 no [quadro](README.md) como **feito**, com o commit.

## O que foi feito (leva 1, a-caixa)

- **`scripts/portoes/rodar.sh`:** o `roda` grava a saída inteira de cada portão em `.cache/portoes/<nome>.log` (o nome
  sem espaço nem acento, pelo `iconv`: `texto-de-tela.log`), sem `tee`, e o código sai do `$?` direto. No fim, depois
  do resumo de sempre: as linhas `FAIL` e `ERRO` dos portões que não deram `ok`, cortadas em 12 (e «(mais N
  linhas)»), «o resto: .cache/portoes/<nome>.log» de cada um deles, e uma linha com onde mora a saída inteira.
  `--desde <ref>` junta ao corte os avisos cujo caminho está em `git diff --name-only <ref>` (e diz quando o git não
  acha a referência). `--tudo` é a saída de antes, com o `tee`. O `.cache/portoes/` não é apagado.
- **`.github/workflows/forja.yml`:** o passo dos portões roda com `--tudo`.
- **`scripts/portoes/LEIA-ME.md`:** o `--desde`, o `--tudo` e onde fica a saída inteira.
- **`tests/prova_dos_portoes.sh`:** seis casos numa árvore com o `rodar.sh` de verdade e portões de mentira (um deles
  imprime 500 avisos e um FAIL): sai 1, a tela fica em até 20 linhas com o FAIL e o caminho do log, e o log tem os
  500; `--tudo` mostra os 500; `--desde` num repositório mostra só o aviso do arquivo mudado; com tudo `ok` sai 0; com
  o portão que não conferiu sai 2.

**Provas:**

- `bash scripts/portoes/rodar.sh` na árvore desta leva: 10 linhas, rc 0; `bash scripts/portoes/rodar.sh --tudo | wc -l`:
  388 (a ficha mediu 385 antes do portão da caixa da WE01).
- A mordida: com o `rodar.sh` mostrando sempre a saída inteira, reprovam o caso das 20 linhas e o do `--desde`; com o
  `--desde` sem ler o git, reprova o do `--desde`. De volta, «68 casos» ok.

**Fica para a mão (o André):** `bash scripts/portoes/rodar.sh --desde origin/main` depois de mexer numa ficha, e
conferir que os avisos dela aparecem e os dos outros arquivos não.
