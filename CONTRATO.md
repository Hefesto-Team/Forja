# CONTRATO — FORJA fala DualSense, não Hefesto

Este arquivo é a lei do jogo. Se um patch quebra uma linha daqui, o patch está errado.

FORJA é um jogo Steam de 4 jogadores locais. Ele trata cada DualSense como a Sony documenta no SDK (`scePad*` / `ScePadTriggerEffectParam`) e como a Steam documenta no Steamworks (`ISteamInput`). O daemon que estiver atrás — Hefesto, hid-playstation, um cabo — é invisível.

## Por que isso existe

Se o jogo chama `trigger.set {uniq}` no socket do Hefesto, o teste é circular: a HUD mostra o que o jogo já decidiu. Isolamento de verdade é o contrário:

1. O jogo abre 4 DualSense (player index 0..3).
2. O jogo escreve o relatório USB `0x02` no DualSense #2, como faria no PS5 e na Steam.
3. O aparelho físico do jogador 3 treme — ou treme o vizinho. O jogo não sabe. A mesa é o oráculo.

## O que o jogo pode chamar

| Intenção | Sony (SDK) | Steam Input | SDL3 |
| --- | --- | --- | --- |
| Vibração L/R | `scePadSetVibration` | `TriggerVibration` / `TriggerVibrationExtended` | `SDL_RumbleGamepad` |
| Gatilho adaptativo | `scePadSetTriggerEffect` + `ScePadTriggerEffectParam` | `SetDualSenseTriggerEffect` | `SDL_SendGamepadEffect` (payload USB) |
| Lightbar | `scePadSetLightBar` | `SetLEDColor` | `SDL_SetGamepadLED` |
| LED de jogador | padrão PS5 de 5 lâmpadas | `SetGamepadPlayerIndex` equivalente | `SDL_SetGamepadPlayerIndex` |
| Giro / acel | `scePadReadState` motion | `GetMotionData` | `SDL_GetGamepadSensorData` |
| Touchpad | `scePadReadState` touch | analog/touch origins | `SDL_GetGamepadTouchpadFinger` |
| Mute LED do mic | HID USB `0x02` byte mic LED | GameInput 3.5 DualSense helper | mesmo payload USB |
| Volume do speaker | HID USB `0x02` speaker vol | **não existe na Steam Input** | mesmo payload USB |

Modos oficiais de gatilho (`isteamdualsense.h`, os únicos que este jogo envia):

- `OFF`
- `FEEDBACK` (resistência)
- `WEAPON` (parede + clique)
- `VIBRATION` (metralhadora)

`Bow`, `Galloping`, `Machine`, `SlopeFeedback` são restos de firmware / DSX. Não entram no jogo. SMG usa `VIBRATION`. Arco usa `FEEDBACK`.

## O que o jogo recusa

Proibido no código de FORJA, em qualquer linguagem:

- socket IPC do Hefesto (`hefesto-dualsense4unix.sock`)
- `uniq`, MAC, `controller.target.set`
- UDP 6969 / DSX / `controllerIndex`
- relatório Bluetooth `0x31`
- CRC sobre cabeçalho `0xA2`
- traduzir USB→BT, volume HID-over-BT, áudio HFP

Bluetooth DualSense usa outro relatório. Este jogo **não** o implementa. Ele só fala USB `0x02`, que é o que a SDL hidapi e a Steam mandam para um DualSense em cabo (e para um DualSense *virtual* USB). Se um pad físico está no rádio e mesmo assim o efeito chega, quem traduziu foi o que estiver na frente do hidraw — e é exatamente isso que a mesa prova.

Se `forja-send` encontrar um DualSense com barramento Bluetooth, ele recusa o aparelho e escreve:

> este jogo não fala o relatório 0x31. ligue o DualSense no cabo, ou um DualSense virtual USB.

Sem citar Hefesto.

## Identidade do pad

O jogo numera DualSense por **player index** (0..3), como `SDL_SetGamepadPlayerIndex` / `scePadOpen(userId)`. Não por MAC. Não por ordem de `hidraw`.

LED de jogador (5 lâmpadas, bit 0 = esquerda):

| Player | bits | byte |
| --- | --- | --- |
| 1 | `00100` | `0x04` |
| 2 | `01010` | `0x0A` |
| 3 | `10101` | `0x15` |
| 4 | `11011` | `0x1B` |

## Dois backends, um payload

1. **Steam (preferido em runtime Steam).** `ISteamInput` no handle de cada jogador. A Steam converte `ScePadTriggerEffectParam` em HID. FORJA não empacota Bluetooth.
2. **SDL / hidraw (sem Steam, ou Linux nativo).** O mesmo `DS5EffectsState_t` de 47 bytes que a SDL manda em `SDL_SendGamepadEffect`. O driver hidapi prefixa `0x02` no USB. `forja-send` escreve `[0x02][47 bytes][pad até 64]`.

Os dois backends compartilham `native/include/forja_dualsense.h`.

## O que esta pasta do browser NÃO é

A HUD no preview (React) pinta o DualSense SVG com o que o jogo *teria enviado*. Isso é apresentação. Isolamento de verdade só existe no binário nativo, com quatro DualSense na mesa. O browser Gamepad API rumble, quando um pad real está ligado, é o único write honesto desta build web — e mesmo assim não cobre gatilho, lightbar nem speaker.
