/* O Cerco — dano direcional e a vida na luz (ADR-002).
 *
 * O padrão é o dos jogos de ação do PS5: o tiro da esquerda treme SÓ o motor da
 * esquerda, a lightbar pisca vermelho quando o golpe acerta e a luz apaga
 * conforme a vida cai. A lightbar do DualSense é uma cor só para as duas
 * fendas: o lado do golpe vem do motor; a luz inteira pisca.
 *
 * E a sala é uma prova às cegas (cegas.h), porque saída o jogo não mede:
 *
 *   - no escuro, os golpes vêm um de cada vez, para um controle só; a tela não
 *     diz de que lado — só o motor diz. Quem sente levanta o escudo daquele
 *     lado (L1 esquerda, R1 direita). Acertar o lado prova o motor forte (a
 *     esquerda) e o fraco (a direita); errar sempre prova que chegam trocados;
 *   - quem levanta o escudo com o golpe indo para OUTRO controle sentiu uma
 *     vibração que não era dele: é o isolamento que falha;
 *   - no fim de cada onda, cada controle acende uma cor sorteada, e a pessoa
 *     diz qual é olhando o plástico (a tela não mostra): é a lightbar.
 *
 * A tela só revela o lado DEPOIS da resposta — o golpe voa, e bate no escudo
 * ou no autômato. */
#include "sala_base.h"

#include "../cenas/pausa.h"
#include "../nucleo/cegas.h"
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
#define POR_LADO 5
#define ONDAS 3
#define JANELA 1.3f       /* s para levantar o escudo depois do golpe */
#define REVELA 0.5f       /* s da animação do golpe, depois da resposta */
#define GOLPE_MS 260      /* a vibração do golpe */
#define DANO 0.14f
#define VIDA_MIN 0.12f
#define PERGUNTA_MAX 9.0f /* s para dizer a cor */
#define MAX_TIROS (MAX_JOGADORES * POR_LADO * 2)
#define MAX_PERGUNTAS 5

typedef enum Estado { EC_PAUSA = 0, EC_GOLPE, EC_REVELA, EC_PERGUNTA, EC_RESPOSTA, EC_ACABOU } Estado;

typedef struct Cor {
  const char *nome;
  SDL_Color c;
} Cor;

/* longe das cores de jogador (azul, vermelho, verde, rosa), para não confundir */
static const Cor CORES[4] = {
    {"âmbar", {255, 150, 0, 255}},
    {"ciano", {0, 210, 255, 255}},
    {"violeta", {170, 70, 255, 255}},
    {"branco", {255, 255, 255, 255}},
};
static const SDL_GamepadButton BOTAO_COR[4] = {SDL_GAMEPAD_BUTTON_SOUTH, SDL_GAMEPAD_BUTTON_EAST,
                                               SDL_GAMEPAD_BUTTON_WEST, SDL_GAMEPAD_BUTTON_NORTH};
static const Icone ICONE_COR[4] = {IC_CRUZ, IC_CIRCULO, IC_QUADRADO, IC_TRIANGULO};

typedef struct Jogador {
  float vida;
  float pisca;       /* >0: a lightbar está no pisca vermelho */
  bool vermelho;     /* o último envio do pisca foi vermelho */
  Cega esq, dir;     /* os golpes de cada lado */
  int fantasmas, chances;
  bool reagiu;
  bool rumble_ok, luz_ok;
  Cega cor;
  int perguntas;
  int cor_pedida, cor_resposta, cor_antes;
  float escudo;      /* animação do escudo levantado */
  Lado escudo_lado;
  float interroga;   /* o "?" do escudo à toa */
  float dano;
  int bloqueios, combo;
  /* o robô */
  float robo_forte, robo_fraco;
  float robo_reage;
  Lado robo_lado;
  float robo_cor;
} Jogador;

static const Feature FEATS[] = {F_VIBRACAO_FORTE, F_VIBRACAO_FRACA, F_VIBRACAO_ISOLAMENTO, F_LIGHTBAR};

static SalaBase g_b;
static Jogador g_j[MAX_JOGADORES];
static SDL_FRect g_faixa[MAX_JOGADORES];
static int g_slot_faixa[MAX_JOGADORES], g_n_faixas;
static const SDL_FRect AREA = {40, 140, TELA_L - 80, TELA_A - 140 - 96};

