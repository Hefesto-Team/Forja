#!/usr/bin/env bash
# O ACE-Step 1.5, o motor da trilha (ficha H09; docs/DESENVOLVER.md "A trilha").
#
#   scripts/ace_step.sh instalar      baixa o projeto e as dependências em fontes/ace-step/
#   scripts/ace_step.sh servir        sobe o servidor de API na porta 8001 (deixe rodando)
#   scripts/ace_step.sh estado        diz o que já está instalado e se o servidor responde
#   scripts/ace_step.sh desinstalar   apaga a pasta, o ambiente e os pesos baixados
#
# Nada aqui depende da máquina de alguém: tudo sai da raiz do repositório e do
# $HOME. A pasta fontes/ está no .gitignore — nada disto entra no git.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASTA="${FORJA_ACE_STEP:-$RAIZ/fontes/ace-step}"
REPO="https://github.com/ACE-Step/ACE-Step-1.5.git"
PORTA="${FORJA_ACE_STEP_PORTA:-8001}"
# Onde o Hugging Face guarda os pesos; dentro do projeto, para o desinstalar
# levar tudo embora e o disco de casa não encher sem a gente ver.
export HF_HOME="${FORJA_HF_HOME:-$RAIZ/fontes/modelos}"

uv_bin() {
  if command -v uv >/dev/null 2>&1; then command -v uv
  elif [[ -x "$HOME/.local/bin/uv" ]]; then echo "$HOME/.local/bin/uv"
  else echo ""; fi
}

instalar() {
  local uv; uv="$(uv_bin)"
  if [[ -z "$uv" ]]; then
    echo "==> instalando o uv (o gerenciador de pacotes que o ACE-Step usa)"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    uv="$(uv_bin)"
    [[ -n "$uv" ]] || { echo "o uv não instalou; veja https://astral.sh/uv"; exit 1; }
  fi
  echo "==> uv: $uv"

  mkdir -p "$(dirname "$PASTA")" "$HF_HOME"
  if [[ -d "$PASTA/.git" ]]; then
    echo "==> o projeto já está em $PASTA; atualizando"
    git -C "$PASTA" pull --ff-only || echo "    (não deu para atualizar; sigo com o que está aqui)"
  else
    echo "==> baixando o ACE-Step 1.5 em $PASTA"
    git clone --depth 1 "$REPO" "$PASTA"
  fi

  echo "==> as dependências (PyTorch com CUDA e o resto; são vários GB, demora)"
  ( cd "$PASTA" && "$uv" sync )

  echo
  echo "Pronto. O servidor:  scripts/ace_step.sh servir"
  echo "Os pesos do modelo descem na primeira geração, para $HF_HOME."
  echo "Numa placa de 8 GB use o 2B turbo; o XL não cabe."
}

servir() {
  local uv; uv="$(uv_bin)"
  [[ -d "$PASTA" ]] || { echo "não instalado: scripts/ace_step.sh instalar"; exit 1; }

  # A placa tem 8 GB. Sem estes ajustes o ACE-Step ocupa ~6,8 GB e estoura na
  # primeira geração ("CUDA out of memory. Tried to allocate 14.00 MiB"),
  # porque o compositor, o navegador e o terminal também moram ali.
  #
  # - o modelo do ACE-Step não entra: quem escreve o prompt é o
  #   nosso descrever_trilha.py, com o Ollama, e os dois não cabem juntos;
  # - o decodificador (VAE) desce para a CPU, que é onde está o pico;
  # - o resto sai da placa entre uma faixa e outra.
  # Qualquer um se desfaz exportando a variável antes de chamar o script.
  export ACESTEP_INIT_modelo="${ACESTEP_INIT_modelo:-false}"
  export ACESTEP_VAE_ON_CPU="${ACESTEP_VAE_ON_CPU:-1}"
  export ACESTEP_OFFLOAD_TO_CPU="${ACESTEP_OFFLOAD_TO_CPU:-1}"
  export ACESTEP_SAVE_MEMORY="${ACESTEP_SAVE_MEMORY:-1}"
  export PYTORCH_ALLOC_CONF="${PYTORCH_ALLOC_CONF:-expandable_segments:True}"

  echo "==> o ACE-Step na porta $PORTA (Ctrl+C para parar); os pesos ficam em $HF_HOME"
  echo "    placa de 8 GB: sem o modelo, VAE na CPU, descarga entre as faixas"
  cd "$PASTA" && exec "$uv" run acestep-api
}

estado() {
  echo "pasta:   $PASTA $([[ -d "$PASTA" ]] && echo "(existe)" || echo "(não instalada)")"
  echo "ambiente: $PASTA/.venv $([[ -d "$PASTA/.venv" ]] && echo "(pronto)" || echo "(falta o uv sync)")"
  echo "pesos:   $HF_HOME ($(du -sh "$HF_HOME" 2>/dev/null | cut -f1 || echo 0))"
  if curl -fsS --max-time 2 "http://127.0.0.1:$PORTA/docs" >/dev/null 2>&1; then
    echo "servidor: responde em http://127.0.0.1:$PORTA"
  else
    echo "servidor: não responde na porta $PORTA (suba com: scripts/ace_step.sh servir)"
  fi
  command -v nvidia-smi >/dev/null && nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader
}

desinstalar() {
  echo "Isto apaga, sem volta:"
  echo "  $PASTA"
  echo "  $HF_HOME  ($(du -sh "$HF_HOME" 2>/dev/null | cut -f1 || echo 0) de pesos)"
  read -r -p "Apagar? [s/N] " r
  [[ "$r" == "s" || "$r" == "S" ]] || { echo "deixei como estava"; exit 0; }
  rm -rf "$PASTA" "$HF_HOME"
  echo "apagado. As faixas já escolhidas em godot/assets/ost/ ficaram onde estavam."
}

case "${1:-}" in
  instalar) instalar ;;
  servir) servir ;;
  estado) estado ;;
  desinstalar) desinstalar ;;
  *) sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
