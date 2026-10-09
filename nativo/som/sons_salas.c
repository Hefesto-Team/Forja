/* Os sons das salas de som. Ver sons_salas.h. */
#include "sons_salas.h"

#include "sintese.h"

#include <stddef.h>
#include <stdlib.h>

static SonsSalas g_sons;
static bool g_prontos;

/* O buffer da síntese é do malloc da libc; o mixer libera com SDL_free.
 * Copia para um buffer do SDL e devolve o original. */
static void som_de_onda(Som *dst, Onda *o) {
  dst->amostras = SDL_malloc(sizeof(float) * (size_t)(o->n > 0 ? o->n : 1));
  dst->n = 0;
  if (dst->amostras && o->a) {
    SDL_memcpy(dst->amostras, o->a, sizeof(float) * (size_t)o->n);
    dst->n = o->n;
  }
  onda_liberar(o);
}

const SonsSalas *sons_salas(void) {
  if (g_prontos)
    return &g_sons;
  Onda o = {0};
  sint_bigorna(&o, 1046.5f, 0.9f, 1.2f, 21);
  som_de_onda(&g_sons.sino, &o);
  sint_pulso(&o, 120.0f, 0.12f, 2, 0.18f);
  som_de_onda(&g_sons.pulso, &o);
  sint_bigorna(&o, 784.0f, 0.42f, 1.1f, 23);
  som_de_onda(&g_sons.nota, &o);
  sint_bigorna(&o, 1174.7f, 0.42f, 1.2f, 29);
  som_de_onda(&g_sons.nota_alta, &o);
  sint_grito(&o, 0.9f, 31);
  som_de_onda(&g_sons.grito, &o);
  sint_pulso(&o, 90.0f, 0.16f, 1, 0.2f);
  som_de_onda(&g_sons.tropeco, &o);
  sint_blip(&o, 2400.0f, 0.02f);
  som_de_onda(&g_sons.clique, &o);
  sint_bigorna(&o, 1568.0f, 0.5f, 1.3f, 37);
  som_de_onda(&g_sons.pronto, &o);
  sint_tom(&o, 1000.0f, 1.0f, 0.01f);
  som_de_onda(&g_sons.tom, &o);
  for (int c = 0; c < 4; c++)
    for (int v = 0; v < SONS_PASSOS_VARIANTES; v++) {
      sint_passo(&o, c, (uint32_t)(100 + c * 10 + v));
      som_de_onda(&g_sons.passo[c][v], &o);
    }
  /* o pio de cada boneco: uma escala pentatônica a partir do dó 5 */
  static const float PIO_HZ[SONS_PIOS] = {523.25f, 587.33f, 659.25f, 783.99f, 880.0f, 1046.5f,
                                          554.37f, 622.25f, 739.99f, 830.61f, 932.33f, 1108.7f};
  for (int k = 0; k < SONS_PIOS; k++) {
    sint_pio(&o, PIO_HZ[k], k % 2, 40u + (uint32_t)k);
    som_de_onda(&g_sons.pio[k], &o);
  }
  /* a nota de cada lugar (o hoqueto: dó, ré, fá, sol) e a mesma, quebrada */
  static const float NOTA_HZ[4] = {523.25f, 587.33f, 698.46f, 783.99f};
  for (int l = 0; l < 4; l++) {
    sint_bigorna(&o, NOTA_HZ[l], 0.42f, 1.1f, 50u + (uint32_t)l);
    som_de_onda(&g_sons.nota_lugar[l], &o);
    sint_bigorna(&o, NOTA_HZ[l] * 0.9659f, 0.2f, 0.4f, 60u + (uint32_t)l); /* 60 cents abaixo, curta e baça */
    som_de_onda(&g_sons.nota_quebrada[l], &o);
  }
  sint_pulso(&o, 2637.0f, 0.03f, 2, 0.06f);
  som_de_onda(&g_sons.coleta, &o);
  for (int m = 0; m < MATERIAL_TOTAL; m++) {
    sint_material(&o, (MaterialHaptico)m, 70u + (uint32_t)m);
    som_de_onda(&g_sons.material[m], &o);
  }
  g_prontos = true;
  return &g_sons;
}

