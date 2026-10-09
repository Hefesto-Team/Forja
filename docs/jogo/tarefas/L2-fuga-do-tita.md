# L2 — Fuga do Titã

**Sprint:** L · **Slot:** S04_J17 · **Tamanho:** M · **Depende de:** H04, H08, F09, L1, G14, G15

## Por quê

O coop da seção: um vagão, um titã que rasteja atrás e uma caldeira que só anda se cada um põe carvão na sua
vez, e a vez de cada um **só a mão sabe** (o passo do titã chega no controle do próximo, uma batida antes).

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (a FICHA, os ganchos, o que o kit dá pronto)
- [`cenario_do_impacto.gd`](../../../godot/scripts/minigames/s04/cenario_do_impacto.gd) (o cenário comum que a L1 criou)
- [`o_cerco.gd`](../../../godot/scripts/minigames/s04/o_cerco.gd) (o modelo: o hoqueto, a pista, o robô, o `momento`)

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão, o RPG) está copiado nesta ficha, com os números.
Onde o índice da seção (`L-o-impacto.md`) dá uma cor em hex ou outra câmera, vale o `cenario_do_impacto.gd`.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s04/fuga_do_tita.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/catalogo.gd` | `S04_J17` em `MINIGAMES` e depois de `"S04_J16"` na seção `S04` de `SECOES` | **de todos** |
| `godot/scripts/traducoes.gd` | `"Fuga do Titã": "Escape from the Titan"`, `"Alimente!": "Feed!"`, `"Carvão": "Coal"` | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_da_fuga_do_tita()` e a chamada depois de `_prova_do_cerco()` | **de todos** |
| `godot/scripts/minigames/s04/cenario_do_impacto.gd` | **não muda**: só chama | da seção (a L1 criou) |
| `godot/scripts/minigames/minigame.gd` | **não muda**: usa `momento()` (a L1 pôs) | de todos |
| `docs/jogo/13-arquitetura.md` | **não muda**: a linha `momento` é da L1 | de todos |

O `.uid` novo (`fuga_do_tita.gd.uid`) sai de `"$GODOT" --headless --path godot --import --quit` e entra no commit.

## Como se joga

### A ficha de dados

```gdscript
extends Minigame
## Fuga do Titã (S04_J17) — os quatro num vagão, o titã rastejando atrás.
## Cada batida tem um dono; o passo do titã chega na mão do dono uma batida
## antes (só o motor forte), e ele põe carvão na caldeira apertando R2 na
## batida. Carvão no tempo afasta o titã; o titã chega mais perto a cada
## compasso. No pico a ordem dos donos se embaralha a cada compasso; na saída,
## a vez cai nas colcheias.
##
## A falha: o tranco do vagão derruba quem errou (sentado, 0,6 m para a
## frente) e arranca a grade dele. O momento: o braço do titã agarra o vagão.
## O vencedor: coop — o vagão chega aos 100 s (todos vencem) ou o titã alcança
## (todos perdem); quem pôs mais carvão no tempo leva o destaque.
## O alto-falante do dono: o julgamento do kit; sem vibração, a pista em tiques.
## O registro mede: cada passo mandado (canal, ok), a pá na vez certa, a pá
## fora da vez (o fantasma) e os momentos `quase_pego` e `reta`.
## O robô: sente o passo (só o motor forte) e aperta R2 na batida seguinte;
## quando não acerta, 250 ms tarde.
## Com menos de quatro: as batidas se dividem; sozinho, só as pares; as
## colcheias da saída só com três ou mais.
## A régua: (1) "Alimente!" com a caldeira acesa e o titã atrás; (2) sim: a
## vez é só da mão; (3) não pergunta nada.

const FICHA := {
	"slot": "S04_J17",
	"titulo": "Fuga do Titã",
	"verbo": "Alimente!",
	"genero": "coop",
	"icone": "vibracao",
	"entradas": [Forja.R2],
	"camera": "fixa",
	"faixa": "MUS_S04_J17",
	"duracao": 100.0,
	"fim": "meta_coletiva",
	"sensacoes": ["aviso", "golpe_esq", "golpe", "acerto", "perfeito", "erro", "explosao"],
	"material": "madeira",
	"microjogo": {"verbo": "Alimente!", "segundos": 6.0},
}

const PONTOS := [0, 40, 70, 100]  ## ERRO, BOM, OTIMO, PERFEITO
## O quanto a pá afasta o titã, por julgamento (com quatro; com k, vezes 4/k).
const GANHO := [0.0, 0.008, 0.014, 0.02]
## O quanto o titã chega a cada compasso: entrada, pico, saída.
const AVANCO := [0.045, 0.065, 0.055]
## O piso da distância em cada terço: o titã só alcança na saída.
const PISO := [0.25, 0.05, 0.0]
const GRADE := 0.02  ## a falha também dá ao titã este tanto
const DISTANCIA_INICIAL := 0.6
const PERTO := 0.35  ## abaixo disto, o passo é o golpe_esq e o R2 pesa (2, 6)
const PERIGO := 0.25  ## abaixo disto, a barra de luz pulsa na batida
## O braço: agarra quando a distância fica abaixo de 0,2 no começo de um
## compasso; segura 1 compasso; a primeira pá certa depois o empurra (+0,08).
const BRACO_ABAIXO := 0.2
const BRACO_SEGURA_BATIDAS := 4.0
const BRACO_EMPURRA := 0.08
const RUGIDO_DISTANCIA := 0.19  ## no começo do pico, o titã dá o bote até aqui
const BATIDAS_DA_RETA := 16  ## na reta, a pá vale o dobro e o titã avança o dobro
const PONTE_S := 90.0  ## a ponte sobe (em segundos de música)
const R2_APERTA := 0.6
const R2_SOLTA := 0.3
const Z_TITA := Vector2(-6.0, -2.1)  ## o z do titã longe (distância 1) e encostado (0)
const P_MAO := Vector3(0.0, 0.9, 0.6)  ## onde a mão do titã agarra o estrado
const BRACO_M := 5.4  ## 3 vezes o cavaleiro (1,8 m): o degrau catástrofe pede 1,5 ou mais
const TRANCO_M := 0.6  ## a falha: o cavaleiro escorrega para a frente (+z)
const EMPURRAO_MIN_M := 0.5
const QUEDA_TEMPOS := 2.0  ## minigames.csv: 2
```

