# Como o som chega ao controle

O DualSense faz três coisas com som: **toca** (o alto-falante na frente do
controle), **vibra com som** (os dois atuadores voice-coil, a "háptica" dos
jogos de PS5) e **ouve** (o microfone, com o botão de mudo e a luz laranja).
Este documento conta, só com fontes públicas, por onde cada uma passa no PC —
e como a Hefesto Tech Demo acha e prova cada uma, para cada um dos quatro
jogadores.

Nada aqui vem do SDK da Sony. O que é da Sony e está sob NDA não foi usado,
nem procurado.

---

## Os três caminhos, lado a lado

| | (a) HID pelo SDL3 | (b) a placa de áudio USB | (c) a háptica por áudio |
|---|---|---|---|
| o que leva | o **painel de controle** do som: volume do alto-falante e do fone, rota, pré-amp, volume do microfone, a luz do mudo; e, na entrada, o botão do microfone | as **amostras**: o que o alto-falante toca e o que o microfone ouve | as **amostras** que movem os dois atuadores |
| por onde | o relatório USB `0x02`, no bloco de efeitos de 47 bytes (`SDL_SendGamepadEffect`) | USB Audio Class: uma placa de 4 canais de saída a 48 kHz, e a entrada do microfone | a mesma placa, canais 3 e 4 |
| quem entrega | o SDL (driver hidapi do PS5) | o sistema: ALSA/PipeWire no Linux, WASAPI no Windows (e no Wine, sob Proton) | o sistema, igual ao (b) |
| como o jogo acha | o próprio controle aberto no SDL | o dispositivo de áudio do **mesmo aparelho** do controle (ver abaixo) | igual ao (b) |
| na Tech Demo | todas as salas de saída; n'A Voz, o LED e o botão do mudo | O Canto (alto-falante) e A Voz (microfone) | Os Caminhos |

### (a) O painel: HID pelo SDL3

O bloco de efeitos que o SDL3 manda num DualSense em cabo é o
`DS5EffectsState_t` de `SDL_hidapi_ps5.c`, de 47 bytes; o SDL o copia inteiro
para depois do byte `0x02` do relatório USB. Os bytes que interessam ao som
estão nele: o volume do fone (4), o do alto-falante (5), o do microfone (6), o
controle de áudio (7) e a luz do microfone (8). O jogo monta esse bloco numa
"sombra" (`include/forja_dualsense.h`), que lembra o que cada bloco já pediu
e nunca liga os bits que o contrato proíbe (a troca de modo da háptica e a
economia de energia).

- **A rota do alto-falante.** No byte 7, os bits 4–5 dizem para onde vai o
  estéreo da placa: `0` estéreo no fone, `2` o esquerdo no fone e o direito no
  alto-falante, `3` o direito no alto-falante interno. O jogo usa `3`. O volume
  e o pré-amp padrão (`0x64` e `2`) são os que o próprio driver do kernel
  escolhe quando o fone sai (hid-playstation).
- **A luz do microfone.** O byte 8: `0` apagada, `1` acesa, `2` piscando. É ela
  que A Voz pergunta às cegas.
- **O botão do microfone.** Chega pelo SDL3 como `SDL_GAMEPAD_BUTTON_MISC1` (a
  documentação do SDL lista "PS5 microphone button" nesse botão).
- **O mudo do kernel.** No Linux, o hid-playstation trata o botão por conta
  própria: a cada aperto ele alterna o mudo, acende a luz e manda o controle
  calar o microfone no próprio aparelho. Por isso A Voz mede as duas
  coisas separadas: o botão chegou ao jogo? E, mudo, o som do microfone caiu
  (o sistema cortou) ou continuou (o mudo ficou com o jogo)?

### (b) As amostras: a placa de áudio USB

No cabo, o DualSense é também uma placa USB Audio de **4 canais de saída**:

| canal | papel |
|---|---|
| 1 (front-left) | fone, esquerdo |
| 2 (front-right) | fone, direito — e o **alto-falante** quando a rota manda o direito para ele |
| 3 (rear-left) | atuador **esquerdo** |
| 4 (rear-right) | atuador **direito** |

