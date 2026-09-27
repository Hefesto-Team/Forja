/* Um texto que cresce. Ver texto_buf.h. */
#include "texto_buf.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void tb_iniciar(TextoBuf *b) {
  b->dados = NULL;
  b->tam = b->cap = 0;
  b->falhou = 0;
}

void tb_liberar(TextoBuf *b) {
  free(b->dados);
  tb_iniciar(b);
}

static int garantir(TextoBuf *b, size_t mais) {
  if (b->falhou)
    return 0;
  if (b->tam + mais + 1 <= b->cap)
    return 1;
  size_t cap = b->cap ? b->cap : 1024;
  while (cap < b->tam + mais + 1)
    cap *= 2;
  char *novo = realloc(b->dados, cap);
  if (!novo) {
    b->falhou = 1;
    return 0;
  }
  b->dados = novo;
  b->cap = cap;
  return 1;
}

void tb_bytes(TextoBuf *b, const char *s, size_t n) {
  if (!garantir(b, n))
    return;
  memcpy(b->dados + b->tam, s, n);
  b->tam += n;
  b->dados[b->tam] = '\0';
}

void tb_texto(TextoBuf *b, const char *s) { tb_bytes(b, s ? s : "", strlen(s ? s : "")); }

void tb_printf(TextoBuf *b, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  va_list ap2;
  va_copy(ap2, ap);
  int n = vsnprintf(NULL, 0, fmt, ap);
  va_end(ap);
  if (n < 0 || !garantir(b, (size_t)n)) {
    va_end(ap2);
    return;
  }
  vsnprintf(b->dados + b->tam, (size_t)n + 1, fmt, ap2);
  va_end(ap2);
  b->tam += (size_t)n;
}

void tb_json_str(TextoBuf *b, const char *s) {
  if (!s) {
    tb_texto(b, "null");
    return;
  }
  tb_texto(b, "\"");
  for (const unsigned char *p = (const unsigned char *)s; *p; p++) {
    switch (*p) {
    case '"':
      tb_texto(b, "\\\"");
      break;
    case '\\':
      tb_texto(b, "\\\\");
      break;
    case '\n':
      tb_texto(b, "\\n");
      break;
    case '\r':
      tb_texto(b, "\\r");
      break;
    case '\t':
      tb_texto(b, "\\t");
      break;
    default:
      if (*p < 0x20)
        tb_printf(b, "\\u%04x", *p);
      else
        tb_bytes(b, (const char *)p, 1);
    }
  }
  tb_texto(b, "\"");
}

void tb_json_num(TextoBuf *b, double v, int casas) {
  if (isnan(v) || isinf(v)) {
    tb_texto(b, "null");
    return;
  }
  char tmp[64];
  snprintf(tmp, sizeof(tmp), "%.*f", casas, v);
  /* O printf segue o locale do processo; o JSON quer ponto. */
  for (char *c = tmp; *c; c++)
    if (*c == ',')
      *c = '.';
  tb_texto(b, tmp);
}
