/* Os controles e os quatro lugares. Ver pads.h. */
#include "pads.h"

#include "forja.h"
#include "mascara.h"

#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

/* A cor de lightbar de cada lugar, a que o controle recebe ao entrar. */
const SDL_Color LUZ_DO_LUGAR[MAX_JOGADORES] = {
    {0, 72, 255, 255},  /* P1 */
    {255, 24, 8, 255},  /* P2 */
    {0, 255, 64, 255},  /* P3 */
    {255, 8, 168, 255}, /* P4 */
};

static float limitar(float v, float a, float b) { return v < a ? a : (v > b ? b : v); }

/* Os apertos de dois controles que chegam juntos (menos que isto) são o mesmo
 * dedo visto por dois caminhos: um espelho. */
#define JANELA_ESPELHO_NS (60ull * 1000000ull)

/* Os botões marcados neste quadro — um aperto e uma soltura no mesmo quadro
 * não se perdem. */

Uint64 pad_agora_ns(const Forja *a, const Pad *p) {
  return p && p->simulado && a ? a->relogio_sim_ns : SDL_GetTicksNS();
}

const char *pad_origem_rotulo(const Pad *p) {
  return p->simulado ? "simulado (SDL virtual)" : origem_rotulo(p->origem.tipo);
}

static bool g_apertou[MAX_PADS][SDL_GAMEPAD_BUTTON_COUNT];
static bool g_soltou[MAX_PADS][SDL_GAMEPAD_BUTTON_COUNT];

static int indice_de(Forja *a, SDL_JoystickID id) {
  for (int i = 0; i < MAX_PADS; i++)
    if (a->pads.pad[i].usado && a->pads.pad[i].id == id)
      return i;
  return -1;
}

const char *pads_rotulo_slot(int slot) {
  static const char *r[] = {"P1", "P2", "P3", "P4"};
  return slot >= 0 && slot < MAX_JOGADORES ? r[slot] : "—";
}

void pads_iniciar(Forja *a) {
  SDL_memset(&a->pads, 0, sizeof(a->pads));
  for (int s = 0; s < MAX_JOGADORES; s++) {
    a->pads.slot[s].pad = -1;
    a->pads.slot[s].reservado_por = -1;
  }
  a->pads.ultimo_join_pad = -1;
  const char *h = SDL_GetHint(SDL_HINT_JOYSTICK_ENHANCED_REPORTS);
  a->pads.contrato_estrito = h && SDL_strcmp(h, "0") == 0;
}

void pads_encerrar(Forja *a) {
  pads_silencio_todos(a);
  for (int i = 0; i < MAX_PADS; i++) {
    Pad *p = &a->pads.pad[i];
    if (!p->usado)
      continue;
    if (p->hid)
      SDL_hid_close(p->hid);
    if (p->gp)
      SDL_CloseGamepad(p->gp);
    p->usado = false;
  }
}

/* ---------- consultas ---------- */

Pad *pads_do_slot(Forja *a, int slot) {
  if (slot < 0 || slot >= MAX_JOGADORES || !a->pads.slot[slot].ocupado)
    return NULL;
  int i = a->pads.slot[slot].pad;
  return i >= 0 && a->pads.pad[i].usado ? &a->pads.pad[i] : NULL;
}

int pads_jogadores(Forja *a) {
  int n = 0;
  for (int s = 0; s < MAX_JOGADORES; s++)
    n += a->pads.slot[s].ocupado;
  return n;
}

int pads_conectados(Forja *a) {
  int n = 0;
  for (int i = 0; i < MAX_PADS; i++)
    n += a->pads.pad[i].usado;
  return n;
}

static int indice_do_pad(const Pad *p) {
  return (int)(p - FORJA->pads.pad);
}

bool pad_apertou(const Pad *p, SDL_GamepadButton b) {
  return p && b >= 0 && b < SDL_GAMEPAD_BUTTON_COUNT && g_apertou[indice_do_pad(p)][b];
}

bool pad_soltou(const Pad *p, SDL_GamepadButton b) {
  return p && b >= 0 && b < SDL_GAMEPAD_BUTTON_COUNT && g_soltou[indice_do_pad(p)][b];
}

bool pad_segura(const Pad *p, SDL_GamepadButton b) {
  return p && b >= 0 && b < SDL_GAMEPAD_BUTTON_COUNT && p->b[b];
}

bool pad_fala_dualsense(const Pad *p) { return p && p->cap_efeitos; }

const char *pad_transporte(const Pad *p) {
  if (!p)
    return "desconhecido";
  return p->simulado                                           ? "virtual"
         : p->conexao_sdl == SDL_JOYSTICK_CONNECTION_WIRED    ? "usb"
         : p->conexao_sdl == SDL_JOYSTICK_CONNECTION_WIRELESS ? "bt"
                                                              : "desconhecido";
}

int pad_lugar(const Pad *p) { return !p ? -1 : p->slot >= 0 ? p->slot : p->reserva; }

/* ---------- anotação ---------- */

void pad_anotar(Forja *a, Pad *p, bool ok, const char *formato, ...) {
  char corpo[160];
  va_list ap;
  va_start(ap, formato);
  vsnprintf(corpo, sizeof(corpo), formato, ap);
  va_end(ap);
  mascara_mac(corpo);
  if (p) {
    snprintf(p->saidas[p->saidas_prox], sizeof(p->saidas[0]), "%s%s", ok ? "" : "✗ ", corpo);
    p->saidas_t[p->saidas_prox] = a->t;
    p->saidas_prox = (p->saidas_prox + 1) % PAD_ANEL_SAIDAS;
    if (!ok)
      p->saidas_falhas++;
  }
  reg_linha(&a->reg, "%s ← %s%s", p ? pads_rotulo_slot(p->slot) : "--", corpo,
            ok ? "" : "  [o SDL recusou]");
}

