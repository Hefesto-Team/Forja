/* As provas às cegas das salas de saída, do lado do módulo (cegas.h). Uma
 * saída — vibração, cor, gatilho, LED, som — o jogo não mede sozinho: a sala
 * esconde a resposta, pergunta, e guarda o que a pessoa disse (as certas, as
 * erradas e o que ela disse nelas, as perdidas). Aqui sai o veredito, pela
 * régua provada sem aparelho, gravado no relatório no degrau que a prova
 * alcançou (montou, saiu ou obedeceu). Os planos — a ordem dos golpes, das
 * armas, das fontes de som — saem do mesmo sorteio do núcleo. */
#include "forja_controles.h"
#include "forja_interno.h"

extern "C" {
#include "aleatorio.h"
#include "catalogo.h"
#include "cegas.h"
#include "forja.h"
#include "origem.h"
#include "pads.h"
#include "relatorio.h"
}

#include <cstdio>
#include <cstring>

using namespace godot;

namespace {

using forja_interno::cega_de;
using forja_interno::explica_recusa;
using forja_interno::juntar_obs;

bool sim(const Dictionary &d, const char *k, bool padrao) { return d.has(k) ? (bool)d[k] : padrao; }
int num(const Dictionary &d, const char *k) { return d.has(k) ? (int)d[k] : 0; }
String txt(const char *s) { return String::utf8(s ? s : ""); }

} // namespace

Array ForjaControles::cega_plano_tiros(const PackedInt32Array &slots, int por_lado, int64_t semente) const {
  Array saida;
  int s_[MAX_JOGADORES];
  int n = 0;
  for (int i = 0; i < slots.size() && n < MAX_JOGADORES; i++)
    s_[n++] = slots[i];
  Tiro tiros[MAX_JOGADORES * 2 * 16];
  if (por_lado < 0)
    por_lado = 0;
  if (por_lado > 16)
    por_lado = 16;
  Sorteio s;
  sorteio_semear(&s, (uint64_t)semente);
  int k = cegas_plano_tiros(&s, s_, n, por_lado, tiros, (int)(sizeof(tiros) / sizeof(tiros[0])));
  for (int i = 0; i < k; i++)
    saida.append(Vector2i(tiros[i].slot, (int)tiros[i].lado));
  return saida;
}

PackedInt32Array ForjaControles::cega_plano_armas(int vezes, int64_t semente) const {
  PackedInt32Array saida;
  Arma armas[64];
  Sorteio s;
  sorteio_semear(&s, (uint64_t)semente);
  int k = cegas_plano_armas(&s, vezes, armas, 64);
  for (int i = 0; i < k; i++)
    saida.append((int)armas[i]);
  return saida;
}

PackedInt32Array ForjaControles::cega_plano_fontes(const PackedInt32Array &fontes, const PackedInt32Array &vezes,
                                                   int64_t semente) const {
  PackedInt32Array saida;
  int f[16], v[16], out[128];
  int n = 0;
  for (int i = 0; i < fontes.size() && i < vezes.size() && n < 16; i++, n++) {
    f[n] = fontes[i];
    v[n] = vezes[i];
  }
  Sorteio s;
  sorteio_semear(&s, (uint64_t)semente);
  int k = cegas_plano_fontes(&s, f, v, n, out, 128);
  for (int i = 0; i < k; i++)
    saida.append(out[i]);
  return saida;
}

bool ForjaControles::cega_decidida(const String &tipo, const Dictionary &cega) const {
  Cega c = cega_de(cega);
  if (tipo == "cor")
    return cega_cor_decidida(&c);
  if (tipo == "arma")
    return cega_arma_decidida(&c);
  if (tipo == "led_mic")
    return cega_led_mic_decidida(&c);
  return true;
}

