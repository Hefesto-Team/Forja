#!/usr/bin/env bash
set -uo pipefail
uso() {
  cat <<'EOF'
Os portões por script, numa chamada só: o CI (job `portoes`) e o pre-commit chamam este.

Uso: bash scripts/portoes/rodar.sh [--so base|texto|arte|som] [--raiz DIR] [--desde REF] [--tudo]
  --so GRUPO   só um grupo: base, texto (código sem comentário e texto enxuto), arte ou som
  --desde REF  mostra também os avisos dos arquivos mudados desde REF
  --tudo       a saída inteira de cada portão na tela (o CI usa)

Sai 0 quando nenhum portão em modo reprova achou nada, 1 quando algum achou, 2 quando um não conferiu.
A saída inteira de cada portão fica em .cache/portoes/<nome>.log. O que cada um pega: scripts/portoes/LEIA-ME.md.
EOF
}
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAIZ="$(cd "$AQUI/../.." && pwd)"
SO=""
DESDE=""
TUDO=0
while [ $# -gt 0 ]; do
  case "$1" in
    --so) shift; SO="${1:-}" ;;
    --raiz) shift; RAIZ="$(cd "${1:-.}" && pwd)" ;;
    --desde) shift; DESDE="${1:-}" ;;
    --tudo) TUDO=1 ;;
    -h|--ajuda) uso; exit 0 ;;
    *) echo "portões: argumento desconhecido: $1" >&2; exit 2 ;;
  esac
  shift
done

PIOR=0
RESUMO=()
LOGS=()
NAO_OK=()
CACHE="$RAIZ/.cache/portoes"
mkdir -p "$CACHE"
arquivo_de() {
  printf '%s' "$1" | iconv -f utf-8 -t ascii//TRANSLIT 2> /dev/null | tr -c 'A-Za-z0-9' '-' | tr 'A-Z' 'a-z'
}
roda() {
  local grupo="$1" nome="$2"; shift 2
  [ -n "$SO" ] && [ "$SO" != "$grupo" ] && return 0
  local log rc ultima
  log="$CACHE/$(arquivo_de "$nome").log"
  if [ "$TUDO" -eq 1 ]; then
    echo "==> $nome"
    "$@" 2>&1 | tee "$log"
    rc="${PIPESTATUS[0]}"
  else
    "$@" > "$log" 2>&1
    rc=$?
  fi
  ultima="$(tail -n 1 "$log")"
  LOGS+=("$log")
  case "$rc" in
    0) RESUMO+=("ok    $nome — $ultima") ;;
    1) RESUMO+=("FAIL  $nome — $ultima"); [ "$PIOR" -lt 1 ] && PIOR=1; NAO_OK+=("$log") ;;
    *) RESUMO+=("ERRO  $nome (não conferiu, rc=$rc)"); PIOR=2; NAO_OK+=("$log") ;;
  esac
}

roda base "texto de tela" python3 "$RAIZ/scripts/check_texto_de_tela.py"
roda base "sem rastro" bash "$RAIZ/tests/prova_sem_rastro.sh" --so-varrer
roda base "mensagens de commit" python3 "$AQUI/mensagens_de_commit.py" --raiz "$RAIZ"
roda base "ficha pronta" python3 "$AQUI/ficha_pronta.py" --raiz "$RAIZ"
roda base "teste mudo" python3 "$AQUI/teste_mudo.py" --raiz "$RAIZ"
roda base "caixa" python3 "$AQUI/caixa.py" --raiz "$RAIZ"
roda base "devlog" python3 "$AQUI/devlog.py" --raiz "$RAIZ"
roda texto "código sem comentário" python3 "$AQUI/codigo_sem_comentario.py" --raiz "$RAIZ" --catraca
roda texto "texto enxuto" python3 "$AQUI/texto_enxuto.py" --raiz "$RAIZ" --catraca
roda base "regra do udev" python3 "$AQUI/udev.py" --raiz "$RAIZ"
roda arte "arte" python3 "$AQUI/arte.py" --raiz "$RAIZ"
roda som "som" python3 "$AQUI/som.py" --raiz "$RAIZ"

[ "$TUDO" -eq 1 ] && echo
echo "os portões:"
printf '  %s\n' "${RESUMO[@]}"
[ "$TUDO" -eq 1 ] && exit "$PIOR"

MUDADOS=()
if [ -n "$DESDE" ]; then
  git -C "$RAIZ" rev-parse --verify -q "$DESDE^{commit}" > /dev/null ||
    echo "portões: --desde $DESDE: o git não achou a referência (os avisos dos arquivos mudados não aparecem)" >&2
  mapfile -t MUDADOS < <(git -C "$RAIZ" diff --name-only "$DESDE" 2> /dev/null)
fi
VISTAS=()
for log in "${NAO_OK[@]}"; do
  while IFS= read -r l; do VISTAS+=("$l"); done < <(grep -E '^(FAIL|ERRO)' "$log")
done
if [ "${#MUDADOS[@]}" -gt 0 ]; then
  for log in "${LOGS[@]}"; do
    while IFS= read -r l; do
      for m in "${MUDADOS[@]}"; do
        if [[ "$l" == *": $m"* || "$l" == *" $m:"* ]]; then VISTAS+=("$l"); break; fi
      done
    done < <(grep -E '^AVISO' "$log")
  done
fi
if [ "${#VISTAS[@]}" -gt 0 ]; then
  echo
  printf '%s\n' "${VISTAS[@]:0:12}" | cut -c1-200
  [ "${#VISTAS[@]}" -gt 12 ] && echo "(mais $((${#VISTAS[@]} - 12)) linhas)"
fi
for log in "${NAO_OK[@]}"; do echo "o resto: ${log#"$RAIZ"/}"; done
echo "a saída inteira de cada portão: .cache/portoes/<nome>.log (ou --tudo)"
exit "$PIOR"
