/* O que toda sala tem. Ver sala_base.h. */
#include "sala_base.h"

#include "../cenas/pausa.h"
#include "../nucleo/simulador.h"
#include "../nucleo/utf8.h"
#include "../ui/desenho.h"
#include "../ui/icones.h"
#include "../ui/tema.h"
#include "../ui/texto.h"
#include "../ui/widgets.h"

#include <math.h>

static const char *CHAVE_RESULTADO[] = {"nao_medido", "passou", "falhou"};
static const char *CHAVE_NIVEL[] = {"nenhum", "montou", "saiu", "obedeceu", "reagiu"};

void sb_entrar(App *a, SalaBase *b, Sala sala, const Feature *feats, int n_feats, float duracao) {
  static int vezes[SALA_TOTAL];
  SDL_memset(b, 0, sizeof(*b));
  b->sala = sala;
  b->vez = vezes[sala]++;
  sorteio_semear(&b->sorteio, a->semente ^ (0x9E3779B97F4A7C15ull * (unsigned long long)(sala + 1)) ^
                                  ((unsigned long long)b->vez << 32));
  b->fase = FASE_AVISO;
  b->duracao = duracao;
  b->n_feats = n_feats > SALA_MAX_FEATS ? SALA_MAX_FEATS : n_feats;
  for (int i = 0; i < b->n_feats; i++)
    b->feats[i] = feats[i];
  a->brasas.taxa = a->cfg.reduzir_movimento ? 3 : 10;
  som_ambiente(&a->som, true, false);
  pads_silencio_todos(a);
}

static bool atividade(const Pad *p) {
  for (int i = 0; i < SDL_GAMEPAD_BUTTON_COUNT; i++)
    if (p->b[i])
      return true;
  for (int x = 0; x < SDL_GAMEPAD_AXIS_COUNT; x++)
    if (fabsf(p->ax[x]) > 0.5f)
      return true;
  if (p->dedo[0].baixo || p->dedo[1].baixo)
    return true;
  if (p->cap_giro && fabsf(p->giro[0]) + fabsf(p->giro[1]) + fabsf(p->giro[2]) > 1.5f)
    return true;
  return false;
}

static void comecar_jogo(App *a, SalaBase *b) {
  b->fase = FASE_JOGO;
  b->t_fase = 0;
  int n = 0;
  for (int s = 0; s < MAX_JOGADORES; s++) {
    b->jogando[s] = a->pads.slot[s].ocupado && pads_do_slot(a, s) != NULL;
    n += b->jogando[s];
  }
  Evento ev;
  ev_iniciar(&ev, &a->lt, "sala", 0);
  ev_str(&ev, "evento", "jogo_comecou");
  ev_str(&ev, "sala", catalogo_sala(b->sala)->chave);
  ev_int(&ev, "jogadores", n);
  ev_fim(&ev, &a->lt);
  som_evento(&a->som, SOM_MARTELO, 0.8f);
  particulas_faiscas(&a->brasas, TELA_L / 2.0f, 120, 40, COR_OURO, 1.0f);
}

bool sb_todos_acabaram(App *a, const SalaBase *b) {
  if (b->fase != FASE_JOGO)
    return false;
  if (b->duracao > 0 && b->t_fase >= b->duracao)
    return true;
  int jogando = 0, acabaram = 0;
  for (int s = 0; s < MAX_JOGADORES; s++) {
    if (!b->jogando[s])
      continue;
    jogando++;
    /* quem ficou sem controle não segura a sala para os outros */
    if (b->acabou[s] || !pads_do_slot(a, s))
      acabaram++;
  }
  return jogando > 0 && acabaram == jogando;
}

float sb_resta(const SalaBase *b) {
  if (b->duracao <= 0)
    return 0;
  float r = b->duracao - b->t_fase;
  return r > 0 ? r : 0;
}

static void sair_da_sala(App *a, bool concluida) {
  som_evento(&a->som, SOM_CONFIRMA, 0.6f);
  hub_voltar(a, concluida);
}

