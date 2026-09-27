/* A Centelha — runas que acendem ao apertar (ADR-002).
 *
 * O padrão é o do QTE e do jogo de ritmo: um símbolo acende, você aperta antes
 * que ele apague. Cada jogador tem a sua pedra de runas; a fila dele passa por
 * TODOS os botões do DualSense que um jogo usa (os quatro da face, L1, R1, o
 * clique dos dois analógicos, as quatro setas e o Create), por dois círculos
 * — um em cada analógico, até a borda — e pelo fole: cada gatilho segurado no
 * meio do curso e depois apertado até o fundo.
 *
 * O Options fica de fora (é a pausa), o PS também (o sistema costuma tomá-lo),
 * o botão do microfone é da Cripta e o clique do touchpad é do Molde.
 *
 * O que a sala mede enquanto se joga (medidas.h): se cada botão chegou na hora
 * da runa dele, e se chegou OUTRO no lugar (o mapa trocado de um intermediário
 * aparece assim); as oito direções de cada analógico e a deriva em repouso; o
 * curso de cada gatilho, do zero ao fundo, e quantos níveis passaram no meio
 * (um gatilho que chega digital aparece assim). */
#include "sala_base.h"

#include "../cenas/pausa.h"
#include "../nucleo/simulador.h"
#include "../ui/desenho.h"
#include "../ui/icones.h"
#include "../ui/tema.h"
#include "../ui/texto.h"
#include "../ui/widgets.h"

#include <math.h>

#define PI_F 3.14159265f
#define DURACAO 100.0f
#define MAX_FILA 48
#define JANELA_INICIAL 2.8f
#define JANELA_MINIMA 1.5f
#define JANELA_ANALOGICO 7.0f
#define JANELA_GATILHO 8.0f
#define MAX_TENTATIVAS 3

typedef enum TipoRuna { RUNA_BOTAO = 0, RUNA_ANALOGICO, RUNA_GATILHO } TipoRuna;

typedef struct Runa {
  TipoRuna tipo;
  int alvo; /* o botão do SDL; 0/1 analógico esquerdo/direito; 0/1 gatilho L2/R2 */
  int tentativas;
} Runa;

typedef struct Jogador {
  Runa fila[MAX_FILA];
  int n, atual;
  float t;      /* segundos desde que a runa atual acendeu */
  float janela; /* a janela das runas de botão, que encolhe com os acertos */
  int acertos, perdidas, combo, melhor_combo;
  float pop, tremor; /* animações do acerto e do erro */
  uint8_t setores;   /* runa de analógico: as direções que já acenderam */
  int estagio;       /* runa de gatilho: 0 o meio, 1 o fundo */
  float segurou;
  MedBotoes mb;
  MedAnalogico ae, ad;
  MedGatilho gl, gr;
  uint32_t marcados; /* botões cujo primeiro aperto já foi para a linha do tempo */
  /* o robô */
  float robo_reacao;
  int robo_passo;
  float robo_ang, robo_gatilho;
} Jogador;

static const SDL_GamepadButton BOTOES[] = {
    SDL_GAMEPAD_BUTTON_SOUTH,     SDL_GAMEPAD_BUTTON_EAST,          SDL_GAMEPAD_BUTTON_WEST,
    SDL_GAMEPAD_BUTTON_NORTH,     SDL_GAMEPAD_BUTTON_LEFT_SHOULDER, SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER,
    SDL_GAMEPAD_BUTTON_LEFT_STICK, SDL_GAMEPAD_BUTTON_RIGHT_STICK,  SDL_GAMEPAD_BUTTON_DPAD_UP,
    SDL_GAMEPAD_BUTTON_DPAD_DOWN, SDL_GAMEPAD_BUTTON_DPAD_LEFT,     SDL_GAMEPAD_BUTTON_DPAD_RIGHT,
    SDL_GAMEPAD_BUTTON_BACK,
};
#define N_BOTOES ((int)(sizeof(BOTOES) / sizeof(BOTOES[0])))

