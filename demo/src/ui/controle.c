/* O DualSense desenhado. Ver controle.h. */
#include "controle.h"

#include "desenho.h"
#include "icones.h"
#include "tema.h"
#include "texto.h"

#include <math.h>

/* A silhueta num quadro de 160 x 100 unidades, sentido horário. */
static const SDL_FPoint CORPO[] = {
    {26, 14},  {42, 9},   {60, 7},   {80, 7},   {100, 7},  {118, 9},  {134, 14}, {147, 24},
    {154, 40}, {158, 58}, {158, 76}, {153, 90}, {144, 98}, {132, 99}, {122, 93}, {114, 82},
    {106, 70}, {94, 65},  {80, 64},  {66, 65},  {54, 70},  {46, 82},  {38, 93},  {28, 99},
    {16, 98},  {7, 90},   {2, 76},   {2, 58},   {6, 40},   {13, 24},
};
static const SDL_FPoint NUCLEO[] = {
    {24, 22},  {48, 15},  {112, 15}, {136, 22}, {145, 34}, {146, 50}, {138, 63}, {118, 69},
    {100, 64}, {80, 62},  {60, 64},  {42, 69},  {22, 63},  {14, 50},  {15, 34},
};
#define N_CORPO ((int)(sizeof(CORPO) / sizeof(CORPO[0])))
#define N_NUCLEO ((int)(sizeof(NUCLEO) / sizeof(NUCLEO[0])))

static const SDL_Color MARFIM = {214, 206, 194, 255};
static const SDL_Color MARFIM_SOMBRA = {160, 150, 138, 255};
static const SDL_Color GRAFITE = {27, 23, 20, 255};
static const SDL_Color GRAFITE_CLARO = {48, 42, 37, 255};

void controle_vista_do_pad(VistaControle *v, const Pad *p) {
  SDL_memset(v, 0, sizeof(*v));
  v->leds_jogador = -1;
  if (!p) {
    v->cor_jogador = COR_NEUTRO;
    return;
  }
  v->conectado = true;
  SDL_memcpy(v->botao, p->b, sizeof(v->botao));
  SDL_memcpy(v->ax, p->ax, sizeof(v->ax));
  v->dedo[0] = p->dedo[0];
  v->dedo[1] = p->dedo[1];
  v->cor_jogador = p->slot >= 0 ? COR_JOGADOR[p->slot] : COR_NEUTRO;
  v->luz = p->luz;
  v->tem_luz = p->luz.a > 0 || p->luz.r || p->luz.g || p->luz.b;
  v->leds_jogador = p->leds_jogador;
  v->led_mic = p->led_mic;
  v->rumble_forte = p->rumble_ate_ms ? p->rumble_baixo / 65535.0f : 0;
  v->rumble_fraco = p->rumble_ate_ms ? p->rumble_alto / 65535.0f : 0;
  v->l2 = p->modo_l2;
  v->r2 = p->modo_r2;
  v->mostrar_saidas = true;
}

typedef struct Quadro {
  float cx, cy, s;
} Quadro;

static SDL_FPoint P(const Quadro *q, float ux, float uy) {
  SDL_FPoint p = {q->cx + (ux - 80) * q->s, q->cy + (uy - 50) * q->s};
  return p;
}

