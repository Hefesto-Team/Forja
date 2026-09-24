/* FORJA — o alto-falante do DualSense, achado como um jogo o acha.
 * Ver include/forja_alto_falante.h. */
#define _XOPEN_SOURCE 700

#include "forja_alto_falante.h"
#include "forja_mesa.h"

#include <ctype.h>
#include <limits.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* -std=c11 esconde M_PI (__STRICT_ANSI__). */
#define FORJA_PI 3.14159265358979323846

/* As strings USB da Sony, como o PipeWire as monta no nome do nó da placa e
 * como o Windows as mostra ("Wireless Controller"). Casamento por substring
 * sem caixa — o que todo motor de jogo faz. */
static const char *MARCAS[] = {"dualsense", "wireless_controller", "wireless controller",
                               NULL};

static void minusculo(const char *de, char *para, size_t tam) {
  size_t i = 0;
  for (; de[i] && i + 1 < tam; i++)
    para[i] = (char)tolower((unsigned char)de[i]);
  para[i] = '\0';
}

static int contem_sem_caixa(const char *palheiro, const char *agulha) {
  char a[512], b[256];
  minusculo(palheiro, a, sizeof(a));
  minusculo(agulha, b, sizeof(b));
  return b[0] && strstr(a, b) != NULL;
}

int forja_e_do_dualsense(const char *nome, const char *descricao) {
  char baixa[256];
  minusculo(nome ? nome : "", baixa, sizeof(baixa));
  size_t n = strlen(baixa);
  if (n >= 8 && strcmp(baixa + n - 8, ".monitor") == 0)
    return 0; /* o monitor é a saída vista de dentro, não um destino */
  if (strncmp(baixa, "alsa_input.", 11) == 0)
    return 0; /* nó de captura nunca é por onde sai som */
  for (const char **m = MARCAS; *m; m++) {
    if (contem_sem_caixa(nome ? nome : "", *m) || contem_sem_caixa(descricao ? descricao : "", *m))
      return 1;
  }
  return 0;
}

static const char *depois_de(const char *linha, const char *prefixo) {
  size_t n = strlen(prefixo);
  return strncmp(linha, prefixo, n) == 0 ? linha + n : NULL;
}

static void copiar_sem_fim(char *para, size_t tam, const char *de) {
  snprintf(para, tam, "%s", de);
  size_t n = strlen(para);
  while (n && (para[n - 1] == '\n' || para[n - 1] == '\r' || para[n - 1] == ' '))
    para[--n] = '\0';
}

/* `chave = "valor"` de um bloco Properties. 1 se leu. */
static int propriedade(const char *linha, char *chave, size_t tc, char *valor, size_t tv) {
  const char *igual = strstr(linha, " = ");
  if (!igual)
    return 0;
  size_t n = (size_t)(igual - linha);
  if (n + 1 > tc)
    return 0;
  memcpy(chave, linha, n);
  chave[n] = '\0';
  const char *v = igual + 3;
  if (*v == '"')
    v++;
  copiar_sem_fim(valor, tv, v);
  size_t m = strlen(valor);
  if (m && valor[m - 1] == '"')
    valor[m - 1] = '\0';
  return 1;
}

typedef struct Identidade {
  char bus[32];
  long vid, pid;
} Identidade;

static void fechar(ForjaNoDeSom *no, const Identidade *id, ForjaNoDeSom *nos, int max, int *n,
                   int *total) {
  if (no->indice < 0)
    return;
  (*total)++;
  no->usb_da_sony = strcmp(id->bus, "usb") == 0 && id->vid == 0x054c &&
                    (id->pid == 0x0ce6 || id->pid == 0x0df2);
  if (*n < max && forja_e_do_dualsense(no->nome, no->descricao))
    nos[(*n)++] = *no;
}

