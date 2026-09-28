# O Hefesto por dentro — o que muda para quem valida jogando

Estudo de 27/09/2026, feito lendo o clone do Hefesto no commit `d587a73`, só
leitura. Abreviações: **P/** = `docs/protocol/`, **S/** =
`src/hefesto_dualsense4unix/`. Os documentos do Hefesto marcam a própria
confiança: "MEDIDO" é medido; "afirmado-no-doc" vem de fonte de terceiros.

O jogo não usa nada do que aqui é do rádio (o relatório `0x31`, o CRC, o
`uniq`): o [CONTRATO](../../CONTRATO.md) proíbe. Está aqui para entender o
que o Hefesto faz na frente do controle — e por que um veredito pode mudar
com ele na frente. As linhas citadas são as do commit do estudo.

## O que muda para o CONTRATO (ler primeiro)

- **Os LEDs de jogador que o jogo escreve nunca chegam ao controle físico pelo
  Hefesto.** Desde 23/09 o Hefesto sempre os recusa
  (`S/core/backend_pydualsense.py:631,7117-7122`). No modo Nativo, o próprio
  Hefesto escreve a barra de luz e os LEDs de jogador (`:633-645`). Num teste
  de LEDs de jogador, então, o controle mostra o número do Hefesto, não o que
  o jogo mandou.
- **A cópia da barra de luz tem duas armadilhas:**
  - é recusada quando a cor está na paleta de jogadores do SDL (`0x000040,
    0x400000, 0x004000, 0x200020, 0x201000, 0x001010, 0x101010`)
    (`:659-694`);
  - fica retida e depois é descartada enquanto o Hefesto acha que nenhum jogo
    está rodando. Ele só conta um jogo se vê uma janela `steam_app_<id>`, uma
    regra de perfil que casa, a marca do wrapper ou um processo `SteamLaunch
    AppId=` (`S/daemon/subsystems/game_signal.py:154-172`). Um jogo aberto com
    `./run-local.sh`, fora da Steam, provavelmente não tem a barra de luz
    copiada.
- **O volume do alto-falante, a rota do som e o LED do microfone mandados ao
  controle virtual nunca são copiados ao físico** (detalhes em B2).
- **Por padrão, o instalador desliga o suporte a PlayStation da Steam em todo
  `localconfig.vdf`** (`install.sh:210-216,4303-4330`). Um backend pelo
  ISteamInput não vê o DualSense, a não ser com o Hefesto instalado com
  `--keep-steam-input`.
- **O "microfone padrão do sistema" não vai ser o do controle.** Um drop-in do
  WirePlumber rebaixa o microfone do DualSense por padrão
  (`install.sh:199-204`). Escolha o microfone pelo nome.

## A. Os onze documentos de protocolo

**paridade-bluetooth-versus-cabo.md**
- Barra de luz, LEDs de jogador, gatilhos e motores foram medidos funcionando
  pelo Bluetooth. Os gatilhos não mudam entre rádio e cabo: "o `common` é
  idêntico nos dois envelopes" (`:44-55`).
- O som é outro canal, não um canal pior. No cabo o controle é uma "placa USB
  Audio de **4 canais**": "1-2 fone/alto-falante · 3-4 os motores
  voice-coil". Pelo Bluetooth não há "nenhum áudio nativo", e o som vai dentro
  do HID (`:122-132`). O PipeWire mostra zero placas de som para um controle
  no rádio (`:55`).
- Taxa de entrada: no cabo, "250,0 Hz" exatos; no Bluetooth, de 157,8 a
  381,5 Hz, em rajadas: "O rádio não tem taxa típica" (`:100-103,158-163`).
- O controle virtual se apresenta como um Edge (`0x0DF2`), e o SDL supõe "1000
  Hz a um Edge por USB" quando só chegam 250 Hz (`:224-231`). Integre o
  giroscópio pelo carimbo de tempo de cada evento, não pela taxa declarada.
- A barra de luz pelo Bluetooth falha se a Steam estava com o hidraw aberto
  quando o controle conectou: 1 de 3 controles obedeceu com a Steam aberta, 3
  de 3 sem ninguém segurando (`:62-73`).
- Com vários controles no mesmo rádio, aparece no dmesg: `playstation
  0005:054C:0CE6.0007: DualSense input CRC's check failed` (`:172`).
- Linhas desatualizadas: "speaker over BT NÃO IMPLEMENTADO" (`:54`) já não
  vale, porque o som sai pelo Bluetooth no report `0x35`
  (P/proton…:459,472-476). O item "microfone e giroscópio no BT não convivem"
  (`:188-192`) foi corrigido pela guarda `INPUT_FLAG_AUDIO`
  (`S/integrations/dualsense_bt_audio.py:144-150`).

**dualsense-plataforma-e-identidade.md**
- A sondagem do kernel lê `0x09 PAIRING_INFO (20 B) → 0x20 FIRMWARE_INFO (64 B)
  → 0x05 CALIBRATION (41 B)`. Qualquer falha aborta a sondagem inteira
  (`:66-72`).
- Pelo Bluetooth, ler `0x09` ou `0x20` "will also enable enhanced reports over
  Bluetooth" (`:83-96`).
- O report `0x09` traz o endereço do próprio controle nos bytes 1-6 e o do
  computador pareado nos bytes 10-15; o `uniq` e o serial do hidapi saem dele
  (`:104-110,227-230`).
- Um clone conhecido responde só às features "`0x05`, `0x09` e `0x20`"
  (`:152-157`). O original também responde a `0x80`/`0x81`, com o serial e a
  cor do plástico (`:160-165`).
- `0x0A` e `0xE0` só existem no cabo; `0x03` não existe num controle
  original. Para `0xF0`–`0xF5`, o documento diz "Não mexer." (`:37-56`).

**onde-a-porta-usb-mora.md**
- O kernel expõe `physical_location/{panel,horizontal_position,
  vertical_position,lid,dock}` para cada porta, e o aparelho plugado herda os
  valores da porta (`:31-74`).
- Os valores vêm das tabelas ACPI da placa-mãe; na placa medida, só 14 de 22
  portas os têm (`:111-146`).
- "não é um identificador": 14 portas deram só 5 trincas diferentes; o valor
  `location`, de 32 bits, separa melhor as portas (`:245-280`).
- Regra: o produto pode dizer "a face e a região", não o soquete exato
  (`:289-291`). Serve só como dica na tela.

**combinacao-varios-controles-o-que-e-do-aparelho.md**
- Os dois transportes levam o mesmo bloco de 47 bytes. No USB: report `0x02`,
  bloco no byte 1, motores em `[3]/[4]`, LEDs de jogador em `[44]`, RGB em
  `[45..47]`. No Bluetooth: report `0x31`, depois sequência e marca, depois
  `0x10`, bloco no byte 3, CRC32 em `[74..77]` (`:44-57`).
- O pydualsense põe o bloco do Bluetooth um byte cedo demais (`:84-100`). No
  USB, reports de 63, 48 e 64 bytes funcionam (`:104-109`).
- A troca para os reports completos do Bluetooth é por controle e não tem
  volta ("one-way ticket"). Se falha, o sintoma é "esse aqui não tem
  giroscópio" (`:115-135`).
- Um quadro de entrada do Bluetooth com CRC errado é descartado em silêncio
  (`:139-151`). O controle não tem ajuste de taxa (`:171-179`).
- O número do jogador tem três donos (o kernel, o SDL/Steam e o serviço). O
  SDL liga o bit `0x20` = "muda na hora em vez de esmaecer"; o kernel não
  (`:218-250`). Por padrão, o SDL escreve os LEDs e as cores da paleta
  (`:260-265`).
- Limite medido no Bluetooth: cada ponte de som do Hefesto manda 93,75
  reports/s de 334 B. "O TETO MEDIDO DESTA MESA É DUAS PONTES"; uma terceira
  ponte derrubou os quatro controles, e o `write()` nunca falha quando isso
  acontece (`:339-359,371-376`).

**proton-o-pino-desta-casa-e-a-subida-para-o-11-7.md**
- O GE-Proton 11-7 mantém a pilha de áudio e háptica da Sony "retaining
  behavior" (`:216-222`).
- O microfone e o alto-falante pelo Bluetooth são código do próprio Hefesto; o
  `winebus` só passa os reports adiante ("é um cano") (`:450-491`).
- Um jogo pelo Proton tocando som ou háptica num controle no cabo "ainda não
  foi confirmada" (`:493-510`).
- `dsound`, `ContainerId` e `MMDevice` não aparecem nas notas das versões
  11-4 a 11-7. Todo `dsound.dll`, inclusive o da 10-34, tem os mesmos 12
  símbolos de `ContainerId` (`:526-558`).
- O `PROTON_ENABLE_HIDRAW` parou de funcionar no Proton 10; o
  `PROTON_DISABLE_HIDRAW` o substituiu. O Proton ≤9 vaza um controle duplicado
  (`:438-442`). Alguns appids ganham variáveis de controle especiais do Proton
  (`:412-426`).

**dualsense-modo-de-relatorio.md**
- Não existe comando de modo de relatório. O report USB `0x01`, de 64 bytes,
  já é o completo (`:19-34`).
- Pelo Bluetooth, o controle começa num report `0x01` de 10 bytes. Qualquer
  leitura de feature, ou qualquer saída `0x31` (mesmo com CRC errado), o troca
  para o report `0x31` de 78 bytes até desligar (`:36-44,107-114,251-273`).
- Se um controle no rádio fica preso no modo básico, o dmesg mostra `…:
  Unhandled reportID=1` (`:97-105`).
- O número de sequência do Bluetooth não é conferido. CRC errado quer dizer
  que o report não faz nada, em silêncio, mesmo com o `write()` dando certo
  (`:209-227`).
- As sementes do CRC são bytes do cabeçalho HID do Bluetooth: `0x43` / `0x53`
  / `0xA3` / `0xA2` (`:309-318`). Pôr a feature `0x08` em 2 desliga o controle
  (`:344-351`).

**dualsense-energia-e-vibracao.md**
- A bateria é o byte 52 do corpo (`report[53]` no USB, `[54]` no Bluetooth).
  Percentual = `min(n*10+5,100)`. Nibble alto: 0 descarregando, 1
  carregando, 2 cheio, `0xA/0xB/0xF` erro (`:22-40`).
- Não há campo de frequência. Os motores são amplitudes nos bytes `common[2]`
  (direito) e `[3]` (esquerdo); a frequência de verdade vem da onda nos canais
  de áudio 3-4 (`:66-83`).
- A emulação v2 é o bit 2 do byte 38; na v1, a força deveria cair à metade
  (`:75-90`).
- O filtro passa-baixa da háptica é o bit 0 do byte 39, ligado pelo bit 5 do
  `valid_flag1` (`:98-107`).
- O bit 2 do byte `common[9]` é `HapticPowerSave` e o bit 7 é `HapticMute`
  (`:109-111`): mantenha os dois zerados.
- O limiar do firmware v2 é disputado: `0x0215` contra `0x0224`
  (`:117-138`).

**luz-do-dualsense-o-que-terceiros-mapearam.md**
- Os LEDs de jogador são o byte `common[43]` (bit 0 = a lâmpada da esquerda),
  ligados pelo bit `0x10` do `valid_flag1`; pelo Bluetooth ficam em
  `report[46]` (`:15-49`).
- Bit 5 ligado = muda na hora; desligado = esmaece. O kernel nunca o liga
  (`:53-71`).
- A revisão de hardware "Generation 0x04" liga as lâmpadas {1,5} e {2,4}
  juntas, então só há padrões simétricos (fonte única) (`:80-111`). Uma máscara
  assimétrica, como `0x10`, mostra isso.
- O estado dos LEDs não se lê de volta (`:122-146`).
- O byte de brilho `common[42]` esmaece os LEDs de jogador, não a barra de luz,
  e precisa do bit 0 do `valid_flag2` (medido:
  `S/core/ds_output_report.py:233-243`).

**dualsense-report-de-entrada.md**
- Três formatos de entrada: USB `0x01` de 64 B, Bluetooth básico `0x01` de
  10 B, Bluetooth `0x31` de 78 B (`:22-28`).
- Posições no corpo: analógicos 0-3, L2/R2 4-5, botões 7-10, giroscópio
  15-20, acelerômetro 21-26, carimbo de tempo 27-30 (em unidades de 0,33 µs),
  toque 32-39, estado 52-54 (`:48-65`).
- O direcional é um valor de "hat", 8 = centro. `buttons[2]`: bit 0 PS, bit 1
  clique do touchpad, bit 2 microfone (`:79-101`).
- No report de 10 bytes do Bluetooth, os gatilhos vão para o fim e o bit do
  microfone some (`:132-153`).
- Os botões de trás do Edge não aparecem no evdev (`:103-108`).

**dualsense-o-que-nao-e-canal….md**
- O controle virtual zera os bytes 40-51 do corpo (o eco do gatilho
  adaptativo), então um jogo que os lê vê "nenhum efeito carregado … para
  sempre" (`:72-107`).
- Os bits 3/4 do byte 53 do corpo dizem dados USB / energia USB, o que separa
  um cabo de dados de um cabo só de carga (`:188-202`).
- Pelo Bluetooth, o byte 6 do corpo (a sequência) dizem que fica congelado,
  então conferir se o controle está vivo por ele é cego (`:252-258`).
- A ordem dos eixos do giroscópio é disputada (X, Z, Y) (`:155-165`).

**trigger-modes.md**
- Os nomes antigos correspondem assim: `0x21` Feedback, `0x25` Weapon, `0x26`
  Vibration, `0x05` "OFF — não faz nada", `0xFC` "Debug — CORROMPE o estado"
  (`:13-21`).
- Os modos oficiais levam uma máscara de zonas e forças de 3 bits codificadas
  como `força − 1`. As funções antigas `rigid()`/`feedback()` "mandariam OFF"
  (`:23-29`).

**Armadilhas de byte no payload de 47 bytes** (do código e dos registros de
bancada, não dos documentos acima)
- `common[4..7]` = volume do fone / volume do alto-falante / volume do
  microfone / byte de áudio, ligados pelos bits `0x10/0x20/0x40/0x80` do
  `valid_flag0`. Tetos: fone `0x7F`, microfone `0x40`
  (`S/core/ds_output_report.py:101-123,205-207`).
- Os bits 4-5 de `common[7]` são a rota da saída: 0 estéreo→fone, 1
  mono→fone, 2 E→fone / D→alto-falante, 3 só o alto-falante (`:134-146`). O
  padrão do firmware é 0: "NÃO ESCREVER A ROTA É ESCOLHER O FONE"
  (`docs/data/ensaios.csv:229`).
- Os bits 0/2/3 do mesmo byte: "bit0 zerado **mata a captação**", e o bit 2
  em zero desliga o cancelamento de eco. O valor-base seguro é `0x0D`
  (`ds_output_report.py:148-179`).
- O pré-amplificador do alto-falante são os bits 0-2 de `common[37]` (padrão
  `0x2`), ligados pelo bit `0x80` do `valid_flag1`. Sem ele, o volume fica mudo
  até 38 e satura em 102 (`:181-230`).
- O alto-falante interno toca só o canal D (índice 1). O índice 0 vai para o
  fone esquerdo; os índices 2-3 são os atuadores (`ensaios.csv:172-173`). O
  upmix estéreo do PipeWire pode vazar som para os canais da háptica (`:174`).
- Se o report leva volume 0 no alto-falante, ele fica mudo (`:157-159`).
- O PipeWire suspende a saída parada, e o primeiro som depois do silêncio se
  perde: mantenha a saída rodando (`:167`).
- Com o motor diferente de zero, o SDL liga `ucEnableBits1 |= 0x02 /* desliga
  haptics de áudio */` (`S/integrations/uhid_gamepad.py:214-218`), o que
  desliga a háptica dos canais 3-4 até ser limpo.

## B. Os aparelhos virtuais do Hefesto

**B1. O DualSense virtual por uhid ("vpad")** (`S/integrations/uhid_gamepad.py`)
- Criado com o nome `"DualSense Wireless Controller (Hefesto P{N})"`
  (`:1208`), phys `"hefesto-vpad"` (`:579`), barramento `0x03` USB, VID/PID
  `054C:0DF2`, versão `0x0100` (`:1660-1668`).
- Os nós de entrada dele mostram a versão `0x8100`, porque o driver do kernel
  soma `0x8000` (`assets/dkms/hid-playstation/hid-playstation.c:89,1917`).
- O `uniq` é um endereço inventado, que começa em `02:fe:`; os quatro bytes
  seguintes saem de um hash (`blake2b`) do endereço do controle físico
  (`:620-672`). Na falta dele: `02:fe:00:00:00:0N` (`:604-617`); as variantes
  de colisão estão em `:2611-2643`.
- Mora em `/sys/devices/virtual/misc/uhid/0003:054C:0DF2.NNNN/`. Mas, com o
  BlueZ ≥5.73, os controles físicos no Bluetooth também moram nessa pasta,
  como `0005:…`, então o caminho sozinho não prova nada
  (`S/integrations/no_do_vpad.py:40-44`).
  - **Como separar o virtual:** `HID_PHYS=hefesto-vpad` no `uevent` do
    aparelho HID pai.
- Os nós filhos são o controle, "… Motion Sensors", "… Touchpad" e "… Headset
  Jack". O `phys` deles vem vazio, porque o driver do kernel não o copia
  (`S/core/evdev_reader.py:239-250`).
- Usa um descritor de report USB fixo, sem o item `85 31`, e sempre manda o
  report `0x01` de 64 bytes, qualquer que seja o transporte do físico
  (`S/integrations/uhid_blueprint.py:73-93`).
- **Responde só às features `0x05`, `0x09` e `0x20`;** qualquer outra leitura
  volta vazia, e as escritas de feature são aceitas e ignoradas
  (`:130,2545-2564`). É o mesmo perfil do clone descrito acima.
- Os bytes de movimento 15-39 são copiados sem mudança do controle físico, no
  ritmo dele. A bateria é espelhada (desconhecida, vira `0x1F`), e os bits
  0-2 do jack também (`:471-545`).
- O N do nome fica fixo quando o controle é criado. Com o libSDL2 do sistema
  no caminho do evdev, os quatro controles apareceram como "Hefesto P1" pela
  API de GameController (`S/daemon/subsystems/coop.py:1086-1107`).

**B2. O que as escritas do jogo no controle virtual fazem**
- Só o report `0x02` é lido; qualquer outro é descartado (`:2194-2204`).
- A cópia só acontece enquanto um jogo está com o aparelho aberto, a partir de
  0,5 s depois de ele aparecer; sem repetição, e com teto de 250 Hz por
  categoria (`:381,388,2396-2469`).
- **Motor:** passa se `flag0 & 0x03` ou `flag2 & 0x04` está ligado, e o pedido
  de parar do SDL é respeitado (`:880-902,2242-2259`). Um motor sem report de
  vibração novo por 3,0 s é cortado: mande o motor de novo a cada ~2 s, no
  máximo (`:238,2351-2384`).
- **Gatilhos:** `flag0 0x04` → bytes `[10..20]` e `flag0 0x08` → `[21..31]`
  passam sem mudança. O lado do gatilho que o perfil da pessoa fixou é recusado
  (`backend_pydualsense.py:7068-7090`).
- **Barra de luz** (`flag1 0x04`): passa pelas três barreiras do começo deste
  estudo.
- **LEDs de jogador** (`flag1 0x10`, com máscara `&0x1F`): sempre recusados.
- **LED do microfone** e **`common[4..7]`** não passam; os bytes de áudio só
  vão para o registro (`:308-311,2214-2237`).

**B3. Os controles virtuais por uinput** (`S/integrations/uinput_gamepad.py`)
- Xbox: `"Microsoft X-Box 360 pad (Hefesto - Dualsense4Unix virtual)"`,
  `045e:028e`, versão `0x3`, barramento USB (`:57-59,160-165`).
- DualSense de reserva: `"Sony Interactive Entertainment DualSense Edge
  Wireless Controller"`, `054c:0df2` (`:85-88`).
