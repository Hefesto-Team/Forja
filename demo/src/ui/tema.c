/* O tema. Ver tema.h. */
#include "tema.h"

#include <math.h>

const SDL_Color COR_FUNDO_0 = {12, 9, 8, 255};
const SDL_Color COR_FUNDO_1 = {24, 17, 13, 255};
const SDL_Color COR_CARVAO = {34, 25, 20, 255};
const SDL_Color COR_PAINEL = {42, 31, 24, 255};
const SDL_Color COR_PAINEL_CLARO = {62, 46, 35, 255};
const SDL_Color COR_BRONZE_ESCURO = {96, 62, 32, 255};
const SDL_Color COR_BRONZE = {160, 104, 52, 255};
const SDL_Color COR_BRONZE_CLARO = {218, 156, 84, 255};
const SDL_Color COR_OURO = {255, 204, 96, 255};
const SDL_Color COR_BRASA = {255, 110, 32, 255};
const SDL_Color COR_BRASA_VIVA = {255, 160, 70, 255};
const SDL_Color COR_TEXTO = {247, 239, 229, 255};
const SDL_Color COR_TEXTO_2 = {196, 180, 162, 255};
const SDL_Color COR_TEXTO_3 = {140, 124, 108, 255};
const SDL_Color COR_OK = {112, 222, 142, 255};
const SDL_Color COR_FALHA = {255, 96, 82, 255};
const SDL_Color COR_AVISO = {255, 186, 56, 255};
const SDL_Color COR_NEUTRO = {150, 138, 126, 255};

const SDL_Color COR_JOGADOR[4] = {
    {82, 148, 255, 255}, /* P1 azul */
    {255, 84, 76, 255},  /* P2 vermelho */
    {70, 222, 132, 255}, /* P3 verde */
    {255, 112, 206, 255} /* P4 rosa */
};

const SDL_Color COR_LIGHTBAR[4] = {
    {0, 72, 255, 255},  /* P1 */
    {255, 24, 8, 255},  /* P2 */
    {0, 255, 64, 255},  /* P3 */
    {255, 8, 168, 255}, /* P4 */
};

const char *NOME_COR_JOGADOR[4] = {"azul", "vermelho", "verde", "rosa"};

static Uint8 b8(float v) {
  if (v < 0)
    v = 0;
  if (v > 255)
    v = 255;
  return (Uint8)(v + 0.5f);
}

SDL_Color cor_alfa(SDL_Color c, float a) {
  c.a = b8(c.a * limitar(a, 0.0f, 1.0f));
  return c;
}

SDL_Color cor_mistura(SDL_Color a, SDL_Color b, float t) {
  t = limitar(t, 0.0f, 1.0f);
  SDL_Color r = {b8(a.r + (b.r - a.r) * t), b8(a.g + (b.g - a.g) * t), b8(a.b + (b.b - a.b) * t),
                 b8(a.a + (b.a - a.a) * t)};
  return r;
}

SDL_Color cor_clarear(SDL_Color c, float t) {
  SDL_Color branco = {255, 255, 255, c.a};
  return cor_mistura(c, branco, t);
}

SDL_Color cor_escurecer(SDL_Color c, float t) {
  SDL_Color preto = {0, 0, 0, c.a};
  return cor_mistura(c, preto, t);
}

SDL_FColor cor_f(SDL_Color c) {
  SDL_FColor f = {c.r / 255.0f, c.g / 255.0f, c.b / 255.0f, c.a / 255.0f};
  return f;
}

float limitar(float v, float a, float b) { return v < a ? a : (v > b ? b : v); }

float suave(float t) {
  t = limitar(t, 0, 1);
  return t * t * (3 - 2 * t);
}

float sai_rapido(float t) {
  t = limitar(t, 0, 1);
  float u = 1 - t;
  return 1 - u * u * u;
}

float elastico(float t) {
  t = limitar(t, 0, 1);
  if (t == 0 || t == 1)
    return t;
  return powf(2, -10 * t) * sinf((t * 10 - 0.75f) * (2 * 3.14159265f / 3)) + 1;
}

float aproximar(float atual, float alvo, float taxa, float dt) {
  return alvo + (atual - alvo) * expf(-taxa * dt);
}
