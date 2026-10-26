#ifndef DEMO_RELOGIO_H
#define DEMO_RELOGIO_H

#include <SDL3/SDL.h>

void relogio_iniciar(Uint64 inicio_ns);
void relogio_do_jogo(const float *t_jogo);
double relogio_agora(void);

#endif
