/* Os sons que saem DO CONTROLE nas salas de som: o sino do teste, a nota do
 * Canto, os passos dos Caminhos, o grito da Cripta. Sintetizados uma vez, na
 * primeira sala que pedir, e guardados até o fim. */
#ifndef DEMO_SONS_SALAS_H
#define DEMO_SONS_SALAS_H

#include "mixer.h"

#define SONS_PASSOS_VARIANTES 3

typedef struct SonsSalas {
  Som sino;     /* o teste do alto-falante */
  Som pulso;    /* o teste da háptica */
  Som nota;     /* a bigorna do Canto */
  Som nota_alta;
  Som grito;    /* o susto da Cripta */
  Som tropeco;  /* o tropeço dos Caminhos: um lado só */
  Som clique;   /* a arma vazia da Prova: o clique seco na mão */
  Som pronto;   /* o especial carregado, só no controle de quem tem */
  Som passo[4][SONS_PASSOS_VARIANTES];
} SonsSalas;

const SonsSalas *sons_salas(void);
void sons_salas_liberar(void);

#endif
