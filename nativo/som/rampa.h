/* As rampas do som no controle (docs/jogo/04-ritmo-e-audio.md#a-música-que-reage):
 * cortar um som vai a zero em 15 a 30 ms, nunca de uma vez. Pura, sem SDL:
 * provada em nativo/testes/prova_som.c; o mixer usa. */
#ifndef FORJA_RAMPA_H
#define FORJA_RAMPA_H

#ifdef __cplusplus
extern "C" {
#endif

#define RAMPA_SAIDA_MS 20.0f

/* Quanto o ganho anda por amostra para ir de 1 a 0 em `ms`, na `taxa`. */
float rampa_passo(int taxa, float ms);
/* Um passo do ganho `atual` rumo ao `alvo`, sem passar dele. */
float rampa_andar(float atual, float alvo, float passo);

#ifdef __cplusplus
}
#endif

#endif
