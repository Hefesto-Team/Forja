/* A origem do controle: a regra, e a coleta num sysfs de mentira. */
#if defined(__linux__)
#define _XOPEN_SOURCE 700
#endif

#include "prova.h"

#include "origem.h"

#include <stdlib.h>

static void fatos(OrigemFatos *f, int bus, unsigned vid, unsigned pid, const char *real,
                  const char *usb) {
  memset(f, 0, sizeof(*f));
  f->tem_sysfs = 1;
  f->bus = bus;
  f->vid = vid;
  f->pid = pid;
  snprintf(f->caminho_real, sizeof(f->caminho_real), "%s", real);
  snprintf(f->usb_pai, sizeof(f->usb_pai), "%s", usb ? usb : "");
}

static void provas_da_regra(void) {
  OrigemFatos f;
  Origem o;

  fatos(&f, 3, 0x054c, 0x0ce6, "/sys/devices/pci0000:00/usb3/3-4/3-4:1.3/0003:054C:0CE6.0001",
        "/sys/devices/pci0000:00/usb3/3-4");
  origem_classificar(&f, &o);
  espera(o.tipo == ORIGEM_DUALSENSE_NATIVO && o.conexao == CONEXAO_USB, "nativo no cabo");
  espera(!o.inferida, "do sysfs não é inferida");

  fatos(&f, 5, 0x054c, 0x0ce6, "/sys/devices/pci0000:00/usb1/1-2/1-2:1.0/bluetooth/hci0/hci0:256/0005:054C:0CE6.0002",
        "/sys/devices/pci0000:00/usb1/1-2");
  origem_classificar(&f, &o);
  espera(o.tipo == ORIGEM_DUALSENSE_NATIVO && o.conexao == CONEXAO_BT,
         "nativo no rádio (o pai USB é o adaptador, e não importa)");

  fatos(&f, 5, 0x054c, 0x0ce6, "/sys/devices/virtual/misc/uhid/0005:054C:0CE6.0007", NULL);
  origem_classificar(&f, &o);
  espera(o.tipo == ORIGEM_DUALSENSE_NATIVO && o.conexao == CONEXAO_BT,
         "BlueZ >= 5.73 publica o físico por uhid com bus 0005: continua nativo");

  fatos(&f, 3, 0x054c, 0x0df2, "/sys/devices/virtual/misc/uhid/0003:054C:0DF2.000A", NULL);
  snprintf(f.phys, sizeof(f.phys), "vpad");
  origem_classificar(&f, &o);
  espera(o.tipo == ORIGEM_EDGE_VIRTUAL_UHID, "Edge por uhid, declarando USB, é virtual");
  espera(o.conexao == CONEXAO_VIRTUAL_USB, "e a conexão diz que ele declara USB");
  espera(strstr(o.evidencia, "sem pai USB") != NULL, "a evidência diz por quê");
  espera(origem_eh_virtual(o.tipo) && origem_eh_dualsense(o.tipo), "virtual e DualSense");

  fatos(&f, 3, 0x045e, 0x028e, "/sys/devices/virtual/input/input42", NULL);
  origem_classificar(&f, &o);
  espera(o.tipo == ORIGEM_XBOX_VIRTUAL_UINPUT, "Xbox por uinput");
  espera(!origem_eh_dualsense(o.tipo), "o Xbox não fala DualSense");

  fatos(&f, 3, 0x045e, 0x028e, "/sys/devices/pci0000:00/usb3/3-2/3-2:1.0/input/input7",
        "/sys/devices/pci0000:00/usb3/3-2");
  origem_classificar(&f, &o);
  espera(o.tipo == ORIGEM_XBOX_NATIVO, "Xbox de verdade, pelo xpad");

  fatos(&f, 3, 0x28de, 0x11ff, "/sys/devices/virtual/input/input50", NULL);
  origem_classificar(&f, &o);
  espera(o.tipo == ORIGEM_ESPELHO_STEAM, "o espelho do Steam Input");

  fatos(&f, 3, 0x054c, 0x0df2, "/sys/devices/virtual/input/input60", NULL);
  origem_classificar(&f, &o);
  espera(o.tipo == ORIGEM_DUALSENSE_VIRTUAL_UINPUT, "DualSense por uinput é só evdev");
  espera(!origem_eh_dualsense(o.tipo), "e não fala os efeitos do DualSense");

  /* Windows: sem sysfs, inferido */
  memset(&f, 0, sizeof(f));
  f.windows = 1;
  f.wine = 1;
  f.vid = 0x054c;
  f.pid = 0x0df2;
  f.conexao_sdl = 1;
  origem_classificar(&f, &o);
  espera(o.inferida && o.tipo == ORIGEM_EDGE_NATIVO, "no Windows a origem é inferida");
  espera(strstr(o.evidencia, "Wine") != NULL, "e diz que é o Wine");
}

#if defined(__linux__)
#include <sys/stat.h>
#include <unistd.h>

