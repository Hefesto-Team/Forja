# F09 — A prova visual

**Sprint:** F · **Tamanho:** G · **Depende de:** F00, F02 (a coleta de texto), F03 (o fim), F08 (o robô só pelo controle)

## Por quê

Na primeira noite, as fotos e os GIFs mostravam tudo certo, e a partida
jogada mostrou erros grosseiros. A prova visual passa a ver o que o jogador
vê: a partida inteira, pelo caminho de verdade, com o robô errando, e com
checagens automáticas sobre todos os quadros — não só sobre fotos escolhidas.

## Ler antes

- [A arquitetura — a prova visual](../13-arquitetura.md#a-prova-visual--f09)
- [A arquitetura — a paridade](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08)

## O estado de hoje

- `godot/testes/captura_jogo.gd` abre `res://scenes/main.tscn` com quatro
  controles simulados e fotografa momentos escolhidos por roteiro
  (`ROTEIRO=salas|bancada|partida`, `FOTOS=`, `SALAS=`), com `RAPIDO=1`
  encolhendo a janela entre as fotos e `SEM_TREMOR=1` tirando o tremor.
- `godot/scripts/main.gd:156-200` (`_abrir_pelos_args`): `--sala=`,
  `--tela=`, `--partida=` e `--prova-de-fogo` chamam `_todos_entram()`
  (todos entram por código) e pulam o título e o lobby.
- `scripts/trailer.sh` grava com `--write-movie` o mesmo roteiro de
  `captura_jogo.gd`.
- `tests/telas.sh` tira as fotos e compara pastas.
- O simulador já sabe tirar e pôr o cabo: `ctl.simulador_cabo(...)`
  (`nativo/godot/`), além de `simulador_botao`, `_eixo`, `_giro`, `_dedo`,
  `_falar`.
- Na nuvem **não há** `ffmpeg` nem Pillow. O Godot tem tudo o que falta:
  `get_viewport().get_texture().get_image()`, `Image.blit_rect`,
  `Image.save_png`.

## O alvo

Um roteiro novo, `godot/testes/prova_visual.gd` (+ `.tscn`), e um script
`tests/prova_visual.sh` que:

1. roda **quatro partidas** pelo fluxo de verdade, começando no título, cada
   jogador entrando pelo ✕ do seu controle simulado:
   - quatro jogadores, `--robo=bom`, partida de 5;
   - quatro jogadores, `--robo=ruim`, partida de 5;
   - dois jogadores, `--robo=medio`, partida de 3;
   - um jogador, `--robo=medio`, partida de 3, com o controle desconectando
     no meio do segundo minigame (`simulador_cabo`) e voltando no terceiro;
2. a cada 2 s de jogo guarda um quadro (PNG pequeno, 480×270) com a hora;
3. no fim de cada partida monta a **prancha**: uma grade de 6 colunas com
   todos os quadros e a hora embaixo de cada um, em `SAIDA/prancha-<n>.png`;
4. roda as **checagens** sobre todos os quadros e sobre a linha do tempo e
   escreve `SAIDA/checagens.txt` — e sai com erro se alguma reprovou.

## Passos

1. **Os temperamentos do robô.** Em `godot/scripts/forja.gd`, `--robo`
   aceita `=bom|medio|ruim` (sem valor: `bom`). `Forja.robo` continua `bool`;
   `Forja.robo_acerta() -> bool` sorteia pela semente (bom 95%, médio 66%,
   ruim 30%) e o `_robo` de cada sala passa a consultá-la antes de apertar
   no tempo certo (quando não acerta, aperta atrasado ou não aperta). Só o
   gancho do robô muda.
2. **Entrar pelo ✕.** O roteiro não usa `--sala=` nem `--tela=`. Com
   `--robo`, quem aperta do título à construção é o robô do fluxo
   (`main._robo`, `TelaLobby.robo`, da G01/G02), pelo controle simulado; o
   roteiro **só observa** — um ✕ a mais do roteiro pularia a introdução.
   Antes da G01, o roteiro aperta ✕ no controle simulado de cada lugar, com
   intervalo, como um jogador.
3. **Os quadros.** A cada 2 s de `t` do jogo, `get_viewport().get_texture().get_image()`,
   `resize(480, 270)`, guardar em memória com a hora e o estado de
   `main.gd` (`estado`, `sala_id`).
4. **A prancha.** `Image.create(6 * 480, linhas * 290, false, FORMAT_RGB8)`,
   `blit_rect` de cada quadro, e a hora escrita embaixo (um `Label` num
   `SubViewport`, ou pixels de um dígito desenhado — o que for mais simples;
   a prancha é para olho humano).
5. **As checagens** (`godot/testes/checagens_visuais.gd`, `class_name ChecagensVisuais`):
   - `tela_parada(quadros)`: dois quadros seguidos com diferença média de
     pixel abaixo de 0,5% por mais de 5 s, fora de `pausa`;
   - `tela_vazia(quadro)`: mais de 97% dos pixels a menos de 8 níveis da
     mesma cor;
   - `texto(frases)`: pela coleta de `Desenho` (F02), com o retângulo de cada
     frase: sobreposição entre dois retângulos, retângulo fora da área segura
     (5% de cada borda) e altura de fonte abaixo de 30 px;
   - `relogio_sobe(linha_do_tempo)`: o relógio do minigame nunca aumenta
     durante a fase `jogo`;
   - `fim_sem_vencedor(linha_do_tempo)`: todo `minigame` `terminou` tem
     `vencedor`;
   - `minuscula(frases)`: frase de tela começando com minúscula.
6. **O quadro por segundo.** Em `godot/scripts/salas/sala_jogo.gd`, medir o
   `Engine.get_frames_per_second()` na fase `jogo` e gravar ao terminar
   `Forja.evento("desempenho", 0, {"slot": id, "fps_min": ..., "fps_media": ...})`.
   A checagem só **avisa** (não reprova) abaixo de 55, porque na nuvem o
   renderizador é por software.
7. **`tests/prova_visual.sh`**: roda as quatro partidas **sem**
   `--fixed-fps` e **com** `--fixed-fps 60` (duas passadas), com a
   `SAIDA` numa pasta temporária por padrão ou na pasta pedida, e imprime o
   resumo das checagens.
8. Aposentar os atalhos de foto: `captura_jogo.gd` continua para as fotos de
   divulgação, mas `tests/telas.sh` passa a chamar a prova visual. Documentar
   em `docs/DESENVOLVER.md` e em `docs/COMO-CONTRIBUIR.md` (os comandos).

## Armadilhas

- `get_image()` num Godot `--headless` devolve imagem vazia: a prova visual
  roda **com** janela (na nuvem, o Godot sem `--headless` usa o renderizador
  por software; se não abrir, rodar dentro de `xvfb-run`, instalado pela
  F00). Conferir antes de escrever o resto.
- Sem `--fixed-fps`, a partida dura o tempo real: quatro partidas levam uns
  15 minutos. A passada com `--fixed-fps 60` é a que roda na sessão; a sem
  é a do André.
- A semente fixa (`--semente=7`) tem de dar o mesmo resultado nas duas
  passadas; se não der, é bug de jogo, não da prova.
- Guardar os quadros em memória a 480×270 ocupa pouco (cerca de 400 kB por
  quadro em RGB8); não gravar PNG cheio a cada 2 s.
- A coleta de texto da F02 precisa guardar o retângulo, não só a frase; se
  a F02 não guardou, acrescentar lá.

## Não fazer

- Não aprovar aparência (luz, cor, brilho, arte) pela prancha da nuvem: o
  renderizador por software não é a placa de vídeo. A aparência é do André.
- Não trocar o jogo para a prova passar.

## Pronto quando

`bash tests/prova_visual.sh` roda as quatro partidas pelo fluxo de verdade,
gera as quatro pranchas e as checagens, e uma falha plantada de propósito
(um texto encavalado, um relógio que sobe, um minigame sem vencedor) é
reprovada — e depois tirada.

## Provas

- Na sessão: `bash tests/prova_visual.sh` (passada com `--fixed-fps 60`) e
  as três falhas plantadas.
- Com o André, local: `bash tests/prova_visual.sh` sem `--fixed-fps`, com
  placa de vídeo; olhar as quatro pranchas.

## Para o André (local)

Rodar a prova visual, abrir as pranchas e anotar no diário (hora, minigame,
o que viu) tudo o que parecer errado — inclusive a aparência. A partir
daqui, toda ficha de tela, arte, câmera, HUD ou minigame só fecha com a
prancha olhada.

## Ao terminar

Marcar F09 como **feito** no [quadro](README.md), com o gasto. Commit
sugerido: `feat: a prova visual — a partida inteira, o robô que erra, a prancha e as checagens de cada quadro`.

## O que foi feito (leva 1, as-provas)

- Os temperamentos do robô: `--robo=bom|medio|ruim` (`Forja.robo_temperamento`;
  sem valor o robô é o de sempre, que não erra o toque, e as provas dos
  vereditos seguem iguais). `Forja.robo_acerta()` sorteia pela semente (95%,
  66%, 30%); quem erra, em `robo_apertar`, aperta atrasado ou não aperta, e nos
  eixos a mão treme mais. A mudança mora no gancho do robô, em `forja.gd`: o
  `_robo` de cada sala não mudou, e vale para todas. O ✕ do fluxo (o aviso, o
  placar) só atrasa, nunca falta.
- A coleta de retângulos de texto, em `godot/scripts/ui/desenho.gd` (a F02
  guardava só a frase): com `Desenho.coletar_retangulos` ligado, cada
  `texto`, `paragrafo`, `selo` e dica de botão guarda a frase, a caixa da
  **tinta** (do alto das letras altas à ponta das descendentes, não a caixa da
  linha, que traz o entrelinha), o tamanho da letra e a cor. Fora da prova, ninguém
  liga e nada custa.
- `sala_jogo.gd` mede os quadros por segundo da fase `jogo` e grava
  `desempenho` (`slot`, `fps_min`, `fps_media`) ao terminar.
- `godot/testes/prova_visual.gd` (+ `.tscn`): uma partida do título ao pódio,
  sem `--sala=`, sem `--tela=`, sem `_todos_entram()`: o roteiro aperta ✕ no
  controle simulado de cada lugar (a G01 ainda não existe) e só observa o resto.
  A cada 2 s de jogo guarda um quadro de 480×270 com a hora, o estado, a sala e
  os retângulos de texto, e no fim monta a prancha (seis colunas, a hora embaixo
  de cada quadro em dígitos de pixel, a faixa vermelha no quadro que uma
  checagem reprovou) em `prancha-<n>.png` (60 quadros por página, para o PNG
  caber) e escreve `checagens-<n>.txt`. A partida de um jogador desliga o cabo
  no meio do segundo minigame (`simulador_cabo`) e o religa no terceiro.
- `godot/testes/checagens_visuais.gd` (`class_name ChecagensVisuais`): tela
  parada (menos de 0,5% de diferença por mais de 5 s, fora da pausa e do pódio),
  tela vazia (97% a menos de 8 níveis), texto (encavalado, fora da área segura
  de 5% com 4 px de folga, abaixo de 30 px, contraste abaixo de 3:1 lido no pixel
  do quadro, com o texto esmaecido misturado ao fundo), relógio que sobe, fim sem
  vencedor, frase com minúscula, e o aviso de quadros por segundo abaixo de 55.
  O mesmo defeito parado na tela conta uma vez («e mais N iguais»). Duas frases
  iguais exceto pelo número, no mesmo lugar, são um contador, não colisão. Nenhuma
  régua conhece uma cor do tema.
- `tests/prova_visual.sh`: as quatro partidas (4 com o robô bom e partida de 5;
  4 com o ruim e 5; 2 com o médio e 3; 1 com o médio e 3, com o cabo), as duas
  passadas (`fixa` = `--fixed-fps 60`; `livre` = sem), a saída numa pasta
  pedida ou temporária, `checagens.txt` com tudo. Roda no Xvfb com OpenGL por
  software, dentro do `bwrap` (nenhum hidraw, nenhum input: o controle ligado na
  máquina fica de fora), com o servidor de som de mentira, e sai com erro se uma
  partida reprovou. `--autoteste` confere, sem janela, que cada checagem reprova
  o defeito plantado e passa o quadro limpo. `PASSADAS=` e `PARTIDAS=` escolhem.
- `tests/telas.sh visual <pasta>` chama a prova visual; `fotos` ficou para as
  fotos de divulgação. Os comandos estão em `docs/DESENVOLVER.md` e em
  `docs/COMO-CONTRIBUIR.md`.

**A medida.** No Xvfb com o `llvmpipe` e a máquina dividida com outra sessão, a
passada `fixa` roda uns 3 a 6 vezes mais devagar do que o relógio do jogo: a
partida de 1 jogador e 3 salas leva uns 20 minutos de parede (3:42 de jogo), a
de 4 e 5 salas uns 30 (5:21 de jogo com o robô bom, 7:01 com o ruim). O padrão
da janela é 640×360 (a 1280×720 ficava duas vezes mais lento): as caixas de
texto saem do desenho, em pixels do jogo (1920×1080), e o contraste lê o pixel
do quadro com um anel maior que 2 pixels.

**Fez morder.** A régua de cada checagem tem o autoteste (defeito plantado
reprova, quadro limpo passa, e a coleta de retângulo confere a caixa da tinta). No
jogo de verdade, com três defeitos plantados num código temporário (já tirado):
um texto desenhado 10 px acima de outro, o relógio da sala subindo por uns
quadros e o evento de fim do minigame sem `vencedor`, mais uma frase de tela com
minúscula, a prova reprovou os quatro, com a hora e o lugar. Tirados, voltou ao
que o jogo de hoje dá. Achou também, no caminho, três erros da própria régua,
curados: a caixa do texto de uma linha saía com 0×0, o contador «80 s»/«81 s»
contado como colisão, o primeiro quadro (antes do primeiro desenho) com dois
estados do título.

**O que ela acha no jogo de hoje.** Reprova: de 20 (a partida de um jogador) a
46 defeitos distintos por partida, os mesmos nas quatro (letra abaixo de 30 px,
texto fora da margem de 5%, contraste abaixo de 3:1, um texto sobre o outro no
2 contra 2, tela parada por mais de 5 s). Não achou tela vazia, relógio que
sobe, fim sem vencedor nem minúscula. A cura é do jogo, não da régua, e virou a
[F09b](F09b-os-achados-da-prova-visual.md).

**Na conferência.** Corrigido na régua e no roteiro:
- A colisão era frouxa: perdoava duas frases iguais exceto pelo número em
  qualquer lugar. Agora só perdoa a mesma frase, ou o contador, no mesmo lugar
  (0,4 do corpo da letra na horizontal, 0,15 na vertical).
- O relógio lia só a conta da sala. Agora lê também o relógio que a tela mostra
  («80 s», «… 1:29»), com a chave pela sala e pela posição.
- O fim reprova também o vencedor -1 (ninguém).
- O padrão da janela dizia 640×360 e era 1280×720; agora é 640×360.
- A passada `livre` no Xvfb rodava por software, sem placa de vídeo. `NA_TELA=1`
  roda sem Xvfb, com a placa dentro da caixa (abre a janela na tela de quem roda).
- As duas passadas agora comparam a semente: o vencedor de cada minigame e o
  pódio têm de bater, senão reprova. Na partida 4 bateu.
- Na passada `livre` da partida 4, a cruz única do robô no placar se perdia com o
  cabo fora, e o placar ficava parado para sempre: o robô do placar aperta de
  novo a cada 4 s (`main.gd`, `_robo_do_placar`).
- A tela vazia contava o preto de propósito da troca de tela (a cortina de
  `main.gd`, 150 ms fechando): a passada `livre` caiu nele aos 02:01. O quadro
  guarda agora se a troca está em curso, e só o preto de fora dela reprova; a
  troca que fica no preto aparece como tela parada.
- Na mesma passada, o cartão d'A Galeria que desliza saiu «encavalado com ele
  mesmo» a 31 px: sem `--fixed-fps`, um quadro que não se desenha junta dois
  desenhos do nó com o mesmo número de quadro, e a prancha mostra um cartão só.
  A coleta (`desenho.gd`) marca agora cada desenho do nó, e só o último vale.

**Fica para a mão dela ou do André.** A passada `livre` (sem `--fixed-fps`,
com placa de vídeo) e as quatro pranchas olhadas; a aparência (luz, cor, arte)
não se aprova pelo renderizador por software; as partidas 2 e 3 desta rodada
rodaram uma versão da régua que ainda contava o título com dois estados (só o
quadro do título muda; o resto é igual). Uma escolha a validar por ela: `tests/telas.sh
fotos` ficou para a divulgação e a prova visual entrou como `tests/telas.sh visual`.