int forja_nos_de_som(const char *texto, ForjaNoDeSom *nos, int max, int *total) {
  int n = 0, tot = 0;
  ForjaNoDeSom atual;
  Identidade id;
  memset(&atual, 0, sizeof(atual));
  memset(&id, 0, sizeof(id));
  atual.indice = -1;
  const char *p = texto ? texto : "";
  while (*p) {
    const char *fim = strchr(p, '\n');
    size_t len = fim ? (size_t)(fim - p) : strlen(p);
    char linha[1024];
    if (len >= sizeof(linha))
      len = sizeof(linha) - 1;
    memcpy(linha, p, len);
    linha[len] = '\0';
    p = fim ? fim + 1 : p + strlen(p);

    const char *resto;
    if ((resto = depois_de(linha, "Sink #"))) {
      fechar(&atual, &id, nos, max, &n, &tot);
      memset(&atual, 0, sizeof(atual));
      memset(&id, 0, sizeof(id));
      atual.indice = atoi(resto);
      continue;
    }
    const char *c = linha;
    while (*c == ' ' || *c == '\t')
      c++;
    if ((resto = depois_de(c, "Name: "))) {
      copiar_sem_fim(atual.nome, sizeof(atual.nome), resto);
    } else if ((resto = depois_de(c, "Description: "))) {
      copiar_sem_fim(atual.descricao, sizeof(atual.descricao), resto);
    } else if ((resto = depois_de(c, "Sample Specification: "))) {
      int canais = 0;
      if (sscanf(resto, "%*s %dch", &canais) == 1)
        atual.canais = canais;
    } else {
      char chave[128], valor[512];
      if (!propriedade(c, chave, sizeof(chave), valor, sizeof(valor)))
        continue;
      if (strcmp(chave, "sysfs.path") == 0)
        snprintf(atual.sysfs, sizeof(atual.sysfs), "%s", valor);
      else if (strcmp(chave, "device.bus") == 0)
        snprintf(id.bus, sizeof(id.bus), "%s", valor);
      else if (strcmp(chave, "device.vendor.id") == 0)
        id.vid = strtol(valor, NULL, 16); /* "054c" e "0x054c", como o Wine */
      else if (strcmp(chave, "device.product.id") == 0)
        id.pid = strtol(valor, NULL, 16);
    }
  }
  fechar(&atual, &id, nos, max, &n, &tot);
  if (total)
    *total = tot;
  return n;
}

int forja_no_por_nome(const ForjaNoDeSom *nos, int n, const char *texto) {
  if (!texto || !texto[0])
    return -1;
  for (int i = 0; i < n; i++) {
    if (contem_sem_caixa(nos[i].descricao, texto) || contem_sem_caixa(nos[i].nome, texto))
      return i;
  }
  return -1;
}

int forja_no_do_pad(const ForjaNoDeSom *nos, int n, const char *usb_do_pad) {
  if (!usb_do_pad || !usb_do_pad[0])
    return -1;
  for (int i = 0; i < n; i++) {
    if (!nos[i].sysfs[0])
      continue; /* sem sysfs.path o Wine zera o ContainerId: não casa nada */
    char caminho[PATH_MAX];
    snprintf(caminho, sizeof(caminho), "%s%s", forja_sysfs(), nos[i].sysfs);
    char usb[PATH_MAX];
    if (forja_usb_de(caminho, usb, sizeof(usb)) == 0 && strcmp(usb, usb_do_pad) == 0)
      return i;
  }
  return -1;
}

const char *forja_mapa_de_canais(int canais) {
  switch (canais) {
  case 1:
    return "MONO";
  case 2:
    return "FL,FR";
  case 4:
    return "FL,FR,RL,RR";
  default:
    return NULL;
  }
}

int forja_canal_do_alto_falante(int canais) {
  return canais >= 2 ? FORJA_CANAL_DO_ALTO_FALANTE : 0;
}

void forja_tom(int16_t *pcm, long n_quadros, int canais, int canal_a, int canal_b,
               double hz) {
  /* Rampa de 10 ms nas duas pontas: sem ela o nó SUSPENSO come o começo do
   * primeiro som, e o corte seco no fim estala. */
  long rampa = FORJA_TAXA / 100;
  for (long i = 0; i < n_quadros; i++) {
    double env = 1.0;
    if (i < rampa)
      env = (double)i / (double)rampa;
    else if (n_quadros - i < rampa)
      env = (double)(n_quadros - i) / (double)rampa;
    int16_t v = (int16_t)(env * 22000.0 * sin(2.0 * FORJA_PI * hz * (double)i / FORJA_TAXA));
    for (int c = 0; c < canais; c++)
      pcm[i * canais + c] = (c == canal_a || c == canal_b) ? v : 0;
  }
}
