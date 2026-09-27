/* A pausa: Options abre, em qualquer sala e no hub. Continuar, a bancada, o
 * livro, as configurações de acessibilidade, voltar, sair. */
#ifndef DEMO_PAUSA_H
#define DEMO_PAUSA_H

#include <stdbool.h>

struct App;

typedef enum PausaAcao {
  PAUSA_NADA = 0,
  PAUSA_CONTINUAR,
  PAUSA_REFAZER,   /* só nas salas */
  PAUSA_ABANDONAR, /* só nas salas: volta ao hub, a sala fica "não medido" */
  PAUSA_DIAGNOSTICO,
  PAUSA_RELATORIO,
  PAUSA_TITULO,
  PAUSA_SAIR
} PausaAcao;

void pausa_abrir(struct App *a, bool em_sala, int quem);
bool pausa_aberta(void);
PausaAcao pausa_atualizar(struct App *a);
void pausa_desenhar(struct App *a);

#endif
