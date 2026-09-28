/* O relógio da sessão: segundos desde o começo, o mesmo para o registro, a
 * linha do tempo e o relatório. No jogo normal é o relógio de parede; com
 * --acelerado (só com controles simulados), é o tempo do jogo — o que o robô
 * viveu —, e a linha do tempo de uma sessão acelerada fica igual à de uma em
 * tempo real com a mesma semente. */
#ifndef DEMO_RELOGIO_H
#define DEMO_RELOGIO_H

#include <SDL3/SDL.h>

void relogio_iniciar(Uint64 inicio_ns);
/* Passa a contar pelo tempo do jogo (`t_jogo` em segundos, de quem o dono). */
void relogio_do_jogo(const float *t_jogo);
double relogio_agora(void);

#endif
