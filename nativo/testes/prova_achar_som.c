/* Achar o som de cada controle: ler a lista do sistema, reconhecer os nós,
 * casar com a lista do jogo e escolher um dispositivo por jogador. */
#include "prova.h"

#include "achar_som.h"

static const char *SAIDAS =
    "Sink #52\n"
    "\tState: SUSPENDED\n"
    "\tName: alsa_output.usb-Sony_Interactive_Entertainment_DualSense_Wireless_Controller-00.analog-surround-40\n"
    "\tDescription: DualSense Wireless Controller Analog Surround 4.0\n"
    "\tDriver: PipeWire\n"
    "\tSample Specification: s16le 4ch 48000Hz\n"
    "\tChannel Map: front-left,front-right,rear-left,rear-right\n"
    "\tProperties:\n"
    "\t\tsysfs.path = \"/devices/pci0000:00/0000:00:14.0/usb3/3-4/3-4:1.0/sound/card2\"\n"
    "\t\tdevice.bus = \"usb\"\n"
    "\t\tdevice.vendor.id = \"0x054c\"\n"
    "\t\tdevice.product.id = \"0x0ce6\"\n"
    "Sink #60\n"
    "\tName: alsa_output.pci-0000_00_1f.3.analog-stereo\n"
    "\tDescription: Áudio interno Estéreo analógico\n"
    "\tSample Specification: s32le 2ch 48000Hz\n"
    "Sink #71\n"
    "\tName: alsa_output.usb-Sony_Interactive_Entertainment_DualSense_Wireless_Controller-01.analog-surround-40\n"
    "\tDescription: DualSense Wireless Controller Analog Surround 4.0\n"
    "\tSample Specification: s16le 4ch 48000Hz\n"
    "\tProperties:\n"
    "\t\tsysfs.path = \"/devices/pci0000:00/0000:00:14.0/usb3/3-5/3-5:1.0/sound/card3\"\n"
    "Sink #80\n"
    "\tName: alto_falante_3\n"
    "\tDescription: Alto-falante do Controle 3 (DualSense Wireless Controller)\n"
    "\tSample Specification: float32le 1ch 48000Hz";

static const char *ENTRADAS =
    "Source #53\n"
    "\tName: alsa_output.usb-Sony_Interactive_Entertainment_DualSense_Wireless_Controller-00.analog-surround-40.monitor\n"
    "\tDescription: Monitor of DualSense Wireless Controller Analog Surround 4.0\n"
    "\tSample Specification: s16le 4ch 48000Hz\n"
    "Source #54\n"
    "\tName: alsa_input.usb-Sony_Interactive_Entertainment_DualSense_Wireless_Controller-00.mono-fallback\n"
    "\tDescription: DualSense Wireless Controller Mono\n"
    "\tSample Specification: s16le 1ch 48000Hz\n"
    "\tProperties:\n"
    "\t\tsysfs.path = \"/devices/pci0000:00/0000:00:14.0/usb3/3-4/3-4:1.0/sound/card2\"\n";

static NoSom no(const char *nome, int canais, bool gravacao, const char *usb) {
  NoSom n;
  memset(&n, 0, sizeof(n));
  snprintf(n.nome, sizeof(n.nome), "%s", nome);
  n.canais = canais;
  n.gravacao = gravacao;
  n.tipo = achar_tipo(nome, gravacao);
  n.controle_n = achar_numero(nome);
  if (usb)
    snprintf(n.usb, sizeof(n.usb), "%s", usb);
  n.no_sistema = -1;
  return n;
}