### O dono da vez

O compasso `c` tem as batidas `4c` a `4c+3`; o compasso 0 é a contagem de entrada (a primeira vez é a batida 4).
`lista` são os presentes com `conectado(l)`, em ordem crescente; `k = lista.size()`. A 145 BPM, a batida dura
0,414 s e o compasso 1,655 s; `B_FIM = floor(100 * 145 / 60) = 241`; a reta começa em `B_FIM - 16 = 225` (93,1 s).

| terço | música (`andamento()` do kit) | a vez | com poucos |
| --- | --- | --- | --- |
| 1. entrada | 0–33 s | batida `b` → `lista[b % k]`, sempre na mesma ordem | sozinho, só as pares |
| 2. **o pico** | 33–67 s (`no_pico()`) | a `ordem` do compasso é `lista` embaralhada pelo `rng` (Fisher-Yates com `rng.randi_range`, nunca `Array.shuffle`); batida `4c + i` → `ordem[i % k]`; se `ordem[0]` for o dono da batida `4c − 1`, gire a `ordem` uma casa | sozinho, só as pares, sem embaralhar |
| 3. saída | 67–100 s | com `k >= 3`: as oito colcheias `4c + i * 0.5` → `ordem[i % k]` (embaralhada, com a mesma regra da virada); com `k <= 2`: como no pico | — |

- **O mesmo lugar nunca tem duas vezes a menos de uma batida** (na saída, com três ou mais, a menor distância é
  1,5 batida): a pista de uma vez não cai na sensação do kit da vez anterior do mesmo controle.
- Quem está errando (`Ritmo.simples[l]`) perde as vezes das colcheias ímpares (`i` ímpar) da saída; elas ficam
  sem dono.
- Ninguém fica mais de 8 batidas sem vez: com `k <= 4`, cada um tem uma vez a cada `k` batidas, no máximo 4.
- **A nota:** `{"n": int(round(b * 2)), "b": b, "t": Ritmo.t_da_batida(b), "avisada": false, "peso": 0.5 se o compasso é de colcheias, senão 1.0}`,
  com `nova_nota(l, n, t)`. O compasso é gerado quando `Ritmo.batida() >= 4c − 4`, e cada vez vai para `_todas`
  (`[lugar, b]`).

### A pista (o passo do titã)

`t_pista = maxf(Ritmo.t_da_batida(b - 1) - CenarioDoImpacto.antecedencia(l), t_da_vez_anterior_do_lugar + 0.25)`.

- `Forja.sentir(l, "aviso" if distancia > PERTO else "golpe_esq", _ms_da_pista())`, com
  `_ms_da_pista() = int(60000.0 / Ritmo.bpm * 0.4)` (0,4 batida, 165 ms: duas pistas de colcheia não se emendam).
  As duas sensações são só o motor forte (`aviso` 0,6; `golpe_esq` 1,0).
- **Sem vibração** (`sentir` devolveu `false`): `Som.no_controle(l, "tique", 0.7)` uma vez (longe) ou duas
  (perto), uma semicolcheia entre elas, e a pista vai ao registro com `canal` `alto_falante`.
- O registro: `anotar("pista", l, {"n": n, "evento": "mandou", "canal": "rumble", "o_que": "esq", "ok": ok})`.
- Nenhum sinal na tela diz de quem é a vez.

### A pá

R2 passando de `R2_APERTA` (0,6) para cima, rearmando abaixo de `R2_SOLTA` (0,3).

- Casa com a nota do lugar a até `Ritmo.JANELA_BOM` do tempo dela → ponha a nota em `_ultima[l]` e chame
  `julgar_toque(l, t, n)` (não é perigo físico: sem a folga do último).
- **Sem nota perto** (a pá fora da vez): o carvão cai no trilho
  (`Efeitos.faiscas(self, pos_da_pa, Tema.GRAFITE, 8, 0.4)`), nada de ponto nem de erro, e
  `anotar("entrada", l, {"o": "fantasma", "golpe_de": "P%d" % (dono_mais_perto + 1)})`.
- A nota que passa de `t + FOLGA_PERDIDA` (0,14 s) sem pá: `_ultima[l] = nota` e `nota_perdida(l, n)`.
- **Os pontos** (o destaque): `marcar(l, PONTOS[julgamento])` cru; o item (`Itens.pontos_do_acerto`) o kit aplica.

### A distância

0 é encostado, 1 é longe; começa em 0,6.

- A cada compasso novo (`Ritmo.batida()` passa de `4c`, `c >= 1`): `distancia -= AVANCO[terço]`, vezes 2 na reta.
- A cada pá julgada: `distancia += GANHO[julgamento] * 4.0 / k * peso`, vezes 2 na reta.
- A cada falha: `distancia -= GRADE`.
- Depois de cada mudança: `distancia = clampf(distancia, PISO[terço], 1.0)`.
- **O bote (o começo do pico):** no primeiro compasso `c` com `Ritmo.t_da_batida(4c) >= 33.0` (a 145 BPM, o
  compasso 20, aos 33,1 s), `distancia = minf(distancia, RUGIDO_DISTANCIA)`: o titã dá o bote e o braço agarra.
  O primeiro momento é garantido, com qualquer mesa.