/* O evento de saída na linha do tempo: quem, o quê, e se o SDL aceitou. */
static void ev_saida(Forja *a, const Pad *p, const char *o, bool ok, Evento *ev) {
  int l = pad_lugar(p);
  ev_iniciar(ev, &a->lt, "saida", l >= 0 ? l + 1 : 0);
  ev_int(ev, "seq", ++a->seq_saida[l >= 0 ? l : MAX_JOGADORES]);
  ev_str(ev, "o", o);
  ev_bool(ev, "ok", ok);
  if (p && l < 0)
    ev_str(ev, "controle", p->nome);
}

/* ---------- conexão ---------- */

static void assinatura(const Pad *p, char *out, size_t tam) {
  snprintf(out, tam, "%s|%d|%s", p->vidpid, (int)p->origem.tipo, p->nome);
}

/* ---------- a reserva (F04) ---------- */

/* O primeiro lugar que ninguém ocupa nem reservou, ou -1. */
static int lugar_livre(const Forja *a) {
  for (int s = 0; s < MAX_JOGADORES; s++)
    if (!a->pads.slot[s].ocupado && a->pads.slot[s].reservado_por < 0)
      return s;
  return -1;
}

static void soltar_reserva(Forja *a, Pad *p) {
  if (p->reserva >= 0) {
    a->pads.slot[p->reserva].reservado_por = -1;
    p->reserva = -1;
  }
}

/* Dá o lugar `s` ao pad `idx` como reserva: o player index, a luz e as luzinhas
 * do lugar chegam ao controle na hora, antes de qualquer botão. */
static void dar_reserva(Forja *a, int idx, int s, const char *evento) {
  Pad *p = &a->pads.pad[idx];
  p->reserva = s;
  a->pads.slot[s].reservado_por = idx;
  pad_luz_do_slot(a, p);
  pad_leds_do_slot(a, p);
  Evento ev;
  ev_iniciar(&ev, &a->lt, "conexao", s + 1);
  ev_str(&ev, "evento", evento); /* o lugar vai na cabeça (jogador - 1) */
  ev_str(&ev, "nome", p->nome);
  ev_fim(&ev, &a->lt);
  reg_linha(&a->reg, "%s %s %s", pads_rotulo_slot(s), SDL_strcmp(evento, "trocou") == 0 ? "passou a ser de" : "reservou", p->nome);
}

/* O primeiro lugar livre vira a reserva do pad; sem lugar, o controle espera
 * com o player index -1 (as luzinhas apagadas). */
static bool reservar(Forja *a, int idx) {
  Pad *p = &a->pads.pad[idx];
  int s = lugar_livre(a);
  if (s < 0) {
    SDL_SetGamepadPlayerIndex(p->gp, -1);
    return false;
  }
  dar_reserva(a, idx, s, "reservou");
  return true;
}

static void preencher_relatorio(Forja *a, int slot) {
  Pad *p = pads_do_slot(a, slot);
  if (!p)
    return;
  RelControle *c = &a->rel.controles[slot];
  c->presente = 1;
  c->jogador = slot + 1;
  rel_copiar(c->nome, sizeof(c->nome), p->nome);
  rel_copiar(c->nome_do_sistema, sizeof(c->nome_do_sistema), p->nome_sistema);
  rel_copiar(c->vid_pid, sizeof(c->vid_pid), p->vidpid);
  rel_copiar(c->conexao, sizeof(c->conexao), conexao_rotulo(p->origem.conexao));
  rel_copiar(c->origem, sizeof(c->origem), pad_origem_rotulo(p));
  rel_copiar(c->evidencia, sizeof(c->evidencia), p->origem.evidencia);
  rel_copiar(c->tipo_sdl, sizeof(c->tipo_sdl), SDL_GetGamepadStringForType(p->tipo));
  if (p->fw)
    snprintf(c->firmware, sizeof(c->firmware), "0x%04x", p->fw);
  c->giro_declarado_hz = p->giro_hz_declarado;
  c->acel_declarado_hz = p->acel_hz_declarado;
  c->reconexoes = a->pads.slot[slot].reconexoes;
  forja_relatorio_mudou(a);
}

static void ler_bateria(Pad *p) {
  int pct = -1;
  p->energia = SDL_GetGamepadPowerInfo(p->gp, &pct);
  p->bateria = pct;
  p->conexao_sdl = SDL_GetGamepadConnectionState(p->gp);
}

static void abrir_cru(Forja *a, Pad *p) {
  /* Só o DualSense (nativo ou virtual) que se declara USB: o report 0x01 de
   * 64 bytes. O 0x31 do rádio tem outros offsets, e este jogo não o fala. */
  if (p->simulado || !p->caminho[0] || !origem_eh_dualsense(p->origem.tipo))
    return;
  if (p->origem.conexao == CONEXAO_BT)
    return;
  p->hid = SDL_hid_open_path(p->caminho);
  if (p->hid)
    SDL_hid_set_nonblocking(p->hid, 1);
  reg_linha(&a->reg, "%s: report cru %s", p->nome, p->hid ? "aberto (só leitura)" : "indisponível");
}