- Nenhum número de jogador nesses nomes. O Hefesto não define um phys, então
  vale o padrão do python-evdev (não conferido em execução). Sem hidraw, sem
  `uniq`; moram em `/sys/devices/virtual/input/`.

**B4. Os nós do PipeWire de cada controle**

| papel | nome do nó | descrição | formato | outras propriedades |
|---|---|---|---|---|
| alto-falante, nos dois transportes (`S/integrations/alto_falante_bt.py:1092-1200,1316-1326`) | `hefesto_som_<os 6 últimos dígitos hexadecimais do endereço>` (null-sink) | `Alto-falante do Controle N (DualSense Wireless Controller)` | `s16le`, 48 kHz, 2 canais | `priority.session=10`, nome do fabricante e do produto, `node.nick`; sem bus, VID/PID nem `sysfs.path` |
| háptica, só controles no Bluetooth (`S/integrations/endpoint_de_haptica.py:113-116,369-400,644-769`) | `alsa_output.usb-Sony_Interactive_Entertainment_DualSense_Wireless_Controller_HEFESTO<hex6>-00.HiFi__Speaker__sink` (null-sink) | `Háptica do Controle N (DualSense Wireless Controller)` | `float32le`, 48 kHz, 4 canais FL,FR,RL,RR | `device.bus=usb`, `device.vendor.id=054c`, `device.product.id=0ce6`, `sysfs.path=<interface USB de um aparelho sem relação>`, `priority.session=0`, canais de trás a 100% |
| microfone (`S/integrations/dualsense_bt_audio.py:277-278,688,765-892`) | `hefesto_mic_<hex6>` (pipe-source) | `Microfone do Controle N (DualSense Wireless Controller)` | `s16le`, 48 kHz, mono | `priority.session=1500` |