static Tiro g_plano[MAX_TIROS];
static int g_n_plano, g_i_plano;
static int g_fim_onda[ONDAS];
static int g_onda;
static Estado g_estado;
static float g_t, g_espera;
static Tiro g_atual;
static int g_resposta; /* -1 perdido; senão o Lado respondido */
static bool g_respondido;
static bool g_planejado;

/* ---------- a luz: a cor do lugar, apagando com a vida ---------- */

static SDL_Color cor_da_vida(int s, float vida) {
  float k = 0.12f + 0.88f * limitar(vida, 0, 1);
  SDL_Color c = COR_LIGHTBAR[s];
  return (SDL_Color){(Uint8)(c.r * k), (Uint8)(c.g * k), (Uint8)(c.b * k), 255};
}

static void luz(App *a, int s, SDL_Color c) {
  Pad *p = pads_do_slot(a, s);
  if (!p)
    return;
  if (pad_luz(a, p, c))
    g_j[s].luz_ok = true;
}

static void luz_da_vida(App *a, int s) { luz(a, s, cor_da_vida(s, g_j[s].vida)); }

/* ---------- a sala ---------- */

static void entrar(App *a) {
  sb_entrar(a, &g_b, SALA_CERCO, FEATS, 4, 0);
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Jogador *j = &g_j[s];
    SDL_memset(j, 0, sizeof(*j));
    j->vida = 1;
    cega_zerar(&j->esq);
    cega_zerar(&j->dir);
    cega_zerar(&j->cor);
    j->cor_pedida = j->cor_resposta = j->cor_antes = -1;
    j->robo_reage = -1;
  }
  g_n_plano = g_i_plano = 0;
  g_onda = 0;
  g_estado = EC_PAUSA;
  g_t = 0;
  g_espera = 1.2f;
  g_planejado = false;
}

static void sair(App *a) { pads_silencio_todos(a); }

static void planejar(App *a) {
  int slots[MAX_JOGADORES], n = 0;
  for (int s = 0; s < MAX_JOGADORES; s++)
    if (g_b.jogando[s])
      slots[n++] = s;
  g_n_plano = cegas_plano_tiros(&g_b.sorteio, slots, n, POR_LADO, g_plano, MAX_TIROS);
  for (int k = 0; k < ONDAS; k++)
    g_fim_onda[k] = g_n_plano * (k + 1) / ONDAS;
  g_planejado = true;
  for (int i = 0; i < n; i++)
    luz_da_vida(a, slots[i]);
}

static void evento_jogo(App *a, int slot, const char *o, const char *chave, const char *valor) {
  Evento ev;
  ev_iniciar(&ev, &a->lt, "jogo", slot + 1);
  ev_str(&ev, "sala", "cerco");
  ev_str(&ev, "o", o);
  if (chave)
    ev_str(&ev, chave, valor);
  ev_fim(&ev, &a->lt);
}

static void iniciar_golpe(App *a) {
  /* o próximo alvo com controle; quem caiu da mesa perde o golpe (não conta) */
  while (g_i_plano < g_n_plano && !pads_do_slot(a, g_plano[g_i_plano].slot))
    g_i_plano++;
  if (g_i_plano >= g_n_plano)
    return;
  g_atual = g_plano[g_i_plano++];
  g_respondido = false;
  g_resposta = -1;
  g_estado = EC_GOLPE;
  g_t = 0;
  Pad *p = pads_do_slot(a, g_atual.slot);
  bool ok = pad_rumble(a, p, g_atual.lado == LADO_ESQ ? 1.0f : 0.0f, g_atual.lado == LADO_DIR ? 1.0f : 0.0f, GOLPE_MS);
  if (ok)
    g_j[g_atual.slot].rumble_ok = true;
  for (int s = 0; s < MAX_JOGADORES; s++)
    if (g_b.jogando[s] && s != g_atual.slot && pads_do_slot(a, s))
      g_j[s].chances++;
  evento_jogo(a, g_atual.slot, "golpe", "lado", g_atual.lado == LADO_ESQ ? "esquerda" : "direita");
  som_evento(&a->som, SOM_SOPRO, 0.5f); /* no centro: o som não entrega o lado */
}

