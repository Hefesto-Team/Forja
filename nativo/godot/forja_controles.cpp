/* ForjaControles. Ver forja_controles.h. */
#include "forja_controles.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

extern "C" {
#include "catalogo.h"
#include "forja.h"
#include "mascara.h"
#include "origem.h"
#include "pads.h"
#include "relatorio.h"
#include "simulador.h"
}

#include <cstdio>
#include <cstring>

using namespace godot;

namespace {

/* A sessão do módulo: uma só por processo, como o SDL. */
Forja g_forja;

String texto(const char *s) { return String::utf8(s ? s : ""); }

Pad *pad_por_indice(int i) {
  if (!FORJA || i < 0 || i >= MAX_PADS || !FORJA->pads.pad[i].usado)
    return nullptr;
  return &FORJA->pads.pad[i];
}

Pad *pad_por_lugar(int lugar) { return FORJA ? pads_do_slot(FORJA, lugar) : nullptr; }

bool botao_valido(int b) { return b >= 0 && b < SDL_GAMEPAD_BUTTON_COUNT; }

Color cor(SDL_Color c) { return Color(c.r / 255.0f, c.g / 255.0f, c.b / 255.0f, 1.0f); }

const char *conexao_curta(const Pad *p) {
  if (p->simulado)
    return "simulado";
  switch (p->origem.conexao) {
  case CONEXAO_USB:
    return "USB";
  case CONEXAO_BT:
    return "BT";
  case CONEXAO_VIRTUAL_USB:
    return "declara USB";
  default:
    return "virtual";
  }
}

Dictionary info_do_pad(int i, const Pad *p) {
  Dictionary d;
  d["pad"] = i;
  d["nome"] = texto(p->nome);
  d["vidpid"] = texto(p->vidpid);
  d["conexao"] = texto(conexao_rotulo(p->origem.conexao));
  d["conexao_curta"] = texto(conexao_curta(p));
  d["origem"] = texto(pad_origem_rotulo(p));
  d["origem_curta"] = texto(p->simulado ? "SDL virtual" : origem_rotulo_curto(p->origem.tipo));
  d["evidencia"] = texto(p->origem.evidencia);
  d["eh_dualsense"] = origem_eh_dualsense(p->origem.tipo) != 0;
  d["virtual"] = p->simulado || origem_eh_virtual(p->origem.tipo) != 0;
  d["simulado"] = p->simulado;
  d["lugar"] = p->slot;
  d["espelho_de"] = p->espelho_de;
  d["bateria"] = p->bateria;
  d["carregando"] = p->energia == SDL_POWERSTATE_CHARGING;
  d["efeitos"] = p->cap_efeitos;
  d["giro"] = p->cap_giro;
  d["acel"] = p->cap_acel;
  d["toque"] = p->cap_touch;
  d["vibracao"] = p->cap_rumble;
  d["luz"] = p->cap_rgb;
  d["giro_hz_declarado"] = p->giro_hz_declarado;
  d["cru"] = p->cru_ok;
  /* o DualSense nativo no rádio, com o contrato estrito, entra só com a
   * entrada: este jogo não monta o 0x31 */
  d["so_entrada"] = FORJA && FORJA->pads.contrato_estrito && p->origem.conexao == CONEXAO_BT &&
                    origem_eh_dualsense(p->origem.tipo);
  return d;
}

} // namespace

ForjaControles::~ForjaControles() { fechar(); }

/* ---------- a sessão ---------- */

bool ForjaControles::abrir(const String &pasta, int simular, bool robo, int64_t semente) {
  if (aberto_)
    return true;
  if (FORJA) {
    UtilityFunctions::push_error("ForjaControles: já existe uma sessão aberta neste processo");
    return false;
  }
  CharString p = pasta.utf8();
  aberto_ = forja_abrir(&g_forja, p.get_data(), simular, robo, (unsigned long long)semente);
  set_process(aberto_);
  return aberto_;
}