static void conectou(Forja *a, SDL_JoystickID id) {
  if (indice_de(a, id) >= 0)
    return;
  int livre = -1;
  for (int i = 0; i < MAX_PADS; i++)
    if (!a->pads.pad[i].usado) {
      livre = i;
      break;
    }
  if (livre < 0)
    return;
  SDL_Gamepad *gp = SDL_OpenGamepad(id);
  if (!gp)
    return;
  Pad *p = &a->pads.pad[livre];
  SDL_memset(p, 0, sizeof(*p));
  p->usado = true;
  p->id = id;
  p->gp = gp;
  p->slot = -1;
  p->reserva = -1;
  p->espelho_de = -1;
  p->bateria = -1;
  p->visto_em = a->t;
  p->leds_jogador = -1;
  forja_sombra_zerar(&p->sombra);
  SDL_Joystick *js = SDL_GetGamepadJoystick(gp);
  p->simulado = js && SDL_IsJoystickVirtual(id);
  /* o nome do aparelho (o do joystick), e não o do mapeamento do SDL */
  const char *nome = js ? SDL_GetJoystickName(js) : NULL;
  if (!nome || !nome[0])
    nome = SDL_GetGamepadName(gp);
  mascara_mac_copia(nome ? nome : "controle", p->nome, sizeof(p->nome));
  const char *caminho = SDL_GetGamepadPath(gp);
  snprintf(p->caminho, sizeof(p->caminho), "%s", caminho ? caminho : "");
  p->vid = SDL_GetGamepadVendor(gp);
  p->pid = SDL_GetGamepadProduct(gp);
  p->fw = SDL_GetGamepadFirmwareVersion(gp);
  p->tipo = SDL_GetGamepadType(gp);
  snprintf(p->vidpid, sizeof(p->vidpid), "%04x:%04x", p->vid, p->pid);
  ler_bateria(p);

  OrigemFatos f;
  SDL_memset(&f, 0, sizeof(f));
  f.bus = -1;
  f.vid = p->vid;
  f.pid = p->pid;
  f.conexao_sdl = p->conexao_sdl == SDL_JOYSTICK_CONNECTION_WIRED      ? 1
                  : p->conexao_sdl == SDL_JOYSTICK_CONNECTION_WIRELESS ? 2
                                                                       : 0;
#if defined(SDL_PLATFORM_WINDOWS)
  f.windows = 1;
  f.wine = forja_sob_wine();
#endif
  if (!p->simulado)
    origem_fatos_linux(p->caminho, &f);
  if (f.vid == 0 && f.pid == 0) {
    f.vid = p->vid;
    f.pid = p->pid;
  }
  origem_classificar(&f, &p->origem);
  if (p->simulado) {
    p->origem.tipo = ORIGEM_DUALSENSE_NATIVO;
    p->origem.conexao = CONEXAO_VIRTUAL;
    snprintf(p->origem.evidencia, sizeof(p->origem.evidencia), "SDL_AttachVirtualJoystick (--simular)");
  }
  snprintf(p->nome_sistema, sizeof(p->nome_sistema), "%s", f.nome_sistema);
  mascara_mac(p->nome_sistema);
  snprintf(p->usb_pai, sizeof(p->usb_pai), "%s", f.usb_pai);

  SDL_PropertiesID props = SDL_GetGamepadProperties(gp);
  p->cap_rumble = SDL_GetBooleanProperty(props, SDL_PROP_GAMEPAD_CAP_RUMBLE_BOOLEAN, false);
  p->cap_rgb = SDL_GetBooleanProperty(props, SDL_PROP_GAMEPAD_CAP_RGB_LED_BOOLEAN, false);
  p->cap_leds = SDL_GetBooleanProperty(props, SDL_PROP_GAMEPAD_CAP_PLAYER_LED_BOOLEAN, false);
  bool ps5 = p->tipo == SDL_GAMEPAD_TYPE_PS5;
  p->cap_efeitos = ps5 && (p->cap_rgb || p->simulado);
  p->cap_giro = SDL_GamepadHasSensor(gp, SDL_SENSOR_GYRO);
  p->cap_acel = SDL_GamepadHasSensor(gp, SDL_SENSOR_ACCEL);
  if (p->cap_giro) {
    SDL_SetGamepadSensorEnabled(gp, SDL_SENSOR_GYRO, true);
    p->giro_hz_declarado = SDL_GetGamepadSensorDataRate(gp, SDL_SENSOR_GYRO);
  }
  if (p->cap_acel) {
    SDL_SetGamepadSensorEnabled(gp, SDL_SENSOR_ACCEL, true);
    p->acel_hz_declarado = SDL_GetGamepadSensorDataRate(gp, SDL_SENSOR_ACCEL);
  }
  p->cap_touch = SDL_GetNumGamepadTouchpads(gp) > 0;
  p->n_dedos = p->cap_touch ? SDL_GetNumGamepadTouchpadFingers(gp, 0) : 0;
  p->rumble_escala_cheia = p->pid == 0x0DF2 || p->fw == 0 || p->fw >= 0x0224;
  abrir_cru(a, p);

  {
    Evento ev;
    ev_iniciar(&ev, &a->lt, "conexao", 0);
    ev_str(&ev, "evento", "conectou");
    ev_str(&ev, "nome", p->nome);
    ev_str(&ev, "vid_pid", p->vidpid);
    ev_str(&ev, "transporte", pad_transporte(p));
    char fw[8];
    snprintf(fw, sizeof(fw), "0x%04x", p->fw);
    ev_str(&ev, "firmware", fw);
    ev_bool(&ev, "rumble_escala_cheia", p->rumble_escala_cheia);
    ev_str(&ev, "origem", pad_origem_rotulo(p));
    ev_str(&ev, "conexao", conexao_rotulo(p->origem.conexao));
    ev_bool(&ev, "efeitos", p->cap_efeitos);
    ev_num(&ev, "giro_hz_declarado", p->giro_hz_declarado);
    ev_fim(&ev, &a->lt);
  }
  reg_linha(&a->reg,
            "conectou: %s [%s] · %s · %s · efeitos %s · giro %s (%.0f Hz declarados) · toque %s · firmware 0x%04x · rumble %s · transporte %s",
            p->nome, p->vidpid, pad_origem_rotulo(p), conexao_rotulo(p->origem.conexao),
            p->cap_efeitos ? "sim" : "não", p->cap_giro ? "sim" : "não", p->giro_hz_declarado,
            p->cap_touch ? "sim" : "não", p->fw,
            p->rumble_escala_cheia ? "inteiro" : "pela metade (firmware abaixo de 2.24)", pad_transporte(p));
  if (a->pads.contrato_estrito && p->origem.conexao == CONEXAO_BT && origem_eh_dualsense(p->origem.tipo))
    reg_linha(&a->reg, "%s: no rádio, só entrada — este jogo não fala o relatório 0x31. ligue o "
                       "DualSense no cabo, ou um DualSense virtual USB.",
              p->nome);

  /* A volta: um slot desconectado com a mesma assinatura, e só um, retoma. */
  char sig[200];
  assinatura(p, sig, sizeof(sig));
  int candidato = -1, candidatos = 0;
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Slot *sl = &a->pads.slot[s];
    if (sl->ocupado && sl->pad < 0 && strcmp(sl->assinatura, sig) == 0) {
      candidato = s;
      candidatos++;
    }
  }
  if (candidatos == 1) {
    Slot *sl = &a->pads.slot[candidato];
    sl->pad = livre;
    sl->desconectado_em = 0;
    sl->reconexoes++;
    p->slot = candidato;
    SDL_SetGamepadPlayerIndex(gp, candidato);
    pad_luz_do_slot(a, p);
    pad_leds_do_slot(a, p);
    preencher_relatorio(a, candidato);
    reg_linha(&a->reg, "%s voltou ao lugar (reconexão %d)", pads_rotulo_slot(candidato), sl->reconexoes);
    forja_avisar(a, "%s voltou ao lugar", pads_rotulo_slot(candidato));
  }
  /* quem chega pela primeira vez recebe o primeiro lugar livre já na conexão
   * (depois da volta: quem caiu reencontra o seu) */
  if (p->slot < 0)
    reservar(a, livre);
}

