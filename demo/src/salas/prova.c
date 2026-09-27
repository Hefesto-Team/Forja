/* A Prova — duas equipes, tudo ligado (ADR-002).
 *
 * O padrão é o jogo de ação do PS5 inteiro de uma vez, que é onde um
 * intermediário se prova: noventa segundos de partida com tudo ligado ao mesmo
 * tempo, nos quatro controles —
 *
 *   - o analógico esquerdo anda; o direito e o giroscópio miram (L2 afina a
 *     mira, e o gatilho resiste); R2 atira, com a parede e o clique da arma;
 *   - a munição nas cinco luzinhas; vazia, o gatilho solta e o clique seco sai
 *     no alto-falante do controle; □ recarrega;
 *   - o tiro que vem da esquerda treme o motor da esquerda; a luz é a cor da
 *     equipe, pisca vermelho no golpe e apaga com a vida;
 *   - o passo no chão da arena (grama, cascalho, metal, água) nos atuadores;
 *   - ✕ corre; o clique do touchpad solta a martelada quando o sino do
 *     especial toca no controle de quem a carregou.
 *
 * A sala mede o que um jogo não mede: se, com tudo isso junto, a entrada
 * continuou chegando (o giroscópio sem buraco) e se o SDL aceitou todas as
 * saídas. No fim, a prova final às cegas: as luzinhas e a cor de cada
 * controle, depois de noventa segundos de carga. O microfone fica de fora: no
 * ar de uma sala, a voz de um é ouvida por todos (a Cripta mede em turnos). */
#include "sala_base.h"

#include "../cenas/pausa.h"
#include "../nucleo/cegas.h"
#include "../nucleo/chao.h"
#include "../nucleo/simulador.h"
#include "../som/sons_salas.h"
#include "../ui/automato.h"
#include "../ui/desenho.h"
#include "../ui/icones.h"
#include "../ui/tema.h"
#include "../ui/texto.h"
#include "../ui/widgets.h"

#include <math.h>
#include <stdio.h>

#define PI_F 3.14159265f
#define CONTAGEM_S 3.0f
#define PARTIDA_S 90.0f
#define VIDA_MAX 3
#define MUNICAO 5
#define RECARGA_S 1.0f
#define VOLTA_S 2.5f
#define TIRO_V 1150.0f
#define TIRO_VIDA 1.6f
#define RAIO 30.0f
#define MAX_TIROS 64
#define MAX_LUTADORES (MAX_JOGADORES + 2)
#define ESPECIAL_S 20.0f
#define MARTELADA_RAIO 240.0f
#define VEL 330.0f
#define PASSO_S 0.42f
#define PERGUNTA_ESPERA 1.0f
#define PERGUNTA_S 8.0f
#define PLACAR_S 3.0f
#define PILARES 4

typedef enum Etapa { PV_CONTAGEM = 0, PV_PARTIDA, PV_LEDS, PV_COR, PV_PLACAR, PV_ACABOU } Etapa;

typedef struct Lutador {
  bool ativo;
  int slot; /* -1: boneco de treino */
  int equipe;
  float x, y;
  float mira; /* rad; 0 = direita */
  float passo;
  int vida;
  float fora; /* > 0: derrubado, volta quando zera */
  float atordoado, dano;
  /* só dos jogadores */
  int municao;
  float recarga, corrida, corrida_espera;
  float especial; /* 0..1 */
  bool avisou;
  float passo_t, luz_pisca, pulso_t;
  int luz_estado; /* o que a luz mostra agora; -1 força reenviar */
  bool arma;      /* o R2 com o efeito de arma */
  float r2_ant;
  int acertos, derrubou;
  /* o boneco */
  float ia_t, ia_x, ia_y, tiro_t;
  /* o robô */
  float robo_tiro, robo_lado_t;
  int robo_lado;
  bool robo_recarregou;
} Lutador;

typedef struct Disparo {
  bool vivo;
  float x, y, vx, vy, vida;
  int dono; /* índice do lutador */
  int equipe;
} Disparo;

typedef struct Final {
  MedCarga carga;
  long giro_ult;
  Cega leds, cor;
  int leds_pedido, cor_pedida; /* -1: não perguntado (o SDL recusou) */
  int resp;
  float t;
  float robo_espera;
} Final;

typedef struct Cor {
  const char *nome;
  SDL_Color c;
} Cor;

static const Feature FEATS[] = {F_TUDO_JUNTO};
static const Cor CORES[4] = {
    {"âmbar", {255, 150, 0, 255}}, {"ciano", {0, 210, 255, 255}}, {"violeta", {170, 70, 255, 255}}, {"branco", {255, 255, 255, 255}}};
static const SDL_GamepadButton BOTAO[4] = {SDL_GAMEPAD_BUTTON_SOUTH, SDL_GAMEPAD_BUTTON_EAST, SDL_GAMEPAD_BUTTON_WEST,
                                           SDL_GAMEPAD_BUTTON_NORTH};
static const Icone ICONE[4] = {IC_CRUZ, IC_CIRCULO, IC_QUADRADO, IC_TRIANGULO};
/* as equipes: a cor na luz e a que a cor da prova final não pode lembrar */
static const char *NOME_EQUIPE[2] = {"Brasa", "Maré"};
static const SDL_Color LUZ_EQUIPE[2] = {{255, 70, 0, 255}, {0, 90, 255, 255}};
static const int COR_PARECIDA[2] = {0, 1}; /* a Brasa lembra âmbar; a Maré, ciano */
static const ForjaTrigger R2_ARMA = {FORJA_TRIGGER_WEAPON, 2, 6, 8};
static const ForjaTrigger L2_MIRA = {FORJA_TRIGGER_FEEDBACK, 2, 4, 0};
static const ForjaTrigger GATILHO_SOLTO = {FORJA_TRIGGER_OFF, 0, 0, 0};

static SalaBase g_b;
static Lutador g_l[MAX_LUTADORES];
static int g_n_lut;
static int g_lut_do_slot[MAX_JOGADORES];
static Disparo g_tiro[MAX_TIROS];
static Final g_f[MAX_JOGADORES];
static int g_placar[2];
static Etapa g_etapa;
static float g_t, g_tremor;
static bool g_comecou;
static const SDL_FRect ARENA = {70, 150, TELA_L - 140, TELA_A - 150 - 110};
static SDL_FPoint g_pilar[PILARES];
static const float RAIO_PILAR = 46;

