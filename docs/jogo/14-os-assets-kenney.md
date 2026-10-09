# 14 — Os assets da Kenney

O Forja já é feito de Kenney: os bonecos e as peças do Mini Dungeon, e 72
efeitos sonoros. O **Kenney Game Assets All-in-1** junta tudo o que a Kenney
publicou num download só. Esta página decide o que entra no jogo, como
entra, e o que fica de fora.

## Ajuda ou atrapalha

**Ajuda muito, se entrar escolhido. Atrapalha, se entrar inteiro.**

| | |
| --- | --- |
| o que é | 246 pacotes (154 de 2D, 54 de 3D, 16 de áudio, 10 de interface, 8 de ícones), 516 MB zipados, mais de 1 GB aberto |
| preço | US$ 19,95 no itch.io, com atualizações grátis |
| licença | CC0: pode usar, mudar e publicar, até comercialmente, sem dar crédito. A única restrição é não usar o logo da Kenney |
| o que é só do pacote pago | quase nada: tudo é grátis no site, um a um. O pacote pago é a comodidade e os pacotes em "early access" |

**O que ajuda:**
- O **Mini Characters** traz 12 personagens com **o mesmo esqueleto de sete
  ossos e as mesmas 32 animações** do Mini Dungeon que o jogo já usa (conferido
  no arquivo). Sozinho, cumpre a meta de doze bonecos do
  [11](11-arte-e-personagens.md#os-personagens) sem mexer em código de
  animação. O Mini Arena e o Mini Market também são compatíveis.
- Os kits de cenário da mesma família (Castle Kit, Tower Defense Kit, Mini
  Arena, Mini Market) dão variedade às 45 arenas sem sair do estilo.
- O UI Pack em vetor e o Input Prompts (com os botões do PS5) dão acabamento
  à interface.

**O que atrapalha:**
- **Estilos que brigam.** O pacote tem os Mini (atarracados, com paleta), os
  Blocky (cúbicos), os Animated Characters (humanoides, outro esqueleto), os
  kits antigos de cor sólida (Nature, Space), o Retro Urban (texturas estilo
  PS1) e 154 pacotes 2D, a maioria em pixel-art. Juntos, o jogo vira colcha
  de retalhos — o contrário das regras do [11](11-arte-e-personagens.md#as-regras-de-coerência).
- **O arquivo de cores com o mesmo nome.** Cada pacote traz o seu
  `Textures/colormap.png`, com cores diferentes, e os modelos apontam para ele
  pelo caminho. Dois pacotes na mesma pasta estragam as cores de um deles.
- **O peso.** Mais de 1 GB, com cada modelo repetido em três a cinco formatos.

## A curadoria

Medido pacote a pacote (os zips grátis abertos e os `.glb` lidos): **39 dos
54 kits 3D usam o mesmo estilo do Mini Dungeon** — um material `colormap` com
a sua `Textures/colormap.png`, cores da mesma família, fosco. Esses podem
entrar, cada um na sua pasta e **só quando uma ficha pedir**. Os outros não.

| tipo | entra | não entra |
| --- | --- | --- |
| personagens | Mini Characters (12), Mini Dungeon, Mini Arena, Mini Forest, Mini Market, Mini Arcade, Mini Skate; os **personagens do Graveyard Kit** (esqueleto, fantasma, zumbi, vampiro, coveiro — mesmo esqueleto, 32 animações: os monstros do terror) | Blocky Characters (sem esqueleto de pele), Animated Characters (outro esqueleto, só FBX) |
| cenário e objetos | os kits com colormap: Castle, Tower Defense, Graveyard, Factory, Platformer, Pirate, Train, Survival, Fantasy Town, Blaster, Space Station, Prototype, Hexagon, Marble, Coaster, Minigolf, Car, Toy Car, Holiday, Food, Modular Buildings, Building, Modular Dungeon, Modular Cave, Modular Space, Cube Pets, Watercraft, City (Commercial, Industrial, Roads, Suburban) | os de cor sólida (Nature, Space, Racing, Furniture), os de textura própria (Retro Fantasy, Retro Urban), 3D Road Tiles, Brick Kit (peças de montar, fora do tom), os "(Classic)" e o Weapon Pack |
| interface | UI Pack e UI Pack Sci-fi, só a versão em vetor; Input Prompts, só "Default" e "Vector" | tudo em pixel e em 1-bit |
| áudio | Interface Sounds, UI Audio, Impact Sounds, Music Jingles, Digital Audio, Sci-fi Sounds | — |
| fontes | nenhuma: Space Grotesk e JetBrains Mono continuam (o [estudo 03](../estudos/03-o-sistema-visual-do-app-hefesto.md)) | as fontes da Kenney |
| 2D | nada | os 154 pacotes 2D |

**Os vidros:** alguns modelos do Factory, Mini Market, Mini Arcade, Food,
Building e Marble têm um material `glass` à parte; o Fantasy Town tem água em
cor sólida. Esses modelos passam pelo checklist de arte antes de entrar.

### A escala de cada kit

Os kits não têm a mesma escala entre si (medido nos `.glb`; a Kenney não
documenta). A escala que casa com os bonecos:

| kit | medida | fator em `Kit.peca` |
| --- | --- | --- |
| a série Mini, Graveyard, Prototype, Space Station, Fantasy Town, Holiday, Platformer | a mesma dos bonecos (parede 1,0; boneco 0,67 a 0,84) | 1× (o `K = 2.0` de hoje vale para todos) |
| Castle Kit | porta 0,61, portão 0,91 (o boneco fica mais alto que a porta) | 1,3 a 1,5× |
| Survival Kit | bigorna 0,34, barril 0,34 | 1,4× |
| Tower Defense Kit | escala de tabuleiro (canhão 0,53) | 1× como adereço grande; 1,5× como construção |
| Factory Kit | porta 1,6, parede 3,0 | 0,5× |
| Building Kit | parede 2,4 | 0,35× |
| Pirate Kit | porta 4,4, barril 1,34 | 0,35 a 0,4× |
| Cube Pets | cachorro 1,58 | 0,4× |
| Blaster Kit | blaster 0,8 de comprimento | 0,3× na mão do boneco |
| Modular Dungeon, Cave, Space | grade de 4 m | 0,25× |

O fator vai na tabela `ESCALA_DO_PACOTE` de `godot/scripts/mundo/kit.gd`
(ficha [G10](tarefas/G10-a-biblioteca-kenney.md)), e `Kit.peca` o aplica
sozinho a partir do nome do pacote.

### O que falta em todos

**Lava, balão, sino, dragão e mecha** não existem em nenhum kit. Eles se
montam com peças, pela regra 4 do [11](11-arte-e-personagens.md#as-regras-de-coerência)
(peças do kit mais um brilho): a lava continua o shader chapado d'A Viga; o
balão, um cesto do Pirate Kit com uma esfera facetada de 8 lados; o sino, o
cilindro de 8 lados que a G08 já refaz; o dragão, a cabeça em blocos com
olhos emissivos (como o guardião d'A Voz) sobre um corpo de peças do Castle e
do Factory; o mecha, braços `robot-arm` e `crane` do Factory sobre um tronco
de caixas.

## Os kits nos 45 minigames

A resposta ao "e nos minigames, não ajuda?": **ajuda em quase todos.** Cada
minigame ganha uma arena e objetos próprios, em vez de todos saírem do mesmo
Mini Dungeon e de caixas feitas à mão. A tabela é o ponto de partida do
cenário de cada ficha; a ficha do minigame importa o kit na primeira vez que
precisar (`python3 scripts/importar_kenney.py <zip> <pacote>`) e usa as peças
pelo nome real do arquivo.

| # | minigame | kits | peças (nomes reais dos `.glb`) |
| --- | --- | --- | --- |
| 1 | O Martelo de Hefesto | Survival, Graveyard | `workbench-anvil`, `tool-hammer`, `campfire-*`; `fire-basket` |
| 2 | Marcha dos Escudeiros | Factory, Castle | `conveyor-long`, `conveyor-stripe-*`, `piston-square`; muros |
| 3 | Portões de Néon | Castle, Modular Space, Factory | `metal-gate`, `gate`; `gate-lasers`; `piston-thin-square` |
| 4 | O Fole | Survival, Hexagon, Factory | `campfire-*`; `building-smelter`; `pipe-large*` |
| 5 | A Esteira de Escória | Factory | `conveyor*`, `piston-round`, `hopper-square`, `machine` |
| 6 | A Viga | Castle, Platformer | `bridge-straight`; `platform` (a lava continua o shader) |
| 7 | Pêndulos do Caos | Platformer, Factory | `saw`, `spike-block`, `block-moving*`; `crane` |
| 8 | Patinação de Dados | Tower Defense, Holiday, Platformer | `snow-*`, `detail-crystal*`; `snowflake-*`; `block-snow-*` |
| 9 | O Balão dos Foles | Pirate, Fantasy Town | cesto de `structure-*`; `windmill` (o balão é montado) |
| 10 | Mira Óptica | Blaster, Prototype, Mini Forest | `target-large`, `target-small`, `target-fragment-*`; `target-a-*`; `target` |
| 11 | O Molde | Survival, Factory | `workbench`; `machine-bed` |
| 12 | Quebra-Gelo | Tower Defense, Holiday | `detail-crystal-large`, `tile-crystal`; `snow-*` |
| 13 | Hackeando o Terminal | Space Station, Prototype | paredes e portas; os números `0`–`9`, `lever*`, `button-*` |
| 14 | A Pinça | Factory | `robot-arm-a`, `robot-arm-b`, `crane-magnet` |
| 15 | O Carimbo | Factory, Mini Market | `conveyor`, `machine`; caixas |
| 16 | O Cerco | Castle, Tower Defense | torres e muros; `weapon-ballista`, `weapon-ammo-*` |
| 17 | Fuga do Titã | Train, Castle, Factory | `railroad-*`, `train-carriage-*`, `train-locomotive-*`; o titã montado |
| 18 | Curto-Circuito | Platformer, Toy Car | `bomb`; `item-box` |
| 19 | Martelos Térmicos | Survival, Mini Arcade | `tool-hammer`; o fliperama de fundo |
| 20 | A Prensa | Factory | `piston-*` (com as animações do próprio `.glb`), `machine-fortified` |
| 21 | A Galeria | Blaster, Mini Arena | `target-*`; `weapon-rack` |
| 22 | Arco de Néon | Mini Forest | `weapon-bow`, `weapon-arrow`, `target` |
| 23 | Metralhadora de Feitiços | Blaster, Tower Defense | `blaster-*` (0,3×); `enemy-ufo-*` (a frota) |
| 24 | Espada de Fita | Mini Arena | a arena, `weapon-sword` |
| 25 | A Catapulta | Castle | `siege-catapult`, `siege-trebuchet`, torres e as versões `-demolished` |
| 26 | O Canto | Castle, Fantasy Town | `tower-hexagon-*`; o sino montado |
| 27 | Eco do Abismo | Modular Cave, Graveyard | a caverna (0,25×); `lantern-*` |
| 28 | Coral dos Quatro | Fantasy Town, Castle | a praça, `fountain-*`; o salão |
| 29 | Código do Dragão | Modular Dungeon, Hexagon | a sala (0,25×); `building-wizard-tower`; o dragão montado |
| 30 | Corta-Fio | Platformer, Factory | `bomb`; `pipe-*`, `lever-*` |
| 31 | Os Caminhos | Mini Forest, Hexagon, Tower Defense | trilhas, pontes, `tile-*` |
| 32 | Neblina de Dados | Graveyard | lápides, criptas, `iron-fence*`, `character-ghost` |
| 33 | Passo no Fosso | Tower Defense, Platformer | `tile-river-*`; `block-moving*` (o plasma é o shader) |
| 34 | Fuga do Mecha Cego | Graveyard, Modular Cave, Factory | o cenário escuro; o mecha montado com `robot-arm` e `crane` |
| 35 | Engrenagens Sincopadas | Factory, Marble | `cog-a` a `cog-e`; `fan-*` |
| 36 | A Voz | Survival, Castle | `campfire-*`; o guardião de pedra em blocos (G08) |
| 37 | O Sopro no Fole | Survival, Hexagon, Marble | `campfire-*`; `building-smelter`; `fan-*` |
| 38 | Zero Absoluto | Holiday, Tower Defense, Graveyard | `snowman`, `snow-*`; `detail-crystal`; `character-skeleton` (o guardião que escuta) |
| 39 | Grito de Guerra | Mini Arena | a arena de sumô |
| 40 | Palmas da Forja | Fantasy Town, Holiday | a praça em festa |
| 41 | A Prova | Mini Arena, Castle | a arena, as torres das duas equipes |
| 42 | Roubo de Bateria | Space Station, Platformer | corredores; `jewel` (a bateria), `chest` |
| 43 | Mecha de Dois Pilotos | Factory, City Industrial | os mechas montados; a cidade de fundo |
| 44 | Ruge o Reator | Hexagon, Castle, Tower Defense | o tabuleiro que desaba; o dragão montado |
| 45 | O Último Acorde | Castle, Graveyard, Tower Defense | o salão final; `detail-crystal-large` |

Dos 45, **só o Balão (9), o Código do Dragão (29), o Mecha Cego (34), o Mecha
de Dois Pilotos (43) e o Ruge o Reator (44) dependem de uma peça montada** —
e mesmo esses usam kits para todo o resto.

## Como entra no repositório

- **O zip do All-in-1 fica fora do repositório**, na máquina do André.
- **Um pacote por pasta:** `godot/assets/kenney/<pacote>/` — por exemplo
  `godot/assets/kenney/mini-characters/`, `godot/assets/kenney/castle-kit/`.
  O Mini Dungeon de hoje (solto em `godot/assets/kenney/`) se muda para
  `godot/assets/kenney/mini-dungeon/`.
- **Só o necessário:** de cada pacote 3D, só a pasta `GLB format/` (os
  `.glb`) e a pasta `Textures/`; nada de FBX, OBJ, DAE, STL nem prévias. O
  Mini Characters inteiro tem 13,9 MB; o que entra dele, cerca de 3,5 MB.
- **O script faz a cópia:** `scripts/importar_kenney.py <zip ou pasta> <pacote>`
  (ficha [G10](tarefas/G10-a-biblioteca-kenney.md)) copia só o que entra,
  recusa pacote fora da curadoria, confere o esqueleto dos personagens com
  `scripts/conferir_bonecos.py` (G08), converte o áudio para WAV 48 kHz mono,
  e escreve a linha do pacote em `godot/assets/LEIA-ME.md` e em
  `LICENCAS-DE-TERCEIROS.md` (nome, versão, CC0).
- **O código pede a peça pelo pacote:** `Kit.peca(pai, "castle-kit/tower", ...)`;
  sem pacote no nome, vale o `mini-dungeon` (para as salas de hoje não
  quebrarem).
- **Early access fica fora** do repositório público até virar gratuito no
  site.

A estimativa do que entra curado: os personagens (Mini Characters, Arena,
Market) somam perto de 10 MB; cada kit de cenário, de 5 a 20 MB só com o GLB;
a interface, perto de 10 MB; o áudio convertido, perto de 20 MB. Tudo junto
fica abaixo de 100 MB, contra mais de 1 GB do pacote inteiro.

## Recolorir

- **A cor do jogador** não tinge mais o corpo (09/10/2026): o `_vestir()` de
  `godot/scripts/player.gd` deixa de multiplicar o material pela cor do lugar.
  A cor do lugar vai no contorno e nos acentos de cada peça, pela regra do
  [arte/04](arte/04-o-cavaleiro.md#a-peça-se-distingue).
- **A paleta de um pacote inteiro** (por exemplo, o Castle Kit mais escuro e
  lilás, para combinar com a luz da casa): edita-se uma **cópia** do
  `colormap.png` dentro da pasta do pacote. Cada bloco de cor da imagem é uma
  cor de todos os modelos do pacote.
- **A variação de um objeto só:** um material por instância com a textura
  alterada, nunca editando a textura compartilhada.
- **Sempre sem compressão.** A textura de paleta entra sem compressão e com
  filtro "nearest" (é o que os `.glb` da Kenney pedem); comprimida, a cor
  vira faixas.

## Os ícones de botão

Os desenhos de hoje (`godot/assets/glifos/`) vêm do app Hefesto, sob MIT, e
já cobrem os botões, os gatilhos, o giroscópio, o acelerômetro, o touchpad, a
barra de luz, o alto-falante e o microfone. Os do Input Prompts (vetor, com os
botões do PS5 nomeados por geração, como `playstation5_button_create`) entram
**só onde faltar desenho**, redesenhados no mesmo traço e nas cores do
`Tema`. Só o desenho do botão: nunca o logo da PlayStation nem o da Kenney.

## A interface

O UI Pack e o UI Pack Sci-fi (em vetor) dão molduras, painéis, barras e
botões. Eles entram **reatribuídos às cores do `Tema`** (a paleta Dracula do
[estudo 03](../estudos/03-o-sistema-visual-do-app-hefesto.md)), nunca nas
cores originais, e passam pela coleta de texto e pela prova visual como
qualquer tela. A ficha é a [G11](tarefas/G11-a-interface-com-o-ui-pack.md).

## O áudio

Os pacotes de áudio da Kenney vêm só em `.ogg`. Os efeitos do jogo são WAV 48
kHz mono (carregados inteiros na memória, [04](04-ritmo-e-audio.md#os-efeitos));
o script de importação converte. Os `Music Jingles` servem de jingle
provisório até os jingles próprios chegarem (ficha H06).
