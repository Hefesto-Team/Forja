#!/usr/bin/env bash
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"

if [[ "${FORJA_NUVEM:-}" != "1" ]]; then
  exit 0
fi

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

source "$RAIZ/scripts/engine.sh"
if ! forja_baixar_engine; then
  echo "ERRO: sem o Godot ${FORJA_GODOT_VER}: a rede falhou. Rode de novo quando houver rede, ou ponha o binário em tools/." >&2
  exit 1
fi

if [[ ! -f "$RAIZ/godot/bin/libforja.linux.x86_64.so" ]]; then
  echo "==> módulo nativo (a primeira vez demora)"
  "$RAIZ/scripts/compilar.sh" linux
fi

echo "Ambiente pronto: módulo, Godot, pacotes."
