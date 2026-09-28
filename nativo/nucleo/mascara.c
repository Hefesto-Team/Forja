/* A máscara de endereço. Ver mascara.h. */
#include "mascara.h"

#include <stdio.h>
#include <string.h>

static int eh_hex(char c) {
  return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

static int eh_letra_hex(char c) { return (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F'); }

static int eh_palavra(char c) {
  return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}

/* aa?bb?cc?dd?ee?ff com o mesmo separador; devolve 1 e zera dd e ee. */
static int tenta_com_separador(char *p, const char *inicio) {
  if (p > inicio && eh_palavra(p[-1]))
    return 0;
  char sep = p[2];
  if (sep != ':' && sep != '-' && sep != '_')
    return 0;
  for (int i = 0; i < 6; i++) {
    char *par = p + i * 3;
    if (!eh_hex(par[0]) || !eh_hex(par[1]))
      return 0;
    if (i < 5 && par[2] != sep)
      return 0;
  }
  if (eh_palavra(p[17]))
    return 0;
  p[9] = '0';
  p[10] = '0';
  p[12] = '0';
  p[13] = '0';
  return 1;
}

/* doze hex seguidos, com fronteira dos dois lados e ao menos uma letra. */
static int tenta_corrido(char *p, const char *inicio) {
  if (p > inicio && eh_palavra(p[-1]))
    return 0;
  int letras = 0;
  for (int i = 0; i < 12; i++) {
    if (!eh_hex(p[i]))
      return 0;
    letras += eh_letra_hex(p[i]);
  }
  if (eh_palavra(p[12]) || letras == 0)
    return 0;
  for (int i = 6; i < 10; i++)
    p[i] = '0';
  return 1;
}

int mascara_mac(char *texto) {
  if (!texto)
    return 0;
  int n = 0;
  size_t tam = strlen(texto);
  for (size_t i = 0; i < tam; i++) {
    char *p = texto + i;
    if (tam - i >= 17 && tenta_com_separador(p, texto)) {
      n++;
      i += 16;
      continue;
    }
    if (tam - i >= 12 && tenta_corrido(p, texto)) {
      n++;
      i += 11;
    }
  }
  return n;
}

int mascara_mac_copia(const char *de, char *para, size_t tam) {
  if (!para || tam == 0)
    return 0;
  snprintf(para, tam, "%s", de ? de : "");
  return mascara_mac(para);
}
