/* O catálogo das salas e das features. Ver catalogo.h. */
#include "catalogo.h"

#include <string.h>

static const InfoSala SALAS[SALA_TOTAL] = {
    {"centelha", "A Centelha", "acender runas no tempo certo",
     "Aperte o botão que a runa mostra antes que ela apague.", FAM_ENTRADA},
    {"viga", "A Viga", "equilíbrio e mira por movimento",
     "Gire o controle para virar; sacuda para baixo para pisar forte.", FAM_ENTRADA},
    {"molde", "O Molde", "desenhar e moldar no touchpad",
     "Dois dedos abrem o molde; o clique no touchpad carimba.", FAM_ENTRADA},
    {"impacto", "O Impacto", "dano direcional e vida na luz",
     "Desvie: o tiro da esquerda vibra a esquerda, e a luz cai com a vida.", FAM_SAIDA_HID},
    {"galeria", "A Galeria", "armas com gatilho adaptativo",
     "Pistola com clique, metralhadora que treme, arco que pesa.", FAM_SAIDA_HID},
    {"voz", "A Voz", "o microfone e o mudo do controle",
     "Fale no controle; o botão de mudo cala a sua barra e acende o LED.", FAM_AUDIO},
    {"caminhos", "Os Caminhos", "o chão que se sente nas mãos",
     "Ande de olhos fechados e diga por onde está pisando.", FAM_AUDIO},
    {"canto", "O Canto", "ritmo no alto-falante do controle",
     "A bigorna canta no seu controle: repita o ritmo.", FAM_AUDIO},
    {"prova", "A Prova", "duas equipes, tudo ligado",
     "Dois contra dois, noventa segundos, todos os sentidos do controle.", FAM_TUDO},
};

static const InfoFeature FEATURES[F_TOTAL] = {
    {"botoes", "Botões", SALA_CENTELHA},
    {"analogicos", "Analógicos", SALA_CENTELHA},
    {"gatilhos_analogicos", "Gatilhos analógicos", SALA_CENTELHA},
    {"giroscopio", "Giroscópio", SALA_VIGA},
    {"acelerometro", "Acelerômetro", SALA_VIGA},
    {"touchpad_dois_dedos", "Touchpad, dois dedos", SALA_MOLDE},
    {"touchpad_clique", "Touchpad, clique", SALA_MOLDE},
    {"vibracao_forte", "Motor forte (esquerda)", SALA_IMPACTO},
    {"vibracao_fraca", "Motor fraco (direita)", SALA_IMPACTO},
    {"vibracao_isolamento", "Vibração só no controle certo", SALA_IMPACTO},
    {"lightbar", "Lightbar", SALA_IMPACTO},
    {"gatilho_resistencia", "Gatilho: resistência", SALA_GALERIA},
    {"gatilho_arma", "Gatilho: arma", SALA_GALERIA},
    {"gatilho_vibracao", "Gatilho: vibração", SALA_GALERIA},
    {"leds_jogador", "LEDs de jogador", SALA_GALERIA},
    {"microfone", "Microfone", SALA_VOZ},
    {"microfone_mudo", "Mudo do microfone", SALA_VOZ},
    {"led_microfone", "LED do microfone", SALA_VOZ},
    {"haptica_audio", "Háptica por áudio", SALA_CAMINHOS},
    {"alto_falante", "Alto-falante", SALA_CANTO},
    {"tudo_junto", "Tudo junto", SALA_PROVA},
};

const InfoSala *catalogo_sala(Sala s) {
  if ((int)s < 0 || s >= SALA_TOTAL)
    return NULL;
  return &SALAS[s];
}

const InfoFeature *catalogo_feature(Feature f) {
  if ((int)f < 0 || f >= F_TOTAL)
    return NULL;
  return &FEATURES[f];
}

/* O nome antigo da Viga no jogo (`giro`) ainda abre a Viga. */
static const struct {
  const char *antigo;
  Sala sala;
} APELIDOS[] = {
    {"giro", SALA_VIGA},
};

int catalogo_sala_por_chave(const char *chave) {
  for (int i = 0; chave && i < SALA_TOTAL; i++)
    if (strcmp(SALAS[i].chave, chave) == 0)
      return i;
  for (size_t i = 0; chave && i < sizeof(APELIDOS) / sizeof(APELIDOS[0]); i++)
    if (strcmp(APELIDOS[i].antigo, chave) == 0)
      return APELIDOS[i].sala;
  return -1;
}

int catalogo_feature_por_chave(const char *chave) {
  for (int i = 0; chave && i < F_TOTAL; i++)
    if (strcmp(FEATURES[i].chave, chave) == 0)
      return i;
  return -1;
}
