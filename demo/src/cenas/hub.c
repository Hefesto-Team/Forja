/* O Salão da Forja — o hub (ADR-002). Os quatro autômatos andam pelo salão;
 * cada porta é uma sala, a bancada é o diagnóstico, o livro é o relatório, e a
 * fornalha acende a Prova de Fogo (o gauntlet). Perto do fogo, a lightbar de
 * quem chega esquenta. */
#include "../app.h"

#include "../nucleo/simulador.h"
#include "../salas/salas.h"
#include "../ui/automato.h"
#include "../ui/desenho.h"
#include "../ui/icones.h"
#include "../ui/tema.h"
#include "../ui/texto.h"
#include "../ui/widgets.h"
#include "pausa.h"

#include <math.h>

#define PISO_X0 150.0f
#define PISO_X1 1770.0f
#define PISO_Y0 262.0f
#define PISO_Y1 846.0f
#define FORNALHA_X 960.0f
#define FORNALHA_Y 552.0f
#define FORNALHA_R 104.0f
#define PERTO 96.0f

typedef enum TipoPonto { PONTO_SALA, PONTO_BANCADA, PONTO_LIVRO, PONTO_FORNALHA } TipoPonto;

typedef struct Ponto {
  TipoPonto tipo;
  int sala;
  float x, y;      /* onde o autômato fica para interagir */
  float px, py;    /* onde a porta é desenhada */
  bool em_cima;    /* porta na parede de cima (desenho) */
} Ponto;

static Ponto g_pontos[16];
static int g_n_pontos;
static Automato g_boneco[MAX_JOGADORES];
static float g_calor_luz[MAX_JOGADORES];
static float g_luz_enviada_em[MAX_JOGADORES];
static int g_perto[MAX_JOGADORES];
static float g_t;
static float g_robo_alvo_t;

/* ---------- as salas prontas ---------- */

const Cena *hub_cena_da_sala(int sala) { return salas_cena(sala); }
bool hub_sala_pronta(int sala) { return hub_cena_da_sala(sala) != NULL; }

void hub_abrir_sala(App *a, int sala) {
  const Cena *c = hub_cena_da_sala(sala);
  if (!c) {
    app_avisar(a, "A forja ainda não abriu esta porta");
    som_evento(&a->som, SOM_FALHA, 0.5f);
    return;
  }
  a->sala_atual = sala;
  Evento ev;
  ev_iniciar(&ev, &a->lt, "sala", 0);
  ev_str(&ev, "evento", "entrou");
  ev_str(&ev, "sala", catalogo_sala((Sala)sala)->chave);
  ev_bool(&ev, "gauntlet", a->gauntlet);
  ev_fim(&ev, &a->lt);
  reg_linha(&a->reg, "sala: %s%s", catalogo_sala((Sala)sala)->nome, a->gauntlet ? " (gauntlet)" : "");
  app_trocar_cena(a, c);
}

static int proxima_do_gauntlet(App *a) {
  while (a->gauntlet_passo < SALA_TOTAL && !hub_sala_pronta(a->gauntlet_passo))
    a->gauntlet_passo++;
  return a->gauntlet_passo < SALA_TOTAL ? a->gauntlet_passo : -1;
}

void hub_comecar_gauntlet(App *a) {
  a->gauntlet = true;
  a->gauntlet_passo = 0;
  reg_linha(&a->reg, "Prova de Fogo: começou (semente %llu)", a->semente);
  int s = proxima_do_gauntlet(a);
  if (s < 0) {
    a->gauntlet = false;
    rel_nota(&a->rel, "Prova de Fogo pedida, mas nenhuma sala está pronta nesta versão");
    app_relatorio_mudou(a);
    app_trocar_cena(a, &CENA_RELATORIO);
    return;
  }
  hub_abrir_sala(a, s);
}

void hub_voltar(App *a, bool concluida) {
  int sala = a->sala_atual;
  if (sala >= 0) {
    Evento ev;
    ev_iniciar(&ev, &a->lt, "sala", 0);
    ev_str(&ev, "evento", concluida ? "concluiu" : "abandonou");
    ev_str(&ev, "sala", catalogo_sala((Sala)sala)->chave);
    ev_fim(&ev, &a->lt);
  }
  a->sala_atual = -1;
  pads_silencio_todos(a);
  app_relatorio_mudou(a);
  if (a->gauntlet) {
    a->gauntlet_passo++;
    int s = proxima_do_gauntlet(a);
    if (s >= 0) {
      hub_abrir_sala(a, s);
      return;
    }
    a->gauntlet = false;
    reg_linha(&a->reg, "Prova de Fogo: terminou");
    app_trocar_cena(a, &CENA_RELATORIO);
    return;
  }
  app_trocar_cena(a, &CENA_HUB);
}

