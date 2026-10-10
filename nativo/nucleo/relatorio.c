/* O relatório da sessão. Ver relatorio.h. */
#include "relatorio.h"

#include "mascara.h"
#include "texto_buf.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void rel_copiar(char *campo, size_t tam, const char *de) { mascara_mac_copia(de, campo, tam); }

void rel_iniciar(Relatorio *r) {
  memset(r, 0, sizeof(*r));
  for (int i = 0; i < REL_MAX_CONTROLES; i++)
    r->controles[i].jogador = i + 1;
}

void rel_liberar(Relatorio *r) {
  free(r->itens);
  r->itens = NULL;
  r->n_itens = r->cap_itens = 0;
}

RelItem *rel_registrar(Relatorio *r, int jogador, Feature f, Resultado res, NivelEvidencia nivel,
                       const char *pedido, const char *medido, const char *observacao, double t) {
  if (jogador < 1 || jogador > REL_MAX_CONTROLES || (int)f < 0 || f >= F_TOTAL)
    return NULL;
  if (r->n_itens == r->cap_itens) {
    int cap = r->cap_itens ? r->cap_itens * 2 : 64;
    RelItem *novo = realloc(r->itens, (size_t)cap * sizeof(*novo));
    if (!novo)
      return NULL;
    r->itens = novo;
    r->cap_itens = cap;
  }
  RelItem *it = &r->itens[r->n_itens++];
  memset(it, 0, sizeof(*it));
  it->jogador = jogador;
  it->feature = f;
  it->resultado = res;
  it->nivel = nivel;
  it->t = t;
  rel_copiar(it->pedido, sizeof(it->pedido), pedido);
  rel_copiar(it->medido, sizeof(it->medido), medido);
  rel_copiar(it->observacao, sizeof(it->observacao), observacao);
  return it;
}

const RelItem *rel_ultimo(const Relatorio *r, int jogador, Feature f) {
  for (int i = r->n_itens - 1; i >= 0; i--)
    if (r->itens[i].jogador == jogador && r->itens[i].feature == f)
      return &r->itens[i];
  return NULL;
}

void rel_nota(Relatorio *r, const char *texto) {
  if (r->n_notas >= (int)(sizeof(r->notas) / sizeof(r->notas[0])))
    return;
  rel_copiar(r->notas[r->n_notas], sizeof(r->notas[0]), texto);
  r->n_notas++;
}

const char *rel_resultado_rotulo(Resultado res) {
  switch (res) {
  case RES_PASSOU:
    return "passou";
  case RES_FALHOU:
    return "falhou";
  default:
    return "não medido";
  }
}

const char *rel_nivel_rotulo(NivelEvidencia n) {
  switch (n) {
  case NIVEL_MONTOU:
    return "montou";
  case NIVEL_SAIU:
    return "saiu";
  case NIVEL_OBEDECEU:
    return "obedeceu";
  case NIVEL_REAGIU:
    return "reagiu";
  default:
    return "nenhum";
  }
}

/* ---------- JSON ---------- */

static void json_som(TextoBuf *b, const char *chave, const RelSom *s, int ultimo) {
  tb_printf(b, "      \"%s\": {\"nome\": ", chave);
  tb_json_str(b, s->nome[0] ? s->nome : NULL);
  tb_texto(b, ", \"como\": ");
  tb_json_str(b, s->como[0] ? s->como : "não achado");
  tb_printf(b, ", \"canais\": %d}%s\n", s->canais, ultimo ? "" : ",");
}

static void json_hz(TextoBuf *b, const char *chave, double v, int ultimo) {
  tb_printf(b, "      \"%s\": ", chave);
  if (v > 0)
    tb_json_num(b, v, 1);
  else
    tb_texto(b, "null");
  tb_texto(b, ultimo ? "\n" : ",\n");
}

