/* Achar o som de cada controle. Ver achar_som.h. */
#include "achar_som.h"

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void minusculo(const char *de, char *para, size_t tam) {
  size_t i = 0;
  for (; de && de[i] && i + 1 < tam; i++)
    para[i] = (char)tolower((unsigned char)de[i]);
  para[i] = '\0';
}

static bool contem(const char *palheiro_min, const char *agulha) { return strstr(palheiro_min, agulha) != NULL; }

static void sem_fim(char *s) {
  size_t n = strlen(s);
  while (n && (s[n - 1] == '\n' || s[n - 1] == '\r' || s[n - 1] == ' ' || s[n - 1] == '"'))
    s[--n] = '\0';
}

/* ---------- a lista do sistema ---------- */

int achar_ler_pactl(const char *texto, bool gravacao, NoSistema *nos, int max) {
  const char *cabeca = gravacao ? "Source #" : "Sink #";
  int n = 0;
  NoSistema atual;
  bool aberto = false;
  const char *p = texto ? texto : "";
  for (;;) {
    const char *fim = strchr(p, '\n');
    size_t len = fim ? (size_t)(fim - p) : strlen(p);
    char linha[1024];
    if (len >= sizeof(linha))
      len = sizeof(linha) - 1;
    memcpy(linha, p, len);
    linha[len] = '\0';
    bool acabou = !*p;
    const char *c = linha;
    while (*c == ' ' || *c == '\t')
      c++;
    if (acabou || strncmp(linha, cabeca, strlen(cabeca)) == 0) {
      if (aberto && n < max) {
        size_t nn = strlen(atual.nome);
        bool monitor = nn >= 8 && strcmp(atual.nome + nn - 8, ".monitor") == 0;
        if (!monitor)
          nos[n++] = atual;
      }
      if (acabou)
        break;
      memset(&atual, 0, sizeof(atual));
      atual.indice = atoi(linha + strlen(cabeca));
      atual.gravacao = gravacao;
      aberto = true;
    } else if (aberto) {
      if (strncmp(c, "Name: ", 6) == 0) {
        snprintf(atual.nome, sizeof(atual.nome), "%s", c + 6);
        sem_fim(atual.nome);
      } else if (strncmp(c, "Description: ", 13) == 0) {
        snprintf(atual.descricao, sizeof(atual.descricao), "%s", c + 13);
        sem_fim(atual.descricao);
      } else if (strncmp(c, "Sample Specification: ", 22) == 0) {
        int canais = 0;
        if (sscanf(c + 22, "%*s %dch", &canais) == 1)
          atual.canais = canais;
      } else {
        const char *igual = strstr(c, " = ");
        if (igual) {
          char chave[96], valor[512];
          size_t k = (size_t)(igual - c);
          if (k < sizeof(chave)) {
            memcpy(chave, c, k);
            chave[k] = '\0';
            const char *v = igual + 3;
            if (*v == '"')
              v++;
            snprintf(valor, sizeof(valor), "%s", v);
            sem_fim(valor);
            if (!strcmp(chave, "sysfs.path"))
              snprintf(atual.sysfs, sizeof(atual.sysfs), "%s", valor);
            else if (!strcmp(chave, "device.bus"))
              snprintf(atual.bus, sizeof(atual.bus), "%s", valor);
            else if (!strcmp(chave, "device.vendor.id"))
              atual.vid = strtol(valor, NULL, 16);
            else if (!strcmp(chave, "device.product.id"))
              atual.pid = strtol(valor, NULL, 16);
          }
        }
      }
    }
    if (!fim)
      p += len; /* a última linha sem '\n': a próxima volta fecha o bloco */
    else
      p = fim + 1;
  }
  return n;
}

/* ---------- o nome ---------- */

int achar_numero(const char *nome) {
  char b[256];
  minusculo(nome, b, sizeof(b));
  const char *p = strstr(b, "controle ");
  if (!p)
    return 0;
  p += 9;
  if (!isdigit((unsigned char)*p))
    return 0;
  return atoi(p);
}

TipoNoSom achar_tipo(const char *nome, bool gravacao) {
  char b[256];
  minusculo(nome, b, sizeof(b));
  if (contem(b, "monitor of") || contem(b, ".monitor"))
    return NO_OUTRO; /* a saída vista de dentro não é o controle */
  /* só conta o nó que um jogo reconheceria como DualSense pela palavra da
   * Sony (CONTRATO.md) — os nós numerados do Hefesto a trazem entre parênteses */
  bool sony = contem(b, "dualsense") || contem(b, "wireless controller");
  if (!sony)
    return NO_OUTRO;
  bool numerado = achar_numero(nome) > 0;
  if (numerado) {
    if (!gravacao && contem(b, "alto-falante do controle"))
      return NO_NUMERADO_FALANTE;
    if (!gravacao && (contem(b, "háptica do controle") || contem(b, "haptica do controle")))
      return NO_NUMERADO_HAPTICA;
    if (gravacao && contem(b, "microfone do controle"))
      return NO_NUMERADO_MIC;
  }
  return gravacao ? NO_DUALSENSE_ENTRADA : NO_DUALSENSE_SAIDA;
}

