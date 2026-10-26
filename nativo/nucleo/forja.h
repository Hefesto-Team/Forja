#ifndef FORJA_SESSAO_H
#define FORJA_SESSAO_H

#include <SDL3/SDL.h>

#include "linha_tempo.h"
#include "pads.h"
#include "registro.h"
#include "relatorio.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct Forja {
  float t;
  float dt;
  Uint64 inicio_ns;
  Uint64 relogio_sim_ns;
  float intensidade;
  unsigned long long semente;

  Relatorio rel;
  Registro reg;
  LinhaTempo lt;
  Pads pads;
  long seq_saida[MAX_JOGADORES + 1];

  char pasta_relatorios[1024];
  char base_arquivos[64];
  bool relatorio_sujo;

  char aviso[200];
  int aviso_seq;

  int simular;
  bool robo;
  bool em_sala;
  bool so_virtuais;
} Forja;

extern Forja *FORJA;

bool forja_abrir(Forja *f, const char *pasta, int simular, bool robo, unsigned long long semente);
void forja_quadro(Forja *f, float dt);
bool forja_simular(Forja *f, int n);
void forja_fechar(Forja *f);

double forja_agora(const Forja *f);
void forja_hora(char *out, size_t tam);
void forja_avisar(Forja *f, const char *formato, ...)
#if defined(__GNUC__)
    __attribute__((format(printf, 2, 3)))
#endif
    ;
void forja_relatorio_mudou(Forja *f);
bool forja_salvar_relatorio(Forja *f);
bool forja_sob_wine(void);
const char *forja_versao_wine(void);

#ifdef __cplusplus
}
#endif

#endif
