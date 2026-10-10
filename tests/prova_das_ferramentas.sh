#!/usr/bin/env bash
# A prova das ferramentas: as ferramentas que têm prova própria (--prova) e o baixador dos modelos de exportação,
# que quebravam em silêncio e só se descobria no dia de gerar a trilha ou exportar.
#
#   kenney             scripts/kenney.py --prova (sem o pacote, confere só as partes puras)
#   mapa_de_batidas    scripts/mapa_de_batidas.py --prova
#   trilha_fichas      scripts/trilha_fichas.py --prova
#   gerar_trilha       scripts/gerar_trilha.py --prova (o fluxo com o motor de mentira, sem rede e sem placa)
#   descrever_trilha   scripts/descrever_trilha.py --prova (sem rede e sem placa)
#   baixador           scripts/modelos_de_exportacao.py com um pacote feito na hora: a soma certa passa, a trocada
#                      sai diferente de 0 e não deixa arquivo
#   instalar           scripts/instalar.sh numa raiz falsa (um /sys, um /dev e um DESTDIR de mentira, e sudo, apt-get,
#                      dpkg e udevadm de mentira no PATH): o conferir acusa o DualSense sem a regra do udev, o
#                      sistema põe a regra e tira a antiga, e o desinstalar a tira
#
# Fica fora: scripts/bancada_tui.py --prova, que cai em «No module named 'textual'» antes de chegar à prova fora
# da oficina (o textual só existe lá). O scripts/conferir_ost.py já roda pela tests/prova_do_jogo.sh.
#
# Não precisa de Godot, e roda em segundos. Sai 0 com tudo verde e 1 quando qualquer uma falha.
# Uso: bash tests/prova_das_ferramentas.sh [nome ...]   (sem nome, todas; com nomes, só elas, para triar)
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/forja-prova-das-ferramentas-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
FALHAS=0
CASOS=0
TODAS=(kenney mapa_de_batidas trilha_fichas gerar_trilha descrever_trilha baixador instalar)
PEDIDAS=("$@")
[ "${#PEDIDAS[@]}" -eq 0 ] && PEDIDAS=("${TODAS[@]}")

for n in "${PEDIDAS[@]}"; do
  case " ${TODAS[*]} " in
    *" $n "*) ;;
    *) echo "prova_das_ferramentas: não conheço «$n» (conheço: ${TODAS[*]})" >&2; exit 2 ;;
  esac
done

pedida() {
  local n
  for n in "${PEDIDAS[@]}"; do [ "$n" = "$1" ] && return 0; done
  return 1
}

## espera <rc esperado> <o que> <comando...>
espera() {
  local quer="$1" oque="$2"; shift 2
  CASOS=$((CASOS + 1))
  (cd "$RAIZ" && "$@") > "$TMP/saida.log" 2>&1
  local rc=$?
  if [ "$rc" -eq "$quer" ]; then
    echo "ok   $oque"
  else
    echo "FAIL $oque (saiu $rc, esperava $quer)"
    sed 's/^/     | /' "$TMP/saida.log" | tail -n 8
    FALHAS=$((FALHAS + 1))
  fi
}

## confere <o que> <comando...>: passa quando o comando sai 0
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

## a prova própria de cada ferramenta
for f in kenney mapa_de_batidas trilha_fichas gerar_trilha descrever_trilha; do
  pedida "$f" || continue
  espera 0 "scripts/$f.py --prova" python3 "scripts/$f.py" --prova
done

## o baixador dos modelos: um pacote (um zip, como o .tpz) feito na hora, servido por file://
if pedida baixador; then
  python3 - "$TMP/pacote.tpz" > "$TMP/somas.txt" <<'FIM'
import hashlib, sys, zipfile
partes = {"linux_release.x86_64": b"o modelo Linux de mentira\n" * 64,
          "windows_release_x86_64.exe": b"o modelo Windows de mentira\n" * 64}
with zipfile.ZipFile(sys.argv[1], "w", zipfile.ZIP_DEFLATED) as z:
    for nome, dados in partes.items():
        z.writestr("templates/" + nome, dados)
