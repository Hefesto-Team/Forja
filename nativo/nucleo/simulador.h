#ifndef FORJA_SIMULADOR_H
#define FORJA_SIMULADOR_H

#include <SDL3/SDL.h>

#define SIM_PISO_DA_SALA 0.12f

struct Forja;

typedef struct Percepcao {
  float forte, fraco;
  Uint64 rumble_ate_ms;
  Uint8 luz_r, luz_g, luz_b;
  bool luz_ok;
  Uint8 efeito[64];
  int n_efeito;
  Uint64 efeito_ms;
  int player_index;
  Uint8 gatilho_dir[11], gatilho_esq[11];
  int led_mic;
  int leds_jogador;
} Percepcao;

bool simulador_defeitos(const char *lista, char *erro, size_t tam_erro);
const char *simulador_defeitos_texto(void);

enum {
  DEFEITO_TROCA_CRUZ_CIRCULO = 1 << 0,
  DEFEITO_ANALOGICO_CURTO = 1 << 1,
  DEFEITO_GATILHO_DIGITAL = 1 << 2,
  DEFEITO_GIRO_INVERTIDO = 1 << 3,
  DEFEITO_ACEL_ESCALA = 1 << 4,
  DEFEITO_UM_DEDO = 1 << 5,
  DEFEITO_SEM_CLIQUE = 1 << 6,
  DEFEITO_MOTORES_TROCADOS = 1 << 7,
  DEFEITO_VIBRA_VIZINHO = 1 << 8,
  DEFEITO_LUZ_PARADA = 1 << 9,
  DEFEITO_GATILHO_MUDO = 1 << 10,
  DEFEITO_LEDS_ERRADOS = 1 << 11,
  DEFEITO_SEM_ALTO_FALANTE = 1 << 12,
  DEFEITO_SOM_VIZINHO = 1 << 13,
  DEFEITO_HAPTICA_TROCADA = 1 << 14,
  DEFEITO_MIC_SURDO = 1 << 15,
  DEFEITO_LED_MIC_PARADO = 1 << 16,
  DEFEITO_MUDO_NAO_CHEGA = 1 << 17,
  DEFEITO_HAPTICA_MUDA = 1 << 18,
  DEFEITO_ENGASGA = 1 << 19,
};
unsigned simulador_defeitos_agora(void);

void simulador_iniciar(struct Forja *a, int n);
void simulador_encerrar(struct Forja *a);
void simulador_atualizar(struct Forja *a, float dt);
void simulador_selecionar(int sim);
void simulador_manual_botao(int sim, int botao, bool baixo);
void simulador_manual_eixo(int sim, int eixo, float v);
void simulador_manual_giro(int sim, float gx, float gy, float gz);
void simulador_manual_dedo(int sim, int dedo, bool baixo, float x, float y);
void simulador_manual_fala(int sim, float nivel);
void simulador_manual_sacode(int sim, float g);
bool simulador_ativo(void);
bool simulador_cabo(int sim, bool ligado);
const Percepcao *simulador_percepcao(SDL_JoystickID id);
int simulador_selecionado(void);

bool robo_ativo(void);
void robo_apertar(struct Forja *a, int pad, SDL_GamepadButton b, float segundos);
void robo_eixo(struct Forja *a, int pad, SDL_GamepadAxis eixo, float valor, float segundos);
void robo_girar(struct Forja *a, int pad, float gx, float gy, float gz, float segundos);
void robo_sacudir(struct Forja *a, int pad, float g, float segundos);
void robo_tocar(struct Forja *a, int pad, int dedo, float x, float y, float segundos);
float robo_acaso(void);
void robo_falar(struct Forja *a, int pad, float nivel, float segundos);
float simulador_fala(SDL_JoystickID id);

#endif
