/* O diagnóstico: por controle, ao vivo, o que CHEGA e o que SAI.
 *
 * É a tela da bancada. Cada controle mexe só nas próprias saídas — L1 vibra o
 * motor forte DELE, △ troca a cor DELE —, e o desenho de cada um mostra o que
 * foi mandado a ele. Se o vizinho reagir, a mesa vê; a tela não tem como.
 *
 * O que chega: botões, analógicos, gatilhos, giroscópio e acelerômetro (com a
 * taxa DECLARADA pelo SDL ao lado da MEDIDA), toque, bateria, e — quando o
 * controle fala o report 0x01 do cabo — o byte 53 cru: fone, microfone de
 * headset e mudo. */
#include "../app.h"

#include "../nucleo/simulador.h"
#include "../ui/controle.h"
#include "../ui/desenho.h"
#include "../ui/icones.h"
#include "../ui/tema.h"
#include "../ui/texto.h"
#include "../ui/widgets.h"

#include <math.h>

#define GRAUS 57.2957795f

static int g_cor_teste[MAX_PADS];
static int g_modo_r2[MAX_PADS], g_modo_l2[MAX_PADS];
static int g_leds_teste[MAX_PADS];
static int g_mic_teste[MAX_PADS];

static const SDL_Color CORES_TESTE[] = {
    {255, 0, 0, 255}, {0, 255, 0, 255}, {0, 0, 255, 255}, {255, 255, 255, 255}, {255, 200, 0, 255}, {0, 255, 255, 255},
};
#define N_CORES_TESTE ((int)(sizeof(CORES_TESTE) / sizeof(CORES_TESTE[0])))

static void entrar(App *a) {
  a->brasas.taxa = 6;
  SDL_memset(g_cor_teste, 0, sizeof(g_cor_teste));
  SDL_memset(g_modo_r2, 0, sizeof(g_modo_r2));
  SDL_memset(g_modo_l2, 0, sizeof(g_modo_l2));
  SDL_memset(g_leds_teste, 0, sizeof(g_leds_teste));
  SDL_memset(g_mic_teste, 0, sizeof(g_mic_teste));
  som_ambiente(&a->som, true, false);
  reg_linha(&a->reg, "diagnóstico aberto");
}

static void sair(App *a) {
  /* sai em silêncio: nada do teste fica ligado */
  for (int i = 0; i < MAX_PADS; i++) {
    Pad *p = &a->pads.pad[i];
    if (!p->usado)
      continue;
    if (p->slot >= 0) {
      pads_silencio(a, p->slot);
    } else {
      if (p->rumble_ate_ms)
        pad_rumble(a, p, 0, 0, 0);
      if (p->cap_efeitos && (p->modo_l2 || p->modo_r2))
        pad_gatilhos_off(a, p);
      if (p->cap_efeitos && p->led_mic)
        pad_led_mic(a, p, 0);
    }
  }
}

static ForjaTrigger gatilho_de(int modo) {
  ForjaTrigger t = {FORJA_TRIGGER_OFF, 0, 0, 0};
  switch (modo) {
  case 1:
    t = (ForjaTrigger){FORJA_TRIGGER_FEEDBACK, 2, 8, 0};
    break;
  case 2:
    t = (ForjaTrigger){FORJA_TRIGGER_WEAPON, 3, 6, 8};
    break;
  case 3:
    t = (ForjaTrigger){FORJA_TRIGGER_VIBRATION, 0, 8, 30};
    break;
  }
  return t;
}