void provas_achar_som(void) {
  /* ---- a lista do sistema ---- */
  NoSistema sis[SOM_MAX_NOS];
  int n = achar_ler_pactl(SAIDAS, false, sis, SOM_MAX_NOS);
  espera(n == 4, "quatro saídas lidas");
  espera(n == 4 && sis[0].canais == 4 && sis[0].vid == 0x054c && sis[0].pid == 0x0ce6, "a placa do controle");
  espera(n == 4 && strstr(sis[2].sysfs, "3-5") != NULL, "o sysfs.path do segundo controle");
  espera(n == 4 && strcmp(sis[3].descricao, "Alto-falante do Controle 3 (DualSense Wireless Controller)") == 0,
         "a última, sem '\\n' no fim, também entra");
  espera(n == 4 && sis[1].canais == 2 && sis[1].sysfs[0] == 0, "a saída interna, sem sysfs");
  NoSistema ent[SOM_MAX_NOS];
  int ne = achar_ler_pactl(ENTRADAS, true, ent, SOM_MAX_NOS);
  espera(ne == 1 && ent[0].gravacao && ent[0].canais == 1, "o monitor fica de fora; o microfone entra");
  espera(achar_ler_pactl("", false, sis, SOM_MAX_NOS) == 0, "nada, nada");
  espera(achar_ler_pactl(SAIDAS, false, sis, 2) == 2, "respeita o máximo");

  /* ---- os nomes ---- */
  espera(achar_tipo("DualSense Wireless Controller Analog Surround 4.0", false) == NO_DUALSENSE_SAIDA, "a placa");
  espera(achar_tipo("Alto-falante (Wireless Controller)", false) == NO_DUALSENSE_SAIDA, "o nome do Windows");
  espera(achar_tipo("DualSense Wireless Controller Mono", true) == NO_DUALSENSE_ENTRADA, "o microfone");
  espera(achar_tipo("Monitor of DualSense Wireless Controller", true) == NO_OUTRO, "o monitor não é microfone");
  espera(achar_tipo("Alto-falante do Controle 3 (DualSense Wireless Controller)", false) == NO_NUMERADO_FALANTE,
         "o alto-falante numerado");
  espera(achar_tipo("Háptica do Controle 2 (DualSense Wireless Controller)", false) == NO_NUMERADO_HAPTICA,
         "a háptica numerada");
  espera(achar_tipo("Microfone do Controle 4 (DualSense Wireless Controller)", true) == NO_NUMERADO_MIC,
         "o microfone numerado");
  espera(achar_tipo("Áudio interno Estéreo analógico", false) == NO_OUTRO, "a caixa do computador");
  espera(achar_numero("Alto-falante do Controle 3 (DualSense Wireless Controller)") == 3, "o número");
  espera(achar_tipo("Alto-falante do Controle 2", false) == NO_OUTRO,
         "sem a palavra da Sony, o nó numerado não conta (CONTRATO.md)");
  espera(achar_numero("DualSense Wireless Controller") == 0, "sem número");
  espera(achar_numero("controle x") == 0, "controle sem dígito");

  /* ---- casar a lista do jogo com a do sistema, com nomes repetidos ---- */
  NoSom jogo[4] = {no("DualSense Wireless Controller Analog Surround 4.0", 4, false, NULL),
                   no("Áudio interno Estéreo analógico", 2, false, NULL),
                   no("DualSense Wireless Controller Analog Surround 4.0", 4, false, NULL),
                   no("Alto-falante do Controle 3 (DualSense Wireless Controller)", 1, false, NULL)};
  n = achar_ler_pactl(SAIDAS, false, sis, SOM_MAX_NOS);
  achar_casar(jogo, 4, sis, n);
  espera(jogo[0].no_sistema == 0 && jogo[2].no_sistema == 2, "repetidos: o primeiro com o primeiro, o segundo com o segundo");
  espera(jogo[1].no_sistema == 1 && jogo[3].no_sistema == 3, "os únicos");

  /* ---- a escolha ---- */
  snprintf(jogo[0].usb, sizeof(jogo[0].usb), "/usb3/3-4");
  snprintf(jogo[2].usb, sizeof(jogo[2].usb), "/usb3/3-5");
  ComoAchou como;
  bool usado[4] = {false, false, false, false};
  int i = achar_para(jogo, 4, PAPEL_ALTO_FALANTE, "/usb3/3-5", NULL, 1, usado, &como);
  espera(i == 2 && como == ACHOU_APARELHO, "pelo aparelho: o nó do mesmo USB");
  i = achar_para(jogo, 4, PAPEL_HAPTICA, "/usb3/3-5", NULL, 1, usado, &como);
  espera(i == 2 && como == ACHOU_APARELHO, "a háptica mora na mesma placa");
  i = achar_para(jogo, 4, PAPEL_ALTO_FALANTE, NULL, NULL, 3, usado, &como);
  espera(i == 3 && como == ACHOU_NUMERO, "sem aparelho, pelo número do lugar");
  i = achar_para(jogo, 4, PAPEL_ALTO_FALANTE, NULL, NULL, 2, usado, &como);
  espera(i == 0 && como == ACHOU_NOME, "sem aparelho e sem número, pelo nome");
  usado[0] = usado[2] = true;
  i = achar_para(jogo, 4, PAPEL_ALTO_FALANTE, NULL, NULL, 2, usado, &como);
  espera(i < 0 && como == ACHOU_NADA, "as placas já têm dono: não achou");
  usado[0] = usado[2] = false;
  espera(achar_para(jogo, 4, PAPEL_MICROFONE, NULL, NULL, 1, usado, &como) < 0, "saída não é microfone");
  NoSom dois = no("DualSense Wireless Controller Analog Stereo", 2, false, NULL);
  espera(achar_para(&dois, 1, PAPEL_HAPTICA, NULL, NULL, 1, NULL, &como) < 0, "dois canais não têm atuador");
  NoSom cont = no("Alto-falante (Wireless Controller)", 4, false, NULL);
  snprintf(cont.container, sizeof(cont.container), "{00000000-1111-2222-3333-444444444444}");
  i = achar_para(&cont, 1, PAPEL_ALTO_FALANTE, NULL, "{00000000-1111-2222-3333-444444444444}", 1, NULL, &como);
  espera(i == 0 && como == ACHOU_APARELHO, "pelo ContainerId, como no Windows");

  /* ---- os canais ---- */
  int a, b;
  achar_canais(&jogo[0], PAPEL_ALTO_FALANTE, &a, &b);
  espera(a == 1 && b == -1, "na placa de 4 canais, o alto-falante é o canal 1 (front-right)");
  achar_canais(&jogo[0], PAPEL_HAPTICA, &a, &b);
  espera(a == 2 && b == 3, "e os atuadores são o 2 e o 3");
  achar_canais(&jogo[3], PAPEL_ALTO_FALANTE, &a, &b);
  espera(a == 0 && b == -1, "no nó numerado mono, o canal 0");
  NoSom hap = no("Háptica do Controle 2 (DualSense Wireless Controller)", 2, false, NULL);
  achar_canais(&hap, PAPEL_HAPTICA, &a, &b);
  espera(a == 0 && b == 1, "na háptica numerada estéreo, esquerda e direita");
  espera(strcmp(achar_como_rotulo(ACHOU_APARELHO), "pelo aparelho") == 0, "os rótulos");
}
