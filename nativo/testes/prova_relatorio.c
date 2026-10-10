/* O relatório: JSON válido, matriz completa, máscara na entrada. */
#include "prova.h"

#include "relatorio.h"

#include <stdlib.h>

/* Um validador de JSON pequeno: aceita o que o relatório escreve (objetos,
 * listas, strings com escape, números, true/false/null). Não é genérico — é o
 * bastante para provar que nenhuma vírgula ficou sobrando. */
static const char *json_valor(const char *p);

static const char *pula(const char *p) {
  while (*p == ' ' || *p == '\n' || *p == '\r' || *p == '\t')
    p++;
  return p;
}

static const char *json_string(const char *p) {
  if (*p != '"')
    return NULL;
  p++;
  while (*p && *p != '"') {
    if ((unsigned char)*p < 0x20)
      return NULL;
    if (*p == '\\') {
      p++;
      if (!*p)
        return NULL;
    }
    p++;
  }
  return *p == '"' ? p + 1 : NULL;
}

static const char *json_numero(const char *p) {
  const char *i = p;
  if (*p == '-')
    p++;
  while ((*p >= '0' && *p <= '9') || *p == '.' || *p == 'e' || *p == 'E' || *p == '+' || *p == '-')
    p++;
  return p > i ? p : NULL;
}

static const char *json_objeto(const char *p) {
  p = pula(p + 1);
  if (*p == '}')
    return p + 1;
  for (;;) {
    p = json_string(pula(p));
    if (!p)
      return NULL;
    p = pula(p);
    if (*p != ':')
      return NULL;
    p = json_valor(pula(p + 1));
    if (!p)
      return NULL;
    p = pula(p);
    if (*p == ',') {
      p++;
      continue;
    }
    return *p == '}' ? p + 1 : NULL;
  }
}

static const char *json_lista(const char *p) {
  p = pula(p + 1);
  if (*p == ']')
    return p + 1;
  for (;;) {
    p = json_valor(pula(p));
    if (!p)
      return NULL;
    p = pula(p);
    if (*p == ',') {
      p++;
      continue;
    }
    return *p == ']' ? p + 1 : NULL;
  }
}

static const char *json_valor(const char *p) {
  p = pula(p);
  if (*p == '{')
    return json_objeto(p);
  if (*p == '[')
    return json_lista(p);
  if (*p == '"')
    return json_string(p);
  if (strncmp(p, "true", 4) == 0)
    return p + 4;
  if (strncmp(p, "false", 5) == 0)
    return p + 5;
  if (strncmp(p, "null", 4) == 0)
    return p + 4;
  return json_numero(p);
}

static int json_valido(const char *s) {
  const char *fim = json_valor(s);
  return fim && *pula(fim) == '\0';
}

