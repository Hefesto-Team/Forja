/* As peças da interface. Ver widgets.h. */
#include "widgets.h"

#include "desenho.h"
#include "tema.h"
#include "texto.h"

#include <math.h>

void wg_painel(SDL_Renderer *r, float x, float y, float w, float h, SDL_Color acento, float destaque) {
  float raio = 14;
  /* sombra */
  ds_ret_arred(r, x + 6, y + 10, w, h, raio, (SDL_Color){0, 0, 0, 90});
  ds_ret_arred_grad(r, x, y, w, h, raio, cor_alfa(COR_PAINEL, 0.96f), cor_alfa(COR_CARVAO, 0.96f));
  SDL_Color borda = cor_mistura(COR_BRONZE_ESCURO, acento, 0.35f + 0.5f * destaque);
  if (destaque > 0.01f)
    ds_brilho(r, x + w / 2, y + h / 2, fmaxf(w, h) * 0.7f, acento, 0.10f * destaque);
  ds_contorno_arred(r, x, y, w, h, raio, 2.5f, borda);
  ds_contorno_arred(r, x + 6, y + 6, w - 12, h - 12, raio - 5, 1, cor_alfa(borda, 0.35f));
  /* os cantos: pequenos losangos de ouro, como rebites */
  SDL_Color rebite = cor_mistura(COR_BRONZE_CLARO, acento, 0.3f * destaque);
  float cx[4] = {x + 16, x + w - 16, x + w - 16, x + 16};
  float cy[4] = {y + 16, y + 16, y + h - 16, y + h - 16};
  for (int i = 0; i < 4; i++) {
    SDL_FPoint p[4] = {{cx[i], cy[i] - 5}, {cx[i] + 5, cy[i]}, {cx[i], cy[i] + 5}, {cx[i] - 5, cy[i]}};
    ds_poligono(r, p, 4, rebite);
  }
}

float wg_chip_largura(Icone ic, const char *s) {
  float w = texto_largura(F_PEQUENA_N, s) + 28;
  if (ic != IC_TOTAL)
    w += 30;
  return w;
}

float wg_chip(SDL_Renderer *r, float x, float y, Icone ic, const char *s, SDL_Color cor, bool cheio) {
  float h = 38;
  float w = wg_chip_largura(ic, s);
  if (cheio) {
    ds_ret_arred(r, x, y, w, h, h / 2, cor_alfa(cor, 0.9f));
  } else {
    ds_ret_arred(r, x, y, w, h, h / 2, cor_alfa(cor_escurecer(cor, 0.75f), 0.85f));
    ds_contorno_arred(r, x, y, w, h, h / 2, 1.5f, cor_alfa(cor, 0.8f));
  }
  float tx = x + 14;
  SDL_Color frente = cheio ? COR_FUNDO_0 : cor;
  if (ic != IC_TOTAL) {
    icone(r, ic, x + 26, y + h / 2, 26, frente, 0);
    tx += 30;
  }
  texto(r, F_PEQUENA_N, tx, y + (h - texto_altura(F_PEQUENA_N)) / 2, frente, s);
  return w;
}

void wg_barra(SDL_Renderer *r, float x, float y, float w, float h, float v, SDL_Color cor) {
  v = limitar(v, 0, 1);
  ds_ret_arred(r, x, y, w, h, h / 2, cor_alfa(COR_FUNDO_0, 0.8f));
  if (v > 0.001f) {
    float ww = fmaxf(h, w * v);
    ds_ret_arred_grad(r, x, y, ww, h, h / 2, cor_clarear(cor, 0.25f), cor);
  }
  ds_contorno_arred(r, x, y, w, h, h / 2, 1, cor_alfa(COR_BRONZE_ESCURO, 0.9f));
}

