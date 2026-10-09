# WF — A matriz das features

Toda feature que o produto promete, contra o código da integração de 09/10/2026 (`forja-voo/auditoria`, `85f24c3`).
Para cada uma, quatro perguntas: o **módulo** faz, o **GDScript** chama, uma **sala** usa, uma **prova** confere.
Lido, não rodado: nenhuma prova pesada, nenhum aparelho.

Fontes da promessa: `README.md`, `docs/jogo/05-haptica-e-controle.md`, `docs/jogo/pesquisa/dualsense.md`,
`docs/jogo/arte/10-acessibilidade.md`, `CONTRATO.md`, `COMO-RODAR.md`, o catálogo de features do módulo
(`nativo/nucleo/catalogo.c:28-48`) e as fichas feitas do quadro.

Legenda: **sim** · **não** · **meio** (ligado em parte) · **—** (não se aplica). O estado: **ligada** (de ponta a
ponta), **meio**, **interruptor** (desligada de propósito), **só simulador**, **sem código**.

## 1. As 21 features do catálogo (as nove salas de hoje)

Todas as nove salas declaram as suas (`features = [...]` em cada `salas/*.gd`; a Centelha em
`minigames/s01/martelo_de_hefesto.gd:42`), e a prova do jogo joga as nove com quatro controles simulados
(`godot/testes/prova_do_jogo.gd:229-366`). As de saída (motor, luz, gatilho, háptica, alto-falante) só se medem com a
pergunta às cegas, no Modo bancada; fora dele o veredito é «não medido» de propósito (`prova_do_jogo.gd:20`, `:573`).

| feature | módulo | GDScript | sala | prova | estado | onde quebra fora da máquina dela |
| --- | --- | --- | --- | --- | --- | --- |
| botões | sim | `apertou` | Centelha | sim | ligada | — |
| analógicos | sim | `eixo` | Centelha | sim | ligada | — |
| gatilhos analógicos | sim | `eixo(R2/L2)` | Centelha | sim | ligada | — |
| giroscópio | sim (`giro`, `postura`) | sim | Viga | sim | ligada | no rádio, sem ponte: o SDL não liga o sensor (WF-01) |
| acelerômetro | sim | sim | Viga | sim | ligada | idem |
| touchpad, dois dedos | sim (`dedo`) | sim | Molde | sim | ligada | idem (o SDL não cria o touchpad); no Linux, o cursor (ETAPAS, lacuna 3) |
| touchpad, clique | sim | sim | Molde | sim | ligada | idem |
| motor forte / fraco | sim (`vibrar`, SDL_RumbleGamepad) | só `forja.gd` (`sentir`) | Impacto | sim | ligada | no rádio, sem ponte: o rumble volta «não suportado» (WF-01) |
| vibração só no controle certo | sim | sim | Impacto | sim | ligada | idem |
| barra de luz | sim (`luz`, `luz_do_lugar`) | sim | Impacto, Voz, Prova | sim | ligada | idem; o pisca vermelho ignora «Flashes» (WF-04) |
| gatilho: resistência, arma, vibração | sim (`gatilho`, os 4 modos) | sim, com a escala das Opções | Galeria, Prova | sim | ligada | idem; sem acesso ao hidraw, o SDL cai no joystick do kernel e o gatilho some (`COMO-RODAR.md:66-69`) |
| LEDs de jogador | sim | sim | Galeria, Prova | sim | ligada | idem |
| microfone | sim (`som_mic`) | sim | Voz | sim | ligada | só no cabo (o rádio não tem placa: ETAPAS, risco «O rádio») |
| mudo do microfone | sim (`BOTAO_MICROFONE`) | sim | Voz | sim | ligada | — |
| LED do microfone | sim (`led_mic`) | sim | Voz | sim | ligada | no rádio, sem ponte (WF-01) |
| háptica por áudio | sim (`som_haptica`, canais 3 e 4) | sim, com a escala das Opções | Caminhos, kit (`tocar_material`) | sim (placa virtual) | ligada | só no cabo; nos Caminhos não há troca pelo rumble (a sala mede a háptica, e «não senti» é resposta) |
| alto-falante | sim (`som_falante`, rota e volume) | sim | Canto, Voz, Prova, kit, salão | sim (placa virtual) | ligada | só no cabo |
| tudo junto | — | — | Prova | sim | ligada | soma dos de cima |

