#!/usr/bin/env bash
# Os portões por script, numa chamada só: o que o CI roda no job `portoes` e o que se roda antes de commitar.
#
#   A BASE (reprova desde já):
#     texto de tela      toda frase da tabela de traduções começa com maiúscula (scripts/check_texto_de_tela.py)
#     sem rastro         nenhum termo interno, campo de modelo em ficha, trailer, AGENTS.md (tests/prova_sem_rastro.sh)
#     mensagens          os commits novos sem símbolo nem trailer (mensagens_de_commit.py)
#     ficha pronta       ficha «pronta» no quadro tem todas as partes da ficha pronta (ficha_pronta.py)
#   A DIREÇÃO (em AVISO até a bíblia entrar; não reprovam):
#     arte               cor só por token, só as fontes da bíblia, texto de 30 px ou mais, cor de jogador só no
#                        jogador (arte.py, regras em arte.json)
#     som                todo id tocado está no mapa do áudio; duração, pico e clique dos arquivos (som.py, som.json)
#
# VIRAR A ARTE E O SOM PARA REPROVAR: em scripts/portoes/arte.json e scripts/portoes/som.json, trocar
# "modo": "aviso" por "modo": "reprova". Nada muda aqui nem no CI. A ficha V08 diz quando (avisos zerados).
#
# Uso: bash scripts/portoes/rodar.sh [--so base|arte|som] [--raiz DIR]
# Sai 0 quando nenhum portão em modo reprova achou nada; 1 quando algum achou; 2 quando um não conseguiu conferir.
set -uo pipefail
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAIZ="$(cd "$AQUI/../.." && pwd)"
SO=""
while [ $# -gt 0 ]; do
  case "$1" in
    --so) shift; SO="${1:-}" ;;
    --raiz) shift; RAIZ="$(cd "${1:-.}" && pwd)" ;;
    -h|--ajuda) awk 'NR > 1 && /^#/ {sub(/^# ?/, ""); print} /^set -uo/ {exit}' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "portões: argumento desconhecido: $1" >&2; exit 2 ;;
  esac
  shift
done

PIOR=0
RESUMO=()
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT
## roda <grupo> <nome> <comando...>: mostra a saída, guarda o resumo, soma o pior código.
roda() {
  local grupo="$1" nome="$2"; shift 2
  [ -n "$SO" ] && [ "$SO" != "$grupo" ] && return 0
  echo "==> $nome"
  "$@" 2>&1 | tee "$LOG"
  local rc="${PIPESTATUS[0]}" ultima
  ultima="$(tail -n 1 "$LOG")"
  case "$rc" in
    0) RESUMO+=("ok    $nome — $ultima") ;;
    1) RESUMO+=("FAIL  $nome — $ultima"); [ "$PIOR" -lt 1 ] && PIOR=1 ;;
    *) RESUMO+=("ERRO  $nome (não conferiu, rc=$rc)"); PIOR=2 ;;
  esac
}

roda base "texto de tela" python3 "$RAIZ/scripts/check_texto_de_tela.py"
roda base "sem rastro" bash "$RAIZ/tests/prova_sem_rastro.sh" --so-varrer
roda base "mensagens de commit" python3 "$AQUI/mensagens_de_commit.py" --raiz "$RAIZ"
roda base "ficha pronta" python3 "$AQUI/ficha_pronta.py" --raiz "$RAIZ"
roda arte "arte" python3 "$AQUI/arte.py" --raiz "$RAIZ"
roda som "som" python3 "$AQUI/som.py" --raiz "$RAIZ"

echo
echo "os portões:"
printf '  %s\n' "${RESUMO[@]}"
exit "$PIOR"