static const char *const NOMES[MED_MAX_BOTOES] = {
    [SDL_GAMEPAD_BUTTON_SOUTH] = "cruz",
    [SDL_GAMEPAD_BUTTON_EAST] = "círculo",
    [SDL_GAMEPAD_BUTTON_WEST] = "quadrado",
    [SDL_GAMEPAD_BUTTON_NORTH] = "triângulo",
    [SDL_GAMEPAD_BUTTON_BACK] = "Create",
    [SDL_GAMEPAD_BUTTON_GUIDE] = "PS",
    [SDL_GAMEPAD_BUTTON_START] = "Options",
    [SDL_GAMEPAD_BUTTON_LEFT_STICK] = "L3",
    [SDL_GAMEPAD_BUTTON_RIGHT_STICK] = "R3",
    [SDL_GAMEPAD_BUTTON_LEFT_SHOULDER] = "L1",
    [SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER] = "R1",
    [SDL_GAMEPAD_BUTTON_DPAD_UP] = "seta ↑",
    [SDL_GAMEPAD_BUTTON_DPAD_DOWN] = "seta ↓",
    [SDL_GAMEPAD_BUTTON_DPAD_LEFT] = "seta ←",
    [SDL_GAMEPAD_BUTTON_DPAD_RIGHT] = "seta →",
    [SDL_GAMEPAD_BUTTON_MISC1] = "microfone",
    [SDL_GAMEPAD_BUTTON_TOUCHPAD] = "clique do touchpad",
};

static const Feature FEATS[] = {F_BOTOES, F_ANALOGICOS, F_GATILHOS_ANALOGICOS};

static SalaBase g_b;
static Jogador g_j[MAX_JOGADORES];

static Icone icone_do_botao(int b) {
  switch (b) {
  case SDL_GAMEPAD_BUTTON_SOUTH:
    return IC_CRUZ;
  case SDL_GAMEPAD_BUTTON_EAST:
    return IC_CIRCULO;
  case SDL_GAMEPAD_BUTTON_WEST:
    return IC_QUADRADO;
  case SDL_GAMEPAD_BUTTON_NORTH:
    return IC_TRIANGULO;
  case SDL_GAMEPAD_BUTTON_LEFT_SHOULDER:
    return IC_L1;
  case SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER:
    return IC_R1;
  case SDL_GAMEPAD_BUTTON_LEFT_STICK:
    return IC_L3;
  case SDL_GAMEPAD_BUTTON_RIGHT_STICK:
    return IC_R3;
  case SDL_GAMEPAD_BUTTON_DPAD_UP:
    return IC_DPAD_CIMA;
  case SDL_GAMEPAD_BUTTON_DPAD_DOWN:
    return IC_DPAD_BAIXO;
  case SDL_GAMEPAD_BUTTON_DPAD_LEFT:
    return IC_DPAD_ESQ;
  case SDL_GAMEPAD_BUTTON_DPAD_RIGHT:
    return IC_DPAD_DIR;
  default:
    return IC_CREATE;
  }
}

static uint32_t mascara_pedida(void) {
  uint32_t m = 0;
  for (int i = 0; i < N_BOTOES; i++)
    m |= 1u << BOTOES[i];
  return m;
}

/* A fila: os botões embaralhados, com os dois círculos e o fole no meio (não
 * no fim, para a sala não terminar sempre do mesmo jeito). */
static void montar_fila(Jogador *j, Sorteio *s) {
  int ordem[N_BOTOES];
  for (int i = 0; i < N_BOTOES; i++)
    ordem[i] = BOTOES[i];
  sorteio_embaralhar(s, ordem, N_BOTOES);
  Runa extras[4] = {{RUNA_ANALOGICO, 0, 0}, {RUNA_GATILHO, 0, 0}, {RUNA_ANALOGICO, 1, 0}, {RUNA_GATILHO, 1, 0}};
  if (sorteio_entre(s, 0, 1)) { /* às vezes o direito vem antes */
    extras[0].alvo = 1;
    extras[2].alvo = 0;
  }
  int posicoes[4] = {3, 6, 9, 12};
  j->n = 0;
  int e = 0;
  for (int i = 0; i < N_BOTOES; i++) {
    while (e < 4 && posicoes[e] == j->n)
      j->fila[j->n++] = extras[e++];
    j->fila[j->n++] = (Runa){RUNA_BOTAO, ordem[i], 0};
  }
  while (e < 4)
    j->fila[j->n++] = extras[e++];
}

