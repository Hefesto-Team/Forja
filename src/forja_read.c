/* forja-read — giro e acelerômetro de UM DualSense, pelo report 0x01 (USB).
 *
 *   forja-read --player 2          o 3º DualSense da mesa (o mesmo do forja-send)
 *   forja-read /dev/hidraw5        um nó escolhido à mão
 *   forja-read --player 0 --uma    uma leitura só, e sai
 *
 * Imprime uma linha por report:
 *   giro 0.1 -0.3 0.0 graus/s | acel 0.012 -0.998 0.031 g
 *
 * RECUSA o rádio, como o forja-send: outro relatório, outro jogo. rc 3 com a
 * MESMA frase, antes de ler um byte (pelo barramento) ou no primeiro 0x31 que
 * chegar (quando o nó foi escolhido à mão). Um leitor que aceita 0x31 em
 * silêncio publica lixo — os offsets do 0x31 são outros.
 *
 * PROIBIDO aqui: socket IPC, uniq, MAC, escrever no aparelho. Só lê.
 * rc: 0 fim · 1 não abriu · 2 não há esse player · 3 relatório 0x31 · 64 uso.
 */
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
  /* 64 = o report USB inteiro. O hidraw entrega UM report por read(); do
   * 0x31 (78 bytes) chegam os 64 primeiros, e o id basta para recusar. */
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