/* ---------- a arena ---------- */

static int chao_em(float x, float y) {
  float cx = ARENA.x + ARENA.w / 2, cy = ARENA.y + ARENA.h / 2;
  for (int k = 0; k < PILARES; k++)
    if (hypotf(x - g_pilar[k].x, y - g_pilar[k].y) < RAIO_PILAR + 70)
      return CHAO_CASCALHO;
  if (fabsf(x - cx) < 230)
    return CHAO_METAL;
  if (fabsf(y - cy) < 60)
    return CHAO_AGUA;
  return CHAO_GRAMA;
}

static void base_da_equipe(int equipe, int ordem, float *x, float *y) {
  *x = equipe == 0 ? ARENA.x + 110 : ARENA.x + ARENA.w - 110;
  *y = ARENA.y + ARENA.h * (0.3f + 0.4f * (ordem % 2));
}

static void empurrar_dos_pilares(float *x, float *y) {
  for (int k = 0; k < PILARES; k++) {
    float dx = *x - g_pilar[k].x, dy = *y - g_pilar[k].y, d = hypotf(dx, dy), min = RAIO_PILAR + RAIO;
    if (d < min && d > 0.01f) {
      *x = g_pilar[k].x + dx / d * min;
      *y = g_pilar[k].y + dy / d * min;
    }
  }
  *x = limitar(*x, ARENA.x + RAIO, ARENA.x + ARENA.w - RAIO);
  *y = limitar(*y, ARENA.y + RAIO, ARENA.y + ARENA.h - RAIO);
}

/* ---------- as saídas, contadas para o veredito ---------- */

static void contar(int s, bool ok) {
  if (s < 0)
    return;
  g_f[s].carga.saidas++;
  if (!ok)
    g_f[s].carga.recusadas++;
}

static int mascara_de(int n) { return n <= 0 ? 0 : (1 << (n > 5 ? 5 : n)) - 1; }

static void mostrar_municao(App *a, Lutador *l) {
  Pad *p = pads_do_slot(a, l->slot);
  if (p)
    contar(l->slot, pad_leds_jogador(a, p, mascara_de(l->municao)));
}

static void armar(App *a, Lutador *l, bool arma) {
  Pad *p = pads_do_slot(a, l->slot);
  if (!p || l->arma == arma)
    return;
  l->arma = arma;
  contar(l->slot, pad_gatilho(a, p, 1, arma ? R2_ARMA : GATILHO_SOLTO));
}

/* A luz: a cor da equipe, mais fraca com a vida; o vermelho do golpe; o pulso
 * de quem está por um fio; escura derrubado. Só sai quando muda. */
static void atualizar_luz(App *a, Lutador *l, float dt) {
  Pad *p = pads_do_slot(a, l->slot);
  if (!p)
    return;
  l->luz_pisca = fmaxf(0, l->luz_pisca - dt);
  l->pulso_t += dt;
  int estado;
  SDL_Color c = LUZ_EQUIPE[l->equipe];
  float k;
  if (l->fora > 0) {
    estado = 10;
    k = 0.04f;
  } else if (l->luz_pisca > 0) {
    estado = 11;
    c = (SDL_Color){255, 0, 0, 255};
    k = 1;
  } else if (l->vida <= 1) {
    int fase = (int)(l->pulso_t * 4) % 2;
    estado = 20 + fase;
    k = fase ? 0.25f : 0.06f;
  } else {
    estado = l->vida;
    k = l->vida >= 3 ? 1.0f : 0.45f;
  }
  if (estado == l->luz_estado)
    return;
  l->luz_estado = estado;
  SDL_Color f = {(Uint8)(c.r * k), (Uint8)(c.g * k), (Uint8)(c.b * k), 255};
  contar(l->slot, pad_luz(a, p, f));
}

static void voltar(App *a, Lutador *l) {
  int ordem = 0;
  for (int i = 0; i < g_n_lut; i++)
    if (&g_l[i] != l && g_l[i].equipe == l->equipe && g_l[i].ativo)
      ordem++;
  base_da_equipe(l->equipe, ordem + (int)(g_t * 3) % 2, &l->x, &l->y);
  l->vida = VIDA_MAX;
  l->fora = l->atordoado = 0;
  l->mira = l->equipe == 0 ? 0 : PI_F;
  if (l->slot >= 0) {
    l->municao = MUNICAO;
    l->recarga = 0;
    l->luz_estado = -1;
    l->arma = false;
    armar(a, l, true);
    mostrar_municao(a, l);
  }
}

/* ---------- entrar e começar ---------- */

static void entrar(App *a) {
  sb_entrar(a, &g_b, SALA_PROVA, FEATS, 1, 0);
  somc_preparar(a);
  SDL_memset(g_l, 0, sizeof(g_l));
  SDL_memset(g_tiro, 0, sizeof(g_tiro));
  SDL_memset(g_f, 0, sizeof(g_f));
  g_n_lut = 0;
  g_placar[0] = g_placar[1] = 0;
  g_etapa = PV_CONTAGEM;
  g_t = g_tremor = 0;
  g_comecou = false;
  float cx = ARENA.x + ARENA.w / 2, cy = ARENA.y + ARENA.h / 2;
  g_pilar[0] = (SDL_FPoint){cx - 330, cy - 200};
  g_pilar[1] = (SDL_FPoint){cx + 330, cy - 200};
  g_pilar[2] = (SDL_FPoint){cx - 330, cy + 200};
  g_pilar[3] = (SDL_FPoint){cx + 330, cy + 200};
  for (int s = 0; s < MAX_JOGADORES; s++)
    g_lut_do_slot[s] = -1;
}

static void sair(App *a) {
  for (int s = 0; s < MAX_JOGADORES; s++)
    somc_parar_tudo(a, s);
  pads_silencio_todos(a);
}

/* As equipes: quatro, dois contra dois (P1 e P2 contra P3 e P4); três, dois
 * contra um e um boneco de treino; dois, um contra um; sozinho, contra dois
 * bonecos. */