int sb_atualizar(App *a, SalaBase *b, float dt) {
  if (a->proxima)
    return -1;
  PausaAcao pa = pausa_atualizar(a);
  if (pausa_aberta() || pa != PAUSA_NADA) {
    switch (pa) {
    case PAUSA_REFAZER:
      reg_linha(&a->reg, "%s: refeita pela pausa", catalogo_sala(b->sala)->nome);
      app_trocar_cena(a, a->cena);
      break;
    case PAUSA_ABANDONAR:
      reg_linha(&a->reg, "%s: abandonada (fica não medido)", catalogo_sala(b->sala)->nome);
      hub_voltar(a, false);
      break;
    case PAUSA_DIAGNOSTICO:
      app_trocar_cena(a, &CENA_DIAGNOSTICO);
      break;
    case PAUSA_RELATORIO:
      app_trocar_cena(a, &CENA_RELATORIO);
      break;
    case PAUSA_TITULO:
      a->gauntlet = false;
      a->sala_atual = -1;
      app_trocar_cena(a, &CENA_TITULO);
      break;
    case PAUSA_SAIR:
      a->rodando = false;
      break;
    default:
      break;
    }
    return -1;
  }
  b->t_fase += dt;

  for (int s = 0; s < MAX_JOGADORES; s++) {
    Pad *p = pads_do_slot(a, s);
    if (p && pad_apertou(p, SDL_GAMEPAD_BUTTON_START)) {
      pausa_abrir(a, true, s);
      return -1;
    }
  }
  bool teclado = a->nav.quem < 0 && !simulador_ativo();
  if (teclado && a->nav.opcoes) {
    pausa_abrir(a, true, -1);
    return -1;
  }

  switch (b->fase) {
  case FASE_AVISO: {
    int presentes = 0, prontos = 0;
    for (int s = 0; s < MAX_JOGADORES; s++) {
      Pad *p = pads_do_slot(a, s);
      if (!p || !a->pads.slot[s].ocupado)
        continue;
      presentes++;
      if (!b->pronto[s] && b->t_fase > 0.5f &&
          (pad_apertou(p, SDL_GAMEPAD_BUTTON_SOUTH) || (robo_ativo() && b->t_fase > 1.4f + 0.2f * s))) {
        b->pronto[s] = true;
        som_evento_pan(&a->som, SOM_CONFIRMA, 0.6f, -0.75f + 0.5f * s);
      }
      prontos += b->pronto[s];
    }
    if ((presentes > 0 && prontos == presentes && b->t_fase > 0.9f) || (teclado && a->nav.confirma))
      comecar_jogo(a, b);
    return FASE_AVISO;
  }
  case FASE_JOGO:
    for (int s = 0; s < MAX_JOGADORES; s++) {
      if (!b->jogando[s])
        continue;
      Pad *p = pads_do_slot(a, s);
      if (p && atividade(p))
        b->mexeu[s] = true;
    }
    return FASE_JOGO;
  case FASE_FIM:
    b->fim_brilho = aproximar(b->fim_brilho, 1, 3, dt);
    if (b->t_fase > 0.8f) {
      for (int s = 0; s < MAX_JOGADORES; s++) {
        Pad *p = pads_do_slot(a, s);
        if (!p)
          continue;
        if (pad_apertou(p, SDL_GAMEPAD_BUTTON_SOUTH)) {
          sair_da_sala(a, true);
          return -1;
        }
        if (pad_apertou(p, SDL_GAMEPAD_BUTTON_NORTH)) {
          reg_linha(&a->reg, "%s: refeita (%s pediu)", catalogo_sala(b->sala)->nome, pads_rotulo_slot(s));
          app_trocar_cena(a, a->cena);
          return -1;
        }
      }
      if (teclado && a->nav.confirma) {
        sair_da_sala(a, true);
        return -1;
      }
      if (robo_ativo() && b->t_fase > 3.0f) {
        sair_da_sala(a, true);
        return -1;
      }
    }
    return FASE_FIM;
  }
  return -1;
}