- **Chegou a 0** (só na saída, pelo piso): o titã alcança (abaixo).

### O braço (o momento)

No começo de cada compasso, depois do avanço: se o braço está recolhido e `distancia < BRACO_ABAIXO`, o braço
agarra.

- `_braco_desde = Ritmo.batida()`; o ombro gira de recolhido a esticado em 1 colcheia (curva `ENTRA`) e a mão
  bate em `P_MAO`;
- as notas do mesmo compasso com `b` entre `4c` (exclusive) e `4c + 1.5` somem sem erro (tire de `_notas`, sem
  `nota_perdida`): a sensação do momento não pode cair numa pista;
- `CenarioDoImpacto.exagero(self, _cenario, "catastrofe")` (tremor 0,08 m por 4 batidas, sem hit-stop, a chave
  +40 % por 1 batida);
- `Forja.sentir(l, "explosao", 250)` em todos os presentes com controle;
- `Som.tocar("golpe", P_MAO, 0.0)` e `Som.tocar("pedra", P_MAO, -4.0)`;
- quatro marcas de dedo no estrado (o rastro, até o fim): caixas `0.12 × 0.02 × 0.6` em
  `P_MAO + Vector3(-0.45 + 0.3 * i, -0.39, 0)`, `i` de 0 a 3, em `Kit.material(Tema.JANELA, 0.0, 1.0)` (as do
  segundo braço em z +0,25, as do terceiro em +0,5, e assim por diante, até 6 grupos);
- `momento("quase_pego", -1, P_MAO, 1.5, {"distancia": snappedf(distancia, 0.01), "vez": _bracos})`.

O braço segura o vagão por `BRACO_SEGURA_BATIDAS` (4, um compasso). Depois disso, a primeira pá julgada BOM ou
melhor o empurra: `distancia += BRACO_EMPURRA`, o ombro volta a recolhido em 2 batidas (curva `MOLA`) e
`Som.tocar("martelo", P_MAO, -2.0)`. Enquanto segura, as pás contam normalmente.

### A reta

Na batida `B_FIM - 16`: `momento("reta", -1, Vector3(0, 1.0, Z_JOGADOR + 0.2), 1.6, {"objeto": "caldeira", "valores": "%.2f" % distancia})`.
Daí ao fim, o titã avança o dobro e a pá vale o dobro: o fogo da caldeira é o placar de todos.

### O titã alcança

Distância 0 (só na saída): o braço agarra pelo meio, as quatro grades voam, `explosao` (400 ms) em todos,
`CenarioDoImpacto.exagero(self, _cenario, "catastrofe")`, todos `gesto("fall", 1.2)`; `coop_venceu = false` e
`acabou[l] = true` de cada presente: o kit fecha com `jin_derrota`.

### A ponte

Aos `PONTE_S` (90 s): cinco `Kit.peca(self, "wood-structure", Vector3(-8 + 4 * k, -2.0, Z_JOGADOR + 4.0), 0.0, 2.0)`
sobem até y = 0 em 2 batidas (curva `SAI`). Aos 100 s o kit fecha com `coop_venceu = distancia > 0.0`
(`jin_coop_vitoria`).

### O fim e o destaque

`fim` `meta_coletiva`: aos 100 s de música o kit fecha (H08). `coop_venceu` é posto a cada quadro. O registro
grava `vencedor` −1 (coop); o destaque é quem pôs mais pontos:

```gdscript
## Coop: o kit grava vencedor −1 (H08); o destaque é quem pôs mais carvão no tempo.
func destaque() -> int:
	var lista := presentes()
	lista.sort_custom(func(a, b): return int(pontos[a]) > int(pontos[b]) or (int(pontos[a]) == int(pontos[b]) and a < b))
	return int(lista[0]) if not lista.is_empty() else -1
```

### Com menos de quatro

- **Três:** a roda gira; na saída, as colcheias valem (1,5 batida entre as vezes do mesmo).
- **Dois:** um as pares, outro as ímpares; na saída, sem colcheias. O ganho da pá dobra (`4/k`).
- **Um:** só as batidas pares, sem embaralhar; o ganho é quatro vezes. O titã é o mesmo.
  `com_poucos()` devolve `"Só você no vagão"` com um jogador e `""` com mais.
- **O controle que cai:** as vezes dele somem sem erro enquanto está fora, e o compasso seguinte é gerado sem
  ele; quando volta, entra na roda do compasso seguinte.

### Os ganchos

