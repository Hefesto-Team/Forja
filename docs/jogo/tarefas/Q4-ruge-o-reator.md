# Q4 — Ruge o Reator

**Sprint:** Q · **Slot:** S09_J44 · **Tamanho:** G · **Modelo:** Sonnet · **Estimativa:** US$ 2,0 · **Depende de:** H04, F09, H07, G03, Q1, O1 (as linhas `pista`/`troca`), e as seções S1 a S4 prontas (as mecânicas que as estações resumem)

## Por quê

O dragão do reator acorda, e a plataforma comum dos quatro só aguenta se a
turma aguentar. Quatro estações de 24 s, uma atrás da outra, sem pausa, na
mesma música — **bater** (S1), **equilibrar** (S2), **traçar** (S3),
**defender** (S4) — e um final em que as quatro se revezam a cada compasso.
Cada erro tira um pedaço da plataforma. É o medley da primeira metade do
jogo: a noite inteira num minuto e meio.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) e [o kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A ficha-mãe da seção](Q-a-prova.md), em especial "Os medleys" (por que
  mini-versões, e não o catálogo em modo trecho)
- A [O1](O1-os-caminhos.md) (o `_respondeu`, a linha `troca`)
- `godot/scripts/salas/viga.gd:307-316` (`_controle`: a rolagem, a gravidade,
  o analógico) e `:636-690` (o robô que gira o controle simulado);
  `godot/scripts/salas/molde.gd:236-250` (o dedo no touchpad) e o robô dele
  (`robo_tocar`)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S09_J44",
	"titulo": "Ruge o Reator",
	"verbo": "Aguentem!",
	"genero": "coop",
	"icone": "botoes",
	"entradas": [Forja.CRUZ, Forja.L1, Forja.R1],
	"camera": "fixa",
	"faixa": "MUS_S09_J44",
	"duracao": 0.0,
	"fim": "meta_coletiva",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "golpe_esq", "golpe_dir", "explosao"],
	"material": "pedra",
	"microjogo": {"verbo": "Aguentem!", "segundos": 7.0},
	"gesto": "attack-melee-right",
	"treino": false,
}
```

(As entradas-botão são três — ✕, L1, R1 —; o giroscópio e o touchpad também
entram, uma estação cada: cada **estação** usa no máximo duas.)
`duracao` 0: o medley acaba pela música (236 batidas, 118 s), para as quatro
estações rodarem também na prova. Sem treino: são mecânicas que a noite já
ensinou.

## Como se joga

A faixa é `MUS_S09_J44`, 120 bpm (uma batida = 0,5 s). `ENTRADA := 4`.

**O roteiro** (em batidas):

| trecho | batidas | o verbo |
| --- | --- | --- |
| a contagem | 0 a 3 | o dragão abre um olho |
| **1. Bater** (S1) | 4 a 51 | ✕ no seu tempo: o martelo na bigorna |
| **2. Equilibrar** (S2) | 52 a 99 | incline o controle contra o balanço da plataforma |
| **o rugido do meio** (o pico) | 100 a 107 | uma batida de cada verbo, em roda, para todos |
| **3. Traçar** (S3) | 108 a 155 | deslize no touchpad para o lado da seta |
| **4. Defender** (S4) | 156 a 203 | L1 ou R1 do lado de onde vem a garra (a mão sente um tempo antes) |
| **o final — Aguentem!** | 204 a 235 | os quatro verbos, um por compasso (bater, equilibrar, traçar, defender, duas voltas); a última batida, todos ✕ juntos |

- **O hoqueto (nas estações):** a batida `k` de uma estação (contada do
  começo dela) é de `presentes()[k % np]`: com quatro, cada um toca uma vez
  por compasso, e a frase só fica inteira com os quatro; com dois, cada um
  toca duas; com um, todas. Cada nota é aberta uma batida antes. No **rugido
  do meio**, todos tocam todas as batidas, o verbo trocando a cada batida
  (bater, equilibrar, traçar, defender). No **final**, o hoqueto volta, com
  o verbo do compasso; a batida 235 é de todos (✕).
- **A partitura simples** (`Ritmo.simples[l]`): o lugar toca uma nota sim,
  uma não, das dele.

### As estações (cada uma, o menor tamanho da mecânica de origem)

1. **Bater.** ✕ no tempo → `julgar_toque(l, t(bn), n)`. O cavaleiro martela a
   bigorna dele (`attack-melee-right`).
2. **Equilibrar.** No começo de cada compasso, o reator empurra a plataforma
   para um lado (`_lado_balanco`, sorteado com o `rng` do kit: 0 esquerda, 1
   direita); a plataforma inclina (pela batida) e **todos** sentem o empurrão
   na batida 0 do compasso (`Forja.sentir(l, "golpe_esq" / "golpe_dir", 150)`).
   Na nota dele, o jogador inclina o controle **contra**: o balanço para a
   esquerda pede a direita para baixo (a rolagem abaixo de `-INCLINA := -0.35`
   rad), e vice-versa (acima de `+0.35`). O "aperto" é o quadro em que a
   rolagem cruza o limite do lado certo (`Forja.postura(l).x`, como a Viga);
   cruzar o do lado errado, dentro da janela, é erro. Sem giroscópio
   (`not Forja.capacidade(l, "giro")`): a gravidade (`Forja.acel`), e sem ela
   o analógico esquerdo (`Forja.eixo(l, Forja.LX)` além de ±0,6) — com a
   `troca` (`recurso` `giroscopio`, `para` `analogico`, `motivo`
   `sem_giroscopio`).
3. **Traçar.** Na nota dele, a runa à frente do cavaleiro mostra uma seta
   (`_seta[n]`, esquerda ou direita, pelo `rng`), acesa uma batida antes. O
   jogador desliza o dedo no touchpad para aquele lado: o "aperto" é o
   quadro em que o dedo 0, apoiado (`Forja.dedo(l, 0).z > 0.5`), já andou
   `TRACO := 0.25` na direção da seta desde onde tocou; andar 0,25 para o
   outro lado é erro.
4. **Defender.** Uma batida antes da nota dele, a garra do reator anuncia o
   lado **só na mão dele** (`Forja.sentir(l, "golpe_esq" / "golpe_dir", 150)`,
   uma `pista` com `via` `rumble` e `o_que` o lado); na nota, L1 (esquerda) ou
   R1 (direita). O botão do lado errado é erro.

- **A plataforma comum:** `_integridade` começa em 100. Cada erro (toque ERRO
  ou nota que passou) tira `_custo_erro`; cada PERFEITO devolve
  `_custo_erro / 4` (até 100). `_custo_erro = 100.0 / (0.35 * _notas_previstas)`,
  com `_notas_previstas` contadas do roteiro no `iniciar_jogo()` (com os
  presentes de então): a plataforma cai se a turma errar mais de 35% das
  notas. Em 0, **a plataforma cai** (ver "O fim").
- **Pontos:** `[0, 50, 75, 100][j]` por nota; a última batida (todos ✕)
  vale 200 para cada um que acertar.

`t(x)` é `Ritmo.t_da_batida(x)`.

## O cenário

- **O covil do reator:** `Kit.arena(self, 6, 4)`; a luz da casa com néon
  vermelho: `luzes([Vector3(-9, 3, 3), Vector3(9, 3, 3)])`,
  `atmosfera(Color("#ffb070"), Tema.VERMELHO, true, 60, 24.0, -9.0, 0.3)`.
- **O dragão do reator** (peças do kit mais um brilho), no fundo, em
  `(0, 0, -6.0)`: o corpo, três `Kit.peca(self, "wall", ...)` empilhadas
  (escala 1,6); o pescoço, duas `column`; a cabeça,
  `Kit.caixa(self, Vector3(3.0, 1.6, 2.0), Vector3(0, 5.4, -5.0), pedra_escura)`
  (`#3b3345`); a mandíbula, `Kit.caixa(..., Vector3(2.6, 0.5, 1.8), ...)`
  (abre no rugido, pela batida); os olhos, duas caixas `(0.4, 0.2, 0.1)`
  emissivas `#ff3a1a` (energia 1 dormindo, 4 no rugido); os espinhos, três
  `Kit.peca(self, "stairs", ...)` nas costas. O dragão respira: a cabeça sobe
  e desce 0,1 m por compasso (pela batida).
