# O DualSense: o catálogo

O que o controle sabe fazer, o que a Forja já faz com cada coisa, o que falta, por onde passa no Linux e de onde
veio cada ideia. No fim, as dez mágicas mais fortes para a Forja, em ordem.

Quem escreve: o pesquisador do DualSense ([papéis](../o-time/papeis.md)). Pesquisa de 08/10/2026. Lê junto: o
[05 A háptica e o controle](../05-haptica-e-controle.md), [Como o som chega ao controle](../../COMO-O-SOM-CHEGA-AO-CONTROLE.md)
e o [CONTRATO](../../../CONTRATO.md).

## As regras desta página

- **O contrato vale.** O jogo fala o relatório USB `0x02` e só. Nada aqui propõe o `0x31`, o CRC com `0xA2`, MAC,
  `uniq` ou o socket do Hefesto. O que precisa de emenda do contrato está marcado **emenda**.
- **Nenhum código de fora foi copiado.** Desta pesquisa saem fatos (o byte, o bit, a faixa), nunca trechos. Cada
  fato cita a fonte e a licença dela. Fato de protocolo não tem dono; o código que o implementa tem.
- **Código que pode entrar por inteiro**, se um dia for preciso: MIT, zlib e BSD, com o aviso no
  [LICENCAS-DE-TERCEIROS](../../../LICENCAS-DE-TERCEIROS.md). GPL e MPL: só leitura, porque o jogo é MIT.
- **A legenda do estado:** `usa` o jogo já usa · `módulo` o módulo tem e o jogo não usa · `falta` o módulo não tem ·
  `emenda` o contrato proíbe hoje · `fora` fica fora da Forja.

## O mapa em uma tabela

| recurso | estado | onde o módulo faz | o que falta |
| --- | --- | --- | --- |
| gatilho: os 4 modos (Off, Feedback, Weapon, Vibration) | `usa` | `gatilho()`, `forja_trigger_pack` | nada |
| gatilho: Slope, Multiple Position Feedback e Vibration | `emenda` | a mesma embalagem por zona já existe | a emenda e 3 casos no `forja_trigger_pack` |
| gatilho: o estado do efeito (a entrada) | `falta` | o relatório cru já é lido | ler os bytes 41 e 42 |
| gatilho: Bow, Galloping, Machine | `fora` | — | — |
| háptica por áudio (cabo) | `usa` | `som_haptica()`, canais 3 e 4 | a placa aberta na entrada do lugar (Sprint H) |
| rumble de compatibilidade | `usa` | `vibrar()` | a medição da suspeita (b) do 05 |
| atenuação dos motores e do gatilho | `falta` | o bit `FORJA_FX_MOTOR_POWER` existe, nunca é ligado | expor o byte 36 |
| alto-falante | `usa` | `som_falante()`, `alto_falante()` | nada |
| fone no controle (P2 de 3,5 mm) | `módulo` | `status_cru()` lê o bit, a rota `0` existe | uma sala que use |
| microfone | `usa` | `som_mic()` | expor o volume (`forja_fx_volume_mic` já existe em C) |
| botão e luz do mudo | `usa` | `BOTAO_MICROFONE`, `led_mic()` | nada |
| barra de luz | `usa` | `luz()`, `luz_do_lugar()` | o brilho e o apagar suave (byte 41) |
| LEDs de jogador | `usa` | `leds_jogador()`, `leds_do_lugar()` | o brilho (byte 42) |
| giroscópio e acelerômetro | `usa` | `giro()`, `acel()`, `postura()`, `giro_hz()` | nada |
| touchpad | `usa` | `dedo()`, `BOTAO_TOUCHPAD` | nada (não há pressão no aparelho) |
| bateria | `usa` | o dicionário do pad, lido a cada 2 s | nada |
| firmware | `usa` | `SDL_GetGamepadFirmwareVersion` no relatório | nada |
| carimbo de tempo do sensor | `usa` | `taxa.c` | nada |
| DualSense Edge (Fn, alavancas, trava do gatilho) | `falta` | o PID `0x0DF2` é reconhecido | os 4 botões e o aviso da trava |
| háptica e som pelo rádio | `fora` | — | é da ponte na frente do hidraw |

## Os recursos, um por um

### 1. Os gatilhos adaptativos

Um motor em cada gatilho empurra o dedo de volta. O curso tem 10 zonas (0 a 9). Cada efeito é um bloco de 11 bytes:
o modo no byte 0 e os parâmetros nos seguintes, com uma máscara de 10 bits das zonas ativas e 3 bits de força por
zona.

**Os modos que existem.** A lista da Sony aparece em público no cabeçalho `isteamdualsense.h` do Steamworks, o mesmo
que o CONTRATO cita. Ele tem **sete** modos, não quatro:

| modo (Sony) | byte HID | parâmetros | a sensação | no jogo hoje |
| --- | --- | --- | --- | --- |
| `OFF` | `0x05` | — | gatilho solto | `usa` |
| `FEEDBACK` | `0x21` | posição 0–9, força 0–8 | parede firme a partir de uma zona | `usa` (Arco) |
| `WEAPON` | `0x25` | início 2–7, fim início+1–8, força 0–8 | parede que quebra num clique | `usa` (Galeria) |
| `VIBRATION` | `0x26` | posição 0–9, amplitude 0–8, frequência 0–255 Hz | o gatilho treme sob o dedo | `usa` (Metralhadora) |
| `SLOPE_FEEDBACK` | `0x21` por zona | início, fim, força inicial 1–8, força final 1–8 | a parede cresce ao longo do curso | `emenda` |
| `MULTIPLE_POSITION_FEEDBACK` | `0x21` por zona | 10 forças, uma por zona | um relevo: dentes onde se quiser | `emenda` |
| `MULTIPLE_POSITION_VIBRATION` | `0x26` por zona | frequência e 10 amplitudes | o tremor muda conforme a profundidade | `emenda` |

Os três últimos usam os **mesmos bytes de modo** (`0x21` e `0x26`) com a força escrita zona a zona. A embalagem por
zona já existe em `src/forja_dualsense.c` (`pack_zones`). Falta só montar a máscara e as forças a partir de um vetor.

