/* experimental/ — a bancada dos experimentos. Ver experimentos.h e
 * experimental/README.md.
 *
 * Cada resultado vai para a linha do tempo da sessão (`"tipo": "experimento"`)
 * e para o registro, com "medido", "falhou" ou "nao_medido" — o que não deu
 * para medir também é resultado, e fica escrito com o porquê. */
#include "experimentos.h"

#include "../../demo/src/nucleo/cegas.h"
#include "../../demo/src/nucleo/simulador.h"
#include "../../demo/src/som/sintese.h"
#include "../../demo/src/som/sons_salas.h"
#include "../../demo/src/ui/desenho.h"
#include "../../demo/src/ui/icones.h"
#include "../../demo/src/ui/tema.h"
#include "../../demo/src/ui/texto.h"
#include "../../demo/src/ui/widgets.h"
#include "analise.h"

#include <math.h>
#include <stdarg.h>
#include <stdio.h>

typedef enum Chave { EX_LACO = 0, EX_QUATRO_MICS, EX_ECO, EX_GATILHO_CRU, EX_HAPTICA_NOMEADA, EX_TOTAL } Chave;

static const struct {
  const char *chave, *nome, *pergunta;
} EXP[EX_TOTAL] = {
    {"laco", "O laço do alto-falante",
     "quanto tempo o som leva do jogo ao alto-falante do controle e de volta pelo microfone dele — e se o microfone ouve os atuadores"},
    {"quatro-mics", "Quatro microfones",
     "os quatro microfones abrem juntos, chega som de todos, e cada um é o do controle certo?"},
    {"eco", "O eco do alto-falante",
     "quanto do alto-falante chega ao microfone do próprio controle, com a rota no alto-falante e no fone"},
    {"gatilho-cru", "Os bytes do gatilho",
     "que bytes do report USB 0x01 mudam com o modo do gatilho, e quais com o aperto"},
    {"haptica-nomeada", "A háptica pelo nó do Hefesto",
     "a háptica chega pelo nó «Háptica do Controle N» (o caminho do rádio), dos dois lados?"},
};

typedef struct Linha {
  int slot;
  int res; /* 0 medido · 1 falhou · 2 não medido */
  char texto[220];
} Linha;

#define MAX_LINHAS 40
#define TENTATIVAS 5
#define BYTE_INI 32
#define BYTE_N 32

static int g_exp = -1;
static Linha g_lin[MAX_LINHAS];
static int g_n_lin;
static int g_etapa, g_vez, g_k;
static float g_t;
static bool g_acabou;
static char g_agora[160]; /* o que está acontecendo, para a tela */
static int g_ordem[MAX_JOGADORES], g_n_ordem;
static Som g_tom;
static bool g_tem_tom;

/* laço */
static float g_lat[TENTATIVAS];
static int g_n_lat;
static float g_pico_db;
/* quatro microfones */
static float g_nivel[4][4], g_soma[4];
static int g_amostras;
static long g_quadros_ini[4];
static int g_quadros_jogo;
/* eco */
static float g_eco_db[3];
/* gatilho cru */
static Uint8 g_solto_min[4][BYTE_N], g_solto_max[4][BYTE_N], g_min[4][BYTE_N], g_max[4][BYTE_N];
static bool g_viu_solto[4];
/* háptica nomeada */
static int g_plano[4][4], g_resp[4], g_perg[4];
static Cega g_lado[4];
static float g_t_j[4], g_robo[4];

int experimento_por_chave(const char *chave) {
  for (int i = 0; i < EX_TOTAL; i++)
    if (chave && !SDL_strcmp(chave, EXP[i].chave))
      return i;
  return -1;
}

const char *experimentos_chaves(void) { return "laco, quatro-mics, eco, gatilho-cru, haptica-nomeada"; }

/* ---------- o resultado: na tela, na linha do tempo e no registro ---------- */