static void atualizar(App *a, float dt) {
  (void)dt;
  for (int i = 0; i < MAX_PADS; i++) {
    Pad *p = &a->pads.pad[i];
    if (!p->usado)
      continue;
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_START)) {
      som_evento(&a->som, SOM_VOLTA, 0.6f);
      app_trocar_cena(a, a->anterior ? a->anterior : &CENA_TITULO);
      return;
    }
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_LEFT_SHOULDER))
      pad_rumble(a, p, 1.0f, 0.0f, 450);
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER))
      pad_rumble(a, p, 0.0f, 1.0f, 450);
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_WEST) && p->cap_efeitos) {
      g_modo_r2[i] = (g_modo_r2[i] + 1) % 4;
      pad_gatilho(a, p, 1, gatilho_de(g_modo_r2[i]));
    }
    if ((pad_apertou(p, SDL_GAMEPAD_BUTTON_DPAD_LEFT) || pad_apertou(p, SDL_GAMEPAD_BUTTON_DPAD_RIGHT)) &&
        p->cap_efeitos) {
      g_modo_l2[i] = (g_modo_l2[i] + (pad_apertou(p, SDL_GAMEPAD_BUTTON_DPAD_RIGHT) ? 1 : 3)) % 4;
      pad_gatilho(a, p, 0, gatilho_de(g_modo_l2[i]));
    }
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_NORTH)) {
      g_cor_teste[i] = (g_cor_teste[i] + 1) % (N_CORES_TESTE + 1);
      if (g_cor_teste[i] == N_CORES_TESTE && p->slot >= 0)
        pad_luz_do_slot(a, p);
      else
        pad_luz(a, p, CORES_TESTE[g_cor_teste[i] % N_CORES_TESTE]);
    }
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_EAST) && p->cap_efeitos) {
      g_mic_teste[i] = (g_mic_teste[i] + 1) % 4;
      pad_led_mic(a, p, g_mic_teste[i]);
    }
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_DPAD_UP) && p->cap_efeitos) {
      g_leds_teste[i] = (g_leds_teste[i] + 1) % 5;
      pad_leds_jogador(a, p, forja_leds_do_jogador(g_leds_teste[i]));
    }
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_DPAD_DOWN) && p->slot >= 0)
      pad_leds_do_slot(a, p);
  }
  if (a->nav.quem < 0 && a->nav.volta && !simulador_ativo())
    app_trocar_cena(a, a->anterior ? a->anterior : &CENA_TITULO);
}

static void secao(SDL_Renderer *r, float x, float y, float w, const char *titulo) {
  texto_espacado(r, F_PEQUENA_N, x, y, COR_BRONZE_CLARO, ALINHA_ESQ, 3, titulo);
  float tw = texto_largura_espacado(F_PEQUENA_N, 3, titulo);
  ds_linha(r, x + tw + 12, y + 14, x + w, y + 14, 1, cor_alfa(COR_BRONZE_ESCURO, 0.9f));
}

static float linha_valor(SDL_Renderer *r, float x, float y, const char *rotulo, const char *valor, SDL_Color cv) {
  texto(r, F_PEQUENA, x, y, COR_TEXTO_3, rotulo);
  texto(r, F_PEQUENA_N, x + 120, y, cv, valor);
  return 28;
}

