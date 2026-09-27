/* experimental/ — a bancada dos experimentos (ver experimental/README.md).
 *
 * Cada experimento é uma pergunta que o jogo ainda não sabe responder com
 * certeza, medida no aparelho e gravada inteira — inclusive o que falhou e o
 * que não deu para medir. Abre com `--experimento CHAVE`: a mesa de sempre
 * (cada um aperta ✕), e depois o experimento no lugar do salão. */
#ifndef FORJA_EXPERIMENTOS_H
#define FORJA_EXPERIMENTOS_H

#include "../../demo/src/app.h"

extern const Cena CENA_EXPERIMENTO;

/* O índice do experimento pela chave (laco, quatro-mics, eco, gatilho-cru,
 * haptica-nomeada); -1 se não existe. */
int experimento_por_chave(const char *chave);
/* "laco, quatro-mics, ..." — para a mensagem de uso. */
const char *experimentos_chaves(void);

#endif
