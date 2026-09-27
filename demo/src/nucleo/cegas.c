/* As provas às cegas. Ver cegas.h. */
#include "cegas.h"

#include <stdio.h>
#include <string.h>

void cega_zerar(Cega *c) { memset(c, 0, sizeof(*c)); }
void cega_certo(Cega *c) { c->certos++; }
void cega_perdido(Cega *c) { c->perdidos++; }
int cega_total(const Cega *c) { return c->certos + c->errados + c->perdidos; }

void cega_errado(Cega *c, int disse) {
  c->errados++;
  if (disse >= 0 && disse < CEGA_OPCOES)
    c->respondeu_como[disse]++;
}

static int mais_dito(const Cega *c) {
  int melhor = -1;
  for (int i = 0; i < CEGA_OPCOES; i++)
    if (c->respondeu_como[i] > 0 && (melhor < 0 || c->respondeu_como[i] > c->respondeu_como[melhor]))
      melhor = i;
  return melhor;
}

static Veredito vazio(NivelEvidencia nivel) {
  Veredito v;
  memset(&v, 0, sizeof(v));
  v.resultado = RES_NAO_MEDIDO;
  v.nivel = nivel;
  return v;
}

/* ---------- o Cerco ---------- */

/* Escolhe, com peso pelo que ainda resta, um índice de `resta[0..n)` que não
 * seja `evitar` (quando há outro); -1 se não resta nada. */
static int sortear_resto(Sorteio *s, const int *resta, int n, int evitar) {
  int soma = 0, soma_sem = 0;
  for (int i = 0; i < n; i++) {
    soma += resta[i];
    if (i != evitar)
      soma_sem += resta[i];
  }
  if (!soma)
    return -1;
  bool pode_evitar = soma_sem > 0;
  int alvo = sorteio_entre(s, 0, (pode_evitar ? soma_sem : soma) - 1);
  for (int i = 0; i < n; i++) {
    if (pode_evitar && i == evitar)
      continue;
    if (alvo < resta[i])
      return i;
    alvo -= resta[i];
  }
  return -1;
}

int cegas_plano_tiros(Sorteio *s, const int *slots, int n, int por_lado, Tiro *out, int max) {
  /* um de cada vez, escolhendo o próximo alvo com peso pelo que falta a cada
   * um — assim ninguém fica com a rabeira de golpes seguidos no fim — e nunca
   * o mesmo alvo duas vezes seguidas quando há outro */
  int resta[8] = {0}, lados[8][2];
  if (n > 8)
    n = 8;
  for (int i = 0; i < n; i++) {
    resta[i] = 2 * por_lado;
    lados[i][0] = lados[i][1] = por_lado;
  }
  int total = 0, antes = -1;
  while (total < max) {
    int i = sortear_resto(s, resta, n, antes);
    if (i < 0)
      break;
    int lado = sorteio_entre(s, 0, lados[i][0] + lados[i][1] - 1) < lados[i][0] ? 0 : 1;
    lados[i][lado]--;
    resta[i]--;
    out[total++] = (Tiro){slots[i], (Lado)lado};
    antes = i;
  }
  return total;
}

Veredito cega_motor_veredito(const Cega *c, Lado lado, bool sdl_aceitou, bool reagiu) {
  const char *onde = lado == LADO_ESQ ? "esquerda" : "direita";
  const char *outro = lado == LADO_ESQ ? "direita" : "esquerda";
  const char *motor = lado == LADO_ESQ ? "o motor forte (esquerdo)" : "o motor fraco (direito)";
  Veredito v = vazio(NIVEL_SAIU);
  snprintf(v.pedido, sizeof(v.pedido), "sentir o golpe da %s — só %s — e levantar o escudo daquele lado, às cegas",
           onde, motor);
  if (!sdl_aceitou) {
    v.nivel = NIVEL_MONTOU;
    snprintf(v.medido, sizeof(v.medido), "o SDL recusou a vibração");
    snprintf(v.obs, sizeof(v.obs), "não medido: este controle não aceita vibração pelo SDL");
    return v;
  }
  int total = cega_total(c);
  snprintf(v.medido, sizeof(v.medido), "%d de %d golpes da %s bloqueados do lado certo; %d do lado errado; %d sem resposta",
           c->certos, total, onde, c->errados, c->perdidos);
  if (!total) {
    snprintf(v.obs, sizeof(v.obs), "não medido: nenhum golpe deste lado");
    return v;
  }
  if (!reagiu) {
    snprintf(v.obs, sizeof(v.obs), "não medido: ninguém levantou o escudo nesta sala");
    return v;
  }
  int precisa = total >= 5 ? (total * 4 + 4) / 5 : total; /* 80%, e tudo quando são poucos */
  v.nivel = NIVEL_OBEDECEU;
  if (c->certos >= precisa) {
    v.resultado = RES_PASSOU;
  } else if (c->errados >= 3 && c->errados >= c->certos) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "lado trocado: o golpe da %s parecia vir da %s — os motores chegam invertidos", onde,
             outro);
  } else if (c->perdidos >= 3 && c->perdidos > c->certos) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "%s não chega: os golpes da %s não foram sentidos", motor, onde);
  } else {
    v.nivel = NIVEL_SAIU;
    snprintf(v.obs, sizeof(v.obs), "não medido: inconclusivo (%d de %d) — refaça a sala com calma", c->certos, total);
  }
  return v;
}

