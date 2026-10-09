/* A linha do tempo. Ver linha_tempo.h. */
#include "linha_tempo.h"

#include "mascara.h"
#include "relogio.h"

static double g_t_musica = -1.0;

void lt_t_musica(double s) { g_t_musica = s; }

void lt_abrir(LinhaTempo *lt, const char *caminho, Uint64 inicio_ns) {
  SDL_memset(lt, 0, sizeof(*lt));
  lt->inicio_ns = inicio_ns;
  lt_t_musica(-1.0); /* sessão nova: sem música até alguém informar */
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
  e->cabeca = 0;
  double t = relogio_agora();
  tb_texto(&e->b, "{\"t\": ");
  tb_json_num(&e->b, t, 3);
  if (g_t_musica >= 0) {
    tb_texto(&e->b, ", \"t_musica\": ");
    tb_json_num(&e->b, g_t_musica, 3);
    e->cabeca |= 2;
  }
  tb_texto(&e->b, ", \"tipo\": ");
  tb_json_str(&e->b, tipo);
  if (jogador > 0) {
    tb_printf(&e->b, ", \"jogador\": %d, \"lugar\": %d", jogador, jogador - 1);
    e->cabeca |= 1;
  }
}

/* A chave já está na cabeça desta linha? Então o campo não entra (a cabeça
 * vence): o `lugar` que o Ritmo e a reserva mandam como campo é o mesmo
 * jogador - 1 da cabeça, e um JSON com chave repetida quebra leitor estrito. */
static bool na_cabeca(const Evento *e, const char *chave) {
  if (SDL_strcmp(chave, "t") == 0 || SDL_strcmp(chave, "tipo") == 0)
    return true;
  if ((e->cabeca & 1) && (SDL_strcmp(chave, "jogador") == 0 || SDL_strcmp(chave, "lugar") == 0))
    return true;
  return (e->cabeca & 2) && SDL_strcmp(chave, "t_musica") == 0;
}

void ev_str(Evento *e, const char *chave, const char *valor) {
  if (na_cabeca(e, chave))
    return;
  tb_printf(&e->b, ", \"%s\": ", chave);
  tb_json_str(&e->b, valor);
}

void ev_num(Evento *e, const char *chave, double valor) {
  if (na_cabeca(e, chave))
    return;
  tb_printf(&e->b, ", \"%s\": ", chave);
  tb_json_num(&e->b, valor, 3);
}

void ev_int(Evento *e, const char *chave, long valor) {
  if (na_cabeca(e, chave))
    return;
  tb_printf(&e->b, ", \"%s\": %ld", chave, valor);
}

void ev_bool(Evento *e, const char *chave, bool valor) {
  if (na_cabeca(e, chave))
    return;
  tb_printf(&e->b, ", \"%s\": %s", chave, valor ? "true" : "false");
}

void ev_ints(Evento *e, const char *chave, const int *v, int n) {
  if (na_cabeca(e, chave))
    return;
  tb_printf(&e->b, ", \"%s\": [", chave);
  for (int i = 0; i < n; i++)
    tb_printf(&e->b, "%s%d", i ? ", " : "", v[i]);
  tb_texto(&e->b, "]");
}

void ev_nums(Evento *e, const char *chave, const double *v, int n) {
  if (na_cabeca(e, chave))
    return;
  tb_printf(&e->b, ", \"%s\": [", chave);
  for (int i = 0; i < n; i++) {
    if (i)
      tb_texto(&e->b, ", ");
    tb_json_num(&e->b, v[i], 3);
  }
  tb_texto(&e->b, "]");
}

void ev_strs(Evento *e, const char *chave, const char *const *v, int n) {
  if (na_cabeca(e, chave))
    return;
  tb_printf(&e->b, ", \"%s\": [", chave);
  for (int i = 0; i < n; i++) {
    if (i)
      tb_texto(&e->b, ", ");
    tb_json_str(&e->b, v[i]);
  }
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
