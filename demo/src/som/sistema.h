/* O som do sistema: a música da forja e os sons da tela, na saída padrão do
 * computador (a TV, a caixa). O som que sai DO CONTROLE é outro caminho, e
 * mora no marco do áudio. */
#ifndef DEMO_SOM_SISTEMA_H
#define DEMO_SOM_SISTEMA_H

#include "mixer.h"

typedef enum SomEvento {
  SOM_NAVEGA = 0,
  SOM_CONFIRMA,
  SOM_VOLTA,
  SOM_ENTROU,
  SOM_SAIU,
  SOM_SUCESSO,
  SOM_FALHA,
  SOM_MARTELO,
  SOM_BIGORNA,
  SOM_BIGORNA_AGUDA,
  SOM_SOPRO,
  SOM_TICK,
  SOM_TOTAL_EVENTOS
} SomEvento;

typedef struct SomSistema {
  SDL_AudioStream *fluxo;
  Mixer mixer;
  bool ativo;
  char dispositivo[128];
  Som sons[SOM_TOTAL_EVENTOS];
  Som fogo, drone;
  int voz_fogo, voz_drone;
  float *tmp;
  int tmp_quadros;
} SomSistema;

bool som_iniciar(SomSistema *s, bool sem_som);
void som_encerrar(SomSistema *s);
void som_evento(SomSistema *s, SomEvento e, float volume);
/* balanço: -1 esquerda, 0 centro, 1 direita */
void som_evento_pan(SomSistema *s, SomEvento e, float volume, float pan);
void som_ambiente(SomSistema *s, bool fogo, bool musica);
/* Um som qualquer na saída do sistema (a TV), com balanço. */
int som_tocar(SomSistema *s, const Som *som, float volume, float pan);
void som_volume(SomSistema *s, float v);
/* Converte uma Onda sintetizada num Som do mixer (toma posse do buffer). */
void som_de_onda(Som *dst, void *onda);

#endif
