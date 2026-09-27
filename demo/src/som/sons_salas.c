/* Os sons das salas de som. Ver sons_salas.h. */
#include "sons_salas.h"

#include "sintese.h"
#include "sistema.h"

static SonsSalas g_sons;
static bool g_prontos;

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
  for (int c = 0; c < 4; c++)
    for (int v = 0; v < SONS_PASSOS_VARIANTES; v++) {
      sint_passo(&o, c, (uint32_t)(100 + c * 10 + v));
      som_de_onda(&g_sons.passo[c][v], &o);
    }
  g_prontos = true;
  return &g_sons;
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
  for (int c = 0; c < 4; c++)
    for (int v = 0; v < SONS_PASSOS_VARIANTES; v++)
      som_liberar(&g_sons.passo[c][v]);
  g_prontos = false;
}
