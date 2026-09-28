# Hefesto Tech Demo — a Forja

Um jogo de festa **local**, em 3D, para até quatro DualSense, que usa o que o
controle tem — botões, analógicos, gatilhos adaptativos, giroscópio,
acelerômetro, touchpad, os dois motores, a lightbar, os LEDs de jogador, o
alto-falante, a háptica dos atuadores e o microfone com o botão de mudo — do
jeito que os jogos comerciais usam. Enquanto se joga, cada sala mede o que
chegou de cada controle e dá, por jogador, um veredito para cada feature:
**passou**, **falhou** (com o que foi medido) ou **não medido** (com o porquê).

É assim que o [Hefesto](https://github.com/Hefesto-Team/hefesto-dualsense4unix)
se valida: jogando. O jogo fala o DualSense como a Sony e a Steam documentam —
relatório USB `0x02`, os quatro modos oficiais de gatilho, player index 0..3 —
e nunca fala com o Hefesto. Quem estiver na frente do controle (o Hefesto, o
kernel, um cabo) é invisível; quatro controles na mão são o oráculo. A lei do
repositório é o [CONTRATO.md](CONTRATO.md).

## O jogo

Godot 4.4 desenha; um módulo nativo com o SDL3 dentro fala com os controles
([ADR-007](docs/adr/007-o-jogo-e-o-3d-em-godot.md)). A cara é a do app
Hefesto: a paleta dele, Space Grotesk e JetBrains Mono, os glifos e o mapa do
controle desenhados para o app.

- **O lobby** — cada jogador aperta ✕ e ganha o lugar P1…P4: a lightbar na cor
  do lugar, os LEDs de jogador no padrão do lugar (1 | vão | 3 | vão | 1), o
  boneco no pedestal da cor, e um cartão com o nome, o VID:PID, USB ou BT e a
  origem (DualSense nativo, DualSense Edge virtual, Xbox virtual). Cada lugar
  nasce com um visual próprio, e cada um escolhe o seu antes de ficar pronto:
  ◀▶ o boneco (humano ou orc), ▲▼ o que ele leva (espada, lança, escudo,
  poção, chave). A cor não se escolhe: é a do lugar, a mesma da lightbar. ✕ de
  novo fica pronto; com todos prontos, a partida começa.
- **O salão da forja** — o hub: a bigorna no meio e oito portões, um por sala,
  na ordem do percurso. Perto de um portão, a placa diz a sala e ✕ entra.
- **O diagnóstico ao vivo** (Create) — uma coluna por lugar com o mapa do
  controle (o desenho do app, com a peça apertada em rosa, o analógico andando,
  o dedo no touchpad, o motor laranja, a barra de luz na cor mandada) e os
  números da entrada e da saída.
- **O livro** (Options → O livro da sessão) — o relatório na tela: feature ×
  lugar, o pedido, o medido, o degrau da evidência. O mesmo conteúdo vai para
  `relatorios/relatorio-<sessão>.json` e `.txt`, com o registro e a linha do
  tempo `linha-do-tempo-<sessão>.jsonl`.

As salas, e em que marco cada uma ganha o comportamento de jogo comercial
([docs/SALAS.md](docs/SALAS.md)):

| sala | valida | agora |
| --- | --- | --- |
| A Centelha | botões, analógicos, gatilhos analógicos | o jogo: a runa acende em cima da bigorna de cada um; apertar a tempo martela; o círculo do analógico e o fole do gatilho |
| A Viga | giroscópio, acelerômetro | o jogo: a travessia sobre a lava (incline contra o vento), os sinos na mira do giroscópio, a pedra que quebra na martelada |
| O Molde | touchpad com dois dedos, clique | o jogo: o molde é o touchpad; trace a letra, abra e feche com dois dedos, carimbe com o clique |
| O Impacto | motor forte e fraco, isolamento, lightbar | o jogo, às cegas: no escuro, o golpe treme só o motor do lado e você levanta o escudo daquele lado (L1/R1); a luz pisca no golpe e apaga com a vida; no fim da onda, a cor da luz, olhando o controle |
| A Galeria | resistência, arma, vibração, LEDs de jogador | o jogo, às cegas: a arma chega no baú fechado e se reconhece pelo gatilho (parede e clique, tremor, peso, solto); a munição nas luzinhas, contadas no controle |
| A Voz | microfone, mudo, LED do microfone | o jogo: o guardião da cripta escuta pelo microfone do SEU controle — o silêncio de todos, cada um chama na sua vez (a chama sobe com a voz), o mudo acende a luz laranja; a luz do microfone às cegas; e o susto no alto-falante e nos motores |
| Os Caminhos | háptica por áudio (canais 3 e 4) | o jogo, às cegas: no escuro, o chão só existe nos atuadores — grama, cascalho, metal, água; diga o chão a cada três passos, e o lado da pedra no tropeço (L1/R1) |
| O Canto | alto-falante do controle | o jogo, às cegas: a bigorna canta no alto-falante de UM controle ou na TV; saiu da sua mão? (✕/○); o dono repete o ritmo |
| A Prova | tudo junto, duas equipes | aberta (R2 arma, L2 resistência, a luz cai com a vida); marco 5 |

## O que tem aqui

| caminho | o que é |
| --- | --- |
| `godot/` | o jogo: cenas, scripts (`scripts/`: o salão, os jogadores, as salas, a interface), a arte (Kenney Mini Dungeon, CC0; o mapa do controle e os glifos do app Hefesto, MIT — ver `godot/assets/LEIA-ME.md`) |
| `nativo/` | o módulo nativo: `nucleo/` (relatório, vereditos, origem do controle, simulador, linha do tempo — C), `godot/` (a GDExtension, C++), `testes/` (as provas da lógica) |
| `include/`, `src/` | o empacotador USB `0x02` compartilhado, e as ferramentas de bancada `forja-send`, `forja-speak`, `forja-read` |
| `scripts/` | `compilar.sh` (o build reproduzível do módulo), `gauntlet.sh` (a prova com defeitos de mentira), `mapa_do_controle.js` (as camadas do mapa, dos SVGs do app) |
| `tests/` | a prova do jogo (Godot headless, quatro DualSense simulados) e a prova do som |
| `experimental/` | a bancada dos experimentos e os resultados anotados |
| `docs/` | as salas, o som, e as decisões ([docs/adr](docs/adr/README.md)) |
| `udev/` | a regra para ler e escrever o hidraw sem root |

As ferramentas de bancada seguem em [COMO-RODAR.md](COMO-RODAR.md). O plano e
onde cada marco está: [SPRINTS.md](SPRINTS.md).

---

## Como compilar

O módulo leva o SDL 3.4.14 (por versão **e** sha256) e o godot-cpp da série
4.4 (por tag **e** commit) — nunca o que a distro tiver —, e os caminhos da
máquina saem do binário.

No Debian ou Ubuntu:

```sh
sudo apt install build-essential cmake ninja-build pkg-config git curl unzip \
  libasound2-dev libpulse-dev libpipewire-0.3-dev \
  libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxfixes-dev libxi-dev libxss-dev libxtst-dev libxkbcommon-dev \
  libwayland-dev wayland-protocols libdecor-0-dev libdrm-dev libgbm-dev libgl1-mesa-dev libegl1-mesa-dev \
  libdbus-1-dev libudev-dev
sudo apt install mingw-w64          # só para o módulo do Windows
```

```sh
scripts/compilar.sh linux      # godot/bin/libforja.linux.x86_64.so
scripts/compilar.sh windows    # godot/bin/libforja.windows.x86_64.dll (mingw-w64, sem DLL do mingw)
scripts/compilar.sh testes     # as provas da lógica, sem SDL e sem Godot
scripts/compilar.sh tudo       # os três
```

O CI faz o mesmo a cada push, roda a prova do jogo e deixa os dois módulos
como artefatos. A exportação do jogo inteiro (binário Linux e `.exe`) entra no
marco 6.

## Rodar no Linux

```sh
./run-local.sh
```

Compila o módulo, baixa o Godot 4.4.1 na primeira vez, e abre o jogo; os
relatórios vão para `relatorios/`. Argumentos depois de `--` vão para o jogo:

```sh
./run-local.sh -- --simular=4 --robo    # sem controle: quatro de mentira
./run-local.sh -- --sala=galeria        # direto numa sala, com todo controle dentro
./run-local.sh -- --semente=42          # o mesmo sorteio, para comparar sessões
./run-local.sh -- --relatorios=/uma/pasta
```

Sem controle nenhum, o título oferece jogar no teclado: o teclado vira um
DualSense simulado (o módulo inteiro roda, e o relatório diz que foi
simulado). WASD anda, Espaço é ✕, Backspace ○, Q □, E △, F é R2, G é L2, Tab
é Create, Esc é Options, M é o botão do microfone, e Z segurado é falar no
microfone do controle simulado; com `--simular=N`, Ctrl+1…4 troca o controle
que o teclado dirige.

Para ler e escrever o hidraw do DualSense no cabo sem root (o report cru do
jack do fone, e as ferramentas de bancada), a regra do udev:

```sh
sudo cp udev/99-forja-dualsense.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
```

## Rodar o .exe pelo Proton

O `.exe` sai no marco 6, quando o jogo exporta para Windows; o módulo que ele
carrega (`libforja.windows.x86_64.dll`) já compila e já passa no CI. O caminho
vai ser este:

1. Na Steam: **Jogos → Adicionar um jogo não-Steam à minha biblioteca… →
   Procurar…**, com o filtro em todos os arquivos, e escolha o `.exe`.
2. **Propriedades → Compatibilidade → Forçar o uso de uma ferramenta de
   compatibilidade específica do Steam Play**, e escolha um Proton.
3. **Propriedades → Controle**: desative o Steam Input para este jogo (com ele
   ligado, o jogo recebe um controle Xbox e perde o resto do DualSense).
4. Os argumentos entram em **Propriedades → Geral → Opções de inicialização**.
   Os relatórios ficam em `relatorios/`, ao lado do `.exe`.

## Validar com quatro DualSense, passo a passo

Duas rodadas: os quatro controles **no cabo**, depois os quatro **no rádio**;
no fim, os dois relatórios lado a lado. Anote a versão do Hefesto e use a
mesma semente nas duas (`--semente=7`).

### No cabo

1. Ligue os quatro DualSense no USB e abra o jogo (`./run-local.sh -- --semente=7`).
2. No título, ✕. No lobby, cada um aperta ✕, na ordem P1…P4. Confira em cada
   controle: a lightbar na cor do cartão e os LEDs de jogador no padrão do
   lugar; no cartão, "USB", `054c:0ce6` e "DualSense nativo".
3. Cada um aperta ✕ de novo (pronto). No salão, Create abre o diagnóstico:
   mexa em tudo em cada controle — no mapa dele, a peça apertada acende em
   rosa, o analógico anda, o dedo no touchpad aparece, o giroscópio mostra a
   taxa. ○ fecha.
4. Jogue as salas que medem: A Centelha (as runas: todos os botões, os dois
   analógicos até a borda, os dois gatilhos no meio e no fundo), A Viga
   (incline o controle para equilibrar, gire para mirar nos sinos, sacuda para
   quebrar a pedra) e O Molde (trace a letra no touchpad, abra e feche com dois
   dedos, clique quando o metal brilhar). No fim de cada uma, o veredito de
   cada um na tela, por feature, com o que foi medido.
5. Jogue as salas às cegas, que perguntam o que a tela não mostra: O Impacto
   (sinta de que lado veio o golpe e levante o escudo daquele lado; no fim da
   onda, diga a cor da luz do seu controle) e A Galeria (aperte R2 e diga que
   arma é pelo gatilho; depois, conte as luzinhas embaixo do touchpad).
6. Jogue as salas de som. No aviso de cada uma, confira embaixo do seu nome o
   dispositivo que o jogo achou para você e como achou (pelo aparelho, pelo
   número, pelo nome): △ toca o teste nele (o sino no alto-falante; um pulso
   na esquerda e outro na direita, na háptica; no microfone, fale e a barra
   sobe), ◀ ▶ troca. O Canto (o canto saiu do seu controle? e repita o
   ritmo), Os Caminhos (sinta o chão e o lado da pedra, sem olhar a tela) e
   A Voz (silêncio; chame o guardião na sua vez; fique mudo pelo botão do
   microfone; diga como está a luz dele).
7. Options → O livro da sessão mostra a tabela. Os arquivos estão em
   `relatorios/`: `relatorio-<sessão>.txt` para ler, `.json` e a linha do tempo
   para comparar.

### No rádio

1. Pareie os quatro DualSense pelo Bluetooth, com o Hefesto rodando.
2. Abra o jogo com a mesma semente e repita os passos do cabo.
3. O cartão diz a origem que o jogo vê: com o Hefesto na frente, "DualSense
   Edge virtual" (ou "Xbox virtual", conforme o modo dele). Um DualSense
   nativo no rádio, sem ninguém na frente, entra só com a entrada, e o cartão
   diz isso ([ADR-005](docs/adr/005-o-radio-nativo-so-entrada.md)).

### Os dois relatórios

Ponha `relatorio-<cabo>.txt` e `relatorio-<rádio>.txt` lado a lado: cada
diferença é um trabalho para o Hefesto — a feature, o controle, o que foi
pedido e o que chegou.

## As provas sem aparelho

```sh
bash tests/prova_do_jogo.sh   # o jogo headless com quatro DualSense simulados
scripts/gauntlet.sh           # a mesma prova, e de novo com cada defeito de mentira: tem de falhar
make test                     # as ferramentas de bancada e o empacotador
```

A prova do jogo confere, pelo que cada controle simulado **recebeu**, que o
player index, a luz, as lâmpadas, os modos de gatilho, o motor do lado do
golpe e o LED do mudo chegaram só no lugar certo — e que o relatório gravado
se lê, tem os quatro controles e não carrega endereço de aparelho nem caminho
da máquina.
