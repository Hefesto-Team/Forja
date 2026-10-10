#!/usr/bin/env bash
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$RAIZ"

SDL_VERSAO="3.4.14"
SDL_SHA256="30d4aa2b3037718142b32dffd4e72f917ebb6cc5227150e7bb9c45efb2153aeb"
SDL_URL="https://github.com/libsdl-org/SDL/releases/download/release-${SDL_VERSAO}/SDL3-${SDL_VERSAO}.tar.gz"

GODOT_CPP_TAG="master"
GODOT_CPP_COMMIT="507ed9d840c01a3c5b2a39af8bb4000bfac30bf5"
GODOT_CPP_URL="https://github.com/godotengine/godot-cpp.git"
GODOT_CPP_API="${GODOT_CPP_API:-4.7}"

GLIBC_PISO="2.28"

CACHE="${FORJA_CACHE:-$RAIZ/.cache}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
TIPO="${FORJA_BUILD_TIPO:-Release}"

MAPA="-ffile-prefix-map=$RAIZ=. -ffile-prefix-map=$CACHE=.cache"

diga() { printf '==> %s\n' "$*"; }

soma_da_fonte() {
  (
    cd "$RAIZ"
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
      git ls-files -z --cached --others --exclude-standard -- nativo src include cmake scripts/compilar.sh
    else
      find nativo src include cmake scripts/compilar.sh -type f -print0 2> /dev/null || true
    fi | LC_ALL=C sort -zu | while IFS= read -r -d '' f; do
      if [ -f "$f" ]; then printf '%s\0' "$f"; fi
    done | xargs -0 -r sha256sum | sha256sum | cut -d' ' -f1
  )
}

gravar_a_fonte() {
  soma_da_fonte > "$RAIZ/godot/bin/$1.fonte"
  diga "a fonte do módulo: godot/bin/$1.fonte"
}

glibc_pedida() {
  objdump -T "$1" | grep -oE 'GLIBC_[0-9.]+' | sed 's/^GLIBC_//' | sort -Vu | tail -n 1
}

cabe_no_piso() {
  [[ "$(printf '%s\n%s\n' "$1" "$GLIBC_PISO" | sort -V | tail -n 1)" == "$GLIBC_PISO" ]]
}

conferir_piso() {
  local so="$1" pede v
  [[ -f "$so" ]] || { echo "falta $so" >&2; return 2; }
  command -v objdump > /dev/null || { echo "falta o objdump (binutils) para ler $so" >&2; return 2; }
  pede="$(glibc_pedida "$so")"
  [[ -n "$pede" ]] || { echo "nenhuma versão de glibc em $so" >&2; return 2; }
  if cabe_no_piso "$pede"; then
    echo "$so pede glibc $pede; o piso do pacote é $GLIBC_PISO: cabe"
    return 0
  fi
  echo "$so pede glibc $pede, acima do piso $GLIBC_PISO do pacote (o do Godot):" >&2
  for v in $(objdump -T "$so" | grep -oE 'GLIBC_[0-9.]+' | sed 's/^GLIBC_//' | sort -Vu); do
    cabe_no_piso "$v" && continue
    printf '  GLIBC_%s: %s\n' "$v" \
      "$(objdump -T "$so" | awk -v v="(GLIBC_$v)" 'index($0, v) { print $NF }' | sort -u | tr '\n' ' ')" >&2
  done
  return 1
}

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

preparar_godot_cpp() {
  local dir="${GODOT_CPP_DIR:-$CACHE/godot-cpp-${GODOT_CPP_COMMIT:0:10}}"
  if [[ ! -d "$dir/.git" ]]; then
    diga "baixando godot-cpp ${GODOT_CPP_TAG} (${GODOT_CPP_COMMIT:0:10})" >&2
    rm -rf "$dir"
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
  case "$alvo" in
    linux) gravar_a_fonte libforja.linux.x86_64.so ;;
    windows) gravar_a_fonte libforja.windows.x86_64.dll ;;
  esac
  if [[ "$alvo" == linux ]] && command -v objdump > /dev/null; then
    diga "este módulo pede glibc $(glibc_pedida "$RAIZ/godot/bin/libforja.linux.x86_64.so"); o pacote pede no máximo $GLIBC_PISO"
  fi
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
  soma) soma_da_fonte ;;
  piso) conferir_piso "${2:-$RAIZ/godot/bin/libforja.linux.x86_64.so}" ;;
  *)
    echo "uso: scripts/compilar.sh [linux|windows|testes|tudo|deps|soma|piso [biblioteca]]" >&2
    exit 64
    ;;
esac
