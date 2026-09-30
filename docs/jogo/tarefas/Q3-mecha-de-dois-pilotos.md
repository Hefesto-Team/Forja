# Q3 — Mecha de Dois Pilotos

**Sprint:** Q · **Slot:** S09_J43 · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 1,5 · **Depende de:** H04, F09, H07, G03, Q1

## Por quê

Cada dupla pilota um mecha: um é a perna esquerda, o outro a direita. Andar
é alternar os passos no tempo; o soco só sai com **os dois apertando o R2
juntos**, até o clique da arma, no gongo. Fora de sincronia, o mecha soca a
própria cabeça. É o 2v2 da sincronia: a dupla que respira junta vence.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) e [o kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A ficha-mãe da seção](Q-a-prova.md) (as equipes, o Aprendiz, as cores) e a [Q1](Q1-a-prova.md) (o `_saida`, o R2 cruzando 0,6)
- [11 — monstro é peça do kit mais um brilho](../11-arte-e-personagens.md#as-regras-de-coerência)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S09_J43",
	"titulo": "Mecha de Dois Pilotos",
	"verbo": "Pilote juntos!",
	"genero": "2v2",
	"icone": "r2",
	"entradas": [Forja.CRUZ],
	"camera": "fixa",
	"faixa": "MUS_S09_J43",
	"duracao": 100.0,
	"fim": "ultimo_em_pe",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "explosao"],
	"material": "metal",
	"microjogo": {"verbo": "Pilotem!", "segundos": 7.0},
	"papel_som": Forja.PAPEL_HAPTICA,  # o kit abre este papel de som no entrar() (H08)
	"gesto": "attack-melee-right",
}
```

(As entradas: o ✕ — o passo — e o R2, eixo, o soco.)

## Como se joga

A faixa é `MUS_S09_J43`, 145 bpm (uma batida ≈ 0,41 s). `BATIDA_DA_PRIMEIRA_NOTA` (4, do kit: H08).

- **As equipes:** a regra da ficha-mãe (com o Aprendiz). Em cada equipe, o
  primeiro é a **perna esquerda** (E), o segundo a **direita** (D).
- **Os mechas** frente a frente: o da Brasa começa em `x = -4`, o da Maré em
  `x = 4`; a distância entre eles é `_dist` (começa em 8 m; mínimo 2,2).
- **O ciclo** tem 8 batidas (dois compassos), a partir de `g0 = BATIDA_DA_PRIMEIRA_NOTA + 8k`:

  | batida | E | D |
  | --- | --- | --- |
  | `g0 + 0` | **o soco** (R2) | **o soco** (R2) |
  | `g0 + 1`, `+ 3`, `+ 5`, `+ 7` | — | passo (✕) |
  | `g0 + 2`, `+ 4`, `+ 6` | passo (✕) | — |
  | `g0 - 1` (a batida antes do soco) | o gongo: `Forja.som_falante(l, "pronto", 0.8)` nos dois pilotos | idem |

- **O passo:** ✕ no tempo → `julgar_toque(l, t(bn), n)`; o mecha avança
  `PASSO[j]` (`[0.0, 0.25, 0.3, 0.35]` m) na direção do outro (a distância
  nunca abaixo de 2,2); a perna do piloto pisa (a coluna gira para a frente e
  volta em meia batida, pela batida). **A perna na mão:** meia batida antes
  de cada passo do piloto, ele sente a própria perna levantar no atuador do
  lado dela — `Forja.som_haptica(l, "material:metal", "")` (E) ou
  `(l, "", "material:metal")` (D), ganho 0,6 —, longe do acerto do kit (que
  cai na batida, nos dois lados).
- **O soco:** o R2 cruzando 0,6 subindo no tempo do gongo →
  `julgar_toque(l, t(g0), n)` para cada piloto (nota de cada um). Guarde o
  instante do aperto de cada um (`_aperto_t[l] = Ritmo.t_musica()`). Quando
  os dois pilotos do mecha foram julgados:
  - **os dois sem erro e a menos de `SINC := 0.09` s um do outro**, com
    `_dist <= ALCANCE` (3,2 m) → **o soco entra**: o outro mecha leva
    `ABALO := 1.0`, é empurrado 1,5 m para trás; os dois pilotos marcam 150;
  - **os dois sem erro, em sincronia, fora do alcance** → o soco corta o ar
    (nada, e ninguém é punido);
  - **fora de sincronia** (um só acertou, ou mais de `SINC` entre eles) →
    **o mecha soca a própria cabeça** (a falha): `_abalo[e] += 0.5`.
  O R2 é `GATILHO_ARMA` (2, 6, 8) o jogo inteiro: a parede e o clique estão
  no dedo.
- **A queda:** um mecha com `_abalo >= 3.0` cai (a explosão): a outra equipe
  ganha a **queda** (`_quedas[e] += 1`). Os dois voltam a 8 m, os abalos
  zeram, e o ciclo seguinte recomeça depois de um ciclo inteiro de pausa (a
  música segue; a TV mostra o mecha levantando). **Melhor de três:** a
  primeira equipe com 2 quedas vence.
- **O hoqueto:** E pisa nas pares, D nas ímpares — o mecha anda no
  pingue-pongue das duas pernas; o soco é o acorde dos dois; a nota de cada
  lugar soa na TV (kit).
- **A partitura simples** (`Ritmo.simples[l]`): o lugar pisa só no primeiro
  passo dele em cada compasso; o soco continua dele.
- **O pico — o ringue fecha:** no ciclo do meio
  (`_pico_k := floor(ciclos_previstos / 2)`), os dois mechas são puxados para
  3 m (o alcance) e há gongo também em `g0 + 4` (dois socos no ciclo).

`ciclos_previstos = floor((duracao / _t_batida() - BATIDA_DA_PRIMEIRA_NOTA) / 8)`.

## O cenário

- **O ringue:** `Kit.arena(self, 6, 4)`, a luz da casa cheia:
  `luzes([Vector3(-10, 3, -6), Vector3(10, 3, -6), Vector3(0, 4, 6)])`,
  `atmosfera(Color("#ffb86c"), Tema.ROXO, true, 40, 24.0, -9.8)`; o chão de
  cada lado em cor de equipe (`Kit.caixa(self, Vector3(11, 0.03, 8), Vector3(±5.5, 0.015, 0), cor_equipe.darkened(0.3))`,
  fosco).
- **O mecha** (peças do kit mais um brilho), um `Node3D` por equipe: as
  pernas `Kit.peca(mecha, "column", Vector3(±0.8, 0, 0), 0.0, 1.4)` (a da
  esquerda gira no passo de E, a da direita no de D); o tronco
  `Kit.caixa(mecha, Vector3(2.2, 1.6, 1.4), Vector3(0, 3.4, 0), aco)`
  (`aco := Kit.material(Color("#5b6275"), 0.0, 0.6)`); o peito
  `Kit.caixa(mecha, Vector3(1.2, 0.8, 0.1), Vector3(0, 3.5, ±0.72), cor_equipe)`
  (fosco); a cabeça `Kit.caixa(mecha, Vector3(1.0, 0.7, 0.9), Vector3(0, 4.6, 0), aco)`
  com o visor emissivo `Kit.caixa(..., Vector3(0.7, 0.14, 0.06), ...)` `#ff3a1a`
  (o olho); os braços `Kit.caixa(mecha, Vector3(0.5, 1.4, 0.5), Vector3(±1.4, 3.2, 0), aco)`
  — o soco estica o braço da frente 1,2 m em meia batida. Os mechas se olham
  (`rotation.y` para o outro).
