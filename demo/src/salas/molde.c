/* O Molde — desenhar e moldar no touchpad (ADR-002).
 *
 * Os jogos usam o touchpad do DualSense de três jeitos, e a sala pede os três,
 * em sequência, para cada jogador:
 *
 *   1. traçar: uma letra grega aparece no molde, ponto por ponto; o dedo
 *      passa por eles na ordem (o gesto de desenhar um símbolo);
 *   2. abrir: dois dedos no touchpad, afastar até o molde abrir e juntar até
 *      ele fechar (o gesto de pinça do mapa);
 *   3. carimbar: o metal esquenta e esfria; o CLIQUE do touchpad carimba
 *      quando ele brilha (o touchpad como botão).
 *
 * O que a sala mede (medidas.h): quantos dedos chegaram ao mesmo tempo, que
 * pedaço do touchpad os toques cobriram (um recorte ou uma escala errada no
 * caminho aparece aqui), a abertura entre os dedos, e se o clique chegou.
 *
 * Sem touchpad (um pad Xbox por uinput), a sala não tem o que pedir: o
 * veredito é NÃO MEDIDO, com o porquê. */
#include "sala_base.h"

#include "../cenas/pausa.h"
#include "../nucleo/simulador.h"
#include "../ui/desenho.h"
#include "../ui/icones.h"
#include "../ui/tema.h"
#include "../ui/texto.h"
#include "../ui/widgets.h"

#include <math.h>
#include <stdio.h>

#define PI_F 3.14159265f
#define DURACAO 90.0f
#define RAIO_PONTO 0.07f /* em larguras do touchpad */
#define CARIMBOS 3
#define MAX_RASTRO 40

typedef enum Passo { PASSO_TRACAR = 0, PASSO_ABRIR, PASSO_CARIMBAR, PASSO_PRONTO } Passo;

typedef struct Letra {
  const char *nome;
  int n;
  float x[6], y[6];
} Letra;

/* As letras: cada uma leva o dedo aos quatro cantos do touchpad. */
static const Letra LETRAS[] = {
    {"zeta", 4, {0.10f, 0.90f, 0.10f, 0.90f}, {0.14f, 0.14f, 0.86f, 0.86f}},
    {"lambda", 3, {0.08f, 0.50f, 0.92f}, {0.88f, 0.12f, 0.88f}},
    {"sigma", 5, {0.88f, 0.12f, 0.50f, 0.12f, 0.88f}, {0.14f, 0.14f, 0.50f, 0.86f, 0.86f}},
    {"eta, o H de Hefesto", 6, {0.12f, 0.12f, 0.12f, 0.88f, 0.88f, 0.88f}, {0.12f, 0.88f, 0.50f, 0.50f, 0.12f, 0.88f}},
    {"mi", 5, {0.10f, 0.10f, 0.50f, 0.90f, 0.90f}, {0.86f, 0.14f, 0.62f, 0.14f, 0.86f}},
};
#define N_LETRAS ((int)(sizeof(LETRAS) / sizeof(LETRAS[0])))

typedef struct Jogador {
  Passo passo;
  float t_passo;
  const Letra *letra;
  int ponto;           /* o próximo ponto da letra */
  bool aberto;         /* o molde já abriu (falta fechar) */
  float abertura;      /* a distância atual entre os dedos */
  int carimbos, fora;
  float calor_fase;
  float pancada;
  float rastro_x[MAX_RASTRO], rastro_y[MAX_RASTRO];
  int n_rastro;
  bool sem_touchpad;
  MedToque med;
  bool marcou_toque, marcou_dois, marcou_clique;
  /* o robô */
  float robo_x, robo_y, robo_s, robo_espera;
  int robo_ponto; /* o robô vai até o centro de cada ponto, como gente que traça inteiro */
} Jogador;

static const Feature FEATS[] = {F_TOUCH_DOIS_DEDOS, F_TOUCH_CLIQUE};

static SalaBase g_b;
static Jogador g_j[MAX_JOGADORES];
static SDL_FRect g_faixa[MAX_JOGADORES];
static int g_slot_faixa[MAX_JOGADORES], g_n_faixas;
static const SDL_FRect AREA = {40, 140, TELA_L - 80, TELA_A - 140 - 96};

