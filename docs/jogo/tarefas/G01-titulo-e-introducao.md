# G01 — O título e a introdução

**Sprint:** G · **Tamanho:** M · **Depende de:** F00, F04, F07, F08, F09, G14

## Por quê

Ela: «as pessoas precisam ter prazer no início do jogo». Hoje o título fala de
módulo e de USB e cai direto no lobby. Ele vira a fita da noite no deck, com o
PLAY que se ouve e se sente na mão, e uma introdução de 24 s sem uma palavra; o
robô passa por esse começo apertando botões, como uma pessoa.

## Ler antes

- [O plano de cada momento](../arte/01-cinema.md#o-plano-de-cada-momento) (as linhas «título», «PLAY» e «introdução», e o corte no tempo 1)
- [O casamento evento por evento](../arte/03-som.md#o-casamento-evento-por-evento) (o PLAY, o controle entra)
- [A paridade entre a prova e o jogo](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08)

## Arquivos que mudam

| arquivo | também muda em |
| --- | --- |
| `godot/scripts/ui/tela_titulo.gd` | — |
| `godot/scripts/ui/tela_intro.gd` e `.uid` (novos, `class_name TelaIntro`) | — |
| `godot/scripts/ui/desenho.gd` (`caixa`, `carretel`, `contador`) | **G04, G07** |
| `godot/scripts/mundo/lente.gd` e `.uid` (novo, `class_name Lente`) | **G05** (o mesmo conteúdo: o primeiro que chegar cria) |
| `godot/scripts/main.gd` | **G02, G04, G05, G06, G07, G08** |
| `godot/scripts/player.gd` (`acender`, `cabeca`, `INTERVALO_DO_MODELO`) | **G02, G03, G08, G13** |
| `godot/scripts/som.gd` (o encanamento do id, `pio`) | **G03, G04, G06, G07, G08** |
| `godot/scripts/musica.gd` (a faixa `"titulo"`) | — |
| `godot/scripts/mundo/salao.gd` | **G05, G06, G08** |
| `godot/scripts/traducoes.gd` | **todas as G com texto** |
| `godot/assets/sons/` (os WAV de `fx_play` e dos `pio_*`) e `docs/jogo/audio/mapa.csv` | **G03, G04, G06, G07** |
| `godot/testes/prova_do_jogo.gd`, `godot/testes/captura_jogo.gd` | **todas as G** |

## Como se joga

Não se aplica como minigame. O fluxo: **título → PLAY (4 batidas) →
introdução (só na primeira vez da sessão, 24 s) → construção** (o estado
`"lobby"`, que a G02 transforma na construção). No título, ✕ ou Options de
qualquer controle dá o PLAY; △ abre os créditos. Na introdução, qualquer
botão (✕ ○ □ △ Options) a pula, depois de 0,5 s. Sem controle, Enter joga no
teclado.

## A cena

A lente vira FOV vertical por `Lente.fov(mm) = rad_to_deg(2·atan(12/mm))`:
85 mm = 16,1°, 35 mm = 37,8°. O corte de plano espera o próximo tempo 1 do
compasso da faixa do título (115 BPM: batida de 522 ms, compasso de 2087 ms).

| momento | plano | lente | posição e olhar (`B = salao.bigorna.global_position`) | movimento | corte |
| --- | --- | --- | --- | --- | --- |
| título | a forja atrás, fora de foco, sob o cassete desenhado em 2D | 85 mm | `[B + Vector3(0, 1.0, 9.0), B + Vector3(0, 1.0, 0)]` | push-in de 3 % da distância em 8 compassos (16,7 s), `ENTRA_SAI`, e recomeça | sai no PLAY |
| PLAY | o mesmo plano; o cassete 2D desce para o deck | 85 mm | o mesmo | o cassete anda +720 px em y em 4 batidas (2087 ms), `ENTRA` (`TRANS_CUBIC`, `EASE_IN`) | corte seco no primeiro tempo 1 depois das 4 batidas |
| introdução 0–9 s | a bigorna | 35 mm | `[B + Vector3(3.2, 2.2, 4.2), B + Vector3(0, 1.2, 0)]` | parado | — |
| introdução 9–24 s | os quatro pedestais | 35 mm | `[Vector3(0, 2.4, 11.0), Vector3(0, 1.0, 4.4)]` | a câmera anda até lá em 2 compassos, `ENTRA_SAI` | corte seco para a construção no tempo 1 |

- **O foco do título:** `camera.attributes = CameraAttributesPractical` com
  `dof_blur_far_enabled = true`, `dof_blur_far_distance` 3,0 m,
  `dof_blur_far_transition` 2,0 m, `dof_blur_amount` 0,06; fora do título,
  `dof_blur_far_enabled = false`.
- **A luz:** a da forja (`salao.luz_da_forja`, a `OmniLight3D` de
  `_bigorna()`) pulsa na batida: energia `(0.5 + 3.0 * pulso)`, com
  `pulso = clampf(t / 2.0, 0.0, 1.0) * (0.55 + 0.45 * pow(1.0 - fração_da_batida, 3.0))`.
  As tochas tremulam como hoje.
- **O título** (`TelaTitulo._draw()`, tela lógica 1920×1080), a composição
  do quadro aprovado `docs/imagens/direcao/07_titulo.jpg`
  (`godot/estudos/direcao/quadros/07_titulo.gd`, `_hud`):

| o quê | onde | como |
| --- | --- | --- |
| o mostrador | triângulo (100,70)-(100,116)-(138,93) e «PLAY» em (156, 62); «SP  0:00:00» alinhado à direita em x 1820, y 62 | VT323 60 px, `Color(Tema.ETIQUETA, 0.9)`; o contador parado em 0:00:00 até o PLAY |
| o cassete | `Rect2(400, 170, 1120, 690)`, sombra deslocada (10, 16) em `Tema.SOMBRA` | `Desenho.caixa` raio 34, `Tema.CASCO`, borda 4 `Tema.CASCO_ALTO`; quatro parafusos de raio 11 em `Tema.GRAFITE` a 30 px dos cantos |
| a etiqueta | `Rect2(456, 218, 1008, 360)` | `Tema.ETIQUETA` raio 12; tarja `Tema.SECAO[0]` de 18 px em y +26, filete `Tema.SECAO[3]` de 6 px em y +50 |
| o logo | `Rect2(492, 294, 260, 260)` | `Desenho.LOGO` |
| o nome | «A FORJA» em (786, 322) | Bungee 128 em `Tema.TINTA`, com o eco em (796, 332) em `Color(Tema.SECAO[0], 0.9)` |
| a linha | «Nove salas, quatro cavaleiros» em (794, 486) | Permanent Marker 40, `Tema.TINTA` |
| a janela | `Rect2(660, 612, 600, 170)` | `Tema.JANELA` raio 22, borda 3 `Tema.GRAFITE`; dois carretéis de raio 70 em x +140 e +460 (`Desenho.carretel`, fita 0,95 e 0,30), girando 90°/batida, `RETA` |
| o pé | trapézio de (630, 860)-(690, 780)-(1230, 780)-(1290, 860) | `Tema.CASCO_ALTO`; quatro furos de raio 14 em `Tema.JANELA` |
| o botão | `Rect2(760, 920, 400, 82)` | `Desenho.caixa` `Tema.ETIQUETA` raio 14; o halo `grow(10)` em `Color(Tema.ETIQUETA, 0.12 + 0.18 * pulso)`; a dica de ✕ «Gravar» em Archivo 700 de 44 px, `Tema.TINTA` |
| sem controle | a mesma caixa com a dica «Jogar no teclado» (Enter); acima, em y 860, «Nenhum controle encontrado» centrado | Archivo 600 de 34 px, `Tema.ETIQUETA` |
| a dica dos créditos | à direita da caixa, x 1200, y 946 | a dica de △ «Créditos», Archivo 600 de 34 px, `Tema.MUDO` |
| rodapé, USB/BT, módulo, versão | — | **saem** |

  As dicas seguem a escrita da F07 (`Glifo.dica`). A versão vai para o
  registro: `Forja.registrar("FORJA %s" % Forja.versao())` uma vez, no
  `_ready()` do main.
- **A introdução** (`TelaIntro`, **sem nenhum texto**):

| tempo (s) | o que acontece |
| --- | --- |
| 0 – 4 | a forja acesa na batida (`salao.pulso`, como no título) |
| 4 – 9 | a Dissonância: `salao.apagado` sobe de 0 a 1 em 5 s, `ENTRA_SAI` (tochas e forja apagam); a estática cresce de 0 a 1 |
| 9 – 12 | escuro; a estática baixa para 0,35; a câmera vai aos pedestais |
| 12 – 19 | as quatro armaduras vazias nos pedestais: visíveis, sem cabeça (`cabeca(false)`), na animação `"static"`, apagadas (`acender(0.0)`). Aos 12,5 / 14,0 / 15,5 / 17,0 s, a do P1, P2, P3, P4 acende: `acender(1.0)` em 4 quadros, 24 faíscas `Efeitos.faiscas(salao, pos + Vector3(0, 1.6, 0), Tema.JOGADOR[l], 24, 0.8)` (8 com o movimento reduzido: `not Opcoes.tremor` hoje, `Opcoes.movimento == 1` depois da G16) |
| 19 – 24 | a forja reacende: `salao.apagado` desce a 0 em 2 s; a estática some; aos 24,0 s, `acabou = true` |

  A estática, em `_draw()`: `RandomNumberGenerator` com
  `seed = int(t * 24.0)`; `int(60 * densidade)` faixas
  `Rect2(0, y, size.x, h)` com `y` sorteado e `h` de 2 a 10 px, cor
  `Tema.GRAFITE` ou `Tema.ETIQUETA` com alfa de 0,05 a 0,25 × densidade
  (× 0,4 com `Opcoes.flashes` desligado; 0 com o movimento reduzido), e um
  véu `Color(Tema.FITA, 0.35 * escuro)` por cima.
- **O que brilha e de quem:** só o néon dos jogadores (o anel e o contorno
  das armaduras acesas) e a luz da forja (`TUNGSTENIO`, dono «forja»). Nada
  na cor de jogador fora do jogador.

## O som

| quando | id do mapa | onde | volume |
| --- | --- | --- | --- |
| o título e a introdução, de fundo | `mus_titulo` (`MUS_TELA_TITULO`, 115 BPM, Dó menor); enquanto não existe, a reserva `sint_trilha` com `FAIXAS["titulo"] = [60, 115, 1]` | TV | o da `Musica` (−9 dB) |
| qualquer botão de um controle com lugar, no título | `pio_p{lugar+1}_{intervalo}` (humano `segunda`, orc `quinta_baixo`) | TV e o alto-falante do dono | −12 dB |
| o PLAY | `fx_play` | TV | −6 dB |
| introdução 4,0 s e 6,5 s | `sint_vento` (`Som.tocar("vento")`) | TV | 0 dB |
| introdução, cada armadura que acende | `sint_bigorna` (`Som.tocar("bigorna", null, 0.0, tom)`), o tom do lugar: P1 1,0 (Dó), P2 1,1225 (Ré), P3 1,3348 (Fá), P4 1,4983 (Sol) | TV | 0 dB |
| introdução 4,0 s | a música cala (`Musica.calar()`) | — | — |
| introdução 19,0 s | a música do título volta | TV | — |

**Como o som chega ao jogo.** O encanamento, igual nas fichas G09, G11, G12
e G16 (se outra ficha já fez a mudança em `som.gd`, usar a dela sem mudar):

1. copiar `godot/estudos/direcao/som/fx_play.wav` e os 24
   `godot/estudos/direcao/som/pio_p*_*.wav` para `godot/assets/sons/`;
2. `"$GODOT" --headless --path godot --import --quit` e conferir em cada
   `.wav.import` novo a linha `compress/mode=0` (o alto-falante do controle
   lê o PCM cru);
3. em `som.gd`, `Som.tocar(nome, ...)` e `Som.no_controle(lugar, nome, ...)`
   tocam primeiro `res://assets/sons/<nome>.wav` quando ele existe, sem o tom
   sorteado de ±5 % dos gravados;
4. no `docs/jogo/audio/mapa.csv`, nas linhas `fx_play` e `pio_*`: `arquivo`
   = `godot/assets/sons/<id>.wav` e `estado` = `no jogo`.

**O pio** (em `som.gd`; a G02 e a G08 chamam com a mesma assinatura):

```gdscript
## O pio do cavaleiro do lugar (arte/03): a nota do lugar e o intervalo da
## cabeça, na TV e no alto-falante do dono.
func pio(lugar: int, boneco: int) -> void:
	var i := wrapi(boneco, 0, ForjaPlayer.INTERVALO_DO_MODELO.size())
	var id := "pio_p%d_%s" % [lugar + 1, ForjaPlayer.INTERVALO_DO_MODELO[i]]
	tocar(id, null, -12.0)
	no_controle(lugar, id, 0.85)
```

## O controle

| evento | para quem | vibração (forte/fraco/ms) | gatilho | luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| um botão no título (o controle entra) | o dono | toque 0/0,45/60 | Off nos dois (`Forja.gatilhos_off`) | a do lugar, como hoje | o pio |
| o PLAY | quem apertou | fita 0/0,3/400 | não muda | não muda | nada (o `fx_play` é da TV) |
| cada armadura que acende | o dono daquele lugar | acerto 0,3/0,6/80 (uma martelada) | não muda | não muda | nada |
| o resto | — | nada | nada | nada | nada |

Sem o controle na mão: o controle simulado mostra o que recebeu.
`Forja.som_virtual(l).falante` mede o pio no alto-falante de cada lugar, e
`Forja.ctl.percepcao(Forja.pad_do_lugar(l))` traz `forte` e `fraco`. A prova
confere o pio só no P1, o PLAY no P1 e uma martelada em cada lugar ocupado
(Provas).

## O cavaleiro

Não se aplica aos stats: a introdução mostra as armaduras vazias, antes de
qualquer escolha. A cabeça escolhida aparece no pio (o intervalo).
`ForjaPlayer.INTERVALO_DO_MODELO := ["segunda", "quinta_baixo"]`, alinhado
com `MODELOS` (humano, orc); a G08 junta isso em `BONECOS`.

## As reações

Não se aplica: o título aceita reação pela [09](../arte/09-reacoes.md), mas a
roda e os adesivos chegam com a G16; esta ficha não dispara nenhuma.

## A diversão

**O momento:** o PLAY. Quem aperta ✕ ouve o clunk na TV, sente o motor da fita
na mão por 400 ms e vê o cassete afundar no deck, e o grupo vê as quatro
armaduras acenderem uma por uma, cada uma com a sua nota do acorde. **Como se
confere:**

1. A prova mede o PLAY no controle de quem apertou (`fraco` > 0 no P1 até
   400 ms depois do ✕) e o pio só no P1.
2. A prova mede as quatro marteladas da introdução: uma vibração em cada
   lugar ocupado entre 12,5 e 17,5 s.
3. A prancha `prancha-titulo.png` da prova visual mostra, lado a lado, o
   título, o quadro do PLAY com o cassete pela metade e a introdução com as
   quatro armaduras acesas; o jogador do time compara com
   `docs/imagens/direcao/07_titulo.jpg` e anota no diário.

## O estado de hoje

- `godot/scripts/main.gd:29` começa em `var estado := "titulo"`.
- `main.gd:215-229`, `_mostrar()`: `Musica.tocar(sala_id if qual == "sala" else qual)`;
  `salao.pedestais_no.visible = qual in ["lobby", "podio"]`.
- `main.gd:542-566`, `_process()`: o `match estado` chama `_quadro_titulo`,
  `_quadro_lobby`… Não há estado de introdução.
- `main.gd:575-589`, `_quadro_titulo()`: ✕ ou Options de qualquer controle
  vai direto ao lobby com `_trocar(_ir_para_o_lobby)`; △ abre os créditos;
  sem controle, Enter chama `Forja.jogar_no_teclado()`.
- `main.gd:925-931`, `_pose_da_camera()`: o título gira em volta da bigorna
  (`_t * 0.08`). `main.gd:956-976`: `_enquadrar()` usa `FOV_16_9 := 40.0`
  em todo estado; `_mover_camera` suaviza com `k` 1,2 no título.
- `godot/scripts/ui/tela_titulo.gd`: «Hefesto», «Tech Demo», a contagem de
  USB/BT e o rodapé com a versão; tudo sai.
- `godot/scripts/musica.gd:11-24`, `FAIXAS`: não há `"titulo"`;
  `TELAS.titulo = "MUS_TELA_TITULO"` já existe (linha 190), e `tocar` cai no
  salão quando a faixa gerada falta.
- `godot/scripts/mundo/salao.gd:251-313`, `_bigorna()`: a luz da forja vai
  para `_tochas` (linha 313) e tremula como as tochas em `_process` (50-55).
- `godot/scripts/som.gd`: `tocar(nome, pos, volume_db, tom)` na linha 109,
  `no_controle(lugar, nome, ganho)` na 153. Não há tocador por id do mapa.
- O estudo tem os helpers de desenho do cassete em
  `godot/estudos/direcao/hud.gd`: `caixa` (32), `carretel` (74), `contador`
  (105).
- `godot/testes/prova_do_jogo.gd:83`, `_prova_do_percurso()`: aperta ✕ no
  título (linha 90) e espera `"lobby"` 40 quadros depois.
- `godot/testes/captura_jogo.gd` aperta ✕ no título em todos os roteiros
  (`_roteiro_das_telas`, `_roteiro_das_salas`, `_roteiro_da_partida`,
  `_roteiro_do_trailer`, `_roteiro_dos_extras`).

## O alvo

**`Lente`** (`godot/scripts/mundo/lente.gd`, novo; a G05 usa o mesmo):

```gdscript
class_name Lente
## A lente em mm vira FOV vertical (arte/01): sensor de 24 mm de altura.
static func fov(mm: float) -> float:
	return rad_to_deg(2.0 * atan(12.0 / mm))
## O FOV de hoje (40°) em mm, para quem ainda não tem lente decidida.
const PADRAO := 32.97
```

Em `main.gd`: `func _lente() -> float` (`"titulo": 85.0`, `"intro": 35.0`,
o resto `Lente.PADRAO`; a G05 acrescenta as dela) e `_enquadrar()` usa
`Lente.fov(_lente())` no lugar de `FOV_16_9` (o ramo `KEEP_WIDTH` converte o
mesmo FOV como hoje). Se a G05 já fez `_lente()`, só acrescentar as duas
linhas.

**O relógio da batida do título** (no main):

```gdscript
var _toca_titulo: AudioStreamPlayer
var _mapa_titulo := {}
## As batidas desde o começo da faixa do título (115 BPM), pelo relógio de áudio.
func _batidas_do_titulo() -> float:
	if _toca_titulo == null or not _toca_titulo.playing:
		return _t_titulo * 115.0 / 60.0
	var s := _toca_titulo.get_playback_position() + AudioServer.get_time_since_last_mix() \
		- AudioServer.get_output_latency() - float(_mapa_titulo.primeiro_tempo)
	return s * float(_mapa_titulo.bpm) / 60.0
```

Ao mostrar `"titulo"` ou voltar à faixa na introdução:
`var slot := Musica.TELAS.titulo if not Musica.mapa_gerado(Musica.TELAS.titulo).is_empty() else "titulo"`,
`_toca_titulo = Musica.tocar_do_zero(slot)`, `_mapa_titulo = Musica.mapa(slot)`.

**O PLAY** (`_dar_play(l: int)`): no mesmo quadro,
`Som.tocar("fx_play", null, -6.0)`, `Forja.vibrar(l, 0.0, 0.3, 400)`,
`titulo.play_desde = _batidas_do_titulo()` (o cassete começa a descer) e
`play_ms = Time.get_ticks_msec()` (`var play_ms := -1` no main: o contador da
noite, que a G07 lê no fim da fita). O corte: quando
`_batidas_do_titulo() >= ceil((titulo.play_desde + 4.0) / 4.0) * 4.0`, `_trocar`
para a introdução (primeira vez) ou para o lobby. O contador do mostrador
passa a contar de `play_ms`.

**`TelaTitulo`:** `var pulso := 0.0` e `var play_desde := -1.0` (o main
põe); `var batidas := 0.0` (o main põe a cada quadro); o desenho da tabela de
A cena; o cassete inteiro (do mostrador ao botão, menos o mostrador) desloca
`720 * ease_in_cubic(clampf((batidas - play_desde) / 4.0, 0, 1))` px em y
depois do PLAY.

**`Desenho`:** copiar de `godot/estudos/direcao/hud.gd` as funções `caixa`,
`carretel` e `contador`, com os tokens de `Tema` no lugar de `Fita` e o texto
do contador por `Desenho.texto` (a coleta da F09 precisa de todo texto).

**`TelaIntro`** (`godot/scripts/ui/tela_intro.gd`, `extends Control`):

```gdscript
const DURACAO := 24.0
const TOM_DO_LUGAR := [1.0, 1.1225, 1.3348, 1.4983]  ## Dó, Ré, Fá, Sol
const ACENDE := [12.5, 14.0, 15.5, 17.0]
var t := 0.0
var acabou := false
func comecar(salao: Salao, jogadores: Array) -> void
func quadro(dt: float) -> void          # anda a linha do tempo; o main chama no estado "intro"
func terminar() -> void                 # devolve o salão e os bonecos ao normal (também quando pula)
func pose_da_camera() -> Array          # [posição, olhar]
```

`quadro()` toca os sons da tabela de O som e, ao acender o lugar `l`, chama
`Forja.vibrar(l, 0.3, 0.6, 80)` se `Forja.ocupado(l)`.

**`ForjaPlayer`:**

```gdscript
const INTERVALO_DO_MODELO := ["segunda", "quinta_baixo"]
## A armadura apagada (0: o corpo em Tema.GRAFITE, sem o anel) ou acesa (1:
## como o _vestir deixou). A G08 mantém este contrato no shader novo.
func acender(k: float) -> void
func cabeca(visivel: bool) -> void  # mostra ou esconde a malha "head-mesh"
```

`acender` guarda os materiais que `_vestir()` cria numa lista `_roupas`
(esvaziada quando `visual()` troca de modelo), e põe
`m.albedo_color = Tema.GRAFITE.lerp(<a cor que o _vestir deu>, k)` e
`aro.visible = k >= 0.5`.

**`Salao`:**

```gdscript
var luz_da_forja: OmniLight3D   # a luz de _bigorna(), fora de _tochas
var pulso := -1.0               # 0..1: o título e a introdução mandam; -1: tremula como hoje
var apagado := 0.0              # 0..1: a Dissonância apaga tochas e forja
```

**O robô do fluxo** (a regra 2 da paridade): `_robo(dt)` no main, chamada
numa linha só, `if Forja.robo: _robo(dt)`, no fim de `_process`. Só aperta
botões no controle simulado (`Forja.robo_apertar`):

| estado | o robô |
| --- | --- |
| `titulo` | espera 3,0 s e aperta ✕ no primeiro lugar com controle conectado (`Forja.lugar(l).get("conectado", false)`) |
| `intro` | nada: a introdução acaba sozinha em 24 s |
| `lobby` | a cada 0,6 s, aperta ✕ em cada lugar com controle que ainda não está pronto (a G02 troca este ramo pelo robô da construção) |

## Passos

`bash tests/prova_do_jogo.sh` depois dos passos 3, 6 e 9.

1. **`lente.gd`** e **`desenho.gd`** (`caixa`, `carretel`, `contador`);
   `"$GODOT" --headless --path godot --import --quit` para o `lente.gd.uid`.
2. **Os sons:** os quatro passos de «Como o som chega ao jogo» e o `pio`.
3. **`player.gd`:** `INTERVALO_DO_MODELO`, `_roupas`, `acender`, `cabeca`.
4. **`musica.gd` e `salao.gd`:** `"titulo": [60, 115, 1]` em `FAIXAS`; em
   `Salao._bigorna()`, guardar a luz em `luz_da_forja` e **tirar**
   `_tochas.append(forja)` (linha 313); em `Salao._process`, a energia de cada
   tocha × `(1.0 - apagado)` e
   `luz_da_forja.light_energy = ((0.5 + 3.0 * pulso) if pulso >= 0.0 else (1.6 + 0.25 * sin(_t * 7.3))) * (1.0 - apagado)`.
5. **`tela_titulo.gd`:** o desenho de A cena; apagar tudo o que fala de
   módulo, USB/BT e versão.
6. **`tela_intro.gd`** (novo) e o import para o `.uid`. `comecar()` zera `t`
   e `acabou` e mostra os quatro bonecos em `salao.pedestais[l]`
   (`visible = true`, `rotation.y = 0`, `animar("static")`, `cabeca(false)`,
   `acender(0.0)`). `terminar()` volta `salao.pulso = -1.0`,
   `salao.apagado = 0.0`, `cabeca(true)`, `acender(1.0)` e `animar("idle")`.
7. **`main.gd`:**
   - `var intro: TelaIntro` criado em `_interface()` junto das outras telas
     (antes da `cortina`), `visible = false`; `var _viu_a_intro := false`,
     `var _t_titulo := 0.0`, `var play_ms := -1`;
   - `_mostrar()`: `intro.visible = qual == "intro"`; a música: `"titulo"` e
     `"intro"` pelo relógio da batida (O alvo), o resto como hoje;
     `salao.pedestais_no.visible = qual in ["lobby", "podio", "intro"]`; ao
     mostrar `"titulo"`, `_t_titulo = 0.0` e `titulo.play_desde = -1.0`;
     o foco do título (A cena) liga só em `"titulo"`;
   - `_quadro_titulo()`: no lugar de `_trocar(_ir_para_o_lobby)`, chamar
     `_dar_play(l)` com o lugar de quem apertou (sem módulo, o lugar 0); o
     corte de O alvo; antes das checagens, o pio:
     ```gdscript
     for p in Forja.pads():
     	var l := int(p.lugar)
     	if l < 0:
     		continue
     	for b in [Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO, Forja.TRIANGULO, Forja.OPTIONS]:
     		if Forja.pad_apertou(int(p.pad), b):
     			Som.pio(l, jogadores[l].modelo_i)
     			Forja.vibrar(l, 0.0, 0.45, 60)
     			Forja.gatilhos_off(l)
     			break
     ```
     e, a cada quadro: `_t_titulo += dt`, `titulo.batidas = _batidas_do_titulo()`,
     o `pulso` de A cena em `salao.pulso` e `titulo.pulso`;
   - `_ir_para_a_intro()`: `_viu_a_intro = true`, `_mostrar("intro")`,
     `intro.comecar(salao, jogadores)`;
   - `_quadro_intro(dt)`: `intro.quadro(dt)`; se `intro.t > 0.5` e algum pad
     apertou ✕ ○ □ △ ou Options (sem módulo, `Forja.apertou(0, Forja.CRUZ)`),
     ou `intro.acabou`:
     `_trocar(func() -> void: intro.terminar(); _ir_para_o_lobby())`;
   - `_process`: `"intro": _quadro_intro(dt)` no `match`;
   - `_pose_da_camera()`: `"titulo"` e `"intro"` como em A cena (o push-in:
     a distância × `(1.0 - 0.03 * ease_in_out(fmod(batidas, 32.0) / 32.0))`);
     `_mover_camera`: o `k` de 1,2 vale para `"titulo"` e `"intro"`;
   - `_ready()`: `Forja.registrar("FORJA %s" % Forja.versao())`.
8. **`main.gd`, o robô do fluxo:** `_robo(dt)` da tabela, com
   `var _robo_estado := ""` e `var _robo_espera := 0.0` (ao mudar de estado,
   3,0 s no título e 0,6 s no lobby); nada roda com `_trocando` ou com overlay
   aberto. Nenhum outro `Forja.robo` entra no main.
9. **`traducoes.gd`:** se faltar, `"Nenhum controle encontrado": "No controller found"`,
   `"Jogar no teclado": "Play on the keyboard"`, `"Gravar": "Record"`,
   `"Créditos": "Credits"`, `"Nove salas, quatro cavaleiros": "Nine rooms, four knights"`.
   «A FORJA» é nome próprio: não traduz.
10. **As provas e as fotos** (Provas).

## Armadilhas

- **`.uid`:** `tela_intro.gd` e `lente.gd` são scripts novos; commitar os
  `.uid`.
- **Tudo em `_draw()` e pela coleta:** o título e a estática são desenho 2D,
  todo texto por `Desenho.texto` ou `Glifo.dica`; nada de `Label` novo.
- **Texto por `Traducoes`, com maiúscula** (F07). A introdução não tem texto.
- **O robô só aperta:** nenhuma condição `Forja.robo` fora de `_robo` (a
  checagem da F08 reprova). O robô não pula a introdução.
- **Os roteiros com `--robo` não apertam mais no título nem no lobby:** um ✕ a
  mais do roteiro cai na introdução e a pula, ou confirma alguém fora de hora.
- **O ✕ que deu o PLAY não pula a introdução:** a guarda de 0,5 s.
- **O corte espera o tempo 1:** do PLAY ao corte vão de 4 a 8 batidas (2,1 a
  4,2 s a 115 BPM). Sem música (sem módulo), o relógio é `_t_titulo`.
- **Lugar vazio:** na introdução os quatro bonecos aparecem mesmo sem jogador;
  `_ir_para_o_lobby` → `_sincronizar_jogadores()` esconde os vazios.
  `terminar()` roda também quando se pula. A martelada só vibra lugar ocupado.
- **`_tochas` sem a forja:** se a luz da forja ficar nas duas listas, ela
  pisca.
- **O WAV do alto-falante precisa de PCM:** `compress/mode=0` no `.import`;
  com compressão, `w.data` não é PCM16 e o pio sai ruído.
- **O pio só toca para quem tem lugar:** `p.lugar < 0` não toca.
- **Os temperamentos e os casos que quebram:** `--robo=bom|medio|ruim`,
  partidas com 1 e 2 jogadores e o `simulador_cabo`. Com o P1 fora, o robô
  aperta no primeiro lugar conectado; a introdução acaba sozinha.

## Não fazer

- Nenhum texto na introdução, nenhuma pergunta, nenhum «olhe o LED».
- Não mexer no lobby além do ramo do robô (a construção é a G02).
- Não criar áudio novo: só copiar os WAV já gerados.
- Não mostrar na tela «módulo», «relatório», USB/BT, versão.
- Não tingir as armaduras na cor do lugar ao acender: `acender` só tira o
  cinza (a cor do corpo é da G08).

## Pronto quando

Alguém que nunca viu o jogo liga, vê o cassete com a forja pulsando atrás,
aperta ✕, ouve o pio e o PLAY e sente o motor da fita na mão, vê o cassete
afundar e a introdução de 24 s sem uma palavra (ou a pula com qualquer botão)
e chega à construção; `--simular=4 --robo` faz o mesmo caminho sozinho, e a
prova mede o pio, o PLAY e as quatro marteladas nos controles certos.

E só fecha com `bash tests/prova_visual.sh` passando e a prancha olhada; a
aparência só se aprova na máquina do André, com placa de vídeo, sem
`--fixed-fps`.

## Provas

**Na sessão:** `bash tests/prova_do_jogo.sh`.

Em `godot/testes/prova_do_jogo.gd`, `_prova_do_percurso()`: **trocar** o
trecho que vai de `_esperar(jogo.estado == "titulo", …)` até o
`_esperar(jogo.estado == "lobby", …)` por:

```gdscript
	_esperar(jogo.estado == "titulo", "o jogo abre no título")
	# o título: quem aperta ✕ é o robô do fluxo (main.gd _robo), no controle do P1
	var pio := [0.0, 0.0]
	var fita := 0.0
	var q := 0
	while jogo.estado == "titulo" and q < 900:
		await _quadros(1)
		q += 1
		for l in 2:
			pio[l] = maxf(pio[l], float(Forja.som_virtual(l).get("falante", 0.0)))
		if jogo.play_ms >= 0:
			fita = maxf(fita, float(_perc(0).get("fraco", 0.0)))
	_esperar(jogo.play_ms >= 0, "o ✕ no título deu o PLAY")
	_esperar(fita > 0.0, "o PLAY vibrou no controle do P1 (%.2f)" % fita)
	_esperar(pio[0] > 0.05, "o pio do P1 saiu no alto-falante do P1 (%.2f)" % pio[0])
	_esperar(pio[1] < 0.02, "e não no do P2 (%.2f)" % pio[1])
	_esperar(jogo.estado == "intro", "o PLAY leva à introdução")
	_esperar(int(round(jogo._batidas_do_titulo())) % 4 <= 1, "o corte caiu no tempo 1")
	var armaduras := 0
	var martelou := [false, false, false, false]
	q = 0
	while jogo.estado == "intro" and q < 1800:
		await _quadros(1)
		q += 1
		for l in 4:
			martelou[l] = martelou[l] or float(_perc(l).get("forte", 0.0)) > 0.0
		if jogo.intro.t > 18.0:
			var n := 0
			for p in jogo.jogadores:
				if p.visible:
					n += 1
			armaduras = maxi(armaduras, n)
	_esperar(armaduras == 4, "a introdução acende as quatro armaduras (%d)" % armaduras)
	for l in 4:
		if Forja.ocupado(l):
			_esperar(martelou[l], "a martelada do P%d chegou à mão dele" % (l + 1))
	_esperar(q >= 60 * 20, "a introdução dura mais de 20 s sem ninguém apertar (%d quadros)" % q)
	_esperar(jogo.estado == "lobby", "a introdução acaba sozinha e leva à construção")
```

(A esta altura, só os lugares que já entraram estão ocupados; com
`--simular=4` e o robô, o P1. A checagem vale para quem estiver.)

O resto do lobby continua como a F04 deixou, com uma diferença: o robô do
main aperta ✕ em cada lugar a cada 0,6 s. **Tire** os
`_aperta(s, Forja.CRUZ)` que faziam os quatro entrarem e ficarem prontos; os
testes de ◀▶ (P2) e ▲▼ (P3) continuam, apertados logo que
`Forja.ocupado(1)` e `Forja.ocupado(2)` ficam verdadeiros. A espera do salão
passa a ser um laço:
`while (jogo.estado != "salao" or jogo._trocando) and q < 1200`.

Em `godot/testes/captura_jogo.gd` (fotos de divulgação; os roteiros têm de
continuar andando):

- `_roteiro_das_telas` (sem robô): depois de `["aperta", 0, Forja.CRUZ]`,
  `["espera", 60], ["foto", "play"], ["espera", 640], ["foto", "introducao"], ["espera", 420], ["foto", "introducao_armaduras"], ["aperta", 0, Forja.CRUZ], ["espera", 40]`.
- `_roteiro_dos_extras` (sem robô): depois do ✕ do título,
  `["espera", 300], ["aperta", 0, Forja.CRUZ], ["espera", 40]` (pula a
  introdução) antes dos ✕ do lobby.
- `_roteiro_das_salas`, `_roteiro_da_partida` (com `--robo`): trocar os
  `["aperta", …]` do título e do lobby por `["ate", no_salao]`.
- `_roteiro_do_trailer` (com `--robo`): tirar os ✕ do título e do lobby;
  depois de `["espera", 200]`,
  `["ate", func() -> bool: return jogo.estado == "intro"], ["espera", 240], ["aperta", 0, Forja.CRUZ]`,
  e esperar o salão antes das salas.

**A prova visual (F09):** `bash tests/prova_visual.sh` com as quatro partidas;
a prancha `prancha-titulo.png` com o título, o PLAY (o cassete pela metade) e
as quatro armaduras acesas; nas partidas de 1 e 2 jogadores, o mesmo caminho.
A checagem de texto da F09 roda no título (nada abaixo de 30 px, nada fora da
área segura).

## Para o André (local)

1. `bash tests/prova_visual.sh` sem `--fixed-fps`, com a placa de vídeo: o
   título ao lado do `07_titulo.jpg`, a forja fora de foco atrás, a escuridão
   da introdução e as quatro armaduras. Anotar no diário.
2. `./run-local.sh` com dois DualSense: ✕ num e ○ no outro no título; cada pio
   sai só no controle que apertou; o PLAY vibra só em quem deu o ✕; na
   introdução, cada controle sente a sua martelada. Na segunda abertura,
   pular com qualquer botão.
3. `./run-local.sh -- --simular=4 --robo`: o robô passa do título à
   construção sem ninguém tocar.

## Ao terminar

No [quadro](README.md), G01 **feito** com o commit e o gasto. Commit
sugerido (sem trailer):

```
feat: o título é a fita no deck, o PLAY na mão de quem apertou e a introdução sem texto
```

## O que foi feito (leva 1, o-cavaleiro)

- **O título** (`ui/tela_titulo.gd`, reescrito): o cassete em `_draw` (caixa, carretéis que giram, contador da noite), a forja desfocada
  atrás (`CameraAttributesPractical` ligado só no título), a lente de 85 mm (`mundo/lente.gd`, `Lente.fov`), o push-in de 3 % em 8
  compassos (parado com `Opcoes.tremor` desligado), a forja que pulsa na batida da faixa. Tudo por token do tema, sem `Label`.
- **O PLAY e o pio:** ✕ ou Options dá o PLAY (`fx_play` na TV, a sensação `fita` na mão de quem apertou, o cassete desce) e o corte
  espera o próximo tempo 1; qualquer dos cinco botões de um controle com lugar dá o pio dele (`Som.pio`, TV e alto-falante do dono,
  `Forja.sentir(l, "toque")`). △ abre os créditos. O controle sem lugar que aperta ✕ ou Options se senta na hora
  (`Forja.entrar`, registro «P%d entrou»), e o título acha de novo o alto-falante de cada controle a cada lugar que se ocupa
  (`Forja.som_preparar`), porque o módulo só acha o som de quem já ocupa o lugar; `Forja.som_encerrar` ao sair.
- **A introdução** (`ui/tela_intro.gd`, novo, estado `"intro"`): 24 s sem uma palavra, a Dissonância que apaga a forja, a estática,
  as quatro armaduras que acendem aos 12,5, 14, 15,5 e 17 s, cada uma com a nota do lugar e uma martelada na mão do dono
  (`Forja.sentir(l, "acerto")`); qualquer botão a pula depois de 0,5 s; só na primeira vez da sessão. Os bonecos ficam `preso` para
  o `idle` não anular a pose da estática.
- **O som:** `fx_play` e os 24 `pio_p?_*` entram em `godot/assets/sons/` (com `compress/mode=0` no `.import`) e `Som` toca por arquivo
  do mapa (`Som.arquivo`, `tocar`, `no_controle`); as 25 linhas do `mapa.csv` passam a «no jogo»; `Musica.FAIXAS["titulo"]`.
- **O robô** (`main.gd _robo`): no título aperta ✕ no primeiro lugar com controle após 3 s e repete a cada 3 s; no lobby, a cada
  0,6 s, em cada lugar com controle que não está pronto; não pula a introdução. `Forja._robo_apertar_cru` acha o controle pela
  reserva (o controle do lugar ainda não ocupado).
- **Tokens:** o bloco da Fita no fim de `tema.gd` (só o que a G01 e a G02 usam) e `Desenho.caixa/carretel/contador`.
- **As provas** (`prova_do_jogo.gd`, `captura_jogo.gd`, `prova_visual.gd`): o título deixa de ser um ✕ solto; o laço mede o PLAY na
  mão do P1, o pio só no alto-falante do P1, o corte no tempo 1, as quatro armaduras, a martelada em cada mão e a duração de mais de
  20 s. O laço do título espera pelo relógio de parede, porque a batida segue a placa de som e a prova, sem janela, anda mais
  depressa que ela. Os roteiros de captura e a prova visual deixam o robô passar do título ao salão.
- **Mordidas:** sem `Som.pio`, sem `Forja.sentir(l, "fita")` e sem o `sentir` da martelada, a prova reprova as três linhas; devolvidas
  as três, verde nas duas rodadas.

### O que fica para a mão

Está em «Para o André (local)» acima. O que só a mão e a placa de vídeo provam: o título ao lado do `07_titulo.jpg`, o foco da forja
atrás, a escuridão da introdução, o pio saindo só no controle que apertou e a martelada em cada mão. Atenção a um ponto novo: o
primeiro ✕ de um controle que ainda não tinha lugar senta o controle e acha o alto-falante dele no mesmo quadro; com controle de
verdade a procura de dispositivos de som (`pactl`) pode custar um instante antes do clunk. Conferir se o PLAY sai sem engasgo.
