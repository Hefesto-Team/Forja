# FORJA — sprints (plano, não execução)

**Repo:** [Hefesto-Team/Forja](https://github.com/Hefesto-Team/Forja) · `main` com os seis marcos do jogo 3D (28/09/2026)\
**O que está no GitHub hoje:** o jogo 3D em Godot 4.4 com o módulo nativo (SDL3), as nove salas, a Prova de Fogo, o relatório da sessão, as provas sem aparelho e a exportação (o binário Linux e o `.exe`).\
**Contrato:** o jogo fala Sony/Steam no cabo. Não fala Hefesto. Sem relatório `0x31`.

Este arquivo é backlog. Não começa trabalho sozinho. O plano de 13/09 (os
sprints 0 a 5) fica abaixo como foi escrito; onde ele chegou está nas tabelas
do fim, e o que falta, no backlog de 28/09.

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
| 3 | O Impacto e A Galeria às cegas: motores, isolamento, lightbar, os três modos de gatilho, LEDs de jogador | feito — as duas no 3D com o desenho do Cerco e da Galeria; o módulo dá o veredito às cegas pela régua de `cegas.c` (degrau obedeceu); o robô sente o que o controle simulado recebeu, e o gauntlet pega motores-trocados, vibra-vizinho, luz-parada, gatilho-mudo e leds-errados |
| 4 | o som pelo módulo (PipeWire, WASAPI e o `ContainerId`): A Voz com o microfone de cada controle e o susto, Os Caminhos, O Canto | feito — o som de cada controle no módulo (o SDL abre o som só na primeira sala de som; pelo aparelho, pelo número, pelo nome; o aviso mostra, troca e testa); as três salas no 3D com o desenho do Canto, dos Caminhos e da Cripta; o robô ouve e sente a placa virtual do controle simulado e fala no microfone dele; o gauntlet pega sem-alto-falante, som-vizinho, haptica-trocada, haptica-muda e mic-surdo |
| 5 | A Prova com tudo ligado, a Prova de Fogo em ordem, `experimental/` refeito para o 3D | feito — A Prova no 3D (a Brasa contra a Maré, a carga medida pelo módulo a cada quadro, a prova final às cegas) e a Prova de Fogo (as nove salas na ordem, e o livro no fim); o gauntlet pega o `engasga`; a bancada do `experimental/` volta dentro do jogo 3D (`--experimento=`), com a prova dela no CI |
| 6 | a exportação: o binário Linux e o `.exe` pelo Proton, no CI; o README fechado | feito — `scripts/exportar.sh` exporta os dois, com os modelos do Godot por versão e sha256 (só os dois que o jogo usa); a prova da exportação faz o robô jogar a Prova de Fogo inteira no binário Linux e no `.exe` pelo Wine, a base do Proton (a mesma matriz nos dois, nenhum falhou); o CI deixa os dois pacotes como artefatos; o README diz como baixar, exportar e rodar pelo Proton |

## O projeto fechado — 28/09/2026

Os seis marcos do jogo 3D estão feitos e integrados na `main`. O que o jogo
entrega, e onde se confere:

- **as nove salas como jogos**, cada uma medindo o que chegou de cada controle
  e dando o veredito por lugar e por feature — passou, falhou ou não medido,
  com o porquê; a Prova de Fogo joga as nove em ordem e fecha no livro;
- **o relatório da sessão** em `relatorios/` (o texto para ler, o JSON e a
  linha do tempo para comparar), sem endereço de aparelho nem caminho da
  máquina;
- **o jogo exportado**: o binário Linux e o `.exe` (o mesmo do Proton), com
  os dois pacotes como artefatos de cada execução do CI;
- **as provas sem aparelho**, a cada push: a lógica do módulo, a prova do jogo
  (o robô joga as salas com quatro DualSense simulados), o gauntlet (cada
  defeito de mentira tem de ser pego), a bancada do `experimental/` e a
  exportação (a Prova de Fogo inteira no binário Linux e no `.exe` pelo Wine);
- **os estudos** que guiaram a cara e o método, em
  [docs/estudos](docs/estudos/README.md).

Quem continua começa pelo [AGENTS.md](AGENTS.md) (a lei do repositório e os
comandos), pelo [CONTRATO.md](CONTRATO.md) e pelo backlog abaixo. Trabalho
novo começa por um item daqui — e, como o resto deste arquivo, a lista não
começa trabalho sozinha.

### O que ficou de fora dos seis marcos, e por quê

| item | por quê |
| --- | --- |
| GodotSteam, o action set do Steam Input e o trailer (sprint 5) | o jogo fala o DualSense pelo SDL3, como a Sony e a Steam documentam; com o Steam Input na frente, o jogo recebe um controle Xbox e perde o resto do DualSense. O trailer volta no sprint D |
| a rodada que acaba com a bateria (Carga) | no cabo, a bateria fica em 100% e carregando: o cartão do lobby mostra isso, e é o que há para mostrar |
| a voz devolvida pelo alto-falante do próprio controle | o eco se mede na bancada (`experimental/`, `eco`); no jogo, o susto d'A Voz sai no alto-falante de cada controle |
| o ícone e os metadados do `.exe` | trocá-los pede o rcedit rodando pelo Wine na exportação; o `.exe` sai com os do Godot (volta no sprint D) |
| o celular | a demo é para a TV e o desktop |
| o DualSense nativo no rádio com tudo | sem ninguém na frente, entra só com a entrada, e o cartão diz isso ([ADR-005](docs/adr/005-o-radio-nativo-so-entrada.md)); com o Hefesto na frente, entra inteiro |

## O que falta para um jogo completo — o backlog a partir de 28/09/2026

A Tech Demo valida o controle jogando, e cada sala já é um jogo. Para ser um
jogo de festa completo — que alguém baixa, joga uma noite inteira e quer
jogar de novo — falta o que está abaixo, na ordem. Cada sprint diz quando está
pronto.

### Sprint A — a rodada com quatro controles de verdade

O CI prova o jogo contra o simulador; falta o oráculo.

| item | detalhe |
| --- | --- |
| a rodada no cabo e no rádio | o roteiro do README com quatro DualSense, a mesma semente, os dois relatórios lado a lado; cada diferença vira um item aqui ou no Hefesto |
| o som de cada controle, de verdade | o alto-falante, a háptica (canais 3-4) e o microfone de cada controle achados pelo aparelho, no PipeWire e no WASAPI; e sob o Proton, onde um jogo tocando no controle do cabo "ainda não foi confirmada" ([estudo 01](docs/estudos/01-o-hefesto-por-dentro.md)) |
| a bancada com aparelho | `experimental/rodar.sh` com um controle no cabo: o laço, o eco e o gatilho pelo report cru deixam de dizer "não medido" |
| o `.exe` pelo Proton, na Steam | com o Steam Input desligado: os quatro controles, a luz, os gatilhos e o som |

**Pronto quando:** os dois relatórios da rodada (cabo e rádio) estão anotados
em `experimental/RESULTADOS.md`, e cada diferença tem dono.

### Sprint B — a partida de festa

Hoje cada sala dá vereditos; um jogo de festa também dá um vencedor.

| item | detalhe |
| --- | --- |
| os pontos da noite | cada sala já conta pontos por lugar (runas, alvos, golpes, o chão certo); somá-los numa partida, com o placar entre as salas e o pódio no fim — **feito**: a partida soma a colocação (4, 3, 2, 1; o empate divide), não os pontos crus, porque cada sala tem a sua régua; o placar depois de cada veredito, o pódio no salão, e o relatório registra os dois (`scripts/partida.gd`, [SALAS](docs/SALAS.md#a-partida--o-placar-e-o-pódio)) |
| a partida escolhida | 3, 5 ou as 9 salas; na ordem ou sorteadas (a semente já existe) — **feito**: □ na bigorna; na ordem, as curtas só com salas que não pedem o som do controle; sorteada, A Prova fecha sempre; `--partida=N --sorteada` |
| variação e dificuldade | cada sala com duas ou três variações (tempo, velocidade, quantos alvos) e um nível para quem joga pela primeira vez |
| menos de quatro | toda sala jogável com 1, 2 ou 3 (A Prova já faz: com três, dois contra um e um boneco de treino); a sala diz o que muda — **feito**: as nove salas já jogavam com menos; agora o aviso diz o que muda (A Prova, O Impacto e O Canto dizem o delas), e a prova de poucos (`tests/prova_de_poucos.sh`, no CI) faz o robô jogar as nove com 1, 2 e 3 controles: cada sala acaba sozinha, com veredito para quem está e nenhum "falhou" por faltar gente |
| a sala sem o recurso | com o microfone mudo, A Voz passa sozinha pela parte que pede voz (como o Astro faz com o sopro); sem alto-falante achado, O Canto diz e segue — o veredito fica "não medido", nunca "falhou" — **feito**: com o microfone mudo no sistema (silêncio absoluto, nem o ambiente chega), a vez dele no chamado passa e a HUD diz; sem alto-falante achado, o controle não canta, só responde; os dois vereditos ficam "não medido". O controle simulado agora ouve o ambiente de uma sala quieta, e o `mic-surdo` do gauntlet continua pego |

**Pronto quando:** quatro pessoas jogam uma partida de cinco salas, do lobby
ao pódio, sem ninguém explicar nada — e pedem outra.

### Mostrar, não contar — 28/09/2026

O aviso de cada sala era um parágrafo (de 150 a 530 caracteres) antes de
jogar, contra a regra 1 do [estudo 04](docs/estudos/04-minimalismo-e-o-dualsense-nos-jogos.md)
("no máximo 3 coisas novas por sala, porque texto longo não é lido"). Agora o
aviso mostra o nome, o verbo numa linha e os glifos do que se sente na mão; o
que muda com menos de quatro é um selo, não uma frase. As regras por extenso
ficam no código (`objetivo`) e no [SALAS](docs/SALAS.md); na tela, a sala
ensina jogando, pelas dicas curtas na raia de cada um.

| falta | detalhe |
| --- | --- |
| o boneco mostra | no aviso, o boneco de cada um repete o gesto da sala (o Astro faz assim: a bola rola, o zíper abre) e o controle dá uma amostra do que vem — fora das provas às cegas |
| a primeira rodada ensina | a primeira runa, o primeiro alvo, o primeiro golpe valem sem pressa e sem ponto; a dica some quando a pessoa acertou uma vez |
| o veredito enxuto | ✓ ou ✗ grande por feature; o que foi medido só no que falhou (o resto fica no livro) |

### Sprint C — conforto e acessibilidade

Os estudos [02](docs/estudos/02-manuais-de-ui-e-ux.md) e
[04](docs/estudos/04-minimalismo-e-o-dualsense-nos-jogos.md) trazem os
números; falta o menu.

| item | detalhe |
| --- | --- |
| opções por jogador | gatilho Desligado / Fraco / Forte e vibração de 0 a 100%, por lugar, no lobby e na pausa (como o GT7) |
| opções da sessão | o volume da TV e o do alto-falante do controle, o tremor da câmera e os flashes desligáveis, tela cheia ou janela, o tamanho do texto |
| o checklist do estudo 02 | os 31 itens conferidos tela por tela: texto de leitura ≥ 30 px, a área segura, um foco só (contorno de 4 px), ✕ confirma e ○ volta, nada de segurar para confirmar, o aviso pulável a partir da segunda vez |
| a cor nunca sozinha | as capturas passadas por simulação de protanopia, deuteranopia e tritanopia; o veredito sempre com palavra |
| as opções guardadas | num arquivo de configuração do usuário (por máquina, nunca por aparelho) |

**Pronto quando:** o checklist do estudo 02 passa inteiro numa TV de 40" a 3 m
e na tela do Steam Deck.

### Sprint D — som, música e acabamento

| item | detalhe |
| --- | --- |
| a música | uma trilha do salão e uma por sala, com o volume do menu; a música se cala quando a sala pede silêncio (A Voz, O Canto) |
| o som da TV | os efeitos de hoje são sintetizados (`scripts/som.gd`); gravar ou licenciar os que pedem corpo (o martelo, o golpe, o sino) |
| a arte das salas | os bonecos reagindo (ao veredito, ao golpe, à vitória), partículas e luz por sala, as transições |
| o título e os créditos | a tela de título com a bigorna, e os créditos com as licenças (os modelos Kenney, CC0; as fontes, OFL; o SDL, zlib; o Godot e o godot-cpp, MIT; os glifos e o mapa do app Hefesto, MIT) |
| o ícone do jogo | o ícone e os metadados do `.exe` (o rcedit pelo Wine na exportação) e o `.desktop` do Linux |
| o trailer | os 60 s do sprint 5, agora com as salas 3D |

**Pronto quando:** o trailer sai sem nenhum corte para esconder tela crua.

### Sprint E — robustez e alcance

| item | detalhe |
| --- | --- |
| o controle que cai | tirar o cabo no meio de cada sala: a sala segue, o lugar espera, o controle volta ao mesmo lugar — a regra do sprint 1, conferida sala por sala no 3D |
| o Steam Deck | 1280×800 a 60 quadros, com os DualSense pelo Bluetooth ou pelo dock |
| o inglês | as telas e o README em inglês, com o português como padrão |
| a distribuição | um AppImage ou Flatpak no Linux, e os pacotes da exportação como release no GitHub a cada tag |
| as telas no CI | as fotos que o `testes/captura_jogo.gd` já tira, comparadas com as da versão anterior |

**Pronto quando:** o jogo roda no Deck e num PC com Windows, com quatro
DualSense, a partir do pacote baixado, sem compilar nada.

### Fora do escopo, de propósito

O online (o jogo é local); o relatório `0x31` do rádio e tudo o que é do
Hefesto por dentro (o socket, o `uniq`, o CRC); o DSX; e o SDK oficial da
Sony, que é sob NDA — não se usa, não se procura, não se reproduz.

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
