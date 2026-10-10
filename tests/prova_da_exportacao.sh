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
# O Wine é o de WINE e WINESERVER (o padrão é o do PATH); o CI usa o do
# GE-Proton, fixo por versão e sha256. O Wine 9.0 do Ubuntu 24.04 NÃO serve:
# o patch do Debian fixes/virtual-protect.patch faz o VirtualProtect do
# kernelbase.dll ler *old_prot sem conferir nulo, e o Godot 4.6+ passa nulo
# no construtor do OS_Windows (o gancho do dinput8, os_windows.cpp:2862 na tag
# 4.7.2-stable), antes do main do jogo: o .exe cai com 5, com ou sem a dll.
# O .exe roda com WINEDEBUG=+seh,+loaddll; se cair, a prova diz em que dll
# caiu e guarda os logs em dist/o-exe-no-wine/.
#
# Uso: bash tests/prova_da_exportacao.sh      (depois de scripts/exportar.sh tudo)
#      WINE=<wine> WINESERVER=<wineserver> bash tests/prova_da_exportacao.sh
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$RAIZ/dist"
LINUX="$DIST/forja-linux-x86_64/forja.x86_64"
WINDOWS="$DIST/forja-windows-x86_64/forja.exe"
WINE="${WINE:-wine}"
WINESERVER="${WINESERVER:-wineserver}"
[ -x "$LINUX" ] || { echo "sem $LINUX: rode scripts/exportar.sh linux"; exit 2; }

# Numa prova o jogo não tem de achar controle de verdade: a caixa (tests/caixa.sh).
source "$RAIZ/tests/caixa.sh"
caixa_pasta prova-da-exportacao; TMP="$CAIXA_PASTA"   # no vermelho, a pasta fica em .cache/provas/ (WQ04)
# o prefixo do Wine (centenas de MB) não vai para o .cache: os logs do .exe já vão para dist/o-exe-no-wine/
CAIXA_SEM_GUARDAR="wine"
caixa_montar "$TMP"
# o .exe leva o módulo do Windows: com o .exe exportado, a fonte dele também confere (tests/caixa.sh, a WQ03)
if [ -f "$WINDOWS" ]; then caixa_fonte libforja.windows.x86_64.dll; fi
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
formatos = set()
for arq in linhas:
    for l in open(arq, encoding="utf-8"):
        e = json.loads(l)
        if e.get("tipo") == "sessao" and "formato" in e:
            formatos.add(e["formato"])
        if e.get("evento") == "prova_de_fogo" and e.get("o") == "terminou":
            fim = True
if not fim:
    falha("a Prova de Fogo não terminou na linha do tempo")
conhecidos = {"hefesto-tech-demo/linha-do-tempo/1", "hefesto-tech-demo/linha-do-tempo/2"}
if not formatos or not formatos <= conhecidos:
    falha(f"o formato da linha do tempo é {sorted(formatos) or 'nenhum'}, e a prova lê as versões 1 e 2")
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

# $1 = nome, $2 = a pasta dos relatórios: a partida de 3 jogada pelo robô só
# pelo controle simulado (o ✕ do aviso e do placar) até o pódio. A linha do
# tempo diz as três salas, os três placares e o fim da partida (F08).
conferir_partida() {
  python3 - "$@" <<'PY'
import glob, json, sys
nome, pasta = sys.argv[1:3]
def falha(msg):
    print(f"FAIL {nome}: {msg}")
    sys.exit(1)
arqs = glob.glob(pasta + "/relatorio-*.json")
if len(arqs) != 1:
    falha(f"{len(arqs)} relatórios JSON (tinha de ser 1)")
if not json.load(open(arqs[0], encoding="utf-8"))["sessao"]["fim"]:
    falha("a sessão não fechou (o relatório não tem fim)")
ev = []
for arq in glob.glob(pasta + "/linha-do-tempo-*.jsonl"):
    ev += [json.loads(l) for l in open(arq, encoding="utf-8")]
def conta(e, o=None):
    return sum(1 for x in ev if x.get("evento") == e and (o is None or x.get("o") == o))
if conta("partida", "começou") != 1 or conta("partida", "terminou") != 1:
    falha("a partida não começou e terminou uma vez na linha do tempo")
if conta("partida", "placar") != 3 or conta("terminou") != 3:
    falha(f"{conta('partida', 'placar')} placares e {conta('terminou')} salas terminadas (tinham de ser 3 e 3)")
print(f"    {nome}: a partida de 3 foi do aviso ao pódio, só pelo controle simulado")
PY
}