- **A plataforma:** 12 lajes `Kit.caixa(self, Vector3(3.9, 0.3, 2.0), ...)`
  em grade 4 × 3 (x de −6 a 6, z de −1 a 3), pedra `#4a4452`, sob as quatro
  raias; num `Node3D` `_plataforma` que inclina (`rotation.z`) na estação 2.
  Quando `_integridade` cai abaixo de `100 - 100 * (i + 1) / 13` a laje `i`
  (na ordem das bordas para o centro: as da frente e de trás primeiro) cai
  (anda `y` para −6 em uma batida e some).
- **Os cavaleiros:** `raia(l)` e `posicionar(l)` do kit, de frente para o
  dragão (`rotation.y = PI`); `martelo_na_mao(p)`.
- **As peças das estações** (visíveis só na estação delas): a bigorna de cada
  raia (`Kit.bigorna(self, Vector3(RAIAS[l], 0, Z_JOGADOR - 1.2))`); a runa da
  seta (`Kit.caixa` 0,8 × 0,05 × 0,5 com duas caixas em seta, emissiva
  `#f1fa8c` só quando acesa); a garra (`Kit.caixa(self, Vector3(0.6, 0.6, 2.4), ...)`
  de `pedra_escura`, que varre do lado anunciado em meia batida na nota).
