/* A Galeria — armas com gatilho adaptativo (ADR-002).
 *
 * O padrão é o dos jogos de tiro do PS5: cada arma tem o seu gatilho. A
 * pistola tem parede e clique (Weapon), a metralhadora treme (Vibration), o
 * arco pesa (Feedback); sem arma, o gatilho fica solto (Off). A munição fica
 * nas cinco luzinhas brancas embaixo do touchpad (os LEDs de jogador), e
 * quando ela acaba o gatilho solta — "clique seco" — até recarregar.
 *
 * E é uma prova às cegas (cegas.h): a arma chega no escuro. A pessoa aperta R2,
 * sente, e diz qual é (✕ pistola, ○ metralhadora, □ arco, △ sem arma) antes
 * de ver. No fim de cada rodada, o armeiro recarrega sem ninguém ver, e a
 * pessoa diz quantas balas tem contando as luzinhas do controle — a tela não
 * mostra. Só os quatro modos oficiais entram (CONTRATO.md). */
#include "sala_base.h"

#include "../cenas/pausa.h"
#include "../nucleo/cegas.h"
#include "../nucleo/simulador.h"
#include "../ui/desenho.h"
#include "../ui/icones.h"
#include "../ui/tema.h"
#include "../ui/texto.h"
#include "../ui/widgets.h"

#include <math.h>
#include <stdio.h>

#define PI_F 3.14159265f
#define VEZES 2          /* rodadas de cada arma no plano */
#define MAX_RODADAS 16
#define MAX_EXTRAS 4     /* rodadas de desempate */
#define IDENTIFICA_MAX 14.0f
#define REVELA 1.0f
#define ATIRA 5.5f
#define MUNICAO_MAX 9.0f
#define N_ALVOS 3
#define BALAS 5
#define BALAS_MG 30

typedef enum Passo { G_IDENTIFICAR = 0, G_REVELA, G_ATIRAR, G_MUNICAO, G_MUNICAO_RESP, G_PRONTO } Passo;

typedef struct Alvo {
  float x, y, v; /* relativos à galeria, 0..1 */
  bool vivo;
  float quebra;
} Alvo;

typedef struct Jogador {
  Arma plano[MAX_RODADAS];
  int n_plano, rodada, extras;
  Passo passo;
  float t;
  Arma arma;
  bool puxou;
  int resposta;
  int balas, balas_mg;
  float recarga;
  float mira_x, mira_y;
  Alvo alvo[N_ALVOS];
  float cadencia, corda;
  bool armado;
  int acertos;
  float recuo, clarao;
  Cega cega[ARMA_TOTAL];
  Cega leds;
  int leds_pedido, leds_resposta, opcoes[4];
  bool efeito_ok, leds_ok;
  bool comecou;
  /* o robô */
  float robo_t, robo_r2;
  int robo_passo;
} Jogador;

static const Feature FEATS[] = {F_GATILHO_RESISTENCIA, F_GATILHO_ARMA, F_GATILHO_VIBRACAO, F_LEDS_JOGADOR};
static const SDL_GamepadButton BOTAO_OPCAO[4] = {SDL_GAMEPAD_BUTTON_SOUTH, SDL_GAMEPAD_BUTTON_EAST,
                                                 SDL_GAMEPAD_BUTTON_WEST, SDL_GAMEPAD_BUTTON_NORTH};
static const Icone ICONE_OPCAO[4] = {IC_CRUZ, IC_CIRCULO, IC_QUADRADO, IC_TRIANGULO};

static SalaBase g_b;
static Jogador g_j[MAX_JOGADORES];
static SDL_FRect g_faixa[MAX_JOGADORES];
static int g_slot_faixa[MAX_JOGADORES], g_n_faixas;
static const SDL_FRect AREA = {40, 140, TELA_L - 80, TELA_A - 140 - 96};

/* ---------- as saídas ---------- */

static ForjaTrigger gatilho_da_arma(Arma a) {
  switch (a) {
  case ARMA_PISTOLA:
    return (ForjaTrigger){FORJA_TRIGGER_WEAPON, 2, 6, 8};
  case ARMA_METRALHADORA:
    return (ForjaTrigger){FORJA_TRIGGER_VIBRATION, 0, 7, 30};
  case ARMA_ARCO:
    return (ForjaTrigger){FORJA_TRIGGER_FEEDBACK, 1, 6, 0};
  default:
    return (ForjaTrigger){FORJA_TRIGGER_OFF, 0, 0, 0};
  }
}

