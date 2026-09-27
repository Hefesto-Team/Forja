/* As provas às cegas. Ver cegas.h. */
#include "cegas.h"

#include "texto_buf.h"

#include <math.h>

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

/* ---------- as salas de som ---------- */

int cegas_plano_fontes(Sorteio *s, const int *fontes, const int *vezes, int n, int *out, int max) {
  int resta[16] = {0};
  if (n > 16)
    n = 16;
  for (int i = 0; i < n; i++)
    resta[i] = vezes[i];
  int total = 0, antes = -1;
  while (total < max) {
    int i = sortear_resto(s, resta, n, antes);
    if (i < 0)
      break;
    resta[i]--;
    out[total++] = fontes[i];
    antes = i;
  }
  return total;
}

Veredito cega_alto_falante_veredito(const Cega *meus, int fantasmas, int chances, bool tem) {
  Veredito v = vazio(NIVEL_SAIU);
  snprintf(v.pedido, sizeof(v.pedido), "dizer, a cada canto, se ele saiu no SEU controle — às vezes sai em outro, às "
                                       "vezes na TV");
  if (!tem) {
    v.nivel = NIVEL_NENHUM;
    snprintf(v.medido, sizeof(v.medido), "o alto-falante deste controle não foi achado");
    snprintf(v.obs, sizeof(v.obs), "não medido: nem pelo aparelho, nem pelo nome — aponte o alto-falante no aviso da sala");
    return v;
  }
  int total = cega_total(meus);
  snprintf(v.medido, sizeof(v.medido), "reconheceu o próprio canto %d de %d vezes; disse \"foi no meu\" %d vez%s com o "
           "canto em outro lugar, em %d",
           meus->certos, total, fantasmas, fantasmas == 1 ? "" : "es", chances);
  if (total == 0 || meus->certos + meus->errados == 0) {
    snprintf(v.obs, sizeof(v.obs), "não medido: nenhuma resposta nos cantos dele");
    return v;
  }
  v.nivel = NIVEL_OBEDECEU;
  if (fantasmas >= 2 && fantasmas * 2 >= chances) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "o canto de outro lugar saiu neste controle: o som não fica no alto-falante certo");
  } else if (meus->errados >= 2 && meus->errados >= meus->certos) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "o canto mandado para este controle não saiu no alto-falante dele");
  } else if (meus->certos >= 2 && meus->errados <= 1 && fantasmas <= 1) {
    v.resultado = RES_PASSOU;
  } else {
    v.nivel = NIVEL_SAIU;
    snprintf(v.obs, sizeof(v.obs), "não medido: inconclusivo — refaça a sala com calma");
  }
  return v;
}

Veredito cega_haptica_veredito(const Cega *chao, const Cega *le, const Cega *ld, bool tem) {
  Veredito v = vazio(NIVEL_SAIU);
  snprintf(v.pedido, sizeof(v.pedido), "reconhecer o chão pelos atuadores (canais 3 e 4), às cegas, e dizer de que lado foi "
                                       "o tropeço");
  if (!tem) {
    v.nivel = NIVEL_NENHUM;
    snprintf(v.medido, sizeof(v.medido), "a placa de quatro canais (ou a háptica) deste controle não foi achada");
    snprintf(v.obs, sizeof(v.obs), "não medido: sem os canais dos atuadores — no cabo, o controle é uma placa de quatro "
                                   "canais; aponte-a no aviso da sala");
    return v;
  }
  int n_chao = cega_total(chao), lados = cega_total(le) + cega_total(ld);
  int nada_chao = chao->respondeu_como[CAMINHO_NADA];
  int nada_esq = le->respondeu_como[CAMINHO_NADA_LADO], nada_dir = ld->respondeu_como[CAMINHO_NADA_LADO];
  /* trocado é dizer o lado oposto; "não senti" não é trocar */
  int trocados = le->respondeu_como[1] + ld->respondeu_como[0], certos_lado = le->certos + ld->certos;
  snprintf(v.medido, sizeof(v.medido),
           "chão: %d de %d certos, %d \"não senti\", %d sem resposta; tropeço: esquerda %d de %d, direita %d de %d",
           chao->certos, n_chao, nada_chao, chao->perdidos, le->certos, cega_total(le), ld->certos, cega_total(ld));
  if (chao->certos + chao->errados == 0 && le->certos + le->errados + ld->certos + ld->errados == 0) {
    snprintf(v.obs, sizeof(v.obs), "não medido: nenhuma resposta");
    return v;
  }
  v.nivel = NIVEL_OBEDECEU;
  if (nada_chao >= 3 && nada_chao * 2 >= n_chao) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "a mão não sentiu os passos (disse \"não senti\" %d vezes): a háptica não chega aos "
                                   "atuadores", nada_chao);
  } else if (lados >= 4 && trocados >= 3 && trocados > certos_lado) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "os lados chegam trocados: o canal 3 (esquerda) sai na direita e vice-versa");
  } else if ((nada_esq >= 2 && le->certos == 0) != (nada_dir >= 2 && ld->certos == 0)) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "o tropeço da %s nunca chegou: o atuador desse lado (o canal %d) não recebe",
             nada_esq >= 2 ? "esquerda" : "direita", nada_esq >= 2 ? 3 : 4);
  } else if (n_chao >= 6 && chao->certos * 2 < n_chao && chao->errados - nada_chao >= 3) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "os chãos não se distinguem: a textura chega deformada (ou achatada) nos atuadores");
  } else if (chao->certos * 4 >= n_chao * 3 && (lados == 0 || certos_lado * 5 >= lados * 4)) {
    v.resultado = RES_PASSOU;
  } else {
    v.nivel = NIVEL_SAIU;
    snprintf(v.obs, sizeof(v.obs), "não medido: inconclusivo — refaça a sala com calma");
  }
  return v;
}