- **A câmera:** `camera_pos = Vector3(0, 8.0, 12.0)`, `camera_olhar = Vector3(0, 2.0, -2.0)`.
- **Checklist de arte (11):** o dragão é peças do kit e caixas, os olhos o
  único brilho dele; a runa e a borda da raia são os outros emissivos; nada
  nas cores dos lugares; a prancha com o dragão, a plataforma e os quatro.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| botões | ✕ (bater, o final), L1/R1 (defender) | as estações 1 e 4 |
| giroscópio | a inclinação contra o balanço | a estação 2 |
| touchpad | o traço | a estação 3 |
| **vibração** | o lado do empurrão (estação 2, todos) e da garra (estação 4, só o dono): `golpe_esq`/`golpe_dir` 150 ms; a laje que cai: `Forja.sentir(l, "golpe")` em todos; a plataforma que cai: `explosao` | — |
| háptica por material | o kit (`material:pedra`) nos acertos, no cabo | no toque |
| alto-falante do dono | a nota dele (kit); `Forja.som_falante(l, "coleta", 0.7)` a cada troca de estação (todos) | na troca |
| barra de luz | a cor do lugar, sempre | — |
| gatilho | nada a segurar: `Forja.gatilhos_off(l)` | — |
| TV | o órgão e a marcha; `Som.tocar("transicao")` a cada estação; `Som.tocar("grito", dragao, -2.0)` e `tremor = 1.0` no rugido do meio; `Som.tocar("pedra", laje, -4.0)` a cada laje que cai | — |

**No rádio:** nada muda (as pistas desta ficha já são rumble). **Sem
giroscópio:** a troca da estação 2 (acima).

## A falha

- **Um erro:** o cavaleiro cambaleia (`emote-no`, 0,3 s) e a plataforma
  treme (`tremor = 0.3`); a integridade desce; quando uma laje cai, todos
  sentem o golpe e a laje despenca no abismo.
- **A plataforma cai** (integridade 0): as lajes restantes caem juntas, os
  quatro fazem `fall` e caem uma altura (−2 m), a TV explode, `explosao` em
  todos. O dragão ruge por cima. O medley acaba um compasso depois.

## O fim e o vencedor

`coop = true` no `montar()`. Na batida 236 (depois do ✕ de todos), a
plataforma aguentou: `coop_venceu = true`, o dragão fecha os olhos e cai para
trás (a mandíbula fecha, os olhos apagam), faíscas `#ffb070`. Se a plataforma
caiu antes: `coop_venceu = false`. Em qualquer caso, todos acabam.
`vencedor()`: o destaque — quem errou menos (`_erros[l]`), depois mais pontos.

