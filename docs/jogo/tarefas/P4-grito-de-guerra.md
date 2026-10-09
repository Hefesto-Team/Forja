# P4 — Grito de Guerra

**Sprint:** P · **Slot:** S08_J39 · **Tamanho:** M · **Depende de:** P1, H04, H06, H07, H08, F09, G03, G04, G05, G08, G10, G13, G14, G15

## Por quê

Sumô de cavaleiros num octógono de pedra sobre o abismo. O grito no tempo forte solta uma onda que empurra quem está
perto; o grito fora do tempo dá o coice no próprio cavaleiro. É a voz como arma, todos contra todos. E é o minigame
que mais faz a sala rir, porque ninguém consegue gritar no tempo rindo.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (a FICHA, os ganchos, o que o kit dá pronto)
- [`godot/scripts/minigames/s08/ouvido.gd`](../../../godot/scripts/minigames/s08/ouvido.gd) (a P1 cria: a voz, os
  6 dB, o mudo, a escuta)
- [`godot/scripts/minigames/s08/cenario_da_voz.gd`](../../../godot/scripts/minigames/s08/cenario_da_voz.gd) (a P1
  cria: a cripta, a câmera, o exagero, os ganchos do cavaleiro)

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão, o RPG) já está copiado nesta ficha, com os
números. Não abra outro documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s08/grito_de_guerra.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/catalogo.gd` | `S08_J39` em `MINIGAMES` e na seção `S08` | **da seção**: uma linha |
| `godot/scripts/traducoes.gd` | `"Grito de Guerra"`, `"Grite!"`, `"No ringue"`, `"Contra 2 bonecos"` | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_grito_de_guerra()` e a chamada no percurso | **de todos** |

O `.uid` novo (`grito_de_guerra.gd.uid`) sai do import `"$GODOT" --headless --path godot --import --quit` e entra no
commit. Esta ficha não mexe em `ouvido.gd`, `cenario_da_voz.gd`, `musica.gd` nem `minigame.gd`.

### O que muda de hoje

O Grito de Guerra não existe hoje. Ele nasce no kit. Da ficha antiga mudam:

- o lugar: o ringue sobe para a cripta da seção, sem a luz laranja `#ffb070` nem o `Tema.VERMELHO`;
- a câmera: o modo `grupo`, no lugar da pose fixa de cima;
- a mão do empurrado: `toque_esq` e `toque_dir` leves, depois da janela, no lugar do `golpe_esq` e do `golpe_dir`
  cheios (o motor cheio entra no microfone do mesmo controle);
- o começo: o primeiro grito é da TV, na contagem, e empurra os quatro;
- o fim: nas últimas 16 batidas, a onda dobra;
- o fantasma: o sopro puxa o vivo para a borda (antes, empurrava para longe dele, que é para dentro do ringue);
- o volume da voz: só mostra a onda maior, não empurra mais.

### O kit que esta ficha usa

As do kit (H04, H08): `presentes()`, `conectado(l)`, `jogador(l)`, `nova_nota(l, n, t)`, `notas_em_aberto(l)`,
`alvo_da(l, n)`, `julgar_nota(l, n)`, `notas_perdidas(l)`, `nota_perdida(l, n)`, `anotar`, `marcar`, `aprendeu(l)`,
`momento(nome, l, pos, altura_m, campos)`, `rng`, `acabou`, `BATIDA_DA_PRIMEIRA_NOTA` (4). Da câmera (G05):
`camera_modo`, `camera_distancia`, `alvos_da_camera()`. Do G03: `Itens.resiste_a_empurrao(l)` (a Âncora, 0,5 ou
1,0).

Do ouvido (P1): `Ouvido.new(self)`, `comecar()`, `ouvir(dt)`, `nova_voz(l, n, bn)`, `casar_voz(l)`, `janela_casa`,
`nivel[l]`, `piso[l]`, `escuta[l]`, `sozinho(l)`, `falante(l, som, ganho, ms)`, `sentir(l, nome, ms)`,
`depois(l, f)`, `fechar()`. O ouvido chama `_comecou(l)`, `_parou(l)` e `_mudou(l, mudo)`.

Do cenário comum (P1): `CenarioDaVoz.pose_da_camera(recuo, olhar)`, `montar(sala)`, `passar`, `exagero`,
`gancho(l, nome)`, `queda_s(l, tempos)`.

## Como se joga

### A ficha de dados

