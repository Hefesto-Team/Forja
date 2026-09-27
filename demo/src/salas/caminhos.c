/* Os Caminhos — o chão que se sente na mão (ADR-002).
 *
 * O padrão é o da háptica dos jogos de PS5: o passo na grama não é o passo no
 * metal, e a mão sabe antes do olho. Aqui o autômato anda no escuro; a
 * lanterna mostra só ele, e o chão fica por conta dos atuadores do controle —
 * os canais 3 e 4 da placa de áudio do DualSense no cabo (ou o nó "Háptica do
 * Controle N" que o Hefesto cria). A prova é às cegas:
 *
 *   - o treino: os quatro chãos, um de cada vez, com o nome na tela;
 *   - depois, oito trechos no escuro: três passos e a pergunta "que chão é
 *     esse?" (✕ grama, ○ cascalho, □ metal, △ água; o touchpad é "não senti");
 *   - no meio do caminho, às vezes, uma pedra: o tropeço treme UM lado só, e
 *     a pessoa diz qual (L1 esquerda, R1 direita).
 *
 * O "não senti" é resposta, e é a evidência: quem diz "não senti" o caminho
 * inteiro mostra que a háptica não chega à mão. Quem não responde não
 * reprova ninguém (ADR-003). A TV fica calada sobre o chão: o passo só existe
 * no controle. */
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
#define RODADAS 8
#define PASSOS 3
#define TROPECOS 4
#define PRIMEIRO_S 0.35f
#define PASSO_S 0.9f /* entre um passo e outro: a cauda do metal (0,55 s) cabe */
#define TREINO_S 2.1f
#define PERGUNTA_MAX 6.0f
#define TROPECO_MAX 2.5f
#define REVELA_S 1.1f
#define ENV_MAX 64

typedef enum Estado { CM_TREINO = 0, CM_ANDA, CM_PERGUNTA, CM_REVELA, CM_FIM } Estado;

typedef struct Jogador {
  Estado estado;
  float t;
  int treino; /* o chão do treino agora */
  int rodada;
  int plano[RODADAS];
  int trop_lado[RODADAS]; /* -1: sem tropeço no trecho */
  int trop_passo[RODADAS];
  int passos; /* dados neste trecho (ou neste chão do treino) */
  bool trop_aberto;
  float trop_t;
  int trop_agora;
  int trop_disse;
  float trop_msg; /* o retorno do tropeço na tela, decai */
  int resp;       /* a resposta do chão; -1 nenhuma */
  Cega chao, le, ld;
  bool estereo;
  float fase;      /* das pernas */
  float cambaleio; /* o tropeço na tela, decai */
  /* o robô: o que a mão dele sente */
  float env[ENV_MAX];
  int n_env, silencio;
  bool gravando;
  float soma_e, soma_d;
  int votos[CHAO_TOTAL];
  int robo_lado;
  float robo_espera, robo_espera_trop;
} Jogador;

static const Feature FEATS[] = {F_HAPTICA_AUDIO};
static const SDL_GamepadButton BOTAO_CHAO[CHAO_TOTAL] = {SDL_GAMEPAD_BUTTON_SOUTH, SDL_GAMEPAD_BUTTON_EAST,
                                                         SDL_GAMEPAD_BUTTON_WEST, SDL_GAMEPAD_BUTTON_NORTH};
static const Icone ICONE_CHAO[CHAO_TOTAL] = {IC_CRUZ, IC_CIRCULO, IC_QUADRADO, IC_TRIANGULO};
static const SDL_Color COR_CHAO[CHAO_TOTAL] = {
    {86, 150, 78, 255}, {150, 134, 110, 255}, {132, 146, 164, 255}, {70, 128, 196, 255}};
static const char *SENTE[CHAO_TOTAL] = {"um baque macio", "quatro estalos", "um golpe que ressoa", "duas ondas"};

