/* A taxa do sensor. Ver taxa.h. */
#include "taxa.h"

#include <string.h>

void taxa_zerar(Taxa *t) { memset(t, 0, sizeof(*t)); }

void taxa_evento(Taxa *t, uint64_t host_ns, uint64_t sensor_ns) {
  if (t->total == 0)
    t->primeiro_host_ns = host_ns;
  int pos;
  if (t->n < TAXA_JANELA) {
    pos = (t->inicio + t->n) % TAXA_JANELA;
    t->n++;
  } else {
    pos = t->inicio;
    t->inicio = (t->inicio + 1) % TAXA_JANELA;
  }
  t->host_ns[pos] = host_ns;
  t->sensor_ns[pos] = sensor_ns;
  t->total++;
}

/* O índice do evento mais antigo que ainda cai na janela; -1 se nenhum. */
static int primeiro_na_janela(const Taxa *t, uint64_t agora_ns, double janela_s, int *quantos) {
  uint64_t janela_ns = (uint64_t)(janela_s * 1e9);
  uint64_t corte = agora_ns > janela_ns ? agora_ns - janela_ns : 0;
  int achados = 0, primeiro = -1;
  for (int k = t->n - 1; k >= 0; k--) {
    int i = (t->inicio + k) % TAXA_JANELA;
    if (t->host_ns[i] < corte)
      break;
    primeiro = i;
    achados++;
  }
  *quantos = achados;
  return primeiro;
}

static int ultimo(const Taxa *t) { return (t->inicio + t->n - 1) % TAXA_JANELA; }

double taxa_hz_host(const Taxa *t, uint64_t agora_ns, double janela_s) {
  int n = 0;
  int p = primeiro_na_janela(t, agora_ns, janela_s, &n);
  if (p < 0 || n < 2)
    return 0.0;
  uint64_t dt = t->host_ns[ultimo(t)] - t->host_ns[p];
  if (dt == 0)
    return 0.0;
  return (double)(n - 1) * 1e9 / (double)dt;
}

double taxa_hz_sensor(const Taxa *t, uint64_t agora_ns, double janela_s) {
  int n = 0;
  int p = primeiro_na_janela(t, agora_ns, janela_s, &n);
  if (p < 0 || n < 2)
    return 0.0;
  uint64_t a = t->sensor_ns[p], b = t->sensor_ns[ultimo(t)];
  if (b <= a)
    return 0.0;
  return (double)(n - 1) * 1e9 / (double)(b - a);
}