```gdscript
extends Minigame
## Grito de Guerra (S08_J39). Sumô num octógono sobre o abismo: o grito no
## tempo forte solta uma onda que empurra quem está perto; o grito fora do
## tempo é um coice no próprio cavaleiro. O analógico esquerdo anda.
##
## A falha: o coice (1 m para trás), a tosse do calado (0,3 m), a queda no
## abismo (vira fantasma na borda e sopra).
## O vencedor: o último no ringue; depois, quem caiu mais tarde.
## O alto-falante do dono: a nota dele no grito perfeito; o pulso no empurrão.
## O registro mede: a voz de cada grito (`voz`), o tempo do grito (`toque`), o
## lado do empurrão (`sensacao`), o momento `fora_do_ringue`.
## O robô: anda para o centro e grita no tempo forte pelo controle simulado.
## Com menos de quatro: sozinho, contra dois bonecos.
## A régua: (1) "Grite!" e o ícone do microfone; (2) sim: o grito da TV na
## contagem empurra os quatro; (3) não pergunta nada.

const FICHA := {
	"slot": "S08_J39",
	"titulo": "Grito de Guerra",
	"verbo": "Grite!",
	"genero": "tct",
	"icone": "microfone",
	"entradas": [],  # a voz e o analógico esquerdo, que não são botões
	"camera": "grupo",
	"faixa": "MUS_S08_J39",
	"duracao": 90.0,
	"fim": "ultimo_em_pe",
	"sensacoes": ["toque", "toque_esq", "toque_dir", "erro", "golpe"],
	"material": "pedra",
	"microjogo": {"verbo": "Grite!", "segundos": 6.0},
	"papel_som": Forja.PAPEL_MICROFONE,
	"textura_no_acerto": false,  # a textura vai pelo ouvido.depois, fora da escuta
	"nota_no_falante": false,
	"gesto": "attack-melee-right",
}

const Ouvido := preload("res://scripts/minigames/s08/ouvido.gd")
const CENTRO := Vector3(0.0, 0.0, -0.5)
const TOPO := 0.6  ## a pedra do ringue tem 0,6 m: os cavaleiros andam em y 0,6
const RAIO := 6.0  ## o raio em que se cai (o círculo dentro do octógono)
const RAIO_PICO := 4.5
const PARTIDA := 3.0  ## cada um começa a 3 m do centro
const ANGULO := [PI, PI / 2, 0.0, -PI / 2]  ## P1 à esquerda, P2 ao fundo, P3 à direita, P4 à frente
const VEL := 3.0  ## m/s, × a velocidade (o Passo)
const ONDA_R := 3.0
const ONDA_R_RETA := 6.0  ## nas últimas 16 batidas, a onda dobra
const FORCA := [0.0, 1.2, 1.8, 2.4]  ## ERRO, BOM, OTIMO, PERFEITO: os metros da onda
const COICE := 1.0
const TOSSE := 0.3
const GRITO_TV := 0.5  ## o grito da TV na contagem empurra os quatro 0,5 m
const SOPRO := 0.6  ## o fantasma puxa 0,6 m para a borda
const SOPRO_R := 3.0
const SOZINHO_FORCA := 1.2
const SOZINHO_R := 2.0
const GRITO_BONECO := 0.7
const VEL_BONECO := 1.2
const PONTOS_EMPURRAO := 50
const PICO_COMPASSOS := 4
const RETA := 16
const QUEDA_TEMPOS := 2.0  ## a queda no abismo: 2 tempos (a queda da P4)
const JANELA_CASA := 0.3  ## o grito começa largo: 0,3 s (o ouvido usa 0,25 por padrão)
const LUZ_BASE := 0.3  ## a barra de luz fica a 30 % da cor; o grito a leva a 100 % por 0,11 s
const LUZ_GRITO_S := 0.11
```

### Os números de 135 bpm

Uma batida dura 0,444 s. `B_FIM = int(floor(float(FICHA.duracao) * Ritmo.bpm / 60.0))` = 202 (90 s). O tempo forte
é a batida 0 de cada compasso: `bn = BATIDA_DA_PRIMEIRA_NOTA + 4k`, de 4 a 196, 49 gritos. Até a H05, a reserva
`"sopro"` toca a 105 bpm, e `B_FIM` = 157: tudo conta por batida e por `B_FIM`.

| batida | segundos | o que acontece |
| --- | --- | --- |
| 0–3 | 0–1,3 | a contagem (H06); na batida 2, **o grito da TV** |
| 4–99 | 1,8–44,0 | o tempo forte: um grito a cada compasso (1,78 s) |
| 100–115 | 44,4–51,1 | **o pico**: os compassos 24 a 27; o ringue encolhe de 6,0 a 4,5 m; grito nas batidas 0 e 2 |
| 116–185 | 51,6–82,2 | o tempo forte, no ringue de 4,5 m |
| 186–201 | 82,7–89,3 | **a reta**: a onda dobra (raio 6,0 m) |

`_pico_k = int(floor((B_FIM − BATIDA_DA_PRIMEIRA_NOTA) / 4.0)) / 2` = 24. O pico vai de `bp = 4 + 4 × 24` = 100 a
`bp + 16`.

### O ringue

- O octógono tem o centro em `CENTRO` e a pedra em y 0 a 0,6. Cai quem passa de `_raio` do centro (o círculo
  dentro do octógono: o desenho tem o raio do vértice `_raio / cos(PI / 8)`, e ninguém cai com o pé na pedra).
- Cada cavaleiro começa a `PARTIDA` (3 m) do centro, no ângulo do lugar: `CENTRO + 3 × (cos a, 0, sin a)`, de frente
  para o centro.
- **Andar:** o analógico esquerdo (`Forja.eixo(l, Forja.LX)`, `Forja.eixo(l, Forja.LY)`), acima de 0,2, a
  `VEL × CenarioDaVoz.gancho(l, "velocidade")` m/s, com o `dt` (o andar é entrada). O boneco olha para onde anda.
  Quem está sendo empurrado não anda.

### O grito (a nota)

- Uma batida antes de cada tempo forte, cada lugar vivo ou fantasma, conectado e fora do `sozinho`, ganha a nota:
  `ouvido.nova_voz(l, n, bn)` (o alvo é `t(bn) + 0,08`). Com `Ritmo.simples[l]`, só nos compassos pares.
- `ouvido.janela_casa = JANELA_CASA` (0,3 s) no `iniciar_jogo()`: a escuta abre 0,3 s antes do alvo, e a música
  desce 12 dB até o julgamento.
- O `_comecou(l)` casa com `ouvido.casar_voz(l)` e julga com `julgar_nota`. A voz longe de toda nota é ignorada: o
  ruído do sofá não empurra ninguém.
- **A onda** (`toque`, BOM ou melhor): de raio `ONDA_R` (3 m; `ONDA_R_RETA`, 6 m, na reta), empurra todo outro vivo
  conectado (e os bonecos) dentro dela, para longe do gritador:
  `m = FORCA[j] × gancho(l, "tranco") × _sofre(o)`, com
  `_sofre(o) = gancho(o, "empurrao") × Itens.resiste_a_empurrao(o)` (1,0 para os bonecos). Cada empurrado marca
  `PONTOS_EMPURRAO` (50) para o gritador.
