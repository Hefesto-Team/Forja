/* A sessão. Ver forja.h. */
#include "forja.h"

#include "mascara.h"
#include "relogio.h"
#include "simulador.h"
#include "som_controle.h"
#include "sons_salas.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef FORJA_VERSAO
#define FORJA_VERSAO "sem-versão"
#endif

Forja *FORJA;

double forja_agora(const Forja *f) {
  (void)f;
  return relogio_agora();
}

void forja_hora(char *out, size_t tam) {
  SDL_Time agora;
  SDL_DateTime dt;
  if (SDL_GetCurrentTime(&agora) && SDL_TimeToDateTime(agora, &dt, true))
    snprintf(out, tam, "%04d-%02d-%02d %02d:%02d:%02d", dt.year, dt.month, dt.day, dt.hour, dt.minute,
             dt.second);
  else
    snprintf(out, tam, "(sem relógio)");
}

void forja_avisar(Forja *f, const char *formato, ...) {
  va_list ap;
  va_start(ap, formato);
  vsnprintf(f->aviso, sizeof(f->aviso), formato, ap);
  va_end(ap);
  mascara_mac(f->aviso);
  f->aviso_seq++;
}

void forja_relatorio_mudou(Forja *f) { f->relatorio_sujo = true; }

static bool gravar(const char *caminho, const char *dados, size_t tam) {
  SDL_IOStream *io = SDL_IOFromFile(caminho, "wb");
  if (!io)
    return false;
  bool ok = SDL_WriteIO(io, dados, tam) == tam;
  ok = SDL_CloseIO(io) && ok;
  return ok;
}