static void resolver(App *a, int resposta) {
  int s = g_atual.slot;
  Jogador *j = &g_j[s];
  SDL_FRect f = {0};
  for (int i = 0; i < g_n_faixas; i++)
    if (g_slot_faixa[i] == s)
      f = g_faixa[i];
  g_respondido = true;
  g_resposta = resposta;
  const char *res;
  if (resposta == (int)g_atual.lado) {
    cega_certo(g_atual.lado == LADO_ESQ ? &j->esq : &j->dir);
    j->bloqueios++;
    j->combo++;
    sb_pontos(a, &g_b, s, 100 + (g_t < 0.6f ? 50 : 0) + 10 * (j->combo - 1));
    som_evento_pan(&a->som, SOM_BIGORNA, 0.7f, sb_pan(f));
    res = "certo";
  } else {
    if (resposta < 0)
      cega_perdido(g_atual.lado == LADO_ESQ ? &j->esq : &j->dir);
    else
      cega_errado(g_atual.lado == LADO_ESQ ? &j->esq : &j->dir, resposta);
    j->combo = 0;
    j->vida = fmaxf(VIDA_MIN, j->vida - DANO);
    j->dano = 1;
    j->pisca = 0.34f;
    j->vermelho = false; /* o primeiro quadro do pisca manda o vermelho */
    som_evento_pan(&a->som, SOM_FALHA, 0.5f, sb_pan(f));
    res = resposta < 0 ? "perdido" : "errado";
  }
  evento_jogo(a, s, "bloqueio", "resultado", res);
  g_estado = EC_REVELA;
  g_t = 0;
}

static void iniciar_pergunta(App *a) {
  g_estado = EC_PERGUNTA;
  g_t = 0;
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Jogador *j = &g_j[s];
    j->cor_pedida = j->cor_resposta = -1;
    if (!g_b.jogando[s] || !pads_do_slot(a, s) || cega_cor_decidida(&j->cor) || j->perguntas >= MAX_PERGUNTAS)
      continue;
    int c;
    do
      c = sorteio_entre(&g_b.sorteio, 0, 3);
    while (c == j->cor_antes);
    j->cor_pedida = c;
    j->cor_antes = c;
    j->perguntas++;
    j->pisca = 0;
    luz(a, s, CORES[c].c);
    Evento ev;
    ev_iniciar(&ev, &a->lt, "jogo", s + 1);
    ev_str(&ev, "sala", "cerco");
    ev_str(&ev, "o", "pergunta_cor");
    ev_str(&ev, "cor", CORES[c].nome);
    ev_fim(&ev, &a->lt);
  }
  som_evento(&a->som, SOM_CONFIRMA, 0.5f);
}

static bool alguem_pergunta(void) {
  for (int s = 0; s < MAX_JOGADORES; s++)
    if (g_j[s].cor_pedida >= 0)
      return true;
  return false;
}

static void fechar_pergunta(App *a) {
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Jogador *j = &g_j[s];
    if (j->cor_pedida < 0)
      continue;
    const char *res;
    if (j->cor_resposta < 0) {
      cega_perdido(&j->cor);
      res = "perdido";
    } else if (j->cor_resposta == j->cor_pedida) {
      cega_certo(&j->cor);
      sb_pontos(a, &g_b, s, 150);
      res = "certo";
    } else {
      cega_errado(&j->cor, j->cor_resposta);
      res = "errado";
    }
    evento_jogo(a, s, "resposta_cor", "resultado", res);
  }
  g_estado = EC_RESPOSTA;
  g_t = 0;
}

static bool precisa_mais_cor(App *a) {
  for (int s = 0; s < MAX_JOGADORES; s++)
    if (g_b.jogando[s] && pads_do_slot(a, s) && !cega_cor_decidida(&g_j[s].cor) && g_j[s].perguntas < MAX_PERGUNTAS)
      return true;
  return false;
}

