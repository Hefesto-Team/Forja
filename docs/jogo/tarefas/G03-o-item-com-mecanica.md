# G03 — O item com mecânica

**Sprint:** G · **Tamanho:** M · **Depende de:** F00, F05, F06, G02, G08 (parte A: `Pintura` e o acento), G10 (o `survival-kit`) · **Usado por:** G04 (o cartão do item), G13 (escreve `Itens.em_liga`), H04 (o kit chama o `Itens` no julgamento)

## Por quê

O item escolhido na construção hoje é só um nome. Cada um dos seis passa a
ser um poder pequeno com um preço: se vê no corpo (na mão, no braço ou no
peito), se sente no L2, vai para o registro e vale a mesma regra nos 45
minigames.

## Ler antes

- [O item tem mecânica](../06b-a-construcao-do-cavaleiro.md#o-item-tem-mecânica) (a tabela dos seis, a troca e a liga)
- [A arma ou o amuleto](../arte/04-o-cavaleiro.md#a-arma-ou-o-amuleto) (onde cada um fica e de onde vem a malha)
- [O item — G03](../13-arquitetura.md#o-item--g03) e a seção seguinte do mesmo arquivo, «O kit do minigame — H04» (quem chama)

## Arquivos que mudam

| arquivo | também muda em |
| --- | --- |
| `godot/scripts/itens.gd` e `.uid` (novos, `class_name Itens`) | **G04, G13, H04** (só leem; a G13 escreve `em_liga`) |
| `godot/scripts/player.gd` (`_segurar`, `_runa`, `_mats_runa`, `POSE_DO_ITEM` sai) | **G01, G02, G08, G13** |
| `godot/scripts/ui/tela_lobby.gd` (`_sentir_o_item`, `_forjou`, `abrir`) | **G02, G13** |
| `godot/scripts/main.gd` (`_todos_entram`) | **G01, G02, G04, G05, G06, G07, G08** |
| `godot/scripts/salas/sala_jogo.gd` (`usa_gatilho`, `errou`) | **H04** |
| `godot/scripts/salas/centelha.gd`, `galeria.gd`, `prova.gd`, `bancada.gd` | — |
| `godot/assets/sons/ui_peca.wav` e `docs/jogo/audio/mapa.csv` | **G01, G02, G04, G06, G07, G13** |
| `docs/jogo/13-arquitetura.md` (o bloco de [O item — G03](../13-arquitetura.md#o-item--g03)) | — |
| `godot/testes/prova_do_jogo.gd` | **todas as G** |

## Como se joga

Não se aplica como minigame. As regras do item, que todo minigame pergunta à
classe `Itens` (a fonte é `docs/jogo/sistemas/itens.csv`):

| item | tipo | pede | em liga com | o que faz | a troca (fora da liga) | em liga |
| --- | --- | --- | --- | --- | --- | --- |
| Martelo | arma, mão direita | Peso 4 | Peso 5 | o perfeito no tempo forte vale × 2 | o acerto fora do tempo forte vale 85 % | 100 % |
| Âncora | arma, mão direita | Peso 3, Fôlego 3 | Peso 4, Fôlego 4 | sofre 0,5 do empurrão | anda a 0,9 da velocidade na corrida | 1,0 |
| Escudo | arma, braço esquerdo | Passo 3, Faro 3 | Passo 4, Faro 4 | absorve o primeiro erro de cada minigame | começa o minigame com o combo em 0 | começa com o bônus de entrada |
| Fole | amuleto, peito | Fôlego 4 | Fôlego 5 | depois de um erro, o combo volta na metade dos acertos | o combo máximo é 3/4 | o normal |
| Lanterna | amuleto, peito | Faro 4 | Faro 5 | a pista chega meio tempo antes (30/BPM s) | a janela perfeito encolhe 10 ms (5 de cada lado) | não encolhe |
| Diapasão | amuleto, peito | Passo 4 | Passo 5 | a nota a × 1,3 e o perfeito puxa o combo da equipe (2v2 e coop) | no todos contra todos (`"tct"`), nada | no `"tct"`, a nota a × 1,3 |

O «pede» e o «riscado» da tela são da G13 (ela lê os stats). Esta ficha
recebe `Itens.em_liga[l]` pronto e, até a G13, ele fica `false` nos quatro.

## A cena

O item aparece no corpo, preso por um `BoneAttachment3D` chamado `"Item"`.
As posições são no espaço do osso, em unidades do modelo (o player escala o
modelo por `ESCALA` 2,0).

| item | osso | a malha | posição | rotação (graus) | escala |
| --- | --- | --- | --- | --- | --- |
| Martelo | `arm-right` | `load(Kit.caminho("survival-kit/tool-hammer"))` | `(-0.01, -0.13, 0.0)` | `(60, 0, 0)` | 2,3 |
| Escudo | `arm-left` | `load(Kit.caminho("shield-round"))` | `(0.03, -0.07, 0.075)` | `(0, 0, 0)` | 0,9 |
| Âncora | `arm-right` | por código (abaixo) | `(-0.01, -0.13, 0.0)` | `(60, 0, 0)` | 1,0 |
| Fole, Lanterna, Diapasão | `torso` | o medalhão, por código (abaixo) | `rest.affine_inverse() * Vector3(0, 0.28, 0.105)`, com `rest = esqueleto.get_bone_global_rest(esqueleto.find_bone("torso"))` (o meio do peito, 0,005 à frente da frente do torso) | `(0, 0, 0)` em relação ao modelo (`presa.global_basis` desfeita pelo `rest.basis.inverse()`) | 1,0 |
| Mãos livres | — | nada | — | — | — |

**A cor das peças** (arte/02, «a escada de valor»: arma em metal batido, L de
0,68 a 0,80, croma até 0,03, rugosidade de 0,45 a 0,62, `metallic` 0,2;
amuleto em cerâmica, L de 0,68 a 0,80, croma de 0,04 a 0,08, rugosidade
0,35, o emblema em latão com `metallic` 0,2). Os três tons, medidos em OKLab
dentro dessas faixas, moram em `Itens` (constantes, não tokens de tela):

| constante | hex | L | croma | ΔE até o néon mais perto |
| --- | --- | --- | --- | --- |
| `Itens.METAL` | `#9ba6b1` | 0,72 | 0,020 | 0,180 (ciano) |
| `Itens.CERAMICA` | `#c9b08f` | 0,77 | 0,053 | 0,105 (âmbar) |
| `Itens.LATAO` | `#b59b63` | 0,70 | 0,080 | 0,099 (âmbar) |

- **As malhas da Kenney** (Martelo, Escudo): cada superfície ganha uma cópia
  do `StandardMaterial3D` com `albedo_texture = Pintura.textura(<a pasta do .glb>/Textures/colormap.png, "objeto")`,
  `roughness` 0,55, `metallic` 0,2.
- **A Âncora** (caixas por `Kit.caixa`, material
  `Kit.material(Itens.METAL, 0.0, 0.55)` com `metallic = 0.2`; a pega na
  origem, para cima em +y, como `Kit.martelo`): a haste `(0.025, 0.20, 0.025)`
  em `(0, 0.10, 0)`; o anel de cima `(0.06, 0.02, 0.02)` em `(0, 0.21, 0)`; a
  travessa `(0.10, 0.02, 0.02)` em `(0, 0.17, 0)`; os dois braços
  `(0.07, 0.02, 0.02)` em `(±0.04, 0.015, 0)` com `rotation.z = ±0.6`.
- **O medalhão** (12 cm no mundo = 0,06 de diâmetro no modelo): o disco é um
  `CylinderMesh` de `radial_segments` 8, raio 0,03, altura 0,008, girado
  90° em x (a face para +z), material `Kit.material(Itens.CERAMICA, 0.0, 0.35)`;
  o emblema em relevo, caixas de profundidade 0,004 em z +0,006, material
  `Kit.material(Itens.LATAO, 0.0, 0.5)` com `metallic = 0.2`:

| amuleto | o emblema (tamanho; posição no disco) |
| --- | --- |
| Fole | as tábuas `(0.022, 0.026)` em `(0, 0.002)`; o bico `(0.006, 0.010)` em `(0, -0.016)` |
| Lanterna | o corpo `(0.016, 0.022)` em `(0, -0.002)`; a alça `(0.012, 0.003)` em `(0, 0.012)` |
| Diapasão | as hastes `(0.004, 0.024)` em `(±0.006, 0.004)`; a base `(0.016, 0.004)` em `(0, -0.008)`; o cabo `(0.004, 0.012)` em `(0, -0.016)` |

- **A runa** (o acento do item, arte/04: 12 % da área do item no máximo,
  energia 1,6, 2,6 no encaixe; arte/02: no item, num vão `Tema.JANELA` com
  1,5 vez a largura dela). `_runa(pai, tamanho, pos)` põe duas caixas: o vão,
  com `tamanho` × 1,5 nos dois lados da face, profundidade 0,001, em
  `Kit.material(Tema.JANELA, 0.0, 0.9)`, 0,001 atrás; e a linha, com o
  `tamanho`, no néon do dono (`Tema.neon(Tema.JOGADOR[lugar], 1.6, lugar)` da
  G15; sem ela, `Kit.material(Tema.JOGADOR[lugar], 1.6)`). O material da linha
  entra em `_mats_runa`, e `_area_runa` soma `tamanho.x * tamanho.y`.
  `_segurar()` guarda em `_area_item` a área de frente do item (x × y do
  AABB das malhas, no espaço do `"Item"`). A prova confere
  `_area_runa <= 0.12 * _area_item` (o medalhão dá 6,7 %, o escudo 7,5 %).

| item | a runa |
| --- | --- |
| Martelo | o fio: na face de bater, `tamanho` `(0.002, 0.25 * h, 0.8 * d)` no x máximo dos 25 % de cima do AABB da malha (`h` e `d`: altura e fundura do AABB) |
| Escudo | o aro: um octógono de 8 caixas `(0.746 * r, 0.05 * r, 0.004)`, cada uma girada `i * 45°` em z e posta a 0,975 r do centro (`r` = metade do maior lado do AABB), na face +z (z = o máximo do AABB + 0,002) |
| Âncora | as unhas: `(0.02, 0.02, 0.02)` na ponta de cada braço |
| amuletos | o quadro em volta do emblema: 4 linhas de largura 0,002 formando um quadrado de 0,030 de lado |

- **O que brilha e de quem:** só a runa, no néon do dono, a 1,6. O item não
  tem contorno próprio: o contorno do corpo (G08) é a silhueta do dono. A
  chama, a lâmina, o latão: nada emite.

## O som

| quando | id do mapa | onde | volume e tom |
| --- | --- | --- | --- |
| trocar o item, na construção | `ui_peca` | TV (`Som.tocar("ui_peca", null, -12.0, 0.7492)`) e o alto-falante do dono (`Som.no_controle(l, "ui_peca", 0.85)`) | −12 dB, −5 semitons na TV (`pitch_scale` 0,7492); o alto-falante toca o PCM sem tom |
| o Escudo absorve um erro | `escudo_0..4` (`Som.tocar("escudo", pos, -4.0)` e `Som.no_controle(l, "escudo", 0.8)`) | TV, na posição do cavaleiro, e o alto-falante do dono | −4 dB na TV, ganho 0,8 no controle |

`ui_peca` está no estudo e falta no jogo. O encanamento, igual nas fichas
G01, G09, G11, G12 e G16 (se outra ficha já fez, usar o dela): copiar
`godot/estudos/direcao/som/ui_peca.wav` para `godot/assets/sons/`;
`"$GODOT" --headless --path godot --import --quit` e conferir
`compress/mode=0` no `ui_peca.wav.import`; `Som.tocar` e `Som.no_controle`
tocam primeiro `res://assets/sons/<nome>.wav` quando ele existe; no
`docs/jogo/audio/mapa.csv`, a linha `ui_peca` ganha `arquivo` =
`godot/assets/sons/ui_peca.wav` e `estado` = `no jogo`. O sopro do
Fole, o golpe mais pesado do Martelo e o bipe fraco da Lanterna são do kit
(H04), não daqui.

## O controle

| evento | para quem | vibração (forte/fraco/ms) | gatilho L2 | luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| trocar o item, na construção | o dono | acerto 0,3/0,6/80 | o do item novo (`Itens.sentir`) | não muda | `ui_peca` |
| Escudo inteiro (construção e sala sem gatilho próprio) | o dono | — | Resistência, início 2, força 4 (`0x21` na percepção) | — | — |
| Âncora (sempre) | o dono | — | Resistência, início 2, força 2 (`0x21`) | — | — |
| os outros quatro, ou o Escudo quebrado | o dono | — | Off (`0x05`) | — | — |
| o Escudo absorve | o dono | golpe 1,0/0,6/250 | passa a Off | não muda | `escudo_*` |
| o resto | — | nada | o R2 é das salas e das provas: o item nunca toca nele | nada | nada |

Nas salas que usam o gatilho (`usa_gatilho`: Galeria, A Prova, a Bancada), o
item não mexe no L2.

Sem o controle na mão: `Forja.ctl.percepcao(Forja.pad_do_lugar(l))` traz
`gatilho_esq` (o modo do L2) e `forte`/`fraco`; `Forja.som_virtual(l).falante`
mede o alto-falante. A prova confere o L2 do Escudo antes e depois da
quebra, o golpe na mão e o som no controle do dono (Provas).

## O cavaleiro

- **Os stats:** esta ficha não lê stat. O que o item pede e a liga são da
  G13, que escreve `Itens.em_liga[l]` ao forjar. Com `em_liga[l]`, as funções
  da troca devolvem o valor da coluna «em liga» de Como se joga.
- **O item no corpo:** a tabela de A cena. O item claro (L 0,68 a 0,80) se lê
  contra o tecido do braço (0,46 a 0,58) e do peito.
- **`Itens.escolhido`, não `jogadores[l].item_i`:** a sala tira o item
  visual (`maos_livres`); a mecânica segue o que foi escolhido.

## As reações

Não se aplica: nenhum item dispara reação. O carimbo `car_liga` (a liga na
linha Arma ou amuleto da montagem) é da G13 e da G04.

## A diversão

**O momento:** na Centelha, a primeira runa errada de quem leva o Escudo não
custa nada: a TV e o controle dele soam o metal, a mão sente o golpe de
250 ms e o L2, que estava firme desde a construção, afrouxa. Ele sabe que o
escudo quebrou sem olhar a tela. **Como se confere:**

1. A prova mede no P2 de Escudo, sem o controle na mão: o L2 em `0x21` antes,
   `forte` > 0 e `falante` > 0 no erro, o L2 em `0x05` depois, e o combo
   intacto. O segundo erro zera o combo.
2. O registro da partida tem `item` / `absorveu` (a prova lê a linha do
   tempo).
3. A prancha da construção da prova visual mostra as quatro colunas com o
   item no corpo; o jogador do time confere que nenhum atravessa o corpo e
   anota no diário.

## O estado de hoje

- `godot/scripts/player.gd:16-24`: `ITENS` antigos (mãos livres, espada,
  lança, espada e escudo, lança e escudo, poção, chave); a G02 os troca pelos
  sete (0 «Mãos livres», 1 «Martelo», 2 «Escudo», 3 «Fole», 4 «Lanterna»,
  5 «Diapasão», 6 «Âncora»), cada um com `"icone"` e **sem peça 3D**.
- `player.gd:30-36`: `POSE_DO_ITEM` (o escudo em `(0.03, -0.07, 0.075)`,
  escala 0,9). `player.gd:132-152`, `_segurar()`: apaga todo
  `BoneAttachment3D` do esqueleto e prende as peças `"direita"`/`"esquerda"`
  carregando `res://assets/kenney/%s.glb`.
- `godot/scripts/mundo/kit.gd`: `peca` (11), `material(cor, brilho, rugoso)`
  (35), `caixa` (60), `martelo` (103). O martelo da Kenney está só no estudo
  (`godot/estudos/direcao/kenney/survival-kit/tool-hammer.glb`, preso em
  `godot/estudos/direcao/mundo.gd:145-155`); a G10 o traz para
  `godot/assets/kenney/survival-kit/`.
- `godot/scripts/salas/sala.gd:52`: `jogador(lugar) -> ForjaPlayer`.
- `godot/scripts/salas/sala_jogo.gd`: `treinando` (82), `entrar()` (95),
  `maos_livres(p)` (128, tira o item **visual** com `p.visual(p.modelo_i, 0)`),
  `comecar()` (300), `terminar()` (337), `marcar()` (435). Não há gancho de
  erro.
- `godot/scripts/salas/centelha.gd:267-270`: o botão errado (`e.combo = 0`,
  `e.tremor = 0.6`, `Som.tocar("falha", …)`); `_perdeu(l, p)` (350-363):
  `e.combo = 0`, `e.tremor = 1.0`, `"falha"`, `emote-no`, a runa volta à fila
  se `tentativas < MAX_TENTATIVAS`; `_proxima(l)` (365) avança.
- Os gatilhos: `galeria.gd:185-195` e `prova.gd:236-238, 302` usam
  `Forja.gatilho`; `galeria.gd:57` e `prova.gd:85` montam `features` no
  `_init()`; `bancada.gd:80` tem `_init()`. `Forja.gatilho(l, lado, modo, a, b, c)`
  (`forja.gd:468`, lado 0 = L2), `GATILHO_OFF` 0, `GATILHO_RESISTENCIA` 1.
- As provas conferem o R2 solto (`0x05`) no salão e depois de cada sala
  (`godot/testes/prova_do_jogo.gd:299, 401`) e o L2 solto na Galeria (158).
- `godot/assets/sons/escudo_0..4.wav` estão no jogo (`Som.GRAVADOS`,
  `som.gd:41`); `ui_peca.wav` não.
- Não existe `godot/scripts/itens.gd`.

## O alvo

### A classe `Itens` (`godot/scripts/itens.gd`, `class_name Itens extends RefCounted`, estática)

```gdscript
enum { NENHUM, MARTELO, ESCUDO, FOLE, LANTERNA, DIAPASAO, ANCORA }
## O julgamento, na numeração do Ritmo (13): ERRO 0, BOM 1, OTIMO 2, PERFEITO 3.
const PERFEITO := 3
## Os tons das peças (arte/02, a escada de valor), medidos em OKLab.
const METAL := Color("#9ba6b1")     ## L 0,72, croma 0,020: a arma
const CERAMICA := Color("#c9b08f")  ## L 0,770, croma 0,053: o disco do amuleto (o Fita.CERAMICA do estudo, fita.gd:131)
const LATAO := Color("#b59b63")     ## L 0,70, croma 0,080: o emblema
## O item de cada lugar, para a mecânica (a construção escreve; a sala não mexe).
static var escolhido := [NENHUM, NENHUM, NENHUM, NENHUM]
## O item em liga (a G13 escreve ao forjar, pelos stats; até lá, false).
static var em_liga := [false, false, false, false]
static var _escudo := [true, true, true, true]

static func do_lugar(l: int) -> int
static func pontos_do_acerto(l: int, pontos: int, julgamento: int, no_tempo_forte: bool) -> int
static func absorve_erro(l: int) -> bool
static func escudo_inteiro(l: int) -> bool
static func combo_inicial(l: int, normal: int) -> int
static func acertos_para_voltar_o_combo(l: int, normal: int) -> int
static func combo_maximo(l: int, normal: int) -> int
static func antecipacao_s(l: int, bpm: float) -> float
static func janela_perfeito(l: int, janela: Vector2) -> Vector2
static func ganho_da_nota(l: int, genero: String) -> float
static func puxa_o_combo_da_equipe(l: int, genero: String) -> bool
static func resiste_a_empurrao(l: int) -> float
static func velocidade(l: int, genero: String) -> float
static func sentir(l: int) -> void
static func novo_minigame() -> void          # repõe o Escudo dos quatro
static func registrar(l: int, efeito: String) -> void
```

| função | o item | com o item, fora da liga | em liga | os outros |
| --- | --- | --- | --- | --- |
| `pontos_do_acerto` | MARTELO | `pontos * 2` com `julgamento == PERFEITO and no_tempo_forte`; `int(round(pontos * 0.85))` com `not no_tempo_forte` | `pontos * 2` no perfeito do tempo forte; `pontos` fora | `pontos` |
| `absorve_erro` | ESCUDO | `true` se `_escudo[l]`; põe `_escudo[l] = false`, `registrar(l, "absorveu")` | o mesmo | `false` |
| `combo_inicial` | ESCUDO | `0` | `normal` | `normal` |
| `acertos_para_voltar_o_combo` | FOLE | `int(ceil(normal / 2.0))` | o mesmo | `normal` |
| `combo_maximo` | FOLE | `int(normal * 3 / 4)` | `normal` | `normal` |
| `antecipacao_s` | LANTERNA | `30.0 / bpm` | o mesmo | `0.0` |
| `janela_perfeito` | LANTERNA | `Vector2(janela.x + 0.005, janela.y - 0.005)` | `janela` | `janela` |
| `ganho_da_nota` | DIAPASAO | `1.3` se `genero != "tct"`, senão `1.0` | `1.3` sempre | `1.0` |
| `puxa_o_combo_da_equipe` | DIAPASAO | `genero in ["2v2", "coop"]` | o mesmo | `false` |
| `resiste_a_empurrao` | ANCORA | `0.5` | o mesmo | `0.0` |
| `velocidade` | ANCORA | `0.9` se `genero == "corrida"`, senão `1.0` | `1.0` | `1.0` |

`sentir(l)`: ESCUDO com `_escudo[l]` →
`Forja.gatilho(l, 0, Forja.GATILHO_RESISTENCIA, 2, 4)`; ANCORA →
`Forja.gatilho(l, 0, Forja.GATILHO_RESISTENCIA, 2, 2)`; senão
`Forja.gatilho(l, 0, Forja.GATILHO_OFF)`. **Só o L2** (lado 0).

`registrar(l, efeito)`:
`Forja.evento("item", l + 1, {"item": ForjaPlayer.ITENS[do_lugar(l)].nome, "efeito": efeito, "em_liga": em_liga[l]})`
e `Forja.registrar("P%d: %s %s" % [l + 1, nome, efeito])`. Os efeitos desta
ficha: `"leva"` (ao entrar num minigame), `"absorveu"`, `"quebrou"`; os do kit
(`"dobrou"`, `"antecipou"`, `"puxou"`, `"resistiu"`) vêm com a H04.

### O item no corpo (`godot/scripts/player.gd`)

```gdscript
var _mats_runa: Array[Material] = []  ## a linha da runa do item, para acender e o encaixe
var _area_runa := 0.0   ## a área de frente das linhas da runa
var _area_item := 0.0   ## a área de frente do item (o AABB)
## Prende o item escolhido (A cena) num BoneAttachment3D "Item". Apaga só o
## "Item" anterior: os "Peca*" da G02 e os nós de raça da G08 ficam.
func _segurar() -> void
## A runa: o vão em Tema.JANELA (× 1,5) e a linha no néon do dono a 1,6.
func _runa(pai: Node3D, tamanho: Vector3, pos: Vector3) -> void
```

`POSE_DO_ITEM` e o código de `"direita"`/`"esquerda"` saem. Em
`acender(k)` (G01/G08), acrescentar: cada material de `_mats_runa` com
`emission_energy_multiplier = 1.6 * k` (ou o parâmetro `energia` do
`Tema.neon`). Em `acender_acento()` (G08), a runa sobe a 2,6 e volta a 1,6 em
250 ms, `SAI`, junto do acento do corpo.

### Onde o item age hoje (sem o kit)

| onde | o quê |
| --- | --- |
| `TelaLobby._sentir_o_item(l)` | `Itens.escolhido[l] = jogadores[l].item_i`; `Itens.sentir(l)`; `Som.tocar("ui_peca", null, -12.0, 0.7492)`; `Som.no_controle(l, "ui_peca", 0.85)`; `Forja.vibrar(l, 0.3, 0.6, 80)`; `jogadores[l].acender_acento()` |
| `TelaLobby._forjou(l)` e o cavaleiro guardado em `abrir()` | `Itens.escolhido[l] = jogadores[l].item_i` |
| `main.gd`, `_todos_entram()` (`--sala`, `--partida`…) | `Itens.escolhido[l] = jogadores[l].item_i` de cada lugar ocupado |
| `SalaJogo.entrar()` | `Itens.novo_minigame()`; para cada jogador, `Itens.registrar(l, "leva")` |
| `SalaJogo.comecar()` | se `not usa_gatilho`: `Itens.sentir(l)` para cada jogador |
| `SalaJogo.errou(l) -> bool` (novo) | o erro de um lugar; `true` se o Escudo absorveu (a sala então não quebra o combo nem pune) |
| A Centelha | o botão errado e `_perdeu()` perguntam `errou(l)` antes de punir |

`SalaJogo` ganha `var usa_gatilho := false`; `galeria.gd`, `prova.gd` e
`bancada.gd` põem `usa_gatilho = true` no `_init()`.

```gdscript
## Um erro do lugar. Devolve true se o item absorveu (o Escudo): a sala não
## quebra o combo nem pune; o escudo quebra, o L2 afrouxa e o som diz.
func errou(l: int) -> bool:
	if treinando or not Itens.absorve_erro(l):
		return false
	var p := jogador(l)
	Som.tocar("escudo", p.global_position + Vector3(0, 1.2, 0), -4.0)
	Som.no_controle(l, "escudo", 0.8)
	Forja.vibrar(l, 1.0, 0.6, 250)
	if not usa_gatilho:
		Itens.sentir(l)   # o escudo quebrado solta o L2
	Itens.registrar(l, "quebrou")
	return true
```

Na Centelha, `centelha.gd:267`:

```gdscript
		if pedido >= 0 and not errou(l):
			e.combo = 0
			e.tremor = 0.6
			Som.tocar("falha", p.global_position + Vector3(0, 1.5, -2), -10.0)
```

e no começo de `_perdeu(l, p)`, depois de `var r := _runa_atual(l)`:

```gdscript
	if errou(l):
		_proxima(l)
		if e.atual >= e.fila.size():
			acabou[l] = true
		return
```

(a runa passa sem castigo e sem voltar à fila).

## Passos

Rodar `bash tests/prova_do_jogo.sh` depois dos passos 3, 5 e 6.

1. **O 13 primeiro:** trocar o bloco de código de
   [O item — G03](../13-arquitetura.md#o-item--g03) pela API do alvo e a
   frase «o item visual e o de mecânica são o mesmo índice» por «o índice é o
   mesmo; a mecânica lê `Itens.escolhido`, porque a sala pode tirar o item
   visual (`maos_livres`)». Tirar `ajustar_julgamento` (o Martelo mexe nos
   pontos, não no julgamento). A linha de `julgar_toque` passa a citar
   `Itens.janela_perfeito`, `Itens.pontos_do_acerto`, `Itens.absorve_erro` e
   `Itens.ganho_da_nota`.
2. **`godot/scripts/itens.gd` (novo):** a classe inteira;
   `"$GODOT" --headless --path godot --import --quit` e commitar o
   `itens.gd.uid`. O som `ui_peca` (os três passos de O som).
3. **`player.gd`:** `_segurar()`, `_runa()`, `_mats_runa`, as duas linhas em
   `acender` e `acender_acento`; sai `POSE_DO_ITEM`.
4. **`tela_lobby.gd` e `main.gd`:** as linhas da tabela. Ao sair do lobby,
   `Forja.gatilhos_off(l)` nos quatro já existe desde a G02: conferir.
5. **`sala_jogo.gd`:** `usa_gatilho`, `errou()`, as chamadas em `entrar()` e
   `comecar()`; `usa_gatilho = true` em `galeria.gd`, `prova.gd`, `bancada.gd`.
6. **`centelha.gd`:** os dois `errou(l)`.
7. **As provas** (Provas).

## Armadilhas

- **`.uid`** do `itens.gd`: importar e commitar.
- **`Itens.escolhido`, não `jogadores[l].item_i`:** a sala troca o item
  visual (`maos_livres`).
- **`_segurar()` apaga só o `"Item"`:** os `BoneAttachment3D` `"Peca*"` (G02)
  e os do grupo `"raca"` (G08) ficam.
- **O R2 é das provas:** o item só mexe no L2. A prova confere o R2 solto
  (`0x05`) no salão e depois de cada sala.
- **`Forja.silencio(l)`** no `terminar()` e no `sair()` da sala já solta os
  gatilhos: não repetir.
- **Salas às cegas:** não pôr `errou()` no Impacto, na Galeria, no Canto, nos
  Caminhos nem n'A Voz: a medida delas não pode mudar por item. O kit (H04)
  leva o item a elas.
- **Treino:** `errou()` não gasta o Escudo no treino (`treinando`).
- **O robô:** nenhum `Forja.robo` aqui.
- **`metallic` nunca acima de 0,2** e nenhuma esfera ou cilindro com mais de
  8 lados (a checagem da G08 roda nas salas e no salão).
- **A runa ≤ 12 % do item:** a prova mede (Provas). Um aro do escudo mais
  largo que 0,05 r passa do teto.
- **Os temperamentos e os casos que quebram:** `--robo=bom|medio|ruim`,
  partidas com 1 e 2 jogadores e o `simulador_cabo`. Com o `--robo=ruim`, o
  Escudo quebra de verdade na Centelha (a linha do tempo da prova visual tem
  `item` / `absorveu`); com 1 jogador, `Itens.escolhido` dos lugares vazios é
  `NENHUM`; o lugar que desconecta não perde o Escudo (o erro só conta com
  controle).

## Não fazer

- Não mexer em `julgar`, janelas ou relógio (H01, H02): o `Itens` só
  responde; quem pergunta é o kit (H04).
- Não mostrar o item no HUD (é a G04, que lê `Itens.escudo_inteiro` e
  `Itens.em_liga`).
- Não ler stat nem decidir a liga (G13).
- Não balancear pela noite: os números são os da tabela; a noite de seis
  horas (S) mede.
- Não usar a barra de luz nem o R2 para o item.

## Pronto quando

Cada um dos seis itens está no corpo no lugar da tabela, com a runa no néon
do dono, e tem o efeito e a liga da tabela na classe `Itens`; o Escudo
absorve o primeiro erro de cada sala na Centelha, firma o L2 enquanto
inteiro e o solta ao quebrar; o registro mostra o item de cada lugar ao
entrar numa sala e cada vez que o Escudo agiu.

E só fecha com `bash tests/prova_visual.sh` passando e a prancha olhada; a
aparência só se aprova na máquina do André, com placa de vídeo, sem
`--fixed-fps`.

## Provas

**Na sessão:** `bash tests/prova_do_jogo.sh`.

Em `godot/testes/prova_do_jogo.gd`, uma função nova chamada no `_ready()`
logo depois de `_prova_das_contas_da_partida()` (linha 66):

```gdscript
## As contas dos seis itens, sem sala (como as da partida), com e sem liga.
func _prova_das_contas_dos_itens() -> void:
	var antes: Array = Itens.escolhido.duplicate()
	var liga_antes: Array = Itens.em_liga.duplicate()
	Itens.em_liga = [false, false, false, false]
	Itens.escolhido = [Itens.MARTELO, Itens.ESCUDO, Itens.FOLE, Itens.LANTERNA]
	_esperar(Itens.pontos_do_acerto(0, 100, Itens.PERFEITO, true) == 200, "Martelo: o perfeito no tempo forte vale o dobro")
	_esperar(Itens.pontos_do_acerto(0, 100, Itens.PERFEITO, false) == 85, "Martelo: fora do tempo forte, 85%")
	_esperar(Itens.pontos_do_acerto(1, 100, Itens.PERFEITO, true) == 100, "sem Martelo, os pontos não mudam")
	Itens.novo_minigame()
	_esperar(Itens.absorve_erro(1) and not Itens.absorve_erro(1), "Escudo: absorve o primeiro erro, só ele")
	_esperar(not Itens.escudo_inteiro(1), "Escudo: quebrou")
	Itens.novo_minigame()
	_esperar(Itens.escudo_inteiro(1), "Escudo: inteiro de novo no minigame seguinte")
	_esperar(Itens.combo_inicial(1, 3) == 0, "Escudo: começa com o combo em 0")
	_esperar(not Itens.absorve_erro(0), "sem Escudo, nada se absorve")
	_esperar(Itens.acertos_para_voltar_o_combo(2, 10) == 5 and Itens.combo_maximo(2, 20) == 15, "Fole: volta na metade, teto de 3/4")
	_esperar(is_equal_approx(Itens.antecipacao_s(3, 120.0), 0.25), "Lanterna: meio tempo antes")
	_esperar(Itens.janela_perfeito(3, Vector2(-0.040, 0.060)).is_equal_approx(Vector2(-0.035, 0.055)), "Lanterna: o perfeito encolhe 10 ms")
	Itens.em_liga = [true, true, true, true]
	_esperar(Itens.pontos_do_acerto(0, 100, Itens.PERFEITO, false) == 100, "Martelo em liga: fora do tempo forte, 100%")
	_esperar(Itens.combo_inicial(1, 3) == 3, "Escudo em liga: começa com o bônus")
	_esperar(Itens.combo_maximo(2, 20) == 20, "Fole em liga: o combo máximo é o normal")
	_esperar(Itens.janela_perfeito(3, Vector2(-0.040, 0.060)).is_equal_approx(Vector2(-0.040, 0.060)), "Lanterna em liga: não encolhe")
	Itens.em_liga = [false, false, false, false]
	Itens.escolhido = [Itens.DIAPASAO, Itens.ANCORA, Itens.NENHUM, Itens.NENHUM]
	_esperar(is_equal_approx(Itens.ganho_da_nota(0, "coop"), 1.3) and is_equal_approx(Itens.ganho_da_nota(0, "tct"), 1.0), "Diapasão: nada no todos contra todos")
	_esperar(Itens.puxa_o_combo_da_equipe(0, "2v2") and not Itens.puxa_o_combo_da_equipe(0, "tct"), "Diapasão: puxa o combo só em equipe")
	_esperar(is_equal_approx(Itens.resiste_a_empurrao(1), 0.5) and is_equal_approx(Itens.velocidade(1, "corrida"), 0.9), "Âncora: resiste e anda mais devagar")
	Itens.em_liga = [true, true, false, false]
	_esperar(is_equal_approx(Itens.ganho_da_nota(0, "tct"), 1.3), "Diapasão em liga: a nota mais alta no todos contra todos")
	_esperar(is_equal_approx(Itens.velocidade(1, "corrida"), 1.0), "Âncora em liga: a velocidade normal")
	for c in [Itens.METAL, Itens.CERAMICA, Itens.LATAO]:
		var v := Pintura.para_oklab(c)
		_esperar(v.x >= 0.68 and v.x <= 0.80 and Vector2(v.y, v.z).length() <= 0.0801, "o tom %s na faixa do item" % c.to_html(false))
		for j in Tema.JOGADOR:
			_esperar(Pintura.delta_e(c, j) >= 0.08, "o tom %s longe do néon %s" % [c.to_html(false), j.to_html(false)])
	Itens.escolhido = antes
	Itens.em_liga = liga_antes
```

Dentro do percurso, logo depois de
`_esperar(jogo.estado == "salao", "com os quatro forjados, …")`:

```gdscript
	for l in 4:
		var p: ForjaPlayer = jogo.jogadores[l]
		_esperar(Itens.escolhido[l] == p.item_i and Itens.escolhido[l] >= 1,
			"P%d: a mecânica leva o item escolhido (%d)" % [l + 1, Itens.escolhido[l]])
		var esqueleto: Skeleton3D = p.modelo.find_child("Skeleton3D", true, false)
		var presa: BoneAttachment3D = esqueleto.find_child("Item", false, false)
		_esperar(presa != null, "P%d: o item no corpo" % (l + 1))
		var osso := {Itens.MARTELO: "arm-right", Itens.ANCORA: "arm-right", Itens.ESCUDO: "arm-left"}.get(p.item_i, "torso")
		_esperar(presa.bone_name == osso, "P%d: o item no osso %s" % [l + 1, osso])
		var alto := 0.0
		var corpo := 0.0
		for mi in presa.find_children("*", "MeshInstance3D", true, false):
			alto = maxf(alto, (mi.global_transform * mi.get_aabb()).size.y)
		for mi in p.modelo.find_children("body*", "MeshInstance3D", true, false):
			corpo = maxf(corpo, (mi.global_transform * mi.get_aabb()).size.y)
		var faixa := Vector2(0.06, 0.14) if osso == "torso" else Vector2(0.12, 0.60)
		_esperar(alto >= faixa.x * corpo and alto <= faixa.y * corpo,
			"P%d: o item no tamanho (%.2f do corpo)" % [l + 1, alto / maxf(corpo, 0.001)])
		_esperar(p._mats_runa.size() >= 1, "P%d: o item tem a runa" % (l + 1))
		_esperar(p._area_runa <= 0.12 * p._area_item, "P%d: a runa em até 12 %% do item (%.3f)" % [l + 1, p._area_runa / maxf(p._area_item, 0.0001)])
```

(Os itens da G02 dão 1..6 aos quatro lugares. Medido nos `.glb`: o
medalhão de 12 cm é 0,08 de um corpo de 1,5 m; o martelo girado 60°, 0,28;
o escudo, 0,45; a Âncora girada, 0,17.)

Na Centelha (linha 143, `_joga_a_sala("centelha", …)`): trocar por
`_comeca_a_sala` + checagens + `_termina_a_sala`:

```gdscript
	var centelha = await _comeca_a_sala("centelha")
	if centelha:
		Itens.escolhido[1] = Itens.ESCUDO
		Itens.escolhido[0] = Itens.MARTELO
		Itens.novo_minigame()
		var qt := 0
		while is_instance_valid(centelha) and centelha.treinando and qt < 1200:
			await _quadros(2)
			qt += 2
		Itens.sentir(1)
		await _quadros(2)
		_esperar(int(_perc(1).get("gatilho_esq", 0)) == 0x21, "Centelha: o L2 do P2 firme com o Escudo inteiro")
		var golpe := 0.0
		var metal := 0.0
		_esperar(centelha.errou(1), "Centelha: o Escudo do P2 absorve o primeiro erro")
		for q in 20:
			await _quadros(1)
			golpe = maxf(golpe, float(_perc(1).get("forte", 0.0)))
			metal = maxf(metal, float(Forja.som_virtual(1).get("falante", 0.0)))
		_esperar(golpe > 0.0, "Centelha: o golpe chegou à mão do P2 (%.2f)" % golpe)
		_esperar(metal > 0.0, "Centelha: o metal saiu no alto-falante do P2 (%.2f)" % metal)
		_esperar(int(_perc(1).get("gatilho_esq", 0)) == 0x05, "Centelha: o L2 do P2 afrouxa quando o escudo quebra")
		_esperar(not centelha.errou(1), "Centelha: o segundo erro do P2 é de verdade")
		_esperar(not centelha.errou(0), "Centelha: o P1, sem Escudo, erra de verdade")
		await _termina_a_sala(centelha, ["botoes", "analogicos", "gatilhos_analogicos"])
```

(A espera do treino é porque `errou()` não gasta o Escudo no treino.)

Na leitura da linha do tempo de `_prova_do_relatorio()` (437; o laço que
junta `calibracoes`, linha 447), declarar `var absorveu := 0` junto de
`calibracoes` e contar:

```gdscript
				if d is Dictionary and str(d.get("tipo", "")) == "item" and str(d.get("efeito", "")) == "absorveu":
					absorveu += 1
```

e `_esperar(absorveu >= 1, "o registro tem o Escudo agindo")`.

**A prova visual (F09):** `bash tests/prova_visual.sh` com as quatro
partidas; na prancha da construção e na das salas, o item de cada lugar no
corpo, sem atravessar.

## Para o André (local)

1. `bash tests/prova_visual.sh` sem `--fixed-fps`, com a placa de vídeo: os
   itens no corpo nas pranchas, a runa visível a 3 m e o medalhão legível no
   peito. Anotar no diário.
2. Na construção, com um DualSense: passar pelos seis itens. O L2 fica firme
   no Escudo, pesa pouco na Âncora, solta nos outros; cada troca soa no
   controle e dá o pulso de 80 ms.
3. Uma Centelha com o Escudo: errar uma vez (o metal no controle, o golpe, o
   L2 afrouxa, o combo fica), errar de novo (o combo zera).
4. `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh`.

## Ao terminar

No [quadro](README.md), G03 **feito** com o commit e o gasto. Commit
sugerido (sem trailer):

```
feat: os seis itens têm mecânica, liga, lugar no corpo e registro; o Escudo já age n'A Centelha
```


## O que foi feito (leva 1, o-cavaleiro)

- **A regra** (`scripts/itens.gd`, `class_name Itens`): a API da ficha inteira, lendo `Itens.escolhido` (não o item visual do boneco, que a
  sala pode tirar da mão). `pontos_do_acerto`, `absorve_erro`/`escudo_inteiro`/`combo_inicial`, `acertos_para_voltar_o_combo`/`combo_maximo`,
  `antecipacao_s`/`janela_perfeito`, `ganho_da_nota`/`puxa_o_combo_da_equipe`, `resiste_a_empurrao`/`velocidade`, `sentir`, `novo_minigame`,
  `registrar`. O «em liga» é um vetor `Itens.em_liga` que a G13 escreve ao forjar; até lá, tudo `false`.
- **O corpo** (`player.gd`): o Martelo e a Âncora na mão direita, o Escudo no braço esquerdo, os três amuletos (Fole, Lanterna, Diapasão)
  no medalhão do peito, cada um com o emblema dele em relevo; o martelo e o escudo com a malha do Kenney (`MALHA_DO_ITEM`), no osso e no
  tamanho da ficha. A runa do item é o traço no néon do dono (o fio do martelo, o aro do escudo, as unhas da âncora, o quadro do medalhão)
  e acende com o `acender`. `_segurar` novo.
- **A construção e o salão** (`tela_lobby.gd`, `main.gd`): trocar de item sente no L2 (`Itens.sentir`) e o escolhido vai para `Itens.escolhido`
  ao entrar no salão. Toda sala que usa o gatilho (`usa_gatilho`: Galeria e Prova) deixa o L2 por conta dela.
- **O Escudo n'A Centelha** (`sala_jogo.gd errou`, `centelha.gd`): o primeiro erro de cada minigame é absorvido (som `escudo`, metal no
  controle, golpe, L2 afrouxa, linhas `item` com `absorveu` e `quebrou` no registro). O combo fica; o segundo erro zera.
- **O survival-kit** entrou em `godot/assets/kenney/survival-kit/` (só o martelo do estudo; o escudo é o `shield-round.glb` que já estava
  em `assets/kenney/`): paliativo até a G10 trazer o kit.
- **As provas** (`prova_do_jogo.gd`): os seis itens no corpo, cada um no osso certo e no tamanho certo (maior lado do item contra o corpo de
  1,51 m); as contas de cada item (`_prova_das_contas_dos_itens`); o L2 firme/pesado/solto; a Centelha com Escudo; o registro.

### Desvios e decisões (a validar por ela)

- O teste de tamanho da ficha comparava o item com o AABB global do body-mesh (0,74 m, sem a cabeça, e girado): dava 0,85 a 1,32 para o mesmo
  martelo. Troquei por «maior lado do item no espaço dele contra 0,755 × `ForjaPlayer.ESCALA`», com as mesmas faixas.
- `Bancada` não entra em `usa_gatilho`: a ficha a listou, mas ela é `Sala`, não `SalaJogo`.
- Sem `Kit.caminho` (G10) e sem `Tema.neon` (G15): a runa usa `Kit.material`, e o caminho do modelo é uma constante. O `acender_acento()` e a
  textura «objeto» do colormap do item (G08) entraram depois, no commit que fecha a G08: o item trocado acende o acento, e o martelo e o escudo
  do Kenney levam o colormap na faixa dos objetos.
- O quadro do medalhão (0,030) corta o cabo do Diapasão (emblema em y -0,022): literal, como está na ficha.
- O aro do Escudo: caixas em octógono regular, vértice a 0,975 r.
- `Itens.ajustar_julgamento` saiu da arquitetura (a ficha H04, de outro conjunto, ainda o cita).
- Ao entrar no minigame grava-se a linha `item` com `leva` para cada um dos quatro, como a ficha manda; quem está de mãos livres grava
  «Mãos livres» (a primeira versão pulava esse lugar; a conferência devolveu à ficha).

### A conferência (leva 1, o-cavaleiro)

- O registro: o `leva` vale para os quatro lugares, mãos livres também (`sala_jogo.gd entrar`).
- A runa medida no espaço do item: `_area_runa` somava na escala da malha do Kenney (2,3 no martelo, 0,9 no escudo) e `_area_item` na do
  item, e a régua dos 12 % media outra coisa (o martelo saía 5,3 vezes menor). Agora as duas contas usam a mesma escala.
- O Escudo quebrado na última sala voltava quebrado à construção, com o L2 solto: `tela_lobby.gd abrir` chama `Itens.novo_minigame()`
  (decisão pequena, a validar por ela: na construção o Escudo está sempre inteiro).
- Provas novas, cada uma conferida com a mordida (o defeito de volta reprova a régua): a Centelha pergunta `errou()` na runa perdida (antes
  a prova só chamava `errou()` direto, sem passar pela sala); o L2 de cada um na volta à construção depois de um Escudo quebrado; o registro
  com o `leva` dos quatro, com o P4 de mãos livres na Viga. A régua «o aro a 0,25» lê o valor do material, não só o código do shader.

### O que fica para a mão

Está em «Para o André (local)» acima: a prova visual sem `--fixed-fps` com placa de vídeo, o L2 nos seis itens com o DualSense de verdade,
a Centelha com Escudo no controle, `scripts/gauntlet.sh` e `prova_de_poucos.sh`.
