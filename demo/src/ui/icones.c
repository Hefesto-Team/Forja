/* Os ícones. Ver icones.h. */
#include "icones.h"

#include "desenho.h"
#include "tema.h"
#include "texto.h"

#include <math.h>

#define PI_F 3.14159265f

/* As cores dos símbolos do DualSense, suavizadas para o fundo escuro. */
static const SDL_Color AZUL_CRUZ = {128, 170, 255, 255};
static const SDL_Color VERMELHO_CIRC = {255, 112, 112, 255};
static const SDL_Color VERDE_TRI = {72, 216, 170, 255};
static const SDL_Color ROSA_QUAD = {240, 142, 208, 255};

SDL_Color icone_cor_natural(Icone ic) {
  switch (ic) {
  case IC_CRUZ:
    return AZUL_CRUZ;
  case IC_CIRCULO:
    return VERMELHO_CIRC;
  case IC_TRIANGULO:
    return VERDE_TRI;
  case IC_QUADRADO:
    return ROSA_QUAD;
  case IC_OK:
    return COR_OK;
  case IC_FALHA:
    return COR_FALHA;
  case IC_NAO_MEDIDO:
    return COR_NEUTRO;
  case IC_AVISO:
    return COR_AVISO;
  case IC_BLUETOOTH:
    return (SDL_Color){110, 160, 255, 255};
  case IC_USB:
    return COR_TEXTO_2;
  case IC_VIRTUAL:
    return COR_OURO;
  default:
    return COR_TEXTO;
  }
}

static void rotulo(SDL_Renderer *r, float cx, float cy, float tam, SDL_Color c, const char *s) {
  Fonte f = tam >= 56 ? F_MEDIA_N : tam >= 38 ? F_TEXTO_N : tam >= 28 ? F_PEQUENA_N : F_MINI;
  texto_al(r, f, cx, cy - texto_altura(f) * 0.52f, c, ALINHA_CENTRO, s);
}

static void seta(SDL_Renderer *r, float cx, float cy, float s, float ang, SDL_Color c) {
  SDL_FPoint a = {cx + cosf(ang) * s, cy + sinf(ang) * s};
  SDL_FPoint b = {cx + cosf(ang + 2.4f) * s * 0.8f, cy + sinf(ang + 2.4f) * s * 0.8f};
  SDL_FPoint d = {cx + cosf(ang - 2.4f) * s * 0.8f, cy + sinf(ang - 2.4f) * s * 0.8f};
  ds_triangulo(r, a, b, d, c);
}