void sb_veredito(SalaBase *b, int slot, Feature f, const Veredito *v) {
  if (slot < 0 || slot >= MAX_JOGADORES)
    return;
  for (int k = 0; k < b->n_feats; k++)
    if (b->feats[k] == f) {
      b->vered[slot][k] = *v;
      b->tem_vered[slot][k] = true;
      return;
    }
}

void sb_terminar(App *a, SalaBase *b, NivelEvidencia nivel) {
  if (b->fase == FASE_FIM)
    return;
  const InfoSala *sala = catalogo_sala(b->sala);
  for (int s = 0; s < MAX_JOGADORES; s++) {
    if (!b->jogando[s])
      continue;
    for (int k = 0; k < b->n_feats; k++) {
      if (!b->tem_vered[s][k])
        continue;
      const Veredito *v = &b->vered[s][k];
      const InfoFeature *f = catalogo_feature(b->feats[k]);
      rel_registrar(&a->rel, s + 1, b->feats[k], v->resultado, nivel, v->pedido, v->medido, v->obs, app_agora(a));
      Evento ev;
      ev_iniciar(&ev, &a->lt, "veredito", s + 1);
      ev_str(&ev, "sala", sala->chave);
      ev_str(&ev, "feature", f->chave);
      ev_str(&ev, "resultado", CHAVE_RESULTADO[v->resultado]);
      ev_str(&ev, "nivel", CHAVE_NIVEL[nivel]);
      ev_str(&ev, "medido", v->medido);
      ev_fim(&ev, &a->lt);
      reg_linha(&a->reg, "%s · %s: %s — %s", pads_rotulo_slot(s), f->nome, rel_resultado_rotulo(v->resultado),
                v->medido);
    }
  }
  Evento ev;
  ev_iniciar(&ev, &a->lt, "sala", 0);
  ev_str(&ev, "evento", "jogo_terminou");
  ev_str(&ev, "sala", sala->chave);
  ev_num(&ev, "segundos", b->t_fase);
  ev_fim(&ev, &a->lt);
  b->fase = FASE_FIM;
  b->t_fase = 0;
  b->fim_brilho = 0;
  pads_silencio_todos(a);
  app_relatorio_mudou(a);
  som_evento(&a->som, SOM_SUCESSO, 0.7f);
}

void sb_marco(App *a, int slot, const char *o_que, const char *detalhe) {
  Evento ev;
  ev_iniciar(&ev, &a->lt, "entrada", slot + 1);
  ev_str(&ev, "o", o_que);
  if (detalhe && detalhe[0])
    ev_str(&ev, "detalhe", detalhe);
  ev_fim(&ev, &a->lt);
}

void sb_pontos(App *a, SalaBase *b, int slot, int pontos) {
  if (slot < 0 || slot >= MAX_JOGADORES)
    return;
  b->pontos[slot] += pontos;
  a->pads.slot[slot].pontos += pontos;
}

float sb_pan(SDL_FRect f) { return limitar((f.x + f.w / 2) / TELA_L * 2 - 1, -1, 1); }

/* ---------- faixas ---------- */

int sb_faixas(App *a, const SalaBase *b, ModoFaixas modo, SDL_FRect area, SDL_FRect *rects, int *slots) {
  int n = 0;
  for (int s = 0; s < MAX_JOGADORES; s++) {
    bool conta = b->fase == FASE_AVISO ? a->pads.slot[s].ocupado : b->jogando[s];
    if (conta)
      slots[n++] = s;
  }
  if (!n)
    return 0;
  const float gap = 24;
  if (modo == FAIXAS_QUADRANTES && n <= 2)
    modo = FAIXAS_COLUNAS;
  for (int i = 0; i < n; i++) {
    SDL_FRect f = area;
    switch (modo) {
    case FAIXAS_COLUNAS:
      f.w = (area.w - gap * (n - 1)) / n;
      f.x = area.x + i * (f.w + gap);
      break;
    case FAIXAS_LINHAS:
      f.h = (area.h - gap * (n - 1)) / n;
      f.y = area.y + i * (f.h + gap);
      break;
    case FAIXAS_QUADRANTES:
      f.w = (area.w - gap) / 2;
      f.h = (area.h - gap) / 2;
      f.x = area.x + (i % 2) * (f.w + gap);
      f.y = area.y + (i / 2) * (f.h + gap);
      break;
    }
    rects[i] = f;
  }
  return n;
}