static SDL_FRect molde(SDL_FRect f) {
  float mw = fminf(f.w - 220, (f.h - 150) * 2);
  float mh = mw / 2;
  return (SDL_FRect){f.x + (f.w - mw) / 2, f.y + 72, mw, mh};
}

static void entrar(App *a) {
  sb_entrar(a, &g_b, SALA_MOLDE, FEATS, 2, DURACAO);
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Jogador *j = &g_j[s];
    SDL_memset(j, 0, sizeof(*j));
    j->letra = &LETRAS[sorteio_entre(&g_b.sorteio, 0, N_LETRAS - 1)];
    j->calor_fase = sorteio_real(&g_b.sorteio) * 2 * PI_F;
    med_toque_iniciar(&j->med);
    j->robo_x = 0.5f;
    j->robo_y = 0.5f;
    j->robo_espera = -1;
  }
}

static void sair(App *a) { pads_silencio_todos(a); }

static float calor(const Jogador *j) { return 0.5f + 0.5f * sinf(j->t_passo * 2.3f + j->calor_fase); }
static bool no_ponto(const Jogador *j) { return calor(j) > 0.8f; }

static void novo_passo(App *a, int s, Jogador *j, Passo p, SDL_FRect f) {
  j->passo = p;
  j->t_passo = 0;
  if (p == PASSO_ABRIR)
    j->med.pediu_dois = true;
  if (p == PASSO_CARIMBAR)
    j->med.pediu_clique = true;
  if (p == PASSO_PRONTO) {
    g_b.acabou[s] = true;
    som_evento_pan(&a->som, SOM_SUCESSO, 0.6f, sb_pan(f));
    SDL_FRect m = molde(f);
    particulas_brasas(&a->brasas, m.x + m.w / 2, m.y + m.h / 2, 40, COR_OURO);
  } else {
    som_evento_pan(&a->som, SOM_CONFIRMA, 0.5f, sb_pan(f));
  }
}

static void medir(App *a, int s, Jogador *j, Pad *p) {
  bool baixo[2] = {p->dedo[0].baixo, p->dedo[1].baixo};
  float x[2] = {p->dedo[0].x, p->dedo[1].x}, y[2] = {p->dedo[0].y, p->dedo[1].y};
  med_toque_amostra(&j->med, baixo, x, y);
  if (pad_apertou(p, SDL_GAMEPAD_BUTTON_TOUCHPAD)) {
    med_toque_clique(&j->med);
    if (!j->marcou_clique) {
      j->marcou_clique = true;
      sb_marco(a, s, "toque", "o clique do touchpad chegou");
    }
  }
  if ((baixo[0] || baixo[1]) && !j->marcou_toque) {
    j->marcou_toque = true;
    sb_marco(a, s, "toque", "o primeiro dedo chegou");
  }
  if (baixo[0] && baixo[1] && !j->marcou_dois) {
    j->marcou_dois = true;
    sb_marco(a, s, "toque", "dois dedos ao mesmo tempo");
  }
}

