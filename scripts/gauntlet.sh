#!/usr/bin/env bash
# A Prova de Fogo sem aparelho (ADR-003), no jogo 3D: a prova do jogo roda com
# quatro DualSense simulados, e depois roda de novo com cada defeito de mentira
# ligado nos controles simulados.
#
#   1. limpo: a prova tem de passar;
#   2. a prova da prova: com cada defeito, a prova tem de FALHAR — se uma sala
#      deixa um defeito passar, ela não serve de régua para o Hefesto.
#
# Os defeitos daqui são os que as salas deste marco já medem; a lista cresce
# com as salas. "Passou no robô" prova o JOGO; o Hefesto se prova na mão, com
# o roteiro do README.
#
#   scripts/gauntlet.sh            (GODOT=<binário> para outro Godot)
set -uo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-$RAIZ/tools/Godot_v4.4.1-stable_linux.x86_64}"
SEMENTE="${SEMENTE:-7}"
[[ -x "$GODOT" ]] || { echo "sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>" >&2; exit 2; }
[[ -f "$RAIZ/godot/bin/libforja.linux.x86_64.so" ]] || { echo "sem o módulo: scripts/compilar.sh linux" >&2; exit 2; }

DEFEITOS=(troca-cruz-circulo analogico-curto gatilho-digital giro-invertido acel-escala um-dedo sem-clique
          vibra-vizinho motores-trocados luz-parada gatilho-mudo leds-errados led-mic-parado mudo-nao-chega
          sem-alto-falante som-vizinho haptica-trocada haptica-muda)

SAIDA="$(mktemp -d)"
trap 'rm -rf "$SAIDA"' EXIT
falhas=0

rodar() {
  local nome="$1"
  shift
  mkdir -p "$SAIDA/$nome"
  timeout 600 "$GODOT" --headless --fixed-fps 60 --path "$RAIZ/godot" res://testes/prova_do_jogo.tscn \
    -- --simular=4 --robo --semente="$SEMENTE" --relatorios="$SAIDA/$nome" "$@" >"$SAIDA/$nome.log" 2>&1
}

"$GODOT" --headless --path "$RAIZ/godot" --import >/dev/null 2>&1 || true

echo "==> limpo, quatro controles simulados"
if rodar limpo; then
  echo "    passou ($(grep -c '^ok' "$SAIDA/limpo.log") conferências)"
else
  echo "ERRO: a prova limpa falhou"
  grep -E "FAIL|SCRIPT ERROR" "$SAIDA/limpo.log" | head -20
  falhas=$((falhas + 1))
fi

for d in "${DEFEITOS[@]}"; do
  if rodar "$d" --defeitos="$d"; then
    echo "ERRO: o defeito «$d» passou — a prova não o pegou"
    falhas=$((falhas + 1))
  else
    echo "    «$d» pego: $(grep -m1 '^FAIL' "$SAIDA/$d.log" | sed 's/^FAIL *//')"
  fi
done

if [[ "$falhas" -gt 0 ]]; then
  echo "gauntlet: $falhas problema(s)"
  exit 1
fi
echo "gauntlet ok — limpo passa, e cada defeito de mentira é pego"
