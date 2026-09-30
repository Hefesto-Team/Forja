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

O que pode entrar, e o que não entra:

| tipo | entra | não entra |
| --- | --- | --- |
| personagens | Mini Characters (12), Mini Arena, Mini Market, Mini Dungeon (já está) | Blocky Characters (sem esqueleto de pele), Animated Characters (outro esqueleto, só FBX) |
| cenários | Castle Kit, Tower Defense Kit, Mini Dungeon, Mini Arena, Mini Market | Nature Kit e Space Kit (cor sólida, outro traço), Retro Urban Kit, os pacotes "(Classic)" |
| interface | UI Pack e UI Pack Sci-fi, só a versão em vetor; Input Prompts, só "Default" e "Vector" | tudo em pixel e em 1-bit |
| áudio | Interface Sounds, UI Audio, Impact Sounds, Music Jingles, Digital Audio, Sci-fi Sounds | — |
| fontes | nenhuma: Space Grotesk e JetBrains Mono continuam (o [estudo 03](../estudos/03-o-sistema-visual-do-app-hefesto.md)) | as fontes da Kenney |
| 2D | nada | os 154 pacotes 2D |

Pacote que não está na coluna "entra" só entra depois de uma linha nova nesta
tabela, com o porquê, e do checklist de arte do [11](11-arte-e-personagens.md#o-checklist-de-aprovação).

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

- **A cor do jogador** continua como hoje: no material do corpo do boneco
  (`_vestir()` em `godot/scripts/player.gd`), multiplicada pela cor do lugar.
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
