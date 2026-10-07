#!/usr/bin/env bash
# MEDIDA (só no ramo medida/forja-exe-4-7, nunca no main): roda um .exe
# exportado pelo Wine com os canais +seh,+loaddll e diz se ele caiu, e em que
# dll mora o endereço da queda. Não reprova: imprime uma linha RESULTADO e
# deixa os logs inteiros em $4.
#
# Uso: bash tests/medir_o_exe_no_wine.sh <pasta com o forja.exe> <rótulo> <segundos> <pasta dos logs>
# WINE e WINESERVER escolhem o Wine (o padrão é o do PATH).
set -u
PASTA="$1"
ROTULO="$2"
TEMPO="${3:-900}"
SAIDA="$4"
WINE="${WINE:-wine}"
WINESERVER="${WINESERVER:-wineserver}"
mkdir -p "$SAIDA"
TMP="$(mktemp -d /tmp/forja-medida-XXXXXX)"

CAIXA=()
if command -v bwrap > /dev/null; then
  CAIXA=(bwrap --dev-bind / / --dev /dev --tmpfs /run/udev --tmpfs /sys/class/input
         --tmpfs /sys/class/hidraw)
fi
ARGS=(--headless --fixed-fps 60 -- --simular=4 --robo --semente=7 --prova-de-fogo --sair-no-fim)

export WINEPREFIX="$TMP/wine" WINEDLLOVERRIDES="mscoree,mshtml="
"$WINE" --version > "$SAIDA/versao-do-wine.txt" 2>&1
ls -la "$PASTA" > "$SAIDA/pasta.txt" 2>&1
WINEDEBUG=-all "${CAIXA[@]}" "$WINE" wineboot --init > "$SAIDA/wineboot.log" 2>&1
# Sem a janela do winedbg, o backtrace sai no console.
WINEDEBUG=-all "$WINE" reg add 'HKCU\Software\Wine\WineDbg' /v ShowCrashDialog /t REG_DWORD /d 0 /f \
  >> "$SAIDA/wineboot.log" 2>&1
"$WINESERVER" -w 2> /dev/null
mkdir -p "$TMP/rel"
rel="$(WINEDEBUG=-all "$WINE" winepath -w "$TMP/rel" 2> /dev/null)"

inicio="$(date +%s)"
WINEDEBUG="+seh,+loaddll" timeout "$TEMPO" "${CAIXA[@]}" "$WINE" "$PASTA/forja.exe" "${ARGS[@]}" \
  --relatorios="$rel" > "$SAIDA/exe.log" 2>&1
rc=$?
duracao=$(($(date +%s) - inicio))
"$WINESERVER" -k 2> /dev/null
"$WINESERVER" -w 2> /dev/null
cp -r "$TMP/rel" "$SAIDA/relatorios" 2> /dev/null
for log in "$WINEPREFIX"/drive_c/users/*/AppData/Roaming/Godot/app_userdata/*/logs/godot*.log; do
  [ -f "$log" ] && cp "$log" "$SAIDA/"
done

python3 - "$SAIDA" "$ROTULO" "$rc" "$duracao" <<'PY'
import glob, json, os, re, sys
saida, rotulo, rc, duracao = sys.argv[1:5]
linhas = open(os.path.join(saida, "exe.log"), encoding="utf-8", errors="replace").read().splitlines()
versao = open(os.path.join(saida, "versao-do-wine.txt"), errors="replace").read().strip()
carregadas = []  # (base, nome, tipo, índice da linha)
re_dll = re.compile(r'Loaded L"([^"]+)" at ([0-9A-Fa-f]+): (\w+)')
re_falha = re.compile(r"(page fault on \w+ access to (?:0x)?([0-9A-Fa-f]+) .*?(?:at address|in \d+-bit code \()(?:0x)?([0-9A-Fa-f]+))")
re_seh = re.compile(r"code=c0000005.*?addr=(?:0x)?([0-9A-Fa-f]+)")
endereco, primeira = None, None
quedas = []  # (endereço, índice) de todo c0000005
for i, l in enumerate(linhas):
    m = re_dll.search(l)
    if m:
        carregadas.append((int(m.group(2), 16), m.group(1), m.group(3), i))
    m = re_seh.search(l)
    if m:
        quedas.append((int(m.group(1), 16), i))
    if endereco is None:
        m = re_falha.search(l)
        if m and "Unhandled" in l:
            endereco, primeira = int(m.group(3), 16), i
if endereco is not None:
    antes = [i for a, i in quedas if a == endereco and i <= primeira]
    if antes:
        primeira = antes[-1]
elif quedas:
    endereco, primeira = quedas[-1]
if quedas:
    print(f"    {len(quedas)} c0000005 no log, nos endereços: " + ", ".join(sorted({f'{a:016X}' for a, _ in quedas})))
def modulo(addr, ate=None):
    cands = [(b, n, t) for b, n, t, i in carregadas if b <= addr and (ate is None or i <= ate)]
    return max(cands) if cands else None
relatorio = glob.glob(os.path.join(saida, "relatorios", "relatorio-*.json"))
terminou = False
for arq in glob.glob(os.path.join(saida, "relatorios", "linha-do-tempo-*.jsonl")):
    for l in open(arq, encoding="utf-8"):
        try:
            e = json.loads(l)
        except ValueError:
            continue
        if e.get("evento") == "prova_de_fogo" and e.get("o") == "terminou":
            terminou = True
print(f"==> {rotulo}: {versao}, rc={rc}, {duracao}s")
if endereco is not None:
    mod = modulo(endereco, primeira)
    onde = f"{mod[1]} ({mod[2]}, base {mod[0]:016X}, +0x{endereco - mod[0]:X})" if mod else "fora de toda dll carregada"
    print(f"    QUEDA: c0000005 em {endereco:016X}, que mora em {onde}")
    print("    as dez últimas dll carregadas antes da queda:")
    for b, n, t, i in [c for c in carregadas if c[3] <= primeira][-10:]:
        print(f"      {b:016X} {t:8} {n}")
    print("    o log em volta da primeira queda:")
    for l in linhas[max(0, primeira - 25): primeira + 15]:
        print("      " + l[:260])
else:
    print("    sem queda (nenhum c0000005 no log)")
bt = [i for i, l in enumerate(linhas) if l.startswith("Unhandled exception") or l.startswith("Backtrace:")]
if bt:
    print("    o winedbg:")
    for l in linhas[bt[0]: bt[0] + 70]:
        if not l.startswith(("trace:", "warn:", "fixme:")):
            print("      " + l[:260])
proprias = [l for l in linhas if not re.match(r"^[0-9a-f]{4}:(trace|warn|fixme|err):|^(trace|warn|fixme|err):", l)]
print("    as últimas linhas do próprio jogo:")
for l in proprias[-25:]:
    print("      " + l[:260])
mod = modulo(endereco, primeira) if endereco is not None else None
res = (f"RESULTADO {rotulo} | {versao} | rc={rc} | {duracao}s | "
       f"queda={'sim em %016X (%s)' % (endereco, os.path.basename(mod[1].replace(chr(92), '/')) if mod else '?') if endereco is not None else 'não'} | "
       f"relatório={'sim' if relatorio else 'não'} | prova_de_fogo_terminou={'sim' if terminou else 'não'}")
print(res)
open(os.path.join(saida, "RESULTADO.txt"), "w").write(res + "\n")
resumo = os.environ.get("GITHUB_STEP_SUMMARY")
if resumo:
    open(resumo, "a").write(res + "\n\n")
PY
exit 0
