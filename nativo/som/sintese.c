/* Os sons sintetizados. Ver sintese.h. */
#include "sintese.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>

#define PI2 6.28318530717958647692f

static uint32_t g_lcg;
static float ruido(void) {
  g_lcg = g_lcg * 1664525u + 1013904223u;
  return ((g_lcg >> 8) & 0xFFFF) / 32767.5f - 1.0f;
}

static int alocar(Onda *o, float dur) {
  o->n = (int)(dur * SINT_TAXA);
  if (o->n < 1)
    o->n = 1;
  o->a = calloc((size_t)o->n, sizeof(float));
  return o->a ? 0 : -1;
}

static void normalizar(Onda *o, float alvo) {
  float p = onda_pico(o);
  if (p < 1e-6f)
    return;
  float k = alvo / p;
  for (int i = 0; i < o->n; i++)
    o->a[i] *= k;
}

/* as pontas sem clique: 3 ms de rampa */
static void rampas(Onda *o, float ini_s, float fim_s) {
  int ni = (int)(ini_s * SINT_TAXA), nf = (int)(fim_s * SINT_TAXA);
  for (int i = 0; i < ni && i < o->n; i++)
    o->a[i] *= (float)i / ni;
  for (int i = 0; i < nf && i < o->n; i++)
    o->a[o->n - 1 - i] *= (float)i / nf;
}

void onda_liberar(Onda *o) {
  free(o->a);
  o->a = NULL;
  o->n = 0;
}

float onda_pico(const Onda *o) {
  float p = 0;
  for (int i = 0; i < o->n; i++)
    if (fabsf(o->a[i]) > p)
      p = fabsf(o->a[i]);
  return p;
}

float onda_rms(const Onda *o) {
  double s = 0;
  for (int i = 0; i < o->n; i++)
    s += (double)o->a[i] * o->a[i];
  return o->n ? (float)sqrt(s / o->n) : 0;
}

float onda_emenda(const Onda *o) { return o->n > 1 ? fabsf(o->a[o->n - 1] - o->a[0]) : 0; }

int sint_bigorna(Onda *o, float freq, float dur, float brilho, uint32_t semente) {
  if (alocar(o, dur))
    return -1;
  g_lcg = semente * 2654435761u + 1;
  static const float razao[] = {1.0f, 2.76f, 5.40f, 8.93f, 13.34f, 18.64f};
  static const float amp[] = {1.0f, 0.62f, 0.45f, 0.30f, 0.18f, 0.10f};
  float fase[6];
  for (int k = 0; k < 6; k++)
    fase[k] = (ruido() + 1) * 3.14159f;
  for (int i = 0; i < o->n; i++) {
    float t = (float)i / SINT_TAXA;
    float s = 0;
    for (int k = 0; k < 6; k++) {
      float f = freq * razao[k] * (1 + 0.0015f * k);
      if (f > SINT_TAXA * 0.45f)
        continue;
      float dec = (2.2f + k * 2.8f) / (0.4f + brilho);
      float a = amp[k] * (k > 2 ? brilho : 1.0f);
      s += a * expf(-dec * t) * sinf(PI2 * f * t + fase[k]);
    }
    /* o golpe: 4 ms de ruído que abre o som */
    if (t < 0.004f)
      s += ruido() * (1 - t / 0.004f) * 0.9f * brilho;
    o->a[i] = s;
  }
  rampas(o, 0.0005f, 0.01f);
  normalizar(o, 0.9f);
  return 0;
}

int sint_martelada(Onda *o, float freq, uint32_t semente) {
  Onda b = {0};
  if (sint_bigorna(&b, freq, 0.9f, 1.0f, semente))
    return -1;
  if (alocar(o, 0.9f)) {
    onda_liberar(&b);
    return -1;
  }
  for (int i = 0; i < o->n; i++) {
    float t = (float)i / SINT_TAXA;
    float f = 70 + 90 * expf(-t * 30); /* o baque cai de tom */
    float baque = sinf(PI2 * f * t) * expf(-t * 14) * 0.9f;
    o->a[i] = baque + b.a[i] * 0.7f;
  }
  onda_liberar(&b);
  rampas(o, 0.0005f, 0.02f);
  normalizar(o, 0.92f);
  return 0;
}

int sint_blip(Onda *o, float freq, float dur) {
  if (alocar(o, dur))
    return -1;
  for (int i = 0; i < o->n; i++) {
    float t = (float)i / SINT_TAXA;
    float env = expf(-t * 18 / dur * 0.12f);
    o->a[i] = env * (sinf(PI2 * freq * t) + 0.25f * sinf(PI2 * freq * 2.01f * t) +
                     0.1f * sinf(PI2 * freq * 3.0f * t));
  }
  rampas(o, 0.002f, 0.01f);
  normalizar(o, 0.6f);
  return 0;
}

