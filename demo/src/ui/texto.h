/* O texto — duas famílias, as duas sob a SIL Open Font License, embutidas:
 *
 *   - Atkinson Hyperlegible (Braille Institute): o corpo do texto. Foi
 *     desenhada para leitores com baixa visão — cada letra se distingue da
 *     vizinha. É a escolha certa para um projeto de acessibilidade;
 *   - Cinzel: os títulos, com a letra das inscrições em pedra — o mito grego
 *     que dá nome ao Hefesto.
 *
 * Os glifos são rasterizados no início pelo stb_truetype (domínio público),
 * num atlas por tamanho. Português inteiro: Latin-1, travessão, reticências,
 * aspas curvas e setas. */
#ifndef DEMO_TEXTO_H
#define DEMO_TEXTO_H

#include <SDL3/SDL.h>

typedef enum Fonte {
  F_MINI = 0,   /* 18 */
  F_PEQUENA,    /* 22 */
  F_TEXTO,      /* 28 */
  F_MEDIA,      /* 34 */
  F_GRANDE,     /* 44 */
  F_PEQUENA_N,  /* 22 negrito */
  F_TEXTO_N,    /* 28 negrito */
  F_MEDIA_N,    /* 34 negrito */
  F_GRANDE_N,   /* 44 negrito */
  F_ENORME_N,   /* 64 negrito */
  F_TITULO_P,   /* 40 Cinzel */
  F_TITULO,     /* 64 Cinzel */
  F_TITULO_G,   /* 104 Cinzel */
  F_TITULO_X,   /* 150 Cinzel, só maiúsculas e dígitos */
  F_TOTAL_FONTES
} Fonte;

typedef enum Alinhamento { ALINHA_ESQ = 0, ALINHA_CENTRO, ALINHA_DIR } Alinhamento;

bool texto_iniciar(SDL_Renderer *r);
void texto_encerrar(void);

float texto_largura(Fonte f, const char *s);
float texto_altura(Fonte f);   /* altura de linha */
float texto_ascendente(Fonte f);

/* Desenha com o topo em y. Devolve a largura. */
float texto(SDL_Renderer *r, Fonte f, float x, float y, SDL_Color c, const char *s);
float texto_al(SDL_Renderer *r, Fonte f, float x, float y, SDL_Color c, Alinhamento a, const char *s);
/* Com sombra projetada (legível sobre brilho). */
float texto_sombra(SDL_Renderer *r, Fonte f, float x, float y, SDL_Color c, Alinhamento a,
                   const char *s);
/* Espaçamento extra entre letras (títulos em versal). */
float texto_espacado(SDL_Renderer *r, Fonte f, float x, float y, SDL_Color c, Alinhamento a,
                     float espaco, const char *s);
float texto_largura_espacado(Fonte f, float espaco, const char *s);
/* Quebra por palavra em `largura`. Devolve a altura ocupada. `desenhar` false
 * só mede. */
float texto_bloco(SDL_Renderer *r, Fonte f, float x, float y, float largura, SDL_Color c,
                  Alinhamento a, float entrelinha, bool desenhar, const char *s);
/* printf para um buffer interno rotativo (8 buffers de 512 bytes). */
const char *fmt(const char *formato, ...)
#if defined(__GNUC__)
    __attribute__((format(printf, 1, 2)))
#endif
    ;

#endif
