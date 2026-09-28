/* A taxa do sensor, medida — e não a declarada.
 *
 * O SDL declara a taxa do giroscópio por TABELA (SDL_hidapi_ps5.c): 250 Hz para
 * o DualSense no cabo, 1000 Hz para o rádio e para o Edge no cabo. O Hefesto
 * mediu o aparelho (cabo: 250,0 Hz exatos; rádio: em rajadas, nunca 1000) e
 * deixou em aberto o outro lado: o que um JOGO recebe do vpad Edge. Esta
 * régua é a resposta, controle por controle, com duas medidas lado a lado:
 *
 *   - relógio do host: eventos por segundo de parede;
 *   - relógio do controle: eventos pelo `sensor_timestamp` que o SDL entrega
 *     (o carimbo do próprio aparelho, que não depende do agendamento do host).
 */
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

/* Eventos por segundo nos últimos `janela_s` segundos de host, pelo relógio do
 * host. 0 quando há menos de dois eventos na janela. */
double taxa_hz_host(const Taxa *t, uint64_t agora_ns, double janela_s);

/* A mesma janela, pelo relógio do controle (diferença de sensor_timestamp).
 * 0 quando o carimbo não anda (fonte que não o preenche). */
double taxa_hz_sensor(const Taxa *t, uint64_t agora_ns, double janela_s);

#ifdef __cplusplus
}
#endif

#endif