- **O volume da voz é só visual:** o anel da onda brilha `1.2 + 1.4 × clampf((nivel − piso) / 0.5, 0, 1)` e não
  empurra mais longe. Quem grita mais alto não ganha nada além do brilho.
- **O coice** (ERRO: a voz casada, fora da janela do BOM): o próprio cavaleiro vai `COICE × _sofre(l)` m para
  trás, na direção oposta à que olha; `fall` 0,4 s.
- **Calado** (a nota que passou sem voz): tosse, `emote-no` 0,3 s, e recua `TOSSE × _sofre(l)` m.
- **O empurrão anda pela batida:** `_empurrar(q, dir, m)` guarda `{de, ate, b0}`; a posição é
  `de.lerp(ate, clampf((b − b0) / 0.5, 0.0, 1.0))`, meia batida. O andar não soma por cima.

### O grito da TV, na contagem

Na batida 2 da contagem (H06), uma vez: a TV grita do centro. `Som.tocar("grito", CENTRO, -4.0)`, o anel da onda sai
do centro em `Tema.neon(Tema.VIOLETA, 1.2, "mundo")`, e os quatro vão `GRITO_TV` (0,5 m) para fora, de 3,0 a
3,5 m. Ensina, antes do primeiro grito de verdade, que o grito empurra e de onde vem o empurrão. Nenhum microfone
escuta na contagem.

### A queda e o fantasma

- Quem passa de `_raio` do centro cai: `_caiu[l] = true`, `_caiu_em[l] = b`. O boneco faz `fall`, desce 2 m no
  abismo em `CenarioDaVoz.queda_s(l, QUEDA_TEMPOS)` (2 tempos × o Fôlego) e some.
- `momento("fora_do_ringue", l, _pos(l), 1.8, {"por": _quem_empurrou[l], "valores": "%s" % [_vivos()]})` e
  `CenarioDaVoz.exagero(self, _cenario, "catastrofe", jogador(l))`: o tremor de 0,08 m por 4 batidas e a chave a
  +40 % por 1 batida (+20 % sem flashes).
- Depois da queda, ele volta como **fantasma** na borda, fora do ringue, em `CENTRO + (RAIO + 1.2) × (cos a, 0,
  sin a)`, com `a` o ângulo de onde caiu. Faz `idle`, de frente para o centro; o anel do chão dele cai a 0,4.
- O fantasma segue com as notas e é julgado igual. O grito dele no tempo forte (BOM ou melhor) é o **sopro**: puxa o
  vivo mais perto, a até `SOPRO_R` (3 m) do fantasma, `SOPRO × gancho(l, "tranco") × _sofre(o)` m na direção do
  fantasma (o abismo puxa). Não pontua mais.
- O fantasma pode mandar adesivos (o HUD, G04) a qualquer hora.
- **Sem controle não cai:** a onda e o sopro não movem quem está sem controle.

### O pico, o ringue encolhe

De `bp` a `bp + 16`: `_raio = lerpf(RAIO, RAIO_PICO, clampf((b − bp) / 16.0, 0, 1))`. A pedra encolhe junto
(`scale.x = scale.z = _raio / RAIO`). As notas valem nas batidas 0 **e** 2 do compasso (8 gritos em 7,1 s).
Depois do pico, o raio fica em 4,5. Quem estiver fora do raio que encolhe cai: o ringue leva 7,1 s para encolher, e o
anel de cada um pisca a 2,4 nas 2 batidas antes de `bp` (o aviso).

### A reta

Nas últimas 16 batidas (`b >= B_FIM − RETA`, 82,7 s), a onda dobra: raio `ONDA_R_RETA` (6 m), a força igual. No
ringue de 4,5 m, todo grito certo alcança todos.

### O fim e o vencedor

`ultimo_em_pe`: com dois ou mais lugares, quando sobra um vivo no ringue, `_fim_batida = b + 4`; um compasso depois,
`acabou[l] = true` em todos. Com um lugar, quando os dois bonecos caem ou ele cai. Senão, o kit fecha no `duracao`
(90 s de música). Em `B_FIM`, `ouvido.fechar()`.

```gdscript
func vencedor() -> Array:
	var dentro := presentes().filter(func(l): return not _caiu[l])
	dentro.sort_custom(func(a, b): return pontos[a] > pontos[b] or (pontos[a] == pontos[b] and a < b))
	var fora := presentes().filter(func(l): return _caiu[l])
	fora.sort_custom(func(a, b): return _caiu_em[a] > _caiu_em[b])
	return dentro + fora
```

### Com menos de quatro

- **Três, dois:** nada muda; os ângulos são os dos lugares. `com_poucos()` devolve `""`.
- **Um:** ele contra dois **bonecos de treino**, os ids 4 e 5 (o orc tingido, abaixo), nos ângulos `0` e `PI / 2`
  (P3 e P2). Os bonecos andam para ele a `VEL_BONECO` (1,2 m/s) e, em cada tempo forte, gritam com chance
  `GRITO_BONECO` (0,7), sorteada no `rng` do jogo, com a força BOM (1,2 m). Não são lugar, não pontuam, caem como os
  outros e não viram fantasma. `com_poucos()`: `"Contra 2 bonecos"`.
- **O controle que cai:** o cavaleiro sem controle fica parado, não grita e não sai do ringue (a onda não o move);
  volta no próximo tempo forte.
