/* Brasas e faíscas — a forja viva no fundo de toda tela. */
#ifndef DEMO_PARTICULAS_H
#define DEMO_PARTICULAS_H

#include <SDL3/SDL.h>

#include "../nucleo/aleatorio.h"

#define MAX_PARTICULAS 900

typedef struct Particula {
  float x, y, vx, vy;
  float vida, vida_total;
  float tam;
  float giro;
  SDL_Color cor;
  unsigned char tipo; /* 0 brasa que sobe, 1 faísca que cai, 2 anel */
} Particula;

typedef struct Particulas {
  Particula p[MAX_PARTICULAS];
  int n;
  float acumulado; /* brasas de fundo por emitir */
  float taxa;      /* brasas de fundo por segundo */
  Sorteio sorteio;
} Particulas;

void particulas_iniciar(Particulas *ps, uint64_t semente);
void particulas_atualizar(Particulas *ps, float dt);
void particulas_desenhar(SDL_Renderer *r, const Particulas *ps);
/* Uma explosão de faíscas (a martelada, o acerto). */
void particulas_faiscas(Particulas *ps, float x, float y, int quantas, SDL_Color cor, float forca);
/* Um anel de choque que abre e some. */
void particulas_anel(Particulas *ps, float x, float y, SDL_Color cor, float raio_final);
/* Algumas brasas subindo de um ponto (o sopro, a confirmação). */
void particulas_brasas(Particulas *ps, float x, float y, int quantas, SDL_Color cor);

#endif
