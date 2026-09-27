/* As peças da interface: painéis de bronze, chips, barras, selos de veredito,
 * a barra de dicas. Uma linguagem só em todas as telas. */
#ifndef DEMO_WIDGETS_H
#define DEMO_WIDGETS_H

#include <SDL3/SDL.h>

#include "../nucleo/relatorio.h"
#include "icones.h"

typedef struct Dica {
  Icone ic;
  const char *texto;
} Dica;

/* Painel: fundo de carvão, moldura de bronze com cantos marcados. `acento`
 * tinge a moldura (cor do jogador), `destaque` em [0,1] acende. */
void wg_painel(SDL_Renderer *r, float x, float y, float w, float h, SDL_Color acento, float destaque);
/* Um chip (pílula) com ícone opcional (IC_TOTAL = sem). Devolve a largura. */
float wg_chip(SDL_Renderer *r, float x, float y, Icone ic, const char *texto, SDL_Color cor, bool cheio);
float wg_chip_largura(Icone ic, const char *texto);
void wg_barra(SDL_Renderer *r, float x, float y, float w, float h, float v, SDL_Color cor);
/* Barra -1..1 com o zero no meio. */
void wg_barra_centro(SDL_Renderer *r, float x, float y, float w, float h, float v, SDL_Color cor);
void wg_medidor_vertical(SDL_Renderer *r, float x, float y, float w, float h, float v, float pico,
                         SDL_Color cor);
/* O selo do veredito, com ícone E palavra (nunca só cor). */
void wg_selo(SDL_Renderer *r, float cx, float cy, Resultado res, float escala);
/* A barra de dicas no rodapé, centralizada. */
void wg_rodape(SDL_Renderer *r, const Dica *dicas, int n);
/* O cabeçalho de uma tela: título em versal, subtítulo, e o meandro. */
void wg_cabecalho(SDL_Renderer *r, const char *titulo, const char *subtitulo, float t);
/* O aviso curto no topo (quem caiu, quem voltou). */
void wg_aviso(SDL_Renderer *r, const char *texto, float idade);
/* Um item de menu grande. */
void wg_item_menu(SDL_Renderer *r, float x, float y, float w, float h, const char *rotulo,
                  const char *sub, bool selecionado, float brilho, Icone ic);
/* Texto com ícones no meio: "Aperte {X} para entrar". Marcas: {X} {O} {Q} {T}
 * {L1} {R1} {L2} {R2} {L3} {R3} {OPT} {CRI} {PS} {TP} {MIC} {DP} e os
 * analógicos {LE} {LD}. Devolve a largura. */
float wg_texto_rico(SDL_Renderer *r, int fonte, float x, float y, SDL_Color cor, int alinhamento,
                    const char *s);
float wg_texto_rico_largura(int fonte, const char *s);

/* Um ângulo para a tela, de radianos: "+12°", "−3°", "0°" (nunca "-0°"). */
const char *wg_graus(float rad);

/* A etiqueta do jogador: "P1" num escudo com a cor dele. */
void wg_escudo_jogador(SDL_Renderer *r, float cx, float cy, float tam, int slot, bool vivo);

#endif
