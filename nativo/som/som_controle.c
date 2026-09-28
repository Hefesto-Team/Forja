/* O som de cada controle. Ver som_controle.h. */
#include "som_controle.h"

#include "../app.h"
#include "../nucleo/simulador.h"
#include "../ui/tema.h"

#include <math.h>
#include <stdio.h>

static SDL_AudioDeviceID g_ids[SOM_MAX_NOS];

/* ---------- as saídas ---------- */

static void SDLCALL alimentar(void *u, SDL_AudioStream *fluxo, int adicional, int total) {
  (void)total;
  SaidaCtl *s = u;
  int por_quadro = (int)sizeof(float) * s->canais;
  int quadros = adicional / por_quadro;
  while (quadros > 0) {
    int bloco = quadros > s->tmp_quadros ? s->tmp_quadros : quadros;
    mixer_misturar(&s->mixer, s->tmp, bloco);
    SDL_PutAudioStreamData(fluxo, s->tmp, bloco * por_quadro);
    quadros -= bloco;
  }
}

static void fechar_saida(SaidaCtl *s) {
  if (!s->usada)
    return;
  if (s->fluxo)
    SDL_DestroyAudioStream(s->fluxo);
  mixer_encerrar(&s->mixer);
  SDL_free(s->tmp);
  SDL_memset(s, 0, sizeof(*s));
}

static int nova_saida(SomControles *sc) {
  for (int i = 0; i < SOMC_MAX_SAIDAS; i++)
    if (!sc->saidas[i].usada)
      return i;
  return -1;
}

static int preparar_saida(SaidaCtl *s, int canais) {
  s->usada = true;
  s->canais = canais > MIX_MAX_CANAIS ? MIX_MAX_CANAIS : canais;
  mixer_iniciar(&s->mixer, s->canais);
  s->tmp_quadros = 2048;
  s->tmp = SDL_malloc(sizeof(float) * (size_t)s->tmp_quadros * (size_t)s->canais);
  return s->tmp ? 0 : -1;
}

/* A saída de um nó da lista: reaproveita se outro papel já a abriu. */
static int abrir_no(SomControles *sc, int no) {
  if (no < 0)
    return -1;
  for (int i = 0; i < SOMC_MAX_SAIDAS; i++)
    if (sc->saidas[i].usada && !sc->saidas[i].virtual && sc->saidas[i].no == no)
      return i;
  int i = nova_saida(sc);
  if (i < 0)
    return -1;
  SaidaCtl *s = &sc->saidas[i];
  int canais = sc->nos[no].canais > 0 ? sc->nos[no].canais : 2;
  if (preparar_saida(s, canais) < 0) {
    fechar_saida(s);
    return -1;
  }
  s->no = no;
  SDL_AudioSpec spec = {SDL_AUDIO_F32, s->canais, MIX_TAXA};
  s->fluxo = SDL_OpenAudioDeviceStream(g_ids[no], &spec, alimentar, s);
  if (!s->fluxo) {
    fechar_saida(s);
    return -1;
  }
  SDL_ResumeAudioStreamDevice(s->fluxo);
  return i;
}

static int abrir_virtual(SomControles *sc, int slot) {
  for (int i = 0; i < SOMC_MAX_SAIDAS; i++)
    if (sc->saidas[i].usada && sc->saidas[i].virtual && sc->saidas[i].dono == slot)
      return i;
  int i = nova_saida(sc);
  if (i < 0)
    return -1;
  SaidaCtl *s = &sc->saidas[i];
  if (preparar_saida(s, 4) < 0) {
    fechar_saida(s);
    return -1;
  }
  s->virtual = true;
  s->no = -1;
  s->dono = slot;
  return i;
}

/* ---------- a lista e a escolha ---------- */

