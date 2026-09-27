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
  case SALA_CERCO:
    return &CENA_CERCO;
  case SALA_GALERIA:
    return &CENA_GALERIA;
  case SALA_CANTO:
    return &CENA_CANTO;
  case SALA_CAMINHOS:
    return &CENA_CAMINHOS;
  case SALA_CRIPTA:
    return &CENA_CRIPTA;
  case SALA_PROVA:
    return &CENA_PROVA;
  default:
    return NULL;
  }
}
