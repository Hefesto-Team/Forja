/* A Cripta — a voz, o silêncio e o susto (ADR-002).
 *
 * O padrão é o dos jogos de terror que escutam quem joga: o guardião que ouve
 * pelo microfone do controle, o botão de mudo que salva, a luz laranja que diz
 * que o microfone está fechado — e o susto que sai da mão: a vibração forte e
 * o grito no alto-falante do controle, enquanto a TV bate. A sala mede:
 *
 *   - o microfone: o silêncio de todos (o piso) e a voz de cada um, na vez
 *     dele, chamando o guardião;
 *   - o mudo: o botão do microfone (MISC1 no SDL) e, falando baixinho já
 *     mudo, se o sistema também cortou o som ou se o mudo ficou com o jogo;
 *   - o LED do microfone, às cegas: o jogo apaga, acende ou faz piscar a luz,
 *     a tela não mostra, e a pessoa diz como está.
 *
 * O som do ar é de todos: quando um fala, os microfones dos outros também
 * ouvem. Por isso a voz é medida em turnos, e o silêncio de todos junto. */
#include "sala_base.h"

#include "../cenas/pausa.h"
#include "../nucleo/cegas.h"
#include "../nucleo/simulador.h"
#include "../som/sons_salas.h"
#include "../ui/desenho.h"
#include "../ui/icones.h"
#include "../ui/tema.h"
#include "../ui/texto.h"
#include "../ui/widgets.h"

#include <math.h>
#include <stdio.h>

#define PI_F 3.14159265f
#define SILENCIO_S 4.0f
#define CHAMADO_MAX 5.0f
#define MUDO_MAX 8.0f
#define SUSSURRO_S 3.0f
#define LUZ_ESPERA 1.0f /* a luz muda e a pessoa olha, antes de valer a resposta */
#define LUZ_MAX 7.0f
#define LUZ_REVELA 0.8f
#define LUZ_RODADAS 5
#define ESPERA_S 2.2f
#define SUSTO_S 1.9f

typedef enum Estado { CR_SILENCIO = 0, CR_CHAMADO, CR_MUDO, CR_SUSSURRO, CR_LUZ, CR_ESPERA, CR_SUSTO, CR_ACABOU } Estado;
typedef enum LuzFase { LZ_OLHAR = 0, LZ_REVELA, LZ_FIM } LuzFase;

typedef struct Jogador {
  MedMic m;
  double soma_piso;
  int n_piso;
  long quadros_ini;
  bool chamou;   /* a voz passou do limiar na vez dele */
  float acima_t; /* tempo acumulado acima do limiar */
  bool mudo;     /* o jogo está mudo para ele */
  /* o LED, às cegas */
  Cega luz;
  bool luz_ok; /* o SDL aceitou mandar o LED */
  int plano[LUZ_RODADAS], rodada, modo, resp;
  LuzFase fase;
  float t;
  /* a chama da voz, na tela */
  float chama;
  /* o robô */
  float robo_espera;
  bool robo_falou;
} Jogador;

static const Feature FEATS[] = {F_MICROFONE, F_MICROFONE_MUDO, F_LED_MICROFONE};
static const SDL_GamepadButton BOTAO_LUZ[3] = {SDL_GAMEPAD_BUTTON_SOUTH, SDL_GAMEPAD_BUTTON_EAST, SDL_GAMEPAD_BUTTON_WEST};
static const Icone ICONE_LUZ[3] = {IC_CRUZ, IC_CIRCULO, IC_QUADRADO};
static const char *NOME_LUZ[3] = {"apagada", "acesa", "piscando"};
static const SDL_Color COR_LED = {255, 146, 40, 255};

static SalaBase g_b;
static Jogador g_j[MAX_JOGADORES];
static SDL_FRect g_faixa[MAX_JOGADORES];
static int g_slot_faixa[MAX_JOGADORES], g_n_faixas;
static const SDL_FRect AREA = {40, 350, TELA_L - 80, TELA_A - 350 - 96};

static Estado g_estado;
static float g_t;
static int g_vez; /* no chamado: o índice da faixa que fala */
static float g_flash, g_olhos;
static bool g_comecou;

static void entrar(App *a) {
  sb_entrar(a, &g_b, SALA_CRIPTA, FEATS, 3, 0);
  sb_som(a, &g_b, PAPEL_MICROFONE);
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Jogador *j = &g_j[s];
    SDL_memset(j, 0, sizeof(*j));
    cega_zerar(&j->luz);
    j->resp = -1;
    j->robo_espera = -1;
  }
  g_estado = CR_SILENCIO;
  g_t = g_flash = g_olhos = 0;
  g_vez = 0;
  g_comecou = false;
}