```gdscript
var _notas := [[], [], [], []]
var _ultima := [{}, {}, {}, {}]  ## a nota em resolução (toque e falha a leem)
var _gerado := 1
var _fora := [false, false, false, false]
var _armado := [true, true, true, true]  ## o R2 voltou abaixo de R2_SOLTA
var _dono_da_ultima := -1  ## o dono da última vez gerada (a regra da virada)
var _todas: Array = []  ## [lugar, b] de toda vez gerada (a prova confere as distâncias)
var _compasso_do_tita := 0
var _rugiu := false
var _braco_desde := -1.0  ## a batida em que o braço agarrou (-1: recolhido)
var _bracos := 0
var _reta := false
var distancia := DISTANCIA_INICIAL
var _gatilho_forte := [false, false, false, false]
var _caido_ate := [-1.0, -1.0, -1.0, -1.0]  ## o t_musica em que quem caiu volta à pá
var _cenario := {}


func montar() -> void:
	var pose := CenarioDoImpacto.pose_da_camera()
	camera_pos = pose[0]
	camera_olhar = pose[1]
	_cenario = CenarioDoImpacto.montar(self)
	_montar_o_vagao()  # estrado, rodas, caldeira, carvão, grades, dormentes (A cena)
	_montar_o_tita()
	for p in jogadores:
		var l: int = p.lugar
		raia(l).position.y = 0.5
		posicionar(l)
		p.position.y = 0.55
		p.rotation.y = 0.0  # de frente para a câmera; o titã atrás
		p.preso = true
		Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, 4)


func iniciar_jogo() -> void:
	distancia = DISTANCIA_INICIAL
	coop_venceu = true
	for l in presentes():
		CenarioDoImpacto.luz_com_brilho(l, 1.0)


func jogar(dt: float) -> void:
	while _gerado <= int(floor(Ritmo.batida() / 4.0)) + 1:
		_gerar_compasso(_gerado)
		_gerado += 1
	CenarioDoImpacto.passar(self, _cenario, no_pico())
	var c := int(floor(Ritmo.batida() / 4.0))
	if c > _compasso_do_tita and c >= 1:
		_compasso_do_tita = c
		_avancar(c)  # o avanço, o bote, o braço que agarra (A distância, O braço)
	_reta_no_tempo()
	var agora := Ritmo.t_musica()
	for l in presentes():
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_notas[l] = _notas[l].filter(func(nt): return float(nt.t) > agora)
		for nt in _notas[l]:
			if not nt.avisada and agora >= _t_pista(l, nt):
				_avisar(l, nt)
		var r2 := Forja.eixo(l, Forja.R2)
		if _armado[l] and r2 >= R2_APERTA:
			_armado[l] = false
			_pa(l)
		elif r2 <= R2_SOLTA:
			_armado[l] = true
		while not _notas[l].is_empty() and agora > float(_notas[l][0].t) + FOLGA_PERDIDA:
			_ultima[l] = _notas[l].pop_front()
			nota_perdida(l, int(_ultima[l].n))
		_levantar(l)
		_gatilho_do_medo(l)
		_luz_do_perigo(l)
	coop_venceu = distancia > 0.0
	if distancia <= 0.0:
		_o_tita_alcancou()
	_mover_o_mundo()  # dormentes, titã (z e passo), braço, fogo, ponte


func toque(l: int, julgamento: int) -> void:
	marcar(l, PONTOS[julgamento])
	var k := float(maxi(presentes().size(), 1))
	var vale := 2.0 if _reta else 1.0
	_mudar(GANHO[julgamento] * 4.0 / k * float(_ultima[l].peso) * vale)
	jogador(l).gesto("attack-melee-right", 0.30 / CenarioDoImpacto.gancho(l, "velocidade"))
	Som.tocar("martelo", Vector3(0, 1.0, Z_JOGADOR + 0.2), -6.0)
	if julgamento > 0 and _braco_desde >= 0.0 and Ritmo.batida() >= _braco_desde + BRACO_SEGURA_BATIDAS:
		_empurrar_o_braco()


func falha(l: int) -> void:
	_mudar(-GRADE)
	Forja.sentir(l, "golpe")
	Som.tocar("golpe", jogador(l).global_position + Vector3(0, 1.0, 0), -2.0)
	CenarioDoImpacto.exagero(self, _cenario, "golpe", jogador(l))
	_tranco(l)  # O cavaleiro
	_arrancar_a_grade(l)


func _mudar(delta: float) -> void:
	distancia = clampf(distancia + delta, PISO[_terco()], 1.0)
```

- `_terco()` devolve 0, 1 ou 2 pelo `andamento()` do kit (`no_pico()` é o 1).
- `_gerar_compasso(c)` segue a tabela de «O dono da vez» e usa só os lugares com `conectado(l)`.
- `_gatilho_do_medo(l)` troca o R2 para `(2, 6)` quando `distancia < PERTO` e volta para `(2, 4)` acima, só
  quando muda (`_gatilho_forte[l]`).
- `_tranco(l)` e `_levantar(l)` estão em «O cavaleiro»; `_luz_do_perigo(l)` em «O controle».
- `dica()`: `{"partes": ["@r2", "Carvão"], "pos": Vector3(RAIAS[l], 0.0, 4.6)}` quando `na_raia(l)` e
  `not aprendeu(l)`; senão `{}`.
- `combo(l)` (G04): os perfeitos seguidos do lugar.

O catálogo: `Catalogo.MINIGAMES["S04_J17"] = preload("res://scripts/minigames/s04/fuga_do_tita.gd")`.

## A cena

### A câmera

A arena da seção: `CenarioDoImpacto.pose_da_camera()` (35 mm, plongée de 50°, a 13,5 m, olhando
`(0, 0,8, −1,0)`), modo `fixa`, **sem corte** do apito ao apito, roll zero. O quadro cobre o chão de z = 3,4
(embaixo) a z = −10,8 (em cima): a frente do vagão (z 2,7) e o titã inteiro cabem. Em z = −6,2 (a cabeça do titã
mais longe), o quadro vê até y = 2,76; por isso o titã **rasteja**: nada dele passa de y = 2,4.

- **O pico:** `CenarioDoImpacto.passar` recua a câmera 10 % e sobe a chave 20 % em 1 batida.
- **O tremor é do evento:** só o de `CenarioDoImpacto.exagero`.

### A luz

A da seção (mostarda, lado A), posta pelo `CenarioDoImpacto.montar(self)`: a névoa `#170e00` (o main), o
preenchimento `#493400` e a chave `#f8d096`. O fogo da caldeira é uma `OmniLight3D` `Tema.TUNGSTENIO` em
`(0, 1.0, Z_JOGADOR + 0.9)`, energia `0.6 + 1.2 * distancia` (0,6 encostado, 1,8 longe), alcance 5: quanto mais
longe o titã, mais forte o fogo. É o placar de todos, no mundo.

### As peças e o papel de cada uma