static void listar(SomControles *sc) {
  sc->n = 0;
  for (int gravacao = 0; gravacao < 2; gravacao++) {
    int total = 0;
    SDL_AudioDeviceID *ids = gravacao ? SDL_GetAudioRecordingDevices(&total) : SDL_GetAudioPlaybackDevices(&total);
    for (int k = 0; ids && k < total && sc->n < SOM_MAX_NOS; k++) {
      const char *nome = SDL_GetAudioDeviceName(ids[k]);
      if (!nome)
        continue;
      NoSom *no = &sc->nos[sc->n];
      SDL_memset(no, 0, sizeof(*no));
      SDL_strlcpy(no->nome, nome, sizeof(no->nome));
      SDL_AudioSpec spec;
      int quadros = 0;
      no->canais = SDL_GetAudioDeviceFormat(ids[k], &spec, &quadros) ? spec.channels : 2;
      no->gravacao = gravacao;
      no->tipo = achar_tipo(nome, gravacao);
      no->controle_n = achar_numero(nome);
      no->no_sistema = -1;
      g_ids[sc->n] = ids[k];
      sc->n++;
    }
    SDL_free(ids);
  }
  somc_plataforma_nos(sc, sc->plataforma, sizeof(sc->plataforma));
  sc->listou = true;
}

static bool e_candidato(const NoSom *no, PapelSom papel) {
  if (!achar_serve(no->tipo, papel))
    return false;
  if (papel == PAPEL_HAPTICA && no->tipo == NO_DUALSENSE_SAIDA && no->canais < 4)
    return false;
  return true;
}

static void ligar_saidas(App *a, int s) {
  SomControles *sc = &a->somc;
  SomJogador *j = &sc->j[s];
  for (int p = 0; p < PAPEL_TOTAL; p++) {
    j->canal_a[p] = j->canal_b[p] = -1;
    j->saida[p] = -1;
  }
  Pad *pad = pads_do_slot(a, s);
  if (pad && pad->simulado) {
    /* o controle de mentira: uma placa virtual de quatro canais, como a do cabo */
    int v = abrir_virtual(sc, s);
    j->saida[PAPEL_ALTO_FALANTE] = j->saida[PAPEL_HAPTICA] = v;
    j->canal_a[PAPEL_ALTO_FALANTE] = 1;
    j->canal_a[PAPEL_HAPTICA] = 2;
    j->canal_b[PAPEL_HAPTICA] = 3;
    j->mic_virtual = true;
    return;
  }
  for (int p = 0; p < PAPEL_MICROFONE; p++) {
    if (j->no[p] < 0)
      continue;
    achar_canais(&sc->nos[j->no[p]], (PapelSom)p, &j->canal_a[p], &j->canal_b[p]);
    j->saida[p] = abrir_no(sc, j->no[p]);
  }
  if (j->mic) {
    SDL_DestroyAudioStream(j->mic);
    j->mic = NULL;
  }
  j->mic_nivel = j->mic_pico = 0;
  if (j->no[PAPEL_MICROFONE] >= 0) {
    SDL_AudioSpec spec = {SDL_AUDIO_F32, 1, MIX_TAXA};
    j->mic = SDL_OpenAudioDeviceStream(g_ids[j->no[PAPEL_MICROFONE]], &spec, NULL, NULL);
    if (j->mic)
      SDL_ResumeAudioStreamDevice(j->mic);
  }
}

