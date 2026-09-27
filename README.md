# Hefesto Tech Demo — a Forja

Um jogo de festa **local**, para até quatro DualSense, que usa tudo o que o
controle tem — botões, analógicos, gatilhos adaptativos, giroscópio,
acelerômetro, touchpad, os dois motores, a lightbar, os LEDs de jogador, o
alto-falante, a háptica dos atuadores e o microfone com o botão de mudo — do
jeito que os jogos comerciais usam. Enquanto se joga, cada sala mede o que
chegou de cada controle e dá, por jogador, um veredito para cada feature:
**PASSOU**, **FALHOU** (com o que foi medido) ou **NÃO MEDIDO** (com o porquê).

É assim que o [Hefesto](https://github.com/Hefesto-Team/hefesto-dualsense4unix)
se valida: jogando. O jogo fala o DualSense como a Sony e a Steam documentam —
relatório USB `0x02`, os quatro modos oficiais de gatilho — e nunca fala com o
Hefesto. Quem estiver na frente do controle (o Hefesto, o kernel, um cabo) é
invisível; a mesa com quatro controles é o oráculo. A lei do repositório é o
[CONTRATO.md](CONTRATO.md).

## O jogo

- **A mesa** — cada jogador aperta ✕ e ganha o lugar P1…P4: a lightbar na cor
  do lugar, os LEDs de jogador no padrão do lugar, e um cartão com o nome, o
  VID:PID, USB ou rádio, e a origem do controle (DualSense nativo, DualSense
  Edge virtual por uhid, pad Xbox virtual por uinput).
- **O Salão da Forja** — o hub: cada porta é uma sala, e cada sala é um jeito
  que os jogos usam o controle ([docs/SALAS.md](docs/SALAS.md)):

| sala | chave | o padrão de jogo | valida |
| --- | --- | --- | --- |
| A Centelha | `centelha` | runas no tempo certo (QTE, ritmo) | botões, analógicos, gatilhos analógicos |
| A Viga | `viga` | equilíbrio e mira por movimento | giroscópio, acelerômetro |
| O Molde | `molde` | desenhar, abrir e carimbar no touchpad | touchpad com dois dedos, clique |
| O Cerco | `cerco` | o dano que vem de um lado, a vida na luz | motor forte e fraco, isolamento, lightbar |
| A Galeria | `galeria` | armas com gatilho adaptativo | resistência, arma, vibração, LEDs de jogador |
| A Cripta | `cripta` | terror: o silêncio, a voz, o susto | microfone, mudo, LED do microfone |
| Os Caminhos | `caminhos` | o chão que se sente na mão | háptica por áudio (canais 3 e 4) |
| O Canto | `canto` | o som que sai da mão | alto-falante do controle, isolamento do som |
| A Prova | `prova` | duas equipes, tudo ligado, 90 s | tudo junto, sob carga |

- **A Prova de Fogo** — todas as salas em ordem, com semente: o gauntlet.
- **O diagnóstico** — tudo o que chega de cada controle, ao vivo, e a taxa do
  giroscópio que o SDL declara ao lado da que chega.
- **O livro** — o relatório da sessão: controle × feature, o pedido, o medido
  e o veredito, gravado em `relatorios/relatorio-<sessão>.json` e `.txt`, com a
  linha do tempo `linha-do-tempo-<sessão>.jsonl`.

As saídas (vibração, luz, gatilho, LEDs, alto-falante, háptica) são provadas
**às cegas**: a tela não mostra o que o jogo mandou, e quem segura o controle
diz o que sentiu. O som de cada controle se acha como um jogo acha — pelo
aparelho, pelo número, pelo nome ([docs/COMO-O-SOM-CHEGA-AO-CONTROLE.md](docs/COMO-O-SOM-CHEGA-AO-CONTROLE.md)).

## O que tem aqui

| caminho | o que é |
| --- | --- |
| `demo/` | a Tech Demo: SDL3 em C (`demo/src`), as provas da lógica (`demo/testes`), as fontes (`demo/assets`) |
| `experimental/` | a bancada dos experimentos: latência, quatro microfones, eco, bytes do gatilho, háptica pelo nó do Hefesto |
| `docs/` | as salas, o som, e as decisões ([docs/adr](docs/adr/README.md)) |
| `scripts/` | `compilar.sh` (build reproduzível) e `gauntlet.sh` (a Prova de Fogo sem aparelho) |
| `include/`, `src/` | o empacotador USB `0x02` compartilhado, e as ferramentas de mesa `forja-send`, `forja-speak`, `forja-read` |
| `godot/` | o FORJA em Godot 4.4, o jogo de antes (`./run-local.sh godot`; arte Kenney Mini Dungeon, CC0) |
| `udev/` | a regra para ler e escrever o hidraw sem root |
| `.github/workflows/` | o CI: o binário Linux, o `.exe`, as provas e o gauntlet |

As ferramentas de mesa e o jogo Godot seguem documentados em
[COMO-RODAR.md](COMO-RODAR.md). O plano de sprints e onde cada um está: [SPRINTS.md](SPRINTS.md).

---

## Como compilar

O SDL 3.4.14 entra por versão **e** por sha256 — nunca o que a distro tiver —,
estático, e os caminhos da máquina saem do binário.

No Debian ou Ubuntu:

```sh
sudo apt install build-essential cmake ninja-build pkg-config \
  libasound2-dev libpulse-dev libpipewire-0.3-dev \
  libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxfixes-dev libxi-dev libxss-dev libxtst-dev libxkbcommon-dev \
  libwayland-dev wayland-protocols libdecor-0-dev libdrm-dev libgbm-dev libgl1-mesa-dev libegl1-mesa-dev \
  libdbus-1-dev libudev-dev
sudo apt install mingw-w64          # só para o .exe
```

```sh
scripts/compilar.sh linux      # build/linux/hefesto-tech-demo, e as provas da lógica
scripts/compilar.sh windows    # build/windows/hefesto-tech-demo.exe (mingw-w64)
scripts/compilar.sh testes     # só as provas, sem SDL
scripts/compilar.sh tudo       # os dois, e os pacotes em dist/
scripts/gauntlet.sh            # a Prova de Fogo com controles simulados, e cada defeito de mentira
```

O `.exe` é um arquivo só e depende apenas do que o Windows (e o Proton) já têm.
O CI faz o mesmo a cada push e deixa os dois pacotes como artefatos.

## Rodar no Linux

```sh
./run-local.sh
```

Compila o que faltar e abre o jogo; os relatórios vão para `relatorios/`.
Argumentos depois de `--` vão para o jogo:

```sh
./run-local.sh -- --gauntlet            # a Prova de Fogo
./run-local.sh -- --sala canto          # direto numa sala (a chave da tabela acima)
./run-local.sh -- --diagnostico         # direto no diagnóstico
./run-local.sh -- --experimento eco     # um experimento da bancada
./run-local.sh -- --simular 4 --robo    # sem controle: quatro de mentira, e um robô jogando
./run-local.sh -- --semente 42          # o mesmo sorteio, para comparar sessões
```

Para o jogo ler o report cru do DualSense no cabo (o jack do fone, os bytes do
gatilho) e para o `forja-send`, a regra do udev:

```sh
sudo cp udev/99-forja-dualsense.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
```

Na pausa (Options): "reduzir movimento" (tira o tremor e o clarão), as
legendas do som e a intensidade da vibração.

## Rodar o .exe pelo Proton

1. Baixe o pacote do Windows (o artefato `hefesto-tech-demo-windows-x86_64`
   do CI, ou `scripts/compilar.sh tudo`) e extraia numa pasta sua.
2. Na Steam: **Jogos → Adicionar um jogo não-Steam à minha biblioteca… →
   Procurar…**, troque o filtro para todos os arquivos e escolha
   `hefesto-tech-demo.exe`.
3. Na biblioteca, clique com o botão direito no jogo → **Propriedades →
   Compatibilidade → Forçar o uso de uma ferramenta de compatibilidade
   específica do Steam Play**, e escolha um Proton (o Experimental, ou o mais
   novo).
4. Em **Propriedades → Controle**, desative o Steam Input para este jogo: com
   ele ligado, o jogo recebe um controle Xbox e perde os gatilhos, o
   giroscópio e o resto do DualSense.
5. Os argumentos entram em **Propriedades → Geral → Opções de
   inicialização** (por exemplo `--gauntlet`). Os relatórios ficam em
   `relatorios/`, ao lado do `.exe`.

Sob o Proton, o jogo acha o som de cada controle pelo `ContainerId`, como os
ports de PS5; quando o Proton não o entrega, sobra o nome, e o aviso de cada
sala de som deixa conferir e trocar.

## Validar com quatro DualSense, passo a passo

O roteiro para quem valida o Hefesto na mesa. Duas rodadas: uma com os quatro
controles **no cabo** e outra com os quatro **no rádio**; depois, os dois
relatórios lado a lado.

**Antes:** a regra do udev instalada, o volume do computador ligado, uma sala
silenciosa para a Cripta, e o Hefesto na versão que se quer validar. Anote a
versão do Hefesto e a semente (`--semente`): a mesma semente refaz as mesmas
salas.

### No cabo

1. Ligue os quatro DualSense no USB e abra o jogo (`./run-local.sh -- --semente 7`).
2. No título, △ abre o **diagnóstico**: mexa em tudo em cada controle — os
   botões acendem, os analógicos andam, o giroscópio mostra a taxa declarada e
   a medida, a bateria, o fone, o mudo. ○ volta.
3. **Prova de Fogo** (ou **Jogar**, para escolher as salas no salão). Na
   mesa, cada um aperta ✕, na ordem P1…P4. Confira em cada controle: a
   lightbar na cor do cartão, os LEDs de jogador no padrão do lugar, e no
   cartão "USB", `054c:0ce6` e "DualSense nativo".
4. Em cada sala, leia o aviso: ele diz o que fazer e o que a sala valida. Nas
   salas de som, confira na linha de cada jogador o dispositivo achado —
   no cabo, "pelo aparelho" — e aperte △ para testar: o sino tem de sair no
   controle **dele**, e o pulso na esquerda e depois na direita.
5. Nas provas às cegas, responda pelo que sentiu, não pelo que a tela
   sugere; "não senti" é resposta.
6. No fim de cada sala, a tela mostra os vereditos de cada um; ✕ segue. No
   fim, o **livro** mostra a tabela inteira. Os arquivos estão em
   `relatorios/`: `relatorio-<sessão>.txt` para ler, `.json` e a linha do
   tempo para comparar.
7. O esperado no cabo, com DualSense nativos: tudo PASSOU, menos o que alguém
   não fez (e aí NÃO MEDIDO, com o porquê).

### No rádio

1. Pareie os quatro DualSense pelo Bluetooth, com o Hefesto rodando — ele
   cria o controle virtual de cada um e os nós de som «Alto-falante/Háptica/
   Microfone do Controle N».
2. Abra o jogo com a **mesma semente** e repita os passos do cabo.
3. Na mesa, o cartão diz a origem que o jogo vê: com o Hefesto na frente,
   "DualSense Edge virtual (uhid)" (ou "pad Xbox virtual (uinput)", conforme o
   modo do Hefesto). Um DualSense nativo no rádio, sem ninguém na frente,
   entra só com a entrada, e o cartão diz: *este jogo não fala o relatório
   0x31* ([ADR-005](docs/adr/005-o-radio-nativo-so-entrada.md)).
4. Nas salas de som, os dispositivos têm de aparecer "pelo número" (os nós do
   Hefesto). Sem eles, as features de som ficam NÃO MEDIDO, com o porquê.
5. A Prova diz se o controle aguentou tudo ligado: a entrada não pode parar e
   o SDL não pode recusar saída no meio da partida.

### Os dois relatórios

Ponha `relatorio-<cabo>.txt` e `relatorio-<rádio>.txt` lado a lado: cada
diferença é um trabalho para o Hefesto — a feature, o controle, o que foi
pedido e o que chegou. A bancada `experimental/` responde as perguntas que as
salas não fecham (latência do alto-falante, os quatro microfones juntos, o
eco, a háptica pelo nó); anote o que ela disser em
[experimental/RESULTADOS.md](experimental/RESULTADOS.md).
