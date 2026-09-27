/* As salas do hub (ADR-002). Cada sala é uma cena; as que ainda não existem
 * nesta versão devolvem NULL, e a porta delas fica fechada no salão. */
#ifndef DEMO_SALAS_H
#define DEMO_SALAS_H

#include "../app.h"

const Cena *salas_cena(int sala);

extern const Cena CENA_CENTELHA;
extern const Cena CENA_VIGA;
extern const Cena CENA_MOLDE;
extern const Cena CENA_CERCO;
extern const Cena CENA_GALERIA;

#endif
