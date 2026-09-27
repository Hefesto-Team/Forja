/* UTF-8 — o texto do jogo é português com acento, e a fonte desenha por
 * codepoint. Decodificação tolerante: byte inválido vira U+FFFD e avança um. */
#ifndef DEMO_UTF8_H
#define DEMO_UTF8_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Lê um codepoint a partir de `*p` e avança `*p`. Devolve 0 no fim do texto. */
uint32_t utf8_proximo(const char **p);

/* Quantos codepoints há em `s`. */
size_t utf8_contar(const char *s);

/* Escreve `cp` em `out` (até 4 bytes, sem terminar); devolve quantos bytes. */
int utf8_escrever(uint32_t cp, char out[4]);

#ifdef __cplusplus
}
#endif

#endif