static void comecar(App *a) {
  int slots[MAX_JOGADORES], n = 0;
  for (int s = 0; s < MAX_JOGADORES; s++)
    if (g_b.jogando[s])
      slots[n++] = s;
  int por_equipe[2] = {0, 0};
  for (int i = 0; i < n; i++) {
    int equipe = n == 4 ? (i < 2 ? 0 : 1) : n == 3 ? (i < 2 ? 0 : 1) : (i % 2);
    Lutador *l = &g_l[g_n_lut];
    l->ativo = true;
    l->slot = slots[i];
    l->equipe = equipe;
    g_lut_do_slot[slots[i]] = g_n_lut;
    g_n_lut++;
    por_equipe[equipe]++;
    Pad *p = pads_do_slot(a, slots[i]);
    med_carga_zerar(&g_f[slots[i]].carga, p && p->cap_giro);
    g_f[slots[i]].giro_ult = p ? (long)p->taxa_giro.total : 0;
    cega_zerar(&g_f[slots[i]].leds);
    cega_zerar(&g_f[slots[i]].cor);
    g_f[slots[i]].leds_pedido = g_f[slots[i]].cor_pedida = -1;
  }
  /* os bonecos equilibram a arena: sozinho, dois; com três jogadores, um */
  int bonecos = n == 1 ? 2 : n == 3 ? 1 : 0;
  for (int k = 0; k < bonecos && g_n_lut < MAX_LUTADORES; k++) {
    Lutador *l = &g_l[g_n_lut++];
    l->ativo = true;
    l->slot = -1;
    l->equipe = 1;
  }
  (void)por_equipe;
  for (int i = 0; i < g_n_lut; i++) {
    Lutador *l = &g_l[i];
    voltar(a, l);
    if (l->slot >= 0) {
      Pad *p = pads_do_slot(a, l->slot);
      if (p)
        contar(l->slot, pad_gatilho(a, p, 0, L2_MIRA));
    }
  }
  g_comecou = true;
}

/* ---------- a partida ---------- */

static void atirar(App *a, int i, float ang) {
  Lutador *l = &g_l[i];
  for (int k = 0; k < MAX_TIROS; k++) {
    Disparo *t = &g_tiro[k];
    if (t->vivo)
      continue;
    t->vivo = true;
    t->x = l->x + cosf(ang) * 40;
    t->y = l->y + sinf(ang) * 40;
    t->vx = cosf(ang) * TIRO_V;
    t->vy = sinf(ang) * TIRO_V;
    t->vida = TIRO_VIDA;
    t->dono = i;
    t->equipe = l->equipe;
    break;
  }
  float pan = (l->x - ARENA.x) / ARENA.w * 2 - 1;
  som_evento_pan(&a->som, SOM_BIGORNA_AGUDA, l->slot >= 0 ? 0.22f : 0.12f, pan);
}

static void golpe(App *a, Lutador *alvo, int autor, float vx) {
  alvo->vida--;
  alvo->dano = 1;
  Lutador *quem = &g_l[autor];
  if (quem->slot >= 0) {
    quem->acertos++;
    quem->especial = fminf(1, quem->especial + 0.12f);
    sb_pontos(a, &g_b, quem->slot, 50);
    g_f[quem->slot].carga.acertos++;
  }
  if (alvo->slot >= 0) {
    /* o tiro que anda para a direita veio da esquerda: o motor da esquerda */
    Pad *p = pads_do_slot(a, alvo->slot);
    bool da_esquerda = vx > 0;
    if (p)
      contar(alvo->slot, pad_rumble(a, p, da_esquerda ? 1.0f : 0, da_esquerda ? 0 : 1.0f, 220));
    alvo->luz_pisca = 0.16f;
  }
  if (alvo->vida <= 0) {
    alvo->fora = VOLTA_S;
    g_placar[quem->equipe]++;
    if (quem->slot >= 0) {
      quem->derrubou++;
      sb_pontos(a, &g_b, quem->slot, 150);
      g_f[quem->slot].carga.derrubadas++;
    }
    particulas_brasas(&a->brasas, alvo->x, alvo->y, 26, LUZ_EQUIPE[alvo->equipe]);
    som_evento(&a->som, SOM_MARTELO, 0.4f);
    if (alvo->slot >= 0) {
      armar(a, alvo, false);
      alvo->municao = 0;
      mostrar_municao(a, alvo);
    }
  }
}

static void martelada(App *a, int i) {
  Lutador *l = &g_l[i];
  l->especial = 0;
  l->avisou = false;
  g_tremor = 0.5f;
  particulas_brasas(&a->brasas, l->x, l->y, 40, COR_OURO);
  som_evento(&a->som, SOM_MARTELO, 0.8f);
  Pad *pl = pads_do_slot(a, l->slot);
  if (pl)
    contar(l->slot, pad_rumble(a, pl, 0.6f, 0.6f, 150));
  for (int k = 0; k < g_n_lut; k++) {
    Lutador *o = &g_l[k];
    if (!o->ativo || o->equipe == l->equipe || o->fora > 0 || hypotf(o->x - l->x, o->y - l->y) > MARTELADA_RAIO)
      continue;
    o->atordoado = 1.2f;
    Pad *po = pads_do_slot(a, o->slot);
    if (po)
      contar(o->slot, pad_rumble(a, po, 1.0f, 1.0f, 380));
    golpe(a, o, i, o->x - l->x);
  }
}