static void entrar(App *a) {
  sb_entrar(a, &g_b, SALA_CENTELHA, FEATS, 3, DURACAO);
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Jogador *j = &g_j[s];
    SDL_memset(j, 0, sizeof(*j));
    j->janela = JANELA_INICIAL;
    montar_fila(j, &g_b.sorteio);
    med_botoes_iniciar(&j->mb, mascara_pedida(), NOMES);
    med_analogico_iniciar(&j->ae);
    med_analogico_iniciar(&j->ad);
    med_gatilho_iniciar(&j->gl);
    med_gatilho_iniciar(&j->gr);
    j->robo_reacao = -1;
  }
}

static void sair(App *a) { pads_silencio_todos(a); }

static Runa *runa_atual(Jogador *j) { return j->atual < j->n ? &j->fila[j->atual] : NULL; }

static void proxima(Jogador *j) {
  j->atual++;
  j->t = 0;
  j->setores = 0;
  j->estagio = 0;
  j->segurou = 0;
  j->robo_passo = 0;
  j->robo_reacao = -1;
}

static void acertou(App *a, int s, Jogador *j, SDL_FRect f, int base) {
  Runa *r = runa_atual(j);
  float rapidez = r && r->tipo == RUNA_BOTAO ? limitar(1 - j->t / j->janela, 0, 1) : 0.5f;
  j->combo++;
  if (j->combo > j->melhor_combo)
    j->melhor_combo = j->combo;
  j->acertos++;
  sb_pontos(a, &g_b, s, base + (int)(100 * rapidez) + 10 * (j->combo - 1));
  j->pop = 1;
  float cx = f.x + f.w / 2, cy = f.y + 330;
  particulas_faiscas(&a->brasas, cx, cy, 26, COR_OURO, 0.9f);
  particulas_anel(&a->brasas, cx, cy, COR_JOGADOR[s], 170);
  som_evento_pan(&a->som, r && r->tipo == RUNA_BOTAO ? SOM_BIGORNA_AGUDA : SOM_BIGORNA, 0.55f, sb_pan(f));
  Pad *p = pads_do_slot(a, s);
  if (p && p->cap_rumble)
    pad_rumble(a, p, 0, 0.2f, 50); /* o tique na mão de quem acertou */
  if (r && r->tipo == RUNA_BOTAO && j->janela > JANELA_MINIMA)
    j->janela -= 0.08f;
  proxima(j);
  if (j->atual >= j->n) {
    g_b.acabou[s] = true;
    som_evento_pan(&a->som, SOM_SUCESSO, 0.6f, sb_pan(f));
    particulas_brasas(&a->brasas, cx, cy, 40, COR_OURO);
  }
}

/* A runa venceu: volta para o fim da fila (até MAX_TENTATIVAS vezes). */
static void perdeu(App *a, int s, Jogador *j, SDL_FRect f) {
  Runa r = *runa_atual(j);
  j->combo = 0;
  j->perdidas++;
  j->tremor = 1;
  som_evento_pan(&a->som, SOM_FALHA, 0.3f, sb_pan(f));
  r.tentativas++;
  if (r.tentativas < MAX_TENTATIVAS && j->n < MAX_FILA)
    j->fila[j->n++] = r;
  proxima(j);
  if (j->atual >= j->n)
    g_b.acabou[s] = true;
}

static void medir(App *a, int s, Jogador *j, Pad *p) {
  med_analogico_amostra(&j->ae, p->ax[SDL_GAMEPAD_AXIS_LEFTX], p->ax[SDL_GAMEPAD_AXIS_LEFTY]);
  med_analogico_amostra(&j->ad, p->ax[SDL_GAMEPAD_AXIS_RIGHTX], p->ax[SDL_GAMEPAD_AXIS_RIGHTY]);
  med_gatilho_amostra(&j->gl, p->ax[SDL_GAMEPAD_AXIS_LEFT_TRIGGER]);
  med_gatilho_amostra(&j->gr, p->ax[SDL_GAMEPAD_AXIS_RIGHT_TRIGGER]);
  (void)a;
  (void)s;
}

