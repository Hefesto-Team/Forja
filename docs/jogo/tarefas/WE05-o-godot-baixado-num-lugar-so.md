# WE05 — O Godot baixado num lugar só, também em casa

**Sprint:** W · **Tamanho:** P · **Depende de:** [V01](V01-a-engine-conferida.md) (a soma no `forja_baixar_engine`)

## Por quê

O `./run-local.sh` é o primeiro comando do README para quem chega, e ele quebra na primeira baixada do Godot: usa uma
variável que ninguém define. A V01 junta o download do CI no `scripts/engine.sh` e põe a soma ali; o `run-local.sh` e
o `scripts/exportar.sh` têm cada um a própria cópia, e sem esta ficha ficariam fora da soma.

## Ler antes

- [V01 — A engine conferida](V01-a-engine-conferida.md)
- [scripts/engine.sh](../../../scripts/engine.sh) (o `forja_baixar_engine`)
- [F00](F00-o-ambiente-da-sessao.md), linhas 109-112 (onde o defeito foi anotado e ficou sem ficha)

## O estado de hoje

- `run-local.sh:35`, com `set -euo pipefail` (`:11`): `curl -fsSL -o "$tmp/godot.zip" "$GODOT_URL"`. O `engine.sh`
  define `FORJA_GODOT_URL` (`:14`), e só o `exportar.sh` define `GODOT_URL` (`:28`). Medido em 09/10/2026:
  `bash -uc 'source scripts/engine.sh; echo "$GODOT_URL"'` responde «GODOT_URL: variável não associada», rc 127.
  Numa máquina sem o `tools/`, o primeiro `./run-local.sh` morre antes de baixar.
- `scripts/exportar.sh:48-60` (`garantir_godot`) tem outra cópia do mesmo download, que funciona e não confere soma.
- O cabeçalho do `run-local.sh:2` diz «Godot 4.4», e `docs/DESENVOLVER.md:28` diz «baixa o Godot 4.4.1 na primeira
  vez». A versão é a do `engine.sh`: `4.7.2-stable`.
- O `scripts/instalar.sh:139` e o `scripts/preparar_sessao.sh:47` já usam o `forja_baixar_engine` e não têm o defeito.

## O alvo

Um download só, o do `engine.sh`, com a soma da V01: o `run-local.sh` e o `exportar.sh` o chamam.

## Passos

1. No `run-local.sh`, trocar o bloco `:31-39` por `forja_baixar_engine || exit 1`.
2. No `exportar.sh`, o `garantir_godot` vira `forja_baixar_engine`, e a `GODOT_URL` de `:28` sai.
3. O cabeçalho do `run-local.sh` e o `docs/DESENVOLVER.md` (`:7`, `:12`, `:28`) deixam de dizer a versão
   com todas as letras e apontam para o `engine.sh`.

## Armadilhas

- O `run-local.sh` compila o módulo (`:29`) antes de baixar o Godot. Não trocar a ordem: quem só quer a bancada sai
  antes.
- O `exportar.sh` usa `GODOT_BIN` e `GODOT_VER` em outros lugares (os modelos em `:42`): tirar só o download, não as
  variáveis.

## Não fazer

- Não mexer no download dos modelos de exportação nem no do `appimagetool`: já conferem sha256.

## Pronto quando

`git grep -n 'godotengine/godot/releases' -- run-local.sh scripts/exportar.sh` não acha nada, e
`git grep -n 'GODOT_URL' -- run-local.sh scripts/exportar.sh` também não.

## Provas

- `bash -n run-local.sh scripts/exportar.sh`.
- Numa cópia da árvore sem `tools/`, com um `curl` de mentira na frente do PATH que só grava a URL pedida e sai 1:
  `GODOT=/nao/existe ./run-local.sh` sai 1 com a mensagem do `forja_baixar_engine`, e a URL gravada é a do
  `FORJA_GODOT_URL` (hoje sai 127 com «variável não associada»).
- A prova da V01 (a soma trocada) vale para os dois.

## Para o André (local)

Clonar o repositório numa pasta nova e rodar `./run-local.sh`: o Godot baixa, confere e o jogo abre.

## Ao terminar

Pôr a linha da WE05 no [quadro](README.md) como **feito**, com o commit, e na [F00](F00-o-ambiente-da-sessao.md)
trocar o «Anotado, não mexido» por um apontador para esta ficha.
