/* Os chãos dos Caminhos. Ver chao.h. */
#include "chao.h"

#include <stdbool.h>

const char *chao_nome(Chao c) {
  switch (c) {
  case CHAO_GRAMA:
    return "grama";
  case CHAO_CASCALHO:
    return "cascalho";
  case CHAO_METAL:
    return "metal";
  case CHAO_AGUA:
    return "água";
  default:
    return "?";
  }
}

int chao_pelo_envelope(const float *env, int n) {
  float max = 0;
  int i_max = 0;
  for (int i = 0; i < n; i++)
    if (env[i] > max) {
      max = env[i];
      i_max = i;
    }
  if (max < 0.05f)
    return -1;
  /* os picos: sobe além de 60% do máximo, e só conta de novo depois de cair
   * abaixo de 30% */
  int picos = 0, inicio = -1, ataque_de = -1;
  bool embaixo = true;
  for (int i = 0; i < n; i++) {
    float e = env[i] / max;
    if (ataque_de < 0 && e >= 0.1f)
      ataque_de = i;
    if (embaixo && e >= 0.6f) {
      picos++;
      embaixo = false;
      if (inicio < 0)
        inicio = i;
    } else if (!embaixo && e < 0.3f) {
      embaixo = true;
    }
  }
  if (picos >= 3)
    return CHAO_CASCALHO;
  if (picos == 2)
    return CHAO_AGUA;
  /* um pico: o metal chega de uma vez e demora a sumir; a grama sobe e desce */
  int ataque = inicio - ataque_de, cauda = 0;
  for (int i = i_max + 1; i < n && env[i] / max >= 0.3f; i++)
    cauda++;
  if (ataque <= 1 && cauda >= 7)
    return CHAO_METAL;
  return CHAO_GRAMA;
}
