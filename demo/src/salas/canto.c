/* O Canto — o ritmo no alto-falante do controle (ADR-002).
 *
 * O padrão é o do alto-falante do DualSense nos jogos: o som que sai DA MÃO,
 * paralelo ao som da TV — a espada que zune no controle enquanto a música toca
 * na sala. Aqui a bigorna canta um ritmo curto, e a pergunta é a de sempre
 * nas salas de saída, às cegas:
 *
 *   - o canto sai no alto-falante de UM controle, ou na TV (a prova de
 *     controle: nessas vezes ninguém deveria dizer "foi no meu");
 *   - todos respondem: ✕ "cantou no meu controle", ○ "não foi no meu";
 *   - a tela revela de onde saiu, e o dono do canto repete o ritmo com ✕.
 *
 * O som anda no ar, e todo mundo ouve todo canto: a pergunta não é "ouviu?",
 * é "saiu da sua mão?". Quem diz "foi no meu" com o canto saindo em outro
 * lugar ouviu o próprio controle cantar o canto de outro — o som não ficou
 * no alto-falante certo. */
#include "sala_base.h"

#include "../cenas/pausa.h"
#include "../nucleo/cegas.h"
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
#define TV 9
#define NOTAS 4
#define MAX_RODADAS 24
#define PERGUNTA_MAX 5.0f
#define REPETE_MAX 5.0f

typedef enum Estado { CT_PREPARO = 0, CT_CANTO, CT_PERGUNTA, CT_REVELA, CT_REPETE, CT_ACABOU } Estado;

typedef struct Jogador {
  Cega meus;
  int fantasmas, chances;
  int resposta; /* -1 nenhuma, 1 "meu", 0 "não" */
  float toques[NOTAS];
  int n_toques;
  int acertos_ritmo;
  /* o robô: o nível que ouve, o vale desde o último ataque */
  float robo_nivel, robo_vale, robo_desde;
  bool robo_ouviu;
  float robo_onsets[NOTAS + 2];
  int robo_n_onsets;
  float robo_espera;
  int robo_toque;
} Jogador;

static const Feature FEATS[] = {F_ALTO_FALANTE};

static SalaBase g_b;
static Jogador g_j[MAX_JOGADORES];
static SDL_FRect g_faixa[MAX_JOGADORES];
static int g_slot_faixa[MAX_JOGADORES], g_n_faixas;
static const SDL_FRect AREA = {40, 330, TELA_L - 80, TELA_A - 330 - 96};

static int g_plano[MAX_RODADAS], g_n_plano, g_rodada;
static Estado g_estado;
static float g_t;
static float g_relogio; /* desde o começo do jogo; não volta a zero */
static float g_ritmo[NOTAS]; /* os instantes das notas, desde o começo do canto */
static int g_notas_tocadas;
static int g_fonte;
static bool g_planejado;

static void entrar(App *a) {
  sb_entrar(a, &g_b, SALA_CANTO, FEATS, 1, 0);
  sb_som(a, &g_b, PAPEL_ALTO_FALANTE);
  for (int s = 0; s < MAX_JOGADORES; s++) {
    SDL_memset(&g_j[s], 0, sizeof(g_j[s]));
    cega_zerar(&g_j[s].meus);
    g_j[s].resposta = -1;
  }
  g_n_plano = g_rodada = 0;
  g_estado = CT_PREPARO;
  g_t = g_relogio = 0;
  g_planejado = false;
}

static void sair(App *a) {
  for (int s = 0; s < MAX_JOGADORES; s++)
    somc_parar_tudo(a, s);
  pads_silencio_todos(a);
}

static void planejar(void) {
  int fontes[MAX_JOGADORES + 1], vezes[MAX_JOGADORES + 1], n = 0;
  int jogadores = 0;
  for (int s = 0; s < MAX_JOGADORES; s++)
    jogadores += g_b.jogando[s];
  int cada = jogadores <= 1 ? 3 : 2;
  for (int s = 0; s < MAX_JOGADORES; s++)
    if (g_b.jogando[s]) {
      fontes[n] = s;
      vezes[n++] = cada;
    }
  fontes[n] = TV;
  vezes[n++] = jogadores <= 1 ? 3 : 2;
  g_n_plano = cegas_plano_fontes(&g_b.sorteio, fontes, vezes, n, g_plano, MAX_RODADAS);
  g_planejado = true;
}

