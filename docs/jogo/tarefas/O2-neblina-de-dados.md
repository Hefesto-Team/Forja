# O2 — Neblina de Dados

**Sprint:** O · **Slot:** S07_J32 · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 1,5 · **Depende de:** H04, F09, H07, O1

## Por quê

O terror da seção: neblina total, e só a mão sabe onde há chão. Meio tempo
antes de cada batida, a pedra firme bate na palma; quem salta no firme
avança, quem salta na neblina some no escuro. É a háptica como **informação
privada** (a régua, lição 12): quatro no sofá, cada um com o seu caminho.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) e [o kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A ficha-mãe da seção](O-os-caminhos.md) e a [O1](O1-os-caminhos.md) (o `_pista`, o `_respondeu`, a troca, as linhas `pista`/`troca` no 13)
- [05 — a háptica por material](../05-haptica-e-controle.md#a-háptica-por-material)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S07_J32",
	"titulo": "Neblina de Dados",
	"verbo": "Salte no firme!",
	"genero": "terror",
	"icone": "rumble_direito",
	"entradas": [Forja.CRUZ],
	"camera": "fixa",
	"faixa": "MUS_S07_J32",
	"duracao": 100.0,
	"fim": "primeiro_a_chegar",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "areia",
	"microjogo": {"verbo": "Salte!", "segundos": 6.0},
	"papel_som": Forja.PAPEL_HAPTICA,  # o kit abre este papel de som no entrar() (H08)
	"gesto": "jump",
}
```

O `material` é `areia` de propósito: o acerto do kit toca `material:areia`
(granulado) na mão, e a pista é `material:pedra` (a batida surda) — os dois
não se confundem.

## Como se joga

A faixa é `MUS_S07_J32`, 100 bpm (uma batida = 0,6 s). `BATIDA_DA_PRIMEIRA_NOTA` (4, do kit: H08).

- **O caminho de cada um:** para cada batida `n >= BATIDA_DA_PRIMEIRA_NOTA`, `_firme[l][n]`
  diz se ali há pedra (sorteado com o `RandomNumberGenerator` do lugar, semente
  do kit + `7919 * (l + 1)`): 60% firme, nunca três neblinas seguidas. Gere
  400 batidas no `iniciar_jogo()`.
- **A pista:** em `n - 0.5`, se `_firme[l][n]`, a pedra na mão:
  `_pista(l, "material:pedra", "material:pedra", "aviso", n, "firme")` e
  `nova_nota(l, n, Ritmo.t_da_batida(n))`. Na neblina, **nada** (o silêncio é
  a pista).
- **A entrada:** ✕. No aperto, `m := roundi(Ritmo.batida())`:
  - `_firme[l][m]` e a nota `m` ainda aberta → `julgar_toque(l, Ritmo.t_da_batida(m), m, true)`;
  - neblina em `m` e `absf(Ritmo.t_musica() - Ritmo.t_da_batida(m)) <= Ritmo.JANELA_BOM`
    → **a queda** (`_cair(l, m)`), e `_respondeu(l, m, "errado")`;
  - fora disso, o aperto não conta (salto no vazio entre batidas: o boneco só
    dobra os joelhos, `p.gesto("jump", 0.2)`, sem avançar).
- **A nota que passa:** firme em `n` sem aperto até `t(n) + JANELA_BOM` →
  `_motivo[l] = "hesitou"`, `_respondeu(l, n, "nenhuma")`, `nota_perdida(l, n)`.
- **O hoqueto:** todo mundo salta nas mesmas batidas, mas cada um no seu
  caminho; o som da nota de cada lugar (o kit, `TOM_DO_LUGAR`) só soa quando
  ele pisa firme — a melodia da neblina é a soma dos pés certos.
- **Os pontos e o avanço** (`toque`): uma plataforma por salto julgado;
  `marcar(l, [0, 50, 75, 100][j])`; `_respondeu(l, n, "certo")`.
- **A meta:** `META := 24` plataformas; um marco a cada `MARCO := 4`.
- **A partitura simples** (`Ritmo.simples[l]`): da batida em que ela liga em
  diante, só as batidas pares podem ser firmes (as ímpares viram neblina): o
  caminho fica regular.
- **O pico — a neblina engrossa:** as 16 batidas a partir de
  `_pico_b := BATIDA_DA_PRIMEIRA_NOTA + floor((duracao / _t_batida() - BATIDA_DA_PRIMEIRA_NOTA) / 2)`: a pista
  chega em `n - 0.25` (menos tempo), as lanternas caem para 0,3 e a TV toca
  `Som.tocar("vento", null, -4.0)` na entrada do pico.

## O cenário

- **Chão:** nenhum à vista: `Kit.arena(self, 5, 3)` e, por cima do chão da
  arena, uma laje escura grande (`Kit.caixa(self, Vector3(26, 0.02, 14), Vector3(0, 0.02, 0), Kit.material(Color("#0d0b14"), 0.0, 1.0))`).
- **A luz (terror = a casa escurecida):**
  `atmosfera(Color("#b9b0ff"), Tema.ROXO, false, 70, 22.0, -7.8, 0.05)`;
  duas tochas `#ffb070`, energia 0,35, em `(-9, 3, -5)` e `(9, 3, -5)`;
  `Efeitos.poeira(self, Vector3(0, 0.6, -2), Vector3(24, 1.2, 10), Color("#b9b0ff"), 90)`
  (a neblina rasteira).
