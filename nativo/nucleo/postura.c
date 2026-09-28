/* A postura do controle. Ver postura.h. */
#include "postura.h"

#include <math.h>
#include <string.h>

#define TAU 0.6f     /* s: quão devagar a gravidade corrige o giro */
#define JANELA 0.30f /* s: a janela da prova do sinal */
#define MIN_MOV 0.07f /* rad (~4°): o mínimo, nos dois, para a janela contar */
#define BURACO 0.05f /* s: um buraco maior (pausa, reconexão) não vira giro */

void postura_zerar(Postura *p) { memset(p, 0, sizeof(*p)); }

float postura_g(const float a[3]) { return sqrtf(a[0] * a[0] + a[1] * a[1] + a[2] * a[2]) / POSTURA_G; }

float postura_rolagem_da_gravidade(const float a[3]) {
  return atan2f(a[0], sqrtf(a[1] * a[1] + a[2] * a[2]));
}

float postura_arfagem_da_gravidade(const float a[3]) {
  return atan2f(-a[2], sqrtf(a[0] * a[0] + a[1] * a[1]));
}

static bool gravidade_confiavel(const Postura *p) {
  float g = postura_g(p->acel);
  return p->tem_acel && g > 0.8f && g < 1.2f;
}

static void abrir_janela(Postura *p) {
  p->janela_giro[0] = p->janela_giro[1] = 0;
  p->janela_acel0[0] = postura_rolagem_da_gravidade(p->acel);
  p->janela_acel0[1] = postura_arfagem_da_gravidade(p->acel);
  p->janela_base_ok = gravidade_confiavel(p);
  p->janela_t = 0;
}

void postura_acel(Postura *p, const float a[3]) {
  bool primeira = !p->tem_acel;
  memcpy(p->acel, a, sizeof(p->acel));
  p->tem_acel = true;
  p->amostras_acel++;
  if (primeira && gravidade_confiavel(p)) {
    /* o controle começa onde a gravidade diz, não no zero */
    p->rolagem = postura_rolagem_da_gravidade(a);
    p->arfagem = postura_arfagem_da_gravidade(a);
    abrir_janela(p);
  }
}

void postura_giro(Postura *p, const float g[3], uint64_t sensor_ns, uint64_t host_ns) {
  /* o relógio do controle quando ele anda; o do host quando não */
  float dt = 0;
  if (sensor_ns) {
    if (p->ultimo_ns && sensor_ns > p->ultimo_ns)
      dt = (float)((double)(sensor_ns - p->ultimo_ns) / 1e9);
  } else if (host_ns && p->ultimo_host_ns && host_ns > p->ultimo_host_ns) {
    dt = (float)((double)(host_ns - p->ultimo_host_ns) / 1e9);
  }
  p->ultimo_ns = sensor_ns;
  p->ultimo_host_ns = host_ns;
  p->amostras_giro++;
  if (dt <= 0 || dt > BURACO)
    return;

  p->rolagem += g[2] * dt;
  p->arfagem += g[0] * dt;
  p->guinada += g[1] * dt;
  p->janela_giro[0] += g[2] * dt;
  p->janela_giro[1] += g[0] * dt;
  p->janela_t += dt;

  if (!p->tem_acel)
    return;
  bool confiavel = gravidade_confiavel(p);
  if (confiavel) {
    float k = dt / (TAU + dt);
    p->rolagem += (postura_rolagem_da_gravidade(p->acel) - p->rolagem) * k;
    p->arfagem += (postura_arfagem_da_gravidade(p->acel) - p->arfagem) * k;
  }
  if (p->janela_t < JANELA)
    return;
  if (confiavel && p->janela_base_ok) {
    float d_acel[2] = {postura_rolagem_da_gravidade(p->acel) - p->janela_acel0[0],
                       postura_arfagem_da_gravidade(p->acel) - p->janela_acel0[1]};
    for (int e = 0; e < 2; e++) {
      if (fabsf(p->janela_giro[e]) < MIN_MOV || fabsf(d_acel[e]) < MIN_MOV)
        continue;
      if ((p->janela_giro[e] > 0) == (d_acel[e] > 0))
        p->concorda[e]++;
      else
        p->discorda[e]++;
    }
  }
  abrir_janela(p);
}

int postura_sinal(const Postura *p, int eixo) {
  if (eixo < 0 || eixo > 1)
    return 0;
  return postura_sinal_contagem(p->concorda[eixo], p->discorda[eixo]);
}

int postura_sinal_contagem(int c, int d) {
  if (c + d < 3)
    return 0;
  if (c >= 2 * d)
    return 1;
  if (d >= 2 * c)
    return -1;
  return 0;
}