static void desconectou(Forja *a, SDL_JoystickID id) {
  int i = indice_de(a, id);
  if (i < 0)
    return;
  Pad *p = &a->pads.pad[i];
  {
    Evento ev;
    ev_iniciar(&ev, &a->lt, "conexao", p->slot >= 0 ? p->slot + 1 : 0);
    ev_str(&ev, "evento", "desconectou");
    ev_str(&ev, "nome", p->nome);
    ev_fim(&ev, &a->lt);
  }
  if (p->slot >= 0) {
    Slot *sl = &a->pads.slot[p->slot];
    sl->pad = -1;
    sl->desconectado_em = a->t > 0 ? a->t : 0.001f;
    reg_linha(&a->reg, "%s ficou sem controle: %s desconectou", pads_rotulo_slot(p->slot), p->nome);
    forja_avisar(a, "%s sem controle — reconecte para voltar", pads_rotulo_slot(p->slot));
  } else {
    reg_linha(&a->reg, "desconectou: %s", p->nome);
  }
  if (p->hid)
    SDL_hid_close(p->hid);
  SDL_CloseGamepad(p->gp);
  soltar_reserva(a, p);
  SDL_memset(p, 0, sizeof(*p));
  p->slot = -1;
  p->reserva = -1;
  for (int b = 0; b < SDL_GAMEPAD_BUTTON_COUNT; b++)
    g_apertou[i][b] = g_soltou[i][b] = false;
}

