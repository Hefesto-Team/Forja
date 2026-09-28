/* O que as partes do módulo repartem entre si (não é API do GDScript): a Cega
 * que vem do dicionário da sala e o porquê de uma saída que nem montou. */
#ifndef FORJA_GODOT_INTERNO_H
#define FORJA_GODOT_INTERNO_H

#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/variant.hpp>

extern "C" {
#include "cegas.h"
#include "forja.h"
#include "origem.h"
#include "pads.h"
#include "relatorio.h"
}

#include <cstdio>
#include <cstring>

namespace forja_interno {

/* A Cega do dicionário da sala: {certos, errados, perdidos, como}, em que
 * `como[i]` conta as erradas em que a pessoa disse a opção i. */
inline Cega cega_de(const godot::Variant &v) {
  Cega c;
  cega_zerar(&c);
  if (v.get_type() != godot::Variant::DICTIONARY)
    return c;
  godot::Dictionary d = v;
  c.certos = (int)d.get("certos", 0);
  c.errados = (int)d.get("errados", 0);
  c.perdidos = (int)d.get("perdidos", 0);
  if (d.has("como")) {
    godot::Array a = d["como"];
    for (int i = 0; i < a.size() && i < CEGA_OPCOES; i++)
      c.respondeu_como[i] = (int)a[i];
  }
  return c;
}

inline void juntar_obs(Veredito *v, const char *s) {
  size_t n = std::strlen(v->obs);
  std::snprintf(v->obs + n, sizeof(v->obs) - n, "%s%s", n ? " — " : "", s);
}

/* A saída nem montou (o SDL recusou): o porquê é a origem do controle. */
inline void explica_recusa(int lugar, Veredito *v) {
  Pad *p = FORJA ? pads_do_slot(FORJA, lugar) : nullptr;
  if (!p || v->nivel != NIVEL_MONTOU)
    return;
  char pq[240];
  if (FORJA->pads.contrato_estrito && p->origem.conexao == CONEXAO_BT && origem_eh_dualsense(p->origem.tipo))
    std::snprintf(pq, sizeof(pq), "no rádio, este jogo só lê: o relatório 0x31 fica de fora (CONTRATO.md) — ligue o "
                                  "DualSense no cabo, ou um DualSense virtual USB");
  else
    std::snprintf(pq, sizeof(pq), "o controle chegou como %s (%s)", pad_origem_rotulo(p),
                  conexao_rotulo(p->origem.conexao));
  juntar_obs(v, pq);
}

} // namespace forja_interno

#endif
