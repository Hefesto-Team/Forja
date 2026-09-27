/* A postura do controle e as medidas das salas de entrada: o que a sala decide
 * a partir do que chegou. Entradas sintéticas, nenhum aparelho. */
#include "prova.h"

#include "medidas.h"
#include "postura.h"
#include "texto_buf.h"

#include <math.h>

#define PI_F 3.14159265f

static bool perto(float a, float b, float tol) { return fabsf(a - b) <= tol; }

/* A gravidade que um controle parado lê com rolagem `r` e arfagem `p`. */
static void gravidade(float r, float p, float a[3]) {
  a[0] = POSTURA_G * sinf(r) * cosf(p);
  a[1] = POSTURA_G * cosf(r) * cosf(p);
  a[2] = -POSTURA_G * sinf(p);
}

/* Gira de verdade em rolagem com `taxa` rad/s por `seg` segundos a 250 Hz; o
 * giroscópio relata `taxa * sinal_giro` (sinal -1 = eixo invertido). */
static void girar_rolagem(Postura *p, float *verdade, float taxa, float seg, float sinal_giro, uint64_t *ns) {
  int passos = (int)(seg * 250);
  for (int i = 0; i < passos; i++) {
    *verdade += taxa / 250.0f;
    *ns += 4000000ull;
    float a[3], g[3] = {0, 0, taxa * sinal_giro};
    gravidade(*verdade, 0, a);
    postura_acel(p, a);
    postura_giro(p, g, *ns, *ns);
  }
}

void provas_postura(void) {
  Postura p;
  float a[3], g0[3] = {0, 0, 0};

  postura_zerar(&p);
  gravidade(0, 0, a);
  espera(perto(postura_g(a), 1.0f, 0.001f), "parado mede 1 g");
  espera(perto(postura_rolagem_da_gravidade(a), 0, 0.001f), "parado: rolagem 0");
  espera(perto(postura_arfagem_da_gravidade(a), 0, 0.001f), "parado: arfagem 0");

  /* as convenções do SDL: o lado direito erguido dá X positivo */
  gravidade(0.5f, 0, a);
  espera(a[0] > 0 && perto(postura_rolagem_da_gravidade(a), 0.5f, 0.001f), "rolagem pela gravidade");
  gravidade(0, 0.4f, a);
  espera(a[2] < 0 && perto(postura_arfagem_da_gravidade(a), 0.4f, 0.001f), "arfagem pela gravidade");

  /* a primeira gravidade põe o controle onde ele está */
  postura_zerar(&p);
  gravidade(0.52f, 0, a);
  postura_acel(&p, a);
  espera(perto(p.rolagem, 0.52f, 0.01f), "começa na inclinação da gravidade, não no zero");

  /* girar de verdade: o giro integrado acompanha, e o sinal concorda */
  postura_zerar(&p);
  uint64_t ns = 1000000000ull;
  float verdade = 0;
  gravidade(0, 0, a);
  postura_acel(&p, a);
  girar_rolagem(&p, &verdade, 1.0f, 0.6f, 1, &ns);
  espera(perto(p.rolagem, verdade, 0.05f), "a rolagem fundida acompanha a verdadeira");
  girar_rolagem(&p, &verdade, -1.2f, 0.9f, 1, &ns);
  girar_rolagem(&p, &verdade, 1.2f, 0.9f, 1, &ns);
  espera(perto(p.rolagem, verdade, 0.05f), "e volta com ela");
  espera(postura_sinal(&p, 0) == 1, "o giro concorda com a gravidade");
  espera(postura_sinal(&p, 1) == 0, "sem arfagem, a arfagem não tem veredito");

  /* o giroscópio invertido: gira para um lado, a gravidade vai para o outro */
  postura_zerar(&p);
  verdade = 0;
  gravidade(0, 0, a);
  postura_acel(&p, a);
  for (int k = 0; k < 3; k++) {
    girar_rolagem(&p, &verdade, 1.2f, 0.9f, -1, &ns);
    girar_rolagem(&p, &verdade, -1.2f, 0.9f, -1, &ns);
  }
  espera(postura_sinal(&p, 0) == -1, "o eixo invertido aparece");
  espera(p.discorda[0] >= 3, "janela a janela");

  /* um buraco no relógio (pausa, reconexão) não vira giro */
  postura_zerar(&p);
  float g1[3] = {0, 0, 2.0f};
  postura_giro(&p, g1, 1000000000ull, 0);
  postura_giro(&p, g1, 1300000000ull, 0); /* 300 ms depois */
  espera(perto(p.rolagem, 0, 0.0001f), "um buraco de 300 ms não integra");
  postura_giro(&p, g1, 1304000000ull, 0);
  espera(perto(p.rolagem, 2.0f * 0.004f, 0.0001f), "o passo seguinte integra");

  /* sem carimbo do controle, vale o do host */
  postura_zerar(&p);
  postura_giro(&p, g1, 0, 5000000000ull);
  postura_giro(&p, g1, 0, 5010000000ull);
  espera(perto(p.rolagem, 2.0f * 0.010f, 0.0001f), "sem carimbo do controle, o passo é o do host");

  /* uma sacudida (2,5 g) não puxa a postura para um ângulo falso */
  postura_zerar(&p);
  gravidade(0, 0, a);
  postura_acel(&p, a);
  float forte[3] = {POSTURA_G * 2.0f, POSTURA_G * 1.5f, 0};
  postura_acel(&p, forte);
  ns = 2000000000ull;
  for (int i = 0; i < 50; i++) {
    ns += 4000000ull;
    postura_giro(&p, g0, ns, ns);
  }
  espera(perto(p.rolagem, 0, 0.001f), "a sacudida não entra na fusão");
}