/* ---------- o salão ---------- */

static void montar_pontos(void) {
  g_n_pontos = 0;
  static const int cima[4] = {SALA_CENTELHA, SALA_VIGA, SALA_MOLDE, SALA_CERCO};
  static const int baixo[4] = {SALA_GALERIA, SALA_CRIPTA, SALA_CAMINHOS, SALA_CANTO};
  static const float xs[4] = {390, 760, 1160, 1530};
  for (int i = 0; i < 4; i++) {
    g_pontos[g_n_pontos++] = (Ponto){PONTO_SALA, cima[i], xs[i], PISO_Y0 + 40, xs[i], PISO_Y0 - 30, true};
    g_pontos[g_n_pontos++] = (Ponto){PONTO_SALA, baixo[i], xs[i], PISO_Y1 - 20, xs[i], PISO_Y1 + 30, false};
  }
  g_pontos[g_n_pontos++] = (Ponto){PONTO_SALA, SALA_PROVA, PISO_X1 - 50, 552, PISO_X1 + 40, 552, false};
  g_pontos[g_n_pontos++] = (Ponto){PONTO_BANCADA, -1, PISO_X0 + 70, 420, PISO_X0 - 10, 420, false};
  g_pontos[g_n_pontos++] = (Ponto){PONTO_LIVRO, -1, PISO_X0 + 70, 690, PISO_X0 - 10, 690, false};
  g_pontos[g_n_pontos++] = (Ponto){PONTO_FORNALHA, -1, FORNALHA_X, FORNALHA_Y + FORNALHA_R + 40, FORNALHA_X, FORNALHA_Y, false};
}

static void entrar(App *a) {
  g_t = 0;
  montar_pontos();
  a->brasas.taxa = a->cfg.reduzir_movimento ? 4 : 18;
  som_ambiente(&a->som, true, true);
  for (int s = 0; s < MAX_JOGADORES; s++) {
    automato_iniciar(&g_boneco[s], FORNALHA_X - 240 + s * 160, FORNALHA_Y + 230);
    g_calor_luz[s] = 0;
    g_luz_enviada_em[s] = -1;
    g_perto[s] = -1;
  }
  g_robo_alvo_t = 0;
}

static void sair(App *a) { pads_silencio_todos(a); }

static void empurrar_da_fornalha(Automato *b) {
  float dx = b->x - FORNALHA_X, dy = b->y - FORNALHA_Y;
  float d = sqrtf(dx * dx + dy * dy);
  float min = FORNALHA_R + 28;
  if (d < min && d > 0.01f) {
    b->x = FORNALHA_X + dx / d * min;
    b->y = FORNALHA_Y + dy / d * min;
  }
}

static void interagir(App *a, int slot, const Ponto *pt) {
  switch (pt->tipo) {
  case PONTO_SALA:
    if (hub_sala_pronta(pt->sala)) {
      som_evento(&a->som, SOM_CONFIRMA, 0.7f);
      hub_abrir_sala(a, pt->sala);
    } else {
      som_evento(&a->som, SOM_FALHA, 0.4f);
      app_avisar(a, "%s: a forja ainda não abriu esta porta", catalogo_sala((Sala)pt->sala)->nome);
    }
    break;
  case PONTO_BANCADA:
    som_evento(&a->som, SOM_CONFIRMA, 0.6f);
    app_trocar_cena(a, &CENA_DIAGNOSTICO);
    break;
  case PONTO_LIVRO:
    som_evento(&a->som, SOM_CONFIRMA, 0.6f);
    app_trocar_cena(a, &CENA_RELATORIO);
    break;
  case PONTO_FORNALHA:
    som_evento(&a->som, SOM_MARTELO, 0.6f);
    reg_linha(&a->reg, "%s acendeu a Prova de Fogo", pads_rotulo_slot(slot));
    hub_comecar_gauntlet(a);
    break;
  }
}

