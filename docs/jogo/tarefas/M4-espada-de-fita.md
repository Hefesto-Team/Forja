# M4 — Espada de Fita

**Sprint:** M · **Slot:** S05_J24 · **Tamanho:** M · **Estimativa:** US$ 1,5 · **Depende de:** H04, H08, F09, M1

## Por quê

O duelo em dupla da seção. A espada é uma fita K7 esticada: a cada batida
ela estica mais e o R2 pesa um degrau a mais — **o peso é o relógio**. No
pico do peso, solte: a fita estala e corta. A dupla que soltou mais no
ponto corta a outra. Diferente do arco (M2), em que a nota longa manda e o
peso acompanha, aqui é o peso que conta o tempo: dá para jogar de olhos
fechados, só pelo dedo.

## Ler antes

- [O índice da seção](M-a-galeria.md) e a [M1](M1-a-galeria.md) (o cenário comum, as cores das duplas, o `_joga_o_minigame`)
- [O molde de minigame](molde-de-minigame.md) (o `2v2` com três ou menos) e o [kit](../13-arquitetura.md#o-kit-do-minigame--h04)
- [Os princípios](../02-principios.md#3-uma-nota-por-jogador) (a dupla divide um acorde)

## A ficha de dados

`godot/scripts/minigames/s05/espada_de_fita.gd`:

```gdscript
extends Minigame
## Espada de Fita (S05_J24) — duas duplas frente a frente. A cada compasso,
## todos puxam o R2 no primeiro tempo; a fita estica e o R2 pesa um degrau a
## cada batida (Feedback); no quarto tempo — o pico — soltem. A dupla que
## puxou e soltou mais no ponto corta a outra. Três cortes ganham a rodada;
## duas rodadas ganham o duelo.
##
## A falha: soltar fora do pico — a fita afrouxa e a espada balança mole;
## puxar fora do tempo — a fita não pega.
## O vencedor: a dupla que ganhou mais rodadas (e, dentro dela, mais pontos);
## depois a outra.
## O alto-falante do dono: o corte que acertou ("coleta"); o corte que levou ("golpe").
## O registro mede: cada degrau do Feedback mandado (força 3, 5, 7, 8) e o
## curso do R2 na soltura: soltar no pico sem ver a tela é o peso que chegou.
## O robô: puxa no primeiro tempo, segura e solta no quarto, pelo relógio da
## música; quando não acerta, solta 250 ms tarde.
## Com menos de quatro: 2 contra 1 (o sozinho vale dobrado), 1 contra 1, e 1
## contra o espantalho.
## A régua: (1) "Solte no pico!" com a fita esticando; (2) sim: o peso conta
## as batidas até o pico; (3) não pergunta nada.

const FICHA := {
	"slot": "S05_J24",
	"titulo": "Espada de Fita",
	"verbo": "Solte no pico!",
	"genero": "2v2",
	"icone": "gatilho_adaptativo",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S05_J24",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "metal",
	"microjogo": {"verbo": "Solte!", "segundos": 6.0},
	"gesto": "attack-melee-right",
}

const PONTOS := [0, 40, 70, 100]  ## o placar de cada um: puxada e soltura
const VALOR := [0, 1, 2, 3]  ## o que cada nota vale para a dupla no compasso
const ACORDE := 2  ## os dois da dupla soltaram perfeito: o acorde fecha
const SOZINHO := 2  ## a dupla de um só vale dobrado
const ESPANTALHO := 8  ## com um jogador, o valor fixo do espantalho por estocada
const ACERTO_APRENDIZ := 0.8  ## com três jogadores, o Aprendiz na Maré (Q-a-prova.md)
const CORTES_POR_RODADA := 3
const RODADAS_PARA_GANHAR := 2
## O peso da fita: a força do Feedback em cada batida desde a puxada (posição 2).
const PESO := [3, 5, 7, 8]
const PESO_PARADO := 1
```

## Como se joga

**As duplas** são as equipes do [13](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08):
a dupla 0 é **A Brasa** (âmbar), a 1 **A Maré** (turquesa). `lista =
presentes()` em ordem; a Brasa é a primeira metade (`lista.slice(0, (k + 1) / 2)`),
a Maré a segunda. Com quatro: P1+P2 contra P3+P4; com três: os dois
primeiros contra o terceiro **e o Aprendiz** (a regra de
[Q](Q-a-prova.md#o-cenário-comum): um boneco do jogo, não um lugar nem um
robô, que puxa e solta com a dupla e acerta `ACERTO_APRENDIZ` (0,8) das
vezes, sempre BOM, sorteado com o `rng` do kit); com dois: um contra um; com
um: ele contra o espantalho. A Brasa fica nas raias da esquerda olhando para
a direita, a Maré nas da direita olhando para a esquerda. **A cor da equipe
está no mundo** (a bandeira atrás, o chão da raia e a armadura):
`CenarioDaGaleria.EQUIPE[d]`; a barra de luz continua a cor do lugar. Os
pontos da equipe vão para os dois da dupla, e a tela diz "A Brasa venceu!"
ou "A Maré venceu!" (H08).

**A estocada** (todos juntos: a dupla divide o acorde, cada um com a sua
nota): no compasso `c` (a partir de 1, fora das pausas entre rodadas),
para cada presente:

| parte | música (`andamento()` do kit) | a puxada | a soltura (o pico) | o peso (Feedback posição 2) |
| --- | --- | --- | --- | --- |
| entrada | 0–30 s | `4c` | `4c + 3` | `PESO[0..3]` em `4c`, `4c+1`, `4c+2`, `4c+2,5` |
| **pico** | 30–60 s | `4c` e `4c + 2` | `4c + 1,5` e `4c + 3,5` (duas estocadas curtas) | `4` na puxada, `8` meia batida depois |
| saída | 60–90 s | como na entrada | como na entrada | como na entrada |

Cada estocada é um par de notas por lugar:
`{"n": int(round(b * 2)), "b": b, "t": Ritmo.t_da_batida(b), "tipo": "puxa", "e": <a estocada>}`
e `{"n": int(round(b_solta * 2)) + 1, ..., "tipo": "solta", "e": ...}`, as
duas com `nova_nota` na geração. Quem está com `Ritmo.simples[l]` fica com
a estocada da entrada também no pico.

**Puxar:** o R2 passando de `CenarioDaGaleria.R2_APERTA` casa com a `puxa` a
até `JANELA_BOM` → `julgar_toque`. Boa: a fita pega e o peso começa
(`Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, PESO[0])`, e o degrau
seguinte em cada batida pela tabela). ERRO: a fita não pega — a `solta`
daquela estocada sai da lista sem erro e vale 0.

**Soltar no pico:** o R2 caindo abaixo de `CenarioDaGaleria.R2_SOLTA` casa
com a `solta` a até `JANELA_BOM` → `julgar_toque`. A `solta` que passa de
`t + JANELA_BOM` com o R2 puxado é `nota_perdida`. Depois da soltura, o R2
volta a `(2, PESO_PARADO)`.

**O corte:** quando todas as `solta` da estocada estão resolvidas (ou a
batida passou de `b_solta + 0,5`), cada dupla soma
`VALOR[j_puxa] + VALOR[j_solta]` de cada membro, `+ ACORDE` se os dois
soltaram perfeito (o Aprendiz entra com `VALOR[BOM]` nas notas que acerta),
`× SOZINHO` se a dupla tem um só sem o Aprendiz (com um jogador, o
espantalho vale `ESPANTALHO`). A maior corta a outra: `cortes[d] += 1`; no
empate, as espadas batem e ninguém corta (faíscas no meio). Três cortes →
`rodadas[d] += 1`, um compasso de pausa (sem notas), as fitas voltam.
Duas rodadas → todos `acabou`.

**Os pontos** vão para os dois da dupla: `marcar_equipe(equipe[l], PONTOS[julgamento])` (o kit, H08, que também aplica o item)
em cada nota boa.

Cada puxada e soltura gravam o `entrada` `disparo` (modo `"resistencia"`,
curso, curso máximo); cada corte grava
`anotar("jogo", -1, {"o": "corte", "dupla": d, "valores": "%d,%d" % [v0, v1]})`.

## O cenário

- `CenarioDaGaleria.montar(self)`; a câmera d'A Galeria, mais perto do
  meio: `camera_pos = Vector3(0, 6.6, 10.4)`, `camera_olhar = Vector3(0, 1.0, -0.6)`.
- Por lugar: `raia(l)`, `posicionar(l)`, `preso = true`, virado para o meio
  (`rotation.y = PI * 0.5` na dupla 0, `-PI * 0.5` na dupla 1), a espada
  `Kit.peca` `"weapon-sword"` na mão direita (um `BoneAttachment3D` em
  `arm-right`, como a arma da M1).
- **A fita:** de cada espada sai uma fita `Kit.caixa(self, Vector3(0.04, 0.12, 1.0), ..., Kit.material(Color("#3a2a24"), 0.0, 0.9))`
  até um carretel atrás do boneco (`Kit.cilindro(self, 0.2, 0.12, ..., Kit.material(Color("#4a4e5e"), 0.0, 0.6))`,
  deitado); o comprimento (`scale.z`) cresce de 1,0 a 2,2 com o peso.
- **As bandeiras das duplas:** `Kit.peca(self, "banner", Vector3(-8.5, 0, Z_JOGADOR - 1.0), 0.0, 2.0)`
  e em `8.5`, cada uma com o pano tingido por `CenarioDaGaleria.EQUIPE[d]`
  (um `Kit.caixa` fino por cima, fosco); o chão de cada raia com uma faixa
  `Kit.caixa(Vector3(1.6, 0.02, 1.6))` da cor da dupla, fosca, debaixo da borda do kit.
- **O espantalho** (um jogador): `Kit.peca(self, "barrel", Vector3(RAIAS[3], 0, Z_JOGADOR), 0.0, 1.2)`
  com `Kit.peca(self, "pot", ... + Vector3(0, 1.5, 0), 0.0, 1.4)` e uma espada.
- **O placar no mundo:** três marcas de corte por dupla (`Kit.caixa` 0,1 × 0,4 × 0,05)
  na parede do fundo, do lado de cada dupla, que acendem (emissivo na cor da
  dupla) a cada corte; as rodadas ganhas, como um escudo `shield-round` em
  cima da bandeira.
- O checklist do 11: a cor da dupla é fosca e fica no mundo, longe das
  cores dos lugares; nada metálico.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **gatilho (protagonista)** | R2 `GATILHO_RESISTENCIA` (2, 3 → 5 → 7 → 8): o peso que conta até o pico | da puxada boa à soltura |
| gatilho | R2 `GATILHO_RESISTENCIA` (2, 1): a fita frouxa | fora da estocada |
| vibração | `acerto` / `perfeito` / `erro` (o kit) | na puxada e na soltura |
| vibração | `golpe` | em quem leva o corte |
| barra de luz | o kit (`_reagir`, H08): branco no perfeito, a cor do lugar escurecida no erro | no toque julgado |
| luzinhas de jogador | o número, sempre | — |
| alto-falante do dono | `Forja.som_falante(l, "coleta", 0.7)` | nos dois da dupla que cortou |
| alto-falante do dono | `Som.no_controle(l, "golpe", 0.7)` | nos dois da dupla que levou o corte |
| háptica por material | `"metal"` (o kit) | — |
| som na TV | `"bigorna_aguda"` no corte; `"martelo"` no empate; `"confirma"` na rodada ganha | — |

## A falha

- **A fita afrouxa** (soltura ERRO ou perdida): a fita cai em curva (três
  segmentos que despencam com tween), a espada tomba mole na mão
  (`rotation.x` a 1,2 e volta em uma batida), `gesto("emote-no", 0.4)`.
- **A fita não pega** (puxada ERRO): o carretel gira em falso (uma volta em
  meia batida), `Som.tocar("tique", pos, -6.0)`.
- **Levar o corte:** os dois da dupla recuam meio passo (tween de 0,3 no x)
  e `gesto("fall", 0.5)`; `Forja.sentir(l, "golpe")`.
- **A recuperação:** a próxima estocada é no compasso seguinte; a rodada
  perdida recomeça com as fitas de volta.

## O fim e o vencedor

Acaba com duas rodadas ganhas (todos `acabou`) ou aos 90 s de música (H08).

```gdscript
## A dupla na frente: mais rodadas, depois mais cortes na rodada, depois mais pontos somados.
func _dupla_na_frente() -> int:
	if rodadas[0] != rodadas[1]:
		return 0 if rodadas[0] > rodadas[1] else 1
	if cortes[0] != cortes[1]:
		return 0 if cortes[0] > cortes[1] else 1
	return 0 if _soma(0) >= _soma(1) else 1


func vencedor() -> Array:
	var d := _dupla_na_frente()
	var pelos_pontos := func(a, b): return int(pontos[a]) > int(pontos[b])
	var frente: Array = duplas[d].duplicate()
	var tras: Array = duplas[1 - d].duplicate()
	frente.sort_custom(pelos_pontos)
	tras.sort_custom(pelos_pontos)
	return frente + tras
```

(Com um jogador, `duplas[1]` é vazia e ele vence se ganhou do espantalho;
senão, vem sozinho na lista mesmo assim — o fechamento mostra o placar.)

## Com menos de quatro

- **Três:** o Aprendiz completa a Maré (a regra de [Q](Q-a-prova.md#o-cenário-comum)).
  `com_poucos()`: `"Com o Aprendiz"`.
- **Dois:** 1 contra 1, os dois `× SOZINHO` (o mesmo peso). `com_poucos()`: `"Um contra um"`.
- **Um:** contra o espantalho (`ESPANTALHO` por estocada). `com_poucos()`: `"Contra o espantalho"`.
- **O controle que cai:** as notas dele somem sem erro; a dupla dele passa a
  valer `× SOZINHO` enquanto ele está fora (a dupla não fica em desvantagem
  dupla); volta na estocada seguinte.

## O robô

```gdscript
# O robô puxa o R2 na batida da puxada, segura e solta no pico, pelo relógio
# da música. Quando não acerta, solta 250 ms tarde (a fita afrouxa).
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
	Forja.robo_eixo(l, Forja.R2, 0.85 if _robo_segura[l] else 0.0, 0.06)
```

## Os ganchos

```gdscript
var _notas := [[], [], [], []]
var _ultima := [{}, {}, {}, {}]
var _gerado := 1
var _fora := [false, false, false, false]
var _puxado := [false, false, false, false]
var _estocadas := {}  ## e -> {b_solta, "valor": {lugar: [j_puxa, j_solta]}, resolvida}
var duplas := [[], []]
var cortes := [0, 0]
var rodadas := [0, 0]
var _pausa_ate := 0.0  ## a batida em que a pausa entre rodadas acaba
var _com_aprendiz := false  ## três jogadores: o Aprendiz puxa e solta com a Maré


func montar() -> void:
	camera_pos = Vector3(0, 6.6, 10.4)
	camera_olhar = Vector3(0, 1.0, -0.6)
	CenarioDaGaleria.montar(self)
	var lista := jogadores.map(func(p): return p.lugar)
	lista.sort()
	var meio := (lista.size() + 1) / 2
	duplas = [lista.slice(0, meio), lista.slice(meio)]  # com 4, 3 e 2, as equipes do kit (da_equipe(BRASA), da_equipe(MARE))
	_com_aprendiz = lista.size() == 3 and aprendizes[MARE] == 1  # o boneco do Aprendiz entra na raia vazia da Maré
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.preso = true
		p.rotation.y = PI * 0.5 if l in duplas[0] else -PI * 0.5
		_montar_a_espada(l, p)  # espada, fita, carretel, chão da dupla
		Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, PESO_PARADO)
	_montar_as_bandeiras()
	if lista.size() == 1:
		_montar_o_espantalho()


func jogar(_dt: float) -> void:
	while _gerado <= int(floor(Ritmo.batida() / 4.0)) + 1:
		_gerar_compasso(_gerado)  # nada durante a pausa entre rodadas
		_gerado += 1
	var agora := Ritmo.t_musica()
	for l in presentes():
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_notas[l] = _notas[l].filter(func(nt): return nt.tipo == "puxa" and float(nt.t) > agora)
		var r2 := Forja.eixo(l, Forja.R2)
		if not _puxado[l] and r2 >= CenarioDaGaleria.R2_APERTA:
			_puxado[l] = true
			_puxar(l, r2)
		elif _puxado[l] and r2 <= CenarioDaGaleria.R2_SOLTA:
			_puxado[l] = false
			_soltar(l, r2)
		_pesar(l)  # o degrau do Feedback pela batida desde a puxada
		while not _notas[l].is_empty() and agora > float(_notas[l][0].t) + FOLGA_PERDIDA:
			var nt: Dictionary = _notas[l].pop_front()
			_ultima[l] = nt
			nota_perdida(l, int(nt.n))
		_esticar_a_fita(l)
	_resolver_as_estocadas()  # o corte de cada estocada que acabou


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	marcar_equipe(equipe[l], PONTOS[julgamento])  # os dois da dupla; o item, o kit aplica (H08)
	_guardar_o_valor(l, nt, julgamento)
	if nt.tipo == "solta":
		Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, PESO_PARADO)  # o piscar do perfeito é do kit (H08)


func falha(l: int) -> void:
	var nt: Dictionary = _ultima[l]
	_guardar_o_valor(l, nt, Ritmo.ERRO)
	Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, PESO_PARADO)
	if nt.get("tipo", "") == "puxa":
		_tirar_a_soltura(l, int(nt.e))  # a fita não pegou: a solta sai sem erro
		_carretel_em_falso(l)
	else:
		_fita_afrouxa(l)
```

`_pesar(l)`
manda o Feedback só quando o degrau muda (guarde o último por lugar).
`_resolver_as_estocadas()` segue "O corte"; na pausa, `_pausa_ate = (floor(Ritmo.batida() / 4.0) + 2.0) * 4.0`.
Com `_com_aprendiz`, em cada estocada o `_resolver_as_estocadas()` sorteia a
puxada e a soltura do Aprendiz com `rng.randf() < ACERTO_APRENDIZ` (sempre
BOM) e as soma à Maré; o boneco dele (o `character-orc.glb` tingido de
`#b9a98a`, como em [Q](Q-a-prova.md#o-cenário-comum)) fica na raia vazia da
Maré, com a espada.

Catálogo: `"S05_J24"` em `MINIGAMES` e na lista da seção `S05`. O `.uid`.
Traduções: `"Espada de Fita": "Tape Sword"`, `"Solte no pico!": "Release at the peak!"`,
`"Solte!": "Release!"`, `"Com o Aprendiz": "With the Apprentice"` (se a Q1 ou a O5 já não pôs),
`"Um contra um": "One on one"`, `"Contra o espantalho": "Against the scarecrow"`;
`dica(l)`: `{"partes": ["@r2", "Solte no pico"], ...}` com `na_raia(l)` e
`not aprendeu(l)` (`"Solte no pico": "Release at the peak"`).

## O que o registro mede

- A `saida` de gatilho: os degraus do Feedback (`params` `[2, 3, 0]`,
  `[2, 5, 0]`, `[2, 7, 0]`, `[2, 8, 0]`, `[2, 1, 0]`), `seq`, `ok`.
- `entrada` `disparo` (a soltura com o curso), o `toque` do kit e o `jogo`
  `corte`. O cruzamento: soltura no tempo com os degraus `ok` é o peso que
  contou as batidas; o mesmo lugar soltando cedo com os degraus `ok` e o
  curso máximo alto é o Feedback que não pesou.

## Armadilhas

- **A dupla é por `presentes()` no `montar`:** quem cai não troca de dupla.
- **A cor da dupla nunca vai para a barra de luz** (F04): a prova confere o
  tom de cada lugar durante a sala.
- **O peso é o relógio:** os degraus têm de sair na batida certa (pela
  `Ritmo.batida()`); mande só quando o degrau muda.
- **A estocada se resolve uma vez:** marque `resolvida` e não conte de novo.
- **Os pontos e o item:** o kit aplica `Itens.pontos_do_acerto` no `julgar_toque`
  (H08); marque cru.

## Pronto quando

A Espada de Fita joga do aviso ao resultado com 4 (2 contra 2), 3 (2 contra
1), 2 (1 contra 1) e 1 jogador (contra o espantalho) e com o robô nos três
temperamentos; aguenta o cabo que cai; fecha com vencedor (a dupla na
frente primeiro); a prova do jogo passa; e `bash tests/prova_visual.sh`
passa com a **prancha olhada** com a Espada nela (o `Catalogo.sortear` da H08 põe o `S05_J24` na noite: rode a prova visual com a semente que o sorteia, `--semente=N`).

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, depois das outras da seção:

```gdscript
## Espada de Fita (S05_J24): as duplas pela metade, o peso subindo em
## degraus no R2, e o vencedor da dupla na frente.
func _prova_da_espada() -> void:
	var mg = await _joga_o_minigame("S05_J24", 130.0)
	if mg == null:
		return
	var k := mg.presentes().size()
	_esperar(mg.duplas[0].size() == (k + 1) / 2 and mg.duplas[0].size() + mg.duplas[1].size() == k, "Espada: as duplas pela metade (%s)" % [mg.duplas])
	var degraus := {}
	for e in _linha_do_tempo():
		if e.get("tipo") == "saida" and e.get("o") == "gatilho" and e.get("lado") == "R2" and e.get("modo") == "resistencia":
			degraus[int(e.get("params", [0, 0, 0])[1])] = true
	_esperar(degraus.has(3) or degraus.has(4), "Espada: o peso subiu no R2 (%s)" % [degraus.keys()])
	var v := mg.vencedor()
	var d := mg._dupla_na_frente()
	_esperar(v.size() == k and (mg.duplas[d].is_empty() or v[0] in mg.duplas[d]), "Espada: a dupla na frente vem primeiro (%s)" % [v])
```

**O que o André joga e sente** (`./run-local.sh -- --sala=S05_J24`):

- os quatro degraus de peso são distintos e o quarto é o pico;
- dá para soltar no pico de olhos fechados;
- o acorde da dupla (os dois perfeitos) soa e corta;
- a cor da dupla está na bandeira e no chão, nunca na barra de luz.

## Ao terminar

- No [quadro](README.md): a linha **M4** (se não existir, acrescente
  `| [M4](M4-espada-de-fita.md) | M | S5 — Espada de Fita | M | — | 1,5 | feito (<commit>) | <gasto> |`),
  com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: Espada de Fita — o duelo em dupla, com o peso que conta até o pico`