- **Cada raia:** `raia(l)` e `posicionar(l)`, `p.rotation.y = PI`,
  `p.preso = true`. Um `Node3D` `caminho` em `(RAIAS[l], 0, Z_JOGADOR)` com
  uma laje de pedra por plataforma já pisada
  (`Kit.caixa(caminho, Vector3(1.3, 0.25, 1.0), Vector3(0, -0.12, -i * PASSO), pedra)`,
  `PASSO := 1.2`, `pedra := Kit.material(Color("#3a3542"), 0.0, 0.95)`),
  criada **quando o boneco pousa nela** (à frente, nada: é neblina). A cada
  `MARCO` plataformas, um marco: `Kit.peca(caminho, "wood-support", Vector3(0.8, 0, -i * PASSO), 0.0, 1.2)`
  com uma `OmniLight3D` `#ffb070`, energia 0,6, alcance 2,5, no alto dele.
  O portão no fim: `Kit.peca(caminho, "gate", Vector3(0, 0, -META * PASSO - 0.6))`.
- **A lanterna** de cada boneco: `OmniLight3D` na cor do lugar clareada
  (`lerp(Color.WHITE, 0.55)`), energia 1,0, alcance 2,4, em `(RAIAS[l], 2.4, Z_JOGADOR + 0.4)`.
- **A câmera:** `camera_pos = Vector3(0, 6.4, 9.8)`, `camera_olhar = Vector3(0, 0.3, -2.0)`.
- **O movimento, pela batida:** `caminho.position.z = Z_JOGADOR + PASSO * lerpf(_de[l], _ate[l], clampf((b - _salto_b[l]) / 0.5, 0.0, 1.0))`;
  o boneco faz `jump` no meio tempo do salto e `idle` no resto. Na queda,
  `p.position.y` desce de 0,1 a −2,5 em uma batida (`fall`), some
  (`p.visible = false`) por meia batida e volta no marco (`_de`/`_ate` para o
  marco, `p.visible = true`, `p.position.y = 0.1`).
- **Checklist de arte (11):** só caixas e peças do kit; nenhum emissivo novo
  (a luz do marco é luz, não malha que brilha); nada nas cores dos lugares
  além da lanterna do dono; a prancha com um boneco ao lado.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **háptica (protagonista)** | `material:pedra` nos dois atuadores: há chão | meio tempo antes de cada batida firme (no pico, um quarto) |
| háptica por material | o pouso: o kit toca `material:areia` (o acerto) | no toque |
| barra de luz | a cor do lugar a 30%: `Forja.luz(l, Forja.cor_do_lugar(l).darkened(0.7))` no `iniciar_jogo()` (o kit devolve a luz do lugar no fim) | o jogo inteiro |
| alto-falante do dono | a nota dele (kit); `Forja.som_falante(l, "coleta", 0.7)` em cada marco; `Forja.som_falante(l, "nota_quebrada:%d" % l, 0.7)` na queda | no pouso, no marco, na queda |
| vibração | o kit (acerto, erro); a queda: `Forja.sentir(l, "golpe")` | na queda |
| gatilho | nada a segurar: `Forja.gatilhos_off(l)` | — |
| TV | a música quase sem bateria; `Som.tocar("vento", pos, -8.0)` na queda; `Som.tocar("portao", pos)` na chegada | — |

**No rádio:** a pedra vai como `Forja.sentir(l, "aviso")` (o `_pista` do O1),
com a `troca` gravada uma vez. O microfone não é usado.

