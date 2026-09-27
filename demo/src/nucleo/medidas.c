/* As medidas das salas de entrada. Ver medidas.h. */
#include "medidas.h"

#include "texto_buf.h"

#include <math.h>
#include <stdio.h>
#include <string.h>

#define PI_F 3.14159265f

/* número com vírgula, num de oito buffers rotativos (cabe numa linha de printf) */
static const char *dec(double v, int casas) {
  static char buf[8][32];
  static int i;
  i = (i + 1) % 8;
  return num_pt(buf[i], sizeof(buf[i]), v, casas);
}

static Veredito vazio(void) {
  Veredito v;
  memset(&v, 0, sizeof(v));
  v.resultado = RES_NAO_MEDIDO;
  return v;
}

static void juntar(char *dst, size_t tam, const char *s) {
  size_t n = strlen(dst);
  if (n + 1 < tam)
    snprintf(dst + n, tam - n, "%s", s);
}

/* ---------- botões ---------- */

int med_botoes_contar(uint32_t m) {
  int n = 0;
  for (; m; m >>= 1)
    n += (int)(m & 1u);
  return n;
}

void med_botoes_iniciar(MedBotoes *m, uint32_t pedidos, const char *const *nomes) {
  memset(m, 0, sizeof(*m));
  m->pedidos = pedidos;
  m->nomes = nomes;
  for (int i = 0; i < MED_MAX_BOTOES; i++)
    m->trocado_por[i] = -1;
}

void med_botoes_apertou(MedBotoes *m, int botao, int pedido) {
  if (botao < 0 || botao >= MED_MAX_BOTOES)
    return;
  m->chegaram |= 1u << botao;
  if (pedido < 0 || pedido >= MED_MAX_BOTOES)
    return;
  if (botao == pedido) {
    m->na_hora |= 1u << botao;
  } else {
    m->trocas[pedido]++;
    m->trocado_por[pedido] = botao;
  }
}

void med_botoes_mostrou(MedBotoes *m, int botao) {
  if (botao >= 0 && botao < MED_MAX_BOTOES)
    m->mostrados |= 1u << botao;
}

static const char *nome_botao(const MedBotoes *m, int b) {
  if (m->nomes && m->nomes[b])
    return m->nomes[b];
  static char tmp[16];
  snprintf(tmp, sizeof(tmp), "botão %d", b);
  return tmp;
}

Veredito med_botoes_veredito(const MedBotoes *m, bool mexeu) {
  Veredito v = vazio();
  int total = med_botoes_contar(m->pedidos);
  snprintf(v.pedido, sizeof(v.pedido), "apertar %d botões, cada um quando a runa dele acende", total);
  uint32_t chegaram = m->chegaram & m->pedidos;
  uint32_t na_hora = m->na_hora & m->pedidos;
  if (!mexeu && !chegaram) {
    snprintf(v.medido, sizeof(v.medido), "nada chegou deste controle na sala");
    snprintf(v.obs, sizeof(v.obs), "não medido: o controle não mexeu nesta sala");
    return v;
  }
  snprintf(v.medido, sizeof(v.medido), "%d de %d chegaram; %d na hora da runa", med_botoes_contar(chegaram), total,
           med_botoes_contar(na_hora));

  /* o que faltou, o que a sala nem chegou a pedir, e o que chegou trocado */
  char faltaram[200] = "", nao_pedidos[200] = "", trocados[240] = "";
  bool falhou = false;
  for (int b = 0; b < MED_MAX_BOTOES; b++) {
    if (!(m->pedidos & (1u << b)))
      continue;
    if (!(chegaram & (1u << b)) && !(m->mostrados & (1u << b))) {
      juntar(nao_pedidos, sizeof(nao_pedidos), nao_pedidos[0] ? ", " : "");
      juntar(nao_pedidos, sizeof(nao_pedidos), nome_botao(m, b));
    } else if (!(chegaram & (1u << b))) {
      falhou = true;
      juntar(faltaram, sizeof(faltaram), faltaram[0] ? ", " : "");
      juntar(faltaram, sizeof(faltaram), nome_botao(m, b));
    } else if (!(na_hora & (1u << b)) && m->trocas[b] >= 2 && m->trocado_por[b] >= 0) {
      /* chegou, mas nunca na hora; e no lugar dele chegava outro: o mapa troca */
      falhou = true;
      char um[80];
      snprintf(um, sizeof(um), "%s%s pedia, chegava %s (%d×)", trocados[0] ? "; " : "", nome_botao(m, b),
               nome_botao(m, m->trocado_por[b]), m->trocas[b]);
      juntar(trocados, sizeof(trocados), um);
    }
  }
  if (faltaram[0]) {
    juntar(v.medido, sizeof(v.medido), "; nunca chegaram: ");
    juntar(v.medido, sizeof(v.medido), faltaram);
  }
  if (trocados[0]) {
    juntar(v.medido, sizeof(v.medido), "; trocados: ");
    juntar(v.medido, sizeof(v.medido), trocados);
    snprintf(v.obs, sizeof(v.obs), "um botão físico chega ao jogo como outro: o mapa dos botões está trocado");
  } else if (faltaram[0]) {
    snprintf(v.obs, sizeof(v.obs), "a sala pediu e o controle estava vivo, mas esses botões nunca chegaram");
  } else if (nao_pedidos[0]) {
    snprintf(v.obs, sizeof(v.obs), "não medido: a sala acabou antes de pedir %s", nao_pedidos);
    v.resultado = RES_NAO_MEDIDO;
    return v;
  } else if (na_hora != m->pedidos) {
    snprintf(v.obs, sizeof(v.obs), "todos chegaram; alguns só fora da hora da runa, sem sinal de troca");
  }
  v.resultado = falhou ? RES_FALHOU : RES_PASSOU;
  return v;
}

