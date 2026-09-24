/* FORJA — o movimento do report 0x01. Ver include/forja_movimento.h. */
#include "forja_movimento.h"

#define CORPO_GIRO 15
#define CORPO_ACEL 21
/* report id + corpo até o fim do acelerômetro (corpo[26]) */
#define MINIMO (1 + CORPO_ACEL + 6)

static int16_t le16(const uint8_t *p) { return (int16_t)(p[0] | (p[1] << 8)); }

int forja_imu_do_report(const uint8_t *buf, size_t n, ForjaImu *out) {
  if (n < 1)
    return 1;
  if (buf[0] == 0x31)
    return 3;
  if (buf[0] != 0x01 || n < MINIMO)
    return 1;
  const uint8_t *corpo = buf + 1;
  for (int i = 0; i < 3; i++) {
    out->giro[i] = le16(corpo + CORPO_GIRO + 2 * i) / FORJA_GIRO_LSB_POR_GRAU_S;
    out->acel[i] = le16(corpo + CORPO_ACEL + 2 * i) / FORJA_ACEL_LSB_POR_G;
  }
  return 0;
}
