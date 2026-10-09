# P3 — Zero Absoluto

**Sprint:** P · **Slot:** S08_J38 · **Tamanho:** M · **Depende de:** P1, H04, H06, H07, H08, F09, G03, G04, G05, G08, G10, G13, G14, G15

## Por quê

Batatinha frita no gelo. Enquanto a música toca, todos marcham para o guardião; quando ela para, ele se vira e
**escuta**, e quem faz barulho congela. O verbo é o contrário da seção: **calar**. O Botão do microfone é o escudo,
com três cargas: a luz acesa no silêncio é o «estou seguro, posso rir». É o terror da seção, e o momento em que o
sofá inteiro segura o riso.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (a FICHA, os ganchos, o que o kit dá pronto)
- A P1, as partes [«O ouvido inteiro (`ouvido.gd`)»](P1-a-voz.md#o-ouvido-inteiro-godotscriptsminigamess08ouvidogd) (a voz, os 6 dB, o mudo, a escuta) e [«O
  cenário comum (`cenario_da_voz.gd`)»](P1-a-voz.md#o-cenário-comum-godotscriptsminigamess08cenario_da_vozgd) (a cripta, a câmera, o exagero, os ganchos do cavaleiro). A P1 cria os dois em
  `godot/scripts/minigames/s08/`; se ela já entrou, valem os arquivos, e esta ficha só os chama.

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão, o RPG) já está copiado nesta ficha, com os
números. Não abra outro documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s08/zero_absoluto.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/catalogo.gd` | `S08_J38` em `MINIGAMES` e na seção `S08` | **da seção**: uma linha |
| `godot/scripts/traducoes.gd` | `"Zero Absoluto"`, `"Cale!"`, `"%d escudos"` | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_zero_absoluto()` e a linha `"S08_J38": await _prova_zero_absoluto()` no `match slot` de `_prova_da_ficha(slot)` (H08) | **de todos** |

O `.uid` novo (`zero_absoluto.gd.uid`) sai do import `"$GODOT" --headless --path godot --import --quit` e entra no
commit. Esta ficha não mexe em `ouvido.gd`, `cenario_da_voz.gd`, `musica.gd` nem `minigame.gd`.

### O que muda de hoje

O Zero Absoluto não existe hoje. Ele nasce no kit, sem sala antiga para tirar. Da ficha antiga mudam: o verbo
(«Silêncio!» vira «Cale!»), a caverna (a cripta da seção, mais escura, em vez de uma casa de gelo com tochas
`#ffb070`), o guardião (o esqueleto Kenney em vez dos blocos da G08), o escudo (dois toques em vez de um) e o
congelado (sai do bloco na marcha seguinte, em vez de perder a marcha inteira).

### O kit que esta ficha usa

As do kit (H04, H08): `presentes()`, `conectado(l)`, `raia(l)`, `jogador(l)`, `posicionar(l)`, `nova_nota(l, n, t)`,
`notas_em_aberto(l)`, `alvo_da(l, n)`, `casar_toque(l)` (alcance 0,5 s, já com o desvio), `julgar_nota(l, n)`, `notas_perdidas(l)`, `anotar`, `marcar`,
`aprendeu(l)`, `momento(nome, l, pos, altura_m, campos)`, `rng`, `RAIAS`, `Z_JOGADOR` (1,4),
`BATIDA_DA_PRIMEIRA_NOTA` (4). Do `Ritmo`: `Ritmo.calar(batidas)` (a música cala e o relógio segue, H08),
`Ritmo.calada()`. Da F09: `Forja.robo_acerta()`, `Forja.robo_falar(l, nivel, s)` e `Forja._robo_apertar_cru(l,
botao, s)` (o aperto sem sorteio).

Do ouvido (P1): `Ouvido.new(self)`, `comecar()`, `ouvir(dt)`, `falando[l]`, `mudo[l]`, `sem_mic[l]`,
`proteger(l, sim)`, `luz_do_mudo(l)`, `segura[l]`, `abaixa`, `sentir(l, nome)`, `falante(l, som, ganho, ms)`,
`fechar()`. O ouvido chama `_comecou(l)`, `_parou(l)` e `_mudou(l, mudo)`.

Do cenário comum (P1): `CenarioDaVoz.pose_da_camera()`, `montar(sala, escuro)`, `passar`, `exagero`,
`gancho(l, nome)`, `queda_s(l, tempos)`, `antecedencia(l)`.

## Como se joga

### A ficha de dados