static SalaBase g_b;
static Jogador g_j[MAX_JOGADORES];
static SDL_FRect g_faixa[MAX_JOGADORES];
static int g_slot_faixa[MAX_JOGADORES], g_n_faixas;
static const SDL_FRect AREA = {40, 150, TELA_L - 80, TELA_A - 150 - 96};
static bool g_planejado, g_terminou;

static void entrar(App *a) {
  sb_entrar(a, &g_b, SALA_CAMINHOS, FEATS, 1, 0);
  sb_som(a, &g_b, PAPEL_HAPTICA);
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Jogador *j = &g_j[s];
    SDL_memset(j, 0, sizeof(*j));
    cega_zerar(&j->chao);
    cega_zerar(&j->le);
    cega_zerar(&j->ld);
    j->resp = j->trop_disse = j->robo_lado = -1;
    j->robo_espera = j->robo_espera_trop = -1;
  }
  g_planejado = g_terminou = false;
}

static void sair(App *a) {
  for (int s = 0; s < MAX_JOGADORES; s++)
    somc_parar_tudo(a, s);
  pads_silencio_todos(a);
}

static void evento(App *a, int slot, const char *o, const char *k1, const char *v1, const char *k2, const char *v2) {
  Evento ev;
  ev_iniciar(&ev, &a->lt, "jogo", slot + 1);
  ev_str(&ev, "sala", "caminhos");
  ev_str(&ev, "o", o);
  if (k1)
    ev_str(&ev, k1, v1);
  if (k2)
    ev_str(&ev, k2, v2);
  ev_fim(&ev, &a->lt);
}

/* Cada jogador tem o caminho dele, da mesma semente: os oito chãos (cada um
 * duas vezes, sem repetir seguido) e os quatro tropeços (dois de cada lado,
 * nunca no primeiro trecho nem no último passo). Sem háptica estéreo, não há
 * lado a perguntar: o caminho fica sem pedras. */
static void planejar(App *a) {
  static const int CHAOS[CHAO_TOTAL] = {0, 1, 2, 3}, DUAS[CHAO_TOTAL] = {2, 2, 2, 2};
  static const int LADOS[2] = {0, 1}, CADA[2] = {TROPECOS / 2, TROPECOS / 2};
  for (int s = 0; s < MAX_JOGADORES; s++) {
    if (!g_b.jogando[s])
      continue;
    Jogador *j = &g_j[s];
    cegas_plano_fontes(&g_b.sorteio, CHAOS, DUAS, CHAO_TOTAL, j->plano, RODADAS);
    for (int r = 0; r < RODADAS; r++)
      j->trop_lado[r] = -1;
    j->estereo = somc_estereo(a, s, PAPEL_HAPTICA);
    int trechos[RODADAS - 1], lados[TROPECOS];
    for (int r = 0; r < RODADAS - 1; r++)
      trechos[r] = r + 1;
    sorteio_embaralhar(&g_b.sorteio, trechos, RODADAS - 1);
    cegas_plano_fontes(&g_b.sorteio, LADOS, CADA, 2, lados, TROPECOS);
    for (int k = 0; k < TROPECOS && j->estereo; k++) {
      j->trop_lado[trechos[k]] = lados[k];
      j->trop_passo[trechos[k]] = sorteio_entre(&g_b.sorteio, 0, PASSOS - 2);
    }
  }
  g_planejado = true;
}

static void tocar_passo(App *a, int s, int chao, int variacao) {
  const Som *so = &sons_salas()->passo[chao][variacao % 3];
  somc_haptica(a, s, so, so, 1.0f);
}

static void comecar_trecho(Jogador *j) {
  j->estado = CM_ANDA;
  j->t = 0;
  j->passos = 0;
  j->resp = -1;
  SDL_memset(j->votos, 0, sizeof(j->votos));
  j->robo_espera = -1;
}

