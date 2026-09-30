# N5 — Corta-Fio

**Sprint:** N · **Slot:** S06_J30 · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 1,5 · **Depende de:** H04, F09, N1, H07

## Por quê

A sabotagem da seção. Cada um tem uma bomba no peito, e ela bipa **no
alto-falante do próprio controle**: um estalo seco é o fio errado; o bipe
alto e claro é o fio certo — corte na batida seguinte. Quem corta perfeito
ganha um bipe falso para mandar ao controle de quem está na frente: um bipe
quase igual ao certo, um pouco mais grave. O verbo do alto-falante aqui é
**desconfiar**: ouvir não basta, tem de ouvir **qual**.

**Adaptado do [03](../03-os-45-minigames.md#s6--o-canto--alto-falante) pelo
[princípio 8](../02-principios.md#8-ninguém-fica-para-trás-ninguém-é-punido-por-ser-bom):**
"quem está na frente pode mandar um bipe falso para o controle de outro"
vira: quem corta perfeito ganha o bipe falso, e o bipe falso vai sempre
**para** quem está na frente (o ambiente pesa na liderança).

## Ler antes

- [O índice da seção](N-o-canto.md) e a [N1](N1-o-canto.md) (o cenário comum, o robô que ouve, o `_joga_o_minigame`)
- [O molde de minigame](molde-de-minigame.md) e o [kit](../13-arquitetura.md#o-kit-do-minigame--h04)

## A ficha de dados

`godot/scripts/minigames/s06/corta_fio.gd`:

```gdscript
extends Minigame
## Corta-Fio (S06_J30) — a bomba no peito bipa no alto-falante do seu
## controle, na sua batida: o estalo ("clique") é o fio errado; o bipe claro
## ("pronto") é o fio certo — corte com ✕ na batida seguinte. Três fios
## certos desarmam a bomba, e vem outra. Cortar depois do estalo, ou depois
## do bipe falso, estoura a bomba em confete. Quem corta perfeito ganha um
## bipe falso (△) para mandar a quem está na frente.
##
## A falha: a bomba estoura em confete (os fios cortados daquela bomba se
## perdem); o fio certo sem corte escapa (nada estoura).
## O vencedor: mais bombas desarmadas; depois mais fios; depois mais pontos.
## O alto-falante do dono: o bipe (o protagonista) e o falso.
## O registro mede: cada bipe (qual, se foi ao controle) e o corte depois
## dele: cortar depois do estalo com a placa é ouvido que não distinguiu;
## não cortar depois do certo com a placa, sempre, é o alto-falante mudo.
## O robô: ouve o ataque do bipe no alto-falante simulado e corta na batida
## seguinte se o bipe era o certo (pela partitura); quando não acerta, corta
## tarde ou corta o falso. Manda o bipe falso logo que ganha.
## Com menos de quatro: as batidas se dividem; sozinho, só as pares e sem
## bipe falso.
## A régua: (1) "Corte!" com a bomba no peito e o alicate; (2) sim: o fio
## certo só se ouve; (3) não pergunta nada.

const FICHA := {
	"slot": "S06_J30",
	"titulo": "Corta-Fio",
	"verbo": "Corte!",
	"genero": "sabotagem",
	"icone": "alto_falante",
	"entradas": [Forja.CRUZ, Forja.TRIANGULO],
	"camera": "fixa",
	"faixa": "MUS_S06_J30",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["toque", "acerto", "perfeito", "erro", "explosao"],
	"material": "metal",
	"microjogo": {"verbo": "Corte!", "segundos": 6.0},
}

const PONTOS := [0, 40, 70, 100]  ## ERRO, BOM, OTIMO, PERFEITO
const FIOS_POR_BOMBA := 3
const CERTO := 0
const ERRADO := 1
const FALSO := 2
const BIPE := ["pronto", "clique", "nota_alta"]  ## CERTO, ERRADO, FALSO
## A chance de o bipe ser o certo, por parte (entrada 0-30 s, pico 30-60 s, saída 60-90 s).
const CHANCE_CERTO := [0.5, 0.35, 0.4]
const PISCA_ESTOURO := 0.4
const PULSO_S := 0.12
## As cores do confete e dos fios: longe das cores dos lugares (docs/jogo/11, regra 6).
const CONFETE := [Color("#e8b44c"), Color("#6fd3c8"), Color("#c28bff"), Color("#e9e7f2")]
```

## Como se joga

**O dono da batida** é `presentes()` em ordem, `lista[b % k]`; sozinho, só
as batidas pares. O compasso 0 é a contagem; o compasso é gerado quando
`Ritmo.batida() >= 4c − 4`.

**O bipe** do dono na batida `b` (toda batida do dono tem um): `CERTO` com a
chance da parte, senão `ERRADO`; se o lugar tem um falso pendente
(`_falso_para[l]`) e o bipe sorteado é `ERRADO`, ele vira `FALSO` e a
pendência acaba. No **pico** (30–60 s), a batida do dono tem dois bipes, em
`b` e `b + 0,5` (quem está com `Ritmo.simples[l]` fica com um). Na hora
(`Ritmo.t_musica() >= Ritmo.t_da_batida(b)`):
`var foi := CenarioDoCanto.falante(self, l, BIPE[tipo], 0.9)` e
`Forja.evento("jogo", l + 1, {"slot": id, "o": "chamada", "n": int(round((b + 1) * 2)), "som": BIPE[tipo], "no_controle": foi, "tipo": ["certo", "errado", "falso"][tipo]})`.
Na tela, a bomba do peito pisca igual nos três (a luzinha da bomba é a
mesma): a tela diz **quando** bipou, não **qual**.

**O corte** é na batida seguinte ao bipe, `b + 1`:

- bipe `CERTO` → a nota `{"n": int(round((b + 1) * 2)), "b": b + 1, "t": Ritmo.t_da_batida(b + 1), "tipo": CERTO}`,
  com `nova_nota` no bipe. ✕ a até `Ritmo.JANELA_BOM` → `julgar_toque(l, t, n)`:
  BOM ou melhor corta o fio (`fios[l] += 1`; no terceiro, `bombas[l] += 1`,
  `fios[l] = 0`, e uma bomba nova no peito); ERRO (fora do tempo) estoura;
  sem ✕, `nota_perdida` — **o fio escapa** (nada estoura, o fio fica);
- bipe `ERRADO` ou `FALSO` → a armadilha `{"b": b + 1, "t": Ritmo.t_da_batida(b + 1), "tipo": ERRADO ou FALSO}`
  (não é nota do kit: nada de `nova_nota`). ✕ a até `JANELA_BOM` dela →
  **estoura** (sem julgamento do kit) e
  `Forja.evento("jogo", l + 1, {"slot": id, "o": "armadilha", "tipo": "errado"/"falso"})`;
- ✕ longe de nota e de armadilha → nada (o alicate fecha no ar).

**O bipe falso:** o corte PERFEITO dá uma carga (`carga[l] = true`, no
máximo uma; sozinho, nunca). △ com carga manda o falso **para quem está na
frente** — o presente com mais bombas, depois mais fios, depois mais
pontos, que não seja ele mesmo (se ele é o da frente, vai para o segundo):
`_falso_para[alvo] = true`, `carga[l] = false`, `Som.tocar("especial", null, -10.0)`
na TV (todos ouvem que alguém sabotou; ninguém ouve quem), o cavaleiro de
quem mandou dá um chute no ar (`gesto("attack-kick-right", 0.4)`), e
`Forja.evento("jogo", l + 1, {"slot": id, "o": "sabotagem", "para": alvo + 1})`.
O falso é `"nota_alta"` (1175 Hz); o certo é `"pronto"` (1568 Hz, mais
claro): quem conhece o certo distingue.

**Os pontos:** `marcar(l, Itens.pontos_do_acerto(l, PONTOS[j], j, fmod(b, 4.0) == 0.0))`
no corte; `marcar(l, 150)` na bomba desarmada.

**O compasso na mão:** `Forja.sentir(l, "toque")` no começo de cada compasso
e `CenarioDoCanto.tempo_forte()`.

**Os 90 segundos:** entrada (0–30 s) um bipe por vez, metade certos;
**pico** (30–60 s) dois bipes por vez (colcheias), menos certos — aos 30 s as
luzes da capela piscam três vezes em falso-contato (a energia do
enchimento cai a 0,2 e volta, nas batidas 0, 1 e 2) e `Som.tocar("golpe", Vector3(0, 3, -6), -6.0)`;
saída (60–90 s) um bipe por vez, 40% certos.

## O cenário

- `CenarioDoCanto.montar(self)`; a câmera d'O Canto.
- Por lugar: `raia(l)`, `posicionar(l)`, `preso = true`, e:
  - **a bomba no peito:** um `BoneAttachment3D` no osso `torso` com
    `Kit.caixa(presa, Vector3(0.36, 0.26, 0.14), Vector3(0, 0.1, 0.22), Kit.material(Color("#3a3a44"), 0.0, 0.6))`,
    a luzinha da bomba `Kit.caixa(presa, Vector3(0.06, 0.06, 0.04), Vector3(0.1, 0.18, 0.3), Kit.material(Color("#ff4a2a"), 0.0))`
    (o emissivo liga 2,0 por 0,1 s em **todo** bipe, igual) e os três fios
    `Kit.caixa(presa, Vector3(0.3, 0.03, 0.03), Vector3(0, 0.02 - 0.06 * k, 0.3), Kit.material(CONFETE[k], 0.0, 0.8))`
    (o fio cortado some com duas faíscas);
  - **o alicate** na mão direita: duas `Kit.caixa(Vector3(0.04, 0.22, 0.04))`
    num `BoneAttachment3D` em `arm-right`, que fecham (rotação 0,4) no ✕;
  - **as bombas desarmadas** empilhadas ao lado:
    `Kit.caixa(self, Vector3(0.3, 0.2, 0.2), Vector3(RAIAS[l] + 1.1, 0.1 + 0.22 * i, Z_JOGADOR), Kit.material(Color("#4a4e5e"), 0.0, 0.7))`.
- O checklist do 11: caixas foscas; as cores dos fios e do confete longe das
  cores dos lugares; o emissivo só na luzinha da bomba (que tem trabalho) e
  na borda da raia.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **alto-falante (protagonista)** | o bipe: `"pronto"` (certo), `"clique"` (errado), `"nota_alta"` (falso), 0,9 | na batida do dono |
| vibração | `toque` | no começo de cada compasso |
| vibração | `acerto` / `perfeito` / `erro` (o kit) | no corte julgado |
| vibração | `explosao` | a bomba estoura |
| barra de luz | `CenarioDoCanto.luz_da_nota(l, 0.6)` por `PULSO_S`, e volta a 1,0 | no corte bom — nunca no bipe |
| barra de luz | laranja `Color(1.0, 0.45, 0.0)` por `PISCA_ESTOURO` (0,4 s), e volta à cor | no estouro |
| luzinhas de jogador | o número, sempre | — |
| háptica por material | `"metal"` (o kit, no cabo) | — |
| gatilho | `Forja.gatilho(l, 1, Forja.GATILHO_OFF)` no `montar` | nada a segurar |
| som na TV | `"tique"` no corte; `"especial"` na sabotagem; `"falha"` e faíscas no estouro; `"sucesso"` baixo na bomba desarmada | — |

## A falha

- **O estouro** (cortar depois do estalo ou do falso, ou cortar fora do
  tempo): confete das quatro cores (`Efeitos.faiscas(self, pos_do_peito, CONFETE[k], 20, 1.2)`
  para cada `k`), `Forja.sentir(l, "explosao")`, laranja na barra de luz,
  `Som.no_controle(l, "golpe", 0.7)`, o cavaleiro cai sentado coberto de
  confete (`gesto("fall", 0.8)`); `fios[l] = 0` e os três fios da bomba
  voltam (a bomba está inteira de novo).
- **O fio escapa** (o certo sem corte): o fio treme e fica; o kit toca a
  nota quebrada; nada estoura.
- **A recuperação:** o próximo bipe é a próxima vez dele; a bomba nunca vai
  abaixo de zero fios nem perde bombas já desarmadas.

## O fim e o vencedor

90 s de `t_jogo`, pelo kit.

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if int(bombas[a]) != int(bombas[b]):
			return int(bombas[a]) > int(bombas[b])
		if int(fios[a]) != int(fios[b]):
			return int(fios[a]) > int(fios[b])
		return int(pontos[a]) > int(pontos[b]))
	return lista
```

`_na_frente(excluir)` usa a mesma ordem.

## Com menos de quatro

- **Três e dois:** a roda do dono; o falso vai para quem está na frente.
- **Um:** só as batidas pares, sem carga nem falso (não há de quem desconfiar).
  `com_poucos()`: `"Sem bipe falso"`.
- **O controle que cai:** os bipes dele não tocam e as notas somem sem erro;
  um falso pendente para ele espera; a carga dele fica.

## O robô

```gdscript
# O robô ouve o ataque do bipe no alto-falante simulado (a lógica de ataque
# da N1) e, se ouviu, corta na batida seguinte quando o bipe era o certo (pela
# partitura: a placa virtual dá o nível, não a altura). Quando não acerta,
# corta 250 ms tarde — ou corta a armadilha. Manda o falso logo que ganha.
var _robo_vale := [1.0, 1.0, 1.0, 1.0]
var _robo_desde := [0.0, 0.0, 0.0, 0.0]
var _robo_ouviu := [{}, {}, {}, {}]  ## meia batida do ataque -> true
var _robo_alvo := [-1.0, -1.0, -1.0, -1.0]
var _robo_decidiu := [-1.0, -1.0, -1.0, -1.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var nivel := float(Forja.som_virtual(l).get("falante", 0.0))
	var agora := Ritmo.t_musica()
	if nivel > 0.12 and nivel - float(_robo_vale[l]) > 0.10 and agora - float(_robo_desde[l]) > 0.08:
		_robo_vale[l] = nivel
		_robo_desde[l] = agora
		_robo_ouviu[l][int(round(Ritmo.batida() * 2.0))] = true
	else:
		_robo_vale[l] = minf(float(_robo_vale[l]), nivel)
	if carga[l]:
		Forja.robo_apertar(l, Forja.TRIANGULO, 0.06)
	for bp in _bipes_de(l):  # os bipes já tocados do lugar, ainda sem decisão: {b, tipo}
		if float(bp.b) == _robo_decidiu[l]:
			continue
		var meia := int(round(float(bp.b) * 2.0))
		if not (_robo_ouviu[l].has(meia) or _robo_ouviu[l].has(meia + 1)):
			continue
		_robo_decidiu[l] = float(bp.b)
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, erra de um jeito ou de outro
		var acerta := Forja.robo_acerta()
		if int(bp.tipo) == CERTO:
			_robo_alvo[l] = float(bp.b) + 1.0 + (0.0 if acerta else 0.25 / (60.0 / Ritmo.bpm))
		elif not acerta:
			_robo_alvo[l] = float(bp.b) + 1.0  # cai na armadilha
	if _robo_alvo[l] >= 0.0 and agora >= Ritmo.t_da_batida(_robo_alvo[l]):
		Forja.robo_apertar(l, Forja.CRUZ, 0.06)
		_robo_alvo[l] = -1.0
```

(`_bipes_de(l)` devolve os bipes que o minigame já tocou para o lugar e cuja
batida de corte ainda não passou — o minigame guarda `_tocados[l]`. O atraso
de 250 ms entra em batidas: `0.25 / (60 / bpm)`.)

## Os ganchos

```gdscript
var _notas := [[], [], [], []]  ## os cortes certos pendentes
var _armadilhas := [[], [], [], []]  ## os cortes proibidos pendentes
var _bipes: Array = []  ## [lugar, batida, tipo] a tocar
var _tocados := [[], [], [], []]
var _ultima := [{}, {}, {}, {}]
var _gerado := 1
var _compasso := 0
var _fora := [false, false, false, false]
var fios := [0, 0, 0, 0]
var bombas := [0, 0, 0, 0]
var carga := [false, false, false, false]
var _falso_para := [false, false, false, false]
var _pulso := [0.0, 0.0, 0.0, 0.0]
var _pisca := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	camera_pos = Vector3(0, 5.6, 11.2)
	camera_olhar = Vector3(0, 1.6, -1.0)
	CenarioDoCanto.montar(self)
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.preso = true
		_montar_a_bomba_e_o_alicate(l, p)
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
		_gerar_compasso(_gerado)  # os bipes; o falso pendente vira FALSO num ERRADO
		_gerado += 1
	var agora := Ritmo.t_musica()
	_tocar_os_bipes(agora)  # CenarioDoCanto.falante, a chamada, a luzinha da bomba; a nota ou a armadilha
	for l in presentes():
		_apagar_o_pulso_e_o_pisca(l, dt)
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_notas[l] = _notas[l].filter(func(nt): return float(nt.t) > agora)
			_armadilhas[l] = _armadilhas[l].filter(func(a): return float(a.t) > agora)
		if Forja.apertou(l, Forja.CRUZ):
			_cortar(l)
		if Forja.apertou(l, Forja.TRIANGULO) and carga[l]:
			_sabotar(l)
		while not _notas[l].is_empty() and agora > float(_notas[l][0].t) + Ritmo.JANELA_BOM:
			var nt: Dictionary = _notas[l].pop_front()
			_ultima[l] = nt
			nota_perdida(l, int(nt.n))  # o fio escapa
		_armadilhas[l] = _armadilhas[l].filter(func(a): return agora <= float(a.t) + Ritmo.JANELA_BOM)


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	marcar(l, Itens.pontos_do_acerto(l, PONTOS[julgamento], julgamento, fmod(float(nt.b), 4.0) == 0.0))
	_cortar_o_fio(l)  # fios, bomba desarmada, bomba nova
	if julgamento == Ritmo.PERFEITO and presentes().size() > 1:
		carga[l] = true
	CenarioDoCanto.luz_da_nota(l, 0.6)
	_pulso[l] = PULSO_S


func falha(l: int) -> void:
	var nt: Dictionary = _ultima[l]
	if bool(nt.get("cortou", false)):
		_estourar(l)  # cortou o certo fora do tempo
	else:
		_fio_escapa(l)
```

`_cortar(l)`: a nota certa a até `JANELA_BOM` → `nt.cortou = true`,
`_ultima[l] = nt`, tira da lista, `julgar_toque`; senão, a armadilha a até
`JANELA_BOM` → `_estourar(l)` e o evento `armadilha`; senão, nada.
`_estourar(l)`: o confete, `explosao`, o laranja (`_pisca[l] = PISCA_ESTOURO`),
`"golpe"` no alto-falante, `fios[l] = 0`. `_sabotar(l)`: o falso para
`_na_frente(l)`.

Catálogo: `"S06_J30"` em `MINIGAMES` e na lista da seção `S06`. O `.uid`.
Traduções: `"Corta-Fio": "Wire Cutter"`, `"Corte!": "Cut!"`,
`"Sem bipe falso": "No fake beeps"`; `dica(l)`: `{"partes": ["@cross", "Corte", "@triangle", "Bipe falso"], ...}`
(o △ só com carga) com `na_raia(l)` e `not aprendeu(l)` (`"Corte": "Cut"`,
`"Bipe falso": "Fake beep"`); `status(l)`: `"%d bombas" % bombas[l]`
(`"%d bombas": "%d bombs"`).

## O que o registro mede

- `som_controle` (H07) de cada bipe; o `jogo` `chamada` com o `tipo`
  (certo, errado, falso) e `no_controle`.
- O `toque` do kit no corte certo (e o perdido: o fio que escapou); o `jogo`
  `armadilha` (cortou depois do estalo ou do falso); o `jogo` `sabotagem`.
- O cruzamento: com `placa`, cortar o certo e deixar o estalo é o ouvido que
  distingue; cortar tudo ou nada, sempre num controle, é o alto-falante que
  não chegou (o jogador chuta).

## Armadilhas

- **A tela nunca diz qual bipe:** a luzinha da bomba pisca igual nos três;
  a barra de luz só pulsa no corte.
- **A armadilha não é nota do kit:** nada de `nova_nota` nem `julgar_toque`
  para ela; o estouro é da própria ficha.
- **O falso vai para quem está na frente**, nunca para quem mandou; com um
  jogador, não existe.
- **Um som por vez no controle** (H07): o bipe seguinte do mesmo lugar vem
  pelo menos meia batida depois; o bipe corta a nota do kit se encostar.
- **Os pontos e o item:** se o kit já aplica `Itens.pontos_do_acerto`, marque cru.

## Pronto quando

O Corta-Fio joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô
nos três temperamentos (o ruim estoura); aguenta o cabo que cai e volta;
fecha com vencedor; a prova do jogo passa; e `bash tests/prova_visual.sh`
passa com a **prancha olhada** com o Corta-Fio nela (na cópia de trabalho,
sem commitar: `"S06_J30"` em primeiro na lista da seção `S06` e `"canto"` no
lugar de `"viga"` em `Partida.NA_ORDEM[5]`; depois volte os dois arquivos).

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, depois das outras da seção:

```gdscript
## Corta-Fio (S06_J30): os bipes chegam ao alto-falante, os três tipos no
## registro, e o falso nunca vai para quem mandou.
func _prova_do_corta_fio() -> void:
	var mg := await _joga_o_minigame("S06_J30", 60.0)
	if mg == null:
		return
	var bipes := _linha_do_tempo().filter(func(e): return e.get("tipo") == "jogo" and e.get("slot") == "S06_J30" and e.get("o") == "chamada")
	var tipos := {}
	for e in bipes:
		tipos[str(e.get("tipo", ""))] = true
	_esperar(tipos.has("certo") and tipos.has("errado"), "Corta-Fio: bipes certos e errados (%s)" % [tipos.keys()])
	var sabotagens := _linha_do_tempo().filter(func(e): return e.get("tipo") == "jogo" and e.get("slot") == "S06_J30" and e.get("o") == "sabotagem")
	_esperar(sabotagens.all(func(e): return int(e.get("para", 0)) != int(e.get("jogador", -1))), "Corta-Fio: o falso nunca volta para quem mandou")
	var v := mg.vencedor()
	_esperar(not v.is_empty() and int(mg.bombas[v[0]]) == v.map(func(l): return int(mg.bombas[l])).max(), "Corta-Fio: vence quem desarmou mais")
```

**O que o André joga e sente** (`./run-local.sh -- --sala=S06_J30`):

- o estalo e o bipe claro se distinguem na mão, com a música;
- o falso engana na primeira vez e dá para aprender a ouvir a diferença;
- a sabotagem faz a sala gritar (o `"especial"` na TV) sem dizer quem foi;
- o confete é engraçado; ninguém sai do jogo.

## Ao terminar

- No [quadro](README.md): a linha **N5** (se não existir, acrescente
  `| [N5](N5-corta-fio.md) | N | S6 — Corta-Fio | M | Sonnet | 1,5 | feito (<commit>) | <gasto> |`),
  com o commit e o gasto real. Com as cinco feitas, a linha **N** da seção
  também vira **feito**.
- Commit sugerido (sem trailer):
  `feat: Corta-Fio — o bipe certo, o estalo e o falso, cada um no seu controle`