/* ---------- analógicos ---------- */

void med_analogico_iniciar(MedAnalogico *m) {
  memset(m, 0, sizeof(*m));
  m->repouso_min = 2;
}

void med_analogico_repouso(MedAnalogico *m, float x, float y) {
  float d = sqrtf(x * x + y * y);
  if (d < m->repouso_min)
    m->repouso_min = d;
  m->viu_repouso = true;
}

int med_analogico_setor(float x, float y) {
  float a = atan2f(y, x); /* y para baixo, como o SDL: sentido horário na tela */
  int s = (int)lroundf(a / (PI_F / 4));
  return ((s % 8) + 8) % 8;
}

void med_analogico_amostra(MedAnalogico *m, float x, float y) {
  float d = sqrtf(x * x + y * y);
  if (d > m->maximo)
    m->maximo = d;
  if (d > 0.5f)
    m->mexeu = true;
  if (d >= MED_BORDA)
    m->setores |= (uint8_t)(1u << med_analogico_setor(x, y));
}

int med_analogico_setores(const MedAnalogico *m) { return med_botoes_contar(m->setores); }

/* 1 passou, 0 falhou, -1 não pedido (a sala acabou antes do círculo dele) */
static int um_analogico(const MedAnalogico *m, const char *nome, char *medido, size_t tm, char *obs, size_t to) {
  int n = med_analogico_setores(m);
  char um[200];
  snprintf(um, sizeof(um), "%s%s: %d de 8 direções na borda, máximo %s%%", medido[0] ? "; " : "", nome, n,
           dec(m->maximo * 100, 0));
  juntar(medido, tm, um);
  if (m->viu_repouso && m->repouso_min > 0.12f && m->repouso_min < 1.5f) {
    snprintf(um, sizeof(um), "%sderiva: o %s fica em %s%% quando solto", obs[0] ? "; " : "", nome,
             dec(m->repouso_min * 100, 0));
    juntar(obs, to, um);
  }
  if (!m->mexeu && !m->pedido)
    return -1;
  if (!m->mexeu) {
    snprintf(um, sizeof(um), "%so %s nunca se mexeu", obs[0] ? "; " : "", nome);
    juntar(obs, to, um);
    return 0;
  }
  if (n < 8) {
    if (!m->pedido)
      return -1;
    snprintf(um, sizeof(um), "%so %s não chegou à borda em todas as direções", obs[0] ? "; " : "", nome);
    juntar(obs, to, um);
    return 0;
  }
  return 1;
}

