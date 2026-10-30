#!/usr/bin/env bash
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/forja-prova-do-devlog-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
FALHAS=0
CASOS=0

espera() {
  local quer="$1" oque="$2"; shift 2
  CASOS=$((CASOS + 1))
  "$@" > "$TMP/saida.log" 2>&1
  local rc=$?
  if [ "$rc" -eq "$quer" ]; then
    echo "ok   $oque"
  else
    echo "FAIL $oque (saiu $rc, esperava $quer)"
    sed 's/^/     | /' "$TMP/saida.log" | tail -n 8
    FALHAS=$((FALHAS + 1))
  fi
}

confere() {
  local oque="$1"; shift
  CASOS=$((CASOS + 1))
  if "$@"; then
    echo "ok   $oque"
  else
    echo "FAIL $oque"
    FALHAS=$((FALHAS + 1))
  fi
}

echo "==> vez.sh"
export XDG_RUNTIME_DIR="$TMP/run"
mkdir -p "$XDG_RUNTIME_DIR"
export VEZ_SONDA=0.1
vez_serial() {
  : > "$TMP/ordem"
  local i
  for i in 1 2 3; do
    VEZ_N=1 bash "$RAIZ/scripts/vez.sh" bash -c "echo ini$i >> '$TMP/ordem'; sleep 0.4; echo fim$i >> '$TMP/ordem'" &
  done
  wait
  awk '/^ini/ { if (aberto) exit 1; aberto = 1 } /^fim/ { aberto = 0 } END { exit NR != 6 }' "$TMP/ordem"
}
confere "vez: com uma vaga, os comandos não se sobrepõem" vez_serial
vez_paralelo() {
  local t0 t1
  t0="$(date +%s%N)"
  for i in 1 2 3; do VEZ_N=3 bash "$RAIZ/scripts/vez.sh" sleep 0.6 & done
  wait
  t1="$(date +%s%N)"
  [ $(((t1 - t0) / 1000000)) -lt 1500 ]
}
confere "vez: com três vagas, três comandos andam juntos" vez_paralelo
espera 7 "vez: devolve o código do comando" env VEZ_N=2 bash "$RAIZ/scripts/vez.sh" bash -c 'exit 7'
espera 2 "vez: VEZ_N inválido sai 2" env VEZ_N=abc bash "$RAIZ/scripts/vez.sh" true
espera 2 "vez: sem comando sai 2" bash "$RAIZ/scripts/vez.sh"
unset XDG_RUNTIME_DIR VEZ_SONDA

echo
if [ "$FALHAS" -eq 0 ]; then
  echo "prova do devlog ok — $CASOS casos"
  exit 0
fi
echo "prova do devlog: $FALHAS de $CASOS casos falharam"
exit 1
