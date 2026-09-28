#!/usr/bin/env bash
# Sobe o FORJA (a Hefesto Tech Demo) na máquina: o jogo 3D em Godot 4.4 com o
# módulo nativo (SDL3) que fala com os DualSense.
#
#   ./run-local.sh                     compila o módulo e abre o jogo
#   ./run-local.sh -- --simular=4      argumentos depois de -- vão para o jogo
#   ./run-local.sh bancada             só as ferramentas de bancada (forja-send e cia.)
#
# Sem controle nenhum, o título oferece jogar no teclado (um DualSense simulado).
# Argumentos do jogo: --simular[=N] --robo --semente=N --relatorios=PASTA --sala=ID
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

GODOT_VER="4.4.1-stable"
GODOT_BIN="$ROOT/tools/Godot_v${GODOT_VER}_linux.x86_64"
GODOT_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VER}/Godot_v${GODOT_VER}_linux.x86_64.zip"

echo "==> ferramentas de bancada (o mesmo empacotador USB 0x02 do jogo)"
make -s all

if [[ "${1:-}" == bancada ]]; then
  "$ROOT/bin/forja-send" --list || true
  exit 0
fi
[[ "${1:-}" == "--" ]] && shift

echo "==> módulo nativo (SDL3 + godot-cpp; a primeira vez baixa e compila)"
"$ROOT/scripts/compilar.sh" linux

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "==> baixando Godot ${GODOT_VER} (editor Linux x86_64, ~60 MB)"
  mkdir -p "$ROOT/tools"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/godot.zip" "$GODOT_URL"
  unzip -o -q "$tmp/godot.zip" -d "$ROOT/tools"
  chmod +x "$GODOT_BIN"
  rm -rf "$tmp"
fi

echo "==> importando os assets (a primeira vez demora)"
"$GODOT_BIN" --headless --path "$ROOT/godot" --import >"$ROOT/build/godot-import.log" 2>&1 || true

echo "==> abrindo o FORJA"
echo "    ✕ entra e fica pronto · Create diagnóstico · Options pausa"
echo "    sem controle: Enter no título (o teclado vira um DualSense simulado)"
echo "    relatórios em relatorios/"
exec "$GODOT_BIN" --path "$ROOT/godot" -- --relatorios="$ROOT/relatorios" "$@"
