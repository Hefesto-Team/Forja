#!/usr/bin/env bash
# Roda os experimentos da bancada, um depois do outro, com os controles da
# mesa (ver experimental/README.md). Cada um é uma sessão do jogo 3D: a linha
# do tempo e o registro vão para relatorios/. No fim de cada um, ○ fecha e o
# próximo abre.
#
#   experimental/rodar.sh                              os cinco
#   experimental/rodar.sh laco eco                     só esses
#   experimental/rodar.sh -- --simular=4 --robo        depois de --, argumentos do jogo
#   GODOT=<binário> experimental/rodar.sh              outro Godot
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
source "$RAIZ/scripts/engine.sh"   # a versão da engine mora lá (ADR-009)
GODOT="$FORJA_GODOT"
[[ -x "$GODOT" ]] || { echo "sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>" >&2; exit 2; }
[[ -f "$RAIZ/godot/bin/libforja.linux.x86_64.so" ]] || { echo "sem o módulo: scripts/compilar.sh linux" >&2; exit 2; }

experimentos=()
extra=()
while (($#)); do
  if [[ "$1" == "--" ]]; then
    shift
    extra=("$@")
    break
  fi
  experimentos+=("$1")
  shift
done
((${#experimentos[@]})) || experimentos=(laco quatro-mics eco gatilho-cru haptica-nomeada)

mkdir -p "$RAIZ/relatorios"
for exp in "${experimentos[@]}"; do
  echo "==> experimento $exp"
  "$GODOT" --path "$RAIZ/godot" -- --experimento="$exp" --relatorios="$RAIZ/relatorios" ${extra[@]+"${extra[@]}"} ||
    echo "    o jogo saiu com erro no $exp"
done
echo "os resultados estão em relatorios/ (linha-do-tempo-*.jsonl, \"tipo\": \"experimento\")"
