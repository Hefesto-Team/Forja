#!/usr/bin/env bash
# Roda os experimentos da bancada, um depois do outro, com os controles da
# mesa (ver experimental/README.md). Cada um é uma sessão: a linha do tempo e
# o registro vão para relatorios/.
#
#   experimental/rodar.sh                       os cinco
#   experimental/rodar.sh laco eco              só esses
#   JOGO=caminho/do/binario experimental/rodar.sh
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
JOGO="${JOGO:-$RAIZ/build/linux/hefesto-tech-demo}"
if [[ ! -x "$JOGO" ]]; then
  echo "não achei o jogo em $JOGO (scripts/compilar.sh linux)" >&2
  exit 2
fi
if (($# == 0)); then
  set -- laco quatro-mics eco gatilho-cru haptica-nomeada
fi
mkdir -p "$RAIZ/relatorios"
for exp in "$@"; do
  echo "==> experimento $exp"
  "$JOGO" --experimento "$exp" --relatorios "$RAIZ/relatorios" || echo "    o jogo saiu com erro no $exp"
done
echo "os resultados estão em relatorios/ (linha-do-tempo-*.jsonl, \"tipo\": \"experimento\")"
