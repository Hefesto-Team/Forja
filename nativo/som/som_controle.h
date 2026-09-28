/* O som de cada controle: o alto-falante, a háptica e o microfone de cada
 * jogador, achados como um jogo os acha (achar_som.h) e tocados pelo SDL do
 * módulo — um fluxo por dispositivo, paralelo ao som da TV, que é do Godot.
 *
 * A lista vem do SDL (o nome que o jogo mostra e os canais) e é enriquecida
 * pelo sistema, para achar PELO APARELHO:
 *
 *   - Linux: `LC_ALL=C pactl list sinks|sources` — o PipeWire responde pelo
 *     pipewire-pulse — dá o `sysfs.path` de cada nó, e dele o usb_device,
 *     que se compara com o do controle (o mesmo caminho do forja-speak);
 *   - Windows, e o .exe sob Proton: o WASAPI dá o ContainerId de cada
 *     endpoint, e o CfgMgr32 dá o do HID do controle (o caminho dos jogos que
 *     casam o áudio pelo container, segundo ValveSoftware/Proton#5900).
 *
 * Controle simulado (--simular) não tem dispositivo: o som dele vai para uma
 * saída VIRTUAL de quatro canais, que ninguém escuta a não ser o simulador —
 * o robô "ouve" o canal do alto-falante e "sente" os canais dos atuadores do
 * SEU controle. Os defeitos de som do simulador entram aqui. */
#ifndef FORJA_SOM_CONTROLE_H
#define FORJA_SOM_CONTROLE_H

#include <SDL3/SDL.h>

#include "achar_som.h"
#include "mixer.h"

#ifdef __cplusplus
extern "C" {
#endif

struct Forja;

typedef struct SaidaCtl {
  bool usada;
  bool virtual_;          /* a placa de mentira de um controle simulado */
  int no;                 /* índice na lista; -1 na virtual */
  SDL_AudioStream *fluxo;
  Mixer mixer;
  int canais;
  float *tmp;
  int tmp_quadros;
  float nivel[MIX_MAX_CANAIS]; /* virtual: o nível de cada canal agora (0..1) */
  int dono;               /* virtual: o lugar à mesa */
} SaidaCtl;

typedef struct SomJogador {
  int no[PAPEL_TOTAL];
  ComoAchou como[PAPEL_TOTAL];
  int canal_a[PAPEL_TOTAL], canal_b[PAPEL_TOTAL];
  int saida[PAPEL_TOTAL]; /* índice em `saidas` (alto-falante e háptica) */
  SDL_AudioStream *mic;
  float mic_nivel, mic_pico; /* 0..1 */
  long mic_quadros;          /* quadros em que chegou som do microfone */
  bool fone;                 /* o fone está no jack do controle (report USB, byte 53) */
  bool mic_virtual;
  float *escuta;             /* a bancada: as amostras cruas do microfone, sob pedido */
  int escuta_cap, escuta_n;
} SomJogador;

#define SOMC_MAX_SAIDAS 12

typedef struct SomControles {
  NoSom nos[SOM_MAX_NOS];
  int n;
  bool listou;
  SaidaCtl saidas[SOMC_MAX_SAIDAS];
  SomJogador j[4];
  char plataforma[96]; /* de onde veio o "pelo aparelho": "pactl (PipeWire)", "WASAPI"... */
} SomControles;

/* Refaz a lista e a escolha de todos (ao entrar numa sala de som). Abre o
 * som do SDL na primeira vez; sem ele, só os controles simulados têm som. */
void somc_preparar(struct Forja *a);
/* Fecha as saídas e os microfones (ao sair da sala de som, e no fim). */
void somc_encerrar(struct Forja *a);
bool somc_preparado(void);
/* A pessoa aponta: o próximo candidato para o papel (direcao +1/-1). */
void somc_trocar(struct Forja *a, int slot, PapelSom papel, int direcao);
bool somc_tem(struct Forja *a, int slot, PapelSom papel);
/* O papel tem dois canais distintos (a háptica da esquerda e a da direita)? */
bool somc_estereo(struct Forja *a, int slot, PapelSom papel);
const char *somc_nome(struct Forja *a, int slot, PapelSom papel);
ComoAchou somc_como(struct Forja *a, int slot, PapelSom papel);
/* De onde veio o "pelo aparelho" nesta máquina, ou por que não há som. */
const char *somc_plataforma(void);

/* Toca no alto-falante do controle. Devolve a voz, ou -1 sem alto-falante. */
int somc_falante(struct Forja *a, int slot, const Som *s, float ganho);
/* Toca nos atuadores: `esq` no esquerdo e `dir` no direito (um deles NULL
 * para um lado só). Devolve a voz do lado esquerdo (ou do direito). */
int somc_haptica(struct Forja *a, int slot, const Som *esq, const Som *dir, float ganho);
void somc_parar_tudo(struct Forja *a, int slot);
/* Uma vez por quadro: os níveis do microfone, o jack do fone e, na virtual,
 * o que chegou a cada canal. */
void somc_atualizar(struct Forja *a, float dt);
/* O microfone do jogador: nível (RMS) e pico recente, 0..1 (-54 dB..0 dB). */
float somc_mic_nivel(struct Forja *a, int slot);
float somc_mic_pico(struct Forja *a, int slot);
/* Quantos quadros trouxeram amostras do microfone (0: abriu e não chegou nada). */
long somc_mic_quadros(struct Forja *a, int slot);
/* Virtual: o que o controle simulado desse lugar "ouve" no alto-falante e
 * "sente" em cada atuador, 0..1. */
float somc_virtual_falante(struct Forja *a, int slot);
float somc_virtual_atuador(struct Forja *a, int slot, int lado);

/* A bancada (experimental/): grava as próximas `segundos` de amostras do
 * microfone do jogador (48 kHz, mono), a partir de agora — o que estava no
 * fluxo é descartado, para a primeira amostra ser de depois deste instante.
 * Só com microfone de verdade; devolve false sem ele. */
bool somc_escutar(struct Forja *a, int slot, float segundos);
/* As amostras gravadas até agora (NULL sem escuta). */
const float *somc_escuta(struct Forja *a, int slot, int *n);
void somc_escuta_parar(struct Forja *a, int slot);

/* Grava no relatório o alto-falante, o microfone e a háptica de cada um. */
void somc_relatorio(struct Forja *a);

/* Da plataforma (som_controle_linux.c / som_controle_windows.c / nenhum):
 * completam `usb` ou `container` de cada nó, e o do controle. */
void somc_plataforma_nos(SomControles *sc, char *rotulo, size_t tam);
bool somc_plataforma_pad(struct Forja *a, int slot, char *usb, size_t tam_usb, char *container, size_t tam_c);

#ifdef __cplusplus
}
#endif

#endif
