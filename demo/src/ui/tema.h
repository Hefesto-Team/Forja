/* O tema: a forja à noite.
 *
 * A identidade da demo sai do mito que dá nome ao projeto. Hefesto é o deus da
 * forja — e o único do Olimpo com deficiência, que construiu os próprios
 * auxílios: autômatos de ouro que o ajudavam a andar. Um driver de adaptação
 * para acessibilidade com esse nome pede exatamente esta cena: uma oficina
 * escura, brasa, bronze, o metal que acende quando é trabalhado.
 *
 *   - fundo quase preto e quente, como carvão;
 *   - bronze para molduras e texto secundário, ouro fundido para destaque;
 *   - brasa (laranja) para o que está vivo agora;
 *   - as quatro cores de jogador (azul, vermelho, verde, rosa) são as únicas
 *     cores frias da tela — o olho acha o jogador sem procurar.
 *
 * Nada aqui depende só de cor: todo veredito tem ícone e palavra, e o texto é
 * grande (Atkinson Hyperlegible, desenhada para baixa visão).
 */
#ifndef DEMO_TEMA_H
#define DEMO_TEMA_H

#include <SDL3/SDL.h>

/* A tela lógica. O SDL escala para a janela, com tarjas se a proporção mudar. */
#define TELA_L 1920
#define TELA_A 1080

extern const SDL_Color COR_FUNDO_0;
extern const SDL_Color COR_FUNDO_1;
extern const SDL_Color COR_CARVAO;
extern const SDL_Color COR_PAINEL;
extern const SDL_Color COR_PAINEL_CLARO;
extern const SDL_Color COR_BRONZE_ESCURO;
extern const SDL_Color COR_BRONZE;
extern const SDL_Color COR_BRONZE_CLARO;
extern const SDL_Color COR_OURO;
extern const SDL_Color COR_BRASA;
extern const SDL_Color COR_BRASA_VIVA;
extern const SDL_Color COR_TEXTO;
extern const SDL_Color COR_TEXTO_2;
extern const SDL_Color COR_TEXTO_3;
extern const SDL_Color COR_OK;
extern const SDL_Color COR_FALHA;
extern const SDL_Color COR_AVISO;
extern const SDL_Color COR_NEUTRO;

/* As cores de jogador na TELA, e as que vão para a LIGHTBAR (saturadas, e
 * fora da paleta padrão do SDL de propósito: quem estiver na frente do pad
 * pode tratar a paleta do SDL como "cor automática"). */
extern const SDL_Color COR_JOGADOR[4];
extern const SDL_Color COR_LIGHTBAR[4];
extern const char *NOME_COR_JOGADOR[4];

SDL_Color cor_alfa(SDL_Color c, float a);           /* a em [0,1] multiplica o alfa */
SDL_Color cor_mistura(SDL_Color a, SDL_Color b, float t);
SDL_Color cor_clarear(SDL_Color c, float t);        /* mistura com branco */
SDL_Color cor_escurecer(SDL_Color c, float t);      /* mistura com preto */
SDL_FColor cor_f(SDL_Color c);

/* Curvas de animação, t em [0,1]. */
float suave(float t);
float sai_rapido(float t);  /* ease-out cúbico */
float elastico(float t);
float limitar(float v, float a, float b);
float aproximar(float atual, float alvo, float taxa, float dt);

#endif
