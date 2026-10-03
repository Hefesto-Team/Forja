#!/usr/bin/env bash
# Build reproduzível do módulo nativo do FORJA (a GDExtension do jogo 3D).
#
#   scripts/compilar.sh linux      o módulo Linux    -> godot/bin/libforja.linux.x86_64.so
#   scripts/compilar.sh windows    o módulo Windows  -> godot/bin/libforja.windows.x86_64.dll
#   scripts/compilar.sh testes     só a lógica, sem SDL e sem Godot, e as provas
#   scripts/compilar.sh tudo       os três
#   scripts/compilar.sh deps       só baixa e confere o SDL3 e o godot-cpp
#
# Reproduzível quer dizer: o SDL3 entra por versão E por sha256, o godot-cpp
# por tag E por commit (nunca "o que a distro tiver"), e os caminhos desta
# máquina saem do binário (-ffile-prefix-map).
#
# O SDL3 é o 3.4.14 — a mesma série que a Steam distribui no runtime, e a que o
# Hefesto usa como régua. O godot-cpp vem do master, num commit fixo (ADR-009).
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$RAIZ"

SDL_VERSAO="3.4.14"
SDL_SHA256="30d4aa2b3037718142b32dffd4e72f917ebb6cc5227150e7bb9c45efb2153aeb"
SDL_URL="https://github.com/libsdl-org/SDL/releases/download/release-${SDL_VERSAO}/SDL3-${SDL_VERSAO}.tar.gz"

# A godot-cpp não tem versão 4.7: a última com tag é a godot-4.5-stable. Para
# o jogo rodar na 4.7, o módulo compila contra o ramo «master» — mas **fixado
# num commit**, que é o que mantém a compilação reproduzível. Subir de commit é
# decisão, com commit próprio e as provas verdes (ADR-009).
GODOT_CPP_TAG="master"
GODOT_CPP_COMMIT="507ed9d840c01a3c5b2a39af8bb4000bfac30bf5"
GODOT_CPP_URL="https://github.com/godotengine/godot-cpp.git"
# O master traz a API de várias versões (extension_api-4-3 … 4-7) e exige dizer
# qual. A nossa é a da engine que o jogo roda (scripts/engine.sh).
GODOT_CPP_API="${GODOT_CPP_API:-4.7}"

CACHE="${FORJA_CACHE:-$RAIZ/.cache}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
TIPO="${FORJA_BUILD_TIPO:-Release}"

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
  # PIC: o SDL vai para dentro de uma biblioteca compartilhada (a GDExtension)
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

# O godot-cpp na tag fixada, e só se o commit conferir. GODOT_CPP_DIR aponta
# para uma árvore que já existe (conferida do mesmo jeito).
preparar_godot_cpp() {
  local dir="${GODOT_CPP_DIR:-$CACHE/godot-cpp-${GODOT_CPP_COMMIT:0:10}}"
  if [[ ! -d "$dir/.git" ]]; then
    diga "baixando godot-cpp ${GODOT_CPP_TAG} (${GODOT_CPP_COMMIT:0:10})" >&2
    rm -rf "$dir"
    # o commit, não o topo do ramo: o master anda, e a compilação não pode andar junto
    git init -q "$dir" >&2
    git -C "$dir" remote add origin "$GODOT_CPP_URL" >&2
    git -C "$dir" fetch -q --depth 1 origin "$GODOT_CPP_COMMIT" >&2
    git -C "$dir" checkout -q FETCH_HEAD >&2
  fi
  local tem
  tem="$(git -C "$dir" rev-parse HEAD)"
  if [[ "$tem" != "$GODOT_CPP_COMMIT" ]]; then
    echo "commit do godot-cpp não confere: $tem (esperado $GODOT_CPP_COMMIT)" >&2
    exit 1
  fi
  printf '%s' "$dir"
}

# $1 = linux | windows | testes
compilar() {
  local alvo="$1"
  local build="$RAIZ/build/$alvo"
  local extra=()
  case "$alvo" in
    linux)
      compilar_sdl linux
      extra+=(-DCMAKE_PREFIX_PATH="$CACHE/sdl-${SDL_VERSAO}-linux"
              -DGODOT_CPP_DIR="$(preparar_godot_cpp)" -DGODOTCPP_API_VERSION="$GODOT_CPP_API" -DFORJA_TESTES=OFF)
      ;;
    windows)
      compilar_sdl windows
      extra+=(-DCMAKE_TOOLCHAIN_FILE="$RAIZ/cmake/mingw64-x86_64.cmake"
              -DCMAKE_PREFIX_PATH="$CACHE/sdl-${SDL_VERSAO}-windows"
              -DGODOT_CPP_DIR="$(preparar_godot_cpp)" -DGODOTCPP_API_VERSION="$GODOT_CPP_API" -DFORJA_TESTES=OFF)
      ;;
    testes)
      extra+=(-DFORJA_EXTENSAO=OFF -DFORJA_TESTES=ON)
      ;;
  esac
  diga "módulo: ${alvo}"
  cmake -S "$RAIZ/nativo" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE="$TIPO" \
    -DCMAKE_C_FLAGS="$MAPA" -DCMAKE_CXX_FLAGS="$MAPA" "${extra[@]}" >/dev/null
  cmake --build "$build" -j "$JOBS"
  if [[ "$alvo" == testes ]]; then
    diga "provas da lógica"
    ctest --test-dir "$build" --output-on-failure
  fi
}

case "${1:-linux}" in
  linux) compilar linux ;;
  windows) compilar windows ;;
  testes) compilar testes ;;
  tudo)
    compilar testes
    compilar linux
    compilar windows
    ;;
  deps)
    compilar_sdl linux
    compilar_sdl windows
    preparar_godot_cpp >/dev/null
    ;;
  *)
    echo "uso: scripts/compilar.sh [linux|windows|testes|tudo|deps]" >&2
    exit 64
    ;;
esac
