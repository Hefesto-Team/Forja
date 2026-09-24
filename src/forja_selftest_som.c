/* Prova do alto-falante e do movimento — sem servidor de som e sem aparelho.
 *
 * O servidor é um texto de `pactl list sinks` e a mesa é um sysfs de mentira
 * montado numa pasta temporária (FORJA_SYSFS). Nada aqui abre /dev nem fala
 * com o PipeWire de ninguém.
 */
#define _XOPEN_SOURCE 700

#include "forja_alto_falante.h"
#include "forja_mesa.h"
#include "forja_movimento.h"

#include <ftw.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static int fails;

static void expect(int cond, const char *msg) {
  if (!cond) {
    fprintf(stderr, "FAIL %s\n", msg);
    fails++;
  }
}

/* Uma mesa com UM DualSense no cabo e outro no rádio, e o daemon que estiver
 * atrás publicando os nós dele. É o `pactl list sinks` em inglês (LC_ALL=C). */
static const char *SERVIDOR =
    "Sink #40\n"
    "\tState: SUSPENDED\n"
    "\tName: alsa_output.pci-0000_0a_00.1.hdmi-stereo\n"
    "\tDescription: HDA NVidia Digital Stereo (HDMI)\n"
    "\tSample Specification: s32le 2ch 48000Hz\n"
    "\tProperties:\n"
    "\t\tdevice.bus = \"pci\"\n"
    "Sink #551\n"
    "\tState: SUSPENDED\n"
    "\tName: alsa_output.usb-Sony_Interactive_Entertainment_DualSense_Wireless_Controller-00."
    "HiFi__Speaker__sink\n"
    "\tDescription: DualSense wireless controller (PS5) Controller speaker and haptic motors\n"
    "\tSample Specification: s16le 4ch 48000Hz\n"
    "\tChannel Map: front-left,front-right,rear-left,rear-right\n"
    "\tProperties:\n"
    "\t\talsa.card_name = \"DualSense Wireless Controller\"\n"
    "\t\tdevice.bus = \"usb\"\n"
    "\t\tdevice.vendor.id = \"0x054c\"\n"
    "\t\tdevice.product.id = \"0x0ce6\"\n"
    "\t\tsysfs.path = \"/devices/pci0000:00/usb3/3-4/3-4:1.0/sound/card2\"\n"
    "Sink #593\n"
    "\tState: RUNNING\n"
    "\tName: sink_do_daemon_000003\n"
    "\tDescription: Alto-falante do Controle 1 (DualSense Wireless Controller)\n"
    "\tSample Specification: s16le 2ch 48000Hz\n"
    "\tProperties:\n"
    "\t\tdevice.description = \"Alto-falante do Controle 1 (DualSense Wireless Controller)\"\n"
    "Sink #600\n"
    "\tState: IDLE\n"
    "\tName: alsa_output.usb-Sony_Interactive_Entertainment_DualSense_Wireless_Controller_X-00."
    "HiFi__Speaker__sink\n"
    "\tDescription: DualSense 4ch do radio\n"
    "\tSample Specification: float32le 4ch 48000Hz\n"
    "\tProperties:\n"
    "\t\tdevice.bus = \"usb\"\n"
    "\t\tdevice.vendor.id = \"054c\"\n"
    "\t\tdevice.product.id = \"0ce6\"\n"
    "\t\tsysfs.path = \"/devices/pci0000:00/usb1/1-2/1-2:1.0\"\n";

static int achar(const ForjaNoDeSom *nos, int n, const char *nome) {
  for (int i = 0; i < n; i++)
    if (!strcmp(nos[i].nome, nome))
      return i;
  return -1;
}

static void prova_a_lista(void) {
  ForjaNoDeSom nos[16];
  int total = 0;
  int n = forja_nos_de_som(SERVIDOR, nos, 16, &total);
  expect(total == 4, "o servidor tem quatro saídas");
  expect(n == 3, "três saídas são de DualSense: a placa, o nó nomeado e o de quatro canais");
  expect(achar(nos, n, "alsa_output.pci-0000_0a_00.1.hdmi-stereo") < 0, "a TV não é DualSense");

  int placa = achar(nos, n,
                    "alsa_output.usb-Sony_Interactive_Entertainment_DualSense_Wireless_"
                    "Controller-00.HiFi__Speaker__sink");
  int nomeado = achar(nos, n, "sink_do_daemon_000003");
  expect(placa >= 0 && nomeado >= 0, "a placa e o nó nomeado estão na lista");
  if (placa >= 0) {
    expect(nos[placa].canais == 4, "a placa tem quatro canais");
    expect(nos[placa].usb_da_sony == 1, "a placa acha sozinha: 0x054c/0x0ce6, com o 0x");
  }
  if (nomeado >= 0) {
    expect(nos[nomeado].canais == 2, "o nó nomeado tem dois canais");
    expect(nos[nomeado].usb_da_sony == 0, "o nó nomeado só se acha pela lista");
    /* O NOME é o que o jogo mostra: o jogo o acha porque a descrição traz a
     * palavra da Sony, e não pelo nome de dentro, que não a traz. */
    expect(!forja_e_do_dualsense(nos[nomeado].nome, ""), "o nome de dentro não diz DualSense");
    expect(forja_no_por_nome(nos, n, "controle 1") == nomeado, "a pessoa aponta «Controle 1»");
  }
  expect(forja_no_por_nome(nos, n, "Controle 9") == -1, "o que não existe não se acha");
  expect(forja_no_por_nome(nos, n, "") == -1, "texto vazio não aponta nada");
}