| peça ou forma | onde | papel | material |
| --- | --- | --- | --- |
| o estrado: `Kit.caixa(15.0 × 0.3 × 2.6)` | `(0, 0.35, Z_JOGADOR)` | o vagão | `Kit.material(Tema.OXIDO_BRILHO, 0.0, 0.85)` |
| seis rodas: `Kit.cilindro(raio 0.4, altura 0.2)`, `rotation.x = PI * 0.5` | x = −6, 0, 6; z = `Z_JOGADOR ± 1.35`; y 0,4 | as rodas | `Kit.material(Tema.GRAFITE, 0.0, 0.6)` |
| `wood-support` (escala 1,0) | os quatro cantos do estrado | os cantos | a peça |
| as grades: `Kit.caixa(1.8 × 0.5 × 0.08)` e duas estacas `0.1 × 0.6 × 0.1` | `(RAIAS[l], 0.95, Z_JOGADOR + 1.25)` | a proteção de cada lugar (a falha a arranca) | `Kit.material(Tema.OXIDO_BRILHO, 0.0, 0.85)` |
| `rocks` (escala 0,8) | `(RAIAS[l] + 0.8, 0.5, Z_JOGADOR - 0.6)` | o carvão de cada lugar | a peça |
| `barrel` (escala 1,6) | `(0, 0.5, Z_JOGADOR + 0.2)` | a caldeira | a peça |
| a chaminé: `Kit.caixa(0.35 × 1.4 × 0.35)` | `(0, 1.9, Z_JOGADOR + 0.2)` | a chaminé | `Kit.material(Tema.GRAFITE, 0.0, 0.6)` |
| dez dormentes: `Kit.caixa(16.0 × 0.06 × 0.3)` | `z = -8.0 + fposmod(k * 1.6 + Ritmo.batida() * 0.8, 16.0)` a cada quadro | o chão que corre (pela batida, nunca somando `dt`) | `Kit.material(Tema.OXIDO, 0.0, 0.95)` |
| `wood-structure` (escala 2,0) | cinco, aos 90 s (A ponte) | a ponte | a peça |

**O titã** (um `Node3D` `tita`, rastejando; `tita.position.z = lerpf(Z_TITA.y, Z_TITA.x, distancia)` a cada
quadro, e o passo: `tita.position.y = 0.15 * absf(sin(PI * Ritmo.batida()))`, ele bate as mãos em toda batida):

| parte | forma | posição (no `tita`) | material |
| --- | --- | --- | --- |
| o tronco | `Kit.caixa(4.0 × 1.6 × 3.0)` | `(0, 1.0, -1.0)` | `Kit.material(Tema.GRAFITE, 0.0, 0.9)` |
| a cabeça | `Kit.caixa(3.0 × 1.8 × 2.4)` | `(0, 1.5, 1.0)` (de y 0,6 a 2,4) | o mesmo |
| os dois punhos no chão | `Kit.peca(tita, "rocks", ..., 0.0, 2.0)` | `(±1.8, 0, 1.6)` | a peça |
| os dois olhos | `Kit.caixa(0.5 × 0.3 × 0.1)` | `(±0.7, 1.8, 2.21)` | `Tema.neon(Tema.VIOLETA, 1.2, "mundo")` |
| o ombro (pivô) | `Node3D` | `(1.9, 2.2, -1.5)` | — |
| o braço | `Kit.caixa(0.7 × 0.7 × BRACO_M)` no ombro, em `(0, 0, BRACO_M / 2)` | — | `Kit.material(Tema.GRAFITE, 0.0, 0.9)` |
| a mão | `Kit.caixa(1.2 × 1.5 × 1.0)` no ombro, em `(0, -0.3, BRACO_M + 0.2)` | — | o mesmo |

O braço recolhido: `ombro.rotation = Vector3(-1.3, 0, 0)` (para cima e para trás). Esticado: a cada quadro,
`ombro.look_at(P_MAO, Vector3.UP, true)` e `ombro.scale.z = ombro.global_position.distance_to(P_MAO) / (BRACO_M + 0.7)`;
a mão pousa em `P_MAO` mesmo com o titã se mexendo. Com a distância de 0,19, o ombro fica a 5,5 m da mão: o braço
aparece com o seu tamanho.

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08) |
| a borda da raia (`acender_raia`) | o lugar | o kit: 2,0, e 2,6 no acerto por 4 quadros |
| os olhos do titã | o mundo | 1,2 (o teto), `Tema.VIOLETA` |
| o fogo da caldeira | a forja | luz `Tema.TUNGSTENIO`, 0,6 a 1,8 |
| as faíscas da pá certa | o lugar | `Efeitos.faiscas(self, boca_da_caldeira, Forja.cor_do_lugar(l), 12, 0.6)`, 2,4 por 12 quadros |
| o carvão no trilho | ninguém | `Tema.GRAFITE`, 8 partículas, sem brilho |

Nenhum hex fora dos tokens: os `#6b4526`, `#3a3a44`, `#3a2a24`, `#5e5870` e `#ff7a2a` de antes somem, e o
`CenarioDoImpacto.OLHO` de antes não existe. Nada é metálico (`metallic` 0) e nada passa de 300 partículas.

## O som

