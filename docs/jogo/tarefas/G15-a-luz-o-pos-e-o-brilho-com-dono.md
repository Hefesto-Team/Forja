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
- `godot/scripts/salas/sala.gd:59` `luzes()`: tochas `#ffb070` a 1,8 (alcance 9) e um enchimento `#b9b0ff` a 0,55.
  `sala_jogo.gd:162` `atmosfera()`: um preenchimento na `cor_ar` e dois tubos na `cor_neon` a **3,0**.
- 17 `emission_enabled` em `godot/scripts/`, sem dono: `main.gd:449` (o bloco do pódio, 0,6), `mundo/efeitos.gd:95`
  (o anel, 2,0), `mundo/kit.gd:40` (`Kit.material(cor, brilho)`), `mundo/salao.gd` 108 (friso `ROSA` 0,9), 230 (a
  chama `LARANJA` 3,0), 276 (a borda `ROXO` 1,6), 353 (as brasas 2,0), 387 (o aro de cada lugar 1,2),
  `player.gd:83` (o anel no chão, 1,4), `salas/sala_jogo.gd:179` (os tubos 3,0), `salas/impacto.gd:496` e 500 (a
  borda do aviso, `VERMELHO`, de 1,0 a 2,2), `salas/voz.gd` 134 (os olhos `#ff3a1a`), 186 (a borda do lugar), 198
  (a chama 2,5), `salas/canto.gd` 130 (o sino, `AMARELO`) e 200 (a borda do lugar). Mais quatro linhas animam a
  energia (`canto.gd:473`, 499, 503; `voz.gd:538`). Meça de novo antes de mudar.
- O portão de arte, depois da G14, só tem achados 3D (99 pela regra da G14).
- O estudo tem os shaders: `godot/estudos/direcao/shaders/pos_fita.gdshader` (`varredura`, `passo_varredura`,
  `vinheta`, `grao`, `aberracao`, `rasgo`, `desbota`, `semente`), `neon.gdshader` (`cor`, `energia`) e
  `contorno.gdshader` (`cor`, `largura`, `energia`, `normal_suave`).
- A interface mora no `CanvasLayer` `Interface` de `godot/scenes/main.tscn`, `layer` 10.

## O alvo

**A luz por seção**, calculada da tinta, sem hex novo:

- `Tema.oklab(c: Color) -> Vector3` e `Tema.de_oklab(v: Vector3) -> Color` (as funções de `fita.gd`).
- `Tema.luz_da_secao(numero: int, lado_b := false) -> Dictionary` com `nevoa`, `preenchimento`, `chave` (cores),
  `densidade` e `energia_chave`. A conta do [01](../arte/01-cinema.md#a-luz-das-cinco-tintas), sobre
  `tinta_da_secao(numero)` (G14): névoa L 0,17 e croma a 30 %; preenchimento L 0,34 e croma a 55 %, o mesmo matiz;
  chave = `TUNGSTENIO.lerp(tinta, 0.2)`. `densidade` 0,012, ×1,3 no lado B (0,0156); `energia_chave` 1,8, ×0,85 no
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
| `salas/voz.gd:186` e 538, `canto.gd:200` e 503, a borda do lugar | `Tema.emissivo(mb, e, l)` |
| `salas/canto.gd:130`, 473 e 499, o sino e a tela | `Tema.emissivo(mat, e, "forja")` |

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

- `godot/scripts/tema.gd`: `oklab`, `luz_da_secao`, `AMBIENTE_SALAO`, `neon`, `contorno`, `emissivo`. **De todos:**
  G11, G14
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
- `scripts/portoes/arte.json`: `AMBIENTE_SALAO`. **De todos:** G14
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

1. `oklab`, `luz_da_secao`, `AMBIENTE_SALAO`; `acender` em `main.gd`, `sala.gd` e `salao.gd`; o `_ambiente` novo.
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
