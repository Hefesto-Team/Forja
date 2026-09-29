/* As salas de som: a síntese dos passos contra o reconhecedor de chão, e as
 * réguas do alto-falante, da háptica, do microfone, do mudo e do LED. */
#include "prova.h"

#include "cegas.h"
#include "chao.h"
#include "medidas.h"
#include "sintese.h"

#include <math.h>

/* O envelope que o robô sentiria: o RMS de cada quadro de 1/60 s, com um
 * pouco de silêncio antes e depois. */
static int envelope(const Onda *o, float *env, int max) {
  const int bloco = SINT_TAXA / 60;
  int n = 0;
  env[n++] = 0;
  env[n++] = 0;
  for (int ini = 0; ini < o->n && n < max; ini += bloco) {
    double s = 0;
    int k = 0;
    for (; k < bloco && ini + k < o->n; k++)
      s += (double)o->a[ini + k] * o->a[ini + k];
    env[n++] = (float)sqrt(s / (k ? k : 1)) * 1.6f;
  }
  for (int i = 0; i < 6 && n < max; i++)
    env[n++] = 0;
  return n;
}

/* Uma prova com as erradas ditas como `resposta`. */
static Cega cega_disse(int certos, int errados, int resposta, int perdidos) {
  Cega c;
  cega_zerar(&c);
  for (int i = 0; i < certos; i++)
    cega_certo(&c);
  for (int i = 0; i < errados; i++)
    cega_errado(&c, resposta);
  for (int i = 0; i < perdidos; i++)
    cega_perdido(&c);
  return c;
}

static Cega cega(int certos, int errados, int perdidos) {
  Cega c;
  cega_zerar(&c);
  for (int i = 0; i < certos; i++)
    cega_certo(&c);
  for (int i = 0; i < errados; i++)
    cega_errado(&c, 0);
  for (int i = 0; i < perdidos; i++)
    cega_perdido(&c);
  return c;
}