Os ids do [mapa do áudio](../audio/mapa.csv). Todos existem; nenhum som novo.

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| a pá julgada | `Som.tocar("martelo", Vector3(0, 1.0, Z_JOGADOR + 0.2), -6.0)`, na caldeira | o julgamento do kit (`jul_*`) | `martelo_*` |
| a pista | — (a TV não diz de quem é a vez) | — (sem vibração: `tique` 1× ou 2×) | `tique_*` |
| a falha (o tranco) | `Som.tocar("golpe", pos_do_boneco, -2.0)` | `jul_erro_p{n}` (o kit) | `golpe_*` |
| o braço agarra | `Som.tocar("golpe", P_MAO, 0.0)` e `Som.tocar("pedra", P_MAO, -4.0)` | — | `golpe_*`, `pedra_*` |
| o braço é empurrado | `Som.tocar("martelo", P_MAO, -2.0)` | — | `martelo_*` |
| o titã alcança | `Som.tocar("golpe", P_MAO, 0.0)`, depois `jin_derrota` (o kit) | — | `golpe_*`, `jin_derrota` |
| o vagão chega | `jin_coop_vitoria` (o kit) | — | `jin_coop_vitoria` |
| a faixa | `MUS_S04_J17`: 145 BPM, Mi menor, 150 s; até existir, a reserva `sint_trilha` da H05 | — | `mus_s04_j17` |

- **Nenhum `"falha"`** (é um bipe de erro, que a bíblia proíbe) e nenhum `"clique"` no alto-falante: o
  alto-falante do dono é do julgamento do kit, um som por vez. A troca da falha na TV por `fx_tropeco_*` é da H11.
- O material `"madeira"` da FICHA: o kit toca `mod_material_madeira` nos atuadores no acerto.
- A mixagem (o Ambiente −6 dB, +3 dB no último terço) é da H11.

## O controle

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| a pista, longe | só o dono da vez | `aviso` (0,6 / 0) por 165 ms | — | — | sem vibração: `tique` 1× |
| a pista, perto (`distancia < 0.35`) | só o dono | `golpe_esq` (1,0 / 0) por 165 ms | R2 vai a Resistência (2, 6) | — | sem vibração: `tique` 2× |
| a pá julgada | o dono | `acerto`, `perfeito` ou `erro` (o kit) | — | o kit: branco 0,15 s no perfeito; a cor escurecida 0,5 s no erro | `jul_*` (o kit) |
| a falha (o tranco) | o dono | `golpe` (1,0 / 0,6, 250 ms) | — (o R2 já é a pá) | — | `jul_erro_p{n}` (o kit) |
| o braço agarra | todos com controle | `explosao` com 250 ms (1,0 / 1,0) | — | — | — |
| o titã alcança | todos | `explosao` (400 ms) | `gatilhos_off` (o kit, no fim) | — | — |
| o perigo (`distancia < 0.25`) | todos | — | — | `luz_com_brilho(l, 1.0 if fposmod(Ritmo.batida(), 1.0) < 0.5 else 0.6)`: pulsa 2,4 vezes por s; com `Opcoes.flashes` desligado, fica em 0,7 | — |
| começar | todos | — | R2 em Resistência (2, 4): o peso da pá; o L2 é do item (G03) | a cor do lugar, 100 % | — |

- `_luz_do_perigo(l)` manda o brilho só quando o valor muda. Fora do perigo, a cor do lugar a 100 %.
- As luzinhas de jogador mostram o número, sempre. O microfone não se usa.
- **Os outros não sentem nada** da pista de um: a pá fora da vez é a vibração que vazou ou quem contou.

### O robô

```gdscript
# O robô sente o passo do titã no controle simulado: só o motor forte ligado.
# A vez é a batida (ou a colcheia) seguinte à pista; ele aperta R2 nela, pelo
# relógio da música. O explosao (1,0/1,0) e as sensações do kit ligam os dois
# motores e não enganam o robô.
var _robo_ligado := [false, false, false, false]
var _robo_alvo := [-1.0, -1.0, -1.0, -1.0]
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var pc := Forja.percepcao(l)
	if pc.is_empty():
		return
	var pista := float(pc.get("forte", 0.0)) > 0.3 and float(pc.get("fraco", 0.0)) < 0.05
	if pista and not _robo_ligado[l] and _robo_alvo[l] < 0.0:
		var adiante := CenarioDoImpacto.antecedencia(l) * Ritmo.bpm / 60.0
		_robo_alvo[l] = snappedf(Ritmo.batida() + adiante, 0.5) + 1.0
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 250 ms tarde
		_robo_atraso[l] = 0.0 if Forja.robo_acerta() else 0.25
	_robo_ligado[l] = pista
	if _robo_alvo[l] >= 0.0 and Ritmo.t_musica() >= Ritmo.t_da_batida(_robo_alvo[l]) + float(_robo_atraso[l]):
		Forja.robo_eixo(l, Forja.R2, 1.0, 0.08)
		_robo_alvo[l] = -1.0
```

O robô não lê a partitura: se o passo não chegou ao controle simulado, ele não põe carvão. A mesma conta roda no
controle simulado da prova do jogo e no da prova visual.

## O cavaleiro

O cavaleiro é o da montagem (G13): a cabeça, a parte de cima e a de baixo que a pessoa escolheu aparecem como
estão, de frente para a câmera, no vagão. `posicionar(l)` deixa as mãos livres: a arma ou o amuleto não aparece
(a pá é o gesto `attack-melee-right`), mas o efeito do item vale. O cavaleiro pode ser de outra raça (G13, o ajuste
dela de 09/10): esta ficha não supõe corpo humano; usa só o esqueleto comum de 7 ossos e as animações
`attack-melee-right`, `fall` e `idle`.

| stat | gancho | o que muda na Fuga | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | o quanto o tranco do vagão o faz escorregar | 0,70 m | 0,60 m | 0,50 m (o piso) |
| Passo | `velocidade` | a pressa da pá na tela (o gesto dura `0.30 / velocidade` s); nada no julgamento | 0,32 s | 0,30 s | 0,28 s |
| Fôlego | `levantar` | quanto tempo fica sentado depois do tranco (as vezes desse tempo somem sem erro) | 2,5 tempos | 2 tempos | 1,5 tempo |
| Faro | `pista` | o passo do titã chega antes; a vez cai no mesmo tempo | −40 ms | 0 | +40 ms |