/* A runa acesa é o que a sala está pedindo agora: só o que foi pedido pode
 * falhar (o que a sala não chegou a pedir fica "não medido"). */
static void pedindo(Jogador *j, const Runa *r) {
  if (!r)
    return;
  if (r->tipo == RUNA_BOTAO)
    med_botoes_mostrou(&j->mb, r->alvo);
  else if (r->tipo == RUNA_ANALOGICO)
    (r->alvo ? &j->ad : &j->ae)->pedido = true;
  else
    (r->alvo ? &j->gr : &j->gl)->pedido = true;
}

static void jogar(App *a, int s, Jogador *j, Pad *p, SDL_FRect f, float dt) {
  Runa *r = runa_atual(j);
  int pedido = r && r->tipo == RUNA_BOTAO ? r->alvo : -1;
  pedindo(j, r);

  /* todo aperto conta para a medida, com a runa acesa agora */
  for (int b = 0; b < SDL_GAMEPAD_BUTTON_COUNT && b < MED_MAX_BOTOES; b++) {
    if (!pad_apertou(p, (SDL_GamepadButton)b) || b == SDL_GAMEPAD_BUTTON_START)
      continue;
    med_botoes_apertou(&j->mb, b, pedido);
    if ((mascara_pedida() & (1u << b)) && !(j->marcados & (1u << b))) {
      j->marcados |= 1u << b;
      sb_marco(a, s, "botao", NOMES[b]);
    }
    if (pedido >= 0 && b == pedido) {
      acertou(a, s, j, f, 100);
      return;
    }
    if (pedido >= 0 && (mascara_pedida() & (1u << b))) {
      j->combo = 0;
      j->tremor = 0.6f;
    }
  }
  if (!r)
    return;
  j->t += dt;

  switch (r->tipo) {
  case RUNA_BOTAO:
    if (j->t > j->janela)
      perdeu(a, s, j, f);
    break;
  case RUNA_ANALOGICO: {
    float x = p->ax[r->alvo ? SDL_GAMEPAD_AXIS_RIGHTX : SDL_GAMEPAD_AXIS_LEFTX];
    float y = p->ax[r->alvo ? SDL_GAMEPAD_AXIS_RIGHTY : SDL_GAMEPAD_AXIS_LEFTY];
    if (sqrtf(x * x + y * y) >= MED_BORDA) {
      uint8_t antes = j->setores;
      j->setores |= (uint8_t)(1u << med_analogico_setor(x, y));
      if (j->setores != antes)
        som_evento_pan(&a->som, SOM_TICK, 0.35f, sb_pan(f));
    }
    if (j->setores == 0xFF) {
      sb_marco(a, s, "analogico", r->alvo ? "direito: as oito direções" : "esquerdo: as oito direções");
      acertou(a, s, j, f, 250);
    } else if (j->t > JANELA_ANALOGICO) {
      perdeu(a, s, j, f);
    }
    break;
  }
  case RUNA_GATILHO: {
    float v = p->ax[r->alvo ? SDL_GAMEPAD_AXIS_RIGHT_TRIGGER : SDL_GAMEPAD_AXIS_LEFT_TRIGGER];
    bool na_faixa = j->estagio == 0 ? (v >= 0.35f && v <= 0.62f) : v >= 0.92f;
    j->segurou = na_faixa ? j->segurou + dt : fmaxf(0, j->segurou - dt * 2);
    float precisa = j->estagio == 0 ? 0.6f : 0.35f;
    if (j->segurou >= precisa) {
      if (j->estagio == 0) {
        j->estagio = 1;
        j->segurou = 0;
        (r->alvo ? &j->gr : &j->gl)->faixas++;
        som_evento_pan(&a->som, SOM_SOPRO, 0.5f, sb_pan(f));
      } else {
        sb_marco(a, s, "gatilho", r->alvo ? "R2: meio e fundo" : "L2: meio e fundo");
        acertou(a, s, j, f, 250);
      }
    } else if (j->t > JANELA_GATILHO) {
      perdeu(a, s, j, f);
    }
    break;
  }
  }
}

/* ---------- o robô: vê a runa na tela e reage como gente (às vezes erra) ---------- */

