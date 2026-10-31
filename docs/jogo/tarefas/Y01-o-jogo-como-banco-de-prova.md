# Y01 — O Forja como banco de prova: a mão de fora e o registro que o banco lê

**Sprint:** Y · **Tamanho:** G · **Estimativa:** 2 a 3 sessões, em duas partes (a mão de fora; o registro) ·
**Depende de:** [F01](F01-o-modo-bancada.md) (o `--bancada`), [F06](F06-o-registro-v2.md) (o formato `/2`),
[F08](F08-a-paridade.md) (o robô só age pelo controle). Do lado do Hefesto: a sprint
`O-FORJA-E-O-BANCO-DE-PROVA-DO-HEFESTO-01`, citada abaixo como «o banco».

Veio do plano do Hefesto em 13/10/2026: o que é do Forja saiu de lá e mora aqui. Esta ficha pede ao Forja o que o banco
precisa. O banco em si (o plástico de mentira, o `rodar.sh`, o `jogo` do básico, a linha de base) é do Hefesto e não
é passo desta ficha.

## Por quê

O Forja mede 21 features por jogador, mas o robô joga pads simulados **dentro do processo do jogo** e nunca atravessa o
Hefesto; a mão da dona da bancada mediu 8 das 21 em 12 sessões. O Hefesto quer um controle de mentira no kernel, o produto
de verdade no meio e o Forja do pino (um commit) jogando de ponta a ponta, numa VM ou no CI, a cada leva, com a matriz
como portão contra uma linha de base versionada. Para isso o Forja precisa de uma **mão de fora** (o mesmo robô, com o
corpo trocado) e de um registro que diga de quem é cada lugar. Isso é pedido ao Forja, não pré-requisito do banco: no
começo o banco anda com uma mão que só confirma (✕ a cada 2 s) e com o cruzamento das saídas, sem esperar esta ficha.

Decisão da dona da bancada (02/10/2026, resposta «Você pede ao dono do Forja»): o pedido sai pronto, curto e no idioma do
Forja. Esta ficha é esse pedido. Se o Forja aceita é decisão do repositório dele: ver «Para o André».

## Ler antes

- [CONTRATO](../../../CONTRATO.md): o Forja fala DualSense, não Hefesto. A mão de fora não leva `uniq`, endereço nem a
  palavra «Hefesto»; a mão é a pessoa.
- [F01](F01-o-modo-bancada.md), [F06](F06-o-registro-v2.md) e [F08](F08-a-paridade.md): `--bancada`, o `/2` e o robô só
  pelo controle.
- [O Forja ao vivo, `13-arquitetura.md`](../13-arquitetura.md), a paridade entre a prova e o jogo.
- `docs/adr/003-o-gauntlet.md` (o alcance do gauntlet: *«Ele prova o JOGO no CI; o Hefesto se prova na mesa.»*) e
  `scripts/gauntlet.sh`.

## O estado de hoje

### O que se mediu no disco e no remoto (01/10/2026, só leitura)

1. **As doze sessões do Forja** (`dist/forja-linux-x86_64/relatorios/`, de 29/09 12h28 a 01/10 18h24), todas de gente
   (`"simulado": false`): 9 no Forja `9bb19df` e 3 no `9bb19df-dirty` (30/09 01h07 e as duas de 01/10), um build com
   mudança local sem commit, que nenhum pino reproduz. (O `versao` dos relatórios guarda o hash de antes da reescrita;
   o commit é hoje o `795a4a1`.)

   | | |
   | --- | --- |
   | sessões que mediram alguma célula | 4 (29/09 13h02, 15h19 e 15h59; 01/10 18h14) |
   | features medidas alguma vez | 8 de 21: botões, analógicos, gatilhos analógicos, touchpad (dois dedos e clique), microfone, mudo, LED do microfone |
   | nunca medidas | 13: giroscópio, acelerômetro, os três dos motores, lightbar, os três modos do gatilho, LEDs de jogador, háptica por áudio, alto-falante, tudo junto |
   | o pad que o jogo viu | «DualSense Edge virtual (uhid)» em todas: nenhuma sessão no modo Xbox |
   | o transporte do físico | não está no relatório: o pad diz «virtual (declara USB)», e o Forja não pode saber (o CONTRATO dele) |

