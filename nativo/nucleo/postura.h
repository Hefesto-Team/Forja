#ifndef DEMO_POSTURA_H
#define DEMO_POSTURA_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define POSTURA_G 9.80665f

typedef struct Postura {
  float rolagem, arfagem;
  float guinada;
  float acel[3];
  bool tem_acel;
  uint64_t ultimo_ns;
  uint64_t ultimo_host_ns;
  long amostras_giro, amostras_acel;

  float janela_giro[2];
  float janela_acel0[2];
  bool janela_base_ok;
  float janela_t;
  int concorda[2], discorda[2];
} Postura;

void postura_zerar(Postura *p);
void postura_giro(Postura *p, const float g[3], uint64_t sensor_ns, uint64_t host_ns);
void postura_acel(Postura *p, const float a[3]);

float postura_rolagem_da_gravidade(const float a[3]);
float postura_arfagem_da_gravidade(const float a[3]);
float postura_g(const float a[3]);

int postura_sinal(const Postura *p, int eixo);
int postura_sinal_contagem(int concorda, int discorda);

#ifdef __cplusplus
}
#endif

#endif
