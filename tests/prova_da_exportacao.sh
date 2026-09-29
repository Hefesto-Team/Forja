#!/usr/bin/env bash
# A prova da exportação: o jogo exportado (scripts/exportar.sh), sem o editor,
# joga a Prova de Fogo inteira — as nove salas, na ordem — com quatro DualSense
# simulados e o robô. O binário Linux roda direto; o .exe roda pelo Wine, a
# base do Proton (sem o Wine, essa metade diz que não rodou e falha, a não ser
# com SO_LINUX=1).
#
# Cada um tem de fechar sozinho no fim (--sair-no-fim), com o relatório dos
# quatro lugares gravado, a sessão encerrada, a Prova de Fogo terminada na
# linha do tempo e nenhum "falhou"; e os dois têm de medir a mesma matriz.
#
# Uso: bash tests/prova_da_exportacao.sh      (depois de scripts/exportar.sh tudo)
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$RAIZ/dist"
LINUX="$DIST/forja-linux-x86_64/forja.x86_64"
WINDOWS="$DIST/forja-windows-x86_64/forja.exe"
TMP="$(mktemp -d /tmp/forja-prova-da-exportacao-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

[ -x "$LINUX" ] || { echo "sem $LINUX: rode scripts/exportar.sh linux"; exit 2; }

# Numa prova o jogo não tem de achar controle de verdade (ver prova_do_jogo.sh).
CAIXA=()
if command -v bwrap > /dev/null; then
  CAIXA=(bwrap --dev-bind / / --dev /dev --tmpfs /run/udev --tmpfs /sys/class/input
         --tmpfs /sys/class/hidraw)
fi
ARGS=(--headless --fixed-fps 60 -- --simular=4 --robo --semente=7 --prova-de-fogo --sair-no-fim)

FALHAS=0
falha() { echo "FAIL $*"; FALHAS=$((FALHAS + 1)); }

# $1 = nome, $2 = a pasta dos relatórios, $3 = a plataforma que o relatório tem de dizer
conferir() {
  python3 - "$@" <<'PY'
import glob, json, sys
nome, pasta, plataforma = sys.argv[1:4]
def falha(msg):
    print(f"FAIL {nome}: {msg}")
    sys.exit(1)
arqs = glob.glob(pasta + "/relatorio-*.json")
if len(arqs) != 1:
    falha(f"{len(arqs)} relatórios JSON (tinha de ser 1)")
r = json.load(open(arqs[0], encoding="utf-8"))
s = r["sessao"]
if plataforma not in s["plataforma"]:
    falha(f"a plataforma do relatório é «{s['plataforma']}»")
if not s["fim"]:
    falha("a sessão não fechou (o relatório não tem fim)")
if len(r["controles"]) != 4:
    falha(f"{len(r['controles'])} controles no relatório")
linhas = glob.glob(pasta + "/linha-do-tempo-*.jsonl")
fim = False
for arq in linhas:
    for l in open(arq, encoding="utf-8"):
        e = json.loads(l)
        if e.get("evento") == "prova_de_fogo" and e.get("o") == "terminou":
            fim = True
if not fim:
    falha("a Prova de Fogo não terminou na linha do tempo")
conta = {}
for m in r["matriz"]:
    conta[m["resultado"]] = conta.get(m["resultado"], 0) + 1
if conta.get("falhou", 0):
    falhas = [f"P{m['jogador']} {m['feature']}" for m in r["matriz"] if m["resultado"] == "falhou"]
    falha("falhou: " + ", ".join(falhas))
if not conta.get("passou", 0):
    falha("nada passou")
with open(pasta + "/matriz.txt", "w", encoding="utf-8") as f:
    for m in r["matriz"]:
        f.write(f"P{m['jogador']} {m['feature']} {m['resultado']}\n")
print(f"    {nome}: {s['plataforma']}, versão {s['versao_do_jogo']}, SDL {s['sdl']}; "
      f"{conta.get('passou', 0)} passou, {conta.get('não medido', 0)} não medido, 0 falhou; "
      "a Prova de Fogo terminou e a sessão fechou")
PY
}

echo "==> o binário Linux exportado: a Prova de Fogo com o robô"
mkdir -p "$TMP/linux"
timeout 900 "${CAIXA[@]}" "$LINUX" "${ARGS[@]}" --relatorios="$TMP/linux" > "$TMP/linux.log" 2>&1
rc=$?
grep -E "SCRIPT ERROR|^ERROR" "$TMP/linux.log" | head -20
if [ "$rc" -ne 0 ]; then
  tail -n 40 "$TMP/linux.log"
  falha "o binário Linux saiu com $rc"