static const char *const NOMES[MED_MAX_BOTOES] = {"cruz", "círculo", "quadrado", "triângulo"};

void provas_medidas(void) {
  char b[32];
  espera_str(num_pt(b, sizeof(b), 250.34, 1), "250,3", "vírgula decimal");
  espera_str(num_pt(b, sizeof(b), 1.0, 0), "1", "sem casas");

  /* ---- botões ---- */
  MedBotoes mb;
  med_botoes_iniciar(&mb, 0xF, NOMES);
  for (int i = 0; i < 4; i++)
    med_botoes_apertou(&mb, i, i);
  Veredito v = med_botoes_veredito(&mb, true);
  espera(v.resultado == RES_PASSOU, "todo botão na hora: passou");
  espera(strstr(v.medido, "4 de 4") != NULL, "o medido conta");

  med_botoes_iniciar(&mb, 0xF, NOMES);
  med_botoes_apertou(&mb, 0, 0);
  med_botoes_apertou(&mb, 1, 1);
  v = med_botoes_veredito(&mb, true);
  espera(v.resultado == RES_NAO_MEDIDO, "a sala acabou antes de pedir: não medido");
  espera(strstr(v.obs, "quadrado") && strstr(v.obs, "triângulo"), "a observação diz quais não foram pedidos");
  for (int i = 0; i < 4; i++)
    med_botoes_mostrou(&mb, i);
  v = med_botoes_veredito(&mb, true);
  espera(v.resultado == RES_FALHOU, "pediu e não chegou: falhou");
  espera(strstr(v.medido, "quadrado") && strstr(v.medido, "triângulo"), "o medido diz quais faltaram");

  /* ✕ e ○ trocados: o ✕ físico chega como ○ e vice-versa */
  med_botoes_iniciar(&mb, 0xF, NOMES);
  for (int k = 0; k < 3; k++) {
    med_botoes_apertou(&mb, 1, 0); /* pedia cruz, chegou círculo */
    med_botoes_apertou(&mb, 0, 1); /* pedia círculo, chegou cruz */
  }
  med_botoes_apertou(&mb, 2, 2);
  med_botoes_apertou(&mb, 3, 3);
  v = med_botoes_veredito(&mb, true);
  espera(v.resultado == RES_FALHOU, "mapa trocado: falhou, mesmo com todos chegando");
  espera(strstr(v.medido, "cruz pedia, chegava círculo") != NULL, "o medido diz a troca");
  espera(strstr(v.obs, "trocado") != NULL, "a observação explica");

  med_botoes_iniciar(&mb, 0xF, NOMES);
  v = med_botoes_veredito(&mb, false);
  espera(v.resultado == RES_NAO_MEDIDO, "controle parado: não medido");

  med_botoes_iniciar(&mb, 0x3, NOMES);
  med_botoes_apertou(&mb, 0, -1);
  med_botoes_apertou(&mb, 1, 1);
  v = med_botoes_veredito(&mb, true);
  espera(v.resultado == RES_PASSOU, "chegou fora da runa, sem troca: passou");
  espera(v.obs[0] != 0, "com observação");

  /* ---- analógicos ---- */
  espera(med_analogico_setor(1, 0) == 0, "direita é o setor 0");
  espera(med_analogico_setor(0, 1) == 2, "baixo é o setor 2 (y do SDL para baixo)");
  espera(med_analogico_setor(-1, 0) == 4, "esquerda é o setor 4");
  espera(med_analogico_setor(0, -1) == 6, "cima é o setor 6");
  espera(med_analogico_setor(-1, -0.01f) == 4, "o setor 4 dos dois lados do corte");

  MedAnalogico e, d;
  med_analogico_iniciar(&e);
  med_analogico_iniciar(&d);
  for (int i = 0; i < 64; i++) {
    float ang = i * 2 * PI_F / 64;
    med_analogico_amostra(&e, cosf(ang), sinf(ang));
    med_analogico_amostra(&d, 0.95f * cosf(ang), 0.95f * sinf(ang));
  }
  med_analogico_repouso(&e, 0.02f, 0.01f);
  v = med_analogicos_veredito(&e, &d, true);
  espera(med_analogico_setores(&e) == 8 && v.resultado == RES_PASSOU, "o círculo inteiro nos dois: passou");

  med_analogico_iniciar(&d);
  d.pedido = true;
  for (int i = 0; i < 64; i++) {
    float ang = i * 2 * PI_F / 64;
    med_analogico_amostra(&d, 0.7f * cosf(ang), 0.7f * sinf(ang)); /* o curso cortado em 70% */
  }
  v = med_analogicos_veredito(&e, &d, true);
  espera(v.resultado == RES_FALHOU, "curso cortado: falhou");
  espera(strstr(v.medido, "máximo 70%") != NULL, "o medido diz o máximo");

  med_analogico_iniciar(&d);
  med_analogico_repouso(&d, 0.2f, 0.0f);
  for (int i = 0; i < 64; i++) {
    float ang = i * 2 * PI_F / 64;
    med_analogico_amostra(&d, cosf(ang), sinf(ang));
  }
  v = med_analogicos_veredito(&e, &d, true);
  espera(v.resultado == RES_PASSOU && strstr(v.obs, "deriva") != NULL, "deriva em repouso vira observação");

  med_analogico_iniciar(&d);
  v = med_analogicos_veredito(&e, &d, true);
  espera(v.resultado == RES_NAO_MEDIDO, "o círculo do direito nem foi pedido: não medido");
  d.pedido = true;
  v = med_analogicos_veredito(&e, &d, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "direito nunca se mexeu") != NULL, "analógico morto: falhou");

  /* ---- gatilhos ---- */
  MedGatilho l2, r2;
  med_gatilho_iniciar(&l2);
  med_gatilho_iniciar(&r2);
  for (int i = 0; i <= 100; i++) {
    med_gatilho_amostra(&l2, i / 100.0f);
    med_gatilho_amostra(&r2, (100 - i) / 100.0f);
  }
  v = med_gatilhos_veredito(&l2, &r2, true);
  espera(v.resultado == RES_PASSOU, "os dois do zero ao fundo, contínuos: passou");

  med_gatilho_iniciar(&r2);
  for (int k = 0; k < 10; k++) {
    med_gatilho_amostra(&r2, 0);
    med_gatilho_amostra(&r2, 1);
  }
  v = med_gatilhos_veredito(&l2, &r2, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "digital") != NULL, "gatilho digital: falhou");

  med_gatilho_iniciar(&r2);
  for (int i = 0; i <= 60; i++)
    med_gatilho_amostra(&r2, i / 100.0f);
  v = med_gatilhos_veredito(&l2, &r2, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "não chega ao fundo") != NULL, "curso curto: falhou");

  med_gatilho_iniciar(&l2);
  med_gatilho_iniciar(&r2);
  v = med_gatilhos_veredito(&l2, &r2, false);
  espera(v.resultado == RES_NAO_MEDIDO, "nada chegou: não medido");

  /* ---- touchpad ---- */
  MedToque t;
  med_toque_iniciar(&t);
  bool um[2] = {true, false};
  for (int i = 0; i <= 20; i++) {
    float x[2] = {0.05f + 0.9f * i / 20.0f, 0}, y[2] = {0.05f + 0.9f * i / 20.0f, 0};
    med_toque_amostra(&t, um, x, y);
  }
  v = med_toque_dedos_veredito(&t, true);
  espera(v.resultado == RES_NAO_MEDIDO, "sem chegar ao passo dos dois dedos: não medido");
  t.pediu_dois = true;
  v = med_toque_dedos_veredito(&t, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "só um dedo") != NULL, "pediu dois e chegou um: falhou");

  bool dois[2] = {true, true};
  for (int i = 0; i <= 20; i++) { /* abre */
    float s = i / 20.0f * 0.4f;
    float x[2] = {0.5f - s, 0.5f + s}, y[2] = {0.5f, 0.5f};
    med_toque_amostra(&t, dois, x, y);
  }
  for (int i = 20; i >= 0; i--) { /* fecha */
    float s = i / 20.0f * 0.4f;
    float x[2] = {0.5f - s, 0.5f + s}, y[2] = {0.5f, 0.52f};
    med_toque_amostra(&t, dois, x, y);
  }
  v = med_toque_dedos_veredito(&t, true);
  espera(t.max_dedos == 2 && t.abriu && t.fechou, "dois dedos abriram e fecharam");
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "letra") != NULL, "sem a letra completa: falhou");
  t.tracou = true;
  v = med_toque_dedos_veredito(&t, true);
  espera(v.resultado == RES_PASSOU, "dois dedos, área inteira, abre e fecha, letra feita: passou");

  med_toque_iniciar(&t);
  t.tracou = true;
  for (int i = 0; i <= 20; i++) { /* só a metade esquerda chega */
    float s = i / 20.0f * 0.2f;
    float x[2] = {0.05f + s * 0.1f, 0.05f + s * 2.2f}, y[2] = {0.1f, 0.4f};
    med_toque_amostra(&t, dois, x, y);
  }
  v = med_toque_dedos_veredito(&t, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "parte do touchpad") != NULL, "área cortada: falhou");

  espera(perto(med_toque_distancia(0, 0, 1, 0), 1.0f, 0.001f), "a largura inteira vale 1");
  espera(perto(med_toque_distancia(0, 0, 0, 1), 0.5f, 0.001f), "a altura inteira vale meia largura");

  med_toque_iniciar(&t);
  v = med_toque_clique_veredito(&t, true);
  espera(v.resultado == RES_NAO_MEDIDO, "sem chegar ao carimbo: não medido");
  t.pediu_clique = true;
  v = med_toque_clique_veredito(&t, true);
  espera(v.resultado == RES_FALHOU, "no carimbo, sem clique com o controle vivo: falhou");
  med_toque_clique(&t);
  v = med_toque_clique_veredito(&t, true);
  espera(v.resultado == RES_PASSOU, "o clique chegou: passou");

  /* ---- giroscópio e acelerômetro ---- */
  MedSensores s;
  med_sensores_iniciar(&s, false, false, 0);
  espera(med_giro_veredito(&s, true).resultado == RES_NAO_MEDIDO, "sem giroscópio: não medido");
  espera(med_acel_veredito(&s, true).resultado == RES_NAO_MEDIDO, "sem acelerômetro: não medido");

  med_sensores_iniciar(&s, true, true, 250);
  espera(med_giro_veredito(&s, true).resultado == RES_FALHOU, "declara e não manda: falhou");

  float giro[3], acel[3];
  gravidade(0, 0, acel);
  giro[0] = giro[1] = giro[2] = 0;
  for (int i = 0; i < 100; i++)
    med_sensores_amostra(&s, giro, acel);
  for (int i = -40; i <= 40; i++) { /* inclina de -40° a +40° */
    gravidade(i * PI_F / 180, 0, acel);
    giro[0] = 1.2f;
    giro[1] = -1.5f;
    giro[2] = 2.0f;
    med_sensores_amostra(&s, giro, acel);
  }
  float pancada[3] = {0, POSTURA_G * 2.4f, 0};
  med_sensores_amostra(&s, giro, pancada);
  med_sensores_martelada(&s);
  s.amostras_giro = s.amostras_acel = 5000;
  s.hz_host = 250.4;
  s.hz_relogio = 250.0;
  s.sinal[0] = s.sinal[1] = 1;
  v = med_giro_veredito(&s, true);
  espera(v.resultado == RES_PASSOU, "três eixos, taxa boa, sinal certo: passou");
  espera(strstr(v.medido, "250,4 Hz (host)") != NULL, "o medido traz a taxa com vírgula");
  v = med_acel_veredito(&s, true);
  espera(v.resultado == RES_PASSOU, "1 g parado, inclinou, martelou: passou");
  espera(strstr(v.medido, "parado 1,0 g") != NULL, "o medido traz o 1 g");
  espera(perto((float)med_sensores_g_parado(&s), 1.0f, 0.06f), "a mediana parado é 1 g");

  s.sinal[0] = -1;
  v = med_giro_veredito(&s, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "invertido") != NULL, "rolagem invertida: falhou");
  s.sinal[0] = 1;

  s.hz_host = 40;
  espera(med_giro_veredito(&s, true).resultado == RES_FALHOU, "40 amostras por segundo: falhou");
  s.hz_host = 125;
  v = med_giro_veredito(&s, true);
  espera(v.resultado == RES_PASSOU && strstr(v.obs, "difere") != NULL, "taxa diferente da declarada vira observação");

  s.giro_max[1] = 0.3f;
  v = med_giro_veredito(&s, true);
  espera(v.resultado == RES_NAO_MEDIDO, "sem chegar à mira, a guinada não foi pedida: não medido");
  s.pediu_mira = true;
  v = med_giro_veredito(&s, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "guinada") != NULL, "na mira, eixo parado: falhou");

  /* marteladas com o giro parado não puxam a mediana */
  MedSensores k;
  med_sensores_iniciar(&k, true, true, 250);
  float quieto[3] = {0, 0, 0};
  gravidade(0, 0, acel);
  for (int i = 0; i < 60; i++)
    med_sensores_amostra(&k, quieto, acel);
  for (int i = 0; i < 20; i++)
    med_sensores_amostra(&k, quieto, pancada);
  espera(perto((float)med_sensores_g_parado(&k), 1.0f, 0.06f), "a mediana ignora as marteladas");

  /* acelerômetro em escala errada: parado, lê 0,1 g */
  MedSensores q;
  med_sensores_iniciar(&q, true, true, 250);
  float zero[3] = {0, 0, 0}, fraco[3] = {0, 0.98f, 0};
  for (int i = 0; i < 50; i++)
    med_sensores_amostra(&q, zero, fraco);
  q.amostras_acel = 50;
  v = med_acel_veredito(&q, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "escala") != NULL, "0,1 g parado: escala errada");

  /* sem martelada */
  MedSensores m2;
  med_sensores_iniciar(&m2, true, true, 250);
  for (int i = -40; i <= 40; i++) {
    gravidade(i * PI_F / 180, 0, acel);
    med_sensores_amostra(&m2, zero, acel);
  }
  m2.amostras_acel = 81;
  v = med_acel_veredito(&m2, true);
  espera(v.resultado == RES_NAO_MEDIDO, "sem chegar à pedra: não medido");
  m2.pediu_martelada = true;
  v = med_acel_veredito(&m2, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "martelada") != NULL, "na pedra, sem martelada: falhou");
}
