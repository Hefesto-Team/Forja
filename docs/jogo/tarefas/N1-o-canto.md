# N1 — O Canto

**Sprint:** N · **Slot:** S06_J26 · **Tamanho:** G · **Modelo:** Sonnet · **Estimativa:** US$ 2,0 · **Depende de:** H04, H08, F09, F01, F02, F05, H06, H07, G08

## Por quê

O Canto de hoje (`godot/scripts/salas/canto.gd`) pergunta "o canto saiu do
seu controle?" — a pergunta que a regra de ouro 1 proíbe fora da bancada.
O Canto novo é chamada e resposta em hoqueto: num compasso, o controle de
cada um canta, na vez dele, uma frase curta de notas graves e agudas; no
compasso seguinte, cada um repete a sua nos botões. A frase só está no
alto-falante da própria mão; se o som não chegou, a resposta sai errada — e
o registro mostra, sem perguntar nada. A pergunta de hoje fica só no Modo
bancada, onde ela mede o veredito `alto_falante`.

## Ler antes

- [O índice da seção](N-o-canto.md) (o cenário comum, o robô da seção, o registro)
- [O molde de minigame](molde-de-minigame.md) e o [kit](../13-arquitetura.md#o-kit-do-minigame--h04)
- [O Modo bancada](../13-arquitetura.md#o-modo-bancada--f01) e a [F01](F01-o-modo-bancada.md) (o Canto com e sem a bancada)
- [O som em todo evento](H07-o-som-em-todo-evento.md) (a placa aberta desde a entrada, os sons `nota:<lugar>`)
- O código de hoje: `godot/scripts/salas/canto.gd` (inteiro)

## A ficha de dados

`godot/scripts/minigames/s06/o_canto.gd`:

```gdscript
extends Minigame
## O Canto (S06_J26) — chamada e resposta em hoqueto. Os compassos ímpares
## são a chamada: na vez de cada um, o alto-falante do controle dele canta a
## frase — uma nota (a entrada) ou duas (o pico), cada uma grave ou aguda. Os
## compassos pares são a resposta: na mesma vez, repita a frase — ✕ na grave,
## ○ na aguda, no tempo de cada nota. A tela mostra de quem é a vez (o sino
## pequeno balança), nunca a altura.
##
## A falha: a nota sai desafinada e o sino racha (uma trinca a cada erro,
## até três); a frase inteira conserta o sino.
## O vencedor: mais frases inteiras; no empate, mais pontos.
## O alto-falante do dono: a chamada (a protagonista) e a nota que ele toca
## na resposta.
## O registro mede: cada chamada (o som, se foi ao controle) e a resposta
## (o toque do kit com o mesmo n).
## O robô: ouve o ataque no alto-falante simulado na vez dele; só responde as
## notas que ouviu, com a altura que ouviu (o nome do som, H08), no tempo; quando não acerta,
## 250 ms tarde.
## Com menos de quatro: dois têm as vezes 0 e 2; sozinho, as vezes 0 e 2 são
## as duas dele.
## A régua: (1) "Repita!" com o sino que balança; (2) sim: a frase está só no
## controle; (3) não pergunta nada (a pergunta de hoje, só na bancada).

const FICHA := {
	"slot": "S06_J26",
	"titulo": "O Canto",
	"verbo": "Repita!",
	"genero": "tct",
	"icone": "alto_falante",
	"entradas": [Forja.CRUZ, Forja.CIRCULO],
	"camera": "fixa",
	"faixa": "MUS_S06_J26",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["toque", "acerto", "perfeito", "erro"],
	"material": "metal",
	"microjogo": {"verbo": "Repita!", "segundos": 6.0},
	"nota_no_falante": false,  # o alto-falante é a pista: o kit não toca a nota do perfeito nele (H08)
	"papel_som": Forja.PAPEL_ALTO_FALANTE,  # a bancada afina o alto-falante no aviso (F02)
	# o que a bancada mede (o veredito é do núcleo, como hoje)
	"features": ["alto_falante"],
	"botoes_medidos": [Forja.CRUZ, Forja.CIRCULO],
}

const PONTOS := [0, 40, 70, 100]  ## ERRO, BOM, OTIMO, PERFEITO
const FRASE_INTEIRA := 50
const GRAVE := 0
const AGUDA := 1
const SOM := ["nota", "nota_alta"]  ## GRAVE, AGUDA
const BOTAO := [Forja.CRUZ, Forja.CIRCULO]  ## GRAVE, AGUDA
const TRINCAS_MAX := 3
const PULSO_S := 0.12  ## a barra de luz a 60% na nota da resposta
## As notas da frase por parte (entrada 0-30 s, pico 30-60 s, saída 60-90 s):
## a chance de duas notas (a segunda meia batida depois da primeira).
const DUAS_NOTAS := [0.0, 1.0, 0.5]
## A bancada: um compasso de canto às cegas a cada oito.
const BANCADA_A_CADA := 8
```

Do `canto.gd` de hoje continuam **iguais**, para a bancada: `TV`, `NOTAS`,
`INTERVALOS`, `PERGUNTA_MAX`, `REVELA_S`. Saem: `F`, `RAIAS`, `Z_JOGADOR`
(o kit), `REPETE_MAX`, `FOLGA_RITMO` (a resposta agora é julgada pelo
`Ritmo`), `SINO_TV` e `PERFIL` (vão para o cenário comum).

## Como se joga

**As vezes.** `lista = presentes()` em ordem, `k = lista.size()`; a vez do
lugar `lista[i]` no compasso é a batida (desde `4c`): com quatro ou três,
`i`; com dois, `2i`; sozinho, 0 **e** 2 (duas vezes por compasso).

**Os compassos:** o 0 é a contagem (H06). Os ímpares (1, 3, 5…) são a
**chamada**; o par seguinte (2, 4, 6…) é a **resposta** da chamada. O
compasso é gerado quando `Ritmo.batida() >= 4c − 4` — o de chamada gera
também as notas da resposta.

**A frase** de cada vez `v` na chamada `c`: a primeira nota em
`b = 4c + v`, com a altura sorteada (`GRAVE`/`AGUDA`); com a chance de
`DUAS_NOTAS[parte]` (nunca para quem está com `Ritmo.simples[l]`), uma
segunda em `b + 0,5`, com altura sorteada. Cada nota da frase gera a nota
da resposta, **uma batida de compasso depois** (`b + 4`):
`{"n": int(round((b + 4) * 2)), "b": b + 4, "t": Ritmo.t_da_batida(b + 4), "altura": ..., "frase": <id da frase>}`,
com `nova_nota(l, n, t)`.

**A chamada toca** no tempo de cada nota (`Ritmo.t_musica() >= Ritmo.t_da_batida(b)`):
`var foi := CenarioDoCanto.falante(self, l, SOM[altura], 0.9)` e
`anotar("pista", l, {"n": <n da resposta>, "evento": "mandou", "canal": "alto_falante", "o_que": SOM[altura], "no_controle": foi})`.
Na tela, o sino pequeno do lugar balança na vez dele (`CenarioDoCanto.balancar`
com força 1 durante a batida), igual para as duas alturas.

**A resposta:** ✕ ou ○ casa com a nota de resposta do lugar a até
`Ritmo.JANELA_BOM`:

- o botão da altura certa → `julgar_toque(l, t, n)`;
- o botão errado → `nota_perdida(l, n)` (desafinou);
- nenhuma nota perto → nada.

A nota que passa de `t + FOLGA_PERDIDA` (o kit) é `nota_perdida(l, n)`. **A frase
inteira:** todas as notas dela BOM ou melhor → `frases[l] += 1`,
`marcar(l, FRASE_INTEIRA)`, o sino dele brilha dourado (emissivo 1,4 por uma
batida) e as trincas somem.

**Os pontos:** `marcar(l, PONTOS[julgamento])` (o item, `Itens.pontos_do_acerto`, o kit já aplica no `julgar_toque`: H08).

**Os 90 segundos:** entrada (0–30 s) frases de uma nota — a altura só;
**pico** (30–60 s) frases de duas notas — altura e ritmo; aos 30 s o sino
grande toca três vezes (`Som.tocar("sino", CenarioDoCanto.SINO_TV, -4.0)`
nas batidas 0, 1 e 2 do compasso) e a capela acende (`pulso_de_luz(Tema.ROXO)`);
saída (60–90 s) metade de uma nota, metade de duas.

**O compasso na mão:** no começo de cada compasso, `Forja.sentir(l, "toque")`
em cada presente com controle e `CenarioDoCanto.tempo_forte()` na TV.

### O Modo bancada (só com `Forja.bancada`)

A cada `BANCADA_A_CADA` compassos (o `c` de chamada com `c % 8 == 1` e
`c >= 9`), o par chamada-resposta vira **o canto às cegas** de hoje: um
compasso sem notas do jogo, em que a `fonte` da vez (a lista de hoje,
`Forja.cega_plano_fontes(fontes, vezes, rng.randi())`, `canto.gd:242-265`)
canta o ritmo de quatro notas de hoje (`_comecar_canto`, `_tocar_nota`,
`canto.gd:272-311`) — num controle ou na TV —, e depois o `PERGUNTA` e o
`REVELA` de hoje (`canto.gd:409-434`), sem o `REPETE` (a repetição agora é o
jogo). O evento `pergunta` (`qual` = `"canto"`, `jogador` 0) da F01. Enquanto
a pergunta está aberta, o gerador não dá notas. O veredito
(`dar_vereditos`, `canto.gd:445-449`) continua igual e é calculado nos dois
modos (fora da bancada, sai "não medido", como a F01 manda).

## O cenário

- `var grande := CenarioDoCanto.montar(self)` — o cenário comum (o arquivo
  novo, abaixo).
- A câmera: `camera_pos = Vector3(0, 5.6, 11.2)`, `camera_olhar = Vector3(0, 1.6, -1.0)`.
- Por lugar: `raia(l)`; `posicionar(l)`, `preso = true`; o suporte do sino
  pequeno (`canto.gd:201-204`) e o sino
  `CenarioDoCanto.sino(self, Vector3(RAIAS[l] + 0.6, 1.8, Z_JOGADOR - 0.35), 0.34, Color("#c08a42"))`;
  as três trincas escondidas: `Kit.caixa(sino.pivo, Vector3(0.02, 0.18, 0.02), ..., Kit.material(Color("#2a2233")))`
  em ângulos diferentes na saia do sino.
- A partitura de hoje (`canto.gd:212-231`) sai: a tela não mostra a frase.
- O checklist do 11: o sino passa a 8 lados e `metallic` 0,15 (hoje é liso
  e 0,75 — destoa); o badalo, caixa; o emissivo só no sino que acerta e na
  borda da raia.

### O cenário comum (`godot/scripts/minigames/s06/cenario_do_canto.gd`)

```gdscript
class_name CenarioDoCanto
extends RefCounted
## O cenário comum d'O Canto (S06, docs/jogo/tarefas/N-o-canto.md): a
## capela, o sino grande da TV no pórtico, o sino facetado de cada raia, o
## tempo forte e o alto-falante de cada um com a saída silenciosa.

const AR := Color("#b88cff")
const FRIO := Color("#8a80c8")
const TOCHA := Color("#ffb070")
const MADEIRA := Color("#6b4526")
const SINO_TV := Vector3(0.0, 3.9, -4.3)
## O perfil do sino (raio, altura), da coroa à boca (o de canto.gd, igual).
const PERFIL := [
	Vector2(0.0, 1.0), Vector2(0.18, 0.98), Vector2(0.34, 0.89), Vector2(0.43, 0.73), Vector2(0.48, 0.5),
	Vector2(0.5, 0.23), Vector2(0.55, -0.05), Vector2(0.64, -0.32), Vector2(0.77, -0.55), Vector2(0.93, -0.7),
	Vector2(1.0, -0.8), Vector2(0.68, -0.85), Vector2(0.34, -0.875), Vector2(0.0, -0.886),
]
const LADOS := 8  ## facetado (docs/jogo/11, regra 2)
## O som da TV no lugar do alto-falante, quando o controle não tem um: [som, tom].
const NA_TV := {"nota": ["nota", 1.0], "nota_alta": ["nota_alta", 1.0], "clique": ["tique", 1.0],
	"pronto": ["bigorna_aguda", 1.0], "coleta": ["tique", 1.0]}


## A capela: arena, poeira violeta, neon roxo, enchimento frio, duas tochas,
## o pórtico e o sino grande. Devolve o sino grande ({pivo, mat, badalo}).
static func montar(sala: SalaJogo, escuro := 1.0) -> Dictionary:
	Kit.arena(sala, 5, 3)
	sala.atmosfera(AR, Tema.ROXO, false, 36, 22.0, -7.8, 0.2 * escuro)
	var frio := OmniLight3D.new()
	frio.position = Vector3(0, 8.0, 4.0)
	frio.light_color = FRIO
	frio.light_energy = 0.55 * escuro
	frio.omni_range = 26.0
	sala.add_child(frio)
	for x in [-9.5, 9.5]:
		var tocha := OmniLight3D.new()
		tocha.position = Vector3(x, 2.6, -4.5)
		tocha.light_color = TOCHA
		tocha.light_energy = 1.1 * escuro
		tocha.omni_range = 8.0
		sala.add_child(tocha)
	var madeira := Kit.material(MADEIRA, 0.0, 0.85)
	for x in [-2.1, 2.1]:
		Kit.caixa(sala, Vector3(0.36, 5.2, 0.36), Vector3(x, 2.6, SINO_TV.z), madeira)
	Kit.caixa(sala, Vector3(4.9, 0.4, 0.46), Vector3(0, 5.2, SINO_TV.z), madeira)
	return sino(sala, SINO_TV, 1.35, Color("#b07838"))


## O sino de canto.gd (o perfil girado), com LADOS lados, fosco, e o badalo em caixa.
static func sino(pai: Node3D, pos: Vector3, escala: float, cor: Color) -> Dictionary:
	# o corpo de canto.gd:105-152, com `var lados := LADOS`, `mat.metallic = 0.15`,
	# a argola com Kit.anel (G08) e o badalo:
	# Kit.caixa(badalo_pivo, Vector3(0.2, 0.2, 0.2) * escala, Vector3(0, -1.35, 0) * escala, Kit.material(Color("#5a3c1c"), 0.0, 0.6))
	...


## O sino balança pela batida (0: parado).
static func balancar(s: Dictionary, forca: float) -> void:
	(s.pivo as Node3D).rotation.z = sin(TAU * Ritmo.batida()) * 0.3 * forca


## O sino grande dá o tempo forte na TV, baixo: o compasso se ouve mesmo sem faixa.
static func tempo_forte() -> void:
	Som.tocar("sino", SINO_TV, -16.0)


## O som no alto-falante do lugar; sem alto-falante achado, na TV, baixo, na
## raia dele (a saída silenciosa). Devolve se foi ao controle.
static func falante(sala: Node3D, l: int, som: String, ganho := 0.9) -> bool:
	if Forja.som_tem(l, Forja.PAPEL_ALTO_FALANTE) and Forja.som_falante(l, som, ganho) >= 0:
		return true
	var pos := Vector3(Minigame.RAIAS[l], 1.5, Minigame.Z_JOGADOR)
	if som.begins_with("nota:"):
		Som.tocar("nota", pos, -10.0, Minigame.TOM_DO_LUGAR[int(som.substr(5))])
	elif NA_TV.has(som):
		Som.tocar(NA_TV[som][0], pos, -10.0, NA_TV[som][1])
	return false


## A barra de luz na cor do lugar, com o brilho `forca` (nunca abaixo de 0,3: F04).
static func luz_da_nota(l: int, forca: float) -> void:
	var c := Forja.cor_do_lugar(l)
	var k := clampf(forca, 0.3, 1.0)
	Forja.luz(l, Color(c.r * k, c.g * k, c.b * k))
```

(O corpo do `sino` é o de `canto.gd:105-152` com as quatro trocas do
comentário; escreva-o inteiro no arquivo.)

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **alto-falante (protagonista)** | `"nota"` (grave) / `"nota_alta"` (aguda), 0,9 | a chamada, na vez do dono, no tempo de cada nota |
| alto-falante do dono | `SOM[altura do botão]`, 0,8 | a nota que ele toca na resposta boa (a FICHA diz `"nota_no_falante": false`: o kit não toca a dele, um som por vez) |
| vibração | `toque` | no começo de cada compasso, em todos (o tempo forte) |
| vibração | `acerto` / `perfeito` / `erro` (o kit) | na resposta julgada |
| barra de luz | `CenarioDoCanto.luz_da_nota(l, 0.6)` por `PULSO_S`, e volta a 1,0 | na resposta boa — nunca na chamada |
| luzinhas de jogador | o número, sempre | — |
| háptica por material | `"metal"` (o kit, no acerto, no cabo) | — |
| gatilho | `Forja.gatilho(l, 1, Forja.GATILHO_OFF)` no `montar` | nada a segurar; o L2 é do item |
| som na TV | o sino grande no tempo forte; `"nota"` com o tom do lugar (o kit) na resposta boa | — |

## A falha

- **Desafinou** (botão errado, fora do tempo, ou não respondeu): o kit toca
  a nota quebrada do lugar no alto-falante e a falha na TV; o sino pequeno
  **racha**: uma trinca aparece (`trincas[l] += 1`, até 3, visível), o sino
  dá um tranco torto (`rotation.x` a 0,25 e volta em meia batida) e solta
  três faíscas cinzentas; o cavaleiro tapa os ouvidos (`gesto("emote-no", 0.4)`).
- **Três trincas:** o sino fica torto (inclinado 0,2) até a próxima frase
  inteira, que conserta tudo (as trincas somem com faíscas douradas).
- **A recuperação:** a próxima chamada é dois compassos depois; nada se
  perde além do ponto.

## O fim e o vencedor

90 s de música, pelo kit (H08).

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if int(frases[a]) != int(frases[b]):
			return int(frases[a]) > int(frases[b])
		return int(pontos[a]) > int(pontos[b]))
	return lista
```

## Com menos de quatro

- **Três:** as vezes 0, 1 e 2; a batida 3 fica para o sino grande.
- **Dois:** as vezes 0 e 2.
- **Um:** as vezes 0 e 2 são as duas dele (duas frases por chamada).
  `com_poucos()` devolve `""` (nada muda na regra; F02 tirou o selo de hoje).
- **O controle que cai:** a chamada dele não toca enquanto está fora e as
  notas de resposta somem sem erro; quando volta, entra na próxima chamada.

## O robô

```gdscript
# O robô ouve o alto-falante do controle simulado dele (o nível, pela lógica
# de ataque de hoje) e guarda em que batida ouviu cada ataque. Na resposta,
# toca só as notas cuja chamada ele ouviu (uma batida de compasso antes), com
# a altura que ouviu (`Forja.som_virtual` dá o nome do último som: H08), no
# tempo. Quando não acerta, 250 ms tarde.
var _robo_vale := [1.0, 1.0, 1.0, 1.0]
var _robo_desde := [0.0, 0.0, 0.0, 0.0]  ## o tempo de música do último ataque
var _robo_ouviu := [{}, {}, {}, {}]  ## lugar -> {meia batida do ataque: o som ouvido}
var _robo_nota := [-1, -1, -1, -1]
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var nivel := float(Forja.som_virtual(l).get("falante", 0.0))
	var agora := Ritmo.t_musica()
	if nivel > 0.12 and nivel - float(_robo_vale[l]) > 0.10 and agora - float(_robo_desde[l]) > 0.12:
		_robo_vale[l] = nivel
		_robo_desde[l] = agora
		_robo_ouviu[l][int(round(Ritmo.batida() * 2.0))] = str(Forja.som_virtual(l).get("som", ""))  # o nome do último som (H08)
	else:
		_robo_vale[l] = minf(float(_robo_vale[l]), nivel)
	if Forja.bancada and _robo_da_bancada(l):  # a pergunta de hoje: ✕ se ouviu o canto às cegas, ○ se não (canto.gd:579-585)
		return
	if _notas[l].is_empty():
		return
	var nt: Dictionary = _notas[l][0]
	if int(nt.n) != _robo_nota[l]:
		_robo_nota[l] = int(nt.n)
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 250 ms tarde
		_robo_atraso[l] = 0.0 if Forja.robo_acerta() else 0.25
	var chamada := int(round((float(nt.b) - 4.0) * 2.0))
	var ouviu: bool = _robo_ouviu[l].has(chamada) or _robo_ouviu[l].has(chamada + 1)
	if ouviu and agora >= float(nt.t) + float(_robo_atraso[l]):
		var som := str(_robo_ouviu[l].get(chamada, _robo_ouviu[l].get(chamada + 1, "")))
		Forja.robo_apertar(l, BOTAO[maxi(SOM.find(som), 0)], 0.06)  # a altura que ouviu, não a da partitura
		_robo_nota[l] = 99999  # já respondeu esta
```

(O ataque ouvido cai logo depois da batida da chamada — o som anda até o
controle —, por isso o robô aceita a meia batida da chamada ou a seguinte.)

## Os ganchos

O que muda do `canto.gd` de hoje:

| hoje | n'O Canto novo |
| --- | --- |
| `class_name SalaCanto`, `extends SalaJogo` | `extends Minigame`, sem `class_name`, o cabeçalho de "A ficha de dados" |
| `_init()` | sai: o `papel_som` vira a chave `"papel_som"` da FICHA (H08; a bancada afina o alto-falante no aviso, F02); o resto vai para a FICHA e o `montar` |
| `sino()`, `_montar_torre()`, `SINO_TV`, `PERFIL` | vão para `CenarioDoCanto` (facetado e fosco) |
| `_montar_raia()` | o de "O cenário", sem a partitura |
| `_novo_jogador()` | fica (a bancada), mais `frases`, `trincas` em variáveis do minigame |
| `iniciar_jogo()` com o plano das fontes | o plano das fontes só com `Forja.bancada` |
| `estado`, `PREPARO`/`CANTO`/`PERGUNTA`/`REVELA`/`REPETE` | o jogo é das notas; `CANTO`/`PERGUNTA`/`REVELA` ficam em `estado_bancada`, só na bancada; `REPETE` e `_fechar_repeticao` saem |
| `_comecar_canto`, `_tocar_nota`, `_fechar_pergunta`, `pergunta()`, `dar_vereditos()` | ficam iguais (a bancada) |
| `_process`/`_mostrar` | `_mostrar(l)` no fim do `jogar`: o sino da vez balança, trincas, brilho |
| `status()` | `"%d frases" % frases[l]` quando `na_raia(l)` |
| `progresso()` | sai (a barra de tempo do kit) |
| `dica()` | `{"partes": ["@cross", "Grave", "@circle", "Aguda"], ...}` quando `na_raia(l)` e `not aprendeu(l)` |
| `_robo` | `robo(l, dt)` de cima, com a parte da bancada de hoje em `_robo_da_bancada(l)` |
| `com_poucos()` | `""` |

O esqueleto:

```gdscript
var _notas := [[], [], [], []]  ## as notas de resposta, em ordem
var _chamadas: Array = []  ## [lugar, batida, altura] a tocar
var _ultima := [{}, {}, {}, {}]
var _gerado := 1
var _compasso := 0  ## o último compasso que deu o tempo forte
var _fora := [false, false, false, false]
var _frase := {}  ## id da frase -> {lugar, notas, boas}
var frases := [0, 0, 0, 0]
var trincas := [0, 0, 0, 0]
var _pulso := [0.0, 0.0, 0.0, 0.0]
var _grande := {}
var _sinos := {}  ## lugar -> o sino pequeno
var j := {}  ## lugar -> o estado da bancada (o _novo_jogador de hoje)


func montar() -> void:
	camera_pos = Vector3(0, 5.6, 11.2)
	camera_olhar = Vector3(0, 1.6, -1.0)
	_grande = CenarioDoCanto.montar(self)
	for p in jogadores:
		var l: int = p.lugar
		j[l] = _novo_jogador()
		raia(l)
		posicionar(l)
		p.preso = true
		_sinos[l] = _montar_o_sino(l)  # suporte, sino facetado, trincas escondidas
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


func jogar(dt: float) -> void:
	var c := int(floor(Ritmo.batida() / 4.0))
	if c > _compasso:
		_compasso = c
		CenarioDoCanto.tempo_forte()
		for l in presentes():
			if conectado(l):
				Forja.sentir(l, "toque")
	while _gerado <= c + 1:
		_gerar_compasso(_gerado)  # chamadas nos ímpares (com as respostas), nada nos pares
		_gerado += 1
	if Forja.bancada:
		_bancada(dt)  # o canto às cegas a cada BANCADA_A_CADA compassos
	var agora := Ritmo.t_musica()
	_tocar_as_chamadas(agora)  # CenarioDoCanto.falante + o evento "chamada"
	for l in presentes():
		_apagar_o_pulso(l, dt)
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_notas[l] = _notas[l].filter(func(nt): return float(nt.t) > agora)
		if Forja.apertou(l, Forja.CRUZ):
			_responder(l, GRAVE)
		elif Forja.apertou(l, Forja.CIRCULO):
			_responder(l, AGUDA)
		while not _notas[l].is_empty() and agora > float(_notas[l][0].t) + FOLGA_PERDIDA:
			var nt: Dictionary = _notas[l].pop_front()
			_ultima[l] = nt
			nota_perdida(l, int(nt.n))
		_mostrar(l)
	CenarioDoCanto.balancar(_grande, 0.4 if fmod(Ritmo.batida(), 4.0) < 0.5 else 0.0)


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	marcar(l, PONTOS[julgamento])  # o item, o kit já aplicou (H08)
	CenarioDoCanto.falante(self, l, SOM[int(nt.altura)], 0.8)
	CenarioDoCanto.luz_da_nota(l, 0.6)
	_pulso[l] = PULSO_S
	_contar_na_frase(l, nt, true)  # a frase inteira: frases, FRASE_INTEIRA, conserto do sino


func falha(l: int) -> void:
	_contar_na_frase(l, _ultima[l], false)
	_rachar(l)
```

`_responder(l, altura)` acha a nota de resposta do lugar a até `JANELA_BOM`,
põe em `_ultima[l]`, tira da lista e chama `julgar_toque` (altura certa) ou
`nota_perdida` (errada). `_apagar_o_pulso` volta `luz_da_nota(l, 1.0)` quando
`_pulso` chega a 0. O `_bancada(dt)` segue "O Modo bancada".

Onde mora e o catálogo: `godot/scripts/minigames/s06/o_canto.gd`;
`Catalogo.MINIGAMES["S06_J26"] = preload("res://scripts/minigames/s06/o_canto.gd")`;
`"minigames": ["S06_J26"]` na seção `S06`; sai `"canto"` de `SALAS_ANTIGAS`.
`git rm godot/scripts/salas/canto.gd godot/scripts/salas/canto.gd.uid`. Os
`.uid` novos (`o_canto.gd.uid`, `cenario_do_canto.gd.uid`). Traduções (as
que ainda não existirem): `"Repita!": "Repeat!"`, `"Grave": "Low"`,
`"Aguda": "High"`, `"%d frases": "%d phrases"`.

## O que o registro mede

- `som_controle` (H07) de cada chamada: `seq`, `som`, `placa`.
- `pista` (`canal` `alto_falante`) (n da resposta, som, `no_controle`) e o `toque` do kit
  com o mesmo `n`: a chamada que não chegou vira resposta errada ou nenhuma.
- Na bancada, a `pergunta` (`"canto"`), a `resposta` de hoje e o veredito
  `alto_falante`.

## Armadilhas

- **A barra de luz nunca pulsa na chamada:** ela entregaria a vez e o ritmo
  sem o som. Só na resposta.
- **Um som por vez no controle** (H07): a nota da resposta corta a nota do
  kit, e a próxima chamada do mesmo lugar vem pelo menos quatro batidas
  depois — não há colisão de chamada com resposta.
- **A saída silenciosa:** sem alto-falante, a chamada vai para a TV e o
  `pista` (`canal` `alto_falante`) diz `no_controle: false`; o jogo não trava nem pula o lugar.
- **O `_init` com `super()` na primeira linha** (H04: sem ele, a FICHA não é lida).
- **Sem faixa, o compasso é o sino:** o `tempo_forte()` toca em todo
  compasso; não o desligue quando a faixa chegar.
- **Os pontos e o item:** o kit aplica `Itens.pontos_do_acerto` no `julgar_toque`
  (H08); marque cru.

## Pronto quando

O Canto joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos
três temperamentos; aguenta o cabo que cai e volta; fecha com vencedor;
`--sala=canto` abre o `S06_J26`; com `--bancada`, o canto às cegas aparece a
cada oito compassos e o veredito `alto_falante` sai como antes; a prova do
jogo passa nas duas rodadas; e `bash tests/prova_visual.sh` passa com a
**prancha olhada** com O Canto nela — `Partida.NA_ORDEM` inclui o Canto (H08), e o
`Catalogo.sortear` põe o `S06_J26` na noite: rode a prova visual com a
semente que o sorteia (`--semente=N`).

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd` (o `_joga_o_minigame` é o da
[L1](L1-o-cerco.md#provas); se ainda não existir, crie-o com aquele código):

```gdscript
## O Canto (S06_J26): o apelido abre o minigame; a chamada chega ao
## alto-falante simulado só de quem é a vez; fora da bancada, nenhuma pergunta;
## o registro tem a chamada e a resposta.
func _prova_do_canto() -> void:
	var dois_juntos := [0]
	var tocou := [false]
	var olhar := func(m: Minigame) -> void:
		var tocando := 0
		for l in m.presentes():
			if float(Forja.som_virtual(l).get("falante", 0.0)) > 0.3:
				tocando += 1
				tocou[0] = true
		if tocando >= 2 and fmod(Ritmo.batida(), 8.0) < 4.0:
			dois_juntos[0] += 1
	var mg = await _joga_o_minigame("canto", 130.0, olhar)
	if mg == null:
		return
	_esperar(mg.id == "S06_J26", "Canto: --sala=canto abre o S06_J26")
	_esperar(tocou[0], "Canto: a chamada chegou a um alto-falante simulado")
	var chamadas := _linha_do_tempo().filter(func(e): return e.get("tipo") == "pista" and e.get("slot") == "S06_J26" and e.get("evento") == "mandou")
	_esperar(chamadas.size() >= 1 and chamadas.any(func(e): return bool(e.get("no_controle", false))), "Canto: %d chamadas, no controle" % chamadas.size())
	if not Forja.bancada:
		_esperar(_linha_do_tempo().filter(func(e): return e.get("o") == "pergunta" and e.get("sala", e.get("slot", "")) == "S06_J26").is_empty(), "Canto: fora da bancada, nenhuma pergunta")
```

(`dois_juntos` fica como informação na mensagem de quem quiser olhar: a
nota de uma chamada dura 0,42 s e a vez seguinte começa uma batida depois;
com `--fixed-fps 60` a sobreposição curta é normal e não reprova.) As
checagens de hoje que olham `"canto"` pelo id passam a olhar pelo apelido
(`_e_a_sala` da H04).

**O que o André joga e sente** (`./run-local.sh -- --sala=canto`, com os
quatro controles, dois no cabo e dois no rádio):

- a frase sai da própria mão e dá para repetir sem olhar a tela;
- o grave e o agudo se distinguem no alto-falante pequeno;
- a volta da chamada pela roda (P1, P2, P3, P4) soa como uma frase inteira;
- a barra de luz pulsa com a nota da resposta, nunca na chamada;
- com `--bancada`, o canto às cegas a cada oito compassos, e só nela.

## Ao terminar

- No [quadro](README.md): a linha **N1** (se o quadro só tem a linha **N**
  da seção, acrescente abaixo dela
  `| [N1](N1-o-canto.md) | N | S6 — O Canto | G | Sonnet | 2,0 | feito (<commit>) | <gasto> |`),
  com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: O Canto no kit — chamada e resposta no alto-falante de cada um`
