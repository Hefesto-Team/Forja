/* As medidas das salas de entrada, do lado do módulo: o que o jogador fez
 * enquanto jogava vira o veredito de cada feature (medidas.h, a mesma régua
 * provada sem aparelho). A sala 3D só diz o que está pedindo agora (a runa
 * acesa, o círculo, o fole, os dois dedos, a mira, a martelada); o módulo
 * amostra os controles a cada quadro, depois de bombear o SDL, e no fim dá o
 * veredito e o grava no relatório. */
#include "forja_controles.h"
#include "forja_interno.h"

extern "C" {
#include "catalogo.h"
#include "cegas.h"
#include "forja.h"
#include "medidas.h"
#include "pads.h"
#include "postura.h"
#include "relatorio.h"
#include "sintese.h"
#include "taxa.h"
}

#include <cmath>
#include <cstdio>
#include <cstring>

using namespace godot;

namespace {

struct MedidaLugar {
  bool ativa = false;
  bool mexeu = false;   /* o controle fez alguma coisa na sala */
  bool repouso = false; /* a sala pede para soltar os analógicos */
  int pedido = -1;      /* o botão da runa acesa agora */
  MedBotoes botoes;
  MedAnalogico esq, dir;
  MedGatilho l2, r2;
  MedToque toque;
  MedSensores sensores;
  long giro0 = 0, acel0 = 0;
  int concorda0[2] = {0, 0}, discorda0[2] = {0, 0};
  /* O controle que cai e volta é outro Pad, com as contagens do zero: o que o
   * antigo já tinha contado fica guardado aqui, e as bases passam ao novo. */
  SDL_JoystickID pad_id = 0;
  long giro_antes = 0, acel_antes = 0;
  int concorda_antes[2] = {0, 0}, discorda_antes[2] = {0, 0};
  long giro_visto = 0, acel_visto = 0;
  int concorda_visto[2] = {0, 0}, discorda_visto[2] = {0, 0};
  uint32_t marcados = 0; /* botões cujo primeiro aperto já foi para a linha do tempo */
  bool marcou_toque = false, marcou_dois = false, marcou_clique = false;
  /* A Prova: a carga (o giroscópio sem buraco, as saídas aceitas) */
  bool carga_ativa = false;
  MedCarga carga{};
  uint64_t carga_giro_ult = 0;
};

MedidaLugar g_med[MAX_JOGADORES];

/* o nome de cada botão, para o `medido` */
const char *const *nomes_botoes() {
  static const char *nomes[MED_MAX_BOTOES] = {};
  static bool pronto = false;
  if (!pronto) {
    pronto = true;
    nomes[SDL_GAMEPAD_BUTTON_SOUTH] = "cruz";
    nomes[SDL_GAMEPAD_BUTTON_EAST] = "círculo";
    nomes[SDL_GAMEPAD_BUTTON_WEST] = "quadrado";
    nomes[SDL_GAMEPAD_BUTTON_NORTH] = "triângulo";
    nomes[SDL_GAMEPAD_BUTTON_BACK] = "Create";
    nomes[SDL_GAMEPAD_BUTTON_GUIDE] = "PS";
    nomes[SDL_GAMEPAD_BUTTON_START] = "Options";
    nomes[SDL_GAMEPAD_BUTTON_LEFT_STICK] = "L3";
    nomes[SDL_GAMEPAD_BUTTON_RIGHT_STICK] = "R3";
    nomes[SDL_GAMEPAD_BUTTON_LEFT_SHOULDER] = "L1";
    nomes[SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER] = "R1";
    nomes[SDL_GAMEPAD_BUTTON_DPAD_UP] = "seta ↑";
    nomes[SDL_GAMEPAD_BUTTON_DPAD_DOWN] = "seta ↓";
    nomes[SDL_GAMEPAD_BUTTON_DPAD_LEFT] = "seta ←";
    nomes[SDL_GAMEPAD_BUTTON_DPAD_RIGHT] = "seta →";
    nomes[SDL_GAMEPAD_BUTTON_MISC1] = "microfone";
    nomes[SDL_GAMEPAD_BUTTON_TOUCHPAD] = "clique do touchpad";
  }
  return nomes;
}

bool lugar_valido(int l) { return l >= 0 && l < MAX_JOGADORES; }

/* um marco de entrada na linha do tempo: a primeira vez que algo chegou */
void marco(int lugar, const char *o_que, const char *detalhe) {
  if (!FORJA)
    return;
  Evento ev;
  ev_iniciar(&ev, &FORJA->lt, "entrada", lugar + 1);
  ev_str(&ev, "o", o_que);
  if (detalhe && detalhe[0])
    ev_str(&ev, "detalhe", detalhe);
  ev_fim(&ev, &FORJA->lt);
}

String txt(const char *s) { return String::utf8(s ? s : ""); }

} // namespace

