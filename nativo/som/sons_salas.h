/* Os sons que saem DO CONTROLE nas salas de som: o sino do teste, a nota do
 * Canto, os passos dos Caminhos, o grito da Voz. Sintetizados uma vez, na
 * primeira sala que pedir, e guardados até o fim da sessão. */
#ifndef FORJA_SONS_SALAS_H
#define FORJA_SONS_SALAS_H

#include "mixer.h"

#ifdef __cplusplus
extern "C" {
#endif

#define SONS_PASSOS_VARIANTES 3

typedef struct SonsSalas {
  Som sino;     /* o teste do alto-falante */
  Som pulso;    /* o teste da háptica */
  Som nota;     /* a bigorna do Canto */
  Som nota_alta;
  Som grito;    /* o susto da Voz */
  Som tropeco;  /* o tropeço dos Caminhos: um lado só */
  Som clique;   /* o clique seco na mão */
  Som pronto;   /* o especial carregado, só no controle de quem tem */
  Som tom;      /* a bancada: o tom de 1 kHz do eco */
  Som passo[4][SONS_PASSOS_VARIANTES]; /* o chão (chao.h) e a variação */
} SonsSalas;

const SonsSalas *sons_salas(void);
/* Um som pelo nome: "sino", "pulso", "nota", "nota_alta", "grito", "tropeco",
 * "clique", "pronto", "tom" ou "passo:<chão>:<variação>". NULL se não existe. */
const Som *sons_salas_por_nome(const char *nome);
void sons_salas_liberar(void);

#ifdef __cplusplus
}
#endif

#endif
