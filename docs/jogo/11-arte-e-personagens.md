# 11 — A arte e os personagens

O estilo do Forja é bom: o kit Kenney fosco e em blocos, a luz de tocha, o
néon na parede, a névoa lilás. O que falta é **variedade de personagem** —
hoje são dois bonecos, um humano e um orc — e **coerência**: algumas peças
feitas à mão não parecem do mesmo jogo. Esta página decide as regras, o que
se refaz e de onde vêm os bonecos novos.

## As regras de coerência

Tudo o que entra na tela segue o kit Kenney Mini Dungeon
(`godot/assets/kenney/`):

1. **Fosco.** Material com a paleta de `godot/assets/kenney/Textures/colormap.png`
   ou cor lisa sem brilho. `metallic` no máximo 0,2; metal é cor, não reflexo.
2. **Facetado e em blocos.** Nenhuma esfera, elipsoide ou cilindro liso
   visível de perto. Curva se faz com poucos lados (6 a 8 segmentos) ou com
   caixas.
3. **Proporção chibi.** Cabeça grande, corpo curto — como os bonecos. Um
   monstro pode ser enorme, mas com a mesma proporção.
4. **Monstro é peça do kit mais um detalhe que brilha.** O modelo é a
   sentinela do Impacto (`godot/scripts/salas/impacto.gd:124-133`): a
   `column` do kit com um olho emissivo. Chefes e criaturas são montados de
   peças do kit, caixas e um brilho.
5. **O brilho tem dono.** Emissivo só em olho, runa, borda de raia, néon e
   efeito de acerto. O resto é iluminado pela cena.
6. **A cor do jogador é sagrada.** Nada no cenário usa as quatro cores dos
   lugares (`COR_DO_LUGAR` em `godot/scripts/forja.gd`) a não ser para
   marcar aquele jogador.
7. **Luz da casa.** Tocha `#ffb070`, enchimento lilás `#b9b0ff`, névoa
   `#241f33` (`godot/scripts/salas/sala.gd`, `godot/scripts/main.gd:91-113`).
   Um minigame de terror escurece tudo isso, não troca.
8. **Escala 2.0.** As peças do kit entram com a escala `K = 2.0` de
   `godot/scripts/mundo/kit.gd`; o boneco tem cerca de 1,5 m.

### O checklist de aprovação

Todo objeto novo passa pelos oito, antes do commit:

- [ ] é fosco (`metallic` ≤ 0,2)?
- [ ] tem forma facetada ou em blocos, sem curva lisa visível?
- [ ] a proporção conversa com os bonecos?
- [ ] se é criatura, é feita de peças do kit mais um brilho?
- [ ] o emissivo está só onde tem trabalho?
- [ ] não usa a cor de nenhum lugar sem ser dele?
- [ ] foi visto na foto da tela (`godot/testes/captura_jogo.gd`) ao lado de um boneco?
- [ ] a licença está anotada, se veio de fora?

## O que destoa hoje

| o quê | onde | por quê destoa | o que vira |
| --- | --- | --- | --- |
| o guardião d'A Voz | `godot/scripts/salas/voz.gd:107-164` | um elipsoide liso de bronze metálico e reflexivo, com sobrancelha e dentes de caixa colados na curva; uma cara solta de 3,4 m sem corpo, realista-grotesca ao lado de bonecos chibi | uma cabeça de pedra em blocos, montada com peças do kit (paredes, colunas, suportes), com os olhos emissivos e a boca que abre em degraus; a mesma animação de pálpebra e susto |
| os alvos e as runas redondas | `godot/scripts/salas/galeria.gd:141`, `godot/scripts/salas/centelha.gd:115` | discos e toros lisos | discos de 8 lados e runas em placas |
| o "ouro" do Molde | `godot/scripts/salas/molde.gd:420` | material metálico brilhante | ouro fosco, cor da paleta |
| as bordas de raia em toro | caminhos, canto, centelha, galeria, impacto, voz | toro liso emissivo | anel de 8 lados; continua emissivo (é borda, tem trabalho) |
| a lava com shader | `godot/scripts/salas/viga.gd:160` | — | **fica**: é chão e ambiente, e o shader já é chapado |

