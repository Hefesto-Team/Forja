# O3 — Passo no Fosso

**Sprint:** O · **Slot:** S07_J33 · **Tamanho:** M · **Estimativa:** US$ 1,5 · **Depende de:** H04, F09, H07, O1

## Por quê

Uma corrida no breakbeat: as placas sobre o fosso de plasma afundam na
batida e sobem no contratempo, e a mão pulsa exatamente quando elas sobem. O
verbo é **pisar no contratempo** — o ritmo mais difícil de sentir só de
ouvido fica fácil quando a palma marca. No meio, o vapor cobre as placas e só
a mão continua sabendo.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) e [o kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A ficha-mãe da seção](O-os-caminhos.md) e a [O1](O1-os-caminhos.md) (o `_pista`, o `_respondeu`, a troca)
- [04 — as janelas](../04-ritmo-e-audio.md#as-janelas)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S07_J33",
	"titulo": "Passo no Fosso",
	"verbo": "Pise no contratempo!",
	"genero": "corrida",
	"icone": "haptica",
	"entradas": [Forja.CRUZ],
	"camera": "fixa",
	"faixa": "MUS_S07_J33",
	"duracao": 90.0,
	"fim": "primeiro_a_chegar",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "grama",
	"microjogo": {"verbo": "Pise!", "segundos": 6.0},
	"gesto": "jump",
}
```

O `material` é `grama` (o ruído macio) para o acerto do kit não se confundir
com o pulso da placa, que é `material:metal` (o clique seco).

## Como se joga

A faixa é `MUS_S07_J33`, 150 bpm (uma batida = 0,4 s). `ENTRADA := 4`.

- **As placas (de todos, à vista):** afundam em cada batida inteira e sobem
  em cada contratempo. A altura de toda placa é função da batida:
  `y = -0.35 * (0.5 + 0.5 * cos(TAU * fposmod(b, 1.0)))` — no fundo em
  `b` inteiro, no alto em `b + 0.5`.
- **O pulso na mão:** em **todo** contratempo `k + 0.5` (para `k >= ENTRADA - 1`),
  cada lugar em jogo recebe `material:metal` nos dois atuadores, ganho 0,7
  (`Forja.som_haptica` direto, sem o `_pista`: é metrônomo, não informação).
  No contratempo **da nota dele** o pulso vai pelo `_pista` com ganho 1,0
  (`o_que` = `"contratempo"`), e isso vai para o registro.
- **As notas (o hoqueto):** cada um pisa a cada 2 batidas: o lugar na
  posição `i` de `presentes()` pisa nos contratempos `k + 0.5` com
  `(k - ENTRADA - i) % 2 == 0`. Com quatro, P1 e P3 pisam no "e" do 1 e do 3,
  P2 e P4 no "e" do 2 e do 4 — a frase de passos só fica inteira com todos. A
  nota `n` (contada por lugar) tem alvo `Ritmo.t_da_batida(k + 0.5)` e é
  aberta com `nova_nota` na batida `k`.
- **A entrada e o julgamento:** ✕ → `julgar_toque(l, alvo_da_nota_aberta, n, true)`
  (a placa que afunda é perigo físico: folga para quem está em último). O ✕
  sem nota aberta (duas vezes no mesmo contratempo) não conta.
- **A nota que passa:** sem ✕ até `alvo + JANELA_BOM` → `nota_perdida(l, n)`:
  o boneco ficou na placa, que afunda na batida seguinte — a falha.
- **Pontos e avanço** (`toque`): uma placa por passo; `marcar(l, [0, 50, 75, 100][j])`;
  `_respondeu(l, n, "certo")`.
- **A meta:** `META := 30` placas.
- **A partitura simples** (`Ritmo.simples[l]`): o lugar pisa a cada 4
  batidas (só os `k` com `(k - ENTRADA - i) % 4 == 0`).
- **O pico — o vapor:** 16 batidas a partir de
  `_pico_b := ENTRADA + floor((duracao / _t_batida() - ENTRADA) / 2)`: um
  vapor branco cobre as placas (a malha `vapor` de cada raia aparece e as
  placas ficam `visible = false`); só o pulso na mão marca o contratempo.
  A TV: `Som.tocar("vento", null, -6.0)` na entrada do pico.

`_t_batida()` é `Ritmo.t_da_batida(1.0) - Ritmo.t_da_batida(0.0)`.

## O cenário

- **Chão:** `Kit.arena(self, 5, 3)`; o fosso de cada raia é uma caixa de
  plasma `Kit.caixa(self, Vector3(2.4, 0.05, 12.0), Vector3(RAIAS[l], -0.3, Z_JOGADOR - 5.0), plasma)`
  com `plasma := Kit.material(Tema.CIANO.darkened(0.3), 0.8, 0.9)` (o fosso é
  ambiente, como a lava da Viga: o brilho fica; ciano, que não é cor de
  lugar).
- **As placas:** para cada raia, um `Node3D` `trilho` em
  `(RAIAS[l], 0, Z_JOGADOR)` com `META + 4` placas
  `Kit.caixa(trilho, Vector3(1.4, 0.12, 0.9), Vector3(0, 0, -i * PASSO), metal)`,
  `PASSO := 1.1`, `metal := Kit.material(Color("#5b6275"), 0.0, 0.5)`
  (`metallic` 0,2), e dois rebites `(0.1, 0.04, 0.1)` `#d0d6e0` em cada uma.
  A altura de cada placa é a da fórmula (o `_mostrar(b)` põe o `y` de todas).
