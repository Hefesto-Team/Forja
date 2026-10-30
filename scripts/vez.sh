#!/usr/bin/env bash
set -u
uso() {
  cat <<'FIM'
O semáforo da máquina: roda o comando quando houver vaga, para que as provas pesadas não briguem pela CPU e pela memória.

Uso: scripts/vez.sh <comando...>
  VEZ_N       o número de vagas (padrão 4)
  VEZ_SONDA   segundos entre uma olhada e outra nas vagas (padrão 2)
As vagas são travas flock em ${XDG_RUNTIME_DIR:-/tmp}/forja-vez/<n>.lock; a trava solta quando o comando acaba.
Sai com o código do comando.
FIM
}
case "${1:-}" in
  "" | -h | --ajuda) uso; [ $# -eq 0 ] && exit 2; exit 0 ;;
esac
N="${VEZ_N:-4}"
SONDA="${VEZ_SONDA:-2}"
case "$N" in
  "" | *[!0-9]* | 0) echo "vez: VEZ_N tem de ser um inteiro maior que zero (veio «$N»)" >&2; exit 2 ;;
esac
command -v flock > /dev/null || { echo "vez: falta o flock (util-linux)" >&2; exit 2; }
DIR="${XDG_RUNTIME_DIR:-/tmp}/forja-vez"
mkdir -p "$DIR" || exit 2
while :; do
  for ((i = 1; i <= N; i++)); do
    exec {fd}> "$DIR/$i.lock" || exit 2
    if flock -n "$fd"; then
      "$@"
      exit $?
    fi
    exec {fd}>&-
  done
  sleep "$SONDA"
done
