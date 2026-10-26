#ifndef DEMO_MEDIDAS_H
#define DEMO_MEDIDAS_H

#include "relatorio.h"

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct Veredito {
  Resultado resultado;
  NivelEvidencia nivel;
  char pedido[320];
  char medido[480];
  char obs[320];
} Veredito;

#define MED_MAX_BOTOES 32

typedef struct MedBotoes {
  uint32_t pedidos;
  uint32_t mostrados;
  uint32_t chegaram;
  uint32_t na_hora;
  int trocas[MED_MAX_BOTOES];
  int trocado_por[MED_MAX_BOTOES];
  const char *const *nomes;
} MedBotoes;

void med_botoes_iniciar(MedBotoes *m, uint32_t pedidos, const char *const *nomes);
void med_botoes_apertou(MedBotoes *m, int botao, int pedido);
void med_botoes_mostrou(MedBotoes *m, int botao);
int med_botoes_contar(uint32_t mascara);
Veredito med_botoes_veredito(const MedBotoes *m, bool controle_mexeu);

#define MED_BORDA 0.85f

typedef struct MedAnalogico {
  uint8_t setores;
  float maximo;
  bool mexeu;
  float repouso_min;
  bool viu_repouso;
  bool pedido;
} MedAnalogico;

void med_analogico_iniciar(MedAnalogico *m);
void med_analogico_repouso(MedAnalogico *m, float x, float y);
void med_analogico_amostra(MedAnalogico *m, float x, float y);
int med_analogico_setor(float x, float y);
int med_analogico_setores(const MedAnalogico *m);
Veredito med_analogicos_veredito(const MedAnalogico *esq, const MedAnalogico *dir, bool controle_mexeu);

typedef struct MedGatilho {
  float minimo, maximo;
  uint8_t niveis[32];
  bool mexeu;
  int faixas;
  bool pedido;
} MedGatilho;

void med_gatilho_iniciar(MedGatilho *m);
void med_gatilho_amostra(MedGatilho *m, float v);
int med_gatilho_niveis(const MedGatilho *m);
Veredito med_gatilhos_veredito(const MedGatilho *l2, const MedGatilho *r2, bool controle_mexeu);

#define MED_TOQUE_ASPECTO 2.0f

typedef struct MedToque {
  bool tocou;
  int max_dedos;
  float x_min, x_max, y_min, y_max;
  float abertura_max;
  bool abriu, fechou;
  bool clicou;
  bool tracou;
  bool pediu_dois, pediu_clique;
  long amostras;
} MedToque;

void med_toque_iniciar(MedToque *m);
void med_toque_amostra(MedToque *m, const bool baixo[2], const float x[2], const float y[2]);
void med_toque_clique(MedToque *m);
float med_toque_distancia(float x0, float y0, float x1, float y1);
Veredito med_toque_dedos_veredito(const MedToque *m, bool controle_mexeu);
Veredito med_toque_clique_veredito(const MedToque *m, bool controle_mexeu);

typedef struct MedSensores {
  bool tem_giro, tem_acel;
  float giro_max[3];
  long amostras_giro, amostras_acel;
  uint16_t g_parado[80];
  long g_parado_n;
  float rolagem_min, rolagem_max;
  bool viu_rolagem;
  float g_pico;
  int marteladas;
  double hz_declarado, hz_host, hz_relogio;
  int sinal[2];
  bool pediu_mira, pediu_martelada;
} MedSensores;

void med_sensores_iniciar(MedSensores *m, bool tem_giro, bool tem_acel, double hz_declarado);
void med_sensores_amostra(MedSensores *m, const float giro[3], const float acel[3]);
void med_sensores_martelada(MedSensores *m);
double med_sensores_g_parado(const MedSensores *m);
Veredito med_giro_veredito(const MedSensores *m, bool controle_mexeu);
Veredito med_acel_veredito(const MedSensores *m, bool controle_mexeu);

#define MED_VOZ_ACIMA 0.25f

typedef struct MedMic {
  bool tem;
  float piso;
  bool viu_piso;
  float voz;
  float mudo;
  bool viu_mudo;
  bool apertou_mudo;
  bool pediu_mudo;
  long quadros;
} MedMic;

typedef struct MedCarga {
  float segundos;
  bool tem_giro;
  long amostras_giro;
  float parado;
  float maior_parada;
  int paradas;
  int saidas, recusadas;
  int tiros, acertos, derrubadas;
} MedCarga;

void med_carga_zerar(MedCarga *m, bool tem_giro);
void med_carga_quadro(MedCarga *m, long novas, float dt);

void med_mic_iniciar(MedMic *m, bool tem);
Veredito med_mic_veredito(const MedMic *m, bool controle_mexeu);
Veredito med_mudo_veredito(const MedMic *m, bool controle_mexeu);

#ifdef __cplusplus
}
#endif

#endif
