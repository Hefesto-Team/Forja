# P3 — Zero Absoluto

**Sprint:** P · **Slot:** S08_J38 · **Tamanho:** M · **Depende de:** H04, H08, F09, H07, G08, P1

## Por quê

Batatinha frita no gelo. Enquanto a música toca, todos marcham para o
guardião; quando ela para, ele se vira e **escuta** — quem faz barulho
congela. O verbo é o contrário da seção: **calar**. E o botão do mudo é o
escudo, com três cargas: a luz laranja acesa no silêncio é o "estou seguro,
posso rir". É o terror da seção, e o momento em que o sofá inteiro segura o
riso.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) e [o kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A ficha-mãe da seção](P-a-voz.md) e a [P1](P1-a-voz.md): **o ouvido** (`_ouvir`, as constantes, o "sem microfone") — copie igual
- A G08 (o guardião de pedra em blocos: a mesma montagem, outro material)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S08_J38",
	"titulo": "Zero Absoluto",
	"verbo": "Silêncio!",
	"genero": "terror",
	"icone": "microfone",
	"entradas": [Forja.CRUZ, Forja.MICROFONE],
	"camera": "fixa",
	"faixa": "MUS_S08_J38",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "aviso"],
	"material": "gelo",
	"microjogo": {"verbo": "Silêncio!", "segundos": 6.0},
	"papel_som": Forja.PAPEL_MICROFONE,  # o kit abre este papel de som no entrar() (H08)
	"gesto": "walk",
}
```

## Como se joga

A faixa é `MUS_S08_J38`, 120 bpm (uma batida = 0,5 s), que **para por quatro
tempos e volta**: na batida `M` de cada ciclo, `Ritmo.calar(4)` (8 no pico),
da H08 — a música cala e o relógio segue. `BATIDA_DA_PRIMEIRA_NOTA` (4, do kit: H08).

- **O ciclo** `c` começa em `_g0` e tem a marcha de `M = _marcha_de(c)`
  batidas (`MARCHA_1 := 4` no primeiro ciclo — o susto chega logo —,
  `MARCHA := 12` nos outros) e o silêncio de 4 (8 no pico):

  | batidas do ciclo | o que acontece |
  | --- | --- |
  | 0 a `M - 1` | **a marcha:** a música toca, o guardião olha a parede; ✕ em cada batida é um passo (a nota) |
  | `M - 2` | o guardião começa a virar; o sino do aviso no alto-falante de cada um (`Forja.som_falante(l, "pronto", 0.6)`); a vibração `aviso` (a mão sabe antes do olho) |
  | `M` a `M + 3` | **o silêncio:** o guardião escuta, olhos acesos; quem faz barulho congela |

  O ciclo seguinte começa em `_g0 + M + 4` (no pico, `+ 8`).

- **Os passos** (as batidas 0 a `M - 1`): cada batida é uma nota do lugar
  (`nova_nota` meia batida antes); ✕ → `julgar_toque(l, t(bn), n)`; cada
  passo julgado avança uma laje (`_dist[l] += 1`) e marca `[0, 50, 75, 100][j]`;
  sem ✕ → `nota_perdida` (pisa em falso: não avança). Com
  `Ritmo.simples[l]`, só as batidas pares são notas.
- **O silêncio** (as batidas `M` a `M + 3`), para cada lugar vivo, conectado e que não
  está congelado:
  - **o barulho da voz:** o ouvido da P1 marca o lugar como falando (a regra
    do ar vale: a gargalhada é de quem ri mais alto) por mais de
    `BARULHO_S := 0.15` s de música seguidos → **congela**;
  - **o barulho do pé:** qualquer ✕ → **congela**;
  - **o escudo:** quem está mudo (`_mudo[l]`) não é ouvido — pode rir.
- **O escudo** (o Botão do microfone): apertado entre a batida `M - 2` e a
  `M` do ciclo, gasta uma carga (`_cargas[l]`, começa em `CARGAS := 3`), liga o mudo
  (`_mudo[l] = true`, `Forja.led_mic(l, 1)`) e o protege naquele silêncio; o
  mudo desliga sozinho no fim do silêncio (`Forja.led_mic(l, 0)`). Sem carga, o
  botão não faz nada. Fora dessa janela, o botão também não faz nada (é
  escudo, não mudo solto).
- **Congelado:** o lugar perde a próxima marcha inteira (as notas dela não
  abrem) e recua uma laje (`_dist[l] = maxf(0.0, _dist[l] - 1.0)`).
- **O hoqueto:** a marcha é de todos no mesmo tempo (é uma marcha); a nota de
  cada lugar soa na TV (kit) — a marcha só fica inteira se todos pisam.
- **O pico — o guardião desconfia:** o ciclo do meio
  (`_pico_c := floor(ciclos_previstos / 2)`) tem **oito** batidas de silêncio;
  ninguém sabe quando ele vai voltar a olhar a parede.

`ciclos_previstos = floor((duracao / _t_batida() - BATIDA_DA_PRIMEIRA_NOTA) / 16)`.

## O cenário

- **A caverna de gelo (terror = a casa escurecida):** `Kit.arena(self, 5, 3)`;
  `atmosfera(Color("#cfe8ff"), Tema.CIANO, false, 60, 22.0, -7.8, 0.08)` (a
  neve fina); tochas `#ffb070` a 0,35 em `(-9, 3, 2)` e `(9, 3, 2)`.
