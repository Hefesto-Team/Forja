#ifndef FORJA_CATALOGO_H
#define FORJA_CATALOGO_H

#ifdef __cplusplus
extern "C" {
#endif

typedef enum Sala {
  SALA_CENTELHA = 0,
  SALA_VIGA,
  SALA_MOLDE,
  SALA_IMPACTO,
  SALA_GALERIA,
  SALA_VOZ,
  SALA_CAMINHOS,
  SALA_CANTO,
  SALA_PROVA,
  SALA_TOTAL
} Sala;

typedef enum Familia { FAM_ENTRADA = 0, FAM_SAIDA_HID, FAM_AUDIO, FAM_TUDO } Familia;

typedef enum Feature {
  F_BOTOES = 0,
  F_ANALOGICOS,
  F_GATILHOS_ANALOGICOS,
  F_GIROSCOPIO,
  F_ACELEROMETRO,
  F_TOUCH_DOIS_DEDOS,
  F_TOUCH_CLIQUE,
  F_VIBRACAO_FORTE,
  F_VIBRACAO_FRACA,
  F_VIBRACAO_ISOLAMENTO,
  F_LIGHTBAR,
  F_GATILHO_RESISTENCIA,
  F_GATILHO_ARMA,
  F_GATILHO_VIBRACAO,
  F_LEDS_JOGADOR,
  F_MICROFONE,
  F_MICROFONE_MUDO,
  F_LED_MICROFONE,
  F_HAPTICA_AUDIO,
  F_ALTO_FALANTE,
  F_TUDO_JUNTO,
  F_TOTAL
} Feature;

typedef struct InfoSala {
  const char *chave;
  const char *nome;
  const char *padrao;
  const char *acao;
  Familia familia;
} InfoSala;

typedef struct InfoFeature {
  const char *chave;
  const char *nome;
  Sala sala;
} InfoFeature;

const InfoSala *catalogo_sala(Sala s);
const InfoFeature *catalogo_feature(Feature f);
int catalogo_sala_por_chave(const char *chave);
int catalogo_feature_por_chave(const char *chave);

#ifdef __cplusplus
}
#endif

#endif