# $1 = o log do .exe com +seh,+loaddll: diz o endereço da queda, a dll em que
# ele mora e as últimas dll carregadas antes dela.
onde_caiu() {
  python3 - "$1" <<'PY'
import re, sys
linhas = open(sys.argv[1], encoding="utf-8", errors="replace").read().splitlines()
re_dll = re.compile(r'Loaded L"([^"]+)" at ([0-9A-Fa-f]+): (\w+)')
re_fora = re.compile(r"Unhandled (.+?) at address (?:0x)?([0-9A-Fa-f]+)")
re_seh = re.compile(r"dispatch_exception code=([0-9A-Fa-f]+) .*addr=(?:0x)?([0-9A-Fa-f]+)")
dlls, seh, queda = [], [], None
for i, l in enumerate(linhas):
    m = re_dll.search(l)
    if m:
        dlls.append((int(m.group(2), 16), m.group(1), m.group(3), i))
    m = re_seh.search(l)
    if m:
        seh.append((m.group(1).lower(), int(m.group(2), 16), i))
    m = re_fora.search(l)
    if m and queda is None:
        end = int(m.group(2), 16)
        # O código é o da exceção no mesmo endereço, antes da linha do «Unhandled».
        cod = [c for c, e, j in seh if e == end and j < i]
        queda = (end, i, cod[-1] if cod else "?", m.group(1))
if queda is None:
    # Sem a linha do «Unhandled» (o timeout, por exemplo): a última leitura inválida.
    lidas = [(e, j) for c, e, j in seh if c == "c0000005"]
    if lidas:
        queda = lidas[-1] + ("c0000005", "acesso inválido à memória")
if queda is None:
    print("    sem queda de memória no log (nenhum c0000005)")
    sys.exit(0)
end, linha, cod, texto = queda
antes = [d for d in dlls if d[3] <= linha]
dono = max((d for d in antes if d[0] <= end), default=None)
if dono:
    nome = dono[1].replace(chr(92), "/").rsplit("/", 1)[-1]
    print(f"    a queda: {cod} ({texto}) em {end:016X}, {nome} + 0x{end - dono[0]:X} ({dono[2]})")
else:
    print(f"    a queda: {cod} ({texto}) em {end:016X}, fora de toda dll carregada")
print("    as últimas dll carregadas antes dela:")
for base, nome, tipo, _ in antes[-5:]:
    print(f"      {base:016X} {tipo:8} {nome.replace(chr(92) * 2, chr(92))}")
PY
}

echo "==> o binário Linux exportado: a Prova de Fogo com o robô"
mkdir -p "$TMP/linux"
timeout 900 caixa "$LINUX" "${ARGS[@]}" --relatorios="$TMP/linux" > "$TMP/linux.log" 2>&1
rc=$?
grep -E "SCRIPT ERROR|^ERROR" "$TMP/linux.log" | head -20
if [ "$rc" -ne 0 ]; then
  tail -n 40 "$TMP/linux.log"
  falha "o binário Linux saiu com $rc"
else
  conferir linux "$TMP/linux" Linux || FALHAS=$((FALHAS + 1))
fi

echo "==> o binário Linux exportado: uma partida de 3 jogada pelo robô, só pelo controle"
mkdir -p "$TMP/linux-partida"
timeout 900 caixa "$LINUX" --headless --fixed-fps 60 -- --simular=4 --robo --semente=7 --partida=3 --sair-no-fim \
  --relatorios="$TMP/linux-partida" > "$TMP/linux-partida.log" 2>&1
rc=$?
grep -E "SCRIPT ERROR|^ERROR" "$TMP/linux-partida.log" | head -20
if [ "$rc" -ne 0 ]; then
  tail -n 40 "$TMP/linux-partida.log"
  falha "o binário Linux saiu com $rc na partida"
else
  conferir_partida linux-partida "$TMP/linux-partida" || FALHAS=$((FALHAS + 1))
fi

echo "==> o que vai junto: as licenças nos dois pacotes, o ícone e o .desktop no Linux"
for f in "$DIST/forja-linux-x86_64/LICENCAS.txt" "$DIST/forja-windows-x86_64/LICENCAS.txt"; do
  if [ -f "$(dirname "$f")/forja.pck" ] || [ -f "$(dirname "$f")/forja.x86_64" ]; then
    grep -q "Godot Engine" "$f" 2> /dev/null && grep -q "Sam Lantinga" "$f" && grep -q "Open Font License" "$f" \
      || falha "$(basename "$(dirname "$f")"): LICENCAS.txt sem o Godot, o SDL ou as fontes"
  fi
