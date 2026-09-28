/* A postura do controle: para onde ele está inclinado, a partir do giroscópio
 * e do acelerômetro — o que um jogo de mira por movimento faz.
 *
 * As convenções são as do SDL3 para gamepad (SDL_sensor.h): +X para a
 * direita, +Y para cima, +Z na direção de quem segura; o giroscópio em rad/s
 * pela regra da mão direita, o acelerômetro em m/s² com a gravidade para
 * CIMA (parado na mesa, Y ≈ +9,8). Então:
 *
 *   rolagem (roll)  = giro em Z; positivo ergue o lado direito
 *   arfagem (pitch) = giro em X; positivo ergue a borda de longe
 *   guinada (yaw)   = giro em Y; positivo vira para a esquerda
 *
 * Rolagem e arfagem vêm da fusão (o giro integrado, puxado devagar para o
 * ângulo da gravidade); a guinada é só o giro integrado (não há gravidade que
 * a corrija). O passo de tempo é o relógio do CONTROLE (sensor_timestamp),
 * não o do computador: o agendamento do host não entorta a conta.
 *
 * E o que o jogo usa para validar: o sinal do giro tem de concordar com o do
 * acelerômetro. Se um intermediário inverter um eixo do giroscópio, o giro
 * integrado anda para um lado e a gravidade para o outro — e a postura conta.
 */
#ifndef DEMO_POSTURA_H
#define DEMO_POSTURA_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define POSTURA_G 9.80665f

typedef struct Postura {
  float rolagem, arfagem; /* rad, fundidos */
  float guinada;          /* rad, só giro (deriva) */
  float acel[3];
  bool tem_acel;
  uint64_t ultimo_ns;     /* carimbo do controle no último giro */
  uint64_t ultimo_host_ns; /* e o do host */
  long amostras_giro, amostras_acel;

  /* a prova do sinal: o giro puro e a gravidade, janela a janela */
  float janela_giro[2];   /* rolagem, arfagem: só giro, desde o início da janela */
  float janela_acel0[2];  /* o ângulo da gravidade no início da janela */
  bool janela_base_ok;    /* a gravidade era confiável quando a janela abriu */
  float janela_t;         /* segundos acumulados na janela */
  int concorda[2], discorda[2];
} Postura;

void postura_zerar(Postura *p);
/* Uma amostra do giroscópio. `sensor_ns` é o carimbo do controle; quando não
 * anda (fonte que não o preenche), vale o `host_ns`. */
void postura_giro(Postura *p, const float g[3], uint64_t sensor_ns, uint64_t host_ns);
void postura_acel(Postura *p, const float a[3]);

/* Os ângulos que a gravidade dá sozinha (rad). */
float postura_rolagem_da_gravidade(const float a[3]);
float postura_arfagem_da_gravidade(const float a[3]);
/* |a| em g (1 = parado). */
float postura_g(const float a[3]);

/* O veredito do sinal num eixo (0 rolagem, 1 arfagem): 1 concorda, -1 invertido,
 * 0 sem movimento suficiente para dizer. */
int postura_sinal(const Postura *p, int eixo);
/* A mesma regra sobre contagens (as de uma sala só, por exemplo). */
int postura_sinal_contagem(int concorda, int discorda);

#ifdef __cplusplus
}
#endif

#endif
