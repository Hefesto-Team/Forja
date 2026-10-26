#ifndef FORJA_PADS_H
#define FORJA_PADS_H

#include <SDL3/SDL.h>

#include "forja_dualsense.h"
#include "origem.h"
#include "postura.h"
#include "taxa.h"

#define MAX_PADS 12
#define MAX_JOGADORES 4
#define PAD_ANEL_SAIDAS 10

typedef struct Dedo {
  bool baixo;
  float x, y, pressao;
} Dedo;

typedef struct Pad {
  bool usado;
  SDL_JoystickID id;
  SDL_Gamepad *gp;
  bool simulado;
  char nome[128];
  char nome_sistema[128];
  char vidpid[16];
  char caminho[256];
  Uint16 vid, pid, fw;
  SDL_GamepadType tipo;
  Origem origem;
  char usb_pai[512];

  bool cap_giro, cap_acel, cap_touch, cap_rumble, cap_rgb, cap_leds, cap_efeitos;
  int n_dedos;

  bool b[SDL_GAMEPAD_BUTTON_COUNT];
  bool b_ant[SDL_GAMEPAD_BUTTON_COUNT];
  Uint64 b_quando[SDL_GAMEPAD_BUTTON_COUNT];
  float ax[SDL_GAMEPAD_AXIS_COUNT];
  float giro[3];
  float acel[3];
  Taxa taxa_giro, taxa_acel;
  float giro_hz_declarado, acel_hz_declarado;
  Postura postura;
  Dedo dedo[2];
  int bateria;
  SDL_PowerState energia;
  SDL_JoystickConnectionState conexao_sdl;

  SDL_hid_device *hid;
  bool cru_ok;
  Uint8 cru[64];
  Uint8 status53;
  Uint64 cru_reports;

  ForjaSombra sombra;
  bool rumble_escala_cheia;
  Uint16 rumble_baixo, rumble_alto;
  Uint64 rumble_ate_ms;
  float rumble_ate_t;
  SDL_Color luz;
  ForjaTriggerMode modo_l2, modo_r2;
  int leds_jogador;
  int led_mic;
  char saidas[PAD_ANEL_SAIDAS][112];
  float saidas_t[PAD_ANEL_SAIDAS];
  int saidas_prox;
  int saidas_falhas;

  int slot;
  int reserva;
  int espelho_de;
  float visto_em;
} Pad;

typedef struct Slot {
  bool ocupado;
  int pad;
  char assinatura[200];
  float desconectado_em;
  int pontos;
  int reconexoes;
  int reservado_por;
} Slot;

typedef struct Pads {
  Pad pad[MAX_PADS];
  Slot slot[MAX_JOGADORES];
  int ultimo_join_pad;
  Uint64 ultimo_join_ns;
  bool contrato_estrito;
} Pads;

struct Forja;

void pads_iniciar(struct Forja *a);
void pads_encerrar(struct Forja *a);
bool pads_evento(struct Forja *a, const SDL_Event *e);
void pads_atualizar(struct Forja *a, float dt);
void pads_fim_do_quadro(struct Forja *a);

Pad *pads_do_slot(struct Forja *a, int slot);
int pads_jogadores(struct Forja *a);
int pads_conectados(struct Forja *a);
bool pad_apertou(const Pad *p, SDL_GamepadButton b);
bool pad_soltou(const Pad *p, SDL_GamepadButton b);
bool pad_segura(const Pad *p, SDL_GamepadButton b);
bool pad_fala_dualsense(const Pad *p);
const char *pad_origem_rotulo(const Pad *p);
Uint64 pad_agora_ns(const struct Forja *a, const Pad *p);

const char *pad_transporte(const Pad *p);
int pad_lugar(const Pad *p);

int pads_entrar(struct Forja *a, int pad);
int pads_trocar_reserva(struct Forja *a, int pad);
void pads_sair(struct Forja *a, int slot);
void pads_silencio(struct Forja *a, int slot);
void pads_silencio_todos(struct Forja *a);

bool pad_rumble(struct Forja *a, Pad *p, float forte, float fraco, int ms);
bool pad_luz(struct Forja *a, Pad *p, SDL_Color c);
bool pad_luz_do_slot(struct Forja *a, Pad *p);
bool pad_gatilho(struct Forja *a, Pad *p, int direito, ForjaTrigger t);
bool pad_gatilhos_off(struct Forja *a, Pad *p);
bool pad_led_mic(struct Forja *a, Pad *p, int modo);
bool pad_leds_jogador(struct Forja *a, Pad *p, int mascara);
bool pad_leds_do_slot(struct Forja *a, Pad *p);
bool pad_alto_falante(struct Forja *a, Pad *p, int volume, int rota, int preamp);
void pad_anotar(struct Forja *a, Pad *p, bool ok, const char *fmt, ...)
#if defined(__GNUC__)
    __attribute__((format(printf, 4, 5)))
#endif
    ;

extern const SDL_Color LUZ_DO_LUGAR[MAX_JOGADORES];

const char *pads_rotulo_slot(int slot);

#endif
