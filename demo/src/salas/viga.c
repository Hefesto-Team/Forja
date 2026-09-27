/* A Viga — equilíbrio e mira por movimento (ADR-002).
 *
 * Três trechos, um atrás do outro, cada um com o uso de sensor de um tipo de
 * jogo:
 *
 *   1. a travessia: o autômato anda sozinho por uma viga sobre a lava e o
 *      vento empurra; você o equilibra INCLINANDO o controle para os lados
 *      (rolagem) — o controle de equilíbrio dos jogos de plataforma;
 *   2. os sinos: três sinos no alto; a mira anda quando você GIRA o controle
 *      (guinada e arfagem), como a mira por giroscópio dos jogos de tiro;
 *      R1 ou ✕ arremessa o martelo, L1 centraliza a mira;
 *   3. a pedra: uma MARTELADA — sacudir o controle para baixo, um pico no
 *      acelerômetro — quebra a pedra que fecha o caminho.
 *
 * O que a sala mede (medidas.h, postura.h): o pico de giro em cada eixo, a
 * taxa declarada pelo SDL contra a medida (pelo relógio do host e pelo do
 * próprio controle), se o giro anda para o mesmo lado da gravidade (um eixo
 * invertido por um intermediário aparece aqui), a gravidade parado (1 g), a
 * inclinação que a gravidade viu e as marteladas.
 *
 * Sem giroscópio (um pad Xbox por uinput, por exemplo), a sala joga com os
 * analógicos e o ✕ — e o veredito é NÃO MEDIDO, com o porquê. */
#include "sala_base.h"

#include "../cenas/pausa.h"
#include "../nucleo/simulador.h"
#include "../ui/automato.h"
#include "../ui/desenho.h"
#include "../ui/icones.h"
#include "../ui/tema.h"
#include "../ui/texto.h"
#include "../ui/widgets.h"

#include <math.h>
#include <stdio.h>

#define PI_F 3.14159265f
#define DURACAO 80.0f
#define ROLAGEM_CHEIA 0.45f   /* rad (~26°): a inclinação que vale "tudo" */
#define SENSIBILIDADE 420.0f  /* px por rad da mira */
#define N_SINOS 3
#define G_MARTELADA 1.8f

typedef enum Trecho { TRECHO_VIGA = 0, TRECHO_SINOS, TRECHO_PEDRA, TRECHO_FIM } Trecho;

typedef struct Sino {
  float x, y; /* relativos à faixa, 0..1 */
  bool vivo;
  float balanco;
} Sino;

typedef struct Jogador {
  Trecho trecho;
  float t_trecho;
  /* a travessia */
  float progresso;   /* 0..1 ao longo da viga */
  float checkpoint;
  float inclinacao;  /* -1..1 do autômato: >0 caindo para a direita */
  float bambo;       /* segundos além do limite */
  float caindo;      /* 0 de pé; >0 animação da queda */
  int quedas;
  float fase_vento, freq_vento, rajada, rajada_t;
  /* os sinos */
  Sino sino[N_SINOS];
  float mira_x, mira_y; /* px, relativos à faixa */
  int acertos, arremessos;
  float voo;            /* animação do martelo arremessado */
  float voo_x, voo_y;
  /* a pedra */
  int golpes;
  float pancada;        /* animação */
  bool acima;           /* o acelerômetro está acima do limiar (borda) */
  float g_agora;
  /* as medidas */
  MedSensores med;
  long giro0, acel0;    /* contagens de amostras quando o jogo começou */
  int concorda0[2], discorda0[2];
  /* o robô */
  float robo_espera;
} Jogador;

static const Feature FEATS[] = {F_GIROSCOPIO, F_ACELEROMETRO};

static SalaBase g_b;
static Jogador g_j[MAX_JOGADORES];
static SDL_FRect g_faixa[MAX_JOGADORES];
static int g_slot_faixa[MAX_JOGADORES], g_n_faixas;
static const SDL_FRect AREA = {40, 140, TELA_L - 80, TELA_A - 140 - 96};

/* ---------- a geometria de uma faixa ---------- */

static float viga_y(SDL_FRect f) { return f.y + f.h * 0.78f; }
static float viga_x0(SDL_FRect f) { return f.x + 150; }
static float viga_x1(SDL_FRect f) { return f.x + f.w - 210; }
static SDL_FRect ceu(SDL_FRect f) { return (SDL_FRect){f.x + 100, f.y + 70, f.w - 170, f.h * 0.78f - 150}; }