Veredito med_analogicos_veredito(const MedAnalogico *e, const MedAnalogico *d, bool mexeu) {
  Veredito v = vazio();
  snprintf(v.pedido, sizeof(v.pedido), "desenhar o círculo com cada analógico, até a borda");
  if (!mexeu && !e->mexeu && !d->mexeu) {
    snprintf(v.medido, sizeof(v.medido), "nada chegou deste controle na sala");
    snprintf(v.obs, sizeof(v.obs), "não medido: o controle não mexeu nesta sala");
    return v;
  }
  int ok_e = um_analogico(e, "esquerdo", v.medido, sizeof(v.medido), v.obs, sizeof(v.obs));
  int ok_d = um_analogico(d, "direito", v.medido, sizeof(v.medido), v.obs, sizeof(v.obs));
  if (ok_e == 0 || ok_d == 0) {
    v.resultado = RES_FALHOU;
  } else if (ok_e < 0 || ok_d < 0) {
    v.resultado = RES_NAO_MEDIDO;
    juntar(v.obs, sizeof(v.obs), v.obs[0] ? "; " : "");
    juntar(v.obs, sizeof(v.obs), "não medido: a sala acabou antes de pedir o círculo");
  } else {
    v.resultado = RES_PASSOU;
  }
  return v;
}

/* ---------- gatilhos analógicos ---------- */

void med_gatilho_iniciar(MedGatilho *m) {
  memset(m, 0, sizeof(*m));
  m->minimo = 2;
}

void med_gatilho_amostra(MedGatilho *m, float v) {
  if (v < 0)
    v = 0;
  if (v > 1)
    v = 1;
  if (v < m->minimo)
    m->minimo = v;
  if (v > m->maximo)
    m->maximo = v;
  if (v > 0.2f)
    m->mexeu = true;
  int nivel = (int)lroundf(v * 255);
  m->niveis[nivel / 8] |= (uint8_t)(1u << (nivel % 8));
}

int med_gatilho_niveis(const MedGatilho *m) {
  int n = 0;
  for (int i = 0; i < 32; i++)
    n += med_botoes_contar(m->niveis[i]);
  return n;
}

/* 1 passou, 0 falhou, -1 não pedido */
static int um_gatilho(const MedGatilho *m, const char *nome, char *medido, size_t tm, char *obs, size_t to) {
  int niveis = med_gatilho_niveis(m);
  char um[200];
  float minimo = m->minimo > 1 ? 0 : m->minimo;
  snprintf(um, sizeof(um), "%s%s: de %s%% a %s%%, %d níveis", medido[0] ? "; " : "", nome, dec(minimo * 100, 0),
           dec(m->maximo * 100, 0), niveis);
  juntar(medido, tm, um);
  const char *problema = NULL;
  char tmp[120];
  if (!m->mexeu && !m->pedido)
    return -1;
  if (!m->mexeu) {
    problema = "nunca se mexeu";
  } else if (m->maximo >= 0.9f && niveis <= 3) {
    problema = "chegou digital: só solto e no fundo, sem o meio";
  } else if (m->maximo < 0.9f) {
    snprintf(tmp, sizeof(tmp), "não chega ao fundo (máximo %s%%)", dec(m->maximo * 100, 0));
    problema = tmp;
  } else if (minimo > 0.08f) {
    snprintf(tmp, sizeof(tmp), "não volta ao zero (mínimo %s%%)", dec(minimo * 100, 0));
    problema = tmp;
  } else if (niveis < 8) {
    snprintf(tmp, sizeof(tmp), "poucos níveis no meio do curso (%d)", niveis);
    problema = tmp;
  }
  if (!problema)
    return 1;
  snprintf(um, sizeof(um), "%so %s %s", obs[0] ? "; " : "", nome, problema);
  juntar(obs, to, um);
  return 0;
}

Veredito med_gatilhos_veredito(const MedGatilho *l2, const MedGatilho *r2, bool mexeu) {
  Veredito v = vazio();
  snprintf(v.pedido, sizeof(v.pedido), "encher o fole com L2 e com R2: segurar no meio, depois até o fundo");
  if (!mexeu && !l2->mexeu && !r2->mexeu) {
    snprintf(v.medido, sizeof(v.medido), "nada chegou deste controle na sala");
    snprintf(v.obs, sizeof(v.obs), "não medido: o controle não mexeu nesta sala");
    return v;
  }
  int ok_l = um_gatilho(l2, "L2", v.medido, sizeof(v.medido), v.obs, sizeof(v.obs));
  int ok_r = um_gatilho(r2, "R2", v.medido, sizeof(v.medido), v.obs, sizeof(v.obs));
  if (ok_l == 0 || ok_r == 0) {
    v.resultado = RES_FALHOU;
  } else if (ok_l < 0 || ok_r < 0) {
    v.resultado = RES_NAO_MEDIDO;
    juntar(v.obs, sizeof(v.obs), v.obs[0] ? "; " : "");
    juntar(v.obs, sizeof(v.obs), "não medido: a sala acabou antes de pedir o fole");
  } else {
    v.resultado = RES_PASSOU;
  }
  return v;
}

