/* O texto. Ver texto.h. */
#include "texto.h"

#include "../nucleo/utf8.h"
#include "tema.h"

#include "stb_truetype.h"

#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern const unsigned char fonte_texto[];
extern const size_t fonte_texto_tam;
extern const unsigned char fonte_texto_negrito[];
extern const size_t fonte_texto_negrito_tam;
extern const unsigned char fonte_titulo[];
extern const size_t fonte_titulo_tam;

static const int EXTRAS[] = {0x2014, 0x2013, 0x2026, 0x201C, 0x201D, 0x2018, 0x2019, 0x2022,
                             0x2190, 0x2191, 0x2192, 0x2193, 0x2212, 0x2248, 0x2264, 0x2265};
#define N_EXTRAS ((int)(sizeof(EXTRAS) / sizeof(EXTRAS[0])))
#define LATIN_INI 32
#define LATIN_N (256 - 32)

typedef struct Atlas {
  SDL_Texture *tex;
  int w, h;
  const stbtt_fontinfo *info;
  float escala;
  float ascent, descent, gap;
  stbtt_packedchar latin[LATIN_N];
  stbtt_packedchar extra[N_EXTRAS];
  unsigned char tem_latin[LATIN_N];
  unsigned char tem_extra[N_EXTRAS];
  int latin_ate; /* último codepoint latino empacotado + 1 */
} Atlas;

static stbtt_fontinfo g_info[3];
static Atlas g_atlas[F_TOTAL_FONTES];

typedef struct DefFonte {
  int face; /* 0 texto, 1 negrito, 2 título */
  float px;
  int latin_ate;
} DefFonte;

static const DefFonte DEFS[F_TOTAL_FONTES] = {
    {0, 18, 256}, {0, 22, 256}, {0, 28, 256}, {0, 34, 256}, {0, 44, 256},
    {1, 22, 256}, {1, 28, 256}, {1, 34, 256}, {1, 44, 256}, {1, 64, 256},
    {2, 40, 256}, {2, 64, 256}, {2, 104, 256}, {2, 150, 128},
};

static bool empacotar(SDL_Renderer *r, Atlas *a, const DefFonte *d) {
  int oversample = d->px <= 34 ? 2 : 1;
  int lado = 256;
  unsigned char *pixels = NULL;
  for (; lado <= 4096; lado *= 2) {
    free(pixels);
    pixels = calloc((size_t)lado * lado, 1);
    if (!pixels)
      return false;
    stbtt_pack_context pc;
    if (!stbtt_PackBegin(&pc, pixels, lado, lado, 0, 1, NULL))
      continue;
    stbtt_PackSetOversampling(&pc, (unsigned)oversample, 1);
    stbtt_pack_range faixas[2];
    memset(faixas, 0, sizeof(faixas));
    faixas[0].font_size = d->px;
    faixas[0].first_unicode_codepoint_in_range = LATIN_INI;
    faixas[0].num_chars = d->latin_ate - LATIN_INI;
    faixas[0].chardata_for_range = a->latin;
    faixas[1].font_size = d->px;
    faixas[1].array_of_unicode_codepoints = (int *)EXTRAS;
    faixas[1].num_chars = N_EXTRAS;
    faixas[1].chardata_for_range = a->extra;
    int ok = stbtt_PackFontRanges(&pc, d->face == 0   ? fonte_texto
                                       : d->face == 1 ? fonte_texto_negrito
                                                      : fonte_titulo,
                                  0, faixas, 2);
    stbtt_PackEnd(&pc);
    if (ok)
      break;
  }
  if (lado > 4096) {
    free(pixels);
    return false;
  }
  Uint32 *rgba = malloc((size_t)lado * lado * 4);
  if (!rgba) {
    free(pixels);
    return false;
  }
  for (int i = 0; i < lado * lado; i++) {
    Uint8 px[4] = {255, 255, 255, pixels[i]};
    memcpy(&rgba[i], px, 4);
  }
  free(pixels);
  SDL_Surface *s = SDL_CreateSurfaceFrom(lado, lado, SDL_PIXELFORMAT_RGBA32, rgba, lado * 4);
  a->tex = s ? SDL_CreateTextureFromSurface(r, s) : NULL;
  if (s)
    SDL_DestroySurface(s);
  free(rgba);
  if (!a->tex)
    return false;
  SDL_SetTextureBlendMode(a->tex, SDL_BLENDMODE_BLEND);
  SDL_SetTextureScaleMode(a->tex, SDL_SCALEMODE_LINEAR);
  a->w = a->h = lado;
  a->info = &g_info[d->face];
  a->escala = stbtt_ScaleForPixelHeight(a->info, d->px);
  int asc, desc, gap;
  stbtt_GetFontVMetrics(a->info, &asc, &desc, &gap);
  a->ascent = asc * a->escala;
  a->descent = desc * a->escala;
  a->gap = gap * a->escala;
  a->latin_ate = d->latin_ate;
  for (int i = 0; i < LATIN_N; i++)
    a->tem_latin[i] = (LATIN_INI + i) < d->latin_ate && stbtt_FindGlyphIndex(a->info, LATIN_INI + i) != 0;
  for (int i = 0; i < N_EXTRAS; i++)
    a->tem_extra[i] = stbtt_FindGlyphIndex(a->info, EXTRAS[i]) != 0;
  return true;
}

