/* UTF-8. Ver utf8.h. */
#include "utf8.h"

uint32_t utf8_proximo(const char **p) {
  const unsigned char *s = (const unsigned char *)*p;
  if (!s || !*s)
    return 0;
  uint32_t cp;
  int n;
  if (s[0] < 0x80) {
    *p += 1;
    return s[0];
  } else if ((s[0] & 0xE0) == 0xC0) {
    cp = s[0] & 0x1F;
    n = 1;
  } else if ((s[0] & 0xF0) == 0xE0) {
    cp = s[0] & 0x0F;
    n = 2;
  } else if ((s[0] & 0xF8) == 0xF0) {
    cp = s[0] & 0x07;
    n = 3;
  } else {
    *p += 1;
    return 0xFFFD;
  }
  for (int i = 1; i <= n; i++) {
    if ((s[i] & 0xC0) != 0x80) {
      *p += 1;
      return 0xFFFD;
    }
    cp = (cp << 6) | (s[i] & 0x3F);
  }
  *p += n + 1;
  return cp;
}

size_t utf8_contar(const char *s) {
  size_t n = 0;
  while (utf8_proximo(&s))
    n++;
  return n;
}

int utf8_escrever(uint32_t cp, char out[4]) {
  if (cp < 0x80) {
    out[0] = (char)cp;
    return 1;
  }
  if (cp < 0x800) {
    out[0] = (char)(0xC0 | (cp >> 6));
    out[1] = (char)(0x80 | (cp & 0x3F));
    return 2;
  }
  if (cp < 0x10000) {
    out[0] = (char)(0xE0 | (cp >> 12));
    out[1] = (char)(0x80 | ((cp >> 6) & 0x3F));
    out[2] = (char)(0x80 | (cp & 0x3F));
    return 3;
  }
  out[0] = (char)(0xF0 | (cp >> 18));
  out[1] = (char)(0x80 | ((cp >> 12) & 0x3F));
  out[2] = (char)(0x80 | ((cp >> 6) & 0x3F));
  out[3] = (char)(0x80 | (cp & 0x3F));
  return 4;
}

void utf8_maiusculas(const char *s, char *out, size_t tam) {
  if (!out || !tam)
    return;
  size_t n = 0;
  uint32_t cp;
  while (s && (cp = utf8_proximo(&s)) != 0) {
    if (cp >= 'a' && cp <= 'z')
      cp -= 0x20;
    else if (cp >= 0xE0 && cp <= 0xFE && cp != 0xF7) /* à..þ, menos o ÷ */
      cp -= 0x20;
    char b[4];
    int k = utf8_escrever(cp, b);
    if (n + (size_t)k + 1 > tam)
      break;
    for (int i = 0; i < k; i++)
      out[n++] = b[i];
  }
  out[n] = 0;
}