static void jogar(App *a, int s, Jogador *j, Pad *p, SDL_FRect f, float dt) {
  j->t_passo += dt;
  j->pancada = aproximar(j->pancada, 0, 5, dt);
  SDL_FRect m = molde(f);
  const Dedo *d = p->dedo;
  /* o rastro do dedo que desenha */
  int qual = d[0].baixo ? 0 : d[1].baixo ? 1 : -1;
  if (qual >= 0 && j->passo == PASSO_TRACAR) {
    if (j->n_rastro < MAX_RASTRO) {
      j->n_rastro++;
    }
    for (int k = j->n_rastro - 1; k > 0; k--) {
      j->rastro_x[k] = j->rastro_x[k - 1];
      j->rastro_y[k] = j->rastro_y[k - 1];
    }
    j->rastro_x[0] = d[qual].x;
    j->rastro_y[0] = d[qual].y;
  } else if (j->n_rastro > 0) {
    j->n_rastro--;
  }

  switch (j->passo) {
  case PASSO_TRACAR: {
    const Letra *l = j->letra;
    for (int k = 0; k < 2; k++) {
      if (!d[k].baixo || j->ponto >= l->n)
        continue;
      if (med_toque_distancia(d[k].x, d[k].y, l->x[j->ponto], l->y[j->ponto]) < RAIO_PONTO) {
        particulas_faiscas(&a->brasas, m.x + l->x[j->ponto] * m.w, m.y + l->y[j->ponto] * m.h, 14, COR_OURO, 0.6f);
        som_evento_pan(&a->som, SOM_TICK, 0.5f, sb_pan(f));
        j->ponto++;
      }
    }
    if (j->ponto >= l->n) {
      j->med.tracou = true;
      sb_pontos(a, &g_b, s, 300 + (int)fmaxf(0, 200 - j->t_passo * 12));
      novo_passo(a, s, j, PASSO_ABRIR, f);
    }
    break;
  }
  case PASSO_ABRIR:
    j->abertura = d[0].baixo && d[1].baixo ? med_toque_distancia(d[0].x, d[0].y, d[1].x, d[1].y) : 0;
    if (!j->aberto && j->abertura >= 0.45f) {
      j->aberto = true;
      som_evento_pan(&a->som, SOM_SOPRO, 0.6f, sb_pan(f));
    } else if (j->aberto && d[0].baixo && d[1].baixo && j->abertura <= 0.15f) {
      sb_pontos(a, &g_b, s, 250);
      novo_passo(a, s, j, PASSO_CARIMBAR, f);
    }
    break;
  case PASSO_CARIMBAR:
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_TOUCHPAD)) {
      j->pancada = 1;
      if (no_ponto(j)) {
        j->carimbos++;
        sb_pontos(a, &g_b, s, 120);
        particulas_faiscas(&a->brasas, m.x + m.w / 2, m.y + m.h / 2, 30, COR_OURO, 1.0f);
        som_evento_pan(&a->som, SOM_MARTELO, 0.7f, sb_pan(f));
      } else {
        j->fora++;
        som_evento_pan(&a->som, SOM_BIGORNA, 0.3f, sb_pan(f));
      }
    }
    if (j->carimbos >= CARIMBOS)
      novo_passo(a, s, j, PASSO_PRONTO, f);
    break;
  case PASSO_PRONTO:
    break;
  }
}

/* ---------- o robô: vê a letra, o molde e o calor ---------- */

static void robo(App *a, int s, Jogador *j, Pad *p, float dt) {
  (void)s;
  int idx = (int)(p - a->pads.pad);
  switch (j->passo) {
  case PASSO_TRACAR: {
    const Letra *l = j->letra;
    if (j->robo_ponto < j->ponto - 1)
      j->robo_ponto = j->ponto - 1;
    if (j->robo_ponto >= l->n)
      break;
    float tx = l->x[j->robo_ponto], ty = l->y[j->robo_ponto];
    float dx = tx - j->robo_x, dy = ty - j->robo_y;
    float dist = sqrtf(dx * dx + dy * dy), passo = dt * (0.9f + 0.3f * robo_acaso());
    if (dist > passo) {
      j->robo_x += dx / dist * passo;
      j->robo_y += dy / dist * passo;
    } else {
      j->robo_x = tx;
      j->robo_y = ty;
      j->robo_ponto++;
    }
    robo_tocar(a, idx, 0, j->robo_x, j->robo_y, 0.06f);
    break;
  }
  case PASSO_ABRIR:
    if (j->t_passo < 0.4f)
      break;
    if (!j->aberto) {
      j->robo_s = fminf(0.33f, j->robo_s + dt * 0.35f);
    } else {
      j->robo_s = fmaxf(0.03f, j->robo_s - dt * 0.35f);
    }
    robo_tocar(a, idx, 0, 0.5f - j->robo_s, 0.5f, 0.06f);
    robo_tocar(a, idx, 1, 0.5f + j->robo_s, 0.52f, 0.06f);
    break;
  case PASSO_CARIMBAR:
    if (no_ponto(j) && calor(j) > 0.86f) {
      if (j->robo_espera < 0)
        j->robo_espera = 0.05f + 0.1f * robo_acaso();
      j->robo_espera -= dt;
      if (j->robo_espera <= 0) {
        robo_apertar(a, idx, SDL_GAMEPAD_BUTTON_TOUCHPAD, 0.08f);
        j->robo_espera = 10; /* espera o metal esfriar e voltar */
      }
    } else if (!no_ponto(j)) {
      j->robo_espera = -1;
    }
    break;
  case PASSO_PRONTO:
    break;
  }
}

