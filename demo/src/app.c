/* O estado do jogo e os serviços comuns às cenas. Ver app.h. */
#include "app.h"

#include "nucleo/relogio.h"

#include "nucleo/mascara.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

App *APP;

void app_trocar_cena(App *a, const Cena *c) {
  if (!c || a->proxima)
    return;
  a->proxima = c;
  a->transicao = 0.0001f;
}

void app_avisar(App *a, const char *formato, ...) {
  va_list ap;
  va_start(ap, formato);
  vsnprintf(a->aviso, sizeof(a->aviso), formato, ap);
  va_end(ap);
  mascara_mac(a->aviso);
  a->aviso_t = 0;
}

double app_agora(const App *a) {
  (void)a;
  return relogio_agora();
}

void app_hora(char *out, size_t tam) {
  SDL_Time agora;
  SDL_DateTime dt;
  if (SDL_GetCurrentTime(&agora) && SDL_TimeToDateTime(agora, &dt, true))
    snprintf(out, tam, "%04d-%02d-%02d %02d:%02d:%02d", dt.year, dt.month, dt.day, dt.hour, dt.minute,
             dt.second);
  else
    snprintf(out, tam, "(sem relógio)");
}

void app_relatorio_mudou(App *a) {
  a->relatorio_sujo = true;
  a->relatorio_salvo_ha = 0;
}

static bool gravar(const char *caminho, const char *dados, size_t tam) {
  SDL_IOStream *io = SDL_IOFromFile(caminho, "wb");
  if (!io)
    return false;
  bool ok = SDL_WriteIO(io, dados, tam) == tam;
  ok = SDL_CloseIO(io) && ok;
  return ok;
}

bool app_salvar_relatorio(App *a) {
  if (!a->pasta_relatorios[0])
    return false;
  app_hora(a->rel.fim, sizeof(a->rel.fim));
  char *json = NULL, *txt = NULL;
  size_t nj = 0, nt = 0;
  bool ok = rel_json(&a->rel, &json, &nj) == 0 && rel_texto(&a->rel, &txt, &nt) == 0;
  if (ok) {
    char caminho[1200];
    snprintf(caminho, sizeof(caminho), "%srelatorio-%s.json", a->pasta_relatorios, a->base_arquivos);
    ok = gravar(caminho, json, nj);
    snprintf(caminho, sizeof(caminho), "%srelatorio-%s.txt", a->pasta_relatorios, a->base_arquivos);
    ok = gravar(caminho, txt, nt) && ok;
  }
  free(json);
  free(txt);
  a->relatorio_sujo = !ok;
  return ok;
}

#if defined(SDL_PLATFORM_WINDOWS)
typedef const char *(*FnVersaoWine)(void);
static FnVersaoWine versao_wine(void) {
  static bool tentou = false;
  static FnVersaoWine fn = NULL;
  if (!tentou) {
    tentou = true;
    SDL_SharedObject *ntdll = SDL_LoadObject("ntdll.dll");
    if (ntdll)
      fn = (FnVersaoWine)SDL_LoadFunction(ntdll, "wine_get_version");
  }
  return fn;
}
bool app_sob_wine(void) { return versao_wine() != NULL; }
const char *app_versao_wine(void) {
  FnVersaoWine fn = versao_wine();
  return fn ? fn() : NULL;
}
#else
bool app_sob_wine(void) { return false; }
const char *app_versao_wine(void) { return NULL; }
#endif