static void fechar_tropeco(App *a, int s, Jogador *j, int disse) {
  Cega *c = j->trop_agora == 0 ? &j->le : &j->ld;
  const char *res;
  if (disse == j->trop_agora) {
    cega_certo(c);
    sb_pontos(a, &g_b, s, 100);
    res = "certo";
  } else if (disse >= 0) {
    cega_errado(c, disse);
    res = disse == CAMINHO_NADA_LADO ? "não senti" : "errado";
  } else {
    cega_perdido(c);
    res = "perdido";
  }
  j->trop_aberto = false;
  j->trop_disse = disse;
  j->trop_msg = 1.3f;
  evento(a, s, "tropeço", "lado", j->trop_agora ? "direita" : "esquerda", "resultado", res);
}

static void fechar_pergunta(App *a, int s, Jogador *j, float pan) {
  int certo = j->plano[j->rodada];
  const char *res;
  if (j->resp == certo) {
    cega_certo(&j->chao);
    sb_pontos(a, &g_b, s, 100);
    som_evento_pan(&a->som, SOM_SUCESSO, 0.35f, pan);
    res = "certo";
  } else if (j->resp >= 0) {
    cega_errado(&j->chao, j->resp);
    som_evento_pan(&a->som, SOM_FALHA, 0.25f, pan);
    res = j->resp == CAMINHO_NADA ? "não senti" : "errado";
  } else {
    cega_perdido(&j->chao);
    res = "perdido";
  }
  j->estado = CM_REVELA;
  j->t = 0;
  evento(a, s, "resposta", "chão", chao_nome((Chao)certo), "resultado", res);
}

static void terminar(App *a) {
  for (int s = 0; s < MAX_JOGADORES; s++) {
    if (!g_b.jogando[s])
      continue;
    Jogador *j = &g_j[s];
    if (j->trop_aberto)
      fechar_tropeco(a, s, j, -1);
    Veredito v = cega_haptica_veredito(&j->chao, &j->le, &j->ld, somc_tem(a, s, PAPEL_HAPTICA));
    if (somc_tem(a, s, PAPEL_HAPTICA) && !j->estereo && v.resultado != RES_NAO_MEDIDO) {
      size_t n = SDL_strlen(v.obs);
      snprintf(v.obs + n, sizeof(v.obs) - n, "%sa háptica achada tem um canal só: o lado do tropeço não foi perguntado",
               n ? "; " : "");
    }
    sb_veredito(&g_b, s, F_HAPTICA_AUDIO, &v);
  }
  g_terminou = true;
  sb_terminar(a, &g_b, NIVEL_SAIU);
}

/* ---------- o robô: sente os atuadores do controle dele ---------- */

static void robo_sentir(App *a, int s, Jogador *j) {
  float e = somc_virtual_atuador(a, s, 0), d = somc_virtual_atuador(a, s, 1);
  float nivel = fmaxf(e, d);
  if (!j->gravando && nivel > 0.05f) {
    j->gravando = true;
    j->n_env = 0;
    j->env[j->n_env++] = 0;
    j->env[j->n_env++] = 0;
    j->soma_e = j->soma_d = 0;
    j->silencio = 0;
  }
  if (!j->gravando)
    return;
  if (j->n_env < ENV_MAX)
    j->env[j->n_env++] = nivel;
  j->soma_e += e;
  j->soma_d += d;
  j->silencio = nivel < 0.02f ? j->silencio + 1 : 0;
  /* 0,2 s de silêncio fecham o toque: a água tem um vão de 0,1 s entre as
   * duas ondas, que não pode partir um passo em dois */
  if (j->silencio < 12 && j->n_env < ENV_MAX)
    return;
  /* acabou um toque: dos dois lados por igual é passo; de um lado só, tropeço */
  j->gravando = false;
  float mx = fmaxf(j->soma_e, j->soma_d), mn = fminf(j->soma_e, j->soma_d);
  if (mx <= 0)
    return;
  if (mn < 0.3f * mx) {
    j->robo_lado = j->soma_e > j->soma_d ? 0 : 1;
  } else {
    int c = chao_pelo_envelope(j->env, j->n_env);
    if (c >= 0 && c < CHAO_TOTAL)
      j->votos[c]++;
  }
}

