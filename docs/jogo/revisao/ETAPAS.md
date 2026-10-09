# As etapas até o produto completo

Medido em 09/10/2026, 14h10, na árvore `voo/auditoria` (topo `85f24c3`, igual à integração `integra/forja`), com
olhada nos ramos em voo `voo/a-fita` (topo `ea84267`), `voo/o-cavaleiro` (topo `630a879`) e `voo/a-varredura` (topo
`45f989a`). Conferido às 14h25 contra o quadro, as fichas e o código (a seção «A crítica», no fim, diz o que mudou).
A bancada com ela está marcada para ~16h30; o prazo é 17h.

## 1. Onde o produto está

### O quadro (`docs/jogo/tarefas/README.md`), linha por linha

| seção | fichas | feito | em voo | pronta | a fazer | espera |
| --- | --- | --- | --- | --- | --- | --- |
| F — a fundação | 12 | 10 (F00 a F09) | 1 (F09b) | — | — | 1 (F10, a parte B espera o André) |
| G — as telas | 16 | — | 11 | 5 (G04, G07, G11, G12, G13) | — | — |
| H — o ritmo, o som e o kit | 10 | 9 (H03 sem a medida automática) | — | — | 1 (H08) | — |
| I a Q — os 45 minigames | 45 | — | — | 45 | — | — |
| R — o Relâmpago | 1 | — | — | 1 | — | — |
| S — a noite de seis horas | 1 | — | — | 1 | — | — |
| V — a varredura | 8 | — | — (V01 e V06 já voam, ver abaixo) | — | 8 | — |
| X — os módulos | 7 | — | — | — | 7 | — |
| **total** | **100** | **19** | **12** | **52** | **16** | **1** |

Em tamanho, o feito é quase todo fundação: das 19, nenhuma é tela nem minigame. O jogo que se joga hoje é o das nove
salas antigas com o kit novo por baixo (H04, H06, H07) e o minigame de prova.

### O que já está nos ramos e o quadro ainda não diz

- **`voo/a-fita`** (91 arquivos, +3685/−1340): G14, F09b, G15, G16 e G05 com código, prova e a conferência escrita
  na ficha. Nasceram quatro fichas filhas que **não estão no quadro**: F09c (o controle que cai quando se joga
  sozinho), G05b (o que a G05 deixou por dependência), G14b (as cores de luz que sobraram) e G16b (o que a G16 deixou
  por dependência). Mexe no módulo nativo (`nativo/nucleo/pads.c`, a barra de luz da G14).
- **`voo/o-cavaleiro`** (122 arquivos, +4873/−469): G01, G02, G03, G08 e G09 com código e conferência. G06 e G10
  ainda sem commit: estão sujos na árvore do ramo (`colecao.gd` e `scripts/importar_kenney.py` novos; `som.gd`,
  `musica.gd`, `hud.gd`, `main.gd`, `traducoes.gd`, `prova_do_jogo.gd` e o `mapa.csv` mudados).
- **Os dois ramos de telas partem de `5455c41`, não da integração:** nenhum dos dois tem o kit (H04, H06, H07). Na
  costura, a-fita encontra o kit em 11 arquivos (`main.gd`, `sala_jogo.gd`, `som.gd`, `traducoes.gd`, `forja.gd`,
  `placar.gd`, `prova.gd`, `prova_do_jogo.gd`, `captura_jogo.gd`, o `13` e o `README.md`) e o-cavaleiro em 10 (os
  mesmos, sem `placar.gd` e `README.md`, mais `musica.gd`). Entre si, os dois ramos dividem 38 arquivos.
- **`voo/o-kit`**: costurado (H04, H06, H07 feitas em `85f24c3`), ainda **sem push** para o `main`: a integração
  está 23 commits à frente do `main` (`66fa244`), todos do kit.
- **`voo/a-varredura`** (base `85f24c3`, 2 commits): a V01 (`811d54c`, o Godot só entra com o sha512 conferido, o CI
  e o `run-local.sh` baixam pelo `engine.sh`) e a V06 (`45f989a`, a prova das ferramentas). O quadro ainda as mostra
  como **a fazer**.

### O som (`docs/jogo/audio/mapa.csv`, 258 linhas)

| tipo | no jogo | gerado | a fazer |
| --- | --- | --- | --- |
| efeito | 83 | 11 | 8 |
| interface | 16 | 9 | — |
| assinatura | — | 44 | 8 |
| vinheta | 5 | 13 | 5 |
| ambiente | 3 | 1 | — |
| **música** | **1** | — | **51** |

A música está fora desta leva, mas é do produto. A linha «no jogo» da música é o `sint_trilha`, a trilha
sintetizada de reserva (um módulo, não um arquivo): **nenhuma das 51 faixas existe no repositório**. As pastas
`godot/assets/ost/S01` a `S09` e `telas/` só têm o `.gitkeep`, e sem faixa na pasta o jogo toca a reserva
(`godot/assets/ost/LEIA-ME.md`). As 51 são as 45 dos minigames e seis de tela (título, construção, salão, pódio,
créditos e Relâmpago).

