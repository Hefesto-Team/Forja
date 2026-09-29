/* O simulador. Ver simulador.h. */
#include "simulador.h"

#include "forja.h"
#include "aleatorio.h"

#include <math.h>

#define MAX_SIM 4
#define MAX_ACOES 24

typedef enum { AC_BOTAO, AC_EIXO, AC_GIRO, AC_SACODE, AC_TOQUE } TipoAcao;

typedef struct Acao {
  bool viva;
  TipoAcao tipo;
  int alvo;     /* botão, eixo ou dedo */
  float valor;
  float x, y, z;
  float fim;    /* app->t */
} Acao;

typedef struct Sim {
  bool usado;
  SDL_JoystickID id;
  SDL_Joystick *js;
  Percepcao perc;
  Acao acao[MAX_ACOES];
  bool botao_tecla[SDL_GAMEPAD_BUTTON_COUNT];
  float eixo_tecla[SDL_GAMEPAD_AXIS_COUNT];
  float giro_tecla[3];
  float sacode_tecla;
  float fala_tecla;          /* a barra de espaço: falar no microfone de mentira */
  float fala, fala_ate;      /* o robô falando no microfone: nível e até quando */
  bool mouse_dedo[2]; /* o mouse faz de dedo: esquerdo = dedo 1, direito = dedo 2 */
  float mouse_x[2], mouse_y[2];
  Uint64 sensor_ns;
  double acum_sensor;
  float fase;
  float rol, arf, gui; /* a postura do controle de mentira (rad) */
  long efeitos;        /* pacotes de efeito que chegaram */
  float engasgo_ate;   /* o defeito "engasga": a entrada parada até aqui (app->t) */
} Sim;

static float limitar(float v, float a, float b) { return v < a ? a : (v > b ? b : v); }

static Sim g_sim[MAX_SIM];
static int g_n, g_sel;

static const struct {
  const char *nome;
  unsigned bit;
} DEFEITOS[] = {
    {"troca-cruz-circulo", DEFEITO_TROCA_CRUZ_CIRCULO}, {"analogico-curto", DEFEITO_ANALOGICO_CURTO},
    {"gatilho-digital", DEFEITO_GATILHO_DIGITAL},       {"giro-invertido", DEFEITO_GIRO_INVERTIDO},
    {"acel-escala", DEFEITO_ACEL_ESCALA},               {"um-dedo", DEFEITO_UM_DEDO},
    {"sem-clique", DEFEITO_SEM_CLIQUE},                 {"motores-trocados", DEFEITO_MOTORES_TROCADOS},
    {"vibra-vizinho", DEFEITO_VIBRA_VIZINHO},           {"luz-parada", DEFEITO_LUZ_PARADA},
    {"gatilho-mudo", DEFEITO_GATILHO_MUDO},             {"leds-errados", DEFEITO_LEDS_ERRADOS},
    {"sem-alto-falante", DEFEITO_SEM_ALTO_FALANTE},     {"som-vizinho", DEFEITO_SOM_VIZINHO},
    {"haptica-trocada", DEFEITO_HAPTICA_TROCADA},       {"mic-surdo", DEFEITO_MIC_SURDO},
    {"led-mic-parado", DEFEITO_LED_MIC_PARADO},         {"mudo-nao-chega", DEFEITO_MUDO_NAO_CHEGA},
    {"haptica-muda", DEFEITO_HAPTICA_MUDA},             {"engasga", DEFEITO_ENGASGA},
};
static unsigned g_defeitos;
static float g_t_sim; /* o app->t do último quadro, para a voz do robô */
static unsigned g_def_agora; /* os defeitos valendo neste quadro (só dentro das salas) */
static char g_defeitos_texto[200];

bool simulador_defeitos(const char *lista, char *erro, size_t tam_erro) {
  g_defeitos = 0;
  g_defeitos_texto[0] = 0;
  char tmp[256];
  SDL_strlcpy(tmp, lista ? lista : "", sizeof(tmp));
  char *salvo = NULL;
  for (char *tok = SDL_strtok_r(tmp, ",", &salvo); tok; tok = SDL_strtok_r(NULL, ",", &salvo)) {
    bool achou = false;
    for (size_t i = 0; i < sizeof(DEFEITOS) / sizeof(DEFEITOS[0]); i++)
      if (!SDL_strcmp(tok, DEFEITOS[i].nome)) {
        g_defeitos |= DEFEITOS[i].bit;
        achou = true;
      }
    if (!achou) {
      SDL_snprintf(erro, tam_erro, "defeito desconhecido: %s", tok);
      return false;
    }
    if (g_defeitos_texto[0])
      SDL_strlcat(g_defeitos_texto, ", ", sizeof(g_defeitos_texto));
    SDL_strlcat(g_defeitos_texto, tok, sizeof(g_defeitos_texto));
  }
  return true;
}

