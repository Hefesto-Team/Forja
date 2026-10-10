#!/usr/bin/env bash
# A prova visual (F09): quatro partidas do título ao pódio, pelo fluxo que o
# jogador percorre, com controles simulados e o robô de cada temperamento. A
# cada 2 s de jogo guarda um quadro; no fim de cada partida monta a prancha
# (grade de 6 colunas, a hora embaixo de cada quadro) e roda as checagens
# (tela parada, tela vazia, texto encavalado ou fora da área segura, relógio
# que sobe, fim sem vencedor, frase com minúscula) sobre TODOS os quadros.
#
#   bash tests/prova_visual.sh [pasta]     a pasta fica com as pranchas e as checagens
#                                          (sem ela: uma pasta temporária, apagada no fim)
#   PASSADAS="fixa livre"                  fixa = --fixed-fps 60 (a da sessão); livre = sem
#                                          --fixed-fps (a do André: dura o tempo real, uns 15
#                                          minutos por partida, e mostra as travadas);
#                                          reduzida = a fixa com o movimento Reduzido (G16):
#                                          a espera mexe menos, mas não para (F09d)
#   PARTIDAS="1 3"                         só estas das quatro
#   RES=1280x720                           o tamanho da janela (padrão 640x360: no Xvfb, a
#                                          1280x720 a passada fixa fica duas vezes mais lenta)
#   NA_TELA=1                              sem Xvfb: a janela abre NA TELA de quem roda, com a
#                                          placa de vídeo (a passada livre da máquina do André);
#                                          sem isso, o OpenGL é por software
#   bash tests/prova_visual.sh --autoteste só confere que cada checagem reprova o seu defeito
#
# As quatro: 1) 4 jogadores, robô bom, partida de 5; 2) 4 jogadores, robô ruim,
# partida de 5; 3) 2 jogadores, robô médio, partida de 3; 4) 1 jogador, robô
# médio, partida de 3, com o controle que cai no meio do segundo minigame e
# volta no terceiro.
#
# Precisa de janela: roda no Xvfb com OpenGL por software (o --headless não
# devolve imagem), e nenhuma janela abre na tela de ninguém (só com NA_TELA=1).
# Com as duas passadas, a mesma semente tem de dar o mesmo resultado (quem
# venceu cada minigame e o pódio); se não der, é defeito do jogo. O jogo roda
# sempre com controles simulados e dentro da caixa (bwrap): num /dev novo, sem
# hidraw nem input, ele não acha o controle ligado na máquina. Aparência (luz,
# cor, brilho, arte) NÃO se aprova aqui: o renderizador por software não é a
# placa de vídeo; a aparência é de quem olha as pranchas na máquina de verdade.
#
# Precisa do módulo compilado (scripts/compilar.sh linux).
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
source "$RAIZ/scripts/engine.sh"   # a versão da engine mora lá (ADR-009)
GODOT="$FORJA_GODOT"
[ -x "$GODOT" ] || { echo "sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>"; exit 2; }
command -v xvfb-run > /dev/null || { echo "sem xvfb-run (o pacote xvfb)"; exit 2; }

TMP="$(mktemp -d /tmp/forja-prova-visual-XXXXXX)"
SAIDA_PEDIDA="${1:-}"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/sys-vazio"

# o servidor de som é de mentira, como na prova do jogo: nada toca no som da máquina
cat > "$TMP/bin/pactl" <<'PACTL'
#!/usr/bin/env bash
[ "$*" = "list sinks" ] && cat "$SERVIDOR_DE_MENTIRA"
exit 0
PACTL
printf '#!/usr/bin/env bash\ncat > /dev/null\nexit 0\n' > "$TMP/bin/pw-cat"
chmod +x "$TMP/bin/pactl" "$TMP/bin/pw-cat"
export PATH="$TMP/bin:$PATH"
export FORJA_SYSFS="$TMP/sys-vazio"
printf 'Sink #593\n\tName: no_do_radio_000001\n\tDescription: Alto-falante do Controle 1 (DualSense Wireless Controller)\n\tSample Specification: s16le 2ch 48000Hz\n' > "$TMP/sinks"
export SERVIDOR_DE_MENTIRA="$TMP/sinks"
[ "$(command -v pactl)" = "$TMP/bin/pactl" ] || { echo "GUARDA: pactl não é o de mentira"; exit 1; }

# a caixa é obrigatória: sem ela o jogo veria o DualSense ligado na máquina
command -v bwrap > /dev/null || { echo "sem bwrap: a prova visual não roda fora da caixa (o controle da máquina fica de fora)"; exit 2; }
CAIXA=(bwrap --dev-bind / / --dev /dev --tmpfs /run/udev --tmpfs /sys/class/input --tmpfs /sys/class/hidraw)

RES="${RES:-640x360}"
GODOT_JANELA=(--rendering-driver opengl3 --audio-driver Dummy --path "$RAIZ/godot" --resolution "$RES")
if [ "${NA_TELA:-0}" = 1 ]; then
  # a placa de vídeo entra na caixa (o hidraw e o input continuam de fora)
  for d in /dev/dri /dev/nvidia*; do
    [ -e "$d" ] && CAIXA+=(--dev-bind "$d" "$d")
  done
  JANELA=()
else
  # o Xvfb, e o X11 à força: com o Wayland da sessão no ambiente, a janela não pode ir para a tela
  JANELA=(env -u WAYLAND_DISPLAY xvfb-run -a -s "-screen 0 ${RES}x24")
  GODOT_JANELA+=(--display-driver x11)
fi

if [ "${1:-}" = "--autoteste" ]; then
  "${CAIXA[@]}" "$GODOT" --headless --path "$RAIZ/godot" res://testes/prova_visual.tscn -- --autoteste --simular=1 --saida="$TMP/autoteste"
  exit $?
fi

if [ -n "$SAIDA_PEDIDA" ]; then
  SAIDA="$(realpath -m "$SAIDA_PEDIDA")"
else
  SAIDA="$TMP/saida"
fi
mkdir -p "$SAIDA"
"${CAIXA[@]}" "$GODOT" --headless --path "$RAIZ/godot" --import --quit > "$TMP/import.log" 2>&1

# indice | jogadores | robô | salas | extra
PARTIDAS_TODAS=(
  "1|4|bom|5|"
  "2|4|ruim|5|"
  "3|2|medio|3|"
  "4|1|medio|3|--cabo"
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
    IFS='|' read -r n jogadores robo salas extra <<< "$linha"
    case " ${PARTIDAS:-1 2 3 4} " in *" $n "*) ;; *) continue ;; esac
    pasta="$SAIDA/$passada"
    rel="$TMP/relatorios-$passada-$n"
    mkdir -p "$pasta" "$rel"
    echo "==> partida $n ($passada): $jogadores jogador(es), robô $robo, $salas salas ${extra:+($extra)}"
    # shellcheck disable=SC2086
    timeout "${LIMITE_S:-3000}" "${JANELA[@]}" \
      "${CAIXA[@]}" "$GODOT" "${GODOT_JANELA[@]}" "${QUADROS[@]}" res://testes/prova_visual.tscn \
      -- --simular="$jogadores" --robo="$robo" --semente=7 --relatorios="$rel" --saida="$pasta" \
         --salas="$salas" --indice="$n" "${MOVIMENTO[@]}" $extra > "$pasta/partida-$n.log" 2>&1
    rc=$?
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

# a mesma semente nas duas passadas: o mesmo vencedor em cada minigame e o mesmo pódio
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
echo "prova visual ok: as quatro partidas, as pranchas e as checagens${SAIDA_PEDIDA:+ em $SAIDA_PEDIDA}"
