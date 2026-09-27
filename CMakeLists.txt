# FORJA — a Hefesto Tech Demo (SDL3) e as provas da lógica.
#
# O jeito reproduzível de compilar é scripts/compilar.sh, que fixa o SDL3 por
# versão e sha256. Este arquivo é o que ele chama.
#
# As ferramentas de mesa (forja-send, forja-speak, forja-read) continuam no
# Makefile; o empacotador delas (src/forja_dualsense.c) é o MESMO que a demo
# usa — o contrato pede um payload só para os dois backends.
cmake_minimum_required(VERSION 3.20)
project(forja LANGUAGES C)

option(FORJA_DEMO "Hefesto Tech Demo (precisa do SDL3)" ON)
option(FORJA_TESTES "provas da lógica, sem aparelho" ON)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
  add_compile_options(-Wall -Wextra -Wno-unused-parameter -Wno-format-truncation)
endif()

# A versão que o jogo mostra e grava no relatório.
find_package(Git QUIET)
set(FORJA_VERSAO "sem-git")
if(GIT_FOUND AND EXISTS "${CMAKE_SOURCE_DIR}/.git")
  execute_process(COMMAND ${GIT_EXECUTABLE} describe --always --dirty
                  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                  OUTPUT_VARIABLE FORJA_VERSAO OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
  if(NOT FORJA_VERSAO)
    set(FORJA_VERSAO "sem-git")
  endif()
endif()

# --- o empacotador compartilhado --------------------------------------------
add_library(forja_ds5 STATIC src/forja_dualsense.c)
target_include_directories(forja_ds5 PUBLIC include)

# --- o núcleo sem SDL: lógica pura, provada sem aparelho --------------------
add_library(demo_nucleo STATIC
  demo/src/nucleo/aleatorio.c
  demo/src/nucleo/catalogo.c
  demo/src/nucleo/cegas.c
  demo/src/nucleo/mascara.c
  demo/src/nucleo/medidas.c
  demo/src/nucleo/origem.c
  demo/src/nucleo/origem_linux.c
  demo/src/nucleo/postura.c
  demo/src/nucleo/relatorio.c
  demo/src/nucleo/taxa.c
  demo/src/nucleo/texto_buf.c
  demo/src/nucleo/utf8.c
)
target_include_directories(demo_nucleo PUBLIC demo/src/nucleo)
target_link_libraries(demo_nucleo PUBLIC forja_ds5)
if(NOT WIN32)
  target_link_libraries(demo_nucleo PUBLIC m)
endif()

if(FORJA_TESTES)
  enable_testing()
  add_executable(demo-testes
    demo/testes/provas.c
    demo/testes/prova_basicos.c
    demo/testes/prova_cegas.c
    demo/testes/prova_efeitos.c
    demo/testes/prova_medidas.c
    demo/testes/prova_origem.c
    demo/testes/prova_relatorio.c
  )
  target_link_libraries(demo-testes PRIVATE demo_nucleo)
  add_test(NAME demo-testes COMMAND demo-testes)

  add_executable(forja-selftest src/forja_selftest.c)
  target_link_libraries(forja-selftest PRIVATE forja_ds5)
  add_test(NAME forja-selftest COMMAND forja-selftest)
endif()

if(NOT FORJA_DEMO)
  return()
endif()

# --- a Tech Demo -------------------------------------------------------------
find_package(SDL3 3.4 REQUIRED CONFIG COMPONENTS SDL3-static)

set(FONTES_TTF
  ${CMAKE_SOURCE_DIR}/demo/assets/fontes/AtkinsonHyperlegible-Regular.ttf
  ${CMAKE_SOURCE_DIR}/demo/assets/fontes/AtkinsonHyperlegible-Bold.ttf
  ${CMAKE_SOURCE_DIR}/demo/assets/fontes/Cinzel.ttf)
set(FONTES_C ${CMAKE_BINARY_DIR}/gerado/fontes_embutidas.c)
add_custom_command(
  OUTPUT ${FONTES_C}
  COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/gerado
  COMMAND ${CMAKE_COMMAND} -DSAIDA=${FONTES_C}
          "-DENTRADAS=${FONTES_TTF}"
          "-DNOMES=fonte_texto;fonte_texto_negrito;fonte_titulo"
          -P ${CMAKE_SOURCE_DIR}/cmake/embutir.cmake
  DEPENDS ${FONTES_TTF} ${CMAKE_SOURCE_DIR}/cmake/embutir.cmake
  COMMENT "embutindo as fontes (OFL) no executável"
  VERBATIM)

set(DEMO_FONTES
  ${FONTES_C}
  demo/src/main.c
  demo/src/app.c
  demo/src/nucleo/registro.c
  demo/src/nucleo/relogio.c
  demo/src/nucleo/linha_tempo.c
  demo/src/nucleo/pads.c
  demo/src/nucleo/simulador.c
  demo/src/ui/desenho.c
  demo/src/ui/texto.c
  demo/src/ui/tema.c
  demo/src/ui/particulas.c
  demo/src/ui/icones.c
  demo/src/ui/controle.c
  demo/src/ui/widgets.c
  demo/src/ui/automato.c
  demo/src/som/mixer.c
  demo/src/som/sintese.c
  demo/src/som/sistema.c
  demo/src/cenas/titulo.c
  demo/src/cenas/lobby.c
  demo/src/cenas/diagnostico.c
  demo/src/cenas/relatorio_tela.c
  demo/src/cenas/hub.c
  demo/src/cenas/pausa.c
  demo/src/salas/salas.c
  demo/src/salas/sala_base.c
  demo/src/salas/centelha.c
  demo/src/salas/viga.c
  demo/src/salas/molde.c
  demo/src/salas/cerco.c
  demo/src/salas/galeria.c
  demo/src/third_party.c
)

add_executable(hefesto-tech-demo WIN32 ${DEMO_FONTES})
target_include_directories(hefesto-tech-demo PRIVATE demo/src third_party/stb)
target_compile_definitions(hefesto-tech-demo PRIVATE FORJA_VERSAO="${FORJA_VERSAO}")
target_link_libraries(hefesto-tech-demo PRIVATE demo_nucleo SDL3::SDL3-static)
if(WIN32)
  target_link_libraries(hefesto-tech-demo PRIVATE ole32 oleaut32 uuid cfgmgr32 setupapi winmm)
  target_link_options(hefesto-tech-demo PRIVATE -static-libgcc)
else()
  target_link_libraries(hefesto-tech-demo PRIVATE ${CMAKE_DL_LIBS} m)
endif()