static void gatilho(SDL_Renderer *r, const Quadro *q, float ux, float w, bool direito, float apertado,
                    bool l1_apertado, ForjaTriggerMode modo, SDL_Color cj, float t) {
  float s = q->s;
  /* L2/R2: uma aba atrás, que se enche de cima para baixo com o aperto */
  SDL_FPoint a = P(q, ux, -9);
  float gw = w * s, gh = 12 * s;
  ds_ret_arred(r, a.x, a.y, gw, gh, 5 * s, GRAFITE_CLARO);
  if (apertado > 0.02f) {
    float hh = gh * apertado;
    ds_ret_arred(r, a.x, a.y + gh - hh, gw, hh, 4 * s, cor_alfa(cj, 0.85f));
  }
  ds_contorno_arred(r, a.x, a.y, gw, gh, 5 * s, fmaxf(1, 0.7f * s), COR_BRONZE_ESCURO);
  /* o modo do gatilho, desenhado em cima da aba */
  if (modo != FORJA_TRIGGER_OFF) {
    SDL_Color c = modo == FORJA_TRIGGER_FEEDBACK ? COR_OURO : modo == FORJA_TRIGGER_WEAPON ? COR_BRASA : COR_OK;
    float mx = a.x + gw / 2, my = a.y - 6 * s;
    ds_brilho(r, mx, a.y + gh / 2, gw * 0.9f, c, 0.35f);
    if (modo == FORJA_TRIGGER_FEEDBACK) {
      /* uma mola */
      SDL_FPoint mola[9];
      for (int i = 0; i < 9; i++) {
        mola[i].x = mx - 12 * s + i * 3 * s;
        mola[i].y = my + (i % 2 ? -2.5f : 2.5f) * s;
      }
      ds_polilinha(r, mola, 9, fmaxf(1.5f, 0.9f * s), c, false);
    } else if (modo == FORJA_TRIGGER_WEAPON) {
      /* a parede com o clique */
      ds_linha(r, mx - 10 * s, my, mx + 10 * s, my, fmaxf(1.5f, 0.9f * s), cor_alfa(c, 0.5f));
      ds_ret(r, mx - 1.5f * s, my - 4 * s, 3 * s, 8 * s, c);
    } else {
      /* a onda da vibração */
      SDL_FPoint onda[13];
      for (int i = 0; i < 13; i++) {
        onda[i].x = mx - 12 * s + i * 2 * s;
        onda[i].y = my + sinf(i * 1.2f + t * 30) * 2.5f * s;
      }
      ds_polilinha(r, onda, 13, fmaxf(1.5f, 0.9f * s), c, false);
    }
  }
  /* L1/R1: a barra da frente */
  SDL_FPoint b = P(q, ux + (direito ? -1 : 1), 3);
  ds_ret_arred(r, b.x, b.y, (w - 2) * s, 6 * s, 3 * s, l1_apertado ? cj : GRAFITE_CLARO);
  ds_contorno_arred(r, b.x, b.y, (w - 2) * s, 6 * s, 3 * s, fmaxf(1, 0.6f * s), COR_BRONZE_ESCURO);
}

static void botao_face(SDL_Renderer *r, const Quadro *q, float ux, float uy, Icone ic, bool aceso,
                       SDL_Color cj) {
  SDL_FPoint c = P(q, ux, uy);
  float raio = 4.6f * q->s;
  if (aceso)
    ds_brilho(r, c.x, c.y, raio * 3, cj, 0.5f);
  ds_circulo(r, c.x, c.y, raio, aceso ? cor_escurecer(cj, 0.2f) : GRAFITE_CLARO);
  SDL_Color simb = aceso ? COR_TEXTO : icone_cor_natural(ic);
  float e = fmaxf(1.2f, 0.75f * q->s), k = raio * 0.45f;
  switch (ic) {
  case IC_CRUZ:
    ds_linha(r, c.x - k, c.y - k, c.x + k, c.y + k, e, simb);
    ds_linha(r, c.x - k, c.y + k, c.x + k, c.y - k, e, simb);
    break;
  case IC_CIRCULO:
    ds_anel(r, c.x, c.y, raio * 0.5f, e, simb);
    break;
  case IC_QUADRADO:
    ds_contorno_arred(r, c.x - k, c.y - k, 2 * k, 2 * k, 0.5f, e, simb);
    break;
  default: {
    SDL_FPoint p[3] = {{c.x, c.y - k * 1.15f}, {c.x + k * 1.1f, c.y + k * 0.75f}, {c.x - k * 1.1f, c.y + k * 0.75f}};
    ds_polilinha(r, p, 3, e, simb, true);
  }
  }
}