- **A margem:** no fim do trilho, `Kit.peca(trilho, "stairs", Vector3(0, 0, -META * PASSO - 0.8), PI)`
  e duas `Kit.peca(trilho, "rocks", ...)` dos lados.
- **O vapor** de cada raia: `Efeitos.poeira(self, Vector3(RAIAS[l], 0.4, Z_JOGADOR - 3.0), Vector3(2.4, 0.8, 7.0), Color("#e8ecf5"), 60)`
  guardado em `_vapor[l]`, `emitting = false` fora do pico.
- **A luz:** a da casa, cheia (corrida, não terror):
  `luzes([Vector3(-9, 3, -4), Vector3(9, 3, -4)])` e
  `atmosfera(Color("#ffb070"), Tema.CIANO, true, 40, 22.0, -7.8, 0.3)`.
- **O boneco:** `raia(l)` e `posicionar(l)` do kit, `p.rotation.y = PI`,
  `p.preso = true`; ele fica parado em `z = Z_JOGADOR` e o trilho desliza:
  `trilho.position.z = Z_JOGADOR + PASSO * lerpf(_de[l], _ate[l], clampf((b - _passo_b[l]) / 0.5, 0.0, 1.0))`.
  No passo, `p.gesto("jump", 0.3)`; na placa, `idle`; o `y` do boneco
  acompanha o da placa em que ele está.
- **A câmera:** `camera_pos = Vector3(0, 7.0, 10.0)`, `camera_olhar = Vector3(0, 0.0, -2.5)`.
- **Checklist de arte (11):** caixas e peças do kit; o emissivo só no plasma
  (ambiente) e na borda da raia; `metallic` 0,2; nenhuma cor de lugar no
  cenário; a prancha com o boneco ao lado.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **háptica (protagonista)** | `material:metal` nos dois atuadores, ganho 0,7; o da sua nota, 1,0 | todo contratempo |
| háptica por material | o pouso: o kit toca `material:grama`; a queda: `Forja.tocar_material(l, "lama", "golpe", 1.0)` (o plasma é "lama" na tabela) | no toque; na falha |
| barra de luz | a cor do lugar; o minigame não chama `Forja.luz` | — |
| alto-falante do dono | a nota dele (kit); `Forja.som_falante(l, "coleta", 0.7)` a cada 10 placas | no toque; nos marcos |
| vibração | o kit | — |
| gatilho | nada a segurar: `Forja.gatilhos_off(l)` | — |
| TV | o breakbeat; o som da nota de cada um (kit); `Som.tocar("falha", pos, -6.0)` e faíscas ciano no escorregão; `Som.tocar("portao", pos)` na margem | — |