int sint_acorde(Onda *o, const float *freqs, int n, float espaco, float dur_nota) {
  float dur = espaco * (n - 1) + dur_nota;
  if (alocar(o, dur))
    return -1;
  for (int k = 0; k < n; k++) {
    int ini = (int)(k * espaco * SINT_TAXA);
    for (int i = ini; i < o->n; i++) {
      float t = (float)(i - ini) / SINT_TAXA;
      float env = expf(-t * 4.5f) * (t < 0.004f ? t / 0.004f : 1.0f);
      float f = freqs[k];
      o->a[i] += env * (sinf(PI2 * f * t) + 0.35f * sinf(PI2 * f * 2.0f * t) * expf(-t * 6) +
                        0.15f * sinf(PI2 * f * 3.01f * t) * expf(-t * 9));
    }
  }
  rampas(o, 0.001f, 0.03f);
  normalizar(o, 0.7f);
  return 0;
}

/* Faz um laço sem emenda: o fim se funde ao começo em `cruz_s`. */
static void fechar_laco(Onda *o, float cruz_s) {
  int nc = (int)(cruz_s * SINT_TAXA);
  if (nc * 2 >= o->n)
    return;
  int n = o->n - nc;
  for (int i = 0; i < nc; i++) {
    float t = (float)i / nc;
    o->a[i] = o->a[i] * t + o->a[n + i] * (1 - t);
  }
  o->n = n;
}

int sint_fogo(Onda *o, float dur, uint32_t semente) {
  float total = dur + 0.4f;
  if (alocar(o, total))
    return -1;
  g_lcg = semente * 747796405u + 7;
  float lp = 0, lp2 = 0;
  for (int i = 0; i < o->n; i++) {
    float r = ruido();
    lp += (r - lp) * 0.02f;   /* o rumor grave */
    lp2 += (lp - lp2) * 0.05f;
    o->a[i] = lp2 * 2.5f;
  }
  /* os estalos */
  int estalos = (int)(total * 14);
  for (int k = 0; k < estalos; k++) {
    int ini = (int)(((ruido() + 1) * 0.5f) * (o->n - 2000));
    float a = 0.15f + 0.85f * powf((ruido() + 1) * 0.5f, 3.0f);
    float dec = 400 + (ruido() + 1) * 900;
    float hp = 0, ant = 0;
    for (int i = 0; i < 1600 && ini + i < o->n; i++) {
      float t = (float)i / SINT_TAXA;
      float x = ruido();
      hp = 0.7f * (hp + x - ant); /* passa-alta: o estalo é seco */
      ant = x;
      o->a[ini + i] += hp * a * expf(-dec * t);
    }
  }
  fechar_laco(o, 0.4f);
  normalizar(o, 0.5f);
  return 0;
}

int sint_drone(Onda *o, float dur) {
  float total = dur + 1.0f;
  if (alocar(o, total))
    return -1;
  /* ré dórico, grave: ré, lá, ré, fá, com pares desafinados que batem devagar */
  static const float f[] = {73.42f, 110.0f, 146.83f, 174.61f, 220.0f};
  static const float a[] = {0.55f, 0.35f, 0.3f, 0.16f, 0.1f};
  for (int i = 0; i < o->n; i++) {
    float t = (float)i / SINT_TAXA;
    float s = 0;
    for (int k = 0; k < 5; k++) {
      float lfo = 0.75f + 0.25f * sinf(PI2 * (0.05f + 0.013f * k) * t + k);
      s += a[k] * lfo * (sinf(PI2 * f[k] * t) + 0.6f * sinf(PI2 * f[k] * 1.0031f * t + 1.3f));
      s += a[k] * 0.12f * sinf(PI2 * f[k] * 2.0f * t + 0.7f * k); /* um pouco de brilho */
    }
    o->a[i] = s;
  }
  fechar_laco(o, 1.0f);
  normalizar(o, 0.35f);
  return 0;
}

int sint_sopro(Onda *o, float dur, uint32_t semente) {
  if (alocar(o, dur))
    return -1;
  g_lcg = semente * 22695477u + 3;
  float bp1 = 0, bp2 = 0;
  for (int i = 0; i < o->n; i++) {
    float t = (float)i / SINT_TAXA;
    float env = sinf(3.14159f * t / dur);
    float x = ruido();
    bp1 += (x - bp1) * 0.12f;
    bp2 += (bp1 - bp2) * 0.12f;
    o->a[i] = (bp1 - bp2) * env * env;
  }
  normalizar(o, 0.5f);
  return 0;
}