static void robo(App *a, int s, Jogador *j, Pad *p, float dt) {
  int idx = (int)(p - a->pads.pad);
  robo_sentir(a, s, j);
  if (j->trop_aberto) {
    if (j->robo_espera_trop < 0)
      j->robo_espera_trop = 0.55f + 0.4f * robo_acaso();
    j->robo_espera_trop -= dt;
    if (j->robo_espera_trop <= 0) {
      robo_apertar(a, idx,
                   j->robo_lado == 0   ? SDL_GAMEPAD_BUTTON_LEFT_SHOULDER
                   : j->robo_lado == 1 ? SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER
                                       : SDL_GAMEPAD_BUTTON_TOUCHPAD,
                   0.08f);
      j->robo_espera_trop = 99;
    }
  }
  if (j->estado == CM_PERGUNTA && j->resp < 0) {
    if (j->robo_espera < 0)
      j->robo_espera = 0.5f + 0.6f * robo_acaso();
    j->robo_espera -= dt;
    if (j->robo_espera <= 0) {
      int melhor = -1, mv = 0;
      for (int c = 0; c < CHAO_TOTAL; c++)
        if (j->votos[c] > mv) {
          mv = j->votos[c];
          melhor = c;
        }
      robo_apertar(a, idx, melhor >= 0 ? BOTAO_CHAO[melhor] : SDL_GAMEPAD_BUTTON_TOUCHPAD, 0.08f);
      j->robo_espera = 99;
    }
  }
}

/* ---------- o laço ---------- */

static void atualizar_jogador(App *a, int s, Jogador *j, Pad *p, float pan, float dt) {
  j->t += dt;
  j->cambaleio = aproximar(j->cambaleio, 0, 3, dt);
  j->trop_msg = fmaxf(0, j->trop_msg - dt);
  j->fase = aproximar(j->fase, PI_F * (float)(j->passos + j->rodada * PASSOS), 10, dt);

  if (j->trop_aberto) {
    j->trop_t += dt;
    int disse = -1;
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_LEFT_SHOULDER))
      disse = 0;
    else if (pad_apertou(p, SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER))
      disse = 1;
    else if (pad_apertou(p, SDL_GAMEPAD_BUTTON_TOUCHPAD))
      disse = CAMINHO_NADA_LADO;
    if (disse >= 0)
      som_evento_pan(&a->som, SOM_TICK, 0.4f, pan);
    if (disse >= 0 || j->trop_t >= TROPECO_MAX)
      fechar_tropeco(a, s, j, disse);
  }

  switch (j->estado) {
  case CM_TREINO:
    if (j->passos < 2 && j->t >= PRIMEIRO_S + j->passos * PASSO_S) {
      tocar_passo(a, s, j->treino, j->passos);
      j->passos++;
    }
    if (j->t >= TREINO_S) {
      j->treino++;
      j->passos = 0;
      j->t = 0;
      if (j->treino >= CHAO_TOTAL)
        comecar_trecho(j);
    }
    break;
  case CM_ANDA: {
    int r = j->rodada;
    if (j->passos < PASSOS && j->t >= PRIMEIRO_S + j->passos * PASSO_S) {
      if (j->trop_lado[r] >= 0 && j->passos == j->trop_passo[r]) {
        const Som *so = &sons_salas()->tropeco;
        somc_haptica(a, s, j->trop_lado[r] == 0 ? so : NULL, j->trop_lado[r] == 1 ? so : NULL, 1.0f);
        j->trop_aberto = true;
        j->trop_t = 0;
        j->trop_agora = j->trop_lado[r];
        j->trop_disse = -1;
        j->cambaleio = 1;
        j->robo_lado = -1;
        j->robo_espera_trop = -1;
      } else {
        tocar_passo(a, s, j->plano[r], j->passos + r);
      }
      j->passos++;
    }
    if (j->passos >= PASSOS && !j->trop_aberto && j->t >= PRIMEIRO_S + (PASSOS - 1) * PASSO_S + 0.7f) {
      j->estado = CM_PERGUNTA;
      j->t = 0;
    }
    break;
  }
  case CM_PERGUNTA:
    for (int c = 0; c < CHAO_TOTAL && j->resp < 0; c++)
      if (pad_apertou(p, BOTAO_CHAO[c]))
        j->resp = c;
    if (j->resp < 0 && pad_apertou(p, SDL_GAMEPAD_BUTTON_TOUCHPAD))
      j->resp = CAMINHO_NADA;
    if (j->resp >= 0 || j->t >= PERGUNTA_MAX)
      fechar_pergunta(a, s, j, pan);
    break;
  case CM_REVELA:
    if (j->t >= REVELA_S) {
      j->rodada++;
      if (j->rodada >= RODADAS) {
        j->estado = CM_FIM;
        g_b.acabou[s] = true;
      } else {
        comecar_trecho(j);
      }
    }
    break;
  case CM_FIM:
    break;
  }
}

