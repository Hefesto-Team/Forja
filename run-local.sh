#!/usr/bin/env bash
# Sobe FORJA na máquina: empacotador USB 0x02 + Godot 4.4.
# Uso: ./run-local.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "==> empacotador DualSense (USB 0x02)"
make -s all

GODOT_VER="4.4.1-stable"
GODOT_BIN="$ROOT/tools/Godot_v${GODOT_VER}_linux.x86_64"
GODOT_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VER}/Godot_v${GODOT_VER}_linux.x86_64.zip"

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "==> baixando Godot ${GODOT_VER} (editor Linux x86_64, ~60 MB)"
  mkdir -p "$ROOT/tools"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/godot.zip" "$GODOT_URL"
  unzip -o "$tmp/godot.zip" -d "$ROOT/tools"
  chmod +x "$GODOT_BIN"
  rm -rf "$tmp"
fi

echo "==> DualSense na mesa (hidraw USB)"
"$ROOT/bin/forja-send" --list || true

if [[ ! -e /dev/hidraw0 ]]; then
  echo "aviso: nenhum hidraw visível. o jogo ainda abre; rumble SDL funciona se o pad estiver no cabo."
fi

echo "==> importando assets Godot (primeira vez)"
"$GODOT_BIN" --headless --path "$ROOT/godot" --import --quit >/tmp/forja-godot-import.log 2>&1 || true

echo "==> abrindo FORJA"
echo "    WASD anda · Espaço atira · Esc hub"
echo "    3 = P3 toma da esquerda (só o motor L do player 2 deve tremer)"
echo "    F1 Galeria  F2 Impacto  F3 Viga  F4 A Prova"
exec "$GODOT_BIN" --path "$ROOT/godot"