## Os personagens

A meta é **doze bonecos** na construção do cavaleiro, todos no mesmo
esqueleto, para que cada pessoa ache "o seu". Hoje: dois
(`godot/assets/kenney/character-human.glb` e `character-orc.glb`).

O que já existe e ajuda (`godot/scripts/player.gd`):

- os dois bonecos têm **o mesmo esqueleto** de sete ossos (`root`, `leg-left`,
  `leg-right`, `torso`, `arm-left`, `arm-right`, `head`) e as mesmas 32
  animações (`idle`, `walk`, `sprint`, `jump`, `fall`, `die`, `emote-yes`,
  `emote-no`, `attack-melee-right`, `holding-right`…);
- cabeça e corpo são **malhas separadas** (`head-mesh` e `body-mesh`);
- a cor do lugar é aplicada nas malhas `body*` (`_vestir()`);
- o item se prende a um osso com `BoneAttachment3D` (`_segurar()`).

Os bonecos novos vêm de três fontes, que se somam:

### (a) Kenney da mesma família

Pacotes CC0 da Kenney na mesma linha "mini". O **Mini Characters** tem os
mesmos sete ossos e as mesmas 32 animações (conferido no arquivo) e, sozinho,
traz doze bonecos. Quais pacotes entram, como entram e por que os outros
ficam de fora está em [14 — os assets da Kenney](14-os-assets-kenney.md); a
importação é a ficha [G10](tarefas/G10-a-biblioteca-kenney.md), que confere
o esqueleto de cada boneco antes de copiar. Um boneco que não bate não entra,
porque quebraria todas as salas que tocam animação por nome.

### (b) Montar peças

Com cabeça e corpo separados, cada cabeça combina com cada corpo. E as peças
de identidade se prendem ao osso `head` ou `torso` como o item se prende à
mão:

| peça | onde prende | de que é feita |
| --- | --- | --- |
| elmo (fechado, com chifre, com crista) | `head` | caixas e peças do kit |
| capa | `torso`, atrás | duas placas finas que balançam com o `walk` |
| ombreira | `arm-left` e `arm-right` | caixas facetadas |
| barba, máscara, capuz | `head` | caixas |

Duas cabeças × dois corpos × quatro peças já dão dezesseis silhuetas
diferentes antes do primeiro modelo novo.

### (c) Os bonecos do André

O contrato técnico para um boneco feito à mão entrar sem mexer em código:

| regra | valor |
| --- | --- |
| formato | glTF binário (`.glb`) |
| esqueleto | os mesmos sete ossos, com os mesmos nomes e a mesma hierarquia |
| animações | os mesmos nomes do kit; no mínimo `idle`, `walk`, `sprint`, `jump`, `fall`, `die`, `emote-yes`, `emote-no`, `attack-melee-right`, `holding-right` |
| malhas | o corpo com nome começando em `body` (recebe a cor do lugar); a cabeça separada |
| textura | a paleta `colormap.png`, ou uma paleta própria de no máximo 32 cores, fosca |
| tamanho | até 1.500 triângulos |
| escala e origem | a altura de um boneco do kit; a origem entre os pés |
| licença | a do autor, anotada em `LICENCAS-DE-TERCEIROS.md` e em `godot/assets/LEIA-ME.md` |

Um boneco é registrado em `MODELOS` e `NOME_DO_MODELO` de
`godot/scripts/player.gd`, com o seu pio (o som próprio no alto-falante do
controle, [05](05-haptica-e-controle.md#a-agenda-do-alto-falante)).

## As tarefas

A ficha [G08](tarefas/G08-a-arte-bonecos-e-coerencia.md) faz o que esta
página decide: os bonecos das fontes (a) e (b), o contrato para (c) e as
peças que destoam.
