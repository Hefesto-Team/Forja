#ifndef DEMO_REGISTRO_H
#define DEMO_REGISTRO_H

#include <SDL3/SDL.h>

#define REG_MEMORIA 64

typedef struct Registro {
  SDL_IOStream *arq;
  char linhas[REG_MEMORIA][160];
  int prox, total;
  Uint64 inicio_ns;
} Registro;

void reg_abrir(Registro *r, const char *caminho);
void reg_fechar(Registro *r);
void reg_linha(Registro *r, const char *fmt, ...)
#if defined(__GNUC__)
    __attribute__((format(printf, 2, 3)))
#endif
    ;
const char *reg_recente(const Registro *r, int i);

#endif