bool ForjaControles::med_comecar(int lugar, int64_t botoes) {
  if (!aberto_ || !lugar_valido(lugar))
    return false;
  MedidaLugar &m = g_med[lugar];
  m = MedidaLugar();
  m.ativa = true;
  med_botoes_iniciar(&m.botoes, (uint32_t)botoes, nomes_botoes());
  med_analogico_iniciar(&m.esq);
  med_analogico_iniciar(&m.dir);
  med_gatilho_iniciar(&m.l2);
  med_gatilho_iniciar(&m.r2);
  med_toque_iniciar(&m.toque);
  Pad *p = pads_do_slot(FORJA, lugar);
  med_sensores_iniciar(&m.sensores, p && p->cap_giro, p && p->cap_acel, p ? p->giro_hz_declarado : 0);
  if (p) {
    m.pad_id = p->id;
    m.giro0 = p->postura.amostras_giro;
    m.acel0 = p->postura.amostras_acel;
    for (int e = 0; e < 2; e++) {
      m.concorda0[e] = p->postura.concorda[e];
      m.discorda0[e] = p->postura.discorda[e];
    }
  }
  return p != nullptr;
}

void ForjaControles::med_parar(int lugar) {
  if (lugar_valido(lugar))
    g_med[lugar].ativa = false;
}

/* Volta a medir o que já vinha medindo (a pausa não zera nada: o que se
 * aperta no menu não conta, o que veio antes fica). */
void ForjaControles::med_retomar(int lugar) {
  if (lugar_valido(lugar) && aberto_)
    g_med[lugar].ativa = true;
}

void ForjaControles::med_pedido(int lugar, int botao) {
  if (!lugar_valido(lugar))
    return;
  MedidaLugar &m = g_med[lugar];
  m.pedido = botao;
  if (botao >= 0)
    med_botoes_mostrou(&m.botoes, botao);
}

void ForjaControles::med_repouso(int lugar, bool sim) {
  if (lugar_valido(lugar))
    g_med[lugar].repouso = sim;
}

/* A sala chegou a pedir: só o que foi pedido pode falhar. */
void ForjaControles::med_pedir(int lugar, const String &o_que) {
  if (!lugar_valido(lugar))
    return;
  MedidaLugar &m = g_med[lugar];
  if (o_que == "analogico_l")
    m.esq.pedido = true;
  else if (o_que == "analogico_r")
    m.dir.pedido = true;
  else if (o_que == "gatilho_l2")
    m.l2.pedido = true;
  else if (o_que == "gatilho_r2")
    m.r2.pedido = true;
  else if (o_que == "dois_dedos")
    m.toque.pediu_dois = true;
  else if (o_que == "clique")
    m.toque.pediu_clique = true;
  else if (o_que == "mira")
    m.sensores.pediu_mira = true;
  else if (o_que == "martelada")
    m.sensores.pediu_martelada = true;
}

void ForjaControles::med_faixa(int lugar, int lado) {
  if (lugar_valido(lugar))
    (lado ? g_med[lugar].r2 : g_med[lugar].l2).faixas++;
}

void ForjaControles::med_tracou(int lugar) {
  if (lugar_valido(lugar))
    g_med[lugar].toque.tracou = true;
}

void ForjaControles::med_martelada(int lugar) {
  if (lugar_valido(lugar))
    med_sensores_martelada(&g_med[lugar].sensores);
}

