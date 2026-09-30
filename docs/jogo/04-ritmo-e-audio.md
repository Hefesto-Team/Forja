# 04 — O ritmo e o áudio

Num jogo de ritmo, o relógio é a placa de som, não o quadro da tela. Esta
página decide como o Forja mede o tempo, como julga o toque, como calibra a
sala de cada um e como organiza as 45 faixas, os jingles e os efeitos.

## O relógio de áudio

Hoje todo tempo do jogo é soma do `delta` de cada quadro. Isso escorrega:
um quadro de 40 ms numa explosão empurra o jogo para longe da música. A
decisão é seguir o guia oficial do Godot 4.4, *Sync the gameplay with audio
and music*:

```gdscript
# t_musica: a posição que se ouve agora, em segundos
var t := player.get_playback_position() + AudioServer.get_time_since_last_mix()
t -= _latencia_de_saida          # AudioServer.get_output_latency(), lida uma vez e guardada
t = max(t, _t_anterior)          # o relógio nunca anda para trás
```

- `get_output_latency()` é caro: lê-se ao começar a faixa e ao trocar de
  saída, nunca a cada quadro.
- A música começa **agendada**: o minigame espera o próximo mix e parte do
  zero conhecido. Nada começa num `play()` solto no meio do quadro.
- A batida atual é `t_musica * bpm / 60`. Tudo o que se move no ritmo (nota,
  pêndulo, prensa, portão) tem a posição **calculada** a partir dela, nunca
  acumulada.
- A entrada também usa esse relógio. `Input.use_accumulated_input` fica
  desligado, para cada toque chegar com o quadro dele.