static void atualizar(App *a, float dt) {
  g_t += dt;
  PausaAcao pa = pausa_atualizar(a);
  if (pausa_aberta() || pa != PAUSA_NADA) {
    switch (pa) {
    case PAUSA_DIAGNOSTICO:
      app_trocar_cena(a, &CENA_DIAGNOSTICO);
      break;
    case PAUSA_RELATORIO:
      app_trocar_cena(a, &CENA_RELATORIO);
      break;
    case PAUSA_TITULO:
      app_trocar_cena(a, &CENA_TITULO);
      break;
    case PAUSA_SAIR:
      a->rodando = false;
      break;
    default:
      break;
    }
    return;
  }
  SDL_FRect limites = {PISO_X0, PISO_Y0, PISO_X1 - PISO_X0, PISO_Y1 - PISO_Y0};
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Automato *b = &g_boneco[s];
    Pad *p = pads_do_slot(a, s);
    b->conectado = p != NULL;
    if (!a->pads.slot[s].ocupado)
      continue;
    if (!p) {
      automato_andar(b, 0, 0, 0, limites, dt);
      continue;
    }
    float ax = p->ax[SDL_GAMEPAD_AXIS_LEFTX], ay = p->ax[SDL_GAMEPAD_AXIS_LEFTY];
    if (p->b[SDL_GAMEPAD_BUTTON_DPAD_LEFT])
      ax = -1;
    if (p->b[SDL_GAMEPAD_BUTTON_DPAD_RIGHT])
      ax = 1;
    if (p->b[SDL_GAMEPAD_BUTTON_DPAD_UP])
      ay = -1;
    if (p->b[SDL_GAMEPAD_BUTTON_DPAD_DOWN])
      ay = 1;
    automato_andar(b, ax, ay, 430, limites, dt);
    empurrar_da_fornalha(b);

    /* o ponto mais perto, se algum */
    g_perto[s] = -1;
    float melhor = PERTO;
    for (int i = 0; i < g_n_pontos; i++) {
      float dx = b->x - g_pontos[i].x, dy = b->y - g_pontos[i].y;
      float d = sqrtf(dx * dx + dy * dy);
      if (d < melhor) {
        melhor = d;
        g_perto[s] = i;
      }
    }
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_START)) {
      pausa_abrir(a, false, s);
      return;
    }
    if (g_perto[s] >= 0 && pad_apertou(p, SDL_GAMEPAD_BUTTON_SOUTH)) {
      interagir(a, s, &g_pontos[g_perto[s]]);
      return;
    }

    /* o fogo esquenta a lightbar de quem chega perto (como a luz de uma tocha
     * num jogo); a escrita só sai quando a cor muda de verdade */
    float dx = b->x - FORNALHA_X, dy = b->y - FORNALHA_Y;
    float calor = limitar(1 - (sqrtf(dx * dx + dy * dy) - FORNALHA_R) / 260.0f, 0, 1);
    calor = roundf(calor * 5) / 5;
    if (p->cap_rgb && calor != g_calor_luz[s] && g_t - g_luz_enviada_em[s] > 0.12f) {
      g_calor_luz[s] = calor;
      g_luz_enviada_em[s] = g_t;
      pad_luz(a, p, cor_mistura(COR_LIGHTBAR[s], (SDL_Color){255, 90, 0, 255}, calor * 0.75f));
    }
  }
  if (a->nav.quem < 0 && !simulador_ativo()) {
    if (a->nav.opcoes)
      pausa_abrir(a, false, -1);
    else if (a->nav.volta)
      app_trocar_cena(a, &CENA_TITULO);
  }

  /* o robô passeia até a primeira porta aberta e entra */
  if (robo_ativo()) {
    g_robo_alvo_t += dt;
    int alvo = -1;
    for (int i = 0; i < g_n_pontos; i++)
      if (g_pontos[i].tipo == PONTO_SALA && hub_sala_pronta(g_pontos[i].sala)) {
        alvo = i;
        break;
      }
    for (int s = 0; s < MAX_JOGADORES; s++) {
      Pad *p = pads_do_slot(a, s);
      if (!p)
        continue;
      int idx = (int)(p - a->pads.pad);
      float tx = alvo >= 0 ? g_pontos[alvo].x : FORNALHA_X + cosf(g_t * 0.5f + s) * 300;
      float ty = alvo >= 0 ? g_pontos[alvo].y : FORNALHA_Y + sinf(g_t * 0.5f + s) * 250;
      float dx = tx - g_boneco[s].x, dy = ty - g_boneco[s].y;
      float d = sqrtf(dx * dx + dy * dy);
      if (d > 30) {
        robo_eixo(a, idx, SDL_GAMEPAD_AXIS_LEFTX, dx / d, 0.1f);
        robo_eixo(a, idx, SDL_GAMEPAD_AXIS_LEFTY, dy / d, 0.1f);
      } else if (alvo >= 0 && s == 0 && g_robo_alvo_t > 1.0f) {
        robo_apertar(a, idx, SDL_GAMEPAD_BUTTON_SOUTH, 0.1f);
        g_robo_alvo_t = 0;
      }
    }
  }
}