static void coluna(App *a, Pad *p, float x, float y, float w, float h) {
  SDL_Renderer *r = a->r;
  int slot = p->slot;
  SDL_Color cj = slot >= 0 ? COR_JOGADOR[slot] : COR_NEUTRO;
  wg_painel(r, x, y, w, h, cj, slot >= 0 ? 0.6f : 0.1f);
  if (slot >= 0)
    wg_escudo_jogador(r, x + 42, y + 44, 46, slot, true);
  else
    icone(r, IC_VIRTUAL, x + 42, y + 44, 40, COR_NEUTRO, 0);
  texto_bloco(r, F_PEQUENA_N, x + 78, y + 22, w - 96, COR_TEXTO, ALINHA_ESQ, 1.0f, true, p->nome);
  texto(r, F_MINI, x + 78, y + 70, COR_TEXTO_3,
        fmt("%s · %s · %s", p->vidpid, conexao_rotulo(p->origem.conexao),
            p->simulado ? "simulado" : origem_rotulo(p->origem.tipo)));

  VistaControle v;
  controle_vista_do_pad(&v, p);
  controle_desenhar(r, x + w / 2, y + 222, 300, &v, a->t, a->cfg.reduzir_movimento);

  float cy = y + 356;
  float cx = x + 22, cw = w - 44;
  secao(r, cx, cy, cw, "CHEGA");
  cy += 30;
  /* analógicos e gatilhos */
  texto(r, F_MINI, cx, cy, COR_TEXTO_3, "analógico esq.");
  wg_barra_centro(r, cx + 130, cy + 2, 120, 12, p->ax[SDL_GAMEPAD_AXIS_LEFTX], cj);
  wg_barra_centro(r, cx + 262, cy + 2, 120, 12, p->ax[SDL_GAMEPAD_AXIS_LEFTY], cj);
  cy += 22;
  texto(r, F_MINI, cx, cy, COR_TEXTO_3, "analógico dir.");
  wg_barra_centro(r, cx + 130, cy + 2, 120, 12, p->ax[SDL_GAMEPAD_AXIS_RIGHTX], cj);
  wg_barra_centro(r, cx + 262, cy + 2, 120, 12, p->ax[SDL_GAMEPAD_AXIS_RIGHTY], cj);
  cy += 22;
  texto(r, F_MINI, cx, cy, COR_TEXTO_3, "L2 · R2");
  wg_barra(r, cx + 130, cy + 2, 120, 12, p->ax[SDL_GAMEPAD_AXIS_LEFT_TRIGGER], cj);
  wg_barra(r, cx + 262, cy + 2, 120, 12, p->ax[SDL_GAMEPAD_AXIS_RIGHT_TRIGGER], cj);
  cy += 28;
  /* giroscópio e acelerômetro */
  if (p->cap_giro) {
    texto(r, F_MINI, cx, cy, COR_TEXTO_3, "giro °/s");
    for (int k = 0; k < 3; k++)
      wg_barra_centro(r, cx + 130 + k * 84, cy + 2, 76, 12, p->giro[k] * GRAUS / 720.0f, COR_OURO);
    cy += 22;
    texto(r, F_MINI, cx, cy, COR_TEXTO_3, "acel. g");
    float g[3], mod = 0;
    for (int k = 0; k < 3; k++) {
      g[k] = p->acel[k] / 9.80665f;
      mod += g[k] * g[k];
      wg_barra_centro(r, cx + 130 + k * 84, cy + 2, 76, 12, g[k] / 2.0f, COR_BRASA_VIVA);
    }
    cy += 22;
    Uint64 ns = SDL_GetTicksNS();
    double hz = taxa_hz_host(&p->taxa_giro, ns, 2.0), hzc = taxa_hz_sensor(&p->taxa_giro, ns, 2.0);
    cy += texto_bloco(r, F_MINI, cx, cy, cw, COR_TEXTO_2, ALINHA_ESQ, 1.0f, true,
                      fmt("|a| %.2f g · giroscópio: o SDL declara %.0f Hz; chegam %.0f Hz (%.0f pelo relógio do controle)",
                          sqrtf(mod), p->giro_hz_declarado, hz, hzc));
    cy += 6;
  } else {
    texto(r, F_PEQUENA, cx, cy, COR_TEXTO_3, "sem giroscópio / acelerômetro");
    cy += 30;
  }
  if (p->cap_touch) {
    const char *d0 = p->dedo[0].baixo ? fmt("(%.2f, %.2f)", p->dedo[0].x, p->dedo[0].y) : "—";
    const char *d1 = p->dedo[1].baixo ? fmt("(%.2f, %.2f)", p->dedo[1].x, p->dedo[1].y) : "—";
    cy += linha_valor(r, cx, cy, "toque", fmt("1 %s · 2 %s%s", d0, d1, p->b[SDL_GAMEPAD_BUTTON_TOUCHPAD] ? " · clique" : ""), COR_TEXTO);
  }
  cy += linha_valor(r, cx, cy, "bateria",
                    p->bateria >= 0 ? fmt("%d%%%s", p->bateria, p->energia == SDL_POWERSTATE_CHARGING ? " carregando" : "")
                                    : "não informada",
                    COR_TEXTO);
  if (p->cru_ok)
    cy += linha_valor(r, cx, cy, "byte 53 cru",
                      fmt("fone %s · mic %s · mudo %s", (p->status53 & 1) ? "sim" : "não",
                          (p->status53 & 2) ? "sim" : "não", (p->status53 & 4) ? "sim" : "não"),
                      COR_TEXTO);
  else
    cy += linha_valor(r, cx, cy, "report cru", p->origem.conexao == CONEXAO_BT ? "rádio: não lido (0x31)" : "indisponível",
                      COR_TEXTO_3);

  cy += 8;
  secao(r, cx, cy, cw, "SAI");
  cy += 32;
  ds_ret_arred(r, cx, cy, 40, 24, 6, p->luz);
  ds_contorno_arred(r, cx, cy, 40, 24, 6, 1.5f, COR_BRONZE_ESCURO);
  char fig[6] = "—";
  if (p->leds_jogador >= 0)
    for (int i = 0; i < 5; i++)
      fig[i] = (p->leds_jogador >> i) & 1 ? 'x' : '-';
  static const char *mic[] = {"apagado", "aceso", "piscando", "pisca lento"};
  texto(r, F_MINI, cx + 52, cy + 2, COR_TEXTO_2,
        fmt("#%02x%02x%02x · LEDs %s · mic %s", p->luz.r, p->luz.g, p->luz.b, fig, mic[p->led_mic & 3]));
  cy += 30;
  static const char *modo[] = {"Off", "Resistência", "Arma", "Vibração"};
  texto(r, F_MINI, cx, cy, COR_TEXTO_2,
        fmt("L2 %s · R2 %s · vibração %d/%d", modo[p->modo_l2 & 3], modo[p->modo_r2 & 3], p->rumble_baixo >> 8,
            p->rumble_alto >> 8));
  cy += 28;
  for (int k = 0; k < 5; k++) {
    int idx = (p->saidas_prox - 1 - k + PAD_ANEL_SAIDAS * 2) % PAD_ANEL_SAIDAS;
    if (!p->saidas[idx][0])
      break;
    float idade = a->t - p->saidas_t[idx];
    SDL_Color c = cor_alfa(COR_TEXTO_2, idade < 1.5f ? 1.0f : 0.55f);
    if (p->saidas[idx][0] == (char)0xE2)
      c = COR_FALHA;
    texto(r, F_MINI, cx, cy, c, fmt("%5.1fs %s", idade, p->saidas[idx]));
    cy += 22;
    if (cy > y + h - 30)
      break;
  }
}