static void robo(App *a, int s, Jogador *j, Pad *p, float dt) {
  Runa *r = runa_atual(j);
  int idx = (int)(p - a->pads.pad);
  if (!r) {
    j->robo_gatilho = aproximar(j->robo_gatilho, 0, 3, dt);
    return;
  }
  if (j->robo_reacao < 0)
    j->robo_reacao = 0.35f + 0.55f * robo_acaso();
  switch (r->tipo) {
  case RUNA_BOTAO:
    if (j->robo_passo == 0 && j->t >= j->robo_reacao) {
      if (robo_acaso() < 0.06f) {
        /* o dedo escorrega para o vizinho, e corrige */
        int errado = BOTOES[(s + j->atual + 1) % N_BOTOES];
        if (errado == r->alvo)
          errado = BOTOES[(s + j->atual + 2) % N_BOTOES];
        robo_apertar(a, idx, (SDL_GamepadButton)errado, 0.08f);
        j->robo_reacao = j->t + 0.35f;
        j->robo_passo = 1;
      } else {
        robo_apertar(a, idx, (SDL_GamepadButton)r->alvo, 0.09f);
        j->robo_passo = 2;
      }
    } else if (j->robo_passo == 1 && j->t >= j->robo_reacao) {
      robo_apertar(a, idx, (SDL_GamepadButton)r->alvo, 0.09f);
      j->robo_passo = 2;
    }
    break;
  case RUNA_ANALOGICO:
    if (j->t >= j->robo_reacao) {
      j->robo_ang += dt * 2 * PI_F / 1.4f;
      SDL_GamepadAxis ex = r->alvo ? SDL_GAMEPAD_AXIS_RIGHTX : SDL_GAMEPAD_AXIS_LEFTX;
      SDL_GamepadAxis ey = r->alvo ? SDL_GAMEPAD_AXIS_RIGHTY : SDL_GAMEPAD_AXIS_LEFTY;
      robo_eixo(a, idx, ex, cosf(j->robo_ang), 0.06f);
      robo_eixo(a, idx, ey, sinf(j->robo_ang), 0.06f);
    }
    break;
  case RUNA_GATILHO: {
    float alvo = j->t < j->robo_reacao ? 0 : j->estagio == 0 ? 0.48f : 1.0f;
    /* se o fole não enche (o jogo não vê o meio do curso), aperta mais, como
     * gente faz quando o botão "não pegou" */
    float lido = p->ax[r->alvo ? SDL_GAMEPAD_AXIS_RIGHT_TRIGGER : SDL_GAMEPAD_AXIS_LEFT_TRIGGER];
    if (j->estagio == 0 && j->t > j->robo_reacao + 1.2f && lido < 0.2f && fmodf(j->t, 1.6f) < 0.5f)
      alvo = 1.0f;
    j->robo_gatilho = aproximar(j->robo_gatilho, alvo, 4, dt);
    robo_eixo(a, idx, r->alvo ? SDL_GAMEPAD_AXIS_RIGHT_TRIGGER : SDL_GAMEPAD_AXIS_LEFT_TRIGGER, j->robo_gatilho, 0.06f);
    break;
  }
  }
}

static SDL_FRect g_faixa[MAX_JOGADORES];
static int g_slot_faixa[MAX_JOGADORES], g_n_faixas;

static const SDL_FRect AREA = {40, 140, TELA_L - 80, TELA_A - 140 - 96};