void ForjaControles::fechar() {
  if (!aberto_)
    return;
  aberto_ = false;
  set_process(false);
  forja_fechar(&g_forja);
}

bool ForjaControles::simular(int n) { return aberto_ && forja_simular(&g_forja, n); }

void ForjaControles::_process(double delta) {
  if (!aberto_ || Engine::get_singleton()->is_editor_hint())
    return;
  forja_quadro(&g_forja, (float)delta);
  if (g_forja.relatorio_sujo) {
    /* grava de vez em quando, não a cada veredito */
    static double desde = 0;
    desde += delta;
    if (desde > 2.0) {
      desde = 0;
      forja_salvar_relatorio(&g_forja);
    }
  }
}

void ForjaControles::_exit_tree() { fechar(); }

String ForjaControles::versao() const { return texto(aberto_ ? g_forja.rel.versao : FORJA_VERSAO); }
String ForjaControles::pasta_relatorios() const { return texto(aberto_ ? g_forja.pasta_relatorios : ""); }
String ForjaControles::sessao() const { return texto(aberto_ ? g_forja.base_arquivos : ""); }
int64_t ForjaControles::semente() const { return aberto_ ? (int64_t)g_forja.semente : 0; }
bool ForjaControles::simulado() const { return aberto_ && g_forja.simular > 0; }
bool ForjaControles::contrato_estrito() const { return aberto_ && g_forja.pads.contrato_estrito; }
int ForjaControles::aviso_seq() const { return aberto_ ? g_forja.aviso_seq : 0; }
String ForjaControles::aviso() const { return texto(aberto_ ? g_forja.aviso : ""); }

void ForjaControles::intensidade(float v) {
  if (aberto_)
    g_forja.intensidade = v < 0 ? 0 : (v > 1 ? 1 : v);
}

/* ---------- os controles e os lugares ---------- */

int ForjaControles::conectados() const { return aberto_ ? pads_conectados(FORJA) : 0; }
int ForjaControles::jogadores() const { return aberto_ ? pads_jogadores(FORJA) : 0; }

Array ForjaControles::pads() const {
  Array a;
  for (int i = 0; aberto_ && i < MAX_PADS; i++) {
    const Pad *p = pad_por_indice(i);
    if (p)
      a.append(info_do_pad(i, p));
  }
  return a;
}

Dictionary ForjaControles::pad(int indice) const {
  const Pad *p = pad_por_indice(indice);
  return p ? info_do_pad(indice, p) : Dictionary();
}

int ForjaControles::pad_do_lugar(int lugar) const {
  const Pad *p = pad_por_lugar(lugar);
  return p ? (int)(p - FORJA->pads.pad) : -1;
}

Dictionary ForjaControles::lugar(int lugar) const {
  Dictionary d;
  if (!aberto_ || lugar < 0 || lugar >= MAX_JOGADORES)
    return d;
  const Slot *sl = &g_forja.pads.slot[lugar];
  d["lugar"] = lugar;
  d["rotulo"] = texto(pads_rotulo_slot(lugar));
  d["ocupado"] = sl->ocupado;
  d["conectado"] = pad_por_lugar(lugar) != nullptr;
  d["pad"] = pad_do_lugar(lugar);
  d["desconectado_ha"] = sl->ocupado && sl->pad < 0 && sl->desconectado_em > 0 ? g_forja.t - sl->desconectado_em : 0.0;
  d["reconexoes"] = sl->reconexoes;
  d["cor"] = cor(LUZ_DO_LUGAR[lugar]);
  d["leds"] = (int)forja_leds_do_jogador(lugar);
  return d;
}

int ForjaControles::entrar(int indice) { return aberto_ ? pads_entrar(FORJA, indice) : -1; }
void ForjaControles::sair(int lugar) {
  if (aberto_)
    pads_sair(FORJA, lugar);
}

/* ---------- a entrada ---------- */

