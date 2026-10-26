#ifndef FORJA_MIXER_H
#define FORJA_MIXER_H

#include <SDL3/SDL.h>

#define MIX_MAX_CANAIS 4
#define MIX_MAX_VOZES 48
#define MIX_TAXA 48000

typedef struct Som {
  float *amostras;
  int n;
} Som;

typedef struct Voz {
  const Som *som;
  int pos;
  float ganho[MIX_MAX_CANAIS];
  bool laco;
  bool ativa;
  int id;
  float fade;
  float fade_alvo;
} Voz;

typedef struct Mixer {
  SDL_Mutex *trava;
  Voz voz[MIX_MAX_VOZES];
  int canais;
  float volume;
  int prox_id;
  float pico[MIX_MAX_CANAIS];
  Uint64 quadros_misturados;
} Mixer;

void mixer_iniciar(Mixer *m, int canais);
void mixer_encerrar(Mixer *m);
int mixer_tocar(Mixer *m, const Som *som, const float *ganhos, bool laco);
void mixer_parar(Mixer *m, int id, bool suave);
void mixer_parar_tudo(Mixer *m);
bool mixer_tocando(Mixer *m, int id);
void mixer_misturar(Mixer *m, float *saida, int quadros);

void som_liberar(Som *s);

#endif