/* Um quadro de medida: logo depois de o SDL ser bombeado. */
void ForjaControles::med_quadro() {
  if (!aberto_)
    return;
  for (int l = 0; l < MAX_JOGADORES; l++) {
    MedidaLugar &m = g_med[l];
    if (!m.ativa)
      continue;
    Pad *p = pads_do_slot(FORJA, l);
    if (!p)
      continue;
    if (p->id != m.pad_id) {
      /* o controle voltou ao lugar: guarda o que o de antes contou e rebaseia */
      m.giro_antes += m.giro_visto;
      m.acel_antes += m.acel_visto;
      for (int e = 0; e < 2; e++) {
        m.concorda_antes[e] += m.concorda_visto[e];
        m.discorda_antes[e] += m.discorda_visto[e];
        m.concorda0[e] = p->postura.concorda[e];
        m.discorda0[e] = p->postura.discorda[e];
        m.concorda_visto[e] = m.discorda_visto[e] = 0;
      }
      m.giro0 = p->postura.amostras_giro;
      m.acel0 = p->postura.amostras_acel;
      m.giro_visto = m.acel_visto = 0;
      m.carga_giro_ult = p->taxa_giro.total;
      m.pad_id = p->id;
    }
    m.giro_visto = p->postura.amostras_giro - m.giro0;
    m.acel_visto = p->postura.amostras_acel - m.acel0;
    for (int e = 0; e < 2; e++) {
      m.concorda_visto[e] = p->postura.concorda[e] - m.concorda0[e];
      m.discorda_visto[e] = p->postura.discorda[e] - m.discorda0[e];
    }
    bool atividade = false;
    for (int b = 0; b < SDL_GAMEPAD_BUTTON_COUNT && b < MED_MAX_BOTOES; b++) {
      if (!::pad_apertou(p, (SDL_GamepadButton)b) || b == SDL_GAMEPAD_BUTTON_START)
        continue;
      atividade = true;
      med_botoes_apertou(&m.botoes, b, m.pedido);
      if ((m.botoes.pedidos & (1u << b)) && !(m.marcados & (1u << b))) {
        m.marcados |= 1u << b;
        marco(l, "botao", nomes_botoes()[b]);
      }
    }
    float lx = p->ax[SDL_GAMEPAD_AXIS_LEFTX], ly = p->ax[SDL_GAMEPAD_AXIS_LEFTY];
    float rx = p->ax[SDL_GAMEPAD_AXIS_RIGHTX], ry = p->ax[SDL_GAMEPAD_AXIS_RIGHTY];
    if (m.repouso) {
      med_analogico_repouso(&m.esq, lx, ly);
      med_analogico_repouso(&m.dir, rx, ry);
    } else {
      med_analogico_amostra(&m.esq, lx, ly);
      med_analogico_amostra(&m.dir, rx, ry);
    }
    float tl = p->ax[SDL_GAMEPAD_AXIS_LEFT_TRIGGER], tr = p->ax[SDL_GAMEPAD_AXIS_RIGHT_TRIGGER];
    med_gatilho_amostra(&m.l2, tl);
    med_gatilho_amostra(&m.r2, tr);
    bool baixo[2] = {p->dedo[0].baixo, p->dedo[1].baixo};
    float x[2] = {p->dedo[0].x, p->dedo[1].x}, y[2] = {p->dedo[0].y, p->dedo[1].y};
    med_toque_amostra(&m.toque, baixo, x, y);
    if (::pad_apertou(p, SDL_GAMEPAD_BUTTON_TOUCHPAD)) {
      med_toque_clique(&m.toque);
      if (!m.marcou_clique) {
        m.marcou_clique = true;
        marco(l, "toque", "o clique do touchpad chegou");
      }
    }
    if ((baixo[0] || baixo[1]) && !m.marcou_toque) {
      m.marcou_toque = true;
      marco(l, "toque", "o primeiro dedo chegou");
    }
    if (baixo[0] && baixo[1] && !m.marcou_dois) {
      m.marcou_dois = true;
      marco(l, "toque", "dois dedos ao mesmo tempo");
    }
    med_sensores_amostra(&m.sensores, p->giro, p->acel);
    if (m.carga_ativa) {
      /* as amostras de giroscópio que chegaram neste quadro de partida */
      uint64_t total = p->taxa_giro.total;
      med_carga_quadro(&m.carga, (long)(total - m.carga_giro_ult), FORJA->dt);
      m.carga_giro_ult = total;
    }
    if (!m.repouso && (std::hypot(lx, ly) > 0.5f || std::hypot(rx, ry) > 0.5f))
      atividade = true;
    if (tl > 0.2f || tr > 0.2f || baixo[0] || baixo[1])
      atividade = true;
    if (std::fabs(p->giro[0]) + std::fabs(p->giro[1]) + std::fabs(p->giro[2]) > 0.5f)
      atividade = true;
    if (atividade)
      m.mexeu = true;
  }
}