bool ForjaControles::pad_apertou(int indice, int botao) const {
  const Pad *p = pad_por_indice(indice);
  return p && botao_valido(botao) && ::pad_apertou(p, (SDL_GamepadButton)botao);
}

bool ForjaControles::pad_segura(int indice, int botao) const {
  const Pad *p = pad_por_indice(indice);
  return p && botao_valido(botao) && ::pad_segura(p, (SDL_GamepadButton)botao);
}

bool ForjaControles::apertou(int lugar, int botao) const {
  const Pad *p = pad_por_lugar(lugar);
  return p && botao_valido(botao) && ::pad_apertou(p, (SDL_GamepadButton)botao);
}

bool ForjaControles::soltou(int lugar, int botao) const {
  const Pad *p = pad_por_lugar(lugar);
  return p && botao_valido(botao) && ::pad_soltou(p, (SDL_GamepadButton)botao);
}

bool ForjaControles::segura(int lugar, int botao) const {
  const Pad *p = pad_por_lugar(lugar);
  return p && botao_valido(botao) && ::pad_segura(p, (SDL_GamepadButton)botao);
}

float ForjaControles::eixo(int lugar, int eixo) const {
  const Pad *p = pad_por_lugar(lugar);
  if (!p || eixo < 0 || eixo >= SDL_GAMEPAD_AXIS_COUNT)
    return 0;
  float v = p->ax[eixo];
  /* os gatilhos chegam de 0 a 1 */
  if (eixo == SDL_GAMEPAD_AXIS_LEFT_TRIGGER || eixo == SDL_GAMEPAD_AXIS_RIGHT_TRIGGER)
    v = v < 0 ? 0 : v;
  return v;
}

Vector3 ForjaControles::giro(int lugar) const {
  const Pad *p = pad_por_lugar(lugar);
  return p ? Vector3(p->giro[0], p->giro[1], p->giro[2]) : Vector3();
}

Vector3 ForjaControles::acel(int lugar) const {
  const Pad *p = pad_por_lugar(lugar);
  return p ? Vector3(p->acel[0], p->acel[1], p->acel[2]) : Vector3();
}

Vector3 ForjaControles::dedo(int lugar, int i) const {
  const Pad *p = pad_por_lugar(lugar);
  if (!p || i < 0 || i > 1)
    return Vector3();
  return Vector3(p->dedo[i].x, p->dedo[i].y, p->dedo[i].baixo ? 1.0f : 0.0f);
}

Vector2 ForjaControles::postura(int lugar) const {
  const Pad *p = pad_por_lugar(lugar);
  return p ? Vector2(p->postura.rolagem, p->postura.arfagem) : Vector2();
}

float ForjaControles::giro_hz(int lugar) const {
  const Pad *p = pad_por_lugar(lugar);
  return p ? (float)taxa_hz_host(&p->taxa_giro, SDL_GetTicksNS(), 2.0) : 0.0f;
}

int ForjaControles::status_cru(int lugar) const {
  const Pad *p = pad_por_lugar(lugar);
  return p && p->cru_ok ? p->status53 : -1;
}

/* ---------- as saídas ---------- */

bool ForjaControles::vibrar(int lugar, float forte, float fraco, int ms) {
  Pad *p = pad_por_lugar(lugar);
  return p && pad_rumble(FORJA, p, forte, fraco, ms);
}

bool ForjaControles::luz(int lugar, const Color &c) {
  Pad *p = pad_por_lugar(lugar);
  if (!p)
    return false;
  SDL_Color s = {(Uint8)(c.r * 255.0f + 0.5f), (Uint8)(c.g * 255.0f + 0.5f), (Uint8)(c.b * 255.0f + 0.5f), 255};
  return pad_luz(FORJA, p, s);
}

bool ForjaControles::luz_do_lugar(int lugar) {
  Pad *p = pad_por_lugar(lugar);
  return p && pad_luz_do_slot(FORJA, p);
}