static void atualizar(App *a, float dt) {
  int fase = sb_atualizar(a, &g_b, dt);
  g_n_faixas = sb_faixas(a, &g_b, FAIXAS_COLUNAS, AREA, g_faixa, g_slot_faixa);
  for (int s = 0; s < MAX_JOGADORES; s++) {
    g_j[s].pop = aproximar(g_j[s].pop, 0, 5, dt);
    g_j[s].tremor = aproximar(g_j[s].tremor, 0, 4, dt);
  }
  if (fase == FASE_AVISO) {
    /* a sala pede para soltar os analógicos: é quando se mede a deriva */
    for (int s = 0; s < MAX_JOGADORES; s++) {
      Pad *p = pads_do_slot(a, s);
      if (p && g_b.t_fase > 0.6f) {
        med_analogico_repouso(&g_j[s].ae, p->ax[SDL_GAMEPAD_AXIS_LEFTX], p->ax[SDL_GAMEPAD_AXIS_LEFTY]);
        med_analogico_repouso(&g_j[s].ad, p->ax[SDL_GAMEPAD_AXIS_RIGHTX], p->ax[SDL_GAMEPAD_AXIS_RIGHTY]);
      }
    }
    return;
  }
  if (fase != FASE_JOGO)
    return;
  for (int i = 0; i < g_n_faixas; i++) {
    int s = g_slot_faixa[i];
    Pad *p = pads_do_slot(a, s);
    if (!p)
      continue;
    Jogador *j = &g_j[s];
    medir(a, s, j, p);
    if (!g_b.acabou[s]) {
      if (robo_ativo())
        robo(a, s, j, p, dt);
      jogar(a, s, j, p, g_faixa[i], dt);
    } else if (robo_ativo()) {
      robo(a, s, j, p, dt);
    }
  }
  if (sb_todos_acabaram(a, &g_b)) {
    for (int s = 0; s < MAX_JOGADORES; s++) {
      if (!g_b.jogando[s])
        continue;
      Jogador *j = &g_j[s];
      Veredito v = med_botoes_veredito(&j->mb, g_b.mexeu[s]);
      sb_veredito(&g_b, s, F_BOTOES, &v);
      v = med_analogicos_veredito(&j->ae, &j->ad, g_b.mexeu[s]);
      sb_veredito(&g_b, s, F_ANALOGICOS, &v);
      v = med_gatilhos_veredito(&j->gl, &j->gr, g_b.mexeu[s]);
      sb_veredito(&g_b, s, F_GATILHOS_ANALOGICOS, &v);
    }
    sb_terminar(a, &g_b, NIVEL_REAGIU);
  }
}

/* ---------- desenho ---------- */

static void pedra(SDL_Renderer *r, float cx, float cy, float R, SDL_Color cor, float brilho) {
  ds_brilho(r, cx, cy, R * 2.3f, cor, 0.18f + 0.45f * brilho);
  ds_circulo_grad(r, cx, cy, R, (SDL_Color){62, 51, 44, 255}, (SDL_Color){27, 21, 18, 255});
  ds_anel(r, cx, cy, R, 5, cor_mistura(COR_BRONZE_ESCURO, cor, 0.3f * brilho));
  for (int i = 0; i < 16; i++) {
    float an = i * 2 * PI_F / 16;
    float r0 = R * (i % 2 ? 0.86f : 0.8f), r1 = R * 0.93f;
    ds_linha(r, cx + cosf(an) * r0, cy + sinf(an) * r0, cx + cosf(an) * r1, cy + sinf(an) * r1, 2,
             cor_alfa(COR_BRONZE, 0.5f));
  }
}