### O que ela ainda decide (`docs/jogo/o-time/ESPERA-ELA.md`)

- A emenda do contrato do gatilho (SLOPE_FEEDBACK e os dois MULTIPLE_POSITION): segura a mágica 7 do catálogo
  (`docs/jogo/pesquisa/dualsense.md:509`). Nenhuma ficha do quadro espera por ela: a J1 (`:1147`) e a K1 (`:1108`)
  a citam para dizer que não a usam.
- A regra udev do touchpad (`LIBINPUT_IGNORE_DEVICE=1`), que pede o sudo dela. O ESPERA-ELA diz que ela segura K1 e
  K3, mas as fichas dizem o contrário: K1 (`:1104`), K3 (`:597`) e K4 (`:630`) leem o touchpad pelo SDL e «não
  dependem da regra»; K2 e K5 dizem «nada». O que a regra cura é o cursor da área de trabalho que anda junto com o
  dedo. A linha do ESPERA-ELA pede outra redação (o que espera: nenhuma ficha; o conforto da máquina dela).
- Nova, da F09c: sozinho, com o cabo que cai, a sala **espera** o controle voltar ou **termina**? Ainda não está no
  ESPERA-ELA.

## 2. O que falta até a bancada, e a ordem que destrava mais

### Até a bancada (~16h30): fechar o que já voou, não abrir frente

Os 45 minigames não cabem até 17h: todos dependem da H08, que nem começou, e da G12, que depende de G08 e G11 (e a
G11, de G04 e G10). A bancada de hoje é **título → construção do cavaleiro → salão → as nove salas → resultado →
virar da fita**, com a luz nova, a câmera nova e o kit por baixo. A ordem:

1. **Costurar `voo/a-fita`** (as cinco fichas já têm conferência) por cima do kit. Na costura: pôr F09c, G05b, G14b
   e G16b no quadro como **a fazer**; os encontros com o kit estão na seção 1 (o «os dois lados» vale para os
   arquivos de todos, mas `som.gd`, `placar.gd` e `prova.gd` pedem leitura).
2. **Costurar `voo/o-cavaleiro`** com as cinco que voltaram (G01, G02, G03, G08, G09). G06 e G10 entram quando
   voltarem; se não voltarem até ~15h30, ficam para depois da bancada (e o salão da bancada é o de hoje). Os
   encontros com a a-fita:
   - `godot/scripts/mundo/lente.gd`: os dois ramos criam o arquivo com conteúdo **e `.uid` diferentes**. Vale um
     arquivo só, com `fov`, `PADRAO`, `recuo` e a lente do título (85 mm), conforme o passo 1 da G05b, e **um** uid:
     conferir quem referencia o outro antes de apagar.
   - `main.gd` (`_pose_da_camera`), `tema.gd`, `player.gd`, `opcoes.gd`, `mundo/kit.gd`, as nove salas e as telas do
     título e do lobby.
   - Os shaders `contorno` e `neon` e o `fx_caneta.wav` nascem nos dois ramos com o mesmo conteúdo: o segundo
     cherry-pick tem de sair limpo; se não sair, é sinal de que um lado mudou depois.
3. **Uma rodada das provas pesadas na integração**, pelo semáforo (`vez-do-pytest.sh`): `bash tests/prova_sem_rastro.sh`,
   `scripts/compilar.sh testes`, `bash tests/prova_do_jogo.sh`, e a prova visual só se a máquina estiver abaixo de ~5
   de carga (com ~13, o o-kit tomou 6 erros falsos no P2). Às 14h16 a carga estava em **52**, com a revisão e os
   estudos em voo: a rodada das pesadas pede que eles tenham voltado. Push só com tudo verde.
4. **Antes de ela jogar:** a mesa (`/mnt/Apate/Desenvolvimento/Hefesto-Forja`, o `main`, hoje em `66fa244`) recebe a
   integração por ff, e é nela que se compila: `scripts/compilar.sh linux` (o módulo muda com a H07, já na
   integração, e com a G14, `pads.c`) e `~/.local/state/forja-casa/forja-muda.sh desligar` (os testes estão mudos).

O que ela confere com a mão na bancada:

- o PLAY na mão de quem apertou, a introdução sem uma palavra, as quatro armaduras acesas (G01);
- montar o cavaleiro peça por peça, a roupa de cima e a de baixo diferentes, o neon só no acento, as outras raças,
  e escrever o nome no próprio controle (G02, G08, G09 e o ajuste dela de 09/10, 00h);
- o item que muda a mecânica, o Escudo n'A Centelha (G03);
- a luz de cada seção e o brilho com dono (G15); a câmera que segue o grupo n'A Prova e o salão a 35 mm (G05). O
  tremor em degraus **não aparece no jogo ainda**: nenhuma sala chama `tremer(...)` (G05b, «O estado de hoje»);
