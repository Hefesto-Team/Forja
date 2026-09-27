/* O registro das salas. Ver salas.h. */
#include "salas.h"

const Cena *salas_cena(int sala) {
  switch (sala) {
  case SALA_CENTELHA:
    return &CENA_CENTELHA;
  case SALA_VIGA:
    return &CENA_VIGA;
  case SALA_MOLDE:
    return &CENA_MOLDE;
  default:
    return NULL;
  }
}