Dictionary ForjaControles::med_estado(int lugar) const {
  Dictionary d;
  if (!lugar_valido(lugar))
    return d;
  const MedidaLugar &m = g_med[lugar];
  d["ativa"] = m.ativa;
  d["mexeu"] = m.mexeu;
  d["setores_l"] = (int)m.esq.setores;
  d["setores_r"] = (int)m.dir.setores;
  d["niveis_l2"] = med_gatilho_niveis(&m.l2);
  d["niveis_r2"] = med_gatilho_niveis(&m.r2);
  d["dedos"] = m.toque.max_dedos;
  d["abertura"] = m.toque.abertura_max;
  d["g_pico"] = m.sensores.g_pico;
  d["marteladas"] = m.sensores.marteladas;
  d["g_parado"] = med_sensores_g_parado(&m.sensores);
  return d;
}

Dictionary ForjaControles::med_veredito(int lugar, const String &chave, int nivel) {
  Dictionary d;
  if (!aberto_ || !lugar_valido(lugar))
    return d;
  CharString c = chave.utf8();
  int f = catalogo_feature_por_chave(c.get_data());
  if (f < 0)
    return d;
  MedidaLugar &m = g_med[lugar];
  Pad *p = pads_do_slot(FORJA, lugar);
  const char *origem = p ? pad_origem_rotulo(p) : "desconectado";
  Veredito v;
  std::memset(&v, 0, sizeof(v));
  v.resultado = RES_NAO_MEDIDO;
  switch ((Feature)f) {
  case F_BOTOES:
    v = med_botoes_veredito(&m.botoes, m.mexeu);
    break;
  case F_ANALOGICOS:
    v = med_analogicos_veredito(&m.esq, &m.dir, m.mexeu);
    break;
  case F_GATILHOS_ANALOGICOS:
    v = med_gatilhos_veredito(&m.l2, &m.r2, m.mexeu);
    break;
  case F_TOUCH_DOIS_DEDOS:
  case F_TOUCH_CLIQUE:
    if (p && !p->cap_touch) {
      std::snprintf(v.pedido, sizeof(v.pedido), "%s",
                    f == F_TOUCH_CLIQUE ? "carimbar o molde com o clique do touchpad"
                                        : "traçar a runa com um dedo e abrir e fechar o molde com dois");
      std::snprintf(v.medido, sizeof(v.medido), "o controle não publica touchpad");
      std::snprintf(v.obs, sizeof(v.obs), "não medido: o controle chegou sem touchpad (%s)", origem);
    } else {
      v = f == F_TOUCH_CLIQUE ? med_toque_clique_veredito(&m.toque, m.mexeu) : med_toque_dedos_veredito(&m.toque, m.mexeu);
    }
    break;
  case F_GIROSCOPIO:
  case F_ACELEROMETRO:
    if (p) {
      Uint64 agora = pad_agora_ns(FORJA, p);
      bool mesmo = p->id == m.pad_id;
      m.sensores.amostras_giro = m.giro_antes + (mesmo ? p->postura.amostras_giro - m.giro0 : 0);
      m.sensores.amostras_acel = m.acel_antes + (mesmo ? p->postura.amostras_acel - m.acel0 : 0);
      m.sensores.hz_host = taxa_hz_host(&p->taxa_giro, agora, 2.0);
      m.sensores.hz_relogio = taxa_hz_sensor(&p->taxa_giro, agora, 2.0);
      for (int e = 0; e < 2; e++)
        m.sensores.sinal[e] = postura_sinal_contagem(
            m.concorda_antes[e] + (mesmo ? p->postura.concorda[e] - m.concorda0[e] : 0),
            m.discorda_antes[e] + (mesmo ? p->postura.discorda[e] - m.discorda0[e] : 0));
    }
    if (f == F_GIROSCOPIO) {
      v = med_giro_veredito(&m.sensores, m.mexeu);
      if (!m.sensores.tem_giro && p)
        std::snprintf(v.obs, sizeof(v.obs),
                      "não medido: o controle chegou sem giroscópio (%s) — a sala jogou com o analógico", origem);
    } else {
      v = med_acel_veredito(&m.sensores, m.mexeu);
      if (!m.sensores.tem_acel && p)
        std::snprintf(v.obs, sizeof(v.obs),
                      "não medido: o controle chegou sem acelerômetro (%s) — a martelada foi o botão cruz", origem);
    }
    break;
  default:
    return d;
  }
  int n = v.nivel != NIVEL_NENHUM ? (int)v.nivel : nivel;
  veredito(lugar, f, (int)v.resultado, n, txt(v.pedido), txt(v.medido), txt(v.obs));
  d["feature"] = chave;
  d["nome"] = txt(catalogo_feature((Feature)f)->nome);
  d["resultado"] = (int)v.resultado;
  d["rotulo"] = txt(rel_resultado_rotulo(v.resultado));
  d["nivel"] = n;
  d["pedido"] = txt(v.pedido);
  d["medido"] = txt(v.medido);
  d["obs"] = txt(v.obs);
  return d;
}

