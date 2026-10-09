#!/usr/bin/env bash
# O ambiente da Forja, numa máquina nova (Debian, Ubuntu ou Pop!_OS).
#
#   scripts/instalar.sh conferir   diz o que falta e não instala nada
#   scripts/instalar.sh sistema    os pacotes de scripts/requisitos-sistema.txt (pede senha)
#   scripts/instalar.sh modulo     compila o módulo nativo e baixa a engine
#   scripts/instalar.sh trilha     o gerador de música (placa de vídeo; uns 20 GB)
#   scripts/instalar.sh tudo       os três, nesta ordem
#   scripts/instalar.sh desinstalar  tira o que a Forja trouxe (pede senha)
#
# Nada aqui conhece a máquina de ninguém: tudo sai da raiz do repositório e do
# $HOME de quem roda. A senha, quando é pedida, é a do próprio sudo e não fica
# gravada em lugar nenhum.
#
# Quem só quer jogar e mexer no jogo precisa de «sistema» e «modulo». A
# «trilha» só interessa a quem vai gerar música, e pede placa de vídeo.
set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LISTA="$RAIZ/scripts/requisitos-sistema.txt"
OFICINA="${FORJA_OFICINA:-$RAIZ/oficina}"
# Os pacotes que a Forja instalou nesta máquina, um por linha. O que já estava
# aqui antes não entra, e por isso o desinstalar nunca tira o que era seu.
REGISTRO="$OFICINA/pacotes-do-sistema.txt"

if [[ -t 1 ]]; then
  N=$'\e[0m'; B=$'\e[1m'; VERDE=$'\e[38;5;114m'; AMARELO=$'\e[38;5;222m'; CINZA=$'\e[38;5;245m'
else
  N=""; B=""; VERDE=""; AMARELO=""; CINZA=""
fi
ok()    { printf '  %sok%s    %s\n' "$VERDE" "$N" "$*"; }
falta() { printf '  %sfalta%s %s\n' "$AMARELO" "$N" "$*"; }
titulo(){ printf '\n%s%s%s\n' "$B" "$*" "$N"; }

pacotes_da_lista() {
  grep -vE '^\s*(#|$)' "$LISTA" | awk '{print $1}'
}

pacotes_que_faltam() {
  local faltam=()
  while read -r p; do
    [[ -z "$p" ]] && continue
    dpkg -s "$p" >/dev/null 2>&1 || faltam+=("$p")
  done < <(pacotes_da_lista)
  printf '%s\n' "${faltam[@]}"
}

tem_apt() { command -v apt-get >/dev/null 2>&1; }

placa() {
  if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
    nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader | head -1
  elif [[ -d /sys/class/drm/card0 ]] && command -v lspci >/dev/null 2>&1 && lspci 2>/dev/null | grep -qi "amd/ati"; then
    echo "AMD (sem CUDA)"
  else
    echo ""
  fi
}

# ---------------------------------------------------------------- conferir --

conferir() {
  titulo "O sistema"
  if ! tem_apt; then
    falta "esta máquina não usa apt; instale à mão o que está em scripts/requisitos-sistema.txt"
  else
    local faltam; faltam="$(pacotes_que_faltam | grep -v '^$' || true)"
    if [[ -z "$faltam" ]]; then
      ok "os $(pacotes_da_lista | wc -l) pacotes estão instalados"
    else
      falta "$(echo "$faltam" | wc -l) pacote(s): $(echo "$faltam" | tr '\n' ' ')"
      echo "        scripts/instalar.sh sistema"
    fi
  fi

  titulo "O jogo"
  if [[ -f "$RAIZ/godot/bin/libforja.linux.x86_64.so" ]]; then
    ok "o módulo nativo está compilado"
  else
    falta "o módulo nativo (scripts/instalar.sh modulo)"
  fi
  local engine; engine="$(ls "$RAIZ"/tools/Godot_v*_linux.x86_64 2>/dev/null | tail -1)"
  if [[ -x "$engine" ]]; then
    ok "a engine: $("$engine" --version 2>/dev/null | tail -1)"
  else
    falta "a engine em tools/ (scripts/instalar.sh modulo)"
  fi

  titulo "A trilha (só para quem gera música)"
  local p; p="$(placa)"
  if [[ -z "$p" ]]; then
    falta "nenhuma placa de vídeo com CUDA; a geração roda só na CPU, e é lenta"
  else
    ok "placa: $p"
    local livre; livre="$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)"
    if [[ -n "$livre" && "$livre" -lt 7000 ]]; then
      falta "menos de 7 GB de memória de vídeo: o modelo de música não cabe inteiro"
    fi
  fi
  [[ -d "$RAIZ/oficina/ace-step" ]] && ok "o gerador de música" || falta "o gerador de música (scripts/instalar.sh trilha)"
  [[ -x "$RAIZ/oficina/ollama/bin/ollama" ]] || command -v ollama >/dev/null 2>&1 \
    && ok "o modelo de texto" || falta "o modelo de texto (scripts/instalar.sh trilha)"
  [[ -x "$RAIZ/oficina/trilha-venv/bin/python" ]] && ok "a tela da bancada" || falta "a tela da bancada (scripts/instalar.sh trilha)"

  titulo "Como abrir"
  echo "  ./run.sh"
}