bool achar_serve(TipoNoSom tipo, PapelSom papel) {
  switch (papel) {
  case PAPEL_ALTO_FALANTE:
    return tipo == NO_DUALSENSE_SAIDA || tipo == NO_NUMERADO_FALANTE;
  case PAPEL_HAPTICA:
    return tipo == NO_DUALSENSE_SAIDA || tipo == NO_NUMERADO_HAPTICA;
  case PAPEL_MICROFONE:
    return tipo == NO_DUALSENSE_ENTRADA || tipo == NO_NUMERADO_MIC;
  default:
    return false;
  }
}

static bool numerado(TipoNoSom t) {
  return t == NO_NUMERADO_FALANTE || t == NO_NUMERADO_HAPTICA || t == NO_NUMERADO_MIC;
}

/* A háptica da placa do controle precisa dos canais dos atuadores. */
static bool cabe(const NoSom *no, PapelSom papel) {
  if (!achar_serve(no->tipo, papel))
    return false;
  if (papel == PAPEL_HAPTICA && no->tipo == NO_DUALSENSE_SAIDA && no->canais < 4)
    return false;
  return true;
}

/* ---------- casar as duas listas ---------- */

void achar_casar(NoSom *jogo, int n_jogo, const NoSistema *sis, int n_sis) {
  for (int i = 0; i < n_jogo; i++) {
    jogo[i].no_sistema = -1;
    int k = 0; /* quantos com o mesmo nome vieram antes na lista do jogo */
    for (int j = 0; j < i; j++)
      if (jogo[j].gravacao == jogo[i].gravacao && !strcmp(jogo[j].nome, jogo[i].nome))
        k++;
    for (int s = 0; s < n_sis; s++) {
      if (sis[s].gravacao != jogo[i].gravacao || strcmp(sis[s].descricao, jogo[i].nome) != 0)
        continue;
      if (k-- == 0) {
        jogo[i].no_sistema = s;
        break;
      }
    }
  }
}

/* ---------- a escolha ---------- */

int achar_para(const NoSom *nos, int n, PapelSom papel, const char *usb_do_pad, const char *container_do_pad,
               int numero_na_mesa, const bool *usado, ComoAchou *como) {
  if (como)
    *como = ACHOU_NADA;
  /* 1. pelo aparelho */
  for (int i = 0; i < n; i++) {
    if ((usado && usado[i]) || !cabe(&nos[i], papel))
      continue;
    bool mesmo_usb = usb_do_pad && usb_do_pad[0] && nos[i].usb[0] && !strcmp(nos[i].usb, usb_do_pad);
    bool mesmo_container = container_do_pad && container_do_pad[0] && nos[i].container[0] &&
                           !strcmp(nos[i].container, container_do_pad);
    if (mesmo_usb || mesmo_container) {
      if (como)
        *como = ACHOU_APARELHO;
      return i;
    }
  }
  /* 2. pelo número do lugar à mesa */
  for (int i = 0; numero_na_mesa > 0 && i < n; i++) {
    if ((usado && usado[i]) || !cabe(&nos[i], papel) || !numerado(nos[i].tipo))
      continue;
    if (nos[i].controle_n == numero_na_mesa) {
      if (como)
        *como = ACHOU_NUMERO;
      return i;
    }
  }
  /* 3. pelo nome: a placa do controle que ninguém levou e que não é, pelo
   * aparelho, de outro controle conhecido (quem chama marca isso em `usado`) */
  for (int i = 0; i < n; i++) {
    if ((usado && usado[i]) || !cabe(&nos[i], papel) || numerado(nos[i].tipo))
      continue;
    if (como)
      *como = ACHOU_NOME;
    return i;
  }
  return -1;
}

void achar_canais(const NoSom *no, PapelSom papel, int *a, int *b) {
  *a = *b = -1;
  if (!no)
    return;
  switch (no->tipo) {
  case NO_DUALSENSE_SAIDA:
    if (papel == PAPEL_ALTO_FALANTE && no->canais >= 2) {
      *a = 1; /* front-right: o alto-falante sem fone (o front-left é o fone) */
    } else if (papel == PAPEL_ALTO_FALANTE && no->canais == 1) {
      *a = 0;
    } else if (papel == PAPEL_HAPTICA && no->canais >= 4) {
      *a = 2; /* rear-left: o atuador esquerdo */
      *b = 3; /* rear-right: o atuador direito */
    }
    break;
  case NO_NUMERADO_FALANTE:
    *a = 0;
    if (no->canais >= 2)
      *b = 1;
    break;
  case NO_NUMERADO_HAPTICA:
    *a = 0;
    *b = no->canais >= 2 ? 1 : 0;
    break;
  case NO_DUALSENSE_ENTRADA:
  case NO_NUMERADO_MIC:
    if (papel == PAPEL_MICROFONE)
      *a = 0;
    break;
  default:
    break;
  }
}

const char *achar_como_rotulo(ComoAchou c) {
  switch (c) {
  case ACHOU_APARELHO:
    return "pelo aparelho";
  case ACHOU_NUMERO:
    return "pelo número do controle no nome";
  case ACHOU_NOME:
    return "pelo nome";
  case ACHOU_PESSOA:
    return "a pessoa apontou na lista";
  default:
    return "não achado";
  }
}