static void armar(App *a, int s, Arma arma) {
  Pad *p = pads_do_slot(a, s);
  if (p && pad_gatilho(a, p, 1, gatilho_da_arma(arma)))
    g_j[s].efeito_ok = true;
}

static void leds(App *a, int s, int n) {
  Pad *p = pads_do_slot(a, s);
  if (p && pad_leds_jogador(a, p, n > 0 ? (1 << (n > 5 ? 5 : n)) - 1 : 0))
    g_j[s].leds_ok = true;
}

static int luzes_da_mg(int balas) { return (balas + 5) / 6; }

/* ---------- a sala ---------- */

static void sortear_alvos(Jogador *j) {
  for (int k = 0; k < N_ALVOS; k++) {
    j->alvo[k].x = sorteio_real(&g_b.sorteio);
    j->alvo[k].y = 0.18f + 0.3f * k;
    j->alvo[k].v = (0.18f + 0.18f * sorteio_real(&g_b.sorteio)) * (k % 2 ? -1 : 1);
    j->alvo[k].vivo = true;
    j->alvo[k].quebra = 0;
  }
}

static void nova_rodada(App *a, int s, Jogador *j) {
  j->arma = j->plano[j->rodada];
  j->passo = G_IDENTIFICAR;
  j->t = 0;
  j->puxou = false;
  j->resposta = -1;
  j->robo_passo = 0;
  j->robo_t = 0;
  armar(a, s, j->arma);
  Pad *p = pads_do_slot(a, s);
  if (p)
    pad_leds_do_slot(a, p); /* na identificação, as luzinhas não contam nada */
  Evento ev;
  ev_iniciar(&ev, &a->lt, "jogo", s + 1);
  ev_str(&ev, "sala", "galeria");
  ev_str(&ev, "o", "arma_no_escuro");
  ev_str(&ev, "arma", cegas_nome_arma(j->arma));
  ev_fim(&ev, &a->lt);
}

static void entrar(App *a) {
  sb_entrar(a, &g_b, SALA_GALERIA, FEATS, 4, 0);
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Jogador *j = &g_j[s];
    SDL_memset(j, 0, sizeof(*j));
    j->n_plano = cegas_plano_armas(&g_b.sorteio, VEZES, j->plano, MAX_RODADAS - MAX_EXTRAS);
    for (int k = 0; k < ARMA_TOTAL; k++)
      cega_zerar(&j->cega[k]);
    cega_zerar(&j->leds);
    j->mira_x = 0.5f;
    j->mira_y = 0.5f;
    j->resposta = j->leds_resposta = -1;
    sortear_alvos(j);
  }
}

static void sair(App *a) { pads_silencio_todos(a); }

static void atirar(App *a, int s, Jogador *j, SDL_FRect f) {
  j->recuo = 1;
  j->clarao = 1;
  bool acertou = false;
  for (int k = 0; k < N_ALVOS; k++) {
    Alvo *al = &j->alvo[k];
    if (!al->vivo)
      continue;
    float dx = (al->x - j->mira_x) * 1.4f, dy = al->y - j->mira_y;
    if (dx * dx + dy * dy < 0.09f * 0.09f) {
      al->vivo = false;
      al->quebra = 1;
      acertou = true;
      j->acertos++;
      sb_pontos(a, &g_b, s, 50);
      particulas_faiscas(&a->brasas, f.x + 30 + al->x * (f.w - 60), f.y + 116 + al->y * f.h * 0.40f, 18, COR_OURO, 0.8f);
      break;
    }
  }
  som_evento_pan(&a->som, acertou ? SOM_BIGORNA_AGUDA : SOM_TICK, acertou ? 0.6f : 0.35f, sb_pan(f));
  if (j->arma == ARMA_METRALHADORA) {
    j->balas_mg--;
    int antes = luzes_da_mg(j->balas_mg + 1), agora = luzes_da_mg(j->balas_mg);
    if (agora != antes)
      leds(a, s, agora);
    if (j->balas_mg <= 0)
      armar(a, s, ARMA_NENHUMA); /* sem munição, o gatilho solta */
  } else {
    j->balas--;
    leds(a, s, j->balas);
    if (j->balas <= 0)
      armar(a, s, ARMA_NENHUMA);
  }
}

static bool vazia(const Jogador *j) { return j->arma == ARMA_METRALHADORA ? j->balas_mg <= 0 : j->balas <= 0; }