2. **A chave da célula.** Em 3 das 5 sessões com dois controles (29/09 15h19 e 15h59; 01/10 18h14), o lugar 1 do jogo era
   o «Hefesto P2» (o nome do sistema do pad). A matriz do Forja é por lugar. Chaveada pelo P do Hefesto, a única célula que
   passou e depois falhou é **«Botões» do P2**: passou em 29/09 15h19 e falhou em 01/10 18h14 («seta → pedia, chegava R3
   (3×)»). Por lugar, a história mistura controles: o «LED do microfone» do lugar 1 é o P1 às 13h02 e o P2 às 15h19. Nas
   doze, o pior das tentativas e o último da matriz coincidiram (30 células com tentativa, 0 diferentes).

   E essa falha não é do Hefesto: a sprint irmã `O-BOTAO-CHEGA-AO-JOGO-COMO-ELE-E-01` («A causa») refez a fila das runas
   pela semente e mediu que o veredito do Forja **chama de troca a resposta atrasada à runa anterior**, e guarda só o nome
   do último aperto (`nativo/nucleo/medidas.c:46-59`, `:100-105`). Um portão sobre a mão teria dado, no primeiro dia, um
   alarme falso. Por isso o pedido «a troca com assinatura» abaixo.
3. **O Forja roda sob o Freestyle** (diário do daemon, 18h13–18h42): às 18h14min24, sete segundos depois de a sessão abrir,
   o troca-automática de perfil do Hefesto trocou do perfil de outro jogo para o Freestyle. O Forja não tem perfil próprio.
4. **O Forja remoto** (`gh api repos/Hefesto-Team/Forja`, só leitura): público; o `main` estava em `eac3326` (30/09 22h28) e
   depois do último commit de código (`795a4a1`, que era `9bb19df` antes da reescrita) vieram 22 commits só de documentação (o plano do «jogo completo»,
   fichas F00 a S). Três encostam aqui: a F01 (Modo bancada: as perguntas às cegas e o veredito só com `--bancada`, ligado
   também por `--prova-de-fogo`; sem ele, oito features saem «não medido»), a F06 (registro v2: `formato` `/2` da linha do tempo,
   `seq` por lugar, `transporte` na conexão e o relógio de parede) e a F08 (o robô só age pelo controle simulado, sem atalho). O
   [08 — A noite de seis horas](../08-a-noite-de-6-horas.md) prevê um cruzamento do que o jogo mandou com «o registro da
   ponte». O repositório não tem tag: o pino do banco é um commit.

### O código do Forja, medido em `795a4a1` e reapontado em 30/10/2026 (`9b8bf3d`)

As linhas abaixo são as de 30/10/2026, depois do corte dos comentários (V09) e da F08. Ainda não existem `--mao` nem
`--listar-defeitos` no código.

- **O robô só joga pad simulado.** `--robo` sem `--simular` vira `--simular=4` (`godot/scripts/forja.gd:146-148`). O
  simulado é um `SDL_AttachVirtualJoystick` dentro do processo do jogo (`nativo/nucleo/simulador.c:227`). O
  `robo_apertar` procura o simulado do pad e, sem ele, não faz nada (`:291-326`, `sim_do_pad`). O que o robô «sente» vem
  dos callbacks desse joystick (`cb_rumble`, `:119`), e não de um aparelho. Desde a F08 o robô tem temperamento
  (`--robo=bom|medio|ruim`, `forja.gd:149-153`): `robo_apertar` e `robo_confirmar` passam por ele antes do
  `_robo_apertar_cru` (`:924-939`, `:981`).
- **Os 20 defeitos entram entre a mão do robô e o fio do simulado** (a lista em `simulador.c:52-62`; os efeitos em
  `:119-176` e `:507-576`), e o `scripts/gauntlet.sh` exige que cada um seja pego (ele lê a lista do `simulador.c`;
  `docs/adr/003-o-gauntlet.md:31`: *«Ele prova o JOGO no CI; o Hefesto se prova na mesa.»*).
