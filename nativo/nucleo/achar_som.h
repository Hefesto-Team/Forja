/* Achar o som de cada controle — a lógica pura, sem SDL e sem sistema.
 *
 * O jogo abre o controle como um SEGUNDO dispositivo de áudio, além da saída
 * principal (é assim no PC: ValveSoftware/Proton#5900 lista os jeitos que os
 * jogos usam). Três perguntas para cada jogador — de onde sai o alto-falante,
 * de onde sai a háptica, de onde entra o microfone — e três jeitos de
 * responder, nesta ordem:
 *
 *   1. PELO APARELHO — o dispositivo de áudio que mora no MESMO aparelho do
 *      controle: no Linux, o nó cujo `sysfs.path` sobe ao mesmo usb_device
 *      do pad; no Windows (e sob Proton), o endpoint com o mesmo ContainerId
 *      do HID. É o que fazem os ports de PS5;
 *   2. PELO NÚMERO — um nó que diz de qual controle é pelo nome («Alto-falante
 *      do Controle 2 (DualSense Wireless Controller)», como o Hefesto batiza
 *      os seus), com o número do lugar à mesa. A pessoa confere;
 *
 * Em todos, só conta o nó que um jogo reconheceria como DualSense pela
 * palavra da Sony ("DualSense" ou "Wireless Controller"), como manda o
 * CONTRATO.md; nunca por MAC.
 *   3. PELO NOME — o primeiro dispositivo livre com "DualSense" ou "Wireless
 *      Controller" no nome, como fazem os jogos que procuram pela palavra. A
 *      pessoa confere, e troca se não for o dela.
 *
 * Numa placa de quatro canais do DualSense no cabo, o canal 1 (front-right)
 * é o alto-falante e os canais 2 e 3 são os dois atuadores (medido na bancada
 * do Hefesto). Nos nós do Hefesto, cada papel tem o seu nó.
 */
#ifndef DEMO_ACHAR_SOM_H
#define DEMO_ACHAR_SOM_H

#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define SOM_MAX_NOS 32

typedef enum PapelSom { PAPEL_ALTO_FALANTE = 0, PAPEL_HAPTICA, PAPEL_MICROFONE, PAPEL_TOTAL } PapelSom;

typedef enum TipoNoSom {
  NO_OUTRO = 0,         /* a TV, a caixa, o fone: não é do controle */
  NO_DUALSENSE_SAIDA,   /* a placa do controle (4 canais no cabo) */
  NO_DUALSENSE_ENTRADA, /* o microfone do controle */
  NO_NUMERADO_FALANTE,  /* «Alto-falante do Controle N» */
  NO_NUMERADO_HAPTICA,  /* «Háptica do Controle N» */
  NO_NUMERADO_MIC       /* «Microfone do Controle N» */
} TipoNoSom;

typedef enum ComoAchou {
  ACHOU_NADA = 0,
  ACHOU_APARELHO, /* o mesmo USB, ou o mesmo ContainerId */
  ACHOU_NUMERO,   /* «... do Controle N» com o N do lugar */
  ACHOU_NOME,     /* a palavra da Sony no nome */
  ACHOU_PESSOA    /* a pessoa apontou na lista */
} ComoAchou;

/* Um nó como o SISTEMA o descreve (Linux: `pactl list sinks|sources`, que o
 * PipeWire responde pelo pipewire-pulse). */
typedef struct NoSistema {
  int indice;
  bool gravacao;
  char nome[256];      /* Name: */
  char descricao[256]; /* Description: — o nome que o jogo mostra */
  int canais;
  char sysfs[512];     /* sysfs.path */
  char bus[16];        /* device.bus */
  long vid, pid;
} NoSistema;

/* Um dispositivo como o JOGO o vê (a lista do SDL), com o que se soube dele. */
typedef struct NoSom {
  char nome[160];
  int canais;
  bool gravacao;
  TipoNoSom tipo;
  int controle_n;      /* o N de «... do Controle N»; 0 sem */
  char usb[512];       /* o usb_device do aparelho por trás; "" sem */
  char container[48];  /* o ContainerId (Windows); "" sem */
  int no_sistema;      /* índice na lista do sistema; -1 sem */
} NoSom;

/* Lê a saída de `LC_ALL=C pactl list sinks` (ou `sources`) e devolve quantos
 * nós leu (até `max`). Os monitores (a saída vista de dentro) ficam de fora. */
int achar_ler_pactl(const char *texto, bool gravacao, NoSistema *nos, int max);

TipoNoSom achar_tipo(const char *nome, bool gravacao);
/* O N de «... do Controle N»; 0 quando o nome não diz. */
int achar_numero(const char *nome);
/* O nó serve para o papel? */
bool achar_serve(TipoNoSom tipo, PapelSom papel);

/* Casa a lista do jogo com a do sistema pelo nome que o jogo mostra; entre
 * nomes repetidos, o k-ésimo com o k-ésimo (as duas listas andam na ordem de
 * criação dos nós). Preenche `no_sistema`. */
void achar_casar(NoSom *jogo, int n_jogo, const NoSistema *sis, int n_sis);

/* O dispositivo para um jogador num papel: o índice em `nos`, ou -1. `usado`
 * marca o que outro jogador já levou (um dispositivo, um dono). */
int achar_para(const NoSom *nos, int n, PapelSom papel, const char *usb_do_pad, const char *container_do_pad,
               int numero_na_mesa, const bool *usado, ComoAchou *como);

/* Os canais de um papel num nó: o alto-falante e os dois atuadores. -1 quando
 * o nó não tem o canal. */
void achar_canais(const NoSom *no, PapelSom papel, int *canal_a, int *canal_b);

const char *achar_como_rotulo(ComoAchou c);

#ifdef __cplusplus
}
#endif

#endif