```gdscript
extends Minigame
## Zero Absoluto (S08_J38). Batatinha frita no gelo: enquanto a música toca,
## ✕ no tempo marcha para o guardião; quando ela para, ele se vira e escuta, e
## quem faz barulho (a voz, ou o pé) congela. O Botão do microfone é o escudo,
## com três cargas: ergue antes do silêncio, baixa depois.
##
## A falha: congela no gelo e recua uma laje; o escudo esquecido gasta mais
## uma carga; o mudo sem carga racha e congela.
## O vencedor: quem chegou mais longe, depois menos congelamentos, depois os pontos.
## O alto-falante do dono: o sino da virada, o clique do escudo; nada no silêncio.
## O registro mede: a voz no silêncio (`voz`), o escudo (`saida` led_microfone),
## a marcha no tempo, o momento `congelou`.
## O robô: marcha pelo relógio; às vezes ergue o escudo e ri; o ruim ri sem escudo.
## Com menos de quatro: nada muda.
## A régua: (1) "Cale!" e o ícone do microfone; (2) sim: o guardião vira antes
## de escutar; (3) não pergunta nada.

const FICHA := {
	"slot": "S08_J38",
	"titulo": "Zero Absoluto",
	"verbo": "Cale!",
	"genero": "terror",
	"icone": "microfone",
	"entradas": [Forja.CRUZ, Forja.MICROFONE],
	"camera": "fixa",
	"faixa": "MUS_S08_J38",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["toque", "aviso", "erro"],
	"material": "gelo",
	"microjogo": {"verbo": "Cale!", "segundos": 6.0},
	"papel_som": Forja.PAPEL_MICROFONE,
	"textura_no_acerto": false,  # a textura do passo toca pelo minigame, fora do silêncio
	"nota_no_falante": false,
	"gesto": "walk",
}

const Ouvido := preload("res://scripts/minigames/s08/ouvido.gd")
const MARCHA_1 := 4  ## o primeiro ciclo: o susto chega logo (o silêncio em 4 s)
const MARCHA := 12
const SILENCIO := 4
const SILENCIO_PICO := 8
const RETA := 16  ## nas últimas 16 batidas, o silêncio cai fora do lugar
const FORA_DO_LUGAR := [1, 3, 5]  ## batidas depois do começo da reta, sorteadas no rng do jogo
const CARGAS := 3
const BARULHO_S := 0.15  ## a voz por 0,15 s de música no silêncio congela
const BAIXAR_EM := 2.0  ## o escudo baixa em até 2 batidas depois do silêncio
const PASSO := 0.5  ## uma laje: 0,5 m
const META := 100  ## as lajes até o guardião
const SEM_MIC_PASSO := 0.8  ## sem microfone, o guardião não o ouve: anda 0,8 laje por passo
const RAIO_PE := 3.5  ## o barulho do pé: 3,5 m × o Ruído
const CHEGOU := 300  ## os pontos de quem toca o guardião
const PONTOS := [0, 50, 75, 100]
const QUEDA_TEMPOS := 3.0  ## o degelo: 3 tempos (a queda da P3)
const GUARDIAO := Vector3(0.0, 0.0, -3.0)
```

### Os números de 120 bpm

Uma batida dura 0,5 s. `B_FIM = int(floor(float(FICHA.duracao) * Ritmo.bpm / 60.0))` = 180 (90 s). A reta começa em
`B_FIM − RETA` = 164 (82 s). Até a H05, a reserva `"sopro"` toca a 105 bpm, e `B_FIM` = 157: tudo conta por batida
e por `B_FIM`.

### Os ciclos

O `iniciar_jogo()` monta a lista dos ciclos `{g0, m, s}` (o começo, a marcha, o silêncio), uma vez, no `rng` do jogo:

```gdscript
func _ciclos() -> void:
	var r := float(_b_fim - RETA)
	var g := float(BATIDA_DA_PRIMEIRA_NOTA)
	var pico := int(floor((_b_fim - g) / 16.0)) / 2
	var c := 0
	while g < _b_fim:
		var m := MARCHA_1 if c == 0 else MARCHA
		var s := SILENCIO_PICO if c == pico else SILENCIO
		if g + m > r:  # a reta: o silêncio cai fora do lugar
			m = maxi(int(r - g), 0) + int(FORA_DO_LUGAR[rng.randi() % FORA_DO_LUGAR.size()])
			s = SILENCIO
		_ciclo.append({"g0": g, "m": m, "s": s})
		g += m + s
		c += 1
```

A 120 bpm (com a semente 7, a reta sorteia, por exemplo, 3 e 1):

| ciclo | marcha (batidas) | silêncio (batidas) | silêncio (s) |
| --- | --- | --- | --- |
| c0 | 4–7 | 8–11 | 4–6 |
| c1 a c4 | 12–23, 28–39, 44–55, 60–71 | 24–27, 40–43, 56–59, 72–75 | 12, 20, 28, 36 |
| c5 (**o pico**) | 76–87 | **88–95** | 44–48 |
| c6 a c9 | 96–107, 112–123, 128–139, 144–155 | 108–111, 124–127, 140–143, 156–159 | 54, 62, 70, 78 |
| c10 (a reta) | 160–166 | 167–170 | 83,5 |
| c11 (a reta) | 171 | 172–175 | 86 |
| c12 | 176–179 | — | o fim em 180 |

Em cada ciclo, com `M = g0 + m` (a primeira batida do silêncio) e `S = s`:

| batida | o que acontece |
| --- | --- |
| `g0` a `M − 1` | **a marcha**: a música toca, o guardião olha a parede; ✕ em cada batida é um passo (a nota) |
| `M − 2` | o guardião começa a virar (1 batida e meia, `lerpf` pela batida); o sino `pronto` no alto-falante de cada um (0,6, 500 ms) e `ouvido.sentir(l, "aviso")` (a mão sabe antes do olho), cada lugar em `t(M − 2) − CenarioDaVoz.antecedencia(l)`; abre a janela do escudo |
| `M` | **o silêncio**: `Ritmo.calar(S)`; os olhos acendem; a barra de luz de cada um cai a 30 %; `ouvido.segura[l] = true` em todos |
| `M` a `M + S − 1` | o guardião escuta: quem faz barulho congela |
| `M + S` | a música volta; o guardião vira para a parede em 1 batida; `segura` volta a `false`; o que esperou o silêncio toca (abaixo); abre a janela de baixar o escudo |
| `M + S + 2` | quem ainda está mudo esqueceu o escudo |

**O falso alarme da contagem.** Na batida 2 da contagem (H06), `Ritmo.calar(1)`: a música para uma batida, e o
guardião **não** vira. Ensina que o perigo é o olhar dele, não o silêncio da música.

### A marcha

Cada batida inteira da marcha é uma nota do lugar: `nova_nota(l, n, Ritmo.t_da_batida(bn))`, aberta meia batida
antes. No `jogar`, `Forja.apertou(l, Forja.CRUZ)` na marcha → `var n := casar_toque(l)`; `n >= 0` → `julgar_nota`.
Cada passo julgado sem erro avança: `_dist[l] = minf(_dist[l] + (SEM_MIC_PASSO if ouvido.sem_mic[l] else 1.0), META)`
e marca `PONTOS[j]`. Sem ✕, a nota passa e vira `nota_perdida`: pisa em falso (`fall` 0,3 s), não avança. Com
`Ritmo.simples[l]`, só as batidas pares são notas.

