#!/usr/bin/env bash
set -uo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
source "$RAIZ/scripts/engine.sh"
GODOT="$FORJA_GODOT"
SEMENTE="${SEMENTE:-7}"
[[ -x "$GODOT" ]] || { echo "sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>" >&2; exit 2; }
[[ -f "$RAIZ/godot/bin/libforja.linux.x86_64.so" ]] || { echo "sem o módulo: scripts/compilar.sh linux" >&2; exit 2; }

DEFEITOS=(troca-cruz-circulo analogico-curto gatilho-digital giro-invertido acel-escala um-dedo sem-clique
          vibra-vizinho motores-trocados luz-parada gatilho-mudo leds-errados led-mic-parado mudo-nao-chega
          sem-alto-falante som-vizinho haptica-trocada haptica-muda mic-surdo engasga)

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

caixa "$GODOT" --headless --path "$RAIZ/godot" --import >/dev/null 2>&1 || true

julgar() {
  caixa_julgar "$SAIDA/$1.log" || { echo "ERRO: erro do motor na rodada «$1»"; falhas=$((falhas + 1)); }
}

echo "==> limpo, quatro controles simulados"
if rodar limpo; then
  echo "    passou ($(grep -c '^ok' "$SAIDA/limpo.log") conferências)"
else
  echo "ERRO: a prova limpa falhou"
  grep -E "FAIL|SCRIPT ERROR" "$SAIDA/limpo.log" | head -20
  falhas=$((falhas + 1))
fi
julgar limpo

for d in "${DEFEITOS[@]}"; do
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
echo "gauntlet ok — limpo passa, e cada defeito de mentira é pego"