O canal do alto-falante foi medido de ouvido na bancada do Hefesto
(16/08/2026) e está em `include/forja_alto_falante.h`. Pelo rádio não existe
placa: é outro caminho, e está mais abaixo.

**Como um jogo acha a placa certa entre quatro controles.** A discussão
pública do Proton sobre os recursos do DualSense
([ValveSoftware/Proton#5900](https://github.com/ValveSoftware/Proton/issues/5900))
lista os três jeitos que os jogos usam:

1. pelo **nome**: o dispositivo de áudio cujo nome contém "Wireless
   Controller" (Final Fantasy XIV, Final Fantasy VII Remake);
2. pelo **container**: o `ContainerId` do HID do controle, e o primeiro
   endpoint de áudio (MMDevice) com o mesmo `ContainerId` (Ghostwire: Tokyo,
   Deathloop);
3. pelo SetupDi: o mesmo container, achado pela API SetupDi (o alto-falante
   de Deathloop).

No Windows, o `ContainerId` agrupa as funções de um mesmo aparelho físico: o
HID e o áudio do mesmo DualSense têm o mesmo
([Microsoft: Container IDs](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/container-ids)).
O endpoint expõe o dele no repositório de propriedades (o mesmo GUID do
`DEVPKEY_Device_ContainerId`), e o nó do HID responde pelo CfgMgr32
(`CM_Get_DevNode_PropertyW`).

**Sob Proton**, o Wine precisa inventar os dois do mesmo lugar: o do HID pelo
winebus, o do endpoint pelo mmdevapi, a partir do `sysfs.path` que o winepulse
lê do servidor de som (as propostas
[wine!359](https://gitlab.winehq.org/wine/wine/-/merge_requests/359),
"mmdevapi: copy ContainerID property from audio driver if available", e
[wine!7238](https://gitlab.winehq.org/wine/wine/-/merge_requests/7238),
"winebus,mmdevapi: implement audio device container id"). Depende da versão:
com o winepipewire no lugar do winepulse, o container pode não vir
([proton-cachyos#296](https://github.com/CachyOS/proton-cachyos/issues/296)),
e sobra o caminho pelo nome.

**No Linux nativo**, o PipeWire responde como PulseAudio (`pipewire-pulse`), e
`LC_ALL=C pactl list sinks` (e `sources`) dá, para cada nó, o `sysfs.path` do
aparelho por trás. Subindo por ele até o `usb_device`, chega-se ao mesmo
aparelho USB do controle — o mesmo pai que o hidraw do pad tem. É o
equivalente do `ContainerId`, e é o que o `forja-speak --player N` faz.

### (c) A háptica por áudio

A "háptica" dos jogos de PS5 não é vibração de motor: é **som** nos canais 3 e
4, uma forma de onda que os atuadores transformam em movimento. Um passo na
grama é um baque grave e macio; no metal, um golpe que ressoa. O SDL3 não tem
uma função de gamepad para isso: o jogo abre a placa do controle como um
segundo dispositivo de áudio e escreve nos canais dos atuadores. A vibração
"de compatibilidade" (`SDL_RumbleGamepad`) é outra coisa: o próprio controle a
imita nos atuadores, sem o jogo mandar forma de onda nenhuma.

---

## E pelo rádio (Bluetooth)?

Pelo Bluetooth o DualSense **não tem placa de som**. O áudio, quando passa,
passa **dentro do HID**: o microfone chega como Opus a 48 kHz, em quadros de
10 ms, no relatório de entrada `0x31` — o Hefesto mediu isso e mantém a ponte
(`docs/protocol/paridade-bluetooth-versus-cabo.md`, no
[repositório do Hefesto](https://github.com/Hefesto-Team/hefesto-dualsense4unix)).
A saída de som e de háptica pelo rádio não está implementada no Hefesto, e as
duas fontes internas dele discordam sobre o relatório que leva os dados; nada
disso foi medido.

**Este jogo não fala o relatório `0x31`** — o `CONTRATO.md` o proíbe, junto
com o CRC sobre o cabeçalho `0xA2`. O rádio é domínio de quem está na frente
do controle. Quando o Hefesto publica os nós de áudio dele —
«Microfone do Controle N (DualSense Wireless Controller)», «Alto-falante do
Controle N (…)», «Háptica do Controle N (…)» —, o jogo os acha **pelo
número**. Sem eles, um controle no rádio fica sem som nas salas de áudio, e o
veredito é NÃO MEDIDO, com o porquê.

---

## Como a Tech Demo acha o som de cada jogador

No jogo 3D, o som da TV é do Godot (o autoload `Som`); o som de cada controle
é do módulo nativo, que tem o SDL3 dentro: um segundo cliente de som, ao lado
do Godot, com um fluxo por dispositivo (`nativo/som/som_controle.c`). O som do
SDL só abre na primeira sala de som — quem joga só as salas de entrada não
pede nada ao servidor de som —, e o GDScript toca pelo lugar do jogador
(`Forja.som_falante`, `Forja.som_haptica`, `Forja.som_mic`); os sons que vão
ao controle são os da forja, sintetizados no módulo (`nativo/som/sons_salas.c`).

Ao entrar numa sala de som, o módulo pede ao SDL a lista de dispositivos de
áudio e completa cada um com o que o sistema sabe:

- **Linux:** `pactl` dá o `sysfs.path`, e dele o `usb_device`;
- **Windows e Proton:** o WASAPI dá o `ContainerId` de cada endpoint, e o
  CfgMgr32 dá o do HID do controle (a partir do caminho que o SDL devolve em
  `SDL_GetGamepadPath`).

Depois, para cada jogador e cada papel (alto-falante, háptica, microfone),
tenta nesta ordem (`nativo/nucleo/achar_som.c`, provado sem aparelho):

1. **pelo aparelho** — o mesmo USB, ou o mesmo `ContainerId`;
2. **pelo número** — «… do Controle N» com o N do lugar do jogador;
3. **pelo nome** — o primeiro livre com "DualSense" ou "Wireless Controller".

Em todos, só conta o nó que um jogo reconheceria como DualSense pela palavra
da Sony — os nós numerados do Hefesto a trazem entre parênteses. Nunca por
MAC. O aviso da sala mostra, para cada jogador, o dispositivo achado e **como**
foi achado; ◀ ▶ troca, △ toca um teste nele (um sino no alto-falante; um pulso
na esquerda e depois na direita, na háptica; no microfone, a barra sobe com a
voz). Quem joga confere antes de a prova começar.

Controle simulado (`--simular`) não tem dispositivo: o som dele vai para uma
placa **virtual** de quatro canais que só o simulador "escuta" — é assim que o
robô do gauntlet ouve o alto-falante e sente os atuadores do controle dele, e
é aí que entram os defeitos de mentira (`--defeitos=sem-alto-falante`,
`som-vizinho`, `haptica-trocada`, `haptica-muda`, `mic-surdo`). A placa virtual
não precisa de servidor de som: a prova do CI, que não tem nenhum, roda as três
salas de som inteiras. Ela anda no tempo do jogo (cada quadro mistura o que
cabe no quadro), e é por isso que a prova, mais rápida que o tempo real, ouve
o mesmo que ouviria devagar.

---

## Como cada sala prova

As três salas são provas às cegas, como as de saída por HID (ADR-003): o jogo
sabe o que mandou, a tela não mostra, e quem joga diz o que sentiu. FALHOU só
com evidência.

- **O Canto** — a bigorna canta um ritmo no alto-falante de UM controle, ou
  na TV. Todo mundo ouve; a pergunta é outra: "saiu da SUA mão?". Reprova o
  canto que não sai no controle dele (o canal 2 não chega ao alto-falante) e o
  canto dos outros que sai no dele (o som não fica no controle certo).
- **Os Caminhos** — cada boneco anda no escuro; o chão (grama, cascalho, metal,
  água) só existe nos atuadores, e um tropeço treme um lado só. Reprova quem
  diz "não senti" o caminho inteiro, os lados trocados (canais 3 e 4
  invertidos), o atuador de um lado que nunca recebe e a textura que chega
  deformada.
- **A Voz** — o silêncio de todos (o piso), a voz de cada um na sua vez, o
  botão do mudo, a voz baixinha já mudo, e a luz do microfone perguntada às
  cegas. Reprova o microfone que não sobe com a voz, o botão que não chega e a
  luz que não é a que o jogo mandou. O susto do fim — vibração forte e o grito
  no alto-falante do controle, com a TV batendo — é o padrão dos jogos de
  terror, e não entra no veredito.

---

## O que o jogo não faz, e por quê

- não liga a troca de modo da háptica (`HAPTICS_SELECT`) nem a economia de
  energia (`POWER_SAVE`) no bloco de efeitos: são bits que a sombra recusa;
- não fala o relatório Bluetooth `0x31`, nem calcula CRC com `0xA2`;
- não abre o socket do Hefesto, não lê `uniq` nem MAC;
- não usa nada do SDK da Sony.

---

## Fontes

Todas públicas.

- Linux, `drivers/hid/hid-playstation.c` — os relatórios de saída USB `0x02`
  (63 bytes) e Bluetooth `0x31` (78 bytes, CRC32 com semente `0xA2`), os bits
  de validade, o botão do mudo (alterna, acende a luz e cala o microfone no
  aparelho) e o volume do alto-falante quando o fone sai:
  <https://github.com/torvalds/linux/blob/master/drivers/hid/hid-playstation.c>
- SDL3, `src/joystick/hidapi/SDL_hidapi_ps5.c` — o `DS5EffectsState_t` de 47
  bytes e a cópia do bloco para o relatório USB:
  <https://github.com/libsdl-org/SDL/blob/main/src/joystick/hidapi/SDL_hidapi_ps5.c>
- SDL3, `include/SDL3/SDL_gamepad.h` — `SDL_SendGamepadEffect`,
  `SDL_GetGamepadPath` e o botão do microfone do PS5 em `MISC1`:
  <https://github.com/libsdl-org/SDL/blob/main/include/SDL3/SDL_gamepad.h>
- SDL3, a API de áudio (dispositivos de reprodução e gravação, fluxos):
  <https://wiki.libsdl.org/SDL3/CategoryAudio>
- ValveSoftware/Proton#5900, "DualSense advanced features compatibility" — os
  três jeitos que os jogos usam para achar o áudio do controle:
  <https://github.com/ValveSoftware/Proton/issues/5900>
- Wine, merge requests 359 e 7238 — o `ContainerId` do endpoint de áudio a
  partir da topologia do Linux:
  <https://gitlab.winehq.org/wine/wine/-/merge_requests/359> ·
  <https://gitlab.winehq.org/wine/wine/-/merge_requests/7238>
- CachyOS/proton-cachyos#296 — a háptica que não começa quando o container não
  vem, com o winepipewire: <https://github.com/CachyOS/proton-cachyos/issues/296>
- Microsoft, Container IDs, `DEVPKEY_Device_ContainerId` e
  `CM_Get_DevNode_PropertyW`:
  <https://learn.microsoft.com/en-us/windows-hardware/drivers/install/container-ids> ·
  <https://learn.microsoft.com/en-us/windows-hardware/drivers/install/devpkey-device-containerid> ·
  <https://learn.microsoft.com/en-us/windows/win32/api/cfgmgr32/nf-cfgmgr32-cm_get_devnode_propertyw>
- PipeWire (e o `pipewire-pulse`, que responde ao `pactl`):
  <https://docs.pipewire.org/>
- Hefesto — a paridade Bluetooth × cabo (o áudio pelo rádio, medido) e os
  nomes dos nós de som por controle:
  <https://github.com/Hefesto-Team/hefesto-dualsense4unix/blob/main/docs/protocol/paridade-bluetooth-versus-cabo.md>
- Neste repositório: `CONTRATO.md`, `include/forja_dualsense.h` (a sombra e
  os bytes do som), `include/forja_alto_falante.h` (o canal do alto-falante e
  o `forja-speak`), `docs/SALAS.md` (as regras das salas) e
  `docs/adr/006-o-som-se-acha-como-um-jogo-acha.md`.
