/* O relógio da sessão. Ver relogio.h. */
#include "relogio.h"

static Uint64 g_inicio_ns;
static const float *g_t_jogo;

void relogio_iniciar(Uint64 inicio_ns) {
  g_inicio_ns = inicio_ns;
  g_t_jogo = NULL;
}

void relogio_do_jogo(const float *t_jogo) { g_t_jogo = t_jogo; }

double relogio_agora(void) {
  if (g_t_jogo)
    return *g_t_jogo;
  if (!g_inicio_ns)
    g_inicio_ns = SDL_GetTicksNS();
  return (double)(SDL_GetTicksNS() - g_inicio_ns) / 1e9;
}
