# Embute arquivos binários num .c — as fontes vão DENTRO do executável, e o
# .exe roda pelo Proton sem pasta de assets ao lado.
#
# Uso (script): cmake -DSAIDA=<arquivo.c> -DENTRADAS="a.ttf;b.ttf" -DNOMES="a;b" -P embutir.cmake
cmake_minimum_required(VERSION 3.20)

if(NOT SAIDA OR NOT ENTRADAS OR NOT NOMES)
  message(FATAL_ERROR "embutir.cmake: SAIDA, ENTRADAS e NOMES são obrigatórios")
endif()

set(conteudo "/* Gerado por cmake/embutir.cmake — não edite. */\n#include <stddef.h>\n\n")
list(LENGTH ENTRADAS total)
math(EXPR ultimo "${total} - 1")
foreach(i RANGE ${ultimo})
  list(GET ENTRADAS ${i} arquivo)
  list(GET NOMES ${i} nome)
  file(READ "${arquivo}" hex HEX)
  string(LENGTH "${hex}" n_hex)
  math(EXPR n_bytes "${n_hex} / 2")
  string(REGEX REPLACE "([0-9a-f][0-9a-f])" "0x\\1," corpo "${hex}")
  # quebra de linha a cada 24 bytes, para o arquivo ser legível por editor
  string(REGEX REPLACE "((0x[0-9a-f][0-9a-f],){24})" "\\1\n" corpo "${corpo}")
  string(APPEND conteudo "const unsigned char ${nome}[${n_bytes}] = {\n${corpo}\n};\n")
  string(APPEND conteudo "const size_t ${nome}_tam = ${n_bytes};\n\n")
endforeach()
file(WRITE "${SAIDA}.tmp" "${conteudo}")
file(COPY_FILE "${SAIDA}.tmp" "${SAIDA}" ONLY_IF_DIFFERENT)
file(REMOVE "${SAIDA}.tmp")