else
  conferir linux "$TMP/linux" Linux || FALHAS=$((FALHAS + 1))
fi

echo "==> o que vai junto: as licenças nos dois pacotes, o ícone e o .desktop no Linux"
for f in "$DIST/forja-linux-x86_64/LICENCAS.txt" "$DIST/forja-windows-x86_64/LICENCAS.txt"; do
  if [ -f "$(dirname "$f")/forja.pck" ] || [ -f "$(dirname "$f")/forja.x86_64" ]; then
    grep -q "Godot Engine" "$f" 2> /dev/null && grep -q "Sam Lantinga" "$f" && grep -q "Open Font License" "$f" \
      || falha "$(basename "$(dirname "$f")"): LICENCAS.txt sem o Godot, o SDL ou as fontes"
  fi
done
[ -s "$DIST/forja-linux-x86_64/forja.png" ] && grep -q "^Exec=forja.x86_64" "$DIST/forja-linux-x86_64/forja.desktop" \
  || falha "o Linux sem o ícone ou sem o .desktop"

APPIMAGE="$DIST/FORJA-x86_64.AppImage"
if [ -f "$APPIMAGE" ]; then
  echo "==> o AppImage: a mesma Prova de Fogo"
  mkdir -p "$TMP/appimage"
  chmod +x "$APPIMAGE"
  APPIMAGE_EXTRACT_AND_RUN=1 timeout 900 "${CAIXA[@]}" "$APPIMAGE" "${ARGS[@]}" --relatorios="$TMP/appimage" > "$TMP/appimage.log" 2>&1
  rc=$?
  if [ "$rc" -ne 0 ]; then
    tail -n 40 "$TMP/appimage.log"
    falha "o AppImage saiu com $rc"
  elif conferir appimage "$TMP/appimage" Linux; then
    diff -u "$TMP/linux/matriz.txt" "$TMP/appimage/matriz.txt" > /dev/null || falha "o AppImage mediu outra matriz"
  else
    FALHAS=$((FALHAS + 1))
  fi
fi

if [ -f "$WINDOWS" ]; then
  echo "==> o ícone e a versão do .exe"
  recursos="$(python3 "$RAIZ/scripts/icone_do_exe.py" --conferir "$WINDOWS")"
  echo "$recursos" | sed 's/^/    /'
  echo "$recursos" | grep -q "^ícone: 256 .* 16$" || falha "o .exe não tem o ícone do FORJA"
  echo "$recursos" | grep -q "^ProductName: Forja$" || falha "o .exe não tem a versão do FORJA"
fi

echo "==> o .exe exportado, pelo Wine: a mesma Prova de Fogo"
if ! command -v wine > /dev/null; then
  if [ "${SO_LINUX:-0}" = 1 ]; then
    echo "    sem o Wine: o .exe não rodou (SO_LINUX=1)"
  else
    falha "sem o Wine, o .exe não rodou (instale o wine, ou SO_LINUX=1 para só o Linux)"
  fi
elif [ ! -f "$WINDOWS" ]; then
  falha "sem $WINDOWS: rode scripts/exportar.sh windows"
else
  export WINEPREFIX="$TMP/wine" WINEDEBUG=-all WINEDLLOVERRIDES="mscoree,mshtml="
  "${CAIXA[@]}" wineboot --init > "$TMP/wineboot.log" 2>&1
  mkdir -p "$TMP/windows"
  rel="$(winepath -w "$TMP/windows" 2> /dev/null)"
  timeout 1500 "${CAIXA[@]}" wine "$WINDOWS" "${ARGS[@]}" --relatorios="$rel" > "$TMP/windows.log" 2>&1
  rc=$?
  wineserver -w 2> /dev/null
  grep -E "SCRIPT ERROR|^ERROR" "$TMP/windows.log" | head -20
  if [ "$rc" -ne 0 ]; then
    tail -n 40 "$TMP/windows.log"
    for log in "$WINEPREFIX"/drive_c/users/*/AppData/Roaming/Godot/app_userdata/*/logs/godot.log; do
      [ -f "$log" ] && tail -n 40 "$log"
    done
    falha "o .exe saiu com $rc"
  elif conferir windows "$TMP/windows" Windows; then
    if [ -f "$TMP/linux/matriz.txt" ] && ! diff -u "$TMP/linux/matriz.txt" "$TMP/windows/matriz.txt"; then
      falha "o Linux e o Windows mediram matrizes diferentes"
    fi
  else
    FALHAS=$((FALHAS + 1))
  fi
fi

[ "$FALHAS" -eq 0 ] || exit 1
echo "prova da exportação ok — o jogo exportado, sem o editor, joga a Prova de Fogo inteira e mede o mesmo nos dois sistemas"