- **Os pilotos** em pé nos ombros do mecha: E em `mecha + (0, 4.3, -0.6)`, D
  em `mecha + (0, 4.3, 0.6)` (a câmera de lado), `p.preso = true`,
  `attack-melee-right` no soco, `idle` no resto. O Aprendiz, se houver, no
  ombro dele.
- **A câmera:** de lado, `camera_pos = Vector3(0, 7.5, 13.0)`,
  `camera_olhar = Vector3(0, 3.0, 0)`.
- **Checklist de arte (11):** os mechas são `column` + caixas + o visor
  emissivo; o peito na cor da equipe, fosco; nenhuma cor de lugar no mecha;
  a prancha com os dois mechas e os pilotos nos ombros.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **gatilho (tudo junto)** | o R2 com a parede e o clique (`ARMA` 2, 6, 8): o soco | o jogo todo |
| **háptica** | a própria perna levantando, no atuador do lado dela | meia batida antes de cada passo |
| **alto-falante do dono** | o gongo (`pronto`) uma batida antes do soco, nos dois pilotos | antes de cada soco |
| vibração | levou soco: `Forja.sentir(l, "golpe")` nos dois pilotos do mecha atingido; a queda: `explosao` nos dois | no soco; na queda |
| barra de luz | a cor do lugar, sempre | — |
| luzinhas | o número do jogador, sempre | — |
| TV | o grave pesado; `Som.tocar("martelo", pos, 2.0)` e `tremor = 0.8` no soco que entra; `Som.tocar("golpe", cabeca, -2.0)` na cabeçada própria; `Som.tocar("especial")` na queda | — |

