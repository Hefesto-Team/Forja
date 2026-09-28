/* As provas às cegas: o plano dos golpes e das armas, e a estatística que
 * decide cada veredito de saída. */
#include "prova.h"

#include "cegas.h"

static Cega cega(int certos, int errados, int perdidos, int disse) {
  Cega c;
  cega_zerar(&c);
  for (int i = 0; i < certos; i++)
    cega_certo(&c);
  for (int i = 0; i < errados; i++)
    cega_errado(&c, disse);
  for (int i = 0; i < perdidos; i++)
    cega_perdido(&c);
  return c;
}

void provas_cegas(void) {
  Sorteio s;

  /* ---- o plano dos golpes ---- */
  int slots[4] = {0, 1, 2, 3};
  Tiro t[64];
  sorteio_semear(&s, 42);
  int n = cegas_plano_tiros(&s, slots, 4, 5, t, 64);
  espera(n == 40, "quatro jogadores, cinco de cada lado: quarenta golpes");
  int por[4][2] = {{0}}, seguidos = 0;
  for (int i = 0; i < n; i++) {
    por[t[i].slot][t[i].lado]++;
    if (i && t[i].slot == t[i - 1].slot)
      seguidos++;
  }
  int iguais = 1;
  for (int k = 0; k < 4; k++)
    iguais &= por[k][0] == 5 && por[k][1] == 5;
  espera(iguais, "cada jogador leva cinco da esquerda e cinco da direita");
  espera(seguidos <= 1, "quase nunca o mesmo alvo duas vezes seguidas");
  Tiro t2[64];
  sorteio_semear(&s, 42);
  cegas_plano_tiros(&s, slots, 4, 5, t2, 64);
  espera(memcmp(t, t2, sizeof(Tiro) * 40) == 0, "a mesma semente dá o mesmo plano");
  sorteio_semear(&s, 43);
  cegas_plano_tiros(&s, slots, 4, 5, t2, 64);
  espera(memcmp(t, t2, sizeof(Tiro) * 40) != 0, "outra semente, outro plano");
  int um[1] = {2};
  sorteio_semear(&s, 7);
  n = cegas_plano_tiros(&s, um, 1, 5, t, 64);
  int esq = 0;
  for (int i = 0; i < n; i++)
    esq += t[i].lado == LADO_ESQ && t[i].slot == 2;
  espera(n == 10 && esq == 5, "sozinho: dez golpes, cinco de cada lado");
  espera(cegas_plano_tiros(&s, slots, 4, 5, t, 12) == 12, "respeita o tamanho do buffer");

  /* ---- o plano das armas ---- */
  Arma armas[16];
  sorteio_semear(&s, 5);
  n = cegas_plano_armas(&s, 2, armas, 16);
  int conta[ARMA_TOTAL] = {0}, repetidas = 0;
  for (int i = 0; i < n; i++) {
    conta[armas[i]]++;
    if (i && armas[i] == armas[i - 1])
      repetidas++;
  }
  espera(n == 8 && conta[0] == 2 && conta[1] == 2 && conta[2] == 2 && conta[3] == 2, "cada arma duas vezes");
  espera(repetidas <= 1, "quase nunca a mesma arma em seguida");

  /* ---- o plano genérico ---- */
  int fontes[3] = {0, 2, 9}, vezes[3] = {2, 2, 3}, plano[16];
  sorteio_semear(&s, 11);
  n = cegas_plano_fontes(&s, fontes, vezes, 3, plano, 16);
  int c9 = 0, c0 = 0, rep = 0;
  for (int i = 0; i < n; i++) {
    c9 += plano[i] == 9;
    c0 += plano[i] == 0;
    rep += i && plano[i] == plano[i - 1];
  }
  espera(n == 7 && c9 == 3 && c0 == 2, "cada fonte nas vezes pedidas");
  espera(rep <= 1, "quase nunca a mesma fonte em seguida");

  /* ---- o motor ---- */
  Cega c = cega(5, 0, 0, -1);
  Veredito v = cega_motor_veredito(&c, LADO_ESQ, true, true);
  espera(v.resultado == RES_PASSOU && v.nivel == NIVEL_OBEDECEU, "cinco de cinco: passou, obedeceu");
  c = cega(4, 1, 0, LADO_DIR);
  espera(cega_motor_veredito(&c, LADO_ESQ, true, true).resultado == RES_PASSOU, "quatro de cinco: passou");
  c = cega(1, 4, 0, LADO_DIR);
  v = cega_motor_veredito(&c, LADO_ESQ, true, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "trocado") != NULL, "quase tudo do outro lado: lado trocado");
  c = cega(1, 0, 4, -1);
  v = cega_motor_veredito(&c, LADO_DIR, true, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "motor fraco") != NULL, "não sentiu: o motor não chega");
  c = cega(3, 1, 1, LADO_DIR);
  v = cega_motor_veredito(&c, LADO_ESQ, true, true);
  espera(v.resultado == RES_NAO_MEDIDO && strstr(v.obs, "inconclusivo") != NULL, "três de cinco: inconclusivo");
  c = cega(5, 0, 0, -1);
  v = cega_motor_veredito(&c, LADO_ESQ, false, true);
  espera(v.resultado == RES_NAO_MEDIDO && v.nivel == NIVEL_MONTOU, "o SDL recusou: não medido, só montou");
  c = cega(0, 0, 5, -1);
  espera(cega_motor_veredito(&c, LADO_ESQ, true, false).resultado == RES_NAO_MEDIDO, "ninguém jogou: não medido");

  /* ---- o isolamento ---- */
  Cega meus = cega(9, 0, 1, -1);
  espera(cega_isolamento_veredito(0, 30, 0, &meus).resultado == RES_NAO_MEDIDO, "sozinho: não medido");
  espera(cega_isolamento_veredito(0, 30, 3, &meus).resultado == RES_PASSOU, "nenhum fantasma: passou");
  espera(cega_isolamento_veredito(1, 30, 3, &meus).resultado == RES_PASSOU, "um fantasma é distração");
  v = cega_isolamento_veredito(5, 30, 3, &meus);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "golpes dos outros") != NULL, "cinco fantasmas: vazou");
  Cega surdo = cega(1, 0, 9, -1);
  v = cega_isolamento_veredito(0, 30, 3, &surdo);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "não chegaram") != NULL, "os golpes dele foram para outro");

  /* ---- a cor ---- */
  c = cega(3, 0, 0, -1);
  espera(cega_cor_decidida(&c) && cega_cor_veredito(&c, true).resultado == RES_PASSOU, "três cores certas: passou");
  c = cega(1, 2, 0, 1);
  espera(cega_cor_decidida(&c) && cega_cor_veredito(&c, true).resultado == RES_FALHOU, "duas erradas: falhou");
  c = cega(2, 1, 0, 1);
  espera(!cega_cor_decidida(&c), "duas certas e uma errada: mais uma pergunta");
  c = cega(0, 0, 3, -1);
  espera(cega_cor_veredito(&c, true).resultado == RES_NAO_MEDIDO, "sem resposta: não medido");

  /* ---- a arma ---- */
  Cega off = cega(2, 0, 0, -1);
  c = cega(2, 0, 0, -1);
  espera(cega_arma_decidida(&c) && cega_arma_veredito(ARMA_PISTOLA, &c, &off, true).resultado == RES_PASSOU,
         "duas de duas: passou");
  c = cega(0, 2, 0, ARMA_NENHUMA);
  v = cega_arma_veredito(ARMA_ARCO, &c, &off, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "não chega ao gatilho") != NULL, "não sentiu nada: não chega");
  c = cega(0, 2, 0, ARMA_METRALHADORA);
  v = cega_arma_veredito(ARMA_PISTOLA, &c, &off, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "pareceu metralhadora") != NULL, "sentiu outra: modo trocado");
  espera(strstr(v.medido, "pareceu metralhadora 2×") != NULL, "o medido diz o que pareceu");
  c = cega(1, 1, 0, ARMA_ARCO);
  espera(!cega_arma_decidida(&c), "uma certa e uma errada: mais uma rodada");
  espera(cega_arma_veredito(ARMA_PISTOLA, &c, &off, true).resultado == RES_NAO_MEDIDO, "e por ora, inconclusivo");
  Cega preso = cega(0, 2, 0, ARMA_ARCO);
  c = cega(2, 0, 0, -1);
  v = cega_arma_veredito(ARMA_PISTOLA, &c, &preso, true);
  espera(strstr(v.obs, "não solta") != NULL, "sem arma que parece arco: o gatilho não solta");
  espera(strcmp(cegas_nome_arma(ARMA_METRALHADORA), "metralhadora") == 0, "os nomes");

  /* ---- os LEDs ---- */
  c = cega(6, 1, 1, -1);
  v = cega_leds_veredito(&c, true);
  espera(v.resultado == RES_PASSOU, "seis de oito, um errado: passou");
  espera(strstr(v.medido, "6 contagens certas, 1 errada") != NULL, "o plural certo");
  c = cega(1, 0, 0, -1);
  espera(strstr(cega_leds_veredito(&c, true).medido, "1 contagem certa") != NULL, "e o singular");
  c = cega(2, 5, 1, -1);
  espera(cega_leds_veredito(&c, true).resultado == RES_FALHOU, "cinco erradas: falhou");
  c = cega(3, 3, 0, -1);
  espera(cega_leds_veredito(&c, true).resultado == RES_NAO_MEDIDO, "meio a meio: inconclusivo");

  /* ---- A Prova: tudo junto ---- */
  {
    MedCarga m;
    med_carga_zerar(&m, true);
    m.segundos = 90;
    m.amostras_giro = 250L * 90;
    m.saidas = 400;
    Cega l1, c1;
    cega_zerar(&l1);
    cega_zerar(&c1);
    cega_certo(&l1);
    cega_certo(&c1);
    Veredito v = cega_tudo_junto_veredito(&m, &l1, &c1, true);
    espera(v.resultado == RES_PASSOU && v.nivel == NIVEL_OBEDECEU, "tudo ligado, nada parou, a prova final certa: passou");
    espera(strstr(v.medido, "250 Hz") != NULL, "o medido traz a taxa do giroscópio");
    espera(cega_tudo_junto_veredito(&m, &l1, &c1, false).resultado == RES_NAO_MEDIDO, "quem não jogou: não medido");
    m.paradas = 3;
    m.maior_parada = 1.5f;
    v = cega_tudo_junto_veredito(&m, &l1, &c1, true);
    espera(v.resultado == RES_FALHOU && strstr(v.obs, "engasga") != NULL && strstr(v.obs, "1,5 s") != NULL,
           "a entrada parou sob carga: falhou");
    m.paradas = 0;
    m.recusadas = 7;
    v = cega_tudo_junto_veredito(&m, &l1, &c1, true);
    espera(v.resultado == RES_FALHOU && strstr(v.obs, "recusou 7 de 400") != NULL, "saídas recusadas no meio: falhou");
    m.recusadas = 400;
    espera(cega_tudo_junto_veredito(&m, &l1, &c1, true).resultado == RES_NAO_MEDIDO,
           "todas recusadas (o rádio nativo): não medido");
    m.recusadas = 0;
    m.amostras_giro = 30L * 90;
    v = cega_tudo_junto_veredito(&m, &l1, &c1, true);
    espera(v.resultado == RES_FALHOU && strstr(v.obs, "30 Hz") != NULL, "o giroscópio caiu com a carga: falhou");
    m.amostras_giro = 250L * 90;
    Cega l0, c0;
    cega_zerar(&l0);
    cega_zerar(&c0);
    cega_errado(&l0, 1);
    cega_errado(&c0, 2);
    v = cega_tudo_junto_veredito(&m, &l0, &c0, true);
    espera(v.resultado == RES_FALHOU && strstr(v.obs, "luzinhas e a cor") != NULL, "as duas erradas: falhou");
    cega_zerar(&l0);
    cega_zerar(&c0);
    espera(cega_tudo_junto_veredito(&m, &l0, &c0, true).resultado == RES_NAO_MEDIDO, "sem resposta: não medido");
  }
}