static void sortear_sinos(Jogador *j, Sorteio *s) {
  for (int i = 0; i < N_SINOS; i++) {
    /* espalhados na largura, e alternando alto e baixo: mirar pede guinada E
     * arfagem */
    j->sino[i].x = 0.1f + 0.8f * (i + 0.2f + 0.6f * sorteio_real(s)) / N_SINOS;
    j->sino[i].y = (i % 2 ? 0.72f : 0.12f) + 0.16f * sorteio_real(s);
    j->sino[i].vivo = true;
    j->sino[i].balanco = sorteio_real(s) * 6;
  }
}

static void entrar(App *a) {
  sb_entrar(a, &g_b, SALA_VIGA, FEATS, 2, DURACAO);
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Jogador *j = &g_j[s];
    SDL_memset(j, 0, sizeof(*j));
    j->fase_vento = sorteio_real(&g_b.sorteio) * 2 * PI_F;
    j->freq_vento = 0.22f + 0.12f * sorteio_real(&g_b.sorteio);
    j->rajada_t = 2.5f + 2 * sorteio_real(&g_b.sorteio);
    sortear_sinos(j, &g_b.sorteio);
    j->robo_espera = -1;
  }
}

static void sair(App *a) { pads_silencio_todos(a); }

static void comecar_medida(Jogador *j, Pad *p) {
  med_sensores_iniciar(&j->med, p->cap_giro, p->cap_acel, p->giro_hz_declarado);
  j->giro0 = p->postura.amostras_giro;
  j->acel0 = p->postura.amostras_acel;
  for (int e = 0; e < 2; e++) {
    j->concorda0[e] = p->postura.concorda[e];
    j->discorda0[e] = p->postura.discorda[e];
  }
}

static void novo_trecho(App *a, int s, Jogador *j, Trecho t, SDL_FRect f) {
  j->trecho = t;
  j->t_trecho = 0;
  if (t == TRECHO_SINOS)
    j->med.pediu_mira = true;
  if (t == TRECHO_PEDRA)
    j->med.pediu_martelada = true;
  if (t == TRECHO_SINOS) {
    SDL_FRect c = ceu(f);
    j->mira_x = c.w / 2;
    j->mira_y = c.h / 2;
  }
  if (t == TRECHO_FIM) {
    g_b.acabou[s] = true;
    som_evento_pan(&a->som, SOM_SUCESSO, 0.6f, sb_pan(f));
    particulas_brasas(&a->brasas, viga_x1(f) + 80, viga_y(f) - 60, 36, COR_OURO);
  } else {
    som_evento_pan(&a->som, SOM_CONFIRMA, 0.5f, sb_pan(f));
  }
}

/* O vento: uma onda lenta que cresce ao longo da viga, e rajadas. */
static float vento(Jogador *j, float t) {
  float amp = 0.3f + 0.45f * j->progresso;
  float v = amp * sinf(t * j->freq_vento * 2 * PI_F + j->fase_vento);
  v += 0.12f * sinf(t * 1.7f + j->fase_vento * 2);
  return v + j->rajada;
}

static void travessia(App *a, int s, Jogador *j, Pad *p, SDL_FRect f, float dt) {
  if (j->caindo > 0) {
    j->caindo += dt;
    if (j->caindo > 1.3f) {
      j->caindo = 0;
      j->progresso = j->checkpoint;
      j->inclinacao = 0;
      j->bambo = 0;
    }
    return;
  }
  /* as rajadas: um empurrão curto, para um lado sorteado */
  j->rajada_t -= dt;
  if (j->rajada_t <= 0) {
    float lado = sorteio_real(&g_b.sorteio) < 0.5f ? -1.0f : 1.0f;
    j->rajada = lado * (0.35f + 0.25f * sorteio_real(&g_b.sorteio));
    j->rajada_t = 2.2f + 2.0f * sorteio_real(&g_b.sorteio);
  }
  j->rajada = aproximar(j->rajada, 0, 1.4f, dt);

  /* inclinar o controle para a direita (lado direito para baixo = rolagem
   * negativa) inclina o autômato para a direita; contra o vento, equilibra */
  float controle = p->cap_giro   ? -p->postura.rolagem / ROLAGEM_CHEIA
                   : p->cap_acel ? -postura_rolagem_da_gravidade(p->acel) / ROLAGEM_CHEIA
                                 : p->ax[SDL_GAMEPAD_AXIS_LEFTX];
  float alvo = limitar(vento(j, g_b.t_fase) + controle, -1.6f, 1.6f);
  j->inclinacao = aproximar(j->inclinacao, alvo, 7, dt);
  float mod = fabsf(j->inclinacao);
  j->progresso += dt * (mod < 0.6f ? 0.075f : 0.035f);
  if (j->progresso >= 1.0f / 3 && j->checkpoint < 1.0f / 3)
    j->checkpoint = 1.0f / 3;
  if (j->progresso >= 2.0f / 3 && j->checkpoint < 2.0f / 3)
    j->checkpoint = 2.0f / 3;
  j->bambo = mod > 1 ? j->bambo + dt : fmaxf(0, j->bambo - dt);
  if (j->bambo > 0.45f) {
    j->caindo = 0.001f;
    j->quedas++;
    som_evento_pan(&a->som, SOM_FALHA, 0.5f, sb_pan(f));
    particulas_faiscas(&a->brasas, viga_x0(f) + (viga_x1(f) - viga_x0(f)) * j->progresso, viga_y(f) + 80, 20,
                       COR_BRASA_VIVA, 0.7f);
  }
  if (j->progresso >= 1) {
    j->progresso = 1;
    sb_pontos(a, &g_b, s, j->quedas < 5 ? 500 - 80 * j->quedas : 100);
    novo_trecho(a, s, j, TRECHO_SINOS, f);
  }
}