static void sair(App *a) {
  for (int s = 0; s < MAX_JOGADORES; s++)
    somc_parar_tudo(a, s);
  pads_silencio_todos(a);
}

static void evento(App *a, int slot, const char *o, const char *chave, const char *valor) {
  Evento ev;
  ev_iniciar(&ev, &a->lt, "jogo", slot + 1);
  ev_str(&ev, "sala", "cripta");
  ev_str(&ev, "o", o);
  if (chave)
    ev_str(&ev, chave, valor);
  ev_fim(&ev, &a->lt);
}

static void comecar(App *a) {
  static const int MODOS[3] = {0, 1, 2}, VEZES[3] = {2, 2, 1};
  for (int s = 0; s < MAX_JOGADORES; s++) {
    if (!g_b.jogando[s])
      continue;
    Jogador *j = &g_j[s];
    med_mic_iniciar(&j->m, somc_tem(a, s, PAPEL_MICROFONE));
    j->quadros_ini = somc_mic_quadros(a, s);
    cegas_plano_fontes(&g_b.sorteio, MODOS, VEZES, 3, j->plano, LUZ_RODADAS);
    Pad *p = pads_do_slot(a, s);
    if (p)
      pad_led_mic(a, p, 0);
  }
  g_comecou = true;
}

/* A faixa da vez no chamado, pulando quem não tem controle ou microfone. */
static int proxima_vez(App *a, int de) {
  for (int i = de; i < g_n_faixas; i++) {
    int s = g_slot_faixa[i];
    if (g_b.jogando[s] && pads_do_slot(a, s) && somc_tem(a, s, PAPEL_MICROFONE))
      return i;
  }
  return -1;
}

static void luz_rodada(App *a, int s, Jogador *j) {
  Pad *p = pads_do_slot(a, s);
  j->modo = j->plano[j->rodada];
  j->resp = -1;
  j->t = 0;
  j->fase = LZ_OLHAR;
  j->robo_espera = -1;
  j->luz_ok = p && pad_led_mic(a, p, j->modo);
  if (!j->luz_ok)
    j->fase = LZ_FIM; /* o que o SDL não manda não se pergunta */
}

static void comecar_luz(App *a) {
  g_estado = CR_LUZ;
  g_t = 0;
  for (int s = 0; s < MAX_JOGADORES; s++)
    if (g_b.jogando[s]) {
      g_j[s].rodada = 0;
      g_j[s].mudo = false;
      luz_rodada(a, s, &g_j[s]);
    }
}

static void susto(App *a) {
  const SonsSalas *so = sons_salas();
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Pad *p = pads_do_slot(a, s);
    if (!p || !g_b.jogando[s])
      continue;
    pad_rumble(a, p, 1.0f, 1.0f, 700);
    pad_luz(a, p, (SDL_Color){255, 20, 10, 255});
    somc_falante(a, s, &so->grito, 1.0f);
  }
  som_tocar(&a->som, &so->grito, 0.55f, 0);
  som_evento(&a->som, SOM_MARTELO, 1.0f);
  g_flash = 1;
  evento(a, -1, "susto", NULL, NULL);
}

static void terminar(App *a) {
  for (int s = 0; s < MAX_JOGADORES; s++) {
    if (!g_b.jogando[s])
      continue;
    Jogador *j = &g_j[s];
    j->m.quadros = somc_mic_quadros(a, s) - j->quadros_ini;
    Veredito v = med_mic_veredito(&j->m, g_b.mexeu[s]);
    sb_veredito(&g_b, s, F_MICROFONE, &v);
    v = med_mudo_veredito(&j->m, g_b.mexeu[s]);
    sb_veredito(&g_b, s, F_MICROFONE_MUDO, &v);
    bool mandou = j->luz_ok || cega_total(&j->luz) > 0;
    v = cega_led_mic_veredito(&j->luz, mandou);
    if (!mandou)
      sb_explica_recusa(a, s, &v);
    sb_veredito(&g_b, s, F_LED_MICROFONE, &v);
  }
  g_estado = CR_ACABOU;
  sb_terminar(a, &g_b, NIVEL_SAIU);
}

/* ---------- o robô: fala na vez dele, fica mudo, olha a luz ---------- */

