# FORJA — sprints (plano, não execução)

**Repo:** [AndreBFarias/forja](https://github.com/AndreBFarias/forja) · privado · `main` @ `07248b2` (13/09/2026)
**O que está no GitHub hoje:** empacotador C USB `0x02` + Godot 4.4 (Hub / Galeria / Impacto / Viga / Prova) + `./run-local.sh`.
**O que NÃO está no GitHub:** o preview web (eleição de modo, packer alinhado ao mapa USB do specs.html, WebHID, audio 4.0).
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