/* ---------- desenho ---------- */

static void piso(SDL_Renderer *r, float t) {
  /* lajes de pedra, com placas de metal num anel em volta da fornalha */
  for (float y = PISO_Y0 - 40; y < PISO_Y1 + 40; y += 80)
    for (float x = PISO_X0 - 40; x < PISO_X1 + 40; x += 80) {
      int ix = (int)(x / 80), iy = (int)(y / 80);
      float dx = x + 40 - FORNALHA_X, dy = y + 40 - FORNALHA_Y;
      float d = sqrtf(dx * dx + dy * dy);
      bool metal = d > FORNALHA_R + 40 && d < FORNALHA_R + 200;
      SDL_Color c = metal ? (SDL_Color){50, 44, 40, 255} : ((ix + iy) % 2 ? (SDL_Color){37, 29, 24, 255} : (SDL_Color){40, 31, 25, 255});
      float calor = limitar(1 - d / 760, 0, 1);
      c = cor_mistura(c, (SDL_Color){96, 46, 18, 255}, calor * 0.4f);
      ds_ret(r, x, y, 80, 80, cor_escurecer(c, 0.25f));
      ds_ret(r, x + 1, y + 1, 78, 78, c);
      if (metal) {
        ds_circulo(r, x + 10, y + 10, 2.5f, (SDL_Color){80, 70, 62, 255});
        ds_circulo(r, x + 70, y + 70, 2.5f, (SDL_Color){80, 70, 62, 255});
      }
    }
  (void)t;
  /* as paredes */
  SDL_Color pedra = {30, 23, 19, 255};
  ds_ret(r, 0, 0, TELA_L, PISO_Y0 - 70, pedra);
  ds_ret(r, 0, PISO_Y1 + 70, TELA_L, TELA_A - PISO_Y1 - 70, pedra);
  ds_ret(r, 0, 0, PISO_X0 - 60, TELA_A, pedra);
  ds_ret(r, PISO_X1 + 60, 0, TELA_L - PISO_X1 - 60, TELA_A, pedra);
  ds_greca(r, PISO_X0 - 60, PISO_Y0 - 70, PISO_X1 - PISO_X0 + 120, 22, 2, cor_alfa(COR_BRONZE, 0.7f));
  ds_greca(r, PISO_X0 - 60, PISO_Y1 + 48, PISO_X1 - PISO_X0 + 120, 22, 2, cor_alfa(COR_BRONZE, 0.7f));
}

static void fornalha(SDL_Renderer *r, float t, bool perto) {
  float pulso = 0.8f + 0.2f * sinf(t * 2.3f) + 0.08f * sinf(t * 7.1f);
  ds_brilho(r, FORNALHA_X, FORNALHA_Y, 520, COR_BRASA, 0.35f * pulso);
  ds_circulo_grad(r, FORNALHA_X, FORNALHA_Y, FORNALHA_R, (SDL_Color){70, 50, 40, 255}, (SDL_Color){36, 28, 24, 255});
  ds_anel(r, FORNALHA_X, FORNALHA_Y, FORNALHA_R, 6, COR_BRONZE_ESCURO);
  ds_circulo_grad(r, FORNALHA_X, FORNALHA_Y, FORNALHA_R * 0.7f, cor_clarear(COR_BRASA_VIVA, 0.2f * pulso),
                  (SDL_Color){120, 30, 8, 255});
  for (int i = 0; i < 9; i++) {
    float a = i * 0.698f + t * 0.4f;
    float h = 30 + 18 * sinf(t * 6 + i * 1.7f);
    float fx = FORNALHA_X + cosf(a) * 36, fy = FORNALHA_Y + sinf(a) * 26;
    SDL_FPoint p[3] = {{fx - 10, fy + 6}, {fx + 10, fy + 6}, {fx + sinf(t * 5 + i) * 6, fy - h}};
    ds_poligono(r, p, 3, cor_alfa(COR_OURO, 0.8f));
  }
  ds_brilho(r, FORNALHA_X, FORNALHA_Y - 10, 160, COR_OURO, 0.5f * pulso);
  if (perto)
    ds_anel(r, FORNALHA_X, FORNALHA_Y, FORNALHA_R + 16 + 4 * sinf(t * 4), 3, COR_OURO);
}