- **O guardião de gelo** no fundo, em `(0, 3.05, -4.6)`: a montagem em blocos
  da G08 (a cabeça, o corpo de `wall` e as `column` de orelha), com a pedra
  trocada por gelo fosco `Kit.material(Color("#7f9fb8"), 0.0, 0.9)` e os olhos
  emissivos `Tema.CIANO` (energia 0 na marcha, 4 no silêncio). Ele gira no
  eixo y: de costas (`rotation.y = PI`) na marcha, de frente no silêncio; a
  virada anda da batida `M - 2` à `M` por `lerpf` (pela batida).
- **Cada raia:** `raia(l)` e `posicionar(l)`, `p.rotation.y = PI` (andando
  para o guardião), `p.preso = true`. A trilha de gelo: um `Node3D` com
  `META + 4` lajes `Kit.caixa(trilha, Vector3(1.4, 0.05, 0.9), Vector3(0, 0.03, -i * PASSO), gelo_chao)`
  (`PASSO := 0.5`, `gelo_chao := Kit.material(Color("#9fc6e0"), 0.0, 0.5)`),
  que desliza pela batida (`lerpf` na meia batida depois do passo). A lanterna
  do boneco na cor do lugar clareada, energia 0,9.
- **O bloco de gelo** do congelado: `Kit.caixa(self, Vector3(1.1, 2.0, 1.1), pos_do_boneco + Vector3(0, 1.0, 0), gelo_bloco)`
  com `gelo_bloco := Kit.material(Color("#bfe6ff"), 0.0, 0.4)` e
  `transparency` alfa 0,7; aparece no congelamento, some quando a marcha
  seguinte acaba.
- **A barra de luz no silêncio:** a cor do lugar a 30%
  (`Forja.luz(l, Forja.cor_do_lugar(l).darkened(0.7))` na batida `M`,
  `Forja.luz_do_lugar(l)` no fim do silêncio) — a sala inteira prende a respiração.
- **A câmera:** `camera_pos = Vector3(0, 6.2, 10.4)`, `camera_olhar = Vector3(0, 1.4, -2.0)`.
- **Checklist de arte (11):** o guardião é o da G08 (blocos, sem esfera); o
  gelo fosco, alfa só no bloco; o emissivo nos olhos e na borda da raia;
  nenhuma cor de lugar no gelo.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **microfone (protagonista)** | o que o guardião escuta | no silêncio |
| **luz do mudo** | o escudo aceso (`led_mic(l, 1)`) no silêncio de quem gastou carga | o silêncio |
| vibração | o aviso da virada: `Forja.sentir(l, "aviso")` na batida `M - 2`; congelou: `Forja.sentir(l, "golpe")` | `M - 2`; no congelamento |
| barra de luz | a cor do lugar; a 30% no silêncio | o silêncio |
| alto-falante do dono | o sino do aviso (`pronto`, 0,6) na batida `M - 2`; `Forja.som_falante(l, "clique", 0.7)` ao gastar carga; a nota quebrada ao congelar (`nota_quebrada:<l>`) | `M - 2`; no escudo; no congelamento |
| háptica por material | o passo no gelo: o kit (`material:gelo`, um atuador só, no cabo) | no toque |
| gatilho | nada a segurar: `Forja.gatilhos_off(l)` | — |
| TV | a música que para; no silêncio, só o vento (`Som.tocar("vento", null, -12.0)` na batida `M`); `Som.tocar("carimbo", pos, -2.0)` (o estalo do gelo) no congelamento | — |