/* O veredito de uma feature de saída, pelas respostas guardadas pela sala. Os
 * `dados` de cada uma:
 *   vibracao_forte, vibracao_fraca  {cega, sdl_aceitou, reagiu}
 *   vibracao_isolamento             {fantasmas, chances, vizinhos, proprios}
 *   lightbar, leds_jogador,
 *   led_microfone                   {cega, sdl_aceitou}
 *   gatilho_*                       {cega, nenhuma, sdl_aceitou}
 *   alto_falante                    {cega, fantasmas, chances, tem}
 *   haptica_audio                   {cega (o chão), esq, dir, tem} */
Dictionary ForjaControles::cega_veredito(int lugar, const String &chave, const Dictionary &d) {
  Dictionary r;
  if (!aberto_ || lugar < 0 || lugar >= MAX_JOGADORES)
    return r;
  CharString c = chave.utf8();
  int f = catalogo_feature_por_chave(c.get_data());
  if (f < 0)
    return r;
  Cega cega = cega_de(d.get("cega", Variant()));
  bool aceitou = sim(d, "sdl_aceitou", true);
  Veredito v;
  switch ((Feature)f) {
  case F_VIBRACAO_FORTE:
  case F_VIBRACAO_FRACA:
    v = cega_motor_veredito(&cega, f == F_VIBRACAO_FORTE ? LADO_ESQ : LADO_DIR, aceitou, sim(d, "reagiu", false));
    if (FORJA && FORJA->intensidade < 0.5f) {
      char nota[96];
      std::snprintf(nota, sizeof(nota), "a intensidade da vibração estava em %d%%",
                    (int)(FORJA->intensidade * 100 + 0.5f));
      juntar_obs(&v, nota);
    }
    break;
  case F_VIBRACAO_ISOLAMENTO: {
    Cega proprios = cega_de(d.get("proprios", Variant()));
    v = cega_isolamento_veredito(num(d, "fantasmas"), num(d, "chances"), num(d, "vizinhos"), &proprios);
    break;
  }
  case F_LIGHTBAR:
    v = cega_cor_veredito(&cega, aceitou);
    break;
  case F_GATILHO_RESISTENCIA:
  case F_GATILHO_ARMA:
  case F_GATILHO_VIBRACAO: {
    Cega nenhuma = cega_de(d.get("nenhuma", Variant()));
    Arma a = f == F_GATILHO_RESISTENCIA ? ARMA_ARCO : (f == F_GATILHO_ARMA ? ARMA_PISTOLA : ARMA_METRALHADORA);
    v = cega_arma_veredito(a, &cega, &nenhuma, aceitou);
    break;
  }
  case F_LEDS_JOGADOR:
    v = cega_leds_veredito(&cega, aceitou);
    break;
  case F_LED_MICROFONE:
    v = cega_led_mic_veredito(&cega, aceitou);
    break;
  case F_ALTO_FALANTE:
    v = cega_alto_falante_veredito(&cega, num(d, "fantasmas"), num(d, "chances"), sim(d, "tem", true));
    break;
  case F_HAPTICA_AUDIO: {
    Cega esq = cega_de(d.get("esq", Variant())), dir = cega_de(d.get("dir", Variant()));
    v = cega_haptica_veredito(&cega, &esq, &dir, sim(d, "tem", true));
    break;
  }
  default:
    return r;
  }
  explica_recusa(lugar, &v);
  int nivel = v.nivel != NIVEL_NENHUM ? (int)v.nivel : (int)NIVEL_SAIU;
  veredito(lugar, f, (int)v.resultado, nivel, txt(v.pedido), txt(v.medido), txt(v.obs));
  r["feature"] = chave;
  r["nome"] = txt(catalogo_feature((Feature)f)->nome);
  r["resultado"] = (int)v.resultado;
  r["rotulo"] = txt(rel_resultado_rotulo(v.resultado));
  r["nivel"] = nivel;
  r["pedido"] = txt(v.pedido);
  r["medido"] = txt(v.medido);
  r["obs"] = txt(v.obs);
  return r;
}
