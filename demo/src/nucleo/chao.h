/* Os chãos dos Caminhos, e como reconhecê-los pelo que se sente.
 *
 * Cada passo tem uma assinatura no envelope (o nível ao longo do tempo), a
 * mesma que a mão sente: a grama é um baque macio, o cascalho são quatro
 * estalos, o metal é um golpe que ressoa, a água são duas ondas. É o que o
 * robô usa para "sentir" o chão pelos canais dos atuadores do controle dele —
 * nunca pelo que a sala sorteou. Lógica pura, provada contra a síntese. */
#ifndef DEMO_CHAO_H
#define DEMO_CHAO_H

#ifdef __cplusplus
extern "C" {
#endif

typedef enum Chao { CHAO_GRAMA = 0, CHAO_CASCALHO, CHAO_METAL, CHAO_AGUA, CHAO_TOTAL } Chao;

const char *chao_nome(Chao c);
/* O chão de um envelope (um nível por quadro de 1/60 s, desde antes do passo
 * até depois dele); -1 quando não há nada para sentir. */
int chao_pelo_envelope(const float *env, int n);

#ifdef __cplusplus
}
#endif

#endif