static void robo(App *a, int s, Jogador *j, Pad *p, float dt) {
  int idx = (int)(p - a->pads.pad);
  switch (g_estado) {
  case CR_CHAMADO:
    if (g_slot_faixa[g_vez] == s && !j->robo_falou && g_t > 0.4f) {
      robo_falar(a, idx, 0.8f, 1.2f);
      j->robo_falou = true;
    }
    break;
  case CR_MUDO:
    if (!j->m.apertou_mudo) {
      if (j->robo_espera < 0)
        j->robo_espera = 0.6f + 0.8f * robo_acaso();
      j->robo_espera -= dt;
      if (j->robo_espera <= 0) {
        robo_apertar(a, idx, SDL_GAMEPAD_BUTTON_MISC1, 0.08f);
        j->robo_espera = 1.5f; /* se não chegou, tenta de novo */
      }
    }
    break;
  case CR_SUSSURRO:
    if (!j->robo_falou && g_t > 0.5f) {
      robo_falar(a, idx, 0.35f, 1.5f);
      j->robo_falou = true;
    }
    break;
  case CR_LUZ:
    if (j->fase == LZ_OLHAR && j->resp < 0) {
      if (j->robo_espera < 0)
        j->robo_espera = LUZ_ESPERA + 0.2f + 0.8f * robo_acaso();
      j->robo_espera -= dt;
      if (j->robo_espera <= 0) {
        const Percepcao *pc = simulador_percepcao(p->id);
        int visto = pc ? pc->led_mic : 0;
        robo_apertar(a, idx, BOTAO_LUZ[visto >= 2 ? 2 : visto], 0.08f);
        j->robo_espera = 99;
      }
    }
    break;
  default:
    break;
  }
}

/* ---------- o laço ---------- */

static void medir(App *a, float dt) {
  for (int i = 0; i < g_n_faixas; i++) {
    int s = g_slot_faixa[i];
    Jogador *j = &g_j[s];
    if (!g_b.jogando[s])
      continue;
    float nivel = somc_mic_nivel(a, s);
    j->chama = aproximar(j->chama, j->mudo ? 0 : nivel, 8, dt);
    if (!j->m.tem)
      continue;
    switch (g_estado) {
    case CR_SILENCIO:
      if (g_t >= 1.0f) { /* o primeiro segundo é de quem ainda está calando */
        j->soma_piso += nivel;
        j->n_piso++;
        j->m.piso = (float)(j->soma_piso / j->n_piso);
        j->m.viu_piso = true;
      }
      break;
    case CR_CHAMADO:
      if (g_slot_faixa[g_vez] == s) {
        j->m.voz = fmaxf(j->m.voz, nivel);
        if (nivel - j->m.piso >= MED_VOZ_ACIMA + 0.05f)
          j->acima_t += dt;
      }
      break;
    case CR_SUSSURRO:
      if (j->mudo) {
        j->m.mudo = fmaxf(j->m.mudo, nivel);
        j->m.viu_mudo = true;
      }
      break;
    default:
      break;
    }
  }
}

static void atualizar_luz(App *a, int s, Jogador *j, Pad *p, float pan, float dt) {
  j->t += dt;
  if (j->fase == LZ_OLHAR) {
    if (j->t >= LUZ_ESPERA)
      for (int k = 0; k < 3 && j->resp < 0; k++)
        if (pad_apertou(p, BOTAO_LUZ[k])) {
          j->resp = k;
          som_evento_pan(&a->som, SOM_TICK, 0.4f, pan);
        }
    if (j->resp >= 0 || j->t >= LUZ_ESPERA + LUZ_MAX) {
      const char *res;
      if (j->resp == j->modo) {
        cega_certo(&j->luz);
        sb_pontos(a, &g_b, s, 100);
        res = "certo";
      } else if (j->resp >= 0) {
        cega_errado(&j->luz, j->resp);
        res = "errado";
      } else {
        cega_perdido(&j->luz);
        res = "perdido";
      }
      evento(a, s, "luz", "resultado", fmt("%s (era %s)", res, NOME_LUZ[j->modo]));
      j->fase = LZ_REVELA;
      j->t = 0;
    }
  } else if (j->fase == LZ_REVELA && j->t >= LUZ_REVELA) {
    j->rodada++;
    if (cega_led_mic_decidida(&j->luz) || j->rodada >= LUZ_RODADAS) {
      j->fase = LZ_FIM;
      pad_led_mic(a, p, 0);
    } else {
      luz_rodada(a, s, j);
    }
  }
}

