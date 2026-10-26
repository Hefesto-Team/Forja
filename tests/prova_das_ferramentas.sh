#!/usr/bin/env bash
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/forja-prova-das-ferramentas-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
FALHAS=0
CASOS=0
TODAS=(kenney mapa_de_batidas trilha_fichas gerar_trilha descrever_trilha baixador)
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

for f in kenney mapa_de_batidas trilha_fichas gerar_trilha descrever_trilha; do
  pedida "$f" || continue
  espera 0 "scripts/$f.py --prova" python3 "scripts/$f.py" --prova
done

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

echo
if [ "$FALHAS" -eq 0 ]; then
  echo "prova das ferramentas ok — $CASOS casos (${PEDIDAS[*]})"
  exit 0
fi
echo "prova das ferramentas: $FALHAS de $CASOS casos falharam"
exit 1
