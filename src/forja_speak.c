/* forja-speak — um SFX no alto-falante de UM DualSense, achado como um jogo acha.
 *
 *   forja-speak --list
 *   forja-speak --player 2 [--hz 1300] [--ms 400]        pelo APARELHO (o 3º da mesa)
 *   forja-speak --nome "Controle 2" [--hz 1300]          pelo NOME que o jogo mostra
 *   forja-speak --player 0 --hz 60 --ms 400 --vcm        nos dois atuadores
 *   forja-speak --player 0 --canal 0                     a mordida: o fone, não o plástico
 *
 * Por que um binário, e não o motor: o AudioServer do Godot tem UM device para
 * o processo inteiro, e numa mesa de quatro DualSense "o tiro do P3 sai no
 * alto-falante do P3" é impossível dentro dele. Este é o irmão do forja-send:
 * um processo curto por SFX.
 *
 * Lê `LC_ALL=C pactl list sinks` (o pactl traduz, e um leitor cego responde
 * "não há" sobre aparelho de pé) e empurra PCM cru por `pw-cat`, sem shell.
 *
 * PROIBIDO aqui, como em todo este repo: socket IPC, uniq, MAC, 0x31.
 *
 * rc: 0 tocou · 1 o tocador falhou · 2 não achou alto-falante · 4 o alto-falante
 *     achado não tem o canal pedido · 64 uso errado. "Não achei" nunca se lê
 *     como "toquei e nada saiu".
 */
#define _XOPEN_SOURCE 700

#include "forja_alto_falante.h"
#include "forja_mesa.h"

#include <errno.h>
#include <limits.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#define MAX_NOS 32
#define MAX_MS 10000

static char *ler_pactl(void) {
  FILE *p = popen("LC_ALL=C pactl list sinks 2>/dev/null", "r");
  if (!p)
    return NULL;
  size_t tam = 0, cap = 1 << 16;
  char *buf = malloc(cap);
  if (!buf) {
    pclose(p);
    return NULL;
  }
  size_t lidos;
  while ((lidos = fread(buf + tam, 1, cap - tam - 1, p)) > 0) {
    tam += lidos;
    if (cap - tam < 4096) {
      char *maior = realloc(buf, cap * 2);
      if (!maior)
        break;
      buf = maior;
      cap *= 2;
    }
  }
  buf[tam] = '\0';
  pclose(p);
  return buf;
}

static void uso(void) {
  fputs("uso: forja-speak --list\n", stderr);
  fputs("     forja-speak (--player N | --nome TEXTO) [--hz HZ] [--ms MS] [--vcm | --canal C]\n",
        stderr);
}

static int tocar(const ForjaNoDeSom *no, int canal_a, int canal_b, double hz, int ms) {
  const char *mapa = forja_mapa_de_canais(no->canais);
  if (!mapa)
    return 4;
  long quadros = (long)FORJA_TAXA * ms / 1000;
  int16_t *pcm = calloc((size_t)quadros * (size_t)no->canais, sizeof(int16_t));
  if (!pcm)
    return 1;
  forja_tom(pcm, quadros, no->canais, canal_a, canal_b, hz);

  char alvo[300], taxa[32], canais[32], mapa_arg[64];
  snprintf(alvo, sizeof(alvo), "--target=%s", no->nome);
  snprintf(taxa, sizeof(taxa), "--rate=%d", FORJA_TAXA);
  snprintf(canais, sizeof(canais), "--channels=%d", no->canais);
  snprintf(mapa_arg, sizeof(mapa_arg), "--channel-map=%s", mapa);

  int canos[2];
  if (pipe(canos) != 0) {
    free(pcm);
    return 1;
  }
  pid_t filho = fork();
  if (filho < 0) {
    free(pcm);
    return 1;
  }
  if (filho == 0) {
    dup2(canos[0], STDIN_FILENO);
    close(canos[0]);
    close(canos[1]);
    execlp("pw-cat", "pw-cat", "--playback", "--raw", alvo, taxa, canais, "--format=s16",
           mapa_arg, "--latency=40ms", "-", (char *)NULL);
    _exit(127);
  }
  close(canos[0]);
  const char *p = (const char *)pcm;
  size_t falta = (size_t)quadros * (size_t)no->canais * sizeof(int16_t);
  int escrita_ok = 1;
  while (falta > 0) {
    ssize_t w = write(canos[1], p, falta);
    if (w < 0) {
      if (errno == EINTR)
        continue;
      escrita_ok = 0;
      break;
    }
    p += w;
    falta -= (size_t)w;
  }
  close(canos[1]);
  free(pcm);
  int estado = 0;
  while (waitpid(filho, &estado, 0) < 0 && errno == EINTR) {
  }
  return (escrita_ok && WIFEXITED(estado) && WEXITSTATUS(estado) == 0) ? 0 : 1;
}

