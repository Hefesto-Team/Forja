#!/usr/bin/env bash
# A fila da trilha: gera as candidatas de cada faixa, uma faixa por vez, em
# segundo plano, sem travar a máquina de quem está usando.
#
#   scripts/trilha_fila.sh ligar [SLOT...]   começa (sem SLOT: toda faixa MUS_ com menos de N candidatas)
#   scripts/trilha_fila.sh estado            a faixa da vez, quantas faltam, a placa e o fim do registro
#   scripts/trilha_fila.sh desligar          para a fila e devolve a placa
#
# O que segura a máquina:
#   - roda como serviço do usuário (systemd-run), fora do terminal: fechar o
#     terminal não para a fila, e a fila não leva o terminal junto;
#   - teto de memória (TRILHA_RAM, padrão 6G) e prioridade baixa de CPU e disco;
#     se a memória acabar, quem morre é a fila (OOMScoreAdjust alto), não a tela;
#   - a placa: a faixa só começa com a placa quase vazia (TRILHA_PLACA_MIB usados
#     por outros, padrão 2500) e sem jogo aberto; se um jogo abre ou a placa
#     enche no meio, a fila mata o gerador, solta o modelo e espera. A faixa
#     interrompida volta para a fila.
#
# A escolha da candidata é de quem escuta: scripts/gerar_trilha.py ouvir e escolher.
set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OFICINA="${FORJA_OFICINA:-$RAIZ/oficina}"
export FORJA_TRILHA="${FORJA_TRILHA:-$OFICINA/trilha}"
export FORJA_ACE_STEP="${FORJA_ACE_STEP:-$OFICINA/ace-step}"
export FORJA_HF_HOME="${FORJA_HF_HOME:-$OFICINA/modelos}"
UNIDADE=forja-trilha-fila
N="${TRILHA_N:-4}"
RAM="${TRILHA_RAM:-6G}"
PLACA_MIB="${TRILHA_PLACA_MIB:-2500}"
PORTA="${FORJA_ACE_STEP_PORTA:-8001}"
REGISTRO="$FORJA_TRILHA/fila.log"

diz() { echo "$(date +%H:%M:%S) $*" | tee -a "$REGISTRO"; }

placa_usada() { nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null | head -1; }
placa_livre() { nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits 2>/dev/null | head -1; }

# Um jogo aberto: a Steam (SteamLaunch, o reaper, o Proton) ou a Forja numa janela de verdade.
jogo_aberto() {
  pgrep -f 'SteamLaunch AppId|/proton |wine64-preloader' >/dev/null && return 0
  # a Forja na tela: o Godot de verdade (não o timeout nem o xvfb-run que o chamam), sem --headless e fora
  # da tela de mentira (o xvfb-run -a usa :99 em diante)
  local p
  for p in $(pgrep -f Godot_v); do
    [[ "$(readlink "/proc/$p/exe" 2>/dev/null)" == *Godot_v* ]] || continue
    tr '\0' ' ' <"/proc/$p/cmdline" 2>/dev/null | grep -q -- '--headless' && continue
    tr '\0' '\n' <"/proc/$p/environ" 2>/dev/null | grep -qE '^DISPLAY=:9[0-9]+' && continue
    return 0
  done
  return 1
}

servidor_responde() { curl -fsS --max-time 2 "http://127.0.0.1:$PORTA/health" >/dev/null 2>&1 \
  || curl -fsS --max-time 2 "http://127.0.0.1:$PORTA/docs" >/dev/null 2>&1; }

soltar() {
  [[ -n "${GERADOR:-}" ]] && kill "$GERADOR" 2>/dev/null
  [[ -n "${SERVIDOR:-}" ]] && pkill -TERM -P "$SERVIDOR" 2>/dev/null; [[ -n "${SERVIDOR:-}" ]] && kill "$SERVIDOR" 2>/dev/null
  pkill -f acestep-api 2>/dev/null
  GERADOR="" SERVIDOR=""
  sleep 3
}

