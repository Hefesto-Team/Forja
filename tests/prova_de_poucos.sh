#!/usr/bin/env bash
# A prova de poucos, sem janela: toda sala jogável com 1, 2 ou 3 controles
# (o robô joga as nove com N DualSense simulados, e cada sala diz no aviso o
# que muda), e a sala sem o recurso — com o microfone mudo no sistema
# (o defeito de mentira mic-surdo), A Voz segue sozinha e o veredito fica
# "não medido", nunca "falhou".
#
# Precisa do módulo compilado (scripts/compilar.sh linux).
# Uso: bash tests/prova_de_poucos.sh        (GODOT=<binário> para outro Godot)
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-$RAIZ/tools/Godot_v4.4.1-stable_linux.x86_64}"
[ -x "$GODOT" ] || { echo "sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>"; exit 2; }
TMP="$(mktemp -d /tmp/forja-prova-de-poucos-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

CAIXA=()
if command -v bwrap > /dev/null; then
  CAIXA=(bwrap --dev-bind / / --dev /dev --tmpfs /run/udev --tmpfs /sys/class/input
         --tmpfs /sys/class/hidraw)
fi
export FORJA_SYSFS="$TMP/sys-vazio"
mkdir -p "$FORJA_SYSFS"

"${CAIXA[@]}" "$GODOT" --headless --path "$RAIZ/godot" --import --quit > "$TMP/import.log" 2>&1

rodar() {
  local nome="$1"
  shift
  mkdir -p "$TMP/rel-$nome"
  "${CAIXA[@]}" "$GODOT" --headless --fixed-fps 60 --path "$RAIZ/godot" res://testes/prova_de_poucos.tscn \
    -- --robo --semente=7 --relatorios="$TMP/rel-$nome" "$@" > "$TMP/$nome.log" 2>&1
  local rc=$?
  grep -E "FAIL|SCRIPT ERROR|prova de poucos ok" "$TMP/$nome.log"
  [ "$rc" -eq 0 ] || { echo "FAIL a prova de poucos «$nome» (rc=$rc)"; return 1; }
}

FALHAS=0
rodar um --simular=1 & a=$!
rodar dois --simular=2 & b=$!
rodar tres --simular=3 & c=$!
for p in $a $b $c; do wait "$p" || FALHAS=$((FALHAS + 1)); done
SALAS=voz rodar mudo-no-sistema --simular=4 --defeitos=mic-surdo || FALHAS=$((FALHAS + 1))
[ "$FALHAS" -eq 0 ] || exit 1
echo "prova de poucos ok — as nove salas com 1, 2 e 3 controles, e A Voz com o microfone mudo no sistema"