static void porta(App *a, const Ponto *pt, bool perto) {
  SDL_Renderer *r = a->r;
  bool aberta = pt->tipo != PONTO_SALA || hub_sala_pronta(pt->sala);
  float w = pt->tipo == PONTO_SALA && pt->sala == SALA_PROVA ? 150 : 150, h = 110;
  float x, y;
  bool vertical = pt->tipo != PONTO_SALA || pt->sala == SALA_PROVA;
  if (vertical) {
    x = pt->px - 40;
    y = pt->py - w / 2;
    SDL_Color moldura = aberta ? COR_BRONZE : cor_alfa(COR_BRONZE_ESCURO, 0.6f);
    if (aberta)
      ds_brilho(r, pt->px, pt->py, 110, perto ? COR_OURO : COR_BRASA, perto ? 0.5f : 0.2f);
    ds_ret_arred(r, x, y, 80, w, 10, (SDL_Color){20, 15, 12, 255});
    ds_contorno_arred(r, x, y, 80, w, 10, 3, perto ? COR_OURO : moldura);
  } else {
    x = pt->px - w / 2;
    y = pt->em_cima ? pt->py - h / 2 - 20 : pt->py - h / 2 + 20;
    SDL_Color moldura = aberta ? COR_BRONZE : cor_alfa(COR_BRONZE_ESCURO, 0.6f);
    if (aberta)
      ds_brilho(r, pt->px, pt->py, 120, perto ? COR_OURO : COR_BRASA, perto ? 0.5f : 0.22f);
    ds_ret_arred(r, x, y, w, h, 16, (SDL_Color){20, 15, 12, 255});
    ds_contorno_arred(r, x, y, w, h, 16, 3, perto ? COR_OURO : moldura);
  }
  /* o que a porta é */
  Icone ic = IC_TOTAL;
  const char *nome = "";
  switch (pt->tipo) {
  case PONTO_BANCADA:
    ic = IC_MARTELO;
    nome = "Bancada";
    break;
  case PONTO_LIVRO:
    ic = IC_NAO_MEDIDO;
    nome = "Livro";
    break;
  case PONTO_FORNALHA:
    return;
  case PONTO_SALA: {
    static const Icone ICONES[SALA_TOTAL] = {IC_CRUZ,  IC_GIRO,      IC_TOQUE,        IC_VIBRACAO, IC_GATILHO,
                                             IC_MICROFONE, IC_VIBRACAO, IC_ALTO_FALANTE, IC_MARTELO};
    ic = ICONES[pt->sala];
    nome = catalogo_sala((Sala)pt->sala)->nome;
    break;
  }
  }
  float cx = vertical ? x + 40 : x + w / 2, cy = vertical ? y + w / 2 : y + h / 2;
  SDL_Color cor_ic = aberta ? (perto ? COR_OURO : COR_BRONZE_CLARO) : COR_TEXTO_3;
  if (pt->tipo == PONTO_LIVRO) {
    ds_ret_arred(r, cx - 20, cy - 26, 40, 50, 4, cor_ic);
    ds_linha(r, cx - 12, cy - 12, cx + 12, cy - 12, 2, COR_CARVAO);
    ds_linha(r, cx - 12, cy - 2, cx + 12, cy - 2, 2, COR_CARVAO);
    ds_linha(r, cx - 12, cy + 8, cx + 6, cy + 8, 2, COR_CARVAO);
  } else if (!aberta) {
    icone(r, IC_CADEADO, cx, cy - 8, 50, cor_ic, 0);
  } else {
    icone(r, ic, cx, cy - 8, 54, cor_ic, 0);
  }
  float ly = vertical ? y + w + 6 : (pt->em_cima ? y + h + 6 : y - 36);
  texto_al(r, F_PEQUENA_N, cx, ly, aberta ? COR_TEXTO : COR_TEXTO_3, ALINHA_CENTRO, nome);
}

