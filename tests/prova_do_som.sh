#!/usr/bin/env bash
# Prova de ponta a ponta do forja-speak e do forja-read — sem servidor de som e
# sem aparelho: o `pactl` e o `pw-cat` são de mentira (numa pasta temporária,
# na frente do PATH) e a mesa é um sysfs de mentira (FORJA_SYSFS).
#
# GUARDA: se o `pactl` ou o `pw-cat` que o PATH achar não forem os daqui, nada
# roda — o PipeWire de quem estiver na máquina não é lugar de prova.
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
# a pasta temporária da caixa (tests/caixa.sh): esta prova não abre o Godot, e o pactl e o pw-cat são os daqui
source "$RAIZ/tests/caixa.sh"
caixa_pasta prova-do-som; TMP="$CAIXA_PASTA"   # no vermelho, a pasta fica em .cache/provas/ (WQ04)
mkdir -p "$TMP/bin"
FALHAS=0
falha() { echo "FAIL $*" >&2; FALHAS=$((FALHAS + 1)); }

cat > "$TMP/bin/pactl" <<'PACTL'
#!/usr/bin/env bash
[ "$*" = "list sinks" ] && cat "$SERVIDOR_DE_MENTIRA"
exit 0
PACTL
cat > "$TMP/bin/pw-cat" <<'PWCAT'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$PROVA_DIR/argv"
cat > "$PROVA_DIR/pcm"
exit 0
PWCAT
chmod +x "$TMP/bin/pactl" "$TMP/bin/pw-cat"
export PATH="$TMP/bin:$PATH"
export PROVA_DIR="$TMP"
[ "$(command -v pactl)" = "$TMP/bin/pactl" ] || { echo "GUARDA: pactl não é o de mentira"; exit 1; }
[ "$(command -v pw-cat)" = "$TMP/bin/pw-cat" ] || { echo "GUARDA: pw-cat não é o de mentira"; exit 1; }

# A mesa de mentira: um DualSense no cabo (hidraw3, com a placa dele) e um no rádio.
S="$TMP/sys"
mkdir -p "$S/devices/usb3/3-4/3-4:1.0/sound/card2" "$S/devices/usb3/3-4/3-4:1.3/0003:054C:0CE6.0001" \
         "$S/devices/usb1/1-2/1-2:1.0/bt/0005:054C:0CE6.0002" "$S/class/hidraw/hidraw3" "$S/class/hidraw/hidraw5"
echo 3 > "$S/devices/usb3/3-4/busnum"; echo 7 > "$S/devices/usb3/3-4/devnum"
echo 1 > "$S/devices/usb1/1-2/busnum"; echo 2 > "$S/devices/usb1/1-2/devnum"
printf 'HID_ID=0003:0000054C:00000CE6\n' > "$S/devices/usb3/3-4/3-4:1.3/0003:054C:0CE6.0001/uevent"
printf 'HID_ID=0005:0000054C:00000CE6\n' > "$S/devices/usb1/1-2/1-2:1.0/bt/0005:054C:0CE6.0002/uevent"
ln -s "$S/devices/usb3/3-4/3-4:1.3/0003:054C:0CE6.0001" "$S/class/hidraw/hidraw3/device"
ln -s "$S/devices/usb1/1-2/1-2:1.0/bt/0005:054C:0CE6.0002" "$S/class/hidraw/hidraw5/device"
export FORJA_SYSFS="$S"

export SERVIDOR_DE_MENTIRA="$TMP/sinks"
cat > "$SERVIDOR_DE_MENTIRA" <<'SINKS'
Sink #551
	Name: alsa_output.usb-Sony_Interactive_Entertainment_DualSense_Wireless_Controller-00.HiFi__Speaker__sink
	Description: DualSense wireless controller (PS5) Controller speaker and haptic motors
	Sample Specification: s16le 4ch 48000Hz
	Properties:
		device.bus = "usb"
		device.vendor.id = "0x054c"
		device.product.id = "0x0ce6"
		sysfs.path = "/devices/usb3/3-4/3-4:1.0/sound/card2"
Sink #593
	Name: no_do_radio_000002
	Description: Alto-falante do Controle 2 (DualSense Wireless Controller)
	Sample Specification: s16le 2ch 48000Hz
Sink #40
	Name: alsa_output.pci-0000_0a_00.1.hdmi-stereo
	Description: HDA NVidia Digital Stereo (HDMI)
	Sample Specification: s32le 2ch 48000Hz
SINKS

SPEAK="$RAIZ/bin/forja-speak"
READ="$RAIZ/bin/forja-read"
# O "player N" é a ordem do diretório, e ela não é a da criação: quem diz qual
# é o do cabo e qual é o do rádio é o forja-send --list, que só lê.
MESA="$("$RAIZ/bin/forja-send" --list)"
USB="$(awk '$4 == "usb" { print $2; exit }' <<< "$MESA")"
BT="$(awk '$4 == "bluetooth" { print $2; exit }' <<< "$MESA")"
[ -n "$USB" ] && [ -n "$BT" ] || { echo "GUARDA: a mesa de mentira não montou: $MESA"; exit 1; }

# --list: os dois, com o nome que o jogo mostra
LISTA="$("$SPEAK" --list)"
echo "$LISTA" | grep -q $'^alto-falante 0\talsa_output.usb-Sony' || falha "--list sem a placa: $LISTA"
echo "$LISTA" | grep -q $'\tAlto-falante do Controle 2 (DualSense Wireless Controller)\t2 canais\tpela lista$' \
  || falha "--list sem o nó do rádio pelo nome: $LISTA"
echo "$LISTA" | grep -q '^# 3 saídas no servidor, 2 de DualSense$' || falha "--list sem a conta: $LISTA"