void sb_moldura(App *a, SDL_FRect f, int slot, float destaque) {
  wg_painel(a->r, f.x, f.y, f.w, f.h, COR_JOGADOR[slot], destaque);
  sb_escudo(a, f, slot);
}

void sb_escudo(App *a, SDL_FRect f, int slot) {
  wg_escudo_jogador(a->r, f.x + 42, f.y + 44, 44, slot, pads_do_slot(a, slot) != NULL);
}

void sb_sem_controle(App *a, SDL_FRect f, int slot) {
  ds_ret_arred(a->r, f.x + 8, f.y + 8, f.w - 16, f.h - 16, 12, (SDL_Color){8, 5, 4, 200});
  float cy = f.y + f.h / 2;
  icone(a->r, IC_AVISO, f.x + f.w / 2, cy - 40, 54, COR_AVISO, 0);
  texto_al(a->r, F_TEXTO_N, f.x + f.w / 2, cy + 4, COR_TEXTO, ALINHA_CENTRO, fmt("%s sem controle", pads_rotulo_slot(slot)));
  texto_al(a->r, F_PEQUENA, f.x + f.w / 2, cy + 44, COR_TEXTO_2, ALINHA_CENTRO, "reconecte para voltar ao lugar");
}

/* ---------- desenho comum ---------- */

static void posicao_na_prova(App *a, int *i, int *n) {
  *i = *n = 0;
  for (int s = 0; s < SALA_TOTAL; s++) {
    if (!hub_sala_pronta(s))
      continue;
    (*n)++;
    if (s <= a->sala_atual)
      *i = *n;
  }
}

void sb_desenhar_topo(App *a, const SalaBase *b) {
  SDL_Renderer *r = a->r;
  char nome[96];
  utf8_maiusculas(catalogo_sala(b->sala)->nome, nome, sizeof(nome));
  texto_espacado(r, F_TITULO_P, 60, 30, COR_OURO, ALINHA_ESQ, 5, nome);
  texto(r, F_PEQUENA, 62, 82, COR_TEXTO_3, catalogo_sala(b->sala)->padrao);

  if (b->fase == FASE_JOGO && b->duracao > 0) {
    float w = 560, x = TELA_L / 2 - w / 2, y = 44;
    float resta = sb_resta(b), frac = resta / b->duracao;
    SDL_Color c = frac > 0.3f ? COR_BRASA : cor_mistura(COR_FALHA, COR_OURO, 0.5f + 0.5f * sinf(a->t * 8));
    wg_barra(r, x, y, w, 16, frac, c);
    int seg = (int)ceilf(resta);
    texto_al(r, F_MEDIA_N, TELA_L / 2.0f, y + 22, COR_TEXTO, ALINHA_CENTRO, fmt("%d:%02d", seg / 60, seg % 60));
  }
  if (a->gauntlet) {
    int i, n;
    posicao_na_prova(a, &i, &n);
    float x = TELA_L - 60;
    icone(r, IC_CHAMA, x - 18, 50, 34, COR_BRASA_VIVA, 0);
    texto_al(r, F_PEQUENA_N, x - 44, 38, COR_TEXTO_2, ALINHA_DIR, fmt("Prova de Fogo · sala %d de %d", i, n));
  }
}

/* Desenha um texto rico com várias linhas (separadas por '\n'), centralizado. */
static float linhas_ricas(SDL_Renderer *r, Fonte f, float cx, float y, SDL_Color c, const char *s) {
  char linha[256];
  float yy = y;
  while (s && *s) {
    const char *fim = SDL_strchr(s, '\n');
    size_t n = fim ? (size_t)(fim - s) : SDL_strlen(s);
    if (n >= sizeof(linha))
      n = sizeof(linha) - 1;
    SDL_memcpy(linha, s, n);
    linha[n] = 0;
    wg_texto_rico(r, f, cx, yy, c, ALINHA_CENTRO, linha);
    yy += texto_altura(f) * 1.35f;
    s = fim ? fim + 1 : NULL;
  }
  return yy - y;
}