- o virar da fita na metade e as Opções novas, Movimento e Reações (G16);
- o apito que para a música em seco, o jingle do resultado e o pio de cada cavaleiro (H06, H07);
- a decisão da F09c.

### Depois da bancada, ainda o plano de hoje: a ordem que mais destrava

Quem segura mais fichas, contando só o que ainda não está **feito** e só a dependência escrita na coluna «depende de»
(a ficha que diz «as seções I a Q prontas» não conta para cada n.º 1; a X06, que pede «as fichas G que mexem no
`main.gd`», fica fora):

| ficha | estado | fichas que esperam por ela |
| --- | --- | --- |
| H08 | a fazer | **47** (os 45, a V04 e a X07; a R e a S esperam por tabela) |
| G03 | em voo | 13 (a H08 entre elas: por ela passam as 47) |
| G08 | em voo | 9 |
| G12 | pronta | 9 (o n.º 1 de cada seção) |
| O1 | pronta | 8 (O2 a O5, Q1, Q4, Q5, S) |
| P1 | pronta | 7 |
| G02 | em voo | 6 |
| G05 | em voo | 5 |
| G10 | em voo | 2 (G11 e G13), mas está no caminho G10 → G11 → G12 → os nove n.º 1 |

A ordem:

1. **H08 imediatamente depois da costura da G03.** É fundação (vai de **a fazer** direto para **em voo**) e é o
   gargalo do produto: sozinha segura 47 fichas. **A G04 não é disjunta dela**: as duas mexem em `main.gd`,
   `sala_jogo.gd`, `forja.gd`, `traducoes.gd` e `prova_do_jogo.gd`; vai logo depois, ou junto aceitando a costura à
   mão nesses cinco. Junto da H08, sem briga: a **V05** (só `som.gd` e duas chamadas em `canto.gd` e `viga.gd`), que
   já pode voar (H06, H07 feitas; o mapa publicado), desde que as duas costuras de telas tenham entrado (as duas mudam
   `som.gd`).
2. **V02, V03 e V04 antes de abrir as seções.** Setenta e seis fichas editam `godot/testes/prova_do_jogo.gd` (V02),
   31 editam a tabela de traduções (V03) e as seções estão em sete constantes de quatro arquivos (V04): com quatro
   seções em voo, cada costura vira conflito à mão. Partir a prova, partir a tabela e juntar as seções é o que deixa
   quatro conjuntos voarem juntos com arquivos disjuntos. A V04 pede a H08; V02 e V03, só que as duas costuras de
   telas tenham entrado. A WE02 desta revisão (a prova do kit no relógio do quadro) vai antes da V02.
3. **G10 → G11 → G12** em fila (a G11 pede G04 e G10; a G12 pede G08, G11, H04, H06). Depois da G10: **G13** (pede
   G02, G10 e G14). Ao lado: **G07** (pede G03, G04, G06).
4. **O n.º 1 de cada seção** (I1, J1, K1, L1, M1, N1, O1, P1, Q1): cada um cria o `secao.gd` da seção. **O1 antes da
   Q1** (a Q1 pede a O1), e O1 e P1 cedo, porque Q1, Q4, Q5, R e S dependem delas. A K1 não espera a regra udev (ver
   a seção 1).
5. **Os n.º 2 a 5**, seção por seção; Q4 e Q5 por último entre os minigames (a Q4 pede as seções S1 a S4 prontas; a
   Q5, as S5 a S8 e a Q4).
6. **R**, depois **S** com o André.

## 3. As próximas etapas depois da bancada, em blocos

### Bloco 1 — O plano de hoje até o fim (G, H08, I a Q, R, S)

O que está na seção anterior. É o que transforma a bateria de salas em jogo. A conta do ANDAMENTO da leva 1 é ~3 a
4 h de relógio por onda (as seções vão de duas em duas, das ondas 6 a 9; a I sozinha, na 5b).

### Bloco 2 — A dívida da leva 1, e a revisão de hoje

Por quê: cada conjunto deixou o que dependia de vizinho, e isso só fecha depois que o vizinho existe.

- As filhas: F09b (em voo), F09c, G05b, G14b, G16b.
- A H03 com a medida automática (pede a G02).
- As fichas W desta revisão (em `~/.local/state/forja-casa/leva-2/achados/`), que viram a seção «W — A revisão» no
  quadro quando a revisão voltar, agrupadas por arquivo, com no máximo três trilhos de Godot ao mesmo tempo.
