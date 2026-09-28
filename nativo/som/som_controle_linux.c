/* O som de cada controle, no Linux: o "pelo aparelho" pelo PipeWire.
 *
 * `LC_ALL=C pactl list sinks|sources` — o PipeWire responde pelo
 * pipewire-pulse — dá, de cada nó, a descrição (o nome que o SDL mostra) e o
 * `sysfs.path` da placa. Do caminho, sobe-se ao usb_device (origem_usb_de), o
 * mesmo pai de onde o controle tem o dele: se os dois batem, o nó mora no
 * aparelho do controle. É o caminho do forja-speak, e o mesmo pai de onde o
 * Wine tira o ContainerId de um endpoint (winepulse.drv, get_container_id). */
#if defined(__linux__)
#define _POSIX_C_SOURCE 200809L /* popen, no C11 estrito */
#endif
#include "som_controle.h"

#if defined(__linux__)

#include "forja.h"
#include "origem.h"
#include "pads.h"

#include <stdio.h>
#include <stdlib.h>

static char *ler_comando(const char *cmd) {
  FILE *p = popen(cmd, "r");
  if (!p)
    return NULL;
  size_t tam = 0, cap = 1 << 16;
  char *buf = malloc(cap);
  if (!buf) {
    pclose(p);
    return NULL;
  }
  size_t lidos;
  while ((lidos = fread(buf + tam, 1, cap - tam - 1, p)) > 0) {
    tam += lidos;
    if (cap - tam < 4096) {
      char *maior = realloc(buf, cap * 2);
      if (!maior)
        break;
      buf = maior;
      cap *= 2;
    }
  }
  buf[tam] = '\0';
  pclose(p);
  return buf;
}

void somc_plataforma_nos(SomControles *sc, char *rotulo, size_t tam) {
  char *saidas = ler_comando("LC_ALL=C pactl list sinks 2>/dev/null");
  char *entradas = ler_comando("LC_ALL=C pactl list sources 2>/dev/null");
  static NoSistema sis[SOM_MAX_NOS * 2];
  int n = achar_ler_pactl(saidas, false, sis, SOM_MAX_NOS);
  n += achar_ler_pactl(entradas, true, sis + n, SOM_MAX_NOS * 2 - n);
  free(saidas);
  free(entradas);
  if (n == 0) {
    snprintf(rotulo, tam, "sem pactl: só pelo nome");
    return;
  }
  achar_casar(sc->nos, sc->n, sis, n);
  int achados = 0;
  for (int i = 0; i < sc->n; i++) {
    int k = sc->nos[i].no_sistema;
    if (k < 0 || !sis[k].sysfs[0])
      continue;
    char caminho[1200];
    snprintf(caminho, sizeof(caminho), "%s%s", origem_raiz_sysfs(), sis[k].sysfs);
    if (origem_usb_de(caminho, sc->nos[i].usb, sizeof(sc->nos[i].usb)) == 0)
      achados++;
  }
  snprintf(rotulo, tam, "PipeWire (pactl): o sysfs.path da placa sobe ao USB do controle");
  (void)achados;
}

bool somc_plataforma_pad(Forja *a, int slot, char *usb, size_t tam_usb, char *container, size_t tam_c) {
  (void)container;
  (void)tam_c;
  Pad *p = pads_do_slot(a, slot);
  if (!p || !p->usb_pai[0])
    return false;
  SDL_strlcpy(usb, p->usb_pai, tam_usb);
  return true;
}

#endif