static void prova_o_nome_de_antes_era_invisivel(void) {
  /* A mordida do nome (E6): com a descrição de antes da forma A, o nó do rádio
   * some da lista que o jogo percorre — ele existia e ninguém o reconhecia. */
  const char *antes = "Sink #593\n"
                      "\tName: sink_do_daemon_000003\n"
                      "\tDescription: Alto-falante do Controle 1\n"
                      "\tSample Specification: s16le 2ch 48000Hz\n";
  ForjaNoDeSom nos[4];
  int total = 0;
  expect(forja_nos_de_som(antes, nos, 4, &total) == 0 && total == 1,
         "sem a palavra da Sony o jogo não acha o alto-falante do rádio");
  expect(!forja_e_do_dualsense("x.monitor", "DualSense"), "monitor nunca é destino");
  expect(!forja_e_do_dualsense("alsa_input.usb-Sony_DualSense", "DualSense"),
         "captura nunca é destino");
}

static void escrever(const char *caminho, const char *texto) {
  FILE *f = fopen(caminho, "w");
  if (f) {
    fputs(texto, f);
    fclose(f);
  }
}

static void pasta(const char *raiz, const char *rel) {
  char caminho[PATH_MAX];
  snprintf(caminho, sizeof(caminho), "%s/%s", raiz, rel);
  for (char *p = caminho + strlen(raiz) + 1; *p; p++) {
    if (*p == '/') {
      *p = '\0';
      mkdir(caminho, 0755);
      *p = '/';
    }
  }
  mkdir(caminho, 0755);
}

/* Um pad: a pasta HID dele sob `pai`, e o /sys/class/hidraw/<nome>/device. */
static void pad(const char *raiz, const char *nome, const char *pai, const char *hid_id) {
  char rel[PATH_MAX], caminho[PATH_MAX], alvo[2 * PATH_MAX], uevent[2 * PATH_MAX];
  snprintf(rel, sizeof(rel), "%s/0003:054C:0CE6.%s", pai, nome);
  pasta(raiz, rel);
  snprintf(uevent, sizeof(uevent), "%s/%s/uevent", raiz, rel);
  char conteudo[128];
  snprintf(conteudo, sizeof(conteudo), "DRIVER=playstation\nHID_ID=%s\n", hid_id);
  escrever(uevent, conteudo);
  snprintf(caminho, sizeof(caminho), "class/hidraw/%s", nome);
  pasta(raiz, caminho);
  snprintf(caminho, sizeof(caminho), "%s/class/hidraw/%s/device", raiz, nome);
  snprintf(alvo, sizeof(alvo), "%s/%s", raiz, rel);
  if (symlink(alvo, caminho) != 0)
    expect(0, "montar o symlink do pad");
}

static void usb(const char *raiz, const char *rel) {
  char c[PATH_MAX + 16];
  pasta(raiz, rel);
  snprintf(c, sizeof(c), "%s/%s/busnum", raiz, rel);
  escrever(c, "3\n");
  snprintf(c, sizeof(c), "%s/%s/devnum", raiz, rel);
  escrever(c, "7\n");
}

static int apagar_um(const char *caminho, const struct stat *st, int tipo, struct FTW *ftw) {
  (void)st;
  (void)tipo;
  (void)ftw;
  return remove(caminho);
}

static const ForjaPad *pad_por_nome(const ForjaPad *pads, int n, const char *nome) {
  for (int i = 0; i < n; i++)
    if (!strcmp(pads[i].hidraw, nome))
      return &pads[i];
  return NULL;
}

