# M1 — A Galeria

**Sprint:** M · **Slot:** S05_J21 · **Tamanho:** G · **Estimativa:** US$ 2,0 · **Depende de:** H04, F09, F01, F04, F05, F06, H06, H07, G03, G08

## Por quê

A Galeria de hoje (`godot/scripts/salas/galeria.gd`) é uma prova às cegas:
a arma chega no baú fechado, a pessoa diz qual é e depois conta as
luzinhas. A Galeria nova é o estande no tempo da faixa: um alvo sobe na sua
batida, você mira e atira — e o tiro só sai quando o dedo passa do clique da
Weapon. A munição está no tambor em cima da mesa e no gatilho: acabou, o
R2 fica solto (o clique seco) até você recarregar no tempo. As luzinhas
mostram o seu número o tempo todo. A identificação da arma e a contagem das
luzinhas continuam, **só no Modo bancada**, porque são elas que medem os
quatro vereditos da sala.

## Ler antes

- [O índice da seção](M-a-galeria.md) (o cenário comum, o robô da seção, o registro)
- [O molde de minigame](molde-de-minigame.md) e o [kit](../13-arquitetura.md#o-kit-do-minigame--h04)
- [O Modo bancada](../13-arquitetura.md#o-modo-bancada--f01) e a [F01](F01-o-modo-bancada.md) (o que a Galeria faz com e sem a bancada)
- O código de hoje: `godot/scripts/salas/galeria.gd` (inteiro)

## A ficha de dados

`godot/scripts/minigames/s05/a_galeria.gd`:

```gdscript
extends Minigame
## A Galeria (S05_J21) — o estande no tempo da faixa. Na batida do dono, um
## alvo sobe numa das três colunas do muro dele (esquerda, meio, direita),
## uma batida antes. Mire com o analógico esquerdo e atire com R2 na batida:
## a pistola (Weapon) só dispara quando o dedo passa do clique. Seis balas no
## tambor; vazio, o R2 fica solto e a próxima batida dele é a recarga (□ no
## tempo).
##
## A falha: o tiro sai fora do tempo ou na coluna errada e espirra no muro;
## a recarga fora do tempo emperra (o tambor gira em falso).
## O vencedor: mais alvos; no empate, mais pontos.
## O alto-falante do dono: o tiro ("tiro"); a recarga ("recarga").
## O registro mede: cada efeito de gatilho (Weapon, Off) e o curso do R2 no
## disparo — o clique no ponto certo.
## O robô: vê o alvo subir, mira a coluna e atira na batida pelo relógio da
## música; sente o gatilho solto e recarrega; quando não acerta, 250 ms tarde.
## Com menos de quatro: as batidas se dividem; sozinho, todas são dele.
## A régua: (1) "Atire!" com o alvo e a mira; (2) não: o alvo é visto (a
## seção se joga sem tela na M3 e na M4); (3) não pergunta nada fora da
## bancada.

const FICHA := {
	"slot": "S05_J21",
	"titulo": "A Galeria",
	"verbo": "Atire!",
	"genero": "tct",
	"icone": "gatilho_adaptativo",
	"entradas": [Forja.QUADRADO],
	"camera": "fixa",
	"faixa": "MUS_S05_J21",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "toque"],
	"material": "metal",
	"microjogo": {"verbo": "Atire!", "segundos": 6.0},
	# o que a bancada mede (o veredito é do núcleo, como hoje)
	"features": ["gatilho_resistencia", "gatilho_arma", "gatilho_vibracao", "leds_jogador"],
	"botoes_medidos": [Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO, Forja.TRIANGULO],
	"gesto": "holding-right-shoot",
}

const PONTOS := [0, 40, 70, 100]  ## ERRO, BOM, OTIMO, PERFEITO
const DOURADO := 2  ## o alvo dourado vale o dobro
const BALAS := 6
const COLUNAS := [0.2, 0.5, 0.8]  ## o x da mira de cada coluna (0..1 no muro)
const Y_ALVO := 0.5
const LX_COLUNA := 0.5  ## |LX| acima disto escolhe a coluna do lado
## Por parte (entrada 0-30 s, pico 30-60 s, saída 60-90 s): a chance de alvo
## na batida do dono, e a chance de o alvo ser dourado.
const DENSIDADE := [0.6, 1.0, 0.75]
const DOURADOS := [0.0, 0.0, 0.1]
```

Da `galeria.gd` de hoje continuam **iguais**, para a bancada: `VEZES`,
`MAX_EXTRAS`, `IDENTIFICA_MAX`, `REVELA`, `MUNICAO_MAX`, `NOME_ARMA`,
`SENTE`, `BOTAO_OPCAO`, `GLIFO_OPCAO` e os `enum` de arma e de passo (com o
passo novo `RITMO` no lugar de `ATIRAR`). Saem: `F`, `RAIAS`, `Z_JOGADOR`,
`Z_BAU` e `Z_ALVOS` (o kit e o cenário comum), `ATIRA`, `N_ALVOS`,
`n_alvos`, `BALAS_MG`, `MIRA_*` (cenário comum).

## Como se joga

**O dono da batida** é `presentes()` em ordem, `lista[b % k]`; sozinho, todas
as batidas são dele (aqui não há pista na mão para colidir). O compasso 0 é
a contagem; o compasso é gerado quando `Ritmo.batida() >= 4c − 4`.

**A nota** do dono na batida `b`, com a chance da parte:
`{"n": int(round(b * 2)), "b": b, "t": Ritmo.t_da_batida(b), "tipo": "alvo", "coluna": 0 | 1 | 2, "dourado": bool}`,
com `nova_nota(l, n, t)`. No **pico**, cada batida do dono tem dois alvos:
em `b` e em `b + 0,5`, em colunas diferentes (a rajada de alvos; quem está
com `Ritmo.simples[l]` fica só com o de `b`).

**O alvo sobe** de `b − 1` a `b − 0,5` (escala de 0 a 1, pela batida), fica
até `b + 0,25` e cai (escala a 0 até `b + 0,5`). Na tela, é o aviso — uma
batida antes.

**A mira:** o analógico esquerdo escolhe a coluna (`LX < −0,5` esquerda,
`> 0,5` direita, senão o meio); o anel da mira fica no muro, na coluna
escolhida, na altura `Y_ALVO`.

**O tiro:** o R2 passando de `CenarioDaGaleria.R2_CLIQUE` (0,62: o clique da
Weapon) para cima, rearmando abaixo de `R2_SOLTA` (0,2). Cada tiro gasta uma
bala (com o tambor vazio, o R2 não dispara). Casa com a nota `alvo` do lugar
a até `Ritmo.JANELA_BOM`:

- coluna certa → `julgar_toque(l, t, n)`: o kit chama `toque` (o alvo
  estoura) ou `falha` (fora do tempo);
- coluna errada → `nota_perdida(l, n)` (espirra no muro);
- sem nota perto → o tiro à toa: faísca no muro, `Forja.sentir(l, "toque")`,
  nada de ponto nem de erro.

Todo tiro grava `Forja.evento("jogo", l + 1, {"slot": id, "o": "disparo", "n": n, "modo": "arma", "curso": r2, "curso_max": <o maior R2 até soltar>})`
(o `curso_max` se grava ao soltar; guarde o evento até lá).

**A munição:** `balas[l]` começa em `BALAS`. Chegou a 0 →
`Forja.gatilho(l, 1, Forja.GATILHO_OFF)` (o clique seco) e a próxima nota do
dono é uma **recarga** no lugar do alvo:
`{"tipo": "recarga", ...}`; o tambor da mesa brilha uma batida antes. □ a até
`JANELA_BOM` → `julgar_toque(l, t, n)`: BOM ou melhor enche o tambor
(`balas = BALAS`, a Weapon volta: `Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, 8)`);
ERRO ou perdida → continua vazio e a próxima nota dele é recarga de novo.

**Os pontos:** `marcar(l, Itens.pontos_do_acerto(l, PONTOS[j] * (DOURADO if dourado else 1), j, fmod(b, 4.0) == 0.0))`
e `alvos[l] += 1` no alvo (a recarga dá `PONTOS[j] / 2` e não conta alvo).

**Os 90 segundos:** entrada (0–30 s) chance 0,6; **pico** (30–60 s) todo
compasso, dois alvos por batida do dono — o muro pisca `Tema.CIANO` no
começo do pico (`pulso_de_luz(Tema.CIANO)`); saída (60–90 s) chance 0,75
e 10% de alvos dourados (o disco do meio em `Color("#e8b44c")`, fosco).

### O Modo bancada (só com `Forja.bancada`)

A bancada acrescenta duas camadas; fora dela, nenhuma existe.

1. **A prateleira**, antes do primeiro alvo de cada um: o baú fechado com
   as quatro armas, duas vezes cada, na ordem de
   `Array(Forja.cega_plano_armas(VEZES, rng.randi()))` — o fluxo de hoje
   `IDENTIFICAR` → `REVELANDO` (`galeria.gd:219-231`, `:253-262`,
   `:424-443`), com o desempate (`:477-483`). Enquanto a prateleira do lugar
   não acaba, o gerador não dá nota a ele. Acabou: a pistola na mão, a
   Weapon no R2 e o passo `RITMO`. O evento `pergunta` (`qual` = `"arma"`)
   da F01 em cada rodada.
2. **A contagem**, depois de cada recarga boa: `_perguntar_municao(l)` de
   hoje (`galeria.gd:446-470`) — as luzinhas com 1 a 5 acesas, ✕ ○ □ △ — e o
   `MUNICAO` / `MUNICAO_RESP` de hoje (`:328-352`). Enquanto a pergunta está
   aberta, o lugar não recebe nota; fechou, `Forja.leds_do_lugar(l)` (o
   número de volta) e o `RITMO`. O evento `pergunta` (`qual` = `"leds"`).

Os quatro vereditos (`dar_vereditos`, `galeria.gd:497-505`) continuam
iguais e são calculados nos dois modos (fora da bancada, sem resposta, saem
"não medido", como a F01 manda).

## O cenário

- `CenarioDaGaleria.montar(self)` — o cenário comum (o arquivo novo, abaixo).
- A câmera: `camera_pos = Vector3(0, 7.5, 11.0)`, `camera_olhar = Vector3(0, 0.2, -2.2)`.
- Por lugar: `raia(l)`; `posicionar(l)`, `rotation.y = PI`, `preso = true`;
  `CenarioDaGaleria.faixa(self, l)`; a mesa do armeiro
  `Kit.caixa(self, Vector3(1.3, 0.5, 0.9), Vector3(RAIAS[l], 0.25, Z_JOGADOR - 1.35), Kit.material(Color("#4b4558"), 0.0, 0.9))`
  e, em cima, o baú de hoje (`Kit.peca(self, "chest", ..., 0.0, 1.9)`, só
  aberto na bancada) e **o tambor**: seis balas
  `Kit.caixa(self, Vector3(0.1, 0.18, 0.1), Vector3(RAIAS[l] - 0.4 + 0.16 * k, 0.6, Z_JOGADOR - 1.1), Kit.material(Color("#c9cbd6"), 0.0, 0.4))`
  (a bala gasta some: `visible = k < balas[l]`); o brilho da recarga é o
  emissivo `Tema.CIANO` 1,5 nas seis, uma batida antes da nota de recarga.
- Os três alvos de cada muro: `CenarioDaGaleria.alvo(self)` em
  `CenarioDaGaleria.no_muro(l, Vector2(COLUNAS[c], Y_ALVO))`, escala 0 até
  subirem; a mira de hoje (`galeria.gd:118-131`) com o anel `Kit.anel` (G08).
- A pistola na mão desde o começo (fora da bancada):
  `CenarioDaGaleria.arma_na_mao(jogador(l), CenarioDaGaleria.PISTOLA)`, e
  `animar("holding-right")`.
- O checklist do 11: os alvos com 8 lados; nada metálico; o emissivo só na
  borda da raia, no alvo que estoura (faíscas) e no brilho da recarga.

### O cenário comum (`godot/scripts/minigames/s05/cenario_da_galeria.gd`)

```gdscript
class_name CenarioDaGaleria
extends RefCounted
## O cenário comum d'A Galeria (S05, docs/jogo/tarefas/M-a-galeria.md): o
## estande synthwave, a faixa de cada raia, o alvo de 8 lados, as armas em
## blocos, o muro e o curso do R2. Os cinco minigames da seção usam isto.

enum { PISTOLA, METRALHADORA, ARCO, NENHUMA }

const AR := Color("#c28bff")
const Z_ALVOS := -6.4
const MIRA_LARG := 2.8
const MIRA_Y0 := 0.8
const MIRA_Y1 := 2.7
## O curso do R2: o clique da Weapon, o apertar e o soltar.
const R2_CLIQUE := 0.62
const R2_APERTA := 0.5
const R2_SOLTA := 0.2
## As cores das duplas: no mundo (bandeira, castelo), nunca na barra de luz.
const EQUIPE := [Color(1.0, 0.59, 0.0), Color(0.0, 0.82, 1.0)]


static func montar(sala: SalaJogo) -> void:
	Kit.arena(sala, 5, 3)
	sala.atmosfera(AR, Tema.CIANO, false, 50)
	sala.luzes([Vector3(-9, 2.6, -5), Vector3(9, 2.6, -5), Vector3(0, 3.0, 5)])


## A faixa no chão na cor do lugar, do boneco até o muro dos alvos.
static func faixa(sala: Node3D, l: int) -> void:
	var z0 := Minigame.Z_JOGADOR
	Kit.caixa(sala, Vector3(1.5, 0.02, z0 - Z_ALVOS + 0.6), Vector3(Minigame.RAIAS[l], 0.02, (z0 + Z_ALVOS) * 0.5),
		Kit.material(Forja.cor_do_lugar(l).darkened(0.6), 0.25))


## Um alvo: três discos de 8 lados (branco, vermelho, branco) de frente para o jogador.
static func alvo(pai: Node3D) -> Node3D:
	var a := Node3D.new()
	pai.add_child(a)
	var cores := [Color("#e9e7f2"), Color("#c0392b"), Color("#e9e7f2")]
	for i in 3:
		var disco := Kit.cilindro(a, 0.42 - 0.13 * i, 0.04, Vector3(0, 0, 0.012 * i), Kit.material(cores[i], 0.0, 0.6))
		disco.rotation.x = PI * 0.5
	return a
```

e, movidas de `galeria.gd` sem mudança de corpo: `static func arma(pai, qual)`
(`:152-181`), `static func arma_na_mao(p: ForjaPlayer, qual: int) -> Node3D`
(`:545-559`, devolvendo o `BoneAttachment3D` em vez de guardá-lo),
`static func no_muro(l, m)` (`:399-400`, com `Minigame.RAIAS`) e
`static func rastro(sala, de, ate)` (`:404-421`, com `de` e `ate` em vez do
jogador). O vermelho do alvo deixa de ser `Tema.VERMELHO` (é cor de texto)
e vira `#c0392b` fosco.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **gatilho (protagonista)** | R2 `GATILHO_ARMA` (2, 6, 8): a parede e o clique | com bala no tambor |
| gatilho | R2 `GATILHO_OFF` | tambor vazio (o clique seco), até a recarga boa |
| vibração | `acerto` / `perfeito` / `erro` (o kit): o recuo | no tiro julgado |
| vibração | `toque` | no tiro à toa |
| barra de luz | a cor do lugar, 100% | sempre |
| barra de luz | branco 0,1 s | em todo alvo estourado (BOM ou melhor) |
| luzinhas de jogador | o número do lugar, sempre | só a pergunta da bancada mexe nelas |
| alto-falante do dono | `Som.no_controle(l, "tiro", 0.45)` | em todo tiro, menos o perfeito (aí o kit toca a nota do jogador) |
| alto-falante do dono | `Som.no_controle(l, "recarga", 0.6)` | na recarga boa |
| háptica por material | `"metal"` (o kit, no acerto) | — |
| som na TV | `"alvo"` no alvo estourado, `"tique"` no tiro que espirra, `"tiro"` baixo (−10 dB) | — |

## A falha

- **O tiro que espirra** (fora do tempo, ou coluna errada): o rastro vai à
  coluna mirada e espirra faísca `Tema.LARANJA` no muro, o alvo de verdade
  cai para trás sem estourar (tween de `rotation.x` a −1,4), o cavaleiro
  recua o braço (`gesto("holding-right-shoot", 0.2)` e depois `"emote-no"`
  0,3).
- **A recarga que emperra:** o tambor gira em falso (as seis balas giram
  uma volta em `y` em meia batida e continuam apagadas);
  `Som.tocar("vazio", pos, -6.0)`.
- **A recuperação:** a próxima nota do lugar é a próxima batida dele; a
  recarga repete até dar certo.

## O fim e o vencedor

90 s de `t_jogo`, pelo kit.

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if int(alvos[a]) != int(alvos[b]):
			return int(alvos[a]) > int(alvos[b])
		return int(pontos[a]) > int(pontos[b]))
	return lista
```

## Com menos de quatro

- **Três e dois:** a roda do dono. **Um:** todas as batidas dele.
- **O controle que cai:** as notas dele somem sem erro enquanto está fora;
  o tambor fica como estava. Na bancada, a prateleira ou a pergunta abertas
  esperam por ele (como hoje).

## O robô

```gdscript
# O robô vê o alvo subir (a nota da vez), mira a coluna com o analógico e
# atira na batida, pelo relógio da música. Sente o gatilho solto (Off, 0x05)
# e recarrega na nota de recarga. Na bancada, identifica a arma pelo que
# chegou ao dedo e conta as luzinhas, como hoje.
var _robo_nota := [-1, -1, -1, -1]
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]
var _robo_r2 := [0.0, 0.0, 0.0, 0.0]


