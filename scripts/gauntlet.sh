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
source "$RAIZ/scripts/engine.sh"   # a versão da engine mora lá (ADR-009)
GODOT="$FORJA_GODOT"
SEMENTE="${SEMENTE:-7}"
[[ -x "$GODOT" ]] || { echo "sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>" >&2; exit 2; }
[[ -f "$RAIZ/godot/bin/libforja.linux.x86_64.so" ]] || { echo "sem o módulo: scripts/compilar.sh linux" >&2; exit 2; }

DEFEITOS=(troca-cruz-circulo analogico-curto gatilho-digital giro-invertido acel-escala um-dedo sem-clique
          vibra-vizinho motores-trocados luz-parada gatilho-mudo leds-errados led-mic-parado mudo-nao-chega
          sem-alto-falante som-vizinho haptica-trocada haptica-muda mic-surdo engasga)

# a caixa (tests/caixa.sh): o jogo não acha o controle ligado na máquina
source "$RAIZ/tests/caixa.sh"
caixa_pasta gauntlet; SAIDA="$CAIXA_PASTA"   # no vermelho, a pasta fica em .cache/provas/ (WQ04)
caixa_montar "$SAIDA/caixa"
falhas=0

# --acelerado (a WE02): a prova do kit conta os prazos em quadros e o Ritmo mede o tempo do jogo, como na
# tests/prova_do_jogo.sh; no relógio de parede, a máquina carregada muda o julgamento
rodar() {
  local nome="$1"
  shift
  mkdir -p "$SAIDA/$nome"
  timeout 600 caixa "$GODOT" --headless --fixed-fps 60 --path "$RAIZ/godot" res://testes/prova_do_jogo.tscn \
    -- --simular=4 --robo --semente="$SEMENTE" --relatorios="$SAIDA/$nome" --bancada --acelerado "$@" >"$SAIDA/$nome.log" 2>&1
}

caixa "$GODOT" --headless --path "$RAIZ/godot" --import >/dev/null 2>&1 || true

# o erro do motor que não está em tests/erros_esperados.txt conta como problema,
# no limpo e em cada defeito (WQ01): o defeito tem de ser pego pela prova, não
# por um erro do motor
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
