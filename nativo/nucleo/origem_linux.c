/* A coleta dos fatos de origem no sysfs (Linux). Ver origem.h.
 *
 * Lê só o que precisa: HID_ID, HID_NAME e HID_PHYS do uevent do hidraw, ou
 * name/phys/id do evdev. A linha HID_UNIQ nunca é lida — é o endereço do
 * aparelho, e o contrato o proíbe. */
#if defined(__linux__)
#define _XOPEN_SOURCE 700
#endif

#include "origem.h"

#include "mascara.h"

#include <stdio.h>
#include <string.h>

#if defined(__linux__)
#include <dirent.h>
#include <limits.h>
#include <stdlib.h>
#include <unistd.h>

static void sem_fim_de_linha(char *s) {
  size_t n = strlen(s);
  while (n && (s[n - 1] == '\n' || s[n - 1] == '\r'))
    s[--n] = '\0';
}

static int ler_linha(const char *caminho, char *out, size_t tam) {
  FILE *arq = fopen(caminho, "r");
  if (!arq)
    return 0;
  int ok = fgets(out, (int)tam, arq) != NULL;
  fclose(arq);
  if (ok)
    sem_fim_de_linha(out);
  return ok;
}

static unsigned ler_hex(const char *caminho) {
  char linha[64];
  if (!ler_linha(caminho, linha, sizeof(linha)))
    return 0;
  return (unsigned)strtoul(linha, NULL, 16);
}

/* O realpath num buffer menor que PATH_MAX: o realpath pede um de PATH_MAX (e
 * o _FORTIFY_SOURCE aborta quando não é), então ele devolve o dele e a cópia
 * cabe no nosso. */
static void caminho_real(const char *de, char *out, size_t tam) {
  char *r = realpath(de, NULL);
  if (r && strlen(r) < tam)
    snprintf(out, tam, "%s", r);
  else
    out[0] = '\0';
  free(r);
}

static int tem(const char *pasta, const char *arquivo) {
  char caminho[PATH_MAX + 32];
  snprintf(caminho, sizeof(caminho), "%s/%s", pasta, arquivo);
  return access(caminho, R_OK) == 0;
}

int origem_usb_de(const char *caminho, char *out, size_t tam) {
  char atual[PATH_MAX];
  char raiz[PATH_MAX];
  if (!realpath(caminho, atual) || !realpath(origem_raiz_sysfs(), raiz))
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
    if (strlen(atual) <= n_raiz)
      return -1; /* acima da raiz do sysfs não há aparelho */
  }
}

static const char *base(const char *caminho) {
  const char *b = strrchr(caminho, '/');
  return b ? b + 1 : caminho;
}

static int fatos_hidraw(const char *nome, OrigemFatos *f) {
  char dispositivo[PATH_MAX];
  snprintf(dispositivo, sizeof(dispositivo), "%s/class/hidraw/%s/device", origem_raiz_sysfs(), nome);
  char uevent[PATH_MAX + 16];
  snprintf(uevent, sizeof(uevent), "%s/uevent", dispositivo);
  FILE *arq = fopen(uevent, "r");
  if (!arq)
    return 0;
  char linha[512];
  while (fgets(linha, sizeof(linha), arq)) {
    sem_fim_de_linha(linha);
    if (strncmp(linha, "HID_ID=", 7) == 0) {
      unsigned b = 0, v = 0, p = 0;
      if (sscanf(linha + 7, "%x:%x:%x", &b, &v, &p) == 3) {
        f->bus = (int)b;
        f->vid = v;
        f->pid = p;
      }
    } else if (strncmp(linha, "HID_NAME=", 9) == 0) {
      snprintf(f->nome_sistema, sizeof(f->nome_sistema), "%s", linha + 9);
    } else if (strncmp(linha, "HID_PHYS=", 9) == 0) {
      mascara_mac_copia(linha + 9, f->phys, sizeof(f->phys));
    }
    /* HID_UNIQ: de propósito, nenhum ramo. */
  }
  fclose(arq);
  caminho_real(dispositivo, f->caminho_real, sizeof(f->caminho_real));
  if (origem_usb_de(dispositivo, f->usb_pai, sizeof(f->usb_pai)) != 0)
    f->usb_pai[0] = '\0';
  f->tem_sysfs = 1;
  return 1;
}