bool pads_evento(Forja *a, const SDL_Event *e) {
  switch (e->type) {
  case SDL_EVENT_GAMEPAD_ADDED:
    conectou(a, e->gdevice.which);
    return true;
  case SDL_EVENT_GAMEPAD_REMOVED:
    desconectou(a, e->gdevice.which);
    return true;
  case SDL_EVENT_GAMEPAD_BUTTON_DOWN:
  case SDL_EVENT_GAMEPAD_BUTTON_UP: {
    int i = indice_de(a, e->gbutton.which);
    if (i < 0 || e->gbutton.button >= SDL_GAMEPAD_BUTTON_COUNT)
      return true;
    Pad *p = &a->pads.pad[i];
    p->b[e->gbutton.button] = e->gbutton.down;
    if (e->gbutton.down) {
      g_apertou[i][e->gbutton.button] = true;
      p->b_quando[e->gbutton.button] = e->gbutton.timestamp;
    } else {
      g_soltou[i][e->gbutton.button] = true;
    }
    return true;
  }
  case SDL_EVENT_GAMEPAD_AXIS_MOTION: {
    int i = indice_de(a, e->gaxis.which);
    if (i < 0 || e->gaxis.axis >= SDL_GAMEPAD_AXIS_COUNT)
      return true;
    float v = e->gaxis.value / 32767.0f;
    a->pads.pad[i].ax[e->gaxis.axis] = limitar(v, -1, 1);
    return true;
  }
  case SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN:
  case SDL_EVENT_GAMEPAD_TOUCHPAD_MOTION:
  case SDL_EVENT_GAMEPAD_TOUCHPAD_UP: {
    int i = indice_de(a, e->gtouchpad.which);
    if (i < 0 || e->gtouchpad.finger < 0 || e->gtouchpad.finger > 1)
      return true;
    Dedo *d = &a->pads.pad[i].dedo[e->gtouchpad.finger];
    d->baixo = e->type != SDL_EVENT_GAMEPAD_TOUCHPAD_UP;
    d->x = e->gtouchpad.x;
    d->y = e->gtouchpad.y;
    d->pressao = e->gtouchpad.pressure;
    return true;
  }
  case SDL_EVENT_GAMEPAD_SENSOR_UPDATE: {
    int i = indice_de(a, e->gsensor.which);
    if (i < 0)
      return true;
    Pad *p = &a->pads.pad[i];
    Uint64 host = p->simulado ? a->relogio_sim_ns : e->gsensor.timestamp;
    if (e->gsensor.sensor == SDL_SENSOR_GYRO) {
      SDL_memcpy(p->giro, e->gsensor.data, sizeof(p->giro));
      taxa_evento(&p->taxa_giro, host, e->gsensor.sensor_timestamp);
      postura_giro(&p->postura, p->giro, e->gsensor.sensor_timestamp, host);
    } else if (e->gsensor.sensor == SDL_SENSOR_ACCEL) {
      SDL_memcpy(p->acel, e->gsensor.data, sizeof(p->acel));
      taxa_evento(&p->taxa_acel, host, e->gsensor.sensor_timestamp);
      postura_acel(&p->postura, p->acel);
    }
    return true;
  }
  default:
    return false;
  }
}

void pads_atualizar(Forja *a, float dt) {
  (void)dt;
  Uint64 agora = SDL_GetTicks();
  static float bateria_em = 0;
  bool ler_bat = a->t - bateria_em > 2.0f;
  if (ler_bat)
    bateria_em = a->t;
  for (int i = 0; i < MAX_PADS; i++) {
    Pad *p = &a->pads.pad[i];
    if (!p->usado)
      continue;
    if (p->simulado && p->rumble_ate_t > 0 && a->t >= p->rumble_ate_t) {
      /* o controle simulado: quem para o motor é o jogo, no relógio dele */
      SDL_RumbleGamepad(p->gp, 0, 0, 0);
      p->rumble_ate_t = 0;
      p->rumble_ate_ms = 0;
      p->rumble_baixo = p->rumble_alto = 0;
      p->sombra.motor_esq = p->sombra.motor_dir = 0;
    } else if (!p->simulado && p->rumble_ate_ms && agora >= p->rumble_ate_ms) {
      p->rumble_ate_ms = 0;
      p->rumble_baixo = p->rumble_alto = 0;
      p->sombra.motor_esq = p->sombra.motor_dir = 0;
    }
    if (ler_bat)
      ler_bateria(p);
    if (p->hid) {
      Uint8 buf[80];
      int n, lidos = 0;
      while (lidos < 64 && (n = SDL_hid_read(p->hid, buf, sizeof(buf))) > 0) {
        lidos++;
        if (buf[0] == 0x31) {
          /* chegou report do rádio: não é o que este jogo lê */
          reg_linha(&a->reg, "%s: report 0x31 no cru — fechado (este jogo não fala o 0x31)", p->nome);
          SDL_hid_close(p->hid);
          p->hid = NULL;
          p->cru_ok = false;
          break;
        }
        if (buf[0] == 0x01 && n >= 64) {
          SDL_memcpy(p->cru, buf, 64);
          p->status53 = buf[1 + 53];
          p->cru_ok = true;
          p->cru_reports++;
        }
      }
    }
  }
  /* o relatório acompanha a taxa medida e a bateria de quem está na mesa */
  for (int s = 0; s < MAX_JOGADORES; s++) {
    Pad *p = pads_do_slot(a, s);
    if (!p)
      continue;
    RelControle *c = &a->rel.controles[s];
    Uint64 ns = pad_agora_ns(a, p);
    double hz = taxa_hz_host(&p->taxa_giro, ns, 2.0);
    if (hz > 0) {
      c->giro_medido_hz = hz;
      c->giro_medido_relogio_hz = taxa_hz_sensor(&p->taxa_giro, ns, 2.0);
    }
    double hza = taxa_hz_host(&p->taxa_acel, ns, 2.0);
    if (hza > 0)
      c->acel_medido_hz = hza;
    if (ler_bat && p->bateria >= 0) {
      const char *estado = p->energia == SDL_POWERSTATE_CHARGING   ? " (carregando)"
                           : p->energia == SDL_POWERSTATE_CHARGED  ? " (carregado)"
                           : p->energia == SDL_POWERSTATE_ON_BATTERY ? " (na bateria)"
                                                                     : "";
      snprintf(c->bateria, sizeof(c->bateria), "%d%%%s", p->bateria, estado);
    }
  }
  /* um lugar vagou: quem esperava sem lugar (o quinto controle) recebe */
  for (int i = 0; i < MAX_PADS && lugar_livre(a) >= 0; i++) {
    Pad *p = &a->pads.pad[i];
    if (p->usado && p->slot < 0 && p->reserva < 0 && p->espelho_de < 0)
      reservar(a, i);
  }
}