bool cega_led_mic_decidida(const Cega *c) { return cega_cor_decidida(c); }

Veredito cega_led_mic_veredito(const Cega *c, bool sdl_aceitou) {
  Veredito v = cega_cor_veredito(c, sdl_aceitou);
  snprintf(v.pedido, sizeof(v.pedido), "dizer, olhando o controle, se a luz laranja do microfone está apagada, acesa ou "
                                       "piscando — a tela não mostra");
  if (v.resultado == RES_FALHOU)
    snprintf(v.obs, sizeof(v.obs), "a luz do microfone que a pessoa viu não era a que o jogo mandou");
  if (!sdl_aceitou) {
    snprintf(v.medido, sizeof(v.medido), "o SDL recusou o LED do microfone");
    snprintf(v.obs, sizeof(v.obs), "não medido: este controle não aceita o LED do microfone pelo SDL");
  } else {
    char *p = strstr(v.medido, " cor");
    if (p) /* "3 cores certas" vira "3 respostas certas" */
      snprintf(v.medido, sizeof(v.medido), "%d resposta%s certa%s, %d errada%s, %d sem resposta", c->certos,
               c->certos == 1 ? "" : "s", c->certos == 1 ? "" : "s", c->errados, c->errados == 1 ? "" : "s", c->perdidos);
  }
  return v;
}

/* ---------- A Prova ---------- */

Veredito cega_tudo_junto_veredito(const MedCarga *m, const Cega *leds, const Cega *cor, bool mexeu) {
  Veredito v = vazio(NIVEL_SAIU);
  snprintf(v.pedido, sizeof(v.pedido), "jogar a partida com tudo ligado — vibração, luz, gatilhos, LEDs, háptica e "
                                       "sensores ao mesmo tempo — e, no fim, dizer as luzinhas e a cor do controle");
  int hz = m->tem_giro && m->segundos > 0 ? (int)lround(m->amostras_giro / m->segundos) : 0;
  int certos = leds->certos + cor->certos, errados = leds->errados + cor->errados;
  char giro[96], parada[16];
  num_pt(parada, sizeof(parada), m->maior_parada, 1);
  if (m->tem_giro)
    snprintf(giro, sizeof(giro), "giroscópio a %d Hz, a maior parada %s s", hz, parada);
  else
    snprintf(giro, sizeof(giro), "sem giroscópio");
  snprintf(v.medido, sizeof(v.medido), "%s; %d saídas, %d recusadas; no fim: luzinhas %d de %d, cor %d de %d", giro,
           m->saidas, m->recusadas, leds->certos, cega_total(leds), cor->certos, cega_total(cor));
  if (!mexeu) {
    v.nivel = NIVEL_NENHUM;
    snprintf(v.obs, sizeof(v.obs), "não medido: o controle não jogou a partida");
    return v;
  }
  if (m->saidas > 0 && m->recusadas == m->saidas) {
    v.nivel = NIVEL_MONTOU;
    snprintf(v.obs, sizeof(v.obs), "não medido: o SDL recusou todas as saídas deste controle");
    return v;
  }
  v.nivel = certos + errados > 0 ? NIVEL_OBEDECEU : NIVEL_SAIU;
  if (m->paradas >= 1) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "a entrada parou no meio da carga (%d vez%s, a maior de %s s): o controle engasga com "
                                   "tudo ligado", m->paradas, m->paradas == 1 ? "" : "es", parada);
  } else if (m->recusadas > 0) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "o SDL recusou %d de %d saídas no meio da partida", m->recusadas, m->saidas);
  } else if (m->tem_giro && m->segundos >= 10 && hz < 60) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "com tudo ligado, o giroscópio caiu para %d Hz (o mínimo é 60)", hz);
  } else if (errados >= 2 && certos == 0) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "com tudo ligado, as luzinhas e a cor não eram as que o jogo mandou");
  } else if (certos >= 2 && errados == 0) {
    v.resultado = RES_PASSOU;
  } else if (certos + errados == 0) {
    snprintf(v.obs, sizeof(v.obs), "não medido: a prova final ficou sem resposta");
  } else {
    snprintf(v.obs, sizeof(v.obs), "não medido: inconclusivo — refaça a sala com calma");
  }
  return v;
}
