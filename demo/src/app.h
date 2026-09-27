/* O estado do jogo inteiro e o contrato das cenas. */
#ifndef DEMO_APP_H
#define DEMO_APP_H

#include <SDL3/SDL.h>

#include "nucleo/aleatorio.h"
#include "nucleo/linha_tempo.h"
#include "nucleo/pads.h"
#include "nucleo/registro.h"
#include "nucleo/relatorio.h"
#include "som/sistema.h"
#include "ui/particulas.h"

typedef struct App App;

/* Uma cena: título, lobby, diagnóstico, uma estação... */
typedef struct Cena {
  const char *nome;
  void (*entrar)(App *a);
  void (*sair)(App *a);
  void (*evento)(App *a, const SDL_Event *e);
  void (*atualizar)(App *a, float dt);
  void (*desenhar)(App *a);
} Cena;

/* A navegação de menu da rodada: qualquer jogador (ou o teclado) navega. */
typedef struct Nav {
  bool cima, baixo, esq, dir;
  bool confirma, volta, opcoes, extra; /* ✕ ○ Options △ */
  int quem;                            /* o slot que apertou (-1 teclado) */
} Nav;

typedef struct Config {
  bool reduzir_movimento; /* sem tremor de tela e com menos partículas */
  bool legendas;          /* legenda de todo som que sai de um controle */
  float intensidade;      /* 0..1, multiplica vibração e háptica */
  float volume_sistema;   /* 0..1, a música e os sons da tela */
  bool tela_cheia;
} Config;

struct App {
  SDL_Window *janela;
  SDL_Renderer *r;
  bool rodando;
  float t;  /* segundos desde o início */
  float dt;
  Uint64 inicio_ns;

  Config cfg;
  Sorteio sorteio;
  unsigned long long semente;

  Relatorio rel;
  Registro reg;
  LinhaTempo lt;
  Pads pads;
  SomSistema som;
  Particulas brasas;

  const Cena *cena;
  const Cena *proxima;
  const Cena *anterior; /* de onde se veio (o diagnóstico volta para lá) */
  float transicao; /* 0..1: saída da cena atual, 1..2: entrada da próxima */

  Nav nav;
  float tremor; /* tremor de tela, decai */

  char pasta_relatorios[1024];
  char base_arquivos[64]; /* "20260927-193005" */
  bool relatorio_sujo;
  float relatorio_salvo_ha;
  char aviso[200];
  float aviso_t;

  /* o que o lobby abre quando a mesa fecha */
  int modo_jogo;   /* 0 o hub, 1 o gauntlet (todas as salas, na ordem) */
  int sala_atual;  /* -1 no hub */
  unsigned salas_feitas; /* as salas concluídas nesta sessão (um bit por sala) */
  bool robo_sala_unica;  /* --sala com --robo: joga a sala, lê o livro e sai */
  bool gauntlet;   /* o gauntlet está em andamento */
  int gauntlet_passo;

  /* argumentos */
  int simular;
  bool robo;
  bool acelerado; /* só com --simular: passo fixo de 1/60 s, sem esperar o relógio */
  int sala_direta;
  bool diagnostico_direto;
  char captura[512];
  int captura_quadro;
  int quadro;
  bool sem_som;
};

extern App *APP;

void app_trocar_cena(App *a, const Cena *c);
void app_avisar(App *a, const char *fmt, ...);
/* Grava o relatório (JSON e texto) agora. Devolve true se gravou. */
bool app_salvar_relatorio(App *a);
/* Marca o relatório para gravar no próximo quadro calmo. */
void app_relatorio_mudou(App *a);
/* Segundos desde o início da sessão (a régua do relatório). */
double app_agora(const App *a);
/* A data e a hora de agora, "2026-09-27 19:31:05". */
void app_hora(char *out, size_t tam);
/* Windows sob Wine/Proton: o jogo sabe, e o relatório diz. */
bool app_sob_wine(void);
const char *app_versao_wine(void);

/* As cenas. */
extern const Cena CENA_TITULO;
extern const Cena CENA_LOBBY;
extern const Cena CENA_DIAGNOSTICO;
extern const Cena CENA_RELATORIO;
extern const Cena CENA_HUB;

/* O hub e as salas (hub.c). */
void hub_abrir_sala(App *a, int sala);
/* A sala terminou (ou foi abandonada): volta ao hub, ou segue o gauntlet. */
void hub_voltar(App *a, bool concluida);
const Cena *hub_cena_da_sala(int sala);
bool hub_sala_pronta(int sala);
void hub_comecar_gauntlet(App *a);

#endif