- **Sem microfone ou mudo fora do escudo** (`ouvido.sozinho(l)`): o lugar «grita sozinho, mais fraco». A cada tempo
  forte, uma onda de `SOZINHO_FORCA` (1,2 m) e raio `SOZINHO_R` (2 m), sem nota e sem pontos. A `troca` sai do
  ouvido, uma vez. A luz do mudo fica 2.

### Os ganchos

| gancho | o que faz |
| --- | --- |
| `montar()` | a câmera `grupo`, `CenarioDaVoz.montar(self)`, tira as duas colunas grandes, o abismo, o ringue, as marcas e os anéis, os bonecos com um lugar; `gatilhos_off` |
| `iniciar_jogo()` | o ouvido (`janela_casa = 0.3`), `_b_fim`, `_pico_k`, `_robo_rng.seed = rng.seed + 99`, a barra de luz a 30 % |
| `jogar(dt)` | `ouvido.ouvir(dt)`, `passar`, o grito da TV, `_raio`, o andar, as notas, os empurrões, a queda, os bonecos, o último em pé, `_mostrar` |
| `alvos_da_camera()` | o centro na altura da pedra, os vivos e os bonecos de pé |
| `_comecou(l)` | casa a voz e julga |
| `_parou(l)`, `_mudou(l, mudo)` | nada |
| `toque(l, j)` | a onda (ou o sopro, se fantasma); `ouvido.depois(l, ...)`: `Forja.textura(l, "pedra", 0.5)` e o falante `nota:%d` no perfeito |
| `falha(l)` | o coice ou a tosse |
| `vencedor()` | acima |
| `combo(l)` | os gritos certos seguidos (G04) |
| `status(l)` | `"No ringue"` ou `"Fantasma"` |
| `dica(l)` | `["@mic"]` sob o cavaleiro na nota, enquanto `not aprendeu(l)`; senão `{}` |

O esqueleto:

```gdscript
var ouvido: Ouvido
var _cenario := {}
var _b_fim := 202
var _pico_k := 24
var _raio := RAIO
var _pos := []  ## id -> Vector3: 0 a 3 os lugares, 4 e 5 os bonecos
var _caiu := [false, false, false, false, false, false]
var _caiu_em := [-1.0, -1.0, -1.0, -1.0, -1.0, -1.0]
var _empurrao := {}  ## id -> {de, ate, b0}
var _quem_empurrou := [-1, -1, -1, -1, -1, -1]
var _motivo := ["", "", "", ""]
var _ultima_nota := [-1, -1, -1, -1]
var _aberta := [-1.0, -1.0, -1.0, -1.0]  ## o último tempo forte com nota aberta
var _sozinho_feito := [-1.0, -1.0, -1.0, -1.0]
var _fim_batida := -1.0
var _fez := {}
var _bonecos := []  ## com um lugar: [{no, anim}] dos ids 4 e 5
var _ringue: MeshInstance3D
var _marca := {}  ## id -> o pivô das duas caixas dos pés
var _anel := {}  ## id -> {no, mat}
var _tv_depois := []  ## os sons de TV que esperam todas as escutas fecharem


func jogar(dt: float) -> void:
	var b := Ritmo.batida()
	ouvido.ouvir(dt)
	CenarioDaVoz.passar(self, _cenario, _no_pico(b))
	if b >= 2.0 and not _fez.has("tv"):
		_fez["tv"] = true
		_grito_da_tv()
	_raio = _raio_em(b)
	for l in presentes():
		if not conectado(l):
			continue
		if not _caiu[l]:
			_andar(l, dt)
		_abrir(l, b)  # a nota 1 batida antes do tempo forte (e do 2 no pico); o sozinho na batida
		notas_perdidas(l)
	for q in _pos.size():
		_mover(q, b)  # o empurrão pela batida
		_cair_se_saiu(q, b)
	_bonecos_jogam(b)
	_ultimo_em_pe(b)
	if _fim_batida > 0.0 and b >= _fim_batida:
		for l in presentes():
			acabou[l] = true
	if b >= _b_fim and not _fez.has("fim"):
		_fez["fim"] = true
		ouvido.fechar()
	if not ouvido.escuta.has(true):  # o som da TV não entra em microfone que escuta
		for f in _tv_depois:
			f.call()
		_tv_depois.clear()
	_mostrar(b)


func _comecou(l: int) -> void:
	var n := ouvido.casar_voz(l)
	if n < 0:
		return
	_motivo[l] = "coice"
	_julgar(l, n)


func nota_perdida(l: int, n: int) -> void:
	_motivo[l] = "calado"
	_ultima_nota[l] = n
	super(l, n)


func toque(l: int, j: int) -> void:
	_flash(l)
	if _caiu[l]:
		_sopro(l)
	else:
		_onda(l, FORCA[j] * CenarioDaVoz.gancho(l, "tranco"), ONDA_R_RETA if _na_reta() else ONDA_R, l)
	ouvido.depois(l, func():
		Forja.textura(l, "pedra", 0.5)
		if j == Ritmo.PERFEITO:
			ouvido.falante(l, "nota:%d" % l, 0.8, 300))


func falha(l: int) -> void:
	if _caiu[l]:
		return
	var m := (COICE if _motivo[l] == "coice" else TOSSE) * _sofre(l)
	_empurrar(l, -_frente(l), m, l)
	jogador(l).gesto("fall" if _motivo[l] == "coice" else "emote-no", 0.4 if _motivo[l] == "coice" else 0.3)
	if _motivo[l] == "coice":
		_tv_depois.append(func(): Som.tocar("pedra", _pos[l], -6.0))


## A onda de `de`: empurra os outros vivos dentro de `raio`, para longe dele.
func _onda(de: int, forca: float, raio: float, dono: int) -> void:
	var c := _pos[de] as Vector3
	var k := 0
	for o in _alvos_da_onda(de):  # os outros ids vivos, conectados (os bonecos sempre)
		var d := Vector2(_pos[o].x - c.x, _pos[o].z - c.z)
		if d.length() > raio or d.length() < 0.001:
			continue
		_empurrar(o, Vector3(d.x, 0.0, d.y).normalized(), forca * _sofre(o), de)
		k += 1
		if dono >= 0:
			marcar(dono, PONTOS_EMPURRAO)
		if o < 4:
			var lado := "toque_esq" if c.x < _pos[o].x else "toque_dir"
			ouvido.depois(o, func():
				ouvido.sentir(o, lado, 200)
				ouvido.falante(o, "pulso", 0.6, 100))
		_tv_depois.append(func(): Som.tocar("golpe", _pos[o], -4.0))
	_anel_da_onda(c, raio, de)
	if dono >= 0:
		anotar("entrada", dono, {"o": "onda", "raio": raio, "empurrados": k})


func _sofre(q: int) -> float:
	if q >= 4:
		return 1.0
	return CenarioDaVoz.gancho(q, "empurrao") * Itens.resiste_a_empurrao(q)
```