Veredito cega_isolamento_veredito(int fantasmas, int chances, int vizinhos, const Cega *proprios) {
  Veredito v = vazio(NIVEL_SAIU);
  snprintf(v.pedido, sizeof(v.pedido), "levantar o escudo só quando o SEU controle vibrar, com os golpes indo um a um para "
                                       "cada controle da mesa");
  int meus = cega_total(proprios), sentidos = proprios->certos + proprios->errados;
  snprintf(v.medido, sizeof(v.medido), "levantou o escudo %d vez%s com o golpe indo para outro controle, em %d; sentiu %d dos "
           "%d golpes dele",
           fantasmas, fantasmas == 1 ? "" : "es", chances, sentidos, meus);
  if (vizinhos == 0) {
    snprintf(v.obs, sizeof(v.obs), "não medido: sozinho na mesa, não há outro controle para a vibração vazar");
    return v;
  }
  if (chances == 0 || meus == 0) {
    snprintf(v.obs, sizeof(v.obs), "não medido: sem golpes para comparar");
    return v;
  }
  v.nivel = NIVEL_OBEDECEU;
  if (fantasmas >= 3) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "este controle vibrou com golpes dos outros: a vibração não fica no controle certo");
  } else if (meus >= 4 && sentidos * 2 < meus) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "os golpes deste jogador não chegaram no controle dele (foram para outro?)");
  } else if (fantasmas <= 1 && sentidos * 5 >= meus * 3) {
    v.resultado = RES_PASSOU;
  } else {
    v.nivel = NIVEL_SAIU;
    snprintf(v.obs, sizeof(v.obs), "não medido: inconclusivo — refaça a sala com calma");
  }
  return v;
}

bool cega_cor_decidida(const Cega *c) { return c->certos >= 3 || c->errados >= 2 || cega_total(c) >= 5; }

Veredito cega_cor_veredito(const Cega *c, bool sdl_aceitou) {
  Veredito v = vazio(NIVEL_SAIU);
  snprintf(v.pedido, sizeof(v.pedido), "dizer, olhando o controle, de que cor está a luz — a tela não mostra");
  if (!sdl_aceitou) {
    v.nivel = NIVEL_MONTOU;
    snprintf(v.medido, sizeof(v.medido), "o SDL recusou a cor da lightbar");
    snprintf(v.obs, sizeof(v.obs), "não medido: este controle não aceita cor pelo SDL");
    return v;
  }
  snprintf(v.medido, sizeof(v.medido), "%d cor%s certa%s, %d errada%s, %d sem resposta", c->certos,
           c->certos == 1 ? "" : "es", c->certos == 1 ? "" : "s", c->errados, c->errados == 1 ? "" : "s", c->perdidos);
  if (c->certos + c->errados == 0) {
    snprintf(v.obs, sizeof(v.obs), "não medido: nenhuma pergunta de cor respondida");
    return v;
  }
  v.nivel = NIVEL_OBEDECEU;
  if (c->certos >= 3 && c->errados <= 1) {
    v.resultado = RES_PASSOU;
  } else if (c->errados >= 2 && c->errados >= c->certos) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "a cor que a pessoa viu no controle não era a que o jogo mandou");
  } else {
    v.nivel = NIVEL_SAIU;
    snprintf(v.obs, sizeof(v.obs), "não medido: inconclusivo — refaça a sala com calma");
  }
  return v;
}

/* ---------- a Galeria ---------- */

const char *cegas_nome_arma(Arma a) {
  switch (a) {
  case ARMA_PISTOLA:
    return "pistola";
  case ARMA_METRALHADORA:
    return "metralhadora";
  case ARMA_ARCO:
    return "arco";
  case ARMA_NENHUMA:
    return "sem arma";
  default:
    return "?";
  }
}

static const char *modo_da_arma(Arma a) {
  switch (a) {
  case ARMA_PISTOLA:
    return "Weapon: parede e clique";
  case ARMA_METRALHADORA:
    return "Vibration: o gatilho treme";
  case ARMA_ARCO:
    return "Feedback: resistência";
  default:
    return "Off: o gatilho solto";
  }
}

int cegas_plano_armas(Sorteio *s, int vezes, Arma *out, int max) {
  int resta[ARMA_TOTAL];
  for (int a = 0; a < ARMA_TOTAL; a++)
    resta[a] = vezes;
  int total = 0, antes = -1;
  while (total < max) {
    int a = sortear_resto(s, resta, ARMA_TOTAL, antes);
    if (a < 0)
      break;
    resta[a]--;
    out[total++] = (Arma)a;
    antes = a;
  }
  return total;
}

