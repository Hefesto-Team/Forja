#!/usr/bin/env bash
set -uo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
SEMENTE="${SEMENTE:-7}"

mapfile -t DEFEITOS < <(awk '/DEFEITOS\[\] = \{/ {d = 1; next} d && /^\};/ {exit} d' "$RAIZ/nativo/nucleo/simulador.c" |
  grep -oE '\{"[a-z0-9-]+", *DEFEITO_[A-Z0-9_]+\}' | sed -E 's/^\{"([^"]+)".*/\1/')
[[ "${#DEFEITOS[@]}" -gt 0 ]] || { echo "gauntlet: a lista de defeitos do simulador saiu vazia (nativo/nucleo/simulador.c)" >&2; exit 2; }

SO="" PERNAS=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --so) shift; SO="${1:-}"; [[ -n "$SO" ]] || { echo "gauntlet: --so pede a lista (limpo,defeito,...)" >&2; exit 2; } ;;
    --pernas) shift; PERNAS="${1:-}"; [[ "$PERNAS" =~ ^[1-9][0-9]*$ ]] || { echo "gauntlet: --pernas pede um número" >&2; exit 2; } ;;
    -h|--ajuda) awk 'NR > 1 && /^#/ {sub(/^# ?/, ""); print} /^set -uo/ {exit}' "$0"; exit 0 ;;
    *) echo "gauntlet: argumento desconhecido: $1" >&2; exit 2 ;;
  esac
  shift
done

if [[ -n "$PERNAS" ]]; then
  por=$(( (${#DEFEITOS[@]} + PERNAS - 1) / PERNAS ))
  sep="["
  for ((i = 0; i < ${#DEFEITOS[@]}; i += por)); do
    parte=("${DEFEITOS[@]:i:por}")
    [[ "$i" -eq 0 ]] && parte=(limpo "${parte[@]}")
    lista="$(IFS=,; echo "${parte[*]}")"
    printf '%s{"nome":"%s","so":"%s"}' "$sep" "${lista//,/, }" "$lista"
    sep=","
  done
  echo "]"
  exit 0
fi

LIMPO=1
if [[ -n "$SO" ]]; then
  LIMPO=0; PEDIDOS=()
  IFS=, read -ra itens <<< "$SO"
  for d in "${itens[@]}"; do
    [[ "$d" == limpo ]] && { LIMPO=1; continue; }
    [[ " ${DEFEITOS[*]} " == *" $d "* ]] || { echo "gauntlet: o simulador não tem o defeito «$d» (tem: ${DEFEITOS[*]})" >&2; exit 2; }
    PEDIDOS+=("$d")
  done
  DEFEITOS=("${PEDIDOS[@]}")
fi

source "$RAIZ/scripts/engine.sh"
GODOT="$FORJA_GODOT"
[[ -x "$GODOT" ]] || { echo "sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>" >&2; exit 2; }
[[ -f "$RAIZ/godot/bin/libforja.linux.x86_64.so" ]] || { echo "sem o módulo: scripts/compilar.sh linux" >&2; exit 2; }

source "$RAIZ/tests/caixa.sh"
caixa_pasta gauntlet; SAIDA="$CAIXA_PASTA"
caixa_montar "$SAIDA/caixa"
falhas=0

rodar() {
  local nome="$1"
  shift
  mkdir -p "$SAIDA/$nome"
  timeout 600 caixa "$GODOT" --headless --fixed-fps 60 --path "$RAIZ/godot" res://testes/prova_do_jogo.tscn \
    -- --simular=4 --robo --semente="$SEMENTE" --relatorios="$SAIDA/$nome" --bancada --acelerado "$@" >"$SAIDA/$nome.log" 2>&1
}

cp "$RAIZ/tests/erros_esperados.txt" "$SAIDA/import.esperados"
if [[ ! -d "$RAIZ/godot/.godot/imported" ]]; then
  fonte=$(sed -n 's|^theme/custom_font="res://\(.*\)"$|\1|p' "$RAIZ/godot/project.godot")
  if [[ -n "$fonte" ]]; then
    f=$(printf '%s' "$fonte" | sed 's/[][\.*^$+?(){}|]/\\&/g')
    b=$(printf '%s' "${fonte##*/}" | sed 's/[][\.*^$+?(){}|]/\\&/g')
    printf '%s\n' \
      "^ERROR: Cannot open file 'res://\\.godot/imported/$b-[0-9a-f]+\\.fontdata'\\.\$" \
      "^ERROR: Failed loading resource: res://\\.godot/imported/$b-[0-9a-f]+\\.fontdata\\.\$" \
      "^ERROR: Failed loading resource: res://$f\\.\$" \
      "^ERROR: Error loading custom project font 'res://$f'\$" >>"$SAIDA/import.esperados"
  fi
fi
if ! caixa "$GODOT" --headless --path "$RAIZ/godot" --import --quit >"$SAIDA/import.log" 2>&1 ||
  ! CAIXA_ESPERADOS="$SAIDA/import.esperados" caixa_julgar "$SAIDA/import.log" >"$SAIDA/import.julgado"; then
  echo "ERRO: o import do projeto falhou ($SAIDA/import.log):"
  cat "$SAIDA/import.julgado" 2>/dev/null
  tail -n 15 "$SAIDA/import.log"
  exit 1
fi

julgar() {
  caixa_julgar "$SAIDA/$1.log" || { echo "ERRO: erro do motor na rodada «$1»"; falhas=$((falhas + 1)); }
}

if [[ "$LIMPO" -eq 1 ]]; then
  echo "==> limpo, quatro controles simulados"
  if rodar limpo; then
    echo "    passou ($(grep -c '^ok' "$SAIDA/limpo.log") conferências)"
  else
    echo "ERRO: a prova limpa falhou"
    grep -E "FAIL|SCRIPT ERROR" "$SAIDA/limpo.log" | head -20
    falhas=$((falhas + 1))
  fi
  julgar limpo
fi

for d in "${DEFEITOS[@]+"${DEFEITOS[@]}"}"; do
  if rodar "$d" --defeitos="$d"; then
    echo "ERRO: o defeito «$d» passou — a prova não o pegou"
    falhas=$((falhas + 1))
  else
    echo "    «$d» pego: $(grep -m1 '^FAIL' "$SAIDA/$d.log" | sed 's/^FAIL *//')"
  fi
  julgar "$d"
done

if [[ "$falhas" -gt 0 ]]; then
  echo "gauntlet: $falhas problema(s)"
  exit 1
fi
echo "gauntlet ok — $([[ "$LIMPO" -eq 1 ]] && echo "limpo passa, e ")cada defeito de mentira é pego (${#DEFEITOS[@]}: ${DEFEITOS[*]-})"