static void atualizar(App *a, float dt) {
  int fase = sb_atualizar(a, &g_b, dt);
  g_n_faixas = sb_faixas(a, &g_b, FAIXAS_QUADRANTES, AREA, g_faixa, g_slot_faixa);
  if (fase != FASE_JOGO)
    return;
  for (int i = 0; i < g_n_faixas; i++) {
    int s = g_slot_faixa[i];
    Pad *p = pads_do_slot(a, s);
    Jogador *j = &g_j[s];
    if (!p)
      continue;
    if (!p->cap_touch) {
      if (!j->sem_touchpad) {
        j->sem_touchpad = true;
        g_b.acabou[s] = true;
      }
      continue;
    }
    medir(a, s, j, p);
    if (g_b.acabou[s])
      continue;
    if (robo_ativo())
      robo(a, s, j, p, dt);
    jogar(a, s, j, p, g_faixa[i], dt);
  }
  if (sb_todos_acabaram(a, &g_b)) {
    for (int s = 0; s < MAX_JOGADORES; s++) {
      if (!g_b.jogando[s])
        continue;
      Jogador *j = &g_j[s];
      Pad *p = pads_do_slot(a, s);
      Veredito v1, v2;
      if (j->sem_touchpad) {
        SDL_memset(&v1, 0, sizeof(v1));
        v1.resultado = RES_NAO_MEDIDO;
        snprintf(v1.pedido, sizeof(v1.pedido), "traçar a runa com um dedo e abrir e fechar o molde com dois");
        snprintf(v1.medido, sizeof(v1.medido), "o controle não publica touchpad");
        snprintf(v1.obs, sizeof(v1.obs), "não medido: o controle chegou sem touchpad (%s)",
                 p ? pad_origem_rotulo(p) : "desconectado");
        v2 = v1;
        snprintf(v2.pedido, sizeof(v2.pedido), "carimbar o molde com o clique do touchpad");
      } else {
        v1 = med_toque_dedos_veredito(&j->med, g_b.mexeu[s]);
        v2 = med_toque_clique_veredito(&j->med, g_b.mexeu[s]);
      }
      sb_veredito(&g_b, s, F_TOUCH_DOIS_DEDOS, &v1);
      sb_veredito(&g_b, s, F_TOUCH_CLIQUE, &v2);
    }
    sb_terminar(a, &g_b, NIVEL_REAGIU);
  }
}

/* ---------- desenho ---------- */