- Os achados anotados que não têm ficha:
  - `run-local.sh:35` baixa a engine de `$GODOT_URL`, que ninguém define (anotado na F00, `:109`). **Já curado** no
    ramo `voo/a-varredura` (`811d54c`): o `run-local.sh` e o `exportar.sh` chamam o `forja_baixar_engine`. Entra com
    a V01. A WE05 desta revisão abre ficha para o mesmo defeito: encolhe para o que sobra (o cabeçalho do
    `run-local.sh:2` e o `docs/DESENVOLVER.md:28`, que ainda dizem Godot 4.4).
  - «Faltam 2 jogadores ficarem prontos» (`tela_lobby.gd:74`, `traducoes.gd:315`) pede outra redação.
  - O `README.en.md` ficou atrás do `README.md` desde `66fa244`.
  - O «relógio sem faixa» (`prova_do_jogo.gd:904`) falha às vezes com a máquina carregada. A WE02 dá a causa provável
    (o `Ritmo` no relógio de parede, medido por um robô que aperta por quadro) e a cura; vale para os dois.
  - O título longo da tela de resultado: a cura da H04 foi revertida na integração em `46aae4d` (`45d4a72` no ramo
    o-kit) «para depois da fita», porque a F09b e a G14 trocam a mesma linha. Volta depois da costura da a-fita,
    medida com a letra nova.

### Bloco 3 — Os portões que reprovam (V05, V08)

Por quê: os portões de arte e de som estão em modo aviso, porque o código inteiro estava fora da bíblia. A V05 casa
o `Som` com o mapa do áudio e já pode voar (ver a ordem, item 1). A V08 zera os avisos e vira a chave: a bíblia já
foi aprovada (09/10, ~00h); falta a G14 entrar, a V05 e os arquivos do mapa. Sem isso, a bíblia é texto e não lei.

### Bloco 4 — A esteira e os módulos (V01, V06, V07, X01 a X07)

Por quê: o que vale fora da Forja (o pacote do DualSense, o do ritmo, o do kit de minigame) e o que impede a esteira
de quebrar em silêncio. **V01 e V06 já voam** (`voo/a-varredura`); a V07 espera a F10 (o André). A X03 já pode voar
(H01, H02 e H03 feitas), mas troca toda chamada `Ritmo.` do jogo e das provas e o autoload no `project.godot`: ou vai
antes da H08 (que mexe no `ritmo.gd`), ou depois das seções, nunca junto de uma delas. A X06 espera X01 e as G; a X07
espera X03, X04, X06, a H08 e a seção I. Não segura a bancada nem o lançamento; segura o segundo jogo.

### Bloco 5 — A música (fora desta leva, dentro do produto)

Por quê: 51 faixas do mapa a fazer, nenhuma no repositório (45 dos minigames e seis de tela). Segue
`docs/jogo/o-time/o-mapa-do-audio.md` e a fila que já existe em fundo (`scripts/trilha_fila.sh`), uma faixa por vez,
com a placa livre; as candidatas esperam a escolha dela. Sem ela, o jogo sai com a trilha sintetizada de reserva em
todos os 45 minigames e nas telas.

### Bloco 6 — O controle de qualquer um (novo, sem ficha)

Por quê: o jogo foi desenhado para quatro DualSense no cabo, e quem compra num PC raramente tem isso. Ver as
lacunas 1, 2, 3 e 16. É o bloco que decide se a Forja é um jogo à venda ou um jogo da casa. O estudo «qualquer
máquina, qualquer controle» está em voo nesta mesma leva (as fichas WR, WU, WF, WQ, WO e WT, que chegam em
`leva-2/achados/`): o bloco se escreve a partir delas, não do zero.

### Bloco 7 — O lançamento (novo, sem ficha)

Por quê: a exportação já existe (`scripts/exportar.sh`, o AppImage, o `.tar.gz` e o `.zip` publicados a cada tag,
`SPRINTS.md:452`), mas nada liga isso a uma loja. Ver as lacunas 4 a 7.

### Bloco 8 — O teste com gente (novo, sem ficha)

Por quê: o único teste com pessoas no plano é a noite de seis horas, com o André e quem já conhece o jogo. Ver a
lacuna 8.

## 4. Os riscos