static void resultado(App *a, int slot, const char *o, int res, const char *formato, ...) {
  char texto[220];
  va_list ap;
  va_start(ap, formato);
  vsnprintf(texto, sizeof(texto), formato, ap);
  va_end(ap);
  static const char *NOMES[3] = {"medido", "falhou", "nao_medido"};
  Evento ev;
  ev_iniciar(&ev, &a->lt, "experimento", slot + 1);
  ev_str(&ev, "experimento", EXP[g_exp].chave);
  ev_str(&ev, "o", o);
  ev_str(&ev, "resultado", NOMES[res]);
  ev_str(&ev, "texto", texto);
  ev_fim(&ev, &a->lt);
  reg_linha(&a->reg, "experimento %s · %s · %s: %s", EXP[g_exp].chave, slot >= 0 ? pads_rotulo_slot(slot) : "mesa",
            NOMES[res], texto);
  if (g_n_lin < MAX_LINHAS) {
    Linha *l = &g_lin[g_n_lin++];
    l->slot = slot;
    l->res = res;
    SDL_strlcpy(l->texto, texto, sizeof(l->texto));
  }
}

static int idx_pad(App *a, int s) {
  Pad *p = pads_do_slot(a, s);
  return p ? (int)(p - a->pads.pad) : -1;
}

/* ---------- 1. o laço: alto-falante → microfone do mesmo controle ---------- */

static void laco_proximo(App *a) {
  g_vez++;
  g_etapa = 0;
  g_k = 0;
  g_n_lat = 0;
  g_pico_db = -90;
  g_t = 0;
  (void)a;
}

static bool laco(App *a, float dt) {
  g_t += dt;
  if (g_vez >= g_n_ordem)
    return true;
  int s = g_ordem[g_vez];
  const SonsSalas *so = sons_salas();
  if (g_etapa == 0) {
    if (!somc_tem(a, s, PAPEL_ALTO_FALANTE) || !somc_escutar(a, s, 0.1f)) {
      resultado(a, s, "latencia", 2, "não medido: %s", !somc_tem(a, s, PAPEL_ALTO_FALANTE)
                                                             ? "sem alto-falante achado"
                                                             : "sem microfone de verdade (controle simulado, ou não achado)");
      laco_proximo(a);
      return false;
    }
    somc_escuta_parar(a, s);
    g_etapa = 1;
    g_t = 0;
  }
  bool haptica = g_k >= TENTATIVAS;
  int total = TENTATIVAS + 3;
  if (g_etapa == 1 && g_t >= 0.35f) { /* dispara: o microfone limpo, e o som sai agora */
    somc_escutar(a, s, 0.8f);
    if (haptica)
      somc_haptica(a, s, &so->pulso, &so->pulso, 1.0f);
    else
      somc_falante(a, s, &so->clique, 1.0f);
    g_etapa = 2;
    g_t = 0;
    snprintf(g_agora, sizeof(g_agora), "%s: %s %d de %d", pads_rotulo_slot(s), haptica ? "pulso nos atuadores" : "clique no alto-falante",
             haptica ? g_k - TENTATIVAS + 1 : g_k + 1, haptica ? 3 : TENTATIVAS);
  }
  if (g_etapa == 2 && g_t >= 0.85f) {
    int n;
    const float *am = somc_escuta(a, s, &n);
    int t = am ? exp_ataque(am, n, 6, 0.01f) : -1;
    if (t >= 0) {
      g_lat[g_n_lat++] = 1000.0f * t / EXP_TAXA;
      float pico = exp_db(exp_rms(am, t, SDL_min(n - t, EXP_TAXA / 50)));
      g_pico_db = fmaxf(g_pico_db, pico);
    }
    somc_escuta_parar(a, s);
    g_k++;
    g_etapa = 1;
    g_t = 0;
    if (g_k == TENTATIVAS) {
      if (g_n_lat > 0) {
        int ouviu = g_n_lat;
        float med = exp_mediana(g_lat, g_n_lat);
        resultado(a, s, "latencia", 0, "o clique voltou pelo microfone em %.0f ms (mediana de %d de %d), a %.0f dBFS", med,
                  ouviu, TENTATIVAS, g_pico_db);
      } else {
        resultado(a, s, "latencia", 1, "o microfone do controle não ouviu nenhum dos %d cliques do alto-falante dele",
                  TENTATIVAS);
      }
      g_n_lat = 0;
      g_pico_db = -90;
    } else if (g_k == total) {
      if (!somc_tem(a, s, PAPEL_HAPTICA))
        resultado(a, s, "atuadores_no_microfone", 2, "não medido: sem háptica achada");
      else if (g_n_lat > 0)
        resultado(a, s, "atuadores_no_microfone", 0, "o microfone ouviu o pulso dos atuadores em %.0f ms (%d de 3), a %.0f dBFS",
                  exp_mediana(g_lat, g_n_lat), g_n_lat, g_pico_db);
      else
        resultado(a, s, "atuadores_no_microfone", 0, "o microfone não ouviu o pulso dos atuadores (0 de 3): o zumbido não "
                                                     "chega a ele");
      laco_proximo(a);
    }
  }
  return false;
}

