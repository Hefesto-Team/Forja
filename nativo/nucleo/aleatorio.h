/* O sorteio das estações. Todo teste às cegas depende dele, e por isso ele é
 * determinístico a partir de uma semente que vai para o relatório: quem quiser
 * refazer a mesma sessão, na mesma ordem, passa `--semente N`. */
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
/* inteiro em [a, b], inclusive */
int sorteio_entre(Sorteio *s, int a, int b);
/* real em [0, 1) */
float sorteio_real(Sorteio *s);
/* embaralha `n` inteiros no lugar (Fisher-Yates) */
void sorteio_embaralhar(Sorteio *s, int *v, int n);

#ifdef __cplusplus
}
#endif

#endif
