# G13 — O cavaleiro montável

**Sprint:** G · **Tamanho:** G · **Depende de:** F00, F07 (o texto), F09 (a prova visual), G02 (a construção: a coluna, a forja, o robô, o guardado), G08 parte A (`Pintura`, o shader, `acender_acento`), G10 (os 12 do Mini Characters em `godot/assets/kenney/mini-characters/`), G14 (os tokens e as fontes) · **Usado por:** G03 (lê `Itens.em_liga`, que esta ficha escreve), G04 (o VU e `car_liga` pelo `Visor`), G06 (o cavaleiro guardado), G08 parte B (as raças no esqueleto montado), G09 (a linha Nome), H04 e as fichas de minigame (`Cavaleiro.gancho`)

## Por quê

Ela, na noite de teste: «as roupas superiores e inferiores precisam se
diferenciar. tudo tá num neon de uma unica cor que nada diferencia na hora da
montagem.» E: «as pessoas precisam ter prazer no início do jogo.» Hoje cada
lugar escolhe um de dois bonecos inteiros, pintados por cima com a cor do
lugar. Esta ficha corta os 12 personagens do Mini Characters em cabeça,
superior e inferior, monta três peças de personagens diferentes no mesmo
esqueleto, põe os stats dos CSV do designer de sistemas na tela, e faz de
cada troca um encaixe que se ouve, se sente e se vê em menos de 1 s. A cor de
cada peça é a dela (G08 parte A); o néon do lugar só marca o acento.

## Ler antes

