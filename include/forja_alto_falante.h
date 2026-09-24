/* FORJA — o alto-falante do DualSense, achado como um JOGO o acha.
 *
 * Um jogo tem dois jeitos de achar o alto-falante do controle, e esta mesa
 * prova os dois:
 *
 *   1. PELO APARELHO — o port de PS5 casa o endpoint de áudio com o controle
 *      pelo ContainerId, que o Wine tira do pai USB do `sysfs.path` do nó
 *      (winepulse.drv, get_container_id). Aqui: forja_no_do_pad().
 *   2. PELO NOME — o jogo mostra a lista de saídas e a pessoa aponta. Sob
 *      Proton o nome que ele mostra é a DESCRIÇÃO do nó (get_device_name), e
 *      o alto-falante do controle é o que tem "DualSense" ou "Wireless
 *      Controller" nela. Aqui: forja_no_por_nome().
 *
 * Nenhum dos dois conhece o daemon que estiver atrás. PROIBIDO aqui: socket
 * IPC, uniq, MAC, relatório 0x31.
 */
#ifndef FORJA_ALTO_FALANTE_H
#define FORJA_ALTO_FALANTE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define FORJA_TAXA 48000
/* No sink de 4 canais do DualSense, só o canal 1 (front-right) chega ao
 * alto-falante; o 0 é o fone esquerdo e o 2 e o 3 são os dois atuadores
 * voice-coil. Medido de ouvido na bancada do Hefesto em 16/08/2026. */
#define FORJA_CANAL_DO_ALTO_FALANTE 1
#define FORJA_CANAL_VCM_E 2
#define FORJA_CANAL_VCM_D 3

typedef struct ForjaNoDeSom {
  int indice;          /* o "Sink #N" do servidor */
  char nome[256];      /* Name: — o que o motor abre */
  char descricao[256]; /* Description: — o nome que o jogo MOSTRA */
  int canais;          /* da Sample Specification; 0 se não veio */
  char sysfs[512];     /* sysfs.path, "" sem */
  int usb_da_sony;     /* device.bus=usb + 054c + 0ce6/0df2 no proplist */
} ForjaNoDeSom;

/* Lê a saída de `LC_ALL=C pactl list sinks` e devolve quantos nós são de
 * DualSense (até `max`). `total` recebe quantas saídas o servidor tem. */
int forja_nos_de_som(const char *texto, ForjaNoDeSom *nos, int max, int *total);

/* 1 se o nome ou a descrição trazem a palavra da Sony (sem caixa). Monitor e
 * nó de captura nunca são alto-falante. */
int forja_e_do_dualsense(const char *nome, const char *descricao);

/* O primeiro nó cujo nome ou descrição contém `texto` (sem caixa); -1 sem. */
int forja_no_por_nome(const ForjaNoDeSom *nos, int n, const char *texto);

/* O nó cujo `sysfs.path` sobe ao MESMO usb_device do pad; -1 sem. */
int forja_no_do_pad(const ForjaNoDeSom *nos, int n, const char *usb_do_pad);

/* O mapa que o pw-cat entende para `canais`, ou NULL quando não sabemos. */
const char *forja_mapa_de_canais(int canais);

/* O canal do alto-falante num nó de `canais`: o 1 (FR) quando há frente
 * estéreo, o 0 num nó mono. */
int forja_canal_do_alto_falante(int canais);

/* Um tom senoidal de `n_quadros` quadros intercalados de `canais` canais: o
 * tom no `canal_a` (e no `canal_b`, se >= 0) e ZERO em todos os outros. O zero
 * nos demais é o ponto: é o que transforma "ouvi" em "ouvi ALI". */
void forja_tom(int16_t *pcm, long n_quadros, int canais, int canal_a, int canal_b,
               double hz);

#ifdef __cplusplus
}
#endif

#endif
