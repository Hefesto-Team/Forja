#!/usr/bin/env bash
set -euo pipefail
uso() {
  cat <<'FIM'
Cria a entrada do devlog: docs/devlog/AAAA-MM-DD-<slug>/entrada.md, com o cabeçalho e o resumo para escrever.

Uso: scripts/devlog/entrada.sh <slug> "<título>" [--base REF] [--topo REF] [--ramo NOME]
  --base   o ponto de antes (padrão: git merge-base main HEAD)
  --topo   o ponto de depois (padrão: HEAD)
  --ramo   o nome do ramo no cabeçalho (padrão: o ramo atual)
Imprime o caminho da pasta. O resumo tem no máximo 8 linhas e é de quem entrega; depois, scripts/devlog/fotos.sh.
FIM
}
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAIZ="$(cd "$AQUI/../.." && pwd)"
SLUG=""
TITULO=""
BASE=""
TOPO="HEAD"
RAMO=""
POS=()
while [ $# -gt 0 ]; do
  case "$1" in
    -h | --ajuda) uso; exit 0 ;;
    --base) BASE="${2:?falta o valor de --base}"; shift ;;
    --topo) TOPO="${2:?falta o valor de --topo}"; shift ;;
    --ramo) RAMO="${2:?falta o valor de --ramo}"; shift ;;
    -*) echo "entrada: argumento desconhecido: $1" >&2; exit 2 ;;
    *) POS+=("$1") ;;
  esac
  shift
done
[ "${#POS[@]}" -eq 2 ] || { uso >&2; exit 2; }
SLUG="${POS[0]}"
TITULO="${POS[1]}"
case "$SLUG" in
  "" | *[!a-z0-9-]* | -* | *-) echo "entrada: o slug usa só a-z, 0-9 e hífen (veio «$SLUG»)" >&2; exit 2 ;;
esac
[ -n "$TITULO" ] || { echo "entrada: falta o título" >&2; exit 2; }
case "$TITULO" in *$'\n'*) echo "entrada: o título cabe numa linha" >&2; exit 2 ;; esac

cd "$RAIZ"
topo_sha="$(git rev-parse --verify --short=7 "$TOPO^{commit}" 2> /dev/null)" || { echo "entrada: o topo «$TOPO» não existe" >&2; exit 2; }
if [ -z "$BASE" ]; then
  BASE="$(git merge-base main HEAD 2> /dev/null)" || { echo "entrada: sem o main para achar a base; passe --base" >&2; exit 2; }
fi
base_sha="$(git rev-parse --verify --short=7 "$BASE^{commit}" 2> /dev/null)" || { echo "entrada: a base «$BASE» não existe" >&2; exit 2; }
if [ -z "$RAMO" ]; then
  RAMO="$(git rev-parse --abbrev-ref HEAD 2> /dev/null || echo "?")"
  [ "$RAMO" != "HEAD" ] || RAMO="(solto)"
fi

data="${DEVLOG_DATA:-$(date +%F)}"
pasta="docs/devlog/$data-$SLUG"
[ ! -e "$pasta" ] || { echo "entrada: $pasta já existe" >&2; exit 1; }

fichas=""
for id in $(git log --format='%s%n%b' "$base_sha..$topo_sha" 2> /dev/null | grep -oE '\b[A-Z][0-9]{2}\b' | sort -u); do
  if compgen -G "docs/jogo/tarefas/$id-*.md" > /dev/null; then
    fichas="${fichas:+$fichas, }$id"
  fi
done

mkdir -p "$pasta"
{
  echo "---"
  echo "titulo: $TITULO"
  echo "data: $data"
  echo "ramo: $RAMO"
  echo "base: $base_sha"
  echo "topo: $topo_sha"
  echo "fichas: $fichas"
  echo "---"
  echo "A ESCREVER: o que mudou, em até 8 linhas."
} > "$pasta/entrada.md"
echo "$pasta"