bool ForjaControles::gatilho(int lugar, int lado, int modo, int a, int b, int c) {
  Pad *p = pad_por_lugar(lugar);
  if (!p)
    return false;
  /* só os quatro modos oficiais (isteamdualsense.h) */
  if (modo < FORJA_TRIGGER_OFF || modo > FORJA_TRIGGER_VIBRATION)
    return false;
  ForjaTrigger t = {(ForjaTriggerMode)modo, (uint8_t)a, (uint8_t)b, (uint8_t)c};
  return pad_gatilho(FORJA, p, lado ? 1 : 0, t);
}

bool ForjaControles::gatilhos_off(int lugar) {
  Pad *p = pad_por_lugar(lugar);
  return p && pad_gatilhos_off(FORJA, p);
}

bool ForjaControles::led_mic(int lugar, int modo) {
  Pad *p = pad_por_lugar(lugar);
  return p && pad_led_mic(FORJA, p, modo);
}

bool ForjaControles::leds_jogador(int lugar, int mascara) {
  Pad *p = pad_por_lugar(lugar);
  return p && pad_leds_jogador(FORJA, p, mascara);
}

bool ForjaControles::leds_do_lugar(int lugar) {
  Pad *p = pad_por_lugar(lugar);
  return p && pad_leds_do_slot(FORJA, p);
}

bool ForjaControles::alto_falante(int lugar, int volume, int rota, int preamp) {
  Pad *p = pad_por_lugar(lugar);
  return p && pad_alto_falante(FORJA, p, volume, rota, preamp);
}

void ForjaControles::silencio(int lugar) {
  if (aberto_)
    pads_silencio(FORJA, lugar);
}

void ForjaControles::silencio_todos() {
  if (aberto_)
    pads_silencio_todos(FORJA);
}

PackedStringArray ForjaControles::saidas(int lugar) const {
  PackedStringArray a;
  const Pad *p = pad_por_lugar(lugar);
  if (!p)
    return a;
  for (int k = 0; k < PAD_ANEL_SAIDAS; k++) {
    int i = (p->saidas_prox - 1 - k + PAD_ANEL_SAIDAS * 2) % PAD_ANEL_SAIDAS;
    if (!p->saidas[i][0])
      break;
    char linha[160];
    snprintf(linha, sizeof(linha), "%5.1fs  %s", g_forja.t - p->saidas_t[i], p->saidas[i]);
    a.append(texto(linha));
  }
  return a;
}

Dictionary ForjaControles::estado_saida(int lugar) const {
  Dictionary d;
  const Pad *p = pad_por_lugar(lugar);
  if (!p)
    return d;
  bool vibrando = p->rumble_ate_ms != 0;
  d["forte"] = vibrando ? p->rumble_baixo / 65535.0f : 0.0f;
  d["fraco"] = vibrando ? p->rumble_alto / 65535.0f : 0.0f;
  d["luz"] = cor(p->luz);
  d["l2"] = (int)p->modo_l2;
  d["r2"] = (int)p->modo_r2;
  d["led_mic"] = p->led_mic;
  d["leds_jogador"] = p->leds_jogador;
  return d;
}

Color ForjaControles::cor_do_lugar(int lugar) const {
  if (lugar < 0 || lugar >= MAX_JOGADORES)
    return Color(0.5f, 0.5f, 0.5f);
  return cor(LUZ_DO_LUGAR[lugar]);
}

/* ---------- o relatório ---------- */

Array ForjaControles::salas() const {
  Array a;
  for (int s = 0; s < SALA_TOTAL; s++) {
    const InfoSala *inf = catalogo_sala((Sala)s);
    Dictionary d;
    d["id"] = s;
    d["chave"] = texto(inf->chave);
    d["nome"] = texto(inf->nome);
    d["padrao"] = texto(inf->padrao);
    d["acao"] = texto(inf->acao);
    d["familia"] = (int)inf->familia;
    a.append(d);
  }
  return a;
}

