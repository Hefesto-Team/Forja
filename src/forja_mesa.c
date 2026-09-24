/* FORJA — a mesa: os DualSense em hidraw, na mesma ordem para todo binário.
 * Ver include/forja_mesa.h. */
#define _XOPEN_SOURCE 700

#include "forja_mesa.h"
#include "forja_dualsense.h"

#include <dirent.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

const char *forja_sysfs(void) {
  const char *raiz = getenv("FORJA_SYSFS");
  return (raiz && raiz[0]) ? raiz : "/sys";
}

static int ler_uevent(const char *hidraw, ForjaPad *out) {
  char uevent[PATH_MAX];
  snprintf(uevent, sizeof(uevent), "%s/class/hidraw/%s/device/uevent", forja_sysfs(),
           hidraw);
  FILE *f = fopen(uevent, "r");
  if (!f)
    return 0;
  char line[256];
  int vid = 0, pid = 0, bus = 0;
  while (fgets(line, sizeof(line), f)) {
    if (strncmp(line, "HID_ID=", 7) != 0)
      continue;
    unsigned b = 0, v = 0, p = 0;
    if (sscanf(line + 7, "%x:%x:%x", &b, &v, &p) == 3) {
      bus = (int)b;
      vid = (int)v;
      pid = (int)p;
    }
  }
  fclose(f);
  if (vid != FORJA_DS5_VID)
    return 0;
  if (pid != FORJA_DS5_PID && pid != FORJA_DS5_EDGE_PID)
    return 0;
  snprintf(out->hidraw, sizeof(out->hidraw), "%s", hidraw);
  snprintf(out->path, sizeof(out->path), "/dev/%s", hidraw);
  out->bus = bus;
  out->pid = pid;
  return 1;
}

int forja_mesa_pads(ForjaPad *pads, int max) {
  char dir[PATH_MAX];
  snprintf(dir, sizeof(dir), "%s/class/hidraw", forja_sysfs());
  DIR *d = opendir(dir);
  if (!d)
    return 0;
  int n = 0;
  struct dirent *e;
  while ((e = readdir(d)) && n < max) {
    if (e->d_name[0] == '.')
      continue;
    ForjaPad p;
    if (ler_uevent(e->d_name, &p))
      pads[n++] = p;
  }
  closedir(d);
  return n;
}

static int tem(const char *pasta, const char *arquivo) {
  char caminho[PATH_MAX + 16];
  snprintf(caminho, sizeof(caminho), "%s/%s", pasta, arquivo);
  return access(caminho, R_OK) == 0;
}

int forja_usb_de(const char *caminho, char *out, size_t tam) {
  char atual[PATH_MAX];
  char raiz[PATH_MAX];
  if (!realpath(caminho, atual) || !realpath(forja_sysfs(), raiz))
    return -1;
  size_t n_raiz = strlen(raiz);
  for (;;) {
    if (tem(atual, "busnum") && tem(atual, "devnum")) {
      snprintf(out, tam, "%s", atual);
      return 0;
    }
    char *barra = strrchr(atual, '/');
    if (!barra || barra == atual)
      return -1;
    *barra = '\0';
    /* Nunca sobe além da raiz do sysfs: acima dela não há aparelho. */
    if (strlen(atual) <= n_raiz)
      return -1;
  }
}

int forja_usb_do_pad(const ForjaPad *pad, char *out, size_t tam) {
  /* Só o pad no USB tem aparelho de som próprio. Subir do nó de um pad no
   * rádio chegaria ao ADAPTADOR Bluetooth, que também é um usb_device — e o
   * alto-falante "achado" seria de outro aparelho. */
  if (pad->bus != FORJA_BUS_USB)
    return -1;
  char device[PATH_MAX];
  snprintf(device, sizeof(device), "%s/class/hidraw/%s/device", forja_sysfs(), pad->hidraw);
  return forja_usb_de(device, out, tam);
}
