#ifndef FORJA_EXP_ANALISE_H
#define FORJA_EXP_ANALISE_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define EXP_TAXA 48000

int exp_ataque(const float *a, int n, float vezes, float minimo);

float exp_rms(const float *a, int ini, int n);

float exp_db(float rms);

float exp_mediana(float *v, int n);

int exp_diagonal(const float nivel[4][4], int n, float *margem_db);

#ifdef __cplusplus
}
#endif

#endif