- A rota do alto-falante: no cabo, volta para a saída USB do próprio controle,
  em FL/FR (`:3568-3577`). No Bluetooth, passa pela ponte `0x35`, que só roda
  enquanto há som tocando. Cada controle no rádio fica no modo alto-falante ou
  no modo háptica, nunca nos dois (`:862-867`).
- Sob o Proton, o nome da saída de háptica que o jogo vê vira «Speakers
  (DualSense Wireless Controller)» (`endpoint_de_haptica.py:67-70`).
- Microfone: no cabo, vem do microfone ALSA do próprio controle; no
  Bluetooth, a captura só roda enquanto alguém grava (`:90-97`).
- As descrições têm teto de 62 caracteres sob o Wine
  (`S/integrations/vestido_de_dualsense.py:50-53`). Não se editam no lugar:
  renomear é descarregar e carregar o nó de novo
  (`dualsense_bt_audio.py:2121-2129`).
- O wrapper do Hefesto escreve um aparelho de áudio KS no prefixo do Proton. O
  ContainerId dele é `{(pid<<16|vid)-BUSNUM-DEVNUM-Data4}`, em que o Data4 pode
  ser 0 (`S/integrations/audio_ks_dualsense.py:19-43`). No Bluetooth, esse ID
  vem do aparelho-âncora sem relação. Um ContainerId que case o HID do
  controle virtual com uma saída de áudio não está documentado em lugar
  nenhum.

