/* As primitivas de desenho. Ver desenho.h. */
#include "desenho.h"

#include "tema.h"

#include <math.h>
#include <string.h>

#define PI_F 3.14159265358979f
#define MAX_V 12288

static SDL_Vertex g_v[MAX_V];
static int g_idx[MAX_V * 3];
static SDL_Texture *g_brilho;
static SDL_Texture *g_vinheta;
static SDL_Texture *g_ruido;

static SDL_Vertex vtx(float x, float y, SDL_FColor c) {
  SDL_Vertex v;
  v.position.x = x;
  v.position.y = y;
  v.color = c;
  v.tex_coord.x = 0;
  v.tex_coord.y = 0;
  return v;
}

static int segmentos_para(float raio) {
  int s = (int)(raio * 0.9f);
  if (s < 10)
    s = 10;
  if (s > 96)
    s = 96;
  return s;
}

/* ---------- texturas geradas ---------- */

static uint32_t hash2(int x, int y, uint32_t s) {
  uint32_t h = (uint32_t)x * 374761393u + (uint32_t)y * 668265263u + s * 2246822519u;
  h = (h ^ (h >> 13)) * 1274126177u;
  return h ^ (h >> 16);
}

static float ruido_valor(float x, float y, int periodo, uint32_t s) {
  int xi = (int)floorf(x), yi = (int)floorf(y);
  float fx = x - xi, fy = y - yi;
  float u = fx * fx * (3 - 2 * fx), v = fy * fy * (3 - 2 * fy);
  int x0 = ((xi % periodo) + periodo) % periodo, y0 = ((yi % periodo) + periodo) % periodo;
  int x1 = (x0 + 1) % periodo, y1 = (y0 + 1) % periodo;
  float a = (hash2(x0, y0, s) & 0xFFFF) / 65535.0f;
  float b = (hash2(x1, y0, s) & 0xFFFF) / 65535.0f;
  float c = (hash2(x0, y1, s) & 0xFFFF) / 65535.0f;
  float d = (hash2(x1, y1, s) & 0xFFFF) / 65535.0f;
  return (a + (b - a) * u) * (1 - v) + (c + (d - c) * u) * v;
}

static SDL_Texture *textura_de(SDL_Renderer *r, int w, int h, const Uint32 *px) {
  SDL_Surface *s = SDL_CreateSurfaceFrom(w, h, SDL_PIXELFORMAT_RGBA32, (void *)px, w * 4);
  if (!s)
    return NULL;
  SDL_Texture *t = SDL_CreateTextureFromSurface(r, s);
  SDL_DestroySurface(s);
  if (t)
    SDL_SetTextureScaleMode(t, SDL_SCALEMODE_LINEAR);
  return t;
}

static Uint32 rgba(int r, int g, int b, int a) {
  Uint8 px[4] = {(Uint8)r, (Uint8)g, (Uint8)b, (Uint8)a};
  Uint32 v;
  memcpy(&v, px, 4);
  return v;
}

bool desenho_iniciar(SDL_Renderer *r) {
  static Uint32 px[256 * 256];
  /* brilho: branco com queda suave, para o modo aditivo */
  const int B = 128;
  for (int y = 0; y < B; y++)
    for (int x = 0; x < B; x++) {
      float dx = (x + 0.5f) / B * 2 - 1, dy = (y + 0.5f) / B * 2 - 1;
      float d = sqrtf(dx * dx + dy * dy);
      float a = d >= 1 ? 0 : powf(1 - d, 2.2f);
      px[y * B + x] = rgba(255, 255, 255, (int)(a * 255));
    }
  g_brilho = textura_de(r, B, B, px);
  if (g_brilho)
    SDL_SetTextureBlendMode(g_brilho, SDL_BLENDMODE_ADD);

  /* vinheta: preto que cresce para as bordas */
  const int VW = 256, VH = 144;
  for (int y = 0; y < VH; y++)
    for (int x = 0; x < VW; x++) {
      float dx = ((x + 0.5f) / VW - 0.5f) * 2, dy = ((y + 0.5f) / VH - 0.5f) * 2;
      float d = sqrtf(dx * dx * 0.8f + dy * dy * 1.1f);
      float t = limitar((d - 0.55f) / 0.75f, 0, 1);
      px[y * VW + x] = rgba(0, 0, 0, (int)(suave(t) * 255));
    }
  g_vinheta = textura_de(r, VW, VH, px);
  if (g_vinheta)
    SDL_SetTextureBlendMode(g_vinheta, SDL_BLENDMODE_BLEND);

  /* ruído: metal martelado, em tons de brasa apagada, repetível */
  const int RW = 256;
  for (int y = 0; y < RW; y++)
    for (int x = 0; x < RW; x++) {
      float n = 0, amp = 0.5f, soma = 0;
      for (int o = 0; o < 4; o++) {
        int per = 8 << o;
        float f = (float)per / RW;
        n += ruido_valor(x * f, y * f, per, 7u + (uint32_t)o) * amp;
        soma += amp;
        amp *= 0.5f;
      }
      n /= soma;
      /* "marteladas": manchas circulares suaves */
      float m = ruido_valor(x * 12.0f / RW, y * 12.0f / RW, 12, 99u);
      float v = limitar(n * 0.8f + m * 0.35f - 0.2f, 0, 1);
      px[y * RW + x] = rgba(120 + (int)(v * 70), 80 + (int)(v * 40), 50 + (int)(v * 20), (int)(v * 255));
    }
  g_ruido = textura_de(r, RW, RW, px);
  if (g_ruido) {
    SDL_SetTextureBlendMode(g_ruido, SDL_BLENDMODE_BLEND);
    SDL_SetTextureScaleMode(g_ruido, SDL_SCALEMODE_LINEAR);
  }
  return g_brilho && g_vinheta && g_ruido;
}