**No rádio:** sem placa de áudio não há microfone nem alto-falante: o lugar
entra no "sozinho" abaixo desde o começo (a `troca` `de` `microfone` `para` `sem_microfone`), os
sons do alto-falante não soam, e a háptica do kit vai pelo rumble. A luz do
mudo é saída HID e passa pela ponte.

**Sem microfone / mudo no sistema** (a P1): o guardião não o ouve — por isso
ele anda mais devagar: cada passo vale `0.8` de laje (`_dist` é `float`) e as
cargas dele são 0; a `troca` uma vez. O pé (✕ no silêncio) congela igual.

## A falha

- **Congelou:** o bloco de gelo nasce em volta do boneco, que fica em
  `emote-no` parado dentro dele; a mão sente o golpe; o gelo estala na TV;
  ele recua uma laje e perde a próxima marcha.
- **Pisou em falso** (a nota da marcha que passou): o boneco escorrega no
  gelo (`fall` curto, 0,3 s) e não avança.

## O fim e o vencedor

O kit fecha no `duracao` (90 s). `vencedor()`: quem chegou mais longe
(`_dist`), depois menos congelamentos (`_congelou[l]`), depois pontos.

## Com menos de quatro

- **3, 2, 1:** nada muda (a regra do ar com um só microfone é trivial).
- **O controle que cai:** sem controle não marcha e **não congela** (o
  guardião o ignora); volta na marcha seguinte.
- **Duplas:** não há.

## O robô

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var b := Ritmo.batida()
	var c: int = _c
	var g0: float = _g0
	# a marcha: ✕ em cada nota aberta
	var n: int = _nota[l]
	if n >= 0 and _robo_apertou[l] != n:
		if _robo_nota[l] != n:
			_robo_nota[l] = n
			_robo_mira[l] = 0.0 if Forja.robo_acerta() else 0.25
		if Ritmo.t_musica() >= float(_alvo[l]) + float(_robo_mira[l]):
			Forja.robo_apertar(l, Forja.CRUZ, 0.05)
			_robo_apertou[l] = n
	# o silêncio: decide uma vez por ciclo
	var m := float(_marcha_de(c))
	if _robo_ciclo[l] != c and b >= g0 + m - 1.8:
		_robo_ciclo[l] = c
		var certo := Forja.robo_acerta()
		if certo and _cargas[l] > 0 and _robo_rng.randf() < 0.3:
			Forja.robo_apertar(l, Forja.MICROFONE, 0.08)   # gasta o escudo e ri à vontade
			_robo_ri[l] = true
		else:
			_robo_ri[l] = not certo                        # o ruim ri sem escudo
	if _robo_ri[l] and b >= g0 + m + 1.0 and _robo_riu[l] != c:
		_robo_riu[l] = c
		Forja.robo_falar(l, 0.7, 0.4)
```

## Os ganchos

`godot/scripts/minigames/s08/zero_absoluto.gd`, `extends Minigame`.

```gdscript
extends Minigame
## Zero Absoluto (S08_J38). Batatinha frita no gelo: enquanto a música toca,
## ✕ no tempo marcha para o guardião; quando ela para, ele se vira e escuta —
## quem faz barulho (a voz, ou o pé) congela. O Botão do microfone é o escudo,
## com três cargas: a luz dele acesa no silêncio é o "pode rir".
##
## A falha: congela no gelo, recua e perde a próxima marcha. O vencedor: quem
## chegou mais longe. O alto-falante do dono: o sino da virada, o clique do
## escudo. O registro mede: a voz no silêncio (voz), o escudo (led_microfone),
## e a marcha no tempo. O robô: marcha pelo relógio, às vezes ri. Com menos
## de quatro: nada muda. A régua: "Silêncio!" basta; nada pergunta nada.

const FICHA := { ... }

const MARCHA_1 := 4
const MARCHA := 12
const SILENCIO := 4
const SILENCIO_PICO := 8
const CARGAS := 3
const BARULHO_S := 0.15
const PASSO := 0.5
const META := 60        ## as lajes até o guardião (ninguém chega fácil)
const PONTOS := [0, 50, 75, 100]
# ... e as do ouvido (a P1)