static void terminar(App *a) {
  int jogando = 0;
  for (int s = 0; s < MAX_JOGADORES; s++)
    jogando += g_b.jogando[s];
  for (int s = 0; s < MAX_JOGADORES; s++) {
    if (!g_b.jogando[s])
      continue;
    Jogador *j = &g_j[s];
    Veredito v = cega_motor_veredito(&j->esq, LADO_ESQ, j->rumble_ok, j->reagiu);
    sb_explica_recusa(a, s, &v);
    sb_veredito(&g_b, s, F_VIBRACAO_FORTE, &v);
    v = cega_motor_veredito(&j->dir, LADO_DIR, j->rumble_ok, j->reagiu);
    sb_explica_recusa(a, s, &v);
    sb_veredito(&g_b, s, F_VIBRACAO_FRACA, &v);
    Cega meus = j->esq;
    meus.certos += j->dir.certos;
    meus.errados += j->dir.errados;
    meus.perdidos += j->dir.perdidos;
    v = cega_isolamento_veredito(j->fantasmas, j->chances, jogando - 1, &meus);
    sb_explica_recusa(a, s, &v);
    sb_veredito(&g_b, s, F_VIBRACAO_ISOLAMENTO, &v);
    v = cega_cor_veredito(&j->cor, j->luz_ok);
    sb_explica_recusa(a, s, &v);
    sb_veredito(&g_b, s, F_LIGHTBAR, &v);
    if (a->cfg.intensidade < 0.5f) {
      Veredito *vs[2] = {&g_b.vered[s][0], &g_b.vered[s][1]};
      for (int k = 0; k < 2; k++) {
        size_t n = SDL_strlen(vs[k]->obs);
        SDL_snprintf(vs[k]->obs + n, sizeof(vs[k]->obs) - n, "%sa intensidade da vibração estava em %d%% (pausa)",
                     n ? "; " : "", (int)(a->cfg.intensidade * 100 + 0.5f));
      }
    }
  }
  g_estado = EC_ACABOU;
  sb_terminar(a, &g_b, NIVEL_SAIU);
}

/* ---------- o robô: sente o motor e vê a própria luz ---------- */

static int cor_mais_perto(const Percepcao *pc) {
  int melhor = 0, dmin = 1 << 30;
  for (int k = 0; k < 4; k++) {
    int dr = pc->luz_r - CORES[k].c.r, dg = pc->luz_g - CORES[k].c.g, db = pc->luz_b - CORES[k].c.b;
    int d = dr * dr + dg * dg + db * db;
    if (d < dmin) {
      dmin = d;
      melhor = k;
    }
  }
  return melhor;
}

static void robo(App *a, int s, Jogador *j, Pad *p, float dt) {
  const Percepcao *pc = simulador_percepcao(p->id);
  if (!pc)
    return;
  int idx = (int)(p - a->pads.pad);
  /* a borda de subida da vibração: um golpe chegou neste controle */
  bool subiu_forte = pc->forte > 0.3f && j->robo_forte <= 0.3f;
  bool subiu_fraco = pc->fraco > 0.3f && j->robo_fraco <= 0.3f;
  j->robo_forte = pc->forte;
  j->robo_fraco = pc->fraco;
  if ((subiu_forte || subiu_fraco) && j->robo_reage < 0) {
    j->robo_lado = subiu_forte && !subiu_fraco ? LADO_ESQ : LADO_DIR;
    j->robo_reage = 0.22f + 0.3f * robo_acaso();
  }
  if (j->robo_reage >= 0) {
    j->robo_reage -= dt;
    if (j->robo_reage < 0)
      robo_apertar(a, idx, j->robo_lado == LADO_ESQ ? SDL_GAMEPAD_BUTTON_LEFT_SHOULDER : SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER,
                   0.08f);
  }
  if (g_estado == EC_PERGUNTA && j->cor_pedida >= 0 && j->cor_resposta < 0) {
    if (j->robo_cor <= 0)
      j->robo_cor = 0.7f + 0.8f * robo_acaso();
    j->robo_cor -= dt;
    if (j->robo_cor <= 0.001f) {
      robo_apertar(a, idx, BOTAO_COR[cor_mais_perto(pc)], 0.08f);
      j->robo_cor = 10;
    }
  } else if (g_estado != EC_PERGUNTA) {
    j->robo_cor = 0;
  }
  (void)s;
}

/* ---------- o laço ---------- */

