/* Os sons da forja, sintetizados — nenhum arquivo de áudio de fora.
 *
 * A bigorna é um conjunto de parciais inarmônicas com decaimento exponencial
 * (as razões de uma barra livre: 1; 2,76; 5,40; 8,93), o martelo é um baque
 * grave com a bigorna por cima, o fogo é ruído em estalos. É o timbre que dá
 * identidade ao jogo, e é também o que sai no alto-falante do controle.
 *
 * Tudo mono, 48 kHz, float em [-1, 1]. Sem SDL: provado sem som. */
#ifndef DEMO_SINTESE_H
#define DEMO_SINTESE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define SINT_TAXA 48000

typedef struct Onda {
  float *a;
  int n;
} Onda;

/* Cada função aloca `o->a` (libere com onda_liberar). Devolvem 0 se ok. */
int sint_bigorna(Onda *o, float freq, float dur, float brilho, uint32_t semente);
int sint_martelada(Onda *o, float freq, uint32_t semente);
int sint_blip(Onda *o, float freq, float dur);
int sint_acorde(Onda *o, const float *freqs, int n, float espaco, float dur_nota);
int sint_fogo(Onda *o, float dur, uint32_t semente); /* em laço sem emenda */
int sint_drone(Onda *o, float dur);                  /* em laço sem emenda */
int sint_sopro(Onda *o, float dur, uint32_t semente); /* o fole: ruído que respira */
int sint_tom(Onda *o, float freq, float dur, float rampa_s);
/* Háptica: pulsos de baixa frequência para os atuadores (canais 3 e 4). */
int sint_pulso(Onda *o, float freq, float dur, int batidas, float intervalo);
int sint_textura(Onda *o, float dur, float aspereza, uint32_t semente);
void onda_liberar(Onda *o);

/* Utilidades provadas */
float onda_pico(const Onda *o);
float onda_rms(const Onda *o);
/* O maior salto entre a última e a primeira amostra (a emenda do laço). */
float onda_emenda(const Onda *o);

#ifdef __cplusplus
}
#endif

#endif