static void jogador(App *a, int i, Pad *p, float dt) {
  Lutador *l = &g_l[i];
  int s = l->slot;
  const SonsSalas *so = sons_salas();
  l->corrida = fmaxf(0, l->corrida - dt);
  l->corrida_espera = fmaxf(0, l->corrida_espera - dt);
  float r2 = p->ax[SDL_GAMEPAD_AXIS_RIGHT_TRIGGER];
  bool apertou_r2 = r2 > 0.6f && l->r2_ant <= 0.6f;
  l->r2_ant = r2;
  if (l->fora > 0 || l->atordoado > 0)
    return;
  /* andar: o analógico esquerdo; L2 afina (e anda devagar); ✕ corre */
  float lx = p->ax[SDL_GAMEPAD_AXIS_LEFTX], ly = p->ax[SDL_GAMEPAD_AXIS_LEFTY];
  float m = hypotf(lx, ly);
  if (m < 0.15f)
    lx = ly = m = 0;
  bool afina = p->ax[SDL_GAMEPAD_AXIS_LEFT_TRIGGER] > 0.3f;
  if (pad_apertou(p, SDL_GAMEPAD_BUTTON_SOUTH) && l->corrida_espera <= 0) {
    l->corrida = 0.18f;
    l->corrida_espera = 1.2f;
  }
  float v = VEL * (afina ? 0.55f : 1) * (l->corrida > 0 ? 2.3f : 1);
  l->x += lx * v * dt;
  l->y += ly * v * dt;
  empurrar_dos_pilares(&l->x, &l->y);
  if (m > 0)
    l->passo += dt * v * m / 26.0f;
  /* mirar: o analógico direito e o giroscópio (a guinada gira a mira) */
  float rx = p->ax[SDL_GAMEPAD_AXIS_RIGHTX], ry = p->ax[SDL_GAMEPAD_AXIS_RIGHTY];
  if (hypotf(rx, ry) > 0.35f)
    l->mira = atan2f(ry, rx);
  else if (m > 0 && !afina)
    l->mira = atan2f(ly, lx);
  if (p->cap_giro)
    l->mira -= p->giro[1] * dt * (afina ? 2.2f : 1.2f);
  /* atirar e recarregar */
  if (l->recarga > 0) {
    l->recarga -= dt;
    if (l->recarga <= 0) {
      l->municao = MUNICAO;
      mostrar_municao(a, l);
      armar(a, l, true);
    }
  } else if (pad_apertou(p, SDL_GAMEPAD_BUTTON_WEST) && l->municao < MUNICAO) {
    l->recarga = RECARGA_S;
  }
  if (apertou_r2 && l->recarga <= 0) {
    if (l->municao > 0) {
      atirar(a, i, l->mira);
      l->municao--;
      g_f[s].carga.tiros++;
      mostrar_municao(a, l);
      contar(s, pad_rumble(a, p, 0, 0.35f, 60));
      if (l->municao == 0)
        armar(a, l, false);
    } else {
      somc_falante(a, s, &so->clique, 0.9f); /* o clique seco sai da mão */
    }
  }
  /* a martelada */
  if (l->especial < 1)
    l->especial = fminf(1, l->especial + dt / ESPECIAL_S);
  if (l->especial >= 1 && !l->avisou) {
    l->avisou = true;
    somc_falante(a, s, &so->pronto, 0.8f); /* o sino só no controle de quem tem */
  }
  if (l->especial >= 1 && pad_apertou(p, SDL_GAMEPAD_BUTTON_TOUCHPAD))
    martelada(a, i);
  /* o passo no chão, nos atuadores */
  if (m > 0) {
    l->passo_t -= dt * (l->corrida > 0 ? 1.8f : 1);
    if (l->passo_t <= 0) {
      l->passo_t = PASSO_S;
      int c = chao_em(l->x, l->y);
      const Som *ps = &so->passo[c][(int)(l->passo) % SONS_PASSOS_VARIANTES];
      somc_haptica(a, s, ps, ps, 0.55f);
    }
  }
}

static float angulo_para(const Lutador *de, const Lutador *para) { return atan2f(para->y - de->y, para->x - de->x); }

static int inimigo_mais_perto(int i) {
  int melhor = -1;
  float md = 1e9f;
  for (int k = 0; k < g_n_lut; k++) {
    const Lutador *o = &g_l[k];
    if (!o->ativo || o->equipe == g_l[i].equipe || o->fora > 0)
      continue;
    float d = hypotf(o->x - g_l[i].x, o->y - g_l[i].y);
    if (d < md) {
      md = d;
      melhor = k;
    }
  }
  return melhor;
}

static void boneco(App *a, int i, float dt) {
  Lutador *l = &g_l[i];
  if (l->fora > 0 || l->atordoado > 0)
    return;
  l->ia_t -= dt;
  if (l->ia_t <= 0) {
    l->ia_t = 1.4f + 1.2f * sorteio_real(&g_b.sorteio);
    l->ia_x = ARENA.x + ARENA.w * (l->equipe == 0 ? 0.08f + 0.35f * sorteio_real(&g_b.sorteio)
                                                  : 0.57f + 0.35f * sorteio_real(&g_b.sorteio));
    l->ia_y = ARENA.y + ARENA.h * (0.1f + 0.8f * sorteio_real(&g_b.sorteio));
  }
  float dx = l->ia_x - l->x, dy = l->ia_y - l->y, d = hypotf(dx, dy);
  if (d > 8) {
    l->x += dx / d * VEL * 0.5f * dt;
    l->y += dy / d * VEL * 0.5f * dt;
    l->passo += dt * VEL * 0.5f / 26.0f;
  }
  empurrar_dos_pilares(&l->x, &l->y);
  int alvo = inimigo_mais_perto(i);
  if (alvo >= 0) {
    l->mira = angulo_para(l, &g_l[alvo]);
    l->tiro_t -= dt;
    if (l->tiro_t <= 0) {
      l->tiro_t = 1.8f;
      atirar(a, i, l->mira + (sorteio_real(&g_b.sorteio) - 0.5f) * 0.5f);
    }
  }
}

static void mover_tiros(App *a, float dt) {
  for (int k = 0; k < MAX_TIROS; k++) {
    Disparo *t = &g_tiro[k];
    if (!t->vivo)
      continue;
    t->x += t->vx * dt;
    t->y += t->vy * dt;
    t->vida -= dt;
    if (t->vida <= 0 || t->x < ARENA.x || t->x > ARENA.x + ARENA.w || t->y < ARENA.y || t->y > ARENA.y + ARENA.h) {
      t->vivo = false;
      continue;
    }
    for (int p = 0; p < PILARES; p++)
      if (hypotf(t->x - g_pilar[p].x, t->y - g_pilar[p].y) < RAIO_PILAR) {
        t->vivo = false;
        particulas_brasas(&a->brasas, t->x, t->y, 5, COR_BRASA);
      }
    for (int i = 0; t->vivo && i < g_n_lut; i++) {
      Lutador *o = &g_l[i];
      if (!o->ativo || o->equipe == t->equipe || o->fora > 0 || hypotf(o->x - t->x, o->y - t->y) > RAIO)
        continue;
      t->vivo = false;
      golpe(a, o, t->dono, t->vx);
    }
  }
}