const char *simulador_defeitos_texto(void) { return g_defeitos_texto; }
unsigned simulador_defeitos_agora(void) { return g_def_agora; }
static bool g_robo;
static Sorteio g_sorteio;
static const Uint32 MASCARA_BOTOES = 0x1FFFFFu & ~((1u << SDL_GAMEPAD_BUTTON_RIGHT_PADDLE1) |
                                                   (1u << SDL_GAMEPAD_BUTTON_LEFT_PADDLE1) |
                                                   (1u << SDL_GAMEPAD_BUTTON_RIGHT_PADDLE2) |
                                                   (1u << SDL_GAMEPAD_BUTTON_LEFT_PADDLE2));

static int indice_botao(int b) {
  if (!(MASCARA_BOTOES & (1u << b)))
    return -1;
  int n = 0;
  for (int i = 0; i < b; i++)
    if (MASCARA_BOTOES & (1u << i))
      n++;
  return n;
}

static int popcount(Uint32 m) {
  int n = 0;
  for (; m; m >>= 1)
    n += (int)(m & 1);
  return n;
}

/* ---------- os callbacks: o que chega ao "plástico" ---------- */

static bool SDLCALL cb_rumble(void *u, Uint16 baixo, Uint16 alto) {
  Sim *s = u;
  if (g_def_agora & DEFEITO_MOTORES_TROCADOS) {
    Uint16 t = baixo;
    baixo = alto;
    alto = t;
  }
  if ((g_def_agora & DEFEITO_VIBRA_VIZINHO) && g_n > 1) {
    /* o fio trocado: a vibração deste controle chega no próximo da fila */
    int i = (int)(s - g_sim);
    s = &g_sim[(i + 1) % g_n];
  }
  s->perc.forte = baixo / 65535.0f;
  s->perc.fraco = alto / 65535.0f;
  return true;
}

static bool SDLCALL cb_rumble_gatilhos(void *u, Uint16 e, Uint16 d) {
  (void)u;
  (void)e;
  (void)d;
  return false;
}

static bool SDLCALL cb_led(void *u, Uint8 r, Uint8 g, Uint8 b) {
  Sim *s = u;
  if (g_def_agora & DEFEITO_LUZ_PARADA)
    return true;
  s->perc.luz_r = r;
  s->perc.luz_g = g;
  s->perc.luz_b = b;
  s->perc.luz_ok = true;
  return true;
}

static bool SDLCALL cb_efeito(void *u, const void *dados, int tam) {
  Sim *s = u;
  const Uint8 *b = dados;
  if (tam > (int)sizeof(s->perc.efeito))
    tam = (int)sizeof(s->perc.efeito);
  SDL_memcpy(s->perc.efeito, b, (size_t)tam);
  s->perc.n_efeito = tam;
  s->perc.efeito_ms = SDL_GetTicks();
  /* o intermediário que engasga sob carga: a cada 40 pacotes, a entrada para */
  if (++s->efeitos % 40 == 0 && (g_def_agora & DEFEITO_ENGASGA))
    s->engasgo_ate = g_t_sim + 1.5f;
  if (tam >= 47) {
    /* o "firmware" do simulador obedece aos blocos cujos bits vieram ligados */
    if ((b[0] & 0x04) && !(g_def_agora & DEFEITO_GATILHO_MUDO))
      SDL_memcpy(s->perc.gatilho_dir, b + 10, 11);
    if ((b[0] & 0x08) && !(g_def_agora & DEFEITO_GATILHO_MUDO))
      SDL_memcpy(s->perc.gatilho_esq, b + 21, 11);
    if ((b[1] & 0x01) && !(g_def_agora & DEFEITO_LED_MIC_PARADO))
      s->perc.led_mic = b[8] <= 3 ? b[8] : 0;
    if (b[1] & 0x10) {
      int m = b[43] & 0x1F;
      s->perc.leds_jogador = (g_def_agora & DEFEITO_LEDS_ERRADOS) ? m >> 1 : m;
    }
    if ((b[1] & 0x04) && !(g_def_agora & DEFEITO_LUZ_PARADA)) {
      s->perc.luz_r = b[44];
      s->perc.luz_g = b[45];
      s->perc.luz_b = b[46];
      s->perc.luz_ok = true;
    }
  }
  return true;
}