## A falha

- **A queda** (saltou na neblina): `p.gesto("fall", 0.6)`, o boneco afunda na
  neblina e some; a mão sente o golpe; a TV sopra o vento; ele volta ao
  último marco (`_dist[l] = floor(_dist[l] / MARCO) * MARCO`), meia batida
  depois. As lajes depois do marco somem. As notas firmes que caem durante a
  queda (uma batida) não contam (`_caindo_ate[l]`: sem pista, sem nota).
- **Hesitou** (a pedra passou sem salto): `p.gesto("emote-no", 0.4)`; o
  boneco fica na mesma plataforma, nada mais.

## O fim e o vencedor

Quem pousa na plataforma `META` chega: `_chegada.append(l)`,
`acabou[l] = true`, `p.gesto("emote-yes", 1.2)`, a coleta no alto-falante.
Na primeira chegada, `_fim_batida = b + 8`; depois dela todos acabam. Sem
chegada, o kit fecha no `duracao`. `vencedor()`: `_chegada`, depois os outros
pela distância, depois pelos pontos.

## Com menos de quatro

- **3, 2, 1:** nada muda; cada um tem o seu caminho. Com um, ele corre contra
  o portão.
- **O controle que cai:** sem controle, nenhuma pista nem nota para ele
  (`_fora[l] = true`); quando volta, a próxima batida firme a partir de
  `ceili(b + 1)` é a primeira que vale (as do meio não viram erro).
- **Duplas:** não há.

## O robô

Sente a pedra na placa virtual (ou nos motores, no rádio), mira pelo relógio
da música e erra pelo temperamento.

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var b := Ritmo.batida()
	var n := ceili(b)
	# a janela de sentir: da pista (n - 0,5) até pouco antes da batida; o
	# pouso anterior (areia, 0,14 s) já passou
	if b > n - 0.55 and b < n - 0.05:
		var s := _robo_sente(l)
		if s.x + s.y > 0.05:
			_robo_firme[l] = n
	if _robo_firme[l] != n or _robo_saltou[l] == n:
		return
	if _robo_decidiu[l] != n:
		_robo_decidiu[l] = n
		var certo := Forja.robo_acerta()
		_robo_mira[l] = 0.0 if certo else (0.25 if _robo_rng.randf() < 0.5 else -1.0)
	if float(_robo_mira[l]) < 0.0:
		# erra saltando na neblina: a próxima batida sem pedra
		var m := n + 1
		if Ritmo.t_musica() >= Ritmo.t_da_batida(m):
			Forja.robo_apertar(l, Forja.CRUZ, 0.05)
			_robo_saltou[l] = n
		return
	if Ritmo.t_musica() >= Ritmo.t_da_batida(n) + float(_robo_mira[l]):
		Forja.robo_apertar(l, Forja.CRUZ, 0.05)
		_robo_saltou[l] = n


## O que a mão do controle simulado sente agora: (esquerda, direita).
func _robo_sente(l: int) -> Vector2:
	if _rumble[l]:
		var pc := Forja.percepcao(l)
		return Vector2(float(pc.get("forte", 0.0)), float(pc.get("fraco", 0.0)))
	var v := Forja.som_virtual(l)
	return Vector2(float(v.get("esq", 0.0)), float(v.get("dir", 0.0)))
```

(A batida `n + 1` do erro "salta na neblina" nem sempre é neblina; quando é
firme, o salto só sai atrasado — também é erro. Está certo: o ruim erra de
jeitos diferentes.)

## Os ganchos

`godot/scripts/minigames/s07/neblina_de_dados.gd`, `extends Minigame`.

```gdscript
extends Minigame
## Neblina de Dados (S07_J32). Neblina total: meio tempo antes de cada batida
## em que há pedra, a pedra bate na mão (só na sua). ✕ no tempo salta para
## ela; saltar onde a mão ficou calada é cair na neblina.
##
## A falha: some no escuro e volta ao último marco. O vencedor: o primeiro no
## portão. O alto-falante do dono: a coleta em cada marco, a nota quebrada na
## queda. O registro mede: cada pedra mandada (pista, via), o salto depois
## dela (pista respondeu) e o salto na neblina. O robô: sente a pedra na
## placa virtual. Com menos de quatro: nada muda. A régua: a tela não mostra o
## caminho; sem o controle não se joga — é a seção dele.

const FICHA := { ... }

