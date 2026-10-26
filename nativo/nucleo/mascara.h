#ifndef DEMO_MASCARA_H
#define DEMO_MASCARA_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

int mascara_mac(char *texto);

int mascara_mac_copia(const char *de, char *para, size_t tam);

#ifdef __cplusplus
}
#endif

#endif