const Som *sons_salas_por_nome(const char *nome) {
  if (!nome || !nome[0])
    return NULL;
  const SonsSalas *s = sons_salas();
  if (!SDL_strncmp(nome, "passo:", 6)) {
    char *fim = NULL;
    long chao = strtol(nome + 6, &fim, 10);
    long var = (fim && *fim == ':') ? strtol(fim + 1, NULL, 10) : 0;
    if (chao < 0 || chao > 3)
      return NULL;
    if (var < 0)
      var = -var;
    return &s->passo[chao][var % SONS_PASSOS_VARIANTES];
  }
  /* os que levam um número ou um nome depois dos dois pontos (H07) */
  if (!SDL_strncmp(nome, "pio:", 4)) {
    long k = strtol(nome + 4, NULL, 10);
    return k >= 0 && k < SONS_PIOS ? &s->pio[k] : NULL;
  }
  if (!SDL_strncmp(nome, "nota:", 5)) {
    long l = strtol(nome + 5, NULL, 10);
    return l >= 0 && l < 4 ? &s->nota_lugar[l] : NULL;
  }
  if (!SDL_strncmp(nome, "nota_quebrada:", 14)) {
    long l = strtol(nome + 14, NULL, 10);
    return l >= 0 && l < 4 ? &s->nota_quebrada[l] : NULL;
  }
  if (!SDL_strncmp(nome, "material:", 9)) {
    int m = material_por_nome(nome + 9);
    return m >= 0 ? &s->material[m] : NULL;
  }
  static const struct {
    const char *nome;
    size_t desloc;
  } TABELA[] = {
      {"sino", offsetof(SonsSalas, sino)},       {"pulso", offsetof(SonsSalas, pulso)},
      {"nota", offsetof(SonsSalas, nota)},       {"nota_alta", offsetof(SonsSalas, nota_alta)},
      {"grito", offsetof(SonsSalas, grito)},     {"tropeco", offsetof(SonsSalas, tropeco)},
      {"clique", offsetof(SonsSalas, clique)},   {"pronto", offsetof(SonsSalas, pronto)},
      {"tom", offsetof(SonsSalas, tom)},         {"coleta", offsetof(SonsSalas, coleta)},
  };
  for (size_t i = 0; i < sizeof(TABELA) / sizeof(TABELA[0]); i++)
    if (!SDL_strcmp(nome, TABELA[i].nome))
      return (const Som *)((const char *)s + TABELA[i].desloc);
  return NULL;
}

void sons_salas_liberar(void) {
  if (!g_prontos)
    return;
  som_liberar(&g_sons.sino);
  som_liberar(&g_sons.pulso);
  som_liberar(&g_sons.nota);
  som_liberar(&g_sons.nota_alta);
  som_liberar(&g_sons.grito);
  som_liberar(&g_sons.tropeco);
  som_liberar(&g_sons.clique);
  som_liberar(&g_sons.pronto);
  som_liberar(&g_sons.tom);
  for (int c = 0; c < 4; c++)
    for (int v = 0; v < SONS_PASSOS_VARIANTES; v++)
      som_liberar(&g_sons.passo[c][v]);
  for (int k = 0; k < SONS_PIOS; k++)
    som_liberar(&g_sons.pio[k]);
  for (int l = 0; l < 4; l++) {
    som_liberar(&g_sons.nota_lugar[l]);
    som_liberar(&g_sons.nota_quebrada[l]);
  }
  som_liberar(&g_sons.coleta);
  for (int m = 0; m < MATERIAL_TOTAL; m++)
    som_liberar(&g_sons.material[m]);
  g_prontos = false;
}