static void desenhar_molde(App *a, int s, Jogador *j, Pad *p, SDL_FRect f) {
  SDL_Renderer *r = a->r;
  SDL_FRect m = molde(f);
  float quente = j->passo == PASSO_CARIMBAR ? calor(j) : j->passo == PASSO_PRONTO ? 1 : 0.35f;
  float meio = j->passo == PASSO_ABRIR ? fminf(j->abertura, 0.6f) * 60 : 0;
  /* as duas metades do molde (afastam quando se abre) */
  SDL_Color pedra_topo = {66, 55, 48, 255}, pedra_base = {34, 27, 23, 255};
  ds_ret_arred_grad(r, m.x - 18 - meio, m.y - 18, m.w / 2 + 18, m.h + 36, 22, pedra_topo, pedra_base);
  ds_ret_arred_grad(r, m.x + m.w / 2 + meio, m.y - 18, m.w / 2 + 18, m.h + 36, 22, pedra_topo, pedra_base);
  /* o metal no fundo do molde */
  SDL_Color metal = cor_mistura((SDL_Color){70, 24, 8, 255}, COR_BRASA_VIVA, quente);
  if (j->passo == PASSO_CARIMBAR && no_ponto(j))
    metal = cor_mistura(COR_BRASA_VIVA, COR_OURO, 0.6f);
  ds_ret_arred(r, m.x - meio, m.y, m.w / 2, m.h, 16, metal);
  ds_ret_arred(r, m.x + m.w / 2 + meio, m.y, m.w / 2, m.h, 16, metal);
  ds_brilho(r, m.x + m.w / 2, m.y + m.h / 2, m.w * 0.6f, COR_BRASA, 0.15f + 0.4f * quente);
  ds_contorno_arred(r, m.x - 4, m.y - 4, m.w + 8, m.h + 8, 18, 2, cor_alfa(COR_BRONZE, 0.7f));

  const Letra *l = j->letra;
  if (j->passo == PASSO_TRACAR) {
    /* o sulco da letra, e o que já encheu de ouro */
    for (int k = 0; k + 1 < l->n; k++) {
      float x0 = m.x + l->x[k] * m.w, y0 = m.y + l->y[k] * m.h;
      float x1 = m.x + l->x[k + 1] * m.w, y1 = m.y + l->y[k + 1] * m.h;
      bool cheio = k + 1 < j->ponto;
      ds_linha(r, x0, y0, x1, y1, cheio ? 10 : 6, cheio ? COR_OURO : cor_alfa(COR_CARVAO, 0.8f));
    }
    for (int k = 0; k < l->n; k++) {
      float px = m.x + l->x[k] * m.w, py = m.y + l->y[k] * m.h;
      bool feito = k < j->ponto, proximo = k == j->ponto;
      float raio = RAIO_PONTO * m.w;
      if (proximo) {
        ds_brilho(r, px, py, raio * 2.4f, COR_OURO, 0.5f + 0.3f * sinf(a->t * 6));
        ds_anel(r, px, py, raio * (0.9f + 0.1f * sinf(a->t * 6)), 3, COR_OURO);
      }
      ds_circulo(r, px, py, feito ? 12 : 9, feito ? COR_OURO : COR_CARVAO);
      texto_al(r, F_MINI, px, py - 30, feito ? COR_OURO : COR_TEXTO_2, ALINHA_CENTRO, fmt("%d", k + 1));
    }
    for (int k = j->n_rastro - 1; k > 0; k--) {
      float al = 1 - (float)k / MAX_RASTRO;
      ds_linha(r, m.x + j->rastro_x[k] * m.w, m.y + j->rastro_y[k] * m.h, m.x + j->rastro_x[k - 1] * m.w,
               m.y + j->rastro_y[k - 1] * m.h, 5 * al + 1, cor_alfa(COR_OURO, al));
    }
  } else if (j->passo == PASSO_PRONTO) {
    /* a peça forjada: a letra em ouro, com o sulco escuro por baixo */
    for (int k = 0; k + 1 < l->n; k++)
      ds_linha(r, m.x + l->x[k] * m.w, m.y + l->y[k] * m.h + 3, m.x + l->x[k + 1] * m.w, m.y + l->y[k + 1] * m.h + 3, 18,
               (SDL_Color){90, 36, 10, 255});
    for (int k = 0; k + 1 < l->n; k++)
      ds_linha(r, m.x + l->x[k] * m.w, m.y + l->y[k] * m.h, m.x + l->x[k + 1] * m.w, m.y + l->y[k + 1] * m.h, 12,
               cor_clarear(COR_OURO, 0.2f));
    ds_brilho(r, m.x + m.w / 2, m.y + m.h / 2, m.w * 0.45f, COR_OURO, 0.25f);
  }
  if (j->passo == PASSO_ABRIR) {
    /* a régua da abertura: fechar abaixo de 15%, abrir além de 45% */
    float gx = m.x + 30, gy = m.y + m.h - 28, gw = m.w - 60;
    wg_barra(r, gx, gy, gw, 10, fminf(j->abertura / 0.7f, 1), j->aberto ? COR_BRASA_VIVA : COR_OURO);
    ds_linha(r, gx + gw * 0.15f / 0.7f, gy - 6, gx + gw * 0.15f / 0.7f, gy + 16, 2, COR_TEXTO_2);
    ds_linha(r, gx + gw * 0.45f / 0.7f, gy - 6, gx + gw * 0.45f / 0.7f, gy + 16, 2, COR_TEXTO_2);
  }
  if (j->passo == PASSO_CARIMBAR) {
    /* o termômetro do metal, e o carimbo que desce */
    float tx = m.x + m.w + 34, ty = m.y, th = m.h;
    ds_ret_arred(r, tx, ty, 18, th, 9, cor_alfa(COR_FUNDO_0, 0.9f));
    ds_ret(r, tx, ty, 18, th * 0.2f, cor_alfa(COR_OURO, 0.3f));
    ds_ret_arred(r, tx + 3, ty + th * (1 - quente), 12, th * quente, 6, no_ponto(j) ? COR_OURO : COR_BRASA);
    float desce = j->pancada * 30;
    icone(r, IC_MARTELO, m.x + m.w / 2, m.y - 30 + desce, 56, COR_BRONZE_CLARO, 0);
    for (int k = 0; k < CARIMBOS; k++) {
      float kx = m.x + m.w / 2 - 130 + k * 34, ky = m.y - 34;
      ds_circulo(r, kx, ky, 11, k < j->carimbos ? COR_OURO : COR_CARVAO);
      ds_anel(r, kx, ky, 11, 1.5f, COR_BRONZE);
    }
  }
  /* os dedos, onde o jogo os vê */
  if (p) {
    for (int k = 0; k < 2; k++) {
      if (!p->dedo[k].baixo)
        continue;
      float px = m.x + p->dedo[k].x * m.w, py = m.y + p->dedo[k].y * m.h;
      SDL_Color c = k == 0 ? COR_JOGADOR[s] : cor_clarear(COR_JOGADOR[s], 0.4f);
      ds_brilho(r, px, py, 60, c, 0.6f);
      ds_circulo(r, px, py, 14, c);
      ds_anel(r, px, py, 14, 2, COR_TEXTO);
      texto_al(r, F_MINI, px, py - 36, COR_TEXTO, ALINHA_CENTRO, k == 0 ? "1" : "2");
    }
    if (p->dedo[0].baixo && p->dedo[1].baixo)
      ds_linha(r, m.x + p->dedo[0].x * m.w, m.y + p->dedo[0].y * m.h, m.x + p->dedo[1].x * m.w,
               m.y + p->dedo[1].y * m.h, 2, cor_alfa(COR_TEXTO, 0.5f));
  }

  const char *dica = "";
  switch (j->passo) {
  case PASSO_TRACAR:
    dica = fmt("1 · trace o %s: toque os pontos na ordem", l->nome);
    break;
  case PASSO_ABRIR:
    dica = j->aberto ? "2 · agora junte os dois dedos" : "2 · dois dedos no touchpad, e afaste";
    break;
  case PASSO_CARIMBAR:
    dica = "3 · clique o touchpad {TP} quando o metal brilhar";
    break;
  case PASSO_PRONTO:
    dica = "peça forjada!";
    break;
  }
  if (j->sem_touchpad)
    dica = "este controle não tem touchpad";
  Fonte fd = f.w < 700 ? F_PEQUENA_N : F_TEXTO_N;
  float dw = wg_texto_rico_largura(fd, dica);
  ds_ret_arred(r, f.x + f.w / 2 - dw / 2 - 16, f.y + f.h - 54, dw + 32, 42, 10, cor_alfa(COR_CARVAO, 0.85f));
  wg_texto_rico(r, fd, f.x + f.w / 2, f.y + f.h - 48, j->sem_touchpad ? COR_AVISO : COR_TEXTO, ALINHA_CENTRO, dica);
}

