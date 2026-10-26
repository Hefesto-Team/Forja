#ifndef DEMO_ALEATORIO_H
#define DEMO_ALEATORIO_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct Sorteio {
  uint64_t estado;
} Sorteio;

void sorteio_semear(Sorteio *s, uint64_t semente);
uint32_t sorteio_u32(Sorteio *s);
int sorteio_entre(Sorteio *s, int a, int b);
float sorteio_real(Sorteio *s);
void sorteio_embaralhar(Sorteio *s, int *v, int n);

#ifdef __cplusplus
}
#endif

#endif