/* ---------- 2. quatro microfones ao mesmo tempo ---------- */

static float linear(float nivel) { return powf(10.0f, (nivel * 54.0f - 54.0f) / 20.0f); }

static bool quatro_mics(App *a, float dt) {
  g_t += dt;
  if (g_etapa == 0) {
    int n = 0;
    for (int i = 0; i < g_n_ordem; i++)
      n += somc_tem(a, g_ordem[i], PAPEL_MICROFONE);
    if (n == 0) {
      resultado(a, -1, "microfones", 2, "não medido: nenhum microfone achado");
      return true;
    }
    for (int i = 0; i < g_n_ordem; i++)
      g_quadros_ini[i] = somc_mic_quadros(a, g_ordem[i]);
    g_quadros_jogo = 0;
    SDL_memset(g_nivel, 0, sizeof(g_nivel));
    g_etapa = 1;
    g_t = 0;
    g_vez = -1; /* -1: o silêncio de todos */
    g_amostras = 0;
    SDL_memset(g_soma, 0, sizeof(g_soma));
  }
  g_quadros_jogo++;
  float dur = g_vez < 0 ? 2.0f : 2.5f;
  if (g_t >= 0.5f)
    for (int i = 0; i < g_n_ordem; i++)
      g_soma[i] += linear(somc_mic_nivel(a, g_ordem[i]));
  if (g_t >= 0.5f)
    g_amostras++;
  snprintf(g_agora, sizeof(g_agora), "%s", g_vez < 0 ? "todos em silêncio" : fmt("%s: fale agora, perto do seu controle",
                                                                                      pads_rotulo_slot(g_ordem[g_vez])));
  if (g_t >= dur) {
    for (int i = 0; i < g_n_ordem && g_vez >= 0; i++)
      g_nivel[i][g_vez] = g_amostras ? g_soma[i] / g_amostras : 0;
    g_vez++;
    g_t = 0;
    g_amostras = 0;
    SDL_memset(g_soma, 0, sizeof(g_soma));
    if (g_vez < g_n_ordem && robo_ativo()) {
      int idx = idx_pad(a, g_ordem[g_vez]);
      if (idx >= 0)
        robo_falar(a, idx, 0.8f, 2.2f);
    }
    if (g_vez >= g_n_ordem) {
      for (int i = 0; i < g_n_ordem; i++) {
        int s = g_ordem[i];
        if (!somc_tem(a, s, PAPEL_MICROFONE)) {
          resultado(a, s, "microfone", 2, "não medido: sem microfone achado");
          continue;
        }
        long q = somc_mic_quadros(a, s) - g_quadros_ini[i];
        int pct = g_quadros_jogo ? (int)lroundf(100.0f * q / g_quadros_jogo) : 0;
        resultado(a, s, "microfone", pct >= 90 ? 0 : 1, "chegou som em %d%% dos quadros; com a própria voz, %.0f dB", pct,
                  exp_db(g_nivel[i][i]));
      }
      if (g_n_ordem >= 2) {
        float margem;
        int certos = exp_diagonal(g_nivel, g_n_ordem, &margem);
        resultado(a, -1, "microfone_certo", certos == g_n_ordem ? 0 : 1,
                  "%d de %d microfones foram os mais altos com a voz do próprio jogador (a menor margem: %.0f dB)", certos,
                  g_n_ordem, margem);
      }
      return true;
    }
  }
  return false;
}