static void perguntar_municao(App *a, int s, Jogador *j) {
  /* o armeiro recarregou no escuro: quantas balas há agora? */
  int n = sorteio_entre(&g_b.sorteio, 1, 5);
  j->leds_pedido = n;
  j->leds_resposta = -1;
  int pos = sorteio_entre(&g_b.sorteio, 0, 3);
  int usados[6] = {0};
  usados[n] = 1;
  for (int k = 0; k < 4; k++) {
    if (k == pos) {
      j->opcoes[k] = n;
      continue;
    }
    int o;
    do
      o = sorteio_entre(&g_b.sorteio, 1, 5);
    while (usados[o]);
    usados[o] = 1;
    j->opcoes[k] = o;
  }
  leds(a, s, n);
  armar(a, s, ARMA_NENHUMA);
  j->passo = G_MUNICAO;
  j->t = 0;
  Evento ev;
  ev_iniciar(&ev, &a->lt, "jogo", s + 1);
  ev_str(&ev, "sala", "galeria");
  ev_str(&ev, "o", "pergunta_municao");
  ev_int(&ev, "luzes", n);
  ev_fim(&ev, &a->lt);
}

static void responder_arma(App *a, int s, Jogador *j, int resposta, SDL_FRect f) {
  j->resposta = resposta;
  Cega *c = &j->cega[j->arma];
  const char *res;
  if (resposta < 0) {
    cega_perdido(c);
    res = "perdido";
  } else if (resposta == (int)j->arma) {
    cega_certo(c);
    sb_pontos(a, &g_b, s, 150);
    res = "certo";
  } else {
    cega_errado(c, resposta);
    res = "errado";
  }
  Evento ev;
  ev_iniciar(&ev, &a->lt, "jogo", s + 1);
  ev_str(&ev, "sala", "galeria");
  ev_str(&ev, "o", "resposta_arma");
  ev_str(&ev, "resultado", res);
  ev_fim(&ev, &a->lt);
  som_evento_pan(&a->som, resposta == (int)j->arma ? SOM_CONFIRMA : SOM_FALHA, 0.5f, sb_pan(f));
  j->passo = G_REVELA;
  j->t = 0;
}

static void proxima_rodada(App *a, int s, Jogador *j) {
  j->rodada++;
  if (j->rodada >= j->n_plano) {
    /* desempate: a arma que ficou no meio do caminho ganha mais uma rodada */
    for (int k = 0; k < ARMA_TOTAL && j->extras < MAX_EXTRAS && j->n_plano < MAX_RODADAS; k++)
      if (k != ARMA_NENHUMA && !cega_arma_decidida(&j->cega[k]) && cega_total(&j->cega[k]) > 0 &&
          (j->n_plano == 0 || j->plano[j->n_plano - 1] != (Arma)k)) {
        j->plano[j->n_plano++] = (Arma)k;
        j->extras++;
      }
  }
  if (j->rodada >= j->n_plano) {
    j->passo = G_PRONTO;
    g_b.acabou[s] = true;
    armar(a, s, ARMA_NENHUMA);
    Pad *p = pads_do_slot(a, s);
    if (p)
      pad_leds_do_slot(a, p);
    return;
  }
  nova_rodada(a, s, j);
}