static bool SDLCALL cb_sensores(void *u, bool ligado) {
  (void)u;
  (void)ligado;
  return true;
}

static void SDLCALL cb_indice(void *u, int indice) {
  Sim *s = u;
  static const int figuras[] = {0x04, 0x0A, 0x15, 0x1B, 0x1F};
  s->perc.player_index = indice;
  s->perc.leds_jogador = indice >= 0 ? figuras[indice % 5] : 0;
}

/* ---------- vida ---------- */

void simulador_iniciar(Forja *a, int n) {
  (void)a;
  SDL_memset(g_sim, 0, sizeof(g_sim));
  g_n = n > MAX_SIM ? MAX_SIM : n;
  g_robo = a->robo;
  sorteio_semear(&g_sorteio, a->semente ^ 0x5151ull);
  static SDL_VirtualJoystickTouchpadDesc toque = {2, {0, 0, 0}};
  static SDL_VirtualJoystickSensorDesc sensores[2] = {{SDL_SENSOR_GYRO, 250.0f}, {SDL_SENSOR_ACCEL, 250.0f}};
  static const char *nomes[MAX_SIM] = {"DualSense simulado 1", "DualSense simulado 2", "DualSense simulado 3",
                                       "DualSense simulado 4"};
  for (int i = 0; i < g_n; i++) {
    Sim *s = &g_sim[i];
    SDL_VirtualJoystickDesc d;
    SDL_INIT_INTERFACE(&d);
    d.type = SDL_JOYSTICK_TYPE_GAMEPAD;
    d.vendor_id = 0x054C;
    d.product_id = 0x0CE6;
    d.naxes = SDL_GAMEPAD_AXIS_COUNT;
    d.nbuttons = (Uint16)popcount(MASCARA_BOTOES);
    d.button_mask = MASCARA_BOTOES;
    d.axis_mask = (1u << SDL_GAMEPAD_AXIS_COUNT) - 1;
    d.ntouchpads = 1;
    d.touchpads = &toque;
    d.nsensors = 2;
    d.sensors = sensores;
    d.name = nomes[i];
    d.userdata = s;
    d.Rumble = cb_rumble;
    d.RumbleTriggers = cb_rumble_gatilhos;
    d.SetLED = cb_led;
    d.SendEffect = cb_efeito;
    d.SetSensorsEnabled = cb_sensores;
    d.SetPlayerIndex = cb_indice;
    /* antes de ligar: o SDL já dá um player index ao controle na chegada, e o
     * aviso (cb_indice) não pode ser apagado depois */
    s->perc.player_index = -1;
    s->perc.gatilho_dir[0] = s->perc.gatilho_esq[0] = 0x05;
    s->id = SDL_AttachVirtualJoystick(&d);
    if (!s->id)
      continue;
    s->js = SDL_OpenJoystick(s->id);
    s->usado = true;
    s->fase = (float)i;
  }
}

void simulador_encerrar(Forja *a) {
  (void)a;
  for (int i = 0; i < g_n; i++)
    if (g_sim[i].usado) {
      if (g_sim[i].js)
        SDL_CloseJoystick(g_sim[i].js);
      SDL_DetachVirtualJoystick(g_sim[i].id);
    }
  g_n = 0;
}

bool simulador_ativo(void) { return g_n > 0; }
bool robo_ativo(void) { return g_robo && g_n > 0; }
int simulador_selecionado(void) { return g_sel; }

const Percepcao *simulador_percepcao(SDL_JoystickID id) {
  for (int i = 0; i < g_n; i++)
    if (g_sim[i].usado && g_sim[i].id == id)
      return &g_sim[i].perc;
  return NULL;
}

static Sim *sim_do_pad(Forja *a, int pad) {
  if (pad < 0 || pad >= MAX_PADS || !a->pads.pad[pad].usado)
    return NULL;
  for (int i = 0; i < g_n; i++)
    if (g_sim[i].usado && g_sim[i].id == a->pads.pad[pad].id)
      return &g_sim[i];
  return NULL;
}

/* A ação nova do mesmo botão, eixo ou dedo toma o lugar da velha (vale a mais
 * nova de qualquer jeito): o robô que reescreve os analógicos a cada quadro
 * não enche a fila e não deixa o aperto do gatilho de fora. */
