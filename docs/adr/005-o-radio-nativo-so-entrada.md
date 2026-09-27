# ADR-005: DualSense nativo no rádio entra só com a entrada

**Status:** aceito · **Data:** 2026-09-27

## Contexto

O `CONTRATO.md` proíbe o relatório Bluetooth `0x31` e o CRC `0xA2` no código da
Forja. O SDL3, sozinho, empacota o `0x31` quando abre um DualSense nativo pelo
rádio — e aí quem traduziu para o rádio foi o próprio jogo, não o que estiver na
frente. A validação do Hefesto no rádio perderia o sentido.

## Decisão

Antes do `SDL_Init`, a Tech Demo liga `SDL_HINT_JOYSTICK_ENHANCED_REPORTS = "0"`.
No código do SDL 3.4.14 (`SDL_hidapi_ps5.c`), isso só afeta o rádio: no cabo, e
em todo DualSense que se declara USB (o virtual por `uhid`), o modo completo
continua ligado.

- **Cabo:** tudo funciona, pelo `0x02` que o SDL monta a partir do payload de 47
  bytes da Forja (`include/forja_dualsense.h`).
- **Rádio com o Hefesto na frente:** o controle chega como DualSense Edge virtual
  (USB), e tudo funciona — quem traduz para o rádio é o Hefesto. É o que a mesa
  valida.
- **Rádio sem ninguém na frente:** o controle entra na mesa com botões e
  analógicos; o cartão diz *"este jogo não fala o relatório 0x31. ligue o
  DualSense no cabo, ou um DualSense virtual USB."*, a mesma frase do
  `forja-send`.

## Consequências

- O relatório diz a conexão e a origem de cada controle, para que "passou no
  rádio" signifique "o Hefesto entregou".
- O SDL ainda manda, sozinho, um `0x31` vazio e sem CRC quando um controle do
  rádio fica 3 s sem report (é como ele detecta a queda). O firmware o descarta;
  fica registrado aqui para ninguém tomá-lo por escrita do jogo.
