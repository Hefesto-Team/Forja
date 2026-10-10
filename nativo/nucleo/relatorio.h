#ifndef DEMO_RELATORIO_H
#define DEMO_RELATORIO_H

#include "catalogo.h"

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define REL_MAX_CONTROLES 4

typedef enum Resultado {
  RES_NAO_MEDIDO = 0,
  RES_PASSOU,
  RES_FALHOU
} Resultado;

typedef enum NivelEvidencia {
  NIVEL_NENHUM = 0,
  NIVEL_MONTOU,
  NIVEL_SAIU,
  NIVEL_OBEDECEU,
  NIVEL_REAGIU
} NivelEvidencia;

typedef struct RelSom {
  char nome[160];
  char como[96];
  int canais;
} RelSom;

typedef struct RelControle {
  int presente;
  int jogador;
  char nome[128];
  char nome_do_sistema[128];
  char vid_pid[16];
  char conexao[48];
  char origem[64];
  char evidencia[160];
  char tipo_sdl[32];
  char firmware[16];
  char bateria[48];
  double giro_declarado_hz, giro_medido_hz, giro_medido_relogio_hz;
  double acel_declarado_hz, acel_medido_hz;
  RelSom alto_falante, microfone, haptica;
  int reconexoes;
  int hidraw_sem_permissao;
} RelControle;

#define REL_CAUSA_HIDRAW "sem permissão no hidraw: os efeitos não chegam"

typedef struct RelItem {
  int jogador;
  Feature feature;
  Resultado resultado;
  NivelEvidencia nivel;
  char pedido[320];
  char medido[480];
  char observacao[320];
  double t;
} RelItem;

typedef struct Relatorio {
  char sessao[40];
  char inicio[32];
  char fim[32];
  char versao[48];
  char plataforma[128];
  char sdl[48];
  char contrato[200];
  unsigned long long semente;
  RelControle controles[REL_MAX_CONTROLES];
  RelItem *itens;
  int n_itens, cap_itens;
  char notas[8][200];
  int n_notas;
} Relatorio;

void rel_iniciar(Relatorio *r);
void rel_liberar(Relatorio *r);

RelItem *rel_registrar(Relatorio *r, int jogador, Feature f, Resultado res, NivelEvidencia nivel,
                       const char *pedido, const char *medido, const char *observacao, double t);

const RelItem *rel_ultimo(const Relatorio *r, int jogador, Feature f);

void rel_nota(Relatorio *r, const char *texto);

void rel_copiar(char *campo, size_t tam, const char *de);

const char *rel_resultado_rotulo(Resultado res);
const char *rel_nivel_rotulo(NivelEvidencia n);

int rel_json(const Relatorio *r, char **saida, size_t *tam);
int rel_texto(const Relatorio *r, char **saida, size_t *tam);

#ifdef __cplusplus
}
#endif

#endif
