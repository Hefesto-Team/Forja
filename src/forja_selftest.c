#include "forja_dualsense.h"

#include <stdio.h>
#include <stdlib.h>

static int fails;

static void expect(int cond, const char *msg) {
  if (!cond) {
    fprintf(stderr, "FAIL %s\n", msg);
    fails++;
  }
}

int main(void) {
  expect(sizeof(ForjaDs5Effect) == 47, "effect is 47 bytes");

  ForjaDs5Output in = {0};
  in.rumble_left = 240;
  in.rumble_right = 0;
  in.player_index = 2;
  in.player_led_on = 1;
  in.lightbar_r = 0;
  in.lightbar_g = 200;
  in.lightbar_b = 80;
  in.r2.mode = FORJA_TRIGGER_VIBRATION;
  in.r2.a = 0;
  in.r2.b = 7;
  in.r2.c = 32;
  in.l2.mode = FORJA_TRIGGER_OFF;
  in.mic_led = 0;

  uint8_t report[FORJA_DS5_USB_REPORT_SIZE];
  forja_ds5_usb_report(report, &in);

  expect(report[0] == 0x02, "USB report id 0x02");
  expect(report[0] != 0x31, "never Bluetooth 0x31");
  expect(report[1] & FORJA_FX_RUMBLE, "rumble enable");
  expect(report[1] & FORJA_FX_R2, "R2 enable");
  expect(report[4] == 240, "left motor 240 at usb[4]");
  expect(report[3] == 0, "right motor silent");
  expect((report[44] & 0x1F) == 0x15, "P3 player LED 0x15");
  expect(report[11] == FORJA_HID_TRIGGER_VIBRATION, "R2 official Vibration 0x26");
  expect(report[11] != 0x06, "not simple leftover 0x06");
  expect(report[22] == FORJA_HID_TRIGGER_OFF, "L2 Off 0x05");
  expect(report[45] == 0, "lightbar R common[44]");
  expect(report[46] == 200, "lightbar G common[45]");
  expect(report[8] == (FORJA_AUDIO_FORCE_INTERNAL_MIC | (FORJA_AUDIO_ROTA_SPEAKER << 4)),
         "audio rota speaker + FORCE_INTERNAL_MIC");
  expect(report[38] == 0x02, "preamp +6 dB common[37]");
  expect(report[42] == 0, "não manda LIGHT_OUT em loop");
  expect(report[7] == 0x40, "mic volume teto 0x40");

  ForjaTrigger fb = {FORJA_TRIGGER_FEEDBACK, 3, 8, 0};
  uint8_t blk[11];
  forja_trigger_pack(blk, fb);
  expect(blk[0] == FORJA_HID_TRIGGER_FEEDBACK, "Feedback 0x21");
  expect(blk[1] != 0, "Feedback active zones");

  ForjaTrigger wp = {FORJA_TRIGGER_WEAPON, 2, 6, 8};
  forja_trigger_pack(blk, wp);
  expect(blk[0] == FORJA_HID_TRIGGER_WEAPON, "Weapon 0x25");

  ForjaDs5Output quiet = {0};
  quiet.player_index = 0;
  quiet.player_led_on = 1;
  uint8_t r0[FORJA_DS5_USB_REPORT_SIZE];
  forja_ds5_usb_report(r0, &quiet);
  expect(r0[4] == 0, "P1 pack has no left rumble");
  expect((r0[44] & 0x1F) == 0x04, "P1 LED 0x04");

  ForjaScePadTriggerEffect sce;
  ForjaTrigger l2 = {FORJA_TRIGGER_FEEDBACK, 2, 6, 0};
  ForjaTrigger r2 = {FORJA_TRIGGER_WEAPON, 2, 6, 8};
  forja_sce_pad_trigger(&sce, l2, r2);
  expect(sce.trigger_mask == 0x03, "sce mask L2|R2");
  expect(sce.mode_l2 == FORJA_TRIGGER_FEEDBACK, "sce L2 Feedback");
  expect(sce.mode_r2 == FORJA_TRIGGER_WEAPON, "sce R2 Weapon");

  if (fails) {
    fprintf(stderr, "%d falha(s)\n", fails);
    return 1;
  }
  puts("forja_dualsense selftest ok — USB 0x02, Feedback 0x21 Weapon 0x25 Vibration 0x26, P3 motor L");
  return 0;
}