## Com menos de quatro

- **3, 2, 1:** o hoqueto reparte as batidas por quem joga (a batida `k` é de
  `presentes()[k % np]`); `_notas_previstas` usa os presentes do começo, e o
  `_custo_erro` fica justo para qualquer número.
- **O controle que cai:** as notas dele não abrem (nem erram); a batida dele
  fica **vazia** (ninguém a toca, e a plataforma não sofre por ela). Volta na
  próxima nota dele.
- **Duplas:** não há (coop de todos).

## O robô

Um ramo por estação, sempre pelo controle simulado, mirando pelo relógio;
na estação 4 ele **sente** o lado nos motores (a `percepcao`).

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var n: int = _nota[l]
	if n < 0:
		_robo_voltar(l)                    # o controle volta ao meio (rolagem a zero, dedo solto)
		return
	if _robo_nota[l] != n:
		_robo_nota[l] = n
		_robo_certo[l] = Forja.robo_acerta()
		_robo_mira[l] = 0.0 if _robo_certo[l] else 0.25
		_robo_feito[l] = false
	if _verbo[l] == DEFENDER and Ritmo.t_musica() < float(_alvo[l]) - 0.05:
		var pc := Forja.percepcao(l)
		if float(pc.get("forte", 0.0)) > 0.5 and float(pc.get("fraco", 0.0)) < 0.1:
			_robo_lado[l] = 0
		elif float(pc.get("fraco", 0.0)) > 0.5 and float(pc.get("forte", 0.0)) < 0.1:
			_robo_lado[l] = 1
	var quando := float(_alvo[l]) + float(_robo_mira[l])
	if _robo_feito[l] or Ritmo.t_musica() < quando - _antecipa(_verbo[l]):
		return
	match _verbo[l]:
		BATER:
			Forja.robo_apertar(l, Forja.CRUZ, 0.05)
			_robo_feito[l] = true
		EQUILIBRAR:
			# gira contra o balanço até passar do limite (o ruim gira para o lado errado)
			var sinal := (-1.0 if _lado_balanco == 0 else 1.0) * (1.0 if _robo_certo[l] else -1.0)
			Forja.robo_girar(l, Vector3(0, 0, 6.0 * sinal), 0.06)
			if absf(Forja.postura(l).x) > INCLINA + 0.05:
				_robo_feito[l] = true
		TRACAR:
			var dx := (1.0 if _seta_da_nota[l] == 1 else -1.0) * (1.0 if _robo_certo[l] else -1.0)
			_robo_x[l] = clampf(float(_robo_x[l]) + dx * 0.05, 0.1, 0.9)
			Forja.robo_tocar(l, 0, float(_robo_x[l]), 0.5, 0.06)
			if absf(float(_robo_x[l]) - 0.5) > TRACO + 0.05:
				_robo_feito[l] = true
		DEFENDER:
			var lado: int = _robo_lado[l] if _robo_certo[l] else 1 - int(_robo_lado[l])
			Forja.robo_apertar(l, Forja.L1 if lado == 0 else Forja.R1, 0.05)
			_robo_feito[l] = true
```

`_antecipa(verbo)`: 0 para bater e defender; 0,06 s para equilibrar e traçar
(o gesto leva uns quadros para cruzar o limite). `_robo_voltar(l)`: a rolagem
volta (`Forja.robo_girar(l, Vector3(0, 0, -2.5 * Forja.postura(l).x), 0.06)`)
e o dedo solta (`_robo_x[l] = 0.5`, sem `robo_tocar`).

## Os ganchos

`godot/scripts/minigames/s09/ruge_o_reator.gd`, `extends Minigame`.

```gdscript
extends Minigame
## Ruge o Reator (S09_J44). O dragão acorda. Quatro estações de 24 s sem
## pausa — bater (✕), equilibrar (incline contra o balanço), traçar (deslize
## no touchpad para a seta), defender (L1/R1 do lado que a mão sentiu) — e o
## final, um verbo por compasso. Cada erro tira um pedaço da plataforma comum.
##
## A falha: a laje cai; em zero, a plataforma inteira. O vencedor: coop (a
## plataforma aguenta); o destaque é quem errou menos. O alto-falante do dono:
## a coleta a cada estação. O registro mede: cada estação (estacao) e o
## desvio de cada recurso nela (toque), por controle. O robô: um ramo por
## estação, pelo controle simulado. Com menos de quatro: o hoqueto reparte.
## A régua: o verbo muda, o ícone da estação aparece; nada pergunta nada.

