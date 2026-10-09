# G08 — A arte: a peça que se distingue, as raças e a coerência

**Sprint:** G · **Tamanho:** G · **Depende de:** F00, G01, G02, G14, F09 ·
**A parte B depende também de:** G10 (o `cube-pets` importado) e G13 (a
montagem por peças)

## Por quê

Ela, ao aprovar a direção (09/10/2026): «as roupas superiores e inferiores
precisam se diferenciar. tudo tá num neon de uma única cor que nada diferencia
na hora da montagem» e «só temos assets de personagens humanos». A causa está
em `godot/scripts/player.gd`, `_vestir()`: o corpo inteiro é multiplicado pela
cor do lugar. Esta ficha tira a cor do corpo, dá a cada parte a sua faixa de
valor e um acento de néon com área contada, põe quatro raças na montagem e
fecha a coerência fosca e facetada do resto do jogo.

## Ler antes

- [A peça se distingue](../arte/04-o-cavaleiro.md#a-peça-se-distingue) (a regra, a tabela dos acentos, o teste de 64 px)
- [A cor da peça e o néon do dono](../arte/02-cor-e-letra.md#o-cavaleiro-a-cor-da-peça-e-o-néon-do-dono) (as faixas de L e as peles)
- [As raças](../arte/04-o-cavaleiro.md#as-raças) (só para a parte B)

## Arquivos que mudam

| arquivo | parte | também muda em |
| --- | --- | --- |
| `scripts/conferir_bonecos.py` (novo) | A | G10 roda ele |
| `godot/shaders/cavaleiro.gdshader` e `.uid` (novos) | A | — |
| `godot/shaders/contorno.gdshader`, `godot/shaders/neon.gdshader` e `.uid` (novos, se a G15 ainda não criou) | A | **G15** |
| `godot/scripts/mundo/pintura.gd` e `.uid` (novo, `class_name Pintura`) | A | — |
| `godot/scripts/player.gd` | A e B | **G01, G02, G03, G13** |
| `godot/scripts/main.gd` (`_mostrar`) | A | **G01, G02, G04, G05, G06, G07** |
| `godot/scripts/som.gd` (`pio`) | A | **G01, G03, G04, G06, G07** |
| `godot/scripts/mundo/kit.gd` | A | **G03, G10** |
| `godot/scripts/salas/voz.gd`, `canto.gd`, `caminhos.gd`, `centelha.gd`, `galeria.gd`, `impacto.gd`, `molde.gd`, `viga.gd`, `prova.gd`, `godot/scripts/mundo/efeitos.gd`, `godot/scripts/mundo/salao.gd` | A | **G05** (`salao.gd`), **G06** (`salao.gd`), **G15** |
| `godot/scripts/mundo/racas.gd` e `.uid` (novo, `class_name Racas`) | B | — |
| `godot/scripts/ui/tela_lobby.gd` (a tela de montagem que a G13 pôs no lugar do seletor do lobby; a linha da cabeça) | B | **G02**, **G13** |
| `godot/scripts/traducoes.gd` | B | **todas as G com texto** |
| `godot/testes/prova_do_jogo.gd`, `tests/prova_do_jogo.sh` | A e B | **todas as G** |

## Como se joga

Não se aplica à parte A: ela muda a aparência, não a regra.

Parte B, na montagem da G13: na linha da cabeça, **R1** alterna Humana, Orc,
Autômato, Golem e Raposa, em laço, uma por toque. ◀ ▶ continuam escolhendo
entre os 12 perfis de cabeça (stats e pio de `pecas.csv`), em qualquer raça.
A raça não muda stat, colisão (a cápsula de raio 0,42 e altura 1,5 de
`player.gd`), velocidade nem janela de julgamento. O pré-montado sorteia a raça
pela semente do lugar: humana se `semente % 2 == 0`, senão a raça
`1 + (semente / 2) % 4`.

## A cena

- **Câmera:** nenhuma muda aqui. A montagem segue o plano da G13 (50 mm,
  frontal); o resto, a G05.
- **Luz:** nenhuma muda. A luz da casa (tocha, lilás, névoa) fica.
- **O corpo do cavaleiro, por parte** (L e croma em OKLab; o recolorir é o
  `graduar` do estudo, `godot/estudos/direcao/fita.gd:175-197`, com o teto de
  croma de cada papel):

| parte | papel em `Pintura.GRADE` | `l0` | `l1` | `sat` | croma máximo | rugosidade | metallic |
| --- | --- | --- | --- | --- | --- | --- | --- |
| cabeça | `personagem` | 0,06 | 0,86 | 0,80 | 0,098 | 0,90 | 0 |
| tronco superior | `tecido` | 0,46 | 0,12 | 0,55 | 0,098 | 0,85 | 0 |
| tronco inferior | `couro` | 0,22 | 0,14 | 0,40 | 0,07 | 0,70 | 0 |
| item | `objeto` | 0,22 | 0,56 | 0,40 | 0,03 | 0,55 | 0,2 |

  O teto é 0,098 e a folga até um `Tema.JOGADOR` é 0,085, não 0,10 e 0,08:
  o arredondamento do sRGB de 8 bits passava do limite (04, «O que mudou no
  estudo, em 09/10»). Depois do teto, o laço do estudo: enquanto a cor está a
  menos de 0,085 de algum `JOGADOR`, o croma desce 10 %, até 20 passos. A
  prova continua conferindo croma de até 0,10 e ΔE de 0,08 ou mais.

  A L de cada parte não depende do croma: `l = l0 + L × l1`. Por isso o
  superior cai sempre em [0,46; 0,58], o inferior em [0,22; 0,36] e a
  diferença é de 0,10 ou mais, em qualquer colormap. A exceção é a pele.
- **A pele não se clareia** (04, «O que a medida deu, em 09/10»). No
  colormap do Mini Characters, as três rampas de pele ficam em
  `PELE_UV = Rect2(330/512, 380/512, 182/512, 132/512)` (`fita.gd:123`): a mão,
  a perna de fora, o rosto. Esses pixels recebem o papel `personagem` também
  no superior e no inferior (o `papel_pele` do `recolorir`, `fita.gd:202-218`).
  As medianas do superior e do inferior se medem só no pano (a UV fora de
  `PELE_UV`). Medido no estudo em 09/10, nos 12 do Mini Characters: o
  superior de 0,501 a 0,562, o inferior de 0,269 a 0,332, o pior par a 0,169.
  O male-f (a bermuda) passa: superior 0,532, inferior 0,298. Nos bonecos do
  Mini Dungeon de hoje não há `PELE_UV`: o colormap inteiro vai pelo papel
  da parte.

  Este é o caminho de «medir só no pano» que o 04 propõe para o male-f. O
  diretor de arte ainda não decidiu (PRODUCAO, item 17). Se ele tirar o male-f
  do inferior, a prova não muda; se decidir o critério do rosto (|ΔL| de 0,10
  ou mais entre o rosto e o superior, com a gola acesa onde não chega), ele
  entra na prova como uma linha a mais. Até lá, a cabeça não tem faixa na
  prova.

- **O néon do dono** (sempre `Tema.JOGADOR[lugar]`, nunca a cor da peça):

| elemento | onde | energia | área |
| --- | --- | --- | --- |
| o contorno | casco invertido, largura 0,012 | 1,6 na montagem (`_mostrar("lobby")`), 2,4 no resto | não conta |
| o friso | faixa no y mais baixo do osso `torso` e na gola, no menor entre o y mais alto do `torso` e y 0,343 (`PESCOCO`, o pescoço) | 1,6; 2,6 no encaixe, volta em 250 ms (`SAI`: `TRANS_CUBIC`, `EASE_OUT`) | até 8 % da frente do superior |
| a costura | linha no x de maior módulo de `leg-left` e `leg-right` | 1,6; 2,6 no encaixe | até 5 % da frente do inferior |
| o aro (fresnel) | as faces de lado de todo o corpo | 0,25, abaixo do limiar do glow (0,82) | não conta |
| o anel de 8 lados no chão | toro de 8 lados, raio 0,62 (unidade do jogo, depois da `ESCALA` 2,0 vale 1,24 m) | 1,5 | — |
| as lâmpadas à frente do anel | caixas de 0,09 × 0,02 × 0,14, nas posições acesas de `Forja.LEDS_DO_LUGAR[lugar]` | 1,8 | — |
| a cabeça humana | nenhum acento | — | 0 % |

  A soma do friso e da costura fica em até 8 % da frente do corpo.
- **As raças (parte B)**, as do estudo `godot/estudos/direcao/cavaleiro/racas.gd`,
  que a prancha aprovou (04, «O que mudou no estudo, em 09/10»). Medidas nas
  unidades do personagem do Mini Characters (o `male-a` tem 0,67 de altura; a
  cabeça dele vai de y 0,34 a 0,67). A cabeça por código nasce no osso `head`,
  em y `PESCOCO` = 0,343, com a escala `ESCALA_CABECA` = 1,30 sobre as medidas
  abaixo (o autômato fica com 0,39 de largura, perto dos 0,45 da cabeça
  humana).

| raça | a cabeça | as mãos | a cauda | a proporção | a pele | o acento | a marca do perfil |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Orc | a `head-mesh` de `Kit.caminho("mini-dungeon-personagens/character-orc")` (G10), com o skin dela; o colormap do orc em `personagem` e depois `Pintura.trocar_matiz(img, Tema.PELE_ORC, -0.05)`: os pixels com o a do OKLab abaixo de −0,05 (o verde) ganham o a e o b de `PELE_ORC`, e a L de cada um fica | na pele | — | — | `Tema.PELE_ORC` `#89aa77` | nenhum | o tufo: caixa de 0,06 com o centro em (0; 0,78; 0), o alto da cabeça do orc |
| Autômato | caixa chanfrada (três caixas cruzadas, chanfro 0,025) de 0,30 × 0,28 × 0,28; dois parafusos nos lados (cilindro de 6 lados, raio 0,035, 0,02 de altura); o visor: caixa `Tema.JANELA` de 0,24 × 0,06 × 0,02 a 0,10 do topo, com o acento de 0,22 × 0,02 × 0,01 dentro; a boca: três frestas `JANELA` de 0,018 × 0,04 × 0,01, a 0,04 uma da outra, em y 0,07; a antena: haste de 0,012 × 0,08 × 0,012 em x 0,06 | a pinça: uma placa de 0,05 × 0,02 × 0,05 e dois dedos de 0,02 × 0,05 × 0,02 girados ±0,25 rad, no punho | — | — | `Tema.PELE_LATAO` `#bda978`, metallic 0,2; rugosidade 0,9 na cabeça e 0,55 na pinça | o visor, 1,6 | a bola da antena: esfera de raio 0,025 (6 × 3) no alto da haste |
| Golem | um tronco de pirâmide de faces chapadas, sem pescoço (a base em y −0,03): a base de 0,36 × 0,30, o topo de 0,26 × 0,24, 0,27 de altura; a sobrancelha chanfrada de 0,30 × 0,045 × 0,07 a 0,165 da base; os olhos `Tema.TINTA` de 0,06 × 0,026 em x ±0,075, a 0,13 da base; a boca `TINTA` de 0,14 × 0,014, a 0,06 da base; duas pedras de 0,08 × 0,075 × 0,12 nas bochechas, em x ±0,165; a laje torta de 0,15 × 0,05 × 0,14 no alto, em x 0,035; a rachadura: três traços em zigue-zague em x −0,05 ± 0,01, do topo até a sobrancelha, cada um um vão `JANELA` de 0,018 de altura com o acento de 0,007 dentro | o punho de pedra: cubo chanfrado de 0,075 | — | `torso` × (1,15; 1; 1,15), `head` × (0,87; 1; 0,87) | `Tema.PELE_ESCORIA` `#a3958e`, rugosidade 0,9 | a rachadura, 1,6 | dois tufos de líquen desencontrados: 0,07 × 0,035 × 0,06 em (0,07; topo + 0,05; −0,04) e 0,05 × 0,03 × 0,05 em (−0,08; topo + 0,01; 0,03) |
| Raposa | caixa chanfrada (chanfro 0,02) de 0,28 × 0,24 × 0,26; a máscara: placa `Tema.ETIQUETA_SOMBRA` de 0,26 × 0,10 × 0,01 na metade de baixo da cara (y 0,05); o focinho em `ETIQUETA_SOMBRA` de 0,11 × 0,07 × 0,08 em y 0,055; o nariz `TINTA` de 0,045 × 0,028 × 0,02 na frente do focinho; os olhos `TINTA` de 0,03 em x ±0,065, y 0,14; as orelhas: prismas de 0,08 × 0,10 × 0,04 em x ±0,085, girados ∓0,15 rad | na pele | a malha `tail` de `Kit.caminho("cube-pets/animal-fox")` × 0,33 (0,30 de comprimento), no osso `root` em (0; 0,20; −0,10); balança ±8° por batida (o seno do B2) | — | `Tema.PELE_RAPOSA` `#cd8d6d` | nenhum | a ponta das orelhas: prismas de 0,027 × 0,034 × 0,042 |

  As posições e os giros que a tabela não dá são os de `racas.gd`
  (`automato` 249-287, `golem` 289-331, `raposa` 334-354, `_mao` 357-377,
  `_cauda` 380-397), copiados sem mudar. A marca do perfil é a cor de maior
  área da cabeça humana do perfil fora de `PELE_UV` (`cabelo`, `racas.gd:110-135`).
- **O guardião d'A Voz** sai da esfera de bronze para pedra em blocos:
  pedra `Tema.GRAFITE`, escuro `Tema.CASCO`, a boca `Tema.JANELA`, os dentes
  `Tema.ETIQUETA`; metallic 0, rugosidade 0,95. O olho fica o `mat_olho` de
  hoje, sem mudar a cor: o token dele e o dono são da G15.
- **A coerência:** nenhuma curva com mais de 8 lados; nada com `metallic`
  acima de 0,2; o metal com rugosidade de 0,45 ou mais.

## O som

- **O pio do boneco** (`Som.pio`, que a G01 criou) passa a ler o intervalo de
  `ForjaPlayer.BONECOS[boneco].intervalo` e toca `pio_p{lugar+1}_{intervalo}`
  pelo encanamento do id da G01 (`Som.tocar` e `Som.no_controle`). Humano
  `segunda`, Orc `quinta_baixo` (os mesmos da G01).
- **A raça (parte B):** R1 toca `ui_peca` a +7 semitons (tom `pow(2, 7/12.0)`
  = 1,498) no alto-falante do dono e na TV a −12 dB, pelo
  `Som.tocar("ui_peca", null, -12.0, 1.498)` e `Som.no_controle(lugar, "ui_peca", 0.85)`
  (o alto-falante toca o PCM sem tom; copiar o `ui_peca.wav` do estudo se
  a G03 ou a G13 ainda não copiou). A raça não tem pio próprio: o
  pio é o do perfil da cabeça.
- Nenhum id novo no `mapa.csv`.

## O controle

| evento | para quem | vibração | gatilho | luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| R1 troca a raça (parte B) | o dono | o pulso de 40 ms da troca de peça: a mesma chamada que a G13 usa (a 03 pede 150 Hz nos atuadores); se a G13 não deixou uma, `Forja.vibrar(l, 0.0, 0.45, 40)` | não muda | não muda | `ui_peca` +7 |
| o resto | — | não muda | não muda | não muda | não muda |

Sem o controle na mão: o controle simulado mostra o que recebeu
(`Forja.ctl.percepcao(pad)` tem `forte` e `fraco`; `Forja.som_virtual(l)` tem
`falante`, `esq` e `dir`), e a prova confere que o R1 do robô chegou ao
motor ou aos atuadores e ao alto-falante do lugar dele, e de nenhum outro
(Provas).

## O cavaleiro

- Os stats não mudam aqui. A raça é aparência
  ([sistemas](../sistemas/README.md#o-que-não-tem-stat)); o perfil da cabeça
  continua dando os stats e o pio.
- A peça escolhida aparece pela faixa de valor: em cinza, o tronco médio
  (0,46 a 0,58) e as pernas escuras (0,22 a 0,36), medidos no pano. A cabeça
  fica na pele como veio: os 12 rostos medem de 0,52 a 0,72 (A cena, a pele).
- O item (G03) usa o papel `objeto` e a runa dele é o acento do item; esta
  ficha só entrega `Pintura` e o acento, a G03 aplica.

## As reações

Não se aplica: a ficha não dispara adesivo nem carimbo.

## A diversão

**O momento:** na montagem, de 3 m da TV, cada um aponta o seu cavaleiro pelo
corpo e não pela cor, e alguém ri do golem de calça social. **Como se
confere:**

1. A prova do jogo mede as medianas de L do pano de cada parte nos quatro
   cavaleiros da montagem: superior em [0,46; 0,58], inferior em
   [0,22; 0,36], e a diferença entre os dois de 0,10 ou mais (no estudo, o
   pior par dá 0,169).
2. A prancha `prancha-montagem-cinza.png` da prova visual (o quadro da
   montagem convertido para cinza e reduzido a 64 px de altura por cavaleiro):
   o jogador do time aponta, sem cor, qual parte é cabeça, tronco e pernas nos
   quatro, e anota no diário.
3. Parte B: na noite de teste, quem joga a montagem pela primeira vez troca a
   raça pelo menos uma vez em 90 s (a prova do robô mede que o R1 funciona; a
   noite mede o gosto).

## O estado de hoje

- `godot/scripts/player.gd`:
  - linha 13 `MODELOS := ["character-human", "character-orc"]`; linha 14
    `NOME_DO_MODELO := ["humano", "orc"]`; a G01 acrescentou
    `INTERVALO_DO_MODELO := ["segunda", "quinta_baixo"]`;
  - linhas 75-89, o aro: `TorusMesh` de `rings` 32, `StandardMaterial3D`
    sem luz com emissão 1,4 na cor do lugar;
  - linha 107 `visual(m, item)` carrega `res://assets/kenney/%s.glb` (a G10
    passa para `Kit.caminho`), chama `_vestir(modelo)`;
  - linhas 156-166, `_vestir()`: cada `body*` recebe uma cópia do material
    com `albedo_color = cor.lerp(Color.WHITE, 0.25)`. **É a causa.**
- Os `.glb` do Mini Dungeon: sete ossos `root`, `leg-left`, `leg-right`,
  `torso`, `arm-left`, `arm-right`, `head` (`root` → pernas e `torso`;
  `torso` → braços e `head`); 32 animações com trilhas de posição, rotação e
  escala em todos os ossos; malhas `body-mesh` e `head-mesh`; 465 e 374
  triângulos; altura 0,755 com a origem nos pés; `metallicFactor` 0; a
  textura `Textures/colormap.png` ao lado do `.glb`.
- O estudo já tem o shader do cavaleiro (`godot/estudos/direcao/shaders/cavaleiro.gdshader`,
  com `tingir` e `brilho_proprio`), o contorno e o néon (`contorno.gdshader`,
  `neon.gdshader`), a normal suave no TANGENT (`Mundo.suavizar`,
  `godot/estudos/direcao/mundo.gd:46-73`), o anel com lâmpadas (`Mundo.anel`,
  `mundo.gd:159-189`) e o `graduar` em OKLab (`fita.gd:107-197`). O jogo não
  tem `godot/shaders/`.
- `godot/scripts/salas/voz.gd:114-168`, `_montar_guardiao()`: rosto
  `Kit.esfera` escalado (1,55; 1,95; 0,55) em bronze `metallic` 0,6; olhos
  esféricos; devolve `{"pivo", "mat_olho", "palpebras", "boca", "dentes",
  "brilho", "fundo"}`. A animação (`voz.gd:500-515`) usa
  `mat_olho.emission_energy_multiplier`, `palpebras` (`scale.y` e
  `position.y = 0.28 + 0.2 * olhos`), `boca.scale` e `pivo.position`.
- Curvas lisas: `TorusMesh` em `player.gd:75`, `efeitos.gd:86`,
  `centelha.gd:128`, `molde.gd:166`, `canto.gd:139`, `:188`, `:225`,
  `caminhos.gd:148`, `impacto.gd:115`, `voz.gd:177`, `viga.gd:220`,
  `galeria.gd:123`; `SphereMesh` em `kit.gd:89` (20 × 10), `centelha.gd:140`,
  `salao.gd:223`; `kit.gd:78` cilindro de 20 lados; CSG em `kit.gd:158`
  (16), `salao.gd:214`, `261` (32), `268` (48), `297` (16), `368` (32),
  `378` (40).
- `metallic` acima de 0,2: `molde.gd:424` (0,7), `canto.gd:129` (0,75),
  `viga.gd:71` (0,8), `caminhos.gd:117` (0,8), `voz.gd:120` (0,6),
  `prova.gd:125` (0,8).
- `pecas.csv` tem 36 peças com os nomes da cor nativa (Blusa roxa, Camisa
  verde, Short azul). A raça não entra no CSV.
- O `character-orc.glb` corta limpo (0 triângulo misto): cabeça 176,
  superior 144, inferior 54. O Graveyard Kit tem bonecos **rígidos** (um nó
  com malha por osso, mesmas 32 animações, sem skin); a G10 os importa como
  monstros e roda o conferidor neles.

## O alvo

### Parte A — a peça se distingue e a coerência

**A1. O conferidor de bonecos** (`scripts/conferir_bonecos.py`, Python 3 sem
dependência). Aceita os dois tipos: com skin (os sete ossos nas juntas) e
rígido (um nó com o nome de cada osso, cada um com malha ou filho com malha, e
`head` com malha).

```python
#!/usr/bin/env python3
"""Confere um boneco .glb antes de ele entrar no Forja (docs/jogo/arte/04).

    python3 scripts/conferir_bonecos.py                 os character-*.glb de godot/assets/kenney
    python3 scripts/conferir_bonecos.py <arquivo|pasta>...
    python3 scripts/conferir_bonecos.py --teste         a prova da mordida

Uma linha por arquivo: PASSOU ou FALHOU e o porquê. Sai com 1 se algum falhou.
"""
import json
import pathlib
import struct
import sys

OSSOS = ["root", "leg-left", "leg-right", "torso", "arm-left", "arm-right", "head"]
PAI = {"leg-left": "root", "leg-right": "root", "torso": "root",
       "arm-left": "torso", "arm-right": "torso", "head": "torso"}
ANIMACOES = ["idle", "walk", "sprint", "jump", "fall", "die", "emote-yes", "emote-no",
             "attack-melee-right", "holding-right", "static", "interact-right"]
TRIANGULOS = 1500
ALTURA = 0.755
RAIZ = pathlib.Path(__file__).resolve().parent.parent


def ler(caminho):
    b = pathlib.Path(caminho).read_bytes()
    if b[:4] != b"glTF":
        raise ValueError("não é glTF binário")
    n = struct.unpack("<I", b[12:16])[0]
    return json.loads(b[20:20 + n])


def conferir(j, pasta):
    falhas = []
    nos = j.get("nodes", [])
    nome = lambda i: nos[i].get("name", "")
    pai = {}
    for n in nos:
        for c in n.get("children", []):
            pai[nome(c)] = n.get("name", "")
    if j.get("skins"):
        tipo = "skin"
        for s in j["skins"]:
            juntas = [nome(i) for i in s["joints"]]
            if sorted(juntas) != sorted(OSSOS):
                falhas.append(f"ossos {juntas}")
    else:
        tipo = "rígido"
        por_nome = {n.get("name", ""): n for n in nos}
        faltam = [o for o in OSSOS if o not in por_nome]
        if faltam:
            falhas.append(f"ossos {faltam} faltam")
        tem_malha = lambda n: "mesh" in n or any("mesh" in nos[c] for c in n.get("children", []))
        if "head" in por_nome and not tem_malha(por_nome["head"]):
            falhas.append("head sem malha")
    for osso, p in PAI.items():
        if pai.get(osso) != p:
            falhas.append(f"{osso} pendurado em {pai.get(osso)!r}, não em {p!r}")
    anims = {a.get("name", "") for a in j.get("animations", [])}
    faltam = [a for a in ANIMACOES if a not in anims]
    if faltam:
        falhas.append(f"faltam as animações {faltam}")
    tri, alto, baixo = 0, -1e9, 1e9
    for m in j.get("meshes", []):
        for p in m["primitives"]:
            pos = j["accessors"][p["attributes"]["POSITION"]]
            alto, baixo = max(alto, pos["max"][1]), min(baixo, pos["min"][1])
            conta = j["accessors"][p["indices"]]["count"] if "indices" in p else pos["count"]
            tri += conta // 3
    if tri > TRIANGULOS:
        falhas.append(f"{tri} triângulos (máximo {TRIANGULOS})")
    if tipo == "skin" and abs(alto - ALTURA) > ALTURA * 0.15:
        falhas.append(f"altura {alto:.3f} (a do kit é {ALTURA})")
    if tipo == "skin" and abs(baixo) > 0.03:
        falhas.append(f"a origem não está nos pés (o mais baixo em {baixo:.3f})")
    for mat in j.get("materials", []):
        metal = mat.get("pbrMetallicRoughness", {}).get("metallicFactor", 1.0)
        if metal > 0.2:
            falhas.append(f"material {mat.get('name')!r} com metallic {metal} (máximo 0,2)")
    for img in j.get("images", []):
        if "uri" in img and not (pasta / img["uri"]).exists():
            falhas.append(f"a textura {img['uri']} não está ao lado do .glb")
    return falhas, tri, len(anims), tipo


def arquivos(args):
    alvos = [pathlib.Path(a) for a in args] or [RAIZ / "godot/assets/kenney"]
    for a in alvos:
        yield from (sorted(a.rglob("character-*.glb")) if a.is_dir() else [a])


def teste():
    f = next(arquivos([]))
    j = ler(f)
    bom = conferir(j, f.parent)[0]
    for n in j["nodes"]:
        if n.get("name") == "head":
            n["name"] = "cabeca"
    j["animations"] = [a for a in j["animations"] if a.get("name") != "idle"]
    ruim = conferir(j, f.parent)[0]
    ok = not bom and any("ossos" in x for x in ruim) and any("idle" in x for x in ruim)
    print("PASSOU  a mordida: o boneco passa; sem 'head' e sem 'idle', falha" if ok else f"FALHOU  a mordida: {bom} / {ruim}")
    return 0 if ok else 1


def main():
    if sys.argv[1:] == ["--teste"]:
        return teste()
    rc = 0
    for f in arquivos(sys.argv[1:]):
        falhas, tri, n, tipo = conferir(ler(f), f.parent)
        rel = f.resolve().relative_to(RAIZ) if f.resolve().is_relative_to(RAIZ) else f.name
        if falhas:
            rc = 1
            print(f"FALHOU  {rel}: " + "; ".join(falhas))
        else:
            print(f"PASSOU  {rel} ({tipo}, {tri} triângulos, {n} animações)")
    return rc


if __name__ == "__main__":
    sys.exit(main())
```

O rígido não tem altura nem origem conferidas: as peças dele ficam no espaço
do osso, e a G10 só os usa como monstros.

**A2. Os shaders do jogo** em `godot/shaders/`:

- `contorno.gdshader` e `neon.gdshader`: cópias exatas dos do estudo. Se a
  G15 já os criou, usar os dela.
- `cavaleiro.gdshader` (novo, sem `tingir` nem `brilho_proprio`):

```glsl
// O cavaleiro (arte/04, a peça se distingue): a cor é a da peça, já
// recolorida pela faixa da parte; o néon do dono é só acento (o friso, a
// costura) e o aro de luz fraco. COLOR.r: 0 superior, 1 inferior. UV2: a
// posição de repouso (x, y) do vértice, para a faixa do acento não andar.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D textura_cima : source_color, filter_nearest;
uniform sampler2D textura_baixo : source_color, filter_nearest;
uniform vec4 dono : source_color = vec4(1.0);
uniform float aro = 0.25;
uniform float aro_pot = 2.5;
uniform float rugoso_cima = 0.85;
uniform float rugoso_baixo = 0.70;
uniform float metal = 0.0;            // 0,2 no autômato e no item; o acabamento (G02, G06) escreve
uniform vec4 pele : source_color = vec4(1.0);
uniform float pele_ativa = 0.0;       // 1 numa raça: a pele do colormap vira a pele dela
uniform vec4 pele_uv = vec4(0.6445, 0.7422, 1.0, 1.0);  // Pintura.PELE_UV: x0, y0, x1, y1
uniform float acento = 1.6;          // 2,6 no encaixe
uniform float friso_y0 = 0.0;        // o y mais baixo do torso, em repouso
uniform float friso_y1 = 0.0;        // a gola: min(y mais alto do torso, 0.343)
uniform float friso_alto = 0.010;
uniform float costura_x = 0.0;       // o |x| mais de fora da perna
uniform float costura_larg = 0.008;
uniform bool tem_acento = true;
uniform vec4 apagado : source_color = vec4(0.227, 0.200, 0.275, 1.0); // Tema.GRAFITE #3a3346 (o _vestir põe o token)
uniform float acesa = 1.0;            // 0: a armadura apagada da introdução (G01)

varying float baixo;
varying vec2 repouso;

void vertex() {
	baixo = COLOR.r;
	repouso = UV2;
}

void fragment() {
	vec3 c = baixo > 0.5 ? texture(textura_baixo, UV).rgb : texture(textura_cima, UV).rgb;
	if (pele_ativa > 0.5 && UV.x >= pele_uv.x && UV.y >= pele_uv.y) {
		// a rampa de pele desce do alto da coluna: o degradê é a razão
		vec2 alto = vec2(UV.x, 0.7754);
		vec3 topo = baixo > 0.5 ? texture(textura_baixo, alto).rgb : texture(textura_cima, alto).rgb;
		float lum = dot(c, vec3(0.299, 0.587, 0.114));
		float k = clamp(lum / max(dot(topo, vec3(0.299, 0.587, 0.114)), 0.05), 0.6, 1.0);
		c = pele.rgb * k;
	}
	ALBEDO = c;
	ROUGHNESS = baixo > 0.5 ? rugoso_baixo : rugoso_cima;
	METALLIC = metal;
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), aro_pot);
	EMISSION = dono.rgb * f * aro;
	bool friso = baixo < 0.5 && repouso.y >= friso_y0 - 0.0001
		&& (repouso.y <= friso_y0 + friso_alto || repouso.y >= friso_y1 - friso_alto);
	bool costura = baixo > 0.5 && abs(repouso.x) >= costura_x - costura_larg;
	if (tem_acento && (friso || costura)) {
		vec3 n = dono.rgb * acento;
		float m = max(n.r, max(n.g, n.b));
		ALBEDO = m > 1.0 ? n / m : n;
		EMISSION = dono.rgb * acento;
	}
	// apagada (acesa 0): o corpo em GRAFITE, sem acento e sem aro
	ALBEDO = mix(apagado.rgb, ALBEDO, acesa);
	EMISSION *= acesa;
}
```

  A cabeça usa o mesmo shader com `textura_cima` recolorida pelo papel
  `personagem`, `rugoso_cima` 0,90 e `tem_acento` false (a cabeça humana não
  tem acento). O `friso` do superior só vale para vértices do `torso`: os
  braços recebem `UV2.y` = −1 (abaixo de qualquer `friso_y0`).

  A pele (`pele`, `pele_ativa`, `pele_uv`) é o bloco do estudo
  (`godot/estudos/direcao/shaders/cavaleiro.gdshader:28-32`): a parte B liga
  numa raça. A costura (`abs(repouso.x) >= costura_x − costura_larg`) acende
  a faixa de 0,008 da frente de cada perna, junto ao lado de fora (04, «O que
  mudou no estudo»), e a face de fora da perna inteira; a face de fora não
  conta na área de frente.

**A3. `Pintura`** (`godot/scripts/mundo/pintura.gd`, `class_name Pintura`,
novo). Copia do estudo `godot/estudos/direcao/fita.gd` `DE_JOGADOR` (0,085),
`PELE_UV` (123), `para_oklab`, `de_oklab`, `_lin`, `_srgb`, `graduar`
(175-197, com o laço do ΔE), `recolorir(img, papel, papel_pele := "")`
(202-218) e `trocar_matiz` (223-236), trocando `JOGADOR` por `Tema.JOGADOR`.
A `GRADE` é a da tabela de A cena: `teto` = o croma máximo de cada papel,
`tinge` 0 nos quatro (o jogo não puxa para o violeta). Mais:

```gdscript
## A textura do colormap `caminho` recolorida pelo papel, uma vez por trio.
## `papel_pele`: o papel dos pixels de PELE_UV ("" fora do Mini Characters).
static func textura(caminho: String, papel: String, papel_pele := "") -> ImageTexture
## Distância OKLab entre duas cores.
static func delta_e(a: Color, b: Color) -> float
## Prepara a malha de um boneco com skin: grava COLOR.r (0 superior, 1
## inferior), UV2 (a posição de repouso x, y; y = -1 nos braços) e a normal
## suave no TANGENT (o casco do contorno). Pelo osso de maior peso de cada
## vértice: `leg-left`, `leg-right` e `root` são inferior; `torso`,
## `arm-left`, `arm-right` são superior. Devolve as medidas para o shader:
## {"friso_y0", "friso_y1", "friso_alto", "costura_x", "costura_larg",
##  "frente_cima", "frente_baixo"}. Guarda a malha pronta num cache por Mesh.
static func preparar(mi: MeshInstance3D, esqueleto: Skeleton3D) -> Dictionary
## As medianas de L (OKLab) de cada parte, pela cor da textura recolorida no
## UV de cada vértice: {"cabeca", "superior", "inferior"}, e as cores usadas
## por superior e inferior em "cores". Com `boneco.get_meta("so_pano", false)`,
## o superior e o inferior pulam os vértices com UV em PELE_UV (a pele).
static func medianas(boneco: Node3D) -> Dictionary
```

  As medidas do acento saem da caixa de repouso de cada osso (o AABB dos
  vértices de maior peso nele):
  - `frente_cima` = largura × altura do torso + as duas dos braços;
    `frente_baixo` = as duas das pernas;
  - `friso_alto` = `min(0.010, 0.08 * frente_cima / (2 * largura_do_torso))`;
  - `costura_larg` = `min(0.008, 0.05 * frente_baixo / (2 * altura_da_perna))`;
  - se `2 * friso_alto * largura_do_torso + 2 * costura_larg * altura_da_perna`
    passar de 8 % de `frente_cima + frente_baixo`, as duas larguras caem na
    mesma razão até caber.

  O boneco sem skin (rígido) não passa por `preparar`: ele é monstro (G10),
  não jogador.

**A4. `player.gd`, a roupa sem a cor do lugar:**

```gdscript
const SH_CAVALEIRO := preload("res://shaders/cavaleiro.gdshader")
const SH_CONTORNO := preload("res://shaders/contorno.gdshader")
const SH_NEON := preload("res://shaders/neon.gdshader")
## O contorno: 1,6 na montagem, 2,4 no resto (arte/07).
const CONTORNO_MONTAGEM := 1.6
const CONTORNO_JOGO := 2.4
var _mats_corpo: Array[ShaderMaterial] = []   ## os do body*, para o acento
var _contornos: Array[ShaderMaterial] = []

## A roupa (arte/04): cada parte na sua faixa, o néon do dono só no acento,
## no contorno e no aro. Troca o `_vestir` de hoje, que multiplicava pela cor.
func _vestir(n: Node) -> void
## O contorno de todos os casco: 1,6 ou 2,4.
func brilho_do_contorno(energia: float) -> void
## O encaixe de uma peça (a G13 chama): o acento sobe a 2,6 e volta a 1,6 em
## 0,25 s, SAI. Com Opcoes.movimento reduzido, o mesmo (é luz, não movimento).
func acender_acento() -> void
## O contrato da G01 (se a G01 ainda não chegou, nasce aqui): 0 apaga (o corpo em Tema.GRAFITE, sem
## acento, sem aro, sem contorno), 1 acende como o _vestir deixou.
func acender(k: float) -> void
```

  `acender(k)`: em cada material de `_mats_corpo` e da cabeça,
  `set_shader_parameter("acesa", k)`; em cada `_contornos`, `energia` =
  `k ×` o valor atual de `brilho_do_contorno`; `aro.visible = k >= 0.5`. A
  lista `_roupas` e o `albedo_color` que a G01 usava saem: o shader faz o
  mesmo.

  `_vestir`: para cada `MeshInstance3D` do modelo, `Pintura.preparar`, um
  `ShaderMaterial` com `SH_CAVALEIRO`, a textura do `colormap.png` ao lado do
  `.glb` por `Pintura.textura(caminho, "tecido", pp)` em `textura_cima` e
  `Pintura.textura(caminho, "couro", pp)` em `textura_baixo`, com
  `pp = "personagem"` quando o `.glb` está em `mini-characters/` e `""` fora
  dele; `modelo.set_meta("so_pano", pp != "")` (na `head*`, `"personagem"`
  nas duas e `tem_acento` false), `dono = Tema.JOGADOR[lugar]`, as medidas de
  `preparar`; e no `next_pass` um `ShaderMaterial` com `SH_CONTORNO`
  (`cor = Tema.JOGADOR[lugar]`, `largura` 0,012, `energia` 2,4). Se a G15 já
  fez `Tema.contorno(cor, largura, energia, dono)`, usar ela com
  `dono = lugar`.

**A5. O anel no chão** troca o aro de `montar()`: `Kit.anel_do_dono(self,
lugar)`, uma cópia de `Mundo.anel` do estudo (toro de `rings` 8,
`ring_segments` 4, raios 0,57 e 0,65, escala y 0,22, girado π/8, néon 1,5; as
lâmpadas de `Forja.LEDS_DO_LUGAR[lugar]` a 1,8, em x = (i − 2) · 0,16 e
z = 0,82). O campo `aro` do player passa a guardar o `Node3D` devolvido (quem
usa `p.aro.visible` continua funcionando). Sombra desligada no néon.

**A6. O boneco e o pio:**

```gdscript
## Os bonecos registrados: o arquivo e o intervalo do pio (arte/03). A G10
## acrescenta os 12 do Mini Characters; a G13 troca por peças.
const BONECOS := [
	{"nome": "Humano", "arquivo": "character-human", "intervalo": "segunda"},
	{"nome": "Orc", "arquivo": "character-orc", "intervalo": "quinta_baixo"},
]
static func nome_do_boneco(i: int) -> String:
	return Traducoes.traduzir(BONECOS[wrapi(i, 0, BONECOS.size())].nome)
```

  Saem `MODELOS`, `NOME_DO_MODELO` e `INTERVALO_DO_MODELO`
  (`grep -rn "MODELOS\|NOME_DO_MODELO\|INTERVALO_DO_MODELO" godot/` e trocar
  cada uso). `Som.pio(l, boneco)` lê `ForjaPlayer.BONECOS[boneco].intervalo`.
  `"Humano"` e `"Orc"` já são palavras do jogo; conferir em `traducoes.gd`
  que existem `"Humano": "Human"` e `"Orc": "Orc"`, e acrescentar se faltar.

**A7. O guardião d'A Voz em blocos** (`_montar_guardiao()`, as mesmas chaves
no dicionário e a mesma animação, com uma troca:
`boca.scale = Vector3(1, 0.12 + 0.75 * snappedf(grito, 0.25), 1)`, a boca
abre em degraus de 0,25). Pedra `Kit.material(Tema.GRAFITE, 0.0, 0.95)`,
escuro `Kit.material(Tema.CASCO, 0.0, 0.9)`, tudo filho de `pivo` (escala
0,86):

| parte | como |
| --- | --- |
| a cabeça | testa `Kit.caixa(pivo, Vector3(2.6, 0.9, 1.0), Vector3(0, 0.95, 0), pedra)`; face `(2.9, 1.0, 1.1)` em `(0, 0.1, 0)`; queixo `(2.2, 0.8, 1.0)` em `(0, -0.8, 0)` |
| as sobrancelhas | as duas caixas de hoje, em escuro |
| o nariz | `(0.35, 0.7, 0.35)` em `(0, 0.05, 0.62)`, pedra |
| os olhos | `Kit.caixa(pivo, Vector3(0.34, 0.22, 0.12), Vector3(±0.55, 0.3, 0.56), mat_olho)` (o `mat_olho` de hoje) |
| as pálpebras | `(0.5, 0.44, 0.12)` em `(±0.55, 0.28, 0.62)`, pedra |
| a boca | `boca.position = Vector3(0, -0.78, 0.56)`; o fundo `(1.1, 1.0, 0.1)` em `Kit.material(Tema.JANELA, 0.0, 1.0)`; os dentes como hoje, em `Kit.material(Tema.ETIQUETA, 0.0, 0.8)` |
| a luz | `brilho` e `foco` como hoje |

**A8. A coerência:**

- `kit.gd`: `cilindro` com `radial_segments` 8; `esfera` com
  `radial_segments` 8 e `rings` 4; o chifre da bigorna com `sides` 8; a função
  nova `static func anel(pai: Node, raio_dentro: float, raio_fora: float, pos:
  Vector3, mat: Material) -> MeshInstance3D` (`TorusMesh` de `rings` 8 e
  `ring_segments` 6, `material_override = mat`) e `anel_do_dono` (A5).
- Cada `TorusMesh` da lista do estado de hoje: `rings = 8`,
  `ring_segments = 6`. `centelha.gd:140` e `salao.gd:223`: `radial_segments`
  8, `rings` 4. Os CSG da lista: `sides = 8`.
- Os seis `metallic`: 0,2, e a rugosidade de cada um no mínimo 0,45
  (`molde.gd:423` de 0,3 para 0,5; `canto.gd` de 0,35 para 0,5;
  `viga.gd:70` de 0,3 para 0,5; `caminhos.gd` de 0,35 para 0,5; `voz.gd` sai
  com o guardião; `prova.gd:124` de 0,35 para 0,5). A energia de emissão não
  muda aqui (é da G15).

### Parte B — as quatro raças

**B1.** `python3 scripts/importar_kenney.py oficina/kenney/3.7.0 cube-pets`
(o script da G10, que já tem `cube-pets` na curadoria). A cauda não passa por
`Kit.peca`, então o 0,4 do `ESCALA_DO_PACOTE` não vale para ela: a escala é a
0,33 do B2.

**B2. `Racas`** (`godot/scripts/mundo/racas.gd`, novo): o estudo
`godot/estudos/direcao/cavaleiro/racas.gd` portado. A API:

```gdscript
class_name Racas
extends RefCounted
const NOMES := ["Humana", "Orc", "Autômato", "Golem", "Raposa"]
const CHAVES := ["humana", "orc", "automato", "golem", "raposa"]   ## o RACAS do estudo
const PESCOCO := 0.343
const ESCALA_CABECA := 1.30
const ENERGIA := 1.6
## Veste a raça no esqueleto do Mini Characters (o da G13). Primeiro apaga o
## que uma raça anterior pôs (os nós do grupo "raca") e volta a cabeça humana
## visível; tudo o que cria entra no grupo "raca". Põe ou tira o
## ProporcaoDoGolem; liga `pele` e `pele_ativa` nos materiais do corpo.
## `marca`: a cor do cabelo do perfil, que `cabelo()` dá.
static func vestir(esq: Skeleton3D, raca: int, lugar: int, marca: Color) -> void
## A pele da raça (Color(0, 0, 0, 0) na Humana).
static func pele(raca: int) -> Color
## A cor de maior área da cabeça do perfil fora de PELE_UV (racas.gd:110-135).
static func cabelo(cabeca: Mesh, colormap: Image) -> Color
## O punho no espaço do esqueleto: o Montar.mao do estudo (montar.gd:180-211).
static func punho(esq: Skeleton3D, osso: String) -> Vector3
```

Copiar de `racas.gd`, sem mudar número: `_por` (138), `_liso` (152), `_caixa`
(169), `_chanfrada` (177), `_tronco` (185), `_prisma` (222), `_juntar` (228),
`_montar` (238), `automato` (249), `golem` (289), `raposa` (334), `_mao`
(357), `_cauda` (380) e o corpo de `vestir` (53). As trocas:

| no estudo | no jogo |
| --- | --- |
| `raca: String` | `CHAVES[raca]` |
| `perfil` e `cabelo(perfil)` | o argumento `marca` |
| `maos` | `[punho(esq, "arm-left"), punho(esq, "arm-right")]`, dentro do `vestir` |
| `cor` | `Tema.JOGADOR[lugar]` |
| `Fita.JANELA`, `Fita.ETIQUETA_SOMBRA`, `Fita.TINTA`, `Fita.PELE_*` | `Tema.JANELA`, `Tema.ETIQUETA_SOMBRA`, `Tema.TINTA`, `Tema.PELE_*` |
| `Fita.PELE_UV` | `Pintura.PELE_UV` |
| `Fita.neon(cor, ENERGIA)` | `Tema.neon(cor, ENERGIA, lugar)` (G15); sem a G15, um `ShaderMaterial` com `ForjaPlayer.SH_NEON`, `cor` e `energia` |
| `Mundo.contornar(n, cor, largura, energia)` | `_contornar`, cópia de `godot/estudos/direcao/mundo.gd:80-92` com o `suavizar` (`mundo.gd:48`); o `Fita.contorno` dela (`fita.gd:245-251`) vira um `ShaderMaterial` com `ForjaPlayer.SH_CONTORNO`, `cor`, `largura` e `energia` |
| `_liso`: `Fita.SH_CAVALEIRO`, `textura`, `rugosidade`, `metalico`, `aro_cor` | `ForjaPlayer.SH_CAVALEIRO`; a textura de 1 px em `textura_cima` e `textura_baixo`; `rugoso_cima` e `rugoso_baixo`; `metal`; `dono`; `tem_acento` false |
| o orc: `Cortar.partes("orc")` e `Corpo.parte` | a `head-mesh` de `Kit.caminho("mini-dungeon-personagens/character-orc")`: a malha e o skin num `MeshInstance3D` `"raca-orc"` filho do esqueleto, com o `transform` da cabeça humana; o material `SH_CAVALEIRO` com `Pintura.textura` do colormap do orc em `personagem`, passado por `Pintura.trocar_matiz(img, Tema.PELE_ORC, -0.05)`; a cabeça humana fica invisível, não sai |
| `RAPOSA_CAUDA` | `Kit.caminho("cube-pets/animal-fox")` |
| `preparar` (`set_bone_pose_scale`) | o `ProporcaoDoGolem` abaixo: no jogo a animação reescreve a escala de todo osso a cada quadro, e a pose parada do estudo não |

- **As mãos na pele:** o `vestir` põe, em cada `ShaderMaterial` do corpo com
  `ForjaPlayer.SH_CAVALEIRO` fora do grupo `"raca"`, `pele = pele(raca)` e
  `pele_ativa = 1.0` (0,0 na Humana). A pele da mão e da perna de fora vira a
  da raça, com o degradê da rampa.
- **O Golem:** `class ProporcaoDoGolem extends SkeletonModifier3D` dentro de
  `racas.gd`, que em `_process_modification_with_delta` multiplica a escala
  da pose do `torso` por (1,15; 1; 1,15) e a do `head` por (0,87; 1; 0,87).
  Filho do esqueleto, no grupo `"raca"`.
- **O tufo do orc:** `Kit.caixa` de 0,06 na cor `marca`, num
  `BoneAttachment3D` do osso `head`, com o centro em (0; 0,78; 0) no espaço
  do esqueleto (o `resto.affine_inverse()` do `vestir`).
- **A cauda balança:** no `_process` de quem mostra o boneco (a tela da
  G13), o `MeshInstance3D` `"cauda"` (`racas.gd:392`; o pai dele guarda os 8°
  do estudo) recebe `rotation.y = deg_to_rad(8) * sin(TAU * batidas)`, com
  `batidas = Time.get_ticks_msec() / 1000.0 * Musica.mapa(Musica.atual).bpm / 60.0`
  (`musica.gd:128`; 120 BPM sem faixa).
- **`punho`** lê a malha do superior que a G13 põe no esqueleto: no estudo, o
  nó `"body-sup"` (`corpo.gd:27`). A G13 usa os nomes do estudo
  (`"head"`, `"body-sup"`, `"body-inf"`).
- **A cadeira de rodas (R1 do inferior, G13):** toda raça senta; a cauda sobe
  0,05.
- Os triângulos contam só sob o nó `"raca-cabeca"` (o `BoneAttachment3D`
  do estudo, `racas.gd:68`): até 300 no autômato e na raposa, até 400 no
  golem. As mãos e a cauda ficam fora da conta.

**B3. A montagem (`godot/scripts/ui/tela_lobby.gd`, a tela da G13):** na
linha da cabeça, R1 faz `raca[l] = (raca[l] + 1) % 5`, chama
`Racas.vestir(esq, raca[l], l, Racas.cabelo(<a malha da cabeça do perfil>, <o colormap do Mini Characters>))`, toca o som e o pulso de O
som e O controle, e troca o rótulo «Cabeça» pelo nome da raça
(`Traducoes.traduzir(Racas.NOMES[raca])`), na letra da linha (Archivo Narrow 600, 30
px). O pré-montado sorteia pela regra de Como se joga. A raça vai junto do
cavaleiro guardado (`Opcoes.cavaleiro`, chave `"raca"`, padrão 0).

**B4.** `traducoes.gd`: `"Humana": "Human"`, `"Autômato": "Automaton"`,
`"Golem": "Golem"`, `"Raposa": "Fox"` (o `"Orc"` já existe).

## Passos

Rodar `bash tests/prova_do_jogo.sh` depois dos passos 3, 6 e 8.

1. `scripts/conferir_bonecos.py` e
   `python3 scripts/conferir_bonecos.py && python3 scripts/conferir_bonecos.py --teste`.
2. `godot/shaders/` (A2) e `godot/scripts/mundo/pintura.gd` (A3);
   `"$GODOT" --headless --path godot --import --quit` para nascerem os `.uid`.
3. `player.gd`: A4, A5, A6; `som.gd`: o `pio`; `main.gd`, em `_mostrar(qual)`:
   `for p in jogadores: p.brilho_do_contorno(ForjaPlayer.CONTORNO_MONTAGEM if qual == "lobby" else ForjaPlayer.CONTORNO_JOGO)`.
4. `voz.gd`: A7.
5. `kit.gd`, as salas, `salao.gd`, `efeitos.gd`: A8.
6. `tests/prova_do_jogo.sh`: antes do Godot, a linha
   `python3 "$RAIZ/scripts/conferir_bonecos.py" > "$TMP/bonecos.log" && python3 "$RAIZ/scripts/conferir_bonecos.py" --teste >> "$TMP/bonecos.log" || { cat "$TMP/bonecos.log"; echo "FAIL os bonecos"; exit 1; }`;
   e as funções de Provas em `godot/testes/prova_do_jogo.gd`.
7. Parte B, só com a G13 feita: B1, B2, B3, B4.
8. As provas da parte B.

## Armadilhas

- **A malha preparada guarda o skin:** `surface_get_arrays` traz `ARRAY_BONES`
  e `ARRAY_WEIGHTS`; o `add_surface_from_arrays` tem de passar os mesmos
  `flags` da superfície original (`surface_get_format(s)`, com
  `Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS` se houver). O `skin` do
  `MeshInstance3D` fica o mesmo.
- **A faixa do acento é pela posição de repouso (UV2), não pelo `VERTEX`:**
  o `VERTEX` já vem animado e a faixa andaria com o pulo.
- **O UV2 dos Kenney está vazio:** se algum `.glb` novo trouxer UV2, a
  `preparar` sobrescreve (a luz do jogo não usa lightmap).
- **O cache da malha:** um `Mesh` preparado por malha de origem, não por
  jogador; os quatro lugares dividem a malha e cada um tem o seu material.
- **O contorno precisa da normal suave no TANGENT:** sem ela, o casco abre
  nos cantos dos blocos.
- **`metallic` não volta:** o orc e as raças passam pelo conferidor; o
  autômato é o único 0,2.
- **A prova visual da nuvem não aprova cor:** a mediana de L é conferida por
  número na prova do jogo; a prancha cinza é para o olho do time.
- **A G15 e os shaders:** se a G15 entrar antes, os `.gdshader` de
  `godot/shaders/` são dela; não duplicar.
- **O robô:** nada novo na parte A. Na parte B, o robô aperta R1 uma vez na
  montagem (o temperamento `bom` e o `medio`; o `ruim` não).
- **Os temperamentos e os casos que quebram:** `--robo=bom|medio|ruim`,
  partidas com 1 e 2 jogadores e o `simulador_cabo` (o controle cai e volta):
  o cavaleiro de quem caiu mantém a raça, o acento e o contorno.

## Não fazer

- Não tingir corpo nenhum na cor do lugar, em nenhum lugar do jogo.
- Não usar os monstros do Graveyard (esqueleto, zumbi, vampiro, fantasma)
  como raça: eles são inimigos (arte/04, o que ficou de fora).
- Não dar stat, colisão ou janela à raça.
- Não mexer na emissão dos materiais de sala nem na luz (G15).
- Não criar animação nova.

## Pronto quando

Nos quatro cavaleiros da montagem, a mediana de L do superior fica em
[0,46; 0,58], a do inferior em [0,22; 0,36] e as duas diferem em 0,10 ou mais;
toda cor de peça tem croma de até 0,10 e ΔE de 0,08 ou mais até cada
`Tema.JOGADOR`; o acento soma até 8 % da frente do corpo; nenhuma curva tem
mais de 8 lados e nada passa de `metallic` 0,2; o guardião não tem esfera; e,
com a parte B, as cinco raças vestem os quatro lugares sem perder osso nem
animação.

## Provas

**Na sessão:** `bash tests/prova_do_jogo.sh` (com a linha do conferidor do
passo 6).

Em `godot/testes/prova_do_jogo.gd`, chamadas logo depois de chegar ao lobby
(`_prova_da_peca()`), em `_comeca_a_sala(id)` depois do `_esperar` de
abertura (`_confere_a_arte(sala, id)`), e uma vez no salão
(`_confere_a_arte(jogo.salao, "o salão")`):

```gdscript
## A peça se distingue (arte/04): as faixas de L, o croma, a distância até os
## néons e a área do acento.
func _prova_da_peca() -> void:
	for p in jogo.jogadores:
		var m: Dictionary = Pintura.medianas(p.modelo)
		_esperar(m.superior >= 0.46 and m.superior <= 0.58, "P%d: o superior na faixa (%.3f)" % [p.lugar + 1, m.superior])
		_esperar(m.inferior >= 0.22 and m.inferior <= 0.36, "P%d: o inferior na faixa (%.3f)" % [p.lugar + 1, m.inferior])
		_esperar(m.superior - m.inferior >= 0.10, "P%d: superior e inferior diferem 0,10 (%.3f)" % [p.lugar + 1, m.superior - m.inferior])
		var ruins := []
		for c in m.cores:
			var v := Pintura.para_oklab(c)
			if Vector2(v.y, v.z).length() > 0.1001:
				ruins.append("croma %s" % c.to_html(false))
			for j in Tema.JOGADOR:
				if Pintura.delta_e(c, j) < 0.08:
					ruins.append("perto do néon %s" % c.to_html(false))
		_esperar(ruins.is_empty(), "P%d: a peça nunca é néon %s" % [p.lugar + 1, ruins])
		var mat: ShaderMaterial = p._mats_corpo[0]
		var area: float = 2.0 * mat.get_shader_parameter("friso_alto") * p._medidas.largura_torso \
			+ 2.0 * mat.get_shader_parameter("costura_larg") * p._medidas.altura_perna
		_esperar(area <= 0.0801 * (p._medidas.frente_cima + p._medidas.frente_baixo), "P%d: o acento em até 8 %% da frente" % (p.lugar + 1))
		_esperar(is_equal_approx(float(mat.get_shader_parameter("aro")), 0.25), "P%d: o aro a 0,25" % (p.lugar + 1))
		_esperar(not mat.shader.code.contains("tingir"), "P%d: nada se tinge" % (p.lugar + 1))
		p.acender(0.0)
		_esperar(is_zero_approx(float(mat.get_shader_parameter("acesa"))), "P%d: acender(0) apaga a armadura" % (p.lugar + 1))
		p.acender(1.0)
		_esperar(is_equal_approx(float(mat.get_shader_parameter("acesa")), 1.0), "P%d: acender(1) volta" % (p.lugar + 1))
		var cont: ShaderMaterial = mat.next_pass
		_esperar(is_equal_approx(float(cont.get_shader_parameter("energia")), 1.6), "P%d: o contorno a 1,6 na montagem" % (p.lugar + 1))
```

(`p._medidas` é o dicionário que `Pintura.preparar` devolveu para o corpo,
guardado pelo `_vestir`, com `largura_torso` e `altura_perna` a mais.)

```gdscript
## O checklist que se confere sem olho: nada liso, nada metálico.
func _confere_a_arte(raiz: Node, onde: String) -> void:
	var lisas: Array = []
	var metalicos: Array = []
	for n in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var m := mi.mesh
		if (m is SphereMesh and (m as SphereMesh).radial_segments > 8) \
				or (m is TorusMesh and (m as TorusMesh).rings > 8) \
				or (m is CylinderMesh and (m as CylinderMesh).radial_segments > 8):
			lisas.append(str(raiz.get_path_to(mi)))
		var mat := mi.material_override
		if mat is StandardMaterial3D and (mat as StandardMaterial3D).metallic > 0.2:
			metalicos.append(str(raiz.get_path_to(mi)))
	for n in raiz.find_children("*", "CSGCylinder3D", true, false):
		if (n as CSGCylinder3D).sides > 8:
			lisas.append(str(raiz.get_path_to(n)))
	for n in raiz.find_children("*", "CSGTorus3D", true, false):
		if (n as CSGTorus3D).sides > 8:
			lisas.append(str(raiz.get_path_to(n)))
	_esperar(lisas.is_empty(), "%s: nenhuma curva lisa %s" % [onde, lisas])
	_esperar(metalicos.is_empty(), "%s: nada metálico acima de 0,2 %s" % [onde, metalicos])
```

No salão, depois de `_confere_a_arte`: o contorno de cada jogador a 2,4
(`_esperar(is_equal_approx(float(p._mats_corpo[0].next_pass.get_shader_parameter("energia")), 2.4), ...)`).
N'A Voz, depois de abrir:
`_esperar(sala.g.pivo.find_children("*", "MeshInstance3D", true, false).all(func(m): return not (m.mesh is SphereMesh)), "o guardião d'A Voz não tem esfera")`.

**Parte B**, uma função nova `_prova_das_racas()`, chamada na montagem:

```gdscript
func _prova_das_racas() -> void:
	var p: ForjaPlayer = jogo.jogadores[3]
	var esq: Skeleton3D = p.modelo.find_child("Skeleton3D", true, false)
	for r in Racas.NOMES.size():
		Racas.vestir(esq, r, 3, Color.WHITE)
		await _quadros(2)
		var faltam := []
		for a in ["idle", "walk", "emote-yes", "attack-melee-right", "interact-right"]:
			if not p.anim.has_animation(a):
				faltam.append(a)
		_esperar(faltam.is_empty(), "%s: as animações %s" % [Racas.NOMES[r], faltam])
		_esperar(esq.get_bone_count() == 7, "%s: os sete ossos" % Racas.NOMES[r])
		var tri := 0
		var cab := esq.find_child("raca-cabeca", true, false)
		if cab != null:
			for n in cab.find_children("*", "MeshInstance3D", true, false):
				tri += (n as MeshInstance3D).mesh.get_faces().size() / 3
		var teto := 400 if r == 3 else 300
		_esperar(tri <= teto, "%s: a cabeça por código até %d triângulos (%d)" % [Racas.NOMES[r], teto, tri])
		if r > 0:
			_esperar(Pintura.delta_e(Racas.pele(r), Tema.JOGADOR[0]) >= 0.08, "%s: a pele longe do néon" % Racas.NOMES[r])
	Racas.vestir(esq, 0, 3, Color.WHITE)
```

E na montagem com o robô, logo depois do R1 do P1 (`await _aperta(0, Forja.R1)`, com
a linha da cabeça escolhida):

```gdscript
	await _quadros(2)
	var sv: Dictionary = Forja.som_virtual(0)
	var pe := _perc(0)
	_esperar(float(pe.get("fraco", 0.0)) > 0.0 or float(sv.get("esq", 0.0)) > 0.0 or float(sv.get("dir", 0.0)) > 0.0,
		"o R1 da raça chega à mão do P1")
	_esperar(float(sv.get("falante", 0.0)) > 0.05, "o ui_peca da raça sai no alto-falante do P1")
	_esperar(float(Forja.som_virtual(1).get("falante", 0.0)) < 0.05, "e não no do P2")
```

**A prova visual (F09):** `bash tests/prova_visual.sh` com as quatro partidas;
a prancha nova `prancha-montagem-cinza.png` (o quadro da montagem em L, com
cada cavaleiro reduzido a 64 px de altura) e a de cada sala com o anel de 8
lados.

## Para o André (local)

1. `bash tests/prova_visual.sh` sem `--fixed-fps`, com a placa de vídeo:
   na prancha cinza, cabeça, tronco e pernas se separam nos quatro; nas
   coloridas, a camisa e a calça de cada um têm cores diferentes e o néon só
   aparece no contorno, no friso, na costura e no anel. Anotar no diário.
2. `./run-local.sh`: na montagem, de 3 m da TV, apontar o seu cavaleiro sem
   olhar o P#.
3. Parte B: passar pelas cinco raças nos quatro lugares; nenhuma peça
   atravessa a cabeça, a cauda da raposa balança na batida.

## Ao terminar

No [quadro](README.md), G08 **feito** (ou «parte A feita, a B espera a G13»)
com o commit e o gasto. Commit sugerido (sem trailer):

```
feat(arte): cada parte do cavaleiro na sua faixa, o néon do dono só no acento e as quatro raças
```