| risco | o que derruba | o que segura |
| --- | --- | --- |
| **A H08 sozinha segura 47 fichas** | se ela atrasar ou voltar errada, nenhum minigame anda | despachar logo depois da G03; conferente forte; nada de seção antes dela |
| **Os dois ramos de telas sem o kit** | a-fita e o-cavaleiro partem de `5455c41`: cada um encontra o kit em ~10 arquivos e o outro em 38; a costura das duas antes das 16h30 é o caminho crítico da bancada | costurar a a-fita primeiro (já completa), depois o-cavaleiro; ler (não só «os dois lados») `som.gd`, `lente.gd` e o `.uid` dele |
| **Os arquivos de todos** | `prova_do_jogo.gd` (76 fichas), `traducoes.gd` (31), `main.gd` (25, pela X06): com quatro seções juntas, a costura vira conflito à mão e o «os dois lados» passa a esconder erro | V02, V03 e V04 antes das seções; X06 depois das G |
| **A máquina carregada** | provas que reprovam sem defeito (o P2 do o-kit com 6 erros com carga ~13; o relógio sem faixa): a regra «uma prova falha duas vezes seguidas, a ficha volta para enriquecida» (`o-time/a-esteira.md:50`) passa a punir ficha certa. Às 14h16, carga 52 | prova pesada só com carga baixa; o semáforo; medir a carga antes de culpar a ficha; a WE02 (a prova no relógio do quadro) |
| **O prazo das 17h** | a promessa «a noite inteira jogável» do plano de 08/10 não cabe | a bancada de hoje é a das telas e do kit; os minigames são o Bloco 1 |
| **Gente que não é a máquina** | F10 B e S esperam o André; a aparência só se aprova na máquina dele (regra de ouro 10, `docs/jogo/README.md`); ela joga só no fim da seção | marcar a noite com o André assim que a R voltar; a F10 B não segura ninguém de jogo (só a V07 e a X04, e por ela a X05 e a X07) |
| **O sudo no Linux** | o jogo escreve no hidraw pela regra `udev/99-forja-dualsense.rules`, que o pacote leva e manda copiar com sudo (`scripts/exportar.sh:110`); o touchpad que mexe o cursor pede outra regra (ESPERA-ELA). Quem compra pela loja não roda sudo | a lacuna 3 |
| **O Steam Input** | aberto pela loja, o Steam Input liga por padrão para controles PlayStation e entrega ao jogo um controle genérico: some o gatilho, a luz, o alto-falante (o caso do meio curso no Ratchet de PC). O módulo já reconhece o espelho (`nativo/nucleo/origem.c:202`, `28de:11ff`), mas o jogo não faz nada com isso. Está em `docs/jogo/pesquisa/dualsense.md:516`, sem ficha | ficha no Bloco 6 |
| **O rádio** | o jogo só fala USB `0x02`; o alto-falante, o microfone e a háptica por áudio só chegam no cabo (a própria Sony diz que a resposta tátil no PC pede USB). As seções N (o canto) e P (a voz) perdem o segredo no ouvido e a voz | já coberto nas fichas: na N, sem alto-falante, o som do dono vai para a raia dele na TV a −10 dB (N1 `:901`, e a tabela de cada N); na P, «no rádio» o lugar joga sozinho com a `troca` registrada (P1 `:1177`, P2 a P5). O que falta é a bancada provar com dois no rádio, como as fichas pedem |
| **A música gerada por programa** | a loja pede declarar conteúdo gerado que o jogador vê ou ouve; o `LICENCAS-DE-TERCEIROS.md:19` diz como a trilha foi feita, mas nada prepara a declaração | escrever a declaração no Bloco 7 |
| **O commit assinado** | o `main` recusa merge de commit antigo não assinado | costura só por cherry-pick (re-assina) |

## 5. As lacunas: o que nenhum documento cobre

1. **O controle de outra marca.** Em sessões na Steam com controle, 59 % são de controle Xbox e 26 % de PlayStation
   (números da Valve, junho de 2024). O `nativo/nucleo/pads.c:292-328` abre qualquer controle do SDL e só liga os
   efeitos quando o tipo é PS5 (o Edge entra como PS5 e o `origem.c` o conta como DualSense: ele não é lacuna). O
   controle Xbox não tem touchpad, giro, alto-falante, microfone nem gatilho com peso; o DualShock 4 tem touchpad,
   giro e barra de luz, mas não tem gatilho com peso, háptica por áudio nem microfone embutido. As salas antigas já
   dizem o que fazem sem giro (`docs/SALAS.md:108`: «a sala joga com os analógicos e o ✕»); para os 45, nenhum
   documento diz o que cada um desses controles faz: K (touchpad), J (giro), N (alto-falante) e P (microfone) perdem
   o verbo no Xbox; o gatilho de M e Q some nos dois. Falta decidir: recusar com uma frase do mundo, jogar com um
   verbo trocado, ou deixar o minigame fora da noite daquele lugar.
2. **O Steam Input.** O `docs/VALIDAR.md:78` manda o testador desligar à mão. Para quem compra, falta: a configuração
   padrão do jogo na loja (desligado para PlayStation), ou o caminho do Steam Input pela API dele, que o
   `CONTRATO.md:75` promete como o **preferido** quando o jogo roda pela loja (com `SetDualSenseTriggerEffect`, na
   tabela do `:20`) e que não tem código nem ficha; e o bloco de gatilho do cabeçalho tem 24 bytes, contra os 120 da
   API (`dualsense.md:515`). E o que o jogo faz quando recebe o espelho genérico no lugar de um DualSense: o módulo já
   o reconhece (`origem.c:202`), o jogo ainda não responde.
3. **O sudo de quem compra.** São duas regras udev, não uma: a do hidraw (`udev/99-forja-dualsense.rules`, sem a qual
   o jogo não escreve o `0x02`) e a do touchpad (ESPERA-ELA). O pacote de hoje manda rodar `sudo cp`
   (`scripts/exportar.sh:110`); quem compra não roda sudo. Falta medir se as regras que o cliente da loja já instala
   dão acesso ao hidraw do DualSense (a conferir), o que o jogo faz quando o hidraw está fechado (avisar com uma frase
   do mundo, cair para o que o SDL dá) e a resposta do touchpad que mexe o cursor (pegar o dispositivo pelo próprio
   SDL, avisar, ou ensinar), escrita antes de K1.