- [A tela de montagem](../arte/04-o-cavaleiro.md#a-tela-de-montagem) (a coluna, os botões, a forja)
- [O primeiro minuto](../arte/04-o-cavaleiro.md#o-primeiro-minuto) (o encaixe, a pose de cada linha, o carimbo)
- [A regra que impede](../sistemas/README.md#a-regra-que-impede) (os opostos; logo abaixo, o arquétipo, a build boa e o pré-montado)

## Arquivos que mudam

| arquivo | também muda em |
| --- | --- |
| `godot/testes/cortar_pecas.gd` e `.uid` (novos, `extends SceneTree`; `testes/` fica fora da exportação) | — |
| `scripts/dados_do_cavaleiro.py` (novo) | — |
| `godot/assets/kenney/mini-characters/pecas/` (novos: 60 `.res`) | — |
| `godot/dados/pecas.csv`, `itens.csv`, `stats.csv`, `arquetipos.csv`, `nomes.csv`, `regras.csv` (cópias geradas) | **G03** (lê `itens.csv`), **H04** |
| `godot/scripts/cavaleiro.gd` e `.uid` (novos, `class_name Cavaleiro`) | **H04** e as fichas I a R (só leem `gancho`) |
| `godot/scripts/mundo/montar.gd` e `.uid` (novos, `class_name Montar`) | **G08** (`Racas.punho` usa `Montar.mao`) |
| `godot/scripts/player.gd` (`pecas`, `cadeira`, `BONECOS`, `montar`, `acender_parte`, `cavaleiro`, `vestir`) | **G01, G02, G03, G06, G08, G10, G14, G15** |
| `godot/scripts/mundo/pintura.gd` (`juntar_medidas`) | **G08** |
| `godot/scripts/ui/tela_lobby.gd` (as cinco linhas, o encaixe, o sorteio, a trava) | **G02, G03, G08, G09** |
| `godot/scripts/ui/cartao_jogador.gd` (a coluna inteira) | **G02** |
| `godot/scripts/ui/desenho.gd` (`placa`, `lampadas`, `dica`, `vu`, se ainda não existem) | **G04, G06, G11, G12, G14, G16** |
| `godot/scripts/ui/glifo.gd` (os quatro emblemas) | **G02, G04, G11** |
| `godot/scripts/mundo/salao.gd` (`montagem`, as bigornas e as luzes da montagem) | **G02, G06, G08** |
| `godot/scripts/main.gd` (`_mostrar`, `_pose_da_camera`, `_lente`, `_quadro_lobby`, `_robo`) | **G01, G02, G03, G04, G05, G06, G07, G08, G09, G11, G14, G15, G16** |
| `godot/scripts/opcoes.gd` (as chaves novas de `cavaleiro`) | **G02, G06, G16** |
| `godot/scripts/traducoes.gd` | **todas as G com texto** |
| `godot/assets/sons/ui_sorteio.wav`, `ui_trava.wav`, `car_liga.wav`, `ass_p1..4.wav` e os `.import`; `docs/jogo/audio/mapa.csv` | **G01, G02, G03, G04, G06, G07, G09, G11, G12, G16** |
| `docs/jogo/13-arquitetura.md` (a linha `cavaleiro` do registro) | **G02** |
| `godot/testes/prova_do_jogo.gd` | **todas as G** |
| `godot/testes/captura_jogo.gd` (o roteiro da construção) | **G02, G16** |

## Como se joga

A construção da G02 continua: a coluna de 432 px de cada lugar, a música a
120 BPM, as 8 marteladas que calibram, o guardado da noite. Esta ficha troca
as três linhas da G02 por cinco e põe as peças, os stats e o encaixe.

| botão | faz |
| --- | --- |
| ▲ ▼ | a linha: Cabeça, Superior, Inferior, Arma ou amuleto, Nome (para nas pontas) |
| ◀ ▶ | troca a peça da linha: o próximo dos 12 personagens, pulando os riscados (a regra dos opostos) e, na cabeça, os de outro lugar. Na arma ou amuleto, o próximo item que o corpo alcança. No nome, o próximo livre |
| R1 | na Cabeça: a raça (G08 parte B3). No Inferior: Pernas → as quatro cadeiras → Pernas |
| △ | sorteia tudo o que não está travado, pelo pré-montado (6 trocas, uma por semicolcheia) |
| □ (toque) | trava ou destrava a linha (Cabeça, Superior, Inferior e Arma ou amuleto; o Nome não trava) |
| □ (segurar 1 s) | troca de lugar (F04) |
| ✕ | forja: as 8 marteladas (G02) |
| ○ | volta: desfaz a forja; da linha 1, sai do lugar |

- **Todo lugar nasce montado** pelo pré-montado (Os stats): um cavaleiro bom
  com um item que uma troca de peça põe em liga. A primeira coisa que a
  pessoa descobre é essa troca.
- **A troca de uma peça muda o item** quando o corpo novo não alcança mais o
  item: ele passa ao próximo que o corpo alcança, na ordem de
  `ForjaPlayer.ITENS`. Todo corpo válido alcança pelo menos um item (o
  `conferir.py` conta: 96 corpos alcançam 1, 380 alcançam 2, 280 alcançam 3).
- **A cadeira** troca as pernas sem mudar stat: o stat é o da peça inferior
  escolhida (a linha mostra «Cadeira» e o nome da peça some).

## A cena

### A câmera (50 mm, frontal, à altura do peito)

O plano do estudo (`godot/estudos/direcao/quadros/10_montagem.gd:42-53`),
deslocado para o salão (o cavaleiro do estudo está em z 0; o do jogo, em
z 4,4):

| campo | valor |
| --- | --- |
| `position` | `Vector3(0, 0.95, 13.4)` (9 m na frente dos cavaleiros) |
| `rotation` | `Vector3.ZERO` |
| `projection` | `Camera3D.PROJECTION_FRUSTUM` |
| `near` / `far` | 0,1 / 60 |
| `size` | 0,048 (`2 × near × 0,24`, 27° vertical) |
| `frustum_offset` | `Vector2(0, -0.82 * 0.1 / 9.0)`: desce 0,82 m (0,16 + 165 / 250) para o cavaleiro cair entre y 160 e 600 sem a câmera olhar para baixo |

A 9 m, 250 px por metro. Os centros das colunas (`96 + 432·i + 216`) caem em
x de mundo `(centro − 960) / 250`: **−2,592, −0,864, 0,864, 2,592**.

- `_pose_da_camera()`, ramo `"lobby"`: devolve a posição e o alvo
  `Vector3(0, 0.95, 4.4)`; um `_lente_da_montagem(true)` liga o FRUSTUM ao
  entrar e `_lente_da_montagem(false)` volta a `PROJECTION_PERSPECTIVE` e
  `frustum_offset = Vector2.ZERO` ao sair do lobby (em `_mostrar`).
- `_lente()` (G05): `"lobby"` → 50,0; no plano dos prontos, 85,0. Sem a G05,
  o FRUSTUM acima basta.

### Onde ficam os cavaleiros

- `salao.gd`: `var montagem: Array[Vector3]`, os quatro
  `Vector3(-2.592 + 1.728 * i, 0.06, 4.4)`, e `var montagem_no: Node3D` com
  os quatro anéis do estudo (`Mundo.anel`, `godot/estudos/direcao/mundo.gd:200`,
  chamado em `cavaleiro/montar.gd:71-72` pelo `"anel": true`), portado como
  está, com `raio` 0,62: um `Node3D` a y 0,03; nele um `MeshInstance3D` com
  `TorusMesh` `inner_radius` 0,57 (raio − 0,05), `outer_radius` 0,65
  (raio + 0,03), `rings` 8, `ring_segments` 4, `scale = Vector3(1, 0.22, 1)`,
  `rotation.y = PI / 8`, material néon da cor do lugar a 1,5 (o `Fita.neon`
  do estudo vira o que a G08 diz na tabela de troca: `Tema.neon(cor, 1.5, l)`
  da G15, ou o `ShaderMaterial` com `ForjaPlayer.SH_NEON`); e as lâmpadas do
  lugar na frente do anel: para cada bit `i` (0 a 4) aceso em
  `Forja.LEDS_DO_LUGAR[l]`, um `BoxMesh` de 0,09 × 0,02 × 0,14 em
  `Vector3((i − 2) × 0,16, 0, 0,82)`, néon a 1,8. O `rings` 8 passa no
  `_confere_a_arte` da G08 (reprova acima de 8). O «aro a 0,25» do acento é
  outro: o fresnel do shader (G08), não este anel.
- `main.gd`: no lobby (`_mostrar`, linha 226, e `_sincronizar_jogadores`,
  linha 238) o cavaleiro vai para `salao.montagem[l]`, não para
  `salao.pedestais[l]`. `salao.pedestais_no.visible = qual == "podio"`;
  `salao.montagem_no.visible = qual == "lobby"`.
- **As bigornas da G02** saem de `pedestais_no` para `montagem_no`, em
  `montagem[l] + Vector3(0.62, -0.06, -0.5)`, escala 0,3; a luz de cada uma em
  `+ Vector3(0.62, 0.5, -0.5)`.

### A luz de cada coluna

Do estudo (`10_montagem.gd:76-81`, `Mundo.foco` em
`godot/estudos/direcao/mundo.gd:304`), deslocada em z 4,4. Nascem em
`montagem_no`:

| luz | de | para | cor | energia | ângulo | alcance | sombra |
| --- | --- | --- | --- | --- | --- | --- | --- |
| a chave (`SpotLight3D`) | `(x + 1.6, 3.6, 7.6)` | `(x, 0.8, 4.4)` | `Tema.TUNGSTENIO` | 3,2; 5,5 depois de forjar | 22° | 9 | sim |
| o contra-luz (`SpotLight3D`) | `(x − 0.4, 2.8, 1.8)` | `(x, 1.0, 4.4)` | `Tema.JOGADOR[l]` | 1,2 | 26° | 7 | não |

A chave é tungstênio desde o começo: o violeta do 04 tingia o corpo de rosa e
as três peças viravam uma cor só (o estudo mediu). O contra-luz baixou de 3,0
para 1,2 pelo mesmo motivo.

### O plano dos prontos

Com todos forjados (a contagem de 1,6 s da G02 vira este plano):

- a câmera volta a `PROJECTION_PERSPECTIVE` com `fov` 16,1 (85 mm), y
  0,35, z 4,4 + 7,0, olhando y 1,58: baixa, de baixo para cima;
- o travelling anda em x de −3,456 a 3,456 em 8 s (4 compassos), `ENTRA_SAI`
  (o 05 deixa `RETA` só para o contador, os carretéis e o confete);
- no compasso k (0 a 3), o lugar k: `ass_p{k+1}` na TV, `Forja.sentir(k,
  "acerto")`, o nome dele em `Tema.bungee()` 46 px na cor `Tema.JOGADOR[k]`,
  centrado na tela, base y 980;
- no fim, o corte para o salão. Um ✕ de qualquer um corta no próximo
  tempo 1.

## O som

| quando | id | onde | volume e tom |
| --- | --- | --- | --- |
| o encaixe (a semicolcheia depois do toque) | `ui_peca` | TV `Som.tocar("ui_peca", null, -12.0, tom)` e `Som.no_controle(l, "ui_peca", 0.85)` | −12 dB; tom: cabeça 1,4983 (+7), superior 1,2599 (+4), inferior 1,0, item 0,7492 (−5) |
| o encaixe na arma ou amuleto | `ui_peca` a 0,7492 e o som do item | `_sentir_o_item(l)` (G03) | o da G03 |
| a pose da cabeça ou da raça | `pio_p{l+1}_{intervalo}` | `Som.pio(l, jogadores[l].modelo_i)` | o da G01 |
| a etiqueta reescreve o arquétipo | `fx_caneta` | TV `Som.tocar("fx_caneta", null, -6.0)` | −6 dB |
| o item entra em liga | `car_liga` | pelo `Visor` (G04): `visor.bater(l, "car_liga", <o centro da etiqueta>)`; sem a G04, só na TV, `Som.tocar("car_liga", null, -9.0)` (o mapa diz `tv` em `onde_toca`) | −9 dB |
| a build fica boa | `fx_caneta` na TV e `ass_p{l+1}` só no alto-falante do dono | `Som.no_controle(l, "ass_p%d" % (l + 1), 0.7)` | o acorde do lugar ainda não tem id: `ass_p{n}` é a reserva |
| △ | `ui_sorteio` (a roleta de 6 tiques) | TV −12 dB e o alto-falante do dono | — |
| □ trava ou destrava | `ui_trava` | TV −12 dB e o alto-falante do dono | — |
| cada martelada | `martelo` | como na G02 | −4 dB |
| a oitava | o pio, e `fx_caneta` no carimbo do nome | G02 | — |

O intervalo do pio vem da letra do personagem da cabeça: a `segunda`, b
`terca`, c `quarta`, d `quinta`, e `quinta_baixo`, f `oitava` (os 24
`pio_p*_*` já existem no estudo).

**O encanamento** (o mesmo da G02; quem chega primeiro faz): para
`ui_sorteio`, `ui_trava`, `car_liga` e `ass_p1` a `ass_p4`,
`python3 godot/estudos/direcao/som/gerar_sons.py --so <id> --fita leve --saida godot/assets/sons --sem-ogg`;
para `ass_p{n}`, a `receita` da linha do mapa:
`python3 godot/estudos/direcao/som/gerar_sons.py --so ass_p{n} --lugar {n} --fita cheia --saida godot/assets/sons --sem-ogg`; `"$GODOT" --headless --path godot --import --quit`;
`compress/mode=0` em cada `.wav.import`; no `mapa.csv`, `arquivo` =
`godot/assets/sons/<id>.wav` e `estado` = `no jogo`.

## O controle

| evento | vibração | gatilho | luz | alto-falante |
| --- | --- | --- | --- | --- |
| ▲ ▼ | `Forja.sentir(l, "toque")` | — | — | `tique` (G02) |
| o encaixe de cabeça, superior ou inferior | `Forja.sentir(l, "metal")` (0/0,45/40, da G02) | — | — | `ui_peca` |
| o encaixe do item | `_sentir_o_item(l)` (G03: o pulso de 80 ms e o gatilho do item) | o do item | — | `ui_peca` |
| a roleta (toques a menos de 250 ms) | `"metal"` a cada encaixe | — | — | `ui_peca` |
| △, cada uma das 6 trocas | `Forja.sentir(l, "toque", 30)` | — | — | `ui_sorteio` uma vez |
| □ trava | `Forja.sentir(l, "toque")` | — | — | `ui_trava` |
| o item entra em liga | `Forja.sentir(l, "acerto")` | — | — | `car_liga` |
| a oitava martelada | `Forja.sentir(l, "perfeito")` (G02) | — | — | o pio |
| o plano dos prontos, compasso k | `Forja.sentir(k, "acerto")` | — | — | — |

A barra de luz e as lâmpadas não marcam nada da montagem: são o lugar.

## O cavaleiro

### A peça se distingue (a regra do diretor de arte, arte/04)

A pintura é da G08 parte A; esta ficha monta as peças cortadas e chama a
pintura. O que tem que valer no cavaleiro montado:

- **O corpo não se tinge, e a pele não se clareia** (04, «A decisão: a pele
  não se clareia»; G08). O superior (tecido) fica entre 0,46 e 0,58 de
  luminância (L, OKLab) e o inferior (couro) entre 0,22 e 0,36, com 0,10 ou
  mais entre os dois. As duas medianas se medem só no pano: no Mini
  Characters, os pixels de `PELE_UV` ficam com o papel `personagem` (o
  `so_pano` da G08). O rosto humano não tem faixa: passa com |ΔL| de 0,10
  ou mais até o superior, ou pela gola acesa, se a cabeça não desce sobre
  ela (04, «O critério do rosto»: 93 de 144 pares pelo ΔL, 51 pela gola). A
  gola do friso fica no menor entre o topo do torso e o pescoço, y 0,343. A
  pele de raça fica entre 0,68 e 0,80.
- **A cabeça deixa o peito à vista:** 60 % ou mais da frente do superior que
  o resto do corpo deixa, em pé e sentado, em toda raça, a
  `ESCALA_CABECA` 1,30 (04, «A cabeça e o superior»; o pior caso é o golem
  no aceno, 63,2 %).
- **Croma** de no máximo 0,10 em cada peça (no código, teto 0,098); a
  distância até as quatro cores `Tema.JOGADOR` de pelo menos 0,08 em ΔE (no
  código, 0,085).
- **O néon do dono é só acento:** o contorno (1,6 na montagem, 2,4 no jogo),
  o friso do superior, a costura do inferior, a runa do item, o visor ou a
  rachadura da raça, e o aro a 0,25. No máximo 8 % da frente do corpo.
- **No encaixe**, o acento da peça nova sobe a 2,6 e volta a 1,6 em 250 ms,
  `SAI` (`p.acender_acento()`, da G08).

### O corte (uma vez, por script)

`godot/testes/cortar_pecas.gd` (`extends SceneTree`), o estudo
`godot/estudos/direcao/cavaleiro/cortar.gd` (82 linhas) portado:

- lê `res://assets/kenney/mini-characters/character-<p>.glb` para os 12
  personagens (`female-a` a `female-f`, `male-a` a `male-f`), e confere o orc
  (`res://assets/kenney/mini-dungeon-personagens/character-orc.glb`) só na
  contagem;
- os ossos do esqueleto de 7: `root` 0, `leg-left` 1, `leg-right` 2,
  `torso` 3, `arm-left` 4, `arm-right` 5, `head` 6. `OSSOS := {"superior":
  [3, 4, 5], "inferior": [1, 2]}`. A cabeça é a `head-mesh` inteira; o
  superior e o inferior saem da `body-mesh` pelo osso de maior peso de cada
  vértice do triângulo;
- grava, por personagem, em `godot/assets/kenney/mini-characters/pecas/`:
  `<p>-cabeca.res`, `<p>-superior.res`, `<p>-inferior.res` (as `ArrayMesh`),
  `<p>-pele.res` (o `Skin` da `body-mesh`) e `<p>-pele-cabeca.res` (o da
  `head-mesh`): 12 × 5 = 60 arquivos;
- imprime uma linha por personagem e para com código 1 se algum triângulo
  tem vértices em partes diferentes (`misturados > 0`), dizendo qual.

Rodar: `"$GODOT" --headless --path godot -s res://testes/cortar_pecas.gd`
(precisa do projeto: lê os `.glb` importados). A contagem esperada, em
triângulos:

| personagem | cabeça | superior | inferior |
| --- | --- | --- | --- |
| female-a | 298 | 370 | 208 |
| female-b | 340 | 194 | 208 |
| female-c | 312 | 236 | 184 |
| female-d | 322 | 267 | 208 |
| female-e | 322 | 226 | 208 |
| female-f | 288 | 292 | 208 |
| male-a | 273 | 210 | 240 |
| male-b | 288 | 194 | 208 |
| male-c | 299 | 286 | 208 |
| male-d | 221 | 282 | 208 |
| male-e | 288 | 214 | 208 |
| male-f | 213 | 280 | 208 |
| orc (só conferido) | 176 | 144 | 54 |

Misturados: 0 em todos.

### A montagem (`godot/scripts/mundo/montar.gd`, `class_name Montar extends RefCounted`)

```gdscript
const PECAS := "res://assets/kenney/mini-characters/pecas/%s-%s.res"
## Troca a head-mesh e a body-mesh do Mini Characters `m` por três peças
## cortadas: [cabeça, superior, inferior], cada uma o nome do personagem.
## Cria os MeshInstance3D "head", "body-sup" e "body-inf" no Skeleton3D, com
## o transform da body-mesh antiga (estudo, corpo.gd:16-40).
static func trocar(m: Node3D, pecas: Array) -> Skeleton3D
## O punho no espaço do esqueleto (estudo, montar.gd:180-211, copiado sem mudar número).
static func mao(esq: Skeleton3D, osso: String) -> Vector3
```

`trocar` carrega `PECAS % [pecas[0], "cabeca"]` com a pele
`PECAS % [pecas[0], "pele-cabeca"]`, `PECAS % [pecas[1], "superior"]` e
`PECAS % [pecas[2], "inferior"]` com `PECAS % [pecas[k], "pele"]`. O
esqueleto e as 32 animações são as do Mini Characters de `pecas[1]` (todos os
12 têm o mesmo esqueleto).

### O boneco (`godot/scripts/player.gd`)

- `BONECOS` (G08): os 12 do Mini Characters, na ordem `female-a` …
  `male-f`, cada um `{"nome": <o nome da cabeça em pecas.csv>, "arquivo":
  "mini-characters/character-<p>", "intervalo": <a tabela de O som>}`.
  `modelo_i` passa a ser o índice do personagem da **cabeça** (é o que o
  `Som.pio` lê).
- Campos novos: `var pecas := ["male-a", "male-a", "male-a"]` (o personagem
  de cabeça, superior, inferior), `var cadeira := ""` (`""` = pernas, ou um
  dos quatro de `regras.csv` `cadeiras`).
- `montar()`: instancia `BONECOS[índice de pecas[1]].arquivo`, chama
  `Montar.trocar(m, pecas)`, e a G08 pinta (`_vestir`) as malhas `head`,
  `body-sup`, `body-inf`, cada uma com `Pintura.preparar(mi, esq)`. As
  medidas do shader saem de duas peças diferentes:

```gdscript
## pintura.gd: o friso, a largura do torso e a frente de cima vêm do superior;
## a costura, a altura da perna e a frente de baixo, do inferior. Depois
## reaplica o teto de 8 % da frente (a regra da G08).
static func juntar_medidas(sup: Dictionary, inf: Dictionary) -> Dictionary
```

- A textura de todas: `res://assets/kenney/mini-characters/Textures/colormap.png`
  (o `meta` `"colormap"` que a G08 lê).
- `func trocar_peca(parte: int, personagem: String) -> void`: troca uma
  malha só (não remonta o esqueleto; a animação não reinicia).
- `func acender_parte(parte: String, k: float) -> void`: `"cabeca"`,
  `"superior"`, `"inferior"`, `"item"`, de 0 (apagada, o `acender(0)` da
  G08 só naquela malha) a 1.
- A cadeira: com `cadeira != ""`, a malha `res://assets/kenney/mini-characters/<cadeira>.glb`
  (G10) no osso `root`; a pose parada é `wheelchair-sit`.
- `cavaleiro()` passa a devolver `{"cabeca", "superior", "inferior",
  "cadeira", "item", "nome", "acabamento", "raca"}` (os três primeiros, o
  personagem; `raca` da G08). `vestir(c)` é o inverso; um dicionário antigo
  da G02 (com `"boneco"`) vira o pré-montado.

### Os stats (`godot/scripts/cavaleiro.gd`, `class_name Cavaleiro extends RefCounted`)

Os dados são os CSV do designer de sistemas. `scripts/dados_do_cavaleiro.py`
copia `docs/jogo/sistemas/{pecas,itens,stats,arquetipos,nomes,regras}.csv`
para `godot/dados/`, idênticos (o jogo não escreve número de stat no código).
`Cavaleiro` é o estudo `godot/estudos/direcao/cavaleiro/sistemas.gd` (109
linhas) portado, lendo `res://dados/`, mais o que o `conferir.py` faz:

```gdscript
const ST := ["peso", "passo", "folego", "faro"]
const NOME_ST := ["Peso", "Passo", "Fôlego", "Faro"]
const EMBLEMA := {"peso": "emb_bigorna", "passo": "emb_mola", "folego": "emb_brasa", "faro": "emb_lume"}
const OPOSTO := {"peso": "passo", "passo": "peso", "folego": "faro", "faro": "folego"}   ## de regras.csv
const PARTES := ["cabeca", "superior", "inferior"]
static var stats := [[3, 3, 3, 3], [3, 3, 3, 3], [3, 3, 3, 3], [3, 3, 3, 3]]   ## o forjado de cada lugar (3 = neutro)

static func tabela(nome: String) -> Array                     # as linhas do csv como Dictionary
static func peca(parte: String, personagem: String) -> Dictionary
static func item(id: String) -> Dictionary
## {"stats": [4], "perdidos": int, "arquetipo": Dictionary, "valido": bool, "principais": Array}
static func corpo(personagens: Array) -> Dictionary
static func no_corpo(id: String, st: Array) -> String         # "fora", "alcanca" ou "liga"
static func coerente(id: String, st: Array) -> bool
static func build_boa(c: Dictionary, id: String) -> bool
static func chaves(personagens: Array) -> Array               # [corpo, espírito], cada um -1 (esquerda), 0 (meio) ou 1 (direita)
static func pre_montado(lugar: int, ocupados: Dictionary, travado := {}) -> Dictionary
static func gancho(l: int, nome: String) -> float
```

| função | a conta (a mesma do `conferir.py`) |
| --- | --- |
| `corpo` | cada stat começa em `stat_base` 1; cada peça soma o seu perfil (+2 no principal, +1 no secundário); o que passa de `stat_teto` 5 se perde (`perdidos`). `valido`: nenhum par de principais opostos |
| o arquétipo | os dois stats maiores, desempate por mais peças com aquele principal e depois a ordem Peso, Passo, Fôlego, Faro; o par acha a linha de `arquetipos.csv` (`stat_a`, `stat_b`) |
| `no_corpo` | `"liga"` se todo stat ≥ `liga_<st>`; senão `"alcanca"` se todo stat ≥ `pede_<st>`; senão `"fora"` |
| `coerente` | todo stat que o item pede (> 0) está entre os dois maiores, desempate só pela ordem (sem contar peças) |
| `build_boa` | `perdidos == 0`, o item `"liga"` e `coerente` |
| `chaves` | corpo: Peso entre os principais → −1, Passo → 1, nenhum → 0; espírito: Fôlego → −1, Faro → 1, nenhum → 0 |
| `gancho` | a linha de `stats.csv` com `gancho == nome`: `neutro + por_ponto × (stats[l][stat] − 3)`; com `stats_no_relampago` `nao` e a partida no Relâmpago, `neutro` |

**O pré-montado** (`docs/jogo/sistemas/README.md`, «O pré-montado»): um
`RandomNumberGenerator` com `seed = Forja.semente * 31 + lugar`. Os
candidatos são os 756 corpos válidos com cada item; vale o primeiro, numa
ordem embaralhada pelo `rng`, que cumpre:

1. o corpo passa nos opostos e não perde ponto;
2. o arquétipo não é raro e nenhum outro lugar presente (`ocupados`: lugar →
   cavaleiro) tem o mesmo;
3. a cabeça não está com ninguém (`cabeca_unica_na_mesa` `sim`);
4. o item é `coerente`, `"alcanca"` (fora da liga), e uma troca de uma peça
   põe ele em `"liga"` com o corpo novo ainda válido nos opostos (a conta
   `uma_troca_da_liga` do `conferir.py`; o corpo novo pode perder ponto);
5. o nome é um dos seis do arquétipo em `nomes.csv` que ninguém usa; sem
   nenhum livre, qualquer um dos 24 livre.

Devolve `{"pecas", "item", "nome", "troca": {"parte": int, "personagem":
String}}` (a troca do passo 4, que o robô usa). Com `travado`, as linhas
travadas ficam fixas; sem candidato, larga o critério 4, depois o 2, depois
o 1, e nunca larga os opostos nem a cabeça livre.

`item_unico_na_mesa` fica `nao` (é um interruptor de `regras.csv`; com `sim`,
◀▶ também pula o item de outro lugar).

**O que fica na tela, por cavaleiro:** os quatro VUs, o arquétipo na
etiqueta, as duas chaves na placa, o emblema de cada peça na linha. Nenhum
número de gancho.

## As reações

Não se aplica: a montagem não dispara adesivo nem carimbo de reação (o
`car_liga` é carimbo de jogo, pelo `Visor` da G04).

## A diversão

**O momento:** a pessoa aperta ▶ na linha Inferior, a bota nova cai na
semicolcheia, o controle dá o tranco de metal, oito faíscas saem da junta na
cor dela, o cavaleiro chuta para testar a bota e, na batida seguinte, o item
entra em liga com duas marteladas em quinta. Tudo em 1 s. **Como se
confere:**

1. A prova do jogo mede o encaixe: a peça muda no quadro da semicolcheia
   seguinte (até 125 ms + 1 quadro depois do toque), e `car_liga` sai uma
   batida depois.
2. A prova visual tem a sequência do encaixe nos instantes 0, 125, 190, 375,
   500 e 1000 ms ao lado de `docs/imagens/direcao/20_encaixe.jpg`.
3. Na noite de teste: a primeira montagem leva até 90 s; o jogador do time
   anota quantos fizeram uma troca a mais «só para ver o chute».

### O encaixe (uma troca, do toque ao descanso)

As curvas são as do [05](../arte/05-movimento.md): `SAI` é `TRANS_CUBIC` com
`EASE_OUT` (o que chega); `ENTRA` é `TRANS_CUBIC` com `EASE_IN` (o que vai
embora); `ENTRA_SAI` é `TRANS_SINE` com `EASE_IN_OUT` (a câmera, a luz);
`MOLA` é `TRANS_BACK` com `EASE_OUT`, passando 4 % do alvo; `RETA` é
`TRANS_LINEAR`.

| quando | o que acontece |
| --- | --- |
| o toque (0 ms) | a seta apertada cresce a 1,2 e volta (4 quadros, `MOLA`); a peça velha afunda a 0,92 (2 quadros, `ENTRA`) |
| **o encaixe**: `Ritmo.t_da_batida(ceil(Ritmo.batida() * 4.0) / 4.0)`, a semicolcheia seguinte (0 a 125 ms) | `trocar_peca`; a peça nova cai de +0,06 m e vai da escala 0,9 a 1,0 (`MOLA`, 120 ms); `ui_peca` no tom da parte; `"metal"` (no item, `_sentir_o_item`); `Efeitos.faiscas(salao, <a junta>, Tema.JOGADOR[l], 8, 2.4)`; `p.acender_acento()`; o VU anda um segmento a cada 30 ms |
| encaixe + 250 ms, se nenhum toque novo | a pose e o giro (a tabela abaixo); na cabeça ou na raça, o pio |
| a batida seguinte | se o arquétipo mudou: a etiqueta vira (escala y 1 → 0 → 1, 180 ms, `ENTRA_SAI`) e `fx_caneta`; se o item entrou em liga: `car_liga` e a marca da liga no VU acende; se a build ficou boa: os dois sublinhados e `ass_p{l+1}` no alto-falante |
| o descanso | a pose volta ao `idle` em 120 ms |

**A junta** de cada parte: cabeça `y 1.25`, superior `y 0.95`, inferior
`y 0.45`, item `Montar.mao(esq, osso do item)`; somadas a `montagem[l]`.

**A roleta:** toques com menos de 250 ms entre eles fazem só o encaixe, com
4 faíscas em vez de 8. A pose, o giro e o pio esperam 250 ms parados numa
peça.

**O sorteio (△):** 6 trocas, uma por semicolcheia, das linhas não
travadas; `ui_sorteio` uma vez; `Forja.sentir(l, "toque", 30)` a cada uma; a
última em `MOLA`; depois, o aceno e o pio da cabeça.

### A pose de cada linha

| linha | animação (Mini Characters) | o giro da plataforma |
| --- | --- | --- |
| Cabeça e raça | `emote-yes` | 25° para o centro da tela |
| Superior | `holding-both` | 25° |
| Inferior | `attack-kick-right`; na cadeira, `wheelchair-move-forward` e o cavaleiro anda 0,1 m para a frente e volta | nenhum |
| Arma | `attack-melee-right` (o escudo: `attack-melee-left`) | nenhum |
| Amuleto | `interact-right` | 25° |
| Nome | nenhuma | nenhum |

O giro é do cavaleiro sobre o anel, nunca da câmera: `rotation.y` de 0 a
`deg_to_rad(25) × sinal` (o sinal leva para o centro: −1 nos lugares 0 e 1,
+1 nos 2 e 3), ida 120 ms `SAI`, fica 260 ms, volta 120 ms `ENTRA_SAI`.

### A forja, parte por parte

O ✕ da G02 continua sendo o relógio da calibração. O que cada martelada
acende (`acender_parte`), de 0 a 1:

| martelada | acende |
| --- | --- |
| 1 e 2 | a cabeça: 0,5 e 1 |
| 3 e 4 | o superior |
| 5 e 6 | o inferior |
| 7 | a arma ou o amuleto |
| 8 | o nome: a caneta escreve na etiqueta (`fx_caneta`) |

Cada martelada pisca uma `OmniLight3D` `Tema.TUNGSTENIO` na altura da parte
(a junta), energia 1,2 → 0 em 250 ms, `SAI`, alcance 1,2.

**Na oitava** (o carimbo do nome):

- o cavaleiro dá uma volta inteira, 360° em 2 s (1 compasso), `ENTRA_SAI`;
- o nome na placa pousa como carimbo: escala 1,35 → 1,0 em 80 ms, `MOLA`,
  inclinado −4°, com a chapa `Tema.FITA` deslocada 3 px;
- «Forjado» em `Tema.vt()` 30 px, `Tema.ETIQUETA`, embaixo do nome, na
  batida seguinte;
- a parada de 2 quadros só no cavaleiro (`Opcoes.parada(2)` da G16; sem a
  G16, 2);
- a chave da coluna sobe de 3,2 a 5,5 em 1 compasso;
- `Itens.em_liga[l] = Cavaleiro.no_corpo(item, stats) == "liga"`,
  `Cavaleiro.stats[l] = corpo.stats`;
- o evento: `Forja.evento("cavaleiro", l + 1, {"cabeca", "superior",
  "inferior", "cadeira", "item", "nome", "raca", "stats", "arquetipo",
  "liga", "boa", "perdidos"})`.

### Com o movimento reduzido

`Opcoes.reduzido()` (G16; sem a G16, `not Opcoes.tremor`): o giro e o 360°
somem; a peça nova e o carimbo chegam por opacidade em 4 quadros; 4
faíscas. A pose fica. O som, o pulso e o pio não mudam.

### O idle e o forjado

O idle segue a batida (G08). Quem já forjou faz `emote-yes` no tempo 1 de
cada compasso, a 0,5 de mistura.

## O estado de hoje

- A G02 entrega: `TelaLobby` com `LINHAS` de três (`BONECO` 0, `ITEM` 1,
  `NOME` 2), as etapas `EDITANDO`/`FORJANDO`/`FORJADO`/`GUARDADO`,
  `martelar`, `_forjou`, `robo`, `mediana`, a coluna `CartaoJogador` de
  432 × 1080 em `x = 96 + 432·l`, as bigornas em `salao.gd`, o cavaleiro
  guardado em `Opcoes.cavaleiro`.
- `godot/scripts/player.gd`: `MODELOS` (14) com o humano e o orc;
  `montar()` (60) instancia o boneco inteiro.
- `godot/scripts/main.gd`: `_mostrar` (215-227) põe os bonecos em
  `salao.pedestais[l]`; `_pose_da_camera` (925), ramo `"lobby"` (932) em
  `[Vector3(0, 2.9, 14.2), Vector3(0, 0.55, 4.4)]`.
- O estudo tem tudo medido e desenhado:
  - `godot/estudos/direcao/cavaleiro/`: `cortar.gd` (o corte),
    `corpo.gd` (a troca), `montar.gd` (o cavaleiro inteiro, a mão),
    `sistemas.gd` (os stats), `acento.gd`, `racas.gd`;
  - `godot/estudos/direcao/quadros/10_montagem.gd` (a tela) e
    `20_encaixe.gd` (o encaixe), com as fotos
    `docs/imagens/direcao/10_montagem.jpg` e `20_encaixe.jpg`;
  - `godot/estudos/direcao/hud.gd:146-157` (o VU).
- `docs/jogo/sistemas/conferir.py` confere os CSV e imprime as contas
  (Provas).

## O alvo

### A coluna (`CartaoJogador._draw()`)

`x0 = 10`, `w = 412` dentro do cartão. Tudo em `_draw()`, sem `Label`.

| y (px) | o quê | como |
| --- | --- | --- |
| 60 a 150 | a placa | `Desenho.placa(self, Rect2(x0, 60, w, 90), Tema.JOGADOR[l] if <linha escolhida> else Color(0,0,0,0))` |
| | «P1» | `Tema.bungee()` 40, `Tema.JOGADOR[l]`, em (x0 + 18, base 108) |
| | as lâmpadas | `Desenho.lampadas(self, Vector2(x0 + 20, 124), l)` |
| | o nome | `Tema.archivo(600)` 32, `Tema.ETIQUETA`, à direita em x0 + w − 20, base 100 |
| | «Forjado» | `Tema.vt()` 30, `Tema.ETIQUETA`, à direita, base 140, na batida depois da oitava |
| | as duas chaves | entre x0 + 130 e x0 + 276, y 112 a 132 (abaixo) |
| 160 a 600 | o cavaleiro em 3D | nada desenhado |
| 608 a 652 | a etiqueta | `Desenho.etiqueta(self, Rect2(x0 + 26, 608, w − 52, 44), Tema.JOGADOR[l])`; «nome · arquétipo» em `Tema.marcador()` 30, `Tema.TINTA`, centrado; a tira de 8 px na cor do lugar à esquerda (estudo, `10_montagem.gd:120-125`) |
| | a build boa | dois traços de caneta 2,5 px em `Tema.TINTA` sob o texto, a 7 e 13 px da base da etiqueta (estudo, 126-133) |
| 660 + 38·k | as cinco linhas | `Rect2(x0, 660 + 38·k, w, 36)` (de 660 a 848) |
| | a escolhida | fundo `Tema.CASCO_ALTO`, borda 3 px `Tema.JOGADOR[l]`, raio 6 |
| | o rótulo | `Tema.archivo(600)` 30 em x0 + 12; `Tema.MUDO` (`Tema.ETIQUETA` na escolhida). Na cabeça, com raça ≠ Humana, o nome da raça |
| | o valor | «◀» em x0 + 136 e «▶» à direita em x0 + w − 12, `Tema.MUDO`; o nome da peça (`pecas.csv` `nome`) centrado entre x0 + 158 e x0 + w − 34, `Tema.archivo(500)` 30, `Tema.ETIQUETA`. No inferior com cadeira, «Cadeira» |
| | o emblema | `Glifo.desenhar(self, Cavaleiro.EMBLEMA[principal], Rect2(<antes do nome − 30>, y + 7, 24, 24), Tema.ETIQUETA)`; o do secundário, 16 px, depois do nome, `Tema.MUDO` |
| | o cadeado | a linha travada: o `_cadeado` do estudo (`10_montagem.gd:179-185`) em (x0 + 134, y + 6) |
| linha + 38 | a fita das 12 | embaixo da linha escolhida de cabeça, superior ou inferior, por 1,5 s depois do último ◀▶: `Rect2(x0, y + 38, w, 52)` sobre as linhas de baixo; a marca atual na cor do lugar; as riscadas (opostos) em `Tema.CASCO` com o risco `Tema.GRAFITE` 4 px; na cabeça, as de outro lugar na cor dele a 35 % com «P#» em `Tema.vt()` 30 (estudo, `_fita_das_cabecas`, 188-215, que vale para as três linhas) |
| 852 + 26·k | os quatro VUs (de 852 a 956) | o rótulo `Cavaleiro.NOME_ST[k]` em `Tema.vt()` 30, `Tema.MUDO`, em x0 + 12, base y + 23; `Desenho.vu(self, Rect2(x0 + 136, y + 3, w − 190, 20), 5, stats[k], Tema.JOGADOR[l])`; o número em `Tema.vt()` 30, `Tema.ETIQUETA`, em r.end.x + 12, base y + 23 |
| | as marcas do item | na linha do item: duas marcas de 3 px em `Tema.ETIQUETA` no VU de cada stat que o item pede (o `pede` e o `liga`), acima e abaixo 6 px (estudo, 165-175); a marca da liga acende em `Tema.JOGADOR[l]` com o item em liga |
| | a prévia | do encaixe até a pose (250 ms parada numa peça), os segmentos que a troca mudou piscam em `Tema.ETIQUETA` a cada tempo; na roleta, piscam enquanto ela gira |
| base 1006 | as dicas | uma vez para a tela, pela `TelaLobby`: `Desenho.dica(self, Vector2(196 + 400·k, 1006), …)` (o `pos` é a base da letra, como no `Glifo.dica` de hoje: o quadrado de 52 px vai de y 963 a 1015) com `cruz` «Botão ✕ (Forjar)», `triangulo` «Botão △ (Sortear)», `quadrado` «Botão □ (Travar)», `esquerda` «Botão ◀ ▶ (Trocar)» |

**Por que a coluna aperta abaixo da etiqueta:** a área segura do 02 vai de y
60 a 1020, e a checagem da F09 reprova texto além dela. O 04 e o estudo
(`10_montagem.jpg`) põem as linhas a 40 px, os VUs de 870 a 1010 e as dicas
abaixo de 1020: aqui as linhas têm 38 px, os VUs 26 px e as dicas sobem a
base 1006. Os 8 quadrados das marteladas da G02 (y 880) saem da coluna: a
forja mostra o andamento acendendo as partes (A forja, parte por parte).

**As duas chaves** (CORPO e ESPÍRITO), na placa, sem palavra (a letra mínima
de 30 px não cabe ali): cada uma é o emblema da esquerda (16 px) | um trilho
de 32 × 8 em `Tema.GRAFITE` com a alavanca de 10 × 20 em `Tema.ETIQUETA` na
esquerda, no meio ou na direita (`Cavaleiro.chaves`) | o emblema da direita
(16 px). A de cima: Bigorna | Mola; a de baixo: Brasa | Lume.

**`Desenho.placa`, `lampadas` e `dica`** são da G11 (assinaturas em
`G11-a-interface-com-o-ui-pack.md`, tabela de «O alvo»); **`Desenho.vu`** é da
G04 (igual a `hud.gd:146-157` do estudo). A primeira ficha que chegar cria,
com essas assinaturas; quem chega depois usa.

### Os emblemas (`godot/scripts/ui/glifo.gd`, grade de 32, traço `t`)

| nome | desenho |
| --- | --- |
| `emb_bigorna` | `ci.draw_colored_polygon` com [(4,12), (28,12), (22,18), (22,22), (26,26), (6,26), (10,22), (10,18)] |
| `emb_mola` | `ci.draw_polyline` por (8,6), (24,10), (8,14), (24,18), (8,22), (24,26), largura `t` |
| `emb_brasa` | `_contorno` por [(16,4), (24,16), (22,24), (16,28), (10,24), (8,16)] e a linha (16,14)–(16,24) |
| `emb_lume` | `ci.draw_arc(p.call(16,16), 5 * k, 0, TAU, 16, cor, t, true)` e quatro raios de 9 a 13 do centro, a 0°, 90°, 180° e 270° |

### `TelaLobby` (o que muda sobre a G02)

```gdscript
const CABECA := 0
const SUPERIOR := 1
const INFERIOR := 2
const ITEM := 3
const NOME := 4
const LINHAS := ["Cabeça", "Superior", "Inferior", "Arma ou amuleto", "Nome"]
const MAX_TRAVAS := 4               ## as quatro primeiras linhas travam; o nome, não
const ROLETA_S := 0.25
var travada := [{}, {}, {}, {}]     ## linha → true
var corpo := [{}, {}, {}, {}]       ## Cavaleiro.corpo() de cada lugar
var _encaixe := [[], [], [], []]    ## {t, parte, valor} esperando a semicolcheia
var _ultimo_toque := [-1.0, -1.0, -1.0, -1.0]
var _pose := [-1.0, -1.0, -1.0, -1.0]   ## quando a pose do lugar dispara (t_musica)
var _na_batida := [{}, {}, {}, {}]      ## o que sai na batida seguinte: arquetipo, liga, boa
```

- `BONECO` sai (as três peças ficam em `jogadores[l].pecas`).
- `entrou(l)` sem guardado: `Cavaleiro.pre_montado(l, <os outros ocupados>)`
  e `jogadores[l].vestir(...)`.
- O ✕ em qualquer linha forja (G02). As marteladas chamam também
  `jogadores[l].acender_parte(...)` e piscam a luz da parte.
- A troca vira um pedido na fila `_encaixe[l]`, servido por `quadro()` no
  primeiro quadro com `Ritmo.t_musica() >= t do encaixe`.
- O nome segue a lista da G02 até a G09 (o teclado).

### O robô

Na G02, o robô aperta ✕ e martela. Aqui, antes da forja, o P1 faz **uma**
troca: a do pré-montado (`troca.parte`, `troca.personagem`): ▼ até a linha,
▶ até o personagem (pulando os riscados, como uma pessoa), espera a batida
seguinte (o `car_liga`), e só então ✕. Os outros três forjam o pré-montado
como estão. Tudo por `Forja.robo_apertar` em `TelaLobby.robo(l, dt)`, a cada
0,25 s.

### O registro e o 13

`docs/jogo/13-arquitetura.md`, na linha `cavaleiro` do registro v2: os campos
passam a `cabeca`, `superior`, `inferior`, `cadeira`, `item`, `nome`,
`raca`, `stats`, `arquetipo`, `liga`, `boa`, `perdidos`.

### O texto (`godot/scripts/traducoes.gd`)

| português | inglês |
| --- | --- |
| Cabeça / Superior / Inferior / Cadeira | Head / Upper / Lower / Wheelchair |
| Peso / Passo / Fôlego / Faro | Weight / Stride / Breath / Scent |
| Travar / Botão □ (Travar) | Lock / □ Button (Lock) |
| Muralha / Torre / Relâmpago / Corrente / Aríete / Eco | Bulwark / Tower / Lightning / Torrent / Ram / Echo |
| os 36 nomes de peça de `pecas.csv` | um por um, na mesma tabela |

## Passos

Rodar `bash tests/prova_do_jogo.sh` depois dos passos 3, 6 e 9.

1. **Os dados:** `scripts/dados_do_cavaleiro.py`; rodar; `python3 docs/jogo/sistemas/conferir.py`.
2. **O corte:** `scripts/cortar_pecas.gd`; rodar; a tabela de contagem bate.
3. **`Montar` e o boneco:** `montar.gd`, os campos e as funções de `player.gd`,
   `Pintura.juntar_medidas`. Um cavaleiro de três peças anda no salão.
4. **`Cavaleiro`:** as funções e o pré-montado; a prova contra o `conferir.py`.
5. **Os sons e os emblemas.**
6. **A coluna:** `CartaoJogador._draw()` inteira; a câmera e as luzes.
7. **O encaixe:** a fila, a semicolcheia, a pose, o giro, a batida seguinte.
8. **A forja parte por parte** e o carimbo; `Itens.em_liga`; o evento.
9. **O robô, o plano dos prontos, o texto, as provas e a captura.**

## Armadilhas

- **A cabeça humana não sai na raça:** a G08 a esconde e põe a da raça; a
  `head` desta ficha continua no esqueleto.
- **O esqueleto é do superior:** `trocar_peca` da cabeça ou do inferior não
  remonta; do superior também não (as malhas compartilham o esqueleto do
  personagem instanciado, e os 12 têm o mesmo esqueleto).
- **A semicolcheia pode cair no mesmo quadro do toque** (0 ms): o encaixe
  sai no quadro seguinte, nunca no mesmo do ◀▶.
- **Dois toques antes do encaixe:** só o último vale (a fila guarda um por
  lugar e por linha).
- **O FRUSTUM fica preso:** sair do lobby sem `_lente_da_montagem(false)`
  deixa o salão torto.
- **A prova da G02** usa `TelaLobby.ITEM` (agora 3) e ◀▶ no boneco: atualize
  como em Provas.
- **Nada abaixo de 30 px**, nada sem `Traducoes`.

## Não fazer

- As raças, a pintura, o shader e o acento (G08).
- O teclado do nome (G09). O acabamento e a coleção (G06). A gaveta de
  cavaleiros entre noites (`gaveta_maximo`, outra ficha).
- A mecânica e a peça 3D do item (G03).
- Mudar número de stat, de gancho ou de critério: é dos CSV do designer de
  sistemas; o jogo só lê.
- Mexer na câmera para um lugar só (o giro é da plataforma).

## Pronto quando

Os quatro montam um cavaleiro de três personagens diferentes, cada peça na
cor dela e o néon do lugar só no acento; cada troca encaixa na semicolcheia
com o som, o pulso, as faíscas e a pose em 1 s; os VUs e o arquétipo mudam
com as peças; a forja acende parte por parte nas 8 batidas e calibra; e a
tela bate com `docs/imagens/direcao/10_montagem.jpg`.

E só fecha com `bash tests/prova_visual.sh` passando e a prancha olhada; a
aparência só se aprova na máquina do André, com placa de vídeo, sem
`--fixed-fps`.

## Provas

**Na sessão:**

- `"$GODOT" --headless --path godot -s res://testes/cortar_pecas.gd`:
  a tabela de contagem, misturados 0, código 0.
- `python3 docs/jogo/sistemas/conferir.py`: 756 válidos; perdidos
  `{0: 432, 1: 216, 2: 108}`; Torre 176, Muralha 176, Relâmpago 170,
  Corrente 170, Aríete 38, Eco 26; itens por corpo `{1: 96, 2: 380, 3: 280}`;
  build boa possível 432; sorteáveis 270 (Muralha 81, Torre 63, Relâmpago 63,
  Corrente 63).
- `bash tests/prova_do_jogo.sh`, com estes blocos em
  `godot/testes/prova_do_jogo.gd`:

```gdscript
func _prova_do_cavaleiro() -> void:
	# a mesma conta do conferir.py, pelo jogo
	var validos := 0
	var arq := {}
	var sorteaveis := 0
	var P := ["female-a", "female-b", "female-c", "female-d", "female-e", "female-f",
		"male-a", "male-b", "male-c", "male-d", "male-e", "male-f"]
	for a in P:
		for b in P:
			for c in P:
				var k := Cavaleiro.corpo([a, b, c])
				if not k.valido:
					continue
				validos += 1
				arq[k.arquetipo.nome] = arq.get(k.arquetipo.nome, 0) + 1
	_esperar(validos == 756, "756 corpos válidos (%d)" % validos)
	_esperar(arq.get("Torre", 0) == 176 and arq.get("Muralha", 0) == 176 and arq.get("Relâmpago", 0) == 170
		and arq.get("Corrente", 0) == 170 and arq.get("Aríete", 0) == 38 and arq.get("Eco", 0) == 26, "os arquétipos (%s)" % [arq])
	var k := Cavaleiro.corpo(["male-c", "female-f", "male-a"])
	_esperar(k.stats == [4, 2, 5, 2] and k.arquetipo.nome == "Muralha", "male-c, female-f, male-a: Muralha [4, 2, 5, 2]")
	_esperar(Cavaleiro.no_corpo("martelo", k.stats) == "alcanca", "o Martelo alcança, fora da liga, nesse corpo")
	_esperar(is_equal_approx(Cavaleiro.gancho(0, "empurrao"), 1.0), "sem forja, o gancho é o neutro")
```

  E no percurso, no lugar do bloco da G02: os quatro nascem com cabeças
  diferentes e arquétipos diferentes; ◀▶ na linha Cabeça do P2 muda
  `jogadores[1].pecas[0]` e não o do P1; ▼▼▼ leva o P3 à linha do item
  (`TelaLobby.ITEM`); a troca encaixa no quadro em que `Ritmo.t_musica()`
  passa da semicolcheia seguinte (a malha `"head"` muda nesse quadro, não
  antes); com o robô, o P1 faz a troca do pré-montado e `Itens.em_liga[0]`
  fica `true` depois da forja; as linhas `calibracao` da G02 continuam 4.
- G08 `_prova_da_peca()` roda sobre os quatro cavaleiros montados (as faixas
  de L, o croma, o ΔE e os 8 %) e passa.

**A prova visual (F09):** `bash tests/prova_visual.sh`; a prancha da
montagem ao lado de `docs/imagens/direcao/10_montagem.jpg` e a sequência do
encaixe (0, 125, 190, 375, 500, 1000 ms) ao lado de `20_encaixe.jpg`.

**A medida das peças:** `"$GODOT" --headless --path godot -s res://estudos/direcao/medir_pecas.gd`
grava `docs/jogo/arte/dados/pecas_medidas.csv`; o que mudar em relação ao
commitado vai no diário.

**A captura:** o roteiro das telas ganha `["aperta", 1, Forja.DIREITA]` na
linha Cabeça e `["espera", 60], ["foto", "montagem_encaixe"]`.

## Para o André (local)

1. `bash tests/prova_visual.sh` sem `--fixed-fps`: as pranchas da montagem e
   do encaixe; olhar se o superior e o inferior se distinguem a 64 px e em
   cinza.
2. Quatro DualSense: cada um troca 10 peças em 10 s (a roleta) e para numa;
   o pulso de metal e o `ui_peca` saem do controle certo.
3. Uma pessoa que nunca viu monta o primeiro cavaleiro: o tempo até o ✕ (até
   90 s) e a frase dela, no diário.
4. Uma build boa de propósito: os sublinhados e o acorde no alto-falante.

## Ao terminar

No [quadro](README.md), G13 **feito** com o commit e o gasto. Commit sugerido
(sem trailer):

```
feat(montagem): o cavaleiro montado com três peças, o encaixe na batida e os stats dos dados
```

## O que foi feito (leva 1, as-telas)

**A medida antes:** cada lugar escolhia um de dois bonecos inteiros (o Humano e o Orc), pintados por cima com a cor
do lugar; a linha `BONECO` trocava o corpo todo. Os 12 do Mini Characters não estavam no jogo como peças, e nada lia
os CSV do designer de sistemas.

**A ficha cresceu além de um bloco:** entrou o miolo do «Pronto quando» (três personagens, a peça na cor dela, a troca
na semicolcheia com o som, o pulso, as faíscas e a pose, os VUs e o arquétipo que mudam, a forja parte por parte). A
cena em volta virou a [G13b](G13b-a-montagem-em-cena.md): a câmera de 50 mm, os anéis, as luzes, o plano dos
prontos, o giro, a roleta do △, a trava do □, os emblemas, as chaves, a fita das 12, as marcas do item, os sublinhados,
a cadeira e a raça. Sem a G13b, a tela ainda não bate com `10_montagem.jpg`.

**O que entrou:**

- **Os dados:** `scripts/dados_do_cavaleiro.py` copia as seis tabelas de `docs/jogo/sistemas/` para `godot/dados/`
  (com `.csv.import` em `keep`). O `conferir.py` bate: 756 válidos, perdidos `{0: 432, 1: 216, 2: 108}`, Torre 176,
  Muralha 176, Relâmpago 170, Corrente 170, Aríete 38, Eco 26, itens por corpo `{1: 96, 2: 380, 3: 280}`, build boa 432,
  sorteáveis 270.
- **O corte:** `godot/testes/cortar_pecas.gd` grava as 60 peças (3 malhas e 2 peles × 12) em
  `assets/kenney/mini-characters/pecas/`; a tabela de contagem sai com misturados 0 nos 12 e no orc.
- **`Montar`** (`mundo/montar.gd`): `trocar`, `parte` e `mao`. **`Cavaleiro`** (`cavaleiro.gd`): `corpo`, `no_corpo`,
  `coerente`, `build_boa`, `chaves`, `alcancaveis`, `troca_da_liga`, `gancho` e `pre_montado`, só com números dos CSV.
- **O boneco** (`player.gd`, só acréscimos): os 12 em `BONECOS` depois do Orc, `pecas`, `vestir_pecas`, `trocar_peca`,
  `acender_parte`, `indice_do_personagem`; `Pintura.juntar_medidas` tira o friso do superior e a costura do inferior e
  reaplica os 8 %.
- **A montagem** (`tela_lobby.gd`, `cartao_jogador.gd`): as cinco linhas (Cabeça, Superior, Inferior, Arma ou amuleto,
  Nome); o pré-montado ao entrar; ◀▶ pede o encaixe na semicolcheia seguinte (pulando os riscados e as cabeças de
  outro lugar); o encaixe toca `ui_peca` no tom da parte, sente `"metal"`, solta 8 faíscas (4 na roleta) e sobe o
  acento; a pose 250 ms depois; na batida seguinte, `fx_caneta` se o arquétipo mudou, «LIGA!» pelo `Visor` da G04
  logo acima da etiqueta da coluna se o item entrou em liga, `fx_caneta` se a build ficou boa; as 8 marteladas acendem
  cabeça, superior, inferior e item, com a luz de tungstênio na junta; a forja grava `Cavaleiro.stats`,
  `Itens.em_liga` e o evento com `stats`, `arquetipo`, `liga`, `boa` e `perdidos`. A coluna: a etiqueta «nome ·
  arquétipo», as cinco linhas com o nome da peça e os quatro VUs. O robô do P1 faz a troca do pré-montado antes de
  forjar.
- **O texto:** os 36 nomes de peça, as partes, os stats e os arquétipos em inglês. **O 13:** a linha `cavaleiro` do
  registro com os campos novos.

**As provas:** `cortar_pecas.gd` (misturados 0); `conferir.py` (os números acima); `bash tests/prova_do_jogo.sh` com
`_prova_do_cavaleiro` (a conta do `conferir.py` pelo jogo, os quatro pré-montados válidos e distintos em menos de 2 s, o
boneco de três peças, os 8 %, o friso e a costura de cada peça, `trocar_peca` só na cabeça, `acender_parte`),
`_prova_do_encaixe` (o registro do encaixe servido: depois do quadro do toque e na semicolcheia seguinte), o percurso
da G02 nas linhas novas, o guardado antigo que vira o pré-montado, o robô que faz a troca e bate o «LIGA!», os stats
gravados na forja e a G08 `_prova_da_peca` sobre os quatro montados. Os únicos FAIL foram o do kit («kit P2: otimo em N
de 12 notas», conhecido) e, numa das duas passadas do servidor, «longe do portão, nenhuma dica» (o salão, que esta
ficha não toca; passou na outra). Os portões verdes.

**As mordidas:** com o encaixe servido no quadro do toque, «a cabeça do P2 encaixa na semicolcheia seguinte ao toque,
nunca antes» reprova (agora 2,607 < t 2,625); com o `juntar_medidas` tirando tudo do superior, «o friso vem do superior
e a costura e a perna, do inferior» reprova. Os dois restaurados e verdes.

**Escolhas a validar por ela** (a ficha não decidia):

- O Humano e o Orc continuam em `BONECOS` 0 e 1 (os 12 começam em `PRIMEIRO_PERSONAGEM` 2), e `montar()` ainda os põe
  até a montagem vestir as peças.
- Um cavaleiro guardado no formato antigo (`boneco`) vira o pré-montado do lugar, mantendo o item e o nome.
- O item que o corpo novo não alcança passa ao próximo que alcança (a ficha), e o robô volta ao item do pré-montado
  pela linha do item, como uma pessoa faria.
- Os 36 nomes de peça em inglês (Black bun, Bermuda shorts…).
- O △ de hoje é um sorteio válido e instantâneo; a roleta de 6 trocas é da G13b.
- `Itens.em_liga` passa a ser escrito na forja: as salas que leem a liga (G03) veem o valor da montagem.
- Sem campo `raca` no evento até a G08 parte B; `cadeira` vai vazio.
- Os quatro VUs em duas colunas de duas linhas (a ficha e a foto pedem quatro linhas, que não cabem com texto de 30 px
  acima das dicas), e «LIGA!» logo acima da etiqueta, não no centro dela.

**A prova visual** (`PASSADAS=fixa PARTIDAS="1 6"`, a 6 com o texto grande): a prancha da montagem mostra a etiqueta,
as cinco linhas com o nome da peça e os VUs; a câmera ainda é a da G02 (G13b). A régua achou dois defeitos desta ficha,
curados no mesmo bloco:

- **Os quatro VUs encavalavam** («Peso» com «Passo», «3» com «2», 36 e 110 vezes): a tabela da ficha punha texto de
  30 px em linhas de 26 px. Quatro linhas de 30 px esbarram nas dicas (o quadrado começa em y 963), e no texto grande
  ficariam com 34 px. Os VUs passaram para duas colunas de duas linhas, de 852 a 924, que cabem nas duas escalas. A
  prova nova «a coluna do P2: os quatro VUs aparecem e nenhum texto encosta em outro» reprova com as quatro linhas de
  26 px.
- **«LIGA!» cobria a etiqueta** («Rebite · Muralha» com «LIGA!»): o carimbo saía no centro da etiqueta, como a ficha
  pedia, e escondia o arquétipo que acabou de mudar. Agora sai logo acima dela (y 568).

Depois da cura, a mesma passada: a partida 1 caiu de 234 achados para 10, e a 6, de 288 para 26, nenhum deles da
montagem; as duas pranchas da montagem mostram os VUs em duas colunas, nas duas escalas.

As outras reprovações das duas partidas não são da montagem e já têm ficha: o título, o cartão do resultado, o placar e
o contraste dos carimbos do julgamento («Ressonância!», «Afinado», e o «LIGA!» com 1,3:1 sobre a etiqueta, que agora
sai sobre a cena) na [G04c](G04c-o-texto-grande-fora-do-hud.md); a tela parada na F09b e na F09d. «Pronto» com 2,1:1
(00:33, só na primeira passada) é a tecla apagada do teclado do nome (G09), em `MUDO` sobre `CASCO`, e fica anotado
para a F09b. Sem o
carimbo fora da área segura na partida 6: o empurrão da G04 vale.

**A prova do encaixe** aperta ◀▶ de novo quando o primeiro aperto não pede nenhum encaixe (aconteceu uma vez na
passada do servidor «antes»), e imprime um aviso com o estado da tela; a medida da semicolcheia é a do toque que valeu.

**Para o André (local):** os quatro itens de «Para o André» acima. A roleta (item 2) só fica completa com a G13b;
hoje, ◀▶ rápido já faz só o encaixe com 4 faíscas.

**A conferência:** duas linhas da tabela do encaixe não tinham entrado e não estavam na G13b; entraram agora.

- **A junta do item:** as faíscas e a luz da martelada do item saíam da altura fixa 0,95. Agora
  `TelaLobby.junta(l, k)` dá `Montar.mao(esq, osso do item)` (o osso do `BoneAttachment3D` «Item»: torso, arm-left ou
  arm-right), e a altura fixa só sem o superior ou sem o item no esqueleto.
- **O VU anda um segmento a cada 30 ms:** o VU pulava para o stat novo. Agora `CartaoJogador.vu_mostrado` anda um
  segmento por 30 ms até o corpo, e o número acompanha.

A prova do encaixe só lia o registro que o próprio código escreve. Ganhou três conferências de fora: o `t` do encaixe
cai na grade de semicolcheias pelo relógio e não antes do toque; o VU depois de 31 ms anda no máximo um segmento e
chega ao corpo em `máximo − 1` passos; a junta do item é o punho do osso. Mordidas (o encaixe no toque mais 1 ms, o
VU que pula, a junta fixa) reprovam as três. O reaperto da prova do encaixe (quando o primeiro aperto não pede
encaixe) continua, e pode esconder um aperto perdido: fica anotado para quem coordena.