var _c := 0                        ## o ciclo da vez
var _g0 := float(BATIDA_DA_PRIMEIRA_NOTA)          ## o começo dele
var _nota := [-1, -1, -1, -1]
var _alvo := [0.0, 0.0, 0.0, 0.0]
var _n := [0, 0, 0, 0]
var _feita := [-1.0, -1.0, -1.0, -1.0]
var _dist := [0.0, 0.0, 0.0, 0.0]
var _cargas := [CARGAS, CARGAS, CARGAS, CARGAS]
var _congelado_ate := [-1.0, -1.0, -1.0, -1.0]
var _congelou := [0, 0, 0, 0]
var _barulho_desde := [-1.0, -1.0, -1.0, -1.0]
var _pico_c := 999
var _nos := {}
var _guardiao := {}
# o ouvido (a P1)
var _robo_nota := [-1, -1, -1, -1]
var _robo_apertou := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]
var _robo_ciclo := [-1, -1, -1, -1]
var _robo_ri := [false, false, false, false]
var _robo_riu := [-1, -1, -1, -1]


func montar() -> void:
	camera_pos = Vector3(0, 6.2, 10.4)
	camera_olhar = Vector3(0, 1.4, -2.0)
	# a caverna, o guardião de gelo, as trilhas; gatilhos_off


func iniciar_jogo() -> void:
	# o _pico_c; sem microfone (a P1: _cargas = 0 para ele); led_mic(l, 0)
	pass


func jogar(dt: float) -> void:
	var b := Ritmo.batida()
	_ouvir(dt)
	var m := float(_marcha_de(_c))
	var fim_ciclo := _g0 + m + (SILENCIO_PICO if _c == _pico_c else SILENCIO)
	if b >= fim_ciclo:
		_c += 1
		_g0 = fim_ciclo
		for l in presentes():
			if _mudo[l]:
				_mudo[l] = false
				Forja.led_mic(l, 0)
			if conectado(l):
				Forja.luz_do_lugar(l)
	m = float(_marcha_de(_c))
	var fase_b := b - _g0
	for l in presentes():
		if not conectado(l):
			_nota[l] = -1
			continue
		if fase_b < m:
			_marcha(l, b, fase_b)        # abre a nota da próxima batida; ✕ julga; a que passou é pisar em falso
		if fase_b >= m - 2.0 and fase_b < m:
			_escudo(l)                    # o Botão do microfone, com carga
		if fase_b >= m:
			_escuta(l, b)                 # a voz por BARULHO_S, ou ✕: congela
	_virada(fase_b, m)                    # em M - 2: o sino e o aviso de cada um; em M: Ritmo.calar(4 ou 8, H08), a luz a 30%, o vento


func _marcha_de(c: int) -> int:
	return MARCHA_1 if c == 0 else MARCHA
	_mostrar(b)


func toque(l: int, j: int) -> void:
	marcar(l, PONTOS[j])
	_dist[l] += 0.8 if _sem_mic[l] else 1.0


func falha(l: int) -> void:
	jogador(l).gesto("fall", 0.3)   # pisou em falso


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if _dist[a] != _dist[b]:
			return _dist[a] > _dist[b]
		if _congelou[a] != _congelou[b]:
			return _congelou[a] < _congelou[b]
		return pontos[a] > pontos[b])
	return lista