/* ---------- 3. o eco do alto-falante no microfone ---------- */

static bool eco(App *a, float dt) {
  g_t += dt;
  if (g_vez >= g_n_ordem)
    return true;
  int s = g_ordem[g_vez];
  Pad *p = pads_do_slot(a, s);
  if (g_etapa == 0) {
    if (!p || !somc_tem(a, s, PAPEL_ALTO_FALANTE) || !somc_escutar(a, s, 0.1f)) {
      resultado(a, s, "eco", 2, "não medido: %s", !somc_tem(a, s, PAPEL_ALTO_FALANTE) ? "sem alto-falante achado"
                                                                                       : "sem microfone de verdade");
      g_vez++;
      return false;
    }
    somc_escuta_parar(a, s);
    g_etapa = 1;
    g_k = 0;
    g_t = 0;
  }
  /* k = 0: silêncio; 1: o tom no alto-falante; 2: o tom com a rota no fone */
  static const char *O_QUE[3] = {"silêncio", "tom de 1 kHz no alto-falante", "o mesmo tom, com a rota no fone"};
  if (g_etapa == 1 && g_t >= 0.3f) {
    if (g_k == 2)
      pad_alto_falante(a, p, FORJA_VOL_FALANTE_PADRAO, FORJA_ROTA_FONE, FORJA_PREAMP_PADRAO);
    somc_escutar(a, s, 1.3f);
    if (g_k > 0 && g_tem_tom)
      somc_falante(a, s, &g_tom, 0.8f);
    g_etapa = 2;
    g_t = 0;
    snprintf(g_agora, sizeof(g_agora), "%s: %s", pads_rotulo_slot(s), O_QUE[g_k]);
  }
  if (g_etapa == 2 && g_t >= 1.35f) {
    int n;
    const float *am = somc_escuta(a, s, &n);
    int ini = EXP_TAXA * 3 / 10, fim = SDL_min(n, EXP_TAXA * 11 / 10);
    g_eco_db[g_k] = am && fim > ini ? exp_db(exp_rms(am, ini, fim - ini)) : -90;
    somc_escuta_parar(a, s);
    g_k++;
    g_etapa = 1;
    g_t = 0;
    if (g_k == 3) {
      pad_alto_falante(a, p, FORJA_VOL_FALANTE_PADRAO, FORJA_ROTA_FALANTE, FORJA_PREAMP_PADRAO);
      resultado(a, s, "eco", 0, "silêncio a %.0f dBFS; com o alto-falante tocando, %+.0f dB; com a rota no fone, %+.0f dB",
                g_eco_db[0], g_eco_db[1] - g_eco_db[0], g_eco_db[2] - g_eco_db[0]);
      g_vez++;
      g_etapa = 0;
    }
  }
  return false;
}

/* ---------- 4. os bytes de estado do gatilho ---------- */

static const ForjaTrigger MODOS[4] = {{FORJA_TRIGGER_OFF, 0, 0, 0},
                                      {FORJA_TRIGGER_FEEDBACK, 2, 4, 0},
                                      {FORJA_TRIGGER_WEAPON, 2, 6, 8},
                                      {FORJA_TRIGGER_VIBRATION, 0, 7, 30}};
static const char *NOME_MODO[4] = {"Off", "Feedback", "Weapon", "Vibration"};

