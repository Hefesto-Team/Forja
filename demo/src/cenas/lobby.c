/* O lobby: quatro lugares à mesa, e o cartão que diz como cada controle
 * chegou — nome, VID:PID, cabo ou rádio, nativo ou virtual.
 *
 * Sprint 1 da Forja: "Join P1–P4: plugou = slot, LED jogador 4/10/21/27,
 * lightbar da cor"; "Falha visível e curta: «P3 sem controle»". */
#include "../app.h"

#include "../nucleo/simulador.h"
#include "../ui/controle.h"
#include "../ui/desenho.h"
#include "../ui/icones.h"
#include "../ui/tema.h"
#include "../ui/texto.h"
#include "../ui/widgets.h"

#include <math.h>

static float g_entrada[MAX_JOGADORES]; /* animação de quem acabou de entrar */
static float g_robo_prox;

static void entrar(App *a) {
  a->brasas.taxa = 16;
  for (int s = 0; s < MAX_JOGADORES; s++)
    g_entrada[s] = pads_do_slot(a, s) ? 1 : 0;
  g_robo_prox = 0.6f;
  som_ambiente(&a->som, true, true);
}

static void sair(App *a) { (void)a; }

static void comecar(App *a) {
  som_evento(&a->som, SOM_SUCESSO, 0.6f);
  reg_linha(&a->reg, "a mesa fechou com %d jogador(es)", pads_jogadores(a));
  if (a->sala_direta >= 0) {
    int s = a->sala_direta;
    a->sala_direta = -1;
    a->robo_sala_unica = robo_ativo();
    hub_abrir_sala(a, s);
    return;
  }
  if (a->modo_jogo == 1) {
    hub_comecar_gauntlet(a);
    return;
  }
  app_trocar_cena(a, &CENA_HUB);
}

static void atualizar(App *a, float dt) {
  for (int s = 0; s < MAX_JOGADORES; s++)
    g_entrada[s] = aproximar(g_entrada[s], pads_do_slot(a, s) ? 1.0f : 0.0f, 6, dt);

  /* ✕ num controle fora da mesa: entra */
  for (int i = 0; i < MAX_PADS; i++) {
    Pad *p = &a->pads.pad[i];
    if (!p->usado || p->slot >= 0)
      continue;
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_SOUTH)) {
      int s = pads_entrar(a, i);
      if (s >= 0) {
        g_entrada[s] = 0;
        som_evento_pan(&a->som, SOM_ENTROU, 0.8f, -0.75f + 0.5f * s);
        particulas_brasas(&a->brasas, 270 + s * 460, 520, 24, COR_JOGADOR[s]);
        /* a luz da entrada: três piscadas na cor do lugar */
        pad_rumble(a, p, 0.35f, 0.2f, 180);
      }
    }
  }
  /* ○ num controle da mesa: sai; Options: começa */
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Pad *p = pads_do_slot(a, s);
    if (!p)
      continue;
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_EAST)) {
      pads_sair(a, s);
      som_evento(&a->som, SOM_VOLTA, 0.6f);
      continue;
    }
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_START)) {
      comecar(a);
      return;
    }
  }
  /* o teclado sem controle: Enter começa (se houver alguém), Esc volta */
  if (a->nav.quem < 0) {
    if (a->nav.volta && !simulador_ativo())
      app_trocar_cena(a, &CENA_TITULO);
    if (a->nav.opcoes && pads_jogadores(a) > 0)
      comecar(a);
  }

  /* o robô: cada controle simulado entra, e o primeiro começa */
  if (robo_ativo()) {
    g_robo_prox -= dt;
    if (g_robo_prox <= 0) {
      g_robo_prox = 0.45f;
      int fora = -1;
      for (int i = 0; i < MAX_PADS; i++)
        if (a->pads.pad[i].usado && a->pads.pad[i].slot < 0 && a->pads.pad[i].espelho_de < 0) {
          fora = i;
          break;
        }
      if (fora >= 0) {
        robo_apertar(a, fora, SDL_GAMEPAD_BUTTON_SOUTH, 0.1f);
      } else if (pads_jogadores(a) > 0) {
        Pad *p = pads_do_slot(a, 0);
        if (p)
          robo_apertar(a, (int)(p - a->pads.pad), SDL_GAMEPAD_BUTTON_START, 0.1f);
        g_robo_prox = 2.0f;
      }
    }
  }
}