static void jogar(App *a, int s, Jogador *j, Pad *p, SDL_FRect f, float dt) {
  j->t += dt;
  j->recuo = aproximar(j->recuo, 0, 6, dt);
  j->clarao = aproximar(j->clarao, 0, 10, dt);
  float r2 = p->ax[SDL_GAMEPAD_AXIS_RIGHT_TRIGGER];
  switch (j->passo) {
  case G_IDENTIFICAR:
    if (r2 >= 0.25f)
      j->puxou = true;
    if (j->puxou && j->t > 0.4f)
      for (int k = 0; k < 4; k++)
        if (pad_apertou(p, BOTAO_OPCAO[k])) {
          responder_arma(a, s, j, k, f);
          return;
        }
    if (j->t > IDENTIFICA_MAX)
      responder_arma(a, s, j, -1, f);
    break;
  case G_REVELA:
    if (j->t >= REVELA) {
      if (j->arma == ARMA_NENHUMA) {
        perguntar_municao(a, s, j);
      } else {
        j->passo = G_ATIRAR;
        j->t = 0;
        j->balas = BALAS;
        j->balas_mg = BALAS_MG;
        j->armado = true;
        j->corda = 0;
        leds(a, s, j->arma == ARMA_METRALHADORA ? luzes_da_mg(j->balas_mg) : j->balas);
        sortear_alvos(j);
      }
    }
    break;
  case G_ATIRAR: {
    j->mira_x = limitar(j->mira_x + p->ax[SDL_GAMEPAD_AXIS_LEFTX] * 1.1f * dt, 0, 1);
    j->mira_y = limitar(j->mira_y + p->ax[SDL_GAMEPAD_AXIS_LEFTY] * 1.1f * dt, 0, 1);
    for (int k = 0; k < N_ALVOS; k++) {
      Alvo *al = &j->alvo[k];
      al->x += al->v * dt;
      if (al->x < 0.05f || al->x > 0.95f)
        al->v = -al->v;
      al->x = limitar(al->x, 0.05f, 0.95f);
      if (!al->vivo) {
        al->quebra -= dt;
        if (al->quebra < -0.8f) {
          al->vivo = true;
          al->x = sorteio_real(&g_b.sorteio);
        }
      }
    }
    if (j->recarga > 0) {
      j->recarga -= dt;
      if (j->recarga <= 0) {
        j->balas = BALAS;
        j->balas_mg = BALAS_MG;
        leds(a, s, j->arma == ARMA_METRALHADORA ? luzes_da_mg(j->balas_mg) : j->balas);
        armar(a, s, j->arma);
        som_evento_pan(&a->som, SOM_CONFIRMA, 0.4f, sb_pan(f));
      }
    } else if (vazia(j)) {
      if (pad_apertou(p, SDL_GAMEPAD_BUTTON_WEST))
        j->recarga = 0.8f;
    } else {
      switch (j->arma) {
      case ARMA_PISTOLA: /* dispara ao passar do clique; rearma ao soltar */
        if (j->armado && r2 >= 0.62f) {
          j->armado = false;
          atirar(a, s, j, f);
        } else if (r2 <= 0.3f) {
          j->armado = true;
        }
        break;
      case ARMA_METRALHADORA:
        j->cadencia -= dt;
        if (r2 >= 0.35f && j->cadencia <= 0) {
          j->cadencia = 0.09f;
          atirar(a, s, j, f);
        }
        break;
      case ARMA_ARCO: /* puxar contra a resistência, soltar para disparar */
        if (r2 >= 0.15f)
          j->corda = fmaxf(j->corda, r2);
        else if (j->corda > 0.55f) {
          atirar(a, s, j, f);
          j->corda = 0;
        } else {
          j->corda = 0;
        }
        break;
      default:
        break;
      }
    }
    if (j->t >= ATIRA)
      perguntar_municao(a, s, j);
    break;
  }
  case G_MUNICAO:
    if (j->t > 0.5f)
      for (int k = 0; k < 4; k++)
        if (pad_apertou(p, BOTAO_OPCAO[k])) {
          j->leds_resposta = k;
          break;
        }
    if (j->leds_resposta >= 0 || j->t > MUNICAO_MAX) {
      const char *res;
      if (j->leds_resposta < 0) {
        cega_perdido(&j->leds);
        res = "perdido";
      } else if (j->opcoes[j->leds_resposta] == j->leds_pedido) {
        cega_certo(&j->leds);
        sb_pontos(a, &g_b, s, 100);
        res = "certo";
      } else {
        cega_errado(&j->leds, j->opcoes[j->leds_resposta]);
        res = "errado";
      }
      Evento ev;
      ev_iniciar(&ev, &a->lt, "jogo", s + 1);
      ev_str(&ev, "sala", "galeria");
      ev_str(&ev, "o", "resposta_municao");
      ev_str(&ev, "resultado", res);
      ev_fim(&ev, &a->lt);
      j->passo = G_MUNICAO_RESP;
      j->t = 0;
    }
    break;
  case G_MUNICAO_RESP:
    if (j->t >= REVELA)
      proxima_rodada(a, s, j);
    break;
  case G_PRONTO:
    break;
  }
}

/* ---------- o robô: sente o gatilho, vê a galeria e conta as luzinhas ---------- */

static Arma arma_sentida(const Percepcao *pc) {
  switch (pc->gatilho_dir[0]) {
  case FORJA_HID_TRIGGER_WEAPON:
    return ARMA_PISTOLA;
  case FORJA_HID_TRIGGER_VIBRATION:
    return ARMA_METRALHADORA;
  case FORJA_HID_TRIGGER_FEEDBACK:
    return ARMA_ARCO;
  default:
    return ARMA_NENHUMA;
  }
}

static int luzes_acesas(int mascara) {
  int n = 0;
  for (int i = 0; i < 5; i++)
    n += (mascara >> i) & 1;
  return n;
}

