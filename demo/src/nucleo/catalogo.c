/* O catálogo das salas e das features. Ver catalogo.h. */
#include "catalogo.h"

#include <string.h>

static const InfoSala SALAS[SALA_TOTAL] = {
    {"centelha", "A Centelha", "acender runas no tempo certo",
     "Aperte o botão que a runa mostra antes que ela apague.", FAM_ENTRADA},
    {"viga", "A Viga", "equilíbrio e mira por movimento",
     "Incline o controle para atravessar; sacuda para baixo para quebrar.", FAM_ENTRADA},
    {"molde", "O Molde", "desenhar e moldar no touchpad",
     "Dois dedos abrem o molde; o clique no touchpad carimba.", FAM_ENTRADA},
    {"cerco", "O Cerco", "dano direcional e vida na luz",
     "Sobreviva: o tiro da esquerda vibra a esquerda, e a luz apaga com a vida.", FAM_SAIDA_HID},
    {"galeria", "A Galeria", "armas com gatilho adaptativo",
     "Pistola com clique, metralhadora que treme, arco que pesa.", FAM_SAIDA_HID},
    {"cripta", "A Cripta", "terror: silêncio e susto",
     "Fique em silêncio: a cripta ouve o seu microfone.", FAM_AUDIO},
    {"caminhos", "Os Caminhos", "o chão que se sente nas mãos",
     "Ande de olhos fechados e diga por onde está pisando.", FAM_AUDIO},
    {"canto", "O Canto", "ritmo no alto-falante do controle",
     "A bigorna canta no SEU controle: repita o ritmo.", FAM_AUDIO},
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
    {"vibracao_forte", "Motor forte (esquerda)", SALA_CERCO},
    {"vibracao_fraca", "Motor fraco (direita)", SALA_CERCO},
    {"vibracao_isolamento", "Vibração só no controle certo", SALA_CERCO},
    {"lightbar", "Lightbar", SALA_CERCO},
    {"gatilho_resistencia", "Gatilho: resistência", SALA_GALERIA},
    {"gatilho_arma", "Gatilho: arma", SALA_GALERIA},
    {"gatilho_vibracao", "Gatilho: vibração", SALA_GALERIA},
    {"leds_jogador", "LEDs de jogador", SALA_GALERIA},
    {"microfone", "Microfone", SALA_CRIPTA},
    {"microfone_mudo", "Mudo do microfone", SALA_CRIPTA},
    {"led_microfone", "LED do microfone", SALA_CRIPTA},
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

/* Os nomes das salas do FORJA em Godot, que a folha de teste do Hefesto já
 * usa (`--sala=voz`), levam à sala que faz o mesmo papel aqui. */
static const struct {
  const char *antigo;
  Sala sala;
} APELIDOS[] = {
    {"voz", SALA_CRIPTA},
    {"impacto", SALA_CERCO},
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