**No rádio:** a perna levantando vira `Forja.sentir(l, "golpe_esq", 120)`
(E) ou `Forja.sentir(l, "golpe_dir", 120)` (D) — meia batida (≈ 0,2 s) antes
do acerto do kit, sem encostar nele; a `troca` uma vez. **Sem alto-falante**
(o rádio), o gongo vai pela mão: `Forja.sentir(l, "toque")` uma batida antes
do soco, no lugar do `pronto`. O microfone fica de fora.

## A falha

- **O passo errado:** a perna tropeça (a coluna gira para trás), o mecha
  recua 0,2 m, e o piloto faz `emote-no` (0,3 s).
- **O soco fora de sincronia:** o braço do mecha dá a volta e acerta a
  própria cabeça (a cabeça gira 30° e volta em uma batida), a TV bate o golpe,
  e o mecha leva meio abalo. É a piada da seção.

## O fim e o vencedor

A primeira equipe com 2 quedas vence: todos acabam no fim daquele ciclo.
Sem isso, o kit fecha no `duracao`: vence a equipe com mais quedas; no
empate, a com menos abalo agora; depois, mais pontos. `vencedor()` devolve os
da equipe vencedora (pelos pontos) e depois os da outra.

## Com menos de quatro

- **3, 2, 1:** a regra da ficha-mãe, com o Aprendiz. O Aprendiz pisa com 85%
  (sempre BOM) e, no soco, aperta **exatamente** no tempo do gongo com 70%
  (senão, não aperta) — é o humano que tem de sincronizar com ele. Não é
  lugar, não pontua, não entra no registro de notas. `com_poucos()`:
  `"Com o Aprendiz"` (3, 2) ou `"Você e o Aprendiz contra 2"` (1).
- **O controle que cai:** o piloto sem controle não pisa nem soca, e o soco
  do parceiro vale sozinho enquanto ele estiver fora (o sincronismo é
  dispensado: ninguém é punido pelo cabo). Volta no ciclo seguinte.

## O robô

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var n: int = _nota[l]
	if n < 0 or _robo_tocou[l] == n:
		return
	if _robo_nota[l] != n:
		_robo_nota[l] = n
		# quando não acerta: atrasa 0,12 s — no soco, sai fora de sincronia
		_robo_mira[l] = 0.0 if Forja.robo_acerta() else 0.12
	if Ritmo.t_musica() < float(_alvo[l]) + float(_robo_mira[l]):
		return
	if _e_soco[l]:
		Forja.robo_eixo(l, Forja.R2, 1.0, 0.08)
	else:
		Forja.robo_apertar(l, Forja.CRUZ, 0.05)
	_robo_tocou[l] = n
```

## Os ganchos

`godot/scripts/minigames/s09/mecha_de_dois_pilotos.gd`, `extends Minigame`.

```gdscript
extends Minigame
## Mecha de Dois Pilotos (S09_J43). Cada dupla pilota um mecha: um é a perna
## esquerda, o outro a direita, e o mecha anda com os passos alternados no
## tempo (✕). No gongo, os dois apertam o R2 até o clique juntos: o soco.
##
## A falha: fora de sincronia, o mecha soca a própria cabeça. O vencedor:
## melhor de três quedas. O alto-falante do dono: o gongo. O registro mede: o
## gatilho de arma (saida), o passo de cada pé na háptica do lado, e a
## diferença entre os dois apertos do soco. O robô: pelo relógio. Com menos
## de quatro: o Aprendiz pilota a outra perna. A régua: o verbo é o que se
## faz; a cor da equipe está no mecha.

const FICHA := { ... }

const CICLO := 8
const DIST_INICIAL := 8.0
const DIST_MIN := 2.2
const ALCANCE := 3.2
const PASSO := [0.0, 0.25, 0.3, 0.35]
const SINC := 0.09
const ABALO := 1.0
const QUEDA := 3.0
const EMPURRAO := 1.5
const ACERTO_APRENDIZ_PASSO := 0.85
const ACERTO_APRENDIZ_SOCO := 0.7
const COR_EQUIPE := [Color("#e8a33c"), Color("#2fb3b3")]

