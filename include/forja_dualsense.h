/* FORJA DualSense — USB output as Sony/SDL/Steam document it.
 *
 * Official HID trigger modes (Nielk1 / isteamdualsense.h):
 *   Off 0x05, Feedback 0x21, Weapon 0x25, Vibration 0x26
 * Simple leftovers 0x01/0x02/0x06 are not sent.
 *
 * FORBIDDEN: report 0x31, CRC 0xA2, Hefesto IPC, MAC/uniq.
 */
#ifndef FORJA_DUALSENSE_H
#define FORJA_DUALSENSE_H

#include <stdint.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

#define FORJA_DS5_FX_SIZE 47
#define FORJA_DS5_USB_REPORT_SIZE 64
#define FORJA_DS5_USB_REPORT_ID 0x02

#define FORJA_DS5_VID 0x054C
#define FORJA_DS5_PID 0x0CE6
#define FORJA_DS5_EDGE_PID 0x0DF2

#define FORJA_FX_RUMBLE 0x01
#define FORJA_FX_HAPTICS_SELECT 0x02
#define FORJA_FX_R2 0x04
#define FORJA_FX_L2 0x08
#define FORJA_FX_HEADPHONE_VOL 0x10
#define FORJA_FX_SPEAKER_VOL 0x20
#define FORJA_FX_MIC_VOL 0x40
#define FORJA_FX_AUDIO_CONTROL 0x80

#define FORJA_FX_MIC_LED 0x01
#define FORJA_FX_POWER_SAVE 0x02
#define FORJA_FX_LIGHTBAR 0x04
#define FORJA_FX_RELEASE_LEDS 0x08
#define FORJA_FX_PLAYER_LED 0x10
#define FORJA_FX_MOTOR_POWER 0x40
#define FORJA_FX_PREAMP 0x80
#define FORJA_FX2_PLAYER_BRIGHT 0x01
#define FORJA_FX2_VIBRATION_V2 0x04
#define FORJA_AUDIO_FORCE_INTERNAL_MIC 0x01
#define FORJA_AUDIO_ROTA_SPEAKER 2

typedef enum ForjaTriggerMode {
  FORJA_TRIGGER_OFF = 0,
  FORJA_TRIGGER_FEEDBACK = 1,
  FORJA_TRIGGER_WEAPON = 2,
  FORJA_TRIGGER_VIBRATION = 3
} ForjaTriggerMode;

/* Official structured HID (not simple 0x01/0x02/0x06). */
#define FORJA_HID_TRIGGER_OFF 0x05
#define FORJA_HID_TRIGGER_FEEDBACK 0x21
#define FORJA_HID_TRIGGER_WEAPON 0x25
#define FORJA_HID_TRIGGER_VIBRATION 0x26

static const uint8_t FORJA_PLAYER_LED[4] = {0x04, 0x0A, 0x15, 0x1B};

typedef struct ForjaTrigger {
  ForjaTriggerMode mode;
  uint8_t a; /* Feedback/Vibration: position 0-9; Weapon: start 2-7 */
  uint8_t b; /* Feedback: strength 1-8; Weapon: end; Vibration: amplitude 1-8 */
  uint8_t c; /* Weapon: strength 1-8; Vibration: frequency 1-255 */
} ForjaTrigger;

typedef struct ForjaDs5Output {
  uint8_t rumble_left;
  uint8_t rumble_right;
  ForjaTrigger l2;
  ForjaTrigger r2;
  uint8_t lightbar_r, lightbar_g, lightbar_b;
  uint8_t player_index;
  uint8_t player_led_on;
  uint8_t mic_led;
  uint8_t speaker_vol;
  uint8_t set_speaker;
} ForjaDs5Output;

typedef struct __attribute__((packed)) ForjaDs5Effect {
  uint8_t enable1;
  uint8_t enable2;
  uint8_t rumble_right;
  uint8_t rumble_left;
  uint8_t headphone_vol;
  uint8_t speaker_vol;
  uint8_t mic_vol;
  uint8_t audio_enable;
  uint8_t mic_led;
  uint8_t audio_mute;
  uint8_t right_trigger[11];
  uint8_t left_trigger[11];
  uint8_t unknown1[6];
  uint8_t led_flags;
  uint8_t unknown2[2];
  uint8_t led_anim;
  uint8_t led_brightness;
  uint8_t player_leds;
  uint8_t led_r, led_g, led_b;
} ForjaDs5Effect;

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(ForjaDs5Effect) == FORJA_DS5_FX_SIZE, "DS5 effect size");
#endif

void forja_trigger_pack(uint8_t out[11], ForjaTrigger t);
void forja_ds5_pack(ForjaDs5Effect *fx, const ForjaDs5Output *in);
void forja_ds5_usb_report(uint8_t report[FORJA_DS5_USB_REPORT_SIZE],
                          const ForjaDs5Output *in);