**B5. "Controle N"**
- N é a ordem de chegada do controle entre os conectados
  (`S/daemon/subsystems/base.py:86-121`, `coop.py:1880-1918`).
- O mesmo número manda nos LEDs de jogador físicos, nos nomes dos nós de áudio
  e no "Hefesto PN" do controle virtual (fixo desde a criação,
  `coop.py:1017-1030`).
- O lugar fica guardado por 30 s depois que o controle sai
  (`docs/usage/modos.md:187-196`).

**B6. O ambiente de lançamento** (`S/daemon/launch_env.py:1521-1650`,
`assets/hefesto-launch.sh`)
- Só vale para lançamentos pela Steam com `SteamAppId` numérico e o serviço
  vivo (`hefesto-launch.sh:20-53`). Só 9 variáveis são permitidas
  (`launch_env.py:82-92`).
- Sempre: `SDL_GAMECONTROLLER_USE_BUTTON_LABELS=0`,
  `SDL_ACCELEROMETER_AS_JOYSTICK=0`,
  `PROTON_KEEP_SONY_AUDIO_ENDPOINT_VISIBLE=1`,
  `PROTON_ENABLE_MHWILDS_USB_AUDIO=1` (vira `0` sem uma saída de som de
  DualSense, `hefesto-launch.sh:700-721`), e duas variáveis do cache de
  shaders.
