# WU06 — O som pelo nome nunca vai para o controle de outro

**Sprint:** W · **Tamanho:** M · **Depende de:** [WU04](WU04-a-lista-de-som-na-ordem-em-que-chegou.md) (a ordem da
lista) e, para a prova pelo Wine, [WU02](WU02-o-windows-provado-num-windows.md); mexe em `som_controle.c` como a
[WN02](WN02-o-som-que-chega-depois-do-controle.md) e a [WS03](WS03-a-placa-do-controle-nao-fecha-a-toa.md)

## Por quê

A terceira passada da escolha do som, «pelo nome», entrega a um lugar o primeiro nó de DualSense livre. Ela só é
segura quando o jogo sabe de quem é cada nó. Três casos em que não sabe, e o som de um jogador sai no controle de
outro, sem aviso:

1. **Linux sem `pactl`.** O aparelho de cada nó só é lido pelo `pactl`. Sem ele (ou sem servidor do PulseAudio),
   tudo cai «pelo nome»; com quatro DualSense de mesmo nome, o P1 leva o primeiro da lista, que pode ser o do P3.
2. **Windows: a reserva não existe.** O nó de um controle conectado e fora da mesa fica reservado pelo `usb_pai`,
   que no Windows é sempre vazio; o ContainerId só é lido para quem está sentado. Um DualSense carregando no cabo,
   fora da mesa, cede o seu alto-falante a quem está sentado.
3. **O controle no rádio** nunca tem placa de som no PC, mas passa pela mesma passada e pode levar o nó de um
   controle no cabo.

## Ler antes

- [ADR 006](../../adr/006-o-som-se-acha-como-um-jogo-acha.md) e [O som chega ao controle](../../COMO-O-SOM-CHEGA-AO-CONTROLE.md)
- O plano B da pesquisa para o lugar sem placa (`docs/jogo/pesquisa/dualsense.md:431`; na N, a raia na TV; na P, o
  lugar que joga sozinho)

## O estado de hoje

- `nativo/som/som_controle_linux.c:49-59`:
  ```c
  char *saidas = ler_comando("LC_ALL=C pactl list sinks 2>/dev/null");
  ...
  if (n == 0) {
    snprintf(rotulo, tam, "sem pactl: só pelo nome");
    return;
  ```
  O `pactl` vem de um pacote à parte (`pulseaudio-utils` no Debian; o `pipewire-pulse` só o sugere). Esta máquina tem
  `pw-dump`, que dá as mesmas propriedades sem ele.
- `nativo/som/som_controle.c:236-244`, a reserva, só pelo `usb_pai`:
  ```c
  if (o->usado && o->slot < 0 && o->usb_pai[0] && !SDL_strcmp(o->usb_pai, g_sc.nos[i].usb))
    usado[i] = true;
  ```
  e `:228-229`: `somc_plataforma_pad` (o ContainerId no Windows) só para quem está sentado.
  `nativo/nucleo/origem_linux.c:155-165`: fora do Linux o `usb_pai` fica vazio. O `Pad` não guarda container
  (`nativo/nucleo/pads.h:47`).
- `nativo/nucleo/achar_som.c:212-220`, a passada pelo nome, não olha a conexão do controle; `som_controle.c:246-258`
  a roda para todo lugar ocupado e não simulado.
- O relatório só marca «como: nome».

## O alvo

Um lugar só recebe um nó pelo nome quando não pode ser de outro: há um só DualSense conectado com aquele nome, ou o
aparelho dos outros já foi casado. O Linux lê o aparelho do nó sem depender do `pactl`. O Windows reserva pelo
ContainerId. O controle no rádio nunca recebe nó. Quem fica sem nó cai no plano B que as fichas já preveem. Nada
muda na tela.

## Passos

1. **A regra numa função pura** do núcleo (`achar_som.c`): a reserva compara `usb` **ou** `container` de cada
   controle fora da mesa com o de cada nó; a passada pelo nome recusa quando há mais de um controle de verdade
   conectado e o nó não tem aparelho conhecido; um controle com conexão rádio não entra na escolha.
2. **O Windows.** `somc_plataforma_pad` roda para todo controle conectado (não só os sentados), e o `Pad` guarda o
   ContainerId.
3. **O Linux sem `pactl`.** Em `som_controle_linux.c`, quando o `pactl` não responde, ler as mesmas propriedades
   (`device.description`, o caminho do sysfs da placa) por `pw-dump`. Sem servidor nenhum, o rótulo diz
   «sem servidor de som: pelo nome só com um controle».
4. **O registro** diz quando um lugar ficou sem nó por ambiguidade («P2 · som: dois controles iguais, sem aparelho:
   fica na TV»).

## Armadilhas

- **Um DualSense só e sem `pactl`** tem de continuar achando a sua placa pelo nome: a recusa é só com dois ou mais.
- **O virtual da ponte** é USB e tem nós numerados: a passada pelo número continua antes do nome.
- **O `pw-dump` é JSON grande**: ler uma vez por `listar`, não por quadro (a mesma regra da WN02 para o `pactl`).
- **Os simulados** têm placa virtual e ficam fora, como hoje.

## Não fazer

- Não declarar o `pactl` nos requisitos de quem desenvolve achando que isso resolve: quem joga não instala
  `scripts/requisitos-sistema.txt`.
- Não ler o sysfs do ALSA para casar placa por número de carta nesta ficha: não foi medido.
- Não mexer nas passadas pelo aparelho e pelo número.

## Pronto quando

- Com quatro controles iguais e sem aparelho conhecido, nenhum lugar leva o nó de outro.
- No Windows, o nó de um controle fora da mesa não vai para ninguém.
- O controle no rádio não recebe nó.

## Provas

- **Nativa** (`prova_achar_som.c`): quatro nós de nome igual sem aparelho e dois pads reais: nenhum recebe pelo nome
  (hoje o P1 recebe, `ACHOU_NOME`); um nó com container X e um controle fora da mesa com container X: o nó fica
  reservado (hoje não); um pad no rádio: nenhum nó.
- **Nativa:** a leitura do `pw-dump` com um JSON gravado no molde do `forja_selftest_som.c` casa o mesmo
  `usb_device` que a leitura do `pactl`.

## Para o André (local)

Dois DualSense no cabo, com o `pactl` fora do caminho (`PATH` sem ele): cada pio sai no controle certo, pelo
`pw-dump`. Um terceiro controle carregando, fora da mesa: ninguém toca nele.

## Ao terminar

Marcar WU06 como **feito** no [quadro](README.md), com o commit e o gasto. Commit sugerido:
`fix(som): pelo nome só quando o nó não pode ser de outro controle`.