/* ---------- a prova final ---------- */

static void perguntar_leds(App *a) {
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Pad *p = pads_do_slot(a, s);
    int li = g_lut_do_slot[s];
    if (!p || li < 0)
      continue;
    Final *f = &g_f[s];
    int atual = g_l[li].fora > 0 ? 0 : g_l[li].municao, k;
    do
      k = sorteio_entre(&g_b.sorteio, 1, 4);
    while (k == atual);
    f->resp = -1;
    f->t = 0;
    f->robo_espera = -1;
    f->leds_pedido = pad_leds_jogador(a, p, mascara_de(k)) ? k : -1;
  }
  g_etapa = PV_LEDS;
  g_t = 0;
}

static void perguntar_cor(App *a) {
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Pad *p = pads_do_slot(a, s);
    int li = g_lut_do_slot[s];
    if (!p || li < 0)
      continue;
    Final *f = &g_f[s];
    int c;
    do
      c = sorteio_entre(&g_b.sorteio, 0, 3);
    while (c == COR_PARECIDA[g_l[li].equipe]);
    f->resp = -1;
    f->t = 0;
    f->robo_espera = -1;
    f->cor_pedida = pad_luz(a, p, CORES[c].c) ? c : -1;
  }
  g_etapa = PV_COR;
  g_t = 0;
}

/* Uma rodada da prova final: devolve true quando todos responderam (ou o
 * tempo acabou). `certo` é o índice do botão certo de cada um. */
static bool rodada_final(App *a, bool leds, float dt) {
  bool todos = true;
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Pad *p = pads_do_slot(a, s);
    Final *f = &g_f[s];
    int pedido = leds ? f->leds_pedido : f->cor_pedida;
    if (!p || g_lut_do_slot[s] < 0 || pedido < 0 || f->resp == -2)
      continue;
    f->t += dt;
    if (f->resp < 0 && f->t >= PERGUNTA_ESPERA)
      for (int k = 0; k < 4 && f->resp < 0; k++)
        if (pad_apertou(p, BOTAO[k])) {
          f->resp = k;
          som_evento(&a->som, SOM_TICK, 0.4f);
        }
    if (f->resp >= 0 || f->t >= PERGUNTA_ESPERA + PERGUNTA_S) {
      int certo = leds ? pedido - 1 : pedido;
      Cega *c = leds ? &f->leds : &f->cor;
      if (f->resp == certo) {
        cega_certo(c);
        sb_pontos(a, &g_b, s, 100);
      } else if (f->resp >= 0) {
        cega_errado(c, f->resp);
      } else {
        cega_perdido(c);
      }
      f->resp = -2; /* fechada */
    } else {
      todos = false;
    }
  }
  return todos;
}

static void terminar(App *a) {
  for (int s = 0; s < MAX_JOGADORES; s++) {
    if (!g_b.jogando[s])
      continue;
    Final *f = &g_f[s];
    Veredito v = cega_tudo_junto_veredito(&f->carga, &f->leds, &f->cor, g_b.mexeu[s]);
    if (v.nivel == NIVEL_MONTOU)
      sb_explica_recusa(a, s, &v);
    sb_veredito(&g_b, s, F_TUDO_JUNTO, &v);
  }
  g_etapa = PV_ACABOU;
  sb_terminar(a, &g_b, NIVEL_SAIU);
}

/* ---------- o robô ---------- */

static int cor_mais_perto(Uint8 r, Uint8 g, Uint8 b) {
  int melhor = 0;
  float md = 1e9f;
  for (int k = 0; k < 4; k++) {
    float d = powf(r - CORES[k].c.r, 2) + powf(g - CORES[k].c.g, 2) + powf(b - CORES[k].c.b, 2);
    if (d < md) {
      md = d;
      melhor = k;
    }
  }
  return melhor;
}

static void robo(App *a, int i, Pad *p, float dt) {
  Lutador *l = &g_l[i];
  int idx = (int)(p - a->pads.pad), s = l->slot;
  if (g_etapa == PV_LEDS || g_etapa == PV_COR) {
    Final *f = &g_f[s];
    int pedido = g_etapa == PV_LEDS ? f->leds_pedido : f->cor_pedida;
    if (pedido < 0 || f->resp != -1)
      return;
    if (f->robo_espera < 0)
      f->robo_espera = PERGUNTA_ESPERA + 0.3f + 0.8f * robo_acaso();
    f->robo_espera -= dt;
    if (f->robo_espera > 0)
      return;
    const Percepcao *pc = simulador_percepcao(p->id);
    int k = 0;
    if (pc && g_etapa == PV_LEDS) {
      int acesas = 0;
      for (int b = 0; b < 5; b++)
        acesas += (pc->leds_jogador >> b) & 1;
      k = acesas < 1 ? 0 : acesas > 4 ? 3 : acesas - 1;
    } else if (pc) {
      k = cor_mais_perto(pc->luz_r, pc->luz_g, pc->luz_b);
    }
    robo_apertar(a, idx, BOTAO[k], 0.08f);
    f->robo_espera = 99;
    return;
  }
  if (g_etapa != PV_PARTIDA || l->fora > 0)
    return;
  int alvo = inimigo_mais_perto(i);
  if (alvo < 0)
    return;
  Lutador *o = &g_l[alvo];
  float ang = angulo_para(l, o), d = hypotf(o->x - l->x, o->y - l->y);
  l->robo_lado_t -= dt;
  if (l->robo_lado_t <= 0) {
    l->robo_lado_t = 1.5f + robo_acaso() * 1.5f;
    l->robo_lado = robo_acaso() < 0.5f ? -1 : 1;
  }
  float av = d > 460 ? 1.0f : d < 300 ? -0.8f : 0;
  float mx = cosf(ang) * av - sinf(ang) * 0.7f * l->robo_lado, my = sinf(ang) * av + cosf(ang) * 0.7f * l->robo_lado;
  float mm = hypotf(mx, my);
  if (mm > 1) {
    mx /= mm;
    my /= mm;
  }
  robo_eixo(a, idx, SDL_GAMEPAD_AXIS_LEFTX, mx, 0.1f);
  robo_eixo(a, idx, SDL_GAMEPAD_AXIS_LEFTY, my, 0.1f);
  robo_eixo(a, idx, SDL_GAMEPAD_AXIS_RIGHTX, cosf(ang), 0.1f);
  robo_eixo(a, idx, SDL_GAMEPAD_AXIS_RIGHTY, sinf(ang), 0.1f);
  float erro = fabsf(atan2f(sinf(ang - l->mira), cosf(ang - l->mira)));
  l->robo_tiro -= dt;
  if (l->municao == 0 && l->recarga <= 0) {
    if (!l->robo_recarregou) {
      robo_apertar(a, idx, SDL_GAMEPAD_BUTTON_WEST, 0.08f);
      l->robo_recarregou = true;
    }
  } else {
    l->robo_recarregou = false;
  }
  if (l->municao > 0 && l->recarga <= 0 && erro < 0.15f && l->robo_tiro <= 0) {
    robo_eixo(a, idx, SDL_GAMEPAD_AXIS_RIGHT_TRIGGER, 1.0f, 0.08f);
    l->robo_tiro = 0.35f + 0.3f * robo_acaso();
  }
  if (l->especial >= 1 && d < MARTELADA_RAIO * 0.8f)
    robo_apertar(a, idx, SDL_GAMEPAD_BUTTON_TOUCHPAD, 0.08f);
  else if (robo_acaso() < 0.004f)
    robo_apertar(a, idx, SDL_GAMEPAD_BUTTON_SOUTH, 0.08f);
}

