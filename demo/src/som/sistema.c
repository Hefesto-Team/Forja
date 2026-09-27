/* O som do sistema. Ver sistema.h. */
#include "sistema.h"

#include "sintese.h"

#include <math.h>

void som_de_onda(Som *dst, void *onda) {
  Onda *o = onda;
  /* o buffer da síntese é do malloc da libc; o mixer libera com SDL_free.
   * Copiamos para um buffer do SDL e devolvemos o original. */
  dst->amostras = SDL_malloc(sizeof(float) * (size_t)(o->n > 0 ? o->n : 1));
  dst->n = 0;
  if (dst->amostras && o->a) {
    SDL_memcpy(dst->amostras, o->a, sizeof(float) * (size_t)o->n);
    dst->n = o->n;
  }
  onda_liberar(o);
}

static void SDLCALL alimentar(void *userdata, SDL_AudioStream *fluxo, int adicional, int total) {
  (void)total;
  SomSistema *s = userdata;
  int quadros = adicional / (int)(sizeof(float) * 2);
  while (quadros > 0) {
    int bloco = quadros > s->tmp_quadros ? s->tmp_quadros : quadros;
    mixer_misturar(&s->mixer, s->tmp, bloco);
    SDL_PutAudioStreamData(fluxo, s->tmp, bloco * (int)sizeof(float) * 2);
    quadros -= bloco;
  }
}

static void preparar(SomSistema *s) {
  Onda o = {0};
  sint_blip(&o, 660, 0.09f);
  som_de_onda(&s->sons[SOM_NAVEGA], &o);
  const float conf[] = {523.25f, 783.99f};
  sint_acorde(&o, conf, 2, 0.06f, 0.35f);
  som_de_onda(&s->sons[SOM_CONFIRMA], &o);
  const float volta[] = {587.33f, 392.0f};
  sint_acorde(&o, volta, 2, 0.07f, 0.3f);
  som_de_onda(&s->sons[SOM_VOLTA], &o);
  const float entrou[] = {392.0f, 523.25f, 659.25f, 783.99f};
  sint_acorde(&o, entrou, 4, 0.07f, 0.6f);
  som_de_onda(&s->sons[SOM_ENTROU], &o);
  const float saiu[] = {659.25f, 493.88f, 329.63f};
  sint_acorde(&o, saiu, 3, 0.09f, 0.5f);
  som_de_onda(&s->sons[SOM_SAIU], &o);
  const float sucesso[] = {523.25f, 659.25f, 783.99f, 1046.5f, 1318.5f};
  sint_acorde(&o, sucesso, 5, 0.08f, 0.9f);
  som_de_onda(&s->sons[SOM_SUCESSO], &o);
  const float falha[] = {233.08f, 220.0f};
  sint_acorde(&o, falha, 2, 0.16f, 0.6f);
  som_de_onda(&s->sons[SOM_FALHA], &o);
  sint_martelada(&o, 420.0f, 3);
  som_de_onda(&s->sons[SOM_MARTELO], &o);
  sint_bigorna(&o, 540.0f, 1.6f, 1.0f, 5);
  som_de_onda(&s->sons[SOM_BIGORNA], &o);
  sint_bigorna(&o, 880.0f, 1.2f, 1.2f, 9);
  som_de_onda(&s->sons[SOM_BIGORNA_AGUDA], &o);
  sint_sopro(&o, 0.8f, 11);
  som_de_onda(&s->sons[SOM_SOPRO], &o);
  sint_blip(&o, 1400, 0.05f);
  som_de_onda(&s->sons[SOM_TICK], &o);
  sint_fogo(&o, 6.0f, 21);
  som_de_onda(&s->fogo, &o);
  sint_drone(&o, 24.0f);
  som_de_onda(&s->drone, &o);
}

bool som_iniciar(SomSistema *s, bool sem_som) {
  SDL_memset(s, 0, sizeof(*s));
  mixer_iniciar(&s->mixer, 2);
  s->mixer.volume = 0.8f;
  s->tmp_quadros = 1024;
  s->tmp = SDL_calloc((size_t)s->tmp_quadros * 2, sizeof(float));
  preparar(s);
  if (sem_som)
    return false;
  SDL_AudioSpec spec = {SDL_AUDIO_F32, 2, MIX_TAXA};
  s->fluxo = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec, alimentar, s);
  if (!s->fluxo)
    return false;
  SDL_ResumeAudioStreamDevice(s->fluxo);
  s->ativo = true;
  const char *nome = SDL_GetAudioDeviceName(SDL_GetAudioStreamDevice(s->fluxo));
  SDL_snprintf(s->dispositivo, sizeof(s->dispositivo), "%s", nome ? nome : "padrão");
  return true;
}

void som_encerrar(SomSistema *s) {
  if (s->fluxo)
    SDL_DestroyAudioStream(s->fluxo);
  s->fluxo = NULL;
  mixer_encerrar(&s->mixer);
  for (int i = 0; i < SOM_TOTAL_EVENTOS; i++)
    som_liberar(&s->sons[i]);
  som_liberar(&s->fogo);
  som_liberar(&s->drone);
  SDL_free(s->tmp);
  s->tmp = NULL;
}

void som_evento_pan(SomSistema *s, SomEvento e, float volume, float pan) {
  if (e < 0 || e >= SOM_TOTAL_EVENTOS)
    return;
  float ang = (pan + 1) * 0.25f * 3.14159265f;
  float g[MIX_MAX_CANAIS] = {cosf(ang) * volume * 1.41f, sinf(ang) * volume * 1.41f, 0, 0};
  mixer_tocar(&s->mixer, &s->sons[e], g, false);
}

void som_evento(SomSistema *s, SomEvento e, float volume) { som_evento_pan(s, e, volume, 0); }

void som_ambiente(SomSistema *s, bool fogo, bool musica) {
  float gf[MIX_MAX_CANAIS] = {0.28f, 0.28f, 0, 0};
  float gm[MIX_MAX_CANAIS] = {0.5f, 0.5f, 0, 0};
  if (fogo && !mixer_tocando(&s->mixer, s->voz_fogo))
    s->voz_fogo = mixer_tocar(&s->mixer, &s->fogo, gf, true);
  if (!fogo && s->voz_fogo) {
    mixer_parar(&s->mixer, s->voz_fogo, true);
    s->voz_fogo = 0;
  }
  if (musica && !mixer_tocando(&s->mixer, s->voz_drone))
    s->voz_drone = mixer_tocar(&s->mixer, &s->drone, gm, true);
  if (!musica && s->voz_drone) {
    mixer_parar(&s->mixer, s->voz_drone, true);
    s->voz_drone = 0;
  }
}

void som_volume(SomSistema *s, float v) { s->mixer.volume = v; }