static void json_controle(TextoBuf *b, const RelControle *c, int ultimo) {
  tb_texto(b, "    {\n");
  tb_printf(b, "      \"jogador\": %d,\n", c->jogador);
  tb_texto(b, "      \"nome\": ");
  tb_json_str(b, c->nome);
  tb_texto(b, ",\n      \"nome_do_sistema\": ");
  tb_json_str(b, c->nome_do_sistema[0] ? c->nome_do_sistema : NULL);
  tb_texto(b, ",\n      \"vid_pid\": ");
  tb_json_str(b, c->vid_pid);
  tb_texto(b, ",\n      \"conexao\": ");
  tb_json_str(b, c->conexao);
  tb_texto(b, ",\n      \"origem\": ");
  tb_json_str(b, c->origem);
  tb_texto(b, ",\n      \"evidencia_da_origem\": ");
  tb_json_str(b, c->evidencia);
  tb_texto(b, ",\n      \"tipo_sdl\": ");
  tb_json_str(b, c->tipo_sdl);
  tb_texto(b, ",\n      \"firmware\": ");
  tb_json_str(b, c->firmware[0] ? c->firmware : NULL);
  tb_texto(b, ",\n      \"bateria\": ");
  tb_json_str(b, c->bateria[0] ? c->bateria : NULL);
  tb_printf(b, ",\n      \"reconexoes\": %d,\n", c->reconexoes);
  tb_texto(b, "      \"causa_sem_efeitos\": ");
  tb_json_str(b, c->hidraw_sem_permissao ? REL_CAUSA_HIDRAW : NULL);
  tb_texto(b, ",\n");
  json_hz(b, "giroscopio_hz_declarado_pelo_sdl", c->giro_declarado_hz, 0);
  json_hz(b, "giroscopio_hz_medido_relogio_do_host", c->giro_medido_hz, 0);
  json_hz(b, "giroscopio_hz_medido_relogio_do_controle", c->giro_medido_relogio_hz, 0);
  json_hz(b, "acelerometro_hz_declarado_pelo_sdl", c->acel_declarado_hz, 0);
  json_hz(b, "acelerometro_hz_medido", c->acel_medido_hz, 0);
  json_som(b, "alto_falante", &c->alto_falante, 0);
  json_som(b, "microfone", &c->microfone, 0);
  json_som(b, "haptica", &c->haptica, 1);
  tb_printf(b, "    }%s\n", ultimo ? "" : ",");
}

static void json_item(TextoBuf *b, const RelItem *it, int ultimo) {
  const InfoFeature *f = catalogo_feature(it->feature);
  const InfoSala *sala = catalogo_sala(f->sala);
  tb_printf(b, "    {\"jogador\": %d, \"sala\": ", it->jogador);
  tb_json_str(b, sala->chave);
  tb_texto(b, ", \"feature\": ");
  tb_json_str(b, f->chave);
  tb_texto(b, ", \"resultado\": ");
  tb_json_str(b, rel_resultado_rotulo(it->resultado));
  tb_texto(b, ", \"evidencia\": ");
  tb_json_str(b, rel_nivel_rotulo(it->nivel));
  tb_texto(b, ",\n     \"pedido\": ");
  tb_json_str(b, it->pedido);
  tb_texto(b, ",\n     \"medido\": ");
  tb_json_str(b, it->medido);
  tb_texto(b, ",\n     \"observacao\": ");
  tb_json_str(b, it->observacao[0] ? it->observacao : NULL);
  tb_texto(b, ", \"t_s\": ");
  tb_json_num(b, it->t, 1);
  tb_printf(b, "}%s\n", ultimo ? "" : ",");
}

