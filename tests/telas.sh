#!/usr/bin/env bash
# As telas do jogo, fotografadas e comparadas (o Sprint E): a tela virtual
# (Xvfb) e o OpenGL por software; o roteiro do godot/testes/captura_jogo.gd.
#
#   bash tests/telas.sh fotos <pasta>                      o título, os créditos, o lobby,
#                                                          as opções, A Centelha e a partida
#   bash tests/telas.sh comparar <antes> <depois> <saída>  a diferença de cada tela e as
#                                                          pranchas de daltonismo
#
# A comparação só relata: o 3D por software muda um pouco de máquina para
# máquina. LIMITE=<%> faz reprovar acima dele.
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-$RAIZ/tools/Godot_v4.4.1-stable_linux.x86_64}"
[ -x "$GODOT" ] || { echo "sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>"; exit 2; }

fotos() {
  local pasta
  pasta="$(realpath -m "$1")"
  mkdir -p "$pasta"
  "$GODOT" --headless --path "$RAIZ/godot" --import --quit > /dev/null 2>&1
  local rel
  rel="$(mktemp -d)"
  roteiro() { # $1 = ROTEIRO, depois as variáveis e os argumentos
    local r="$1"
    shift
    env SAIDA="$pasta" ROTEIRO="$r" RAPIDO=1 "$@" timeout 900 xvfb-run -a -s "-screen 0 1920x1080x24" \
      "$GODOT" --rendering-driver opengl3 --fixed-fps 60 --path "$RAIZ/godot" --resolution 1920x1080 \
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
  fotos) fotos "$2" ;;
  comparar) comparar "$2" "$3" "$4" ;;
  *) echo "uso: $0 fotos <pasta> | comparar <antes> <depois> <saída>"; exit 2 ;;
esac
