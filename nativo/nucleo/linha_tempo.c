/* A linha do tempo. Ver linha_tempo.h. */
#include "linha_tempo.h"

#include "mascara.h"
#include "relogio.h"

void lt_abrir(LinhaTempo *lt, const char *caminho, Uint64 inicio_ns) {
  SDL_memset(lt, 0, sizeof(*lt));
  lt->inicio_ns = inicio_ns;
  if (caminho && caminho[0])
    lt->arq = SDL_IOFromFile(caminho, "w");
}

void lt_fechar(LinhaTempo *lt) {
  if (lt->arq)
    SDL_CloseIO(lt->arq);
  lt->arq = NULL;
}

void ev_iniciar(Evento *e, const LinhaTempo *lt, const char *tipo, int jogador) {
  tb_iniciar(&e->b);
  (void)lt;
  double t = relogio_agora();
  tb_texto(&e->b, "{\"t\": ");
  tb_json_num(&e->b, t, 3);
  tb_texto(&e->b, ", \"tipo\": ");
  tb_json_str(&e->b, tipo);
  if (jogador > 0)
    tb_printf(&e->b, ", \"jogador\": %d", jogador);
}

void ev_str(Evento *e, const char *chave, const char *valor) {
  tb_printf(&e->b, ", \"%s\": ", chave);
  tb_json_str(&e->b, valor);
}

void ev_num(Evento *e, const char *chave, double valor) {
  tb_printf(&e->b, ", \"%s\": ", chave);
  tb_json_num(&e->b, valor, 3);
}

void ev_int(Evento *e, const char *chave, long valor) { tb_printf(&e->b, ", \"%s\": %ld", chave, valor); }

void ev_bool(Evento *e, const char *chave, bool valor) {
  tb_printf(&e->b, ", \"%s\": %s", chave, valor ? "true" : "false");
}

void ev_ints(Evento *e, const char *chave, const int *v, int n) {
  tb_printf(&e->b, ", \"%s\": [", chave);
  for (int i = 0; i < n; i++)
    tb_printf(&e->b, "%s%d", i ? ", " : "", v[i]);
  tb_texto(&e->b, "]");
}

void ev_fim(Evento *e, LinhaTempo *lt) {
  tb_texto(&e->b, "}\n");
  if (!e->b.falhou && e->b.dados) {
    mascara_mac(e->b.dados);
    if (lt->arq) {
      SDL_WriteIO(lt->arq, e->b.dados, e->b.tam);
      SDL_FlushIO(lt->arq);
    }
    lt->eventos++;
  }
  tb_liberar(&e->b);
}