static void desenhar_runa(App *a, int s, Jogador *j, Pad *p, SDL_FRect f) {
  SDL_Renderer *r = a->r;
  float cx = f.x + f.w / 2, cy = f.y + 330;
  float R = fminf(f.w * 0.34f, 140);
  float treme = j->tremor * 8 * sinf(a->t * 60);
  cx += treme;
  Runa *ru = runa_atual(j);
  if (!ru) {
    /* acesa: a runa inteira em ouro */
    pedra(r, cx, cy, R, COR_OURO, 0.9f + 0.1f * sinf(a->t * 3));
    icone(r, IC_CHAMA, cx, cy - 6, R * 1.0f, COR_OURO, 0);
    texto_al(r, F_MEDIA_N, cx, cy + R + 30, COR_OURO, ALINHA_CENTRO, "ACESA");
    return;
  }
  float frac = 1;
  if (ru->tipo == RUNA_BOTAO)
    frac = 1 - j->t / j->janela;
  else if (ru->tipo == RUNA_ANALOGICO)
    frac = 1 - j->t / JANELA_ANALOGICO;
  else
    frac = 1 - j->t / JANELA_GATILHO;
  frac = limitar(frac, 0, 1);
  SDL_Color cor_t = frac > 0.5f ? COR_OURO : frac > 0.25f ? COR_BRASA : COR_FALHA;
  pedra(r, cx, cy, R, COR_JOGADOR[s], 0.4f + j->pop);
  ds_anel(r, cx, cy, R + 16, 8, cor_alfa(COR_FUNDO_0, 0.9f));
  ds_arco(r, cx, cy, R + 16, 8, -PI_F / 2, -PI_F / 2 + 2 * PI_F * frac, cor_t);

  const char *dica = "";
  switch (ru->tipo) {
  case RUNA_BOTAO: {
    float tam = R * (1.05f + 0.25f * j->pop);
    icone_natural(r, icone_do_botao(ru->alvo), cx, cy, tam, 0.3f + j->pop);
    if (ru->alvo == SDL_GAMEPAD_BUTTON_LEFT_STICK)
      dica = "afunde o analógico esquerdo";
    else if (ru->alvo == SDL_GAMEPAD_BUTTON_RIGHT_STICK)
      dica = "afunde o analógico direito";
    else if (ru->alvo == SDL_GAMEPAD_BUTTON_BACK)
      dica = "o Create, à esquerda do touchpad";
    else
      dica = "aperte!";
    break;
  }
  case RUNA_ANALOGICO: {
    float rr = R * 0.66f;
    ds_anel(r, cx, cy, rr, 3, cor_alfa(COR_BRONZE, 0.6f));
    for (int k = 0; k < 8; k++) {
      float an = k * PI_F / 4;
      bool aceso = j->setores & (1u << k);
      float px = cx + cosf(an) * rr, py = cy + sinf(an) * rr;
      if (aceso)
        ds_brilho(r, px, py, 44, COR_OURO, 0.6f);
      ds_circulo(r, px, py, aceso ? 11 : 7, aceso ? COR_OURO : COR_BRONZE_ESCURO);
    }
    float x = p ? p->ax[ru->alvo ? SDL_GAMEPAD_AXIS_RIGHTX : SDL_GAMEPAD_AXIS_LEFTX] : 0;
    float y = p ? p->ax[ru->alvo ? SDL_GAMEPAD_AXIS_RIGHTY : SDL_GAMEPAD_AXIS_LEFTY] : 0;
    icone_natural(r, ru->alvo ? IC_ANALOGICO_D : IC_ANALOGICO_E, cx, cy, R * 0.55f, 0);
    ds_circulo(r, cx + x * rr, cy + y * rr, 12, COR_JOGADOR[s]);
    ds_anel(r, cx + x * rr, cy + y * rr, 12, 2, COR_TEXTO);
    dica = ru->alvo ? "gire {LD} em volta, até a borda" : "gire {LE} em volta, até a borda";
    break;
  }
  case RUNA_GATILHO: {
    float v = p ? p->ax[ru->alvo ? SDL_GAMEPAD_AXIS_RIGHT_TRIGGER : SDL_GAMEPAD_AXIS_LEFT_TRIGGER] : 0;
    float gw = R * 0.42f, gh = R * 1.3f, gx = cx - gw / 2 + R * 0.18f, gy = cy - gh / 2;
    ds_ret_arred(r, gx, gy, gw, gh, 8, cor_alfa(COR_FUNDO_0, 0.9f));
    float f0 = j->estagio == 0 ? 0.35f : 0.92f, f1 = j->estagio == 0 ? 0.62f : 1.0f;
    ds_ret(r, gx, gy + gh * (1 - f1), gw, gh * (f1 - f0), cor_alfa(COR_OURO, 0.22f));
    ds_contorno_arred(r, gx, gy + gh * (1 - f1), gw, gh * (f1 - f0), 4, 2, COR_OURO);
    ds_ret_arred_grad(r, gx + 4, gy + gh * (1 - v), gw - 8, gh * v, 6, COR_BRASA_VIVA, COR_BRASA);
    ds_contorno_arred(r, gx, gy, gw, gh, 8, 2, COR_BRONZE);
    icone_natural(r, ru->alvo ? IC_R2 : IC_L2, cx - R * 0.42f, cy - R * 0.2f, R * 0.5f, 0);
    float precisa = j->estagio == 0 ? 0.6f : 0.35f;
    ds_arco(r, cx - R * 0.42f, cy + R * 0.32f, 20, 5, -PI_F / 2, -PI_F / 2 + 2 * PI_F * limitar(j->segurou / precisa, 0, 1),
            COR_OURO);
    dica = j->estagio == 0 ? (ru->alvo ? "{R2} até a faixa, e segure" : "{L2} até a faixa, e segure")
                           : (ru->alvo ? "agora {R2} até o fundo" : "agora {L2} até o fundo");
    break;
  }
  }
  Fonte fd = f.w < 560 ? F_PEQUENA_N : F_TEXTO_N;
  wg_texto_rico(r, fd, f.x + f.w / 2, cy + R + 34, COR_TEXTO, ALINHA_CENTRO, dica);
}