static void robo(App *a, int s, Jogador *j, Pad *p, float dt) {
  (void)s;
  const Percepcao *pc = simulador_percepcao(p->id);
  if (!pc)
    return;
  int idx = (int)(p - a->pads.pad);
  j->robo_t += dt;
  float alvo_r2 = 0;
  switch (j->passo) {
  case G_IDENTIFICAR:
    /* aperta, sente, solta e responde */
    if (j->robo_t > 0.35f && j->robo_t < 1.1f)
      alvo_r2 = 0.72f;
    if (j->robo_t > 1.4f && j->robo_passo == 0) {
      robo_apertar(a, idx, BOTAO_OPCAO[arma_sentida(pc)], 0.08f);
      j->robo_passo = 1;
    }
    break;
  case G_ATIRAR: {
    if (vazia(j) && j->recarga <= 0) {
      if (j->robo_passo != 7) {
        robo_apertar(a, idx, SDL_GAMEPAD_BUTTON_WEST, 0.08f);
        j->robo_passo = 7;
      }
      break;
    }
    if (j->robo_passo == 7 && !vazia(j))
      j->robo_passo = 0;
    int alvo = -1;
    for (int k = 0; k < N_ALVOS; k++)
      if (j->alvo[k].vivo) {
        alvo = k;
        break;
      }
    if (alvo < 0)
      break;
    float dx = j->alvo[alvo].x - j->mira_x, dy = j->alvo[alvo].y - j->mira_y;
    robo_eixo(a, idx, SDL_GAMEPAD_AXIS_LEFTX, limitar(dx * 8, -1, 1), 0.06f);
    robo_eixo(a, idx, SDL_GAMEPAD_AXIS_LEFTY, limitar(dy * 8, -1, 1), 0.06f);
    bool perto = dx * dx * 1.96f + dy * dy < 0.05f * 0.05f;
    switch (j->arma) {
    case ARMA_PISTOLA:
      alvo_r2 = perto && fmodf(j->robo_t, 0.4f) < 0.2f ? 0.85f : 0;
      break;
    case ARMA_METRALHADORA:
      alvo_r2 = perto ? 0.6f : 0;
      break;
    case ARMA_ARCO:
      alvo_r2 = perto && j->corda > 0.8f ? 0 : 0.9f;
      break;
    default:
      break;
    }
    break;
  }
  case G_MUNICAO:
    if (j->robo_passo != 3) {
      j->robo_t = 0;
      j->robo_passo = 3;
    }
    if (j->robo_t > 0.7f && j->leds_resposta < 0) {
      int n = luzes_acesas(pc->leds_jogador);
      int escolha = 0;
      for (int k = 0; k < 4; k++)
        if (j->opcoes[k] == n)
          escolha = k;
      robo_apertar(a, idx, BOTAO_OPCAO[escolha], 0.08f);
      j->robo_t = -100;
    }
    break;
  default:
    break;
  }
  j->robo_r2 = aproximar(j->robo_r2, alvo_r2, 9, dt);
  robo_eixo(a, idx, SDL_GAMEPAD_AXIS_RIGHT_TRIGGER, j->robo_r2, 0.06f);
}

static void atualizar(App *a, float dt) {
  int fase = sb_atualizar(a, &g_b, dt);
  g_n_faixas = sb_faixas(a, &g_b, FAIXAS_COLUNAS, AREA, g_faixa, g_slot_faixa);
  if (fase != FASE_JOGO)
    return;
  for (int i = 0; i < g_n_faixas; i++) {
    int s = g_slot_faixa[i];
    Pad *p = pads_do_slot(a, s);
    Jogador *j = &g_j[s];
    if (!p || g_b.acabou[s])
      continue;
    if (!j->comecou) {
      j->comecou = true;
      nova_rodada(a, s, j);
    }
    if (robo_ativo())
      robo(a, s, j, p, dt);
    jogar(a, s, j, p, g_faixa[i], dt);
  }
  if (sb_todos_acabaram(a, &g_b)) {
    for (int s = 0; s < MAX_JOGADORES; s++) {
      if (!g_b.jogando[s])
        continue;
      Jogador *j = &g_j[s];
      Veredito v = cega_arma_veredito(ARMA_ARCO, &j->cega[ARMA_ARCO], &j->cega[ARMA_NENHUMA], j->efeito_ok);
      sb_explica_recusa(a, s, &v);
      sb_veredito(&g_b, s, F_GATILHO_RESISTENCIA, &v);
      v = cega_arma_veredito(ARMA_PISTOLA, &j->cega[ARMA_PISTOLA], &j->cega[ARMA_NENHUMA], j->efeito_ok);
      sb_explica_recusa(a, s, &v);
      sb_veredito(&g_b, s, F_GATILHO_ARMA, &v);
      v = cega_arma_veredito(ARMA_METRALHADORA, &j->cega[ARMA_METRALHADORA], &j->cega[ARMA_NENHUMA], j->efeito_ok);
      sb_explica_recusa(a, s, &v);
      sb_veredito(&g_b, s, F_GATILHO_VIBRACAO, &v);
      v = cega_leds_veredito(&j->leds, j->leds_ok);
      sb_explica_recusa(a, s, &v);
      sb_veredito(&g_b, s, F_LEDS_JOGADOR, &v);
    }
    sb_terminar(a, &g_b, NIVEL_SAIU);
  }
}