`_julgar(l, n)` guarda `_ultima_nota[l] = n` e chama `julgar_nota(l, n)`. `_frente(l)` é
`Vector3(sin(rot.y), 0, cos(rot.y))` do boneco. `_cair_se_saiu(q, b)`: `Vector2(pos.x − CENTRO.x, pos.z −
CENTRO.z).length() > _raio` e `not _caiu[q]` → a queda. `_sopro(l)`: o vivo mais perto a até `SOPRO_R`, puxado
`SOPRO × gancho(l, "tranco") × _sofre(o)` m na direção do fantasma, com a mesma mão e o mesmo som da onda, sem
pontos. `_flash(l)`: `Forja.luz(l, Tema.JOGADOR[l])` e, em `LUZ_GRITO_S` (0,11 s), de volta a
`Tema.JOGADOR[l].darkened(1.0 - LUZ_BASE)`. `_ultimo_em_pe(b)`: com 2 ou mais presentes e um só vivo, guarda
`_fim_batida = b + 4` uma vez.

O catálogo: `Catalogo.MINIGAMES["S08_J39"] = preload("res://scripts/minigames/s08/grito_de_guerra.gd")` e
`"S08_J39"` na seção `S08`. As traduções: `"Grito de Guerra": "War Cry"`, `"Grite!": "Shout!"`,
`"No ringue": "In the ring"`, `"Contra 2 bonecos": "Against 2 dummies"`. O `"Fantasma"` já vem da O4; se a O4 ainda
não entrou, acrescente `"Fantasma": "Ghost"`.

## A cena

### A câmera

O modo `grupo` da G05, lente de 35 mm: `camera_modo = "grupo"`, `camera_distancia = Vector2(11.0, 16.0)`. A
direção é a da seção: `var pose := CenarioDaVoz.pose_da_camera(1.0, CENTRO + Vector3(0, TOPO, 0))`,
`camera_pos = pose[0]`, `camera_olhar = pose[1]` (plongée de 50°). O grupo enquadra os alvos com 15 % de margem:

```gdscript
func alvos_da_camera() -> Array:
	var a := [CENTRO + Vector3(0, TOPO, 0)]
	for q in _pos.size():
		if not _caiu[q] and (q >= 4 or q in presentes()):
			a.append(_pos[q] + Vector3(0, 0.9, 0))
	return a
```

O centro está sempre na lista: a câmera nunca perde o ringue. A 16 m, o ringue inteiro de 6 m cabe (a meia largura
vista é de 9,7 m). Os fantasmas não entram: com dois vivos no meio, a câmera chega a 11 m e a borda sai do quadro.
Roll zero; o tremor é só o do `exagero`.

### A luz da seção

A da P1, pelo `CenarioDaVoz.montar(self)`: `Tema.luz_da_secao(4, "B")`, a chave a 0,77. No pico, a chave sobe 20 % em
1 batida (10 % sem flashes). A queda é catástrofe: a chave a +40 % por 1 batida.

A barra de luz de cada um fica a 30 % da cor do lugar (`Tema.JOGADOR[l].darkened(0.7)`) e vai a 100 % por 0,11 s em
cada grito certo. É o «gritei» na mão.

### As peças Kenney e o papel de cada uma

| peça | onde | papel |
| --- | --- | --- |
| a cripta, as tochas, as velas, as colunas do fundo | `CenarioDaVoz.montar(self)` | o fundo comum da seção |
| `rocks` (escala 0,5) | 8, nos vértices do octógono, `CENTRO + (RAIO / cos(PI / 8)) × (cos(i × PI / 4), 0, sin(i × PI / 4))`, em y 0,6, giro `i × PI / 4` | a borda do ringue |
| `mini-dungeon-personagens/character-orc` | os bonecos de treino (só com um lugar), tingidos de `Tema.ETIQUETA_SOMBRA` | os adversários de quem joga só |

As duas `pillar-large` da cripta, em `(±3.2, 0, −3.4)`, ficam dentro do ringue. O `montar()` tira as duas, pela
posição, sem mexer no `cenario_da_voz.gd`:

```gdscript
for n in get_children():
	if n is Node3D and absf(absf(n.position.x) - 3.2) < 0.01 and absf(n.position.z + 3.4) < 0.01:
		n.queue_free()
```

O que não é peça Kenney (caixas do `Kit`, `metallic` 0):

