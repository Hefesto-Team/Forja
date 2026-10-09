/* De onde veio o controle — o que o cartão do lobby diz.
 *
 * Um mesmo DualSense pode chegar ao jogo por quatro caminhos, e a mesa precisa
 * saber qual deles cada controle usou, porque a pergunta "quem traduziu?" muda
 * com a resposta:
 *
 *   - DualSense nativo, no cabo (hid-playstation sobre USB);
 *   - DualSense nativo, no rádio (hidp, ou uhid do BlueZ >= 5.73, bus 0005);
 *   - DualSense Edge VIRTUAL, por uhid: um nó que declara USB (bus 0003) e mora
 *     em /devices/virtual/misc/uhid — não tem pai USB nenhum;
 *   - pad Xbox 360 VIRTUAL, por uinput: evdev puro, em /devices/virtual/input.
 *
 * No Linux a origem sai do sysfs, lido a partir do caminho que o SDL entrega
 * (SDL_GetGamepadPath). No Windows (e sob o Proton) o jogo só vê o HID que o
 * Wine publica: a origem é inferida pelo VID:PID e marcada como inferida.
 *
 * O que NÃO se lê aqui, e o contrato é o motivo: HID_UNIQ, `uniq`, qualquer
 * endereço. O `phys` passa pela máscara antes de virar texto.
 */
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
  CONEXAO_VIRTUAL_USB, /* nó virtual que se declara USB */
  CONEXAO_VIRTUAL
} Conexao;

#define ORIGEM_BUS_USB 0x03
#define ORIGEM_BUS_BT 0x05

/* Os fatos que a classificação usa — coletados do sysfs (Linux) ou do que o
 * SDL diz (Windows). Separados da coleta para que a regra seja testável. */
typedef struct OrigemFatos {
  int tem_sysfs;          /* 1 quando veio do sysfs */
  int bus;                /* HID_ID / id/bustype; -1 desconhecido */
  unsigned vid, pid;
  char caminho_real[512]; /* realpath do dispositivo no sysfs (interno) */
  char usb_pai[512];      /* o usb_device acima dele, "" sem (interno) */
  char phys[128];         /* HID_PHYS / phys, já mascarado */
  char nome_sistema[128]; /* HID_NAME / name */
  int conexao_sdl;        /* 0 desconhecida, 1 com fio, 2 sem fio */
  int windows;            /* build Windows */
  int wine;               /* Windows sob Wine/Proton */
} OrigemFatos;

typedef struct Origem {
  OrigemTipo tipo;
  Conexao conexao;
  int inferida; /* 1 quando não veio do sysfs */
  char evidencia[160];
} Origem;

void origem_classificar(const OrigemFatos *f, Origem *out);
const char *origem_rotulo(OrigemTipo t);
const char *origem_rotulo_curto(OrigemTipo t); /* para o chip do cartão */
const char *conexao_rotulo(Conexao c);
/* 1 quando o controle fala o DualSense inteiro (efeitos, sensores, toque). */
int origem_eh_dualsense(OrigemTipo t);
/* 1 quando a origem é um nó virtual (uhid ou uinput). */
int origem_eh_virtual(OrigemTipo t);
/* A sessão aberta com --simular só aceita o controle virtual do SDL (o
 * SDL_AttachVirtualJoystick do simulador): numa prova, o DualSense ligado na
 * máquina não ganha lugar. `so_virtuais` é a marca da sessão (nasceu com
 * --simular), `virtual_do_sdl` diz se o controle que chegou é do simulador.
 * 1 aceita, 0 recusa. */
int origem_aceitar_na_sessao(int so_virtuais, int virtual_do_sdl);

/* A raiz do sysfs: FORJA_SYSFS (as provas montam um sysfs de mentira) ou /sys. */
const char *origem_raiz_sysfs(void);

/* Linux: coleta os fatos a partir do caminho do SDL ("/dev/hidraw5",
 * "/dev/input/event12"). Devolve 1 se achou o dispositivo no sysfs. Nas outras
 * plataformas devolve 0 e deixa `f` como veio. */
int origem_fatos_linux(const char *caminho_sdl, OrigemFatos *f);

/* Sobe de `caminho` (dentro do sysfs) até a pasta que tem `busnum` e `devnum`.
 * 0 se achou e escreveu em `out`; -1 se não há pai USB. Só no Linux. */
int origem_usb_de(const char *caminho, char *out, size_t tam);

#ifdef __cplusplus
}
#endif

#endif