int sint_tom(Onda *o, float freq, float dur, float rampa_s) {
  if (alocar(o, dur))
    return -1;
  for (int i = 0; i < o->n; i++)
    o->a[i] = 0.8f * sinf(PI2 * freq * (float)i / SINT_TAXA);
  rampas(o, rampa_s, rampa_s);
  return 0;
}

int sint_pulso(Onda *o, float freq, float dur, int batidas, float intervalo) {
  float total = intervalo * (batidas - 1) + dur;
  if (alocar(o, total))
    return -1;
  for (int b = 0; b < batidas; b++) {
    int ini = (int)(b * intervalo * SINT_TAXA);
    int n = (int)(dur * SINT_TAXA);
    for (int i = 0; i < n && ini + i < o->n; i++) {
      float t = (float)i / SINT_TAXA;
      float env = sinf(3.14159f * t / dur);
      o->a[ini + i] += env * sinf(PI2 * freq * t);
    }
  }
  normalizar(o, 0.95f);
  return 0;
}

int sint_textura(Onda *o, float dur, float aspereza, uint32_t semente) {
  if (alocar(o, dur))
    return -1;
  g_lcg = semente * 1103515245u + 12345;
  float lp = 0;
  float corte = 0.01f + 0.2f * aspereza;
  for (int i = 0; i < o->n; i++) {
    float t = (float)i / SINT_TAXA;
    lp += (ruido() - lp) * corte;
    float base = sinf(PI2 * 90 * t) * (1 - aspereza);
    o->a[i] = lp * (0.5f + aspereza) + base * 0.6f;
  }
  rampas(o, 0.02f, 0.05f);
  normalizar(o, 0.9f);
  return 0;
}

int sint_passo(Onda *o, int chao, uint32_t semente) {
  g_lcg = semente * 2654435761u + 7;
  float lp = 0;
  switch (chao) {
  case 0: { /* grama: um baque macio, grave e abafado */
    float dur = 0.26f;
    if (alocar(o, dur))
      return -1;
    for (int i = 0; i < o->n; i++) {
      float t = (float)i / SINT_TAXA;
      float env = sinf(3.14159f * t / dur);
      lp += (ruido() - lp) * 0.02f;
      o->a[i] = env * env * (0.7f * sinf(PI2 * 70 * t) + 2.5f * lp);
    }
    normalizar(o, 0.45f);
    break;
  }
  case 1: { /* cascalho: quatro estalos secos em fila */
    float dur = 0.3f;
    if (alocar(o, dur))
      return -1;
    for (int b = 0; b < 4; b++) {
      int ini = (int)((b * 0.07f + 0.004f * (ruido() + 1)) * SINT_TAXA);
      int n = (int)(0.03f * SINT_TAXA);
      for (int i = 0; i < n && ini + i < o->n; i++) {
        float t = (float)i / SINT_TAXA;
        float env = sinf(3.14159f * t / 0.03f);
        o->a[ini + i] += env * (0.6f * sinf(PI2 * 160 * t) + 0.6f * ruido());
      }
    }
    normalizar(o, 0.8f);
    break;
  }
  case 2: { /* metal: o golpe seco que fica ressoando */
    float dur = 0.55f;
    if (alocar(o, dur))
      return -1;
    for (int i = 0; i < o->n; i++) {
      float t = (float)i / SINT_TAXA;
      float env = (t < 0.005f ? t / 0.005f : 1.0f) * expf(-t / 0.16f);
      o->a[i] = env * (sinf(PI2 * 190 * t) + 0.6f * sinf(PI2 * 285 * t) + 0.35f * sinf(PI2 * 470 * t));
    }
    normalizar(o, 0.9f);
    break;
  }
  default: { /* água: duas ondas lentas, que empurram e voltam */
    float dur = 0.5f;
    if (alocar(o, dur))
      return -1;
    for (int b = 0; b < 2; b++) {
      int ini = (int)(b * 0.28f * SINT_TAXA);
      int n = (int)(0.18f * SINT_TAXA);
      for (int i = 0; i < n && ini + i < o->n; i++) {
        float t = (float)i / SINT_TAXA;
        float env = sinf(3.14159f * t / 0.18f);
        lp += (ruido() - lp) * 0.01f;
        o->a[ini + i] += env * env * (sinf(PI2 * 45 * t) + 3.0f * lp);
      }
    }
    normalizar(o, 0.6f);
    break;
  }
  }
  rampas(o, 0.002f, 0.01f);
  return 0;
}