static bool gatilho_cru(App *a, float dt) {
  g_t += dt;
  if (g_vez >= g_n_ordem)
    return true;
  int s = g_ordem[g_vez];
  Pad *p = pads_do_slot(a, s);
  if (g_etapa == 0) {
    if (!p || !p->cru_ok) {
      resultado(a, s, "gatilho_cru", 2, "não medido: sem o report cru USB 0x01 (controle simulado, virtual ou pelo rádio)");
      g_vez++;
      return false;
    }
    for (int m = 0; m < 4; m++) {
      SDL_memset(g_solto_min[m], 0xFF, BYTE_N);
      SDL_memset(g_solto_max[m], 0, BYTE_N);
      SDL_memset(g_min[m], 0xFF, BYTE_N);
      SDL_memset(g_max[m], 0, BYTE_N);
      g_viu_solto[m] = false;
    }
    g_k = 0;
    g_etapa = 1;
    g_t = 0;
    pad_gatilho(a, p, 1, MODOS[0]);
  }
  /* cada modo: 4 s — aperte o R2 devagar até o fundo e solte */
  snprintf(g_agora, sizeof(g_agora), "%s: R2 em %s — aperte devagar até o fundo e solte", pads_rotulo_slot(s), NOME_MODO[g_k]);
  if (g_t >= 0.4f) {
    bool solto = p->ax[SDL_GAMEPAD_AXIS_RIGHT_TRIGGER] < 0.04f;
    for (int b = 0; b < BYTE_N; b++) {
      Uint8 v = p->cru[BYTE_INI + b];
      g_min[g_k][b] = SDL_min(g_min[g_k][b], v);
      g_max[g_k][b] = SDL_max(g_max[g_k][b], v);
      if (solto) {
        g_solto_min[g_k][b] = SDL_min(g_solto_min[g_k][b], v);
        g_solto_max[g_k][b] = SDL_max(g_solto_max[g_k][b], v);
      }
    }
    g_viu_solto[g_k] |= solto;
  }
  if (g_t >= 4.0f) {
    g_k++;
    g_t = 0;
    if (g_k < 4) {
      pad_gatilho(a, p, 1, MODOS[g_k]);
    } else {
      pad_gatilho(a, p, 1, MODOS[0]);
      char modo[120] = "", aperto[120] = "";
      for (int b = 0; b < BYTE_N; b++) {
        bool estavel = true, difere = false, varia = false;
        for (int m = 0; m < 4; m++) {
          if (!g_viu_solto[m])
            continue;
          estavel &= g_solto_min[m][b] == g_solto_max[m][b];
          difere |= g_solto_min[m][b] != g_solto_min[0][b];
          varia |= g_max[m][b] != g_min[m][b];
        }
        char item[8];
        snprintf(item, sizeof(item), "%s%d", "", BYTE_INI + b);
        if (estavel && difere) {
          SDL_strlcat(modo, modo[0] ? ", " : "", sizeof(modo));
          SDL_strlcat(modo, item, sizeof(modo));
        } else if (varia && estavel) {
          SDL_strlcat(aperto, aperto[0] ? ", " : "", sizeof(aperto));
          SDL_strlcat(aperto, item, sizeof(aperto));
        }
      }
      resultado(a, s, "gatilho_cru", 0, "bytes que mudam com o modo (solto): %s; bytes que mudam só com o aperto: %s",
                modo[0] ? modo : "nenhum", aperto[0] ? aperto : "nenhum");
      g_vez++;
      g_etapa = 0;
    }
  }
  return false;
}

/* ---------- 5. a háptica pelo nó nomeado ---------- */

