#!/usr/bin/env bash
# A prova do jogo, sem janela: o Godot --headless abre a cena inteira com
# quatro DualSense simulados (o módulo nativo, com o SDL3 dentro, roda todo) e
# confere o que cada controle simulado recebeu — player index, luz, lâmpadas,
# gatilhos, motores, LED do mudo — sala por sala, e o relatório gravado.
#
# O servidor de som é de mentira (pactl e pw-cat numa pasta temporária, na
# frente do PATH) e o sysfs é vazio (FORJA_SYSFS): com o nome que a Sony dá ao
# alto-falante na lista de som, o jogo acha o alto-falante; sem ele, diz que
# não achou (a mordida). Com o `bwrap` instalado, o jogo roda num /dev novo,
# sem hidraw nem input: numa prova ele não tem de achar controle de verdade.
#
# Precisa do módulo compilado (scripts/compilar.sh linux).
# Uso: bash tests/prova_do_jogo.sh        (GODOT=<binário> para outro Godot)
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-$RAIZ/tools/Godot_v4.4.1-stable_linux.x86_64}"
[ -x "$GODOT" ] || { echo "sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>"; exit 2; }
TMP="$(mktemp -d /tmp/forja-prova-do-jogo-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/sys-vazio"
cat > "$TMP/bin/pactl" <<'PACTL'
#!/usr/bin/env bash
[ "$*" = "list sinks" ] && cat "$SERVIDOR_DE_MENTIRA"
exit 0
PACTL
printf '#!/usr/bin/env bash\ncat > /dev/null\nexit 0\n' > "$TMP/bin/pw-cat"
chmod +x "$TMP/bin/pactl" "$TMP/bin/pw-cat"
export PATH="$TMP/bin:$PATH"
export FORJA_SYSFS="$TMP/sys-vazio"
[ "$(command -v pactl)" = "$TMP/bin/pactl" ] || { echo "GUARDA: pactl não é o de mentira"; exit 1; }

cat > "$TMP/forma-a" <<'SINKS'
Sink #40
	Name: alsa_output.pci-0000_0a_00.1.hdmi-stereo
	Description: HDA NVidia Digital Stereo (HDMI)
	Sample Specification: s32le 2ch 48000Hz
Sink #593
	Name: no_do_radio_000001
	Description: Alto-falante do Controle 1 (DualSense Wireless Controller)
	Sample Specification: s16le 2ch 48000Hz
SINKS
sed 's/ (DualSense Wireless Controller)$//' "$TMP/forma-a" > "$TMP/antes"

CAIXA=()
if command -v bwrap > /dev/null; then
  CAIXA=(bwrap --dev-bind / / --dev /dev --tmpfs /run/udev --tmpfs /sys/class/input
         --tmpfs /sys/class/hidraw)
fi

"${CAIXA[@]}" "$GODOT" --headless --path "$RAIZ/godot" --import --quit > "$TMP/import.log" 2>&1

FALHAS=0
rodar() {
  local rel="$TMP/relatorios-$1"
  mkdir -p "$rel"
  SERVIDOR_DE_MENTIRA="$TMP/$1" ESPERADO="$2" \
    timeout 1200 "${CAIXA[@]}" "$GODOT" --headless --fixed-fps 60 --path "$RAIZ/godot" res://testes/prova_do_jogo.tscn \
    -- --simular=4 --robo --semente=7 --relatorios="$rel" > "$TMP/$1.log" 2>&1
  local rc=$?
  grep -E "alto-falante do sistema|FAIL|SCRIPT ERROR|prova do jogo ok" "$TMP/$1.log"
  [ "$rc" -eq 0 ] || { echo "FAIL a prova com o servidor «$1» (rc=$rc)"; FALHAS=$((FALHAS + 1)); }
}
rodar forma-a "alto-falante: Alto-falante do Controle 1 (DualSense Wireless Controller)"
rodar antes "nenhum alto-falante de controle na lista (2 dispositivos)"
[ "$FALHAS" -eq 0 ] || exit 1
echo "prova do jogo ok — os quatro lugares, as salas e o relatório; com o nome da Sony o jogo acha o alto-falante, sem ele diz que não achou"
