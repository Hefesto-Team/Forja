#!/usr/bin/env bash
# O trailer de 60 s: o jogo rodando com quatro DualSense simulados e o robô,
# gravado quadro a quadro pelo Movie Maker do Godot (--write-movie), numa tela
# virtual (Xvfb) — sem cortes para esconder tela crua: é o jogo como ele é.
#
#   scripts/trailer.sh [saída.avi]     (padrão: dist/trailer.avi, 1280×720)
#
# Com um ffmpeg no PATH, sai também um .mp4 ao lado. FORJA_IDIOMA=en grava as
# telas em inglês.
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-$RAIZ/tools/Godot_v4.4.1-stable_linux.x86_64}"
SAIDA="$(realpath -m "${1:-$RAIZ/dist/trailer.avi}")"
mkdir -p "$(dirname "$SAIDA")"
REL="$(mktemp -d)"
trap 'rm -rf "$REL"' EXIT
"$GODOT" --headless --path "$RAIZ/godot" --import --quit > /dev/null 2>&1
ROTEIRO=trailer SAIDA="$REL" xvfb-run -a -s "-screen 0 1280x720x24" \
  "$GODOT" --rendering-driver opengl3 --fixed-fps 60 --path "$RAIZ/godot" --resolution 1280x720 \
  --write-movie "$SAIDA" res://testes/captura_jogo.tscn -- --simular=4 --robo --semente=7 --relatorios="$REL"
echo "==> $SAIDA"
if command -v ffmpeg > /dev/null; then
  ffmpeg -y -loglevel error -i "$SAIDA" -c:v libx264 -pix_fmt yuv420p -crf 23 -c:a aac -b:a 160k "${SAIDA%.avi}.mp4"
  echo "==> ${SAIDA%.avi}.mp4"
fi