- **O CI do Forja esconde os controles de verdade** (`tests/caixa.sh:21-31`: `bwrap` com `tmpfs` sobre
  `/sys/class/hidraw` e `/sys/class/input`) e acelera o tempo (`--fixed-fps 60`, `tests/prova_da_exportacao.sh:16`).
- **A matriz guarda o último veredito** (`nativo/nucleo/relatorio.c:49`, `:206`); o JSON traz todas as tentativas, na
  ordem (`:220`). O `formato` do relatório é `hefesto-tech-demo/relatorio/1` (`:167`); o `/2` da F06 é o da linha do
  tempo (`nativo/nucleo/linha_tempo.h:8`).
- **Sem robô, o jogo anda com ✕.** Cada lugar confirma o aviso (`godot/scripts/salas/sala_jogo.gd:235-239`) e o placar e o
  intervalo (`main.gd:688`, `:799`). O treino acaba em `TREINO_MAX` = 15 s mesmo sem acerto (`sala_jogo.gd:46`, `:535`).
  `--prova-de-fogo` põe todo pad presente na partida (`main.gd:203-216`, `_todos_entram` em `:238`) e `--sair-no-fim`
  grava o relatório e fecha no fim dela (`:515`, `:783`). A linha do tempo é gravada enquanto o jogo roda.
- **As salas são nove, e cada feature tem a sua.** A Prova de Fogo anda por `centelha, viga, molde, impacto, galeria,
  canto, caminhos, voz, prova` (`godot/scripts/main.gd:3`). A Viga mede o giroscópio e o acelerômetro, o Molde o
  touchpad, o Impacto a lightbar e os três dos motores, a Galeria os três do gatilho e os LEDs de jogador, a Voz o
  microfone, o mudo e a luz dele, o Canto o alto-falante e os Caminhos a háptica por áudio (os `veredito(…, "<chave>"`
  de cada `godot/scripts/salas/*.gd`). Com `--sala` ou `--prova-de-fogo`, todo pad presente entra de uma vez: o lugar é
  a ordem em que o SDL os achou, e não quem apertou ✕.
- **O relatório já diz se o pad é o do Hefesto:** cada controle traz o `vid_pid`, o `nome_do_sistema` e a
  `evidencia_da_origem` (`relatorio.c:106-139`), que em 01/10 dizia *«sysfs: HID bus 0003 em /devices/virtual/misc/uhid,
  sem pai USB · phys «hefesto-vpad»»*, e a taxa medida do giroscópio pelo relógio do controle
  (`giroscopio_hz_medido_relogio_do_controle`, `:133`: 248,3 Hz no lugar 1 de 01/10, o Hefesto P2).
- **O CONTRATO proíbe o Forja de falar com o Hefesto, de ler o `uniq` e de montar o report `0x31`** (`CONTRATO.md:41-56`,
  «O que o jogo recusa»). O controle de mentira do rádio, que fala `0x31` com CRC, não pode morar no Forja.
- Os pontos de código que a parte 4 mexe: as ações do robô em `forja.gd:924-980`; a percepção em `forja.gd:764`
  (`percepcao(l)`) e `:853` (`som_virtual(l)`); a linha do tempo dos apertos em `nativo/godot/forja_medidas.cpp:214-221`
  (hoje só o primeiro aperto de cada botão pedido ganha o `marco`) e a troca em `nativo/nucleo/medidas.c:46-59`;
  `include/forja_dualsense.h` (o decodificador do bloco comum de 47 bytes).

### A causa

Duas, e as duas explicam o que já funcionava.

1. **O robô do Forja não atravessa o Hefesto.** Ele aperta botão num joystick que mora dentro do processo do jogo e sente o
   que o SDL entrega a esse mesmo joystick. Entre a mão e o jogo não há kernel, nem pad, nem daemon. Por isso o CI do Forja
   está verde e prova o jogo, e não veria uma regressão do Hefesto nem se rodasse a cada hora.
2. **A mão é a única que atravessa, e ela é rara e ambígua.** Foram 4 sessões medindo em 12, 8 features de 21, e 13 nunca.
   O relatório não diz o transporte nem o modo. A célula é o lugar do jogo, que muda com quem aperta ✕ primeiro. E o
   veredito com gente engana: a «troca» de 01/10 foi uma resposta atrasada. O que funcionou: a mão achou o «LED do
   microfone» que falhava (29/09, 13h02 e 15h19). Mas o que a mão não joga de novo, ninguém vê regredir.