var _equipe := {}
var _perna := {}               ## lugar -> 0 (E) / 1 (D)
var _aprendizes := []          ## {equipe, perna, no, anim}
var _dist := DIST_INICIAL
var _x := [-4.0, 4.0]          ## o x de cada mecha (a distância, dividida)
var _abalo := [0.0, 0.0]
var _quedas := [0, 0]
var _pausa_ate := -1.0         ## depois de uma queda, um ciclo sem notas
var _nota := [-1, -1, -1, -1]
var _alvo := [0.0, 0.0, 0.0, 0.0]
var _e_soco := [false, false, false, false]
var _n := [0, 0, 0, 0]
var _feita := [-1.0, -1.0, -1.0, -1.0]
var _r2_antes := [0.0, 0.0, 0.0, 0.0]
var _perna_b := [-1.0, -1.0, -1.0, -1.0]   ## quando a perna levanta na mão (meia batida antes do passo)
var _soco := [{}, {}]           ## equipe -> {g0, julgados, certos, tempos}
var _fim_batida := -1.0
var _pico_k := 999
var _rumble := [false, false, false, false]
var _nos := {}
var _robo_nota := [-1, -1, -1, -1]
var _robo_tocou := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	usa_gatilho = true
	camera_pos = Vector3(0, 7.5, 13.0)
	camera_olhar = Vector3(0, 3.0, 0)
	# as equipes e os Aprendizes; os dois mechas; os pilotos nos ombros


func iniciar_jogo() -> void:
	for l in presentes():
		_saida(l, Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, 8))
		# o rádio: _rumble e a troca
	# o _pico_k


func jogar(_dt: float) -> void:
	var b := Ritmo.batida()
	_gongo(b)                       # na batida antes de cada soco: o pronto nos dois pilotos de cada mecha
	for l in presentes():
		if not conectado(l):
			_nota[l] = -1
			continue
		_abrir_nota(l, b)           # a próxima: passo da perna dele ou soco; uma batida antes; nada na pausa
		_entrada(l)                 # ✕ no passo; R2 cruzando 0,6 no soco (guarda _aperto_t); julgar_toque
		_prazo(l)                   # a nota que passou: nota_perdida
	_aprendizes_pilotam(b)
	_resolver_socos(b)              # quando os dois pilotos de um mecha foram julgados (ou a janela fechou)
	if _fim_batida > 0.0 and b >= _fim_batida:
		for l in presentes():
			acabou[l] = true
	_mostrar(b)


func toque(l: int, j: int) -> void:
	if _e_soco[l]:
		_soco_de(l, j)              # guarda o julgamento e o instante; o _resolver_socos decide
	else:
		marcar(l, [0, 50, 75, 100][j])
		_andar(_equipe[l], PASSO[j], _perna[l])


func falha(l: int) -> void:
	if _e_soco[l]:
		_soco_de(l, Ritmo.ERRO)
	else:
		_andar(_equipe[l], -0.2, _perna[l])
		jogador(l).gesto("emote-no", 0.3)


func vencedor() -> Array:
	var e := 0 if _quedas[0] > _quedas[1] else (1 if _quedas[1] > _quedas[0] else (0 if _abalo[0] < _abalo[1] else (1 if _abalo[1] < _abalo[0] else _mais_pontos())))
	var ganhou := presentes().filter(func(l): return _equipe[l] == e)
	var perdeu := presentes().filter(func(l): return _equipe[l] != e)
	ganhou.sort_custom(func(a, b): return pontos[a] > pontos[b])
	perdeu.sort_custom(func(a, b): return pontos[a] > pontos[b])
	return ganhou + perdeu