static void escolher(App *a) {
  SomControles *sc = &a->somc;
  char usb[MAX_JOGADORES][512], cont[MAX_JOGADORES][48];
  bool tem[MAX_JOGADORES];
  for (int s = 0; s < MAX_JOGADORES; s++) {
    for (int p = 0; p < PAPEL_TOTAL; p++) {
      sc->j[s].no[p] = -1;
      sc->j[s].como[p] = ACHOU_NADA;
    }
    usb[s][0] = cont[s][0] = 0;
    Pad *pad = pads_do_slot(a, s);
    tem[s] = pad != NULL && a->pads.slot[s].ocupado;
    if (tem[s] && !pad->simulado)
      somc_plataforma_pad(a, s, usb[s], sizeof(usb[s]), cont[s], sizeof(cont[s]));
  }
  for (int p = 0; p < PAPEL_TOTAL; p++) {
    bool usado[SOM_MAX_NOS] = {false};
    /* o nó que é, pelo aparelho, de um controle que não está na mesa também
     * não vai para ninguém pelo nome */
    for (int i = 0; i < sc->n; i++) {
      if (!sc->nos[i].usb[0])
        continue;
      for (int k = 0; k < MAX_PADS; k++) {
        Pad *o = &a->pads.pad[k];
        if (o->usado && o->slot < 0 && o->usb_pai[0] && !SDL_strcmp(o->usb_pai, sc->nos[i].usb))
          usado[i] = true;
      }
    }
    /* três passadas: pelo aparelho para todos, depois pelo número, depois
     * pelo nome — ninguém leva pelo nome o que é de outro pelo aparelho */
    for (int passada = 0; passada < 3; passada++)
      for (int s = 0; s < MAX_JOGADORES; s++) {
        if (!tem[s] || sc->j[s].no[p] >= 0 || pads_do_slot(a, s)->simulado)
          continue;
        ComoAchou como;
        int i = achar_para(sc->nos, sc->n, (PapelSom)p, passada == 0 ? usb[s] : NULL, passada == 0 ? cont[s] : NULL,
                           passada == 1 ? s + 1 : 0, usado, &como);
        ComoAchou quer = passada == 0 ? ACHOU_APARELHO : passada == 1 ? ACHOU_NUMERO : ACHOU_NOME;
        if (i >= 0 && como == quer) {
          sc->j[s].no[p] = i;
          sc->j[s].como[p] = como;
          usado[i] = true;
        }
      }
  }
  for (int s = 0; s < MAX_JOGADORES; s++)
    if (tem[s]) {
      Pad *pad = pads_do_slot(a, s);
      if (pad->simulado)
        for (int p = 0; p < PAPEL_TOTAL; p++)
          sc->j[s].como[p] = ACHOU_APARELHO;
      ligar_saidas(a, s);
    }
}

/* ---------- a vida ---------- */

void somc_iniciar(App *a) {
  SDL_memset(&a->somc, 0, sizeof(a->somc));
  for (int s = 0; s < MAX_JOGADORES; s++)
    for (int p = 0; p < PAPEL_TOTAL; p++)
      a->somc.j[s].no[p] = a->somc.j[s].saida[p] = -1;
}

void somc_encerrar(App *a) {
  SomControles *sc = &a->somc;
  for (int s = 0; s < MAX_JOGADORES; s++) {
    if (sc->j[s].mic) {
      SDL_DestroyAudioStream(sc->j[s].mic);
      sc->j[s].mic = NULL;
    }
    somc_escuta_parar(a, s);
  }
  for (int i = 0; i < SOMC_MAX_SAIDAS; i++)
    fechar_saida(&sc->saidas[i]);
}

void somc_preparar(App *a) {
  somc_encerrar(a);
  somc_iniciar(a);
  listar(&a->somc);
  escolher(a);
  somc_relatorio(a);
  for (int s = 0; s < MAX_JOGADORES; s++) {
    if (!pads_do_slot(a, s) || !a->pads.slot[s].ocupado)
      continue;
    SomJogador *j = &a->somc.j[s];
    reg_linha(&a->reg, "%s · som: alto-falante %s (%s) · háptica %s · microfone %s", pads_rotulo_slot(s),
              somc_nome(a, s, PAPEL_ALTO_FALANTE), achar_como_rotulo(j->como[PAPEL_ALTO_FALANTE]),
              somc_nome(a, s, PAPEL_HAPTICA), somc_nome(a, s, PAPEL_MICROFONE));
  }
}