**No rádio:** o pulso de todo contratempo vira `Forja.sentir(l, "toque")`
(leve), o da nota `Forja.sentir(l, "acerto")`; a `troca` gravada uma vez. O
acerto do kit também é rumble no rádio: por isso o pulso da nota sai no
contratempo **anterior** ao dela no rádio (`k - 0.5`), nunca no mesmo
instante do acerto (a suspeita e de 05). O microfone não é usado.

## A falha

**O escorregão:** a placa afunda com o boneco em cima — `p.gesto("fall", 0.5)`,
ele desce até `y = -0.6` no plasma, faíscas ciano (`Efeitos.faiscas(self, pos, Tema.CIANO, 16, 0.8)`),
a mão sente a lama. **A recuperação:** volta uma placa (`_de`/`_ate` para
`_dist[l] - 1`, mínimo 0) e sobe nela em duas batidas; a nota seguinte dele
não é aberta (`_subindo_ate[l] = b + 2`: sem nota, sem pulso de nota).

## O fim e o vencedor

Quem chega à placa `META` salta para a margem: `_chegada.append(l)`,
`acabou[l] = true`, `emote-yes`. Na primeira chegada, `_fim_batida = b + 8`;
depois, todos acabam. Sem chegada, o kit fecha no `duracao`. `vencedor()`:
`_chegada`, depois a distância, depois os pontos.

## Com menos de quatro

- **3, 2, 1:** o hoqueto usa a posição em `presentes()`: com dois, um no "e"
  do 1 e do 3, o outro no "e" do 2 e do 4; com um, só o "e" do 1 e do 3.
- **O controle que cai:** nenhuma nota nem pulso para ele; quando volta, a
  primeira nota dele é a do próximo contratempo dele que ainda não passou.
- **Duplas:** não há.

## O robô

Mira pelo relógio da música; o pulso é regular, ele não precisa sentir.

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var n: int = _nota[l]
	if n < 0 or _robo_apertou[l] == n:
		return
	if _robo_nota[l] != n:
		_robo_nota[l] = n
		# o temperamento: quando não acerta, pisa na batida (a placa afundada)
		# ou nem pisa
		if Forja.robo_acerta():
			_robo_mira[l] = 0.0
		else:
			_robo_mira[l] = 0.2 if _robo_rng.randf() < 0.6 else 99.0
	if Ritmo.t_musica() >= float(_alvo[l]) + float(_robo_mira[l]):
		Forja.robo_apertar(l, Forja.CRUZ, 0.05)
		_robo_apertou[l] = n
```

`_nota[l]` é a nota aberta (−1 quando não há) e `_alvo[l]` o alvo dela.

## Os ganchos

`godot/scripts/minigames/s07/passo_no_fosso.gd`, `extends Minigame`.

```gdscript
extends Minigame
## Passo no Fosso (S07_J33). As placas sobre o plasma afundam na batida e
## sobem no contratempo; a mão pulsa quando elas sobem. ✕ no contratempo da sua
## vez pisa na próxima; quem fica afunda com a placa.
##
## A falha: escorrega no plasma e volta uma placa. O vencedor: o primeiro na
## margem. O alto-falante do dono: a coleta a cada 10 placas. O registro mede:
## o pulso da nota de cada um (pista, via háptica ou rumble) e o passo depois
## dele. O robô: pisa pelo relógio da música. Com menos de quatro: o hoqueto
## se reparte. A régua: no pico, sem as placas à vista, só a mão marca o tempo.

const FICHA := { ... }

const ENTRADA := 4
const META := 30
const PASSO := 1.1
const PONTOS := [0, 50, 75, 100]
const PICO_BATIDAS := 16