static void chips_do_pad(SDL_Renderer *r, const Pad *p, float x, float y, float largura) {
  float cx = x;
  Icone ic_con = p->origem.conexao == CONEXAO_BT ? IC_BLUETOOTH
                 : p->origem.conexao == CONEXAO_USB ? IC_USB
                                                    : IC_VIRTUAL;
  const char *con = p->origem.conexao == CONEXAO_BT       ? "RÁDIO"
                    : p->origem.conexao == CONEXAO_USB    ? "CABO USB"
                    : p->origem.conexao == CONEXAO_VIRTUAL_USB ? "DECLARA USB"
                    : p->simulado                          ? "SIMULADO"
                                                           : "VIRTUAL";
  SDL_Color c_con = p->origem.conexao == CONEXAO_BT ? icone_cor_natural(IC_BLUETOOTH) : COR_TEXTO_2;
  cx += wg_chip(r, cx, y, ic_con, con, c_con, false) + 10;
  const char *orig = p->simulado ? "SDL VIRTUAL" : origem_rotulo_curto(p->origem.tipo);
  SDL_Color c_orig = origem_eh_virtual(p->origem.tipo) || p->simulado ? COR_OURO : COR_OK;
  if (cx + wg_chip_largura(IC_TOTAL, orig) > x + largura) {
    cx = x;
    y += 46;
  }
  wg_chip(r, cx, y, IC_TOTAL, orig, c_orig, false);
}

static void cartao(App *a, int s, float x, float y, float w, float h) {
  SDL_Renderer *r = a->r;
  Slot *sl = &a->pads.slot[s];
  Pad *p = pads_do_slot(a, s);
  SDL_Color cj = COR_JOGADOR[s];
  float e = g_entrada[s];
  wg_painel(r, x, y, w, h, cj, p ? 0.5f + 0.5f * e : 0.0f);
  wg_escudo_jogador(r, x + 60, y + 64, 64, s, p != NULL);
  if (!sl->ocupado) {
    texto(r, F_GRANDE_N, x + 108, y + 38, cor_alfa(COR_TEXTO_2, 0.8f), fmt("Jogador %d", s + 1));
    float pulso = 0.5f + 0.5f * sinf(a->t * 3 + s);
    icone_natural(r, IC_CRUZ, x + w / 2, y + h / 2 - 30, 96 + 8 * pulso, 0.3f + 0.4f * pulso);
    wg_texto_rico(r, F_MEDIA_N, x + w / 2, y + h / 2 + 40, COR_TEXTO, ALINHA_CENTRO, "Aperte {X}");
    texto_al(r, F_TEXTO, x + w / 2, y + h / 2 + 86, COR_TEXTO_2, ALINHA_CENTRO, "para ocupar este lugar");
    texto_al(r, F_PEQUENA, x + w / 2, y + h - 70, COR_TEXTO_3, ALINHA_CENTRO,
             fmt("lightbar %s · LEDs %s", NOME_COR_JOGADOR[s],
                 s == 0 ? "--x--" : s == 1 ? "-x-x-" : s == 2 ? "x-x-x" : "xx-xx"));
    return;
  }
  if (!p) {
    texto(r, F_GRANDE_N, x + 108, y + 38, COR_TEXTO_2, fmt("Jogador %d", s + 1));
    icone(r, IC_AVISO, x + w / 2, y + h / 2 - 40, 96, COR_AVISO, 0);
    texto_al(r, F_MEDIA_N, x + w / 2, y + h / 2 + 30, COR_AVISO, ALINHA_CENTRO, fmt("%s sem controle", pads_rotulo_slot(s)));
    texto_al(r, F_TEXTO, x + w / 2, y + h / 2 + 76, COR_TEXTO_2, ALINHA_CENTRO, "reconecte e ele volta");
    texto_al(r, F_TEXTO, x + w / 2, y + h / 2 + 112, COR_TEXTO_2, ALINHA_CENTRO, "ao mesmo lugar");
    return;
  }
  texto(r, F_GRANDE_N, x + 108, y + 38, COR_TEXTO, fmt("Jogador %d", s + 1));
  texto_bloco(r, F_PEQUENA, x + 110, y + 90, w - 130, COR_TEXTO_2, ALINHA_ESQ, 1.0f, true, p->nome);

  VistaControle v;
  controle_vista_do_pad(&v, p);
  controle_desenhar(r, x + w / 2, y + 300, w - 70, &v, a->t, a->cfg.reduzir_movimento);

  float ly = y + 440;
  chips_do_pad(r, p, x + 24, ly, w - 48);
  ly += 100;
  texto(r, F_PEQUENA_N, x + 26, ly, COR_TEXTO_2, fmt("VID:PID %s", p->vidpid));
  if (p->bateria >= 0)
    texto_al(r, F_PEQUENA_N, x + w - 26, ly, COR_TEXTO_2, ALINHA_DIR, fmt("bateria %d%%", p->bateria));
  ly += 34;
  texto_bloco(r, F_MINI, x + 26, ly, w - 52, COR_TEXTO_3, ALINHA_ESQ, 1.0f, true, p->origem.evidencia);
  ly += 50;
  /* o que o controle sabe fazer, dito em uma linha */
  const char *falta = NULL;
  if (a->pads.contrato_estrito && p->origem.conexao == CONEXAO_BT && origem_eh_dualsense(p->origem.tipo))
    falta = "no rádio: só entrada — o 0x31 é de quem estiver na frente";
  else if (!p->cap_efeitos && !origem_eh_dualsense(p->origem.tipo))
    falta = "sem gatilho, luz e sensores: o formato não tem onde pôr";
  if (falta) {
    icone(r, IC_AVISO, x + 40, ly + 16, 28, COR_AVISO, 0);
    texto_bloco(r, F_PEQUENA, x + 62, ly, w - 84, COR_AVISO, ALINHA_ESQ, 1.0f, true, falta);
  } else {
    float cx = x + 26;
    struct {
      Icone ic;
      bool tem;
    } caps[] = {{IC_VIBRACAO, p->cap_rumble}, {IC_GATILHO, p->cap_efeitos}, {IC_LUZ, p->cap_rgb},
                {IC_GIRO, p->cap_giro},       {IC_TOQUE, p->cap_touch}};
    for (int i = 0; i < 5; i++) {
      icone(r, caps[i].ic, cx + 20, ly + 18, 34, caps[i].tem ? COR_OK : cor_alfa(COR_NEUTRO, 0.5f), 0);
      cx += 52;
    }
    texto(r, F_PEQUENA, cx + 6, ly + 4, COR_TEXTO_2, "o que ele fala");
  }
}