static void agendar(Sim *s, Acao ac) {
  ac.viva = true;
  int livre = -1;
  for (int i = 0; i < MAX_ACOES; i++) {
    Acao *v = &s->acao[i];
    if (v->viva && v->tipo == ac.tipo && v->alvo == ac.alvo) {
      *v = ac;
      return;
    }
    if (!v->viva && livre < 0)
      livre = i;
  }
  if (livre >= 0)
    s->acao[livre] = ac;
}

void robo_apertar(Forja *a, int pad, SDL_GamepadButton b, float seg) {
  Sim *s = sim_do_pad(a, pad);
  if (!s)
    return;
  Acao ac = {0};
  ac.tipo = AC_BOTAO;
  ac.alvo = b;
  ac.fim = a->t + (seg > 0.05f ? seg : 0.08f);
  agendar(s, ac);
}

void robo_eixo(Forja *a, int pad, SDL_GamepadAxis eixo, float valor, float seg) {
  Sim *s = sim_do_pad(a, pad);
  if (!s)
    return;
  Acao ac = {0};
  ac.tipo = AC_EIXO;
  ac.alvo = eixo;
  ac.valor = valor;
  ac.fim = a->t + seg;
  agendar(s, ac);
}

void robo_girar(Forja *a, int pad, float gx, float gy, float gz, float seg) {
  Sim *s = sim_do_pad(a, pad);
  if (!s)
    return;
  Acao ac = {0};
  ac.tipo = AC_GIRO;
  ac.x = gx;
  ac.y = gy;
  ac.z = gz;
  ac.fim = a->t + seg;
  agendar(s, ac);
}

void robo_sacudir(Forja *a, int pad, float g, float seg) {
  Sim *s = sim_do_pad(a, pad);
  if (!s)
    return;
  Acao ac = {0};
  ac.tipo = AC_SACODE;
  ac.valor = g;
  ac.fim = a->t + seg;
  agendar(s, ac);
}

void robo_tocar(Forja *a, int pad, int dedo, float x, float y, float seg) {
  Sim *s = sim_do_pad(a, pad);
  if (!s)
    return;
  Acao ac = {0};
  ac.tipo = AC_TOQUE;
  ac.alvo = dedo;
  ac.x = x;
  ac.y = y;
  ac.fim = a->t + seg;
  agendar(s, ac);
}

float robo_acaso(void) { return sorteio_real(&g_sorteio); }

void robo_falar(Forja *a, int pad, float nivel, float seg) {
  Sim *s = sim_do_pad(a, pad);
  if (!s)
    return;
  s->fala = nivel;
  s->fala_ate = a->t + seg;
}

float simulador_fala(SDL_JoystickID id) {
  for (int i = 0; i < g_n; i++)
    if (g_sim[i].usado && g_sim[i].id == id) {
      /* uma sala quieta não é silêncio absoluto: o microfone de verdade sempre
       * ouve o ambiente (SIM_PISO_DA_SALA); silêncio absoluto é o mudo do sistema */
      float robo = g_t_sim < g_sim[i].fala_ate ? g_sim[i].fala : SIM_PISO_DA_SALA;
      return robo > g_sim[i].fala_tecla ? robo : g_sim[i].fala_tecla;
    }
  return 0;
}

/* ---------- o teclado ---------- */

/* ---------- à mão: o jogo dirige o controle selecionado ----------
 *
 * Sem janela própria, o módulo não vê o teclado: o jogo (o Godot) lê as
 * teclas e diz aqui o que está apertado no controle de mentira selecionado. */

static Sim *sim_manual(int sim) { return sim >= 0 && sim < g_n && g_sim[sim].usado ? &g_sim[sim] : NULL; }

void simulador_selecionar(int sim) {
  if (sim >= 0 && sim < g_n)
    g_sel = sim;
}

void simulador_manual_botao(int sim, int botao, bool baixo) {
  Sim *s = sim_manual(sim);
  if (s && botao >= 0 && botao < SDL_GAMEPAD_BUTTON_COUNT)
    s->botao_tecla[botao] = baixo;
}

void simulador_manual_eixo(int sim, int eixo, float v) {
  Sim *s = sim_manual(sim);
  if (s && eixo >= 0 && eixo < SDL_GAMEPAD_AXIS_COUNT)
    s->eixo_tecla[eixo] = v;
}

void simulador_manual_giro(int sim, float gx, float gy, float gz) {
  Sim *s = sim_manual(sim);
  if (!s)
    return;
  s->giro_tecla[0] = gx;
  s->giro_tecla[1] = gy;
  s->giro_tecla[2] = gz;
}