static void atualizar(App *a, float dt) {
  int fase = sb_atualizar(a, &g_b, dt);
  g_n_faixas = sb_faixas(a, &g_b, FAIXAS_COLUNAS, AREA, g_faixa, g_slot_faixa);
  g_flash = fmaxf(0, g_flash - dt * 0.9f);
  if (fase != FASE_JOGO || g_estado == CR_ACABOU)
    return;
  if (!g_comecou)
    comecar(a);
  for (int i = 0; i < g_n_faixas; i++) {
    int s = g_slot_faixa[i];
    Pad *p = pads_do_slot(a, s);
    if (p && g_b.jogando[s] && robo_ativo())
      robo(a, s, &g_j[s], p, dt);
  }
  g_t += dt;
  medir(a, dt);
  /* os olhos do guardião: fechados no silêncio, abrindo com as vozes */
  float alvo_olhos = g_estado == CR_SILENCIO ? 0 : g_estado == CR_CHAMADO ? 0.4f : g_estado == CR_ESPERA ? 0.15f : 1;
  g_olhos = aproximar(g_olhos, alvo_olhos, 3, dt);

  switch (g_estado) {
  case CR_SILENCIO:
    if (g_t >= SILENCIO_S) {
      for (int s = 0; s < MAX_JOGADORES; s++)
        if (g_b.jogando[s] && g_j[s].m.viu_piso)
          evento(a, s, "silêncio", "piso", fmt("%.2f", g_j[s].m.piso));
      g_estado = CR_CHAMADO;
      g_t = 0;
      g_vez = proxima_vez(a, 0);
      if (g_vez < 0) {
        g_estado = CR_MUDO;
      }
    }
    break;
  case CR_CHAMADO: {
    int s = g_slot_faixa[g_vez];
    Jogador *j = &g_j[s];
    if (!j->chamou && j->acima_t >= 0.5f) {
      j->chamou = true;
      som_evento_pan(&a->som, SOM_BIGORNA, 0.5f, sb_pan(g_faixa[g_vez]));
      sb_pontos(a, &g_b, s, 150);
      g_t = fmaxf(g_t, CHAMADO_MAX - 0.8f); /* ainda um instante de chama acesa */
    }
    if (g_t >= CHAMADO_MAX || !pads_do_slot(a, s)) {
      evento(a, s, "chamado", "voz", fmt("%.2f", j->m.voz));
      g_t = 0;
      g_vez = proxima_vez(a, g_vez + 1);
      if (g_vez < 0) {
        g_estado = CR_MUDO;
        som_evento(&a->som, SOM_SOPRO, 0.6f);
      }
    }
    break;
  }
  case CR_MUDO: {
    bool todos = true;
    for (int i = 0; i < g_n_faixas; i++) {
      int s = g_slot_faixa[i];
      Pad *p = pads_do_slot(a, s);
      Jogador *j = &g_j[s];
      if (!p || !g_b.jogando[s])
        continue;
      j->m.pediu_mudo = true;
      if (!j->m.apertou_mudo && pad_apertou(p, SDL_GAMEPAD_BUTTON_MISC1)) {
        j->m.apertou_mudo = true;
        j->mudo = true;
        pad_led_mic(a, p, 1); /* o jogo fica mudo: a luz laranja acende, como no console */
        som_evento_pan(&a->som, SOM_TICK, 0.5f, sb_pan(g_faixa[i]));
        sb_pontos(a, &g_b, s, 100);
        sb_marco(a, s, "o botão do microfone chegou", NULL);
      }
      if (!j->m.apertou_mudo)
        todos = false;
    }
    if (todos || g_t >= MUDO_MAX) {
      g_estado = CR_SUSSURRO;
      g_t = 0;
      for (int s = 0; s < MAX_JOGADORES; s++)
        g_j[s].robo_falou = false;
    }
    break;
  }
  case CR_SUSSURRO:
    if (g_t >= SUSSURRO_S)
      comecar_luz(a);
    break;
  case CR_LUZ: {
    bool todos = true;
    for (int i = 0; i < g_n_faixas; i++) {
      int s = g_slot_faixa[i];
      Pad *p = pads_do_slot(a, s);
      if (!p || !g_b.jogando[s])
        continue;
      if (g_j[s].fase != LZ_FIM)
        atualizar_luz(a, s, &g_j[s], p, sb_pan(g_faixa[i]), dt);
      if (g_j[s].fase != LZ_FIM)
        todos = false;
    }
    if (todos) {
      g_estado = CR_ESPERA;
      g_t = 0;
    }
    break;
  }
  case CR_ESPERA:
    if (g_t >= ESPERA_S) {
      g_estado = CR_SUSTO;
      g_t = 0;
      susto(a);
    }
    break;
  case CR_SUSTO:
    if (g_t >= SUSTO_S) {
      for (int s = 0; s < MAX_JOGADORES; s++) {
        Pad *p = pads_do_slot(a, s);
        if (p)
          pad_luz_do_slot(a, p);
      }
      terminar(a);
    }
    break;
  case CR_ACABOU:
    break;
  }
}