void somc_trocar(App *a, int slot, PapelSom papel, int direcao) {
  SomControles *sc = &a->somc;
  if (slot < 0 || slot >= MAX_JOGADORES)
    return;
  SomJogador *j = &sc->j[slot];
  Pad *pad = pads_do_slot(a, slot);
  if (!pad || pad->simulado)
    return;
  /* os candidatos, e o "nenhum" no fim da roda */
  int atual = j->no[papel];
  for (int passo = 0; passo < sc->n + 1; passo++) {
    atual += direcao;
    if (atual >= sc->n)
      atual = -1;
    if (atual < -1)
      atual = sc->n - 1;
    if (atual < 0 || e_candidato(&sc->nos[atual], papel))
      break;
  }
  j->no[papel] = atual;
  j->como[papel] = atual >= 0 ? ACHOU_PESSOA : ACHOU_NADA;
  if (papel == PAPEL_ALTO_FALANTE && atual >= 0 && sc->nos[atual].tipo == NO_DUALSENSE_SAIDA &&
      sc->nos[atual].canais >= 4) {
    /* a placa do controle traz os atuadores junto */
    j->no[PAPEL_HAPTICA] = atual;
    j->como[PAPEL_HAPTICA] = ACHOU_PESSOA;
  }
  /* as saídas que ninguém mais usa fecham quando a sala sai; aqui só religa */
  ligar_saidas(a, slot);
  somc_relatorio(a);
  reg_linha(&a->reg, "%s apontou o %s: %s", pads_rotulo_slot(slot),
            papel == PAPEL_ALTO_FALANTE ? "alto-falante" : papel == PAPEL_HAPTICA ? "atuador" : "microfone",
            somc_nome(a, slot, papel));
}

bool somc_tem(App *a, int slot, PapelSom papel) {
  if (slot < 0 || slot >= MAX_JOGADORES)
    return false;
  SomJogador *j = &a->somc.j[slot];
  if (papel == PAPEL_MICROFONE)
    return j->mic || j->mic_virtual;
  return j->saida[papel] >= 0 && j->canal_a[papel] >= 0;
}

bool somc_estereo(App *a, int slot, PapelSom papel) {
  if (!somc_tem(a, slot, papel) || papel == PAPEL_MICROFONE)
    return false;
  SomJogador *j = &a->somc.j[slot];
  return j->canal_b[papel] >= 0 && j->canal_b[papel] != j->canal_a[papel];
}

const char *somc_nome(App *a, int slot, PapelSom papel) {
  if (slot < 0 || slot >= MAX_JOGADORES)
    return "—";
  SomJogador *j = &a->somc.j[slot];
  Pad *pad = pads_do_slot(a, slot);
  if (pad && pad->simulado)
    return "placa virtual do controle simulado";
  if (j->no[papel] < 0)
    return "não achado";
  return a->somc.nos[j->no[papel]].nome;
}

ComoAchou somc_como(App *a, int slot, PapelSom papel) {
  return slot >= 0 && slot < MAX_JOGADORES ? a->somc.j[slot].como[papel] : ACHOU_NADA;
}

/* ---------- tocar ---------- */

int somc_falante(App *a, int slot, const Som *s, float ganho) {
  if (!somc_tem(a, slot, PAPEL_ALTO_FALANTE) || !s)
    return -1;
  SomJogador *j = &a->somc.j[slot];
  SaidaCtl *sd = &a->somc.saidas[j->saida[PAPEL_ALTO_FALANTE]];
  float g[MIX_MAX_CANAIS] = {0};
  g[j->canal_a[PAPEL_ALTO_FALANTE]] = ganho;
  if (j->canal_b[PAPEL_ALTO_FALANTE] >= 0)
    g[j->canal_b[PAPEL_ALTO_FALANTE]] = ganho;
  /* com o fone no jack, o som do controle vai para as duas orelhas */
  if (j->fone && !sd->virtual && j->no[PAPEL_ALTO_FALANTE] >= 0 &&
      a->somc.nos[j->no[PAPEL_ALTO_FALANTE]].tipo == NO_DUALSENSE_SAIDA)
    g[0] = g[1] = ganho;
  return mixer_tocar(&sd->mixer, s, g, false);
}