int sint_grito(Onda *o, float dur, uint32_t semente) {
  if (alocar(o, dur))
    return -1;
  g_lcg = semente * 22695477u + 11;
  float fase = 0, bp1 = 0, bp2 = 0;
  for (int i = 0; i < o->n; i++) {
    float t = (float)i / SINT_TAXA, k = t / dur;
    /* sobe rasgando, e cai: 520 → 940 → 600 Hz, com um tremor de 7 Hz */
    float f = k < 0.25f ? 520 + 420 * (k / 0.25f) : 940 - 340 * ((k - 0.25f) / 0.75f);
    f *= 1.0f + 0.04f * sinf(PI2 * 7 * t);
    fase += f / SINT_TAXA;
    fase -= floorf(fase);
    float serra = 2 * fase - 1;
    float x = serra + 0.35f * ruido();
    bp1 += (x - bp1) * 0.35f; /* um filtro que deixa passar o meio: a garganta */
    bp2 += (bp1 - bp2) * 0.35f;
    float env = (k < 0.03f ? k / 0.03f : 1.0f) * (k > 0.8f ? (1 - k) / 0.2f : 1.0f);
    o->a[i] = (bp1 - 0.6f * bp2) * env;
  }
  normalizar(o, 0.95f);
  return 0;
}

/* ---------- a trilha: synthwave ----------
 *
 * Oito compassos em laço, na progressão que o gênero consagrou (i, VI, III,
 * VII em menor, dois compassos cada): o pad de serras desafinadas, o baixo em
 * colcheias, o arpejo de onda quadrada em semicolcheias com eco pontuado, e a
 * bateria de máquina — o bumbo que cai de tom, a caixa gorda com a cauda
 * cortada, o chimbal fechado. A energia decide quem toca: 0 é o salão (pad,
 * baixo em mínimas e o arpejo manso), 1 põe a bateria, 2 o bumbo em todo tempo.
 *
 * Tudo é somado com o índice em módulo do tamanho do laço: o que passa do fim
 * (a cauda do pad, o eco) volta no começo, e o laço não tem emenda. */

static float midi_hz(float m) { return 440.0f * powf(2.0f, (m - 69.0f) / 12.0f); }

static void somar(Onda *o, int i, float v) { o->a[((i % o->n) + o->n) % o->n] += v; }

static float serra(float fase) { return 2.0f * (fase - floorf(fase)) - 1.0f; }

static float quadrada(float fase, float largura) { return (fase - floorf(fase)) < largura ? 1.0f : -1.0f; }

/* uma nota de serra (ou quadrada) com envelope ADR e um passa-baixa de um polo */
static void nota(Onda *o, int ini, float hz, float dur, float ataque, float queda, float vol, float corte, int forma,
                 float desafina) {
  int n = (int)((dur + queda) * SINT_TAXA);
  float k = 1.0f - expf(-PI2 * corte / SINT_TAXA);
  float y = 0, fase_a = 0, fase_b = 0.37f;
  float ha = hz * powf(2.0f, desafina / 1200.0f), hb = hz * powf(2.0f, -desafina / 1200.0f);
  for (int i = 0; i < n; i++) {
    float t = (float)i / SINT_TAXA;
    float env = t < ataque ? t / ataque : (t < dur ? 1.0f : expf(-(t - dur) / (queda * 0.3f + 1e-4f)));
    fase_a += ha / SINT_TAXA;
    fase_b += hb / SINT_TAXA;
    float x = forma == 0 ? 0.5f * (serra(fase_a) + serra(fase_b)) : quadrada(fase_a, 0.3f);
    y += k * (x - y);
    somar(o, ini + i, y * env * vol);
  }
}

static void bumbo(Onda *o, int ini, float vol) {
  int n = (int)(0.32f * SINT_TAXA);
  float fase = 0;
  for (int i = 0; i < n; i++) {
    float t = (float)i / SINT_TAXA;
    float hz = 45.0f + 110.0f * expf(-t / 0.03f);
    fase += hz / SINT_TAXA;
    somar(o, ini + i, sinf(PI2 * fase) * expf(-t / 0.11f) * vol);
  }
}

static void caixa(Onda *o, int ini, float vol) {
  int n = (int)(0.34f * SINT_TAXA);
  float ant = 0, fase = 0;
  for (int i = 0; i < n; i++) {
    float t = (float)i / SINT_TAXA;
    float r = ruido();
    float agudo = r - ant; /* um passa-alta de pobre */
    ant = r;
    /* a cauda "gated" dos anos 80: cheia, e cortada de uma vez */
    float env = t < 0.26f ? expf(-t / 0.18f) : expf(-0.26f / 0.18f) * expf(-(t - 0.26f) / 0.01f);
    fase += 190.0f / SINT_TAXA;
    somar(o, ini + i, (0.75f * agudo + 0.35f * sinf(PI2 * fase) * expf(-t / 0.05f)) * env * vol);
  }
}