void desenho_encerrar(void) {
  if (g_brilho)
    SDL_DestroyTexture(g_brilho);
  if (g_vinheta)
    SDL_DestroyTexture(g_vinheta);
  if (g_ruido)
    SDL_DestroyTexture(g_ruido);
  g_brilho = g_vinheta = g_ruido = NULL;
}

/* ---------- formas ---------- */

void ds_ret(SDL_Renderer *r, float x, float y, float w, float h, SDL_Color c) {
  SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_BLEND);
  SDL_SetRenderDrawColor(r, c.r, c.g, c.b, c.a);
  SDL_FRect q = {x, y, w, h};
  SDL_RenderFillRect(r, &q);
}

void ds_ret_grad(SDL_Renderer *r, float x, float y, float w, float h, SDL_Color topo, SDL_Color base) {
  SDL_FColor a = cor_f(topo), b = cor_f(base);
  SDL_Vertex v[4] = {vtx(x, y, a), vtx(x + w, y, a), vtx(x + w, y + h, b), vtx(x, y + h, b)};
  int idx[6] = {0, 1, 2, 0, 2, 3};
  SDL_RenderGeometry(r, NULL, v, 4, idx, 6);
}

/* O perímetro de um retângulo arredondado, começando no canto superior
 * esquerdo, sentido horário. Devolve quantos pontos. */
static int perimetro_arred(float x, float y, float w, float h, float raio, SDL_FPoint *p, int max) {
  if (raio > w / 2)
    raio = w / 2;
  if (raio > h / 2)
    raio = h / 2;
  if (raio < 0.5f) {
    SDL_FPoint q[4] = {{x, y}, {x + w, y}, {x + w, y + h}, {x, y + h}};
    memcpy(p, q, sizeof(q));
    return 4;
  }
  int seg = segmentos_para(raio) / 4;
  if (seg < 3)
    seg = 3;
  if ((seg + 1) * 4 > max)
    seg = max / 4 - 1;
  const float cx[4] = {x + w - raio, x + w - raio, x + raio, x + raio};
  const float cy[4] = {y + raio, y + h - raio, y + h - raio, y + raio};
  const float a0[4] = {-PI_F / 2, 0, PI_F / 2, PI_F};
  int n = 0;
  for (int c = 0; c < 4; c++)
    for (int i = 0; i <= seg; i++) {
      float a = a0[c] + (PI_F / 2) * i / seg;
      p[n].x = cx[c] + cosf(a) * raio;
      p[n].y = cy[c] + sinf(a) * raio;
      n++;
    }
  return n;
}

void ds_ret_arred_grad(SDL_Renderer *r, float x, float y, float w, float h, float raio,
                       SDL_Color topo, SDL_Color base) {
  SDL_FPoint p[512];
  int n = perimetro_arred(x, y, w, h, raio, p, 512);
  SDL_FColor ct = cor_f(topo), cb = cor_f(base);
  g_v[0] = vtx(x + w / 2, y + h / 2, cor_f(cor_mistura(topo, base, 0.5f)));
  for (int i = 0; i < n; i++) {
    float t = h > 0 ? (p[i].y - y) / h : 0;
    SDL_FColor c = {ct.r + (cb.r - ct.r) * t, ct.g + (cb.g - ct.g) * t, ct.b + (cb.b - ct.b) * t,
                    ct.a + (cb.a - ct.a) * t};
    g_v[1 + i] = vtx(p[i].x, p[i].y, c);
  }
  int k = 0;
  for (int i = 0; i < n; i++) {
    g_idx[k++] = 0;
    g_idx[k++] = 1 + i;
    g_idx[k++] = 1 + (i + 1) % n;
  }
  SDL_RenderGeometry(r, NULL, g_v, n + 1, g_idx, k);
}