/* O jack do fone: plugou, o som do controle muda para o fone (as duas
 * orelhas, e a rota do estéreo no fone); tirou, volta ao alto-falante. Só
 * quando o alto-falante é a placa do próprio controle, que é onde a rota do
 * bloco de efeitos manda. */
static void acompanhar_fone(App *a, int slot) {
  SomJogador *j = &a->somc.j[slot];
  Pad *p = pads_do_slot(a, slot);
  bool fone = p && (p->status53 & 1);
  if (fone == j->fone)
    return;
  j->fone = fone;
  bool placa = somc_tem(a, slot, PAPEL_ALTO_FALANTE) && j->no[PAPEL_ALTO_FALANTE] >= 0 &&
               a->somc.nos[j->no[PAPEL_ALTO_FALANTE]].tipo == NO_DUALSENSE_SAIDA;
  if (!placa)
    return;
  pad_alto_falante(a, p, FORJA_VOL_FALANTE_PADRAO, fone ? FORJA_ROTA_FONE : FORJA_ROTA_FALANTE, FORJA_PREAMP_PADRAO);
  reg_linha(&a->reg, "%s: o fone %s — o som do controle vai para %s", pads_rotulo_slot(slot), fone ? "entrou no jack" : "saiu",
            fone ? "o fone" : "o alto-falante");
  Evento ev;
  ev_iniciar(&ev, &a->lt, "fone", slot + 1);
  ev_bool(&ev, "plugado", fone);
  ev_fim(&ev, &a->lt);
}

int somc_haptica(App *a, int slot, const Som *esq, const Som *dir, float ganho) {
  if (!somc_tem(a, slot, PAPEL_HAPTICA))
    return -1;
  SomJogador *j = &a->somc.j[slot];
  SaidaCtl *sd = &a->somc.saidas[j->saida[PAPEL_HAPTICA]];
  int voz = -1;
  float k = limitar(a->cfg.intensidade, 0, 1) * ganho;
  if (esq) {
    float g[MIX_MAX_CANAIS] = {0};
    g[j->canal_a[PAPEL_HAPTICA]] = k;
    voz = mixer_tocar(&sd->mixer, esq, g, false);
  }
  if (dir && j->canal_b[PAPEL_HAPTICA] >= 0) {
    float g[MIX_MAX_CANAIS] = {0};
    g[j->canal_b[PAPEL_HAPTICA]] = k;
    int v2 = mixer_tocar(&sd->mixer, dir, g, false);
    if (voz < 0)
      voz = v2;
  }
  return voz;
}

void somc_parar_tudo(App *a, int slot) {
  SomJogador *j = &a->somc.j[slot];
  for (int p = 0; p < PAPEL_MICROFONE; p++)
    if (j->saida[p] >= 0)
      mixer_parar_tudo(&a->somc.saidas[j->saida[p]].mixer);
}

/* ---------- a cada quadro ---------- */

static void medir_virtual(App *a, SaidaCtl *s, float dt) {
  int quadros = (int)(dt * MIX_TAXA);
  if (quadros > s->tmp_quadros)
    quadros = s->tmp_quadros;
  if (quadros < 1)
    quadros = 1;
  mixer_misturar(&s->mixer, s->tmp, quadros);
  float rms[MIX_MAX_CANAIS] = {0};
  for (int i = 0; i < quadros; i++)
    for (int c = 0; c < s->canais; c++) {
      float v = s->tmp[i * s->canais + c];
      rms[c] += v * v;
    }
  /* os defeitos de som entre o jogo e o "plástico" de mentira */
  unsigned def = simulador_defeitos_agora();
  if (def & DEFEITO_HAPTICA_TROCADA) {
    float t = rms[2];
    rms[2] = rms[3];
    rms[3] = t;
  }
  if (def & DEFEITO_HAPTICA_MUDA)
    rms[2] = rms[3] = 0;
  if (def & DEFEITO_SEM_ALTO_FALANTE)
    rms[1] = 0;
  SaidaCtl *alvo = s;
  if ((def & DEFEITO_SOM_VIZINHO) && simulador_ativo()) {
    /* o som deste controle sai no controle seguinte da mesa */
    for (int d = 1; d < MAX_JOGADORES; d++) {
      int vizinho = (s->dono + d) % MAX_JOGADORES;
      if (!pads_do_slot(a, vizinho))
        continue;
      for (int i = 0; i < SOMC_MAX_SAIDAS; i++)
        if (a->somc.saidas[i].usada && a->somc.saidas[i].virtual && a->somc.saidas[i].dono == vizinho)
          alvo = &a->somc.saidas[i];
      break;
    }
  }
  for (int c = 0; c < s->canais; c++) {
    float nivel = sqrtf(rms[c] / (float)quadros) * 1.6f;
    if (nivel > 1)
      nivel = 1;
    if (alvo != s)
      alvo->nivel[c] = fmaxf(alvo->nivel[c], nivel);
    else
      s->nivel[c] = nivel;
  }
  if (alvo != s)
    for (int c = 0; c < s->canais; c++)
      s->nivel[c] = aproximar(s->nivel[c], 0, 20, dt);
}

