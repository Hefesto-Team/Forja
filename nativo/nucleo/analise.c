/* A análise dos experimentos. Ver analise.h. */
#include "analise.h"

#include <math.h>
#include <stdlib.h>

float exp_rms(const float *a, int ini, int n) {
  if (n <= 0)
    return 0;
  double s = 0;
  for (int i = 0; i < n; i++)
    s += (double)a[ini + i] * a[ini + i];
  return (float)sqrt(s / n);
}

float exp_db(float rms) { return rms > 3.2e-5f ? 20.0f * log10f(rms) : -90.0f; }

int exp_ataque(const float *a, int n, float vezes, float minimo) {
  const int fundo_n = EXP_TAXA / 200, janela = EXP_TAXA / 1000;
  if (n < fundo_n + janela)
    return -1;
  float fundo = exp_rms(a, 0, fundo_n);
  float limiar = fundo * vezes > minimo ? fundo * vezes : minimo;
  for (int i = fundo_n; i + janela <= n; i += janela / 4)
    if (exp_rms(a, i, janela) > limiar) {
      /* afina: a primeira amostra da janela que passa do limiar */
      for (int k = i; k < i + janela; k++)
        if (fabsf(a[k]) > limiar)
          return k;
      return i;
    }
  return -1;
}

static int menor(const void *x, const void *y) {
  float a = *(const float *)x, b = *(const float *)y;
  return (a > b) - (a < b);
}

float exp_mediana(float *v, int n) {
  if (n <= 0)
    return 0;
  qsort(v, (size_t)n, sizeof(float), menor);
  return n % 2 ? v[n / 2] : 0.5f * (v[n / 2 - 1] + v[n / 2]);
}

int exp_diagonal(const float nivel[4][4], int n, float *margem_db) {
  int certos = 0;
  float margem = 999;
  for (int mic = 0; mic < n; mic++) {
    float proprio = nivel[mic][mic], outro = 0;
    for (int quem = 0; quem < n; quem++)
      if (quem != mic && nivel[mic][quem] > outro)
        outro = nivel[mic][quem];
    if (proprio > outro)
      certos++;
    float d = exp_db(proprio) - exp_db(outro);
    if (d < margem)
      margem = d;
  }
  if (margem_db)
    *margem_db = n > 1 ? margem : 0;
  return certos;
}