| objeto | forma | onde | material |
| --- | --- | --- | --- |
| o abismo | caixa 30 × 0,02 × 22 | `(0, 0.01, −0.5)`, sobre o chão da cripta | `Kit.material(Tema.JANELA, 0.0, 1.0)` |
| o ringue | `Kit.cilindro(self, RAIO / cos(PI / 8), TOPO, CENTRO + Vector3(0, 0.3, 0), pedra)` com `radial_segments = 8` | o centro | `Kit.material(Tema.GRAFITE, 0.0, 0.95)` |
| a marca dos pés | 2 caixas 0,25 × 0,02 × 0,4 | filhas de um pivô no pé do cavaleiro, em `(±0.15, 0.01, 0.1)`; o pivô gira com ele | `Tema.neon(Tema.JOGADOR[l], 1.8)` |
| o anel do chão | `TorusMesh`, raio de dentro 0,5, de fora 0,62 | sob o cavaleiro, y `TOPO + 0.01` | `Tema.neon(Tema.JOGADOR[l], 1.5)`; o fantasma, 0,4 |
| o anel da onda | `TorusMesh`, de 0,3 ao raio da onda em 0,25 s, depois some em 0,15 s | o pé do gritador | `Tema.neon(Tema.JOGADOR[l], 1.2 a 2.6)` (o volume); da TV e dos bonecos, `Tema.neon(Tema.VIOLETA, 1.2, "mundo")` |

A marca dos pés mostra para onde ele olha, e o coice vai para o lado contrário. É o que ensina o coice sem palavra.

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08) |
| a marca dos pés | o lugar | 1,8 |
| o anel do chão | o lugar | 1,5; o do fantasma, 0,4; 2,4 piscando nas 2 batidas antes do pico |
| o anel da onda | o lugar | de 1,2 a 2,6, pelo volume da voz |
| a onda da TV e dos bonecos | o mundo | `Tema.VIOLETA`, 1,2 |
| as tochas | a forja | 1,8 (o cenário comum) |

A pedra é `Tema.GRAFITE` e o abismo é `Tema.JANELA`, sem brilho. Somem os `#0d0b14`, `#4a4452`, `#b9b0ff`, `#ffb070`,
`#b9a98a`, o `Tema.VERMELHO` e o `Forja.cor_do_lugar` da ficha antiga.

### A montagem

- Por lugar: **sem** `raia(l)` nem `posicionar(l)` (o ringue é livre). `jogador(l).position = _pos[l]`, de frente para
  o centro, `preso = true`; mova pela posição. A marca dos pés e o anel do chão.
- Com um lugar: os bonecos 4 e 5. O modelo vem de `Kit.caminho("mini-dungeon-personagens/character-orc")`, tingido
  pelo `_tingir` copiado de `prova.gd:200-210` (um `StandardMaterial3D` por superfície, `albedo_color` e `roughness`
  0,9). Cada boneco tem a marca dos pés e o anel em `Tema.VIOLETA`, a 1,0.

## O som

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| o grito da TV (contagem) | `Som.tocar("grito", CENTRO, -4.0)` | — | `grito_*` |
| o grito certo | a nota do kit (`Som.tocar("nota", ...)`, H08) | `nota:%d`, 0,8 (300 ms) no perfeito, depois da escuta | `nota_*` |
| cada empurrado | `Som.tocar("golpe", pos, -4.0)`, depois das escutas | o do empurrado: `pulso`, 0,6 (100 ms), depois da escuta dele | `golpe_*`, `mod_pulso` |
| o coice | `Som.tocar("pedra", pos, -6.0)`, depois das escutas | — | `pedra_*` |
| a queda | `Som.tocar("vento", pos, -2.0)` | — | `vento_*` |
| a faixa | `MUS_S08_J39`: 135 BPM, Si menor; até ela existir, a reserva `"sopro"` (105 bpm) | — | `mus_s08_j39` |

- **Todos gritam no mesmo tempo forte.** Um som da TV dentro da janela entra nos quatro microfones. Por isso os sons
  do empurrão e do coice esperam todas as escutas fecharem (`_tv_depois`), no máximo 0,3 s.
- **O `falha` não existe aqui.** O material `"pedra"` toca pelo minigame, no grito certo, depois da escuta.

## O controle

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| começar | todos | — | `gatilhos_off(l)` | a cor do lugar a 30 % | — |
| o grito certo | o dono | a textura `pedra` 0,5 depois da escuta; sem háptica, `toque` | — | 100 % por 0,11 s | `nota:%d` no perfeito |
| o coice | o dono | o kit: `erro` | — | o kit | — |
| empurrado | o empurrado | `toque_esq` ou `toque_dir` (um motor a 0,4, 200 ms), do lado do gritador, depois da escuta | — | — | `pulso` 0,6 |
| caiu no abismo | o dono | `golpe` (fora da escuta; dentro, o ouvido troca por `toque`) | — | — | — |

- **O lado é o da tela:** o gritador com x menor está à esquerda: `toque_esq`. O empurrado sente de onde veio.
- **Nada forte vibra na escuta:** o `ouvido.sentir` troca o forte por `toque` enquanto o microfone dele escuta.
- **No rádio:** sem microfone nem alto-falante. O lugar grita sozinho desde o começo, com a `troca` gravada pelo
  ouvido. A háptica do kit vai pelo rumble. A luz do mudo passa pela ponte.

### O robô

```gdscript
# O robô anda para o centro e grita no tempo forte pelo controle simulado.
# Quando erra: metade das vezes grita 0,2 s tarde (o coice), metade fica calado.
var _robo_rng := RandomNumberGenerator.new()
var _robo_nota := [-1, -1, -1, -1]
var _robo_feita := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	if not _caiu[l]:
		var para := Vector2(CENTRO.x - _pos[l].x, CENTRO.z - _pos[l].z)
		var mv := para.normalized() * (0.8 if para.length() > 1.5 else 0.0)
		Forja.robo_eixo(l, Forja.LX, mv.x, 0.1)
		Forja.robo_eixo(l, Forja.LY, mv.y, 0.1)
	for n in notas_em_aberto(l):
		if int(n) <= int(_robo_feita[l]):
			continue
		if int(_robo_nota[l]) != int(n):
			_robo_nota[l] = n
			var certo := Forja.robo_acerta()
			_robo_mira[l] = 0.0 if certo else (0.2 if _robo_rng.randf() < 0.5 else 99.0)
		if Ritmo.t_musica() >= alvo_da(l, n) + float(_robo_mira[l]):
			Forja.robo_falar(l, 0.9, 0.3)
			_robo_feita[l] = n
		break
```