/* ---------- o laço ---------- */

static void atualizar(App *a, float dt) {
  int fase = sb_atualizar(a, &g_b, dt);
  g_tremor = fmaxf(0, g_tremor - dt * 1.5f);
  if (fase != FASE_JOGO || g_etapa == PV_ACABOU)
    return;
  if (!g_comecou)
    comecar(a);
  for (int i = 0; i < g_n_lut; i++) {
    Lutador *l = &g_l[i];
    Pad *p = l->slot >= 0 ? pads_do_slot(a, l->slot) : NULL;
    if (p && robo_ativo())
      robo(a, i, p, dt);
  }
  g_t += dt;
  switch (g_etapa) {
  case PV_CONTAGEM:
    if (g_t >= CONTAGEM_S) {
      g_etapa = PV_PARTIDA;
      g_t = 0;
      som_evento(&a->som, SOM_BIGORNA, 0.8f);
    }
    break;
  case PV_PARTIDA:
    for (int i = 0; i < g_n_lut; i++) {
      Lutador *l = &g_l[i];
      if (!l->ativo)
        continue;
      l->dano = aproximar(l->dano, 0, 6, dt);
      l->atordoado = fmaxf(0, l->atordoado - dt);
      if (l->fora > 0) {
        l->fora -= dt;
        if (l->fora <= 0)
          voltar(a, l);
      }
      Pad *p = l->slot >= 0 ? pads_do_slot(a, l->slot) : NULL;
      if (l->slot >= 0 && p) {
        jogador(a, i, p, dt);
        atualizar_luz(a, l, dt);
        Final *f = &g_f[l->slot];
        long total = (long)p->taxa_giro.total;
        med_carga_quadro(&f->carga, total - f->giro_ult, dt);
        f->giro_ult = total;
      } else if (l->slot < 0) {
        boneco(a, i, dt);
      }
    }
    mover_tiros(a, dt);
    if (g_t >= PARTIDA_S) {
      for (int k = 0; k < MAX_TIROS; k++)
        g_tiro[k].vivo = false;
      for (int i = 0; i < g_n_lut; i++)
        if (g_l[i].slot >= 0) {
          armar(a, &g_l[i], false);
          g_b.acabou[g_l[i].slot] = true;
        }
      som_evento(&a->som, SOM_SUCESSO, 0.7f);
      perguntar_leds(a);
    }
    break;
  case PV_LEDS:
    if (rodada_final(a, true, dt))
      perguntar_cor(a);
    break;
  case PV_COR:
    if (rodada_final(a, false, dt)) {
      g_etapa = PV_PLACAR;
      g_t = 0;
      for (int s = 0; s < MAX_JOGADORES; s++) {
        Pad *p = pads_do_slot(a, s);
        if (p)
          pad_luz_do_slot(a, p);
      }
    }
    break;
  case PV_PLACAR:
    if (g_t >= PLACAR_S)
      terminar(a);
    break;
  case PV_ACABOU:
    break;
  }
}

/* ---------- desenho ---------- */

static const SDL_Color TOM_CHAO[CHAO_TOTAL] = {{44, 58, 40, 255}, {58, 52, 46, 255}, {48, 52, 60, 255}, {34, 48, 70, 255}};

