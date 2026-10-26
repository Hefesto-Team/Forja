#define _XOPEN_SOURCE 700

#include "forja_mesa.h"
#include "forja_movimento.h"

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char **argv) {
  const char *caminho = NULL;
  int player = -1, uma = 0;
  for (int i = 1; i < argc; i++) {
    if (!strcmp(argv[i], "--player") && i + 1 < argc)
      player = atoi(argv[++i]);
    else if (!strcmp(argv[i], "--uma"))
      uma = 1;
    else if (argv[i][0] != '-' && !caminho)
      caminho = argv[i];
    else {
      fputs("uso: forja-read (--player N | /dev/hidrawX) [--uma]\n", stderr);
      return 64;
    }
  }
  ForjaPad pads[8];
  if (player >= 0) {
    int n = forja_mesa_pads(pads, 8);
    if (player >= n) {
      fprintf(stderr, "player index %d fora da mesa (%d DualSense)\n", player, n);
      return 2;
    }
    if (pads[player].bus == FORJA_BUS_BT) {
      fprintf(stderr, "%s\n", FORJA_RECUSA_0x31);
      return 3;
    }
    caminho = pads[player].path;
  }
  if (!caminho) {
    fputs("uso: forja-read (--player N | /dev/hidrawX) [--uma]\n", stderr);
    return 64;
  }
  int fd = open(caminho, O_RDONLY);
  if (fd < 0) {
    perror(caminho);
    return 1;
  }
  uint8_t buf[64];
  int rc = 0;
  for (;;) {
    ssize_t n = read(fd, buf, sizeof(buf));
    if (n <= 0)
      break;
    ForjaImu imu;
    int r = forja_imu_do_report(buf, (size_t)n, &imu);
    if (r == 3) {
      fprintf(stderr, "%s\n", FORJA_RECUSA_0x31);
      rc = 3;
      break;
    }
    if (r != 0)
      continue;
    printf("giro %.1f %.1f %.1f graus/s | acel %.3f %.3f %.3f g\n", imu.giro[0], imu.giro[1],
           imu.giro[2], imu.acel[0], imu.acel[1], imu.acel[2]);
    fflush(stdout);
    if (uma)
      break;
  }
  close(fd);
  return rc;
}
