#ifndef DEMO_ACHAR_SOM_H
#define DEMO_ACHAR_SOM_H

#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define SOM_MAX_NOS 32

typedef enum PapelSom { PAPEL_ALTO_FALANTE = 0, PAPEL_HAPTICA, PAPEL_MICROFONE, PAPEL_TOTAL } PapelSom;

typedef enum TipoNoSom {
  NO_OUTRO = 0,
  NO_DUALSENSE_SAIDA,
  NO_DUALSENSE_ENTRADA,
  NO_NUMERADO_FALANTE,
  NO_NUMERADO_HAPTICA,
  NO_NUMERADO_MIC
} TipoNoSom;

typedef enum ComoAchou {
  ACHOU_NADA = 0,
  ACHOU_APARELHO,
  ACHOU_NUMERO,
  ACHOU_NOME,
  ACHOU_PESSOA
} ComoAchou;

typedef struct NoSistema {
  int indice;
  bool gravacao;
  char nome[256];
  char descricao[256];
  int canais;
  char sysfs[512];
  char bus[16];
  long vid, pid;
} NoSistema;

typedef struct NoSom {
  char nome[160];
  int canais;
  bool gravacao;
  TipoNoSom tipo;
  int controle_n;
  char usb[512];
  char container[48];
  int no_sistema;
} NoSom;

int achar_ler_pactl(const char *texto, bool gravacao, NoSistema *nos, int max);

TipoNoSom achar_tipo(const char *nome, bool gravacao);
int achar_numero(const char *nome);
bool achar_serve(TipoNoSom tipo, PapelSom papel);

void achar_casar(NoSom *jogo, int n_jogo, const NoSistema *sis, int n_sis);

int achar_para(const NoSom *nos, int n, PapelSom papel, const char *usb_do_pad, const char *container_do_pad,
               int numero_na_mesa, const bool *usado, ComoAchou *como);

void achar_canais(const NoSom *no, PapelSom papel, int *canal_a, int *canal_b);

const char *achar_como_rotulo(ComoAchou c);

#ifdef __cplusplus
}
#endif

#endif