void ForjaControles::med_zerar_tudo() {
  for (int l = 0; l < MAX_JOGADORES; l++)
    g_med[l] = MedidaLugar();
}

/* Um som da forja pelo nome da receita, com os parâmetros dela (os que
 * faltarem ficam no padrão). Nenhum arquivo de áudio: tudo sai daqui. */
PackedFloat32Array ForjaControles::sintetizar(const String &tipo, const Dictionary &p) const {
  PackedFloat32Array saida;
  auto num = [&](const char *k, double padrao) -> float {
    return p.has(k) ? (float)(double)p[k] : (float)padrao;
  };
  uint32_t semente = (uint32_t)(int64_t)(p.has("semente") ? (int64_t)p["semente"] : 7);
  Onda o = {nullptr, 0};
  int r = -1;
  if (tipo == "bigorna")
    r = sint_bigorna(&o, num("freq", 440), num("dur", 1.2), num("brilho", 0.6), semente);
  else if (tipo == "martelada")
    r = sint_martelada(&o, num("freq", 220), semente);
  else if (tipo == "blip")
    r = sint_blip(&o, num("freq", 1200), num("dur", 0.06));
  else if (tipo == "acorde") {
    float freqs[8] = {523.25f, 659.25f, 783.99f};
    int n = 3;
    if (p.has("freqs")) {
      Array a = p["freqs"];
      n = 0;
      for (int i = 0; i < a.size() && i < 8; i++)
        freqs[n++] = (float)(double)a[i];
    }
    r = sint_acorde(&o, freqs, n, num("espaco", 0.08), num("dur_nota", 0.4));
  } else if (tipo == "fogo")
    r = sint_fogo(&o, num("dur", 4.0), semente);
  else if (tipo == "drone")
    r = sint_drone(&o, num("dur", 6.0));
  else if (tipo == "sopro")
    r = sint_sopro(&o, num("dur", 0.7), semente);
  else if (tipo == "tom")
    r = sint_tom(&o, num("freq", 440), num("dur", 0.3), num("rampa", 0.01));
  else if (tipo == "pulso")
    r = sint_pulso(&o, num("freq", 60), num("dur", 0.3), (int)num("batidas", 2), num("intervalo", 0.12));
  else if (tipo == "textura")
    r = sint_textura(&o, num("dur", 1.0), num("aspereza", 0.5), semente);
  else if (tipo == "passo")
    r = sint_passo(&o, (int)num("chao", 0), semente);
  else if (tipo == "grito")
    r = sint_grito(&o, num("dur", 1.2), semente);
  else if (tipo == "trilha")
    r = sint_trilha(&o, num("tonica", 57), num("bpm", 100), (int)num("energia", 1), semente);
  if (r == 0 && o.a && o.n > 0) {
    saida.resize(o.n);
    std::memcpy(saida.ptrw(), o.a, sizeof(float) * (size_t)o.n);
  }
  onda_liberar(&o);
  return saida;
}