/* ---------- touchpad ---------- */

void med_toque_iniciar(MedToque *m) {
  memset(m, 0, sizeof(*m));
  m->x_min = m->y_min = 2;
  m->x_max = m->y_max = -1;
}

float med_toque_distancia(float x0, float y0, float x1, float y1) {
  float dx = (x1 - x0) * MED_TOQUE_ASPECTO, dy = y1 - y0;
  return sqrtf(dx * dx + dy * dy) / MED_TOQUE_ASPECTO;
}

void med_toque_amostra(MedToque *m, const bool baixo[2], const float x[2], const float y[2]) {
  int n = 0;
  for (int d = 0; d < 2; d++) {
    if (!baixo[d])
      continue;
    n++;
    m->tocou = true;
    if (x[d] < m->x_min)
      m->x_min = x[d];
    if (x[d] > m->x_max)
      m->x_max = x[d];
    if (y[d] < m->y_min)
      m->y_min = y[d];
    if (y[d] > m->y_max)
      m->y_max = y[d];
  }
  if (n > m->max_dedos)
    m->max_dedos = n;
  if (n == 2) {
    float dist = med_toque_distancia(x[0], y[0], x[1], y[1]);
    if (dist > m->abertura_max)
      m->abertura_max = dist;
    if (dist >= 0.45f)
      m->abriu = true;
    else if (m->abriu && dist <= 0.15f)
      m->fechou = true;
  }
  m->amostras++;
}

void med_toque_clique(MedToque *m) { m->clicou = true; }

Veredito med_toque_dedos_veredito(const MedToque *m, bool mexeu) {
  Veredito v = vazio();
  snprintf(v.pedido, sizeof(v.pedido), "traçar a runa com um dedo e abrir e fechar o molde com dois");
  if (!m->tocou) {
    snprintf(v.medido, sizeof(v.medido), "nenhum toque chegou");
    if (mexeu) {
      v.resultado = RES_FALHOU;
      snprintf(v.obs, sizeof(v.obs), "a sala pediu e o controle estava vivo, mas nenhum toque chegou");
    } else {
      snprintf(v.obs, sizeof(v.obs), "não medido: o controle não mexeu nesta sala");
    }
    return v;
  }
  float lx = m->x_max - m->x_min, ly = m->y_max - m->y_min;
  snprintf(v.medido, sizeof(v.medido), "até %d dedo%s ao mesmo tempo; cobriu %s%% da largura e %s%% da altura; abertura máxima %s%%",
           m->max_dedos, m->max_dedos == 1 ? "" : "s", dec(lx * 100, 0), dec(ly * 100, 0), dec(m->abertura_max * 100, 0));
  if (m->max_dedos < 2 && !m->pediu_dois) {
    v.resultado = RES_NAO_MEDIDO;
    snprintf(v.obs, sizeof(v.obs), "não medido: a sala não chegou ao passo dos dois dedos");
  } else if (m->max_dedos < 2) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "só um dedo chega ao jogo: o segundo dedo se perde no caminho");
  } else if (!m->tracou) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "a letra não foi completada: algum canto do touchpad não chega ao jogo?");
  } else if (lx < 0.6f || ly < 0.45f) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "os toques só cobriram parte do touchpad: a escala ou o recorte das coordenadas está errado");
  } else if (!m->abriu || !m->fechou) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "dois dedos chegaram, mas não se viu abrir e fechar (os dois dedos não andam separados?)");
  } else {
    v.resultado = RES_PASSOU;
  }
  return v;
}

Veredito med_toque_clique_veredito(const MedToque *m, bool mexeu) {
  Veredito v = vazio();
  snprintf(v.pedido, sizeof(v.pedido), "carimbar o molde com o clique do touchpad");
  if (m->clicou) {
    v.resultado = RES_PASSOU;
    snprintf(v.medido, sizeof(v.medido), "o clique do touchpad chegou");
  } else if (!m->pediu_clique) {
    snprintf(v.medido, sizeof(v.medido), "nenhum clique chegou");
    snprintf(v.obs, sizeof(v.obs), "não medido: a sala não chegou ao carimbo");
  } else if (mexeu) {
    v.resultado = RES_FALHOU;
    snprintf(v.medido, sizeof(v.medido), "o clique do touchpad nunca chegou");
    snprintf(v.obs, sizeof(v.obs), "a sala pediu e o controle estava vivo, mas o clique não chegou");
  } else {
    snprintf(v.medido, sizeof(v.medido), "nada chegou deste controle na sala");
    snprintf(v.obs, sizeof(v.obs), "não medido: o controle não mexeu nesta sala");
  }
  return v;
}