```

`_resolver_socos(b)`: para cada equipe com um soco aberto, quando os pilotos
com controle foram julgados (o Aprendiz decide na batida exata, com o `rng`)
ou a janela fechou (`t(g0) + JANELA_BOM`): sincronizados (todos sem erro e
`absf(t_E - t_D) <= SINC`; com um piloto sem controle, basta o outro) e no
alcance → o soco entra (`_abalo[outra] += ABALO`, o empurrão, 150 para
cada piloto, `Forja.sentir(l, "golpe")` nos pilotos da outra, a TV);
sincronizados e fora do alcance → o ar; fora de sincronia → a cabeçada
(`_abalo[e] += 0.5`). Depois, se algum `_abalo >= QUEDA`: a queda
(`explosao` nos dois pilotos do que caiu, `_quedas[outra] += 1`, os dois a
8 m, abalos a zero, `_pausa_ate = b + CICLO`); com 2 quedas,
`_fim_batida = b + CICLO`. `_andar(e, d, perna)`: o mecha `e` anda `d` para o
outro (a distância entre `DIST_MIN` e 12); a perna gira (pela batida). A
perna na mão sai do `_abrir_nota` (a nota abre uma batida antes; a perna,
meia batida antes: guarde em `_perna_b[l]` e mande quando `b >= _perna_b[l]`).
`_saida` é o da Q1.

Dica (com `na_raia(l)`, a `pos` no pé do mecha): `["@cross"]` no passo e
`["@r2"]` no soco, enquanto `not aprendeu(l)`. `status(l)`:
`"Brasa %d" % _quedas[0]` / `"Maré %d" % _quedas[1]`.

Catálogo: `"S09_J43"` em `MINIGAMES` e na seção `S09`. Traduções:
`"Mecha de Dois Pilotos": "Two-Pilot Mech"`, `"Pilote juntos!": "Pilot together!"`,
`"Pilotem!": "Pilot!"`.

`_t_batida()` (a duração de uma batida, em s, para o pico):
`return Ritmo.t_da_batida(1.0) - Ritmo.t_da_batida(0.0)`.

`_mais_pontos()`: a equipe com mais pontos somados dos seus lugares (a Brasa
no empate).

## O que o registro mede

- `saida` do gatilho de arma de cada um (uma vez) e das vibrações de cada
  soco e queda, com `seq` e `ok`;
- `som_controle` da perna de cada piloto, no atuador do lado — a noite vê se
  os dois lados chegam, por controle;
- `toque` dos dois apertos de cada soco (a diferença entre eles é o
  sincronismo da dupla — a noite compara cabo e rádio: o rádio atrasa um
  dos dois?).

## Armadilhas

- **O R2 é o soco, o ✕ é o passo:** nunca os dois na mesma batida para o
  mesmo piloto (a tabela do ciclo garante: o soco é na `g0 + 0`, e ninguém
  pisa nela).
- **O sincronismo usa o instante do aperto**, não o julgamento: dois BONS de
  lados opostos da janela (um adiantado, um atrasado) podem estar a 200 ms um
  do outro — isso é fora de sincronia.
- **O Aprendiz não é robô** (é regra do jogo, com o `rng` do kit).
- **`usa_gatilho = true`** e o R2 em `ARMA` a partida inteira; o L2 é do item.
- **Na prova o pico não chega** (o fim é pelo `duracao`).

## Pronto quando

Joga do aviso ao resultado com 4, 3, 2 e 1 jogador (com o Aprendiz) e com o
robô nos três temperamentos (o ruim se esmurra); aguenta o cabo que cai e
volta; fecha com uma equipe vencedora; o R2 fica em arma (0x25) o jogo
inteiro; a prova do jogo passa; e `bash tests/prova_visual.sh` passa com a
prancha olhada (os dois mechas, os pilotos, um soco).

## Provas

Em `godot/testes/prova_do_jogo.gd`, uma `_prova_mecha()`:

```gdscript
## S09_J43: o R2 de cada um em arma; a perna de cada piloto treme só o
## atuador do lado dela; os mechas se aproximam; fecha com vencedor.
func _prova_mecha() -> void:
	# a espera é a do `_joga_o_minigame` da H08: o aviso em quadros, o jogo pelo relógio de parede (100 s de música e o treino)
	var arma := [false, false, false, false]
	var viu_pe := [false]
	var olhar := func(s) -> void:
		for l in 4:
			if int(_perc(l).get("gatilho_dir", 0)) == 0x25:
				arma[l] = true
			var v := Forja.som_virtual(l)
			var meu := float(v.get("esq" if s._perna[l] == 0 else "dir", 0.0))
			var outro := float(v.get("dir" if s._perna[l] == 0 else "esq", 1.0))
			if meu > 0.05 and outro < 0.02:
				viu_pe[0] = true
	var sala = await _joga_o_minigame("S09_J43", 140.0, olhar)
	if sala == null:
		return
	for l in 4:
		_esperar(arma[l], "mecha P%d: o R2 em arma (0x25)" % (l + 1))
	_esperar(viu_pe[0], "mecha: a perna treme só o atuador do lado dela")
	_esperar(sala._dist < sala.DIST_INICIAL, "mecha: os mechas andaram (%.1f m)" % sala._dist)
```

`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**Com o André (local):** `./run-local.sh -- --sala=S09_J43`, duas duplas. O
pingue-pongue das pernas tem de virar dança; o soco junto tem de exigir
olhar para o parceiro; a cabeçada própria tem de fazer a sala rir. Com um
no rádio, confira no registro a diferença dos apertos do soco.

## Ao terminar

- No [quadro](README.md), a linha Q3: **feito**, com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: Mecha de Dois Pilotos — as duas pernas no tempo, o soco em sincronia`
