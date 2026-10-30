#!/usr/bin/env bash
set -uo pipefail
uso() {
  cat <<'FIM'
Monta antes/ e depois/ de uma entrada do devlog a partir de duas pastas de PNG.

Uso: scripts/devlog/pares.sh <png-antes> <png-depois> <pasta-da-entrada>
O par cuja diferença (compare -metric RMSE, normalizada) é menor que 0,01 é igual e sai dos dois lados.
A tela que só existe de um lado fica só nele. Cada foto vira JPEG de até 1280 px, qualidade 78, sem metadados.
Grava no cabeçalho da entrada: so_antes, so_depois e iguais.
Se a entrada passa de 5,5 MiB, recomprime os JPEG em qualidade menor (70, 62, 1120 px q62, 1024 px q58, 896 px q54) até caber.
Uso: scripts/devlog/pares.sh --apertar <pasta-da-entrada>   (só a recompressão, numa entrada que já existe)
FIM
}
TETO="${DEVLOG_TETO:-$((11 * 512 * 1024))}"
bytes() { find "$1/antes" "$1/depois" -type f -name '*.jpg' -printf '%s\n' 2> /dev/null | awk '{s += $1} END {print s + 0}'; }
apertar() {
  local pasta="$1" passo f q larg
  for passo in 70:1280 62:1280 62:1120 58:1024 54:896; do
    [ "$(bytes "$pasta")" -le "$TETO" ] && return 0
    q="${passo%%:*}"
    larg="${passo##*:}"
    for f in "$pasta"/antes/*.jpg "$pasta"/depois/*.jpg; do
      [ -f "$f" ] && convert "$f" -resize "${larg}x>" -strip -sampling-factor 4:2:0 -quality "$q" "$f"
    done
  done
  [ "$(bytes "$pasta")" -le "$TETO" ]
}
case "${1:-}" in
  -h | --ajuda) uso; exit 0 ;;
  --apertar) [ $# -eq 2 ] || { uso >&2; exit 2; }; apertar "$2" || { echo "pares: nem em 896 px q54 a entrada cabe em 5,5 MiB" >&2; exit 1; }; exit 0 ;;
esac
[ $# -eq 3 ] || { uso >&2; exit 2; }
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANTES="$1"
DEPOIS="$2"
SAIDA="$3"
LIMITE="${DEVLOG_LIMITE_IGUAL:-0.01}"
[ -f "$SAIDA/entrada.md" ] || { echo "pares: $SAIDA não é uma entrada (falta entrada.md)" >&2; exit 2; }
command -v convert > /dev/null && command -v compare > /dev/null || { echo "pares: falta o ImageMagick (convert e compare)" >&2; exit 2; }

nomes() {
  local d="$1"
  [ -d "$d" ] || return 0
  find "$d" -maxdepth 1 -type f -name '*.png' -printf '%f\n' | sed 's/\.png$//' | LC_ALL=C sort
}
jpeg() {
  convert "$1" -resize '1280x>' -strip -sampling-factor 4:2:0 -quality 78 "$2"
}
diferenca() {
  local out
  out="$(compare -metric RMSE "$1" "$2" null: 2>&1)"
  printf '%s' "$out" | sed -n 's/.*(\([0-9.eE+-]*\)).*/\1/p'
}

rm -rf "$SAIDA/antes" "$SAIDA/depois"
mkdir -p "$SAIDA/antes" "$SAIDA/depois"
so_antes=()
so_depois=()
iguais=0
pares=0
while IFS= read -r n; do
  [ -n "$n" ] || continue
  a="$ANTES/$n.png"
  d="$DEPOIS/$n.png"
  if [ -f "$a" ] && [ -f "$d" ]; then
    dif="$(diferenca "$a" "$d")"
    if [ -n "$dif" ] && awk -v x="$dif" -v l="$LIMITE" 'BEGIN { exit !(x + 0 < l + 0) }'; then
      iguais=$((iguais + 1))
      continue
    fi
    jpeg "$a" "$SAIDA/antes/$n.jpg" && jpeg "$d" "$SAIDA/depois/$n.jpg" || { echo "pares: o convert falhou em $n" >&2; exit 1; }
    pares=$((pares + 1))
  elif [ -f "$a" ]; then
    jpeg "$a" "$SAIDA/antes/$n.jpg" || exit 1
    so_antes+=("$n")
  else
    jpeg "$d" "$SAIDA/depois/$n.jpg" || exit 1
    so_depois+=("$n")
  fi
done < <({ nomes "$ANTES"; nomes "$DEPOIS"; } | LC_ALL=C sort -u)

apertar "$SAIDA" || { echo "pares: nem em 896 px q54 a entrada cabe em 5,5 MiB; fotografe menos roteiros" >&2; exit 1; }
juntar() { local IFS=,; echo "$*"; }
python3 "$AQUI/cabecalho.py" gravar "$SAIDA/entrada.md" "so_antes=$(juntar "${so_antes[@]+"${so_antes[@]}"}")" \
  "so_depois=$(juntar "${so_depois[@]+"${so_depois[@]}"}")" "iguais=$iguais"
echo "$pares par(es), $iguais igual(is) fora, ${#so_antes[@]} só do antes, ${#so_depois[@]} só do depois"