for nome, dados in partes.items():
    print(nome, hashlib.sha256(dados).hexdigest())
FIM
  sha_linux="$(awk '$1 == "linux_release.x86_64" { print $2 }' "$TMP/somas.txt")"
  sha_windows="$(awk '$1 == "windows_release_x86_64.exe" { print $2 }' "$TMP/somas.txt")"
  sha_trocada="$(printf '%s' "$sha_linux" | tr '0-9a-f' '1-9a-f0')"

  espera 0 "o baixador aceita os modelos com a soma certa" \
    python3 scripts/modelos_de_exportacao.py "file://$TMP/pacote.tpz" "$TMP/certa" \
      "linux_release.x86_64=$sha_linux" "windows_release_x86_64.exe=$sha_windows"
  confere "os dois modelos saem na pasta, com o conteúdo do pacote" \
    bash -c '[ "$(sha256sum < "$1/linux_release.x86_64" | cut -d" " -f1)" = "$2" ] &&
             [ "$(sha256sum < "$1/windows_release_x86_64.exe" | cut -d" " -f1)" = "$3" ]' \
      _ "$TMP/certa" "$sha_linux" "$sha_windows"

  espera 1 "o baixador recusa o modelo com a soma trocada" \
    python3 scripts/modelos_de_exportacao.py "file://$TMP/pacote.tpz" "$TMP/errada" \
      "linux_release.x86_64=$sha_trocada"
  confere "a recusa é pela soma, e diz as duas" \
    grep -q "sha256 de linux_release.x86_64 não confere: $sha_linux (esperado $sha_trocada)" "$TMP/saida.log"
  confere "a soma trocada não deixa arquivo na pasta" \
    bash -c '[ -z "$(ls -A "$1" 2>/dev/null)" ]' _ "$TMP/errada"
fi

