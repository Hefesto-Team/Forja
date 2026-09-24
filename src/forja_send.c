/* Write USB DualSense report 0x02 to hidraw devices that look like USB DualSense.
 * Refuses Bluetooth (bus 0005): this game does not speak report 0x31.
 */
#include "forja_dualsense.h"
#include "forja_mesa.h"

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static void usage(void) {
  fputs("uso: forja-send --player N [--left L] [--right R]\n", stderr);
  fputs("              [--r2|--l2 off|feedback|weapon|vibration]\n", stderr);
  fputs("              [--lightbar R G B] [--mic 0|1|2] [--speaker 0-255] [--quiet]\n",
        stderr);
  fputs("     forja-send --list\n", stderr);
}

static ForjaTriggerMode parse_mode(const char *s) {
  if (!s)
    return FORJA_TRIGGER_OFF;
  if (!strcmp(s, "feedback"))
    return FORJA_TRIGGER_FEEDBACK;
  if (!strcmp(s, "weapon"))
    return FORJA_TRIGGER_WEAPON;
  if (!strcmp(s, "vibration"))
    return FORJA_TRIGGER_VIBRATION;
  return FORJA_TRIGGER_OFF;
}

static const uint8_t DEFAULT_LB[4][3] = {
    {91, 141, 239},
    {232, 93, 93},
    {76, 175, 122},
    {232, 137, 181},
};

int main(int argc, char **argv) {
  int list_only = 0;
  int quiet = 0;
  int player = 0;
  int left = 0, right = 0;
  const char *r2 = "off";
  const char *l2 = "off";
  int lr = -1, lg = -1, lb = -1;
  int mic = 0;
  int speaker = -1;
  for (int i = 1; i < argc; i++) {
    if (!strcmp(argv[i], "--list"))
      list_only = 1;
    else if (!strcmp(argv[i], "--quiet"))
      quiet = 1;
    else if (!strcmp(argv[i], "--player") && i + 1 < argc)
      player = atoi(argv[++i]);
    else if (!strcmp(argv[i], "--left") && i + 1 < argc)
      left = atoi(argv[++i]);
    else if (!strcmp(argv[i], "--right") && i + 1 < argc)
      right = atoi(argv[++i]);
    else if (!strcmp(argv[i], "--r2") && i + 1 < argc)
      r2 = argv[++i];
    else if (!strcmp(argv[i], "--l2") && i + 1 < argc)
      l2 = argv[++i];
    else if (!strcmp(argv[i], "--mic") && i + 1 < argc)
      mic = atoi(argv[++i]);
    else if (!strcmp(argv[i], "--speaker") && i + 1 < argc)
      speaker = atoi(argv[++i]);
    else if (!strcmp(argv[i], "--lightbar") && i + 3 < argc) {
      lr = atoi(argv[++i]);
      lg = atoi(argv[++i]);
      lb = atoi(argv[++i]);
    } else {
      usage();
      return 2;
    }
  }

  /* The table comes from forja_mesa: forja-speak and forja-read read the SAME
   * list, so "player N" is the same DualSense in the three of them. */
  ForjaPad pads[8];
  int n = forja_mesa_pads(pads, 8);
  if (list_only) {
    for (int i = 0; i < n; i++) {
      const char *bus = pads[i].bus == 3 ? "usb" : pads[i].bus == 5 ? "bluetooth" : "outro";
      printf("player-candidato %d  %s  %s  pid=%04x\n", i, pads[i].path, bus,
             pads[i].pid);
      if (pads[i].bus == 5)
        puts("  recusa: este jogo não fala o relatório 0x31. ligue o DualSense no cabo, ou um DualSense virtual USB.");
    }
    if (!n)
      puts("nenhum DualSense (054c:0ce6 / 0df2) em hidraw");
    return 0;
  }

  if (player < 0 || player >= n) {
    if (!quiet)
      fprintf(stderr, "player index %d fora da mesa (%d DualSense)\n", player, n);
    return 1;
  }
  if (pads[player].bus == 5) {
    fputs("recusa: este DualSense está em Bluetooth. este jogo só envia USB 0x02.\n",
          stderr);
    return 1;
  }

  if (player < 0)
    player = 0;
  if (player > 3)
    player = 3;

  ForjaDs5Output out = {0};
  out.rumble_left = (uint8_t)left;
  out.rumble_right = (uint8_t)right;
  out.player_index = (uint8_t)player;
  out.player_led_on = 1;
  if (lr >= 0) {
    out.lightbar_r = (uint8_t)lr;
    out.lightbar_g = (uint8_t)lg;
    out.lightbar_b = (uint8_t)lb;
  } else {
    out.lightbar_r = DEFAULT_LB[player][0];
    out.lightbar_g = DEFAULT_LB[player][1];
    out.lightbar_b = DEFAULT_LB[player][2];
  }
  out.r2.mode = parse_mode(r2);
  out.l2.mode = parse_mode(l2);
  out.mic_led = (uint8_t)mic;
  if (speaker >= 0) {
    out.set_speaker = 1;
    out.speaker_vol = (uint8_t)speaker;
  }

  uint8_t report[FORJA_DS5_USB_REPORT_SIZE];
  forja_ds5_usb_report(report, &out);

  int fd = open(pads[player].path, O_RDWR | O_NONBLOCK);
  if (fd < 0) {
    if (!quiet)
      perror(pads[player].path);
    return 1;
  }
  ssize_t w = write(fd, report, FORJA_DS5_USB_REPORT_SIZE);
  close(fd);
  if (w < 0) {
    if (!quiet)
      perror("write");
    return 1;
  }
  if (!quiet)
    printf("enviado USB 0x02  %s  player %d  rumble L=%d R=%d  r2=%s l2=%s  bytes=%zd\n",
           pads[player].path, player, left, right, r2, l2, w);
  return 0;
}
