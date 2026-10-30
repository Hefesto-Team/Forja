#!/usr/bin/env bash
set -u
uso() {
  cat <<'FIM'
O cobrador do devlog: quem muda o que se vê fecha com a entrada do devlog e as fotos do depois.

Uso: scripts/devlog/cobrar.sh [--ajuda]   (roda na árvore do diretório atual; lê o JSON do gancho na entrada padrão)
Sai 0 quando: o gancho já cobrou uma vez (stop_hook_active), o diretório não é um repositório, o ramo é o main,
o ramo não muda arquivo visual desde a base, ou existe entrada com topo igual ao HEAD (ou ancestral dele, só com
commits não visuais depois) e com ao menos uma foto de depois. Senão sai 2 e diz os comandos que faltam.
Arquivo visual: godot/** menos godot/testes/**, *.import e *.uid.
FIM
}
case "${1:-}" in -h | --ajuda) uso; exit 0 ;; esac
if [ ! -t 0 ]; then
  JSON="$(timeout 1 cat 2> /dev/null || true)"
  if printf '%s' "$JSON" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
    exit 0
  fi
fi
RAIZ="$(git rev-parse --show-toplevel 2> /dev/null)" || exit 0
cd "$RAIZ" || exit 0
RAMO="$(git rev-parse --abbrev-ref HEAD 2> /dev/null)" || exit 0
[ "$RAMO" != main ] || exit 0
git rev-parse --verify -q main > /dev/null || exit 0
BASE="$(git merge-base main HEAD 2> /dev/null)" || exit 0

so_visual() {
  local f
  while IFS= read -r f; do
    case "$f" in godot/testes/* | *.import | *.uid) continue ;; godot/*) echo "$f" ;; esac
  done
}
NO_RAMO="$(git diff --name-only "$BASE" HEAD -- godot | so_visual)"
SUJOS="$({ git diff --name-only HEAD -- godot; git ls-files --others --exclude-standard -- godot; } | so_visual)"
[ -n "$NO_RAMO$SUJOS" ] || exit 0

tem_foto() { compgen -G "$1/depois/*.jpg" > /dev/null; }
sem_fotos=""
if [ -z "$SUJOS" ]; then
  for entrada in docs/devlog/*/entrada.md; do
    [ -f "$entrada" ] || continue
    pasta="$(dirname "$entrada")"
    topo="$(python3 scripts/devlog/cabecalho.py ler "$entrada" topo 2> /dev/null)"
    sha="$(git rev-parse --verify -q "$topo^{commit}" 2> /dev/null)" || continue
    git merge-base --is-ancestor "$sha" HEAD 2> /dev/null || continue
    [ -z "$(git diff --name-only "$sha" HEAD -- godot | so_visual)" ] || continue
    if tem_foto "$pasta"; then
      exit 0
    fi
    sem_fotos="$pasta"
  done
fi

N="$(printf '%s\n%s\n' "$NO_RAMO" "$SUJOS" | sed '/^$/d' | sort -u | wc -l)"
echo "devlog: o ramo $RAMO muda $N arquivo(s) visual(is) sem a entrada do devlog com as fotos do depois." >&2
if [ -n "$sem_fotos" ]; then
  echo "  scripts/devlog/fotos.sh $sem_fotos" >&2
else
  echo "  scripts/devlog/entrada.sh <slug> \"<título>\"" >&2
  echo "  scripts/devlog/fotos.sh docs/devlog/$(date +%F)-<slug>" >&2
fi
[ -z "$SUJOS" ] || echo "  (há mudança visual sem commit: faça o commit antes da entrada, que mira o HEAD)" >&2
exit 2
