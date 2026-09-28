# FORJA — sprints (plano, não execução)

**Repo:** [AndreBFarias/forja](https://github.com/AndreBFarias/forja) · privado · `main` @ `07248b2` (13/09/2026)\
**O que está no GitHub hoje:** empacotador C USB `0x02` + Godot 4.4 (Hub / Galeria / Impacto / Viga / Prova) + `./run-local.sh`.\
**O que NÃO está no GitHub:** o preview web (eleição de modo, packer alinhado ao mapa USB do specs.html, WebHID, audio 4.0).\
**Contrato:** o jogo fala Sony/Steam no cabo. Não fala Hefesto. Sem relatório `0x31`.

Este arquivo é backlog. Não começa trabalho sozinho.

Fonte de verdade das features: coluna **cabo** do `html/specs.html` (branch `dev` do hefesto-dualsense4unix). Cada modo abaixo cita a `chave` do mapa.

---

## Sprint 0 — sincronizar o que já existe

Objetivo: o GitHub deixar de ser um esqueleto atrás do preview.

| item | por quê |
| --- | --- |
| Subir o packer atual (sem `LIGHT_OUT` em loop, rota speaker `common[7]`, pré-amp, teto mic `0x40`) | o `0x02` do repo ainda apaga lightbar |
| Eleição de modo no Godot (4 cartas → 3 piscadas → round) | é a tese da demo, hoje só no web |
| HUD de uma linha | textão queimou a apresentação |
| README: o que o jogador *sente*, não o que o HID *é* | o README atual é contrato de driver |

**Pronto quando:** `./run-local.sh` abre a eleição, um DualSense no cabo pisca 3× e entra na Galeria com R2 duro.

---

## Sprint 1 — QoL (mesa de 4)

Coisas que quebram a demo na frente de gente.

| item | detalhe |
| --- | --- |
| Join P1–P4 | plugou = slot, LED jogador 4/10/21/27, lightbar da cor |
| Reconnect | cabo saiu / voltou sem matar o round |
| udev no `COMO-RODAR` em 3 linhas | senão hidraw pede root e “não funciona” |
| Silêncio de verdade | Off nos dois gatilhos + motores 0 + lightbar do time, sem leftover |
| Pause / voltar ao hub | Start no DualSense, não só Enter no teclado |
| Falha visível e curta | “P3 sem USB” no HUD, não um parágrafo |
| Isolamento visível | se P3 toma da esquerda, P1/P2/P4 ficam mortos no SVG — sem tese |

**Pronto quando:** quatro cabos, um desconecta no meio da Galeria, os outros três continuam atirando, o LED do morto apaga.

---

## Sprint 2 — interface

A demo é o plástico, não a wiki.

| item | detalhe |
| --- | --- |
| Título: 1 frase + 2 botões | Jogar / Escolher modo. Sem USB 0x02 na cara |
| Eleição: 4 cartas com art, 4 palavras de feel | “R2 por arma”, não “common[10..20] flag0 0x04” |
| In-game: nome do modo + 1 linha de ação | “R2 atira” / “desvia” / “gira” / “90s” |
| SVG DualSense no canto = estado, não manual | lightbar, gatilho, motor L/R acesos de verdade |
| Fora: zero `cabo_comando` / `cabo_ressalva` | o mapa fica no código, não na overlay |
| Mobile: só o enough pra apresentação | toque = P1. 4 pads = desktop + cabo |

**Pronto quando:** um estranho entende o que apertar em 5 segundos, sem ler.

---

## Sprint 3 — jogabilidade dos 4 modos atuais

Os modos existem. Ainda não jogam como desculpa.

### Galeria (já no repo)
- Munição visível. Zero munição → R2 Off (`gatilho.*.adaptativo` + Off 0x05).
- Cada lane = uma arma / um modo (SMG Vibration, pistola Weapon, arco Feedback).
- Alvos somem. Placar por player.

### Impacto
- Tiro esquerdo = motor L daquele pad só (`vibracao.rumble.esquerdo` / `.direito`).
- Lightbar pisca branco no hit, depois volta pra vida (`luz.lightbar.cor`).
- HP baixo = pulso vermelho (já especificado; falta sentir).

### Viga
- Yaw do gyro faz o 180 (`movimento.giroscopio.jogo` payload[15..20]).
- Shake no acel = stomp (`movimento.acelerometro.jogo`).
- Stick é fallback se IMU não veio — e o HUD diz “stick”, não finge IMU.

### A Prova
- 2v2, 90s, todos os efeitos ao mesmo tempo.
- Vitória = time com HP. Derrota = lightbar off daquele pad.

**Pronto quando:** dá pra gravar 40s de cada sala e o plástico conta a história sozinho.

---

## Sprint 4 — modos novos (features que o cabo tem e o jogo ainda não desculpa)

Um modo = uma família do mapa. Quatro pads. Isolamento obrigatório. Sem painel de spec.

| modo | o que o jogador faz | chave do mapa (cabo) |
| --- | --- | --- |
| **Voz** | segura mute, xinga, o speaker do *próprio* pad devolve | `audio.microfone` + `audio.alto_falante` (PCM canais 1–2) + `luz.led_microfone` |
| **Toque** | dedo no touch = ping no mapa / mira fina | `toque.touchpad` + `.clique` |
| **Fone** | plugou o jack = mix muda; tirou = speaker interno | `audio.jack.deteccao` payload[53] + `audio.alto_falante.rota` |
| **Couro** | chão de metal vs grama: PCM nos motores, não rumble HID | `vibracao.haptics_vcm` (USB Audio 4.0 canais 3–4). **Não** ligar `flag0` bit1 |
| **Carga** | round acaba quando a bateria do cabo cai um degrau — ou não | `energia.bateria.*` payload[52] (no cabo quase sempre 100% + charging: mostrar isso é o ponto) |

Não abrir laboratório. Cada um entra pela eleição, pisca 3× (`luz.lightbar.aviso_de_modo`), joga 45–90s, volta ao hub.

Fora de escopo deste sprint: rádio, report `0x31`, Opus, IPC Hefesto, Steam page pública.

---

## Sprint 5 — apresentação Steam / mesa

| item | detalhe |
| --- | --- |
| GodotSteam no ramo Steam | `setLEDColor` / `triggerVibration` / `setDualSenseTriggerEffect` — mesmo contrato, outro backend |
| Action set local-coop 4 pads | Steam Input, PlayStation support on |
| Trailer de 60s | eleição → Galeria → Impacto (P3 left) → Viga 180 → Prova |
| Checklist de palco | 4 cabos, udev, volume do speaker, “se o iframe bloquear WebHID usa o zip” |

**Pronto quando:** dá pra ligar quatro DualSense numa mesa, apertar Jogar, e a sala inteira entender o Hefesto *sem ouvir a palavra Hefesto*.

---

## Ordem e o que não fazer

1. Sprint 0 (sync GitHub)
2. Sprint 2 (interface) em paralelo com 1 (QoL) — a cara queima mais que o udev
3. Sprint 3 (os 4 modos jogáveis de verdade)
4. Sprint 4 (modos novos, um por PR)
5. Sprint 5 (Steam) só com 0–3 fechados

Não fazer: dump do specs.html na UI, modo BT “pra testar o Hefesto”, broadcast de rumble, `LIGHT_OUT` em loop, inventar feature que o cabo marca `cabo_aciona=não`.

---

## Entrou por fora da fila — 24/09/2026

A Forja virou o jogo de prova do alto-falante, do microfone e do movimento (decisão de 23/09, sprint `A-FORJA-VALIDA-O-SOM-01` do Hefesto):

- `forja-speak`: um SFX no alto-falante de cada DualSense, achado pelo aparelho ou pelo nome — e o tiro da Galeria sai no controle de quem atirou;
- `forja-read` e a Viga girando com a IMU (`movimento.giroscopio.jogo`); sem IMU, a HUD diz «stick»;
- **Voz** (`F5`): a barra do microfone padrão. O eco no alto-falante do próprio pad, do Sprint 4, **não** entrou.

---

## Onde cada sprint está — 28/09/2026: o jogo 3D volta a ser a base

A tabela de 27/09 (logo abaixo) descrevia o app 2D em SDL3, que saiu do branch
([ADR-007](docs/adr/007-o-jogo-e-o-3d-em-godot.md)): o jogo é o 3D em Godot, e
o SDL3 vai dentro dele como módulo nativo. O que o 2D provou (o relatório, os
vereditos, a origem do controle, o simulador, as provas às cegas) mora em
`nativo/` e volta às salas 3D marco a marco. As salas 2D de `docs/SALAS.md`
são o desenho de cada sala 3D (o Cerco virou O Impacto; a Cripta, A Voz).

| marco | o que entra no 3D | situação |
| --- | --- | --- |
| 1 | o módulo nativo (Linux e Windows), o lobby com os quatro lugares, o salão com os oito portões, o diagnóstico com o mapa do controle, o livro, a pausa, a cara do app Hefesto, a prova do jogo e o gauntlet sem aparelho | feito |
| 2 | A Centelha, A Viga e O Molde como jogos, com os vereditos de entrada | feito — as três no 3D com o desenho das salas 2D e as peças do kit; o módulo mede cada controle a cada quadro (a régua de `medidas.c`); o robô joga as três na prova do jogo e o gauntlet pega os sete defeitos de entrada |
| 3 | O Impacto e A Galeria às cegas: motores, isolamento, lightbar, os três modos de gatilho, LEDs de jogador | a fazer |
| 4 | o som pelo módulo (PipeWire, WASAPI e o `ContainerId`): A Voz com o microfone de cada controle e o susto, Os Caminhos, O Canto | a fazer |
| 5 | A Prova com tudo ligado, a Prova de Fogo em ordem, `experimental/` refeito para o 3D | a fazer |
| 6 | a exportação: o binário Linux e o `.exe` pelo Proton, no CI; o README fechado | a fazer |

## Onde cada sprint estava — 27/09/2026 (o app 2D, fora do branch)

A Hefesto Tech Demo (SDL3, `demo/`) fechou a maior parte deste plano em salas
novas, com o mesmo contrato e o mesmo empacotador. O jogo Godot continuava como
estava. "Feito" aponta onde; "parcial" diz o que falta; "fica" é o que não
entrou.

| sprint | item | situação |
| --- | --- | --- |
| 0 | o packer atual (rota `common[7]`, pré-amp, teto do mic, sem `LIGHT_OUT` em loop) | feito — `include/forja_dualsense.h`, a sombra que lembra cada bloco |
| 0 | eleição de modo | feito, com outra forma — o salão com as portas e o aviso de cada sala (✕ quando pronto); as três piscadas de aviso na lightbar não entraram |
| 0 | HUD de uma linha | feito — o nome da sala e o padrão de jogo no alto, os glifos no rodapé |
| 0 | README do que o jogador sente | feito — `README.md` |
| 1 | entrar P1–P4, LEDs 4/10/21/27, lightbar do lugar | feito — a mesa (`demo/src/cenas/lobby.c`) |
| 1 | reconectar sem matar a rodada | feito — o lugar guarda o controle e o devolve; a sala segue sem ele e mostra "sem controle" |
| 1 | udev em três linhas | feito — `README.md` e `COMO-RODAR.md` |
| 1 | silêncio de verdade | feito — gatilhos Off, motores 0, a cor do lugar, ao sair de cada sala |
| 1 | pausa pelo controle | feito — Options, com refazer, voltar ao salão, diagnóstico, livro |
| 1 | falha visível e curta | feito — a faixa de quem ficou sem controle; o veredito diz o porquê |
| 1 | isolamento visível | feito — provado às cegas: o Cerco (vibração) e o Canto (som) |
| 2 | título: uma frase e dois botões | feito — Jogar / Prova de Fogo; o diagnóstico no △ |
| 2 | cartas com arte, quatro palavras | feito — as portas do salão, com ícone e nome |
| 2 | nome do modo e uma linha de ação | feito — o topo de cada sala e o rodapé |
| 2 | o DualSense desenhado como estado | feito — na mesa e no diagnóstico, aceso com o que chega |
| 2 | nada de mapa na tela | feito — o protocolo mora no diagnóstico e no livro |
| 2 | celular | fica — a Tech Demo é para a TV e o desktop |
| 3 | Galeria: munição, R2 Off vazia, uma arma por modo, placar | feito — A Galeria (e a munição na Prova) |
| 3 | Impacto: tiro da esquerda no motor da esquerda, a luz com a vida | feito — O Cerco; o pulso de vida baixa está na Prova |
| 3 | Viga: giro, sacudida, analógico sem IMU e a tela dizendo | feito — A Viga |
| 3 | A Prova: 2v2, 90 s, tudo junto | feito — A Prova, que mede a carga e fecha com a prova final às cegas |
| 4 | Voz: mudo, microfone, LED, o alto-falante do próprio pad | feito em parte — A Cripta (microfone, mudo, LED às cegas, o grito no alto-falante do próprio controle); a voz devolvida pelo alto-falante não entrou; o eco se mede na bancada (`experimental/`, `eco`) |
| 4 | Toque | feito — O Molde |
| 4 | Fone: plugou, a mistura muda; tirou, alto-falante | feito — com o fone no jack (report USB, byte 53), o som do controle vai para o fone, nas duas orelhas, e volta ao alto-falante quando sai |
| 4 | Couro: PCM nos atuadores, sem o bit 1 do `flag0` | feito — Os Caminhos (canais 3 e 4) |
| 4 | Carga | parcial — a bateria e o "carregando" no cartão da mesa e no diagnóstico; a rodada que acaba com a bateria não entrou |
| 5 | GodotSteam | fica — é do jogo Godot; a Tech Demo fala SDL3 |
| 5 | action set local-coop | fica |
| 5 | trailer de 60 s | fica |
| 5 | checklist de palco | feito — o roteiro de validação com quatro DualSense no `README.md` |

O que entrou além do plano: o livro (o relatório por controle × feature), a
Prova de Fogo e o gauntlet sem aparelho (`scripts/gauntlet.sh`, ADR-003), a
bancada `experimental/`, e o CI com o binário Linux e o `.exe`.