static void evento(App *a, int slot, const char *o, const char *chave, const char *valor) {
  Evento ev;
  ev_iniciar(&ev, &a->lt, "jogo", slot + 1);
  ev_str(&ev, "sala", "canto");
  ev_str(&ev, "o", o);
  if (chave)
    ev_str(&ev, chave, valor);
  ev_fim(&ev, &a->lt);
}

static void comecar_canto(App *a) {
  g_fonte = g_plano[g_rodada];
  /* o ritmo: quatro notas com intervalos sorteados */
  static const float INTERVALOS[3] = {0.24f, 0.36f, 0.52f};
  g_ritmo[0] = 0;
  for (int k = 1; k < NOTAS; k++)
    g_ritmo[k] = g_ritmo[k - 1] + INTERVALOS[sorteio_entre(&g_b.sorteio, 0, 2)];
  g_notas_tocadas = 0;
  g_estado = CT_CANTO;
  g_t = 0;
  for (int s = 0; s < MAX_JOGADORES; s++) {
    g_j[s].resposta = -1;
    g_j[s].n_toques = 0;
    g_j[s].robo_ouviu = false;
    g_j[s].robo_vale = 1;
    g_j[s].robo_desde = 1;
    g_j[s].robo_n_onsets = 0;
    g_j[s].robo_espera = -1;
    g_j[s].robo_toque = 0;
  }
  evento(a, g_fonte == TV ? -1 : g_fonte, "canto", "fonte", g_fonte == TV ? "tv" : pads_rotulo_slot(g_fonte));
}

static void tocar_nota(App *a, int k) {
  const SonsSalas *so = sons_salas();
  const Som *nota = k % 2 ? &so->nota_alta : &so->nota;
  if (g_fonte == TV)
    som_tocar(&a->som, nota, 0.7f, 0);
  else
    somc_falante(a, g_fonte, nota, 0.9f);
}

static void fechar_pergunta(App *a) {
  for (int s = 0; s < MAX_JOGADORES; s++) {
    if (!g_b.jogando[s] || !pads_do_slot(a, s))
      continue;
    Jogador *j = &g_j[s];
    const char *res;
    if (g_fonte == s) {
      if (j->resposta == 1) {
        cega_certo(&j->meus);
        sb_pontos(a, &g_b, s, 100);
        res = "certo";
      } else if (j->resposta == 0) {
        cega_errado(&j->meus, 0);
        res = "errado";
      } else {
        cega_perdido(&j->meus);
        res = "perdido";
      }
    } else {
      j->chances++;
      if (j->resposta == 1) {
        j->fantasmas++;
        res = "fantasma";
      } else {
        if (j->resposta == 0)
          sb_pontos(a, &g_b, s, 50);
        res = j->resposta == 0 ? "certo" : "perdido";
      }
    }
    evento(a, s, "resposta", "resultado", res);
  }
  g_estado = CT_REVELA;
  g_t = 0;
}

static void terminar(App *a) {
  for (int s = 0; s < MAX_JOGADORES; s++) {
    if (!g_b.jogando[s])
      continue;
    Veredito v = cega_alto_falante_veredito(&g_j[s].meus, g_j[s].fantasmas, g_j[s].chances,
                                            somc_tem(a, s, PAPEL_ALTO_FALANTE));
    sb_veredito(&g_b, s, F_ALTO_FALANTE, &v);
  }
  g_estado = CT_ACABOU;
  sb_terminar(a, &g_b, NIVEL_SAIU);
}

/* ---------- o robô: ouve o alto-falante do controle dele ---------- */

