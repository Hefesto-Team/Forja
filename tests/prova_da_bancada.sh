#!/usr/bin/env bash
# A prova da bancada, sem aparelho: os sete experimentos do experimental/,
# headless, com quatro DualSense simulados e o robô. O que precisa de aparelho
# de verdade (o microfone, o report cru) tem de sair "não medido", com o
# porquê; o que o simulador alcança (os quatro microfones, a háptica pelo nó)
# tem de sair medido — e, com os atuadores trocados, a háptica tem de falhar.
#
# Precisa do módulo compilado (scripts/compilar.sh linux).
# Uso: bash tests/prova_da_bancada.sh        (GODOT=<binário> para outro Godot)
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
source "$RAIZ/scripts/engine.sh"   # a versão da engine mora lá (ADR-009)
GODOT="$FORJA_GODOT"
[ -x "$GODOT" ] || { echo "sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>"; exit 2; }
# A caixa (tests/caixa.sh): sem ela, o P1 vira o DualSense ligado na máquina
# e os experimentos tocam o alto-falante, a háptica e os gatilhos dele.
source "$RAIZ/tests/caixa.sh"
caixa_pasta prova-da-bancada; TMP="$CAIXA_PASTA"   # no vermelho, a pasta fica em .cache/provas/ (WQ04)
caixa_montar "$TMP"
caixa "$GODOT" --headless --path "$RAIZ/godot" --import > "$TMP/import.log" 2>&1

FALHAS=0
rodar() {  # $1 experimento, $2 nome da rodada, depois os argumentos a mais
  local exp="$1" nome="$2"
  shift 2
  mkdir -p "$TMP/$nome"
  timeout 300 caixa "$GODOT" --headless --fixed-fps 60 --path "$RAIZ/godot" -- --simular=4 --robo --semente=7 \
    --experimento="$exp" --relatorios="$TMP/$nome" "$@" > "$TMP/$nome.log" 2>&1
  local rc=$?
  cat "$TMP/$nome"/registro-*.log 2>/dev/null | grep "experimento $exp ·" > "$TMP/$nome.linhas"
  if [ "$rc" -ne 0 ] || grep -q "SCRIPT ERROR" "$TMP/$nome.log"; then
    echo "FAIL $nome: o jogo saiu com erro (rc=$rc)"
    FALHAS=$((FALHAS + 1))
  fi
  # o erro do motor que não está em tests/erros_esperados.txt reprova (WQ01)
  caixa_julgar "$TMP/$nome.log" || FALHAS=$((FALHAS + 1))
}
esperar() {  # $1 rodada, $2 quantas linhas, $3 o padrão
  local n
  n=$(grep -c -- "$3" "$TMP/$1.linhas")
  if [ "$n" -eq "$2" ]; then
    echo "ok   $1: $2 × «$3»"
  else
    echo "FAIL $1: $n × «$3» (esperava $2)"
    sed 's/^/     /' "$TMP/$1.linhas"
    FALHAS=$((FALHAS + 1))
  fi
}

rodar laco laco
esperar laco 4 "nao_medido: sem microfone de verdade"
rodar quatro-mics quatro-mics
esperar quatro-mics 4 "medido: chegou som em 100% dos quadros"
esperar quatro-mics 1 "mesa · medido: 4 de 4 microfones"
rodar eco eco
esperar eco 4 "nao_medido: sem microfone de verdade"
rodar gatilho-cru gatilho-cru
esperar gatilho-cru 4 "nao_medido: sem o report cru USB 0x01"
rodar haptica-nomeada haptica-nomeada
esperar haptica-nomeada 4 "medido: «placa virtual do controle simulado», simulado: quatro canais, como no cabo: lado certo 4 de 4"
rodar haptica-nomeada haptica-trocada --defeitos=haptica-trocada
esperar haptica-trocada 4 "falhou: .*lado certo 0 de 4"

rodar haptico haptico
esperar haptico 36 "medido: "
rodar haptico motores-trocados --defeitos=motores-trocados
esperar motores-trocados 32 "falhou: "

# a força (F10): o jogo obedece ao arquivo de comandos do roteiro do rumble seco
printf '0 0.5 80\n1 1.0 80\n2 0.25 80\nparar 0\nfim\n' > "$TMP/forca.cmd"
rodar forca forca --comando="$TMP/forca.cmd"
esperar forca 3 "medido: força"
if [ "$(wc -l < "$TMP/forca.cmd.ok")" -eq 5 ] && [ "$(grep -c '^ok ' "$TMP/forca.cmd.ok")" -eq 3 ]; then
  echo "ok   forca: o jogo respondeu a cada comando (3 vibrações, parar, fim)"
else
  echo "FAIL forca: a resposta do jogo ao roteiro não bate"
  sed 's/^/     /' "$TMP/forca.cmd.ok"
  FALHAS=$((FALHAS + 1))
fi
printf '0 0.5 80\n1 1.0 80\n2 0.25 80\nfim\n' > "$TMP/forca-viz.cmd"
rodar forca forca-vizinho --comando="$TMP/forca-viz.cmd" --defeitos=vibra-vizinho
esperar forca-vizinho 3 "falhou: força"

[ "$FALHAS" -eq 0 ] || { echo "prova da bancada: $FALHAS falha(s)"; exit 1; }
echo "prova da bancada ok — o que precisa de aparelho diz que não mediu, e o que o simulador alcança mede"
