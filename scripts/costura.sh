#!/usr/bin/env bash
# A costura: leva os commits de um ramo de conjunto para a árvore de integração e confere, parando no primeiro
# vermelho. É o passo 5 de docs/jogo/o-time/a-esteira.md, por script.
#
#   1. A integração tem que estar limpa (nada fora de commit) e num ramo que não é o do conjunto.
#   2. Só os commits que faltam: o `git cherry` (por patch-id) dá os «+», na ordem do ramo. Nunca o `rev-list`:
#      o cherry-pick cria hash novo, e o commit já costurado não pode voltar duas vezes.
#   3. Um cherry-pick só, com todos: no conflito, ele é ABORTADO (a integração volta ao topo de antes, limpa) e
#      o script diz o commit e os arquivos. Quem coordena resolve à mão.
#   4. Na integração, os portões (`scripts/portoes/rodar.sh`) e as provas rápidas, na ordem; o primeiro vermelho
#      para tudo, diz qual foi e o topo de antes da costura (para desfazer: `git reset --keep <topo de antes>`).
#   5. Com --pesadas, depois das rápidas, o `scripts/ci-local.sh --rapido` pelo semáforo da máquina (a variável
#      VEZ, um comando que faz fila; sem ela, roda direto): é ele que compila o módulo e roda a prova do jogo.
#      Sem --pesadas, o verde é só dos portões e das provas de ferramenta, e a última linha diz isso. Antes de
#      marcar «feito» no quadro, a costura roda com --pesadas.
#
# As provas rápidas são as do repositório (a lista PROVAS abaixo); `--prova "<comando>"` (repetível) troca a lista
# inteira pelo que for pedido. Toda prova roda na raiz da integração.
#
# Uso: bash scripts/costura.sh <ramo> [--integracao DIR] [--base REF] [--prova CMD]... [--pesadas] [--registro ARQ]
#      bash scripts/costura.sh --marcar <ficha> <estado> [--integracao DIR]
#   --marcar      só troca o estado da ficha no quadro da integração (a última coluna da linha), pelo
#                 `scripts/esteira.py --marcar`; recusa o estado fora da lista de docs/jogo/o-time/a-esteira.md
#                 («Os estados de uma ficha») e não costura nada
#   --integracao  a árvore de integração (padrão: a árvore onde este script está)
#   --base        o ponto de onde o ramo nasceu, para o `git cherry` (padrão: o merge-base)
#   --registro    um arquivo .md onde a costura que deu verde ganha uma linha (hora, ramo, commits, topo)
#
# rc: 0 costurado e verde (ou nada faltava) · 1 uma prova ou um portão vermelho · 3 conflito (abortado)
#     · 2 não começou (argumento, integração suja, ramo que não existe, prova que não existe).
set -uo pipefail
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INT="$(cd "$AQUI/.." && pwd)"
RAMO="" BASE="" REGISTRO="" PESADAS=0
PEDIDAS=() MARCAR=()
PROVAS=(
  "bash scripts/portoes/rodar.sh"
  "bash tests/prova_dos_portoes.sh"
  "bash tests/prova_da_esteira.sh"
  "bash tests/prova_sem_rastro.sh"
)

while [ $# -gt 0 ]; do
  case "$1" in
    --integracao) shift; INT="${1:-}" ;;
    --base) shift; BASE="${1:-}" ;;
    --prova) shift; PEDIDAS+=("${1:-}") ;;
    --pesadas) PESADAS=1 ;;
    --registro) shift; REGISTRO="${1:-}" ;;
    --marcar) [ $# -ge 3 ] || { echo "uso: bash scripts/costura.sh --marcar <ficha> <estado>" >&2; exit 2; }
      MARCAR=("$2" "$3"); shift 2 ;;
    -h|--ajuda) awk 'NR > 1 && /^#/ {sub(/^# ?/, ""); print} /^set -uo/ {exit}' "${BASH_SOURCE[0]}"; exit 0 ;;
    -*) echo "costura: opção desconhecida: $1" >&2; exit 2 ;;
    *) [ -n "$RAMO" ] && { echo "costura: um ramo só (já veio $RAMO)" >&2; exit 2; }; RAMO="$1" ;;
  esac
  shift