static void robo(App *a, int s, Jogador *j, Pad *p, float dt) {
  int idx = (int)(p - a->pads.pad);
  /* o ataque de uma nota: o nível sobe acima do vale deixado pela anterior (as
   * notas se encostam, e a cauda de uma ainda soa quando a outra bate) */
  float nivel = somc_virtual_falante(a, s);
  j->robo_nivel = nivel;
  j->robo_desde += dt;
  bool ataque = nivel > 0.12f && nivel - j->robo_vale > 0.10f && j->robo_desde > 0.12f;
  if (ataque) {
    j->robo_vale = nivel;
    j->robo_desde = 0;
  } else {
    j->robo_vale = fminf(j->robo_vale, nivel);
  }
  if (ataque && (g_estado == CT_CANTO || (g_estado == CT_PERGUNTA && g_t < 0.4f))) {
    j->robo_ouviu = true;
    if (j->robo_n_onsets < NOTAS + 2)
      j->robo_onsets[j->robo_n_onsets++] = g_relogio;
  }
  if (g_estado == CT_PERGUNTA && j->resposta < 0) {
    if (j->robo_espera < 0)
      j->robo_espera = 0.5f + 0.6f * robo_acaso();
    j->robo_espera -= dt;
    if (j->robo_espera <= 0) {
      robo_apertar(a, idx, j->robo_ouviu ? SDL_GAMEPAD_BUTTON_SOUTH : SDL_GAMEPAD_BUTTON_EAST, 0.08f);
      j->robo_espera = 99;
    }
  }
  if (g_estado == CT_REPETE && g_fonte == s && j->robo_n_onsets >= 2) {
    /* repete os intervalos que ouviu, a partir de 0,6 s */
    if (j->robo_toque < j->robo_n_onsets && j->robo_toque < NOTAS) {
      float quando = 0.6f + (j->robo_onsets[j->robo_toque] - j->robo_onsets[0]);
      if (g_t >= quando) {
        robo_apertar(a, idx, SDL_GAMEPAD_BUTTON_SOUTH, 0.06f);
        j->robo_toque++;
      }
    }
  }
}

/* ---------- o laço ---------- */

static void atualizar(App *a, float dt) {
  int fase = sb_atualizar(a, &g_b, dt);
  g_n_faixas = sb_faixas(a, &g_b, FAIXAS_COLUNAS, AREA, g_faixa, g_slot_faixa);
  if (fase != FASE_JOGO || g_estado == CT_ACABOU)
    return;
  if (!g_planejado)
    planejar();
  for (int i = 0; i < g_n_faixas; i++) {
    int s = g_slot_faixa[i];
    Pad *p = pads_do_slot(a, s);
    if (p && robo_ativo())
      robo(a, s, &g_j[s], p, dt);
  }
  g_t += dt;
  g_relogio += dt;
  switch (g_estado) {
  case CT_PREPARO:
    if (g_t >= 1.0f) {
      if (g_rodada >= g_n_plano)
        terminar(a);
      else
        comecar_canto(a);
    }
    break;
  case CT_CANTO:
    while (g_notas_tocadas < NOTAS && g_t >= g_ritmo[g_notas_tocadas])
      tocar_nota(a, g_notas_tocadas++);
    if (g_t >= g_ritmo[NOTAS - 1] + 0.5f) {
      g_estado = CT_PERGUNTA;
      g_t = 0;
    }
    break;
  case CT_PERGUNTA: {
    bool todos = true;
    for (int i = 0; i < g_n_faixas; i++) {
      int s = g_slot_faixa[i];
      Pad *p = pads_do_slot(a, s);
      if (!p)
        continue;
      Jogador *j = &g_j[s];
      if (j->resposta < 0) {
        if (pad_apertou(p, SDL_GAMEPAD_BUTTON_SOUTH))
          j->resposta = 1;
        else if (pad_apertou(p, SDL_GAMEPAD_BUTTON_EAST))
          j->resposta = 0;
        if (j->resposta >= 0)
          som_evento_pan(&a->som, SOM_TICK, 0.4f, sb_pan(g_faixa[i]));
      }
      if (j->resposta < 0)
        todos = false;
    }
    if (todos || g_t >= PERGUNTA_MAX)
      fechar_pergunta(a);
    break;
  }
  case CT_REVELA:
    if (g_t >= 1.4f) {
      g_t = 0;
      if (g_fonte != TV && pads_do_slot(a, g_fonte)) {
        g_estado = CT_REPETE;
      } else {
        g_rodada++;
        g_estado = CT_PREPARO;
      }
    }
    break;
  case CT_REPETE: {
    Pad *p = pads_do_slot(a, g_fonte);
    Jogador *j = &g_j[g_fonte];
    if (p && j->n_toques < NOTAS && pad_apertou(p, SDL_GAMEPAD_BUTTON_SOUTH)) {
      j->toques[j->n_toques++] = g_t;
      somc_falante(a, g_fonte, (j->n_toques - 1) % 2 ? &sons_salas()->nota_alta : &sons_salas()->nota, 0.6f);
    }
    if (j->n_toques >= NOTAS || g_t >= REPETE_MAX) {
      /* o ritmo: os intervalos comparados, com folga de 120 ms */
      int bons = 0;
      for (int k = 1; k < j->n_toques && k < NOTAS; k++) {
        float quer = g_ritmo[k] - g_ritmo[k - 1], fez = j->toques[k] - j->toques[k - 1];
        bons += fabsf(quer - fez) < 0.12f;
      }
      j->acertos_ritmo += bons;
      sb_pontos(a, &g_b, g_fonte, 100 * bons);
      if (bons == NOTAS - 1) {
        som_evento(&a->som, SOM_SUCESSO, 0.5f);
        particulas_brasas(&a->brasas, TELA_L / 2.0f, 200, 30, COR_OURO);
      }
      g_rodada++;
      g_estado = CT_PREPARO;
      g_t = 0;
    }
    break;
  }
  case CT_ACABOU:
    break;
  }
}