static void analogico(SDL_Renderer *r, const Quadro *q, float ux, float uy, float ax, float ay, bool clique,
                      SDL_Color cj) {
  SDL_FPoint base = P(q, ux, uy);
  float s = q->s;
  ds_circulo(r, base.x, base.y, 9.5f * s, (SDL_Color){14, 12, 10, 255});
  float dx = ax * 3.2f * s, dy = ay * 3.2f * s;
  ds_circulo_grad(r, base.x + dx, base.y + dy, 7.5f * s, GRAFITE_CLARO, GRAFITE);
  ds_anel(r, base.x + dx, base.y + dy, 7.5f * s, fmaxf(1, 0.8f * s), clique ? cj : (SDL_Color){70, 62, 55, 255});
  ds_circulo(r, base.x + dx, base.y + dy, 4.2f * s, (SDL_Color){36, 31, 27, 255});
  if (fabsf(ax) > 0.15f || fabsf(ay) > 0.15f || clique)
    ds_brilho(r, base.x + dx, base.y + dy, 12 * s, cj, 0.35f);
}

void controle_desenhar(SDL_Renderer *r, float cx, float cy, float largura, const VistaControle *v,
                       float t, bool reduzir) {
  Quadro q = {cx, cy, largura / 160.0f};
  float s = q.s;
  SDL_Color cj = v->cor_jogador;

  /* o tremor: o desenho do controle que vibra treme — só ele */
  float tremor = (v->rumble_forte * 1.0f + v->rumble_fraco * 0.6f) * (reduzir ? 0.25f : 1.0f);
  if (tremor > 0.01f) {
    q.cx += sinf(t * 83) * tremor * 2.2f * s + sinf(t * 131) * tremor * 1.1f * s;
    q.cy += cosf(t * 97) * tremor * 1.6f * s;
  }

  /* a sombra no chão */
  ds_brilho(r, q.cx, q.cy + 58 * s, 90 * s, (SDL_Color){0, 0, 0, 255}, 0.0f);

  SDL_FPoint corpo[N_CORPO * 6], nucleo[N_NUCLEO * 6];
  SDL_FPoint ctrl[N_CORPO > N_NUCLEO ? N_CORPO : N_NUCLEO];
  for (int i = 0; i < N_CORPO; i++)
    ctrl[i] = P(&q, CORPO[i].x, CORPO[i].y);
  int nc = ds_suavizar(ctrl, N_CORPO, 5, corpo);
  for (int i = 0; i < N_NUCLEO; i++)
    ctrl[i] = P(&q, NUCLEO[i].x, NUCLEO[i].y);
  int nn = ds_suavizar(ctrl, N_NUCLEO, 5, nucleo);

  /* gatilhos atrás do corpo */
  gatilho(r, &q, 14, 30, false, v->ax[SDL_GAMEPAD_AXIS_LEFT_TRIGGER], v->botao[SDL_GAMEPAD_BUTTON_LEFT_SHOULDER],
          v->l2, cj, t);
  gatilho(r, &q, 116, 30, true, v->ax[SDL_GAMEPAD_AXIS_RIGHT_TRIGGER],
          v->botao[SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER], v->r2, cj, t);

  SDL_Color casca = v->conectado ? MARFIM : cor_mistura(MARFIM, COR_CARVAO, 0.6f);
  ds_poligono(r, corpo, nc, casca);
  /* sombra da casca (metade de baixo) para dar volume */
  ds_polilinha(r, corpo, nc, fmaxf(2, 1.6f * s), cor_alfa(MARFIM_SOMBRA, 0.8f), true);
  ds_poligono(r, nucleo, nn, v->conectado ? GRAFITE : cor_mistura(GRAFITE, COR_CARVAO, 0.5f));
  ds_polilinha(r, nucleo, nn, fmaxf(1, 0.8f * s), (SDL_Color){62, 54, 47, 255}, true);

  /* o vibrar nos cabos: um brilho de brasa onde o motor está */
  if (v->mostrar_saidas && v->rumble_forte > 0.01f) {
    SDL_FPoint g = P(&q, 22, 82);
    ds_brilho(r, g.x, g.y, 34 * s, COR_BRASA, 0.45f * v->rumble_forte);
  }
  if (v->mostrar_saidas && v->rumble_fraco > 0.01f) {
    SDL_FPoint g = P(&q, 138, 82);
    ds_brilho(r, g.x, g.y, 30 * s, COR_BRASA_VIVA, 0.45f * v->rumble_fraco);
  }
  /* a háptica por áudio: pulsos frios nos cabos */
  if (v->mostrar_saidas && v->haptica_e > 0.01f) {
    SDL_FPoint g = P(&q, 22, 82);
    ds_anel(r, g.x, g.y, (10 + 14 * v->haptica_e) * s, 2 * s, cor_alfa(COR_OURO, v->haptica_e));
  }
  if (v->mostrar_saidas && v->haptica_d > 0.01f) {
    SDL_FPoint g = P(&q, 138, 82);
    ds_anel(r, g.x, g.y, (10 + 14 * v->haptica_d) * s, 2 * s, cor_alfa(COR_OURO, v->haptica_d));
  }

  /* touchpad */
  SDL_FPoint tp = P(&q, 51, 6);
  float tw = 58 * s, th = 30 * s;
  bool clique = v->botao[SDL_GAMEPAD_BUTTON_TOUCHPAD];
  ds_ret_arred_grad(r, tp.x, tp.y, tw, th, 6 * s, v->conectado ? (SDL_Color){226, 219, 208, 255} : casca,
                    v->conectado ? (SDL_Color){196, 188, 176, 255} : casca);
  ds_contorno_arred(r, tp.x, tp.y, tw, th, 6 * s, fmaxf(1, (clique ? 1.6f : 0.7f) * s),
                    clique ? cj : MARFIM_SOMBRA);
  for (int d = 0; d < 2; d++)
    if (v->dedo[d].baixo) {
      float fx = tp.x + v->dedo[d].x * tw, fy = tp.y + v->dedo[d].y * th;
      ds_brilho(r, fx, fy, 9 * s, cj, 0.8f);
      ds_circulo(r, fx, fy, 3 * s, cor_escurecer(cj, 0.1f));
      char n[2] = {(char)('1' + d), 0};
      if (s > 1.4f)
        texto_al(r, F_MINI, fx, fy - 5 * s - texto_altura(F_MINI), cj, ALINHA_CENTRO, n);
    }

  /* a lightbar: duas fendas ao lado do touchpad, na cor que foi mandada */
  if (v->mostrar_saidas) {
    SDL_Color lb = v->tem_luz ? v->luz : (SDL_Color){40, 36, 32, 255};
    for (int lado = 0; lado < 2; lado++) {
      SDL_FPoint a = P(&q, lado ? 110.5f : 48.5f, 9), b = P(&q, lado ? 112 : 47, 33);
      if (v->tem_luz)
        ds_brilho(r, (a.x + b.x) / 2, (a.y + b.y) / 2, 20 * s, lb, 0.8f);
      ds_linha(r, a.x, a.y, b.x, b.y, 2.4f * s, v->tem_luz ? cor_clarear(lb, 0.25f) : lb);
    }
  }

  /* os cinco LEDs de jogador */
  for (int i = 0; i < 5; i++) {
    SDL_FPoint c = P(&q, 72 + i * 4, 39.5f);
    bool aceso = v->mostrar_saidas && v->leds_jogador > 0 && ((v->leds_jogador >> i) & 1);
    if (aceso)
      ds_brilho(r, c.x, c.y, 5 * s, COR_TEXTO, 0.7f);
    ds_circulo(r, c.x, c.y, 1.1f * s, aceso ? COR_TEXTO : (SDL_Color){58, 52, 46, 255});
  }

  /* botão do microfone, com o LED */
  {
    SDL_FPoint c = P(&q, 80, 46);
    float luz = 0;
    if (v->mostrar_saidas && v->led_mic == 1)
      luz = 1;
    else if (v->mostrar_saidas && v->led_mic == 2)
      luz = 0.5f + 0.5f * sinf(t * 9);
    else if (v->mostrar_saidas && v->led_mic == 3)
      luz = 0.5f + 0.5f * sinf(t * 4.5f);
    bool apertado = v->botao[SDL_GAMEPAD_BUTTON_MISC1];
    if (luz > 0.05f)
      ds_brilho(r, c.x, c.y, 10 * s, COR_BRASA, 0.8f * luz);
    ds_ret_arred(r, c.x - 4.5f * s, c.y - 1.8f * s, 9 * s, 3.6f * s, 1.8f * s,
                 apertado ? cj : cor_mistura(GRAFITE_CLARO, COR_BRASA, luz));
  }
  /* PS */
  {
    SDL_FPoint c = P(&q, 80, 55);
    bool ap = v->botao[SDL_GAMEPAD_BUTTON_GUIDE];
    ds_circulo(r, c.x, c.y, 4 * s, ap ? cj : GRAFITE_CLARO);
    ds_anel(r, c.x, c.y, 4 * s, fmaxf(1, 0.6f * s), (SDL_Color){80, 70, 62, 255});
  }
  /* a grade do alto-falante */
  for (int i = 0; i < 5; i++)
    for (int j = 0; j < 2; j++) {
      SDL_FPoint c = P(&q, 75 + i * 2.5f, 60 + j * 2.2f);
      ds_circulo(r, c.x, c.y, 0.55f * s, (SDL_Color){12, 10, 9, 255});
    }
  if (v->mostrar_saidas && v->som > 0.01f) {
    SDL_FPoint c = P(&q, 80, 61);
    for (int k = 0; k < 3; k++) {
      float fase = fmodf(t * 1.6f + k / 3.0f, 1.0f);
      ds_anel(r, c.x, c.y, (6 + 22 * fase) * s, 1.4f * s, cor_alfa(COR_OURO, v->som * (1 - fase)));
    }
  }

  /* create / options */
  {
    SDL_FPoint c = P(&q, 46, 21);
    ds_ret_arred(r, c.x - 2 * s, c.y - 3.5f * s, 4 * s, 7 * s, 2 * s,
                 v->botao[SDL_GAMEPAD_BUTTON_BACK] ? cj : GRAFITE_CLARO);
    c = P(&q, 114, 21);
    ds_ret_arred(r, c.x - 2 * s, c.y - 3.5f * s, 4 * s, 7 * s, 2 * s,
                 v->botao[SDL_GAMEPAD_BUTTON_START] ? cj : GRAFITE_CLARO);
  }

  /* direcional */
  {
    SDL_FPoint c = P(&q, 30, 38);
    float b = 5.2f * s, L = 9.5f * s;
    struct {
      int botao;
      float x, y, w, h;
    } braco[4] = {
        {SDL_GAMEPAD_BUTTON_DPAD_UP, c.x - b / 2, c.y - L, b, L - b / 2},
        {SDL_GAMEPAD_BUTTON_DPAD_DOWN, c.x - b / 2, c.y + b / 2, b, L - b / 2},
        {SDL_GAMEPAD_BUTTON_DPAD_LEFT, c.x - L, c.y - b / 2, L - b / 2, b},
        {SDL_GAMEPAD_BUTTON_DPAD_RIGHT, c.x + b / 2, c.y - b / 2, L - b / 2, b},
    };
    for (int i = 0; i < 4; i++) {
      bool ap = v->botao[braco[i].botao];
      if (ap)
        ds_brilho(r, braco[i].x + braco[i].w / 2, braco[i].y + braco[i].h / 2, 8 * s, cj, 0.5f);
      ds_ret_arred(r, braco[i].x, braco[i].y, braco[i].w, braco[i].h, 1.5f * s, ap ? cj : GRAFITE_CLARO);
    }
  }

  /* os quatro da direita */
  botao_face(r, &q, 130, 29, IC_TRIANGULO, v->botao[SDL_GAMEPAD_BUTTON_NORTH], cj);
  botao_face(r, &q, 139, 38, IC_CIRCULO, v->botao[SDL_GAMEPAD_BUTTON_EAST], cj);
  botao_face(r, &q, 130, 47, IC_CRUZ, v->botao[SDL_GAMEPAD_BUTTON_SOUTH], cj);
  botao_face(r, &q, 121, 38, IC_QUADRADO, v->botao[SDL_GAMEPAD_BUTTON_WEST], cj);

  analogico(r, &q, 58, 53, v->ax[SDL_GAMEPAD_AXIS_LEFTX], v->ax[SDL_GAMEPAD_AXIS_LEFTY],
            v->botao[SDL_GAMEPAD_BUTTON_LEFT_STICK], cj);
  analogico(r, &q, 102, 53, v->ax[SDL_GAMEPAD_AXIS_RIGHTX], v->ax[SDL_GAMEPAD_AXIS_RIGHTY],
            v->botao[SDL_GAMEPAD_BUTTON_RIGHT_STICK], cj);
}