- O carimbo do registro passa a ter os dois tempos: o de parede (monotônico,
  do sistema) e o da música. Hoje o `relogio.h` diz que é de parede e não é
  ([01](01-diagnostico.md#o-ritmo-não-é-medido)).

## As janelas

Assimétricas, porque a mão humana olhando para a tela chega tarde mais do que
cedo. Os valores valem para os 45 minigames e se medem a partir do tempo
corrigido pela calibração do jogador.

| julgamento | janela | o que acontece |
| --- | --- | --- |
| perfeito | de −40 a +60 ms | o efeito inteiro, a barra de luz pisca, conta para o combo e para a sabotagem |
| ótimo | ±90 ms | o efeito com uma imperfeição visível (o bloco nasce torto, a faísca sai menor) |
| bom | ±140 ms | a ação acontece com prejuízo (o cavaleiro tropeça, a velocidade cai) |
| erro | fora disso, ou sem toque | a falha física do minigame e o som quebrado da nota do jogador |

Quem está em último ganha até +40 ms na janela **bom** dos perigos físicos
([02](02-principios.md#8-ninguém-fica-para-trás-ninguém-é-punido-por-ser-bom)).
A janela **perfeito** nunca muda.

As salas de chamada e resposta (O Canto e a seção S6) comparam intervalos
entre toques. Aí a latência constante se cancela, e a janela vale sobre o
intervalo.

## A calibração que ninguém vê

Cada controle tem a sua latência: o cabo, o rádio, a TV, o fone. A
calibração é por lugar e está disfarçada de jogo. Na
[construção do cavaleiro](06b-a-construcao-do-cavaleiro.md), a armadura é
forjada a marteladas: oito golpes no tempo da bigorna, e a mediana do atraso
de cada um vira o desvio daquele controle. Não há tela de calibração, não há
número na tela; o desvio fica nas opções do lugar (Botão △ (Opções) › Tempo)
para quem quiser ajustar à mão, em passos de 10 ms.

O desvio vai para o registro, com o transporte do controle (cabo ou rádio).
É o primeiro número que a [noite de seis horas](08-a-noite-de-6-horas.md)
compara.

## A música que reage

As faixas geradas chegam como mixagem estéreo. O Forja não usa middleware
de áudio; o que reage é feito nos barramentos do Godot e no mixer do módulo.

- **Sem stems (o mínimo):** no erro, um filtro passa-baixa de 300 ms no
  barramento da música. No combo de oito perfeitos, a música ganha brilho
  (passa-alta desliga, +1,5 dB). No último terço do minigame, sobe a
  intensidade do ambiente.
- **Com stems (quando der):** a faixa é separada offline em bateria, baixo e
  resto. Cada stem toca sincronizado no mesmo relógio. No erro de um jogador
  cai a camada dele; no combo coletivo entra a camada de enriquecimento. A
  troca usa cruzamento de potência igual (`cos` e `sin` do tempo
  normalizado), nunca linear.
- **Rampas sempre:** cortar um som vai a zero em 15 a 30 ms, nunca de uma
  vez. Vale para a TV e para o mixer do controle (`nativo/som/mixer.c`).
- **O acerto aperta a música:** no perfeito, a música abaixa 2 dB por 80 ms,
  e o som do golpe aparece por cima.

## As 45 faixas

Uma faixa por minigame. O nome do arquivo é o slot:
`godot/assets/ost/Sxx/MUS_Sxx_Jyy.ogg`. Com cada faixa vai um mapa de
batidas `MUS_Sxx_Jyy.batidas.json` com o BPM, o instante do primeiro tempo,
os compassos e as seções (introdução, queda, pausa). Faixa gerada por IA
pode escorregar o andamento, e o mapa é conferido à mão antes de a faixa
entrar no jogo.

O "nome de trabalho" é o nome da faixa na lista de geração. Onde está
*nova*, a faixa ainda não existe e o prompt está logo abaixo da tabela.

| slot | minigame | BPM | tom | clima | nome de trabalho |
| --- | --- | --- | --- | --- | --- |
| `MUS_S01_J01` | O Martelo de Hefesto | 122 | Fá menor | bigorna no contratempo, aquecimento alegre | A Primeira Faísca |
| `MUS_S01_J02` | Marcha dos Escudeiros | 110 | Mi menor | bateria muito clara, muito espaço | Calibração de Impacto |
| `MUS_S01_J03` | Portões de Néon | 135 | Si menor | esteira em semicolcheias, perseguição | Esteira de Escória |
| `MUS_S01_J04` | O Fole | 115 | Sol menor | notas longas, filtro abrindo | Sincronia de Matéria |
| `MUS_S01_J05` | A Esteira de Escória | 125 | Sol menor | fábrica, bigorna e ar comprimido | Engrenagens em Sincronia |
| `MUS_S02_J06` | A Viga | 115 | Lá menor | frio, eco pingue-pongue | Glacial Digital |
| `MUS_S02_J07` | Pêndulos do Caos | 130 | Ré menor | bolero que cresce em camadas | A Última Forja Sobrevivente |
| `MUS_S02_J08` | Patinação de Dados | 128 | Ré menor | deslize contínuo, portamento | Patinação de Dados |
| `MUS_S02_J09` | O Balão dos Foles | 128 | Fá menor | nu-disco, baixo slap | Espectro de Luz |
| `MUS_S02_J10` | Mira Óptica | 115 | Lá menor | trap espaçado, foco | Calibração Óptica |
| `MUS_S03_J11` | O Molde | 122 | Dó menor | agudos contra graves, metódico | Inspeção de Qualidade |
| `MUS_S03_J12` | Quebra-Gelo | 130 | Fá# menor | vidro no contratempo | Quebra-Gelo Rítmico |
| `MUS_S03_J13` | Hackeando o Terminal | 140 | Sol menor | arpejos em fusas, urgência | Broca Sincronizada |
| `MUS_S03_J14` | A Pinça | 118 | Si menor | grave sujo, subterrâneo | Profundezas do HD |
| `MUS_S03_J15` | O Carimbo | 128 | Dó# menor | tempos 1 e 3 pesados | Martelos Térmicos |
| `MUS_S04_J16` | O Cerco | 140 | Dó menor | arena, metais sintetizados | Duelo de Neon |
| `MUS_S04_J17` | Fuga do Titã | 145 | Mi menor | perseguição colossal, falhas em 7/8 | O Verme de Dados |
| `MUS_S04_J18` | Curto-Circuito | 160 | Dó menor | sirenes no tempo, pânico | Curto-Circuito |
| `MUS_S04_J19` | Martelos Térmicos | 130 | Ré menor | fornalha, distorção | Combustão de Dados |
| `MUS_S04_J20` | A Prensa | 120 | Mi♭ menor | impacto no tempo 1, ameaça | Prensa Hidráulica |
| `MUS_S05_J21` | A Galeria | 130 | Ré menor | brilho, pingue-pongue de laser | Reflexo Perfeito |
| `MUS_S05_J22` | Arco de Néon | 135 | Si menor | laser como percussão | Matriz de Lasers |
| `MUS_S05_J23` | Metralhadora de Feitiços | 155 | Fá menor | seco, sem cauda, rajadas | Sobrecarga de CPU |
| `MUS_S05_J24` | Espada de Fita | 142 | Dó# menor | arpejos neoclássicos, duelo | O Prisma Sombrio |
| `MUS_S05_J25` | A Catapulta | 135 | Lá menor | queimada, quebra e explosão | Queimada Cibernética |
| `MUS_S06_J26` | O Canto | 110 | Dó menor | reverberação de caverna, chamada e resposta | Eco Subterrâneo |
| `MUS_S06_J27` | Eco do Abismo | 135 | Mi♭ menor | gelo que racha, silêncios súbitos | O Guardião de Nitrogênio |
| `MUS_S06_J28` | Coral dos Quatro | 138 | Fá menor | marcha, coro de vocoder | O Construtor Mestre |
| `MUS_S06_J29` | Código do Dragão | 140 | Mi♭ menor | polirritmia 3 contra 4, bumbo reto | Desfragmentação |
| `MUS_S06_J30` | Corta-Fio | 125 | Lá menor | choques elétricos na percussão | Fios Desencapados |
| `MUS_S07_J31` | Os Caminhos | 120 | Sol menor | meio-tempo pesado, passos | Fundição em Massa |
| `MUS_S07_J32` | Neblina de Dados | 100 | Si♭ menor | terror, quase sem bateria | *nova* |
| `MUS_S07_J33` | Passo no Fosso | 150 | Si menor | breakbeat, corrida | Aceleração Crítica |
| `MUS_S07_J34` | Fuga do Mecha Cego | 140 | Mi menor | chefe, coro de sintetizador | O Mestre Ferreiro |
| `MUS_S07_J35` | Engrenagens Sincopadas | 130 | Mi menor | máquina engasgando, bumbo firme | Esteira Defeituosa |
| `MUS_S08_J36` | A Voz | 105 | Ré menor | respiração, espaço para a voz | *nova* |
| `MUS_S08_J37` | O Sopro no Fole | 112 | Sol menor | notas longas que param em seco | *nova* |
| `MUS_S08_J38` | Zero Absoluto | 120 | Dó menor | para por quatro tempos e volta | Zero Absoluto |
| `MUS_S08_J39` | Grito de Guerra | 135 | Si menor | serra agressiva, silêncio de um compasso | O Martelo do Destino |
| `MUS_S08_J40` | Palmas da Forja | 118 | Lá menor | palmas no dois e no quatro, festa | *nova* |
| `MUS_S09_J41` | A Prova | 145 | Mi menor | estádio, solos | O Campeão Holográfico |
| `MUS_S09_J42` | Roubo de Bateria | 138 | Sol menor | espionagem acelerada | Captura da Bandeira de Dados |
| `MUS_S09_J43` | Mecha de Dois Pilotos | 145 | Sol menor | de grave pesado a cristal, "ACCESS DENIED" | A Porta do Núcleo |
| `MUS_S09_J44` | Ruge o Reator | 120 | Ré menor | órgão sintetizado, marcha pesada | O Despertar do Deus Máquina |
| `MUS_S09_J45` | O Último Acorde | 150 | Mi menor | coro heroico, solo, triunfo | A Forja Supernova |

### As quatro novas

Para gerar no mesmo estilo das outras (inglês, gênero primeiro, marcadores de
estrutura):

- **`MUS_S07_J32` Neblina de Dados:** `instrumental, dark ambient synthwave, horror chiptune, 100 BPM, Bb minor. Thick digital fog. Sparse heartbeat-like sub-bass pulse on every beat, distant detuned 8-bit bells, no snare. [Verse] almost silent, only the pulse and wind noise. [Build] slow rising filtered drone. [Drop] a single heavy kick every bar, cold square wave melody. Tense, suspenseful, clean mix, no vocals.`
- **`MUS_S08_J36` A Voz:** `instrumental, chill synthwave, breathy ambient chiptune, 105 BPM, D minor. Sleeping forge guardian. Soft analog pads, gentle Moog bass, light 8-bit hi-hats, lots of empty space in the mids for a human voice. [Verse] sparse. [Chorus] warm rising square wave melody. [Break] 2 beats of silence. Calm but rhythmic, no vocals.`
- **`MUS_S08_J37` O Sopro no Fole:** `instrumental, progressive synthwave, chiptune, 112 BPM, G minor. Long sustained analog notes that stop dead exactly on the beat, bellows-like filter swells, steady four-on-the-floor kick, heavy sidechain. [Build] filter opening. [Drop] long held square wave notes with hard stops. Mechanical, breathing, precise.`
- **`MUS_S08_J40` Palmas da Forja:** `instrumental, upbeat synthpop, festive chiptune, 118 BPM, A minor. Party at the forge. Loud handclaps on beats 2 and 4, bouncy analog bass, bright anvil hits, four-on-the-floor kick. [Build] clap roll. [Chorus] catchy 8-bit lead with call and response phrases. Joyful, simple, easy to clap along, no vocals.`

### As telas e os jingles

Fora das 45, e cada uma com o seu slot:

| slot | onde toca | BPM | nome de trabalho |
| --- | --- | --- | --- |
| `MUS_TELA_TITULO` | título e introdução | 115 | Inicialização do Sistema |
| `MUS_TELA_CONSTRUCAO` | construção do cavaleiro e lobby | 120 | Seleção de Circuitos |
| `MUS_TELA_SALAO` | o salão | 110 | *nova*: a mesma harmonia do título, sem bateria |
| `MUS_TELA_PODIO` | o pódio | 130 | *nova*: o tema do título em tom maior |
| `MUS_TELA_CREDITOS` | os créditos | 90 | O Cavaleiro do Futuro |
| `MUS_RELAMPAGO` | o Relâmpago | 160 | Colapso do Sistema |

| jingle | quando | duração |
| --- | --- | --- |
| `JIN_APITO` | o fim de todo minigame, a música para em seco | 1 s |
| `JIN_VITORIA` | o resultado com um vencedor | 5 a 8 s |
| `JIN_COOP_VITORIA` | o resultado coop em que todos vencem | 5 a 8 s |
| `JIN_DERROTA` | o resultado coop em que ninguém venceu | 5 s |
| `JIN_EMPATE` | o empate | 5 s |
| `JIN_RECORDE` | um recorde da noite | 3 s |
| `JIN_ENTRADA` | a contagem para o minigame começar ("três, dois, um") no tempo da faixa | 2 compassos |
| `JIN_VIRADA` | a virada no placar | 2 s |

Todo jingle termina em parada seca, sem fade: a tela troca no mesmo
instante.

## Os efeitos

Três destinos, cada um com o seu trabalho:

| destino | o que vai | formato |
| --- | --- | --- |
| a TV | tudo o que a sala inteira precisa ouvir: golpes, quedas, a torcida, a interface | WAV 48 kHz mono, carregado inteiro na memória (`godot/assets/sons/`) |
| o alto-falante do controle | o som pessoal do cavaleiro: o pio dele, o acerto, a coleta, o bipe da bomba | sintetizado no módulo, ou WAV 48 kHz mono, sempre curto |
| os atuadores (háptica por áudio) | a textura: o chão, o peso, o impacto | WAV PCM sem compressão, grave (60 a 180 Hz); nunca QOA nem ADPCM, que deformam a onda |

Todo evento de jogo tem som na TV **e** algo no controle do dono do evento.
A regra do Astro Bot vale aqui: o alto-falante do controle toca só sons
pequenos e ligados a uma ação — nunca música, nunca ambiente contínuo.

## Os arquivos no repositório

- Música e jingles em OGG Vorbis, 48 kHz, estéreo (MP3 é proibido: o
  preenchimento de silêncio quebra o laço).
- Efeitos em WAV 48 kHz. Uma taxa só em todo o projeto, para o motor não
  reamostrar em tempo real.
- **As músicas ficam dentro do git**, em `godot/assets/ost/` (decisão do
  André em 30/09): `S01/` a `S09/` para as 45 faixas, `telas/` e `jingles/`,
  com um [LEIA-ME](../../godot/assets/ost/LEIA-ME.md) que diz o nome de cada
  arquivo. O `.gitattributes` da raiz marca `*.ogg`, `*.wav`, `*.png`,
  `*.glb` e `*.ttf` como binários.
- As 45 faixas somam algo entre 150 e 250 MB. **Cada versão de uma música
  fica para sempre no histórico**, e o clone cresce com ela. Por isso a regra:
  só entra faixa aprovada, ouvida no jogo; rascunho e geração descartada nunca
  entram. Se o repositório ficar pesado demais, o caminho é o Git LFS, sem
  mudar a pasta.
- As sessões de produção (projetos de DAW, stems crus, gerações descartadas)
  nunca entram no repositório.
