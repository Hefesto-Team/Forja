/* As primitivas de desenho — tudo vetorial, pelo SDL_RenderGeometry.
 *
 * Nenhuma imagem de fora: a forja, a bigorna, o controle e os ícones são
 * geometria desenhada aqui, o que mantém o .exe num arquivo só e a arte com a
 * cara deste jogo. As texturas que existem (brilho, vinheta, ruído) nascem no
 * início, por conta. */
#ifndef DEMO_DESENHO_H
#define DEMO_DESENHO_H

#include <SDL3/SDL.h>

bool desenho_iniciar(SDL_Renderer *r);
void desenho_encerrar(void);

void ds_ret(SDL_Renderer *r, float x, float y, float w, float h, SDL_Color c);
void ds_ret_grad(SDL_Renderer *r, float x, float y, float w, float h, SDL_Color topo, SDL_Color base);
void ds_ret_arred(SDL_Renderer *r, float x, float y, float w, float h, float raio, SDL_Color c);
void ds_ret_arred_grad(SDL_Renderer *r, float x, float y, float w, float h, float raio,
                       SDL_Color topo, SDL_Color base);
void ds_contorno_arred(SDL_Renderer *r, float x, float y, float w, float h, float raio, float esp,
                       SDL_Color c);
void ds_circulo(SDL_Renderer *r, float cx, float cy, float raio, SDL_Color c);
void ds_circulo_grad(SDL_Renderer *r, float cx, float cy, float raio, SDL_Color centro,
                     SDL_Color borda);
void ds_anel(SDL_Renderer *r, float cx, float cy, float raio, float esp, SDL_Color c);
/* arco de a0 a a1 em radianos (0 = direita, sentido horário na tela) */
void ds_arco(SDL_Renderer *r, float cx, float cy, float raio, float esp, float a0, float a1,
             SDL_Color c);
void ds_linha(SDL_Renderer *r, float x0, float y0, float x1, float y1, float esp, SDL_Color c);
/* polilinha com juntas arredondadas; `fechada` liga o último ao primeiro */
void ds_polilinha(SDL_Renderer *r, const SDL_FPoint *p, int n, float esp, SDL_Color c, bool fechada);
/* polígono qualquer (côncavo inclusive), por recorte de orelhas */
void ds_poligono(SDL_Renderer *r, const SDL_FPoint *p, int n, SDL_Color c);
void ds_triangulo(SDL_Renderer *r, SDL_FPoint a, SDL_FPoint b, SDL_FPoint c, SDL_Color cor);

/* Brilho aditivo (a textura de gradiente radial). intensidade em [0,1+]. */
void ds_brilho(SDL_Renderer *r, float cx, float cy, float raio, SDL_Color c, float intensidade);
/* O fundo da forja: gradiente, ruído de metal martelado e vinheta. */
void ds_fundo(SDL_Renderer *r, float t, float calor);
void ds_vinheta(SDL_Renderer *r, float forca);
/* A faixa grega (meandro) — o ornamento das molduras. */
void ds_greca(SDL_Renderer *r, float x, float y, float largura, float altura, float esp, SDL_Color c);

/* Suaviza uma curva fechada (Catmull-Rom): `n` pontos de controle viram
 * `n * passos` pontos em `saida` (que deve caber). Devolve quantos. */
int ds_suavizar(const SDL_FPoint *ctrl, int n, int passos, SDL_FPoint *saida);

#endif
