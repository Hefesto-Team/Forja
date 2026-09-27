#!/usr/bin/env bash
# Build reproduzível da Hefesto Tech Demo.
#
#   scripts/compilar.sh linux      binário Linux nativo       -> build/linux/
#   scripts/compilar.sh windows    .exe Windows (mingw-w64)   -> build/windows/
#   scripts/compilar.sh testes     só a lógica, sem SDL        -> build/testes/
#   scripts/compilar.sh tudo       os três, e os pacotes em dist/
#
# Reproduzível quer dizer: o SDL3 entra por versão E por sha256 (nunca "o que
# a distro tiver"), os caminhos da máquina saem do binário (-ffile-prefix-map)
# e os pacotes carregam a data do último commit, não a hora do build.
#
# O SDL3 é o 3.4.14 — a mesma série que a Steam distribui no runtime, e a que o
# Hefesto usa como régua ("medir contra a SDL3 que a Steam distribui").
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$RAIZ"

SDL_VERSAO="3.4.14"
SDL_SHA256="30d4aa2b3037718142b32dffd4e72f917ebb6cc5227150e7bb9c45efb2153aeb"
SDL_URL="https://github.com/libsdl-org/SDL/releases/download/release-${SDL_VERSAO}/SDL3-${SDL_VERSAO}.tar.gz"

CACHE="${FORJA_CACHE:-$RAIZ/.cache}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
TIPO="${FORJA_BUILD_TIPO:-Release}"

if [[ -z "${SOURCE_DATE_EPOCH:-}" ]]; then
  SOURCE_DATE_EPOCH="$(git -C "$RAIZ" log -1 --format=%ct 2>/dev/null || echo 0)"
fi
export SOURCE_DATE_EPOCH

# Tira da string de debug e das macros __FILE__ o caminho desta máquina.
MAPA="-ffile-prefix-map=$RAIZ=. -ffile-prefix-map=$CACHE=.cache"

diga() { printf '==> %s\n' "$*"; }

baixar_sdl() {
  local tar="$CACHE/SDL3-${SDL_VERSAO}.tar.gz"
  mkdir -p "$CACHE"
  if [[ ! -f "$tar" ]]; then
    diga "baixando SDL ${SDL_VERSAO}"
    curl -fsSL -o "$tar.parcial" "$SDL_URL"
    mv "$tar.parcial" "$tar"
  fi
  local tem
  tem="$(sha256sum "$tar" | cut -d' ' -f1)"
  if [[ "$tem" != "$SDL_SHA256" ]]; then
    echo "sha256 do SDL não confere: $tem (esperado $SDL_SHA256)" >&2
    rm -f "$tar"
    exit 1
  fi
  if [[ ! -d "$CACHE/src/SDL3-${SDL_VERSAO}" ]]; then
    mkdir -p "$CACHE/src"
    tar -xzf "$tar" -C "$CACHE/src"
  fi
}

# $1 = linux | windows
compilar_sdl() {
  local alvo="$1"
  local prefixo="$CACHE/sdl-${SDL_VERSAO}-${alvo}"
  [[ -f "$prefixo/.pronto" ]] && return 0
  baixar_sdl
  local fonte="$CACHE/src/SDL3-${SDL_VERSAO}"
  local build="$CACHE/build-sdl-${alvo}"
  local extra=()
  if [[ "$alvo" == windows ]]; then
    extra+=(-DCMAKE_TOOLCHAIN_FILE="$fonte/build-scripts/cmake-toolchain-mingw64-x86_64.cmake")
  fi
  diga "SDL ${SDL_VERSAO} estático para ${alvo}"
  rm -rf "$build"
  cmake -S "$fonte" -B "$build" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$prefixo" \
    -DCMAKE_C_FLAGS="$MAPA" \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DSDL_SHARED=OFF -DSDL_STATIC=ON \
    -DSDL_TEST_LIBRARY=OFF -DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF \
    -DSDL_INSTALL_DOCS=OFF \
    "${extra[@]}" >"$CACHE/sdl-${alvo}-configurar.log"
  cmake --build "$build" -j "$JOBS" >"$CACHE/sdl-${alvo}-compilar.log"
  cmake --install "$build" >/dev/null
  touch "$prefixo/.pronto"
}

