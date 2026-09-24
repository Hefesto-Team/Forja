/* FORJA — a mesa: os DualSense em hidraw, na MESMA ordem para todo binário.
 *
 * forja-send, forja-speak e forja-read perguntam aqui, e o "player N" de um é
 * o "player N" dos outros. Sem isso o gatilho do P3 e o alto-falante do P3
 * poderiam ser dois controles diferentes, e a mesa mediria o vizinho.
 *
 * PROIBIDO aqui, como em todo este repo: uniq, MAC, socket IPC.
 */
#ifndef FORJA_MESA_H
#define FORJA_MESA_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define FORJA_BUS_USB 3
#define FORJA_BUS_BT 5

typedef struct ForjaPad {
  char hidraw[256]; /* "hidraw3" */
  char path[272];  /* "/dev/hidraw3" */
  int bus;         /* 3 = USB, 5 = Bluetooth */
  int pid;
} ForjaPad;

/* A raiz do sysfs: "/sys", ou FORJA_SYSFS — que só a selftest usa, para
 * montar uma mesa de mentira sem tocar em aparelho nenhum. */
const char *forja_sysfs(void);

/* Os DualSense (054c:0ce6 / 0df2) em hidraw, na ordem do diretório. */
int forja_mesa_pads(ForjaPad *pads, int max);

/* O `usb_device` acima de um caminho do sysfs: sobe até a pasta que tem
 * `busnum` e `devnum`. É o mesmo pai de onde o Wine tira o ContainerId de um
 * endpoint de áudio (`get_container_id`), e por isso é por ele que um jogo
 * casa o controle com o alto-falante dele. 0 se achou, -1 se não há. */
int forja_usb_de(const char *caminho, char *out, size_t tam);

/* O `usb_device` do pad — -1 quando ele não está num USB (rádio, virtual). */
int forja_usb_do_pad(const ForjaPad *pad, char *out, size_t tam);

#ifdef __cplusplus
}
#endif

#endif