## O alvo

O Forja aceita uma **mão de fora** e entrega um registro que o banco do Hefesto lê sem adivinhar. Nada do jogo muda para
quem joga; tudo é opção de linha de comando e campo de registro.

**A. A mão de fora (`--mao=<socket>`), depois da F08** (o robô só age pelo controle). É o mesmo robô, com o corpo trocado.

- As ações que hoje vão ao simulado (`robo_apertar`, `robo_eixo`, `robo_girar`, `robo_sacudir`, `robo_tocar` e `robo_falar`,
  `forja.gd:924-980`) vão ao socket, em linhas JSON, com o índice da mão.
- A percepção que hoje vem dos callbacks (`percepcao(l)` e `som_virtual(l)`, `forja.gd:764` e `:853`) volta pelo socket como
  o **bloco comum de 47 bytes** que o controle de mentira recebeu. O Forja o lê com o próprio decodificador
  (`include/forja_dualsense.h`).
- No começo, o robô descobre qual mão é qual lugar apertando ✕ numa de cada vez, e grava o mapa na linha do tempo.
- O socket **não leva `uniq`, endereço nem a palavra «Hefesto»**. A mão é a pessoa, e o CONTRATO fica inteiro.
- A sessão diz `mao: true` na linha `sessao` (como hoje diz `simulado`), e o `--sair-no-fim` vale com ela.

**B. A lista dos defeitos legível de fora** (`--listar-defeitos`, ou um arquivo): o banco reproduz os 20 defeitos com os
mesmos nomes no controle de mentira, e um nome sem mão reprova o job do lado de lá (régua 12).

**C. O formato.** O `/2` da F06 entra lido pelo banco no mesmo commit em que o pino o alcança. O banco recusa o `formato`
que não conhece e, no banco, a `versao` que não é o commit do pino (um `-dirty` inclusive): a base de um build sem commit
não se refaz.

**D. Os dois pedidos da sprint irmã** (`O-BOTAO-CHEGA-AO-JOGO-COMO-ELE-E-01`, «Para o Hefesto-Team»):

- **a troca com assinatura:** o mesmo botão chegando em toda janela do pedido, e nunca a resposta atrasada à runa anterior
  (`medidas.c:46-59`, `:100-105`);
- **todo aperto na linha do tempo, com a runa acesa.** Hoje só o primeiro de cada botão fica
  (`nativo/godot/forja_medidas.cpp:214-221`).

Sem o primeiro, a célula «Botões» da mão não entra na base do Hefesto: o alarme falso de 01/10 se repetiria. **Sem o
segundo, a chave da célula no modo Xbox não existe:** o pad do modo Xbox não leva o Pn no nome, e com `--sala` o lugar é a
ordem do SDL. A chave sai da entrada: cada controle de mentira aperta ✕ sozinho, numa hora que ele grava, e o lugar que
recebeu aquele aperto é o dele. Até lá a perna do modo Xbox do banco roda e grava, mas a célula sai com `jogador = ?` e não
entra na base.

Com a mão de fora, o banco roda com `--bancada --prova-de-fogo` e as 21 features saem pelos vereditos do próprio Forja,
nas quatro pernas. O Forja mede a percepção; o cruzamento das saídas do lado do Hefesto mede cada saída.

## O que o banco faz do lado do Hefesto (contexto e dependência externa, nada disto é passo desta ficha)

Para quem lê esta ficha saber o que está do outro lado do socket. Tudo isto é da sprint `O-FORJA-E-O-BANCO-DE-PROVA-DO-HEFESTO-01`,
no repositório do Hefesto, medido lá em `integra/0110` (`d9a74436b`).

- **Por que o Hefesto não se prova hoje:** nada na casa atravessa o kernel sem a mão de quem joga. O `runtime-smoke` do CI
  sobe o daemon com um controle falso acima do HID; o mais fundo da suíte é um `uhid.c` de mentira (um socket que imita a
  fila). Nenhum teste cria aparelho no kernel.
