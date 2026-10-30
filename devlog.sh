#!/usr/bin/env bash
set -euo pipefail
uso() {
  cat <<'FIM'
Abre o devlog: uma página com as entradas de docs/devlog/, a mais nova em cima, com as fotos de antes e depois.

Uso: ./devlog.sh [--sem-abrir] [--entrada PASTA]
  --sem-abrir      só monta .cache/devlog/index.html e imprime o caminho (o que o agente usa)
  --entrada PASTA  monta só a entrada daquela pasta
A entrada nasce de scripts/devlog/entrada.sh e as fotos de scripts/devlog/fotos.sh. Abre com xdg-open. Sem rede.
FIM
}
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ABRIR=1
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    -h | --ajuda) uso; exit 0 ;;
    --sem-abrir) ABRIR=0 ;;
    --entrada) ARGS+=(--entrada "${2:?falta a pasta de --entrada}"); shift ;;
    *) echo "devlog: argumento desconhecido: $1" >&2; exit 2 ;;
  esac
  shift
done
CAMINHO="$(python3 "$RAIZ/scripts/devlog/montar.py" --raiz "$RAIZ" "${ARGS[@]+"${ARGS[@]}"}")"
echo "$CAMINHO"
if [ "$ABRIR" -eq 1 ]; then
  command -v xdg-open > /dev/null || { echo "devlog: sem xdg-open; abra $CAMINHO" >&2; exit 0; }
  nohup xdg-open "$CAMINHO" > /dev/null 2>&1 &
fi
