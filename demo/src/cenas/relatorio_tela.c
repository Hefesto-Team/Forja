/* O livro: a matriz da sessão — cada feature, cada controle, o veredito — e o
 * detalhe da linha escolhida: o que foi pedido, o que foi medido. Os arquivos
 * (JSON, texto, registro e linha do tempo) já estão gravados; ✕ grava de novo. */
#include "../app.h"

#include "../nucleo/simulador.h"
#include "../ui/desenho.h"
#include "../ui/icones.h"
#include "../ui/tema.h"
#include "../ui/texto.h"
#include "../ui/widgets.h"

static int g_linha;
static float g_robo;

static void entrar(App *a) {
  g_linha = 0;
  g_robo = 0;
  app_salvar_relatorio(a);
  som_ambiente(&a->som, true, false);
}

static void sair(App *a) { (void)a; }

static void atualizar(App *a, float dt) {
  Nav *n = &a->nav;
  if (n->cima)
    g_linha = (g_linha + F_TOTAL - 1) % F_TOTAL;
  if (n->baixo)
    g_linha = (g_linha + 1) % F_TOTAL;
  if (n->confirma) {
    bool ok = app_salvar_relatorio(a);
    som_evento(&a->som, ok ? SOM_CONFIRMA : SOM_FALHA, 0.6f);
    app_avisar(a, ok ? "Relatório gravado" : "Não consegui gravar o relatório");
  }
  bool voltar = n->volta || n->opcoes;
  if (robo_ativo()) {
    g_robo += dt;
    if (g_robo > 2.5f) {
      /* o robô leu o livro: a sessão simulada termina aqui */
      a->rodando = false;
    }
  }
  if (voltar) {
    som_evento(&a->som, SOM_VOLTA, 0.6f);
    const Cena *volta = a->anterior && a->anterior != &CENA_RELATORIO ? a->anterior : &CENA_TITULO;
    if (volta != &CENA_HUB && volta != &CENA_TITULO && volta != &CENA_LOBBY && volta != &CENA_DIAGNOSTICO)
      volta = pads_jogadores(a) ? &CENA_HUB : &CENA_TITULO;
    app_trocar_cena(a, volta);
  }
}

static void desenhar(App *a) {
  SDL_Renderer *r = a->r;
  ds_fundo(r, a->t, 0.5f);
  wg_cabecalho(r, "O LIVRO", "O relatório da sessão: o último veredito de cada feature, por controle.", a->t);

  int cols[MAX_JOGADORES], nc = 0;
  for (int s = 0; s < MAX_JOGADORES; s++)
    if (a->rel.controles[s].presente)
      cols[nc++] = s;

  float x0 = 150, y0 = 190, wn = 460, wc = 190, lh = 34;
  wg_painel(r, x0 - 30, y0 - 20, wn + 4 * wc + 60, F_TOTAL * lh + 80, COR_BRONZE, 0);
  texto(r, F_PEQUENA_N, x0, y0, COR_BRONZE_CLARO, "FEATURE · SALA");
  for (int c = 0; c < nc; c++) {
    int s = cols[c];
    texto_al(r, F_PEQUENA_N, x0 + wn + c * wc + wc / 2, y0, COR_JOGADOR[s], ALINHA_CENTRO, fmt("P%d", s + 1));
  }
  if (!nc)
    texto(r, F_PEQUENA, x0 + wn, y0, COR_TEXTO_3, "ninguém entrou na mesa");
  for (int f = 0; f < F_TOTAL; f++) {
    float y = y0 + 40 + f * lh;
    const InfoFeature *inf = catalogo_feature((Feature)f);
    if (f == g_linha)
      ds_ret_arred(r, x0 - 16, y - 4, wn + 4 * wc + 30, lh, 8, cor_alfa(COR_BRASA, 0.16f));
    texto(r, F_PEQUENA, x0, y, f == g_linha ? COR_TEXTO : COR_TEXTO_2,
          fmt("%s · %s", inf->nome, catalogo_sala(inf->sala)->nome));
    for (int c = 0; c < nc; c++) {
      const RelItem *it = rel_ultimo(&a->rel, cols[c] + 1, (Feature)f);
      Resultado res = it ? it->resultado : RES_NAO_MEDIDO;
      Icone ic = res == RES_PASSOU ? IC_OK : res == RES_FALHOU ? IC_FALHA : IC_NAO_MEDIDO;
      icone_natural(r, ic, x0 + wn + c * wc + wc / 2, y + lh / 2 - 4, 30, 0);
    }
  }

  /* o detalhe da linha escolhida */
  float dx = x0 + wn + 4 * wc + 70, dy = y0 - 20, dw = TELA_L - dx - 60, dh = F_TOTAL * lh + 80;
  wg_painel(r, dx, dy, dw, dh, COR_BRASA, 0.3f);
  const InfoFeature *inf = catalogo_feature((Feature)g_linha);
  texto(r, F_MEDIA_N, dx + 28, dy + 24, COR_OURO, inf->nome);
  float yy = dy + 68;
  yy += texto_bloco(r, F_PEQUENA, dx + 28, yy, dw - 56, COR_TEXTO_2, ALINHA_ESQ, 1.05f, true,
                    fmt("sala: %s — %s", catalogo_sala(inf->sala)->nome, catalogo_sala(inf->sala)->padrao));
  yy += 16;
  for (int c = 0; c < nc && yy < dy + dh - 80; c++) {
    int s = cols[c];
    const RelItem *it = rel_ultimo(&a->rel, s + 1, (Feature)g_linha);
    wg_escudo_jogador(r, dx + 44, yy + 22, 36, s, true);
    if (!it) {
      texto(r, F_PEQUENA, dx + 80, yy + 8, COR_TEXTO_3, "não medido — a sala não foi jogada");
      yy += 60;
      continue;
    }
    wg_selo(r, dx + 180, yy + 20, it->resultado, 0.8f);
    yy += 50;
    yy += texto_bloco(r, F_MINI, dx + 80, yy, dw - 110, COR_TEXTO_2, ALINHA_ESQ, 1.05f, true, fmt("pedido: %s", it->pedido));
    yy += texto_bloco(r, F_MINI, dx + 80, yy, dw - 110, COR_TEXTO, ALINHA_ESQ, 1.05f, true, fmt("medido: %s", it->medido));
    if (it->observacao[0])
      yy += texto_bloco(r, F_MINI, dx + 80, yy, dw - 110, COR_TEXTO_3, ALINHA_ESQ, 1.05f, true, fmt("obs.: %s", it->observacao));
    yy += 14;
  }

  texto_al(r, F_MINI, TELA_L / 2.0f, TELA_A - 104, COR_TEXTO_3, ALINHA_CENTRO,
           fmt("gravado como relatorio-%s.json e .txt, com o registro e a linha do tempo, na pasta relatorios/", a->base_arquivos));
  Dica d[] = {{IC_DPAD, "linha"}, {IC_CRUZ, "gravar de novo"}, {IC_CIRCULO, "voltar"}};
  wg_rodape(r, d, 3);
}

const Cena CENA_RELATORIO = {"livro", entrar, sair, NULL, atualizar, desenhar};