/* ---------- desenho ---------- */

static void desenhar_arma(SDL_Renderer *r, Arma a, float cx, float cy, float esc, float recuo) {
  SDL_Color metal = {150, 140, 128, 255}, escuro = {70, 62, 56, 255}, madeira = {130, 86, 46, 255};
  cx -= recuo * 8 * esc;
  switch (a) {
  case ARMA_PISTOLA: {
    SDL_FPoint corpo[6] = {{cx - 60 * esc, cy - 20 * esc}, {cx + 60 * esc, cy - 20 * esc}, {cx + 60 * esc, cy},
                           {cx - 20 * esc, cy},            {cx - 30 * esc, cy + 48 * esc}, {cx - 60 * esc, cy + 48 * esc}};
    ds_poligono(r, corpo, 6, metal);
    ds_polilinha(r, corpo, 6, 2, escuro, true);
    ds_anel(r, cx - 8 * esc, cy + 12 * esc, 12 * esc, 3, escuro);
    break;
  }
  case ARMA_METRALHADORA:
    ds_ret(r, cx - 30 * esc, cy - 8 * esc, 110 * esc, 12 * esc, metal);
    ds_ret_arred(r, cx - 80 * esc, cy - 22 * esc, 70 * esc, 34 * esc, 6 * esc, escuro);
    ds_ret_arred(r, cx - 110 * esc, cy - 16 * esc, 36 * esc, 26 * esc, 5 * esc, madeira);
    ds_circulo(r, cx - 40 * esc, cy + 30 * esc, 22 * esc, escuro);
    ds_anel(r, cx - 40 * esc, cy + 30 * esc, 22 * esc, 3, metal);
    break;
  case ARMA_ARCO:
    ds_arco(r, cx + 30 * esc, cy, 70 * esc, 7 * esc, PI_F * 0.62f, PI_F * 1.38f, madeira);
    ds_linha(r, cx + 30 * esc + cosf(PI_F * 0.62f) * 70 * esc, cy + sinf(PI_F * 0.62f) * 70 * esc,
             cx + 30 * esc + cosf(PI_F * 1.38f) * 70 * esc, cy + sinf(PI_F * 1.38f) * 70 * esc, 2, COR_TEXTO_2);
    ds_linha(r, cx - 60 * esc, cy, cx + 70 * esc, cy, 3, madeira);
    SDL_FPoint ponta[3] = {{cx + 80 * esc, cy}, {cx + 62 * esc, cy - 8 * esc}, {cx + 62 * esc, cy + 8 * esc}};
    ds_poligono(r, ponta, 3, metal);
    break;
  default:
    texto_al(r, F_TEXTO_N, cx, cy - 16, COR_TEXTO_3, ALINHA_CENTRO, "mãos vazias");
    break;
  }
}

