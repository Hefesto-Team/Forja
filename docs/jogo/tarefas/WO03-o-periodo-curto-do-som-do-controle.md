# WO03 — O período curto do som do controle

**Sprint:** W · **Tamanho:** P · **Depende de:** — (mexe em `nativo/som/som_controle.c`, como a WS03, a WU04 e a
WN02: não voar junto com elas)

## Por quê

A háptica por áudio e o alto-falante do controle saem de um fluxo de som que o módulo abre no SDL. Ninguém pede o
tamanho do período, e o SDL usa o padrão de música: 1024 quadros a 48 kHz, 21,3 ms. O pedido de vibração entra no
mixer e sai entre 21 e 43 ms depois (um a dois períodos), fora o caminho do cabo. Para um jogo de ritmo em que o
golpe se sente na mão, é tempo demais, e o servidor de som aceitaria um período bem menor (nesta máquina,
`clock.min-quantum=32`).

## Ler antes

- [WS — o mapa do som e da música](../revisao/WS-mapa.md) (as três saídas)
- [05 — Háptica e controle](../05-haptica-e-controle.md) (a háptica por áudio)

## O estado de hoje (medido em 09/10/2026, `85f24c3`)

- As dicas do SDL que o módulo põe, `nativo/nucleo/forja.c:168-171`: sinais, relatório do rádio, eventos em segundo
  plano e luzinhas. Nenhuma de som.
- O subsistema de som abre em `nativo/som/som_controle.c:43-51` (`abrir_audio`, `SDL_InitSubSystem(SDL_INIT_AUDIO)`),
  e cada saída em `:112`:
  ```c
  s->fluxo = SDL_OpenAudioDeviceStream(g_ids[no], &spec, alimentar, s);
  ```
- No SDL 3.4.14 (libsdl-org/SDL, licença zlib), `src/audio/SDL_audio.c:151-169`, o período sem a dica:
  ```c
  const char *hint = SDL_GetHint(SDL_HINT_AUDIO_DEVICE_SAMPLE_FRAMES);
  ...
  } else if (freq <= 48000) {
      return 1024;
  ```
  lido na abertura de cada dispositivo (`:663` e `:1843`); e `src/audio/pipewire/SDL_pipewire.c:1192` pede ao
  servidor `node.latency = quadros/taxa`.
- O número saiu da fonte e da configuração viva (`pw-metadata`); não foi medido com aparelho.

## O alvo

O fluxo de cada controle abre com um período curto, de 256 quadros (5,3 ms) ou, se a conferência ouvir falha, de
480 (10 ms). A mudança é uma dica, posta antes da primeira abertura. Nada muda na tela nem na API.

## Arquivos que mudam

- `nativo/som/som_controle.c` (a dica no `abrir_audio`, antes do `SDL_InitSubSystem`, e a linha do registro na
  abertura de cada saída)
- `godot/testes/prova_do_jogo.gd` (o passo da prova) e `tests/prova_do_jogo.sh` (a rodada com o driver de som falso)
- `docs/jogo/05-haptica-e-controle.md` (uma linha sobre o período)

## Passos

1. No `abrir_audio`, `SDL_SetHint(SDL_HINT_AUDIO_DEVICE_SAMPLE_FRAMES, "256")`, com o comentário do porquê.
2. Na abertura de cada saída (`:112`), ler `SDL_GetAudioDeviceFormat(SDL_GetAudioStreamDevice(s->fluxo), &spec,
   &quadros)` e escrever no registro «som: <saída> · período de N quadros». É a medida que a bancada e a prova leem.
3. A prova, sem aparelho: a prova do jogo ganha um passo que roda com `SDL_AUDIO_DRIVER=dummy` no ambiente do módulo
   e aponta o alto-falante do lugar 0 para a saída do driver falso pelo caminho que a pessoa já usa
   (`Forja.som_trocar`, `godot/scripts/forja.gd:879`). O registro tem de dizer no máximo 480 quadros; hoje diz 1024.
4. Na bancada com ela, ouvir e sentir: sem estalo no alto-falante e na háptica com quatro controles e a máquina
   carregada. Com estalo, subir para 480 e registrar o porquê no comentário.

## Armadilhas

- **A dica vale para o processo do módulo** e também encurta o microfone (`som_controle.c:212`). Isso é inofensivo,
  mas a Voz tem de seguir ouvindo (a prova do jogo joga a Voz).
- **O servidor de som pode subir o quantum do grafo inteiro** para atender o pedido mais curto: a TV passa a acordar
  mais vezes. É custo de CPU pequeno; anotar na conferência.
- **No Windows** o período vem do próprio sistema de som; o número pode não mudar. Não reprovar o Windows por isso.
- **Estalo** (falta de amostra no `alimentar`) é o sinal de período curto demais; a régua é a escuta dela na
  bancada.

## Não fazer

- Não mexer no mixer, na rampa nem no `alimentar`.
- Não pôr a dica no `forja.c` com as outras: o lugar é junto da abertura do som, para ninguém tirá-la sem ver.

## Pronto quando

O passo novo da prova do jogo lê no registro no máximo 480 quadros por período na saída aberta pelo módulo (hoje, 1024), e ela, na bancada, não ouve
estalo com quatro controles.

## Provas

- `scripts/compilar.sh linux`.
- `bash tests/prova_do_jogo.sh` com o passo novo, pelo semáforo da máquina e pela caixa da WE01.

## Para o André (local)

Com o DualSense no cabo, numa sala de impacto: o golpe na mão e o som do controle chegam juntos com a pancada da TV.
Se ouvir estalo, anotar a máquina e o servidor de som dela.

## Ao terminar

Pôr a linha da WO03 no [quadro](README.md) como **feito**, com o commit e o número de quadros que ficou.