/* ---------- desenho ---------- */

/* O sino: a silhueta (coroa, ombro, cintura e a boca que abre) inclinada pelo
 * balanço, e o badalo embaixo. */
static void sino(SDL_Renderer *r, float cx, float cy, float esc, float balanco, SDL_Color cor, float brilho) {
  static const SDL_FPoint META[] = {{0, -44}, {8, -43}, {15, -39}, {19, -32}, {21, -22}, {22, -10}, {24, 2},
                                    {28, 14}, {34, 24}, {41, 31}, {44, 35}, {30, 37.5f}, {15, 38.5f}};
  enum { M = sizeof(META) / sizeof(META[0]) };
  SDL_FPoint base[2 * M]; /* o lado direito, o fundo e o lado esquerdo espelhado */
  int n = 0;
  for (int i = 0; i < M; i++)
    base[n++] = META[i];
  base[n++] = (SDL_FPoint){0, 39};
  for (int i = M - 1; i >= 1; i--)
    base[n++] = (SDL_FPoint){-META[i].x, META[i].y};
  float a = sinf(balanco) * 0.2f;
  float ca = cosf(a), sa = sinf(a);
  SDL_FPoint p[2 * M];
  for (int i = 0; i < n; i++)
    p[i] = (SDL_FPoint){cx + (base[i].x * ca - base[i].y * sa) * esc, cy + (base[i].x * sa + base[i].y * ca) * esc};
  if (brilho > 0.01f)
    ds_brilho(r, cx, cy, 120 * esc, COR_OURO, 0.5f * brilho);
  /* o badalo balança atrasado, por dentro da boca */
  float ab = sinf(balanco - 0.6f) * 0.3f;
  ds_circulo(r, cx + sinf(ab) * 44 * esc, cy + cosf(ab) * 44 * esc, 7 * esc, COR_BRONZE_ESCURO);
  ds_poligono(r, p, n, cor);
  ds_polilinha(r, p, n, 2, cor_alfa(COR_OURO, 0.8f), true);
  ds_anel(r, cx - 44 * sa * esc, cy - 49 * ca * esc, 5 * esc, 2.5f * esc, cor);
}

/* Uma colcheia desenhada (a fonte não tem o glifo): a cabeça inclinada, a
 * haste e a bandeira. */