static void desenhar_faixa(App *a, int s, Jogador *j, Pad *p, SDL_FRect f) {
  SDL_Renderer *r = a->r;
  /* a galeria: a parede de madeira, os trilhos e os alvos */
  float gx = f.x + 30, gy = f.y + 116, gw = f.w - 60, gh = f.h * 0.40f;
  ds_ret_arred_grad(r, gx - 10, gy - 20, gw + 20, gh + 40, 10, (SDL_Color){74, 48, 30, 255}, (SDL_Color){40, 26, 16, 255});
  for (float yy = gy - 10; yy < gy + gh + 20; yy += 26)
    ds_linha(r, gx - 10, yy, gx + gw + 10, yy, 1, cor_alfa((SDL_Color){20, 12, 8, 255}, 0.5f));
  /* o toldo listrado da barraca, e as lâmpadas que correm em fila */
  int gomos = (int)(gw / 34) + 1;
  float gomo = (gw + 20) / gomos;
  for (int k = 0; k < gomos; k++) {
    float x0 = gx - 10 + k * gomo;
    SDL_Color c = k % 2 ? (SDL_Color){150, 36, 24, 255} : (SDL_Color){214, 190, 150, 255};
    ds_ret(r, x0, gy - 34, gomo, 16, c);
    SDL_FPoint ponta[3] = {{x0, gy - 18}, {x0 + gomo, gy - 18}, {x0 + gomo / 2, gy - 6}};
    ds_poligono(r, ponta, 3, c);
  }
  for (int k = 0; k < gomos; k++) {
    float bx = gx - 10 + (k + 0.5f) * gomo, by = gy + gh + 12;
    bool acesa = ((int)(a->t * 6) + k) % 3 == 0;
    if (acesa)
      ds_brilho(r, bx, by, 22, COR_OURO, 0.6f);
    ds_circulo(r, bx, by, 4, acesa ? cor_clarear(COR_OURO, 0.3f) : (SDL_Color){90, 70, 40, 255});
  }
  bool atirando = j->passo == G_ATIRAR;
  for (int k = 0; k < N_ALVOS; k++) {
    float ty = gy + j->alvo[k].y * gh;
    ds_ret(r, gx, ty + 22, gw, 4, (SDL_Color){90, 80, 70, 255});
    if (!atirando)
      continue;
    Alvo *al = &j->alvo[k];
    float tx = gx + al->x * gw;
    if (al->vivo) {
      ds_circulo(r, tx, ty, 22, (SDL_Color){200, 150, 70, 255});
      ds_anel(r, tx, ty, 16, 3, (SDL_Color){120, 40, 20, 255});
      ds_circulo(r, tx, ty, 6, (SDL_Color){150, 30, 20, 255});
    } else if (al->quebra > 0) {
      ds_brilho(r, tx, ty, 50 * al->quebra, COR_OURO, 0.6f * al->quebra);
    }
  }
  if (atirando) {
    float mx = gx + j->mira_x * gw, my = gy + j->mira_y * gh;
    ds_anel(r, mx, my, 18, 2.5f, COR_JOGADOR[s]);
    ds_linha(r, mx - 28, my, mx - 10, my, 2.5f, COR_JOGADOR[s]);
    ds_linha(r, mx + 10, my, mx + 28, my, 2.5f, COR_JOGADOR[s]);
    ds_linha(r, mx, my - 28, mx, my - 10, 2.5f, COR_JOGADOR[s]);
    ds_linha(r, mx, my + 10, mx, my + 28, 2.5f, COR_JOGADOR[s]);
    if (j->clarao > 0.05f)
      ds_brilho(r, mx, my, 40, COR_OURO, j->clarao);
  }

  /* a caixa da arma, embaixo */
  float cx = f.x + f.w / 2, cy = gy + gh + 150;
  bool escondida = j->passo == G_IDENTIFICAR;
  ds_ret_arred_grad(r, cx - 150, cy - 70, 300, 140, 14, (SDL_Color){62, 44, 30, 255}, (SDL_Color){34, 24, 16, 255});
  ds_contorno_arred(r, cx - 150, cy - 70, 300, 140, 14, 2, COR_BRONZE_ESCURO);
  if (escondida) {
    texto_al(r, F_ENORME_N, cx, cy - 46, COR_TEXTO_3, ALINHA_CENTRO, "?");
  } else if (j->passo != G_PRONTO) {
    desenhar_arma(r, j->arma, cx, cy - 8, 1.0f, j->recuo);
  } else {
    icone(r, IC_OK, cx, cy, 70, COR_OK, 0);
  }
  /* o curso do R2, sem dizer o modo */
  float r2 = p ? p->ax[SDL_GAMEPAD_AXIS_RIGHT_TRIGGER] : 0;
  icone_natural(r, IC_R2, cx + 190, cy - 52, 34, 0);
  ds_ret_arred(r, cx + 178, cy - 30, 24, 100, 8, cor_alfa(COR_FUNDO_0, 0.85f));
  ds_ret_arred(r, cx + 181, cy - 27 + 94 * (1 - r2), 18, 94 * r2, 6, COR_BRASA);

  /* a linha do que fazer, e as perguntas */
  float ly = cy + 96;
  Fonte fd = f.w < 520 ? F_PEQUENA_N : F_TEXTO_N;
  switch (j->passo) {
  case G_IDENTIFICAR:
    wg_texto_rico(r, fd, cx, ly, COR_TEXTO, ALINHA_CENTRO, j->puxou ? "que arma é esta?" : "aperte {R2} e sinta a arma");
    if (j->puxou)
      for (int k = 0; k < 4; k++) {
        float oy = ly + 44 + k * 38;
        icone_natural(r, ICONE_OPCAO[k], cx - 80, oy + 14, 30, 0);
        texto(r, F_PEQUENA_N, cx - 56, oy + 2, COR_TEXTO_2, cegas_nome_arma((Arma)k));
      }
    break;
  case G_REVELA: {
    bool acertou = j->resposta == (int)j->arma;
    texto_al(r, fd, cx, ly, acertou ? COR_OK : COR_FALHA, ALINHA_CENTRO,
             j->resposta < 0 ? fmt("sem resposta — era %s", cegas_nome_arma(j->arma))
             : acertou        ? fmt("isso: %s", cegas_nome_arma(j->arma))
                              : fmt("era %s", cegas_nome_arma(j->arma)));
    break;
  }
  case G_ATIRAR:
    if (j->recarga > 0)
      texto_al(r, fd, cx, ly, COR_TEXTO_2, ALINHA_CENTRO, "recarregando...");
    else if (vazia(j))
      wg_texto_rico(r, fd, cx, ly, COR_AVISO, ALINHA_CENTRO, "sem munição: {Q} recarrega");
    else
      wg_texto_rico(r, fd, cx, ly, COR_TEXTO, ALINHA_CENTRO, "{LE} mira · {R2} atira");
    texto_al(r, F_MINI, cx, ly + 40, COR_TEXTO_3, ALINHA_CENTRO, "a munição está nas luzinhas do controle");
    break;
  case G_MUNICAO:
  case G_MUNICAO_RESP:
    texto_al(r, fd, cx, ly, COR_TEXTO, ALINHA_CENTRO, "quantas balas restam?");
    texto_al(r, F_MINI, cx, ly + 36, COR_TEXTO_3, ALINHA_CENTRO, "conte as luzinhas embaixo do touchpad");
    for (int k = 0; k < 4; k++) {
      float ox = cx - 150 + k * 78, oy = ly + 66;
      bool escolhida = j->leds_resposta == k;
      bool certa = j->passo == G_MUNICAO_RESP && j->opcoes[k] == j->leds_pedido;
      if (escolhida)
        ds_ret_arred(r, ox - 4, oy - 4, 70, 56, 10, cor_alfa(COR_BRASA, 0.25f));
      if (certa)
        ds_contorno_arred(r, ox - 4, oy - 4, 70, 56, 10, 3, COR_OK);
      icone_natural(r, ICONE_OPCAO[k], ox + 16, oy + 24, 28, 0);
      texto(r, F_MEDIA_N, ox + 36, oy + 4, COR_TEXTO, fmt("%d", j->opcoes[k]));
    }
    break;
  case G_PRONTO:
    texto_al(r, fd, cx, ly, COR_OK, ALINHA_CENTRO, "galeria limpa!");
    break;
  }
  texto(r, F_PEQUENA, f.x + 80, f.y + 30, COR_TEXTO_2,
        fmt("rodada %d de %d", j->rodada + 1 > j->n_plano ? j->n_plano : j->rodada + 1, j->n_plano));
}