int rel_json(const Relatorio *r, char **saida, size_t *tam) {
  TextoBuf b;
  tb_iniciar(&b);
  tb_texto(&b, "{\n  \"formato\": \"hefesto-tech-demo/relatorio/1\",\n  \"sessao\": {\n");
  tb_texto(&b, "    \"id\": ");
  tb_json_str(&b, r->sessao);
  tb_texto(&b, ",\n    \"inicio\": ");
  tb_json_str(&b, r->inicio);
  tb_texto(&b, ",\n    \"fim\": ");
  tb_json_str(&b, r->fim[0] ? r->fim : NULL);
  tb_texto(&b, ",\n    \"versao_do_jogo\": ");
  tb_json_str(&b, r->versao);
  tb_texto(&b, ",\n    \"plataforma\": ");
  tb_json_str(&b, r->plataforma);
  tb_texto(&b, ",\n    \"sdl\": ");
  tb_json_str(&b, r->sdl);
  tb_texto(&b, ",\n    \"contrato\": ");
  tb_json_str(&b, r->contrato);
  tb_printf(&b, ",\n    \"semente\": %llu,\n    \"notas\": [", r->semente);
  for (int i = 0; i < r->n_notas; i++) {
    if (i)
      tb_texto(&b, ", ");
    tb_json_str(&b, r->notas[i]);
  }
  tb_texto(&b, "]\n  },\n  \"controles\": [\n");
  int n_pres = 0;
  for (int i = 0; i < REL_MAX_CONTROLES; i++)
    n_pres += r->controles[i].presente;
  int vistos = 0;
  for (int i = 0; i < REL_MAX_CONTROLES; i++) {
    if (!r->controles[i].presente)
      continue;
    vistos++;
    json_controle(&b, &r->controles[i], vistos == n_pres);
  }
  tb_texto(&b, "  ],\n  \"matriz\": [\n");
  /* A matriz: toda feature, para todo controle presente, com o último
   * veredito — ou "não medido", com o motivo. */
  int linhas = 0, total_linhas = n_pres * F_TOTAL;
  for (int i = 0; i < REL_MAX_CONTROLES; i++) {
    const RelControle *c = &r->controles[i];
    if (!c->presente)
      continue;
    for (int f = 0; f < F_TOTAL; f++) {
      const RelItem *it = rel_ultimo(r, c->jogador, (Feature)f);
      const InfoFeature *inf = catalogo_feature((Feature)f);
      linhas++;
      tb_printf(&b, "    {\"jogador\": %d, \"feature\": ", c->jogador);
      tb_json_str(&b, inf->chave);
      tb_texto(&b, ", \"resultado\": ");
      tb_json_str(&b, rel_resultado_rotulo(it ? it->resultado : RES_NAO_MEDIDO));
      if (!it) {
        tb_texto(&b, ", \"motivo\": ");
        tb_json_str(&b, "a sala não foi jogada com este controle");
      }
      tb_printf(&b, "}%s\n", linhas == total_linhas ? "" : ",");
    }
  }
  tb_texto(&b, "  ],\n  \"tentativas\": [\n");
  for (int i = 0; i < r->n_itens; i++)
    json_item(&b, &r->itens[i], i == r->n_itens - 1);
  tb_texto(&b, "  ]\n}\n");
  if (b.falhou) {
    tb_liberar(&b);
    return -1;
  }
  *saida = b.dados;
  if (tam)
    *tam = b.tam;
  return 0;
}

/* ---------- texto ---------- */

static const char *simbolo(Resultado res) {
  switch (res) {
  case RES_PASSOU:
    return "PASSOU";
  case RES_FALHOU:
    return "FALHOU";
  default:
    return "—";
  }
}

/* Preenche com espaços até `largura` colunas, contando codepoints (os acentos
 * ocupam uma coluna). */
static void coluna(TextoBuf *b, const char *s, int largura) {
  int cols = 0;
  for (const unsigned char *p = (const unsigned char *)s; *p; p++)
    if ((*p & 0xC0) != 0x80)
      cols++;
  tb_texto(b, s);
  for (int i = cols; i < largura; i++)
    tb_texto(b, " ");
}

static void texto_som(TextoBuf *b, const char *rotulo, const RelSom *s) {
  tb_texto(b, "    ");
  coluna(b, rotulo, 14);
  if (s->nome[0])
    tb_printf(b, "%s — %s, %d canais\n", s->nome, s->como, s->canais);
  else
    tb_printf(b, "não achado%s%s\n", s->como[0] ? " — " : "", s->como);
}