const FICHA := { ... }

enum { BATER, EQUILIBRAR, TRACAR, DEFENDER }
const ENTRADA := 4
const ESTACAO := 48
const ROTEIRO := [
	{"de": 4, "ate": 52, "verbo": BATER},
	{"de": 52, "ate": 100, "verbo": EQUILIBRAR},
	{"de": 100, "ate": 108, "verbo": -1},       # o rugido do meio: todos, o verbo por batida
	{"de": 108, "ate": 156, "verbo": TRACAR},
	{"de": 156, "ate": 204, "verbo": DEFENDER},
	{"de": 204, "ate": 236, "verbo": -2},       # o final: o verbo por compasso; a 235 de todos
]
const FIM := 236
const INCLINA := 0.35
const TRACO := 0.25
const PONTOS := [0, 50, 75, 100]
const NOME_ESTACAO := ["bater", "equilibrar", "tracar", "defender"]

var _trecho := -1
var _nota := [-1, -1, -1, -1]
var _alvo := [0.0, 0.0, 0.0, 0.0]
var _verbo := [BATER, BATER, BATER, BATER]
var _n := [0, 0, 0, 0]
var _feita := -1.0              ## a última batida já distribuída
var _lado_balanco := 0
var _lado_garra := [0, 0, 0, 0]
var _seta_da_nota := [0, 0, 0, 0]
var _dedo_de := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var _rolagem_antes := [0.0, 0.0, 0.0, 0.0]
var _sem_giro := [false, false, false, false]
var _integridade := 100.0
var _custo_erro := 1.0
var _erros := [0, 0, 0, 0]
var _caiu := false
var _fim_batida := float(FIM)
var _nos := {}
# o robô
var _robo_nota := [-1, -1, -1, -1]
var _robo_certo := [true, true, true, true]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]
var _robo_feito := [false, false, false, false]
var _robo_lado := [0, 0, 0, 0]
var _robo_x := [0.5, 0.5, 0.5, 0.5]


func montar() -> void:
	coop = true
	camera_pos = Vector3(0, 8.0, 12.0)
	camera_olhar = Vector3(0, 2.0, -2.0)
	# o covil, o dragão, a plataforma, as raias, as peças das estações; gatilhos_off


func iniciar_jogo() -> void:
	_custo_erro = 100.0 / (0.35 * maxf(1.0, float(_contar_notas())))
	for l in presentes():
		_sem_giro[l] = not Forja.capacidade(l, "giro")
		# a troca de quem não tem giroscópio


func jogar(_dt: float) -> void:
	var b := Ritmo.batida()
	_trocar_trecho(b)               # a estação nova: as peças, a coleta, a TV, a linha `estacao`
	_distribuir(b)                  # uma batida antes de cada batida: quem toca, com que verbo; nova_nota
	_pistas(b)                      # o empurrão do balanço (todos) e a garra (só o dono), na hora
	for l in presentes():
		if not conectado(l):
			_nota[l] = -1
			continue
		_entrada(l)                 # o gesto do verbo da nota aberta; julgar_toque ou nota_perdida
		_prazo(l)                   # a nota que passou
	if b >= _fim_batida:
		coop_venceu = not _caiu
		for l in presentes():
			acabou[l] = true
	_mostrar(b)


func toque(l: int, j: int) -> void:
	marcar(l, PONTOS[j] * (2 if Ritmo.batida() >= FIM - 1.5 else 1))
	if j == Ritmo.PERFEITO:
		_integridade = minf(100.0, _integridade + _custo_erro / 4.0)
	_gesto_do_verbo(l)