static void sinos(App *a, int s, Jogador *j, Pad *p, SDL_FRect f, float dt) {
  SDL_FRect c = ceu(f);
  if (p->cap_giro) {
    /* girar para a esquerda (guinada positiva) leva a mira para a esquerda;
     * erguer a borda de longe (arfagem positiva) leva a mira para cima */
    j->mira_x -= p->giro[1] * SENSIBILIDADE * dt;
    j->mira_y -= p->giro[0] * SENSIBILIDADE * dt;
  } else {
    j->mira_x += p->ax[SDL_GAMEPAD_AXIS_RIGHTX] * 520 * dt;
    j->mira_y += p->ax[SDL_GAMEPAD_AXIS_RIGHTY] * 520 * dt;
  }
  if (pad_apertou(p, SDL_GAMEPAD_BUTTON_LEFT_SHOULDER)) {
    j->mira_x = c.w / 2;
    j->mira_y = c.h / 2;
  }
  j->mira_x = limitar(j->mira_x, 0, c.w);
  j->mira_y = limitar(j->mira_y, 0, c.h);
  j->voo = aproximar(j->voo, 0, 4, dt);
  if (pad_apertou(p, SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER) || pad_apertou(p, SDL_GAMEPAD_BUTTON_SOUTH)) {
    j->arremessos++;
    j->voo = 1;
    j->voo_x = j->mira_x;
    j->voo_y = j->mira_y;
    bool acertou = false;
    for (int i = 0; i < N_SINOS; i++) {
      Sino *si = &j->sino[i];
      if (!si->vivo)
        continue;
      float dx = si->x * c.w - j->mira_x, dy = si->y * c.h - j->mira_y;
      if (dx * dx + dy * dy < 46 * 46) {
        si->vivo = false;
        acertou = true;
        j->acertos++;
        sb_pontos(a, &g_b, s, 150 + (int)fmaxf(0, 100 - j->t_trecho * 5));
        particulas_faiscas(&a->brasas, c.x + si->x * c.w, c.y + si->y * c.h, 30, COR_OURO, 1.0f);
        particulas_anel(&a->brasas, c.x + si->x * c.w, c.y + si->y * c.h, COR_OURO, 120);
        som_evento_pan(&a->som, SOM_BIGORNA_AGUDA, 0.7f, sb_pan(f));
        break;
      }
    }
    if (!acertou)
      som_evento_pan(&a->som, SOM_TICK, 0.4f, sb_pan(f));
  }
  if (j->acertos >= N_SINOS)
    novo_trecho(a, s, j, TRECHO_PEDRA, f);
}

static void pedra(App *a, int s, Jogador *j, Pad *p, SDL_FRect f, float dt) {
  j->pancada = aproximar(j->pancada, 0, 5, dt);
  bool golpe = false;
  if (p->cap_acel) {
    float g = postura_g(p->acel);
    j->g_agora = g;
    if (g >= G_MARTELADA && !j->acima) {
      j->acima = true;
      golpe = true;
    } else if (g < 1.3f) {
      j->acima = false;
    }
  } else {
    golpe = pad_apertou(p, SDL_GAMEPAD_BUTTON_SOUTH);
  }
  if (!golpe || j->t_trecho < 0.3f)
    return;
  j->golpes++;
  j->pancada = 1;
  if (p->cap_acel)
    med_sensores_martelada(&j->med);
  float px = viga_x1(f) + 80, py = viga_y(f) - 40;
  particulas_faiscas(&a->brasas, px, py, 34, COR_BRASA_VIVA, 1.1f);
  som_evento_pan(&a->som, SOM_MARTELO, 0.8f, sb_pan(f));
  a->tremor = fmaxf(a->tremor, 0.25f);
  if (j->golpes >= 2) {
    particulas_faiscas(&a->brasas, px, py, 60, COR_OURO, 1.4f);
    sb_pontos(a, &g_b, s, 200);
    novo_trecho(a, s, j, TRECHO_FIM, f);
  }
}