int rel_texto(const Relatorio *r, char **saida, size_t *tam) {
  TextoBuf b;
  tb_iniciar(&b);
  tb_texto(&b, "HEFESTO TECH DEMO — relatório da sessão\n");
  tb_texto(&b, "=======================================\n\n");
  tb_printf(&b, "sessão      %s\n", r->sessao);
  tb_printf(&b, "início      %s\n", r->inicio);
  tb_printf(&b, "fim         %s\n", r->fim[0] ? r->fim : "(em andamento)");
  tb_printf(&b, "versão      %s\n", r->versao);
  tb_printf(&b, "plataforma  %s\n", r->plataforma);
  tb_printf(&b, "SDL         %s\n", r->sdl);
  tb_printf(&b, "contrato    %s\n", r->contrato);
  tb_printf(&b, "semente     %llu  (--semente %llu refaz a mesma ordem dos sorteios)\n\n",
            r->semente, r->semente);

  tb_texto(&b, "CONTROLES NA MESA\n-----------------\n");
  int algum = 0;
  for (int i = 0; i < REL_MAX_CONTROLES; i++) {
    const RelControle *c = &r->controles[i];
    if (!c->presente)
      continue;
    algum = 1;
    tb_printf(&b, "P%d  %s  [%s]\n", c->jogador, c->nome, c->vid_pid);
    if (c->nome_do_sistema[0])
      tb_printf(&b, "    sistema       %s\n", c->nome_do_sistema);
    tb_printf(&b, "    conexão       %s\n", c->conexao);
    tb_printf(&b, "    origem        %s\n", c->origem);
    if (c->evidencia[0])
      tb_printf(&b, "    evidência     %s\n", c->evidencia);
    if (c->firmware[0])
      tb_printf(&b, "    firmware      %s\n", c->firmware);
    if (c->bateria[0])
      tb_printf(&b, "    bateria       %s\n", c->bateria);
    if (c->giro_declarado_hz > 0 || c->giro_medido_hz > 0)
      tb_printf(&b, "    giroscópio    declarado %.0f Hz · medido %.1f Hz (host) · %.1f Hz (relógio do controle)\n",
                c->giro_declarado_hz, c->giro_medido_hz, c->giro_medido_relogio_hz);
    texto_som(&b, "alto-falante", &c->alto_falante);
    texto_som(&b, "microfone", &c->microfone);
    texto_som(&b, "háptica", &c->haptica);
    if (c->reconexoes)
      tb_printf(&b, "    reconexões    %d\n", c->reconexoes);
    if (c->hidraw_sem_permissao)
      tb_printf(&b, "    efeitos       %s\n", REL_CAUSA_HIDRAW);
  }
  if (!algum)
    tb_texto(&b, "(nenhum controle entrou nesta sessão)\n");

  tb_texto(&b, "\nMATRIZ — o último veredito de cada feature\n------------------------------------------\n");
  coluna(&b, "feature", 34);
  for (int i = 0; i < REL_MAX_CONTROLES; i++)
    if (r->controles[i].presente) {
      char cab[8];
      snprintf(cab, sizeof(cab), "P%d", r->controles[i].jogador);
      coluna(&b, cab, 9);
    }
  tb_texto(&b, "\n");
  for (int f = 0; f < F_TOTAL; f++) {
    coluna(&b, catalogo_feature((Feature)f)->nome, 34);
    for (int i = 0; i < REL_MAX_CONTROLES; i++) {
      if (!r->controles[i].presente)
        continue;
      const RelItem *it = rel_ultimo(r, r->controles[i].jogador, (Feature)f);
      coluna(&b, simbolo(it ? it->resultado : RES_NAO_MEDIDO), 9);
    }
    tb_texto(&b, "\n");
  }
  tb_texto(&b, "(— = não medido)\n");

  tb_texto(&b, "\nDETALHE — pedido, medido e veredito\n-----------------------------------\n");
  for (int i = 0; i < REL_MAX_CONTROLES; i++) {
    const RelControle *c = &r->controles[i];
    if (!c->presente)
      continue;
    tb_printf(&b, "\n[P%d]\n", c->jogador);
    for (int f = 0; f < F_TOTAL; f++) {
      const RelItem *it = rel_ultimo(r, c->jogador, (Feature)f);
      const InfoFeature *inf = catalogo_feature((Feature)f);
      if (!it) {
        tb_printf(&b, "  %s: não medido — a sala %s não foi jogada\n", inf->nome,
                  catalogo_sala(inf->sala)->nome);
        continue;
      }
      tb_printf(&b, "  %s: %s  (evidência: %s)\n", inf->nome, rel_resultado_rotulo(it->resultado),
                rel_nivel_rotulo(it->nivel));
      tb_printf(&b, "    pedido: %s\n", it->pedido);
      tb_printf(&b, "    medido: %s\n", it->medido);
      if (it->observacao[0])
        tb_printf(&b, "    obs.:   %s\n", it->observacao);
    }
  }

  if (r->n_notas) {
    tb_texto(&b, "\nNOTAS DA MESA\n-------------\n");
    for (int i = 0; i < r->n_notas; i++)
      tb_printf(&b, "- %s\n", r->notas[i]);
  }
  tb_printf(&b, "\n%d tentativas registradas. O JSON ao lado traz todas, na ordem.\n", r->n_itens);
  if (b.falhou) {
    tb_liberar(&b);
    return -1;
  }
  *saida = b.dados;
  if (tam)
    *tam = b.tam;
  return 0;
}