void provas_som(void) {
  /* ---- cada chão se sente diferente, com qualquer semente ---- */
  int certos = 0, total = 0;
  for (int chao = 0; chao < CHAO_TOTAL; chao++)
    for (uint32_t sem = 1; sem <= 12; sem++) {
      Onda o = {0};
      espera(sint_passo(&o, chao, sem) == 0, "o passo sintetiza");
      float env[128];
      int n = envelope(&o, env, 128);
      int achado = chao_pelo_envelope(env, n);
      total++;
      certos += achado == chao;
      if (achado != chao)
        fprintf(stderr, "  chão %s (semente %u) sentido como %d\n", chao_nome((Chao)chao), sem, achado);
      espera(onda_pico(&o) <= 0.91f, "o passo não estoura");
      onda_liberar(&o);
    }
  espera(certos == total, "cada chão reconhecido pelo envelope, em todas as sementes");
  float nada[20] = {0};
  espera(chao_pelo_envelope(nada, 20) == -1, "silêncio não é chão");
  espera(strcmp(chao_nome(CHAO_AGUA), "água") == 0, "os nomes com acento");

  Onda g = {0};
  espera(sint_grito(&g, 0.8f, 3) == 0 && g.n == (int)(0.8f * SINT_TAXA), "o grito tem a duração pedida");
  espera(onda_pico(&g) > 0.9f && onda_pico(&g) <= 0.951f, "e grita alto, sem estourar");
  onda_liberar(&g);

  /* ---- o microfone ---- */
  MedMic m;
  med_mic_iniciar(&m, false);
  espera(med_mic_veredito(&m, true).resultado == RES_NAO_MEDIDO, "sem microfone achado: não medido");
  med_mic_iniciar(&m, true);
  m.viu_piso = true;
  m.piso = 0.2f;
  m.voz = 0.62f;
  m.quadros = 300;
  Veredito v = med_mic_veredito(&m, true);
  espera(v.resultado == RES_PASSOU && v.nivel == NIVEL_REAGIU, "a voz subiu 23 dB: passou");
  espera(strstr(v.medido, "23 dB acima") != NULL, "o medido em dB");
  m.voz = 0.3f;
  espera(med_mic_veredito(&m, true).resultado == RES_FALHOU, "subiu pouco: falhou");
  m.voz = 0;
  m.piso = 0;
  v = med_mic_veredito(&m, true);
  espera(v.resultado == RES_NAO_MEDIDO && strstr(v.obs, "silêncio absoluto") != NULL,
         "só silêncio absoluto: mudo no sistema, não medido (nunca falhou)");
  m.quadros = 0;
  espera(med_mic_veredito(&m, true).resultado == RES_FALHOU, "abriu e não chegou nada: falhou");

  /* ---- o mudo ---- */
  med_mic_iniciar(&m, true);
  espera(med_mudo_veredito(&m, true).resultado == RES_NAO_MEDIDO, "a sala não pediu o mudo: não medido");
  m.pediu_mudo = true;
  espera(med_mudo_veredito(&m, true).resultado == RES_FALHOU, "pediu e o botão não chegou: falhou");
  m.apertou_mudo = true;
  m.viu_piso = m.viu_mudo = true;
  m.piso = 0.2f;
  m.mudo = 0.22f;
  v = med_mudo_veredito(&m, true);
  espera(v.resultado == RES_PASSOU && strstr(v.obs, "não dá para dizer") != NULL,
         "o microfone nunca deu voz: não se diz se o sistema cortou");
  m.voz = 0.62f;
  v = med_mudo_veredito(&m, true);
  espera(v.resultado == RES_PASSOU && strstr(v.obs, "também cortou") != NULL, "o botão chegou, e o sistema cortou");
  m.mudo = 0.6f;
  v = med_mudo_veredito(&m, true);
  espera(v.resultado == RES_PASSOU && strstr(v.obs, "do jogo") != NULL, "o botão chegou; o mudo ficou com o jogo");

  /* ---- o alto-falante ---- */
  Cega meus = cega(3, 0, 0);
  espera(cega_alto_falante_veredito(&meus, 0, 9, false).resultado == RES_NAO_MEDIDO, "sem alto-falante: não medido");
  v = cega_alto_falante_veredito(&meus, 0, 9, true);
  espera(v.resultado == RES_PASSOU && v.nivel == NIVEL_OBEDECEU, "três de três, sem fantasma: passou");
  meus = cega(0, 3, 0);
  v = cega_alto_falante_veredito(&meus, 0, 9, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "não saiu") != NULL, "o próprio canto não saiu: falhou");
  meus = cega(3, 0, 0);
  v = cega_alto_falante_veredito(&meus, 6, 9, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "outro lugar") != NULL, "o canto dos outros saiu aqui: falhou");
  meus = cega(2, 1, 0);
  espera(cega_alto_falante_veredito(&meus, 1, 9, true).resultado == RES_PASSOU, "dois de três com um fantasma: passou");

  /* ---- a háptica ---- */
  Cega chao = cega(7, 1, 0), le = cega(3, 0, 0), ld = cega(2, 0, 0);
  espera(cega_haptica_veredito(&chao, &le, &ld, false).resultado == RES_NAO_MEDIDO, "sem os canais: não medido");
  v = cega_haptica_veredito(&chao, &le, &ld, true);
  espera(v.resultado == RES_PASSOU && v.nivel == NIVEL_OBEDECEU, "sete de oito chãos, lados certos: passou");
  le = cega_disse(0, 3, 1, 0); /* o tropeço da esquerda, dito "direita" */
  ld = cega_disse(0, 2, 0, 0);
  v = cega_haptica_veredito(&chao, &le, &ld, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "trocados") != NULL, "lados trocados: falhou");
  le = cega_disse(0, 3, CAMINHO_NADA_LADO, 0);
  ld = cega_disse(0, 2, CAMINHO_NADA_LADO, 0);
  v = cega_haptica_veredito(&chao, &le, &ld, true);
  espera(v.resultado != RES_FALHOU || strstr(v.obs, "trocados") == NULL, "\"não senti\" não é trocar de lado");
  chao = cega(0, 0, 8);
  le = cega(0, 0, 3);
  ld = cega(0, 0, 2);
  v = cega_haptica_veredito(&chao, &le, &ld, true);
  espera(v.resultado == RES_NAO_MEDIDO, "ninguém respondeu nada: não medido");
  chao = cega(1, 0, 7);
  le = cega(0, 0, 3);
  ld = cega(1, 0, 1);
  v = cega_haptica_veredito(&chao, &le, &ld, true);
  espera(v.resultado == RES_NAO_MEDIDO, "quase tudo sem resposta: o silêncio não reprova");
  chao = cega_disse(1, 7, CAMINHO_NADA, 0);
  le = cega_disse(0, 2, CAMINHO_NADA_LADO, 0);
  ld = cega_disse(0, 2, CAMINHO_NADA_LADO, 0);
  v = cega_haptica_veredito(&chao, &le, &ld, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "não sentiu") != NULL, "disse \"não senti\" sete vezes: falhou");
  espera(strstr(v.medido, "7 \"não senti\"") != NULL, "o medido conta os \"não senti\"");
  chao = cega(8, 0, 0);
  le = cega(2, 0, 0);
  ld = cega_disse(0, 2, CAMINHO_NADA_LADO, 0);
  v = cega_haptica_veredito(&chao, &le, &ld, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "direita") != NULL && strstr(v.obs, "canal 4") != NULL,
         "o tropeço da direita nunca chegou: o atuador direito");
  chao = cega_disse(2, 6, 1, 0);
  le = cega(3, 0, 0);
  ld = cega(2, 0, 0);
  v = cega_haptica_veredito(&chao, &le, &ld, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "não se distinguem") != NULL, "chãos confundidos: falhou");

  /* ---- o LED do microfone ---- */
  Cega led = cega(3, 0, 0);
  v = cega_led_mic_veredito(&led, true);
  espera(v.resultado == RES_PASSOU && strstr(v.medido, "3 respostas certas") != NULL, "três de três: passou");
  led = cega(0, 2, 0);
  v = cega_led_mic_veredito(&led, true);
  espera(v.resultado == RES_FALHOU && strstr(v.obs, "luz do microfone") != NULL, "duas erradas: falhou");
  espera(cega_led_mic_decidida(&led), "e está decidido");
}
