/* Os ícones: os botões do DualSense e os símbolos da interface, desenhados em
 * geometria (nada de imagem de fora, nada que dependa de a fonte ter o glifo). */
#ifndef DEMO_ICONES_H
#define DEMO_ICONES_H

#include <SDL3/SDL.h>

typedef enum Icone {
  IC_CRUZ = 0,  /* ✕ */
  IC_CIRCULO,   /* ○ */
  IC_QUADRADO,  /* □ */
  IC_TRIANGULO, /* △ */
  IC_L1,
  IC_R1,
  IC_L2,
  IC_R2,
  IC_L3,
  IC_R3,
  IC_OPTIONS,
  IC_CREATE,
  IC_PS,
  IC_TOUCHPAD,
  IC_MIC,
  IC_DPAD,
  IC_DPAD_CIMA,
  IC_DPAD_BAIXO,
  IC_DPAD_ESQ,
  IC_DPAD_DIR,
  IC_ANALOGICO_E,
  IC_ANALOGICO_D,
  /* símbolos */
  IC_OK,
  IC_FALHA,
  IC_NAO_MEDIDO,
  IC_USB,
  IC_BLUETOOTH,
  IC_VIRTUAL,
  IC_ALTO_FALANTE,
  IC_MICROFONE,
  IC_VIBRACAO,
  IC_GATILHO,
  IC_LUZ,
  IC_GIRO,
  IC_TOQUE,
  IC_BATERIA,
  IC_AVISO,
  IC_MARTELO,
  IC_CADEADO,
  IC_CHAMA,
  IC_TOTAL
} Icone;

/* O botão em círculo escuro com o símbolo na cor da Sony (✕ azul, ○ vermelho,
 * △ verde, □ rosa). `aceso` > 0 acende o fundo. `tam` é o diâmetro. */
void icone(SDL_Renderer *r, Icone ic, float cx, float cy, float tam, SDL_Color cor, float aceso);
/* O ícone com a cor natural dele. */
void icone_natural(SDL_Renderer *r, Icone ic, float cx, float cy, float tam, float aceso);
SDL_Color icone_cor_natural(Icone ic);

/* Uma dica: ícone + texto ("✕ confirmar"), devolve a largura ocupada. */
float icone_dica(SDL_Renderer *r, Icone ic, float x, float cy, const char *texto, SDL_Color cor);

#endif