Os itens: o Escudo absorve o primeiro erro (o kit); a Âncora divide o tranco por 2 (até o piso de 0,5 m); a
Lanterna adianta a pista meio tempo (`Itens.antecipacao_s`, dentro do `antecedencia`); o Martelo dobra o perfeito
no tempo forte (o kit). Nenhum stat muda a janela, os pontos, a falha física (o piso de 0,5 m) ou o braço.

```gdscript
## O tranco: o cavaleiro escorrega para a frente (+z) em 1 colcheia (`QUICA`),
## cai sentado (`fall`, quique de 0,30 m e depois 0,10 m) e fica a queda do
## Fôlego; as vezes dele nesse tempo somem sem erro.
func _tranco(l: int) -> void:
	var p := jogador(l)
	var m := maxf(EMPURRAO_MIN_M, TRANCO_M * CenarioDoImpacto.gancho(l, "empurrao") * Itens.resiste_a_empurrao(l))
	var colcheia := 30.0 / Ritmo.bpm
	p.create_tween().tween_property(p, "position:z", Z_JOGADOR + m, colcheia) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	p.gesto("fall", colcheia * 2.0)
	_caido_ate[l] = Ritmo.t_musica() + CenarioDoImpacto.queda_s(l, QUEDA_TEMPOS)
	_notas[l] = _notas[l].filter(func(nt): return float(nt.t) > _caido_ate[l])


## Passada a queda, o cavaleiro volta à pá em 1 batida (`MOLA`).
func _levantar(l: int) -> void:
	if _caido_ate[l] >= 0.0 and Ritmo.t_musica() >= _caido_ate[l]:
		_caido_ate[l] = -1.0
		var p := jogador(l)
		p.create_tween().tween_property(p, "position:z", Z_JOGADOR, 60.0 / Ritmo.bpm) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
```

O erro não tem squash; o desregistro do erro (o contorno de 2,4 a 0,6, a animação a 0,5×) é do kit e da G08. A
grade arrancada voa para `+ Vector3(0, 2.5, -3.0)` com escala 0,01 em 0,4 s e volta 2 compassos depois (0,3 s).

## As reações

- **Carimbos que a Fuga pode disparar** (do kit e do HUD, G04; a Fuga não chama nenhum): `car_em_chamas` (5
  Ressonâncias seguidas do mesmo lugar). O `car_acorde` (os quatro na Ressonância no mesmo tempo 1) não acontece:
  cada batida tem um dono. O `car_por_um_fio` não se aplica ao coop.
- **Adesivos:** ninguém está fora da rodada (quem cai volta em até 2,5 tempos), então ninguém manda adesivo
  durante o jogo.
- Nenhum carimbo próprio de minigame.

## A diversão

**O momento: o braço do titã** (`quase_pego`). A distância cai abaixo de 0,2 e a mão de 5,4 m (3 vezes o
cavaleiro) bate no vagão entre os quatro. O vagão treme 0,08 m por 4 batidas, a luz sobe 40 % por 1 batida e os
quatro controles explodem juntos. A mão segura 1 compasso; a primeira pá certa depois disso a empurra de volta.
É de todos: a luz das outras raias não cai. O primeiro é garantido: no começo do pico (33,1 s), o titã dá o bote.

- **Rastro:** as quatro marcas de dedo no estrado ficam até o fim (mais um grupo a cada braço); a grade arrancada
  de quem errou fica fora por 2 compassos.
- **A curva:** de 0 a 33 s, a roda em ordem (o titã não chega abaixo de 0,25); de 33 a 67 s, o pico (a ordem
  embaralhada, o bote, o braço); de 67 s ao fim, as colcheias (o titã pode alcançar). Na reta (últimas 16
  batidas, de 93,1 s), a pá vale o dobro e o titã avança o dobro: o mesmo jogo, com o dobro em jogo.
- **Ensina sem falar:** na entrada a vez anda em roda e a mão confirma; na terceira volta, o grupo já sabe que a
  vez é da mão.
- **Quem está perdendo:** o piso da distância segura o titã até a saída; quem cai volta em 2 tempos; quem erra
  perde as colcheias ímpares.
- **A nota de hoje:** 4.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7, pela
prova visual da F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem um `toque` com `t_musica` ≤ 10,0 | o quadro de 10 s mostra uma pá ou um cavaleiro sentado |
| 4. o momento | mesa padrão: pelo menos 1 `momento` `quase_pego` entre 33 e 100 s; mesa boa (`--robo=bom`): nenhuma derrota; mesa fraca (`--robo=ruim`): pelo menos 2 | o primeiro quadro depois do 1.º `quase_pego` mostra o braço sobre o vagão |
| 5. a curva | vezes por segundo na saída ≥ 1,5 × as da entrada (com 3 ou mais); a linha `momento` `reta` existe | o quadro do meio do pico tem a luz 20 % acima do quadro do meio da entrada |
| 6. a falha | o P4 tem pelo menos 10 `toque` com `erro` | 1 quadro em 5 mostra um cavaleiro sentado ou uma grade fora |
| 7. quem perde joga | a maior distância entre duas `nota` seguidas de cada lugar é de até 8 batidas (fora da queda) | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | cada `quase_pego` tem 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,08 | a mão se vê no quadro de 480 × 270 sem ampliar |
| 9. o impacto | para cada `quase_pego`, uma `sensacao` `explosao` a até 16,7 ms | as marcas de dedo se veem no quadro seguinte |
| 10. o placar no mundo | a energia do fogo da caldeira bate com `distancia` no `momento` `reta` | no quadro de 93 s, quem olha diz se o titã está perto pelo fogo e pela distância do titã |