var _ordem := {}                  ## lugar -> a posição em presentes()
var _nota := [-1, -1, -1, -1]     ## a nota aberta de cada um
var _alvo := [0.0, 0.0, 0.0, 0.0]
var _n := [0, 0, 0, 0]            ## a contagem de notas de cada um
var _k_feito := [-1, -1, -1, -1]  ## a última batida k já tratada
var _pulso_feito := -1            ## o último contratempo com pulso
var _dist := [0, 0, 0, 0]
var _de := [0.0, 0.0, 0.0, 0.0]
var _ate := [0.0, 0.0, 0.0, 0.0]
var _passo_b := [-9.0, -9.0, -9.0, -9.0]
var _subindo_ate := [-1.0, -1.0, -1.0, -1.0]
var _chegada: Array = []
var _fim_batida := -1.0
var _pico_b := 9999.0
var _rumble := [false, false, false, false]
var _fora := [false, false, false, false]
var _nos := {}
var _vapor := {}
var _robo_nota := [-1, -1, -1, -1]
var _robo_apertou := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	papel_som = Forja.PAPEL_HAPTICA
	camera_pos = Vector3(0, 7.0, 10.0)
	camera_olhar = Vector3(0, 0.0, -2.5)
	# o cenário de cima; para cada jogador: _nos[l] = _montar_raia(l); Forja.gatilhos_off(l)


func iniciar_jogo() -> void:
	_pico_b = ENTRADA + floor((duracao / _t_batida() - ENTRADA) / 2.0)
	var ordem := presentes()
	for i in ordem.size():
		_ordem[ordem[i]] = i
		# o rádio: _rumble e a troca (o O1)


func jogar(_dt: float) -> void:
	var b := Ritmo.batida()
	var k := int(floor(b))
	# o pulso de todo contratempo (uma vez por contratempo, para todos)
	if b >= k + 0.5 and _pulso_feito < k and k >= ENTRADA - 1:
		_pulso_feito = k
		_pulsar(k)
	for l in presentes():
		if acabou[l]:
			continue
		if not conectado(l):
			_fora[l] = true
			_nota[l] = -1
			continue
		if _fora[l]:
			_fora[l] = false
			_k_feito[l] = k
		_abrir_nota(l, k)      # na batida k da vez dele: nova_nota com alvo em k + 0,5
		if _nota[l] >= 0:
			if Forja.apertou(l, Forja.CRUZ):
				var n: int = _nota[l]
				_nota[l] = -1
				julgar_toque(l, float(_alvo[l]), n, true)
			elif Ritmo.t_musica() > float(_alvo[l]) + Ritmo.JANELA_BOM:
				var n2: int = _nota[l]
				_nota[l] = -1
				_respondeu(l, n2, "nenhuma")
				nota_perdida(l, n2)
	if _fim_batida > 0.0 and b >= _fim_batida:
		for l in presentes():
			acabou[l] = true
	_mostrar(b)


func toque(l: int, j: int) -> void:
	marcar(l, PONTOS[j])
	_respondeu(l, _n[l] - 1, "certo")
	_avancar(l, 1)


func falha(l: int) -> void:
	_escorregar(l)   # "A falha": fall, faíscas, lama na mão, volta uma placa, _subindo_ate


func vencedor() -> Array:
	var resto := presentes().filter(func(l): return not l in _chegada)
	resto.sort_custom(func(a, b): return _dist[a] > _dist[b] or (_dist[a] == _dist[b] and pontos[a] > pontos[b]))
	return _chegada + resto