void pads_fim_do_quadro(Forja *a) {
  (void)a;
  SDL_memset(g_apertou, 0, sizeof(g_apertou));
  SDL_memset(g_soltou, 0, sizeof(g_soltou));
}

/* ---------- a mesa ---------- */

int pads_entrar(Forja *a, int idx) {
  if (idx < 0 || idx >= MAX_PADS || !a->pads.pad[idx].usado)
    return -1;
  Pad *p = &a->pads.pad[idx];
  if (p->slot >= 0)
    return p->slot;
  /* o espelho: o mesmo aperto chegou por outro controle da mesa agora há pouco
   * (um controle de mentira do simulador nunca é espelho de nada — e, no modo
   * acelerado, os apertos do robô ficam a milissegundos uns dos outros) */
  for (int s = 0; s < MAX_JOGADORES && !p->simulado; s++) {
    Pad *o = pads_do_slot(a, s);
    if (!o || o == p)
      continue;
    Uint64 t1 = o->b_quando[SDL_GAMEPAD_BUTTON_SOUTH], t2 = p->b_quando[SDL_GAMEPAD_BUTTON_SOUTH];
    Uint64 d = t1 > t2 ? t1 - t2 : t2 - t1;
    if (t1 && t2 && d < JANELA_ESPELHO_NS) {
      p->espelho_de = s;
      reg_linha(&a->reg, "%s parece espelho de %s (o mesmo ✕ em %.1f ms): fica de fora", p->nome,
                pads_rotulo_slot(s), d / 1e6);
      forja_avisar(a, "Esse controle parece espelho de %s — ficou de fora", pads_rotulo_slot(s));
      /* os dois caminhos do mesmo aparelho dizem o mesmo lugar */
      soltar_reserva(a, p);
      SDL_SetGamepadPlayerIndex(p->gp, s);
      pad_luz(a, p, LUZ_DO_LUGAR[s]);
      return -1;
    }
  }
  char sig[200];
  assinatura(p, sig, sizeof(sig));
  int alvo = -1;
  /* primeiro, um lugar de quem caiu com a mesma assinatura */
  for (int s = 0; s < MAX_JOGADORES && alvo < 0; s++)
    if (a->pads.slot[s].ocupado && a->pads.slot[s].pad < 0 && strcmp(a->pads.slot[s].assinatura, sig) == 0)
      alvo = s;
  /* depois, o lugar que a conexão deu a ele (o ✕ só confirma) */
  if (alvo < 0 && p->reserva >= 0 && !a->pads.slot[p->reserva].ocupado)
    alvo = p->reserva;
  /* por fim, um lugar que ninguém ocupa nem reservou. Um controle estranho
   * nunca herda o lugar de quem caiu: esse só volta pela assinatura. */
  for (int s = 0; s < MAX_JOGADORES && alvo < 0; s++)
    if (!a->pads.slot[s].ocupado && a->pads.slot[s].reservado_por < 0)
      alvo = s;
  if (alvo < 0)
    return -1;
  Slot *sl = &a->pads.slot[alvo];
  bool volta = sl->ocupado;
  soltar_reserva(a, p);
  sl->ocupado = true;
  sl->pad = idx;
  sl->desconectado_em = 0;
  if (volta)
    sl->reconexoes++;
  snprintf(sl->assinatura, sizeof(sl->assinatura), "%s", sig);
  p->slot = alvo;
  p->espelho_de = -1;
  SDL_SetGamepadPlayerIndex(p->gp, alvo);
  pad_luz_do_slot(a, p);
  pad_leds_do_slot(a, p);
  preencher_relatorio(a, alvo);
  {
    Evento ev;
    ev_iniciar(&ev, &a->lt, "conexao", alvo + 1);
    ev_str(&ev, "evento", "entrou_no_lugar");
    ev_str(&ev, "nome", p->nome);
    ev_str(&ev, "vid_pid", p->vidpid);
    ev_str(&ev, "origem", pad_origem_rotulo(p));
    ev_str(&ev, "conexao", conexao_rotulo(p->origem.conexao));
    ev_fim(&ev, &a->lt);
  }
  reg_linha(&a->reg, "%s entrou: %s [%s] · %s · %s", pads_rotulo_slot(alvo), p->nome, p->vidpid,
            pad_origem_rotulo(p), conexao_rotulo(p->origem.conexao));
  a->pads.ultimo_join_pad = idx;
  a->pads.ultimo_join_ns = SDL_GetTicksNS();
  return alvo;
}

void pads_sair(Forja *a, int slot) {
  if (slot < 0 || slot >= MAX_JOGADORES)
    return;
  Slot *sl = &a->pads.slot[slot];
  if (!sl->ocupado)
    return;
  Pad *p = pads_do_slot(a, slot);
  if (p)
    pads_silencio(a, slot);
  reg_linha(&a->reg, "%s deixou o lugar", pads_rotulo_slot(slot));
  SDL_memset(sl, 0, sizeof(*sl));
  sl->pad = -1;
  sl->reservado_por = -1;
  if (p) {
    /* o controle continua com o número e a cor: o lugar vira a reserva dele */
    p->slot = -1;
    p->reserva = slot;
    sl->reservado_por = indice_do_pad(p);
  }
}

