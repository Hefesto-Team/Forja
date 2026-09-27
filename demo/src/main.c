/* Hefesto Tech Demo — o laço principal.
 *
 *   hefesto-tech-demo [--simular N] [--robo] [--acelerado] [--defeito LISTA] [--sala CHAVE] [--gauntlet] [--diagnostico]
 *                     [--semente N] [--relatorios PASTA] [--tela-cheia]
 *                     [--tamanho LxA] [--sem-som] [--captura ARQ.png --quadros N]
 *
 * O contrato (CONTRATO.md) começa aqui, antes do SDL_Init: o jogo só monta o
 * payload de 47 bytes; no DualSense NATIVO por rádio, que pediria o relatório
 * 0x31, o SDL fica proibido de escrever (SDL_HINT_JOYSTICK_ENHANCED_REPORTS =
 * "0"), e o controle entra só com a entrada básica. No cabo, e no DualSense
 * virtual que se declara USB, tudo funciona — pelo relatório 0x02. */
#include "app.h"

#include "nucleo/catalogo.h"
#include "nucleo/relogio.h"
#include "nucleo/simulador.h"
#include "ui/desenho.h"
#include "ui/tema.h"
#include "ui/texto.h"
#include "ui/widgets.h"

/* do stb_image_write (third_party.c): a captura de tela vira PNG em memória */
unsigned char *stbi_write_png_to_mem(const unsigned char *pixels, int stride_bytes, int x, int y,
                                     int n, int *out_len);

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef FORJA_VERSAO
#define FORJA_VERSAO "sem-versao"
#endif

static App g_app;

static void uso(void) {
  fputs("uso: hefesto-tech-demo [--simular N] [--robo] [--acelerado] [--defeito LISTA] [--sala CHAVE] [--gauntlet] [--diagnostico]\n"
        "                         [--semente N] [--relatorios PASTA] [--tela-cheia]\n"
        "                         [--tamanho LxA] [--sem-som] [--captura ARQ.png --quadros N]\n",
        stderr);
}

static int largura_janela = 1600, altura_janela = 900;

static bool argumentos(App *a, int argc, char **argv) {
  for (int i = 1; i < argc; i++) {
    const char *s = argv[i];
    const char *prox = i + 1 < argc ? argv[i + 1] : NULL;
    if (!strcmp(s, "--simular") && prox) {
      a->simular = atoi(prox);
      i++;
    } else if (!strcmp(s, "--robo")) {
      a->robo = true;
    } else if (!strcmp(s, "--acelerado")) {
      a->acelerado = true;
    } else if (!strcmp(s, "--defeito") && prox) {
      char erro[160];
      if (!simulador_defeitos(prox, erro, sizeof(erro))) {
        fprintf(stderr, "%s\n", erro);
        return false;
      }
      i++;
    } else if (!strcmp(s, "--gauntlet")) {
      a->modo_jogo = 1;
    } else if ((!strcmp(s, "--sala") && prox) || !strncmp(s, "--sala=", 7)) {
      /* `--sala X` e `--sala=X` (a forma da folha de teste do Hefesto) */
      const char *chave = s[6] == '=' ? s + 7 : prox;
      a->sala_direta = catalogo_sala_por_chave(chave);
      if (a->sala_direta < 0) {
        fprintf(stderr, "sala desconhecida: %s\n", chave);
        return false;
      }
      if (s[6] != '=')
        i++;
    } else if (!strcmp(s, "--")) {
      /* o separador do Godot (`-- --sala=voz`): aqui não separa nada */
    } else if (!strcmp(s, "--diagnostico")) {
      a->diagnostico_direto = true;
    } else if (!strcmp(s, "--semente") && prox) {
      a->semente = strtoull(prox, NULL, 10);
      i++;
    } else if (!strcmp(s, "--relatorios") && prox) {
      snprintf(a->pasta_relatorios, sizeof(a->pasta_relatorios), "%s", prox);
      i++;
    } else if (!strcmp(s, "--tela-cheia")) {
      a->cfg.tela_cheia = true;
    } else if (!strcmp(s, "--tamanho") && prox) {
      if (sscanf(prox, "%dx%d", &largura_janela, &altura_janela) != 2)
        return false;
      i++;
    } else if (!strcmp(s, "--sem-som")) {
      a->sem_som = true;
    } else if (!strcmp(s, "--captura") && prox) {
      snprintf(a->captura, sizeof(a->captura), "%s", prox);
      i++;
    } else if (!strcmp(s, "--quadros") && prox) {
      a->captura_quadro = atoi(prox);
      i++;
    } else if (!strcmp(s, "--reduzir-movimento")) {
      a->cfg.reduzir_movimento = true;
    } else {
      return false;
    }
  }
  return true;
}