void icone(SDL_Renderer *r, Icone ic, float cx, float cy, float tam, SDL_Color cor, float aceso) {
  float R = tam / 2;
  float esp = fmaxf(2.0f, tam * 0.085f);
  SDL_Color fundo = cor_mistura(COR_CARVAO, cor_escurecer(cor, 0.55f), limitar(aceso, 0, 1));
  SDL_Color borda = cor_mistura(COR_BRONZE_ESCURO, cor, limitar(aceso, 0, 1) * 0.8f);
  switch (ic) {
  case IC_CRUZ:
  case IC_CIRCULO:
  case IC_QUADRADO:
  case IC_TRIANGULO:
  case IC_L3:
  case IC_R3:
  case IC_PS:
  case IC_ANALOGICO_E:
  case IC_ANALOGICO_D:
    if (aceso > 0)
      ds_brilho(r, cx, cy, R * 2.2f, cor, 0.35f * aceso);
    ds_circulo(r, cx, cy, R, fundo);
    ds_anel(r, cx, cy, R, fmaxf(1.5f, tam * 0.05f), borda);
    break;
  default:
    break;
  }
  switch (ic) {
  case IC_CRUZ: {
    float s = R * 0.42f;
    ds_linha(r, cx - s, cy - s, cx + s, cy + s, esp, cor);
    ds_linha(r, cx - s, cy + s, cx + s, cy - s, esp, cor);
    break;
  }
  case IC_CIRCULO:
    ds_anel(r, cx, cy, R * 0.48f, esp, cor);
    break;
  case IC_QUADRADO: {
    float s = R * 0.44f;
    ds_contorno_arred(r, cx - s, cy - s, 2 * s, 2 * s, 1, esp, cor);
    break;
  }
  case IC_TRIANGULO: {
    float s = R * 0.55f;
    SDL_FPoint p[3] = {{cx, cy - s}, {cx + s * 0.93f, cy + s * 0.58f}, {cx - s * 0.93f, cy + s * 0.58f}};
    ds_polilinha(r, p, 3, esp, cor, true);
    break;
  }
  case IC_L3:
    rotulo(r, cx, cy, tam, cor, "L3");
    break;
  case IC_R3:
    rotulo(r, cx, cy, tam, cor, "R3");
    break;
  case IC_PS:
    rotulo(r, cx, cy, tam, cor, "PS");
    break;
  case IC_ANALOGICO_E:
  case IC_ANALOGICO_D:
    /* o analógico: as quatro direções em volta e o topo com a letra do lado */
    for (int i = 0; i < 4; i++) {
      float ang = i * PI_F / 2;
      seta(r, cx + cosf(ang) * R * 0.78f, cy + sinf(ang) * R * 0.78f, R * 0.16f, ang, cor_alfa(cor, 0.8f));
    }
    ds_circulo(r, cx, cy, R * 0.5f, cor_alfa(cor, 0.9f));
    rotulo(r, cx, cy, tam * 0.62f, COR_CARVAO, ic == IC_ANALOGICO_E ? "L" : "R");
    break;
  case IC_L1:
  case IC_R1:
  case IC_L2:
  case IC_R2: {
    float w = tam * 1.25f, h = tam * (ic == IC_L2 || ic == IC_R2 ? 0.9f : 0.72f);
    if (aceso > 0)
      ds_brilho(r, cx, cy, w, cor, 0.3f * aceso);
    ds_ret_arred(r, cx - w / 2, cy - h / 2, w, h, h * (ic == IC_L2 || ic == IC_R2 ? 0.5f : 0.3f), fundo);
    ds_contorno_arred(r, cx - w / 2, cy - h / 2, w, h, h * 0.3f, fmaxf(1.5f, tam * 0.05f), borda);
    rotulo(r, cx, cy, tam * 0.9f, cor,
           ic == IC_L1 ? "L1" : ic == IC_R1 ? "R1" : ic == IC_L2 ? "L2" : "R2");
    break;
  }
  case IC_OPTIONS:
  case IC_CREATE: {
    float w = tam * 0.62f, h = tam * 0.9f;
    ds_ret_arred(r, cx - w / 2, cy - h / 2, w, h, w / 2, fundo);
    ds_contorno_arred(r, cx - w / 2, cy - h / 2, w, h, w / 2, fmaxf(1.5f, tam * 0.05f), borda);
    if (ic == IC_OPTIONS) {
      for (int i = -1; i <= 1; i++)
        ds_linha(r, cx - w * 0.22f, cy + i * h * 0.16f, cx + w * 0.22f, cy + i * h * 0.16f, esp * 0.7f, cor);
    } else {
      for (int i = -1; i <= 1; i++) {
        float a = -PI_F / 2 + i * 0.7f;
        ds_linha(r, cx + cosf(a) * h * 0.08f, cy + h * 0.12f + sinf(a) * h * 0.08f, cx + cosf(a) * h * 0.3f,
                 cy + h * 0.12f + sinf(a) * h * 0.3f, esp * 0.7f, cor);
      }
    }
    break;
  }
  case IC_TOUCHPAD: {
    float w = tam * 1.3f, h = tam * 0.78f;
    ds_ret_arred(r, cx - w / 2, cy - h / 2, w, h, h * 0.25f, fundo);
    ds_contorno_arred(r, cx - w / 2, cy - h / 2, w, h, h * 0.25f, fmaxf(1.5f, tam * 0.05f), borda);
    ds_circulo(r, cx + w * 0.12f, cy + h * 0.05f, tam * 0.1f, cor);
    ds_anel(r, cx + w * 0.12f, cy + h * 0.05f, tam * 0.2f, esp * 0.5f, cor_alfa(cor, 0.5f));
    break;
  }
  case IC_MIC:
  case IC_MICROFONE: {
    if (ic == IC_MIC) {
      ds_circulo(r, cx, cy, R, fundo);
      ds_anel(r, cx, cy, R, fmaxf(1.5f, tam * 0.05f), borda);
    }
    float w = tam * 0.24f, h = tam * 0.4f;
    ds_ret_arred(r, cx - w / 2, cy - h * 0.72f, w, h, w / 2, cor);
    ds_arco(r, cx, cy - h * 0.12f, w * 0.95f, esp * 0.7f, 0.15f, PI_F - 0.15f, cor);
    ds_linha(r, cx, cy + w * 0.8f, cx, cy + h * 0.62f, esp * 0.7f, cor);
    break;
  }
  case IC_DPAD:
  case IC_DPAD_CIMA:
  case IC_DPAD_BAIXO:
  case IC_DPAD_ESQ:
  case IC_DPAD_DIR: {
    float b = tam * 0.32f, L = tam * 0.5f;
    /* a cruz inteira sempre aparece (num tom do ícone), e a seta pedida acende:
     * pequeno, um braço aceso sozinho vira um tracinho sem sentido */
    SDL_Color base = ic == IC_DPAD ? fundo : cor_mistura(COR_CARVAO, cor, 0.28f), acende = cor;
    SDL_Color c_cima = ic == IC_DPAD_CIMA ? acende : base, c_baixo = ic == IC_DPAD_BAIXO ? acende : base;
    SDL_Color c_esq = ic == IC_DPAD_ESQ ? acende : base, c_dir = ic == IC_DPAD_DIR ? acende : base;
    ds_ret(r, cx - b / 2, cy - b / 2, b, b, base);
    ds_ret_arred(r, cx - b / 2, cy - L, b, L - b * 0.2f, b * 0.2f, c_cima);
    ds_ret_arred(r, cx - b / 2, cy + b * 0.2f, b, L - b * 0.2f, b * 0.2f, c_baixo);
    ds_ret_arred(r, cx - L, cy - b / 2, L - b * 0.2f, b, b * 0.2f, c_esq);
    ds_ret_arred(r, cx + b * 0.2f, cy - b / 2, L - b * 0.2f, b, b * 0.2f, c_dir);
    ds_contorno_arred(r, cx - b / 2, cy - L, b, 2 * L, b * 0.2f, fmaxf(1.2f, tam * 0.03f), borda);
    ds_contorno_arred(r, cx - L, cy - b / 2, 2 * L, b, b * 0.2f, fmaxf(1.2f, tam * 0.03f), borda);
    if (ic != IC_DPAD) {
      /* a ponta da seta no braço aceso, na cor do fundo */
      float ang = ic == IC_DPAD_CIMA ? -PI_F / 2 : ic == IC_DPAD_BAIXO ? PI_F / 2 : ic == IC_DPAD_ESQ ? PI_F : 0;
      seta(r, cx + cosf(ang) * L * 0.55f, cy + sinf(ang) * L * 0.55f, b * 0.36f, ang, COR_CARVAO);
    }
    break;
  }
  case IC_OK: {
    SDL_FPoint p[3] = {{cx - R * 0.5f, cy + R * 0.02f}, {cx - R * 0.12f, cy + R * 0.4f}, {cx + R * 0.55f, cy - R * 0.38f}};
    ds_polilinha(r, p, 3, esp * 1.3f, cor, false);
    break;
  }
  case IC_FALHA: {
    float s = R * 0.42f;
    ds_linha(r, cx - s, cy - s, cx + s, cy + s, esp * 1.3f, cor);
    ds_linha(r, cx - s, cy + s, cx + s, cy - s, esp * 1.3f, cor);
    break;
  }
  case IC_NAO_MEDIDO:
    ds_linha(r, cx - R * 0.45f, cy, cx + R * 0.45f, cy, esp * 1.3f, cor);
    break;
  case IC_USB: {
    float h = R * 0.85f;
    ds_linha(r, cx, cy + h, cx, cy - h * 0.6f, esp, cor);
    seta(r, cx, cy - h * 0.72f, R * 0.3f, -PI_F / 2, cor);
    ds_linha(r, cx, cy + h * 0.25f, cx - R * 0.42f, cy - h * 0.05f, esp * 0.8f, cor);
    ds_linha(r, cx - R * 0.42f, cy - h * 0.05f, cx - R * 0.42f, cy - h * 0.3f, esp * 0.8f, cor);
    ds_circulo(r, cx - R * 0.42f, cy - h * 0.36f, R * 0.12f, cor);
    ds_linha(r, cx, cy + h * 0.45f, cx + R * 0.42f, cy + h * 0.15f, esp * 0.8f, cor);
    ds_linha(r, cx + R * 0.42f, cy + h * 0.15f, cx + R * 0.42f, cy - h * 0.12f, esp * 0.8f, cor);
    ds_ret(r, cx + R * 0.32f, cy - h * 0.32f, R * 0.2f, R * 0.2f, cor);
    ds_circulo(r, cx, cy + h, R * 0.16f, cor);
    break;
  }
  case IC_BLUETOOTH: {
    float s = R * 0.9f;
    SDL_FPoint p[6] = {{cx - s * 0.38f, cy + s * 0.3f}, {cx + s * 0.36f, cy - s * 0.3f}, {cx, cy - s * 0.7f},
                       {cx, cy + s * 0.7f},            {cx + s * 0.36f, cy + s * 0.3f}, {cx - s * 0.38f, cy - s * 0.3f}};
    ds_polilinha(r, p, 6, esp, cor, false);
    break;
  }
  case IC_VIRTUAL: {
    float s = R * 0.5f;
    ds_contorno_arred(r, cx - s - R * 0.12f, cy - s + R * 0.12f, 2 * s, 2 * s, s * 0.35f, esp * 0.8f,
                      cor_alfa(cor, 0.55f));
    ds_contorno_arred(r, cx - s + R * 0.12f, cy - s - R * 0.12f, 2 * s, 2 * s, s * 0.35f, esp * 0.8f, cor);
    break;
  }
  case IC_ALTO_FALANTE: {
    float s = R * 0.5f;
    SDL_FPoint corpo[6] = {{cx - s * 1.1f, cy - s * 0.4f}, {cx - s * 0.45f, cy - s * 0.4f}, {cx + s * 0.25f, cy - s * 1.0f},
                           {cx + s * 0.25f, cy + s * 1.0f}, {cx - s * 0.45f, cy + s * 0.4f}, {cx - s * 1.1f, cy + s * 0.4f}};
    ds_poligono(r, corpo, 6, cor);
    ds_arco(r, cx + s * 0.35f, cy, s * 0.75f, esp * 0.8f, -0.8f, 0.8f, cor);
    ds_arco(r, cx + s * 0.35f, cy, s * 1.3f, esp * 0.8f, -0.8f, 0.8f, cor_alfa(cor, 0.7f));
    break;
  }
  case IC_VIBRACAO: {
    float w = R * 0.55f, h = R * 0.95f;
    ds_contorno_arred(r, cx - w / 2, cy - h / 2, w, h, w * 0.25f, esp * 0.8f, cor);
    for (int lado = -1; lado <= 1; lado += 2)
      for (int k = 0; k < 2; k++) {
        float x = cx + lado * (w / 2 + R * (0.18f + 0.18f * k));
        ds_arco(r, cx, cy, fabsf(x - cx), esp * 0.7f, lado > 0 ? -0.5f : PI_F - 0.5f,
                lado > 0 ? 0.5f : PI_F + 0.5f, cor_alfa(cor, 1 - 0.35f * k));
      }
    break;
  }
  case IC_GATILHO: {
    SDL_FPoint p[5] = {{cx - R * 0.45f, cy + R * 0.6f}, {cx - R * 0.45f, cy - R * 0.2f}, {cx - R * 0.1f, cy - R * 0.62f},
                       {cx + R * 0.5f, cy - R * 0.62f}, {cx + R * 0.1f, cy + R * 0.6f}};
    ds_polilinha(r, p, 5, esp, cor, true);
    break;
  }
  case IC_LUZ: {
    ds_circulo(r, cx, cy, R * 0.28f, cor);
    for (int i = 0; i < 8; i++) {
      float a = i * PI_F / 4;
      ds_linha(r, cx + cosf(a) * R * 0.45f, cy + sinf(a) * R * 0.45f, cx + cosf(a) * R * 0.72f,
               cy + sinf(a) * R * 0.72f, esp * 0.8f, cor);
    }
    break;
  }
  case IC_GIRO: {
    ds_arco(r, cx, cy, R * 0.62f, esp, -PI_F * 0.9f, PI_F * 0.45f, cor);
    seta(r, cx + cosf(PI_F * 0.45f) * R * 0.58f, cy + sinf(PI_F * 0.45f) * R * 0.58f, R * 0.28f, PI_F * 0.95f, cor);
    ds_circulo(r, cx, cy, R * 0.14f, cor);
    break;
  }
  case IC_TOQUE: {
    ds_circulo(r, cx, cy, R * 0.2f, cor);
    ds_anel(r, cx, cy, R * 0.45f, esp * 0.7f, cor_alfa(cor, 0.7f));
    ds_anel(r, cx, cy, R * 0.72f, esp * 0.6f, cor_alfa(cor, 0.4f));
    break;
  }
  case IC_BATERIA: {
    float w = R * 1.3f, h = R * 0.7f;
    ds_contorno_arred(r, cx - w / 2, cy - h / 2, w, h, h * 0.2f, esp * 0.8f, cor);
    ds_ret(r, cx + w / 2, cy - h * 0.2f, R * 0.12f, h * 0.4f, cor);
    ds_ret(r, cx - w / 2 + esp * 1.6f, cy - h / 2 + esp * 1.6f, (w - esp * 3.2f) * limitar(aceso, 0, 1),
           h - esp * 3.2f, cor);
    break;
  }
  case IC_AVISO: {
    float s = R * 0.85f;
    SDL_FPoint p[3] = {{cx, cy - s}, {cx + s, cy + s * 0.75f}, {cx - s, cy + s * 0.75f}};
    ds_polilinha(r, p, 3, esp, cor, true);
    ds_linha(r, cx, cy - s * 0.35f, cx, cy + s * 0.2f, esp, cor);
    ds_circulo(r, cx, cy + s * 0.45f, esp * 0.6f, cor);
    break;
  }
  case IC_MARTELO: {
    float s = R;
    SDL_FPoint cabo[4] = {{cx - s * 0.12f, cy - s * 0.1f}, {cx + s * 0.06f, cy - s * 0.1f}, {cx + s * 0.1f, cy + s * 0.85f},
                          {cx - s * 0.16f, cy + s * 0.85f}};
    ds_poligono(r, cabo, 4, cor_escurecer(cor, 0.3f));
    ds_ret_arred(r, cx - s * 0.6f, cy - s * 0.62f, s * 1.1f, s * 0.46f, s * 0.08f, cor);
    break;
  }
  case IC_CADEADO: {
    float w = R * 0.9f, h = R * 0.7f;
    ds_arco(r, cx, cy - h * 0.15f, w * 0.32f, esp, PI_F, 2 * PI_F, cor);
    ds_ret_arred(r, cx - w / 2, cy - h * 0.1f, w, h, R * 0.12f, cor);
    break;
  }
  case IC_CHAMA: {
    SDL_FPoint p[9] = {{cx, cy - R * 0.8f},          {cx + R * 0.32f, cy - R * 0.25f}, {cx + R * 0.5f, cy + R * 0.15f},
                       {cx + R * 0.38f, cy + R * 0.55f}, {cx, cy + R * 0.75f},           {cx - R * 0.38f, cy + R * 0.55f},
                       {cx - R * 0.5f, cy + R * 0.15f}, {cx - R * 0.3f, cy - R * 0.2f},  {cx - R * 0.08f, cy - R * 0.02f}};
    ds_poligono(r, p, 9, cor);
    SDL_FPoint q[5] = {{cx, cy - R * 0.1f}, {cx + R * 0.2f, cy + R * 0.3f}, {cx, cy + R * 0.58f},
                       {cx - R * 0.2f, cy + R * 0.3f}, {cx - R * 0.02f, cy + R * 0.12f}};
    ds_poligono(r, q, 5, cor_escurecer(cor, 0.45f));
    break;
  }
  default:
    break;
  }
}

void icone_natural(SDL_Renderer *r, Icone ic, float cx, float cy, float tam, float aceso) {
  icone(r, ic, cx, cy, tam, icone_cor_natural(ic), aceso);
}

float icone_dica(SDL_Renderer *r, Icone ic, float x, float cy, const char *s, SDL_Color cor) {
  float tam = 34;
  float w_ic = (ic >= IC_L1 && ic <= IC_R2) || ic == IC_TOUCHPAD ? tam * 1.3f : tam;
  icone_natural(r, ic, x + w_ic / 2, cy, tam, 0);
  float w = texto(r, F_TEXTO, x + w_ic + 10, cy - texto_altura(F_TEXTO) * 0.5f, cor, s);
  return w_ic + 10 + w;
}