done
[ -s "$DIST/forja-linux-x86_64/forja.png" ] && [ -x "$DIST/forja-linux-x86_64/instalar-atalho.sh" ] \
  || falha "o Linux sem o ícone ou sem o instalar-atalho.sh"

# O atalho do menu (a WU08): o instalar-atalho.sh escreve a entrada numa casa de
# mentira, com o caminho absoluto. Ela tem de passar no desktop-file-validate, e
# o Exec (desfeito como a especificação manda) e o Icon têm de apontar para o
# jogo e o ícone que existem. Duas vezes: na pasta do pacote e numa pasta com
# espaço, aspas, cifrão e porcento no nome (o jogo nela é um atalho do de verdade).
# $1 = a pasta, $2 = a casa
atalho() {
  env -u XDG_DATA_HOME HOME="$2" sh "$1/instalar-atalho.sh" > "$2.log" 2>&1 || { cat "$2.log"; return 1; }
  local d="$2/.local/share/applications/forja.desktop"
  if ! command -v desktop-file-validate > /dev/null; then
    echo "    sem o desktop-file-validate (desktop-file-utils): só o caminho foi conferido"
  elif ! desktop-file-validate "$d"; then
    return 1
  fi
  python3 - "$d" "$1" <<'PY'
import os, sys
arq, pasta = sys.argv[1:3]
campos = {}
for l in open(arq, encoding="utf-8"):
    if "=" in l and not l.startswith("["):
        k, v = l.rstrip("\n").split("=", 1)
        campos[k] = v
def geral(v):  # o escape de todo valor de texto
    tr = {"s": " ", "n": "\n", "t": "\t", "r": "\r", "\\": "\\"}
    out, i = "", 0
    while i < len(v):
        if v[i] == "\\" and i + 1 < len(v):
            out += tr.get(v[i + 1], v[i + 1]); i += 2
        else:
            out += v[i]; i += 1
    return out
def exec_args(v):  # as aspas do Exec: \" \` \$ \\ dentro das aspas, e %% vira %
    args, cur, i, dentro, tem = [], "", 0, False, False
    while i < len(v):
        c = v[i]
        if dentro and c == "\\" and i + 1 < len(v) and v[i + 1] in '"`$\\':
            cur += v[i + 1]; i += 2; continue
        if c == '"':
            dentro, tem = not dentro, True
        elif c == " " and not dentro:
            if cur or tem: args.append(cur)
            cur, tem = "", False
        elif c == "%" and v[i + 1:i + 2] == "%":
            cur += "%"; i += 1
        else:
            cur += c
        i += 1
    if cur or tem: args.append(cur)
    return args
args = exec_args(geral(campos.get("Exec", "")))
icone = geral(campos.get("Icon", ""))
erros = []
if not args or not os.path.isabs(args[0]) or not os.access(args[0], os.X_OK):
    erros.append(f"o Exec não aponta para um executável: {args}")
elif os.path.realpath(args[0]) != os.path.realpath(os.path.join(pasta, "forja.x86_64")):
    erros.append(f"o Exec aponta para outro lugar: {args[0]}")
if not os.path.isabs(icone) or not os.path.isfile(icone):
    erros.append(f"o Icon não aponta para um arquivo: {icone}")
for e in erros:
    print("    " + e)
sys.exit(1 if erros else 0)
PY
}
echo "==> o atalho do menu no Linux: o instalar-atalho.sh, numa casa de mentira"
mkdir -p "$TMP/casa" "$TMP/casa-esquisita"
atalho "$DIST/forja-linux-x86_64" "$TMP/casa" || falha "o atalho do menu não abre o jogo da pasta do pacote"
ESQUISITA="$TMP/a pasta \"do\" \$jogo 100%"
mkdir -p "$ESQUISITA"
for f in forja.x86_64 forja.png instalar-atalho.sh; do ln -s "$DIST/forja-linux-x86_64/$f" "$ESQUISITA/$f"; done
atalho "$ESQUISITA" "$TMP/casa-esquisita" || falha "o atalho do menu se perde numa pasta com espaço, aspas e cifrão"