static bool haptica_nomeada(App *a, float dt) {
  const SonsSalas *so = sons_salas();
  if (g_etapa == 0) {
    for (int i = 0; i < g_n_ordem; i++) {
      int s = g_ordem[i];
      static const int LADOS[2] = {0, 1}, DUAS[2] = {2, 2};
      Sorteio sr;
      sorteio_semear(&sr, a->semente ^ (0x51ED270Bu * (unsigned)(s + 1)));
      cegas_plano_fontes(&sr, LADOS, DUAS, 2, g_plano[s], 4);
      cega_zerar(&g_lado[s]);
      g_perg[s] = 0;
      g_resp[s] = -1;
      g_t_j[s] = 0;
      g_robo[s] = -1;
      if (!somc_tem(a, s, PAPEL_HAPTICA)) {
        resultado(a, s, "haptica", 2, "não medido: nenhuma háptica achada (sem a placa no cabo, sem o nó do Hefesto)");
        g_perg[s] = 4;
      }
    }
    g_etapa = 1;
  }
  bool todos = true;
  snprintf(g_agora, sizeof(g_agora), "de que lado tremeu? L1 esquerda · R1 direita · touchpad: não senti");
  for (int i = 0; i < g_n_ordem; i++) {
    int s = g_ordem[i];
    Pad *p = pads_do_slot(a, s);
    if (!p || g_perg[s] >= 4)
      continue;
    todos = false;
    int lado = g_plano[s][g_perg[s]];
    float t0 = g_t_j[s];
    g_t_j[s] += dt;
    if (t0 < 0.6f && g_t_j[s] >= 0.6f) { /* o pulso, num lado só (num nó mono, nos dois) */
      bool estereo = somc_estereo(a, s, PAPEL_HAPTICA);
      somc_haptica(a, s, lado == 0 || !estereo ? &so->tropeco : NULL, lado == 1 && estereo ? &so->tropeco : NULL, 1.0f);
    }
    if (g_t_j[s] >= 0.9f && g_resp[s] < 0) {
      if (pad_apertou(p, SDL_GAMEPAD_BUTTON_LEFT_SHOULDER))
        g_resp[s] = 0;
      else if (pad_apertou(p, SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER))
        g_resp[s] = 1;
      else if (pad_apertou(p, SDL_GAMEPAD_BUTTON_TOUCHPAD))
        g_resp[s] = 2;
    }
    /* o robô sente os atuadores do controle dele na hora do pulso */
    if (robo_ativo() && g_t_j[s] >= 0.62f && g_t_j[s] < 0.9f) {
      float e = somc_virtual_atuador(a, s, 0), d = somc_virtual_atuador(a, s, 1);
      if (fmaxf(e, d) > 0.05f)
        g_robo[s] = e > d ? 10 : 11; /* 10 esquerda, 11 direita */
    }
    if (robo_ativo() && g_t_j[s] >= 1.3f && g_resp[s] < 0) {
      int idx = idx_pad(a, s);
      SDL_GamepadButton b = g_robo[s] == 10   ? SDL_GAMEPAD_BUTTON_LEFT_SHOULDER
                            : g_robo[s] == 11 ? SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER
                                              : SDL_GAMEPAD_BUTTON_TOUCHPAD;
      if (idx >= 0 && g_t_j[s] < 1.3f + dt * 1.5f)
        robo_apertar(a, idx, b, 0.08f);
    }
    if (g_resp[s] >= 0 || g_t_j[s] >= 6.0f) {
      if (g_resp[s] == lado)
        cega_certo(&g_lado[s]);
      else if (g_resp[s] >= 0)
        cega_errado(&g_lado[s], g_resp[s]);
      else
        cega_perdido(&g_lado[s]);
      g_perg[s]++;
      g_resp[s] = -1;
      g_t_j[s] = 0;
      g_robo[s] = -1;
      if (g_perg[s] >= 4) {
        const char *como = achar_como_rotulo(somc_como(a, s, PAPEL_HAPTICA));
        Cega *c = &g_lado[s];
        int nada = c->respondeu_como[2];
        resultado(a, s, "haptica", c->certos >= 3 ? 0 : 1, "«%s», %s: lado certo %d de 4, \"não senti\" %d, sem resposta %d",
                  somc_nome(a, s, PAPEL_HAPTICA), como, c->certos, nada, c->perdidos);
      }
    }
  }
  return todos;
}

/* ---------- a cena ---------- */

static void entrar(App *a) {
  g_exp = a->experimento;
  a->bancada = true;
  g_n_lin = 0;
  g_etapa = g_vez = g_k = 0;
  g_t = 0;
  g_acabou = false;
  g_agora[0] = '\0';
  g_n_ordem = 0;
  for (int s = 0; s < MAX_JOGADORES; s++)
    if (pads_do_slot(a, s))
      g_ordem[g_n_ordem++] = s;
  somc_preparar(a);
  Onda o = {0};
  g_tem_tom = sint_tom(&o, 1000.0f, 1.2f, 0.02f) == 0;
  if (g_tem_tom)
    som_de_onda(&g_tom, &o);
  reg_linha(&a->reg, "experimento: %s", EXP[g_exp].nome);
  Evento ev;
  ev_iniciar(&ev, &a->lt, "experimento", 0);
  ev_str(&ev, "experimento", EXP[g_exp].chave);
  ev_str(&ev, "o", "comecou");
  ev_int(&ev, "controles", g_n_ordem);
  ev_fim(&ev, &a->lt);
}