static void desenhar(App *a) {
  SDL_Renderer *r = a->r;
  ds_fundo(r, a->t, 0.45f);
  sb_desenhar_topo(a, &g_b);
  for (int i = 0; i < g_n_faixas; i++) {
    int s = g_slot_faixa[i];
    SDL_FRect f = g_faixa[i];
    Pad *p = pads_do_slot(a, s);
    sb_moldura(a, f, s, g_b.acabou[s] ? 0.8f : 0.2f);
    if (g_b.fase != FASE_AVISO)
      desenhar_molde(a, s, &g_j[s], p, f);
    texto_al(r, F_GRANDE_N, f.x + f.w - 28, f.y + 14, COR_TEXTO, ALINHA_DIR, fmt("%d", g_b.pontos[s]));
    if (!p)
      sb_sem_controle(a, f, s);
  }
  particulas_desenhar(r, &a->brasas);
  if (g_b.fase == FASE_AVISO)
    sb_desenhar_aviso(a, &g_b,
                      "O touchpad é o molde. Primeiro, trace a letra: toque os pontos na ordem.\n"
                      "Depois, dois dedos: afaste até o molde abrir, e junte até fechar.\n"
                      "Por fim, clique o touchpad {TP} quando o metal brilhar — três carimbos.");
  else if (g_b.fase == FASE_FIM)
    sb_desenhar_fim(a, &g_b);
  else {
    Dica d[] = {{IC_OPTIONS, "pausa"}};
    wg_rodape(r, d, 1);
  }
  pausa_desenhar(a);
}

const Cena CENA_MOLDE = {"molde", entrar, sair, NULL, atualizar, desenhar};