int pads_trocar_reserva(Forja *a, int idx) {
  if (idx < 0 || idx >= MAX_PADS || !a->pads.pad[idx].usado)
    return -1;
  Pad *p = &a->pads.pad[idx];
  if (p->slot >= 0)
    return p->slot;
  int base = p->reserva >= 0 ? p->reserva : -1;
  for (int k = 1; k <= MAX_JOGADORES; k++) {
    int s = (base + k) % MAX_JOGADORES;
    if (s == p->reserva || a->pads.slot[s].ocupado || a->pads.slot[s].reservado_por >= 0)
      continue;
    soltar_reserva(a, p);
    dar_reserva(a, idx, s, "trocou");
    return s;
  }
  return p->reserva;
}

void pads_silencio(Forja *a, int slot) {
  Pad *p = pads_do_slot(a, slot);
  if (!p)
    return;
  if (p->rumble_baixo || p->rumble_alto || p->rumble_ate_ms)
    pad_rumble(a, p, 0, 0, 0);
  if (p->cap_efeitos) {
    if (p->modo_l2 != FORJA_TRIGGER_OFF || p->modo_r2 != FORJA_TRIGGER_OFF)
      pad_gatilhos_off(a, p);
    if (p->led_mic != 0)
      pad_led_mic(a, p, 0);
  }
  pad_luz_do_slot(a, p);
  pad_leds_do_slot(a, p);
}

void pads_silencio_todos(Forja *a) {
  for (int s = 0; s < MAX_JOGADORES; s++)
    pads_silencio(a, s);
}

/* ---------- saídas ---------- */

static Uint8 escala_rumble(const Pad *p, Uint16 v) {
  Uint8 b = (Uint8)(v >> 8);
  return p->rumble_escala_cheia ? b : (Uint8)(b >> 1);
}

bool pad_rumble(Forja *a, Pad *p, float forte, float fraco, int ms) {
  if (!p || !p->gp)
    return false;
  float k = limitar(a->intensidade, 0, 1);
  Uint16 baixo = (Uint16)(limitar(forte, 0, 1) * k * 65535.0f);
  Uint16 alto = (Uint16)(limitar(fraco, 0, 1) * k * 65535.0f);
  /* Num controle simulado, a duração corre no relógio do jogo (a->t), como a
   * taxa do giroscópio: a prova roda mais rápido que o tempo real e a captura
   * mais devagar, e um golpe de 260 ms do relógio de parede caberia inteiro
   * entre dois quadros de um runner lento — o robô não sentiria. O SDL fica
   * sem prazo, e pads_atualizar para o motor na hora. */
  Uint32 dur = (Uint32)(ms > 0 ? ms : 0);
  bool ok = SDL_RumbleGamepad(p->gp, baixo, alto, p->simulado ? 0 : dur);
  p->rumble_baixo = baixo;
  p->rumble_alto = alto;
  p->rumble_ate_ms = (baixo || alto) && ms > 0 ? SDL_GetTicks() + (Uint64)ms : 0;
  p->rumble_ate_t = (baixo || alto) && ms > 0 ? a->t + (float)ms / 1000.0f : 0.0f;
  p->sombra.motor_esq = escala_rumble(p, baixo);
  p->sombra.motor_dir = escala_rumble(p, alto);
  Evento ev;
  ev_saida(a, p, "vibracao", ok, &ev);
  ev_num(&ev, "forte", forte * k);
  ev_num(&ev, "fraco", fraco * k);
  ev_int(&ev, "ms", ms);
  ev_fim(&ev, &a->lt);
  if (baixo || alto)
    pad_anotar(a, p, ok, "vibração: forte %d%% · fraco %d%% · %d ms", (int)(forte * 100), (int)(fraco * 100), ms);
  else
    pad_anotar(a, p, ok, "vibração: parada");
  return ok;
}

bool pad_luz(Forja *a, Pad *p, SDL_Color c) {
  if (!p || !p->gp)
    return false;
  bool ok = SDL_SetGamepadLED(p->gp, c.r, c.g, c.b);
  p->luz = c;
  p->sombra.led_r = c.r;
  p->sombra.led_g = c.g;
  p->sombra.led_b = c.b;
  Evento ev;
  ev_saida(a, p, "lightbar", ok, &ev);
  int rgb[3] = {c.r, c.g, c.b};
  ev_ints(&ev, "rgb", rgb, 3);
  ev_fim(&ev, &a->lt);
  pad_anotar(a, p, ok, "lightbar: #%02x%02x%02x", c.r, c.g, c.b);
  return ok;
}

bool pad_luz_do_slot(Forja *a, Pad *p) {
  int l = pad_lugar(p);
  if (l < 0)
    return false;
  return pad_luz(a, p, LUZ_DO_LUGAR[l]);
}

static const char *nome_modo(ForjaTriggerMode m) {
  switch (m) {
  case FORJA_TRIGGER_FEEDBACK:
    return "Resistência (Feedback)";
  case FORJA_TRIGGER_WEAPON:
    return "Arma (Weapon)";
  case FORJA_TRIGGER_VIBRATION:
    return "Vibração (Vibration)";
  default:
    return "Off";
  }
}

static bool enviar(Forja *a, Pad *p, const ForjaDs5Effect *fx) {
  if (!p->cap_efeitos)
    return false;
  (void)a;
  return SDL_SendGamepadEffect(p->gp, fx, (int)sizeof(*fx));
}