static void listar(const ForjaNoDeSom *nos, int n, int total) {
  for (int i = 0; i < n; i++) {
    printf("alto-falante %d\t%s\t%s\t%d canais\t%s\n", i, nos[i].nome,
           nos[i].descricao[0] ? nos[i].descricao : "(sem nome)", nos[i].canais,
           nos[i].usb_da_sony ? "acha sozinho" : "pela lista");
  }
  printf("# %d saídas no servidor, %d de DualSense\n", total, n);
}

int main(int argc, char **argv) {
  int player = -1, ms = 400, vcm = 0, listar_so = 0, canal = -1;
  double hz = 1300.0;
  const char *nome = NULL;
  for (int i = 1; i < argc; i++) {
    if (!strcmp(argv[i], "--player") && i + 1 < argc)
      player = atoi(argv[++i]);
    else if (!strcmp(argv[i], "--nome") && i + 1 < argc)
      nome = argv[++i];
    else if (!strcmp(argv[i], "--hz") && i + 1 < argc)
      hz = atof(argv[++i]);
    else if (!strcmp(argv[i], "--ms") && i + 1 < argc)
      ms = atoi(argv[++i]);
    else if (!strcmp(argv[i], "--canal") && i + 1 < argc)
      canal = atoi(argv[++i]);
    else if (!strcmp(argv[i], "--vcm"))
      vcm = 1;
    else if (!strcmp(argv[i], "--list"))
      listar_so = 1;
    else {
      uso();
      return 64;
    }
  }
  if (ms < 1 || ms > MAX_MS || hz <= 0.0 || (vcm && canal >= 0)) {
    uso();
    return 64;
  }
  signal(SIGPIPE, SIG_IGN); /* o tocador que morre vira rc, não um sinal */

  char *texto = ler_pactl();
  ForjaNoDeSom nos[MAX_NOS];
  int total = 0;
  int n = forja_nos_de_som(texto ? texto : "", nos, MAX_NOS, &total);
  free(texto);

  if (listar_so) {
    listar(nos, n, total);
    return 0;
  }

  int escolhido = -1;
  if (nome) {
    escolhido = forja_no_por_nome(nos, n, nome);
    if (escolhido < 0) {
      fprintf(stderr, "nenhum alto-falante de DualSense com «%s» no nome (%d saídas)\n", nome,
              total);
      return 2;
    }
  } else if (player >= 0) {
    ForjaPad pads[8];
    int n_pads = forja_mesa_pads(pads, 8);
    if (player >= n_pads) {
      fprintf(stderr, "player index %d fora da mesa (%d DualSense)\n", player, n_pads);
      return 2;
    }
    char usb[PATH_MAX];
    if (forja_usb_do_pad(&pads[player], usb, sizeof(usb)) != 0) {
      fprintf(stderr,
              "o DualSense do player %d não está num USB: pelo aparelho não há alto-falante. "
              "aponte pelo nome, com --nome.\n",
              player);
      return 2;
    }
    escolhido = forja_no_do_pad(nos, n, usb);
    if (escolhido < 0) {
      fprintf(stderr, "nenhum alto-falante é do mesmo aparelho que o DualSense do player %d\n",
              player);
      return 2;
    }
  } else {
    uso();
    return 64;
  }

  const ForjaNoDeSom *no = &nos[escolhido];
  int canal_a, canal_b = -1;
  if (vcm) {
    if (no->canais < 4) {
      fprintf(stderr, "«%s» tem %d canais: os atuadores são o 3º e o 4º, e ele não os tem\n",
              no->descricao, no->canais);
      return 4;
    }
    canal_a = FORJA_CANAL_VCM_E;
    canal_b = FORJA_CANAL_VCM_D;
  } else {
    canal_a = canal >= 0 ? canal : forja_canal_do_alto_falante(no->canais);
  }
  if (canal_a >= no->canais || !forja_mapa_de_canais(no->canais)) {
    fprintf(stderr, "«%s» tem %d canais: não há o canal %d\n", no->descricao, no->canais,
            canal_a);
    return 4;
  }

  printf("alto-falante: %s\n", no->nome);
  printf("  o nome que o jogo mostra: %s\n", no->descricao);
  if (canal_b >= 0)
    printf("  %d canais · %.0f Hz por %d ms nos canais %d,%d (os atuadores)\n", no->canais, hz,
           ms, canal_a, canal_b);
  else
    printf("  %d canais · %.0f Hz por %d ms no canal %d\n", no->canais, hz, ms, canal_a);
  fflush(stdout);
  int rc = tocar(no, canal_a, canal_b, hz, ms);
  printf("rc=%d\n", rc);
  return rc;
}
