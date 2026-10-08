#!/usr/bin/env bash
# Deixa uma sessão nova na nuvem pronta para provar: pacotes de sistema, módulo
# nativo e Godot. É o que o gancho de início de sessão chama (o gancho mora na
# configuração da própria sessão, fora do repositório).
#
#   FORJA_NUVEM=1 scripts/preparar_sessao.sh
#
# Fora da nuvem (a máquina de quem desenvolve) não faz nada. Dentro dela é
# idempotente e rápido quando já está tudo pronto. Não abre janela nenhuma:
# nunca chama o run-local.sh.
# A versão da engine mora em scripts/engine.sh; o módulo, em scripts/compilar.sh.
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"

# O gancho de início de sessão da nuvem chama o script com FORJA_NUVEM=1; na
# máquina de quem desenvolve a variável não existe, e o script sai sem tocar
# em nada.
if [[ "${FORJA_NUVEM:-}" != "1" ]]; then
  exit 0
fi

# Os pacotes de docs/DESENVOLVER.md, mais bubblewrap e xvfb (a prova do jogo
# roda num /dev novo, e a prova visual da F09 roda com janela virtual).
PACOTES=(build-essential cmake ninja-build pkg-config git curl unzip
  libasound2-dev libpulse-dev libpipewire-0.3-dev
  libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxfixes-dev libxi-dev libxss-dev libxtst-dev libxkbcommon-dev
  libwayland-dev wayland-protocols libdecor-0-dev libdrm-dev libgbm-dev libgl1-mesa-dev libegl1-mesa-dev
  libdbus-1-dev libudev-dev
  bubblewrap xvfb)

faltam=()
for p in "${PACOTES[@]}"; do
  dpkg -s "$p" > /dev/null 2>&1 || faltam+=("$p")
done
if ((${#faltam[@]} > 0)); then
  echo "==> pacotes que faltam: ${faltam[*]}"
  SUDO=()
  [[ "$(id -u)" -eq 0 ]] || SUDO=(sudo)
  "${SUDO[@]}" apt-get update -qq
  "${SUDO[@]}" apt-get install -y -qq "${faltam[@]}"
fi

# O Godot da versão fixada em scripts/engine.sh. O download cai num arquivo
# temporário: se falhar, não sobra meio arquivo em tools/.
source "$RAIZ/scripts/engine.sh"
if ! forja_baixar_engine; then
  echo "ERRO: sem o Godot ${FORJA_GODOT_VER}: a rede falhou. Rode de novo quando houver rede, ou ponha o binário em tools/." >&2
  exit 1
fi

# O módulo: a primeira vez baixa o SDL e o godot-cpp e compila tudo (~70 s);
# depois o cache em .cache/ responde.
if [[ ! -f "$RAIZ/godot/bin/libforja.linux.x86_64.so" ]]; then
  echo "==> módulo nativo (a primeira vez demora)"
  "$RAIZ/scripts/compilar.sh" linux
fi

echo "Ambiente pronto: módulo, Godot, pacotes."
