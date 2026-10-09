/* A sessão: o estado que o módulo nativo guarda entre os quadros do jogo.
 *
 * O jogo (o FORJA 3D, no Godot) fala com os controles por aqui: os pads e os
 * quatro lugares, o relatório da sessão, a linha do tempo e o registro. O
 * módulo não desenha nada — quem desenha é o Godot; aqui mora o que o
 * contrato pede (USB 0x02, player index 0..3, os quatro modos de gatilho) e o
 * que o relatório grava.
 */
#ifndef FORJA_SESSAO_H
#define FORJA_SESSAO_H

#include <SDL3/SDL.h>

#include "linha_tempo.h"
#include "pads.h"
#include "registro.h"
#include "relatorio.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct Forja {
  float t;          /* segundos desde o início da sessão */
  float dt;
  Uint64 inicio_ns;
  Uint64 relogio_sim_ns; /* a soma dos dt: o relógio dos controles simulados */
  float intensidade; /* 0..1: multiplica a vibração (o ajuste da pausa) */
  unsigned long long semente;

  Relatorio rel;
  Registro reg;
  LinhaTempo lt;
  Pads pads;
  long seq_saida[MAX_JOGADORES + 1]; /* o seq das saídas, por lugar; o último, dos pads sem lugar */

  char pasta_relatorios[1024]; /* termina em '/' */
  char base_arquivos[64];      /* "20260927-193005" */
  bool relatorio_sujo;

  char aviso[200]; /* o último aviso curto (quem caiu, quem voltou) */
  int aviso_seq;   /* muda a cada aviso novo: o jogo sabe que tem um para mostrar */

  /* o simulador: controles de mentira para provar sem aparelho */
  int simular;
  bool robo;
  bool em_sala; /* os defeitos de mentira só valem dentro das salas */
  /* a sessão nasceu com --simular: só o controle virtual entra (a prova não vê o
   * de verdade). Não segue o `simular`, que o forja_simular liga no meio da
   * sessão de quem escolheu o teclado: esse continua aceitando o controle ligado depois. */
  bool so_virtuais;
} Forja;

/* A sessão do módulo (uma só por processo). */
extern Forja *FORJA;

/* Abre a sessão: o SDL (só gamepad e hidapi), o relatório, o registro e a
 * linha do tempo em `pasta` (vazia: sem arquivos). `simular` pendura N
 * controles de mentira; `robo` deixa o robô jogar neles. */
bool forja_abrir(Forja *f, const char *pasta, int simular, bool robo, unsigned long long semente);
/* Um quadro: bombeia os eventos do SDL e atualiza os controles. */
void forja_quadro(Forja *f, float dt);
/* Pendura N controles de mentira numa sessão já aberta (quem abriu o jogo sem
 * controle e escolheu jogar no teclado). Só vale uma vez por sessão. */
bool forja_simular(Forja *f, int n);
/* Fecha: silencia os controles, grava o relatório, solta o SDL. */
void forja_fechar(Forja *f);

double forja_agora(const Forja *f);
void forja_hora(char *out, size_t tam);
void forja_avisar(Forja *f, const char *formato, ...)
#if defined(__GNUC__)
    __attribute__((format(printf, 2, 3)))
#endif
    ;
void forja_relatorio_mudou(Forja *f);
/* Grava o relatório (JSON e texto) agora. Devolve true se gravou. */
bool forja_salvar_relatorio(Forja *f);
/* Windows sob Wine/Proton: o jogo sabe, e o relatório diz. */
bool forja_sob_wine(void);
const char *forja_versao_wine(void);

#ifdef __cplusplus
}
#endif

#endif