func robo(l: int, dt: float) -> void:
	if not Forja.robo:
		return
	if Forja.bancada and int(j[l].passo) != RITMO:
		_robo_da_bancada(l, j[l], dt)  # o _robo de hoje (galeria.gd:661-714), só IDENTIFICAR e MUNICAO
		return
	var r2 := 0.0
	if not _notas[l].is_empty():
		var nt: Dictionary = _notas[l][0]
		if int(nt.n) != _robo_nota[l]:
			_robo_nota[l] = int(nt.n)
			# o temperamento (--robo=bom|medio|ruim): quando não acerta, 250 ms tarde
			_robo_atraso[l] = 0.0 if Forja.robo_acerta() else 0.25
		var vazio := int(Forja.percepcao(l).get("gatilho_dir", 0)) == 0x05
		if Ritmo.t_musica() >= Ritmo.t_da_batida(float(nt.b) - 1.0):
			if nt.tipo == "alvo" and not vazio:
				Forja.robo_eixo(l, Forja.LX, float(int(nt.coluna) - 1), 0.06)
				if Ritmo.t_musica() >= float(nt.t) + float(_robo_atraso[l]):
					r2 = 1.0
			elif nt.tipo == "recarga" and vazio and Ritmo.t_musica() >= float(nt.t) + float(_robo_atraso[l]):
				Forja.robo_apertar(l, Forja.QUADRADO, 0.06)
	_robo_r2[l] = r2
	Forja.robo_eixo(l, Forja.R2, r2, 0.06)