# O que o LEIA-ME de cada sistema ensina (a WU08): o Steam Input nos dois, e o
# .exe aberto direto no do Windows.
echo "==> os LEIA-ME: o Steam Input, e o forja.exe aberto direto"
grep -q "Steam Input" "$DIST/forja-linux-x86_64/LEIA-ME.txt" || falha "o LEIA-ME do Linux não fala do Steam Input"
if [ -f "$WINDOWS" ]; then
  L="$DIST/forja-windows-x86_64/LEIA-ME.txt"
  grep -q "Steam Input" "$L" || falha "o LEIA-ME do Windows não fala do Steam Input"
  grep -q "^Abrindo o forja.exe" "$L" && grep -q "cabo" "$L" && grep -q "remapeiam" "$L" \
    && grep -q "não é assinado" "$L" || falha "o LEIA-ME do Windows sem a seção do forja.exe aberto direto"
fi

# O módulo que vai no pacote pede no máximo a glibc do Godot (a WU01): acima
# disso, o Godot abre num Ubuntu 22.04 ou num Debian 12 e o módulo não carrega.
# O do pacote sai do contêiner manylinux_2_28 do CI; o compilado numa máquina
# nova reprova aqui, de propósito.
echo "==> o módulo do pacote cabe no piso de glibc do Godot"
if piso="$(bash "$RAIZ/scripts/compilar.sh" piso "$DIST/forja-linux-x86_64/libforja.linux.x86_64.so" 2>&1)"; then
  echo "$piso" | sed "s|$DIST/||; s/^/    /"
else
  echo "$piso" | sed "s|$DIST/||; s/^/    /"
  falha "o módulo do pacote pede uma glibc mais nova que a do Godot"
fi

APPIMAGE="$DIST/FORJA-x86_64.AppImage"
if [ -f "$APPIMAGE" ]; then
  echo "==> o AppImage: a mesma Prova de Fogo"
  mkdir -p "$TMP/appimage"
  chmod +x "$APPIMAGE"
  APPIMAGE_EXTRACT_AND_RUN=1 timeout 900 caixa "$APPIMAGE" "${ARGS[@]}" --relatorios="$TMP/appimage" > "$TMP/appimage.log" 2>&1
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
if ! command -v "$WINE" > /dev/null; then
  if [ "${SO_LINUX:-0}" = 1 ]; then
    echo "    sem o Wine: o .exe não rodou (SO_LINUX=1)"
  else
    falha "sem o Wine ($WINE), o .exe não rodou (WINE e WINESERVER apontam o Wine, que não pode ser o do apt do Ubuntu 24.04; ou SO_LINUX=1 para só o Linux)"
  fi
elif [ ! -f "$WINDOWS" ]; then
  falha "sem $WINDOWS: rode scripts/exportar.sh windows"
else
  # Os logs de uma queda velha não ficam ao lado de uma corrida nova.
  GUARDA="$DIST/o-exe-no-wine"
  rm -rf "$GUARDA"
  export WINEPREFIX="$TMP/wine" WINEDEBUG=-all WINEDLLOVERRIDES="mscoree,mshtml="
  versao_do_wine="$("$WINE" --version 2> /dev/null | tail -n 1)"
  echo "    $versao_do_wine"
  caixa "$WINE" wineboot --init > "$TMP/wineboot.log" 2>&1
  mkdir -p "$TMP/windows"
  rel="$("$WINE" winepath -w "$TMP/windows" 2> /dev/null)"
  WINEDEBUG="+seh,+loaddll" timeout 1500 caixa "$WINE" "$WINDOWS" "${ARGS[@]}" --relatorios="$rel" \
    > "$TMP/windows.log" 2>&1
  rc=$?
  "$WINESERVER" -w 2> /dev/null
  grep -E "SCRIPT ERROR|^ERROR" "$TMP/windows.log" | head -20
  if [ "$rc" -ne 0 ]; then
    grep -v -E "^([0-9a-f]{4}:)?(trace|warn|fixme|err):" "$TMP/windows.log" | tail -n 40
    onde_caiu "$TMP/windows.log"
    mkdir -p "$GUARDA"
    echo "$versao_do_wine" > "$GUARDA/versao-do-wine.txt"
    cp "$TMP/windows.log" "$GUARDA/exe.log"
    cp "$TMP/wineboot.log" "$GUARDA/"
    for log in "$WINEPREFIX"/drive_c/users/*/AppData/Roaming/Godot/app_userdata/*/logs/godot.log; do
      [ -f "$log" ] && tail -n 40 "$log" && cp "$log" "$GUARDA/"
    done
    echo "    os logs do Wine (+seh,+loaddll): dist/o-exe-no-wine/"
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
