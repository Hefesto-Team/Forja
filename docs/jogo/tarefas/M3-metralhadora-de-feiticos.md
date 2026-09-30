# M3 — Metralhadora de Feitiços

**Sprint:** M · **Slot:** S05_J23 · **Tamanho:** M · **Estimativa:** US$ 1,5 · **Depende de:** H04, H08, F09, M1

## Por quê

O coop da seção. Uma frota de navios no céu, e os quatro dividem a rajada:
cada um segura o gatilho **só na sua batida**, e o gatilho treme no dedo em
semicolcheias enquanto a rajada dura. Segurar a batida inteira e soltar na
hora certa derruba madeira da frota; atirar fora da sua vez superaquece a
arma. O verbo do gatilho aqui é **segurar só a sua parte** — a frase do
ataque só fica inteira se cada um toca a dele (o hoqueto).

## Ler antes

- [O índice da seção](M-a-galeria.md) e a [M1](M1-a-galeria.md) (o cenário comum, o `_joga_o_minigame`)
- [O molde de minigame](molde-de-minigame.md) e o [kit](../13-arquitetura.md#o-kit-do-minigame--h04)
- [Todo minigame fecha](F03-todo-minigame-fecha.md) (o `coop` e o `coop_venceu`)

## A ficha de dados

`godot/scripts/minigames/s05/metralhadora_de_feiticos.gd`:

```gdscript
extends Minigame
## Metralhadora de Feitiços (S05_J23) — a frota no céu, os quatro no chão.
## Cada batida tem um dono; na batida dele, aperte o R2 e segure até a
## batida seguinte: a rajada treme no dedo (Vibration) em semicolcheias.
## Começo e fim no tempo derrubam a frota; atirar fora da sua vez
## superaquece a arma, que trava por um compasso.
##
## A falha: a arma superaquece — fumaça, o R2 duro como pedra por um
## compasso; a rajada que começa ou acaba fora do tempo sai torta e erra o navio.
## O vencedor: coop — a frota cai (todos vencem) ou foge aos 90 s; quem
## derrubou mais leva o destaque.
## O alto-falante do dono: a madeira que cai do navio ("coleta"); a arma que
## superaquece ("tropeco").
## O registro mede: cada Vibration mandada (posição, amplitude, frequência)
## e o curso do R2 durante a rajada; o superaquecimento é o tiro fora da vez.
## O robô: segura o R2 da batida dele até a seguinte, pelo relógio da música;
## quando não acerta, solta 250 ms tarde (e superaquece).
## Com menos de quatro: as batidas se dividem, com uma de descanso entre as
## rajadas do mesmo; a frota tem 100 de vida por jogador.
## A régua: (1) "Segure a rajada!" com a arma e a frota; (2) sim: a vez de cada
## um é fixa e o fim da rajada é o tremor que acaba; (3) não pergunta nada.

const FICHA := {
	"slot": "S05_J23",
	"titulo": "Metralhadora de Feitiços",
	"verbo": "Segure a rajada!",
	"genero": "coop",
	"icone": "r2",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S05_J23",
	"duracao": 90.0,
	"fim": "meta_coletiva",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "explosao"],
	"material": "metal",
	"microjogo": {"verbo": "Segure!", "segundos": 6.0},
	"gesto": "holding-right-shoot",
}

const DANO := [0, 1, 2, 3]  ## por julgamento, no começo e no fim da rajada
const PONTOS_POR_DANO := 10
const VIDA_POR_JOGADOR := 100
const AMPLITUDE := 6
const POSICAO := 1
## A rajada: o R2 acima disto conta como atirando.
const ATIRA := 0.5
## A trava do superaquecimento: Feedback na posição 0 com a força toda.
const TRAVA := [0, 8]
## Por parte (entrada 0-30 s, pico 30-60 s, saída 60-90 s): a chance de
## rajada na batida do dono.
const DENSIDADE := [0.5, 1.0, 0.75]
const LONGA_A_CADA := 4  ## no pico, com três ou mais, uma rajada de duas batidas a cada quatro compassos
const CANHAO_A_CADA := 4  ## no pico, o canhão da frota atira a cada quatro compassos (só o susto)
```

## Como se joga

**O dono da batida** é `presentes()` em ordem, `lista[b % k]`; o compasso 0
é a contagem; o compasso é gerado quando `Ritmo.batida() >= 4c − 4`. Entre
a soltura de uma rajada e o começo da próxima **do mesmo lugar** há pelo
menos uma batida (com um jogador, só as batidas pares; com dois, cada um tem
as suas alternadas e a regra já vale).

**A rajada** do dono na batida `b`, com a chance da parte, é um par de notas:

- o começo `{"n": int(round(b * 2)), "b": b, "t": Ritmo.t_da_batida(b), "tipo": "aperta"}`;
- o fim `{"n": int(round((b + L) * 2)) + 1, "b": b + L, "t": Ritmo.t_da_batida(b + L), "tipo": "solta"}`,

com `L = 1`; no **pico**, com três ou mais presentes, a rajada do dono na
primeira batida de todo compasso `c` com `c % LONGA_A_CADA == 0` tem `L = 2`
(ela invade a batida do próximo — que segura a dele ao mesmo tempo: dois
dedos tremendo juntos). As duas notas entram com `nova_nota` na geração.
Quem está com `Ritmo.simples[l]` fica sem rajada longa.

**O gatilho de todos**, desde o `montar`: R2 em
`Forja.gatilho(l, 1, Forja.GATILHO_VIBRACAO, POSICAO, AMPLITUDE, _frequencia())`,
com `_frequencia() = clampi(int(round(Ritmo.bpm / 60.0 * 4.0)), 1, 255)` —
as semicolcheias da faixa (a 104 bpm, 7 Hz; a 155, 10 Hz). Aperte o R2 e a
rajada treme no dedo.

**Apertar:** o R2 passando de `ATIRA` para cima casa com a nota `aperta` a
até `Ritmo.JANELA_BOM` → `julgar_toque(l, t, n)`. **Soltar:** o R2 caindo
abaixo de `CenarioDaGaleria.R2_SOLTA` casa com a nota `solta` →
`julgar_toque(l, t, n)`. Cada um grava
`Forja.evento("entrada", l + 1, {"slot": id, "o": "disparo", "n": n, "modo": "vibracao", "curso": r2, "curso_max": <o maior R2 da rajada>})`.

**O superaquecimento:** o R2 acima de `ATIRA` sem rajada dele (sem nota
`aperta` perto, ou depois da `solta` passar de `t + JANELA_BOM`) é tiro fora
da vez. A arma trava: `Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, TRAVA[0], TRAVA[1])`
até o começo do compasso seguinte ao próximo (um compasso inteiro); as
notas dele nesse intervalo somem sem erro; `Forja.sentir(l, "erro")`;
`Forja.evento("jogo", l + 1, {"slot": id, "o": "superaqueceu", "b": Ritmo.batida()})`.
Depois, o Vibration volta. (Se o fim de uma rajada passou sem soltar, é a
`nota_perdida` do kit **e** o superaquecimento.)

**A frota:** `vida_da_frota = VIDA_POR_JOGADOR * k` no `iniciar_jogo`. Cada
nota julgada tira `DANO[j]` e soma ao dano do lugar:
`marcar(l, DANO[j] * PONTOS_POR_DANO)` (o item, `Itens.pontos_do_acerto`, o kit aplica no `julgar_toque`: H08).
Vida 0: a frota cai — `coop_venceu = true`, todos `acabou`.

**Os 90 segundos:** entrada (0–30 s) chance 0,5; **pico** (30–60 s) todo
compasso, as rajadas longas e **a nau capitânia**: aos 30 s ela sobe do
fundo (os navios juntam-se num só, maior; `pulso_de_luz(Tema.ROXO)`), e a
cada `CANHAO_A_CADA` compassos o canhão dela atira — `Forja.sentir(l, "golpe")`
em todos, `tremer(TREMOR_GOLPE)`, só o susto, sem dano; saída (60–90 s)
chance 0,75.

## O cenário

- `CenarioDaGaleria.montar(self)` (o `coop` vem do gênero da FICHA: H08); a câmera um pouco mais
  alta para o céu: `camera_pos = Vector3(0, 6.8, 11.5)`, `camera_olhar = Vector3(0, 2.2, -3.0)`.
- Por lugar: `raia(l)`, `posicionar(l)`, `rotation.y = PI`, `preso = true`,
  `CenarioDaGaleria.faixa(self, l)`, e a arma na mão:
  `CenarioDaGaleria.arma_na_mao(jogador(l), CenarioDaGaleria.METRALHADORA)`,
  `animar("holding-right")`.
- **A frota** (peças do kit mais um brilho): quatro navios em
  `Vector3(RAIAS[k], 3.6, -6.0)`, cada um com o casco `Kit.peca(nav, "wood-structure", Vector3.ZERO, 0.0, 1.6)`,
  a vela `Kit.peca(nav, "banner", Vector3(0, 1.2, 0), 0.0, 1.4)` e o olho
  `Kit.caixa(nav, Vector3(0.3, 0.16, 0.08), Vector3(0, 0.5, 0.9), Kit.material(Color("#ff4a2a"), 1.8))`;
  balançam com `sin(PI * Ritmo.batida() * 0.5)` em `y` (0,15). A cada 25% de
  vida perdida, cada navio perde um pedaço (a vela cai com tween; depois o
  casco inclina).
- **A nau capitânia** (pico): `Kit.peca(self, "wood-structure", Vector3(0, 4.2, -6.4), 0.0, 3.2)`
  com duas velas e dois olhos; os navios pequenos vão para trás dela.
- **Os feitiços:** cada rajada solta, a cada semicolcheia, uma caixa
  `Kit.caixa(self, Vector3(0.12, 0.12, 0.3), ..., Kit.material(Forja.cor_do_lugar(l), 2.0))`
  que voa da arma ao navio da frente em 0,25 batida (o brilho tem dono: é a
  cor do jogador que atira).
- O checklist do 11: navios de peças do kit com o olho; nada liso nem metálico.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **gatilho (protagonista)** | R2 `GATILHO_VIBRACAO` (1, 6, semicolcheias da faixa) | sempre, menos no superaquecimento |
| gatilho | R2 `GATILHO_RESISTENCIA` (0, 8): a trava | um compasso depois do tiro fora da vez |
| vibração | `acerto` / `perfeito` / `erro` (o kit) | no começo e no fim julgados da rajada |
| vibração | `golpe` | o canhão da nau, no pico, em todos |
| vibração | `explosao` | a frota cai, em todos |
| barra de luz | o kit (`_reagir`, H08): branco no perfeito, a cor do lugar escurecida no erro | no toque julgado |
| barra de luz | laranja `Color(1.0, 0.45, 0.0)` 0,4 s | no superaquecimento; depois a cor |
| luzinhas de jogador | o número, sempre | — |
| alto-falante do dono | `Forja.som_falante(l, "coleta", 0.7)` | a rajada inteira boa (começo e fim ÓTIMO ou melhor): cai madeira do navio |
| alto-falante do dono | `Forja.som_falante(l, "tropeco", 0.7)` | no superaquecimento |
| háptica por material | `"metal"` (o kit) | — |
| som na TV | `"tiro"` baixo (−14 dB) em cada semicolcheia da rajada; `"pedra"` no navio atingido; `"golpe"` do canhão | — |

## A falha

- **A rajada torta** (começo ou fim ERRO): os feitiços daquela rajada passam
  por cima do navio e somem no fundo; o navio balança rindo (o olho pisca
  duas vezes); `jogador(l).gesto("emote-no", 0.3)`.
- **O superaquecimento:** a arma solta fumaça (`Efeitos.faiscas(self, pos_da_arma, Color("#9a9eb8"), 16, 0.5)`
  a cada batida enquanto dura), o R2 fica duro, o boneco sacode a mão
  (`gesto("emote-no", 0.5)`), laranja na barra de luz, `"tropeco"` no
  alto-falante.
- **A recuperação:** a trava dura um compasso; depois o gatilho treme de
  novo e a vez dele volta.

## O fim e o vencedor

`fim` `meta_coletiva`: a frota cai (vida 0) e o kit fecha com
`coop_venceu = true`; aos 90 s de música (H08), se ainda voa, `coop_venceu = false`
(ela foge: os navios sobem e somem). O registro grava `vencedor` −1 (coop);
o destaque é quem deu mais dano:

```gdscript
## Coop: o kit grava vencedor −1 (H08); o destaque é o artilheiro com mais dano.
func destaque() -> int:
	var lista := presentes()
	lista.sort_custom(func(a, b): return int(pontos[a]) > int(pontos[b]) or (int(pontos[a]) == int(pontos[b]) and a < b))
	return int(lista[0]) if not lista.is_empty() else -1
```

## Com menos de quatro

- **Três:** a roda do dono; as rajadas longas valem.
- **Dois:** as batidas alternadas; sem rajada longa; a frota tem 200.
- **Um:** só as batidas pares; a frota tem 100.
- **O controle que cai:** as rajadas dele somem sem erro; se caiu no meio de
  uma, ela some (sem superaquecer). A vida da frota não muda (quem ficou
  derruba o resto).

## O robô

```gdscript
# O robô aperta o R2 na batida da rajada e segura até a batida seguinte, pelo
# relógio da música. Quando não acerta, solta 250 ms tarde: é o que
# superaquece a arma. Com a arma travada (Feedback, 0x21), espera.
var _robo_nota := [-1, -1, -1, -1]
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]
var _robo_segura := [false, false, false, false]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var travada := int(Forja.percepcao(l).get("gatilho_dir", 0)) == 0x21
	if travada:
		_robo_segura[l] = false
	elif not _notas[l].is_empty():
		var nt: Dictionary = _notas[l][0]
		if int(nt.n) != _robo_nota[l]:
			_robo_nota[l] = int(nt.n)
			# o temperamento (--robo=bom|medio|ruim): quando não acerta, 250 ms tarde
			_robo_atraso[l] = 0.0 if Forja.robo_acerta() else 0.25
		var hora := float(nt.t) + (float(_robo_atraso[l]) if nt.tipo == "solta" else 0.0)
		if Ritmo.t_musica() >= hora:
			_robo_segura[l] = nt.tipo == "aperta"
	Forja.robo_eixo(l, Forja.R2, 1.0 if _robo_segura[l] else 0.0, 0.06)
```

## Os ganchos

```gdscript
var _notas := [[], [], [], []]
var _ultima := [{}, {}, {}, {}]
var _gerado := 1
var _fora := [false, false, false, false]
var _atirando := [false, false, false, false]
var _travada_ate := [-1.0, -1.0, -1.0, -1.0]  ## a batida em que a trava acaba
var _j_aperta := [0, 0, 0, 0]
var vida_da_frota := 0
var _livre_em := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	camera_pos = Vector3(0, 6.8, 11.5)
	camera_olhar = Vector3(0, 2.2, -3.0)
	CenarioDaGaleria.montar(self)
	_montar_a_frota()
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.rotation.y = PI
		p.preso = true
		CenarioDaGaleria.faixa(self, l)
		CenarioDaGaleria.arma_na_mao(p, CenarioDaGaleria.METRALHADORA)


func iniciar_jogo() -> void:
	vida_da_frota = VIDA_POR_JOGADOR * maxi(presentes().size(), 1)
	coop_venceu = false
	for l in presentes():
		_armar(l)


func jogar(_dt: float) -> void:
	while _gerado <= int(floor(Ritmo.batida() / 4.0)) + 1:
		_gerar_compasso(_gerado)
		_gerado += 1
	var agora := Ritmo.t_musica()
	for l in presentes():
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_notas[l] = _notas[l].filter(func(nt): return nt.tipo == "aperta" and float(nt.t) > agora)
		if _travada_ate[l] >= 0.0 and Ritmo.batida() >= _travada_ate[l]:
			_travada_ate[l] = -1.0
			_armar(l)
		var r2 := Forja.eixo(l, Forja.R2)
		if not _atirando[l] and r2 >= ATIRA:
			_atirando[l] = true
			_apertou(l, r2)  # julga o começo, ou superaquece (sem rajada dele)
		elif _atirando[l] and r2 <= CenarioDaGaleria.R2_SOLTA:
			_atirando[l] = false
			_soltou(l, r2)  # julga o fim
		while not _notas[l].is_empty() and agora > float(_notas[l][0].t) + FOLGA_PERDIDA:
			var nt: Dictionary = _notas[l].pop_front()
			_ultima[l] = nt
			nota_perdida(l, int(nt.n))
			if nt.tipo == "solta" and _atirando[l]:
				_superaquecer(l)
		_feiticos(l)  # uma caixa por semicolcheia enquanto atira, pela batida
	_mover_a_frota()
	if vida_da_frota <= 0 and not coop_venceu:
		_a_frota_cai()  # coop_venceu = true, explosao em todos, todos acabou


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	vida_da_frota = maxi(0, vida_da_frota - DANO[julgamento])
	marcar(l, DANO[julgamento] * PONTOS_POR_DANO)  # o item, o kit já aplicou (H08)
	if nt.tipo == "aperta":
		_j_aperta[l] = julgamento
		return
	if _j_aperta[l] >= Ritmo.OTIMO and julgamento >= Ritmo.OTIMO:
		Forja.som_falante(l, "coleta", 0.7)
		_arrancar_um_pedaco(l)


func falha(l: int) -> void:
	_rajada_torta(l)


## O gatilho de sempre: a rajada que treme em semicolcheias.
func _armar(l: int) -> void:
	Forja.gatilho(l, 1, Forja.GATILHO_VIBRACAO, POSICAO, AMPLITUDE, clampi(int(round(Ritmo.bpm / 60.0 * 4.0)), 1, 255))
```

(Com `var _volta_da_luz := [0.0, 0.0, 0.0, 0.0]` descontado por `dt`, e o
`Forja.luz_do_lugar(l)` ao chegar a 0: só para o laranja do superaquecimento,
que não é julgamento; o branco do perfeito é do kit, H08.) `_superaquecer(l)`:
`_travada_ate[l] = (floor(Ritmo.batida() / 4.0) + 2.0) * 4.0`, a trava no
R2, o laranja, `"tropeco"`, o evento, e tira da lista as notas dele com
`b < _travada_ate[l]` (sem erro). `_apertou(l, r2)` sem nota `aperta` a até
`JANELA_BOM` → `_superaquecer(l)`.

Catálogo: `"S05_J23"` em `MINIGAMES` e na lista da seção `S05`. O `.uid`.
Traduções: `"Metralhadora de Feitiços": "Spell Gatling"`,
`"Segure a rajada!": "Hold the burst!"`, `"Segure!": "Hold!"`; `dica(l)`:
`{"partes": ["@r2", "Segure a sua vez"], ...}` com `na_raia(l)` e
`not aprendeu(l)` (`"Segure a sua vez": "Hold your beat"`).

## O que o registro mede

- A `saida` de gatilho: o Vibration (`params` = `[1, 6, <Hz>]`) e a trava
  (Feedback `[0, 8]`), com `seq` e `ok`.
- `entrada` `disparo` no começo e no fim da rajada (curso, curso máximo), o
  `toque` do kit e `jogo` `superaqueceu`. O cruzamento: a rajada solta no
  tempo com o Vibration `ok` é o tremor que chegou (o dedo conta as quatro
  semicolcheias); o mesmo lugar sempre segurando demais é o tremor que não
  chegou.

## Armadilhas

- **O Vibration fica ligado o tempo todo** (é a arma): mande de novo só na
  volta da trava e no começo. A frequência vem do `Ritmo.bpm` do minigame.
- **A rajada longa só com três ou mais:** com dois, ela bateria na próxima
  vez do mesmo dono.
- **A trava apaga as notas sem erro** — é a falha dela, não duas falhas.
- **O R2 é do minigame, o L2 do item** (G03).
- **Os pontos e o item:** o kit aplica `Itens.pontos_do_acerto` no `julgar_toque`
  (H08); marque cru.
- **Poupar as mãos** ([10](../10-a-regua-astro-bot.md), lição 15): 90 s de
  rajada cansam; a chance 0,5 da entrada e as batidas dos outros são o descanso.

## Pronto quando

A Metralhadora de Feitiços joga do aviso ao resultado com 4, 3, 2 e 1
jogador e com o robô nos três temperamentos (o bom derruba a frota, o ruim
superaquece e a frota foge); aguenta o cabo que cai no meio de uma rajada;
fecha com o resultado coop e o destaque; a prova do jogo passa; e
`bash tests/prova_visual.sh` passa com a **prancha olhada** com a
Metralhadora nela (o `Catalogo.sortear` da H08 põe o `S05_J23` na noite: rode a prova visual com a semente que o sorteia, `--semente=N`).

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, depois das outras da seção:

```gdscript
## Metralhadora de Feitiços (S05_J23): o Vibration chegou ao R2 na frequência
## das semicolcheias; é coop; a vida da frota só desce.
func _prova_da_metralhadora() -> void:
	var vibrou := [false]
	var vidas: Array = []
	var olhar := func(m: Minigame) -> void:
		for l in m.presentes():
			if int(Forja.percepcao(l).get("gatilho_dir", 0)) == 0x26:
				vibrou[0] = true
		vidas.append(int(m.vida_da_frota))
	var mg = await _joga_o_minigame("S05_J23", 130.0, olhar)
	if mg == null:
		return
	_esperar(mg.coop and mg.destaque() >= 0, "Metralhadora: é coop, com o destaque")
	_esperar(vibrou[0], "Metralhadora: o Vibration chegou ao R2")
	var subiu := false
	for i in range(1, vidas.size()):
		if vidas[i] > vidas[i - 1] and vidas[i - 1] > 0:
			subiu = true
	_esperar(not subiu, "Metralhadora: a vida da frota nunca sobe")
	var hz := clampi(int(round(Ritmo.bpm / 60.0 * 4.0)), 1, 255)
	var vib := _linha_do_tempo().filter(func(e): return e.get("tipo") == "saida" and e.get("o") == "gatilho" and e.get("modo") == "vibracao")
	_esperar(not vib.is_empty() and int(vib[0].get("params", [0, 0, 0])[2]) > 0, "Metralhadora: o Vibration com frequência (%s; a faixa pede %d Hz)" % [vib[0].get("params") if not vib.is_empty() else "nenhum", hz])
```

**O que o André joga e sente** (`./run-local.sh -- --sala=S05_J23`):

- o tremor do R2 é uma rajada em semicolcheias, no andamento da faixa;
- a frase do ataque passa de mão em mão e soa inteira quando todos acertam;
- a trava do superaquecimento é dura de verdade e dura um compasso;
- a nau do meio e o canhão dão o pico; a frota caindo é festa.

## Ao terminar

- No [quadro](README.md): a linha **M3** (se não existir, acrescente
  `| [M3](M3-metralhadora-de-feiticos.md) | M | S5 — Metralhadora de Feitiços | M | — | 1,5 | feito (<commit>) | <gasto> |`),
  com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: Metralhadora de Feitiços — a rajada dividida, o tremor no dedo`
