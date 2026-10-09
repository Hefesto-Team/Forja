/* O relógio da sessão: segundos desde o começo, o mesmo para o registro, a
 * linha do tempo e o relatório. É sempre o relógio de parede (monotônico), para
 * que as duas pontas do cruzamento com o Hefesto falem do mesmo tempo; só com
 * --acelerado (e controles simulados) ele passa a ser o tempo do jogo — o que
 * o robô viveu —, e a linha do tempo de uma sessão acelerada fica igual à de
 * uma em tempo real com a mesma semente. */
#ifndef DEMO_RELOGIO_H
#define DEMO_RELOGIO_H

#include <SDL3/SDL.h>

void relogio_iniciar(Uint64 inicio_ns);
/* Passa a contar pelo tempo do jogo (`t_jogo` em segundos, de quem o dono). */
void relogio_do_jogo(const float *t_jogo);
double relogio_agora(void);

#endif