static void atualizar(App *a, float dt) {
  int fase = sb_atualizar(a, &g_b, dt);
  g_n_faixas = sb_faixas(a, &g_b, FAIXAS_QUADRANTES, AREA, g_faixa, g_slot_faixa);
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Jogador *j = &g_j[s];
    j->escudo = aproximar(j->escudo, 0, 2.5f, dt);
    j->interroga = aproximar(j->interroga, 0, 2, dt);
    j->dano = aproximar(j->dano, 0, 3, dt);
  }
  if (fase != FASE_JOGO || g_estado == EC_ACABOU)
    return;
  if (!g_planejado)
    planejar(a);

  /* o pisca vermelho: vermelho, escuro, vermelho, e volta à cor da vida */
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Jogador *j = &g_j[s];
    if (j->pisca <= 0 || g_estado == EC_PERGUNTA || g_estado == EC_RESPOSTA)
      continue;
    j->pisca -= dt;
    bool vermelho = j->pisca > 0.22f || (j->pisca > 0 && j->pisca < 0.12f);
    if (j->pisca <= 0) {
      luz_da_vida(a, s);
    } else if (vermelho != j->vermelho) {
      luz(a, s, vermelho ? (SDL_Color){255, 0, 0, 255} : (SDL_Color){40, 0, 0, 255});
    }
    j->vermelho = vermelho;
  }

  for (int i = 0; i < g_n_faixas; i++) {
    int s = g_slot_faixa[i];
    Pad *p = pads_do_slot(a, s);
    if (p && robo_ativo())
      robo(a, s, &g_j[s], p, dt);
  }

  g_t += dt;
  switch (g_estado) {
  case EC_PAUSA:
    if (g_t < g_espera)
      break;
    if (g_onda < ONDAS && g_i_plano >= g_fim_onda[g_onda]) {
      g_onda++;
      iniciar_pergunta(a);
      if (!alguem_pergunta())
        g_estado = EC_PAUSA;
    } else if (g_i_plano < g_n_plano) {
      iniciar_golpe(a);
    } else if (precisa_mais_cor(a)) {
      iniciar_pergunta(a);
    } else {
      terminar(a);
    }
    break;
  case EC_GOLPE:
    for (int k = 0; k < g_n_faixas; k++) {
      int s = g_slot_faixa[k];
      Pad *p = pads_do_slot(a, s);
      if (!p)
        continue;
      bool l1 = pad_apertou(p, SDL_GAMEPAD_BUTTON_LEFT_SHOULDER), r1 = pad_apertou(p, SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER);
      if (!l1 && !r1)
        continue;
      Jogador *j = &g_j[s];
      j->reagiu = true;
      j->escudo = 1;
      j->escudo_lado = l1 ? LADO_ESQ : LADO_DIR;
      if (s == g_atual.slot) {
        if (!g_respondido) {
          resolver(a, l1 ? LADO_ESQ : LADO_DIR);
          break;
        }
      } else {
        /* o escudo à toa: este controle sentiu um golpe que não era dele? */
        j->fantasmas++;
        j->interroga = 1;
        sb_pontos(a, &g_b, s, -20);
        evento_jogo(a, s, "fantasma", "golpe_de", pads_rotulo_slot(g_atual.slot));
      }
    }
    if (g_estado == EC_GOLPE && g_t >= JANELA)
      resolver(a, -1);
    break;
  case EC_REVELA:
    if (g_t >= REVELA) {
      g_estado = EC_PAUSA;
      g_t = 0;
      g_espera = 0.55f + 0.45f * sorteio_real(&g_b.sorteio);
    }
    break;
  case EC_PERGUNTA: {
    bool todos = true;
    for (int k = 0; k < g_n_faixas; k++) {
      int s = g_slot_faixa[k];
      Jogador *j = &g_j[s];
      Pad *p = pads_do_slot(a, s);
      if (j->cor_pedida < 0)
        continue;
      if (p && j->cor_resposta < 0 && g_t > 0.6f)
        for (int c = 0; c < 4; c++)
          if (pad_apertou(p, BOTAO_COR[c])) {
            j->cor_resposta = c;
            som_evento_pan(&a->som, SOM_TICK, 0.5f, sb_pan(g_faixa[k]));
          }
      if (j->cor_resposta < 0 && p)
        todos = false;
    }
    if (todos || g_t >= PERGUNTA_MAX)
      fechar_pergunta(a);
    break;
  }
  case EC_RESPOSTA:
    if (g_t >= 1.6f) {
      for (int s = 0; s < MAX_JOGADORES; s++)
        if (g_j[s].cor_pedida >= 0) {
          g_j[s].cor_pedida = -1;
          luz_da_vida(a, s);
        }
      g_estado = EC_PAUSA;
      g_t = 0;
      g_espera = 1.0f;
    }
    break;
  case EC_ACABOU:
    break;
  }
}