func falha(l: int) -> void:
	_erros[l] += 1
	jogador(l).gesto("emote-no", 0.3)
	_integridade -= _custo_erro
	_derrubar_lajes()               # as que passaram do limite; o golpe em todos
	if _integridade <= 0.0 and not _caiu:
		_caiu = true
		_fim_batida = ceilf(Ritmo.batida() / 4.0) * 4.0 + 4.0   # um compasso depois
		_a_plataforma_cai()


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b): return _erros[a] < _erros[b] or (_erros[a] == _erros[b] and pontos[a] > pontos[b]))
	return lista
```

`_distribuir(b)`: para a batida `x = floor(b) + 1` (uma vez cada, `_feita`):
acha o trecho; nas estações, o dono é `presentes()[(x - de) % np]` (se
conectado; e, com `Ritmo.simples[l]`, uma nota dele sim, uma não), o verbo o
da estação; no rugido do meio, todos, com
`[BATER, EQUILIBRAR, TRACAR, DEFENDER][(x - 100) % 4]`; no final, o dono pelo
hoqueto e o verbo `[BATER, EQUILIBRAR, TRACAR, DEFENDER][int((x - 204) / 4) % 4]`,
e a batida 235 é de todos (bater). Para cada lugar que toca: `_nota[l] = _n[l]`,
`_n[l] += 1`, `_verbo[l]`, `_alvo[l] = t(x)`, `nova_nota`; no traçar,
`_seta_da_nota[l]` pelo `rng` e a runa acende; no defender, `_lado_garra[l]`
pelo `rng` e a pista **agora** (uma batida antes):
`Forja.sentir(l, "golpe_esq" if lado == 0 else "golpe_dir", 150)` e a linha
`pista` (`via` `rumble`, `o_que` `esquerda`/`direita`). `_pistas(b)`: no
equilibrar, a cada compasso (`x % 4 == 0`), `_lado_balanco` pelo `rng` e o
empurrão em todos. `_entrada(l)`: pelo verbo — `BATER`: `Forja.apertou(l, Forja.CRUZ)`;
`EQUILIBRAR`: a rolagem (ou o que a substitui) cruzou o limite (certo →
`julgar_toque`, errado → `nota_perdida`); `TRACAR`: o dedo apoiado andou
`TRACO` desde `_dedo_de[l]` (guardado no toque do dedo); `DEFENDER`: L1/R1.
`_contar_notas()`: percorre o roteiro com os `presentes()` de agora e conta.
A linha de cada estação, no `_trocar_trecho`:
`Forja.evento("estacao", 0, {"slot": id, "estacao": NOME_ESTACAO[verbo], "batida": de})`
(`"rugido"` e `"final"` nos outros dois).

Dica (com `na_raia(l)`): o ícone do verbo da nota aberta — `["@cross"]`,
`["@giroscopio"]` (o glifo de `godot/assets/glifos/giroscopio.png`),
`["@touchpad"]`, `["@l1", "@r1"]` — **sempre** (é um
medley: cada estação ensina de novo em meio segundo). `progresso()`: o nome
da estação — `"Bata!"`, `"Incline!"`, `"Trace!"`, `"Defenda!"`,
`"Aguentem!"`. `status(l)`: `"%d erros" % _erros[l]`.

Catálogo: `"S09_J44"` em `MINIGAMES` e na seção `S09`. Traduções:
`"Ruge o Reator": "The Reactor Roars"`, `"Aguentem!": "Hold on!"`,
`"Incline!": "Tilt!"`, `"Trace!": "Swipe!"`, `"Defenda!": "Defend!"`,
`"%d erros": "%d misses"` (e `"Bata!"`, que veio da H04).

## O que o registro mede

- `estacao` a cada troca: a noite separa o desvio de cada recurso (botão,
  giroscópio, touchpad, vibração) por controle, **no fim da noite**, e
  compara com o desvio das seções de origem no começo — o cansaço por
  recurso;
- `nota`/`toque` de cada estação; `pista` da garra (o lado, só no dono) e
  `respondeu`;
- `troca` de quem não tem giroscópio.

**A linha nova no 13.** Se a tabela "Os tipos, e quem os escreve" do 13
ainda não tem `estacao`, acrescente, no mesmo commit:

```markdown
| `estacao` | `slot`, `estacao` (`bater`, `equilibrar`, `tracar`, `defender`, `rugido`, `final`, e as do Q5), `batida` | os medleys (Q4, Q5), a cada troca de estação |
```

E, na linha `troca` (da O1), acrescente `giroscopio` a `recurso`,
`analogico` a `para` e `sem_giroscopio` a `motivo`.

## Armadilhas

- **Uma estação, um gesto.** Não aceite ✕ na estação 2 nem L1 na 3: cada
  nota só olha a entrada do verbo dela (um aperto de outra coisa não é erro
  nem acerto).
- **O giroscópio do robô** é o simulado: `robo_girar` muda a velocidade, e a
  `postura` integra. Espere a rolagem voltar ao meio entre as notas
  (`_robo_voltar`), senão a nota seguinte já nasce cruzada.
- **O traço mede do ponto em que o dedo tocou**, não do centro: guarde
  `_dedo_de[l]` quando `dedo.z` passa a 1.
- **Rumble e háptica nunca juntos:** o empurrão do balanço e a garra são
  rumble; o acerto do kit é háptica (no cabo) na batida da nota. A garra sai
  uma batida antes (0,5 s): não encosta. O empurrão do balanço sai na batida
  0 do compasso — que é a nota do P1: **no controle de quem toca naquela
  batida**, pule o empurrão (ele já vê a plataforma virar).
- **A prova fica mais longa** (118 s de relógio): a checagem do medley roda
  só na rodada sem a bancada (ver "Provas").
- **`ENTRADA`**: se o kit tiver `BATIDA_DA_PRIMEIRA_NOTA`, use-a.

## Pronto quando

Joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três
temperamentos (o ruim derruba a plataforma; o bom a segura); aguenta o cabo
que cai e volta; passa pelas quatro estações, o rugido e o final sem pausa na
música; fecha com o resultado coop e o destaque; a prova do jogo passa; e
`bash tests/prova_visual.sh` passa com a prancha olhada (as estações
trocando, as lajes caindo, o dragão).

## Provas

Em `godot/testes/prova_do_jogo.gd`, uma `_prova_ruge_o_reator()`, chamada
**só na rodada sem a bancada** (`if not Forja.bancada:`):

```gdscript
## S09_J44: as quatro estações passam na ordem (a linha estacao), o robô joga
## cada uma pelo controle simulado (toques julgados em todas), e o medley fecha
## coop.
func _prova_ruge_o_reator() -> void:
	var sala = await _comeca_a_sala("S09_J44")
	if sala == null:
		return
	var verbos_julgados := {}
	var inicio := Time.get_ticks_usec()
	var antes := [0, 0, 0, 0]
	while is_instance_valid(sala) and sala.fase == "jogo" and Time.get_ticks_usec() - inicio < 150000000:
		for l in 4:
			if sala.pontos[l] != antes[l]:
				antes[l] = sala.pontos[l]
				verbos_julgados[sala._verbo[l]] = true
		await _quadros(1)
	_esperar(is_instance_valid(sala) and sala.fase == "fim", "reator: fechou (%.0f s)" % ((Time.get_ticks_usec() - inicio) / 1e6))
	_esperar(verbos_julgados.size() == 4, "reator: acertos nas quatro estações (%s)" % [verbos_julgados.keys()])
	if is_instance_valid(sala):
		_esperar(sala.coop, "reator: o resultado é coop")
```

No `_prova_do_relatorio()`: as linhas `estacao` do `S09_J44` são seis, na
ordem do roteiro.

`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**Com o André (local):** `./run-local.sh -- --sala=S09_J44`, com quatro, no
fim de uma noite. A troca de estação tem de ser entendida em meio segundo (o
ícone e o verbo); o rugido do meio tem de ser caótico e divertido; a
plataforma caindo tem de dar vontade de "mais uma".

## Ao terminar

- No [quadro](README.md), a linha Q4: **feito**, com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: Ruge o Reator — o medley da primeira metade, a plataforma de todos`