void simulador_manual_dedo(int sim, int dedo, bool baixo, float x, float y) {
  Sim *s = sim_manual(sim);
  if (!s || dedo < 0 || dedo > 1)
    return;
  s->mouse_dedo[dedo] = baixo;
  s->mouse_x[dedo] = x;
  s->mouse_y[dedo] = y;
}

void simulador_manual_fala(int sim, float nivel) {
  Sim *s = sim_manual(sim);
  if (s)
    s->fala_tecla = nivel;
}

void simulador_manual_sacode(int sim, float g) {
  Sim *s = sim_manual(sim);
  if (s)
    s->sacode_tecla = g;
}

/* ---------- a cada quadro ---------- */

void simulador_atualizar(Forja *a, float dt) {
  g_def_agora = a->em_sala ? g_defeitos : 0;
  g_t_sim = a->t;
  for (int i = 0; i < g_n; i++) {
    Sim *s = &g_sim[i];
    if (!s->usado || !s->js)
      continue;
    bool botao[SDL_GAMEPAD_BUTTON_COUNT];
    float eixo[SDL_GAMEPAD_AXIS_COUNT];
    float giro[3] = {s->giro_tecla[0], s->giro_tecla[1], s->giro_tecla[2]};
    float sacode = s->sacode_tecla;
    bool dedo[2] = {s->mouse_dedo[0], s->mouse_dedo[1]};
    float dx[2] = {s->mouse_x[0], s->mouse_x[1]}, dy[2] = {s->mouse_y[0], s->mouse_y[1]};
    SDL_memcpy(botao, s->botao_tecla, sizeof(botao));
    SDL_memcpy(eixo, s->eixo_tecla, sizeof(eixo));
    /* quando duas ações pedem a mesma coisa, vale a mais nova (a que acaba
     * depois): o robô reescreve o analógico e o dedo a cada quadro */
    float fim_eixo[SDL_GAMEPAD_AXIS_COUNT], fim_dedo[2] = {-1, -1}, fim_giro = -1;
    for (int x = 0; x < SDL_GAMEPAD_AXIS_COUNT; x++)
      fim_eixo[x] = -1;
    float giro_robo[3] = {0, 0, 0};
    for (int k = 0; k < MAX_ACOES; k++) {
      Acao *ac = &s->acao[k];
      if (!ac->viva)
        continue;
      if (a->t >= ac->fim) {
        ac->viva = false;
        continue;
      }
      switch (ac->tipo) {
      case AC_BOTAO:
        botao[ac->alvo] = true;
        break;
      case AC_EIXO:
        if (ac->fim > fim_eixo[ac->alvo]) {
          fim_eixo[ac->alvo] = ac->fim;
          eixo[ac->alvo] = ac->valor;
        }
        break;
      case AC_GIRO:
        if (ac->fim > fim_giro) {
          fim_giro = ac->fim;
          giro_robo[0] = ac->x;
          giro_robo[1] = ac->y;
          giro_robo[2] = ac->z;
        }
        break;
      case AC_SACODE:
        if (ac->valor > sacode)
          sacode = ac->valor;
        break;
      case AC_TOQUE:
        if (ac->fim > fim_dedo[ac->alvo]) {
          fim_dedo[ac->alvo] = ac->fim;
          dedo[ac->alvo] = true;
          dx[ac->alvo] = ac->x;
          dy[ac->alvo] = ac->y;
        }
        break;
      }
    }
    for (int e = 0; e < 3; e++)
      giro[e] += giro_robo[e];

    /* os defeitos entram entre a mão e o "fio": o robô aperta o que quer, e o
     * jogo recebe o que o intermediário quebrado deixaria passar. Valem dentro
     * das salas; no menu e no salão o controle chega inteiro, para o robô
     * chegar até elas */
    unsigned def = a->em_sala ? g_defeitos : 0;
    if (def & DEFEITO_TROCA_CRUZ_CIRCULO) {
      bool c = botao[SDL_GAMEPAD_BUTTON_SOUTH];
      botao[SDL_GAMEPAD_BUTTON_SOUTH] = botao[SDL_GAMEPAD_BUTTON_EAST];
      botao[SDL_GAMEPAD_BUTTON_EAST] = c;
    }
    if (def & DEFEITO_SEM_CLIQUE)
      botao[SDL_GAMEPAD_BUTTON_TOUCHPAD] = false;
    if (def & DEFEITO_MUDO_NAO_CHEGA)
      botao[SDL_GAMEPAD_BUTTON_MISC1] = false;
    if (def & DEFEITO_ANALOGICO_CURTO) {
      eixo[SDL_GAMEPAD_AXIS_LEFTX] *= 0.7f;
      eixo[SDL_GAMEPAD_AXIS_LEFTY] *= 0.7f;
      eixo[SDL_GAMEPAD_AXIS_RIGHTX] *= 0.7f;
      eixo[SDL_GAMEPAD_AXIS_RIGHTY] *= 0.7f;
    }
    if (def & DEFEITO_GATILHO_DIGITAL) {
      eixo[SDL_GAMEPAD_AXIS_LEFT_TRIGGER] = eixo[SDL_GAMEPAD_AXIS_LEFT_TRIGGER] > 0.5f ? 1.0f : 0.0f;
      eixo[SDL_GAMEPAD_AXIS_RIGHT_TRIGGER] = eixo[SDL_GAMEPAD_AXIS_RIGHT_TRIGGER] > 0.5f ? 1.0f : 0.0f;
    }
    if (def & DEFEITO_UM_DEDO)
      dedo[1] = false;
    if (a->t < s->engasgo_ate) {
      /* engasgado: nada sai do controle de mentira, nem os sensores */
      s->acum_sensor = 0;
      continue;
    }
    for (int b = 0; b < SDL_GAMEPAD_BUTTON_COUNT; b++) {
      int j = indice_botao(b);
      if (j >= 0)
        SDL_SetJoystickVirtualButton(s->js, j, botao[b]);
    }
    for (int x = 0; x < SDL_GAMEPAD_AXIS_COUNT; x++) {
      float v = eixo[x];
      Sint16 raw;
      if (x == SDL_GAMEPAD_AXIS_LEFT_TRIGGER || x == SDL_GAMEPAD_AXIS_RIGHT_TRIGGER)
        raw = (Sint16)(limitar(v, 0, 1) * 65535.0f - 32768.0f); /* o gatilho solto é -32768 */
      else
        raw = (Sint16)(limitar(v, -1, 1) * 32767);
      SDL_SetJoystickVirtualAxis(s->js, x, raw);
    }
    for (int d = 0; d < 2; d++)
      SDL_SetJoystickVirtualTouchpad(s->js, 0, d, dedo[d], dx[d], dy[d], dedo[d] ? 0.6f : 0);
    /* os sensores a 250 Hz, coerentes entre si: o controle de mentira tem uma
     * postura, o giro pedido a move, e o acelerômetro lê a gravidade dessa
     * postura (convenções do SDL: parado, Y = +9,8). Com o teclado, a mão
     * "relaxa" e o controle volta devagar ao nível — e o giro diz isso também */
    s->acum_sensor += dt * 250.0;
    s->fase += dt;
    int passos = 0;
    while (s->acum_sensor >= 1.0 && passos < 20) {
      s->acum_sensor -= 1.0;
      passos++;
      s->sensor_ns += 4000000ull;
      float g[3] = {giro[0], giro[1], giro[2]};
      if (!g_robo) {
        if (fabsf(g[0]) < 0.01f)
          g[0] = -2.5f * s->arf;
        if (fabsf(g[2]) < 0.01f)
          g[2] = -2.5f * s->rol;
      }
      const float passo = 0.004f, lim = 1.4f;
      s->arf = limitar(s->arf + g[0] * passo, -lim, lim);
      s->gui += g[1] * passo;
      s->rol = limitar(s->rol + g[2] * passo, -lim, lim);
      for (int e = 0; e < 3; e++)
        g[e] += (robo_acaso() - 0.5f) * 0.01f;
      const float G = 9.80665f;
      float pancada = sacode * G * fabsf(sinf(s->fase * 40));
      float ac[3] = {G * sinf(s->rol) * cosf(s->arf) + (robo_acaso() - 0.5f) * 0.02f,
                     G * cosf(s->rol) * cosf(s->arf) + pancada, -G * sinf(s->arf)};
      if (def & DEFEITO_GIRO_INVERTIDO)
        g[2] = -g[2];
      if (def & DEFEITO_ACEL_ESCALA)
        for (int e = 0; e < 3; e++)
          ac[e] *= 0.1f;
      SDL_SendJoystickVirtualSensorData(s->js, SDL_SENSOR_GYRO, s->sensor_ns, g, 3);
      SDL_SendJoystickVirtualSensorData(s->js, SDL_SENSOR_ACCEL, s->sensor_ns, ac, 3);
    }
  }
}
