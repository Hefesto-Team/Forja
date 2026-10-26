#ifndef FORJA_RAMPA_H
#define FORJA_RAMPA_H

#ifdef __cplusplus
extern "C" {
#endif

#define RAMPA_SAIDA_MS 20.0f

float rampa_passo(int taxa, float ms);
float rampa_andar(float atual, float alvo, float passo);

#ifdef __cplusplus
}
#endif

#endif
