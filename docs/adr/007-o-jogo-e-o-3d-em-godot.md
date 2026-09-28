# ADR-007: o jogo é o 3D em Godot, com o SDL3 dentro dele

**Status:** aceito · **Data:** 2026-09-28 · **Substitui em parte:** [ADR-004](004-sdl3-em-c.md)

## Contexto

A Forja já tinha um jogo 3D em Godot 4.4 — o salão, as salas, os bonecos —
quase pronto. O ADR-004 levou a Tech Demo para um app 2D em C sobre SDL3, e
com isso o jogo 3D ficou para trás: a arte que existia deixou de ser a base, e
as salas viraram telas 2D. O pedido era outro: **melhorar o 3D** que existia e
fazer as salas se comportarem como os jogos comerciais usam o DualSense.

O ADR-004 tinha razões que continuam valendo:

- o Godot 4.4 não expõe giroscópio, touchpad, gatilho adaptativo, LED do mudo
  nem o alto-falante do controle;
- o `.exe` pelo Proton é o caminho que a maioria dos jogos faz até o Hefesto,
  e ele tem de achar o som do controle como os ports de PC acham.

## Decisão

1. **O jogo é o 3D em Godot** (`godot/`). O 2D sai do branch; o núcleo em C
   que ele tinha (relatório, vereditos, origem do controle, simulador,
   linha do tempo, provas) fica, em `nativo/`.
2. **O SDL3 vai dentro do Godot**, como um módulo nativo (GDExtension, via
   godot-cpp): `nativo/godot/` expõe o nó `ForjaControles` ao GDScript. O
   módulo fala com os DualSense como o CONTRATO pede — o payload USB `0x02`
   que o SDL monta, player index 0..3, os quatro modos de gatilho — e grava o
   relatório da sessão.
3. **Linux e Windows** saem do mesmo código: `libforja.linux.x86_64.so` e
   `libforja.windows.x86_64.dll` (mingw-w64, sem DLL do mingw), e o jogo
   exporta um binário Linux e um `.exe` — o `.exe` é o que roda pelo Proton.
4. **O som por controle** (alto-falante, háptica por áudio nos canais 3 e 4,
   microfone) também entra pelo módulo: PipeWire no Linux, WASAPI e o
   `ContainerId` do mesmo aparelho no Windows (marco do áudio).
5. `forja-send`, `forja-speak` e `forja-read` continuam como ferramentas de
   bancada, com o mesmo empacotador (`src/forja_dualsense.c`).

## Consequências

- O Godot dono da janela, do 3D e da interface; o módulo dono dos controles
  (`SDL_Init` só de gamepad e eventos). O Godot 4.4 não usa SDL, então não há
  dois SDL no processo.
- O teclado joga sem controle: o título oferece um DualSense simulado dirigido
  pelo teclado, e o módulo inteiro roda — o relatório diz que foi simulado.
- A prova do jogo (`tests/prova_do_jogo.sh`) e o gauntlet
  (`scripts/gauntlet.sh`) rodam o Godot headless com quatro DualSense
  simulados e conferem o que cada controle recebeu.
- O ADR-004 fica valendo para o SDL3 fixado (3.4.14) e para o `.exe` pelo
  Proton; o app 2D e o "Godot como jogo antigo" dele deixam de valer.