bool pad_gatilho(Forja *a, Pad *p, int direito, ForjaTrigger t) {
  if (!p || !p->gp)
    return false;
  ForjaDs5Effect fx;
  forja_fx_gatilho(&fx, &p->sombra, direito, t);
  bool ok = enviar(a, p, &fx);
  if (direito)
    p->modo_r2 = t.mode;
  else
    p->modo_l2 = t.mode;
  Evento ev;
  ev_saida(a, p, "gatilho", ok, &ev);
  ev_str(&ev, "lado", direito ? "R2" : "L2");
  static const char *modos[] = {"off", "resistencia", "arma", "vibracao"};
  ev_str(&ev, "modo", modos[t.mode & 3]);
  int params[3] = {t.a, t.b, t.c};
  ev_ints(&ev, "params", params, 3);
  ev_int(&ev, "byte_modo", direito ? p->sombra.gatilho_dir[0] : p->sombra.gatilho_esq[0]);
  ev_fim(&ev, &a->lt);
  pad_anotar(a, p, ok, "gatilho %s: %s (%d, %d, %d) · 0x%02x", direito ? "R2" : "L2", nome_modo(t.mode),
             t.a, t.b, t.c, direito ? p->sombra.gatilho_dir[0] : p->sombra.gatilho_esq[0]);
  return ok;
}

bool pad_gatilhos_off(Forja *a, Pad *p) {
  if (!p || !p->gp)
    return false;
  ForjaDs5Effect fx;
  ForjaTrigger off = {FORJA_TRIGGER_OFF, 0, 0, 0};
  forja_fx_gatilhos(&fx, &p->sombra, off, off);
  bool ok = enviar(a, p, &fx);
  p->modo_l2 = p->modo_r2 = FORJA_TRIGGER_OFF;
  Evento ev;
  ev_saida(a, p, "gatilho", ok, &ev);
  ev_str(&ev, "lado", "L2+R2");
  ev_str(&ev, "modo", "off");
  ev_fim(&ev, &a->lt);
  pad_anotar(a, p, ok, "gatilhos L2 e R2: Off (0x05)");
  return ok;
}

bool pad_led_mic(Forja *a, Pad *p, int modo) {
  if (!p || !p->gp)
    return false;
  ForjaDs5Effect fx;
  forja_fx_led_mic(&fx, &p->sombra, (uint8_t)modo);
  bool ok = enviar(a, p, &fx);
  p->led_mic = p->sombra.led_mic;
  static const char *nomes[] = {"apagado", "aceso", "piscando", "piscando lento"};
  Evento ev;
  ev_saida(a, p, "led_microfone", ok, &ev);
  ev_int(&ev, "modo", p->led_mic);
  ev_fim(&ev, &a->lt);
  pad_anotar(a, p, ok, "LED do microfone: %s", nomes[p->led_mic & 3]);
  return ok;
}

bool pad_leds_jogador(Forja *a, Pad *p, int mascara) {
  if (!p || !p->gp)
    return false;
  ForjaDs5Effect fx;
  forja_fx_leds_jogador(&fx, &p->sombra, (uint8_t)mascara, 1);
  bool ok = enviar(a, p, &fx);
  p->leds_jogador = mascara & 0x1F;
  char fig[6];
  for (int i = 0; i < 5; i++)
    fig[i] = (mascara >> i) & 1 ? 'x' : '-';
  fig[5] = '\0';
  Evento ev;
  ev_saida(a, p, "leds_jogador", ok, &ev);
  ev_int(&ev, "mascara", mascara & 0x1F);
  ev_fim(&ev, &a->lt);
  pad_anotar(a, p, ok, "LEDs de jogador: %s (0x%02x)", fig, mascara & 0x1F);
  return ok;
}

bool pad_leds_do_slot(Forja *a, Pad *p) {
  int l = pad_lugar(p);
  if (!p || !p->gp || l < 0)
    return false;
  bool ok = SDL_SetGamepadPlayerIndex(p->gp, l);
  p->leds_jogador = forja_leds_do_jogador(l);
  p->sombra.leds_jogador = (Uint8)(p->leds_jogador | 0x20);
  Evento ev;
  ev_saida(a, p, "player_index", ok, &ev);
  ev_int(&ev, "indice", l);
  ev_fim(&ev, &a->lt);
  pad_anotar(a, p, ok, "player index %d (LEDs %s)", l,
             l == 0 ? "--x--" : l == 1 ? "-x-x-" : l == 2 ? "x-x-x" : "xx-xx");
  return ok;
}

bool pad_alto_falante(Forja *a, Pad *p, int volume, int rota, int preamp) {
  if (!p || !p->gp)
    return false;
  ForjaDs5Effect fx;
  forja_fx_alto_falante(&fx, &p->sombra, (uint8_t)volume, (uint8_t)rota, (uint8_t)preamp);
  bool ok = enviar(a, p, &fx);
  Evento ev;
  ev_saida(a, p, "audio_hid", ok, &ev);
  ev_int(&ev, "volume", volume & 0xFF);
  ev_int(&ev, "rota", rota);
  ev_int(&ev, "preamp", preamp);
  ev_fim(&ev, &a->lt);
  pad_anotar(a, p, ok, "áudio do HID: volume 0x%02x · rota %d · pré-amp %d", volume & 0xFF, rota, preamp);
  return ok;
}
