#ifndef DEMO_TEXTO_BUF_H
#define DEMO_TEXTO_BUF_H

#include <stdarg.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct TextoBuf {
  char *dados;
  size_t tam, cap;
  int falhou;
} TextoBuf;

void tb_iniciar(TextoBuf *b);
void tb_liberar(TextoBuf *b);
void tb_texto(TextoBuf *b, const char *s);
void tb_bytes(TextoBuf *b, const char *s, size_t n);
void tb_printf(TextoBuf *b, const char *fmt, ...)
#if defined(__GNUC__)
    __attribute__((format(printf, 2, 3)))
#endif
    ;
void tb_json_str(TextoBuf *b, const char *s);
void tb_json_num(TextoBuf *b, double v, int casas);

const char *num_pt(char *buf, size_t tam, double v, int casas);

#ifdef __cplusplus
}
#endif

#endif
