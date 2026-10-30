#!/usr/bin/env bash
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
source "$RAIZ/scripts/engine.sh"
GODOT="$FORJA_GODOT"
[ -x "$GODOT" ] || { echo "sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>"; exit 2; }
source "$RAIZ/tests/caixa.sh"
caixa_pasta prova-do-fluxo; TMP="$CAIXA_PASTA"
caixa_montar "$TMP"
FOTOS="$(realpath -m "${1:-$TMP/fotos}")"

caixa "$GODOT" --headless --path "$RAIZ/godot" --import --quit > "$TMP/import.log" 2>&1

rodar() {
  local n="$1"
  local robo="--robo"
  local nome="${SALA:-centelha}-$n"
  [ "${2:-}" = sem-robo ] && { robo=""; nome="$nome-sem-robo"; }
  local pasta="$FOTOS/$nome"
  mkdir -p "$pasta" "$TMP/rel-$nome" "$TMP/dados-$nome"
  env XDG_DATA_HOME="$TMP/dados-$nome" SAIDA="$pasta" RAPIDO=1 JOGADORES="$n" timeout 1500 xvfb-run -a -s "-screen 0 1920x1080x24" \
    caixa "$GODOT" --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --path "$RAIZ/godot" --resolution 1920x1080 \
    res://testes/fluxo_inteiro.tscn -- --simular="$n" $robo --semente=7 --relatorios="$TMP/rel-$nome" > "$pasta/log.txt" 2>&1
  local rc=$?
  grep -E "FALHOU|SCRIPT ERROR|o fim com" "$pasta/log.txt"
  local juizo=0
  caixa_julgar "$pasta/log.txt" || juizo=1
  [ "$rc" -eq 0 ] && grep -q "chegou: o fim com" "$pasta/log.txt" || { echo "FAIL o fluxo $nome (rc=$rc)"; return 1; }
  return "$juizo"
}

FALHAS=0
for n in ${QUANTOS:-1 2 4}; do
  rodar "$n" || FALHAS=$((FALHAS + 1))
done
rodar 1 sem-robo || FALHAS=$((FALHAS + 1))
[ "$FALHAS" -eq 0 ] || exit 1
echo "prova do fluxo ok — do título ao salão, a sala jogada até o resultado e a volta, com ${QUANTOS:-1 2 4} controle(s) e com 1 sem o robô; fotos em $FOTOS"