static void chimbal(Onda *o, int ini, float vol) {
  int n = (int)(0.05f * SINT_TAXA);
  float ant = 0;
  for (int i = 0; i < n; i++) {
    float r = ruido();
    somar(o, ini + i, (r - ant) * expf(-((float)i / SINT_TAXA) / 0.012f) * vol);
    ant = r;
  }
}

int sint_trilha(Onda *o, float tonica_midi, float bpm, int energia, uint32_t semente) {
  if (bpm < 60)
    bpm = 60;
  float tempo = 60.0f / bpm;
  int por_tempo = (int)(tempo * SINT_TAXA);
  int compassos = 8;
  o->n = por_tempo * 4 * compassos;
  o->a = calloc((size_t)o->n, sizeof(float));
  if (!o->a)
    return -1;
  g_lcg = semente * 2654435761u + 1u;
  /* i, VI, III, VII: a fundamental de cada acorde e se é menor */
  static const int raiz[4] = {0, -4, 3, -2};
  static const int menor[4] = {1, 0, 0, 0};
  float pad_vol = energia == 0 ? 0.16f : 0.12f;
  for (int c = 0; c < 4; c++) {
    int ini = c * 2 * 4 * por_tempo;
    float base = tonica_midi + raiz[c];
    int terca = menor[c] ? 3 : 4;
    int acorde[3] = {0, terca, 7};
    /* o pad: as três notas do acorde, dois compassos, uma oitava acima */
    for (int k = 0; k < 3; k++)
      nota(o, ini, midi_hz(base + 12 + acorde[k]), 8 * tempo, 0.5f, 1.2f, pad_vol, 1600.0f, 0, 9.0f);
    /* o baixo: colcheias (mínimas no salão), uma oitava abaixo */
    int passo_b = energia == 0 ? 4 : 1; /* em colcheias */
    for (int q = 0; q < 16; q += passo_b) {
      float oitava = (energia > 0 && q % 4 == 3) ? 12.0f : 0.0f; /* o salto de oitava do gênero */
      nota(o, ini + q * por_tempo / 2, midi_hz(base - 12 + oitava), (passo_b * tempo / 2) * 0.8f, 0.004f, 0.08f, 0.30f,
           energia == 0 ? 320.0f : 520.0f, 0, 4.0f);
    }
    /* o arpejo: semicolcheias subindo e descendo pelo acorde (colcheias no salão) */
    static const int desenho[8] = {0, 1, 2, 3, 2, 1, 0, 1};
    int passo_a = energia == 0 ? 2 : 1; /* em semicolcheias */
    for (int s = 0; s < 32; s += passo_a) {
      int grau = desenho[(s / passo_a) % 8];
      float m = base + 24 + (grau == 3 ? 12 : acorde[grau]);
      nota(o, ini + s * por_tempo / 4, midi_hz(m), tempo / 4 * 0.5f, 0.002f, 0.10f, energia == 0 ? 0.06f : 0.08f,
           3200.0f, 1, 0.0f);
    }
  }
  /* o eco do arpejo e do pad: colcheia pontuada, em laço */
  {
    int atraso = (int)(tempo * 0.75f * SINT_TAXA);
    float *seco = malloc(sizeof(float) * (size_t)o->n);
    if (seco) {
      memcpy(seco, o->a, sizeof(float) * (size_t)o->n);
      for (int volta = 1; volta <= 3; volta++) {
        float g = powf(0.32f, (float)volta);
        for (int i = 0; i < o->n; i++)
          o->a[(i + atraso * volta) % o->n] += seco[i] * g;
      }
      free(seco);
    }
  }
  /* a bateria, seca por cima do eco */
  if (energia > 0) {
    for (int b = 0; b < compassos * 4; b++) {
      int ini = b * por_tempo;
      if (energia >= 2 || b % 2 == 0)
        bumbo(o, ini, 0.55f);
      if (b % 2 == 1)
        caixa(o, ini, 0.32f);
      chimbal(o, ini + por_tempo / 2, 0.10f);
      if (energia >= 2)
        chimbal(o, ini, 0.06f);
    }
  }
  /* a cola: uma saturação macia, e o pico em 0,8 */
  for (int i = 0; i < o->n; i++)
    o->a[i] = tanhf(o->a[i] * 1.4f);
  normalizar(o, 0.8f);
  return 0;
}