- **A cura:** o produto de verdade entra entre o robô e um controle de mentira **no ponto mais baixo que ele lê: o HID do
  kernel**. No rádio, pelo `uhid` (como o BlueZ cria o controle de verdade). No cabo, por um gadget USB num controlador
  virtual (`usbip-vudc` + `vhci-hcd` + `libcomposite` + `usb_f_hid`), que dá ao aparelho um pai USB de verdade: o produto
  **recusa de propósito** um DualSense de cabo nascido no `uhid` (o broker confere o pai HID, o D1: *«USB real NUNCA é
  uhid»*), e contornar isso mediria outra coisa. Tudo o que o produto faz entre as duas bordas do kernel passa num caminho
  só: o evdev e o hidraw do físico, o pad (uhid no modo DualSense, uinput no modo Xbox), a saída ao físico (o `0x02` no cabo,
  o `0x31` com CRC no rádio), a numeração de P1 a P4, o físico escondido e a volta depois da queda.
- **Parte 0, a sonda** (já costurada no Hefesto em 06/10/2026, topo `1f5de1ead`): um job do CI só em `workflow_dispatch`
  (`banco-de-prova-sonda`) mede no runner o kernel, os módulos, se um `UHID_CREATE2` no barramento `0005` faz o
  `hid_playstation` registrar o controle, se o `usb_f_hid` responde o `GET_REPORT` de feature (`0x05`, `0x09`, `0x20`), se o
  `install.sh` sobe o broker e a regra de `udev`, e se quem roda o jogo abre o hidraw e o evdev do pad sem concessão
  manual. Decide a casa por perna: sem `uhid`/`hid_playstation` ou sem a ACL do pad, o banco mora só na VM; sem o
  `GET_REPORT` do gadget, as pernas com cabo não existem naquela casa. A primeira corrida (`gh workflow run`) é de quem
  mantém e ainda não aconteceu: um `não-mediu` ali é um achado.
- **Partes 1 a 4** (a bancada do Hefesto, ainda por fazer lá): o controle de mentira (de 1 a 4, um por mão, entrada no ritmo
  do transporte, o CRC-32 de cada quadro do rádio com a semente `0xA1` na entrada, `0xA2` na saída e `0xA3` nos features, a
  saída decodificada do bloco comum de 47 bytes e gravada, a queda que destrói e recria com o mesmo endereço, e a guarda que
  sai com rc=2 fora de VM); o `rodar.sh` (lar de mentira, daemon de verdade, o `retrato`, o Forja do pino headless e em
  tempo real, nunca `--fixed-fps`, com `--semente=7 --nivel=2`, sala por sala `centelha|viga|molde|impacto|galeria|voz|prova`
  com teto por sala); o subcomando `jogo` do básico (a célula é `jogo · <feature> × Pn · transporte · modo`, nunca o lugar; o
  pior das tentativas e não o último da matriz; recusa o pad que não é do Hefesto; a linha «o movimento chega» pela taxa do
  giroscópio contra a que o controle de mentira mandou; o cruzamento das saídas); e `docs/data/banco-de-prova.csv`, a linha
  de base, que só cresce pela costura do Hefesto.
- **As pernas:** `misto-dualsense` (P1 e P2 no cabo, P3 e P4 no rádio, pad uhid), `misto-xbox` (os mesmos, pad uinput),
  `um-no-radio` (só o P1) e `queda` (a `misto-dualsense` com o P3 saindo e voltando no meio da Galeria). Onde o gadget do
  cabo não responde, as quatro nascem no rádio e o nome da perna diz isso.
- **Fica de fora do banco:** o som (a háptica por áudio, o alto-falante e o microfone, e com eles o Canto e os Caminhos), o
  «registro da ponte» do 08 e o caminho do botão no Hefesto (é da sprint irmã, só em `src/` do Hefesto; o banco é a prova
  dela no jogo quando existir: a perna `misto-dualsense`, a Centelha, com a mão de fora).

### Como o banco decide (para o Forja saber o que o registro dele sustenta)

- **No banco**, a célula que PASSOU na base e saiu FALHOU **ou NÃO MEDIDO** reprova (zero com o alvo fora não é zero). **Na
  mão**, só FALHOU reprova; NÃO MEDIDO não, porque a pessoa joga o que quer. O vermelho do banco barra o merge do Hefesto; o
  da mão é alarme e vira sprint se o banco não o explicar.