/* ---------- giroscópio e acelerômetro ---------- */

#define G_PADRAO 9.80665f
#define GIRO_EIXO_MIN 0.5f /* rad/s: um eixo que não passou disso não foi girado (o ruído parado é ~0,02) */
#define GIRO_PARADO 0.15f  /* rad/s: abaixo disso o controle está parado */

void med_sensores_iniciar(MedSensores *m, bool tem_giro, bool tem_acel, double hz_declarado) {
  memset(m, 0, sizeof(*m));
  m->tem_giro = tem_giro;
  m->tem_acel = tem_acel;
  m->hz_declarado = hz_declarado;
}

void med_sensores_amostra(MedSensores *m, const float giro[3], const float acel[3]) {
  float gira = 0;
  if (m->tem_giro && giro) {
    for (int e = 0; e < 3; e++) {
      float v = fabsf(giro[e]);
      if (v > m->giro_max[e])
        m->giro_max[e] = v;
      gira += v;
    }
  }
  if (m->tem_acel && acel) {
    float g = sqrtf(acel[0] * acel[0] + acel[1] * acel[1] + acel[2] * acel[2]) / G_PADRAO;
    if (g > m->g_pico)
      m->g_pico = g;
    if (!m->tem_giro || gira < GIRO_PARADO) {
      int faixa = (int)(g / 0.05f);
      if (faixa > 79)
        faixa = 79;
      if (m->g_parado[faixa] < 0xFFFF)
        m->g_parado[faixa]++;
      m->g_parado_n++;
    }
    if (g > 0.8f && g < 1.2f) {
      float r = atan2f(acel[0], sqrtf(acel[1] * acel[1] + acel[2] * acel[2]));
      if (!m->viu_rolagem || r < m->rolagem_min)
        m->rolagem_min = r;
      if (!m->viu_rolagem || r > m->rolagem_max)
        m->rolagem_max = r;
      m->viu_rolagem = true;
    }
  }
}

void med_sensores_martelada(MedSensores *m) { m->marteladas++; }

double med_sensores_g_parado(const MedSensores *m) {
  long total = 0;
  for (int i = 0; i < 80; i++)
    total += m->g_parado[i];
  if (!total)
    return 0;
  long meio = (total + 1) / 2, conta = 0;
  for (int i = 0; i < 80; i++) {
    conta += m->g_parado[i];
    if (conta >= meio)
      return (i + 0.5) * 0.05;
  }
  return 0;
}

static const char *nome_sinal(int s) { return s > 0 ? "concorda" : s < 0 ? "INVERTIDO" : "sem movimento para dizer"; }

