/* Os controles conectados e os quatro lugares (P1..P4).
 *
 * Um controle conectado é um PAD; um lugar à mesa é um SLOT. Todo controle
 * que aparece vira pad; só vira jogador quando aperta ✕ no lobby. O slot
 * guarda o jogador mesmo se o cabo sair: o pad some, o slot fica esperando, e
 * quando um controle com a mesma assinatura volta, ele reassume o lugar.
 *
 * Identidade por PLAYER INDEX (0..3), como o contrato manda — nunca por
 * endereço. SDL_SetGamepadPlayerIndex acende o padrão de LEDs do lugar, e a
 * lightbar recebe a cor do lugar.
 *
 * Toda saída passa por aqui (vibração, gatilho, luzes, áudio do HID), e cada
 * uma é anotada: no registro da sessão e no anel de "o que saiu" que o
 * diagnóstico mostra. É o degrau SAIU da escada de evidência.
 */
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
  char nome[128];         /* o que o SDL diz */
  char nome_sistema[128]; /* o que o kernel publica (Linux) */
  char vidpid[16];
  char caminho[256];      /* interno: nunca vai para o relatório */
  Uint16 vid, pid, fw;
  SDL_GamepadType tipo;
  Origem origem;
  char usb_pai[512];      /* interno: para casar com o áudio pelo aparelho */

  bool cap_giro, cap_acel, cap_touch, cap_rumble, cap_rgb, cap_leds, cap_efeitos;
  int n_dedos;

  /* entrada */
  bool b[SDL_GAMEPAD_BUTTON_COUNT];
  bool b_ant[SDL_GAMEPAD_BUTTON_COUNT];
  Uint64 b_quando[SDL_GAMEPAD_BUTTON_COUNT]; /* ns do último aperto */
  float ax[SDL_GAMEPAD_AXIS_COUNT];          /* -1..1; gatilhos 0..1 */
  float giro[3];                             /* rad/s */
  float acel[3];                             /* m/s² */
  Taxa taxa_giro, taxa_acel;
  float giro_hz_declarado, acel_hz_declarado;
  Postura postura; /* a inclinação, pela fusão do giro com a gravidade */
  Dedo dedo[2];
  int bateria;              /* -1 desconhecida */
  SDL_PowerState energia;
  SDL_JoystickConnectionState conexao_sdl;

  /* o report cru (só USB 0x01; o 0x31 do rádio este jogo não lê) */
  SDL_hid_device *hid;
  bool cru_ok;
  Uint8 cru[64];
  Uint8 status53;   /* bit0 fone, bit1 microfone de headset, bit2 mudo */
  Uint64 cru_reports;

  /* saída */
  ForjaSombra sombra;
  bool rumble_escala_cheia; /* o SDL manda o rumble inteiro (Edge ou fw >= 0x0224) */
  Uint16 rumble_baixo, rumble_alto;
  Uint64 rumble_ate_ms;
  SDL_Color luz;
  ForjaTriggerMode modo_l2, modo_r2;
  int leds_jogador;
  int led_mic;
  char saidas[PAD_ANEL_SAIDAS][112];
  float saidas_t[PAD_ANEL_SAIDAS];
  int saidas_prox;
  int saidas_falhas;

  int slot;          /* -1 fora da mesa */
  int espelho_de;    /* slot de quem ele parece espelho, -1 nenhum */
  float visto_em;    /* app->t da conexão */
} Pad;

typedef struct Slot {
  bool ocupado;
  int pad;                 /* índice em pads[], -1 desconectado */
  char assinatura[200];    /* vid:pid + tipo de origem + nome, para a volta */
  float desconectado_em;   /* app->t; 0 conectado */
  int pontos;
  int reconexoes;
} Slot;

typedef struct Pads {
  Pad pad[MAX_PADS];
  Slot slot[MAX_JOGADORES];
  int ultimo_join_pad;
  Uint64 ultimo_join_ns;
  bool contrato_estrito; /* SDL_HINT_JOYSTICK_ENHANCED_REPORTS = "0" */
} Pads;

struct Forja;

void pads_iniciar(struct Forja *a);
void pads_encerrar(struct Forja *a);
/* Trata os eventos de gamepad. Devolve true se o evento era de controle. */
bool pads_evento(struct Forja *a, const SDL_Event *e);
/* Uma vez por quadro, antes das cenas: bordas de botão, vibração que venceu,
 * report cru, bateria. */
void pads_atualizar(struct Forja *a, float dt);
/* Depois das cenas: guarda o estado dos botões para a borda do próximo. */
void pads_fim_do_quadro(struct Forja *a);

/* Consultas */
Pad *pads_do_slot(struct Forja *a, int slot);        /* NULL se vazio/desconectado */
int pads_jogadores(struct Forja *a);                  /* quantos slots ocupados */
int pads_conectados(struct Forja *a);                 /* quantos pads */
bool pad_apertou(const Pad *p, SDL_GamepadButton b); /* borda de descida neste quadro */
bool pad_soltou(const Pad *p, SDL_GamepadButton b);
bool pad_segura(const Pad *p, SDL_GamepadButton b);
bool pad_fala_dualsense(const Pad *p);              /* efeitos, sensores e toque */
const char *pad_origem_rotulo(const Pad *p);        /* "DualSense nativo", "simulado (SDL virtual)"... */

/* A mesa */
int pads_entrar(struct Forja *a, int pad);   /* devolve o slot, -1 cheio */
void pads_sair(struct Forja *a, int slot);
void pads_silencio(struct Forja *a, int slot); /* tudo desligado, cor e LED do lugar */
void pads_silencio_todos(struct Forja *a);

/* Saídas (cada uma anotada) */
bool pad_rumble(struct Forja *a, Pad *p, float forte, float fraco, int ms);
bool pad_luz(struct Forja *a, Pad *p, SDL_Color c);
bool pad_luz_do_slot(struct Forja *a, Pad *p);
bool pad_gatilho(struct Forja *a, Pad *p, int direito, ForjaTrigger t);
bool pad_gatilhos_off(struct Forja *a, Pad *p);
bool pad_led_mic(struct Forja *a, Pad *p, int modo);
bool pad_leds_jogador(struct Forja *a, Pad *p, int mascara);
bool pad_leds_do_slot(struct Forja *a, Pad *p);
bool pad_alto_falante(struct Forja *a, Pad *p, int volume, int rota, int preamp);
/* Anota uma saída no anel do diagnóstico e no registro. */
void pad_anotar(struct Forja *a, Pad *p, bool ok, const char *fmt, ...)
#if defined(__GNUC__)
    __attribute__((format(printf, 4, 5)))
#endif
    ;

/* A cor de lightbar de cada lugar. */
extern const SDL_Color LUZ_DO_LUGAR[MAX_JOGADORES];

/* O rótulo "P3" / "—" */
const char *pads_rotulo_slot(int slot);

#endif
