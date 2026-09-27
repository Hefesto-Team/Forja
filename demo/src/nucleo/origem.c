/* De onde veio o controle. Ver origem.h. */
#include "origem.h"

#include "mascara.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define VID_SONY 0x054C
#define PID_DUALSENSE 0x0CE6
#define PID_EDGE 0x0DF2
#define VID_MICROSOFT 0x045E
#define PID_XBOX360 0x028E
#define VID_VALVE 0x28DE
#define PID_STEAM_VIRTUAL 0x11FF

const char *origem_raiz_sysfs(void) {
  const char *raiz = getenv("FORJA_SYSFS");
  return (raiz && raiz[0]) ? raiz : "/sys";
}

const char *origem_rotulo(OrigemTipo t) {
  switch (t) {
  case ORIGEM_DUALSENSE_NATIVO:
    return "DualSense nativo";
  case ORIGEM_EDGE_NATIVO:
    return "DualSense Edge nativo";
  case ORIGEM_DUALSENSE_VIRTUAL_UHID:
    return "DualSense virtual (uhid)";
  case ORIGEM_EDGE_VIRTUAL_UHID:
    return "DualSense Edge virtual (uhid)";
  case ORIGEM_DUALSENSE_VIRTUAL_UINPUT:
    return "DualSense virtual (uinput, só evdev)";
  case ORIGEM_XBOX_VIRTUAL_UINPUT:
    return "pad Xbox virtual (uinput)";
  case ORIGEM_XBOX_NATIVO:
    return "Xbox 360 nativo";
  case ORIGEM_ESPELHO_STEAM:
    return "espelho do Steam Input (uinput)";
  case ORIGEM_OUTRO_VIRTUAL:
    return "outro controle virtual";
  case ORIGEM_OUTRO:
    return "outro controle";
  default:
    return "origem desconhecida";
  }
}

const char *origem_rotulo_curto(OrigemTipo t) {
  switch (t) {
  case ORIGEM_DUALSENSE_NATIVO:
  case ORIGEM_EDGE_NATIVO:
    return "NATIVO";
  case ORIGEM_DUALSENSE_VIRTUAL_UHID:
  case ORIGEM_EDGE_VIRTUAL_UHID:
    return "VIRTUAL · UHID";
  case ORIGEM_DUALSENSE_VIRTUAL_UINPUT:
  case ORIGEM_XBOX_VIRTUAL_UINPUT:
  case ORIGEM_ESPELHO_STEAM:
    return "VIRTUAL · UINPUT";
  case ORIGEM_XBOX_NATIVO:
    return "XBOX";
  case ORIGEM_OUTRO_VIRTUAL:
    return "VIRTUAL";
  default:
    return "?";
  }
}

const char *conexao_rotulo(Conexao c) {
  switch (c) {
  case CONEXAO_USB:
    return "USB";
  case CONEXAO_BT:
    return "Bluetooth";
  case CONEXAO_VIRTUAL_USB:
    return "virtual (declara USB)";
  case CONEXAO_VIRTUAL:
    return "virtual";
  default:
    return "desconhecida";
  }
}

int origem_eh_dualsense(OrigemTipo t) {
  return t == ORIGEM_DUALSENSE_NATIVO || t == ORIGEM_EDGE_NATIVO ||
         t == ORIGEM_DUALSENSE_VIRTUAL_UHID || t == ORIGEM_EDGE_VIRTUAL_UHID;
}

int origem_eh_virtual(OrigemTipo t) {
  return t == ORIGEM_DUALSENSE_VIRTUAL_UHID || t == ORIGEM_EDGE_VIRTUAL_UHID ||
         t == ORIGEM_DUALSENSE_VIRTUAL_UINPUT || t == ORIGEM_XBOX_VIRTUAL_UINPUT ||
         t == ORIGEM_ESPELHO_STEAM || t == ORIGEM_OUTRO_VIRTUAL;
}

static Conexao conexao_pelo_bus(int bus, int conexao_sdl) {
  if (bus == ORIGEM_BUS_USB)
    return CONEXAO_USB;
  if (bus == ORIGEM_BUS_BT)
    return CONEXAO_BT;
  if (conexao_sdl == 1)
    return CONEXAO_USB;
  if (conexao_sdl == 2)
    return CONEXAO_BT;
  return CONEXAO_DESCONHECIDA;
}

static void classificar_windows(const OrigemFatos *f, Origem *o) {
  o->inferida = 1;
  o->conexao = conexao_pelo_bus(-1, f->conexao_sdl);
  const char *onde = f->wine ? "Wine/Proton" : "Windows";
  if (f->vid == VID_SONY && f->pid == PID_EDGE) {
    o->tipo = ORIGEM_EDGE_NATIVO;
    snprintf(o->evidencia, sizeof(o->evidencia),
             "%s: VID:PID do HID; um Edge sob o Wine costuma ser o virtual (uhid), "
             "mas o sysfs não é visível daqui",
             onde);
    return;
  }
  if (f->vid == VID_SONY && f->pid == PID_DUALSENSE)
    o->tipo = ORIGEM_DUALSENSE_NATIVO;
  else if (f->vid == VID_MICROSOFT && f->pid == PID_XBOX360)
    o->tipo = ORIGEM_XBOX_NATIVO;
  else if (f->vid == VID_VALVE && f->pid == PID_STEAM_VIRTUAL)
    o->tipo = ORIGEM_ESPELHO_STEAM;
  else
    o->tipo = ORIGEM_OUTRO;
  snprintf(o->evidencia, sizeof(o->evidencia), "%s: inferida pelo VID:PID (sem sysfs)", onde);
}

