/* O som de cada controle, onde não há como achar pelo aparelho: só pelo nome
 * (a lista do SDL) e pela pessoa que aponta. */
#include "som_controle.h"

#if !defined(__linux__) && !defined(_WIN32)

void somc_plataforma_nos(SomControles *sc, char *rotulo, size_t tam) {
  (void)sc;
  SDL_snprintf(rotulo, tam, "só pelo nome nesta plataforma");
}

bool somc_plataforma_pad(struct Forja *a, int slot, char *usb, size_t tam_usb, char *container, size_t tam_c) {
  (void)a;
  (void)slot;
  (void)usb;
  (void)tam_usb;
  (void)container;
  (void)tam_c;
  return false;
}

#endif