/* ---------- desenho ---------- */

static void inimigo(SDL_Renderer *r, float x, float y, float esc, float t, float semente, bool ameaca) {
  SDL_Color sombra = {22, 16, 14, 255};
  SDL_FPoint corpo[3] = {{x - 22 * esc, y + 30 * esc}, {x + 22 * esc, y + 30 * esc}, {x, y - 18 * esc}};
  ds_poligono(r, corpo, 3, sombra);
  ds_circulo(r, x, y - 22 * esc, 13 * esc, sombra);
  float pisca = fmodf(t * 0.7f + semente, 3.0f) < 0.12f ? 0.1f : 1.0f;
  SDL_Color olho = cor_alfa((SDL_Color){255, 60, 30, 255}, (ameaca ? 1.0f : 0.55f) * pisca);
  ds_brilho(r, x, y - 23 * esc, 22 * esc, olho, 0.35f * pisca);
  ds_circulo(r, x - 5 * esc, y - 23 * esc, 2.4f * esc, olho);
  ds_circulo(r, x + 5 * esc, y - 23 * esc, 2.4f * esc, olho);
}

static void desenhar_faixa(App *a, int s, Jogador *j, Pad *p, SDL_FRect f) {
  SDL_Renderer *r = a->r;
  float cx = f.x + f.w / 2, cy = f.y + f.h / 2 + 10;
  float R = fminf(f.w * 0.28f, f.h * 0.35f);
  bool alvo = g_estado == EC_GOLPE && g_atual.slot == s;
  bool revela = g_estado == EC_REVELA && g_atual.slot == s;
  bool perguntando = (g_estado == EC_PERGUNTA || g_estado == EC_RESPOSTA) && j->cor_pedida >= 0;

  /* a arena no escuro */
  ds_circulo_grad(r, cx, cy, R * 1.25f, (SDL_Color){34, 27, 23, 255}, (SDL_Color){14, 10, 9, 255});
  ds_anel(r, cx, cy, R * 1.25f, 4, cor_alfa(COR_BRONZE_ESCURO, 0.7f));
  for (int k = 0; k < 7; k++) { /* rachaduras no chão */
    float an = k * 0.9f + s;
    ds_linha(r, cx + cosf(an) * R * 0.3f, cy + sinf(an) * R * 0.25f, cx + cosf(an + 0.3f) * R * 0.8f,
             cy + sinf(an + 0.3f) * R * 0.6f, 1.5f, cor_alfa(COR_FUNDO_0, 0.8f));
  }
  if (alvo) { /* o aviso não tem lado: a arena inteira pulsa */
    float pulso = 0.5f + 0.5f * sinf(a->t * 18);
    ds_anel(r, cx, cy, R * 1.22f, 10, cor_alfa(COR_FALHA, 0.35f + 0.35f * pulso));
  }
  /* os inimigos em volta, três de cada lado */
  static const float ANG[6] = {2.55f, 3.14159f, 3.73f, -0.59f, 0.0f, 0.59f};
  for (int k = 0; k < 6; k++)
    inimigo(r, cx + cosf(ANG[k]) * R * 1.12f, cy + sinf(ANG[k]) * R * 0.95f, 0.9f, a->t, k * 1.7f + s, alvo);

  /* o golpe, revelado depois da resposta */
  if (revela) {
    float k = limitar(g_t / (REVELA * 0.6f), 0, 1);
    float lado = g_atual.lado == LADO_ESQ ? -1 : 1;
    float x0 = cx + lado * R * 1.12f, y0 = cy;
    bool bloqueou = g_resposta == (int)g_atual.lado;
    float xf = bloqueou ? cx + lado * R * 0.42f : cx;
    float bx = x0 + (xf - x0) * k;
    ds_linha(r, x0 + (bx - x0) * 0.3f, y0, bx, y0, 6, cor_alfa(COR_BRASA_VIVA, 0.8f));
    ds_brilho(r, bx, y0, 50, COR_BRASA_VIVA, 0.8f);
    if (k >= 1)
      ds_brilho(r, xf, y0, 90, bloqueou ? COR_OURO : COR_FALHA, 0.7f * (1 - (g_t - REVELA * 0.6f) / (REVELA * 0.4f)));
  }

  /* o autômato: o núcleo acende com a vida (e fica neutro na pergunta da cor,
   * para a tela não soprar a resposta) */
  Automato bon;
  automato_iniciar(&bon, cx, cy + 50);
  bon.vida = perguntando ? 0.5f : j->vida;
  bon.dano = j->dano;
  bon.conectado = p != NULL;
  bon.olhar = PI_F / 2;
  automato_desenhar(r, &bon, perguntando ? COR_NEUTRO : COR_JOGADOR[s], 1.1f, a->t, -1);
  if (j->escudo > 0.02f) {
    float lado = j->escudo_lado == LADO_ESQ ? -1 : 1;
    float a0 = lado < 0 ? PI_F * 0.62f : -PI_F * 0.38f;
    ds_arco(r, cx + lado * 8, cy - 10, 64, 10, a0, a0 + PI_F * 0.76f, cor_alfa(COR_BRONZE_CLARO, j->escudo));
    ds_arco(r, cx + lado * 8, cy - 10, 70, 3, a0, a0 + PI_F * 0.76f, cor_alfa(COR_OURO, j->escudo));
  }
  if (alvo)
    texto_al(r, F_ENORME_N, cx, cy - 170, cor_mistura(COR_FALHA, COR_OURO, 0.5f + 0.5f * sinf(a->t * 16)), ALINHA_CENTRO, "!");
  if (j->interroga > 0.02f)
    texto_al(r, F_GRANDE_N, cx + 60, cy - 150, cor_alfa(COR_AVISO, j->interroga), ALINHA_CENTRO, "?");

  /* a vida, de pé na lateral direita, com a luz do controle em cima */
  float vx = f.x + f.w - 64, vy0 = f.y + 120, vh = f.h - 190;
  icone(r, IC_LUZ, vx + 9, vy0 - 26, 32, perguntando ? COR_NEUTRO : cor_da_vida(s, j->vida), 0);
  ds_ret_arred(r, vx, vy0, 18, vh, 9, cor_alfa(COR_FUNDO_0, 0.85f));
  float cheio = vh * j->vida;
  ds_ret_arred_grad(r, vx + 3, vy0 + vh - cheio, 12, cheio, 6, cor_mistura(COR_FALHA, COR_OK, j->vida),
                    cor_escurecer(cor_mistura(COR_FALHA, COR_OK, j->vida), 0.3f));
  ds_contorno_arred(r, vx, vy0, 18, vh, 9, 1.5f, COR_BRONZE_ESCURO);
  texto_al(r, F_MINI, vx + 9, vy0 + vh + 8, COR_TEXTO_3, ALINHA_CENTRO, "vida");
  texto(r, F_PEQUENA, f.x + 80, f.y + 30, COR_TEXTO_2, fmt("bloqueios: %d", j->bloqueios));
  texto(r, F_MINI, f.x + 24, f.y + f.h - 32, COR_TEXTO_3, "a vida também está na luz do controle");

  /* a pergunta da cor */
  if (perguntando) {
    float pw = fminf(f.w - 60, 660), ph = 176, px = cx - pw / 2, py = f.y + 64;
    ds_ret_arred(r, px, py, pw, ph, 14, cor_alfa(COR_CARVAO, 0.94f));
    ds_contorno_arred(r, px, py, pw, ph, 14, 2, COR_OURO);
    texto_al(r, F_TEXTO_N, cx, py + 12, COR_TEXTO, ALINHA_CENTRO, "Que cor está a sua luz? Olhe o controle.");
    float cw = (pw - 40) / 4;
    for (int c = 0; c < 4; c++) {
      float ox = px + 20 + c * cw, oy = py + 60;
      bool escolhida = j->cor_resposta == c;
      bool certa = g_estado == EC_RESPOSTA && c == j->cor_pedida;
      if (escolhida)
        ds_ret_arred(r, ox, oy - 4, cw - 8, 48, 10, cor_alfa(COR_BRASA, 0.25f));
      if (certa)
        ds_contorno_arred(r, ox, oy - 4, cw - 8, 48, 10, 3, COR_OK);
      icone_natural(r, ICONE_COR[c], ox + 20, oy + 20, 30, 0);
      ds_circulo(r, ox + 50, oy + 20, 11, CORES[c].c);
      texto(r, F_PEQUENA_N, ox + 66, oy + 8, COR_TEXTO, CORES[c].nome);
    }
    if (g_estado == EC_RESPOSTA) {
      bool acertou = j->cor_resposta == j->cor_pedida;
      texto_al(r, F_PEQUENA_N, cx, py + ph - 50, acertou ? COR_OK : COR_FALHA, ALINHA_CENTRO,
               j->cor_resposta < 0 ? fmt("sem resposta — era %s", CORES[j->cor_pedida].nome)
               : acertou            ? "isso: a luz obedeceu"
                                    : fmt("não — o jogo mandou %s", CORES[j->cor_pedida].nome));
    }
  }
}