```

(O R2 fica apertado até o tiro sair: a nota julgada sai da lista e, na
próxima nota, o R2 volta a 0 e rearma. O `_robo_da_bancada` é o `_robo` de
hoje com os passos `IDENTIFICAR` e `MUNICAO` e sem o `ATIRAR`, com
`_arma_sentida` e `_luzes_acesas` copiadas iguais.)

## Os ganchos

O que muda do `galeria.gd` de hoje:

| hoje | na Galeria nova |
| --- | --- |
| `class_name SalaGaleria`, `extends SalaJogo` | `extends Minigame`, sem `class_name`, o cabeçalho de "A ficha de dados" |
| `_init()` | sai (a FICHA; a câmera vai para o `montar`) |
| `montar()`, `_montar_raia()`, `_alvo_no()`, `_arma()`, `_rastro()`, `_no_muro()`, `_arma_na_mao()` | o `montar` de "O cenário", com o cenário comum |
| `_novo_jogador()` | fica (é da bancada), com `"passo": RITMO` fora da bancada |
| `_gatilho(l, arma)` | fica (a bancada usa as quatro armas; o jogo, a pistola e o Off) |
| `_leds`, `_luzes_da_mg` | `_leds` fica só para a pergunta da bancada; `_luzes_da_mg` sai |
| `jogar()` / `_jogar()` com `ATIRAR` | o `jogar` de baixo; `IDENTIFICAR`, `REVELANDO`, `MUNICAO`, `MUNICAO_RESP` só na bancada |
| `_sortear_alvos`, `_atirar`, `_vazia` | `_gerar_compasso`, `_atirar(l, r2)`, `balas[l] == 0` |
| `_responder_arma`, `_perguntar_municao`, `_proxima_rodada`, `_fechar_bau`, `_abrir_bau`, `_guardar_arma`, `pergunta()`, `dar_vereditos()` | ficam iguais (a bancada); `_proxima_rodada` no fim da prateleira vai para `RITMO` em vez de `PRONTO` |
| `_process`/`_mostrar` | `_mostrar(l)` no fim do `jogar`: alvos pela batida, mira, tambor |
| `status()` | `"%d alvos" % alvos[l]` quando `na_raia(l)` |
| `dica()` | `{"partes": ["@stick_l", "Mira", "@r2", "Atira"], ...}`; vazio: `["@square", "Recarrega"]`; com `na_raia(l)` e `not aprendeu(l)` |
| `_robo` | `robo(l, dt)` de cima |

O esqueleto:

```gdscript
var _notas := [[], [], [], []]
var _ultima := [{}, {}, {}, {}]
var _gerado := 1
var _fora := [false, false, false, false]
var _armado := [true, true, true, true]
var balas := [BALAS, BALAS, BALAS, BALAS]
var alvos := [0, 0, 0, 0]
var _disparo := [{}, {}, {}, {}]  ## o evento do tiro, até soltar (o curso_max)
var j := {}  ## lugar -> o estado da bancada (o _novo_jogador de hoje)
var n := {}  ## lugar -> os nós da raia