- "Jogar pelo Hefesto" com a máscara DualSense:
  `PROTON_DISABLE_HIDRAW=0x054C/0x0CE6` e, só quando todo controle físico tem
  um virtual, `SDL_GAMECONTROLLER_IGNORE_DEVICES=0x054c/0x0ce6,0x28de/0x11ff`.
  O `0x0DF2` nunca entra na lista.
- Máscara Xbox/Nintendo: também `SDL_JOYSTICK_HIDAPI=0`.
- Modo Nativo, ou emulação desligada: nenhuma das variáveis de controle acima.

**B7. Esconder e segurar**
- Os nós hidraw físicos (USB `0ce6`/`0df2`, Bluetooth `0005:…`) nascem `0600
  root`, sem acesso da sessão; o hidraw do controle virtual é `0660`, com
  acesso da sessão (`assets/73-hefesto-ps5-controller.rules:76-92`).
- Os nós evdev físicos também viram `0600 root` quando o broker está instalado
  (`assets/72-…rules:171-172`). O broker ainda esconde o hidraw físico fora do
  modo Nativo (`S/daemon/subsystems/gamepad.py:284-326`).
- O Hefesto segura com exclusividade cada evdev de controle físico (o P1 e os
  do co-op) (`gamepad.py:16-19,258-281`; `coop.py:1141-1145`). O nó "Motion
  Sensors" só é segurado quando a pessoa desliga um sensor.