static void desenhar_arena(SDL_Renderer *r, float t) {
  float cx = ARENA.x + ARENA.w / 2, cy = ARENA.y + ARENA.h / 2;
  ds_ret_arred(r, ARENA.x, ARENA.y, ARENA.w, ARENA.h, 18, TOM_CHAO[CHAO_GRAMA]);
  ds_ret(r, ARENA.x, cy - 60, ARENA.w, 120, TOM_CHAO[CHAO_AGUA]);
  for (int k = 0; k < 3; k++) { /* as ondas da água */
    SDL_FPoint pt[40];
    for (int i = 0; i < 40; i++) {
      float x = ARENA.x + ARENA.w * i / 39.0f;
      pt[i] = (SDL_FPoint){x, cy - 30 + k * 30 + sinf(x * 0.02f + t * 2 + k) * 4};
    }
    ds_polilinha(r, pt, 40, 2, cor_alfa((SDL_Color){90, 150, 220, 255}, 0.35f), false);
  }
  ds_ret(r, cx - 230, ARENA.y, 460, ARENA.h, TOM_CHAO[CHAO_METAL]);
  for (float y = ARENA.y + 60; y < ARENA.y + ARENA.h; y += 120) /* as placas do metal */
    ds_linha(r, cx - 230, y, cx + 230, y, 2, cor_alfa(COR_TEXTO, 0.08f));
  ds_linha(r, cx, ARENA.y, cx, ARENA.y + ARENA.h, 3, cor_alfa(COR_TEXTO, 0.12f));
  for (int e = 0; e < 2; e++) { /* as bases */
    float x = e == 0 ? ARENA.x : ARENA.x + ARENA.w - 190;
    ds_ret_grad(r, x, ARENA.y, 190, ARENA.h, cor_alfa(LUZ_EQUIPE[e], 0.10f), cor_alfa(LUZ_EQUIPE[e], 0.03f));
  }
  for (int k = 0; k < PILARES; k++) {
    ds_circulo(r, g_pilar[k].x, g_pilar[k].y, RAIO_PILAR + 70, cor_alfa(TOM_CHAO[CHAO_CASCALHO], 0.9f));
    for (int j = 0; j < 14; j++) {
      float an = j * 2.4f + k, rr = RAIO_PILAR + 20 + fmodf(j * 17.0f, 45);
      ds_circulo(r, g_pilar[k].x + cosf(an) * rr, g_pilar[k].y + sinf(an) * rr, 3 + (j % 3), cor_alfa(COR_BRONZE, 0.35f));
    }
    ds_circulo(r, g_pilar[k].x, g_pilar[k].y + 6, RAIO_PILAR, (SDL_Color){20, 14, 10, 160});
    ds_circulo_grad(r, g_pilar[k].x, g_pilar[k].y, RAIO_PILAR, COR_BRONZE, COR_BRONZE_ESCURO);
    ds_anel(r, g_pilar[k].x, g_pilar[k].y, RAIO_PILAR - 10, 3, cor_alfa(COR_OURO, 0.5f));
  }
  ds_contorno_arred(r, ARENA.x, ARENA.y, ARENA.w, ARENA.h, 18, 2, cor_alfa(COR_BRONZE, 0.6f));
}

static void desenhar_lutador(App *a, const Lutador *l, float ox, float oy) {
  SDL_Renderer *r = a->r;
  if (l->fora > 0) {
    ds_anel(r, l->x + ox, l->y + oy, 26, 2, cor_alfa(LUZ_EQUIPE[l->equipe], 0.4f));
    texto_al(r, F_PEQUENA_N, l->x + ox, l->y + oy - 12, COR_TEXTO_3, ALINHA_CENTRO, fmt("%.0f", ceilf(l->fora)));
    return;
  }
  float x = l->x + ox, y = l->y + oy;
  SDL_Color cor = l->slot >= 0 ? COR_JOGADOR[l->slot] : (SDL_Color){150, 150, 150, 255};
  ds_brilho(r, x, y, 70, LUZ_EQUIPE[l->equipe], 0.25f);
  ds_anel(r, x, y + 4, RAIO + 6, 3, cor_alfa(LUZ_EQUIPE[l->equipe], 0.8f));
  Automato bon;
  automato_iniciar(&bon, x, y + 20);
  bon.olhar = l->mira;
  bon.passo = l->passo;
  bon.dano = l->dano;
  automato_desenhar(r, &bon, cor, 0.8f, a->t, -1);
  /* a mira */
  ds_linha(r, x + cosf(l->mira) * 44, y + sinf(l->mira) * 44, x + cosf(l->mira) * 70, y + sinf(l->mira) * 70, 3,
           cor_alfa(cor, 0.9f));
  /* a vida, a munição e o especial, colados nele */
  for (int k = 0; k < VIDA_MAX; k++)
    ds_ret_arred(r, x - 27 + k * 19, y - 64, 16, 7, 3, k < l->vida ? COR_OK : cor_alfa(COR_TEXTO_3, 0.4f));
  if (l->slot >= 0) {
    texto_al(r, F_PEQUENA_N, x, y - 96, cor, ALINHA_CENTRO, pads_rotulo_slot(l->slot));
    for (int k = 0; k < MUNICAO; k++)
      ds_circulo(r, x - 24 + k * 12, y + 44, 4, k < l->municao ? COR_TEXTO : cor_alfa(COR_TEXTO_3, 0.4f));
    if (l->recarga > 0)
      ds_arco(r, x, y + 4, RAIO + 14, 3, -PI_F / 2, -PI_F / 2 + 2 * PI_F * (1 - l->recarga / RECARGA_S), COR_TEXTO_2);
    if (l->especial >= 1)
      ds_anel(r, x, y + 4, RAIO + 18 + 3 * sinf(a->t * 8), 2, COR_OURO);
  }
  if (l->atordoado > 0)
    for (int k = 0; k < 3; k++) {
      float an = a->t * 6 + k * 2.1f;
      ds_circulo(r, x + cosf(an) * 22, y - 50 + sinf(an) * 6, 4, COR_OURO);
    }
}

