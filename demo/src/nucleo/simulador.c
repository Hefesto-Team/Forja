/* O simulador. Ver simulador.h. */
#include "simulador.h"

#include "../app.h"
#include "../ui/tema.h"
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
  Uint64 sensor_ns;
  double acum_sensor;
  float fase;
} Sim;

static Sim g_sim[MAX_SIM];
static int g_n, g_sel;
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
  if (tam >= 47) {
    /* o "firmware" do simulador obedece aos blocos cujos bits vieram ligados */
    if (b[0] & 0x04)
      SDL_memcpy(s->perc.gatilho_dir, b + 10, 11);
    if (b[0] & 0x08)
      SDL_memcpy(s->perc.gatilho_esq, b + 21, 11);
    if (b[1] & 0x01)
      s->perc.led_mic = b[8] <= 3 ? b[8] : 0;
    if (b[1] & 0x10)
      s->perc.leds_jogador = b[43] & 0x1F;
    if (b[1] & 0x04) {
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

void simulador_iniciar(App *a, int n) {
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
    s->id = SDL_AttachVirtualJoystick(&d);
    if (!s->id)
      continue;
    s->js = SDL_OpenJoystick(s->id);
    s->usado = true;
    s->perc.player_index = -1;
    s->perc.gatilho_dir[0] = s->perc.gatilho_esq[0] = 0x05;
    s->fase = (float)i;
  }
}

void simulador_encerrar(App *a) {
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

static Sim *sim_do_pad(App *a, int pad) {
  if (pad < 0 || pad >= MAX_PADS || !a->pads.pad[pad].usado)
    return NULL;
  for (int i = 0; i < g_n; i++)
    if (g_sim[i].usado && g_sim[i].id == a->pads.pad[pad].id)
      return &g_sim[i];
  return NULL;
}

static void agendar(Sim *s, Acao ac) {
  for (int i = 0; i < MAX_ACOES; i++)
    if (!s->acao[i].viva) {
      ac.viva = true;
      s->acao[i] = ac;
      return;
    }
}

void robo_apertar(App *a, int pad, SDL_GamepadButton b, float seg) {
  Sim *s = sim_do_pad(a, pad);
  if (!s)
    return;
  Acao ac = {0};
  ac.tipo = AC_BOTAO;
  ac.alvo = b;
  ac.fim = a->t + (seg > 0.05f ? seg : 0.08f);
  agendar(s, ac);
}

void robo_eixo(App *a, int pad, SDL_GamepadAxis eixo, float valor, float seg) {
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

void robo_girar(App *a, int pad, float gx, float gy, float gz, float seg) {
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

void robo_sacudir(App *a, int pad, float g, float seg) {
  Sim *s = sim_do_pad(a, pad);
  if (!s)
    return;
  Acao ac = {0};
  ac.tipo = AC_SACODE;
  ac.valor = g;
  ac.fim = a->t + seg;
  agendar(s, ac);
}

void robo_tocar(App *a, int pad, int dedo, float x, float y, float seg) {
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

/* ---------- o teclado ---------- */

static int botao_da_tecla(SDL_Keycode k) {
  switch (k) {
  case SDLK_RETURN:
  case SDLK_Z:
    return SDL_GAMEPAD_BUTTON_SOUTH;
  case SDLK_ESCAPE:
  case SDLK_X:
    return SDL_GAMEPAD_BUTTON_EAST;
  case SDLK_C:
    return SDL_GAMEPAD_BUTTON_WEST;
  case SDLK_V:
    return SDL_GAMEPAD_BUTTON_NORTH;
  case SDLK_Q:
    return SDL_GAMEPAD_BUTTON_LEFT_SHOULDER;
  case SDLK_E:
    return SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER;
  case SDLK_O:
    return SDL_GAMEPAD_BUTTON_START;
  case SDLK_P:
    return SDL_GAMEPAD_BUTTON_BACK;
  case SDLK_T:
    return SDL_GAMEPAD_BUTTON_TOUCHPAD;
  case SDLK_M:
    return SDL_GAMEPAD_BUTTON_MISC1;
  case SDLK_UP:
    return SDL_GAMEPAD_BUTTON_DPAD_UP;
  case SDLK_DOWN:
    return SDL_GAMEPAD_BUTTON_DPAD_DOWN;
  case SDLK_LEFT:
    return SDL_GAMEPAD_BUTTON_DPAD_LEFT;
  case SDLK_RIGHT:
    return SDL_GAMEPAD_BUTTON_DPAD_RIGHT;
  case SDLK_F:
    return SDL_GAMEPAD_BUTTON_LEFT_STICK;
  case SDLK_G:
    return SDL_GAMEPAD_BUTTON_RIGHT_STICK;
  default:
    return -1;
  }
}

bool simulador_evento(App *a, const SDL_Event *e) {
  (void)a;
  if (g_n == 0 || (e->type != SDL_EVENT_KEY_DOWN && e->type != SDL_EVENT_KEY_UP))
    return false;
  if (e->key.repeat)
    return true;
  bool baixo = e->type == SDL_EVENT_KEY_DOWN;
  SDL_Keycode k = e->key.key;
  if (k == SDLK_TAB && baixo) {
    g_sel = (g_sel + 1) % g_n;
    app_avisar(a, "O teclado agora é o DualSense simulado %d", g_sel + 1);
    return true;
  }
  Sim *s = &g_sim[g_sel];
  int b = botao_da_tecla(k);
  if (b >= 0) {
    s->botao_tecla[b] = baixo;
    return true;
  }
  float v = baixo ? 1.0f : 0.0f;
  switch (k) {
  case SDLK_1:
    s->eixo_tecla[SDL_GAMEPAD_AXIS_LEFT_TRIGGER] = v;
    return true;
  case SDLK_3:
    s->eixo_tecla[SDL_GAMEPAD_AXIS_RIGHT_TRIGGER] = v;
    return true;
  case SDLK_W:
    s->eixo_tecla[SDL_GAMEPAD_AXIS_LEFTY] = -v;
    return true;
  case SDLK_S:
    s->eixo_tecla[SDL_GAMEPAD_AXIS_LEFTY] = v;
    return true;
  case SDLK_A:
    s->eixo_tecla[SDL_GAMEPAD_AXIS_LEFTX] = -v;
    return true;
  case SDLK_D:
    s->eixo_tecla[SDL_GAMEPAD_AXIS_LEFTX] = v;
    return true;
  case SDLK_I:
    s->giro_tecla[0] = -v * 3;
    return true;
  case SDLK_K:
    s->giro_tecla[0] = v * 3;
    return true;
  case SDLK_J:
    s->giro_tecla[1] = v * 3;
    return true;
  case SDLK_L:
    s->giro_tecla[1] = -v * 3;
    return true;
  default:
    return false;
  }
}

/* ---------- a cada quadro ---------- */

void simulador_atualizar(App *a, float dt) {
  for (int i = 0; i < g_n; i++) {
    Sim *s = &g_sim[i];
    if (!s->usado || !s->js)
      continue;
    bool botao[SDL_GAMEPAD_BUTTON_COUNT];
    float eixo[SDL_GAMEPAD_AXIS_COUNT];
    float giro[3] = {s->giro_tecla[0], s->giro_tecla[1], s->giro_tecla[2]};
    float sacode = 0;
    bool dedo[2] = {false, false};
    float dx[2] = {0}, dy[2] = {0};
    SDL_memcpy(botao, s->botao_tecla, sizeof(botao));
    SDL_memcpy(eixo, s->eixo_tecla, sizeof(eixo));
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
        eixo[ac->alvo] = ac->valor;
        break;
      case AC_GIRO:
        giro[0] += ac->x;
        giro[1] += ac->y;
        giro[2] += ac->z;
        break;
      case AC_SACODE:
        sacode = ac->valor;
        break;
      case AC_TOQUE:
        dedo[ac->alvo] = true;
        dx[ac->alvo] = ac->x;
        dy[ac->alvo] = ac->y;
        break;
      }
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
    /* os sensores a 250 Hz: gravidade no acelerômetro, e o giro pedido */
    s->acum_sensor += dt * 250.0;
    s->fase += dt;
    int passos = 0;
    while (s->acum_sensor >= 1.0 && passos < 20) {
      s->acum_sensor -= 1.0;
      passos++;
      s->sensor_ns += 4000000ull;
      float ruido_g[3] = {(robo_acaso() - 0.5f) * 0.01f, (robo_acaso() - 0.5f) * 0.01f,
                          (robo_acaso() - 0.5f) * 0.01f};
      float g[3] = {giro[0] + ruido_g[0], giro[1] + ruido_g[1], giro[2] + ruido_g[2]};
      float ac[3] = {0.02f * sinf(s->fase), -9.80665f - sacode * 9.80665f * fabsf(sinf(s->fase * 40)), 0.05f};
      SDL_SendJoystickVirtualSensorData(s->js, SDL_SENSOR_GYRO, s->sensor_ns, g, 3);
      SDL_SendJoystickVirtualSensorData(s->js, SDL_SENSOR_ACCEL, s->sensor_ns, ac, 3);
    }
  }
}