static void atualizar(App *a, float dt) {
  int fase = sb_atualizar(a, &g_b, dt);
  g_n_faixas = sb_faixas(a, &g_b, FAIXAS_COLUNAS, AREA, g_faixa, g_slot_faixa);
  if (fase != FASE_JOGO || g_terminou)
    return;
  if (!g_planejado)
    planejar(a);
  for (int i = 0; i < g_n_faixas; i++) {
    int s = g_slot_faixa[i];
    Pad *p = pads_do_slot(a, s);
    if (!p || !g_b.jogando[s])
      continue;
    if (robo_ativo())
      robo(a, s, &g_j[s], p, dt);
    atualizar_jogador(a, s, &g_j[s], p, sb_pan(g_faixa[i]), dt);
  }
  if (sb_todos_acabaram(a, &g_b))
    terminar(a);
}

/* ---------- desenho ---------- */

static float hash01(int i) {
  unsigned h = (unsigned)i * 2654435761u;
  h ^= h >> 15;
  h *= 2246822519u;
  h ^= h >> 13;
  return (float)(h & 0xFFFF) / 65535.0f;
}

/* O desenho de um chão num retângulo — a mesma assinatura que a mão sente,
 * para o olho: as folhas, as pedras, as placas, as ondas. */
static void desenhar_chao(SDL_Renderer *r, int c, float x, float y, float w, float h, float alfa, float t) {
  SDL_Color base = cor_escurecer(COR_CHAO[c], 0.62f), traco = cor_alfa(COR_CHAO[c], alfa);
  ds_ret_arred(r, x, y, w, h, fminf(14, h / 3), cor_alfa(base, alfa));
  int n = (int)(w * h / 900);
  switch (c) {
  case CHAO_GRAMA:
    for (int i = 0; i < n; i++) {
      float bx = x + 8 + hash01(i) * (w - 16), by = y + 12 + hash01(i + 97) * (h - 18);
      float v = sinf(t * 1.5f + i) * 2;
      ds_linha(r, bx, by, bx - 4 + v, by - 12, 2.5f, traco);
      ds_linha(r, bx + 4, by, bx + 6 + v, by - 10, 2.5f, traco);
    }
    break;
  case CHAO_CASCALHO:
    for (int i = 0; i < n + 4; i++) {
      float bx = x + 8 + hash01(i + 5) * (w - 16), by = y + 8 + hash01(i + 71) * (h - 16);
      ds_circulo(r, bx, by, 3 + hash01(i + 33) * 4, cor_alfa(cor_mistura(COR_CHAO[c], COR_TEXTO, hash01(i) * 0.3f), alfa));
    }
    break;
  case CHAO_METAL: {
    int placas = (int)fmaxf(2, w / 70);
    float pw = (w - 12) / placas;
    for (int k = 0; k < placas; k++) {
      float px = x + 6 + k * pw;
      ds_ret_arred(r, px + 2, y + 6, pw - 4, h - 12, 4, cor_alfa(cor_mistura(base, COR_CHAO[c], 0.35f), alfa));
      ds_linha(r, px + 6, y + 10, px + pw - 8, y + 10, 2, cor_alfa(COR_TEXTO, 0.25f * alfa));
      ds_circulo(r, px + 8, y + h - 12, 2.5f, traco);
      ds_circulo(r, px + pw - 10, y + h - 12, 2.5f, traco);
    }
    break;
  }
  default: {
    int ondas = (int)fmaxf(2, h / 22);
    for (int k = 0; k < ondas; k++) {
      SDL_FPoint pt[24];
      float yy = y + (k + 0.6f) * h / ondas;
      for (int i = 0; i < 24; i++) {
        float xx = x + 10 + (w - 20) * i / 23.0f;
        pt[i] = (SDL_FPoint){xx, yy + sinf(xx * 0.06f + t * 2 + k) * 3.5f};
      }
      ds_polilinha(r, pt, 24, 2.5f, traco, false);
    }
    break;
  }
  }
}