void origem_classificar(const OrigemFatos *f, Origem *o) {
  memset(o, 0, sizeof(*o));
  if (!f->tem_sysfs) {
    if (f->windows) {
      classificar_windows(f, o);
      return;
    }
    o->inferida = 1;
    o->conexao = conexao_pelo_bus(f->bus, f->conexao_sdl);
    if (f->vid == VID_SONY && f->pid == PID_DUALSENSE)
      o->tipo = ORIGEM_DUALSENSE_NATIVO;
    else if (f->vid == VID_SONY && f->pid == PID_EDGE)
      o->tipo = ORIGEM_EDGE_NATIVO;
    else if (f->vid == VID_MICROSOFT && f->pid == PID_XBOX360)
      o->tipo = ORIGEM_XBOX_NATIVO;
    else if (f->vid == VID_VALVE && f->pid == PID_STEAM_VIRTUAL)
      o->tipo = ORIGEM_ESPELHO_STEAM;
    else
      o->tipo = ORIGEM_OUTRO;
    snprintf(o->evidencia, sizeof(o->evidencia), "inferida pelo VID:PID (sem sysfs)");
    return;
  }

  const char *real = f->caminho_real;
  int uhid = strstr(real, "/devices/virtual/misc/uhid/") != NULL;
  int uinput = strstr(real, "/devices/virtual/input/") != NULL;
  int virtual_qualquer = strstr(real, "/devices/virtual/") != NULL;
  int tem_usb = f->usb_pai[0] != '\0';
  int sony = f->vid == VID_SONY && (f->pid == PID_DUALSENSE || f->pid == PID_EDGE);
  int edge = f->pid == PID_EDGE;
  char phys[72] = "";
  if (f->phys[0])
    snprintf(phys, sizeof(phys), " · phys «%.48s»", f->phys);

  if (sony) {
    if (uhid && f->bus == ORIGEM_BUS_BT) {
      /* O BlueZ >= 5.73 publica o controle do rádio por uhid, com bus 0005:
       * é o físico, não um virtual (a pasta sozinha não prova nada). */
      o->tipo = edge ? ORIGEM_EDGE_NATIVO : ORIGEM_DUALSENSE_NATIVO;
      o->conexao = CONEXAO_BT;
      snprintf(o->evidencia, sizeof(o->evidencia), "sysfs: HID bus 0005 publicado pelo BlueZ (uhid)%s",
               phys);
    } else if (uhid) {
      o->tipo = edge ? ORIGEM_EDGE_VIRTUAL_UHID : ORIGEM_DUALSENSE_VIRTUAL_UHID;
      o->conexao = f->bus == ORIGEM_BUS_USB ? CONEXAO_VIRTUAL_USB : CONEXAO_VIRTUAL;
      snprintf(o->evidencia, sizeof(o->evidencia),
               "sysfs: HID bus %04x em /devices/virtual/misc/uhid, sem pai USB%s", f->bus & 0xFFFF,
               phys);
    } else if (uinput) {
      o->tipo = ORIGEM_DUALSENSE_VIRTUAL_UINPUT;
      o->conexao = CONEXAO_VIRTUAL;
      snprintf(o->evidencia, sizeof(o->evidencia), "sysfs: evdev em /devices/virtual/input%s", phys);
    } else {
      o->tipo = edge ? ORIGEM_EDGE_NATIVO : ORIGEM_DUALSENSE_NATIVO;
      o->conexao = conexao_pelo_bus(f->bus, f->conexao_sdl);
      if (o->conexao == CONEXAO_USB && tem_usb)
        snprintf(o->evidencia, sizeof(o->evidencia), "sysfs: HID bus 0003 com pai USB");
      else if (o->conexao == CONEXAO_BT)
        snprintf(o->evidencia, sizeof(o->evidencia), "sysfs: HID bus 0005 (Bluetooth)");
      else
        snprintf(o->evidencia, sizeof(o->evidencia), "sysfs: HID bus %04x", f->bus & 0xFFFF);
    }
    return;
  }

  if (f->vid == VID_VALVE && f->pid == PID_STEAM_VIRTUAL) {
    o->tipo = ORIGEM_ESPELHO_STEAM;
    o->conexao = CONEXAO_VIRTUAL;
    snprintf(o->evidencia, sizeof(o->evidencia), "28de:11ff — o espelho que o Steam Input cria");
    return;
  }
  if (f->vid == VID_MICROSOFT && f->pid == PID_XBOX360) {
    if (uinput || virtual_qualquer) {
      o->tipo = ORIGEM_XBOX_VIRTUAL_UINPUT;
      o->conexao = CONEXAO_VIRTUAL;
      snprintf(o->evidencia, sizeof(o->evidencia), "sysfs: evdev em /devices/virtual/input%s", phys);
    } else {
      o->tipo = ORIGEM_XBOX_NATIVO;
      o->conexao = conexao_pelo_bus(f->bus, f->conexao_sdl);
      snprintf(o->evidencia, sizeof(o->evidencia), "sysfs: xpad%s", tem_usb ? " com pai USB" : "");
    }
    return;
  }
  if (virtual_qualquer) {
    o->tipo = ORIGEM_OUTRO_VIRTUAL;
    o->conexao = CONEXAO_VIRTUAL;
    snprintf(o->evidencia, sizeof(o->evidencia), "sysfs: /devices/virtual%s", phys);
    return;
  }
  o->tipo = ORIGEM_OUTRO;
  o->conexao = conexao_pelo_bus(f->bus, f->conexao_sdl);
  snprintf(o->evidencia, sizeof(o->evidencia), "sysfs: bus %04x", f->bus < 0 ? 0 : f->bus);
}