static void mkdir_p(const char *caminho) {
  char tmp[1024];
  snprintf(tmp, sizeof(tmp), "%s", caminho);
  for (char *p = tmp + 1; *p; p++) {
    if (*p == '/') {
      *p = '\0';
      mkdir(tmp, 0755);
      *p = '/';
    }
  }
  mkdir(tmp, 0755);
}

static void escreve(const char *caminho, const char *texto) {
  FILE *f = fopen(caminho, "w");
  if (f) {
    fputs(texto, f);
    fclose(f);
  }
}

static void provas_do_sysfs(void) {
  /* a pasta temporária do sistema, ou a pasta onde a prova roda: nenhum caminho
   * escrito aqui (os symlinks pedem caminho absoluto) */
  char aqui[900], raiz[1024];
  const char *base = getenv("TMPDIR");
  if (!base || !*base)
    base = getcwd(aqui, sizeof(aqui)) ? aqui : ".";
  snprintf(raiz, sizeof(raiz), "%s/forja-prova-origem-XXXXXX", base);
  if (!mkdtemp(raiz)) {
    espera(0, "mkdtemp");
    return;
  }
  char c[1200], d[1400];
  /* um DualSense no cabo */
  snprintf(c, sizeof(c), "%s/devices/usb3/3-4/3-4:1.3/0003:054C:0CE6.0001", raiz);
  mkdir_p(c);
  snprintf(d, sizeof(d), "%s/devices/usb3/3-4/busnum", raiz);
  escreve(d, "3\n");
  snprintf(d, sizeof(d), "%s/devices/usb3/3-4/devnum", raiz);
  escreve(d, "7\n");
  snprintf(d, sizeof(d), "%s/uevent", c);
  escreve(d, "DRIVER=playstation\nHID_ID=0003:0000054C:00000CE6\nHID_NAME=Sony Interactive "
             "Entertainment DualSense Wireless Controller\nHID_PHYS=usb-0000:00:14.0-4/input3\n"
             "HID_UNIQ=a0:fa:9c:00:00:f0\n");
  snprintf(d, sizeof(d), "%s/class/hidraw/hidraw3", raiz);
  mkdir_p(d);
  snprintf(d, sizeof(d), "%s/class/hidraw/hidraw3/device", raiz);
  espera(symlink(c, d) == 0, "symlink do hidraw3");

  /* um Edge virtual por uhid */
  snprintf(c, sizeof(c), "%s/devices/virtual/misc/uhid/0003:054C:0DF2.000A", raiz);
  mkdir_p(c);
  snprintf(d, sizeof(d), "%s/uevent", c);
  escreve(d, "HID_ID=0003:0000054C:00000DF2\nHID_NAME=DualSense Wireless Controller (vpad P1)\n"
             "HID_PHYS=vpad\nHID_UNIQ=02:fe:12:00:00:78\n");
  snprintf(d, sizeof(d), "%s/class/hidraw/hidraw7", raiz);
  mkdir_p(d);
  snprintf(d, sizeof(d), "%s/class/hidraw/hidraw7/device", raiz);
  espera(symlink(c, d) == 0, "symlink do hidraw7");

  /* um Xbox por uinput */
  snprintf(c, sizeof(c), "%s/devices/virtual/input/input42", raiz);
  mkdir_p(c);
  snprintf(d, sizeof(d), "%s/id", c);
  mkdir_p(d);
  snprintf(d, sizeof(d), "%s/name", c);
  escreve(d, "Microsoft X-Box 360 pad\n");
  snprintf(d, sizeof(d), "%s/id/bustype", c);
  escreve(d, "0003\n");
  snprintf(d, sizeof(d), "%s/id/vendor", c);
  escreve(d, "045e\n");
  snprintf(d, sizeof(d), "%s/id/product", c);
  escreve(d, "028e\n");
  snprintf(d, sizeof(d), "%s/class/input/event21", raiz);
  mkdir_p(d);
  snprintf(d, sizeof(d), "%s/class/input/event21/device", raiz);
  espera(symlink(c, d) == 0, "symlink do event21");

  /* o mesmo DualSense do cabo, pelo evdev (a WU03): o aparelho HID publica o
   * input30 e, ao lado, o hidraw3; o /dev de mentira tem o nó do hidraw3 */
  char hid[1200];
  snprintf(hid, sizeof(hid), "%s/devices/usb3/3-4/3-4:1.3/0003:054C:0CE6.0001", raiz);
  snprintf(d, sizeof(d), "%s/hidraw/hidraw3", hid);
  mkdir_p(d);
  snprintf(c, sizeof(c), "%s/input/input30/id", hid);
  mkdir_p(c);
  snprintf(c, sizeof(c), "%s/input/input30", hid);
  snprintf(d, sizeof(d), "%s/name", c);
  escreve(d, "Sony Interactive Entertainment DualSense Wireless Controller\n");
  snprintf(d, sizeof(d), "%s/id/bustype", c);
  escreve(d, "0003\n");
  snprintf(d, sizeof(d), "%s/id/vendor", c);
  escreve(d, "054c\n");
  snprintf(d, sizeof(d), "%s/id/product", c);
  escreve(d, "0ce6\n");
  snprintf(d, sizeof(d), "%s/class/input/event30", raiz);
  mkdir_p(d);
  snprintf(d, sizeof(d), "%s/class/input/event30/device", raiz);
  espera(symlink(c, d) == 0, "symlink do event30");
  char dev[1100], no[1200];
  snprintf(dev, sizeof(dev), "%s/dev", raiz);
  mkdir_p(dev);
  snprintf(no, sizeof(no), "%s/hidraw3", dev);
  escreve(no, "");

  setenv("FORJA_SYSFS", raiz, 1);

  OrigemFatos f;
  Origem o;
  memset(&f, 0, sizeof(f));
  espera(origem_fatos_linux("/dev/hidraw3", &f) == 1, "acha o hidraw3 no sysfs");
  espera(f.bus == 3 && f.vid == 0x054c && f.pid == 0x0ce6, "HID_ID lido");
  espera(strstr(f.nome_sistema, "DualSense") != NULL, "HID_NAME lido");
  espera(f.usb_pai[0] != '\0', "o pai USB achado");
  origem_classificar(&f, &o);
  espera(o.tipo == ORIGEM_DUALSENSE_NATIVO && o.conexao == CONEXAO_USB, "nativo no cabo");

  memset(&f, 0, sizeof(f));
  espera(origem_fatos_linux("/dev/hidraw7", &f) == 1, "acha o hidraw7");
  espera(f.usb_pai[0] == '\0', "o uhid não tem pai USB");
  espera(strcmp(f.phys, "vpad") == 0, "o phys lido");
  origem_classificar(&f, &o);
  espera(o.tipo == ORIGEM_EDGE_VIRTUAL_UHID, "Edge virtual por uhid");
  espera(strstr(f.nome_sistema, "02:fe") == NULL && strstr(o.evidencia, "02:fe") == NULL,
         "o HID_UNIQ nunca é lido");

  memset(&f, 0, sizeof(f));
  espera(origem_fatos_linux("/dev/input/event21", &f) == 1, "acha o event21");
  origem_classificar(&f, &o);
  espera(o.tipo == ORIGEM_XBOX_VIRTUAL_UINPUT, "Xbox virtual por uinput");
  espera(!f.hidraw_sem_permissao, "o Xbox não é da Sony: nada a conferir no hidraw");

  /* a WU03: o DualSense que chegou pelo evdev, com o hidraw irmão trancado */
  setenv("FORJA_DEV", dev, 1);
  espera(chmod(no, 0444) == 0, "o nó do hidraw3 sem escrita");
  memset(&f, 0, sizeof(f));
  espera(origem_fatos_linux("/dev/input/event30", &f) == 1, "acha o event30");
  espera(f.vid == 0x054c && f.pid == 0x0ce6, "o evdev é do DualSense");
  origem_classificar(&f, &o);
  if (geteuid() == 0) {
    /* como root o access() deixa escrever em tudo: a falta não se mede aqui */
    printf("  (como root, a falta de permissão não se mede: só o caminho do hidraw irmão)\n");
  } else {
    espera(f.hidraw_sem_permissao, "o hidraw irmão sem escrita: hidraw_sem_permissao");
    espera(o.hidraw_sem_permissao, "e a origem carrega a causa");
  }
  espera(chmod(no, 0666) == 0, "o nó do hidraw3 com escrita");
  memset(&f, 0, sizeof(f));
  origem_fatos_linux("/dev/input/event30", &f);
  espera(!f.hidraw_sem_permissao, "com escrita no hidraw irmão, nada a dizer");
  espera(unlink(no) == 0, "o nó do hidraw3 some");
  memset(&f, 0, sizeof(f));
  origem_fatos_linux("/dev/input/event30", &f);
  espera(!f.hidraw_sem_permissao, "o nó que não existe não é falta de permissão");
  memset(&f, 0, sizeof(f));
  origem_fatos_linux("/dev/hidraw3", &f);
  espera(!f.hidraw_sem_permissao, "pelo hidraw, o SDL já abriu: nada a conferir");
  unsetenv("FORJA_DEV");

  memset(&f, 0, sizeof(f));
  espera(origem_fatos_linux("/dev/hidraw99", &f) == 0, "o que não existe não é achado");
  espera(origem_fatos_linux("", &f) == 0, "caminho vazio");

  unsetenv("FORJA_SYSFS");
  char cmd[1200];
  snprintf(cmd, sizeof(cmd), "rm -rf '%s'", raiz);
  espera(system(cmd) == 0, "limpa o sysfs de mentira");
}
#endif

static void provas_da_sessao(void) {
  espera(origem_aceitar_na_sessao(1, 1), "com --simular, o controle simulado entra");
  espera(!origem_aceitar_na_sessao(1, 0), "com --simular, o controle de verdade é recusado");
  espera(origem_aceitar_na_sessao(0, 0), "sem a marca, o controle de verdade entra");
  espera(origem_aceitar_na_sessao(0, 1), "sem a marca, o simulado também entra");
}

void provas_origem(void) {
  provas_da_regra();
  provas_da_sessao();
#if defined(__linux__)
  provas_do_sysfs();
#endif
}
