#ifndef DEMO_LINHA_TEMPO_H
#define DEMO_LINHA_TEMPO_H

#include <SDL3/SDL.h>

#include "texto_buf.h"

#define LINHA_TEMPO_FORMATO "hefesto-tech-demo/linha-do-tempo/2"

typedef struct LinhaTempo {
  SDL_IOStream *arq;
  Uint64 inicio_ns;
  long eventos;
} LinhaTempo;

typedef struct Evento {
  TextoBuf b;
  unsigned cabeca;
} Evento;

void lt_abrir(LinhaTempo *lt, const char *caminho, Uint64 inicio_ns);
void lt_fechar(LinhaTempo *lt);
void lt_t_musica(double s);

void ev_iniciar(Evento *e, const LinhaTempo *lt, const char *tipo, int jogador);
void ev_str(Evento *e, const char *chave, const char *valor);
void ev_num(Evento *e, const char *chave, double valor);
void ev_int(Evento *e, const char *chave, long valor);
void ev_bool(Evento *e, const char *chave, bool valor);
void ev_ints(Evento *e, const char *chave, const int *v, int n);
void ev_nums(Evento *e, const char *chave, const double *v, int n);
void ev_strs(Evento *e, const char *chave, const char *const *v, int n);
void ev_fim(Evento *e, LinhaTempo *lt);

#endif
