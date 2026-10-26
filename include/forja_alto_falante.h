#ifndef FORJA_ALTO_FALANTE_H
#define FORJA_ALTO_FALANTE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define FORJA_TAXA 48000
#define FORJA_CANAL_DO_ALTO_FALANTE 1
#define FORJA_CANAL_VCM_E 2
#define FORJA_CANAL_VCM_D 3

typedef struct ForjaNoDeSom {
  int indice;
  char nome[256];
  char descricao[256];
  int canais;
  char sysfs[512];
  int usb_da_sony;
} ForjaNoDeSom;

int forja_nos_de_som(const char *texto, ForjaNoDeSom *nos, int max, int *total);

int forja_e_do_dualsense(const char *nome, const char *descricao);

int forja_no_por_nome(const ForjaNoDeSom *nos, int n, const char *texto);

int forja_no_do_pad(const ForjaNoDeSom *nos, int n, const char *usb_do_pad);

const char *forja_mapa_de_canais(int canais);

int forja_canal_do_alto_falante(int canais);

void forja_tom(int16_t *pcm, long n_quadros, int canais, int canal_a, int canal_b,
               double hz);

#ifdef __cplusplus
}
#endif

#endif