## 2. O resto do controle (`docs/jogo/pesquisa/dualsense.md:21-44`)

| recurso | o que a pesquisa diz | o que o código mostra | estado |
| --- | --- | --- | --- |
| fone no controle (jack) | `módulo`, «uma sala que use» (`:33`, `:165`), e uma ficha a abrir (`:512`) | o módulo já troca a rota sozinho a cada quadro (`nativo/som/som_controle.c:416-434`, chamado em `:527`) e põe o som nas duas orelhas (`:402-405`); o volume do fone nunca é escrito | **meio**, e a pesquisa está atrasada (WF-03) |
| volume do microfone | `falta` expor | `forja_fx_volume_mic` existe só em `src/forja_dualsense.c:206` | sem código no jogo (pesquisa já diz) |
| atenuação dos motores e do gatilho | `falta` | `FORJA_FX_MOTOR_POWER` só no `forja-send` (`src/forja_dualsense.c:106`) | sem código no jogo (pesquisa já diz) |
| brilho da barra e dos LEDs | `falta` | nada | sem código (pesquisa já diz) |
| estado do efeito do gatilho (bytes 41 e 42) | `falta` | nada | sem código (pesquisa já diz) |
| DualSense Edge (Fn, alavancas) | `falta` | o PID `0x0DF2` é reconhecido | sem código (pesquisa já diz) |
| Slope, Multiple Position | `emenda` | — | interruptor de contrato |
| bateria | `usa` | `hud.gd`, `cartao_jogador.gd` | ligada |
| firmware, carimbo do sensor | `usa` | no registro e na bancada | ligada |
| rumble pela metade (firmware < 2.24) | registro | só a sombra (`nativo/nucleo/pads.c:725-748`); quem corrige é o SDL (`SDL_hidapi_ps5.c:724`) | ligada |
| `ctl.intensidade` | — | método nativo sem chamada, proibido pela prova das sensações (`prova_do_jogo.gd:1173-1174`) | morto de propósito |
| `status_cru`, `sintetizar`, `nome`, `aberto`, `contrato_estrito`, `pasta_relatorios`, `simulado` | — | métodos nativos sem chamada em `godot/scripts` | sem uso (a V07 cobre só as do GDScript) |

## 3. As promessas do 05 (a háptica e o controle)

| promessa | onde | estado |
| --- | --- | --- |
| o piso de força, numa tabela só | `godot/scripts/forja.gd:501-511` | ligada; a sensação `aviso` não tem quem peça (os 45 pedem) |
| o motor vence a háptica | `forja.gd:893-896`, prova `prova_do_jogo.gd:1215` | ligada |
| a escala salva no registro | `forja.gd:154-157`, `:532` | ligada |
| a háptica por material, onda nos atuadores e mais baixa no alto-falante | `nativo/som/sintese.c:540-615`, `forja.gd:909-916` | ligada (o gelo num atuador só) |
| a agenda do alto-falante (pio, nota, nota quebrada, clique) | `main.gd:275`, `:902`; `minigame.gd:270-279` | ligada; a placa abre na entrada do lugar (`main.gd:259-275`) — o 05 ainda diz «hoje só nas salas de som» (`05:128`) |
| o acerto perfeito pisca branco na luz | nada no código | sem código; está na H08 (`H08-os-acrescimos-do-kit.md:438`) |
| a identidade P1..P4, quem caiu reencontra o lugar | `nativo/nucleo/pads.c:372-`, F04 | ligada |
| trocar de lugar segurando ◻ | `trocar_lugar` no módulo e no `main.gd` | ligada; a construção do cavaleiro é a G02 (em voo) |
| no rádio, o rumble entrega a pista da háptica | `forja.gd:909-916` (kit) | meio: o kit troca; os Caminhos não (é sala de medida) |
| o modo seco do rumble | — | interruptor de contrato (F10 B espera o André) |

