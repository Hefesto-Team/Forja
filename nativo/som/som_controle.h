#ifndef FORJA_SOM_CONTROLE_H
#define FORJA_SOM_CONTROLE_H

#include <SDL3/SDL.h>

#include "achar_som.h"
#include "mixer.h"

#ifdef __cplusplus
extern "C" {
#endif

struct Forja;

typedef struct SaidaCtl {
  bool usada;
  bool virtual_;
  int no;
  SDL_AudioStream *fluxo;
  Mixer mixer;
  int canais;
  float *tmp;
  int tmp_quadros;
  float nivel[MIX_MAX_CANAIS];
  int dono;
} SaidaCtl;

typedef struct SomJogador {
  int no[PAPEL_TOTAL];
  ComoAchou como[PAPEL_TOTAL];
  int canal_a[PAPEL_TOTAL], canal_b[PAPEL_TOTAL];
  int saida[PAPEL_TOTAL];
  SDL_AudioStream *mic;
  float mic_nivel, mic_pico;
  long mic_quadros;
  bool fone;
  bool mic_virtual;
  float *escuta;
  int escuta_cap, escuta_n;
} SomJogador;

#define SOMC_MAX_SAIDAS 12

typedef struct SomControles {
  NoSom nos[SOM_MAX_NOS];
  int n;
  bool listou;
  SaidaCtl saidas[SOMC_MAX_SAIDAS];
  SomJogador j[4];
  char plataforma[96];
} SomControles;

void somc_preparar(struct Forja *a);
void somc_encerrar(struct Forja *a);
bool somc_preparado(void);
void somc_trocar(struct Forja *a, int slot, PapelSom papel, int direcao);
bool somc_tem(struct Forja *a, int slot, PapelSom papel);
bool somc_estereo(struct Forja *a, int slot, PapelSom papel);
const char *somc_nome(struct Forja *a, int slot, PapelSom papel);
ComoAchou somc_como(struct Forja *a, int slot, PapelSom papel);
const char *somc_plataforma(void);

int somc_falante(struct Forja *a, int slot, const Som *s, float ganho, const char *nome);
int somc_haptica(struct Forja *a, int slot, const Som *esq, const Som *dir, float ganho, const char *nome);
void somc_parar_tudo(struct Forja *a, int slot);
void somc_atualizar(struct Forja *a, float dt);
float somc_mic_nivel(struct Forja *a, int slot);
float somc_mic_pico(struct Forja *a, int slot);
long somc_mic_quadros(struct Forja *a, int slot);
float somc_virtual_falante(struct Forja *a, int slot);
float somc_virtual_atuador(struct Forja *a, int slot, int lado);

bool somc_escutar(struct Forja *a, int slot, float segundos);
const float *somc_escuta(struct Forja *a, int slot, int *n);
void somc_escuta_parar(struct Forja *a, int slot);

void somc_relatorio(struct Forja *a);

void somc_plataforma_nos(SomControles *sc, char *rotulo, size_t tam);
bool somc_plataforma_pad(struct Forja *a, int slot, char *usb, size_t tam_usb, char *container, size_t tam_c);

#ifdef __cplusplus
}
#endif

#endif
