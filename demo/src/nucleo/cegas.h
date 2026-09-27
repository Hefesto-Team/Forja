/* As provas às cegas: o degrau OBEDECEU da escada de evidência.
 *
 * Uma saída (vibração, luz, gatilho) o jogo não mede sozinho: ele sabe o que
 * MONTOU e se o SDL aceitou (SAIU), mas não se o plástico obedeceu. Quem sabe
 * é quem segura o controle — desde que não possa adivinhar pela tela. Então as
 * salas de saída escondem a resposta e perguntam:
 *
 *   - de que lado veio o golpe? (o Cerco: o motor da esquerda ou da direita)
 *   - a vibração chegou no SEU controle? (o Cerco: o golpe fantasma)
 *   - de que cor está a sua luz? (o Cerco: a lightbar)
 *   - que arma é esta? (a Galeria: o modo do gatilho, sentido no dedo)
 *   - quantas balas você tem? (a Galeria: os LEDs de jogador)
 *
 * E a estatística decide com folga para o acaso: um veredito de "passou" por
 * chute tem chance pequena, e o inconclusivo vira NÃO MEDIDO, com o pedido de
 * refazer. Lógica pura: provada sem aparelho.
 */
#ifndef DEMO_CEGAS_H
#define DEMO_CEGAS_H

#include "aleatorio.h"
#include "medidas.h"

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define CEGA_OPCOES 8

/* Um conjunto de tentativas às cegas de uma pergunta. */
typedef struct Cega {
  int certos, errados, perdidos; /* perdido: não respondeu a tempo */
  int respondeu_como[CEGA_OPCOES]; /* nas erradas, o que a pessoa disse */
} Cega;

void cega_zerar(Cega *c);
void cega_certo(Cega *c);
void cega_errado(Cega *c, int disse);
void cega_perdido(Cega *c);
int cega_total(const Cega *c);

/* ---------- o Cerco ---------- */

typedef enum Lado { LADO_ESQ = 0, LADO_DIR = 1 } Lado;

typedef struct Tiro {
  int slot;  /* o alvo */
  Lado lado;
} Tiro;

/* O plano dos golpes: `por_lado` golpes de cada lado para cada jogador de
 * `slots`, embaralhados pela semente, um de cada vez, sem o mesmo jogador duas
 * vezes seguidas quando há mais de um. Devolve quantos. */
int cegas_plano_tiros(Sorteio *s, const int *slots, int n, int por_lado, Tiro *out, int max);

/* O motor de um lado (esquerdo = forte, direito = fraco). `sdl_aceitou` é o
 * SAIU: se o SDL recusou a vibração, não há o que perguntar. `reagiu` diz se a
 * pessoa levantou o escudo alguma vez na sala (senão, ninguém estava jogando). */
Veredito cega_motor_veredito(const Cega *c, Lado lado, bool sdl_aceitou, bool reagiu);
/* O isolamento: quantas vezes a pessoa levantou o escudo com o golpe indo para
 * OUTRO controle, em quantas chances; e como ela foi nos golpes dela. */
Veredito cega_isolamento_veredito(int fantasmas, int chances, int vizinhos, const Cega *proprios);
/* A cor da luz: respostas certas e erradas às perguntas de cor. */
Veredito cega_cor_veredito(const Cega *c, bool sdl_aceitou);
/* Pergunta de cor: quando parar (3 certas ou 2 erradas). */
bool cega_cor_decidida(const Cega *c);

/* ---------- a Galeria ---------- */

typedef enum Arma {
  ARMA_PISTOLA = 0, /* Weapon: parede e clique */
  ARMA_METRALHADORA, /* Vibration */
  ARMA_ARCO,         /* Feedback: resistência */
  ARMA_NENHUMA,      /* Off: o gatilho solto */
  ARMA_TOTAL
} Arma;

const char *cegas_nome_arma(Arma a);
/* O plano das rodadas: cada arma `vezes` vezes, embaralhadas, sem repetir a
 * mesma em seguida. Devolve quantas. */
int cegas_plano_armas(Sorteio *s, int vezes, Arma *out, int max);
/* O veredito de um modo de gatilho (a arma dele), com o que a pessoa disse nas
 * erradas; `nenhuma` é como ela foi na rodada sem arma (o Off). */
Veredito cega_arma_veredito(Arma arma, const Cega *c, const Cega *nenhuma, bool sdl_aceitou);
/* A arma já tem veredito, ou vale mais uma rodada dela? */
bool cega_arma_decidida(const Cega *c);
/* As perguntas de munição (LEDs de jogador). */
Veredito cega_leds_veredito(const Cega *c, bool sdl_aceitou);

/* ---------- as salas de som ---------- */

/* Um plano genérico: `fontes[i]` aparece `vezes[i]` vezes, embaralhado pela
 * semente, sem a mesma fonte duas vezes seguidas quando há outra. */
int cegas_plano_fontes(Sorteio *s, const int *fontes, const int *vezes, int n, int *out, int max);

/* O Canto: nas rodadas em que o canto saiu no controle dele, quantas vezes a
 * pessoa disse "foi no meu"; e quantas vezes ela disse isso com o canto saindo
 * em OUTRO lugar (outro controle, ou a TV), em quantas chances. */
Veredito cega_alto_falante_veredito(const Cega *meus, int fantasmas, int chances, bool tem_alto_falante);
/* Os Caminhos: o chão reconhecido pela textura, e o tropeço de cada lado.
 * As respostas: no chão, 0..3 são os chãos (chao.h) e CAMINHO_NADA é "não
 * senti nada"; no tropeço, 0 é a esquerda, 1 a direita e CAMINHO_NADA_LADO
 * "não senti". O "não senti" dito é a evidência de que a mão não recebeu —
 * o silêncio (não responder) não reprova ninguém. */
#define CAMINHO_NADA 4
#define CAMINHO_NADA_LADO 2
Veredito cega_haptica_veredito(const Cega *chao, const Cega *lado_esq, const Cega *lado_dir, bool tem_haptica);
/* A Cripta: como está a luz do microfone (apagada, acesa, piscando). */
Veredito cega_led_mic_veredito(const Cega *c, bool sdl_aceitou);
bool cega_led_mic_decidida(const Cega *c);

#ifdef __cplusplus
}
#endif

#endif
