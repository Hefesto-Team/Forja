/* O autômato. Ver automato.h. */
#include "automato.h"

#include "desenho.h"
#include "tema.h"
#include "texto.h"

#include <math.h>

void automato_iniciar(Automato *a, float x, float y) {
  SDL_memset(a, 0, sizeof(*a));
  a->x = x;
  a->y = y;
  a->olhar = 3.14159f / 2;
  a->vida = 1;
  a->vivo = true;
  a->conectado = true;
}

void automato_andar(Automato *a, float ax, float ay, float vel, SDL_FRect lim, float dt) {
  float m = sqrtf(ax * ax + ay * ay);
  if (m < 0.2f) {
    ax = ay = 0;
    m = 0;
  } else if (m > 1) {
    ax /= m;
    ay /= m;
    m = 1;
  }
  a->vx = aproximar(a->vx, ax * vel, 14, dt);
  a->vy = aproximar(a->vy, ay * vel, 14, dt);
  a->x = limitar(a->x + a->vx * dt, lim.x, lim.x + lim.w);
  a->y = limitar(a->y + a->vy * dt, lim.y, lim.y + lim.h);
  float v = sqrtf(a->vx * a->vx + a->vy * a->vy);
  if (v > 20) {
    a->olhar = atan2f(a->vy, a->vx);
    a->passo += dt * v / 28.0f;
  }
  a->dano = aproximar(a->dano, 0, 6, dt);
}

void automato_desenhar(SDL_Renderer *r, const Automato *a, SDL_Color cor, float s, float t, int slot) {
  float bob = a->vivo ? fabsf(sinf(a->passo)) * 5 * s : 0;
  float x = a->x, y = a->y;
  SDL_Color bronze = a->conectado ? (SDL_Color){176, 116, 60, 255} : (SDL_Color){90, 80, 72, 255};
  SDL_Color escuro = cor_escurecer(bronze, 0.45f);
  if (!a->vivo)
    bronze = cor_mistura(bronze, COR_CARVAO, 0.6f);
  /* sombra */
  ds_circulo(r, x, y + 4 * s, 26 * s, (SDL_Color){0, 0, 0, 110});
  /* pernas: alternam com o passo */
  float perna = a->vivo ? sinf(a->passo) * 7 * s : 0;
  ds_ret_arred(r, x - 16 * s, y - 20 * s + perna * 0.3f, 10 * s, 22 * s, 4 * s, escuro);
  ds_ret_arred(r, x + 6 * s, y - 20 * s - perna * 0.3f, 10 * s, 22 * s, 4 * s, escuro);
  /* tronco */
  float ty = y - 62 * s - bob;
  ds_ret_arred_grad(r, x - 24 * s, ty, 48 * s, 46 * s, 14 * s, cor_clarear(bronze, 0.15f), escuro);
  ds_contorno_arred(r, x - 24 * s, ty, 48 * s, 46 * s, 14 * s, 1.5f * s, cor_alfa(COR_OURO, 0.5f));
  /* o núcleo, na cor do jogador, que pulsa e apaga com a vida */
  float pulso = 0.7f + 0.3f * sinf(t * 3 + slot);
  float brilho = a->vivo ? (0.35f + 0.65f * a->vida) * pulso : 0.1f;
  SDL_Color nucleo = a->dano > 0.05f ? cor_mistura(cor, (SDL_Color){255, 40, 30, 255}, a->dano) : cor;
  ds_brilho(r, x, ty + 22 * s, 40 * s, nucleo, brilho * 0.8f);
  ds_circulo(r, x, ty + 22 * s, 8 * s, cor_mistura(COR_CARVAO, nucleo, brilho));
  /* braços */
  ds_ret_arred(r, x - 34 * s, ty + 6 * s, 10 * s, 30 * s, 5 * s, escuro);
  ds_ret_arred(r, x + 24 * s, ty + 6 * s, 10 * s, 30 * s, 5 * s, escuro);
  /* cabeça, e o olho olhando para onde anda */
  float hy = ty - 22 * s;
  ds_circulo_grad(r, x, hy, 20 * s, cor_clarear(bronze, 0.2f), escuro);
  float ox = cosf(a->olhar) * 7 * s, oy = sinf(a->olhar) * 4 * s;
  ds_brilho(r, x + ox, hy + oy, 14 * s, nucleo, a->vivo ? 0.7f : 0.1f);
  ds_circulo(r, x + ox, hy + oy, 4 * s, a->vivo ? cor_clarear(nucleo, 0.3f) : COR_NEUTRO);
  if (slot >= 0) {
    const char *rot = slot == 0 ? "P1" : slot == 1 ? "P2" : slot == 2 ? "P3" : "P4";
    texto_al(r, F_PEQUENA_N, x, hy - 52 * s, a->conectado ? cor : COR_NEUTRO, ALINHA_CENTRO, rot);
  }
}