static void desenhar(App *a) {
  SDL_Renderer *r = a->r;
  ds_fundo(r, a->t, 0.25f);
  sb_desenhar_topo(a, &g_b);
  if (g_b.fase == FASE_JOGO && g_planejado) {
    int feitos = g_i_plano < g_n_plano ? g_i_plano : g_n_plano;
    texto_al(r, F_PEQUENA_N, TELA_L / 2.0f, 50, COR_TEXTO_2, ALINHA_CENTRO,
             fmt("onda %d de %d · golpe %d de %d", g_onda < ONDAS ? g_onda + 1 : ONDAS, ONDAS, feitos, g_n_plano));
    wg_texto_rico(r, F_PEQUENA, TELA_L / 2.0f, 84, COR_TEXTO_3, ALINHA_CENTRO,
                  "sinta de que lado vem o golpe: {L1} esquerda, {R1} direita — só no seu controle");
  }
  for (int i = 0; i < g_n_faixas; i++) {
    int s = g_slot_faixa[i];
    SDL_FRect f = g_faixa[i];
    Pad *p = pads_do_slot(a, s);
    sb_moldura(a, f, s, g_b.fase == FASE_JOGO && g_estado == EC_GOLPE && g_atual.slot == s ? 0.9f : 0.2f);
    if (g_b.fase != FASE_AVISO)
      desenhar_faixa(a, s, &g_j[s], p, f);
    sb_escudo(a, f, s);
    texto_al(r, F_GRANDE_N, f.x + f.w - 28, f.y + 14, COR_TEXTO, ALINHA_DIR, fmt("%d", g_b.pontos[s]));
    if (!p)
      sb_sem_controle(a, f, s);
  }
  particulas_desenhar(r, &a->brasas);
  if (g_b.fase == FASE_AVISO) {
    sb_desenhar_aviso(a, &g_b,
                      "No escuro, os golpes vêm um de cada vez, para um controle só.\n"
                      "A tela não diz o lado: sinta no controle. Esquerda treme o motor da esquerda.\n"
                      "Levante o escudo do lado certo: {L1} esquerda, {R1} direita. Só no seu golpe!\n"
                      "A luz do controle pisca vermelho no golpe e apaga com a vida. No fim da onda, diga a cor dela.");
    if (a->cfg.intensidade < 0.5f)
      texto_al(r, F_PEQUENA_N, TELA_L / 2.0f, 150, COR_AVISO, ALINHA_CENTRO,
               fmt("a vibração está em %d%% (pausa): para esta sala, deixe perto de 100%%", (int)(a->cfg.intensidade * 100 + 0.5f)));
  } else if (g_b.fase == FASE_FIM) {
    sb_desenhar_fim(a, &g_b);
  } else {
    Dica d[] = {{IC_L1, "escudo à esquerda"}, {IC_R1, "escudo à direita"}, {IC_OPTIONS, "pausa"}};
    wg_rodape(r, d, 3);
  }
  pausa_desenhar(a);
}

const Cena CENA_CERCO = {"cerco", entrar, sair, NULL, atualizar, desenhar};