void wg_barra_centro(SDL_Renderer *r, float x, float y, float w, float h, float v, SDL_Color cor) {
  v = limitar(v, -1, 1);
  ds_ret_arred(r, x, y, w, h, h / 2, cor_alfa(COR_FUNDO_0, 0.8f));
  float meio = x + w / 2;
  float ww = fabsf(v) * w / 2;
  if (ww > 1)
    ds_ret(r, v > 0 ? meio : meio - ww, y + 2, ww, h - 4, cor);
  ds_linha(r, meio, y - 2, meio, y + h + 2, 2, COR_TEXTO_3);
  ds_contorno_arred(r, x, y, w, h, h / 2, 1, cor_alfa(COR_BRONZE_ESCURO, 0.9f));
}

void wg_medidor_vertical(SDL_Renderer *r, float x, float y, float w, float h, float v, float pico,
                         SDL_Color cor) {
  v = limitar(v, 0, 1);
  ds_ret_arred(r, x, y, w, h, 6, cor_alfa(COR_FUNDO_0, 0.85f));
  int seg = 16;
  float gap = 3;
  float sh = (h - gap * (seg + 1)) / seg;
  for (int i = 0; i < seg; i++) {
    float nivel = (i + 0.5f) / seg;
    float sy = y + h - gap - (i + 1) * (sh + gap) + gap;
    SDL_Color c = i >= seg - 3 ? COR_FALHA : i >= seg - 6 ? COR_AVISO : cor;
    bool aceso = nivel <= v;
    ds_ret_arred(r, x + 4, sy, w - 8, sh, 2, aceso ? c : cor_alfa(c, 0.12f));
  }
  if (pico > 0.02f) {
    float py = y + h - limitar(pico, 0, 1) * h;
    ds_ret(r, x + 2, py - 1.5f, w - 4, 3, COR_TEXTO);
  }
  ds_contorno_arred(r, x, y, w, h, 6, 1.5f, COR_BRONZE_ESCURO);
}

void wg_selo(SDL_Renderer *r, float cx, float cy, Resultado res, float escala) {
  SDL_Color c = res == RES_PASSOU ? COR_OK : res == RES_FALHOU ? COR_FALHA : COR_NEUTRO;
  Icone ic = res == RES_PASSOU ? IC_OK : res == RES_FALHOU ? IC_FALHA : IC_NAO_MEDIDO;
  const char *palavra = res == RES_PASSOU ? "PASSOU" : res == RES_FALHOU ? "FALHOU" : "NÃO MEDIDO";
  Fonte f = escala >= 1.2f ? F_MEDIA_N : F_PEQUENA_N;
  float tw = texto_largura(f, palavra);
  float h = 44 * escala, w = tw + 70 * escala;
  float x = cx - w / 2, y = cy - h / 2;
  ds_ret_arred(r, x, y, w, h, h / 2, cor_alfa(cor_escurecer(c, 0.78f), 0.95f));
  ds_contorno_arred(r, x, y, w, h, h / 2, 2, c);
  icone(r, ic, x + h * 0.55f, cy, h * 0.75f, c, 0);
  texto(r, f, x + h * 0.95f, cy - texto_altura(f) / 2, c, palavra);
}

void wg_rodape(SDL_Renderer *r, const Dica *dicas, int n) {
  float y = TELA_A - 58;
  ds_ret_grad(r, 0, y - 30, TELA_L, 90, (SDL_Color){0, 0, 0, 0}, (SDL_Color){0, 0, 0, 170});
  float larg = 0;
  for (int i = 0; i < n; i++) {
    float w_ic = (dicas[i].ic >= IC_L1 && dicas[i].ic <= IC_R2) || dicas[i].ic == IC_TOUCHPAD ? 44 : 34;
    larg += w_ic + 10 + texto_largura(F_TEXTO, dicas[i].texto) + (i < n - 1 ? 44 : 0);
  }
  float x = TELA_L / 2 - larg / 2;
  for (int i = 0; i < n; i++) {
    x += icone_dica(r, dicas[i].ic, x, y + 12, dicas[i].texto, COR_TEXTO_2);
    x += 44;
  }
}