candidatas() { ls "$FORJA_TRILHA/$1"/*.wav 2>/dev/null | wc -l; }

a_fazer() {
  if [[ $# -gt 0 ]]; then printf '%s\n' "$@"; return; fi
  python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
for s in d["faixas"]:
    if s.startswith("MUS_"):
        print(s)' "$RAIZ/scripts/trilha_prompts.json"
}

esperar_a_vez() {
  local avisou=0
  while :; do
    local usada; usada="$(placa_usada)"
    if ! jogo_aberto && [[ -n "$usada" && "$usada" -le "$PLACA_MIB" ]]; then return; fi
    [[ $avisou -eq 0 ]] && diz "esperando a vez (jogo aberto ou placa com ${usada:-?} MiB usados)" && avisou=1
    sleep 30
  done
}

subir_servidor() {
  servidor_responde && return 0
  diz "subindo o ACE-Step"
  bash "$RAIZ/scripts/ace_step.sh" servir >>"$FORJA_TRILHA/ace-step.log" 2>&1 &
  SERVIDOR=$!
  for _ in $(seq 1 120); do servidor_responde && return 0; sleep 5; done
  diz "o ACE-Step não subiu em 10 min (ver $FORJA_TRILHA/ace-step.log)"
  soltar
  return 1
}

# Uma faixa: 0 pronta, 1 interrompida (volta para a fila), 2 falhou.
uma_faixa() {
  local slot="$1" falta; falta=$((N - $(candidatas "$slot")))
  [[ $falta -le 0 ]] && return 0
  esperar_a_vez
  subir_servidor || return 2
  diz "$slot: $falta candidata(s)"
  python3 "$RAIZ/scripts/gerar_trilha.py" gerar "$slot" -n "$falta" >>"$REGISTRO" 2>&1 &
  GERADOR=$!
  local cheia=0
  while kill -0 "$GERADOR" 2>/dev/null; do
    sleep 5
    if jogo_aberto; then diz "$slot: um jogo abriu; solto a placa e espero"; soltar; return 1; fi
    local livre; livre="$(placa_livre)"
    if [[ -n "$livre" && "$livre" -lt 300 ]]; then cheia=$((cheia + 1)); else cheia=0; fi
    if [[ $cheia -ge 3 ]]; then diz "$slot: a placa encheu (${livre} MiB livres); solto e espero"; soltar; sleep 60; return 1; fi
  done
  wait "$GERADOR"; local rc=$?
  GERADOR=""
  [[ $rc -eq 0 ]] && { diz "$slot: pronta ($(candidatas "$slot") candidatas)"; return 0; }
  diz "$slot: o gerador saiu com $rc"
  return 2
}

rodar() {
  mkdir -p "$FORJA_TRILHA"
  trap 'soltar; diz "fila parada"; exit 0' TERM INT
  diz "fila começou: N=$N, teto de RAM $RAM, placa até $PLACA_MIB MiB usados por outros"
  local slot falhas
  for slot in $(a_fazer "$@"); do
    falhas=0
    while :; do
      uma_faixa "$slot"; local r=$?
      [[ $r -eq 0 ]] && break
      [[ $r -eq 2 ]] && falhas=$((falhas + 1))
      [[ $falhas -ge 2 ]] && { diz "$slot: falhou duas vezes; sigo para a próxima"; break; }
    done
  done
  soltar
  diz "fila terminou. Escute: python3 scripts/gerar_trilha.py ouvir"
}

case "${1:-estado}" in
  ligar)
    shift
    if systemctl --user is-active -q "$UNIDADE"; then echo "a fila já roda (scripts/trilha_fila.sh estado)"; exit 0; fi
    mkdir -p "$FORJA_TRILHA"
    systemd-run --user --unit "$UNIDADE" --collect --quiet \
      -p MemoryMax="$RAM" -p MemorySwapMax=0 -p OOMScoreAdjust=900 \
      -p CPUWeight=20 -p IOWeight=20 -p Nice=15 \
      --setenv=FORJA_TRILHA="$FORJA_TRILHA" --setenv=FORJA_ACE_STEP="$FORJA_ACE_STEP" \
      --setenv=FORJA_HF_HOME="$FORJA_HF_HOME" --setenv=TRILHA_N="$N" \
      --setenv=TRILHA_PLACA_MIB="$PLACA_MIB" --setenv=PATH="$PATH" \
      bash "$RAIZ/scripts/trilha_fila.sh" _rodar "$@"
    echo "a fila começou, fora do terminal. Acompanhar: scripts/trilha_fila.sh estado"
    ;;
  _rodar) shift; rodar "$@" ;;
  desligar)
    systemctl --user stop "$UNIDADE" 2>/dev/null
    pkill -f acestep-api 2>/dev/null
    echo "fila parada, placa devolvida"
    ;;
  estado)
    systemctl --user is-active -q "$UNIDADE" && echo "fila: rodando" || echo "fila: parada"
    total=0 prontas=0
    for s in $(a_fazer); do total=$((total + 1)); [[ $(candidatas "$s") -ge $N ]] && prontas=$((prontas + 1)); done
    echo "faixas com $N candidatas: $prontas de $total"
    echo "placa: $(placa_usada) MiB usados, $(placa_livre) MiB livres"
    [[ -f "$REGISTRO" ]] && grep -E '^[0-9]{2}:' "$REGISTRO" | tail -5
    true
    ;;
  *) sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
