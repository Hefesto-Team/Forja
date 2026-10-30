#!/usr/bin/env bash
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
source "$RAIZ/scripts/engine.sh"
GODOT="$FORJA_GODOT"
[ -x "$GODOT" ] || { echo "sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>"; exit 2; }
source "$RAIZ/tests/caixa.sh"
caixa_pasta prova-de-poucos; TMP="$CAIXA_PASTA"
caixa_montar "$TMP"

caixa "$GODOT" --headless --path "$RAIZ/godot" --import --quit > "$TMP/import.log" 2>&1

rodar() {
  local nome="$1"
  shift
  mkdir -p "$TMP/rel-$nome"
  timeout 600 caixa "$GODOT" --headless --fixed-fps 60 --path "$RAIZ/godot" res://testes/prova_de_poucos.tscn \
    -- --robo --semente=7 --relatorios="$TMP/rel-$nome" --bancada --acelerado "$@" > "$TMP/$nome.log" 2>&1
  local rc=$?
  grep -E "FAIL|SCRIPT ERROR|prova de poucos ok" "$TMP/$nome.log"
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
SALAS=centelha,impacto,galeria,prova rodar rapido --simular=4 --nivel=2 & e=$!
SALAS=centelha,impacto,galeria,prova rodar primeira-vez --simular=2 --nivel=0 & f=$!
OPCOES_DE_TESTE=1 SALAS=impacto,galeria,caminhos rodar opcoes --simular=4 & g=$!
for p in $d $e $f $g; do wait "$p" || FALHAS=$((FALHAS + 1)); done
CABO=1 rodar cabo --simular=4 || FALHAS=$((FALHAS + 1))
CABO_SOZINHO=1 SALAS=galeria,centelha rodar sozinho-sem-cabo --simular=1 || FALHAS=$((FALHAS + 1))
[ "$FALHAS" -eq 0 ] || exit 1
echo "prova de poucos ok — as nove salas com 1, 2 e 3 controles, A Voz com o microfone mudo no sistema, os três ritmos, as opções e o controle que cai (com quatro e sozinho)"
