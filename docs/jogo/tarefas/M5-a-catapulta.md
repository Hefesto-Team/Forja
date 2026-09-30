# M5 — A Catapulta

**Sprint:** M · **Slot:** S05_J25 · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 1,5 · **Depende de:** H04, F09, M1

## Por quê

O segundo 2v2 da seção, e o único em que a carga passa **de um dedo para o
outro**. Um da dupla puxa a corda (o R2 dele resiste, cada vez mais); o
outro trava no contratempo (o R2 dele tem a parede e o clique da Weapon) e
lança. A pedra só voa se os dois fazem a parte no tempo. O verbo do gatilho
aqui é **carregar e passar adiante**; cada dupla sente o mesmo lançamento
em dois gatilhos diferentes.

**Adaptado do [03](../03-os-45-minigames.md#s5--a-galeria--gatilho-adaptativo-e-luzinhas-de-jogador):**
a munição (as pedras) está no monte ao lado da catapulta e no peso do
gatilho; a equipe está na cor do castelo e da bandeira, nunca na barra de
luz nem nas luzinhas.

## Ler antes

- [O índice da seção](M-a-galeria.md) e a [M1](M1-a-galeria.md) (o cenário comum, as cores das duplas, o `_joga_o_minigame`)
- A [M4](M4-espada-de-fita.md) (as duplas pela metade e o sozinho)
- [O molde de minigame](molde-de-minigame.md) e o [kit](../13-arquitetura.md#o-kit-do-minigame--h04)

## A ficha de dados

`godot/scripts/minigames/s05/a_catapulta.gd`:

```gdscript
extends Minigame
## A Catapulta (S05_J25) — cada dupla tem uma catapulta e um castelo. A cada
## compasso: o puxador puxa a corda no primeiro tempo (o R2 dele resiste e
## pesa mais a cada meia batida) e solta no terceiro, quando a trava pegou;
## o travador aperta o R2 até o clique no contratempo (o "e" do segundo
## tempo) e solta no quarto — a pedra voa no castelo da outra dupla. A cada
## oito compassos, os dois trocam de posto.
##
## A falha: a trava fora do tempo — a corda escapa e a pedra cai no próprio
## muro; a puxada fora do tempo — a concha vai vazia; a soltura fora do
## tempo — a pedra sai torta (meio dano).
## O vencedor: a dupla que derrubou o castelo da outra, ou deu mais dano em
## 90 s; dentro dela, mais pontos.
## O alto-falante do dono: a trava que pega ("clique"); a pedra no castelo
## rival ("coleta"); a pedra no próprio muro ("golpe").
## O registro mede: o Feedback da corda (os degraus) e a Weapon da trava
## (o clique), com o curso de cada um no aperto e na soltura.
## O robô: sente o posto pelo modo do R2 (Feedback é a corda, Weapon é a
## trava) e faz a parte dele pelo relógio da música; quando não acerta,
## 250 ms tarde.
## Com menos de quatro: o sozinho puxa, e a trava da catapulta dele é o
## contrapeso (sempre no tempo, vale ÓTIMO); com um jogador, o castelo rival
## é vazio (só o dano conta).
## A régua: (1) "Carregue e lance!" com a catapulta e o castelo rival;
## (2) sim: o posto e o tempo estão no gatilho; (3) não pergunta nada.

const FICHA := {
	"slot": "S05_J25",
	"titulo": "A Catapulta",
	"verbo": "Carregue e lance!",
	"genero": "2v2",
	"icone": "gatilho_adaptativo",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S05_J25",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "explosao"],
	"material": "madeira",
	"microjogo": {"verbo": "Lance!", "segundos": 6.0},
}

const PONTOS := [0, 40, 70, 100]  ## o placar de cada um, por nota
const DANO := [0, 1, 2, 3]  ## o que cada nota põe na pedra
const CONTRAPESO := 2  ## a trava automática do sozinho vale ÓTIMO em cada nota dela
const PROPRIO_MURO := 4  ## a pedra que cai no próprio muro
const VIDA_DO_CASTELO := 150
const TROCA_A_CADA := 8  ## compassos até os dois trocarem de posto
## A corda (Feedback, posição 2): a força ao puxar, e +1 a cada meia batida, até 8.
const CORDA_INICIO := 3
const CORDA_PARADA := 1
## A trava (Weapon): o começo da parede, o fim e a força.
const TRAVA := [2, 6, 7]
## O tempo do compasso, em batidas desde 4c: [puxa, trava, solta a corda, lança].
const TEMPOS := [[0.0, 1.5, 2.0, 3.0], [0.0, 2.5, 3.0, 3.5], [0.0, 1.5, 2.0, 3.0]]  ## entrada, pico, saída
```

## Como se joga

**As duplas** são as da M4 (`presentes()` em ordem, a primeira metade é a
dupla 0). **Os postos:** em cada dupla de dois, o de lugar menor é o
**puxador** e o outro o **travador** nos compassos 1 a 8; trocam a cada
`TROCA_A_CADA` compassos (no compasso da troca, sem notas: os dois correm
um para o lugar do outro, e o sino toca na TV, `Som.tocar("sino_viga", null, -6.0)`).
O gatilho diz o posto: o puxador tem o R2 em Feedback
(`Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, CORDA_PARADA)`), o
travador em Weapon (`Forja.gatilho(l, 1, Forja.GATILHO_ARMA, TRAVA[0], TRAVA[1], TRAVA[2])`).

**O lançamento** do compasso `c`, com `T = TEMPOS[parte]` e `b0 = 4c`:

| nota | quem | quando | o R2 |
| --- | --- | --- | --- |
| `puxa` | puxador | `b0 + T[0]` | passa de `R2_APERTA` para cima; a corda pesa `CORDA_INICIO` e sobe 1 a cada meia batida até 8 |
| `trava` | travador | `b0 + T[1]` (o contratempo) | passa de `R2_CLIQUE` para cima (o clique da Weapon) |
| `solta` | puxador | `b0 + T[2]` | cai abaixo de `R2_SOLTA`; a corda volta a `CORDA_PARADA` |
| `lanca` | travador | `b0 + T[3]` | cai abaixo de `R2_SOLTA`: a pedra voa |

Cada nota: `{"n": int(round(b * 2)) + <0 puxa, 0 trava, 1 solta, 1 lanca>, "b": b, "t": Ritmo.t_da_batida(b), "tipo": ...}`,
com `nova_nota` na geração (os `n` de uma mesma pessoa nunca repetem: as
batidas dela são diferentes). O pico (30–60 s) é o contratempo mais
difícil: a trava no "e" do terceiro tempo e o lançamento na colcheia
seguinte. Quem está com `Ritmo.simples[l]` fica com os `TEMPOS` da entrada.

**O julgamento** é o do kit em cada uma (`julgar_toque(l, t, n)` a até
`JANELA_BOM`; a que passa é `nota_perdida`). O que cada resultado faz:

- `puxa` ERRO → a concha vai vazia: as outras três notas do compasso
  continuam (o jogo segue no tempo), mas o lançamento não tem pedra;
- `trava` ERRO → a corda escapa: a pedra cai no próprio muro
  (`vida[d] -= PROPRIO_MURO`) e o `lanca` do compasso sai da lista sem erro;
- `solta` ou `lanca` ERRO → a pedra sai torta: dano pela metade.

**O dano** do lançamento: a soma de `DANO[j]` das quatro notas (a trava do
contrapeso vale `CONTRAPESO` em cada uma das duas dele), no castelo da
outra dupla, quando a pedra cai — em `b0 + T[3] + 1,5` (o arco do voo, pela
batida). Castelo em 0 → todos `acabou`.

**Os pontos** de cada um: `marcar(l, Itens.pontos_do_acerto(l, PONTOS[j], j, fmod(b, 4.0) == 0.0))`.

Cada aperto e soltura gravam o `jogo` `disparo` (modo `"resistencia"` do
puxador ou `"arma"` do travador, curso, curso máximo); cada lançamento grava
`Forja.evento("jogo", 0, {"slot": id, "o": "lancamento", "dupla": d, "dano": dano})`.

## O cenário

- `CenarioDaGaleria.montar(self)`; a câmera alta para os dois castelos:
  `camera_pos = Vector3(0, 8.4, 11.6)`, `camera_olhar = Vector3(0, 0.8, -2.4)`.
- Por lugar: `raia(l)`, `posicionar(l)`, `preso = true`, `rotation.y = PI`.
  O puxador fica na raia de fora (x = ±6) e o travador na de dentro (±2);
  na troca, eles trocam de raia (tween de 0,5 s com `animar("sprint")`), e
  a borda da raia vai com o boneco (a raia do kit é do lugar: mova o
  `Node3D` dela junto).
- **A catapulta** de cada dupla, entre as duas raias dela (x = ±4,
  `Z_JOGADOR − 1.6`): a base `Kit.peca(self, "wood-structure", pos, 0.0, 1.6)`,
  o braço `Kit.caixa(braco, Vector3(0.22, 0.22, 3.0), Vector3(0, 0, -1.2), madeira)`
  num `Node3D` pivô em `pos + Vector3(0, 1.4, 0)`, a concha
  `Kit.peca(braco, "pot", Vector3(0, 0.2, -2.6), 0.0, 1.0)`, e a corda
  `Kit.caixa(self, Vector3(0.04, 0.04, 1.0), ...)` do braço até a mão do
  puxador. O braço baixa com a corda (`rotation.x` de 0 a 0,7 pelo peso) e
  dispara no lançamento (a −0,9 em 0,15 s e volta em uma batida).
- **O monte de pedras** ao lado: `Kit.peca(self, "stones", pos + Vector3(±1.2, 0, 0.6), 0.0, 1.2)`
  com a escala caindo de 1,2 a 0,5 ao longo dos oito compassos do posto, e
  cheio de novo na troca; a pedra na concha é `Kit.peca(concha, "rocks", ..., 0.0, 0.5)`.
- **Os castelos:** o da dupla 0 em `(-6.5, 0, -6.0)`, o da dupla 1 em
  `(6.5, 0, -6.0)`: três andares de `Kit.peca(self, "wall", ..., 0.0, 2.0)`
  (quatro peças por andar, em quadrado) e as ameias de `wall-half`; a
  bandeira `Kit.peca(self, "banner", topo, 0.0, 2.0)` com o pano na cor
  `CenarioDaGaleria.EQUIPE[d]` (fosco). A cada 25% de vida perdida, uma
  peça de cima cai (tween para o chão e some); em 0, o castelo desaba
  (todas as peças caem em uma batida) com `explosao` nos dois da dupla dele.
- **A pedra que voa:** `Kit.peca(self, "rocks", ..., 0.0, 0.6)` em arco da
  concha ao castelo rival, pela batida (1,5 batida de voo, `y` em parábola).
- O checklist do 11: madeira e pedra do kit, foscas; a cor da dupla só no
  pano da bandeira.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **gatilho (protagonista)** | puxador: R2 `GATILHO_RESISTENCIA` (2, 3 → 8), a corda | da puxada à soltura; `(2, 1)` fora dela |
| **gatilho (protagonista)** | travador: R2 `GATILHO_ARMA` (2, 6, 7), a parede e o clique da trava | sempre, enquanto ele é travador |
| vibração | `acerto` / `perfeito` / `erro` (o kit) | nas quatro notas |
| vibração | `golpe` | nos dois da dupla cujo castelo leva a pedra (e no próprio muro) |
| vibração | `explosao` | nos dois da dupla cujo castelo desaba |
| barra de luz | a cor do lugar, 100%; branco 0,1 s | no lançamento com as quatro notas boas, nos dois |
| luzinhas de jogador | o número, sempre | — |
| alto-falante do dono | `Forja.som_falante(l, "clique", 0.7)` | no travador, na trava BOM ou ÓTIMO (no perfeito, a nota do kit) |
| alto-falante do dono | `Forja.som_falante(l, "coleta", 0.7)` | nos dois, quando a pedra deles cai no castelo rival |
| alto-falante do dono | `Som.no_controle(l, "golpe", 0.7)` | nos dois, quando uma pedra cai no castelo deles |
| háptica por material | `"madeira"` (o kit) | — |
| som na TV | `"pedra"` na pedra que cai; `"portao"` no castelo que desaba; `"sino_viga"` na troca de posto | — |

## A falha

- **A corda escapa** (trava ERRO): o braço volta sozinho e a pedra cai de
  lado, no próprio muro (o arco curto para o castelo da própria dupla),
  `Som.tocar("pedra", ...)`, o travador `gesto("emote-no", 0.4)`, o
  puxador `gesto("fall", 0.4)` (a corda puxou ele).
- **A concha vazia** (puxada ERRO): o braço dispara no lançamento sem
  pedra, com um estalo seco (`Som.tocar("vazio", ...)`).
- **A pedra torta** (soltura ou lançamento ERRO): a pedra voa baixa e acerta
  só a base do castelo (meio dano, faíscas pequenas).
- **A recuperação:** o compasso seguinte é um lançamento novo; o monte de
  pedras não acaba (só encolhe no posto).

## O fim e o vencedor

Castelo derrubado (todos `acabou`) ou 90 s de `t_jogo`. A dupla na frente
é a de castelo de pé (se um caiu) ou a de mais dano dado
(`VIDA_DO_CASTELO - vida[outra]`); dentro dela, mais pontos. O
`vencedor()` é o da M4 com `_dupla_na_frente()` assim:

```gdscript
func _dupla_na_frente() -> int:
	if vida[0] <= 0 or vida[1] <= 0:
		return 0 if vida[0] > 0 else 1
	return 0 if vida[1] <= vida[0] else 1
```

## Com menos de quatro

- **Três:** o sozinho é sempre o puxador; a trava da catapulta dele é o
  contrapeso (um peso de pedra que desce sozinho no contratempo: sem nota,
  vale `CONTRAPESO` duas vezes). `com_poucos()`: `"Dois contra um"`.
- **Dois:** os dois puxam, cada um com o contrapeso. `com_poucos()`: `"Um contra um"`.
- **Um:** ele puxa; o castelo rival não tem ninguém, e o minigame acaba ao
  derrubá-lo ou aos 90 s. `com_poucos()`: `"Derrube o castelo"`.
- **O controle que cai:** as notas dele somem sem erro; se era o travador,
  a catapulta passa ao contrapeso até ele voltar; se era o puxador, o
  travador vira puxador (o R2 dele muda para o Feedback no compasso
  seguinte) e o contrapeso trava.

## O robô

```gdscript
# O robô sente o posto pelo modo do R2 no controle simulado (0x21 Feedback:
# a corda; 0x25 Weapon: a trava) e faz a parte dele pelo relógio da música:
# segura o R2 da nota de apertar até a de soltar. Quando não acerta, 250 ms tarde.
var _robo_nota := [-1, -1, -1, -1]
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]
var _robo_segura := [false, false, false, false]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var modo := int(Forja.percepcao(l).get("gatilho_dir", 0))
	if modo != 0x21 and modo != 0x25:
		_robo_segura[l] = false
	elif not _notas[l].is_empty():
		var nt: Dictionary = _notas[l][0]
		if int(nt.n) != _robo_nota[l]:
			_robo_nota[l] = int(nt.n)
			# o temperamento (--robo=bom|medio|ruim): quando não acerta, 250 ms tarde
			_robo_atraso[l] = 0.0 if Forja.robo_acerta() else 0.25
		if Ritmo.t_musica() >= float(nt.t) + float(_robo_atraso[l]):
			_robo_segura[l] = nt.tipo == "puxa" or nt.tipo == "trava"
	Forja.robo_eixo(l, Forja.R2, 1.0 if _robo_segura[l] else 0.0, 0.06)
```

(O robô travador aperta até o fundo: passa do clique. O puxador também:
a corda é resistência, não parede.)

## Os ganchos

```gdscript
var _notas := [[], [], [], []]
var _ultima := [{}, {}, {}, {}]
var _gerado := 1
var _fora := [false, false, false, false]
var _apertado := [false, false, false, false]
var duplas := [[], []]
var vida := [VIDA_DO_CASTELO, VIDA_DO_CASTELO]
var _posto := {}  ## lugar -> "puxador" | "travador"
var _lancamentos := {}  ## c -> {dupla: {"dano": int, "sem_pedra": bool, "torta": bool, "escapou": bool}}
var _corda := [0, 0, 0, 0]  ## a força mandada ao R2 do puxador


func montar() -> void:
	camera_pos = Vector3(0, 8.4, 11.6)
	camera_olhar = Vector3(0, 0.8, -2.4)
	CenarioDaGaleria.montar(self)
	var lista := jogadores.map(func(p): return p.lugar)
	lista.sort()
	var meio := (lista.size() + 1) / 2
	duplas = [lista.slice(0, meio), lista.slice(meio)]
	_montar_as_catapultas_e_os_castelos()
	for p in jogadores:
		raia(p.lugar)
		posicionar(p.lugar)
		p.preso = true
		p.rotation.y = PI
	_dar_os_postos(0)  # o de lugar menor puxa; o sozinho puxa; manda os gatilhos


func jogar(_dt: float) -> void:
	while _gerado <= int(floor(Ritmo.batida() / 4.0)) + 1:
		_gerar_compasso(_gerado)  # troca de posto a cada TROCA_A_CADA (compasso sem notas)
		_gerado += 1
	var agora := Ritmo.t_musica()
	for l in presentes():
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_notas[l] = _notas[l].filter(func(nt): return float(nt.t) > agora and (nt.tipo == "puxa" or nt.tipo == "trava"))
		var r2 := Forja.eixo(l, Forja.R2)
		var limiar := CenarioDaGaleria.R2_CLIQUE if _posto.get(l, "") == "travador" else CenarioDaGaleria.R2_APERTA
		if not _apertado[l] and r2 >= limiar:
			_apertado[l] = true
			_apertar(l, r2)
		elif _apertado[l] and r2 <= CenarioDaGaleria.R2_SOLTA:
			_apertado[l] = false
			_soltar(l, r2)
		_puxar_a_corda(l)  # o Feedback sobe 1 a cada meia batida desde a puxada boa
		while not _notas[l].is_empty() and agora > float(_notas[l][0].t) + Ritmo.JANELA_BOM:
			var nt: Dictionary = _notas[l].pop_front()
			_ultima[l] = nt
			nota_perdida(l, int(nt.n))
	_voar_as_pedras()  # pela batida; ao cair, o dano e o castelo


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	marcar(l, Itens.pontos_do_acerto(l, PONTOS[julgamento], julgamento, fmod(float(nt.b), 4.0) == 0.0))
	_somar_no_lancamento(l, nt, DANO[julgamento])
	match nt.tipo:
		"puxa":
			_corda_puxada(l, float(nt.b))
		"trava":
			if julgamento != Ritmo.PERFEITO:
				Forja.som_falante(l, "clique", 0.7)
		"solta":
			_corda(l, CORDA_PARADA)
		"lanca":
			_lancar(_dupla_de(l), int(floor(float(nt.b) / 4.0)))


func falha(l: int) -> void:
	var nt: Dictionary = _ultima[l]
	var c := int(floor(float(nt.get("b", 0.0)) / 4.0))
	match nt.get("tipo", ""):
		"puxa":
			_marcar_sem_pedra(_dupla_de(l), c)
		"trava":
			_corda_escapa(_dupla_de(l), c)  # próprio muro; tira o "lanca" sem erro
		"solta":
			_corda(l, CORDA_PARADA)
			_marcar_torta(_dupla_de(l), c)
		"lanca":
			_marcar_torta(_dupla_de(l), c)
			_lancar(_dupla_de(l), c)


## A corda: a força no R2 do puxador, mandada só quando muda.
func _corda(l: int, forca: int) -> void:
	if _corda[l] != forca:
		_corda[l] = forca
		Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, forca)
```

`_apertar(l, r2)` e `_soltar(l, r2)` acham a nota do tipo certo para o
posto (`puxa`/`trava` no aperto, `solta`/`lanca` na soltura) a até
`JANELA_BOM`, gravam o `disparo`, põem em `_ultima[l]`, tiram da lista e
chamam `julgar_toque`; sem nota perto, nada. `_dar_os_postos(c)` manda o
Feedback ao puxador e a Weapon ao travador.

Catálogo: `"S05_J25"` em `MINIGAMES` e na lista da seção `S05`. O `.uid`.
Traduções: `"A Catapulta": "The Catapult"`, `"Carregue e lance!": "Load and launch!"`,
`"Lance!": "Launch!"`, `"Derrube o castelo": "Knock the castle down"`, e as
da M4 que ainda não existirem; `dica(l)`: `{"partes": ["@r2", "Puxe a corda"], ...}`
para o puxador e `{"partes": ["@r2", "Trave e lance"], ...}` para o
travador, com `na_raia(l)` e `not aprendeu(l)` (`"Puxe a corda": "Pull the rope"`,
`"Trave e lance": "Lock and launch"`).

## O que o registro mede

- A `saida` de gatilho: o Feedback da corda (os degraus) e a Weapon da trava
  (`params` `[2, 6, 7]`), `seq`, `ok`, e a troca de posto (o modo muda).
- `jogo` `disparo` nas quatro notas (curso: a trava sai logo acima de 0,62
  quando o clique existe), o `toque` do kit e o `jogo` `lancamento`.

## Armadilhas

- **O limiar do aperto depende do posto:** o travador só aperta de verdade
  no clique (`R2_CLIQUE`); o puxador em `R2_APERTA`.
- **A trava ERRO tira o `lanca` sem erro:** a falha dela já é a pedra no
  próprio muro; o lançamento não conta de novo.
- **A troca de posto** muda o modo do R2 dos dois no compasso sem notas:
  mande a Weapon a um e o Feedback ao outro no começo desse compasso.
- **O L2 é do item** (G03): tudo aqui é R2.
- **A cor da dupla nunca na barra de luz** (F04).
- **Os pontos e o item:** se o kit já aplica `Itens.pontos_do_acerto`, marque cru.

## Pronto quando

A Catapulta joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô
nos três temperamentos; troca os postos a cada oito compassos; aguenta o
cabo que cai (o contrapeso entra); fecha com vencedor (a dupla de castelo
de pé ou de mais dano); a prova do jogo passa; e `bash tests/prova_visual.sh`
passa com a **prancha olhada** com a Catapulta nela (na cópia de trabalho,
sem commitar, `"S05_J25"` em primeiro na lista da seção `S05`; depois volte a ordem).

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, depois das outras da seção:

```gdscript
## A Catapulta (S05_J25): numa dupla de dois, um R2 em Feedback (a corda) e o
## outro em Weapon (a trava); o castelo só perde vida; o vencedor da dupla na frente.
func _prova_da_catapulta() -> void:
	var postos_ok := [false]
	var vidas: Array = []
	var olhar := func(m: Minigame) -> void:
		for d in 2:
			if m.duplas[d].size() == 2:
				var a := int(Forja.percepcao(m.duplas[d][0]).get("gatilho_dir", 0))
				var b := int(Forja.percepcao(m.duplas[d][1]).get("gatilho_dir", 0))
				if (a == 0x21 and b == 0x25) or (a == 0x25 and b == 0x21):
					postos_ok[0] = true
		vidas.append([int(m.vida[0]), int(m.vida[1])])
	var mg := await _joga_o_minigame("S05_J25", 60.0, olhar)
	if mg == null:
		return
	if mg.presentes().size() >= 3:
		_esperar(postos_ok[0], "Catapulta: a corda num dedo e a trava no outro")
	var subiu := false
	for i in range(1, vidas.size()):
		for d in 2:
			if vidas[i][d] > vidas[i - 1][d]:
				subiu = true
	_esperar(not subiu, "Catapulta: o castelo nunca ganha vida")
	var v := mg.vencedor()
	var d := mg._dupla_na_frente()
	_esperar(mg.duplas[d].is_empty() or v[0] in mg.duplas[d], "Catapulta: a dupla na frente vem primeiro (%s)" % [v])
```

**O que o André joga e sente** (`./run-local.sh -- --sala=S05_J25`):

- a corda pesa mais a cada meia batida e o dedo sabe quando soltar;
- a trava tem a parede e o clique, no contratempo — o do pico é difícil e bom;
- o lançamento é dos dois: quando sai inteiro, a pedra é grande;
- a troca de posto a cada oito compassos refresca a mão;
- a cor da dupla está no castelo e na bandeira; a barra de luz é de cada um.

## Ao terminar

- No [quadro](README.md): a linha **M5** (se não existir, acrescente
  `| [M5](M5-a-catapulta.md) | M | S5 — A Catapulta | M | Sonnet | 1,5 | feito (<commit>) | <gasto> |`),
  com o commit e o gasto real. Com as cinco feitas, a linha **M** da seção
  também vira **feito**.
- Commit sugerido (sem trailer):
  `feat: A Catapulta — a corda num gatilho, a trava no outro`