/* O controle da Sony que chega ao SDL pelo evdev (/dev/input/event*) quase
 * sempre chegou assim porque o hidraw dele não abriu: o SDL desiste do driver
 * do DualSense em silêncio e fica com o genérico, que não tem luz nem efeito.
 * Aqui se acha o hidraw irmão (o mesmo aparelho HID publica o evdev em
 * <hid>/input/inputN e o hidraw em <hid>/hidraw/hidrawM) e se pergunta ao
 * sistema, com access(), se quem joga pode ler e escrever nele. O access() não
 * abre o nó. O nó que não existe não é falta de permissão. */
static void conferir_hidraw_irmao(const char *dispositivo, OrigemFatos *f) {
  char atual[PATH_MAX];
  char raiz[PATH_MAX];
  if (!realpath(dispositivo, atual) || !realpath(origem_raiz_sysfs(), raiz))
    return;
  size_t n_raiz = strlen(raiz);
  for (int nivel = 0; nivel < 4; nivel++) {
    char pasta[PATH_MAX + 16];
    snprintf(pasta, sizeof(pasta), "%s/hidraw", atual);
    DIR *d = opendir(pasta);
    if (d) {
      struct dirent *e;
      while ((e = readdir(d)) != NULL) {
        if (strncmp(e->d_name, "hidraw", 6) != 0)
          continue;
        char no[PATH_MAX + 300];
        snprintf(no, sizeof(no), "%s/%s", origem_raiz_dev(), e->d_name);
        if (access(no, F_OK) == 0 && access(no, R_OK | W_OK) != 0)
          f->hidraw_sem_permissao = 1;
      }
      closedir(d);
      return;
    }
    char *barra = strrchr(atual, '/');
    if (!barra || barra == atual)
      return;
    *barra = '\0';
    if (strlen(atual) <= n_raiz)
      return; /* acima da raiz do sysfs não há aparelho */
  }
}

static int fatos_evdev(const char *nome, OrigemFatos *f) {
  char dispositivo[PATH_MAX];
  snprintf(dispositivo, sizeof(dispositivo), "%s/class/input/%s/device", origem_raiz_sysfs(), nome);
  char caminho[PATH_MAX + 32];
  snprintf(caminho, sizeof(caminho), "%s/name", dispositivo);
  if (!ler_linha(caminho, f->nome_sistema, sizeof(f->nome_sistema)))
    return 0;
  char phys[160];
  snprintf(caminho, sizeof(caminho), "%s/phys", dispositivo);
  if (ler_linha(caminho, phys, sizeof(phys)))
    mascara_mac_copia(phys, f->phys, sizeof(f->phys));
  snprintf(caminho, sizeof(caminho), "%s/id/bustype", dispositivo);
  f->bus = (int)ler_hex(caminho);
  snprintf(caminho, sizeof(caminho), "%s/id/vendor", dispositivo);
  f->vid = ler_hex(caminho);
  snprintf(caminho, sizeof(caminho), "%s/id/product", dispositivo);
  f->pid = ler_hex(caminho);
  caminho_real(dispositivo, f->caminho_real, sizeof(f->caminho_real));
  if (origem_usb_de(dispositivo, f->usb_pai, sizeof(f->usb_pai)) != 0)
    f->usb_pai[0] = '\0';
  if (f->vid == 0x054c)
    conferir_hidraw_irmao(dispositivo, f);
  f->tem_sysfs = 1;
  return 1;
}

int origem_fatos_linux(const char *caminho_sdl, OrigemFatos *f) {
  if (!caminho_sdl || !caminho_sdl[0])
    return 0;
  const char *nome = base(caminho_sdl);
  if (strncmp(nome, "hidraw", 6) == 0)
    return fatos_hidraw(nome, f);
  if (strncmp(nome, "event", 5) == 0)
    return fatos_evdev(nome, f);
  return 0;
}

#else

int origem_fatos_linux(const char *caminho_sdl, OrigemFatos *f) {
  (void)caminho_sdl;
  (void)f;
  return 0;
}

int origem_usb_de(const char *caminho, char *out, size_t tam) {
  (void)caminho;
  if (out && tam)
    out[0] = '\0';
  return -1;
}

#endif