- Uma célula intermitente (passa numa corrida e falha na outra, com a mesma semente) sai numa linha própria e **não entra
  na base**. Em tempo real e com a mão de fora do relógio do jogo, a matriz inteira não se repete byte a byte; o que tem de
  se repetir é a célula que entraria na base.
- As regras de igualdade das saídas citam as decisões do Hefesto: a vibração vai só a quem joga naquele lugar, os motores
  ficam no HID no banco (sem caminho de háptica por áudio), o gatilho do jogo chega salvo o lado que o perfil declarou, e a
  luz e o mudo do microfone obedecem ao jogo; a lightbar e os LEDs de jogador saem «não sei» até a primeira corrida separar o
  que é do jogo do que o Hefesto escreve por conta própria.

## Passos

1. **Medir de novo** no commit atual do Forja antes de começar (`git log -1`): `forja.gd` (`_ler_args`, ações do robô,
   percepção), `simulador.c`, `forja_medidas.cpp`, `medidas.c`, `relatorio.c`. As linhas de «O código do Forja» são de
   30/10/2026 (`9b8bf3d`); anotar na ficha o que mudar de linha.
2. **Abrir uma conversa curta com o repositório do Hefesto** (só leitura de lá) para fechar o nome dos campos que o `jogo`
   do básico lê: `formato`, `versao`, `mao`, `lugar → mão`, a lista de defeitos. Escrever o combinado no
   [CONTRATO](../../../CONTRATO.md) como «o que o Forja entrega a quem o mede», sem citar o Hefesto.
3. **D primeiro, porque é o que destrava a célula «Botões»:** a troca com assinatura (`medidas.c`) e todo aperto na linha do
   tempo com a runa acesa (`forja_medidas.cpp`). Prova: o relatório de 01/10 18h14 deixa de poder produzir o alarme falso
   (o mesmo botão em toda janela; nenhuma resposta atrasada vira troca).
4. **A, a mão de fora.** `--mao=<socket>` ligando as ações do robô ao socket e a percepção ao bloco de 47 bytes; o mapa
   mão→lugar na linha do tempo; `mao: true` em `sessao`; `--sair-no-fim` valendo. Teste do socket com um servidor de mentira
   que fala o bloco de 47 bytes (sem nenhum nome do Hefesto).
5. **B, `--listar-defeitos`:** os 20 nomes, um por linha, estáveis.
6. **C, o `/2`:** conferir que o relatório e a linha do tempo trazem o que a lista do alvo pede e que o `formato` muda de
   número se o esquema mudar.
7. **A prova do jogo e o gauntlet seguem verdes**: a mão de fora é opção, o caminho do simulado não muda.
8. **Documentar** `--mao`, `--listar-defeitos` e o socket em `docs/DESENVOLVER.md` e no `docs/COMO-CONTRIBUIR.md`.

## Armadilhas

- **O CONTRATO fica inteiro.** Nada de `uniq`, endereço, palavra «Hefesto» ou `0x31` no código do Forja. A mão é a pessoa.
- **`--fixed-fps` mente para o banco:** o banco roda em tempo real; a mão de fora não pode contar com o relógio acelerado
  do CI do Forja.
- **Lugar não é jogador.** Com `--sala` ou `--prova-de-fogo` o lugar é a ordem em que o SDL achou o pad. O mapa mão→lugar
  tem de sair da linha do tempo, nunca de suposição.
- **Um build `-dirty` não é pino.** O banco recusa `9bb19df-dirty`; as três sessões assim do disco servem de fixture, nunca
  de base.
- **A troca atrasada é do Forja, não do Hefesto** (a medida da sprint irmã): não «cure» no registro; cure o veredito.
- **Não suba a perna do som.** Háptica por áudio, alto-falante e microfone ficam fora do banco; a mão de fora não os leva.
- **A conversa com o Hefesto não vira dependência:** o Forja nunca lê nada do Hefesto; o combinado é um formato escrito no CONTRATO.

## Não fazer

