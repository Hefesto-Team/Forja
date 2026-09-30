# Forja — onde estamos e o que falta

**Hoje (30/09/2026):** a primeira noite de teste aconteceu. As nove salas
funcionaram, e o Forja cumpriu o objetivo inicial: cada recurso do DualSense
provado jogando. Ela também mostrou o que falta para ser um jogo de verdade:
o jogo pergunta ao jogador se o controle obedeceu, manda olhar o LED, termina
salas numa tabela de veredito; não tem introdução nem criação de personagem;
o HUD é fixo e a câmera não segue ninguém; o háptico é ultra fraco e o som no
controle quase não aparece; no rádio nada se repetiu; o P1 da tela não era o
P1 do controle. O diagnóstico inteiro, com arquivo e linha, está em
[docs/jogo/01-diagnostico.md](docs/jogo/01-diagnostico.md).

**Agora é a vez de tornar o jogo bom e viciante para quatro pessoas jogarem
de quatro a seis horas sem cansar.** A direção está em
[docs/jogo/](docs/jogo/README.md): 45 minigames (nove seções, cinco jogos
cada), o ritmo medido pelo relógio de áudio, háptico forte, a construção do
cavaleiro, e uma noite de seis horas que valida tudo pelo registro.

**Contrato:** o jogo fala Sony/Steam no cabo. Não fala Hefesto. Sem relatório `0x31`.

## O que ainda falta

| o quê | por quê | sprint |
| --- | --- | --- |
| tirar o teste de dentro do jogo | quiz, veredito e "olhe o LED" quebram o jogo; a validação vai para o registro | F |
| háptico forte e o P1 certo | o controle falou baixo e trocou de número | F |
| todo minigame fecha com vencedor | tela vazia e relógio que volta não são fim | F |
| as telas de um jogo | título, introdução, construção do cavaleiro, HUD de cada jogador, câmera, os doze bonecos e a arte coerente | G |
| o ritmo, o som e o kit | relógio de áudio, janelas, calibração, as 45 faixas, jingles, som no controle em todo evento, o kit do minigame | H |
| os 45 minigames | cinco por seção, com a sala de hoje como o primeiro | I a Q |
| o Relâmpago | microjogos para aquecer e desempatar | R |
| a noite de seis horas | o teste final com quatro pessoas, dois no cabo e dois no rádio | S |

O trabalho anda pelo [quadro de fichas](docs/jogo/tarefas/README.md): uma
ficha por sessão, na ordem do quadro, sem data. F primeiro, porque tudo
depende dela. G e H podem andar juntas; as seções vêm depois do kit do
minigame (H04), uma por vez. R depois das seções, S por último. Os itens do
Sprint A que continuam valendo (o `.exe` pela Steam, a TV de 40" a 3 m, o
Steam Deck) entram na noite de seis horas. O método e o orçamento estão em
[docs/jogo/12-como-trabalhar.md](docs/jogo/12-como-trabalhar.md).

## O jogo completo — as sprints a partir de 30/09/2026