/* As quatro respostas: o chão, o botão e o nome. `marca` acende uma (o
 * treino, a resposta certa), `erro` pinta a resposta errada. */
static void desenhar_opcoes(App *a, SDL_FRect f, float y, float alfa, int marca, int erro) {
  SDL_Renderer *r = a->r;
  float esp = 10, w = (f.w - 40 - esp * 3) / CHAO_TOTAL, h = 116;
  for (int c = 0; c < CHAO_TOTAL; c++) {
    float x = f.x + 20 + c * (w + esp);
    SDL_Color borda = c == marca ? COR_OK : c == erro ? COR_FALHA : cor_alfa(COR_BRONZE_ESCURO, 0.9f);
    float al = c == marca || c == erro ? 1 : alfa;
    ds_ret_arred(r, x, y, w, h, 10, cor_alfa(COR_PAINEL, 0.9f * al));
    desenhar_chao(r, c, x + 8, y + 8, w - 16, 50, al, a->t);
    ds_contorno_arred(r, x, y, w, h, 10, c == marca || c == erro ? 3 : 1.5f, cor_alfa(borda, al));
    icone_natural(r, ICONE_CHAO[c], x + w / 2, y + 76, 24, al);
    texto_al(r, w < 90 ? F_MINI : F_PEQUENA, x + w / 2, y + 90, cor_alfa(COR_TEXTO, al), ALINHA_CENTRO,
             chao_nome((Chao)c));
  }
}

