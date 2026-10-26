#ifndef DEMO_TAXA_H
#define DEMO_TAXA_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define TAXA_JANELA 1024

typedef struct Taxa {
  uint64_t host_ns[TAXA_JANELA];
  uint64_t sensor_ns[TAXA_JANELA];
  int inicio, n;
  uint64_t total;
  uint64_t primeiro_host_ns;
} Taxa;

void taxa_zerar(Taxa *t);
void taxa_evento(Taxa *t, uint64_t host_ns, uint64_t sensor_ns);

double taxa_hz_host(const Taxa *t, uint64_t agora_ns, double janela_s);

double taxa_hz_sensor(const Taxa *t, uint64_t agora_ns, double janela_s);

#ifdef __cplusplus
}
#endif

#endif