func montar() -> void:
	camera_pos = Vector3(0, 7.5, 11.0)
	camera_olhar = Vector3(0, 0.2, -2.2)
	CenarioDaGaleria.montar(self)
	for p in jogadores:
		var l: int = p.lugar
		j[l] = _novo_jogador()
		raia(l)
		posicionar(l)
		p.rotation.y = PI
		p.preso = true
		n[l] = _montar_raia(l, p)  # faixa, mesa, baú, tambor, três alvos, mira
		if not Forja.bancada:
			j[l].passo = RITMO
			n[l].arma_mao = CenarioDaGaleria.arma_na_mao(p, CenarioDaGaleria.PISTOLA)
			Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, 8)


func jogar(dt: float) -> void:
	while _gerado <= int(floor(Ritmo.batida() / 4.0)) + 1:
		_gerar_compasso(_gerado)  # só para quem está no passo RITMO
		_gerado += 1
	var agora := Ritmo.t_musica()
	for l in presentes():
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_notas[l] = _notas[l].filter(func(nt): return float(nt.t) > agora)
		if int(j[l].passo) != RITMO:
			_jogar_a_bancada(l, jogador(l), j[l], dt)  # o _jogar de hoje sem o ATIRAR
			continue
		var r2 := Forja.eixo(l, Forja.R2)
		if _armado[l] and r2 >= CenarioDaGaleria.R2_CLIQUE and balas[l] > 0:
			_armado[l] = false
			_atirar(l, r2)
		elif r2 <= CenarioDaGaleria.R2_SOLTA:
			if not _armado[l]:
				_soltou(l)  # grava o disparo com o curso_max
			_armado[l] = true
		if not _armado[l]:
			_disparo[l]["curso_max"] = maxf(float(_disparo[l].get("curso_max", 0.0)), r2)
		if Forja.apertou(l, Forja.QUADRADO):
			_recarregar(l)
		while not _notas[l].is_empty() and agora > float(_notas[l][0].t) + Ritmo.JANELA_BOM:
			var nt: Dictionary = _notas[l].pop_front()
			_ultima[l] = nt
			nota_perdida(l, int(nt.n))
		_mostrar(l)


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	var forte := fmod(float(nt.b), 4.0) == 0.0
	if nt.tipo == "recarga":
		marcar(l, Itens.pontos_do_acerto(l, PONTOS[julgamento] / 2, julgamento, forte))
		balas[l] = BALAS
		Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, 8)
		Som.no_controle(l, "recarga", 0.6)
		if Forja.bancada:
			_perguntar_municao(l)
		return
	marcar(l, Itens.pontos_do_acerto(l, PONTOS[julgamento] * (DOURADO if nt.dourado else 1), julgamento, forte))
	alvos[l] += 1
	_estourar_o_alvo(l, nt)  # faíscas, "alvo" na TV
	Forja.luz(l, Color.WHITE)
	_volta_da_luz[l] = 0.1  # e em _mostrar: ao chegar a 0, Forja.luz_do_lugar(l)