static void desenhar_fila(App *a, Jogador *j, SDL_FRect f) {
  SDL_Renderer *r = a->r;
  float y = f.y + f.h - 170;
  texto(r, F_PEQUENA_N, f.x + 28, y, COR_BRONZE_CLARO, "PRÓXIMAS");
  float x = f.x + 40;
  for (int k = 1; k <= 5 && j->atual + k < j->n; k++) {
    const Runa *ru = &j->fila[j->atual + k];
    Icone ic = ru->tipo == RUNA_BOTAO       ? icone_do_botao(ru->alvo)
               : ru->tipo == RUNA_ANALOGICO ? (ru->alvo ? IC_ANALOGICO_D : IC_ANALOGICO_E)
                                            : (ru->alvo ? IC_R2 : IC_L2);
    float alfa = 1 - (k - 1) * 0.16f;
    ds_circulo(r, x + 30, y + 64, 30, cor_alfa(COR_FUNDO_0, 0.8f * alfa));
    icone_natural(r, ic, x + 30, y + 64, 42, 0);
    x += 72;
  }
  int feitas = j->atual < j->n ? j->atual : j->n;
  wg_barra(r, f.x + 28, f.y + f.h - 56, f.w - 56, 12, j->n ? (float)feitas / (float)j->n : 0, COR_OURO);
  texto(r, F_MINI, f.x + 28, f.y + f.h - 36, COR_TEXTO_3, fmt("%d de %d runas · %d perdidas", feitas, j->n, j->perdidas));
}

static void desenhar(App *a) {
  SDL_Renderer *r = a->r;
  ds_fundo(r, a->t, 0.35f);
  sb_desenhar_topo(a, &g_b);
  for (int i = 0; i < g_n_faixas; i++) {
    int s = g_slot_faixa[i];
    SDL_FRect f = g_faixa[i];
    Jogador *j = &g_j[s];
    Pad *p = pads_do_slot(a, s);
    sb_moldura(a, f, s, g_b.acabou[s] ? 0.8f : 0.25f + 0.5f * j->pop);
    texto_al(r, F_GRANDE_N, f.x + f.w - 28, f.y + 14, COR_TEXTO, ALINHA_DIR, fmt("%d", g_b.pontos[s]));
    if (j->combo > 1)
      texto_al(r, F_PEQUENA_N, f.x + f.w - 28, f.y + 66, COR_BRASA_VIVA, ALINHA_DIR, fmt("combo ×%d", j->combo));
    if (g_b.fase != FASE_AVISO)
      desenhar_runa(a, s, j, p, f);
    desenhar_fila(a, j, f);
    if (!p)
      sb_sem_controle(a, f, s);
  }
  particulas_desenhar(r, &a->brasas);
  if (g_b.fase == FASE_AVISO)
    sb_desenhar_aviso(a, &g_b,
                      "Cada um tem a sua pedra. Quando a runa acender, aperte o botão dela\n"
                      "antes que o anel se apague. Nas runas de {LE} e {LD}, gire até a borda;\n"
                      "no fole, segure {L2} ou {R2} na faixa e depois aperte até o fundo.\n"
                      "Agora, solte os analógicos: a sala mede o repouso deles.");
  else if (g_b.fase == FASE_FIM)
    sb_desenhar_fim(a, &g_b);
  else {
    Dica d[] = {{IC_OPTIONS, "pausa"}};
    wg_rodape(r, d, 1);
  }
  pausa_desenhar(a);
}

const Cena CENA_CENTELHA = {"centelha", entrar, sair, NULL, atualizar, desenhar};