void wg_cabecalho(SDL_Renderer *r, const char *titulo, const char *subtitulo, float t) {
  (void)t;
  texto_espacado(r, F_TITULO, TELA_L / 2.0f, 46, COR_OURO, ALINHA_CENTRO, 6, titulo);
  float tw = texto_largura_espacado(F_TITULO, 6, titulo);
  float gx = TELA_L / 2 - tw / 2 - 180, gw = 140;
  ds_greca(r, gx, 72, gw, 22, 2, cor_alfa(COR_BRONZE, 0.8f));
  ds_greca(r, TELA_L / 2 + tw / 2 + 40, 72, gw, 22, 2, cor_alfa(COR_BRONZE, 0.8f));
  if (subtitulo && subtitulo[0])
    texto_al(r, F_TEXTO, TELA_L / 2.0f, 128, COR_TEXTO_2, ALINHA_CENTRO, subtitulo);
}

void wg_aviso(SDL_Renderer *r, const char *s, float idade) {
  if (!s || !s[0] || idade > 4.0f)
    return;
  float entra = sai_rapido(idade / 0.3f);
  float sai = idade > 3.4f ? 1 - (idade - 3.4f) / 0.6f : 1;
  float a = limitar(fminf(entra, sai), 0, 1);
  float w = texto_largura(F_TEXTO_N, s) + 90, h = 58;
  float x = TELA_L / 2 - w / 2, y = -h + (h + 24) * entra;
  ds_ret_arred(r, x, y, w, h, 12, cor_alfa(COR_CARVAO, 0.95f * a));
  ds_contorno_arred(r, x, y, w, h, 12, 2, cor_alfa(COR_AVISO, a));
  icone(r, IC_AVISO, x + 34, y + h / 2, 30, cor_alfa(COR_AVISO, a), 0);
  texto(r, F_TEXTO_N, x + 62, y + (h - texto_altura(F_TEXTO_N)) / 2, cor_alfa(COR_TEXTO, a), s);
}

void wg_item_menu(SDL_Renderer *r, float x, float y, float w, float h, const char *rotulo,
                  const char *sub, bool sel, float brilho, Icone ic) {
  SDL_Color acento = sel ? COR_BRASA : COR_BRONZE_ESCURO;
  if (sel) {
    ds_brilho(r, x + w / 2, y + h / 2, w * 0.6f, COR_BRASA, 0.18f + 0.06f * brilho);
    ds_ret_arred_grad(r, x, y, w, h, 12, cor_alfa((SDL_Color){78, 44, 22, 255}, 0.95f),
                      cor_alfa((SDL_Color){46, 26, 14, 255}, 0.95f));
  } else {
    ds_ret_arred_grad(r, x, y, w, h, 12, cor_alfa(COR_PAINEL, 0.85f), cor_alfa(COR_CARVAO, 0.85f));
  }
  ds_contorno_arred(r, x, y, w, h, 12, sel ? 3 : 1.5f, acento);
  float tx = x + 30;
  if (ic != IC_TOTAL) {
    icone(r, ic, x + 50, y + h / 2, 44, sel ? COR_OURO : COR_BRONZE_CLARO, 0);
    tx = x + 96;
  }
  float ty = sub ? y + h / 2 - texto_altura(F_MEDIA_N) + 6 : y + (h - texto_altura(F_MEDIA_N)) / 2;
  texto(r, F_MEDIA_N, tx, ty, sel ? COR_TEXTO : COR_TEXTO_2, rotulo);
  if (sub)
    texto(r, F_PEQUENA, tx, y + h / 2 + 6, sel ? COR_TEXTO_2 : COR_TEXTO_3, sub);
  if (sel) {
    /* a brasa que marca a escolha */
    float px = x - 26, py = y + h / 2;
    SDL_FPoint p[3] = {{px - 10, py - 12}, {px + 8, py}, {px - 10, py + 12}};
    ds_poligono(r, p, 3, COR_BRASA_VIVA);
  }
}