/* ---------- o robô: vê a inclinação do autômato, a mira e os sinos ---------- */

static void robo(App *a, int s, Jogador *j, Pad *p, SDL_FRect f, float dt) {
  (void)s;
  int idx = (int)(p - a->pads.pad);
  float gx = 0, gy = 0, gz = 0;
  switch (j->trecho) {
  case TRECHO_VIGA:
    /* contra a queda: inclina para o lado oposto, com a mão de gente */
    gz = limitar(4.2f * j->inclinacao + (robo_acaso() - 0.5f) * 0.4f, -3.0f, 3.0f);
    break;
  case TRECHO_SINOS: {
    SDL_FRect c = ceu(f);
    int alvo = -1;
    for (int i = 0; i < N_SINOS; i++)
      if (j->sino[i].vivo) {
        alvo = i;
        break;
      }
    gz = -2.5f * p->postura.rolagem; /* volta a mão ao nível */
    if (alvo >= 0) {
      float dx = j->sino[alvo].x * c.w - j->mira_x, dy = j->sino[alvo].y * c.h - j->mira_y;
      gy = limitar(-6.0f * dx / SENSIBILIDADE, -4.5f, 4.5f);
      gx = limitar(-6.0f * dy / SENSIBILIDADE, -4.5f, 4.5f);
      if (dx * dx + dy * dy < 20 * 20) {
        if (j->robo_espera < 0)
          j->robo_espera = 0.15f + 0.3f * robo_acaso();
        j->robo_espera -= dt;
        if (j->robo_espera <= 0) {
          robo_apertar(a, idx, SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER, 0.08f);
          j->robo_espera = -1;
        }
      }
    }
    break;
  }
  case TRECHO_PEDRA:
    gz = -2.5f * p->postura.rolagem;
    gx = -2.5f * p->postura.arfagem;
    if (j->robo_espera < 0)
      j->robo_espera = 0.7f + 0.5f * robo_acaso();
    j->robo_espera -= dt;
    if (j->robo_espera <= 0) {
      robo_sacudir(a, idx, 1.6f, 0.2f);
      if (!p->cap_acel)
        robo_apertar(a, idx, SDL_GAMEPAD_BUTTON_SOUTH, 0.08f);
      j->robo_espera = 0.8f + 0.4f * robo_acaso();
    }
    break;
  case TRECHO_FIM:
    gz = -2.5f * p->postura.rolagem;
    gx = -2.5f * p->postura.arfagem;
    break;
  }
  if (p->cap_giro)
    robo_girar(a, idx, gx, gy, gz, 0.06f);
  else if (j->trecho == TRECHO_VIGA)
    robo_eixo(a, idx, SDL_GAMEPAD_AXIS_LEFTX, limitar(-1.5f * j->inclinacao, -1, 1), 0.06f);
}

static void atualizar(App *a, float dt) {
  int fase = sb_atualizar(a, &g_b, dt);
  g_n_faixas = sb_faixas(a, &g_b, FAIXAS_QUADRANTES, AREA, g_faixa, g_slot_faixa);
  if (fase == FASE_JOGO && g_b.t_fase <= dt + 0.0001f) {
    for (int s = 0; s < MAX_JOGADORES; s++) {
      Pad *p = pads_do_slot(a, s);
      if (p && g_b.jogando[s])
        comecar_medida(&g_j[s], p);
    }
  }
  if (fase != FASE_JOGO)
    return;
  for (int i = 0; i < g_n_faixas; i++) {
    int s = g_slot_faixa[i];
    Pad *p = pads_do_slot(a, s);
    Jogador *j = &g_j[s];
    if (!p)
      continue;
    med_sensores_amostra(&j->med, p->giro, p->acel);
    if (robo_ativo())
      robo(a, s, j, p, g_faixa[i], dt);
    j->t_trecho += dt;
    switch (j->trecho) {
    case TRECHO_VIGA:
      travessia(a, s, j, p, g_faixa[i], dt);
      break;
    case TRECHO_SINOS:
      sinos(a, s, j, p, g_faixa[i], dt);
      break;
    case TRECHO_PEDRA:
      pedra(a, s, j, p, g_faixa[i], dt);
      break;
    case TRECHO_FIM:
      break;
    }
    for (int k = 0; k < N_SINOS; k++)
      j->sino[k].balanco += dt * 2.2f;
  }
  if (sb_todos_acabaram(a, &g_b)) {
    Uint64 agora = SDL_GetTicksNS();
    for (int s = 0; s < MAX_JOGADORES; s++) {
      if (!g_b.jogando[s])
        continue;
      Jogador *j = &g_j[s];
      Pad *p = pads_do_slot(a, s);
      if (p) {
        j->med.amostras_giro = p->postura.amostras_giro - j->giro0;
        j->med.amostras_acel = p->postura.amostras_acel - j->acel0;
        j->med.hz_host = taxa_hz_host(&p->taxa_giro, agora, 2.0);
        j->med.hz_relogio = taxa_hz_sensor(&p->taxa_giro, agora, 2.0);
        for (int e = 0; e < 2; e++)
          j->med.sinal[e] = postura_sinal_contagem(p->postura.concorda[e] - j->concorda0[e],
                                                   p->postura.discorda[e] - j->discorda0[e]);
      }
      Veredito v = med_giro_veredito(&j->med, g_b.mexeu[s]);
      if (!j->med.tem_giro && p)
        snprintf(v.obs, sizeof(v.obs), "não medido: o controle chegou sem giroscópio (%s) — a sala jogou com o analógico",
                 pad_origem_rotulo(p));
      sb_veredito(&g_b, s, F_GIROSCOPIO, &v);
      v = med_acel_veredito(&j->med, g_b.mexeu[s]);
      if (!j->med.tem_acel && p)
        snprintf(v.obs, sizeof(v.obs), "não medido: o controle chegou sem acelerômetro (%s) — a martelada foi o botão cruz",
                 pad_origem_rotulo(p));
      sb_veredito(&g_b, s, F_ACELEROMETRO, &v);
    }
    sb_terminar(a, &g_b, NIVEL_REAGIU);
  }
}

