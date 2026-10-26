#!/usr/bin/env bash
set -euo pipefail
uso() {
  cat <<'EOF'
Liga o pre-commit da Forja: o .git/hooks/pre-commit passa a chamar o scripts/hooks/pre-commit da árvore do commit.

Uso: bash scripts/hooks/ligar.sh [--conferir]
  --conferir   diz se está ligado (sai 0) ou não (sai 1), sem gravar
Vale para toda worktree do repositório. Uma árvore sem o scripts/hooks/pre-commit passa sem conferir.
EOF
}
DESTINO="$(git rev-parse --path-format=absolute --git-common-dir)/hooks/pre-commit"
INVOLUCRO='#!/usr/bin/env bash
G="$(git rev-parse --show-toplevel)/scripts/hooks/pre-commit"
[ -x "$G" ] || exit 0
exec "$G" "$@"'
case "${1:-}" in
  -h|--ajuda) uso; exit 0 ;;
  --conferir)
    if [ -x "$DESTINO" ] && [ "$(cat "$DESTINO")" = "$INVOLUCRO" ]; then echo "pre-commit: ligado ($DESTINO)"; exit 0; fi
    echo "pre-commit: desligado; rode bash scripts/hooks/ligar.sh"; exit 1 ;;
  "") ;;
  *) uso >&2; exit 2 ;;
esac
if [ -e "$DESTINO" ] && [ "$(cat "$DESTINO")" != "$INVOLUCRO" ]; then
  cp -p "$DESTINO" "$DESTINO.antes-de-ligar"
  echo "pre-commit: o gancho que estava lá foi guardado em $DESTINO.antes-de-ligar"
fi
mkdir -p "$(dirname "$DESTINO")"
printf '%s\n' "$INVOLUCRO" > "$DESTINO"
chmod +x "$DESTINO"
echo "pre-commit: ligado ($DESTINO)"
