# G02 — A construção do cavaleiro

**Sprint:** G · **Tamanho:** G · **Depende de:** F00, F04 (o lugar e o ✕ que confirma), F05 (`Forja.sentir`), F06 (o registro v2), F07 (o texto), F08 (o robô só aperta), F09 (a prova visual e `Forja.robo_acerta`), G01 (`acender`, `Som.pio`) · **Usado por:** G03 (`ITENS`, `_sentir_o_item`, `_forjou`), G04 (`ForjaPlayer.nome`), G06 (`ACABAMENTOS`, `Opcoes.noite()`), G08 (o acabamento no shader), G09 e G13 (a coluna, a forja e o robô)

## Por quê

Não há criação de personagem. O lobby de hoje é um seletor no pé do pedestal,
◀▶ e ▲▼ sem som nem peso, e ninguém sabe o atraso do próprio controle. Esta
ficha troca o lobby pela construção: cada lugar tem uma coluna de 432 px, três
linhas, e as 8 marteladas na batida que forjam o cavaleiro e, sem ninguém ver,
medem o atraso de cada controle. A peça por peça (cabeça, superior, inferior,
stats) é da G13; esta ficha deixa o fluxo, a forja e o que se guarda.

## Ler antes

- [A tela de montagem](../arte/04-o-cavaleiro.md#a-tela-de-montagem) (a coluna, os botões, a forja)
- [A calibração que ninguém vê](../04-ritmo-e-audio.md#a-calibração-que-ninguém-vê)
- [O registro v2](../13-arquitetura.md#o-registro-v2--f06-h01-h02-g02-h07) (os tipos `calibracao` e `cavaleiro`)

## Arquivos que mudam

| arquivo | também muda em |
| --- | --- |
| `godot/scripts/ui/tela_lobby.gd` (reescrito; a classe `TelaLobby` continua) | **G03, G08, G09, G13** |
| `godot/scripts/ui/cartao_jogador.gd` (passa a ser a coluna do lugar) | **G13** |
| `godot/scripts/main.gd` (`_mostrar`, `_quadro_lobby`, `_robo`, `_interface`, `_process`) | **G01, G03, G04, G05, G06, G07, G08, G09, G11, G13, G14, G15, G16** |
| `godot/scripts/player.gd` (`ITENS`, `ACABAMENTOS`, `nome`, `cavaleiro`, `vestir`, `_aplicar_acabamento`) | **G01, G03, G06, G08, G10, G13, G14, G15** |
| `godot/scripts/opcoes.gd` (`cavaleiro`, `noite_dos_cavaleiros`, `noite`, `guardar`) | **F05, G06, G13, G16** |
| `godot/scripts/musica.gd` (`FAIXAS`) | **G11, G16** |
| `godot/scripts/mundo/salao.gd` (as bigornas) | **G06, G08, G13** |
| `godot/scripts/forja.gd` (`SENSACOES["metal"]`) | **F05** |
| `godot/scripts/ui/glifo.gd` (os seis ícones de item) | **G04, G11, G13** |
| `godot/scripts/traducoes.gd` | **todas as G com texto** |
| `godot/assets/sons/ui_peca.wav`, `ui_confirma.wav`, `ui_volta.wav`, `fx_caneta.wav` e os `.import`; `docs/jogo/audio/mapa.csv` | **G01, G03, G04, G06, G07, G09, G11, G12, G13, G16** |
| `docs/jogo/13-arquitetura.md` (a linha `cavaleiro` do registro) | **G13** |
| `godot/testes/prova_do_jogo.gd` | **todas as G** |
| `godot/testes/captura_jogo.gd` (`_roteiro_das_telas`, `_roteiro_dos_extras`, o passo `ate_pronto`) | **G16** |

## Como se joga

Cada lugar ocupado tem a sua coluna. A tela inteira roda na música da
construção, a 120 BPM (a batida tem 500 ms).

| botão | editando | forjando | forjado | guardado (cavaleiro desta noite) |
| --- | --- | --- | --- | --- |
| ▲ ▼ | a linha: Boneco, Arma ou amuleto, Nome (para nas pontas) | — | — | — |
| ◀ ▶ | Boneco: Humano ↔ Orc; Arma ou amuleto: os seis itens em laço (nunca Mãos livres); Nome: o próximo dos 24 que nenhum outro lugar usa | — | — | — |
| △ | sorteia boneco, item e nome livre | — | — | — |
| ✕ | começa a forja, de qualquer linha | uma martelada | — | confirma (fica forjado) |
| ○ | linha 2 ou 3: vai à linha 1; linha 1: sai do lugar (`Forja.sair(l)`) | cancela (as marteladas zeram) | desfaz a forja (volta a editar) | refaz (volta a editar, linha 1) |
| Options | a pausa; nela, «Opções» abre as opções do lugar | igual | igual | igual |

- **A forja:** o ✕ apaga o cavaleiro (`acender(0.0)`). Cada ✕ seguinte é uma
  martelada: o cavaleiro acende um oitavo, a bigorna brilha e a mão sente.
  Na oitava, o cavaleiro está aceso, faz o aceno, o pio sai do controle e o
  lugar fica forjado. Qualquer ✕ conta; o tempo de cada um é a medida.
- **A partida começa** 1,6 s depois de todo lugar ocupado e com controle estar
  forjado (como hoje). Com 1 jogador, assim que ele forja.
- **Quem volta na mesma noite** (pela pausa, ou fechando e abrindo o jogo)
  acha o cavaleiro guardado: ✕ confirma, ○ refaz.
- Nenhum número na tela. A calibração é «a armadura ficando pronta».

## A cena

- **Câmera:** a de hoje, sem mudança: `main.gd:932`,
  `[Vector3(0, 2.9, 14.2), Vector3(0, 0.55, 4.4)]`, 40°. A cerca de 148 px
  por metro na altura dos pedestais, os pedestais (x = −4,2 + 2,8·i, z = 4,4)
  caem em x de tela ≈ 338, 753, 1167, 1582. Os centros das colunas de 432 px
  (x = 96 + 432·i + 216) são 312, 744, 1176, 1608. O cavaleiro cai dentro da
  sua coluna sem mexer na câmera. O plano de 50 mm é da G13.
- **A coluna de cada lugar** (tela lógica 1920 × 1080, `x0 = 96 + 432·l + 10`,
  largura útil 412):

| y (px) | o que tem |
| --- | --- |
| 60 a 150 | a placa: «P1» à esquerda, o nome do cavaleiro à direita, as lâmpadas do lugar embaixo do P#, «Forjado» embaixo do nome |
| 160 a 600 | o cavaleiro em 3D, no pedestal (nada desenhado) |
| 610 a 650 | vazio (a etiqueta do arquétipo é da G13) |
| 660, 700, 740 | as três linhas, 40 px cada (38 de altura): Boneco, Arma ou amuleto, Nome |
| 870 a 1010 | as 8 marteladas: quadrados de 24 × 24 com vão de 10, centrados (x0 + 75 a x0 + 337), em y 880 |
| base 1046 | uma fileira de dicas para a tela toda |

- **A bigorna de cada lugar** (`salao.gd`, `_pedestais()`): `Kit.bigorna(pedestais_no, pos + Vector3(0.62, 0.32, -0.5), 0.3)`
  com `rotation.y = -0.5`, e uma `OmniLight3D` em `pos + Vector3(0.62, 0.9, -0.5)`,
  `light_color = Tema.LARANJA`, `omni_range` 1,6, sombra desligada, energia
  0. O brilho é quente e baixo: não tinge o cavaleiro.
- **Luz:** nenhuma outra muda.

## O som

| quando | id do mapa | onde | volume e tom |
| --- | --- | --- | --- |
| ▲ ▼ troca a linha | `tique` (`tique_0..2`, já no jogo) | alto-falante do dono: `Som.no_controle(l, "tique", 0.6)` | ganho 0,6 |
| ◀ ▶ ou △ no Boneco | `ui_peca` | TV `Som.tocar("ui_peca", null, -12.0, 1.0)` e `Som.no_controle(l, "ui_peca", 0.85)` | −12 dB, tom 1,0 |
| ◀ ▶ ou △ no item | `ui_peca` (em `_sentir_o_item`, que a G03 troca) | TV `Som.tocar("ui_peca", null, -12.0, 0.7492)` e o alto-falante do dono | −12 dB, −5 semitons |
| ◀ ▶ no Nome | `fx_caneta` | TV `Som.tocar("fx_caneta", null, -6.0)` | −6 dB |
| ✕ começa a forja, ✕ confirma o guardado | `ui_confirma` | TV `Som.tocar("ui_confirma", null, -12.0)` e `Som.no_controle(l, "ui_confirma", 0.85)` | −12 dB |
| ○ (qualquer) | `ui_volta` | TV a −12 dB e o alto-falante do dono | −12 dB |
| cada batida, enquanto algum lugar forja | `tique` | TV `Som.tocar("tique", null, -10.0)` | −10 dB |
| cada martelada | `martelo` (`martelo_0..4`, já no jogo) | TV na posição do cavaleiro: `Som.tocar("martelo", jogadores[l].global_position, -4.0)` | −4 dB |
| a oitava martelada | o pio (`pio_p{l+1}_{intervalo}`) | `Som.pio(l, jogadores[l].modelo_i)` (G01: TV e alto-falante) | −12 dB |
| a música | `MUS_TELA_CONSTRUCAO` | TV, pelo `Ritmo` | `Musica.VOLUME_DB` |

Os tons: +7 semitons = 1,4983; +4 = 1,2599; 0 = 1,0; −5 = 0,7492. Esta ficha
usa só 1,0 e 0,7492 (a G13 usa os quatro).

**O encanamento dos quatro sons** (igual nas fichas G01, G03, G09, G11, G12,
G13 e G16; quem chega primeiro faz, quem chega depois confere): o git só
tem o `.ogg` do estudo; o `.wav` sai do gerador, direto no jogo:
`python3 godot/estudos/direcao/som/gerar_sons.py --so ui_peca --fita leve --saida godot/assets/sons --sem-ogg`,
e o mesmo para `ui_confirma` e `ui_volta` (`--fita leve`) e `fx_caneta`
(`--fita cheia`), como diz a coluna `receita` do mapa;
`"$GODOT" --headless --path godot --import --quit`; conferir
`compress/mode=0` em cada `.wav.import`; `Som.tocar` e `Som.no_controle`
tocam primeiro `res://assets/sons/<nome>.wav` quando ele existe; no
`docs/jogo/audio/mapa.csv`, as quatro linhas ganham `arquivo` =
`godot/assets/sons/<id>.wav` e `estado` = `no jogo`.

**A música:** em `musica.gd`, `FAIXAS["MUS_TELA_CONSTRUCAO"] = [57, 120, 1]`
(Lá, 120 BPM, energia 1). `Musica.TELAS` já leva `"lobby"` a
`"MUS_TELA_CONSTRUCAO"`. `Musica.mapa("MUS_TELA_CONSTRUCAO")` dá
`bpm_sintetizado(120)` = 120 exatos (24 000 amostras por tempo a 48 kHz).
Quando o `.ogg` da H05 chegar (`godot/assets/ost/telas/MUS_TELA_CONSTRUCAO.ogg`,
hoje «a fazer» no mapa), o `mapa` passa a ler o `.batidas.json` dele sem
mudança aqui.

## O controle

| evento | para quem | vibração (`Forja.sentir`) | gatilho | luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| ▲ ▼ | o dono | `"toque"` (0/0,45/60) | — | — | `tique` |
| ◀ ▶ ou △ no Boneco ou no Nome | o dono | `"metal"` (0/0,45/40, nova) | — | — | `ui_peca` (Boneco) |
| ◀ ▶ ou △ no item | o dono | `"acerto"` (0,3/0,6/80), em `_sentir_o_item` | o do item (G03) | — | `ui_peca` |
| ✕ começa a forja, ✕ confirma | o dono | `"acerto"` | — | — | `ui_confirma` |
| cada martelada | o dono | `"acerto"` | — | — | — (o martelo é da TV) |
| a oitava | o dono | `"perfeito"` (0,5/0,8/100) | — | — | o pio |
| ○ | o dono | `"toque"` | — | — | `ui_volta` |
| sair do lobby | os quatro | — | `Forja.gatilhos_off(l)` | — | — |

A sensação nova, em `forja.gd` (a tabela da F05):
`SENSACOES["metal"] = [0.0, 0.45, 40]`: o pulso curto da troca de peça (o
03 pede 150 Hz nos atuadores; com o motor, 0/0,45 por 40 ms).

Sem o controle na mão: `Forja.ctl.percepcao(Forja.pad_do_lugar(l))` traz
`forte` e `fraco`; `Forja.som_virtual(l).falante` mede o alto-falante.

## O cavaleiro

- **Os stats:** nenhum aqui. As peças, os stats, o arquétipo e a liga são da
  G13.
- **O item** é o índice de `ForjaPlayer.ITENS` (a ordem é a da G03): 0 Mãos
  livres, 1 Martelo, 2 Escudo, 3 Fole, 4 Lanterna, 5 Diapasão, 6 Âncora. A
  construção escolhe de 1 a 6. A mecânica e a peça 3D são da G03.
- **O acabamento** (Fosco, Polido, Riscado, Dourado) não tem linha aqui: o 04
  manda escolher no salão (G06). `acabamento_i` fica no cavaleiro guardado e
  muda só a rugosidade e o metal, nunca a cor.
- **O boneco:** os dois de hoje (`MODELOS`, Humano e Orc). A G08 troca a
  lista; a G13 troca o boneco por três peças.

## As reações

Não se aplica: a construção não dispara adesivo nem carimbo.

## A diversão

**O momento:** na oitava martelada o cavaleiro, que estava cinza, termina de
acender, acena, e o pio sai do controle de quem forjou. Quatro pessoas
martelando juntas na batida, sem saber que estão sendo medidas. **Como se
confere:**

1. A prova do jogo mede as 8 marteladas dos quatro, o desvio do P1 entre 0 e
   70 ms e o do P4 de 70 a 130 ms depois do P1 (o robô atrasa 33 ms por
   lugar).
2. A linha do tempo tem quatro linhas `calibracao` com `origem` `construcao`
   e `amostras` 8.
3. Na noite de teste: quatro pessoas forjam em menos de dois minutos, e
   ninguém pergunta «o que é isso?» nas marteladas (o jogador do time anota).

## O estado de hoje

- `godot/scripts/ui/tela_lobby.gd` (113 linhas): `prontos`, `contagem`,
  `pes`, `visual`, quatro `CartaoJogador` de 384 × 300 no pé da tela
  (`_posicionar`, 33), o título e a linha de estado em `_draw` (47), o
  seletor no pé do pedestal (`_seletor`, 94).
- `godot/scripts/ui/cartao_jogador.gd` (96 linhas): nome do aparelho,
  VID:PID, origem, «Luz», «LEDs», bateria.
- `godot/scripts/main.gd`:
  - `_mostrar(qual)` (215): `Musica.tocar(qual)`. Sem entrada `"lobby"` em
    `FAIXAS`, o lobby toca a do salão.
  - `_quadro_lobby(dt)` (592-649): ✕ de pad sem lugar entra; △ abre as
    opções do lugar; ◀▶/▲▼ chamam `p.visual(p.modelo_i + dx, p.item_i + dy)`
    com `Forja.vibrar(l, 0.0, 0.25, 40)`; ✕ fica pronto e grava
    `Forja.evento("visual", …)`; ○ desfaz ou sai; com todos prontos,
    `lobby.contagem = 1.6`. Não chama `_atalhos_de_overlay()`.
  - `_atalhos_de_overlay()` (726): Options abre a pausa em qualquer estado
    que o chame; o salão chama (652).
  - `_process` (544-549): a cada quadro o main põe `lobby.pes[l]` e
    `lobby.visual[l]`.
  - `_passo(l, vertical)` (816): a borda do analógico e do d-pad.
  - `_pose_da_camera()` (925), ramo `"lobby"` (932).
- `godot/scripts/ui/pausa.gd:25`: a pausa já lista «Opções»
  (`["opcoes", "Opções"]`); no lobby a lista é Continuar, Opções, Voltar ao
  lobby, Sair do jogo.
- `godot/scripts/player.gd`: `MODELOS` (14), `ITENS` (17, os sete antigos:
  espada, lança, poção, chave), `VISUAL_DO_LUGAR` (27), `POSE_DO_ITEM` (32),
  `montar` (60), `visual(m, item)` (107), `_segurar` (132), `_vestir` (156),
  `gesto` (185). A G01 deixou `acender(k)` e `Som.pio(lugar, boneco)`.
- `godot/scripts/ritmo.gd`: `tocar(slot, bpm, primeiro_tempo)` (65),
  `parar()` (84), `t_musica()` (105), `batida()` (110), `t_da_batida(n)`
  (115), `definir_desvio(l, segundos, origem, amostras)` (228), que grava
  `Opcoes.tempo_ms[l]` (entre `TEMPO_MIN` −150 e `TEMPO_MAX` 250) e o
  evento `calibracao` com o `transporte`.
- `godot/scripts/opcoes.gd`: `tempo_ms` (38), `de_fabrica` (49), `gravar`
  (89); não há cavaleiro guardado.
- `godot/scripts/mundo/salao.gd:361-392`, `_pedestais()`: quatro discos em
  `Vector3(-4.2 + i * 2.8, 0, 4.4)` com o aro do lugar; não há bigorna por
  lugar. `Kit.bigorna(pai, pos, escala)` existe (`mundo/kit.gd:138`).
- `godot/testes/prova_do_jogo.gd:109-123`: os visuais, ◀▶ do P2, ▼ do P3 e
  ✕ de pronto nos quatro.
- `godot/testes/captura_jogo.gd:265-274`, `_roteiro_dos_extras`: △ do P2 no
  lobby abre as opções.

## O alvo

**O estado continua `"lobby"`** (a pausa, o `--tela=lobby` e as provas usam o
nome). `TelaLobby` e `CartaoJogador` continuam: sem script novo, sem `.uid`
novo.

### `TelaLobby` (`godot/scripts/ui/tela_lobby.gd`)

```gdscript
const BONECO := 0
const ITEM := 1
const NOME := 2
const LINHAS := ["Boneco", "Arma ou amuleto", "Nome"]
const EDITANDO := 0
const FORJANDO := 1
const FORJADO := 2
const GUARDADO := 3
const MARTELADAS := 8
const ROBO_ATRASO_S := 0.033   ## o robô do lugar l martela l × 33 ms depois da batida
## Os 24 de docs/jogo/sistemas/nomes.csv, na ordem do arquivo (a G13 passa a ler o csv).
const NOMES := ["Basalto", "Granito", "Bronze", "Tenaz", "Rebite", "Ferrugem",
	"Obsidiana", "Ônix", "Titânio", "Cobalto", "Quartzo", "Cinzel",
	"Brasa", "Carvão", "Latão", "Estanho", "Níquel", "Âmbar",
	"Faísca", "Magnésio", "Cromo", "Safira", "Pirita", "Grafite"]

var prontos := [false, false, false, false]   ## continua: o main conta por ele
var contagem := -1.0
var etapa := [EDITANDO, EDITANDO, EDITANDO, EDITANDO]
var linha := [0, 0, 0, 0]
var golpes := [[], [], [], []]                ## o desvio de cada martelada, em s
var desvio := [0.0, 0.0, 0.0, 0.0]
var jogadores: Array = []                     ## o main põe em _interface()
var salao: Node = null                        ## idem
var _robo_espera := [0.0, 0.0, 0.0, 0.0]
var _robo_batida := [0, 0, 0, 0]
var _robo_erro := [0.0, 0.0, 0.0, 0.0]
var _batida_vista := -1

func abrir() -> void              # zera tudo; cada lugar já ocupado passa por entrou(l)
func entrou(l: int) -> void       # o lugar acabou de confirmar (F04): guardado ou EDITANDO
func quadro(dt: float, dx: Array, dy: Array) -> void   # os botões da tabela, os quatro lugares
func martelar(l: int) -> void
func _forjou(l: int) -> void
func _sentir_o_item(l: int) -> void   # a G03 troca o corpo
func robo(l: int, dt: float) -> void
static func mediana(v: Array) -> float   # ordena; ímpar: o do meio; par: a média dos dois do meio; vazio: 0.0
```

`pes` e `visual` saem (o main para de escrever neles).

- **`entrou(l)`:** com `Opcoes.noite_dos_cavaleiros == Opcoes.noite()` e
  `Opcoes.cavaleiro[l]` não vazio, `jogadores[l].vestir(Opcoes.cavaleiro[l])`
  e `etapa[l] = GUARDADO`. Senão `etapa[l] = EDITANDO`, `linha[l] = 0` e o
  inicial: `jogadores[l].visual(VISUAL_DO_LUGAR[l][0], VISUAL_DO_LUGAR[l][1])`,
  `jogadores[l].nome = NOMES[(Forja.semente * 7 + l * 5) % 24]` (quatro
  diferentes). Nos dois casos, `salao.acender_bigorna(l, 1.5)` e
  `Som.pio(l, jogadores[l].modelo_i)`.
- **O nome livre:** `_nome_livre(l, passo)` anda `passo` (±1) em `NOMES` a
  partir do atual e pula os nomes de `jogadores[j].nome` dos outros lugares
  ocupados.
- **O sorteio (△):** um `RandomNumberGenerator` com
  `seed = Forja.semente * 31 + l + 1000 * n`, sendo `n` quantos sorteios o
  lugar já fez (`var _sorteios := [0, 0, 0, 0]`); `modelo_i =
  rng.randi_range(0, 1)`, `item_i = rng.randi_range(1, 6)`, o nome =
  `_nome_livre` a partir de `rng.randi_range(0, 23)`.
- **Toda troca** (◀ ▶ △): `jogadores[l].gesto("interact-right", 0.5)` e o som
  e o pulso das tabelas. ◀ ▶ no item chama `_sentir_o_item(l)`, que hoje é
  `Som.tocar("ui_peca", null, -12.0, 0.7492)`, `Som.no_controle(l, "ui_peca", 0.85)`
  e `Forja.sentir(l, "acerto")`.

### As 8 marteladas (a calibração)

- **O relógio é o `Ritmo`:** `quadro()` lê `var b := floori(Ritmo.batida())`;
  quando `b != _batida_vista` e algum lugar está em FORJANDO,
  `Som.tocar("tique", null, -10.0)` e `_batida_vista = b`.
- **✕ começa:** `etapa[l] = FORJANDO`, `golpes[l].clear()`,
  `jogadores[l].acender(0.0)`, `_robo_batida[l] = floori(Ritmo.batida()) + 1`,
  `_robo_erro[l] = 0.0`.
- **Cada ✕ em FORJANDO** (`martelar(l)`):

```gdscript
func martelar(l: int) -> void:
	var t := Ritmo.t_musica()
	var d := t - Ritmo.t_da_batida(roundf(Ritmo.batida()))   # até a batida mais perto, em s
	golpes[l].append(d)
	var k: float = golpes[l].size() / float(MARTELADAS)
	jogadores[l].acender(k)
	jogadores[l].gesto("attack-melee-right", 0.35)
	Som.tocar("martelo", jogadores[l].global_position, -4.0)
	Forja.sentir(l, "acerto")
	salao.acender_bigorna(l, 2.5)
	if golpes[l].size() >= MARTELADAS:
		_forjou(l)
```

- **`_forjou(l)`:**

```gdscript
func _forjou(l: int) -> void:
	desvio[l] = mediana(golpes[l])
	Ritmo.definir_desvio(l, desvio[l], "construcao", golpes[l].size())  # Opcoes.tempo_ms e o evento calibracao
	Opcoes.cavaleiro[l] = jogadores[l].cavaleiro()
	Opcoes.noite_dos_cavaleiros = Opcoes.noite()
	Opcoes.guardar()
	etapa[l] = FORJADO
	prontos[l] = true
	jogadores[l].acender(1.0)
	jogadores[l].gesto("emote-yes", 1.2)
	Efeitos.faiscas(salao, jogadores[l].global_position + Vector3(0, 1.6, 0), Forja.cor_do_lugar(l), 24, 1.0)
	Forja.sentir(l, "perfeito")
	Som.pio(l, jogadores[l].modelo_i)
	Forja.evento("cavaleiro", l + 1, jogadores[l].cavaleiro())
	Forja.registrar("P%d forjou o cavaleiro" % (l + 1))
```

- **○ em FORJANDO:** `golpes[l].clear()`, `acender(1.0)`, `etapa[l] = EDITANDO`.
  **○ em FORJADO:** `prontos[l] = false`, `etapa[l] = EDITANDO`; o desvio já
  gravado fica.
- **✕ em GUARDADO:** `etapa[l] = FORJADO`, `prontos[l] = true`; o desvio é o
  guardado em `Opcoes.tempo_ms[l]` (o `Ritmo` já o lê ao abrir).

### O robô da construção

`TelaLobby.robo(l, dt)` (o nome que a checagem da F08 aceita), chamado pelo
`_robo(dt)` do main no estado `"lobby"`, a cada quadro, nos quatro lugares:

```gdscript
## O robô (--robo) constrói pelo controle simulado, como uma pessoa: ✕ para
## forjar e as oito marteladas na batida, o lugar l atrasado l × 33 ms.
func robo(l: int, dt: float) -> void:
	if not Forja.lugar(l).get("conectado", false) or not Forja.ocupado(l):
		return
	if etapa[l] == FORJANDO:
		if Ritmo.t_musica() >= Ritmo.t_da_batida(_robo_batida[l]) + ROBO_ATRASO_S * l + _robo_erro[l]:
			Forja.robo_apertar(l, Forja.CRUZ)
			_robo_batida[l] += 1
			_robo_erro[l] = 0.0 if Forja.robo_acerta() else 0.12   # a mediana absorve um ou dois
		return
	_robo_espera[l] -= dt
	if _robo_espera[l] > 0.0 or etapa[l] == FORJADO:
		return
	Forja.robo_apertar(l, Forja.CRUZ)   # EDITANDO: começa a forja; GUARDADO: confirma
	_robo_espera[l] = 0.9 + 0.1 * l + (0.0 if Forja.robo_acerta() else 1.5)
```

### A coluna (`CartaoJogador`, um por lugar)

`TelaLobby._posicionar()`: `cartoes[i].position = Vector2(96 + 432 * i, 0)`,
`size = Vector2(432, 1080)`. `CartaoJogador._draw()` lê `TelaLobby` pelo
`get_parent()`; tudo em `_draw()`, com `Desenho` e `Glifo`, nenhum `Label`.
Dentro do cartão, `x0 = 10`, `w = 412`.

| o quê | medida | tokens e letra |
| --- | --- | --- |
| a placa | `Desenho.moldura(self, Rect2(x0, 60, w, 90), Tema.PAINEL, Tema.tom_para_a_borda(Forja.cor_do_lugar(l)), 3, Tema.RAIO_CARTAO)` | — |
| «P1» | base y 104, x x0 + 18 | `Tema.fonte(700)`, `Tema.T_CORPO`, `Forja.cor_do_lugar(l)` |
| o nome | base y 104, alinhado à direita em x0 + w − 18, cortado por `Desenho.caber(…, 1)` em 260 px | `Tema.fonte(600)`, `Tema.T_CORPO`, `Tema.FG` |
| as lâmpadas | `Desenho.leds(self, Vector2(x0 + 20, 120), Forja.LEDS_DO_LUGAR[l], 12.0)` | — |
| «Forjado» | base y 142, à direita em x0 + w − 18, só em FORJADO | `Tema.mono(500)`, `Tema.T_MONO`, `Tema.VERDE` |
| «Guardado» | no mesmo lugar, só em GUARDADO | `Tema.mono(500)`, `Tema.T_MONO`, `Tema.SUAVE` |
| as linhas | `Rect2(x0, 660 + 40·k, w, 38)` | — |
| a linha escolhida (EDITANDO) | `Desenho.moldura(self, r, Tema.SEL, Forja.cor_do_lugar(l), 3, 6)` | — |
| o rótulo | x x0 + 12, base r.y + 30 | `Tema.fonte(600)`, `Tema.T_ROTULO`; `Tema.FG` na escolhida, `Tema.SUAVE` nas outras |
| o valor | área de x0 + 136 a x0 + w − 12 (264 px): «◀» na esquerda e «▶» na direita em `Tema.MUDO`; o valor centrado, cortado em 220 px | `Tema.fonte(500)`, 30 px, `Tema.FG` |
| o ícone do item | `Glifo.desenhar(self, ITENS[i].icone, Rect2(x0 + 160, r.y + 3, 32, 32), Tema.FG)`, e o nome do item centrado no que sobra | — |
| as 8 marteladas | `Rect2(x0 + 75 + k·34, 880, 24, 24)` | feitas: `Forja.cor_do_lugar(l)`; por fazer: `Tema.TRILHO` |
| lugar vazio | a placa com borda `Tema.SUTIL` 2 px, «P3» em `Tema.MUDO`; `Glifo.dica(self, Vector2(x0 + 100, 400), "cruz", "Entrar", 30, Tema.FG, Tema.SUAVE)` | — |
| lugar sem controle | a placa por `Desenho.tracejado(self, Rect2(x0, 60, w, 90), Tema.LARANJA, 3.0)`; «Sem controle» no lugar do nome, `Tema.LARANJA` | — |

A fileira de dicas, desenhada pela `TelaLobby` uma vez para a tela:
`Desenho.dicas_a_esquerda(self, Vector2(196, 1046), [["cruz", "Forjar"], ["triangulo", "Sortear"], ["esquerda", "Trocar"], ["circulo", "Voltar"]])`
(o «Botão» sai só na primeira, como a função já faz). Com a contagem
correndo, a fileira dá lugar a «Todos prontos» centrado em `Tema.VERDE`,
`Tema.fonte(600)`, `Tema.T_CORPO`.

### O ícone do item (`godot/scripts/ui/glifo.gd`, em `desenhar()`, grade de 32, traço `t`)

| nome | desenho |
| --- | --- |
| `item_martelo` | `_contorno(ci, [p.call(14,6), p.call(26,14), p.call(22,20), p.call(10,12)], cor, t)`; cabo `ci.draw_line(p.call(16,16), p.call(8,28), cor, t, true)` |
| `item_escudo` | `_contorno(ci, [p.call(8,7), p.call(24,7), p.call(24,16), p.call(16,26), p.call(8,16)], cor, t)` |
| `item_fole` | `_contorno(ci, [p.call(6,10), p.call(20,6), p.call(20,26), p.call(6,22)], cor, t)`; bico `ci.draw_line(p.call(20,16), p.call(28,16), cor, t, true)` |
| `item_lanterna` | `_retangulo_arred(ci, Rect2(p.call(10,10), Vector2(12,16) * k), 3 * k, cor, t)`; alça `ci.draw_arc(p.call(16,10), 4 * k, PI, TAU, 16, cor, t, true)`; chama `ci.draw_line(p.call(16,15), p.call(16,21), cor, t, true)` |
| `item_diapasao` | `ci.draw_line(p.call(12,6), p.call(12,18), cor, t, true)`; `ci.draw_line(p.call(20,6), p.call(20,18), cor, t, true)`; `ci.draw_arc(p.call(16,18), 4 * k, 0, PI, 16, cor, t, true)`; `ci.draw_line(p.call(16,22), p.call(16,28), cor, t, true)` |
| `item_ancora` | `ci.draw_line(p.call(16,8), p.call(16,26), cor, t, true)`; argola `ci.draw_arc(p.call(16,6), 2.5 * k, 0, TAU, 16, cor, t, true)`; travessa `ci.draw_line(p.call(11,11), p.call(21,11), cor, t, true)`; curva `ci.draw_arc(p.call(16,18), 8 * k, 0, PI, 24, cor, t, true)` |

A G04 usa os mesmos ícones no HUD.

### O boneco (`godot/scripts/player.gd`)

```gdscript
## O item: o índice é o de Itens (G03). "id" é o de docs/jogo/sistemas/itens.csv.
const ITENS := [
	{"id": "", "nome": "Mãos livres", "icone": ""},
	{"id": "martelo", "nome": "Martelo", "icone": "item_martelo"},
	{"id": "escudo", "nome": "Escudo", "icone": "item_escudo"},
	{"id": "fole", "nome": "Fole", "icone": "item_fole"},
	{"id": "lanterna", "nome": "Lanterna", "icone": "item_lanterna"},
	{"id": "diapasao", "nome": "Diapasão", "icone": "item_diapasao"},
	{"id": "ancora", "nome": "Âncora", "icone": "item_ancora"},
]
const VISUAL_DO_LUGAR := [[0, 1], [1, 2], [0, 3], [1, 4]]   ## [boneco, item] de cada lugar ao entrar
## O acabamento muda como a luz bate, nunca a cor: o corpo não se tinge
## (arte/04). "livre": false até a coleção (G06). metallic nunca passa de 0,2.
const ACABAMENTOS := [
	{"nome": "Fosco", "rugoso": 0.95, "metal": 0.0},
	{"nome": "Polido", "rugoso": 0.45, "metal": 0.2},
	{"nome": "Riscado", "rugoso": 0.75, "metal": 0.1},
	{"nome": "Dourado", "rugoso": 0.5, "metal": 0.2, "livre": false},
]
var acabamento_i := 0
var nome := ""

static func acabamentos_disponiveis() -> Array   # os índices com "livre" ausente ou true (a G06 soma a coleção)
func cavaleiro() -> Dictionary                   # {"boneco": modelo_i, "item": ITENS[item_i].id, "nome": nome, "acabamento": acabamento_i}
func vestir(c: Dictionary) -> void               # o inverso: acha o índice do item pelo id; chama visual() e _aplicar_acabamento()
func _aplicar_acabamento() -> void
```

- `_aplicar_acabamento()`, chamado no fim de `visual()` (troque o modelo ou
  não): em cada material das malhas `body*`, `roughness = a.rugoso` e
  `metallic = a.metal`. Nada de `albedo`. Quando a G08 chegar, ele escreve
  `rugoso_cima`, `rugoso_baixo` e `metal` nos `ShaderMaterial` de
  `_mats_corpo` (a G08 cita).
- `POSE_DO_ITEM` e o `_segurar()` de hoje ficam até a G03 (ela troca o item
  visual). Com os `ITENS` novos, `_segurar()` não acha peça para os seis e
  deixa as mãos livres: é o esperado até a G03.
- Saem: as peças Elmo, Capa e Ombreira do desenho antigo (nunca entraram) e
  o campo `peca_i`.

### O que se guarda (`godot/scripts/opcoes.gd`)

```gdscript
static var cavaleiro := [{}, {}, {}, {}]   ## ForjaPlayer.cavaleiro() de cada lugar
static var noite_dos_cavaleiros := ""      ## Opcoes.noite() de quando foram forjados
static var _robo := false                  ## posto por carregar(robo)
## A noite: a data de seis horas atrás (a noite que passa da meia-noite continua a mesma).
static func noite() -> String:
	return Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) - 6 * 3600)
## Grava sem quem chama saber do robô (a paridade da F08).
static func guardar() -> void:
	gravar(_robo)
```

No `user://opcoes.cfg`: seção `P%d`, chave `"cavaleiro"` (o dicionário);
seção `sessao`, `"noite_dos_cavaleiros"`. `de_fabrica()` zera os dois.
`carregar(robo)` guarda `_robo = robo` **antes** do `return` do robô. Com o
robô nada vai ao disco, mas os valores ficam na memória (voltar ao lobby pela
pausa acha o cavaleiro guardado). O desvio é o `tempo_ms` que já existe.

### A bigorna (`godot/scripts/mundo/salao.gd`)

```gdscript
var luzes_das_bigornas: Array[OmniLight3D] = []
## A bigorna do lugar acende e cai a 0,8 em 0,3 s (SAI) se o lugar está ocupado, a 0 se não.
func acender_bigorna(l: int, energia: float) -> void
```

As bigornas e as luzes nascem em `_pedestais()` (A cena) e são filhas de
`pedestais_no`, que só aparece no lobby e no pódio.

### O main (`godot/scripts/main.gd`)

- `_interface()`: `lobby.jogadores = jogadores`, `lobby.salao = salao`.
- `_process`: sai a escrita de `lobby.pes` e `lobby.visual`.
- `_mostrar(qual)`: no começo, `var era_lobby := estado == "lobby"`. Com
  `qual == "lobby"`, no lugar de `Musica.tocar(qual)`:
  `var m := Musica.mapa("MUS_TELA_CONSTRUCAO")`,
  `Ritmo.tocar("MUS_TELA_CONSTRUCAO", m.bpm, m.primeiro_tempo)` e
  `lobby.abrir()`. Com outro `qual` e `era_lobby`: `Ritmo.parar()`,
  `for l in 4: Forja.gatilhos_off(l)`, e o `Musica.tocar(…)` de sempre (o
  salão toca `"salao"`).
- `_quadro_lobby(dt)`: primeiro `if _atalhos_de_overlay(): return`. O bloco
  da F04 que dá o lugar fica; logo depois de um lugar confirmar,
  `lobby.entrou(l)`. Sai o bloco de △/◀▶/▲▼/✕/○ (608-634); no lugar,
  `var dx := [0, 0, 0, 0]`, `var dy := [0, 0, 0, 0]`, `dx[l] = _passo(l, false)`
  e `dy[l] = _passo(l, true)` para os quatro, e `lobby.quadro(dt, dx, dy)`.
  No quadro em que o lugar confirma (`chegou[l]`), `quadro()` não trata o ✕
  dele. A contagem de 1,6 s continua, contando só os lugares ocupados **e**
  com controle (`Forja.lugar(l).get("conectado", false)`).
- `_robo(dt)`, ramo `"lobby"`: `for l in 4: lobby.robo(l, dt)` a cada quadro,
  sem a espera de 0,6 s da G01.

### O texto (`godot/scripts/traducoes.gd`)

| português | inglês |
| --- | --- |
| Boneco / Arma ou amuleto / Nome | Figure / Weapon or charm / Name |
| Mãos livres / Martelo / Escudo / Fole / Lanterna / Diapasão / Âncora | Empty hands / Hammer / Shield / Bellows / Lantern / Tuning fork / Anchor |
| Fosco / Polido / Riscado / Dourado | Matte / Polished / Scratched / Golden |
| Forjar / Sortear / Trocar / Voltar / Entrar | Forge / Shuffle / Switch / Back / Join |
| Forjado / Guardado / Sem controle / Todos prontos | Forged / Saved / No controller / All ready |

`Humano` e `Orc` já existem. Os 24 nomes são nomes próprios: não traduzem.

### O registro (`docs/jogo/13-arquitetura.md`)

Na tabela do [registro v2](../13-arquitetura.md#o-registro-v2--f06-h01-h02-g02-h07),
a linha `cavaleiro` com os campos `boneco`, `item`, `nome`, `acabamento`
(G02; a G13 troca `boneco` por `cabeca`, `superior`, `inferior`). Na seção
do relógio, a frase: «`Opcoes.tempo_ms[l]` guarda a calibração: a G02 mede
nas 8 marteladas, as Opções ajustam à mão; o `Ritmo` lê de lá ao abrir.»

## Passos

Rodar `bash tests/prova_do_jogo.sh` depois dos passos 3, 6 e 8.

1. **O 13:** a linha `cavaleiro` e a frase do relógio.
2. **Os sons:** o encanamento dos quatro (O som); `musica.gd`, a faixa;
   `forja.gd`, a sensação `"metal"`.
3. **`opcoes.gd`:** `cavaleiro`, `noite_dos_cavaleiros`, `_robo`, `noite()`,
   `guardar()`, a leitura e a gravação no cfg.
4. **`player.gd`:** `ITENS`, `VISUAL_DO_LUGAR`, `ACABAMENTOS`,
   `acabamento_i`, `nome`, `acabamentos_disponiveis()`, `cavaleiro()`,
   `vestir()`, `_aplicar_acabamento()`.
5. **`glifo.gd`:** os seis ícones. **`salao.gd`:** as bigornas, as luzes e
   `acender_bigorna()`.
6. **`tela_lobby.gd` e `cartao_jogador.gd`:** reescrever (O alvo).
7. **`main.gd`:** as linhas de «O main».
8. **`traducoes.gd`**, as provas e os roteiros da captura (Provas).

## Armadilhas

- **O ✕ que confirma o lugar não é o ✕ da forja:** guarde o `chegou[l]` do
  main e passe-o a `quadro()` pela ordem dos passos (o `entrou(l)` roda antes).
- **O desvio da prova anda em degraus de ~17 ms** a 60 quadros fixos: as
  tolerâncias já contam com isso.
- **`Ritmo.parar()` ao sair:** sem ele, o salão segue o relógio da construção.
- **Sem o módulo** (`Forja.modulo` falso), a faixa sintetizada não toca e o
  `Ritmo` segue o relógio do sistema a 120 BPM: a forja funciona igual.
- **O robô só aperta:** nenhum `Forja.robo` fora de `robo()` e `_robo()`;
  `Opcoes.guardar()` existe para a tela não saber do robô.
- **Nada abaixo de 30 px**, nada sem `Traducoes`, nenhum `Label`.
- **O pedestal escondido:** `pedestais_no.visible` é `qual in ["lobby", "podio"]`
  (`main.gd:221`); as bigornas vão junto.
- **Os temperamentos e os casos que quebram:** `--robo=bom|medio|ruim`,
  partidas com 1 e 2 jogadores e o `simulador_cabo`. Quem cai guarda a etapa
  e as marteladas, a coluna mostra «Sem controle», e quando volta continua de
  onde parou; a contagem não espera por ele.

## Não fazer

- As peças, os stats, o arquétipo, o VU, o pré-montado e o plano de 50 mm
  (G13).
- O teclado do nome (G09): aqui é a lista e o sorteio.
- A linha do acabamento (o 04 manda para o salão, G06).
- A mecânica e a peça 3D do item (G03); os bonecos e a cor do corpo (G08).
- Mostrar o desvio, «calibração» ou qualquer número de latência na tela.
- Usar a barra de luz ou as lâmpadas para marcar etapa.

## Pronto quando

Quatro pessoas forjam os quatro cavaleiros em menos de dois minutos; a linha
do tempo tem uma linha `calibracao` por lugar, com origem `construcao`;
quem volta ao lobby pela pausa acha o seu cavaleiro guardado; e o robô
constrói os quatro sozinho, só apertando botões.

E só fecha com `bash tests/prova_visual.sh` passando e a prancha olhada; a
aparência só se aprova na máquina do André, com placa de vídeo, sem
`--fixed-fps`.

## Provas

**Na sessão:** `bash tests/prova_do_jogo.sh`.

Em `godot/testes/prova_do_jogo.gd`, `_prova_do_percurso()`: **trocar** o
bloco de 108 a 123 (os `visuais`, ◀▶ do P2, ▼ do P3 e os ✕ de pronto) por:

```gdscript
	# a construção: ◀▶ e ▼ mexem só no próprio lugar; o robô forja os quatro na batida
	var nomes0 := {}
	for l in 4:
		nomes0[jogo.jogadores[l].nome] = true
	_esperar(nomes0.size() == 4, "os quatro nascem com nomes diferentes")
	var m1: int = jogo.jogadores[0].modelo_i
	var m2: int = jogo.jogadores[1].modelo_i
	await _aperta(1, Forja.DIREITA)
	_esperar(jogo.jogadores[1].modelo_i != m2, "◀▶ troca o boneco do P2")
	_esperar(jogo.jogadores[0].modelo_i == m1, "e o do P1 fica como estava")
	await _aperta(2, Forja.BAIXO)
	_esperar(jogo.lobby.linha[2] == TelaLobby.ITEM, "▼ leva o P3 à linha do item")
	var i3: int = jogo.jogadores[2].item_i
	await _aperta(2, Forja.DIREITA)
	_esperar(jogo.jogadores[2].item_i != i3 and jogo.jogadores[2].item_i >= 1, "◀▶ troca o item do P3, entre os seis")
	var q := 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 3600:
		await _quadros(2)
		q += 2
	_esperar(jogo.estado == "salao", "com os quatro forjados, o salão (%d quadros)" % q)
	var nomes := {}
	for l in 4:
		_esperar(jogo.lobby.golpes[l].size() == TelaLobby.MARTELADAS, "P%d: as oito marteladas" % (l + 1))
		_esperar(Opcoes.tempo_ms[l] == clampi(roundi(jogo.lobby.desvio[l] * 1000.0), Opcoes.TEMPO_MIN, Opcoes.TEMPO_MAX),
			"P%d: o desvio foi para as opções (%d ms)" % [l + 1, Opcoes.tempo_ms[l]])
		_esperar(not Opcoes.cavaleiro[l].is_empty(), "P%d: o cavaleiro ficou guardado" % (l + 1))
		nomes[jogo.jogadores[l].nome] = true
	_esperar(nomes.size() == 4 and not nomes.has(""), "quatro nomes diferentes (%s)" % [nomes.keys()])
	var d0: float = jogo.lobby.desvio[0]
	var dif: float = jogo.lobby.desvio[3] - d0
	_esperar(d0 >= -0.01 and d0 <= 0.07, "P1 martelou no tempo: desvio %d ms" % int(d0 * 1000.0))
	_esperar(dif >= 0.07 and dif <= 0.13, "P4 martelou uns 100 ms depois do P1: %d ms" % int(dif * 1000.0))
	_esperar(absf(TelaLobby.mediana([0.3, -0.1, 0.0, 0.5, 0.1]) - 0.1) < 0.0001
		and absf(TelaLobby.mediana([0.0, 0.2, 0.4, 1.0]) - 0.3) < 0.0001
		and TelaLobby.mediana([]) == 0.0, "a mediana: ímpar, par e vazia")
	_esperar(Ritmo.slot == "", "fora do lobby o Ritmo não segue a faixa da construção")
```

Em `_prova_do_relatorio()`, depois de `_esperar(json != "", …)`:

```gdscript
	var calibracoes := 0
	for f in arquivos:
		if f.begins_with("linha-do-tempo-") and f.ends_with(".jsonl"):
			for linha in FileAccess.get_file_as_string(pasta.path_join(f)).split("\n", false):
				var d = JSON.parse_string(linha)
				if d is Dictionary and str(d.get("tipo", "")) == "calibracao" \
						and str(d.get("origem", "")) == "construcao" and int(d.get("amostras", 0)) == 8:
					calibracoes += 1
	_esperar(calibracoes == 4, "a linha do tempo tem a calibração dos quatro (%d)" % calibracoes)
```

**A prova visual (F09):** `bash tests/prova_visual.sh`, as quatro partidas (4
jogadores bom e ruim, 2 jogadores, 1 jogador com o controle caindo); na
prancha da construção: as colunas de 1, 2 e 4 lugares sem texto encostando,
o cavaleiro de cada um dentro da sua coluna, os quadrados das marteladas
enchendo, e a partida em que o controle cai chegando ao salão.

**Os roteiros da captura** (`godot/testes/captura_jogo.gd`; fotos de
divulgação, não prova):

- Um passo novo no `match` de `_rodar()`:

```gdscript
			"ate_pronto":
				# sem robô: ✕ no simulado até o lugar forjar (fora do tempo também conta)
				var n := 0
				while not jogo.lobby.prontos[p[1]] and n < 40:
					Forja.ctl.simulador_botao(p[1], Forja.CRUZ, true)
					for i in 3:
						await get_tree().process_frame
					Forja.ctl.simulador_botao(p[1], Forja.CRUZ, false)
					for i in 17:
						await get_tree().process_frame
					n += 1
```

- `_roteiro_das_telas`, depois de pular a introdução: ✕ nos simulados 0, 1 e
  2; `["espera", 40]`; `["aperta", 1, Forja.DIREITA]`; `["aperta", 2, Forja.BAIXO]`;
  `["espera", 30], ["foto", "construcao"]`; `["aperta", 0, Forja.CRUZ]` três
  vezes com `["espera", 30]` entre elas, `["foto", "construcao_forjar"]`;
  depois `["ate_pronto", 0], ["ate_pronto", 1], ["ate_pronto", 2]` e
  `["espera", 150], ["foto", "salao"]`.
- `_roteiro_dos_extras`: o `["aperta", 1, Forja.TRIANGULO]` vira
  `["aperta", 1, Forja.OPTIONS], ["espera", 10], ["aperta", 1, Forja.BAIXO], ["espera", 6], ["aperta", 1, Forja.CRUZ], ["espera", 10]`
  (a captura roda sem bancada: a pausa do lobby é Continuar, Opções, Voltar
  ao lobby, Sair). O resto do roteiro fica.

## Para o André (local)

1. `bash tests/prova_visual.sh` sem `--fixed-fps`, com a placa de vídeo: a
   construção nas pranchas (as colunas, o cavaleiro acendendo a cada
   martelada, a bigorna brilhando).
2. Quatro DualSense (dois no cabo, dois no rádio): forjar os quatro em menos
   de dois minutos; cada pio sai do seu controle.
3. No `relatorios/linha-do-tempo-*.jsonl`, as quatro linhas `calibracao`:
   colar no diário o `desvio_ms` de cada um com o `transporte`. Esperado: o
   rádio com desvio maior que o cabo.
4. Fechar e abrir o jogo na mesma noite: ✕ confirma e o cavaleiro já vem
   pronto; ○ refaz.

## Ao terminar

No [quadro](README.md), G02 **feito** com o commit e o gasto. Commit sugerido
(sem trailer):

```
feat: a construção do cavaleiro, com a coluna de cada lugar e as oito marteladas que calibram
```