Quem chega a `META` toca o guardião: `marcar(l, CHEGOU)` uma vez, `anotar("entrada", l, {"o": "chegou"})`; segue
marchando e marcando pontos, sem passar de `META`.

A 120 bpm, a marcha tem 124 notas por lugar em 90 s. Quem acerta tudo chega à `META` na batida 136 (68 s); o robô
`bom`, com 1 ou 2 congelamentos, perto dos 72 s; o `ruim` fica entre 40 e 70 lajes.

### O silêncio

De `M` a `M + S − 1`, para cada lugar vivo, conectado e fora do bloco:

- **a voz:** `ouvido.falando[l]` por mais de `BARULHO_S` (0,15 s de música) seguidos → **congela** (`"voz"`). A
  regra dos 6 dB vale: a gargalhada é de quem ri mais alto.
- **o pé:** qualquer ✕ → **congela** (`"pe"`), com escudo ou sem. O estalo do pé tem raio
  `RAIO_PE × CenarioDaVoz.gancho(l, "ruido")` m: o vizinho dentro do raio também congela (`"raio"`), se não estiver
  com o escudo erguido. A distância entre dois lugares é
  `sqrt((RAIAS[a] − RAIAS[b])² + ((_dist[a] − _dist[b]) × PASSO)²)`; as raias distam 4 m, então só o Ruído 5
  (4,2 m) alcança o vizinho na mesma laje.
- **o escudo:** quem está mudo com o escudo erguido não é ouvido: pode rir.
- **o mudo sem carga:** quem está mudo em `M` sem escudo pago e sem carga para pagar → o escudo racha e ele
  **congela** (`"racha"`).

O ouvido fica com `abaixa = false` (a música já está calada) e `segura[l] = true` no silêncio: a escuta abre, o
motor forte não vibra, e o alto-falante não toca.

### O escudo, em dois toques

O mudo é o do ouvido (por paridade: um aperto liga, o outro desliga). O escudo é a regra do Zero Absoluto em cima
dele:

1. **Erguer:** um aperto de `M − 2` a `M` liga o mudo. Com `_cargas[l] > 0`: `_cargas[l] -= 1`,
   `_pago[l] = c`, `ouvido.proteger(l, true)` (luz 1, acesa) e `ouvido.falante(l, "clique", 0.7, 100)`. Sem carga, o
   mudo liga e fica sem escudo (luz 2).
2. **Em `M`:** quem está mudo e não pagou neste ciclo paga agora, se tem carga (`_cargas[l] -= 1`, escudo). Sem
   carga, racha e congela.
3. **Baixar:** um aperto de `M + S` a `M + S + BAIXAR_EM` desliga o mudo (luz 0) e `ouvido.proteger(l, false)`.
4. **Esqueceu:** ainda mudo em `M + S + BAIXAR_EM`: `_cargas[l] = maxi(_cargas[l] - 1, 0)`,
   `ouvido.proteger(l, false)` (luz 2, piscando), `anotar("entrada", l, {"o": "escudo_esquecido"})` e
   `jogador(l).gesto("emote-no", 0.4)`.

Um aperto fora dessas janelas também muda o mudo (a paridade), sem escudo: luz 2. No próximo `M`, ele paga ou racha.

### Congelar

`_congelar(l, motivo)`:

- `momento("congelou", l, _pos(l), 2.0, {"motivo": motivo, "valores": "%s" % [_dist]})`;
- `CenarioDaVoz.exagero(self, _cenario, "estrondo", jogador(l))`: o tremor de 0,05 m por 2 batidas e o hit-stop de 3
  quadros;
- o bloco de gelo nasce em volta do boneco; o boneco fica parado (`anim.speed_scale = 0`) dentro dele;
- `_dist[l] = maxf(_dist[l] - 1.0, 0.0)` (recua uma laje), `_congelou[l] += 1`;
- `ouvido.segura[l] = false` e `Forja.sentir(l, "toque")` (o lugar não escuta mais; o forte espera);
- **depois do silêncio** (`_apos_silencio`): `ouvido.sentir(l, "erro")`, `Som.tocar("carimbo", _pos(l), -2.0)` (o
  estalo do gelo) e `ouvido.falante(l, "nota_quebrada:%d" % l, 0.8, 400)`;
- o bloco fica até a próxima marcha (`M + S`) e derrete em `CenarioDaVoz.queda_s(l, QUEDA_TEMPOS)` (o Fôlego). Durante
  o degelo, as notas da marcha dele não abrem.

### O fim e o vencedor

O kit fecha no `duracao` (90 s de música). Em `B_FIM`, `ouvido.fechar()` e `Forja.led_mic(l, 0)` em todos.

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if _dist[a] != _dist[b]:
			return _dist[a] > _dist[b]
		if _congelou[a] != _congelou[b]:
			return _congelou[a] < _congelou[b]
		return pontos[a] > pontos[b] or (pontos[a] == pontos[b] and a < b))
	return lista