```

`_abrir_nota(l, k)`: se `_k_feito[l] < k`, `_k_feito[l] = k`; se é a vez dele
(`(k - ENTRADA - _ordem[l]) % 2 == 0`, ou `% 4` com `Ritmo.simples[l]`),
`b >= _subindo_ate[l]` e `k >= ENTRADA`: `_nota[l] = _n[l]`, `_n[l] += 1`,
`_alvo[l] = Ritmo.t_da_batida(k + 0.5)`, `nova_nota(l, _nota[l], _alvo[l])`.
`_pulsar(k)`: para cada lugar em jogo e conectado, `_pista(...)` se a nota
aberta dele tem alvo em `k + 0.5` (no rádio, o pulso da nota sai no
contratempo anterior — ver "O repertório"), senão
`Forja.som_haptica(l, "material:metal", "material:metal", 0.7)` (no rádio,
`Forja.sentir(l, "toque")`). O `_pista` e o `_respondeu` são os do O1.

Dica: `["@cross"]` sob a raia enquanto `not aprendeu(l)`. `status(l)`:
`"%d de %d" % [_dist[l], META]`.

Catálogo: `"S07_J33"` em `MINIGAMES` e na seção `S07`. Traduções:
`"Passo no Fosso": "Step over the Pit"`, `"Pise no contratempo!": "Step on the offbeat!"`,
`"Pise!": "Step!"`.

## O que o registro mede

- `pista` `mandou` do pulso de cada nota (`o_que` `contratempo`, `via`) e
  `respondeu` (`certo`/`nenhuma`); o desvio de cada passo (`toque`,
  `desvio_ms`) — o contratempo é onde o desvio de quem joga de ouvido mais
  cresce, e a noite compara com o do rádio;
- `som_controle` de todo pulso (a carga contínua nos atuadores, 2,5 por
  segundo por controle), `troca` no rádio.

## Armadilhas

- **O robô sorteia no dele.** `var _robo_rng := RandomNumberGenerator.new()`, com
  `_robo_rng.seed = rng.seed + 99` no `iniciar_jogo()`: o `rng` do kit é do jogo
  (os caminhos, os lados, o Aprendiz), e o robô não pode mudar o que o jogo sorteia
  (a paridade: com robô ou com gente, o mesmo jogo).
- **Rumble e háptica nunca juntos, no rádio.** No rádio o acerto do kit é
  rumble no instante do passo; o pulso da nota sai meio tempo antes (ver "O
  repertório"). No cabo, os dois são háptica e se misturam no mixer — tudo
  bem.
- **A altura das placas é função da batida**, nunca `+= dt`. O mesmo para o
  deslize do trilho.
- **150 bpm:** com o `JANELA_BOM` de 140 ms, o passo na batida (200 ms antes
  ou depois do contratempo) é erro — é a regra, não mude a janela.
- **Na prova o pico não chega** (o fim é pelo `duracao`, em tempo de jogo).
- **`ENTRADA`**: se o kit tiver `BATIDA_DA_PRIMEIRA_NOTA`, use-a.

## Pronto quando

Joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três
temperamentos; aguenta o cabo que cai e volta; fecha com vencedor; a prova do
jogo passa; e `bash tests/prova_visual.sh` passa com a prancha olhada (as
placas subindo e descendo, o boneco nelas, o escorregão visível).

## Provas

Em `godot/testes/prova_do_jogo.gd`, uma `_prova_passo_no_fosso()`:

```gdscript
## S07_J33: o pulso do contratempo chega à placa virtual de todos, o robô
## pisa, e os desvios dos toques ficam dentro da janela no robô bom.
func _prova_passo_no_fosso() -> void:
	var sala = await _comeca_a_sala("S07_J33")
	if sala == null:
		return
	var sentiu := [false, false, false, false]
	var q := 0
	while is_instance_valid(sala) and sala.fase == "jogo" and q < 12000:
		for l in 4:
			if float(Forja.som_virtual(l).get("dir", 0.0)) > 0.05:
				sentiu[l] = true
		await _quadros(1)
		q += 1
	_esperar(sentiu.all(func(s): return s), "fosso: o pulso chegou à mão dos quatro %s" % [sentiu])
	_esperar(is_instance_valid(sala) and sala.fase == "fim", "fosso: fechou")
	if is_instance_valid(sala):
		_esperar(sala._dist.max() >= 1, "fosso: alguém pisou (%s)" % [sala._dist])
		_esperar(sala.colocacao.size() == 4, "fosso: a colocação tem os quatro")
```

No `_prova_do_relatorio()`: os `toque` do `S07_J33` com `julgamento != "erro"`
têm `absf(desvio_ms) <= 140` (o robô bom mira o contratempo, não a batida).

`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**Com o André (local):** `./run-local.sh -- --sala=S07_J33`. O pulso no
contratempo tem de puxar o passo sem pensar; no vapor (o pico), jogar só pela
mão tem de dar. No rádio, o pulso pelo rumble a 150 bpm não pode virar um
zumbido contínuo — se virar, anote na ficha.

## Ao terminar

- No [quadro](README.md), a linha O3: **feito**, com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: Passo no Fosso — a mão marca o contratempo`
