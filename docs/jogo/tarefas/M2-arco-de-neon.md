# M2 — Arco de Néon

**Sprint:** M · **Slot:** S05_J22 · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 1,5 · **Depende de:** H04, H08, F09, M1

## Por quê

O arco é o gatilho que resiste: puxar custa, segurar custa mais, e a nota
longa diz quanto tempo aguentar. É o verbo **sustentar e soltar** — o
contrário da pistola da M1, em que o tempo é o do clique. Aqui o tempo está
no fim da nota: soltar cedo derruba a flecha aos pés; soltar no fim dela
acerta o alvo de néon.

## Ler antes

- [O índice da seção](M-a-galeria.md) e a [M1](M1-a-galeria.md) (o cenário comum, o `_joga_o_minigame`)
- [O molde de minigame](molde-de-minigame.md) e o [kit](../13-arquitetura.md#o-kit-do-minigame--h04)

## A ficha de dados

`godot/scripts/minigames/s05/arco_de_neon.gd`:

```gdscript
extends Minigame
## Arco de Néon (S05_J22) — cada flecha é uma nota longa. Na batida do dono,
## puxe o R2 (o arco resiste: Feedback); segure até o fim da nota — o arco
## endurece a cada batida — e solte no fim dela. A flecha acerta o alvo de
## néon do seu muro. No pico, puxar até o fundo acende a flecha de fogo.
##
## A falha: soltar cedo ou tarde — a flecha cai aos pés; puxar fora do tempo —
## a corda escapa e a flecha nem sai.
## O vencedor: mais alvos; no empate, mais pontos.
## O alto-falante do dono: a corda que range ao puxar ("clique"); a flecha
## no alvo ("coleta").
## O registro mede: cada Feedback mandado (posição, força, seq) e o curso do
## R2 durante a nota: quem solta cedo sempre num controle é o peso que não chegou.
## O robô: puxa na batida, segura (até o fundo no pico) e solta no fim da
## nota, pelo relógio da música; quando não acerta, solta 250 ms tarde.
## Com menos de quatro: as batidas se dividem; ninguém puxa antes de uma
## batida de descanso depois da última soltura.
## A régua: (1) "Puxe e solte!" com o arco na mão; (2) quase: o peso diz
## quanto falta, a tela diz quando começa; (3) não pergunta nada.

const FICHA := {
	"slot": "S05_J22",
	"titulo": "Arco de Néon",
	"verbo": "Puxe e solte!",
	"genero": "tct",
	"icone": "gatilho_adaptativo",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S05_J22",
	"duracao": 80.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "toque"],
	"material": "madeira",
	"microjogo": {"verbo": "Solte!", "segundos": 6.0},
	"gesto": "holding-right",
}

const PONTOS := [0, 20, 35, 50]  ## por julgamento, na puxada e na soltura (a flecha vale a soma)
const FOGO := 50  ## a flecha de fogo (no pico, puxada até o fundo)
const FUNDO := 0.9
const SEGURA := 0.35  ## abaixo disto, no meio da nota, a corda afrouxa (vale como soltura)
## A força do arco: parado, ao puxar, a cada batida segurando (até 8).
const FORCA_PARADO := 2
const FORCA_PUXADA := 4
const FORCA_POR_BATIDA := 2
## Por parte (entrada 0-27 s, pico 27-54 s, saída 54-80 s): a chance de
## flecha na batida do dono e o comprimento da nota, em batidas.
const DENSIDADE := [0.5, 1.0, 0.8]
const COMPRIMENTO := [[2.0], [2.0], [1.0, 2.0]]
```

## Como se joga

**O dono da batida** é `presentes()` em ordem, `lista[b % k]`. O compasso 0
é a contagem; o compasso é gerado quando `Ritmo.batida() >= 4c − 4`. **Uma
flecha nova só nasce** se a última soltura daquele lugar é pelo menos uma
batida antes (`b >= _livre_em[l]`, com `_livre_em = soltura + 1`): com dois
ou um jogador, parte das batidas dele fica vazia.

**A flecha** do dono na batida `b`, com a chance da parte e o comprimento
`L` sorteado entre os de `COMPRIMENTO[parte]` (quem está com
`Ritmo.simples[l]` fica sempre com `L = 2` e sem fogo):

- a nota da puxada: `{"n": int(round(b * 2)), "b": b, "t": Ritmo.t_da_batida(b), "tipo": "puxa", "L": L}`,
  com `nova_nota` na geração;
- a nota da soltura: `{"n": int(round((b + L) * 2)) + 1, "b": b + L, "t": Ritmo.t_da_batida(b + L), "tipo": "solta"}`,
  com `nova_nota` **só quando a puxada foi boa** (BOM ou melhor).

**O alvo de néon acende** no muro do lugar uma batida antes da puxada (a
borda de 8 lados liga o emissivo `Tema.CIANO` 2,0), e apaga ao acertar ou
cair a flecha.

**Puxar:** o R2 passando de `CenarioDaGaleria.R2_APERTA` (0,5) para cima
casa com a nota `puxa` a até `Ritmo.JANELA_BOM` → `julgar_toque(l, t, n)`.
Boa: `Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, FORCA_PUXADA)`, a
corda estica, a nota `solta` nasce. ERRO: a corda escapa (a falha) e a
flecha acaba ali.

**Segurar:** a cada batida inteira depois da puxada, a força sobe
`FORCA_POR_BATIDA` (até 8): `Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, mini(8, FORCA_PUXADA + FORCA_POR_BATIDA * batidas))`.
O arco endurece: o dedo conta a nota longa.

**Soltar:** o R2 caindo abaixo de `CenarioDaGaleria.R2_SOLTA` (0,2) — ou
abaixo de `SEGURA` (0,35) no meio da nota — casa com a nota `solta` →
`julgar_toque(l, t, n)` (cedo demais é ERRO pelo próprio julgamento). A
nota `solta` que passa de `t + FOLGA_PERDIDA` (o kit) com o R2 ainda puxado é
`nota_perdida(l, n)` (o braço cansou). Depois da soltura, o arco volta a
`(2, FORCA_PARADO)`.

**A flecha** voa em 0,25 batida (tween pela batida) e acerta o alvo:
`marcar(l, PONTOS[j_puxa] + PONTOS[j_solta] + (FOGO if fogo else 0))` (o item, `Itens.pontos_do_acerto`, o kit aplica no `julgar_toque`: H08)
e `alvos[l] += 1`. **Fogo:** no pico, se o maior R2 entre a puxada e a
soltura passou de `FUNDO` (0,9), a flecha sai em chamas (o rastro laranja
e `Efeitos.faiscas` `Tema.LARANJA`).

Cada puxada e cada soltura gravam
`anotar("entrada", l, {"o": "disparo", "n": n, "modo": "resistencia", "curso": r2, "curso_max": <o maior R2 da nota>})`.

**Os 80 segundos:** entrada (0–27 s) chance 0,5, notas de 2 batidas; **pico**
(27–54 s) toda batida do dono livre tem flecha, e a de fogo vale (aos 27 s
os alvos ganham um anel `Tema.ROSA` e `pulso_de_luz(Tema.ROSA)`); saída
(54–80 s) chance 0,8 e notas de 1 ou 2 batidas misturadas — o dedo tem de
ler o comprimento pelo peso.

## O cenário

- `CenarioDaGaleria.montar(self)`; a câmera d'A Galeria.
- Por lugar: `raia(l)`, `posicionar(l)`, `rotation.y = PI`, `preso = true`,
  `CenarioDaGaleria.faixa(self, l)`, e o arco na mão:
  `CenarioDaGaleria.arma_na_mao(jogador(l), CenarioDaGaleria.ARCO)`,
  `animar("holding-right")`.
- **O alvo de néon:** `CenarioDaGaleria.alvo(self)` em
  `CenarioDaGaleria.no_muro(l, Vector2(0.5, 0.45))`, com a borda
  `Kit.anel(self, 0.46, 0.52, pos + Vector3(0, 0, 0.03), mat_neon)` —
  `mat_neon = Kit.material(Tema.CIANO, 0.0)`, o emissivo liga só na vez.
- **A corda esticando:** o arco na mão se inclina para trás com o R2
  (`rotation.z` de 0 a −0,4 por `Forja.eixo(l, Forja.R2)`), e a flecha
  (`Kit.caixa(Vector3(0.6, 0.04, 0.04))` de madeira com a ponta
  `Kit.caixa(Vector3(0.08, 0.08, 0.08))` `Tema.CIANO` emissiva) aparece
  presa ao arco enquanto a nota dura.
- O checklist do 11: arco em blocos (o de hoje), alvo e anel de 8 lados, o
  emissivo só no néon da vez e na ponta da flecha.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **gatilho (protagonista)** | R2 `GATILHO_RESISTENCIA` (2, 4) na puxada, +2 por batida até 8 | durante a nota longa |
| gatilho | R2 `GATILHO_RESISTENCIA` (2, 2): o arco parado | fora da nota, e ao começar |
| vibração | `acerto` / `perfeito` / `erro` (o kit) | na puxada e na soltura julgadas |
| vibração | `toque` | a flecha no alvo |
| barra de luz | o kit (`_reagir`, H08): branco no perfeito, a cor do lugar escurecida no erro | no toque julgado |
| luzinhas de jogador | o número, sempre | — |
| alto-falante do dono | `Forja.som_falante(l, "clique", 0.5)` | na puxada BOM ou ÓTIMO (no perfeito, o kit toca a nota) |
| alto-falante do dono | `Forja.som_falante(l, "coleta", 0.7)` | a flecha no alvo (0,25 batida depois da soltura) |
| háptica por material | `"madeira"` (o kit) | — |
| som na TV | `"alvo"` no acerto; `"tique"` na flecha que cai | — |

## A falha

- **A corda escapa** (puxada ERRO): o arco estala para a frente
  (`rotation.z` a +0,3 e volta), `Som.tocar("tique", pos, -6.0)`, nenhuma
  flecha; `jogador(l).gesto("emote-no", 0.3)`.
- **A flecha cai aos pés** (soltura ERRO ou perdida): a flecha sai com
  força nenhuma e cai no chão na frente do boneco (tween para
  `pos + Vector3(0, -0.9, -0.6)` com `rotation.x` a −1,2), fica uma batida
  e some; o alvo apaga.
- **A recuperação:** a próxima flecha do lugar é na próxima batida livre dele.

## O fim e o vencedor

80 s de música, pelo kit (H08). `vencedor()`: por `alvos` e, no empate, por
`pontos` (o mesmo código da M1, com `alvos`).

## Com menos de quatro

- **Três e dois:** a roda do dono, com a batida de descanso; com dois, cada
  um puxa no máximo uma flecha a cada quatro batidas (dois tempos segurando,
  um de descanso).
- **Um:** todas as batidas são dele, com o mesmo descanso.
- **O controle que cai:** as notas dele somem sem erro; se caiu no meio de
  uma nota longa, ela some e o arco dele volta a `(2, FORCA_PARADO)` quando
  voltar.

## O robô

```gdscript
# O robô puxa o R2 na batida da puxada e segura até a soltura, pelo relógio
# da música (no pico, até o fundo). Quando não acerta, solta 250 ms tarde.
var _robo_nota := [-1, -1, -1, -1]
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]
var _robo_segura := [false, false, false, false]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	if not _notas[l].is_empty():
		var nt: Dictionary = _notas[l][0]
		if int(nt.n) != _robo_nota[l]:
			_robo_nota[l] = int(nt.n)
			# o temperamento (--robo=bom|medio|ruim): quando não acerta, 250 ms tarde
			_robo_atraso[l] = 0.0 if Forja.robo_acerta() else 0.25
		var hora := float(nt.t) + (float(_robo_atraso[l]) if nt.tipo == "solta" else 0.0)
		if Ritmo.t_musica() >= hora:
			_robo_segura[l] = nt.tipo == "puxa"
	var v := 0.0
	if _robo_segura[l]:
		v = 1.0 if _parte() == 1 else 0.8
	Forja.robo_eixo(l, Forja.R2, v, 0.06)
```

(Quando a puxada é julgada, a nota `solta` entra na lista e o robô segura
até a hora dela; quando a soltura é julgada, a lista fica com a próxima
`puxa` e ele continua solto até lá.)

## Os ganchos

```gdscript
var _notas := [[], [], [], []]  ## em ordem de tempo; a de agora é a primeira
var _ultima := [{}, {}, {}, {}]
var _gerado := 1
var _fora := [false, false, false, false]
var _puxado := [false, false, false, false]  ## o R2 passou de R2_APERTA e ainda não caiu
var _livre_em := [0.0, 0.0, 0.0, 0.0]
var _j_puxa := [0, 0, 0, 0]
var _maior := [0.0, 0.0, 0.0, 0.0]  ## o maior R2 da nota
var _forca := [0, 0, 0, 0]  ## a força mandada ao R2
var alvos := [0, 0, 0, 0]


func montar() -> void:
	camera_pos = Vector3(0, 7.5, 11.0)
	camera_olhar = Vector3(0, 0.2, -2.2)
	CenarioDaGaleria.montar(self)
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.rotation.y = PI
		p.preso = true
		_montar_a_raia(l, p)  # faixa, arco na mão, alvo de néon, flecha
		_arco(l, FORCA_PARADO)


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
			_notas[l] = _notas[l].filter(func(nt): return nt.tipo == "puxa" and float(nt.t) > agora)
			_arco(l, FORCA_PARADO)
		var r2 := Forja.eixo(l, Forja.R2)
		_maior[l] = maxf(float(_maior[l]), r2)
		if not _puxado[l] and r2 >= CenarioDaGaleria.R2_APERTA:
			_puxado[l] = true
			_puxar(l, r2)
		elif _puxado[l] and (r2 <= CenarioDaGaleria.R2_SOLTA or (r2 <= SEGURA and _segurando(l))):
			_puxado[l] = false
			_soltar(l, r2)
		_endurecer(l)  # a força pela batida desde a puxada
		while not _notas[l].is_empty() and agora > float(_notas[l][0].t) + FOLGA_PERDIDA:
			var nt: Dictionary = _notas[l].pop_front()
			_ultima[l] = nt
			nota_perdida(l, int(nt.n))
		_mostrar(l)


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	if nt.tipo == "puxa":
		_j_puxa[l] = julgamento
		_maior[l] = 0.0
		_arco(l, FORCA_PUXADA)
		_nascer_a_soltura(l, nt)
		if julgamento != Ritmo.PERFEITO:
			Forja.som_falante(l, "clique", 0.5)
		return
	var fogo := _parte() == 1 and float(_maior[l]) >= FUNDO and not Ritmo.simples[l]
	marcar(l, PONTOS[_j_puxa[l]] + PONTOS[julgamento] + (FOGO if fogo else 0))  # o item, o kit já aplicou (H08)
	alvos[l] += 1
	_arco(l, FORCA_PARADO)
	_livre_em[l] = float(nt.b) + 1.0
	_voar(l, fogo)  # a flecha, o alvo, "coleta" no alto-falante ao chegar (a barra de luz é do kit)


func falha(l: int) -> void:
	var nt: Dictionary = _ultima[l]
	_arco(l, FORCA_PARADO)
	if nt.get("tipo", "") == "puxa":
		_corda_escapa(l)
		_livre_em[l] = float(nt.b) + 1.0
	else:
		_flecha_cai(l)
		_livre_em[l] = float(nt.b) + 1.0


## O arco: a força no R2, mandada só quando muda.
func _arco(l: int, forca: int) -> void:
	if _forca[l] != forca:
		_forca[l] = forca
		Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, forca)
```

`_puxar(l, r2)` e `_soltar(l, r2)` acham a nota do tipo certo a até
`JANELA_BOM`, gravam o `disparo`, põem a nota em `_ultima[l]`, tiram-na da
lista e chamam `julgar_toque`; puxada sem nota perto não faz nada (o arco
tensiona à toa); soltura sem nota perto também não. `_segurando(l)`: há uma
nota `solta` na lista (a nota longa está correndo). `_parte()`: 0, 1 ou 2
pelo `andamento()` do kit (um terço e dois terços da duração, em tempo de música: H08).

Catálogo: `"S05_J22"` em `MINIGAMES` e na lista da seção `S05`. O `.uid`.
Traduções: `"Arco de Néon": "Neon Bow"`, `"Puxe e solte!": "Draw and release!"`,
`"Solte!": "Release!"`; `dica(l)`: `{"partes": ["@r2", "Puxe e solte"], ...}`
com `na_raia(l)` e `not aprendeu(l)` (`"Puxe e solte": "Draw and release"`).

## O que o registro mede

- A `saida` de gatilho: cada Feedback (posição 2, força 2 a 8, `seq`, `ok`).
- `entrada` `disparo` na puxada e na soltura (curso e curso máximo) e o `toque`
  do kit. O cruzamento: com o Feedback mandado e `ok`, as solturas no tempo
  dizem que o peso chegou; o mesmo lugar soltando cedo, sempre, com o curso
  máximo baixo, é o arco que não resistiu.

## Armadilhas

- **A nota de soltura só nasce com a puxada boa:** senão uma puxada ERRO
  viraria duas notas erradas no registro.
- **Soltar cedo é o julgamento que diz:** não trate a soltura antecipada à
  parte; o `julgar_toque` com o tempo da nota `solta` já dá ERRO.
- **A força só sobe, e só durante a nota;** mande o Feedback só quando
  muda (`_arco`), senão a `saida` inunda o registro.
- **O L2 é do item:** o arco é só o R2.
- **Os pontos e o item:** o kit aplica `Itens.pontos_do_acerto` no `julgar_toque`
  (H08); marque cru.

## Pronto quando

O Arco de Néon joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o
robô nos três temperamentos; aguenta o cabo que cai no meio de uma nota
longa; fecha com vencedor; a prova do jogo passa; e `bash tests/prova_visual.sh`
passa com a **prancha olhada** com o Arco nela (o `Catalogo.sortear` da H08 põe o `S05_J22` na noite: rode a prova visual com a semente que o sorteia, `--semente=N`).

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, depois da prova da Galeria:

```gdscript
## Arco de Néon (S05_J22): o Feedback chegou ao R2 e a força subiu durante a
## nota; o registro tem puxada e soltura.
func _prova_do_arco() -> void:
	var feedback := [false]
	var olhar := func(m: Minigame) -> void:
		for l in m.presentes():
			if int(Forja.percepcao(l).get("gatilho_dir", 0)) == 0x21:
				feedback[0] = true
	var mg = await _joga_o_minigame("S05_J22", 120.0, olhar)
	if mg == null:
		return
	_esperar(feedback[0], "Arco: o Feedback chegou ao R2")
	var forcas := {}
	for e in _linha_do_tempo():
		if e.get("tipo") == "saida" and e.get("o") == "gatilho" and e.get("lado") == "R2" and e.get("modo") == "resistencia":
			forcas[str(e.get("params", []))] = true
	_esperar(forcas.size() >= 2, "Arco: a força do arco mudou durante o jogo (%s)" % [forcas.keys()])
	var disparos := _linha_do_tempo().filter(func(e): return e.get("tipo") == "entrada" and e.get("slot") == "S05_J22" and e.get("o") == "disparo")
	_esperar(disparos.size() >= 2, "Arco: %d puxadas e solturas no registro" % disparos.size())
```

(A linha `saida` do gatilho tem `lado` (`"R2"`), `modo` (`"resistencia"`…)
e `params` (`[a, b, c]`), como grava `nativo/nucleo/pads.c` hoje.)

**O que o André joga e sente** (`./run-local.sh -- --sala=S05_J22`):

- o arco endurece a cada batida e o dedo sente o fim da nota chegando;
- soltar no fim é natural; soltar cedo derruba a flecha aos pés (e todo mundo ri);
- no pico, puxar até o fundo contra o peso vale o fogo;
- na saída, notas curtas e longas misturadas pedem atenção ao peso.

## Ao terminar

- No [quadro](README.md): a linha **M2** (se não existir, acrescente
  `| [M2](M2-arco-de-neon.md) | M | S5 — Arco de Néon | M | Sonnet | 1,5 | feito (<commit>) | <gasto> |`),
  com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: Arco de Néon — a nota longa no peso do gatilho`
