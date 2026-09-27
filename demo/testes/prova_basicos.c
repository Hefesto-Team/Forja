/* Máscara de MAC, UTF-8, sorteio, taxa e catálogo. */
#include "prova.h"

#include "aleatorio.h"
#include "catalogo.h"
#include "mascara.h"
#include "taxa.h"
#include "utf8.h"

#include <math.h>
#include <stdlib.h>

void provas_mascara(void) {
  char s[128];

  mascara_mac_copia("uniq 14:3a:9a:12:34:ab fim", s, sizeof(s));
  espera_str(s, "uniq 14:3a:9a:00:00:ab fim", "os octetos 4 e 5 zerados, com ':'");

  mascara_mac_copia("serial a0-fa-9c-00-11-f0", s, sizeof(s));
  espera_str(s, "serial a0-fa-9c-00-00-f0", "com '-', como o SDL monta o serial");

  mascara_mac_copia("bluez_output.D4_2F_4B_77_66_D8.1", s, sizeof(s));
  espera_str(s, "bluez_output.D4_2F_4B_00_00_D8.1", "com '_', como o nó do BlueZ");

  mascara_mac_copia("usb-Sony_DualSense_a0fa9c1122f0-00", s, sizeof(s));
  espera_str(s, "usb-Sony_DualSense_a0fa9c0000f0-00", "doze hex seguidos (iSerial)");

  mascara_mac_copia("sessão 202609271930 às 19h", s, sizeof(s));
  espera_str(s, "sessão 202609271930 às 19h", "doze dígitos sem letra não são MAC");

  mascara_mac_copia("14:3a:9a:12:34", s, sizeof(s));
  espera_str(s, "14:3a:9a:12:34", "cinco pares não são MAC");

  mascara_mac_copia("14:3a:9a-12:34:ab", s, sizeof(s));
  espera_str(s, "14:3a:9a-12:34:ab", "separador misturado não é MAC");

  mascara_mac_copia("x14:3a:9a:12:34:ab", s, sizeof(s));
  espera_str(s, "x14:3a:9a:12:34:ab", "grudado numa palavra não é MAC");

  strcpy(s, "a 11:22:33:44:55:66 e b 77:88:99:aa:bb:cc");
  espera(mascara_mac(s) == 2, "dois MACs no mesmo texto");
  espera_str(s, "a 11:22:33:00:00:66 e b 77:88:99:00:00:cc", "os dois mascarados");

  espera(mascara_mac(NULL) == 0, "NULL não quebra");
  mascara_mac_copia(NULL, s, sizeof(s));
  espera_str(s, "", "NULL vira vazio");
}

void provas_utf8(void) {
  const char *p = "ção";
  espera(utf8_proximo(&p) == 0xE7, "ç");
  espera(utf8_proximo(&p) == 0xE3, "ã");
  espera(utf8_proximo(&p) == 'o', "o");
  espera(utf8_proximo(&p) == 0, "fim");
  espera(utf8_contar("Não medido") == 10, "dez codepoints");
  const char *ruim = "\xff" "a";
  espera(utf8_proximo(&ruim) == 0xFFFD, "byte inválido vira U+FFFD");
  espera(utf8_proximo(&ruim) == 'a', "e avança um só");
  char buf[4];
  espera(utf8_escrever(0x2014, buf) == 3, "travessão tem três bytes");
  char m[64];
  utf8_maiusculas("O Salão da Forja — ação", m, sizeof(m));
  espera_str(m, "O SALÃO DA FORJA — AÇÃO", "versal com acento, o travessão passa");
  utf8_maiusculas("çéíóúâêôàü", m, sizeof(m));
  espera_str(m, "ÇÉÍÓÚÂÊÔÀÜ", "o Latin-1 inteiro");
  utf8_maiusculas("abcdef", m, 4);
  espera_str(m, "ABC", "corta sem estourar");
  utf8_maiusculas("ãã", m, 4);
  espera_str(m, "Ã", "não corta um acento no meio");
}

