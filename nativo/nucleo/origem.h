#ifndef DEMO_ORIGEM_H
#define DEMO_ORIGEM_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum OrigemTipo {
  ORIGEM_DESCONHECIDA = 0,
  ORIGEM_DUALSENSE_NATIVO,
  ORIGEM_EDGE_NATIVO,
  ORIGEM_DUALSENSE_VIRTUAL_UHID,
  ORIGEM_EDGE_VIRTUAL_UHID,
  ORIGEM_DUALSENSE_VIRTUAL_UINPUT,
  ORIGEM_XBOX_VIRTUAL_UINPUT,
  ORIGEM_XBOX_NATIVO,
  ORIGEM_ESPELHO_STEAM,
  ORIGEM_OUTRO_VIRTUAL,
  ORIGEM_OUTRO
} OrigemTipo;

typedef enum Conexao {
  CONEXAO_DESCONHECIDA = 0,
  CONEXAO_USB,
  CONEXAO_BT,
  CONEXAO_VIRTUAL_USB,
  CONEXAO_VIRTUAL
} Conexao;

#define ORIGEM_BUS_USB 0x03
#define ORIGEM_BUS_BT 0x05

typedef struct OrigemFatos {
  int tem_sysfs;
  int bus;
  unsigned vid, pid;
  char caminho_real[512];
  char usb_pai[512];
  char phys[128];
  char nome_sistema[128];
  int conexao_sdl;
  int windows;
  int wine;
  int hidraw_sem_permissao;
} OrigemFatos;

typedef struct Origem {
  OrigemTipo tipo;
  Conexao conexao;
  int inferida;
  char evidencia[160];
  int hidraw_sem_permissao;
} Origem;

void origem_classificar(const OrigemFatos *f, Origem *out);
const char *origem_rotulo(OrigemTipo t);
const char *origem_rotulo_curto(OrigemTipo t);
const char *conexao_rotulo(Conexao c);
int origem_eh_dualsense(OrigemTipo t);
int origem_eh_virtual(OrigemTipo t);
int origem_aceitar_na_sessao(int so_virtuais, int virtual_do_sdl);

const char *origem_raiz_sysfs(void);
const char *origem_raiz_dev(void);

int origem_fatos_linux(const char *caminho_sdl, OrigemFatos *f);

int origem_usb_de(const char *caminho, char *out, size_t tam);

#ifdef __cplusplus
}
#endif

#endif
