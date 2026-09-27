/* O mixer. Ver mixer.h. */
#include "mixer.h"

#include <math.h>

void mixer_iniciar(Mixer *m, int canais) {
  SDL_memset(m, 0, sizeof(*m));
  m->trava = SDL_CreateMutex();
  m->canais = canais > MIX_MAX_CANAIS ? MIX_MAX_CANAIS : (canais < 1 ? 1 : canais);
  m->volume = 1.0f;
  m->prox_id = 1;
}

void mixer_encerrar(Mixer *m) {
  if (m->trava)
    SDL_DestroyMutex(m->trava);
  m->trava = NULL;
}

int mixer_tocar(Mixer *m, const Som *som, const float *ganhos, bool laco) {
  if (!som || !som->amostras || som->n <= 0)
    return 0;
  SDL_LockMutex(m->trava);
  int livre = -1;
  for (int i = 0; i < MIX_MAX_VOZES; i++)
    if (!m->voz[i].ativa) {
      livre = i;
      break;
    }
  if (livre < 0) {
    /* sem voz livre: rouba a que está mais adiantada (a que termina antes) */
    int melhor = 0;
    float resto_min = 1e9f;
    for (int i = 0; i < MIX_MAX_VOZES; i++) {
      if (m->voz[i].laco)
        continue;
      float resto = (float)(m->voz[i].som->n - m->voz[i].pos);
      if (resto < resto_min) {
        resto_min = resto;
        melhor = i;
      }
    }
    livre = melhor;
  }
  Voz *v = &m->voz[livre];
  SDL_memset(v, 0, sizeof(*v));
  v->som = som;
  v->laco = laco;
  v->ativa = true;
  v->fade = 1;
  v->fade_alvo = 1;
  for (int c = 0; c < MIX_MAX_CANAIS; c++)
    v->ganho[c] = ganhos ? ganhos[c] : 1.0f;
  v->id = m->prox_id++;
  int id = v->id;
  SDL_UnlockMutex(m->trava);
  return id;
}

void mixer_parar(Mixer *m, int id, bool suave) {
  if (id <= 0)
    return;
  SDL_LockMutex(m->trava);
  for (int i = 0; i < MIX_MAX_VOZES; i++)
    if (m->voz[i].ativa && m->voz[i].id == id) {
      if (suave)
        m->voz[i].fade_alvo = 0;
      else
        m->voz[i].ativa = false;
    }
  SDL_UnlockMutex(m->trava);
}

void mixer_parar_tudo(Mixer *m) {
  SDL_LockMutex(m->trava);
  for (int i = 0; i < MIX_MAX_VOZES; i++)
    m->voz[i].ativa = false;
  SDL_UnlockMutex(m->trava);
}

bool mixer_tocando(Mixer *m, int id) {
  bool sim = false;
  SDL_LockMutex(m->trava);
  for (int i = 0; i < MIX_MAX_VOZES; i++)
    if (m->voz[i].ativa && m->voz[i].id == id)
      sim = true;
  SDL_UnlockMutex(m->trava);
  return sim;
}

void mixer_misturar(Mixer *m, float *saida, int quadros) {
  int nc = m->canais;
  SDL_memset(saida, 0, sizeof(float) * (size_t)quadros * (size_t)nc);
  SDL_LockMutex(m->trava);
  const float passo_fade = 1.0f / (MIX_TAXA * 0.04f); /* 40 ms */
  for (int i = 0; i < MIX_MAX_VOZES; i++) {
    Voz *v = &m->voz[i];
    if (!v->ativa)
      continue;
    const float *a = v->som->amostras;
    int n = v->som->n;
    for (int q = 0; q < quadros; q++) {
      if (v->pos >= n) {
        if (v->laco)
          v->pos = 0;
        else {
          v->ativa = false;
          break;
        }
      }
      if (v->fade != v->fade_alvo) {
        v->fade += v->fade_alvo > v->fade ? passo_fade : -passo_fade;
        if (fabsf(v->fade - v->fade_alvo) < passo_fade)
          v->fade = v->fade_alvo;
        if (v->fade <= 0 && v->fade_alvo <= 0) {
          v->ativa = false;
          break;
        }
      }
      float s = a[v->pos++] * v->fade;
      float *o = &saida[q * nc];
      for (int c = 0; c < nc; c++)
        o[c] += s * v->ganho[c];
    }
  }
  float picos[MIX_MAX_CANAIS] = {0};
  for (int q = 0; q < quadros; q++)
    for (int c = 0; c < nc; c++) {
      float *o = &saida[q * nc + c];
      float x = *o * m->volume;
      /* limitador suave: nunca estoura, e quase não colore abaixo de 0,7 */
      if (x > 0.7f)
        x = 0.7f + 0.3f * tanhf((x - 0.7f) / 0.3f);
      else if (x < -0.7f)
        x = -0.7f - 0.3f * tanhf((-x - 0.7f) / 0.3f);
      *o = x;
      float ab = fabsf(x);
      if (ab > picos[c])
        picos[c] = ab;
    }
  for (int c = 0; c < nc; c++)
    m->pico[c] = picos[c];
  m->quadros_misturados += (Uint64)quadros;
  SDL_UnlockMutex(m->trava);
}

void som_liberar(Som *s) {
  SDL_free(s->amostras);
  s->amostras = NULL;
  s->n = 0;
}