/* ---------- desenho ---------- */

static void desenhar_sino(SDL_Renderer *r, float x, float y, float balanco, bool vivo) {
  if (!vivo)
    return;
  float a = sinf(balanco) * 0.25f;
  float ca = cosf(a), sa = sinf(a);
  /* o sino: um corpo em trapézio arredondado, girando no gancho */
  SDL_FPoint base[7] = {{-10, -26}, {10, -26}, {18, -6}, {22, 16}, {28, 22}, {-28, 22}, {-22, 16}};
  SDL_FPoint p[7];
  for (int i = 0; i < 7; i++)
    p[i] = (SDL_FPoint){x + base[i].x * ca - base[i].y * sa, y + base[i].x * sa + base[i].y * ca};
  ds_brilho(r, x, y, 70, COR_OURO, 0.25f);
  ds_linha(r, x, y - 60, x - 26 * sa, y - 26 * ca, 2, COR_BRONZE_ESCURO);
  ds_poligono(r, p, 7, (SDL_Color){190, 140, 60, 255});
  ds_polilinha(r, p, 7, 2, COR_OURO, true);
  ds_circulo(r, x + 30 * sa, y + 28 * ca, 6, COR_BRONZE_ESCURO);
}

/* O cenário de uma faixa: a caverna com arcos ao fundo, as correntes que
 * seguram a viga, os pilares de pedra e a lava que ondula lá embaixo. */
