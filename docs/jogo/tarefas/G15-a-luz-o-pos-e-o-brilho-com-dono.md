# G15 — A luz, o pós e o brilho com dono

**Sprint:** G · **Tamanho:** G · **Depende de:** F00, F09, G14 (os tokens; o corpo sem tom)

## Por quê

O jogo acende tudo no mesmo laranja, com a energia que cada arquivo quis, e o néon brilha sem dono. Depois que a
G14 tira o tom do corpo, o que diz de quem é o cavaleiro é o contorno e o anel. A bíblia decidiu a luz de cada seção,
o pós da fita e um dono para cada brilho; esta ficha leva os três ao jogo.

## Ler antes

- [01, a luz das cinco tintas](../arte/01-cinema.md#a-luz-das-cinco-tintas) (a conta da luz, o lado B, a fita gasta)
- [07, a tabela do brilho](../arte/07-vfx.md#a-tabela-do-brilho) (os donos, os tetos, o pós em duas passadas)
- [12, o portão 6](../arte/12-portoes.md#6-emissivo-com-dono)

## O estado de hoje

- `godot/scripts/main.gd:92` `_ambiente()`, igual em toda seção: fundo `Tema.CASA`; ambiente `#6d64a0` a 0,42;
  filmic, exposição 1,05; glow 0,7, bloom 0,08, `glow_hdr_threshold` 0,9; **SSAO ligado** (raio 1,2, intensidade
  1,6); névoa `#241f33` a 0,012; saturação 1,08.
- `godot/scripts/salas/sala.gd:60` `luzes()`: tochas `#ffb070` a 1,8 (alcance 9) e um enchimento `#b9b0ff` a 0,55.
  `sala_jogo.gd:158` `atmosfera()`: um preenchimento na `cor_ar` e dois tubos na `cor_neon` a **3,0**.
- 17 `emission_enabled` em `godot/scripts/`, sem dono: `main.gd:449` (o bloco do pódio, 0,6), `mundo/efeitos.gd:95`
  (o anel, 2,0), `mundo/kit.gd:40` (`Kit.material(cor, brilho)`), `mundo/salao.gd` 108 (friso `ROSA` 0,9), 230 (a
  chama `LARANJA` 3,0), 276 (a borda `ROXO` 1,6), 353 (as brasas 2,0), 387 (o aro de cada lugar 1,2),
  `player.gd:83` (o anel no chão, 1,4), `salas/sala_jogo.gd:179` (os tubos 3,0), `salas/impacto.gd:496` e 500 (a
  borda do aviso, `VERMELHO`, de 1,0 a 2,2), `salas/voz.gd` 134 (os olhos `#ff3a1a`), 186 (a borda do lugar), 198
  (a chama 2,5), `salas/canto.gd` 130 (o sino, `AMARELO`) e 196 (a borda do lugar). Mais linhas animam a energia:
  `canto.gd:473`, 499, 503; `voz.gd:538` e 507 (os olhos, 0,2 + 3,2·olhos + 4,0·flash, até 7,4); `impacto.gd:285` e
  296 (o olho da sentinela, 4,0 e 1,2) e 498 (a borda do aviso); `molde.gd:347` (o metal, 0,3 + 2,2·quente, até 2,5,
  num material de `Kit.material`); `prova.gd:721` (o disco da equipe, 1,0 + 2,5·dano, até 3,5, criado na linha 190
  com `LUZ_EQUIPE`). E `Kit.material(cor, brilho)` com brilho > 0 se chama em `centelha.gd`, `galeria.gd`,
  `viga.gd`, `canto.gd`, `caminhos.gd`, `molde.gd`, `impacto.gd`, `voz.gd` e `prova.gd`. Meça de novo antes de mudar.
- O portão de arte, depois da G14, só tem achados 3D (99 pela regra da G14).
- O estudo tem os shaders: `godot/estudos/direcao/shaders/pos_fita.gdshader` (`varredura`, `passo_varredura`,
  `vinheta`, `grao`, `aberracao`, `rasgo`, `desbota`, `semente`), `neon.gdshader` (`cor`, `energia`) e
  `contorno.gdshader` (`cor`, `largura`, `energia`, `normal_suave`).
- A interface mora no `CanvasLayer` `Interface` de `godot/scenes/main.tscn`, `layer` 10.

## O alvo

**A luz por seção**, calculada da tinta, sem hex novo:

- `Tema.para_oklab(c: Color) -> Vector3` e `Tema.de_oklab(v: Vector3, a := 1.0) -> Color`, copiadas de
  `godot/estudos/direcao/fita.gd` (linhas 142 a 170, com as auxiliares `_lin` e `_srgb`).
- `Tema.luz_da_secao(numero: int, lado_b := false) -> Dictionary` com `nevoa`, `preenchimento`, `chave` (cores),
  `densidade` e `energia_chave`. A conta do [01](../arte/01-cinema.md#a-luz-das-cinco-tintas), sobre
  `tinta_da_secao(numero)` (G14): névoa L 0,17 e croma a 30 %; preenchimento L 0,34 e croma a 55 %, o mesmo matiz;
  a chave **não se calcula**: é a constante `CHAVE_SECAO` = `[#ffc99c, #e5d3c6, #e5d7ad, #f8d096, #f8ccba]`
  (vermelhão, cobalto, petróleo, mostarda, ameixa, na ordem de `SECAO`; os hex da tabela do 01 e de
  `godot/estudos/direcao/quadros/13_luz.gd:19` a 23). `TUNGSTENIO.lerp(tinta, 0.2)` dá `#f4bb90` no vermelhão, não
  `#ffc99c`. As cinco entram em `tema.gd` e em `scripts/portoes/arte.json` (`tokens`, nome → hex) como
  `CHAVE_SECAO_0` a `CHAVE_SECAO_4`. `densidade` 0,012, ×1,3 no lado B (0,0156); `energia_chave` 1,8, ×0,85 no
  lado B (1,53).
- `numero` −1 é o salão: névoa `VIOLETA_FUNDO`, preenchimento `AMBIENTE_SALAO` (`#2a2738`, token novo em `tema.gd` e
  em `scripts/portoes/arte.json`, citando o 01), chave `TUNGSTENIO`.
- `main.gd` guarda o `Environment` e ganha `acender(numero, lado_b := false)`: `background_color` `FITA`;
  `ambient_light_color` = preenchimento, energia 0,42; `fog_light_color` = névoa, `fog_density` = densidade;
  `ssao_enabled` **false**; `glow_hdr_threshold` **0,82**; o resto como hoje. E chama `sala.acender(luz)`.
- `Sala.acender(luz)`: as tochas de `luzes()` com `light_color` = chave e `light_energy` = `energia_chave`; o
  enchimento de cima e o preenchimento de `atmosfera()` com a cor `preenchimento`. O salão faz o mesmo nas tochas e
  na luz da forja.
- Quem chama: a entrada de cada sala com o `numero` da seção dela; o salão com −1; o pódio com 0 (mostarda). O lado B
  chega pela G16 (`partida.lado() == "B"`); até lá, `lado_b` é false.

**O brilho com dono**, em `tema.gd` (o portão 6 lê só estas):

| função | devolve | o que faz |
| --- | --- | --- |
| `Tema.neon(cor, energia, dono)` | `ShaderMaterial` com `godot/shaders/neon.gdshader` | `cor` e `energia` |
| `Tema.contorno(cor, largura, energia, dono)` | `ShaderMaterial` com `godot/shaders/contorno.gdshader` | para `next_pass`; `normal_suave` true |
| `Tema.emissivo(material, energia, dono)` | o próprio `StandardMaterial3D` | liga `emission_enabled` (desliga com energia 0), `emission` = a cor do dono, a energia |

- O dono é um lugar (0 a 3, cor `JOGADOR[dono]`, teto 3,0), `"mundo"` (`VIOLETA`, teto 1,2) ou `"forja"`
  (`TUNGSTENIO`, teto 2,4). Dono inválido ou energia acima do teto: `push_error` com o arquivo que chamou e corta no
  teto. `neon` e `contorno` com dono lugar usam a cor do lugar e ignoram `cor` se forem diferentes (o erro diz).
- `Kit.material(cor, brilho := 0.0, rugoso := 0.8, dono = "mundo")`: com `brilho` > 0, chama `Tema.emissivo`.

**Cada brilho de hoje, com o dono e a energia** (as linhas do [07](../arte/07-vfx.md#a-tabela-do-brilho)):

| onde | vira |
| --- | --- |
| `player.gd:83`, o anel no chão | `Tema.neon(JOGADOR[l], 1.5, l)` |
| `player.gd`, o contorno do boneco (novo) | `Tema.contorno(JOGADOR[l], 0.012, 2.4, l)` no `next_pass` de toda superfície das malhas do modelo; 1,6 na montagem (`ForjaPlayer.contornar(energia)`, que a G13 chama depois de montar) |
| `player.gd`, a luz de dono (nova) | `OmniLight3D` na cor do lugar, energia 0,9, alcance 3,4 m, sem sombra, a 0,6 m do chão, só com `controlavel` |
| `mundo/salao.gd:387`, o aro de cada lugar | `Tema.neon(JOGADOR[i], 1.5, i)` |
| `main.gd:449`, o bloco do pódio | `Tema.emissivo(mat, 0.6, l)` |
| `mundo/efeitos.gd:95`, o anel de efeito | `Tema.neon(cor, 2.0, dono)`; `Efeitos.anel` ganha o parâmetro `dono` |
| `salas/sala_jogo.gd:179`, os tubos | `Tema.neon(VIOLETA, 1.0, "mundo")`; 1,1 no tempo 1 de cada compasso, de volta a 1,0 em 1 colcheia |
| `mundo/salao.gd:108`, o friso | `Tema.neon(VIOLETA, 0.9, "mundo")` |
| `mundo/salao.gd:276`, a borda da forja | `Tema.neon(VIOLETA, 1.1, "mundo")` |
| `mundo/salao.gd:230`, a chama | `Tema.neon(TUNGSTENIO, 1.8, "forja")` |
| `mundo/salao.gd:353`, as brasas | `Tema.emissivo(mat, 2.0, "forja")` |
| `salas/impacto.gd:496`/500, a borda do aviso | `Tema.emissivo(mb, e, "forja")`, com `e` de 1,0 a 2,2 como hoje |
| `salas/voz.gd:134`, os olhos | `Tema.emissivo(mat_olho, e, "forja")` |
| `salas/voz.gd:198`, a chama | `Tema.emissivo(mat_chama, 1.8, "forja")` |
| `salas/voz.gd:186` e 538, `canto.gd:196` e 503, a borda do lugar | `Tema.emissivo(mb, e, l)` |
| `salas/canto.gd:130`, 473 e 499, o sino e a tela | `Tema.emissivo(mat, e, "forja")` |
| `salas/voz.gd:507`, os olhos animados | `Tema.emissivo(mo, (0.2 + 3.2 * olhos + 4.0 * flash) * 2.4 / 7.4, "forja")` |
| `salas/impacto.gd:285` e 296, o olho da sentinela | `Tema.emissivo(mo, 2.4, "forja")` e `Tema.emissivo(mo, 1.2 * 2.4 / 4.0, "forja")` |
| `salas/molde.gd:347`, o metal quente | `Tema.emissivo(metal, (0.3 + 2.2 * quente) * 2.4 / 2.5, "forja")`; a cor do metal fica a de hoje |
| `salas/prova.gd:190` e 721, o disco da equipe | `Kit.material(LUZ_EQUIPE[e.equipe], 1.0, 0.6, "forja")`; `Tema.emissivo(md, (1.0 + 2.5 * float(e.dano)) * 2.4 / 3.5, "forja")` |

**Quem chama `Kit.material` com brilho > 0** passa o dono por esta regra, sem decidir caso a caso:

- a cor do lugar (`Forja.cor_do_lugar(l)`, `cor_l`, a `cor` do lugar e o `lerp` dela) → dono `l`;
- `AMARELO`, `LARANJA`, o metal quente, os olhos, a chama, a vela, a bola de fogo e o disco de dano da prova →
  `"forja"`;
- o resto (`ROSA`, as cores do chão, a água, o alvo da galeria) → `"mundo"`, com energia `min(brilho, 1.0)`.

Energia fixa acima do teto do dono vira o teto. Energia animada que passa do teto se multiplica por teto ÷ o máximo
de hoje (a tabela acima já faz a conta): a curva fica a mesma, só mais baixa.

**As cores 3D restantes** (os achados 3D do portão) viram token: a luz de tocha vira a `chave`, o enchimento vira o
`preenchimento`; uma superfície de cenário vira `GRAFITE`, `OXIDO`, `OXIDO_BRILHO` ou `CASCO` (a mais perto em OKLab);
uma cor que marca jogador vira `JOGADOR[l]` com dono.

**O pós da fita** (`PosFita`, autoload novo, `godot/scripts/pos_fita.gd`, com `godot/shaders/pos_fita.gdshader`
copiado do estudo):

- duas passadas: um `CanvasLayer` `layer` 5 (entre o 3D e a `Interface`) e um `layer` 20 (por cima);
- a de baixo leva o desgaste, o rasgo e a aberração; a de cima: `varredura` 0,06, `grao` 0,02, `aberracao` no
  máximo 2,0, `rasgo` a 1/3 do de baixo, `vinheta` 0, `desbota` 0;
- `PosFita.gastar(faixa: int)`: `grao` 0,018 + 0,002 × (faixa − 1) até 0,040; `desbota` 0,01 × (faixa − 1) até 0,10;
  `varredura` 0,07 + 0,002 × (faixa − 1) até 0,09; `vinheta` 0,38 + 0,003 × (faixa − 1) até 0,45. A sala chama em
  `entrar()` com `partida.passo + 1`; fora da partida, faixa 1. Virar a fita não zera;
- `PosFita.ajustar(nome, valor, ms := 0)` e `PosFita.soltar(nome, ms := 0)` (volta ao valor do desgaste), por tween,
  na passada de baixo;
- `PosFita.rasgo_curto()`: `rasgo` 0,35 e `aberracao` 2,2, subida 2 quadros, platô 2, descida 6; a `semente` muda a
  cada 2 quadros enquanto dura; no máximo 3 rasgos por segundo (o quarto é ignorado);
- com `Opcoes.flashes` false: `rasgo` e `aberracao` ficam em 0; o desgaste segue.

## Arquivos que mudam

- `godot/scripts/tema.gd`: `para_oklab`, `de_oklab`, `CHAVE_SECAO`, `luz_da_secao`, `AMBIENTE_SALAO`, `neon`,
  `contorno`, `emissivo`. **De todos:** G11, G14
- `godot/shaders/neon.gdshader`, `contorno.gdshader`, `pos_fita.gdshader` (novos, cópias do estudo)
- `godot/scripts/pos_fita.gd` (novo) e `godot/project.godot` (o autoload `PosFita`). **De todos:** G14
- `godot/scripts/main.gd`: `_ambiente`, `acender`, o bloco do pódio. **De todos:** G09, G11, G13, G14, G16
- `godot/scripts/salas/sala.gd` e `godot/scripts/salas/sala_jogo.gd`: `acender`, os tubos, `gastar`. **De todos:** G12,
  G16
- `godot/scripts/mundo/salao.gd`, `godot/scripts/mundo/kit.gd`, `godot/scripts/mundo/efeitos.gd`. **De todos:** G10,
  G14
- `godot/scripts/salas/*.gd`: só as linhas 3D. **De todos:** G14, G16
- `godot/scripts/player.gd`: o anel, o contorno, a luz de dono. **De todos:** G10, G13, G14
- `godot/scenes/main.tscn`: a cor 3D da linha 16. **De todos:** G14
- `scripts/portoes/arte.json`: `AMBIENTE_SALAO` e `CHAVE_SECAO_0` a `_4`. **De todos:** G14
- `godot/testes/prova_do_jogo.gd` e `godot/testes/prancha_da_luz.gd` (novo). **De todos**

## Como se joga

Não se aplica: nenhuma regra muda.

## A cena

- **A luz:** cada sala na luz da tinta da seção, pela conta do 01. O resultado bate com a tabela do 01 (vermelhão:
  névoa `#210502`, preenchimento `#602016`, chave `#ffc99c`; cobalto `#050d26`, `#1f346a`, `#e5d3c6`; petróleo
  `#011311`, `#11413b`, `#e5d7ad`; mostarda `#170e00`, `#493400`, `#f8d096`; ameixa `#18081c`, `#4a2854`, `#f8ccba`).
- **O que brilha:** só o que está na tabela acima, com o teto do dono; o contorno de 0,012 e o anel são os únicos
  néons saturados da sala, e cada um tem a cor de um lugar.
- **O pós:** grão, varredura e vinheta sempre; o rasgo só na entrada, na volta da pausa e na Dissonância.
- **A prancha:** `godot/testes/prancha_da_luz.gd` (xvfb, `--audio-driver Dummy`) grava `docs/imagens/jogo/luz.jpg`,
  1920×2700: a sala do minigame de prova nas cinco tintas (linhas) e nos lados A e B (colunas), 960×540 cada, câmera
  de 35 mm em plongée de 50°, com os quatro bonecos; a mesma montagem do `docs/imagens/direcao/13_luz.jpg`.

## O som

Não se aplica: nenhum som muda.

## O controle

Não se aplica: a lightbar é a cor do lugar pela G14, e nada aqui a muda.

## O cavaleiro

A peça não muda de stat. Como aparece: o corpo na cor da malha (G14), com o contorno de 0,012 na cor do lugar a 2,4
(1,6 na montagem), o anel de oito lados no chão a 1,5 e a luz de dono a 0,9. A G13 acende o acento da peça com
`Tema.neon(JOGADOR[l], 1.6, l)` e chama `contornar(1.6)` na montagem.

## As reações

Não se aplica: nenhuma reação muda.

## A diversão

Não se aplica como momento: a luz não muda o que acontece na noite. O que ela garante, e como se confere:

- **Prancha:** em `luz.jpg`, os quatro bonecos se distinguem pelo contorno nas dez células, e as cinco tintas se
  separam de longe; o jogador do time diz, de cada célula, o lugar de cada boneco e a seção.
- **Robô:** na mesa padrão (P1 `bom`, P2 e P3 `medio`, P4 `ruim`), semente 7, a prova lê o `grao` do pós no começo da
  faixa 1 (0,018) e da faixa 12 (0,040).

## Pronto quando

Cada seção tem a luz do 01 nos dois lados; o SSAO está desligado e o limiar do glow é 0,82; nenhum material brilha
fora das três funções; o portão de arte não tem mais achado de cor nem de emissivo; o pós está nas duas passadas,
gasta por faixa e desliga o rasgo sem Flashes.

## Provas

- `bash tests/prova_do_jogo.sh`, com estas checagens novas em `godot/testes/prova_do_jogo.gd`:

  ```gdscript
  var v := Tema.luz_da_secao(1)
  _esperar(v.nevoa.to_html(false) == "210502" and v.chave.to_html(false) == "ffc99c", "luz: vermelhão como o 01")
  _esperar(is_equal_approx(Tema.luz_da_secao(1, true).densidade, 0.0156), "luz: o lado B adensa a névoa")
  _esperar(main.env.ssao_enabled == false and is_equal_approx(main.env.glow_hdr_threshold, 0.82), "luz: sem SSAO, limiar 0,82")
  var m := Tema.emissivo(StandardMaterial3D.new(), 9.0, "mundo")
  _esperar(is_equal_approx(m.emission_energy_multiplier, 1.2), "brilho: o mundo para em 1,2")
  PosFita.gastar(12)
  _esperar(is_equal_approx(PosFita.valor("grao"), 0.040), "pós: a faixa 12 no teto do grão")
  Opcoes.flashes = false
  PosFita.rasgo_curto()
  _esperar(PosFita.valor("rasgo") == 0.0, "pós: sem Flashes, sem rasgo")
  Opcoes.flashes = true
  ```

  A conta OKLab pode errar 1 em 255 num canal: se `to_html` diferir só nisso, a prova compara canal a canal com
  folga de 1/255.
- `bash scripts/portoes/rodar.sh --so arte`: zero achados de cor e de emissivo.
- `bash tests/prova_visual.sh`: as fotos das salas na luz nova; o HUD legível com o pós de cima.
- A prancha `docs/imagens/jogo/luz.jpg` ao lado de `docs/imagens/direcao/13_luz.jpg`, olhada pelo jogador do time.

## Passos

1. `para_oklab`, `CHAVE_SECAO`, `luz_da_secao`, `AMBIENTE_SALAO`; `acender` em `main.gd`, `sala.gd` e `salao.gd`;
   o `_ambiente` novo.
2. As três funções de brilho e os shaders; trocar os 17 materiais e as 4 animações, um arquivo por commit.
3. O contorno, o anel e a luz de dono em `player.gd`.
4. As cores 3D restantes.
5. `PosFita`, as duas passadas, o desgaste e o rasgo.
6. A prancha da luz; o portão.

## Armadilhas

- **O Compatibility multiplica o glow pelo fundo a ×0,45:** a energia que parece certa no Forward+ fica fraca aqui.
  Medir na prova, não no editor.
- **O contorno em `next_pass`** dobra as chamadas de desenho do boneco: medir o quadro com 4 bonecos na prova; se
  passar de 16,7 ms na máquina da prova, o `normal_suave` vai a false.
- **A passada de baixo lê a tela antes da `Interface`:** o `layer` 5 tem de ficar abaixo do 10.
- **O pico** (a chave +20 % quando a música dobra) não entra: nenhuma faixa diz hoje onde o pico está.

## Não fazer

- Não mexer em câmera nem em corte (é da G05 e do 01).
- Não pôr SSAO nem uma segunda luz com sombra.
- Não pintar o corpo do boneco: o tom do dono é contorno, anel, luz e acento.

## Ao terminar

Marcar G15 como **feito** no [quadro](README.md), com o gasto. Commit sugerido:
`feat(luz): a luz de cada seção, o pós da fita em duas passadas e o brilho com dono`.

## O que foi feito (leva 1, a-fita)

- **A luz de cada seção** (`tema.gd`, `arte.json`): os tokens da luz (`para_oklab`, `CHAVE_SECAO`, `luz_da_secao`,
  `AMBIENTE_SALAO`) e o `acender(numero, lado_b)` em `main.gd`, `sala.gd` e `salao.gd`. Cada sala acende na entrada
  com a chave, o preenchimento e a névoa da seção dela (`Sala.numero()`/`SECAO_DE`; a Bancada é a seção 0, mostarda).
  O Sol da cena recebe o preenchimento da seção (o `main.tscn` não fixa mais `light_color`). SSAO desligado.
- **O brilho com dono:** as três funções (`Tema.emissivo`, `Tema.neon`, `Tema.contorno`) e os shaders
  `neon/contorno/pos_fita.gdshader`; os 17 `emission_enabled` soltos e as animações passaram por elas (`Kit.material`
  leva o dono). O teto de energia é do dono (mundo 1,2, forja 2,4, lugar 3,0); dono inválido cai no teto 1,0.
  `Tema.brilho_de()` deixa as animações lerem a energia sem escrever fora do tema.
- **O cavaleiro** (`player.gd`): o anel no chão é néon do lugar (1,5), o contorno de néon do lugar (2,4 no jogo, 1,6
  na montagem, `contornar(energia)`) em toda superfície do boneco e do que ele leva (a normal suavizada vai no
  TANGENT, em cache), e a luz de dono (0,9, 3,4 m, sem sombra, a 0,6 m) que só acende com `controlavel`.
- **O pós da fita** (`PosFita`, autoload, duas passadas nas camadas 5 e 20): grão, vinheta e o rasgo, gastos por faixa
  (`gastar` na entrada da sala), `rasgo_curto()` na entrada da sala e na volta da pausa, e sem rasgo com
  `Opcoes.flashes` desligado (o rasgo que já corre é cortado no meio).
- **O portão de arte** (`scripts/portoes/arte.py`, regra 6): emissão fora do tema, néon sem dono, energia acima do
  teto e shader escrito à mão reprovam; `prova_dos_portoes.sh` foi a 46 casos.
- **A prancha** (`godot/testes/prancha_da_luz.*`, `docs/imagens/jogo/luz.jpg`): a Centelha real nas cinco tintas,
  lado A e B, com os quatro bonecos.
- **Medida:** o portão de arte foi de **127 para 35 achados**, todos de cor e todos da G14b (os `Color(...)` de
  `atmosfera`, o sino, a faísca, a barra de luz, o metal do Molde); **zero** de emissivo. SSAO 1,2 para desligado; limiar
  do glow 0,9 para 0,82; 17 `emission_enabled` para 3 funções.
- **Provas:** `_prova_da_luz` em `prova_do_jogo.gd` (a chave e a névoa por seção e por lado, o acender da sala e do
  salão, o teto por dono, o anel, o contorno e a luz de dono dos quatro bonecos, o pós por faixa, o rasgo cortado no
  meio). Mordeu, uma a uma: SSAO ligado; limiar 0,9; acender sem a chave; teto do grão em 0,060; Flashes ignorados no
  pós; boneco sem `contornar`; luz de dono sem seguir `controlavel`; 30 rasgos por segundo; `gastar` na entrada;
  `TETO_MUNDO` 3,0; chave da seção 0 fixa; lado B sem ×1,3; e as quatro do portão. `rodar.sh` e `prova_sem_rastro` ok.
- **O que a prova achou no caminho:** as salas penduram peças no boneco (a vara da Viga, o martelo, a arma da
  Galeria) com o material da sala; a régua do contorno olha só o que é do boneco (sem `material_override`).

### Escolhas minhas, para ela validar

- Superfícies claras de cenário (ouro, madeira, metal, gramas, pedra) caem em `OXIDO_BRILHO` pela regra do token mais
  perto em OKLab, e o visual achata; ouro, brasa, olhos e a bola de fogo ficaram com albedo `TUNGSTENIO` ou
  `OXIDO_BRILHO` e emissão do dono «forja».
- O anel de efeito some baixando a energia (o shader neon não tem alfa; o anel fica opaco enquanto some).
- A lanterna do Impacto: emissão fixa na cor do lugar (perde o tom do estado no brilho).
- `atmosfera()` ignora `cor_neon`: os tubos são sempre `VIOLETA`, a cor do mundo.
- O disco da equipe da prova e a bola de tiro têm dono «forja».
- Contorno de 0,012 no espaço do modelo (escala 2,0, uns 0,024 m); aplicado em `visual()` porque a G13 não existe.
- O pós gasta pela faixa da noite (uma partida de 9 salas só chega à faixa 9, grão 0,034); o teto 0,040 é da faixa 12.

### Para o André (local)

- Abrir `docs/imagens/jogo/luz.jpg` ao lado de `docs/imagens/direcao/13_luz.jpg` na placa de vídeo: a foto é de software
  (llvmpipe), a aparência não se aprova ali; as manchas rosa e amarela da luz de dono no chão da prancha parecem fortes.
- Ver o contorno, o anel e a luz de dono com o controle de verdade; o rasgo do pós; o glow no Compatibility.
- Medir o quadro com 4 contornos na máquina da prova: se passar de 16,7 ms, `normal_suave` vai a false.
- Fica para a G14b: os 35 achados de cor. Fica para a G13: chamar `contornar(1.6)` na montagem. Fica para quem fizer a
  Dissonância: chamar `PosFita.rasgo_curto()`.

### Na conferência (leva 1, a-fita)

- O contorno trouxe um erro novo no log da prova do jogo: `Parameter "material" is null` (0 na base, 16 a cada passada
  depois da G15), no fim de cada sala e na troca do boneco. A causa: o material duplicado com `next_pass` morria na fila
  de deleção junto com o boneco, e o servidor de desenho ainda o pedia no quadro em que outro boneco nascia. A cura, em
  `player.gd`: `_soltar_contorno()` devolve as superfícies ao material do kit antes de todo `queue_free` (o modelo, os
  itens nos ossos e o próprio boneco, no `NOTIFICATION_PREDELETE`), e `_contornar_em` pula o que já está na fila. Medido
  de novo: 0 nas duas passadas.
- O «Pronto quando» pede o portão de arte sem achado de cor: ficam os 35, que a G14b assume um a um. A cor de controle
  (as equipes do Impacto e da Prova, o `Color(1, 0, 0)` da pergunta) e o metal do Molde pedem decisão dela.
