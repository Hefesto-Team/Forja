#ifndef DEMO_UTF8_H
#define DEMO_UTF8_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

uint32_t utf8_proximo(const char **p);

size_t utf8_contar(const char *s);

int utf8_escrever(uint32_t cp, char out[4]);

void utf8_maiusculas(const char *s, char *out, size_t tam);

#ifdef __cplusplus
}
#endif

#endif