void wg_escudo_jogador(SDL_Renderer *r, float cx, float cy, float tam, int slot, bool vivo) {
  SDL_Color c = slot >= 0 && slot < 4 ? COR_JOGADOR[slot] : COR_NEUTRO;
  if (!vivo)
    c = cor_mistura(c, COR_NEUTRO, 0.7f);
  float w = tam, h = tam * 1.12f;
  SDL_FPoint p[7] = {{cx - w / 2, cy - h / 2},         {cx + w / 2, cy - h / 2},
                     {cx + w / 2, cy + h * 0.08f},      {cx + w * 0.28f, cy + h * 0.36f},
                     {cx, cy + h / 2},                  {cx - w * 0.28f, cy + h * 0.36f},
                     {cx - w / 2, cy + h * 0.08f}};
  if (vivo)
    ds_brilho(r, cx, cy, tam * 1.2f, c, 0.3f);
  ds_poligono(r, p, 7, cor_escurecer(c, 0.55f));
  ds_polilinha(r, p, 7, 3, c, true);
  char rot[4] = {'P', (char)('1' + (slot >= 0 ? slot : 0)), 0, 0};
  Fonte f = tam >= 80 ? F_GRANDE_N : tam >= 54 ? F_MEDIA_N : F_TEXTO_N;
  texto_al(r, f, cx, cy - texto_altura(f) * 0.58f, COR_TEXTO, ALINHA_CENTRO, rot);
}

/* ---------- texto com ícones ---------- */

static const struct {
  const char *marca;
  Icone ic;
  float largura; /* em alturas de linha */
} MARCAS[] = {
    {"{X}", IC_CRUZ, 1.0f},     {"{O}", IC_CIRCULO, 1.0f},  {"{Q}", IC_QUADRADO, 1.0f},
    {"{T}", IC_TRIANGULO, 1.0f}, {"{L1}", IC_L1, 1.3f},     {"{R1}", IC_R1, 1.3f},
    {"{L2}", IC_L2, 1.3f},       {"{R2}", IC_R2, 1.3f},     {"{L3}", IC_L3, 1.0f},
    {"{R3}", IC_R3, 1.0f},       {"{OPT}", IC_OPTIONS, 0.8f}, {"{CRI}", IC_CREATE, 0.8f},
    {"{PS}", IC_PS, 1.0f},       {"{TP}", IC_TOUCHPAD, 1.4f}, {"{MIC}", IC_MIC, 1.0f},
    {"{DP}", IC_DPAD, 1.0f},
};

static int marca_em(const char *p, int *ind) {
  for (int i = 0; i < (int)(sizeof(MARCAS) / sizeof(MARCAS[0])); i++) {
    size_t n = SDL_strlen(MARCAS[i].marca);
    if (SDL_strncmp(p, MARCAS[i].marca, n) == 0) {
      *ind = i;
      return (int)n;
    }
  }
  return 0;
}

static float rico(SDL_Renderer *r, Fonte f, float x, float y, SDL_Color cor, const char *s, bool desenhar) {
  float lh = texto_altura(f);
  float cx = x;
  char pedaco[512];
  size_t np = 0;
  for (const char *p = s;; p++) {
    int ind = -1, n = *p ? marca_em(p, &ind) : 0;
    if (!*p || n) {
      pedaco[np] = 0;
      if (np) {
        if (desenhar)
          texto(r, f, cx, y, cor, pedaco);
        cx += texto_largura(f, pedaco);
      }
      np = 0;
      if (!*p)
        break;
      float tam = lh * 0.92f;
      float w = lh * MARCAS[ind].largura;
      if (desenhar)
        icone_natural(r, MARCAS[ind].ic, cx + w / 2 + 2, y + lh * 0.52f, tam, 0);
      cx += w + 4;
      p += n - 1;
      continue;
    }
    if (np < sizeof(pedaco) - 1)
      pedaco[np++] = *p;
  }
  return cx - x;
}

float wg_texto_rico_largura(int fonte, const char *s) { return rico(NULL, (Fonte)fonte, 0, 0, COR_TEXTO, s, false); }

float wg_texto_rico(SDL_Renderer *r, int fonte, float x, float y, SDL_Color cor, int alinhamento, const char *s) {
  float w = wg_texto_rico_largura(fonte, s);
  float xx = alinhamento == ALINHA_CENTRO ? x - w / 2 : alinhamento == ALINHA_DIR ? x - w : x;
  return rico(r, (Fonte)fonte, xx, y, cor, s, true);
}
