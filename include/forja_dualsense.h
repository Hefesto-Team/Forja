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
