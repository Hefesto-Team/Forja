#!/usr/bin/env bash
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
source "$RAIZ/scripts/engine.sh"
GODOT="$FORJA_GODOT"
SAIDA="$(realpath -m "${1:-$RAIZ/dist/trailer.avi}")"
mkdir -p "$(dirname "$SAIDA")"
REL="$(mktemp -d)"
trap 'rm -rf "$REL"' EXIT
source "$RAIZ/tests/caixa.sh"
caixa_montar "$REL/caixa"
caixa "$GODOT" --headless --path "$RAIZ/godot" --import --quit > /dev/null 2>&1
ROTEIRO=trailer SAIDA="$REL" xvfb-run -a -s "-screen 0 1280x720x24" \
  caixa "$GODOT" --rendering-driver opengl3 --fixed-fps 60 --path "$RAIZ/godot" --resolution 1280x720 \
  --write-movie "$SAIDA" res://testes/captura_jogo.tscn -- --simular=4 --robo --semente=7 --relatorios="$REL"
echo "==> $SAIDA"
if command -v ffmpeg > /dev/null; then
  ffmpeg -y -loglevel error -i "$SAIDA" -c:v libx264 -pix_fmt yuv420p -crf 23 -c:a aac -b:a 160k "${SAIDA%.avi}.mp4"
  echo "==> ${SAIDA%.avi}.mp4"
fi