O robô grita 0,3 s a 0,9. O grito 0,2 s tarde casa (até 0,3 s) e passa da janela do BOM: é o coice. O `99.0` nunca
chega: é o calado. O fantasma do robô segue gritando.

## O cavaleiro

O cavaleiro é o da montagem (G13), solto no ringue, de mãos livres. O cavaleiro pode ser de outra raça (G13, o ajuste
dela de 09/10): esta ficha não supõe corpo humano; usa só o esqueleto comum de 7 ossos e as animações `walk`, `idle`,
`fall`, `emote-no` e `attack-melee-right`.

| stat | gancho | o que muda no Grito de Guerra | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | o que ele sofre: a onda, o coice, a tosse, o sopro | ×1,16 | ×1 | ×0,84 |
| Peso | `tranco` | o que a onda dele dá, e o sopro de fantasma | ×0,84 (2,0 m no perfeito) | ×1 (2,4 m) | ×1,16 (2,8 m) |
| Passo | `velocidade` | o andar | 2,82 m/s | 3,0 m/s | 3,18 m/s |
| Fôlego | `levantar` | a queda no abismo até virar fantasma (2 tempos) | 2,5 tempos | 2 tempos | 1,5 tempo |
| Faro | — | não age: o tempo forte é a música, sem pista | — | — | — |

Os itens: a Âncora divide o empurrão que ele sofre por 2 (`Itens.resiste_a_empurrao`, 0,5); o Escudo absorve o
primeiro erro (o kit, G03); o Fole devolve metade do combo; o Martelo dobra o perfeito no tempo forte (o kit: aqui,
todo grito é no tempo forte); o Diapasão é do kit; a Lanterna não age. Nenhum stat muda a janela de julgamento.

## As reações

- **Carimbos** (do kit e do HUD, G04; o Grito não chama nenhum): `car_em_chamas` (5 Ressonâncias seguidas do mesmo
  lugar), `car_acorde` (os quatro gritam certo no mesmo tempo forte: o coro de guerra), `car_por_um_fio` (o último em
  pé a até 0,5 m da borda).
- **Adesivos:** os fantasmas mandam adesivos (G04) enquanto o jogo segue.
- Nenhum carimbo próprio de minigame.

## A diversão

**O momento: fora do ringue** (`fora_do_ringue`). A onda certa pega o vizinho na borda, ele voa e some no abismo.
Ou pior: o coice do próprio grito atrasado o joga para fora. A sala explode. Degrau catástrofe.

- **Rastro:** quem caiu volta como fantasma na borda, com o anel apagado, e o sopro dele puxa os vivos para o abismo.
- **A curva:** de 0,9 a 1,8 s, o grito da TV; de 1,8 a 44 s, um grito por compasso, no ringue de 6 m; de 44,4 a
  51,6 s, **o pico**: o ringue encolhe a 4,5 m e o grito vale no 1 e no 3; de 51,6 a 82,7 s, o ringue pequeno; de
  82,7 s ao fim, a onda dobra.
- **Ensina sem falar:** o grito da TV empurra os quatro na contagem; a marca dos pés mostra o lado do coice; a mão
  sente o lado do empurrão.
- **Quem está perdendo:** como fantasma, ainda grita e puxa os vivos para o abismo.
- **A nota de hoje:** 4. Gênero `tct`.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | o grito da TV na batida 2 (0,9 s); cada lugar tem um `toque` com `t_musica` ≤ 5,4 (a batida 12) | o quadro de 1 s mostra a onda violeta e os quatro afastados |
| 4. o momento | pelo menos 2 linhas `momento` `fora_do_ringue` entre 0 e 90 s, pelo menos 1 no pico (44,4 a 51,6 s) | depois de 45 s, 1 quadro em cada 3 mostra um fantasma na borda |
| 5. a curva | existem `nota` em batidas `≡ 2 (mod 4)` entre 100 e 115; toda `entrada` `onda` depois de 82,7 s tem `raio` 6 | o quadro de 52 s mostra o ringue menor que o de 30 s |
| 6. a falha | o P4 tem pelo menos 3 `toque` com `erro` ou `nota` perdida | o P4 cai para trás (`fall`) em 1 quadro em 10 |
| 7. quem perde joga | o P4 tem nota em todo tempo forte, vivo ou fantasma; o P4 tem um `toque` BOM ou melhor em cada terço | o HUD do P4 (G04) aparece em 100 % dos quadros de jogo |
| 8. a câmera | todo `fora_do_ringue` tem 0,05 ≤ `x_tela` ≤ 0,95 e `altura_tela` ≥ 0,06 | os vivos e o centro do ringue cabem no quadro de 480 × 270 |
| 9. o impacto | o empurrado começa a andar na mesma batida da onda (o `b0` do empurrão é a batida do `toque`) | o quadro seguinte à onda mostra o anel aberto e o empurrado fora do lugar |
| 10. o placar no mundo | o `valores` do `fora_do_ringue` bate com `_vivos()` | os fantasmas na borda mostram quem caiu |

A mesa padrão roda em duas rodadas até o robô por lugar existir: `bash tests/prova_do_jogo.sh --robo=medio` (os
itens 1, 5, 8, 9 e 10) e `--robo=ruim` (os itens 4, 6 e 7).

