/* O título: uma frase, dois botões, e a forja acesa.
 *
 * Sprint 2 da Forja: "Título: 1 frase + 2 botões — Jogar / Escolher modo. Sem
 * USB 0x02 na cara." O protocolo mora no diagnóstico; aqui mora o convite. */
#include "../app.h"

#include "../nucleo/simulador.h"

#include "../ui/desenho.h"
#include "../ui/icones.h"
#include "../ui/tema.h"
#include "../ui/texto.h"
#include "../ui/widgets.h"

#include <math.h>

static int g_sel;
static float g_t;
static float g_golpe;     /* 0..1 do ciclo do martelo */
static float g_flash;     /* o lampejo do lingote na pancada */
static int g_golpes;

static void entrar(App *a) {
  g_sel = 0;
  g_t = 0;
  g_golpe = 0.3f;
  g_flash = 0;
  a->brasas.taxa = 26;
  som_ambiente(&a->som, true, true);
}

static void sair(App *a) { (void)a; }

static void atualizar(App *a, float dt) {
  g_t += dt;
  float antes = g_golpe;
  g_golpe += dt / 2.6f;
  if (g_golpe >= 1)
    g_golpe -= 1;
  /* a pancada acontece em 0,62 do ciclo */
  if (antes < 0.62f && g_golpe >= 0.62f) {
    g_flash = 1;
    g_golpes++;
    particulas_faiscas(&a->brasas, 640, 780, 36, COR_BRASA_VIVA, 1.0f);
    particulas_anel(&a->brasas, 640, 780, COR_OURO, 160);
    som_evento(&a->som, g_golpes % 3 ? SOM_MARTELO : SOM_BIGORNA, 0.28f);
    if (!a->cfg.reduzir_movimento)
      a->tremor = 5;
  }
  g_flash = aproximar(g_flash, 0, 5, dt);

  /* o robô escolhe "Jogar" (ou a Prova de Fogo, se pedida) */
  if (robo_ativo() && g_t > 1.2f && g_t - dt <= 1.2f) {
    for (int i = 0; i < MAX_PADS; i++)
      if (a->pads.pad[i].usado) {
        robo_apertar(a, i, SDL_GAMEPAD_BUTTON_SOUTH, 0.1f);
        break;
      }
  }

  Nav *n = &a->nav;
  if (n->cima || n->esq) {
    g_sel = (g_sel + 1) % 2;
    som_evento(&a->som, SOM_NAVEGA, 0.5f);
  }
  if (n->baixo || n->dir) {
    g_sel = (g_sel + 1) % 2;
    som_evento(&a->som, SOM_NAVEGA, 0.5f);
  }
  if (n->confirma) {
    som_evento(&a->som, SOM_CONFIRMA, 0.7f);
    a->modo_jogo = g_sel;
    app_trocar_cena(a, &CENA_LOBBY);
  } else if (n->extra) {
    som_evento(&a->som, SOM_CONFIRMA, 0.7f);
    app_trocar_cena(a, &CENA_DIAGNOSTICO);
  } else if (n->volta) {
    a->rodando = false;
  }
}

/* A bigorna, em silhueta: chifre à esquerda, face, cintura, pé. */
static void bigorna(SDL_Renderer *r, float cx, float cy, float s) {
  static const SDL_FPoint forma[] = {
      {-128, -46}, {150, -46}, {158, -38}, {158, -14}, {92, -8},   {78, 6},    {70, 40},
      {118, 76},   {126, 96},  {-116, 96}, {-108, 76}, {-62, 40},  {-70, 6},   {-100, -6},
      {-150, -12}, {-196, -20}, {-236, -28}, {-196, -38}, {-150, -44},
  };
  enum { N = sizeof(forma) / sizeof(forma[0]) };
  SDL_FPoint p[N];
  for (int i = 0; i < N; i++) {
    p[i].x = cx + forma[i].x * s;
    p[i].y = cy + forma[i].y * s;
  }
  ds_brilho(r, cx, cy + 90 * s, 330 * s, COR_BRASA, 0.18f);
  ds_poligono(r, p, N, (SDL_Color){30, 25, 22, 255});
  ds_polilinha(r, p, N, 2.5f, cor_alfa(COR_BRONZE_ESCURO, 0.9f), true);
  /* o fio da face, polido, que pega a luz do fogo */
  ds_linha(r, cx - 124 * s, cy - 44 * s, cx + 152 * s, cy - 44 * s, 3 * s, cor_alfa(COR_BRONZE_CLARO, 0.9f));
}

static void martelo(SDL_Renderer *r, float px, float py, float ang, float s) {
  /* o martelo gira em torno de (px, py), o punho do ferreiro */
  float c = cosf(ang), sn = sinf(ang);
#define ROT(x, y) (SDL_FPoint){px + ((x) * c - (y) * sn) * s, py + ((x) * sn + (y) * c) * s}
  SDL_FPoint cabo[4] = {ROT(-8, 0), ROT(8, 0), ROT(6, 230), ROT(-6, 230)};
  ds_poligono(r, cabo, 4, (SDL_Color){92, 60, 36, 255});
  SDL_FPoint cabeca[4] = {ROT(-70, 214), ROT(70, 214), ROT(70, 268), ROT(-70, 268)};
  ds_poligono(r, cabeca, 4, (SDL_Color){58, 52, 48, 255});
  ds_polilinha(r, cabeca, 4, 2, cor_alfa(COR_BRONZE, 0.8f), true);
#undef ROT
}