static void nota(SDL_Renderer *r, float x, float y, float esc, SDL_Color c) {
  SDL_FPoint cab[10];
  for (int i = 0; i < 10; i++) {
    float t = i * 2 * PI_F / 10;
    float ex = cosf(t) * 9 * esc, ey = sinf(t) * 6 * esc;
    cab[i] = (SDL_FPoint){x + ex * 0.94f + ey * 0.34f, y - ex * 0.34f + ey * 0.94f};
  }
  ds_poligono(r, cab, 10, c);
  float hx = x + 8 * esc, topo = y - 34 * esc;
  ds_linha(r, hx, y - 2 * esc, hx, topo, 2.5f * esc, c);
  ds_linha(r, hx, topo, hx + 11 * esc, topo + 12 * esc, 3 * esc, c);
}

static void desenhar_faixa(App *a, int s, Jogador *j, Pad *p, SDL_FRect f) {
  SDL_Renderer *r = a->r;
  float cx = f.x + f.w / 2;
  bool dono = (g_estado == CT_REVELA || g_estado == CT_REPETE) && g_fonte == s;
  if (dono)
    ds_brilho(r, cx, f.y + f.h / 2, f.w * 0.6f, COR_OURO, 0.35f);
  Automato bon;
  automato_iniciar(&bon, cx, f.y + f.h - 150);
  bon.conectado = p != NULL;
  bon.olhar = -PI_F / 2;
  automato_desenhar(r, &bon, COR_JOGADOR[s], 1.1f, a->t, -1);
  sino(r, cx + 58, f.y + f.h - 230, 0.8f, dono && g_estado == CT_REPETE ? a->t * 10 : 0, (SDL_Color){176, 120, 56, 255},
       dono ? 1 : 0);

  Fonte fd = f.w < 520 ? F_PEQUENA_N : F_TEXTO_N;
  float ty = f.y + 90;
  switch (g_estado) {
  case CT_PERGUNTA:
    if (j->resposta < 0) {
      wg_texto_rico(r, fd, cx, ty, COR_TEXTO, ALINHA_CENTRO, "saiu no seu controle?");
      wg_texto_rico(r, F_PEQUENA, cx, ty + 40, COR_TEXTO_2, ALINHA_CENTRO, "{X} foi no meu · {O} não foi");
    } else {
      texto_al(r, fd, cx, ty, COR_TEXTO_2, ALINHA_CENTRO, "respondeu");
    }
    break;
  case CT_REVELA: {
    bool certo = (g_fonte == s) == (j->resposta == 1);
    const char *disse = j->resposta == 1 ? "disse: foi no meu" : j->resposta == 0 ? "disse: não foi no meu" : "não respondeu";
    texto_al(r, fd, cx, ty, j->resposta < 0 ? COR_TEXTO_3 : certo ? COR_OK : COR_FALHA, ALINHA_CENTRO, disse);
    if (dono)
      texto_al(r, F_PEQUENA_N, cx, ty + 40, COR_OURO, ALINHA_CENTRO, "o canto era seu");
    break;
  }
  case CT_REPETE:
    if (dono) {
      wg_texto_rico(r, fd, cx, ty, COR_OURO, ALINHA_CENTRO, "repita o ritmo com {X}");
      float x0 = f.x + 50, w = f.w - 100, total = g_ritmo[NOTAS - 1] + 0.3f;
      ds_linha(r, x0, ty + 70, x0 + w, ty + 70, 2, COR_BRONZE_ESCURO);
      for (int k = 0; k < NOTAS; k++)
        ds_circulo(r, x0 + w * g_ritmo[k] / total, ty + 70, 9, cor_alfa(COR_OURO, 0.6f));
      for (int k = 0; k < j->n_toques; k++) {
        float tk = j->toques[k] - j->toques[0];
        ds_anel(r, x0 + w * fminf(tk / total, 1), ty + 70, 13, 3, COR_JOGADOR[s]);
      }
    }
    break;
  default:
    break;
  }
  texto(r, F_PEQUENA, f.x + 80, f.y + 30, COR_TEXTO_2, fmt("ritmo: %d", j->acertos_ritmo));
  if (!somc_tem(a, s, PAPEL_ALTO_FALANTE))
    texto_al(r, F_MINI, cx, f.y + f.h - 36, COR_AVISO, ALINHA_CENTRO, "alto-falante não achado");
}