```

### Com menos de quatro

- **Três, dois, um:** nada muda (a regra dos 6 dB com um microfone só é trivial). `com_poucos()` devolve `""`.
- **O controle que cai:** sem controle não marcha e **não congela** (o guardião o ignora); volta na marcha seguinte.
- **Sem microfone ou mudo no sistema** (`ouvido.sem_mic[l]`): o guardião não o ouve, por isso ele anda 0,8 laje por
  passo e tem 0 cargas. O pé no silêncio congela igual.

**A partida.** O Zero Absoluto e o O4 nunca vêm na mesma partida de 3 ou de 5 minigames (README da diversão, regra
3). A regra é do sorteio da partida, não desta ficha.

### Os ganchos

| gancho | o que faz |
| --- | --- |
| `montar()` | a câmera, `CenarioDaVoz.montar(self, 0.6)`, o guardião, por lugar a trilha, a lanterna e o bloco escondido; `gatilhos_off` |
| `iniciar_jogo()` | o ouvido (`abaixa = false`), `_b_fim`, `_ciclos()`, `_cargas` (0 sem microfone), `_robo_rng.seed = rng.seed + 99` |
| `jogar(dt)` | `ouvido.ouvir(dt)`, `passar`, o roteiro do ciclo pela batida, a marcha, o silêncio, o escudo, `notas_perdidas`, `_mostrar` |
| `_comecou(l)`, `_parou(l)` | nada: o silêncio lê `ouvido.falando[l]` a cada quadro |
| `_mudou(l, mudo)` | o escudo (erguer, baixar) |
| `toque(l, j)` | os pontos e o passo; `ouvido.depois(l, ...)`: `Forja.textura(l, "gelo", 0.5)` |
| `falha(l)` | pisou em falso: `fall` 0,3 s |
| `vencedor()` | acima |
| `combo(l)` | os passos seguidos sem erro (G04) |
| `status(l)` | `"%d escudos" % _cargas[l]` |
| `dica(l)` | `["@cross"]` na marcha e `["@mic"]` de `M − 2` a `M`, enquanto `not aprendeu(l)`; senão `{}` |

**O arquivo se monta à mão:** os blocos daqui são pedaços dele, e o resto sai da prosa; por isso nenhum leva `arquivo=`.

O esqueleto:

```gdscript
var ouvido: Ouvido
var _cenario := {}
var _b_fim := 180
var _ciclo := []  ## [{g0, m, s}]
var _c := 0  ## o ciclo da vez
var _fez := {}  ## "c:evento" -> true (a virada, o silêncio, a volta, o esquecido)
var _dist := [0.0, 0.0, 0.0, 0.0]
var _dist_visto := [0.0, 0.0, 0.0, 0.0]  ## o que a trilha mostra: anda até _dist em meia batida
var _cargas := [CARGAS, CARGAS, CARGAS, CARGAS]
var _pago := [-1, -1, -1, -1]  ## o ciclo em que o escudo foi pago
var _congelado_ate := [-1.0, -1.0, -1.0, -1.0]  ## a batida em que o degelo acaba
var _congelou := [0, 0, 0, 0]
var _chegou := [false, false, false, false]
var _barulho_desde := [-1.0, -1.0, -1.0, -1.0]
var _apos_silencio := []  ## Callables para M + S
var _n := [0, 0, 0, 0]
var _feita := [-1.0, -1.0, -1.0, -1.0]
var _guardiao := {}  ## {pivo, olhos, mat_olhos}
var _trilha := {}  ## lugar -> [lajes]
var _lanterna := {}  ## lugar -> {brasas, luz}
var _bloco := {}  ## lugar -> a caixa de gelo


func jogar(dt: float) -> void:
	var b := Ritmo.batida()
	ouvido.ouvir(dt)
	CenarioDaVoz.passar(self, _cenario, int(_c) == _pico_c())
	while _c + 1 < _ciclo.size() and b >= float(_ciclo[_c + 1].g0):
		_c += 1
	var ci: Dictionary = _ciclo[_c]
	var m: float = ci.g0 + ci.m
	var fim: float = m + ci.s
	_roteiro(b, m, fim)  # M - 2, M, M + S, M + S + 2: uma vez por ciclo (_fez)
	for l in presentes():
		if not conectado(l):
			continue
		var cruz := Forja.apertou(l, Forja.CRUZ)
		if b < m:
			_marcha(l, b, cruz)  # abre a nota; ✕ julga; o degelo bloqueia
		elif b < fim:
			_escuta(l, cruz)  # a voz por BARULHO_S, o pé, o raio
		notas_perdidas(l)
	if b >= _b_fim and not _fez.has("fim"):
		_fez["fim"] = true
		ouvido.fechar()
		for l in presentes():
			Forja.led_mic(l, 0)
	_mostrar(b, m, fim)


func _escuta(l: int, cruz: bool) -> void:
	if _no_bloco(l) or (ouvido.mudo[l] and ouvido.escudo[l]):
		if cruz and not _no_bloco(l):
			_pe(l)
		return
	if cruz:
		_pe(l)
		return
	if ouvido.falando[l]:
		if _barulho_desde[l] < 0.0:
			_barulho_desde[l] = Ritmo.t_musica()
		elif Ritmo.t_musica() - _barulho_desde[l] > BARULHO_S:
			_congelar(l, "voz")
	else:
		_barulho_desde[l] = -1.0


## O pé no silêncio: congela o dono e quem está no raio sem escudo erguido.
func _pe(l: int) -> void:
	_congelar(l, "pe")
	var raio := RAIO_PE * CenarioDaVoz.gancho(l, "ruido")
	for o in presentes():
		if o == l or _no_bloco(o) or not conectado(o) or (ouvido.mudo[o] and ouvido.escudo[o]):
			continue
		var d := Vector2(RAIAS[l] - RAIAS[o], (_dist[l] - _dist[o]) * PASSO).length()
		if d <= raio:
			_congelar(o, "raio")