void ds_ret_arred(SDL_Renderer *r, float x, float y, float w, float h, float raio, SDL_Color c) {
  ds_ret_arred_grad(r, x, y, w, h, raio, c, c);
}

void ds_contorno_arred(SDL_Renderer *r, float x, float y, float w, float h, float raio, float esp,
                       SDL_Color c) {
  SDL_FPoint fora[512], dentro[512];
  int n = perimetro_arred(x, y, w, h, raio, fora, 512);
  int m = perimetro_arred(x + esp, y + esp, w - 2 * esp, h - 2 * esp, raio - esp > 0 ? raio - esp : 0,
                          dentro, 512);
  if (n != m) {
    /* raio interno zerado: refaz os dois com o mesmo número de pontos */
    n = perimetro_arred(x, y, w, h, raio < esp + 1 ? esp + 1 : raio, fora, 512);
    m = perimetro_arred(x + esp, y + esp, w - 2 * esp, h - 2 * esp, raio < esp + 1 ? 1 : raio - esp,
                        dentro, 512);
    if (n != m)
      return;
  }
  SDL_FColor fc = cor_f(c);
  for (int i = 0; i < n; i++) {
    g_v[2 * i] = vtx(fora[i].x, fora[i].y, fc);
    g_v[2 * i + 1] = vtx(dentro[i].x, dentro[i].y, fc);
  }
  int k = 0;
  for (int i = 0; i < n; i++) {
    int a = 2 * i, b = 2 * i + 1, cc = 2 * ((i + 1) % n), d = 2 * ((i + 1) % n) + 1;
    g_idx[k++] = a;
    g_idx[k++] = cc;
    g_idx[k++] = b;
    g_idx[k++] = b;
    g_idx[k++] = cc;
    g_idx[k++] = d;
  }
  SDL_RenderGeometry(r, NULL, g_v, 2 * n, g_idx, k);
}

void ds_circulo_grad(SDL_Renderer *r, float cx, float cy, float raio, SDL_Color centro,
                     SDL_Color borda) {
  int seg = segmentos_para(raio);
  g_v[0] = vtx(cx, cy, cor_f(centro));
  SDL_FColor fb = cor_f(borda);
  for (int i = 0; i < seg; i++) {
    float a = 2 * PI_F * i / seg;
    g_v[1 + i] = vtx(cx + cosf(a) * raio, cy + sinf(a) * raio, fb);
  }
  int k = 0;
  for (int i = 0; i < seg; i++) {
    g_idx[k++] = 0;
    g_idx[k++] = 1 + i;
    g_idx[k++] = 1 + (i + 1) % seg;
  }
  SDL_RenderGeometry(r, NULL, g_v, seg + 1, g_idx, k);
}

void ds_circulo(SDL_Renderer *r, float cx, float cy, float raio, SDL_Color c) {
  ds_circulo_grad(r, cx, cy, raio, c, c);
}

void ds_arco(SDL_Renderer *r, float cx, float cy, float raio, float esp, float a0, float a1,
             SDL_Color c) {
  float faixa = fabsf(a1 - a0);
  int seg = (int)(segmentos_para(raio) * faixa / (2 * PI_F)) + 2;
  if (seg > MAX_V / 2 - 2)
    seg = MAX_V / 2 - 2;
  SDL_FColor fc = cor_f(c);
  float ri = raio - esp;
  for (int i = 0; i <= seg; i++) {
    float a = a0 + (a1 - a0) * i / seg;
    g_v[2 * i] = vtx(cx + cosf(a) * raio, cy + sinf(a) * raio, fc);
    g_v[2 * i + 1] = vtx(cx + cosf(a) * ri, cy + sinf(a) * ri, fc);
  }
  int k = 0;
  for (int i = 0; i < seg; i++) {
    int a = 2 * i;
    g_idx[k++] = a;
    g_idx[k++] = a + 2;
    g_idx[k++] = a + 1;
    g_idx[k++] = a + 1;
    g_idx[k++] = a + 2;
    g_idx[k++] = a + 3;
  }
  SDL_RenderGeometry(r, NULL, g_v, 2 * (seg + 1), g_idx, k);
}