/* A pasta dos relatórios: a pedida, ou `relatorios/` ao lado do executável
 * (sob o Proton é a pasta de verdade do .exe), ou a pasta do usuário. Nunca
 * um caminho escrito no código. */
static void escolher_pasta(App *a) {
  char tentativa[1024];
  if (a->pasta_relatorios[0]) {
    size_t n = strlen(a->pasta_relatorios);
    if (a->pasta_relatorios[n - 1] != '/' && a->pasta_relatorios[n - 1] != '\\' && n + 1 < sizeof(a->pasta_relatorios))
      strcat(a->pasta_relatorios, "/");
    SDL_CreateDirectory(a->pasta_relatorios);
    return;
  }
  const char *base = SDL_GetBasePath();
  if (base) {
    snprintf(tentativa, sizeof(tentativa), "%srelatorios/", base);
    if (SDL_CreateDirectory(tentativa)) {
      char teste[1100];
      snprintf(teste, sizeof(teste), "%s.escrita", tentativa);
      SDL_IOStream *io = SDL_IOFromFile(teste, "w");
      if (io) {
        SDL_CloseIO(io);
        SDL_RemovePath(teste);
        snprintf(a->pasta_relatorios, sizeof(a->pasta_relatorios), "%s", tentativa);
        return;
      }
    }
  }
  char *pref = SDL_GetPrefPath("Hefesto", "TechDemo");
  if (pref) {
    snprintf(a->pasta_relatorios, sizeof(a->pasta_relatorios), "%srelatorios/", pref);
    SDL_free(pref);
    SDL_CreateDirectory(a->pasta_relatorios);
  }
}

static void preparar_relatorio(App *a) {
  rel_iniciar(&a->rel);
  SDL_Time agora;
  SDL_DateTime dt;
  if (SDL_GetCurrentTime(&agora) && SDL_TimeToDateTime(agora, &dt, true))
    snprintf(a->base_arquivos, sizeof(a->base_arquivos), "%04d%02d%02d-%02d%02d%02d", dt.year, dt.month,
             dt.day, dt.hour, dt.minute, dt.second);
  else
    snprintf(a->base_arquivos, sizeof(a->base_arquivos), "sessao");
  snprintf(a->rel.sessao, sizeof(a->rel.sessao), "%s", a->base_arquivos);
  app_hora(a->rel.inicio, sizeof(a->rel.inicio));
  snprintf(a->rel.versao, sizeof(a->rel.versao), "%s", FORJA_VERSAO);
  int v = SDL_GetVersion();
  snprintf(a->rel.sdl, sizeof(a->rel.sdl), "%d.%d.%d (%s)", SDL_VERSIONNUM_MAJOR(v), SDL_VERSIONNUM_MINOR(v),
           SDL_VERSIONNUM_MICRO(v), SDL_GetRevision());
  const char *wine = app_versao_wine();
  char plat[128];
  if (wine)
    snprintf(plat, sizeof(plat), "%s sob Wine %s (Proton)", SDL_GetPlatform(), wine);
  else
    snprintf(plat, sizeof(plat), "%s", SDL_GetPlatform());
  snprintf(a->rel.plataforma, sizeof(a->rel.plataforma), "%s · vídeo %s · áudio %s", plat,
           SDL_GetCurrentVideoDriver() ? SDL_GetCurrentVideoDriver() : "?",
           SDL_GetCurrentAudioDriver() ? SDL_GetCurrentAudioDriver() : "nenhum");
  rel_copiar(a->rel.contrato, sizeof(a->rel.contrato),
             "estrito: o jogo monta só o payload de 47 bytes e fala USB 0x02 pelo SDL; DualSense nativo "
             "no rádio entra só com a entrada básica (SDL_HINT_JOYSTICK_ENHANCED_REPORTS=0)");
  a->rel.semente = a->semente;
  if (a->simular) {
    rel_nota(&a->rel, "sessão com controles SIMULADOS (--simular): nada aqui foi medido em aparelho");
    if (simulador_defeitos_texto()[0]) {
      char nota[240];
      snprintf(nota, sizeof(nota), "defeitos de mentira nos controles simulados (--defeito): %s",
               simulador_defeitos_texto());
      rel_nota(&a->rel, nota);
    }
  }
}