static void desenhar(App *a) {
  SDL_Renderer *r = a->r;
  ds_fundo(r, a->t, 0.8f);
  particulas_desenhar(r, &a->brasas);
  wg_cabecalho(r, "A MESA", "Cada controle ocupa um lugar. A cor e os LEDs do lugar vão para o controle.", a->t);
  float w = 430, h = 700, gap = 26;
  float x0 = TELA_L / 2 - (4 * w + 3 * gap) / 2;
  for (int s = 0; s < MAX_JOGADORES; s++)
    cartao(a, s, x0 + s * (w + gap), 176, w, h);

  /* os controles conectados que ainda não sentaram (e os espelhos) */
  float y = 896;
  int n = 0;
  for (int i = 0; i < MAX_PADS; i++) {
    Pad *p = &a->pads.pad[i];
    if (!p->usado || p->slot >= 0)
      continue;
    const char *linha = p->espelho_de >= 0
                            ? fmt("%s — parece espelho de %s, fora da mesa", p->nome, pads_rotulo_slot(p->espelho_de))
                            : fmt("%s [%s] · %s — aperte {X} para entrar", p->nome, p->vidpid,
                                  pad_origem_rotulo(p));
    wg_texto_rico(r, F_PEQUENA, TELA_L / 2.0f, y + n * 30, p->espelho_de >= 0 ? COR_AVISO : COR_TEXTO_2, ALINHA_CENTRO, linha);
    if (++n >= 3)
      break;
  }
  if (pads_conectados(a) == 0)
    texto_al(r, F_TEXTO, TELA_L / 2.0f, y, COR_TEXTO_2, ALINHA_CENTRO,
             "Nenhum controle conectado. Ligue um DualSense no cabo, no rádio, ou pelo Hefesto.");

  Dica d[] = {{IC_CRUZ, "entrar"}, {IC_CIRCULO, "sair da mesa"}, {IC_OPTIONS, "começar"}};
  wg_rodape(r, d, 3);
}

const Cena CENA_LOBBY = {"lobby", entrar, sair, NULL, atualizar, desenhar};