- Não criar controle de mentira, `uhid`, gadget ou qualquer coisa de kernel no Forja (é do banco, lá).
- Não mudar regra, tempo ou tela do jogo por causa do banco.
- Não tirar os 20 defeitos nem o simulado: o gauntlet segue sendo a prova do JOGO.
- Não pôr no repositório do Forja nenhum dado da máquina de quem joga (endereço de rádio, nome de rede, MAC, IP).

## Pronto quando

- `--mao=<socket>` joga uma sessão inteira contra um servidor de mentira, e o relatório diz `mao: true`.
- `--listar-defeitos` imprime os 20 nomes.
- O mesmo botão chega em toda janela do pedido e todo aperto está na linha do tempo; o relatório de 01/10 18h14 já não
  produz o alarme falso.
- A prova do jogo, o gauntlet e a prova de poucos seguem verdes.

## Provas

- `bash tests/prova_do_jogo.sh` (as duas rodadas) e `scripts/gauntlet.sh` (pela caixa e pelo semáforo da máquina).
- Um teste novo do socket, com mordida: tire a leitura do bloco de 47 bytes e veja a percepção reprovar; devolva.
- Mordida da troca: devolva a resposta atrasada como troca e veja a prova nova reprovar.
- As réguas do banco que dependem desta ficha são do Hefesto: 12 (cada defeito reproduzido no controle de mentira vira FALHOU
  na feature dele, e um defeito que passa reprova o job), 6 (relatório `/2` desconhecido ou `versao` fora do pino dá rc=2) e
  7 (a chave é o P do Hefesto; com o relatório de 01/10 18h14, «Botões» falha no P2). As outras réguas (pad que não é do
  Hefesto recusado, saída ao plástico certo, produto medido por um `sitecustomize` e nunca por `src/`, célula que passou não
  volta, pior e não último, plástico sem `import` do produto, guarda do kernel único, zero com o alvo fora, base só muda com
  decisão, queda no meio, movimento chega, cabo é cabo) vivem lá.

## Para o André (local)

- **Decidir se o Forja aceita a mão de fora.** A decisão é do repositório dele; esta ficha é o pedido pronto. Sem aceite, a
  ficha fica como está e o banco segue com a mão que só confirma.
- **Sessão jogada na máquina da bancada fecha célula na folha dos ensaios do Hefesto, inclusive a de visita**, com o nome de
  quem jogou na nota (resposta de 13/10/2026). A sessão de 01/10 às 18h14 foi da dona da bancada; o relatório entra como
  sessão dela e é a medida da régua 7 (a troca de botão do segundo controle).
- **A folha:** o livro do Forja mais a leitura do básico do Hefesto, logo depois de cada sessão (a sessão do roteiro J1, ~15
  min: um controle no cabo e um no rádio). Só a mão prova: a cor que se vê, o tremor que se sente, o gatilho que endurece; o
  rádio de verdade (adaptadores, rajadas, quedas); o som pela placa USB e pela ponte do rádio; o Forja pelo Proton com o
  Steam Input desligado; os módulos do DKMS da casa; o tempo (engasgo e quadro); e o «O JOGO REAGIU».

## O que ficou sem prova (dos dois lados)

- Se as salas fecham com a mão que só confirma: as perguntas às cegas da F01 e a Voz sem voz. O teto por sala e a linha do
  tempo contínua seguram a medida, mas o número de cada sala sai da primeira corrida do banco.
- A duração em tempo real de cada perna; o descritor do rádio (a captura é do Hefesto); se o `usb_f_hid` do kernel da VM e
  do runner responde o `GET_REPORT` (a sonda mede); se o usuário do runner recebe a ACL do pad sem sessão num assento (a
  sonda mede); se a taxa do giroscópio responde ao espelho de movimento como a régua 14 supõe; o daemon sem BlueZ na perna do
  rádio; se o Hefesto escreve no controle de mentira coisas próprias durante o jogo (a vigia da luz), que o cruzamento leria
  como vazamento.

## Ao terminar

Pôr a linha da Y01 no [quadro](README.md) como **feito** (ou **espera o André**, se a parte D e a A estiverem prontas e o
aceite da mão de fora ainda faltar), com o commit. Avisar o repositório do Hefesto para o pino andar (trocar o pino é ato
da costura de lá).
