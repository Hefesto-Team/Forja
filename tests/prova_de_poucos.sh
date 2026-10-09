#!/usr/bin/env bash
# A prova de poucos, sem janela: toda sala jogável com 1, 2 ou 3 controles
# (o robô joga as nove com N DualSense simulados, e cada sala diz no aviso o
# que muda), e a sala sem o recurso — com o microfone mudo no sistema
# (o defeito de mentira mic-surdo), A Voz segue sozinha e o veredito fica
# "não medido", nunca "falhou". E os ritmos (--nivel=0 e 2): as janelas de
# tempo mudam, e o robô ainda passa sem nenhum "falhou". E o controle que cai
# (CABO=1): em cada sala o cabo do P2 sai e volta; a sala segue, o lugar
# espera, o controle volta ao mesmo lugar, e ninguém sai com "falhou".
#
# Precisa do módulo compilado (scripts/compilar.sh linux).
# Uso: bash tests/prova_de_poucos.sh        (GODOT=<binário> para outro Godot)
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
source "$RAIZ/scripts/engine.sh"   # a versão da engine mora lá (ADR-009)
GODOT="$FORJA_GODOT"
[ -x "$GODOT" ] || { echo "sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>"; exit 2; }
# a caixa (tests/caixa.sh): o jogo não acha o controle ligado na máquina
source "$RAIZ/tests/caixa.sh"
caixa_pasta prova-de-poucos; TMP="$CAIXA_PASTA"   # no vermelho, a pasta fica em .cache/provas/ (WQ04)
caixa_montar "$TMP"

caixa "$GODOT" --headless --path "$RAIZ/godot" --import --quit > "$TMP/import.log" 2>&1

rodar() {
  local nome="$1"
  shift
  mkdir -p "$TMP/rel-$nome"
  timeout 600 caixa "$GODOT" --headless --fixed-fps 60 --path "$RAIZ/godot" res://testes/prova_de_poucos.tscn \
    -- --robo --semente=7 --relatorios="$TMP/rel-$nome" --bancada "$@" > "$TMP/$nome.log" 2>&1
  local rc=$?
  grep -E "FAIL|SCRIPT ERROR|prova de poucos ok" "$TMP/$nome.log"
  # o erro do motor que não está em tests/erros_esperados.txt reprova (WQ01)
  local juizo=0
  caixa_julgar "$TMP/$nome.log" || juizo=1
  [ "$rc" -eq 0 ] || { echo "FAIL a prova de poucos «$nome» (rc=$rc)"; return 1; }
  return "$juizo"
}

FALHAS=0
rodar um --simular=1 & a=$!
rodar dois --simular=2 & b=$!
rodar tres --simular=3 & c=$!
for p in $a $b $c; do wait "$p" || FALHAS=$((FALHAS + 1)); done
SALAS=voz rodar mudo-no-sistema --simular=4 --defeitos=mic-surdo & d=$!
# os ritmos: as janelas de tempo mudam, a medida não
SALAS=centelha,impacto,galeria,prova rodar rapido --simular=4 --nivel=2 & e=$!
SALAS=centelha,impacto,galeria,prova rodar primeira-vez --simular=2 --nivel=0 & f=$!
# as opções do lugar: a vibração do P2 em 0% e o gatilho do P3 desligado
OPCOES_DE_TESTE=1 SALAS=impacto,galeria,caminhos rodar opcoes --simular=4 & g=$!
for p in $d $e $f $g; do wait "$p" || FALHAS=$((FALHAS + 1)); done
# o controle que cai: em cada sala, o cabo do P2 sai por 3 s e volta
CABO=1 rodar cabo --simular=4 || FALHAS=$((FALHAS + 1))
[ "$FALHAS" -eq 0 ] || exit 1
echo "prova de poucos ok — as nove salas com 1, 2 e 3 controles, A Voz com o microfone mudo no sistema, os três ritmos, as opções e o controle que cai"
