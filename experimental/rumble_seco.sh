#!/usr/bin/env bash
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
LUGAR=0
PLAYER=""
RODADAS=1
SEMENTE=$$
ENSAIO=0
while (($#)); do
  case "$1" in
    --lugar) LUGAR="$2"; shift 2 ;;
    --player) PLAYER="$2"; shift 2 ;;
    --rodadas) RODADAS="$2"; shift 2 ;;
    --semente) SEMENTE="$2"; shift 2 ;;
    --ensaio) ENSAIO=1; shift ;;
    *) echo "uso: $0 [--lugar L] [--player N] [--rodadas R] [--semente S] [--ensaio]" >&2; exit 2 ;;
  esac
done
PLAYER="${PLAYER:-$LUGAR}"
RANDOM=$SEMENTE

FORCAS=(25 50 75 100)
DURACOES=(80 250 400)
PAUSA_ENTRE=1.5

pares=()
for ((r = 0; r < RODADAS; r++)); do
  for f in "${FORCAS[@]}"; do
    for d in "${DURACOES[@]}"; do
      if ((RANDOM % 2)); then pares+=("$f $d suave seco"); else pares+=("$f $d seco suave"); fi
    done
  done
done
for ((i = ${#pares[@]} - 1; i > 0; i--)); do
  j=$((RANDOM % (i + 1)))
  tmp="${pares[i]}"; pares[i]="${pares[j]}"; pares[j]="$tmp"
done

if ((ENSAIO)); then
  echo "ensaio: ${#pares[@]} pares (semente $SEMENTE), lugar $LUGAR, forja-send --player $PLAYER; nada é tocado"
  for p in "${pares[@]}"; do echo "  $p"; done
  exit 0
fi

SEND="$RAIZ/bin/forja-send"
source "$RAIZ/scripts/engine.sh"
GODOT="${GODOT:-$FORJA_GODOT}"
[[ -x "$SEND" ]] || { echo "sem o forja-send: make bin/forja-send" >&2; exit 2; }
[[ -x "$GODOT" ]] || { echo "sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>" >&2; exit 2; }
[[ -f "$RAIZ/godot/bin/libforja.linux.x86_64.so" ]] || { echo "sem o módulo: scripts/compilar.sh linux" >&2; exit 2; }

echo "Os controles que o forja-send acha (o índice é o do --player):"
"$SEND" --list
read -r -p "O controle do roteiro é o índice $PLAYER do forja-send e o lugar P$((LUGAR + 1)) do jogo? [Enter para seguir, Ctrl+C para sair] " _

mkdir -p "$RAIZ/relatorios"
ESTAMPA="$(date +%Y%m%d-%H%M%S)"
COMANDO="$RAIZ/relatorios/rumble-seco-$ESTAMPA.comando"
SAIDA="$RAIZ/relatorios/rumble-seco-$ESTAMPA.txt"
rm -f "$COMANDO" "$COMANDO.ok"
: > "$COMANDO.ok"

"$GODOT" --path "$RAIZ/godot" -- --experimento=forca --comando="$COMANDO" --relatorios="$RAIZ/relatorios" &
JOGO=$!
trap 'kill "$JOGO" 2>/dev/null || true' EXIT

mandar() {
  local antes
  antes=$(wc -l < "$COMANDO.ok")
  printf '%s\n' "$1" > "$COMANDO.tmp" && mv "$COMANDO.tmp" "$COMANDO"
  for _ in $(seq 1 "${2:-100}"); do
    [[ $(wc -l < "$COMANDO.ok") -gt $antes ]] && return 0
    sleep 0.2
  done
  echo "o jogo não respondeu a «$1»" >&2
  return 1
}

mandar "parar $LUGAR" 600
mandar "$LUGAR 0 20"
FW="$(tail -1 "$COMANDO.ok" | awk '{print $5}')"
echo "Firmware do controle: ${FW:-?}"

vibrar() {
  if [[ "$1" == suave ]]; then
    mandar "$LUGAR $(awk -v f="$2" 'BEGIN{printf "%.2f", f/100}') $3"
    sleep "$(awk -v ms="$3" 'BEGIN{printf "%.2f", ms/1000 + 0.1}')"
  else
    local b=$((255 * $2 / 100))
    "$SEND" --player "$PLAYER" --left "$b" --right "$b" --quiet
    sleep "$(awk -v ms="$3" 'BEGIN{printf "%.2f", ms/1000}')"
    "$SEND" --player "$PLAYER" --left 0 --right 0 --quiet
  fi
}

{
  echo "rumble seco · $(date +%F) · lugar P$((LUGAR + 1)) · forja-send --player $PLAYER · firmware ${FW:-?} · semente $SEMENTE"
} | tee "$SAIDA"

declare -A mais_forte_seco mais_forte_suave igual total
n=0
for p in "${pares[@]}"; do
  read -r f d primeiro segundo <<< "$p"
  n=$((n + 1))
  read -r -p "Par $n de ${#pares[@]}: feche os olhos e aperte Enter. " _
  echo "  1..." ; vibrar "$primeiro" "$f" "$d"
  sleep "$PAUSA_ENTRE"
  echo "  2..." ; vibrar "$segundo" "$f" "$d"
  while true; do
    read -r -p "  Qual sentiu mais forte? 1, 2 ou = (igual): " r
    case "$r" in 1|2|=) break ;; esac
  done
  case "$r" in
    1) venceu="$primeiro" ;;
    2) venceu="$segundo" ;;
    *) venceu="igual" ;;
  esac
  chave="$f"
  total[$chave]=$(( ${total[$chave]:-0} + 1 ))
  case "$venceu" in
    seco) mais_forte_seco[$chave]=$(( ${mais_forte_seco[$chave]:-0} + 1 )) ;;
    suave) mais_forte_suave[$chave]=$(( ${mais_forte_suave[$chave]:-0} + 1 )) ;;
    *) igual[$chave]=$(( ${igual[$chave]:-0} + 1 )) ;;
  esac
  echo "par · ${f}% · ${d} ms · ordem $primeiro,$segundo · mais forte: $venceu" >> "$SAIDA"