void somc_atualizar(App *a, float dt) {
  SomControles *sc = &a->somc;
  for (int s = 0; s < MAX_JOGADORES; s++)
    acompanhar_fone(a, s);
  for (int i = 0; i < SOMC_MAX_SAIDAS; i++)
    if (sc->saidas[i].usada && sc->saidas[i].virtual)
      medir_virtual(a, &sc->saidas[i], dt);
  float buf[2048];
  for (int s = 0; s < MAX_JOGADORES; s++) {
    SomJogador *j = &sc->j[s];
    float nivel = 0, pico = 0;
    if (j->mic_virtual) {
      Pad *p = pads_do_slot(a, s);
      nivel = p ? simulador_fala(p->id) : 0;
      if (simulador_defeitos_agora() & DEFEITO_MIC_SURDO)
        nivel = 0;
      pico = nivel;
      j->mic_quadros++;
    } else if (j->mic) {
      int n = SDL_GetAudioStreamData(j->mic, buf, (int)sizeof(buf));
      int amostras = n > 0 ? n / (int)sizeof(float) : 0;
      if (amostras <= 0) {
        j->mic_nivel = aproximar(j->mic_nivel, 0, 4, dt);
        j->mic_pico = aproximar(j->mic_pico, 0, 1.5f, dt);
        continue;
      }
      j->mic_quadros++;
      if (j->escuta) {
        int cabe = j->escuta_cap - j->escuta_n;
        int n_esc = amostras < cabe ? amostras : cabe;
        if (n_esc > 0) {
          SDL_memcpy(j->escuta + j->escuta_n, buf, (size_t)n_esc * sizeof(float));
          j->escuta_n += n_esc;
        }
      }
      double soma = 0;
      for (int k = 0; k < amostras; k++) {
        float v = fabsf(buf[k]);
        soma += (double)v * v;
        if (v > pico)
          pico = v;
      }
      nivel = (float)sqrt(soma / amostras);
      /* o nível para a tela: -54 dB..0 dB em 0..1, que é como o ouvido lê */
      nivel = nivel > 0.002f ? limitar((20 * log10f(nivel) + 54) / 54, 0, 1) : 0;
      pico = pico > 0.002f ? limitar((20 * log10f(pico) + 54) / 54, 0, 1) : 0;
    }
    j->mic_nivel = nivel > j->mic_nivel ? nivel : aproximar(j->mic_nivel, nivel, 6, dt);
    j->mic_pico = pico > j->mic_pico ? pico : aproximar(j->mic_pico, 0, 1.2f, dt);
  }
}

float somc_mic_nivel(App *a, int slot) { return slot >= 0 && slot < MAX_JOGADORES ? a->somc.j[slot].mic_nivel : 0; }
float somc_mic_pico(App *a, int slot) { return slot >= 0 && slot < MAX_JOGADORES ? a->somc.j[slot].mic_pico : 0; }
long somc_mic_quadros(App *a, int slot) { return slot >= 0 && slot < MAX_JOGADORES ? a->somc.j[slot].mic_quadros : 0; }