**Os que ficam fora.** `Bow` (`0x22`), `Galloping` (`0x23`) e `Machine` (`0x27`) são achados por engenharia reversa e
não estão na lista da Sony; o próprio autor do gerador de referência avisa que um firmware novo pode tirá-los. Os
modos simples `0x01`, `0x02`, `0x06` e os limitados `0x11`, `0x12` são restos de firmware, e `0xFC` a `0xFE` são de
calibração e corrompem o estado do gatilho até o próximo Off. O CONTRATO acerta ao recusar todos esses.

**O que o CONTRATO diz errado.** Ele chama `SlopeFeedback` de resto de firmware. O `isteamdualsense.h` que ele mesmo
cita lista `SCE_PAD_TRIGGER_EFFECT_MODE_SLOPE_FEEDBACK`, `..._MULTIPLE_POSITION_FEEDBACK` e
`..._MULTIPLE_POSITION_VIBRATION` como modos da Sony, com as faixas acima. A emulação AnyPS5 aceita modos de 0 a 6 na
`scePadSetTriggerEffect`, o que bate com sete modos. A emenda pedida está em [O que fica em aberto](#o-que-fica-em-aberto-e-de-quem).

**O estado do efeito (a entrada).** O controle conta, a cada relatório de entrada, em que fase o efeito está. No
relatório USB `0x01`, contando depois do id: byte 41 é o R2, byte 42 é o L2. O nibble baixo é a fase (no Weapon: 0
antes da parede, 1 dentro, 2 depois do clique) e o bit `0x10` diz que o efeito está ativo. O SDL não expõe isso; o
módulo já lê o relatório cru inteiro (`pads.c`, `p->cru`), então ler a fase é um byte a mais.

**A trava do Edge.** O DualSense Edge tem uma trava física que encurta o curso do L2 e do R2. Com ela, o fundo do curso
não chega. Todo minigame que pede profundidade (O Fole, a Espada de Fita) tem que calibrar o fundo pelo maior valor
que o jogador alcança no cartão, e nunca exigir 100 %.

| | |
| --- | --- |
| **o módulo hoje** | os 4 modos (`gatilho(lugar, lado, modo, a, b, c)`), a sombra que nunca cala o motor, as opções que reduzem à metade (`Opcoes.ajustar_gatilho`) |
| **o jogo usa** | a Galeria, a Prova, a Bancada e o diagnóstico; nos 45: S5 inteira (21 a 25), o Fole (4), o Roubo de Bateria (42) |
| **falta** | a fase do efeito (bytes 41 e 42), os 3 modos por zona (**emenda**), a calibração do fundo do curso |
| **pelo Linux** | só pelo relatório de saída no hidraw (pelo SDL: `SDL_SendGamepadEffect`). O `hid-playstation` não tem interface para gatilho |
| **como se prova** | às cegas, como a Galeria já faz: o jogo sorteia o modo, a tela não mostra, quem joga diz o que sentiu |
| **fontes** | Steamworks `isteamdualsense.h` (cópia pública em `ValveSoftware/Proton`, `lsteamclient/steamworks_sdk_165/`); o gerador de efeitos de John «Nielk1» Klein (gist `6d54cc2c00d2201ccb8c2720ad7538db`, revisão 6); o explorador `nondebug/dualsense` (bytes 41 e 42); `boykopovar/AnyPS5`, `core/libs/prx/libScePad/Export.cpp`; a página de suporte da Sony sobre a trava do Edge |
| **licença da referência** | Nielk1: MIT (pode entrar com o aviso). Steamworks: licença da Valve, só leitura. AnyPS5: GPL-2.0, só leitura. nondebug: sem licença declarada, só leitura |

**A mágica.** Quem joga: a arma que montou tem um gatilho só dela (a mágica 1). Os outros: veem a arma acender na
tela no mesmo quadro em que o dedo passa a parede, e ouvem o clique no alto-falante do dono.

### 2. A háptica por áudio

Os dois atuadores (bobinas, como um alto-falante sem cone) tocam uma onda. No cabo, o controle é uma placa USB Audio
de 4 canais a 48 kHz; os canais 3 e 4 são os atuadores esquerdo e direito. A onda grave (60 a 180 Hz) vira textura na
mão.

| | |
| --- | --- |
| **o módulo hoje** | `som_haptica(lugar, esq, dir, ganho)`, sons pelo nome, a mixagem por controle (`som_controle.c`), a placa virtual do simulador, a busca do aparelho pelo mesmo USB (`achar_som.c`) |
| **o jogo usa** | Os Caminhos, a Prova, a sala de jogo e a Bancada; nos 45: S7 inteira (31 a 35), o Cerco (16), Martelos Térmicos (19) |
| **falta** | abrir a placa na entrada do lugar e não só nas salas de som (Sprint H do 05); a tabela de material do 05 (`sintese.c`) |
| **pelo Linux** | ALSA ou PipeWire (`snd-usb-audio`): um nó de saída de 4 canais; o `pactl` dá o `sysfs.path` e dele o mesmo `usb_device` do hidraw |
| **o cuidado** | o SDL desliga a háptica por áudio enquanto há rumble; os dois no mesmo instante se anulam (suspeita (e) do 05). A AnyPS5, ao rotear a háptica dos jogos de PS5 pelo driver `pulseaudio` do SDL, abre 6 canais e escreve a háptica nas posições 4 e 5: a ordem dos canais depende do driver de som, e o módulo precisa conferir o mapa de canais, não assumir 3 e 4 |
| **como se prova** | Os Caminhos já prova: lados trocados, um lado mudo, textura deformada |
| **fontes** | `ValveSoftware/Proton#5900`; o SDL (`SDL_hidapi_ps5.c`, a háptica cortada sob rumble); `boykopovar/AnyPS5`, `core/libs/prx/libSceAudioOut/src/AudioOut2PadMix.cpp` (portas `PAD_SPEAKER` 0x3 e `PAD_VIBRATION` 0x6); análises de Astro's Playroom (os pés de metal do Astro batem alternando esquerda e direita) e de Ghost of Tsushima Director's Cut (a chuva no chão sob os pés) |
| **licença da referência** | SDL: zlib (pode entrar). AnyPS5: GPL-2.0, só leitura |

**A mágica.** Quem joga: sente o chão e o ritmo antes de ver (as mágicas 3, 6 e 9). Os outros: nada, e é esse o
ponto; a háptica é a informação que só o dono tem, e a mesa inteira olha para a cara dele.

### 3. O rumble de compatibilidade

O pedido de dois motores (forte e fraco) do mundo do DualShock. O firmware imita os motores nos mesmos atuadores.

| | |
| --- | --- |
| **o módulo hoje** | `vibrar(lugar, forte, fraco, ms)` por `SDL_RumbleGamepad`, a escala do lugar, a sombra que nunca manda o bit `RUMBLE` por conta própria |
| **o jogo usa** | quase toda sala (`main`, `centelha`, `impacto`, `viga`, `voz`, `molde`, `prova`, a sala de jogo, as opções) |
| **falta** | medir as suspeitas (b) e (c) do 05: firmware abaixo de `0x0224` divide o motor por 2 no SDL; o kernel usa outro limiar (2.21) |
| **pelo Linux** | pelo SDL no hidraw. O kernel também oferece `FF_RUMBLE` no evdev, e é por isso que o Godot nunca pode vibrar (suspeita (d) do 05) |
| **como se prova** | a ficha F05 (o háptico forte) e a sala do Impacto |
| **fontes** | SDL `SDL_hidapi_ps5.c` (o limiar `0x0224`, o deslocamento de 1 bit); Linux `drivers/hid/hid-playstation.c` (`DS_FEATURE_VERSION(2, 21)`) |
| **licença da referência** | SDL: zlib. Linux: GPL-2.0-or-later, só leitura |

**A mágica.** É o caminho do rádio. Toda mágica de háptica tem um plano B em rumble, mais grosso e jogável.

### 4. O alto-falante

Um alto-falante pequeno na frente do controle. No cabo, recebe o canal 2 da placa quando a rota (byte 7, bits 4–5)
é `3`. Volume no byte 5 (0x00–0xFF; o kernel usa `0x64`) e pré-amplificador no byte 37 (bits 0–2; o kernel usa `2`).

| | |
| --- | --- |
| **o módulo hoje** | `som_falante(lugar, som, ganho)`, `alto_falante(lugar, volume, rota, preamp)`, o `forja-speak --player N`, a busca do nó pelo aparelho, pelo número e pelo nome |
| **o jogo usa** | O Canto, A Voz, a Prova, a sala de jogo, a Bancada; nos 45: S6 inteira (26 a 30), o Roubo de Bateria (42) |
| **falta** | a agenda do 05 (o pio na entrada, o clique de navegação, o perfeito e o erro) fora das salas de som |
| **pelo Linux** | a mesma placa USB Audio; o byte 7 e o byte 5 pelo relatório `0x02` |
| **como se prova** | O Canto: «saiu da SUA mão?», às cegas |
| **fontes** | `hid-playstation.c` (volume e pré-amp quando o fone sai); Death Stranding (o BB chora no alto-falante do controle, desde o PS4); Ghostwire: Tokyo (vozes do outro mundo saem do controle, no blog da PlayStation de maio de 2021); Astro Bot (boa parte dos sons sai do controle, nas análises) |
| **licença da referência** | Linux: GPL-2.0-or-later, só leitura |

**A mágica.** Quem joga: ouve a própria nota (Dó, Mi, Sol ou Si) sair da mão. Os outros: ouvem que saiu da mão
dele, mas não o quê (a mágica 2).

### 5. O fone no controle

O controle tem uma entrada de 3,5 mm. No relatório de entrada, o byte 53 diz: bit 0 fone ligado, bit 1 microfone do
fone, bit 2 mudo. No relatório de saída, a rota `0` manda o estéreo para o fone, o volume do fone fica no byte 4
(0x00–0x7F), e o kernel cala o alto-falante quando o fone entra.

| | |
| --- | --- |
| **o módulo hoje** | `status_cru(lugar)` com `CRU_FONE`, `CRU_MIC_DO_FONE` e `CRU_MUDO`; a rota `FORJA_ROTA_FONE`; nenhuma sala usa |
| **o jogo usa** | nada |
| **falta** | um fio no jogo: com o fone ligado, o som do dono vai para o fone (rota `0`, volume do fone `0x50`) e o jogo avisa no cartão do jogador |
| **pelo Linux** | o kernel cria o dispositivo «Headset Jack» com `SW_HEADPHONE_INSERT` e `SW_MICROPHONE_INSERT` (só no cabo); o módulo lê o mesmo bit do relatório cru |
| **como se prova** | numa sala de som, plugar e tirar o fone: o bit muda, o som troca de saída, o veredito anota |
| **fontes** | `hid-playstation.c` (o «Headset Jack»); `nondebug/dualsense` (byte 53); `nowrep/dualsensectl` (o comando `speaker internal|headphone|both`) |
| **licença da referência** | Linux e dualsensectl: GPL-2.0, só leitura |

**A mágica.** Quem tem um fone no controle ganha o segredo de verdade, sem vazar nada para a sala (a mágica 2).

### 6. O microfone

Dois microfones na frente do controle. Chegam pela mesma placa USB, como entrada. O byte 6 é o volume (0x00–0x40). O
byte 7 tem, nos bits 0–3, microfone interno, microfone do fone, cancelamento de eco e de ruído (a base do módulo é
`0x0D`), e nos bits 6–7 o caminho da entrada (o `dualsensectl` chama de `chat`, `asr` e `both`).

| | |
| --- | --- |
| **o módulo hoje** | `som_mic(lugar)`, a escuta crua da bancada, a base `0x0D`; o volume existe em C (`forja_fx_volume_mic`) mas não chega ao GDScript |
| **o jogo usa** | A Voz e a Bancada; nos 45: S8 inteira (36 a 40) |
| **falta** | expor o volume; a regra da Sony: enquanto o microfone interno escuta, a vibração e o gatilho que treme ficam mais fracos (a API da Sony tem uma função só para isso, `scePadSetVibrationTriggerEffectWeakWhileEmbeddedMicInUse`; o motor faz barulho que o microfone pega) |
| **pelo Linux** | ALSA ou PipeWire, o nó de entrada do mesmo `usb_device` |
| **como se prova** | A Voz: o piso de silêncio, a voz de cada um, a voz baixa já mudo |
| **fontes** | `dualsensectl` (`microphone-mode`, `microphone-volume`); `boykopovar/AnyPS5` (a lista de funções da `libScePad`); Astro's Playroom (soprar no microfone gira o cata-vento que move a plataforma) |
| **licença da referência** | dualsensectl e AnyPS5: GPL-2.0, só leitura |

**A mágica.** Quem joga: o sopro é um botão que todo mundo entende sem tutorial. Os outros: o grupo inteiro precisa se
calar quando o guardião escuta (a mágica 10).

### 7. O botão e a luz do mudo

Um botão abaixo do PS e uma luz laranja nele. A luz é o byte 8: `0` apagada, `1` acesa, `2` piscando.

| | |
| --- | --- |
| **o módulo hoje** | `BOTAO_MICROFONE` (o `MISC1` do SDL), `led_mic(lugar, modo)` |
| **o jogo usa** | A Voz (a luz perguntada às cegas); nos 45: Zero Absoluto (38), o escudo de três cargas |
| **falta** | nada no módulo. No jogo: o kernel alterna o mudo sozinho a cada aperto e acende a luz por conta dele; o jogo pede a luz depois do kernel, no quadro seguinte |
| **pelo Linux** | o `hid-playstation` trata o botão (alterna, acende a luz, cala o microfone pelo `power_save_control`); o jogo só manda o byte 8 |
| **como se prova** | A Voz: o botão chegou? o som caiu? a luz é a que o jogo mandou? |
| **fontes** | `hid-playstation.c`; SDL (`SDL_GAMEPAD_BUTTON_PS5_MICROPHONE`) |
| **licença da referência** | Linux: GPL-2.0-or-later. SDL: zlib |

**A mágica.** A luz do mudo vira um contador de três cargas que todo mundo vê na mão do outro (a mágica 10).

### 8. A barra de luz

O LED RGB em volta do touchpad. Cor nos bytes 44–46. O byte 41 acende (`0x01`) ou apaga suave (`0x02`) a barra.

| | |
| --- | --- |
| **o módulo hoje** | `luz(lugar, cor)`, `luz_do_lugar(lugar)` pelo `SDL_SetGamepadLED`; as quatro cores do lugar |
| **o jogo usa** | a Prova, o Impacto, A Voz, a sala de jogo; a regra do 05: a cor do lugar sempre, o perfeito pisca branco e volta |
| **falta** | o apagar suave (byte 41) para o fim da noite |
| **pelo Linux** | pelo SDL no hidraw; o kernel também publica `/sys/class/leds/<hid>:rgb:indicator` (`multi_intensity`, `brightness`) |
| **como se prova** | a Carga da Prova já pergunta a cor às cegas |
| **fontes** | SDL `SDL_hidapi_ps5.c`; `hid-playstation.c`; `dualsensectl` (`lightbar on|off`, `lightbar R G B [brilho]`) |
| **licença da referência** | SDL: zlib. Linux e dualsensectl: GPL-2.0, só leitura |

**A mágica.** A sala escura acende pelas mãos: o mundo da Forja é escuro e os cavaleiros são as luzes (a
[alma](../arte/README.md)). A barra respira na batida entre 60 % e 100 % da cor do lugar, sem nunca trocar de cor (a
mágica 4). No fim da fita, as quatro apagam suave juntas no último acorde.

### 9. Os LEDs de jogador

Cinco lâmpadas brancas abaixo do touchpad. Byte 43: bits 0–4 as lâmpadas, `0x20` troca sem esmaecer. Byte 42: o
brilho das lâmpadas e da luz do mudo (`0` alto, `1` médio, `2` baixo).

| | |
| --- | --- |
| **o módulo hoje** | `leds_jogador(lugar, máscara)`, `leds_do_lugar(lugar)`; P1 `0x04`, P2 `0x0A`, P3 `0x15`, P4 `0x1B` |
| **o jogo usa** | o cartão do jogador, o mapa do controle, a Galeria, a Prova; a regra do 05: nunca munição, nunca pergunta |
| **falta** | o brilho (byte 42, validade no byte 38 bit 0); é o ajuste natural para a sala escura |
| **pelo Linux** | pelo SDL no hidraw; o kernel publica `/sys/class/leds/<hid>:white:player-1` a `-5` |
| **como se prova** | a Galeria já confere as lâmpadas às cegas |
| **fontes** | `hid-playstation.c` (`LED_FUNCTION_PLAYER1` a `5`); SDL (`SDL_HINT_JOYSTICK_HIDAPI_PS5_PLAYER_LED`); `dualsensectl` (`player-leds`, `led-brightness`) |
| **licença da referência** | Linux e dualsensectl: GPL-2.0. SDL: zlib |

**A mágica.** A identidade é sagrada: as lâmpadas não entram em mágica nenhuma além de dizer quem é quem (a mágica 1
as acende no fim da entrada).

### 10. O giroscópio e o acelerômetro

Seis eixos. O SDL declara 250 Hz no cabo para o DualSense e 1000 Hz no rádio e no Edge. O carimbo do sensor conta em
unidades de 0,33 µs.

| | |
| --- | --- |
| **o módulo hoje** | `giro()`, `acel()`, `postura()` (a fusão própria), `giro_hz()` (a taxa medida, não a declarada), o robô que gira e sacode |
| **o jogo usa** | a Viga, a Prova, o diagnóstico; nos 45: S2 inteira (6 a 10) |
| **falta** | nada no módulo. A API da Sony tem correção de inclinação, zona morta da velocidade angular e «zerar a orientação» (`scePadSetTiltCorrectionState`, `scePadSetAngularVelocityDeadbandState`, `scePadResetOrientation`); a `postura()` deve oferecer o «zerar» por gesto, no cartão |
| **pelo Linux** | pelo SDL (`SDL_GetGamepadSensorData`); o kernel cria o dispositivo «Motion Sensors» no evdev |
| **como se prova** | a Viga e a taxa medida no relatório |
| **fontes** | SDL `SDL_hidapi_ps5.c` (as taxas, o carimbo); `hid-playstation.c` (o carimbo ÷ 3); `boykopovar/AnyPS5` (a lista de funções); Astro's Playroom (o traje de mola mira o pulo inclinando o controle) |
| **licença da referência** | SDL: zlib. Linux e AnyPS5: GPL-2.0, só leitura |

**A mágica.** O brinde: os quatro erguem o controle juntos no fim da noite (a mágica 8). Quem joga sente a bolinha
rolar dentro do controle quando inclina (a mágica 6).

### 11. O touchpad

Dois dedos ao mesmo tempo, X de 0 a 1919 e Y de 0 a 1069, normalizados de 0 a 1 pelo SDL. Clique como botão. **Não
há pressão**: o SDL manda 1,0 com o dedo e 0,0 sem.

| | |
| --- | --- |
| **o módulo hoje** | `dedo(lugar, i)` para 2 dedos, `BOTAO_TOUCHPAD`, o robô que toca |
| **o jogo usa** | o Molde, o mapa do controle, o diagnóstico; nos 45: S3 inteira (11 a 15) |
| **falta** | nada; nenhuma mecânica pode pedir força do dedo |
| **pelo Linux** | pelo SDL; o kernel cria o dispositivo «Touchpad» com 2 dedos e `INPUT_PROP_BUTTONPAD` |
| **fontes** | SDL `SDL_hidapi_ps5.c` (as escalas, a pressão fixa); Astro's Playroom (deslizar no touchpad rola a bola e fecha o zíper do traje) |
| **licença da referência** | SDL: zlib |

**A mágica.** O quadrante do touchpad é a nota do jogador (Hackeando o Terminal, 13). Fica com o diretor de jogo.

### 12. A bateria

O byte 52 do relatório: nibble baixo o nível (0 a 10), nibble alto o estado (descarregando, carregando, cheio). O SDL
devolve `nível × 10 + 5` %, em degraus de 10.

| | |
| --- | --- |
| **o módulo hoje** | `bateria` no dicionário do pad, lida a cada 2 s; o estado de energia e de conexão |
| **o jogo usa** | a HUD, o cartão do jogador, o desenho do controle |
| **falta** | nada. A noite tem 6 horas (o [08](../08-a-noite-de-6-horas.md)); a bateria em 15 % no virar da fita vira aviso no cartão, nunca na partida |
| **pelo Linux** | pelo SDL (`SDL_GetGamepadPowerInfo`); o kernel publica um `power_supply` cujo nome traz o MAC, e por isso o jogo não o lê |
| **fontes** | SDL `SDL_hidapi_ps5.c`; `hid-playstation.c` |
| **licença da referência** | SDL: zlib. Linux: GPL-2.0-or-later |

**A mágica.** Nenhuma. A bateria é cuidado, não jogo.

### 13. A atenuação dos motores e do gatilho

O byte 36 do bloco de saída: bits 0–2 reduzem o rumble e a háptica (0 a 7), bits 4–6 reduzem o gatilho que treme (0 a
7). Validade: byte 1, bit 6 (`FORJA_FX_MOTOR_POWER`, já definido no cabeçalho e nunca ligado). O byte 1, bit 5, liga
um filtro passa-baixa da háptica, sem efeito documentado.

| | |
| --- | --- |
| **o módulo hoje** | o nome do bit existe; a sombra não guarda o byte 36 |
| **o jogo usa** | nada; as opções multiplicam os valores no GDScript |
| **falta** | guardar o byte 36 na sombra e expô-lo como opção de acessibilidade por lugar: a mão sensível pede menos sem que a sala mude os valores dos eventos |
| **pelo Linux** | pelo relatório `0x02` (pelo SDL: `SDL_SendGamepadEffect`) |
| **fontes** | `nowrep/dualsensectl`, `main.c` (`attenuation RUMBLE TRIGGER`, campo `reduce_motor_power`) |
| **licença da referência** | GPL-2.0, só leitura (o fato do byte entra, o código não) |

**A mágica.** Nenhuma; é acessibilidade (a régua do [10](../10-a-regua-astro-bot.md) e a bíblia de arte).

### 14. O firmware e o carimbo de tempo

O relatório de recurso `0x20` dá a versão do firmware; `0x05` dá a calibração dos sensores; `0x09` o pareamento. O
relatório de entrada traz um contador, uma sequência de 32 bits e o carimbo do sensor.

| | |
| --- | --- |
| **o módulo hoje** | o firmware no relatório da sessão; a taxa medida pelo relógio do sensor (`taxa.c`) |
| **o jogo usa** | o relatório e a noite de 6 horas |
| **falta** | usar o carimbo do sensor para julgar o tempo de um aperto com a resolução do relatório (4 ms a 250 Hz) e não do quadro (16,7 ms) |
| **fontes** | `hid-playstation.c` (os ids `0x05`, `0x09`, `0x20`); SDL (a escolha do rumble pelo firmware) |
| **licença da referência** | Linux: GPL-2.0-or-later. SDL: zlib |

**A mágica.** O julgamento justo: um jogo de ritmo que julga em 4 ms não briga com quem acertou.

### 15. O DualSense Edge

PID `0x0DF2`. Dois botões Fn, duas alavancas traseiras, a trava de curso dos gatilhos, sticks trocáveis, sensores a
1000 Hz no cabo.

| | |
| --- | --- |
| **o módulo hoje** | o PID reconhecido (`FORJA_DS5_EDGE_PID`) |
| **o jogo usa** | nada |
| **falta** | ler os 4 botões a mais (o SDL 3.4.14 os entrega como `SDL_GAMEPAD_BUTTON_PS5_LEFT_FUNCTION`, `..._RIGHT_FUNCTION`, `..._LEFT_PADDLE`, `..._RIGHT_PADDLE`) e nunca exigir o fundo do gatilho (a trava) |
| **pelo Linux** | pelo SDL; o kernel mapeia em `BTN_TRIGGER_HAPPY1` a `4` |
| **fontes** | SDL 3.4.14 (`SDL_hidapi_ps5.c`, linhas 1333–1336 da cópia em `.cache/src/`); `hid-playstation.c`; suporte da PlayStation, «How to personalize your DualSense Edge» |
| **licença da referência** | SDL: zlib. Linux: GPL-2.0-or-later |

**A mágica.** Nenhuma nova; as alavancas podem repetir L1 e R1 para quem joga com dor na mão.

### 16. O rádio (Bluetooth)

Pelo rádio, o DualSense não tem placa de som. A háptica por áudio passa dentro do HID, num relatório próprio: o
projeto SAxense escreve PCM de 8 bits, estéreo, a 3000 Hz, um relatório a cada 10,67 ms, direto no hidraw. O
microfone chega dentro do `0x31`.

| | |
| --- | --- |
| **o jogo** | não fala nada disso (o CONTRATO). Quem traduz é a ponte na frente do hidraw |
| **o que esta pesquisa entrega à ponte** | a fonte pública da háptica pelo rádio (SAxense) e a da apresentação do controle do rádio como cabo (OpenDS5) |
| **fontes** | `egormanga/SAxense` («DualSense Haptics over Bluetooth (POC)»); a análise de viabilidade do projeto Dr.QP; `LordVicky/OpenDS5` |
| **licença da referência** | SAxense: MPL-2.0, só leitura. OpenDS5: sem licença declarada, só leitura |

## As fontes de fora

| fonte | o que ensina | licença | o código pode entrar? |
| --- | --- | --- | --- |
| [SDL, `SDL_hidapi_ps5.c`](https://github.com/libsdl-org/SDL/blob/main/src/joystick/hidapi/SDL_hidapi_ps5.c) | o bloco de 47 bytes, o rumble por firmware, as taxas, o touchpad, a bateria, o Edge | zlib | sim (já entra: é o SDL do jogo) |
| [Linux, `hid-playstation.c`](https://github.com/torvalds/linux/blob/master/drivers/hid/hid-playstation.c) | os relatórios, o mudo, o fone, os LEDs no sysfs, o limiar 2.21 | GPL-2.0-or-later | não |
| [Steamworks, `isteamdualsense.h`](https://github.com/ValveSoftware/Proton/blob/proton_9.0/lsteamclient/steamworks_sdk_165/isteamdualsense.h) | os sete modos da Sony e as faixas | licença do Steamworks SDK | não; os nomes e faixas são o que a Steam publica |
| [Nielk1, gerador de efeitos (rev. 6)](https://gist.github.com/Nielk1/6d54cc2c00d2201ccb8c2720ad7538db) | a embalagem por zona, oficiais × achados, a fase do efeito | MIT | sim, com o aviso |
| [nowrep/dualsensectl](https://github.com/nowrep/dualsensectl) | o bloco de saída inteiro com nomes: atenuação, brilho, modos do microfone, rota | GPL-2.0 | não |
| [nondebug/dualsense](https://github.com/nondebug/dualsense) | o explorador WebHID: bytes 41 e 42 (gatilhos), 52 e 53 (bateria, fone) | sem licença | não |
| [boykopovar/AnyPS5](https://github.com/boykopovar/AnyPS5) | a `libScePad` refeita: as funções que os jogos de PS5 chamam; as portas de áudio do controle | GPL-2.0 | não |
| [InoriRus/Kyty](https://github.com/InoriRus/Kyty) | emulador de PS4 e PS5: a `LibPad` só tem leitura, vibração e barra de luz; nada de gatilho nem de áudio no controle | MIT | sim, mas não há o que tirar |
| [KytyPS5](https://github.com/KytyPS5/KytyPS5) | o derivado do Kyty para PS5 | GPL-2.0 | não |
| [flok/pydualsense](https://github.com/flok/pydualsense) | gatilho, barra de luz e botões em Python, pelo hidapi | MIT | sim, mas o módulo já cobre |
| [daidr/dualsense-tester](https://github.com/daidr/dualsense-tester) | o testador no navegador, DualSense e Edge | MIT | sim |
| [radu781/dualsense-rs](https://github.com/radu781/dualsense-rs) | o mesmo protocolo em Rust | MIT | sim |
| [Paliverse/DualSenseX](https://github.com/Paliverse/DualSenseX) | a origem do DSX (hoje pago na Steam); usa o gerador do Nielk1 | sem licença; o código-fonte não está no repositório | não (e o UDP do DSX é proibido no CONTRATO) |
| [egormanga/SAxense](https://github.com/egormanga/SAxense) | a háptica pelo rádio | MPL-2.0 | não |
| [LordVicky/OpenDS5](https://github.com/LordVicky/OpenDS5) | o rádio apresentado como cabo; o laboratório de gatilho com os 7 modos | sem licença | não |
| [ValveSoftware/Proton#5900](https://github.com/ValveSoftware/Proton/issues/5900) | como os jogos acham o áudio do controle | — | — |

## O que os jogos de PS5 ensinam

| jogo | a técnica | a fonte | como vira Forja |
| --- | --- | --- | --- |
| Astro's Playroom (Team Asobi, 2020) | a textura do chão nos dois lados; a mola no gatilho; a pegada do macaco que solta com força demais; soprar no microfone; inclinar para mirar | blog da PlayStation, análises da GameSpot | Os Caminhos; o Fole; a Voz |
| Astro Bot (Team Asobi, 2024) | o robô resgatado pula para dentro do controle e se sente o peso dele | análise da Checkpoint Gaming | a mágica 1 (o cavaleiro entra no controle) |
| Returnal (Housemarque, 2021) | o L2 em dois estágios: meio curso mira, curso inteiro troca o tiro; a chuva sentida | análises (GamingTrend, Game World Observer) | o Weapon com a fase lida: meio curso e curso inteiro são dois verbos |
| Ratchet & Clank: Rift Apart (Insomniac, 2021) | cada arma tem o seu gatilho; meio curso um tiro, curso inteiro o tiro forte | blog da PlayStation; tópicos da Steam (o meio curso quebra com o Steam Input) | a mágica 1; o risco do Steam Input |
| Deathloop (Arkane, 2021) | a arma emperra e o gatilho trava no meio antes da animação; o soco que desemperra se sente | blog da PlayStation, novembro de 2020 | a mágica 5 (o gatilho que trava) |
| Gran Turismo 7 (Polyphony, 2022) | o ABS como pulsação no gatilho do freio; a roda trava e a resistência some; a zebra num lado só | editorial da PlayStation; GTPlanet | o gatilho que pulsa no tempo da música |
| Ghost of Tsushima Director's Cut (Sucker Punch, 2021) | o vento-guia na háptica, de uma ponta à outra, apontando o caminho | GamingBolt (entrevista), Can I Play That | a mágica 9 (o vento que aponta) |
| Ghostwire: Tokyo (Tango, 2022) | cada elemento com um gatilho que se reconhece de olhos fechados; o gatilho fica mais forte quando o poder cresce | blog da PlayStation, maio de 2021; análise da NextRift | a mágica 1 (os stats no gatilho) |
| Death Stranding (Kojima Productions) | o bebê no alto-falante do controle | Destructoid; editorial da PlayStation do Director's Cut | o pio do cavaleiro |
| Hi-Fi Rush, versão de PS5 (Tango, 2024) | as batidas da música na háptica | análise da TechRadar | a mágica 3 (o metrônomo na mão) |
| 1-2-Switch (Nintendo, 2017) | Ball Count: contar bolinhas pela vibração ao inclinar; Safe Crack: girar até sentir o clique | página da Nintendo; análise da Vooks | a mágica 6 (contar pelo tato) |

## As dez mágicas mais fortes para a Forja

Ordem: o quanto a mágica serve à [alma](../arte/README.md) e à fala dela (o cavaleiro montado, a sensação de dono),
quantas vezes aparece na noite, e quanto custa hoje. Cada uma diz o que quem joga sente, o que os outros veem, o
recurso, os números, onde entra, o que falta e de onde veio.

### 1. A arma que você montou mora no gatilho

- **Quem joga:** cada arma ou amuleto do cavaleiro tem um perfil de gatilho próprio. Trocar a peça na tela de montagem
  troca o gatilho na mesma batida. A build se sente antes de se ver.
- **Os outros:** a arma acende na tela no quadro em que o dedo passa a parede, e o clique sai do alto-falante do dono.
- **Os números (proposta para o designer de sistemas):** martelo `WEAPON` 3→6, força 7; arco `FEEDBACK` zona 2, força
  4; lança `VIBRATION` zona 5, amplitude 3, 40 Hz; amuleto `FEEDBACK` zona 0, força 1. O stat de força soma 1 de
  força a cada 2 pontos, até 8. O stat de precisão abre a janela do Weapon de 1 a 3 zonas.
- **Onde:** a montagem do cavaleiro; S5 (21 a 25); a Prova (41) e o Roubo de Bateria (42).
- **O que falta:** só o dado (a tabela de perfis, do designer de sistemas). Os quatro modos já bastam.
- **Fontes:** Ratchet & Clank (cada arma, um gatilho); Ghostwire: Tokyo (o gatilho cresce com o poder); o gerador do
  Nielk1 (as faixas).

### 2. O segredo no ouvido

- **Quem joga:** um som que só ele ouve: o bipe da bomba, o degrau do eco, a senha do dragão. Com fone no controle, o
  som vai para o fone e nem o vizinho escuta.
- **Os outros:** veem a etiqueta do dono «falar» (a onda na cor dele) e não sabem o quê. Nasce o blefe.
- **Os números:** o alto-falante a `0x64` e pré-amp `2`; com o fone, rota `0` e volume do fone `0x50`; um som por vez
  por controle (o 05).
- **Onde:** S6 (26 a 30), Corta-Fio (30) com o bipe falso, o Roubo de Bateria (42).
- **O que falta:** ligar o bit do fone (byte 53) à rota.
- **Fontes:** Death Stranding e Ghostwire: Tokyo (a voz que sai do controle); o `hid-playstation` (o fone cala o
  alto-falante).

### 3. O metrônomo na mão

- **Quem joga:** a batida da faixa como um pulso grave nos atuadores: 80 Hz por 30 ms em cada tempo, 120 Hz por 50 ms
  no tempo 1, ganho 0,35. Na hora da vez dele, o pulso dobra.
- **Os outros:** nos minigames de chamada e resposta, os quatro controles pulsam em roda; cada um sabe que é a vez dele
  sem olhar a tela.
- **Onde:** todo minigame de ritmo; o Coral dos Quatro (28); o Último Acorde (45).
- **O que falta:** a placa aberta na entrada do lugar (Sprint H). No rádio, o rumble fraco a 0,3 por 40 ms.
- **Fontes:** Hi-Fi Rush, versão de PS5; a régua da bíblia «tudo cai na batida».

### 4. O cavaleiro entra no controle

- **Quem joga:** ao apertar o botão Cruz no lobby, o cavaleiro salta para dentro do controle. 0 a 200 ms: um baque de 90 Hz no
  atuador esquerdo; 200 a 400 ms: no direito; 400 ms: o pio do cavaleiro no alto-falante; a barra de luz sobe do preto
  à cor do lugar em 600 ms; as lâmpadas P# acendem de uma vez em 600 ms.
- **Os outros:** veem na TV o cavaleiro mergulhar na direção daquela mão e a luz acender nela. Ninguém pergunta qual
  controle é o de quem.
- **Onde:** o lobby, toda vez que alguém entra ou volta (o 05: quem caiu reencontra o lugar).
- **O que falta:** a sequência no lobby. Tudo existe no módulo.
- **Fontes:** Astro Bot (o robô que pula para dentro do controle); a agenda do alto-falante do 05.

### 5. O gatilho que trava

- **Quem joga:** a arma superaquecida trava o R2 no meio do curso por um compasso (`FEEDBACK` zona 4, força 8) e
  solta no tempo 1 seguinte. O tiro só conta no clique de verdade: a fase do Weapon (byte 41) passa de 1 para 2 e o
  jogo julga esse instante, não o eixo.
- **Os outros:** veem a arma fumegar e o dono apertar em vão. O humor mora no corpo.
- **Onde:** a Metralhadora de Feitiços (23), a Galeria (21), a Catapulta (25).
- **O que falta:** ler a fase do efeito (bytes 41 e 42 do relatório cru).
- **Fontes:** Deathloop (o gatilho bloqueado no meio quando a arma emperra); Returnal (os dois estágios); o
  explorador `nondebug/dualsense` (os bytes).

### 6. Contar pelo tato

- **Quem joga:** uma caixa com 3 a 9 bolinhas dentro do controle. Inclinar devagar faz cada bolinha bater na parede:
  um clique de 150 Hz por 12 ms no lado onde bateu. Quem conta certo leva.
- **Os outros:** todo mundo inclina o controle em silêncio, de olho na cara dos outros; a TV só revela no fim.
- **Onde:** uma faixa nova para S7, ou o desempate de Os Caminhos. Proposta para o diretor de jogo.
- **O que falta:** nada no módulo (`postura()` mais `som_haptica()`).
- **Fontes:** 1-2-Switch, Ball Count (Nintendo).

### 7. O degrau da nota

- **Quem joga:** no Fole, cada nota tem um dente no curso do gatilho: Dó na zona 2, Mi na 4, Sol na 6, Si na 8. O dente
  do dono tem força 6; o resto do curso, força 1. Achar a nota é achar o dente.
- **Os outros:** ouvem o acorde fechar quando os quatro estão no dente certo.
- **Onde:** o Fole (4), a Espada de Fita (24), o Último Acorde (45).
- **O que falta:** a **emenda** do contrato (`MULTIPLE_POSITION_FEEDBACK`). Sem ela, um `FEEDBACK` que começa na zona
  da nota dá meia mágica: a parede no lugar da nota.
- **Fontes:** `isteamdualsense.h`; o gerador do Nielk1; Astro's Playroom (a força certa da pegada do macaco).

### 8. O brinde

- **Quem joga:** no pódio, o jogo pede o brinde. Quando os quatro erguem o controle (aceleração acima de 1,8 g) numa
  janela de 400 ms, a fita solta o confete e os quatro controles batem juntos: 1,0 por 120 ms, pausa de 120 ms, 0,7
  por 120 ms (o batimento da vitória da [bíblia de som](../arte/03-som.md)).
- **Os outros:** são os outros. É a única mágica que só existe com os quatro.
- **Onde:** o pódio, uma vez por noite; o virar da fita, se o diretor de jogo quiser.
- **O que falta:** nada no módulo.
- **Fontes:** ideia desta pesquisa sobre o acelerômetro; o ritual vem da alma («a noite é uma fita»).

### 9. O vento que aponta

- **Quem joga:** no escuro, a háptica corre de um lado ao outro em 400 ms, a cada 2 tempos, na direção da saída. A
  amplitude cresce quando o cavaleiro chega perto.
- **Os outros:** veem o cavaleiro andar no escuro sem errar o caminho.
- **Onde:** Neblina de Dados (32), Fuga do Mecha Cego (34), Eco do Abismo (27).
- **O que falta:** nada no módulo (`som_haptica()` com dois lados).
- **Fontes:** Ghost of Tsushima Director's Cut (o vento-guia na háptica).

### 10. O sopro e o silêncio

- **Quem joga:** o sopro é um verbo (nível acima de −24 dBFS por 150 ms). O botão de mudo é o escudo, com a luz
  contando as cargas: 3 acesa, 2 piscando, 1 piscando no tempo forte, 0 apagada. Enquanto o microfone escuta, os
  motores caem para 0,5 e o gatilho que treme vai a Off.
- **Os outros:** a sala inteira precisa se calar quando o guardião escuta; quem ri entrega o time.
- **Onde:** S8 (36 a 40), com Zero Absoluto (38) no centro.
- **O que falta:** a regra do microfone (motor mais fraco enquanto escuta); o volume do microfone no GDScript.
- **Fontes:** Astro's Playroom (soprar no cata-vento); a API da Sony
  (`scePadSetVibrationTriggerEffectWeakWhileEmbeddedMicInUse`, na lista da AnyPS5).

## O que fica em aberto, e de quem

| o quê | de quem | por quê |
| --- | --- | --- |
| a emenda do CONTRATO: admitir `SLOPE_FEEDBACK`, `MULTIPLE_POSITION_FEEDBACK` e `MULTIPLE_POSITION_VIBRATION` | **a Vitória decide**; o arquiteto escreve | o próprio `isteamdualsense.h` lista os três; a mágica 7 depende disso |
| a ficha da fase do efeito do gatilho (bytes 41 e 42 do relatório cru, R2 e L2) | o arquiteto abre; o implementador faz | a mágica 5 e o julgamento justo da S5 |
| a ficha da atenuação por lugar (byte 36, bit 6 do byte 1) e do brilho dos LEDs (byte 42) | o arquiteto | acessibilidade sem mexer nos eventos |
| a ficha do fone no controle (o bit 0 do byte 53 liga a rota `0`) | o arquiteto | a mágica 2 |
| expor o volume do microfone ao GDScript | o arquiteto | a mágica 10 |
| conferir o mapa de canais da placa por driver de som (a AnyPS5 usa as posições 4 e 5 com o driver `pulseaudio`) | o arquiteto, na bancada | a háptica pode cair no canal errado |
| o `ForjaScePadTriggerEffect` de `include/forja_dualsense.h` tem 24 bytes; o `ScePadTriggerEffectParam` da Steam tem 120 (máscara, 7 de preenchimento, e dois comandos de 56). Hoje só o autoteste o usa | o arquiteto, antes do backend Steam | o backend Steam do CONTRATO receberia o bloco errado |
| o Steam Input tomando o controle: no Ratchet de PC, com o Steam Input ligado, o meio curso do gatilho sumiu | o arquiteto | o lançamento na Steam; conferir que o jogo recebe o DualSense cru |
| a regra «enquanto o microfone escuta, o motor cai» na bíblia de háptica | o diretor de som e háptica | a mágica 10 |
| os perfis de gatilho por peça e por stat | o designer de sistemas | a mágica 1 |
| o brinde, contar pelo tato e o vento que aponta nos minigames | o diretor de jogo | as mágicas 6, 8 e 9 |
| as 45 notas de pesquisa por minigame (`docs/jogo/pesquisa/<ficha>.md`) | o pesquisador do DualSense, no próximo bloco | este bloco entregou o catálogo |

Nada desta página foi medido num controle de verdade. Cada byte acima vem de fonte pública e vira prova na bancada
(F01) antes de entrar no jogo.
