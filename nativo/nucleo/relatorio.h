/* O relatório da sessão — o que foi pedido, o que foi medido, e o veredito.
 *
 * Um arquivo JSON (para máquina) e um de texto (para gente), escritos juntos,
 * a cada estação que termina: se o jogo cair no meio, o que já se mediu fica.
 *
 * Três vereditos, e só três: PASSOU, FALHOU, NÃO MEDIDO. O "não medido" não é
 * um "passou" tímido — é o jogo dizendo que não teve como saber (a estação não
 * foi jogada, o controle não tem o canal, o alto-falante não foi achado). O
 * motivo vai junto, sempre.
 *
 * A escada de evidência do Hefesto entra no campo `nivel` das features de
 * saída: MONTOU (o payload existe) → SAIU (a chamada ao SDL voltou ok) →
 * OBEDECEU (a pessoa, às cegas, sentiu o que foi mandado). Só o último é
 * aceite; os dois primeiros são o que o jogo sabe sozinho.
 *
 * Nada de caminho da máquina, nada de endereço de hardware: todo texto que
 * entra aqui passa pela máscara de MAC.
 */
#ifndef DEMO_RELATORIO_H
#define DEMO_RELATORIO_H

#include "catalogo.h"

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define REL_MAX_CONTROLES 4

typedef enum Resultado {
  RES_NAO_MEDIDO = 0,
  RES_PASSOU,
  RES_FALHOU
} Resultado;

typedef enum NivelEvidencia {
  NIVEL_NENHUM = 0,
  NIVEL_MONTOU,   /* o payload existe */
  NIVEL_SAIU,     /* o SDL aceitou a chamada */
  NIVEL_OBEDECEU, /* a pessoa sentiu, às cegas, o que foi mandado */
  NIVEL_REAGIU    /* o jogo leu de volta (entrada) */
} NivelEvidencia;

typedef struct RelSom {
  char nome[160]; /* o nome que o jogo mostra (descrição do nó / endpoint) */
  char como[96];  /* "pelo aparelho (ContainerId)", "pelo nome", "não achado" */
  int canais;
} RelSom;

typedef struct RelControle {
  int presente;
  int jogador;             /* 1..4 */
  char nome[128];          /* o nome que o SDL dá */
  char nome_do_sistema[128]; /* o nome que o kernel publica (Linux), "" sem */
  char vid_pid[16];        /* "054c:0ce6" */
  char conexao[48];        /* "USB", "Bluetooth", "virtual (declara USB)" */
  char origem[64];         /* "DualSense nativo", "DualSense Edge virtual (uhid)", ... */
  char evidencia[160];     /* de onde a origem foi tirada */
  char tipo_sdl[32];       /* "ps5", "xbox360", ... */
  char firmware[16];
  char bateria[48];
  double giro_declarado_hz, giro_medido_hz, giro_medido_relogio_hz;
  double acel_declarado_hz, acel_medido_hz;
  RelSom alto_falante, microfone, haptica;
  int reconexoes;
  int hidraw_sem_permissao; /* a causa do «efeitos não»: REL_CAUSA_HIDRAW */
} RelControle;

/* A causa, no registro e no relatório, quando o hidraw do controle da Sony não
 * dá leitura e escrita a quem joga (a WU03). Fica fora da tela. */
#define REL_CAUSA_HIDRAW "sem permissão no hidraw: os efeitos não chegam"

typedef struct RelItem {
  int jogador; /* 1..4 */
  Feature feature;
  Resultado resultado;
  NivelEvidencia nivel;
  char pedido[320];
  char medido[480];
  char observacao[320];
  double t; /* segundos desde o início da sessão */
} RelItem;

typedef struct Relatorio {
  char sessao[40];     /* "20260927-193005" */
  char inicio[32];     /* "2026-09-27 19:30:05" */
  char fim[32];
  char versao[48];     /* git describe do build */
  char plataforma[128];
  char sdl[48];
  char contrato[200];
  unsigned long long semente;
  RelControle controles[REL_MAX_CONTROLES];
  RelItem *itens;
  int n_itens, cap_itens;
  char notas[8][200]; /* observações da mesa inteira */
  int n_notas;
} Relatorio;

void rel_iniciar(Relatorio *r);
void rel_liberar(Relatorio *r);

/* Registra uma tentativa. As strings são mascaradas na entrada. Devolve o item
 * (válido até o próximo registro), ou NULL sem memória. */
RelItem *rel_registrar(Relatorio *r, int jogador, Feature f, Resultado res, NivelEvidencia nivel,
                       const char *pedido, const char *medido, const char *observacao, double t);

/* A última tentativa de `jogador` em `f`, ou NULL (= não medido). */
const RelItem *rel_ultimo(const Relatorio *r, int jogador, Feature f);

/* Uma observação da mesa inteira (mascarada). */
void rel_nota(Relatorio *r, const char *texto);

/* Mascara e copia `de` para um campo do relatório. */
void rel_copiar(char *campo, size_t tam, const char *de);

const char *rel_resultado_rotulo(Resultado res); /* "passou" | "falhou" | "não medido" */
const char *rel_nivel_rotulo(NivelEvidencia n);

/* Monta o JSON e o texto. Devolvem 0 e entregam um texto que o chamador libera
 * com free(); -1 sem memória. */
int rel_json(const Relatorio *r, char **saida, size_t *tam);
int rel_texto(const Relatorio *r, char **saida, size_t *tam);

#ifdef __cplusplus
}
#endif

#endif