```

`_marcha(l, b, fase_b)`: se `b < _congelado_ate[l]`, nada (congelado); a
próxima batida inteira `bn` da marcha (`_g0 + 0` a `_g0 + M - 1`, as pares com
`Ritmo.simples[l]`) abre meia batida antes, como na P1 (`_feita`); ✕ com
nota aberta → `julgar_toque`; a nota que passou → `nota_perdida`.
`_escuta(l, b)`: se `_mudo[l]` ou congelado, nada; ✕ → `_congelar(l, b)`;
`_falando[l]` → marca `_barulho_desde[l]` (tempo de música) e, passado
`BARULHO_S`, `_congelar(l, b)`; parou de falar → `_barulho_desde[l] = -1`.
`_congelar(l, b)`: o bloco, o golpe, o estalo, a nota quebrada,
`_dist[l] = maxf(0.0, _dist[l] - 1.0)`, `_congelou[l] += 1`,
`_congelado_ate[l]` = o fim da marcha do ciclo seguinte (ele a perde inteira).
`_escudo(l)`: `Forja.apertou(l, Forja.MICROFONE)` com `_cargas[l] > 0` e
ainda não mudo → `_cargas[l] -= 1`, `_mudo[l] = true`, `Forja.led_mic(l, 1)`,
o clique no alto-falante.

Dica: `["@cross"]` na marcha e `["@mic"]` entre as batidas `M - 2` e `M` enquanto
`not aprendeu(l)`. `status(l)`: `"%d escudos" % _cargas[l]`.

Catálogo: `"S08_J38"` em `MINIGAMES` e na seção `S08`. Traduções:
`"Zero Absoluto": "Absolute Zero"`, `"Silêncio!": "Silence!"`,
`"%d escudos": "%d shields"`.

`_t_batida()` (a duração de uma batida, em s, para o pico):
`return Ritmo.t_da_batida(1.0) - Ritmo.t_da_batida(0.0)`.

## O que o registro mede

- `voz` no silêncio (quem fez barulho, o nível e o piso — e quantas vezes o
  barulho era da sala inteira e a regra do ar escolheu o mais alto);
- `saida` `led_microfone` de cada escudo, com `seq` e `ok`, e o botão pelas
  medidas;
- a marcha (`nota`/`toque`); `troca` `de` `microfone` `para` `sem_microfone`.

## Armadilhas

- **O robô sorteia no dele.** `var _robo_rng := RandomNumberGenerator.new()`, com
  `_robo_rng.seed = rng.seed + 99` no `iniciar_jogo()`: o `rng` do kit é do jogo
  (os caminhos, os lados, o Aprendiz), e o robô não pode mudar o que o jogo sorteia
  (a paridade: com robô ou com gente, o mesmo jogo).
- **A música cala no silêncio de cada ciclo** (as batidas 8 a 11, depois 24
  a 27, 40 a 43…) pelo `Ritmo.calar(batidas)` da H08, uma vez por ciclo na
  batida `M`: a música some e o relógio segue, com a faixa gerada e com a
  sintetizada. O jogo não depende de a faixa ter a pausa.
- **O pé também é barulho**: o ✕ no silêncio congela, mesmo com escudo (o
  escudo cala a voz, não o pé).
- **O escudo desliga sozinho** no fim do silêncio: `Forja.led_mic(l, 0)`; no fim do
  minigame, o kit põe o controle em repouso.
- **A regra do ar no silêncio** é o que impede a gargalhada de um de congelar
  os quatro; não a desligue.
- **Na prova o pico chega:** o fim conta em tempo de música (H08), e os 90 s
  rodam inteiros.

## Pronto quando

Joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três
temperamentos (o ruim ri e congela); aguenta o cabo que cai e volta; fecha
com vencedor; o LED do mudo acende só em quem gastou escudo e apaga na
fim do silêncio; a prova do jogo passa; e `bash tests/prova_visual.sh` passa com a
prancha olhada (o guardião virando, os blocos de gelo, a caverna escura sem
virar tela vazia).

## Provas

Em `godot/testes/prova_do_jogo.gd`, uma `_prova_zero_absoluto()`:

```gdscript
## S08_J38: a marcha anda, e no primeiro silêncio o LED do mudo está aceso em
## quem gastou escudo e apagado nos outros.
func _prova_zero_absoluto() -> void:
	# a espera é a do `_joga_o_minigame` da H08: o aviso em quadros, o jogo pelo relógio de parede (90 s de música e o treino)
	var viu := [false]
	var olhar := func(s) -> void:
		# o primeiro silêncio: as batidas 8 a 11 (4 s de música)
		if not viu[0] and Ritmo.batida() >= s.BATIDA_DA_PRIMEIRA_NOTA + s.MARCHA_1 + 1.0:
			viu[0] = true
			for l in 4:
				var aceso := int(_perc(l).get("led_mic", 0)) != 0
				_esperar(aceso == bool(s._mudo[l]), "zero: o LED do P%d %s no silêncio" % [l + 1, "aceso" if s._mudo[l] else "apagado"])
	var sala = await _joga_o_minigame("S08_J38", 130.0, olhar)
	if sala == null:
		return
	_esperar(viu[0], "zero: o primeiro silêncio chegou")
	_esperar(sala._dist.max() >= 1.0, "zero: alguém marchou (%s)" % [sala._dist])
```

(O fim conta em tempo de música (H08): os 90 s rodam inteiros na prova, com
todos os silêncios; a marcha curta do primeiro ciclo é para o susto chegar
logo.)

`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**Com o André (local):** `./run-local.sh -- --sala=S08_J38`, com quatro no
sofá. O silêncio tem de fazer todo mundo prender o riso; o escudo aceso tem
de ser um alívio visível na mão; a gargalhada de um não pode congelar os
quatro (se congelar, anote os `voz` e ajuste `MARGEM_AR`).

## Ao terminar

- No [quadro](README.md), a linha P3: **feito**, com o commit.
- Commit sugerido (sem trailer):
  `feat: Zero Absoluto — calar no tempo, o mudo é o escudo`
