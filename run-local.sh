#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

source "$ROOT/scripts/engine.sh"
GODOT_VER="$FORJA_GODOT_VER"
GODOT_BIN="$FORJA_GODOT"

echo "==> ferramentas de bancada (o mesmo empacotador USB 0x02 do jogo)"
make -s all

if [[ "${1:-}" == bancada ]]; then
  "$ROOT/bin/forja-send" --list || true
  exit 0
fi
[[ "${1:-}" == "--" ]] && shift

echo "==> módulo nativo (SDL3 + godot-cpp; a primeira vez baixa e compila)"
"$ROOT/scripts/compilar.sh" linux

forja_baixar_engine || exit 1

echo "==> importando os assets (a primeira vez demora)"
"$GODOT_BIN" --headless --path "$ROOT/godot" --import >"$ROOT/build/godot-import.log" 2>&1 || true

echo "==> abrindo o FORJA"
echo "    ✕ entra e fica pronto · Options pausa · com -- --bancada, Create abre o diagnóstico"
echo "    sem controle: Enter no título (o teclado vira um DualSense simulado)"
echo "    relatórios em relatorios/"
exec "$GODOT_BIN" --path "$ROOT/godot" -- --relatorios="$ROOT/relatorios" "$@"
