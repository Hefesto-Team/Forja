/* O catálogo: as estações do FORJA 3D e as features que cada uma valida.
 *
 * Uma estação, uma família de features, os quatro jogando juntos; a estação
 * com tudo ligado vem por último. Toda feature aparece no relatório de todo
 * controle que entrou — com o veredito que teve, ou "não medido" quando a
 * estação dela não foi jogada. As chaves são as do `--sala=` do jogo. */
#ifndef FORJA_CATALOGO_H
#define FORJA_CATALOGO_H

#ifdef __cplusplus
extern "C" {
#endif

typedef enum Sala {
  SALA_CENTELHA = 0, /* botões, analógicos, gatilhos analógicos */
  SALA_VIGA,         /* giroscópio e acelerômetro */
  SALA_MOLDE,        /* touchpad: dois dedos e clique */
  SALA_IMPACTO,      /* dano direcional: motores, isolamento, lightbar */
  SALA_GALERIA,      /* gatilhos adaptativos, LEDs de jogador */
  SALA_VOZ,          /* microfone, mudo, LED do microfone */
  SALA_CAMINHOS,     /* háptica por áudio (canais 3 e 4) */
  SALA_CANTO,        /* alto-falante do controle */
  SALA_PROVA,        /* tudo ligado ao mesmo tempo */
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
  const char *chave;   /* "impacto" — estável, vai para o JSON e para o --sala= */
  const char *nome;    /* "O Impacto" */
  const char *padrao;  /* o padrão de jogo que a sala reproduz */
  const char *acao;    /* a linha única de ação na tela */
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
