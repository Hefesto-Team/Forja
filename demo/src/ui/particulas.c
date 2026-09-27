/* Brasas e faíscas. Ver particulas.h. */
#include "particulas.h"

#include "desenho.h"
#include "tema.h"

#include <math.h>

void particulas_iniciar(Particulas *ps, uint64_t semente) {
  SDL_memset(ps, 0, sizeof(*ps));
  ps->taxa = 22;
  sorteio_semear(&ps->sorteio, semente ^ 0xB4A5Eull);
}

static Particula *nova(Particulas *ps) {
  if (ps->n >= MAX_PARTICULAS)
    return NULL;
  Particula *p = &ps->p[ps->n++];
  SDL_memset(p, 0, sizeof(*p));
  return p;
}

static float r01(Particulas *ps) { return sorteio_real(&ps->sorteio); }

void particulas_atualizar(Particulas *ps, float dt) {
  ps->acumulado += ps->taxa * dt;
  while (ps->acumulado >= 1) {
    ps->acumulado -= 1;
    Particula *p = nova(ps);
    if (!p)
      break;
    p->tipo = 0;
    p->x = TELA_L * (0.08f + 0.84f * r01(ps));
    p->y = TELA_A + 20;
    p->vx = (r01(ps) - 0.5f) * 30;
    p->vy = -(40 + r01(ps) * 90);
    p->vida_total = p->vida = 5 + r01(ps) * 7;
    p->tam = 1.2f + r01(ps) * 2.6f;
    p->giro = r01(ps) * 6.28f;
    p->cor = r01(ps) < 0.7f ? COR_BRASA : COR_OURO;
  }
  for (int i = 0; i < ps->n;) {
    Particula *p = &ps->p[i];
    p->vida -= dt;
    if (p->vida <= 0) {
      ps->p[i] = ps->p[--ps->n];
      continue;
    }
    switch (p->tipo) {
    case 0: /* brasa: sobe, ondula, esfria */
      p->giro += dt * 1.3f;
      p->vx += sinf(p->giro) * 12 * dt;
      p->x += p->vx * dt;
      p->y += p->vy * dt;
      p->vy *= 1 - 0.05f * dt;
      break;
    case 1: /* faísca: balística, com arrasto */
      p->vy += 900 * dt;
      p->vx *= 1 - 1.8f * dt;
      p->vy *= 1 - 0.9f * dt;
      p->x += p->vx * dt;
      p->y += p->vy * dt;
      break;
    default:
      break;
    }
    i++;
  }
}

void particulas_desenhar(SDL_Renderer *r, const Particulas *ps) {
  for (int i = 0; i < ps->n; i++) {
    const Particula *p = &ps->p[i];
    float vida = p->vida / p->vida_total; /* 1 -> 0 */
    switch (p->tipo) {
    case 0: {
      float pisca = 0.65f + 0.35f * sinf(p->giro * 7.0f);
      float a = limitar(vida * 1.4f, 0, 1) * pisca;
      SDL_Color c = cor_mistura(COR_BRASA_VIVA, p->cor, 1 - vida);
      ds_brilho(r, p->x, p->y, p->tam * 7, c, a * 0.55f);
      ds_circulo(r, p->x, p->y, p->tam * 0.7f, cor_alfa(cor_clarear(c, 0.4f), a));
      break;
    }
    case 1: {
      float a = limitar(vida * 1.6f, 0, 1);
      float vx = p->vx * 0.018f, vy = p->vy * 0.018f;
      ds_linha(r, p->x - vx, p->y - vy, p->x, p->y, p->tam, cor_alfa(cor_clarear(p->cor, 0.5f), a));
      ds_brilho(r, p->x, p->y, p->tam * 6, p->cor, a * 0.5f);
      break;
    }
    case 2: {
      float t = 1 - vida;
      float raio = p->tam * sai_rapido(t);
      ds_anel(r, p->x, p->y, raio, 3 + 6 * (1 - t), cor_alfa(p->cor, (1 - t) * 0.8f));
      break;
    }
    }
  }
}

void particulas_faiscas(Particulas *ps, float x, float y, int quantas, SDL_Color cor, float forca) {
  for (int i = 0; i < quantas; i++) {
    Particula *p = nova(ps);
    if (!p)
      return;
    float ang = -3.14159f * (0.05f + 0.9f * r01(ps));
    float vel = (250 + r01(ps) * 650) * forca;
    p->tipo = 1;
    p->x = x;
    p->y = y;
    p->vx = cosf(ang) * vel;
    p->vy = sinf(ang) * vel;
    p->vida_total = p->vida = 0.35f + r01(ps) * 0.6f;
    p->tam = 1.5f + r01(ps) * 2.0f;
    p->cor = r01(ps) < 0.5f ? cor : COR_OURO;
  }
}

void particulas_anel(Particulas *ps, float x, float y, SDL_Color cor, float raio_final) {
  Particula *p = nova(ps);
  if (!p)
    return;
  p->tipo = 2;
  p->x = x;
  p->y = y;
  p->vida_total = p->vida = 0.55f;
  p->tam = raio_final;
  p->cor = cor;
}

void particulas_brasas(Particulas *ps, float x, float y, int quantas, SDL_Color cor) {
  for (int i = 0; i < quantas; i++) {
    Particula *p = nova(ps);
    if (!p)
      return;
    p->tipo = 0;
    p->x = x + (r01(ps) - 0.5f) * 40;
    p->y = y + (r01(ps) - 0.5f) * 20;
    p->vx = (r01(ps) - 0.5f) * 80;
    p->vy = -(60 + r01(ps) * 160);
    p->vida_total = p->vida = 1.2f + r01(ps) * 1.6f;
    p->tam = 1.5f + r01(ps) * 2.5f;
    p->giro = r01(ps) * 6.28f;
    p->cor = cor;
  }
}
