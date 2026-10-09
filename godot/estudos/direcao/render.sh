#!/usr/bin/env bash
# Os quadros do estudo de direção (Fita Magnética), fotografados na tela
# virtual (Xvfb) pelo renderizador Compatibility, como as telas do jogo.
#
#   bash godot/estudos/direcao/render.sh <pasta> [quadro ...]
#
# Sem quadro, faz todos. Recolore os colormaps antes (recolorir.gd).
set -u
RAIZ="$(cd "$(dirname "$0")/../../.." && pwd)"
source "$RAIZ/scripts/engine.sh"
GODOT="$FORJA_GODOT"
pasta="$(realpath -m "${1:?uso: render.sh <pasta> [quadro ...]}")"
shift
mkdir -p "$pasta"
QUADROS=("$@")
if [ ${#QUADROS[@]} -eq 0 ]; then
  QUADROS=(01_centelha 02_salao 03_entrada 04_cartao 05_dissonancia 06_podio 07_titulo 08_cavaleiros 09_paleta_kenney 10_montagem 11_pecas 12_reacoes 13_luz 14_storyboard 15_fim_da_fita 16_bigorna 17_forja 18_cortina 19_racas 20_encaixe)
fi
timeout 300 "$GODOT" --headless --path "$RAIZ/godot" -s res://estudos/direcao/recolorir.gd > "$pasta/recolorir.log" 2>&1
timeout 600 "$GODOT" --headless --path "$RAIZ/godot" --import > "$pasta/import.log" 2>&1
for q in "${QUADROS[@]}"; do
  env QUADRO="$q" SAIDA="$pasta" timeout 300 xvfb-run -a -s "-screen 0 1920x1080x24" \
    "$GODOT" --rendering-driver opengl3 --audio-driver Dummy --path "$RAIZ/godot" --resolution 1920x1080 \
    res://estudos/direcao/estudo.tscn > "$pasta/$q.log" 2>&1
  grep -hE "SCRIPT ERROR|ERROR:|foto:" "$pasta/$q.log" | head -5
done
