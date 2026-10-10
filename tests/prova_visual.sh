#!/usr/bin/env bash
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
source "$RAIZ/scripts/engine.sh"
GODOT="$FORJA_GODOT"
[ -x "$GODOT" ] || { echo "sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>"; exit 2; }
command -v xvfb-run > /dev/null || { echo "sem xvfb-run (o pacote xvfb)"; exit 2; }

TMP="$(mktemp -d /tmp/forja-prova-visual-XXXXXX)"
SAIDA_PEDIDA="${1:-}"
trap 'rm -rf "$TMP"' EXIT

source "$RAIZ/tests/caixa.sh"
caixa_montar "$TMP"
printf 'Sink #593\n\tName: no_do_radio_000001\n\tDescription: Alto-falante do Controle 1 (DualSense Wireless Controller)\n\tSample Specification: s16le 2ch 48000Hz\n' > "$TMP/sinks"
export SERVIDOR_DE_MENTIRA="$TMP/sinks"

RES="${RES:-640x360}"
GODOT_JANELA=(--rendering-driver opengl3 --audio-driver Dummy --path "$RAIZ/godot" --resolution "$RES")
if [ "${NA_TELA:-0}" = 1 ]; then
  CAIXA_LIGAR="$(echo /dev/dri /dev/nvidia*)"
  export CAIXA_LIGAR
  JANELA=()
else
  JANELA=(env -u WAYLAND_DISPLAY xvfb-run -a -s "-screen 0 ${RES}x24")
  GODOT_JANELA+=(--display-driver x11)
fi

if [ "${1:-}" = "--autoteste" ]; then
  caixa "$GODOT" --headless --path "$RAIZ/godot" res://testes/prova_visual.tscn -- --autoteste --simular=1 --saida="$TMP/autoteste"
  exit $?
fi

if [ -n "$SAIDA_PEDIDA" ]; then
  SAIDA="$(realpath -m "$SAIDA_PEDIDA")"
else
  SAIDA="$TMP/saida"
fi
mkdir -p "$SAIDA"
caixa "$GODOT" --headless --path "$RAIZ/godot" --import --quit > "$TMP/import.log" 2>&1

PARTIDAS_TODAS=(
  "1|4|bom|5|"
  "2|4|ruim|5|"
  "3|2|medio|3|"
  "4|1|medio|3|--cabo"
  "5|4|medio|3||FORJA_IDIOMA=en FORJA_TEXTO=grande|en-grande"
  "6|4|medio|3||FORJA_TEXTO=grande|pt-grande"
)
FALHAS=0
: > "$SAIDA/checagens.txt"
for passada in ${PASSADAS:-fixa livre}; do
  case "$passada" in
    fixa) QUADROS=(--fixed-fps 60) ;;
    livre) QUADROS=() ;;
    reduzida) QUADROS=(--fixed-fps 60) ;;
    *) echo "passada desconhecida: $passada (fixa, reduzida ou livre)"; exit 2 ;;
  esac
  MOVIMENTO=()
  [ "$passada" = reduzida ] && MOVIMENTO=(--movimento=reduzido)
  for linha in "${PARTIDAS_TODAS[@]}"; do
    IFS='|' read -r n jogadores robo salas extra ambiente nome_da_prancha <<< "$linha"
    case " ${PARTIDAS:-1 2 3 4 5 6} " in *" $n "*) ;; *) continue ;; esac
    pasta="$SAIDA/$passada"
    rel="$TMP/relatorios-$passada-$n"
    mkdir -p "$pasta" "$rel"
    echo "==> partida $n ($passada): $jogadores jogador(es), robô $robo, $salas salas ${extra:+($extra)}${ambiente:+ ($ambiente)}"
    # shellcheck disable=SC2086
    timeout "${LIMITE_S:-3000}" env $ambiente "${JANELA[@]}" \
      "${CAIXA[@]}" "$GODOT" "${GODOT_JANELA[@]}" "${QUADROS[@]}" res://testes/prova_visual.tscn \
      -- --simular="$jogadores" --robo="$robo" --semente=7 --relatorios="$rel" --saida="$pasta" \
         --salas="$salas" --indice="$n" "${MOVIMENTO[@]}" $extra > "$pasta/partida-$n.log" 2>&1
    rc=$?
    if [ -n "${nome_da_prancha:-}" ]; then
      for png in "$pasta"/prancha-"$n".png "$pasta"/prancha-"$n"-*.png; do
        [ -f "$png" ] && mv "$png" "${png/prancha-$n/prancha-$nome_da_prancha}"
      done
    fi
    grep -E "SCRIPT ERROR|^ERROR|^FAIL" "$pasta/partida-$n.log" | head -5
    if [ -f "$pasta/checagens-$n.txt" ]; then
      { echo "=== passada $passada ==="; cat "$pasta/checagens-$n.txt"; echo; } >> "$SAIDA/checagens.txt"
      sed -n '1p;/REPROVADAS/,/^$/p' "$pasta/checagens-$n.txt" | head -30
    else
      echo "FAIL a partida $n ($passada) não chegou ao fim (rc=$rc); veja $pasta/partida-$n.log"
      tail -5 "$pasta/partida-$n.log"
    fi
    [ "$rc" -eq 0 ] || { echo "FAIL a partida $n ($passada) reprovou (rc=$rc)"; FALHAS=$((FALHAS + 1)); }
  done
done

for linha in "${PARTIDAS_TODAS[@]}"; do
  n="${linha%%|*}"
  [ -d "$TMP/relatorios-fixa-$n" ] && [ -d "$TMP/relatorios-livre-$n" ] || continue
  if python3 - "$n" "$TMP/relatorios-fixa-$n" "$TMP/relatorios-livre-$n" >> "$SAIDA/checagens.txt" <<'PY'
import glob, json, sys
n, fixa, livre = sys.argv[1:4]
def resultado(pasta):
    ev = []
    for arq in sorted(glob.glob(pasta + "/linha-do-tempo-*.jsonl")):
        ev += [json.loads(l) for l in open(arq, encoding="utf-8") if l.strip()]
    salas = [(e.get("slot"), e.get("vencedor")) for e in ev if e.get("tipo") == "minigame" and e.get("evento") == "terminou"]
    podio = [e.get("podio") for e in ev if e.get("evento") == "partida" and e.get("o") == "terminou"]
    return salas, podio
a, b = resultado(fixa), resultado(livre)
if a == b:
    print(f"partida {n}: a semente deu o mesmo resultado nas duas passadas ({a[0]}, pódio {a[1]})")
    sys.exit(0)
print(f"FAIL partida {n}: a mesma semente deu outro resultado sem --fixed-fps (fixa: {a[0]}, pódio {a[1]}; livre: {b[0]}, pódio {b[1]})")
sys.exit(1)
PY
  then
    tail -1 "$SAIDA/checagens.txt"
  else
    tail -1 "$SAIDA/checagens.txt"
    FALHAS=$((FALHAS + 1))
  fi
done

if [ -z "$SAIDA_PEDIDA" ]; then
  echo "(sem pasta pedida: as pranchas foram apagadas com a pasta temporária; passe uma pasta para guardá-las)"
fi
[ "$FALHAS" -eq 0 ] || { echo "prova visual: $FALHAS partida(s) reprovada(s)"; exit 1; }
echo "prova visual ok: as seis partidas, as pranchas e as checagens${SAIDA_PEDIDA:+ em $SAIDA_PEDIDA}"