void sb_desenhar_aviso(App *a, const SalaBase *b, const char *como_jogar) {
  SDL_Renderer *r = a->r;
  float e = sai_rapido(limitar(b->t_fase / 0.4f, 0, 1));
  ds_ret(r, 0, 0, TELA_L, TELA_A, (SDL_Color){6, 4, 3, (Uint8)(150 * e)});
  float w = 1200, h = 700, x = TELA_L / 2 - w / 2, y = 170 + (1 - e) * 30;
  wg_painel(r, x, y, w, h, COR_BRASA, 0.5f);
  const InfoSala *sala = catalogo_sala(b->sala);
  char nome[96];
  utf8_maiusculas(sala->nome, nome, sizeof(nome));
  texto_espacado(r, F_TITULO, TELA_L / 2.0f, y + 40, COR_OURO, ALINHA_CENTRO, 8, nome);
  float tw = texto_largura_espacado(F_TITULO, 8, nome);
  ds_greca(r, TELA_L / 2 - tw / 2 - 170, y + 66, 130, 22, 2, cor_alfa(COR_BRONZE, 0.8f));
  ds_greca(r, TELA_L / 2 + tw / 2 + 40, y + 66, 130, 22, 2, cor_alfa(COR_BRONZE, 0.8f));
  texto_al(r, F_TEXTO, TELA_L / 2.0f, y + 124, COR_BRASA_VIVA, ALINHA_CENTRO, sala->padrao);

  float yy = y + 190;
  yy += linhas_ricas(r, F_TEXTO, TELA_L / 2.0f, yy, COR_TEXTO, como_jogar);

  /* o que a sala valida */
  char valida[240] = "";
  for (int k = 0; k < b->n_feats; k++) {
    SDL_strlcat(valida, k ? " · " : "", sizeof(valida));
    SDL_strlcat(valida, catalogo_feature(b->feats[k])->nome, sizeof(valida));
  }
  texto_al(r, F_PEQUENA_N, TELA_L / 2.0f, y + h - 210, COR_BRONZE_CLARO, ALINHA_CENTRO, "ESTA SALA VALIDA");
  texto_al(r, F_PEQUENA, TELA_L / 2.0f, y + h - 180, COR_TEXTO_2, ALINHA_CENTRO, valida);

  /* quem está pronto */
  int presentes[MAX_JOGADORES], n = 0;
  for (int s = 0; s < MAX_JOGADORES; s++)
    if (a->pads.slot[s].ocupado)
      presentes[n++] = s;
  float passo = 170, x0 = TELA_L / 2 - passo * (n - 1) / 2.0f, ey = y + h - 96;
  for (int i = 0; i < n; i++) {
    int s = presentes[i];
    bool conectado = pads_do_slot(a, s) != NULL;
    wg_escudo_jogador(r, x0 + i * passo - 36, ey, 46, s, conectado);
    if (b->pronto[s]) {
      icone(r, IC_OK, x0 + i * passo + 20, ey, 36, COR_OK, 0);
      texto_al(r, F_PEQUENA_N, x0 + i * passo, ey + 34, COR_OK, ALINHA_CENTRO, "pronto");
    } else if (conectado) {
      wg_texto_rico(r, F_PEQUENA, x0 + i * passo + 30, ey - 14, COR_TEXTO_2, ALINHA_CENTRO, "{X}");
      texto_al(r, F_PEQUENA, x0 + i * passo, ey + 34, COR_TEXTO_3, ALINHA_CENTRO, "esperando");
    } else {
      texto_al(r, F_PEQUENA, x0 + i * passo, ey + 34, COR_AVISO, ALINHA_CENTRO, "sem controle");
    }
  }
  if (!n)
    texto_al(r, F_TEXTO, TELA_L / 2.0f, ey - 14, COR_AVISO, ALINHA_CENTRO, "ninguém na mesa");
  Dica d[] = {{IC_CRUZ, "pronto"}, {IC_OPTIONS, "pausa"}};
  wg_rodape(r, d, 2);
}

