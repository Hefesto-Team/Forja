# L3 — Curto-Circuito

**Sprint:** L · **Slot:** S04_J18 · **Tamanho:** M · **Estimativa:** US$ 1,5 · **Depende de:** H04, H08, F09, L1

## Por quê

A batata quente da seção. Uma bomba passa de mão em mão no tempo, e o
pavio dela só quem segura sente: o coração bate na mão, devagar quando
falta muito, acelerado quando falta pouco. É a pista privada do Astro Bot
([10](../10-a-regua-astro-bot.md), lição 12): com quatro no sofá, quem está
com a bomba sabe uma coisa que os outros não sabem — e escolhe para quem
passar. O verbo da vibração aqui é **contar o tempo que falta**.

**Adaptado do [03](../03-os-45-minigames.md#s4--o-impacto--vibração-e-barra-de-luz):**
a bomba está no mundo (em cima da cabeça de quem segura) e no peso do R2 de
quem segura; a barra de luz continua na cor do lugar e nunca diz quem está
com ela. "Quatro rodadas; o último que não estourou" vira: quatro rodadas,
e vence quem estourou menos.

## Ler antes

- [O índice da seção](L-o-impacto.md) e a [L1](L1-o-cerco.md) (o cenário comum, o `_joga_o_minigame`)
- [O molde de minigame](molde-de-minigame.md) e o [kit](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A régua Astro Bot](../10-a-regua-astro-bot.md) (a lição 12)

## A ficha de dados

`godot/scripts/minigames/s04/curto_circuito.gd`:

```gdscript
extends Minigame
## Curto-Circuito (S04_J18) — a bomba passa de mão em mão. Quem segura joga
## para o vizinho da esquerda (L1) ou da direita (R1), na batida seguinte à
## que recebeu (no pico, na colcheia seguinte). O pavio é secreto: o coração
## da bomba bate na mão de quem segura e acelera quando falta pouco; o R2
## dele pesa cada vez mais. Quem está com ela quando o pavio acaba estoura.
## Quatro rodadas.
##
## A falha: jogar fora do tempo — a bomba escorrega e fica na mão mais uma
## batida; segurar quatro vezes seguidas — ela estoura. Estourar: o cavaleiro
## sai voando e volta caído.
## O vencedor: quem estourou menos; no empate, mais pontos.
## O alto-falante do dono: o tique da bomba ao pegar ("clique"); o estouro ("golpe").
## O registro mede: cada pulso do coração mandado (sensação, ok) a quem
## segura, e o passe no tempo: quem passa tarde repetidas vezes com o
## coração acelerado não sentiu o coração.
## O robô: sente a bomba pelo peso do R2 no controle simulado e joga na
## primeira batida possível, para o vizinho com mais pontos; quando não
## acerta, 250 ms tarde (escorrega).
## Com menos de quatro: dois jogam um para o outro; sozinho, o boneco de palha devolve.
## A régua: (1) "Passe!" com a bomba acesa na cabeça de alguém; (2) sim: o
## pavio é só da mão; (3) não pergunta nada.

const FICHA := {
	"slot": "S04_J18",
	"titulo": "Curto-Circuito",
	"verbo": "Passe!",
	"genero": "sabotagem",
	"icone": "rumble_esquerdo",
	"entradas": [Forja.L1, Forja.R1],
	"camera": "fixa",
	"faixa": "MUS_S04_J18",
	"duracao": 100.0,
	"fim": "ultimo_em_pe",
	"sensacoes": ["toque", "aviso", "golpe", "explosao", "acerto", "perfeito", "erro"],
	"material": "metal",
	"microjogo": {"verbo": "Passe!", "segundos": 6.0},
}

const PONTOS := [0, 10, 20, 30]  ## o passe: ERRO, BOM, OTIMO, PERFEITO
const SOBREVIVEU := 100  ## a cada rodada, quem não estourou
const RODADAS := 4
## O pavio de cada rodada, em batidas (sorteado entre os dois): 1 e 4 longos, 2 e 3 (o pico) curtos.
const PAVIO := [[16, 24], [10, 16], [10, 16], [16, 24]]
## O passo da grade de cada rodada: 1 batida, ou meia no pico.
const PASSO := [1.0, 0.5, 0.5, 1.0]
const SEGURA_MAX := 4  ## quatro vezes sem passar e ela estoura
const PAUSA_COMPASSOS := 2  ## entre uma rodada e a outra
const LARANJA := Color(1.0, 0.45, 0.0)  ## as faíscas do estouro (no mundo, nunca na barra de luz)
const BONECO := 9  ## o "lugar" do boneco de palha (um jogador só)
```

## Como se joga

**A rodada.** A primeira começa no compasso 1 (batida 4); cada uma das
seguintes começa `PAUSA_COMPASSOS` compassos depois do estouro, no começo de
um compasso. Quem começa com a bomba: o presente com controle que estourou
menos (no empate, `rng` sorteia entre eles). O pavio:
`_estouro_b = inicio + rng.randi_range(PAVIO[r][0], PAVIO[r][1])` (em
batidas inteiras), secreto.

**Quem segura** (`_com`) tem sempre **uma** nota, a próxima chance de
passar: ao receber na batida `r`, a nota é `r + PASSO[rodada]`; cada chance
perdida (sem passe, ou passe fora do tempo) põe a próxima `PASSO[rodada]`
depois. A nota: `{"n": int(round(b * 2)), "b": b, "t": Ritmo.t_da_batida(b)}`,
com `nova_nota(l, n, t)`. Na `SEGURA_MAX`-ésima chance perdida ela estoura.

**O passe:** L1 joga para o vizinho da esquerda, R1 para o da direita. Os
vizinhos são os presentes com controle, em ordem de lugar, em roda (a
esquerda de P1 é o último; a direita do último é P1). Se o aperto está a
até `Ritmo.JANELA_BOM` da nota → `julgar_toque(l, t, n)`:

- BOM, ÓTIMO ou PERFEITO → `toque()`: a bomba voa (0,3 batida de tween,
  enfeite) e o vizinho a **recebe na batida da nota** (`r = b`): a vez dele
  é `b + PASSO`. Em roda e no tempo, a bomba anda uma batida por jogador —
  o hoqueto;
- ERRO → `falha()`: escorrega (abaixo); a próxima chance é `b + PASSO`.

Aperto longe de qualquer nota (quem não segura, ou quem segura fora da
janela): nada acontece com a bomba; quem não segura e aperta ganha
`Forja.evento("entrada", l + 1, {"slot": id, "o": "fantasma", "golpe_de": "P%d" % (_com + 1)})`
(sentiu o coração de outro?). A chance que passa de `t + FOLGA_PERDIDA` (o kit) sem
aperto é `nota_perdida(l, n)`.

**O coração (a pista, só em quem segura):** `faltam = _estouro_b − Ritmo.batida()`.

| faltam | o pulso | quando |
| --- | --- | --- |
| mais de 8 batidas | `Forja.sentir(l, "toque", 60)` | em cada batida |
| de 8 a 4 | `Forja.sentir(l, "aviso", 60)` | em cada colcheia |
| menos de 4 | `Forja.sentir(l, "golpe", 60)` | em cada colcheia |

Controle pelo índice da grade: `var g := int(floor(Ritmo.batida() * div))`
(`div` 1 ou 2); pulse quando `g > _ultimo_pulso` e guarde. Cada pulso vai ao
registro como `sensacao` (F05); o minigame grava, na mudança de faixa,
`Forja.evento("pista", l + 1, {"slot": id, "n": -1, "evento": "mandou", "via": "rumble", "o_que": "ambos", "ok": ok, "faltam": int(faltam)})`.

**O peso (o gatilho de quem segura):** R2 em
`Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 0, forca)`, com `forca` 3
(mais de 8), 6 (8 a 4) e 8 (menos de 4); ao passar, o R2 de quem passou
volta a `Forja.GATILHO_OFF`. Mande só quando muda.

**O estouro:** quando `Ritmo.batida() >= _estouro_b` (ou na quarta chance
perdida), quem segura estoura. Os que não estouraram ganham `SOBREVIVEU`.
Na quarta rodada, depois do estouro, todos `acabou`.

**Os pontos** do passe: `marcar(l, PONTOS[julgamento])` (o item, `Itens.pontos_do_acerto`, o kit já aplica no `julgar_toque`: H08).

**O pico** são as rodadas 2 e 3: o pavio mais curto e o passe na colcheia —
a bomba roda duas vezes mais depressa. A rodada 4 volta à batida, com pavio
longo: o fim tenso.

## O cenário

- `CenarioDoImpacto.montar(self)`; a câmera d'O Impacto
  (`Vector3(0, 6.4, 10.8)` olhando `Vector3(0, 1.0, -0.4)`).
- Por lugar: `raia(l)`, `posicionar(l)`, `preso = true`, de frente para a
  câmera (`rotation.y = 0.0`).
- **A bomba** (uma só, um `Node3D`): `Kit.peca(bomba, "barrel", Vector3.ZERO, 0.0, 0.7)`,
  o pavio `Kit.caixa(bomba, Vector3(0.05, 0.3, 0.05), Vector3(0, 0.75, 0), Kit.material(Color("#3a3a44")))`
  e a faísca `Kit.caixa(bomba, Vector3(0.09, 0.09, 0.09), Vector3(0, 0.95, 0), Kit.material(Color("#ffb000"), 2.5))`
  com a escala `1.0 + 0.4 * absf(sin(PI * 4.0 * Ritmo.batida()))` (pisca no
  mesmo ritmo para todos: não conta o pavio). Em quem segura, em
  `jogador(_com).global_position + Vector3(0, 2.1, 0)`; o boneco segura com
  `animar("holding-both")`.
- **O fosso de fios** atrás das raias: seis `Kit.caixa(self, Vector3(0.06, 0.06, 3.0), Vector3(-7.5 + 3.0 * k, 0.05, -2.5), Kit.material(Color("#3a3a44")))`
  com faíscas (`Efeitos.faiscas`) azuis-claras `#6fa8ff` a cada compasso:
  o curto-circuito do título.
- **O boneco de palha** (só com um jogador): `Kit.peca(self, "barrel", Vector3(RAIAS[l] + 4.0, 0, Z_JOGADOR), 0.0, 1.2)`
  e a cabeça `Kit.peca(self, "pot", Vector3(RAIAS[l] + 4.0, 1.5, Z_JOGADOR), 0.0, 1.4)`.
- O checklist do 11: peças do kit e caixas; o emissivo só na faísca e na
  borda da raia.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **vibração (protagonista)** | o coração: `toque` → `aviso` → `golpe` (60 ms), só em quem segura | em cada batida ou colcheia, pela tabela |
| vibração | `acerto` / `perfeito` / `erro` (o kit) | no passe julgado |
| vibração | `explosao` | no estouro, em quem estourou |
| barra de luz | a cor do lugar, 100%, sempre | — |
| barra de luz | o kit (`_reagir`, H08): branco no perfeito, a cor do lugar escurecida no erro | no toque julgado |
| luzinhas de jogador | o número, sempre | — |
| alto-falante do dono | `Forja.som_falante(l, "clique", 0.8)` | ao receber a bomba |
| alto-falante do dono | `Som.no_controle(l, "golpe", 0.8)` | no estouro |
| gatilho | R2 `GATILHO_RESISTENCIA` (0, 3 / 6 / 8) em quem segura; `GATILHO_OFF` nos outros | a cada troca de dono e de faixa do pavio |
| háptica por material | `"metal"` (o kit, no passe) | — |
| som na TV | `"tique"` no voo; `"golpe"` e faíscas grandes no estouro | — |

Nada na barra de luz nem nas luzinhas diz quem está com a bomba: ela está
no mundo e no R2.

## A falha

- **Escorregou** (passe ERRO ou chance perdida): a bomba cai do alto da
  cabeça para o chão da raia e volta para a mão em meia batida (tween);
  `jogador(l).gesto("emote-no", 0.4)`; o kit já sentiu o `erro`.
- **Estourou:** `Forja.sentir(l, "explosao")`, `Som.no_controle(l, "golpe", 0.8)`,
  `Som.tocar("golpe", pos, 0.0)`, `Efeitos.faiscas(self, pos, LARANJA, 60, 1.6)`,
  `tremer(TREMOR_EXPLOSAO)`; o cavaleiro sai voando: tween de
  `position` para `+ Vector3(0, 2.5, -1.5)` em meia batida e de volta em
  meia, `gesto("fall", 1.0)`, e fica caído (`animar("die")`) até a rodada
  seguinte começar. `explosoes[l] += 1`.
- **A recuperação:** a rodada seguinte recomeça todo mundo de pé; quem
  estourou começa com a bomba só se é quem estourou menos.

## O fim e o vencedor

`fim` `ultimo_em_pe`: depois da quarta rodada, todos `acabou` e o kit fecha;
os 100 s de `duracao` são o teto (o molde: nenhum minigame passa de 120 s).

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if int(explosoes[a]) != int(explosoes[b]):
			return int(explosoes[a]) < int(explosoes[b])
		return int(pontos[a]) > int(pontos[b]))
	return lista