# canal de cada linha do PCM: "c0 c1 c2 c3" -> quais canais têm som
canais_com_som() { od -An -v -t d2 -w$((2 * $1)) "$TMP/pcm" | awk -v n="$1" '
  { for (i = 1; i <= n; i++) if ($i != 0) som[i-1] = 1 }
  END { s = ""; for (i = 0; i < n; i++) if (som[i]) s = s i; print s }'; }

# --player (o do cabo): PELO APARELHO — a placa do mesmo USB, no canal 1 e só nele
"$SPEAK" --player "$USB" --ms 50 > "$TMP/saida" || falha "--player $USB rc=$?"
grep -q -- '--target=alsa_output.usb-Sony_Interactive_Entertainment_DualSense' "$TMP/argv" || falha "--player mirou outro nó"
grep -q -- '--channel-map=FL,FR,RL,RR' "$TMP/argv" || falha "--player sem o mapa de quatro canais"
[ "$(canais_com_som 4)" = "1" ] || falha "--player: o tom não saiu SÓ no canal 1 ($(canais_com_som 4))"

# --canal 0: a mordida de ouvido — o tom vai para o fone, e é o silêncio que prova
"$SPEAK" --player "$USB" --ms 50 --canal 0 > /dev/null || falha "--canal 0 rc=$?"
[ "$(canais_com_som 4)" = "0" ] || falha "--canal 0 não moveu o tom para o canal 0"

# --vcm: os dois atuadores, e o alto-falante calado
"$SPEAK" --player "$USB" --ms 50 --hz 60 --vcm > /dev/null || falha "--vcm rc=$?"
[ "$(canais_com_som 4)" = "23" ] || falha "--vcm: o tremor não ficou nos canais 2 e 3 ($(canais_com_som 4))"

# --nome: PELO NOME que o jogo mostra — o nó do rádio, de dois canais
"$SPEAK" --nome "Controle 2" --ms 50 > /dev/null || falha "--nome rc=$?"
grep -q -- '--target=no_do_radio_000002' "$TMP/argv" || falha "--nome mirou outro nó"
[ "$(canais_com_som 2)" = "1" ] || falha "--nome: o tom não saiu no FR do nó de dois canais"

# --nome pelo NOME do nó, que é o que um motor nativo lista (o Godot mostra o
# Name): o MESMO nó. A folha de teste do Hefesto aponta assim, uma coluna por
# controle — se isto cair, o botão do jogo dela diz «não achei» sobre um nó de pé.
"$SPEAK" --nome "no_do_radio_000002" --ms 50 > /dev/null || falha "--nome pelo nome do nó rc=$?"
grep -q -- '--target=no_do_radio_000002' "$TMP/argv" || falha "--nome pelo nome do nó mirou outro nó"

# as recusas têm rc próprio, e nenhuma toca nada
rm -f "$TMP/pcm"
"$SPEAK" --nome "Controle 2" --vcm > /dev/null 2>&1; [ $? -eq 4 ] || falha "--vcm num nó de dois canais tem de dar rc=4"
"$SPEAK" --nome "Controle 9" > /dev/null 2>&1; [ $? -eq 2 ] || falha "nome que não existe tem de dar rc=2"
"$SPEAK" --nome "hdmi-stereo" > /dev/null 2>&1; [ $? -eq 2 ] \
  || falha "apontar um nó sem a palavra da Sony tem de dar rc=2: o nome não fura a regra"
"$SPEAK" --player 7 > /dev/null 2>&1; [ $? -eq 2 ] || falha "player fora da mesa tem de dar rc=2"
"$SPEAK" --player "$BT" > /dev/null 2>&1; [ $? -eq 2 ] || falha "o do rádio não tem alto-falante pelo aparelho: rc=2"
[ ! -e "$TMP/pcm" ] || falha "uma recusa tocou alguma coisa"

# forja-read: dois 0x01 (parado: 1 g no Y, giro zero) e um 0x31 — lê dois e recusa
python3 - "$TMP/reports" <<'PY' 2>/dev/null || printf '' > "$TMP/reports"
import struct, sys
def rep(i, g, a):
    b = bytearray(64); b[0] = i
    struct.pack_into("<6h", b, 16, *g, *a)
    return bytes(b)
open(sys.argv[1], "wb").write(rep(1, (0, 0, 0), (0, -8192, 0)) * 2 + rep(0x31, (1, 1, 1), (1, 1, 1)))
PY
if [ -s "$TMP/reports" ]; then
  "$READ" "$TMP/reports" > "$TMP/imu" 2> "$TMP/imu.err"; RC=$?
  [ "$RC" -eq 3 ] || falha "forja-read tem de recusar o 0x31 com rc=3 (deu $RC)"
  [ "$(grep -c '^giro 0.0 0.0 0.0 graus/s | acel 0.000 -1.000 0.000 g$' "$TMP/imu")" -eq 2 ] \
    || falha "forja-read não leu os dois 0x01 parados: $(cat "$TMP/imu")"
  grep -q 'não fala o relatório 0x31' "$TMP/imu.err" || falha "forja-read recusou sem a frase"
fi
# e o pad do rádio é recusado ANTES de abrir o nó
"$READ" --player "$BT" > /dev/null 2> "$TMP/imu.err"; RC=$?
[ "$RC" -eq 3 ] || falha "forja-read abriu o pad do rádio (rc=$RC)"
grep -q 'não fala o relatório 0x31' "$TMP/imu.err" || falha "o rádio foi recusado sem a frase"

if [ "$FALHAS" -gt 0 ]; then
  echo "$FALHAS falha(s)" >&2
  exit 1
fi
echo "prova do som ok — pelo aparelho e pelo nome, o tom só no canal dele, as recusas com rc próprio"