static void cenario(App *a, SDL_FRect f, float fase) {
  SDL_Renderer *r = a->r;
  float vy = viga_y(f), x0 = viga_x0(f), x1 = viga_x1(f);
  float fundo_y = f.y + f.h - 8, lava_y = vy + (fundo_y - vy) * 0.42f;
  ds_ret_grad(r, f.x + 6, f.y + 6, f.w - 12, f.h - 12, (SDL_Color){16, 12, 10, 255}, (SDL_Color){62, 26, 12, 255});
  /* os arcos da forja, em silhueta */
  SDL_Color sil = {27, 20, 17, 255};
  for (int k = 0; k < 3; k++) {
    float ax = f.x + f.w * (0.2f + 0.3f * k), aw = f.w * 0.2f, topo = f.y + f.h * 0.3f;
    float esp = aw * 0.14f;
    ds_ret(r, ax - aw / 2, topo, esp, lava_y - topo, sil);
    ds_ret(r, ax + aw / 2 - esp, topo, esp, lava_y - topo, sil);
    ds_arco(r, ax, topo, aw / 2 - esp / 2, esp, PI_F, 2 * PI_F, sil);
    ds_brilho(r, ax, topo + (lava_y - topo) * 0.6f, aw * 0.6f, COR_BRASA, 0.05f);
  }
  /* a lava: a superfície ondula, e bolhas estouram */
  SDL_FPoint onda[28];
  int n = 0;
  for (int i = 0; i <= 25; i++) {
    float x = f.x + 8 + i * (f.w - 16) / 25.0f;
    onda[n++] = (SDL_FPoint){x, lava_y + sinf(fase * 1.6f + i * 0.8f) * 4 + sinf(fase * 0.7f + i * 0.3f) * 3};
  }
  onda[n++] = (SDL_FPoint){f.x + f.w - 8, fundo_y};
  onda[n++] = (SDL_FPoint){f.x + 8, fundo_y};
  ds_poligono(r, onda, n, (SDL_Color){176, 58, 14, 255});
  ds_ret_grad(r, f.x + 8, lava_y + 8, f.w - 16, fundo_y - lava_y - 8, (SDL_Color){200, 70, 16, 0}, (SDL_Color){120, 30, 8, 200});
  ds_polilinha(r, onda, 26, 3, cor_alfa(COR_OURO, 0.8f), false);
  for (int k = 0; k < 6; k++) {
    float ciclo = fmodf(fase * 0.5f + k * 0.37f, 1.0f);
    float bx = f.x + 40 + fmodf(k * 157.0f, f.w - 80);
    float br = 3 + ciclo * 9;
    ds_brilho(r, bx, lava_y + 10, 60, COR_BRASA_VIVA, 0.3f);
    if (ciclo < 0.85f)
      ds_anel(r, bx, lava_y + 8 - ciclo * 4, br, 2, cor_alfa(COR_OURO, 1 - ciclo));
  }
  /* os pilares de pedra, com as juntas dos blocos */
  SDL_Color pedra_c = {74, 62, 54, 255}, pedra_e = {36, 29, 25, 255};
  float pw0 = x0 - (f.x + 24), pw1 = f.x + f.w - 24 - x1;
  ds_ret_arred_grad(r, f.x + 24, vy - 6, pw0, fundo_y - vy, 6, pedra_c, pedra_e);
  ds_ret_arred_grad(r, x1, vy - 6, pw1, fundo_y - vy, 6, pedra_c, pedra_e);
  for (float yy = vy + 22; yy < fundo_y - 6; yy += 26) {
    ds_linha(r, f.x + 24, yy, x0, yy, 1.5f, cor_alfa(pedra_e, 0.9f));
    ds_linha(r, x1, yy, x1 + pw1, yy, 1.5f, cor_alfa(pedra_e, 0.9f));
  }
  /* as correntes do teto até as pontas da viga: elos alternados, um de frente
   * (o anel) e um de lado (o traço), encavalados como numa corrente de verdade */
  for (int lado = 0; lado < 2; lado++) {
    float cx0 = lado ? x1 - 30 : x0 + 30, cy0 = f.y + 8, cy1 = vy;
    int k = 0;
    for (float yy = cy0 + 6; yy < cy1 - 6; yy += 9, k++) {
      if (k % 2)
        ds_linha(r, cx0, yy - 6, cx0, yy + 6, 3, (SDL_Color){58, 52, 48, 255});
      else
        ds_contorno_arred(r, cx0 - 4, yy - 7, 8, 14, 4, 1.6f, (SDL_Color){92, 84, 76, 255});
    }
  }
  /* a viga: tábua com cintas de ferro */
  ds_ret_grad(r, x0, vy - 2, x1 - x0, 14, (SDL_Color){150, 104, 58, 255}, (SDL_Color){86, 58, 32, 255});
  ds_ret(r, x0, vy + 12, x1 - x0, 3, (SDL_Color){40, 26, 16, 255});
  for (int k = 1; k < 8; k++) {
    float bx = x0 + (x1 - x0) * k / 8.0f;
    ds_ret(r, bx - 3, vy - 3, 6, 16, (SDL_Color){70, 64, 60, 255});
  }
}

