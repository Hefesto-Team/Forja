#!/usr/bin/env bash
# Sobe FORJA na máquina.
#
#   ./run-local.sh                  a Hefesto Tech Demo (SDL3): compila e abre
#   ./run-local.sh -- --sala=voz    argumentos depois de -- vão para a Tech Demo
#   ./run-local.sh godot            o FORJA em Godot 4.4, como antes
#
# Os dois falam DualSense do mesmo jeito: relatório USB 0x02, um empacotador só
# (src/forja_dualsense.c). Ver CONTRATO.md.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "==> empacotador DualSense (USB 0x02)"
make -s all

echo "==> DualSense na mesa (hidraw USB)"
"$ROOT/bin/forja-send" --list || true

if [[ ! -e /dev/hidraw0 ]]; then
  echo "aviso: nenhum hidraw visível. o jogo ainda abre; rumble SDL funciona se o pad estiver no cabo."
fi

if [[ "${1:-}" == godot ]]; then
  shift
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

  echo "==> importando assets Godot (primeira vez)"
  "$GODOT_BIN" --headless --path "$ROOT/godot" --import --quit >/tmp/forja-godot-import.log 2>&1 || true

  echo "==> abrindo FORJA (Godot)"
  echo "    WASD anda · Espaço atira · Esc hub"
  echo "    3 = P3 toma da esquerda (só o motor L do player 2 deve tremer)"
  echo "    F1 Galeria  F2 Impacto  F3 Viga  F4 A Prova"
  exec "$GODOT_BIN" --path "$ROOT/godot" "$@"
fi

[[ "${1:-}" == "--" ]] && shift

echo "==> Hefesto Tech Demo (SDL3 estático, primeira vez baixa e compila o SDL)"
"$ROOT/scripts/compilar.sh" linux

echo "==> abrindo a Hefesto Tech Demo"
echo "    ✕ entra na mesa · Options começa · ○ volta"
echo "    sem controle: --simular 4 (teclado: Z/X/C/V, setas, WASD, Tab troca o controle)"
echo "    relatórios em relatorios/"
exec "$ROOT/build/linux/hefesto-tech-demo" --relatorios "$ROOT/relatorios" "$@"
