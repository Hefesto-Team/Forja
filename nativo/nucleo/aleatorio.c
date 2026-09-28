/* O sorteio: xorshift64*, pequeno e reprodutível. Ver aleatorio.h. */
#include "aleatorio.h"

void sorteio_semear(Sorteio *s, uint64_t semente) {
  /* splitmix64 espalha a semente: 1, 2 e 3 viram estados sem parentesco. */
  uint64_t z = semente + 0x9E3779B97F4A7C15ull;
  z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ull;
  z = (z ^ (z >> 27)) * 0x94D049BB133111EBull;
  z ^= z >> 31;
  s->estado = z ? z : 0x2545F4914F6CDD1Dull;
}

uint32_t sorteio_u32(Sorteio *s) {
  uint64_t x = s->estado;
  x ^= x >> 12;
  x ^= x << 25;
  x ^= x >> 27;
  s->estado = x;
  return (uint32_t)((x * 0x2545F4914F6CDD1Dull) >> 32);
}

int sorteio_entre(Sorteio *s, int a, int b) {
  if (b <= a)
    return a;
  uint32_t faixa = (uint32_t)(b - a) + 1u;
  return a + (int)(sorteio_u32(s) % faixa);
}

float sorteio_real(Sorteio *s) { return (float)(sorteio_u32(s) >> 8) / 16777216.0f; }

void sorteio_embaralhar(Sorteio *s, int *v, int n) {
  for (int i = n - 1; i > 0; i--) {
    int j = sorteio_entre(s, 0, i);
    int t = v[i];
    v[i] = v[j];
    v[j] = t;
  }
}