4. **A loja.** Nenhuma ficha cobre: a conta e a taxa da loja, a página «em breve» (pública por no mínimo duas
   semanas antes do lançamento), a revisão do build e da página, os depósitos, as capturas e o vídeo, os requisitos
   de sistema, os idiomas declarados, as conquistas (o `13` e a G06 falam em conquista dentro do jogo, não na loja),
   o salvo na nuvem, e o Steam Linux Runtime (o «sniper» é o recomendado para jogo nativo novo; o AppImage não é o
   que a loja roda). O Steam Deck também: a verificação pede letra legível a 30 cm (mínimo 9 px em 1280×800, 12 px
   recomendado) e glifo do controle que está na mão; o `docs/jogo/arte/10-acessibilidade.md` mede para TV a 3 m. E o
   Windows: o `.exe` sai do CI e joga a Prova de Fogo no Wine (`tests/prova_da_exportacao.sh`); nenhum documento
   registra uma partida num Windows de verdade com quatro DualSense, que o `SPRINTS.md:455` põe no «pronto quando».
5. **A classificação indicativa.** Zero menções. No Brasil, jogo digital se autoclassifica pelo questionário
   internacional (IARC), nas faixas livre, 10, 12, 14, 16 e 18; o ECA Digital vale desde março de 2026. A Forja tem a
   Dissonância, golpes, a Metralhadora de Feitiços e um dragão: a faixa precisa ser escolhida, e as palavras da loja
   têm de bater com ela.
6. **A declaração do conteúdo gerado por programa** (lacuna e risco): a trilha e parte dos sons. A loja pede dizer o
   que o jogador vê ou ouve; o que só ajudou a escrever o código não precisa.
7. **A licença do que se vende.** O repositório inteiro é MIT, e o CONTRATO diz que a Forja é um jogo de loja: quem
   quiser recompila e distribui. Pode ser a intenção; nenhum documento diz que é. Falta separar (ou confirmar) a licença
   do código, da arte, dos sons e da trilha próprios.
8. **O teste com gente de fora.** Só existe a noite de seis horas. O que os guias de teste de jogo independente
   recomendam: várias sessões curtas por versão (menos de uma hora, de 4 a 8 pessoas, com uma conversa no fim), com
   gente de fora e não só amigos. Falta o roteiro (o que se observa, o que se pergunta, onde se anota) e a régua de
   quando um minigame volta para enriquecida por causa do teste.
9. **A noite interrompida.** Uma noite de quatro a seis horas sem salvar: o jogo guarda só `user://opcoes.cfg` (com
   o cavaleiro de cada lugar, G02) e `user://colecao.cfg` (G06, ainda sem commit). Queda de luz ou fechamento no meio
   perde o placar, a fita e o lado. Falta a retomada (a fita com o contador, o placar, o lado A ou B e a próxima faixa).
10. **Jogar menos de quatro.** O `06:53` diz que «um lugar vazio nunca segura o minigame», cada ficha de minigame tem
    a seção «Com menos de quatro» (o molde pede), e o `13:715` já põe o robô de treino na dupla quando sobra um só.
    Mas o gênero preenche a vaga com jogador do computador em todo minigame, e fora daquela dupla o robô (F08) só joga
    na prova. Falta decidir se o robô senta na vaga vazia, e com que temperamento.
11. **Escolher e treinar um minigame.** Os jogos do gênero têm o lugar onde se joga um minigame avulso e se treina
    (a baía dos minigames do Mario Party Jamboree; o Museu do WarioWare: Move It, liberado depois de jogado na
    história). A R é aquecimento e desempate, não escolha. A coleção (G06) guarda acabamentos, não minigames, e é da
    noite: outra noite começa vazia. Falta o jogo livre, que é também o que faz alguém voltar sem a noite inteira.
12. **A seção P sem voz.** O `10-acessibilidade` cobre a falta de visão de cor, de audição, de vibração e do
    movimento fino, mas não a de **falar**: quem não pode (ou não quer, de madrugada com vizinho) gritar não joga a
    seção P. O caminho existe por baixo (sem microfone, o ouvido marca `sem_microfone` e o lugar joga sozinho, P1
    `:1177`), mas só o rádio o liga: ninguém o escolhe. Falta a alternativa, no mesmo espírito do «Jogar no teclado».
13. **Remapear os botões.** As diretrizes de acessibilidade em jogos põem o remapeamento no nível básico e entre as
    quatro queixas mais comuns (com tamanho de texto, daltonismo e legenda). A Forja tem texto grande, daltonismo,
    movimento reduzido e o peso do gatilho por lugar (Desligado, Fraco, Forte, `opcoes.gd:12`); não tem remapear,
    nem segurar-ou-alternar para quem aperta seis horas.
