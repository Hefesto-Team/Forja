/* A roda das provas. `demo-testes` sai com 0 quando tudo passa. */
#include "prova.h"

int prova_falhas = 0;
int prova_contas = 0;

static const struct {
  const char *nome;
  ProvaFn fn;
} PROVAS[] = {
    {"máscara de MAC", provas_mascara},   {"utf-8", provas_utf8},
    {"sorteio", provas_sorteio},          {"taxa do sensor", provas_taxa},
    {"catálogo", provas_catalogo},        {"relatório", provas_relatorio},
    {"origem do controle", provas_origem}, {"payload do DualSense", provas_efeitos},
    {"postura do controle", provas_postura}, {"medidas das salas", provas_medidas},
    {"provas às cegas", provas_cegas},
};

int main(void) {
  for (size_t i = 0; i < sizeof(PROVAS) / sizeof(PROVAS[0]); i++) {
    int antes = prova_falhas;
    PROVAS[i].fn();
    /* a coluna conta letras, não bytes: "catálogo" tem um acento */
    int letras = 0;
    for (const unsigned char *c = (const unsigned char *)PROVAS[i].nome; *c; c++)
      letras += (*c & 0xC0) != 0x80;
    printf("%s%*s %s\n", PROVAS[i].nome, letras < 22 ? 22 - letras : 0, "", prova_falhas == antes ? "ok" : "FALHOU");
  }
  printf("%d verificações, %d falha(s)\n", prova_contas, prova_falhas);
  return prova_falhas ? 1 : 0;
}