static void prova_pelo_aparelho(void) {
  char raiz[] = "/tmp/forja-sysfs-XXXXXX";
  if (!mkdtemp(raiz)) {
    expect(0, "mkdtemp");
    return;
  }
  /* dois DualSense no cabo, cada um com a placa dele; um no rádio; um virtual */
  usb(raiz, "devices/pci0000:00/usb3/3-4");
  usb(raiz, "devices/pci0000:00/usb3/3-5");
  usb(raiz, "devices/pci0000:00/usb1/1-2");  /* o adaptador BT */
  pasta(raiz, "devices/pci0000:00/usb3/3-4/3-4:1.0/sound/card2");
  pasta(raiz, "devices/pci0000:00/usb3/3-5/3-5:1.0/sound/card3");
  pad(raiz, "hidraw3", "devices/pci0000:00/usb3/3-4/3-4:1.3", "0003:0000054C:00000CE6");
  pad(raiz, "hidraw4", "devices/pci0000:00/usb3/3-5/3-5:1.3", "0003:0000054C:00000CE6");
  pad(raiz, "hidraw5", "devices/pci0000:00/usb1/1-2/1-2:1.0/bluetooth/hci0/hci0:256",
      "0005:0000054C:00000CE6");
  pad(raiz, "hidraw6", "devices/virtual/misc/uhid", "0003:0000054C:00000CE6");
  setenv("FORJA_SYSFS", raiz, 1);

  ForjaPad pads[8];
  int n_pads = forja_mesa_pads(pads, 8);
  expect(n_pads == 4, "a mesa tem quatro DualSense");
  const ForjaPad *p1 = pad_por_nome(pads, n_pads, "hidraw3");
  const ForjaPad *p2 = pad_por_nome(pads, n_pads, "hidraw4");
  const ForjaPad *radio = pad_por_nome(pads, n_pads, "hidraw5");
  const ForjaPad *virtual = pad_por_nome(pads, n_pads, "hidraw6");
  expect(p1 && p2 && radio && virtual, "os quatro pads com o hidraw certo");
  if (!(p1 && p2 && radio && virtual)) {
    unsetenv("FORJA_SYSFS");
    nftw(raiz, apagar_um, 16, FTW_DEPTH | FTW_PHYS);
    return;
  }
  expect(radio->bus == FORJA_BUS_BT, "o do rádio diz bus 5");

  char usb1[PATH_MAX], usb2[PATH_MAX], lixo[PATH_MAX];
  expect(forja_usb_do_pad(p1, usb1, sizeof(usb1)) == 0, "o pad do cabo tem aparelho USB");
  expect(forja_usb_do_pad(p2, usb2, sizeof(usb2)) == 0, "o segundo também");
  expect(strcmp(usb1, usb2) != 0, "cada um no seu aparelho");
  /* O rádio sobe até o ADAPTADOR, que também é USB: tem de recusar antes. */
  expect(forja_usb_do_pad(radio, lixo, sizeof(lixo)) != 0, "o do rádio não tem aparelho de som");
  expect(forja_usb_do_pad(virtual, lixo, sizeof(lixo)) != 0, "o virtual não tem aparelho de som");

  const char *dois_no_cabo =
      "Sink #1\n\tName: alsa_output.usb-Sony_DualSense-00.HiFi__Speaker__sink\n"
      "\tDescription: DualSense wireless controller (PS5)\n"
      "\tSample Specification: s16le 4ch 48000Hz\n"
      "\t\tsysfs.path = \"/devices/pci0000:00/usb3/3-4/3-4:1.0/sound/card2\"\n"
      "Sink #2\n\tName: alsa_output.usb-Sony_DualSense-01.HiFi__Speaker__sink\n"
      "\tDescription: DualSense wireless controller (PS5)\n"
      "\tSample Specification: s16le 4ch 48000Hz\n"
      "\t\tsysfs.path = \"/devices/pci0000:00/usb3/3-5/3-5:1.0/sound/card3\"\n"
      "Sink #3\n\tName: alsa_output.usb-Sony_DualSense_X-00.HiFi__Speaker__sink\n"
      "\tDescription: DualSense 4ch\n"
      "\tSample Specification: float32le 4ch 48000Hz\n"
      "\t\tsysfs.path = \"/devices/pci0000:00/usb1/1-2/1-2:1.0\"\n";
  ForjaNoDeSom nos[8];
  int total = 0;
  int n = forja_nos_de_som(dois_no_cabo, nos, 8, &total);
  expect(n == 3, "três alto-falantes na lista");
  int do_p1 = forja_no_do_pad(nos, n, usb1);
  int do_p2 = forja_no_do_pad(nos, n, usb2);
  expect(do_p1 >= 0 && !strcmp(nos[do_p1].nome,
                               "alsa_output.usb-Sony_DualSense-00.HiFi__Speaker__sink"),
         "o P1 acha a placa DELE");
  expect(do_p2 >= 0 && !strcmp(nos[do_p2].nome,
                               "alsa_output.usb-Sony_DualSense-01.HiFi__Speaker__sink"),
         "o P2 acha a placa DELE, e não a do vizinho");
  unsetenv("FORJA_SYSFS");
  nftw(raiz, apagar_um, 16, FTW_DEPTH | FTW_PHYS);
}

