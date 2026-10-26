#!/usr/bin/env bash
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
source "$RAIZ/scripts/engine.sh"
GODOT="$FORJA_GODOT"
[ -x "$GODOT" ] || { echo "sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>"; exit 2; }

fotos() {
  local pasta
  pasta="$(realpath -m "$1")"
  mkdir -p "$pasta"
  local rel
  rel="$(mktemp -d)"
  source "$RAIZ/tests/caixa.sh"
  caixa_montar "$rel/caixa"
  caixa "$GODOT" --headless --path "$RAIZ/godot" --import --quit > /dev/null 2>&1
  roteiro() {
    local r="$1"
    shift
    env SAIDA="$pasta" ROTEIRO="$r" RAPIDO=1 "$@" timeout 900 xvfb-run -a -s "-screen 0 1920x1080x24" \
      caixa "$GODOT" --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --path "$RAIZ/godot" --resolution 1920x1080 \
      res://testes/captura_jogo.tscn -- --simular=4 --semente=7 --relatorios="$rel" ${ROBO:-}
  }
  roteiro extras > "$pasta/extras.log" 2>&1
  ROBO=--robo roteiro salas SALAS=centelha FOTOS=centelha_aviso,centelha_fim > "$pasta/salas.log" 2>&1
  ROBO=--robo roteiro partida FOTOS=partida_escolha,partida_placar_1,partida_podio > "$pasta/partida.log" 2>&1
  rm -rf "$rel"
  local n
  n="$(ls "$pasta"/*.png 2> /dev/null | wc -l)"
  echo "$n foto(s) em $1"
  [ "$n" -ge 9 ] || { grep -hE "SCRIPT ERROR|não chegou" "$pasta"/*.log | head; exit 1; }
}

comparar() {
  mkdir -p "$3"
  "$GODOT" --headless -s "$RAIZ/scripts/comparar_telas.gd" -- "$(realpath -m "$1")" "$(realpath -m "$2")" \
    "$(realpath -m "$3")" ${LIMITE:-} | grep "|"
  local rc=${PIPESTATUS[0]}
  "$GODOT" --headless -s "$RAIZ/scripts/daltonismo.gd" -- "$(realpath -m "$2")" "$(realpath -m "$3")/daltonismo" | tail -1
  return "$rc"
}

case "${1:-}" in
  visual) shift; PASSADAS="${PASSADAS:-fixa}" exec bash "$RAIZ/tests/prova_visual.sh" "$@" ;;
  fotos) fotos "$2" ;;
  comparar) comparar "$2" "$3" "$4" ;;
  *) echo "uso: $0 visual <pasta> | fotos <pasta> | comparar <antes> <depois> <saída>"; exit 2 ;;
esac