void provas_relatorio(void) {
  Relatorio r;
  rel_iniciar(&r);
  snprintf(r.sessao, sizeof(r.sessao), "20260927-193005");
  snprintf(r.inicio, sizeof(r.inicio), "2026-09-27 19:30:05");
  snprintf(r.versao, sizeof(r.versao), "prova");
  snprintf(r.plataforma, sizeof(r.plataforma), "Linux");
  snprintf(r.sdl, sizeof(r.sdl), "3.4.14");
  snprintf(r.contrato, sizeof(r.contrato), "USB 0x02 pelo SDL");
  r.semente = 42;

  /* vazio: JSON válido, sem controles */
  char *json = NULL;
  espera(rel_json(&r, &json, NULL) == 0, "o JSON vazio monta");
  espera(json && json_valido(json), "o JSON vazio é válido");
  free(json);

  RelControle *c1 = &r.controles[0];
  c1->presente = 1;
  rel_copiar(c1->nome, sizeof(c1->nome), "DualSense Wireless Controller");
  rel_copiar(c1->vid_pid, sizeof(c1->vid_pid), "054c:0ce6");
  rel_copiar(c1->conexao, sizeof(c1->conexao), "USB");
  rel_copiar(c1->origem, sizeof(c1->origem), "DualSense nativo");
  rel_copiar(c1->evidencia, sizeof(c1->evidencia), "sysfs: HID bus 0003 com pai USB");
  c1->giro_declarado_hz = 250;
  c1->giro_medido_hz = 249.8;
  RelControle *c3 = &r.controles[2];
  c3->presente = 1;
  rel_copiar(c3->nome, sizeof(c3->nome), "DualSense \"aspas\" \\ barra\ttab");
  rel_copiar(c3->evidencia, sizeof(c3->evidencia), "phys 02:3a:9a:12:34:ab");
  c3->hidraw_sem_permissao = 1; /* a WU03: o relatório diz a causa do «efeitos não» */

  espera(strcmp(c3->evidencia, "phys 02:3a:9a:00:00:ab") == 0, "o relatório mascara na entrada");

  rel_registrar(&r, 1, F_GIROSCOPIO, RES_FALHOU, NIVEL_REAGIU, "girar", "pouco", NULL, 10.0);
  rel_registrar(&r, 1, F_GIROSCOPIO, RES_PASSOU, NIVEL_REAGIU, "girar", "312 graus/s", "segunda", 20.5);
  rel_registrar(&r, 3, F_VIBRACAO_FORTE, RES_FALHOU, NIVEL_SAIU, "sentir o grave",
                "2/6 às cegas; MAC 02:22:33:44:55:66", "", 30.0);
  espera(rel_registrar(&r, 5, F_GIROSCOPIO, RES_PASSOU, NIVEL_REAGIU, "", "", "", 0) == NULL,
         "jogador 5 não existe");
  espera(rel_registrar(&r, 1, F_TOTAL, RES_PASSOU, NIVEL_REAGIU, "", "", "", 0) == NULL,
         "feature fora do catálogo");

  const RelItem *u = rel_ultimo(&r, 1, F_GIROSCOPIO);
  espera(u && u->resultado == RES_PASSOU, "vale a última tentativa");
  espera(rel_ultimo(&r, 1, F_ACELEROMETRO) == NULL, "o que não se mediu não existe");
  const RelItem *v = rel_ultimo(&r, 3, F_VIBRACAO_FORTE);
  espera(v && strstr(v->medido, "02:22:33:00:00:66") != NULL, "o medido também é mascarado");

  rel_nota(&r, "nota da mesa");
  espera(rel_json(&r, &json, NULL) == 0, "o JSON cheio monta");
  espera(json && json_valido(json), "o JSON cheio é válido (escapes, vírgulas)");
  if (json) {
    espera(strstr(json, "\"formato\": \"hefesto-tech-demo/relatorio/1\"") != NULL, "tem o formato");
    espera(strstr(json, "\\\"aspas\\\"") != NULL, "aspas escapadas");
    espera(strstr(json, "\\t") != NULL, "tab escapado");
    espera(strstr(json, "12:34") == NULL, "nenhum octeto de MAC escapa");
    /* matriz: 2 controles x F_TOTAL linhas */
    int linhas = 0;
    const char *m = strstr(json, "\"matriz\"");
    const char *t = strstr(json, "\"tentativas\"");
    for (const char *p = m; p && p < t; p++)
      if (strncmp(p, "{\"jogador\"", 10) == 0)
        linhas++;
    espera(linhas == 2 * F_TOTAL, "a matriz tem toda feature de todo controle presente");
    espera(strstr(json, "\"motivo\": \"a sala não foi jogada com este controle\"") != NULL,
           "o não medido traz o motivo");
    espera(strstr(json, "\"causa_sem_efeitos\": \"" REL_CAUSA_HIDRAW "\"") != NULL,
           "o JSON diz a causa do hidraw sem permissão");
    espera(strstr(json, "\"causa_sem_efeitos\": null") != NULL, "e null no controle que tem permissão");
    free(json);
  }

  char *txt = NULL;
  espera(rel_texto(&r, &txt, NULL) == 0, "o texto monta");
  if (txt) {
    espera(strstr(txt, "MATRIZ") != NULL, "o texto tem a matriz");
    espera(strstr(txt, "Giroscópio: passou") != NULL, "o detalhe diz o veredito");
    espera(strstr(txt, "não medido — a sala") != NULL, "e diz o que não foi medido");
    espera(strstr(txt, "--semente 42") != NULL, "e como refazer os sorteios");
    espera(strstr(txt, "efeitos       " REL_CAUSA_HIDRAW) != NULL, "o texto diz a causa do hidraw");
    free(txt);
  }
  rel_liberar(&r);
}