static void sair(App *a) {
  for (int s = 0; s < MAX_JOGADORES; s++) {
    somc_parar_tudo(a, s);
    somc_escuta_parar(a, s);
  }
  if (g_tem_tom)
    som_liberar(&g_tom);
  g_tem_tom = false;
  pads_silencio_todos(a);
  a->bancada = false;
}

static void atualizar(App *a, float dt) {
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Pad *p = pads_do_slot(a, s);
    if (!p)
      continue;
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_START) || (g_acabou && pad_apertou(p, SDL_GAMEPAD_BUTTON_EAST))) {
      app_trocar_cena(a, &CENA_TITULO);
      return;
    }
    if (g_acabou && pad_apertou(p, SDL_GAMEPAD_BUTTON_SOUTH)) {
      sair(a);
      entrar(a);
      return;
    }
  }
  if (g_acabou) {
    /* com o robô, a bancada fecha sozinha: é uma rodada de teste */
    if (robo_ativo()) {
      g_t += dt;
      if (g_t > 2.0f)
        a->rodando = false;
    }
    return;
  }
  bool fim = false;
  switch (g_exp) {
  case EX_LACO:
    fim = laco(a, dt);
    break;
  case EX_QUATRO_MICS:
    fim = quatro_mics(a, dt);
    break;
  case EX_ECO:
    fim = eco(a, dt);
    break;
  case EX_GATILHO_CRU:
    fim = gatilho_cru(a, dt);
    break;
  case EX_HAPTICA_NOMEADA:
    g_t += dt;
    fim = haptica_nomeada(a, dt);
    break;
  default:
    fim = true;
  }
  if (fim) {
    g_acabou = true;
    g_t = 0;
    snprintf(g_agora, sizeof(g_agora), "pronto: %d resultado%s gravado%s na linha do tempo da sessão", g_n_lin,
             g_n_lin == 1 ? "" : "s", g_n_lin == 1 ? "" : "s");
    som_evento(&a->som, SOM_SUCESSO, 0.5f);
  }
}

static void desenhar(App *a) {
  SDL_Renderer *r = a->r;
  ds_fundo(r, a->t, 0.2f);
  texto(r, F_PEQUENA_N, 120, 70, COR_TEXTO_2, "experimental/ · a bancada dos experimentos");
  texto(r, F_TITULO_P, 120, 104, COR_OURO, EXP[g_exp].nome);
  float y = 180 + texto_bloco(r, F_TEXTO, 120, 180, 1680, COR_TEXTO, ALINHA_ESQ, 1.3f, true, EXP[g_exp].pergunta);
  texto(r, F_MEDIA_N, 120, y + 30, g_acabou ? COR_OK : COR_TEXTO, g_agora);
  float ly = y + 110;
  static const char *SELO[3] = {"medido", "falhou", "não medido"};
  const SDL_Color COR_RES[3] = {COR_OK, COR_FALHA, COR_TEXTO_3};
  for (int i = 0; i < g_n_lin; i++) {
    const Linha *l = &g_lin[i];
    if (l->slot >= 0)
      wg_escudo_jogador(r, 146, ly + 16, 36, l->slot, true);
    else
      texto(r, F_PEQUENA_N, 126, ly, COR_TEXTO_2, "mesa");
    texto(r, F_PEQUENA_N, 190, ly, COR_RES[l->res], SELO[l->res]);
    ly += texto_bloco(r, F_PEQUENA, 340, ly, 1460, COR_TEXTO, ALINHA_ESQ, 1.25f, true, l->texto) + 18;
    if (ly > TELA_A - 140)
      break;
  }
  if (g_acabou) {
    Dica d[] = {{IC_CRUZ, "repetir"}, {IC_CIRCULO, "sair"}};
    wg_rodape(r, d, 2);
  } else {
    Dica d[] = {{IC_OPTIONS, "parar"}};
    wg_rodape(r, d, 1);
  }
}

const Cena CENA_EXPERIMENTO = {"experimento", entrar, sair, NULL, atualizar, desenhar};