static void desenhar(App *a) {
  SDL_Renderer *r = a->r;
  ds_fundo(r, a->t, 0.4f);
  sb_desenhar_topo(a, &g_b);
  for (int i = 0; i < g_n_faixas; i++) {
    int s = g_slot_faixa[i];
    SDL_FRect f = g_faixa[i];
    Pad *p = pads_do_slot(a, s);
    sb_moldura(a, f, s, g_b.acabou[s] ? 0.8f : 0.2f);
    if (g_b.fase != FASE_AVISO)
      desenhar_faixa(a, s, &g_j[s], p, f);
    sb_escudo(a, f, s);
    texto_al(r, F_GRANDE_N, f.x + f.w - 28, f.y + 14, COR_TEXTO, ALINHA_DIR, fmt("%d", g_b.pontos[s]));
    if (!p)
      sb_sem_controle(a, f, s);
  }
  particulas_desenhar(r, &a->brasas);
  if (g_b.fase == FASE_AVISO)
    sb_desenhar_aviso(a, &g_b,
                      "A arma chega no escuro. Aperte {R2} e sinta: parede e clique é a pistola,\n"
                      "tremor é a metralhadora, peso é o arco, e solto é sem arma.\n"
                      "Diga qual é ({X} {O} {Q} {T}) e atire nos alvos: {LE} mira, {R2} atira.\n"
                      "A munição está nas luzinhas embaixo do touchpad — a tela não mostra.");
  else if (g_b.fase == FASE_FIM)
    sb_desenhar_fim(a, &g_b);
  else {
    Dica d[] = {{IC_R2, "sentir e atirar"}, {IC_QUADRADO, "recarregar"}, {IC_OPTIONS, "pausa"}};
    wg_rodape(r, d, 3);
  }
  pausa_desenhar(a);
}

const Cena CENA_GALERIA = {"galeria", entrar, sair, NULL, atualizar, desenhar};