Array ForjaControles::features() const {
  Array a;
  for (int f = 0; f < F_TOTAL; f++) {
    const InfoFeature *inf = catalogo_feature((Feature)f);
    Dictionary d;
    d["id"] = f;
    d["chave"] = texto(inf->chave);
    d["nome"] = texto(inf->nome);
    d["sala"] = (int)inf->sala;
    d["sala_nome"] = texto(catalogo_sala(inf->sala)->nome);
    a.append(d);
  }
  return a;
}

void ForjaControles::nota(const String &t) {
  if (!aberto_)
    return;
  CharString s = t.utf8();
  rel_nota(&g_forja.rel, s.get_data());
  forja_relatorio_mudou(&g_forja);
}

void ForjaControles::veredito(int lugar, int feature, int resultado, int nivel, const String &pedido,
                              const String &medido, const String &obs) {
  if (!aberto_ || lugar < 0 || lugar >= MAX_JOGADORES || feature < 0 || feature >= F_TOTAL)
    return;
  CharString pe = pedido.utf8(), me = medido.utf8(), ob = obs.utf8();
  RelItem *it = rel_registrar(&g_forja.rel, lugar + 1, (Feature)feature, (Resultado)resultado, (NivelEvidencia)nivel,
                              pe.get_data(), me.get_data(), ob.get_data(), forja_agora(&g_forja));
  if (!it)
    return;
  const InfoFeature *inf = catalogo_feature((Feature)feature);
  Evento ev;
  ev_iniciar(&ev, &g_forja.lt, "veredito", lugar + 1);
  ev_str(&ev, "feature", inf->chave);
  ev_str(&ev, "resultado", rel_resultado_rotulo((Resultado)resultado));
  ev_str(&ev, "nivel", rel_nivel_rotulo((NivelEvidencia)nivel));
  ev_str(&ev, "medido", it->medido);
  ev_fim(&ev, &g_forja.lt);
  reg_linha(&g_forja.reg, "%s · %s: %s — %s", pads_rotulo_slot(lugar), inf->nome,
            rel_resultado_rotulo((Resultado)resultado), it->medido);
  forja_relatorio_mudou(&g_forja);
}

Dictionary ForjaControles::ultimo_veredito(int lugar, int feature) const {
  Dictionary d;
  if (!aberto_ || feature < 0 || feature >= F_TOTAL)
    return d;
  const RelItem *it = rel_ultimo(&g_forja.rel, lugar + 1, (Feature)feature);
  if (!it)
    return d;
  d["resultado"] = (int)it->resultado;
  d["rotulo"] = texto(rel_resultado_rotulo(it->resultado));
  d["nivel"] = (int)it->nivel;
  d["pedido"] = texto(it->pedido);
  d["medido"] = texto(it->medido);
  d["obs"] = texto(it->observacao);
  d["t"] = it->t;
  return d;
}

Dictionary ForjaControles::controle_do_relatorio(int lugar) const {
  Dictionary d;
  if (!aberto_ || lugar < 0 || lugar >= REL_MAX_CONTROLES)
    return d;
  const RelControle *c = &g_forja.rel.controles[lugar];
  if (!c->presente)
    return d;
  d["nome"] = texto(c->nome);
  d["vid_pid"] = texto(c->vid_pid);
  d["conexao"] = texto(c->conexao);
  d["origem"] = texto(c->origem);
  d["evidencia"] = texto(c->evidencia);
  d["bateria"] = texto(c->bateria);
  d["giro_declarado_hz"] = c->giro_declarado_hz;
  d["giro_medido_hz"] = c->giro_medido_hz;
  d["reconexoes"] = c->reconexoes;
  return d;
}

bool ForjaControles::gravar_relatorio() { return aberto_ && forja_salvar_relatorio(&g_forja); }

void ForjaControles::registrar(const String &linha) {
  if (!aberto_)
    return;
  CharString s = linha.utf8();
  reg_linha(&g_forja.reg, "%s", s.get_data());
}

