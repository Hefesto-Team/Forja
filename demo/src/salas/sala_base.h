/* O que toda sala tem: o aviso (o que fazer, e ✕ quando pronto), o jogo com o
 * relógio, o fim com o veredito de cada jogador — e a pausa no meio.
 *
 * O desenho é o mesmo em todas, para quem joga aprender uma vez:
 *
 *   AVISO  o nome da sala, o padrão de jogo que ela reproduz e como jogar;
 *          cada jogador aperta ✕ quando está pronto;
 *   JOGO   a sala roda; em cima, o nome e o tempo; cada jogador na sua faixa;
 *   FIM    os pontos e, por feature, o selo (PASSOU / FALHOU / NÃO MEDIDO) com
 *          o que foi medido; ✕ volta ao salão (ou segue a Prova de Fogo),
 *          △ refaz a sala.
 *
 * O veredito entra no relatório no FIM, uma vez, só de quem estava na mesa
 * quando a sala começou. Quem abandona pela pausa não deixa veredito: a sala
 * fica "não medido". */
#ifndef DEMO_SALA_BASE_H
#define DEMO_SALA_BASE_H

#include "../app.h"
#include "../nucleo/medidas.h"

#define SALA_MAX_FEATS 4

typedef enum FaseSala { FASE_AVISO = 0, FASE_JOGO, FASE_FIM } FaseSala;

typedef enum ModoFaixas {
  FAIXAS_COLUNAS = 0, /* lado a lado */
  FAIXAS_LINHAS,      /* uma embaixo da outra */
  FAIXAS_QUADRANTES   /* dois por dois */
} ModoFaixas;

typedef struct SalaBase {
  Sala sala;
  FaseSala fase;
  float t_fase;  /* segundos na fase atual */
  float duracao; /* do jogo, em segundos */
  bool pronto[MAX_JOGADORES];
  bool jogando[MAX_JOGADORES]; /* na mesa quando o jogo começou */
  bool mexeu[MAX_JOGADORES];   /* algo chegou deste controle durante o jogo */
  bool acabou[MAX_JOGADORES];  /* o jogador terminou a parte dele */
  int pontos[MAX_JOGADORES];
  Feature feats[SALA_MAX_FEATS];
  int n_feats;
  Veredito vered[MAX_JOGADORES][SALA_MAX_FEATS];
  bool tem_vered[MAX_JOGADORES][SALA_MAX_FEATS];
  float robo_t;
  float fim_brilho;
  /* o acaso desta sala: a semente da sessão, a sala e a vez (ADR-003) — a
   * mesma semente refaz a mesma sala, qualquer que seja o caminho até ela */
  Sorteio sorteio;
  int vez;
} SalaBase;

/* No `entrar` da sala. */
void sb_entrar(App *a, SalaBase *b, Sala sala, const Feature *feats, int n_feats, float duracao);

/* No começo do `atualizar` da sala. Trata a pausa, o aviso e o fim. Devolve a
 * fase em que a sala deve rodar a lógica dela neste quadro, ou -1 quando a
 * sala não deve fazer nada (pausa aberta, troca de cena pedida). */
int sb_atualizar(App *a, SalaBase *b, float dt);

/* Todos os jogadores que estão jogando acabaram? (ou o relógio acabou) */
bool sb_todos_acabaram(App *a, const SalaBase *b);
float sb_resta(const SalaBase *b);

/* O veredito de um jogador numa feature da sala (guardado; entra no relatório
 * no `sb_terminar`). */
void sb_veredito(SalaBase *b, int slot, Feature f, const Veredito *v);
/* Do jogo para o fim: grava os vereditos no relatório e na linha do tempo. */
void sb_terminar(App *a, SalaBase *b, NivelEvidencia nivel);

/* Um marco de entrada na linha do tempo ("o primeiro toque chegou"). */
void sb_marco(App *a, int slot, const char *o_que, const char *detalhe);

/* As faixas dos jogadores que estão jogando: devolve quantas, com o retângulo
 * e o slot de cada uma. `area` é o espaço disponível. */
int sb_faixas(App *a, const SalaBase *b, ModoFaixas modo, SDL_FRect area, SDL_FRect *rects, int *slots);
/* A moldura de uma faixa: o painel com a cor do jogador e o escudo. */
void sb_moldura(App *a, SDL_FRect f, int slot, float destaque);
/* Só o escudo (para redesenhar por cima do cenário da sala). */
void sb_escudo(App *a, SDL_FRect f, int slot);
/* O aviso sobre a faixa de quem ficou sem controle. */
void sb_sem_controle(App *a, SDL_FRect f, int slot);

/* O desenho comum: o topo (nome e tempo) no jogo; o aviso; o fim. */
void sb_desenhar_topo(App *a, const SalaBase *b);
void sb_desenhar_aviso(App *a, const SalaBase *b, const char *como_jogar);
void sb_desenhar_fim(App *a, const SalaBase *b);

/* Quando o SDL recusou a saída (o veredito ficou em MONTOU), diz por quê: o
 * rádio nativo, que este jogo só lê, ou a origem do controle. */
void sb_explica_recusa(App *a, int slot, Veredito *v);

/* Pontos para um jogador (somam também no placar da mesa). */
void sb_pontos(App *a, SalaBase *b, int slot, int pontos);

/* O x de uma faixa em [-1, 1], para pôr o som no lado dela. */
float sb_pan(SDL_FRect f);

#endif