static void capturar(App *a, const char *caminho) {
  SDL_Surface *s = SDL_RenderReadPixels(a->r, NULL);
  if (!s)
    return;
  SDL_Surface *rgba = SDL_ConvertSurface(s, SDL_PIXELFORMAT_RGBA32);
  SDL_DestroySurface(s);
  if (!rgba)
    return;
  int n = 0;
  unsigned char *png = stbi_write_png_to_mem(rgba->pixels, rgba->pitch, rgba->w, rgba->h, 4, &n);
  SDL_DestroySurface(rgba);
  if (!png)
    return;
  SDL_IOStream *io = SDL_IOFromFile(caminho, "wb");
  if (io) {
    SDL_WriteIO(io, png, (size_t)n);
    SDL_CloseIO(io);
    reg_linha(&a->reg, "captura de tela gravada");
  }
  SDL_free(png);
}

/* A navegação de menu: qualquer controle conectado, ou o teclado. */
static void navegar(App *a, float dt) {
  static float repeticao[MAX_PADS];
  static int dir_ant[MAX_PADS];
  Nav *n = &a->nav;
  for (int i = 0; i < MAX_PADS; i++) {
    Pad *p = &a->pads.pad[i];
    if (!p->usado)
      continue;
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_SOUTH)) {
      n->confirma = true;
      n->quem = p->slot;
    }
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_EAST)) {
      n->volta = true;
      n->quem = p->slot;
    }
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_START)) {
      n->opcoes = true;
      n->quem = p->slot;
    }
    if (pad_apertou(p, SDL_GAMEPAD_BUTTON_NORTH)) {
      n->extra = true;
      n->quem = p->slot;
    }
    int dir = 0;
    if (p->b[SDL_GAMEPAD_BUTTON_DPAD_UP] || p->ax[SDL_GAMEPAD_AXIS_LEFTY] < -0.6f)
      dir = 1;
    else if (p->b[SDL_GAMEPAD_BUTTON_DPAD_DOWN] || p->ax[SDL_GAMEPAD_AXIS_LEFTY] > 0.6f)
      dir = 2;
    else if (p->b[SDL_GAMEPAD_BUTTON_DPAD_LEFT] || p->ax[SDL_GAMEPAD_AXIS_LEFTX] < -0.6f)
      dir = 3;
    else if (p->b[SDL_GAMEPAD_BUTTON_DPAD_RIGHT] || p->ax[SDL_GAMEPAD_AXIS_LEFTX] > 0.6f)
      dir = 4;
    bool dispara = false;
    if (dir && dir != dir_ant[i]) {
      dispara = true;
      repeticao[i] = 0.38f;
    } else if (dir) {
      repeticao[i] -= dt;
      if (repeticao[i] <= 0) {
        dispara = true;
        repeticao[i] = 0.13f;
      }
    }
    dir_ant[i] = dir;
    if (dispara) {
      n->quem = p->slot;
      n->cima |= dir == 1;
      n->baixo |= dir == 2;
      n->esq |= dir == 3;
      n->dir |= dir == 4;
    }
  }
}

