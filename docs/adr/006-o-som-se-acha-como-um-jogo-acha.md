# ADR-006: O som de cada controle se acha como um jogo acha

**Status:** aceito · **Data:** 2026-09-27

## Contexto

O alto-falante, os atuadores da háptica e o microfone do DualSense não passam
pelo HID: no cabo, o controle é também uma placa USB Audio de quatro canais
(1–2 fone e alto-falante, 3–4 os atuadores) com o microfone ao lado. Com quatro
controles na mesa, são quatro placas — e o jogo precisa saber qual é de quem,
senão o canto do P1 sai na mão do P3 e ninguém percebe.

O `CONTRATO.md` já diz a regra para o alto-falante: ele se acha como um jogo
acha — **pelo aparelho** (o port de PS5 casa o endpoint com o controle pelo
`ContainerId`) e **pelo nome que o jogo mostra** —, e só conta o nó que um jogo
reconheceria como DualSense pela palavra da Sony. Nunca por MAC. O Hefesto, por
sua vez, publica nós nomeados por lugar: «Alto-falante do Controle N
(DualSense Wireless Controller)», «Háptica do Controle N (…)», «Microfone do
Controle N (…)» — é assim que o som de um controle no rádio chega ao sistema.

## Decisão

Cada jogador tem três papéis de som (alto-falante, háptica, microfone), e cada
papel se acha em três passos, nesta ordem (`demo/src/nucleo/achar_som.c`, lógica
pura provada sem aparelho):

1. **pelo aparelho** — no Linux, o nó cujo `sysfs.path` (do `pactl`, que o
   PipeWire responde) sobe ao mesmo `usb_device` do controle; no Windows e sob
   Proton, o endpoint do WASAPI com o mesmo `ContainerId` do HID (o CfgMgr32
   lê o do HID a partir de `SDL_GetGamepadPath`);
2. **pelo número** — o nó do Hefesto com o N do lugar do jogador;
3. **pelo nome** — o primeiro nó livre com "DualSense" ou "Wireless
   Controller".

Em todos, a palavra da Sony é obrigatória. O aviso de cada sala de som mostra o
que foi achado e como; a pessoa confere, troca (◀ ▶) e testa (△) antes de a
prova começar. O jogo toca e grava pelo SDL: um fluxo por dispositivo, ao lado
da saída principal da TV. No cabo, o alto-falante é o canal 2 da placa (a rota
do bloco de efeitos manda o direito para ele) e a háptica são os canais 3 e 4.

Controle simulado ganha uma placa **virtual** de quatro canais, que só o
simulador escuta; os defeitos de som (`sem-alto-falante`, `som-vizinho`,
`haptica-trocada`, `haptica-muda`, `mic-surdo`) entram entre o jogo e essa placa,
para o gauntlet provar que as salas de som dizem FALHOU quando devem.

## Consequências

- Um DualSense no rádio, sem o Hefesto na frente, não tem som nenhum no
  sistema: as features de som ficam NÃO MEDIDO, com o porquê. O jogo não fala
  o `0x31` (ADR-005), e o áudio pelo rádio é domínio de quem está na frente.
- Sob Proton, o caminho pelo aparelho depende de o Wine inventar o mesmo
  `ContainerId` para o HID e para o endpoint; quando não inventa, sobra o nome,
  e a pessoa confere no aviso.
- O relatório diz, para cada jogador e cada papel, o dispositivo e **como** ele
  foi achado — "passou pelo nome" vale menos que "passou pelo aparelho", e quem
  lê o relatório precisa saber.
- A explicação inteira, com as fontes públicas, está em
  [COMO-O-SOM-CHEGA-AO-CONTROLE.md](../COMO-O-SOM-CHEGA-AO-CONTROLE.md).