done
if [ ${#MARCAR[@]} -gt 0 ]; then
  [ -z "$RAMO" ] || { echo "costura: --marcar não costura; tire o ramo $RAMO" >&2; exit 2; }
  exec python3 "$AQUI/esteira.py" --raiz "$INT" --marcar "${MARCAR[@]}"
fi
[ -n "$RAMO" ] || { echo "uso: bash scripts/costura.sh <ramo> [--integracao DIR] [--prova CMD]..." >&2; exit 2; }
[ ${#PEDIDAS[@]} -gt 0 ] && PROVAS=("${PEDIDAS[@]}")
[ -d "$INT" ] || { echo "costura: a integração $INT não existe" >&2; exit 2; }
INT="$(cd "$INT" && pwd)"
g() { git -C "$INT" "$@"; }

g rev-parse --is-inside-work-tree > /dev/null 2>&1 || { echo "costura: $INT não é um repositório git" >&2; exit 2; }
NA_INT="$(g rev-parse --abbrev-ref HEAD)"
[ "$NA_INT" != "HEAD" ] || { echo "costura: a integração está sem ramo (HEAD solto)" >&2; exit 2; }
g rev-parse --verify --quiet "$RAMO^{commit}" > /dev/null || { echo "costura: não existe o ramo $RAMO em $INT" >&2; exit 2; }
[ "$RAMO" != "$NA_INT" ] || { echo "costura: a integração está no próprio $RAMO" >&2; exit 2; }
[ -z "$(g status --porcelain --untracked-files=no)" ] \
  || { echo "costura: a integração $INT tem mudança fora de commit; nada foi costurado" >&2; exit 2; }
if [ -e "$(g rev-parse --git-path CHERRY_PICK_HEAD)" ] || [ -d "$(g rev-parse --git-path sequencer)" ]; then
  echo "costura: há um cherry-pick pela metade em $INT; termine ou aborte antes" >&2; exit 2
fi
for p in "${PROVAS[@]}"; do
  # o arquivo do comando (o segundo campo de «bash x.sh» ou «python3 x.py») tem que existir na integração
  arq="$(awk '{print ($1 == "bash" || $1 == "python3" || $1 == "sh") ? $2 : ""}' <<< "$p")"
  if [ -n "$arq" ] && [ ! -f "$INT/$arq" ] && [ ! -f "$arq" ]; then
    echo "costura: a prova «$p» não existe em $INT; nada foi costurado" >&2; exit 2
  fi
done

[ -n "$BASE" ] || BASE="$(g merge-base HEAD "$RAMO")" || { echo "costura: $RAMO não tem base comum com $NA_INT" >&2; exit 2; }
# A saída vai para uma variável antes do awk: o cherry que FALHA não pode ler-se como «nada falta».
CHERRY="$(g cherry HEAD "$RAMO" "$BASE")" || { echo "costura: o git cherry de $RAMO falhou; nada foi costurado" >&2; exit 2; }
mapfile -t FALTAM < <(awk '$1 == "+" {print $2}' <<< "$CHERRY")
ANTES="$(g rev-parse --short HEAD)"
if [ ${#FALTAM[@]} -eq 0 ]; then
  echo "costura: nada falta de $RAMO em $NA_INT (topo $ANTES)"
  exit 0
fi
echo "costura: ${#FALTAM[@]} commit(s) de $RAMO em $NA_INT (topo de antes $ANTES)"

if ! g cherry-pick "${FALTAM[@]}" > /dev/null 2>&1; then
  QUAL="$(g rev-parse --short CHERRY_PICK_HEAD 2> /dev/null || echo '?')"
  ASSUNTO="$(g log -1 --format=%s "$QUAL" 2> /dev/null || true)"
  mapfile -t BRIGAM < <(g diff --name-only --diff-filter=U)
  g cherry-pick --abort > /dev/null 2>&1 || g reset --merge > /dev/null 2>&1
  echo "costura: CONFLITO em $QUAL «$ASSUNTO»" >&2
  [ ${#BRIGAM[@]} -gt 0 ] && printf '  %s\n' "${BRIGAM[@]}" >&2
  echo "costura: abortado; a integração voltou a $(g rev-parse --short HEAD). Resolva à mão e rode de novo." >&2
  exit 3
fi
TOPO="$(g rev-parse --short HEAD)"
echo "costura: costurado, topo $TOPO; agora os portões e as provas"

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT
roda() {
  echo "==> $1"
  if ! (cd "$INT" && bash -c "$1") > "$LOG" 2>&1; then
    tail -n 15 "$LOG" | sed 's/^/  | /'
    echo "costura: VERMELHO em «$1»; parei aqui (topo $TOPO, antes da costura $ANTES)." >&2
    echo "costura: para desfazer a costura: git -C $INT reset --keep $ANTES" >&2
    exit 1
  fi
  echo "    ok — $(tail -n 1 "$LOG")"
}
for p in "${PROVAS[@]}"; do roda "$p"; done
if [ "$PESADAS" -eq 1 ]; then
  roda "${VEZ:+$VEZ }bash scripts/ci-local.sh --rapido"
fi

if [ -n "$REGISTRO" ]; then
  [ -f "$REGISTRO" ] || printf '# A costura\n\n| hora | ramo | commits | topo |\n| --- | --- | --- | --- |\n' > "$REGISTRO"
  printf '| %s | %s | %s | %s |\n' "$(date '+%d/%m %H:%M')" "$RAMO" "${#FALTAM[@]}" "$TOPO" >> "$REGISTRO"
fi
if [ "$PESADAS" -eq 1 ]; then
  echo "costura: verde — ${#FALTAM[@]} commit(s) de $RAMO, topo $TOPO"
else
  # sem --pesadas, o jogo não rodou: o verde é dos portões e das provas de ferramenta, não da prova do jogo
  echo "costura: verde sem as pesadas — ${#FALTAM[@]} commit(s) de $RAMO, topo $TOPO; a prova do jogo não rodou (--pesadas)"
fi
