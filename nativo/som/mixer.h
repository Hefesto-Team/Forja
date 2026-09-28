/* O mixer: vozes tocando buffers em N canais.
 *
 * É a saída de quatro canais de cada controle (o som da TV é do Godot):
 * contando do zero, o canal 1 é o alto-falante e os canais 2 e 3 são os dois
 * atuadores. O ganho é por voz E por canal: é isso que põe uma bigorna SÓ no
 * alto-falante e um pulso SÓ no atuador esquerdo. */
#ifndef FORJA_MIXER_H
#define FORJA_MIXER_H

#include <SDL3/SDL.h>

#define MIX_MAX_CANAIS 4
#define MIX_MAX_VOZES 48
#define MIX_TAXA 48000

typedef struct Som {
  float *amostras; /* mono, MIX_TAXA */
  int n;
} Som;

typedef struct Voz {
  const Som *som;
  int pos;
  float ganho[MIX_MAX_CANAIS];
  bool laco;
  bool ativa;
  int id;
  float fade;      /* ganho de fade atual */
  float fade_alvo; /* 0 = sumindo */
} Voz;

typedef struct Mixer {
  SDL_Mutex *trava;
  Voz voz[MIX_MAX_VOZES];
  int canais;
  float volume;
  int prox_id;
  /* medidor: o pico de cada canal no último bloco (para o diagnóstico) */
  float pico[MIX_MAX_CANAIS];
  Uint64 quadros_misturados;
} Mixer;

void mixer_iniciar(Mixer *m, int canais);
void mixer_encerrar(Mixer *m);
/* Toca `som` com um ganho por canal (NULL = 1 em todos). Devolve o id. */
int mixer_tocar(Mixer *m, const Som *som, const float *ganhos, bool laco);
void mixer_parar(Mixer *m, int id, bool suave);
void mixer_parar_tudo(Mixer *m);
bool mixer_tocando(Mixer *m, int id);
/* Mistura `quadros` quadros intercalados em `saida` (float, m->canais). */
void mixer_misturar(Mixer *m, float *saida, int quadros);

void som_liberar(Som *s);

#endif