bool texto_iniciar(SDL_Renderer *r) {
  const unsigned char *dados[3] = {fonte_texto, fonte_texto_negrito, fonte_titulo};
  for (int i = 0; i < 3; i++)
    if (!stbtt_InitFont(&g_info[i], dados[i], stbtt_GetFontOffsetForIndex(dados[i], 0)))
      return false;
  for (int f = 0; f < F_TOTAL_FONTES; f++)
    if (!empacotar(r, &g_atlas[f], &DEFS[f]))
      return false;
  return true;
}

void texto_encerrar(void) {
  for (int f = 0; f < F_TOTAL_FONTES; f++)
    if (g_atlas[f].tex) {
      SDL_DestroyTexture(g_atlas[f].tex);
      g_atlas[f].tex = NULL;
    }
}

/* O índice empacotado do codepoint: >= 0 latino, <= -1 extra (-(i+1)), ou
 * INT32_MIN quando a fonte não tem o glifo (cai no '?'). */
static stbtt_packedchar *glifo(Atlas *a, uint32_t cp) {
  if (cp >= LATIN_INI && cp < 256 && (int)cp < a->latin_ate && a->tem_latin[cp - LATIN_INI])
    return &a->latin[cp - LATIN_INI];
  for (int i = 0; i < N_EXTRAS; i++)
    if ((uint32_t)EXTRAS[i] == cp && a->tem_extra[i])
      return &a->extra[i];
  /* sem o glifo: travessão e aspas viram o equivalente ASCII */
  uint32_t troca = '?';
  if (cp == 0x2014 || cp == 0x2013 || cp == 0x2212)
    troca = '-';
  else if (cp == 0x201C || cp == 0x201D)
    troca = '"';
  else if (cp == 0x2018 || cp == 0x2019)
    troca = '\'';
  else if (cp == 0xA0)
    troca = ' ';
  else if (cp >= 'a' && cp <= 'z')
    troca = cp - 32; /* a fonte de versal não tem minúscula: vira maiúscula */
  else if (cp >= 0xE0 && cp <= 0xFE && cp != 0xF7)
    troca = cp - 32;
  if (troca != cp && troca >= LATIN_INI && troca < 256 && (int)troca < a->latin_ate &&
      a->tem_latin[troca - LATIN_INI])
    return &a->latin[troca - LATIN_INI];
  if ('?' < a->latin_ate && a->tem_latin['?' - LATIN_INI])
    return &a->latin['?' - LATIN_INI];
  return NULL;
}

float texto_altura(Fonte f) {
  Atlas *a = &g_atlas[f];
  return a->ascent - a->descent + a->gap;
}