void sb_desenhar_fim(App *a, const SalaBase *b) {
  SDL_Renderer *r = a->r;
  float e = sai_rapido(limitar(b->t_fase / 0.4f, 0, 1));
  ds_ret(r, 0, 0, TELA_L, TELA_A, (SDL_Color){6, 4, 3, (Uint8)(170 * e)});
  float w = 1780, h = 820, x = TELA_L / 2 - w / 2, y = 120 + (1 - e) * 30;
  wg_painel(r, x, y, w, h, COR_OURO, 0.4f * b->fim_brilho);
  char nome[96];
  utf8_maiusculas(catalogo_sala(b->sala)->nome, nome, sizeof(nome));
  texto_espacado(r, F_TITULO_P, TELA_L / 2.0f, y + 28, COR_OURO, ALINHA_CENTRO, 6, fmt("%s · CONCLUÍDA", nome));

  int slots[MAX_JOGADORES], n = 0;
  for (int s = 0; s < MAX_JOGADORES; s++)
    if (b->jogando[s])
      slots[n++] = s;
  if (!n) {
    texto_al(r, F_TEXTO, TELA_L / 2.0f, y + h / 2, COR_TEXTO_2, ALINHA_CENTRO, "ninguém jogou esta sala");
  }
  /* o melhor placar ganha a coroa de louros */
  int melhor = -1;
  for (int i = 0; i < n; i++)
    if (melhor < 0 || b->pontos[slots[i]] > b->pontos[melhor])
      melhor = slots[i];
  float cw = (w - 60) / (n ? n : 1);
  for (int i = 0; i < n; i++) {
    int s = slots[i];
    float cx = x + 30 + i * cw, cy = y + 100;
    if (i > 0)
      ds_linha(r, cx - 1, cy, cx - 1, y + h - 40, 1, cor_alfa(COR_BRONZE_ESCURO, 0.6f));
    wg_escudo_jogador(r, cx + 50, cy + 36, 54, s, pads_do_slot(a, s) != NULL);
    texto(r, F_GRANDE_N, cx + 96, cy + 8, COR_TEXTO, fmt("%d", b->pontos[s]));
    texto(r, F_PEQUENA, cx + 98, cy + 58, COR_TEXTO_3, "pontos");
    if (s == melhor && n > 1 && b->pontos[s] > 0)
      icone(r, IC_CHAMA, cx + cw - 60, cy + 36, 40, COR_OURO, 0);
    float yy = cy + 108;
    for (int k = 0; k < b->n_feats; k++) {
      const InfoFeature *f = catalogo_feature(b->feats[k]);
      texto(r, F_PEQUENA_N, cx + 20, yy, COR_TEXTO, f->nome);
      yy += 32;
      if (!b->tem_vered[s][k]) {
        wg_selo(r, cx + 110, yy + 20, RES_NAO_MEDIDO, 0.8f);
        yy += 50;
        texto(r, F_MINI, cx + 20, yy, COR_TEXTO_3, "a sala não mediu");
        yy += 40;
        continue;
      }
      const Veredito *v = &b->vered[s][k];
      wg_selo(r, cx + 110, yy + 20, v->resultado, 0.8f);
      yy += 50;
      yy += texto_bloco(r, F_MINI, cx + 20, yy, cw - 40, COR_TEXTO_2, ALINHA_ESQ, 1.05f, true, v->medido) + 6;
      if (v->resultado == RES_FALHOU && v->obs[0]) {
        yy += texto_bloco(r, F_MINI, cx + 20, yy, cw - 40, COR_FALHA, ALINHA_ESQ, 1.05f, true, v->obs) + 4;
      }
      yy += 14;
    }
  }
  const char *seguir = a->gauntlet ? "seguir a Prova de Fogo" : "voltar ao salão";
  Dica d[] = {{IC_CRUZ, seguir}, {IC_TRIANGULO, "refazer a sala"}};
  wg_rodape(r, d, 2);
}
