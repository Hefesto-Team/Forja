/* O registro da sessão. Ver registro.h. */
#include "registro.h"

#include "mascara.h"

#include <stdarg.h>
#include <stdio.h>

void reg_abrir(Registro *r, const char *caminho) {
  SDL_memset(r, 0, sizeof(*r));
  r->inicio_ns = SDL_GetTicksNS();
  if (caminho && caminho[0])
    r->arq = SDL_IOFromFile(caminho, "w");
}

void reg_fechar(Registro *r) {
  if (r->arq) {
    SDL_CloseIO(r->arq);
    r->arq = NULL;
  }
}

void reg_linha(Registro *r, const char *formato, ...) {
  char corpo[400];
  va_list ap;
  va_start(ap, formato);
  vsnprintf(corpo, sizeof(corpo), formato, ap);
  va_end(ap);
  mascara_mac(corpo);
  double t = (double)(SDL_GetTicksNS() - r->inicio_ns) / 1e9;
  char linha[440];
  int n = snprintf(linha, sizeof(linha), "[%9.3f] %s\n", t, corpo);
  if (r->arq && n > 0) {
    SDL_WriteIO(r->arq, linha, (size_t)(n < (int)sizeof(linha) ? n : (int)sizeof(linha) - 1));
    SDL_FlushIO(r->arq);
  }
  snprintf(r->linhas[r->prox], sizeof(r->linhas[0]), "%s", corpo);
  r->prox = (r->prox + 1) % REG_MEMORIA;
  r->total++;
}

const char *reg_recente(const Registro *r, int i) {
  if (i < 0 || i >= REG_MEMORIA || i >= r->total)
    return NULL;
  int idx = (r->prox - 1 - i + REG_MEMORIA * 2) % REG_MEMORIA;
  return r->linhas[idx];
}