/* ---------- desenho ---------- */

/* O guardião: a máscara de bronze. `olhos` 0 fechados .. 1 abertos e acesos;
 * `grito` abre a boca, com os dentes, no susto. */
static void guardiao(SDL_Renderer *r, float cx, float cy, float esc, float olhos, float grito, float t) {
  SDL_FPoint rosto[24];
  for (int i = 0; i < 24; i++) {
    float a = i * 2 * PI_F / 24;
    float rx = 118 * esc, ry = (a > 0 && a < PI_F ? 150 : 128) * esc; /* o queixo desce */
    rosto[i] = (SDL_FPoint){cx + cosf(a) * rx, cy + sinf(a) * ry};
  }
  ds_brilho(r, cx, cy, 260 * esc, COR_FALHA, 0.12f + 0.25f * olhos);
  ds_poligono(r, rosto, 24, (SDL_Color){92, 64, 38, 255});
  ds_polilinha(r, rosto, 24, 3, cor_alfa(COR_BRONZE, 0.9f), true);
  /* a testa franzida e o nariz */
  ds_linha(r, cx - 70 * esc, cy - 52 * esc, cx - 18 * esc, cy - 38 * esc, 5 * esc, COR_BRONZE_ESCURO);
  ds_linha(r, cx + 70 * esc, cy - 52 * esc, cx + 18 * esc, cy - 38 * esc, 5 * esc, COR_BRONZE_ESCURO);
  ds_linha(r, cx, cy - 30 * esc, cx - 10 * esc, cy + 30 * esc, 4 * esc, COR_BRONZE_ESCURO);
  for (int lado = -1; lado <= 1; lado += 2) {
    float ex = cx + lado * 48 * esc, ey = cy - 12 * esc;
    if (olhos < 0.1f) {
      ds_arco(r, ex, ey - 6 * esc, 20 * esc, 4 * esc, 0.2f, PI_F - 0.2f, COR_BRONZE_ESCURO);
    } else {
      float pulso = 0.8f + 0.2f * sinf(t * 6);
      ds_brilho(r, ex, ey, 60 * esc, COR_FALHA, olhos * pulso);
      ds_circulo(r, ex, ey, (6 + 10 * olhos) * esc, cor_mistura(COR_FALHA, COR_TEXTO, 0.2f * olhos));
    }
  }
  /* a boca: uma fenda; no susto, escancarada, com os dentes */
  if (grito <= 0) {
    ds_ret_arred(r, cx - 46 * esc, cy + 62 * esc, 92 * esc, (8 + 6 * olhos) * esc, 6 * esc, (SDL_Color){30, 16, 10, 255});
    return;
  }
  float bw = 70 * esc, bh = (20 + 60 * grito) * esc, by = cy + 50 * esc;
  SDL_FPoint boca[12];
  for (int i = 0; i < 12; i++) {
    float a = i * 2 * PI_F / 12;
    boca[i] = (SDL_FPoint){cx + cosf(a) * bw, by + bh / 2 + sinf(a) * bh / 2};
  }
  ds_poligono(r, boca, 12, (SDL_Color){24, 6, 4, 255});
  for (int k = 0; k < 6; k++) {
    float x = cx - bw * 0.75f + k * bw * 0.3f;
    ds_triangulo(r, (SDL_FPoint){x - 9 * esc, by + 6 * esc}, (SDL_FPoint){x + 9 * esc, by + 6 * esc},
                 (SDL_FPoint){x, by + (22 + 10 * grito) * esc}, (SDL_Color){236, 226, 206, 255});
    ds_triangulo(r, (SDL_FPoint){x - 9 * esc, by + bh - 4 * esc}, (SDL_FPoint){x + 9 * esc, by + bh - 4 * esc},
                 (SDL_FPoint){x, by + bh - (18 + 8 * grito) * esc}, (SDL_Color){236, 226, 206, 255});
  }
}