static void desenhar_faixa(App *a, int s, Jogador *j, Pad *p, SDL_FRect f) {
  SDL_Renderer *r = a->r;
  float cx = f.x + f.w / 2;
  Fonte fd = f.w < 520 ? F_TEXTO_N : F_MEDIA_N;
  float ty = f.y + 80;

  /* o caminho: a estrada no escuro, as pedras da beira descendo a cada passo */
  float topo = f.y + 150, pe = f.y + f.h - 250;
  float largura = fminf(260, f.w * 0.55f);
  ds_ret_grad(r, cx - largura / 2, topo, largura, pe - topo + 60, cor_alfa(COR_CARVAO, 0), cor_alfa(COR_CARVAO, 0.9f));
  float andou = j->fase / PI_F * 46;
  for (int k = 0; k < 9; k++) {
    float yy = topo + fmodf(k * 46 + andou, pe - topo + 60);
    float luz = limitar(1 - fabsf(yy - pe) / 260, 0, 1);
    ds_circulo(r, cx - largura / 2 - 10, yy, 4, cor_alfa(COR_BRONZE, 0.15f + 0.5f * luz));
    ds_circulo(r, cx + largura / 2 + 10, yy + 23, 4, cor_alfa(COR_BRONZE, 0.15f + 0.5f * luz));
  }
  /* o chão sob os pés: aceso no treino e depois da resposta; escuro andando */
  float cw = largura - 20, ch = 84, chy = pe - 36; /* o autômato fica de pé no meio dele */
  int chao_visto = -1;
  if (j->estado == CM_TREINO && j->treino < CHAO_TOTAL)
    chao_visto = j->treino;
  else if (j->estado == CM_REVELA)
    chao_visto = j->plano[j->rodada];
  ds_brilho(r, cx, pe, 190, COR_BRASA, 0.35f);
  if (chao_visto >= 0) {
    desenhar_chao(r, chao_visto, cx - cw / 2, chy, cw, ch, 1, a->t);
  } else {
    /* no escuro: só a borda tracejada de um chão que a mão ainda vai dizer */
    ds_ret_arred(r, cx - cw / 2, chy, cw, ch, 14, cor_alfa(COR_PAINEL, 0.9f));
    for (float x = cx - cw / 2 + 16; x < cx + cw / 2 - 16; x += 22) {
      ds_linha(r, x, chy, x + 11, chy, 2, cor_alfa(COR_BRONZE, 0.6f));
      ds_linha(r, x, chy + ch, x + 11, chy + ch, 2, cor_alfa(COR_BRONZE, 0.6f));
    }
  }
  Automato bon;
  automato_iniciar(&bon, cx + sinf(j->cambaleio * 18) * 10 * j->cambaleio, pe);
  bon.conectado = p != NULL;
  bon.olhar = -PI_F / 2;
  bon.passo = j->fase;
  bon.dano = j->cambaleio * 0.4f;
  automato_desenhar(r, &bon, COR_JOGADOR[s], 1.15f, a->t, -1);
  if (j->trop_aberto)
    texto_al(r, F_GRANDE_N, cx, pe - 150, COR_AVISO, ALINHA_CENTRO, "!");

  /* o texto da vez */
  switch (j->estado) {
  case CM_TREINO:
    if (j->treino < CHAO_TOTAL) {
      texto_al(r, fd, cx, ty, COR_TEXTO, ALINHA_CENTRO, fmt("treino: %s", chao_nome((Chao)j->treino)));
      texto_al(r, F_PEQUENA, cx, ty + 40, COR_TEXTO_2, ALINHA_CENTRO, fmt("sinta: %s", SENTE[j->treino]));
    }
    break;
  case CM_ANDA:
    if (j->trop_aberto) {
      texto_al(r, fd, cx, ty, COR_AVISO, ALINHA_CENTRO, "tropeçou! de que lado tremeu?");
      wg_texto_rico(r, F_PEQUENA, cx, ty + 40, COR_TEXTO_2, ALINHA_CENTRO, "{L1} esquerda · {R1} direita · {TP} não senti");
    } else {
      texto_al(r, fd, cx, ty, COR_TEXTO, ALINHA_CENTRO, "sinta o chão");
      texto_al(r, F_PEQUENA, cx, ty + 40, COR_TEXTO_2, ALINHA_CENTRO, fmt("trecho %d de %d", j->rodada + 1, RODADAS));
    }
    break;
  case CM_PERGUNTA:
    texto_al(r, fd, cx, ty, COR_TEXTO, ALINHA_CENTRO, "que chão é esse?");
    wg_barra(r, cx - 90, ty + 46, 180, 8, 1 - j->t / PERGUNTA_MAX, COR_BRASA);
    break;
  case CM_REVELA: {
    int certo = j->plano[j->rodada];
    const char *linha = j->resp == certo ? fmt("isso: %s", chao_nome((Chao)certo))
                        : j->resp == CAMINHO_NADA ? fmt("não sentiu: era %s", chao_nome((Chao)certo))
                        : j->resp >= 0             ? fmt("era %s", chao_nome((Chao)certo))
                                                   : fmt("sem resposta: era %s", chao_nome((Chao)certo));
    texto_al(r, fd, cx, ty, j->resp == certo ? COR_OK : j->resp >= 0 ? COR_FALHA : COR_TEXTO_3, ALINHA_CENTRO, linha);
    break;
  }
  case CM_FIM:
    texto_al(r, fd, cx, ty, COR_OURO, ALINHA_CENTRO, "caminho feito");
    texto_al(r, F_PEQUENA, cx, ty + 40, COR_TEXTO_2, ALINHA_CENTRO,
             fmt("%d de %d chãos certos", j->chao.certos, cega_total(&j->chao)));
    break;
  }
  if (j->trop_msg > 0 && !j->trop_aberto) {
    bool certo = j->trop_disse == j->trop_agora;
    const char *m = certo ? "tropeço: lado certo" : j->trop_disse < 0 ? "tropeço: sem resposta"
                                                  : j->trop_disse == CAMINHO_NADA_LADO ? "tropeço: não sentiu"
                                                                                       : "tropeço: o outro lado";
    texto_al(r, F_PEQUENA_N, cx, pe - 150, cor_alfa(certo ? COR_OK : COR_FALHA, fminf(1, j->trop_msg * 2)), ALINHA_CENTRO,
             m);
  }

  /* as respostas embaixo */
  float oy = f.y + f.h - 172;
  if (j->estado == CM_TREINO)
    desenhar_opcoes(a, f, oy, 0.35f, j->treino, -1);
  else if (j->estado == CM_PERGUNTA)
    desenhar_opcoes(a, f, oy, 1, -1, -1);
  else if (j->estado == CM_REVELA)
    desenhar_opcoes(a, f, oy, 0.35f, j->plano[j->rodada], j->resp >= 0 && j->resp < CHAO_TOTAL && j->resp != j->plano[j->rodada] ? j->resp : -1);
  else if (j->estado == CM_ANDA)
    desenhar_opcoes(a, f, oy, 0.2f, -1, -1);
  if (j->estado == CM_PERGUNTA)
    wg_texto_rico(r, F_PEQUENA, cx, f.y + f.h - 46, COR_TEXTO_2, ALINHA_CENTRO, "{TP} não senti nada");
  if (!somc_tem(a, s, PAPEL_HAPTICA))
    texto_al(r, F_MINI, cx, f.y + 120, COR_AVISO, ALINHA_CENTRO, "háptica não achada");
}