func falha(l: int) -> void:
	var nt: Dictionary = _ultima[l]
	if nt.get("tipo", "") == "recarga":
		_emperrar(l)
	else:
		_espirrar(l, nt)
```

(Com `var _volta_da_luz := [0.0, 0.0, 0.0, 0.0]`, descontado por `dt` no
`_mostrar`.) `_atirar(l, r2)` gasta a bala, mostra o rastro, toca o tiro
(menos no perfeito: decida depois do julgamento), acha a nota e decide pelo
"Como se joga", e começa `_disparo[l]`; ao chegar a 0 balas, o Off e a
próxima nota vira recarga. `_recarregar(l)` casa o □ com a nota `recarga`.

Catálogo: `Catalogo.MINIGAMES["S05_J21"] = preload("res://scripts/minigames/s05/a_galeria.gd")`,
`"minigames": ["S05_J21"]` na seção `S05`, e sai `"galeria"` de
`SALAS_ANTIGAS`. `git rm godot/scripts/salas/galeria.gd godot/scripts/salas/galeria.gd.uid`.
Os `.uid` novos (`a_galeria.gd.uid`, `cenario_da_galeria.gd.uid`).
Traduções (as que ainda não existirem): `"Atire!": "Shoot!"`, `"Mira": "Aim"`,
`"Atira": "Shoot"`, `"Recarrega": "Reload"`, `"%d alvos": "%d targets"`.

## O que o registro mede

- A `saida` de gatilho (Weapon 2, 6, 8 e Off, com `seq` e `ok`).
- `jogo` `disparo` (n, modo `"arma"`, `curso`, `curso_max`) em todo tiro, e
  o `toque` do kit: o curso no disparo mostra o clique no ponto certo.
- Na bancada, a `pergunta` (`"arma"`, `"leds"`), as respostas de hoje
  (`resposta_arma`, `resposta_municao`) e os quatro vereditos.
- **O tipo `jogo` na tabela do 13:** se ainda não estiver lá, acrescente a
  linha (o texto está na [L1](L1-o-cerco.md#o-que-o-registro-mede)).

## Armadilhas

- **As luzinhas são do número do jogador.** Fora da bancada, nenhum
  `Forja.leds_jogador`; a prova da F04 confere as luzinhas de cada lugar
  durante a sala. Na bancada, depois da pergunta, `Forja.leds_do_lugar(l)`.
- **O tiro só com bala:** com o tambor vazio o R2 está Off e o curso não
  dispara; sem isso, o jogador sem peso no dedo atiraria "de graça".
- **O pico tem dois alvos por batida:** a pistola rearma abaixo de 0,2; meia
  batida (≈ 0,29 s a 104 bpm) dá para soltar e apertar de novo — o robô
  solta o R2 quando a nota sai da lista.
- **A bancada não muda a regra do jogo** ([paridade](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08)):
  ela acrescenta a prateleira antes e a contagem depois da recarga; o resto
  é o mesmo jogo.
- **A barra de luz:** o branco do acerto dura 0,1 s e volta com
  `Forja.luz_do_lugar(l)`.
- **Os pontos e o item:** se o kit já aplica `Itens.pontos_do_acerto`, marque cru.

## Pronto quando

A Galeria joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô
nos três temperamentos; aguenta o cabo que cai e volta; fecha com vencedor;
`--sala=galeria` abre o `S05_J21`; com `--bancada`, a prateleira e a
contagem aparecem e os quatro vereditos saem como antes (o gauntlet e a
prova de poucos, do André, passam); a prova do jogo passa nas duas rodadas;
e `bash tests/prova_visual.sh` passa com a **prancha olhada** — a Galeria
está nas partidas de 3 e de 5 da prova visual.

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd` (o `_joga_o_minigame` é o da
[L1](L1-o-cerco.md#provas); se ainda não existir, crie-o com aquele código):

```gdscript
## A Galeria (S05_J21): o apelido abre o minigame; o R2 recebeu a Weapon; fora
## da bancada, as luzinhas nunca saem do número; o registro tem o disparo com
## o curso.
func _prova_da_galeria() -> void:
	var arma := [false]
	var leds_ok := [true]
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			var pc := Forja.percepcao(l)
			if int(pc.get("gatilho_dir", 0)) == 0x25:
				arma[0] = true
			if not Forja.bancada and int(pc.get("leds_jogador", 0)) != Forja.LEDS_DO_LUGAR[l]:
				leds_ok[0] = false
	var mg := await _joga_o_minigame("galeria", 60.0, olhar)
	if mg == null:
		return
	_esperar(mg.id == "S05_J21", "Galeria: --sala=galeria abre o S05_J21")
	if not Forja.bancada:
		_esperar(arma[0], "Galeria: a Weapon chegou ao R2")
		_esperar(leds_ok[0], "Galeria: as luzinhas mostraram o número do jogador o tempo todo")
		var disparos := _linha_do_tempo().filter(func(e): return e.get("tipo") == "jogo" and e.get("slot") == "S05_J21" and e.get("o") == "disparo")
		_esperar(disparos.size() >= 1 and disparos.all(func(e): return float(e.get("curso", 0.0)) >= 0.62), "Galeria: %d disparos, todos depois do clique" % disparos.size())
	var v := mg.vencedor()
	_esperar(not v.is_empty() and int(mg.alvos[v[0]]) == v.map(func(l): return int(mg.alvos[l])).max(), "Galeria: vence quem estourou mais alvos")
```

As checagens de hoje que olham a Galeria pelo id (a F01, `SO_COM_PERGUNTA`;
o L2 solto da G03) passam a olhar pelo apelido (`_e_a_sala` da H04).

**O que o André joga e sente** (`./run-local.sh -- --sala=galeria`):

- o tiro só sai no clique, e o clique no tempo é gostoso;
- o tambor esvazia na mesa e o R2 fica mole — e a recarga no tempo devolve a parede;
- no pico, dois alvos por batida pedem o dedo rápido;
- as luzinhas ficam no número o tempo todo; a barra de luz pisca branco no acerto;
- com `--bancada`, a prateleira e a contagem das luzinhas como antes.

## Ao terminar

- No [quadro](README.md): a linha **M1** (se o quadro só tem a linha **M**
  da seção, acrescente abaixo dela
  `| [M1](M1-a-galeria.md) | M | S5 — A Galeria | G | — | 2,0 | feito (<commit>) | <gasto> |`),
  com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: A Galeria no kit — o estande no tempo, a munição no tambor e no gatilho`