## Pronto quando

O Grito de Guerra joga do aviso ao resultado com 4, 3, 2 e 1 jogador (com os bonecos) e com o robô nos três
temperamentos (o ruim leva coice). Aguenta o cabo que cai e volta, e fecha com vencedor pelo último em pé. O empurrado
sente um motor só, do lado certo, depois da janela. Nada forte vibra na escuta. A prova do jogo passa, e
`bash tests/prova_visual.sh` passa com a prancha olhada (o ringue, as ondas, alguém caindo, os fantasmas na borda).

## Provas

Em `godot/testes/prova_do_jogo.gd`, depois da `_prova_zero_absoluto()`:

```gdscript
## S08_J39: o robô grita no tempo forte; alguém é empurrado, e a mão do
## empurrado sente um motor só; nada forte vibra na escuta; o ringue encolhe.
func _prova_grito_de_guerra() -> void:
	var forte := [0]
	var raio_pico := [99.0]
	var olhar := func(mg) -> void:
		if mg.ouvido == null:
			return
		raio_pico[0] = minf(raio_pico[0], mg._raio)
		for l in mg.presentes():
			if not mg.ouvido.escuta[l]:
				continue
			var pc := Forja.percepcao(l)
			if maxf(float(pc.get("forte", 0.0)), float(pc.get("fraco", 0.0))) > 0.75:
				forte[0] += 1
	var mg = await _joga_o_minigame("S08_J39", 130.0, olhar)
	if mg == null:
		return
	_esperar(forte[0] == 0, "Grito: nada forte vibrou na escuta (%d)" % forte[0])
	_esperar(mg.colocacao().size() == mg.presentes().size(), "Grito: a colocação tem todos")
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S08_J39")
	var lados := linhas.filter(func(e): return e.get("tipo") == "sensacao" \
		and str(e.get("nome", "")) in ["toque_esq", "toque_dir"])
	_esperar(lados.size() >= 1, "Grito: alguém foi empurrado e sentiu o lado (%d)" % lados.size())
	var ondas := linhas.filter(func(e): return e.get("tipo") == "entrada" and e.get("o") == "onda")
	_esperar(ondas.size() >= 1, "Grito: uma onda saiu")
	if mg._fim_batida < 0.0 or mg._fim_batida > 116.0:
		_esperar(raio_pico[0] <= 4.51, "Grito: o ringue encolheu no pico (%.2f)" % raio_pico[0])
	var quedas := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "fora_do_ringue")
	if Forja.robo_temperamento == "ruim":
		_esperar(quedas.size() >= 2, "Grito: %d quedas na mesa ruim" % quedas.size())
	for q in quedas:
		_esperar(float(q.get("x_tela", 0.0)) >= 0.05 and float(q.get("x_tela", 0.0)) <= 0.95, "Grito: a queda na tela (%s)" % [q])
```

O 4,51 é o `RAIO_PICO` com a folga do `lerpf`. A conferência do pico só vale se o jogo chegou ao
fim do pico (a batida 116) sem acabar por último em pé. `Forja.robo_temperamento` é o temperamento da F09 (se o nome
lá for outro, use o da F09).

### O que o registro mede

- `voz` de cada grito (o nível e o limiar): o grito é o nível mais alto da seção, e a noite vê se algum microfone
  satura ou corta.
- `nota` e `toque` de cada grito, com o desvio da voz no tempo forte.
- `sensacao` `toque_esq` e `toque_dir` de cada empurrão: o lado, no controle de quem foi empurrado.
- `entrada` `onda`, com o raio e os empurrados; `momento` `fora_do_ringue`, com quem empurrou e os vivos.
- `troca` de `microfone` para `sem_microfone`.

### As pranchas que o jogador do time olha

- o quadro de 1 s: a onda violeta da TV e os quatro afastados;
- o de 30 s: o ringue de 6 m e as ondas;
- o de 52 s: o ringue de 4,5 m;
- um quadro com a queda: o boneco abaixo da borda;
- depois de 45 s: os fantasmas na borda.

### O que o André joga e sente

`./run-local.sh -- --sala=S08_J39`, com quatro:

- o grito no tempo tem de ser **o** momento;
- o coice perto da borda tem de fazer rir;
- o empurrão chega na mão do lado certo;
- a voz de um não solta a onda do vizinho calado. Se soltar, anote os `voz` dos dois;
- o fantasma puxando para o abismo dá vontade de continuar gritando.

### Armadilhas

- **O robô sorteia no dele:** `_robo_rng.seed = rng.seed + 99`. Os bonecos gritam pelo `rng` do jogo: são regra,
  não robô.
- **Todos gritam juntos.** A regra dos 6 dB conta todos os que gritam perto do mais alto: é o esperado. Quem não
  gritou fica abaixo e não solta onda.
- **O empurrão anda pela batida**, não por velocidade somada com o `dt`. O andar do analógico é entrada e usa o `dt`.
- **Nenhum som de TV na janela:** o golpe e a pedra esperam no `_tv_depois`. O grito da TV é na contagem, quando
  ninguém escuta.
- **As colunas grandes:** se a prancha mostrar uma coluna no ringue, o `montar()` não achou as duas pela posição.
  Meça a posição no `cenario_da_voz.gd` e anote.
- **Na prova o pico chega:** o fim conta em tempo de música (H08). Com 4 robôs, o último em pé pode acabar o jogo
  antes do pico: a prova só confere o pico quando o jogo passou dele.

### Ao terminar

- No [quadro](README.md): a linha **P4**, com o commit (`feito (<commit>)`).
- Commit sugerido (sem trailer):
  `feat: Grito de Guerra no kit — a voz no tempo forte empurra`