14. **Jogar à distância.** A loja deixa jogo local virar jogo pela internet (o Remote Play Together, até quatro
    pessoas, só quem hospeda precisa ter o jogo). O `09-fora-do-escopo` recusa jogo online com servidor, mas não diz
    nada disto: na transmissão, o alto-falante, o gatilho e a háptica dos convidados não chegam. Falta registrar se a
    Forja aceita, recusa (e marca na loja), ou avisa.
15. **Os idiomas.** O jogo tem português e inglês (`traducoes.gd`, a tabela `EN`); nenhum documento diz se haverá
    outro (o espanhol é o vizinho de mercado do Brasil), nem quem revisa o inglês, nem o que a loja declara.
16. **As pendências da pesquisa do DualSense.** A tabela «O que fica em aberto, e de quem»
    (`docs/jogo/pesquisa/dualsense.md:505-520`) tem doze linhas: a emenda está no ESPERA-ELA, o Steam Input no
    Bloco 6, e as 45 notas por minigame já existem em `docs/jogo/pesquisa/`. As outras nove não têm ficha: a fase do efeito do gatilho (a mágica 5 e o julgamento justo da
    S5), a atenuação por lugar e o brilho dos LEDs, o fone no controle (a mágica 2), o volume do microfone no GDScript
    e a regra «enquanto o microfone escuta, o motor cai» (a mágica 10), o mapa de canais da placa por driver (a
    háptica pode cair no canal errado), o bloco de 24 contra 120 bytes, os perfis de gatilho por peça (a mágica 1) e o
    brinde, contar pelo tato e o vento que aponta (as mágicas 6, 8 e 9).

## Fontes

