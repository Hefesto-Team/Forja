/* FORJA — o movimento do DualSense, lido do report 0x01 de ENTRADA (USB).
 *
 * É o que a SDL e a libScePad leem. Offsets dentro do CORPO (buf[1..]), como o
 * hid-playstation os publica (struct dualsense_input_report):
 *   gyro  x,y,z : corpo[15..20]  int16 LE, 1024 LSB por grau/s (x=pitch, y=yaw, z=roll)
 *   accel x,y,z : corpo[21..26]  int16 LE, 8192 LSB por g
 * Valores CRUS, sem a calibração do aparelho: parado na mesa, o acelerômetro
 * marca ~1 g num eixo e o giro fica perto de zero — é a mordida.
 *
 * O relatório Bluetooth 0x31 tem outros offsets. Este jogo não o fala: quem o
 * recebe recusa, com a mesma frase do forja-send.
 */
#ifndef FORJA_MOVIMENTO_H
#define FORJA_MOVIMENTO_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define FORJA_GIRO_LSB_POR_GRAU_S 1024.0
#define FORJA_ACEL_LSB_POR_G 8192.0
#define FORJA_RECUSA_0x31                                                                   \
  "este jogo não fala o relatório 0x31. ligue o DualSense no cabo, ou um DualSense virtual " \
  "USB."

typedef struct ForjaImu {
  double giro[3]; /* graus/s: pitch, yaw, roll */
  double acel[3]; /* g */
} ForjaImu;

/* 0 = leu o movimento; 3 = é o relatório 0x31 (recuse); 1 = outro relatório
 * ou curto demais (pule). */
int forja_imu_do_report(const uint8_t *buf, size_t n, ForjaImu *out);

#ifdef __cplusplus
}
#endif

#endif