static void tecla(App *a, const SDL_Event *e) {
  if (e->type != SDL_EVENT_KEY_DOWN)
    return;
  SDL_Keycode k = e->key.key;
  if (k == SDLK_F11) {
    a->cfg.tela_cheia = !a->cfg.tela_cheia;
    SDL_SetWindowFullscreen(a->janela, a->cfg.tela_cheia);
    return;
  }
  if (k == SDLK_F12) {
    char caminho[1200];
    static int n = 0;
    snprintf(caminho, sizeof(caminho), "%scaptura-%s-%02d.png", a->pasta_relatorios, a->base_arquivos, ++n);
    capturar(a, caminho);
    app_avisar(a, "Captura gravada na pasta dos relatórios");
    return;
  }
  if (simulador_ativo())
    return; /* o teclado é o controle simulado */
  Nav *n = &a->nav;
  n->quem = -1;
  switch (k) {
  case SDLK_UP:
  case SDLK_W:
    n->cima = true;
    break;
  case SDLK_DOWN:
  case SDLK_S:
    n->baixo = true;
    break;
  case SDLK_LEFT:
  case SDLK_A:
    n->esq = true;
    break;
  case SDLK_RIGHT:
  case SDLK_D:
    n->dir = true;
    break;
  case SDLK_RETURN:
  case SDLK_SPACE:
  case SDLK_KP_ENTER:
    n->confirma = true;
    break;
  case SDLK_ESCAPE:
  case SDLK_BACKSPACE:
    n->volta = true;
    break;
  case SDLK_TAB:
    n->opcoes = true;
    break;
  default:
    break;
  }
}

static void desenhar_transicao(App *a) {
  if (!a->proxima && a->transicao <= 0)
    return;
  float alfa = a->transicao <= 1 ? a->transicao : 2 - a->transicao;
  ds_ret(a->r, 0, 0, TELA_L, TELA_A, (SDL_Color){6, 4, 3, (Uint8)(limitar(alfa, 0, 1) * 255)});
}