# $1 = linux | windows | testes
compilar_jogo() {
  local alvo="$1"
  local build="$RAIZ/build/$alvo"
  local extra=()
  case "$alvo" in
    linux)
      compilar_sdl linux
      extra+=(-DCMAKE_PREFIX_PATH="$CACHE/sdl-${SDL_VERSAO}-linux" -DFORJA_DEMO=ON)
      ;;
    windows)
      compilar_sdl windows
      extra+=(-DCMAKE_TOOLCHAIN_FILE="$RAIZ/cmake/mingw64-x86_64.cmake"
              -DCMAKE_PREFIX_PATH="$CACHE/sdl-${SDL_VERSAO}-windows" -DFORJA_DEMO=ON
              -DFORJA_TESTES=OFF)
      ;;
    testes)
      extra+=(-DFORJA_DEMO=OFF)
      ;;
  esac
  diga "jogo: ${alvo}"
  cmake -S "$RAIZ" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE="$TIPO" \
    -DCMAKE_C_FLAGS="$MAPA" "${extra[@]}" >/dev/null
  cmake --build "$build" -j "$JOBS"
  if [[ "$alvo" != windows ]]; then
    diga "testes da lógica (${alvo})"
    ctest --test-dir "$build" --output-on-failure
  fi
}

empacotar() {
  local versao
  versao="$(git -C "$RAIZ" describe --always --dirty 2>/dev/null || echo sem-git)"
  mkdir -p "$RAIZ/dist"
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  if [[ -x "$RAIZ/build/linux/hefesto-tech-demo" ]]; then
    local d="$tmp/hefesto-tech-demo-linux-x86_64"
    mkdir -p "$d"
    cp "$RAIZ/build/linux/hefesto-tech-demo" "$d/"
    cp "$RAIZ/README.md" "$RAIZ/LICENSE" "$d/"
    cp -r "$RAIZ/udev" "$d/"
    cp "$RAIZ"/demo/assets/fontes/OFL-*.txt "$d/"
    echo "$versao" >"$d/VERSAO"
    tar --sort=name --mtime="@${SOURCE_DATE_EPOCH}" --owner=0 --group=0 --numeric-owner \
      -C "$tmp" -czf "$RAIZ/dist/hefesto-tech-demo-linux-x86_64.tar.gz" "hefesto-tech-demo-linux-x86_64"
    diga "dist/hefesto-tech-demo-linux-x86_64.tar.gz"
  fi
  if [[ -f "$RAIZ/build/windows/hefesto-tech-demo.exe" ]]; then
    local w="$tmp/hefesto-tech-demo-windows-x86_64"
    mkdir -p "$w"
    cp "$RAIZ/build/windows/hefesto-tech-demo.exe" "$w/"
    cp "$RAIZ/README.md" "$RAIZ/LICENSE" "$w/"
    cp "$RAIZ"/demo/assets/fontes/OFL-*.txt "$w/"
    echo "$versao" >"$w/VERSAO"
    find "$w" -exec touch -h -d "@${SOURCE_DATE_EPOCH}" {} +
    (cd "$tmp" && cmake -E tar cf "$RAIZ/dist/hefesto-tech-demo-windows-x86_64.zip" --format=zip \
      --mtime="@${SOURCE_DATE_EPOCH}" "hefesto-tech-demo-windows-x86_64")
    diga "dist/hefesto-tech-demo-windows-x86_64.zip"
  fi
}

case "${1:-linux}" in
  linux) compilar_jogo linux ;;
  windows) compilar_jogo windows ;;
  testes) compilar_jogo testes ;;
  tudo)
    compilar_jogo linux
    compilar_jogo windows
    empacotar
    ;;
  pacotes) empacotar ;;
  sdl)
    compilar_sdl linux
    compilar_sdl windows
    ;;
  *)
    echo "uso: scripts/compilar.sh [linux|windows|testes|tudo|pacotes|sdl]" >&2
    exit 64
    ;;
esac
