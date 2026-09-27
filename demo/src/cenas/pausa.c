/* A pausa. Ver pausa.h. */
#include "pausa.h"

#include "../app.h"
#include "../ui/desenho.h"
#include "../ui/tema.h"
#include "../ui/texto.h"
#include "../ui/widgets.h"

typedef enum Item {
  IT_CONTINUAR,
  IT_REFAZER,
  IT_ABANDONAR,
  IT_DIAGNOSTICO,
  IT_RELATORIO,
  IT_MOVIMENTO,
  IT_LEGENDAS,
  IT_INTENSIDADE,
  IT_TITULO,
  IT_SAIR,
  IT_TOTAL
} Item;

static bool g_aberta, g_em_sala;
static int g_sel, g_quem;
static float g_t;

static bool visivel(Item i) { return g_em_sala || (i != IT_REFAZER && i != IT_ABANDONAR); }

void pausa_abrir(App *a, bool em_sala, int quem) {
  g_aberta = true;
  g_em_sala = em_sala;
  g_sel = IT_CONTINUAR;
  g_quem = quem;
  g_t = 0;
  som_evento(&a->som, SOM_NAVEGA, 0.6f);
  reg_linha(&a->reg, "pausa (%s)", pads_rotulo_slot(quem));
}

bool pausa_aberta(void) { return g_aberta; }

static void mover(int d) {
  for (int k = 0; k < IT_TOTAL; k++) {
    g_sel = (g_sel + d + IT_TOTAL) % IT_TOTAL;
    if (visivel((Item)g_sel))
      return;
  }
}

PausaAcao pausa_atualizar(App *a) {
  if (!g_aberta)
    return PAUSA_NADA;
  g_t += a->dt;
  Nav *n = &a->nav;
  if (n->cima) {
    mover(-1);
    som_evento(&a->som, SOM_NAVEGA, 0.4f);
  }
  if (n->baixo) {
    mover(1);
    som_evento(&a->som, SOM_NAVEGA, 0.4f);
  }
  if ((n->esq || n->dir) && g_sel == IT_INTENSIDADE) {
    a->cfg.intensidade = limitar(a->cfg.intensidade + (n->dir ? 0.1f : -0.1f), 0.0f, 1.0f);
    som_evento(&a->som, SOM_TICK, 0.5f);
  }
  if (n->volta || n->opcoes) {
    g_aberta = false;
    return PAUSA_CONTINUAR;
  }
  if (!n->confirma)
    return PAUSA_NADA;
  som_evento(&a->som, SOM_CONFIRMA, 0.5f);
  switch ((Item)g_sel) {
  case IT_MOVIMENTO:
    a->cfg.reduzir_movimento = !a->cfg.reduzir_movimento;
    a->brasas.taxa = a->cfg.reduzir_movimento ? 4 : 18;
    return PAUSA_NADA;
  case IT_LEGENDAS:
    a->cfg.legendas = !a->cfg.legendas;
    return PAUSA_NADA;
  case IT_INTENSIDADE:
    return PAUSA_NADA;
  default:
    break;
  }
  g_aberta = false;
  switch ((Item)g_sel) {
  case IT_CONTINUAR:
    return PAUSA_CONTINUAR;
  case IT_REFAZER:
    return PAUSA_REFAZER;
  case IT_ABANDONAR:
    return PAUSA_ABANDONAR;
  case IT_DIAGNOSTICO:
    return PAUSA_DIAGNOSTICO;
  case IT_RELATORIO:
    return PAUSA_RELATORIO;
  case IT_TITULO:
    return PAUSA_TITULO;
  case IT_SAIR:
    return PAUSA_SAIR;
  default:
    return PAUSA_NADA;
  }
}

void pausa_desenhar(App *a) {
  if (!g_aberta)
    return;
  SDL_Renderer *r = a->r;
  float e = sai_rapido(g_t / 0.25f);
  ds_ret(r, 0, 0, TELA_L, TELA_A, (SDL_Color){6, 4, 3, (Uint8)(190 * e)});
  float w = 720, h = 760, x = TELA_L / 2 - w / 2, y = TELA_A / 2 - h / 2 + (1 - e) * 40;
  SDL_Color acento = g_quem >= 0 ? COR_JOGADOR[g_quem] : COR_BRONZE;
  wg_painel(r, x, y, w, h, acento, 0.6f);
  texto_espacado(r, F_TITULO, TELA_L / 2.0f, y + 26, COR_OURO, ALINHA_CENTRO, 6, "PAUSA");
  if (g_quem >= 0)
    texto_al(r, F_PEQUENA, TELA_L / 2.0f, y + 104, COR_TEXTO_2, ALINHA_CENTRO, fmt("pedida por %s", pads_rotulo_slot(g_quem)));
  const char *rot[IT_TOTAL] = {"Continuar",
                               "Refazer a sala",
                               "Voltar ao salão",
                               "A bancada (diagnóstico)",
                               "O livro (relatório)",
                               fmt("Reduzir movimento: %s", a->cfg.reduzir_movimento ? "sim" : "não"),
                               fmt("Legendas do som: %s", a->cfg.legendas ? "sim" : "não"),
                               fmt("Intensidade da vibração: %d%%", (int)(a->cfg.intensidade * 100 + 0.5f)),
                               "Voltar ao título",
                               "Sair do jogo"};
  float iy = y + 146;
  for (int i = 0; i < IT_TOTAL; i++) {
    if (!visivel((Item)i))
      continue;
    bool sel = g_sel == i;
    if (sel) {
      ds_ret_arred(r, x + 40, iy - 4, w - 80, 50, 10, cor_alfa(COR_BRASA, 0.18f));
      ds_contorno_arred(r, x + 40, iy - 4, w - 80, 50, 10, 2, COR_BRASA);
    }
    texto_al(r, sel ? F_MEDIA_N : F_MEDIA, TELA_L / 2.0f, iy, sel ? COR_TEXTO : COR_TEXTO_2, ALINHA_CENTRO, rot[i]);
    iy += 56;
  }
  Dica d[] = {{IC_DPAD, "escolher"}, {IC_CRUZ, "confirmar"}, {IC_CIRCULO, "continuar"}};
  wg_rodape(r, d, 3);
}
