#include "forja_dualsense.h"

/* Official Sony/Nielk1 packing: 10 zones, 3-bit force = (strength-1)&7.
 * Simple leftover modes 0x01/0x02/0x06 are NOT used. */

static void pack_zones(uint8_t out[11], uint8_t mode, uint16_t active,
                       uint32_t forces, uint8_t freq) {
  memset(out, 0, 11);
  out[0] = mode;
  out[1] = (uint8_t)(active & 0xff);
  out[2] = (uint8_t)((active >> 8) & 0xff);
  out[3] = (uint8_t)(forces & 0xff);
  out[4] = (uint8_t)((forces >> 8) & 0xff);
  out[5] = (uint8_t)((forces >> 16) & 0xff);
  out[6] = (uint8_t)((forces >> 24) & 0xff);
  out[9] = freq;
}

static uint8_t force3(uint8_t strength) {
  if (strength < 1)
    return 0;
  if (strength > 8)
    strength = 8;
  return (uint8_t)((strength - 1) & 0x07);
}

void forja_trigger_pack(uint8_t out[11], ForjaTrigger t) {
  memset(out, 0, 11);
  switch (t.mode) {
  case FORJA_TRIGGER_FEEDBACK: {
    uint8_t pos = t.a <= 9 ? t.a : 2;
    uint8_t str = t.b ? t.b : 6;
    if (str > 8)
      str = 8;
    if (str < 1) {
      out[0] = FORJA_HID_TRIGGER_OFF;
      return;
    }
    uint8_t fv = force3(str);
    uint16_t active = 0;
    uint32_t forces = 0;
    for (int i = pos; i < 10; i++) {
      active |= (uint16_t)(1u << i);
      forces |= (uint32_t)fv << (3 * i);
    }
    pack_zones(out, FORJA_HID_TRIGGER_FEEDBACK, active, forces, 0);
    break;
  }
  case FORJA_TRIGGER_WEAPON: {
    uint8_t start = t.a ? t.a : 2;
    uint8_t end = t.b ? t.b : 6;
    uint8_t str = t.c ? t.c : 8;
    if (start < 2)
      start = 2;
    if (start > 7)
      start = 7;
    if (end <= start)
      end = (uint8_t)(start + 1);
    if (end > 8)
      end = 8;
    if (str > 8)
      str = 8;
    if (str < 1) {
      out[0] = FORJA_HID_TRIGGER_OFF;
      return;
    }
    uint16_t active = (uint16_t)((1u << start) | (1u << end));
    uint32_t forces = (uint32_t)force3(str) << (3 * end);
    pack_zones(out, FORJA_HID_TRIGGER_WEAPON, active, forces, 0);
    break;
  }
  case FORJA_TRIGGER_VIBRATION: {
    uint8_t pos = t.a <= 9 ? t.a : 0;
    uint8_t amp = t.b ? t.b : 7;
    uint8_t freq = t.c ? t.c : 32;
    if (amp > 8)
      amp = 8;
    if (amp < 1) {
      out[0] = FORJA_HID_TRIGGER_OFF;
      return;
    }
    uint8_t fv = force3(amp);
    uint16_t active = 0;
    uint32_t forces = 0;
    for (int i = pos; i < 10; i++) {
      active |= (uint16_t)(1u << i);
      forces |= (uint32_t)fv << (3 * i);
    }
    pack_zones(out, FORJA_HID_TRIGGER_VIBRATION, active, forces, freq);
    break;
  }
  default:
    out[0] = FORJA_HID_TRIGGER_OFF;
    break;
  }
}

void forja_ds5_pack(ForjaDs5Effect *fx, const ForjaDs5Output *in) {
  memset(fx, 0, sizeof(*fx));
  int rumble = in->rumble_left || in->rumble_right;
  fx->enable1 = FORJA_FX_R2 | FORJA_FX_L2 | FORJA_FX_HEADPHONE_VOL |
                FORJA_FX_SPEAKER_VOL | FORJA_FX_MIC_VOL | FORJA_FX_AUDIO_CONTROL;
  if (rumble)
    fx->enable1 |= FORJA_FX_RUMBLE | FORJA_FX_HAPTICS_SELECT;
  fx->enable2 = FORJA_FX_MIC_LED | FORJA_FX_POWER_SAVE | FORJA_FX_LIGHTBAR |
                FORJA_FX_PLAYER_LED | FORJA_FX_MOTOR_POWER | FORJA_FX_PREAMP;
  fx->rumble_left = in->rumble_left;
  fx->rumble_right = in->rumble_right;
  forja_trigger_pack(fx->right_trigger, in->r2);
  forja_trigger_pack(fx->left_trigger, in->l2);
  fx->mic_led = in->mic_led;
  fx->headphone_vol = in->set_speaker
                          ? (in->speaker_vol > 0x7F ? 0x7F : in->speaker_vol)
                          : 0x50;
  fx->speaker_vol = in->set_speaker ? in->speaker_vol : 160;
  fx->mic_vol = 0x40;
  fx->audio_enable = FORJA_AUDIO_FORCE_INTERNAL_MIC | (FORJA_AUDIO_ROTA_SPEAKER << 4);
  fx->unknown1[5] = 0x02;
  fx->led_flags = FORJA_FX2_PLAYER_BRIGHT | FORJA_FX2_VIBRATION_V2;
  fx->led_anim = 0;
  fx->led_brightness = 0;
  fx->led_r = in->lightbar_r;
  fx->led_g = in->lightbar_g;
  fx->led_b = in->lightbar_b;
  if (in->player_led_on && in->player_index < 4) {
    fx->player_leds = (uint8_t)(FORJA_PLAYER_LED[in->player_index] | 0x20);
  }
}

void forja_ds5_usb_report(uint8_t report[FORJA_DS5_USB_REPORT_SIZE],
                         const ForjaDs5Output *in) {
  ForjaDs5Effect fx;
  forja_ds5_pack(&fx, in);
  memset(report, 0, FORJA_DS5_USB_REPORT_SIZE);
  report[0] = FORJA_DS5_USB_REPORT_ID;
  memcpy(report + 1, &fx, FORJA_DS5_FX_SIZE);
}

void forja_sce_pad_trigger(ForjaScePadTriggerEffect *out, ForjaTrigger l2,
                           ForjaTrigger r2) {
  memset(out, 0, sizeof(*out));
  out->trigger_mask = 0x01 | 0x02;
  out->mode_l2 = (uint32_t)l2.mode;
  out->mode_r2 = (uint32_t)r2.mode;
  out->param_l2[0] = l2.a;
  out->param_l2[1] = l2.b;
  out->param_l2[2] = l2.c;
  out->param_r2[0] = r2.a;
  out->param_r2[1] = r2.b;
  out->param_r2[2] = r2.c;
}
