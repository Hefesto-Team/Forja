# WS05 — O mixer rouba pela rampa, e tem prova

**Sprint:** W · **Tamanho:** P · **Depende de:** H07

## Por quê

O mixer de cada controle tem 48 vozes. Quando todas estão ocupadas, o som novo rouba a vaga da voz que termina antes,
e o roubo zera a voz na mesma amostra: um estalo, o que a rampa de 20 ms existe para evitar em todo o resto do mixer.
Com as 48 em laço, o roubo leva a voz 0 mesmo assim, contra a regra que o próprio laço de escolha segue. Hoje é raro
(nenhum laço toca no controle, e os sons duram de 0,02 a 0,9 s), mas o mixer é a base de todo som no controle e não
tem prova nenhuma: a WS01 (a prioridade do alto-falante) e a WS03 (a saída que fecha pela rampa) mexem nele às cegas.

A causa: o roubo foi escrito como reiniciar a vaga, sem passar pela rampa, e a escolha da vítima começa da voz 0 sem
conferir se ela é laço.

## Ler antes

- `nativo/som/mixer.h` (a `Voz` e o `Mixer`) e `nativo/som/rampa.h` (`RAMPA_SAIDA_MS`).
- `nativo/testes/prova_som.c` (a prova da rampa, que é o molde).

## O estado de hoje

- `nativo/som/mixer.c:32-48`:

  ```c
  if (livre < 0) {
    /* sem voz livre: rouba a que está mais adiantada (a que termina antes) */
    int melhor = 0;
    float resto_min = 1e9f;
    for (int i = 0; i < MIX_MAX_VOZES; i++) {
      if (m->voz[i].laco)
        continue;
      …
    }
    livre = melhor;
  }
  Voz *v = &m->voz[livre];
  SDL_memset(v, 0, sizeof(*v));
  ```

  Com as 48 em laço, `melhor` fica 0 e a voz 0 perde o laço. Fora disso, a voz roubada some do valor que tinha para 0
  entre duas amostras (medido fora da árvore, com um SDL de mentira: 0,600 antes do roubo e 0,000 na amostra seguinte;
  pela rampa, a mesma passagem dá 0,5994 e 0,5988).
- `nativo/CMakeLists.txt:52-69`: o `forja_nucleo` (o que o `forja-testes` liga, `:78-91`) compila só `som/rampa.c` e
  `som/sintese.c` do som; o `mixer.c` e o `som_controle.c` ficam no `forja_sdl` (`:108-109`), sem prova.
- `nativo/testes/prova_som.c:216-225` prova só a rampa.
- A H07 já viu e deixou de fora: «o roubo de voz do mixer (sem voz livre, `MIX_MAX_VOZES` = 48) ainda corta de uma
  vez; a ficha não mandou mudar» (`docs/jogo/tarefas/H07-o-som-em-todo-evento.md:995-996`).

## O alvo

- A voz roubada não some: vai para uma vaga de saída (uma voz a mais, fora das 48, só para o fim pela rampa), e a nova
  entra no lugar dela. Com todas em laço, a nova é recusada (`mixer_tocar` devolve 0).
- O núcleo do mixer (vozes, roubo, mistura, limitador) sem SDL, no `forja_nucleo`, e a trava fica num invólucro do
  `forja_sdl`. O `forja-testes` prova o núcleo.

## Passos

1. Separar `mixer.c` em núcleo puro (sem `SDL_LockMutex`; `memset` e `memcpy` da biblioteca padrão) e a trava em volta
   (o `Mixer` do jogo continua com a mesma API).
2. A vaga de saída e a recusa no laço.
3. A prova no `forja-testes`: encher as 48, tocar a 49ª e medir as amostras depois do roubo; e as 48 em laço mais uma
   nova.

## Armadilhas

- A mistura roda no fio de áudio (`alimentar`, `nativo/som/som_controle.c:55-65`): o núcleo não pode alocar memória.
- O `mixer_tocando(id)` da voz roubada tem de dizer «não» logo depois do roubo, mesmo com ela ainda saindo pela rampa
  (quem pergunta é o jogo, e para ele aquele som acabou).

## Não fazer

- Não subir o número de vozes para fugir do roubo.
- Não mudar o limitador nem a rampa.

## Pronto quando

O `forja-testes` passa com os dois casos: depois do roubo, nenhum salto entre duas amostras passa do passo da rampa
(hoje cai de 0,6 a 0); e com as 48 em laço, nenhuma voz em laço muda (hoje a voz 0 perde o laço).

## Provas

- `cmake --build` do `forja-testes` e `ctest`.
- `bash tests/prova_do_jogo.sh` (o som do controle continua igual).

## Para o André (local)

Nada: é medida.

## Ao terminar

Pôr a linha no [quadro](README.md) como **feito**, com o gasto.