float texto_ascendente(Fonte f) { return g_atlas[f].ascent; }

float texto_largura_espacado(Fonte f, float espaco, const char *s) {
  Atlas *a = &g_atlas[f];
  if (!a->tex || !s)
    return 0;
  float larg = 0, linha = 0;
  uint32_t cp, ant = 0;
  while ((cp = utf8_proximo(&s))) {
    if (cp == '\n') {
      if (linha > larg)
        larg = linha;
      linha = 0;
      ant = 0;
      continue;
    }
    stbtt_packedchar *g = glifo(a, cp);
    if (!g)
      continue;
    if (ant)
      linha += stbtt_GetCodepointKernAdvance(a->info, (int)ant, (int)cp) * a->escala;
    linha += g->xadvance + espaco;
    ant = cp;
  }
  if (linha > larg)
    larg = linha;
  return larg > 0 && espaco > 0 ? larg - espaco : larg;
}

float texto_largura(Fonte f, const char *s) { return texto_largura_espacado(f, 0, s); }

#define LOTE 1024
static SDL_Vertex g_lote_v[LOTE * 4];
static int g_lote_i[LOTE * 6];

static float desenhar_linha(SDL_Renderer *r, Atlas *a, float x, float y, SDL_Color c, float espaco,
                            const char *s, const char *fim) {
  if (!a->tex)
    return 0;
  float cx = x, base = y + a->ascent;
  SDL_FColor fc = cor_f(c);
  int n = 0;
  uint32_t cp, ant = 0;
  const char *p = s;
  while ((!fim || p < fim) && (cp = utf8_proximo(&p))) {
    if (cp == '\n')
      break;
    stbtt_packedchar *g = glifo(a, cp);
    if (!g)
      continue;
    if (ant)
      cx += stbtt_GetCodepointKernAdvance(a->info, (int)ant, (int)cp) * a->escala;
    ant = cp;
    float x0 = cx + g->xoff, y0 = base + g->yoff, x1 = cx + g->xoff2, y1 = base + g->yoff2;
    float u0 = g->x0 / (float)a->w, v0 = g->y0 / (float)a->h, u1 = g->x1 / (float)a->w,
          v1 = g->y1 / (float)a->h;
    cx += g->xadvance + espaco;
    if (g->x1 <= g->x0)
      continue; /* espaço */
    SDL_Vertex *v = &g_lote_v[n * 4];
    v[0].position.x = x0; v[0].position.y = y0; v[0].tex_coord.x = u0; v[0].tex_coord.y = v0;
    v[1].position.x = x1; v[1].position.y = y0; v[1].tex_coord.x = u1; v[1].tex_coord.y = v0;
    v[2].position.x = x1; v[2].position.y = y1; v[2].tex_coord.x = u1; v[2].tex_coord.y = v1;
    v[3].position.x = x0; v[3].position.y = y1; v[3].tex_coord.x = u0; v[3].tex_coord.y = v1;
    for (int k = 0; k < 4; k++)
      v[k].color = fc;
    int *ix = &g_lote_i[n * 6];
    ix[0] = n * 4; ix[1] = n * 4 + 1; ix[2] = n * 4 + 2;
    ix[3] = n * 4; ix[4] = n * 4 + 2; ix[5] = n * 4 + 3;
    n++;
    if (n == LOTE) {
      SDL_RenderGeometry(r, a->tex, g_lote_v, n * 4, g_lote_i, n * 6);
      n = 0;
    }
  }
  if (n)
    SDL_RenderGeometry(r, a->tex, g_lote_v, n * 4, g_lote_i, n * 6);
  return cx - x - (espaco > 0 ? espaco : 0);
}