static void desenhar(App *a) {
  SDL_Renderer *r = a->r;
  ds_fundo(r, a->t, 0.4f);
  sb_desenhar_topo(a, &g_b);
  /* o coro da forja: o grande sino no alto, que é a TV */
  bool canta_tv = g_estado == CT_CANTO;
  bool revela_tv = (g_estado == CT_REVELA) && g_fonte == TV;
  float cx = TELA_L / 2.0f, cy = 185;
  sino(r, cx, cy, 1.25f, revela_tv ? a->t * 8 : canta_tv ? g_t * 6 : 0, (SDL_Color){150, 104, 50, 255},
       revela_tv ? 1 : 0);
  if (canta_tv) {
    /* as notas sobem do meio, sem apontar para ninguém */
    for (int k = 0; k < g_notas_tocadas; k++) {
      float idade = g_t - g_ritmo[k];
      float x = cx + (k % 2 ? 1 : -1) * (70 + idade * 40), y = cy - 20 - idade * 80;
      if (idade < 1)
        nota(r, x, y, 1.1f, cor_alfa(COR_OURO, 1 - idade));
    }
  }
  if (g_b.fase == FASE_JOGO && g_planejado) {
    const char *linha = g_estado == CT_CANTO      ? "ouçam: de onde vem o canto?"
                        : g_estado == CT_PERGUNTA ? "o canto saiu no SEU controle?"
                        : g_estado == CT_REVELA   ? (g_fonte == TV ? "o canto era da TV" : fmt("o canto era do %s", pads_rotulo_slot(g_fonte)))
                        : g_estado == CT_REPETE   ? fmt("%s repete o ritmo", pads_rotulo_slot(g_fonte))
                                                  : "";
    texto_al(r, F_MEDIA_N, cx, 272, COR_TEXTO, ALINHA_CENTRO, linha);
    /* os cantos da sala, em contas: cheias as que já foram */
    float passo = 24, x0 = cx - passo * (g_n_plano - 1) / 2.0f;
    for (int k = 0; k < g_n_plano; k++) {
      float x = x0 + passo * k;
      if (k < g_rodada)
        ds_circulo(r, x, 40, 6, COR_OURO);
      else if (k == g_rodada)
        ds_anel(r, x, 40, 8, 2.5f, COR_OURO);
      else
        ds_anel(r, x, 40, 6, 2, COR_BRONZE_ESCURO);
    }
  }
  for (int i = 0; i < g_n_faixas; i++) {
    int s = g_slot_faixa[i];
    SDL_FRect f = g_faixa[i];
    Pad *p = pads_do_slot(a, s);
    sb_moldura(a, f, s, (g_estado == CT_REVELA || g_estado == CT_REPETE) && g_fonte == s ? 0.9f : 0.2f);
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
                      "A bigorna canta um ritmo: às vezes no alto-falante de UM controle, às vezes na TV.\n"
                      "Todo mundo ouve. A pergunta é outra: o canto saiu da SUA mão?\n"
                      "{X} foi no meu, {O} não foi. Depois, quem era o dono do canto repete o ritmo com {X}.\n"
                      "Confira o seu alto-falante abaixo: {T} toca um sino nele; no cabo, é o canal 1 da placa.");
  else if (g_b.fase == FASE_FIM)
    sb_desenhar_fim(a, &g_b);
  else if (g_estado == CT_PERGUNTA) {
    Dica d[] = {{IC_CRUZ, "foi no meu"}, {IC_CIRCULO, "não foi"}, {IC_OPTIONS, "pausa"}};
    wg_rodape(r, d, 3);
  } else if (g_estado == CT_REPETE) {
    Dica d[] = {{IC_CRUZ, fmt("%s: repetir o ritmo", pads_rotulo_slot(g_fonte))}, {IC_OPTIONS, "pausa"}};
    wg_rodape(r, d, 2);
  } else {
    Dica d[] = {{IC_OPTIONS, "pausa"}};
    wg_rodape(r, d, 1);
  }
  pausa_desenhar(a);
}

const Cena CENA_CANTO = {"canto", entrar, sair, NULL, atualizar, desenhar};