static void desenhar_faixa(App *a, int s, Jogador *j, Pad *p, SDL_FRect f) {
  SDL_Renderer *r = a->r;
  float vy = viga_y(f), x0 = viga_x0(f), x1 = viga_x1(f);
  cenario(a, f, a->t + s * 1.3f);
  for (int k = 1; k < 3; k++) { /* os pontos de retorno: bandeirolas */
    float cx = x0 + (x1 - x0) * k / 3.0f;
    bool passou = j->checkpoint >= k / 3.0f - 0.001f;
    ds_linha(r, cx, vy - 2, cx, vy - 38, 3, (SDL_Color){70, 64, 60, 255});
    SDL_FPoint band[3] = {{cx, vy - 38}, {cx + 22, vy - 31}, {cx, vy - 24}};
    ds_poligono(r, band, 3, passou ? COR_OURO : COR_BRONZE_ESCURO);
  }

  /* o vento: riscos que correm para o lado dele */
  if (j->trecho == TRECHO_VIGA) {
    float v = vento(j, g_b.t_fase);
    int n = (int)(fabsf(v) * 14);
    for (int k = 0; k < n; k++) {
      float fase = fmodf(a->t * (0.9f + 0.1f * k) + k * 0.37f, 1.0f);
      float wx = v > 0 ? f.x + 20 + fase * (f.w - 40) : f.x + f.w - 20 - fase * (f.w - 40);
      float wy = f.y + 80 + fmodf(k * 53.0f, (vy - f.y) - 110);
      ds_linha(r, wx, wy, wx - (v > 0 ? 46 : -46), wy, 2, cor_alfa(COR_TEXTO_2, 0.55f * (1 - fabsf(fase - 0.5f) * 2)));
    }
  }

  /* o autômato, com a vara de equilíbrio */
  Automato bon;
  float bx = j->trecho == TRECHO_VIGA ? x0 + (x1 - x0) * j->progresso : x1 + 40;
  float by = vy;
  if (j->caindo > 0) {
    by += j->caindo * j->caindo * 260;
    bx += j->inclinacao * j->caindo * 60;
  }
  automato_iniciar(&bon, bx + j->inclinacao * 6, by);
  bon.passo = j->trecho == TRECHO_VIGA && j->caindo == 0 ? g_b.t_fase * 7 : 0;
  bon.olhar = j->trecho == TRECHO_SINOS ? -PI_F / 2 : 0;
  bon.conectado = p != NULL;
  if (j->caindo < 0.9f) {
    automato_desenhar(r, &bon, COR_JOGADOR[s], 0.75f, a->t, -1);
    if (j->trecho == TRECHO_VIGA) {
      float ang = j->inclinacao * 0.5f;
      float cx = bx + j->inclinacao * 6, cy = by - 38;
      float dx = cosf(ang) * 70, dy = sinf(ang) * 70;
      ds_linha(r, cx - dx, cy - dy, cx + dx, cy + dy, 4, (SDL_Color){150, 110, 60, 255});
      ds_circulo(r, cx - dx, cy - dy, 6, COR_BRONZE);
      ds_circulo(r, cx + dx, cy + dy, 6, COR_BRONZE);
    }
  }
  if (j->caindo > 0 && j->caindo < 0.6f)
    ds_brilho(r, bx, viga_y(f) + 60, 140, COR_BRASA_VIVA, 0.8f * (0.6f - j->caindo));

  /* a pedra, na ponta da plataforma */
  if (j->trecho <= TRECHO_PEDRA) {
    float px = x1 + 128, py = vy - 44;
    float sac = j->pancada * 5 * sinf(a->t * 70);
    SDL_FPoint rocha[8] = {{px - 44 + sac, py + 40}, {px - 50 + sac, py},      {px - 26 + sac, py - 36},
                           {px + 8 + sac, py - 44},  {px + 40 + sac, py - 24}, {px + 48 + sac, py + 8},
                           {px + 36 + sac, py + 40}, {px + sac, py + 44}};
    ds_poligono(r, rocha, 8, (SDL_Color){84, 72, 64, 255});
    ds_polilinha(r, rocha, 8, 2.5f, (SDL_Color){40, 34, 30, 255}, true);
    ds_linha(r, px - 30 + sac, py - 10, px + 10 + sac, py - 30, 2, (SDL_Color){104, 92, 84, 255});
    if (j->golpes >= 1) {
      ds_linha(r, px - 20 + sac, py - 30, px + 4 + sac, py + 4, 3, COR_BRASA_VIVA);
      ds_linha(r, px + 4 + sac, py + 4, px - 6 + sac, py + 36, 3, COR_BRASA_VIVA);
      ds_brilho(r, px, py, 60, COR_BRASA_VIVA, 0.3f);
    }
  } else {
    ds_brilho(r, x1 + 128, vy - 50, 110, COR_OURO, 0.4f);
    icone(r, IC_CHAMA, x1 + 128, vy - 50, 64, COR_OURO, 0);
  }

  /* os sinos e a mira */
  if (j->trecho == TRECHO_SINOS) {
    SDL_FRect c = ceu(f);
    for (int k = 0; k < N_SINOS; k++)
      desenhar_sino(r, c.x + j->sino[k].x * c.w, c.y + j->sino[k].y * c.h, j->sino[k].balanco, j->sino[k].vivo);
    float mx = c.x + j->mira_x, my = c.y + j->mira_y;
    if (j->voo > 0.01f)
      ds_anel(r, c.x + j->voo_x, c.y + j->voo_y, 30 * (1.4f - j->voo), 3, cor_alfa(COR_OURO, j->voo));
    ds_anel(r, mx, my, 24, 3, COR_JOGADOR[s]);
    ds_linha(r, mx - 36, my, mx - 12, my, 3, COR_JOGADOR[s]);
    ds_linha(r, mx + 12, my, mx + 36, my, 3, COR_JOGADOR[s]);
    ds_linha(r, mx, my - 36, mx, my - 12, 3, COR_JOGADOR[s]);
    ds_linha(r, mx, my + 12, mx, my + 36, 3, COR_JOGADOR[s]);
    ds_circulo(r, mx, my, 3, COR_TEXTO);
  }

  /* a instrução do trecho, embaixo */
  const char *dica = "";
  bool sem_giro = p && !p->cap_giro;
  switch (j->trecho) {
  case TRECHO_VIGA:
    dica = sem_giro ? "1 · a travessia — {LE} contra o vento" : "1 · a travessia — incline o controle contra o vento";
    break;
  case TRECHO_SINOS:
    dica = sem_giro ? "2 · os sinos — mire com {LD}, {R1} arremessa" : "2 · os sinos — gire o controle para mirar, {R1} arremessa";
    break;
  case TRECHO_PEDRA:
    dica = p && !p->cap_acel ? "3 · a pedra — {X} dá a martelada" : "3 · a pedra — sacuda o controle para baixo";
    break;
  case TRECHO_FIM:
    dica = "atravessou!";
    break;
  }
  Fonte fd = f.w < 700 ? F_PEQUENA_N : F_TEXTO_N;
  float dw = wg_texto_rico_largura(fd, dica);
  ds_ret_arred(r, f.x + f.w / 2 - dw / 2 - 16, f.y + f.h - 56, dw + 32, 42, 10, cor_alfa(COR_CARVAO, 0.88f));
  ds_contorno_arred(r, f.x + f.w / 2 - dw / 2 - 16, f.y + f.h - 56, dw + 32, 42, 10, 1.5f, cor_alfa(COR_BRONZE, 0.6f));
  wg_texto_rico(r, fd, f.x + f.w / 2, f.y + f.h - 50, COR_TEXTO, ALINHA_CENTRO, dica);

  /* em cima, no meio: o equilíbrio na travessia; a leitura do sensor depois */
  float topo = f.y + 24;
  if (j->trecho == TRECHO_VIGA) {
    float bw = 280, bx0 = f.x + f.w / 2 - bw / 2;
    ds_ret(r, bx0, topo, bw * 0.12f, 14, cor_alfa(COR_FALHA, 0.55f));
    ds_ret(r, bx0 + bw * 0.88f, topo, bw * 0.12f, 14, cor_alfa(COR_FALHA, 0.55f));
    wg_barra_centro(r, bx0, topo, bw, 14, limitar(j->inclinacao / 1.15f, -1, 1),
                    fabsf(j->inclinacao) > 1 ? COR_FALHA : COR_OURO);
    topo += 24;
  }
  if (p && p->cap_giro) {
    double hz = taxa_hz_host(&p->taxa_giro, SDL_GetTicksNS(), 1.0);
    texto_al(r, F_MINI, f.x + f.w / 2, topo, COR_TEXTO_3, ALINHA_CENTRO,
             fmt("giroscópio %.0f Hz · inclinação %s", hz, wg_graus(p->postura.rolagem)));
  } else if (p) {
    texto_al(r, F_MINI, f.x + f.w / 2, topo, COR_AVISO, ALINHA_CENTRO, "sem giroscópio: a sala joga com os analógicos");
  }
  if (j->quedas)
    texto(r, F_PEQUENA, f.x + 80, f.y + 30, COR_TEXTO_2, fmt("quedas: %d", j->quedas));
}