int main(int argc, char **argv) {
  App *a = &g_app;
  APP = a;
  SDL_memset(a, 0, sizeof(*a));
  a->sala_direta = -1;
  a->sala_atual = -1;
  a->cfg.legendas = true;
  a->cfg.intensidade = 1.0f;
  a->cfg.volume_sistema = 0.8f;
  if (!argumentos(a, argc, argv)) {
    uso();
    return 64;
  }
  if (!a->semente) {
    Uint64 t = SDL_GetTicksNS();
    SDL_Time agora;
    if (SDL_GetCurrentTime(&agora))
      t ^= (Uint64)agora;
    a->semente = (t % 1000000000ull) + 1;
  }

  /* o contrato, antes de tudo */
  SDL_SetHint(SDL_HINT_JOYSTICK_ENHANCED_REPORTS, "0");
  SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");
  SDL_SetHint(SDL_HINT_JOYSTICK_HIDAPI_PS5_PLAYER_LED, "1");
  SDL_SetHint(SDL_HINT_VIDEO_ALLOW_SCREENSAVER, "0");
  SDL_SetAppMetadata("Hefesto Tech Demo", FORJA_VERSAO, "org.hefesto.techdemo");
  SDL_SetAppMetadataProperty(SDL_PROP_APP_METADATA_CREATOR_STRING, "Hefesto Team");

  if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD | SDL_INIT_AUDIO | SDL_INIT_EVENTS)) {
    fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
    return 1;
  }
  SDL_WindowFlags flags = SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY;
  if (a->cfg.tela_cheia)
    flags |= SDL_WINDOW_FULLSCREEN;
  a->janela = SDL_CreateWindow("Hefesto Tech Demo — Forja", largura_janela, altura_janela, flags);
  if (!a->janela) {
    fprintf(stderr, "janela: %s\n", SDL_GetError());
    return 1;
  }
  a->r = SDL_CreateRenderer(a->janela, NULL);
  if (!a->r) {
    fprintf(stderr, "renderer: %s\n", SDL_GetError());
    return 1;
  }
  bool vsync = SDL_SetRenderVSync(a->r, 1);
  const char *vd = SDL_GetCurrentVideoDriver();
  bool sem_tela = vd && (!SDL_strcmp(vd, "offscreen") || !SDL_strcmp(vd, "dummy"));
  SDL_SetRenderLogicalPresentation(a->r, TELA_L, TELA_A, SDL_LOGICAL_PRESENTATION_LETTERBOX);
  if (!desenho_iniciar(a->r) || !texto_iniciar(a->r)) {
    fprintf(stderr, "não consegui preparar o desenho ou as fontes\n");
    return 1;
  }

  a->inicio_ns = SDL_GetTicksNS();
  relogio_iniciar(a->inicio_ns);
  if (a->acelerado && a->simular > 0)
    relogio_do_jogo(&a->t);
  escolher_pasta(a);
  preparar_relatorio(a);
  char caminho_reg[1200];
  snprintf(caminho_reg, sizeof(caminho_reg), "%sregistro-%s.log", a->pasta_relatorios, a->base_arquivos);
  reg_abrir(&a->reg, a->pasta_relatorios[0] ? caminho_reg : NULL);
  reg_linha(&a->reg, "Hefesto Tech Demo %s · SDL %s · %s", FORJA_VERSAO, a->rel.sdl, a->rel.plataforma);
  reg_linha(&a->reg, "contrato: %s", a->rel.contrato);
  reg_linha(&a->reg, "semente dos sorteios: %llu", a->semente);

  sorteio_semear(&a->sorteio, a->semente);
  char caminho_lt[1200];
  snprintf(caminho_lt, sizeof(caminho_lt), "%slinha-do-tempo-%s.jsonl", a->pasta_relatorios, a->base_arquivos);
  lt_abrir(&a->lt, a->pasta_relatorios[0] ? caminho_lt : NULL, a->inicio_ns);
  {
    Evento ev;
    ev_iniciar(&ev, &a->lt, "sessao", 0);
    ev_str(&ev, "formato", LINHA_TEMPO_FORMATO);
    ev_str(&ev, "sessao", a->rel.sessao);
    ev_int(&ev, "semente", (long)a->semente);
    ev_str(&ev, "versao", a->rel.versao);
    ev_str(&ev, "sdl", a->rel.sdl);
    ev_str(&ev, "plataforma", a->rel.plataforma);
    ev_bool(&ev, "simulado", a->simular > 0);
    ev_fim(&ev, &a->lt);
  }
  som_iniciar(&a->som, a->sem_som);
  som_volume(&a->som, a->cfg.volume_sistema);
  reg_linha(&a->reg, "som do sistema: %s", a->som.ativo ? a->som.dispositivo : "desligado");
  particulas_iniciar(&a->brasas, a->semente);
  pads_iniciar(a);
  if (a->simular > 0)
    simulador_iniciar(a, a->simular);

  if (a->diagnostico_direto)
    a->cena = &CENA_DIAGNOSTICO;
  else if (a->sala_direta >= 0 || a->modo_jogo == 1)
    a->cena = &CENA_LOBBY;
  else
    a->cena = &CENA_TITULO;
  a->cena->entrar(a);
  a->transicao = 1.0f; /* entra com fade */

  a->rodando = true;
  Uint64 antes = SDL_GetTicksNS();
  /* Sem vsync de verdade (sem janela, ou um compositor que o ignora), o
   * quadro tem piso: 60 por segundo sem tela, 240 com. */
  const Uint64 QUADRO_NS = 1000000000ull / (sem_tela || !vsync ? 60 : 240);
  /* --acelerado (só com controles simulados): o tempo do jogo anda 1/60 s por
   * quadro, sem esperar o relógio, e só um quadro em quatro é desenhado — o
   * gauntlet do robô termina em minutos no CI */
  const bool acelerado = a->acelerado && a->simular > 0;
  while (a->rodando) {
    float dt;
    if (acelerado) {
      dt = 1.0f / 60.0f;
    } else {
      Uint64 gasto = SDL_GetTicksNS() - antes;
      if (gasto < QUADRO_NS)
        SDL_DelayPrecise(QUADRO_NS - gasto);
      Uint64 agora = SDL_GetTicksNS();
      dt = (float)((agora - antes) / 1e9);
      antes = agora;
    }
    if (dt > 0.1f)
      dt = 0.1f;
    a->dt = dt;
    a->t += dt;
    SDL_memset(&a->nav, 0, sizeof(a->nav));
    a->nav.quem = -1;

    SDL_Event e;
    while (SDL_PollEvent(&e)) {
      if (e.type == SDL_EVENT_QUIT)
        a->rodando = false;
      if (simulador_evento(a, &e))
        continue;
      if (pads_evento(a, &e))
        continue;
      tecla(a, &e);
      if (a->cena->evento)
        a->cena->evento(a, &e);
    }
    if (simulador_ativo())
      simulador_atualizar(a, dt);
    pads_atualizar(a, dt);
    navegar(a, dt);

    if (!a->proxima && a->transicao <= 0)
      a->cena->atualizar(a, dt);
    else if (a->transicao > 1)
      a->cena->atualizar(a, dt);
    particulas_atualizar(&a->brasas, dt);
    a->tremor = aproximar(a->tremor, 0, 8, dt);
    a->aviso_t += dt;

    if (a->proxima || a->transicao > 0) {
      a->transicao += dt * 3.5f;
      if (a->proxima && a->transicao >= 1) {
        if (a->cena->sair)
          a->cena->sair(a);
        a->anterior = a->cena;
        a->cena = a->proxima;
        a->proxima = NULL;
        a->cena->entrar(a);
        a->transicao = 1.0001f;
      } else if (!a->proxima && a->transicao >= 2) {
        a->transicao = 0;
      }
    }

    bool desenhar = !acelerado || a->quadro % 4 == 0 || (a->captura_quadro && a->quadro + 1 >= a->captura_quadro);
    if (desenhar) {
      SDL_SetRenderDrawColor(a->r, 0, 0, 0, 255);
      SDL_RenderClear(a->r);
      a->cena->desenhar(a);
      wg_aviso(a->r, a->aviso, a->aviso_t);
      desenhar_transicao(a);
      SDL_RenderPresent(a->r);
    }
    pads_fim_do_quadro(a);
    a->quadro++;

    if (a->relatorio_sujo) {
      a->relatorio_salvo_ha += dt;
      if (a->relatorio_salvo_ha > 0.5f)
        app_salvar_relatorio(a);
    }
    if (a->captura[0] && a->captura_quadro > 0 && a->quadro == a->captura_quadro) {
      /* o quadro já foi apresentado: redesenha para ler os pixels */
      SDL_RenderClear(a->r);
      a->cena->desenhar(a);
      capturar(a, a->captura);
      SDL_RenderPresent(a->r);
      a->rodando = false;
    }
  }

  if (a->cena && a->cena->sair)
    a->cena->sair(a);
  /* o silêncio final (motores, gatilhos, luzes) entra no registro antes do fim */
  pads_encerrar(a);
  reg_linha(&a->reg, "fim da sessão");
  app_salvar_relatorio(a);
  if (simulador_ativo())
    simulador_encerrar(a);
  som_encerrar(&a->som);
  reg_fechar(&a->reg);
  lt_fechar(&a->lt);
  rel_liberar(&a->rel);
  texto_encerrar();
  desenho_encerrar();
  SDL_DestroyRenderer(a->r);
  SDL_DestroyWindow(a->janela);
  SDL_Quit();
  return 0;
}
