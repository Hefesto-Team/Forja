#!/usr/bin/env bash
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
source "$RAIZ/scripts/engine.sh"
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
((${#experimentos[@]})) || experimentos=(laco quatro-mics eco gatilho-cru haptica-nomeada haptico)

mkdir -p "$RAIZ/relatorios"
for exp in "${experimentos[@]}"; do
  echo "==> experimento $exp"
  "$GODOT" --path "$RAIZ/godot" -- --experimento="$exp" --relatorios="$RAIZ/relatorios" ${extra[@]+"${extra[@]}"} ||
    echo "    o jogo saiu com erro no $exp"
done
echo "os resultados estão em relatorios/ (linha-do-tempo-*.jsonl, \"tipo\": \"experimento\")"
