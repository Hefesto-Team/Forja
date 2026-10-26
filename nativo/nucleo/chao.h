#ifndef DEMO_CHAO_H
#define DEMO_CHAO_H

#ifdef __cplusplus
extern "C" {
#endif

typedef enum Chao { CHAO_GRAMA = 0, CHAO_CASCALHO, CHAO_METAL, CHAO_AGUA, CHAO_TOTAL } Chao;

const char *chao_nome(Chao c);
int chao_pelo_envelope(const float *env, int n);

#ifdef __cplusplus
}
#endif

#endif