```

`_marcha`, `_roteiro`, `_mudou`, `_congelar`, `_no_bloco` e `_mostrar` fazem o que as partes desta ficha dizem.
`_pico_c()` devolve o índice do ciclo de `s == SILENCIO_PICO`.

O catálogo: `Catalogo.MINIGAMES["S08_J38"] = preload("res://scripts/minigames/s08/zero_absoluto.gd")` e
`"S08_J38"` na seção `S08`. As traduções: `"Zero Absoluto": "Absolute Zero"`, `"Cale!": "Hush!"`,
`"%d escudos": "%d shields"`.

## A cena

### A câmera

A da P1: `CenarioDaVoz.pose_da_camera()`, 35 mm, plongée de 50°, a 13,5 m de `(0; 1,2; −1,6)`, o modo `fixa`. O
guardião de pé chega a 4,77 m em z −3,0 (o esqueleto Kenney tem 0,722 m; na escala 6,6, 4,77 m), e o topo do
quadro ali está a 5,46 m: sobra 0,7 m. No silêncio do pico,
a câmera recua 10 % (`pose_da_camera(1.1)`). Roll zero; o tremor é só o do `exagero`.

### A luz da seção

A cripta da P1 mais escura: `CenarioDaVoz.montar(self, 0.6)`. A chave fica a 0,77 × 0,6 = 0,46, as tochas a 0,48 e a
névoa do `atmosfera` a 0,21. É a mesma caverna, escurecida: o terror vem do escuro, não de outra paleta.

- **O silêncio:** a barra de luz de cada um cai a 30 % (`Forja.luz(l, Tema.JOGADOR[l].darkened(0.7))`) e volta em
  `M + S` (`Forja.luz_do_lugar(l)`). Os olhos do guardião vão de 0 a 1,2 em meia batida.
- **O pico:** a chave sobe 20 % em 1 batida (10 % sem flashes).

### As peças Kenney e o papel de cada uma

| peça | onde | papel |
| --- | --- | --- |
| a cripta, as tochas, as velas, as colunas | `CenarioDaVoz.montar(self, 0.6)` | o fundo comum da seção |
| `graveyard-kit/character-skeleton` (escala 6,6: 4,77 m de altura, 3,4 m de largura com os braços) | o pivô em `GUARDIAO = (0, 0, −3.0)` | **o guardião**: de costas (`rotation.y = PI`) na marcha, de frente (`0`) no silêncio |

O que não é peça Kenney (caixas do `Kit`, `metallic` 0):

| objeto | forma | onde | material |
| --- | --- | --- | --- |
| os olhos do guardião | 2 caixas 0,3 × 0,22 × 0,04 | filhos do pivô, em `(±0.46, 3.85, 1.09)`: as órbitas do crânio (no modelo, x ±0,07, y 0,584, frente em z 0,162; × 6,6) | `Tema.neon(Tema.VIOLETA, e, "mundo")`, `e` 0 na marcha, 1,2 no silêncio |
| as lajes da trilha | 24 caixas 1,4 × 0,05 × 0,45 por lugar | `(RAIAS[l], 0.03, Z_JOGADOR − i × PASSO)`, recicladas | `Kit.material(Tema.ETIQUETA_SOMBRA, 0.0, 0.5)` |
| o bloco de gelo | caixa 1,1 × 2,0 × 1,1 | `(RAIAS[l], 1.0, Z_JOGADOR)` | `Kit.material(Tema.ETIQUETA, 0.0, 0.25)`, alfa 0,55 |
| o poste da lanterna | caixa 0,08 × 1,6 × 0,08 | `(RAIAS[l] + 0.9, 0.8, Z_JOGADOR)` | `Kit.material(Tema.GRAFITE, 0.0, 0.6)` |
| as brasas do escudo | 3 caixas 0,14 × 0,14 × 0,14, empilhadas | no topo do poste, y 1,7 / 1,86 / 2,02 | `Tema.neon(Tema.JOGADOR[l], 1.6, l)`; a gasta some (de cima para baixo) |
| a luz da lanterna | `OmniLight3D` | `(RAIAS[l] + 0.9, 2.0, Z_JOGADOR)` | a cor do lugar, 0,9, alcance 4 |

**A trilha, pela batida.** O cavaleiro não sai do lugar: a trilha desliza. A laje `i` fica em
`z = Z_JOGADOR − (i × PASSO − fmod(_dist_visto[l] × PASSO, 24 × PASSO))`, e a que passa de z 3,0 volta para trás. O
`_dist_visto[l]` anda até `_dist[l]` em meia batida depois do passo (`lerpf`).

**O guardião vira** de `M − 2` a `M − 0.5` (de `PI` a `0`) e volta de `M + S` a `M + S + 1`, pela batida, curva
`ENTRA_SAI`.

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08) |
| as brasas do escudo | o lugar | 1,6 |
| a luz da lanterna | o lugar | omni 0,9 |
| os olhos do guardião | o mundo | `Tema.VIOLETA`, de 0 a 1,2 |
| as tochas | a forja | 1,8 (o cenário comum), a luz a 0,48 |

O gelo é `Tema.ETIQUETA` e `Tema.ETIQUETA_SOMBRA`, sem brilho. Somem os `#cfe8ff`, `#ffb070`, `#7f9fb8`, `#9fc6e0`,
`#bfe6ff` e o `Tema.CIANO` da ficha antiga. Nenhuma cor de lugar no gelo.

### A montagem

- Por lugar: `raia(l)`, `posicionar(l)`, `rotation.y = PI` (andando para o guardião), `preso = true`; a trilha; a
  lanterna; o bloco, escondido.
- O guardião: um pivô `Node3D` em `GUARDIAO` com o esqueleto (`Kit.peca(pivo, "graveyard-kit/character-skeleton",
  Vector3.ZERO, 0.0, 6.6)`) e os olhos.

