/* O simulador: controles de mentira, para jogar e provar SEM aparelho.
 *
 * `--simular N` pendura N gamepads virtuais do SDL (SDL_AttachVirtualJoystick)
 * com touchpad de dois dedos, giroscópio e acelerômetro. O jogo dirige o
 * selecionado pelo teclado (simulador_manual_*); `--robo` põe um robô para
 * jogar em todos.
 *
 * O ponto que importa: o robô só sabe o que um jogador saberia. Ele "sente" a
 * vibração, "vê" a lightbar e "sente" o gatilho pelos callbacks do joystick
 * virtual — exatamente o que chegaria ao plástico. Se o jogo mandasse a
 * vibração para o controle errado, o robô responderia errado, e o relatório
 * diria FALHOU. É a mesa, em miniatura, dentro do CI. */
#ifndef FORJA_SIMULADOR_H
#define FORJA_SIMULADOR_H

#include <SDL3/SDL.h>

/* O nível do microfone simulado numa sala quieta (na escala da tela, ~-48 dB). */
#define SIM_PISO_DA_SALA 0.12f

struct Forja;

typedef struct Percepcao {
  float forte, fraco;     /* a vibração que está chegando, 0..1 */
  Uint64 rumble_ate_ms;
  Uint8 luz_r, luz_g, luz_b;
  bool luz_ok;
  Uint8 efeito[64];       /* o último payload de efeito que chegou */
  int n_efeito;
  Uint64 efeito_ms;
  int player_index;
  Uint8 gatilho_dir[11], gatilho_esq[11]; /* o estado que o gatilho "sente" */
  int led_mic;
  int leds_jogador;
} Percepcao;

/* Os defeitos de mentira: o que um intermediário quebrado faria com o
 * controle, para provar que as salas dizem FALHOU quando devem (a prova da
 * prova). `lista` é separada por vírgula:
 *
 *   troca-cruz-circulo  o ✕ chega como ○ e o ○ como ✕
 *   analogico-curto     os analógicos só chegam a 70% do curso
 *   gatilho-digital     L2 e R2 chegam só soltos ou no fundo
 *   giro-invertido      o eixo Z (rolagem) do giroscópio chega com o sinal trocado
 *   acel-escala         o acelerômetro chega dez vezes menor
 *   um-dedo             o segundo dedo do touchpad nunca chega
 *   sem-clique          o clique do touchpad nunca chega
 *   motores-trocados    o motor forte vibra no lugar do fraco, e vice-versa
 *   vibra-vizinho       a vibração de um controle chega no controle seguinte
 *   luz-parada          a lightbar não muda mais de cor
 *   gatilho-mudo        o efeito do gatilho nunca chega ao dedo
 *   leds-errados        os LEDs de jogador acendem uma luz a menos
 *   sem-alto-falante    o canal do alto-falante não chega ao plástico
 *   som-vizinho         o som de um controle sai no controle seguinte
 *   haptica-trocada     os atuadores da esquerda e da direita trocados
 *   haptica-muda        nada chega aos atuadores
 *   engasga             a cada 40 pacotes de efeito, a entrada para por 1,5 s
 *   mic-surdo           o microfone não manda nada
 *   led-mic-parado      o LED do microfone não muda mais
 *   mudo-nao-chega      o botão do microfone nunca chega
 *
 * Devolve false (e diz qual) se algum nome não existe. */
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
/* Os defeitos valendo agora (só dentro das salas e na bancada dos
 * experimentos); 0 fora delas. */
unsigned simulador_defeitos_agora(void);

void simulador_iniciar(struct Forja *a, int n);
void simulador_encerrar(struct Forja *a);
void simulador_atualizar(struct Forja *a, float dt);
/* À mão: o jogo lê o teclado e diz o que está apertado no controle de
 * mentira `sim` (0..N-1). O selecionado é o que o teclado dirige. */
void simulador_selecionar(int sim);
void simulador_manual_botao(int sim, int botao, bool baixo);
void simulador_manual_eixo(int sim, int eixo, float v);
void simulador_manual_giro(int sim, float gx, float gy, float gz);
void simulador_manual_dedo(int sim, int dedo, bool baixo, float x, float y);
void simulador_manual_fala(int sim, float nivel);
void simulador_manual_sacode(int sim, float g);
bool simulador_ativo(void);
/* A percepção do controle simulado com esse id (NULL se não é simulado). */
const Percepcao *simulador_percepcao(SDL_JoystickID id);
int simulador_selecionado(void);

/* O robô: aperta, segura, gira, toca. `pad` é o índice em a->pads.pad[]. */
bool robo_ativo(void);
void robo_apertar(struct Forja *a, int pad, SDL_GamepadButton b, float segundos);
void robo_eixo(struct Forja *a, int pad, SDL_GamepadAxis eixo, float valor, float segundos);
void robo_girar(struct Forja *a, int pad, float gx, float gy, float gz, float segundos);
void robo_sacudir(struct Forja *a, int pad, float g, float segundos);
void robo_tocar(struct Forja *a, int pad, int dedo, float x, float y, float segundos);
/* Um número entre 0 e 1 do sorteio do robô (reação humana, erro, demora). */
float robo_acaso(void);
/* O robô fala no microfone do controle dele (nível 0..1, por `segundos`). */
void robo_falar(struct Forja *a, int pad, float nivel, float segundos);
/* O que o microfone do controle simulado com esse id capta agora (0..1): a
 * voz do robô ou a barra de espaço do teclado. */
float simulador_fala(SDL_JoystickID id);

#endif