static void desenhar(App *a) {
  SDL_Renderer *r = a->r;
  ds_fundo(r, a->t, 0.5f);
  sb_desenhar_topo(a, &g_b);
  for (int i = 0; i < g_n_faixas; i++) {
    int s = g_slot_faixa[i];
    SDL_FRect f = g_faixa[i];
    Pad *p = pads_do_slot(a, s);
    sb_moldura(a, f, s, g_b.acabou[s] ? 0.8f : 0.2f);
    desenhar_faixa(a, s, &g_j[s], p, f);
    sb_escudo(a, f, s);
    texto_al(r, F_GRANDE_N, f.x + f.w - 28, f.y + 14, COR_TEXTO, ALINHA_DIR, fmt("%d", g_b.pontos[s]));
    if (!p)
      sb_sem_controle(a, f, s);
  }
  particulas_desenhar(r, &a->brasas);
  if (g_b.fase == FASE_AVISO)
    sb_desenhar_aviso(a, &g_b,
                      "Três trechos. Na viga, o vento empurra: incline o controle para o outro lado.\n"
                      "Nos sinos, gire o controle para mirar e arremesse com {R1} ({L1} centraliza).\n"
                      "Na pedra, dê uma martelada: sacuda o controle para baixo, com vontade.");
  else if (g_b.fase == FASE_FIM)
    sb_desenhar_fim(a, &g_b);
  else {
    Dica d[] = {{IC_OPTIONS, "pausa"}};
    wg_rodape(r, d, 1);
  }
  pausa_desenhar(a);
}

const Cena CENA_VIGA = {"viga", entrar, sair, NULL, atualizar, desenhar};