Até o robô por lugar (`--robo=bom,medio,medio,ruim`, pedido ao arquiteto) existir, a prova do jogo roda com o
`--robo` dela e confere os itens 4 (o mínimo de 1, garantido pelo bote), 8 e 9; os itens 5, 6 e 7 e as mesas boa
e fraca se conferem pela prova visual com `--robo=bom` e `--robo=ruim`.

## Pronto quando

A Fuga do Titã joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos (o `ruim`
vê o braço pelo menos 2 vezes, o `bom` chega aos 100 s); aguenta o cabo que cai e volta; fecha com o resultado
coop (vitória ou derrota) e o destaque; o braço aparece no bote aos 33,1 s; a prova do jogo passa; e
`bash tests/prova_visual.sh` passa com a prancha olhada.

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh` (com `--semente=N` que sorteie o
`S04_J17` na noite, pelo `Catalogo.sortear` da H08).

Em `godot/testes/prova_do_jogo.gd`, chamada depois de `_prova_do_cerco()`:

```gdscript
## Fuga do Titã (S04_J17): a pista só no motor forte, o peso da pá no R2, a
## vez do mesmo lugar nunca a menos de uma batida, o braço e o fim coop.
func _prova_da_fuga_do_tita() -> void:
	var pesou := {}
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			if int(Forja.percepcao(l).get("gatilho_dir", 0)) == 0x21:
				pesou[l] = true
	var mg = await _joga_o_minigame("S04_J17", 140.0, olhar)
	if mg == null:
		return
	_esperar(mg.coop and mg.destaque() >= 0, "Titã: é coop, com o destaque")
	_esperar(pesou.size() == mg.presentes().size(), "Titã: a pá pesou no R2 de todos (%s)" % [pesou.keys()])
	var perto := 99.0
	for a in mg._todas:
		for b in mg._todas:
			if a != b and int(a[0]) == int(b[0]):
				perto = minf(perto, absf(float(a[1]) - float(b[1])))
	_esperar(perto >= 1.0, "Titã: a vez do mesmo lugar nunca a menos de uma batida (%.2f)" % perto)
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S04_J17")
	var pistas := linhas.filter(func(e): return e.get("tipo") == "sensacao" and e.get("nome") in ["aviso", "golpe_esq"])
	_esperar(pistas.size() >= 1, "Titã: %d passos do titã mandados" % pistas.size())
	var bracos := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "quase_pego" \
		and float(e.get("t_musica", 0.0)) >= 33.0 and float(e.get("t_musica", 0.0)) <= 100.0)
	_esperar(bracos.size() >= 1, "Titã: %d braços entre 33 e 100 s (o mínimo é 1)" % bracos.size())
	for a in bracos:
		_esperar(float(a.get("x_tela", 0.0)) >= 0.2 and float(a.get("x_tela", 0.0)) <= 0.8 \
			and float(a.get("altura_tela", 0.0)) >= 0.08, "Titã: o braço no meio da tela (%s)" % [a])
	_esperar(linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "reta").size() <= 1, \
		"Titã: a linha momento reta no máximo uma vez")
```

(`_joga_o_minigame` é da H08; `_linha_do_tempo` da F01; as duas já estão na prova.)

### O que o registro mede

- `sensacao` `aviso`/`golpe_esq`/`explosao`/`golpe` e a `saida` de vibração (`seq`, `ok`); a `saida` de gatilho
  (modo 1, 2, 4 ou 6).
- `pista` (`canal` `rumble`, ou `alto_falante`); o `toque` do kit na pá; `entrada` `fantasma` na pá fora da vez
  (com o dono da vez mais perto); `momento` `quase_pego` e `reta`.

### As pranchas que o jogador do time olha

O quadro de 10 s (a pá ou o tranco), o primeiro depois de 33,1 s (o braço sobre o vagão, as marcas de dedo), o
do meio do pico (a luz mais alta e a câmera mais longe), o de 93 s (o fogo da caldeira) e o último (a ponte ou o
titã que alcançou).

### O que o André joga e sente

`./run-local.sh -- --sala=S04_J17`, com quatro DualSense:

- no começo, a vez anda em roda e a mão confirma; no pico, a vez pula e só a mão sabe;
- o passo engrossa quando o titã chega perto, e o R2 pesa mais;
- o bote aos 33 s assusta: o braço bate no vagão e os quatro controles explodem juntos;
- o tranco derruba o cavaleiro e a grade voa; a derrota (o titã alcançando) tem cara de fim;
- a barra de luz pulsa quando o perigo é grande e volta à cor.

### Armadilhas

- **Nunca `Array.shuffle()`:** usa o gerador global e quebra a semente. O embaralhar é Fisher-Yates com
  `rng.randi_range`.
- **A distância mínima entre as vezes do mesmo lugar** (1 batida; 1,5 na saída) deixa a pista inteira. A prova
  confere pela `_todas`.
- **O braço tira as notas de `4c` a `4c + 1,5`** antes de mandar a pista delas: a `explosao` do momento não pode
  cair numa pista.
- **O compasso do titã conta uma vez** (`_compasso_do_tita`); o treino também avança o titã, mas não soma pontos.
- **O `coop_venceu`** é da `SalaJogo` (F03); o `coop` vem do gênero (H08).
- **O R2 é do minigame, o L2 do item** (G03): nunca `gatilhos_off` depois do `montar`.
- **Pela batida:** dormentes, titã, braço e ponte se mexem por `Ritmo.batida()`; o tween da grade é enfeite.

### Ao terminar

- No [quadro](README.md): a linha **L2**, com o commit (`feito (<commit>)`).
- Commit sugerido (sem trailer): `feat: Fuga do Titã, o coop d'O Impacto, a vez que passa de mão em mão`
