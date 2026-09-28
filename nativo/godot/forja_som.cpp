/* O som de cada controle, do lado do módulo (som/som_controle.h): o
 * alto-falante, os dois atuadores e o microfone de cada jogador, achados como
 * um jogo os acha e tocados pelo SDL — paralelos ao som da TV, que é do
 * Godot. Os sons que vão ao controle são os da forja, sintetizados aqui
 * (som/sons_salas.h), pelo nome. O veredito do microfone e do botão do mudo
 * sai da régua do núcleo (medidas.h). */
#include "forja_controles.h"

extern "C" {
#include "achar_som.h"
#include "catalogo.h"
#include "chao.h"
#include "forja.h"
#include "medidas.h"
#include "pads.h"
#include "relatorio.h"
#include "simulador.h"
#include "som_controle.h"
#include "sons_salas.h"
}

using namespace godot;

namespace {

String txt(const char *s) { return String::utf8(s ? s : ""); }
bool papel_ok(int papel) { return papel >= 0 && papel < PAPEL_TOTAL; }
bool sim(const Dictionary &d, const char *k, bool padrao) { return d.has(k) ? (bool)d[k] : padrao; }
float real(const Dictionary &d, const char *k) { return d.has(k) ? (float)(double)d[k] : 0.0f; }

/* O som pelo nome ("sino", "passo:2:1"...); vazio é nenhum. */
const Som *som_do_nome(const String &nome) {
  if (nome.is_empty())
    return nullptr;
  CharString c = nome.utf8();
  return sons_salas_por_nome(c.get_data());
}

} // namespace

void ForjaControles::som_preparar(int papel) {
  if (!aberto_)
    return;
  sons_salas();
  somc_preparar(FORJA);
  /* o alto-falante do DualSense no cabo precisa da rota: o canal R para o
   * alto-falante interno, o volume e o pré-amplificador (o que o
   * hid-playstation também escreve quando o fone sai) */
  if (papel != PAPEL_HAPTICA)
    for (int s = 0; s < MAX_JOGADORES; s++) {
      Pad *p = pads_do_slot(FORJA, s);
      if (p && p->cap_efeitos)
        pad_alto_falante(FORJA, p, FORJA_VOL_FALANTE_PADRAO, FORJA_ROTA_FALANTE, FORJA_PREAMP_PADRAO);
    }
}

void ForjaControles::som_encerrar() {
  if (!aberto_)
    return;
  for (int s = 0; s < MAX_JOGADORES; s++)
    somc_parar_tudo(FORJA, s);
  somc_encerrar(FORJA);
}

bool ForjaControles::som_preparado() const { return aberto_ && somc_preparado(); }

bool ForjaControles::som_tem(int lugar, int papel) const {
  return aberto_ && papel_ok(papel) && somc_tem(FORJA, lugar, (PapelSom)papel);
}

bool ForjaControles::som_estereo(int lugar, int papel) const {
  return aberto_ && papel_ok(papel) && somc_estereo(FORJA, lugar, (PapelSom)papel);
}

String ForjaControles::som_nome(int lugar, int papel) const {
  return aberto_ && papel_ok(papel) ? txt(somc_nome(FORJA, lugar, (PapelSom)papel)) : String();
}

String ForjaControles::som_como(int lugar, int papel) const {
  return aberto_ && papel_ok(papel) ? txt(achar_como_rotulo(somc_como(FORJA, lugar, (PapelSom)papel))) : String();
}

String ForjaControles::som_plataforma() const { return aberto_ ? txt(somc_plataforma()) : String(); }

void ForjaControles::som_trocar(int lugar, int papel, int direcao) {
  if (aberto_ && papel_ok(papel))
    somc_trocar(FORJA, lugar, (PapelSom)papel, direcao < 0 ? -1 : 1);
}

int ForjaControles::som_falante(int lugar, const String &som, float ganho) {
  return aberto_ ? somc_falante(FORJA, lugar, som_do_nome(som), ganho) : -1;
}

int ForjaControles::som_haptica(int lugar, const String &esq, const String &dir, float ganho) {
  if (!aberto_)
    return -1;
  return somc_haptica(FORJA, lugar, som_do_nome(esq), som_do_nome(dir), ganho);
}

void ForjaControles::som_parar(int lugar) {
  if (aberto_)
    somc_parar_tudo(FORJA, lugar);
}

Dictionary ForjaControles::som_mic(int lugar) const {
  Dictionary d;
  if (!aberto_)
    return d;
  d["nivel"] = somc_mic_nivel(FORJA, lugar);
  d["pico"] = somc_mic_pico(FORJA, lugar);
  d["quadros"] = (int64_t)somc_mic_quadros(FORJA, lugar);
  return d;
}

Dictionary ForjaControles::som_virtual(int lugar) const {
  Dictionary d;
  if (!aberto_)
    return d;
  d["falante"] = somc_virtual_falante(FORJA, lugar);
  d["esq"] = somc_virtual_atuador(FORJA, lugar, 0);
  d["dir"] = somc_virtual_atuador(FORJA, lugar, 1);
  return d;
}

void ForjaControles::robo_falar(int indice, float nivel, float s) {
  if (aberto_ && indice >= 0 && indice < MAX_PADS)
    ::robo_falar(FORJA, indice, nivel, s);
}

void ForjaControles::simulador_falar(int sim_, float nivel) { simulador_manual_fala(sim_, nivel); }

int ForjaControles::chao_do_envelope(const PackedFloat32Array &env) const {
  return chao_pelo_envelope(env.ptr(), (int)env.size());
}

/* O microfone e o botão do mudo, pelo que a sala mediu:
 *   {tem, piso, viu_piso, voz, mudo, viu_mudo, apertou_mudo, pediu_mudo,
 *    quadros, mexeu}
 * (os níveis na escala da tela: 0 = -54 dB, 1 = 0 dB). */
Dictionary ForjaControles::mic_veredito(int lugar, const String &chave, const Dictionary &d) {
  Dictionary r;
  if (!aberto_)
    return r;
  MedMic m;
  med_mic_iniciar(&m, sim(d, "tem", false));
  m.piso = real(d, "piso");
  m.viu_piso = sim(d, "viu_piso", false);
  m.voz = real(d, "voz");
  m.mudo = real(d, "mudo");
  m.viu_mudo = sim(d, "viu_mudo", false);
  m.apertou_mudo = sim(d, "apertou_mudo", false);
  m.pediu_mudo = sim(d, "pediu_mudo", false);
  m.quadros = d.has("quadros") ? (long)(int64_t)d["quadros"] : 0;
  bool mexeu = sim(d, "mexeu", true);
  Veredito v;
  Feature f;
  if (chave == "microfone") {
    v = med_mic_veredito(&m, mexeu);
    f = F_MICROFONE;
  } else if (chave == "microfone_mudo") {
    v = med_mudo_veredito(&m, mexeu);
    f = F_MICROFONE_MUDO;
  } else {
    return r;
  }
  /* sem microfone achado, o degrau fica em "nenhum": não se mediu nada */
  int nivel = (int)v.nivel;
  veredito(lugar, f, (int)v.resultado, nivel, txt(v.pedido), txt(v.medido), txt(v.obs));
  r["feature"] = chave;
  r["nome"] = txt(catalogo_feature(f)->nome);
  r["resultado"] = (int)v.resultado;
  r["rotulo"] = txt(rel_resultado_rotulo(v.resultado));
  r["nivel"] = nivel;
  r["pedido"] = txt(v.pedido);
  r["medido"] = txt(v.medido);
  r["obs"] = txt(v.obs);
  return r;
}
