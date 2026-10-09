#!/usr/bin/env bash
# O roteiro às cegas do rumble seco (F10, parte A): de olhos fechados, com UM
# DualSense no cabo, você sente pares de vibração na mesma força — um «suave»
# (o do jogo, pelo SDL) e um «seco» (o pacote antigo, pelo bin/forja-send) —,
# em ordem sorteada, e diz qual sentiu mais forte. No fim, qual prefere para
# golpe, acerto e explosão. O jogo não muda: o seco só existe aqui.
#
#   experimental/rumble_seco.sh                        o roteiro inteiro (uns 10 minutos)
#   experimental/rumble_seco.sh --lugar 1 --player 1   outro controle (lugar do jogo, índice do forja-send)
#   experimental/rumble_seco.sh --rodadas 2            cada par duas vezes, em outra ordem
#   experimental/rumble_seco.sh --semente 7            o mesmo sorteio
#   experimental/rumble_seco.sh --ensaio               só mostra o roteiro: não abre o jogo nem toca no controle
#   GODOT=<binário> experimental/rumble_seco.sh        outro Godot
#
# Antes: scripts/compilar.sh linux, make bin/forja-send, e o controle no CABO
# (o forja-send recusa o rádio de propósito). Troque de controle rodando de
# novo: um com firmware antigo, um novo e o Edge, se houver. O firmware de
# cada um vem do jogo e entra no resultado.
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

FORCAS=(25 50 75 100)   # em porcento
DURACOES=(80 250 400)   # em milissegundos
PAUSA_ENTRE=1.5         # segundos entre a primeira e a segunda vibração do par

# os pares, na ordem sorteada, cada um com a ordem dos dois modos sorteada
pares=()
for ((r = 0; r < RODADAS; r++)); do
  for f in "${FORCAS[@]}"; do
    for d in "${DURACOES[@]}"; do
      if ((RANDOM % 2)); then pares+=("$f $d suave seco"); else pares+=("$f $d seco suave"); fi
    done
  done
done
# embaralha (Fisher-Yates com o RANDOM semeado)
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
source "$RAIZ/scripts/engine.sh"   # a versão da engine mora lá (ADR-009)
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

mandar() {  # $1 o comando, $2 quantos décimos de segundo esperar a resposta (padrão 100)
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

# espera o jogo abrir (a primeira vez importa os recursos e demora: até 2 minutos)
mandar "parar $LUGAR" 600
mandar "$LUGAR 0 20"
FW="$(tail -1 "$COMANDO.ok" | awk '{print $5}')"
echo "Firmware do controle: ${FW:-?}"

vibrar() {  # $1 modo, $2 força em %, $3 ms
  if [[ "$1" == suave ]]; then
    mandar "$LUGAR $(awk -v f="$2" 'BEGIN{printf "%.2f", f/100}') $3"
    sleep "$(awk -v ms="$3" 'BEGIN{printf "%.2f", ms/1000 + 0.1}')"
  else
    local b=$((255 * $2 / 100))
    "$SEND" --player "$PLAYER" --left "$b" --right "$b" --quiet
    sleep "$(awk -v ms="$3" 'BEGIN{printf "%.2f", ms/1000}')"
    # parar o seco pelo mesmo forja-send: o pacote com os motores em zero sai sem
    # os bits de rumble, o mesmo jeito com que o SDL para o dele. Pelo jogo não
    # dá: o SDL_RumbleGamepad(0, 0) com o SDL já em zero não manda pacote nenhum
    # (SDL_joystick.c, «Just update the expiration»), e o seco seguiria vibrando.
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
pref() {  # $1 nome, $2 força, $3 ms
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

# a regra da ficha: o seco vence se, em pelo menos dois terços dos pares de 75% e 100%,
# foi sentido mais forte, E é o preferido para golpe e explosão
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
