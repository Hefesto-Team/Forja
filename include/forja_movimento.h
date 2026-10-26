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
  double giro[3];
  double acel[3];
} ForjaImu;

int forja_imu_do_report(const uint8_t *buf, size_t n, ForjaImu *out);

#ifdef __cplusplus
}
#endif

#endif