void ForjaControles::evento(const String &tipo, int jogador, const Dictionary &campos) {
  if (!aberto_)
    return;
  CharString t = tipo.utf8();
  Evento ev;
  ev_iniciar(&ev, &g_forja.lt, t.get_data(), jogador);
  Array chaves = campos.keys();
  for (int i = 0; i < chaves.size(); i++) {
    CharString k = String(chaves[i]).utf8();
    Variant v = campos[chaves[i]];
    switch (v.get_type()) {
    case Variant::BOOL:
      ev_bool(&ev, k.get_data(), (bool)v);
      break;
    case Variant::INT:
      ev_int(&ev, k.get_data(), (long)(int64_t)v);
      break;
    case Variant::FLOAT:
      ev_num(&ev, k.get_data(), (double)v);
      break;
    default: {
      CharString s = String(v).utf8();
      ev_str(&ev, k.get_data(), s.get_data());
    }
    }
  }
  ev_fim(&ev, &g_forja.lt);
}

PackedStringArray ForjaControles::registro_recente(int n) const {
  PackedStringArray a;
  for (int i = 0; aberto_ && i < n; i++) {
    const char *l = reg_recente(&g_forja.reg, i);
    if (!l)
      break;
    a.append(texto(l));
  }
  return a;
}

/* ---------- o simulador e o robô ---------- */

void ForjaControles::em_sala(bool v) {
  if (aberto_)
    g_forja.em_sala = v;
}

String ForjaControles::defeitos(const String &lista) {
  char erro[160] = "";
  CharString s = lista.utf8();
  if (!simulador_defeitos(s.get_data(), erro, sizeof(erro)))
    return texto(erro);
  return String();
}

void ForjaControles::simulador_selecionar(int sim) { ::simulador_selecionar(sim); }
void ForjaControles::simulador_botao(int sim, int botao, bool baixo) { simulador_manual_botao(sim, botao, baixo); }
void ForjaControles::simulador_eixo(int sim, int eixo, float v) { simulador_manual_eixo(sim, eixo, v); }
void ForjaControles::simulador_giro(int sim, const Vector3 &g) { simulador_manual_giro(sim, g.x, g.y, g.z); }
void ForjaControles::simulador_dedo(int sim, int dedo, bool baixo, float x, float y) {
  simulador_manual_dedo(sim, dedo, baixo, x, y);
}

void ForjaControles::robo_apertar(int indice, int botao, float s) {
  if (aberto_ && botao_valido(botao))
    ::robo_apertar(FORJA, indice, (SDL_GamepadButton)botao, s);
}

void ForjaControles::robo_eixo(int indice, int eixo, float v, float s) {
  if (aberto_ && eixo >= 0 && eixo < SDL_GAMEPAD_AXIS_COUNT)
    ::robo_eixo(FORJA, indice, (SDL_GamepadAxis)eixo, v, s);
}

void ForjaControles::robo_girar(int indice, const Vector3 &g, float s) {
  if (aberto_)
    ::robo_girar(FORJA, indice, g.x, g.y, g.z, s);
}

void ForjaControles::robo_sacudir(int indice, float g, float s) {
  if (aberto_)
    ::robo_sacudir(FORJA, indice, g, s);
}

void ForjaControles::robo_tocar(int indice, int dedo, float x, float y, float s) {
  if (aberto_)
    ::robo_tocar(FORJA, indice, dedo, x, y, s);
}

Dictionary ForjaControles::percepcao(int indice) const {
  Dictionary d;
  const Pad *p = pad_por_indice(indice);
  if (!p)
    return d;
  const Percepcao *pe = simulador_percepcao(p->id);
  if (!pe)
    return d;
  d["forte"] = pe->forte;
  d["fraco"] = pe->fraco;
  d["luz"] = Color(pe->luz_r / 255.0f, pe->luz_g / 255.0f, pe->luz_b / 255.0f);
  d["player_index"] = pe->player_index;
  d["led_mic"] = pe->led_mic;
  d["leds_jogador"] = pe->leds_jogador;
  d["gatilho_esq"] = (int)pe->gatilho_esq[0];
  d["gatilho_dir"] = (int)pe->gatilho_dir[0];
  return d;
}