/* A luz do microfone, desenhada: a pílula apagada, acesa ou pulsando. */
static void led(SDL_Renderer *r, float cx, float cy, float esc, int modo, float t) {
  float brilho = modo == 1 ? 1 : modo == 2 ? 0.5f + 0.5f * sinf(t * 5) : 0;
  if (brilho > 0.05f)
    ds_brilho(r, cx, cy, 40 * esc, COR_LED, 0.7f * brilho);
  ds_ret_arred(r, cx - 16 * esc, cy - 6 * esc, 32 * esc, 12 * esc, 6 * esc,
               cor_mistura((SDL_Color){58, 44, 34, 255}, COR_LED, brilho));
  ds_contorno_arred(r, cx - 16 * esc, cy - 6 * esc, 32 * esc, 12 * esc, 6 * esc, 1.5f, cor_alfa(COR_BRONZE, 0.8f));
}

/* A tocha da voz: a chama cresce com o nível do microfone. */
static void tocha(SDL_Renderer *r, float cx, float cy, float nivel, SDL_Color cor, float t, bool apagada) {
  ds_ret_arred(r, cx - 9, cy, 18, 90, 4, COR_BRONZE_ESCURO);
  ds_ret_arred(r, cx - 20, cy - 6, 40, 14, 5, COR_BRONZE);
  if (apagada) {
    ds_circulo(r, cx, cy - 12, 5, cor_alfa(COR_TEXTO_3, 0.5f));
    return;
  }
  float h = 22 + 120 * nivel, w = 16 + 26 * nivel;
  ds_brilho(r, cx, cy - h * 0.5f, 60 + 160 * nivel, COR_BRASA, 0.35f + 0.6f * nivel);
  SDL_FPoint p[9];
  float tremor = sinf(t * 17) * 3 * (0.3f + nivel);
  p[0] = (SDL_FPoint){cx - w, cy - 8};
  p[1] = (SDL_FPoint){cx - w * 0.9f, cy - h * 0.35f};
  p[2] = (SDL_FPoint){cx - w * 0.45f, cy - h * 0.7f};
  p[3] = (SDL_FPoint){cx + tremor, cy - h};
  p[4] = (SDL_FPoint){cx + w * 0.45f, cy - h * 0.68f};
  p[5] = (SDL_FPoint){cx + w * 0.9f, cy - h * 0.32f};
  p[6] = (SDL_FPoint){cx + w, cy - 8};
  p[7] = (SDL_FPoint){cx + w * 0.3f, cy};
  p[8] = (SDL_FPoint){cx - w * 0.3f, cy};
  ds_poligono(r, p, 9, cor_mistura(COR_BRASA_VIVA, cor, 0.25f));
  for (int i = 0; i < 9; i++)
    p[i] = (SDL_FPoint){cx + (p[i].x - cx) * 0.5f, cy - 4 + (p[i].y - cy) * 0.55f};
  ds_poligono(r, p, 9, COR_OURO);
}

