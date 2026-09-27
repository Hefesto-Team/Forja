/* As medidas das salas de entrada, e o veredito de cada uma.
 *
 * Uma sala de entrada joga; estas medidas olham o que chegou enquanto se
 * jogava, e dizem PASSOU, FALHOU ou NÃO MEDIDO com o porquê. A régua:
 *
 *   PASSOU      a sala viu o comportamento inteiro (todo botão na hora da
 *               runa, o analógico nas oito direções, o gatilho do zero ao
 *               fundo passando pelo meio, dois dedos que abrem e fecham...);
 *   FALHOU      a sala pediu, o controle estava vivo (outras coisas chegavam)
 *               e o que chegou foi pouco ou torto — e o `medido` diz o quê;
 *   NÃO MEDIDO  não houve como saber: o controle não mexeu nada, ou não
 *               publica a capacidade (um pad Xbox não tem giroscópio).
 *
 * Nada aqui depende do SDL: é lógica pura, provada sem aparelho.
 */
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
  NivelEvidencia nivel; /* NIVEL_NENHUM: vale o da sala */
  char pedido[320];
  char medido[480];
  char obs[320];
} Veredito;

/* ---------- botões ---------- */

#define MED_MAX_BOTOES 32

typedef struct MedBotoes {
  uint32_t pedidos;  /* os botões que a sala pede */
  uint32_t mostrados; /* os que a sala chegou a pedir (a runa acendeu ao menos uma vez) */
  uint32_t chegaram; /* os que chegaram, em qualquer hora */
  uint32_t na_hora;  /* os que chegaram com a runa deles acesa */
  int trocas[MED_MAX_BOTOES];     /* apertos de OUTRO botão com a runa de i acesa */
  int trocado_por[MED_MAX_BOTOES]; /* o último botão que chegou no lugar de i */
  const char *const *nomes;       /* o nome de cada botão, para o texto */
} MedBotoes;

void med_botoes_iniciar(MedBotoes *m, uint32_t pedidos, const char *const *nomes);
/* Chegou `botao`; `pedido` é o botão da runa acesa agora (-1 nenhuma). */
void med_botoes_apertou(MedBotoes *m, int botao, int pedido);
/* A runa de `botao` acendeu: a sala pediu. */
void med_botoes_mostrou(MedBotoes *m, int botao);
int med_botoes_contar(uint32_t mascara);
Veredito med_botoes_veredito(const MedBotoes *m, bool controle_mexeu);

/* ---------- analógicos ---------- */

#define MED_BORDA 0.85f   /* a partir daqui a direção conta como "na borda" */

typedef struct MedAnalogico {
  uint8_t setores;   /* as oito direções que chegaram à borda */
  float maximo;      /* a maior distância do centro */
  bool mexeu;        /* passou de 0,5 alguma vez */
  float repouso_min; /* a menor distância enquanto a sala pedia para soltar */
  bool viu_repouso;
  bool pedido;       /* a sala chegou a pedir o círculo */
} MedAnalogico;

void med_analogico_iniciar(MedAnalogico *m);
/* Uma amostra com a sala pedindo para soltar o analógico. */
void med_analogico_repouso(MedAnalogico *m, float x, float y);
void med_analogico_amostra(MedAnalogico *m, float x, float y);
/* O setor (0..7, 0 = direita, sentido horário na tela) de um ponto. */
int med_analogico_setor(float x, float y);
int med_analogico_setores(const MedAnalogico *m);
/* Os dois analógicos viram UMA feature. */
Veredito med_analogicos_veredito(const MedAnalogico *esq, const MedAnalogico *dir, bool controle_mexeu);

/* ---------- gatilhos analógicos ---------- */

typedef struct MedGatilho {
  float minimo, maximo;
  uint8_t niveis[32]; /* 256 bits: os níveis (v*255) que apareceram */
  bool mexeu;         /* passou de 0,2 */
  int faixas;         /* quantas vezes segurou na faixa do meio */
  bool pedido;        /* a sala chegou a pedir o fole */
} MedGatilho;