# ---------------------------------------------------------------- instalar --

sistema() {
  tem_apt || { echo "esta máquina não usa apt. Instale à mão o que está em $LISTA"; exit 1; }
  local faltam; faltam="$(pacotes_que_faltam | grep -v '^$' || true)"
  if [[ -z "$faltam" ]]; then
    ok "nada a instalar: os pacotes já estão aqui"
    return 0
  fi
  echo "Vou instalar $(echo "$faltam" | wc -l) pacote(s) com o apt:"
  echo "$faltam" | sed 's/^/  /'
  echo
  echo "${CINZA}O sudo vai pedir a sua senha. Ela não fica gravada em lugar nenhum.${N}"
  # shellcheck disable=SC2086
  sudo apt-get update -qq && sudo apt-get install -y $(echo "$faltam" | tr '\n' ' ')
  mkdir -p "$OFICINA"
  local p
  while read -r p; do
    dpkg -s "$p" >/dev/null 2>&1 && echo "$p"
  done <<<"$faltam" | cat - "$REGISTRO" 2>/dev/null | sort -u >"$REGISTRO.novo"
  mv "$REGISTRO.novo" "$REGISTRO"
  local resto; resto="$(pacotes_que_faltam | grep -v '^$' || true)"
  [[ -z "$resto" ]] && ok "o sistema está pronto" || falta "ainda faltam: $resto"
}

modulo() {
  echo "==> compilando o módulo nativo (a primeira vez baixa o SDL3 e a godot-cpp)"
  bash "$RAIZ/scripts/compilar.sh" linux || return 1
  echo "==> a engine"
  # quem baixa a engine é o run-local.sh; aqui só a parte que não abre o jogo
  bash "$RAIZ/scripts/baixar_engine.sh" || return 1
  ok "o jogo está pronto: ./run.sh"
}

trilha() {
  local p; p="$(placa)"
  if [[ -z "$p" ]]; then
    echo "${AMARELO}Sem placa com CUDA, a geração de música roda na CPU e leva horas por faixa.${N}"
    read -r -p "Instalar mesmo assim? [s/N] " r
    [[ "$r" == "s" || "$r" == "S" ]] || return 0
  fi
  bash "$RAIZ/scripts/trilha_ambiente.sh" instalar || return 1
  bash "$RAIZ/scripts/trilha_ambiente.sh" modelo || return 1
  ok "a trilha está pronta: ./run.sh trilha"
}

# ------------------------------------------------------------- desinstalar --

desinstalar() {
  titulo "A trilha"
  if [[ -d "$OFICINA/ace-step" || -d "$OFICINA/ollama" || -d "$OFICINA/trilha-venv" ]]; then
    bash "$RAIZ/scripts/trilha_ambiente.sh" desinstalar
  else
    ok "nada da trilha nesta máquina"
  fi

  titulo "O sistema"
  local meus=""
  [[ -s "$REGISTRO" ]] && meus="$(grep -vE '^\s*(#|$)' "$REGISTRO" | while read -r p; do
    dpkg -s "$p" >/dev/null 2>&1 && echo "$p"; done || true)"
  if [[ -z "$meus" ]]; then
    ok "a Forja não instalou nenhum pacote nesta máquina"
    return 0
  fi
  echo "A Forja instalou $(echo "$meus" | wc -l) pacote(s) nesta máquina:"
  echo "$meus" | sed 's/^/  /'
  echo "${CINZA}O que já estava aqui antes da Forja não está nesta lista e fica.${N}"
  read -r -p "Remover? [s/N] " r
  [[ "$r" == "s" || "$r" == "S" ]] || { echo "deixei como estava"; return 0; }
  # shellcheck disable=SC2086
  sudo apt-get remove -y $(echo "$meus" | tr '\n' ' ') && rm -f "$REGISTRO"
}

case "${1:-conferir}" in
  conferir) conferir ;;
  sistema)  sistema ;;
  modulo)   modulo ;;
  trilha)   trilha ;;
  tudo)     sistema && modulo && trilha && conferir ;;
  desinstalar) desinstalar ;;
  *) sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