float texto_espacado(SDL_Renderer *r, Fonte f, float x, float y, SDL_Color c, Alinhamento al,
                     float espaco, const char *s) {
  if (!s)
    return 0;
  Atlas *a = &g_atlas[f];
  float larg = 0;
  const char *linha = s;
  float yy = y;
  for (;;) {
    const char *quebra = strchr(linha, '\n');
    char tmp[1024];
    size_t n = quebra ? (size_t)(quebra - linha) : strlen(linha);
    if (n >= sizeof(tmp))
      n = sizeof(tmp) - 1;
    memcpy(tmp, linha, n);
    tmp[n] = '\0';
    float w = texto_largura_espacado(f, espaco, tmp);
    float xx = al == ALINHA_CENTRO ? x - w / 2 : al == ALINHA_DIR ? x - w : x;
    desenhar_linha(r, a, floorf(xx + 0.5f), floorf(yy + 0.5f), c, espaco, tmp, NULL);
    if (w > larg)
      larg = w;
    if (!quebra)
      break;
    linha = quebra + 1;
    yy += texto_altura(f);
  }
  return larg;
}

float texto_al(SDL_Renderer *r, Fonte f, float x, float y, SDL_Color c, Alinhamento al, const char *s) {
  return texto_espacado(r, f, x, y, c, al, 0, s);
}

float texto(SDL_Renderer *r, Fonte f, float x, float y, SDL_Color c, const char *s) {
  return texto_al(r, f, x, y, c, ALINHA_ESQ, s);
}

float texto_sombra(SDL_Renderer *r, Fonte f, float x, float y, SDL_Color c, Alinhamento al,
                   const char *s) {
  float d = texto_altura(f) > 60 ? 4 : 2;
  SDL_Color sombra = {0, 0, 0, (Uint8)(c.a * 0.7f)};
  texto_al(r, f, x + d * 0.6f, y + d, sombra, al, s);
  return texto_al(r, f, x, y, c, al, s);
}

float texto_bloco(SDL_Renderer *r, Fonte f, float x, float y, float largura, SDL_Color c,
                  Alinhamento al, float entrelinha, bool desenhar, const char *s) {
  if (!s)
    return 0;
  float lh = texto_altura(f) * (entrelinha > 0 ? entrelinha : 1.0f);
  float yy = y;
  char linha[1024] = "";
  size_t nl = 0;
  const char *p = s;
  while (*p) {
    /* a próxima palavra (até espaço ou quebra) */
    const char *ini = p;
    while (*p && *p != ' ' && *p != '\n')
      p++;
    size_t npal = (size_t)(p - ini);
    char tentativa[1024];
    if (nl)
      snprintf(tentativa, sizeof(tentativa), "%s %.*s", linha, (int)npal, ini);
    else
      snprintf(tentativa, sizeof(tentativa), "%.*s", (int)npal, ini);
    if (nl && texto_largura(f, tentativa) > largura) {
      if (desenhar)
        texto_al(r, f, al == ALINHA_CENTRO ? x + largura / 2 : al == ALINHA_DIR ? x + largura : x, yy,
                 c, al, linha);
      yy += lh;
      snprintf(linha, sizeof(linha), "%.*s", (int)npal, ini);
    } else {
      snprintf(linha, sizeof(linha), "%s", tentativa);
    }
    nl = strlen(linha);
    if (*p == '\n') {
      if (desenhar)
        texto_al(r, f, al == ALINHA_CENTRO ? x + largura / 2 : al == ALINHA_DIR ? x + largura : x, yy,
                 c, al, linha);
      yy += lh;
      linha[0] = '\0';
      nl = 0;
      p++;
    } else if (*p == ' ') {
      p++;
    }
  }
  if (nl) {
    if (desenhar)
      texto_al(r, f, al == ALINHA_CENTRO ? x + largura / 2 : al == ALINHA_DIR ? x + largura : x, yy,
               c, al, linha);
    yy += lh;
  }
  return yy - y;
}

const char *fmt(const char *formato, ...) {
  static char bufs[8][512];
  static int prox = 0;
  char *b = bufs[prox];
  prox = (prox + 1) % 8;
  va_list ap;
  va_start(ap, formato);
  vsnprintf(b, 512, formato, ap);
  va_end(ap);
  return b;
}