```

## Com menos de quatro

- **Três:** a roda de três; a esquerda e a direita são os outros dois.
- **Dois:** a esquerda e a direita são o mesmo vizinho; a bomba vai e volta.
- **Um:** o vizinho dos dois lados é o boneco de palha (`BONECO`): ele segura
  uma batida (`PASSO` no pico) e devolve sozinho, sempre no tempo; se o
  pavio acaba com ele, ele estoura em faíscas (sem ponto para ninguém).
  `com_poucos()` devolve `"Você e o boneco de palha"` com um jogador.
- **O controle que cai:** se quem segura perde o controle, a bomba passa
  sozinha para o vizinho da direita na próxima chance, sem julgamento; quem
  está sem controle sai da roda até voltar (e volta na rodada seguinte, com
  o placar dele como estava).

## O robô

```gdscript
# O robô sabe que está com a bomba pelo peso do R2 no controle simulado (o
# modo Feedback, 0x21), e joga na primeira chance, pelo relógio da música,
# para o lado do vizinho com mais pontos (a sabotagem).
var _robo_nota := [-1.0, -1.0, -1.0, -1.0]
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var com_ela := int(Forja.percepcao(l).get("gatilho_dir", 0)) == 0x21
	if not com_ela or _notas[l].is_empty():
		_robo_nota[l] = -1.0
		return
	var nt: Dictionary = _notas[l][0]
	if float(nt.b) != _robo_nota[l]:
		_robo_nota[l] = float(nt.b)
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 250 ms tarde (escorrega)
		_robo_atraso[l] = 0.0 if Forja.robo_acerta() else 0.25
	if Ritmo.t_musica() >= float(nt.t) + float(_robo_atraso[l]):
		var esq := _vizinho(l, 0)
		var dir := _vizinho(l, 1)
		var lado := 0 if int(pontos[esq] if esq < 4 else 0) >= int(pontos[dir] if dir < 4 else 0) else 1
		Forja.robo_apertar(l, Forja.L1 if lado == 0 else Forja.R1, 0.06)
		_robo_nota[l] = 99999.0  # já jogou nesta chance