void ds_anel(SDL_Renderer *r, float cx, float cy, float raio, float esp, SDL_Color c) {
  ds_arco(r, cx, cy, raio, esp, 0, 2 * PI_F, c);
}

void ds_linha(SDL_Renderer *r, float x0, float y0, float x1, float y1, float esp, SDL_Color c) {
  float dx = x1 - x0, dy = y1 - y0;
  float len = sqrtf(dx * dx + dy * dy);
  if (len < 0.001f)
    return;
  float nx = -dy / len * esp / 2, ny = dx / len * esp / 2;
  SDL_FColor fc = cor_f(c);
  SDL_Vertex v[4] = {vtx(x0 + nx, y0 + ny, fc), vtx(x1 + nx, y1 + ny, fc), vtx(x1 - nx, y1 - ny, fc),
                     vtx(x0 - nx, y0 - ny, fc)};
  int idx[6] = {0, 1, 2, 0, 2, 3};
  SDL_RenderGeometry(r, NULL, v, 4, idx, 6);
}

void ds_polilinha(SDL_Renderer *r, const SDL_FPoint *p, int n, float esp, SDL_Color c, bool fechada) {
  if (n < 2)
    return;
  int lados = fechada ? n : n - 1;
  for (int i = 0; i < lados; i++) {
    SDL_FPoint a = p[i], b = p[(i + 1) % n];
    ds_linha(r, a.x, a.y, b.x, b.y, esp, c);
  }
  if (esp >= 2.5f)
    for (int i = 0; i < n; i++)
      if (fechada || (i > 0 && i < n - 1))
        ds_circulo(r, p[i].x, p[i].y, esp / 2, c);
}

void ds_triangulo(SDL_Renderer *r, SDL_FPoint a, SDL_FPoint b, SDL_FPoint c, SDL_Color cor) {
  SDL_FColor f = cor_f(cor);
  SDL_Vertex v[3] = {vtx(a.x, a.y, f), vtx(b.x, b.y, f), vtx(c.x, c.y, f)};
  SDL_RenderGeometry(r, NULL, v, 3, NULL, 0);
}

static float cruz(SDL_FPoint o, SDL_FPoint a, SDL_FPoint b) {
  return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
}

static bool dentro_do_tri(SDL_FPoint p, SDL_FPoint a, SDL_FPoint b, SDL_FPoint c) {
  float d1 = cruz(a, b, p), d2 = cruz(b, c, p), d3 = cruz(c, a, p);
  bool neg = (d1 < 0) || (d2 < 0) || (d3 < 0);
  bool pos = (d1 > 0) || (d2 > 0) || (d3 > 0);
  return !(neg && pos);
}

void ds_poligono(SDL_Renderer *r, const SDL_FPoint *p, int n, SDL_Color c) {
  if (n < 3 || n > 1024)
    return;
  int ind[1024];
  float area = 0;
  for (int i = 0; i < n; i++) {
    const SDL_FPoint *a = &p[i], *b = &p[(i + 1) % n];
    area += a->x * b->y - b->x * a->y;
  }
  for (int i = 0; i < n; i++)
    ind[i] = area > 0 ? i : n - 1 - i;
  SDL_FColor fc = cor_f(c);
  for (int i = 0; i < n; i++)
    g_v[i] = vtx(p[i].x, p[i].y, fc);
  int k = 0, m = n, guarda = 0;
  int i = 0;
  while (m > 3 && guarda < n * n) {
    guarda++;
    int ia = ind[(i + m - 1) % m], ib = ind[i % m], ic = ind[(i + 1) % m];
    SDL_FPoint a = p[ia], b = p[ib], cc = p[ic];
    bool orelha = cruz(a, b, cc) > 0;
    for (int j = 0; orelha && j < m; j++) {
      int ij = ind[j];
      if (ij == ia || ij == ib || ij == ic)
        continue;
      if (dentro_do_tri(p[ij], a, b, cc))
        orelha = false;
    }
    if (orelha) {
      g_idx[k++] = ia;
      g_idx[k++] = ib;
      g_idx[k++] = ic;
      for (int j = i % m; j < m - 1; j++)
        ind[j] = ind[j + 1];
      m--;
      if (i >= m)
        i = 0;
    } else {
      i = (i + 1) % m;
    }
  }
  if (m == 3) {
    g_idx[k++] = ind[0];
    g_idx[k++] = ind[1];
    g_idx[k++] = ind[2];
  }
  SDL_RenderGeometry(r, NULL, g_v, n, g_idx, k);
}