static void desenhar(App *a) {
  SDL_Renderer *r = a->r;
  ds_fundo(r, a->t, 0.5f);
  wg_cabecalho(r, "DIAGNÓSTICO", "Ao vivo, por controle: o que chega e o que sai. Cada controle só mexe nas próprias saídas.", a->t);
  /* a ordem: quem está na mesa, por lugar; depois os outros */
  Pad *lista[4];
  int n = 0;
  for (int s = 0; s < MAX_JOGADORES && n < 4; s++) {
    Pad *p = pads_do_slot(a, s);
    if (p)
      lista[n++] = p;
  }
  for (int i = 0; i < MAX_PADS && n < 4; i++)
    if (a->pads.pad[i].usado && a->pads.pad[i].slot < 0)
      lista[n++] = &a->pads.pad[i];
  float w = 452, gap = 16, h = 840;
  float x0 = TELA_L / 2 - (4 * w + 3 * gap) / 2;
  for (int i = 0; i < 4; i++) {
    float x = x0 + i * (w + gap);
    if (i < n) {
      coluna(a, lista[i], x, 170, w, h);
    } else {
      wg_painel(r, x, 170, w, h, COR_NEUTRO, 0);
      texto_al(r, F_TEXTO, x + w / 2, 170 + h / 2 - 20, COR_TEXTO_3, ALINHA_CENTRO, "sem controle");
    }
  }
  Dica d[] = {{IC_L1, "motor forte"}, {IC_R1, "fraco"}, {IC_QUADRADO, "R2"}, {IC_DPAD, "L2 e LEDs"},
              {IC_TRIANGULO, "cor"}, {IC_CIRCULO, "LED mic"}, {IC_OPTIONS, "voltar"}};
  wg_rodape(r, d, 7);
}

const Cena CENA_DIAGNOSTICO = {"diagnóstico", entrar, sair, NULL, atualizar, desenhar};
