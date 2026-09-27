/* As provas da lógica da Tech Demo — sem SDL, sem som, sem aparelho.
 *
 * Mesmo desenho das provas do forja-send: uma função `espera(cond, msg)` que
 * conta falhas, e cada arquivo prova_*.c registra as suas funções. O que se
 * prova aqui é o que o jogo DECIDE (máscara, relatório, origem, payload,
 * sorteio, taxa, estações); o que o aparelho FAZ é da mesa, com o roteiro. */
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

#endif