static void desenhar_faixa(App *a, int i, int s, Jogador *j, Pad *p, SDL_FRect f) {
  SDL_Renderer *r = a->r;
  float cx = f.x + f.w / 2;
  Fonte fd = f.w < 520 ? F_TEXTO_N : F_MEDIA_N;
  float ty = f.y + 84;
  bool vez = g_estado == CR_CHAMADO && g_vez == i;

  tocha(r, cx, f.y + f.h - 170, j->chama, COR_JOGADOR[s], a->t, j->mudo || !j->m.tem);
  /* o medidor do microfone, com a marca do silêncio */
  float mx = f.x + f.w - 50, my = f.y + 150, mh = f.h - 260;
  if (g_estado <= CR_SUSSURRO) {
    wg_medidor_vertical(r, mx, my, 16, mh, j->mudo ? 0 : somc_mic_nivel(a, s), somc_mic_pico(a, s), COR_JOGADOR[s]);
    if (j->m.viu_piso)
      ds_linha(r, mx - 6, my + mh * (1 - j->m.piso), mx + 22, my + mh * (1 - j->m.piso), 2, COR_TEXTO_2);
    if (j->mudo)
      icone(r, IC_MIC, mx + 8, my - 22, 26, COR_LED, 1);
  }

  switch (g_estado) {
  case CR_SILENCIO:
    texto_al(r, fd, cx, ty, COR_TEXTO, ALINHA_CENTRO, "silêncio");
    texto_al(r, F_PEQUENA, cx, ty + 40, COR_TEXTO_2, ALINHA_CENTRO, "o guardião dorme");
    break;
  case CR_CHAMADO:
    if (vez) {
      texto_al(r, fd, cx, ty, COR_OURO, ALINHA_CENTRO, j->chamou ? "ele ouviu!" : "chame o guardião!");
      texto_al(r, F_PEQUENA, cx, ty + 40, COR_TEXTO_2, ALINHA_CENTRO, "fale alto, perto do controle");
    } else {
      texto_al(r, fd, cx, ty, COR_TEXTO_3, ALINHA_CENTRO, j->chamou ? "ele ouviu você" : "quieto: não é a sua vez");
    }
    break;
  case CR_MUDO:
    if (!j->m.apertou_mudo) {
      wg_texto_rico(r, fd, cx, ty, COR_AVISO, ALINHA_CENTRO, "fique mudo: {MIC}");
      texto_al(r, F_PEQUENA, cx, ty + 40, COR_TEXTO_2, ALINHA_CENTRO, "o botão do microfone, embaixo do PS");
    } else {
      texto_al(r, fd, cx, ty, COR_OK, ALINHA_CENTRO, "mudo");
      texto_al(r, F_PEQUENA, cx, ty + 40, COR_TEXTO_2, ALINHA_CENTRO, "a luz laranja acendeu no controle");
    }
    break;
  case CR_SUSSURRO:
    texto_al(r, fd, cx, ty, COR_TEXTO, ALINHA_CENTRO, j->mudo ? "fale baixinho" : "quieto");
    texto_al(r, F_PEQUENA, cx, ty + 40, COR_TEXTO_2, ALINHA_CENTRO, j->mudo ? "mudo, ele não ouve você" : "sem o mudo");
    break;
  case CR_LUZ:
    if (j->fase == LZ_FIM) {
      texto_al(r, fd, cx, ty, COR_TEXTO_3, ALINHA_CENTRO, j->luz_ok || cega_total(&j->luz) ? "pronto" : "o LED não foi aceito");
      break;
    }
    texto_al(r, fd, cx, ty, COR_TEXTO, ALINHA_CENTRO, "olhe a luz do microfone");
    texto_al(r, F_PEQUENA, cx, ty + 40, COR_TEXTO_2, ALINHA_CENTRO, "no controle — a tela não mostra");
    for (int k = 0; k < 3; k++) {
      float w = fminf(120, (f.w - 60) / 3), x = cx + (k - 1) * (w + 10);
      float y = f.y + 250;
      bool certo = j->fase == LZ_REVELA && k == j->modo, errou = j->fase == LZ_REVELA && k == j->resp && k != j->modo;
      float al = j->fase == LZ_OLHAR ? (j->t >= LUZ_ESPERA ? 1 : 0.4f) : certo || errou ? 1 : 0.3f;
      ds_ret_arred(r, x - w / 2, y, w, 120, 10, cor_alfa(COR_PAINEL, 0.9f * al));
      ds_contorno_arred(r, x - w / 2, y, w, 120, 10, certo || errou ? 3 : 1.5f,
                        cor_alfa(certo ? COR_OK : errou ? COR_FALHA : COR_BRONZE_ESCURO, al));
      led(r, x, y + 30, 1.2f, k, a->t);
      icone_natural(r, ICONE_LUZ[k], x, y + 66, 24, al);
      texto_al(r, F_PEQUENA, x, y + 84, cor_alfa(COR_TEXTO, al), ALINHA_CENTRO, NOME_LUZ[k]);
    }
    break;
  case CR_ESPERA:
    texto_al(r, fd, cx, ty, COR_TEXTO_3, ALINHA_CENTRO, "...");
    break;
  default:
    break;
  }
  if (!j->m.tem && g_estado <= CR_SUSSURRO)
    texto_al(r, F_MINI, cx, f.y + f.h - 40, COR_AVISO, ALINHA_CENTRO, "microfone não achado");
  (void)p;
}