- A regra 75, opcional, desliga o áudio USB do controle inteiro
  (`assets/75-…rules`).

## C. O método de validação (para os testes guiados na tela)

1. **Confira primeiro onde está mirando.** `HID_PHYS=hefesto-vpad` é o
   controle virtual, e nunca é alvo de teste; VID, PID, barramento e caminho
   não provam nada. Confirme o transporte por `HID_ID` 0005 (Bluetooth) ou
   0003 (USB) (`docs/method/METODO-DE-ISOLAMENTO.md:29-141`).
2. **O instrumento não briga com o produto.** Ele se recusa a rodar, ou diz o
   estado do serviço (`:87-122`).
3. **Faça a linha de base, depois teste um suspeito por vez, com ele e sem
   ele.** "Um suspeito só é julgado quando existem ensaios **com** ele e
   **sem** ele" (`:175-204`).
4. **Prove primeiro que responde:** "tudo apagado contra tudo aceso"
   (`:278-280`).
5. **Meça em pares.** Um controle no cabo e um no rádio, na mesma janela de
   tempo. Inclua um controle negativo simultâneo — por exemplo, o L2 endurece
   enquanto o R2 fica solto (`:282-303`).
6. **Mire um controle e use os outros três como testemunhas.** Se nada
   acontece em lugar nenhum, suspeite da mira, não do produto
   (`:299-303,643-667`).