PackedByteArray ForjaControles::sintetizar_pcm16(const String &tipo, const Dictionary &p) const {
  PackedFloat32Array f = sintetizar(tipo, p);
  PackedByteArray b;
  b.resize(f.size() * 2);
  const float *src = f.ptr();
  uint8_t *dst = b.ptrw();
  for (int64_t i = 0; i < f.size(); i++) {
    float v = src[i] < -1.0f ? -1.0f : (src[i] > 1.0f ? 1.0f : src[i]);
    int16_t s16 = (int16_t)std::lround(v * 32767.0f);
    dst[i * 2] = (uint8_t)(s16 & 0xFF);
    dst[i * 2 + 1] = (uint8_t)((s16 >> 8) & 0xFF);
  }
  return b;
}

/* ---------- A Prova: a carga ---------- */

/* A partida começou: daqui em diante, cada quadro conta as amostras de
 * giroscópio que chegaram (o buraco maior, as paradas de mais de 1 s). */
bool ForjaControles::carga_comecar(int lugar) {
  if (!aberto_ || !lugar_valido(lugar))
    return false;
  MedidaLugar &m = g_med[lugar];
  Pad *p = pads_do_slot(FORJA, lugar);
  med_carga_zerar(&m.carga, p && p->cap_giro);
  m.carga_giro_ult = p ? p->taxa_giro.total : 0;
  m.carga_ativa = p != nullptr;
  return m.carga_ativa;
}

void ForjaControles::carga_parar(int lugar) {
  if (lugar_valido(lugar))
    g_med[lugar].carga_ativa = false;
}

/* Uma saída mandada no meio da carga: o SDL aceitou? */
void ForjaControles::carga_saida(int lugar, bool ok) {
  if (!lugar_valido(lugar))
    return;
  MedCarga &c = g_med[lugar].carga;
  c.saidas++;
  if (!ok)
    c.recusadas++;
}

void ForjaControles::carga_placar(int lugar, int tiros, int acertos, int derrubadas) {
  if (!lugar_valido(lugar))
    return;
  MedCarga &c = g_med[lugar].carga;
  c.tiros = tiros;
  c.acertos = acertos;
  c.derrubadas = derrubadas;
}

Dictionary ForjaControles::carga_estado(int lugar) const {
  Dictionary d;
  if (!lugar_valido(lugar))
    return d;
  const MedCarga &c = g_med[lugar].carga;
  d["segundos"] = c.segundos;
  d["amostras_giro"] = (int64_t)c.amostras_giro;
  d["maior_parada"] = c.maior_parada;
  d["paradas"] = c.paradas;
  d["saidas"] = c.saidas;
  d["recusadas"] = c.recusadas;
  return d;
}

/* O veredito de "tudo junto": a carga da partida e a prova final às cegas
 * (as luzinhas e a cor), pela régua de cegas.c. */
Dictionary ForjaControles::carga_veredito(int lugar, const Dictionary &leds, const Dictionary &cor, bool mexeu) {
  Dictionary d;
  if (!aberto_ || !lugar_valido(lugar))
    return d;
  MedidaLugar &m = g_med[lugar];
  m.carga_ativa = false;
  Cega cl = forja_interno::cega_de(leds), cc = forja_interno::cega_de(cor);
  Veredito v = cega_tudo_junto_veredito(&m.carga, &cl, &cc, mexeu || m.mexeu);
  forja_interno::explica_recusa(lugar, &v);
  int n = v.nivel != NIVEL_NENHUM ? (int)v.nivel : (int)NIVEL_SAIU;
  veredito(lugar, F_TUDO_JUNTO, (int)v.resultado, n, txt(v.pedido), txt(v.medido), txt(v.obs));
  d["feature"] = "tudo_junto";
  d["nome"] = txt(catalogo_feature(F_TUDO_JUNTO)->nome);
  d["resultado"] = (int)v.resultado;
  d["rotulo"] = txt(rel_resultado_rotulo(v.resultado));
  d["nivel"] = n;
  d["pedido"] = txt(v.pedido);
  d["medido"] = txt(v.medido);
  d["obs"] = txt(v.obs);
  return d;
}
