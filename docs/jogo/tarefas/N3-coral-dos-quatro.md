# N3 — Coral dos Quatro

**Sprint:** N · **Slot:** S06_J28 · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 1,5 · **Depende de:** H04, H08, F09, N1, H07

## Por quê

O coop da seção, e o hoqueto no sentido mais literal: o acorde é dividido,
cada controle tem a sua nota (dó, ré, fá, sol — a nota do lugar da H07), e
o acorde só fecha se cada um cantar a sua **na vez dela**. A vez muda a cada
frase, e quem conta a vez é o próprio controle: no compasso da chamada, o
alto-falante de cada um canta na posição em que ele vai responder. O verbo
do alto-falante aqui é **achar a sua vez** — n'O Canto (N1) a vez é fixa e o
que muda é a altura; aqui a nota é sempre a sua e o que muda é o quando.

## Ler antes

- [O índice da seção](N-o-canto.md) e a [N1](N1-o-canto.md) (o cenário comum, chamada e resposta, o robô que ouve)
- [O molde de minigame](molde-de-minigame.md) e o [kit](../13-arquitetura.md#o-kit-do-minigame--h04)
- [Todo minigame fecha](F03-todo-minigame-fecha.md) (o `coop` e o `coop_venceu`)

## A ficha de dados

`godot/scripts/minigames/s06/coral_dos_quatro.gd`:

```gdscript
extends Minigame
## Coral dos Quatro (S06_J28) — o acorde dividido. Nos compassos ímpares (a
## chamada), o alto-falante de cada controle canta a nota do lugar dele numa
## das quatro batidas — a vez dele. Nos pares (a resposta), cada um aperta ✕
## na mesma batida: o arpejo volta inteiro na TV. A ordem das vezes se
## embaralha a partir do pico; no pico, às vezes os quatro cantam juntos (o
## acorde) e respondem juntos.
##
## A falha: a nota falta ou sai fora da vez — o coral desafina e o vitral trinca.
## O vencedor: coop — o vitral inteiro aceso (todos vencem) ou não; quem
## cantou mais no tempo leva o destaque.
## O alto-falante do dono: a nota dele na chamada (a protagonista).
## O registro mede: cada chamada (a nota do lugar, se foi ao controle) e a
## resposta na vez: se a chamada não chegou, a resposta sai fora da vez.
## O robô: ouve em que batida o próprio alto-falante cantou na chamada e
## aperta na mesma batida da resposta; quando não acerta, 250 ms tarde.
## Com menos de quatro: as vezes são tantas quantos jogadores; as outras
## batidas ficam para o sino grande.
## A régua: (1) "Cante a sua!" com o vitral e o coro; (2) sim: a vez só o
## próprio controle diz; (3) não pergunta nada.

const FICHA := {
	"slot": "S06_J28",
	"titulo": "Coral dos Quatro",
	"verbo": "Cante a sua!",
	"genero": "coop",
	"icone": "alto-falante",
	"entradas": [Forja.CRUZ],
	"camera": "fixa",
	"faixa": "MUS_S06_J28",
	"duracao": 90.0,
	"fim": "meta_coletiva",
	"sensacoes": ["toque", "acerto", "perfeito", "erro"],
	"material": "madeira",
	"microjogo": {"verbo": "Cante!", "segundos": 6.0},
	"nota_no_falante": false,  # o alto-falante é a pista: o kit não toca a nota do perfeito nele (H08)
}

const PONTOS := [0, 40, 70, 100]  ## ERRO, BOM, OTIMO, PERFEITO
const PAINEIS := 12  ## o vitral: 4 × 3
## As cores do vitral: foscas, longe das cores dos lugares (docs/jogo/11, regra 6).
const CORES_DO_VITRAL := [Color("#e8b44c"), Color("#6fd3c8"), Color("#c28bff"), Color("#e9e7f2")]
const ACORDE_A_CADA := 4  ## no pico, a chamada c com (c / 2) % 4 == 3 é o acorde junto
const PULSO_S := 0.12
```

## Como se joga

**Os compassos:** o 0 é a contagem; os ímpares são a **chamada**, o par
seguinte a **resposta**. O compasso de chamada é gerado quando
`Ritmo.batida() >= 4c − 4` e gera também a resposta.

**As vezes:** `lista = presentes()` em ordem, `k = lista.size()`. Cada
chamada escolhe `k` das quatro batidas (`0..3`) e dá uma a cada lugar:

| parte | música (`progresso()` do kit) | as batidas e a ordem |
| --- | --- | --- |
| entrada | 0–30 s | as batidas `[0, 1, 2, 3]` (com dois: `[0, 2]`; com um: `[0]`; com três: `[0, 1, 2]`), na ordem de `lista`: a roda de sempre |
| **pico** | 30–60 s | as mesmas batidas, embaralhadas entre os lugares pelo `rng` (Fisher-Yates com `rng.randi_range`; nunca `Array.shuffle`); a chamada com `(c / 2) % ACORDE_A_CADA == 3` é **o acorde**: todos na batida 0 |
| saída | 60–90 s | `k` batidas sorteadas entre as quatro (qualquer posição), embaralhadas |

Quem está com `Ritmo.simples[l]` fica com a mesma vez da chamada anterior.

**A chamada:** na batida `b = 4c + vez` de cada lugar, `var foi := CenarioDoCanto.falante(self, l, "nota:%d" % l, 0.9)`
e `Forja.evento("pista", l + 1, {"slot": id, "n": n, "evento": "mandou", "via": "alto_falante" if foi else "tv", "o_que": "nota:%d" % l, "no_controle": foi})`.
Na tela, nenhum sino balança na chamada (a vez é só do alto-falante); o
sino grande dá o tempo forte.

**A resposta:** a nota do lugar em `b + 4`:
`{"n": int(round((b + 4) * 2)), "b": b + 4, "t": Ritmo.t_da_batida(b + 4), "c": c + 1}`,
com `nova_nota(l, n, t)`. ✕ a até `Ritmo.JANELA_BOM` dela → `julgar_toque(l, t, n)`;
✕ longe da nota dele → nada (o kit não julga; o jogador só perdeu o
aperto). A nota que passa é `nota_perdida(l, n)`. O kit toca na TV a nota
com o tom do lugar (`TOM_DO_LUGAR`): o arpejo volta inteiro.

**O acorde fecha:** quando todas as notas de resposta de um compasso estão
resolvidas, se todas foram BOM ou melhor, um painel do vitral acende
(`acesos += 1`; o sino grande toca, `Som.tocar("sucesso", CenarioDoCanto.SINO_TV, -6.0)`);
se alguma faltou, **o vitral trinca**: o último painel aceso apaga com uma
trinca (`acesos = maxi(0, acesos - 1)`). `acesos == PAINEIS` → o coral vence:
`coop_venceu = true`, todos `acabou`.

**Os pontos** (o destaque): `marcar(l, PONTOS[julgamento])` (o item, `Itens.pontos_do_acerto`, o kit já aplica no `julgar_toque`: H08).

**O compasso na mão:** `Forja.sentir(l, "toque")` no começo de cada compasso
e `CenarioDoCanto.tempo_forte()`.

**Os 90 segundos:** entrada, a roda (aprende-se a própria nota); **pico**,
a ordem embaralhada e o acorde junto — aos 30 s o vitral se ilumina por
trás (`pulso_de_luz(Color("#e8b44c"))`) e o coro de bonecos de pedra no
fundo abre a boca; saída, as vezes em qualquer batida.

## O cenário

- `var grande := CenarioDoCanto.montar(self)` (o `coop` vem do gênero da FICHA: H08); a câmera d'O Canto.
- Por lugar: `raia(l)`, `posicionar(l)`, `preso = true`, e o sino pequeno
  com o suporte (N1: `CenarioDoCanto.sino(self, Vector3(RAIAS[l] + 0.6, 1.8, Z_JOGADOR - 0.35), 0.34, Color("#c08a42"))`),
  que balança **na resposta** boa dele.
- **O vitral**, na parede do fundo atrás do sino grande: uma moldura
  `Kit.caixa(self, Vector3(5.2, 3.6, 0.2), Vector3(0, 3.4, -7.4), Kit.material(Color("#3a2a24"), 0.0, 0.9))`
  e 12 painéis `Kit.caixa(self, Vector3(1.1, 0.95, 0.06), Vector3(-1.8 + 1.2 * (i % 4), 2.2 + 1.05 * (i / 4), -7.25), mat_i)`
  com `mat_i = Kit.material(CORES_DO_VITRAL[i % 4].darkened(0.7), 0.0, 0.8)`;
  aceso, o emissivo da cor dele (1,4); trincado, uma caixa escura fina em
  diagonal por cima.
- **O coro de pedra** no fundo, dos dois lados do vitral: quatro
  `Kit.peca(self, "column", Vector3(±3.6, 0, -6.8) e (±4.6, 0, -6.4), 0.0, 1.2)`
  com a boca `Kit.caixa(Vector3(0.3, 0.12, 0.05))` escura que abre (escala y
  1 → 2,5) quando o acorde fecha.
- O checklist do 11: vitral e coro de caixas e peças do kit, foscos; as
  cores do vitral longe das dos lugares; o emissivo só no painel aceso.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **alto-falante (protagonista)** | `"nota:<lugar>"` (a nota do lugar: dó, ré, fá, sol), 0,9 | na chamada, na batida da vez dele |
| vibração | `toque` | no começo de cada compasso |
| vibração | `acerto` / `perfeito` / `erro` (o kit) | na resposta julgada |
| barra de luz | `CenarioDoCanto.luz_da_nota(l, 0.6)` por `PULSO_S`, e volta a 1,0 | na resposta boa — nunca na chamada |
| luzinhas de jogador | o número, sempre | — |
| háptica por material | `"madeira"` (o kit, no cabo) | — |
| gatilho | `Forja.gatilho(l, 1, Forja.GATILHO_OFF)` no `montar` | nada a segurar |
| som na TV | a nota do lugar com o tom dele (o kit) na resposta; `"sucesso"` do sino no acorde fechado; `"falha"` baixo no vitral que trinca | — |

## A falha

- **A nota falta** (resposta ERRO ou perdida): o kit toca a nota quebrada do
  lugar no alto-falante; o cavaleiro fecha a boca e baixa a cabeça
  (`gesto("emote-no", 0.4)`); o sino pequeno dele dá um tranco torto.
- **O coral desafina** (o compasso com alguma falta): o último painel aceso
  trinca e apaga (`Som.tocar("falha", Vector3(0, 3, -7), -8.0)`, faíscas
  cinzentas no painel); o coro de pedra fecha a boca.
- **A recuperação:** a próxima chamada é dois compassos depois; o vitral só
  perde um painel por compasso.

## O fim e o vencedor

`fim` `meta_coletiva`: o vitral inteiro (todos `acabou`, `coop_venceu = true`)
ou os 90 s de música (H08; `coop_venceu = false`: o vitral fica pela metade). O
registro grava `vencedor` −1 (coop); o destaque é quem cantou mais no tempo:

```gdscript
## Coop: o kit grava vencedor −1 (H08); o destaque é quem cantou mais no tempo.
func destaque() -> int:
	var lista := presentes()
	lista.sort_custom(func(a, b): return int(pontos[a]) > int(pontos[b]) or (int(pontos[a]) == int(pontos[b]) and a < b))
	return int(lista[0]) if not lista.is_empty() else -1
```

## Com menos de quatro

- **Três:** três vezes por chamada; a quarta batida é do sino grande.
- **Dois:** duas vezes; o vitral precisa dos mesmos 12 (a frase é mais curta).
- **Um:** uma vez por chamada, em batidas que mudam no pico e na saída; é um
  jogo de ouvido contra o relógio.
- **O controle que cai:** a vez dele não entra nas chamadas seguintes (as
  notas dele somem sem erro, e o acorde do compasso fecha com quem está);
  quando volta, entra na próxima chamada.

## O robô

```gdscript
# O robô ouve o ataque no alto-falante simulado dele durante a chamada (a
# lógica de ataque da N1) e guarda a batida; na resposta, aperta ✕ na mesma
# batida do compasso seguinte. Tudo pelo controle: a vez vem do som que chegou.
var _robo_vale := [1.0, 1.0, 1.0, 1.0]
var _robo_desde := [0.0, 0.0, 0.0, 0.0]
var _robo_vez := [-1.0, -1.0, -1.0, -1.0]  ## a batida da resposta que o robô ouviu
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var nivel := float(Forja.som_virtual(l).get("falante", 0.0))
	var agora := Ritmo.t_musica()
	var b := Ritmo.batida()
	var c := int(floor(b / 4.0))
	if nivel > 0.12 and nivel - float(_robo_vale[l]) > 0.10 and agora - float(_robo_desde[l]) > 0.12:
		_robo_vale[l] = nivel
		_robo_desde[l] = agora
		if c % 2 == 1:  # só na chamada: na resposta, o que toca é a nota do kit
			_robo_vez[l] = floorf(b) + 4.0
			# o temperamento (--robo=bom|medio|ruim): quando não acerta, 250 ms tarde
			_robo_atraso[l] = 0.0 if Forja.robo_acerta() else 0.25
	else:
		_robo_vale[l] = minf(float(_robo_vale[l]), nivel)
	if _robo_vez[l] >= 0.0 and agora >= Ritmo.t_da_batida(_robo_vez[l]) + float(_robo_atraso[l]):
		Forja.robo_apertar(l, Forja.CRUZ, 0.06)
		_robo_vez[l] = -1.0
```

(O ataque cai logo depois da batida da chamada: o `floorf` acha a batida
certa. No acorde junto, os quatro ouvem na batida 0 e respondem na 0.)

## Os ganchos

```gdscript
var _notas := [[], [], [], []]
var _chamadas: Array = []  ## [lugar, batida] a tocar
var _ultima := [{}, {}, {}, {}]
var _gerado := 1
var _compasso := 0
var _fora := [false, false, false, false]
var _respostas := {}  ## compasso -> {lugar: julgamento ou -1 (ainda não)}
var acesos := 0
var _vez_anterior := [0, 0, 0, 0]
var _paineis: Array = []
var _pulso := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	camera_pos = Vector3(0, 5.6, 11.2)
	camera_olhar = Vector3(0, 1.6, -1.0)
	CenarioDoCanto.montar(self)
	_montar_o_vitral_e_o_coro()
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.preso = true
		_montar_o_sino(l)
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
		_gerar_compasso(_gerado)  # nas chamadas: as vezes, a chamada de cada um e a resposta
		_gerado += 1
	var agora := Ritmo.t_musica()
	_tocar_as_chamadas(agora)
	for l in presentes():
		_apagar_o_pulso(l, dt)
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_notas[l] = _notas[l].filter(func(nt): return float(nt.t) > agora)
			_tirar_das_respostas_abertas(l)
		if Forja.apertou(l, Forja.CRUZ):
			_cantar(l)
		while not _notas[l].is_empty() and agora > float(_notas[l][0].t) + FOLGA_PERDIDA:
			var nt: Dictionary = _notas[l].pop_front()
			_ultima[l] = nt
			nota_perdida(l, int(nt.n))
	_fechar_os_acordes()  # o compasso de resposta resolvido: acende ou trinca
	coop_venceu = acesos >= PAINEIS
	if coop_venceu:
		for l in presentes():
			acabou[l] = true


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	marcar(l, PONTOS[julgamento])  # o item, o kit já aplicou (H08)
	_respostas[int(nt.c)][l] = julgamento
	CenarioDoCanto.luz_da_nota(l, 0.6)
	_pulso[l] = PULSO_S
	_balancar_o_sino(l)


func falha(l: int) -> void:
	var nt: Dictionary = _ultima[l]
	if _respostas.has(int(nt.get("c", -1))):
		_respostas[int(nt.c)][l] = Ritmo.ERRO
	_desafinar(l)
```

`_cantar(l)` acha a nota de resposta do lugar a até `JANELA_BOM`, põe em
`_ultima[l]`, tira da lista e chama `julgar_toque`; sem nota perto, nada.
`_fechar_os_acordes()` olha os compassos de `_respostas` em que ninguém está
em −1 e decide (e apaga o compasso do dicionário). `_tirar_das_respostas_abertas(l)`
tira o lugar que caiu das respostas abertas (o acorde fecha com quem ficou).

Catálogo: `"S06_J28"` em `MINIGAMES` e na lista da seção `S06`. O `.uid`.
Traduções: `"Coral dos Quatro": "Choir of Four"`, `"Cante a sua!": "Sing yours!"`,
`"Cante!": "Sing!"`; `dica(l)`: `{"partes": ["@cross", "Na sua vez"], ...}`
com `na_raia(l)` e `not aprendeu(l)` (`"Na sua vez": "On your turn"`).

## O que o registro mede

- `som_controle` (H07) de cada chamada (`nota:<lugar>`, `placa`) e o `jogo`
  `chamada` (n da resposta, `no_controle`).
- O `toque` do kit na resposta: a chamada com `placa` e a resposta perdida
  ou fora da vez, sempre no mesmo controle, é o alto-falante que não cantou.
- `{"o": "acorde", "c": c, "fechou": bool, "acesos": acesos}` a cada compasso de resposta.

## Armadilhas

- **Nenhum sinal da vez na tela durante a chamada:** o sino pequeno só
  balança na resposta boa; o `pulso` da barra de luz, também.
- **As vezes em batidas diferentes:** duas vezes na mesma batida só no
  acorde junto (todos na 0) — aí a nota de cada um é a dele, e o coro soa.
- **Nunca `Array.shuffle()`:** o embaralhar é pelo `rng` da semente.
- **O acorde fecha com quem está:** quem caiu não segura os outros.
- **Os pontos e o item:** o kit aplica `Itens.pontos_do_acerto` no `julgar_toque`
  (H08); marque cru.

## Pronto quando

O Coral dos Quatro joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com
o robô nos três temperamentos (o bom acende o vitral, o ruim não); aguenta o
cabo que cai e volta; fecha com o resultado coop e o destaque; a prova do
jogo passa; e `bash tests/prova_visual.sh` passa com a **prancha olhada** com
o Coral nela (o `Catalogo.sortear` da H08 põe o `S06_J28` na noite: rode a prova visual com a semente que o sorteia, `--semente=N`).

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, depois das outras da seção:

```gdscript
## Coral dos Quatro (S06_J28): é coop; na chamada, só um alto-falante canta
## por vez (fora do acorde junto); o vitral nunca passa de 12 nem fica negativo.
func _prova_do_coral() -> void:
	var fora := [0]
	var olhar := func(m: Minigame) -> void:
		if int(m.acesos) < 0 or int(m.acesos) > m.PAINEIS:
			fora[0] += 1
	var mg = await _joga_o_minigame("S06_J28", 130.0, olhar)
	if mg == null:
		return
	_esperar(mg.coop and mg.destaque() >= 0, "Coral: é coop, com o destaque")
	_esperar(fora[0] == 0, "Coral: o vitral entre 0 e 12")
	var chamadas := _linha_do_tempo().filter(func(e): return e.get("tipo") == "pista" and e.get("slot") == "S06_J28" and e.get("evento") == "mandou")
	var sons := {}
	for e in chamadas:
		sons[str(e.get("som", ""))] = true
	_esperar(chamadas.size() >= 1 and sons.size() >= mini(2, mg.presentes().size()), "Coral: cada um cantou a sua nota (%s)" % [sons.keys()])
```

**O que o André joga e sente** (`./run-local.sh -- --sala=S06_J28`):

- cada um reconhece a própria nota no próprio controle;
- a roda da entrada ensina; no pico, a vez pula e só o ouvido acha;
- o acorde junto dos quatro controles é bonito;
- o vitral acendendo é o placar de todos; a trinca dói em todos.

## Ao terminar

- No [quadro](README.md): a linha **N3** (se não existir, acrescente
  `| [N3](N3-coral-dos-quatro.md) | N | S6 — Coral dos Quatro | M | Sonnet | 1,5 | feito (<commit>) | <gasto> |`),
  com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: Coral dos Quatro — o acorde dividido entre os alto-falantes`
