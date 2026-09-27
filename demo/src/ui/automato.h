/* O autômato de bronze — o boneco de cada jogador. Hefesto forjou autômatos que
 * o ajudavam a andar; aqui cada jogador é um deles, com o núcleo na cor do
 * lugar. */
#ifndef DEMO_AUTOMATO_H
#define DEMO_AUTOMATO_H

#include <SDL3/SDL.h>

typedef struct Automato {
  float x, y;         /* posição dos pés */
  float vx, vy;
  float olhar;        /* ângulo para onde olha */
  float passo;        /* fase da caminhada */
  float dano;         /* lampejo de dano, decai */
  float vida;         /* 0..1 */
  bool vivo;
  bool conectado;
} Automato;

void automato_iniciar(Automato *a, float x, float y);
/* Anda com o analógico (-1..1); `limites` é o retângulo onde ele pode estar. */
void automato_andar(Automato *a, float ax, float ay, float velocidade, SDL_FRect limites, float dt);
void automato_desenhar(SDL_Renderer *r, const Automato *a, SDL_Color cor, float escala, float t, int slot);

#endif