done

echo
echo "Agora a preferência, para três coisas que o jogo faz com a vibração:"
pref() {
  local r
  while true; do
    read -r -p "  Para «$1» (${2}%, $3 ms), prefere o suave (s), o seco (c) ou tanto faz (t)? " r
    case "$r" in s|c|t) break ;; esac
  done
  echo "preferência · $1 · $r" >> "$SAIDA"
  eval "PREF_$1=$r"
}
pref golpe 100 250
pref acerto 50 80
pref explosao 100 400

mandar "fim" || true
trap - EXIT

seco_alto=$(( ${mais_forte_seco[75]:-0} + ${mais_forte_seco[100]:-0} ))
total_alto=$(( ${total[75]:-0} + ${total[100]:-0} ))
if ((total_alto > 0 && seco_alto * 3 >= total_alto * 2)) && [[ "$PREF_golpe" == c && "$PREF_explosao" == c ]]; then
  VEREDITO="o seco venceu (mais forte em $seco_alto de $total_alto pares de 75% e 100%, e preferido para golpe e explosão)"
else
  VEREDITO="o suave basta (o seco foi mais forte em $seco_alto de $total_alto pares de 75% e 100%; preferência: golpe $PREF_golpe, explosão $PREF_explosao)"
fi

{
  echo "resultado · $VEREDITO"
  echo
  echo "Para colar em experimental/RESULTADOS.md (seção rumble-seco):"
  echo "| $(date +%F) | mesa (cabo), lugar P$((LUGAR + 1)) | firmware ${FW:-?} | $VEREDITO | semente $SEMENTE, $n pares; relatorios/rumble-seco-$ESTAMPA.txt |"
} | tee -a "$SAIDA"
