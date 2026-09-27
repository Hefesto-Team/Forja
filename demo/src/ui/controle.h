/* O DualSense desenhado — o espelho de cada controle na tela.
 *
 * Não é manual, é estado: o botão apertado acende na cor do jogador, o
 * analógico anda, o dedo aparece no touchpad; e o que SAI também aparece — a
 * lightbar na cor que foi mandada, os LEDs de jogador, o LED do microfone, o
 * modo de cada gatilho, o tremor nos cabos. Se o P3 toma vibração, é o
 * desenho do P3 que treme — o isolamento fica à vista (Sprint 1 da Forja). */
#ifndef DEMO_CONTROLE_H
#define DEMO_CONTROLE_H

#include <SDL3/SDL.h>

#include "../nucleo/pads.h"

typedef struct VistaControle {
  bool conectado;
  bool botao[SDL_GAMEPAD_BUTTON_COUNT];
  float ax[SDL_GAMEPAD_AXIS_COUNT];
  Dedo dedo[2];
  SDL_Color cor_jogador;
  SDL_Color luz;
  bool tem_luz;
  int leds_jogador; /* máscara de 5 bits; -1 desconhecido */
  int led_mic;
  float rumble_forte, rumble_fraco; /* 0..1 */
  ForjaTriggerMode l2, r2;
  float som;                 /* atividade do alto-falante 0..1 */
  float haptica_e, haptica_d; /* atividade dos atuadores 0..1 */
  bool mostrar_saidas;
} VistaControle;

void controle_vista_do_pad(VistaControle *v, const Pad *p);
/* Desenha com o centro em (cx, cy) e a largura dada. `t` anima. */
void controle_desenhar(SDL_Renderer *r, float cx, float cy, float largura, const VistaControle *v,
                       float t, bool reduzir_movimento);

#endif