```

(`_notas[l]` tem no máximo uma nota: a chance de agora. O robô lê a hora
dela; ele só age pelo controle.)

## Os ganchos

```gdscript
var _notas := [[], [], [], []]  ## só quem segura tem uma: a próxima chance
var _ultima := [{}, {}, {}, {}]
var _com := -1  ## quem segura (0..3, BONECO, ou -1 entre as rodadas)
var _estouro_b := 0.0
var _rodada := 0  ## 0..3; RODADAS = acabou
var _perdidas := 0  ## chances perdidas seguidas de quem segura
var _proxima_rodada_b := 4.0
var _ultimo_pulso := -1
var _forca := [-1, -1, -1, -1]  ## a força do R2 mandada (-1: Off)
var explosoes := [0, 0, 0, 0]
var _pisca := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	camera_pos = Vector3(0, 6.4, 10.8)
	camera_olhar = Vector3(0, 1.0, -0.4)
	CenarioDoImpacto.montar(self)
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.preso = true
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)
	_montar_a_bomba()
	_montar_os_fios()
	if jogadores.size() == 1:
		_montar_o_boneco()


func iniciar_jogo() -> void:
	_proxima_rodada_b = 4.0


func jogar(_dt: float) -> void:
	var b := Ritmo.batida()
	if _com == -1 and _rodada < RODADAS and b >= _proxima_rodada_b:
		_comecar_rodada(int(_proxima_rodada_b))
	for l in presentes():
		if not conectado(l):
			continue
		if Forja.apertou(l, Forja.L1):
			_passar(l, 0)
		elif Forja.apertou(l, Forja.R1):
			_passar(l, 1)
	if _com >= 0:
		_coracao()
		_gatilho_do_pavio()
		if _com < 4 and not conectado(_com):
			_passa_sozinha()
		elif _com < 4 and not _notas[_com].is_empty() and Ritmo.t_musica() > float(_notas[_com][0].t) + FOLGA_PERDIDA:
			var nt: Dictionary = _notas[_com].pop_front()
			_ultima[_com] = nt
			nota_perdida(_com, int(nt.n))  # chama falha(): escorrega, ou estoura na quarta
		elif _com == BONECO and b >= float(_ultima_do_boneco) + PASSO[_rodada]:
			_boneco_devolve()
		if b >= _estouro_b:
			_estourar(_com)
	_mostrar_a_bomba()


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	marcar(l, PONTOS[julgamento])  # o item, o kit já aplicou (H08); o piscar do perfeito é do kit
	jogador(l).gesto("interact-left" if _lado_do_passe[l] == 0 else "interact-right", 0.3)
	_entregar(_vizinho(l, _lado_do_passe[l]), float(nt.b))