## O som

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| o passo | a nota do kit (`Som.tocar("nota", ...)`, H08) | — | `nota_*` |
| a virada (`M − 2`) | — | `pronto`, 0,6 (500 ms) | `mod_pronto` |
| erguer o escudo | — | `clique`, 0,7 (100 ms) | `mod_clique` |
| o silêncio | **nada**: a música cala (`Ritmo.calar`) | **nada** | — |
| congelou (depois do silêncio) | `Som.tocar("carimbo", _pos(l), -2.0)` (o estalo do gelo) | `nota_quebrada:%d`, 0,8 (400 ms) | `carimbo_*` |
| tocou o guardião | `Som.tocar("sino", GUARDIAO, -4.0)` | — | `sino_*` |
| a faixa | `MUS_S08_J38`: 120 BPM, Dó menor; até ela existir, a reserva `"sopro"` (105 bpm) | — | `mus_s08_j38` |

- **O silêncio é silêncio.** Todo som de TV no silêncio chega aos quatro microfones quase igual: pela regra dos
  6 dB, os quatro contariam e congelariam juntos. Por isso o estalo do gelo, a nota quebrada e o vento da ficha
  antiga esperam `M + S`.
- **O `falha` não existe aqui.** O material `"gelo"` (`mod_material_gelo`, 180 Hz, 20 ms, num atuador só) toca pelo
  minigame no passo, fora do silêncio.

## O controle

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante | luz do mudo |
| --- | --- | --- | --- | --- | --- | --- |
| começar | todos | — | `gatilhos_off(l)` | a cor do lugar | — | 0 |
| o passo | o dono | a textura `gelo` 0,5; sem háptica, `toque` | — | o kit: branco no perfeito | — | — |
| pisou em falso | o dono | o kit: `erro` | — | o kit | — | — |
| a virada (`M − 2`) | todos | `aviso` | — | — | `pronto` 0,6 | — |
| erguer o escudo | o dono | — | — | — | `clique` 0,7 | 1 (acesa) |
| o silêncio | todos | nada forte (`ouvido.sentir`) | — | a cor a 30 % | nada | — |
| congelou | o dono | `toque` na hora; `erro` em `M + S` | — | — | `nota_quebrada:%d` em `M + S` | — |
| esqueceu o escudo | o dono | — | — | — | — | 2 (piscando) |
| baixar o escudo | o dono | — | — | — | — | 0 |

- **No silêncio, nada forte vibra** e o alto-falante cala: o motor e o falante seriam ouvidos pelo microfone do mesmo
  controle e pelos vizinhos.
- A barra de luz é sempre a cor do lugar; no silêncio, a mesma cor a 30 %.
- **No rádio:** sem microfone nem alto-falante. O lugar anda 0,8 laje por passo, sem cargas, com a `troca` gravada
  pelo ouvido. A luz do mudo passa pela ponte.

### O robô

```gdscript
# O robô marcha pelo relógio e decide o silêncio uma vez por ciclo. Sorteia no
# rng dele: o rng do kit é do jogo (a reta fora do lugar).
var _robo_rng := RandomNumberGenerator.new()
var _robo_nota := [-1, -1, -1, -1]
var _robo_feita := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]
var _robo_ciclo := [-1, -1, -1, -1]
var _robo_ri := [false, false, false, false]
var _robo_escudo := [false, false, false, false]
var _robo_riu := [-1, -1, -1, -1]
var _robo_baixou := [-1, -1, -1, -1]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var b := Ritmo.batida()
	var ci: Dictionary = _ciclo[_c]
	var m: float = ci.g0 + ci.m
	var fim: float = m + ci.s
	# a marcha: ✕ em cada nota aberta (quando erra, 0,25 s tarde)
	for n in notas_em_aberto(l):
		if int(n) <= int(_robo_feita[l]):
			continue
		if int(_robo_nota[l]) != int(n):
			_robo_nota[l] = n
			_robo_mira[l] = 0.0 if Forja.robo_acerta() else 0.25
		if Ritmo.t_musica() >= alvo_da(l, n) + float(_robo_mira[l]) and b < m:
			Forja._robo_apertar_cru(l, Forja.CRUZ, 0.05)  # já sorteou: o aperto sem sorteio
			_robo_feita[l] = n
		break
	# o silêncio: decide uma vez por ciclo, em M - 1,8
	if _robo_ciclo[l] != _c and b >= m - 1.8:
		_robo_ciclo[l] = _c
		var certo := Forja.robo_acerta()
		_robo_escudo[l] = certo and _cargas[l] > 0 and _robo_rng.randf() < 0.3
		_robo_ri[l] = _robo_escudo[l] or not certo  # com escudo ri à vontade; o que erra ri sem
		if _robo_escudo[l]:
			Forja._robo_apertar_cru(l, Forja.MICROFONE, 0.08)
	if _robo_ri[l] and b >= m + 1.0 and b < fim and _robo_riu[l] != _c:
		_robo_riu[l] = _c
		Forja.robo_falar(l, 0.7, 0.4)
	if _robo_escudo[l] and b >= fim + 0.5 and _robo_baixou[l] != _c:
		_robo_baixou[l] = _c
		if Forja.robo_acerta():  # quando erra, esquece o escudo erguido
			Forja._robo_apertar_cru(l, Forja.MICROFONE, 0.08)
```

O robô ri 0,4 s a 0,7: passa dos 0,15 s e congela quem não tem escudo. A chance de rir sem escudo num silêncio é a
de errar: 5 % no `bom`, 34 % no `medio`, 70 % no `ruim`.

O robô sorteia o temperamento uma vez, no `Forja.robo_acerta()`, e aperta pelo `Forja._robo_apertar_cru(l, botao,
s)` da F09. O `Forja.robo_apertar` sorteia de novo dentro (quem erra não aperta em 50 % das vezes, ou aperta de 0,4
a 1,2 s tarde): com ele, o escudo do robô `bom` falharia, e as chances acima ficariam erradas. Se a F09 entrar com
outro nome para o aperto sem sorteio, use o dela e anote o nome aqui.

## O cavaleiro

