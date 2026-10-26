#ifndef DEMO_SINTESE_H
#define DEMO_SINTESE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define SINT_TAXA 48000

typedef struct Onda {
  float *a;
  int n;
} Onda;

int sint_bigorna(Onda *o, float freq, float dur, float brilho, uint32_t semente);
int sint_martelada(Onda *o, float freq, uint32_t semente);
int sint_blip(Onda *o, float freq, float dur);
int sint_acorde(Onda *o, const float *freqs, int n, float espaco, float dur_nota);
int sint_fogo(Onda *o, float dur, uint32_t semente);
int sint_drone(Onda *o, float dur);
int sint_sopro(Onda *o, float dur, uint32_t semente);
int sint_tom(Onda *o, float freq, float dur, float rampa_s);
int sint_pulso(Onda *o, float freq, float dur, int batidas, float intervalo);
int sint_textura(Onda *o, float dur, float aspereza, uint32_t semente);
int sint_passo(Onda *o, int chao, uint32_t semente);
int sint_grito(Onda *o, float dur, uint32_t semente);
int sint_trilha(Onda *o, float tonica_midi, float bpm, int energia, uint32_t semente);
int sint_pio(Onda *o, float freq, int forma, uint32_t semente);

typedef enum MaterialHaptico {
  MATERIAL_METAL,
  MATERIAL_PEDRA,
  MATERIAL_AREIA,
  MATERIAL_GELO,
  MATERIAL_GRAMA,
  MATERIAL_LAMA,
  MATERIAL_MADEIRA,
  MATERIAL_TOTAL
} MaterialHaptico;
int sint_material(Onda *o, MaterialHaptico m, uint32_t semente);
const char *material_nome(MaterialHaptico m);
int material_por_nome(const char *nome);
void onda_liberar(Onda *o);

float onda_pico(const Onda *o);
float onda_rms(const Onda *o);
float onda_emenda(const Onda *o);

#ifdef __cplusplus
}
#endif

#endif