/* ---------- o que o GDScript vê ---------- */

#define METODO(nome, ...) ClassDB::bind_method(D_METHOD(#nome, ##__VA_ARGS__), &ForjaControles::nome)
#define CONSTANTE(nome, valor) ClassDB::bind_integer_constant(get_class_static(), "", nome, valor)

void ForjaControles::_bind_methods() {
  METODO(abrir, "pasta", "simular", "robo", "semente");
  METODO(fechar);
  METODO(simular, "n");
  METODO(aberto);
  METODO(versao);
  METODO(pasta_relatorios);
  METODO(sessao);
  METODO(semente);
  METODO(simulado);
  METODO(contrato_estrito);
  METODO(aviso_seq);
  METODO(aviso);
  METODO(intensidade, "valor");

  METODO(conectados);
  METODO(jogadores);
  METODO(pads);
  METODO(pad, "indice");
  METODO(pad_do_lugar, "lugar");
  METODO(lugar, "lugar");
  METODO(entrar, "indice");
  METODO(sair, "lugar");

  METODO(pad_apertou, "indice", "botao");
  METODO(pad_segura, "indice", "botao");
  METODO(apertou, "lugar", "botao");
  METODO(soltou, "lugar", "botao");
  METODO(segura, "lugar", "botao");
  METODO(eixo, "lugar", "eixo");
  METODO(giro, "lugar");
  METODO(acel, "lugar");
  METODO(dedo, "lugar", "i");
  METODO(postura, "lugar");
  METODO(giro_hz, "lugar");
  METODO(status_cru, "lugar");

  METODO(vibrar, "lugar", "forte", "fraco", "ms");
  METODO(luz, "lugar", "cor");
  METODO(luz_do_lugar, "lugar");
  METODO(gatilho, "lugar", "lado", "modo", "a", "b", "c");
  METODO(gatilhos_off, "lugar");
  METODO(led_mic, "lugar", "modo");
  METODO(leds_jogador, "lugar", "mascara");
  METODO(leds_do_lugar, "lugar");
  METODO(alto_falante, "lugar", "volume", "rota", "preamp");
  METODO(silencio, "lugar");
  METODO(silencio_todos);
  METODO(saidas, "lugar");
  METODO(estado_saida, "lugar");
  METODO(cor_do_lugar, "lugar");

  METODO(salas);
  METODO(features);
  METODO(nota, "texto");
  METODO(veredito, "lugar", "feature", "resultado", "nivel", "pedido", "medido", "obs");
  METODO(ultimo_veredito, "lugar", "feature");
  METODO(controle_do_relatorio, "lugar");
  METODO(gravar_relatorio);
  METODO(registrar, "linha");
  METODO(evento, "tipo", "jogador", "campos");
  METODO(registro_recente, "n");

  METODO(em_sala, "sim");
  METODO(defeitos, "lista");
  METODO(simulador_selecionar, "sim");
  METODO(simulador_botao, "sim", "botao", "baixo");
  METODO(simulador_eixo, "sim", "eixo", "valor");
  METODO(simulador_giro, "sim", "giro");
  METODO(simulador_dedo, "sim", "dedo", "baixo", "x", "y");
  METODO(robo_apertar, "indice", "botao", "segundos");
  METODO(robo_eixo, "indice", "eixo", "valor", "segundos");
  METODO(robo_girar, "indice", "giro", "segundos");
  METODO(robo_sacudir, "indice", "g", "segundos");
  METODO(robo_tocar, "indice", "dedo", "x", "y", "segundos");
  METODO(percepcao, "indice");

  /* os botões, como o SDL3 os numera */
  CONSTANTE("BOTAO_CRUZ", SDL_GAMEPAD_BUTTON_SOUTH);
  CONSTANTE("BOTAO_CIRCULO", SDL_GAMEPAD_BUTTON_EAST);
  CONSTANTE("BOTAO_QUADRADO", SDL_GAMEPAD_BUTTON_WEST);
  CONSTANTE("BOTAO_TRIANGULO", SDL_GAMEPAD_BUTTON_NORTH);
  CONSTANTE("BOTAO_CREATE", SDL_GAMEPAD_BUTTON_BACK);
  CONSTANTE("BOTAO_PS", SDL_GAMEPAD_BUTTON_GUIDE);
  CONSTANTE("BOTAO_OPTIONS", SDL_GAMEPAD_BUTTON_START);
  CONSTANTE("BOTAO_L3", SDL_GAMEPAD_BUTTON_LEFT_STICK);
  CONSTANTE("BOTAO_R3", SDL_GAMEPAD_BUTTON_RIGHT_STICK);
  CONSTANTE("BOTAO_L1", SDL_GAMEPAD_BUTTON_LEFT_SHOULDER);
  CONSTANTE("BOTAO_R1", SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER);
  CONSTANTE("BOTAO_CIMA", SDL_GAMEPAD_BUTTON_DPAD_UP);
  CONSTANTE("BOTAO_BAIXO", SDL_GAMEPAD_BUTTON_DPAD_DOWN);
  CONSTANTE("BOTAO_ESQUERDA", SDL_GAMEPAD_BUTTON_DPAD_LEFT);
  CONSTANTE("BOTAO_DIREITA", SDL_GAMEPAD_BUTTON_DPAD_RIGHT);
  CONSTANTE("BOTAO_MICROFONE", SDL_GAMEPAD_BUTTON_MISC1);
  CONSTANTE("BOTAO_TOUCHPAD", SDL_GAMEPAD_BUTTON_TOUCHPAD);
  /* os eixos */
  CONSTANTE("EIXO_LX", SDL_GAMEPAD_AXIS_LEFTX);
  CONSTANTE("EIXO_LY", SDL_GAMEPAD_AXIS_LEFTY);
  CONSTANTE("EIXO_RX", SDL_GAMEPAD_AXIS_RIGHTX);
  CONSTANTE("EIXO_RY", SDL_GAMEPAD_AXIS_RIGHTY);
  CONSTANTE("EIXO_L2", SDL_GAMEPAD_AXIS_LEFT_TRIGGER);
  CONSTANTE("EIXO_R2", SDL_GAMEPAD_AXIS_RIGHT_TRIGGER);
  /* os quatro modos oficiais de gatilho */
  CONSTANTE("GATILHO_OFF", FORJA_TRIGGER_OFF);
  CONSTANTE("GATILHO_RESISTENCIA", FORJA_TRIGGER_FEEDBACK);
  CONSTANTE("GATILHO_ARMA", FORJA_TRIGGER_WEAPON);
  CONSTANTE("GATILHO_VIBRACAO", FORJA_TRIGGER_VIBRATION);
  /* o veredito e o degrau da evidência */
  CONSTANTE("NAO_MEDIDO", RES_NAO_MEDIDO);
  CONSTANTE("PASSOU", RES_PASSOU);
  CONSTANTE("FALHOU", RES_FALHOU);
  CONSTANTE("NIVEL_MONTOU", NIVEL_MONTOU);
  CONSTANTE("NIVEL_SAIU", NIVEL_SAIU);
  CONSTANTE("NIVEL_OBEDECEU", NIVEL_OBEDECEU);
  CONSTANTE("NIVEL_REAGIU", NIVEL_REAGIU);
  /* o byte 53 do report cru */
  CONSTANTE("CRU_FONE", 1);
  CONSTANTE("CRU_MIC_DO_FONE", 2);
  CONSTANTE("CRU_MUDO", 4);
}