static void desenhar(App *a) {
  SDL_Renderer *r = a->r;
  ds_fundo(r, a->t, 0.25f);
  sb_desenhar_topo(a, &g_b);
  for (int i = 0; i < g_n_faixas; i++) {
    int s = g_slot_faixa[i];
    SDL_FRect f = g_faixa[i];
    Pad *p = pads_do_slot(a, s);
    sb_moldura(a, f, s, g_j[s].trop_aberto ? 0.8f : 0.2f);
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
                      "O autômato anda no escuro: o chão só existe na sua mão. Primeiro, um treino com os quatro chãos.\n"
                      "Depois, a cada trecho, diga o chão: {X} grama, {O} cascalho, {Q} metal, {T} água — {TP} se não sentiu.\n"
                      "Se ele tropeçar, um lado só treme: {L1} esquerda, {R1} direita.\n"
                      "Confira a háptica abaixo: {T} pulsa na esquerda e depois na direita; no cabo, são os canais 3 e 4.");
  else if (g_b.fase == FASE_FIM)
    sb_desenhar_fim(a, &g_b);
  else {
    Dica d[] = {{IC_CRUZ, "grama"}, {IC_CIRCULO, "cascalho"}, {IC_QUADRADO, "metal"}, {IC_TRIANGULO, "água"},
                {IC_TOUCHPAD, "não senti"}, {IC_OPTIONS, "pausa"}};
    wg_rodape(r, d, 6);
  }
  pausa_desenhar(a);
}

const Cena CENA_CAMINHOS = {"caminhos", entrar, sair, NULL, atualizar, desenhar};