## 4. As Opções e a acessibilidade

| opção | onde se aplica | estado |
| --- | --- | --- |
| gatilho por lugar (desligado, fraco, forte) | `opcoes.gd:117-127` → `forja.gd:570-571` | ligada |
| vibração por lugar | `forja.gd:556`, `:896` (motor e háptica) | ligada |
| tempo por lugar (calibração) | `ritmo.gd:48` | ligada (a medida automática espera a G02) |
| volume da TV, volume do controle | `forja.gd:164-165`, `:887` | ligada |
| movimento (tremor) | `main.gd:1006`, `:1063` | ligada (a G16 estende) |
| flashes | `sala_jogo.gd:200`, `voz.gd:304` | **meio**: a luz do controle pisca na Impacto e na Prova sem olhar a opção (WF-04) |
| texto grande, idioma, tela cheia | `forja.gd:166-171` | ligada |
| jogar no teclado | `tela_titulo.gd:62-63`, `forja.gd:387` | ligada |

## 5. Onde o jogo roda

| alvo | o que existe | estado |
| --- | --- | --- |
| Linux x86_64, DualSense no cabo | módulo, exportação, CI | ligada, com a regra do udev (`COMO-RODAR.md:56-69`: sem ela, gatilho, luz, LEDs e o cru morrem) |
| Windows x86_64 (e o `.exe` no Proton) | módulo, exportação, o som pelo ContainerId (`nativo/som/som_controle_windows.c`) | ligada |
| DualSense no rádio, sem ponte | `SDL_HINT_JOYSTICK_ENHANCED_REPORTS = "0"` (`nativo/nucleo/forja.c:169`) | **interruptor**: só botões e analógicos (WF-01) |
| macOS, Linux ARM, Windows ARM | `godot/forja.gdextension:9-10` só lista Linux e Windows x86_64; `som_controle_outro.c` existe e ninguém compila | **sem código no pacote** (WF-02) |
| backend da Steam (`ISteamInput`) | `CONTRATO.md:75` o diz «preferido»; nenhum código | sem código; já na ETAPAS (lacuna 2) e na pesquisa (`dualsense.md:514`) |
| controle de outra marca | abre, sem efeitos | já na ETAPAS (lacuna 1) |

## 6. O README

| promessa | estado |
| --- | --- |
| «45 minigames em nove seções» | 1 dos 45 no catálogo (`S01_J01`) e as oito salas antigas; os 44 são fichas prontas (I a Q) |
| «As nove salas de hoje funcionam e cada uma prova um recurso do DualSense» | verdade no cabo; no rádio sem ponte, Viga e Molde perdem o verbo e as de saída ficam mudas (WF-01) |
| o CI joga as salas, tira um cabo, liga defeitos e joga o binário exportado | `tests/prova_do_jogo.sh`, `tests/prova_da_exportacao.sh` |

## Os achados desta matriz

- **WF-01** — O DualSense no rádio, sem a ponte, fica só com botões e analógicos: o giroscópio, o touchpad, o rumble,
  a luz, os LEDs e o gatilho morrem juntos, não só o som (a ETAPAS, risco «O rádio», só fala do som).
- **WF-02** — O módulo só sai para Linux e Windows x86_64: em macOS e em ARM o jogo abre sem controle nenhum.
- **WF-03** — O fone no controle está ligado pela metade (a rota troca, o volume do fone nunca é escrito), e a
  pesquisa e o 05 dizem que nada está ligado.
- **WF-04** — A opção «Flashes» não chega à luz do controle: a Impacto e a Prova piscam vermelho saturado com ela
  desligada.
