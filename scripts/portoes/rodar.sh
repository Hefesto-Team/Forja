#!/usr/bin/env bash
# Os portões por script, numa chamada só: o que o CI roda no job `portoes` e o que se roda antes de commitar.
#
#   A BASE (reprova desde já):
#     texto de tela      toda frase da tabela de traduções começa com maiúscula (scripts/check_texto_de_tela.py)
#     sem rastro         nenhum termo interno, campo de modelo em ficha, trailer, AGENTS.md (tests/prova_sem_rastro.sh)
#     mensagens          os commits novos sem símbolo nem trailer (mensagens_de_commit.py)
#     ficha pronta       ficha «pronta» no quadro tem todas as partes da ficha pronta (ficha_pronta.py)
#     caixa              prova e script abrem o jogo só pelo `caixa` (tests/caixa.sh), sem ver o controle (caixa.py)
#   A DIREÇÃO (em AVISO até a bíblia entrar; não reprovam):
#     arte               cor só por token, só as fontes da bíblia, texto de 30 px ou mais, cor de jogador só no
#                        jogador (arte.py, regras em arte.json)
#     som                todo id tocado está no mapa do áudio; duração, pico e clique dos arquivos (som.py, som.json)
#
# VIRAR A ARTE E O SOM PARA REPROVAR: em scripts/portoes/arte.json e scripts/portoes/som.json, trocar
# "modo": "aviso" por "modo": "reprova". Nada muda aqui nem no CI. A ficha V08 diz quando (avisos zerados).
#
# Uso: bash scripts/portoes/rodar.sh [--so base|arte|som] [--raiz DIR] [--desde REF] [--tudo]
# Sai 0 quando nenhum portão em modo reprova achou nada; 1 quando algum achou; 2 quando um não conseguiu conferir.
#
# A tela fala curto: o resumo por portão e, de quem não deu ok, as linhas de FAIL e de ERRO (no máximo 12 no
# total). A saída inteira de cada portão fica em .cache/portoes/<nome>.log. Com --desde REF, os avisos dos
# arquivos mudados desde REF também aparecem (no mesmo corte). Com --tudo, a saída inteira vai para a tela,
# como antes (o CI usa).
set -uo pipefail
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
    -h|--ajuda) awk 'NR > 1 && /^#/ {sub(/^# ?/, ""); print} /^set -uo/ {exit}' "${BASH_SOURCE[0]}"; exit 0 ;;
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
## o nome do portão no arquivo, sem espaço nem acento («texto de tela» vira texto-de-tela)
arquivo_de() {
  printf '%s' "$1" | iconv -f utf-8 -t ascii//TRANSLIT 2> /dev/null | tr -c 'A-Za-z0-9' '-' | tr 'A-Z' 'a-z'
}
## roda <grupo> <nome> <comando...>: guarda a saída inteira em .cache/portoes/<nome>.log, o resumo, e soma o pior
## código. Com --tudo, a saída também vai para a tela, como antes.
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
roda arte "arte" python3 "$AQUI/arte.py" --raiz "$RAIZ"
roda som "som" python3 "$AQUI/som.py" --raiz "$RAIZ"

[ "$TUDO" -eq 1 ] && echo
echo "os portões:"
printf '  %s\n' "${RESUMO[@]}"
[ "$TUDO" -eq 1 ] && exit "$PIOR"

# O que pede leitura, no máximo 12 linhas: o FAIL e o ERRO de quem não deu ok e, com --desde, os avisos dos arquivos
# mudados desde a referência.
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
