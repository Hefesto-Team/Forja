/* A bancada dos experimentos (experimental/), do lado do módulo: a escuta
 * crua do microfone de cada controle, o report cru USB 0x01, a análise
 * provada sem aparelho (analise.h) e o resultado de cada medida — na linha
 * do tempo (`"tipo": "experimento"`) e no registro, com "medido", "falhou"
 * ou "nao_medido". Nada daqui decide veredito de sala. */
#include "forja_controles.h"

extern "C" {
#include "analise.h"
#include "forja.h"
#include "pads.h"
#include "som_controle.h"
}

#include <cstring>
#include <vector>

using namespace godot;

bool ForjaControles::som_escutar(int lugar, float segundos) {
  return aberto_ && segundos > 0.0f && somc_escutar(FORJA, lugar, segundos);
}

PackedFloat32Array ForjaControles::som_escuta(int lugar) const {
  PackedFloat32Array saida;
  if (!aberto_)
    return saida;
  int n = 0;
  const float *a = somc_escuta(FORJA, lugar, &n);
  if (a && n > 0) {
    saida.resize(n);
    std::memcpy(saida.ptrw(), a, sizeof(float) * (size_t)n);
  }
  return saida;
}

void ForjaControles::som_escuta_parar(int lugar) {
  if (aberto_)
    somc_escuta_parar(FORJA, lugar);
}

int ForjaControles::exp_ataque(const PackedFloat32Array &a, float vezes, float minimo) const {
  return ::exp_ataque(a.ptr(), (int)a.size(), vezes, minimo);
}

float ForjaControles::exp_rms_db(const PackedFloat32Array &a, int ini, int n) const {
  if (ini < 0 || n <= 0 || ini + n > a.size())
    return -90.0f;
  return exp_db(exp_rms(a.ptr(), ini, n));
}

float ForjaControles::exp_mediana(const PackedFloat32Array &v) const {
  std::vector<float> c(v.ptr(), v.ptr() + v.size());
  return ::exp_mediana(c.data(), (int)c.size());
}

/* niveis: 16 números, microfone × quem fala (linha a linha). */
Dictionary ForjaControles::exp_diagonal(const PackedFloat32Array &niveis, int n) const {
  Dictionary d;
  float m[4][4] = {};
  for (int i = 0; i < 16 && i < niveis.size(); i++)
    m[i / 4][i % 4] = niveis[i];
  float margem = 0.0f;
  d["certos"] = ::exp_diagonal(m, n < 0 ? 0 : (n > 4 ? 4 : n), &margem);
  d["margem_db"] = margem;
  return d;
}

/* O report cru USB 0x01 do controle do lugar (64 bytes), ou vazio sem ele (um
 * controle simulado, virtual ou pelo rádio). */
PackedByteArray ForjaControles::relatorio_cru(int lugar) const {
  PackedByteArray b;
  Pad *p = aberto_ ? pads_do_slot(FORJA, lugar) : nullptr;
  if (!p || !p->cru_ok)
    return b;
  b.resize(64);
  std::memcpy(b.ptrw(), p->cru, 64);
  return b;
}

/* Um resultado da bancada: a linha do tempo, o registro (mascarado). */
void ForjaControles::experimento(int lugar, const String &chave, const String &o, int resultado, const String &texto) {
  if (!aberto_)
    return;
  static const char *const NOMES[3] = {"medido", "falhou", "nao_medido"};
  const char *res = NOMES[resultado < 0 || resultado > 2 ? 2 : resultado];
  CharString ch = chave.utf8(), oc = o.utf8(), tx = texto.utf8();
  Evento ev;
  ev_iniciar(&ev, &FORJA->lt, "experimento", lugar >= 0 ? lugar + 1 : 0);
  ev_str(&ev, "experimento", ch.get_data());
  ev_str(&ev, "o", oc.get_data());
  ev_str(&ev, "resultado", res);
  ev_str(&ev, "texto", tx.get_data());
  ev_fim(&ev, &FORJA->lt);
  reg_linha(&FORJA->reg, "experimento %s · %s · %s: %s", ch.get_data(), lugar >= 0 ? pads_rotulo_slot(lugar) : "mesa",
            res, tx.get_data());
}