bool forja_salvar_relatorio(Forja *f) {
  if (!f->pasta_relatorios[0])
    return false;
  forja_hora(f->rel.fim, sizeof(f->rel.fim));
  char *json = NULL, *txt = NULL;
  size_t nj = 0, nt = 0;
  bool ok = rel_json(&f->rel, &json, &nj) == 0 && rel_texto(&f->rel, &txt, &nt) == 0;
  if (ok) {
    char caminho[1200];
    snprintf(caminho, sizeof(caminho), "%srelatorio-%s.json", f->pasta_relatorios, f->base_arquivos);
    ok = gravar(caminho, json, nj);
    snprintf(caminho, sizeof(caminho), "%srelatorio-%s.txt", f->pasta_relatorios, f->base_arquivos);
    ok = gravar(caminho, txt, nt) && ok;
  }
  free(json);
  free(txt);
  f->relatorio_sujo = !ok;
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
bool forja_sob_wine(void) { return versao_wine() != NULL; }
const char *forja_versao_wine(void) {
  FnVersaoWine fn = versao_wine();
  return fn ? fn() : NULL;
}
#else
bool forja_sob_wine(void) { return false; }
const char *forja_versao_wine(void) { return NULL; }
#endif

/* A pasta dos relatórios: a pedida pelo jogo (que já a resolveu: ao lado do
 * executável, ou a pasta do usuário), com a barra no fim. Nunca um caminho
 * escrito no código. */
static void preparar_pasta(Forja *f, const char *pasta) {
  f->pasta_relatorios[0] = '\0';
  if (!pasta || !pasta[0])
    return;
  snprintf(f->pasta_relatorios, sizeof(f->pasta_relatorios), "%s", pasta);
  size_t n = strlen(f->pasta_relatorios);
  if (n && f->pasta_relatorios[n - 1] != '/' && f->pasta_relatorios[n - 1] != '\\' &&
      n + 1 < sizeof(f->pasta_relatorios))
    strcat(f->pasta_relatorios, "/");
  SDL_CreateDirectory(f->pasta_relatorios);
}

static void preparar_relatorio(Forja *f) {
  rel_iniciar(&f->rel);
  SDL_Time agora;
  SDL_DateTime dt;
  if (SDL_GetCurrentTime(&agora) && SDL_TimeToDateTime(agora, &dt, true))
    snprintf(f->base_arquivos, sizeof(f->base_arquivos), "%04d%02d%02d-%02d%02d%02d", dt.year, dt.month,
             dt.day, dt.hour, dt.minute, dt.second);
  else
    snprintf(f->base_arquivos, sizeof(f->base_arquivos), "sessao");
  snprintf(f->rel.sessao, sizeof(f->rel.sessao), "%s", f->base_arquivos);
  forja_hora(f->rel.inicio, sizeof(f->rel.inicio));
  snprintf(f->rel.versao, sizeof(f->rel.versao), "%s", FORJA_VERSAO);
  int v = SDL_GetVersion();
  snprintf(f->rel.sdl, sizeof(f->rel.sdl), "%d.%d.%d (%s)", SDL_VERSIONNUM_MAJOR(v), SDL_VERSIONNUM_MINOR(v),
           SDL_VERSIONNUM_MICRO(v), SDL_GetRevision());
  const char *wine = forja_versao_wine();
  if (wine)
    snprintf(f->rel.plataforma, sizeof(f->rel.plataforma), "%s sob Wine %s (Proton) · Godot", SDL_GetPlatform(), wine);
  else
    snprintf(f->rel.plataforma, sizeof(f->rel.plataforma), "%s · Godot", SDL_GetPlatform());
  rel_copiar(f->rel.contrato, sizeof(f->rel.contrato),
             "estrito: o jogo monta só o payload de 47 bytes e fala USB 0x02 pelo SDL; DualSense nativo "
             "no rádio entra só com a entrada básica (SDL_HINT_JOYSTICK_ENHANCED_REPORTS=0)");
  f->rel.semente = f->semente;
  if (f->simular) {
    rel_nota(&f->rel, "sessão com controles SIMULADOS: nada aqui foi medido em aparelho");
    if (simulador_defeitos_texto()[0]) {
      char nota[240];
      snprintf(nota, sizeof(nota), "defeitos de mentira nos controles simulados: %s", simulador_defeitos_texto());
      rel_nota(&f->rel, nota);
    }
  }
}

bool forja_abrir(Forja *f, const char *pasta, int simular, bool robo, unsigned long long semente) {
  SDL_memset(f, 0, sizeof(*f));
  FORJA = f;
  f->intensidade = 1.0f;
  f->simular = simular;
  f->so_virtuais = simular > 0;
  f->robo = robo;
  f->semente = semente;
  if (!f->semente) {
    Uint64 t = SDL_GetTicksNS();
    SDL_Time agora;
    if (SDL_GetCurrentTime(&agora))
      t ^= (Uint64)agora;
    f->semente = (t % 1000000000ull) + 1;
  }

  /* o contrato, antes de tudo: sem o relatório estendido, um DualSense nativo
   * no rádio fica só com a entrada básica — este jogo não monta o 0x31 */
  /* o processo é do Godot: o Ctrl+C e o SIGTERM são dele (sem esta dica, o
   * SDL troca os dois por um evento de saída que ninguém lê, e o jogo não
   * fecha pelo terminal) */
  SDL_SetHint(SDL_HINT_NO_SIGNAL_HANDLERS, "1");
  SDL_SetHint(SDL_HINT_JOYSTICK_ENHANCED_REPORTS, "0");
  SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");
  SDL_SetHint(SDL_HINT_JOYSTICK_HIDAPI_PS5_PLAYER_LED, "1");
  SDL_SetAppMetadata("FORJA", FORJA_VERSAO, "org.hefesto.forja");
  if (!SDL_Init(SDL_INIT_GAMEPAD | SDL_INIT_EVENTS)) {
    fprintf(stderr, "forja: SDL_Init: %s\n", SDL_GetError());
    return false;
  }
  f->inicio_ns = SDL_GetTicksNS();
  relogio_iniciar(f->inicio_ns);  /* de parede; o do jogo só com --acelerado (forja_controles) */
  preparar_pasta(f, pasta);
  preparar_relatorio(f);

  char caminho[1200];
  snprintf(caminho, sizeof(caminho), "%sregistro-%s.log", f->pasta_relatorios, f->base_arquivos);
  reg_abrir(&f->reg, f->pasta_relatorios[0] ? caminho : NULL);
  reg_linha(&f->reg, "FORJA %s · SDL %s · %s", FORJA_VERSAO, f->rel.sdl, f->rel.plataforma);
  reg_linha(&f->reg, "contrato: %s", f->rel.contrato);
  reg_linha(&f->reg, "semente dos sorteios: %llu", f->semente);

  snprintf(caminho, sizeof(caminho), "%slinha-do-tempo-%s.jsonl", f->pasta_relatorios, f->base_arquivos);
  lt_abrir(&f->lt, f->pasta_relatorios[0] ? caminho : NULL, f->inicio_ns);
  {
    Evento ev;
    ev_iniciar(&ev, &f->lt, "sessao", 0);
    ev_str(&ev, "formato", LINHA_TEMPO_FORMATO);
    ev_str(&ev, "relogio", "parede");
    ev_str(&ev, "sessao", f->rel.sessao);
    ev_int(&ev, "semente", (long)f->semente);
    ev_str(&ev, "versao", f->rel.versao);
    ev_str(&ev, "sdl", f->rel.sdl);
    ev_str(&ev, "plataforma", f->rel.plataforma);
    ev_bool(&ev, "simulado", f->simular > 0);
    ev_fim(&ev, &f->lt);
  }
  pads_iniciar(f);
  if (f->simular > 0)
    simulador_iniciar(f, f->simular);
  return true;
}

void forja_quadro(Forja *f, float dt) {
  f->dt = dt;
  f->t += dt;
  f->relogio_sim_ns += (Uint64)((double)dt * 1e9);
  /* os apertos do quadro anterior já foram lidos pelo jogo: zera, e só então
   * bombeia os novos — cada borda vale exatamente um quadro */
  pads_fim_do_quadro(f);
  if (f->simular > 0)
    simulador_atualizar(f, dt);
  SDL_Event e;
  while (SDL_PollEvent(&e))
    pads_evento(f, &e);
  pads_atualizar(f, dt);
  /* o som de cada controle (só depois de uma sala de som pedir) */
  somc_atualizar(f, dt);
}

bool forja_simular(Forja *f, int n) {
  if (f->simular > 0 || n <= 0)
    return false;
  f->simular = n;
  rel_nota(&f->rel, "controles SIMULADOS entraram no meio da sessão: o que eles fizeram não foi medido em aparelho");
  reg_linha(&f->reg, "controles simulados: %d", n);
  forja_relatorio_mudou(f);
  simulador_iniciar(f, n);
  return true;
}

void forja_fechar(Forja *f) {
  if (!FORJA)
    return;
  somc_encerrar(f);
  sons_salas_liberar();
  pads_encerrar(f);
  if (f->simular > 0)
    simulador_encerrar(f);
  forja_salvar_relatorio(f);
  {
    Evento ev;
    ev_iniciar(&ev, &f->lt, "sessao", 0);
    ev_str(&ev, "evento", "fim");
    ev_fim(&ev, &f->lt);
  }
  reg_linha(&f->reg, "fim da sessão");
  lt_fechar(&f->lt);
  reg_fechar(&f->reg);
  rel_liberar(&f->rel);
  SDL_Quit();
  FORJA = NULL;
}