- Remapeamento e as quatro queixas mais comuns: [Game Accessibility Guidelines, o nível básico](https://gameaccessibilityguidelines.com/basic/)
- A verificação do Steam Deck (letra, glifos): [Steamworks, compatibilidade do Steam Deck](https://partner.steamgames.com/doc/steamdeck/compat)
- O runtime do Linux na loja: [Steamworks, a plataforma Linux](https://partner.steamgames.com/doc/store/application/platforms/linux); a recomendação do «sniper» para jogo nativo novo, de segunda mão: [uma documentação de terceiros para Godot na Steam](https://docs.sentry.io/platforms/godot/configuration/steam/)
- A taxa, a página «em breve» por duas semanas, a revisão: [How to sell a game on Steam](https://fungies.io/how-to-sell-a-game-on-steam) (guia de terceiros; conferir na documentação da loja)
- A declaração do conteúdo gerado: [GeekWire, as regras de 2024](https://www.geekwire.com/2024/valve-software-reveals-new-rules-for-ai-powered-game-development-on-steam/), [a revisão de janeiro de 2026](https://tech-insider.org/steam-ai-disclosure-2026) (de segunda mão: cita a loja por outros sites)
- A classificação indicativa: [a portaria do Ministério da Justiça](https://www.gov.br/mj/pt-br/assuntos/seus-direitos/classificacao-1/legislacao/arquivos-diversos/Portaria502SEI.pdf), [as faixas em vigor desde 2022](https://oimparcial.com.br/noticias/2022/01/entra-em-vigor-portaria-que-regulamenta-classificacao-indicativa/), [o ECA Digital e a verificação de idade](https://olhardigital.com.br/2026/06/12/games-e-consoles/playstation-exigira-verificacao-de-idade/)
- O uso de controles na Steam: [Pure Xbox, os números de junho de 2024](https://www.purexbox.com/news/2024/06/xbox-remains-the-controller-of-choice-for-steam-users-unsurprisingly) (a manchete diz «usuários»; os números são de sessões com controle), [PC Gamer](https://pcgamer.com/48-million-players-use-controllers-on-steam)
- A háptica do DualSense no PC pede USB: [PlayStation, usar o DualSense no PC](https://playstation.com/pair-dualsense) (diz da resposta tátil; dos gatilhos, não); o Steam Input escondendo o DualSense: [tópico do Ratchet & Clank: Rift Apart](https://steamcommunity.com/app/1895880/discussions/0/3801652295709093492)
- O Remote Play Together: [VGC](https://videogameschronicle.com/news/steam-users-can-now-play-local-multiplayer-games-online)
- A baía dos minigames e os Bonus Stars: [Super Mario Party Jamboree, Super Mario Wiki](https://www.mariowiki.com/Mario_Party_Jamboree); o Museu do WarioWare: [análise do Move It](https://www.gfinityesports.com/reviews/warioware-move-it/), [o Museu na Super Mario Wiki](https://www.mariowiki.com/Museum_(WarioWare:_Move_It!))
- O teste com gente: [Playtesting for indies, Game Developer](https://www.gamedeveloper.com/production/playtesting-for-indies), [How many playtesters do you need](https://www.fixgamingchannel.com/how-many-playtesters-do-you-need-guide/)

## A crítica

Conferido às 14h25 contra o quadro, as fichas, o ESPERA-ELA, o ANDAMENTO da leva 1 e o código. Os números da tabela
do quadro, do mapa do áudio e das contagens da V02, V03 e X06 bateram. O que mudou, e por quê:

1. **A emenda do gatilho não segura J1 nem K1.** As duas fichas a citam para dizer que não a usam (J1 `:1147`, K1
   `:1108`). Ela segura só a mágica 7.
2. **A regra udev não segura K1 nem K3.** K1, K3 e K4 dizem, cada uma, que leem o touchpad pelo SDL e «não dependem da
   regra». Saiu o «K1 e K3 só depois da decisão do udev» da ordem; o ESPERA-ELA é que está desatualizado e ficou
   anotado.
3. **A H08 segura os 45, a V04 e a X07**, não «a R»: a R não cita a H08 (espera por tabela, pelas seções).
4. **A G04 não é disjunta da H08**: dividem cinco arquivos. No lugar, a V05, que já tem as dependências feitas e é
   disjunta da H08.
5. **A G13 pede a G10** (e a G02), não só a G14: não anda «ao lado» da fila G10 → G11 → G12. **A Q1 pede a O1**:
   entrou na justificativa de pôr O1 cedo.
6. **A música:** não há «a trilha que já está em `godot/assets/ost/` (S01 a S09)». As pastas só têm `.gitkeep`; o
   jogo toca a reserva sintetizada (`sint_trilha`, a única linha «no jogo»). As 51 são 45 de minigame e seis de tela,
   não «uma por minigame». O Bloco 5 dizia «nove faixas para 45 minigames»: são zero.
7. **O módulo nativo** muda com a H07 (já na integração) e com a G14 (`pads.c`), não com a G02 e a G03: o
   o-cavaleiro não toca em `nativo/`.
8. **Os ramos de telas partem de `5455c41`**, sem o kit: a costura encontra o kit em ~10 arquivos de cada ramo, e
   os dois ramos dividem 38 entre si. O `lente.gd` não é só um conflito de conteúdo: os dois `.uid` são diferentes.
   Entrou um risco novo para isso.
9. **A V01 e a V06 já voam** (`voo/a-varredura`, base `85f24c3`), e a V01 já curou o `run-local.sh` que o Bloco 2
   mandava pôr nela. A WE05 desta revisão abre ficha para o mesmo defeito: encolhe para o que sobra.
10. **O tremor em degraus não se vê na bancada**: a G05b diz que nenhuma sala chama `tremer(...)`. A linha do que ela
    confere foi corrigida para não prometer o que não está no jogo.
11. **O rádio nas seções N e P já está escrito** em cada ficha (a raia na TV a −10 dB; o lugar que joga sozinho). O
    risco passou de «falta dizer» para «falta a bancada provar».
12. **A mesa recebe por ff antes de ela jogar**: o passo 4 compilava sem dizer onde; ela joga na mesa (`main`, ainda
    em `66fa244`), não na integração.
13. **A carga de 52 às 14h16** entrou no passo 3 e no risco da máquina: a rodada das pesadas antes da bancada depende
    dos estudos em voo voltarem.
14. **Uma etapa esquecida:** as fichas W desta revisão viram a seção W do quadro (Bloco 2), e o Bloco 6 se escreve a
    partir do estudo «qualquer máquina, qualquer controle» que já voa nesta leva.
15. **Uma promessa sem ficha:** o `CONTRATO.md:75` diz que o caminho pela API da loja é o preferido quando o jogo
    roda por ela; não há código nem ficha (lacuna 2). E a tabela de pendências da pesquisa do DualSense tem nove linhas
    sem ficha nem destino (lacuna 16, nova).
16. **As lacunas foram afinadas onde o repositório já cobre uma parte:** o Edge é DualSense para o módulo e o
    DualShock 4 tem touchpad e giro (lacuna 1); as salas antigas já jogam sem giro (`SALAS.md:108`); a regra udev do
    hidraw também pede sudo (lacuna 3, e o risco «O sudo no Linux» no lugar do «touchpad no Linux»); o Windows real
    sem registro (lacuna 4); o robô de treino na dupla (lacuna 10); o `sem_microfone` da P1 (lacuna 12); o peso do
    gatilho por lugar nas Opções (lacuna 13); a coleção é da noite (lacuna 11).
17. **As fontes:** os números de controle são de sessões com controle, não de usuários (a manchete confunde); a
    página do DualSense no PC diz que a resposta tátil pede USB, mas não diz isso do gatilho; a revisão de 2026 da
    declaração é de segunda mão. O Museu do WarioWare ganhou uma fonte que diz o que o texto diz. O commit da reversão
    do título é `46aae4d` na integração (`45d4a72` é o do ramo o-kit). A regra das duas falhas ganhou o lugar
    (`o-time/a-esteira.md:50`); a regra de ouro 10, o arquivo.