7. **Desenhe para a resposta ser sentida, não cronometrada.** Nada de
   cronômetro; amplitude cheia; "dois controles, um em cada mão"; anote a hora
   de começo e de fim (`:328-360`).
8. **Testes às cegas.** "Teste CEGO: ela não sabia o que foi enviado antes de
   relatar", com um pulso zero/zero como negativo
   (`docs/data/ensaios.csv:105-114`). O áudio usou gabaritos lacrados
   (`S/integrations/dualsense_bt_audio.py:2106-2113`).
9. **A escada da evidência:** `MONTOU → SAIU NO FIO → O APARELHO OBEDECEU → O
   JOGO RECEBEU → O JOGO REAGIU`. "Obedeceu" e "reagiu" só contam quando a
   pessoa viu ou sentiu. "Recebeu" quer dizer que o inode do controle virtual
   aparece entre os arquivos abertos do processo do jogo (`:935-1024`). É a
   ideia de "quatro controles na mão são o oráculo".
10. **O roteiro de quatro controles tem 21 linhas, cada uma com PASSA/REPROVA.**
    Montagem: 2 controles no cabo e 2 no rádio, e cada controle é uma condição
    à parte. Exemplos: só o P1 treme (linha 6), só o gatilho do P3 muda (linha
    7), o P4 é o negativo da rota do som (linha 11), só o alto-falante do P2
    toca (linha 19) (`docs/usage/roteiro-da-bancada-de-quatro.md:13-37`).
    Anote cada ensaio no mesmo dia; se precisou de um "porém", o resultado não
    é `obedece` (`METODO…:720-747`).