static void desenhar(App *a) {
  SDL_Renderer *r = a->r;
  float tx = a->tremor > 0.2f ? sinf(a->t * 90) * a->tremor : 0;
  ds_fundo(r, a->t, 1.1f + g_flash * 0.8f);
  particulas_desenhar(r, &a->brasas);

  /* o título */
  float ty = 86;
  ds_brilho(r, TELA_L / 2.0f + tx, ty + 90, 620, COR_BRASA, 0.20f + 0.06f * sinf(a->t * 1.3f) + g_flash * 0.15f);
  SDL_Color titulo = cor_mistura(COR_OURO, COR_BRASA_VIVA, 0.25f + 0.1f * sinf(a->t * 0.8f));
  texto_espacado(r, F_TITULO_X, TELA_L / 2.0f + 5 + tx, ty + 7, (SDL_Color){0, 0, 0, 160}, ALINHA_CENTRO, 22,
                 "HEFESTO");
  texto_espacado(r, F_TITULO_X, TELA_L / 2.0f + tx, ty, titulo, ALINHA_CENTRO, 22, "HEFESTO");
  float lw = texto_largura_espacado(F_TITULO_X, 22, "HEFESTO");
  ds_greca(r, TELA_L / 2 - lw / 2, ty + 186, lw, 26, 2.5f, cor_alfa(COR_BRONZE, 0.9f));
  texto_espacado(r, F_TITULO_P, TELA_L / 2.0f, ty + 226, COR_BRONZE_CLARO, ALINHA_CENTRO, 10,
                 "TECH DEMO · A FORJA");
  texto_al(r, F_MEDIA, TELA_L / 2.0f, ty + 300, COR_TEXTO, ALINHA_CENTRO,
           "Quatro controles, uma forja: cada sentido do DualSense, provado na sua mão.");

  /* a oficina, à esquerda */
  float bx = 600 + tx, by = 850;
  bigorna(r, bx, by, 1.0f);
  float calor = 0.75f + 0.25f * sinf(a->t * 2.1f) + g_flash;
  ds_brilho(r, bx + 40, by - 60, 190, COR_BRASA, 0.45f * calor);
  ds_ret_arred_grad(r, bx - 20, by - 70, 120, 24, 8, cor_clarear(COR_OURO, 0.3f * g_flash),
                    cor_mistura(COR_BRASA, COR_OURO, 0.4f + 0.3f * g_flash));
  ds_brilho(r, bx + 40, by - 58, 90, COR_OURO, 0.5f * calor);
  /* o martelo gira em torno do punho; a cabeça cai no lingote em 0,62 do ciclo */
  /* ergue devagar (a cabeça sobe por cima do punho) e desce de uma vez */
  float g = g_golpe, ang;
  if (g < 0.5f)
    ang = 1.25f * suave(g / 0.5f);
  else if (g < 0.62f)
    ang = 1.25f * (1 - powf((g - 0.5f) / 0.12f, 2.2f));
  else
    ang = 0.16f * sinf((g - 0.62f) / 0.38f * 3.14159f) * (1 - (g - 0.62f) / 0.38f);
  martelo(r, bx + 216, by - 250, ang + 0.82f, 1.0f);

  /* os dois caminhos, à direita */
  const char *rot[2] = {"Jogar", "Prova de Fogo"};
  const char *sub[2] = {"o Salão da Forja e as suas salas, do seu jeito",
                        "todas as salas, na ordem e com semente: o gauntlet"};
  float w = 640, h = 104, x = 1110, y0 = 520;
  for (int i = 0; i < 2; i++)
    wg_item_menu(r, x, y0 + i * 134, w, h, rot[i], sub[i], g_sel == i, sinf(a->t * 3), i == 0 ? IC_MARTELO : IC_CHAMA);

  int n = pads_conectados(a);
  const char *estado = n == 0   ? "Nenhum controle ainda: conecte um DualSense, no cabo ou no rádio."
                       : n == 1 ? "1 controle conectado."
                                : fmt("%d controles conectados.", n);
  texto_al(r, F_PEQUENA, x + w / 2, y0 + 268, COR_TEXTO_2, ALINHA_CENTRO, estado);
  texto_al(r, F_PEQUENA, TELA_L / 2.0f, 972, cor_alfa(COR_TEXTO_3, 0.95f), ALINHA_CENTRO,
           "Hefesto, o ferreiro dos deuses, forjou os próprios apoios. Esta forja é para quem joga do seu jeito.");
  Dica d[] = {{IC_CRUZ, "escolher"}, {IC_TRIANGULO, "diagnóstico"}, {IC_CIRCULO, "sair"}};
  wg_rodape(r, d, 3);
}

const Cena CENA_TITULO = {"título", entrar, sair, NULL, atualizar, desenhar};