static int canal_mudo(const int16_t *pcm, long quadros, int canais, int c) {
  for (long i = 0; i < quadros; i++)
    if (pcm[i * canais + c] != 0)
      return 0;
  return 1;
}

static void prova_o_tom(void) {
  expect(!strcmp(forja_mapa_de_canais(4), "FL,FR,RL,RR"), "mapa de quatro canais");
  expect(!strcmp(forja_mapa_de_canais(2), "FL,FR"), "mapa de dois canais");
  expect(forja_mapa_de_canais(6) == NULL, "mapa que não conhecemos não se inventa");
  expect(forja_canal_do_alto_falante(4) == 1, "no de quatro, o alto-falante é o canal 1 (FR)");
  expect(forja_canal_do_alto_falante(2) == 1, "no de dois, também o FR");
  expect(forja_canal_do_alto_falante(1) == 0, "no mono, o único");

  enum { Q = 4800 };
  static int16_t pcm[Q * 4];
  forja_tom(pcm, Q, 4, FORJA_CANAL_DO_ALTO_FALANTE, -1, 1300.0);
  expect(!canal_mudo(pcm, Q, 4, 1), "o tom sai no canal 1");
  expect(canal_mudo(pcm, Q, 4, 0) && canal_mudo(pcm, Q, 4, 2) && canal_mudo(pcm, Q, 4, 3),
         "e ZERO nos outros três: é o que faz «ouvi» virar «ouvi ALI»");
  expect(pcm[1] == 0, "a rampa começa do zero");

  forja_tom(pcm, Q, 4, FORJA_CANAL_VCM_E, FORJA_CANAL_VCM_D, 60.0);
  expect(!canal_mudo(pcm, Q, 4, 2) && !canal_mudo(pcm, Q, 4, 3), "os atuadores nos canais 2 e 3");
  expect(canal_mudo(pcm, Q, 4, 0) && canal_mudo(pcm, Q, 4, 1), "o alto-falante calado no tremor");
}

static void report(uint8_t *buf, uint8_t id, int16_t g0, int16_t g1, int16_t g2, int16_t a0,
                   int16_t a1, int16_t a2) {
  memset(buf, 0, 64);
  buf[0] = id;
  int16_t v[6] = {g0, g1, g2, a0, a1, a2};
  for (int i = 0; i < 6; i++) {
    buf[1 + 15 + 2 * i] = (uint8_t)(v[i] & 0xff);
    buf[1 + 15 + 2 * i + 1] = (uint8_t)((v[i] >> 8) & 0xff);
  }
}

static void prova_o_movimento(void) {
  uint8_t buf[64];
  ForjaImu imu;
  /* parado na mesa: 1 g no eixo Y (para baixo) e giro zero — a mordida (1) */
  report(buf, 0x01, 0, 0, 0, 0, -8192, 0);
  expect(forja_imu_do_report(buf, 64, &imu) == 0, "o 0x01 se lê");
  expect(imu.acel[1] == -1.0 && imu.acel[0] == 0.0 && imu.acel[2] == 0.0, "1 g num eixo só");
  expect(imu.giro[0] == 0.0 && imu.giro[1] == 0.0 && imu.giro[2] == 0.0, "parado, giro zero");
  /* girando no yaw a 30 graus/s (o int16 cobre +-32 graus/s por 1024) */
  report(buf, 0x01, 0, 30 * 1024, 0, 0, -8192, 0);
  forja_imu_do_report(buf, 64, &imu);
  expect(imu.giro[1] == 30.0, "yaw de 30 graus/s no giro[1]");
  /* a mordida (2): o 0x31 é recusado, nunca lido com os offsets do 0x01 */
  report(buf, 0x31, 1024, 1024, 1024, 8192, 8192, 8192);
  expect(forja_imu_do_report(buf, 64, &imu) == 3, "o 0x31 é recusado");
  report(buf, 0x02, 0, 0, 0, 0, 0, 0);
  expect(forja_imu_do_report(buf, 64, &imu) == 1, "outro relatório se pula");
  expect(forja_imu_do_report(buf, 10, &imu) == 1, "curto demais se pula");
}

int main(void) {
  prova_a_lista();
  prova_o_nome_de_antes_era_invisivel();
  prova_pelo_aparelho();
  prova_o_tom();
  prova_o_movimento();
  if (fails) {
    fprintf(stderr, "%d falha(s)\n", fails);
    return 1;
  }
  puts("forja som e movimento ok — o alto-falante pelo nome e pelo aparelho, o tom só no canal "
       "dele, o 0x31 recusado");
  return 0;
}