static SaidaCtl *virtual_de(App *a, int slot) {
  SomJogador *j = &a->somc.j[slot];
  int i = j->saida[PAPEL_ALTO_FALANTE];
  return i >= 0 && a->somc.saidas[i].virtual ? &a->somc.saidas[i] : NULL;
}

float somc_virtual_falante(App *a, int slot) {
  SaidaCtl *s = slot >= 0 && slot < MAX_JOGADORES ? virtual_de(a, slot) : NULL;
  return s ? s->nivel[1] : 0;
}

float somc_virtual_atuador(App *a, int slot, int lado) {
  SaidaCtl *s = slot >= 0 && slot < MAX_JOGADORES ? virtual_de(a, slot) : NULL;
  return s ? s->nivel[lado ? 3 : 2] : 0;
}

void somc_relatorio(App *a) {
  for (int s = 0; s < MAX_JOGADORES; s++) {
    RelControle *c = &a->rel.controles[s];
    if (!c->presente)
      continue;
    SomJogador *j = &a->somc.j[s];
    RelSom *alvos[PAPEL_TOTAL] = {&c->alto_falante, &c->haptica, &c->microfone};
    for (int p = 0; p < PAPEL_TOTAL; p++) {
      RelSom *r = alvos[p];
      Pad *pad = pads_do_slot(a, s);
      if (pad && pad->simulado) {
        rel_copiar(r->nome, sizeof(r->nome), "placa virtual do controle simulado");
        rel_copiar(r->como, sizeof(r->como), "simulado (quatro canais, como no cabo)");
        r->canais = 4;
        continue;
      }
      if (j->no[p] < 0) {
        r->nome[0] = 0;
        rel_copiar(r->como, sizeof(r->como), a->somc.listou ? "nem pelo aparelho, nem pelo nome" : "");
        r->canais = 0;
        continue;
      }
      const NoSom *no = &a->somc.nos[j->no[p]];
      rel_copiar(r->nome, sizeof(r->nome), no->nome);
      char como[96];
      SDL_snprintf(como, sizeof(como), "%s%s%s", achar_como_rotulo(j->como[p]),
                   j->como[p] == ACHOU_APARELHO && a->somc.plataforma[0] ? " · " : "",
                   j->como[p] == ACHOU_APARELHO ? a->somc.plataforma : "");
      rel_copiar(r->como, sizeof(r->como), como);
      r->canais = no->canais;
    }
  }
  app_relatorio_mudou(a);
}

/* ---------- a escuta do experimental/ ---------- */

bool somc_escutar(App *a, int slot, float segundos) {
  if (slot < 0 || slot >= MAX_JOGADORES)
    return false;
  SomJogador *j = &a->somc.j[slot];
  if (!j->mic)
    return false;
  somc_escuta_parar(a, slot);
  j->escuta_cap = (int)(segundos * MIX_TAXA);
  j->escuta = SDL_calloc((size_t)j->escuta_cap, sizeof(float));
  j->escuta_n = 0;
  if (!j->escuta)
    return false;
  SDL_ClearAudioStream(j->mic); /* a primeira amostra gravada é de depois de agora */
  return true;
}

const float *somc_escuta(App *a, int slot, int *n) {
  if (slot < 0 || slot >= MAX_JOGADORES || !a->somc.j[slot].escuta) {
    *n = 0;
    return NULL;
  }
  *n = a->somc.j[slot].escuta_n;
  return a->somc.j[slot].escuta;
}

void somc_escuta_parar(App *a, int slot) {
  if (slot < 0 || slot >= MAX_JOGADORES)
    return;
  SomJogador *j = &a->somc.j[slot];
  SDL_free(j->escuta);
  j->escuta = NULL;
  j->escuta_cap = j->escuta_n = 0;
}