Veredito med_giro_veredito(const MedSensores *m, bool mexeu) {
  Veredito v = vazio();
  snprintf(v.pedido, sizeof(v.pedido), "equilibrar (rolagem) e mirar (guinada e arfagem) girando o controle");
  if (!m->tem_giro) {
    snprintf(v.medido, sizeof(v.medido), "o controle não publica giroscópio");
    snprintf(v.obs, sizeof(v.obs), "não medido: sem giroscópio, a sala jogou com o analógico");
    return v;
  }
  if (m->amostras_giro <= 0) {
    v.resultado = RES_FALHOU;
    snprintf(v.medido, sizeof(v.medido), "declarado %s Hz, mas nenhuma amostra chegou", dec(m->hz_declarado, 0));
    snprintf(v.obs, sizeof(v.obs), "o controle diz ter giroscópio e não manda nada");
    return v;
  }
  snprintf(v.medido, sizeof(v.medido),
           "declarado %s Hz · medido %s Hz (host) · %s Hz (relógio do controle); pico X %s, Y %s, Z %s rad/s; "
           "sinal: rolagem %s, arfagem %s",
           dec(m->hz_declarado, 0), dec(m->hz_host, 1), dec(m->hz_relogio, 1), dec(m->giro_max[0], 1),
           dec(m->giro_max[1], 1), dec(m->giro_max[2], 1), nome_sinal(m->sinal[0]), nome_sinal(m->sinal[1]));
  static const char *EIXO[3] = {"X (arfagem)", "Y (guinada)", "Z (rolagem)"};
  if (m->sinal[0] < 0 || m->sinal[1] < 0) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "o giro anda ao contrário da gravidade na %s: um eixo do giroscópio chega invertido",
             m->sinal[0] < 0 ? "rolagem" : "arfagem");
    return v;
  }
  for (int e = 0; e < 3; e++)
    if (m->giro_max[e] < GIRO_EIXO_MIN) {
      /* guinada e arfagem são da mira: se a sala não chegou aos sinos, não pediu */
      bool pedido = e == 2 || m->pediu_mira;
      v.resultado = mexeu && pedido ? RES_FALHOU : RES_NAO_MEDIDO;
      if (pedido)
        snprintf(v.obs, sizeof(v.obs), "o eixo %s nunca passou de %s rad/s", EIXO[e], dec(GIRO_EIXO_MIN, 1));
      else
        snprintf(v.obs, sizeof(v.obs), "não medido: a sala não chegou à mira (guinada e arfagem)");
      return v;
    }
  if (m->hz_host > 0 && m->hz_host < 60) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "chegam só %s amostras por segundo: pouco para mirar", dec(m->hz_host, 0));
    return v;
  }
  v.resultado = RES_PASSOU;
  if (m->hz_declarado > 0 && m->hz_host > 0 && fabs(m->hz_host - m->hz_declarado) / m->hz_declarado > 0.2)
    snprintf(v.obs, sizeof(v.obs), "a taxa medida difere da declarada em %s%%",
             dec(fabs(m->hz_host - m->hz_declarado) / m->hz_declarado * 100, 0));
  return v;
}

Veredito med_acel_veredito(const MedSensores *m, bool mexeu) {
  Veredito v = vazio();
  snprintf(v.pedido, sizeof(v.pedido), "inclinar para os lados e dar a martelada (sacudir para baixo)");
  if (!m->tem_acel) {
    snprintf(v.medido, sizeof(v.medido), "o controle não publica acelerômetro");
    snprintf(v.obs, sizeof(v.obs), "não medido: sem acelerômetro, a martelada foi com o botão");
    return v;
  }
  if (m->amostras_acel <= 0) {
    v.resultado = RES_FALHOU;
    snprintf(v.medido, sizeof(v.medido), "nenhuma amostra chegou");
    snprintf(v.obs, sizeof(v.obs), "o controle diz ter acelerômetro e não manda nada");
    return v;
  }
  double parado = med_sensores_g_parado(m);
  float graus_min = m->rolagem_min * 180 / PI_F, graus_max = m->rolagem_max * 180 / PI_F;
  snprintf(v.medido, sizeof(v.medido), "parado %s g; inclinou de %s° a %s°; pico %s g; %d martelada%s",
           dec(parado, 1), dec(graus_min, 0), dec(graus_max, 0), dec(m->g_pico, 1), m->marteladas,
           m->marteladas == 1 ? "" : "s");
  if (m->g_parado_n > 0 && (parado < 0.85 || parado > 1.15)) {
    v.resultado = RES_FALHOU;
    snprintf(v.obs, sizeof(v.obs), "parado, o controle mede %s g (o certo é 1 g): a escala do acelerômetro está errada",
             dec(parado, 1));
    return v;
  }
  if (!m->viu_rolagem || graus_max - graus_min < 20) {
    v.resultado = mexeu ? RES_FALHOU : RES_NAO_MEDIDO;
    snprintf(v.obs, sizeof(v.obs), "a inclinação medida pela gravidade não passou de %s°", dec(graus_max - graus_min, 0));
    return v;
  }
  if (m->marteladas == 0 && !m->pediu_martelada) {
    v.resultado = RES_NAO_MEDIDO;
    snprintf(v.obs, sizeof(v.obs), "não medido: a sala não chegou à pedra (a martelada)");
    return v;
  }
  if (m->marteladas == 0) {
    v.resultado = mexeu ? RES_FALHOU : RES_NAO_MEDIDO;
    snprintf(v.obs, sizeof(v.obs), "a martelada (um pico acima de 1,8 g) nunca chegou");
    return v;
  }
  v.resultado = RES_PASSOU;
  return v;
}
