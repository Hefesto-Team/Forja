#ifndef DEMO_PROVA_H
#define DEMO_PROVA_H

#include <stdio.h>
#include <string.h>

extern int prova_falhas;
extern int prova_contas;

#define espera(cond, msg)                                                                  \
  do {                                                                                     \
    prova_contas++;                                                                        \
    if (!(cond)) {                                                                         \
      fprintf(stderr, "FALHOU %s:%d  %s\n", __FILE__, __LINE__, (msg));                    \
      prova_falhas++;                                                                      \
    }                                                                                      \
  } while (0)

#define espera_str(a, b, msg) espera(strcmp((a), (b)) == 0, msg)

typedef void (*ProvaFn)(void);

void provas_mascara(void);
void provas_utf8(void);
void provas_sorteio(void);
void provas_taxa(void);
void provas_relatorio(void);
void provas_origem(void);
void provas_efeitos(void);
void provas_catalogo(void);
void provas_postura(void);
void provas_medidas(void);
void provas_cegas(void);
void provas_achar_som(void);
void provas_som(void);
void provas_experimentos(void);

#endif
