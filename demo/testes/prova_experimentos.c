/* A análise dos experimentos (experimental/src/analise.c). */
#include "prova.h"

#include "analise.h"

#include <math.h>
#include <stdlib.h>

void provas_experimentos(void) {
  /* um clique a 2400 amostras (50 ms), com ruído de fundo baixo */
  enum { N = 9600 };
  static float a[N];
  unsigned lcg = 7;
  for (int i = 0; i < N; i++) {
    lcg = lcg * 1664525u + 1013904223u;
    a[i] = ((float)(lcg >> 8) / 16777216.0f - 0.5f) * 0.004f;
  }
  for (int i = 2400; i < 2400 + 480; i++)
    a[i] += 0.5f * sinf(2 * 3.14159f * 1000 * (i - 2400) / EXP_TAXA) * expf(-(i - 2400) / 120.0f);
  int t = exp_ataque(a, N, 6, 0.02f);
  espera(t >= 2400 && t <= 2400 + 48, "o ataque do clique, com precisão de 1 ms");
  float silencio[N];
  for (int i = 0; i < N; i++)
    silencio[i] = a[i % 2000];
  espera(exp_ataque(silencio, N, 6, 0.02f) == -1, "só ruído não tem ataque");
  espera(fabsf(exp_db(1.0f)) < 0.01f && exp_db(0) == -90.0f, "a escala em dBFS");

  float v[5] = {40, 10, 30, 20, 50};
  espera(exp_mediana(v, 5) == 30, "a mediana de cinco");
  float w[4] = {4, 1, 3, 2};
  espera(exp_mediana(w, 4) == 2.5f, "a mediana de quatro");

  float m[4][4] = {{0.5f, 0.1f, 0.05f, 0.02f}, {0.1f, 0.4f, 0.1f, 0.05f}, {0.02f, 0.1f, 0.6f, 0.1f}, {0.01f, 0.02f, 0.1f, 0.3f}};
  float margem;
  espera(exp_diagonal(m, 4, &margem) == 4 && margem > 9, "cada microfone é o mais alto com o próprio jogador");
  m[0][0] = 0.05f; /* o microfone do P1 quase não ouve o P1: é de outro controle */
  espera(exp_diagonal(m, 4, &margem) == 3 && margem < 0, "um microfone trocado aparece");
}