void med_gatilho_iniciar(MedGatilho *m);
void med_gatilho_amostra(MedGatilho *m, float v);
int med_gatilho_niveis(const MedGatilho *m);
Veredito med_gatilhos_veredito(const MedGatilho *l2, const MedGatilho *r2, bool controle_mexeu);

/* ---------- touchpad ---------- */

#define MED_TOQUE_ASPECTO 2.0f /* o touchpad do DualSense é cerca de duas vezes mais largo que alto */

typedef struct MedToque {
  bool tocou;
  int max_dedos;                    /* o máximo de dedos ao mesmo tempo */
  float x_min, x_max, y_min, y_max; /* a área que os toques cobriram */
  float abertura_max;               /* a maior distância entre dois dedos (em larguras) */
  bool abriu, fechou;               /* abriu além de 0,45; depois fechou abaixo de 0,15 */
  bool clicou;
  bool tracou;                      /* a sala diz: a letra foi completada, ponto a ponto */
  bool pediu_dois, pediu_clique;    /* a sala chegou ao passo dos dois dedos / ao carimbo */
  long amostras;
} MedToque;

void med_toque_iniciar(MedToque *m);
/* O estado dos dois dedos agora (x, y em 0..1). */
void med_toque_amostra(MedToque *m, const bool baixo[2], const float x[2], const float y[2]);
void med_toque_clique(MedToque *m);
/* A distância entre dois pontos do touchpad, em larguras. */
float med_toque_distancia(float x0, float y0, float x1, float y1);
Veredito med_toque_dedos_veredito(const MedToque *m, bool controle_mexeu);
Veredito med_toque_clique_veredito(const MedToque *m, bool controle_mexeu);

/* ---------- giroscópio e acelerômetro ---------- */

typedef struct MedSensores {
  bool tem_giro, tem_acel;
  float giro_max[3];   /* |rad/s| máximo por eixo (X arfagem, Y guinada, Z rolagem) */
  long amostras_giro, amostras_acel;
  uint16_t g_parado[80]; /* |a| com o giro parado, em faixas de 0,05 g (a mediana ignora as marteladas) */
  long g_parado_n;
  float rolagem_min, rolagem_max; /* da gravidade, rad */
  bool viu_rolagem;
  float g_pico;        /* o maior |a|, em g */
  int marteladas;
  double hz_declarado, hz_host, hz_relogio;
  int sinal[2];        /* postura_sinal: rolagem, arfagem */
  bool pediu_mira, pediu_martelada; /* a sala chegou aos sinos / à pedra */
} MedSensores;

void med_sensores_iniciar(MedSensores *m, bool tem_giro, bool tem_acel, double hz_declarado);
/* Uma amostra por quadro: o giro e a aceleração mais recentes. */
void med_sensores_amostra(MedSensores *m, const float giro[3], const float acel[3]);
void med_sensores_martelada(MedSensores *m);
/* A mediana de |a| (em g) com o controle parado; 0 sem amostras. */
double med_sensores_g_parado(const MedSensores *m);
Veredito med_giro_veredito(const MedSensores *m, bool controle_mexeu);
Veredito med_acel_veredito(const MedSensores *m, bool controle_mexeu);

/* ---------- microfone e mudo ---------- */

/* Os níveis estão na escala da tela: 0 = -54 dB, 1 = 0 dB (18 dB a cada
 * 0,333). A voz tem de subir ao menos 0,25 (13,5 dB) acima do silêncio. */
#define MED_VOZ_ACIMA 0.25f

typedef struct MedMic {
  bool tem;          /* o microfone deste controle foi achado */
  float piso;        /* o nível no silêncio pedido */
  bool viu_piso;
  float voz;         /* o maior nível quando a sala pediu a voz */
  float mudo;        /* o maior nível com a pessoa muda, sussurrando */
  bool viu_mudo;
  bool apertou_mudo; /* o botão do microfone chegou */
  bool pediu_mudo;   /* a sala chegou a pedir o botão */
  long quadros;      /* quadros com nível lido */
} MedMic;

void med_mic_iniciar(MedMic *m, bool tem);
Veredito med_mic_veredito(const MedMic *m, bool controle_mexeu);
Veredito med_mudo_veredito(const MedMic *m, bool controle_mexeu);

#ifdef __cplusplus
}
#endif

#endif
