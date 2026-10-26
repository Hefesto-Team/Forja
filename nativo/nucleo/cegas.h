#ifndef DEMO_CEGAS_H
#define DEMO_CEGAS_H

#include "aleatorio.h"
#include "medidas.h"

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define CEGA_OPCOES 8

typedef struct Cega {
  int certos, errados, perdidos;
  int respondeu_como[CEGA_OPCOES];
} Cega;

void cega_zerar(Cega *c);
void cega_certo(Cega *c);
void cega_errado(Cega *c, int disse);
void cega_perdido(Cega *c);
int cega_total(const Cega *c);

typedef enum Lado { LADO_ESQ = 0, LADO_DIR = 1 } Lado;

typedef struct Tiro {
  int slot;
  Lado lado;
} Tiro;

int cegas_plano_tiros(Sorteio *s, const int *slots, int n, int por_lado, Tiro *out, int max);

Veredito cega_motor_veredito(const Cega *c, Lado lado, bool sdl_aceitou, bool reagiu);
Veredito cega_isolamento_veredito(int fantasmas, int chances, int vizinhos, const Cega *proprios);
Veredito cega_cor_veredito(const Cega *c, bool sdl_aceitou);
bool cega_cor_decidida(const Cega *c);

typedef enum Arma {
  ARMA_PISTOLA = 0,
  ARMA_METRALHADORA,
  ARMA_ARCO,
  ARMA_NENHUMA,
  ARMA_TOTAL
} Arma;

const char *cegas_nome_arma(Arma a);
int cegas_plano_armas(Sorteio *s, int vezes, Arma *out, int max);
Veredito cega_arma_veredito(Arma arma, const Cega *c, const Cega *nenhuma, bool sdl_aceitou);
bool cega_arma_decidida(const Cega *c);
Veredito cega_leds_veredito(const Cega *c, bool sdl_aceitou);

int cegas_plano_fontes(Sorteio *s, const int *fontes, const int *vezes, int n, int *out, int max);

Veredito cega_alto_falante_veredito(const Cega *meus, int fantasmas, int chances, bool tem_alto_falante);
#define CAMINHO_NADA 4
#define CAMINHO_NADA_LADO 2
Veredito cega_haptica_veredito(const Cega *chao, const Cega *lado_esq, const Cega *lado_dir, bool tem_haptica);
Veredito cega_led_mic_veredito(const Cega *c, bool sdl_aceitou);
bool cega_led_mic_decidida(const Cega *c);

Veredito cega_tudo_junto_veredito(const MedCarga *m, const Cega *leds, const Cega *cor, bool mexeu);

#ifdef __cplusplus
}
#endif

#endif