Cada sprint começa pelo documento dela em [docs/jogo/](docs/jogo/README.md)
e respeita as [regras de ouro](docs/jogo/README.md#as-regras-de-ouro).

### Sprint F — a fundação

Fichas: F00 a F10, no [quadro](docs/jogo/tarefas/README.md).

O jogo deixa de ser teste, e o controle passa a falar alto e com o número
certo.

| item | detalhe |
| --- | --- |
| o Modo bancada | o veredito ✓/✗, as perguntas das salas às cegas, o diagnóstico ao vivo, o livro da sessão e a bancada dos experimentos saem do jogo e vão para `--bancada`, fora do menu; a tela de fim de sala perde a tabela de veredito ([01](docs/jogo/01-diagnostico.md#o-jogo-parece-um-teste)) |
| nenhuma frase metalinguística | "olhe o controle…", "olhe a luz", "o canto saiu do seu controle?", "Que chão é esse?", as features no aviso e o hardware no portão saem; cada sala pede um verbo do mundo ([02](docs/jogo/02-principios.md#1-o-controle-é-mundo-não-prova)) |
| todo minigame fecha | o apito, o resultado com vencedor e colocação, o jingle e a volta, também fora de partida; o relógio não volta depois do treino; o aviso começa sozinho em oito segundos; a bancada emite `terminou` ([02](docs/jogo/02-principios.md#7-todo-minigame-fecha)) |
| o P1 é o controle P1 | o lugar e as luzinhas na conexão, não no ✕; controle estranho não herda lugar; nenhuma sala usa as luzinhas nem a barra de luz de um jeito que apague a identidade ([05](docs/jogo/05-haptica-e-controle.md#a-identidade-p1p4)) |
| as sete suspeitas do háptico | medir cada uma (firmware, modo suave, dono do motor, rumble contra háptica por áudio, escala salva) antes de mudar valores; registrar o firmware na conexão ([05](docs/jogo/05-haptica-e-controle.md#por-que-o-háptico-está-fraco)) |
| o piso de força | as salas pedem eventos, não números; a tabela de eventos com o piso de [05](docs/jogo/05-haptica-e-controle.md#o-piso-de-força); nenhum `Input.start_joy_vibration` |
| a decisão do rumble seco | votar, com a medição na mão, se o contrato ganha uma emenda para o bloco próprio de rumble ([05](docs/jogo/05-haptica-e-controle.md#a-força-máxima-que-é-legítima)) |
| o registro v2 | `seq`, tempo de parede de verdade, `transporte`, `firmware`, os tipos `saida`, `som_controle`, `nota`, `toque`, `minigame`; o `formato` sobe de versão ([08](docs/jogo/08-a-noite-de-6-horas.md#o-registro-v2)) |
| a voz nova do texto | toda frase de tela começa com maiúscula, botão como "Botão ✕ (Iniciar)"; as 233 frases de `traducoes.gd` e os textos montados; "fechar" ganha tradução; o portão `scripts/check_texto_de_tela.py` entra antes do push ([06](docs/jogo/06-telas-e-fluxo.md#a-voz-do-texto)) |

**Pronto quando:** uma partida de nove salas vai do título ao pódio sem uma
pergunta sobre o controle, sem uma tabela de veredito e sem uma frase em
minúscula; cada sala acaba com um vencedor na tela; o P1 da tela é o P1 do
controle desde a conexão; a prova do jogo, o gauntlet e a prova de poucos
passam; e a linha do tempo sai no formato v2.

### Sprint G — as telas

Fichas: G01 a G11, no [quadro](docs/jogo/tarefas/README.md) (a G09 é o teclado do nome; a G10 e a G11, a Kenney — [14](docs/jogo/14-os-assets-kenney.md)).

| item | detalhe |
| --- | --- |
| título e introdução | a forja acendendo no ritmo; a introdução sem texto na primeira vez da noite ([06](docs/jogo/06-telas-e-fluxo.md#as-telas)) |
| a construção do cavaleiro | boneco, acabamento, peça, item, nome e as oito marteladas que calibram; é também o lobby ([06b](docs/jogo/06b-a-construcao-do-cavaleiro.md)) |
| o item com mecânica | Martelo, Escudo, Fole, Lanterna, Diapasão e Âncora, cada um visto no HUD e sentido no controle ([06b](docs/jogo/06b-a-construcao-do-cavaleiro.md#o-item-tem-mecânica)) |
| o HUD de cada jogador | um canto por jogador, ancorado, com área segura; nunca abaixo de 30 px; conferido nas duas escalas e nas duas línguas ([06](docs/jogo/06-telas-e-fluxo.md#o-hud-de-cada-jogador)) |
| a câmera dos quatro | enquadra quem está vivo, suave, com mínimo e máximo por minigame ([06](docs/jogo/06-telas-e-fluxo.md#a-câmera)) |
| o salão e a coleção | os portões com o nome da seção, a vitrine da noite ([06b](docs/jogo/06b-a-construcao-do-cavaleiro.md#a-coleção)) |
| a narrativa leve | a Dissonância, os Cavaleiros de Néon, as falas curtas e o vocabulário do visor ([07](docs/jogo/07-narrativa-e-voz.md)) |
| a arte: bonecos e coerência | doze bonecos no mesmo esqueleto, as peças de identidade, o guardião d'A Voz refeito e o checklist de arte ([11](docs/jogo/11-arte-e-personagens.md)) |

**Pronto quando:** alguém que nunca jogou liga o jogo, constrói o cavaleiro
e chega ao primeiro minigame sem ler nada além de títulos e verbos; as fotos
das telas (`tests/telas.sh`) não mostram colisão em nenhuma escala.

### Sprint H — o ritmo, o som e o kit do minigame

Fichas: H01 a H09, no [quadro](docs/jogo/tarefas/README.md).

| item | detalhe |
| --- | --- |
| o relógio de áudio | a posição da música pelo guia do Godot, com a latência em cache e o início agendado; tudo que se move no ritmo é calculado da batida ([04](docs/jogo/04-ritmo-e-audio.md#o-relógio-de-áudio)) |
| as janelas | perfeito −40/+60 ms, ótimo ±90, bom ±140, erro; a ajuda escondida para quem está atrás ([04](docs/jogo/04-ritmo-e-audio.md#as-janelas)) |
| a calibração | o desvio de cada controle pelas marteladas, ajustável nas opções do lugar ([04](docs/jogo/04-ritmo-e-audio.md#a-calibração-que-ninguém-vê)) |
| as 45 faixas | slots `MUS_Sxx_Jyy`, o mapa de batidas de cada uma, as quatro faixas novas, as faixas das telas; tudo dentro do git, em `godot/assets/ost/` ([04](docs/jogo/04-ritmo-e-audio.md#as-45-faixas)) |
| o gerador da trilha | `scripts/gerar_trilha.py` com o ACE-Step 1.5 (modelo aberto) no desktop do André: candidatas por faixa, o andamento conferido, a página de escuta ([H09](docs/jogo/tarefas/H09-o-gerador-da-trilha.md)) |
| os jingles | apito, vitória, vitória coop, derrota, empate, recorde, entrada, virada ([04](docs/jogo/04-ritmo-e-audio.md#as-telas-e-os-jingles)) |
| a música que reage | filtro no erro, brilho no combo, rampas de 15 a 30 ms, e as camadas quando houver stems ([04](docs/jogo/04-ritmo-e-audio.md#a-música-que-reage)) |
| o som no controle em todo evento | a placa de áudio de cada controle aberta na entrada do lugar; a agenda do alto-falante; a háptica por material ([05](docs/jogo/05-haptica-e-controle.md#a-agenda-do-alto-falante)) |
| o kit do minigame | o que as salas repetem sobe para `SalaJogo`, e cada minigame vira uma ficha de dados mais os ganchos dele ([molde](docs/jogo/tarefas/molde-de-minigame.md)) |

**Pronto quando:** um minigame de teste toca uma faixa com mapa de batidas,
julga cada toque pelas janelas com o desvio da calibração, e todo evento tem
som na TV e algo no controle do dono; o registro mostra `t_musica` em cada
`nota` e cada `toque`.

### Sprints I a Q — as nove seções

Fichas: I a Q, no [quadro](docs/jogo/tarefas/README.md).

Uma sprint por seção, cinco minigames cada, na ordem: **I** A Centelha,
**J** A Viga, **K** O Molde, **L** O Impacto, **M** A Galeria, **N** O Canto,
**O** Os Caminhos, **P** A Voz, **Q** A Prova. As fichas de cada minigame
estão em [docs/jogo/03-os-45-minigames.md](docs/jogo/03-os-45-minigames.md).

| item | detalhe |
| --- | --- |
| a sala de hoje, reescrita | o primeiro minigame de cada seção é a sala atual, sem quiz, sem veredito, no relógio de áudio |
| os quatro novos | prototipar mais de quatro ideias e ficar com as melhores; cada um com um verbo diferente dos outros da seção |
| pelo menos uma dupla | cada seção tem um minigame de dupla e um de todos contra todos |
| o repertório inteiro | vibração, barra de luz, alto-falante e gatilho em todo minigame, além da feature da seção ([02](docs/jogo/02-principios.md#2-a-feature-protagoniza-o-repertório-acompanha)) |
| o que o registro mede | a validação da feature, sem perguntar nada ao jogador |
| a régua | as três perguntas de aprovação de [10](docs/jogo/10-a-regua-astro-bot.md#a-pergunta-de-aprovação) |

**Pronto quando** (para cada seção): os cinco minigames jogam do aviso ao
resultado com quatro, três, dois e um jogador, com o robô; o gauntlet e a
prova de poucos passam; e a partida sorteada já os inclui.

### Sprint R — o Relâmpago

Fichas: R, no [quadro](docs/jogo/tarefas/README.md).

| item | detalhe |
| --- | --- |
| os microjogos | de 5 a 8 segundos, tirados dos 45, com um verbo de uma palavra ([03](docs/jogo/03-os-45-minigames.md#o-relâmpago)) |
| a aceleração | a faixa `MUS_RELAMPAGO` sobe o andamento a cada cinco microjogos |
| aquecimento e desempate | abre a noite e decide empates no placar |

**Pronto quando:** três minutos de Relâmpago passam por microjogos das nove
seções sem uma tela de carregamento.

### Sprint S — a noite de seis horas

Fichas: S, no [quadro](docs/jogo/tarefas/README.md).

| item | detalhe |
| --- | --- |
| o protocolo | quatro pessoas, dois no cabo e dois no rádio, trocando na metade; seis horas com pausas ([08](docs/jogo/08-a-noite-de-6-horas.md#o-protocolo)) |
| o cruzamento | `scripts/cruzar_noite.py` casa o registro do jogo com o da ponte e com os toques, por controle e por transporte ([08](docs/jogo/08-a-noite-de-6-horas.md#o-cruzamento)) |
| o que sobrou do Sprint A | o `.exe` pela Steam, a TV de 40" a 3 m, o Steam Deck |
| o que vem depois | cada número do cruzamento vira um item aqui |

**Pronto quando:** os quatro jogam seis horas com vontade, e o cruzamento
responde por controle e por transporte: quanto o jogo mandou, quanto chegou
e quanto o jogador percebeu.

---

## Como este arquivo se lê

Daqui para baixo é o histórico, como foi escrito: o plano de 13/09 (os
sprints 0 a 5), onde ele chegou, o backlog de 28/09 (os sprints A a E) com o
que cada item virou, e o que ficou de fora de propósito. Este arquivo é
backlog: não começa trabalho sozinho.

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
| variação e dificuldade | cada sala com duas ou três variações (tempo, velocidade, quantos alvos) e um nível para quem joga pela primeira vez — **feito em parte**: o ritmo da sessão (primeira vez, normal, rápido; `--nivel=0..2`), escolhido na partida, estica ou encurta as janelas de tempo (a runa, o escudo, o tiro, o tempo da sala, a partida d'A Prova) sem mudar a quantidade de medidas; a prova de poucos joga os ritmos. As variações de conteúdo (quantos alvos, outra arena) ainda não |
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

| item | situação |
| --- | --- |
| o boneco mostra | feito — o aviso sobe para o alto e deixa a arena à mostra; o boneco de quem não está pronto repete o gesto da sala (martela, atira, toca o molde, levanta o escudo de um lado e do outro). A amostra no controle ficou de fora: no aviso os analógicos medem a deriva, e um motor ligado ali sujaria a medida |
| a dica aprendida vira glifo | feito — depois de três acertos na sala, a dica da raia perde as palavras e fica só o glifo; sem glifo, some |
| a primeira rodada ensina | feito — toda sala começa em treino: três acertos de cada um (ou 15 s) sem valer ponto, e aí o "Valendo!" |
| o veredito enxuto | feito — uma linha por feature (o glifo e o nome), um selo por lugar; o porquê só no que não passou; o resto no livro |

### Sprint C — conforto e acessibilidade

Os estudos [02](docs/estudos/02-manuais-de-ui-e-ux.md) e
[04](docs/estudos/04-minimalismo-e-o-dualsense-nos-jogos.md) trazem os
números; falta o menu.

| item | detalhe |
| --- | --- |
| opções por jogador | gatilho Desligado / Fraco / Forte e vibração de 0 a 100%, por lugar, no lobby e na pausa (como o GT7) — **feito**: △ no lobby (antes de ficar pronto) ou Opções na pausa; a vibração dá um toque na força nova; o recurso desligado nas opções deixa o veredito da feature "não medido", com o porquê, nunca "falhou" |
| opções da sessão | o volume da TV e o do alto-falante do controle, o tremor da câmera e os flashes desligáveis, tela cheia ou janela, o tamanho do texto — **feito** (o texto: normal ou grande, ×1,15) |
| o checklist do estudo 02 | os 31 itens conferidos tela por tela: texto de leitura ≥ 30 px, a área segura, um foco só (contorno de 4 px), ✕ confirma e ○ volta, nada de segurar para confirmar, o aviso pulável a partir da segunda vez — **conferido**: [CHECKLIST-DO-ESTUDO-02](docs/CHECKLIST-DO-ESTUDO-02.md), 30 ok e 1 que falta (o teste na TV e no Deck) |
| a cor nunca sozinha | as capturas passadas por simulação de protanopia, deuteranopia e tritanopia; o veredito sempre com palavra — **feito**: `scripts/daltonismo.gd` faz as pranchas; a cor de cada lugar é clareada até 3:1 nas quatro visões |
| as opções guardadas | num arquivo de configuração do usuário (por máquina, nunca por aparelho) — **feito**: `user://opcoes.cfg`; as provas não leem nem gravam |

**Pronto quando:** o checklist do estudo 02 passa inteiro numa TV de 40" a 3 m
e na tela do Steam Deck.

### Sprint D — som, música e acabamento

| item | detalhe |
| --- | --- |
| a música | uma trilha do salão e uma por sala, com o volume do menu; a música se cala quando a sala pede silêncio (A Voz, O Canto) — **feito**: synthwave sintetizado no módulo (`sint_trilha`: pad de serras, baixo em colcheias, arpejo com eco, bateria de máquina), oito compassos em laço sem emenda, com tônica, andamento e energia por sala; cala n'A Voz, n'O Canto e na bancada |
| o som da TV | os efeitos de hoje são sintetizados (`scripts/som.gd`); gravar ou licenciar os que pedem corpo (o martelo, o golpe, o sino) — **feito**: os efeitos de sabor são gravações CC0 da Kenney (`assets/sons/`, várias versões de cada, com o tom levemente sorteado), na TV e no alto-falante de cada controle (o módulo recebe a gravação: `som_registrar`); o martelo soa na mão de quem martelou, o tiro na de quem atirou, o golpe na de quem apanhou, e a fanfarra na do vencedor. Os sons que as salas medem (as notas, os passos, o sino e o pulso de teste) seguem sintetizados, e nas provas às cegas nada soa no controle antes da resposta |
| a arte das salas | os bonecos reagindo (ao veredito, ao golpe, à vitória), partículas e luz por sala, as transições — **feito**: no veredito, quem passou em tudo comemora, quem falhou balança a cabeça, e quem fez mais pontos ganha as faíscas na cor do lugar; cada sala tem o seu clima (as partículas do ar, o preenchimento de cor, os neons na parede do fundo) e pulsa a luz no "Valendo!" e no fim; o aviso entra deslizando e a troca de cena tem o seu som |
| a gincana | a primeira rodada de cada sala é **treino**: não vale ponto, o erro não tira, e acaba quando cada um acertou uma vez (ou em 15 s) — aí o "Valendo!" e o relógio devolve o tempo; o placar entre as salas conta os pontos subindo, troca as linhas de lugar, marca quem lidera e grita a virada; o pódio sobe em blocos pela colocação, com confete, a fanfarra e a faixa de festa — **feito** |
| o título e os créditos | a tela de título com a bigorna, e os créditos com as licenças (os modelos Kenney, CC0; as fontes, OFL; o SDL, zlib; o Godot e o godot-cpp, MIT; os glifos e o mapa do app Hefesto, MIT) — **feito em parte**: △ no título abre os créditos, só "Hefesto Team" sobre o sol do synthwave; as licenças vão com o jogo em `assets/LEIA-ME.md` e nos textos ao lado de cada coisa |
| o ícone do jogo | o ícone e os metadados do `.exe` e o `.desktop` do Linux — **feito**: o `.desktop` e o ícone no pacote Linux e no AppImage; o `.exe` ganha o ícone e a versão pelo `scripts/icone_do_exe.py` (Python puro, sem rcedit nem Wine), e a prova da exportação confere os dois |
| o trailer | os 60 s do sprint 5, agora com as salas 3D — **feito**: `scripts/trailer.sh` grava o jogo rodando pelo Movie Maker do Godot (o título, o lobby, A Galeria, O Impacto, A Viga, O Molde, A Prova, o pódio e os créditos, em 70 s), sem corte nenhum; com um ffmpeg no PATH, sai também o `.mp4` |

**Pronto quando:** o trailer sai sem nenhum corte para esconder tela crua.

### Sprint E — robustez e alcance

| item | detalhe |
| --- | --- |
| o controle que cai | tirar o cabo no meio de cada sala: a sala segue, o lugar espera, o controle volta ao mesmo lugar — a regra do sprint 1, conferida sala por sala no 3D — **feito**: o simulador tira e põe o cabo (`simulador_cabo`); a prova de poucos tira o do P2 no meio de cada uma das nove salas. Ela achou dois defeitos, corrigidos: a medida dos sensores guardava a contagem do controle antigo (A Viga dava "falhou" ao P2 que voltou) e A Prova contava como recusa do SDL a saída mandada com o cabo fora. Agora ninguém sai com "falhou" por perder o cabo |
| o Steam Deck | 1280×800 a 60 quadros, com os DualSense pelo Bluetooth ou pelo dock — **feito em parte**: as fotos a 1280×800 mostraram as telas inteiras (o `expand` dá conta) e o 3D cortando as raias da ponta; em telas mais estreitas que 16:9, a câmera agora guarda a largura. Os 60 quadros e os controles pelo dock pedem o aparelho |
| o inglês | as telas e o README em inglês, com o português como padrão — **feito**: todo texto das telas passa por `Traducoes` (a frase exata, ou um padrão com os números); a lista saiu de uma coleta do que as telas desenham jogando todas as salas; **Idioma** nas opções, `FORJA_IDIOMA=en` para as fotos; o `README.en.md`. O porquê de cada veredito e o relatório vêm do núcleo em C e ficam em português |
| a distribuição | um AppImage ou Flatpak no Linux, e os pacotes da exportação como release no GitHub a cada tag — **feito**: `scripts/exportar.sh appimage` (o appimagetool 1.9.0 por sha256, o runtime tirado dele mesmo); a prova da exportação joga a Prova de Fogo no AppImage e confere a mesma matriz do binário; a cada tag, o job `release` publica o `.tar.gz`, o `.zip` e o AppImage. Os pacotes levam `LICENCAS.txt` (o `LICENCAS-DE-TERCEIROS.md` e os avisos do Godot tirados do binário) |
| as telas no CI | as fotos que o `testes/captura_jogo.gd` já tira, comparadas com as da versão anterior — **feito**: o job `telas` fotografa nove telas (`tests/telas.sh`), compara com as da versão anterior do branch (o cache) e deixa as pranchas de diferença e de daltonismo como artefato; relata, não reprova (o 3D por software varia entre máquinas) |

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
