#ifndef FORJA_MESA_H
#define FORJA_MESA_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define FORJA_BUS_USB 3
#define FORJA_BUS_BT 5

typedef struct ForjaPad {
  char hidraw[256];
  char path[272];
  int bus;
  int pid;
} ForjaPad;

const char *forja_sysfs(void);

int forja_mesa_pads(ForjaPad *pads, int max);

int forja_usb_de(const char *caminho, char *out, size_t tam);

int forja_usb_do_pad(const ForjaPad *pad, char *out, size_t tam);

#ifdef __cplusplus
}
#endif

#endif