/* ---------------------------------------------------------------------------
 * A SOMBRA — o payload do SDL_SendGamepadEffect, montado bloco a bloco.
 *
 * O report é atômico: os 47 bytes viajam em TODO write, e o firmware obedece
 * aos bytes de motor mesmo com os bits de vibração desligados (medido na
 * bancada do Hefesto, canônica §2: "não há valor neutro para common[2]/[3]").
 * Um payload de gatilho com os motores em zero calaria a vibração que estiver
 * em curso. Por isso quem escreve guarda a sombra — o último valor de cada
 * campo — e todo payload a carrega inteira, ligando só os bits do bloco que
 * muda.
 *
 * O que a sombra NUNCA liga, e o contrato é o motivo:
 *   - FORJA_FX_RUMBLE / FORJA_FX_HAPTICS_SELECT: a vibração é do SDL
 *     (SDL_RumbleGamepad), e o HAPTICS_SELECT mata a háptica por áudio;
 *   - FORJA_FX_POWER_SAVE: o mudo do microfone é do botão e do driver;
 *   - o valid_flag2 (byte 38): lightbar e brilho são do SDL_SetGamepadLED.
 * ------------------------------------------------------------------------- */
typedef struct ForjaSombra {
  uint8_t motor_esq, motor_dir; /* na escala que o SDL mandou por último */
  uint8_t gatilho_dir[11];
  uint8_t gatilho_esq[11];
  uint8_t led_r, led_g, led_b;
  uint8_t leds_jogador; /* & 0x1F, 0x20 = sem fade */
  uint8_t led_mic;      /* 0 apagado · 1 aceso · 2 piscando · 3 piscando lento */
  uint8_t vol_fone;     /* 0x00-0x7F */
  uint8_t vol_alto_falante;
  uint8_t vol_mic;      /* 0x00-0x40 */
  uint8_t audio;        /* common[7]: rota nos bits 4-5 */
  uint8_t audio2;       /* common[37]: pré-amp nos bits 0-2 */
} ForjaSombra;

/* Base segura do common[7], medida no Hefesto: bit0 (microfone interno), bit2
 * (cancelamento de eco) e bit3 (de ruído). "bit0 zerado mata a captação". */
#define FORJA_AUDIO_BASE 0x0D
#define FORJA_ROTA_FONE 0         /* estéreo no fone */
#define FORJA_ROTA_FONE_E_FALANTE 2 /* L no fone, R no alto-falante */
#define FORJA_ROTA_FALANTE 3      /* R no alto-falante interno */
/* O volume que o driver da Sony escolhe para o alto-falante ("[0x3d..0x64]"),
 * e o pré-amp que ele liga junto (hid-playstation, borda do HP_DETECT). */
#define FORJA_VOL_FALANTE_PADRAO 0x64
#define FORJA_PREAMP_PADRAO 0x02

#define FORJA_BITS1_PROIBIDOS (FORJA_FX_RUMBLE | FORJA_FX_HAPTICS_SELECT)
#define FORJA_BITS2_PROIBIDOS (FORJA_FX_POWER_SAVE)

/* O LED de jogador canônico do jogador 0..4 (5 = todas), bit 0 = a lâmpada da
 * esquerda. As cinco figuras são palíndromos: não há lado a errar. */
uint8_t forja_leds_do_jogador(int indice);

void forja_sombra_zerar(ForjaSombra *s);

/* O payload que carrega a sombra inteira e liga só `bits1`/`bits2` — menos os
 * proibidos, que saem sempre desligados. */
void forja_fx_da_sombra(ForjaDs5Effect *fx, const ForjaSombra *s, uint8_t bits1, uint8_t bits2);

/* Os blocos, prontos: mexem na sombra e montam o payload daquele bloco só. */
void forja_fx_gatilho(ForjaDs5Effect *fx, ForjaSombra *s, int direito, ForjaTrigger t);
void forja_fx_gatilhos(ForjaDs5Effect *fx, ForjaSombra *s, ForjaTrigger l2, ForjaTrigger r2);
void forja_fx_led_mic(ForjaDs5Effect *fx, ForjaSombra *s, uint8_t modo);
void forja_fx_leds_jogador(ForjaDs5Effect *fx, ForjaSombra *s, uint8_t mascara, int instantaneo);
void forja_fx_alto_falante(ForjaDs5Effect *fx, ForjaSombra *s, uint8_t volume, uint8_t rota,
                           uint8_t preamp);
void forja_fx_volume_mic(ForjaDs5Effect *fx, ForjaSombra *s, uint8_t volume);

typedef struct ForjaScePadTriggerEffect {
  uint8_t trigger_mask;
  uint8_t padding[7];
  uint32_t mode_l2;
  uint32_t mode_r2;
  uint8_t param_l2[4];
  uint8_t param_r2[4];
} ForjaScePadTriggerEffect;

void forja_sce_pad_trigger(ForjaScePadTriggerEffect *out, ForjaTrigger l2,
                           ForjaTrigger r2);

#ifdef __cplusplus
}
#endif

#endif
