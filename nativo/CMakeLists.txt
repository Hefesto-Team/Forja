# FORJA — o módulo nativo do jogo 3D: uma GDExtension com o SDL3 dentro.
#
# O Godot desenha; este módulo fala com os DualSense como a Sony e a Steam
# documentam (o payload USB 0x02 de 47 bytes pelo SDL3, player index 0..3, os
# quatro modos de gatilho) e grava o relatório da sessão. O mesmo código roda
# no Linux e no .exe do Windows (e, por ele, no Proton).
#
# O jeito reproduzível de compilar é scripts/compilar.sh: ele fixa o SDL3 e o
# godot-cpp por versão (e sha256 / commit) e chama este arquivo.
#
#   -DFORJA_EXTENSAO=ON    a GDExtension (precisa do SDL3 e do godot-cpp)
#   -DFORJA_TESTES=ON      as provas da lógica, sem aparelho e sem SDL
#   -DGODOT_CPP_DIR=...    a árvore do godot-cpp (godot-4.4-stable)
cmake_minimum_required(VERSION 3.20)
project(forja LANGUAGES C CXX)

option(FORJA_EXTENSAO "a GDExtension do jogo (SDL3 + godot-cpp)" ON)
option(FORJA_TESTES "as provas da lógica, sem aparelho" ON)
set(GODOT_CPP_DIR "" CACHE PATH "a árvore do godot-cpp")

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(RAIZ ${CMAKE_CURRENT_SOURCE_DIR}/..)

if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
  add_compile_options($<$<COMPILE_LANGUAGE:C>:-Wall> $<$<COMPILE_LANGUAGE:C>:-Wextra>
                      $<$<COMPILE_LANGUAGE:C>:-Wno-unused-parameter>
                      $<$<COMPILE_LANGUAGE:C>:-Wno-format-truncation>)
endif()

# A versão que o jogo mostra e grava no relatório.
find_package(Git QUIET)
set(FORJA_VERSAO "sem-git")
if(GIT_FOUND AND EXISTS "${RAIZ}/.git")
  execute_process(COMMAND ${GIT_EXECUTABLE} describe --always --dirty
                  WORKING_DIRECTORY ${RAIZ}
                  OUTPUT_VARIABLE FORJA_VERSAO OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
  if(NOT FORJA_VERSAO)
    set(FORJA_VERSAO "sem-git")
  endif()
endif()

# --- o empacotador compartilhado com as ferramentas de mesa -----------------
add_library(forja_ds5 STATIC ${RAIZ}/src/forja_dualsense.c)
target_include_directories(forja_ds5 PUBLIC ${RAIZ}/include)

# --- o núcleo sem SDL: lógica pura, provada sem aparelho --------------------
add_library(forja_nucleo STATIC
  nucleo/achar_som.c
  nucleo/aleatorio.c
  nucleo/analise.c
  nucleo/catalogo.c
  nucleo/cegas.c
  nucleo/chao.c
  nucleo/mascara.c
  nucleo/medidas.c
  nucleo/origem.c
  nucleo/origem_linux.c
  nucleo/postura.c
  nucleo/relatorio.c
  nucleo/taxa.c
  nucleo/texto_buf.c
  nucleo/utf8.c
  som/sintese.c
)
target_include_directories(forja_nucleo PUBLIC nucleo som)
target_link_libraries(forja_nucleo PUBLIC forja_ds5)
if(NOT WIN32)
  target_link_libraries(forja_nucleo PUBLIC m)
endif()

if(FORJA_TESTES)
  enable_testing()
  add_executable(forja-testes
    testes/provas.c
    testes/prova_achar_som.c
    testes/prova_basicos.c
    testes/prova_cegas.c
    testes/prova_efeitos.c
    testes/prova_experimentos.c
    testes/prova_medidas.c
    testes/prova_origem.c
    testes/prova_relatorio.c
    testes/prova_som.c
  )
  target_link_libraries(forja-testes PRIVATE forja_nucleo)
  add_test(NAME forja-testes COMMAND forja-testes)
endif()

if(NOT FORJA_EXTENSAO)
  return()
endif()

# --- a parte com SDL: os controles, o simulador, a sessão --------------------
find_package(SDL3 REQUIRED CONFIG COMPONENTS SDL3-static)

add_library(forja_sdl STATIC
  nucleo/forja.c
  nucleo/linha_tempo.c
  nucleo/pads.c
  nucleo/registro.c
  nucleo/relogio.c
  nucleo/simulador.c
  som/mixer.c
  som/som_controle.c
  som/som_controle_linux.c
  som/som_controle_outro.c
  som/som_controle_windows.c
  som/sons_salas.c
)
target_include_directories(forja_sdl PUBLIC nucleo som)
target_compile_definitions(forja_sdl PRIVATE FORJA_VERSAO="${FORJA_VERSAO}")
target_link_libraries(forja_sdl PUBLIC forja_nucleo SDL3::SDL3-static)
if(WIN32)
  # o som de cada controle: o WASAPI (COM) e o ContainerId do HID (CfgMgr32)
  target_link_libraries(forja_sdl PUBLIC ole32 cfgmgr32)
endif()

# --- a GDExtension -----------------------------------------------------------
if(NOT GODOT_CPP_DIR)
  message(FATAL_ERROR "FORJA_EXTENSAO pede -DGODOT_CPP_DIR (scripts/compilar.sh baixa o godot-cpp)")
endif()
# Só as classes do Godot que o módulo usa: o godot-cpp gera e compila bem
# menos, e o build do CI cabe em minutos.
set(GODOTCPP_BUILD_PROFILE "${CMAKE_CURRENT_SOURCE_DIR}/godot/perfil_godot.json" CACHE PATH "" FORCE)
add_subdirectory(${GODOT_CPP_DIR} ${CMAKE_BINARY_DIR}/godot-cpp EXCLUDE_FROM_ALL)

add_library(forja SHARED
  godot/registro_tipos.cpp
  godot/forja_controles.cpp
  godot/forja_medidas.cpp
  godot/forja_cegas.cpp
  godot/forja_som.cpp
)
target_link_libraries(forja PRIVATE forja_sdl godot-cpp::template_release)
target_compile_definitions(forja PRIVATE FORJA_VERSAO="${FORJA_VERSAO}")

# O nome segue o do godot-cpp: libforja.linux.x86_64.so, libforja.windows.x86_64.dll
if(WIN32)
  set(FORJA_PLATAFORMA windows)
else()
  set(FORJA_PLATAFORMA linux)
endif()
set(FORJA_SAIDA "${RAIZ}/godot/bin")
set_target_properties(forja PROPERTIES
  CXX_STANDARD 17
  CXX_EXTENSIONS OFF
  CXX_VISIBILITY_PRESET hidden
  PREFIX "lib"
  OUTPUT_NAME "forja.${FORJA_PLATAFORMA}.x86_64"
  LIBRARY_OUTPUT_DIRECTORY "$<1:${FORJA_SAIDA}>"
  RUNTIME_OUTPUT_DIRECTORY "$<1:${FORJA_SAIDA}>"
)
if(WIN32)
  # nenhuma DLL do mingw para acompanhar a do jogo
  target_link_options(forja PRIVATE -static -static-libgcc -static-libstdc++)
else()
  # o SDL3 e o godot-cpp ficam dentro da biblioteca: só o entry_symbol sai dela
  target_link_options(forja PRIVATE -Wl,--exclude-libs,ALL)
endif()
