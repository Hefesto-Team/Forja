#ifndef FORJA_SONS_SALAS_H
#define FORJA_SONS_SALAS_H

#include "mixer.h"
#include "sintese.h"

#ifdef __cplusplus
extern "C" {
#endif

#define SONS_PASSOS_VARIANTES 3
#define SONS_PIOS 12

typedef struct SonsSalas {
  Som sino;
  Som pulso;
  Som nota;
  Som nota_alta;
  Som grito;
  Som tropeco;
  Som clique;
  Som pronto;
  Som tom;
  Som passo[4][SONS_PASSOS_VARIANTES];
  Som pio[SONS_PIOS];
  Som nota_lugar[4];
  Som nota_quebrada[4];
  Som coleta;
  Som material[MATERIAL_TOTAL];
} SonsSalas;

const SonsSalas *sons_salas(void);
const Som *sons_salas_por_nome(const char *nome);
void sons_salas_liberar(void);

#ifdef __cplusplus
}
#endif

#endif
