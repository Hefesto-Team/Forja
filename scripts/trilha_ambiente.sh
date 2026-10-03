#!/usr/bin/env bash
# O ambiente da trilha: tudo o que a geração da OST precisa, numa pasta só.
#
#   scripts/trilha_ambiente.sh instalar      o ACE-Step, o Ollama e a tela do terminal
#   scripts/trilha_ambiente.sh estado        o que está instalado, e a memória da placa agora
#   scripts/trilha_ambiente.sh soltar        descarrega os modelos e devolve a memória da placa
#   scripts/trilha_ambiente.sh desinstalar   apaga tudo o que o instalar trouxe
#
# Nada pede senha: o Ollama entra como um arquivo em oficina/ollama/, não como
# serviço do sistema. Nada depende da máquina de alguém: tudo sai da raiz do
# repositório. A pasta oficina/ está no .gitignore.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OFICINA="${FORJA_OFICINA:-$RAIZ/oficina}"
OLLAMA_DIR="$OFICINA/ollama"
VENV="$OFICINA/trilha-venv"
export OLLAMA_MODELS="${OLLAMA_MODELS:-$OFICINA/modelos/ollama}"
export OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11434}"
OLLAMA_API="https://api.github.com/repos/ollama/ollama/releases/latest"
OLLAMA_PACOTE="ollama-linux-amd64.tar.zst"  ## o nome do pacote na release (mudou de .tgz em 2025)
MODELO_TEXTO="${FORJA_MODELO_TEXTO:-qwen3:8b}"

ollama_bin() {
  if [[ -x "$OLLAMA_DIR/bin/ollama" ]]; then echo "$OLLAMA_DIR/bin/ollama"
  elif command -v ollama >/dev/null 2>&1; then command -v ollama
  else echo ""; fi
}

uv_bin() {
  if command -v uv >/dev/null 2>&1; then command -v uv
  elif [[ -x "$HOME/.local/bin/uv" ]]; then echo "$HOME/.local/bin/uv"
  else echo ""; fi
}

instalar_ollama() {
  if [[ -n "$(ollama_bin)" ]]; then
    echo "==> o Ollama já está aqui: $(ollama_bin)"
    return
  fi
  command -v zstd >/dev/null || { echo "sem zstd: sudo apt install zstd"; exit 1; }
  local url
  url="$(curl -fsSL "$OLLAMA_API" | python3 -c "
import json, sys
alvo = '$OLLAMA_PACOTE'
d = json.load(sys.stdin)
for a in d.get('assets', []):
    if a['name'] == alvo:
        print(a['browser_download_url']); break
")"
  [[ -n "$url" ]] || { echo "não achei o $OLLAMA_PACOTE na última release do Ollama"; exit 1; }
  echo "==> baixando o Ollama (uns 1,5 GB, sem senha e sem serviço do sistema)"
  echo "    $url"
  mkdir -p "$OLLAMA_DIR" "$OLLAMA_MODELS"
  local tmp; tmp="$(mktemp -d)"
  curl -fL --progress-bar -o "$tmp/ollama.tar.zst" "$url" || { rm -rf "$tmp"; exit 1; }
  tar --zstd -xf "$tmp/ollama.tar.zst" -C "$OLLAMA_DIR" || { rm -rf "$tmp"; exit 1; }
  rm -rf "$tmp"
  [[ -x "$OLLAMA_DIR/bin/ollama" ]] || { echo "o pacote do Ollama veio com outra forma; veja $OLLAMA_DIR"; exit 1; }
  echo "==> Ollama em $OLLAMA_DIR/bin/ollama"
}

instalar_tela() {
  local uv; uv="$(uv_bin)"
  echo "==> a tela do terminal (Textual) em $VENV"
  if [[ -n "$uv" ]]; then
    "$uv" venv --python 3.12 "$VENV" >/dev/null
    VIRTUAL_ENV="$VENV" "$uv" pip install --quiet -r "$RAIZ/scripts/requisitos-trilha.txt"
  else
    python3 -m venv "$VENV"
    "$VENV/bin/pip" install --quiet --upgrade pip
    "$VENV/bin/pip" install --quiet -r "$RAIZ/scripts/requisitos-trilha.txt"
  fi
  echo "==> pronto: $VENV/bin/python"
}

instalar() {
  mkdir -p "$OFICINA"
  bash "$RAIZ/scripts/ace_step.sh" instalar
  instalar_ollama
  instalar_tela
  echo
  echo "Falta só o modelo de texto (uns 5 GB), que desce na primeira vez:"
  echo "  scripts/trilha_ambiente.sh modelo"
  echo
  echo "Depois, a tela:  scripts/trilha_ambiente.sh tela"
}

modelo() {
  local ob; ob="$(ollama_bin)"
  [[ -n "$ob" ]] || { echo "sem Ollama: scripts/trilha_ambiente.sh instalar"; exit 1; }
  echo "==> subindo o Ollama só para baixar o $MODELO_TEXTO"
  "$ob" serve >/dev/null 2>&1 &
  local pid=$!
  sleep 2
  "$ob" pull "$MODELO_TEXTO"
  "$ob" stop "$MODELO_TEXTO" 2>/dev/null || true
  kill "$pid" 2>/dev/null || true
  echo "==> $MODELO_TEXTO pronto, e a placa devolvida"
}

tela() {
  [[ -x "$VENV/bin/python" ]] || { echo "sem a tela: scripts/trilha_ambiente.sh instalar"; exit 1; }
  exec "$VENV/bin/python" "$RAIZ/scripts/trilha_tui.py" "$@"
}

soltar() {
  local ob; ob="$(ollama_bin)"
  if [[ -n "$ob" ]]; then
    local carregados
    carregados="$("$ob" ps 2>/dev/null | tail -n +2 | awk '{print $1}' || true)"
    for m in $carregados; do
      echo "==> descarregando $m"
      "$ob" stop "$m" 2>/dev/null || true
    done
  fi
  pkill -f "acestep-api" 2>/dev/null && echo "==> servidor do ACE-Step parado" || true
  sleep 1
  command -v nvidia-smi >/dev/null && nvidia-smi --query-gpu=memory.used,memory.free --format=csv,noheader
}

estado() {
  bash "$RAIZ/scripts/ace_step.sh" estado
  echo "ollama:  $(ollama_bin || true) ${OLLAMA_MODELS}"
  if [[ -n "$(ollama_bin)" ]]; then "$(ollama_bin)" ps 2>/dev/null || echo "  (não está no ar)"; fi
  echo "tela:    $VENV $([[ -x "$VENV/bin/python" ]] && echo "(pronta)" || echo "(falta)")"
}

desinstalar() {
  soltar
  echo "Isto apaga, sem volta: $OLLAMA_DIR, $VENV, $OLLAMA_MODELS e a pasta do ACE-Step."
  read -r -p "Apagar? [s/N] " r
  [[ "$r" == "s" || "$r" == "S" ]] || { echo "deixei como estava"; exit 0; }
  rm -rf "$OLLAMA_DIR" "$VENV" "$OLLAMA_MODELS"
  bash "$RAIZ/scripts/ace_step.sh" desinstalar
}

case "${1:-}" in
  instalar) instalar ;;
  modelo) modelo ;;
  tela) shift; tela "$@" ;;
  estado) estado ;;
  soltar) soltar ;;
  desinstalar) desinstalar ;;
  *) sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