int ds_suavizar(const SDL_FPoint *ctrl, int n, int passos, SDL_FPoint *saida) {
  int k = 0;
  for (int i = 0; i < n; i++) {
    SDL_FPoint p0 = ctrl[(i + n - 1) % n], p1 = ctrl[i], p2 = ctrl[(i + 1) % n],
               p3 = ctrl[(i + 2) % n];
    for (int s = 0; s < passos; s++) {
      float t = (float)s / passos, t2 = t * t, t3 = t2 * t;
      saida[k].x = 0.5f * ((2 * p1.x) + (-p0.x + p2.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 +
                           (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3);
      saida[k].y = 0.5f * ((2 * p1.y) + (-p0.y + p2.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 +
                           (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3);
      k++;
    }
  }
  return k;
}

/* ---------- atmosfera ---------- */

void ds_brilho(SDL_Renderer *r, float cx, float cy, float raio, SDL_Color c, float intensidade) {
  if (!g_brilho || intensidade <= 0.001f)
    return;
  float a = limitar(intensidade, 0, 1);
  SDL_SetTextureColorMod(g_brilho, c.r, c.g, c.b);
  SDL_SetTextureAlphaMod(g_brilho, (Uint8)(a * c.a));
  SDL_FRect q = {cx - raio, cy - raio, raio * 2, raio * 2};
  SDL_RenderTexture(r, g_brilho, NULL, &q);
}

void ds_vinheta(SDL_Renderer *r, float forca) {
  if (!g_vinheta)
    return;
  SDL_SetTextureAlphaMod(g_vinheta, (Uint8)(limitar(forca, 0, 1) * 255));
  SDL_FRect q = {0, 0, TELA_L, TELA_A};
  SDL_RenderTexture(r, g_vinheta, NULL, &q);
}

void ds_fundo(SDL_Renderer *r, float t, float calor) {
  ds_ret_grad(r, 0, 0, TELA_L, TELA_A, COR_FUNDO_1, COR_FUNDO_0);
  if (g_ruido) {
    SDL_SetTextureAlphaMod(g_ruido, 22);
    SDL_SetTextureColorMod(g_ruido, 255, 220, 190);
    const float lado = 512;
    for (float y = 0; y < TELA_A; y += lado)
      for (float x = 0; x < TELA_L; x += lado) {
        SDL_FRect q = {x, y, lado, lado};
        SDL_RenderTexture(r, g_ruido, NULL, &q);
      }
  }
  /* o fogo da forja, embaixo, respirando */
  float pulso = 0.85f + 0.15f * sinf(t * 1.7f) + 0.05f * sinf(t * 5.3f);
  float c = limitar(calor, 0, 1.5f) * pulso;
  ds_brilho(r, TELA_L * 0.5f, TELA_A + 180, 900, COR_BRASA, 0.22f * c);
  ds_brilho(r, TELA_L * 0.5f, TELA_A + 60, 520, COR_BRASA_VIVA, 0.16f * c);
  ds_brilho(r, TELA_L * 0.18f, TELA_A + 120, 420, COR_BRASA, 0.08f * c);
  ds_brilho(r, TELA_L * 0.82f, TELA_A + 120, 420, COR_BRASA, 0.08f * c);
  ds_vinheta(r, 0.85f);
}

void ds_greca(SDL_Renderer *r, float x, float y, float largura, float altura, float esp, SDL_Color c) {
  /* duas réguas e, entre elas, ganchos em espiral quadrada — o meandro. */
  float u = altura; /* largura do módulo = altura da faixa */
  int n = (int)(largura / u);
  if (n < 1)
    return;
  float sobra = (largura - n * u) / 2;
  ds_linha(r, x, y, x + largura, y, esp, c);
  ds_linha(r, x, y + altura, x + largura, y + altura, esp, c);
  static const float gancho[][2] = {{0.18f, 0.84f}, {0.18f, 0.18f}, {0.82f, 0.18f},
                                    {0.82f, 0.66f}, {0.42f, 0.66f}, {0.42f, 0.42f}};
  for (int i = 0; i < n; i++) {
    SDL_FPoint p[6];
    for (int k = 0; k < 6; k++) {
      p[k].x = x + sobra + i * u + gancho[k][0] * u;
      p[k].y = y + gancho[k][1] * altura;
    }
    ds_polilinha(r, p, 6, esp, c, false);
  }
}
