/* A análise dos experimentos — lógica pura, sem SDL, provada sem aparelho
 * (demo/testes/prova_experimentos.c). */
#ifndef FORJA_EXP_ANALISE_H
#define FORJA_EXP_ANALISE_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define EXP_TAXA 48000

/* O primeiro instante (índice da amostra) em que o som sobe acima do fundo:
 * o fundo é o RMS dos primeiros 5 ms; o ataque é a primeira janela de 1 ms
 * com RMS acima de `vezes` o fundo e de `minimo`. -1 sem ataque. */
int exp_ataque(const float *a, int n, float vezes, float minimo);

/* O RMS de a[ini .. ini+n). */
float exp_rms(const float *a, int ini, int n);

/* dBFS de um RMS (piso de -90 dB). */
float exp_db(float rms);

/* A mediana de v[0..n) (reordena v). 0 com n == 0. */
float exp_mediana(float *v, int n);

/* Quatro microfones: nivel[mic][quem_fala], n jogadores. Devolve quantos
 * microfones foram os mais altos quando o PRÓPRIO jogador falou; `margem_db`
 * recebe a menor distância (em dB) entre o próprio e o segundo mais alto. */
int exp_diagonal(const float nivel[4][4], int n, float *margem_db);

#ifdef __cplusplus
}
#endif

#endif