func falha(l: int) -> void:
	_perdidas += 1
	if _perdidas >= SEGURA_MAX:
		_estourar(l)
		return
	var nt: Dictionary = _ultima[l]
	_nova_chance(l, float(nt.b) + PASSO[_rodada])
	_escorregar(l)
```

As outras, pelo que "Como se joga" e "A falha" dizem:
`_comecar_rodada(b)`, `_passar(l, lado)` (guarda `_lado_do_passe[l] = lado`,
põe a nota em `_ultima[l]` e chama `julgar_toque`, ou grava o fantasma),
`_entregar(para, b)` (o R2 de quem passou vai a Off, `_com = para`,
`_perdidas = 0`, `Forja.som_falante(para, "clique", 0.8)`, `_nova_chance(para, b + PASSO[_rodada])`),
`_nova_chance(l, b)` (limpa `_notas[l]`, põe a nova, `nova_nota`),
`_vizinho(l, lado)` (a roda; `BONECO` com um jogador), `_coracao()`,
`_gatilho_do_pavio()`, `_passa_sozinha()`, `_boneco_devolve()`,
`_estourar(l)` (o estouro; `_com = -1`; `_rodada += 1`;
`_proxima_rodada_b = (floor(b / 4.0) + 1 + PAUSA_COMPASSOS) * 4`; na última,
todos `acabou`), `_escorregar(l)`. A barra de luz fica na cor do lugar; o
piscar do perfeito e do erro é do kit (H08). E
`var _lado_do_passe := [0, 0, 0, 0]`, `var _ultima_do_boneco := 0.0`.

`progresso()`: `"Rodada %d de %d" % [mini(_rodada + 1, RODADAS), RODADAS]`
na fase jogo. `dica(l)`: `{"partes": ["@l1", "Esquerda", "@r1", "Direita"], "pos": Vector3(RAIAS[l], 0.0, 4.6)}`
quando `na_raia(l)` e `_com == l` e `not aprendeu(l)`.

Catálogo: `"S04_J18"` em `MINIGAMES` e na lista da seção `S04`. O `.uid`.
Traduções: `"Curto-Circuito": "Short Circuit"`, `"Passe!": "Pass!"`,
`"Rodada %d de %d": "Round %d of %d"`, `"Você e o boneco de palha": "You and the scarecrow"`.

## O que o registro mede

- Cada pulso do coração (`sensacao`, com `seq` e `ok` na `saida`) só no
  controle de quem segura, e o `pista` (`via` `rumble`) (`"ambos"`, `faltam`) a cada
  mudança de faixa do pavio.
- O passe (`toque` do kit) e a chance perdida (`toque` perdido).
- O fantasma: quem aperta sem segurar, com quem segurava (a vibração vazou?).
- A `saida` de gatilho (Feedback 3, 6, 8, e Off) de cada troca de dono.

## Armadilhas

- **Uma bomba, uma nota:** só quem segura tem nota; ao entregar, limpe a
  nota de quem passou. Nota perdida de quem já não segura não pode existir.
- **O vizinho pula quem está sem controle** e nunca é o próprio lugar (com
  um jogador, é o `BONECO`, que não é índice de `pontos`).
- **O pavio é em batidas**, secreto; a faísca da bomba pisca igual para
  todos (não entrega o pavio).
- **O coração não repete na mesma grade:** `_ultimo_pulso` guarda o índice.
- **O R2 de quem não segura fica Off**; o L2 é do item (G03) — nunca
  `gatilhos_off` no meio do jogo.
- **Os 100 s são o teto**, não o fim normal: as quatro rodadas acabam
  antes (o fim é do jogo, `ultimo_em_pe`). O teto conta em tempo de música
  (H08), então vale igual na prova e no sofá.
- **Os pontos e o item:** o kit aplica `Itens.pontos_do_acerto` no `julgar_toque`
  (H08); marque cru.

## Pronto quando

O Curto-Circuito joga do aviso ao resultado com 4, 3, 2 e 1 jogador (com o
boneco de palha) e com o robô nos três temperamentos; aguenta o cabo que cai
com a bomba na mão; fecha com vencedor; a prova do jogo passa; e
`bash tests/prova_visual.sh` passa com a **prancha olhada** com o
Curto-Circuito nela (o `Catalogo.sortear` da H08 põe o `S04_J18` na noite: rode a prova visual com a semente que o sorteia, `--semente=N`).

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, depois das outras da seção:

```gdscript
## Curto-Circuito (S04_J18): uma bomba só (o R2 pesado em um controle por
## vez), a roda dos vizinhos e o vencedor por estouros.
func _prova_do_curto_circuito() -> void:
	var dois_com_ela := [0]
	var alguem_com_ela := [false]
	var olhar := func(mg: Minigame) -> void:
		var com := 0
		for l in mg.presentes():
			if int(Forja.percepcao(l).get("gatilho_dir", 0)) == 0x21:
				com += 1
		if com >= 2:
			dois_com_ela[0] += 1
		if com == 1:
			alguem_com_ela[0] = true
	var mg = await _joga_o_minigame("S04_J18", 140.0, olhar)
	if mg == null:
		return
	_esperar(alguem_com_ela[0], "Curto-Circuito: a bomba pesou no R2 de quem segurava")
	_esperar(dois_com_ela[0] <= 2, "Curto-Circuito: nunca dois com a bomba (%d quadros)" % dois_com_ela[0])
	if mg.presentes().size() == 4:
		_esperar(mg._vizinho(0, 0) == 3 and mg._vizinho(0, 1) == 1 and mg._vizinho(3, 1) == 0, "Curto-Circuito: a roda dos vizinhos")
	var v := mg.vencedor()
	_esperar(not v.is_empty() and int(mg.explosoes[v[0]]) == v.map(func(l): return int(mg.explosoes[l])).min(), "Curto-Circuito: vence quem estourou menos")
```

**O que o André joga e sente** (`./run-local.sh -- --sala=S04_J18`):

- o coração na mão é claro e acelera; dá medo segurar quando ele dispara;
- o passe no tempo faz a bomba rodar em hoqueto; no pico, gira o dobro;
- o R2 pesa com a bomba e solta ao passar;
- o estouro é engraçado (o voo) e ninguém sai do jogo;
- a barra de luz nunca entrega quem está com a bomba.

## Ao terminar

- No [quadro](README.md): a linha **L3** (se não existir, acrescente
  `| [L3](L3-curto-circuito.md) | L | S4 — Curto-Circuito | M | — | 1,5 | feito (<commit>) | <gasto> |`),
  com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: Curto-Circuito — a bomba de mão em mão, com o pavio que só a mão sente`