void provas_sorteio(void) {
  Sorteio a, b;
  sorteio_semear(&a, 42);
  sorteio_semear(&b, 42);
  int iguais = 1;
  for (int i = 0; i < 100; i++)
    if (sorteio_u32(&a) != sorteio_u32(&b))
      iguais = 0;
  espera(iguais, "a mesma semente dá a mesma sequência");

  sorteio_semear(&a, 1);
  sorteio_semear(&b, 2);
  espera(sorteio_u32(&a) != sorteio_u32(&b), "sementes vizinhas não se parecem");

  int conta[4] = {0};
  for (int i = 0; i < 4000; i++) {
    int v = sorteio_entre(&a, 0, 3);
    espera(v >= 0 && v <= 3, "entre respeita a faixa");
    conta[v]++;
  }
  for (int i = 0; i < 4; i++)
    espera(conta[i] > 800 && conta[i] < 1200, "os quatro lados saem parecidos");

  int v[6] = {0, 1, 2, 3, 4, 5};
  sorteio_embaralhar(&a, v, 6);
  int soma = 0;
  for (int i = 0; i < 6; i++)
    soma += v[i];
  espera(soma == 15, "embaralhar não perde nem repete");
  float r = sorteio_real(&a);
  espera(r >= 0.0f && r < 1.0f, "real em [0,1)");
}

void provas_taxa(void) {
  Taxa t;
  taxa_zerar(&t);
  /* 250 Hz no host e no relógio do controle, por 3 s */
  for (int i = 0; i < 750; i++)
    taxa_evento(&t, (uint64_t)i * 4000000ull, 1000000000ull + (uint64_t)i * 4000000ull);
  uint64_t agora = 749ull * 4000000ull;
  espera(fabs(taxa_hz_host(&t, agora, 2.0) - 250.0) < 0.5, "250 Hz pelo host");
  espera(fabs(taxa_hz_sensor(&t, agora, 2.0) - 250.0) < 0.5, "250 Hz pelo relógio do controle");

  /* o Edge declara 1000 e entrega 250: a régua mede o que chega */
  Taxa u;
  taxa_zerar(&u);
  espera(taxa_hz_host(&u, 0, 2.0) == 0.0, "sem evento, sem taxa");
  taxa_evento(&u, 5, 0);
  espera(taxa_hz_host(&u, 5, 2.0) == 0.0, "um evento só não faz taxa");
  taxa_evento(&u, 10, 0);
  espera(taxa_hz_sensor(&u, 10, 2.0) == 0.0, "carimbo parado não inventa taxa");

  /* a janela anda: depois de 10 s de silêncio não há taxa */
  espera(taxa_hz_host(&t, agora + 10000000000ull, 2.0) == 0.0, "janela vazia depois do silêncio");
}

void provas_catalogo(void) {
  for (int f = 0; f < F_TOTAL; f++) {
    const InfoFeature *inf = catalogo_feature((Feature)f);
    espera(inf && inf->chave && inf->nome, "toda feature tem chave e nome");
    espera(catalogo_feature_por_chave(inf->chave) == f, "a chave volta à feature");
    espera(inf->sala >= 0 && inf->sala < SALA_TOTAL, "toda feature é de uma sala");
  }
  int por_sala[SALA_TOTAL] = {0};
  for (int f = 0; f < F_TOTAL; f++)
    por_sala[catalogo_feature((Feature)f)->sala]++;
  for (int e = 0; e < SALA_TOTAL; e++) {
    const InfoSala *inf = catalogo_sala((Sala)e);
    espera(inf && inf->acao && inf->acao[0] && inf->padrao[0], "toda sala tem o padrão e a linha de ação");
    espera(catalogo_sala_por_chave(inf->chave) == e, "a chave volta à sala");
    espera(por_sala[e] > 0, "toda sala valida alguma feature");
  }
  espera(catalogo_sala(SALA_PROVA)->familia == FAM_TUDO, "tudo junto é a última família");
  espera(SALA_PROVA == SALA_TOTAL - 1, "a sala de tudo junto vem por último");
  espera(catalogo_feature_por_chave("nao_existe") == -1, "chave desconhecida");
  /* a folha de teste do Hefesto usa os nomes das salas do FORJA em Godot */
  espera(catalogo_sala_por_chave("voz") == SALA_CRIPTA, "--sala=voz abre a sala do microfone");
  espera(catalogo_sala_por_chave("impacto") == SALA_CERCO, "--sala=impacto abre o dano direcional");
  espera(catalogo_sala_por_chave("galeria") == SALA_GALERIA, "galeria continua galeria");
  espera(catalogo_sala_por_chave("nao_existe") == -1, "sala desconhecida");
}