static void desenhar(App *a) {
  SDL_Renderer *r = a->r;
  ds_fundo(r, a->t, 0.3f);
  sb_desenhar_topo(a, &g_b);
  float tremor = a->cfg.reduzir_movimento ? 0 : g_tremor;
  float ox = sinf(a->t * 70) * 10 * tremor, oy = cosf(a->t * 60) * 8 * tremor;
  if (g_b.fase != FASE_AVISO) {
    desenhar_arena(r, a->t);
    for (int k = 0; k < MAX_TIROS; k++) {
      const Disparo *t = &g_tiro[k];
      if (!t->vivo)
        continue;
      ds_brilho(r, t->x + ox, t->y + oy, 26, LUZ_EQUIPE[t->equipe], 0.6f);
      ds_linha(r, t->x + ox - t->vx * 0.018f, t->y + oy - t->vy * 0.018f, t->x + ox, t->y + oy, 5, COR_OURO);
    }
    for (int i = 0; i < g_n_lut && g_etapa <= PV_PARTIDA; i++)
      if (g_l[i].ativo)
        desenhar_lutador(a, &g_l[i], ox, oy);
  }
  particulas_desenhar(r, &a->brasas);
  if (g_b.fase == FASE_JOGO && g_comecou) {
    /* o placar e o relógio, no alto */
    float cx = TELA_L / 2.0f;
    texto_al(r, F_GRANDE_N, cx - 90, 40, LUZ_EQUIPE[0], ALINHA_DIR, fmt("%s %d", NOME_EQUIPE[0], g_placar[0]));
    texto_al(r, F_GRANDE_N, cx + 90, 40, cor_clarear(LUZ_EQUIPE[1], 0.3f), ALINHA_ESQ, fmt("%d %s", g_placar[1], NOME_EQUIPE[1]));
    int resta = g_etapa == PV_PARTIDA ? (int)ceilf(PARTIDA_S - g_t) : g_etapa == PV_CONTAGEM ? (int)PARTIDA_S : 0;
    texto_al(r, F_GRANDE_N, cx, 40, COR_TEXTO, ALINHA_CENTRO, fmt("%d:%02d", resta / 60, resta % 60));
    if (g_etapa == PV_CONTAGEM) {
      int n = (int)ceilf(CONTAGEM_S - g_t);
      ds_ret(r, 0, 0, TELA_L, TELA_A, cor_alfa(COR_CARVAO, 0.5f));
      texto_al(r, F_TITULO_X, cx, TELA_A / 2.0f - 90, COR_OURO, ALINHA_CENTRO, fmt("%d", n));
    } else if (g_etapa == PV_LEDS || g_etapa == PV_COR || g_etapa == PV_PLACAR) {
      ds_ret(r, 0, 0, TELA_L, TELA_A, cor_alfa(COR_CARVAO, 0.9f));
      if (g_etapa == PV_PLACAR) {
        const char *venceu = g_placar[0] == g_placar[1] ? "empate na forja"
                             : fmt("a %s venceu", NOME_EQUIPE[g_placar[0] > g_placar[1] ? 0 : 1]);
        texto_al(r, F_TITULO, cx, 380, COR_OURO, ALINHA_CENTRO, venceu);
        texto_al(r, F_GRANDE_N, cx, 500, COR_TEXTO, ALINHA_CENTRO,
                 fmt("%s %d  ×  %d %s", NOME_EQUIPE[0], g_placar[0], g_placar[1], NOME_EQUIPE[1]));
      } else {
        bool leds = g_etapa == PV_LEDS;
        texto_al(r, F_TITULO_P, cx, 250, COR_OURO, ALINHA_CENTRO, "a prova final");
        texto_al(r, F_MEDIA_N, cx, 330, COR_TEXTO, ALINHA_CENTRO,
                 leds ? "quantas luzinhas brancas estão acesas no SEU controle?" : "de que cor está a luz do SEU controle?");
        texto_al(r, F_PEQUENA, cx, 380, COR_TEXTO_2, ALINHA_CENTRO, "olhe o controle — a tela não mostra");
        static const char *NUMS[4] = {"uma", "duas", "três", "quatro"};
        for (int k = 0; k < 4; k++) {
          float x = cx + (k - 1.5f) * 230, y = 470;
          ds_ret_arred(r, x - 100, y, 200, 150, 14, cor_alfa(COR_PAINEL, 0.95f));
          ds_contorno_arred(r, x - 100, y, 200, 150, 14, 1.5f, COR_BRONZE_ESCURO);
          icone_natural(r, ICONE[k], x, y + 44, 40, 1);
          texto_al(r, F_TEXTO_N, x, y + 86, COR_TEXTO, ALINHA_CENTRO, leds ? NUMS[k] : CORES[k].nome);
        }
        /* quem já respondeu */
        float x0 = cx - 330;
        for (int s = 0; s < MAX_JOGADORES; s++) {
          if (g_lut_do_slot[s] < 0)
            continue;
          const Final *f = &g_f[s];
          int pedido = leds ? f->leds_pedido : f->cor_pedida;
          const char *st = pedido < 0 ? "sem saída" : f->resp == -2 ? "respondeu" : "olhando…";
          wg_escudo_jogador(r, x0, 720, 44, s, pads_do_slot(a, s) != NULL);
          texto_al(r, F_PEQUENA, x0, 760, pedido < 0 ? COR_AVISO : COR_TEXTO_2, ALINHA_CENTRO, st);
          x0 += 220;
        }
      }
    }
  }
  if (g_b.fase == FASE_AVISO)
    sb_desenhar_aviso(a, &g_b,
                      "Duas equipes, noventa segundos, tudo ligado. {LE} anda, {LD} e o giroscópio miram ({L2} afina), {R2} atira.\n"
                      "A munição está nas luzinhas do controle; vazia, o gatilho solta: {Q} recarrega. {X} corre.\n"
                      "O golpe da esquerda treme a esquerda; a luz é a da equipe e apaga com a vida.\n"
                      "Quando o sino tocar no seu controle, o {TP} solta a martelada. No fim, a prova final: olhe o controle.");
  else if (g_b.fase == FASE_FIM)
    sb_desenhar_fim(a, &g_b);
  else if (g_etapa == PV_LEDS || g_etapa == PV_COR) {
    Dica d[] = {{IC_CRUZ, g_etapa == PV_LEDS ? "uma" : "âmbar"}, {IC_CIRCULO, g_etapa == PV_LEDS ? "duas" : "ciano"},
                {IC_QUADRADO, g_etapa == PV_LEDS ? "três" : "violeta"}, {IC_TRIANGULO, g_etapa == PV_LEDS ? "quatro" : "branco"}};
    wg_rodape(r, d, 4);
  } else if (g_etapa == PV_PLACAR) {
    Dica d[] = {{IC_OPTIONS, "pausa"}};
    wg_rodape(r, d, 1);
  } else {
    Dica d[] = {{IC_R2, "atirar"}, {IC_QUADRADO, "recarregar"}, {IC_CRUZ, "correr"}, {IC_TOUCHPAD, "martelada"},
                {IC_OPTIONS, "pausa"}};
    wg_rodape(r, d, 5);
  }
  pausa_desenhar(a);
}

const Cena CENA_PROVA = {"prova", entrar, sair, NULL, atualizar, desenhar};