O cavaleiro é o da montagem (G13), de costas para a câmera, de mãos livres, andando (`walk`) na marcha. O cavaleiro
pode ser de outra raça (G13, o ajuste dela de 09/10): esta ficha não supõe corpo humano; usa só o esqueleto comum de
7 ossos e as animações `walk`, `fall`, `emote-no` e `idle`.

| stat | gancho | o que muda no Zero Absoluto | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `ruido` | o raio do pé no silêncio (3,5 m ×) | 2,8 m | 3,5 m | 4,2 m (alcança o vizinho na mesma laje) |
| Passo | — | não age: o passo é uma laje para todos (o tempo manda) | — | — | — |
| Fôlego | `levantar` | o degelo (3 tempos) | 3,75 tempos | 3 tempos | 2,25 tempos |
| Faro | `pista` | o sino e o aviso na mão da virada chegam antes para ele; o silêncio cai no mesmo tempo | −40 ms | 0 | +40 ms |

Os itens: o Escudo absorve o primeiro erro (o kit, G03: o primeiro pisar em falso); a Lanterna adianta o sino e o aviso
da virada meio tempo para ele; o Fole devolve metade do combo; o Martelo dobra o perfeito no tempo forte (o kit); o
Diapasão é do kit; a Âncora não age. Nenhum stat muda a janela de julgamento nem o `BARULHO_S`.

## As reações

- **Carimbos** (do kit e do HUD, G04; o Zero Absoluto não chama nenhum): `car_em_chamas` (5 Ressonâncias seguidas na
  marcha), `car_acorde` (os quatro no mesmo tempo 1 da marcha), `car_por_um_fio` (o vencedor por até 1 laje).
- **Adesivos:** quem está no bloco de gelo pode mandar adesivo (G04) enquanto espera; o adesivo não faz som no
  silêncio (o HUD é da TV, mudo).
- Nenhum carimbo próprio de minigame.

## A diversão

**O momento: congelou** (`congelou`). O guardião se vira, alguém não segura o riso, e o bloco de gelo nasce em volta
dele. A sala explode no riso que não pode, e quem tem escudo ri à vontade. Degrau estrondo.

- **Rastro:** o bloco fica até a próxima marcha e derrete no degelo (3 tempos × o Fôlego); a trilha dele recuou uma
  laje; a brasa gasta do escudo não volta.
- **A curva:** de 2 a 6 s, a primeira marcha curta (o susto em 4 s); de 6 a 44 s, marchas de 12; de 44 a 48 s, **o
  silêncio do pico**, de 8 batidas (ninguém sabe quando ele volta a olhar a parede); de 48 a 82 s, marchas de 12;
  de 82 s ao fim, o silêncio fora do lugar.
- **Ensina sem falar:** o falso alarme da contagem (a música para, o guardião não vira); a virada começa 2 batidas
  antes do silêncio; o sino e o aviso na mão.
- **Quem está perdendo:** congelar só recua uma laje, e o degelo acaba no começo da marcha seguinte.
- **A nota de hoje:** 4. Gênero `terror`.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | o primeiro silêncio começa em `t_musica` 4,0; cada lugar tem um `toque` com `t_musica` ≤ 4,0 | o quadro de 4 s mostra o guardião virando |
| 4. o momento | pelo menos 2 linhas `momento` `congelou` entre 0 e 90 s, pelo menos 1 no silêncio do pico (44 a 48 s) | 1 quadro em cada 5 mostra um bloco de gelo |
| 5. a curva | o silêncio do pico tem 8 batidas; os silêncios depois de 82 s começam numa batida ímpar | o quadro de 46 s mostra os olhos acesos e a câmera mais longe |
| 6. a falha | o P4 tem pelo menos 2 `congelou` ou 3 `toque` com `erro` | o P4 aparece no bloco em 1 quadro em 10 |
| 7. quem perde joga | ninguém fica mais de 16 batidas sem nota aberta fora do silêncio; o P4 tem um passo certo em cada terço | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | todo `congelou` tem 0,05 ≤ `x_tela` ≤ 0,95 e `altura_tela` ≥ 0,08 | o guardião inteiro cabe no quadro de 480 × 270 |
| 9. o impacto | o bloco de gelo aparece no mesmo quadro do `congelou` (o `visible` muda na mesma chamada) | o quadro seguinte ao `congelou` mostra o bloco |
| 10. o placar no mundo | o `valores` do `congelou` bate com `_dist` | as trilhas mostram quem está na frente pelas lajes; as brasas mostram os escudos |

A mesa padrão roda em duas rodadas até o robô por lugar existir: `ROBO=medio SALA=S08_J38 bash
tests/prova_do_jogo.sh` (os itens 1, 5, 8, 9 e 10) e `ROBO=ruim SALA=S08_J38 bash tests/prova_do_jogo.sh` (os itens 4, 6 e 7). A variável `ROBO` é da
P1 (em `tests/prova_do_jogo.sh`); `--robo=medio` depois do comando não chega ao Godot.

## Pronto quando

O Zero Absoluto joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos (o ruim ri e
congela). Aguenta o cabo que cai e volta, e fecha com vencedor. A luz do mudo acende só em quem ergueu o escudo,
pisca em quem esqueceu e apaga em quem baixou. Nada toca nem vibra forte no silêncio. `SALA=S08_J38 bash tests/prova_do_jogo.sh` passa (sem e com `--bancada`), e
`bash tests/prova_visual.sh` passa com a prancha olhada (o guardião virando, os blocos de gelo, a caverna escura sem
virar tela vazia).

## Provas

Na sessão, nesta ordem:

```bash
bash tests/prova_do_jogo.sh                              # o percurso: nada que já passava quebrou
SALA=S08_J38 bash tests/prova_do_jogo.sh                 # o minigame inteiro, sem e com --bancada
ROBO=medio SALA=S08_J38 bash tests/prova_do_jogo.sh      # a régua, a rodada do medio
ROBO=ruim SALA=S08_J38 bash tests/prova_do_jogo.sh       # a régua, a rodada do ruim
bash tests/prova_visual.sh                               # as pranchas
```

