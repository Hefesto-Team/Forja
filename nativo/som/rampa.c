/* As rampas. Ver rampa.h. */
#include "rampa.h"

float rampa_passo(int taxa, float ms) {
  float n = (float)taxa * ms / 1000.0f;
  return n > 1.0f ? 1.0f / n : 1.0f;
}

float rampa_andar(float atual, float alvo, float passo) {
  if (atual < alvo)
    return atual + passo >= alvo ? alvo : atual + passo;
  return atual - passo <= alvo ? alvo : atual - passo;
}