## o instalar e a regra do udev (WU03): nada toca o /sys, o /dev nem o /etc desta máquina
if pedida instalar; then
  echo "==> instalar: a regra do udev numa raiz falsa"
  F="$TMP/instalar"
  mkdir -p "$F/raiz/scripts" "$F/raiz/udev" "$F/bin" "$F/oficina" "$F/destino/etc/udev/rules.d" "$F/dev" \
    "$F/sys/class/hidraw/hidraw3/device" "$F/sys/class/hidraw/hidraw4/device"
  cp "$RAIZ/scripts/instalar.sh" "$RAIZ/scripts/requisitos-sistema.txt" "$F/raiz/scripts/"
  cp "$RAIZ"/udev/*-forja-dualsense.rules "$F/raiz/udev/"
  # os comandos de raiz são de mentira: anotam a chamada e não fazem nada
  for c in sudo apt-get dpkg udevadm nvidia-smi lspci; do
    printf '#!/bin/sh\necho "%s $*" >> "%s"\n[ "%s" = nvidia-smi ] && exit 1\nexit 0\n' "$c" "$F/chamadas" "$c" > "$F/bin/$c"
    chmod +x "$F/bin/$c"
  done
  echo "HID_ID=0003:0000054C:00000CE6" > "$F/sys/class/hidraw/hidraw3/device/uevent"   # o DualSense no cabo
  echo "HID_ID=0003:0000045E:00000B12" > "$F/sys/class/hidraw/hidraw4/device/uevent"   # um Xbox, que não conta
  : > "$F/dev/hidraw3"; : > "$F/dev/hidraw4"; chmod 0444 "$F/dev/hidraw3" "$F/dev/hidraw4"
  inst() { env PATH="$F/bin:$PATH" FORJA_OFICINA="$F/oficina" FORJA_SYSFS="$F/sys" FORJA_DEV="$F/dev" \
    bash "$F/raiz/scripts/instalar.sh" "$@"; }
  if [ "$(id -u)" -ne 0 ]; then
    inst conferir > "$F/conferir.log" 2>&1
    confere "o conferir acusa o DualSense sem escrita no hidraw" \
      grep -q "falta a regra do udev (os efeitos do controle): 1 DualSense" "$F/conferir.log"
  else
    echo "     (como root todo nó tem escrita: o caso do nó trancado fica de fora)"
  fi
  chmod 0666 "$F/dev/hidraw3"
  inst conferir > "$F/conferir.log" 2>&1
  confere "com escrita no hidraw, o conferir diz que os efeitos chegam" \
    grep -q "ok    1 DualSense com os efeitos" "$F/conferir.log"
  rm "$F/sys/class/hidraw/hidraw3/device/uevent"
  inst conferir > "$F/conferir.log" 2>&1
  confere "sem DualSense ligado e sem a regra, o conferir diz a falta" \
    grep -q "falta a regra do udev (os efeitos do controle); com um DualSense ligado" "$F/conferir.log"
  echo 'KERNEL=="hidraw*", MODE="0666"' > "$F/destino/etc/udev/rules.d/99-forja-dualsense.rules"
  : > "$F/chamadas"
  espera 0 "o sistema numa raiz falsa (DESTDIR) sai 0" env DESTDIR="$F/destino" PATH="$F/bin:$PATH" \
    FORJA_OFICINA="$F/oficina" bash "$F/raiz/scripts/instalar.sh" sistema
  confere "o sistema põe a regra em /etc/udev/rules.d, igual à do repositório" \
    cmp -s "$F/raiz/udev/70-forja-dualsense.rules" "$F/destino/etc/udev/rules.d/70-forja-dualsense.rules"
  confere "e tira a regra antiga, a do 0666" test ! -e "$F/destino/etc/udev/rules.d/99-forja-dualsense.rules"
  confere "e registra a regra para o desinstalar" \
    grep -qx "$F/destino/etc/udev/rules.d/70-forja-dualsense.rules" "$F/oficina/arquivos-do-sistema.txt"
  confere "com DESTDIR, ninguém chama o sudo nem o udevadm" bash -c '! grep -qE "^(sudo|udevadm) " "$1"' _ "$F/chamadas"
  confere "com a regra posta e nenhum DualSense, o conferir diz que ela está lá" \
    bash -c 'env DESTDIR="$1" PATH="$2:$PATH" FORJA_OFICINA="$3" FORJA_SYSFS="$4" bash "$5" conferir | grep -q "a regra do udev está instalada"' \
    _ "$F/destino" "$F/bin" "$F/oficina" "$F/sys" "$F/raiz/scripts/instalar.sh"
  espera 0 "o desinstalar numa raiz falsa sai 0" env DESTDIR="$F/destino" PATH="$F/bin:$PATH" \
    FORJA_OFICINA="$F/oficina" bash "$F/raiz/scripts/instalar.sh" desinstalar
  confere "o desinstalar tira a regra" test ! -e "$F/destino/etc/udev/rules.d/70-forja-dualsense.rules"
  : > "$F/chamadas"
  rm -f "$F/oficina/arquivos-do-sistema.txt"
  # sem DESTDIR, o sudo (de mentira) recebe a cópia e a recarga; o /etc desta máquina não é tocado
  if [ -e /etc/udev/rules.d/70-forja-dualsense.rules ]; then
    echo "     (esta máquina já tem a regra no /etc: o caso sem DESTDIR fica de fora)"
  else
    inst sistema > "$F/sistema.log" 2>&1
    confere "sem DESTDIR, a regra vai pelo sudo para /etc/udev/rules.d" \
      grep -q "^sudo install -m 0644 $F/raiz/udev/70-forja-dualsense.rules /etc/udev/rules.d/70-forja-dualsense.rules" "$F/chamadas"
    confere "e o udev recarrega as regras e reaplica no hidraw" \
      grep -q "^sudo udevadm trigger --subsystem-match=hidraw" "$F/chamadas"
  fi
fi

echo
if [ "$FALHAS" -eq 0 ]; then
  echo "prova das ferramentas ok — $CASOS casos (${PEDIDAS[*]})"
  exit 0
fi
echo "prova das ferramentas: $FALHAS de $CASOS casos falharam"
exit 1
