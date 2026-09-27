/* O simulador: controles de mentira, para jogar e provar SEM aparelho.
 *
 * `--simular N` pendura N gamepads virtuais do SDL (SDL_AttachVirtualJoystick)
 * com touchpad de dois dedos, giroscópio e acelerômetro. O teclado dirige o
 * selecionado (Tab troca); `--robo` põe um robô para jogar em todos.
 *
 *   Z ou Enter ✕ · X ou Esc ○ · C □ · V △ · Q L1 · E R1 · 1 L2 · 3 R2
 *   F L3 · G R3 · O Options · P Create · T clique do touchpad · M microfone
 *   setas: direcional · WASD: analógico esquerdo
 *   I/K inclina para a frente e para trás · J/L inclina para os lados
 *   B/N vira para os lados · H a martelada (sacode para baixo)
 *   mouse: o touchpad — botão esquerdo é um dedo; segure os dois botões e o
 *   segundo dedo segue o mouse enquanto o primeiro fica parado
 *
 * O ponto que importa: o robô só sabe o que um jogador saberia. Ele "sente" a
 * vibração, "vê" a lightbar e "sente" o gatilho pelos callbacks do joystick
 * virtual — exatamente o que chegaria ao plástico. Se o jogo mandasse a
 * vibração para o controle errado, o robô responderia errado, e o relatório
 * diria FALHOU. É a mesa, em miniatura, dentro do CI. */
#ifndef DEMO_SIMULADOR_H
#define DEMO_SIMULADOR_H

#include <SDL3/SDL.h>

struct App;

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
 *
 * Devolve false (e diz qual) se algum nome não existe. */
bool simulador_defeitos(const char *lista, char *erro, size_t tam_erro);
const char *simulador_defeitos_texto(void);

void simulador_iniciar(struct App *a, int n);
void simulador_encerrar(struct App *a);
/* O teclado dirige o controle simulado selecionado. Devolve true se usou. */
bool simulador_evento(struct App *a, const SDL_Event *e);
void simulador_atualizar(struct App *a, float dt);
bool simulador_ativo(void);
/* A percepção do controle simulado com esse id (NULL se não é simulado). */
const Percepcao *simulador_percepcao(SDL_JoystickID id);
int simulador_selecionado(void);

/* O robô: aperta, segura, gira, toca. `pad` é o índice em a->pads.pad[]. */
bool robo_ativo(void);
void robo_apertar(struct App *a, int pad, SDL_GamepadButton b, float segundos);
void robo_eixo(struct App *a, int pad, SDL_GamepadAxis eixo, float valor, float segundos);
void robo_girar(struct App *a, int pad, float gx, float gy, float gz, float segundos);
void robo_sacudir(struct App *a, int pad, float g, float segundos);
void robo_tocar(struct App *a, int pad, int dedo, float x, float y, float segundos);
/* Um número entre 0 e 1 do sorteio do robô (reação humana, erro, demora). */
float robo_acaso(void);

#endif