static void desenhar(App *a) {
  SDL_Renderer *r = a->r;
  ds_fundo(r, a->t, 0.08f);
  /* os arcos da cripta */
  for (int k = 0; k < 5; k++) {
    float x = 160 + k * 400;
    ds_arco(r, x, 330, 150, 14, PI_F, 2 * PI_F, cor_alfa(COR_BRONZE_ESCURO, 0.35f));
    ds_ret(r, x - 157, 330, 14, 700, cor_alfa(COR_BRONZE_ESCURO, 0.25f));
    ds_ret(r, x + 143, 330, 14, 700, cor_alfa(COR_BRONZE_ESCURO, 0.25f));
  }
  sb_desenhar_topo(a, &g_b);
  bool susto_agora = g_estado == CR_SUSTO || (g_estado == CR_ACABOU && g_flash > 0);
  if (susto_agora) {
    /* o susto: a cripta some no escuro, a máscara salta com a boca aberta e
     * treme; um clarão curto, e o vermelho que fica */
    float k = fminf(1, g_t * 6), tremor = 14 * g_flash;
    ds_ret(r, 0, 0, TELA_L, TELA_A, (SDL_Color){6, 2, 2, 235});
    ds_vinheta(r, 1.0f);
    guardiao(r, TELA_L / 2.0f + sinf(a->t * 90) * tremor, 470 + cosf(a->t * 70) * tremor, 1.2f + 1.3f * k, 1,
             fminf(1, g_t * 5), a->t);
  } else if (g_b.fase != FASE_AVISO) {
    guardiao(r, TELA_L / 2.0f, 172, 0.74f, g_olhos, 0, a->t);
  }
  for (int i = 0; i < g_n_faixas && !susto_agora; i++) {
    int s = g_slot_faixa[i];
    SDL_FRect f = g_faixa[i];
    Pad *p = pads_do_slot(a, s);
    bool vez = g_estado == CR_CHAMADO && g_vez == i;
    sb_moldura(a, f, s, vez ? 0.9f : 0.2f);
    if (g_b.fase != FASE_AVISO)
      desenhar_faixa(a, i, s, &g_j[s], p, f);
    sb_escudo(a, f, s);
    texto_al(r, F_GRANDE_N, f.x + f.w - 28, f.y + 14, COR_TEXTO, ALINHA_DIR, fmt("%d", g_b.pontos[s]));
    if (!p)
      sb_sem_controle(a, f, s);
  }
  if (susto_agora && g_t < 0.16f)
    ds_ret(r, 0, 0, TELA_L, TELA_A, cor_alfa(COR_TEXTO, 0.85f * (1 - g_t / 0.16f)));
  else if (g_flash > 0)
    ds_ret(r, 0, 0, TELA_L, TELA_A, cor_alfa(COR_FALHA, g_flash * 0.25f));
  if (g_b.fase == FASE_JOGO && !susto_agora) {
    const char *linha = g_estado == CR_SILENCIO  ? "silêncio: o guardião dorme"
                        : g_estado == CR_CHAMADO ? (g_vez >= 0 ? fmt("%s chama o guardião; os outros, quietos",
                                                                    pads_rotulo_slot(g_slot_faixa[g_vez]))
                                                              : "")
                        : g_estado == CR_MUDO     ? "ele acordou! fiquem mudos"
                        : g_estado == CR_SUSSURRO ? "mudos, ele não ouve: falem baixinho"
                        : g_estado == CR_LUZ      ? "como está a luz do SEU microfone?"
                        : g_estado == CR_ESPERA   ? "a cripta ficou quieta demais..."
                                                  : "";
    texto_al(r, F_MEDIA_N, TELA_L / 2.0f, 300, COR_TEXTO, ALINHA_CENTRO, linha);
  }
  particulas_desenhar(r, &a->brasas);
  if (g_b.fase == FASE_AVISO)
    sb_desenhar_aviso(a, &g_b,
                      "O guardião da cripta escuta pelo microfone do controle. Primeiro, todos em silêncio.\n"
                      "Depois, cada um na sua vez chama o guardião falando alto — os outros, quietos.\n"
                      "Quando ele acordar, fiquem mudos com {MIC}; e digam, olhando o controle, como está a luz\n"
                      "do microfone: {X} apagada, {O} acesa, {Q} piscando. Confira o seu microfone abaixo: fale e a barra sobe.");
  else if (g_b.fase == FASE_FIM)
    sb_desenhar_fim(a, &g_b);
  else if (g_estado == CR_LUZ) {
    Dica d[] = {{IC_CRUZ, "apagada"}, {IC_CIRCULO, "acesa"}, {IC_QUADRADO, "piscando"}, {IC_OPTIONS, "pausa"}};
    wg_rodape(r, d, 4);
  } else if (g_estado == CR_MUDO) {
    Dica d[] = {{IC_MIC, "ficar mudo"}, {IC_OPTIONS, "pausa"}};
    wg_rodape(r, d, 2);
  } else {
    Dica d[] = {{IC_OPTIONS, "pausa"}};
    wg_rodape(r, d, 1);
  }
  pausa_desenhar(a);
}

const Cena CENA_CRIPTA = {"cripta", entrar, sair, NULL, atualizar, desenhar};