const META := 24
const MARCO := 4
const PASSO := 1.2
const PONTOS := [0, 50, 75, 100]
const FIRME_CHANCE := 0.6
const PICO_BATIDAS := 16

var _rng := {}
var _firme := [[], [], [], []]   ## lugar -> [bool por batida]
var _aberta := [{}, {}, {}, {}]  ## lugar -> {n: true} as notas firmes à espera
var _pistas := [-1, -1, -1, -1]  ## a última batida cuja pista já saiu
var _dist := [0, 0, 0, 0]
var _de := [0.0, 0.0, 0.0, 0.0]
var _ate := [0.0, 0.0, 0.0, 0.0]
var _salto_b := [-9.0, -9.0, -9.0, -9.0]
var _caindo_ate := [-1.0, -1.0, -1.0, -1.0]
var _motivo := ["", "", "", ""]
var _chegada: Array = []
var _fim_batida := -1.0
var _pico_b := 9999.0
var _rumble := [false, false, false, false]
var _fora := [false, false, false, false]
var _nos := {}
var _robo_firme := [-1, -1, -1, -1]
var _robo_saltou := [-1, -1, -1, -1]
var _robo_decidiu := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	camera_pos = Vector3(0, 6.4, 9.8)
	camera_olhar = Vector3(0, 0.3, -2.0)
	# ... o cenário de cima; para cada jogador: _nos[l] = _montar_raia(l); Forja.gatilhos_off(l)


func iniciar_jogo() -> void:
	_pico_b = BATIDA_DA_PRIMEIRA_NOTA + floor((duracao / _t_batida() - BATIDA_DA_PRIMEIRA_NOTA) / 2.0)
	for l in presentes():
		# o rng do lugar, o caminho (_gerar), o rádio (_rumble e a troca), a luz a 30%
		Forja.luz(l, Forja.cor_do_lugar(l).darkened(0.7))


func jogar(_dt: float) -> void:
	var b := Ritmo.batida()
	for l in presentes():
		if acabou[l]:
			continue
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_aberta[l].clear()
			_pistas[l] = ceili(b + 1) - 1
		_pistas_na_mao(l, b)       # a pedra de n em n - 0,5 (no pico, n - 0,25); abre a nota
		if Forja.apertou(l, Forja.CRUZ) and b >= _caindo_ate[l]:
			_salto(l)
		_notas_que_passaram(l)     # firme sem salto: "hesitou", nenhuma, nota_perdida
	if _fim_batida > 0.0 and b >= _fim_batida:
		for l in presentes():
			acabou[l] = true
	_mostrar(b)


func toque(l: int, j: int) -> void:
	marcar(l, PONTOS[j])
	_pousar(l)   # _dist += 1, a laje nova, o marco (coleta), a chegada


func falha(l: int) -> void:
	if _motivo[l] == "hesitou":
		jogador(l).gesto("emote-no", 0.4)
	# (o erro de tempo num salto para a pedra também chega aqui: "hesitou")


func vencedor() -> Array:
	var resto := presentes().filter(func(l): return not l in _chegada)
	resto.sort_custom(func(a, b): return _dist[a] > _dist[b] or (_dist[a] == _dist[b] and pontos[a] > pontos[b]))
	return _chegada + resto