Em `godot/testes/prova_do_jogo.gd`, a função entra no `match slot` de `_prova_da_ficha(slot)` da H08, ao lado da
linha da P1 (o percurso não joga 90 s de cada minigame):

```gdscript
		"S08_J38":
			await _prova_zero_absoluto()
```

A função:

```gdscript
## S08_J38: a marcha anda; no silêncio, a luz do mudo acende em quem ergueu o
## escudo e apaga nos outros; nada forte vibra no silêncio; o falso alarme da
## contagem não vira o guardião.
func _prova_zero_absoluto() -> void:
	var luz_certa := [0]
	var luz_errada := [0]
	var forte := [0]
	var falso := [false]
	var olhar := func(mg) -> void:
		if mg.ouvido == null:
			return
		if Ritmo.batida() < 4.0 and Ritmo.calada():
			falso[0] = absf(mg._guardiao.pivo.rotation.y - PI) < 0.01
		for l in mg.presentes():
			if not mg.ouvido.segura[l]:
				continue
			var pc := Forja.percepcao(l)
			var esperado: int = mg.ouvido.luz_do_mudo(l)
			if int(pc.get("led_mic", 0)) == esperado:
				luz_certa[0] += 1
			else:
				luz_errada[0] += 1
			if maxf(float(pc.get("forte", 0.0)), float(pc.get("fraco", 0.0))) > 0.75:
				forte[0] += 1
	var mg = await _joga_o_minigame("S08_J38", 140.0, olhar)
	if mg == null:
		return
	_esperar(falso[0], "Zero: a música calou na contagem e o guardião não virou")
	_esperar(luz_certa[0] > 0 and luz_errada[0] == 0, "Zero: a luz do mudo certa no silêncio (%d erradas)" % luz_errada[0])
	_esperar(forte[0] == 0, "Zero: nada forte vibrou no silêncio (%d)" % forte[0])
	_esperar(mg._dist.max() >= 1.0, "Zero: alguém marchou (%s)" % [mg._dist])
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S08_J38")
	var gelos := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "congelou")
	if Forja.robo_temperamento == "ruim":
		_esperar(gelos.size() >= 2, "Zero: %d congelamentos na mesa ruim" % gelos.size())
	for g in gelos:
		_esperar(float(g.get("x_tela", 0.0)) >= 0.05 and float(g.get("x_tela", 0.0)) <= 0.95, "Zero: o bloco na tela (%s)" % [g])
```

`Forja.robo_temperamento` é o temperamento da F09 (`var robo_temperamento := ""` em `forja.gd`). A luz conferida é a do
`led_mic` que a `percepcao` lê (a saída mandada), no próprio quadro: a F01 anota a `saida` com o `seq`.

### O que o registro mede

- `voz` no silêncio: quem fez barulho, o nível e o limiar (e quantas vezes o barulho era da sala inteira e a regra
  dos 6 dB escolheu o mais alto).
- `saida` `led_microfone` de cada escudo, com `seq` e `ok`; o botão pelas medidas.
- a marcha (`nota` e `toque`); `entrada` `chegou` e `escudo_esquecido`.
- `momento` `congelou`, com o `motivo` (`voz`, `pe`, `raio`, `racha`).
- `troca` de `microfone` para `sem_microfone`.

### As pranchas que o jogador do time olha

- o quadro de 4 s: o guardião virando pela primeira vez;
- o de 46 s: o silêncio do pico, os olhos acesos, a câmera mais longe;
- os quadros com bloco de gelo;
- o último: as trilhas e as brasas de cada um.

A caverna escura não pode virar tela vazia: o guardião, os quatro cavaleiros e as lanternas aparecem em todo quadro.

### O que o André joga e sente

`./run-local.sh -- --sala=S08_J38`, com quatro no sofá:

- o silêncio faz todo mundo prender o riso;
- o escudo aceso é um alívio visível na mão (a luz laranja do microfone);
- a gargalhada de um não congela os quatro. Se congelar, anote os `voz` dos quatro;
- o controle não faz som nem vibra forte no silêncio;
- quem esquece o escudo vê a luz piscando e uma brasa a menos.

### Armadilhas

- **O robô sorteia no dele:** `_robo_rng.seed = rng.seed + 99`. A reta fora do lugar usa o `rng` do jogo, uma vez,
  no `iniciar_jogo()`.
- **A música cala pelo `Ritmo.calar(S)`** da H08, uma vez por ciclo, na batida `M`: o relógio segue, com a faixa da
  H05 e com a reserva. O jogo não depende de a faixa ter a pausa.
- **O pé também é barulho:** o ✕ no silêncio congela, mesmo com escudo (o escudo cala a voz, não o pé).
- **Nenhum som no silêncio:** nem da TV, nem do alto-falante. Um som a mais congela os quatro.
- **O `abaixa = false`:** a `Musica.escuta` não pode mexer no volume enquanto a música está calada; o ouvido já não
  mexe com o `Ritmo.calada()`, e o `abaixa` desliga o resto.
- **Os olhos do esqueleto:** os números saem do `character-skeleton.glb` do Graveyard Kit (o crânio de y 0,447 a
  0,722; as órbitas em x ±0,07 e y 0,584). Se a G10 ou a G14 trocarem a escala da pasta `graveyard-kit` (hoje 1×),
  divida o 6,6 pelo fator novo para o guardião ficar com 4,77 m.

### Ao terminar

- No [quadro](README.md): a linha **P3**, com o commit (`feito (<commit>)`).
- Commit sugerido (sem trailer):
  `feat: Zero Absoluto no kit — calar no tempo, o mudo é o escudo`
