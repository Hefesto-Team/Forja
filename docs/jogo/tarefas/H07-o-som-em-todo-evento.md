# H07 — O som em todo evento

**Sprint:** H · **Tamanho:** G · **Estimativa:** US$ 3,5 · **Depende de:** F00, F05, F06, H04

## Por quê

O alto-falante do controle quase não toca, e há evento sem som. Todo evento
tem som na TV **e** algo no controle do dono: a placa de áudio de cada
controle abre na entrada do lugar e fica aberta; o cavaleiro tem o seu pio;
o acerto perfeito toca a nota do jogador e o erro a nota quebrada; o
material tem a sua textura nos atuadores; nada corta de uma vez; a música
reage; e cada som mandado ao controle vai para o registro.

## Ler antes

- [A agenda do alto-falante](../05-haptica-e-controle.md#a-agenda-do-alto-falante) e [a háptica por material](../05-haptica-e-controle.md#a-háptica-por-material)
- [A música que reage](../04-ritmo-e-audio.md#a-música-que-reage)
- [O registro v2](../13-arquitetura.md#o-registro-v2--f06-h01-h02-g02-h07) (o tipo `som_controle`)

## O estado de hoje

- **A placa abre e fecha a cada sala.** `godot/scripts/salas/sala_jogo.gd:92-97`
  chama `Forja.som_preparar(...)` na entrada de toda sala, e
  `sala_jogo.gd:106-107` chama `Forja.som_encerrar()` na saída; o mesmo em
  `godot/scripts/salas/prova.gd:93` e `:109`, em
  `godot/scripts/salas/bancada.gd:108` e `:116`, e no pódio
  (`godot/scripts/main.gd:436` e `:516`). No lobby e no salão, o controle não
  tem som. `somc_preparar()` (`nativo/som/som_controle.c:280-297`) fecha tudo,
  lista de novo (no Linux, roda o `pactl`) e reabre.
- **O alto-falante toca por cima** (`nativo/som/som_controle.c:370-388`,
  `somc_falante`): dois sons no mesmo controle se somam. O 05 diz "nunca dois
  sons ao mesmo tempo no mesmo controle".
- **O corte**: o mixer tem fade de 40 ms só no `mixer_parar(id, suave)`
  (`nativo/som/mixer.c:95`); `mixer_parar_tudo` (`mixer.c:74-79`) corta de
  uma vez; roubar voz (sem voz livre, `mixer.c:31`) corta de uma vez. O 04
  pede 15 a 30 ms.
- **Os sons do controle** são os sintetizados de `nativo/som/sons_salas.c`
  (`sino`, `pulso`, `nota`, `nota_alta`, `grito`, `tropeco`, `clique`,
  `pronto`, `tom`, `passo:<chão>:<variação>`) e as gravações que o jogo
  registra (`som_registrar`, `nativo/godot/forja_som.cpp:57-87`). Não há pio,
  nem nota por lugar, nem material.
- **O registro** não tem o som do controle: só a linha `fone`
  (`som_controle.c:405`).
- **A música** toca no barramento principal (`godot/scripts/musica.gd:36-40`),
  sem efeito nenhum.
- `godot/project.godot` não tem `default_bus_layout.tres`: há só o Master.
- O kit (H04): `Minigame._reagir(l, j)` chama `Forja.sentir(...)` e toca a
  nota na TV.
- **Medido nesta preparação**: o código de "O alvo" (C e GDScript) foi
  compilado (`scripts/compilar.sh testes` e `linux`) e rodado com a prova do
  jogo numa cópia do projeto: verde, com o pio chegando só no controle de
  quem entrou (0,22 a 0,25 no alto-falante virtual; 0,00 nos outros), a
  placa aberta depois de cada sala, O Canto e Os Caminhos passando, e
  400 linhas `som_controle` por lugar numa prova. Um nome pegou: `Material`
  colide com o `godot::Material` do godot-cpp no C++ (o `using namespace
  godot`) — o tipo C se chama `MaterialHaptico`.

## O alvo

(**Novo** no 13: `Forja.som_pronto()`, `Forja.tocar_material(l, material,
sensacao, forca)`, `Musica.reagir(evento)`, os sons `pio:<boneco>`,
`nota:<lugar>`, `nota_quebrada:<lugar>`, `coleta`, `material:<nome>`, e a
linha `som_controle` com `lugar`, `seq`, `papel`, `som`, `ganho`, `placa`.)

### O C

`nativo/som/sintese.h`, antes de `void onda_liberar(Onda *o);`:

```c
/* O pio do cavaleiro (docs/jogo/05-haptica-e-controle.md#a-agenda-do-alto-falante):
 * duas notas curtas, a segunda uma quinta acima; cada boneco tem a sua
 * `freq`. forma 0: seno; 1: quadrada suave (o boneco mais "metálico"). */
int sint_pio(Onda *o, float freq, int forma, uint32_t semente);

/* A háptica por material (docs/jogo/05-haptica-e-controle.md#a-háptica-por-material):
 * a mesma onda vai para os atuadores e, mais baixa, para o alto-falante. */
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
const char *material_nome(MaterialHaptico m); /* "metal", "pedra"... */
int material_por_nome(const char *nome); /* -1 se não existe; "plasma" é a lama */
```

`nativo/som/sintese.c`, ao fim:

```c
/* ---------- o pio do cavaleiro ---------- */

int sint_pio(Onda *o, float freq, int forma, uint32_t semente) {
  const float nota = 0.09f, espaco = 0.07f;
  if (alocar(o, espaco + nota + 0.02f))
    return -1;
  g_lcg = semente * 2654435761u + 7u;
  for (int k = 0; k < 2; k++) {
    float f = k == 0 ? freq : freq * 1.4983f; /* a quinta */
    int ini = (int)(k * espaco * SINT_TAXA);
    int n = (int)(nota * SINT_TAXA);
    float desvio = 1.0f + 0.004f * ruido(); /* cada pio um nada diferente */
    for (int i = 0; i < n && ini + i < o->n; i++) {
      float t = (float)i / SINT_TAXA;
      float fase = PI2 * f * desvio * t * (1.0f + 0.06f * t / nota); /* sobe um pouco: é um pio */
      float x = sinf(fase);
      if (forma == 1)
        x = tanhf(3.0f * x) * 0.8f;
      float env = t < 0.004f ? t / 0.004f : expf(-(t - 0.004f) / (nota * 0.35f));
      o->a[ini + i] += x * env;
    }
  }
  rampas(o, 0.002f, 0.01f);
  normalizar(o, 0.8f);
  return 0;
}

/* ---------- a háptica por material ---------- */

static const char *NOMES_MATERIAL[MATERIAL_TOTAL] = {"metal", "pedra", "areia", "gelo", "grama", "lama", "madeira"};

const char *material_nome(MaterialHaptico m) { return m >= 0 && m < MATERIAL_TOTAL ? NOMES_MATERIAL[m] : ""; }

int material_por_nome(const char *nome) {
  if (!nome)
    return -1;
  if (!strcmp(nome, "plasma"))
    return MATERIAL_LAMA;
  for (int m = 0; m < MATERIAL_TOTAL; m++)
    if (!strcmp(nome, NOMES_MATERIAL[m]))
      return m;
  return -1;
}

/* Um pulso de seno com ataque e queda exponencial, somado em `ini`. */
static void pulso_grave(Onda *o, float ini_s, float freq, float dur, float queda, float vol) {
  int ini = (int)(ini_s * SINT_TAXA), n = (int)(dur * SINT_TAXA);
  for (int i = 0; i < n && ini + i < o->n; i++) {
    float t = (float)i / SINT_TAXA;
    float env = (t < 0.002f ? t / 0.002f : 1.0f) * expf(-t / queda);
    o->a[ini + i] += vol * env * sinf(PI2 * freq * t);
  }
}

/* Ruído grave (um passa-baixa de um polo em `corte`), com envelope em sino. */
static void ruido_grave(Onda *o, float corte, float vol) {
  float k = 1.0f - expf(-PI2 * corte / SINT_TAXA), y = 0;
  for (int i = 0; i < o->n; i++) {
    y += k * (ruido() - y);
    float env = sinf(3.14159f * (float)i / o->n);
    o->a[i] += vol * env * y;
  }
}

int sint_material(Onda *o, MaterialHaptico m, uint32_t semente) {
  static const float DUR[MATERIAL_TOTAL] = {0.06f, 0.08f, 0.14f, 0.03f, 0.22f, 0.28f, 0.12f};
  if (m < 0 || m >= MATERIAL_TOTAL || alocar(o, DUR[m]))
    return -1;
  g_lcg = semente * 2654435761u + 11u;
  switch (m) {
  case MATERIAL_METAL: /* clique seco, duro: pulso curto de 150 Hz, ataque instantâneo */
    pulso_grave(o, 0, 150.0f, 0.06f, 0.015f, 1.0f);
    break;
  case MATERIAL_PEDRA: /* batida surda: 80 Hz, 60 ms, decaimento rápido */
    pulso_grave(o, 0, 80.0f, 0.06f, 0.02f, 1.0f);
    break;
  case MATERIAL_AREIA: /* granulado espalhado: ruído abaixo de 200 Hz, baixo */
    ruido_grave(o, 200.0f, 1.0f);
    break;
  case MATERIAL_GELO: /* fino e localizado: 180 Hz, 20 ms (um atuador só: quem toca decide) */
    pulso_grave(o, 0, 180.0f, 0.02f, 0.008f, 1.0f);
    break;
  case MATERIAL_GRAMA: /* macio: ruído grave, envelope longo */
    ruido_grave(o, 120.0f, 1.0f);
    break;
  case MATERIAL_LAMA: /* pesado e lento: 60 Hz com vibrato lento */
    for (int i = 0; i < o->n; i++) {
      float t = (float)i / SINT_TAXA;
      float env = sinf(3.14159f * t / DUR[m]);
      o->a[i] = env * sinf(PI2 * 60.0f * t + 2.5f * sinf(PI2 * 4.0f * t));
    }
    break;
  case MATERIAL_MADEIRA: /* oco: 110 Hz, duas batidas curtas */
    pulso_grave(o, 0, 110.0f, 0.03f, 0.012f, 1.0f);
    pulso_grave(o, 0.06f, 110.0f, 0.03f, 0.012f, 0.8f);
    break;
  default:
    break;
  }
  rampas(o, 0.001f, 0.004f);
  normalizar(o, m == MATERIAL_AREIA || m == MATERIAL_GRAMA ? 0.5f : 0.95f);
  return 0;
}
```

`nativo/som/rampa.h` (novo):

```c
/* As rampas do som no controle (docs/jogo/04-ritmo-e-audio.md#a-música-que-reage):
 * cortar um som vai a zero em 15 a 30 ms, nunca de uma vez. Pura, sem SDL:
 * provada em nativo/testes/prova_som.c; o mixer usa. */
#ifndef FORJA_RAMPA_H
#define FORJA_RAMPA_H

#ifdef __cplusplus
extern "C" {
#endif

#define RAMPA_SAIDA_MS 20.0f

/* Quanto o ganho anda por amostra para ir de 1 a 0 em `ms`, na `taxa`. */
float rampa_passo(int taxa, float ms);
/* Um passo do ganho `atual` rumo ao `alvo`, sem passar dele. */
float rampa_andar(float atual, float alvo, float passo);

#ifdef __cplusplus
}
#endif

#endif
```

`nativo/som/rampa.c` (novo):

```c
/* As rampas. Ver rampa.h. */
#include "rampa.h"

float rampa_passo(int taxa, float ms) {
  float n = (float)taxa * ms / 1000.0f;
  return n > 1.0f ? 1.0f / n : 1.0f;
}

float rampa_andar(float atual, float alvo, float passo) {
  if (atual < alvo)
    return atual + passo >= alvo ? alvo : atual + passo;
  return atual - passo <= alvo ? alvo : atual - passo;
}
```

E as mudanças nos arquivos que já existem, como diff (o contexto é o de
hoje; se outra ficha mexeu perto, aplique à mão):

```diff
--- a/nativo/som/sons_salas.h
+++ b/nativo/som/sons_salas.h
@@ -5,12 +5,14 @@
 #define FORJA_SONS_SALAS_H

 #include "mixer.h"
+#include "sintese.h"

 #ifdef __cplusplus
 extern "C" {
 #endif

 #define SONS_PASSOS_VARIANTES 3
+#define SONS_PIOS 12 /* um pio por boneco (player.gd, MODELOS; a G08 chega a doze) */

 typedef struct SonsSalas {
   Som sino;     /* o teste do alto-falante */
@@ -23,11 +25,18 @@
   Som pronto;   /* o especial carregado, só no controle de quem tem */
   Som tom;      /* a bancada: o tom de 1 kHz do eco */
   Som passo[4][SONS_PASSOS_VARIANTES]; /* o chão (chao.h) e a variação */
+  Som pio[SONS_PIOS];           /* o pio de cada boneco, quando o lugar entra (H07) */
+  Som nota_lugar[4];            /* a nota de cada lugar, limpa: o acerto perfeito */
+  Som nota_quebrada[4];         /* a mesma nota, quebrada: o erro */
+  Som coleta;                   /* o tilintar da coleta */
+  Som material[MATERIAL_TOTAL]; /* a háptica por material (sintese.h) */
 } SonsSalas;

 const SonsSalas *sons_salas(void);
 /* Um som pelo nome: "sino", "pulso", "nota", "nota_alta", "grito", "tropeco",
- * "clique", "pronto", "tom" ou "passo:<chão>:<variação>". NULL se não existe. */
+ * "clique", "pronto", "tom", "coleta", "passo:<chão>:<variação>",
+ * "pio:<boneco>", "nota:<lugar>", "nota_quebrada:<lugar>" ou
+ * "material:<nome>". NULL se não existe. */
 const Som *sons_salas_por_nome(const char *nome);
 void sons_salas_liberar(void);

--- a/nativo/som/sons_salas.c
+++ b/nativo/som/sons_salas.c
@@ -48,6 +48,27 @@
       sint_passo(&o, c, (uint32_t)(100 + c * 10 + v));
       som_de_onda(&g_sons.passo[c][v], &o);
     }
+  /* o pio de cada boneco: uma escala pentatônica a partir do dó 5 */
+  static const float PIO_HZ[SONS_PIOS] = {523.25f, 587.33f, 659.25f, 783.99f, 880.0f, 1046.5f,
+                                          554.37f, 622.25f, 739.99f, 830.61f, 932.33f, 1108.7f};
+  for (int k = 0; k < SONS_PIOS; k++) {
+    sint_pio(&o, PIO_HZ[k], k % 2, 40u + (uint32_t)k);
+    som_de_onda(&g_sons.pio[k], &o);
+  }
+  /* a nota de cada lugar (o hoqueto: dó, ré, fá, sol) e a mesma, quebrada */
+  static const float NOTA_HZ[4] = {523.25f, 587.33f, 698.46f, 783.99f};
+  for (int l = 0; l < 4; l++) {
+    sint_bigorna(&o, NOTA_HZ[l], 0.42f, 1.1f, 50u + (uint32_t)l);
+    som_de_onda(&g_sons.nota_lugar[l], &o);
+    sint_bigorna(&o, NOTA_HZ[l] * 0.9659f, 0.2f, 0.4f, 60u + (uint32_t)l); /* 60 cents abaixo, curta e baça */
+    som_de_onda(&g_sons.nota_quebrada[l], &o);
+  }
+  sint_pulso(&o, 2637.0f, 0.03f, 2, 0.06f);
+  som_de_onda(&g_sons.coleta, &o);
+  for (int m = 0; m < MATERIAL_TOTAL; m++) {
+    sint_material(&o, (MaterialHaptico)m, 70u + (uint32_t)m);
+    som_de_onda(&g_sons.material[m], &o);
+  }
   g_prontos = true;
   return &g_sons;
 }
@@ -66,6 +87,23 @@
       var = -var;
     return &s->passo[chao][var % SONS_PASSOS_VARIANTES];
   }
+  /* os que levam um número ou um nome depois dos dois pontos (H07) */
+  if (!SDL_strncmp(nome, "pio:", 4)) {
+    long k = strtol(nome + 4, NULL, 10);
+    return k >= 0 && k < SONS_PIOS ? &s->pio[k] : NULL;
+  }
+  if (!SDL_strncmp(nome, "nota:", 5)) {
+    long l = strtol(nome + 5, NULL, 10);
+    return l >= 0 && l < 4 ? &s->nota_lugar[l] : NULL;
+  }
+  if (!SDL_strncmp(nome, "nota_quebrada:", 14)) {
+    long l = strtol(nome + 14, NULL, 10);
+    return l >= 0 && l < 4 ? &s->nota_quebrada[l] : NULL;
+  }
+  if (!SDL_strncmp(nome, "material:", 9)) {
+    int m = material_por_nome(nome + 9);
+    return m >= 0 ? &s->material[m] : NULL;
+  }
   static const struct {
     const char *nome;
     size_t desloc;
@@ -74,7 +112,7 @@
       {"nota", offsetof(SonsSalas, nota)},       {"nota_alta", offsetof(SonsSalas, nota_alta)},
       {"grito", offsetof(SonsSalas, grito)},     {"tropeco", offsetof(SonsSalas, tropeco)},
       {"clique", offsetof(SonsSalas, clique)},   {"pronto", offsetof(SonsSalas, pronto)},
-      {"tom", offsetof(SonsSalas, tom)},
+      {"tom", offsetof(SonsSalas, tom)},         {"coleta", offsetof(SonsSalas, coleta)},
   };
   for (size_t i = 0; i < sizeof(TABELA) / sizeof(TABELA[0]); i++)
     if (!SDL_strcmp(nome, TABELA[i].nome))
@@ -97,5 +135,14 @@
   for (int c = 0; c < 4; c++)
     for (int v = 0; v < SONS_PASSOS_VARIANTES; v++)
       som_liberar(&g_sons.passo[c][v]);
+  for (int k = 0; k < SONS_PIOS; k++)
+    som_liberar(&g_sons.pio[k]);
+  for (int l = 0; l < 4; l++) {
+    som_liberar(&g_sons.nota_lugar[l]);
+    som_liberar(&g_sons.nota_quebrada[l]);
+  }
+  som_liberar(&g_sons.coleta);
+  for (int m = 0; m < MATERIAL_TOTAL; m++)
+    som_liberar(&g_sons.material[m]);
   g_prontos = false;
 }
--- a/nativo/som/mixer.c
+++ b/nativo/som/mixer.c
@@ -3,6 +3,8 @@

 #include <math.h>

+#include "rampa.h"
+
 void mixer_iniciar(Mixer *m, int canais) {
   SDL_memset(m, 0, sizeof(*m));
   m->trava = SDL_CreateMutex();
@@ -71,10 +73,11 @@
   SDL_UnlockMutex(m->trava);
 }

+/* Todas as vozes vão a zero pela rampa de saída (nunca de uma vez). */
 void mixer_parar_tudo(Mixer *m) {
   SDL_LockMutex(m->trava);
   for (int i = 0; i < MIX_MAX_VOZES; i++)
-    m->voz[i].ativa = false;
+    m->voz[i].fade_alvo = 0;
   SDL_UnlockMutex(m->trava);
 }

@@ -92,7 +95,7 @@
   int nc = m->canais;
   SDL_memset(saida, 0, sizeof(float) * (size_t)quadros * (size_t)nc);
   SDL_LockMutex(m->trava);
-  const float passo_fade = 1.0f / (MIX_TAXA * 0.04f); /* 40 ms */
+  const float passo_fade = rampa_passo(MIX_TAXA, RAMPA_SAIDA_MS);
   for (int i = 0; i < MIX_MAX_VOZES; i++) {
     Voz *v = &m->voz[i];
     if (!v->ativa)
@@ -109,9 +112,7 @@
         }
       }
       if (v->fade != v->fade_alvo) {
-        v->fade += v->fade_alvo > v->fade ? passo_fade : -passo_fade;
-        if (fabsf(v->fade - v->fade_alvo) < passo_fade)
-          v->fade = v->fade_alvo;
+        v->fade = rampa_andar(v->fade, v->fade_alvo, passo_fade);
         if (v->fade <= 0 && v->fade_alvo <= 0) {
           v->ativa = false;
           break;
--- a/nativo/som/som_controle.h
+++ b/nativo/som/som_controle.h
@@ -84,11 +84,14 @@
 /* De onde veio o "pelo aparelho" nesta máquina, ou por que não há som. */
 const char *somc_plataforma(void);

-/* Toca no alto-falante do controle. Devolve a voz, ou -1 sem alto-falante. */
-int somc_falante(struct Forja *a, int slot, const Som *s, float ganho);
+/* Toca no alto-falante do controle — um som por vez: o anterior daquele
+ * alto-falante sai pela rampa. Grava o `som_controle` na linha do tempo
+ * (`nome`: o nome que o jogo pediu). Devolve a voz, ou -1 sem alto-falante. */
+int somc_falante(struct Forja *a, int slot, const Som *s, float ganho, const char *nome);
 /* Toca nos atuadores: `esq` no esquerdo e `dir` no direito (um deles NULL
- * para um lado só). Devolve a voz do lado esquerdo (ou do direito). */
-int somc_haptica(struct Forja *a, int slot, const Som *esq, const Som *dir, float ganho);
+ * para um lado só), e grava o `som_controle`. Devolve a voz do lado
+ * esquerdo (ou do direito). */
+int somc_haptica(struct Forja *a, int slot, const Som *esq, const Som *dir, float ganho, const char *nome);
 void somc_parar_tudo(struct Forja *a, int slot);
 /* Uma vez por quadro: os níveis do microfone, o jack do fone e, na virtual,
  * o que chegou a cada canal. */
--- a/nativo/som/som_controle.c
+++ b/nativo/som/som_controle.c
@@ -13,6 +13,25 @@
 static bool g_preparado;
 static bool g_audio_tentou, g_audio_ok;
 static char g_sem_audio[200];
+static int g_voz_falante[MAX_JOGADORES]; /* a última voz de cada alto-falante: um som por vez */
+static long g_seq_som[MAX_JOGADORES];    /* os sons mandados a cada lugar, em ordem */
+
+
+/* Cada som mandado a um controle, na linha do tempo (o registro v2): o
+ * lugar, a ordem, o papel, o som, o ganho e se havia placa para ele. */
+static void registrar_som(Forja *a, int slot, const char *papel, const char *nome, float ganho, bool placa) {
+  if (slot < 0 || slot >= MAX_JOGADORES)
+    return;
+  Evento ev;
+  ev_iniciar(&ev, &a->lt, "som_controle", slot + 1);
+  ev_int(&ev, "lugar", slot);
+  ev_int(&ev, "seq", ++g_seq_som[slot]);
+  ev_str(&ev, "papel", papel);
+  ev_str(&ev, "som", nome ? nome : "");
+  ev_num(&ev, "ganho", ganho);
+  ev_bool(&ev, "placa", placa);
+  ev_fim(&ev, &a->lt);
+}

 static float limitar(float v, float a, float b) { return v < a ? a : (v > b ? b : v); }
 static float aproximar(float atual, float alvo, float taxa, float dt) {
@@ -255,6 +274,7 @@

 static void zerar(void) {
   SDL_memset(&g_sc, 0, sizeof(g_sc));
+  SDL_memset(g_voz_falante, 0, sizeof(g_voz_falante));
   for (int s = 0; s < MAX_JOGADORES; s++)
     for (int p = 0; p < PAPEL_TOTAL; p++)
       g_sc.j[s].no[p] = g_sc.j[s].saida[p] = -1;
@@ -367,8 +387,10 @@

 /* ---------- tocar ---------- */

-int somc_falante(Forja *a, int slot, const Som *s, float ganho) {
-  if (!somc_tem(a, slot, PAPEL_ALTO_FALANTE) || !s)
+int somc_falante(Forja *a, int slot, const Som *s, float ganho, const char *nome) {
+  bool tem = somc_tem(a, slot, PAPEL_ALTO_FALANTE);
+  registrar_som(a, slot, "alto_falante", nome, ganho, tem);
+  if (!tem || !s)
     return -1;
   SomJogador *j = &g_sc.j[slot];
   SaidaCtl *sd = &g_sc.saidas[j->saida[PAPEL_ALTO_FALANTE]];
@@ -380,7 +402,10 @@
   if (j->fone && !sd->virtual_ && j->no[PAPEL_ALTO_FALANTE] >= 0 &&
       g_sc.nos[j->no[PAPEL_ALTO_FALANTE]].tipo == NO_DUALSENSE_SAIDA)
     g[0] = g[1] = ganho;
-  return mixer_tocar(&sd->mixer, s, g, false);
+  /* nunca dois sons ao mesmo tempo no mesmo alto-falante (docs/jogo/05) */
+  mixer_parar(&sd->mixer, g_voz_falante[slot], true);
+  g_voz_falante[slot] = mixer_tocar(&sd->mixer, s, g, false);
+  return g_voz_falante[slot];
 }

 /* O jack do fone: plugou, o som do controle muda para o fone (as duas
@@ -407,8 +432,10 @@
   ev_fim(&ev, &a->lt);
 }

-int somc_haptica(Forja *a, int slot, const Som *esq, const Som *dir, float ganho) {
-  if (!somc_tem(a, slot, PAPEL_HAPTICA))
+int somc_haptica(Forja *a, int slot, const Som *esq, const Som *dir, float ganho, const char *nome) {
+  bool tem = somc_tem(a, slot, PAPEL_HAPTICA);
+  registrar_som(a, slot, "haptica", nome, ganho, tem);
+  if (!tem)
     return -1;
   SomJogador *j = &g_sc.j[slot];
   SaidaCtl *sd = &g_sc.saidas[j->saida[PAPEL_HAPTICA]];
--- a/nativo/godot/forja_som.cpp
+++ b/nativo/godot/forja_som.cpp
@@ -141,13 +141,19 @@
 }

 int ForjaControles::som_falante(int lugar, const String &som, float ganho) {
-  return aberto_ ? somc_falante(FORJA, lugar, som_do_nome(som), ganho) : -1;
+  if (!aberto_)
+    return -1;
+  CharString nome = som.utf8();
+  return somc_falante(FORJA, lugar, som_do_nome(som), ganho, nome.get_data());
 }

 int ForjaControles::som_haptica(int lugar, const String &esq, const String &dir, float ganho) {
   if (!aberto_)
     return -1;
-  return somc_haptica(FORJA, lugar, som_do_nome(esq), som_do_nome(dir), ganho);
+  /* o nome no registro: o do lado que toca, ou "esquerdo|direito" quando são dois */
+  String quais = esq.is_empty() ? dir : (dir.is_empty() || dir == esq ? esq : esq + String("|") + dir);
+  CharString nome = quais.utf8();
+  return somc_haptica(FORJA, lugar, som_do_nome(esq), som_do_nome(dir), ganho, nome.get_data());
 }

 void ForjaControles::som_parar(int lugar) {
--- a/nativo/CMakeLists.txt
+++ b/nativo/CMakeLists.txt
@@ -64,6 +64,7 @@
   nucleo/taxa.c
   nucleo/texto_buf.c
   nucleo/utf8.c
+  som/rampa.c
   som/sintese.c
 )
 target_include_directories(forja_nucleo PUBLIC nucleo som)
```

(`seq` é um contador por lugar só dos sons. Se a F06 já criou o contador de
`seq` por lugar das saídas — `grep -rn "seq" nativo/nucleo/*.h` —, use o dela
no lugar do `g_seq_som`, para os dois tipos saírem numa ordem só.)

### O GDScript

`godot/scripts/forja.gd`, na seção do som de cada controle:

```gdscript
## A placa de áudio dos controles está aberta (H07: ela abre na entrada do
## lugar e fica aberta até ele sair)?
func som_pronto() -> bool:
	return ctl.som_preparado() if modulo else false


## A textura de um material na mão do lugar (docs/jogo/05#a-háptica-por-material):
## no cabo, a onda nos atuadores e, mais baixa, no alto-falante; sem placa
## (o rádio), a sensação pelo rumble — nunca os dois no mesmo instante
## (docs/jogo/05, a suspeita e). O gelo é de um atuador só.
func tocar_material(l: int, material: String, sensacao: String, forca := 1.0) -> void:
	var nome := "material:" + material
	if som_tem(l, PAPEL_HAPTICA):
		som_haptica(l, nome, "" if material == "gelo" else nome, forca)
		som_falante(l, nome, 0.35 * forca)
	else:
		sentir(l, sensacao)
```

`godot/scripts/musica.gd`: no `_ready()`, `_criar_o_barramento()` antes do
laço dos tocadores e `p.bus = BUS` em cada tocador; e, ao fim:

```gdscript
# ---------------------------------------------------------------- a música que reage (H07) --

const BUS := "Musica"
const ABERTO_HZ := 20000.0
var _bus := -1
var _passa_baixa: AudioEffectLowPassFilter = null
var _tw_reacao: Tween = null


## O barramento da música, com o passa-baixa aberto (chamado no _ready, antes
## dos tocadores). A música manda no Master, onde está o volume da TV.
func _criar_o_barramento() -> void:
	_bus = AudioServer.get_bus_index(BUS)
	if _bus < 0:
		_bus = AudioServer.bus_count
		AudioServer.add_bus(_bus)
		AudioServer.set_bus_name(_bus, BUS)
		AudioServer.set_bus_send(_bus, "Master")
		_passa_baixa = AudioEffectLowPassFilter.new()
		_passa_baixa.cutoff_hz = ABERTO_HZ
		AudioServer.add_bus_effect(_bus, _passa_baixa, 0)
	else:
		_passa_baixa = AudioServer.get_bus_effect(_bus, 0) as AudioEffectLowPassFilter


## A música reage ao jogo (docs/jogo/04#a-música-que-reage): "erro" abafa por
## 300 ms; "perfeito" abaixa 2 dB por 80 ms (o golpe aparece por cima);
## "combo" (oito perfeitos seguidos) sobe 1,5 dB por 2 s.
func reagir(evento: String) -> void:
	if _tw_reacao:
		_tw_reacao.kill()
	_passa_baixa.cutoff_hz = ABERTO_HZ
	_volume(0.0)
	_tw_reacao = create_tween()
	match evento:
		"erro":
			_passa_baixa.cutoff_hz = 600.0
			_tw_reacao.tween_property(_passa_baixa, "cutoff_hz", ABERTO_HZ, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		"perfeito":
			_volume(-2.0)
			_tw_reacao.tween_interval(0.08)
			_tw_reacao.tween_callback(_volume.bind(0.0))
		"combo":
			_volume(1.5)
			_tw_reacao.tween_interval(2.0)
			_tw_reacao.tween_method(_volume, 1.5, 0.0, 0.3)


func _volume(db: float) -> void:
	AudioServer.set_bus_volume_db(_bus, db)
```

`godot/scripts/minigames/minigame.gd`: as constantes
`const COMBO := 8` e `var _perfeitos_seguidos := [0, 0, 0, 0]`, e o
`_reagir` passa a ser:

```gdscript
func _reagir(l: int, j: int) -> void:
	var p := jogador(l)
	var pos := p.global_position + Vector3(0, 1.2, 0) if p else Vector3(RAIAS[l], 1.2, Z_JOGADOR)
	if j == Ritmo.ERRO:
		_perfeitos_seguidos[l] = 0
		Forja.sentir(l, "erro")
		Forja.som_falante(l, "nota_quebrada:%d" % l, 0.7)
		Som.tocar("falha", pos, -6.0)
		Musica.reagir("erro")
		return
	var perfeito := j == Ritmo.PERFEITO
	# a textura do material na mão (no cabo) ou a sensação pelo rumble (no rádio)
	Forja.tocar_material(l, str(ficha.material), "perfeito" if perfeito else "acerto", 1.0 if perfeito else 0.7)
	Som.tocar("nota", pos, -4.0 if perfeito else -9.0, TOM_DO_LUGAR[l])
	if perfeito:
		Forja.som_falante(l, "nota:%d" % l, 0.8)
		_perfeitos_seguidos[l] += 1
		if _perfeitos_seguidos[l] >= COMBO:
			_perfeitos_seguidos[l] = 0
			Musica.reagir("combo")
		else:
			Musica.reagir("perfeito")
	else:
		_perfeitos_seguidos[l] = 0
```

`godot/scripts/main.gd`: junto das outras variáveis,

```gdscript
var _som_de_quem := ""  ## os lugares com a placa de áudio aberta ("013")
var _caiu := {}  ## os lugares cujo controle caiu (e ainda não voltou)
```

no `_ready()`, depois de `pausa.escolheu.connect(_na_pausa)`:

```gdscript
	# um controle que cai e volta pode voltar noutro nó de áudio: a placa se refaz
	Forja.pads_mudaram.connect(_ao_mudar_os_controles)
```

ao fim do `_sincronizar_jogadores()` (`main.gd:228-240`), a chamada
`_abrir_o_som()`; e as duas funções:

```gdscript
## Um controle que caiu e voltou pode ter voltado noutro nó de áudio: a
## placa se refaz (sem pio: quem está não mudou).
func _ao_mudar_os_controles() -> void:
	var voltou := false
	for l in 4:
		if not Forja.ocupado(l):
			_caiu.erase(l)
		elif not Forja.lugar(l).get("conectado", false):
			_caiu[l] = true
		elif _caiu.has(l):
			_caiu.erase(l)
			voltou = true
	if voltou:
		_abrir_o_som(true)


## A placa de áudio de cada controle abre na entrada do lugar e fica aberta
## (docs/jogo/05#a-agenda-do-alto-falante); só se refaz quando muda quem está
## (ou quando um controle volta). Quem acabou de entrar ouve o pio do seu
## cavaleiro, no próprio controle.
func _abrir_o_som(refazer := false) -> void:
	var quem := ""
	for l in 4:
		if Forja.ocupado(l):
			quem += str(l)
	if quem == _som_de_quem and not refazer:
		return
	var antes := _som_de_quem
	_som_de_quem = quem
	var papel := Forja.PAPEL_ALTO_FALANTE
	if estado == "sala" and sala is SalaJogo and (sala as SalaJogo).papel_som >= 0:
		papel = (sala as SalaJogo).papel_som
	Forja.som_preparar(papel)
	for l in 4:
		if Forja.ocupado(l) and not str(l) in antes:
			Forja.som_falante(l, "pio:%d" % jogadores[l].modelo_i, 0.8)
```

(O `pads_mudaram` também dispara na entrada do lobby, quando o lugar muda
na assinatura: refazer a placa ali cortaria o pio que acabou de sair — foi
medido. Por isso o `_caiu`: só refaz depois de **ver** o controle cair.)

`godot/scripts/salas/sala_jogo.gd`, a entrada e a saída:

```gdscript
	if papel_som >= 0:
		# o som de cada um, achado como um jogo acha; o aviso mostra e deixa trocar
		Forja.som_preparar(papel_som)
	elif sfx_no_controle and not Forja.som_pronto():
		# a placa abre na entrada do lugar (main.gd); aqui só se ainda não abriu
		Forja.som_preparar(Forja.PAPEL_ALTO_FALANTE)
```

```gdscript
func sair() -> void:
	...
	if papel_som >= 0:
		# a placa fica aberta: volta ao papel de sempre (o alto-falante)
		Forja.som_preparar(Forja.PAPEL_ALTO_FALANTE)
	super()
```

## Passos

Rode a prova indicada no fim de cada passo. Se a sessão passar de uns 40
turnos antes do passo 8, **pare depois do passo 7** (o C inteiro, provado),
faça o commit e escreva a ficha H07b com os passos 8 a 12 — é o que o
[12](../12-como-trabalhar.md#o-ciclo-de-uma-ficha) manda.

1. **Antes**: `scripts/compilar.sh testes` e `bash tests/prova_do_jogo.sh`
   verdes. Confira `grep -n "func sentir" godot/scripts/forja.gd` (F05).
2. **A síntese** (`sintese.h`, `sintese.c`): o pio e o material. **Prova:**
   as linhas de `prova_som.c` (em "Provas") e `scripts/compilar.sh testes`.
3. **As rampas** (`rampa.h`, `rampa.c`, o `CMakeLists.txt` no
   `forja_nucleo`, e o `mixer.c` do diff). **Prova:** `scripts/compilar.sh testes`.
4. **Os sons do controle** (`sons_salas.h`, `sons_salas.c` do diff).
5. **O registro e um som por vez** (`som_controle.h`, `som_controle.c`,
   `forja_som.cpp` do diff). **Prova:** `scripts/compilar.sh linux` (não com
   o Godot aberto: ele segura o `.so`) e `bash tests/prova_do_jogo.sh`.
6. **`godot/scripts/forja.gd`**: `som_pronto()` e `tocar_material()`.
7. **A placa aberta**: `main.gd` (`_abrir_o_som()`, `_ao_mudar_os_controles()`,
   as duas variáveis, a conexão no `_ready()` e a chamada no
   `_sincronizar_jogadores()`; no pódio, `main.gd:436` passa a
   `if not Forja.som_pronto(): Forja.som_preparar(...)`, e sai o
   `Forja.som_encerrar()` do `_sair_do_podio()`, `main.gd:516`),
   `sala_jogo.gd` (a entrada e a saída), `prova.gd` (sai o `sair()` que só
   encerrava, linha 92-94; na linha 109, `if not Forja.som_pronto():`),
   `bancada.gd:116` (troque o `som_encerrar()` por
   `Forja.som_preparar(F.PAPEL_ALTO_FALANTE)`). **Prova:** a do jogo, com as
   checagens do pio e da placa (em "Provas").
8. **A agenda no kit**: o `_reagir` novo do `minigame.gd` (a nota limpa no
   perfeito, a quebrada no erro, o material no acerto — pela háptica no cabo,
   pelo rumble no rádio, nunca os dois).
9. **A navegação**: em `main.gd`, `_passo(l, vertical)` (`main.gd:802`) é
   por onde toda interface anda; quando ele devolver `!= 0`, toque
   `Forja.som_falante(l, "clique", 0.5)` — só no controle de quem navegou.
10. **A música que reage** (`musica.gd`). **Prova:** a do jogo, com
    `_prova_da_musica_que_reage()`.
11. **A coleta**: `grep -rn "Som.tocar(\"ponto\"\|coleta\|moeda" godot/scripts/salas`
    e, onde uma sala toca a coleta na TV para um lugar, acrescente
    `Forja.som_falante(l, "coleta", 0.7)`. Se não houver coleta em sala
    nenhuma hoje, anote na ficha e siga (os minigames novos usam o som).
12. **O 13**: o que está marcado **novo**, e a linha `som_controle` da tabela
    do registro com `lugar`. **Prova final:** `scripts/compilar.sh testes`,
    `scripts/compilar.sh linux`, `bash tests/prova_do_jogo.sh`.

## Armadilhas

- **Não recompile com um Godot rodando** (ele segura o `.so`, COMO-CONTRIBUIR).
- **`Material` é nome do godot-cpp**: o tipo C é `MaterialHaptico` (medido).
- **Rumble e háptica por áudio não se somam no mesmo instante** (o 05,
  suspeita e): `tocar_material` escolhe um; o kit não chama `sentir` no
  acerto (só no erro).
- **O alto-falante toca um som por vez**: o anterior sai pela rampa (20 ms).
  O Canto e o robô dele continuam passando (medido); se uma sala precisar de
  dois sons juntos no alto-falante, é sinal de que a sala está errada, não o
  mixer.
- **`mixer_parar_tudo` agora é suave**: o `som_encerrar()` fecha o fluxo
  logo depois, e o que sobrou some com ele — sem estalo, porque o fluxo para.
- **A placa se refaz só quando muda quem está**: `som_preparar` roda o
  `pactl` (no Linux) e reabre tudo; chamá-lo a cada sala é o que se tira
  aqui. As salas de som (`papel_som >= 0`) ainda refazem, porque deixam
  trocar o dispositivo no aviso.
- **O controle simulado tem placa virtual** (`placa: true`); o registro diz
  `placa: false` quando o lugar não tem alto-falante ou atuador (o rádio, na
  máquina do André) — e aí o `tocar_material` vai pelo rumble.
- **O lugar desconectado**: `som_tem` dá falso, o som não sai e o registro
  mostra `placa: false`. Quando o controle volta, `_ao_mudar_os_controles`
  refaz a placa (sem pio). Não troque o `_caiu` por "refazer a cada
  `pads_mudaram`": o sinal dispara na entrada do lobby e corta o pio
  (medido).
- **O robô e a prova**: nada aqui olha `Forja.robo`. A prova ouve o
  alto-falante virtual (`Forja.som_virtual(l)`) no quadro seguinte ao ✕.
- **Os tweens da música andam no tempo do jogo**: na prova, espere em
  quadros, não no relógio de parede.
- **O treino e a pausa**: o som toca igual no treino; na pausa, nada toca
  porque o jogo está congelado.

## Não fazer

- Não tocar música nem ambiente contínuo no alto-falante do controle (o 05).
- Não mexer no relatório USB `0x02` nem no bloco de efeitos: é som, não HID.
- Não criar stems nem middleware de áudio (o 04: "sem stems, o mínimo").
- Não mudar o volume do alto-falante da sala (é das opções).

## Pronto quando

A placa de cada controle abre na entrada do lugar e fica aberta até ele
sair; cada cavaleiro tem o seu pio, só no seu controle; no minigame do kit,
todo acerto e erro tem som na TV e algo no controle do dono (a nota, o
material ou o rumble); nada corta sem rampa; a música abafa no erro, abaixa
no perfeito e brilha no combo; e o registro mostra cada som mandado a cada
controle, com a placa — com as provas do módulo e do jogo verdes.

## Provas

**Na sessão:**

```bash
scripts/compilar.sh testes
scripts/compilar.sh linux
bash tests/prova_do_jogo.sh
```

Em `nativo/testes/prova_som.c` (e `#include "rampa.h"` no começo), ao fim
de `provas_som()`:

```c
  /* ---- o pio de cada boneco (H07) ---- */
  for (int k = 0; k < 12; k++) {
    Onda p = {0};
    espera(sint_pio(&p, 523.25f * powf(2.0f, k / 12.0f), k % 2, 40u + (uint32_t)k) == 0 && p.n > 0, "o pio sintetiza");
    espera(onda_pico(&p) > 0.5f && onda_pico(&p) <= 0.81f, "o pio soa, sem estourar");
    onda_liberar(&p);
  }
  /* ---- a háptica por material (H07) ---- */
  for (int m = 0; m < MATERIAL_TOTAL; m++) {
    Onda h = {0};
    espera(sint_material(&h, (MaterialHaptico)m, 5) == 0 && h.n > 0, "o material sintetiza");
    espera(onda_pico(&h) > 0.3f && onda_pico(&h) <= 0.951f, "o material se sente, sem estourar");
    espera(material_por_nome(material_nome((MaterialHaptico)m)) == m, "o nome do material volta");
    onda_liberar(&h);
  }
  espera(material_por_nome("plasma") == MATERIAL_LAMA && material_por_nome("vidro") == -1, "plasma é lama; vidro não existe");
  /* ---- as rampas (H07) ---- */
  float passo = rampa_passo(48000, RAMPA_SAIDA_MS);
  float ganho = 1.0f;
  int amostras = 0;
  while (ganho > 0.0f && amostras < 100000) {
    ganho = rampa_andar(ganho, 0.0f, passo);
    amostras++;
  }
  espera(amostras >= 950 && amostras <= 970, "a rampa de saída leva 20 ms (960 amostras)");
  espera(rampa_andar(0.5f, 1.0f, 0.7f) == 1.0f && rampa_andar(0.5f, 0.0f, 0.7f) == 0.0f, "a rampa não passa do alvo");
```

Em `godot/testes/prova_do_jogo.gd`:

- no lobby de `_prova_do_percurso()`, o laço que faz cada um entrar passa a
  conferir o pio:

  ```gdscript
  	for s in 4:
  		await _aperta(s, Forja.CRUZ)
  		# o pio do cavaleiro sai no controle de quem entrou, e só nele
  		var nivel := float(Forja.som_virtual(s).get("falante", 0.0))
  		var outros := 0.0
  		for o in 4:
  			if o != s:
  				outros = maxf(outros, float(Forja.som_virtual(o).get("falante", 0.0)))
  		_esperar(nivel > 0.1 and outros < 0.05, "P%d entrou: o pio no controle dele (%.2f; os outros %.2f)" % [s + 1, nivel, outros])
  		await _quadros(20)
  ```

  e, depois de "os quatro entraram":
  `_esperar(Forja.som_pronto(), "a placa de áudio dos quatro abriu na entrada")`;
- em `_termina_a_sala()`, depois de "de volta ao salão pelo veredito":
  `_esperar(Forja.som_pronto(), "%s: a placa de áudio continua aberta" % id)`;
- em `_prova_do_kit()` (H04), no fim:
  `_esperar(Forja.som_tem(2, Forja.PAPEL_ALTO_FALANTE), "kit: o P3 voltou com o alto-falante")`
  (o cabo dele saiu e voltou no meio do minigame);
- `_prova_da_musica_que_reage()`, chamada com `await` em `_ready()` logo
  depois de `_prova_dos_jingles()` (H06):

  ```gdscript
  ## A música que reage (H07): o erro abafa e abre, o perfeito abaixa e volta.
  ## Os tweens andam no tempo do jogo: a espera é em quadros.
  func _prova_da_musica_que_reage() -> void:
  	Musica.reagir("erro")
  	_esperar(Musica._passa_baixa.cutoff_hz < 1000.0, "música: o erro abafa (%.0f Hz)" % Musica._passa_baixa.cutoff_hz)
  	await _quadros(40)
  	_esperar(is_equal_approx(Musica._passa_baixa.cutoff_hz, Musica.ABERTO_HZ), "música: e abre de novo")
  	Musica.reagir("perfeito")
  	_esperar(is_equal_approx(AudioServer.get_bus_volume_db(Musica._bus), -2.0), "música: o perfeito abaixa 2 dB")
  	await _quadros(12)
  	_esperar(is_equal_approx(AudioServer.get_bus_volume_db(Musica._bus), 0.0), "música: e volta")
  ```

- em `_prova_do_relatorio()`, junto das outras leituras da linha do tempo:

  ```gdscript
  	# o som em todo evento (H07): cada lugar recebeu sons no controle, com a
  	# placa (a virtual, nos simulados), o pio na entrada e a nota do perfeito
  	var sons := [0, 0, 0, 0]
  	var pios := 0
  	var notas := 0
  	for f in arquivos:
  		if not (f.begins_with("linha-do-tempo-") and f.ends_with(".jsonl")):
  			continue
  		for linha in FileAccess.get_file_as_string(pasta.path_join(f)).split("\n", false):
  			var ev = JSON.parse_string(linha)
  			if not ev is Dictionary or ev.get("tipo", "") != "som_controle":
  				continue
  			var l := int(ev.get("lugar", -1))
  			if l >= 0 and l < 4 and ev.get("placa", false):
  				sons[l] += 1
  			pios += 1 if str(ev.get("som", "")).begins_with("pio:") else 0
  			notas += 1 if str(ev.get("som", "")) == "nota:0" else 0
  	_esperar(sons.all(func(n): return n > 0), "registro: cada controle recebeu som, com a placa (%s)" % [sons])
  	_esperar(pios >= 4 and notas >= 1, "registro: o pio de cada um e a nota do perfeito (%d pios, %d notas)" % [pios, notas])
  ```

**Com o André, local:** ver abaixo.

## Para o André (local)

```bash
scripts/gauntlet.sh
bash tests/prova_de_poucos.sh
./run-local.sh
```

Com dois controles no cabo e um no rádio: no lobby, cada um ouve o pio do
seu cavaleiro no próprio controle (e só nele); a navegação clica baixinho
no controle de quem navegou; numa partida, o perfeito toca a sua nota no
controle e a música abaixa de leve; o erro abafa a música e quebra a nota;
no cabo, o acerto tem a textura do chão nas mãos; no rádio, vibra. Diga o
que não soou, o que soou alto demais e o que estalou.

## Ao terminar

- Marque a H07 como **feito** no [quadro](README.md), com o commit e o gasto
  real (ou a H07 **feito** até o passo 7 e a H07b nova no quadro).
- Commit sugerido (sem trailer):
  `feat: o som em todo evento — a placa aberta, o pio, a nota de cada um, o material, as rampas e a música que reage`