```

O `_salto(l)` faz o que "A entrada" diz (a nota firme aberta mais perto vai
para `julgar_toque`, com `_motivo[l] = "hesitou"` antes, e sai de `_aberta`);
o `_cair(l, m)` faz a queda de "A falha" (`Forja.sentir(l, "golpe")`, a nota
quebrada no alto-falante, `Som.tocar("vento", ...)`, `_caindo_ate[l] = b + 1.5`,
o `_dist` volta ao marco). O `_pista` e o `_respondeu` são os do O1, iguais.
A dica: `["@cross"]` sob a raia enquanto `not aprendeu(l)`. O `status(l)`:
`"%d de %d" % [_dist[l], META]`.

Catálogo: `"S07_J32"` em `MINIGAMES` e na lista da seção `S07`, depois do
`S07_J31`. Traduções: `"Neblina de Dados": "Data Fog"`,
`"Salte no firme!": "Jump on solid ground!"`, `"Salte!": "Jump!"`.

`_t_batida()` (a duração de uma batida, em s, para o pico):
`return Ritmo.t_da_batida(1.0) - Ritmo.t_da_batida(0.0)`.

## O que o registro mede

- `pista` `mandou` de cada pedra (`o_que` `firme`, `via`) e `respondeu`
  (`certo` no salto julgado, `nenhuma` na pedra que passou, `errado` no salto
  na neblina) — é daqui que a noite tira "P3 respondeu às pistas só de
  háptica em 71% das vezes";
- `troca` no rádio; `som_controle` de cada pedra; `nota`, `toque` (o kit).

## Armadilhas

- **O robô sorteia no dele.** `var _robo_rng := RandomNumberGenerator.new()`, com
  `_robo_rng.seed = rng.seed + 99` no `iniciar_jogo()`: o `rng` do kit é do jogo
  (os caminhos, os lados, o Aprendiz), e o robô não pode mudar o que o jogo sorteia
  (a paridade: com robô ou com gente, o mesmo jogo).
- **Duas coisas na háptica ao mesmo tempo.** O pouso (areia, 0,14 s) sai na
  batida `n`; a próxima pedra, em `n + 0.5` (no pico, `n + 0.75`). A 100 bpm
  sobra tempo; não suba o andamento nem a antecedência.
- **Rumble e háptica nunca juntos** (a suspeita e): a queda chama `sentir`
  (250 ms) na batida `m`; a próxima pedra sai em `m + 0.5` (300 ms depois).
  Não mande pista durante `_caindo_ate`.
- **A luz a 30%** é o piso da F04: não escureça mais. O kit devolve a cor do
  lugar no fim (`Forja.silencio` no `terminar`).
- **Na prova, o pico não chega** (o fim é pelo `duracao`, em tempo de jogo;
  a 16× a música anda uns 6 s). A prova confere as pistas, os saltos e o fim.
- **O `rng` por lugar**, como no O1.

## Pronto quando

Joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três
temperamentos; aguenta o cabo que cai e volta; fecha com vencedor; a barra de
luz fica na cor do lugar (30%) e volta no fim; a prova do jogo passa; e
`bash tests/prova_visual.sh` passa com a prancha olhada (a neblina não pode
virar tela vazia: o boneco, a lanterna e as lajes pisadas têm de aparecer).

## Provas

Em `godot/testes/prova_do_jogo.gd`, uma `_prova_neblina()` chamada no
percurso depois da dos Caminhos:

```gdscript
## S07_J32: as pedras chegam à placa virtual de cada um, o robô salta nelas, e
## a luz de cada controle fica na cor do lugar, mais fraca, até o fim.
func _prova_neblina() -> void:
	# a espera é a do `_joga_o_minigame` da H08: o aviso em quadros, o jogo pelo relógio de parede (100 s de música e o treino)
	var sentiu := [false, false, false, false]
	var luz_ok := [true]
	var q := [0]
	var olhar := func(_s) -> void:
		q[0] += 1
		for l in 4:
			if float(Forja.som_virtual(l).get("esq", 0.0)) > 0.05:
				sentiu[l] = true
			if q[0] > 60:
				var c: Color = _perc(l).get("luz", Color.BLACK)
				var alvo := Forja.cor_do_lugar(l).darkened(0.7)
				if Vector3(c.r - alvo.r, c.g - alvo.g, c.b - alvo.b).length() > 0.08:
					luz_ok[0] = false
	var sala = await _joga_o_minigame("S07_J32", 140.0, olhar)
	if sala == null:
		return
	_esperar(sentiu.all(func(s): return s), "neblina: a pedra chegou à mão dos quatro %s" % [sentiu])
	_esperar(luz_ok[0], "neblina: a luz ficou na cor do lugar, a 30%")
	_esperar(sala._dist.max() >= 1, "neblina: alguém pousou numa pedra (%s)" % [sala._dist])
	_esperar(sala.colocacao().size() == 4, "neblina: a colocação tem os quatro")
```

No `_prova_do_relatorio()`: `pista` do `S07_J32` com `evento == "respondeu"`
e `resposta == "certo"` ≥ 1.

`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**Com o André (local):** `./run-local.sh -- --sala=S07_J32`, com um controle
no cabo e um no rádio. No cabo, a pedra tem de ser inconfundível na palma e
chegar com tempo de reagir; no rádio, o `aviso` pelo rumble tem de dar para
jogar, pior. A queda tem de ser engraçada, não frustrante (volta rápida ao
marco). A neblina do pico tem de assustar sem apagar o boneco.

## Ao terminar

- No [quadro](README.md), a linha O2: **feito**, com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: Neblina de Dados — só a mão sabe onde há chão`
