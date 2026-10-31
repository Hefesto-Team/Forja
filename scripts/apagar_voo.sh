#!/usr/bin/env bash
set -uo pipefail

uso() {
  cat <<'EOF'
O voo que já está no main sai da máquina: a worktree e o ramo local (docs/jogo/o-time/a-esteira.md).

  bash scripts/apagar_voo.sh <voo/ramo>... [--base REF] [--sim]
  bash scripts/apagar_voo.sh --velhos [--base REF] [--sim]

  --velhos  todo ramo voo/* desta máquina
  --base    onde o voo tem de estar (padrão: origin/main, buscado antes)
  --sim     apaga; sem ele, só diz o que apagaria

Sai só o voo cujo commit inteiro está na base (pelo git cherry, ou pelo conteúdo: o commit aplicado sobre a base não
muda nada, como na costura que resolveu um conflito) e cuja worktree está limpa. Antes de apagar, o ramo vai para um
bundle em <git-common-dir>/voo-apagados/. O remoto não muda.

rc: 0 feito (ou nada a apagar) · 1 algum voo ficou (aberto ou sujo) · 2 argumento, ramo ou base que não existe.
EOF
}

BASE="" SIM=0 VELHOS=0
RAMOS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --base) shift; BASE="${1:-}" ;;
    --sim) SIM=1 ;;
    --velhos) VELHOS=1 ;;
    -h|--ajuda) uso; exit 0 ;;
    -*) uso >&2; exit 2 ;;
    *) RAMOS+=("$1") ;;
  esac
  shift
done

COMUM="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || { echo "apagar_voo: fora de um repositório git" >&2; exit 2; }
if [ -z "$BASE" ]; then
  git fetch -q origin main 2>/dev/null || echo "apagar_voo: não busquei o origin/main; sigo com o que a máquina tem" >&2
  BASE="origin/main"
fi
git rev-parse -q --verify "$BASE^{commit}" > /dev/null || { echo "apagar_voo: a base $BASE não existe" >&2; exit 2; }
if [ "$VELHOS" = 1 ]; then
  mapfile -t RAMOS < <(git for-each-ref --format='%(refname:short)' 'refs/heads/voo/')
fi
[ "${#RAMOS[@]}" -gt 0 ] || { [ "$VELHOS" = 1 ] && { echo "apagar_voo: nenhum voo nesta máquina"; exit 0; }; uso >&2; exit 2; }

ARVORE="$(git rev-parse "$BASE^{tree}")"
AQUI="$(git rev-parse --show-toplevel)"
FICOU=0

no_conteudo() {
  local t
  t="$(git merge-tree --write-tree --merge-base="$1^" "$BASE" "$1" 2>/dev/null)" || return 1
  [ "$(head -n 1 <<< "$t")" = "$ARVORE" ]
}

worktree_de() {
  git worktree list --porcelain | awk -v r="refs/heads/$1" '/^worktree /{w=substr($0,10)} $0=="branch " r {print w}'
}

for r in "${RAMOS[@]}"; do
  git rev-parse -q --verify "refs/heads/$r" > /dev/null || { echo "apagar_voo: o ramo $r não existe" >&2; exit 2; }
  fora=0
  while read -r c; do
    no_conteudo "$c" || fora=$((fora + 1))
  done < <(git cherry "$BASE" "$r" | awk '/^\+/{print $2}')
  w="$(worktree_de "$r")"
  if [ "$fora" -gt 0 ]; then
    echo "fica   $r: $fora commit(s) fora de $BASE"; FICOU=1; continue
  fi
  if [ -n "$w" ] && [ "$w" = "$AQUI" ]; then
    echo "fica   $r: é a árvore de onde este script roda"; FICOU=1; continue
  fi
  if [ -n "$w" ] && [ -n "$(git -C "$w" status --porcelain)" ]; then
    echo "fica   $r: a worktree $w tem mudança sem commit"; FICOU=1; continue
  fi
  if [ "$SIM" = 0 ]; then
    echo "sairia $r${w:+ (e a worktree $w)}"; continue
  fi
  mkdir -p "$COMUM/voo-apagados"
  pacote="$COMUM/voo-apagados/${r//\//_}-$(date +%Y%m%d-%H%M%S).bundle"
  git bundle create -q "$pacote" "refs/heads/$r" || { echo "fica   $r: o bundle falhou" >&2; FICOU=1; continue; }
  if [ -n "$w" ]; then
    git worktree remove "$w" || { echo "fica   $r: a worktree $w não saiu" >&2; FICOU=1; continue; }
  fi
  git branch -q -D "$r"
  echo "saiu   $r${w:+ e $w} (bundle: $pacote)"
done
exit "$FICOU"