bool cega_arma_decidida(const Cega *c) {
  return (c->certos >= 2 && c->errados == 0) || c->certos >= 3 || c->errados >= 2 || cega_total(c) >= 4;
}

Veredito cega_arma_veredito(Arma arma, const Cega *c, const Cega *nenhuma, bool sdl_aceitou) {
  Veredito v = vazio(NIVEL_SAIU);
  snprintf(v.pedido, sizeof(v.pedido), "reconhecer a %s pelo gatilho R2, às cegas (%s)", cegas_nome_arma(arma),
           modo_da_arma(arma));
  if (!sdl_aceitou) {
    v.nivel = NIVEL_MONTOU;
    snprintf(v.medido, sizeof(v.medido), "o SDL recusou o efeito do gatilho");
    snprintf(v.obs, sizeof(v.obs), "não medido: este controle não aceita efeito de gatilho pelo SDL");
    return v;
  }
  int total = cega_total(c);
  snprintf(v.medido, sizeof(v.medido), "%d de %d vezes reconhecida", c->certos, total);
  int dito = mais_dito(c);
  if (dito >= 0) {
    char mais[96];
    snprintf(mais, sizeof(mais), "; pareceu %s %d×", cegas_nome_arma((Arma)dito), c->respondeu_como[dito]);
    size_t n = strlen(v.medido);
    snprintf(v.medido + n, sizeof(v.medido) - n, "%s", mais);
  }
  if (c->certos + c->errados == 0) {
    snprintf(v.obs, sizeof(v.obs), "não medido: nenhuma rodada desta arma respondida");
    return v;
  }
  v.nivel = NIVEL_OBEDECEU;
  if ((c->certos >= 2 && c->errados == 0) || (c->certos >= 3 && c->errados <= 1)) {
    v.resultado = RES_PASSOU;
  } else if (c->errados >= 2 && c->certos <= 1) {
    v.resultado = RES_FALHOU;
    if (dito == ARMA_NENHUMA)
      snprintf(v.obs, sizeof(v.obs), "o dedo não sentiu nada: o efeito não chega ao gatilho");
    else if (dito >= 0)
      snprintf(v.obs, sizeof(v.obs), "a %s pareceu %s: o modo chega trocado", cegas_nome_arma(arma),
               cegas_nome_arma((Arma)dito));
  } else {
    v.nivel = NIVEL_SAIU;
    snprintf(v.obs, sizeof(v.obs), "não medido: inconclusivo — refaça a sala com calma");
  }
  /* o gatilho que não solta aparece nas rodadas sem arma */
  if (nenhuma && nenhuma->errados >= 2 && nenhuma->errados > nenhuma->certos) {
    int preso = mais_dito(nenhuma);
    char nota[140];
    snprintf(nota, sizeof(nota), "%sO gatilho não solta: sem arma pareceu %s", v.obs[0] ? ". " : "",
             preso >= 0 ? cegas_nome_arma((Arma)preso) : "outra arma");
    size_t n = strlen(v.obs);
    snprintf(v.obs + n, sizeof(v.obs) - n, "%s", nota);
  }
  return v;
}

Veredito cega_leds_veredito(const Cega *c, bool sdl_aceitou) {
  Veredito v = vazio(NIVEL_SAIU);
  snprintf(v.pedido, sizeof(v.pedido), "contar a munição nos LEDs de jogador, embaixo do touchpad — a tela não mostra");
  if (!sdl_aceitou) {
    v.nivel = NIVEL_MONTOU;
    snprintf(v.medido, sizeof(v.medido), "o SDL recusou os LEDs de jogador");
    snprintf(v.obs, sizeof(v.obs), "não medido: este controle não aceita os LEDs de jogador pelo SDL");
    return v;
  }
  snprintf(v.medido, sizeof(v.medido), "%d contage%s certa%s, %d errada%s, %d sem resposta", c->certos,
           c->certos == 1 ? "m" : "ns", c->certos == 1 ? "" : "s", c->errados, c->errados == 1 ? "" : "s", c->perdidos);
  if (c->certos + c->errados == 0) {
    snprintf(v.obs, sizeof(v.obs), "não medido: nenhuma pergunta de munição respondida");
    return v;
  }
  v.nivel = NIVEL_OBEDECEU;
  if (c->certos >= 3 && c->errados * 4 <= c->certos) {
    v.resultado = RES_PASSOU;
  } else if (c->errados >= 3 && c->errados > c->certos) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "as luzes que a pessoa contou não batiam com a munição que o jogo mandou");
  } else {
    v.nivel = NIVEL_SAIU;
    snprintf(v.obs, sizeof(v.obs), "não medido: inconclusivo — refaça a sala com calma");
  }
  return v;
}
