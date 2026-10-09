# WU04 — A lista de som na ordem em que chegou

**Sprint:** W · **Tamanho:** P · **Depende de:** — (mexe em `nativo/som/som_controle.c`, como a
[WN02](WN02-o-som-que-chega-depois-do-controle.md), a [WS03](WS03-a-placa-do-controle-nao-fecha-a-toa.md) e a
[WU06](WU06-o-som-pelo-nome-nunca-vai-para-outro.md): voar no mesmo conjunto)

## Por quê

Com quatro DualSense no cabo, os nós de som têm o mesmo nome. Para saber de que aparelho é cada um, o jogo casa a
lista do SDL com a lista do sistema (o `pactl` no Linux, o WASAPI no Windows) contando «o k-ésimo com o mesmo nome»,
supondo que as duas andam na mesma ordem. O SDL 3 não entrega na ordem: entrega na ordem dos baldes de uma tabela de
espalhamento. Quando a ordem vira, o jogo dá a um jogador o aparelho do nó de outro controle e ainda escreve «pelo
aparelho», a garantia mais forte: a voz do P1 sai no controle do P3.

## Ler antes

- [ADR 006 — O som se acha como um jogo acha](../../adr/006-o-som-se-acha-como-um-jogo-acha.md)
- [WN02](WN02-o-som-que-chega-depois-do-controle.md) (que relista na volta: a ordem conta lá também)

## O estado de hoje

- `nativo/nucleo/achar_som.c:165-175`, `achar_casar`: «quantos com o mesmo nome vieram antes na lista do jogo», e o
  k-ésimo de mesmo nome na lista do sistema.
- `nativo/som/som_controle.c:141-163`, `listar`, na ordem que `SDL_GetAudioPlaybackDevices` e
  `SDL_GetAudioRecordingDevices` devolvem; `nativo/som/som_controle_windows.c:93-102` diz no comentário «as duas
  listas andam na mesma ordem».
- No SDL 3.4.14 (libsdl-org/SDL, zlib, `.cache/src/SDL3-3.4.14/src`):
  - `audio/SDL_audio.c:1492-1504`: a lista sai de `SDL_IterateHashTable` sobre `device_hash_physical`;
  - `audio/SDL_audio.c:942-947`: a chave é o id deslocado 2 bits; `:358-366`: o id é um contador que cresce a cada
    dispositivo acrescentado (também os lógicos, a cada fluxo aberto);
  - `SDL_hashtable.c:101-105`: o balde é `(id × 0x9E3779B1) & máscara`; começa pequeno e dobra acima de 217/256 de
    ocupação (`:274-286`).
- A conta: `0x9E3779B1` vale 1 módulo 16 e 17 módulo 32. Até 16 baldes, a ordem é a do contador módulo o tamanho; com
  32 baldes (a partir de 14 dispositivos físicos), saem os pares e depois os ímpares. E mesmo com poucos
  dispositivos, um contador que passou do tamanho da tabela (depois de cabos tirados e fluxos abertos) dá a volta e
  embaralha. A máquina dela hoje: 3 saídas e 2 entradas; quatro DualSense somam 8 nós: 13.

## O alvo

A lista do jogo sai na ordem em que o sistema enumerou, e o «k-ésimo de mesmo nome» casa com o k-ésimo do sistema.
Quando a contagem de um nome difere entre as duas listas, ninguém herda o aparelho de outro. Nada muda na tela.

## Passos

1. **A função pura.** Em `achar_som.c`, ordenar os ids em ordem crescente (o id cresce na ordem em que o backend
   acrescenta: `SDL_audio.c:366`). `listar` chama a função antes de montar `g_sc.nos`.
2. **O Windows.** Enumerar por fluxo (`eRender`, depois `eCapture`), como o SDL faz (`SDL_immdevice.c:468-469`), em
   vez de `eAll`.
3. **A recusa.** Em `achar_casar`, um nome repetido que aparece em número diferente nas duas listas não casa: o nó
   fica sem aparelho e cai no número ou no nome.

## Armadilhas

- **O `pactl` lista por índice do servidor**, que também cresce na ordem de criação; é o que o passo 1 alinha. Não
  supor mais que isso: a prova usa as duas listas como vêm de verdade.
- **A WN02 relista com nós chegando no meio**: o nó novo tem o maior id e o maior índice; a ordenação mantém.

## Não fazer

- Não ordenar por nome: os nomes são iguais.
- Não mexer nas três passadas de `escolher`.

## Pronto quando

Com 14 ou mais dispositivos, ou com o contador dando a volta, cada jogador recebe o nó do seu próprio controle.

## Provas

- **Nativa** (`prova_achar_som.c`): quatro nós «DualSense Wireless Controller» com USB distintos, e a lista do jogo
  na ordem que o SDL devolve com 14 dispositivos (os pares, depois os ímpares). O i-ésimo do jogo casa com o
  i-ésimo do sistema. Hoje o 1º do jogo leva o USB do 2º do sistema: reprova.
- **Nativa:** um nome com 3 no jogo e 4 no sistema não casa ninguém.

## Para o André (local)

Quatro DualSense no cabo e um fone USB ligado (para passar de 13): cada jogador aperta o pio na sala de som, e o pio
sai no controle de quem apertou. Tirar e repor dois cabos e repetir.

## Ao terminar

Marcar WU04 como **feito** no [quadro](README.md), com o commit e o gasto. Commit sugerido:
`fix(som): a lista do SDL volta à ordem do sistema antes de casar os nomes`.