static void desenhar(App *a) {
  SDL_Renderer *r = a->r;
  ds_ret(r, 0, 0, TELA_L, TELA_A, COR_FUNDO_0);
  piso(r, a->t);
  bool alguem_na_fornalha = false;
  for (int s = 0; s < MAX_JOGADORES; s++)
    if (g_perto[s] >= 0 && g_pontos[g_perto[s]].tipo == PONTO_FORNALHA)
      alguem_na_fornalha = true;
  for (int i = 0; i < g_n_pontos; i++) {
    bool perto = false;
    for (int s = 0; s < MAX_JOGADORES; s++)
      if (g_perto[s] == i && pads_do_slot(a, s))
        perto = true;
    porta(a, &g_pontos[i], perto);
  }
  fornalha(r, a->t, alguem_na_fornalha);
  particulas_desenhar(r, &a->brasas);

  /* os autômatos, de trás para a frente */
  int ordem[MAX_JOGADORES] = {0, 1, 2, 3};
  for (int i = 0; i < MAX_JOGADORES; i++)
    for (int j = i + 1; j < MAX_JOGADORES; j++)
      if (g_boneco[ordem[j]].y < g_boneco[ordem[i]].y) {
        int t = ordem[i];
        ordem[i] = ordem[j];
        ordem[j] = t;
      }
  for (int k = 0; k < MAX_JOGADORES; k++) {
    int s = ordem[k];
    if (!a->pads.slot[s].ocupado)
      continue;
    automato_desenhar(r, &g_boneco[s], COR_JOGADOR[s], 1.0f, a->t, s);
  }
  /* o convite de quem está perto de algo */
  for (int s = 0; s < MAX_JOGADORES; s++) {
    if (g_perto[s] < 0 || !pads_do_slot(a, s))
      continue;
    const Ponto *pt = &g_pontos[g_perto[s]];
    const char *txt;
    if (pt->tipo == PONTO_SALA)
      txt = hub_sala_pronta(pt->sala) ? fmt("{X} %s — %s", catalogo_sala((Sala)pt->sala)->nome,
                                           catalogo_sala((Sala)pt->sala)->padrao)
                                      : fmt("%s — fechada nesta versão", catalogo_sala((Sala)pt->sala)->nome);
    else if (pt->tipo == PONTO_BANCADA)
      txt = "{X} a bancada: o diagnóstico ao vivo";
    else if (pt->tipo == PONTO_LIVRO)
      txt = "{X} o livro: o relatório da sessão";
    else
      txt = "{X} Prova de Fogo: todas as salas, na ordem";
    float bx = g_boneco[s].x, by = g_boneco[s].y - 150;
    float w = wg_texto_rico_largura(F_PEQUENA_N, txt) + 30;
    bx = limitar(bx, w / 2 + 10, TELA_L - w / 2 - 10);
    ds_ret_arred(r, bx - w / 2, by - 6, w, 42, 10, cor_alfa(COR_CARVAO, 0.92f));
    ds_contorno_arred(r, bx - w / 2, by - 6, w, 42, 10, 2, COR_JOGADOR[s]);
    wg_texto_rico(r, F_PEQUENA_N, bx, by, COR_TEXTO, ALINHA_CENTRO, txt);
  }
  texto_espacado(r, F_TITULO_P, TELA_L / 2.0f, 34, COR_OURO, ALINHA_CENTRO, 8, "O SALÃO DA FORJA");
  texto_al(r, F_PEQUENA, TELA_L / 2.0f, 92, COR_TEXTO_2, ALINHA_CENTRO,
           "Ande até uma porta. Cada sala é um jeito que os jogos usam o controle.");
  if (pads_jogadores(a) == 0)
    wg_texto_rico(r, F_TEXTO, TELA_L / 2.0f, TELA_A / 2.0f + 180, COR_AVISO, ALINHA_CENTRO,
                  "Ninguém na mesa: volte ao título com {O} e entre pelo lobby.");
  pausa_desenhar(a);
  if (!pausa_aberta()) {
    Dica d[] = {{IC_ANALOGICO_E, "andar"}, {IC_CRUZ, "entrar"}, {IC_OPTIONS, "pausa"}};
    wg_rodape(r, d, 3);
  }
}

const Cena CENA_HUB = {"hub", entrar, sair, NULL, atualizar, desenhar};
